# I-Feel-Fine

Guardrails, agents and skills for working with Claude Code, packaged as two plugins. Install them, read the short header in each file to see what it enforces and why, then adapt them to your own repos.

## Philosophy

- **Guardrails you can read.** Each hook is a short bash script. A comment block at the top says what it enforces and why.
- **Quiet when unused.** A hook for a tool you do not have exits silently. You never see failures from hooks you cannot use.
- **Rules live in your repo.** The plugins carry no project knowledge. Agents and skills read your `CLAUDE.md`, your domain doc and an optional `.claude/ifeelfine.json`.
- **Cautious defaults.** The kit asks before risky actions. Permissive choices stay in your own settings.

## Prerequisites

- Claude Code with plugin support (`claude plugin --help` works).
- `bash` and `jq`. Every hook needs `jq` to read Claude Code's JSON. Without it the hooks do nothing, and a session-start line tells you so. Install: `brew install jq`, `sudo apt install jq`, `choco install jq`.
- `git`.
- For `dotnet-angular`: the .NET SDK for the build and format hooks, and a local `node_modules/.bin/prettier` for web formatting. Each is optional. The hooks skip what is missing.

Hooks use portable bash (works with the bash 3.2 that ships on macOS).

## Install

In Claude Code:

```
/plugin marketplace add ronlease/I-Feel-Fine
/plugin install core@i-feel-fine
/plugin install dotnet-angular@i-feel-fine
```

Or enable them per repo by copying `templates/settings.cautious.json` to `.claude/settings.json`. Committing `enabledPlugins` does not install anything for teammates. Each person runs the install commands once (use `--scope project` to record it in the repo).

To try a local checkout without installing:

```
claude --plugin-dir ./plugins/core --plugin-dir ./plugins/dotnet-angular
```

Check your changes with `claude plugin validate .` and `claude plugin validate plugins/core`.

## What is in it

```
.claude-plugin/marketplace.json     marketplace "i-feel-fine"
plugins/core/                       works on any stack
  agents/                           implementer, reviewer
  skills/                           new-backlog-item, pre-pr, update-c4
  hooks/                            guard-main, session-start, lib
plugins/dotnet-angular/             dotnet, EF Core, npm, prettier
  skills/                           ef-migration, new-feature-slice
  hooks/                            guard-paths, guard-destructive-migration,
                                    format-on-edit, stop-verify
templates/                          copy-in starters, never auto-loaded
tests/                              hook tests and fixtures
docs/                               one short page per component
```

Skills appear namespaced: `/core:pre-pr`, `/dotnet-angular:ef-migration`. Agents appear as `core:implementer` and `core:reviewer`.

## Set up a repo

1. Install the plugins.
2. Copy `templates/CLAUDE.md` to your repo root and fill it in. Commands and Invariants matter most.
3. Copy `templates/domain.md` to `docs/domain.md` if you have domain rules worth protecting.
4. Optionally copy `templates/ifeelfine.json` to `.claude/ifeelfine.json`. See [docs/configuration.md](docs/configuration.md).
5. Copy permissions from `templates/settings.cautious.json` into `.claude/settings.json`. Plugins cannot ship permissions, so those stay in your settings.

## Docs

- [Configuration](docs/configuration.md)
- Hooks: [guard-main](docs/guard-main.md), [session-start](docs/session-start.md), [guard-paths](docs/guard-paths.md), [guard-destructive-migration](docs/guard-destructive-migration.md), [format-on-edit](docs/format-on-edit.md), [stop-verify](docs/stop-verify.md)
- Agents: [implementer](docs/implementer.md), [reviewer](docs/reviewer.md)
- Skills: [new-backlog-item](docs/new-backlog-item.md), [pre-pr](docs/pre-pr.md), [update-c4](docs/update-c4.md), [ef-migration](docs/ef-migration.md), [new-feature-slice](docs/new-feature-slice.md)
- [Templates](docs/templates.md)
- [Tests](docs/testing.md)

## Develop

```
bash tests/run.sh
shellcheck plugins/*/hooks/*.sh tests/run.sh
```

`plugins/dotnet-angular/hooks/lib.sh` is a copy of `plugins/core/hooks/lib.sh`, because each plugin installs on its own. Edit the core copy and copy it over. CI fails if they differ.

## License

MIT. See [LICENSE](LICENSE).
