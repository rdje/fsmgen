# R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT: Diagnostic Provenance Frontier Audit

## Metadata

- Tree ID: `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT`
- Status: `done`
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
  Status: `done`
  Goal: `Resolve the next source-provenance and diagnostics decision from evidence.`
  Children: `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.1`,
    `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.2`,
    `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.3`

- ID: `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.1`
  Status: `done`
  Goal: `Activate the R10 diagnostic/provenance frontier audit task tree.`
  Acceptance: `The active tree, roadmap status, task-tree table, live docs, and README index name this tree, and the next leaf is limited to an audit/design boundary before any behavior-bearing diagnostic change.`
  Verification: `passed: feature-backlog audit, mdBook build, and diff check`
  Commit: `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.1: select diagnostic provenance frontier`

- ID: `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.2`
  Status: `done`
  Goal: `Audit the current source-provenance and diagnostic frontier and select close-out, documentation truth sync, or one bounded implementation cut.`
  Acceptance: `The audit identifies current source-local and construct-local diagnostic coverage, tests, public metadata, mdBook coverage, and remaining gaps; it records whether the next safe step is implementation, documentation truth sync, roadmap handoff, or R10 close-out. No behavior changes are made in this audit leaf.`
  Verification: `passed: focused diagnostic context tests, feature-backlog audit, mdBook build, and diff check`
  Commit: `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.2: audit diagnostic provenance frontier`

- ID: `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.3`
  Status: `done`
  Goal: `Clean up empty source-file diagnostics without leaking Perl call-stack frames.`
  Acceptance: `Empty direct .fsm source files fail with a targeted source-local diagnostic through pipeline, CLI, check JSON, and normalized semantic JSON; the message does not contain the legacy "does not exit" typo, raw Lispish fallback text, or Perl stack frames; mdBook/live docs describe the user-facing behavior.`
  Verification: `passed: syntax checks, focused empty-source/diagnostic JSON tests, feature-backlog audit, mdBook build, and diff check`
  Commit: `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.3: clean empty source diagnostics`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.3` | `done` | Empty source files now fail with a targeted source-local diagnostic across pipeline, CLI, check JSON, and normalized semantic JSON. |

## Decisions

- `2026-05-24`: Select `R10` diagnostic/provenance frontier auditing after
  the `R9` strict-mode frontier audit marked `R9` mostly done. The live
  roadmap still lists `R10` as in progress, with open work to define the next
  provenance-carrying boundaries and add regression coverage for error shape
  and location reporting, so PNT should inspect the current diagnostic surface
  before adding another behavior-bearing boundary.
- `2026-05-24`: Select empty direct `.fsm` source-file diagnostics as the next
  bounded implementation leaf. Existing `R10` slices already cover top-level
  source context, generated-child context, RTL metadata context, missing child
  and missing `.rtlif` artifacts, lookup search roots, pre-pipeline CLI
  missing-input/output-open context, and typed-extension hook/loading context.
  A fresh empty-file probe still reports the raw Lispish fallback text
  `File ... is either empty or does not exit` and leaks Perl call-stack frames
  through `bin/fsmgen --quiet`, so `.3` should replace that with a targeted
  source-local diagnostic and lock the pipeline, CLI, check-JSON, and
  normalized semantic JSON surfaces.
- `2026-05-24`: Close the tree after `.3`. Empty direct `.fsm` source files
  now report a targeted source-local diagnostic across pipeline, CLI,
  check-JSON, and normalized semantic JSON, with no raw Lispish fallback text,
  no `does not exit` typo, and no Perl stack frames.

## Open Questions

- None. `.2` owns the diagnostic/provenance inventory and next-slice
  selection.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |
| `2026-05-24` | `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.2` | `prove -Iperl t/241-top-level-source-file-diagnostic-boundary.t t/242-composition-child-source-file-diagnostic-boundary.t t/243-composition-rtl-child-diagnostic-context.t t/244-composition-child-resolution-diagnostic-context.t t/246-cli-error-output-cleanup.t t/250-cli-entrypoint-file-context.t t/252-extension-diagnostic-context.t t/253-extension-loader-diagnostic-context.t t/255-composition-missing-rtl-metadata-diagnostic-context.t t/256-composition-missing-child-source-artifact-context.t t/115-composition-child-source-diagnostics.t t/117-composition-rtlif-metadata-diagnostics.t t/131-composition-failure-summary-reporting.t`; `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: focused diagnostic context tests Files=13, Tests=172; feature-backlog audit Files=1, Tests=15` |
| `2026-05-24` | `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.3` | `perl -Iperl -c perl/FSM/Pipeline/SourceFrontend.pm`; `perl -Iperl -c t/1346-empty-source-file-diagnostic-boundary.t`; `prove -Iperl t/1346-empty-source-file-diagnostic-boundary.t t/241-top-level-source-file-diagnostic-boundary.t t/246-cli-error-output-cleanup.t t/250-cli-entrypoint-file-context.t t/299-check-json-diagnostics.t t/634-normalized-semantic-snapshot-failure-boundary.t t/636-normalized-semantic-diagnostic-summary.t t/637-check-json-diagnostic-summary.t`; `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: focused empty-source/diagnostic JSON tests Files=8, Tests=19; feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.1` | `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.1: select diagnostic provenance frontier` | `selection slice` |
| `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.2` | `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.2: audit diagnostic provenance frontier` | `audit/design slice` |
| `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.3` | `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.3: clean empty source diagnostics` | `implementation close-out slice` |

## Changelog

- `2026-05-24`: Created active `R10` diagnostic/provenance frontier audit tree
  and selected `.2` as the audit/design frontier.
- `2026-05-24`: Completed `.2` and selected `.3` for empty source-file
  diagnostic cleanup across pipeline, CLI, check JSON, and normalized semantic
  JSON.
- `2026-05-24`: Completed `.3` and closed the tree. Empty direct `.fsm`
  source files now fail with the targeted empty-source diagnostic.
