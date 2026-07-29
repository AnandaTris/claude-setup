#!/bin/bash
# PreToolUse/Bash guard. Stops Claude from reading shell profiles, expanding
# secret-looking environment variables, or dumping the whole environment.
#
# Reads the hook payload on stdin. Prints a deny decision as JSON when a
# command is unsafe, otherwise stays silent. Always exits 0 — a non-zero exit
# would surface as a hook error rather than a clean block.

cmd=$(jq -r '.tool_input.command // ""')

deny() {
  jq -cn --arg reason "$1" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$reason}}'
  exit 0
}

# 1. Shell profiles hold exported keys, so their contents are off limits.
if printf '%s' "$cmd" | grep -qE '\.(zshrc|zshenv|zprofile|zlogin|bashrc|bash_profile|bash_login|profile)([^A-Za-z0-9_-]|$)'; then
  deny "Blocked: this command touches a shell profile file, which holds exported API keys. Ask the user to run it themselves."
fi

# 2. Secret variables. Strip the forms that reveal nothing — \${#VAR} (length),
# \${VAR:+x} / \${VAR:-x} (presence), and `-u VAR` (unset) — then treat any
# surviving mention of an uppercase key-shaped name as an attempt to read it.
# Uppercase only, so lowercase source-code searches like `grep api_key src/`
# still work.
safe=$(printf '%s' "$cmd" | sed -E \
  -e 's/\$\{#[A-Za-z0-9_]*(API_KEY|TOKEN|SECRET)[A-Za-z0-9_]*\}//g' \
  -e 's/\$\{[A-Za-z0-9_]*(API_KEY|TOKEN|SECRET)[A-Za-z0-9_]*:[+-][^}]*\}//g' \
  -e 's/-u[[:space:]]+[A-Za-z0-9_]*(API_KEY|TOKEN|SECRET)[A-Za-z0-9_]*//g')
if printf '%s' "$safe" | grep -qE '[A-Z0-9_]*(API_KEY|TOKEN|SECRET)[A-Z0-9_]*'; then
  deny "Blocked: this command references a secret variable. Use \${#VAR} for its length or \${VAR:+set} to check whether it is set."
fi

# 3. Whole-environment dumps, which would print every key at once.
if printf '%s' "$cmd" | grep -qE '(^|[;&|(]|[[:space:]])printenv([[:space:]]|$)'; then
  deny "Blocked: printenv would expose API keys. Ask for a specific non-secret variable instead."
fi
if printf '%s' "$cmd" | grep -qE '(^|[;&|(]|[[:space:]])(env|export -p|declare -p|set)[[:space:]]*(\||>|$)'; then
  deny "Blocked: this command dumps the environment, which would expose API keys. Name the specific non-secret variable instead."
fi

exit 0
