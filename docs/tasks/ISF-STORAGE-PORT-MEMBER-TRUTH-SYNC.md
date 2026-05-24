# ISF-STORAGE-PORT-MEMBER-TRUTH-SYNC: Storage-Port Member Truth Sync

## Metadata

- Tree ID: `ISF-STORAGE-PORT-MEMBER-TRUTH-SYNC`
- Status: `done`
- Roadmap lane: `R14 documentation truth sync`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Remove stale ISF resource wording that still implies `(members ...)` belongs
only to `output_bundle`, and keep the spec, book, downstream handoff, public
contract, roadmap status, task index, and live docs truthful about the shipped
`storage_port` member surface.

## Non-Goals

- Do not change parser, scheduler, report, HDL, CLI, or public runtime
  behavior.
- Do not add a new resource kind, user namespace, arbiter, storage lock, route
  mux/storage, fairness state, or lifetime ownership.
- Do not widen `storage_port` beyond explicit concrete actor-owned storage
  members for declared rule users.

## Acceptance Criteria

- `docs/ISF_SPEC.md` no longer says `(members ...)` is accepted only for
  `output_bundle`; it names both `output_bundle` and `storage_port`.
- The user-facing mdBook and downstream/public contract docs remain consistent
  with the shipped `storage_port` member boundary.
- `ROADMAP_STATUS.md`, `docs/TASK_TREE.md`, `MEMORY.md`, `CHANGES.md`,
  `DEVELOPMENT_NOTES.md`, and `LIVE_ACHIEVEMENT_STATUS.md` record the
  truth-sync completion.
- Focused documentation audits and a docs build pass.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-STORAGE-PORT-MEMBER-TRUTH-SYNC`
  Status: `done`
  Goal: `Synchronize storage-port member wording across public docs`
  Children: `ISF-STORAGE-PORT-MEMBER-TRUTH-SYNC.1`

- ID: `ISF-STORAGE-PORT-MEMBER-TRUTH-SYNC.1`
  Status: `done`
  Goal: `Correct stale storage-port member wording and close the truth-sync slice`
  Acceptance: `The public docs no longer contradict the shipped storage_port
  member surface, live docs are synchronized, and focused docs validation
  passes`
  Verification: `stale-wording source-doc audit; public live-book/spec-index/
  feature-matrix audits; mdBook build; git diff check`
  Commit: `pending this commit`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `The storage-port member truth-sync slice is complete and ready for commit.` |

## Decisions

- `2026-05-24`: Keep this as a one-leaf documentation truth-sync because the
  implementation already accepts, validates, reports, and tests `storage_port`
  members. The only defect is public-doc wording drift.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `ISF-STORAGE-PORT-MEMBER-TRUTH-SYNC.1` | source-doc stale wording audit | `passed: no stale output-bundle-only source-doc wording` |
| `2026-05-24` | `ISF-STORAGE-PORT-MEMBER-TRUTH-SYNC.1` | `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t` | `passed: Files=3, Tests=339` |
| `2026-05-24` | `ISF-STORAGE-PORT-MEMBER-TRUTH-SYNC.1` | `mdbook build docs/book` | `passed` |
| `2026-05-24` | `ISF-STORAGE-PORT-MEMBER-TRUTH-SYNC.1` | `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-STORAGE-PORT-MEMBER-TRUTH-SYNC.1` | `pending this commit: ISF-STORAGE-PORT-MEMBER-TRUTH-SYNC.1: sync storage-port member docs` | `documentation-only truth sync` |

## Changelog

- `2026-05-24`: Created and activated the task tree.
- `2026-05-24`: Corrected stale spec wording and closed the task tree.
