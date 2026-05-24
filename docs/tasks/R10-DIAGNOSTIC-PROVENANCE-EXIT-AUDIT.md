# R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT: Diagnostic Provenance Exit Audit

## Metadata

- Tree ID: `R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT`
- Status: `active`
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
  Status: `active`
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
  Status: `pending`
  Goal: `Audit the current R10 diagnostic/provenance frontier and decide whether to select another bounded slice or close/handoff.`
  Acceptance: `The audit records current evidence, validation scope, remaining gaps, and the next roadmap decision; no behavior changes are made in this audit leaf unless a follow-up task tree is selected first.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT.2` | `pending` | The latest expected-failure `.fsm` corpus probe checked 106 entries and found no remaining quiet CLI `Parser.pm`, `SourceFrontend.pm`, `Lispish::`, `called at`, or generic Perl script-line leakage. An evidence-based audit should decide the next R10 frontier instead of inventing a cleanup. |

## Decisions

- `2026-05-24`: Select an exit/frontier audit after the empty-source, quiet
  banner, combinational self-dependency, and D-input self-dependency cleanup
  slices. The immediate corpus leak probe is clean, so the next step should be
  evidence gathering and status decision, not an unowned code change.

## Open Questions

- None. `.2` owns the evidence-gathering audit and next-frontier decision.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT.1` | `R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT.1: select R10 exit audit` | `selection slice` |

## Changelog

- `2026-05-24`: Created active `R10` diagnostic/provenance exit audit tree
  and selected `.2` as the evidence-gathering frontier.
