# FSMGen Roadmap v2

This is the detailed companion to [ROADMAP_STATUS.md](ROADMAP_STATUS.md).

Use this file for:
- the detailed post-`R0`..`R7` roadmap shape,
- sequencing and dependency rationale,
- and the concrete intent behind the active `R8+` workstreams.

Use [ROADMAP_STATUS.md](ROADMAP_STATUS.md) for:
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

The remaining work is no longer "finish the refactor."
It is "turn the modernized tool into a stricter, more explicit, more trustworthy language/tool contract."

That is what roadmap v2 is for.

## v2 principles
- Prefer explicit language contracts over implicit parser acceptance.
- Distinguish "implemented" from "supported".
- Make diagnostics part of the product, not just a debugging aid.
- Grow surface area only when semantics are crisp and regression-backed.
- Keep composition and extension growth deliberate rather than legacy-compatible by default.
- Alternate deliberately between consolidation slices and visibly user-facing capability slices; do not let long cleanup-only streaks become the default unless cleanup is still the clear blocker.

## Current package-breakdown note
- The bounded source-frontend family now has an explicit owner in [perl/FSM/Pipeline/SourceFrontend.pm](perl/FSM/Pipeline/SourceFrontend.pm), covering Lispish file parsing, top-level source-kind classification, typed composition parsing, and semantic FSM/DT module creation.
- That means [perl/FSM/Pipeline/SourceGenerationOrchestrator.pm](perl/FSM/Pipeline/SourceGenerationOrchestrator.pm), [perl/FSM/Pipeline/DirectGenerationOrchestrator.pm](perl/FSM/Pipeline/DirectGenerationOrchestrator.pm), [perl/FSM/Composition/GenerationOrchestrator.pm](perl/FSM/Composition/GenerationOrchestrator.pm), and [perl/FSM/Composition/GeneratedChildRealizer.pm](perl/FSM/Composition/GeneratedChildRealizer.pm) no longer need `HDLGenerator` to keep that frontend family inline.
- The old composition failure-summary and provenance/override/block label helper residue is now also gone from [perl/FSM/Pipeline/HDLGenerator.pm](perl/FSM/Pipeline/HDLGenerator.pm), because [bin/fsmgen](bin/fsmgen) and the direct failure-summary regression coverage now call the dedicated builder owners directly.
- The old direct generated-module helper residue is now also gone from [perl/FSM/Pipeline/HDLGenerator.pm](perl/FSM/Pipeline/HDLGenerator.pm): direct-root/generated-child callers and the direct-owner tests now talk to [perl/FSM/IR/IntentHIRBuilder.pm](perl/FSM/IR/IntentHIRBuilder.pm), [perl/FSM/IR/StructuralRTLIRBuilder.pm](perl/FSM/IR/StructuralRTLIRBuilder.pm), [perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm](perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm), [perl/FSM/Backend/GeneratedModuleEmitter.pm](perl/FSM/Backend/GeneratedModuleEmitter.pm), and [perl/FSM/Pipeline/SourceFrontend.pm](perl/FSM/Pipeline/SourceFrontend.pm) directly.
- The remaining source-frontend wrapper residue is now also gone from [perl/FSM/Pipeline/HDLGenerator.pm](perl/FSM/Pipeline/HDLGenerator.pm): test coverage and internal callers now ask [perl/FSM/Pipeline/SourceFrontend.pm](perl/FSM/Pipeline/SourceFrontend.pm) directly.
- That leaves `HDLGenerator` at the intended thin public facade shape: shared pipeline configuration plus `generate_hdl_from_file(...)`.
- The first bounded direct SystemVerilog scaffold family now also has an explicit owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ScaffoldEmitter.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ScaffoldEmitter.pm), covering header, module declaration, state encoding, and state register rendering.
- The internal declaration family now also has an explicit owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/InternalDeclarationEmitter.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/InternalDeclarationEmitter.pm), covering bounded `reg` declaration rendering from the enable-graph declaration plan.
- The direct first-pass AST-factorization pipeline now also has an explicit owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GlobalFactorizationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GlobalFactorizationSupport.pm), while [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ASTFactorizationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ASTFactorizationSupport.pm) is now narrowed to substituted-AST lookup plus the legacy direct intermediate-signal rendering helper, and the old [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm) package is now gone from the live direct backend path.
- The direct SystemVerilog intermediate runtime-recovery family now also has an explicit owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalRecoverySupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalRecoverySupport.pm), covering runtime AST lookup, rendered-expression caching, and dependency recovery for the direct intermediate-signal path.
- The paired direct SystemVerilog intermediate width family now also has an explicit owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm), covering width normalization and recursive width inference for that same direct intermediate-signal path.
- The paired direct SystemVerilog intermediate filter-heuristic family now also has an explicit owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalFilterPolicySupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalFilterPolicySupport.pm), covering AST-aware keep/filter heuristics, runtime-AST-miss live-usage fallback, and the small AST-shape predicates used by that decision path.
- The direct consolidated-intermediate selection owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSelectionSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSelectionSupport.pm) now owns the live AST-first keep/filter dispatch over the extracted recovery and filter-policy owners directly, and the older [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm) package now survives only as a compatibility-shell test surface outside the live backend path.
- The direct SystemVerilog consolidated intermediate collection family now also has an explicit owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSupport.pm), covering AST-factorized, pre-scanned, and FSMGen-parsed intermediate-signal collection for the direct backend block that appears before unified WEN/EN generation.
- The paired direct SystemVerilog consolidated intermediate normalization family now also has an explicit owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateNormalizationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateNormalizationSupport.pm), covering runtime AST, width, dependency, rendered-expression, and live-usage normalization over that same merged signal set before selection, planning, and emission.
- The paired direct SystemVerilog consolidated intermediate classification family now also has an explicit owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateClassificationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateClassificationSupport.pm), covering the initial AST-first keep/filter partition over that normalized direct backend set before dependency rescue and ordering.
- The direct SystemVerilog consolidated intermediate selection family now also has an explicit owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSelectionSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSelectionSupport.pm), covering dependency-aware rescue plus final kept/filtered summary projection for the normalized and initially classified direct backend set that appears before unified WEN/EN generation.
- The paired direct SystemVerilog consolidated intermediate dependency family now also has an explicit owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateDependencySupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateDependencySupport.pm), covering dependency-map construction plus dependency-safe emission ordering for that same direct backend block.
- The paired direct SystemVerilog consolidated intermediate planning family in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePlanningSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePlanningSupport.pm) is now narrowed to overall plan composition over the extracted selection and dependency owners.
- The older direct SystemVerilog consolidated intermediate block-preparation package in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateBlockSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateBlockSupport.pm) now survives only as a directly testable compatibility shell outside the live backend path.
- That older block-preparation compatibility shell now delegates directly to the live [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStagePreparationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStagePreparationSupport.pm) owner, leaving no detached collection/planning/projection fallback copy in the shell.
- The paired direct SystemVerilog prepared consolidated intermediate block family now also has an explicit owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePreparedBlockSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePreparedBlockSupport.pm), covering prepared block-contract projection from the collected normalized set plus the composed plan.
- The paired direct SystemVerilog consolidated intermediate stage-preparation family now also has an explicit owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStagePreparationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStagePreparationSupport.pm), covering live prepared-block reconstruction from the extracted collection, planning, and prepared-block projection owners.
- The paired direct SystemVerilog consolidated intermediate rendering family now also has an explicit owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateRenderingSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateRenderingSupport.pm), covering final prepared-block rendering over the extracted declaration and assignment owners.
- The older direct SystemVerilog consolidated intermediate emitter compatibility shell now has its focused test pinned to the live rendering owner rather than to a hand-rebuilt scaffold/declaration/direct-prefix sequence.
- The direct SystemVerilog consolidated intermediate assignment family now also has an explicit owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateAssignmentSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateAssignmentSupport.pm), covering prepared assign emission from that block contract.
- The direct SystemVerilog consolidated intermediate declaration family now also has an explicit owner in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateDeclarationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateDeclarationSupport.pm), covering prepared wire-declaration rendering from that same block contract.
- The live direct consolidated-intermediate stage handoff is now owned by [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStageSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStageSupport.pm), composing prescan preparation, stage preparation, pre-generation validation, and rendering, while the older [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm) package now survives only as a compatibility shell outside the live backend path.
- The older direct SystemVerilog consolidated intermediate-signal emission package in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm) now survives only as a directly testable compatibility shell outside the live backend path.
- The iterative post-substitution factorization path now also has an explicit loop-state owner in [perl/FSM/HDL/Factorization/Fixpoint/LoopStateSupport.pm](perl/FSM/HDL/Factorization/Fixpoint/LoopStateSupport.pm), covering aggregate loop-state creation, accepted-pass outcome application, and final termination/result normalization.
- The iterative post-substitution factorization path now also has an explicit single-pass execution owner in [perl/FSM/HDL/Factorization/Fixpoint/PassExecutionSupport.pm](perl/FSM/HDL/Factorization/Fixpoint/PassExecutionSupport.pm), covering per-pass factorizer construction, repeated-signature short-circuit detection, and one-pass substitution/update execution.
- The paired per-pass helper owner in [perl/FSM/HDL/Factorization/Fixpoint/PassSupport.pm](perl/FSM/HDL/Factorization/Fixpoint/PassSupport.pm) continues to cover primary intermediate lookup, deterministic pass signatures, second-pass name-collision recovery, and new-signal projection/debugging, while the paired [perl/FSM/HDL/Factorization/Fixpoint.pm](perl/FSM/HDL/Factorization/Fixpoint.pm) package is now narrowed further to pass scheduling and top-level coordination.
- The synthesis-side intermediate-signal registry and dependency-recovery family now also has an explicit owner in [perl/FSM/Synthesis/EnableGraph/IntermediateSignalSupport.pm](perl/FSM/Synthesis/EnableGraph/IntermediateSignalSupport.pm), and the direct backend plus synthesis callers now ask that owner directly instead of keeping that whole pocket inline in [perl/FSM/Synthesis/EnableGraph.pm](perl/FSM/Synthesis/EnableGraph.pm).
- The synthesis-side factorization-analysis and substitution/live-usage evidence family now also has an explicit owner in [perl/FSM/Synthesis/EnableGraph/FactorizationSupport.pm](perl/FSM/Synthesis/EnableGraph/FactorizationSupport.pm), and the direct backend plus fixpoint callers now ask that owner directly instead of keeping that AST-factorization bookkeeping inline in [perl/FSM/Synthesis/EnableGraph.pm](perl/FSM/Synthesis/EnableGraph.pm).
- The new direct owner lock in [t/203-enable-graph-factorization-support.t](t/203-enable-graph-factorization-support.t) also records one important contract nuance: in the prepared direct backend context, some synthesized factorization intermediates can be live by substitution evidence only rather than by final owner-side expression presence, so this owner is about analysis and synchronization evidence, not fake final-expression ownership.
- The next honest `R11` seam is now no longer the aggregate loop-state contract in [perl/FSM/HDL/Factorization/Fixpoint.pm](perl/FSM/HDL/Factorization/Fixpoint.pm), the collection/normalization split inside the direct consolidated backend path, the initial AST-first classification split there, the dependency-map/ordering split there, the old direct intermediate dispatcher shell, the old direct consolidated block shell, the old direct consolidated emitter shell, the old direct consolidated generation shell, prepared block-contract projection, prepared wire-declaration rendering, live stage preparation, final prepared-block rendering, recursive decision-tree flattening, the structural pre-stage prelude pocket, the retired live generation-structural-prelude shell, the retired live generation-enable-preparation shell, the retired live generation-prelude shell, the retired live generation-pipeline shell, or post-flattening SystemVerilog assembly. It is the remaining lower-level direct-backend coordination across [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePlanningSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePlanningSupport.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStagePreparationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStagePreparationSupport.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStageSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStageSupport.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPrescanPreparationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPrescanPreparationSupport.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationTailSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationTailSupport.pm), and the broader direct-backend convergence target, not the already-extracted per-pass execution, loop-state lifecycle, AST-vs-runtime filter heuristics, collection/normalization prep, first-pass classification, dependency graph mechanics, old compatibility-shell cleanup, prepared block projection, declaration rendering, stage preparation, stage orchestration, or assembly orchestration.

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
- One now-shipped correctness sub-slice under this lane is static numeric partial-LHS lowering for the core assignment families:
  - same-context piecewise `=` / `<-` / `<=` / `<-=` / `<=-` writes now normalize into full-width mux inputs instead of collapsing to raw whole-signal writes, with legacy `<=+` preserved as a default-mode compatibility alias,
  - partial sequential writes now retain untouched bits through the correct feedback source,
  - the dual-output sequential families now also keep `next_*` / `*_r` auxiliary outputs aligned to the full base-signal width even for partial indexed/sliced writes,
  - and that same shipped contract is now regression-backed both when width comes from explicit `+size` and when width is inferred only from static slice/index bounds.

