#!/bin/sh
# Claude Code status line: <model> · <effort> · <pwd> · C:<ctx %> · F:<5h %> · W:<weekly %>
# Input: session JSON on stdin. Output: one line.
input=$(cat)

used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
effort=$(echo "$input" | jq -r '.effort.level // empty')
# The live working directory, so diving into a project folder is visible.
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // .workspace.project_dir // empty')
# Quota windows. seven_day is the "weekly" bucket.
five=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

reset='\033[0m'
dim='\033[2m'

# Path relative to $HOME, minus one leading segment (the "~/").
case "$dir" in
  "$HOME") dir='~' ;;
  "$HOME"/*) dir="${dir#"$HOME"/}" ;;
esac

# Each meter is labelled so the three stay distinguishable at a glance:
# C = context, F = five-hour quota, W = weekly quota. Each gets its own base
# hue so they never blur together, but all three escalate to yellow and red,
# because running out is the same kind of warning whichever meter it is.
# The colon matters: "F95%" reads as one number, "F:95%" does not.
meter() {
  _pct="$1"; _label="$2"; _base="$3"
  [ -z "$_pct" ] && return
  _int=$(printf '%.0f' "$_pct")
  if [ "$_int" -ge 90 ]; then
    _c='\033[0;31m'
  elif [ "$_int" -ge 70 ]; then
    _c='\033[0;33m'
  else
    _c="$_base"
  fi
  printf '%s' "${dim}·${reset} ${_c}${_label}:${_int}%${reset}"
}

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

ctx_seg=$(meter "$used" "C" '\033[0;32m')
five_seg=$(meter "$five" "F" '\033[0;36m')
week_seg=$(meter "$week" "W" '\033[0;35m')

[ -n "$ctx_seg" ]  && line="${line} ${ctx_seg}"
[ -n "$five_seg" ] && line="${line} ${five_seg}"
[ -n "$week_seg" ] && line="${line} ${week_seg}"

printf '%b\n' "$line"
