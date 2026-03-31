# FSMGen Roadmap v2

This is the detailed companion to [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md).

Use this file for:
- the detailed post-`R0`..`R7` roadmap shape,
- sequencing and dependency rationale,
- and the concrete intent behind the active `R8+` workstreams.

Use [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) for:
- the canonical live status,
- current active lane,
- and done/left tracking.

## Why roadmap v2 exists
`R0` through `R7` closed the first major modernization roadmap:
- live roadmap tracking,
- `FlattenedDT` cleanup,
- synthesis ownership migration,
- AST/CoreAST-first convergence,
- assignment semantics modernization,
- generator reuse safety,
- scoped composition,
- and typed extension replacement.

The remaining work is no longer “finish the refactor.”
It is “turn the modernized tool into a stricter, more explicit, more trustworthy language/tool contract.”

That is what roadmap v2 is for.

## v2 principles
- Prefer explicit language contracts over implicit parser acceptance.
- Distinguish “implemented” from “supported”.
- Make diagnostics part of the product, not just a debugging aid.
- Grow surface area only when semantics are crisp and regression-backed.
- Keep composition and extension growth deliberate rather than legacy-compatible by default.

## Current package-breakdown note
- The bounded source-frontend family now has an explicit owner in [perl/FSM/Pipeline/SourceFrontend.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceFrontend.pm), covering Lispish file parsing, top-level source-kind classification, typed composition parsing, and semantic FSM/DT module creation.
- That means [perl/FSM/Pipeline/SourceGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceGenerationOrchestrator.pm), [perl/FSM/Pipeline/DirectGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/DirectGenerationOrchestrator.pm), [perl/FSM/Composition/GenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GenerationOrchestrator.pm), and [perl/FSM/Composition/GeneratedChildRealizer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GeneratedChildRealizer.pm) no longer need `HDLGenerator` to keep that frontend family inline.
- The old composition failure-summary and provenance/override/block label helper residue is now also gone from [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm), because [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) and the direct failure-summary regression coverage now call the dedicated builder owners directly.
- The old direct generated-module helper residue is now also gone from [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm): direct-root/generated-child callers and the direct-owner tests now talk to [perl/FSM/IR/IntentHIRBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/IntentHIRBuilder.pm), [perl/FSM/IR/StructuralRTLIRBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIRBuilder.pm), [perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm), [perl/FSM/Backend/GeneratedModuleEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Backend/GeneratedModuleEmitter.pm), and [perl/FSM/Pipeline/SourceFrontend.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceFrontend.pm) directly.
- The remaining source-frontend wrapper residue is now also gone from [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm): test coverage and internal callers now ask [perl/FSM/Pipeline/SourceFrontend.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceFrontend.pm) directly.
- That leaves `HDLGenerator` at the intended thin public facade shape: shared pipeline configuration plus `generate_hdl_from_file(...)`.
- The first bounded direct SystemVerilog scaffold family now also has an explicit owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ScaffoldEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ScaffoldEmitter.pm), covering header, module declaration, state encoding, and state register rendering.
- The internal declaration family now also has an explicit owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/InternalDeclarationEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/InternalDeclarationEmitter.pm), covering bounded `reg` declaration rendering from the enable-graph declaration plan.
- The direct first-pass AST-factorization pipeline now also has an explicit owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GlobalFactorizationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GlobalFactorizationSupport.pm), while [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ASTFactorizationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ASTFactorizationSupport.pm) is now narrowed to substituted-AST lookup plus the legacy direct intermediate-signal rendering helper, and the old [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm) package is now gone from the live direct backend path.
- The direct SystemVerilog intermediate runtime-recovery family now also has an explicit owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalRecoverySupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalRecoverySupport.pm), covering runtime AST lookup, rendered-expression caching, and dependency recovery for the direct intermediate-signal path.
- The paired direct SystemVerilog intermediate width family now also has an explicit owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm), covering width normalization and recursive width inference for that same direct intermediate-signal path.
- The paired direct SystemVerilog intermediate filter-heuristic family now also has an explicit owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalFilterPolicySupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalFilterPolicySupport.pm), covering AST-aware keep/filter heuristics, runtime-AST-miss live-usage fallback, and the small AST-shape predicates used by that decision path.
- The direct consolidated-intermediate selection owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSelectionSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSelectionSupport.pm) now owns the live AST-first keep/filter dispatch over the extracted recovery and filter-policy owners directly, and the older [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm) package now survives only as a compatibility-shell test surface outside the live backend path.
- The direct SystemVerilog consolidated intermediate collection family now also has an explicit owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSupport.pm), covering AST-factorized, pre-scanned, and FSMGen-parsed intermediate-signal collection for the direct backend block that appears before unified WEN/EN generation.
- The paired direct SystemVerilog consolidated intermediate normalization family now also has an explicit owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateNormalizationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateNormalizationSupport.pm), covering runtime AST, width, dependency, rendered-expression, and live-usage normalization over that same merged signal set before selection, planning, and emission.
- The paired direct SystemVerilog consolidated intermediate classification family now also has an explicit owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateClassificationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateClassificationSupport.pm), covering the initial AST-first keep/filter partition over that normalized direct backend set before dependency rescue and ordering.
- The direct SystemVerilog consolidated intermediate selection family now also has an explicit owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSelectionSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSelectionSupport.pm), covering dependency-aware rescue plus final kept/filtered summary projection for the normalized and initially classified direct backend set that appears before unified WEN/EN generation.
- The paired direct SystemVerilog consolidated intermediate dependency family now also has an explicit owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateDependencySupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateDependencySupport.pm), covering dependency-map construction plus dependency-safe emission ordering for that same direct backend block.
- The paired direct SystemVerilog consolidated intermediate planning family in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePlanningSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePlanningSupport.pm) is now narrowed to overall plan composition over the extracted selection and dependency owners.
- The older direct SystemVerilog consolidated intermediate block-preparation package in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateBlockSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateBlockSupport.pm) now survives only as a directly testable compatibility shell outside the live backend path.
- The paired direct SystemVerilog prepared consolidated intermediate block family now also has an explicit owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePreparedBlockSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePreparedBlockSupport.pm), covering prepared block-contract projection from the collected normalized set plus the composed plan.
- The paired direct SystemVerilog consolidated intermediate stage-preparation family now also has an explicit owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStagePreparationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStagePreparationSupport.pm), covering live prepared-block reconstruction from the extracted collection, planning, and prepared-block projection owners.
- The paired direct SystemVerilog consolidated intermediate rendering family now also has an explicit owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateRenderingSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateRenderingSupport.pm), covering final prepared-block rendering over the extracted declaration and assignment owners.
- The direct SystemVerilog consolidated intermediate assignment family now also has an explicit owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateAssignmentSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateAssignmentSupport.pm), covering prepared assign emission from that block contract.
- The direct SystemVerilog consolidated intermediate declaration family now also has an explicit owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateDeclarationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateDeclarationSupport.pm), covering prepared wire-declaration rendering from that same block contract.
- The live direct stage handoff is now composed directly in [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm) from [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStagePreparationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStagePreparationSupport.pm) plus [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateRenderingSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateRenderingSupport.pm), while the older [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm) package now survives only as a compatibility shell outside the live backend path.
- The older direct SystemVerilog consolidated intermediate-signal emission package in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm) now survives only as a directly testable compatibility shell outside the live backend path.
- The iterative post-substitution factorization path now also has an explicit loop-state owner in [perl/FSM/HDL/Factorization/Fixpoint/LoopStateSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint/LoopStateSupport.pm), covering aggregate loop-state creation, accepted-pass outcome application, and final termination/result normalization.
- The iterative post-substitution factorization path now also has an explicit single-pass execution owner in [perl/FSM/HDL/Factorization/Fixpoint/PassExecutionSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint/PassExecutionSupport.pm), covering per-pass factorizer construction, repeated-signature short-circuit detection, and one-pass substitution/update execution.
- The paired per-pass helper owner in [perl/FSM/HDL/Factorization/Fixpoint/PassSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint/PassSupport.pm) continues to cover primary intermediate lookup, deterministic pass signatures, second-pass name-collision recovery, and new-signal projection/debugging, while the paired [perl/FSM/HDL/Factorization/Fixpoint.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint.pm) package is now narrowed further to pass scheduling and top-level coordination.
- The synthesis-side intermediate-signal registry and dependency-recovery family now also has an explicit owner in [perl/FSM/Synthesis/EnableGraph/IntermediateSignalSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph/IntermediateSignalSupport.pm), and the direct backend plus synthesis callers now ask that owner directly instead of keeping that whole pocket inline in [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm).
- The synthesis-side factorization-analysis and substitution/live-usage evidence family now also has an explicit owner in [perl/FSM/Synthesis/EnableGraph/FactorizationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph/FactorizationSupport.pm), and the direct backend plus fixpoint callers now ask that owner directly instead of keeping that AST-factorization bookkeeping inline in [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm).
- The new direct owner lock in [t/203-enable-graph-factorization-support.t](/Users/richarddje/Documents/github/fsmgen/t/203-enable-graph-factorization-support.t) also records one important contract nuance: in the prepared direct backend context, some synthesized factorization intermediates can be live by substitution evidence only rather than by final owner-side expression presence, so this owner is about analysis and synchronization evidence, not fake final-expression ownership.
- The next honest `R11` seam is now no longer the aggregate loop-state contract in [perl/FSM/HDL/Factorization/Fixpoint.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint.pm), the collection/normalization split inside the direct consolidated backend path, the initial AST-first classification split there, the dependency-map/ordering split there, the old direct intermediate dispatcher shell, the old direct consolidated block shell, the old direct consolidated emitter shell, the old direct consolidated generation shell, prepared block-contract projection, prepared wire-declaration rendering, live stage preparation, final prepared-block rendering, recursive decision-tree flattening, the structural pre-stage prelude pocket, the logical-count/prescan pocket inside the narrowed enable-preparation owner, the retired live generation-prelude shell, or the retired live generation-pipeline shell. It is the remaining lower-level direct-backend coordination across [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePlanningSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePlanningSupport.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStagePreparationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStagePreparationSupport.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStageSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStageSupport.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPrescanPreparationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPrescanPreparationSupport.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationEnablePreparationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationEnablePreparationSupport.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationStructuralPreludeSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationStructuralPreludeSupport.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationTailSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationTailSupport.pm], and [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm), not the already-extracted per-pass execution, loop-state lifecycle, AST-vs-runtime filter heuristics, collection/normalization prep, first-pass classification, dependency graph mechanics, old compatibility-shell cleanup, prepared block projection, declaration rendering, stage preparation, or stage orchestration.