Expected result:
- the active language boundary becomes crisp enough that strict mode can be built on top of it cleanly.

### R9. Strict mode and support-tier enforcement
Goal:
- let users choose "only the supported language" explicitly.

Deliverable themes:
- a strict mode in the CLI/pipeline,
- targeted errors for constructs outside the fully supported tier,
- and workflow guidance on when to use strict mode.

First bounded slice:
- make strict mode real at the CLI/pipeline surface,
- start with the high-signal root-family compatibility cut by rejecting the legacy `+fsm` root family in strict mode,
- then tighten the `?dtc` child contract so strict mode accepts only canonical `?dt:` roots there instead of continuing to treat `?mod:` / `?module:` as acceptable standalone-DT child residue,
- then tighten the `?fsmc` child contract so strict mode accepts only canonical `?fsm:` roots there instead of continuing to tolerate legacy `+fsm` child residue,
- then narrow the direct module-root alias family so strict mode accepts canonical `?mod:` while leaving `?module:` as default-mode compatibility only,
- then reject the legacy empty `(+size)` no-op form in strict mode as the first section-level compatibility-residue cut while leaving default-mode compatibility intact,
- then reject legacy or misleading explicit reset spellings such as `(asreset rstn)` and `(sreset rstn)` in strict mode while leaving default-mode compatibility intact, with canonical reset intent carried by `(sreset reset)` for synchronous active-high reset and `(areset rst_n)` for asynchronous active-low reset,
- then reject the legacy compact top-level `(:= signal=value)` directive on the current `?fsm:` / `?dt:` path in strict mode while leaving default-mode compatibility intact, even though the current strict surface still lacks a canonical replacement for that compatibility form,
- and use that first slice to establish the support-tier enforcement pattern before widening it to other compatibility residue.

Expected result:
- production users can choose predictability over compatibility residue.

### R10. Source provenance and diagnostics
Goal:
- make parser/generator failures precise, actionable, and source-local.

Deliverable themes:
- file/line/construct provenance through parsing and generation,
- targeted errors instead of generic fallthrough failures,
- and clearer remediation guidance in diagnostics.

First bounded slice:
- make top-level failures keep the offending source path consistently,
- start at the source-file orchestration boundary so both pipeline and CLI entry points benefit at once,
- use that first slice to establish one reusable provenance/error-shape pattern before pushing deeper into line/construct-level provenance,
- normalize CLI presentation of those ordinary string diagnostics so source-local failure messages do not dump raw Perl stack traces,
- then widen that same pattern through generated-child realization so multi-file composition failures keep the child source path, the parent composition path when relevant, and the declared child-source identity instead of surfacing only inner adapter/parser text,
- then widen that same generated-child pattern through wrong-kind and unresolved external child boundaries so blocked composition child resolution/realization failures keep the same source-local framing instead of dropping back to raw search or wrong-kind text,
- then refine unresolved external `?fsmc` / `?dtc` lookup too, so missing child-source failures keep an explicit expected-child-file artifact label instead of stopping at only the composition path plus generated-child identity,
- then carry the same idea into external/embedded `?rtl` metadata loading so sidecar `.rtlif` failures keep the resolved metadata file plus parent composition source while embedded `?rtlif` failures still point back to the containing composition source,
- then refine unresolved external `?rtl` metadata lookup too, so missing sidecar `.rtlif` failures keep an explicit expected-artifact label and the same source-local framing instead of surfacing only raw search text,
- then promote lookup search details into stable `Search roots:` / `Searched locations:` lines so missing child-source and missing sidecar diagnostics keep their active search contract visible in both raw failures and the bounded non-quiet composition summary,
- and finally bring the same artifact-label idea one step earlier into pre-pipeline CLI entrypoint failures so unresolved source lookup and output-open errors keep concrete requested-source/output-file context too.
- the next honest widening step after that is to keep the same source-local framing around typed extension hook failures too, so extension errors preserve the failing source path plus the extension module/stage instead of surfacing as raw hook fallout.
- the next sibling widening step after that is to keep loader/construction failures in the same family too, so malformed extension config files and constructor-failing extension modules keep explicit artifact labels and cleaned CLI output instead of raw constructor fallout.

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
  - keep one dedicated live architecture note for the CLI entrypoint/import-tree shape in [docs/BIN_FSMGEN_IMPORT_TREE.md](docs/BIN_FSMGEN_IMPORT_TREE.md), and refresh it when the effective spine or package ownership picture changes enough that the saved analysis is no longer honest,
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
- allow one external RTL interface contract such as `(?rtlif:uart_tx ...)` to be instantiated several times through explicit `?rtl` instance aliases such as `(?rtl:u_uart_a uart_tx)` and `(?rtl:u_uart_b uart_tx)`,
- keep per-instance parameter/generic overrides as a typed semantic instantiation contract that survives into IR and target lowering, not as raw template text hidden in `?rtl` payloads,
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
  - the semantic split from `?fsm:name` is the control model, not "combinational only" versus "sequential allowed",
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
  - keep that frontend type core semantic rather than backend-spelled:
    - carry width, signedness, 2-state versus 4-state behavior, and value/category role as internal meaning,
    - avoid treating raw backend spellings like SV `logic signed [7:0]` or VHDL `std_logic_vector` as the source-language contract,
  - prefer packed-struct semantics as the default SystemVerilog lowering for frontend record/struct types so the portable contract does not depend on looser unpacked-struct synthesis behavior,
  - lower concrete backend carriers late from that semantic model:
    - SystemVerilog may need `bit` versus `logic` and signed versus unsigned vectors,
    - VHDL may need `std_logic_vector` versus `signed` / `unsigned`,
    - but the authored `.fsm` surface should stay intent-level unless an explicit override is genuinely needed,
  - defer backend-specific or semantically sharp-edged features such as unions and user-visible promises of free aggregate-to-vector casting until the portable core is stable,
  - keep the future VHDL promise narrower and evidence-based: nested record/array aggregates may be supported where the backend can lower and regression-lock them honestly, but the frontend should not promise unlimited nesting across all targets before that backend exists,
  - prefer convention over configuration by making type inference the default path for most signals and ports:
    - infer scalar versus aggregate shape from LHS and RHS usage,
    - infer record fields and array shapes from member/index access and compatible assignments,
    - infer nested record/list structure from authored usage rather than requiring users to predeclare every intermediate aggregate layer,
    - allow alternating list/record/list nesting in the frontend model when authored usage determines one safe aggregate shape,
    - avoid forcing explicit scalar type declarations when authored usage already recovers one safe answer,
    - fail explicitly when inference stays ambiguous or underconstrained instead of silently guessing,
    - and keep explicit type declarations available mainly as overrides, disambiguation anchors, and interface-stability controls,
  - keep the authored surface easy and expressive rather than ceremony-heavy:
    - `.fsm` authoring should feel closer to a dynamic language or script surface than to a declaration-first HDL clone,
    - mixed integer spellings should be accepted whenever the frontend can normalize them onto one safe semantic meaning,
    - aggregate authoring should feel similarly low-friction, with the engine autovivifying intermediate list/record structure from usage whenever that recovery is honest,
    - and the engine should prefer behind-the-scenes normalization/coercion only when that meaning is honest and backend-portable, otherwise it should stop with an explicit diagnostic,
  - keep future pack/deconstruct assignment syntax in the same intent-level
    family rather than treating it as raw HDL concatenation:
    - a future RHS pack form may compose one LHS from static-width expressions,
    - a future LHS deconstruct form may split one RHS across multiple legal
      static lvalues,
    - authored left-to-right ordering should map high-to-low in the packed
      value,
    - exact total-width agreement, declared/assigned operand legality, and
      compatible element types should be checked before generation,
    - overlapping or duplicate LHS ranges should fail unless a later semantic
      pass deliberately defines priority/merge behavior,
    - and the backend should receive normalized AST/IR assignments instead of
      inferring deconstruction from renderer-side text,
  - keep the initial operational contract narrower than the eventual syntax surface:
    - member/field reads and writes,
    - fixed-index and bounded array-element access,
    - exact-type whole-aggregate assignment only after the member-access lane is stable,
    - and explicit conversion helpers later where backend differences require them,
