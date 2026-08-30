#!/bin/bash
# edit-fact-gate.sh — PreToolUse guard for Edit/Write/NotebookEdit.
#
# Denies the FIRST edit to each pre-existing file in a session and hands the
# model a checklist of facts to gather (importers, affected API, the user's
# instruction). The model investigates and retries on its own — the user never
# sees a prompt. Derived from ECC's GateGuard idea, with three fixes for
# problems ECC's own tracker still has open:
#
#   1. New files are never gated. A file that does not exist yet has no
#      importers, so gating it is pure friction (ECC issue #2608).
#   2. The retry is VERIFIED, not assumed. ECC allows any second attempt. This
#      hook reads the session transcript and checks that a Read/Grep/Glob/Bash
#      call actually referenced the target between the denial and the retry.
#      No evidence, one more denial — then it gives up and allows.
#   3. Hard caps everywhere. Two denials per file, GATE_CAP denials per
#      session. Nothing can wedge the session into an edit loop.
#
# Fails open on every internal error: a broken gate must never stop work. The
# deny path always exits 0 with JSON, because a non-zero exit surfaces as a
# hook error instead of a clean block (the bug that made ECC's own
# config-protection hook inert — their issue #2697).
#
# Off switch, either one:
#   touch ~/.claude/.edit-gate-off        # persistent
#   CLAUDE_EDIT_GATE=off                  # per shell
#
# Tests: ~/.claude/hooks/tests/test-edit-fact-gate.sh

set -u

GATE_CAP=${CLAUDE_EDIT_GATE_CAP:-8}   # max denials per session, all files
STATE_ROOT="$HOME/.claude/cache/edit-gate"

# ---------------------------------------------------------------- off switch
[ -f "$HOME/.claude/.edit-gate-off" ] && exit 0
[ "${CLAUDE_EDIT_GATE:-on}" = "off" ] && exit 0

command -v jq >/dev/null 2>&1 || exit 0   # no jq, no opinion

payload=$(cat)
[ -n "$payload" ] || exit 0

get() { printf '%s' "$payload" | jq -r "$1 // \"\"" 2>/dev/null; }

tool=$(get '.tool_name')
session=$(get '.session_id')
transcript=$(get '.transcript_path')

# NotebookEdit carries notebook_path; everything else carries file_path.
target=$(get '.tool_input.file_path')
[ -n "$target" ] || target=$(get '.tool_input.notebook_path')
[ -n "$target" ] || exit 0

case "$tool" in
  Edit|Write|NotebookEdit|MultiEdit) ;;
  *) exit 0 ;;
esac

# ------------------------------------------------------------ what to ignore
# Only pre-existing files are worth gating. A Write that creates a new file has
# no call sites to check.
[ -f "$target" ] || exit 0

