#!/bin/sh
# Verification harness for the Claude/Codex config sync.
set -u
SYNC="$HOME/.claude/sync"; FAIL=0
ok(){ printf '  ok   %s\n' "$1"; }
no(){ printf '  FAIL %s\n' "$1"; FAIL=1; }

echo "-- renderer --"
T=$(mktemp -d)
printf 'OTHER=Codex\nREVIEW=/review\n' > "$T/vars"
printf 'Ask {{OTHER}} via {{REVIEW}}.\n' > "$T/core.md"
printf '# Tail\n' > "$T/overlay.md"
sh "$SYNC/sync.sh" render "$T/vars" "$T/core.md" "$T/overlay.md" "$T/out.md" 2>/dev/null
grep -q 'Ask Codex via /review.' "$T/out.md" 2>/dev/null && ok "substitutes vars" || no "substitutes vars"
grep -q '^# Tail' "$T/out.md" 2>/dev/null && ok "appends overlay" || no "appends overlay"
head -1 "$T/out.md" 2>/dev/null | grep -q 'GENERATED' && ok "writes header" || no "writes header"

printf 'Hello {{MISSING}}.\n' > "$T/bad.md"
rm -f "$T/bad-out.md"
sh "$SYNC/sync.sh" render "$T/vars" "$T/bad.md" "$T/overlay.md" "$T/bad-out.md" 2>/dev/null \
  && no "aborts on unbound var" || ok "aborts on unbound var"
[ -f "$T/bad-out.md" ] && no "writes nothing on abort" || ok "writes nothing on abort"
rm -rf "$T"

echo "-- generated instruction files --"
sh "$SYNC/sync.sh" apply >/dev/null 2>&1
grep -q '^# Ultracode' "$HOME/.claude/CLAUDE.md" && ok "claude has Ultracode" || no "claude has Ultracode"
grep -q '^# Ultracode' "$HOME/.codex/AGENTS.md" && no "codex omits Ultracode" || ok "codex omits Ultracode"
grep -q 'gstack-review' "$HOME/.codex/AGENTS.md" && ok "codex uses gstack names" || no "codex uses gstack names"
grep -q '/review' "$HOME/.claude/CLAUDE.md" && ok "claude uses slash names" || no "claude uses slash names"
grep -lq '{{' "$HOME/.claude/CLAUDE.md" "$HOME/.codex/AGENTS.md" 2>/dev/null \
  && no "no stray template tokens" || ok "no stray template tokens"
grep -q '^# Secrets' "$HOME/.codex/AGENTS.md" && ok "codex now carries Secrets" || no "codex now carries Secrets"
grep -q '^# Model allocation' "$HOME/.codex/AGENTS.md" && no "codex omits Model allocation" || ok "codex omits Model allocation"

echo "-- shared hook scripts --"
for h in block-secret-reads.sh marcel-detector.sh; do
  [ -L "$HOME/.claude/hooks/$h" ] && ok "claude $h is a symlink" || no "claude $h is a symlink"
done
[ -L "$HOME/.codex/hooks/block-secret-reads.sh" ] && ok "codex guard is a symlink" || no "codex guard is a symlink"
a=$(wc -c < "$HOME/.claude/hooks/block-secret-reads.sh" 2>/dev/null || echo 0)
b=$(wc -c < "$HOME/.codex/hooks/block-secret-reads.sh" 2>/dev/null || echo 0)
[ "$a" = "$b" ] && [ "$a" -gt 0 ] && ok "guards byte-identical ($a)" || no "guards byte-identical ($a vs $b)"
grep -q UserPromptSubmit "$HOME/.codex/hooks.json" 2>/dev/null && ok "codex wires marcel-detector" || no "codex wires marcel-detector"

echo "-- codex skill links --"
sh "$SYNC/sync.sh" link-skills >/dev/null 2>&1 || no "link-skills exits clean"
GAP='_gstack-command connect-chrome docx emil-design-eng expo-native-ui
expo-router expo-web-to-native find-skills gemini-media higgsfield-generate
higgsfield-soul-id higgsfield-video-explainer humanizer impeccable pptx
react-native-best-practices xlsx'
bad=0; cnt=0
for s in $GAP; do
  cnt=$((cnt+1))
  [ -L "$HOME/.codex/skills/$s" ] || { bad=$((bad+1)); continue; }
  [ -s "$HOME/.codex/skills/$s/SKILL.md" ] || bad=$((bad+1))
