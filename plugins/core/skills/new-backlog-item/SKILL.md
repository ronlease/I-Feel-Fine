---
name: new-backlog-item
description: Add a new item to the backlog. Use when the user describes a feature, fix, chore or spike that has no backlog entry, or asks for a story, business problem or acceptance criteria. Reads the index only, never the other item files.
---
<!--
Enforces: every change has a written backlog item with testable acceptance criteria
before code starts, and each item fits one vertical slice.
Why: a scenario a tester can run without asking questions is the cheapest bug fix.
Reading only the index keeps the skill fast as the backlog grows.
Config (.claude/ifeelfine.json): backlogDir (default docs/backlog), backlogPrefix (default BL).
-->

# New backlog item

Every feature needs an item before code.

Read `.claude/ifeelfine.json` if it exists. Use `backlogDir` (default `docs/backlog`) and `backlogPrefix` (default `BL`). Below, `<P>` is the prefix and `<dir>` the backlog folder.

1. Read `<dir>/index.md` only. Take the highest `<P>-###` and add one. Do not open other item files. If the index is missing, start at `<P>-001` and offer to create it from the kit's `backlog-index.md` template.
2. Write `<dir>/items/<P>-###.md` from the template below.
3. Add a row to `<dir>/index.md` with id, title, status and priority.
4. The item must fit one vertical slice (every layer it touches, plus tests). If it does not, write several items instead and note the order in each.
5. Show the user the item before writing files.

## Template

````markdown
## [<P>-###] Title

**Status:** Backlog
**Priority:** High | Medium | Low

### Business Problem
What problem this solves, for whom, and why it matters. Two to five sentences.

### Acceptance Criteria
```gherkin
Feature: Name
  Scenario: Name
    Given a precondition
    When an action
    Then an observable outcome
```
````

Status values: Backlog, Proposed, In Progress, Blocked, Done.

## Gherkin rules

- One behavior per scenario. Name the scenario for the outcome.
- Concrete values: "3 items", not "enough items".
- Observable results only: response fields, status codes, rows, UI text. Never internals.
- Cover the boundary and the failure case, not only the happy path.
- Respect the Invariants in `CLAUDE.md` and the rules in the domain doc.
- A QA reader must be able to write the test without asking a question.
- Do not gold-plate. State what is out of scope.
