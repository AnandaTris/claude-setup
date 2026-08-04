#!/bin/bash
# ============================================================
#  MARCEL DETECTOR
#  Plays a random clip back whenever your prompt contains a
#  swear word. English + Indonesian. Silent no-op on anything
#  unexpected.
#
#  TO ADD MORE VOICE LINES:
#    Drop any .m4a / .mp3 / .wav into ~/.claude/sounds/marcel/
#    One is picked at random per swear. No code change needed.
#
#  TO DELETE THE WHOLE THING, run these three lines:
#
#    jq 'del(.hooks.UserPromptSubmit)' ~/.claude/settings.json > /tmp/s.json \
#      && mv /tmp/s.json ~/.claude/settings.json
#    rm ~/.claude/hooks/marcel-detector.sh
#    rm -rf ~/.claude/sounds/marcel
#
#  Then open /hooks once to reload. Everything for this feature
#  is named "marcel" — nothing else to hunt down.
# ============================================================

CLIPDIR="$HOME/.claude/sounds/marcel"
[[ -d "$CLIPDIR" ]] || exit 0
command -v afplay >/dev/null 2>&1 || exit 0

prompt=$(jq -r '.prompt // ""' 2>/dev/null | tr '[:upper:]' '[:lower:]')
[[ -n "$prompt" ]] || exit 0

# Stems: match with a leading word boundary, any suffix allowed
# (fucking, shitty, bitches, damned, anjingnya).
stems='fuck|shit|damn|bitch|bastard|asshole|arsehole|cunt|dickhead|bollock|wanker|twat|goddam|motherfuck|crap|piss|anjing|anjir|anjay|bangsat|kontol|memek|tolol|goblok|ngentot|bajingan|jancok|jancuk|kampret|brengsek|sialan|pantek'

# Whole words only — these are substrings of innocent words (assist, class,
# taiwan, setanggi) so both boundaries must hold.
whole='ass|arse|prick|wtf|stfu|fml|omfg|jfc|asu|babi|tai|taik|setan|puki'

grep -qE "(^|[^a-z])($stems)" <<<"$prompt" \
  || grep -qE "(^|[^a-z])($whole)([^a-z]|$)" <<<"$prompt" \
  || exit 0

# Pick one clip at random.
shopt -s nullglob
clips=("$CLIPDIR"/*.m4a "$CLIPDIR"/*.mp3 "$CLIPDIR"/*.wav)
(( ${#clips[@]} )) || exit 0

afplay "${clips[RANDOM % ${#clips[@]}]}"
exit 0
