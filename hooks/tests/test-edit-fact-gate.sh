#!/bin/sh
# Verification harness for the pre-edit fact gate.
# Runs against a throwaway HOME so it never touches real session state.
set -u
RC=0
HOOK="$HOME/.claude/hooks/edit-fact-gate.sh"; FAIL=0
ok(){ printf '  ok   %s\n' "$1"; }
no(){ printf '  FAIL %s\n' "$1"; FAIL=1; }

[ -x "$HOOK" ] || { echo "  FAIL hook not executable at $HOOK"; exit 1; }

# Deliberately NOT under mktemp -d: on macOS that lands in /var/folders, which
# the hook skips by design. The sandbox has to sit somewhere the gate is live.
SANDBOX="$HOME/.cache/edit-gate-test.$$"
rm -rf "$SANDBOX"; mkdir -p "$SANDBOX" || { echo "  FAIL cannot make sandbox"; exit 1; }
trap 'rm -rf "$SANDBOX"' EXIT
FAKEHOME="$SANDBOX/home"; mkdir -p "$FAKEHOME/.claude"
WORK="$SANDBOX/work"; mkdir -p "$WORK"
printf 'export const a = 1\n' > "$WORK/real.ts"
printf '# Doc\n' > "$WORK/real.md"

# run <session> <tool> <path> [transcript] -> stdout of the hook; exit code in RC
run() {
  _s=$1; _t=$2; _p=$3; _tr=${4:-}
  _out=$(printf '{"session_id":"%s","transcript_path":"%s","cwd":"%s","tool_name":"%s","tool_input":{"file_path":"%s"}}' \
    "$_s" "$_tr" "$WORK" "$_t" "$_p" | env HOME="$FAKEHOME" TMPDIR="" sh "$HOOK" 2>/dev/null)
  _rc=$?
  printf '%s' "$_out"
  return $_rc
}
raw() { printf '%s' "$1" | env HOME="$FAKEHOME" TMPDIR="" sh "$HOOK" 2>/dev/null; }

denies() { printf '%s' "$1" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1; }
allows() { [ -z "$1" ]; }

echo "-- contract shape --"
out=$(run s-shape Edit "$WORK/real.ts"); RC=$?
[ "$RC" = 0 ] && ok "deny path still exits 0" || no "deny path exits 0 (got $RC)"
printf '%s' "$out" | jq -e . >/dev/null 2>&1 && ok "emits valid JSON" || no "emits valid JSON"
printf '%s' "$out" | jq -e '.hookSpecificOutput.hookEventName == "PreToolUse"' >/dev/null 2>&1 \
  && ok "hookEventName is PreToolUse" || no "hookEventName is PreToolUse"
denies "$out" && ok "permissionDecision is deny" || no "permissionDecision is deny"
printf '%s' "$out" | jq -re '.hookSpecificOutput.permissionDecisionReason' 2>/dev/null | grep -q 'real.ts' \
  && ok "reason names the file" || no "reason names the file"
printf '%s' "$out" | jq -re '.hookSpecificOutput.permissionDecisionReason' 2>/dev/null | grep -q 'edit-gate-off' \
  && ok "reason carries the off switch" || no "reason carries the off switch"

echo "-- what is never gated --"
allows "$(run s-new Write "$WORK/brand-new.ts")" && ok "new file passes" || no "new file passes"
allows "$(run s-new Write "$WORK/nested/deep/new.ts")" && ok "new file in new dir passes" || no "new file in new dir passes"
allows "$(run s-new Bash "$WORK/real.ts")" && ok "non-edit tool passes" || no "non-edit tool passes"
allows "$(run s-new Read "$WORK/real.ts")" && ok "Read passes" || no "Read passes"
mkdir -p "$WORK/node_modules/x" && printf 'x\n' > "$WORK/node_modules/x/i.js"
allows "$(run s-new Edit "$WORK/node_modules/x/i.js")" && ok "node_modules passes" || no "node_modules passes"
mkdir -p "$WORK/.git" && printf 'x\n' > "$WORK/.git/config"
allows "$(run s-new Edit "$WORK/.git/config")" && ok ".git passes" || no ".git passes"
printf 'x\n' > /tmp/edit-gate-probe.txt
allows "$(run s-new Edit /tmp/edit-gate-probe.txt)" && ok "/tmp passes" || no "/tmp passes"
rm -f /tmp/edit-gate-probe.txt
TMPPROBE=$(mktemp); printf 'x\n' > "$TMPPROBE"
tmpout=$(printf '{"session_id":"s-tmp","tool_name":"Edit","tool_input":{"file_path":"%s"}}' "$TMPPROBE" \
  | env HOME="$FAKEHOME" sh "$HOOK" 2>/dev/null)
