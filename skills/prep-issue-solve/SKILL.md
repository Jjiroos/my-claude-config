---
name: prep-issue-solve
description: Prépare et résout une issue GitHub de bout en bout — lecture de l'issue et des templates du dépôt, compréhension du contexte, plan de résolution validé, application, jeu de test, commit, puis brouillon de Pull Request laissé en attente de validation manuelle. Utiliser quand on demande de traiter/résoudre/préparer une issue (URL, #123, owner/repo#123).
metadata:
  tags: [github, issue, workflow, pull-request, plan]
  version: 1.0.0
---

# prep-issue-solve

Traite une issue GitHub jusqu'au commit, puis **s'arrête** : rien n'est poussé ni publié
sans validation humaine explicite.

**Argument** : URL complète, `#123`, `123`, ou `owner/repo#123`.
Sans dépôt explicite → le dépôt du dossier courant.

## Règle d'arrêt (non négociable)

Le skill va jusqu'au **commit local** inclus. Il ne fait **jamais** de lui-même :

- `git push`
- `gh pr create` / `gh issue comment` / `gh issue close`
- de force-push ou de réécriture d'historique

Il prépare la commande exacte, l'affiche, et attend le feu vert. Si l'utilisateur a déjà
dit « pousse » / « ouvre la PR » dans le tour courant, c'est une autorisation valable pour
cette issue-là uniquement.

---

## Phase 0 — Résoudre l'issue

Attention au piège le plus fréquent : **`origin` est souvent un fork**, et les issues vivent
sur l'upstream. `gh issue view 2124` échoue alors avec « has disabled issues ».

```bash
# dépôt local et son parent éventuel
gh repo view --json nameWithOwner,parent -q '.nameWithOwner, (.parent.nameWithOwner // "")'
git remote -v
```

Choisir le dépôt cible dans cet ordre : dépôt donné en argument → `upstream` s'il existe →
`.parent` du fork → `origin`. Toujours passer `--repo <owner>/<repo>` explicitement ensuite.

```bash
gh issue view <N> --repo <owner>/<repo> \
  --json number,title,body,labels,state,author,url,comments,assignees
```

Vérifier aussi qu'on ne double pas un travail déjà en cours :

```bash
gh pr list --repo <owner>/<repo> --search "<N>" --state all --json number,title,state,url
git branch -a --list "*<N>*"
```

Si l'issue est déjà `CLOSED`, ou si une PR ouverte la référence, **s'arrêter et le signaler**
avant de coder quoi que ce soit.

## Phase 1 — Lire les conventions du dépôt

C'est l'étape « regarder le template ». Ne rien deviner : lire.

