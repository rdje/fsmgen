# R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT: Diagnostic Provenance Exit Audit

## Metadata

- Tree ID: `R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT`
- Status: `done`
- Roadmap lane: `R10`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Audit the current `R10` source-provenance and diagnostic state after the
recent stack-free cleanup slices, then select the next bounded frontier or
close/handoff decision from evidence.

## Non-Goals

- Do not change parser, scheduler, HDL, CLI, or JSON behavior in the audit
  selection leaf.
- Do not implement a diagnostic cleanup before the audit identifies a bounded
  leaf.
- Do not claim full line/construct provenance unless tests and documentation
  already prove it.

## Acceptance Criteria

- The audit maps current `R10` coverage across source context, composition
  artifact context, CLI presentation cleanup, check JSON, normalized semantic
  JSON, and known expected-failure corpus diagnostics.
- The audit records whether another bounded `R10` implementation slice is
  justified now, or whether `R10` should move to `mostly done` with future
  diagnostic maintenance handled by later feature slices.
- mdBook/live docs are synchronized if status or user-facing diagnostic claims
  change.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT`
  Status: `done`
  Goal: `Audit R10 diagnostic/provenance exit criteria and select the next frontier or close/handoff decision.`
  Children: `R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT.1`,
    `R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT.2`

- ID: `R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT.1`
  Status: `done`
  Goal: `Activate the R10 diagnostic/provenance exit audit task tree.`
  Acceptance: `The active tree, roadmap status, task-tree table, live docs, and README index name this tree, and the next leaf is limited to an evidence-gathering audit before any behavior-bearing diagnostic change.`
  Verification: `passed: feature-backlog audit, mdBook build, and diff check`
  Commit: `R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT.1: select R10 exit audit`

- ID: `R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT.2`
  Status: `done`
  Goal: `Audit the current R10 diagnostic/provenance frontier and decide whether to select another bounded slice or close/handoff.`
  Acceptance: `The audit records current evidence, validation scope, remaining gaps, and the next roadmap decision; no behavior changes are made in this audit leaf unless a follow-up task tree is selected first.`
  Verification: `passed: focused R10 diagnostics tests, expected-failure corpus leak probe, regression-corpus accounting, feature-backlog audit, mdBook build, and diff check`
  Commit: `R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT.2: audit R10 exit frontier`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT.2` | `done` | The audit found no immediate parser/stack leakage frontier and moved `R10` to `mostly done` with future diagnostic work handled by later feature slices. |

## Decisions

- `2026-05-24`: Select an exit/frontier audit after the empty-source, quiet
  banner, combinational self-dependency, and D-input self-dependency cleanup
  slices. The immediate corpus leak probe is clean, so the next step should be
  evidence gathering and status decision, not an unowned code change.
- `2026-05-24`: Close the tree after `.2`. Focused R10 diagnostic coverage and
  a fresh expected-failure `.fsm` corpus leak probe found no immediate
  parser-name or stack-frame cleanup frontier. `R10` moves to `mostly done`;
  future diagnostic/provenance work should be selected by later feature slices
  when a concrete user-facing gap appears.

## Open Questions

- None. The tree is closed.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |
| `2026-05-24` | `R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT.2` | `prove -Iperl t/241-top-level-source-file-diagnostic-boundary.t t/246-cli-error-output-cleanup.t t/250-cli-entrypoint-file-context.t t/252-extension-diagnostic-context.t t/253-extension-loader-diagnostic-context.t t/1346-empty-source-file-diagnostic-boundary.t t/1347-cli-quiet-banner-boundary.t t/1348-self-dependency-diagnostic-cleanup.t t/1349-d-input-self-dependency-diagnostic-cleanup.t t/299-check-json-diagnostics.t t/636-normalized-semantic-diagnostic-summary.t t/637-check-json-diagnostic-summary.t`; expected-failure `.fsm` quiet CLI leak probe; `prove -Iperl t/248-regression-corpus-accounting.t`; `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: focused R10 diagnostics Files=12, Tests=37; expected-failure probe checked=106, leaks=0; regression-corpus accounting Files=1, Tests=3149; feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT.1` | `R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT.1: select R10 exit audit` | `selection slice` |
| `R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT.2` | `R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT.2: audit R10 exit frontier` | `audit close-out slice` |

## Changelog

- `2026-05-24`: Created active `R10` diagnostic/provenance exit audit tree
  and selected `.2` as the evidence-gathering frontier.
- `2026-05-24`: Completed `.2` and closed the tree. `R10` is now `mostly
  done` with no immediate parser-name or stack-frame cleanup frontier selected.