allows "$tmpout" && ok "TMPDIR passes" || no "TMPDIR passes"
rm -f "$TMPPROBE"

echo "-- malformed and missing input --"
allows "$(raw '')" && ok "empty stdin passes" || no "empty stdin passes"
allows "$(raw 'not json at all')" && ok "garbage stdin passes" || no "garbage stdin passes"
allows "$(raw '{"tool_name":"Edit","tool_input":{}}')" && ok "no file_path passes" || no "no file_path passes"
allows "$(raw "$(printf '{"tool_name":"Edit","tool_input":{"file_path":"%s"}}' "$WORK/real.ts")")" \
  && ok "no session_id passes" || no "no session_id passes"

echo "-- off switches --"
touch "$FAKEHOME/.claude/.edit-gate-off"
allows "$(run s-off Edit "$WORK/real.ts")" && ok "marker file disables gate" || no "marker file disables gate"
rm -f "$FAKEHOME/.claude/.edit-gate-off"
envout=$(printf '{"session_id":"s-env","tool_name":"Edit","tool_input":{"file_path":"%s"}}' "$WORK/real.ts" \
  | env HOME="$FAKEHOME" CLAUDE_EDIT_GATE=off sh "$HOOK" 2>/dev/null)
allows "$envout" && ok "CLAUDE_EDIT_GATE=off disables gate" || no "CLAUDE_EDIT_GATE=off disables gate"
denies "$(run s-env2 Edit "$WORK/real.ts")" && ok "gate live again after unset" || no "gate live again after unset"

echo "-- first touch, then retry without evidence --"
S=s-flow
EMPTYTR="$SANDBOX/empty.jsonl"
cat > "$EMPTYTR" <<JSON
{"timestamp":"2099-01-01T00:00:00.000Z","message":{"content":[{"type":"text","text":"thinking out loud"}]}}
JSON
denies "$(run $S Edit "$WORK/real.ts" "$EMPTYTR")" && ok "1st attempt denied" || no "1st attempt denied"
out2=$(run $S Edit "$WORK/real.ts" "$EMPTYTR")
denies "$out2" && ok "2nd attempt denied (no evidence)" || no "2nd attempt denied (no evidence)"
printf '%s' "$out2" | jq -re '.hookSpecificOutput.permissionDecisionReason' | grep -q 'final gate' \
  && ok "2nd denial says it is the last" || no "2nd denial says it is the last"
allows "$(run $S Edit "$WORK/real.ts" "$EMPTYTR")" && ok "3rd attempt passes (fail-open)" || no "3rd attempt passes"
allows "$(run $S Edit "$WORK/real.ts" "$EMPTYTR")" && ok "4th attempt still passes" || no "4th attempt still passes"

echo "-- retry with transcript evidence --"
S=s-proof
TR="$SANDBOX/transcript.jsonl"
denies "$(run $S Edit "$WORK/real.ts" "$TR")" && ok "1st attempt denied" || no "1st attempt denied"
cat > "$TR" <<JSON
{"timestamp":"2099-01-01T00:00:00.000Z","message":{"content":[{"type":"tool_use","name":"Grep","input":{"pattern":"real.ts","path":"."}}]}}
JSON
allows "$(run $S Edit "$WORK/real.ts" "$TR")" && ok "grep for the file unlocks it" || no "grep for the file unlocks it"
allows "$(run $S Edit "$WORK/real.ts" "$TR")" && ok "stays unlocked afterwards" || no "stays unlocked afterwards"

S=s-stale
denies "$(run $S Edit "$WORK/real.ts" "$TR")" && ok "1st attempt denied" || no "1st attempt denied"
cat > "$TR" <<JSON
{"timestamp":"2000-01-01T00:00:00.000Z","message":{"content":[{"type":"tool_use","name":"Grep","input":{"pattern":"real.ts"}}]}}
{"timestamp":"2099-01-01T00:00:00.000Z","message":{"content":[{"type":"tool_use","name":"Grep","input":{"pattern":"something-else"}}]}}
JSON
denies "$(run $S Edit "$WORK/real.ts" "$TR")" && ok "pre-denial search does not count" || no "pre-denial search does not count"

S=s-unrelated
denies "$(run $S Edit "$WORK/real.ts" "$TR")" && ok "1st attempt denied" || no "1st attempt denied"
cat > "$TR" <<JSON
{"timestamp":"2099-01-01T00:00:00.000Z","message":{"content":[{"type":"tool_use","name":"Edit","input":{"file_path":"real.ts"}}]}}
JSON
denies "$(run $S Edit "$WORK/real.ts" "$TR")" && ok "an Edit is not investigation" || no "an Edit is not investigation"

