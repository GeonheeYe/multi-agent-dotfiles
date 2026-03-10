---
name: skill-creator
description: Guide for creating effective skills.
---

# Skill Creator

Use this skill when the user wants to create a new skill or update an existing one.

## Goal

Produce a small, reusable skill that extends the agent with focused instructions, references, and optional scripts.

## Workflow

1. Clarify the exact job the skill should help with.
2. Keep the scope narrow. One skill should solve one repeatable problem well.
3. Prefer short, explicit instructions over long theory.
4. Put reusable operational steps in `SKILL.md`.
5. Put large examples, references, or templates in sibling files only when they are needed.
6. If shell scripts or helper files make the skill safer or easier to use, add them and reference them from `SKILL.md`.

## Recommended Structure

```text
my-skill/
├── SKILL.md
├── references/
├── templates/
└── scripts/
```

## Writing Rules

- Start with a one-line description of when to use the skill.
- Explain the minimum workflow needed to apply it correctly.
- Prefer concrete steps, commands, and decision rules.
- Keep paths portable. Use `~` or `$HOME`, not user-specific absolute paths.
- Avoid tool-specific assumptions unless the skill is intentionally tied to one tool.

## Validation

Before finishing, check:

- The trigger condition is clear.
- The workflow is short enough to follow during a live task.
- Any referenced files actually exist.
- The skill does not duplicate another existing skill unnecessarily.
