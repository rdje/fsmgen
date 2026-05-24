# R9-STRICT-MODE-FRONTIER-AUDIT: Strict Mode Frontier Audit

## Metadata

- Tree ID: `R9-STRICT-MODE-FRONTIER-AUDIT`
- Status: `active`
- Roadmap lane: `R9`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Audit the current strict-mode support-tier frontier and decide whether `R9`
still has one bounded compatibility rejection to ship, should close, or should
hand remaining strict-mode maintenance to future feature slices.

## Non-Goals

- Do not add a new strict-mode rejection before the audit identifies an exact
  compatibility family, canonical replacement, diagnostics, tests, and docs.
- Do not remove default-mode compatibility under this tree unless a later leaf
  explicitly selects that migration and proves the corpus impact.
- Do not claim strict mode is complete unless the current compatibility
  residue, supported corpus, mdBook, diagnostics, and manifest evidence support
  that claim.

## Acceptance Criteria

- The audit maps every currently known default-mode compatibility residue to
  strict-mode behavior, diagnostics, corpus accounting, mdBook coverage, and
  public metadata.
- The tree either selects one bounded strict-mode follow-up leaf, closes `R9`
  honestly, or records a precise future-slice maintenance decision.
- Any behavior-bearing follow-up leaf includes paired default/strict coverage,
  stable diagnostics, and mdBook/live-doc synchronization.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R9-STRICT-MODE-FRONTIER-AUDIT`
  Status: `active`
  Goal: `Resolve the next strict-mode support-tier decision from evidence.`
  Children: `R9-STRICT-MODE-FRONTIER-AUDIT.1`,
    `R9-STRICT-MODE-FRONTIER-AUDIT.2`

- ID: `R9-STRICT-MODE-FRONTIER-AUDIT.1`
  Status: `done`
  Goal: `Activate the R9 strict-mode frontier audit task tree.`
  Acceptance: `The active tree, roadmap status, task-tree table, live docs, and README index name this tree, and the next leaf is limited to an audit/design boundary before any behavior-bearing strict-mode change.`
  Verification: `passed: feature-backlog audit, mdBook build, and diff check`
  Commit: `R9-STRICT-MODE-FRONTIER-AUDIT.1: select strict-mode frontier audit`

- ID: `R9-STRICT-MODE-FRONTIER-AUDIT.2`
  Status: `pending`
  Goal: `Audit strict-mode coverage and select close-out, maintenance handoff, or one bounded strict cut.`
  Acceptance: `The audit identifies the current default/strict split for every known compatibility residue, validates supported-corpus strict acceptance evidence, and records whether the next safe step is implementation, documentation truth sync, roadmap handoff, or R9 close-out. No behavior changes are made in this audit leaf.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R9-STRICT-MODE-FRONTIER-AUDIT.2` | `pending` | `R8` handed active implementation focus to `R9`; the next safe strict-mode step is an evidence audit before another support-tier cut. |

## Decisions

- `2026-05-24`: Select `R9` strict-mode frontier auditing after the `R8`
  language-contract exit audit marked `R8` mostly done. The live roadmap still
  lists `R9` as in progress, so PNT should inspect the default/strict split
  before adding or closing any strict-mode support-tier work.

## Open Questions

- None. `.2` owns the strict-mode inventory and next-slice selection.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `R9-STRICT-MODE-FRONTIER-AUDIT.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R9-STRICT-MODE-FRONTIER-AUDIT.1` | `R9-STRICT-MODE-FRONTIER-AUDIT.1: select strict-mode frontier audit` | `selection slice` |

## Changelog

- `2026-05-24`: Created active `R9` strict-mode frontier audit tree and
  selected `.2` as the audit/design frontier.