done
[ "$bad" -eq 0 ] && ok "all $cnt gap skills linked and readable" || no "$bad of $cnt gap skills bad"
# The outside-voice pair must stay asymmetric: each host sees only its own.
[ -e "$HOME/.codex/skills/codex" ] && no "codex skill not pushed to codex" || ok "codex skill not pushed to codex"
[ -e "$HOME/.claude/skills/gstack-claude" ] && no "gstack-claude stays codex-only" || ok "gstack-claude stays codex-only"
# Idempotent: a second run must not fail or duplicate.
sh "$SYNC/sync.sh" link-skills >/dev/null 2>&1 && ok "link-skills is idempotent" || no "link-skills is idempotent"

echo "-- drift check --"
sh "$SYNC/sync.sh" apply >/dev/null 2>&1
sh "$SYNC/sync.sh" --check >/dev/null 2>&1 && ok "clean tree exits 0" || no "clean tree exits 0"

# Tamper with a generated file; --check must notice and must not repair it.
SAVE=$(mktemp)
cp "$HOME/.claude/CLAUDE.md" "$SAVE"
printf '\nhand-edited line that apply would erase\n' >> "$HOME/.claude/CLAUDE.md"
BEFORE=$(shasum < "$HOME/.claude/CLAUDE.md")
OUT=$(sh "$SYNC/sync.sh" --check 2>&1); RC=$?
[ "$RC" -ne 0 ] && ok "drift exits nonzero" || no "drift exits nonzero"
printf '%s' "$OUT" | grep -q 'CLAUDE.md' && ok "names the drifted file" || no "names the drifted file"
[ "$(shasum < "$HOME/.claude/CLAUDE.md")" = "$BEFORE" ] && ok "check is read-only" || no "check is read-only"
cp "$SAVE" "$HOME/.claude/CLAUDE.md"; rm -f "$SAVE"
sh "$SYNC/sync.sh" --check >/dev/null 2>&1 && ok "restored tree exits 0" || no "restored tree exits 0"

# The audit must surface the fact that Codex has no deny-rule mechanism.
sh "$SYNC/sync.sh" --check 2>&1 | grep -qi 'deny' && ok "audit reports deny posture" || no "audit reports deny posture"

echo "-- drift hook --"
H="$SYNC/hooks/config-drift.sh"
[ -x "$H" ] && ok "hook is executable" || no "hook is executable"

# An edit somewhere unrelated must be ignored entirely.
OUT=$(printf '%s' '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/unrelated.txt"}}' | sh "$H" 2>&1)
[ -z "$OUT" ] && ok "ignores unrelated paths" || no "ignores unrelated paths (got: $OUT)"

# A clean synced file must also stay quiet.
sh "$SYNC/sync.sh" apply >/dev/null 2>&1
OUT=$(printf '{"tool_name":"Edit","tool_input":{"file_path":"%s/core.md"}}' "$SYNC" | sh "$H" 2>&1)
[ -z "$OUT" ] && ok "quiet when in sync" || no "quiet when in sync (got: $OUT)"

# Drift on a watched path must be reported.
SAVE=$(mktemp); cp "$HOME/.claude/CLAUDE.md" "$SAVE"
printf '\ndrift\n' >> "$HOME/.claude/CLAUDE.md"
OUT=$(printf '{"tool_name":"Edit","tool_input":{"file_path":"%s/core.md"}}' "$SYNC" | sh "$H" 2>&1)
printf '%s' "$OUT" | grep -qi 'sync' && ok "reports drift on watched path" || no "reports drift on watched path"
printf '%s' "$OUT" | grep -q '"hookEventName"' && ok "emits hook JSON" || no "emits hook JSON"
cp "$SAVE" "$HOME/.claude/CLAUDE.md"; rm -f "$SAVE"

echo "-- session hook --"
SH="$SYNC/hooks/session-check.sh"
[ -x "$SH" ] && ok "session hook executable" || no "session hook executable"
sh "$SYNC/sync.sh" apply >/dev/null 2>&1
OUT=$(sh "$SH" 2>&1); RC=$?
[ -z "$OUT" ] && ok "silent when in sync" || no "silent when in sync (got: $OUT)"
[ "$RC" -eq 0 ] && ok "exits 0 when in sync" || no "exits 0 when in sync"
SAVE=$(mktemp); cp "$HOME/.claude/CLAUDE.md" "$SAVE"; printf '\ndrift\n' >> "$HOME/.claude/CLAUDE.md"
OUT=$(sh "$SH" 2>&1); RC=$?
printf '%s' "$OUT" | grep -qi 'out of sync' && ok "reports drift at session start" || no "reports drift at session start"
[ "$RC" -eq 0 ] && ok "never fails the session" || no "never fails the session"
cp "$SAVE" "$HOME/.claude/CLAUDE.md"; rm -f "$SAVE"

