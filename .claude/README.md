# `.claude/` - Shared Claude Code skills for the helix_projects team

This folder ships **Claude Code skills** along with the per-tenant project workspaces. Teammates who clone `helix_projects` get both the docs they work on AND the `da-*` skills that drive how Claude Code interacts with them.

## What's in here

```
.claude/
  skills/
    da-biz-ba/           Business-analyst persona (process / BPMN / AS-IS-TO-BE)
    da-ch/               ClickHouse SQL & MV operations
    da-data/             Metric / KPI definition, ad-hoc SQL
    da-discovery/        Problem discovery before spec
    da-ops/              Daily operational pulse from activity log
    da-ops-release/      Stakeholder PDF release pack
    da-ops-review/       Audit /da-ops artifacts
    da-pm/               Sprint / roadmap / risk
    da-projects/         Git mechanics for this repo (helix_projects)
    da-retro/            Post-mortem / retrospective
    da-ship/             Final gate before pushing code to Dev squad review
    da-storytelling-data/  Dashboard storytelling advisor
    da-trace/            Spec vs implementation drift report
    da-triage/           Customer bug-list triage
```

Each skill is a Markdown file (`SKILL.md`) plus optional `references/` content. Claude Code loads them when its workspace contains a `.claude/skills/` folder.

## How the sync works

The **canonical** copy of each skill lives in **two places** on each developer machine:

| Location | Role |
|---|---|
| `<repo-root>/.claude/skills/da-*/` | What Claude Code actually loads when you run it inside the main `smartlog-control-tower` workspace. Gitignored from the main repo (so it doesn't pollute backend/frontend code reviews). |
| `<repo-root>/projects/.claude/skills/da-*/` | What gets committed to **this repo** (`helix_projects`) and shared with the team. |

A sync script keeps the two in lockstep:

```powershell
# Check drift (exit code 1 if any difference)
.\projects\scripts\sync-da-skills.ps1 -Mode check

# Workspace -> projects  (after YOU edited a skill, before commit)
.\projects\scripts\sync-da-skills.ps1 -Mode push

# Projects -> workspace  (after teammate pushed an update)
.\projects\scripts\sync-da-skills.ps1 -Mode pull
```

Use `-DryRun` to preview, `-Force` to skip the confirm prompt.

## Workflows

### When YOU update a skill

```
1. Edit  <repo-root>/.claude/skills/da-<name>/SKILL.md      (or references/)
2. Test locally - reload Claude Code and try the skill
3. .\projects\scripts\sync-da-skills.ps1 -Mode push
4. cd projects
5. git status                      # confirm only .claude/skills/da-<name>/ changed
6. git add .claude/skills/da-<name>/
7. git commit -m "feat(skills): <what changed and why>"
8. git push origin main
9. Tell the team: "pulled helix_projects, run sync pull"
```

### When TEAMMATE updated a skill

```
1. cd projects
2. git pull origin main
3. cd ..
4. .\projects\scripts\sync-da-skills.ps1 -Mode pull
5. Restart Claude Code to pick up the new skill content
```

### Onboarding a new teammate

```
1. Clone the main repo:    git clone <smartlog-control-tower>
2. Clone projects inside:  cd smartlog-control-tower
                           git clone https://github.com/vanthuy1107/helix_projects.git projects
3. Mirror skills out:      .\projects\scripts\sync-da-skills.ps1 -Mode pull
4. Open the workspace in Claude Code - skills are now loaded.
```

## Rules of the road

- **One direction at a time.** Never run `push` and `pull` interchangeably without a `check` first - you'll silently overwrite someone's work. The script is a strict mirror: extras on the destination side get deleted.
- **Push only what you intended.** Run `git status` inside `projects/` after push - if you see unexpected files, run `pull` to revert and re-do.
- **Don't edit `projects/.claude/skills/` directly.** It's a mirror, not the source. Edit in `<repo-root>/.claude/skills/` and push.
- **`-Force` is for CI / scripts only.** Interactively, let the confirmation prompt run so you see what's about to change.
- **Drift in CI:** `sync-da-skills.ps1 -Mode check` returns exit 1 on drift - wire it into a pre-push hook or CI step if you want hard enforcement.

## Why not symlink?

Symlinks on Windows need either Developer Mode or admin rights, and they confuse git when the link points across repos. A copy + sync script is dumber but works on every Windows machine without elevation.

## Why not a git submodule?

Git submodules would be ideologically cleanest (one canonical skills repo, both sides reference it) but add friction for PM/BA/DA teammates who aren't fluent with `git submodule update --init --recursive`. The copy-and-sync approach trades a small drift risk for zero new git concepts to learn.

## Adding a new skill

1. Create `<repo-root>/.claude/skills/da-<your-skill>/SKILL.md` with valid frontmatter (see existing skills for the schema).
2. Optionally add `references/*.md` for long-form content.
3. Test it loads in Claude Code (skill name appears in the available-skills list).
4. Run `push` -> commit -> push to helix_projects.

Skills must be prefixed `da-` to be picked up by this sync. Non-da skill folders are ignored on both sides.
