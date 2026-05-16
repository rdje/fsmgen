# ISF-BACKLOG-TRUTH-SYNC: Backlog Truth Synchronization

## Metadata

- Tree ID: `ISF-BACKLOG-TRUTH-SYNC`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Keep the canonical ISF feature backlog truthful after recently completed R14
work, so user-facing backlog text does not describe closed task trees as active
or imply that already-covered boundaries still need implementation closure.

## Non-Goals

- Do not change parser, scheduler, report, manifest, or HDL behavior.
- Do not reopen the closed activation-parameter override task tree.
- Do not widen activation-site parameter syntax.

## Acceptance Criteria

- The mdBook feature backlog accurately describes the shipped bounded surface
  for spawn, blocking `do`, and rule-trigger parameter overrides.
- The backlog accurately states that direct `(on ...)` activation parameter
  syntax is unsupported and regression-covered as fail-closed.
- The owning task tree, README, roadmap, live recovery docs, changelog, and
  development notes record the documentation-truth slice.
- Focused documentation checks pass.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-BACKLOG-TRUTH-SYNC`
  Status: `done`
  Goal: `Synchronize stale ISF backlog text after closed R14 task trees.`
  Children: `ISF-BACKLOG-TRUTH-SYNC.1`

- ID: `ISF-BACKLOG-TRUTH-SYNC.1`
  Status: `done`
  Goal: `Correct activation-parameter backlog status.`
  Acceptance: `The canonical feature backlog no longer says the activation-parameter override tree is active or that direct activation parameter implementation/test closure remains pending.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-BACKLOG-TRUTH-SYNC.1: sync activation backlog truth`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | The stale backlog entry is synchronized with the closed activation-parameter work. |

## Decisions

- `2026-05-16`: The handoff and ISF spec already describe the direct
  activation parameter boundary correctly. The stale text was isolated to the
  canonical feature backlog, so this slice updates the backlog and live
  recovery records without touching compiler behavior.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-BACKLOG-TRUTH-SYNC.1` | `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-BACKLOG-TRUTH-SYNC.1` | `ISF-BACKLOG-TRUTH-SYNC.1: sync activation backlog truth` | Corrected stale backlog wording after closed activation-parameter work. |

## Changelog

- `2026-05-16`: Created and completed the tree with
  `ISF-BACKLOG-TRUTH-SYNC.1`.
