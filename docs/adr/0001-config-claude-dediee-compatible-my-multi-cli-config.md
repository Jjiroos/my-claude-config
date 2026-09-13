# Config Claude Code dédiée, compatible avec my-multi-cli-config

Ce dépôt porte ce que `my-multi-cli-config` (anciennement `my_llm_conf`) exclut de sa v1 (son ADR-0001) : `CLAUDE.md`, `settings.json`, permissions, hooks et commandes propres à Claude Code. Ses skills suivent le standard Agent Skills (`name` égal au nom du dossier, `description`) pour que `my-multi-cli-config` puisse les reprendre comme Artefacts locaux le jour où son outil existera. On dispose ainsi d'une config utile sans attendre l'outil multi-CLI, et sans créer un format concurrent.

## Considered Options

- **Fusion dans `my-multi-cli-config`** : un seul dépôt, mais il faudrait élargir son périmètre v1 à des Artefacts que ses ADR jugent trop divergents entre CLIs.
- **Config autonome sans contrainte de portabilité** : plus libre, mais les skills seraient à réécrire au moment de la migration.

## Consequences

- Les plugins natifs (`mattpocock-skills`, `superpowers`) restent installés ici, en tension avec l'ADR-0003 de `my-multi-cli-config`, qui prévoit de les remplacer par un Manifest. À arbitrer quand son outil sera livré.
- Les champs de frontmatter propres à Claude Code (`paths`, `disable-model-invocation`, `allowed-tools`) sont admis. Leur tolérance par Codex, OpenCode et Hermes reste à vérifier côté `my-multi-cli-config` (un Overlay peut les retirer).
