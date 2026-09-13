#!/usr/bin/env bash
# test-hooks.sh — rejoue des entrées JSON d'exemple sur chaque hook et vérifie leur comportement.
# Les phrases de clôture viennent de mon historique réel.
# Code de sortie : 0 si tout passe, 1 sinon.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS="$REPO/hooks"
failures=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

pass() { printf '  ✓ %s\n' "$1"; }
fail() {
  printf '  ✗ %s\n' "$1"
  failures=$((failures + 1))
}

# expect_silent <description> <hook> <entrée>
expect_silent() {
  local out code
  out="$(printf '%s' "$3" | "$HOOKS/$2" 2>&1)"
  code=$?
  if [[ $code -eq 0 && -z "$out" ]]; then pass "$1"; else fail "$1 (code $code, sortie : ${out:0:120})"; fi
}

# expect_json <description> <hook> <entrée> <filtre jq qui doit valoir true>
expect_json() {
  local out code
  out="$(printf '%s' "$3" | "$HOOKS/$2" 2>/dev/null)"
  code=$?
  if [[ $code -eq 0 ]] && jq -e "$4" <<<"$out" >/dev/null 2>&1; then pass "$1"; else fail "$1 (code $code, sortie : ${out:0:120})"; fi
}

prompt_input() { jq -nc --arg p "$1" '{hook_event_name: "UserPromptSubmit", prompt: $p}'; }
file_input() { jq -nc --arg f "$1" '{hook_event_name: "PostToolUse", tool_name: "Edit", tool_input: {file_path: $f}}'; }

echo "→ session-close.sh"
for phrase in "on va arreter la pour aujourd'hui" "Ok j'ai push, à demain" "Ok merci claude. A demain !" \
  "merci bonne nuit" "J'ai tout pousser. Merci on s'arrête là pour aujourd’hui" \
  "commit sans mention de claude code ni de la session on reprend demain"; do
  expect_json "clôture : « $phrase »" session-close.sh "$(prompt_input "$phrase")" \
    '.hookSpecificOutput.hookEventName == "UserPromptSubmit" and (.hookSpecificOutput.additionalContext | length > 0)'
done
for phrase in "Ok j'ai push on enchaine." "arrête là, ce n'est pas ce que je veux" \
  "prévois le déploiement de demain matin" "voilà demain on verra"; do
  expect_silent "pas une clôture : « $phrase »" session-close.sh "$(prompt_input "$phrase")"
done
expect_silent "entrée illisible" session-close.sh "pas du json"

echo "→ format-python.sh"
mkdir -p "$tmp/plain"
printf 'x=1\n' >"$tmp/plain/a.py"
expect_silent "fichier non Python ignoré" format-python.sh "$(file_input "$tmp/plain/a.ts")"
expect_silent "fichier absent ignoré" format-python.sh "$(file_input "$tmp/plain/absent.py")"
expect_silent "Python sans ruff configuré : no-op" format-python.sh "$(file_input "$tmp/plain/a.py")"
if [[ "$(cat "$tmp/plain/a.py")" == "x=1" ]]; then pass "fichier intact sans ruff configuré"; else fail "fichier modifié sans ruff configuré"; fi

project="$tmp/ruff-project"
mkdir -p "$project"
printf '[project]\nname = "t"\nversion = "0"\nrequires-python = ">=3.10"\n\n[tool.ruff]\nline-length = 100\n' >"$project/pyproject.toml"
printf 'import sys\nimport os\nx=1\n' >"$project/b.py"
if (cd "$project" && uv venv -q && uv pip install -q --offline ruff) >/dev/null 2>&1; then
  expect_silent "ruff configuré : hook silencieux" format-python.sh "$(file_input "$project/b.py")"
  result="$(cat "$project/b.py")"
  if grep -qx 'x = 1' <<<"$result"; then pass "ruff format appliqué"; else fail "ruff format non appliqué : ${result//$'\n'/|}"; fi
  if [[ "$(grep -n '^import' <<<"$result" | tr '\n' ' ')" == "1:import os 2:import sys " ]]; then
    pass "imports triés et conservés même inutilisés"
  else
    fail "imports inattendus : ${result//$'\n'/|}"
  fi
else
  echo "  - ruff indisponible hors ligne : cas positif non testé"
fi

echo "→ notify.sh"
expect_json "séquence OSC 9 produite" notify.sh \
  '{"hook_event_name":"Notification","notification_type":"permission_prompt","message":"Claude needs your permission"}' \
  '.terminalSequence | startswith("]9;") and endswith("") and contains("permission")'
expect_json "message absent : texte par défaut" notify.sh '{"hook_event_name":"Notification"}' \
  '.terminalSequence | contains("Claude attend")'
expect_json "caractères de contrôle retirés du message" notify.sh "$(jq -nc '{message: "abc\nd"}')" \
  '.terminalSequence | ltrimstr("]9;") | rtrimstr("") | test("[\n]") | not'

echo "→ settings.json ↔ scripts"
while read -r command; do
  script="${command/\$HOME\/.claude\/hooks\//$HOOKS/}"
  if [[ -x "$script" ]]; then pass "$(basename "$script") référencé et exécutable"; else fail "commande de hook sans script exécutable : $command"; fi
done < <(jq -r '.hooks[][] | .hooks[] | .command' "$REPO/settings.json")

if (( failures == 0 )); then
  echo "✓ Tous les tests passent"
  exit 0
fi
echo "✗ $failures échec(s)"
exit 1
