# ROADMAP-R14-ACTIVE-LANE-STATUS-SYNC: R14 Active Lane Status Sync

## Metadata

- Tree ID: `ROADMAP-R14-ACTIVE-LANE-STATUS-SYNC`
- Status: `done`
- Roadmap lane: `R14 roadmap maintenance`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Synchronize the detailed `ROADMAP_STATUS.md` current-active-lane and R14
`Done` sections with the latest committed R14 slices.

## Non-Goals

- Do not change parser behavior, scheduler lowering, generated `.fsm`, HDL,
  schedule-report payloads, public contract code, tests, or runtime behavior.
- Do not reopen behavior-changing binding timing conversion, direct/local
  rule-trigger output bindings, or other deferred R14 behavior.

## Acceptance Criteria

- The detailed `Current active lane` completion status no longer names an
  older R14 slice as the latest completion.
- The R14 `Done` section records the latest generated `do` timing coverage,
  binding timing history sync, rule-trigger output history sync, direct
  `(on ... (params ...))` diagnostic, and this status sync.
- Task tree, README index, roadmap status, live docs, and change history
  record this as documentation-only truth synchronization.
- Focused live-doc/book validation passes.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ROADMAP-R14-ACTIVE-LANE-STATUS-SYNC`
  Status: `done`
  Goal: `Synchronize detailed R14 active-lane status with the latest committed slices.`
  Children: `ROADMAP-R14-ACTIVE-LANE-STATUS-SYNC.1`

- ID: `ROADMAP-R14-ACTIVE-LANE-STATUS-SYNC.1`
  Status: `done`
  Goal: `Update detailed roadmap recovery sections after recent R14 closures.`
  Acceptance: `Detailed live status points at the latest R14 work without changing behavior.`
  Verification: `focused live-doc/book audits; mdbook build docs/book; git diff --check`
  Commit: `ROADMAP-R14-ACTIVE-LANE-STATUS-SYNC.1: sync active lane status`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ROADMAP-R14-ACTIVE-LANE-STATUS-SYNC.1` | `done` | Detailed roadmap recovery status now matches the latest R14 closures. |

## Decisions

- `2026-05-25`: Keep this documentation-only. The top of
  `ROADMAP_STATUS.md` is already current after each recent slice; the stale
  surface is the detailed active-lane recovery text lower in the same file.

## Open Questions

- None for this sync slice.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ROADMAP-R14-ACTIVE-LANE-STATUS-SYNC.1` | `focused live-doc/book audits; mdbook build docs/book; git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ROADMAP-R14-ACTIVE-LANE-STATUS-SYNC.1` | `ROADMAP-R14-ACTIVE-LANE-STATUS-SYNC.1: sync active lane status` | Documentation-only; production behavior unchanged. |

## Changelog

- `2026-05-25`: Created active task tree for detailed R14 active-lane status
  truth synchronization.
- `2026-05-25`: Synchronized the detailed active-lane recovery text and R14
  `Done` head with the latest committed R14 slices; closed the task tree.
