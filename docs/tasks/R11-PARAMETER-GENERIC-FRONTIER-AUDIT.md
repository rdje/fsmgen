# R11-PARAMETER-GENERIC-FRONTIER-AUDIT: Parameter/Generic Frontier Audit

## Metadata

- Tree ID: `R11-PARAMETER-GENERIC-FRONTIER-AUDIT`
- Status: `active`
- Roadmap lane: `R11`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Audit the current semantic parameter/generic contract and select one bounded
next slice or deferral from evidence.

## Non-Goals

- Do not implement VHDL generic-map lowering in the activation leaf.
- Do not widen scalar or aggregate parameter/generic expression domains before
  the audit identifies one bounded, testable surface.
- Do not change direct-root `+params`, `.rtlif`, generated-child, package, IR,
  or backend behavior during the activation leaf.

## Acceptance Criteria

- The activation leaf creates clear task-tree ownership before any
  parameter/generic behavior-bearing work.
- The audit leaf maps shipped parameter/generic evidence across direct roots,
  `.rtlif`, external `?rtl`, generated `?fsmc` / `?dtc`, package defaults,
  scalar expressions, aggregate values, leafwise aggregate operators,
  structural IR, and SystemVerilog instance emission.
- The audit leaf records one next implementation slice or an explicit deferral
  if the remaining work depends on VHDL backend support, the portable type
  lane, or a stronger aggregate-expression contract.
- Focused validation passes.
- Live docs and roadmap status are updated where project state changed.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R11-PARAMETER-GENERIC-FRONTIER-AUDIT`
  Status: `active`
  Goal: `Audit the R11 semantic parameter/generic frontier and choose the next bounded slice.`
  Children: `R11-PARAMETER-GENERIC-FRONTIER-AUDIT.1`,
    `R11-PARAMETER-GENERIC-FRONTIER-AUDIT.2`

- ID: `R11-PARAMETER-GENERIC-FRONTIER-AUDIT.1`
  Status: `done`
  Goal: `Activate the parameter/generic frontier audit task tree.`
  Acceptance: `The active tree, roadmap status, task-tree table, live docs, and README index name this tree, and the next leaf is limited to an evidence-gathering audit before any parameter/generic behavior change.`
  Verification: `passed: feature-backlog audit, mdBook build, and diff check`
  Commit: `R11-PARAMETER-GENERIC-FRONTIER-AUDIT.1: select parameter frontier`

- ID: `R11-PARAMETER-GENERIC-FRONTIER-AUDIT.2`
  Status: `pending`
  Goal: `Audit shipped semantic parameter/generic behavior and choose the next bounded slice or deferral.`
  Acceptance: `The audit records current evidence, remaining gaps, and one implementation direction or deferral decision before any parameter/generic behavior change.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-PARAMETER-GENERIC-FRONTIER-AUDIT.2` | `pending` | The next R11 left item is semantic parameter/generic widening, and the remaining directions are broad enough to require an evidence-led bounded selection before code. |

## Decisions

- `2026-05-24`: Select a parameter/generic frontier audit after the `.rtlif`
  direction decision closed. The roadmap names several remaining
  parameter/generic directions, so the next safe step is to map shipped
  evidence and choose one bounded implementation slice or deferral.

## Open Questions

- None. `.2` owns the evidence-gathering audit and next-frontier decision.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `R11-PARAMETER-GENERIC-FRONTIER-AUDIT.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-PARAMETER-GENERIC-FRONTIER-AUDIT.1` | `R11-PARAMETER-GENERIC-FRONTIER-AUDIT.1: select parameter frontier` | `selection slice` |

## Changelog

- `2026-05-24`: Created active `R11` parameter/generic frontier audit tree
  and selected `.2` as the evidence-gathering frontier.
