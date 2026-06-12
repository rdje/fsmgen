# R11-DIRECT-BACKEND-COORDINATION-FRONTIER: Direct Backend Coordination Frontier

## Metadata

- Tree ID: `R11-DIRECT-BACKEND-COORDINATION-FRONTIER`
- Status: `active`
- Roadmap lane: `R11`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Audit the roadmap-named remaining lower-level direct-backend coordination seam
and select the next exact, signoff-sized executable slice before any source or
test behavior changes.

## Ground Truth

- `docs/TASK_TREE.md` currently has no active or proposed PNT-eligible task.
- `ROADMAP_STATUS.md` marks active lane, active task tree, and current
  frontier as `none`.
- `ROADMAP_V2.md` says the next honest `R11` seam is remaining lower-level
  direct-backend coordination across the consolidated-intermediate planning,
  stage-preparation, stage, prescan-preparation, and tail owners plus broader
  direct-backend convergence.
- The current import-tree architecture note says the old stage, prescan, tail,
  and post-flattening assembly clusters already have dedicated live owners; the
  remaining pressure is lower-level planning/stage coordination and broader
  direct-backend convergence, not another broad wrapper extraction.

## Non-Goals

- Do not refactor direct backend code before this selector leaf picks one exact
  executable boundary.
- Do not reroute HDL emission or broaden public behavior under an architecture
  cleanup label.
- Do not edit frozen legacy blobs (`CHANGES.md`, `DEVELOPMENT_NOTES.md`,
  `ROADMAP_STATUS.md`, `LIVE_ACHIEVEMENT_STATUS.md`).
- Do not change mdBook unless the selected slice affects user-facing behavior
  or user-facing supported-surface claims.

## Acceptance Criteria

- The selector leaf reviews the roadmap and current direct-backend owner/test
  evidence.
- One next exact executable leaf is added or activated, or the tree records a
  no-action/deferral decision with concrete evidence.
- Focused documentation and memory gates pass.
- The completed selector leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R11-DIRECT-BACKEND-COORDINATION-FRONTIER`
  Status: `active`
  Goal: `Select the next exact R11 direct-backend coordination slice from current evidence.`
  Children: `R11-DIRECT-BACKEND-COORDINATION-FRONTIER.1`,
    `R11-DIRECT-BACKEND-COORDINATION-FRONTIER.2`

- ID: `R11-DIRECT-BACKEND-COORDINATION-FRONTIER.1`
  Status: `done`
  Goal: `Audit current direct-backend coordination evidence and choose the next exact executable R11 slice.`
  Acceptance: `The leaf records reviewed files/tests, identifies whether one safe lower-level coordination or direct StructuralRTLIR convergence slice exists, and updates this tree with the selected next leaf or a justified deferral.`
  Verification: `passed`
  Commit: `R11-DIRECT-BACKEND-COORDINATION-FRONTIER.1: select direct enable nets`

- ID: `R11-DIRECT-BACKEND-COORDINATION-FRONTIER.2`
  Status: `pending`
  Goal: `Project top-level direct state and standalone-DT enable wires into direct StructuralRTLIR nets.`
  Acceptance: `Direct-root structural_rtl_ir.nets[] includes existing declaration-only storage/helper nets plus one-bit top-level state/standalone-DT enable wires derived from the already-prepared state_enables and dt_enables registries; the slice does not claim DT-specific/LHS WEN/EN wires, assignment connectivity, instances, links, auxiliary assignments, or reroute HDL emission.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-DIRECT-BACKEND-COORDINATION-FRONTIER.1` | `done` | Selected the next exact direct StructuralRTLIR convergence slice from current evidence. |
| 2 | `R11-DIRECT-BACKEND-COORDINATION-FRONTIER.2` | `pending` | The previous direct structural slice explicitly left generated enable wires outside `structural_rtl_ir.nets[]`; top-level state/DT enable wires are already stable one-bit facts derived by `EnableSupport` and can be projected without rerouting HDL emission. |

## Decisions

- `2026-06-12`: Open this as a selector/audit tree because the active task-tree
  queue is exhausted, while `ROADMAP_V2.md` still records direct-backend
  coordination and convergence as remaining R11 architecture work.
- `2026-06-12`: Selector leaf `.1` chose a narrow behavior-bearing follow-up:
  project only top-level direct state/standalone-DT enable wires into direct
  `structural_rtl_ir.nets[]`. The slice deliberately does not claim
  DT-specific/LHS WEN/EN wires or assignment connectivity.

## Open Questions

- None for the selector leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `R11-DIRECT-BACKEND-COORDINATION-FRONTIER.1` | Evidence review: `ROADMAP_V2.md`; `ROADMAP_STATUS.md`; `docs/BIN_FSMGEN_IMPORT_TREE.md`; `docs/tasks/ARCHITECTURE-DEBT-FRONTIER.md`; `docs/tasks/IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.md`; `perl/FSM/IR/StructuralRTLIRBuilder.pm`; `perl/FSM/Synthesis/EnableGraph/EnableSupport.pm`; `perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm`; `t/1333-direct-structural-rtl-ir-projection.t`; `t/206-enable-graph-enable-support.t`; `t/293-systemverilog-post-flattening-assembly-support.t`; `perl -Iperl -c perl/FSM/IR/StructuralRTLIRBuilder.pm`; `perl -Iperl -c perl/FSM/Synthesis/EnableGraph/EnableSupport.pm`; `prove -Iperl t/1333-direct-structural-rtl-ir-projection.t t/206-enable-graph-enable-support.t t/293-systemverilog-post-flattening-assembly-support.t`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `git --no-pager diff --check` | `passed`; selected `.2` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-DIRECT-BACKEND-COORDINATION-FRONTIER.1` | `R11-DIRECT-BACKEND-COORDINATION-FRONTIER.1: select direct enable nets` | Selector/audit slice. |
| `R11-DIRECT-BACKEND-COORDINATION-FRONTIER.2` | `pending` | `pending` |

## Changelog

- `2026-06-12`: Created after the previous PNT queue was exhausted and the
  roadmap still identified remaining lower-level direct-backend coordination
  plus broader direct-backend convergence as the next honest R11 architecture
  seam.
- `2026-06-12`: Completed selector leaf `.1`; activated `.2` for top-level
  direct state/standalone-DT enable-wire projection into direct
  `StructuralRTLIR` nets.
