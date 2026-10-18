# Configuration: .claude/ifeelfine.json

Optional. Put it in the repo that uses the plugins. A missing file, a missing key or broken JSON never fails a hook. Each key has a default.

| Key | Default | Used by |
|---|---|---|
| `backlogDir` | `docs/backlog` | implementer, reviewer, new-backlog-item, pre-pr |
| `backlogPrefix` | `BL` | implementer, new-backlog-item |
| `solution` | shallowest `.slnx`, `.sln` or `.csproj` within four folders | stop-verify |
| `webDir` | nearest folder above the edited file with a `package.json` | format-on-edit |
| `protectedPaths` | none | guard-paths |
| `renderC4Script` | none | update-c4, pre-pr |
| `stopVerifyTimeoutSeconds` | `25` | stop-verify |

`protectedPaths` is a list of `{ "glob": "...", "message": "..." }`. A glob with no slash also matches in any folder.

See `templates/ifeelfine.json` for a starting point. The hooks read the file with `jq`.

## Missing tools

Every hook checks for the tools it needs (`jq`, `dotnet`, node, prettier) and exits 0 without output when one is missing. `session-start` is the one exception: it prints a line when `jq` is missing, so you know the guards are off.
