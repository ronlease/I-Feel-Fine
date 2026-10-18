# ef-migration (skill)

Plugin: `dotnet-angular`

## What it does

Walks through an EF Core migration: scaffold with `dotnet ef`, read `Up` and `Down`, add `DESTRUCTIVE-ACK` for drops, verify on a scratch database copy, run tests.

## Why

A migration is the change that is hardest to undo. Verifying on a copy first catches bad SQL and slow backfills before they reach real data.

## How to adapt

Record the data project path, startup project and database setup in `CLAUDE.md`. The skill reads them from there.
