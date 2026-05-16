# ISF-PARAM-WAIT-COUNTS: Parameter-Backed Wait Counts

## Metadata

- Tree ID: `ISF-PARAM-WAIT-COUNTS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Allow transaction `(wait NAME)` counts to use actor-local scalar parameter
defaults when those defaults resolve to non-negative integer literals.

## Non-Goals

- Supporting runtime parameter mutation.
- Supporting parameter-backed runtime dynamic waits.
- Supporting list or aggregate parameter defaults as wait counts.
- Supporting use-site parameter override specialization for wait counts beyond
  the current reusable-library actor specialization model.
- Changing generated wait-state timing, dynamic wait counters, or zero-count
  behavior.

## Acceptance Criteria

- `(wait PARAM)` accepts actor-local scalar parameter defaults that resolve to
  non-negative integer literals.
- Parameter-backed waits lower exactly like literal/static waits: zero counts
  remain transparent, positive counts emit fixed wait-state chains, and
  `transaction_waits[]` reports `count_kind: static`, exact cycles, and
  `count_source` equal to the authored parameter name.
- Non-scalar or non-integer parameter defaults fail closed with targeted
  diagnostics.
- The ISF spec, mdBook, public contract docs, roadmap, live docs, and focused
  tests stay synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-PARAM-WAIT-COUNTS`
  Status: `done`
  Goal: `Ship actor-parameter-backed static transaction wait counts.`
  Children: `ISF-PARAM-WAIT-COUNTS.1`

- ID: `ISF-PARAM-WAIT-COUNTS.1`
  Status: `done`
  Goal: `Accept actor scalar params as static wait counts.`
  Acceptance: `Focused wait-count tests prove lowering, reports, diagnostics, docs are synchronized, and ISF gates pass.`
  Verification: `passed`
  Commit: `ISF-PARAM-WAIT-COUNTS.1: ship parameter-backed waits`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-PARAM-WAIT-COUNTS.1` | `done` | Actor-parameter-backed static wait counts now ship with lowering, diagnostics, schedule-report, spec, downstream handoff, mdBook, and roadmap synchronization. |

## Decisions

- `2026-05-16`: Treat this as static actor-parameter default resolution only.
  Accepted parameter waits reuse the static wait report shape rather than
  adding a new `count_kind` value.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-PARAM-WAIT-COUNTS.1` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1244-isf-wait-clause-lowering.t`; `perl -Iperl -c t/1255-isf-schedule-report-golden-matrix.t`; `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `prove -l t/1244-isf-wait-clause-lowering.t t/1255-isf-schedule-report-golden-matrix.t t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book` | `passed`; focused `Files=4, Tests=115`; ISF gate `Files=227, Tests=998` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-PARAM-WAIT-COUNTS.1` | `ISF-PARAM-WAIT-COUNTS.1: ship parameter-backed waits` | Planned commit subject for this completed leaf. |

## Changelog

- `2026-05-16`: Created task tree and started the parameter-backed wait-count
  leaf.
- `2026-05-16`: Completed the actor-parameter-backed wait-count leaf. The
  lowerer now resolves actor-local scalar parameter defaults as static wait
  counts after actor constants, while non-scalar actor params, transaction
  params, and use-site override specialization remain fail-closed.
