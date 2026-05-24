# R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT: Language Surface Gray-Zone Audit

## Metadata

- Tree ID: `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT`
- Status: `active`
- Roadmap lane: `R8`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Identify the next remaining parser-accepted `.fsm` gray-zone construct family
and turn it into an explicit support-tier decision with documentation and
regression ownership.

## Non-Goals

- Do not make broad parser or strict-mode changes before one exact construct
  family is selected.
- Do not remove default-mode compatibility unless a leaf explicitly chooses
  that migration and proves the current corpus impact.
- Do not classify an accepted construct as fully supported without focused
  regression coverage and mdBook documentation.
- Do not change `.isf` behavior under this tree unless an R8 leaf explicitly
  discovers an `.isf`-generated `.fsm` language-surface gap and creates the
  matching R14 synchronization scope.

## Acceptance Criteria

- The current language-surface gray zones are audited against parser/frontend
  behavior, support-accounting metadata, strict-mode boundaries, manifest
  metadata, regression corpus docs, and the mdBook.
- One next bounded construct family is selected, or the tree records that no
  safe implementation leaf remains under this audit.
- Any behavior-bearing leaf includes paired acceptance/rejection coverage,
  stable diagnostics when applicable, and mdBook/live-doc synchronization.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT`
  Status: `active`
  Goal: `Resolve the next parser-accepted language-surface gray zone.`
  Children: `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.1`,
    `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.2`

- ID: `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.1`
  Status: `done`
  Goal: `Activate the R8 gray-zone audit task tree.`
  Acceptance: `The active tree, roadmap status, task-tree table, live docs, and README index name this tree, and the next leaf is limited to an audit/design boundary before behavior changes.`
  Verification: `passed: feature-backlog audit, mdBook build, and diff check`
  Commit: `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.1: select gray-zone audit`

- ID: `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.2`
  Status: `pending`
  Goal: `Audit parser-accepted compatibility residue and select one bounded support-tier decision.`
  Acceptance: `The audit identifies remaining accepted compatibility or ambiguous constructs, current docs/support-accounting coverage, strict-mode behavior, manifest exposure, and one bounded next implementation leaf or a documented close-out decision. No behavior changes are made in this audit leaf.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.2` | `pending` | The tree is active; the next safe step is evidence gathering before any language-surface behavior change. |

## Decisions

- `2026-05-24`: Select R8 language-surface gray-zone auditing as the next PNT
  activity after closing the strict slash-link task tree. The live roadmap
  still lists R8 as in progress, with remaining work to resolve parser-
  accepted legacy constructs and keep support claims regression-backed.

## Open Questions

- None. `.2` owns the actual inventory and next-slice selection.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.1` | `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.1: select gray-zone audit` | `selection slice` |

## Changelog

- `2026-05-24`: Created active R8 language-surface gray-zone audit tree and
  selected the activation frontier.
- `2026-05-24`: Completed `.1`; current frontier is `.2`, the audit/design
  slice.