- and harden mixed `?fsmc` / `?rtl` flows before adding broader composition syntax.
- record one future composition-syntax cleanup decision instead of leaving it as untracked taste:
  - decide whether `?wiring` should remain the canonical spelling,
  - or whether a clearer preferred alias such as `?wiring` should be added above it while keeping `?wiring` as compatibility spelling until a deliberate syntax cleanup pass says otherwise.
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
- `?mod:name` and `?module:name` are also currently accepted on the live direct single-module path, but they should not be treated as semantic aliases of `?dt:name`.
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
  - bounded explicit-link `C2` / `C3` omitted/empty-`?ports` inference when explicit `?wiring` endpoints themselves still make the top boundary unambiguous, including renamed top-boundary signals plus source-side top-port bit/slice expressions whose highest referenced bit still yields one compatible inferred top-input contract,
  - bounded explicit-link `C2` / `C3` undeclared top-input inference when same-name child inputs remain top-facing and agree exactly on direction, width, and type metadata,
  - bounded explicit-link `C2` / `C3` undeclared top-output inference when exactly one same-name child output remains top-facing and is not already consumed by explicit child-to-child wiring,
  - saved ergonomics direction: `?ports` should increasingly act as the explicit override/disambiguation surface for the public boundary rather than as required boilerplate, so future composition inference work should prefer omission-by-default when one safe top boundary can be recovered honestly,
  - bounded explicit-link `C2` / `C3` plain-explicit-top-port same-name convention when child-side evidence is still exact and safe:
    - plain explicit top inputs may fan out by same name when compatible child inputs agree exactly on direction, width, and type metadata,
    - plain explicit top outputs may adopt one unique same-name top-facing child output when that child-side evidence stays exact,
    - mixed-direction plain-input families fail explicitly,
    - multi-output plain-output families fail explicitly,
    - and explicit top-boundary links still override that convention locally,
  - first bounded composition-plan transparency metadata:
    - top ports carry `origin_kind` so declared versus inferred top-boundary decisions remain visible,
    - links carry `origin_kind` so explicit wiring_blocks, `=name`, same-name convention links, internal-carrier links, and auto system-port links can be distinguished,
    - and the typed composition plan exposes `resolved_links` as the full resolved link set used by planning,
  - first bounded user-facing composition provenance reporting on top of that metadata:
    - composition generation results now carry `composition_report`,
    - the report summarizes top-port and resolved-link provenance by `origin_kind`,
    - the report now also surfaces the first shipped local override events,
    - the report now also surfaces the first shipped blocked convention events,
    - plain explicit top-port same-name convention failures now also say when that convention is blocked instead of only implying it,
    - undeclared top-input/top-output and undeclared internal-carrier inference failures now also say when those convention-first inference paths are blocked,
    - explicit-wiring-driven undeclared top-port inference failures now also say when that inference path is blocked by direction, width, or type disagreement,
    - explicit `?wiring` validation failures now also say when endpoint resolution, direction, duplicate-drive, or width evidence blocks the declared link,
    - explicit-link top-wiring and realized-child-wiring failures now also say when declared top ports or realized child ports remain unwired in explicit-link lanes,
    - explicit-link lane-entry and remaining topology failures now also say when explicit-link lanes are entered without `?wiring` or when a still-unsupported explicit-link topology is requested,
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
  - those structural instance pin bindings now also preserve typed `connection_expr` nodes, currently bounded to backend-neutral `signal_ref`, source-side top-port `bit_select` / `slice` / `repeat` forms, source-side child-output `bit_select` / `slice` / `repeat` forms, and the first shipped explicit-wiring actual-source forms through `open` and bit-vector literals,
  - and realized composition-plan instances now also preserve those same typed nodes before structural serialization instead of forcing `StructuralRTLIR` to synthesize them late,
  - with that earlier binding normalization now owned by `FSM::Composition::RealizedInstance` itself instead of only by `HDLGenerator`,
  - and the current bounded `signal_ref` / `open` / bit-vector-literal construction, signal-name recovery, and backend-neutral text rendering for those actual-connection nodes now also live in dedicated `FSM::IR::StructuralRTLIR::ConnectionExpr` helpers instead of staying split across pipeline glue,
  - with the remaining "effective binding expression" fallback now also centralized there, so structural serialization no longer re-synthesizes `signal_ref` nodes ad hoc from `signal_name` inside `HDLGenerator`,
  - and the first bounded signal-ref binding constructor/update helpers now also live there, so the pipeline no longer hand-pairs `signal_name` and `connection_expr` when creating or rebinding structural instance bindings,
  - with normalized binding cloning/backfilling now also centralized there, so both `FSM::Composition::RealizedInstance` and structural instance-binding serialization consume the same bounded binding contract,
  - and the first bounded signal-ref binding-list ensure/set operations now also live there, so `HDLGenerator` no longer owns the low-level "reuse this binding versus append/update it" rules for structural port-binding lists,
  - and explicit `?wiring` may now use `=open`, scalar `=0` / `=1`, unsized binary/decimal/signed-decimal/octal/hex direct forms such as `=0b10`, `='b10`, `=0d10`, `='d10`, `=-1`, `=0d-1`, `='sd-1`, `='sb1010`, `='so7`, `='shA`, `=0o7`, `='o7`, `=0xA`, `='hA`, `=170`, or `=A5`, underscore-separated spellings such as `=0b1010_0101`, `='b1010_0101`, `=1_70`, `='d1_70`, `=0o2_45`, `='o2_45`, `='so6_45`, `='hA_5`, and `=8'hA_5`, and exact-width `=N'b...` / `=N'sb...` / `=N'd...` / `=N'sd...` / `=N'o...` / `=N'so...` / `=N'h...` / `=N'sh...` as source actuals, with `=open` still targeting realized child inputs only while direct scalar `=0` / `=1` plus unsized binary/decimal/octal/hex direct actuals widen to the realized child-input or declared top-output target width, unsized signed decimal direct actuals plus unsized signed binary/octal/hex direct actuals widen when the signed value fits the signed range of that direct target width, exact-width literal actuals may now also drive declared top outputs, and linked planning preserves those bindings directly instead of inventing helper nets or undeclared same-name top inputs,
  - and bounded composition-root `+constants` / `+enums` symbols may now also feed those explicit `?wiring` literal-actual positions, so direct bindings and bounded concat operands can use named literal actuals such as `=RESET_BYTE`, `=BYTES[1]`, `=FRAME.flag`, or `=mode.BUSY` without opening a separate symbol-only lowering path or claiming the broader future type lane is already shipped,
  - and the semantic package/import lane now also ships one bounded whole-aggregate slice on that same literal-actual path and the direct generated-root path: `?top` may use bounded `+import` blocks, shared `?pkg:name` roots may be embedded or resolved through the normal search roots, namespaced package symbols such as `=shared.RESET_BYTE`, `=shared.mode.BUSY`, `=shared.BYTES[1]`, `=shared.FRAME.flag`, `=shared.HEADER`, or `=shared.FRAME` now resolve onto the same direct/concat structural literal path, direct `?fsm` / `?dt` roots may now also use bounded `+import` blocks whose namespaced package scalar leaves and whole aggregate roots resolve in assignment RHS expressions and guard equality conditions, and hash-like whole roots now pack authored members left to right in declaration order when every leaf is still scalar-literal-lowerable,
  - and that same bounded aggregate-value contract now also covers local direct-root `+constants`, so direct `?fsm` / `?dt` sources may use local aggregate references such as `BYTES[1]`, `FRAME.flag`, and `NEST.header.nibble` plus whole aggregate roots such as `BYTES`, `TAIL`, or `FRAME` in assignment RHS expressions and guard equality conditions without moving those values into packages first,
  - and bounded aggregate values now also reuse same-scope named scalar ingredients through one declarative-resolution pass instead of parser order: local direct roots, local composition tops, and `?pkg:name` packages may now build aggregate values from constants, enum members, and whole aggregate roots such as `(PACKET (HEADER mode.IDLE))` and `(HEADER (mode.BUSY RESET_BYTE))` regardless of declaration order, while explicit dependency cycles now fail clearly,
  - and that same shipped declarative-scope lane now also covers the first bounded `+types` slice: direct roots, composition tops, and `?pkg:name` packages accept scalar aliases for `bit`, `(bits N)`, and named scalar aliases without declaration-order dependence, direct-root `+size`, local composition `?ports`, direct package-qualified imported composition `?ports` width tokens such as `shared.byte`, and local composition aliases that themselves target imported package scalar types may use those aliases, explicit type cycles fail clearly, and forward `symbol_contract` / mirrored `module_info` now also preserve local type names/counts plus canonical scalar type specs,
  - and that same width-token lane now also accepts positive integer scalar symbols on live authored width positions, so direct-root `+size` and composition `?ports` may use local/imported scalar names such as `BYTE_W` or `shared.BYTE_W` when those symbols resolve to one positive integer literal value, with one shared scalar-width extraction helper owning that numeric-width boundary instead of parser-local string rules,
  - and direct generated roots now also preserve one bounded `symbol_contract` through `intent_hir` and mirrored `module_info`, carrying local constant/enum names and counts, canonical aggregate/scalar constant payloads, scalar-leaf convenience payloads, aggregate-root path summaries, and imported package names/counts so later whole-aggregate/type work no longer has to rediscover the authored symbol layer from parser residue,
  - and composition tops now also preserve that same bounded `symbol_contract` through composition-top `intent_hir` and mirrored `module_info`, so local top constants/enums, canonical aggregate/scalar constant payloads, scalar-leaf convenience payloads, aggregate-root path summaries, and imported package names/counts survive the composition forward-IR boundary too,
  - and that same direct structural binding path now also covers source-side top-port `name[index]` / `name[msb:lsb]` expressions over declared top inputs when they drive realized child inputs, again without inventing helper nets or undeclared same-name top inputs,
  - and that same direct structural binding path now also covers source-side child-output `instance.port[index]` / `instance.port[msb:lsb]` expressions when they drive realized child inputs or declared top outputs, with linked planning grouping those projected-child uses by one deterministic base carrier instead of inventing per-projection helper nets,
  - and that same structural path now also covers bounded repeat groups such as `{3{status_bus[0]}}` and `{2{producer.serial_lo}}`, with child-output repeats reusing that same deterministic base-carrier family instead of inventing repeat-only helper nets,
  - and bounded source-side concat expressions may now also include child-output operands such as `producer.payload`, `producer.payload[7:4]`, and `producer.payload[0]`, with those operands reusing that same deterministic base-carrier family instead of inventing concat-only helper nets or raw dotted-name text paths,
  - and the bounded failed-run summary path now also keeps that same structural/top-expression slice honest, so blocked actual-source role failures preserve `Actual source '=...'` context, blocked actual-endpoint target failures preserve `Actual endpoint '=...'` context, blocked top-expression range failures preserve `Top expression '...'` context, and blocked child-expression range failures preserve `Child expression '...'` context under the concise `explicit actual binding` or `explicit link endpoint resolution` boundary as appropriate,
  - and the active composition-top emitter now walks that structural layer instead of re-reading only `FSM::Composition::Plan` state directly during top-module dumping.
- The next structural widening step is now also shipped:
  - direct generated `?fsm` / `?dt` results now expose a bounded structural module-interface slice through `structural_rtl_ir`,
  - that direct-root structural slice currently covers explicit module ports, declaration-only storage/helper nets, generated enable-wire nets, generated enable assignment records, scalar compatibility auxiliary-assignment lines, generated-enable assignment-record source/target connectivity on direct nets, direct input-port generated-enable RHS target connectivity, direct output-port source summaries from lowered output-drive families, and direct SystemVerilog top state/standalone-DT generated-enable condition emission rerouted through `StructuralRTLIR`; broader output-drive/always-block body consumers remain future exact work, selector `R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.1` deferred broader/full direct SystemVerilog rerouting until direct behavior-body/state-update/output/assertion regions have exact structural ownership, selector `R11-DIRECT-STRUCTURAL-VHDL-REROUTING.1` deferred direct VHDL backend/reroute work until the SystemVerilog-backed IAL0/IAL1/IAL2 path is feature complete, and selector `R11-DIRECT-STRUCTURAL-INSTANCES-LINKS.1` confirmed direct roots intentionally keep empty instance/link arrays and populated instances/links remain composition-top structural facts,
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
  - composition-top `structural_rtl_ir` now preserves declared explicit-wiring connectivity separately through `declared_links` instead of only carrying the post-resolution link graph,
  - and block-event reasoning for explicit child links now consumes that structural declared-link surface instead of rereading declared wiring_blocks directly from the plan.
- The next structural-consumption step is now also shipped through override/block resolved-link handling:
  - composition override events now take their explicit-wiring and inferred-reexport connectivity from `structural_rtl_ir->{resolved_links}`,
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
  - keep `?top:name` as the explicit composition root while keeping `?dt:name` as the standalone-DT root and leaving the precise broader `?mod:name` / `?module:name` module-root contract open,
  - extend reusable-source lookup through existing `FSMLIB` semantics plus repeatable `--path DIR` CLI roots,
  - and add one semantic package/import lane for sharable named scalar values, named aggregate values, `+enums`, and future `+types`, rather than falling back to textual include-style reuse.
- longer-term hierarchy direction:
  - whole `.fsm` designs should eventually behave as authored bottom-up multi-level hierarchies with non-leaf composition nodes and leaf implementation nodes,
  - users should still invoke only the top root, with `fsmgen top.fsm` recursively realizing child nodes, collecting interfaces/semantic summaries bottom-up, and resolving bindings/wiring at each parent level until the final top is emitted,
  - internal non-leaf reusable composition modules should eventually become first-class authored artifacts instead of composition remaining only a top-shell over leaf children,
  - and the implementation should distinguish authored graph from elaborated instance tree: source reuse may form a DAG, while elaboration still produces a concrete hierarchy for emission.
