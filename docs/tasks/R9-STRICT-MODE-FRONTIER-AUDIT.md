# R9-STRICT-MODE-FRONTIER-AUDIT: Strict Mode Frontier Audit

## Metadata

- Tree ID: `R9-STRICT-MODE-FRONTIER-AUDIT`
- Status: `done`
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
  Status: `done`
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
  Status: `done`
  Goal: `Audit strict-mode coverage and select close-out, maintenance handoff, or one bounded strict cut.`
  Acceptance: `The audit identifies the current default/strict split for every known compatibility residue, validates supported-corpus strict acceptance evidence, and records whether the next safe step is implementation, documentation truth sync, roadmap handoff, or R9 close-out. No behavior changes are made in this audit leaf.`
  Verification: `passed: focused strict/corpus gates, feature-backlog audit, mdBook build, and diff check`
  Commit: `R9-STRICT-MODE-FRONTIER-AUDIT.2: audit strict-mode frontier`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R9-STRICT-MODE-FRONTIER-AUDIT.2` | `done` | Audit found no currently named default-mode compatibility residue that lacks paired strict-mode rejection, diagnostics, corpus ownership, and mdBook/public metadata. |

## Decisions

- `2026-05-24`: Select `R9` strict-mode frontier auditing after the `R8`
  language-contract exit audit marked `R8` mostly done. The live roadmap still
  lists `R9` as in progress, so PNT should inspect the default/strict split
  before adding or closing any strict-mode support-tier work.
- `2026-05-24`: Close the current `R9` frontier without adding another
  behavior-bearing strict cut. The audit mapped the
  `language_surface.default_mode_compatibility.accepted_but_not_canonical_for_generated_output`
  inventory to paired default-compatible / strict-rejected regression-corpus
  entries, stable `FSMGEN_STRICT_*` diagnostic codes, strict-mode mdBook
  coverage, and manifest-visible compatibility metadata. Future strict-mode
  work should be selected only when a future feature slice introduces,
  preserves, or promotes a compatibility surface that needs a new strict
  boundary.

## Open Questions

- None. `.2` owns the strict-mode inventory and next-slice selection.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `R9-STRICT-MODE-FRONTIER-AUDIT.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |
| `2026-05-24` | `R9-STRICT-MODE-FRONTIER-AUDIT.2` | `prove -Iperl t/239-strict-mode-legacy-fsm-root-boundary.t t/240-strict-mode-standalone-dt-alias-boundary.t t/245-strict-mode-fsm-child-root-boundary.t t/251-strict-mode-empty-size-boundary.t t/254-strict-mode-asreset-boundary.t t/257-strict-mode-compact-init-boundary.t t/295-strict-mode-infix-assignment-boundary.t t/410-strict-mode-legacy-lteplus-boundary.t t/411-strict-mode-composition-wiring-slash-boundary.t t/248-regression-corpus-accounting.t t/249-regression-corpus-classified-behavior.t t/261-regression-corpus-supported-language-features.t t/296-regression-corpus-supported-behavior.t`; `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: focused strict/corpus gates Files=13, Tests=3204; feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R9-STRICT-MODE-FRONTIER-AUDIT.1` | `R9-STRICT-MODE-FRONTIER-AUDIT.1: select strict-mode frontier audit` | `selection slice` |
| `R9-STRICT-MODE-FRONTIER-AUDIT.2` | `R9-STRICT-MODE-FRONTIER-AUDIT.2: audit strict-mode frontier` | `audit close-out slice` |

## Changelog

- `2026-05-24`: Created active `R9` strict-mode frontier audit tree and
  selected `.2` as the audit/design frontier.
- `2026-05-24`: Completed `.2` and closed the tree. The next safe step is not
  another immediate strict cut; it is future-slice maintenance when new
  compatibility residue appears.
