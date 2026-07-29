#!/bin/sh
# Claude Code status line: <model> · <pwd> · <context %>
# Input: session JSON on stdin. Output: one line.
input=$(cat)

used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
effort=$(echo "$input" | jq -r '.effort.level // empty')
# The live working directory, so diving into a project folder is visible.
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // .workspace.project_dir // empty')

reset='\033[0m'
dim='\033[2m'

# Path relative to $HOME, minus one leading segment (the "~/").
case "$dir" in
  "$HOME") dir='~' ;;
  "$HOME"/*) dir="${dir#"$HOME"/}" ;;
esac

line=""
[ -n "$model" ] && line="${dim}${model}${reset}"
if [ -n "$effort" ]; then
  [ -n "$line" ] && line="${line} ${dim}·${reset} "
  line="${line}${dim}${effort}${reset}"
fi
if [ -n "$dir" ]; then
  [ -n "$line" ] && line="${line} ${dim}·${reset} "
  line="${line}${dim}${dir}${reset}"
fi

# Context: percent used only — "N% remaining" is just 100 minus this.
if [ -n "$used" ]; then
  used_int=$(printf '%.0f' "$used")
  if [ "$used_int" -ge 90 ]; then
    ctx_color='\033[0;31m'
  elif [ "$used_int" -ge 70 ]; then
    ctx_color='\033[0;33m'
  else
    ctx_color='\033[0;32m'
  fi

  [ -n "$line" ] && line="${line} ${dim}·${reset} "
  line="${line}${ctx_color}${used_int}%${reset}"
fi

printf '%b\n' "$line"
