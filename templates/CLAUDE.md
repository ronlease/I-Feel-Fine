# <Project name>

<One or two sentences: what this project is, who uses it, how it is deployed.>

Domain rules: [docs/domain.md](docs/domain.md). Read it before touching <the risky areas>.

## Stack

- <Language and framework, versions>
- <Database>
- <Test tools>

## Commands

Run these from the repo root unless noted.

```
<build command>
<test command>
<format command>
<lint command>
```

## Workflow

- Work in thin vertical slices. One backlog item is one slice.
- Backlog: `docs/backlog/index.md` lists items. Read an item's file only when working it. Every feature needs a backlog item before code.
- Skills and agents come from the i-feel-fine plugins: `core:new-backlog-item`, `core:pre-pr`, `core:update-c4`, `core:implementer`, `core:reviewer`, and for dotnet and Angular repos `dotnet-angular:ef-migration` and `dotnet-angular:new-feature-slice`.
- Hooks come from the same plugins. Read `.claude/ifeelfine.json` to see how this repo configures them.
- Branch off `main` for all work. Commit locally as you go. Push feature branches when asked.

## Conventions

- <Naming rules>
- <Folder layout rules>
- <Where secrets live. Never hardcode credentials.>
- Writing style for docs and comments: active voice, terse, no emojis.

## Invariants

Rules that must never break. The reviewer agent tries to violate each one.

- <Invariant 1, stated as a testable sentence>
- <Invariant 2>
