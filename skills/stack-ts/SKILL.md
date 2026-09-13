---
name: stack-ts
description: Conventions TypeScript/Node de mes projets (pnpm ou bun selon le lockfile, Vitest, Prisma, ESLint). Charger avant d'installer une dépendance, lancer des tests, vérifier un build ou modifier un schéma Prisma.
paths:
  - "**/*.{ts,tsx,mts,cts}"
  - "**/package.json"
  - "**/schema.prisma"
---

# Stack TypeScript / Node

## Gestionnaire de paquets : celui du dépôt

Le lockfile versionné désigne l'outil ; le champ `packageManager` du `package.json` le précise.

| Lockfile | Outil | Binaire local |
|---|---|---|
| `pnpm-lock.yaml` | `pnpm` | `pnpm exec <bin>` |
| `bun.lock` / `bun.lockb` | `bun` | `bunx <bin>` |
| `package-lock.json` | `npm` | `npx <bin>` |

Un dépôt a un seul lockfile. Plusieurs lockfiles présents : signale-le et demande lequel fait foi.
Monorepo pnpm (`pnpm-workspace.yaml`) : cible un paquet avec `pnpm --filter <nom> <script>`.

## Portes de vérification

Avant de dire « fait », lance ce que lance la CI (`.github/workflows/`, `.forgejo/workflows/`), dans cet ordre :

1. typecheck : script `typecheck`, sinon `tsc --noEmit` ;
2. `lint` ;
3. tests du paquet touché, en exécution unique : script `test:run` s'il existe, sinon `vitest run [fichier]`.

## Prisma

Après une modification de `schema.prisma` : régénère le client (`db:generate` ou `prisma generate`), puis termine ton rapport par l'action à jouer en prod (`db:push` ou `prisma migrate deploy`) : elle n'est jamais automatique.

## Style

ESLint porte le style de ces projets : aligne-toi sur les fichiers voisins et sur la sortie de `lint`.
