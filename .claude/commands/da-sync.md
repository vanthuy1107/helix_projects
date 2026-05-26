---
description: Sync da-* Claude skills and commands between the workspace and the helix_projects repo. Runs a drift check first, then asks the user which direction to mirror.
---

You are handling the `/da-sync` command. Job: keep workspace `.claude/skills/` + `.claude/commands/` in lockstep with the team's mirror in `projects/.claude/`.

## Steps

1. **Resolve the projects path.** The script lives at `<workspace>/projects/scripts/sync-da-skills.ps1`. If `projects/scripts/sync-da-skills.ps1` doesn't exist under the current workspace, STOP and tell the user: "helix_projects isn't cloned into `projects/` yet — clone it first or run from a workspace that has it."

2. **Run drift check.** Execute:
   ```
   & "<workspace>/projects/scripts/sync-da-skills.ps1" -Mode check
   ```
   Use the Bash or PowerShell tool. Capture stdout.

3. **If output says "No drift"** → report success in one line and stop. Nothing else to do.

4. **If drift is detected**, show the user the diff list verbatim, then ask:
   > "Drift detected. Pick direction:
   > **push** = workspace → projects (you just edited a skill/command locally and want to share),
   > **pull** = projects → workspace (teammate updated the team repo),
   > **cancel** = bail out."

5. **Wait for the user's pick.** Don't guess. If they say push or pull, run with `-Force`:
   ```
   & "<workspace>/projects/scripts/sync-da-skills.ps1" -Mode <push|pull> -Force
   ```
   If they say cancel or anything ambiguous, stop without running.

6. **After push:** remind the user to commit + push the change to helix_projects:
   ```
   git -C "<workspace>/projects" status
   git -C "<workspace>/projects" add .claude/
   git -C "<workspace>/projects" commit -m "feat(skills|commands): <one-line why>"
   git -C "<workspace>/projects" push origin main
   ```
   Don't run these automatically — show them and let the user confirm. Follow `/da-projects` Task A/B rules.

7. **After pull:** tell the user to **restart Claude Code** to load updated skills/commands (Claude Code only scans `.claude/` at startup).

## Rules

- Always `check` first. Never push or pull blind.
- Strict mirror: both push and pull DELETE extras on the destination side. Show the diff before asking direction so the user sees exactly what's about to move.
- Never run both push and pull in the same invocation.
- If `check` exits with code other than 0 or 1, surface the raw output to the user (script error).
- This command only touches `.claude/skills/da-*/` and `.claude/commands/da-*.md`. Non-da assets are ignored by the script — don't try to expand scope.
