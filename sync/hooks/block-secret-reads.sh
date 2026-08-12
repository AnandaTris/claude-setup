#!/bin/bash
# PreToolUse/Bash guard. Stops Claude from reading shell profiles or credential
# stores, expanding secret-looking environment variables, or dumping the whole
# environment.
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

# Names that look like they hold a credential. `_KEY` is the workhorse: it
# covers SERVICE_ROLE_KEY, ANON_KEY, INGEST_KEY and PRIVATE_KEY, none of which
# contain the literal API_KEY. Uppercase only, so lowercase source-code
# searches like `grep api_key src/` still work, and underscore-anchored, so
# SQL like `PRIMARY KEY` stays readable.
SECRET_NAME='[A-Z0-9_]*(_KEY|KEY_|TOKEN|SECRET|PASSWORD|PASSWD|CREDENTIAL|_DSN|BYPASS_CODE)[A-Z0-9_]*'

# 1. Shell profiles, shell history and credential stores all hold pasted keys.
if printf '%s' "$cmd" | grep -qE '\.(zshrc|zshenv|zprofile|zlogin|bashrc|bash_profile|bash_login|profile|zsh_history|bash_history|netrc|npmrc|pypirc)([^A-Za-z0-9_-]|$)'; then
  deny "Blocked: this command touches a shell profile or history file, which holds exported API keys. Ask the user to run it themselves."
fi
if printf '%s' "$cmd" | grep -qE '\.(aws/credentials|config/gcloud|ssh/id_|gnupg)'; then
  deny "Blocked: this command touches a credential store. Ask the user to run it themselves."
fi

# 8x_Internship/Keys is the user's own secret store — .p8 files, service-role
# keys, API keys pasted out of dashboards. Nothing in there is ever a
# legitimate read, and the FILENAMES leak too (which vendors hold which
# credentials), so listing it is blocked alongside reading it. Case-insensitive
# because macOS is: `keys` and `Keys` are the same directory.
if printf '%s' "$cmd" | grep -qiE '8x_?internship/keys(/|[^A-Za-z0-9_-]|$)'; then
  deny "Blocked: 8x_Internship/Keys is the user's secret store, off limits by standing instruction — no reading, listing, copying, grepping or moving it. Ask the user for the one specific value you need, or have them run the command themselves."
fi

# 2. Secret variables. Strip only the forms that cannot reveal the value:
# ${#VAR} (its length) and ${VAR:+word} / ${VAR+word} (presence — these expand
# to word, never to the value). EVERY other expansion leaks. ${VAR:-word} and
# ${VAR:=word} print the value whenever the variable IS set, which is how two
# real keys reached a transcript on 2026-08-04; ${VAR:0:4} and ${VAR#...} leak
# it in pieces; ${VAR} and $VAR leak it whole. The replacement word is
# [^}$]* so that ${VAR:+${VAR}} cannot smuggle a real expansion through.
safe=$(printf '%s' "$cmd" | sed -E \
  -e 's/\$\{#'"$SECRET_NAME"'\}//g' \
  -e 's/\$\{'"$SECRET_NAME"':?\+[^}$]*\}//g' \
  -e 's/-u[[:space:]]+'"$SECRET_NAME"'//g')
if printf '%s' "$safe" | grep -qE "$SECRET_NAME"; then
  deny "Blocked: this command references a secret variable. Only \${#VAR} (its length) and \${VAR:+set} (whether it is set) are permitted — \${VAR}, \${VAR:-...} and \${VAR:0:4} all print the value or part of it."
fi

# 3. Whole-environment dumps, which would print every key at once.
if printf '%s' "$cmd" | grep -qE '(^|[;&|(]|[[:space:]])printenv([[:space:]]|$)'; then
  deny "Blocked: printenv would expose API keys. Ask for a specific non-secret variable instead."
fi
if printf '%s' "$cmd" | grep -qE '(^|[;&|(]|[[:space:]])(env|export -p|declare -p|set)[[:space:]]*(\||>|$)'; then
  deny "Blocked: this command dumps the environment, which would expose API keys. Name the specific non-secret variable instead."
fi
# The same dump one language up: process.env / os.environ with no property
# access after it means the whole object is being printed.
if printf '%s' "$cmd" | grep -qE '(process\.env|os\.environ)([^.[A-Za-z_]|$)'; then
  deny "Blocked: printing the whole environment object would expose API keys. Read one specific non-secret variable instead."
fi

exit 0
