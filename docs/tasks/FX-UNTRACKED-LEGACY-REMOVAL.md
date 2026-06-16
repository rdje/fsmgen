# FX-UNTRACKED-LEGACY-REMOVAL: Untracked Legacy fx Directory Removal

## Metadata

- Tree ID: `FX-UNTRACKED-LEGACY-REMOVAL`
- Status: `done`
- Roadmap lane: `artifact cleanup / continuity`
- Created: `2026-06-16`
- Last updated: `2026-06-16`
- Owner: repo-local workflow

## Goal

Remove the unused untracked legacy `fx/` directory after verifying that active
FSMGen does not use it and no tracked files live under it.

## Non-Goals

- Do not change active `bin/fsmgen`, Perl modules, tests, generated artifacts,
  or public behavior.
- Do not remove tracked historical notes that mention legacy `fx/` behavior.
- Do not alter the active IAL2 PNT frontier.

## Acceptance Criteria

- `git ls-files fx` confirms no tracked files live under `fx/`.
- The untracked `fx/` directory is removed from the working tree.
- `git status --short` no longer reports `?? fx/`.
- The task tree and `MEMORY.md` record the cleanup and preserve the next active
  PNT owner.
- Focused memory/path/diff gates pass.
- The completed slice is committed through `COMMIT.md`.

## Task Tree

- ID: `FX-UNTRACKED-LEGACY-REMOVAL`
  Status: `done`
  Goal: `Remove the unused untracked legacy fx directory.`
  Children: `FX-UNTRACKED-LEGACY-REMOVAL.1`

- ID: `FX-UNTRACKED-LEGACY-REMOVAL.1`
  Status: `done`
  Goal: `Delete untracked fx/ and record the cleanup.`
  Acceptance: `Verify fx/ has no tracked files, remove the directory, update continuity docs, and commit the cleanup record.`
  Verification: `git ls-files fx`; `du -sh fx`; `git status --short fx` before removal; `test ! -e fx`; `git status --short`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `scripts/check_memory_architecture.sh`; `knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check`
  Commit: `FX-UNTRACKED-LEGACY-REMOVAL.1: remove unused legacy fx tree`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `FX-UNTRACKED-LEGACY-REMOVAL.1` | `done` | The user explicitly requested deletion of unused untracked `fx/`; it had no tracked files and is now absent from the working tree. |

## Decisions

- `2026-06-16`: Treat `fx/` as an unused untracked legacy directory. Active
  FSMGen uses `bin/fsmgen`; tracked references to `fx/` are historical notes,
  not runtime dependencies.
- `2026-06-16`: Keep this cleanup to filesystem removal plus continuity
  records only. No behavior-bearing code or public docs change is selected.
- `2026-06-16`: Removed `fx/` after confirming `git ls-files fx` returned no
  tracked paths; `git status --short` no longer reports `?? fx/`.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-16` | `.1` | `git ls-files fx`; `du -sh fx` reported `2.6M`; `git status --short fx` reported `?? fx/` before removal; `test ! -e fx`; `git status --short`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `scripts/check_memory_architecture.sh`; `knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check` | pass |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `FX-UNTRACKED-LEGACY-REMOVAL.1: remove unused legacy fx tree` | Pending cleanup commit. |

## Changelog

- `2026-06-16`: Created active cleanup tree and activated `.1`.
- `2026-06-16`: Completed `.1`; removed the unused untracked `fx/` directory
  and recorded the cleanup.
