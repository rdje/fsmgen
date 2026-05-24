# R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT: Diagnostic Provenance Frontier Audit

## Metadata

- Tree ID: `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT`
- Status: `active`
- Roadmap lane: `R10`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Audit the current source-provenance and diagnostic frontier and select the
next bounded `R10` slice from evidence.

## Non-Goals

- Do not change parser, scheduler, frontend, CLI, diagnostic, JSON, or report
  behavior in the selection leaf.
- Do not add a new diagnostic boundary before the audit identifies the exact
  failure family, current behavior, expected user-facing wording, tests, and
  documentation impact.
- Do not claim `R10` is complete while major parser/generator failures still
  lack precise source-local or construct-local remediation paths.

## Acceptance Criteria

- The audit maps the shipped `R10` diagnostic/provenance boundaries to current
  tests, docs, public metadata, and remaining roadmap exit criteria.
- The tree either selects one bounded diagnostic/provenance implementation
  leaf, records a documentation truth-sync leaf, or closes/hands off `R10`
  honestly from evidence.
- Any behavior-bearing follow-up leaf names the exact failure family, source
  provenance payload, CLI/pipeline impact, focused tests, and mdBook/live-doc
  synchronization requirements before code changes begin.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT`
  Status: `active`
  Goal: `Resolve the next source-provenance and diagnostics decision from evidence.`
  Children: `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.1`,
    `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.2`

- ID: `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.1`
  Status: `done`
  Goal: `Activate the R10 diagnostic/provenance frontier audit task tree.`
  Acceptance: `The active tree, roadmap status, task-tree table, live docs, and README index name this tree, and the next leaf is limited to an audit/design boundary before any behavior-bearing diagnostic change.`
  Verification: `passed: feature-backlog audit, mdBook build, and diff check`
  Commit: `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.1: select diagnostic provenance frontier`

- ID: `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.2`
  Status: `pending`
  Goal: `Audit the current source-provenance and diagnostic frontier and select close-out, documentation truth sync, or one bounded implementation cut.`
  Acceptance: `The audit identifies current source-local and construct-local diagnostic coverage, tests, public metadata, mdBook coverage, and remaining gaps; it records whether the next safe step is implementation, documentation truth sync, roadmap handoff, or R10 close-out. No behavior changes are made in this audit leaf.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.2` | `pending` | `R9` handed active implementation focus to `R10`; the next safe diagnostics/provenance step is an evidence audit before another source-local diagnostic change. |

## Decisions

- `2026-05-24`: Select `R10` diagnostic/provenance frontier auditing after
  the `R9` strict-mode frontier audit marked `R9` mostly done. The live
  roadmap still lists `R10` as in progress, with open work to define the next
  provenance-carrying boundaries and add regression coverage for error shape
  and location reporting, so PNT should inspect the current diagnostic surface
  before adding another behavior-bearing boundary.

## Open Questions

- None. `.2` owns the diagnostic/provenance inventory and next-slice
  selection.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.1` | `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.1: select diagnostic provenance frontier` | `selection slice` |

## Changelog

- `2026-05-24`: Created active `R10` diagnostic/provenance frontier audit tree
  and selected `.2` as the audit/design frontier.
