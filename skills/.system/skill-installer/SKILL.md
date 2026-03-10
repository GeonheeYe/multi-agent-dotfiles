---
name: skill-installer
description: Install Codex skills into $CODEX_HOME/skills from a curated list or a GitHub repo path.
---

# Skill Installer

Use this skill when the user wants to list installable skills, install a curated skill, or install a skill from another repository.

## Workflow

1. Determine the source of the skill:
   - existing local skill
   - curated skill provided by the environment
   - external GitHub repository
2. Inspect the source skill before copying it.
3. Install the skill under `$HOME/.codex/skills/` unless the user asked for another destination.
4. Preserve the source layout so relative references inside the skill keep working.
5. Do not overwrite an existing skill blindly. Back it up or confirm replacement if behavior would change.

## Checks

- `SKILL.md` exists in the source.
- Referenced helper files are copied with it.
- The installed path is readable by Codex.
- If the source came from GitHub, keep the repository-specific files that the skill depends on.

## Notes

- Prefer the minimal set of files required for the skill to work.
- If the user asks to sync skills into a shared dotfiles repo, install into that repo first and then link or sync it to agent-specific locations.
