# stop-verify (hook)

Plugin: `dotnet-angular`

## What it does

Runs when Claude finishes a turn. If any `.cs` file changed, it checks for unacknowledged destructive migrations and runs `dotnet build`. A failure goes back to Claude with the last 30 lines of errors. A build that exceeds the time limit counts as a skip.

It honors `stop_hook_active`, so a build that stays broken cannot trap Claude in a loop.

## Why

A broken build found at the end of a turn costs one more turn. Found at the pull request, it costs a review cycle.

## How to adapt

Set `solution` (a path relative to the repo) and `stopVerifyTimeoutSeconds` (default 25, keep it under the 30 second hook timeout) in `.claude/ifeelfine.json`. Without `solution` the hook builds the shallowest `.slnx`, `.sln` or `.csproj` within four folders.
