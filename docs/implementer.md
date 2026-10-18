# implementer (agent)

Plugin: `core`

## What it does

Builds one backlog item as a vertical slice: reads the item, writes Gherkin as test comments, writes failing tests, then code, then docs, then marks the item Done and commits on a feature branch. Uses the `sonnet` model alias.

## Why

A slice small enough to review in one sitting ships safely. The agent carries no project rules. It reads `CLAUDE.md` and the domain doc, so it works in any repo.

## How to adapt

Put commands and conventions in `CLAUDE.md`, invariants in its Invariants section, and exact test expectations in a "Required tests" section of the domain doc. Set `backlogDir` and `backlogPrefix` in `.claude/ifeelfine.json`.
