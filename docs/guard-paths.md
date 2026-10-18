# guard-paths (hook)

Plugin: `dotnet-angular`

## What it does

Runs before Edit and Write. Blocks edits to `node_modules`, `bin`, `obj`, coverage output, `package-lock.json` and EF Core `*.Designer.cs` files, plus any path listed in `protectedPaths` in `.claude/ifeelfine.json`.

Matching ignores case and accepts Windows or Unix separators.

## Why

Generated files come from tools. A hand edit is lost on the next run or corrupts it. The block message tells Claude the right fix: change the source, rerun the tool.

## How to adapt

Add your own generated files to `protectedPaths`:

```json
"protectedPaths": [
  { "glob": "docs/diagrams/*.png", "message": "Rendered. Edit the source." }
]
```

A glob with no slash also matches in any folder. The built-in rules live in `plugins/dotnet-angular/hooks/guard-paths.sh`.