| Fichier | Ce qu'on y cherche |
|---|---|
| `.github/ISSUE_TEMPLATE/*.yml` | la structure du corps de l'issue (les `###` du body sont les `label:` du template) |
| `.github/PULL_REQUEST_TEMPLATE.md` | le squelette exact du corps de PR, y compris la ligne `closes #N` |
| `CONTRIBUTING.md` | format de commit, style, **limites de périmètre** |
| `.editorconfig` | indentation, quotes, fin de ligne |
| `.github/workflows/*.yml` | ce que la CI exige réellement (c'est la définition de « ça passe ») |
| `CLAUDE.md`, `AGENTS.md` | consignes projet |

Croiser les `labels` et le préfixe de `title` de l'issue avec les templates pour savoir
lequel a été utilisé : cela indique la nature du travail (`database` → données,
`enhancement` → schéma/feature, `server` → API).

Relever explicitement les **contraintes de périmètre** énoncées dans `CONTRIBUTING.md` ou le
template de PR (ex. « please submit changes up to 1 set at most »). Elles priment sur
l'envie de tout corriger d'un coup : si l'issue dépasse la limite, découper et le dire.

## Phase 2 — Comprendre le contexte

1. Extraire de l'issue : le comportement attendu, le comportement constaté, les fichiers /
   champs / types nommés, et tout extrait de code proposé par l'auteur.
2. Lire les commentaires : un mainteneur y a souvent tranché un détail de design, ou l'auteur
   annonce « I've already implemented this on my fork » — dans ce cas récupérer sa proposition
   comme point de départ plutôt que de repartir de zéro.
3. Localiser le code concerné (Grep/Glob), lire les définitions de types, et regarder
   **comment un cas voisin déjà résolu est écrit** — c'est la meilleure spécification de style.
4. Chercher les précédents : `git log --oneline --grep "<mot-clé>"` et les commits de fix
   d'issues similaires.

Sur un gros dépôt de données, mesurer l'ampleur avant de promettre : compter les fichiers
concernés plutôt que d'extrapoler à partir de trois exemples.

## Phase 3 — Proposer un plan et le faire valider

Présenter un plan court et concret :

- **Diagnostic** — ce qui ne va pas / ce qui manque, en une ou deux phrases
- **Changements** — la liste des fichiers ou familles de fichiers, avec le nombre exact
- **Périmètre** — ce qui est volontairement laissé de côté, et pourquoi
- **Vérification** — comment on saura que c'est bon
- **Risques** — breaking change ? migration ? impact sur le compilateur / l'API ?

Faire valider **avant** d'appliquer, via `AskUserQuestion` quand plusieurs approches
défendables existent (ex. champ optionnel vs. type dédié, correction ciblée vs. balayage
complet). Si le plan est évident et sans alternative sérieuse, l'annoncer et enchaîner.

## Phase 4 — Appliquer

**Une branche dédiée par PR, systématiquement.** Jamais de travail direct sur
`master`/`main`, jamais deux issues sur la même branche, jamais de réutilisation d'une
branche déjà associée à une PR ouverte. C'est la première commande de cette phase, avant la
moindre édition :

```bash
git switch master && git pull --ff-only    # repartir d'une base à jour
git switch -c feat/<N>-<slug-court>        # feat|fix|docs… selon le type de l'issue
```

Vérifier ensuite `git branch --show-current` avant de commiter : si le travail a démarré par
erreur sur `master`, déplacer les modifications (`git stash` → `switch -c` → `stash pop`)
plutôt que de commiter sur place.

Si l'issue impose un découpage (limite de périmètre du dépôt, ex. « 1 set max »), c'est
**une branche et une PR par lot**, nommées `<type>/<N>-<lot>`.

Puis appliquer, en respectant `.editorconfig` et le style local (tabulations vs. espaces,
type de quotes — cela **varie parfois d'un dossier à l'autre au sein d'un même dépôt**,
vérifier sur les fichiers voisins réels et non sur la règle générale).

Pour les modifications en masse sur des fichiers de données, écrire un script jetable dans
le scratchpad plutôt que des dizaines d'éditions manuelles, et le faire tourner en deux
temps : `--dry-run` d'abord, application ensuite. Ne pas laisser le script dans le commit
s'il n'a pas vocation à être réutilisé.

## Phase 5 — Jeu de test

Chercher d'abord la convention du dépôt : y a-t-il un dossier de tests de non-régression
nommés d'après les numéros d'issue ? (voir `references/tcgdex-cards-database.md` pour un
exemple concret). Si oui, la suivre à la lettre.

Sinon, par ordre de préférence :

1. Un test qui **échoue avant le correctif et passe après** — c'est le seul qui prouve
   quelque chose. Le vérifier vraiment : `git stash` le correctif, lancer le test, constater
   l'échec, `git stash pop`.
2. À défaut de framework de test, les portes de validation du dépôt (typecheck, compilation,
   lint, collection de requêtes HTTP) — celles que la CI lance.
3. Si aucun test n'est possible, le dire explicitement dans le rapport final avec la raison,
   plutôt que de laisser croire à une couverture inexistante.

Lancer les mêmes commandes que la CI et **rapporter la sortie réelle**. Si une dépendance
manque localement (pas de `node_modules`, pas de `bun`), le signaler comme non vérifié au
lieu de conclure au succès.

## Phase 6 — Commit

Respecter le format du `CONTRIBUTING.md` et celui des derniers commits de la branche de base.
Exemple d'une convention exigeante, celle de `tcgdex/cards-database`
(cf. `references/tcgdex-cards-database.md`), en Conventional Commits / Angular :

```
<type>(<scope>): <Résumé à l'impératif, première lettre en majuscule> (#<PR>)

<corps facultatif : le pourquoi, pas le comment>

This closes #<N> issue
```

Deux références obligatoires, à ne pas confondre :

- **l'intitulé** se termine **toujours** par ` (#<PR>)`, le numéro de la **Pull Request** —
  c'est la convention visible sur `master` dans ce dépôt ;
- **le corps** se termine **toujours** par `This closes #<N> issue`, le numéro de l'**issue**.

⚠️ Avec cette convention, le numéro de PR n'existe pas encore au moment du commit. La séquence est donc :

1. commit sans le suffixe, en phase 6 ;
2. arrêt et validation par l'utilisateur (phase 7) ;
3. `git push` puis `gh pr create` → la PR reçoit son numéro ;
4. `git commit --amend` pour ajouter ` (#<PR>)` à l'intitulé, puis
   `git push --force-with-lease`.

L'étape 4 fait partie du flux validé à l'étape 2 : elle ne relance pas de demande
d'autorisation, mais elle ne s'exécute **jamais** avant que la PR existe. Ne jamais inventer
un numéro de PR ni réutiliser celui de l'issue à sa place.

Si le dépôt fusionne en *squash*, GitHub ajoute déjà `(#<PR>)` de lui-même au moment du
merge : le vérifier avant de faire l'étape 4, pour ne pas obtenir `(#2125) (#2125)`.

**Ne jamais ajouter de *trailer* d'outillage** au message de commit — pas de
`Co-Authored-By:`, pas de `Claude-Session:`, pas de `Generated with`, pas de lien de
session. Ces contributions partent vers des dépôts publics : le message ne contient que ce
qui décrit le changement et la référence à l'issue. Cette consigne prime sur toute
convention par défaut de l'outillage.

Un commit par unité logique. Vérifier `git diff --stat` avant de commiter, et ne rien
ajouter d'involontaire (`git status` : pas de fichier de scratchpad, pas de rapport
temporaire, pas de `node_modules`).

