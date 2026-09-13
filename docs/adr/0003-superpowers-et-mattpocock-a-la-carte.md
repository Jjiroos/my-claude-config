# superpowers et mattpocock-skills ensemble, routés par CLAUDE.md

Les deux plugins sont activés. L'échelle d'effort et la table « Un skill par besoin » de `CLAUDE.md` désignent un seul skill pour chaque besoin. `skillOverrides` ne s'applique pas aux skills de plugin (doc Claude Code, vérifié le 2026-09-13), et aucun réglage ne désactive un skill ou un hook isolé d'un plugin. La sélection « à la carte » repose donc sur la priorité des instructions utilisateur, que `using-superpowers` reconnaît lui-même.

## Considered Options

- **mattpocock-skills seul** : moins de contexte et aucun doublon, mais on se prive du flux L+ de superpowers (`writing-plans` → `subagent-driven-development`).
- **Sous-ensemble de superpowers copié en skills personnels** : sans hook, masquable par `skillOverrides`, mais ses renvois internes `superpowers:<skill>` ne résolvent plus.

## Consequences

- Coût accepté : 14 descriptions superpowers en permanence, et le texte de `using-superpowers` injecté par son hook `SessionStart` (démarrage, `/clear`, compaction), dont les descriptions agressives (« You MUST use this before any creative work »).
- Critère de revue au prochain audit : si un skill de process superpowers se déclenche sur une tâche XS/S, ou si `/skill-doctor` le range parmi les coûts sans usage, basculer vers un plugin local nommé `superpowers` qui n'embarque que les skills routés et aucun hook (les renvois `superpowers:<skill>` restent alors valides).
