#!/bin/sh
# Verification harness for the context audit.
# Builds a synthetic ~/.claude with known contents and checks the measurements.
set -u
AUDIT="$HOME/.claude/skills/config-audit/audit.py"; FAIL=0
ok(){ printf '  ok   %s\n' "$1"; }
no(){ printf '  FAIL %s\n' "$1"; FAIL=1; }

[ -f "$AUDIT" ] || { echo "  FAIL no audit.py"; exit 1; }

SB="$HOME/.cache/config-audit-test.$$"
rm -rf "$SB"; mkdir -p "$SB/.claude/skills" "$SB/.claude/agents" "$SB/.claude/commands" \
  "$SB/.claude/plugins" || exit 1
trap 'rm -rf "$SB"' EXIT

mkskill() { # name, description, body-repeat-count
  mkdir -p "$SB/.claude/skills/$1"
  { printf -- '---\nname: %s\ndescription: %s\n---\n\n' "$1" "$2"
    i=0; while [ $i -lt "$3" ]; do printf 'body line %s of %s\n' "$i" "$1"; i=$((i+1)); done
  } > "$SB/.claude/skills/$1/SKILL.md"
}

mkboiler() { # name — carries an identical 12-line preamble
  mkdir -p "$SB/.claude/skills/$1"
  { printf -- '---\nname: %s\ndescription: short one.\n---\n\n' "$1"
    printf '## Preamble (run first)\n'
    i=0; while [ $i -lt 11 ]; do printf 'shared preamble line %s here\n' "$i"; i=$((i+1)); done
    printf 'unique tail for %s\n' "$1"
  } > "$SB/.claude/skills/$1/SKILL.md"
}

mkskill tiny "short description." 5
mkskill huge "also short." 900
mkskill wordy "$(i=0; while [ $i -lt 45 ]; do printf 'word%s ' "$i"; i=$((i+1)); done)" 10
mkboiler dup-a; mkboiler dup-b; mkboiler dup-c
printf -- '---\nname: ag\ndescription: an agent.\n---\n%s\n' \
  "$(i=0; while [ $i -lt 250 ]; do printf 'agent line %s\n' "$i"; i=$((i+1)); done)" \
  > "$SB/.claude/agents/ag.md"
printf -- '---\nname: cmd\ndescription: a command.\n---\nbody\n' > "$SB/.claude/commands/cmd.md"
printf 'global instructions here\n' > "$SB/.claude/CLAUDE.md"
printf '{"enabledPlugins":{"on-one@m":true,"off-one@m":false}}\n' > "$SB/.claude/settings.json"
printf '{"version":2,"plugins":{}}\n' > "$SB/.claude/plugins/installed_plugins.json"

J=$(HOME="$SB" python3 "$AUDIT" --json 2>"$SB/err") || { echo "  FAIL script errored"; cat "$SB/err"; exit 1; }
q() { printf '%s' "$J" | python3 -c "import json,sys;d=json.load(sys.stdin);print(eval(sys.argv[1],{},{'d':d}))" "$1" 2>/dev/null; }

echo "-- discovery --"
[ "$(q "d['counts'].get('skill')")" = 6 ] && ok "finds all 6 skills" || no "finds all 6 skills (got $(q "d['counts'].get('skill')"))"
[ "$(q "d['counts'].get('agent')")" = 1 ] && ok "finds the agent" || no "finds the agent"
[ "$(q "d['counts'].get('command')")" = 1 ] && ok "finds the command" || no "finds the command"

echo "-- always-on accounting --"
[ "$(q "'CLAUDE.md (global)' in d['always_on']")" = True ] && ok "counts CLAUDE.md" || no "counts CLAUDE.md"
[ "$(q "d['always_on_total'] > 0")" = True ] && ok "total is positive" || no "total is positive"
[ "$(q "d['always_on_total'] == sum(d['always_on'].values())")" = True ] \
  && ok "total equals its parts" || no "total equals its parts"
# A long body must NOT inflate always-on. That distinction is the whole point.
[ "$(q "d['always_on_total'] < 2000")" = True ] \
  && ok "900-line body stays out of always-on" || no "900-line body leaked into always-on"

echo "-- thresholds --"
[ "$(q "[b['name'] for b in d['bloated_descriptions']] == ['wordy']")" = True ] \
  && ok "flags only the 45-word description" || no "flags only the 45-word description"
[ "$(q "'huge' in [h['name'] for h in d['heavy_bodies']]")" = True ] \
  && ok "flags the 900-line skill" || no "flags the 900-line skill"
[ "$(q "'tiny' in [h['name'] for h in d['heavy_bodies']]")" = False ] \
  && ok "leaves the small skill alone" || no "leaves the small skill alone"
[ "$(q "'ag' in [h['name'] for h in d['heavy_bodies']]")" = True ] \
  && ok "agents use the lower line threshold" || no "agents use the lower line threshold"

echo "-- duplication --"
[ "$(q "d['duplication']['files']")" = 3 ] \
  && ok "spots the 3 boilerplate twins" || no "spots the 3 boilerplate twins (got $(q "d['duplication']['files']"))"
[ "$(q "sorted(x['name'] for x in d['duplication']['worst']) == ['dup-a','dup-b','dup-c']")" = True ] \
  && ok "names exactly the duplicating skills" || no "names exactly the duplicating skills"
[ "$(q "d['duplication']['avg_per_skill'] > 0")" = True ] \
  && ok "reports a per-invocation figure" || no "reports a per-invocation figure"
[ "$(q "d['duplication']['total'] >= d['duplication']['avg_per_skill']")" = True ] \
  && ok "total is not below the average" || no "total is not below the average"

echo "-- plugins --"
[ "$(q "d['enabled_plugins']")" = "['on-one@m']" ] && ok "lists enabled" || no "lists enabled"
[ "$(q "d['disabled_plugins']")" = "['off-one@m']" ] && ok "lists disabled" || no "lists disabled"

echo "-- robustness --"
printf 'no frontmatter at all\n' > "$SB/.claude/skills/tiny/SKILL.md"
HOME="$SB" python3 "$AUDIT" --json >/dev/null 2>&1 && ok "survives missing frontmatter" || no "survives missing frontmatter"
printf -- '---\nname: broken\ndescription: unterminated\n' > "$SB/.claude/skills/huge/SKILL.md"
HOME="$SB" python3 "$AUDIT" --json >/dev/null 2>&1 && ok "survives unterminated frontmatter" || no "survives unterminated frontmatter"
rm -rf "$SB/.claude/skills"
HOME="$SB" python3 "$AUDIT" >/dev/null 2>&1 && ok "survives having no skills" || no "survives having no skills"
rm -f "$SB/.claude/settings.json"
HOME="$SB" python3 "$AUDIT" >/dev/null 2>&1 && ok "survives missing settings.json" || no "survives missing settings.json"

echo "-- read-only --"
BEFORE=$(find "$SB" -type f | sort | xargs shasum 2>/dev/null | shasum)
HOME="$SB" python3 "$AUDIT" >/dev/null 2>&1
AFTER=$(find "$SB" -type f | sort | xargs shasum 2>/dev/null | shasum)
[ "$BEFORE" = "$AFTER" ] && ok "audit writes nothing" || no "audit modified files"

echo
[ $FAIL -eq 0 ] && echo "PASS" || echo "FAILURES PRESENT"
exit $FAIL
