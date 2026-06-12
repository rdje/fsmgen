# PPIF-FEATURE-BACKLOG-CLI-MODES-SYNC: Sync PPIF Feature-Backlog CLI Modes

## Metadata

- Tree ID: `PPIF-FEATURE-BACKLOG-CLI-MODES-SYNC`
- Status: `done`
- Roadmap lane: `IAL2 horizon exploration / mdBook truth sync`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Keep the canonical mdBook feature-backlog IAL2 section aligned with the
capability manifest's `.ppif` `supported_cli_modes[]` metadata.

## Non-Goals

- Do not change parser, lowering, manifest, CLI, report, HDL, or test behavior.
- Do not add new `.ppif` syntax, aliases, objects, or AXI manager behavior.
- Do not reopen broader IAL2 feature selection.

## Acceptance Criteria

- `docs/book/src/14-feature-backlog.md` states that the `.ppif`
  file-surface manifest entry publishes supported CLI modes.
- The wording names the user-facing `.ppif` report/check modes without
  implying broader `.ppif` syntax or full AXI manager support.
- mdBook, feature-backlog audit, docs path audit, task tree, and `MEMORY.md`
  stay aligned.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `PPIF-FEATURE-BACKLOG-CLI-MODES-SYNC`
  Status: `done`
  Goal: `Sync the feature-backlog IAL2 section with PPIF manifest CLI-mode metadata.`
  Children: `PPIF-FEATURE-BACKLOG-CLI-MODES-SYNC.1`

- ID: `PPIF-FEATURE-BACKLOG-CLI-MODES-SYNC.1`
  Status: `done`
  Goal: `Document .ppif supported_cli_modes in the feature-backlog IAL2 section.`
  Acceptance: `The feature-backlog IAL2 section names supported_cli_modes[] and the shipped .ppif report/check modes while preserving first-slice boundaries.`
  Verification: `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1414-docs-relative-paths-audit.t`; `scripts/check_memory_architecture.sh`; `git diff --check`
  Commit: `PPIF-FEATURE-BACKLOG-CLI-MODES-SYNC.1: sync PPIF backlog CLI modes`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `PPIF-FEATURE-BACKLOG-CLI-MODES-SYNC.1` | `done` | The feature-backlog IAL2 section now names `.ppif` `supported_cli_modes[]` and the shipped report/check modes. |

## Decisions

- `2026-06-12`: Treat this as a book truth-sync leaf only. The manifest
  behavior shipped under `LANGUAGE-SURFACE-FILE-CLI-MODES.1`.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `PPIF-FEATURE-BACKLOG-CLI-MODES-SYNC.1` | `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1414-docs-relative-paths-audit.t`; `scripts/check_memory_architecture.sh`; `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `PPIF-FEATURE-BACKLOG-CLI-MODES-SYNC.1` | `PPIF-FEATURE-BACKLOG-CLI-MODES-SYNC.1: sync PPIF backlog CLI modes` | `completed` |

## Changelog

- `2026-06-12`: Created task tree and selected the feature-backlog CLI-mode
  sync leaf.
- `2026-06-12`: Synced the feature-backlog IAL2 section with the `.ppif`
  manifest-supported CLI modes.