S=s-badtr
denies "$(run $S Edit "$WORK/real.ts" "$SANDBOX/nope.jsonl")" && ok "1st attempt denied" || no "1st attempt denied"
allows "$(run $S Edit "$WORK/real.ts" "$SANDBOX/nope.jsonl")" && ok "missing transcript fails open" || no "missing transcript fails open"

S=s-notr
denies "$(run $S Edit "$WORK/real.ts")" && ok "1st attempt denied" || no "1st attempt denied"
allows "$(run $S Edit "$WORK/real.ts")" && ok "absent transcript_path fails open" || no "absent transcript_path fails open"

S=s-corrupt
denies "$(run $S Edit "$WORK/real.ts" "$SANDBOX/corrupt.jsonl")" && ok "1st attempt denied" || no "1st attempt denied"
printf 'not json\n{"broken":\n' > "$SANDBOX/corrupt.jsonl"
denies "$(run $S Edit "$WORK/real.ts" "$SANDBOX/corrupt.jsonl")" && ok "corrupt lines are skipped, not fatal" \
  || no "corrupt lines are skipped, not fatal"

echo "-- per-file and per-session scoping --"
S=s-scope
denies "$(run $S Edit "$WORK/real.ts")" && ok "file A denied" || no "file A denied"
denies "$(run $S Edit "$WORK/real.md")" && ok "file B denied independently" || no "file B denied independently"
printf '%s' "$(run s-other Edit "$WORK/real.ts")" | jq -e '.hookSpecificOutput' >/dev/null 2>&1 \
  && ok "a second session gets its own verdict" || no "a second session gets its own verdict"
# Same file reached by a different path string must resolve to one marker.
S=s-path
denies "$(run $S Edit "$WORK/real.ts" "$EMPTYTR")" && ok "1st attempt denied" || no "1st attempt denied"
denies "$(run $S Edit "$WORK/./real.ts" "$EMPTYTR")" && ok "./ path denied as a retry, not a new file" \
  || no "./ path denied as a retry, not a new file"
n=$(find "$FAKEHOME/.claude/cache/edit-gate/$S" -type f 2>/dev/null | wc -l | tr -d ' ')
[ "$n" = 1 ] && ok "./ path shares one marker" || no "./ path shares one marker (found $n)"
allows "$(run $S Edit "$WORK/real.ts" "$EMPTYTR")" && ok "and resolves after two" || no "and resolves after two"

echo "-- prose vs code prompt --"
mdout=$(run s-md Edit "$WORK/real.md")
printf '%s' "$mdout" | jq -re '.hookSpecificOutput.permissionDecisionReason' | grep -q 'consumes this document' \
  && ok "markdown asks about readers" || no "markdown asks about readers"
tsout=$(run s-ts2 Edit "$WORK/real.ts")
printf '%s' "$tsout" | jq -re '.hookSpecificOutput.permissionDecisionReason' | grep -q 'imports, requires' \
  && ok "code asks about importers" || no "code asks about importers"

echo "-- notebook payload --"
nbout=$(printf '{"session_id":"s-nb","tool_name":"NotebookEdit","tool_input":{"notebook_path":"%s"}}' "$WORK/real.ts" \
  | env HOME="$FAKEHOME" sh "$HOOK" 2>/dev/null)
denies "$nbout" && ok "notebook_path is read" || no "notebook_path is read"

echo "-- session budget --"
S=s-cap
i=0
while [ $i -lt 12 ]; do
  printf 'x\n' > "$WORK/cap$i.ts"
  run $S Edit "$WORK/cap$i.ts" >/dev/null
  i=$((i+1))
done
printf 'x\n' > "$WORK/cap-last.ts"
allows "$(run $S Edit "$WORK/cap-last.ts")" && ok "gate goes quiet past the budget" || no "gate goes quiet past the budget"
# A file already mid-flight still gets its second gate even at the cap.
denies "$(run $S Edit "$WORK/cap0.ts" "$EMPTYTR")" && ok "in-flight file still resolves" || no "in-flight file still resolves"

echo "-- never writes outside the cache --"
find "$FAKEHOME" -type f ! -path "*/cache/edit-gate/*" ! -name '.edit-gate-off' 2>/dev/null | grep -q . \
  && no "touched something outside the cache" || ok "state confined to cache/edit-gate"

echo "-- exit codes --"
bad=0
for t in Edit Write NotebookEdit Bash Read; do
  run s-rc $t "$WORK/real.ts" >/dev/null || bad=$((bad+1))
done
raw '' >/dev/null; [ $? = 0 ] || bad=$((bad+1))
raw 'garbage' >/dev/null; [ $? = 0 ] || bad=$((bad+1))
[ $bad -eq 0 ] && ok "every path exits 0" || no "$bad paths exited non-zero"

echo
[ $FAIL -eq 0 ] && echo "PASS" || echo "FAILURES PRESENT"
exit $FAIL
