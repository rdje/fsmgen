# AGGREGATE-AUTOGROWTH-FROM-USAGE: Automatic Aggregate Growth From Usage

## Metadata

- Tree ID: `AGGREGATE-AUTOGROWTH-FROM-USAGE`
- Status: `active`
- Roadmap lane: `aggregate types and data`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Broaden aggregate shape/type inference where FSMGen can recover a safe
list/record shape from authored usage without requiring an explicit aggregate
type anchor.

## Non-Goals

- Do not claim broad aggregate autovivification across every source position
  in one slice.
- Do not make backend-owned struct/record lowering the default under this
  tree.
- Do not widen VHDL aggregate lowering under this tree.
- Do not infer aggregate shapes from ambiguous or conflicting member/index
  usage without a reviewable proof source and fail-closed diagnostics.
- Do not change code before the audit leaf selects one bounded implementation
  surface.

## Acceptance Criteria

- The current aggregate-growth boundary is audited across direct `.fsm`,
  composition, ISF lowering, tests, corpus accounting, mdBook, and live docs.
- Each behavior-bearing leaf names one bounded source position or diagnostic
  family before code changes begin.
- Shipped behavior and remaining deferrals are documented in the mdBook and
  live docs in the same slice as implementation.
- Focused validation covers accepted, rejected, and still-deferred aggregate
  shape inference cases for the changed surface.
- Broader validation runs when a leaf touches shared aggregate typing,
  composition endpoint typing, or HDL lowering paths.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `AGGREGATE-AUTOGROWTH-FROM-USAGE`
  Status: `active`
  Goal: `Broaden safe aggregate shape inference one reviewable surface at a time.`
  Children: `AGGREGATE-AUTOGROWTH-FROM-USAGE.1`,
    `AGGREGATE-AUTOGROWTH-FROM-USAGE.2`

- ID: `AGGREGATE-AUTOGROWTH-FROM-USAGE.1`
  Status: `done`
  Goal: `Select the task tree and establish the first executable frontier.`
  Acceptance: `The active tree, roadmap status, live docs, and backlog owner stance name this tree, and the next leaf is limited to an audit/design boundary before behavior changes.`
  Verification: `passed: live-book/spec/backlog audits, mdBook build, and diff check`
  Commit: `pending this commit`

- ID: `AGGREGATE-AUTOGROWTH-FROM-USAGE.2`
  Status: `pending`
  Goal: `Audit shipped aggregate-growth behavior and choose the smallest safe implementation surface.`
  Acceptance: `The audit identifies current aggregate inference sources, expected-failure or deferred aggregate source positions, relevant tests/docs, and one bounded next implementation leaf with explicit non-goals.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `AGGREGATE-AUTOGROWTH-FROM-USAGE.2` | `pending` | Aggregate inference spans type aliases, aggregate literals, partial LHS writes, composition endpoints, and backend lowering, so the next code slice must audit the current boundary before selecting one proof surface. |

## Decisions

- `2026-05-24`: The first executable leaf is an audit/design slice, not an
  implementation slice. Aggregate growth touches shared typing and backend
  emission, so a behavior-bearing slice must first identify one narrow
  source position and preserve fail-closed diagnostics for ambiguous shape
  evidence.

## Open Questions

- Which aggregate source position should be implemented first is deliberately
  left to `AGGREGATE-AUTOGROWTH-FROM-USAGE.2`.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `AGGREGATE-AUTOGROWTH-FROM-USAGE.1` | `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: Files=3, Tests=351` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `AGGREGATE-AUTOGROWTH-FROM-USAGE.1` | `pending this commit: AGGREGATE-AUTOGROWTH-FROM-USAGE.1: select aggregate autogrowth work` | `selection slice` |
| `AGGREGATE-AUTOGROWTH-FROM-USAGE.2` | `pending` | `audit/design slice` |

## Changelog

- `2026-05-24`: Created active task tree and selected the audit/design
  frontier.
