# R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT: Reusable-Module Contract Frontier Audit

## Metadata

- Tree ID: `R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT`
- Status: `done`
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
  Status: `done`
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
  Status: `done`
  Goal: `Audit shipped reusable-module behavior and choose the next bounded slice or deferral.`
  Acceptance: `The audit records current evidence, remaining gaps, and one implementation direction or deferral decision before any reusable-module behavior change.`
  Verification: `passed: focused reusable-module evidence, feature-backlog audit, mdBook build, and diff check`
  Commit: `R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT.2: audit reusable-module frontier`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT.2` | `done` | The next R11 left item is the reusable standalone-DT/module-library contract family, and the remaining directions require an evidence-led bounded selection before code. |

Current frontier: `closed`.

## Decisions

- `2026-05-24`: Select a reusable-module contract frontier audit after the
  shared-datapath audit closed. The roadmap names several remaining directions
  across unnamed DT roots, fuller standalone-DT module contracts,
  multi-block enable exposure, advanced DT enable-control, implicit
  system-port policy, generated-child export rules, lookup roots, and reusable
  package/import semantics, so the next safe step is to map shipped evidence
  and choose one bounded implementation slice or deferral.
- `2026-05-24`: Do not select a new reusable-module implementation slice now.
  The shipped bounded contract already covers canonical `?dt:name` roots,
  compatibility aliases outside strict child-source checks, composition-facing
  `?dtc` children, explicit standalone-DT system metadata, reusable source
  lookup through embedded roots / repeated `--path DIR` roots / `FSMLIB` /
  local source context, block-enable families, grouped multi-drive targets,
  SystemVerilog assertion hooks, composition child exports, generated-child
  defaults and parameter overrides, CLI summaries, and forward-IR export
  surfaces. Broader unnamed roots, authored DT enable-control, declarative
  reusable packages, advanced reusable-module interface/export rules, broader
  lookup policy, external activation/deactivation, advanced same-target
  merge/priority, and debug-reporting semantics should wait for one precise
  reusable-module, lookup, package/import, enable-control, portable-type, or
  architecture contract.

## Audit Result

Supported shipped evidence:

- Direct standalone-DT roots are supported through canonical `?dt:name`, with
  `?mod:name` and `?module:name` retained as compatibility aliases outside
  strict child-source checks.
- Composition-facing `?dtc` children can realize embedded or externally
  resolved standalone-DT sources in the shipped generated-child lanes.
- Generated child source lookup covers embedded roots, repeated `--path DIR`
  roots, `FSMLIB`, and local source context; named `?dtc:name` children may
  default the source token to `name`.
- Standalone-DT roots may opt into explicit `+system` metadata, and composition
  auto-wires those explicit system inputs when the top exposes matching names.
- Direct `?dt` roots and realized `?dtc` children preserve standalone-DT
  block-enable family metadata and module-level enable-family summaries.
- Grouped standalone-DT multi-drive target metadata reports target signal,
  mux/storage class, DT names, RHS values, per-DT enable signals, grouped LHS
  enable signals, and onehot0 assertion metadata.
- SystemVerilog direct `?dt` roots and realized `?dtc` children emit bounded
  non-synthesis multi-drive guard assertions; Verilog keeps the metadata and
  omits SystemVerilog assertion syntax.
- Composition tops aggregate reusable standalone-DT child exports through
  `composition_standalone_dt_children` and related count fields in
  `module_info` and `intent_hir`.
- Reusable standalone-DT child exports preserve each realized child's forward
  `intent_hir`, `lowered_rtl_ir`, and structural interface boundary summaries
  where those layers exist.
- The mdBook now documents the full shipped contract and its backlog boundary.

No implementation slice is selected from this tree. The next R11 activity
should move to another roadmap family while future reusable-module work should
be selected only when one broader reusable-module, lookup, package/import,
enable-control, portable-type, or architecture prerequisite is ready.

## Open Questions

- None. `.2` owns the evidence-gathering audit and deferral decision.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |
| `2026-05-24` | `R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT.2` | `prove -Iperl t/48-language-contract-standalone-dt-classification.t t/82-standalone-dt-root-support.t t/83-reusable-source-path-resolution.t t/85-composition-standalone-dt-children.t t/86-composition-single-child-connect-by-name.t t/130-composition-generated-child-source-shape-diagnostics.t t/133-standalone-dt-root-aliases.t t/134-standalone-dt-explicit-system-support.t t/135-composition-generated-child-default-source-names.t t/136-standalone-dt-enable-family-metadata.t t/137-standalone-dt-multi-drive-family-metadata.t t/138-composition-standalone-dt-export-metadata.t t/154-standalone-dt-assertion-runtime-hdl.t t/157-composition-standalone-dt-forward-ir-exports.t t/171-forward-lowered-rtl-ir-standalone-dt-target-helpers.t t/292-composition-generated-child-parameter-overrides.t`; `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: focused reusable-module evidence Files=16, Tests=42; feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT.1` | `R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT.1: select reusable-module frontier` | `selection slice` |
| `R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT.2` | `R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT.2: audit reusable-module frontier` | `audit/deferral slice` |

## Changelog

- `2026-05-24`: Created active `R11` reusable-module contract frontier audit
  tree and selected `.2` as the evidence-gathering frontier.
- `2026-05-24`: Completed `.2`, recorded that no new reusable-module
  implementation slice is selected now, documented the shipped bounded
  contract in the mdBook, and closed the tree.
