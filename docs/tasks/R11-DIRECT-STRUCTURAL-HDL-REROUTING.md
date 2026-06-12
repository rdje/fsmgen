# R11-DIRECT-STRUCTURAL-HDL-REROUTING: Direct HDL Rerouting Through StructuralRTLIR

## Metadata

- Tree ID: `R11-DIRECT-STRUCTURAL-HDL-REROUTING`
- Status: `active`
- Roadmap lane: `R11`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Reroute selected direct HDL emission through `StructuralRTLIR` once the direct
structural surface is rich enough to preserve the current generated HDL
semantics without relying on parallel string-only generation paths.

## Non-Goals

- Do not change HDL emission while this tree remains `proposed`; an explicit
  active leaf must own any implementation slice.
- Do not reroute before the required direct structural ports, nets, assignment
  records, and net source/target connectivity have been selected or proven
  sufficient for the chosen slice.
- Do not use string parsing as the rerouting contract.
- Do not broaden to VHDL, package-root HDL emission, composition HDL parity, or
  instance/link rerouting unless a later activated leaf explicitly selects that
  scope.
- Do not remove compatibility surfaces without a compatibility-specific owner.

## Acceptance Criteria

- A readiness/selection leaf identifies the first safe HDL rerouting slice and
  all required structural prerequisites.
- The selected implementation leaf, when activated, generates the chosen direct
  HDL path from `StructuralRTLIR` while preserving existing supported behavior.
- Focused HDL regression tests and broader semantic/HDL gates prove no
  unintended output drift for the selected fixtures.
- Public contracts, mdBook, roadmap, Knowledge Map, and task-tree evidence are
  updated when an implementation leaf is activated.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R11-DIRECT-STRUCTURAL-HDL-REROUTING`
  Status: `active`
  Goal: `Reroute selected direct HDL emission through StructuralRTLIR.`
  Children: `R11-DIRECT-STRUCTURAL-HDL-REROUTING.1`, `R11-DIRECT-STRUCTURAL-HDL-REROUTING.2`

- ID: `R11-DIRECT-STRUCTURAL-HDL-REROUTING.1`
  Status: `done`
  Goal: `Audit direct HDL emission parity prerequisites and select the first StructuralRTLIR-rerouted HDL slice.`
  Acceptance: `A readiness/selection slice records the first reroute target, required structural fields, validation matrix, rollback boundary, and documentation targets before any HDL rerouting code changes.`
  Verification: `passed`
  Commit: `R11-DIRECT-STRUCTURAL-HDL-REROUTING.1: select direct HDL reroute target`

- ID: `R11-DIRECT-STRUCTURAL-HDL-REROUTING.2`
  Status: `pending`
  Goal: `Reroute direct generated-enable continuous assignment emission through StructuralRTLIR.`
  Acceptance: `The direct SystemVerilog generated-enable assignment block is emitted from StructuralRTLIR assignment records or their scalar compatibility mirror through an explicit handoff path; output HDL for focused fixtures remains equivalent; no unmarked HDL parsing, full module reroute, VHDL reroute, instances/links reroute, or compatibility-surface removal occurs.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-DIRECT-STRUCTURAL-HDL-REROUTING.2` | `pending` | The selected first reroute target is the direct generated-enable continuous assignment block, because that block is represented structurally by assignment records and scalar compatibility lines while the rest of direct module emission still requires backend-only always-block/output-drive state. |

## Decisions

- `2026-06-12`: Track HDL rerouting through `StructuralRTLIR` as its own R11
  tree so it is planned explicitly and not conflated with assignment records or
  source/target connectivity.
- `2026-06-12`: Select generated-enable continuous assignment emission as the
  first reroute target. Full direct module emission remains unsafe because
  direct output-drive/always-block bodies are not yet represented by
  `StructuralRTLIR`.
- `2026-06-12`: `.2` must use an explicit direct-backend handoff or explicit
  generated-enable assignment block markers. It must not parse unmarked HDL
  text to find assignments.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `R11-DIRECT-STRUCTURAL-HDL-REROUTING.1` | Selection audit/read of `docs/tasks/R11-DIRECT-STRUCTURAL-HDL-REROUTING.md`; `docs/tasks/R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.md`; `docs/TASK_TREE.md`; `README.md`; `ROADMAP_V2.md`; `perl/FSM/Pipeline/DirectGenerationOrchestrator.pm`; `perl/FSM/Backend/GeneratedModuleEmitter.pm`; `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/PostFlatteningAssemblySupport.pm`; `perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm`; `perl/FSM/IR/StructuralRTLIRBuilder.pm`; `t/1333-direct-structural-rtl-ir-projection.t`; `t/293-systemverilog-post-flattening-assembly-support.t`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `git --no-pager diff --check` | `passed`; selected `.2` |
| `2026-06-12` | `R11-DIRECT-STRUCTURAL-HDL-REROUTING.2` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-DIRECT-STRUCTURAL-HDL-REROUTING.1` | `R11-DIRECT-STRUCTURAL-HDL-REROUTING.1: select direct HDL reroute target` | Selected direct generated-enable continuous assignment emission as the first reroute target and opened `.2`. |
| `R11-DIRECT-STRUCTURAL-HDL-REROUTING.2` | `pending` | `pending` |

## Changelog

- `2026-06-12`: Created proposed task tree.
- `2026-06-12`: Activated `.1`, selected generated-enable continuous
  assignment emission as the first direct StructuralRTLIR reroute target, and
  opened implementation frontier `.2`.
