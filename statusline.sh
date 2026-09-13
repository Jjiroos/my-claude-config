#!/usr/bin/env bash
# Claude Code status line - model | level | remaining tokens

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // .model.id // "?"')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')

# Remaining tokens
remaining=""
if [ -n "$used_pct" ] && [ -n "$ctx_size" ]; then
  remaining=$(echo "$used_pct $ctx_size" | awk '{r = $2 * (1 - $1/100); if (r >= 1000) printf "%.0fk", r/1000; else printf "%.0f", r}')
fi

# Level (context used %)
level=""
if [ -n "$used_pct" ]; then
  level=$(printf "%.0f" "$used_pct")
fi

# Output
out="$model"
[ -n "$level" ] && out="$out | ${level}%"
[ -n "$remaining" ] && out="$out | ${remaining} tokens"

printf "%s\n" "$out"
