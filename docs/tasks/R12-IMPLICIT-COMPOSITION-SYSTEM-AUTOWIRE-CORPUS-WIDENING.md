# R12-IMPLICIT-COMPOSITION-SYSTEM-AUTOWIRE-CORPUS-WIDENING: Implicit Composition System Autowire Corpus Widening

## Metadata

- Tree ID: `R12-IMPLICIT-COMPOSITION-SYSTEM-AUTOWIRE-CORPUS-WIDENING`
- Status: `active`
- Roadmap lane: `R12`
- Created: `2026-05-21`
- Last updated: `2026-05-21`
- Owner: repo-local workflow

## Goal

Promote already-focused multi-child composition auto-wiring for implicit child
system ports into the maintained supported-smoke regression corpus with
strict-supported coverage and public support-accounting visibility.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not change direct implicit system-default lowering; that is covered by
  `R12-IMPLICIT-SYSTEM-DEFAULTS-CORPUS-WIDENING`.
- Do not change explicit `+system` reset semantics, named clock/reset
  remapping, or legacy reset-name compatibility.
- Do not change ISF actor timing defaults.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes a composition `?top` source whose child
  FSMs omit `+system` into a named supported-smoke catalog entry.
- The new entry records strict-supported metadata and compiled HDL-shape
  expectations proving that the generated top exposes `clk` and `rst_n` and
  auto-wires both implicit child system ports.
- Supported corpus behavior, check JSON, normalized semantic JSON, manifest,
  and docs stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-IMPLICIT-COMPOSITION-SYSTEM-AUTOWIRE-CORPUS-WIDENING`
  Status: `active`
  Goal: `widen maintained supported-smoke corpus coverage for implicit composition system-port auto-wiring`
  Children: `R12-IMPLICIT-COMPOSITION-SYSTEM-AUTOWIRE-CORPUS-WIDENING.1`, `R12-IMPLICIT-COMPOSITION-SYSTEM-AUTOWIRE-CORPUS-WIDENING.2`

- ID: `R12-IMPLICIT-COMPOSITION-SYSTEM-AUTOWIRE-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the implicit composition system autowire corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-IMPLICIT-COMPOSITION-SYSTEM-AUTOWIRE-CORPUS-WIDENING.1: select implicit composition autowire widening`

- ID: `R12-IMPLICIT-COMPOSITION-SYSTEM-AUTOWIRE-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add a maintained supported-smoke entry for implicit composition system auto-wiring`
  Acceptance: `named fixture/catalog entry covers child FSMs that omit +system with strict-supported checks and HDL-shape expectations for top-level clk/rst_n auto-wiring`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-IMPLICIT-COMPOSITION-SYSTEM-AUTOWIRE-CORPUS-WIDENING.2` | `pending` | Ownership is selected; the next slice can promote already-focused composition implicit-system auto-wiring into the maintained corpus. |

## Decisions

- `2026-05-21`: Selected implicit composition system auto-wiring because
  [t/74-language-contract-implicit-system-defaults.t](../../t/74-language-contract-implicit-system-defaults.t)
  already locks multi-child composition auto-wiring of implicit `clk` and
  `rst_n`, while maintained positive composition corpus entries do not yet
  isolate that system-port behavior.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-21` | `R12-IMPLICIT-COMPOSITION-SYSTEM-AUTOWIRE-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-IMPLICIT-COMPOSITION-SYSTEM-AUTOWIRE-CORPUS-WIDENING.1` | `R12-IMPLICIT-COMPOSITION-SYSTEM-AUTOWIRE-CORPUS-WIDENING.1: select implicit composition autowire widening` | Selection leaf; no compiler behavior changed. |
| `R12-IMPLICIT-COMPOSITION-SYSTEM-AUTOWIRE-CORPUS-WIDENING.2` | `pending` | `pending` |

## Changelog

- `2026-05-21`: Created task tree and selected the next implementation
  frontier.