- first contract questions to settle:
  - what the exact source-root family becomes beyond the now-shipped `?fsm:name`, `?dt:name`, `?mod:name`, `?module:name`, and `?top:name`,
  - whether the package root should be something like `?pkg:name`, `?package:name`, or a different but still explicitly non-behavioral family,
  - whether unnamed reusable DT roots such as `?dt:` should exist at all or remain deferred,
  - how standalone DT interfaces are declared/exposed,
  - which declaration families belong in packages from day one: certainly shared scalar values, named aggregate values, and enum families, plus likely future named types, but probably not instance-specific parameterization by default,
  - what the explicit import/use syntax should be for `?fsm`, `?dt`, and `?top` roots,
  - whether package symbols are always referenced by namespace or may also be imported selectively,
  - how block-level and module-level enable families are surfaced so same-target arbitration stays explicit without structural over-rejection,
  - how lookup precedence works between explicit paths, `--path` roots, `FSMLIB`, and local files,
  - how duplicate-name shadowing is diagnosed,
  - how reusable DT/module roots are referenced from other `.fsm` sources without drifting back into legacy implicit behavior,
  - and how the package lane avoids turning into a preprocessor or macro system instead of staying semantic, namespaced, frontend-checkable, and smaller than a verbatim SystemVerilog/VHDL surface clone.
- portable synthesizable scalar/aggregate types with inference-first declarations.
- intent:
  - add one portable synthesizable type system that works as a frontend contract first and a backend lowering problem second,
  - let most users omit explicit type declarations most of the time by inferring signal and port types from how names are used in assignments and expressions,
  - avoid forcing explicit scalar declarations when usage already determines one safe type,
  - make authored `.fsm` feel dynamic and forgiving at the surface by accepting mixed integer formats and other low-friction spelling variation whenever the engine can recover one safe meaning,
  - infer aggregate list/record structure the same way, including nested autovivified shapes when authored usage determines one safe aggregate model,
  - fail explicitly when inference cannot determine one safe type instead of falling back to hidden guesses,
  - keep explicit type declarations mainly as overrides where the user wants to disambiguate or freeze an interface contract,
  - and make backend capability checks explicit when an inferred aggregate shape is richer than the selected HDL target can lower honestly.
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

First bounded slice:
- start with named in-repo protocol seeds instead of only anonymous fixture accumulation,
- lock direct-root smoke for imported protocol actors such as `apb_requester`, `apb_completer`, and `amba_requester`,
- lock one composed protocol harness such as `apb_tb` so the corpus includes a real generated-child/wiring path and not only leaf modules,
- promote that first slice into a small machine-checked corpus catalog so future support claims grow by explicit classification instead of ad hoc hardcoded test lists,
- and widen that same first catalog beyond `supported_smoke` by proving at least one explicit compatibility-retained `legacy_out_of_scope` entry and one explicit `expected_failure` entry,
- then prove that `expected_failure` is not just "strict-mode rejection" by adding at least one malformed-language contract entry with a normal pipeline/CLI rejection boundary,
- then widen the same catalog beyond root-level legacy behavior by adding at least one section-level compatibility-residue asset that is retained in default mode but intentionally rejected in strict mode,
- then widen the same catalog again into generated-child source-root residue by adding at least one compatibility-retained child-root asset plus one strict expected-rejection child-root asset that both depend on explicit source-search-path realization,
- then widen the same catalog again into composition-contract rejection by adding at least one composition-top expected-failure asset whose failure is neither a strict-mode cut nor a direct language-contract parse rejection,
- then widen that same composition-contract slice beyond one subsystem by adding at least one missing generated-child source case alongside the earlier missing external `.rtlif` sidecar case,
- then widen the supported side beyond imported protocol seeds too by promoting at least one shipped language-feature contract into named `supported_smoke` corpus assets with semantic HDL checks instead of compile smoke only,
- and use that first slice to establish that imported/example assets only count toward support claims once they are regression-backed.

Expected result:
- support claims stop being conversational and become auditable.

### R13. Public embedding/API stabilization
Goal:
- make FSMGen intentionally embeddable as a library/tooling component.

Deliverable themes:
- stabilize the `HDLGenerator` result contract,
- document the typed extension/context contract at an embedding level,
- and grow explicit serializable plan/report APIs instead of leaving downstream
  tooling to traverse raw in-process compatibility shells.

Current direction:
- The serializable plan/report boundary is now an affirmative `R13` direction,
  not an optional maybe. Raw branches such as `composition_spec`,
  `composition_plan`, `fsm_module`, `raw_ast`, `resolved_package_imports`, and
  `composition_report` remain in-process compatibility shells, while new
  embedder-facing work should prefer bounded JSON-safe snapshots/reports that
  can be versioned, regression-locked, and documented independently.
- First surface: `embedding.serializable_plan_reports` now advertises the
  current JSON-safe report families and raw-shell replacement guidance through
  [perl/FSM/Support/SerializablePlanReportContract.pm](perl/FSM/Support/SerializablePlanReportContract.pm).
- First plan API: [perl/FSM/Support/SerializableCompositionPlanSnapshot.pm](perl/FSM/Support/SerializableCompositionPlanSnapshot.pm)
  now provides a bounded JSON-safe `composition_plan_snapshot` summary for raw
  composition plans.
- Public report path: successful normalized semantic JSON reports now embed that
  snapshot at `semantic.composition.plan_snapshot` for composition roots.
- Second report API: [perl/FSM/Support/SerializableGenerationResultSnapshot.pm](perl/FSM/Support/SerializableGenerationResultSnapshot.pm)
  now provides a JSON-safe `generation_result_snapshot` summary for raw
  `HDLGenerator` results.
- Public report path: successful normalized semantic JSON reports now embed that
  snapshot as top-level `generation_result_snapshot`.
- Diagnostic report API: [perl/FSM/Support/SerializableDiagnosticSummary.pm](perl/FSM/Support/SerializableDiagnosticSummary.pm)
  now provides a JSON-safe `diagnostic_summary` for stable diagnostic code/count
  inspection.
- Public report path: normalized semantic JSON now embeds that summary for both
  success and failure reports.
- Shared report path: check JSON now embeds the same summary for both success
  and failure reports.

Expected result:
- the project becomes a stronger platform for downstream tooling, not just a CLI.

### R14. Intent Scheduling — `.isf` format and lowering compiler
Goal:
- design and implement a new Lisp-ish hardware-intent format (`.isf` =
  Intent Scheduling Format) that abstracts cycle counting away from the
  author, and build the compiler that infers/schedules cycles and lowers
  to explicit cycle-accurate `.fsm`.

Core thesis (from [docs/INTENT_SCHEDULING_BRAINSTORM.md](docs/INTENT_SCHEDULING_BRAINSTORM.md)):
- `.fsm` is already an abstraction above SystemVerilog/VHDL, but today
  `?fsm` authoring is still explicitly cycle-aware because state DTs
  encode the schedule directly.
- `.isf` lets authors describe transactions, rules, handshakes, phases,
  resources, and constraints without choosing every state/cycle manually.
- The compiler infers and schedules cycles, producing explicit `.fsm` plus
  a generated schedule report.
- Cycles do not disappear from the final semantics. They become an inferred,
  scheduled, and reviewable compiler result.

Architecture:
- `.isf` (Intent Scheduling Format) → scheduled `.fsm` → SV/VHDL
- SPECFORGE targets `.isf` from its IntentIR; FSMGen owns scheduling,
  cycle inference, conflict analysis, and lowering.
- `.fsm` remains the explicit cycle-accurate middle layer — inspectable,
  debuggable, and patchable.

Deliverable themes:
- formalize the `.isf` syntax and semantic contract,
- define the lowering/scheduling compiler pipeline,
- implement the first bounded scheduler slice,
- produce machine-readable schedule reports,
- keep ambiguity explicit: if timing cannot be inferred safely, fail with
  an actionable report rather than choosing a hidden schedule.
- explore static Actor Transfer Level (`ATL`) actor-network orchestration as
  an IAL1 extension: a top-level actor whose structure/content is a network
  of explicit ISF actors, where actors replace flops/registers as the named
  transfer endpoints. Top-level actor transactions and rules can trigger
  actors or transactions inside the network; actors can synchronize on
  scheduler-visible events; and data/information can move between actors,
  between concurrent actor groups, and between the top-level pins and actors
  through explicit scheduler-visible bindings. This remains IAL1 while
  authored as explicit `.isf`; it becomes IAL2 only if the source model moves
  above explicit actor/network syntax into protocol/platform intent inference.

Initial sub-slices:
1. Formalize the `.isf` format specification from the brainstorm log,
   defining concrete syntax for transactions, rules, handshakes, phases,
   latency constraints, and resource declarations.
2. Define the lowering contract: what `.isf` constructs map to what `.fsm`
   patterns, and what the schedule report shape is.
3. Implement the first bounded scheduler for a single-transaction `.isf`
   source, producing valid `.fsm` output.
4. Add regression coverage and schedule report validation.
5. Clarify the active actor-network/ATL orchestration contract before
   implementation: source shape, compact plus verbose syntax, event pulse
   semantics, endpoint-aware drive-body pairs in existing `(sink source)`
   order, mux/enable/handoff inference for multiple source actors,
   concurrent actor-group scheduling,
   generated artifact naming, report visibility,
   whether ATL clauses should be scoped by `(network ...)` or live flat under
   the top-level actor, and fail-closed boundaries are tracked in
   [docs/tasks/ISF-ACTOR-NETWORK-ORCHESTRATION.md](docs/tasks/ISF-ACTOR-NETWORK-ORCHESTRATION.md)
   and the concrete ATL v0 proposal in
   [docs/ISF_ATL_DESIGN_PROPOSAL.md](docs/ISF_ATL_DESIGN_PROPOSAL.md).

Expected result:
- a working `.isf` → `.fsm` lowering path that handles at least one realistic
  transaction/rule pattern with generated schedule reporting.

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
- `R13` should solidify before `R14`, because the embedding/API surface is how downstream tools will consume captured `.fsm` artifacts.

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
- create a Rust implementation of FSMGen, keeping Rust/Wasm as a plausible
  future deployment target.

Intent:
- carry the mature language/tool contract into a stronger long-term systems implementation,
- not to re-open the language-design phase in a second implementation prematurely,
- preserve IAL0/IAL1/IAL2 as backend-language-neutral contracts rather than
  Perl-specific implementation APIs.

Prerequisite:
- the language contract, diagnostics contract, support accounting, and embedding surface must already be stable enough that a Rust implementation is an execution project, not a moving-target rewrite.

Initial execution guidance:
- start the first serious Rust implementation in this same repository rather than in a separate repository with the current Perl tree as a submodule,
- keep the Perl implementation as the reference/oracle while the Rust implementation grows beside it,
- share one roadmap, one documentation set, one regression corpus, and one differential-test harness across both implementations,
- and only consider splitting into a separate repository later if release cadence, contributor workflow, packaging, or ownership really diverge enough that a monorepo becomes friction rather than leverage.
- avoid baking POSIX filesystem access, process spawning, Perl module loading,
  or other host-only assumptions into the portable IAL contracts, so Rust/Wasm
  and browser-hosted implementations can use suitable host abstractions.

