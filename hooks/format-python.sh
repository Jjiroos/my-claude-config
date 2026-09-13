#!/usr/bin/env bash
# PostToolUse Write|Edit : formate un fichier Python avec le ruff du projet.
# Seulement `ruff format` et le tri des imports (règle I) : un `ruff check --fix`
# complet supprimerait un import ajouté une édition avant son premier usage.
# No-op si le fichier n'est pas du Python, si aucun pyproject.toml parent ne
# configure ruff, ou si ruff n'est pas installé dans le projet.
set -uo pipefail

file="$(jq -r '.tool_input.file_path // empty' 2>/dev/null)" || exit 0
[[ "$file" == *.py && -f "$file" ]] || exit 0

dir="$(dirname "$file")"
while [[ "$dir" != "/" && "$dir" != "." ]]; do
  if [[ -f "$dir/pyproject.toml" ]] && grep -q '^\[tool\.ruff' "$dir/pyproject.toml"; then
    cd "$dir" || exit 0
    uv run --no-sync ruff format --quiet "$file" >/dev/null 2>&1 || exit 0
    uv run --no-sync ruff check --select I --fix --quiet "$file" >/dev/null 2>&1
    exit 0
  fi
  dir="$(dirname "$dir")"
done
exit 0
