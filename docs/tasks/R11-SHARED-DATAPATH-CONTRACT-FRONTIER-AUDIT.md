# R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT: Shared-Datapath Contract Frontier Audit

## Metadata

- Tree ID: `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT`
- Status: `active`
- Roadmap lane: `R11`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Audit the shipped shared-datapath extraction surface and select one bounded
next contract slice or an explicit deferral from evidence.

## Non-Goals

- Do not implement new shared-datapath behavior in the activation leaf.
- Do not widen route mux/storage, fan-in/fan-out, ready/backpressure, or
  payload-protocol semantics before the audit selects one exact surface.
- Do not change composition planning, structural IR, backend lowering, HDL
  emission, or generated artifacts during the activation leaf.

## Acceptance Criteria

- The activation leaf creates clear task-tree ownership before any
  shared-datapath behavior-bearing work.
- The audit leaf maps shipped shared-datapath evidence across candidate
  discovery, metadata, helper HDL, runtime HDL, assertions, visibility,
  registered peer-read cases, combinational cases, public fanout, and forward
  IR export surfaces.
- The audit leaf records one next implementation slice or an explicit deferral
  if the remaining work depends on a stronger route/storage/protocol,
  reusable-module, portable-type, or architecture contract.
- Focused validation passes.
- Live docs and roadmap status are updated where project state changed.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT`
  Status: `active`
  Goal: `Audit the R11 shared-datapath contract frontier and choose the next bounded slice.`
  Children: `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT.1`,
    `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT.2`

- ID: `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT.1`
  Status: `done`
  Goal: `Activate the shared-datapath contract frontier audit task tree.`
  Acceptance: `The active tree, roadmap status, task-tree table, live docs, and README index name this tree, and the next leaf is limited to an evidence-gathering audit before any shared-datapath behavior change.`
  Verification: `passed: feature-backlog audit, mdBook build, and diff check`
  Commit: `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT.1: select shared-datapath frontier`

- ID: `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT.2`
  Status: `pending`
  Goal: `Audit shipped shared-datapath behavior and choose the next bounded slice or deferral.`
  Acceptance: `The audit records current evidence, remaining gaps, and one implementation direction or deferral decision before any shared-datapath behavior change.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT.2` | `pending` | The next R11 left item is the shared-datapath contract family, and the shipped surface is broad enough to require an evidence-led bounded selection before code. |

Current frontier: `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT.2`.

## Decisions

- `2026-05-24`: Select a shared-datapath contract frontier audit after the
  parameter/generic audit closed. The roadmap names several remaining
  shared-datapath directions across ownership, lifted mux/register behavior,
  public re-export/default visibility, and combinational behavior, so the next
  safe step is to map shipped evidence and choose one bounded implementation
  slice or deferral.

## Open Questions

- Does the remaining shared-datapath frontier contain one bounded immediate
  implementation slice, or should the next behavior-bearing work wait for a
  stronger route/storage/protocol, reusable-module, portable-type, or
  architecture contract?

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT.1` | `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT.1: select shared-datapath frontier` | `selection slice` |

## Changelog

- `2026-05-24`: Created active `R11` shared-datapath contract frontier audit
  tree and selected `.2` as the evidence-gathering frontier.