## Workstreams
### R8. Language-contract hardening
Goal:
- turn the current supported-language boundary into a normative contract.

Why first:
- this is the highest-value gap between a capable tool and a serious tool.

Deliverable themes:
- one normative `.fsm` language reference,
- one clear support-tier model,
- one explicit bucket for every parser-visible construct:
  - fully supported,
  - intentionally experimental/deferred,
  - or explicitly rejected.

Initial sub-slices:
1. Promote the already-agreed semantics for:
   - guarded blocks,
   - condition suffixes,
   - update shorthand,
   - and operator-arity rules
   from engineering notes into a normative reference.
2. Resolve the remaining gray-zone families:
   - `(+system ...)` beyond conventional `clk` / `rstn`,
   - `(+constants ...)`, `(+enums ...)`, `(+define ...)`, `(+params ...)`,
   - any remaining parser-accepted legacy constructs not yet classified clearly.
3. Add focused per-family regression coverage so support claims become provable.

Expected result:
- the active language boundary becomes crisp enough that strict mode can be built on top of it cleanly.

### R9. Strict mode and support-tier enforcement
Goal:
- let users choose “only the supported language” explicitly.

Deliverable themes:
- a strict mode in the CLI/pipeline,
- targeted errors for constructs outside the fully supported tier,
- and workflow guidance on when to use strict mode.

Expected result:
- production users can choose predictability over compatibility residue.

### R10. Source provenance and diagnostics
Goal:
- make parser/generator failures precise, actionable, and source-local.

Deliverable themes:
- file/line/construct provenance through parsing and generation,
- targeted errors instead of generic fallthrough failures,
- and clearer remediation guidance in diagnostics.

Expected result:
- large `.fsm` files become much easier to debug and review.

### R11. Composition contract strengthening
Goal:
- deepen the shipped `R6` composition model and adjacent reusable module/type contracts without widening them carelessly.

Deliverable themes:
- formalize the `.rtlif` mini-contract,
- decide whether a stronger interface-source contract should later replace or sit above `.rtlif`,
  - record and later deliberately reduce the current architectural hotspot set instead of letting those seams stay as unnamed background debt:
  - split composition policy, interface inference, and top-emission planning back out of `FSM::Pipeline::HDLGenerator`,
  - keep one dedicated live architecture note for the CLI entrypoint/import-tree shape in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md), and refresh it when the effective spine or package ownership picture changes enough that the saved analysis is no longer honest,
  - start extracting explicit forward compiler IR layers out of the currently mixed pipeline instead of leaving proto-HIR/proto-lowered semantics implicit:
    - first one bounded `Intent HIR` slice for direct generated roots and realized generated children,
    - then one bounded `Lowered RTL IR` slice once that first forward semantic surface is stable,
    - then one bounded `Structural RTL IR` / connectivity slice once the lowered summary stops being asked to stand in for the full emitted wiring shape,
    - while keeping those forward IR shapes aligned with the future shared-middle/import architecture rather than growing a separate forward-only semantic stack,
  - shrink `FSM::Synthesis::EnableGraph` toward a clearer synthesis ownership boundary instead of one ever-growing semantic gravity well,
  - move planning/normalization residue out of `FSM::HDL::FlattenedDT::Backend::SystemVerilog` so the backend boundary becomes more honestly rendering-oriented,
  - make the bridge between `FSM::CoreAST::*` and `FSM::AST::*` more explicit so future work is not forced to rediscover that seam inside `EnableGraph`,
  - decide whether `FSM::ExpressionNamer` is real remaining surface or compatibility residue that should eventually be retired,
  - remove stale CLI/help compatibility wording from `bin/fsmgen`,
  - and revisit the global-state shape in `FSM::Debug` before `R13` embedding/API work makes that harder to change,
- define one bounded multi-FSM shared-datapath composition lane instead of reopening broad implicit composition:
  - one `fsmgen` run may build one top from one `.fsm` source or from several `.fsm` sources,
  - some child outputs remain directly owned by their source FSMs,
  - outputs assigned in at least two child FSMs are the shared-datapath candidates and may be lifted into one shared datapath block instantiated by the generated top,
  - outputs assigned in only one child FSM are not shared and should remain directly child-owned,
  - outputs produced by the child FSMs or by the shared datapath block are top-level outputs by default,
  - if a registered output is read on the RHS by another child FSM, that signal should become top-internal by default instead of auto-exported,
  - if such a now-internal registered signal must also appear as a top-level output, the user should request that export explicitly,
  - that shared block owns the mux/register logic for those lifted targets and receives deterministic per-child drive-intent enables such as `A_P_Q_en`, `B_P_Q_en`, and aggregate enables such as `P_Q_en`,
  - lifted registered/shared outputs may be looped back into child FSM inputs and may be either top-local or top-exposed,
  - combinational outputs, whether shared or not, must not become cross-FSM read sources and should only exist as top-level outputs,
  - same-target/same-value aggregation should remain distinct from same-target/different-value conflicts,
  - the default shared-drive contract should surface conflict/assertion bits rather than auto-resolve or auto-prioritize,
  - per `(P, Q)` families should support onehot0-style checks over source enables such as `A_P_Q_en`, `B_P_Q_en`, and `C_P_Q_en`,
  - and per-target `P` families should support assertion bits that detect more than one value-family enable being active in the same cycle,
- define one bounded reusable standalone-DT/module-library lane instead of reopening broad implicit hierarchy:
  - add `?dt:name` as the smallest standalone module description,
  - let `?dt:name` contain any number of internal general DT blocks such as `(-foo ...)`,
  - `?dt:name` may mix combinational outputs such as `(P = RHS)` and sequential outputs such as `(Q <- QRHS)` in the same standalone DT module,
  - the semantic split from `?fsm:name` is the control model, not “combinational only” versus “sequential allowed”,
  - `?fsm:name` should implicitly declare `clk` / `rst_n`,
  - `?dt:name` should implicitly declare `clk` / `rst_n` only when at least one sequential assignment exists in that standalone DT module,
  - `?top:name` and sequential `?dt:name` should keep `rst_n` as the default async-reset convention even if the current explicit `?fsm` `+system` compatibility residue still spells `rstn`,
  - output-driving semantics inside `?dt:name` should stay aligned with the current DT handling inside `?fsm:name`,
  - multiple internal `(-foo ...)` blocks in the same `?dt:name` may assign the same target without being rejected structurally,
  - but the generated enable families must still support mutual-exclusion assertions so arbitration stays explicit,
  - keep `?top:name` as the explicit composition-root concept unless a later family-level root-syntax decision adds aliases such as `?mod:name` or `?module:name`,
  - let reusable `.fsm` module roots be located through existing `FSMLIB`-style search roots plus explicit per-invocation CLI search roots,
  - start any future standard-library lane as ordinary reusable `.fsm` roots that flow through the same parser, IR, diagnostics, provenance, and backend path as user sources instead of privileged builtins,
  - prefer a small curated gold set of broadly reusable control/dataflow helpers before any broad primitive zoo,
  - and prefer repeatable `--path DIR` search-root options over comma-packed path lists so lookup stays deterministic and shell-friendly,
- define one bounded portable synthesizable-type lane instead of bolting backend-specific struct/record behavior onto the current scalar-oriented language:
  - add one frontend type core that maps honestly to both SystemVerilog and future VHDL:
    - bits / bit-vectors,
    - enums,
    - records / packed-struct-like aggregates,
    - fixed-size arrays,
    - arrays of records,
    - and named aliases / subtypes,
  - defer backend-specific or semantically sharp-edged features such as unions and user-visible promises of free aggregate-to-vector casting until the portable core is stable,
  - prefer convention over configuration by making type inference the default path for most signals and ports:
    - infer scalar versus aggregate shape from LHS and RHS usage,
    - infer record fields and array shapes from member/index access and compatible assignments,
    - and keep explicit type declarations available mainly as overrides, disambiguation anchors, and interface-stability controls,
  - keep the initial operational contract narrower than the eventual syntax surface:
    - member/field reads and writes,
    - fixed-index and bounded array-element access,
    - exact-type whole-aggregate assignment only after the member-access lane is stable,
    - and explicit conversion helpers later where backend differences require them,
- and harden mixed `?fsmc` / `?rtl` flows before adding broader composition syntax.
- record one future composition-syntax cleanup decision instead of leaving it as untracked taste:
  - decide whether `?toplink` should remain the canonical spelling,
  - or whether a clearer preferred alias such as `?wiring` should be added above it while keeping `?toplink` as compatibility spelling until a deliberate syntax cleanup pass says otherwise.
- record one future bounded syntax-power direction instead of drifting either into verbosity or into a general macro language:
  - highest-leverage candidates currently look like:
    - interface bundles / protocol groups,
    - enum-first `case` / `match` style control capture,
    - small local aliasing/default blocks for repeated guards and output intent,
    - bounded replication for repeated instances/lanes,
    - first-class intent helpers for common RTL patterns such as edge/pulse/sticky/handshake/conflict checks,
    - terse invariant/assertion forms,
    - and stronger explain/report surfaces for inferred behavior,
  - if a future generic/meta-programming lane is opened, it should stay list-oriented, semantic, elaboration-bounded, and 100% RTL/synthesis-focused,
  - if explicit parameterization/generics are opened, prefer explicit list-oriented parameter declarations with defaults plus explicit override binding, and make them elaborate through the same semantic pipeline instead of text substitution,
  - such a lane should lower into the same typed AST / diagnostics path as ordinary syntax instead of acting like a parallel text/template preprocessor,
  - and it should explicitly avoid broad source-to-source macros, general-purpose metaprogramming, or anything that reopens the old legacy placeholder/template ambiguity.

First shipped `R11` slice now in tree:
- `?dt:name` is now an active standalone-module root in the live toolchain.
- `?mod:name` and `?module:name` are now also active standalone-DT root aliases in the live toolchain.
- The `.rtlif` mini-contract is now explicit enough to build on:
  - one flat `(?rtlif:module_name ...)` root,
  - embedded same-file `(?rtlif:module_name ...)` companion roots taking precedence over sidecar metadata when present,
  - declaration-ordered port tokens,
  - compact tokens such as `clk`, `data_in<8`, and `txd>`,
  - typed tokens such as `core_clk:clock`, `rst_async_n:reset`, and `data_in<8:data`,
  - explicit type annotations currently limited to `data`, `clock`, and `reset`,
  - typed `clock` / `reset` metadata now enabling honest auto-wiring of custom-named RTL system ports in the shipped mixed-composition lane,
  - mixed composition no longer requiring a separate sidecar file when the external RTL interface contract is embedded in the composition source itself,
  - single-child composition now also covering a lone `?rtl` child across passthrough, explicit-link, and declared by-name lanes,
  - and explicit-link composition now also covering any explicit-link top with at least one `?rtl` child, including multiple generated children beside those RTL children.
