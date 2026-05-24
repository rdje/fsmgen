# R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT: Language Surface Gray-Zone Audit

## Metadata

- Tree ID: `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT`
- Status: `done`
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
  Status: `done`
  Goal: `Resolve the next parser-accepted language-surface gray zone.`
  Children: `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.1`,
    `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.2`,
    `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.3`

- ID: `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.1`
  Status: `done`
  Goal: `Activate the R8 gray-zone audit task tree.`
  Acceptance: `The active tree, roadmap status, task-tree table, live docs, and README index name this tree, and the next leaf is limited to an audit/design boundary before behavior changes.`
  Verification: `passed: feature-backlog audit, mdBook build, and diff check`
  Commit: `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.1: select gray-zone audit`

- ID: `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.2`
  Status: `done`
  Goal: `Audit parser-accepted compatibility residue and select one bounded support-tier decision.`
  Acceptance: `The audit identifies remaining accepted compatibility or ambiguous constructs, current docs/support-accounting coverage, strict-mode behavior, manifest exposure, and one bounded next implementation leaf or a documented close-out decision. No behavior changes are made in this audit leaf.`
  Verification: `passed: feature-backlog audit, mdBook build, and diff check`
  Commit: `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.2: audit gray-zone residue`

- ID: `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.3`
  Status: `done`
  Goal: `Sync the legacy <=+ assignment alias into top-level language-surface compatibility metadata.`
  Acceptance: `The public language-surface manifest records legacy <=+ assignment compatibility in the same default-mode compatibility inventory as the other parser-accepted legacy residues, while preserving the existing assignment-specific compatibility entry, parser behavior, strict-mode rejection, corpus accounting, and mdBook truth.`
  Verification: `passed: syntax, language-surface manifest tests, feature-backlog audit, mdBook build, and diff check`
  Commit: `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.3: sync legacy lteplus manifest metadata`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | The selected metadata truth-sync leaf is complete; a future PNT selection should start from the roadmap/task-tree index. |

## Decisions

- `2026-05-24`: Select R8 language-surface gray-zone auditing as the next PNT
  activity after closing the strict slash-link task tree. The live roadmap
  still lists R8 as in progress, with remaining work to resolve parser-
  accepted legacy constructs and keep support claims regression-backed.
- `2026-05-24`: Completed the audit-only `.2` leaf without changing parser,
  scheduler, HDL, CLI, public API, test, or generated behavior. The remaining
  default-mode compatibility residue is already mostly accounted for: paired
  corpus entries cover legacy direct roots, `?module` aliases, empty
  `(+size)`, misleading reset spellings, compact `:=`, infix assignments,
  legacy `<=+`, legacy generated-child roots, and composition slash-link
  wiring. Strict mode rejects each current residue with stable diagnostics
  where an explicit strict cut has shipped, and the mdBook/regression corpus
  docs describe the user-facing split. The one bounded gap selected for `.3`
  is manifest metadata truth: `FSM::Support::LanguageSurfaceSection` exposes
  `legacy <=+ assignment operator alias for <=-` under assignment
  compatibility, but its top-level
  `default_mode_compatibility.accepted_but_not_canonical_for_generated_output`
  list does not name the same accepted legacy residue beside the other
  default-mode compatibility families.
- `2026-05-24`: Completed `.3` and closed the tree. The language-surface
  manifest now exposes `legacy <=+ assignment operator alias for <=-` in both
  the broad
  `default_mode_compatibility.accepted_but_not_canonical_for_generated_output`
  inventory and the assignment-specific `assignments.compatibility_forms`
  inventory. No parser, scheduler, HDL, CLI, strict-mode diagnostic, corpus
  classification, or generated behavior changed.

## Open Questions

- None. The tree is closed.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |
| `2026-05-24` | `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.2` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |
| `2026-05-24` | `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.3` | `perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm`; `prove -Iperl t/317-language-surface-contract.t t/363-language-surface-section-runtime-contract-audit.t t/483-language-surface-section-defensive-copy-boundary-audit.t t/297-capability-manifest.t`; `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: manifest tests Files=4, Tests=12; feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.1` | `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.1: select gray-zone audit` | `selection slice` |
| `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.2` | `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.2: audit gray-zone residue` | `audit/design slice` |
| `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.3` | `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.3: sync legacy lteplus manifest metadata` | `metadata truth-sync slice` |

## Changelog

- `2026-05-24`: Created active R8 language-surface gray-zone audit tree and
  selected the activation frontier.
- `2026-05-24`: Completed `.1`; current frontier is `.2`, the audit/design
  slice.
- `2026-05-24`: Completed `.2`; selected `.3` to synchronize legacy `<=+`
  assignment compatibility into top-level language-surface metadata.
- `2026-05-24`: Completed `.3`; closed the tree with language-surface
  manifest metadata synchronized for legacy `<=+` compatibility.
