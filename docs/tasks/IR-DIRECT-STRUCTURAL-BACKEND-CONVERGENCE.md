# IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE: Direct Backend Structural IR Convergence

## Metadata

- Tree ID: `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE`
- Status: `active`
- Roadmap lane: `architecture backlog`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Move the direct single-module generation path toward the same clean
`StructuralRTLIR -> backend emitter` shape that composition already uses,
without changing emitted HDL semantics or destabilizing existing direct-root
debuggability.

## Non-Goals

- Do not rewrite the whole direct backend in one slice.
- Do not change public HDL output without focused and broad regression gates.
- Do not disturb composition's existing structural-IR emission path unless a
  selected slice explicitly proves shared benefit.
- Do not treat this tree as active until it is selected by the roadmap/PNT
  workflow.

## Acceptance Criteria

- Direct-root backend residues that still bypass `StructuralRTLIR` are
  inventoried with owners and consumers.
- The first behavior-preserving convergence slice is selected before code
  changes begin.
- Any implementation leaf has focused direct-root HDL/semantic checks plus a
  broader regression gate when the blast radius warrants it.
- Book/live-doc updates are made if user-visible inspection, generated output,
  or embedding surfaces change.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE`
  Status: `active`
  Goal: `Converge direct-root backend emission toward StructuralRTLIR where safe.`
  Children: `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.1`,
  `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.2`,
  `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.3`

- ID: `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.1`
  Status: `done`
  Goal: `Map direct-root backend residues that still bypass StructuralRTLIR.`
  Acceptance: `The task file lists direct-root emission/metadata owners,
  current StructuralRTLIR inputs, remaining bypasses, and a smallest safe
  convergence candidate.`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.1: map direct backend residues`

- ID: `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.2`
  Status: `active`
  Goal: `Select the first behavior-preserving convergence slice.`
  Acceptance: `The selected slice names the files, expected no-op behavior,
  focused tests, broad gate, and rollback boundary before implementation.`
  Verification: `pending`
  Commit: `pending`

- ID: `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.3`
  Status: `proposed`
  Goal: `Implement the selected direct-root structural convergence slice.`
  Acceptance: `Direct-root generation consumes the selected StructuralRTLIR
  boundary without behavior drift, and all selected gates pass.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

This tree is active. The current PNT frontier selects the first
behavior-preserving convergence slice from the residue map.

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.1` | `done` | Factual residue mapping completed before any direct-backend refactor. |
| 2 | `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.2` | `active` | Select the smallest no-op convergence slice and its gates before code changes. |

## Direct Backend Residue Map

`IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.1` inspected the direct and
composition generation owners to separate current fact from convergence
aspiration.

Current direct-root flow:

1. `FSM::Pipeline::DirectGenerationOrchestrator` parses direct roots into
   `CoreAST`, builds `IntentHIR`, and creates the initial `module_info`.
2. `FSM::Backend::GeneratedModuleEmitter` calls `FSM::HDL::FlattenedDT`
   directly to emit HDL text.
3. `FSM::Pipeline::GeneratedModuleInfoBuilder` enriches `module_info` after
   backend emission by reading the mutable backend generator state.
4. `FSM::IR::LoweredRTLIRBuilder` derives direct lowered facts from
   `module_info` plus `FlattenedDT` assignment analysis.
5. `FSM::IR::StructuralRTLIRBuilder` builds the direct-root
   `StructuralRTLIR` from enriched `module_info`, currently limited to module
   identity and port/system-port structure.
6. `GeneratedModuleEmitter` appends verification-only runtime assertions to
   the already-emitted HDL text from lowered metadata.

Current composition contrast:

1. `FSM::Composition::GenerationOrchestrator` builds `Composition::Plan`.
2. `StructuralRTLIRBuilder->build_from_composition_plan(...)` creates the
   structural top IR with ports, nets, instances, links, bindings, and
   auxiliary assignments.
3. `StructuralRTLIREmitter->emit_module(...)` emits the top module by walking
   that structural IR.

