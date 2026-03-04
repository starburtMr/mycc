# AGENTS

Codex execution rules for this workspace.

## Persona Source

- Use `0-System/about-me/persona.md` as the single persona source.
- Do not redefine persona in this file.

## Scope

- Codex can write shared zones and `.codex/`.
- Codex must not modify `.claude/` unless explicitly requested by the user.

## Task System

- `tasks/` is the only task source of truth.
- Every task transition must be reflected in `tasks/`.

## Handoff

- Handoffs must include: `progress`, `next_step`, `blocker`, `verification`, `risk`, `decision_needed`.
