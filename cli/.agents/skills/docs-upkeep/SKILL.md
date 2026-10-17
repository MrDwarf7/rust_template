---
name: docs-upkeep
description: Keep project docs current when features or behavior change.
---

# Docs upkeep

Whenever a feature or behavior is added or changed:

1. Run `uv run scripts/update-docs-index.py --new "<Title>"` from the project root.
2. Fill in the new doc and update the relevant existing docs.
3. Run `uv run scripts/update-docs-index.py`, then `uv run scripts/update-docs-index.py --check`.
