# MyCC Collaboration Workspace

This workspace is designed for Claude Code and Codex collaboration.

## Core Rules

- `tasks/` is the single source of truth for task status.
- Global persona is defined only in `0-System/about-me/persona.md`.
- `.claude/` and `.codex/` are private adapter/config areas.
- Project-specific details live under `2-Projects/<project-name>/`.
- Handoffs must be written to project `handoff/` records, not only chat.

## Top-level Layout

- `.claude/` Claude-specific config and adapters
- `.codex/` Codex-specific config and adapters
- `skills-core/` shared skill core content
- `0-System/` global memory system
- `1-Inbox/` idea inbox
- `2-Projects/` active projects
- `3-Thinking/` insights and thinking notes
- `4-Assets/` reusable assets
- `5-Archive/` archived items
- `tasks/` cross-session task tracking (source of truth)
# mycc
