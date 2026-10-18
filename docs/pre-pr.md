# pre-pr (skill)

Plugin: `core`

## What it does

Runs the build, test, lint and format commands from `CLAUDE.md` once, then makes the checks a linter cannot: README freshness, API docs, backlog statuses, diagram currency, domain doc, leftovers. It never opens or updates the pull request.

## Why

Reviewers lose time on stale docs and debris. Mechanical gates belong in CI. This skill covers judgment.

## How to adapt

List your commands under Commands in `CLAUDE.md`. Set `renderC4Script` if you keep diagrams.
