# ISF-WAIT-ZERO: Zero-Count Transaction Wait

## Metadata

- Tree ID: `ISF-WAIT-ZERO`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-15`
- Last updated: `2026-05-15`
- Owner: repo-local workflow

## Goal

Ship a precise `(wait 0)` semantics for ISF transactions so zero-count waits
are no longer a deferred edge case.

## Non-Goals

- Dynamic wait counts such as `(wait cycles)`.
- Symbolic wait counts whose value is resolved through parameters or constants.
- Counter-based wait lowering.

## Acceptance Criteria

- `(wait 0)` is accepted wherever shipped literal waits are accepted.
- `(wait 0)` emits no wait state, consumes no active transaction cycle, and
  creates no `transaction_waits[]` report entry.
- Pending samples before `(wait 0)` are preserved for the next
  state-producing clause.
- Malformed negative, dynamic, list, missing, and extra-operand waits still
  fail closed.
- Focused wait regression and broader ISF checks pass.
- The mdBook, ISF spec, public contract docs, roadmap status, and live docs
  describe the shipped behavior.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-WAIT-ZERO`
  Status: `done`
  Goal: `Ship zero-count literal wait semantics.`
  Children: `ISF-WAIT-ZERO.1`

- ID: `ISF-WAIT-ZERO.1`
  Status: `done`
  Goal: `Implement and document transparent zero-count wait lowering.`
  Acceptance: `(wait 0)` is a no-op in top-level and inline transaction wait
  contexts, docs are synchronized, and validation passes.
  Verification: `pass`
  Commit: `ISF-WAIT-ZERO.1: ship zero-count wait semantics`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-WAIT-ZERO.1` | `done` | Removes a documented deferred edge case from the shipped wait surface. |

## Decisions

- `2026-05-15`: `(wait 0)` means no delay. It emits no generated wait state,
  consumes no active transaction cycle, and creates no `transaction_waits[]`
  entry.
- `2026-05-15`: Pending samples before `(wait 0)` remain pending and attach to
  the next state-producing clause. The zero wait does not materialize or drop
  them.
- `2026-05-15`: Dynamic and symbolic wait counts remain backlog because they
  require width, reset, latency, and report semantics.

## Open Questions

- None for this leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-15` | `ISF-WAIT-ZERO.1` | `perl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `prove -Iperl t/1244-isf-wait-clause-lowering.t` | `pass` |
| `2026-05-15` | `ISF-WAIT-ZERO.1` | `prove -Iperl t/1237-isf-fifo-library-fixture.t t/1241-isf-transaction-port-bindings.t t/1244-isf-wait-clause-lowering.t` | `pass` |
| `2026-05-15` | `ISF-WAIT-ZERO.1` | `prove -Iperl t/1244-isf-wait-clause-lowering.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-WAIT-ZERO.1` | `ISF-WAIT-ZERO.1: ship zero-count wait semantics` | `pending local commit` |

## Changelog

- `2026-05-15`: Created task tree and started `ISF-WAIT-ZERO.1`.
- `2026-05-15`: Completed `ISF-WAIT-ZERO.1`.
