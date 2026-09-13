#!/usr/bin/env bash
# UserPromptSubmit : détecte une clôture de session (« à demain », « bonne nuit »,
# « on s'arrête là pour aujourd'hui ») et rappelle les deux gestes de fin de session.
# UserPromptSubmit n'a pas de matcher : le filtrage se fait ici, sur le texte du prompt.
# Alternances plutôt que classes de caractères : les accents restent corrects quelle
# que soit la locale du hook. Au moindre doute : exit 0 sans sortie.
set -uo pipefail

prompt="$(jq -r '.prompt // empty' 2>/dev/null)" || exit 0
[[ -n "$prompt" ]] || exit 0

closing="pour aujourd.{1,3}hui|(^|[^[:alpha:]])(à|À|a|A) demain|bonne (nuit|soirée|soiree)|reprend(ra|rons)? demain"
grep -qiE "$closing" <<<"$prompt" || exit 0

context="Clôture de session détectée. Avant de conclure, en restant bref :
1. Si le projet a un fichier de plan (PLAN.md, IMPLEMENTATION_PLAN.md, TODO.md), propose sa mise à jour : état atteint, prochaine étape, points à trancher.
2. Si une procédure répétée, une correction que l'utilisateur a refaite ou un piège évité de justesse est apparu pendant la session, propose en diff le skill, la ligne de CLAUDE.md ou le garde-fou correspondant (skill claude-config). Sinon, n'en parle pas."

jq -nc --arg ctx "$context" \
  '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: $ctx}}'
