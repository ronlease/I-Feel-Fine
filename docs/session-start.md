# session-start (hook)

Plugin: `core`

## What it does

Runs when a session starts. Prints one line when `jq` is not installed. Always exits 0.

## Why

Every hook needs `jq` to read Claude Code's JSON and does nothing without it. A silent guard looks like a working guard, so this hook says so.

## How to adapt

Install `jq` (`brew install jq`, `apt install jq`, `choco install jq`). Delete the hook entry from `hooks.json` if you do not want the notice.