Residue table:

| Area | Current owner | Current StructuralRTLIR input | Remaining bypass / risk |
| --- | --- | --- | --- |
| Direct HDL module body | `FSM::Backend::GeneratedModuleEmitter`, `FSM::HDL::FlattenedDT`, and `FSM::HDL::FlattenedDT::Orchestrator` | None before emission | HDL text is produced before direct `StructuralRTLIR` exists, so the structural layer cannot be the direct-root emission boundary today. |
| Direct SystemVerilog assembly | `FSM::HDL::FlattenedDT::Backend::SystemVerilog::PostFlatteningAssemblySupport` plus scaffold, declaration, enable, consolidated-intermediate, and tail helpers | `CoreAST` module plus backend context | Port declarations, state/register logic, enables, intermediate declarations, and tail logic are assembled from backend state rather than a structural IR. |
| Direct lowered facts | `GeneratedModuleInfoBuilder` and `LoweredRTLIRBuilder` | `module_info`, `CoreAST`, and `FlattenedDT` assignment analysis | Lowered summaries are useful forward IR, but they are extracted after backend analysis rather than driving backend emission. |
| Direct StructuralRTLIR | `StructuralRTLIRBuilder->build_from_generated_module_info` | Enriched `module_info` signal/system summaries | Direct structural IR currently captures identity and ports. It has no direct behavior body, internal nets, enable graph, state register, or assignment structure sufficient for direct HDL emission. |
| Runtime assertion augmentation | `GeneratedModuleEmitter->augment_with_runtime_assertions` | `module_info` / lowered metadata, not `StructuralRTLIR` | Assertions are text postprocessing after emission. This is behavior-preserving but not part of the structural emitter path. |
| Generated-child direct roots | `FSM::Composition::GeneratedChildRealizer` | Same generated-module direct path as direct roots | Generated children inherit the same direct bypass before their HDL is embedded in composition output. |
| Verilog target | `FSM::HDL::FlattenedDT::Backend::Verilog` | None | Verilog output converts direct SystemVerilog text rather than emitting from structural IR. It should not be the first convergence target. |

Smallest safe convergence candidate for `.2` to evaluate:

- Do not reroute direct-root HDL emission through `StructuralRTLIREmitter` yet;
  the direct `StructuralRTLIR` does not carry enough behavior to reproduce the
  direct module body.
- The first safe slice should be audit/guard style: lock the direct
  `StructuralRTLIR` port/system-port projection against generated HDL or
  normalized semantic output, then use that evidence to select a later
  behavior-bearing convergence point.
- Candidate files for that first slice are likely
  `perl/FSM/IR/StructuralRTLIRBuilder.pm`, direct-root semantic/HDL tests, and
  the book/live docs if the user-visible inspection surface changes.

## Decisions

- `2026-05-20`: Selected as an actionable follow-up from
  `FSMGEN-IR-AUDIT.4` because the architecture snapshot still identifies the
  direct single-module path as not fully converged on the forward
  `StructuralRTLIR -> backend emitter` spine.
- `2026-05-20`: `.1` found that direct roots emit through
  `GeneratedModuleEmitter -> FlattenedDT` before direct `StructuralRTLIR`
  exists. The first convergence step should therefore guard the existing
  direct structural projection instead of attempting to reroute HDL emission.

## Open Questions

- Which direct-root HDL family is the smallest behavior-preserving candidate
  for the first convergence slice?

## Blockers

- None while proposed.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE` | `pending` | `pending` |
| `2026-05-20` | `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.1` | `git diff --check`; `mdbook build docs/book` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE` | `pending` | `pending` |
| `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.1` | `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.1: map direct backend residues` | Mapped direct-root bypasses and advanced `.2` selection. |

## Changelog

- `2026-05-20`: Created proposed follow-up task tree from
  `FSMGEN-IR-AUDIT.4`.
- `2026-05-20`: Completed `.1` direct backend residue mapping and advanced
  the active frontier to `.2` selection.
