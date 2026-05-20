# R12-CUSTOM-SYSTEM-CLOCK-CORPUS-WIDENING: Custom System Clock Corpus Widening

## Metadata

- Tree ID: `R12-CUSTOM-SYSTEM-CLOCK-CORPUS-WIDENING`
- Status: `active`
- Roadmap lane: `R12`
- Created: `2026-05-21`
- Last updated: `2026-05-21`
- Owner: repo-local workflow

## Goal

Promote already-focused supported custom `+system` clock-name behavior into the
maintained supported-smoke regression corpus with strict-supported coverage and
public support-accounting visibility.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not change strict-mode policy for legacy or misleading reset spellings
  such as `(sreset rstn)` or `(asreset rstn)`.
- Do not widen malformed `+system` diagnostics; those are already covered by
  the existing system-section expected-failure tree.
- Do not change ISF timing defaults or actor timing conventions.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes a canonical `+system` declaration with a
  non-default clock identifier into a named supported-smoke catalog entry.
- The new entry records strict-supported metadata and compiled HDL-shape
  expectations proving the authored clock is emitted as the system clock while
  the canonical reset policy remains unchanged.
- Supported corpus behavior, check JSON, normalized semantic JSON, manifest,
  and docs stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-CUSTOM-SYSTEM-CLOCK-CORPUS-WIDENING`
  Status: `active`
  Goal: `widen maintained supported-smoke corpus coverage for supported custom system clock names`
  Children: `R12-CUSTOM-SYSTEM-CLOCK-CORPUS-WIDENING.1`, `R12-CUSTOM-SYSTEM-CLOCK-CORPUS-WIDENING.2`

- ID: `R12-CUSTOM-SYSTEM-CLOCK-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the custom system clock corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-CUSTOM-SYSTEM-CLOCK-CORPUS-WIDENING.1: select custom system clock widening`

- ID: `R12-CUSTOM-SYSTEM-CLOCK-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add a maintained supported-smoke entry for custom system clock names`
  Acceptance: `named fixture/catalog entry covers a canonical reset declaration with custom authored clock name with strict-supported checks and HDL-shape expectations`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-CUSTOM-SYSTEM-CLOCK-CORPUS-WIDENING.2` | `pending` | Ownership is selected; the next slice can promote the already-focused custom-clock behavior into the maintained corpus. |

## Decisions

- `2026-05-21`: Selected custom system clock names because
  [t/31-language-contract-system-section.t](../../t/31-language-contract-system-section.t)
  already locks non-canonical clock identifiers, while maintained positive
  system-contract corpus entries currently cover canonical `clk` with
  canonical reset policy only.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-21` | `R12-CUSTOM-SYSTEM-CLOCK-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-CUSTOM-SYSTEM-CLOCK-CORPUS-WIDENING.1` | `R12-CUSTOM-SYSTEM-CLOCK-CORPUS-WIDENING.1: select custom system clock widening` | Selection leaf; no compiler behavior changed. |
| `R12-CUSTOM-SYSTEM-CLOCK-CORPUS-WIDENING.2` | `pending` | `pending` |

## Changelog

- `2026-05-21`: Created task tree and selected the next implementation
  frontier.
