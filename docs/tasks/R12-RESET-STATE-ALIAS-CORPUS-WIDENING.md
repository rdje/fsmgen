# R12-RESET-STATE-ALIAS-CORPUS-WIDENING: Reset-State Alias Corpus Widening

## Metadata

- Tree ID: `R12-RESET-STATE-ALIAS-CORPUS-WIDENING`
- Status: `active`
- Roadmap lane: `R12`
- Created: `2026-05-21`
- Last updated: `2026-05-21`
- Owner: repo-local workflow

## Goal

Promote already-focused supported reset-state alias behavior into the
maintained supported-smoke regression corpus with strict-supported coverage and
public support-accounting visibility.

## Non-Goals

- Do not change parser acceptance or generated HDL behavior in the selection
  leaf.
- Do not change reset semantics, reset polarity handling, or state-register
  planning.
- Do not change malformed reset-state diagnostics or broaden unrelated
  standalone DT support.
- Do not modify ISF timing defaults or actor-network behavior.

## Acceptance Criteria

- Task-tree ownership exists before fixture, catalog, test, source,
  generated-artifact, or config changes.
- The implementation leaf promotes legacy non-state reset aliases into a named
  supported-smoke catalog entry.
- The new entry records strict-supported metadata and compiled HDL-shape
  expectations proving aliases remain DT-style non-state blocks and stay out of
  encoded state comparisons.
- Supported corpus behavior, check JSON, normalized semantic JSON, manifest,
  and docs stay synchronized with the widened catalog.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R12-RESET-STATE-ALIAS-CORPUS-WIDENING`
  Status: `active`
  Goal: `widen maintained supported-smoke corpus coverage for supported reset-state aliases`
  Children: `R12-RESET-STATE-ALIAS-CORPUS-WIDENING.1`, `R12-RESET-STATE-ALIAS-CORPUS-WIDENING.2`

- ID: `R12-RESET-STATE-ALIAS-CORPUS-WIDENING.1`
  Status: `done`
  Goal: `select the reset-state alias corpus-widening slice and create task-tree ownership before implementation`
  Acceptance: `active task tree and live status identify the next implementation leaf`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `R12-RESET-STATE-ALIAS-CORPUS-WIDENING.1: select reset-state alias widening`

- ID: `R12-RESET-STATE-ALIAS-CORPUS-WIDENING.2`
  Status: `pending`
  Goal: `add a maintained supported-smoke entry for reset-state aliases`
  Acceptance: `named fixture/catalog entry covers legacy reset-state alias normalization and non-state DT HDL lowering with strict-supported checks and HDL-shape expectations`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R12-RESET-STATE-ALIAS-CORPUS-WIDENING.2` | `pending` | Ownership is selected; the next slice can promote the already-focused reset-state alias behavior into the maintained corpus. |

## Decisions

- `2026-05-21`: Selected legacy non-state reset aliases because
  [t/45-language-contract-reset-state-spellings.t](../../t/45-language-contract-reset-state-spellings.t)
  already locks parser and HDL behavior for `-syncreset`, `-syncrst`, and
  `-asyncreset`, while the maintained supported corpus does not yet expose
  that compatibility surface through support accounting.

## Open Questions

- None blocking the current frontier.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-21` | `R12-RESET-STATE-ALIAS-CORPUS-WIDENING.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R12-RESET-STATE-ALIAS-CORPUS-WIDENING.1` | `R12-RESET-STATE-ALIAS-CORPUS-WIDENING.1: select reset-state alias widening` | Selection leaf; no compiler behavior changed. |
| `R12-RESET-STATE-ALIAS-CORPUS-WIDENING.2` | `pending` | `pending` |

## Changelog

- `2026-05-21`: Created task tree and selected the next implementation
  frontier.
