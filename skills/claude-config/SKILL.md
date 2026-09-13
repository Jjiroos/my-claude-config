---
name: claude-config
description: Modifier ma config Claude Code (CLAUDE.md global, settings, permissions, hooks, skills, plugins), versionnée dans le dépôt my-claude-config et déployée par liens dans ~/.claude. Charger avant toute modification de ~/.claude ou de ce dépôt, et pour décider où ranger une règle apprise.
---

# Config Claude Code — my-claude-config

`~/.claude` ne contient que des liens vers le dépôt, qui est la cible de `readlink -f ~/.claude/CLAUDE.md`. On modifie le dépôt, puis on lance `./install.sh`.

## Où ranger quoi

| Nature | Emplacement |
|---|---|
| Règle valable pour tous mes projets | `CLAUDE.md` (≤ 200 lignes) |
| Garde-fou qui doit tenir même si le modèle l'oublie | `settings.json` : `permissions` (`deny`, `ask`) ou hook |
| Procédure que le modèle déclenche seul | `skills/<nom>/SKILL.md`, description orientée déclencheurs |
| Commande que je tape | `skills/<nom>/SKILL.md` avec `disable-model-invocation: true` |
| Conventions d'un langage | `skills/stack-<langage>/` avec `paths` |
| Préférence ou correction propre à un projet | mémoire native du projet |
| Décision dure à inverser | `docs/adr/NNNN-slug.md`, un paragraphe |

Pour rédiger un skill ou `CLAUDE.md` : skill `mattpocock-skills:writing-for-agents`.

## Compatibilité my-multi-cli-config

Les skills suivent le standard Agent Skills (`name` = nom du dossier, `description`) pour que `my-multi-cli-config` puisse les reprendre (ADR-0001). `paths`, `disable-model-invocation` et `allowed-tools` sont propres à Claude Code ; les métadonnées libres vont sous `metadata`.

## Hooks : pièges vérifiés

- **Doc brute d'abord.** Un résumé WebFetch de la doc a affirmé à tort que `Stop` ignore `additionalContext` et que le prompt de `UserPromptSubmit` s'appelle `user_prompt`. Vérifie sur la page brute : `curl -sL https://code.claude.com/docs/en/hooks.md | rg …`.
- **Entrée** : parse avec `jq` ; au moindre doute, `exit 0` sans sortie. Un hook ne bloque jamais à tort.
- **Injecter du contexte** : `exit 0` + `{"hookSpecificOutput":{"hookEventName":"<Événement>","additionalContext":"…"}}` (`UserPromptSubmit`, `PostToolUse`, `SessionStart`, `Stop`). Sur `Stop`, `exit 2` et `decision: "block"` s'affichent comme une erreur.
- **Notifier** : un hook n'a pas de terminal ; renvoie `{"terminalSequence":"…"}` (OSC 9, BEL) et Claude Code l'écrit.
- **Chemins** : les commandes passent par le shell ; référence `$HOME/.claude/hooks/<script>.sh`, qui résout vers le dépôt.
- **Règles Bash** : évaluées `deny` → `ask` → `allow`, sur chaque sous-commande d'une commande composée ; une règle qui contient un pipe ne correspond donc à rien.
- **Plugins** : `skillOverrides` ne touche pas les skills de plugin, et aucun réglage ne coupe un hook isolé d'un plugin (ADR-0003).

## Déployer et vérifier

```bash
./install.sh --dry-run    # ce qui changerait, sans rien toucher
./install.sh              # liens, sauvegarde de ce qui est remplacé, plugins
scripts/check-drift.sh    # README ↔ dépôt ↔ ~/.claude (pre-commit en mode --repo-only)
scripts/test-hooks.sh     # entrées d'exemple sur chaque hook
claude plugin details <plugin>@<marketplace>   # composants et coût en tokens d'un plugin
```

Ajouter ou retirer un skill, un hook ou un plugin met à jour le tableau correspondant du `README.md` dans le même commit : le pre-commit refuse le commit sinon.
