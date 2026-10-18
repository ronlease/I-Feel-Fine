# guard-main (hook)

Plugin: `core`

## What it does

Runs before every Bash call. Blocks `git commit` on `main` or `master`, blocks any push to them, blocks every force-push (`--force`, `-f`, `--force-with-lease`, `+refspec`), blocks `push --all`, `--mirror` and `--delete`, and blocks pushes that use shell expansion (`$var`, braces, globs, backslashes).

It follows `git checkout -b` and `git switch main` inside one command line. `git checkout -b x && git commit` passes. `git commit && git checkout -b x` does not.

## Why

Work belongs on feature branches, and a person merges. One slip on `main` is hard to undo, so the hook fails closed: when it cannot read a push, it refuses.

## How to adapt

Nothing to configure. To protect another branch name, edit the `PROTECTED_REF` pattern and the branch test in `plugins/core/hooks/guard-main.sh`, then add cases to `tests/run.sh`. Pair it with branch protection on your Git host, which a hook cannot replace.
