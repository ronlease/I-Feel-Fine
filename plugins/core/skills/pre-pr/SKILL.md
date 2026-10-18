---
name: pre-pr
description: Judgment checks to run before the user opens a PR from a feature branch: README freshness, API doc accuracy, backlog statuses, diagram currency. Use when work is ready for review or when asked to prepare, finalize or check a branch for a PR.
---
<!--
Enforces: the checks a linter cannot make. Do the docs still match the code? Is the
backlog status true? Are diagrams current? It never opens or updates the PR.
Why: reviewers lose time on stale docs and leftover debris. Mechanical gates (build,
tests, format, coverage) belong in CI and hooks, so this skill only runs them once and reports.
Config (.claude/ifeelfine.json): backlogDir, renderC4Script. Commands come from CLAUDE.md.
-->

# Pre-PR

Do not open or update the PR. The user does that. Push only if asked.

Read `.claude/ifeelfine.json` if it exists (`backlogDir` default `docs/backlog`, `renderC4Script` default none). Read the Commands section of `CLAUDE.md`.

## Mechanical gates (run once, report results)

Run the build, test, lint and format-check commands listed in `CLAUDE.md`. Report each as passed or failed with the failing output. If the repo sets `renderC4Script`, run it with `--check` when the diff touches diagram sources. Remove leftover coverage and test-result folders before committing.

## Judgment checks

1. **READMEs**: every feature folder touched by the diff has a README whose claims match the code. The root README structure and feature list still match.
2. **API docs**: every new or changed endpoint has a summary, parameter, response and status-code docs. Descriptions match behavior.
3. **Backlog**: the item for this branch is `Done`, its file is in `<backlogDir>/archive/`, and the index agrees. Scan `git log --oneline -20` for merged items whose status is stale and fix them.
4. **Diagrams**: if the change adds a container, component, external system or relationship, the diagram sources reflect it. Use the `core:update-c4` skill.
5. **Domain doc**: if the change alters a rule in the domain doc, update it in the same branch.
6. **Leftovers**: no TODO without a backlog item, no commented-out code, no debug output, no secrets.

## Output

A short list: gates passed or failed, then each judgment check as pass or the fix applied.
