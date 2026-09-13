# Audit config Claude Code — 2026-09-13 (audit fondateur)

**Précédent** : aucun · **Périmètre** : dépôt `my-claude-config`, `~/.claude`, et la config de référence de Cyril Moron (`cmoron/claude-config`, commit `546e4c6`)

## 1. TL;DR

- **Point de départ** :
  - pas de `CLAUDE.md` global ;
  - 5 agents génériques jamais invoqués ;
  - 2 skills, dont un générique de 426 lignes ;
  - aucune permission ni hook ;
  - trailers d'attribution Claude revenant dans les commits malgré au moins quatre corrections.
- **Config construite, déployée et vérifiée en session réelle** :
  - `CLAUDE.md` de 96 lignes (échelle d'effort, routage superpowers / mattpocock) ;
  - 9 skills : 3 commandes, 4 stacks, 2 métier ;
  - 3 hooks couverts par 24 tests ;
  - permissions allowlist + `ask` + `deny` ;
  - attribution coupée ;
  - audits outillés (`usage-stats.sh`, `check-drift.sh` en pre-commit).
- **Reste à évaluer** : les plugins LSP et context7, et quatre ajustements hors de ce dépôt (§5).

## 2. Métriques de référence

| Métrique | Avant | Après | Source |
|---|---|---|---|
| Transcripts conservés | 21, sur 8 projets | rétention portée de 30 à 90 jours | `usage-stats.sh`, `cleanupPeriodDays` |
| Appels d'outils | 2 351 (Bash 1 685, Read 183, Write 135, MCP Unreal 127, Edit 93) | à suivre | `usage-stats.sh` |
| Invocations de skills par Claude | 4, dont 1 pendant cet audit | à suivre | `usage-stats.sh` |
| Sous-agents lancés | 0 | à suivre | `usage-stats.sh` |
| Commandes les plus tapées | `/clear` 9, `/compact` 6, `/context` 5, `/interactive-planner` 3 | à suivre | `history.jsonl` |
| `CLAUDE.md` global | absent | 96 lignes, 5 885 caractères | `wc` |
| Agents personnels | 5 (≈ 1 360 caractères de descriptions), 0 invocation | 0 | `~/.claude/agents` |
| Skills perso listés au modèle | 2 skills, 643 caractères | Au démarrage, 2 skills : `claude-config`, `prep-issue-solve`. Les 4 `stack-*` n'apparaissent qu'au contact d'un fichier correspondant (`paths`, observé). Les 3 commandes ne coûtent rien. | listing des skills en session |
| Coût permanent des plugins | mattpocock ≈ 1 609 tok, frontend-design ≈ 78 tok | En plus pour superpowers : ≈ 688 tok de listing, et le texte de `using-superpowers` (≈ 1,1 k tok) injecté par son hook `SessionStart` | `claude plugin details` ; transcript de la session de test |
| Hooks | 0 | 3, 24 tests OK, vérifiés en session réelle | `scripts/test-hooks.sh`, `claude -p` |
| Correction « commit sans mention de Claude » | au moins 4 prompts | `attribution` vide dans `settings.json` + règle `CLAUDE.md` | `history.jsonl`, transcripts |
| Consigne « ne pousse jamais, je valide » | au moins 2 prompts + mémoire de pioum | `ask` sur `git push`, `gh pr create`… | idem |
| Ouvertures « reprends / où on en était » | au moins 8 | `/reprise` | `history.jsonl` |
| Clôtures « à demain / bonne nuit / pour aujourd'hui » | au moins 6 | hook `session-close` | `history.jsonl` |

## 3. Analyse de la config de référence (Cyril)

### Forces reprises et adaptées

| Force | Chez Cyril | Ici |
|---|---|---|
| Déploiement déclaratif par liens | `install.sh` + `prune_managed_links` | Liens + sauvegarde horodatée de ce qui est remplacé, `--dry-run`, purge des liens morts |
| Échelle d'effort XS → L+ et garde-fou de coût | `CLAUDE.md` | Reprise, routée vers superpowers et mattpocock (« Un skill par besoin ») |
| Skills = compétences, agents = métiers | spec 2026-05-15 | 0 agent global ; stacks en skills limités par `paths` |
| Frugalité de contexte | allowlist des skills upstream, descriptions courtes | Descriptions ≤ 353 caractères, commandes en `disable-model-invocation` (aucun coût), plafonds vérifiés par `check-drift.sh` |
| Hooks qui dégradent en no-op | `command -v … \|\| true` | Idem, plus 24 tests |
| Auto-amélioration encadrée | `reflect-nudge.sh` sur `Stop` | Déclenchée par les phrases réelles de clôture (`UserPromptSubmit`) |
| Preuve d'exécution ; un avertissement invalide la sortie | `CLAUDE.md` | Reprises |
| Audits datés, décisions tracées | `docs/audits/` (3 passages) | Reprise, avec `TEMPLATE.md`, `/audit-config` et `usage-stats.sh` |

### Faiblesses corrigées

| Faiblesse | Preuve | Correction |
|---|---|---|
| Doc qui dérive trois audits de suite, contrôle « à l'œil » | audit 2026-07-06 §2 | `check-drift.sh` en pre-commit : README ↔ skills, hooks, plugins, frontmatter, `~/.claude` |
| Audits sans données d'usage | aucun chiffre d'invocation dans les trois audits | `usage-stats.sh`, `/skill-doctor`, `claude plugin details` |
| `bypassPermissions` + denylist | `rm -rf ~*` bloqué, `rm -fr ~` passe | Mode `default` + allowlist + `ask` (ADR-0002) |
| `includeCoAuthoredBy`, déprécié depuis v2.0.62 | `settings.json` | `attribution` : `commit` et `pr` vides, `sessionUrl` à `false` |
| Chemins de dépôt en dur dans les hooks | `$HOME/src/claude-config/scripts/…` | `$HOME/.claude/hooks/…`, résolu par lien |
| Format-on-save : `ruff check --fix` complet, `prettier` et `ruff` globaux | `format-on-save.sh` | ruff du projet, `format` + règle `I` seulement : un import ajouté avant son usage survit (testé avec ruff 0.16.7) |
| Rappel d'auto-amélioration au premier `Stop`, souvent en pleine tâche | `reflect-nudge.sh` | Déclencheur = clôture réelle de session |
| `sg` présenté comme ast-grep | table Outils du `CLAUDE.md` | Sur cette machine, `/usr/bin/sg` est `newgrp` : consigne explicite |
| Stack imposée (« jamais npm/pnpm ») | `stack-ts` | Gestionnaire déduit du lockfile (pnpm, bun et npm coexistent dans mes projets) |
| `autoship` : merge et déploiement prod autonomes | `skills/autoship` | Non porté : contraire à « je valide avant de pousser » |
| Parsing JSON des hooks en `python3` | scripts | `jq` : 13 ms contre 19 ms par appel, mesurés |

### Non repris

Hors de mon profil : `linear`, `openclaw`, `lotusim-developer`, `macos-control`, `nvim-config`, `mvp`, `deployment`, `api-design`, RTK (binaire absent, gain non mesuré ici), `ponytail`, `codex`.
`opensource-contributor` est à reconsidérer si les contributions upstream deviennent fréquentes : `prep-issue-solve` en couvre une partie.

## 4. Constats

Sévérité : 🔴 cassé ou risqué · 🟠 coûte en tokens ou en temps · 🟡 dette · ⚪ information

| Sévérité | Constat | Preuve |
|---|---|---|
| 🔴 | Trailers d'attribution Claude dans les commits malgré les corrections | 4 prompts « sans mention de Claude / supprime le Co-Authored » ; branche `backup-avant-nettoyage-trailers` dans pokebuddy |
| 🟠 | 5 agents génériques (DDS, Kafka, K8S, Go, Next.js), modèles figés (`claude-opus-4-7`, `claude-sonnet-4-6`), déclencheurs « PROACTIVEMENT » | 0 sous-agent sur 21 transcripts |
| 🟠 | `interactive-planner` : 426 lignes génériques, renvois vers des skills inexistants (`web-cli-teleport`, `sparc-methodology`), doublon de `grilling` et d'`AskUserQuestion` | `SKILL.md` |
| 🟡 | `prep-issue-solve` mêlait la convention de commit de tcgdex (`(#PR)`, amend, force-with-lease) au flux générique | Phase 6 ; corrigé : convention présentée comme exemple conditionnel, frontmatter mis au standard (`metadata`) |
| 🟡 | Allowlists de projet encombrées de commandes ponctuelles | `mycollectbuddy/.claude/settings.local.json` (`python3 -c …`, `grep` sur `PLAN.md`) |
| 🟡 | Transcripts effacés après 30 jours : un audit mensuel manque de matière | `cleanupPeriodDays` par défaut |
| ⚪ | Les résumés WebFetch de la doc Claude Code se sont trompés deux fois (`Stop` et `additionalContext`, champ `prompt` de `UserPromptSubmit`) ; la doc brute fait foi | `code.claude.com/docs/en/hooks.md` |
| ⚪ | `skillOverrides` ne s'applique pas aux skills de plugin ; aucun réglage ne coupe un skill ou un hook isolé d'un plugin | `skills.md`, `settings-reference.md` |
| ⚪ | `claude plugin install` réécrit `settings.json` à travers le lien (ordre des clés changé, valeurs identiques) ; le lien survit | diff du dépôt après installation de superpowers ; `check-drift.sh` OK |
| ⚪ | `claude plugin details` classe le hook `SessionStart` de superpowers « harness-only — no model context cost », alors qu'il injecte `using-superpowers` dans le contexte | transcript de la session de test |

## 5. Décisions

### Tranchées le 2026-09-13

- Périmètre : config Claude dédiée, compatible `my-multi-cli-config` (anciennement `my_llm_conf`) → [ADR-0001](../adr/0001-config-claude-dediee-compatible-my-multi-cli-config.md).
- Permissions : allowlist + `ask` → [ADR-0002](../adr/0002-permissions-allowlist-et-ask.md).
- Stacks couvertes : TS/Node, Python/uv, UE5 C++ via WSL, Java 17.
- Méthode : superpowers et mattpocock à la carte → [ADR-0003](../adr/0003-superpowers-et-mattpocock-a-la-carte.md).
- Déploiement, retrait des 5 agents et d'`interactive-planner`, commit initial : validés.

### À trancher

1. **Plugins LSP** (`typescript-lsp`, `pyright-lsp`, `jdtls-lsp`, `clangd-lsp`) et **context7** : vérifier d'abord la présence des binaires. Recommandation : à évaluer au prochain audit.
2. **Hors de ce dépôt** (proposé, non fait) :
   - `git config --global pull.rebase true` (actuellement `false`, contraire à l'historique linéaire) ;
   - allowlist de projet pour DontTouchMyAle (`cmd.exe /c …Build.bat`, `taskkill.exe`, `netstat.exe`) ;
   - alléger la mémoire de DontTouchMyAle des pièges génériques désormais portés par `stack-ue5-wsl` ;
   - trois lockfiles dans `/mnt/z/dev_workspace/pioum` (bun, pnpm, npm) ;
   - `~/.claude/statusline-command.sh`, remplacé par `statusline.sh`, à supprimer.

## 6. Actions exécutées

1. **Rédaction du dépôt** : `CLAUDE.md`, `settings.json`, 3 hooks, 9 skills, 3 scripts, pre-commit, 3 ADR, README, cet audit.
2. **Vérifications avant déploiement** :
   - `shellcheck` sur tous les scripts ;
   - `scripts/test-hooks.sh` : 24 tests sur 24, dont le formatage réel par ruff ;
   - `scripts/check-drift.sh --repo-only` : aucune dérive ;
   - `./install.sh --dry-run`.
3. **Déploiement** (`./install.sh`) :
   - liens créés dans `~/.claude` ;
   - `settings.json` et `skills/prep-issue-solve` sauvegardés dans `~/.claude/backups/my-claude-config-20260913-120730/` ;
   - superpowers 6.3.0 installé ;
   - `core.hooksPath` réglé sur `.githooks`.
4. **Retrait** : les 5 agents et `interactive-planner` sont déplacés dans `~/.claude/backups/retrait-20260913-120734/`, et `~/.claude/agents`, vide, est supprimé.
5. **Vérifications après déploiement** :
   - `scripts/check-drift.sh` complet : aucune dérive ;
   - barre d'état fonctionnelle via le lien ;
   - session `claude -p` sur une phrase de clôture : aucun avertissement de réglage, réponse en français, contexte du hook `session-close` et injection `SessionStart` de superpowers présents dans le transcript.
6. **Commit initial** du dépôt (celui qui introduit cet audit), sans push.

## 7. Prochaine revue

Le 2026-10-13, ou après 30 jours d'usage. À mesurer en priorité :

- `/context` dès la première session interactive, pour remplacer les estimations du §2 ;
- déclenchements de skills de process superpowers sur des tâches XS/S (critère de l'ADR-0003) ;
- `/skill-doctor` : skills jamais invoqués et leur coût ;
- usage de `/reprise`, `/commit` et du hook `session-close` ;
- prompts de permission ressentis comme du bruit, pour ajuster l'allowlist.
