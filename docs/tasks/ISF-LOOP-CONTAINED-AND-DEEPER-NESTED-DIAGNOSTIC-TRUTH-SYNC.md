# ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-DIAGNOSTIC-TRUTH-SYNC: Sync Book Chapters For New Targeted Diagnostics

## Metadata

- Tree ID: `ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-DIAGNOSTIC-TRUTH-SYNC`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-27`
- Last updated: `2026-05-27`
- Owner: repo-local workflow

## Goal

Update book chapters that currently mention deeper-branch and
loop-contained repeat activation deferrals to also mention the new
targeted diagnostics shipped by
`ISF-LOOP-CONTAINED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION` and
`ISF-DEEPER-NESTED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION`. The
`14-feature-backlog.md` and `ISF_DOWNSTREAM_INTEGRATION_SPEC.md` doc
surfaces were already synchronized when those slices shipped; this
slice extends the sync to the four book chapters that mention these
deferrals in passing.

## Non-Goals

- Do not change validator behavior, lowering, schedule reports,
  generated HDL, manifests, public API, tests, or runtime behavior.
- Do not refresh historical task-tree records.
- Do not alter prose unrelated to the targeted diagnostics.

## Acceptance Criteria

- `docs/book/src/13b-transactions.md`, `13d-control-flow.md`,
  `13h-lowering-reference.md`, and `13k-isf-feature-support-matrix.md`
  each reflect the new targeted diagnostics for loop-contained and
  deeper-nested repeat-body `do`/`spawn` (with the diagnostic
  wording or a brief reference linking to the targeted phrase).
- mdBook builds clean; `git diff --check` clean.
- `t/1305-isf-book-feature-matrix-audit.t`,
  `t/1307-isf-loop-body-doc-truth-audit.t`,
  `t/1332-isf-atl-doc-status-audit.t` continue to pass.
- Live docs (MEMORY.md, ROADMAP_STATUS.md, CHANGES.md,
  DEVELOPMENT_NOTES.md, LIVE_ACHIEVEMENT_STATUS.md, README.md,
  docs/TASK_TREE.md) reflect the truth-sync.
- The slice is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-DIAGNOSTIC-TRUTH-SYNC`
  Status: `pending`
  Goal: `Synchronize book chapters with the new targeted diagnostics.`
  Children:
    `ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-DIAGNOSTIC-TRUTH-SYNC.1`,
    `ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-DIAGNOSTIC-TRUTH-SYNC.2`

- ID: `ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-DIAGNOSTIC-TRUTH-SYNC.1`
  Status: `pending`
  Goal: `Select the truth-sync slice; record scope and target chapters.`
  Acceptance: `Task tree exists and is committed before any book change.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `pending`

- ID: `ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-DIAGNOSTIC-TRUTH-SYNC.2`
  Status: `pending`
  Goal: `Ship the synchronized book prose plus live-doc updates.`
  Acceptance: `Each of the four target chapters mentions the new targeted diagnostics; audits still pass.`
  Verification: `prove -Iperl t/1305 t/1307 t/1332; mdbook build docs/book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | Both leaves shipped. `.2` updated the four target chapters and reverified the audits. |

## Decisions

- `2026-05-27`: Picked because book chapters 13b/13d/13h/13k mention
  deeper-branch and loop-contained repeat deferrals in passing but
  pre-date the new targeted diagnostics. Other doc surfaces
  (`14-feature-backlog.md`, `ISF_SPEC.md`,
  `ISF_DOWNSTREAM_INTEGRATION_SPEC.md`) were already synchronized
  when the diagnostic-precision slices shipped.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-27` | `ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-DIAGNOSTIC-TRUTH-SYNC.1` | `mdbook build docs/book`; `git diff --check` | `PASS`; selection-only commit |
| `2026-05-27` | `ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-DIAGNOSTIC-TRUTH-SYNC.2` | `prove -Iperl t/1305 t/1307 t/1332` (Files=3, Tests=709); `mdbook build docs/book`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-DIAGNOSTIC-TRUTH-SYNC.1` | `2c77d31a ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-DIAGNOSTIC-TRUTH-SYNC.1: select loop-contained and deeper-nested diagnostic doc-truth sync` | Selection commit. |
| `ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-DIAGNOSTIC-TRUTH-SYNC.2` | `ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-DIAGNOSTIC-TRUTH-SYNC.2: ship loop-contained and deeper-nested diagnostic doc-truth sync` | `pending commit hash` |

## Changelog

- `2026-05-27`: Created doc-truth-sync task tree to extend the
  targeted-diagnostic synchronization to book chapters 13b/13d/13h/13k.
  Other doc surfaces were already synchronized when the
  diagnostic-precision slices shipped.
- `2026-05-27`: Shipped `.2`. Updated `13b-transactions.md` (deeper-
  branch/loop-contained deferral paragraph), `13d-control-flow.md`
  (deeper-branch/loop-contained reject sentence),
  `13h-lowering-reference.md` (deeper-branch/loop-contained reject
  paragraph), and `13k-isf-feature-support-matrix.md`
  (cross-domain/loop-contained/deeper-branch deferral sentence) to
  mention the new targeted diagnostics. Audits `t/1305`, `t/1307`,
  `t/1332` reverified clean.
