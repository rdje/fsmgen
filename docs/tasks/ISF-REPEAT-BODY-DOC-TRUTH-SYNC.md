# ISF-REPEAT-BODY-DOC-TRUTH-SYNC: Repeat Body Documentation Truth Sync

## Metadata

- Tree ID: `ISF-REPEAT-BODY-DOC-TRUTH-SYNC`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Synchronize user-facing and downstream-facing documentation with the currently
shipped repeat-body clause surface.

## Non-Goals

- Do not change parser, scheduler, emitter, schedule-report, generated `.fsm`,
  or HDL behavior.
- Do not add new repeat-body clause support.
- Do not reopen child activation, nested loop, stage, or contract support
  inside repeat bodies.

## Acceptance Criteria

- The mdBook and ISF spec state the current shipped repeat-body clause family:
  named drive calls, `await`, `sample`, `update`, `set`, `shift_left`,
  `shift_right`, `assemble`, `extract`, actor-owned bank `store`/`load`, and
  shipped `wait` clauses.
- The docs remain explicit that child activation, await-sync, stage, contract,
  and nested loop forms remain outside the shipped repeat-body subset.
- A focused audit prevents the repeat-body docs from losing the shipped
  `set`/`store`/`load`/`wait` entries again.
- Live docs, task index, README, roadmap status, and change history are
  synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-BODY-DOC-TRUTH-SYNC`
  Status: `done`
  Goal: `Correct and audit repeat-body shipped-subset documentation.`
  Children: `ISF-REPEAT-BODY-DOC-TRUTH-SYNC.1`

- ID: `ISF-REPEAT-BODY-DOC-TRUTH-SYNC.1`
  Status: `done`
  Goal: `Synchronize repeat-body shipped clause lists in the book and spec.`
  Acceptance: `The book/spec repeat-body lists include every currently shipped repeat-body family and the audit locks those terms.`
  Verification: `perl -Iperl -c t/1304-isf-repeat-body-doc-truth-audit.t`; `prove -Iperl t/1304-isf-repeat-body-doc-truth-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check`
  Commit: `ISF-REPEAT-BODY-DOC-TRUTH-SYNC.1: sync repeat body docs`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-REPEAT-BODY-DOC-TRUTH-SYNC.1` | `done` | The repeat docs now include shipped `set`, `store`, `load`, and `wait` body clauses and audit that list. |

## Decisions

- `2026-05-16`: Treat this as documentation-truth synchronization. The
  implementation already ships the listed repeat-body forms; this tree only
  makes the book/spec truthful and adds an audit.

## Open Questions

- None for the current leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-REPEAT-BODY-DOC-TRUTH-SYNC.1` | `perl -Iperl -c t/1304-isf-repeat-body-doc-truth-audit.t`; `prove -Iperl t/1304-isf-repeat-body-doc-truth-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | passed; ISF gate Files=210, Tests=827 |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-BODY-DOC-TRUTH-SYNC.1` | `ISF-REPEAT-BODY-DOC-TRUTH-SYNC.1: sync repeat body docs` | Documentation truth-sync slice. |

## Changelog

- `2026-05-16`: Created task tree and selected the repeat-body documentation
  truth-sync leaf.
- `2026-05-16`: Synchronized repeat-body shipped clause lists in the mdBook,
  ISF spec, downstream handoff, and public contract doc; added the focused doc
  truth audit.
