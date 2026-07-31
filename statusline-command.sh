#!/bin/sh
# Claude Code status line: <model> · <effort> · <pwd> · <context %> · 5<5h %> · W<weekly %>
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
# Green is the resting state; it warms up as the window fills.
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

# Quota: labelled so the two windows stay distinguishable at a glance —
# "5" is the five-hour window, "W" the weekly one. Each gets its own base
# hue (cyan / magenta) so neither reads as context, but both still escalate
# to yellow and red, because a quota about to run out is the same kind of
# warning regardless of which window it belongs to.
quota_seg() {
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
  # Colon separates label from value: "595%" is unreadable, "5:95%" is not.
  printf '%s' "${dim}·${reset} ${_c}${_label}:${_int}%${reset}"
}

five_seg=$(quota_seg "$five" "five" '\033[0;36m')
week_seg=$(quota_seg "$week" "W" '\033[0;35m')

[ -n "$five_seg" ] && line="${line} ${five_seg}"
[ -n "$week_seg" ] && line="${line} ${week_seg}"

printf '%b\n' "$line"
