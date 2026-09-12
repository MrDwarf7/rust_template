---
title: "Agent Docs Setup"
description: "First-run onboarding guide for new or bare projects. Removed after initial setup."
keywords: [onboarding, first-run, setup, agent, docs, architecture, design]
order: 0
---

# Agent Docs Setup

This file exists to guide an agent through populating project documentation
on first encounter. It is self-removing: once all relevant docs are filled in
and the user confirms the setup is complete, this file and its reference in
AGENTS.md should both be deleted.

## When to read this

Read this file ONLY if:
- The project has no commits yet (bare/scaffolded state), OR
- `docs/00_project-brief.md` still contains template placeholder text

If the project already has populated docs and a real description in AGENTS.md,
this file should not exist. If it does, something went wrong -- ask the user
before proceeding.

## Onboarding flow

Have a conversation with the user. Do NOT fill in docs with guesses or
hallucinated content. Every field should come from the user's answers or
be explicitly confirmed by them.

### Step 1: Understand the project

Ask the user:
1. What does this project do? (one paragraph for the project brief)
2. Is it a CLI, library, binary, or workspace?
3. What problem does it solve? Who is it for?
4. What language/ecosystem conventions should it follow?

Fill in `docs/00_project-brief.md` with their answers.

### Step 2: Architecture and design

Ask the user:
1. What are the main modules and their responsibilities?
2. What external dependencies or APIs does it use?
3. Are there design patterns or constraints to follow?
4. What does the data flow look like?

Create `docs/01_architecture.md` if the project is complex enough to
warrant it. For simple projects, these details can live in the brief.

### Step 3: Build and development

Confirm with the user:
1. How to build, run, and test
2. Any special setup steps (env vars, config files, databases)
3. CI/CD expectations

Create `docs/02_building.md` if the build process is non-trivial.

### Step 4: Additional docs

Based on the project, consider creating docs for:
- Feature flags or configuration
- API reference (for libraries)
- Integration guides
- Contributing guidelines

Only create docs that have real content. Do not create placeholder docs.

### Step 5: Finalize

After all relevant docs are populated:

1. Run `python3 scripts/update-docs-index.py` to regenerate the index.
2. Verify the index looks correct with `python3 scripts/update-docs-index.py --check`.
3. Confirm with the user that the docs are complete.
4. Delete this file: `docs/00_AGENT_DOCS_SETUP.md`
5. Remove the "First-run onboarding" section from `AGENTS.md` (the block
   that references this file).

The goal is that after setup, no trace of this file remains. A new agent
session should see a clean project with real docs and no onboarding artifacts.

## Notes

- Do NOT create docs "just in case." Only create what the project needs.
- All docs use YAML frontmatter (title, description, keywords, order).
  See `docs/00_project-brief.md` for the format.
- Filenames prefixed with `_` are ignored by the index script (useful for drafts).
- Keep descriptions to one line. Keywords should be lowercase, comma-separated.
- The index script auto-generates frontmatter if missing, but manual frontmatter
  is always preferred for accuracy.
