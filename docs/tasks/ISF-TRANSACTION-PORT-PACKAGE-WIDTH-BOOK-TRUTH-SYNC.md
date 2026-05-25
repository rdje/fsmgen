# ISF-TRANSACTION-PORT-PACKAGE-WIDTH-BOOK-TRUTH-SYNC: Transaction Port Package Width Book Truth Sync

## Metadata

- Tree ID: `ISF-TRANSACTION-PORT-PACKAGE-WIDTH-BOOK-TRUTH-SYNC`
- Status: `done`
- Roadmap lane: `R14 documentation truth sync`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Remove stale mdBook backlog prose that still claimed package constants were
fail-closed in transaction-local port width contexts after
`ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.2` shipped that support.

## Non-Goals

- Do not change parser, scheduler, report, generated artifact, HDL, CLI, or
  public API behavior.
- Do not widen the transaction-port value domain beyond qualified imported
  package scalar constants that resolve to positive integers.
- Do not rewrite historical live-doc entries whose wording described an older
  then-current boundary.

## Acceptance Criteria

- The mdBook feature backlog no longer says package constants fail closed for
  transaction-local port widths in the current static value-domain summary.
- The same mdBook section states the shipped transaction-local port
  package-constant behavior and fail-closed unsupported shapes.
- The task index, roadmap, live docs, and changelog record the truth sync.
- The mdBook and focused book/backlog audits pass.
- The slice is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-TRANSACTION-PORT-PACKAGE-WIDTH-BOOK-TRUTH-SYNC`
  Status: `done`
  Goal: `Synchronize stale mdBook backlog prose for transaction port package-constant widths.`
  Children: `ISF-TRANSACTION-PORT-PACKAGE-WIDTH-BOOK-TRUTH-SYNC.1`

- ID: `ISF-TRANSACTION-PORT-PACKAGE-WIDTH-BOOK-TRUTH-SYNC.1`
  Status: `done`
  Goal: `Remove the stale mdBook backlog fail-closed wording.`
  Acceptance: `Current mdBook backlog prose matches the shipped transaction-local port package-constant width behavior.`
  Verification: `mdbook build docs/book; feature-backlog/live-book/book-matrix audits with Files=3, Tests=364; git diff --check`
  Commit: `aae67a1f ISF-TRANSACTION-PORT-PACKAGE-WIDTH-BOOK-TRUTH-SYNC.1: sync package width book text`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | Stale mdBook backlog wording is synchronized. |

## Decisions

- `2026-05-25`: Treat this as documentation truth synchronization only. The
  shipped compiler behavior already changed in
  `ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.2`.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-TRANSACTION-PORT-PACKAGE-WIDTH-BOOK-TRUTH-SYNC.1` | `mdbook build docs/book; prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t; git diff --check` | `passed: Files=3, Tests=364` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-TRANSACTION-PORT-PACKAGE-WIDTH-BOOK-TRUTH-SYNC.1` | `aae67a1f ISF-TRANSACTION-PORT-PACKAGE-WIDTH-BOOK-TRUTH-SYNC.1: sync package width book text` | `documentation truth sync` |

## Changelog

- `2026-05-25`: Created and completed the mdBook transaction-port
  package-constant width truth-sync task tree.
