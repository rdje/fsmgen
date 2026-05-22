# ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS: Watchdog Actor-Constant Limits

## Metadata

- Tree ID: `ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS`
- Status: `completed`
- Roadmap lane: `R14`
- Created: `2026-05-22`
- Last updated: `2026-05-22`
- Owner: repo-local workflow

## Goal

Allow watchdog limits to use declared actor constants anywhere the shipped
positive literal watchdog limit is accepted.

## Non-Goals

- Do not accept actor parameters, transaction parameters, runtime signals, or
  arbitrary expressions as watchdog limits.
- Do not change omitted watchdog defaults, watchdog counter decrement/timeout
  semantics, reset behavior, or schedule-report schema shape.
- Do not add cross-domain watchdog policy or parameterized generated-top
  watchdog specialization.

## Acceptance Criteria

- Actor-level `(watchdog LIMIT_CONST)` lowers when `LIMIT_CONST` is a declared
  actor constant whose resolved value is positive.
- Await-local `(await ready (watchdog LIMIT_CONST))` lowers through the same
  watchdog counter path as a literal override.
- Literal watchdog limits keep existing behavior and diagnostics.
- Unknown, zero-valued, parameter-backed, runtime, and expression watchdog
  limit tokens remain fail-closed with targeted diagnostics.
- The ISF spec, mdBook, downstream/public guidance where relevant, roadmap
  status, task tree, and live docs are synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS`
  Status: `completed`
  Goal: `ship positive actor constants as watchdog limits`
  Children: `ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS.1`,
  `ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS.2`

- ID: `ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS.1`
  Status: `done`
  Goal: `select the watchdog actor-constant limits task tree`
  Acceptance: `task-tree owner, source boundary, non-goals, and implementation leaf are recorded before code`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `62f2e188 ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS.1: select watchdog actor-constant limits`

- ID: `ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS.2`
  Status: `done`
  Goal: `implement and document actor-constant watchdog limits`
  Acceptance: `positive actor constants lower as literal watchdog limits; unsupported watchdog tokens fail closed; docs and focused tests are synchronized`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1331-isf-timing-conventions.t`; focused watchdog/timing/storage tests; public/doc audits; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `pending this commit`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS.2` | `done` | Completed; no remaining frontier in this tree. |

## Decisions

- `2026-05-22`: Treat actor constants as static compile-time evidence for
  watchdog limits, matching transaction wait counts, transaction latency
  bounds, and temporal contract windows. Parameters remain out of scope
  because they are overrideable specialization values.
- `2026-05-22`: Preserve the public watchdog scalar as the resolved integer
  limit. The authored constant remains visible through `actor_constants[]`.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| 2026-05-22 | `ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS.1` | `mdbook build docs/book`; `git diff --check` | Pass |
| 2026-05-22 | `ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS.2` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1331-isf-timing-conventions.t`; `prove -Iperl t/1331-isf-timing-conventions.t t/1165-isf-public-actor-shell-timing-shape-audit.t t/1095-isf-scheduler-burst-reader.t t/1106-isf-schedule-json-counter-storage.t t/1305-isf-book-feature-matrix-audit.t`; `prove -Iperl t/1112-isf-public-interface-contract.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | Pass; broad ISF gate `Files=238, Tests=1589` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS.1` | `62f2e188 ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS.1: select watchdog actor-constant limits` | Selection commit. |
| `ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS.2` | `pending this commit: ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS.2: ship watchdog actor-constant limits` | Implementation and documentation commit. |

## Changelog

- `2026-05-22`: Created active R14 task tree for positive actor constants in
  actor-level and await-local watchdog limits.
- `2026-05-22`: Shipped positive actor constants for actor-level and
  await-local watchdog limits, with parameters and dynamic limits still
  fail-closed.