- The shipped first slice currently supports:
  - top-level general DT blocks such as `(-foo ...)`,
  - the conventional explicit `(+system ...)` section plus directive sections `(+size ...)`, `(+constants ...)`, `(+enums ...)`, `(+define ...)`, and `(+params ...)`,
  - compact top-level `(:= signal=value)` directives,
  - explicit conventional `+system` yielding `clk` / `rstn` in standalone-DT roots and composition-facing `?dtc` children,
  - implicit `clk` / `rst_n` only when the `?dt:name` source contains sequential assignments and no explicit `+system` is present,
  - default output exposure for driven non-intermediate targets,
  - repeatable `--path DIR` search roots for bare `.fsm` input lookup,
  - the same explicit search roots feeding current `.rtlif` metadata lookup ahead of `FSMLIB`,
  - external `?fsmc` composition child sources resolved from sibling or searched `.fsm` files without leaving the active typed pipeline,
  - named `?fsmc:name` and `?dtc:name` children omitting the explicit source token when the child source should default to `name`,
  - `?dtc` composition child realization from embedded or external standalone-DT sources, including honest non-system interfaces for purely combinational DT children,
  - module-info-level reusable standalone-DT metadata for direct roots, realized `?dtc` children, and top-level composition aggregation of those realized child exports,
  - plus one bounded standalone-DT onehot0-style assertion-metadata/export layer for grouped multi-drive targets through DT-specific driver-enable families,
  - plus the first actual SystemVerilog standalone-DT assertion-emission slice through non-synthesis grouped-target guard assertions in direct `?dt` roots and realized `?dtc` children while keeping Verilog emission clean,
  - module-info-level shared-datapath candidate metadata for same-name output families across multiple realized `?fsmc` children,
  - and the first bounded per-child drive-intent metadata for those candidate families through generated-child `output_drive_families` plus candidate-contributor `drive_intent`,
  - plus one bounded aggregate-enable metadata layer for those candidates through deterministic whole-target and per-value aggregate enable names,
  - plus the first planned conflict-bit metadata layer for those candidates through `P_Q_multi_src_conflict`-style and `P_multi_value_conflict`-style names,
  - plus one bounded onehot0-style assertion-metadata layer for those candidates through deterministic per-child source-enable aliases and whole-target/per-value assertion inputs,
  - plus the first actual shared-datapath helper HDL slice for those candidates through hidden child source-enable export bindings and generated aggregate/conflict wires in the composition top,
  - plus the first actual SystemVerilog shared-datapath assertion-emission slice through non-synthesis same-value and whole-target conflict guards in the generated top while keeping Verilog emission clean,
  - plus one bounded lifted-ownership planning layer for those candidates through storage-class, peer-read endpoint, default-visibility, planned re-export, and loopback-policy metadata,
  - plus one bounded combinational peer-read policy layer for those candidates through explicit public-preserving top-output-only versus internal-only top-local policy and surfaced block-reason metadata,
  - plus the first actual bounded combinational peer-read public-preserving runtime through one emitted shared top-facing combinational carrier, peer-input rebinding, and preserved top-output re-export assignments,
  - plus the sibling bounded combinational peer-read internal-only runtime through one emitted shared top-local combinational carrier, peer-input rebinding, and no invented public top re-export assignments,
  - plus the sibling bounded combinational public-only fanout runtime through that same emitted shared top-facing combinational carrier and preserved public top-output fanout without requiring peer-read child inputs,
  - plus the first actual lifted shared-target behavior for the bounded registered peer-read public-preserving case through one emitted shared top-level register, peer-input rebinding, and preserved top-output re-export assignments, now including mixed public/internal carrier families,
  - plus the sibling bounded registered peer-read internal-only runtime case through that same emitted shared top-level register and peer-input rebinding without invented public re-export assignments,
  - plus the sibling bounded registered public-only fanout runtime through that same emitted shared top-level register and preserved public top-output fanout without requiring peer-read child inputs,
  - bounded single-child `C1` top-interface inference when `?ports` is omitted or empty, with the inferred top interface matching the lone realized child interface exactly,
  - bounded explicit-link `C2` / `C3` omitted/empty-`?ports` inference when explicit `?toplink` endpoints themselves still make the top boundary unambiguous, including renamed top-boundary signals with one consistent direction plus exact width/type agreement,
  - bounded explicit-link `C2` / `C3` undeclared top-input inference when same-name child inputs remain top-facing and agree exactly on direction, width, and type metadata,
  - bounded explicit-link `C2` / `C3` undeclared top-output inference when exactly one same-name child output remains top-facing and is not already consumed by explicit child-to-child wiring,
  - bounded explicit-link `C2` / `C3` plain-explicit-top-port same-name convention when child-side evidence is still exact and safe:
    - plain explicit top inputs may fan out by same name when compatible child inputs agree exactly on direction, width, and type metadata,
    - plain explicit top outputs may adopt one unique same-name top-facing child output when that child-side evidence stays exact,
    - mixed-direction plain-input families fail explicitly,
    - multi-output plain-output families fail explicitly,
    - and explicit top-boundary links still override that convention locally,
  - first bounded composition-plan transparency metadata:
    - top ports carry `origin_kind` so declared versus inferred top-boundary decisions remain visible,
    - links carry `origin_kind` so explicit toplinks, `=name`, same-name convention links, internal-carrier links, and auto system-port links can be distinguished,
    - and the typed composition plan exposes `resolved_links` as the full resolved link set used by planning,
  - first bounded user-facing composition provenance reporting on top of that metadata:
    - composition generation results now carry `composition_report`,
    - the report summarizes top-port and resolved-link provenance by `origin_kind`,
    - the report now also surfaces the first shipped local override events,
    - the report now also surfaces the first shipped blocked convention events,
    - plain explicit top-port same-name convention failures now also say when that convention is blocked instead of only implying it,
    - undeclared top-input/top-output and undeclared internal-carrier inference failures now also say when those convention-first inference paths are blocked,
    - explicit-toplink-driven undeclared top-port inference failures now also say when that inference path is blocked by direction, width, or type disagreement,
    - explicit `?toplink` validation failures now also say when endpoint resolution, direction, duplicate-drive, or width evidence blocks the declared link,
    - explicit-link top-wiring and realized-child-wiring failures now also say when declared top ports or realized child ports remain unwired in explicit-link lanes,
    - explicit-link lane-entry and topology failures now also say when explicit-link lanes are entered without `?toplink`, when top inputs try to drive top outputs directly, or when one source tries to drive multiple top outputs,
    - top-level composition lane/shape gates now also say when lane entry is blocked by missing child instances and when shape is blocked by invalid `?ports` multiplicity or omitted/empty `?ports` outside the bounded inference cases,
    - explicit top-output re-export mismatches for inferred same-name internal carriers now also say when that bounded re-export path is blocked by width or type disagreement,
    - declared `=name` connect-by-name failures now also say when the declared match is blocked by direction, width, ambiguity, or missing-endpoint evidence,
    - and `bin/fsmgen` now prints the same provenance summary for non-quiet composition runs,
  - bounded explicit-link `C2` / `C3` undeclared same-name internal-carrier inference when no explicit link already touches that name family, exactly one same-name child output remains available, and one or more same-name child inputs remain available,
  - bounded local override on top of that convention: an explicit same-name top output may adopt and re-export one of those inferred carriers when direction, width, and type metadata still match exactly,
  - single-generated-child declared connect-by-name through `=name` for both `?fsmc` and `?dtc` children,
  - and declared connect-by-name now covering one or more generated children, one or more external `?rtl` children, or any mixture of those generated and external RTL children when the top-level exact-match rule is still unambiguous,
  - and declared connect-by-name is now direction-asymmetric at the top boundary, with top outputs staying exact-one-match while top inputs may fan out to all matching child inputs of the same name and width,
  - and standalone-DT child interface direction now preferring semantic signal roles over the older name-based output heuristic in composition-facing interface realization.
- The shipped first slice does not yet widen into:
  - regular FSM-state blocks inside `?dt:name`,
  - broader implicit parent-interface inference for undeclared top ports beyond the bounded single-child `C1` passthrough slice and bounded `C2` / `C3` undeclared top-input/top-output/internal-carrier slices,
  - broader reusable-module interface/export rules beyond the now-shipped module-info-level standalone-DT enable-family, grouped multi-drive-family, and composition-facing child-export surfacing slices,
  - or unnamed-root questions.
- The first explicit forward-compiler IR extraction slice is now also shipped:
  - direct generated roots now build one explicit `FSM::IR::IntentHIR` summary before `module_info` is derived,
  - that serialized `intent_hir` summary now flows back in direct generation results,
  - realized generated children (`?fsmc` / `?dtc`) now also preserve that same serialized forward intent summary through their `module_info`,
  - and the shipped slice is intentionally narrow: root identity, system contract, regular-state versus standalone-DT families, stable signal-analysis summaries, and standalone-DT enable families are now explicit.
- The first explicit forward `Lowered RTL IR` extraction slice is now also shipped:
  - new `FSM::IR::LoweredRTLIR` now captures one explicit lowered forward summary for generated output-drive families and standalone-DT grouped multi-drive targets,
  - direct generated roots now expose that serialized `lowered_rtl_ir` summary in generation results,
  - realized generated children (`?fsmc` / `?dtc`) now also preserve that same serialized lowered summary through their `module_info`,
  - and selected downstream composition/export consumers now prefer the extracted `lowered_rtl_ir` surface when present instead of re-reading only ad hoc legacy fields.
- That same first widening step is now also shipped through one top-level composition export surface: aggregated `composition_standalone_dt_children` entries now preserve each realized `?dtc` child's serialized `intent_hir` and `lowered_rtl_ir` summaries instead of stripping those explicit forward layers back off at the top boundary.
- That same reusable standalone-DT export surface now also lives inside composition-top `IntentHIR`, and the compatible top-level `module_info` summary now mirrors it back out from that explicit semantic layer instead of keeping it as a separate ad hoc side channel.
- The next widening step is now also shipped through one broader generated-child composition export surface:
  - top-level `composition_generated_children` now covers realized `?fsmc` and `?dtc` children together instead of only the reusable standalone-DT subset,
  - those exported generated-child entries preserve both serialized `intent_hir` and serialized `lowered_rtl_ir`,
  - and non-quiet `bin/fsmgen` runs now print one concise generated-child summary derived from that broader export instead of requiring plan-internal inspection.
