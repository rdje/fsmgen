# R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT: Reusable-Module Contract Frontier Audit

## Metadata

- Tree ID: `R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT`
- Status: `active`
- Roadmap lane: `R11`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Audit the shipped reusable standalone-DT and module-library surface and select
one bounded next contract slice or an explicit deferral from evidence.

## Non-Goals

- Do not implement new reusable-module behavior in the activation leaf.
- Do not introduce unnamed reusable DT roots, advanced DT enable-control
  syntax, broader lookup roots, or reusable package/import behavior before the
  audit selects one exact surface.
- Do not change parser, composition planning, backend lowering, HDL emission,
  lookup semantics, or generated artifacts during the activation leaf.

## Acceptance Criteria

- The activation leaf creates clear task-tree ownership before any
  reusable-module behavior-bearing work.
- The audit leaf maps shipped evidence across standalone `?dt:name` roots,
  composition `?dtc` children, implicit system-port policy, grouped multi-drive
  targets, assertion metadata/runtime, child-export metadata, lookup roots,
  generated-child contracts, and forward-IR surfaces.
- The audit leaf records one next implementation slice or an explicit deferral
  if the remaining work depends on a stronger reusable-module, lookup,
  package/import, enable-control, portable-type, or architecture contract.
- Focused validation passes.
- Live docs and roadmap status are updated where project state changed.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT`
  Status: `active`
  Goal: `Audit the R11 reusable standalone-DT/module-library frontier and choose the next bounded slice.`
  Children: `R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT.1`,
    `R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT.2`

- ID: `R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT.1`
  Status: `done`
  Goal: `Activate the reusable-module contract frontier audit task tree.`
  Acceptance: `The active tree, roadmap status, task-tree table, live docs, and README index name this tree, and the next leaf is limited to an evidence-gathering audit before any reusable-module behavior change.`
  Verification: `passed: feature-backlog audit, mdBook build, and diff check`
  Commit: `R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT.1: select reusable-module frontier`

- ID: `R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT.2`
  Status: `pending`
  Goal: `Audit shipped reusable-module behavior and choose the next bounded slice or deferral.`
  Acceptance: `The audit records current evidence, remaining gaps, and one implementation direction or deferral decision before any reusable-module behavior change.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT.2` | `pending` | The next R11 left item is the reusable standalone-DT/module-library contract family, and the remaining directions require an evidence-led bounded selection before code. |

Current frontier: `R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT.2`.

## Decisions

- `2026-05-24`: Select a reusable-module contract frontier audit after the
  shared-datapath audit closed. The roadmap names several remaining directions
  across unnamed DT roots, fuller standalone-DT module contracts,
  multi-block enable exposure, advanced DT enable-control, implicit
  system-port policy, generated-child export rules, lookup roots, and reusable
  package/import semantics, so the next safe step is to map shipped evidence
  and choose one bounded implementation slice or deferral.

## Open Questions

- Does the remaining reusable-module frontier contain one bounded immediate
  implementation slice, or should the next behavior-bearing work wait for a
  stronger reusable-module, lookup, package/import, enable-control,
  portable-type, or architecture contract?

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT.1` | `R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT.1: select reusable-module frontier` | `selection slice` |

## Changelog

- `2026-05-24`: Created active `R11` reusable-module contract frontier audit
  tree and selected `.2` as the evidence-gathering frontier.
