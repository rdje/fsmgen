# ISF-DYNAMIC-WAIT-INDEPENDENT-UPDATE-SAMPLE-COVERAGE: Dynamic Wait Samples Before Independent Updates

## Metadata

- Tree ID: `ISF-DYNAMIC-WAIT-INDEPENDENT-UPDATE-SAMPLE-COVERAGE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Lock explicit coverage for the legacy `(update lhs expr)` spelling in the
independent scalar setter zero-bypass subset.

## Non-Goals

- Changing the independent setter lowering contract shipped by
  `ISF-DYNAMIC-WAIT-INDEPENDENT-SET-SAMPLE.1`.
- Widening the accepted successor set beyond independent scalar `set` and
  `update` states.
- Reopening sample-consuming setter behavior.

## Acceptance Criteria

- A top-level `(sample ...) (wait count) (update out expr)` sequence lowers
  through the same sample-preserving zero-count clone as the canonical
  `(set out expr)` spelling.
- The regression proves the positive path exits through the original update
  state and the zero path materializes samples in the update clone.
- Live docs, roadmap, and task tree state record that this is coverage
  hardening, not a new source-language behavior change.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-DYNAMIC-WAIT-INDEPENDENT-UPDATE-SAMPLE-COVERAGE`
  Status: `done`
  Goal: `Cover independent update zero-bypass for pending-sample runtime waits.`
  Children: `ISF-DYNAMIC-WAIT-INDEPENDENT-UPDATE-SAMPLE-COVERAGE.1`

- ID: `ISF-DYNAMIC-WAIT-INDEPENDENT-UPDATE-SAMPLE-COVERAGE.1`
  Status: `done`
  Goal: `Add explicit update-spelling regression coverage for independent setter zero-bypass.`
  Acceptance: `Focused wait tests prove independent update zero-bypass and live docs record the coverage hardening.`
  Verification: `passed`
  Commit: `ISF-DYNAMIC-WAIT-INDEPENDENT-UPDATE-SAMPLE-COVERAGE.1: cover update zero-sample waits`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-DYNAMIC-WAIT-INDEPENDENT-UPDATE-SAMPLE-COVERAGE.1` | `done` | Explicit `update` coverage now prevents the legacy spelling from drifting away from canonical `set` behavior. |

## Decisions

- `2026-05-16`: Treat this as regression coverage only. The prior slice
  already made `source_kind => update` eligible through the same independent
  setter classifier as `set`.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-DYNAMIC-WAIT-INDEPENDENT-UPDATE-SAMPLE-COVERAGE.1` | `perl -Iperl -c t/1244-isf-wait-clause-lowering.t`; `prove -l t/1244-isf-wait-clause-lowering.t`; `git diff --check` | focused `Files=1, Tests=25`; diff gate passed |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DYNAMIC-WAIT-INDEPENDENT-UPDATE-SAMPLE-COVERAGE.1` | `ISF-DYNAMIC-WAIT-INDEPENDENT-UPDATE-SAMPLE-COVERAGE.1: cover update zero-sample waits` | Planned commit subject for this completed leaf. |

## Changelog

- `2026-05-16`: Created task tree and started the independent update
  zero-bypass coverage leaf.
- `2026-05-16`: Completed the leaf by adding explicit top-level `(update out
  expr)` coverage for independent pending-sample runtime wait zero-bypass.