- The next widening step is now also shipped through the shared-datapath candidate surface:
  - shared-datapath candidate contributors now preserve their realized child's serialized `intent_hir` and serialized `lowered_rtl_ir`,
  - those same contributor entries now also preserve the exact selected `output_drive_family` from that child's serialized `lowered_rtl_ir`,
  - and the existing bounded `drive_intent` summary is now derived from that extracted family instead of standing alone,
  - those contributor entries now also preserve stable generated-child identity through `kind` and `source_name`,
  - and non-quiet `bin/fsmgen` runs now print one concise contributor-context line from that forward child IR surface before the existing drive-intent summary.
- The next widening step is now also shipped through composition tops themselves:
  - direct `?top` generation results now expose serialized top-level `intent_hir` and serialized top-level `lowered_rtl_ir`,
  - those composition-top forward layers now carry stable top-port analysis plus composition child-count / lane metadata on the intent side,
  - that same composition-top `intent_hir` surface now also carries the broader generated-child export instead of leaving it only as a separate top-level compatibility summary,
  - those same composition-top forward layers now also carry stable internal-net / instance / auxiliary-assignment summaries plus the bounded shared-datapath candidate surface on the lowered side,
  - and `module_info` now mirrors those same serialized composition-top forward IR layers instead of leaving composition tops as the remaining forward-IR gap.
- The first bounded `Structural RTL IR` extraction slice is now also shipped:
  - new `FSM::IR::StructuralRTLIR` now captures one explicit AST/netlist-like connectivity surface for composition tops,
  - direct `?top` generation results now expose serialized `structural_rtl_ir`,
  - composition-top `module_info` now mirrors that same serialized structural surface,
  - the shipped slice currently covers explicit top ports, internal nets, realized instances, pin bindings, and auxiliary assignments,
  - those structural instance pin bindings now also preserve a first typed `connection_expr` node, currently bounded to backend-neutral `signal_ref`,
  - and realized composition-plan instances now also preserve that same typed `signal_ref` node before structural serialization instead of forcing `StructuralRTLIR` to synthesize it late,
  - with that earlier binding normalization now owned by `FSM::Composition::RealizedInstance` itself instead of only by `HDLGenerator`,
  - and the current bounded `signal_ref` construction, signal-name recovery, and backend-neutral text rendering for those actual-connection nodes now also live in dedicated `FSM::IR::StructuralRTLIR::ConnectionExpr` helpers instead of staying split across pipeline glue,
  - with the remaining “effective binding expression” fallback now also centralized there, so structural serialization no longer re-synthesizes `signal_ref` nodes ad hoc from `signal_name` inside `HDLGenerator`,
  - and the first bounded signal-ref binding constructor/update helpers now also live there, so the pipeline no longer hand-pairs `signal_name` and `connection_expr` when creating or rebinding structural instance bindings,
  - with normalized binding cloning/backfilling now also centralized there, so both `FSM::Composition::RealizedInstance` and structural instance-binding serialization consume the same bounded binding contract,
  - and the first bounded signal-ref binding-list ensure/set operations now also live there, so `HDLGenerator` no longer owns the low-level “reuse this binding versus append/update it” rules for structural port-binding lists,
  - and the active composition-top emitter now walks that structural layer instead of re-reading only `FSM::Composition::Plan` state directly during top-module dumping.
- The next structural widening step is now also shipped:
  - direct generated `?fsm` / `?dt` results now expose a bounded structural module-interface slice through `structural_rtl_ir`,
  - that direct-root structural slice currently covers explicit module ports plus empty nets/instances/auxiliary structure,
  - and realized generated-child export surfaces now preserve that same child `structural_rtl_ir` beside `intent_hir` and `lowered_rtl_ir`.
- The next structural-consumption step is now also shipped:
  - realized generated-child interface planning now consumes `structural_rtl_ir` as its first boundary source of truth instead of rebuilding child ports only from signal analysis,
  - and that handoff explicitly normalizes low-level declaration types like `wire`/`logic` back into plain semantic data ports so composition type-matching does not accidentally tighten.
- The next IR-to-IR handoff step is now also shipped:
  - composition-top `lowered_rtl_ir` now consumes `structural_rtl_ir` for internal-net names, realized-instance names, and auxiliary-assignment counts instead of rebuilding that bounded connectivity summary directly from the plan,
  - and that keeps the lowered/structural boundary explicit: `StructuralRTLIR` owns the concrete wiring shape while `LoweredRTLIR` mirrors only the lowered summary it actually needs.
- The next structural-consumption step is now also shipped:
  - composition-top `module_info` and `statistics` now consume `structural_rtl_ir` for child, top-port, and internal-net counts instead of rereading those bounded accounting fields directly from plan internals.
- The next IR-to-IR handoff step is now also shipped through top-level bookkeeping:
  - `module_info` now derives internal-net names/counts, instance names/counts, auxiliary-assignment count, and composition lane from `lowered_rtl_ir` / `intent_hir` instead of falling back straight to raw plan bookkeeping,
  - and `statistics` now derives composition lane and shared-datapath candidate count from `intent_hir` / `lowered_rtl_ir` instead of only carrying those fields straight from plan/runtime state.
- The next structural-consumption step is now also shipped through composition provenance:
  - `composition_report` now consumes `structural_rtl_ir` for top-port metadata and resolved-link endpoint lookup, so that bounded reporting surface no longer rereads those explicit boundary/interface details directly from plan internals.
- The next structural-consumption step is now also shipped through override/block reporting:
  - composition override/block event grouping and candidate-context lookup now consume `structural_rtl_ir` for top-port and child-interface metadata, so that bounded reporting surface no longer rereads those same interface families directly from plan internals.
- The next IR-to-IR handoff step is now also shipped through composition-top semantic summaries:
  - composition-top `intent_hir` now consumes `structural_rtl_ir` for top-port names, counts, and grouped signal-analysis families,
  - and the compatible top-level `module_info` signal metadata now mirrors that same structural top-port boundary instead of rebuilding it separately from plan internals.
- The next structural widening step is now also shipped through explicit resolved connectivity:
  - composition-top `structural_rtl_ir` now preserves resolved links as first-class structural connectivity entries alongside ports/nets/instances/bindings,
  - `composition_report` now derives its resolved-link identity/origin list from that structural layer instead of rereading plan-only link state,
  - and compatible top-level accounting now keeps resolved-link counts aligned with `structural_rtl_ir`.
- The next structural widening step is now also shipped through declared connectivity:
  - composition-top `structural_rtl_ir` now preserves declared explicit-toplink connectivity separately through `declared_links` instead of only carrying the post-resolution link graph,
  - and block-event reasoning for explicit child links now consumes that structural declared-link surface instead of rereading declared toplinks directly from the plan.
- The next structural-consumption step is now also shipped through override/block resolved-link handling:
  - composition override events now take their explicit-toplink and inferred-reexport connectivity from `structural_rtl_ir->{resolved_links}`,
  - and the kept-internal internal-carrier block path now also derives its family detection from that same structural resolved-link surface instead of rereading resolved links from the plan.
- The next widening step is now also shipped through the composition provenance/reporting surface:
  - `composition_report` now preserves per-resolved-link endpoint context instead of only raw endpoint strings,
  - those endpoint contexts now carry bounded forward child summaries when a resolved link touches a realized generated child endpoint,
  - and top-port / resolved-link provenance kinds now each preserve one stable example subject so non-quiet CLI summaries are no longer counts-only in that area.
- The next widening step is now also shipped through the composition override/block reporting surface:
  - override and block events now preserve structured top-port / child-endpoint context instead of only flat signal names,
  - those generated-child endpoint contexts now carry bounded forward child summaries from `intent_hir` and `lowered_rtl_ir`,
  - and non-quiet CLI override/block sections now print richer link/endpoint examples instead of count-plus-name examples only.
- The next widening step is now also shipped through the broader composition child semantic surface:
  - composition-top `intent_hir` now carries one unified `composition_child_count` / `composition_children` export across all realized child kinds (`?fsmc`, `?dtc`, and `?rtl`),
  - compatible top-level `module_info` now mirrors that same unified child export instead of leaving child identity split across narrower side channels only,
  - those unified child entries preserve stable child identity together with each realized child's `intent_hir`, `lowered_rtl_ir`, and `structural_rtl_ir` summaries when present,
  - and composition provenance / override / block endpoint context lookup now consumes that unified semantic child export instead of rereading realized child identity only from plan instances.
- The next structural-consumption step is now also shipped through the unified composition child export itself:
  - `composition_children` now derives child identity and order from `structural_rtl_ir->{instances}` instead of rereading realized child identity directly from `composition_plan->instances`,
  - and the narrower generated-child and reusable standalone-DT export builders now reuse that same computed child surface in the top-generation path instead of each rebuilding it again.
- The next narrowing step is now also shipped through the generated-child export path:
  - the narrower `composition_generated_children` export now derives from the broader semantic `composition_children` layer,
  - so generated-child export identity no longer gets reconstructed separately from plan instances,
  - and the existing generated-child surface stays stable while depending more directly on the explicit forward semantic layer.
- The sibling narrowing step is now also shipped through the reusable standalone-DT export path:
  - the narrower `composition_standalone_dt_children` export now derives from the broader semantic `composition_children` layer,
  - so reusable standalone-DT child export identity no longer gets reconstructed separately from plan instances,
  - child standalone-DT names and enable families now come from child `intent_hir`, grouped multi-drive targets now come from child `lowered_rtl_ir`,
  - and the existing reusable standalone-DT export surface stays stable while depending more directly on the explicit forward semantic and lowered layers.
- The next lowering step is now also shipped through shared-datapath candidate discovery:
  - shared-datapath candidate discovery now consumes `structural_rtl_ir` for top-output / child-interface connectivity instead of rereading those bounded families directly from plan ports/instances,
  - contributor identity and lowered contributor context now come from the unified semantic `composition_children` export,
  - and the existing candidate surface stays behaviorally the same while depending less on ad hoc plan crawling inside `HDLGenerator`.