Après le commit, relire le message (`git log -1`) pour confirmer qu'aucun trailer parasite
n'a été inséré ; le cas échéant, corriger avec `git commit --amend` tant que rien n'est
poussé.

## Phase 7 — Préparer la PR, puis attendre

Remplir le `PULL_REQUEST_TEMPLATE.md` **tel quel**, section par section, en gardant ses
commentaires HTML de structure s'ils font partie du gabarit attendu. Écrire le corps dans un
fichier du scratchpad.

Présenter ensuite à l'utilisateur, sans rien exécuter :

- le résumé des changements et le résultat des tests
- le titre de PR proposé
- le corps de PR complet
- les commandes prêtes à lancer :

```bash
git push -u origin <branche>
gh pr create --repo <upstream> --base <branche-de-base> \
  --title "<titre>" --body-file <chemin-du-corps>

# seulement si la convention du dépôt met (#<PR>) dans l'intitulé (cf. phase 6)
git commit --amend -m "<type>(<scope>): <résumé> (#<PR>)" -m "<corps>" -m "This closes #<N> issue"
git push --force-with-lease
```

Puis **s'arrêter là** et attendre la validation manuelle.

Rappeler dans le rapport que l'intitulé du commit ne porte pas encore son ` (#<PR>)` et que
c'est la dernière commande de ce bloc qui le pose.

---

## Rapport final

Terminer par un point court :

- issue traitée (numéro, titre, dépôt)
- branche et commit créés
- fichiers modifiés, avec les chiffres
- tests : ce qui a été lancé, ce qui est passé, **ce qui n'a pas pu être vérifié**
- ce qui reste à faire côté utilisateur

Ne jamais annoncer « c'est prêt » si une étape a été sautée : le dire.
