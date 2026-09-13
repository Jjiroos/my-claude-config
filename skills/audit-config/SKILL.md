---
name: audit-config
description: Audit daté de ma config Claude Code — usage réel, dérive, coût de contexte, suivi des décisions.
disable-model-invocation: true
---

# /audit-config

Dépôt de la config :

!`dirname "$(readlink -f "$HOME/.claude/CLAUDE.md")" 2>/dev/null || echo "introuvable : ~/.claude/CLAUDE.md n'est pas un lien vers le dépôt"`

Audits existants :

!`ls -1 "$(dirname "$(readlink -f "$HOME/.claude/CLAUDE.md")")/docs/audits" 2>/dev/null || echo "aucun"`

Un audit mesure avant de juger : chaque constat pointe un chiffre, un fichier ou une citation.

## Étapes

1. **Suivi.** Relis le dernier audit et donne un statut à chacune de ses recommandations : faite, en cours, abandonnée (raison), reportée.
2. **Usage réel.** `scripts/usage-stats.sh <date du dernier audit>` : skills, sous-agents et outils invoqués, commandes tapées, corrections probables.
3. **Coût de contexte.** Demande-moi les sorties de `/context` et `/skill-doctor` (je suis seul à pouvoir les lancer) et compare-les à l'audit précédent.
4. **Dérive.** `scripts/check-drift.sh`, puis `scripts/test-hooks.sh`.
5. **Apprentissages dormants.** Parcours les mémoires de projet (`~/.claude/projects/*/memory/`) : une préférence présente dans deux projets ou plus devient candidate pour `CLAUDE.md` ou un skill.
6. **État de l'art.** Seulement si je le demande : c'est l'étape la plus coûteuse.
7. **Rédige** `docs/audits/<AAAA-MM-JJ>-audit.md` d'après [TEMPLATE.md](TEMPLATE.md).

Les recommandations restent des propositions : je tranche, puis on exécute. Une décision dure à inverser gagne un ADR dans `docs/adr/`.

Complet quand chaque recommandation précédente a un statut, chaque métrique du gabarit sa valeur et sa variation, et chaque constat sa preuve.
