---
name: stack-python
description: Conventions Python de mes projets (uv, FastAPI, SQLAlchemy 2, Alembic, pytest, ruff). Charger avant d'ajouter une dépendance, écrire une migration Alembic, utiliser une syntaxe Python récente ou lancer les tests.
paths:
  - "**/*.py"
  - "**/pyproject.toml"
  - "**/alembic.ini"
---

# Stack Python

## uv pilote tout

- Dépendance : `uv add <pkg>` ; outil de dev : `uv add --group dev <pkg>` (les projets déclarent `[dependency-groups]`).
- Chaque commande passe par `uv run` (`uv run pytest`, `uv run alembic …`) : c'est lui qui garantit le bon venv.

## Syntaxe : celle de `requires-python`

Mes projets ne ciblent pas tous la même version (3.10 et 3.12 cohabitent). Lis `requires-python` avant d'écrire une syntaxe récente : `type X = …` et les génériques PEP 695 exigent 3.12 ; `except*` et `tomllib` exigent 3.11.

## Style

`ruff` est configuré dans `pyproject.toml`. Le hook `format-python` applique `ruff format` et le tri des imports après chaque édition ; avant de conclure, lance le lint complet : `uv run ruff check`.

## Migrations Alembic

1. `uv run alembic revision --autogenerate -m "<quoi>"`.
2. Relis le script généré. L'autogenerate voit un renommage de table ou de colonne comme un drop + add, et ignore les changements de `server_default` et de valeurs d'enum PostgreSQL : corrige à la main.
3. Sur une base de dev : `uv run alembic upgrade head`, puis `downgrade -1` et `upgrade head` pour prouver la réversibilité.

Quand le `docker-compose.yml` déclare un service `migrate`, c'est lui qui applique les migrations dans cet environnement.

## Tests

`uv run pytest -q`. Les tests async reposent sur `pytest-asyncio` : lis `asyncio_mode` dans `[tool.pytest.ini_options]` avant d'ajouter des marqueurs.
