---
name: ef-migration
description: Create, check and apply an EF Core migration. Use when an entity, configuration or seed change needs a schema change. Covers scaffolding, destructive-change acknowledgement and verification on a scratch database.
---
<!--
Enforces: migrations are scaffolded by dotnet ef (never hand-written or hand-edited),
destructive changes carry a written reason, and risky migrations run on a scratch copy
of the database before they touch real data.
Why: a migration is the one change that is hard to undo. The guard-destructive-migration
hook blocks drops without a DESTRUCTIVE-ACK line. This skill is the human-readable path
that keeps you out of its way.
Config: project paths, database names and connection details come from CLAUDE.md. This
skill embeds none of them.
-->

# EF migration

Read `CLAUDE.md` for the data project path, the startup project, the database setup and how the app applies migrations. If any of that is missing, ask the user. Do not guess a project path or a database name.

## Policy

- Scaffold explicitly: `dotnet ef migrations add <Name> --project <data project>` (add `--startup-project` when the repo splits them). Never edit a generated `*.Designer.cs` or the model snapshot by hand.
- Name the migration for the change (`AddOrdersTitleIndex`). One concern per migration.
- Check `CLAUDE.md` for whether the app applies migrations at startup, and in which environments. Never apply a migration to a shared or production database from here.

## Steps

1. Change the entity and its configuration class.
2. Scaffold the migration. Read the generated `Up` and `Down`.
3. If `Up` contains `DropTable`, `DropColumn`, `DropSchema`, `DropSequence` or destructive raw SQL, add a line `// DESTRUCTIVE-ACK: <reason>` to the migration file. The `guard-destructive-migration` hook blocks the file without it. Tell the user what data is lost.
4. Put seed and reference data in the migration when the repo's convention says so.
5. Verify on a scratch copy before any real database sees the migration, especially when the app applies migrations at startup:
   - Create a scratch database from the live one (for PostgreSQL, `CREATE DATABASE <scratch> TEMPLATE <live>`, with the app stopped so no connection blocks the copy).
   - Generate the SQL: `dotnet ef migrations script <last-applied> <new> --project <data project> --output <file>`. Run it against the scratch database with errors set to stop (`-v ON_ERROR_STOP=1` for psql).
   - For heavy backfills raise the command timeout in the scratch connection string. Many drivers default to 30 seconds.
   - Check the plan of any hot query with `EXPLAIN ANALYZE`, then drop the scratch database.
6. Before a risky migration, suggest that the user take a backup. Never run a backup or restore script automatically.
7. Run the tests. Update any README that documents the schema.
