# Repère : tcgdex/cards-database

Notes vérifiées sur le dépôt le plus souvent traité. À relire avant de traiter une issue
dessus — mais **revérifier** si le dépôt a bougé depuis.

## Fork / upstream

Le clone local pointe généralement sur un fork (`origin = <user>/cards-database`), dont les
issues sont désactivées. Les issues et les PR vivent sur **`tcgdex/cards-database`**.
Toujours `--repo tcgdex/cards-database`. Branche de base : `master`.

## Templates d'issue

`.github/ISSUE_TEMPLATE/` — `blank_issues_enabled: false`, donc toute issue suit un gabarit :

| Template | Titre | Labels | Nature |
|---|---|---|---|
| `database-issue.yml` | `issue:` | `issue`, `database` | données cartes/sets/séries |
| `api-issue.yml` | `issue:` | `issue`, `server` | serveur, GraphQL, JSON API, traductions, définitions |
| `enhancement.yml` | `enhancement:` | `enhancement` | nouveau champ / feature |
| `new-set.yml` | `new set: {Set Name}` | `database` | nouveau set annoncé |

Les `###` du corps de l'issue correspondent aux `label:` du YAML — s'en servir pour parser.

## Conventions de code

`.editorconfig` + `CONTRIBUTING.md` :

- indentation **tabulation**
- **double quotes** dans `data/`, **simple quotes** partout ailleurs
- `;` seulement quand nécessaire, et en début de ligne
- commits Conventional / Angular. Types autorisés : `build` (server/compiler), `ci`
  (workflows, Dockerfile), `docs`, `feat` (nouveau champ/feature), `fix` (données ou
  serveur), `pref`, `refactor`, `test`. Résumé à l'impératif, majuscule initiale.

⚠️ La règle « tabulation » n'est **pas** respectée partout dans `data/` : plusieurs sets
sont indentés aux espaces (Paldean Wonders, Scarlet & Violet Energy, McDonald's
2018/2019, Mega Evolution Energy). Tout outillage qui repose sur l'indentation pour parser
ces fichiers rate ces cas — préférer un suivi de profondeur d'accolades.

## Périmètre des PR

`PULL_REQUEST_TEMPLATE.md` : « please submit changes up to **1 set at most** ».
Une correction qui touche plusieurs sets doit être découpée en une PR par set — c'est ce
que font les commits existants (`fix(data): Add missing French evolveFrom translations for A1`).

Le corps de PR attendu :

```
closes #<N>

## Changes

<résumé court>

## Details

<détails>
```

## Structure des données

- `interfaces.d.ts` — le contrat. `Card`, `Set`, `Serie`, `SupportedLanguages`.
  `Languages<T> = Partial<Record<SupportedLanguages, T>>` : **toutes les locales sont
  optionnelles**, donc une traduction manquante ne fait jamais échouer le typecheck.
- `data/<Série>/<Set>/<numéro>.ts` — une carte, `export default card`. ~23 600 fichiers.
- `data/<Série>/<Set>.ts` et `data/<Série>.ts` — sets et séries, à ne pas confondre avec
  des cartes lors d'un glob.
- `data-asia/` — base japonaise/asiatique, ~18 400 fichiers, **aucune locale `fr`**.
- `meta/translations/*.json` — traductions hors cartes.
- `server/` — API, compilateur, projet et `package.json` séparés.

## Tests

Convention de non-régression : `.bruno/fixes/<numéro-issue>-<slug-kebab>.bru`, avec

```
meta {
  name: <N> - <Titre lisible>
  type: http|graphql
  seq: <n>
}
```

et un bloc `assert` (`res.status: eq 200`, `res.body.…: eq …`). Suivre ce nommage pour toute
issue serveur/API.

Ce que lance la CI (`.github/workflows/test.yml`), sur Linux/Windows/macOS :

```bash
bun install --frozen-lockfile
cd server && bun install --frozen-lockfile && bun run compile
bun run validate            # racine : tsc --noEmit
cd server && bun run --bun validate
cd server && bun run start &        # puis
cd .bruno && bru run --env Developpement
```

`.github/workflows/build.yml` construit en plus l'image Docker sur chaque PR.

⚠️ L'environnement local peut ne pas avoir `bun` ni `node_modules` installés, et le dépôt
est parfois sur un montage `/mnt/z` lent (un parcours complet de `data/` prend plusieurs
minutes). Dans ce cas : lancer les scans en tâche de fond, et déclarer la validation
« non vérifiée localement » plutôt que de la supposer bonne.

## Outillage existant

- `scripts/check-missing.ts` — cherche une propriété manquante :
  `bun scripts/check-missing.ts "data/*/*/*.ts" name.fr`
- `scripts/pokedexIdFixer/` — audit/fix/lint des `dexId` (`npm run dex:audit`, `dex:fix:dry-run`, `dex:lint`)
- `scripts/utils/ts-extract-utils.ts` — extrait l'export par défaut d'un `.ts` via l'AST
  TypeScript. À réutiliser plutôt que de réécrire un parseur.
