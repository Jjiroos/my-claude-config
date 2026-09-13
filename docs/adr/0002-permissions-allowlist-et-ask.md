# Permissions : mode par défaut, allowlist, `ask` sur les actions publiques

Le mode de permission reste `default`. Les commandes courantes de build, de test et de git local sont pré-autorisées. Tout ce qui publie ou agit hors du dépôt local (`git push`, `gh pr create`, `ssh`, `docker compose down`) est en `ask`, et les formes manifestement destructrices sont en `deny`. Claude Code évalue `deny`, puis `ask`, puis `allow` : un « ne plus demander » cliqué par mégarde ne peut donc pas rendre un push silencieux. La règle répétée « je valide toujours avant de pousser » devient ainsi mécanique, au lieu de dépendre de la prose.

## Considered Options

- **`bypassPermissions` + denylist** (config de Cyril) : zéro prompt, mais une denylist ne bloque que les formes prévues (`rm -fr` passe là où `rm -rf` est bloqué).
- **`acceptEdits` + allowlist** : moins de prompts sur les éditions ; écarté au profit d'une validation des éditions une fois par session.

## Consequences

- Les règles Bash portent sur le texte de la commande : elles ne couvrent pas toutes les variantes d'invocation. Pour un blocage robuste, un hook `PreToolUse` reste nécessaire.
- Les autorisations ponctuelles accordées pendant une session atterrissent dans `.claude/settings.local.json` du projet ; l'audit les passe en revue.
