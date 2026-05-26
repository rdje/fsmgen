# ISF-REPEAT-PRIOR-AWAITANY-SPAWN-AFTER-DO-TRUTH-SYNC: Prior-Awaitany Spawn-After-Do Truth Sync

## Metadata

- Tree ID: `ISF-REPEAT-PRIOR-AWAITANY-SPAWN-AFTER-DO-TRUTH-SYNC`
- Status: `done`
- Roadmap lane: `R14 documentation truth sync`
- Created: `2026-05-26`
- Last updated: `2026-05-26`
- Owner: repo-local workflow

## Goal

Synchronize the ISF repeat-body documentation and focused doc-truth audit with
the shipped branch-contained local-do and plain generated-child prior
multi-pending `await_any` then generated-spawn behavior.

## Non-Goals

- Do not change parser, scheduler, generated `.fsm`, HDL, schedule-report
  payloads, public APIs, or runtime behavior.
- Do not widen specialized generated-do prior-observation spawn-after-do
  variants, second post-spawn `await_any`, missing-drain, cross-domain,
  deeper-nesting, or broader outstanding-child lifetime semantics.
- Do not stage unrelated untracked local material.

## Acceptance Criteria

- Current ISF spec wording no longer says local-do or plain generated-child
  prior-observation spawn-after-do shapes remain fail-closed after they
  shipped.
- The docs still explicitly defer specialized generated-do prior-observation
  spawn-after-do variants, second post-spawn `await_any`, missing drains,
  cross-domain activation, deeper nesting, and broader lifetime semantics.
- Focused doc-truth audit coverage prevents the stale fail-closed sentence
  from returning.
- Live docs, roadmap status, task tree, README index, change history,
  development notes, and memory are synchronized.
- The leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-REPEAT-PRIOR-AWAITANY-SPAWN-AFTER-DO-TRUTH-SYNC`
  Status: `done`
  Goal: `Synchronize prior-awaitany spawn-after-do repeat documentation after local/plain generated-child shipping.`
  Children: `ISF-REPEAT-PRIOR-AWAITANY-SPAWN-AFTER-DO-TRUTH-SYNC.1`

- ID: `ISF-REPEAT-PRIOR-AWAITANY-SPAWN-AFTER-DO-TRUTH-SYNC.1`
  Status: `done`
  Goal: `Fix stale fail-closed wording and add audit coverage for shipped local/plain generated-child prior-observation spawn-after-do behavior.`
  Acceptance: `Docs distinguish shipped local/plain generated-child prior-observation spawn-after-do behavior from still-deferred specialized generated-do and unsupported forms, and focused audits pass.`
  Verification: `syntax check; focused doc/public audits; stale wording grep; mdbook build docs/book; git diff --check`
  Commit: `ISF-REPEAT-PRIOR-AWAITANY-SPAWN-AFTER-DO-TRUTH-SYNC.1: sync prior-awaitany spawn-after-do docs`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `ISF-REPEAT-PRIOR-AWAITANY-SPAWN-AFTER-DO-TRUTH-SYNC.1` synchronized prior-observation spawn-after-do docs and audit coverage. |

## Decisions

- `2026-05-26`: Treat this as documentation/audit truth sync. Behavior is
  already shipped by
  `ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-AFTER-DO.1` and
  `ISF-REPEAT-GENDO-PLAIN-PRIOR-AWAITANY-SPAWN-AFTER-DO.1`; this slice only
  removes stale contrary wording and pins audit coverage.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-26` | `ISF-REPEAT-PRIOR-AWAITANY-SPAWN-AFTER-DO-TRUTH-SYNC.1` | `perl -Iperl -c t/1307-isf-loop-body-doc-truth-audit.t`; `prove -Iperl t/1307-isf-loop-body-doc-truth-audit.t t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; stale wording grep; `mdbook build docs/book`; `git diff --check` | passed |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-REPEAT-PRIOR-AWAITANY-SPAWN-AFTER-DO-TRUTH-SYNC.1` | `ISF-REPEAT-PRIOR-AWAITANY-SPAWN-AFTER-DO-TRUTH-SYNC.1: sync prior-awaitany spawn-after-do docs` | task-scoped commit subject |

## Changelog

- `2026-05-26`: Created active documentation/audit truth-sync task tree.
- `2026-05-26`: Synchronized docs/audits and closed the task tree.
