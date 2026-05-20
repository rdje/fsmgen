# R12-STANDALONE-DT-EXPLICIT-SYSTEM-CORPUS-WIDENING: Standalone DT Explicit System Corpus Widening

## Metadata

- Tree ID: `R12-STANDALONE-DT-EXPLICIT-SYSTEM-CORPUS-WIDENING`
- Status: `active`
- Roadmap lane: `R12`
- Created: `2026-05-21`
- Last updated: `2026-05-21`
- Owner: repo-local workflow

## Goal

Promote already-focused standalone `?dt` explicit `+system` behavior into the
maintained supported-smoke regression corpus with strict-supported coverage and
public support-accounting visibility.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not promote `?dtc` composition auto-wiring in this slice; that can be a
  separate bounded corpus entry if selected.
- Do not change explicit `+system` reset semantics or legacy reset-name
  compatibility.
- Do not change standalone-DT guard or classification semantics.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes a direct `?dt` source with canonical
  explicit `+system` metadata into a named supported-smoke catalog entry.
- The supported-corpus tests understand the direct `dt` source kind and record
  strict-supported metadata plus compiled HDL-shape expectations proving
  explicit system ports are emitted without an encoded state register.
- Supported corpus behavior, check JSON, normalized semantic JSON, manifest,
  and docs stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-STANDALONE-DT-EXPLICIT-SYSTEM-CORPUS-WIDENING`
  Status: `active`
  Goal: `widen maintained supported-smoke corpus coverage for direct standalone DT explicit system contracts`
  Children: `R12-STANDALONE-DT-EXPLICIT-SYSTEM-CORPUS-WIDENING.1`, `R12-STANDALONE-DT-EXPLICIT-SYSTEM-CORPUS-WIDENING.2`

- ID: `R12-STANDALONE-DT-EXPLICIT-SYSTEM-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the standalone DT explicit-system corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-STANDALONE-DT-EXPLICIT-SYSTEM-CORPUS-WIDENING.1: select standalone DT explicit-system widening`

- ID: `R12-STANDALONE-DT-EXPLICIT-SYSTEM-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add a maintained supported-smoke entry for direct standalone DT explicit system contracts`
  Acceptance: `named fixture/catalog entry covers a canonical ?dt +system source with strict-supported checks, dt source-kind support, and HDL-shape expectations for explicit system ports without current_state`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-STANDALONE-DT-EXPLICIT-SYSTEM-CORPUS-WIDENING.2` | `pending` | Ownership is selected; the next slice can promote already-focused direct standalone-DT explicit-system behavior into the maintained corpus. |

## Decisions

- `2026-05-21`: Selected direct standalone-DT explicit-system support because
  [t/134-standalone-dt-explicit-system-support.t](../../t/134-standalone-dt-explicit-system-support.t)
  already locks `?dt` explicit-system emission, while maintained positive
  corpus entries currently exercise `?fsm` direct roots and composition tops
  but no direct `?dt` source-kind entry.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-21` | `R12-STANDALONE-DT-EXPLICIT-SYSTEM-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-STANDALONE-DT-EXPLICIT-SYSTEM-CORPUS-WIDENING.1` | `R12-STANDALONE-DT-EXPLICIT-SYSTEM-CORPUS-WIDENING.1: select standalone DT explicit-system widening` | Selection leaf; no compiler behavior changed. |
| `R12-STANDALONE-DT-EXPLICIT-SYSTEM-CORPUS-WIDENING.2` | `pending` | `pending` |

## Changelog

- `2026-05-21`: Created task tree and selected the next implementation
  frontier.
