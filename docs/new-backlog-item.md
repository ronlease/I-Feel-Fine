# new-backlog-item (skill)

Plugin: `core`

## What it does

Adds an item to the backlog: reads the index only, takes the next id, writes the item from a Gherkin template, adds the index row, and shows you the item first.

## Why

Every change gets testable acceptance criteria before code starts. Reading only the index keeps it fast as the backlog grows.

## How to adapt

Set `backlogDir` and `backlogPrefix` in `.claude/ifeelfine.json`. Start from `templates/backlog-index.md`.