Rationale:
- a same-repo start keeps the contract, fixtures, snapshots, and expected diagnostics physically close to both implementations,
- it avoids submodule drift and cross-repository version skew while the Rust implementation is still proving semantic parity,
- and it makes it much easier to treat the Perl codebase as a semantic reference instead of trying to maintain two partially decoupled moving targets.

Architecture constraint:
- [docs/decisions/0018-ial-contracts-are-backend-language-neutral.md](docs/decisions/0018-ial-contracts-are-backend-language-neutral.md)
  records that IAL0/IAL1/IAL2 and the mdBook are portable contracts for the
  current Perl reference implementation plus future Rust, Rust/Wasm, and
  browser-capable JavaScript and Dart/web implementations.

### H1b. Browser-Capable JavaScript FSMGen
Long-term goal:
- make FSMGen capable of running in a web browser through a JavaScript and/or
  Wasm-hosted implementation.

Intent:
- expose the same public source, report, diagnostic, and HDL-generation
  contracts through browser-appropriate host abstractions,
- avoid designing a separate browser-only semantics layer.

### H1c. Browser-Capable Dart FSMGen
Long-term goal:
- make FSMGen capable of running in a web browser through a Dart/web
  implementation.

Intent:
- treat Dart as another implementation/runtime option for the same public IAL
  contracts,
- avoid designing Dart-only source, report, diagnostic, or lowering semantics.

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
- do not describe the reverse-path early layer as a "non-semantic HIR"; the non-semantic layer is the parsed HDL CST/AST, and honest recovery actually needs more semantic structure rather than less,
- the forward `.fsm` to HDL compiler should now be treated as likely converging toward `parsed .fsm AST -> semantic Intent HIR -> Lowered RTL IR -> Structural RTL IR / Connectivity IR -> backend emission`,
- the reverse HDL-import path should converge toward `parsed HDL CST/AST -> semantic HDL HIR -> elaborated RTL IR -> Flat IR -> recovered Intent IR -> .fsm output + recovery report`,
- the important refinement is that the current `Lowered RTL IR` should not be expected to double as the full connectivity graph forever: it can carry normalized lowering summaries and backend-relevant analysis without being the final structural object that the emitter walks,
- the planned `Structural RTL IR` / connectivity layer should eventually be an AST-like netlist structure that carries explicit ports, nets, instances, pin/binding edges, assignments, and backend-facing auxiliary structure so HDL emission becomes primarily a rendering walk instead of a place where connectivity is rediscovered ad hoc,
- that `Structural RTL IR` should stay backend-neutral and extensible rather than collapsing into raw SystemVerilog/VHDL syntax, so child actual-pin connections should eventually be represented through typed structural connection expressions / actual-connection AST nodes instead of opaque HDL strings,
- those structural connection expressions should be allowed to grow toward durable connectivity forms such as references, literals, slices/part-selects, concatenations, member/index access, and bounded open/default associations where those remain portable across supported backends,
- and when a connection gets too backend-specific or too awkward to keep elegant there, the healthier rule is to normalize it earlier into helper nets or auxiliary assignments and then bind the child pin to that normalized structural value,
- one important implementation distinction is that the current `FSM::Pipeline::HDLGenerator` is still a combined compiler driver, lowering coordinator, and emitter, so any direct `Intent HIR` or `Lowered RTL IR` queries there should be treated as transitional coordinator cleanup rather than the desired final backend boundary,
- and the convergence target is to split that combined role so orchestration may still see all three forward IRs while the pure HDL backend/emitter mostly walks `Structural RTL IR` as the last IR before HDL text,
- and there should be no public-compatibility pretext holding that breakdown back: FSMGen is not a published public contract yet, so preserving today's accidental monolith is less important than converging to the strongest architecture, with any internal shim accepted only when it is clearly temporary and moving toward that split,
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
This lane is now handled externally by the SPECFORGE project (PDF/spec →
IntentIR → `.isf`). FSMGen captures the method reference in
[docs/INTENT_CAPTURE_AXI_CASE_STUDY.md](docs/INTENT_CAPTURE_AXI_CASE_STUDY.md)
and the APB worksheet in [docs/APB_REQUESTER_CAPTURE_WORKSHEET.md](docs/APB_REQUESTER_CAPTURE_WORKSHEET.md)
as documentation artifacts, but the active implementation belongs to SPECFORGE.

### H5. VHDL backend
Long-term goal:
- implement a real VHDL backend once a second backend is genuinely warranted.

Intent:
- demoted from former `R14` to horizon status on 2026-05-11,
- the scoping work already done in [docs/VHDL_SCOPE.md](docs/VHDL_SCOPE.md)
  remains valid and should be consulted when this lane is eventually promoted.

Deliverable themes (preserved from former R14):
- define the VHDL backend scope (done: see VHDL_SCOPE.md),
- implement the single-FSM lane first,
- then decide whether composition-top VHDL generation is still desirable.

Prerequisite:
- a second backend multiplies ambiguity if the language contract is still
  gray; promote this only after the SystemVerilog-backed IAL0, IAL1, and IAL2
  path is feature complete and the active lanes are genuinely stable.

Priority note:
- the current feature-completeness priority is IAL2 on the SystemVerilog-backed
  lowering path, tracked by
  [docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md);
  the first post-Valid-Ready AXI manager rule subset is now selected as
  outstanding-capacity plus acceptance/status feedback, the readiness audit
  found no IAL1 or IAL0/SV prerequisite blocker, the first in-process
  generator is shipped as
  `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus`, the public `.ppif`
  parser/CLI first slice is shipped for exactly one
  `manager-capacity-status` object, the next subset is selected as ID-family
  declaration/static validation, and the additive optional `(id-families ...)`
  public `.ppif` extension is shipped for the existing capacity/status object;
  the next subset is selected as a logical read/write transaction envelope and
  static-validation contract; the readiness audit selects an additive optional
  `(transactions ...)` static/report metadata extension under that same object;
  the public `.ppif` transaction-envelope metadata slice is now shipped with
  structured report metadata and initially unchanged generated `.isf`, `.fsm`,
  and HDL behavior; the transaction event dispatch and direction fan-in readiness audit
  selected an additive implementation boundary with no separate pre-slice
  IAL1/IAL0/SystemVerilog prerequisite, and that dispatch/fan-in slice is now
  shipped with generated transaction-event inputs, OR fan-in guards, additive
  `transaction_event_dispatch` report metadata, and the needed bounded IAL1
  OR/negated-OR guard conflict proof; the next selected subset is AXI manager
  ID/response rule-engine readiness before any ID allocation, response
  matching, ordering, burst, queued-policy, alias, full-manager, or VHDL
  behavior changes; the readiness audit selected additive concrete transaction
  ID request/response assertions as the first implementation boundary; that
  concrete-ID assertion slice is now shipped with generated ID inputs, `.fsm`
  `+assert` carriers, verification-only SystemVerilog assertions, and
  `id_response_rule_engine` report metadata; the next selected subset is AXI
  manager auto-ID lifecycle/request-ID drive readiness before any auto-ID
  allocation, ID release, response demux, ordering, burst, queued-policy,
  alias, full-manager, or VHDL behavior changes; the readiness audit concluded
  that the substrate can carry a bounded scalar request-ID lifecycle, but the
  public contract must first select a bounded auto-ID pool/request-ID drive
  contract because width and `(id auto)` alone are not a reviewable allocation
  policy; the contract selector chose an explicit optional
  `(auto-id-lifecycle (write (pool ...)) (read (pool ...)))` clause and
  advanced the frontier to parser/report metadata before generated request-ID
  drive behavior; that parser/report metadata slice is now shipped with a
  runnable sample, support accounting, static validation, and unchanged
  generated `.isf`, `.fsm`, and HDL behavior; the first bounded request-ID
  drive behavior slice is now shipped for explicit lifecycle families, with
  generated request-ID outputs, selected-ID/busy state, first-free allocation
  rules, completion-event release rules, runtime assertions, and
  `auto_id_lifecycle.generated_behavior: true`.

