---
name: update-c4
description: Update PlantUML C4 diagrams and regenerate the committed images. Use when a change adds or removes a container, component, external system or relationship, or when the diagram render check fails.
---
<!--
Enforces: diagram sources and their rendered images change together, and diagrams
describe what is built, not what is planned.
Why: a diagram that lags the code is worse than none. Rendering from source in one
step keeps the images honest; hand-edited images drift.
Config (.claude/ifeelfine.json): renderC4Script, the script that renders the diagrams
(and verifies them with --check).
-->

# Update C4

Read `.claude/ifeelfine.json` for `renderC4Script`. If it is missing, ask the user how diagrams are rendered and stop. Do not invent a render command.

1. Find the `.puml` sources (look near the render script and under `docs/`). Read the affected files and the code they describe. Keep diagrams true to what is built.
2. Edit the `.puml` files with C4-PlantUML macros. Do not show features that `CLAUDE.md` marks as unbuilt.
3. Make sure the tools the script needs are running (often Docker), then run the render script.
4. Run it again with `--check` if it supports that flag. It must pass.
5. Commit the sources and the regenerated images together.

Never edit a rendered image by hand. List the images under `protectedPaths` in `.claude/ifeelfine.json` so the guard hook blocks it.
