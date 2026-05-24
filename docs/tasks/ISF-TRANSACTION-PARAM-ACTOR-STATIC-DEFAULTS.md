# ISF-TRANSACTION-PARAM-ACTOR-STATIC-DEFAULTS: Actor Static Transaction Defaults

## Metadata

- Tree ID: `ISF-TRANSACTION-PARAM-ACTOR-STATIC-DEFAULTS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Allow generated-child transaction parameter defaults to use actor-local static
values without making child scheduled artifacts depend on private parent
resolution state.

## Non-Goals

- Do not allow transaction-parameter-to-transaction-parameter default
  dependencies, cycles, or expression solving.
- Do not allow runtime interface signals or arbitrary expressions as
  transaction parameter defaults.
- Do not allow non-scalar actor parameters as scalar defaults.
- Do not change the existing rule that transaction `(params ...)` declarations
  are supported only on generated child transactions.
- Do not add package/imported constants beyond the shipped enum-member path.

## Acceptance Criteria

- Generated child transaction scalar defaults and scalar leaves inside
  compatible aggregate/list defaults may use declared actor constants and
  actor-local scalar parameter defaults by name.
- Actor-static names resolve to literal values before generated child `.fsm`
  `+params`, generated-composition summaries, and schedule-report publication,
  so downstream artifacts remain self-contained.
- Existing enum-member transaction defaults keep their authored enum tokens
  where scheduled child `.fsm` review artifacts can carry them.
- Transaction-parameter dependencies, non-scalar actor parameters, runtime
  interface signals, unknown symbols, arbitrary expressions, and malformed
  shapes fail closed with targeted diagnostics.
- The ISF spec, downstream integration handoff, public contract, mdBook, task
  tree, README index, roadmap, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-TRANSACTION-PARAM-ACTOR-STATIC-DEFAULTS`
  Status: `active`
  Goal: `Ship actor-static generated-child transaction parameter defaults.`
  Children: `ISF-TRANSACTION-PARAM-ACTOR-STATIC-DEFAULTS.1`,
  `ISF-TRANSACTION-PARAM-ACTOR-STATIC-DEFAULTS.2`

- ID: `ISF-TRANSACTION-PARAM-ACTOR-STATIC-DEFAULTS.1`
  Status: `done`
  Goal: `Select the bounded transaction parameter static-default tree.`
  Acceptance: `The task-tree owner, implementation frontier, value-domain
  boundary, publication rule, non-goals, and validation scope are recorded
  before code changes.`
  Verification: `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check`
  Commit: `pending this commit`

- ID: `ISF-TRANSACTION-PARAM-ACTOR-STATIC-DEFAULTS.2`
  Status: `pending`
  Goal: `Implement actor constants and actor scalar parameters in generated-child transaction parameter defaults.`
  Acceptance: `Lowering resolves actor-static transaction parameter defaults,
  literalizes them for child/report publication, preserves enum-token review
  behavior, rejects unsupported sources, and updates public docs/tests.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-TRANSACTION-PARAM-ACTOR-STATIC-DEFAULTS.2` | `pending` | This is the selected implementation leaf after the documentation-only tree selection. |

## Decisions

- `2026-05-24`: Generated child scheduled artifacts must stay self-contained.
  Actor constants and actor scalar parameters used by transaction parameter
  defaults will therefore be resolved to literals before child `.fsm` and
  generated-composition report publication.
- `2026-05-24`: Enum member defaults keep the existing authored-token review
  behavior because child artifacts already carry the needed enum declarations.

## Open Questions

- None for the selected bounded implementation leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `ISF-TRANSACTION-PARAM-ACTOR-STATIC-DEFAULTS.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-TRANSACTION-PARAM-ACTOR-STATIC-DEFAULTS.1` | `pending this commit: ISF-TRANSACTION-PARAM-ACTOR-STATIC-DEFAULTS.1: select transaction static defaults` | Selection commit. |
| `ISF-TRANSACTION-PARAM-ACTOR-STATIC-DEFAULTS.2` | `pending` | Implementation leaf. |

## Changelog

- `2026-05-24`: Created the active R14 task tree for actor-static generated
  child transaction parameter defaults.
