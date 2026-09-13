# my-claude-config

Ma configuration Claude Code : instructions globales, permissions, hooks, skills et plugins, versionnés ici et déployés par liens symboliques dans `~/.claude`.

Construite le 2026-09-13 à partir de l'analyse de la config de Cyril Moron et de mon usage réel : voir [l'audit initial](docs/audits/2026-09-13-audit-initial.md).

## Installer

Prérequis : `claude`, `git`, `jq` ; `uv` pour le formatage Python ; `shellcheck` pour la vérification.

```bash
./install.sh --dry-run   # aperçu, sans rien modifier
./install.sh             # déploiement ; ce qui occupait une place gérée part dans ~/.claude/backups/
```

Relançable sans risque après chaque modification. Redémarrer Claude Code ensuite.

## Structure

```
CLAUDE.md        instructions globales, chargées à chaque session
settings.json    modèle, langue, attribution, permissions, hooks, plugins
statusline.sh    barre d'état : modèle, % de contexte, tokens restants
hooks/           scripts des hooks, liés en ~/.claude/hooks
skills/          un dossier par skill, lié dans ~/.claude/skills
scripts/         vérification (check-drift, test-hooks) et mesure (usage-stats)
docs/adr/        décisions dures à inverser
docs/audits/     audits datés de la config
.githooks/       pre-commit : check-drift en mode --repo-only
```

## Skills

| Skill | Invocation | Rôle |
|---|---|---|
| `commit` | `/commit` | Commit Conventional Commits en français, court, sans push |
| `reprise` | `/reprise` | Reprendre un projet : état git, plan, prochaines étapes |
| `audit-config` | `/audit-config` | Audit daté de cette config, appuyé sur l'usage réel |
| `claude-config` | modèle | Modifier cette config ; décider où ranger une règle |
| `prep-issue-solve` | modèle ou `/prep-issue-solve` | Traiter une issue GitHub jusqu'au commit, PR préparée sans push |
| `stack-ts` | modèle, fichiers TS | Gestionnaire selon le lockfile, Vitest, Prisma, ESLint |
| `stack-python` | modèle, fichiers Python | uv, FastAPI, Alembic, pytest, ruff |
| `stack-java` | modèle, fichiers Java | Maven, JUnit 5, périmètre Java 17 |
| `stack-ue5-wsl` | modèle, projet UE5 | Build par cmd.exe, éditeur et MCP Unreal depuis WSL |

## Hooks

| Script | Événement | Rôle |
|---|---|---|
| `session-close.sh` | `UserPromptSubmit` | Sur « à demain », « bonne nuit »… : rappelle de mettre le plan à jour et de proposer une évolution de la config |
| `format-python.sh` | `PostToolUse` (Write, Edit) | `ruff format` + tri des imports si le projet configure ruff |
| `notify.sh` | `Notification` (permission, attente) | Notification Windows Terminal (OSC 9) |

## Plugins

| Plugin | Rôle |
|---|---|
| `mattpocock-skills@claude-plugins-official` | grilling, tdd, diagnosing-bugs, domain-modeling, code-review, writing-for-agents |
| `superpowers@claude-plugins-official` | Flux M et L+ : brainstorming, writing-plans, subagent-driven-development |
| `frontend-design@claude-plugins-official` | Direction visuelle des interfaces |

Le routage entre les deux premiers vit dans `CLAUDE.md` (« Un skill par besoin ») ; voir [ADR-0003](docs/adr/0003-superpowers-et-mattpocock-a-la-carte.md).

## Permissions

Mode `default`. Build, tests et git local sont pré-autorisés. Push, PR, `gh api`, `ssh`, `docker compose down` et `sudo` demandent toujours validation. Force-push, `rm -rf` de la racine ou du home, et édition des `.env` sont interdits. Voir [ADR-0002](docs/adr/0002-permissions-allowlist-et-ask.md).

## Maintenir

- `scripts/check-drift.sh` : README, dépôt et `~/.claude` disent la même chose ; lancé en pre-commit.
- `scripts/test-hooks.sh` : chaque hook sur des entrées d'exemple, dont des phrases réelles de mon historique.
- `/audit-config` : audit mensuel ; `scripts/usage-stats.sh` fournit les chiffres.
- Transcripts conservés 90 jours (`cleanupPeriodDays`) pour que les audits aient de la matière.
