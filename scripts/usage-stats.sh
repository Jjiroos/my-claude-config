#!/usr/bin/env bash
# usage-stats.sh — usage réel de Claude Code d'après les transcripts et l'historique locaux.
# Usage : scripts/usage-stats.sh [AAAA-MM-JJ]   (depuis cette date ; défaut : tout ce qui est conservé)
# Sortie : Markdown, prêt à coller dans un audit. Les transcripts plus vieux que
# cleanupPeriodDays ont été supprimés par Claude Code : la période réelle peut être plus courte.
set -euo pipefail

TARGET="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SINCE="${1:-1970-01-01}"
since_ms="$(( $(date -d "$SINCE" +%s) * 1000 ))"
# Nombre maximal de lignes affichées par tableau.
TOP=15

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mapfile -t transcripts < <(find "$TARGET/projects" -name '*.jsonl' -newermt "$SINCE" 2>/dev/null | sort)
: >"$tmp/tools.jsonl"
if (( ${#transcripts[@]} > 0 )); then
  jq -c --arg since "$SINCE" '
    select(.type == "assistant" and (.timestamp // "") >= $since)
    | .message.content[]? | select(.type == "tool_use")
    | {name, skill: .input.skill, agent: .input.subagent_type, model: .input.model}
  ' "${transcripts[@]}" >"$tmp/tools.jsonl" 2>/dev/null || true
fi

# Lit une valeur par ligne sur stdin et l'affiche en tableau « valeur | nombre ».
table() {
  printf '| %s | Nombre |\n|---|---|\n' "$1"
  sort | uniq -c | sort -rn | head -n "${2:-$TOP}" |
    awk '{ count = $1; $1 = ""; sub(/^ /, ""); printf "| %s | %d |\n", $0, count }'
}

history_since() {
  jq -r --argjson since "$since_ms" "select((.timestamp // 0) >= \$since) | $1" "$TARGET/history.jsonl" 2>/dev/null || true
}

projects_count="$(printf '%s\n' "${transcripts[@]}" | sed '/^$/d' | xargs -r -n1 dirname | sort -u | wc -l)"

echo "# Usage de Claude Code depuis $SINCE"
echo
echo "- Transcripts : ${#transcripts[@]}, sur $projects_count projet(s)"
echo "- Appels d'outils : $(wc -l <"$tmp/tools.jsonl")"
echo "- Prompts saisis : $(history_since '.display // empty' | wc -l)"
echo
echo "## Outils"
echo
jq -r '.name' "$tmp/tools.jsonl" | table "Outil"
echo
echo "## Skills invoqués par Claude"
echo
jq -r 'select(.name == "Skill") | .skill // "?"' "$tmp/tools.jsonl" | table "Skill"
echo
echo "## Sous-agents"
echo
jq -r 'select(.name == "Agent" or .name == "Task") | "\(.agent // "general-purpose") · \(.model // "modèle hérité")"' "$tmp/tools.jsonl" |
  table "Type · modèle"
echo
echo "## Commandes tapées"
echo
history_since '.display // empty | select(startswith("/")) | split(" ")[0]' | table "Commande" 25
echo
echo "## Corrections probables (à relire)"
echo
history_since '.display // empty | select(startswith("/") | not) | gsub("\n"; " ") | .[0:180]' |
  grep -iE "jamais|sans mention|supprime|retiens|note de|attention|pourquoi tu|j'ai dit|au lieu de|ne pousse|ne fais pas|arrête de" |
  head -n 30 | sed 's/^/- /' || true
echo
echo "## Mémoire native par projet"
echo
echo "| Projet | Entrées | dont feedback |"
echo "|---|---|---|"
for dir in "$TARGET"/projects/*/memory; do
  [[ -d "$dir" ]] || continue
  entries="$(find "$dir" -name '*.md' ! -name MEMORY.md | wc -l)"
  feedback="$(grep -lE '^[[:space:]]*type:[[:space:]]*feedback' "$dir"/*.md 2>/dev/null | wc -l || true)"
  printf '| %s | %d | %d |\n' "$(basename "$(dirname "$dir")")" "$entries" "$feedback"
done