Expected result:
- composition remains explicit and serious instead of drifting back toward legacy implicit behavior.
- convention should stay the primary integration path, while explicit configuration should act as a precise local override instead of forcing whole-interface restatement.

Planned bounded sub-lane inside `R11`:
- shared datapath extraction for multi-FSM tops.
- intent:
  - keep FSM children as controllers,
  - keep singly-owned outputs in their owning child FSMs,
  - and let only multiply-assigned shared/register-bearing targets move into one common datapath block.
- first contract questions to settle:
  - beyond the now-shipped same-name candidate-discovery metadata, how multiply-assigned lifted targets are declared and detected,
  - which RHS/value sources must also be surfaced to the shared datapath block,
  - how per-child drive intents are named and reported,
  - how same-target/same-value aggregation differs from same-target/different-value conflicts,
  - how conflict/assertion bits are expressed and named for per-`(P, Q)` source-enable families and for whole-target `P` value-family conflicts,
  - the bounded combinational peer-read lane now ships in one public-preserving top-facing form,
  - the bounded registered peer-read lane now ships in public-preserving, mixed-boundary, and internal-only forms,
  - and the remaining question is which broader registered outputs should internalize automatically, when public re-export should stay explicit or defaulted beyond the now-shipped peer-read and public-fanout slices, which lifted registered outputs may legally loop back into child FSM inputs, and how far the combinational lane should widen beyond the now-shipped peer-read public-preserving, internal-only, and public-fanout slices.
- reusable standalone-DT/module-library roots.
- intent:
  - treat `?dt:name` as the smallest reusable standalone module form,
  - allow one `?dt:name` source to contain any number of internal general DT blocks such as `(-foo ...)`,
  - allow that standalone DT module form to mix combinational and sequential outputs freely,
  - keep `?fsm:name` on implicit `clk` / `rst_n` by default,
  - let `?dt:name` acquire implicit `clk` / `rst_n` only when a sequential assignment exists,
  - keep the output-driving semantics inside `?dt:name` aligned with existing DT handling instead of inventing a separate conflict model,
  - keep `?top:name` as the explicit composition root while treating `?dt:name`, `?mod:name`, and `?module:name` as the current standalone-DT root family,
  - and extend reusable-source lookup through existing `FSMLIB` semantics plus repeatable `--path DIR` CLI roots.
- longer-term hierarchy direction:
  - whole `.fsm` designs should eventually behave as authored bottom-up multi-level hierarchies with non-leaf composition nodes and leaf implementation nodes,
  - users should still invoke only the top root, with `fsmgen top.fsm` recursively realizing child nodes, collecting interfaces/semantic summaries bottom-up, and resolving bindings/wiring at each parent level until the final top is emitted,
  - internal non-leaf reusable composition modules should eventually become first-class authored artifacts instead of composition remaining only a top-shell over leaf children,
  - and the implementation should distinguish authored graph from elaborated instance tree: source reuse may form a DAG, while elaboration still produces a concrete hierarchy for emission.
- first contract questions to settle:
  - what the exact source-root family becomes beyond the now-shipped `?fsm:name`, `?dt:name`, `?mod:name`, `?module:name`, and `?top:name`,
  - whether unnamed reusable DT roots such as `?dt:` should exist at all or remain deferred,
  - how standalone DT interfaces are declared/exposed,
  - how block-level and module-level enable families are surfaced so same-target arbitration stays explicit without structural over-rejection,
  - how lookup precedence works between explicit paths, `--path` roots, `FSMLIB`, and local files,
  - how duplicate-name shadowing is diagnosed,
  - and how reusable DT/module roots are referenced from other `.fsm` sources without drifting back into legacy implicit behavior.
- portable synthesizable scalar/aggregate types with inference-first declarations.
- intent:
  - add one portable synthesizable type system that works as a frontend contract first and a backend lowering problem second,
  - let most users omit explicit type declarations most of the time by inferring signal and port types from how names are used in assignments and expressions,
  - and keep explicit type declarations mainly as overrides where inference is ambiguous or where the user wants to freeze an interface contract.
- proposed syntax:
```lisp
(+types
  (type bit1 bit)
  (type byte (bits 8))
  (type word (bits 32))
  (type state_t (enum IDLE RUN DONE))
  (type axi_t
    (record
      (valid bit)
      (data (bits 32))
      (keep (bits 4))))
  (type axi_vec_t
    (array 4 axi_t)))
```
```lisp
(+ports
  (in  payload_in byte)
  (out status     state_t)
  (out bus        axi_t))
```
```lisp
(bus.valid = 1)
(bus.data  = payload_in)
(lanes[0].keep = 15)
(pkt <- next_pkt)
```
- phased implementation boundaries:
  1. add a first-class type AST plus explicit type declarations and backend-lowerable named types, without yet promising broad inference or aggregate-wide operations,
  2. add conservative inference for scalar versus aggregate declarations from LHS/RHS/member/index usage, while allowing explicit declarations to override or pin intent,
  3. add member/field and fixed-size array access in DT expressions and assignments,
  4. add exact-type whole-aggregate assignment and typed port/interface exposure rules,
  5. add explicit conversion/helper boundaries for backend differences, especially future VHDL record/vector lowering.
- first contract questions to settle:
  - which syntax is the canonical explicit declaration surface: `(+types ...)` only, or a paired signal/port type-annotation family too,
  - how far inference is allowed to go before the tool must require an explicit type anchor,
  - whether inferred aggregate declarations are recorded back into generated interface/type sections or remain internal planner facts only,
  - how enums interact with the already-shipped `(+enums ...)` lane versus a future unified type section,
  - how record/array literals are deferred or introduced without overcommitting early,
  - and how SystemVerilog packed-type convenience is prevented from leaking into a VHDL-hostile frontend promise.

### R12. Regression corpus and support accounting
Goal:
- make support claims measurable and continuously checked.

Deliverable themes:
- curate a representative `.fsm` corpus,
- classify each case as supported / expected-failure / legacy-out-of-scope,
- and add golden outputs or semantic checks where appropriate.

Expected result:
- support claims stop being conversational and become auditable.

### R13. Public embedding/API stabilization
Goal:
- make FSMGen intentionally embeddable as a library/tooling component.

Deliverable themes:
- stabilize the `HDLGenerator` result contract,
- document the typed extension/context contract at an embedding level,
- and consider a more explicit serializable plan/report boundary where useful.

Expected result:
- the project becomes a stronger platform for downstream tooling, not just a CLI.

### R14. VHDL backend, if still wanted
Goal:
- implement a real VHDL backend only after the language contract is solid enough to support a second backend honestly.

Deliverable themes:
- define the VHDL backend scope,
- implement the single-FSM lane first,
- then decide whether composition-top VHDL generation is still desirable.

Expected result:
- VHDL becomes a deliberate second backend, not a speculative unfinished promise.

## Sequencing
Recommended order:
1. `R8`
2. `R9`
3. `R10`
4. `R11`
5. `R12`
6. `R13`
7. `R14`

Dependency logic:
- `R9` depends on `R8`, because strict mode needs a crisp language contract.
- `R10` benefits from `R8`, because better diagnostics depend on knowing the intended construct boundary.
- `R11` should follow `R8`, because composition should grow against a stable language core.
- `R12` should start as soon as `R8` classifications harden, because the corpus is how those claims stay honest.
- `R14` should come last, because a second backend multiplies ambiguity if the language contract is still gray.

## Long-term horizon (not active workstreams yet)
These are intentional long-term goals, but they are not near-term roadmap lanes.

Gating rule:
- first make FSMGen state-of-the-art,
- rock solid,
- and really stable
through the `R8`..`R13` contract-hardening and product-hardening work.

Only then should the project seriously widen its long-term ambition into these horizon goals.

### H1. Rust FSMGen
Long-term goal:
- create a Rust implementation of FSMGen.

Intent:
- carry the mature language/tool contract into a stronger long-term systems implementation,
- not to re-open the language-design phase in a second implementation prematurely.

Prerequisite:
- the language contract, diagnostics contract, support accounting, and embedding surface must already be stable enough that a Rust implementation is an execution project, not a moving-target rewrite.

Initial execution guidance:
- start the first serious Rust implementation in this same repository rather than in a separate repository with the current Perl tree as a submodule,
- keep the Perl implementation as the reference/oracle while the Rust implementation grows beside it,
- share one roadmap, one documentation set, one regression corpus, and one differential-test harness across both implementations,
- and only consider splitting into a separate repository later if release cadence, contributor workflow, packaging, or ownership really diverge enough that a monorepo becomes friction rather than leverage.

Rationale:
- a same-repo start keeps the contract, fixtures, snapshots, and expected diagnostics physically close to both implementations,
- it avoids submodule drift and cross-repository version skew while the Rust implementation is still proving semantic parity,
- and it makes it much easier to treat the Perl codebase as a semantic reference instead of trying to maintain two partially decoupled moving targets.

### H2. Public project website
Long-term goal:
- create a very nice, beautiful, and dynamic public website for FSMGen so other people can discover and use the project.

Intent:
- publish the project professionally once the tool is strong enough to represent publicly with confidence,
- with a site that highlights:
  - the language,
  - the generated HDL model,
  - examples,
  - documentation,
  - and why the tool is worth adopting.

Prerequisite:
- the tool itself should first be strong enough that the website is amplifying a genuinely trustworthy product rather than compensating for an unstable one.

### H3. HDL import / intent recovery
Long-term goal:
- add a bounded reverse-direction lane that can recover `.fsm`-style design intent from `SystemVerilog` or `VHDL` inputs.

Intent:
- treat `.fsm` as the canonical design-intent IR,
- and treat HDL-to-`.fsm` as import/recovery rather than as a claim of exact source inversion.

Constraint:
- do not promise full or lossless recovery for arbitrary handwritten HDL,
- even when the input stays within synthesizable RTL.

Primary scope boundary:
- target synthesizable RTL rather than arbitrary simulation/testbench HDL.

Preferred execution order:
- begin with design/probe work and bounded round-trip experiments before promoting HDL import to a primary implementation lane,
- start with `fsmgen`-generated `SystemVerilog` as the first round-trip/import target,
- then support a bounded handwritten synthesizable HDL subset where ports, clocks/resets, FSMs, DT-like logic, datapath structure, and composition hierarchy are recognizable,
- keep serious recovery implementation behind the current forward/backend cleanup and language-contract stabilization so the reverse lane is targeting a steadier semantic surface,
- and only later decide how much broader `SystemVerilog` or `VHDL` recovery is worth attempting.

