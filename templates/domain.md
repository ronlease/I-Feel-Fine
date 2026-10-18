# Domain

Single source for domain concepts and rules. It describes what the code does today. Feature READMEs document endpoints. Backlog items document intent.

## Concepts

- **<Term>**: <definition, with the fields or rules that matter>.

## Rules

Group rules by topic. State each as something a test can check.

### <Topic>

- <Rule, with exact boundaries: "below 10 gives X, 10 and above gives Y">.

## Required tests

The implementer agent writes a test for each entry that applies to the area it touches. Keep entries short, concrete and at the boundary.

- <Behavior> returns <result>, never <wrong result>.
- <Boundary>: value A gives X, value B gives Y.
- Empty input returns an empty result without throwing.
