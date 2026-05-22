# helix_projects

Per-tenant project workspaces for the Smartlog Control Tower codebase. Lives under `<repo>/projects/` locally but is gitignored from the main repo (line 52 of the smartlog `.gitignore`) and synced to its own remote.

## Layout

- `assessments/` — internal assessment exercises & datasets
- `mondelez/` — Mondelez tenant section docs, data audits, build artifacts
- `panasonic/` — Panasonic (PSV pipeline) tenant artifacts
- `pm/` — PM-side reviews and sign-offs
- `trace/` — drift / spec-vs-implementation trace reports

## Convention

Section-level docs follow `{section}-prd.md` / `{section}-spec.md` / `{section}-wireframe.md`. Analyses go under `{section}/analysis/`. See per-folder READMEs for details.
