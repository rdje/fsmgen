# ISF-ATL-DOC-STATUS-TRUTH-SYNC: ATL Documentation Status Truth Sync

## Metadata

- Tree ID: `ISF-ATL-DOC-STATUS-TRUTH-SYNC`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Synchronize ATL documentation status wording after the
`ISF-ACTOR-NETWORK-ORCHESTRATION` task tree closed, so current live docs and
the mdBook no longer present the ATL tree itself as active.

## Non-Goals

- Do not change parser, scheduler, emitter, schedule-report, generated `.fsm`,
  or HDL behavior.
- Do not widen or narrow the shipped ATL v0 public contract.
- Do not remove historical changelog entries that were true when written.

## Acceptance Criteria

- The mdBook feature backlog states that the bounded ATL v0 public contract is
  shipped while broader ATL work remains backlog.
- The ATL design proposal no longer labels the ATL design tree as active.
- The roadmap status board uses historical wording for prior ATL frontiers and
  states the current tree closure truth.
- A focused audit prevents the stale active ATL status wording from returning.
- Live docs, task index, README, roadmap status, and change history are
  synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-ATL-DOC-STATUS-TRUTH-SYNC`
  Status: `done`
  Goal: `Synchronize ATL documentation status truth after tree closure.`
  Children: `ISF-ATL-DOC-STATUS-TRUTH-SYNC.1`

- ID: `ISF-ATL-DOC-STATUS-TRUTH-SYNC.1`
  Status: `done`
  Goal: `Correct stale ATL active-tree wording and audit it.`
  Acceptance: `The book, ATL design proposal, and roadmap status no longer
  claim an active ATL design tree while still preserving the shipped/deferred
  ATL v0 boundary.`
  Verification: `perl -Iperl -c t/1332-isf-atl-doc-status-audit.t`; `prove
  -Iperl t/1332-isf-atl-doc-status-audit.t
  t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff
  --check`
  Commit: `ISF-ATL-DOC-STATUS-TRUTH-SYNC.1: sync ATL doc status`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-ATL-DOC-STATUS-TRUTH-SYNC.1` | `done` | The stale active-tree wording is corrected and audited. |

## Decisions

- `2026-05-20`: Treat this as a documentation truth-sync slice. The ATL
  implementation and public contract are unchanged; only status wording and
  audit coverage should move.

## Open Questions

- None for the current leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `ISF-ATL-DOC-STATUS-TRUTH-SYNC.1` | `perl -Iperl -c t/1332-isf-atl-doc-status-audit.t`; `prove -Iperl t/1332-isf-atl-doc-status-audit.t t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | passed |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ATL-DOC-STATUS-TRUTH-SYNC.1` | `ISF-ATL-DOC-STATUS-TRUTH-SYNC.1: sync ATL doc status` | Documentation status truth-sync slice. |

## Changelog

- `2026-05-20`: Created task tree and selected the ATL documentation status
  truth-sync leaf.
- `2026-05-20`: Synchronized ATL status wording across the mdBook, ATL design
  proposal, roadmap board, and live docs; added focused audit coverage.
