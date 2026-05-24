# DYNAMIC-DIVISOR-SAFETY-FRONTIER: Dynamic Divisor Safety Proof Frontier

## Metadata

- Tree ID: `DYNAMIC-DIVISOR-SAFETY-FRONTIER`
- Status: `active`
- Roadmap lane: `language ergonomics`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Broaden divide/modulo safety beyond the currently shipped constant-expression
and ISF literal/actor-symbol checks by selecting and implementing one
reviewable proof surface at a time.

## Non-Goals

- Do not claim complete dynamic nonzero proof coverage in one task tree.
- Do not weaken existing constant-expression, ISF, or HDL-generation
  fail-closed behavior for known-zero divisors.
- Do not change expression scheduling or generated HDL before the audit leaf
  names a bounded implementation surface and proof source.
- Do not infer nonzero facts from runtime values unless the proof is explicit,
  stable, documented, and covered by focused validation.

## Acceptance Criteria

- The current divide/modulo safety boundary is audited across direct `.fsm`,
  composition, ISF lowering, tests, corpus accounting, mdBook, and live docs.
- Each behavior-bearing leaf names one bounded source position or proof family
  before code changes begin.
- Shipped behavior and remaining deferrals are documented in the mdBook and
  live docs in the same slice as implementation.
- Focused validation covers accepted, rejected, and still-deferred divisor
  cases for the changed surface.
- Broader validation runs when a leaf touches shared expression evaluation,
  scheduling, or HDL lowering paths.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `DYNAMIC-DIVISOR-SAFETY-FRONTIER`
  Status: `active`
  Goal: `Broaden divide/modulo safety proofs one reviewable surface at a time.`
  Children: `DYNAMIC-DIVISOR-SAFETY-FRONTIER.1`,
    `DYNAMIC-DIVISOR-SAFETY-FRONTIER.2`

- ID: `DYNAMIC-DIVISOR-SAFETY-FRONTIER.1`
  Status: `done`
  Goal: `Select the task tree and establish the first executable frontier.`
  Acceptance: `The active tree, roadmap status, live docs, and backlog owner stance name this tree, and the next leaf is limited to an audit/design boundary before behavior changes.`
  Verification: `passed: live-book/spec/backlog audits, mdBook build, and diff check`
  Commit: `pending this commit`

- ID: `DYNAMIC-DIVISOR-SAFETY-FRONTIER.2`
  Status: `pending`
  Goal: `Audit shipped divide/modulo safety and choose the smallest safe implementation surface.`
  Acceptance: `The audit identifies current proof sources, expected-failure or deferred runtime divisor positions, relevant tests/docs, and one bounded next implementation leaf with explicit non-goals.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `DYNAMIC-DIVISOR-SAFETY-FRONTIER.2` | `pending` | The compiler already has several shipped divisor checks, so the next code slice must audit the remaining gap before selecting one proof surface. |

## Decisions

- `2026-05-24`: The first executable follow-up is an audit/design leaf, not an
  implementation leaf. Divide/modulo safety spans constant evaluation,
  runtime expression handling, ISF lowering, and generated HDL, so a code
  slice must first identify one bounded proof source and preserve fail-closed
  behavior for known-zero divisors.

## Open Questions

- Which non-ISF or cross-surface divisor proof should be implemented first is
  deliberately left to `DYNAMIC-DIVISOR-SAFETY-FRONTIER.2`.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `DYNAMIC-DIVISOR-SAFETY-FRONTIER.1` | `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: Files=3, Tests=351` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `DYNAMIC-DIVISOR-SAFETY-FRONTIER.1` | `pending this commit: DYNAMIC-DIVISOR-SAFETY-FRONTIER.1: select divisor safety work` | `selection slice` |
| `DYNAMIC-DIVISOR-SAFETY-FRONTIER.2` | `pending` | `audit/design slice` |

## Changelog

- `2026-05-24`: Created active task tree and selected the audit/design
  frontier.
