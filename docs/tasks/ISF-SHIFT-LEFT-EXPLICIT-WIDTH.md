# ISF-SHIFT-LEFT-EXPLICIT-WIDTH: Shift Left Explicit Width

## Metadata

- Tree ID: `ISF-SHIFT-LEFT-EXPLICIT-WIDTH`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Allow `shift_left` to accept the same optional `(width N)` width-evidence
assertion pattern already used by `shift_right`, without changing
`shift_left` timing or emitted expression semantics.

## Non-Goals

- Do not require width evidence for ordinary `shift_left`; the operation does
  not need an insertion-position width.
- Do not reinterpret `(width N)` as a cast, truncation, or resize.
- Do not widen data-operation expression syntax beyond the existing scalar
  register and scalar inserted-bit operands.
- Do not change `shift_right`, `assemble`, or `extract` behavior except where
  they consume width evidence produced by `shift_left`.

## Acceptance Criteria

- `(shift_left REG BIT (width N))` accepts a positive integer `N`.
- The width option fills missing transaction-local width evidence for `REG`.
- The width option fails closed when it conflicts with already-known width
  evidence for `REG`.
- Malformed `shift_left` width options fail with targeted diagnostics.
- Existing `(shift_left REG BIT)` behavior and lowering remain unchanged.
- Public `tested_by` metadata, the ISF spec, downstream handoff, public
  contract, mdBook, data-width task notes, live docs, README, roadmap board,
  and task tree stay synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-SHIFT-LEFT-EXPLICIT-WIDTH`
  Status: `done`
  Goal: `Ship optional width evidence for shift_left.`
  Children: `ISF-SHIFT-LEFT-EXPLICIT-WIDTH.1`

- ID: `ISF-SHIFT-LEFT-EXPLICIT-WIDTH.1`
  Status: `done`
  Goal: `Implement and document shift_left optional width evidence.`
  Acceptance: `The parser/lowerer accept and validate shift_left width evidence, tests cover accepted and rejected shapes, docs and metadata are synchronized, and focused plus ISF gates pass.`
  Verification: `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`;
  `prove -l t/1318-isf-shift-left-explicit-width.t t/1199-isf-shift-clause-boundary.t t/1173-isf-shift-right-explicit-width.t t/1226-isf-data-width-storage-report.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t`;
  `./bin/ci-regression isf --no-book`; `mdbook build docs/book`;
  `git diff --check`
  Commit: `ISF-SHIFT-LEFT-EXPLICIT-WIDTH.1: add shift_left width evidence`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| - | - | `closed` | `ISF-SHIFT-LEFT-EXPLICIT-WIDTH.1` completed optional shift-left width evidence and closed the tree. |

## Decisions

- `2026-05-16`: Treat `(width N)` on `shift_left` as width evidence only. The
  emitted shift expression remains `(| (<< REG 1) BIT)`.
- `2026-05-16`: Keep ordinary `(shift_left REG BIT)` accepted without known
  width evidence because left insertion does not require a computed MSB
  position.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-SHIFT-LEFT-EXPLICIT-WIDTH.1` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `prove -l t/1318-isf-shift-left-explicit-width.t t/1199-isf-shift-clause-boundary.t t/1173-isf-shift-right-explicit-width.t t/1226-isf-data-width-storage-report.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed`; focused tests `Files=8, Tests=110`; ISF gate `Files=224, Tests=984` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-SHIFT-LEFT-EXPLICIT-WIDTH.1` | `ISF-SHIFT-LEFT-EXPLICIT-WIDTH.1: add shift_left width evidence` | Optional `(width N)` on `shift_left`, focused coverage, and synchronized public docs. |

## Changelog

- `2026-05-16`: Created task tree and started the shift-left explicit-width
  leaf.
- `2026-05-16`: Completed `ISF-SHIFT-LEFT-EXPLICIT-WIDTH.1`, synchronized the
  spec, downstream handoff, public contract, mdBook, data-width notes, live
  docs, README, roadmap board, and task tree, and closed the tree.