## Current intent
The active immediate feature-completeness lane is IAL2 on the
SystemVerilog-backed lowering path; see
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).
The parser/report metadata slice `IAL2-FEATURE-COMPLETENESS-FRONTIER.39` is
now shipped for the bounded AXI read response-demux public contract selected
by `.38`. The selected read arm requires `(response-scope single-beat)`,
treats top-level `read-complete` as the raw accepted single-beat read response
event under explicit opt-in, reports structural `response_demux.read`
metadata with `generated_behavior: false`, and keeps generated read `.isf`,
`.fsm`, and HDL behavior unchanged through `.39`. Readiness audit `.40`
concluded that bounded single-beat generated read `RID` response-demux
behavior can be implemented directly with no new IAL1/IAL0/SystemVerilog
prerequisite. `.41` now ships that generated read behavior, and `.42` selected
read-data payload, burst/`RLAST`, and per-ID readiness as the next audit.
Audit `.43` concluded that the bounded public read-data payload/status
contract must be selected before parser/report metadata or generated behavior
changes. Selector `.44` chose explicit bounded `(read-data (read ...))`
syntax for single-beat `RDATA`/`RRESP` capture, with generated read
response-demux as the completion source and `RLAST`/bursts deferred. Slice
`.45` now ships parser/report metadata and static validation for that contract:
the public `.ppif` parser accepts one structural `read-data` read arm, the
capacity/status report publishes transaction-bound data/status outputs, the
new read-data sample is support-accounted for check JSON and normalized
semantic JSON, and generated capture behavior was deferred to `.47`.
Readiness audit `.46`
concluded that generated single-beat read-data capture can be implemented
directly with no new IAL1/IAL0/SystemVerilog prerequisite. Slice `.47` now
ships that behavior: generated `RDATA`/`RRESP` inputs, per-transaction
data/status outputs, normal guarded capture assignments under generated read
completion pulses, generated artifact report lists, and
`read_data.generated_behavior: true` with generated-capture residue removed.
Selector `.48` chose `IAL2-FEATURE-COMPLETENESS-FRONTIER.49`, AXI
burst/`RLAST` completion readiness, as the next exact prerequisite before
multi-beat read-data reassembly or broader read-side manager behavior.
Audit `.49` concluded that the existing IAL1/IAL0/SystemVerilog substrate is
probably sufficient for a later bounded `RLAST` implementation, but the public
contract must be selected first. The active frontier is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.50`, a selector for `RLAST` signal
ownership, burst length or beat-count metadata, beat-valid versus
transaction-complete semantics, data/status capture granularity, diagnostics,
report/residue movement, and generated artifact boundaries before
parser/report metadata or HDL behavior changes.
Selector `.50` chose an additive read `response-demux` contract:
`response-scope burst-last` plus one-bit `last-signal`. It keeps transaction
completion as the generated last-beat pulse, publishes no per-transaction
beat-valid output, uses `RLAST` rather than `ARLEN` or beat-count metadata for
this first boundary, rejects the current single-beat `read-data` contract when
paired with burst-last response demux, and leaves multi-beat read-data
reassembly deferred. Slice `.51` ships parser/report metadata and static
validation for that contract, including the support-accounted burst-last
sample and structural report-only `response_demux.read` metadata with
`generated_behavior: false`, while generated `.isf`, `.fsm`, and HDL behavior
remain unchanged. Audit `.52` found no new IAL1/IAL0/SystemVerilog
prerequisite and selected direct generated burst-last/`RLAST` completion
behavior. Slice `.53` ships that behavior: explicit burst-last read response
demux now emits the raw response beat input, generated `RID` input, generated
one-bit `RLAST` input, generated transaction completion pulse outputs,
RLAST-gated response-demux rules, assertions, auto-ID lifecycle residue
movement, same-ID coverage movement, and HDL reachability. The active frontier
selector `.54` found one remaining report-contract drift: generated schedule
report prose still describes burst-last `RLAST` metadata as report-only and
generated burst/last-beat tracking as outside the capacity/status shell.
Slice `.55` aligns that report/static text: reports now say burst-last
response-demux generates matched-`RID`-and-`RLAST` last-beat completion
behavior, and list generated burst-last `RLAST` response-demux completion as
supported. Selector `.56` selects `.57`, public AXI burst read-data contract
selection, before parser/report metadata or generated behavior. Direct
multi-beat read-data behavior remains premature because the current
`read-data` contract is single-beat-only, the burst-last sample has no
`read_data` contract, and the public shape for burst capture scope, output
binding, beat-count/depth, `RRESP` aggregation, interleaving, diagnostics, and
report residue movement is not selected yet. Selector `.57` chooses explicit
last-beat read-data capture as the first bounded burst-side contract:
`capture-scope last-beat`, `status-policy last-beat`, and
`interleaving last-beat-by-rid`, paired only with generated
`response_scope burst_last` response demux. Slice `.58` now ships
parser/report metadata and static validation for that contract: the public
`.ppif` parser accepts the last-beat read-data shape, requires generated
burst-last read response-demux metadata, reports
`bounded_last_beat_read_data_contract` with `generated_behavior: false`, adds
a strict support-accounted sample, and keeps generated `.isf`, `.fsm`, HDL
behavior, check JSON semantics, and existing single-beat read-data behavior
unchanged. Readiness audit `.59` found no new IAL1/IAL0/SystemVerilog
prerequisite because the existing read-data input/output/capture-rule helpers
can use the generated burst-last completion pulses from response demux. The
`.60` slice now ships that generated behavior: generated `RDATA`/`RRESP`
inputs, per-transaction last-beat data/status outputs, normal guarded capture
rules driven by generated burst-last completion pulses, generated `.fsm`
assignments, HDL reachability, read_data generated artifact report lists, and
residue movement. Selector `.61` chose public AXI burst read-data
beat-count/depth contract selection because full reassembly, per-beat
outputs, `RRESP` aggregation, missing/extra beat validation, and per-ID
reassembly need an explicit expected-count/depth contract first. Selector
`.62` chose an additive ARLEN-based `burst-length` contract with width-8
`axlen-plus-one` encoding, transaction-request capture, required `max-beats`
in range `1..256`, and report-only validation. Slice `.63` ships
parser/report metadata and static validation for that contract: `.ppif`
accepts optional last-beat `read-data` `burst-length` metadata, reports
ARLEN/max-beats fields with `burst_length_generated_behavior: false`, adds a
support-accounted sample, keeps generated `.isf`, `.fsm`, and HDL behavior
unchanged, and moves ARLEN work into explicit generated-capture and
beat-count-validation residue. The active frontier is `.64`, the next
exact-owner selector after report-only burst-length metadata. Full multi-beat
read-data reassembly, per-beat outputs, `RRESP` aggregation, per-ID queues,
direct backend lowering, and VHDL remain deferred.
The shipped public capacity/status source accepts one
`(manager-capacity-status NAME ...)` object under
`(protocol-platform-intent ...)`, `(profile axi4)`, and top-level source
anchors, and works through schedule JSON, generated `.isf`/`.fsm` review
artifacts, HDL, `--verify-hdl`, check JSON, and normalized semantic JSON.
That source now accepts optional `(id-families ...)` metadata: separate
read/write ID-family widths, request/response ID signal-pair metadata,
zero-width absence semantics, static diagnostics, and report metadata, without
changing generated `.isf`, generated `.fsm`, or HDL behavior. Broader ID
allocation, ordering, response matching, bursts, queued/blocking policy,
profile aliases, and full AXI manager behavior remain task-tree-owned residue.
The selected
transaction-envelope subset is now shipped as optional `(transactions ...)`
metadata: machine-readable AST/structural logical read/write transaction
names, tags, request/completion event bindings, and optional requested-ID
static validation against declared ID-family widths. Request and completion
bindings may use direction-level or per-transaction events. Transactions with
concrete requested IDs now generate ID request/response assertions; auto-ID
transactions remain report-only before an allocator is selected. The completed
readiness audit verified that
distinct per-transaction request/completion events can fan into the existing
read/write capacity/status rule matrices through the current
IAL1/IAL0/SystemVerilog path. That slice now declares unique transaction event
inputs, preserves scalar one-event compatibility, generates OR fan-in guards
for multi-event groups, widens the IAL1 guard-conflict proof for bounded
OR/negated-OR generated guards, and reports additive
`transaction_event_dispatch` metadata. `IAL2-FEATURE-COMPLETENESS-FRONTIER.17`
selected a narrow concrete transaction ID assertion boundary: generated IAL1
can declare used ID-family request/response ID signals, emit assertion-only
transaction checks through `.fsm` `+assert` carriers, and reach the existing
SystemVerilog assertion emitter path without a separate substrate prerequisite.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.18` shipped that boundary. Completed
selector `.19` chose auto-ID lifecycle/request-ID drive readiness. Completed
readiness audit `.20` concluded that generated request-ID drive needs a
bounded public auto-ID pool/request-ID drive contract first, and
`IAL2-FEATURE-COMPLETENESS-FRONTIER.21` selected explicit optional
`auto-id-lifecycle` bounded-pool syntax, and
`IAL2-FEATURE-COMPLETENESS-FRONTIER.22` shipped the active parser/report
metadata frontier with `auto_id_lifecycle` report metadata, a separate public
sample, check JSON and semantic JSON support accounting, and unchanged
generated `.isf`, `.fsm`, and HDL behavior. `IAL2-FEATURE-COMPLETENESS-FRONTIER.23`
shipped bounded request-ID drive behavior for explicit lifecycle families:
request ID signals become generated outputs, selected-ID/busy state is
generated per auto transaction, allocation uses first-free pool order,
completion events release selected IDs, and runtime assertions cover
no-ID-available plus illegal same-family simultaneous requests. Completed
selector `.24` chose AXI generated response-demux readiness as the next exact
subset. Completed readiness audit `.25` selected a bounded write `BID`
response-demux public contract selector first, because existing transaction
`completion` names are authored inputs and must not be silently reinterpreted
as generated demux signals. Completed selector `.26` chose explicit optional
write-only `(response-demux (write (response-event EVENT)
(transaction-completion generated)))` syntax. In the first bounded contract,
`EVENT` must equal top-level `write-complete`, and read `RID` demux remains
future work. Completed implementation leaf
`IAL2-FEATURE-COMPLETENESS-FRONTIER.27` shipped parser/report metadata and
static validation for that explicit opt-in, including a runnable
`ppif/axi_manager_capacity_status_response_demux.ppif` sample, support
accounting, `response_demux.generated_behavior: false`, generated
transaction-completion ownership in the report, focused diagnostics, check
JSON and semantic JSON coverage, and unchanged generated `.isf`, `.fsm`, and
HDL behavior. Completed readiness audit
`IAL2-FEATURE-COMPLETENESS-FRONTIER.28` selected a small IAL1 prerequisite
before generated demux behavior: write transaction completion names under
`response-demux` must lower as one-cycle pulse actions, not ordinary sticky
flopped rule assignments. Completed implementation leaf
`IAL2-FEATURE-COMPLETENESS-FRONTIER.29` shipped bounded IAL1 `(pulse TARGET)`
rule actions for scalar outputs and scalar storage variables, lowering through
`<1` pulse-domain assignments with focused parser/lowerer/HDL coverage.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.30` shipped generated write `BID`
response-demux behavior for explicit `response-demux` contracts: `BID` is a
generated IAL1 input, transaction completion names are generated pulse outputs,
guarded demux rules pulse those completions, capacity and auto-ID release
consume the generated completion pulses, response assertions cover
unmatched/inactive and ambiguous matches, and reports remove generated write
demux residue. Completed selector
`IAL2-FEATURE-COMPLETENESS-FRONTIER.31` found the post-`.30` report still
lists `response_demux` under `auto_id_lifecycle.residue`, which is stale now
that generated demux pulses drive auto-ID release. Completed implementation
leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.32` aligns that report residue:
at that point explicit generated write demux reported
`auto_id_lifecycle.residue: [same_id_ordering]`, while non-demux lifecycle
samples kept their response demux residue. Completed selector
`IAL2-FEATURE-COMPLETENESS-FRONTIER.33` chose a same-ID ordering readiness
audit because `same_id_ordering` was then the common remaining
ID/auto-ID/write-demux residue after generated write demux and auto-ID residue
alignment. Completed
readiness audit `IAL2-FEATURE-COMPLETENESS-FRONTIER.34` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.35` as a bounded generated
auto-ID same-ID avoidance assertion/report slice. That first boundary should
make the existing unique-active selected-ID invariant explicit before per-ID
issue-order queues, authored concrete-ID same-ID ordering, read `RID` demux,
read-data interleaving/reassembly, bursts, queued policy, aliases,
full-manager behavior, or VHDL changes. Completed implementation leaf
`IAL2-FEATURE-COMPLETENESS-FRONTIER.35` now ships that boundary: generated
auto-ID families get pairwise active selected-ID assertions, reports add
machine-readable `same_id_ordering` metadata, covered generated write demux
residue removes `same_id_ordering`, and `.36` selected read response-demux
readiness as the next exact slice. Completed audit `.37` found that bounded
read `RID` response matching should not jump directly to implementation or
parser/report metadata: the public contract had to define read response scope,
event meaning, metadata requirements, diagnostics, and residue first. Completed
selector `.38` chose an explicit read arm with mandatory
`(response-scope single-beat)`, response-event equality with top-level
`read-complete`, positive-width read ID-family/read transaction/read
auto-ID-lifecycle requirements, and generated completion ownership only under
the opt-in. `.39` shipped parser/report metadata, static validation, a
runnable read-demux `.ppif` sample, check JSON/semantic JSON support
accounting, and `response_demux.read.generated_behavior: false` while leaving
generated read `.isf`, `.fsm`, and HDL behavior unchanged. `.40` audited read
behavior readiness and selected `.41`, bounded generated single-beat read
`RID` response-demux behavior, with no new IAL1/IAL0/SystemVerilog
prerequisite. `.41` now ships that behavior: generated IAL1 adds `RID` as a
response input, reclassifies selected read transaction completions as
generated pulse outputs, emits one guarded read demux rule per auto-ID read
transaction, emits read active-match and unique-match assertions, and keeps
read capacity plus auto-ID release driven by generated completion pulses. The
report marks `response_demux.read.generated_behavior: true` and leaves only
read-data interleaving and burst residue in that demux arm. `.42` selected
`.43` as a readiness audit for read-data payload, burst/`RLAST`, and per-ID
ordering/reassembly ownership after generated read demux. `.43` selected
`.44`, the bounded public read-data payload/status contract selector, before
parser/report metadata or generated behavior changes. `.44` selected
`.45`, parser/report metadata and static validation for explicit
single-beat `read-data` syntax. `.45` shipped that metadata, `.46`
selected direct generated single-beat `RDATA`/`RRESP` capture behavior, and
`.47` shipped the generated capture implementation with no new
IAL1/IAL0/SystemVerilog prerequisite. `.48` selected `.49`, AXI
burst/`RLAST` completion readiness, as the next exact prerequisite before
multi-beat read-data reassembly or broader read-side manager behavior.
`.49` selected `.50`, public burst/`RLAST` completion contract selection,
before parser/report metadata or generated behavior changes.
`.50` selected `.51`, parser/report metadata and static validation for the
additive `response-scope burst-last` plus one-bit `last-signal` read
response-demux contract, with generated behavior deferred.
Full-manager
behavior, profile aliases, queued/blocking policy, direct backend lowering,
and VHDL remain residue.

The first honest `R11` slices are now:
1. keep widening convention-first composition only where the child-side evidence is still deterministic,
2. let explicit local overrides stay precise without forcing whole-interface restatement,
3. keep pushing shared-datapath and reusable-module feature slices before returning to contract-hardening-only work,
4. keep `R8` paused except when a feature slice necessarily touches a still-unlocked boundary.
- External-RTL instantiation note:
  - `(?rtl:module)` is the shorthand instance form,
  - `(?rtl:instance module)` is the explicit alias form for reusing one declared `?rtlif:module` contract under several instance names,
  - and the first shipped parameter/generic override seam stays semantic: `.rtlif` declares scalar or bounded aggregate `(params (NAME default_value) ...)` entries, declaration defaults may use package-qualified values from imported packages, `?rtl` instances override declared names through `(params (NAME value) ...)`, aggregate overrides are checked against the `.rtlif` default's inferred aggregate shape, and the current Verilog-family backend lowers validated overrides to SystemVerilog `#(...)` instance parameters.
