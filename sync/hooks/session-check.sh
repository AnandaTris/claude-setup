#!/bin/sh
# session-check.sh — SessionStart guard for the Claude/Codex config sync.
#
# Runs the drift report once per session and prints it only when something is
# actually out of sync, so a healthy tree costs nothing in context. Never fails
# the session: a broken sync setup should not stop work from starting.
set -u

report=$(sh "$HOME/.claude/sync/sync.sh" --check 2>&1) && exit 0

printf 'Claude/Codex config is out of sync:\n%s\n\nRun `/sync-agents` to regenerate.\n' "$report"
exit 0
