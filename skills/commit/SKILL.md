---
name: commit
description: Committer le travail en cours — Conventional Commits en français, message court, sans push.
disable-model-invocation: true
allowed-tools: Bash(git add *) Bash(git commit *)
---

# /commit

!`git status --short --branch 2>&1 || true`

!`git log --oneline -8 2>&1 || true`

1. **Périmètre.** Lis `git diff --staged`, ou `git diff` si rien n'est indexé. Une unité logique par commit : sépare les changements sans lien.
2. **Branche.** Sur la branche principale, crée d'abord `feat/<slug>` ou `fix/<slug>`, sauf si je t'ai demandé de committer sur la branche courante.
3. **Style.** Suis la convention du dépôt (`CONTRIBUTING.md`, langue et forme des derniers commits ci-dessus). À défaut :

   ```
   <type>(<scope>): <sujet au présent, en français, ≤ 72 caractères>

   <corps optionnel de 2 à 5 lignes : le pourquoi que le diff ne dit pas>
   ```

   Types : `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, `chore`.
4. **Message.** Il s'arrête à la dernière ligne du corps, sans trailer d'attribution.
5. **Commit**, puis montre `git log -1 --stat`.

Termine en donnant la commande de push, sans la lancer : le push reste ma décision.