- Execution-cadence note:
  - after a backend/debt-reduction slice, strongly prefer the next slice to land in a visibly user-facing lane such as language contract, strict mode, diagnostics, or reusable assets,
  - and only keep stacking consolidation slices when the next feature is still materially blocked by that cleanup.
- Forward-IR note: `StructuralRTLIR` actual-connection nodes are now wider than
  plain signal references; the current bounded family includes indexed and
  sliced signal forms, including explicit-wiring source-side top-port and
  child-output projections, while keeping rendering deliberately scoped to
  the current Verilog-family backend until broader backend support is
  designed.
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
  explicit `open` actual form, because "leave this formal unconnected" is real
  structural semantics and should not be represented as a backend-specific text
  escape hatch.
- Forward-IR note: that bounded `open` / literal actual family now also has its
  first real composition producer/consumer path: explicit `?wiring` may use
  `=open`, `=0`, `=1`, exact-width `=N'b...`, exact-width `=N'd...`,
  exact-width `=N'o...`, and exact-width `=N'h...` as source actuals into
  realized child inputs without
  inventing helper nets or undeclared same-name top inputs.
- Forward-IR note: that same producer/consumer path now also covers
  source-side declared-top `bit_select` / `slice` forms such as `bus[0]` and
  `bus[7:4]`, so the already-shipped structural expression nodes now have a
  first honest composition wiring path beyond plain top-port references.
- Forward-IR note: that same producer/consumer path now also covers bounded
  flat source-side concat forms such as `header_bus,status_bus[0],=1,payload`
  over declared whole top-port refs, top-port bit/slice refs, one-bit scalar
  actuals, intrinsic-width unsized binary/decimal/octal/hex actuals, intrinsic-width unsized signed decimal actuals, intrinsic-width unsized signed binary/octal/hex actuals, and
  fixed-width binary/decimal/signed-decimal/octal/hex literal actuals in unsigned or signed form, so explicit `?wiring`
  child-input bindings can now reuse the already-shipped structural `concat`
  node directly instead of inventing carrier nets or backend-specific text
  escapes while keeping concat width intrinsic: binary/octal/hex use digit
  width, unsigned decimal now uses the minimum width required by its numeric value, and signed decimal now uses the minimum signed width required by its numeric value.
- Forward-IR note: those bounded concat forms now also preserve nested
  brace-group source structure such as
  `header_bus,{status_bus[0],=0b1_0},{payload_bus[3:2],payload_bus[1:0]}` from
  `.fsm` source through raw AST and composition parsing, so nested structural
  `concat` nodes survive file loading instead of being flattened by the source
  reader before lowering even begins.
- Forward-IR note: that same producer/consumer path now also covers bounded
  source-side repeat groups such as `{3{status_bus[0]}}` and
  `{2{producer.serial_lo}}`, with linked planning lowering them into typed
  structural `repeat` nodes instead of renderer-only text, child-output
  repeats reusing the same deterministic base carrier family as projected
  child-output operands, and omitted/empty-`?ports` inference now also
  deriving one undeclared repeated whole-port operand when the child-target
  remainder width divides evenly across the repeat count.
- Forward-IR note: explicit-link planning now also supports one realized child
  output source fanning out to multiple top outputs through one deterministic
  shared carrier net plus explicit top-output assignments, so that topology no
  longer needs to be blocked as if it required multiple independent drivers.
- Forward-IR note: explicit-link planning now also supports one declared top
  input feeding one or more top outputs directly through explicit top-output
  assignments while sibling child-input consumers reuse that same top input,
  and shared-datapath augmentation now preserves those preexisting assignments
  instead of overwriting them later in the top-runtime rewrite path.
- Forward-IR note: source-side top-port bit/slice and bounded concat
  expressions now also reach declared top outputs through those same explicit
  top-output assignments, so the already-shipped structural expression nodes
  now have a first direct top-boundary assignment path beyond child-input
  bindings.
- Forward-IR note: direct scalar `=0` / `=1` actuals plus exact-width
  `=N'b...`, `=N'd...`, `=N'o...`, and `=N'h...` literal actuals now also reach
  declared top outputs through that same explicit top-output assignment path;
  scalar `=0` / `=1` widen to the direct binding target width there and on
  realized child inputs, while `=open` remains the bounded child-input-only
  sibling because "leave this output unconnected" is not honest top-boundary
  wiring.
- Forward-IR note: omitted/empty-`?ports` top-boundary inference now also sees
  inferable `name[index]` / `name[msb:lsb]` operands inside those bounded
  concat sources, and one remaining undeclared whole-port concat operand may
  now also be sized exactly from the child-input target remainder width while
  several still-unsized whole-port operands continue to fail explicitly
  instead of guessing several widths at once.
- Forward-IR note: that same nested-concat preservation now also reaches
  declared top-output assignments and omitted-port inference, so the same
  brace-grouped source expression can drive a child input, drive a top output,
  and contribute to omitted/empty-`?ports` inference without taking different
  parser paths.
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
  split "true flat leaf carrier" from "broader dependency set," so compatibility
  fields like `bound_signal` do not silently misclassify richer expressions such
  as `member_access` or `index_access`.
- Forward-IR note: shared-datapath contributor and peer-input metadata now
  also preserve the actual typed binding expression through
  `bound_connection_expr`, so later consumers can reuse real structural AST
  nodes instead of reconstructing binding shape from names-only summaries.
- Forward-IR note: same-name shared-datapath family discovery now also
  consumes preserved declared type identity conservatively, so width-equal
  typed child output families no longer collapse into one candidate when
  their declared type contracts disagree, while uniform typed families now
  preserve one candidate-level declared type contract plus typed raw
  contributor nets.
- Forward-IR note: lifted shared-datapath runtime carriers now also live as
  explicit structural nets with declaration-kind metadata instead of existing
  only as declaration text in auxiliary HDL, and uniform typed shared
  families now carry that declared type contract onto the lifted runtime nets
  too.
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
  reusable "summary entry to true flat leaf carrier" rule through
  `binding_signal_summary_leaf_signal`, so shared-datapath planning no longer
  needs a pipeline-local copy of that typed-summary leaf-selection logic.
- Forward-IR note: that same structural helper layer now also owns the
  reusable "summary entry to rendered binding text" rule through
  `binding_signal_summary_text`, so CLI/reporting consumers no longer need to
  keep their own local `bound_connection_expr`-first rendering copy.
- Forward-IR note: that same structural helper layer now also owns the
  normalized cloned summary-export payload through
  `binding_signal_summary_metadata`, so shared-datapath contributor and
  peer-read metadata no longer need to hand-copy `bound_signal`,
  `bound_signals`, and `bound_connection_expr` in `HDLGenerator`.
- Forward-IR note: that same structural helper layer now also owns the
  reusable "binding list to per-port summary index" rule through
  `binding_signal_summaries_by_port`, so composition system-signal inference
  and shared-datapath candidate assembly no longer need to rebuild that same
  local summary map inside `HDLGenerator`.
- Forward-IR note: `StructuralRTLIR` itself now also owns explicit child
  endpoint-query helpers through `interface_endpoint`,
  `interface_signal_endpoints`, and `interface_signal_endpoint_groups`, so
  provenance/reporting consumers no longer need to hand-walk nested
  `instances` / `interface_ports` arrays for those endpoint-family queries.
- Forward-IR note: that same `StructuralRTLIR` surface now also owns top-port
  lookup and "resolved links touching endpoint X" queries through `top_port`
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
  "compatibility" concern should preserve the current monolith; any internal
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
  direct-root module-boundary, implicit-system-port, declaration-only
  storage/helper net, generated enable-wire structural assembly, generated
  enable assignment-record projection, scalar auxiliary-assignment mirror
  projection, generated-enable net source/target connectivity, direct
  input-port generated-enable RHS target connectivity, direct output-port
  source summaries, or the selected direct top generated-enable condition
  reroute inline either. Broader output-drive/always-block body consumers
  remain later exact work, broader/full direct SystemVerilog rerouting was
  deferred by `R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.1` until direct
  behavior-body/state-update/output/assertion regions have exact structural
  ownership, and VHDL rerouting through `StructuralRTLIR` is deferred by
  `R11-DIRECT-STRUCTURAL-VHDL-REROUTING.1` until the SystemVerilog-backed
  IAL0/IAL1/IAL2 path is feature complete; direct instances/links were selected
  as intentionally empty for direct roots by
  `R11-DIRECT-STRUCTURAL-INSTANCES-LINKS.1`. The next honest seam
  is now the remaining direct-path backend
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
  lane's explicit passthrough validation, implicit top-port inference, or
  direct passthrough link/binding assembly.
- Forward-IR note: another real composition-plan family split is now active
  too: bounded declared connect-by-name `C4` link construction now lives in
  `FSM::Composition::DeclaredByNameLinkBuilder`, so `HDLGenerator` no longer
  owns that family's system-port exclusion, same-name endpoint matching,
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
  that family's inferred top-input fanout, inferred top-output selection, or
  inferred internal same-name carrier rules directly.
- Forward-IR note: another real composition-planning family split is now
  active too: generic explicit-link linked-plan assembly for the active
  `C2`/`C3`/`C4` lanes now lives in `FSM::Composition::LinkedPlanBuilder`, so
  `HDLGenerator` no longer owns that family's system auto-wiring, endpoint
  resolution, role/width validation, deterministic carrier-net allocation, or
  realized-child rebinding logic directly.
- Forward-IR note: another real composition-planning family split is now
  active too: inferred multi-child top-port projection now lives in
  `FSM::Composition::TopPortInferenceBuilder`, so `HDLGenerator` no longer
  owns explicit-wiring top-port inference or undeclared same-name top-input
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
  owns that reporting family's structural/intent projection logic directly.
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
  so `FlattenedDT::Orchestrator` no longer hand-composes prescan preparation,
  prepared-block stage preparation, pre-generation operand-contract validation,
  and rendering inline and the older
  `FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateGenerationSupport`
  now survives only as a compatibility shell over that real live owner.
- Forward-IR note: the older direct post-flattening SystemVerilog assembly
  package in
  `FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPipelineSupport`
  now survives only as a pure compatibility shell over the live
  `FSM::HDL::FlattenedDT::Backend::SystemVerilog::PostFlatteningAssemblySupport`
  owner, with no implicit owner construction fallback, and
  `FlattenedDT::Orchestrator` now delegates post-flattening scaffold /
  declaration / enable / stage / tail assembly after reset, module attachment,
  and decision-tree flattening.
