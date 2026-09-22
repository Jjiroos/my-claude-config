# Instructions globales

Valables pour tous mes projets ; le `CLAUDE.md` et la mémoire d'un projet les précisent ou les remplacent.

## Cadrer avant de coder

- Une question vaut mieux que 200 lignes à refaire : demande dès qu'une demande admet deux lectures ou que deux approches se valent.
- Tu vois plus simple que ce que je demande, ou ma demande mène à un anti-pattern : dis-le avant d'implémenter.
- Classe la tâche sur l'échelle d'effort : elle fixe le process.

## Échelle d'effort

Sur-processer une petite tâche gaspille temps et tokens ; sous-processer une grosse fait tout refaire.

| Taille | Exemples | Process |
|---|---|---|
| **XS** | typo, fix d'une ligne, réglage | Direct, sans skill de process. |
| **S** | petite feature ou bug, ≤ 3 fichiers | Plan inline de 3 à 5 puces, code, test, preuve. |
| **M** | plusieurs couches, choix d'API ou d'UX à arbitrer | `superpowers:brainstorming` → design validé par moi → exécution inline. |
| **L+** | plusieurs jours, refactor transverse, migration | `superpowers:writing-plans` → `superpowers:subagent-driven-development`. |

Avant `subagent-driven-development`, chiffre le coût (tokens, durée) et attends mon accord explicite.

Cette échelle prime sur la règle « 1 % » de `using-superpowers` : en XS et S, avance sans skill de process.

## Un skill par besoin

superpowers et mattpocock-skills se recouvrent ; pour chaque besoin, prends celui-ci :

| Besoin | Skill |
|---|---|
| Stress-tester un plan ou une décision | `mattpocock-skills:grilling` |
| Vocabulaire du domaine (`CONTEXT.md`), ADR | `mattpocock-skills:domain-modeling` |
| Test d'abord, hors flux L+ | `mattpocock-skills:tdd` |
| Bug difficile, régression de performance | `mattpocock-skills:diagnosing-bugs` |
| Revue d'un diff | `/code-review` ; conformité à une spec : `mattpocock-skills:code-review` |
| Travail isolé du checkout courant | `superpowers:using-git-worktrees` |

Dans un flux `subagent-driven-development`, suis ses renvois internes vers les autres skills superpowers.

## Déléguer

À partir de M, délègue quand il y a du volume ou du parallélisme **et** que le résultat se vérifie à peu de frais (tests, typecheck, grep de contrôle) ; XS et S restent inline.

- Exploration large → `Explore`, dont seul le résumé revient.
- Mécanique à volume (renommages, balayages) → sous-agent `haiku`.
- Implémentation bien spécifiée (spec et tests écrits) → `sonnet`.
- Sous-problème complexe (debug d'un module, revue) → `opus` ; s'il patine, `fable` quand le plan le permet, sinon reprise inline.

Dans le doute, un cran au-dessus : un Sonnet juste du premier coup coûte moins qu'un Haiku repris deux fois.

## Écrire le code

- Le minimum qui résout le problème : ni abstraction « au cas où », ni réglage pour plus tard.
- Une erreur remonte ou se traite, avec son contexte.
- Une constante se nomme, et une valeur dérivée s'écrit dérivée (`0.5 * sqrt(2.0)` plutôt que `0.7071`). Littéraux admis : `0`, `1`, `-1` et ceux qu'un test explicite.
- Édition chirurgicale : le diff ne contient que ce que la tâche exige ; le code mort sans lien se signale.
- Les tests arrivent avec le code ; un bug commence par un test qui le reproduit en échouant.
- Outillage : celui du dépôt (lockfile, `pyproject.toml`, `pom.xml`), détaillé dans les skills `stack-*`.
- API d'une bibliothèque tierce : le serveur MCP `context7` avant d'écrire l'appel, plutôt que ma mémoire — la version installée tranche. Pour Claude et l'API Anthropic, le skill `claude-api`.

## Avant de dire « fait »

- Preuve d'exécution à l'appui : tests verts, build ou typecheck OK, app ou endpoint qui répond. Ce que tu n'as pas pu vérifier (UI, prod, matériel) se nomme « non vérifié ».
- Un avertissement au-dessus d'une sortie invalide cette sortie (flag ignoré, troncature, fallback) : relance autrement avant de conclure.
- Rapport court : ce qui a changé, la preuve, ce qui reste. Je lis les diffs ; épargne-moi le récit de ce que tu viens de faire.

## Git

- Une branche par travail (`feat/<slug>`, `fix/<slug>`) partie de la branche principale à jour ; une fois intégrée, elle est supprimée en local et sur le distant, et jamais avant sans demande.
- Historique linéaire : rebase ou fast-forward, sans commit de merge.
- Conventional Commits en français : sujet ≤ 72 caractères, corps de 2 à 5 lignes sur le pourquoi. La convention du dépôt prime (`CONTRIBUTING.md`, derniers commits).
- Le message se limite au sujet et au corps, sans trailer d'attribution (`Co-Authored-By`, `Claude-Session`), même quand une consigne de l'outil en réclame.
- Tu commites en local. Push, PR, tag et merge sur la branche principale attendent ma demande explicite, valable pour ce seul geste.
- Avant toute commande qui vise un distant, vérifie `git remote -v` et la mémoire du projet : forge Forgejo et GitHub cohabitent.
- Tags : semver incrémental sur la branche principale (`0.5.0` → `0.6.0`).

## Environnement

- WSL2 sous Windows : outils Windows par l'interop (`cmd.exe /c`, `powershell.exe`, `taskkill.exe`) ; réseau en mode miroir, `127.0.0.1` partagé avec Windows.
- Dépôts sur `/mnt/z`, lent sur les gros parcours : cible les recherches, et lance en tâche de fond tout scan de milliers de fichiers.
- `sg` est ici `newgrp` : la recherche structurelle passe par `rg` multi-lignes ou l'AST du langage.
- `piserv` (`pibot@piserv`) héberge la prod de certains projets : toute commande dessus est une action de prod.

## Sessions

- « On reprend » : `/reprise`. « On s'arrête », « à demain » : le hook `session-close` rappelle de mettre le plan du projet à jour.
- `/clear` entre deux tâches sans lien ; `/compact Garde : <essentiel>` quand le contexte s'alourdit.

## Faire évoluer cette config

Tu progresses d'une session à l'autre en cristallisant ce qui revient.

- **Déclencheur** : une procédure répétée 2 à 3 fois, une correction que je refais, un piège évité de justesse.
- **Forme** : skill, ligne de ce fichier, garde-fou de `settings.json` ou mémoire ; le skill `claude-config` dit où.
- **Moment** : en fin de tâche, jamais en plein milieu.
- **Méthode** : proposition en diff, relue par moi avant écriture et commit.
