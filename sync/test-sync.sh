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

# === APPEND NEW ASSERTIONS ABOVE THIS LINE ===
[ "$FAIL" -eq 0 ] && echo "PASS" || echo "FAILURES"; exit "$FAIL"
