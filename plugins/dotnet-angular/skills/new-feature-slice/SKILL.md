---
name: new-feature-slice
description: Scaffold a new feature slice in the API and the Angular app by copying the shape of an existing slice. Use when a backlog item introduces a new feature folder rather than extending an existing one.
---
<!--
Enforces: a new feature starts from the repo's own proven shape, with its README and
tests, rather than a shape Claude invents.
Why: consistent slices are easy to review and easy to find. The skill carries no folder
layout. It learns the layout from an existing slice and from CLAUDE.md, so it fits any
repo that organizes code by feature.
Config: layout, naming and the example slice to copy come from CLAUDE.md.
-->

# New feature slice

Requires a backlog item. Confirm the item id and the slice name first. Read `CLAUDE.md` for the feature folder layout, naming rules and which existing slice to copy. If it names none, pick the smallest existing slice that has the same parts you need and tell the user which one.

## Steps

1. Find the API feature folder and the Angular feature folder of the model slice. List their files. Read one of each kind (controller, service, DTO, component, routes, README, test).
2. Create the new folders with the same names and shape, in the casing `CLAUDE.md` uses for each side (for example PascalCase for the API, kebab-case for Angular).
3. API side, as the model slice has them: controller with routes and XML docs, service interface and implementation, repository only when the slice needs data access beyond the shared context, one file per DTO, README with backlog ids, endpoints and files. Register services where the model slice registers them.
4. If the slice adds an entity, add its configuration and use the `ef-migration` skill.
5. Tests: mirror the model slice's unit and integration tests. Write the Gherkin scenarios as comments above each test class. Mock external clients.
6. Angular side, as the model slice has it: standalone page component with its spec, a typed service, routes and the entry in the app routes, README.
7. Run the build and the test suites named in `CLAUDE.md`. Add a navigation entry if the slice has a page. Use the `core:update-c4` skill when you add a component.

Keep the flat folder rule if `CLAUDE.md` states one. Do not add layers the model slice does not have.