Required behavior:
- recover recognizable structure honestly into `.fsm`,
- surface a report that distinguishes recognized intent, bounded heuristics, and unsupported residue,
- and never pretend certainty where the HDL structure is ambiguous.

Recovery stance:
- do not freeze `.fsm` prematurely if repeated HDL recovery cases reveal a missing first-class semantic construct,
- but keep any such growth semantic, readable, and elegant instead of turning the language into a generic macro or syntax mirror of HDL,
- and prefer explicit residue/annotation reporting over forcing weak evidence into fake high-level elegance.

Expected technical pipeline:
- preprocess `SystemVerilog` / `VHDL` when needed,
- parse the HDL into an AST,
- run frontend semantic compilation work such as name/type/parameter/interface resolution,
- elaborate hierarchy, generate structure, and resolved bindings without requiring a full backend compile/synthesis flow,
- build a typed canonical RTL IR with provenance,
- recover design intent from that IR into `.fsm`,
- and emit a recovery report alongside the recovered source.

Planned IR layering:
- do not describe the reverse-path early layer as a “non-semantic HIR”; the non-semantic layer is the parsed HDL CST/AST, and honest recovery actually needs more semantic structure rather than less,
- the forward `.fsm` to HDL compiler should now be treated as likely converging toward `parsed .fsm AST -> semantic Intent HIR -> Lowered RTL IR -> Structural RTL IR / Connectivity IR -> backend emission`,
- the reverse HDL-import path should converge toward `parsed HDL CST/AST -> semantic HDL HIR -> elaborated RTL IR -> Flat IR -> recovered Intent IR -> .fsm output + recovery report`,
- the important refinement is that the current `Lowered RTL IR` should not be expected to double as the full connectivity graph forever: it can carry normalized lowering summaries and backend-relevant analysis without being the final structural object that the emitter walks,
- the planned `Structural RTL IR` / connectivity layer should eventually be an AST-like netlist structure that carries explicit ports, nets, instances, pin/binding edges, assignments, and backend-facing auxiliary structure so HDL emission becomes primarily a rendering walk instead of a place where connectivity is rediscovered ad hoc,
- that `Structural RTL IR` should stay backend-neutral and extensible rather than collapsing into raw SystemVerilog/VHDL syntax, so child actual-pin connections should eventually be represented through typed structural connection expressions / actual-connection AST nodes instead of opaque HDL strings,
- those structural connection expressions should be allowed to grow toward durable connectivity forms such as references, literals, slices/part-selects, concatenations, member/index access, and bounded open/default associations where those remain portable across supported backends,
- and when a connection gets too backend-specific or too awkward to keep elegant there, the healthier rule is to normalize it earlier into helper nets or auxiliary assignments and then bind the child pin to that normalized structural value,
- one important implementation distinction is that the current `FSM::Pipeline::HDLGenerator` is still a combined compiler driver, lowering coordinator, and emitter, so any direct `Intent HIR` or `Lowered RTL IR` queries there should be treated as transitional coordinator cleanup rather than the desired final backend boundary,
- and the convergence target is to split that combined role so orchestration may still see all three forward IRs while the pure HDL backend/emitter mostly walks `Structural RTL IR` as the last IR before HDL text,
- and there should be no public-compatibility pretext holding that breakdown back: FSMGen is not a published public contract yet, so preserving today’s accidental monolith is less important than converging to the strongest architecture, with any internal shim accepted only when it is clearly temporary and moving toward that split,
- `Flat IR` is likely optional in the forward path at first but valuable later for deeper optimization/analysis, while it is much more likely to be necessary in the reverse path because many hardware facts only become obvious after elaboration/flattening,
- and the reverse path therefore needs one extra semantic stage beyond the forward path: a recovered-intent layer that can preserve confidence, ambiguity, and residue instead of pretending that inference is the same thing as authored intent.

Shared-middle rule:
- do not build two completely separate semantic worlds for forward compilation and reverse recovery,
- keep the parse/surface trees separate (`.fsm` AST vs HDL CST/AST),
- keep the early HDL-specific semantic layer separate where the source languages genuinely differ,
- but aim to share the semantic middle:
  - one backend-independent `Intent HIR` that represents `.fsm`-level design intent,
  - one backend-independent `Lowered RTL IR` for normalized registers/drivers/shared-datapath structure and other lowered semantic facts,
  - one backend-independent `Structural RTL IR` / connectivity layer for explicit ports/nets/instances/pin bindings and full top/child wiring once that layer is extracted,
  - and possibly one shared `Flat IR` plus one general provenance model if they prove broad enough,
- while keeping recovery-specific residue/confidence reporting separate from authored-source semantics.

Refactoring implication:
- the current Perl runtime already has proto-HIR/proto-lowered-IR behavior spread across modules such as `HDLGenerator`, `FSMGenFull`, composition planning, and `FlattenedDT`,
- so the future goal is not to invent semantics from nothing but to make those semantic layers explicit, shareable, and backend-independent instead of continuing to rediscover them ad hoc inside generation code.

Advanced synthesizable targets worth considering later, not rejecting upfront:
- macro/preprocessor-heavy RTL after preprocessing with provenance retained,
- generate-heavy RTL after elaboration,
- richer composition hierarchies beyond the first bounded recovery slice,
- hand-optimized logic where some regions may recover as FSM/datapath intent and other regions remain opaque,
- and bounded pragma/attribute recovery where those annotations represent durable design intent rather than backend-specific implementation residue.

Prerequisite:
- the forward `.fsm` contract, diagnostics contract, and embedding/result surfaces should already be stable enough that HDL import targets a known IR instead of a moving language boundary.

### H4. TRM / protocol-spec intent capture
Long-term goal:
- add a bounded spec-to-`.fsm` lane that can capture executable design intent from technical reference manuals, protocol specifications, and normalized `Markdown` source material.

Intent:
- treat prose/specification documents as a source of recoverable behavioral contract, role structure, timing rules, and invariants,
- and treat spec-to-`.fsm` as intent capture rather than HDL import or exact natural-language inversion.

Terminology stance:
- prefer the term `intent capture` over `intent synthesis` for this lane,
- because the source is prose/spec text and the output should stay explicit about ambiguity, residue, and required human confirmation.

Primary scope boundary:
- begin with bounded protocol and interface specifications such as `APB`, `AMBA`, `AXI`, `I2C`, and `I2S`,
- rather than attempting arbitrary prose-heavy hardware manuals all at once.

Likely output shape:
- requester / initiator role `.fsm` roots,
- completer / target role `.fsm` roots,
- protocol checker / monitor assets,
- reusable assertions and invariants,
- and optional `.fsm` composition or testbench harnesses that exercise those roles together.

Preferred execution order:
- begin with design/probe work and bounded capture experiments before promoting this to a primary implementation lane,
- treat `PDF -> .md` normalization as a separate pre-step rather than burying document cleanup inside the capture engine,
- keep serious implementation behind the active forward/backend cleanup and language-contract stabilization so this lane targets steadier IR and reporting surfaces,
- and let successful captured protocols later seed the future reusable-library lane rather than creating a separate privileged asset world.

Preferred working method:
- start from normalized `Markdown`, not directly from the source `PDF`,
- work actor-first instead of protocol-as-a-monolith,
- build a protocol dossier, actor catalog, actor sheet per actor, assertion ledger, abstraction/boundedness log, FSM mapping sheet, and validation log,
- keep source facts, derived machine rules, local design decisions, and explicit abstractions separate,
- define actor interfaces plus invariants/contracts/gates in plain English before emitting `.fsm`,
- and treat early imported fixtures such as the APB requester/completer/top and AMBA requester examples as seed corpus, not as proof that the general capture lane is already solved.

Required behavior:
- emit captured `.fsm` artifacts plus a capture report,
- distinguish confidently captured intent from heuristic inference and unresolved ambiguity,
- and never present ambiguous prose as if it had been recovered with implementation-grade certainty.

Expected technical pipeline:
- normalize `PDF` or other source documents into structured `Markdown`,
- build a normalized spec IR over roles, transactions, timing rules, fields, and invariants,
- recover protocol role models and reusable behavioral rules from that IR,
- project those recovered semantics into `.fsm` roots plus optional composition/testbench harnesses,
- and emit a capture report alongside the generated sources.

Relationship to other horizon lanes:
- keep this lane distinct from HDL import / intent recovery even if both eventually share middle-layer semantic IRs,
- because the source evidence, ambiguity model, and validation story are materially different,
- and use the same honesty rule in both directions: report residue explicitly instead of pretending elegance where the source does not justify it.

## Current intent
The active immediate lane is `R11`.

The first honest `R11` slices are now:
1. keep widening convention-first composition only where the child-side evidence is still deterministic,
2. let explicit local overrides stay precise without forcing whole-interface restatement,
3. keep pushing shared-datapath and reusable-module feature slices before returning to contract-hardening-only work,
4. keep `R8` paused except when a feature slice necessarily touches a still-unlocked boundary.
- Forward-IR note: `StructuralRTLIR` actual-connection nodes are now wider than
  plain signal references; the current bounded family includes indexed and
  sliced signal forms, while keeping rendering deliberately scoped to the
  current Verilog-family backend until broader backend support is designed.
- Forward-IR note: that bounded `StructuralRTLIR` actual-connection family now
  also includes concatenation over nested operands, so the structural emitter
  is beginning to walk a richer backend-neutral binding AST instead of only
  leaf-like reference nodes.
- Forward-IR note: those already-shipped bounded `bit_select`, `slice`, and
  `concat` nodes now also render honestly through the current VHDL helper path,
  including `downto`/`to` slice direction and `&` concatenation, so the
  structural AST is a bit more genuinely cross-backend instead of only looking
  portable on paper.
- Forward-IR note: the structural connection-expression layer now also needs a
  recursive dependency view, because once bindings can be slices or concats the
  rest of the pipeline can no longer safely ask only for one flat bound signal
  name.
- Forward-IR note: the structural connection-expression layer now also needs a
  bounded literal family, because real top/child connectivity eventually needs
  honest constant actuals and tie-offs without collapsing back into raw
  backend-specific syntax strings.
- Forward-IR note: that bounded literal family now also renders honestly
  through the current VHDL helper path, so the structural AST is a bit more
  genuinely cross-backend for constant/tie-off actuals instead of only being
  rendered for the Verilog family.
- Forward-IR note: the structural connection-expression layer now also needs an
  explicit `open` actual form, because “leave this formal unconnected” is real
  structural semantics and should not be represented as a backend-specific text
  escape hatch.
