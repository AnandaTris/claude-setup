#!/bin/sh
# config-drift.sh — PostToolUse guard for the Claude/Codex config sync.
#
# Claude Code matches PostToolUse hooks on tool NAME, not path, so this fires
# after every Edit/Write. It must therefore be cheap on the common case: read
# the path, and bail immediately unless the edit touched a synced config file.
# Only then does it pay for the full sync.sh --check.
set -u

SYNC="$HOME/.claude/sync"

# jq is the norm in these hooks, but a plain sed keeps the common path to one
# process instead of two.
path=$(sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
[ -n "$path" ] || exit 0

case "$path" in
  "$HOME"/.claude/sync/*|\
  "$HOME"/.claude/CLAUDE.md|\
  "$HOME"/.claude/settings.json|\
  "$HOME"/.codex/AGENTS.md|\
  "$HOME"/.codex/hooks.json|\
  "$HOME"/.codex/config.toml) ;;
  *) exit 0 ;;
esac

report=$(sh "$SYNC/sync.sh" --check 2>&1) && exit 0

# Drift found. Tell the model, don't block the edit — the fix may be mid-flight.
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":%s}}\n' \
  "$(printf '%s' "Claude/Codex config drift after editing $path:
$report

Run \`sh ~/.claude/sync/sync.sh apply\` to regenerate, or /sync-agents." |
     sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g' |
     awk 'BEGIN{printf "\""} {printf "%s%s", sep, $0; sep="\\n"} END{printf "\""}')"
exit 0
