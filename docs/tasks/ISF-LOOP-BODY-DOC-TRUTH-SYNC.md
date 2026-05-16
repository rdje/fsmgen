# ISF-LOOP-BODY-DOC-TRUTH-SYNC: Loop Body Documentation Truth Synchronization

## Metadata

- Tree ID: `ISF-LOOP-BODY-DOC-TRUTH-SYNC`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Synchronize dynamic loop body documentation so the ISF spec and mdBook feature
backlog list the shipped transaction `set` clause alongside the rest of the
accepted loop-body inline subset.

## Non-Goals

- Do not change parser, scheduler, emitter, schedule-report, generated `.fsm`,
  or HDL behavior.
- Do not widen loop body support beyond the already-shipped inline subset.
- Do not change the deferred status of child activation, await-sync, stage,
  contract, or nested loop forms inside loop bodies.

## Acceptance Criteria

- The ISF spec loop-body surface includes transaction `set`.
- The mdBook feature backlog loop-body surface includes transaction `set`.
- The transaction chapter remains aligned with those loop-body markers.
- A focused audit prevents the shipped loop-body `set` entry from being lost.
- Live docs and roadmap/task-tree state are synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-LOOP-BODY-DOC-TRUTH-SYNC`
  Status: `done`
  Goal: `Synchronize loop-body shipped-clause documentation.`
  Children: `ISF-LOOP-BODY-DOC-TRUTH-SYNC.1`

- ID: `ISF-LOOP-BODY-DOC-TRUTH-SYNC.1`
  Status: `done`
  Goal: `Add the shipped transaction set clause to loop-body doc surfaces.`
  Acceptance: `The spec, feature backlog, and transaction chapter all list
  set in the shipped loop-body inline subset while preserving child/nested
  deferrals.`
  Verification: `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`;
  `prove -Iperl t/1307-isf-loop-body-doc-truth-audit.t
  t/1250-isf-spec-focused-test-index-audit.t`; `mdbook build docs/book`;
  `./bin/ci-regression isf --no-book`; `git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-LOOP-BODY-DOC-TRUTH-SYNC.1` | `done` | The spec and feature backlog omitted the shipped `set` loop-body clause. |

## Decisions

- `2026-05-16`: This is a documentation-truth slice because loop-body `set`
  behavior is already shipped and documented in the transaction chapter.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-LOOP-BODY-DOC-TRUTH-SYNC.1` | `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -Iperl t/1307-isf-loop-body-doc-truth-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | passed; ISF gate Files=213, Tests=893 |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-LOOP-BODY-DOC-TRUTH-SYNC.1` | `pending` | `pending` |

## Changelog

- `2026-05-16`: Added `set` to the shipped loop-body clause wording in the
  spec and book backlog, and added a focused doc-truth audit.
