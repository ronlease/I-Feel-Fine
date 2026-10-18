# guard-destructive-migration (hook)

Plugin: `dotnet-angular`

## What it does

Blocks an EF Core migration that contains `DropTable`, `DropColumn`, `DropSchema`, `DropSequence`, or raw SQL that drops, truncates or deletes, unless the file also has a comment line `// DESTRUCTIVE-ACK: <reason>`.

It runs three ways: before Edit and Write (judges the file as it will look after the write), after `dotnet ef migrations add` (scans files git reports), and from `stop-verify`.

## Why

A migration can delete data when it runs. A written reason forces a pause, and the block message tells Claude to tell you what is lost.

## How to adapt

The check is plain text matching in `violates()`. Add keywords there. The acknowledgement format is one regex in the same function.
