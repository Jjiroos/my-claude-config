#!/usr/bin/env bash
# install.sh — déploie my-claude-config dans ~/.claude : liens symboliques, plugins,
# et serveurs MCP de mcp/servers.json enregistrés en scope user.
# Idempotent : relancer après chaque modification. Ce qui occupait déjà une place
# gérée (fichier réel, autre lien) est déplacé dans ~/.claude/backups/, jamais supprimé.
# Options : --dry-run (affiche sans rien modifier), --no-plugins (saute les plugins).
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
BACKUP="$TARGET/backups/my-claude-config-$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false
WITH_PLUGINS=true

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --no-plugins) WITH_PLUGINS=false ;;
    *) echo "option inconnue : $arg" >&2; exit 2 ;;
  esac
done

run() {
  if $DRY_RUN; then
    printf '    (dry-run) %s\n' "$*"
  else
    "$@"
  fi
}

# Fait de $2 un lien vers $1 ; sauvegarde ce qui s'y trouvait si ce n'est pas déjà ce lien.
link() {
  local src="$1" dest="$2" rel="${2#"$TARGET"/}"
  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    printf '  = %s\n' "$rel"
    return
  fi
  if [[ -e "$dest" || -L "$dest" ]]; then
    run mkdir -p "$(dirname "$BACKUP/$rel")"
    run mv "$dest" "$BACKUP/$rel"
    printf '  ↪ %s sauvegardé dans %s\n' "$rel" "${BACKUP#"$TARGET"/}"
  fi
  run ln -s "$src" "$dest"
  printf '  ✓ %s\n' "$rel"
}

# Retire de $1 les liens qui pointent dans le dépôt vers une cible disparue.
prune() {
  local dir="$1" entry
  [[ -d "$dir" ]] || return 0
  for entry in "$dir"/*; do
    [[ -L "$entry" && ! -e "$entry" && "$(readlink "$entry")" == "$REPO"/* ]] || continue
    run rm "$entry"
    printf '  ✗ lien mort retiré : %s\n' "${entry#"$TARGET"/}"
  done
}

echo "→ Dépôt : $REPO"
echo "→ Cible : $TARGET"
if $DRY_RUN; then echo "→ Dry-run : aucune modification"; fi
run mkdir -p "$TARGET/skills"

echo "→ Fichiers"
for name in CLAUDE.md settings.json statusline.sh hooks; do
  link "$REPO/$name" "$TARGET/$name"
done

echo "→ Skills"
prune "$TARGET/skills"
for dir in "$REPO"/skills/*/; do
  name="$(basename "$dir")"
  link "$REPO/skills/$name" "$TARGET/skills/$name"
done

echo "→ Hook git du dépôt (pre-commit : check-drift)"
if [[ "$(git -C "$REPO" config --get core.hooksPath || true)" == ".githooks" ]]; then
  echo "  = core.hooksPath"
else
  run git -C "$REPO" config core.hooksPath .githooks
  echo "  ✓ core.hooksPath = .githooks"
fi

if $WITH_PLUGINS; then
  echo "→ Plugins (enabledPlugins de settings.json)"
  if ! command -v claude >/dev/null; then
    echo "  ⚠ CLI claude introuvable : relancer install.sh une fois Claude Code installé"
  else
    installed="$(claude plugin list 2>/dev/null || true)"
    while read -r plugin; do
      if grep -qF "$plugin" <<<"$installed"; then
        printf '  = %s\n' "$plugin"
      else
        run claude plugin install "$plugin"
        printf '  ✓ %s\n' "$plugin"
      fi
    done < <(jq -r '.enabledPlugins // {} | to_entries[] | select(.value) | .key' "$REPO/settings.json")
  fi
fi

echo "→ MCP (mcp/servers.json, scope user)"
if ! command -v claude >/dev/null; then
  echo "  ⚠ CLI claude introuvable : relancer install.sh une fois Claude Code installé"
else
  # Réenregistrement de ce qui est déjà en place : la déclaration du dépôt fait foi,
  # et la CLI n'expose pas les en-têtes d'un serveur enregistré, donc rien à comparer.
  registered="$(claude mcp list 2>/dev/null || true)"
  while IFS=$'\t' read -r name entry; do
    [[ -n "$name" ]] || continue
    if grep -q "^$name:" <<<"$registered"; then
      run claude mcp remove "$name" --scope user
      mark='↻'
    else
      mark='✓'
    fi
    run claude mcp add-json --scope user "$name" "$entry"
    printf '  %s %s\n' "$mark" "$name"
  done < <(jq -r '.mcpServers // {} | to_entries[] | "\(.key)\t\(.value | tojson)"' "$REPO/mcp/servers.json")
fi

echo "✓ Terminé. Redémarre Claude Code pour charger la config."
