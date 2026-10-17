# Project instructions

This project is a Rust CLI application.

## Commits

Use Conventional Commits. Keep the header at most 50 characters, including type and scope. Wrap the
body at 72 characters. Put any `BREAKING CHANGE:` footer at the bottom.

## Documentation

Documentation lives in `docs/`. Read `docs/INDEX.md` first, then load only the docs relevant to the
task.

## Skills

- [Docs upkeep](./.agents/skills/docs-upkeep/SKILL.md)
{% if perf_testing %}- [Hotpath profiling](./.agents/skills/hotpath-init/SKILL.md)
- [Hotpath Cloud](./.agents/skills/hotpath-cloud/SKILL.md)
- [Hotpath CI](./.agents/skills/hotpath-init-ci/SKILL.md)
- [Hotpath CI for forks](./.agents/skills/hotpath-init-ci-forks/SKILL.md)
{% endif -%}
