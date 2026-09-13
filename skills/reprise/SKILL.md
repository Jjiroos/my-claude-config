---
name: reprise
description: Reprendre un projet en début de session — état git, plan en cours, prochaines étapes.
disable-model-invocation: true
---

# /reprise

## État du dépôt

!`git status --short --branch 2>&1 || true`

!`git log --oneline --decorate -12 2>&1 || true`

!`git branch -vv 2>&1 || true`

!`git stash list 2>&1 || true`

Fichiers de plan présents :

!`ls -1d PLAN.md IMPLEMENTATION_PLAN.md TODO.md CHANGELOG.md docs/plans 2>/dev/null || echo "aucun"`

## Étapes

1. Lis les fichiers de plan listés ci-dessus et l'index de mémoire du projet.
2. Rapproche plan et réalité : chaque tâche du plan est livrée (commit identifié), en cours (fichiers modifiés, branche) ou à faire.
3. Mesure l'écart avec le distant : `git fetch`, puis les `ahead`/`behind` de `git branch -vv`. Rien n'est poussé ni fusionné.

## Rapport

- **Où on en est** : branche, derniers commits, travail non commité, stash.
- **En cours** : ce que le plan annonce et ce que le code confirme ou contredit.
- **Prochaines étapes** : trois au plus, la première prête à démarrer.
- **À trancher** : les décisions qui m'attendent.

Complet quand chaque fichier modifié, chaque stash et chaque tâche ouverte du plan apparaît dans le rapport.
