# reviewer (agent)

Plugin: `core`

## What it does

Reviews a diff against the item's acceptance criteria and the repo's invariants. Read-only: its tool list is Read, Grep, Glob and Bash, and the prompt limits Bash to read-only git commands. Reports findings ranked by severity with a failing input for each. Uses the `opus` model alias.

## Why

The author reads a change charitably. A reviewer with no stake and no way to fix things quietly finds more.

## How to adapt

The checks come from your `CLAUDE.md` Invariants and domain doc. Edit those. To review against a branch other than `main`, say so when you invoke it.
