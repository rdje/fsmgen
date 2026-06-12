# R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING: Full Direct HDL Rerouting

## Metadata

- Tree ID: `R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING`
- Status: `deferred`
- Roadmap lane: `R11`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Reroute broader or full direct SystemVerilog module emission through
`StructuralRTLIR` once the direct structural surface can preserve generated HDL
semantics.

## Non-Goals

- Do not change behavior in selector `.1`.
- Do not duplicate the already shipped top state/standalone-DT
  generated-enable reroute from `R11-DIRECT-STRUCTURAL-HDL-REROUTING`.
- Do not include VHDL rerouting; that has a separate proposed owner.
- Do not use unmarked HDL string parsing as the rerouting contract.
- Do not remove compatibility surfaces unless a compatibility-specific owner
  approves the change.

## Acceptance Criteria

- A selector/readiness leaf proves the exact first broader SystemVerilog
  reroute target and all required `StructuralRTLIR` prerequisites before code
  changes.
- Any implementation leaf emits only the selected direct SystemVerilog HDL
  portion from `StructuralRTLIR` and preserves existing supported behavior.
- Focused HDL regression tests plus broader semantic/HDL gates prove no
  unintended output drift.
- Public contracts, mdBook, roadmap, README, and Knowledge Map are updated when
  behavior or user-visible inspection changes.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING`
  Status: `deferred`
  Goal: `Reroute broader direct SystemVerilog HDL emission through StructuralRTLIR.`
  Children: `R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.1`,
    `R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.2`

- ID: `R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.1`
  Status: `done`
  Goal: `Select the next broader direct SystemVerilog HDL reroute target.`
  Acceptance: `The selector records current reroute coverage, missing structural prerequisites, first safe broader HDL target, focused fixtures, validation gates, rollback boundary, and docs/contracts to update before behavior changes.`
  Verification: `passed`
  Commit: `R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.1: defer full direct reroute`

- ID: `R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.2`
  Status: `deferred`
  Goal: `Implement a broader direct SystemVerilog reroute after behavior-body structural prerequisites exist.`
  Acceptance: `No implementation runs from this tree until direct StructuralRTLIR has an exact task-tree-owned behavior-body/state-update/output/assertion region capable of reproducing focused direct SystemVerilog HDL without unmarked text parsing.`
  Verification: `not run; deferred by selector .1`
  Commit: `deferred`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.1` | `done` | Selector confirmed the only safe direct reroute remains the already-shipped generated-enable marker handoff. |
| 2 | `R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.2` | `deferred` | Broader/full direct SystemVerilog rerouting is blocked until direct StructuralRTLIR owns behavior-body/state-update/output/assertion regions. |

## Decisions

- `2026-06-12`: Track broader direct SystemVerilog rerouting separately from
  the completed top state/standalone-DT generated-enable reroute so partial
  shipped behavior is not confused with full module rerouting.
- `2026-06-12`: Selector `.1` found no safe broader reroute target. The direct
  structural surface now has ports, declaration nets, generated-enable
  assignment records, auxiliary assignment mirrors, generated-enable
  source/target connectivity, and compact output-port source summaries, but it
  still does not represent the ordered direct behavior body: state register
  update, next-state/output always blocks, selector/conflict assertion regions,
  temporal/immediate assertion augmentation, or full backend tail assembly.
  Full rerouting remains deferred until those regions have exact structural
  ownership.

## Open Questions

- Direct behavior-body/state-update/output/assertion structural ownership is
  missing. Unblock condition: a future exact task-tree leaf represents enough
  direct behavior body in `StructuralRTLIR` to reproduce focused direct
  SystemVerilog HDL without unmarked text parsing.

## Blockers

- Not active.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.1` | Audit/read: `docs/tasks/R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.md`; `docs/tasks/R11-DIRECT-STRUCTURAL-HDL-REROUTING.md`; `docs/tasks/IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.md`; `docs/TASK_TREE.md`; `README.md`; `ROADMAP_V2.md`; `docs/book/src/14-feature-backlog.md`; `perl/FSM/Pipeline/DirectGenerationOrchestrator.pm`; `perl/FSM/Backend/GeneratedModuleEmitter.pm`; `perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm`; `perl/FSM/IR/StructuralRTLIRBuilder.pm`; `perl/FSM/IR/StructuralRTLIR.pm`; `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ScaffoldEmitter.pm`; `t/194-generated-module-emitter.t`; `t/293-systemverilog-post-flattening-assembly-support.t`; `t/1333-direct-structural-rtl-ir-projection.t`; `mdbook build docs/book`; `prove -Iperl t/194-generated-module-emitter.t t/293-systemverilog-post-flattening-assembly-support.t t/1333-direct-structural-rtl-ir-projection.t`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check` | `passed`; no broader implementation target selected |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.1` | `R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.1: defer full direct reroute` | Selector deferred broader/full direct SystemVerilog rerouting until direct behavior-body structural prerequisites exist. |
| `R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.2` | `deferred` | No implementation runs from this tree until the behavior-body prerequisite is task-tree owned and shipped. |

## Changelog

- `2026-06-12`: Created proposed owner tree.
- `2026-06-12`: Completed selector `.1`; broader/full direct SystemVerilog
  rerouting remains deferred behind direct behavior-body structural
  prerequisites, and no implementation leaf was opened.