- Forward-IR note: final-emission operand and assignment-width validation
  regressions now drive the live `PostFlatteningAssemblySupport` owner directly
  in `t/269-systemverilog-operand-contract-validation-support.t` and
  `t/270-systemverilog-assignment-width-contract-validation.t`, leaving
  `t/232-systemverilog-generation-pipeline-support.t` as the dedicated
  `GenerationPipelineSupport` compatibility-shell anchor rather than the main
  proof of the live validation path.
- Forward-IR note: the older direct pre-stage SystemVerilog generation-
  prelude package in
  `FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPreludeSupport`
  now survives only as a compatibility shell, and the live
  `PostFlatteningAssemblySupport` owner now composes direct
  scaffold/internal-declaration assembly, direct enable-condition generation,
  and the prescan-aware consolidated intermediate stage.
- Forward-IR note: the paired live direct pre-stage SystemVerilog
  enable-oriented preparation package in
  `FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationEnablePreparationSupport`,
  now survives only as a compatibility shell, and the live direct backend
  no longer depends on that shell to reach enable-condition generation or
  the extracted prescan-preparation composition before consolidated
  intermediate generation.
- Forward-IR note: the paired live direct pre-stage SystemVerilog
  prescan-preparation family now also has an explicit owner in
  `FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationPrescanPreparationSupport`,
  so the live consolidated-intermediate stage owner now reaches idempotent
  logical-operation counting plus WEN/EN prescan before prepared-block
  reconstruction.
- Forward-IR note: the older direct pre-stage SystemVerilog structural
  prelude package in
  `FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationStructuralPreludeSupport`
  now survives only as a compatibility shell, and the live direct backend now
  reaches header/module/state/internal-declaration assembly directly instead
  of routing through either of the older generation wrappers.
- Forward-IR note: the paired live direct post-stage SystemVerilog generation
  tail family now also has an explicit owner in
  `FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationTailSupport`,
  and the live `PostFlatteningAssemblySupport` owner now consumes it after
  consolidated intermediate generation, while the older generation-pipeline
  shell delegates instead of owning that closeout inline.
- Forward-IR note: the paired live direct recursive decision-tree flattening
  family now also has an explicit owner in
  `FSM::HDL::FlattenedDT::DecisionTreeFlatteningSupport`, so
  `FlattenedDT::Orchestrator` no longer owns recursive regular-state and
  standalone-DT flattening inline before direct backend text assembly.
- Forward-IR note: the first semantic scalar-type-property widening beyond raw
  width is now shipped too: signed scalar aliases live in the bounded
  `+types` lane, direct-root `+size` plus composition `?ports` preserve that
  signedness into emitted SystemVerilog declarations, and canonical
  `symbol_contract` type specs now preserve `signed` beside `width` without
  exposing raw backend type spellings as the source-language contract.
- Forward-IR note: the next semantic scalar-type-property widening beyond raw
  width and signedness is now shipped too: explicit `(two_state ...)` and
  `(four_state ...)` scalar aliases live in that same bounded `+types` lane,
  direct-root `+size` plus composition `?ports` preserve that state-model
  intent into emitted SystemVerilog `bit` / `logic` declarations, and
  canonical `symbol_contract` type specs now preserve `state_model` beside
  `width` and `signed` without exposing raw backend type spellings as the
  authored source-language contract.
- Forward-IR note: the first packed aggregate-type widening on top of that
  bounded `+types` lane is now shipped too: `(list ...)` and
  `(record (field TYPE) ...)` aliases resolve through the same declarative
  type/import lane across direct roots, composition tops, and semantic
  packages, direct-root `+size` plus composition `?ports` may use those
  aggregate aliases including local aliases with nested imported package type
  members, canonical `symbol_contract` / mirrored `module_info` now preserve
  aggregate type shape plus authored `member_order`, and the current live SV
  lowering keeps the authored contract honest by mapping those aggregate types
  to packed vector widths instead of frontend-shaped typedef syntax.
- Forward-IR note: the next honest typed-boundary step on top of that shipped
  `+types` lane is now landed too: when a live direct-root `+size`,
  composition `?ports`, or realized generated-child interface boundary comes
  from a named type alias, `structural_rtl_ir` plus mirrored `module_info`
  now preserve `declared_type_name` and canonical `declared_type_spec`
  instead of flattening authored type identity down to width, signedness, and
  state-model only.
- Forward-IR note: that preserved declared-type boundary now also feeds the
  live same-name composition contract: undeclared top-port inference, plain
  explicit top-port same-name convention, declared `=name` connect-by-name,
  and inferred same-name internal-carrier re-export now reject width-equal
  but declared-type-incompatible child families, and inferred undeclared top
  ports preserve one shared declared type contract when the eligible child
  evidence is uniform.
- Forward-IR note: that same declared-type boundary now also feeds the live
  explicit-link port-to-port path, so plain `?wiring` bindings no longer
  bypass declared type compatibility just because the author spelled the link
  explicitly; width-equal but alias-incompatible endpoints are now blocked on
  that path too, with the bounded failure-summary surface preserving concise
  child-endpoint or top-port context for those mismatches.
- Forward-IR note: inferred composition carrier nets now also preserve
  `declared_type_name` plus canonical `declared_type_spec` when they are
  driven by one typed child-output family, so the structural RTL handoff no
  longer drops named aggregate/scalar type identity at internal net boundaries
  before later aggregate-aware lowering or embedder inspection can consume it.
- Forward-IR note: whole named aggregate actual roots on the bounded
  explicit-actual path now also consume that same declared-type boundary when
  they bind directly to typed aggregate targets, so width-equal but
  aggregate-shape-incompatible `=FRAME`-style direct actuals are now blocked
  explicitly instead of slipping through on packed width alone.
- Forward-IR note: direct-root whole aggregate RHS assignments now also
  consume that same declared-type boundary before emission, so `(OUT = FRAME)`
  no longer slips through typed aggregate `+size` targets on packed width
  alone when the preserved target aggregate contract is shape-incompatible.
- Forward-IR note: source-side top expressions and child expressions now also
  consume that same declared-type boundary on direct explicit-link targets, so
  width-equal but aggregate-shape-incompatible concat/repeat/bit-slice/whole-
  signal expression sources are now blocked explicitly instead of slipping
  through typed composition planning on packed width alone.
- Forward-IR note: the next typed binding-handoff slice is now also landed:
  realized composition-plan instance bindings plus exported
  `structural_rtl_ir` instance bindings now preserve `connection_type_name`
  and canonical `connection_type_spec` whenever one typed source contract is
  already known, so typed signal bindings, source expressions, and whole
  aggregate actual roots no longer drop back to width-only binding metadata
  before later lowering, reporting, or embedder inspection.
- Backend-lowering note: the next aggregate-aware final-mile slice is now also
  landed across the Verilog-family generated surfaces: structural
  SystemVerilog emission and the direct generated-module SystemVerilog backend
  now synthesize backend-owned local packed typedefs for declared aggregate
  aliases, so typed top ports, typed structural nets, direct module ports, and
  direct internal/helper declarations no longer flatten all the way back to raw
  vector declarations at the final emitted HDL boundary. The next honest seams
  are broader inference-first aggregate access, VHDL aggregate lowering, and
  public type/export surface stabilization rather than packed-width-only
  direct SV declaration emission.
- Backend-lowering note: the first direct typed aggregate expression slice is
  now also landed. Declared aggregate direct-root signals can be read through
  typed AST member/list paths such as `FRAME.tag` and `FRAME.payload[1]`, list
  indexes render through the generated packed typedef fields such as
  `.item_1`, and partial aggregate LHS writes now map through the declared
  aggregate path to packed base-signal ranges before mux emission.
- Forward-IR note: the matching bounded composition source-expression slice is
  now also landed. Explicit `?wiring` sources may read declared aggregate
  top-port members/items such as `in_frame.tag` and `in_frame.payload[1]`, and
  declared aggregate generated-child output members/items such as
  `producer.OUT_FRAME.tag` and `producer.OUT_FRAME.payload[1]`. Generated-child
  aggregate projections reuse one typed child-output carrier before applying
  member/item access, and authored list indexes lower through the same
  generated packed-typedef field convention such as `.item_1`.
- Reporting/embedding note: the composition provenance endpoint surface now
  resolves those aggregate source paths against preserved declared type specs
  too, so `in_frame.tag`, `in_frame.payload[1]`, and
  `producer.OUT_FRAME.payload[1]` report leaf width/type facts instead of
  falling back to whole-base widths or generic bit/slice defaults.
- Ownership note: aggregate path traversal now has a shared package-level owner
  in `FSM::Package::AggregatePathSupport`, so direct typed aggregate
  `AggregateRef` parsing, composition explicit-link planning, and composition
  provenance reporting consume the same record/list/scalar path semantics
  rather than keeping parallel walkers that could drift. The composition helper
  now adds only structural connection-expression lowering on top of those
  frontend-neutral path segments, and direct assignment lowering consumes the
  same owner for packed base-signal range projection on partial aggregate LHS
  writes.
- Validation note: partial aggregate LHS normalization now preserves
  per-assignment whole-aggregate source/target contracts through the
  base-signal mux lowering step, so pre-generation validation compares values
  like `TAIL` assigned to `OUT.payload` against the `payload` leaf type
  contract rather than the normalized whole `OUT` contract, while
  width-equal but shape-incompatible leaf writes still fail before emission.
  The contract is now locked through direct pipeline/CLI coverage too, and the
  backend validator fallback delegates target-contract extraction to the
  assignment-support owner instead of carrying a second AST walker.
- Pack/deconstruct note: the first direct RHS pack slice is now shipped.
  Direct assignments accept `(concat ...)` and `(cat ...)`, preserve a
  `CoreAST::Concatenation` node, emit SystemVerilog concat text from that AST,
  and feed exact summed operand width into the existing pre-generation
  assignment-width contract so mismatches fail before emission with the
  authored RHS expression in the diagnostic. When a direct RHS concat drives a
  declared aggregate target, the frontend also infers an ordered source
  aggregate contract before generation: typed list targets compare against the
  concat operand list, nested concat operands keep nested list shape, and typed
  record targets can map exact top-level operands onto record member order.
  That blocks width-equal but shape/order-incompatible concat assignments
  before HDL emission. The matching bounded LHS deconstruct form is now
  shipped too: deconstruct fragments aligned to RHS concat operands keep those
  operands instead of selecting from a whole concat blob, and nested RHS concat
  fragments now preserve aligned nested operand list shape plus target-aware
  record member mapping before the pre-generation validator runs. The
  CoreAST aggregate-expression type-shape inference for those pack/deconstruct
  paths now has one package owner,
  `FSM::Package::AggregateExpressionTypeSupport`, consumed by both the direct
  parser and EnableGraph capture path with local exact-width resolvers instead
  of parallel concat/list/record walkers.
- Documentation note: once `docs/USER_GUIDE.md` becomes too large to stay
  approachable, the preferred shape is a book-like docs set with one Markdown
  file per major topic, a landing-page/table-of-contents role for
  `docs/USER_GUIDE.md`, and progressive beginner-to-advanced examples rather
  than one monolithic reference wall.
- Documentation planning note: that split is now concrete enough to plan
  immediately, and the live migration outline now lives in
  [docs/BOOK_PLAN.md](docs/BOOK_PLAN.md)
  rather than only in steering notes.