- Forward-IR note: the structural connection-expression layer has now started
  the bounded member/field-access lane too, with a first `member_access` node
  over one source expression plus one identifier-like member name, rendered
  through the current SystemVerilog/VHDL helper path while the broader
  aggregate/backend story stays deliberately bounded.
- Forward-IR note: the structural connection-expression layer has now also
  started the fixed-size array/index-access lane, with a first `index_access`
  node over one source expression plus one numeric index, rendered through the
  current SystemVerilog/Verilog/VHDL helper path while the broader aggregate
  and type story stays deliberately bounded.
- Forward-IR note: downstream structural consumers are now also starting to
  split “true flat leaf carrier” from “broader dependency set,” so compatibility
  fields like `bound_signal` do not silently misclassify richer expressions such
  as `member_access` or `index_access`.
- Forward-IR note: shared-datapath contributor and peer-input metadata now
  also preserve the actual typed binding expression through
  `bound_connection_expr`, so later consumers can reuse real structural AST
  nodes instead of reconstructing binding shape from names-only summaries.
- Forward-IR note: shared-datapath planning itself now also prefers that typed
  `bound_connection_expr` surface when it needs a true flat leaf-carrier name,
  so compatibility mirrors no longer outrank the structural AST in those
  carrier/top-output/peer-input decisions.
- Forward-IR note: non-quiet CLI shared-datapath summaries now also consume
  `bound_connection_expr` for peer-read binding display, so that structural
  AST surface is no longer trapped purely inside planning metadata.
- Forward-IR note: that same non-quiet CLI shared-datapath section now also
  consumes `bound_connection_expr` for the main contributor summary line, so
  the first candidate line itself no longer collapses typed contributor
  bindings back to endpoint-only text.
- Forward-IR note: the structural helper layer now also owns one reusable
  `binding_signal_summary` projection over flat leaf carrier name, broader
  dependency names, and cloned typed binding expression payload, so
  `HDLGenerator` consumers no longer need to rebuild that structural summary
  ad hoc.
- Forward-IR note: that same structural helper layer now also owns the
  reusable “summary entry to true flat leaf carrier” rule through
  `binding_signal_summary_leaf_signal`, so shared-datapath planning no longer
  needs a pipeline-local copy of that typed-summary leaf-selection logic.
- Forward-IR note: that same structural helper layer now also owns the
  reusable “summary entry to rendered binding text” rule through
  `binding_signal_summary_text`, so CLI/reporting consumers no longer need to
  keep their own local `bound_connection_expr`-first rendering copy.
- Forward-IR note: that same structural helper layer now also owns the
  normalized cloned summary-export payload through
  `binding_signal_summary_metadata`, so shared-datapath contributor and
  peer-read metadata no longer need to hand-copy `bound_signal`,
  `bound_signals`, and `bound_connection_expr` in `HDLGenerator`.
- Forward-IR note: that same structural helper layer now also owns the
  reusable “binding list to per-port summary index” rule through
  `binding_signal_summaries_by_port`, so composition system-signal inference
  and shared-datapath candidate assembly no longer need to rebuild that same
  local summary map inside `HDLGenerator`.
- Forward-IR note: `StructuralRTLIR` itself now also owns explicit child
  endpoint-query helpers through `interface_endpoint`,
  `interface_signal_endpoints`, and `interface_signal_endpoint_groups`, so
  provenance/reporting consumers no longer need to hand-walk nested
  `instances` / `interface_ports` arrays for those endpoint-family queries.
- Forward-IR note: that same `StructuralRTLIR` surface now also owns top-port
  lookup and “resolved links touching endpoint X” queries through `top_port`
  and `resolved_links_touching`, so provenance/override consumers no longer
  need to rebuild those small structural queries in `HDLGenerator`.
- Forward-IR note: `IntentHIR` now also owns semantic composition-child lookup
  by instance through `composition_children_by_instance` and
  `composition_child`, so provenance/shared-datapath consumers no longer need
  to rebuild that same semantic child index locally in `HDLGenerator`.
- Forward-IR note: `LoweredRTLIR` now also owns normalized output-drive-family
  lookup by signal through `output_drive_families_from_input`,
  `output_drive_families_by_signal`, and `output_drive_family`, so shared
  datapath and module-output-drive consumers no longer need to rebuild that
  same lowered signal map locally in `HDLGenerator`.
- Forward-IR note: `LoweredRTLIR` now also owns grouped standalone-DT
  multi-drive target lookup through `standalone_dt_multi_drive_targets_from_input`,
  `standalone_dt_multi_drive_targets_by_signal`, and
  `standalone_dt_multi_drive_target`, so standalone-DT assertion/export
  consumers no longer need to reread that same lowered target surface locally
  in `HDLGenerator`.
- Forward-IR note: `IntentHIR` now also owns semantic system-contract and
  signal-analysis boundary lookup through `system_contract_from_input` and
  `signal_analysis_entries_from_input`, so realized-child interface fallback
  no longer needs to reread that same semantic boundary data directly from raw
  `module_info` fields in `HDLGenerator`.
- Forward-IR note: the saved convergence target is still `IntentHIR ->
  LoweredRTLIR -> StructuralRTLIR -> backend emission`, but the current
  `HDLGenerator` remains a combined driver/lowering/emitter module, so direct
  semantic or lowered IR queries there are still acceptable as transitional
  coordinator cleanup while the longer-term split should leave pure HDL
  emission mostly walking `StructuralRTLIR`.
- Forward-IR note: the saved policy is now also explicit that no unpublished
  “compatibility” concern should preserve the current monolith; any internal
  shim is acceptable only as a clearly transitional migration aid toward a
  split compiler/orchestrator plus backend-emitter architecture.
- Forward-IR note: the first real backend-emitter extraction slice is now
  active too: composition-top structural HDL text emission now lives in
  `FSM::Backend::VerilogFamily::StructuralRTLIREmitter`, so
  `HDLGenerator` no longer owns that direct structural text-rendering step.
- Forward-IR note: the matching pipeline-side split is now active too:
  composition-top `StructuralRTLIR` construction and hash/object coercion now
  live in `FSM::IR::StructuralRTLIRBuilder`, so `HDLGenerator` no longer owns
  that structural assembly/coercion code directly either.
- Forward-IR note: the next composition-top semantic-builder split is now
  active too: bounded composition-top `IntentHIR` construction now lives in
  `FSM::IR::IntentHIRBuilder`, so `HDLGenerator` no longer owns that semantic
  assembly path directly either; the next matching forward-IR seam is now the
  lowered-builder split rather than one more inline composition-top HIR helper.
- Forward-IR note: that matching lowered-builder split is now active too:
  bounded composition-top `LoweredRTLIR` construction now lives in
  `FSM::IR::LoweredRTLIRBuilder`, so `HDLGenerator` no longer owns that
  lowered assembly path directly either; the next honest seam is now a broader
  coordinator/direct-root split rather than another inline composition-top IR
  builder.
- Package-breakdown note: the remaining bounded composition generation
  orchestration is now active in its own package too:
  `FSM::Composition::GenerationOrchestrator` now owns composition plan-to-result
  assembly, so `HDLGenerator` no longer keeps the whole composition-top result
  cluster inline; the next honest breakdown seam is now on the broader
  non-composition/direct-root coordinator path.
- Package-breakdown note: that direct-root counterpart is now active too:
  `FSM::Pipeline::DirectGenerationOrchestrator` now owns the bounded
  non-composition source-to-result path, so `HDLGenerator` no longer keeps the
  whole direct-root result-assembly cluster inline either; the next honest
  seam is now the direct-path builder/backend residue or a broader facade split
  for `HDLGenerator`.
- Package-breakdown note: the broader source/file dispatch counterpart is now
  active too: `FSM::Pipeline::SourceGenerationOrchestrator` now owns top-level
  parse/classify/dispatch orchestration plus the surrounding extension-hook
  and final-result finalization flow, so `HDLGenerator` no longer keeps the
  whole source-level coordinator inline either; the next honest seam is now
  the thinner remaining `HDLGenerator` facade residue or deeper cleanup under
  the older backend family.
- Package-breakdown note: the next generated-module metadata-owner split is
  now active too: `FSM::Pipeline::GeneratedModuleInfoBuilder` now owns the
  bounded generated-module `module_info` family, including lowered enrichment
  and normalized output-drive-family / grouped-target queries, so
  `HDLGenerator`, `DirectGenerationOrchestrator`, and
  `GeneratedChildRealizer` no longer keep that metadata family inline either;
  the next honest seam is now the thinner remaining `HDLGenerator`
  facade/helper residue or deeper cleanup under the older backend family.
- Forward-IR note: the direct-root semantic-builder counterpart is now active
  too: bounded direct-root `IntentHIR` construction now also lives in
  `FSM::IR::IntentHIRBuilder`, so `HDLGenerator` no longer owns direct-root
  signal-analysis grouping, direction inference, or standalone-DT enable-family
  assembly inline either; the next honest seam is now the remaining direct-path
  lowered/structural builder residue or a broader facade split rather than one
  more direct semantic helper.
- Forward-IR note: the next direct-root lowered-builder counterpart is now
  active too: bounded direct-root `LoweredRTLIR` construction now also lives in
  `FSM::IR::LoweredRTLIRBuilder`, so `HDLGenerator` no longer owns direct-root
  output-drive-family or standalone-DT lowered-target assembly inline either;
  the next honest seam is now the remaining direct-path structural builder
  residue or a broader facade split rather than one more direct lowered helper.
- Forward-IR note: the matching direct-root structural-builder counterpart is
  now active too: bounded direct-root `StructuralRTLIR` construction now also
  lives in `FSM::IR::StructuralRTLIRBuilder`, so `HDLGenerator` no longer owns
  direct-root module-boundary and implicit-system-port structural assembly
  inline either; the next honest seam is now the remaining direct-path backend
  residue or a broader facade split rather than one more direct structural
  helper.
- Forward-IR note: that next direct-path backend-owner split is now active
  too: bounded direct generated-module backend execution, backend statistics,
  and standalone-DT assertion postprocessing now live in
  `FSM::Backend::GeneratedModuleEmitter`, so `HDLGenerator`,
  `DirectGenerationOrchestrator`, and `GeneratedChildRealizer` no longer keep
  that backend family inline either; the next honest seam is now a broader
  `HDLGenerator` facade/coordinator split or deeper cleanup under the older
  `FlattenedDT` / `EnableGraph` backend family.
