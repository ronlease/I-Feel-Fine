# format-on-edit (hook)

Plugin: `dotnet-angular`

## What it does

Runs after Edit and Write. Formats `.cs` files with `dotnet format` in the nearest project that holds a `.csproj`, skipping Migrations. Formats `.ts`, `.html` and `.scss` files with the project's local prettier. It always exits 0.

## Why

Formatting is a tool's job. Doing it right after each edit keeps diffs clean and spares Claude turns spent on style.

## How to adapt

Set `webDir` in `.claude/ifeelfine.json` when your web app is not the nearest folder with a `package.json`. Prettier must be installed locally (`node_modules/.bin/prettier`); the hook skips quietly if it is not.
