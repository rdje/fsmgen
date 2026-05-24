# ISF-TRANSACTION-PARAM-DEPENDENCY-DEFAULTS: Transaction Parameter Dependency Defaults

## Metadata

- Tree ID: `ISF-TRANSACTION-PARAM-DEPENDENCY-DEFAULTS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Allow generated-child transaction parameter defaults to reference earlier
scalar transaction parameter defaults without introducing a general dependency
graph, expression solver, or parent actor resolution requirement.

## Non-Goals

- Do not allow forward, self, cyclic, or non-scalar transaction parameter
  dependencies.
- Do not add arbitrary expression solving for transaction parameter defaults.
- Do not allow runtime interface signals as transaction parameter defaults.
- Do not change activation-site parameter override semantics.
- Do not change the existing rule that transaction `(params ...)` declarations
  are supported only on generated child transactions.
- Do not widen package/imported constants beyond shipped enum-member support.

## Acceptance Criteria

- Generated child transaction scalar defaults and scalar leaves inside
  compatible aggregate/list defaults may reference earlier scalar transaction
  parameter defaults by name.
- Transaction parameter dependency tokens remain authored in generated child
  `.fsm` `+params`, generated-composition child summaries, and default
  instance bindings, because the dependency is child-local and self-contained.
- The lowerer records resolved default literals internally when an earlier
  scalar transaction parameter default resolves to a numeric/exact-width value.
- Forward references, self references, cycles, non-scalar transaction
  parameters, runtime interface signals, unknown symbols, arbitrary
  expressions, and malformed shapes fail closed with targeted diagnostics.
- The ISF spec, downstream integration handoff, public contract, mdBook, task
  tree, README index, roadmap, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-TRANSACTION-PARAM-DEPENDENCY-DEFAULTS`
  Status: `active`
  Goal: `Ship earlier-scalar generated-child transaction parameter dependency defaults.`
  Children: `ISF-TRANSACTION-PARAM-DEPENDENCY-DEFAULTS.1`,
  `ISF-TRANSACTION-PARAM-DEPENDENCY-DEFAULTS.2`

- ID: `ISF-TRANSACTION-PARAM-DEPENDENCY-DEFAULTS.1`
  Status: `done`
  Goal: `Select the bounded transaction parameter dependency default tree.`
  Acceptance: `The task-tree owner, implementation frontier, value-domain
  boundary, publication rule, non-goals, and validation scope are recorded
  before code changes.`
  Verification: `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check`
  Commit: `pending this commit`

- ID: `ISF-TRANSACTION-PARAM-DEPENDENCY-DEFAULTS.2`
  Status: `pending`
  Goal: `Implement earlier scalar transaction parameter defaults inside generated-child transaction params.`
  Acceptance: `Lowering accepts earlier scalar transaction parameter
  dependencies, preserves child-local authored tokens, records resolved
  default literals, rejects unsupported sources, and updates public docs/tests.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-TRANSACTION-PARAM-DEPENDENCY-DEFAULTS.2` | `pending` | This is the selected implementation leaf after the documentation-only tree selection. |

## Decisions

- `2026-05-24`: Keep the first dependency model source-order based. A
  transaction parameter may reference only an earlier scalar transaction
  parameter default, matching the conservative actor-parameter dependency
  model and avoiding a new graph solver.
- `2026-05-24`: Preserve authored transaction-parameter dependency tokens in
  generated child `.fsm` and reports. Unlike actor constants or actor
  parameters, these names are declared in the same generated child artifact and
  are therefore self-contained.

## Open Questions

- None for the selected bounded implementation leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `ISF-TRANSACTION-PARAM-DEPENDENCY-DEFAULTS.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-TRANSACTION-PARAM-DEPENDENCY-DEFAULTS.1` | `pending this commit: ISF-TRANSACTION-PARAM-DEPENDENCY-DEFAULTS.1: select transaction param dependency defaults` | Selection commit. |
| `ISF-TRANSACTION-PARAM-DEPENDENCY-DEFAULTS.2` | `pending` | Implementation leaf. |

## Changelog

- `2026-05-24`: Created the active R14 task tree for earlier-scalar generated
  child transaction parameter dependency defaults.