- Forward-IR note: a new composition-side builder extraction is now active
  too: realized generated-child interface port construction plus the shared
  interface-type normalization and system-port ordering rules now live in
  `FSM::Composition::InterfacePortBuilder`, so `HDLGenerator` no longer owns
  that child-boundary projection logic directly either.
- Forward-IR note: the first real composition-lane plan split is now active
  too: bounded single-child passthrough `C1` planning now lives in
  `FSM::Composition::C1PlanBuilder`, so `HDLGenerator` no longer owns that
  lane’s explicit passthrough validation, implicit top-port inference, or
  direct passthrough link/binding assembly.
- Forward-IR note: another real composition-plan family split is now active
  too: bounded declared connect-by-name `C4` link construction now lives in
  `FSM::Composition::DeclaredByNameLinkBuilder`, so `HDLGenerator` no longer
  owns that family’s system-port exclusion, same-name endpoint matching,
  input fanout, unique-output selection, or direction/width validation.
- Forward-IR note: `StructuralRTLIR` now also owns composition-top port
  metadata projection through `port_metadata` and `port_metadata_from_input`,
  so top-level `signals` / `signal_names` / grouped input-output signal
  analysis no longer need one more pipeline-local reconstruction helper in
  `HDLGenerator`.
- Forward-IR note: active forward-IR packages now also carry an explicit POD
  standard: package-level POD near the top of the file plus routine-level POD
  for owned functions, so the package split remains reviewable while
  `HDLGenerator` is still being decomposed.
- Forward-IR note: the saved naming direction is now also explicit: keep
  `fsmgen` as the product/tool identity for historical reasons, but treat the
  internal `FSM::...` umbrella namespace as a deferred late-roadmap cleanup
  candidate once the package split is much closer to stable. That rename is not
  urgent and should wait until the roadmap is nearly complete.
- Forward-IR note: another real composition-planning family split is now
  active too: the bounded inferred same-name convention links used by the
  active `C2`/`C3` lanes now live in
  `FSM::Composition::SameNameLinkBuilder`, so `HDLGenerator` no longer owns
  that family’s inferred top-input fanout, inferred top-output selection, or
  inferred internal same-name carrier rules directly.
- Forward-IR note: another real composition-planning family split is now
  active too: generic explicit-link linked-plan assembly for the active
  `C2`/`C3`/`C4` lanes now lives in `FSM::Composition::LinkedPlanBuilder`, so
  `HDLGenerator` no longer owns that family’s system auto-wiring, endpoint
  resolution, role/width validation, deterministic carrier-net allocation, or
  realized-child rebinding logic directly.
- Forward-IR note: another real composition-planning family split is now
  active too: inferred multi-child top-port projection now lives in
  `FSM::Composition::TopPortInferenceBuilder`, so `HDLGenerator` no longer
  owns explicit-toplink top-port inference or undeclared same-name top-input
  and top-output inference directly.
- Forward-IR note: another real composition-support family split is now
  active too: shared-datapath naming, generated-child source-export metadata,
  assertion metadata/rendering, and runtime plan augmentation now live in
  `FSM::Composition::SharedDatapathSupport`, so `HDLGenerator` no longer owns
  that shared-datapath support family directly.
- Forward-IR note: another real composition-reporting family split is now
  active too: composition provenance report assembly plus override/block event
  detection and endpoint-context labeling now live in
  `FSM::Composition::ProvenanceReportBuilder`, so `HDLGenerator` no longer
  owns that reporting family’s structural/intent projection logic directly.
- Forward-IR note: another real composition result-surface split is now
  active too: unified realized-child exports plus the narrower generated-child
  and standalone-DT export views now live in
  `FSM::Composition::ChildExportBuilder`, so `HDLGenerator` no longer owns
  that child-export/result-assembly family directly.
- Forward-IR note: another real composition failure/result split is now
  active too: blocked composition summary extraction now lives in
  `FSM::Composition::FailureReportBuilder` and success-path composition
  `module_info` / `statistics` assembly now lives in
  `FSM::Composition::ResultMetadataBuilder`, so `HDLGenerator` no longer owns
  those result-shaping families directly either.
- Forward-IR note: another real composition shared-datapath split is now
  active too: candidate discovery plus normalized contributor/peer-read/
  drive-intent/aggregate-family metadata now live in
  `FSM::Composition::SharedDatapathCandidateBuilder`, so `HDLGenerator` no
  longer owns that shared-datapath candidate assembly family directly.
- Forward-IR note: another real child/source-orchestration split is now
  active too: `?fsmc` / `?dtc` realization plus embedded/external
  generated-child source loading now live in
  `FSM::Composition::GeneratedChildRealizer`, so `HDLGenerator` no longer owns
  that generated-child realization/source-loading pocket directly.
- Forward-IR note: another real external-RTL child split is now active too:
  `?rtl` child realization into normalized `RealizedInstance` carriers now
  lives in `FSM::Composition::RTLChildRealizer`, while
  `FSM::Composition::RTLInterfaceLoader` stays the narrower owner of `.rtlif`
  metadata loading and validation, so `HDLGenerator` no longer owns that
  external-RTL child realization pocket directly either.
- Forward-IR note: another real composition-plan split is now active too:
  child realization dispatch, `?ports` shape gating, top-port inference
  handoff, lane selection, and shared-datapath plan augmentation now live in
  `FSM::Composition::PlanBuilder`, so `HDLGenerator` no longer owns that
  composition-plan orchestration cluster directly either.
- Forward-IR note: another real synthesis/backend split is now active too:
  module declaration planning, internal signal declaration planning, state
  register planning, and effective system-contract lookup now live in
  `FSM::Synthesis::EnableGraph::ModulePlanningSupport`, so `EnableGraph` no
  longer owns that module/state/declaration planning family directly.
- Forward-IR note: the matching assignment-analysis/backend-emission support
  split is now active too: unified assignment analysis, RHS grouping,
  mux-plan construction, driven-signal discovery, reset/default/width
  recovery, and delayed-pulse / flop / combinational assignment emission now
  live in `FSM::Synthesis::EnableGraph::AssignmentSupport`, so `EnableGraph`
  no longer owns that bounded assignment/mux family directly either.
- Forward-IR note: the matching enable-family support split is now active
  too: top-level state/DT enable initialization, WEN/EN prescan tracking,
  top-level enable emission, and unified DT/LHS WEN/EN emission now live in
  `FSM::Synthesis::EnableGraph::EnableSupport`, so `EnableGraph` no longer
  owns that bounded enable family directly either.
- Forward-IR note: the matching AST capture/conversion support split is now
  active too: condition-stack normalization, assignment/transition capture,
  test-selector conversion, and AST signal-name extraction now live in
  `FSM::Synthesis::EnableGraph::CaptureSupport`, so `EnableGraph` no longer
  owns that bounded capture/conversion family directly either.
- Forward-IR note: the matching AST rendering/classification support split is
  now active too: AST-to-SystemVerilog rendering, single-bit operand-aware
  operator selection, factorizable-operator discovery, and
  arithmetic/logical/factorization classification now live in
  `FSM::Synthesis::EnableGraph::ASTSupport`, so `EnableGraph` no longer owns
  that bounded rendering/classification family directly either.
- Forward-IR note: the matching signal/intermediate support split is now
  active too: AST-based intermediate naming, reset/default lookup, direct
  intermediate-dependency extraction, signal/intermediate classification,
  backend-safe signal-name cleanup, and RHS-based enable naming now live in
  `FSM::Synthesis::EnableGraph::SignalSupport`, so `EnableGraph` no longer
  owns that remaining signal/intermediate family directly either and is now a
  thin synthesis-context shell.
- Forward-IR note: the matching factorization-policy support split is now
  active too: logical-operation counting, first-pass AST feed preparation,
  second-pass AST feed eligibility, and high-count logical-operation policy
  now live in `FSM::Synthesis::EnableGraph::FactorizationPolicySupport`, so
  `FSM::Synthesis::EnableGraph::FactorizationSupport` now narrows to
  substitution synchronization and live-usage evidence instead of owning the
  whole factorization family.
- Forward-IR note: the paired live direct consolidated intermediate stage-6
  generation family now also has an explicit owner in
  `FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateStageSupport`,
  so `FlattenedDT::Orchestrator` no longer hand-composes stage preparation
  plus rendering inline and the older
  `FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateGenerationSupport`
  now survives only as a compatibility shell over that real live owner.
- Forward-IR note: the older direct post-flattening SystemVerilog assembly
  package in
  `FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPipelineSupport`
  now survives only as a compatibility shell, and
  `FlattenedDT::Orchestrator` now composes structural-prelude generation,
  enable-oriented preparation, consolidated intermediate stage generation,
  and tail closeout directly after flattening.
- Forward-IR note: the older direct pre-stage SystemVerilog generation-
  prelude package in
  `FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPreludeSupport`
  now survives only as a compatibility shell, and
  `FlattenedDT::Orchestrator` now composes
  `GenerationStructuralPreludeSupport` plus
  `GenerationEnablePreparationSupport` directly before consolidated
  intermediate generation.
- Forward-IR note: the paired live direct pre-stage SystemVerilog
  enable-oriented preparation family now also has an explicit owner in
  `FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationEnablePreparationSupport`,
  so the live direct backend no longer depends on the older generation-
  prelude shell to reach enable-condition generation or the extracted
  prescan-preparation composition before consolidated intermediate generation.
- Forward-IR note: the paired live direct pre-stage SystemVerilog
  prescan-preparation family now also has an explicit owner in
  `FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPrescanPreparationSupport`,
  so `GenerationEnablePreparationSupport` no longer owns logical-operation
  counting and WEN/EN prescan inline after enable-condition emission.
- Forward-IR note: the paired live direct pre-stage SystemVerilog structural
  prelude family now also has an explicit owner in
  `FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationStructuralPreludeSupport`,
  so the live direct backend now reaches
  header/module/state/internal-declaration assembly directly instead of
  routing through the older generation-prelude shell.
- Forward-IR note: the paired live direct post-stage SystemVerilog generation
  tail family now also has an explicit owner in
  `FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationTailSupport`,
  so the older generation-pipeline shell no longer owns unified WEN/EN
  emission, signal-assignment emission, and module closeout inline after
  consolidated intermediate generation.
- Forward-IR note: the paired live direct recursive decision-tree flattening
  family now also has an explicit owner in
  `FSM::HDL::FlattenedDT::DecisionTreeFlatteningSupport`, so
  `FlattenedDT::Orchestrator` no longer owns recursive regular-state and
  standalone-DT flattening inline before direct backend text assembly.
