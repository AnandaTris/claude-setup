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

# === APPEND NEW ASSERTIONS ABOVE THIS LINE ===
[ "$FAIL" -eq 0 ] && echo "PASS" || echo "FAILURES"; exit "$FAIL"
