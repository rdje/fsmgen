# R12-SYSTEM-SECTION-CORPUS-WIDENING: System-Section Corpus Widening

## Metadata

- Tree ID: `R12-SYSTEM-SECTION-CORPUS-WIDENING`
- Status: `done`
- Roadmap lane: `R12`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Promote already-focused malformed `+system` language-contract failures into
the maintained expected-failure regression corpus with stable diagnostics and
public report coverage.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not change strict-mode policy for legacy reset spellings.
- Do not widen ISF timing behavior in this tree.
- Do not claim all system-section behavior is exhausted; this tree covers one
  bounded malformed-`+system` subset.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, diagnostic, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes selected malformed `+system` rejection
  families into named expected-failure catalog entries.
- Each new entry records stable diagnostic-code metadata and a compiled
  diagnostic regex.
- Corpus behavior, check JSON, normalized semantic JSON, manifest, and docs
  stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-SYSTEM-SECTION-CORPUS-WIDENING`
  Status: `done`
  Goal: `widen maintained expected-failure corpus coverage for malformed system sections`
  Children: `R12-SYSTEM-SECTION-CORPUS-WIDENING.1`, `R12-SYSTEM-SECTION-CORPUS-WIDENING.2`

- ID: `R12-SYSTEM-SECTION-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the system-section corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-SYSTEM-SECTION-CORPUS-WIDENING.1: select system-section widening`

- ID: `R12-SYSTEM-SECTION-CORPUS-WIDENING.2`
  Status: `done`
  Goal: `add maintained expected-failure entries for malformed +system rejection families`
  Acceptance: `named fixtures/catalog entries cover incomplete system sections, duplicate clock/reset entries, malformed system entry structures, and invalid clock/reset identifiers with stable diagnostics and corpus behavior checks`
  Verification: `perl -Iperl -c` for touched support/tests; focused system-section tests; corpus accounting/behavior tests; manifest/check-json/semantic-json corpus gates; supported corpus gates; `git diff --check`; `mdbook build docs/book`
  Commit: `R12-SYSTEM-SECTION-CORPUS-WIDENING.2: widen system-section corpus`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `R12-SYSTEM-SECTION-CORPUS-WIDENING.2` shipped the selected system-section corpus widening. |

## Decisions

- `2026-05-20`: Selected malformed `+system` failures as the next R12 corpus
  subset because timing/system declarations are user-visible and currently
  represented mostly by focused tests rather than maintained corpus entries.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `R12-SYSTEM-SECTION-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-20` | `R12-SYSTEM-SECTION-CORPUS-WIDENING.2` | `perl -Iperl -c` for touched support/tests; focused system-section tests; corpus accounting/behavior tests; manifest/check-json/semantic-json corpus gates; supported corpus gates; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-SYSTEM-SECTION-CORPUS-WIDENING.1` | `R12-SYSTEM-SECTION-CORPUS-WIDENING.1: select system-section widening` | Selection leaf; no compiler behavior changed. |
| `R12-SYSTEM-SECTION-CORPUS-WIDENING.2` | `R12-SYSTEM-SECTION-CORPUS-WIDENING.2: widen system-section corpus` | Adds six maintained malformed `+system` expected-failure entries. |

## Changelog

- `2026-05-20`: Created task tree and selected the next implementation
  frontier.
- `2026-05-20`: Shipped the selected system-section corpus widening and closed
  the task tree.
