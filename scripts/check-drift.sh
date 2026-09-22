#!/usr/bin/env bash
# check-drift.sh — vérifie que le README, le dépôt et ~/.claude disent la même chose.
# --repo-only : ignore l'état déployé dans ~/.claude (mode pre-commit).
# Code de sortie : 0 si aligné, 1 s'il existe au moins une dérive.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
REPO_ONLY=false
[[ "${1:-}" == "--repo-only" ]] && REPO_ONLY=true
# Plafond de description d'un skill dans le listing de Claude Code.
MAX_DESCRIPTION_CHARS=1536
# Taille cible de CLAUDE.md recommandée par la doc Claude Code.
MAX_CLAUDE_MD_LINES=200

drifts=0
drift() {
  printf '  ✗ %s\n' "$*"
  drifts=$((drifts + 1))
}

# Premier nom entre backticks de chaque ligne de tableau de la section « ## <titre> » du README.
readme_names() {
  awk -v title="$1" '
    /^## / { in_section = ($0 == "## " title); next }
    in_section && /^\| `/ { split($0, parts, "`"); print parts[2] }
  ' "$REPO/README.md"
}

# compare <objet> <source documentaire> <noms réels> <noms documentés>
compare() {
  local kind="$1" source="$2" actual="$3" documented="$4" name
  while read -r name; do
    [[ -n "$name" ]] && drift "$kind « $name » présent dans le dépôt, absent de $source"
  done < <(comm -23 <(sort -u <<<"$actual") <(sort -u <<<"$documented"))
  while read -r name; do
    [[ -n "$name" ]] && drift "$kind « $name » cité dans $source, absent du dépôt"
  done < <(comm -13 <(sort -u <<<"$actual") <(sort -u <<<"$documented"))
}

frontmatter_field() {
  awk -v key="$2" '
    /^---$/ { n++; next }
    n == 1 && index($0, key ":") == 1 { sub("^" key ":[[:space:]]*", ""); print; exit }
  ' "$1"
}

echo "→ settings.json"
jq empty "$REPO/settings.json" 2>/dev/null || drift "settings.json n'est pas un JSON valide"

echo "→ Skills"
skills="$(find "$REPO/skills" -mindepth 1 -maxdepth 1 -type d -printf '%f\n')"
compare "skill" "README § Skills" "$skills" "$(readme_names Skills)"
while read -r name; do
  file="$REPO/skills/$name/SKILL.md"
  if [[ ! -f "$file" ]]; then
    drift "skill $name : SKILL.md absent"
    continue
  fi
  front_name="$(frontmatter_field "$file" name)"
  [[ "$front_name" == "$name" ]] || drift "skill $name : name « $front_name » différent du nom du dossier"
  description="$(frontmatter_field "$file" description)"
  [[ -n "$description" ]] || drift "skill $name : description absente"
  (( ${#description} <= MAX_DESCRIPTION_CHARS )) || drift "skill $name : description de ${#description} caractères (plafond $MAX_DESCRIPTION_CHARS)"
done <<<"$skills"

echo "→ Hooks"
hook_files="$(find "$REPO/hooks" -maxdepth 1 -type f -name '*.sh' -printf '%f\n')"
hook_refs="$(jq -r '.hooks // {} | .[][] | .hooks[] | .command' "$REPO/settings.json" | grep -oE '[a-z0-9-]+\.sh')"
compare "hook" "settings.json" "$hook_files" "$hook_refs"
compare "hook" "README § Hooks" "$hook_files" "$(readme_names Hooks)"

echo "→ Plugins"
plugins="$(jq -r '.enabledPlugins // {} | to_entries[] | select(.value) | .key' "$REPO/settings.json")"
compare "plugin" "README § Plugins" "$plugins" "$(readme_names Plugins)"
# shellcheck disable=SC2016 # les backticks du motif sont littéraux
while read -r reference; do
  [[ -n "$reference" ]] || continue
  grep -q "^${reference%%:*}@" <<<"$plugins" || drift "CLAUDE.md cite $reference, mais le plugin ${reference%%:*} n'est pas activé"
done < <(grep -oE '`[a-z0-9-]+:[a-z0-9-]+`' "$REPO/CLAUDE.md" | tr -d '`' | sort -u)

echo "→ MCP"
jq empty "$REPO/mcp/servers.json" 2>/dev/null || drift "mcp/servers.json n'est pas un JSON valide"
mcp_servers="$(jq -r '.mcpServers // {} | keys[]' "$REPO/mcp/servers.json" 2>/dev/null)"
compare "serveur MCP" "README § MCP" "$mcp_servers" "$(readme_names MCP)"

echo "→ CLAUDE.md"
lines="$(wc -l <"$REPO/CLAUDE.md")"
(( lines <= MAX_CLAUDE_MD_LINES )) || drift "CLAUDE.md : $lines lignes (cible ≤ $MAX_CLAUDE_MD_LINES)"

if command -v shellcheck >/dev/null; then
  echo "→ shellcheck"
  shellcheck "$REPO/install.sh" "$REPO"/hooks/*.sh "$REPO"/scripts/*.sh "$REPO/.githooks/pre-commit" "$REPO/statusline.sh" >/dev/null ||
    drift "shellcheck signale des problèmes (relancer shellcheck pour le détail)"
fi

if ! $REPO_ONLY; then
  echo "→ Déploiement ($TARGET)"
  for name in CLAUDE.md settings.json statusline.sh hooks; do
    [[ "$(readlink "$TARGET/$name" 2>/dev/null)" == "$REPO/$name" ]] ||
      drift "$TARGET/$name ne pointe pas vers le dépôt (lancer install.sh)"
  done
  while read -r name; do
    [[ "$(readlink "$TARGET/skills/$name" 2>/dev/null)" == "$REPO/skills/$name" ]] ||
      drift "skill $name non déployé (lancer install.sh)"
  done <<<"$skills"
  for entry in "$TARGET"/skills/*; do
    if [[ -L "$entry" && ! -e "$entry" ]]; then
      drift "lien mort : $entry"
    fi
  done

  echo "→ MCP enregistrés"
  if command -v claude >/dev/null; then
    registered="$(claude mcp list 2>/dev/null || true)"
    while read -r name; do
      [[ -n "$name" ]] || continue
      grep -q "^$name:" <<<"$registered" || drift "serveur MCP $name non enregistré (lancer install.sh)"
    done <<<"$mcp_servers"
  fi
  # Une variable manquante ne casse pas le chargement : Claude Code envoie le ${VAR} littéral
  # au serveur, qui répond 401. Mieux vaut le voir ici.
  # shellcheck disable=SC2016 # le motif ${VAR} cherché est littéral
  while read -r var; do
    [[ -n "${!var:-}" ]] || drift "variable $var référencée par mcp/servers.json, absente de l'environnement"
  done < <(grep -oE '\$\{[A-Z_][A-Z0-9_]*\}' "$REPO/mcp/servers.json" | tr -d '${}' | sort -u)
fi

if (( drifts == 0 )); then
  echo "✓ Aucune dérive"
  exit 0
fi
echo "✗ $drifts dérive(s)"
exit 1
