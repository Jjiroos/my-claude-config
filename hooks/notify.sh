#!/usr/bin/env bash
# Notification (permission_prompt, idle_prompt) : notification Windows Terminal (OSC 9)
# quand Claude attend une validation ou une réponse. Un hook n'a pas de terminal :
# Claude Code écrit lui-même la séquence renvoyée dans terminalSequence.
set -uo pipefail

message="$(jq -r '.message // "Claude attend ta réponse"' 2>/dev/null)" || exit 0
message="${message//[$'\a\033']/}"
message="${message//$'\n'/ }"

sequence="$(printf '\033]9;Claude Code : %s\007' "$message")"
jq -nc --arg seq "$sequence" '{terminalSequence: $seq}'
