# R11-DIRECT-STRUCTURAL-WEN-EN-NETS: Direct Structural WEN/EN Net Projection

## Metadata

- Tree ID: `R11-DIRECT-STRUCTURAL-WEN-EN-NETS`
- Status: `done`
- Roadmap lane: `R11`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Project direct backend DT-specific and LHS-level WEN/EN wires into direct
`StructuralRTLIR` nets as declaration-only one-bit structural facts.

## Ground Truth

- `R11-DIRECT-BACKEND-COORDINATION-FRONTIER.2` already projects
  declaration-only storage/helper nets plus top-level state and standalone-DT
  enable wires into direct `structural_rtl_ir.nets[]`.
- `perl/FSM/Synthesis/EnableGraph/EnableSupport.pm` emits DT-specific enable
  assignments from `assignment_analysis.*.rhs_groups.*.dt_specific_enables`
  and LHS-level enable assignments from
  `assignment_analysis.*.rhs_groups.*.lhs_level_enable`.
- `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/InternalDeclarationEmitter.pm`
  already treats those generated names as one-bit internal wire declarations.
- Direct `StructuralRTLIR` still deliberately does not claim assignment
  connectivity, instances, links, auxiliary assignments, or HDL emission
  rerouting.

## Non-Goals

- Do not claim assignment source/target connectivity.
- Do not populate direct `auxiliary_assignments[]`, instances, links, or
  resolved links.
- Do not reroute HDL emission through `StructuralRTLIR`.
- Do not change enable generation semantics or emitted HDL text.

## Acceptance Criteria

- Direct `structural_rtl_ir.nets[]` includes one-bit declaration-only net
  entries for DT-specific enable names from `dt_specific_enables`.
- Direct `structural_rtl_ir.nets[]` includes one-bit declaration-only net
  entries for LHS-level enable names from `lhs_level_enable`.
- The projection preserves existing storage/helper and top-level
  state/standalone-DT enable net behavior.
- Tests prove regular-state and standalone-DT WEN/EN names are included while
  direct assignment connectivity and auxiliary assignments remain unclaimed.
- Contract/book/README/Knowledge Map wording is synchronized if the public
  structural-IR surface changes.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R11-DIRECT-STRUCTURAL-WEN-EN-NETS`
  Status: `done`
  Goal: `Project direct DT-specific and LHS-level WEN/EN wires as declaration-only StructuralRTLIR nets.`
  Children: `R11-DIRECT-STRUCTURAL-WEN-EN-NETS.1`

- ID: `R11-DIRECT-STRUCTURAL-WEN-EN-NETS.1`
  Status: `done`
  Goal: `Add DT-specific and LHS-level WEN/EN declaration-only net projection to direct StructuralRTLIR.`
  Acceptance: `Direct roots include storage/helper nets, top-level state/standalone-DT enable nets, DT-specific WEN/EN nets, and LHS-level WEN/EN nets in nets[] while assignment connectivity, auxiliary assignments, instances, links, and HDL rerouting remain unclaimed.`
  Verification: `passed`
  Commit: `R11-DIRECT-STRUCTURAL-WEN-EN-NETS.1: project direct wen/en nets`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-DIRECT-STRUCTURAL-WEN-EN-NETS.1` | `done` | Projected DT-specific/LHS WEN/EN wires into direct `StructuralRTLIR` nets; no active next leaf remains in this tree. |

## Decisions

- `2026-06-12`: Keep this slice declaration-only. WEN/EN assignment
  expressions and source/target connectivity need a later exact owner.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `R11-DIRECT-STRUCTURAL-WEN-EN-NETS.1` | `perl -Iperl -c perl/FSM/IR/StructuralRTLIRBuilder.pm`; `perl -Iperl -c perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm`; `perl -Iperl -c t/1333-direct-structural-rtl-ir-projection.t`; `perl -Iperl -c t/163-forward-structural-rtl-ir-surface.t`; `perl -Iperl -c t/624-hdl-generator-stateful-direct-structural-rtl-ir-alias-boundary-audit.t`; `prove -Iperl t/1333-direct-structural-rtl-ir-projection.t t/163-forward-structural-rtl-ir-surface.t t/624-hdl-generator-stateful-direct-structural-rtl-ir-alias-boundary-audit.t`; `prove -Iperl t/341-normalized-semantic-structural-rtl-ir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t`; `prove -Iperl t/206-enable-graph-enable-support.t t/293-systemverilog-post-flattening-assembly-support.t`; `mdbook build docs/book`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `prove -Iperl t/303-normalized-semantic-json-supported-corpus.t t/304-normalized-semantic-json-regression-corpus.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-DIRECT-STRUCTURAL-WEN-EN-NETS.1` | `R11-DIRECT-STRUCTURAL-WEN-EN-NETS.1: project direct wen/en nets` | Implementation slice. |

## Changelog

- `2026-06-12`: Created and activated the next R11 direct StructuralRTLIR
  convergence slice after top-level direct enable net projection shipped.
- `2026-06-12`: Completed `.1`; direct `StructuralRTLIR` nets now include
  declaration-only storage/helper entries plus generated enable-wire entries,
  while assignment connectivity remains outside the projection.
