# update-c4 (skill)

Plugin: `core`

## What it does

Edits PlantUML C4 sources, runs your render script, verifies it with `--check` and commits sources and images together.

## Why

A diagram that lags the code is worse than none. Rendering from source keeps images honest.

## How to adapt

Set `renderC4Script` in `.claude/ifeelfine.json`. Add the rendered images to `protectedPaths`.
