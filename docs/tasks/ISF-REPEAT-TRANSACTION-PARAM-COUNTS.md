# ISF-REPEAT-TRANSACTION-PARAM-COUNTS: Repeat Transaction Parameter Counts

## Metadata

- Tree ID: `ISF-REPEAT-TRANSACTION-PARAM-COUNTS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Allow same-transaction scalar parameter defaults to provide static repeat
count values for `(repeat COUNT body...)`.

## Non-Goals

- Do not add runtime or activation-site override specialization for repeat
  counts.
- Do not add expression-valued repeat counts, aggregate/list repeat counts,
  package member/item repeat count paths, or zero-count static repeat
  semantics.
- Do not change generated child activation behavior, repeat-body scheduling
  beyond the count source, schedule-report schema, HDL handoff shape, or
  runtime behavior for existing accepted repeat counts.

## Acceptance Criteria

- A transaction-local scalar parameter default can be used as the repeat count
  in that same transaction.
- Transaction-local repeat-count parameters shadow actor-level static names.
- Transaction parameter defaults used as repeat counts must resolve to
  positive integer scalar literals; zero and aggregate/list values fail
  closed.
- Existing literal, actor-constant, actor-parameter, package-constant, and
  runtime scalar repeat-count behavior remains green.
- ISF spec, public contract, mdBook, task tree, roadmap status, live docs, and
  change history document the shipped boundary and remaining deferrals.
- Focused syntax/test validation plus live-doc/book validation passes.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-TRANSACTION-PARAM-COUNTS`
  Status: `done`
  Goal: `Ship same-transaction scalar parameter defaults as static repeat counts.`
  Children: `ISF-REPEAT-TRANSACTION-PARAM-COUNTS.1`

- ID: `ISF-REPEAT-TRANSACTION-PARAM-COUNTS.1`
  Status: `done`
  Goal: `Implement transaction parameter repeat counts and update docs/tests.`
  Acceptance: `Same-transaction scalar repeat-count params are accepted with targeted diagnostics for unsupported values.`
  Verification: `syntax checks; focused repeat/parameter-surface tests (Files=7, Tests=80); ./bin/ci-regression isf --no-book (Files=274, Tests=1745); focused public/spec/book audits (Files=4, Tests=366); mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-TRANSACTION-PARAM-COUNTS.1: support repeat transaction params`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REPEAT-TRANSACTION-PARAM-COUNTS.1` | `done` | Same-transaction scalar repeat-count params are now shipped. |

## Decisions

- `2026-05-25`: Keep transaction parameter repeat counts static. The
  parameter default resolves during lowering and provides counter-width
  evidence, and the scheduled `.fsm` repeat init loads the resolved integer
  because transaction parameters are local lowering inputs.

## Open Questions

- None for this bounded slice.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-REPEAT-TRANSACTION-PARAM-COUNTS.1` | `syntax checks; focused repeat/parameter-surface tests (Files=7, Tests=80); ./bin/ci-regression isf --no-book (Files=274, Tests=1745); focused public/spec/book audits (Files=4, Tests=366); mdbook build docs/book; git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-TRANSACTION-PARAM-COUNTS.1` | `ISF-REPEAT-TRANSACTION-PARAM-COUNTS.1: support repeat transaction params` | Shipped same-transaction scalar parameter defaults as static repeat counts. |

## Changelog

- `2026-05-25`: Created active task tree for same-transaction scalar
  parameter defaults in repeat counts.
- `2026-05-25`: Shipped same-transaction scalar parameter defaults in repeat
  counts, including shadowing, counter-width evidence, resolved scheduled
  `.fsm` load values, and fail-closed zero/non-scalar diagnostics; closed the
  task tree.
