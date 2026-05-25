# ROADMAP-R14-PORT-BINDING-HISTORICAL-TRUTH-SYNC: Port Binding Historical Truth Sync

## Metadata

- Tree ID: `ROADMAP-R14-PORT-BINDING-HISTORICAL-TRUTH-SYNC`
- Status: `done`
- Roadmap lane: `R14 roadmap maintenance`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Update older live recovery notes around `ISF-PORT-BINDING.5` so they mention
later R14 port-binding slices that have since shipped.

## Non-Goals

- Do not change parser behavior, scheduler lowering, generated `.fsm`, HDL,
  schedule-report payloads, public contract code, or runtime behavior.
- Do not rewrite the full historical timeline.
- Do not select a new transaction-port behavior surface.

## Acceptance Criteria

- `ROADMAP_STATUS.md` no longer leaves the closed `ISF-PORT-BINDING.5` note
  as the apparent current source of truth for remaining port-binding work.
- `MEMORY.md` records that later slices shipped expression-valued input
  bindings, generated-child rule-trigger output bindings, current-timing
  assertions, and binding-report metadata additions.
- Live docs, README task index, and task tree record the documentation-only
  boundary.
- Focused recovery-doc validation passes.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ROADMAP-R14-PORT-BINDING-HISTORICAL-TRUTH-SYNC`
  Status: `done`
  Goal: `Synchronize older port-binding recovery notes with later shipped slices.`
  Children: `ROADMAP-R14-PORT-BINDING-HISTORICAL-TRUTH-SYNC.1`

- ID: `ROADMAP-R14-PORT-BINDING-HISTORICAL-TRUTH-SYNC.1`
  Status: `done`
  Goal: `Clarify stale historical port-binding deferred-surface wording.`
  Acceptance: `Older recovery notes point to later shipped slices and leave only actually remaining surfaces as deferred.`
  Verification: `recovery-doc grep; live-doc/book audits; mdBook build; git diff --check`
  Commit: `ROADMAP-R14-PORT-BINDING-HISTORICAL-TRUTH-SYNC.1: sync port binding history`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| `_None_` | `_None_` | `_None_` | Tree closed. |

## Decisions

- `2026-05-25`: Preserve historical context but append later shipped-slice
  truth so recovery readers do not treat old deferred lists as current
  roadmap direction.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ROADMAP-R14-PORT-BINDING-HISTORICAL-TRUTH-SYNC.1` | `rg -n "Later R14 slices shipped|Remaining transaction-port binding surfaces" ROADMAP_STATUS.md MEMORY.md`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ROADMAP-R14-PORT-BINDING-HISTORICAL-TRUTH-SYNC.1` | `ROADMAP-R14-PORT-BINDING-HISTORICAL-TRUTH-SYNC.1: sync port binding history` | `documentation truth-sync commit` |

## Changelog

- `2026-05-25`: Created and completed the historical port-binding recovery-note
  truth-sync tree.