case "$target" in
  */.git/*|*/node_modules/*|*/.next/*|*/dist/*|*/build/*|*/__pycache__/*) exit 0 ;;
  /tmp/*|/private/tmp/*|/var/folders/*) exit 0 ;;   # scratchpads and temp work
esac
[ -n "${TMPDIR:-}" ] && case "$target" in "$TMPDIR"*) exit 0 ;; esac

# ------------------------------------------------------------------- state
# Keyed on session so two concurrent sessions never share a verdict.
[ -n "$session" ] || exit 0
safe_session=$(printf '%s' "$session" | tr -c 'A-Za-z0-9._-' '_')
state="$STATE_ROOT/$safe_session"
mkdir -p "$state" 2>/dev/null || exit 0

# Prune session dirs older than two days. Cheap, and keeps the cache bounded.
find "$STATE_ROOT" -mindepth 1 -maxdepth 1 -type d -mtime +2 ! -name "$safe_session" -exec rm -rf {} + 2>/dev/null

abs=$(cd "$(dirname "$target")" 2>/dev/null && printf '%s/%s' "$(pwd -P)" "$(basename "$target")") || abs="$target"
key=$(printf '%s' "$abs" | shasum 2>/dev/null | cut -c1-40)
[ -n "$key" ] || exit 0
marker="$state/$key"

# Session-wide budget: after GATE_CAP distinct files, the gate goes quiet for
# the rest of the session. Counts resolved files too, so a long editing run can
# never accumulate unbounded friction.
gated_files=$(find "$state" -mindepth 1 -maxdepth 1 -type f ! -name '*.done' 2>/dev/null | wc -l | tr -d ' ')
done_files=$(find "$state" -mindepth 1 -maxdepth 1 -type f -name '*.done' 2>/dev/null | wc -l | tr -d ' ')
[ $(( ${gated_files:-0} + ${done_files:-0} )) -ge "$GATE_CAP" ] && [ ! -e "$marker" ] && exit 0

deny() {
  jq -cn --arg reason "$1" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$reason}}'
  exit 0
}

base=$(basename "$abs")

# Prose files have readers, not importers. Ask the question that fits.
case "$base" in
  *.md|*.mdx|*.txt|*.rst)
    q1="1. Name what consumes this document (a skill that loads it, a link from another doc, a script that parses it) — search for its filename." ;;
  *)
    q1="1. List every file that imports, requires, or references \`$base\` — run a Grep for its module name or path." ;;
esac

# ------------------------------------------------------------ first contact
if [ ! -e "$marker" ] && [ ! -e "$marker.done" ]; then
  date -u +%Y-%m-%dT%H:%M:%S > "$marker" 2>/dev/null || exit 0
  deny "Fact gate: first edit to $base this session. Gather these before retrying — the retry is checked against the transcript, so actually run the searches:

$q1
2. Name the public functions, exports, or config keys this change affects, and what breaks if their behaviour shifts.
3. Quote the user's current instruction verbatim, so the edit is scoped to what was asked.

State the answers, then make the same edit again. New files are never gated; this fires once per existing file per session. Off switch: touch ~/.claude/.edit-gate-off"
fi

[ -e "$marker.done" ] && exit 0

# ------------------------------------------------- retry: verify the homework
denied_at=$(cat "$marker" 2>/dev/null)
attempts=$(wc -l < "$marker" 2>/dev/null | tr -d ' ')

# Second denial is the last one. Third attempt always passes.
if [ "${attempts:-1}" -ge 2 ]; then
  mv "$marker" "$marker.done" 2>/dev/null
  exit 0
fi

# Default is "unknown" — if the transcript cannot be inspected at all there is
# nothing to hold against the retry, so it passes. Only a transcript that was
# actually read and contained no probe returns "no".
investigated=unknown
if [ -n "$transcript" ] && [ -f "$transcript" ] && command -v python3 >/dev/null 2>&1; then
  investigated=$(python3 - "$transcript" "$denied_at" "$abs" "$base" 2>/dev/null <<'PY' || echo unknown
import json, sys
path, since, abs_target, base = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
PROBES = {"Read", "Grep", "Glob", "Bash", "Task", "Agent", "Explore"}
try:
    lines = open(path, encoding="utf-8", errors="ignore").readlines()[-400:]
except OSError:
    print("unknown"); raise SystemExit
for line in lines:
    try:
        rec = json.loads(line)
    except ValueError:
        continue
    ts = (rec.get("timestamp") or "")[:19]
    if not ts or ts < since:
        continue
    content = (rec.get("message") or {}).get("content")
    if not isinstance(content, list):
        continue
    for block in content:
        if not isinstance(block, dict) or block.get("type") != "tool_use":
            continue
        if block.get("name") not in PROBES:
            continue
        blob = json.dumps(block.get("input") or {})
        if base in blob or abs_target in blob:
            print("yes"); raise SystemExit
print("no")
PY
)
fi

case "$investigated" in
  yes|unknown)
    # Verified, or the transcript could not be read — either way, let it through.
    mv "$marker" "$marker.done" 2>/dev/null
    exit 0
    ;;
esac

printf '%s\n' "second" >> "$marker"
deny "Fact gate: still no search for \`$base\` in this session's transcript since the last denial. The checklist is not a formality — run the Grep, read one importer, then retry. This is the final gate on this file; the next attempt goes through either way."
