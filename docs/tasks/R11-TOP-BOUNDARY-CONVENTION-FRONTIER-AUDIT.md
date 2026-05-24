# R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT: Top-Boundary Convention Frontier Audit

## Metadata

- Tree ID: `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT`
- Status: `active`
- Roadmap lane: `R11`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Audit the shipped top-boundary convention and declared connect-by-name
surface, then select one bounded next contract slice or an explicit deferral
from evidence.

## Non-Goals

- Do not implement new composition inference, connect-by-name, explicit-link,
  public-port, or child-to-child wiring behavior in the activation leaf.
- Do not widen hidden child-to-child inference, interface bundle syntax,
  protocol grouping, or generic meta-programming before the audit identifies
  one exact contract.
- Do not change parser, planner, report, generated artifact, HDL, CLI, public
  API, source, test, or generated behavior during the activation leaf.

## Acceptance Criteria

- The activation leaf creates clear task-tree ownership before any
  top-boundary convention behavior-bearing work.
- The audit leaf maps shipped evidence across omitted/empty `?ports`
  inference, same-name top-input fanout, same-name top-output adoption,
  internal-carrier inference/re-export, declared `=name` connect-by-name,
  explicit local overrides, provenance/block reporting, structural IR
  surfaces, generated/RTL child mixes, and explicit deferrals.
- The audit leaf records one next implementation slice or an explicit deferral
  if the remaining work depends on a stronger top-boundary convention,
  interface bundle, protocol, package/import, reusable-module, portable-type,
  or architecture contract.
- Focused validation passes.
- Live docs and roadmap status are updated where project state changed.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT`
  Status: `active`
  Goal: `Audit the R11 top-boundary convention/connect-by-name frontier and choose the next bounded slice.`
  Children: `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT.1`,
    `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT.2`

- ID: `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT.1`
  Status: `done`
  Goal: `Activate the top-boundary convention frontier audit task tree.`
  Acceptance: `The active tree, roadmap status, task-tree table, live docs, and README index name this tree, and the next leaf is limited to an evidence-gathering audit before any convention or connect-by-name behavior change.`
  Verification: `passed: feature-backlog audit, mdBook build, and diff check`
  Commit: `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT.1: select top-boundary frontier`

- ID: `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT.2`
  Status: `pending`
  Goal: `Audit shipped top-boundary convention and connect-by-name behavior and choose the next bounded slice or deferral.`
  Acceptance: `The audit records current evidence, remaining gaps, and one implementation direction or deferral decision before any top-boundary convention behavior change.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT.2` | `pending` | The next R11 left item is the declared top-port/connect-by-name convention family, and the remaining directions require an evidence-led bounded selection before code. |

Current frontier: `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT.2`.

## Decisions

- `2026-05-24`: Select a top-boundary convention frontier audit after the
  portable-type audit closed. The roadmap names remaining work around
  asymmetric declared top-port connect-by-name, convention-over-configuration
  widening, explicit local override ergonomics, internal re-export policy, and
  keeping convention top-boundary-oriented rather than hidden child-to-child
  inference, so the next safe step is to map shipped evidence and choose one
  bounded implementation slice or deferral.

## Open Questions

- Does the remaining top-boundary convention frontier contain one bounded
  immediate implementation slice, or should the next behavior-bearing work
  wait for a stronger convention, interface-bundle, protocol, package/import,
  reusable-module, portable-type, or architecture contract?

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT.1` | `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT.1: select top-boundary frontier` | `selection slice` |

## Changelog

- `2026-05-24`: Created active `R11` top-boundary convention frontier audit
  tree and selected `.2` as the evidence-gathering frontier.
