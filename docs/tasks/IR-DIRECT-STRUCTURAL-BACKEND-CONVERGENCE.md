# IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE: Direct Backend Structural IR Convergence

## Metadata

- Tree ID: `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE`
- Status: `done`
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
  Status: `done`
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
  Status: `done`
  Goal: `Select the first behavior-preserving convergence slice.`
  Acceptance: `The selected slice names the files, expected no-op behavior,
  focused tests, broad gate, and rollback boundary before implementation.`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.2: select direct structural guard`

- ID: `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.3`
  Status: `done`
  Goal: `Implement the selected direct-root structural convergence slice.`
  Acceptance: `Direct-root generation consumes the selected StructuralRTLIR
  boundary without behavior drift, and all selected gates pass.`
  Verification: `perl -Iperl -c t/1333-direct-structural-rtl-ir-projection.t`; `prove -Iperl t/1333-direct-structural-rtl-ir-projection.t`; `prove -Iperl t/162-composition-top-structural-rtl-ir-surface.t t/167-structural-connection-expr-helpers.t`; `mdbook build docs/book`; `git diff --check`
  Commit: `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.3: guard direct structural projection`

## Current Frontier

This tree is closed. The selected no-op direct structural projection guard
landed without changing production behavior.

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.1` | `done` | Factual residue mapping completed before any direct-backend refactor. |
| 2 | `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.2` | `done` | Selected the smallest no-op convergence guard and its gates before code changes. |
| 3 | `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.3` | `done` | Implemented the selected direct structural projection guard. |

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

## Selected First Slice

`IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.2` selects a no-op guard slice:
add focused regression coverage proving the existing direct-root
`structural_rtl_ir` projection is stable and agrees with the generated direct
result's public surfaces.

Selected implementation goal for `.3`:

- Add a focused direct-root test that generates at least one direct `.fsm`
  source through the normal pipeline and inspects the returned
  `structural_rtl_ir`.
- Assert that direct `structural_rtl_ir.module_name`,
  `source_root_kind`, `target_language`, and port entries match the generated
  result's `module_info` / signal-analysis public facts.
- Assert that explicit or implicit system ports present in generated output
  are also represented in direct `structural_rtl_ir.ports`.
- Assert that the direct structural IR remains a projection guard only:
  direct `nets`, `instances`, and `auxiliary_assignments` stay empty until a
  later behavior-bearing slice explicitly widens the direct structural model.
- Do not route direct-root HDL emission through `StructuralRTLIREmitter` in
  `.3`.

Expected no-op behavior:

- Generated HDL text is unchanged.
- Normalized semantic JSON and schedule/report schemas are unchanged.
- Direct `module_info` compatibility shape is unchanged.
- The only intended new behavior is regression coverage for the already
  shipped direct `structural_rtl_ir` projection.

Initial write scope for `.3`:

- Add one focused test under `t/`.
- Update this task file and live docs for the implementation evidence.
- Update the mdBook only if the test exposes a user-visible inspection nuance
  that is not already described in the IR/metadata surfaces chapter.

Focused and broad gates for `.3`:

- `perl -Iperl -c <new direct structural projection test>`
- `prove -Iperl <new direct structural projection test>`
- `prove -Iperl t/162-composition-top-structural-rtl-ir-surface.t t/167-structural-connection-expr-helpers.t`
- `mdbook build docs/book`
- `git diff --check`

Rollback boundary:

- Revert the new focused test and documentation evidence only. No production
  code should change in `.3`; if implementation discovers production behavior
  must change, stop and create or select a more precise follow-up leaf before
  editing production code.

## Implementation Evidence

`IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.3` added
[t/1333-direct-structural-rtl-ir-projection.t](../../t/1333-direct-structural-rtl-ir-projection.t).

The guard generates a direct `.fsm` through the normal `HDLGenerator` pipeline
and proves:

- the top-level direct `structural_rtl_ir` is returned;
- `module_info.structural_rtl_ir` mirrors the same serialized projection;
- module name, source root kind, target language, and port count are stable;
- direct structural ports match `module_info.signal_analysis` plus the
  explicit system clock/reset contract;
- every structural port is present in the generated HDL module header;
- direct `nets`, `instances`, `declared_links`, `resolved_links`, and
  `auxiliary_assignments` remain empty for now.

No production code changed. This is a guard for the existing projection, not a
direct HDL emission reroute.

## Decisions

- `2026-05-20`: Selected as an actionable follow-up from
  `FSMGEN-IR-AUDIT.4` because the architecture snapshot still identifies the
  direct single-module path as not fully converged on the forward
  `StructuralRTLIR -> backend emitter` spine.
- `2026-05-20`: `.1` found that direct roots emit through
  `GeneratedModuleEmitter -> FlattenedDT` before direct `StructuralRTLIR`
  exists. The first convergence step should therefore guard the existing
  direct structural projection instead of attempting to reroute HDL emission.
- `2026-05-20`: `.2` selected a no-op focused regression guard for direct
  `structural_rtl_ir` projection parity. The next implementation must not
  reroute direct HDL emission or widen direct structural semantics.
- `2026-05-20`: `.3` added the selected no-op guard and closed the tree. The
  next behavior-bearing direct structural convergence work needs a new task
  tree or a reopened follow-up leaf before production code changes.

## Open Questions

- Which future direct-root behavior family is the first safe candidate for
  structural modeling beyond ports?

## Blockers

- None while proposed.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE` | `git diff --check`; `mdbook build docs/book` under `FSMGEN-IR-AUDIT.4` | `pass` |
| `2026-05-20` | `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.1` | `git diff --check`; `mdbook build docs/book` | `pass` |
| `2026-05-20` | `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.2` | `git diff --check`; `mdbook build docs/book` | `pass` |
| `2026-05-20` | `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.3` | `perl -Iperl -c t/1333-direct-structural-rtl-ir-projection.t`; `prove -Iperl t/1333-direct-structural-rtl-ir-projection.t`; `prove -Iperl t/162-composition-top-structural-rtl-ir-surface.t t/167-structural-connection-expr-helpers.t`; `mdbook build docs/book`; `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE` | `FSMGEN-IR-AUDIT.4: select IR follow-ups` | Created proposed follow-up task tree. |
| `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.1` | `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.1: map direct backend residues` | Mapped direct-root bypasses and advanced `.2` selection. |
| `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.2` | `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.2: select direct structural guard` | Selected no-op direct structural projection guard and advanced `.3` implementation. |
| `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.3` | `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.3: guard direct structural projection` | Added focused no-op guard and closed the tree. |

## Changelog

- `2026-05-20`: Created proposed follow-up task tree from
  `FSMGEN-IR-AUDIT.4`.
- `2026-05-20`: Completed `.1` direct backend residue mapping and advanced
  the active frontier to `.2` selection.
- `2026-05-20`: Completed `.2` direct structural guard selection and advanced
  the active frontier to `.3` implementation.
- `2026-05-20`: Completed `.3` direct structural projection guard and closed
  the tree.