echo "-- settings wiring --"
S="$HOME/.claude/settings.json"
jq -e . "$S" >/dev/null 2>&1 && ok "settings.json is valid json" || no "settings.json is valid json"
jq -e '.hooks.SessionStart[]?.hooks[]? | select(.command | test("session-check"))' "$S" >/dev/null 2>&1 \
  && ok "SessionStart wired" || no "SessionStart wired"
jq -e '.hooks.PostToolUse[]? | select(.matcher | test("Edit|Write"))' "$S" >/dev/null 2>&1 \
  && ok "PostToolUse scoped to edits" || no "PostToolUse scoped to edits"
jq -e '.permissions.deny | map(select(test("Keys";"i"))) | length >= 12' "$S" >/dev/null 2>&1 \
  && ok "Keys deny rules intact" || no "Keys deny rules intact"

echo "-- no competing instruction files --"
# Stale copies here would be loaded alongside the generated ones and silently
# reintroduce the drift this whole thing exists to remove.
[ -e "$HOME/.claude/AGENTS.md" ] && no "~/.claude/AGENTS.md stays retired" || ok "~/.claude/AGENTS.md stays retired"
[ -e "$HOME/AGENTS.md" ] && no "~/AGENTS.md stays retired" || ok "~/AGENTS.md stays retired"
[ -f "$HOME/.codex/AGENTS.md" ] && ok "codex keeps its generated AGENTS.md" || no "codex keeps its generated AGENTS.md"

echo "-- versioned codex config --"
CX="$SYNC/codex"
[ -f "$CX/hooks.json" ] && ok "hooks.json is in the repo" || no "hooks.json is in the repo"
[ -L "$HOME/.codex/hooks.json" ] && ok "codex hooks.json is a symlink" || no "codex hooks.json is a symlink"
jq -e . "$HOME/.codex/hooks.json" >/dev/null 2>&1 && ok "codex reads valid json" || no "codex reads valid json"
jq -e '.hooks.PreToolUse' "$HOME/.codex/hooks.json" >/dev/null 2>&1 && ok "guard still wired" || no "guard still wired"
jq -e '.hooks.UserPromptSubmit' "$HOME/.codex/hooks.json" >/dev/null 2>&1 && ok "marcel still wired" || no "marcel still wired"

[ -f "$CX/config.settings.toml" ] && ok "settings snapshot exists" || no "settings snapshot exists"
# The snapshot must hold only hand-authored scalars — no project paths, no state.
grep -qE '^\[projects\.|^\[hooks\.state|^\[plugins\.' "$CX/config.settings.toml" 2>/dev/null \
  && no "snapshot excludes machine churn" || ok "snapshot excludes machine churn"
# overlay.codex.md promises xhigh is the default; config must actually say so.
grep -q 'model_reasoning_effort = "xhigh"' "$CX/config.settings.toml" 2>/dev/null \
  && ok "snapshot pins xhigh effort" || no "snapshot pins xhigh effort"

# Drift between the snapshot and the live config must be reported.
sh "$SYNC/sync.sh" --check 2>&1 | grep -q 'codex settings' && ok "check reports settings" || no "check reports settings"

echo "-- nothing secret is versioned --"
# auth.json holds the OAuth tokens and must never be copied into the repo.
[ -e "$CX/auth.json" ] && no "auth.json never enters the repo" || ok "auth.json never enters the repo"
HITS=""
for f in $(git -C "$HOME/.claude" ls-files 'sync/codex/*' 2>/dev/null); do
  [ -f "$HOME/.claude/$f" ] || continue
  grep -qEi 'sk-[A-Za-z0-9]{16}|ghp_[A-Za-z0-9]{20}|BEGIN [A-Z ]*PRIVATE KEY|eyJ[A-Za-z0-9_-]{30}' \
    "$HOME/.claude/$f" && HITS="$HITS $f"
done
[ -z "$HITS" ] && ok "tracked codex files carry no credentials" || no "credentials found in:$HITS"

# === APPEND NEW ASSERTIONS ABOVE THIS LINE ===
[ "$FAIL" -eq 0 ] && echo "PASS" || echo "FAILURES"; exit "$FAIL"
