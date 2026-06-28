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
- Deep semantic introspection is now a first-class FSMGen feature, tracked by
  [docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md](docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md).
  The selected rule is stable semantic API first and MCP as a required adapter
  over that API. `SEMANTIC-INTROSPECTION-MCP-FRONTIER.3` shipped a
  manifest-advertised `semantic_introspection` section over existing
  capability, check JSON, normalized semantic JSON, schedule JSON,
  support-accounting, diagnostics, documentation/example, embedding, and
  backend-validation surfaces. `SEMANTIC-INTROSPECTION-MCP-FRONTIER.4` shipped
  `bin/fsmgen-mcp`, the first read-only local JSON-RPC stdio adapter over that
  contract; write/generation MCP tools remain disabled.
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
- downstream-visible changes keep the codebase, downstream handoff/integration
  docs, public contracts, capability-manifest metadata, support-accounting
  catalog entries, tests, and mdBook in lockstep for every downstream consumer.

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
- Downstream tools, including SPECFORGE, may target `.isf` from their own
  intent representations; FSMGen owns scheduling, cycle inference, conflict
  analysis, and lowering.
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
- `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER` completed the current
  task-tree owner frontier for this horizon. Its `.2.1` leaf records that
  every future variant or implementation must satisfy FSMGen's public
  contracts and stay on par with the Perl reference/oracle. Its `.2.2`
  readiness audit separated
  backend-neutral public contracts from current Perl implementation details
  and selected exact future leaves. The `.2.3` leaf selected a portable
  in-memory request/result API family with JSON-safe envelopes and virtual
  artifacts. The `.2.4` leaf selected a source-catalog plus artifact-sink host
  abstraction. The `.2.5` leaf selected the Perl-reference parity harness and
  normalization rules. The `.2.6` leaf selected the mdBook language-X
  implementation blueprint structure and added the implementation-blueprint
  chapter. The `.2.7` leaf selected typed extension/plugin support as out of
  scope for the first non-Perl implementation experiment unless a future
  portable extension API is selected first. The `.2.8` leaf selected the
  same-repository Rust/Rust-Wasm portable API smoke as the first implementation
  experiment. The `.3.1` leaf scaffolded the additive `fsmgen_portable_api`
  Rust contract crate with fail-closed unsupported-operation behavior and no
  shipped Perl runtime integration. The `.3.2` leaf added the first direct
  `.fsm` check smoke for `feature.direct_sreset_active_high` only, with all
  other Rust check sources and non-check operations still fail-closed. The
  `.3.3` leaf added Perl-oracle parity for that result through a Rust
  projection binary and a focused normalized comparison against the Perl
  check-JSON oracle.
- SystemVerilog-to-Verilog portability should default to FSMGen-owned
  generation/lowering instead of a mandatory external converter dependency.
  External converters such as `sv2v` are audit candidates only: they may be
  optional validation aids, or explicitly selected dependencies only if a
  later owned audit proves exceptional quality and coverage.

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

### H4a. IAL2 protocol onboarding workflow
Future FSMGen-owned protocol support must follow the reusable IAL2 workflow in
[docs/IAL2_NEW_PROTOCOL_SUPPORT_WORKFLOW.md](docs/IAL2_NEW_PROTOCOL_SUPPORT_WORKFLOW.md).
The workflow captures the AXI/APB-proven sequence: source evidence, readiness
audit, public contract selection, bounded parser/report/generator behavior,
generated `.isf` and `.fsm` review artifacts, runnable examples, support
accounting, diagnostics, mdBook coverage, Knowledge Map continuity, doctrine
gates, and per-slice commits.

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
The active immediate priority is now first-class semantic introspection and
MCP-queryable FSMGen semantics under
[docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md](docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md).
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.2` activated that lane,
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.3` shipped the manifest-advertised
`semantic_introspection` contract, and
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.4` shipped the first read-only MCP adapter
over that contract. The shipped adapter exposes capabilities, contracts,
diagnostics, support accounting, examples, source check JSON, normalized
semantic JSON, and schedule previews through `bin/fsmgen-mcp` without enabling
write/generation, network, shell, mutation, commit, or push tools.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.5` hardened protocol/client behavior with
JSON-RPC error-code policy, notification handling, malformed percent-encoding
rejection, and non-leaking source-query provenance.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.6` added `fsmgen_support_summary`,
bounded support-accounting aggregates, support-aware example discovery, and
diagnostic explanations linked to support-accounting examples.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.7` documented generic read-only MCP
client configuration and bounded one-shot workflows for capabilities, support
summaries, diagnostics, examples, check JSON, semantic JSON, and schedule
previews. `SEMANTIC-INTROSPECTION-MCP-FRONTIER.8` added bounded read-only MCP
schema snapshot fixtures plus a client compatibility matrix for the shipped
one-shot and MCP 2025-06-18 newline-delimited JSON-RPC stdio profile.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.9` locked that stdio framing boundary
with a focused no-embedded-newline guard and keeps Streamable HTTP, prompts,
sampling, completions, client roots consumption, service mode, and write tools outside
the shipped profile. `SEMANTIC-INTROSPECTION-MCP-FRONTIER.10` selected
explicit `--workspace-root` as the only shipped source authority; MCP client
roots are not consumed yet and source escapes remain fail-closed before any
runner invocation. `SEMANTIC-INTROSPECTION-MCP-FRONTIER.11` keeps prompt
templates unadvertised until a separate prompt contract can be selected and
snapshot-tested. `SEMANTIC-INTROSPECTION-MCP-FRONTIER.12` keeps resource
subscriptions and list-change notifications unadvertised, with static
resources reporting `listChanged: false`. `SEMANTIC-INTROSPECTION-MCP-FRONTIER.13`
keeps `completion/complete` unsupported until a bounded candidate provider is
selected. `SEMANTIC-INTROSPECTION-MCP-FRONTIER.14` keeps MCP logging
unsupported; adapter diagnostics remain JSON-RPC errors and structured
payloads. `SEMANTIC-INTROSPECTION-MCP-FRONTIER.15` keeps list responses
bounded and unpaginated: resource/template/tool listings emit no `nextCursor`,
and client-supplied cursors are invalid params until a paginated profile is
selected. `SEMANTIC-INTROSPECTION-MCP-FRONTIER.16` keeps sampling and
elicitation unsupported; the adapter does not initiate model calls or
user-input requests through MCP. `SEMANTIC-INTROSPECTION-MCP-FRONTIER.17`
keeps transport bounded to one-shot `--request-json` and newline-delimited
stdio; Streamable HTTP and service mode remain unshipped.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.18` ships MCP `structuredContent` for
read-only tool results while retaining serialized JSON text compatibility.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.19` ships compact per-tool
`outputSchema` metadata for stable public envelope fields while leaving
volatile nested reports and catalog internals schema-light.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.20` ships MCP tool annotations for the
read-only profile: every current tool is marked `readOnlyHint: true` and
`openWorldHint: false`, while write-only destructive/idempotent hints remain
absent. `SEMANTIC-INTROSPECTION-MCP-FRONTIER.21` keeps common MCP annotations
absent from resources, templates, resource-read content, and tool-result text
blocks, and does not return resource links from tools.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.22` keeps progress/cancellation session
behavior unshipped: request progress tokens do not emit progress
notifications, and id-less `notifications/cancelled` messages remain silent.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.23` explicitly rejects JSON-RPC batch
arrays and non-object request envelopes with `-32600 Invalid Request`; the
stdio profile remains one compact request object per line.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.24` locks initialize negotiation to the
single supported `2025-06-18` protocol version and keeps client
capabilities from widening the server's minimal resources/tools capability
set. `SEMANTIC-INTROSPECTION-MCP-FRONTIER.25` keeps JSON-RPC errors
message-only and sanitized, with no `error.data` until a bounded data schema
is selected. `SEMANTIC-INTROSPECTION-MCP-FRONTIER.26` adds stable
`serverInfo.title` metadata while keeping instructions compact and read-only.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.27` exhausts the immediate MCP
protocol-hardening pass: remaining optional MCP feature families are either
shipped, explicitly unsupported for the read-only profile, or deferred behind
future exact owners. The next frontier is
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.28`, read-only source/workspace discovery
selection. `SEMANTIC-INTROSPECTION-MCP-FRONTIER.28` selects catalog-backed
source discovery over existing manifest/support/example surfaces, not
arbitrary workspace traversal. `SEMANTIC-INTROSPECTION-MCP-FRONTIER.29` ships
that catalog-backed discovery as `fsmgen://sources` and
`fsmgen_discover_sources`, returning only repo/workspace-relative source
identities with file kind, source kind, available read-only query kinds, and
support-accounting metadata under query/limit/filter controls.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.30` closes the immediate read-only
semantic-introspection/MCP pass after source discovery. The IAL2
feature-completeness tree has shipped
`IAL2-FEATURE-COMPLETENESS-FRONTIER.223`, bounded dynamic write
transaction-ID capture and `BID` response matching.
`DOCTRINE-ENFORCEMENT-ADOPTION.1` now adopts the portable doctrine-enforcement
driver, root `DOCTRINE_ENFORCEMENT.md`, root `TOOLBOX.md`, the
`scripts/check_doctrines.sh` registry, and FSMGEN-native issue-pinpointing
commands. `IAL2-FEATURE-COMPLETENESS-FRONTIER.227` now ships generated bounded
single-beat dynamic read transaction-ID capture and `RID` response matching:
explicit `response-demux.read` with one transaction-local dynamic read ID
captures admitted `ARID`, stores generated selected-ID/busy state, matches raw
read responses with `RID == captured_id`, pulses the generated read completion,
and support-accounts the new dynamic read PPIF sample. `.231` now ships the
bounded dynamic read burst-last/`RLAST` sibling: explicit
`response-demux.read` with one dynamic read transaction, `response-scope
burst-last`, one-bit `last-signal`, admitted `ARID` capture, generated
selected-ID/busy state, generated completion on matched `RID && RLAST`, busy
release, `bounded_dynamic_read_rid_rlast_demux_contract` reports, and
`ppif/axi_manager_capacity_status_dynamic_read_response_demux_burst_last.ppif`
as a support-accounted sample. `.232` selected `.233`, readiness audit for
dynamic read-data routing over the generated single-active dynamic read
response-demux family. `.233` selected `.234`, direct bounded implementation
of scalar dynamic read-data capture for the generated dynamic read single-beat
and burst-last/`RLAST` demux shapes. `.234` now ships that bounded scalar
dynamic read-data behavior with support-accounted single-beat and last-beat
PPIF samples, generated `RDATA`/`RRESP` capture, dynamic completion-validity
report vocabulary, and explicit fail-closed residue. `.235` selected `.236`,
AXI manager focused-suite cost cleanup, before any broader dynamic behavior
change because the primary AXI manager parser/generator focused suites are no
longer routine closeout surfaces. `.236` now adds
`t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t`, a bounded focused
target for the shipped dynamic transaction-ID family, and selects `.237`,
readiness audit for dynamic burst-length capture over generated dynamic
last-beat read-data. `.237` now selects `.238`, direct bounded report-only
raw-`ARLEN` burst-length capture over generated dynamic last-beat read-data.
`.238` now ships that report-only dynamic raw-`ARLEN` capture, and `.239`
selects `.240`, direct bounded generated dynamic beat-count/`RLAST` runtime
validation over the same generated dynamic last-beat boundary.
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
ARLEN/max-beats fields, adds a support-accounted sample, and moves ARLEN work
into explicit generated-capture and beat-count-validation residue. Selector
`.64` chose `.65`, a generated ARLEN burst-length capture readiness audit,
because generated capture is the next prerequisite before
validation/reassembly but adds a new HDL input/storage/request-event path that
must be audited before behavior changes. Audit `.65` found no new
IAL1/IAL0/SystemVerilog substrate prerequisite and selected `.66`; `.66`
ships generated raw-ARLEN capture with a width-8 `axi0_arlen` input,
per-transaction raw-ARLEN storage, request-event guarded capture rules,
`.fsm`/SystemVerilog lowering, and generated burst-length input/storage/rule
report fields. Audit `.67` finds the IAL1/IAL0/SystemVerilog substrate ready
for generated beat-count/RLAST validation, but preserves `validation
report-only` as no-runtime-check behavior. Selector `.68` selects
`(validation runtime-assertion)` with normalized report value
`runtime_assertion`, preserves `validation report-only`, and requires parser
support plus generated runtime assertions to ship together. Implementation
`.69` ships that first generated beat-count/RLAST runtime-validation
implementation: `.ppif` accepts `validation runtime-assertion`, generated
IAL1/.fsm/SystemVerilog include expected-beat storage, matched-beat counters,
runtime validation rules/assertions, and schedule JSON reports generated
validation artifacts while `validation report-only` remains no-runtime-check
behavior. Selector `.70` chooses `.71`, public AXI multi-beat read-data
reassembly/output contract selection. Selector `.71` chooses the first public
multi-beat contract as `capture-scope multi-beat` with mandatory ARLEN
`burst-length` runtime assertions, per-beat status, `multi-beat-by-rid`
interleaving, per-transaction data/status output prefixes, valid-mask outputs,
and length outputs. Implementation `.72` ships parser/report metadata and
static validation for that syntax, adds the support-accounted
`ppif/axi_manager_capacity_status_read_data_multi_beat.ppif` fixture, reports
generated lane names, valid-mask widths, length-output widths, and the
selected output-bank shape. Audit `.73` finds no new
IAL1/IAL0/SystemVerilog prerequisite for the first generated output-bank
behavior. Implementation `.74` ships that behavior: generated `RDATA`/`RRESP`
inputs, per-transaction data/status lane outputs, valid-mask outputs, length
outputs, request-time output-bank clearing, lane capture rules guarded by
matched read beat plus `!request_event` plus current beat-count equality, and
generated multi-beat artifact report fields. Schedule JSON reports
`multi_beat_reassembly_generated_behavior: true` and reduces read-data
residue to `rresp_aggregation`. Selector `.75` selects `.76`, public scalar
`RRESP` aggregation contract selection, before parser/report metadata or
generated behavior changes. Selector `.76` selects additive scalar `RRESP`
aggregation syntax: read-level `(status-aggregation (policy worst-observed))`
plus transaction-local `(status-aggregate-output NAME)`, with normalized
report spelling `worst_observed`. Per-beat status lanes remain mandatory,
width-3 responses stay deferred. Implementation `.77` ships parser/report
metadata and static validation for that contract: the public multi-beat sample
now accepts `status-aggregation`, reports `status_aggregation` as
`worst_observed`, marks `status_aggregation_generated_behavior: false`,
reports per-transaction scalar aggregate output names/widths, and narrows
read-data residue to `generated_rresp_aggregation` while preserving the
existing generated output-bank `.isf`, `.fsm`, and HDL behavior. Audit `.78`
finds no new IAL1/IAL0/SystemVerilog prerequisite for first generated width-2
`worst_observed` scalar behavior: request-time `OKAY` initialization,
matched-beat numeric max updates under the existing `!request_event`
boundary, scalar aggregate outputs, report artifact movement, and
`generated_rresp_aggregation` residue removal can ship directly.
Implementation `.79` ships that behavior: generated scalar aggregate outputs,
request-time `2'd0` initialization in the existing output-bank init rules,
matched-beat max updates under `!request_event`, generated aggregate
output/init/update report fields, and read-data residue with
`generated_rresp_aggregation` removed. Selector `.80` chooses `.81`, AXI
per-ID read-data interleaving and queue readiness, as the next exact audit.
Audit `.81` finds the covered generated auto-ID multi-beat sample already has
bounded `multi_beat_by_rid` output-bank behavior under generated same-ID
avoidance, matched-`RID` response demux, and independent per-transaction beat
counters/output banks. It selects `.82`, report/static residue alignment that
removes over-broad `read_data_interleaving` residue only for that covered
generated subset before any new behavior.
Implementation `.82` ships that alignment: public multi-beat reports now
leave only `bursts` in `response_demux.residue`, remove
`read_data_interleaving` from `same_id_ordering.residue` for the covered
generated auto-ID multi-beat-by-RID subset, preserve concrete-ID same-ID and
per-ID queue residue, and keep generated `.isf`, `.fsm`, and SystemVerilog
behavior unchanged. Selector `.83` chooses `.84`, AXI burst payload/output
readiness, because `bursts` is now the only `response_demux` residue and
remains shared with `same_id_ordering` while the public multi-beat sample
already has burst-last `RLAST` demux, raw ARLEN capture, beat-count/RLAST
runtime validation, per-beat output banks, valid masks, length outputs, and
scalar aggregate `RRESP`. Audit `.84` selects `.85`, report/static `bursts`
residue alignment for the covered generated auto-ID multi-beat output-bank
subset, because the selected per-beat output bank is already the bounded burst
payload/output shape for that subset. Packed/full burst assembly remains a
separate deferred contract.
Implementation `.85` ships that alignment: the public multi-beat sample now
reports `response_demux.residue: []` and `same_id_ordering.residue:
[concrete_id_same_id_ordering, per_id_issue_order_queues]` while
`read_data.residue` stays empty. Generated `.isf`, `.fsm`, and SystemVerilog
behavior is unchanged. `.85` advanced the frontier to `.86`, the next AXI
manager feature-completeness selector. `.86` also carries the IAL2 factoring
question: shared common IAL2 constructs should be kept to a small semantic core
and only promoted from protocol/platform vocabularies after reuse is proven
across multiple profiles.
Selector `.86` chooses `.87`, AXI concrete-ID same-ID ordering readiness. The
public multi-beat sample now leaves only `concrete_id_same_id_ordering` and
`per_id_issue_order_queues` under `same_id_ordering.residue`; concrete-ID
samples still keep `same_id_ordering` under `id_response_rule_engine.residue`.
Audit `.87` selects `.88`, conservative fail-closed static validation for
multiple concrete-ID transactions in the same read or write response family
that share one concrete ID value. Existing concrete-ID equality assertions do
not prove same-ID response issue order, and an in-memory probe confirms the
pre-`.88` generator accepted same-ID concrete pairs with unique events while
leaving `same_id_ordering` as residue. Implementation `.88` now rejects that
unsupported same-family concrete-ID reuse with a fail-closed diagnostic while
leaving currently valid single-concrete-ID samples behavior-stable. Selector
`.89` chooses `.90`, AXI per-ID issue-order queue readiness, before any
accepted concrete-ID same-ID reuse behavior, queue/scoreboard substrate,
public same-ID reuse policy, concrete response-demux behavior, or report/static
residue refinement ships. Audit `.90` selects `.91`, AXI same-ID reuse policy
contract selection, because the missing prerequisite is not a smaller lowering
feature but an explicit public source/report contract for reject, queue,
stall/block, or scoreboard semantics. Selector `.91` chooses an optional
AXI-profile-local `same-id-ordering` clause with read/write
`concrete-id-reuse reject` arms and selects `.92`, parser/report metadata plus
static validation for that explicit reject policy. Implementation `.92` now
accepts one optional `(same-id-ordering ...)` PPIF clause, emits additive
`same_id_ordering.mode: concrete_id_reuse_policy` report metadata with
`generated_queue_behavior: false`, preserves the `.88` omitted-policy
diagnostic, emits a policy-specific duplicate concrete-ID diagnostic for
explicit `reject`, and leaves generated `.isf`, `.fsm`, and SystemVerilog
unchanged for valid sources. It advances the frontier to `.93`, the next AXI
manager selector before any accepted same-ID reuse, generated per-ID queue,
or scoreboard behavior. Selector `.93` chooses `.94`, AXI same-ID issue-order
queue policy contract selection, before parser/report metadata or generated
queue behavior. That contract-selection leaf must define the public
`issue-order-queue` spelling, read/write family scope, depth bounds,
enqueue/dequeue semantics, queue-head response-demux expectations,
diagnostics, report vocabulary, validation gates, and rollback boundary before
accepted same-ID reuse can ship. Selector `.94` chooses family-local
`(concrete-id-reuse issue-order-queue)` under the existing
`same-id-ordering` clause, derives queue bounds from family `max-pending` and
the concrete transaction inventory rather than a new source depth clause, and
requires queue-head response demux before accepted same-ID reuse can be
reported. It selects `.95`, AXI same-ID issue-order queue behavior readiness,
because the current response-demux behavior is auto-ID-oriented and direct
parser/report acceptance would be unsafe before the queue-head behavior split
is audited. Audit `.95` finds generated queue-head behavior is not ready as a
direct next slice: response demux is still selected-ID auto-ID matching,
concrete transactions have no queue-head state, and queue enqueue needs an
admitted per-transaction request boundary. It selects `.96`, metadata-first
parser/report support for `issue-order-queue`, with
`implementation_status: selected_not_generated`, `accepted_same_id_reuse:
false`, `generated_queue_behavior: false`, and duplicated concrete same-ID
reuse still fail-closed until generated queue-head behavior ships.
Implementation `.96` ships that metadata boundary: PPIF accepts
`(concrete-id-reuse issue-order-queue)` under read/write `same-id-ordering`
arms, schedule JSON reports `policy: issue_order_queue`,
`implementation_status: selected_not_generated`,
`accepted_same_id_reuse: false`, and `generated_queue_behavior: false`, and
duplicated concrete same-ID transactions still fail closed with a
selected-not-generated diagnostic. The new support-accounted sample is
`ppif/axi_manager_capacity_status_same_id_issue_order_queue_policy.ppif`.
Audit `.97` selects the admitted per-transaction request boundary as the next
safe prerequisite before queue state. Implementation `.98` ships that admitted
request boundary: selected `issue-order-queue` families emit one internal
admitted-request pulse storage target and one pulse rule per concrete
transaction, guarded by the transaction request event, current capacity
storage, family `max-pending`, and same-cycle completion fan-in rather than
the generated `can_accept` output value. Schedule JSON reports
`enforcement: admitted_request_boundary`,
`implementation_status: admitted_request_pulses_generated`,
`accepted_same_id_reuse: false`, `generated_queue_behavior: false`, and the
generated pulse/rule/guard payload under the selected family. Duplicated
concrete same-ID reuse, queue storage, dequeue rules, queue-head response
demux, accepted same-ID reuse, direct backend, and VHDL remain deferred. The
active frontier advances to `.99`, the post-admitted-request-pulse AXI
manager selector. Selector `.99` chooses `.100`, AXI same-ID issue-order queue
state and queue-head demux readiness audit. Direct queue-state implementation
is premature because admitted request pulses solve only the enqueue boundary;
accepted same-ID reuse still needs bounded queue storage, enqueue/dequeue
semantics, queue-head response demux, duplicate-ID validation changes,
assertions, and residue movement to be audited together before generated
behavior changes.
Audit `.100` confirms the existing generated response demux is still auto-ID
busy/selected-ID matching, including the read burst-last path, while the
selected same-ID sample still reports `accepted_same_id_reuse: false` and
`generated_queue_behavior: false`. Queue-head demux therefore needs queue
identity state first, and direct queue-state behavior remains too broad until
the representation is selected. The active frontier advances to `.101`,
bounded AXI same-ID issue-order queue state representation selection, before
duplicate concrete same-ID reuse, generated queue behavior, queue-head demux,
direct backend, or VHDL behavior can change.
Selector `.101` chooses `compact_onehot_transaction_slots`: family-local and
concrete-ID-value-local compacted slots, slot `0` as head, one explicit
transaction identity bit per slot/transaction, and depth bounded by
`min(max-pending, concrete transaction inventory)`. The representation avoids
arrays, dynamic indexed left-hand sides, hidden unbounded queues, and pointer
modulo arithmetic, and keeps enqueue sourced only from admitted request
pulses. It also confirms implementation remains gated by a concrete same-ID
queue-head response-demux source contract because current `response-demux`
syntax and behavior require auto-ID lifecycle state. The active frontier
advances to `.102`, AXI same-ID queue-head response-demux contract selection.
Selector `.102` reuses the existing public `response-demux` read/write arms
for concrete same-ID queue-head demux when the same family selects
`concrete-id-reuse issue-order-queue`, has duplicate concrete-ID groups, and
does not also require same-family auto-ID demux in the first contract. Write
uses `bounded_write_bid_queue_head_demux_contract`; read uses
`bounded_read_rid_queue_head_demux_contract` for `single-beat` or
`burst-last` scope. Behavior remains selected-not-generated, and the active
frontier advances to `.103`, parser/report metadata and static validation for
the selected contract.
Implementation `.103` ships selected-not-generated parser/report metadata and
static validation for that contract. The new public sample
`ppif/axi_manager_capacity_status_same_id_queue_head_response_demux.ppif`
reports a duplicate concrete-ID read group under
`same_id_issue_order_queues`, `transaction_completion_source:
generated_queue_head_demux`, and `implementation_status:
selected_not_generated`; generated queue state, queue-head demux rules,
accepted same-ID reuse, generated queue behavior, direct backend, and VHDL
remain unchanged. Same-family auto-ID demux plus concrete same-ID queue-head
demux and read-data consumption of selected-not-generated queue-head demux
fail closed. The active frontier advances to `.104`, generated same-ID queue
state and queue-head behavior readiness. Audit `.104` finds no obvious new
IAL1/IAL0/SystemVerilog substrate prerequisite for the first bounded generated
behavior slice, but queue state and queue-head demux remain behavior-coupled:
queue state needs a dequeue event from queue-head demux, and queue-head demux
needs queue-head transaction identity from queue state. Direct broad
implementation is therefore too large. The active frontier advances to
`.105`, first generated AXI same-ID queue state and queue-head behavior slice
selection, before generated queue state, queue-head demux rules, accepted
same-ID reuse, generated queue behavior, direct backend, or VHDL behavior
changes. Selector `.105` chooses `.106`, generated AXI same-ID read
burst-last queue behavior for the existing public queue-head sample shape:
one duplicate concrete read-ID group, two read transactions, computed depth 2,
generated compact one-hot queue state, and generated queue-head completion
demux shipped together. Write queue-head behavior, read `single-beat`, deeper
or multiple groups, same-family mixed auto-ID, read-data consumption, direct
backend, and VHDL remain deferred. Implementation `.106` now ships that
bounded shape: generated slot state, finite queue update rules, queue-head
last-beat completion demux, generated completion outputs, queue integrity and
response-demux assertions, and report/residue movement. The public same-ID
queue-head sample reports `response_demux.generated_behavior: true`,
`same_id_ordering.generated_behavior: true`, `accepted_same_id_reuse: true`,
and `generated_queue_behavior: true` for the covered read burst-last
two-transaction depth-2 group only. The active frontier advances to `.107`,
the next same-ID queue behavior expansion audit/selector. Selector `.107`
chose `.108` as the next behavior-bearing owner. Implementation `.108` now
ships the write-family analogue for
`ppif/axi_manager_capacity_status_write_same_id_queue_head_response_demux.ppif`:
one duplicate concrete write-ID group of two transactions at computed depth
2, compact one-hot write queue slots, generated write completion pulse
outputs, queue-head `BID` demux rules, support-accounting coverage, and
Verilator-clean generated SystemVerilog. At that point, read `single-beat`
remained deferred until `.110`; deeper/multiple groups, same-family mixed
auto-ID, read-data consumption of concrete queue-head demux, direct backend,
and VHDL remain deferred.
After `.108`, the frontier advanced to `.109`, the same-ID queue behavior
expansion audit/selector after shipped read burst-last and write depth-2
queue-head behavior.
Selector `.109` chooses `.110`, generated read `single-beat` concrete
same-ID queue-head behavior for one duplicate read-ID group of two
transactions at depth 2. Implementation `.110` now ships that bounded shape
for
`ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_response_demux.ppif`:
compact one-hot read queue slots, admitted read enqueue pulses, generated read
completion pulse outputs, queue-head `RID` demux rules without `RLAST`,
support-accounting coverage, and Verilator-clean generated SystemVerilog.
Read-data consumption, deeper or multiple groups, same-family mixed auto-ID,
generalized per-ID queues, direct backend, and VHDL remain deferred. The
`.111` selector chooses `.112`, AXI read-data consumption of generated
concrete same-ID queue-head demux readiness. The existing generated
read-data path captures `RDATA`/`RRESP` from generated auto-ID read
response-demux completion pulses, but current normalization still rejects
`read_data` when the read response-demux source is generated concrete
queue-head demux. `.112` must decide whether the first safe behavior slice can
be bounded to read single-beat queue-head demux plus single-beat read-data
capture, or whether parser/report/static metadata alignment is required first.
Audit `.112` selects `.113`, generated single-beat read-data capture for the
bounded read single-beat concrete same-ID queue-head demux shape. No
IAL1/IAL0/SystemVerilog prerequisite is evident; the behavior slice must make
read-data coverage source-aware for generated queue-head completion signals
instead of only auto-ID transaction lists, then add the combined public sample,
tests, support accounting, and docs. Implementation `.113` now ships that
bounded behavior for
`ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_read_data.ppif`:
the generator derives read-data transaction coverage from the generated
queue-head group and completion signals, emits generated `RDATA`/`RRESP`
inputs plus per-transaction data/status outputs, guards capture rules with the
generated queue-head completion pulses, and reports
`generated_queue_head_response_demux_completion_pulse` while preserving the
existing auto-ID read-data completion-validity report. Selector `.114` chose
`.115`, generated last-beat read-data capture for the bounded read burst-last
concrete same-ID queue-head demux shape. Implementation `.115` now ships that
shape for
`ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_read_data.ppif`:
the generator reuses the already generated `RLAST`-qualified queue-head
completion pulses, emits generated `RDATA`/`RRESP` inputs plus
per-transaction last-beat data/status outputs, guards capture rules with the
generated queue-head last-beat completion pulses, and reports
`generated_queue_head_response_demux_last_beat_completion_pulse` while
preserving existing auto-ID last-beat and queue-head single-beat read-data
report values. Selector `.116` chose `.117`, generated raw-`ARLEN`
burst-length capture for the bounded queue-head last-beat read-data shape.
Implementation `.117` now ships report-only raw-`ARLEN` burst-length capture
for
`ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length.ppif`:
generated `axi0_arlen` input, per-transaction raw-`ARLEN` storage,
request-guarded burst-length capture rules, and the existing queue-head
last-beat `RDATA`/`RRESP` capture rules. The report keeps
`generated_queue_head_response_demux_last_beat_completion_pulse` and sets
`burst_length_generated_behavior: true`. Selector `.118` chose `.119`,
generated queue-head beat-count/RLAST runtime validation for the bounded
queue-head last-beat read-data shape, and implementation `.119` now ships
that runtime-validation sibling for
`ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif`.
It preserves request-bound raw-`ARLEN` capture and queue-head last-beat
`RDATA`/`RRESP` capture, adds expected-count storage, matched-read-beat
counters, initialization/increment rules, and runtime assertions for
request-time `ARLEN` bounds, over-count/extra beats, early `RLAST`, and
missing final `RLAST`. Matched beats are counted from raw response event plus
concrete `RID` plus active queue-head transaction identity while preserving
the queue-head last-beat completion-validity report. Implementation `.121`
now ships generated multi-beat read-data output-bank behavior for
`ppif/axi_manager_capacity_status_read_multi_beat_same_id_queue_head_read_data.ppif`.
That bounded sample emits request-time output-bank clearing, per-beat
`RDATA`/`RRESP` lane captures guarded by raw matched queue-head read beat plus
beat-count lane index, valid-mask/length outputs, scalar `RRESP` aggregation,
generated beat-count/`RLAST` artifacts, and empty `read_data` and
`response_demux` residue. Selector `.122` chose `.123`, readiness audit for
multiple independent read burst-last depth-2 concrete same-ID queue-head
response-demux groups. Audit `.123` selected `.124`, generated read
burst-last response-demux-only queue-head behavior for two or more duplicate
concrete read-ID groups, each exactly two transactions at computed depth `2`.
Implementation `.124` now ships that behavior for
`ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif`.
The generated path emits concrete-ID-scoped compact one-hot queue storage,
finite depth-2 transition rules, generated completion pulse outputs,
queue-head response-demux rules, queue assertions, response-demux assertions,
and generated queue reports for both covered groups while preserving the
existing family-wide admitted-request onehot boundary. Selector `.125` chose
`.126`, readiness audit for read-data coverage over multiple generated read
burst-last concrete same-ID queue-head groups. Audit `.126` selected `.127`,
generated multi-group queue-head multi-beat read-data output-bank behavior.
`.127` now ships that behavior for
`ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data.ppif`,
flattening the `RID` `3` and `RID` `5` generated queue groups into
multi-beat read-data coverage with per-transaction output banks, valid masks,
length outputs, scalar `RRESP` aggregation, raw `ARLEN` capture, and
beat-count/`RLAST` runtime validation. Audit `.129` selected `.130`,
generated multi-group queue-head last-beat read-data capture. `.130` now ships
that behavior for
`ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_read_data.ppif`,
flattening the `RID` `3` and `RID` `5` generated queue groups into scalar
last-beat read-data coverage with generated `RDATA`/`RRESP` inputs,
per-transaction last-beat data/status outputs, and capture rules guarded by
generated queue-head last-beat completion pulses. `.132` now ships
report-only raw-`ARLEN` burst-length capture for the same multi-group
queue-head scalar last-beat read-data shape:
`ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length.ppif`
adds the shared generated `axi0_arlen` input, per-transaction raw-`ARLEN`
storage/capture rules for `r0`, `r1`, `r2`, and `r3`, and preserves scalar
last-beat data/status capture. Implementation `.135` now ships the
runtime-validation sibling
`ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif`:
per-transaction expected-beat storage, matched read-beat counters,
request-time initialization, raw queue-head matched-beat increment rules, and
beat-count/`RLAST` assertions are generated for `r0`, `r1`, `r2`, and `r3`
while scalar final data/status capture stays guarded by generated queue-head
last-beat completion pulses.
Selector `.131` selected `.132`, generated report-only raw-`ARLEN`
burst-length capture for the multi-group queue-head scalar last-beat read-data
shape, and `.132` completed that implementation boundary. Selector `.133`
selected `.134`, readiness audit for generated runtime-validation multi-group
queue-head scalar last-beat read-data, before any behavior slice adds
expected-beat storage, matched-beat counters, and beat-count/`RLAST`
assertions across multiple queue groups. Audit `.134` found no new IAL1,
IAL0, SystemVerilog, direct-backend, or VHDL prerequisite; the remaining local
blocker is the queue-head read-data coverage gate. It selected `.135`,
and `.135` completed that implementation boundary. Same-family auto-ID,
deeper queues, write or read single-beat multi-group queue-head behavior,
packed outputs, direct backend, and VHDL remain deferred.
Selector `.136` selected `.137`, report/static residue cleanup, because live
`.135` reports prove generated runtime-validation multi-group queue-head
scalar last-beat read-data is supported while the AXI ID/order support-detail
string and focused PPIF/parser assertion still preserve stale unsupported
wording for that exact behavior. `.137` completed that cleanup: the support
detail now describes the shipped runtime-validation multi-group scalar shape
as supported, the focused parser assertion rejects the retired unsupported
wording, the `.135`, `.132`, `.130`, `.127`, `.124`, and `.119` live reports
remain unchanged, and `.138` selected `.139`, readiness audit for generated
write-family multi-group queue-head response-demux. A temporary two-group
write probe reported two duplicate concrete write-ID groups but remained
metadata-only with `generated_same_id_queue_head_demux` residue, while
one-group write queue-head and read burst-last multi-group queue-head behavior
were already generated. Read single-beat multi-group behavior, deeper queues,
same-family mixed auto-ID plus concrete queue-head demux, packed outputs,
direct backend, and VHDL remain deferred.
Audit `.139` selected `.140`, generated write-family multi-group queue-head
response-demux, after finding no new parser, support-accounting,
generated-artifact, lowerer, direct-backend, or VHDL prerequisite. The
planner and report path already carry multiple write groups, and downstream
queue-state, transition, assertion, response-demux state/rule, report, and
residue helpers already group-iterate once behavior exists; the local blocker
was the narrow builder gate that permitted multiple groups only for read
burst-last. `.140` shipped generated write-family multi-group queue-head
response-demux for
`ppif/axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux.ppif`.
The generated report lists `BID` `3` for `w0`/`w1` and `BID` `5` for
`w2`/`w3`, every generated group remains depth `2`, generated completion
signals cover `w0` through `w3`, and `generated_same_id_queue_head_demux`
residue is removed for the covered write family. The implementation preserves
the existing family-wide admitted-request onehot boundary and keeps
group-local simultaneous enqueue widening deferred. `.141` selected `.142`,
readiness audit for generated read single-beat multi-group queue-head
response-demux, because a temporary read single-beat two-group probe reported
two duplicate concrete read-ID groups but remained selected-not-generated with
`generated_same_id_queue_head_demux` residue while adjacent read burst-last
multi-group, read single-beat one-group, and write multi-group queue-head
response-demux shapes were generated. Audit `.142` selected `.143`, generated
read single-beat multi-group queue-head response-demux, after finding no new
parser, support-accounting, generated-artifact, lowerer, direct-backend, or
VHDL prerequisite. The planner, storage, transition, assertion,
response-demux rule, report, and residue helpers already group-iterate for
read single-beat once behavior exists. `.143` shipped generated read
single-beat multi-group queue-head response-demux for
`ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_response_demux.ppif`.
The generated report lists `RID` `3` for `r0`/`r1` and `RID` `5` for
`r2`/`r3`, every generated group remains depth `2`, generated completion
signals cover `r0` through `r3`, no `RLAST` or `read_data` behavior is
introduced, and `generated_same_id_queue_head_demux` residue is removed for
the covered read single-beat response-demux-only family. Strict check JSON and
normalized semantic JSON match the support-accounting entry for the sample,
keeping MCP-facing semantic introspection aligned with the public support
catalog. Selector `.144` chose `.145`, readiness audit for generated read-data
over read single-beat multi-group queue-head groups. Audit `.145` found no
new parser, IAL1, IAL0/SystemVerilog, direct-backend, or VHDL prerequisite and
selected `.146`, the bounded implementation owner. `.146` shipped generated
read-data over read single-beat multi-group queue-head response-demux for
`ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_read_data.ppif`.
The generated report covers `RID` `3` for `r0`/`r1` and `RID` `5` for
`r2`/`r3`, scalar `RDATA`/`RRESP` captures guarded by generated queue-head
completion pulses, and `completion_validity:
generated_queue_head_response_demux_completion_pulse`; strict check JSON and
semantic JSON match the new support-accounting entry. Selector `.147`
selected `.148`, readiness audit for generated concrete same-ID queue-head
groups deeper than two slots, after live reports confirmed the generated
queue-head families remain depth-2 and code inspection found the queue
builder, transition matrix, state/full helpers, and assertions specialized
around two slots. Audit `.148` confirmed temporary depth-3 read single-beat,
read burst-last, and write response-demux probes report selected-not-generated
depth-3 queue groups while passing strict check/semantic without
support-accounting matches; temporary depth-3 read-data probes fail closed
because generated read response-demux metadata does not exist for depth-3
groups. `.148` selected `.149`, generated read single-beat depth-3
queue-head response-demux through generalized shared queue-state helpers.
`.149` now ships that bounded behavior for
`ppif/axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_response_demux.ppif`:
one read single-beat concrete `RID` `3` group covers `r0`/`r1`/`r2`, compact
one-hot queue storage spans `slot0` through `slot2`, generated completion
pulses are emitted only for the active head transaction, and strict check JSON,
semantic JSON, and `--verify-hdl` cover the public sample through support
accounting. Read-data over depth-3 queues, write and burst-last depth-3
response-demux, multiple or mixed depth-3 groups, same-family mixed auto-ID,
and group-local simultaneous enqueue widening remained deferred from `.149`.
Selector `.150`
chose `.151`, focused PPIF support-detail expectation alignment, because the
production support detail now explicitly names independent `depth-2`
queue-head groups while the focused PPIF regex still expected the older
wording. `.151` aligned that validation surface without changing parser,
generator, report, sample, support-accounting, generated artifact, or HDL
behavior. `.152` audited scalar read-data over generated read single-beat
depth-3 queue-head response-demux and selected `.153` as the direct bounded
implementation owner: one read single-beat concrete `RID` group of three
transactions with scalar `RDATA`/`RRESP` capture over the generated completion
pulses. Read burst-last depth-3, write depth-3, multiple or mixed depth-3
groups, same-family mixed auto-ID, group-local enqueue widening, direct
backend, and VHDL remain deferred until separately selected.
`.153` now ships that bounded scalar read-data sibling for
`ppif/axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_read_data.ppif`:
the same `r0`/`r1`/`r2` concrete `RID` `3` depth-3 queue-head group drives
generated `axi0_rdata`/`axi0_rresp` inputs, per-transaction scalar
`RDATA`/`RRESP` outputs, and capture rules guarded by
`generated_queue_head_response_demux_completion_pulse`; strict check JSON,
semantic JSON, and `--verify-hdl` cover the public sample through support
accounting. `.154` selected `.155`, readiness audit for generated read
burst-last depth-3 queue-head response-demux. `.155` selected `.156` as the
direct bounded implementation owner after finding the temporary depth-3
burst-last probe passes schedule/check/semantic parsing and remains
selected-not-generated only because of the local queue-builder depth gate.
Write depth-3, read-data over read burst-last depth-3, multiple or mixed
depth-3 groups, same-family mixed auto-ID, group-local enqueue widening,
direct backend, and VHDL remain deferred until separately selected.
`.156` now ships that bounded read burst-last depth-3 queue-head
response-demux sibling for
`ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_response_demux.ppif`:
one read burst-last concrete `RID` `3` group covers `r0`/`r1`/`r2`, compact
one-hot queue storage spans `slot0` through `slot2`, generated completion
pulses are emitted only for the active head transaction when raw read
completion, `RID`, `RLAST`, and slot identity match, and strict check JSON,
semantic JSON, and `--verify-hdl` cover the public sample through support
accounting. Read-data over read burst-last depth-3, burst-length/runtime or
multi-beat over read burst-last depth-3, write depth-3, multiple or mixed
depth-3 groups, same-family mixed auto-ID, group-local enqueue widening,
direct backend, and VHDL remain deferred. `.157` selected `.158`, readiness
audit for generated read-data over read burst-last depth-3 queue-head
response-demux, after a temporary last-beat read-data-over-`.156` probe
failed closed at the depth-2-only burst-last queue-head read-data coverage
gate. No behavior-bearing code changed in `.157`; write depth-3,
burst-length/runtime or multi-beat over read burst-last depth-3, multiple or
mixed depth-3 groups, same-family mixed auto-ID, group-local enqueue widening,
direct backend, and VHDL remain deferred until separately selected. `.158`
audited the scalar last-beat read-data sibling and selected `.159`, direct
bounded implementation for exactly one generated read burst-last depth-3
concrete `RID` group with `r0`/`r1`/`r2`. Code review found the same-ID queue
builder already generates the depth-3 burst-last demux and the scalar
read-data artifact path already iterates covered transactions once the local
coverage gate admits them; no lower-layer prerequisite was found. `.158`
remains audit-only. Burst-length/runtime or multi-beat over read burst-last
depth-3, write depth-3, multiple or mixed depth-3 groups, same-family mixed
auto-ID, group-local enqueue widening, direct backend, and VHDL remain
deferred until separately selected.
`.159` now ships that bounded scalar last-beat read-data sibling for
`ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_read_data.ppif`:
the same `r0`/`r1`/`r2` concrete `RID` `3` depth-3 queue-head group drives
generated `axi0_rdata`/`axi0_rresp` inputs, per-transaction scalar
last-beat `RDATA`/`RRESP` outputs, and capture rules guarded by
`generated_queue_head_response_demux_last_beat_completion_pulse`. Strict
check JSON, semantic JSON, and `--verify-hdl` cover the public sample through
support accounting. Burst-length/runtime or multi-beat over read burst-last
depth-3, write depth-3, multiple or mixed depth-3 groups, same-family mixed
auto-ID, group-local enqueue widening, direct backend, and VHDL remain
deferred until separately selected. `.160` selected `.161`, readiness audit
for generated report-only raw-`ARLEN` burst-length capture over the same
read burst-last depth-3 queue-head read-data shape. Runtime validation,
multi-beat output-bank behavior, write depth-3, multiple or mixed depth-3
groups, same-family mixed auto-ID, group-local enqueue widening, direct
backend, and VHDL remain deferred until separately selected.
`.161` selected `.162`, direct bounded implementation of generated
report-only raw-`ARLEN` burst-length capture over exactly one generated read
burst-last depth-3 queue-head read-data group, after live probes found the
temporary candidate fails only at the local queue-head read-data coverage
predicate and the raw-`ARLEN` storage/rule/report path is already
transaction-list driven. Runtime validation, multi-beat output-bank behavior,
write depth-3, multiple or mixed depth-3 groups, same-family mixed auto-ID,
group-local enqueue widening, direct backend, and VHDL remain deferred until
separately selected.
`.162` now ships that bounded report-only raw-`ARLEN` burst-length sibling for
`ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length.ppif`:
the same `r0`/`r1`/`r2` concrete `RID` `3` depth-3 queue-head group keeps
generated scalar last-beat `RDATA`/`RRESP` capture and adds generated
`axi0_arlen`, raw-`ARLEN` storage for `r0`, `r1`, and `r2`, and
request-guarded burst-length capture rules. Strict check JSON, semantic JSON,
and `--verify-hdl` cover the public sample through support accounting.
Runtime validation, multi-beat output-bank behavior over read burst-last
depth-3, write depth-3, multiple or mixed depth-3 groups, same-family mixed
auto-ID, group-local enqueue widening, direct backend, and VHDL remain
deferred until separately selected. `.162` advances the active frontier to
`.163`, the next feature-completeness selector.
`.163` now selects `.164`, readiness audit for generated runtime
beat-count/`RLAST` validation over that `.162` depth-3 queue-head read-data
plus report-only raw-`ARLEN` burst-length shape. Live probes confirmed the
`.162` sample still reports `generated_beat_count_validation` residue, while
the existing one-group and multi-group depth-2 runtime-validation samples
already generate expected-beat storage, matched-beat counters, beat-count
rules, and runtime assertions from transaction-list driven helpers. A
temporary depth-3 runtime-validation candidate currently fails closed only at
the local last-beat queue-head coverage diagnostic. `.164` must audit whether
direct implementation only needs that admission boundary widened or whether a
smaller prerequisite is required. Multi-beat output banks, write depth-3,
multiple or mixed depth-3 groups, mixed auto-ID, direct backend, and VHDL
remain deferred until separately selected.
`.164` now selects `.165`, direct bounded implementation of generated
runtime beat-count/`RLAST` validation over that same `.162` depth-3
queue-head raw-`ARLEN` burst-length shape. The audit found no lower-layer
prerequisite beyond the local coverage gate: runtime-validation
normalization, expected-beat storage, read-beat counters, beat-count
init/increment rules, assertion generation, generated-artifact reporting, and
schedule-report fields already iterate the covered transaction list. `.165`
now ships that behavior for
`ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion.ppif`.
The generated report has expected-beat storage and read-beat counters for
`r0`, `r1`, and `r2`, raw matched-read-beat increment rules, four
beat-count/`RLAST` assertions per transaction, and
`beat_count_match_source: response_demux_matched_read_beat`; it removes
`generated_beat_count_validation` residue while keeping
`multi_beat_read_data_reassembly`, `per_beat_outputs`, and
`rresp_aggregation` residue. The `.162` report-only sample is preserved.
`.167` audited generated multi-beat output-bank readiness over that same
depth-3 runtime-validation shape and selected `.168`, direct bounded
implementation. Live reports show `.165` leaves only
`multi_beat_read_data_reassembly`, `per_beat_outputs`, and
`rresp_aggregation` read-data residue; depth-2 one-group and multi-group
multi-beat siblings already generate `per_beat_output_bank` behavior with
empty read-data residue; and an in-memory depth-3 multi-beat candidate fails
closed only at the local multi-beat coverage diagnostic. `.168` is limited to
one read burst-last depth-3 queue-head group with `r0`/`r1`/`r2`, runtime
`ARLEN` validation, per-beat output banks, valid masks, length outputs, and
scalar `RRESP` aggregation. Write depth-3, multiple or mixed depth-3 groups,
mixed auto-ID, direct backend, verification-output generation, and VHDL
remain deferred.
`.168` now ships that bounded multi-beat read-data behavior for
`ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data.ppif`.
It admits exactly one read burst-last concrete `RID` `3` group at depth `3`,
generates per-transaction output-bank clearing, 48 per-lane `RDATA`/`RRESP`
captures, valid masks, length outputs, scalar worst-observed `RRESP`
aggregation, raw `ARLEN` capture, expected-beat/read-beat storage, runtime
beat-count/`RLAST` assertions, and empty `read_data`/`response_demux` residue
for the covered sample. The support-accounted check/semantic surface reports
`intent.ppif_axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data`.
That completed `.168` and handed off to `.169`, a selector/audit for the
next roadmap-aligned IAL2 feature-completeness slice after depth-3 multi-beat
output-bank behavior.
`.169` now selects `.170`, readiness audit for generated write-family
depth-3 concrete same-ID queue-head response-demux. Existing write depth-2
one-group and multi-group queue-head response-demux samples are generated
through `generated_write_bid_queue_head_demux`, and a temporary write
depth-3 candidate with `w0`/`w1`/`w2` sharing concrete `BID` `3` passes
strict check with no diagnostics while reporting one depth-3 write queue
group and remaining selected-not-generated only with
`generated_same_id_queue_head_demux` residue. Multiple or mixed depth-3
groups, mixed auto-ID, group-local enqueue widening, packed outputs,
alternate burst assembly, direct backend, verification-output generation, and
VHDL remain deferred until separately selected.
`.171` now ships direct bounded generated write-family depth-3 concrete
same-ID queue-head response-demux. The public sample uses `w0`/`w1`/`w2`
sharing concrete `BID` `3`, queue depth `3`, and boundary
`generated_write_bid_queue_head_demux`; strict check JSON and semantic JSON
support-account it as
`intent.ppif_axi_manager_capacity_status_write_depth3_same_id_queue_head_response_demux`.
Generated behavior includes three completion outputs and response-demux
rules, four write response-demux assertions, 9 queue slot storage signals, 54
queue update rules, and 14 queue assertions. Multiple or mixed depth-3 groups,
mixed auto-ID, group-local enqueue widening, read-data, burst-length,
runtime-validation, multi-beat payload, direct backend, verification-output
generation, and VHDL remain deferred.
`.172` now selects `.173`, readiness audit for generated multiple or mixed
depth-3 concrete same-ID queue-head response-demux groups. The selector found
that one-group depth-3 and multi-group depth-2 response-demux samples are
already generated, while temporary multi-depth-3 and mixed depth-3/depth-2
write probes strict-check with no diagnostics but remain selected-not-generated
with `generated_same_id_queue_head_demux` residue. `.173` remained
behavior-free and selected the exact next behavior owner before any parser,
generator, PPIF sample, support-accounting, generated-artifact, test, or HDL
behavior changes.
`.174` now ships generated multiple or mixed depth-3 concrete same-ID
queue-head response-demux for response-demux-only read single-beat, read
burst-last, and write families. The implementation widens only the local
queue-head behavior admission boundary for duplicate concrete-ID groups whose
computed depth is `2` or `3` with at least one depth-3 group; downstream
storage, transition, assertion, response-demux, and report helpers remain
group/depth driven. Six public PPIF samples are support-accounted: read
single-beat two-depth-3 and mixed depth-3/depth-2 groups, read burst-last
two-depth-3 and mixed depth-3/depth-2 groups, and write two-depth-3 and mixed
depth-3/depth-2 groups. The report boundaries remain
`generated_read_single_beat_queue_head_demux`,
`generated_read_burst_last_queue_head_demux`, and
`generated_write_bid_queue_head_demux`; generated response-demux residue
removes `generated_same_id_queue_head_demux` for the covered family. Read-data
over multiple/mixed depth-3 groups, burst-length, runtime-validation,
multi-beat payload, mixed auto-ID, group-local enqueue widening, packed
outputs, direct backend, verification-output generation, VHDL, and
backend-language variants remain behind future owned leaves.
`.175` now selects `.176`, readiness audit for generated read-data over
multiple or mixed depth-3 concrete same-ID queue-head groups. Temporary
read-data probes over two depth-3 read queue groups fail closed at the local
read-data coverage gate, while `.174` response-demux-only samples remain
generated. The selector is documentation-only and makes no parser, generator,
PPIF sample, support-accounting, generated-artifact, test, or HDL behavior
changes.
`.176` now selects `.177`, direct bounded implementation of generated read
single-beat scalar `RDATA`/`RRESP` over multiple or mixed depth-3 concrete
same-ID queue-head groups. The audit found that the blocker is local to the
single-beat branch of `_read_data_response_demux_transaction_coverage`; after
coverage admits transactions, read-data normalization, generated-artifact
enumeration, report projection, and tests are transaction-list driven.
Burst-last read-data, burst-length, runtime-validation, multi-beat payload,
mixed auto-ID, group-local enqueue widening, packed outputs, direct backend,
verification-output generation, VHDL, and backend-language variants remain
deferred behind future owned leaves.
`.177` now ships generated read single-beat scalar `RDATA`/`RRESP` over
multiple or mixed depth-3 concrete same-ID queue-head groups. The local
single-beat read-data coverage gate now admits duplicate concrete `RID`
groups with computed depths `2` or `3` when at least one group is depth `3`;
read-data normalization, artifact enumeration, report projection, and HDL
lowering remain transaction-list driven. Two public support-accounted samples
cover the two-depth-3 and mixed depth-3/depth-2 shapes. Selector `.178`
selected `.179`, readiness audit for generated read burst-last scalar
last-beat read-data over multiple/mixed depth-3 queue-head groups. Audit
`.179` selected `.180`, and implementation `.180` now ships generated read
burst-last scalar last-beat `RDATA`/`RRESP` over two-depth-3 and mixed
depth-3/depth-2 concrete same-ID queue-head groups with no `burst_length`
metadata. The two public samples are support-accounted, strict check/semantic
JSON matched, and HDL-verifiable. Burst-length, runtime-validation,
multi-beat payload over those groups, write-family read-data, mixed auto-ID,
group-local enqueue widening, packed outputs, alternate burst assembly, direct
backend, verification-output generation, VHDL, and backend-language variants
remain deferred. Selector `.181` selected `.182`, readiness audit for
generated report-only raw-`ARLEN` burst-length capture over the same
multiple/mixed depth-3 queue-head scalar last-beat read-data shape. This
follows the established one-group depth-3 and multi-group depth-2 sequence:
no-`burst_length` scalar last-beat read-data, report-only raw-`ARLEN`, then
runtime validation and multi-beat output-bank behavior only behind later exact
owners. Audit `.182` selected `.183`, direct bounded implementation of
generated report-only raw-`ARLEN` burst-length capture over those
multiple/mixed depth-3 queue-head scalar last-beat read-data groups.
Implementation `.183` now ships that report-only raw-`ARLEN` burst-length
behavior for the two-depth-3 and mixed depth-3/depth-2 queue-head scalar
last-beat read-data samples. The new samples are support-accounted, strict
check/semantic JSON matched, and HDL-verifiable; generated reports keep
`generated_beat_count_validation` residue because runtime validation remains
deferred. Selector `.184` selected `.185`,
readiness audit for generated runtime beat-count/`RLAST` validation over the
same multiple/mixed depth-3 queue-head scalar last-beat read-data shape. Audit
`.185` selected `.186`, direct bounded implementation of that generated
runtime-validation behavior. Implementation `.186` now ships generated
runtime beat-count/`RLAST` validation over the same multiple/mixed depth-3
queue-head scalar last-beat read-data shape. The two support-accounted
runtime-assertion samples cover depth `3,3` and `3,2` queue sets, capture raw
request `ARLEN`, store expected beats as `ARLEN+1`, generate read beat
counters and request/response update rules, emit beat-count/`RLAST`
assertions, report `burst_length_validation: runtime_assertion`, and remove
`generated_beat_count_validation` residue while preserving multi-beat payload,
per-beat output, and `RRESP` aggregation residue. Multi-beat payload,
write-family read-data, same-family mixed auto-ID, group-local enqueue
widening, packed outputs, alternate burst assembly, direct backend,
verification-output generation, VHDL, and backend-language variants remain
deferred. Selector `.187` selected `.188`, report/static support-residue
cleanup, because live `.186` reports generate runtime validation while the AXI
ID/order unsupported-residue detail still classifies multiple/mixed depth-3
runtime validation with multi-beat payload as outside the shell. Cleanup `.188`
now reports selected multiple/mixed
depth-3 runtime-validation scalar last-beat shapes as supported and leaves
only read burst-last multi-beat payload over those groups as unsupported
residue. Selector `.189` selected `.190`, readiness audit for generated
multi-beat output-bank behavior over those multiple/mixed depth-3
runtime-validation groups. Audit `.190` selected `.191`, direct bounded
implementation of generated multi-beat output-bank behavior over the two
existing `.186` depth `3,3` and mixed depth `3,2` runtime-validation
queue-head shapes. Implementation `.191` now ships that behavior with two
support-accounted public samples. Reports for both samples set
`bounded_multi_beat_read_data_contract`, `per_beat_output_bank`,
runtime-assertion `ARLEN` validation, empty `read_data` residue, and empty
`response_demux` residue. Selector `.192` selected `.193`, readiness audit
for same-family mixed auto-ID lifecycle plus concrete same-ID queue-head
response-demux before any behavior change. Audit `.193` selected `.194`,
direct bounded response-demux-only implementation of that mixed family
boundary. Implementation `.194` now ships that behavior for public read
single-beat, read burst-last, and write fixtures by combining auto-ID and
queue-head completion outputs, response-demux states, request-ID drive
ownership, reports, and assertions without new syntax. Selector `.195`
selected `.196`, readiness audit for mixed read-data consumption over
same-family mixed auto-ID plus concrete same-ID queue-head response-demux.
Audit `.196` selected `.197`, direct bounded implementation of scalar
read-data consumption for the read single-beat and read burst-last mixed
families. Implementation `.197` now ships that bounded scalar read-data
behavior for the read single-beat and read burst-last same-family mixed
auto-ID plus concrete same-ID queue-head response-demux shapes. The two public
support-accounted samples bind `RDATA`/`RRESP` for `r0`, `r1`, and `r2`,
reuse the combined generated response-demux completions, report the mixed
single-beat and burst-last read-data completion-validity strings, strict-check
and HDL-verify cleanly, and keep existing PPIF syntax. Selector `.198`
selected `.199`, readiness audit for generated report-only raw-`ARLEN`
burst-length capture over the read burst-last same-family mixed auto-ID plus
concrete queue-head scalar last-beat read-data shape. Audit `.199` found
temporary report-only and runtime-assertion probes both generate through
existing helpers, selected `.200` to publish/support-account the report-only
boundary first, and requires `.200` to preserve or lock runtime validation as
separately owned. Implementation `.200` now ships that support-accounted
report-only raw-`ARLEN` burst-length boundary through
`ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length.ppif`.
Audit `.201` selected `.202`, direct bounded support/publication of generated
runtime beat-count/`RLAST` validation over that same mixed auto-ID plus
concrete queue-head read burst-last scalar last-beat shape. Implementation
`.202` now ships that support-accounted runtime-assertion sibling through
`ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length_runtime_assertion.ppif`.
It reports `burst_length_validation: runtime_assertion`,
`beat_count_match_source: response_demux_matched_read_beat`, expected-beat
storage, read-beat counters, six beat-count rules, twelve beat-count/`RLAST`
assertions, strict support accounting, semantic JSON support, and HDL, while
removing `generated_beat_count_validation` residue. Cleanup `.204` aligned
public/support wording for that selected mixed runtime-validation shape. Audit
`.206` then selected `.207`, direct bounded implementation of generated mixed
multi-beat output-bank behavior over the same runtime-validation shape. The
audit found no lower-layer prerequisite: a temporary mixed multi-beat mutation
fails closed only at the local mixed read-data coverage predicate, while
existing transaction-list helpers already provide output-bank, scalar
aggregate, burst-length, beat-count, assertion, and report artifacts after
admission. Implementation `.207` now ships the support-accounted mixed multi-beat
output-bank sample and report surface over that exact runtime-validation
shape, with three covered transactions, 48 RDATA lanes, 48 RRESP lanes, valid
masks, length outputs, scalar `RRESP` aggregates, 48 lane capture rules,
runtime beat-count/`RLAST` assertions, strict support accounting, semantic
JSON, and HDL. Group-local enqueue widening, packed outputs, direct backend,
verification-output generation, VHDL, and backend-language variants remain
separately owned.
Selector `.208` now chooses `.209`, readiness audit for group-local
simultaneous enqueue widening across generated concrete same-ID queue-head
families. The selector records that representative generated read multi-group,
write multi-group, and mixed multi-beat queue-head samples still carry a
family-wide request onehot assertion even when multiple concrete-ID queue
groups exist, so the next safe owner is an audit of admission, direction-level
capacity accounting, transition generation, and preservation before any
behavior change.
Audit `.209` selected `.210`, counted admission/capacity prerequisite audit.
Live probes over representative generated queue-head samples show one Boolean
request fan-in per direction, one family-wide request onehot assertion, and
per-group queue update rules. Generated IAL1 confirms admitted pulses use
scalar pending storage plus completion fan-in while the capacity rules
increment pending by one for any request fan-in. Distinct concrete-ID group
queue transitions are structurally separable, but group-local onehot
replacement must wait until counted same-direction request admission and
pending/status accounting are owned.
Implementation `.211` ships the counted substrate while keeping the
family-wide request onehot assertion. Generated read/write multi-group
queue-head reports now expose counted selected-request accounting,
`counted_submit` capacity matrices, exact request-count expressions,
`maximum_request_count: 2`, Boolean completion accounting, and
`reject_current_request_set` over-capacity behavior. Non-counted directions
and mixed auto-ID single concrete-group directions remain Boolean. Selector
`.212` found that admitted-request pulses still use scalar pending storage
plus Boolean completion fan-in, so direct group-local onehot narrowing could
enqueue requests that the capacity matrix rejects. Audit `.213` selected
`.214`, direct bounded implementation of counted admitted-request guard
alignment and group-local request assertions for generated multi-group
queue-head families. Implementation `.214` ships that behavior: counted
multi-group queue-head families now gate admitted-request pulses with a
request-set fit expression derived from counted capacity/status semantics and
replace the family-wide request onehot with per-concrete-ID group request
assertions. Non-counted directions and mixed auto-ID single concrete-group
directions preserve Boolean admission and the existing family-wide assertion.
Selector `.215` found no cleanup prerequisite and selected `.216`; audit
`.216` selected `.217`, public dynamic/user transaction-ID contract selection
before generalized per-ID issue-order queues. Selector `.217` selected
transaction-local `(id dynamic)`, sourced from the family request-ID signal at
the admitted request point. Audit `.218` selected `.219`, direct
metadata-first dynamic transaction-ID parser/report implementation.
Implementation `.219` ships that metadata-only boundary: public `.ppif`
accepts exactly `(id dynamic)`, requires a positive-width `id-families`
request/response signal contract, reports user-supplied selected-not-generated
dynamic metadata, adds a support-accounted metadata-only sample, and fails
closed for behavior clauses that would need dynamic capture, response matching,
queues, scoreboards, read-data routing, or HDL behavior. Selector `.220`
chooses `.221`, readiness audit for generated dynamic transaction-ID capture
and response matching before any behavior changes. Audit `.221` selects
`.222`, public contract selection for bounded dynamic write transaction-ID
capture and `BID` response matching. Selector `.222` selects `.223`, direct
generated behavior using existing `response-demux.write` with one
transaction-local dynamic write ID. Implementation `.223` ships that boundary:
the generator captures the write request-ID source at the admitted request
point, enforces single-active selected-ID/busy ownership, matches `BID`
against the captured ID, generates the transaction completion pulse, releases
busy from that pulse, reports `bounded_dynamic_write_bid_demux_contract`, and
adds `ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif` as
a support-accounted sample. `.365` extends that same single-active dynamic write
sample with same-cycle release-and-recapture. Metadata-only dynamic IDs remain
unchanged when no behavior clause consumes them. Implementation `.227` ships generated
single-beat dynamic read ID capture and `RID` response matching using existing
`response-demux.read` with one transaction-local dynamic read ID, and `.368`
extends that same sample with same-cycle release-and-recapture. The generated
path captures admitted `ARID`, stores selected-ID/busy state, matches raw read
responses with `RID == captured_id`, pulses the generated read completion,
releases or recaptures busy from that completion, reports
`bounded_dynamic_read_rid_demux_contract`, and adds a support-accounted dynamic
read PPIF sample. `.231` now ships the bounded dynamic read burst-last/`RLAST`
sibling with existing `response-demux.read` burst-last syntax, one dynamic read
ID, one-bit `last-signal`, admitted `ARID` capture, matched `RID && RLAST`
completion, generated busy release, and support-accounted public PPIF coverage;
`.372` extends that same burst-last sample with same-cycle release-and-recapture.
Dynamic read-data routing, burst-length/runtime validation, and bounded
multiple dynamic read single-beat response-demux now ship under later leaves.
Interleaving, multiple dynamic read burst-last/read-data widening, mixed
dynamic/static read demux, same-cycle recapture outside the selected
single-active dynamic write, read single-beat, and read burst-last boundaries,
same-ID ordering,
queues, scoreboards, direct backend behavior, HDL shapes outside this selected
SystemVerilog path, and VHDL remain deferred. Selector `.232` chose `.233`,
readiness audit for dynamic read-data
routing over the generated single-active dynamic read response-demux family;
audit `.233` selected `.234`, direct bounded implementation of scalar
single-beat plus scalar last-beat dynamic read-data capture. `.234` now ships
that behavior through existing `read-data.read` syntax for exactly one dynamic
read transaction, with generated `RDATA`/`RRESP` inputs, scalar data/status
outputs, dynamic completion-validity reports, and support-accounted public
samples. `.235` selected `.236`, AXI manager focused-suite cost cleanup, so
the shipped dynamic transaction-ID family can be validated through bounded
focused targets before more behavior is added. `.236` now ships that bounded
target. `.237` selected `.238`, direct bounded report-only
dynamic raw-`ARLEN` burst-length implementation. `.238` now ships that
generated report-only dynamic raw-`ARLEN` capture with support-accounted
`ppif/axi_manager_capacity_status_dynamic_read_data_burst_length.ppif`,
generated `axi0_arlen` input/storage/request-capture/report fields, and
scalar payload capture still guarded by the generated dynamic last-beat
completion pulse. `.240` now ships generated dynamic beat-count/`RLAST`
runtime validation over that same generated dynamic last-beat boundary with
support-accounted
`ppif/axi_manager_capacity_status_dynamic_read_data_burst_length_runtime_assertion.ppif`;
the `.238` report-only sample remains supported and unchanged. Dynamic
multi-beat output banks, multiple/mixed dynamic demux, same-cycle recapture,
dynamic same-ID ordering, queues, scoreboards, direct backend behavior, and
VHDL remain residue. Selector `.241` selected `.242`, readiness audit for
generated dynamic multi-beat output-bank behavior over the selected dynamic
runtime-validation boundary. Audit `.242` selected `.243`, direct bounded
dynamic multi-beat output-bank implementation over generated dynamic runtime
validation, and `.243` now ships that generated dynamic multi-beat read-data
output-bank behavior. `.244` selected `.245`, readiness audit for
multiple/mixed dynamic response-demux behavior after generated dynamic
multi-beat output banks. `.245` selected `.246`, public contract selection
for bounded multiple dynamic write response-demux behavior. `.246` selected
`.247`, and `.247` now ships direct bounded multiple dynamic write
response-demux implementation with all selected write transactions dynamic,
same-cycle dynamic write requests still onehot0, active dynamic IDs required
pairwise unique, generated active-match/unique-match/same-ID conflict
assertions, and
`ppif/axi_manager_capacity_status_dynamic_write_response_demux_multi.ppif` as
a support-accounted public sample. `.248` selected `.249`, readiness audit for
multiple dynamic read response-demux. That audit must account for read
`single_beat` and `burst_last` scopes, optional `RLAST`, raw matched-read-beat
counting, scalar read-data, burst-length/runtime validation, and multi-beat
output-bank coupling before any multiple dynamic read behavior is widened.
Audit `.249` selected `.250`, public contract selection for bounded multiple
dynamic read response-demux, because the lower substrate is partly list-shaped
but public read semantics and dynamic read-data interaction need exact
ownership before implementation. `.250` selected `.251`, and `.251` now ships
generated behavior for the bounded all-dynamic read-family `single_beat`
response-demux-only contract with per-transaction selected-ID/busy state,
admitted `ARID` capture, matched `RID` completion pulses, request onehot0,
active dynamic-ID uniqueness, active-match, unique-match, and
completion-active assertions. `.252` selected `.253`, readiness audit for
multiple dynamic read burst-last/`RLAST` response-demux, because that boundary
must define raw matched-`RID` beat assertions, selected-ID/busy lifetime across
non-last beats, and final `RID && RLAST` completion before read-data,
burst-length/runtime validation, or multi-beat output banks over multiple
dynamic reads can widen safely. `.253` selected `.254`, public contract
selection for bounded multiple dynamic read burst-last/`RLAST`
response-demux, because the lower substrate is close but the public contract
must pin all-dynamic family shape, last-signal ownership, raw beat versus
final completion assertions, report vocabulary, validation, and residue before
behavior changes. `.254` selected `.255`, direct generated behavior for the
bounded all-dynamic multi-active read burst-last/`RLAST` response-demux
contract, with read-data, burst-length/runtime validation, multi-beat output
banks, mixed dynamic/static demux, same-cycle widening, release-and-recapture,
dynamic same-ID queues, scoreboards, direct backend, backend-language
variants, and VHDL still deferred. `.255` ships that generated behavior as
`bounded_multi_dynamic_read_rid_rlast_demux_contract` with raw `RID` beat
active/unique assertions, final `RID && RLAST` completion/release guards, and
the support-accounted public sample
`ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last.ppif`.
`.256` selected `.257`, readiness audit for read-data over generated multiple
dynamic read response-demux, because dynamic read-data coverage still
accepted exactly one dynamic read transaction while the response-demux
substrate had multiple dynamic completion pulses. `.257` selected `.258`,
public contract selection for bounded scalar read-data over generated
multiple dynamic read response-demux. `.258` selected `.259`, and `.259` now
ships generated bounded scalar single-beat and scalar last-beat read-data
over all-dynamic multiple read response-demux through the support-accounted
public samples `ppif/axi_manager_capacity_status_dynamic_read_data_multi.ppif`
and
`ppif/axi_manager_capacity_status_dynamic_read_data_multi_last_beat.ppif`.
`.260` selected `.261`, readiness audit for generated burst-length and
runtime beat-count/`RLAST` validation over generated multiple dynamic read
response-demux, because multi-beat output-bank widening depends on
per-transaction raw-`ARLEN` capture and runtime counter/assertion semantics
across multiple active dynamic reads. `.261` selected `.262`, public
contract selection for bounded burst-length/runtime validation over generated
multiple dynamic read response-demux, because the lower helpers are close
after coverage admission but sample names, split/combined report-only/runtime
scope, report vocabulary, diagnostics, validation, and residue need contract
ownership before implementation. `.262` selected a split implementation, and
`.263` now ships report-only raw-`ARLEN` burst-length capture over generated
multiple dynamic read response-demux through
`ppif/axi_manager_capacity_status_dynamic_read_data_multi_burst_length.ppif`.
`.264` now ships the runtime beat-count/`RLAST` assertion sibling through
`ppif/axi_manager_capacity_status_dynamic_read_data_multi_burst_length_runtime_assertion.ppif`.
`.265` selects `.266`, readiness audit for generated multiple dynamic
multi-beat output-bank behavior over the generated multiple dynamic read
runtime-validation boundary. `.266` selects `.267`, public contract selection
for bounded generated multiple dynamic multi-beat output-bank behavior. `.267`
selected `.268`, and `.268` now ships generated bounded multiple dynamic
multi-beat output-bank behavior through the support-accounted public sample
`ppif/axi_manager_capacity_status_dynamic_read_data_multi_transaction_multi_beat.ppif`.
Later recapture work returned to this all-dynamic read family after multiple
dynamic write and single-beat read recapture shipped. `.382` selects `.383`,
readiness audit for multiple all-dynamic read burst-last `RID && RLAST`
same-cycle release-and-recapture, because final completion, non-final raw read
beats, scalar last-beat read-data, raw-`ARLEN`, runtime beat-count/`RLAST`, and
multi-beat output banks must be preserved before any burst-last recapture
contract or implementation is selected. `.383` selects `.384`, public
contract selection for that burst-last recapture boundary, after finding the
implementation substrate close but public last-beat release-recapture source,
assertion rename, guard, raw-beat preservation, read-data, raw-`ARLEN`,
runtime, multi-beat, validation, and rollback semantics still need explicit
ownership before behavior changes. `.384` selects `.385`, direct
implementation of that contract for the existing support-accounted multiple
all-dynamic read burst-last sample, with mode preservation, per-transaction
`multi_active_unique_dynamic_read` fields, last-beat release-recapture source,
idle-or-releasing request assertions, and preservation of raw non-final beats
plus read-data/raw-`ARLEN`/runtime/multi-beat consumers. `.385` now ships that
behavior for the existing support-accounted multiple all-dynamic read
burst-last sample. FSMGen emits `axi0_r0_dynamic_id_release_recapture` and
`axi0_r1_dynamic_id_release_recapture`, reports
`release_recapture_source: generated_dynamic_demux_last_beat_completion` under
`response_demux.read.dynamic_capture.transactions[]`, replaces the selected
request-not-busy assertions with idle-or-releasing assertions, keeps raw
non-final beats as raw matched beats only, and preserves scalar last-beat
read-data, raw-`ARLEN`, runtime beat-count/`RLAST`, and multi-beat output-bank
consumers.
`.386` selects `.387`, readiness audit for mixed dynamic/static same-cycle
release-and-recapture. The selector changes no behavior. The audit comes next
because all selected all-dynamic recapture siblings are now covered, while the
mixed boundary must still pin static busy recapture semantics,
dynamic/static concrete-ID reservation, onehot0 sibling policy, assertion
changes, read `RID && RLAST` and raw non-final beat preservation, and layered
read-data/raw-`ARLEN`/runtime/multi-beat implications before behavior changes.
`.387` selects `.388`, public contract selection for mixed dynamic/static
write `BID` same-cycle release-and-recapture. The audit changes no behavior.
Guarded baseline schedule probes for the one-dynamic/one-static mixed write,
read single-beat, and read burst-last public samples passed and confirmed the
current reports still use request-not-busy assertions with no
release-recapture metadata. Mixed write is the next owner because it exercises
both dynamic selected-ID recapture and static concrete busy recapture without
the read `RID`/`RLAST`, read-data, raw-`ARLEN`, runtime validation, and
multi-beat output-bank preservation stack.
`.388` selects `.389`, direct implementation of mixed dynamic/static write
`BID` same-cycle release-and-recapture for the existing support-accounted
public sample. The selector changes no behavior. It preserves public syntax,
`bounded_mixed_dynamic_static_write_bid_demux_contract`, generated mixed
completion source, onehot0 mixed request policy, static-ID reservation,
response active/unique-match, and completion-active assertions while selecting
dynamic recapture report fields, a new `static_capture` report block,
dynamic/static release-only exclusion, dynamic/static release-recapture guards,
and dynamic/static idle-or-releasing request assertions.
`.389` now ships that behavior. FSMGen emits
`axi0_w0_dynamic_id_release_recapture` and
`axi0_w1_static_busy_release_recapture`, keeps release-only rules disjoint from
same-transaction same-cycle requests, reports
`mixed_dynamic_static_dynamic_write` under
`response_demux.write.dynamic_capture` and
`mixed_dynamic_static_static_write` under
`response_demux.write.static_capture`, and replaces the selected
request-not-busy assertions with
`axi0_w0_dynamic_request_idle_or_releasing` and
`axi0_w1_static_request_idle_or_releasing`. Public syntax, support identity,
the mixed write mode, static-ID reservation, onehot0 request policy, response
active/unique-match, and completion-active assertions are preserved.
`.390` selects `.391`, public contract selection for mixed dynamic/static read
single-beat `RID` same-cycle release-and-recapture. The selector changes no
behavior. Guarded baseline schedule probes for the mixed read single-beat and
burst-last public samples passed below the 88% host-memory cutoff and
confirmed the post-`.389` read reports still use request-not-busy assertions
with no read-side release-recapture metadata or `static_capture` block.
Single-beat read is next so `.391` can adapt the `.389` dynamic/static
recapture vocabulary to `response_demux.read` while preserving
`bounded_mixed_dynamic_static_read_rid_demux_contract`,
`response_scope: single_beat`, and `generated_mixed_dynamic_static_read_demux`
before burst-last, read-data, raw-`ARLEN`, runtime-validation, and multi-beat
preservation layers are widened.
`.391` selects `.392`, direct implementation of mixed dynamic/static read
single-beat `RID` same-cycle release-and-recapture for the existing
support-accounted public sample. The selector changes no behavior. It
preserves public syntax, `bounded_mixed_dynamic_static_read_rid_demux_contract`,
`response_scope: single_beat`, generated mixed read completion source,
static-ID reservation, onehot0 mixed request policy, response
active/unique-match, and completion-active assertions while selecting
`response_demux.read.dynamic_capture` recapture fields, a new
`response_demux.read.static_capture` report block, dynamic/static release-only
exclusion, dynamic/static release-recapture guards, and dynamic/static
idle-or-releasing request assertions.
`.392` now ships that behavior. FSMGen emits
`axi0_r0_dynamic_id_release_recapture` and
`axi0_r1_static_busy_release_recapture`, keeps release-only rules disjoint from
same-transaction same-cycle requests, reports
`mixed_dynamic_static_dynamic_read` under
`response_demux.read.dynamic_capture` and
`mixed_dynamic_static_static_read` under
`response_demux.read.static_capture`, and replaces the selected
request-not-busy assertions with
`axi0_r0_dynamic_request_idle_or_releasing` and
`axi0_r1_static_request_idle_or_releasing`. Public syntax, support identity,
the mixed read single-beat mode/scope/source, static-ID reservation, onehot0
request policy, response active/unique-match, and completion-active assertions
are preserved. The mixed read burst-last `RID && RLAST` sample remains
unchanged with no recapture metadata or `static_capture` report block.
`.393` selects `.394`, readiness audit for mixed dynamic/static read
burst-last `RID && RLAST` same-cycle release-and-recapture. The selector
changes no behavior. Burst-last is the nearest sibling after `.392`, but it
needs audit before contract selection because final-only release and recapture
must preserve raw non-final `RID` beats, raw active/unique-match assertions,
scalar last-beat read-data, raw `ARLEN`, runtime beat-count/`RLAST`
validation, and multi-beat output-bank consumers.
`.394` selects `.395`, public contract selection for mixed dynamic/static read
burst-last `RID && RLAST` same-cycle release-and-recapture. The audit changes
no behavior. A guarded baseline schedule probe confirmed the existing
`bounded_mixed_dynamic_static_read_rid_rlast_demux_contract`,
`response_scope: burst_last`, `last_signal: axi0_rlast`, last-beat completion
source, request-not-busy assertions, no recapture metadata, and no
`static_capture` block. Contract selection is next so last-beat report source,
dynamic/static recapture fields, idle-or-releasing assertions, raw non-final
`RID` preservation, and read-data/raw-`ARLEN`/runtime/multi-beat consumers are
pinned before implementation.
`.395` selects `.396`, direct implementation of mixed dynamic/static read
burst-last `RID && RLAST` same-cycle release-and-recapture for the existing
public sample. The selector changes no behavior. The selected contract
preserves the burst-last mode/scope, `last_signal`, last-beat transaction
completion source, raw non-final `RID` assertions, and layered read-data/
raw-`ARLEN`/runtime/multi-beat consumers. It reuses
`mixed_dynamic_static_dynamic_read` and `mixed_dynamic_static_static_read`
policy names, with
`generated_mixed_dynamic_static_read_demux_last_beat_completion` as the
release-recapture source.
`.396` now ships that behavior under the existing public sample. FSMGen emits
`axi0_r0_dynamic_id_release_recapture` and
`axi0_r1_static_busy_release_recapture`, keeps release-only rules disjoint
from same-transaction same-cycle requests, drives both recapture paths from
generated final `RID && RLAST` completion pulses, reports the last-beat
release-recapture source under `response_demux.read.dynamic_capture` and
`response_demux.read.static_capture`, and replaces the selected
request-not-busy assertions with `axi0_r0_dynamic_request_idle_or_releasing`
and `axi0_r1_static_request_idle_or_releasing`. Public syntax, support
identity, the burst-last mode/scope/source, raw non-final `RID` assertions,
and the scalar read-data/raw-`ARLEN`/runtime/multi-beat consumers are
preserved.
`.397` selects `.398`, readiness audit for broader mixed dynamic/static
same-cycle release-and-recapture. The selector changes no behavior. Broader
mixed recapture is the nearest next residue now that the one-dynamic plus
one-static mixed write/read/read-`RLAST` family has shipped; multi-static,
three-static, and two-dynamic-plus-one-static public samples add sibling
static busy recapture, static-ID exclusion lists, active dynamic-ID
uniqueness, and read burst-last raw non-final beat preservation that need
audit ownership before contract selection or implementation. The `.396`
RAM-guard cutoff is recorded but is not selected as the next owner.
`.398` selects `.399`, public contract selection for one-dynamic plus
two-static mixed dynamic/static write `BID` same-cycle release-and-recapture.
The audit changes no behavior. Guarded baseline probes confirmed the
two-static, three-static, and two-dynamic-plus-one-static write samples still
report no `static_capture` recapture block; the two-static write sample is the
smallest broader owner because it adds sibling static busy recapture and
multiple static-ID exclusions without adding read `RLAST`/read-data
preservation or two-dynamic active-ID uniqueness.
`.399` selects `.400`, direct implementation of one-dynamic plus two-static
mixed dynamic/static write `BID` same-cycle release-and-recapture for the
existing multi-static public sample. The selector changes no behavior. The
selected contract preserves the list-shaped multi-mixed write mode/source,
transaction lists, static-ID reservations, response-demux rules, generated
completions, onehot0/static-ID-exclusion/active-match/unique-match/
completion-active assertions, and support-accounting identity. It adds
list-shaped recapture report fields under `dynamic_capture.transactions[]` and
`static_capture[]`, selects disjoint release-only and release-recapture guards
for `w0`, `w1`, and `w2`, and replaces the selected request-not-busy assertions
with idle-or-releasing names.
`.400` now ships one-dynamic plus two-static mixed dynamic/static write `BID`
same-cycle release-and-recapture for the existing multi-static public sample.
FSMGen emits dynamic `w0` selected-ID release-recapture and `w1`/`w2`
concrete static busy release-recapture, reports dynamic recapture under
`dynamic_capture.transactions[0]`, reports static recapture under list-shaped
`static_capture[]`, and replaces the selected `w0`/`w1`/`w2`
request-not-busy assertions with idle-or-releasing assertions. Public syntax,
support identity, mode/source/semantics, transaction lists, static-ID
reservations, response-demux matches, generated completions, onehot0/
static-ID-exclusion/active-match/pairwise-unique-match/completion-active
assertions, one-static singular recapture shape, and three-static
no-recapture shape are preserved. `.401` selects the next post two-static
mixed write recapture activity.
`.401` selects `.402`, public contract selection for one-dynamic plus
three-static mixed dynamic/static write `BID` same-cycle release-and-recapture
under the existing three-static public sample
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static3.ppif`.
The selector changes no behavior. Three-static write recapture is the smallest
post-`.400` behavior direction because it stays write-only and one-dynamic
while adding only one more concrete static sibling. Two-dynamic recapture
remains deferred behind active dynamic-ID uniqueness and no-active-same-ID
checks; broader mixed read recapture remains deferred behind `RID`/`RLAST`,
read-data, raw-`ARLEN`, runtime, and multi-beat preservation.
`.402` selects `.403`, direct implementation of one-dynamic plus three-static
mixed dynamic/static write `BID` same-cycle release-and-recapture for the
existing three-static public sample. The selector changes no behavior. The
selected contract preserves public syntax, support identity,
`bounded_multi_mixed_dynamic_static_write_bid_demux_contract`,
`generated_multi_mixed_dynamic_static_demux`,
`matched_dynamic_or_static_concrete_id`, transaction lists, static-ID
reservations for `4'd3`/`4'd5`/`4'd7`, generated demux rules/completions, and
onehot0/static-ID-exclusion/active-match/pairwise-unique-match/
completion-active assertions. It selects dynamic recapture fields under
`dynamic_capture.transactions[0]`, list-shaped `static_capture[]` entries for
`w1`/`w2`/`w3`, disjoint release-only and release-recapture guards for all
four transactions, and idle-or-releasing assertion names for `w0`/`w1`/`w2`/
`w3`.
`.403` now ships one-dynamic plus three-static mixed dynamic/static write
`BID` same-cycle release-and-recapture for the existing three-static public
sample. FSMGen emits dynamic `w0` selected-ID release-recapture and concrete
static `w1`/`w2`/`w3` busy release-recapture, reports dynamic recapture under
`dynamic_capture.transactions[0]`, reports static recapture under list-shaped
`static_capture[]`, makes release-only rules disjoint from same-transaction
same-cycle requests, and replaces `w0`/`w1`/`w2`/`w3` request-not-busy
assertions with idle-or-releasing assertions. Public syntax, support identity,
mode/source/semantics, transaction lists, static-ID reservations, generated
demux/completion behavior, onehot0/static-ID-exclusion/active-match/
pairwise-unique-match/completion-active assertions, the one-static singular
recapture shape, the two-static recapture shape, and the
two-dynamic-plus-one-static no-recapture shape are preserved. `.404` selects
the next post three-static mixed write recapture activity.
`.404` now selects `.405`, readiness audit for two-dynamic-plus-one-static
mixed dynamic/static write `BID` same-cycle release-and-recapture under the
existing `ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif`
sample. The selector changes no behavior. This is the nearest post-`.403`
residue because it stays write-only, but it needs an audit before contract
selection: the current mixed write recapture marker is capped at one dynamic
transaction, while the candidate composes two active dynamic selected-ID
owners, one concrete static owner, active dynamic-ID uniqueness,
no-active-same-ID checks, static-ID exclusions, list-shaped dynamic recapture
entries, and `static_capture`. Broader mixed read recapture remains deferred
behind raw non-final `RID`, `RLAST`, read-data, raw-`ARLEN`, runtime, and
multi-beat preservation.
`.405` now selects `.406`, public contract selection for the same
two-dynamic-plus-one-static mixed dynamic/static write `BID` same-cycle
release-and-recapture boundary. The audit changes no behavior. It found no
smaller parser/source/support-accounting/report/assertion substrate
prerequisite: the existing state builder already computes sibling dynamic
request blocks, active sibling same-ID blocks, static request blocks,
static-ID exclusions, static dynamic-request blocks, idle-or-releasing names,
no-active-same-ID assertions, active dynamic-ID uniqueness, response
active-match, unique-match, and completion-active surfaces. Contract
selection remains required before implementation because the current mixed
write recapture marker is capped at one dynamic transaction and the dynamic
recapture helper currently chooses either multi-active dynamic guards or mixed
static guards. A guarded candidate schedule probe stopped before usable
output at host memory 89.5% against the default 88% cutoff; no cutoff was
raised. Broader mixed read recapture remains deferred behind raw non-final
`RID`, `RLAST`, read-data, raw-`ARLEN`, runtime, and multi-beat preservation.
`.406` now selects `.407`, direct implementation of two-dynamic-plus-one-static
mixed dynamic/static write `BID` same-cycle release-and-recapture for the
existing
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif`
sample. The selector changes no behavior. The contract preserves public
syntax, support identity, the multi-mixed write mode/source/semantics,
transaction lists, static ID `4'd3`, generated demux/completion behavior, and
onehot0/no-active-same-ID/active dynamic-ID uniqueness/static-ID-exclusion/
active-match/unique-match/completion-active assertions. It selects dynamic
recapture fields for both `dynamic_capture.transactions[]` entries, new
dynamic policy `mixed_dynamic_static_multi_active_dynamic_write`,
`release_recapture_source: generated_multi_mixed_dynamic_static_demux_completion`,
list-shaped
`static_capture[]` for `w2`, combined dynamic guards across sibling dynamic
request, active sibling same-ID, static request, and static-ID exclusion
blocks, static recapture guarded against both dynamic requests, release-only
exclusion of same-transaction requests, and idle-or-releasing assertions for
`w0`/`w1`/`w2`. Broader mixed read recapture remains deferred behind raw
non-final `RID`, `RLAST`, read-data, raw-`ARLEN`, runtime, and multi-beat
preservation.
`.407` now ships two-dynamic-plus-one-static mixed dynamic/static write `BID`
same-cycle release-and-recapture for the existing
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif`
sample. FSMGen emits `axi0_w0_dynamic_id_release_recapture`,
`axi0_w1_dynamic_id_release_recapture`, and
`axi0_w2_static_busy_release_recapture`, reports
`mixed_dynamic_static_multi_active_dynamic_write` for both dynamic capture
transaction entries, reports list-shaped `static_capture[]` for `w2`, keeps
release-only rules disjoint from same-transaction requests, composes dynamic
guards across sibling dynamic request, active sibling same-ID, static request,
and static-ID exclusion blocks, guards static recapture against both dynamic
requests, and replaces `w0`/`w1`/`w2` request-not-busy assertions with
idle-or-releasing assertions. Syntax checks passed. Guarded selected schedule
JSON and focused t/1438 probes stopped before usable output at host memory
94.5% and 92.5% against the default 88% cutoff; no cutoff was raised. `.408`
now selects `.409`, readiness audit for one-dynamic-plus-two-static mixed
dynamic/static read single-beat `RID` same-cycle release-and-recapture. The
selector changes no behavior. It chooses the read single-beat one-dynamic plus
two-static sample because broader mixed write recapture is now covered, while
read burst-last recapture adds raw non-final `RID`, final `RLAST`, read-data,
raw-`ARLEN`, runtime, and multi-beat preservation, and two-dynamic read
recapture adds active dynamic-ID uniqueness and no-active-same-ID guards. A
guarded candidate schedule probe stopped before usable output at host memory
92.0% against the default 88% cutoff; output was 0 bytes and no cutoff was
raised.
`.409` now selects `.410`, public contract selection for
one-dynamic-plus-two-static mixed dynamic/static read single-beat `RID`
same-cycle release-and-recapture. The audit changes no behavior. A guarded
baseline schedule probe for
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif`
completed at host memory 79.6% against the default 88% cutoff and produced a
44021-byte schedule report. The live report still has request-not-busy
assertions for `r0`/`r1`/`r2`, no `static_capture`, and no
release-recapture fields under `dynamic_capture.transactions[]`. No smaller
parser/source/support-accounting/report-substrate or lower IAL prerequisite
was found before contract selection; direct behavior remains deferred until
list-shaped static read recapture, dynamic guard composition,
idle-or-releasing assertion names, and scalar read-data preservation are
contract-owned.
`.410` now selects `.411`, direct implementation of one-dynamic-plus-two-static
mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture
for the existing support-accounted public sample. The selector changes no
behavior. A guarded baseline schedule probe completed at host memory 83.5%
against the default 88% cutoff and produced a 44021-byte report. The selected
contract preserves the public syntax, support identity, multi-mixed read
single-beat mode, generated completion source, response semantics,
dynamic/static/mixed transaction lists, static ID reservations, generated
demux rules/completions, onehot0/static-ID-exclusion/active-match/
unique-match/completion-active assertions, and scalar single-beat read-data
consumers. It selects dynamic recapture fields for
`dynamic_capture.transactions[0]`, list-shaped `static_capture[]` entries for
`r1`/`r2`, `mixed_dynamic_static_dynamic_read`,
`mixed_dynamic_static_static_read`,
`generated_multi_mixed_dynamic_static_read_demux_completion`,
idle-or-releasing assertions for `r0`/`r1`/`r2`, dynamic guards across both
static requests and static-ID exclusions, static guards across dynamic request
and sibling static request, and same-transaction request exclusion on
release-only rules.
`.411` now ships one-dynamic-plus-two-static mixed dynamic/static read
single-beat `RID` same-cycle release-and-recapture for the existing public
sample. FSMGen emits `axi0_r0_dynamic_id_release_recapture`,
`axi0_r1_static_busy_release_recapture`, and
`axi0_r2_static_busy_release_recapture`; reports
`mixed_dynamic_static_dynamic_read` under
`dynamic_capture.transactions[0]`; reports list-shaped `static_capture[]` for
`r1`/`r2`; uses
`generated_multi_mixed_dynamic_static_read_demux_completion`; keeps
release-only rules disjoint from same-transaction requests; composes dynamic
guards across both static requests and both static-ID exclusions; composes
static guards across dynamic request and sibling static request; and replaces
`r0`/`r1`/`r2` request-not-busy assertions with idle-or-releasing assertions.
The singular mixed read recapture shape, the three-static no-recapture
boundary, and scalar single-beat read-data consumers remain preserved.
Guarded selected schedule, strict check, semantic JSON, SystemVerilog, and
verify-hdl probes passed; guarded focused `t/1438` stopped at the RAM cutoff
before TAP output. `.412` now selects the next post-read-recapture activity.
`.412` now selects `.413`, readiness audit for one-dynamic-plus-two-static
mixed dynamic/static read burst-last `RID && RLAST` same-cycle
release-and-recapture. The selector changes no behavior. A guarded baseline
schedule probe for
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif`
started at host memory 85.2% against the default 88% cutoff and produced a
44340-byte report. The live burst-last report still uses
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`,
`response_scope: burst_last`,
`generated_multi_mixed_dynamic_static_read_demux_last_beat`,
request-not-busy assertions for `r0`/`r1`/`r2`, no `static_capture`, and no
release-recapture fields under `dynamic_capture.transactions[]`. The next
audit must pin final-beat release-recapture source, raw non-final `RID`
preservation, list-shaped `static_capture[]`, idle-or-releasing assertion
renames, and scalar read-data/raw-`ARLEN`/runtime/multi-beat preservation
before implementation.
`.413` now selects `.414`, public contract selection for
one-dynamic-plus-two-static mixed dynamic/static read burst-last `RID &&
RLAST` same-cycle release-and-recapture. The audit changes no behavior. A
guarded baseline schedule probe for the same public burst-last sample started
at host memory 86.3% against the default 88% cutoff and produced a 44340-byte
report showing request-not-busy assertions, no `static_capture`, and no
release-recapture fields. No lower parser, PPIF syntax, support-accounting,
IAL1/HDL lowering, or report-schema prerequisite was found. The next contract
selection must pin
`generated_multi_mixed_dynamic_static_read_demux_last_beat_completion`,
`dynamic_capture.transactions[0]`, list-shaped `static_capture[]`, raw
non-final `RID` preservation, and scalar read-data/raw-`ARLEN`/runtime/
multi-beat preservation before implementation.
`.414` now selects `.415`, direct implementation of that
one-dynamic-plus-two-static mixed dynamic/static read burst-last `RID &&
RLAST` same-cycle release-and-recapture contract. The selector changes no
behavior. The selected contract preserves public syntax, support identity,
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`,
`response_scope: burst_last`, `last_signal: axi0_rlast`,
`generated_multi_mixed_dynamic_static_read_demux_last_beat`, final-beat
completion semantics, `r0`/`r1`/`r2` transaction lists, static ID
reservations for `4'd3` and `4'd5`, generated demux/completion behavior, raw
`RID` assertions, completion-active assertions, and scalar read-data/
raw-`ARLEN`/runtime/multi-beat consumers. It selects
`dynamic_capture.transactions[0]`, list-shaped `static_capture[]`,
`generated_multi_mixed_dynamic_static_read_demux_last_beat_completion`,
mixed read policy names, dynamic/static guard composition, release-only
same-transaction request exclusions, and idle-or-releasing assertion names
for the implementation owner.
`.415` now ships that one-dynamic-plus-two-static mixed dynamic/static read
burst-last `RID && RLAST` same-cycle release-and-recapture behavior. FSMGen
reports dynamic recapture under `dynamic_capture.transactions[0]`,
list-shaped static recapture under `static_capture[]`, final-beat source
`generated_multi_mixed_dynamic_static_read_demux_last_beat_completion`, and
idle-or-releasing assertions for `r0`/`r1`/`r2`. Public syntax, support
identity, burst-last mode/source/semantics, generated demux/completion
behavior, raw `RID` active/unique-match assertions, completion-active
assertions, one-static RLAST recapture, three-static no-recapture,
two-dynamic-plus-one-static no-recapture, and scalar read-data/raw-`ARLEN`/
runtime/multi-beat consumers remain preserved. Guarded selected schedule JSON
passed and produced a 46549-byte report; focused `t/1438`, strict check JSON,
semantic JSON, SystemVerilog generation, and `--verify-hdl` stopped at the
default 88% RAM guard cutoff before completion, with no cutoff raised. `.416`
now selects the next post two-static mixed read burst-last recapture slice.
`.416` now selects `.417`, readiness audit for one-dynamic-plus-three-static
mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture.
The selector changes no behavior. A guarded baseline schedule probe for
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3.ppif`
started at host memory 87.3% against the default 88% cutoff and produced a
46985-byte report showing request-not-busy assertions for `r0`/`r1`/`r2`/
`r3`, no `static_capture`, and no release-recapture fields. `.417` must pin
three-static `static_capture[]`, dynamic/static guard composition,
idle-or-releasing assertions, validation gates, rollback, docs, Knowledge Map
impact, and deferred burst-last/two-dynamic/backend boundaries before any
behavior change.
`.417` now selects `.418`, public contract selection for
one-dynamic-plus-three-static mixed dynamic/static read single-beat `RID`
same-cycle release-and-recapture. The audit changes no behavior. It found no
lower parser, PPIF syntax, support-accounting, report-schema, or IAL1/HDL
prerequisite before contract selection: the public three-static read sample
and list-shaped report mode already ship, rule/assertion helpers already
compose over dynamic/static request and static-ID guard arrays, and the mixed
read recapture marker body already projects list-shaped static capture entries
after its current one-or-two-static selection guard. `.418` must pin the
exact report, guard, assertion, validation, rollback, docs, Knowledge Map,
and deferred-boundary contract before implementation.
`.418` now selects `.419`, direct implementation of
one-dynamic-plus-three-static mixed dynamic/static read single-beat `RID`
same-cycle release-and-recapture for
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3.ppif`.
The selector changes no behavior. The selected contract preserves public
syntax/support identity,
`bounded_multi_mixed_dynamic_static_read_rid_demux_contract`,
`response_scope: single_beat`,
`transaction_completion_source: generated_multi_mixed_dynamic_static_read_demux`,
`transaction_completion_semantics:
matched_dynamic_or_static_concrete_id_single_beat`, `r0`/`r1`/`r2`/`r3`
transaction lists, static-ID reservations for `4'd3`/`4'd5`/`4'd7`,
generated demux/completion behavior, onehot0, static-ID exclusions,
response-active-match, pairwise unique-match, completion-active assertions,
and adjacent three-static read-data/raw-`ARLEN`/runtime/multi-beat consumers.
It selects `dynamic_capture.transactions[0]` recapture fields, list-shaped
`static_capture[]` entries for `r1`/`r2`/`r3`, release-recapture source
`generated_multi_mixed_dynamic_static_read_demux_completion`, dynamic/static
guard composition, release-only same-transaction request exclusions, and
idle-or-releasing assertion names. A fresh guarded baseline schedule attempt
stopped at the default 88% host RAM cutoff because host memory started at
88.1%; no cutoff was raised, and the `.416`/`.417` 46985-byte baseline
remains the recorded evidence.
`.419` now ships one-dynamic-plus-three-static mixed dynamic/static read
single-beat `RID` same-cycle release-and-recapture for
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3.ppif`.
The implementation widens only the selected single-beat marker path and
focused expectation. Reports now include dynamic recapture under
`dynamic_capture.transactions[0]`, list-shaped `static_capture[]` entries for
`r1`/`r2`/`r3`,
`generated_multi_mixed_dynamic_static_read_demux_completion`, guard
composition across three static requests/static-ID exclusions and both static
siblings, release-only same-transaction request exclusions, and
idle-or-releasing assertions for all four read transactions. Public syntax,
support identity, mode/scope/source/semantics, onehot0/static-ID/
active-match/unique-match/completion-active assertions, one-/two-static read
recapture, three-static burst-last no-recapture,
two-dynamic-plus-one-static no-recapture, and three-static read-data consumers
remain preserved. Syntax and direct normalizer/rule/preservation probes
passed. Guarded selected schedule and focused `t/1438` probes stopped because
host memory was already above the default 88% cutoff; no cutoff was raised.
`.420` now selects the next exact post-recapture owner.
`.420` now selects `.421`, readiness audit for one-dynamic-plus-three-static
mixed dynamic/static read burst-last `RID && RLAST` same-cycle
release-and-recapture. The selector changes no behavior. A direct baseline
probe for
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif`
confirmed the current report remains
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`,
`response_scope: burst_last`,
`generated_multi_mixed_dynamic_static_read_demux_last_beat`, no
`static_capture`, no dynamic recapture fields, and four request-not-busy
assertions. The audit comes next because `.419` shipped the three-static
single-beat recapture sibling, `.415` shipped the two-static burst-last
precedent, `.326` already ships the three-static burst-last demux public
sample, and the burst-last normalizer still marks recapture only for exactly
one dynamic plus two static states.
`.421` now selects `.422`, public contract selection for
one-dynamic-plus-three-static mixed dynamic/static read burst-last `RID &&
RLAST` same-cycle release-and-recapture. The audit changes no behavior. A
direct normalizer/report probe confirmed the current public three-static
burst-last baseline remains
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract` with
`response_scope: burst_last`, `last_signal: axi0_rlast`,
`last_signal_width: 1`,
`generated_multi_mixed_dynamic_static_read_demux_last_beat`, no
`static_capture`, no dynamic recapture fields, and four request-not-busy
assertions. A direct marker probe confirmed the existing marker substrate
already sees one dynamic plus three static states and projects
`mixed_dynamic_static_dynamic_read`,
`generated_multi_mixed_dynamic_static_read_demux_last_beat_completion`, and
three `static_capture` entries for `r1`/`r2`/`r3` if invoked. The remaining
implementation gap is deliberate selection logic in the burst-last normalizer
and focused RLAST expectations, so `.422` must pin the public contract before
behavior changes.
`.422` now selects `.423`, direct implementation of
one-dynamic-plus-three-static mixed dynamic/static read burst-last `RID &&
RLAST` same-cycle release-and-recapture for the existing support-accounted
sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif`.
The selector changes no behavior. The selected contract preserves public
syntax/support identity,
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`,
`response_scope: burst_last`, one-bit `axi0_rlast`,
`generated_multi_mixed_dynamic_static_read_demux_last_beat`, final-beat
match semantics, `r0`/`r1`/`r2`/`r3` transaction lists, static ID
reservations for `4'd3`/`4'd5`/`4'd7`, generated demux/completion behavior,
raw non-final `RID` ownership evidence, adjacent read-data consumers, dynamic
recapture under `dynamic_capture.transactions[0]`, list-shaped
`static_capture[]` entries for `r1`/`r2`/`r3`,
`generated_multi_mixed_dynamic_static_read_demux_last_beat_completion`,
dynamic/static guard composition, release-only same-transaction request
exclusions, idle-or-releasing assertion names, validation gates, RAM-guard
fallback probes, rollback, docs, Knowledge Map impact, and deferred
two-dynamic/backend/VHDL boundaries.
`.423` now ships that one-dynamic-plus-three-static mixed dynamic/static read
burst-last `RID && RLAST` same-cycle release-and-recapture behavior. The
implementation widens only the burst-last multi-mixed read recapture selector
from exactly one dynamic plus two static read transactions to exactly one
dynamic plus two or three static read transactions, and aligns the focused
RLAST report expectation helper. The selected public sample now reports
dynamic recapture under `dynamic_capture.transactions[0]`, list-shaped
`static_capture[]` entries for `r1`/`r2`/`r3`,
`generated_multi_mixed_dynamic_static_read_demux_last_beat_completion`,
r0/r1/r2/r3 idle-or-releasing assertions, and generated `r3` static
release-recapture rule wiring. Direct preservation probes confirmed the
one-static and two-static RLAST recapture shapes, the
two-dynamic-plus-one-static no-recapture boundary, and the three-static
read-data completion-validity contract remain in their expected shapes.
Guarded selected schedule JSON passed; guarded focused `t/1438`, strict
check JSON, and generated-SV attempts tripped the default RAM guard when host
memory rose above cutoff; guarded verify-HDL was skipped after those repeated
trips. Fallback direct adapter/report and FSM-to-SystemVerilog probes were
used without raising the cutoff. `.424` is now the next selector after this
recapture shipment.
`.424` now selects `.425`, readiness audit for two-dynamic-plus-one-static
mixed dynamic/static read single-beat `RID` same-cycle release-and-recapture
on
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif`.
The selector changes no behavior. A direct adapter/report probe confirmed the
current two-dynamic-plus-one-static mixed read single-beat and burst-last
reports still have no release-recapture fields, no `static_capture`, three
request-not-busy assertions, and zero idle-or-releasing assertions. The
single-beat shape is selected for audit before burst-last because it exercises
multi-dynamic selected-ID recapture, active same-ID blocking, static concrete
busy recapture, onehot0 mixed request policy, no-active-same-ID assertions,
and active dynamic-ID uniqueness without final-only `RLAST` release-source or
raw non-final `RID` questions.
`.425` now selects `.426`, public contract selection for
two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID`
same-cycle release-and-recapture on the same public sample. The audit changes
no behavior. A guarded schedule JSON probe stopped because host memory was
already 95.3% against the default 88% cutoff, so direct fallback probes were
used. Direct probes confirmed the selected sample remains no-recapture today:
no dynamic release-recapture fields, no `static_capture`, no
release-recapture rules in ISF, and request-not-busy assertions for
`r0`/`r1`/`r2`. The audit found the read guard operands already exist; the
contract-selection leaf should pin `mixed_dynamic_static_multi_active_dynamic_read`,
list-shaped static capture for `r2`,
`generated_multi_mixed_dynamic_static_read_demux_completion`, and
idle-or-releasing assertions for `r0`, `r1`, and `r2`.
`.426` now selects `.427`, direct implementation of that
two-dynamic-plus-one-static mixed dynamic/static read single-beat recapture
contract. The selector changes no behavior. The contract preserves the
existing public syntax, support identity,
`bounded_multi_mixed_dynamic_static_read_rid_demux_contract`,
`generated_multi_mixed_dynamic_static_read_demux`, and
`matched_dynamic_or_static_concrete_id_single_beat`; it adds dynamic
recapture fields for `r0`/`r1` with
`mixed_dynamic_static_multi_active_dynamic_read`, list-shaped
`static_capture[]` for `r2`, the generated mixed read completion source,
combined dynamic/static guards, same-transaction release-only exclusions, and
idle-or-releasing assertions for `r0`, `r1`, and `r2`.
`.427` now ships that two-dynamic-plus-one-static mixed dynamic/static read
single-beat `RID` same-cycle release-and-recapture behavior for the existing
public sample. FSMGen emits `axi0_r0_dynamic_id_release_recapture`,
`axi0_r1_dynamic_id_release_recapture`, and
`axi0_r2_static_busy_release_recapture`; reports
`mixed_dynamic_static_multi_active_dynamic_read` under both dynamic
`dynamic_capture.transactions[]` entries; reports list-shaped
`static_capture[]` for `r2`; composes dynamic guards across sibling dynamic
requests, active sibling same-ID, static requests, and static-ID exclusion;
composes static guards across both dynamic requests; and replaces the
`r0`/`r1`/`r2` request-not-busy assertions with idle-or-releasing assertions.
The two-dynamic burst-last and read-data/raw-`ARLEN`/runtime/multi-beat
consumers remain no-recapture preservation boundaries. A guarded focused
`t/1438` selected filter stopped at the RAM cutoff before TAP output; direct
report and ISF/FSM/SystemVerilog fallback probes covered the selected
behavior. `.428` now selects the next post two-dynamic mixed read recapture
slice.
`.428` now selects `.429`, readiness audit for two-dynamic-plus-one-static
mixed dynamic/static read burst-last `RID && RLAST` same-cycle
release-and-recapture. The selector changes no behavior. Direct baseline
probes on the burst-last response-demux, burst-last read-data, and burst-last
raw-`ARLEN` samples confirmed they still use
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`,
`generated_multi_mixed_dynamic_static_read_demux_last_beat`,
request-not-busy assertions for `r0`/`r1`/`r2`, no `static_capture`, and no
release-recapture rules. The audit is next because this shape reuses the
`.427` dynamic/static guard problem but adds final-beat source, raw non-final
`RID`, `RLAST`, and read-data/raw-`ARLEN`/runtime/multi-beat preservation
questions before any behavior change.
`.429` now selects `.430`, public contract selection for the same
two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID &&
RLAST` release-and-recapture boundary. The audit changes no behavior. It found
no lower parser, support-accounting, report-schema, IAL1, or HDL prerequisite:
`.427` already supplied the read-side multi-active mixed recapture policy and
guard storage, while the burst-last normalizer is the remaining selector that
leaves the two-dynamic/one-static RLAST branch unmarked. `.430` must pin
`generated_multi_mixed_dynamic_static_read_demux_last_beat_completion`,
dynamic/static report fields, guard composition, idle-or-releasing assertion
names, and read-data/raw-`ARLEN`/runtime/multi-beat preservation before
implementation.
`.430` now selects `.431`, direct implementation of that
two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID &&
RLAST` release-and-recapture contract. The selector changes no behavior. The selected
implementation keeps the existing public sample, support identity,
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`,
`axi0_rlast`, final-beat completion source, raw non-final `RID` assertion
roles, completion-active assertions, and read-data/raw-`ARLEN`/runtime/
multi-beat consumers. It adds `r0`/`r1` dynamic recapture fields with
`mixed_dynamic_static_multi_active_dynamic_read`, list-shaped
`static_capture[]` for `r2`, final-beat release-recapture source
`generated_multi_mixed_dynamic_static_read_demux_last_beat_completion`,
combined dynamic/static guards, release-only same-transaction request
exclusions, and idle-or-releasing assertions for `r0`, `r1`, and `r2`.
`.431` now ships that two-dynamic-plus-one-static mixed dynamic/static read
burst-last `RID && RLAST` release-and-recapture behavior. FSMGen emits
`axi0_r0_dynamic_id_release_recapture`,
`axi0_r1_dynamic_id_release_recapture`, and
`axi0_r2_static_busy_release_recapture` from generated final-beat completion
pulses only; reports `r0`/`r1` recapture under
`dynamic_capture.transactions[]`; reports list-shaped `static_capture[]` for
`r2`; keeps release-only rules disjoint from same-transaction requests; and
replaces the selected request-not-busy assertions with idle-or-releasing
assertions. Public syntax, support identity, mode/source/semantics, raw
non-final `RID` active/unique-match assertions, final-beat completion
ownership, `.427` single-beat recapture, one-/two-/three-static burst-last
recapture, and read-data/raw-`ARLEN`/runtime/multi-beat consumers are
preserved. A guarded focused `t/1438` selected-case run stopped at host memory
93.0% against the default 88% cutoff; direct report/ISF/FSM/SystemVerilog
probes covered the selected behavior. `.432` is the next post two-dynamic
mixed read burst-last recapture selector.
`.432` now selects `.433`, readiness audit for dynamic same-ID issue-order
policy, queue, and scoreboard ownership after the bounded dynamic/mixed
response-demux, read-data, multi-beat, and same-cycle release-and-recapture
chain reached the two-dynamic-plus-one-static read burst-last boundary. The
selector changes no behavior. It records that dynamic transaction-ID
contract/report support and generated bounded dynamic/mixed response-demux
behavior now exist, while direct same-ID queue or scoreboard behavior still
needs public issue-order policy, request arbitration, overflow/ambiguity
assertions, and report/residue movement before implementation.
`.433` now selects `.434`, public dynamic same-ID policy contract selection
before dynamic per-ID queues, scoreboards, parser/report implementation, or
generated behavior. The audit changes no behavior. It records that bounded
dynamic and mixed response-demux/read-data/multi-beat/recapture substrate now
exists, while dynamic same-ID reuse still lacks source/report vocabulary
distinct from `concrete-id-reuse`. Direct queues or scoreboards remain
deferred until `.434` chooses the dynamic policy spelling, report fields,
diagnostics, allowed first policy values, and first later owner.
`.434` now selects the additive family-local `(dynamic-id-reuse reject)`
source contract under `(same-id-ordering ...)`, distinct from existing
`concrete-id-reuse`, and selects `.435`, metadata-first parser/report
readiness audit before implementation. The selector changes no behavior. The
first dynamic same-ID policy value is only `reject`; dynamic
`issue-order-queue` and `scoreboard` values remain unsupported future owners.
The selected report vocabulary is
`same_id_ordering.dynamic_id_reuse_policy.<family>`, with accepted same-ID
reuse false and no generated queue or scoreboard behavior.
`.435` now selects `.436`, direct metadata-first parser/report implementation
for `(dynamic-id-reuse reject)`. The audit changes no behavior. It found no
lowerer, HDL, support-accounting infrastructure, Knowledge Map, or mdBook
prerequisite. `.436` should add the public syntax, normalized report fields,
focused diagnostics, a metadata-only public sample, and support accounting,
while keeping generated dynamic response-demux plus dynamic same-ID policy
fail-closed until a later owner maps generated no-active-same-ID assertion
enforcement.
`.436` now ships metadata-first parser/report support for the selected
`(dynamic-id-reuse reject)` policy under `(same-id-ordering ...)`. PPIF accepts
dynamic-only family arms and coexistence with existing concrete
`concrete-id-reuse` clauses; empty arms, duplicate dynamic clauses,
unsupported dynamic policy values, selected dynamic policy without
transactions, selected dynamic policy without a same-family dynamic
transaction, and concrete-only same-ID policy against dynamic transaction IDs
fail closed with targeted diagnostics. At the `.436` metadata-only boundary,
dynamic response-demux plus same-family dynamic policy also failed closed;
later `.438` and `.442` slices accept covered generated response-demux
assertion mappings. Reports now carry
`same_id_ordering.dynamic_id_reuse_policy.<family>` with `policy: reject`,
`implementation_status: selected_not_generated`, `enforcement:
not_generated`, `accepted_same_id_reuse: false`,
`request_conflict_policy: no_active_same_id`, and no generated queue or
scoreboard behavior. Dynamic-only policy uses
`same_id_ordering.mode: dynamic_id_reuse_policy`; concrete plus dynamic policy
uses `id_reuse_policy`. The public sample
`ppif/axi_manager_capacity_status_dynamic_same_id_reject_policy.ppif` is
support-accounted as
`intent.ppif_axi_manager_capacity_status_dynamic_same_id_reject_policy`.
At this metadata-first boundary, generated dynamic same-ID enforcement and
response-demux mapping were still deferred; later `.438` and `.442` slices now
cover bounded generated response-demux assertion mappings. Dynamic queues,
scoreboards, HDL behavior, and VHDL behavior remain deferred.
`.437` now selects `.438`, a narrow generated-enforcement report mapping for
selected `dynamic-id-reuse reject` policy over already generated multi-active
dynamic and mixed dynamic/static response-demux shapes. The audit changes no
behavior. The first covered shapes are bounded multiple all-dynamic write/read
response demux and bounded two-dynamic-plus-one-static mixed write/read
response demux where generated reports already expose
`active_dynamic_ids_must_be_unique`, `*_dynamic_request_no_active_same_id`,
and `*_dynamic_active_id_unique` artifacts. Single-active dynamic demux,
one-dynamic mixed demux, queues, scoreboards, direct backend behavior, and
VHDL remain deferred.
`.438` now ships that generated-enforcement report mapping. Same-family
`response-demux.<family>` plus `same-id-ordering.<family>
(dynamic-id-reuse reject)` is accepted for the covered multi-active
all-dynamic and two-dynamic-plus-one-static mixed response-demux shapes
without adding generated rules, storage, assertions, HDL behavior, or runtime
behavior. Covered dynamic policy reports use `implementation_status:
generated_no_active_same_id_reject`, `enforcement:
generated_no_active_same_id_assertions`, `assertion_enforcement:
runtime_assertion`, `response_demux_covered: true`, response-demux
mode/source metadata, covered dynamic transactions, and exact generated
no-active-same-ID plus active-ID uniqueness assertion names. The
support-accounted public sample is
`ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_same_id_reject.ppif`.
Single-active dynamic demux, one-dynamic mixed demux, queues, scoreboards,
direct backend behavior, backend-language variants, and VHDL remain deferred.
`.439` now selects `.440`, readiness audit for single-active dynamic
same-ID reject mapping. Single-active dynamic response-demux already exposes
generated `*_dynamic_request_idle_or_releasing`, active-match, and
completion-active assertions for write `BID`, read single-beat `RID`, and read
burst-last `RID && RLAST`, but it does not expose the `.438` multi-active
`*_dynamic_request_no_active_same_id` plus `*_dynamic_active_id_unique`
assertion pair. The next audit must decide whether a single-active-specific
generated reject report contract is honest or whether the current fail-closed
behavior remains. One-dynamic mixed mapping, dynamic queues, scoreboards,
direct backend behavior, backend-language variants, VHDL, and new generated HDL
remain deferred.
`.440` now selects `.441`, public contract selection for that single-active
mapping. Guarded compact probes confirmed the single-active write `BID`, read
single-beat `RID`, and read burst-last `RID && RLAST` samples expose generated
`*_dynamic_request_idle_or_releasing`, active-match, and completion-active
assertions while still carrying `same_id_ordering` residue. Temporary guarded
single-active same-ID reject probes still fail closed at the `.438` generated
multi-active no-active-same-ID diagnostic. The existing idle-or-releasing
assertions are strong enough for a single-active generated reject contract, but
they are not the `.438` multi-active evidence model, so `.441` must select
exact report fields, residue movement, and diagnostics before behavior changes.
One-dynamic mixed mapping, dynamic queues, scoreboards, direct backend
behavior, backend-language variants, VHDL, and new generated HDL remain
deferred.
`.442` now ships the single-active dynamic same-ID reject mapping. Same-family
`response-demux.<family>` plus `same-id-ordering.<family>
(dynamic-id-reuse reject)` is accepted for single-active dynamic write `BID`,
read single-beat `RID`, and read burst-last `RID && RLAST` shapes that already
report generated idle-or-releasing, active-match, and completion-active
assertions. Covered policy reports use
`implementation_status: generated_single_active_reject`, `enforcement:
generated_idle_or_releasing_assertions`, `single_active_covered: true`, and
`single_active_request_policy: idle_or_releasing`, while preserving
`accepted_same_id_reuse: false`, `request_conflict_policy:
no_active_same_id`, and generated queue/scoreboard false. They list generated
idle-or-releasing, active-match, and completion-active assertion names and
deliberately do not reuse the `.438` multi-active
`generated_no_active_same_id_assertions` or
`generated_active_id_uniqueness_assertions` fields. The support-accounted
public sample is
`ppif/axi_manager_capacity_status_dynamic_read_response_demux_same_id_reject.ppif`.
The mapping adds no generated rules, storage, assertions, HDL, or runtime
behavior; one-dynamic mixed mapping, dynamic queues, scoreboards, direct
backend behavior, backend-language variants, VHDL, and new generated HDL remain
deferred. `.442` selects `.443`, the next post-single-active-mapping selector.
`.443` now selects `.444`, readiness audit for one-dynamic mixed
dynamic/static dynamic same-ID reject mapping. The selector changes no
behavior. It compares the remaining one-dynamic mixed fail-closed boundary
against the generated mixed response-demux evidence: static concrete ID
reservation/exclusion, dynamic request-not-static-ID and
active-not-static-ID assertions, mixed request onehot0, response
active/unique-match, and completion-active assertions. The audit must decide
whether that evidence can support a generated reject report contract distinct
from `.438` multi-active no-active-same-ID coverage and `.442` single-active
idle-or-releasing coverage, or whether the current fail-closed behavior should
remain. Dynamic queues, scoreboards, direct backend behavior,
backend-language variants, VHDL, and new generated HDL remain deferred.
`.444` now selects `.445`, public report contract selection for one-dynamic
mixed dynamic/static dynamic same-ID reject mapping. Guarded schedule probes
confirmed representative mixed write, read single-beat, read burst-last,
three-static write, and three-static read burst-last samples expose static-ID
reservation/exclusion, mixed request onehot0, response active/unique-match,
and completion-active assertion evidence. A guarded temporary read probe still
failed closed at the generated multi-active no-active-same-ID diagnostic. The
evidence is ready for contract selection, but direct implementation is
deferred because one-dynamic mixed mapping needs report fields and residue
rules distinct from both `.438` multi-active and `.442` single-active
coverage. Dynamic queues, scoreboards, direct backend behavior,
backend-language variants, VHDL, and new generated HDL remain deferred.
`.445` now selects `.446`, direct implementation of the one-dynamic mixed
dynamic/static dynamic same-ID reject report/acceptance mapping. The selected
contract covers generated mixed write `BID`, read single-beat `RID`, and read
burst-last `RID && RLAST` response-demux shapes with exactly one dynamic
transaction plus one, two, or three pairwise-distinct concrete static
transactions. Covered reports use `implementation_status:
generated_mixed_static_id_exclusion_reject`, `enforcement:
generated_static_id_exclusion_assertions`, `mixed_dynamic_static_covered:
true`, `mixed_dynamic_static_request_policy: onehot0_mixed_request`,
`static_id_conflict_policy: static_concrete_ids_reserved`, and
`static_id_exclusion_policy: dynamic_id_must_not_equal_static_concrete_id`,
while preserving `accepted_same_id_reuse: false`,
`request_conflict_policy: no_active_same_id`, and generated queue/scoreboard
false. The mapping is bounded to acceptance/report/residue movement over
existing generated static-ID exclusion, mixed request onehot0, response
active/unique-match, and completion-active evidence; it does not add generated
rules, storage, assertions, HDL, runtime behavior, direct backend behavior,
backend-language variants, queues, scoreboards, VHDL, or new generated HDL.
`.446` now ships that one-dynamic mixed dynamic/static dynamic same-ID reject
mapping. Same-family `response-demux.<family>` plus
`same-id-ordering.<family> (dynamic-id-reuse reject)` is accepted for
generated mixed write `BID`, read single-beat `RID`, and read burst-last
`RID && RLAST` shapes with exactly one dynamic transaction plus one, two, or
three pairwise-distinct concrete static transactions. Covered reports use the
`.445` selected `generated_mixed_static_id_exclusion_reject` and
`generated_static_id_exclusion_assertions` contract, list exact static-ID
reservations, dynamic request/active static-ID exclusion assertions, mixed
request onehot0 assertions, response active/unique-match assertions, and
completion-active assertions, and remove only covered same-family
`same_id_ordering` residue. No new public PPIF sample or support-accounting
entry is added; focused tests insert the same-ID policy into existing
support-accounted mixed response-demux samples in memory and compare generated
IAL1/IAL0 artifacts against the original samples. Dynamic queues,
scoreboards, direct backend behavior, backend-language variants, VHDL, new
generated HDL, and new generated rule/storage/assertion/runtime behavior
remain deferred. `.446` selects `.447`, the next post-mapping selector.
`.447` now selects `.448`, readiness audit for the public dynamic same-ID
`issue-order-queue` policy contract after the bounded `dynamic-id-reuse
reject` mappings shipped. The selector changes no behavior and does not
accept new source values yet. It chooses issue-order queue contract readiness
before scoreboard because concrete same-ID queue-head work already provides
the closest bounded precedent, while dynamic scoreboard behavior has a
different completion-tracking promise and remains a separate later owner.
`.448` must decide whether `dynamic-id-reuse issue-order-queue` becomes
metadata-first selected-not-generated policy, remains unsupported until a
generated queue behavior slice exists, or needs another prerequisite before
parser/report changes.
`.448` now selects `.449`, public dynamic same-ID `issue-order-queue`
policy contract selection. The audit changes no behavior and keeps
`dynamic-id-reuse issue-order-queue` and `dynamic-id-reuse scoreboard`
unsupported until later exact owners. It finds direct generated dynamic queue
behavior too large, direct parser/report implementation premature without a
contract, and scoreboard policy separate from issue-order queue semantics.
`.449` must decide the source spelling, metadata-first report fields,
selected-not-generated boundary, residue movement, diagnostics,
support-accounting impact, validation gates, and non-goals before any parser
or generated behavior change.
`.449` now selects `.450`, metadata-first parser/report implementation for
dynamic same-ID `issue-order-queue` policy. The selected public spelling is
family-local `(dynamic-id-reuse issue-order-queue)` under `same-id-ordering`
read/write arms. `.450` must accept and report the selected metadata with
`implementation_status: selected_not_generated`, `enforcement:
not_generated`, `accepted_same_id_reuse: false`, `generated_queue_behavior:
false`, and residue for `dynamic_per_id_issue_order_queues`, while preserving
dynamic `scoreboard` as unsupported and avoiding generated dynamic queue,
HDL, direct backend, or accepted-reuse behavior.
`.450` now ships that metadata-first parser/report support. Public PPIF
source may use `(dynamic-id-reuse issue-order-queue)` for read or write
same-ID ordering families. The new support-accounted sample
`ppif/axi_manager_capacity_status_dynamic_same_id_issue_order_queue_policy.ppif`
lowers to the same generated IAL1/IAL0 artifacts as the base dynamic
transaction-ID metadata sample, while its report records
`dynamic_id_reuse_policy.<family>.policy: issue_order_queue`,
`implementation_status: selected_not_generated`,
`request_conflict_policy: dynamic_issue_order_queue_selected_not_generated`,
`accepted_same_id_reuse: false`, `generated_queue_behavior: false`,
`generated_scoreboard_behavior: false`, and residue
`dynamic_per_id_issue_order_queues`. Dynamic `scoreboard`, generated dynamic
queues, accepted dynamic same-ID reuse, HDL, VHDL, direct backend behavior,
and backend-language variants remain deferred. `.450` selects `.451`, the
post-metadata selector for the next dynamic same-ID policy slice.
`.451` now selects `.452`, readiness audit for generated dynamic same-ID
`issue-order-queue` behavior. The selector changes no behavior. It chooses
queue readiness before scoreboard because `.450` made
`dynamic_per_id_issue_order_queues` explicit and user-visible, while dynamic
scoreboard remains a separate unsupported policy with different
completion-tracking semantics. `.452` must decide whether generated dynamic
queue behavior can move to contract selection, needs a narrower prerequisite,
or remains deferred.
`.452` now selects `.453`, public contract selection for generated dynamic
same-ID `issue-order-queue` behavior. The audit changes no behavior. It finds
the dynamic response-demux substrate mature enough for a contract pass, but
direct generated queue behavior still needs the public family/scope,
runtime-ID queue key, entry state, admitted enqueue, dequeue, response
matching, ordering guarantees, overflow/ambiguity assertions, report fields,
and residue movement selected first.
`.453` now selects `.454`, runtime-ID queue-state representation selection
for the first generated dynamic same-ID `issue-order-queue` behavior. The
selector changes no behavior. It chooses the all-dynamic write `BID` path as
the first generated family, but direct behavior still waits for an explicit
representation contract because accepting dynamic same-ID reuse must replace
reject-only active-ID uniqueness proofs with runtime-ID queue state,
enqueue/dequeue semantics, response matching, same-cycle policy,
overflow/ambiguity assertions, report fields, and residue movement.
`.454` now selects `.455`, implementation of the bounded two-transaction
all-dynamic write `BID` dynamic issue-order queue behavior. The selector
changes no behavior. It chooses `compact_runtime_id_issue_order_slots`: each
queue slot stores one-hot transaction identity plus a slot-local captured
runtime ID, and `BID` response demux selects the earliest valid slot whose
captured ID matches the response. Same-ID overlaps are ordered by slot age,
different-ID slot1 responses may complete ahead of slot0, same-cycle selected
dequeue plus one enqueue is supported, and reject-only active-ID uniqueness
assertions remain exclusive to `dynamic-id-reuse reject`.
`.455` now ships that generated bounded behavior through support-accounted
public sample
`ppif/axi_manager_capacity_status_dynamic_write_same_id_issue_order_queue.ppif`.
The generated write response-demux uses
`bounded_dynamic_write_bid_issue_order_queue_demux_contract`,
`generated_dynamic_issue_order_queue_demux`,
`earliest_matching_captured_runtime_id`, and
`dynamic_issue_order_earliest_matching_slot`. The same-ID ordering report uses
`generated_dynamic_write_bid_issue_order_queue`, accepts dynamic same-ID reuse
for the covered write family, clears covered same-ID ordering residue, and
exposes slot-local `AWID` capture, same-cycle selected dequeue plus enqueue,
and queue-specific assertions. Dynamic read queues, broader write
cardinalities, mixed dynamic/static queues, dynamic scoreboards, direct backend
behavior, backend-language variants, and VHDL remain future exact owners.
`.455` selects `.456`, the post dynamic write same-ID issue-order queue
selector.
`.456` now selects `.457`, readiness audit for generated dynamic read
same-ID `issue-order-queue` behavior. The selector changes no behavior. It
chooses read queue readiness before broader write cardinality, mixed
dynamic/static queues, scoreboards, validation retry, direct backend,
backend-language variants, or VHDL because existing generated dynamic read
behavior already has single-beat `RID`, burst-last `RID && RLAST`, read-data,
raw `ARLEN`/runtime validation, multi-beat output-bank, and recapture
consumers that a queue implementation must preserve.
`.457` now selects `.458`, public contract selection for the first generated
dynamic read same-ID `issue-order-queue` behavior. The readiness audit changes
no behavior. It chooses all-dynamic read single-beat `RID` before direct
behavior or burst-last `RID && RLAST` because the single-beat shape can reuse
the runtime-ID queue model without final-beat-only dequeue, raw non-final
beats, `RLAST`, read-data, raw `ARLEN`, runtime validation, multi-beat, or
recapture consumer coupling.
`.459` now ships the bounded two-transaction all-dynamic read single-beat
`RID` dynamic same-ID `issue-order-queue` behavior through support-accounted
public sample
`ppif/axi_manager_capacity_status_dynamic_read_same_id_issue_order_queue.ppif`.
Generated `response-demux.read` now reports
`bounded_dynamic_read_rid_issue_order_queue_demux_contract`,
`generated_dynamic_issue_order_queue_demux`,
`earliest_matching_captured_runtime_id`,
`compact_runtime_id_issue_order_slots`, and
`dynamic_issue_order_earliest_matching_slot` for exactly two all-dynamic read
transactions with `response-scope single-beat`. Generated same-ID ordering
reports `generated_dynamic_read_rid_issue_order_queue`,
`first_generated_scope: read_rid_two_dynamic_transactions`,
`accepted_same_id_reuse: true`, queue-specific assertions, slot-local `ARID`
capture, same-cycle selected dequeue plus enqueue, earliest matching `RID`,
and no same-ID ordering residue for the covered read family. Read burst-last,
read-data over queues, raw `ARLEN`/runtime, multi-beat, broader queue
cardinality, mixed dynamic/static queues, scoreboards, direct backend
behavior, backend-language variants, and VHDL remain future exact owners.
`.459` selects `.460`, the post dynamic read single-beat same-ID
issue-order queue selector.
`.460` now selects `.461`, readiness audit for generated dynamic read
burst-last `RID && RLAST` same-ID `issue-order-queue` behavior. The selector
changes no behavior. It chooses burst-last queue readiness because the shipped
dynamic read queue path covers only `response-scope single-beat`, while the
burst-last sibling must settle final-beat-only dequeue, raw non-final beat
policy, `RLAST`/`response-scope`/`last-signal` requirements, selected-match
assertions, downstream read-data/burst/runtime/multi-beat/recapture
preservation, report/residue/support/sample/validation, rollback, and
explicit residue before any behavior change. Read-data over queues, raw
`ARLEN`/runtime over queues, multi-beat output banks over queues, broader
queue cardinality, mixed dynamic/static queues, scoreboards, validation retry,
direct backend behavior, backend-language variants, and VHDL remain future
exact owners.
`.461` now selects `.462`, public contract selection for generated dynamic
read burst-last `RID && RLAST` same-ID `issue-order-queue` behavior. The
readiness audit changes no behavior. It found no lower parser, report-schema,
IAL1, IAL0, or SystemVerilog prerequisite because burst-last response-demux
metadata, one-bit `RLAST` input lowering, compact runtime-ID queue slots,
final dynamic `RID && RLAST` completions, raw non-final dynamic beat
assertions, and concrete burst-last queue-head non-last no-dequeue semantics
already exist. Direct behavior still needs public contract selection for
final-beat-only selected dequeue, raw non-final beat preservation, `RLAST`
requirements, selected completion and report vocabulary, queue assertions,
residue/support/sample/validation, and downstream read-data/burst/runtime/
multi-beat/recapture preservation.
`.462` now selects `.463`, direct implementation of the first generated
dynamic read burst-last `RID && RLAST` same-ID `issue-order-queue` behavior.
The contract-selection slice changes no behavior. It selects exactly two
all-dynamic reads, explicit `response-demux.read` with `response-scope
burst-last` and one-bit `last-signal`, compact runtime-ID issue-order slots,
raw `RID` beat matching without `RLAST`, selected final dequeue and generated
completion only on the earliest matching captured runtime ID plus `RLAST`,
mode `bounded_dynamic_read_rid_rlast_issue_order_queue_demux_contract`,
completion source `generated_dynamic_issue_order_queue_demux_last_beat`,
implementation status `generated_dynamic_read_rid_rlast_issue_order_queue`,
and first scope `read_rid_rlast_two_dynamic_transactions`. Read-data over
generated dynamic read queues, raw `ARLEN`, runtime validation, multi-beat
output banks, queue recapture widening, broader queue cardinality, mixed
dynamic/static queues, scoreboards, direct backend behavior,
backend-language variants, and VHDL remain future exact owners.
`.463` now ships generated bounded two-transaction all-dynamic read
burst-last `RID && RLAST` dynamic same-ID `issue-order-queue` behavior. The
public sample
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue.ppif`
uses exactly two dynamic reads, `same-id-ordering.read
(dynamic-id-reuse issue-order-queue)`, explicit generated
`response-demux.read`, `response-scope burst-last`, and one-bit
`last-signal axi0_rlast`. FSMGen generates compact runtime-ID queue slots with
slot-local `ARID`, raw earliest matching `RID` response ownership, final
completion/dequeue only on earliest matching captured runtime ID plus `RLAST`,
same-cycle selected final dequeue plus one enqueue, and queue assertions
including non-final no-dequeue. Reports use
`bounded_dynamic_read_rid_rlast_issue_order_queue_demux_contract`,
`generated_dynamic_issue_order_queue_demux_last_beat`,
`generated_dynamic_read_rid_rlast_issue_order_queue`, and
`first_generated_scope: read_rid_rlast_two_dynamic_transactions`. Read-data
over generated dynamic read queues, raw `ARLEN`, runtime validation,
multi-beat output banks, broader queue cardinality, mixed dynamic/static
queues, scoreboards, direct backend behavior, backend-language variants, and
VHDL remain future exact owners.
`.464` now selects `.465`, readiness audit for read-data routing over
generated dynamic read same-ID `issue-order-queue` response-demux pulses. The
selector changes no behavior. Read-data is next because generated dynamic read
same-ID queues now ship both single-beat `RID` and burst-last `RID && RLAST`
completion sources, while read-data over generated dynamic read queues remains
explicitly unowned. The audit must decide whether the first behavior owner is
scalar single-beat over generated dynamic read single-beat queues, scalar
last-beat over generated dynamic read burst-last queues, a paired bounded
scalar contract, a report/static cleanup prerequisite, a lower-layer
prerequisite, or deferral. Raw `ARLEN`, runtime validation, multi-beat output
banks, queue recapture widening, broader queue cardinality, mixed
dynamic/static queues, scoreboards, direct backend behavior, backend-language
variants, and VHDL remain future exact owners.
`.465` now selects `.466`, public contract selection for paired bounded
scalar read-data routing over generated dynamic read same-ID
`issue-order-queue` completions. The readiness audit changes no behavior. It
selects a paired contract because generated dynamic read same-ID queues now
ship both single-beat `generated_dynamic_issue_order_queue_demux` and
burst-last `generated_dynamic_issue_order_queue_demux_last_beat` completion
sources, and the ordinary generated dynamic read-data path already supports
the matching scalar single-beat and scalar last-beat public syntax. `.466`
must pin the public source shape, sample identities, report keys, diagnostics,
residue, validation, rollback, and queue-specific read-data completion
validity names
`generated_dynamic_read_issue_order_queue_response_demux_completion_pulse` and
`generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse`
before behavior changes. Raw `ARLEN`, runtime validation, multi-beat output
banks, queue recapture widening, broader queue cardinality, mixed
dynamic/static queues, scoreboards, direct backend behavior, backend-language
variants, and VHDL remain future exact owners.
`.466` now selects `.467`, direct implementation of paired bounded scalar
read-data routing over generated dynamic read same-ID `issue-order-queue`
completions. The contract-selection slice changes no behavior. It reuses
existing `read-data.read` syntax and selects two public samples:
`ppif/axi_manager_capacity_status_dynamic_read_same_id_issue_order_queue_read_data.ppif`
and
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data.ppif`.
The implementation must cover exactly two all-dynamic read transactions with
complete scalar transaction bindings, keep the underlying queue response-demux
modes and sources, report
`generated_dynamic_read_issue_order_queue_response_demux_completion_pulse` for
single-beat capture and
`generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse`
for last-beat capture, and leave raw `ARLEN`, runtime validation, multi-beat
output banks, queue recapture widening, broader queue cardinality, mixed
dynamic/static queues, scoreboards, direct backend behavior, backend-language
variants, and VHDL as future exact owners.
`.467` now ships paired scalar read-data routing over generated dynamic read
same-ID `issue-order-queue` completions. It adds the public samples
`ppif/axi_manager_capacity_status_dynamic_read_same_id_issue_order_queue_read_data.ppif`
and
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data.ppif`,
strict support-accounting entries, read-data coverage for
`generated_dynamic_issue_order_queue_demux` and
`generated_dynamic_issue_order_queue_demux_last_beat`, queue-specific
completion-validity names
`generated_dynamic_read_issue_order_queue_response_demux_completion_pulse` and
`generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse`,
and scalar `RDATA`/`RRESP` capture for `r0` and `r1`. The response-demux
remains queue-owned for the no-`burst-length` samples. Report-only raw
`ARLEN` capture is now covered by the `.469` sibling described below.

`.468` selected `.469`, direct bounded implementation of report-only
raw-`ARLEN` burst-length capture over generated dynamic read same-ID
`issue-order-queue` last-beat read-data. `.469` now ships that behavior
through the support-accounted public sample
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_burst_length.ppif`.
The generator admits only the exact two-transaction all-dynamic burst-last
queue report-only shape, emits generated `axi0_arlen`, per-transaction
raw-`ARLEN` storage, request-capture rules, and reports
`generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse`
with `burst_length_validation: report_only`. `.471` now ships runtime
beat-count/`RLAST` validation over that generated dynamic read same-ID
`issue-order-queue` last-beat raw-`ARLEN` shape through
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_burst_length_runtime_assertion.ppif`.
The generator emits expected-beat storage, beat-count storage, request-time
`ARLEN[4:0] + 5'd1` initialization, matched queue read-beat increments, and
four beat-count/`RLAST` assertions per transaction while preserving `.469`.
`.472` selected `.473`, direct bounded implementation of multi-beat output
banks over that generated dynamic read same-ID `issue-order-queue`
runtime-validation read-data. `.473` now ships the support-accounted public
sample
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_multi_beat.ppif`.
The generator admits only the exact two-transaction all-dynamic burst-last
queue runtime multi-beat shape and emits per-transaction output-bank clearing,
32 `RDATA` lanes, 32 `RRESP` lanes, valid masks, length outputs, scalar
worst-observed `RRESP` aggregate outputs/rules, raw `ARLEN`,
expected-beat/read-beat counter artifacts, and beat-count/`RLAST` assertions.
The selected queue read-data report uses
`bounded_multi_beat_read_data_contract`,
`generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse`,
`response_demux_matched_read_beat`, and empty read-data residue. `.474` now
selects `.475`, public report/static contract selection for generated dynamic
same-ID `issue-order-queue` same-cycle selected-dequeue-plus-enqueue
recapture. The audit changes no behavior. It found no new queue
state-machine prerequisite for emitted state-changing queue transitions, but
`.475` now selects `.476`, readiness audit for identity-preserving
same-transaction queue recapture ID refresh, before any positive queue
recapture report field is added. Current queue reports keep
`generated_update_rules` as literal emitted-rule lists under
`same_id_ordering.dynamic_id_reuse_policy.*.generated_queues[]`; classic
`same_cycle_release_recapture_policy` and `release_recapture_*` fields remain
exclusive to dynamic response-demux capture state. Broader queue cardinality,
mixed dynamic/static queues, scoreboards, direct backend behavior,
backend-language variants, and VHDL remain future exact owners. `.477` now
ships state-key-preserving dynamic queue recapture ID refresh. Generated
dynamic same-ID queue update rules include same-transaction refresh forms such
as `r0_dequeue_enqueue_r0`, `r1_r0_dequeue_enqueue_r0`,
`w0_dequeue_enqueue_w0`, and `w1_w0_dequeue_enqueue_w0`; those rules refresh
the affected slot ID from current `ARID`/`AWID` while preserving retained slot
IDs. `.479` now reports that support explicitly under each generated dynamic
queue entry with `same_transaction_recapture_policy:
refresh_captured_request_id`, `same_transaction_recapture_rule_scope:
state_key_preserving_selected_dequeue_enqueue`, and
`same_transaction_recapture_id_source` set to the queue request-ID source
(`axi0_awid` for write BID queues and `axi0_arid` for read RID/RID-and-RLAST
queues). The literal `generated_update_rules` list remains the emitted-rule
evidence, and classic `release_recapture_*` fields remain exclusive to
response-demux capture state. `.480` now selects `.481`, readiness audit for
the smallest broader dynamic queue cardinality step: one generated all-dynamic
write BID same-ID `issue-order-queue` widened from two transactions to a
bounded depth-3, three-transaction queue. Mixed dynamic/static queues,
scoreboards, read-side depth-3 queues, direct backend behavior,
backend-language variants, and VHDL remain future exact owners.
`.481` now selects `.482`, direct bounded implementation of that depth-3
all-dynamic write queue. The readiness audit found the behavior blocker is the
local dynamic queue admission/storage gate, which still requires depth 2 and
exactly two transactions. Transition, assignment, state-expression,
selected-match, assertion, and report helpers are already queue-depth and
transaction-list driven. `.482` now ships the generated depth-3 write shape
through support-accounted public sample
`ppif/axi_manager_capacity_status_dynamic_write_depth3_same_id_issue_order_queue.ppif`.
The generated queue has three compact runtime-ID slots, covers `w0`/`w1`/`w2`,
reports `first_generated_scope: write_bid_three_dynamic_transactions`, and
keeps same-transaction captured-`AWID` refresh fields under the generated
queue report. Ambiguous depth-3 cross-transaction dequeue/enqueue rule names
include the selected dequeued transaction, while existing depth-2 and
same-transaction refresh rule names stay stable. Read depth-3 queues,
read-data, mixed dynamic/static queues, scoreboards, arbitrary cardinality,
direct backend behavior, backend-language variants, and VHDL remain future
owners. `.483` now selects `.484`, readiness audit for generated
all-dynamic read single-beat `RID` same-ID `issue-order-queue` cardinality
widening from two transactions to one bounded depth-3, three-transaction
queue. Read single-beat is the smallest read-side depth-3 audit after the
write proof because it adds generated `RID` completion without `RLAST`,
read-data, raw `ARLEN`, runtime validation, output banks, mixed static-ID
exclusion, or scoreboard semantics. A RAM-guarded temporary read-depth3
schedule probe stopped at host-memory cutoff before producing data; no
unguarded retry or cutoff raise was used. Backend-language variants and
external converters such as `sv2v` remain outside this IAL2 slice;
FSMGen-owned generation/lowering remains the default under the backend
portability frontier. `.484` now selects `.485`, direct bounded
implementation of one generated all-dynamic read single-beat `RID` same-ID
`issue-order-queue` with exactly three dynamic read transactions, generated
single-beat `RID` response-demux completion, `read-max-pending` at least 3,
and queue depth 3. The readiness audit found the current blocker is local:
the dynamic read planner still requires exactly two all-dynamic reads and
records depth 2, while the shared dynamic queue builder admits depth 3 only
for write. A lightweight helper probe produced 99 transition rules, 19
assertions, zero duplicate names, the disambiguated cross-transaction rule,
the tail-selected refresh rule, and the `r2` completion-selected-match
assertion. Read burst-last depth-3, read-data over depth-3 queues, mixed
dynamic/static queues, scoreboards, arbitrary cardinality, backend-language
variants, external converter dependencies, and VHDL remain deferred.
`.485` now ships that generated depth-3 all-dynamic read single-beat `RID`
same-ID `issue-order-queue` behavior through support-accounted public sample
`ppif/axi_manager_capacity_status_dynamic_read_depth3_same_id_issue_order_queue.ppif`.
Generated `response-demux.read` covers `r0`/`r1`/`r2`, reports
`bounded_dynamic_read_rid_issue_order_queue_demux_contract`,
`generated_dynamic_issue_order_queue_demux`,
`read_rid_three_dynamic_transactions`, queue depth 3, and queue-owned
same-transaction captured-`ARID` refresh fields. The generated queue allocates
three compact runtime-ID slots, emits slot2 onehot and `r2`
completion-selected-match assertions, and keeps depth-2 read queues plus the
depth-3 write queue behavior unchanged. Read burst-last depth-3, read-data
over depth-3 queues, mixed dynamic/static queues, scoreboards, arbitrary
cardinality, direct backend behavior, backend-language variants, external
converter dependencies, and VHDL remain deferred. `.486` is the next
post-behavior selector. `.486` now selects `.487`, readiness audit for
generated all-dynamic read burst-last `RID && RLAST` same-ID
`issue-order-queue` cardinality widening from the shipped two-transaction
dynamic read burst-last queue to one bounded depth-3, three-transaction queue.
It is the smallest next audit because `.485` proves the read depth-3 runtime-ID
queue shape and `.463` proves RLAST-gated dynamic read queue semantics.
Read-data over depth-3 queues, mixed dynamic/static queues, scoreboards,
arbitrary cardinality, direct backend behavior, backend-language variants,
external converter dependencies such as `sv2v`, and VHDL remain deferred;
FSMGen-owned generation/lowering remains the default. `.487` now selects
`.488`, direct bounded implementation of one generated all-dynamic read
burst-last `RID && RLAST` same-ID `issue-order-queue` with exactly three
dynamic read transactions, one-bit `last_signal`, `read-max-pending` at least
3, and queue depth 3. The readiness audit found only local planner, builder,
and RLAST scope-reporting gates. A direct helper probe produced 99 transition
rules, 20 assertions, zero duplicate names, the non-final no-dequeue
assertion, the slot2 onehot assertion, the `r2` completion-selected-match
assertion, the tail-selected recapture rule, and the disambiguated
cross-transaction enqueue rule. `.488` now ships that generated
three-transaction read burst-last `RID && RLAST` same-ID `issue-order-queue`
behavior through support-accounted public sample
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue.ppif`.
The response-demux report lists `r0`/`r1`/`r2`, generated response-demux
rules, generated completions,
`generated_dynamic_issue_order_queue_demux_last_beat`, and
`read_rid_rlast_three_dynamic_transactions`. The generated queue allocates
three compact runtime-ID slots, gates completion and dequeue on earliest
matching captured `RID` plus one-bit `axi0_rlast`, keeps matching non-final
beats from dequeuing, and reports the slot2 onehot and `r2`
completion-selected-match assertions. Existing depth-2 RLAST queues,
depth-3 single-beat read queues, and depth-3 write queues remain unchanged.
Read-data over depth-3 queues, mixed dynamic/static queues, scoreboards,
arbitrary cardinality, direct backend behavior, backend-language variants,
external converter dependencies such as `sv2v`, and VHDL remain deferred;
FSMGen-owned generation/lowering remains the default. `.489` is the next
post-behavior selector. `.489` now selects `.490`, readiness audit for scalar
last-beat read-data over the generated all-dynamic read burst-last
`RID && RLAST` depth-3 same-ID `issue-order-queue` behavior shipped in
`.488`. The selector is next because `.488` now provides the missing
three-transaction queue-owned last-beat completion source, `.467`/`.469`/
`.471`/`.473` prove the two-transaction dynamic issue-order queue read-data
ladder, and the concrete depth-3 queue-head chain shows depth-3 read-data
needs explicit audit ownership before implementation. Mixed dynamic/static
queues, scoreboards, arbitrary cardinality, direct backend behavior,
backend-language variants, external converter dependencies such as `sv2v`,
and VHDL remain deferred; FSMGen-owned generation/lowering remains the
default. `.491` now ships scalar last-beat read-data over that generated
depth-3 dynamic RLAST queue through support-accounted sample
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data.ppif`.
The generated capture covers `r0`, `r1`, and `r2`, binds each
`axi0_r*_read_data_capture` rule to the generated queue completion pulse,
captures `axi0_rdata`/`axi0_rresp` into `axi0_r*_last_rdata`/
`axi0_r*_last_rresp`, and reports
`generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse`
with `read_rid_rlast_three_dynamic_transactions`. Raw `ARLEN`, runtime
beat-count/`RLAST` validation, multi-beat output banks, mixed dynamic/static
queues, scoreboards, arbitrary cardinality, direct backend behavior,
backend-language variants, external converter dependencies such as `sv2v`,
and VHDL remain deferred; FSMGen-owned generation/lowering remains the
default. `.492` now selects `.493`, readiness audit for report-only raw
`ARLEN` burst-length capture over that depth-3 dynamic RLAST queue
read-data. This is the smallest adjacent owner because `.491` supplies the
exact three-transaction scalar last-beat queue read-data surface, while
`.469` already proves report-only raw `ARLEN` over the two-transaction
dynamic RLAST queue. Runtime validation, multi-beat output banks, mixed
dynamic/static queues, scoreboards, arbitrary cardinality, verification-code
generation, direct backend behavior, backend-language variants, external
converter dependencies such as `sv2v`, and VHDL remain deferred;
FSMGen-owned generation/lowering remains the default. `.493` now selects
`.494`, direct bounded implementation of report-only raw `ARLEN` over that
same depth-3 dynamic RLAST queue read-data shape. The audit found only a
local dynamic issue-order queue read-data coverage gate: depth-2 queue
raw-`ARLEN` and depth-3 no-burst read-data are already supported, while the
generated burst-length storage/rule/report helpers already enumerate all
covered transactions. The RAM-guarded in-memory candidate failed closed at
that local diagnostic. Runtime validation, multi-beat output banks, mixed
dynamic/static queues, scoreboards, arbitrary cardinality,
verification-code generation, direct backend behavior, backend-language
variants, external converter dependencies such as `sv2v`, and VHDL remain
deferred; FSMGen-owned generation/lowering remains the default. `.494` now
ships that report-only raw `ARLEN` behavior through support-accounted sample
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_burst_length.ppif`.
The generated `read-data.read` path keeps the queue-owned
`RID && RLAST` completion pulse, adds generated input `axi0_arlen`, stores raw
request-time length in `axi0_r0_arlen_q`, `axi0_r1_arlen_q`, and
`axi0_r2_arlen_q`, and emits `axi0_r*_burst_length_capture` rules for
`r0`/`r1`/`r2`. The report advertises
`burst_length_validation: report_only`,
`generated_burst_length_inputs: [axi0_arlen]`, and the three generated
storage/rule names. Runtime validation over this depth-3 queue, multi-beat
output banks over this depth-3 queue, mixed dynamic/static queues,
scoreboards, arbitrary cardinality, verification-code generation, direct
backend behavior, backend-language variants, external converter dependencies
such as `sv2v`, and VHDL remain deferred; FSMGen-owned generation/lowering
remains the default. `.495` now selects `.496`, readiness audit for runtime
beat-count/`RLAST` validation over that same depth-3 dynamic RLAST queue
raw-`ARLEN` read-data shape. This is the smallest adjacent owner because
`.494` supplies the exact three-transaction report-only raw-`ARLEN` queue
read-data surface, while `.471` already proves runtime beat-count/`RLAST`
validation over the two-transaction dynamic RLAST queue. Multi-beat output
banks, mixed dynamic/static queues, scoreboards, arbitrary cardinality,
verification-code generation, direct backend behavior, backend-language
variants, external converter dependencies such as `sv2v`, and VHDL remain
deferred; FSMGen-owned generation/lowering remains the default. `.496` now
selects `.497`, direct bounded implementation of runtime beat-count/`RLAST`
validation over that same depth-3 dynamic RLAST queue raw-`ARLEN` read-data
shape. The audit found only the local dynamic issue-order queue read-data
coverage gate: the unmodified runtime candidate failed closed at the existing
diagnostic, and a RAM-guarded out-of-tree one-line predicate overlay proved the
existing runtime helpers enumerate `r0`/`r1`/`r2` expected-beat storage,
read-beat counters, six rules, and twelve beat-count/`RLAST` assertion
names. Multi-beat output banks, mixed dynamic/static queues, scoreboards,
arbitrary cardinality, verification-code generation, direct backend
behavior, backend-language variants, external converter dependencies such as
`sv2v`, and VHDL remain deferred; FSMGen-owned generation/lowering remains
the default. `.497` now ships that selected runtime-validation behavior through
support-accounted sample
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_burst_length_runtime_assertion.ppif`.
The generated path keeps queue-owned `RID && RLAST` completion and scalar
last-beat read-data capture, adds per-transaction expected-beat storage and
read-beat counters for `r0`/`r1`/`r2`, emits six beat-count init/increment
rules, and emits twelve `ARLEN`/beat-count/`RLAST` runtime assertions. The
read-data report advertises `burst_length_validation: runtime_assertion`,
`beat_count_validation_generated_behavior: true`, three
`generated_expected_beat_count_storage` entries, three
`generated_beat_count_storage` entries, six `generated_beat_count_rules`, and
twelve `generated_beat_count_assertions`. The `.494` report-only sample
remains supported and keeps runtime beat-count state absent. Multi-beat output
banks over this depth-3 queue, mixed dynamic/static queues, scoreboards,
arbitrary cardinality, verification-code generation, direct backend behavior,
backend-language variants, external converter dependencies such as `sv2v`, and
VHDL remain deferred; FSMGen-owned generation/lowering remains the default.
`.498` now selects `.499`, readiness audit for multi-beat output banks over
that same depth-3 dynamic RLAST queue runtime-validation read-data shape. This
is the smallest adjacent owner because `.497` supplies the exact
three-transaction runtime-validation queue read-data surface, while `.473`
already proves multi-beat output banks over the two-transaction dynamic RLAST
queue. Mixed dynamic/static queues, scoreboards, arbitrary cardinality,
verification-code generation, direct backend behavior, backend-language
variants, external converter dependencies such as `sv2v`, and VHDL remain
deferred; FSMGen-owned generation/lowering remains the default.
`.500` now ships that selected multi-beat output-bank behavior through
support-accounted sample
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_multi_beat.ppif`.
The generated path keeps queue-owned `RID && RLAST` completion, raw-`ARLEN`
capture, expected-beat storage, read-beat counters, six beat-count rules, and
twelve beat-count/`RLAST` runtime assertions, and adds per-transaction
multi-beat `RDATA`/`RRESP` output banks for `r0`/`r1`/`r2`, valid masks,
length outputs, scalar worst-observed `RRESP` aggregate outputs, output-init
rules, 48 lane-capture rules, and aggregate update rules. The read-data report
advertises `bounded_multi_beat_read_data_contract`, `capture_scope:
multi_beat`, response-demux matched-read-beat capture, runtime-assertion
burst-length validation, three generated valid-mask outputs, three generated
length outputs, 48 data outputs, 48 status outputs, and 48 capture rules.
Existing two-transaction dynamic queue multi-beat behavior, the `.494`
report-only depth-3 raw-`ARLEN` sample, and the `.497` depth-3 scalar
runtime-validation sample remain supported. Mixed dynamic/static queues,
scoreboards, arbitrary cardinality, verification-code generation, direct
backend behavior, backend-language variants, external converter dependencies
such as `sv2v`, and VHDL remain deferred; FSMGen-owned generation/lowering
remains the default.
`.501` now selects `.502`, readiness audit for generated mixed
dynamic/static write `BID` same-ID `issue-order-queue` behavior with exactly
one dynamic write transaction and one concrete static write transaction. It
changes no behavior. This is the smallest mixed queue owner after `.500`
closed the all-dynamic depth-3 queue/read-data ladder: write `BID` avoids
read-only `RLAST`, read-data, raw `ARLEN`, runtime beat-count validation, and
multi-beat output-bank complications. Optional external converter audits such
as `sv2v`, scoreboards, arbitrary cardinality, same-cycle widening,
verification-code generation, direct backend behavior, backend-language
variants, and VHDL remain deferred; FSMGen-owned generation/lowering remains
the default.
`.502` now audits that boundary and selects `.503`, direct bounded
implementation for exactly one dynamic write transaction plus one concrete
static write transaction. Parser support already accepts
`dynamic-id-reuse issue-order-queue`; a RAM-guarded temporary mixed write
candidate failed closed only at the local all-dynamic write queue planner
diagnostic requiring two or three all-dynamic write transactions. The direct
implementation is therefore local to mixed queue planning, report projection,
queue rule/assertion coverage, sample/support accounting, and focused tests.
External converter dependencies such as `sv2v`, mixed read queues,
multi-static or two-dynamic-plus-static queues, scoreboards, arbitrary
cardinality, backend behavior, backend-language variants, verification-code
generation, and VHDL remain deferred.
`.503` now ships generated mixed dynamic/static write `BID` same-ID
`issue-order-queue` behavior through support-accounted public sample
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue.ppif`.
The generated response-demux uses
`bounded_mixed_dynamic_static_write_bid_issue_order_queue_demux_contract`,
`generated_mixed_dynamic_static_issue_order_queue_demux`,
`earliest_matching_captured_or_static_runtime_id`, compact runtime-ID slots,
and `mixed_dynamic_static_issue_order_earliest_matching_slot`. Dynamic
enqueues store `axi0_awid`; static enqueues store the sized concrete literal
such as `4'd3`; static/dynamic runtime-ID overlap is allowed and ordered by
queue position. The same-ID ordering report uses
`generated_mixed_dynamic_static_write_bid_issue_order_queue`,
`generated_mixed_dynamic_static_issue_order_queue`,
`accepted_same_id_reuse: true`, `generated_scoreboard_behavior: false`,
`active_id_uniqueness_policy: not_required_for_issue_order_queue`, and
`static_id_conflict_policy: ordered_overlap_allowed`. Mixed read queues,
multi-static/two-dynamic mixed queues, scoreboards, arbitrary cardinality,
backend behavior, backend-language variants, verification-code generation,
external converter dependencies such as `sv2v`, and VHDL remain deferred;
FSMGen-owned generation/lowering remains the default.
`.504` now selects `.505`, readiness audit for generated mixed dynamic/static
read single-beat `RID` same-ID `issue-order-queue` behavior. This is the
smallest adjacent FSMGen-owned queue continuation after `.503`: it reuses the
one-dynamic plus one-concrete-static queue model and the all-dynamic read
single-beat `RID` queue model while avoiding mixed read burst-last
`RID && RLAST`, read-data, raw `ARLEN`, runtime validation, multi-beat output
banks, broader mixed cardinality, scoreboards, direct backend behavior,
backend-language variants, verification-code generation, external converter
dependencies such as `sv2v`, and VHDL. No parser, generator, PPIF sample,
support-accounting catalog, generated artifact, report JSON, test,
HDL/runtime behavior, backend behavior, external converter dependency, or
VHDL behavior changed in `.504`.
`.505` now audits that boundary and selects `.506`, direct bounded
implementation for exactly one dynamic read transaction plus one concrete
static read transaction. Parser support already accepts read
`dynamic-id-reuse issue-order-queue`; a RAM-guarded temporary mixed read
candidate fails closed only at the local all-dynamic read queue planner
diagnostic requiring exactly two all-dynamic read transactions, or exactly
three all-dynamic read transactions with single-beat or burst-last scope. The
direct implementation is therefore local to mixed read queue planning, read
response-demux projection, mixed queue coverage gating, report projection,
queue rule/assertion coverage, sample/support accounting, and focused tests.
External converter dependencies such as `sv2v`, mixed read burst-last queues,
read-data, raw `ARLEN`, runtime validation, multi-beat output banks, broader
mixed cardinality, scoreboards, backend behavior, backend-language variants,
verification-code generation, and VHDL remain deferred.
`.506` now ships generated mixed dynamic/static read single-beat `RID`
same-ID `issue-order-queue` behavior through support-accounted public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_same_id_issue_order_queue.ppif`.
The top-level response-demux report remains the aggregate
`bounded_response_demux_contract`, while `response_demux.read.mode` reports
`bounded_mixed_dynamic_static_read_rid_issue_order_queue_demux_contract`.
The generated read demux uses
`generated_mixed_dynamic_static_issue_order_queue_demux`,
`earliest_matching_captured_or_static_runtime_id`, compact runtime-ID slots,
`captured_or_static_request_id`, and
`mixed_dynamic_static_issue_order_earliest_matching_slot`. Dynamic enqueues
store `axi0_arid`; static enqueues store the sized concrete literal such as
`4'd3`; static/dynamic runtime-ID overlap is allowed and ordered by queue
position. The same-ID ordering report uses
`generated_mixed_dynamic_static_read_rid_issue_order_queue`,
`generated_mixed_dynamic_static_issue_order_queue`,
`accepted_same_id_reuse: true`, `generated_scoreboard_behavior: false`,
`active_id_uniqueness_policy: not_required_for_issue_order_queue`, and
`static_id_conflict_policy: ordered_overlap_allowed`. Mixed read burst-last
queues, read-data over this queue, raw `ARLEN`, runtime validation,
multi-beat output banks, multi-static/two-dynamic mixed queues, scoreboards,
arbitrary cardinality, backend behavior, backend-language variants,
verification-code generation, external converter dependencies such as `sv2v`,
and VHDL remain deferred; FSMGen-owned generation/lowering remains the
default.
`.507` now selects `.508`, readiness audit for generated mixed
dynamic/static read burst-last `RID && RLAST` same-ID `issue-order-queue`
behavior. This selector changes no behavior. The next audit is the smallest
adjacent owner because `.506` proves the queue-owned one-dynamic plus
one-static mixed read `RID` model, `.463` proves all-dynamic read burst-last
queue completion/dequeue semantics, and `.280` proves mixed read final
`RID && RLAST` response-demux matching. Read-data over mixed read queues, raw
`ARLEN`, runtime validation, multi-beat output banks, broader mixed
cardinality, scoreboards, backend behavior, backend-language variants,
verification-code generation, external converter dependencies such as `sv2v`,
and VHDL remain deferred; FSMGen-owned generation/lowering remains the
default.
`.508` now audits that boundary and selects `.509`, direct bounded
implementation of generated mixed dynamic/static read burst-last
`RID && RLAST` same-ID `issue-order-queue` behavior for exactly one dynamic
read transaction and one concrete static read transaction. A RAM-guarded
temporary candidate derived from the `.506` mixed read queue sample by
switching to `response-scope burst-last` and adding one-bit `axi0_rlast`
fails closed at the local planner diagnostic that still permits mixed
dynamic/static read issue-order queues only for `response_scope single-beat`.
No parser, IAL1, IAL0, SystemVerilog, backend-language, external converter,
verification-output, or VHDL prerequisite is required first. The direct
implementation is local to mixed read burst-last queue admission, last-beat
response-demux report projection, mixed queue behavior gating, report
vocabulary, sample/support accounting, and focused tests. Read-data over the
mixed queue, raw `ARLEN`, runtime validation, multi-beat output banks,
broader mixed cardinality, scoreboards, backend behavior, backend-language
variants, verification-code generation, external converter dependencies such
as `sv2v`, and VHDL remain deferred.
`.509` now ships that bounded mixed dynamic/static read burst-last
`RID && RLAST` same-ID `issue-order-queue` behavior through support-accounted
sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue.ppif`.
The generated queue stores `axi0_arid` for dynamic enqueues and `4'd3` for
the public static enqueue, completes/dequeues only on the selected
captured-or-static `RID` match plus `axi0_rlast`, and reports
`bounded_mixed_dynamic_static_read_rid_rlast_issue_order_queue_demux_contract`
plus `generated_mixed_dynamic_static_issue_order_queue_demux_last_beat`.
Read-data, raw `ARLEN`, runtime validation, multi-beat output banks, broader
mixed cardinality, scoreboards, backend behavior, backend-language variants,
verification-code generation, external converter dependencies such as `sv2v`,
and VHDL remain deferred.
`.510` now selects `.511`, public `.ppif` downstream-contract,
capability-manifest, and mdBook surface synchronization before any further
mixed queue behavior. The selector found the behavior-specific
`.503`/`.506`/`.509` surfaces current, but the downstream handoff, public
interface contract, embedding chapter, and `language_surface.file_surfaces`
`.ppif` manifest boundary do not yet advertise the generated mixed
dynamic/static same-ID `issue-order-queue` chain for write `BID`, read
single-beat `RID`, and read burst-last `RID && RLAST`. `.511` owns that
public-surface repair without parser/generator/sample/support-accounting,
generated-artifact, schedule/check/semantic JSON, HDL/runtime, backend,
external-converter, verification-output, or VHDL behavior changes. Mixed
read-data over these queues, raw `ARLEN`, runtime validation, multi-beat output
banks, broader mixed cardinality, scoreboards, backend behavior,
backend-language variants, verification-code generation, external converter
dependencies such as `sv2v`, and VHDL remain deferred.

`.511` now ships that public-surface synchronization. The downstream
integration spec, public interface contract, embedding chapter, and
`language_surface.file_surfaces` `.ppif` manifest boundary now advertise
generated one-dynamic plus one-concrete-static mixed dynamic/static same-ID
`issue-order-queue` behavior for write `BID`, read single-beat `RID`, and read
burst-last `RID && RLAST`. The manifest test now locks that boundary. The
later `.514` slice adds paired scalar read-data over the generated mixed read
single-beat and burst-last queue completions; raw `ARLEN`, runtime validation,
and multi-beat output banks over generated mixed dynamic/static issue-order
queues remain deferred, as do broader mixed cardinality, scoreboards, backend
behavior, backend-language variants, verification-code generation, external
converter dependencies such as `sv2v`, and VHDL. `.512` is the next selector
after this public-surface sync.

`.512` now selects `.513`, readiness audit for scalar read-data routing over
generated mixed dynamic/static read same-ID `issue-order-queue` completion
pulses. The selector changes no behavior and follows the established
progression from generated completion pulses to scalar read-data before raw
`ARLEN`, runtime validation, multi-beat output banks, broader mixed
cardinality, scoreboards, backend behavior, backend-language variants,
verification-code generation, external converter dependencies such as `sv2v`,
or VHDL. `.513` must decide whether the next owner is paired scalar
single-beat plus scalar last-beat contract selection, direct bounded
implementation, a narrower read-data owner, a prerequisite cleanup, or
deferral before any behavior changes.

`.513` now selects `.514`, direct bounded implementation of paired scalar
read-data routing over generated mixed dynamic/static read same-ID
`issue-order-queue` completions. The audit found existing scalar
`read-data.read` syntax and report modes sufficient, with the remaining
blocker local to read-data transaction coverage for
`generated_mixed_dynamic_static_issue_order_queue_demux` and
`generated_mixed_dynamic_static_issue_order_queue_demux_last_beat`. Temporary
single-beat and burst-last candidates reached the current coverage fallback,
so no parser, PPIF syntax, IAL1, IAL0, SystemVerilog, backend, external
converter, or VHDL prerequisite is exposed. Raw `ARLEN`, runtime validation,
multi-beat output banks, broader mixed cardinality, scoreboards, backend
behavior, backend-language variants, verification-code generation, external
converter dependencies such as `sv2v`, and VHDL remain deferred.

`.514` now ships paired scalar read-data routing over the generated mixed
dynamic/static read same-ID `issue-order-queue` completions. The two
support-accounted samples add existing scalar single-beat and scalar last-beat
`read-data.read` clauses to the shipped mixed read queue samples. Coverage is
deliberately bounded to exactly one dynamic read transaction plus one concrete
static read transaction, one depth-2 generated mixed queue, no `burst_length`
metadata, complete scalar `RDATA`/`RRESP` bindings, and queue-specific
completion-validity names for the single-beat and last-beat queue demux
pulses. Raw `ARLEN`, runtime validation, multi-beat output banks, broader
mixed cardinality, scoreboards, backend behavior, backend-language variants,
verification-code generation, external converter dependencies such as `sv2v`,
and VHDL remain deferred. `.515` is the raw-`ARLEN` burst-length readiness
audit over the mixed burst-last queue read-data path.

`.515` now selects `.516`, direct bounded implementation of report-only
raw-`ARLEN` burst-length capture over generated mixed dynamic/static read
burst-last same-ID `issue-order-queue` scalar read-data. Existing
`burst-length` syntax, dynamic queue raw-`ARLEN` behavior, and ordinary mixed
response-demux raw-`ARLEN` behavior are sufficient; the temporary candidate
failed only at the local mixed queue coverage branch that still requires no
`burst_length` metadata. Runtime validation, multi-beat output banks, broader
mixed cardinality, scoreboards, backend behavior, backend-language variants,
verification-code generation, external converter dependencies such as `sv2v`,
and VHDL remain deferred.

`.516` now ships report-only raw-`ARLEN` burst-length capture over generated
mixed dynamic/static read burst-last same-ID `issue-order-queue` scalar
read-data. The new support-accounted sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_burst_length.ppif`.
Coverage remains bounded to exactly one dynamic read plus one concrete static
read, one depth-2 generated mixed queue, complete scalar last-beat
`RDATA`/`RRESP` bindings, existing report-only `burst-length` metadata, and
completion validity
`generated_mixed_dynamic_static_read_issue_order_queue_response_demux_last_beat_completion_pulse`.
Runtime validation is now covered by `.517`/`.518`; multi-beat output banks,
broader mixed cardinality, scoreboards, backend behavior, backend-language
variants, verification-code generation, external converter dependencies such as
`sv2v`, and VHDL remain deferred.

`.517` now selects `.518`, direct bounded implementation of runtime
beat-count/`RLAST` validation over generated mixed dynamic/static read
burst-last same-ID `issue-order-queue` scalar last-beat read-data with
raw-`ARLEN` capture. Existing `burst-length` syntax, dynamic issue-order queue
runtime behavior, ordinary mixed response-demux runtime behavior, and shared
runtime generation/report helpers are sufficient. The remaining blocker is
local to the mixed queue read-data coverage branch admitting `report_only` but
not `runtime_assertion`. Multi-beat output banks, broader mixed cardinality,
scoreboards, backend behavior, backend-language variants, verification-code
generation, external converter dependencies such as `sv2v`, and VHDL remain
deferred.

`.518` now ships runtime beat-count/`RLAST` validation over generated mixed
dynamic/static read burst-last same-ID `issue-order-queue` scalar last-beat
read-data with raw-`ARLEN` capture. The support-accounted sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_burst_length_runtime_assertion.ppif`.
Coverage remains bounded to exactly one dynamic read plus one concrete static
read, one depth-2 generated mixed queue, complete scalar last-beat
`RDATA`/`RRESP` bindings, runtime-assertion raw-`ARLEN` metadata,
per-transaction expected-beat/read-beat-count storage, eight beat-count/`RLAST`
assertions, and completion validity
`generated_mixed_dynamic_static_read_issue_order_queue_response_demux_last_beat_completion_pulse`.
Multi-beat output banks, broader mixed cardinality, scoreboards, backend
behavior, backend-language variants, verification-code generation, external
converter dependencies such as `sv2v`, and VHDL remain deferred. `.519` is the
multi-beat output-bank readiness audit over this mixed queue path.

`.519` now selects `.520`, direct bounded implementation of multi-beat output
banks over the `.518` mixed queue runtime-validation read-data path. The audit
found the remaining blocker local to the mixed dynamic/static issue-order queue
read-data coverage branch: it has scalar single-beat and scalar last-beat
boundaries, but no `capture-scope multi-beat` boundary requiring
runtime-assertion `burst-length` metadata. Shared parser syntax, normalization,
report metadata, output-bank rule generation, status aggregation, beat-count/
`RLAST` assertions, response-state lookup, and test helper vocabulary are
already present. The selected `.520` public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_multi_beat.ppif`.
Broader mixed cardinality, scoreboards, backend behavior,
backend-language variants, verification-code generation, external converter
dependencies such as `sv2v`, and VHDL remain deferred.

`.520` now ships multi-beat output banks over generated mixed dynamic/static
read burst-last same-ID `issue-order-queue` runtime-validation read-data. The
support-accounted sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_multi_beat.ppif`.
The shipped shape is exactly one dynamic read plus one concrete static read,
one depth-2 generated mixed queue, generated burst-last queue completion source
`generated_mixed_dynamic_static_issue_order_queue_demux_last_beat`,
`capture-scope multi-beat`, runtime-assertion raw-`ARLEN` burst-length
metadata, complete per-transaction data/status output banks, scalar
worst-observed `RRESP` aggregate outputs, valid-mask outputs, length outputs,
and completion validity
`generated_mixed_dynamic_static_read_issue_order_queue_response_demux_last_beat_completion_pulse`.
The read-data report residue is empty for this bounded queue-owned shape.
Broader mixed issue-order queue cardinality, scoreboards, backend behavior,
backend-language variants, verification-code generation, external converter
dependencies such as `sv2v`, and VHDL remain deferred. `.522` now selects
`.523`, readiness audit for one-dynamic plus two-concrete-static mixed
dynamic/static write `BID` same-ID issue-order queue behavior. `.523` now
selects `.524`, direct bounded implementation for that one-dynamic plus
two-concrete-static write queue shape. The audit found the current candidate
fails closed only at the local mixed write issue-order queue
planner/materializer boundary, while lower queue transition, assignment,
assertion, storage, and report helpers are already transaction-list driven.
No parser, IAL1, IAL0, SystemVerilog, backend, external converter, or VHDL
prerequisite is required before the bounded `.524` implementation. `.524` now
ships generated mixed dynamic/static write `BID` same-ID `issue-order-queue`
behavior for one dynamic write plus two pairwise-distinct concrete static
writes through support-accounted public sample
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue_multi_static.ppif`.
The generated queue remains FSMGen-owned, uses compact runtime-ID slots of
depth three, enqueues `axi0_awid`, `4'd3`, and `4'd5`, reports
`write_bid_one_dynamic_two_static_transactions`, and preserves the `.503`
one-static mixed queue plus all-dynamic write depth-2/depth-3 queues. Broader
read queue cardinality, read-data, raw `ARLEN`, runtime validation,
multi-beat output banks, scoreboards, arbitrary mixed cardinality,
group-local simultaneous enqueue widening, backend behavior,
verification-output generation, backend-language variants, external converter
dependencies such as `sv2v`, and VHDL remain deferred.
`.525` now selects `.526`, readiness audit for the IAL2 protocol/platform
generality guardrail before more profile-specific implementation. AXI is the
first shipped IAL2 profile/example, not the definition of IAL2. Common IAL2
constructs remain protocol/platform-generic and AXI-specific vocabulary stays
profile-local unless compatible reuse is proven across multiple profiles.
`.526` now selects `.527`, public-surface cleanup for that IAL2
protocol/platform generality guardrail. The audit found the architecture
records correct and the remaining risk in downstream/public capability
boundary wording: public `.ppif` surfaces should lead with AXI as the first
shipped IAL2 profile/example, not the IAL2 definition.
`.527` now synchronizes the public `.ppif` contract, downstream handoff, and
capability-manifest language-surface boundary with that guardrail and selects
`.528`, post-guardrail IAL2 next-slice selection. Public `.ppif` surfaces now
lead with AXI as the first shipped IAL2 profile/example, not the IAL2
definition; future protocol-specific suffixes are profile aliases over IAL2;
and common IAL2 constructs stay small until compatible reuse is proven across
profiles.
`.528` now selects `.529`, readiness audit for a protocol-neutral/non-AXI
Valid-Ready `.ppif` example boundary. The selector deliberately does not
return to another AXI behavior slice before auditing the existing
Valid-Ready family as the next small IAL2 generality exercise.
`.529` now selects `.530`, public contract selection for a
protocol-neutral/non-AXI Valid-Ready `.ppif` profile and source-vocabulary
boundary. The audit found that `.ppif` is the generic IAL2 container, but the
current Valid-Ready implementation path still requires a profile clause and
accepts only AXI protocol names plus AXI channel families. A non-AXI or
protocol-neutral Valid-Ready sample therefore needs public vocabulary
selection before parser, generator, sample, support-accounting, or report
changes.
`.530` now selects `.531`, direct bounded implementation of the first
protocol-neutral/non-AXI Valid-Ready `.ppif` sample. The selected contract
keeps `(profile valid-ready)` explicit and required, keeps no-profile input
unsupported, uses `ppif/valid_ready_handshake.ppif` with support identity
`intent.ppif_valid_ready_handshake`, treats `(channel data_link)` as an
authored logical channel identifier rather than an AXI family, selects
`producer-to-consumer` as the first neutral role, and introduces no `.axi` or
other suffix alias.
`.531` now ships that first protocol-neutral/non-AXI Valid-Ready `.ppif`
sample. `ppif/valid_ready_handshake.ppif` lowers through generated
`data_link_valid_ready_monitor.isf` and `data_link_valid_ready_monitor.fsm`,
reports `target_channel.protocol = "valid-ready"`,
`target_channel.family = "data_link"`, and
`target_channel.role = "producer-to-consumer"`, and is support-accounted as
`intent.ppif_valid_ready_handshake`. Existing AXI Valid-Ready, AXI AW/W
bundle, AXI manager capacity/status, unsupported suffix aliases, direct
backend, verification-output, backend-language variant, and VHDL boundaries
remain unchanged.
`.532` now selects `.533`, readiness audit for protocol-neutral/non-AXI
Valid-Ready `.ppif` bundles. This is the next smallest IAL2 generality owner
because `.531` deliberately kept `(profile valid-ready)` multi-channel bundles
fail-closed while the existing aggregate bundle path is shipped only through
the AXI AW/W profile sample. No behavior changes in `.532`.
`.533` now selects `.534`, public contract selection for a bounded
protocol-neutral/non-AXI Valid-Ready `.ppif` bundle. The audit found no
separate aggregate wrapper/top prerequisite, but direct implementation would
still force public choices into code: sample/support identity, both neutral
roles, source-anchor inheritance, generic aggregate residue, docs/manifest
wording, and RAM-guard-friendly validation. No behavior changes in `.533`.
`.534` now selects `.535`, direct bounded implementation of
`ppif/valid_ready_dual_channel_bundle.ppif`. The contract keeps explicit
`(profile valid-ready)`, selects support identity
`intent.ppif_valid_ready_dual_channel_bundle`, exercises both neutral roles,
preserves the aggregate `valid_ready_bundle.v1` schema, requires generic
neutral aggregate residue instead of AXI manager residue, and preserves the
AXI AW/W bundle boundary. No behavior changes in `.534`.
`.535` now ships that protocol-neutral/non-AXI Valid-Ready `.ppif` bundle.
`ppif/valid_ready_dual_channel_bundle.ppif` lowers through generated
`data_downstream_valid_ready_monitor.isf`,
`status_upstream_valid_ready_monitor.isf`, their generated `.fsm` monitors,
and the aggregate wrapper/top `valid_ready_dual_channel_bundle.fsm`.
Schedule/check/semantic JSON report support identity
`intent.ppif_valid_ready_dual_channel_bundle`, both neutral roles,
one inherited channel source, generic aggregate residue
`valid_ready_profile_bundle_behavior_outside_monitor`, and no AXI manager
residue. Existing AXI AW/W bundle behavior still reports its AXI-profile
`axi_manager_concurrency` residue.
`.536` now selects `.537`, readiness audit for future IAL2 profile-alias file
suffixes after the neutral one-channel and dual-channel Valid-Ready `.ppif`
examples shipped. The selector is not an `.axi` implementation selection; it
audits how future suffixes such as `.axi`, `.chi`, `.ace`, `.ahb`, `.apb`,
`.atb`, `.smbus`, or `.i2s` can remain aliases over the same IAL2 model
without changing `.ppif` behavior, support accounting, reports, source paths,
or mandatory `IAL2 -> IAL1 -> IAL0` lowering.
`.537` now selects `.538`, public unsupported-alias inventory synchronization
before any profile-alias suffix implementation. The audit found that `.axi`,
`.chi`, `.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`, and `.i2s` are valid future
profile-alias candidates over IAL2, but the shipped CLI still accepts only
`.fsm`, `.isf`, and `.ppif` as source suffixes, the PPIF adapter requires a
`.ppif` path, and the manifest unsupported-alias inventory must be aligned with
the public boundary prose before any suffix behavior changes.
`.538` synchronized that pre-`.540` public inventory: at that point the
capability manifest kept `.pif`, `.ppi`, `.axi`, `.chi`, `.ace`, `.ahb`,
`.apb`, `.atb`, `.smbus`, and `.i2s` unsupported in the first IAL2 public
file-surface slice. The shipped source suffixes were still `.fsm`, `.isf`, and
`.ppif`; no profile-alias suffix was accepted until `.540`. `.538` selected
`.539`, public contract selection for the first IAL2 profile-alias suffix.
`.539` now selects `.540`, direct bounded implementation of `.axi` as the first
IAL2 profile-alias suffix. The selected alias mirrors
`ppif/axi_aw_valid_ready.ppif` at `ppif/axi_aw_valid_ready.axi`, requires an
explicit AXI-family profile such as `(profile axi4)`, and remains an IAL2 alias
that lowers through generated `.isf` before generated `.fsm`. This is only the
first profile-alias example; it does not make IAL2 AXI-only.
`.540` now ships that `.axi` profile-alias behavior for the selected AXI AW
Valid-Ready sample. `ppif/axi_aw_valid_ready.axi` uses the same IAL2
`protocol-platform-intent` shape as `.ppif`, must declare an explicit
AXI-family profile (`axi`, `axi3`, `axi4`, or `axi5`), and lowers through the
reviewable `axi_aw_valid_ready_monitor.isf` and
`axi_aw_valid_ready_monitor.fsm` artifacts before HDL generation. Check JSON
and semantic JSON keep the authored `.axi` path and support-account the sample
as `intent.axi_profile_alias_aw_valid_ready` with source kind
`ial2_profile_alias`. `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`,
`.i2s`, `.pif`, and `.ppi` remain unsupported; `.ppif` remains the generic
IAL2 container and AXI remains only the first profile-alias example.
`.541` now selects `.542`, a post-`.axi` IAL2 generality readiness audit before
another behavior implementation. It also corrects Knowledge Map routing so
current `.axi` acceptance questions point to the shipped `.540` behavior card,
while older profile-alias readiness and inventory cards are historical
pre-implementation facts. The next owner must choose from neutral/profile-
generic evidence and must not treat AXI as all of IAL2.
`.542` now selects `.543`, public-surface historical wording sync for the
post-`.axi` profile-alias chronology. The audit found code, manifest,
support-accounting, and Knowledge Map routing current after `.540`/`.541`; the
remaining prerequisite is to make pre-`.540` mdBook wording around `.537` and
`.538` explicitly historical before selecting another behavior owner.
`.543` now completes that public wording sync: README, ROADMAP_V2, and mdBook
make the `.537`/`.538` profile-alias readiness and unsupported-inventory
wording explicitly historical pre-`.540` state, while current `.axi` behavior
and remaining unsupported aliases stay clear. AXI remains the first shipped
profile-alias example, not the definition or full scope of IAL2. No behavior
changed in `.543`.
`.544` now selects `.545`, a non-AXI profile-alias readiness audit after the
public chronology sync. The next owner is deliberately not another AXI
implementation: it must audit `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`,
`.smbus`, `.i2s`, `.pif`, and `.ppi` readiness or prerequisites without
accepting any new suffix or changing behavior.
`.545` now selects `.546`, a non-AXI profile-alias taxonomy and evidence
prerequisite. The audit found no non-AXI protocol suffix ready for contract
selection: `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`, and `.i2s` still
lack source-shape, profile-matching, report, support-accounting, and mdBook
evidence, while `.pif` and `.ppi` remain generic-container candidates rather
than protocol aliases.
`.546` now selects `.547`, a generic-container alias policy selection for
`.pif` and `.ppi`. The taxonomy records that `.ppif` is the shipped generic
IAL2 container, `.pif` and `.ppi` are generic-container spelling candidates,
and `.chi`, `.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`, and `.i2s` are
protocol-profile alias candidates that still lack contract evidence.
Protocol-neutral `(profile valid-ready)` under `.ppif` remains the current
non-AXI IAL2 evidence; it proves IAL2 is not AXI-only but does not define a
protocol suffix contract.
`.547` keeps `.pif` and `.ppi` explicitly unsupported historical
generic-container spellings and selects `.548`, an APB IAL2 source-shape
readiness audit. `.ppif` remains the only shipped generic IAL2 container.
The next APB owner must audit whether existing APB lower-layer fixtures are
enough for an APB `.ppif` source-shape contract, a lower-layer prerequisite, a
report/support-accounting prerequisite, or deferral; it must not accept `.apb`
or add APB `.ppif` behavior.
`.548` now selects `.549`, APB `.ppif` source-shape public contract
selection. The audit found enough lower-layer APB evidence in the ISF
requester, requester/completer FSMs, composition top, mdBook examples, and
support catalog to choose a public APB IAL2 source-shape contract. It does not
select implementation. At `.548` closeout, `.apb` remained unsupported, no APB
`.ppif` sample was added, and APB report/support-accounting identity remained a
contract-selection decision before behavior changes.
`.549` now selects `.550`, direct bounded implementation of the first APB
`.ppif` source shape. The selected contract uses `(profile apb)` and a single
`(apb-requester apb_requester ...)` object, future sample path
`ppif/apb_requester_transfer.ppif`, support identity
`intent.ppif_apb_requester_transfer`, generated review artifacts
`apb_requester.isf` and `apb_requester.fsm`, and report schema
`fsmgen.ial2.protocol_intent.apb_requester_transfer.v1`. `.apb` and all other
new suffixes remain unsupported.
`.550` now ships that APB `.ppif` requester-transfer first slice. The sample
`ppif/apb_requester_transfer.ppif` parses `(profile apb)` with one
`(apb-requester apb_requester ...)` object, emits report schema
`fsmgen.ial2.protocol_intent.apb_requester_transfer.v1`, generates review
artifacts `apb_requester.isf` and `apb_requester.fsm` through IAL1 before
IAL0, reaches HDL module `apb_requester`, and support-accounts
`intent.ppif_apb_requester_transfer`. `.apb` and all other new suffixes remain
unsupported; APB is a `.ppif` profile behavior, not an AXI extension.
`.551` now selects `.552`, an APB `.apb` profile-alias readiness audit. The
selector found that `.550` creates enough generic `.ppif` APB evidence to
audit `.apb` alias readiness, but direct `.apb` implementation still needs a
separate public file-surface contract for explicit profile matching,
source-path/report identity, support accounting, manifest wording,
diagnostics, and generated `.isf` review artifacts before generated `.fsm`.
`.552` now selects `.553`, APB `.apb` public profile-alias contract
selection. The audit found APB is ready for contract selection because the
shipped `.ppif` requester-transfer path already locks profile `apb`,
`apb-requester` vocabulary, generated `apb_requester.isf` and
`apb_requester.fsm` review artifacts, report schema, strict check JSON,
semantic JSON, and support accounting. At `.552` closeout, `.apb` remained
unsupported until a separate contract and implementation owner settled explicit
profile policy, authored `.apb` source identity, support-accounting
identity/source kind, manifest wording, diagnostics, and mandatory generated
`.isf` review preservation.
`.553` now selects `.554`, direct bounded implementation of the first APB
`.apb` profile-alias suffix. The selected contract mirrors
`ppif/apb_requester_transfer.ppif` at future path
`ppif/apb_requester_transfer.apb`, keeps explicit `(profile apb)` with no
suffix inference, lowers through generated `apb_requester.isf` before
`apb_requester.fsm`, support-accounts the alias as
`intent.apb_profile_alias_requester_transfer` with source kind
`ial2_profile_alias`, and reserves focused
`t/1470-ial2-apb-profile-alias.t` coverage. At `.553` closeout, `.apb`
remained unsupported until `.554` implemented the contract.
`.554` now ships that bounded APB `.apb` profile-alias requester-transfer
behavior. The sample `ppif/apb_requester_transfer.apb` uses explicit
`(profile apb)` with one `(apb-requester apb_requester ...)` object, lowers
through generated `apb_requester.isf` before `apb_requester.fsm`, preserves the
authored `.apb` source path in check JSON and semantic JSON, reaches HDL module
`apb_requester`, and support-accounts
`intent.apb_profile_alias_requester_transfer` with source kind
`ial2_profile_alias`. `.chi`, `.ace`, `.ahb`, `.atb`, `.smbus`, `.i2s`,
`.pif`, and `.ppi` remain unsupported aliases, and APB completer/interconnect
generation, sidebands, alternate widths, multi-peripheral decode,
back-to-back policy, direct backend lowering, verification-output generation,
backend-language variants, and VHDL remain deferred.
`.555` now selects `.556`, a no-behavior public-surface sync after APB `.apb`
profile-alias support shipped. The next owner must make current `.axi`
behavior/fact wording stop listing `.apb` as unsupported after `.554`, while
preserving historical pre-`.554` closeout wording and keeping `.chi`, `.ace`,
`.ahb`, `.atb`, `.smbus`, `.i2s`, `.pif`, and `.ppi` unsupported.
`.556` now completes that public-surface sync. Current profile-alias surfaces
list `.axi` and `.apb` as shipped bounded aliases, keep `.chi`, `.ace`,
`.ahb`, `.atb`, `.smbus`, `.i2s`, `.pif`, and `.ppi` unsupported, and
preserve pre-`.554` `.apb`-unsupported wording only as dated history. `.556`
selects `.557`, the next exact IAL2 owner selector after the sync.
`.557` now selects `.558`, a no-behavior readiness audit for APB
completer/interconnect generation. The selector reverified the supported APB
completer fixture, the APB requester-to-completer composition top, and the
current `.apb` requester-transfer schedule/check path, then chose the explicit
`apb_completer_and_interconnect_generation_deferred` residue for audit before
any APB expansion behavior.
`.558` now selects `.559`, APB completer/interconnect public contract
selection. The audit found the lower-layer APB completer and requester-to-
completer composition fixtures plus current APB IAL2 requester-transfer
residue are sufficient for a contract selector, but direct behavior still needs
owned decisions for source vocabulary, completer/interconnect split policy,
mandatory generated `.isf` before `.fsm` artifacts, aggregate top shape,
report/support-accounting identities, diagnostics, and `.ppif` versus `.apb`
exposure.
`.559` now selects `.560`, APB completer generated-IAL1 substrate audit. The
contract splits the combined APB completer/interconnect residue: first select
`.ppif` APB completer generation with future sample `ppif/apb_completer.ppif`,
object `(apb-completer apb_completer ...)`, generated `apb_completer.isf`
before `apb_completer.fsm`, report schema
`fsmgen.ial2.protocol_intent.apb_completer.v1`, and future support identity
`intent.ppif_apb_completer`; APB interconnect/composition and `.apb`
completer alias exposure remain deferred until later owners.
`.560` now selects `.561`, IAL1 expression entry-activation guard rendering
repair before APB completer behavior. The audit found runtime `wait_cycles`,
storage reset/update, no-public-done target transactions, address-dependent
read/write state, `PSLVERR`, and generated report/artifact structure are
viable. At `.560` closeout, direct APB `.ppif` completer implementation was
blocked because `(when EXPR (sample ...))` entry guards lowered to invalid
generated `.fsm` guard suffixes containing `ARRAY(...)`. The APB setup detector
requires `PSEL && !PENABLE`, so `.561` was selected to repair the IAL1 guard
serialization before any APB completer parser/generator/sample/support
behavior.
`.561` now ships that IAL1 guard serialization repair. First-clause
`(when EXPR (sample ...))` entry activation renders valid generated `.fsm`
expression guard text for sample enables and entry transitions, keeps the
structured expression AST for internal analysis, preserves scalar entry guard,
when-body, and runtime-wait behavior, and proves the APB-shaped
`PSEL && !PENABLE` setup detector without `ARRAY(...)`. APB completer
parser/generator/sample/support behavior remains deferred to `.562`.
`.562` now ships the first generated APB `.ppif` completer behavior. The
sample `ppif/apb_completer.ppif` uses explicit `(profile apb)` with one
`(apb-completer apb_completer ...)` object, lowers through generated
`apb_completer.isf` before generated `apb_completer.fsm`, emits report schema
`fsmgen.ial2.protocol_intent.apb_completer.v1`, and support-accounts
`intent.ppif_apb_completer`. The bounded subset covers setup detection
`PSEL && !PENABLE`, runtime `wait_cycles`, address-0 register read/write, and
unmapped-address `PSLVERR`. At `.562` closeout `.apb` remained requester-
transfer only; `.569` later exposes the same bounded completer through
`ppif/apb_completer.apb`. APB interconnect/composition, sidebands, alternate
widths, multi-register decode, back-to-back policy, direct backend lowering,
verification-output generation, backend-language variants, AXI behavior, and
VHDL remain deferred.
`.563` now selects `.564`, a no-behavior APB interconnect/composition
readiness audit after generated APB requester and completer `.ppif` endpoints
both exist. The selector reverified the completer `.ppif`, requester `.ppif`,
requester `.apb`, lower-layer completer, and lower-layer APB composition
surfaces, then chose the `apb_interconnect_generation_deferred` residue for
audit. APB completer `.apb` alias exposure, multi-register decode, sidebands,
alternate widths, back-to-back policy, direct backend lowering,
verification-output generation, backend-language variants, AXI behavior, and
VHDL remain deferred.
`.564` now selects `.565`, APB interconnect/composition public contract
selection. The readiness audit found contract selection is justified because
generated APB `.ppif` requester and completer endpoint paths both exist and
the strict-supported lower-layer `fsm/apb_tb.fsm` target already wires
`apb_requester` to `apb_completer` through the APB bus. Direct interconnect
implementation, APB completer `.apb` alias exposure, multi-register decode,
sidebands, alternate widths, back-to-back policy, direct backend lowering,
verification-output generation, backend-language variants, AXI behavior, and
VHDL remain deferred until a public composition contract is selected.
`.565` now selects `.566`, direct bounded APB `.ppif` composition
implementation. The selected first contract is `ppif/apb_composition.ppif`
with top-level intent `apb_composition`, exactly one embedded
`(apb-requester apb_requester ...)`, exactly one embedded `(apb-completer
apb_completer ...)`, and one explicit `(apb-composition apb_tb ...)` object
that references those endpoints. It generates `apb_requester.isf`,
`apb_requester.fsm`, `apb_completer.isf`, `apb_completer.fsm`, and
`apb_tb.fsm`, selects report schema
`fsmgen.ial2.protocol_intent.apb_composition.v1`, and support-accounts
`intent.ppif_apb_composition`. At `.565`/`.566` closeout, requester `busy`
exposure, `.apb` composition/completer aliases, multi-peripheral
interconnect/decode, multi-register decode, sidebands, alternate widths,
back-to-back policy, direct backend lowering, verification-output generation,
backend-language variants, AXI behavior, and VHDL remained deferred; `.569`
later ships the completer and fixed-composition `.apb` aliases.
`.566` now ships that APB `.ppif` composition behavior. The sample
`ppif/apb_composition.ppif` lowers one embedded APB requester and one embedded
APB completer through generated `apb_requester.isf`,
`apb_completer.isf`, `apb_requester.fsm`, `apb_completer.fsm`, and
`apb_tb.fsm`; selects `apb_tb.fsm` as the HDL entry; emits report schema
`fsmgen.ial2.protocol_intent.apb_composition.v1`; and support-accounts
`intent.ppif_apb_composition` with semantic source root kind `top`. The top
exposes `start`, request fields, `wait_cycles`, `done`, `last_error`, and
`last_read_data`, but not requester `busy`. `.566` selects `.567`, the next
no-behavior APB surface selector after shipped requester, completer, and fixed
composition `.ppif` paths.
`.567` now selects `.568`, APB `.apb` profile-alias public contract selection
for APB completer and fixed APB requester/completer composition sources. The
selector confirmed requester-transfer `.apb`, completer `.ppif`, and
composition `.ppif` still pass, while temporary completer/composition `.apb`
copies failed closed with the requester-transfer-only alias diagnostic at
`.567` closeout. No behavior changed in `.567`; exact `.apb` sample paths,
support identities, source-kind behavior, diagnostics, and validation scope
were selected in `.568` before `.569` implemented alias widening.
`.568` now selects `.569`, direct bounded implementation of APB `.apb`
profile-alias widening for shipped APB completer and fixed APB composition
sources. The selected future samples are `ppif/apb_completer.apb` and
`ppif/apb_composition.apb`, both retaining explicit `(profile apb)`,
generated `.isf`/`.fsm` review artifacts, authored `.apb` source identity in
check/semantic JSON, and source kind `ial2_profile_alias`. The selected
support identities are `intent.apb_profile_alias_completer` and
`intent.apb_profile_alias_composition`; the composition alias keeps `apb_tb`
as semantic top with children `apb_requester` and `apb_completer`. No behavior
changed in `.568`; `.569` owns the parser/sample/support/test/docs behavior
widening, while multi-peripheral interconnect/decode, requester busy/status,
multi-register decode, sidebands/strobes, alternate widths, back-to-back
policy, direct backend, verification-output, backend-language variants, AXI,
and VHDL remain deferred.
`.569` now ships that bounded APB `.apb` alias widening. The public aliases
`ppif/apb_completer.apb` and `ppif/apb_composition.apb` mirror the shipped
generic `.ppif` completer and fixed requester/completer composition sources,
preserve authored `.apb` source identity in check and semantic JSON, lower
through the same generated `.isf` and `.fsm` review artifacts, and
support-account as `intent.apb_profile_alias_completer` and
`intent.apb_profile_alias_composition` with source kind `ial2_profile_alias`.
The `.apb` suffix now accepts exactly requester-transfer, completer, and fixed
one-requester/one-completer composition APB shapes; missing profile,
non-APB profile, non-APB objects, and implicit mixed requester/completer
sources still fail closed. `.569` selects `.570`, the next no-behavior APB
surface selector after requester/completer/composition `.apb` alias coverage
shipped.
`.570` now selects `.571`, APB requester busy/status public contract
selection, without changing behavior. Current generated APB requester and
fixed composition IAL2 reports expose `done`, `last_error`, and
`last_read_data` while carrying `apb_requester_busy_status_deferred`;
lower-layer hand-authored `fsm/apb_requester.fsm` and `fsm/apb_tb.fsm`
already expose `busy`. The next owner must decide exact source syntax,
whether the first widening exposes only `busy` or also a named status field,
generated `.isf`/`.fsm` review artifacts, fixed composition top-port
propagation, support/report/residue/docs updates, diagnostics, validation, and
rollback before any parser or generator behavior changes.
`.571` now selects `.572`, direct bounded implementation of additive
busy-only APB requester status exposure. Existing APB requester-transfer and
fixed-composition samples remain unchanged; the selected new busy-capable
paths are `ppif/apb_requester_transfer_busy.ppif`,
`ppif/apb_requester_transfer_busy.apb`, `ppif/apb_composition_busy.ppif`, and
`ppif/apb_composition_busy.apb`. The selected syntax adds optional
`(busy busy)` inside the APB requester `(response ...)` block. Named status
fields remain deferred through `apb_requester_status_field_deferred`.
`.572` now ships the selected busy-only contract. Busy-capable requester
sources expose public `busy` in generated `apb_requester.isf`,
`apb_requester.fsm`, and HDL module `apb_requester`; busy-capable fixed
composition sources propagate `busy` to generated top `apb_tb`. The new
support identities are `intent.ppif_apb_requester_transfer_busy`,
`intent.apb_profile_alias_requester_transfer_busy`,
`intent.ppif_apb_composition_busy`, and
`intent.apb_profile_alias_composition_busy`. Existing no-busy APB samples keep
`apb_requester_busy_status_deferred`; busy-capable reports keep
`apb_requester_status_field_deferred` for future named status fields.
`.573` now selects `.574`, a no-behavior public-surface and `bin/fsmgen`
import-tree synchronization slice before any further behavior work. At `.573`
selection time, the live import probe reported `213` project files total and
`212` reachable `FSM::...` `.pm` packages, including the APB IAL2 requester,
completer, and composition owners, while the import-tree note/fact and mdBook
language-surface prose still needed sync.
`.574` now completes that public-surface sync. `docs/BIN_FSMGEN_IMPORT_TREE.md`
and the import-tree fact record the live `213` total / `212` reachable
`FSM::...` `.pm` package closure with APB IAL2 requester, completer, and fixed
composition owners reachable. The mdBook language-surface and
intent-scheduling chapters describe `.ppif` as the generic IAL2 container,
`.axi` and `.apb` as bounded shipped profile aliases, and keep `.pif`, `.ppi`,
`.chi`, `.ace`, `.ahb`, `.atb`, `.smbus`, and `.i2s` unsupported. `.575`
later selected the next exact IAL2 slice recorded below.
`.575` now selects `.576`, APB requester named status-field public contract
selection, without changing behavior. Busy-capable APB requester-transfer and
fixed-composition reports keep `apb_requester_status_field_deferred`, making
named status fields the next smallest direct APB follow-on. Multi-peripheral
decode, multi-register decode, sidebands/strobes, alternate widths,
back-to-back policy, direct backend, verification-output, backend-language
variants, AXI follow-on, and VHDL remain deferred.
`.576` now selects `.577`, direct bounded implementation of additive 2-bit APB
requester named status-field exposure, without changing behavior. The selected
source shape adds `(status status width 2)` only in busy-capable APB requester
response blocks that also contain `(busy busy)`. The selected code is
`0 idle`, `1 busy`, `2 done_ok`, and `3 done_error`. Status-capable requester
and fixed-composition `.ppif`/`.apb` samples will be additive; existing no-busy
and busy-only APB samples remain unchanged. Status-only samples, enum/custom
encodings, sticky status registers, APB decode/storage/sideband/width work,
back-to-back policy, direct backend, verification-output, backend-language
variants, AXI follow-on, and VHDL remain deferred.
`.577` now ships that additive busy-plus-status contract. The new
requester-transfer samples are `ppif/apb_requester_transfer_status.ppif` and
`ppif/apb_requester_transfer_status.apb`; the new fixed-composition samples
are `ppif/apb_composition_status.ppif` and
`ppif/apb_composition_status.apb`. The accepted response shape keeps
`(busy busy)` and adds `(status status width 2)`. Generated requester artifacts
expose public `busy` and `status[1:0]`, drive status `0 idle`, `1 busy`, and
publish `2 done_ok` / `3 done_error` with `(concat 1'b1 slverr)` after
sampling `PSLVERR`. Status-capable composition sources propagate `status<2`
to generated top `apb_tb`. The new support identities are
`intent.ppif_apb_requester_transfer_status`,
`intent.apb_profile_alias_requester_transfer_status`,
`intent.ppif_apb_composition_status`, and
`intent.apb_profile_alias_composition_status`. Status-capable reports remove
both `apb_requester_status_field_deferred` and
`apb_requester_busy_status_deferred`; existing no-busy and busy-only APB
samples keep their prior residue. Status-only samples, enum/custom encodings,
sticky status registers, APB decode/storage/sideband/width work, back-to-back
policy, direct backend, verification-output, backend-language variants, AXI
follow-on, and VHDL remain deferred.

`.578` now selects `.579`, APB multi-register decode readiness audit, without
changing behavior. The selector chose multi-register readiness because
status-capable APB requester-transfer and fixed-composition reports now remove
the requester busy/status residues, while APB completer/composition reports
still expose the single-register boundary through
`apb_multi_register_decode_deferred`. `.579` must decide whether the next owner
is public contract selection, lower-layer/storage prerequisite work,
parser/report/static-validation readiness, direct implementation, or explicit
deferral. Multi-peripheral APB topology, sidebands/strobes, alternate widths,
back-to-back policy, direct backend, verification-output, backend-language
variants, AXI follow-on, and VHDL remain deferred.

`.579` now audits APB multi-register decode readiness and selects `.580`,
public APB multi-register completer decode contract selection, without
changing behavior. The parser already scans repeated `(register ...)` clauses,
but the current source contract, normalized model, reports, generated ISF/FSM,
samples, lower-layer fixture, and focused tests are still singular. Direct
implementation is not ready until `.580` selects public source syntax,
deterministic ordering, address uniqueness/diagnostics, report migration,
generated storage naming, sample/support/test scope, and deferred boundaries.

`.580` now selects `.581`, direct bounded APB multi-register completer decode
implementation, without changing behavior. The selected public syntax is
repeated `(register ...)` clauses under `(storage ...)`, in source order. The
first implementation keeps unique decimal 32-bit 4-byte-aligned addresses,
32-bit register data, reset 0, existing register read/write policy, and
unmapped-address error behavior. Existing one-register reports remain
unchanged; multi-register reports add `bindings.storage.registers[]` and
`transfer.registers[]`. New standalone completer and status-capable
fixed-composition `.ppif`/`.apb` samples are selected for `.581`.

`.581` now ships additive APB multi-register completer decode through
`ppif/apb_completer_multi_register.ppif`,
`ppif/apb_completer_multi_register.apb`,
`ppif/apb_composition_multi_register.ppif`, and
`ppif/apb_composition_multi_register.apb`. Repeated register clauses decode
source-order 32-bit aligned addresses, update/read only the selected register,
and drive `PSLVERR` on unmapped addresses. Existing one-register APB samples
and singular report fields remain unchanged. Multi-register reports expose
`bindings.storage.registers[]` and `transfer.registers[]`, remove
`apb_multi_register_decode_deferred`, and keep multi-peripheral topology,
sidebands/strobes, alternate widths, back-to-back policy, direct backend,
verification-output, backend-language variants, AXI follow-on, and VHDL
deferred.

`.582` now selects `.583`, APB multi-peripheral interconnect/decode readiness
audit, without changing behavior. Live APB schedule probes after `.581`
confirmed that multi-register composition removes the register-local residue
but still carries `apb_interconnect_multi_peripheral_decode_deferred`, while
requester reports still carry `apb_multi_peripheral_decode_deferred`.
Multi-peripheral topology is selected before sidebands/strobes, alternate
widths, back-to-back policy, direct backend, verification-output,
backend-language variants, AXI follow-on, and VHDL because it owns the next
composition/report/source-shape boundary.
`.583` now selects `.584`, APB multi-peripheral interconnect/decode public
contract selection, without changing behavior. Current APB parser/generator/
report support remains fixed to one requester, one completer, and one
composition object. The missing public contract must select the peripheral
list, address map, decode priority, response mux, diagnostics, report schema,
sample/support/test scope, and validation boundary before behavior work. The
selected direction is APB-specific generated reusable IAL1 review lowering,
configured by IAL2 source-level parameter/generic-like topology/address-map
bindings. AXI and AHB remain separate protocol-specific future owners; their
interconnect/decode logic cannot share APB implementation logic.
`.584` now selects `.585`, direct bounded APB multi-peripheral
interconnect/decode implementation, without changing behavior. The selected
contract keeps `(apb-composition ...)` as the IAL2 owner, adds repeated
`(peripheral INSTANCE OBJECT)` APB completer children, `(address-map ...)`
windows with static 32-bit parameter/generic-like base/size defaults,
`(decode (overlap reject) (priority source-order) (unmapped-address error))`,
local peripheral address translation, selected response muxing, generated
`apb_interconnect.isf` before `apb_interconnect.fsm`, additive
`apb_composition.v1` report fields, and new
`ppif/apb_composition_multi_peripheral.ppif`/`.apb` samples. Existing fixed
APB composition behavior remains unchanged.
`.585` now ships bounded APB multi-peripheral interconnect/decode through
`ppif/apb_composition_multi_peripheral.ppif` and
`ppif/apb_composition_multi_peripheral.apb`. The parser accepts repeated
`(peripheral INSTANCE OBJECT)` APB completer children, static non-overlapping
`(address-map ...)` windows, and the selected reject/source-order/unmapped
error decode policy. Lowering emits `apb_interconnect.isf`,
`apb_interconnect.fsm`, requester/peripheral endpoint artifacts, and
`apb_tb.fsm`; the generated interconnect fans out decoded `PSEL`, translates
local `PADDR`, muxes selected responses, and returns `PSLVERR` for active
unmapped accesses. Reports expose topology/address-map/response-mux fields,
preserve authored peripheral names, and publish collision-free generated
instance names such as `status_peripheral`.
`.586` now selects `.587`, a no-behavior APB sidebands/strobes/byte-lane
readiness audit after the multi-peripheral interconnect/decode behavior. Live
APB schedule probes through the public `unsupported_residue` field show that
top-level multi-peripheral composition removed the top-level multi-peripheral
decode residue, while APB sideband/strobe, alternate-width, and back-to-back
residues remain explicit. The selected audit must settle whether `PPROT`,
`PSTRB`, byte-lane write semantics, composition/interconnect propagation,
diagnostics, report fields, samples, support-accounting, and validation should
proceed through a public contract, a lower-layer prerequisite, an
alternate-width prerequisite, or explicit deferral before any behavior change.
`.587` now selects `.588`, public APB sideband/strobe contract selection,
without changing behavior. The audit found that current APB bus blocks accept
only core APB signals and reject unselected `(strobe ...)` and `(protection
...)` clauses, while generated IAL1/IAL0 already has fixed-width ports,
bitwise operations, shifts, concatenation, and masked field-update support
needed for a later byte-lane implementation. `.588` must select the exact
`PPROT`/`PSTRB` source syntax, 32-bit first-slice policy, byte-enable write
semantics, propagation through fixed and multi-peripheral compositions,
reports, support-accounting, diagnostics, validation, and rollback.
`.588` now selects `.589`, direct bounded APB `PPROT`/`PSTRB`
sideband/strobe implementation, without changing behavior in `.588`. The
selected syntax adds requester-side `(protection req_prot width 3)` and
`(write-strobe req_wstrb width 4)` fields plus bus-side `(protection PPROT
width 3)` and `(strobe PSTRB width 4)` on requester, completer, and
composition bus/wiring blocks. The selected byte-lane policy is fixed 32-bit
APB: `PSTRB[0]` controls `PWDATA[7:0]`, `PSTRB[1]` controls `PWDATA[15:8]`,
`PSTRB[2]` controls `PWDATA[23:16]`, and `PSTRB[3]` controls `PWDATA[31:24]`.
`PPROT` is propagated and sampled while protection access-control effects
remain deferred.
`.589` now ships bounded APB `PPROT`/`PSTRB` sideband/strobe behavior through
sideband-aware requester, multi-register completer, fixed multi-register
composition, and multi-peripheral composition `.ppif` and `.apb` samples.
Requesters sample `req_prot`/`req_wstrb`, drive `PPROT`, drive `PSTRB` only
for writes, and clear both sidebands in the terminal phase. Completers sample
`PPROT/PSTRB` during APB setup and apply little-endian byte-lane register
writes while preserving unselected bytes. Fixed composition wires sidebands
directly, and multi-peripheral composition fans them out through
`apb_interconnect` while preserving decoded `PSEL`, local `PADDR`
translation, response muxing, and unmapped active-access `PSLVERR`.
Sideband-aware reports replace `apb_protection_and_strobes_deferred` with
`apb_protection_policy_effects_deferred`; alternate widths, PPROT
access-control effects, and back-to-back policy remain deferred.
`.590` now selects `.591`, APB public-surface/report-static cleanup, without
changing behavior in `.590`. Focused live report probes confirm sideband-aware
APB reports now carry `apb_protection_policy_effects_deferred`,
`apb_alternate_widths_deferred`, and `apb_back_to_back_policy_deferred`, with
topology residues only on narrower endpoint/fixed-composition shapes. The
generic `.ppif` language-surface manifest still has stale APB sideband
deferral wording after `.589`, so `.591` must align public/static prose before
APB alternate widths, PPROT access-control effects, back-to-back policy,
additional APB topology work, AXI/AHB return, direct backend,
verification-output, backend-language variants, or VHDL.
`.591` now synchronizes APB public-surface/report-static wording without
changing behavior. The generic `.ppif` language-surface manifest names the
shipped sideband-aware APB requester-transfer, multi-register completer, fixed
multi-register composition, and multi-peripheral composition `.ppif` coverage;
the `.apb` mirror paragraph includes the matching sideband-aware profile-alias
fixtures. The stale broad "APB sidebands" deferral is removed from the generic
`.ppif` public boundary, leaving APB alternate widths, PPROT access-control
effects, and back-to-back policy explicit. `.592` now owns APB alternate-width
readiness audit after the public surface is aligned.
`.592` now selects `.593`, public APB alternate-width contract selection,
without changing behavior. The audit found that parser syntax already
preserves APB width tokens, but validators and generated behavior still pin
the APB slice to 32-bit address/data/register/address-map widths, 4-bit wait
controls, 3-bit `PPROT`, and 4-bit `PSTRB`; requester `PSTRB` drive,
completer `strb_q`, byte-lane masks, and address-map width remain hard-coded
to the 32-bit/4-strobe shape. Existing generated IAL1/IAL0 width-bearing
ports, bitwise operations, concatenation, `when-bit`, and masked
read-modify-write expressions are enough for bounded static-width contract
selection, so `.593` must settle the public width matrix before behavior work.
`.593` now selects `.594`, direct bounded implementation of sideband-aware
16-bit APB data/strobe variants, without changing behavior. The selected
contract keeps address width and address-map parameter width at 32, completer
wait-count width at 4, `PPROT` at 3, and requester status at 2. New `data16`
requester, multi-register completer, fixed multi-register composition, and
multi-peripheral composition sample pairs will use 16-bit write/read/register
data and 2-bit `PSTRB`/write-strobe, with register and address-map window
alignment tied to the 2-byte data beat. Selected 16-bit reports replace
`apb_alternate_widths_deferred` with narrower remaining-width residue;
`PPROT` policy effects and back-to-back policy remain deferred.
`.594` now ships the selected sideband-aware APB `data16` behavior. The new
requester-transfer, multi-register completer, fixed multi-register
composition, and multi-peripheral composition `.ppif`/`.apb` sample pairs use
16-bit write/read/register data with 2-bit `PSTRB`/write-strobe, two byte
lanes, and 2-byte register/window alignment. Existing 32-bit APB behavior is
preserved. Data16 reports add `width_policy` metadata and use
`apb_remaining_widths_deferred`; remaining APB residues are `PPROT`
access-control effects, back-to-back policy, APB address widths other than 32,
wait-count widths other than 4, and data widths beyond the selected
sideband-aware 16/32-bit boundary. `.595` now owns APB `PPROT`
access-control effects readiness audit.
`.595` now selects `.596`, public APB `PPROT` access-control effects contract
selection, without changing behavior. The audit found that sideband-aware APB
requester, completer, fixed-composition, and multi-peripheral composition
paths already propagate or sample 3-bit `PPROT`, and sideband-aware reports
still carry `apb_protection_policy_effects_deferred`. Existing generated
IAL1/IAL0 expression and conditional-action support is sufficient for bounded
static policy checks, so `.596` must settle public policy vocabulary,
denied-read/write behavior, `PSTRB` interaction, composition/interconnect
effects, reports, support identities, diagnostics, validation, and rollback.
`.596` now selects `.597`, direct bounded implementation of the first APB
`PPROT` access-control effects contract, without changing behavior. The
selected syntax adds register-local `(access-policy ...)` clauses to
sideband-aware 32-bit APB completer storage registers, with read/write clauses
that either `allow` or `require (privileged 0|1)`. The first FSMGen-local
predicate maps `privileged` to sampled `PPROT[0]`. Denied mapped accesses
complete at the normal APB response point with `PREADY=1` and `PSLVERR=1`;
denied reads drive `PRDATA=0`, denied writes are side-effect-free including
`PSTRB=0`, and fixed/multi-peripheral composition propagates `PPROT` and muxes
responses while selected completers own enforcement. Selected reports will
replace `apb_protection_policy_effects_deferred` with
`apb_additional_protection_policies_deferred`. At that point, data16 policy
effects, additional `PPROT` predicates, global/window/peripheral policies,
interconnect-owned enforcement, back-to-back policy, direct backend,
verification-output, backend-language variants, AXI, AHB, and VHDL remain
deferred.
`.597` now ships the selected bounded APB `PPROT` access-policy behavior. The
new sideband-aware 32-bit completer, fixed-composition, and multi-peripheral
composition `.ppif`/`.apb` sample pairs accept register-local
`(access-policy ...)` clauses. Completers evaluate sampled `PPROT[0]` against
each selected register's `read`/`write` policy, preserve allowed byte-lane
writes and reads, return `PSLVERR=1` plus zero `PRDATA` for denied reads, and
return `PSLVERR=1` without storage updates for denied writes including
`PSTRB=0`. Fixed and multi-peripheral composition remain propagation/mux-only
for policy; selected completers own enforcement. Reports add
`protection_policy` metadata and use
`apb_additional_protection_policies_deferred`. At that point, data16 policy
effects, additional `PPROT` predicates, global/window/peripheral policies,
interconnect-owned enforcement, back-to-back policy, direct backend,
verification-output, backend-language variants, AXI, AHB, and VHDL remain
deferred. `.598` selected `.599`, APB profile-alias/public-surface
synchronization after `.597`, without behavior changes. Live probes confirmed
selected 32-bit protection aliases carry `protection_policy` metadata and
`apb_additional_protection_policies_deferred`, while sideband data16 aliases
retain `apb_protection_policy_effects_deferred` and no `protection_policy`.
`.599` synchronized `docs/IAL2_APB_PROFILE_ALIAS_BEHAVIOR.md` with the shipped
protection alias behavior, including protection support-accounting prose, CLI
examples, report wording, diagnostics, and narrowed non-goals, without behavior
changes. `.600` selected `.601`, APB sideband data16 `PPROT` policy effects
readiness audit, without behavior changes. `.601` audited that readiness and
selected `.602`, public contract selection for sideband data16 APB `PPROT`
policy effects, without behavior changes. A temporary data16 access-policy
candidate failed exactly at the current 32-bit `ApbCompleter` guard, and the
audit found no parser, IAL1, IAL0, report-schema, composition, direct-backend,
or VHDL prerequisite before contract selection. `.602` selected `.603`,
direct bounded implementation of the `sideband_data16_protection` contract,
without behavior changes. The selected sample pairs are data16 protection
completer, fixed composition, and multi-peripheral composition `.ppif`/`.apb`
paths; the contract reuses register-local `allow` / `require (privileged
0|1)`, keeps `width_policy.selected_contract = sideband_data16`, adds
`protection_policy`, replaces policy-effects residue with
`apb_additional_protection_policies_deferred`, and retains
`apb_remaining_widths_deferred`.
`.603` now ships that selected behavior. The six new
`sideband_data16_protection` `.ppif`/`.apb` samples are support-accounted;
sideband-aware data16 multi-register completers accept the same register-local
access-policy syntax as the 32-bit protection path; denied 16-bit mapped reads
return zero data with `PSLVERR=1`; denied writes are side-effect-free,
including `PSTRB=0`; fixed and multi-peripheral compositions propagate
`PPROT/PSTRB` while endpoint completers enforce policies. Reports keep
`width_policy.selected_contract = sideband_data16`, add `protection_policy`,
remove `apb_protection_policy_effects_deferred` for the selected data16
protection samples, and retain the explicit future residues. `.604` selected
`.605`, APB back-to-back transfer policy readiness audit, without behavior
changes. Back-to-back is the remaining APB timing/protocol residue spanning
requester transfer admission, completer setup admission, and composition
propagation; additional protection policies, remaining widths, direct backend,
verification-output, backend-language/VHDL, AXI, and AHB remain deferred.
`.605` now selects `.606`, public APB back-to-back transfer policy contract
selection, without behavior changes. The audit found no lower-layer,
report-static, public-surface, or mdBook prerequisite before contract
selection. Current requester, completer, fixed-composition, multi-peripheral
composition, and interconnect reports retain explicit
`apb_back_to_back_policy_deferred` residue, while `.606` must settle source
vocabulary, explicit versus implicit timing-policy boundary, requester queued
admission, completer setup admission, composition/interconnect propagation,
report/support-accounting movement, diagnostics, validation, rollback, and
direct-backend/VHDL deferral.
`.606` now selects `.607`, bounded implementation of the selected APB
back-to-back timing-policy contract, without behavior changes. The selected
requester vocabulary is explicit opt-in `(timing-policy (back-to-back queued)
(queue-depth 1) (overflow reject))`, requiring public `accepted`, `busy`, and
2-bit `status` response fields. The selected completer vocabulary is
`(timing-policy (setup-admission adjacent))`. The first implementation family
is status-observable requester-transfer, one-register completer, and fixed
one-requester/one-completer composition, each with `.ppif` and `.apb`
coverage. Multi-peripheral propagation, sideband/data16/protection variants,
deeper queues, alternate overflow policies, direct backend,
verification-output, backend-language variants, AXI, AHB, and VHDL remain
deferred.
`.607` now ships the selected bounded APB back-to-back timing-policy behavior
for the status-observable requester-transfer, one-register completer, and
fixed one-requester/one-completer composition samples. The requester samples
`ppif/apb_requester_transfer_status_back_to_back.ppif` and `.apb` expose
`accepted`, keep `busy/status`, implement one queued request slot, reject
overflow without overwriting the queue, and drive queued setup with `PSEL=1`
and `PENABLE=0` without an inserted idle bus cycle. The completer samples
`ppif/apb_completer_back_to_back.ppif` and `.apb` explicitly report adjacent
`PSEL && !PENABLE` setup admission. The fixed-composition samples
`ppif/apb_composition_status_back_to_back.ppif` and `.apb` expose `accepted`
at the top, require compatible requester/completer timing policies, report
aggregate `back_to_back_policy` metadata, remove broad
`apb_back_to_back_policy_deferred` residue, and keep narrowed
`apb_additional_back_to_back_policies_deferred` for multi-peripheral
propagation, sideband/data16/protection variants, deeper queues, alternate
overflow policies, direct backend, verification-output, backend-language
variants, AXI, AHB, and VHDL.
`.608` now audits APB multi-peripheral back-to-back propagation readiness
without behavior changes and selects `.609`, direct bounded implementation for
the 32-bit no-sideband multi-peripheral status back-to-back family. The audit
confirms the generated interconnect is propagation-only, decodes current
`PSEL/PADDR`, forwards `PENABLE`, muxes selected responses, and returns
unmapped errors only for active accesses (`PSEL && PENABLE`), so it is
structurally compatible with queued requester setup and per-peripheral
adjacent setup admission. Sideband/data16/protection variants, deeper queues,
alternate overflow, multiple active APB transfers, direct backend,
verification-output, backend-language variants, AXI, AHB, and VHDL remain
deferred.
`.609` now ships the selected bounded APB multi-peripheral status
back-to-back family for
`ppif/apb_composition_multi_peripheral_status_back_to_back.ppif` and `.apb`.
The selected shape is exactly two 32-bit no-sideband peripheral completers with
the existing static non-overlapping address map. The requester exposes
`accepted/busy/status` and uses the `.607` depth-1 queued overflow-reject
policy; every peripheral declares adjacent setup admission. The generated
interconnect remains propagation-only, decodes current `PSEL/PADDR`, forwards
`PENABLE`, and keeps unmapped errors active-access only. Reports add aggregate
`back_to_back_policy`, remove broad `apb_back_to_back_policy_deferred` only for
the selected top/interconnect/requester/peripheral surfaces, and retain
narrowed `apb_additional_back_to_back_policies_deferred` for
sideband/data16/protection variants, deeper queues, alternate overflow,
multiple active APB transfers, direct backend, verification-output,
backend-language variants, AXI, AHB, and VHDL.
`.610` now selects `.611`, APB sideband-aware back-to-back timing-policy
readiness audit, without behavior changes. Sideband-aware timing is the next
APB residue because no-sideband fixed and multi-peripheral back-to-back paths
are shipped, shipped sideband/data16/protection APB families still carry
explicit back-to-back residue, and data16/protection variants build on the
sideband-aware request payload. The audit must settle queued `PPROT/PSTRB`
capture, fixed versus multi-peripheral propagation scope, adjacent completer
setup with byte lanes and endpoint-local policies, report/residue movement,
diagnostics, validation, and rollback before any implementation. Data16 and
protection back-to-back variants, deeper queues, alternate overflow,
accepted-less requesters, multiple active APB transfers, direct backend,
verification-output, backend-language variants, AXI, AHB, and VHDL remain
deferred.
`.611` now audits APB sideband-aware back-to-back readiness and selects
`.612`, bounded requester-first implementation, without behavior changes. The
audit found no new public timing-policy vocabulary is needed because `.606`
already selected accepted-time sampling for every request payload field,
including sidebands when present. The first implementation should add only the
32-bit sideband requester `apb_requester_transfer_sideband_status_back_to_back`
`.ppif`/`.apb` pair, with `PPROT` width 3, `PSTRB` width 4,
`accepted/busy/status`, queued `PPROT/PSTRB` capture, and queued sideband
relaunch. Fixed composition, multi-peripheral composition, completer
timing-policy propagation, data16/protection back-to-back variants, deeper
queues, alternate overflow, accepted-less requesters, multiple active APB
transfers, direct backend, verification-output, backend-language variants,
AXI, AHB, and VHDL remain deferred.
`.612` now ships that selected requester-first APB sideband timing-policy
behavior for the 32-bit
`apb_requester_transfer_sideband_status_back_to_back` `.ppif`/`.apb` samples.
The generated requester queues `PPROT/PSTRB` through `queued_prot` and
`queued_wstrb`, relaunches queued setup without an inserted idle cycle, masks
queued `PSTRB` by the queued write bit, and removes the broad back-to-back
residue only for the selected sideband requester surfaces. Fixed composition,
multi-peripheral composition, completer propagation, data16/protection
variants, deeper queues, alternate overflow, direct backend,
verification-output, backend-language variants, AXI, AHB, and VHDL remain
deferred.
`.613` now audits APB sideband-aware completer and composition back-to-back
readiness and selects `.614`, public contract selection before implementation,
without behavior changes. The requester prerequisite is present after `.612`,
and sideband completer/composition substrates already sample or propagate
`PPROT/PSTRB`; the remaining guards still restrict adjacent completer setup and
fixed/multi-peripheral composition timing propagation to 32-bit no-sideband
families. `.614` must settle the bounded one-register sideband completer and
fixed-composition contract, sample names, report/support movement,
diagnostics, validation, and rollback before implementation. Multi-peripheral
sideband timing propagation, data16/protection variants, multi-register timing
policy, deeper queues, alternate overflow, direct backend, verification-output,
backend-language variants, AXI, AHB, and VHDL remain deferred.
`.614` now selects the public sideband-aware APB completer and fixed-composition
back-to-back contract without behavior changes. `.615` shall implement
`ppif/apb_completer_sideband_back_to_back.ppif`, its `.apb` alias,
`ppif/apb_composition_sideband_status_back_to_back.ppif`, and its `.apb`
alias together. The selected completer is the bounded one-register 32-bit
sideband-aware adjacent setup family with `PPROT width 3` and `PSTRB width 4`.
The selected fixed composition combines the `.612` sideband requester
back-to-back policy with that sideband completer and sideband-aware wiring.
Multi-peripheral sideband timing propagation, data16/protection variants,
multi-register timing policy, deeper queues, alternate overflow, direct
backend, verification-output, backend-language variants, AXI, AHB, and VHDL
remain deferred.
`.615` now ships the selected sideband-aware APB completer and fixed-composition
back-to-back behavior. The new public sources are
`ppif/apb_completer_sideband_back_to_back.ppif`, its `.apb` alias,
`ppif/apb_composition_sideband_status_back_to_back.ppif`, and its `.apb`
alias. The selected sideband completer reports adjacent setup admission with
`PPROT width 3` and `PSTRB width 4`; the selected fixed composition reports
aggregate `back_to_back_policy` combining the `.612` sideband requester queue
with the adjacent sideband completer. Broad `apb_back_to_back_policy_deferred`
residue is removed from those selected surfaces, while data16/protection
variants, multi-register timing policy, broader timing-policy families, deeper
queues, alternate overflow, direct backend, verification-output,
backend-language variants, AXI, AHB, and VHDL remain deferred.
`.616` now selects `.617`, public contract selection for the bounded 32-bit
sideband-aware APB multi-peripheral back-to-back family, without behavior
changes. `.609` already shipped no-sideband multi-peripheral back-to-back
propagation, `.612` shipped sideband requester queued `PPROT/PSTRB`, and
`.615` shipped sideband adjacent completer setup plus fixed-composition
propagation. Existing sideband multi-peripheral samples propagate
`PPROT/PSTRB` through the generated interconnect but still carry broad
`apb_back_to_back_policy_deferred`; a temporary combined candidate failed at
the current no-sideband-only multi-peripheral timing guard. `.617` must settle
exact public sources, endpoint/interconnect compatibility, report/support
movement, diagnostics, validation, and rollback before implementation.
Data16/protection variants, multi-register timing policy, deeper queues,
alternate overflow, direct backend, verification-output, backend-language
variants, AXI, AHB, and VHDL remain deferred.
`.617` now selects the public sideband-aware APB multi-peripheral
back-to-back contract without behavior changes. `.618` shall implement exactly
`ppif/apb_composition_multi_peripheral_sideband_status_back_to_back.ppif` and
its `.apb` alias. The selected contract is a two-peripheral 32-bit sideband
composition with requester `accepted/busy/status`, depth-1 queued requester
timing, `PPROT width 3`, `PSTRB width 4`, adjacent setup admission on every
one-register peripheral completer, and the existing static status/control
address-map/decode shape. Reports shall remove broad back-to-back residue for
the selected top, requester, interconnect, and peripheral surfaces while
retaining narrowed future-policy residue plus protection-policy effects
residue. Data16/protection timing variants, multi-register timing policy,
deeper queues, alternate overflow, direct backend, verification-output,
backend-language variants, AXI, AHB, and VHDL remain deferred.
`.618` now ships that selected bounded APB sideband-aware multi-peripheral
status back-to-back behavior. The new public sources are
`ppif/apb_composition_multi_peripheral_sideband_status_back_to_back.ppif` and
its `.apb` alias. The selected generated requester queues `PPROT/PSTRB`, the
generated interconnect decodes the queued setup through current `PSEL/PADDR`
with `PENABLE` low and fans out `PPROT/PSTRB`, and every selected peripheral
uses adjacent sideband setup admission. Reports remove broad back-to-back
residue for the selected top, requester, interconnect, and peripheral surfaces,
retain narrowed future-policy residue, and keep protection-policy effects
residue explicit. Data16/protection timing variants, multi-register timing
policy, deeper queues, alternate overflow, direct backend, verification-output,
backend-language variants, AXI, AHB, and VHDL remain deferred.
`.619` now selects `.620`, APB data16/protection back-to-back timing-policy
readiness audit, without behavior changes. Live reports over representative
data16, protection, and data16-protection requester/composition samples still
carry broad `apb_back_to_back_policy_deferred` and no aggregate
`back_to_back_policy`, while current requester/completer/composition timing
guards remain bounded to selected 32-bit no-sideband or selected 32-bit
sideband-aware one-register families. `.620` must decide whether the next exact
owner is data16-only, protection-only, combined data16-protection,
multi-register adjacent-setup prerequisite, requester/completer prerequisite,
or explicit deferral before behavior changes.
`.620` now audits that data16/protection back-to-back readiness and selects
`.621`, public contract selection for a bounded APB sideband-aware
multi-register back-to-back timing-policy prerequisite, without behavior
changes. The audit found that all shipped data16/protection completer and
composition samples use multi-register storage, while current timing-policy
guards still reject multi-register completer storage for adjacent setup and
composition propagation. The next contract selection must settle exact
sideband-aware 32-bit multi-register samples, endpoint compatibility,
report/support movement, diagnostics, validation, rollback, and explicit
deferral for data16, protection-policy effects, combined data16-protection,
deeper queues, alternate overflow, direct backend, verification-output,
backend-language variants, AXI, AHB, and VHDL.
`.621` now selects `.622`, direct bounded implementation of the APB
sideband-aware multi-register back-to-back timing-policy prerequisite, without
behavior changes. The selected public sources are
`ppif/apb_completer_multi_register_sideband_back_to_back.ppif`,
`ppif/apb_completer_multi_register_sideband_back_to_back.apb`,
`ppif/apb_composition_multi_register_sideband_status_back_to_back.ppif`, and
`ppif/apb_composition_multi_register_sideband_status_back_to_back.apb`. The
selected implementation is limited to a 32-bit sideband-aware no-policy
two-register completer with adjacent setup admission and a fixed
one-requester/one-completer composition over the `.612` sideband requester.
Multi-peripheral multi-register timing propagation, data16/protection
variants, deeper queues, alternate overflow, direct backend,
verification-output, backend-language variants, AXI, AHB, and VHDL remain
deferred.
`.622` now ships that selected bounded APB sideband-aware multi-register
back-to-back timing-policy prerequisite. The new public sources are
`ppif/apb_completer_multi_register_sideband_back_to_back.ppif`,
`ppif/apb_completer_multi_register_sideband_back_to_back.apb`,
`ppif/apb_composition_multi_register_sideband_status_back_to_back.ppif`, and
`ppif/apb_composition_multi_register_sideband_status_back_to_back.apb`. The
selected standalone completer accepts adjacent setup for the 32-bit
sideband-aware two-register no-policy shape, decodes `reg0` at address `0` and
`reg1` at address `4`, samples `PPROT/PSTRB`, and applies byte-lane writes. The
selected fixed composition combines that completer with the `.612` sideband
requester queue and exposes aggregate `back_to_back_policy`. Multi-peripheral
multi-register timing propagation, data16/protection variants, deeper queues,
alternate overflow, direct backend, verification-output, backend-language
variants, AXI, AHB, and VHDL remain deferred. `.623` selected the next APB
data16/protection back-to-back owner without behavior changes first.
`.623` now selects `.624`, public contract selection for the bounded APB
sideband-aware data16 back-to-back timing-policy family, without behavior
changes. Live reports over representative data16, protection, and
data16-protection APB sources still show no aggregate `back_to_back_policy` and
retain broad `apb_back_to_back_policy_deferred`. Data16 is selected before
protection because it widens the shipped sideband queue and adjacent-completer
paths to 16-bit data and `PSTRB width 2` without adding register-local
denied-access side effects. Protection-only timing, combined data16-protection
timing, multi-peripheral multi-register timing, deeper queues, alternate
overflow, direct backend, verification-output, backend-language variants, AXI,
AHB, and VHDL remain deferred.
`.624` now selects `.625` to directly implement the bounded APB
sideband-aware data16 back-to-back timing-policy contract for exactly
`ppif/apb_requester_transfer_sideband_data16_status_back_to_back.ppif`, its
`.apb` alias, `ppif/apb_completer_multi_register_sideband_data16_back_to_back.ppif`,
its `.apb` alias,
`ppif/apb_composition_multi_register_sideband_data16_status_back_to_back.ppif`,
and its `.apb` alias. The selected contract keeps APB addresses and wait
counts at 32/4 bits, uses 16-bit data and `PSTRB width 2`, requires
`accepted/busy/status` depth-1 queued requester timing, selects a two-register
no-policy adjacent completer with `reg0` at address `0` and `reg1` at address
`2`, and selects fixed one-requester/one-completer propagation. Protection-only
timing, combined data16-protection timing, multi-peripheral multi-register
timing, deeper queues, alternate overflow, direct backend, verification-output,
backend-language variants, AXI, AHB, and VHDL remain deferred.
`.625` now ships that selected bounded APB sideband-aware data16
back-to-back timing-policy behavior. The new public sources are
`ppif/apb_requester_transfer_sideband_data16_status_back_to_back.ppif`,
`ppif/apb_requester_transfer_sideband_data16_status_back_to_back.apb`,
`ppif/apb_completer_multi_register_sideband_data16_back_to_back.ppif`,
`ppif/apb_completer_multi_register_sideband_data16_back_to_back.apb`,
`ppif/apb_composition_multi_register_sideband_data16_status_back_to_back.ppif`,
and `ppif/apb_composition_multi_register_sideband_data16_status_back_to_back.apb`.
The requester queues 16-bit write data, `PPROT width 3`, and `PSTRB width 2`;
the adjacent completer decodes `reg0` at address `0` and `reg1` at address
`2` with 16-bit byte-lane writes; the fixed composition reports aggregate
`back_to_back_policy` while retaining future-policy, remaining-width, and
protection-policy residue. `.626` selects the next APB data16/protection
back-to-back owner without behavior changes.
`.626` now selects `.627`, public contract selection for a bounded APB
sideband-aware protection back-to-back timing-policy family, without behavior
changes. Live reports after `.625` confirm the 32-bit protection and
data16-protection APB samples still expose `protection_policy`, have no
`back_to_back_policy`, and retain broad `apb_back_to_back_policy_deferred`.
A temporary protected adjacent-setup candidate fails at the current no-policy
timing guard, so protection-only timing is selected before combined
data16-protection timing. Multi-peripheral multi-register timing, deeper
queues, alternate overflow, accepted-less requesters, multiple active APB
transfers, direct backend, verification-output, backend-language variants,
AXI, AHB, and VHDL remain deferred.
`.627` now selects `.628` to directly implement exactly four APB
sideband-aware protection back-to-back public sources:
`ppif/apb_completer_multi_register_sideband_protection_back_to_back.ppif`,
its `.apb` alias,
`ppif/apb_composition_multi_register_sideband_protection_status_back_to_back.ppif`,
and its `.apb` alias. The selected protected completer is 32-bit,
sideband-aware, uses `PPROT width 3`, `PSTRB width 4`, `reg0` at address `0`
with read-allow/write-privileged policy, and `reg1` at address `4` with
read/write privileged policy. The selected fixed composition combines that
protected adjacent completer with the `.612` queued sideband requester and
leaves protection enforcement owned by the completer. Data16-protection
timing, multi-peripheral multi-register timing, deeper queues, alternate
overflow, accepted-less requesters, multiple active APB transfers, broader
protection policies, direct backend, verification-output, backend-language
variants, AXI, AHB, and VHDL remain deferred.
`.628` now ships the selected bounded APB sideband-aware protection
back-to-back timing-policy behavior. The new public sources are
`ppif/apb_completer_multi_register_sideband_protection_back_to_back.ppif`,
`ppif/apb_completer_multi_register_sideband_protection_back_to_back.apb`,
`ppif/apb_composition_multi_register_sideband_protection_status_back_to_back.ppif`,
and
`ppif/apb_composition_multi_register_sideband_protection_status_back_to_back.apb`.
The standalone completer admits adjacent setup for the exact protected
32-bit two-register shape, preserves `PPROT` allow/deny and zero-strobe
semantics, and keeps `reg0` at address `0` plus `reg1` at address `4`. The
fixed composition propagates the `.612` queued sideband requester into that
protected completer, reports aggregate `back_to_back_policy`, removes broad
back-to-back residue for the selected surfaces, and retains narrowed
future-timing, broader-protection, remaining-width, and multi-peripheral
decode residue. `.629` is the next selector for remaining APB timing residue:
data16-protection timing, multi-peripheral multi-register timing, deeper
queues, alternate overflow, accepted-less requesters, multiple active APB
transfers, broader protection policy, direct backend, verification-output,
backend-language variants, AXI, AHB, and VHDL remain deferred.
`.629` now selects `.630`, public contract selection for a bounded APB
sideband-aware data16-protection back-to-back timing-policy family, without
behavior changes. Live data16-protection standalone, fixed-composition, and
multi-peripheral reports after `.628` remain 16-bit, expose
`protection_policy`, have no `back_to_back_policy`, and keep broad
`apb_back_to_back_policy_deferred`. A temporary data16-protection adjacent
setup candidate still fails at the current selected-family timing guard, so
`.630` must settle the exact public sample names, selected 16-bit protected
two-register shape, requester/status requirements, report/residue movement,
diagnostics, validation, and rollback before implementation. Multi-peripheral
data16-protection status/control timing later shipped in `.634`; broader
multi-peripheral multi-register timing, deeper queues, alternate overflow,
accepted-less requesters, multiple active APB transfers, broader protection
policy, direct backend, verification-output, backend-language variants, AXI,
AHB, and VHDL remain deferred.
`.630` now selects `.631` to directly implement exactly four APB
sideband-aware data16-protection back-to-back public sources:
`ppif/apb_completer_multi_register_sideband_data16_protection_back_to_back.ppif`,
its `.apb` alias,
`ppif/apb_composition_multi_register_sideband_data16_protection_status_back_to_back.ppif`,
and its `.apb` alias. The selected standalone completer is 16-bit,
sideband-aware, uses `PPROT width 3`, `PSTRB width 2`, `reg0` at address `0`
with read-allow/write-privileged policy, and `reg1` at address `2` with
read/write privileged policy. The selected fixed composition combines that
protected data16 adjacent completer with the `.625` queued data16 sideband
requester and leaves protection enforcement owned by the completer. No
requester-only public source is selected. Multi-peripheral data16-protection
status/control timing later shipped in `.634`; broader multi-peripheral
multi-register timing, deeper queues, alternate overflow, accepted-less
requesters, multiple active APB transfers, broader protection policies,
direct backend, verification-output, backend-language variants, AXI, AHB, and
VHDL remain deferred.
`.631` now ships those four selected APB sideband-aware data16-protection
back-to-back public sources. The standalone completer accepts adjacent setup
for the selected protected 16-bit two-register shape with `reg0` at address
`0`, `reg1` at address `2`, `PPROT width 3`, and `PSTRB width 2`, preserving
allowed, denied, zero-strobe, byte-lane, and unmapped access behavior. The
fixed composition propagates the `.625` queued data16 sideband requester into
that completer, exposes aggregate `back_to_back_policy`, and keeps protection
enforcement owned by the completer. `.632` now selects `.633`, public
contract selection for bounded APB sideband-aware multi-peripheral
data16-protection back-to-back timing, without behavior changes. Existing
multi-peripheral data16-protection reports already expose 16-bit data,
`PPROT width 3`, `PSTRB width 2`, and completer-owned protection enforcement,
but still have no aggregate `back_to_back_policy` and retain broad
`apb_back_to_back_policy_deferred`. Broader multi-peripheral multi-register
timing, deeper queues, alternate overflow, accepted-less requesters, multiple
active APB transfers, broader protection policies, direct backend,
verification-output, backend-language variants, AXI, AHB, and VHDL remain
deferred.
`.633` now selects `.634` to directly implement exactly two APB
sideband-aware multi-peripheral data16-protection back-to-back public sources:
`ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.ppif`
and its `.apb` alias. The selected contract uses the existing two-peripheral
status/control protected data16 topology with requester `accepted/busy/status`
depth-1 queued timing, adjacent setup on both peripheral completers, 16-bit
data, `PPROT width 3`, `PSTRB width 2`, 2-byte-aligned windows at `0` and
`258`, propagation-only interconnect decode, peripheral-owned protection
enforcement, and aggregate multi-peripheral `back_to_back_policy` reporting.
Broader multi-peripheral multi-register timing, deeper queues, alternate
overflow, accepted-less requesters, multiple active APB transfers, broader
protection policies, direct backend, verification-output, backend-language
variants, AXI, AHB, and VHDL remain deferred.
`.634` now ships those two selected APB sideband-aware multi-peripheral
data16-protection back-to-back public sources. The generated requester keeps
depth-1 queued `accepted/busy/status` timing and relaunches queued 16-bit
`PWDATA`, `PPROT`, and 2-bit `PSTRB`; the generated interconnect propagates
queued setup without inserting an idle cycle, decodes the `0` and `258`
windows, translates `PADDR_CONTROL`, and remains enforcement-free; the status
and control peripheral completers own register-local privileged `PPROT[0]`
enforcement and preserve data16 byte-lane, zero-strobe, denied-access,
unmapped, and adjacent-setup behavior. Selected reports remove broad
`apb_back_to_back_policy_deferred` and retain narrowed future timing,
broader-protection, and remaining-width residue. `.635` is now the next
selector for the remaining APB back-to-back timing frontier. Broader
multi-peripheral multi-register timing, deeper queues, alternate overflow,
accepted-less requesters, multiple active APB transfers, broader protection
policies, direct backend, verification-output, backend-language variants,
AXI, AHB, and VHDL remain deferred.
`.635` now selects `.636`, readiness audit for broader APB multi-peripheral
multi-register back-to-back timing propagation, without behavior changes. The
audit is next because broader multi-peripheral multi-register propagation is
the first explicit remaining composition timing residue after `.634`, while
deeper queues, alternate overflow, accepted-less requesters, multiple active
APB transfers, broader protection policies, direct backend,
verification-output, backend-language variants, AXI, AHB, and VHDL remain
deferred behind future exact owners.
`.636` now selects `.637`, public contract selection for bounded 32-bit APB
sideband-aware protection multi-peripheral back-to-back timing, without
behavior changes. The readiness audit chose the existing
`ppif/apb_composition_multi_peripheral_sideband_protection.ppif` family as
the conservative next candidate: 32-bit data/addressing, `PPROT width 3`,
`PSTRB width 4`, two protected registers per peripheral at byte addresses
`0` and `4`, status/control windows at `0` and `256`, propagation-only
interconnect decode, peripheral-completer-owned protection enforcement, and
broad `apb_back_to_back_policy_deferred` residue. `.637` will settle exact
source names, topology, timing, protection, sideband propagation, reporting,
support accounting, diagnostics, validation, rollback, and implementation
boundary before any behavior change.
`.637` now selects `.638` to directly implement exactly two APB
sideband-aware protection multi-peripheral back-to-back public sources:
`ppif/apb_composition_multi_peripheral_sideband_protection_status_back_to_back.ppif`
and its `.apb` alias. The selected contract uses the existing two-peripheral
status/control protected 32-bit topology with requester `accepted/busy/status`
depth-1 queued timing, adjacent setup on both peripheral completers,
`PPROT width 3`, `PSTRB width 4`, 4-byte-aligned windows at `0` and `256`,
propagation-only interconnect decode, peripheral-owned protection
enforcement, and aggregate multi-peripheral `back_to_back_policy` reporting.
No-policy multi-peripheral multi-register timing, sideband data16 no-policy
multi-register timing, data16-protection generalization beyond the selected
`.634` family, generalized register shapes, deeper queues, alternate
overflow, accepted-less requesters, multiple active APB transfers, broader
protection policies, direct backend, verification-output, backend-language
variants, AXI, AHB, and VHDL remain deferred.
`.638` now ships that selected bounded APB sideband-aware multi-peripheral
protection back-to-back timing behavior. The `.ppif` and `.apb` sources are
support-accounted, generate requester/interconnect/status/control review
artifacts, report aggregate multi-peripheral `back_to_back_policy`, preserve
peripheral-completer-owned privileged `PPROT[0]` enforcement, propagate
queued 32-bit `PWDATA` plus `PPROT/PSTRB` through the interconnect without
idle insertion, remove broad `apb_back_to_back_policy_deferred`, and retain
narrowed future timing, broader-protection, and alternate-width residue.
`.639` is the next selector for the remaining APB back-to-back timing residue
after the protected 32-bit multi-peripheral timing family shipped.
`.639` now selects `.640`, readiness audit for APB no-policy
multi-peripheral multi-register back-to-back timing, without behavior
changes. Fixed no-policy multi-register timing is already shipped for
selected 32-bit sideband and sideband data16 fixed compositions, while
multi-peripheral no-policy timing is shipped only for one-register peripheral
shapes. The current multi-peripheral timing guard still rejects broader
two-register no-policy peripheral storage, so `.640` must settle source
shape, endpoint storage, interconnect propagation, report/residue movement,
diagnostics, support accounting, validation, rollback, and docs before any
parser/generator/sample/test/HDL behavior change.
`.640` now selects `.641`, public contract selection for the bounded 32-bit
sideband-aware no-policy multi-peripheral multi-register back-to-back timing
family, without behavior changes. Fixed sideband no-policy multi-register
timing and sideband data16 no-policy multi-register timing are
support-accounted on fixed compositions, while multi-peripheral no-policy
timing is currently one-register per peripheral. In-memory two-register
no-policy multi-peripheral candidates fail closed at the current
multi-peripheral timing guard, so `.641` must settle public source names,
32-bit register/window shape, requester/completer/interconnect timing
requirements, report/residue movement, support-accounting identities,
diagnostics, validation, rollback, and docs before implementation.
`.641` now selects `.642`, direct implementation of exactly
`ppif/apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back.ppif`
and its `.apb` alias, without behavior changes. The selected contract is a
bounded two-peripheral 32-bit sideband-aware no-policy multi-register family:
requester `accepted/busy/status`, depth-1 queued overflow-reject timing,
`PPROT width 3`, `PSTRB width 4`, status/control windows at bases `0` and
`256`, adjacent setup on both peripheral completers, and exactly `reg0` at
address `0` plus `reg1` at address `4` with no access policy in each
peripheral. Reports shall add aggregate `back_to_back_policy`, remove broad
back-to-back residue for selected surfaces, retain narrowed future-policy,
protection-effects, and alternate-width residue, and keep sideband data16
no-policy multi-peripheral multi-register timing deferred.
`.642` now ships the selected bounded 32-bit sideband-aware no-policy APB
multi-peripheral multi-register back-to-back timing behavior for exactly
`ppif/apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back.ppif`
and its `.apb` alias. The generated requester exposes
`accepted/busy/status`, accepts one active transfer plus one queued next
transfer, and relaunches queued 32-bit `PWDATA` plus `PPROT/PSTRB`. The
generated interconnect propagates queued setup without idle-cycle insertion,
decodes the status/control windows at bases `0` and `256`, subtracts the
control base for `PADDR_CONTROL`, muxes selected responses, and remains
access-policy-free. Both generated peripheral completers use adjacent setup
and exactly no-policy `reg0` at local byte address `0` plus `reg1` at local
byte address `4`, with 32-bit reset-0 storage and 4-bit byte-lane writes.
Reports add aggregate multi-peripheral `back_to_back_policy`, remove broad
`apb_back_to_back_policy_deferred` for the selected surfaces, and retain
narrowed future timing, protection-policy-effects, and alternate-width
residue. Sideband data16 no-policy multi-peripheral multi-register timing,
generalized multi-peripheral multi-register shapes, deeper queues, alternate
overflow, accepted-less requesters, multiple active APB transfers, direct
backend, verification-output, backend-language variants, AXI, AHB, and VHDL
remain deferred.
`.643` now selects `.644`, public contract selection for the bounded APB
sideband-aware data16 no-policy multi-peripheral multi-register
back-to-back timing family, without behavior changes. `.625` already ships
fixed-composition data16 no-policy reg0/reg1 timing, `.634` already ships
data16 multi-peripheral timing for the protected status/control shape, and
`.642` already ships the 32-bit no-policy reg0/reg1 multi-peripheral family.
No public data16 no-policy multi-peripheral multi-register back-to-back
source exists yet, and the current multi-peripheral timing guard admits the
sideband data16 family only for the selected data16-protection status/control
storage shape. `.644` must settle exact public source names, status/control
window shape, requester/completer/interconnect timing requirements,
no-policy `reg0`/`reg1` storage requirements, report/residue movement,
support-accounting identities, diagnostics, validation, rollback, and docs
before implementation.
`.644` now selects `.645`, direct implementation of exactly
`ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back.ppif`
and its `.apb` alias, without behavior changes. The selected contract is one
requester, two peripheral completers, 32-bit addresses, 16-bit APB and
register data, `PPROT width 3`, `PSTRB width 2`, status/control windows at
bases `0` and `258` with size `258`, adjacent setup on both peripherals, and
exactly no-policy `reg0` at local address `0` plus `reg1` at local address
`2` in each peripheral. Reports shall add aggregate `back_to_back_policy`,
remove broad back-to-back residue for selected surfaces, retain narrowed
future-policy, protection-effects, and remaining-width residue, and keep
data16-protection generalization, generalized register shapes, deeper queues,
alternate overflow, accepted-less requesters, multiple active APB transfers,
direct backend, verification-output, backend-language variants, AXI, AHB, and
VHDL deferred.
`.645` now ships the selected bounded APB sideband-aware data16 no-policy
multi-peripheral multi-register back-to-back timing behavior for exactly
`ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back.ppif`
and its `.apb` alias. The generated requester exposes
`accepted/busy/status`, accepts one active transfer plus one queued next
transfer, and relaunches queued 16-bit `PWDATA` plus `PPROT/PSTRB`. The
generated interconnect propagates queued setup without idle-cycle insertion,
decodes status/control windows at bases `0` and `258`, subtracts the control
base for `PADDR_CONTROL`, muxes selected responses, and remains
access-policy-free. Both generated peripheral completers use adjacent setup
and exactly no-policy `reg0` at local byte address `0` plus `reg1` at local
byte address `2`, with 16-bit reset-0 storage and 2-bit byte-lane writes.
Reports add aggregate multi-peripheral `back_to_back_policy`, remove broad
`apb_back_to_back_policy_deferred`, and retain narrowed future timing,
protection-policy-effects, and remaining-width residue. Data16-protection
generalization, generalized multi-peripheral multi-register shapes, deeper
queues, alternate overflow, accepted-less requesters, multiple active APB
transfers, direct backend, verification-output, backend-language variants,
AXI, AHB, and VHDL remain deferred.
`.646` now selects `.647`, readiness audit for APB data16-protection
generalization, without behavior changes. The selector found that selected
no-policy multi-peripheral multi-register timing is shipped for both 32-bit
and data16 families, selected protected data16 timing is shipped for fixed and
multi-peripheral status/control families, and no explicit public
multi-peripheral multi-register data16-protection source family exists yet.
`.647` must decide whether the next exact owner is public contract selection,
direct implementation of an already-selected family, a source-shape/report-static
prerequisite, or explicit deferral. Generalized register shapes,
deeper queues, alternate overflow, accepted-less requesters, multiple active
APB transfers, bus matrices, scoreboards, direct backend, verification-output,
backend-language variants, AXI, AHB, and VHDL remain deferred.
`.647` now selects `.648`, public contract selection for bounded APB
sideband-aware data16-protection multi-peripheral multi-register
back-to-back timing, without behavior changes. The audit found that fixed
data16-protection multi-register timing and selected multi-peripheral
data16-protection status/control timing are shipped, but no explicit public
multi-peripheral multi-register data16-protection source family exists yet.
`.648` must settle exact source names, storage/policy shape, report/residue
movement, support accounting, diagnostics, validation, rollback, docs, and
Knowledge Map before behavior changes. Generalized register shapes, deeper
queues, alternate overflow, accepted-less requesters, multiple active APB
transfers, bus matrices, scoreboards, direct backend, verification-output,
backend-language variants, AXI, AHB, and VHDL remain deferred.
`.648` now selects `.649`, direct implementation of exactly
`ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back.ppif`
and its `.apb` alias, without behavior changes. The selected contract uses
one requester, two peripheral completers, 32-bit addresses, 16-bit APB and
register data, `PPROT width 3`, `PSTRB width 2`, status/control windows at
bases `0` and `258`, adjacent setup on both peripherals, and exactly
protected `reg0` at local address `0` plus protected `reg1` at local address
`2` in each peripheral. `reg0` reads are allowed and writes require
privileged `PPROT[0]`; `reg1` reads and writes require privileged
`PPROT[0]`. Status/control protected storage generalization beyond `.634`,
generalized register shapes, deeper queues, alternate overflow, accepted-less
requesters, multiple active APB transfers, bus matrices, scoreboards, direct
backend, verification-output, backend-language variants, AXI, AHB, and VHDL
remain deferred.
`.649` now ships the selected bounded APB sideband-aware data16-protection
multi-peripheral multi-register back-to-back timing behavior for exactly
`ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back.ppif`
and its `.apb` alias. The generated requester exposes
`accepted/busy/status`, accepts one active transfer plus one queued next
transfer, and relaunches queued 16-bit `PWDATA` plus `PPROT/PSTRB`. The
generated interconnect propagates queued setup without idle-cycle insertion,
decodes status/control windows at bases `0` and `258`, translates
`PADDR_CONTROL`, muxes selected responses, and remains protection-enforcement
free. Both peripheral completers use adjacent setup and exactly protected
`reg0` at local byte address `0` plus protected `reg1` at local byte address
`2`, with 16-bit reset-0 storage, 2-bit byte-lane writes, `reg0` read allow
plus privileged writes, and `reg1` privileged reads/writes. Reports add
aggregate multi-peripheral `back_to_back_policy`, remove broad
`apb_back_to_back_policy_deferred` and old
`apb_protection_policy_effects_deferred`, and retain narrowed future timing,
additional-protection-policy, and remaining-width residue. Status/control
protected storage generalization beyond the selected family, generalized
multi-peripheral multi-register shapes, deeper queues, alternate overflow,
accepted-less requesters, multiple active APB transfers, bus matrices,
scoreboards, direct backend, verification-output, backend-language variants,
AXI, AHB, and VHDL remain deferred.
`.650` now selects `.651`, readiness audit for APB status/control
protected-storage generalization, without behavior changes. The selector
chooses that residue because `.649` closed the explicit selected
data16-protection `reg0`/`reg1` two-peripheral timing surface while `.638` and
`.634` already ship selected 32-bit and data16 status/control protected
two-peripheral timing families. `.651` must decide whether the next exact
owner is public contract selection for a bounded status/control
protected-storage generalization, direct implementation of one already-selected
status/control protected shape, a smaller source-shape/report-static
prerequisite, or explicit deferral before generalized multi-peripheral
multi-register shapes, deeper queues, alternate overflow, accepted-less
requesters, multiple active APB transfers, bus matrices, scoreboards, direct
backend, verification-output, backend-language variants, AXI, AHB, or VHDL.

`.269` selected `.270`, readiness audit for mixed dynamic/static
response-demux after the all-dynamic multiple dynamic
write/read/read-data/multi-beat chain is now covered. `.270` selected `.271`,
public contract selection for bounded mixed dynamic/static write `BID`
response-demux. `.271` selected `.272`, and `.272` now ships generated
bounded mixed write behavior through the support-accounted public sample
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux.ppif`.
The shipped contract uses existing `response-demux.write` syntax with exactly
one dynamic write transaction, exactly one concrete static write transaction,
static concrete IDs reserved away from dynamic capture, mixed request onehot0
assertions, response active/unique-match assertions, and completion-active
release assertions. `.273` selected `.274`, readiness audit for mixed
dynamic/static read response-demux before choosing single-beat `RID`,
burst-last `RID && RLAST`, read-data, burst/runtime, multi-beat, report
cleanup, or another prerequisite. `.274` selected `.275`, public contract
selection for bounded mixed dynamic/static read single-beat `RID`
response-demux. `.275` selected `.276`, direct generated behavior for that
bounded mixed read contract. `.276` now ships generated bounded mixed
dynamic/static read single-beat `RID` response-demux through public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux.ppif`.
`.277` selected `.278`, readiness audit for bounded mixed dynamic/static read
burst-last `RID && RLAST` response-demux before read-data, burst-length/runtime
validation, multi-beat output banks, or broader mixed widening. `.278`
selected `.279`, public contract selection for that mixed read burst-last
shape, after finding the substrate close but requiring explicit static
final-beat completion and report semantics before implementation. `.279`
selected `.280`, direct generated behavior for the bounded mixed read
burst-last contract. `.280` now ships generated bounded mixed dynamic/static
read burst-last `RID && RLAST` response-demux through public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif`.
The shipped behavior uses existing `response-demux.read` syntax with
`response-scope burst-last`, one-bit `axi0_rlast`, one dynamic read transaction
and one concrete static read transaction, static concrete ID reservation away
from dynamic capture, raw `RID` beat active/unique assertions, final
`RID && RLAST` dynamic/static completions, and report mode
`bounded_mixed_dynamic_static_read_rid_rlast_demux_contract`. `.281` selected
`.282`, readiness audit for read-data over generated mixed dynamic/static read
response-demux, because scalar read-data coverage is the next dependency
before mixed burst-length/runtime validation, multi-beat output banks, or
broader mixed widening. `.282` selected `.283`, public contract selection for
bounded scalar read-data over generated mixed dynamic/static read
response-demux, after finding the read-data helper substrate close but not
contract-complete for the new mixed completion sources. `.283` selected
`.284`, direct generated behavior for bounded scalar read-data over generated
mixed dynamic/static read response-demux. `.284` now ships that behavior
through support-accounted public samples
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_read_data.ppif`
and
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data.ppif`.
The shipped capture covers the ordered dynamic-plus-static transaction set,
guards scalar `RDATA`/`RRESP` updates only with generated mixed demux
completion pulses, and reports the mixed-specific single-beat and last-beat
completion-validity strings. `.285` selected `.286`, readiness audit for
generated report-only raw-`ARLEN` burst-length capture over the mixed
dynamic/static last-beat read-data shape. `.286` selected `.287`, direct
bounded implementation of that report-only raw-`ARLEN` capture shape. `.287`
now ships that behavior through support-accounted public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_burst_length.ppif`.
The shipped behavior emits `axi0_arlen`, per-transaction raw-`ARLEN`
storage/capture rules, keeps scalar `RDATA`/`RRESP` capture guarded by the
generated mixed `RID && RLAST` completion pulses, and reports `report_only`
burst-length validation with the mixed last-beat completion-validity string.
`.288` selected `.289`, direct bounded implementation of runtime
beat-count/`RLAST` validation over that same mixed dynamic/static
raw-`ARLEN` scalar last-beat read-data shape, after finding the generic
runtime machinery ready and no separate public contract selection needed.
`.289` now ships that runtime sibling through support-accounted public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_burst_length_runtime_assertion.ppif`.
The generated behavior emits expected-beat storage, read-beat counters,
request-time `ARLEN + 1` initialization, raw matched-read-beat counter
increments for the dynamic captured `RID` and static concrete `RID`, four
runtime assertions per covered transaction, and report/residue updates with
`runtime_assertion`, `response_demux_matched_read_beat`, and no
`generated_beat_count_validation` residue while preserving `.287`
report-only behavior.
`.290` selected `.291`, direct bounded implementation of generated mixed
dynamic/static multi-beat output banks over the `.289` runtime boundary,
after finding the existing output-bank machinery transaction-list driven and
the current blocker local to the mixed coverage predicate. `.291` now ships
that behavior through support-accounted public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_multi_beat.ppif`.
The generated behavior emits per-transaction data/status output banks, valid
masks, length outputs, scalar worst-observed `RRESP` aggregate outputs,
request-time output-bank clearing, raw matched-read-beat lane capture for the
dynamic captured `RID` and static concrete `RID`, raw `ARLEN`/expected
beat/count state, four runtime assertions per transaction, empty read-data
residue, and `response_demux.residue = [same_id_ordering]`. `.291` selected
`.292`, the next mixed dynamic/static frontier selector after generated mixed
multi-beat output banks. `.292` now selects `.293`, readiness audit for
multiple mixed dynamic/static transaction cardinality after the one-dynamic
plus one-concrete-static mixed path reached multi-beat output banks. `.293`
now selects `.294`, public contract selection for bounded multiple mixed
dynamic/static write `BID` response-demux. `.294` now selects `.295`, direct
generated behavior for exactly one dynamic plus two concrete static write
transactions under existing `response-demux.write` syntax. `.295` now ships
that bounded multiple mixed write behavior through support-accounted public
sample
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static.ppif`.
The generated behavior emits dynamic selected-ID/busy state, per-static busy
state, dynamic capture exclusions for static IDs `4'd3` and `4'd5`, onehot0
request assertions across all selected write transactions, three raw `BID`
response-demux completion pulses, pairwise unique-match assertions, and
list-shaped report fields while preserving the `.272` one-dynamic plus
one-static report contract. `.296` now selects `.297`, readiness audit for
multiple mixed dynamic/static read response-demux after the widened write
contract shipped, because the read plan builder remains singular while
read-side single-beat `RID` and burst-last `RID && RLAST` scopes need an
owned parity audit before contract selection or implementation. `.297` now
selects `.298`, public contract selection for bounded multiple mixed
dynamic/static read single-beat `RID` response-demux, leaving burst-last
`RID && RLAST`, read-data, burst-length/runtime validation, multi-beat output
banks, broader mixed cardinalities, same-cycle widening, queues/scoreboards,
backend variants, and VHDL as later exact owners. `.298` now selects `.299`,
direct generated behavior for exactly one dynamic plus two concrete static
read transactions under existing `response-demux.read` syntax with
`response-scope single-beat`, candidate report mode
`bounded_multi_mixed_dynamic_static_read_rid_demux_contract`, and list-shaped
static-ID reservation fields. `.299` now ships that bounded multiple mixed
read behavior through support-accounted public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif`.
The generated behavior emits dynamic selected-ID/busy state, per-static busy
state, dynamic capture exclusions for static IDs `4'd3` and `4'd5`, onehot0
request assertions across all selected read transactions, three raw
single-beat `RID` completion pulses, pairwise unique-match assertions, and
list-shaped report fields while preserving the `.276` one-dynamic plus
one-static read report contract. `.299` selected `.300`, the next exact IAL2
feature-completeness selector after widened mixed read single-beat behavior.
`.300` now selects `.301`, readiness audit for multiple mixed dynamic/static
read burst-last `RID && RLAST` response-demux, because read-data,
burst-length/runtime validation, and multi-beat output-bank widening over the
multi-static mixed read shape should wait until final-beat completion semantics
are audited. `.301` now selects `.302`, public contract selection for bounded
multiple mixed dynamic/static read burst-last `RID && RLAST` response-demux,
after a guarded temporary candidate confirmed the current fail-closed
diagnostic for the multi-static burst-last shape. `.302` now selects `.303`,
direct generated behavior for that bounded multiple mixed read burst-last
contract: exactly one dynamic read plus two pairwise-distinct concrete static
reads under existing `response-demux.read` syntax with `response-scope
burst-last`, one-bit `last-signal`, mode
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`,
completion source `generated_multi_mixed_dynamic_static_read_demux_last_beat`,
list-shaped mixed/static-ID reservation fields, raw `RID` ownership
assertions, and final `RID && RLAST` completion pulses for `r0`, `r1`, and
`r2`. `.303` now ships that bounded multiple mixed read burst-last behavior
through support-accounted public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif`.
The generated behavior emits dynamic selected-ID/busy state, per-static busy
state, dynamic capture exclusions for static IDs `4'd3` and `4'd5`, onehot0
request assertions across all selected read transactions, three final-beat
`RID && RLAST` completion pulses, pairwise raw `RID` unique-match assertions,
and list-shaped report fields while preserving the `.276`, `.280`, and `.299`
public report contracts. `.303` selected `.304`, the next exact IAL2
feature-completeness selector after widened mixed read burst-last behavior.
`.304` now selects `.305`, readiness audit for bounded scalar read-data over
generated multiple mixed dynamic/static read response-demux, because `.299`
and `.303` now provide the single-beat and burst-last generated completion
pulses that scalar `RDATA`/`RRESP` capture would consume. The audit must
settle candidate sample stems, completion-validity vocabulary,
dynamic-then-static transaction coverage, diagnostics, validation strategy,
rollback, and residue before raw `ARLEN`, runtime validation, multi-beat
output banks, broader cardinalities, same-cycle widening, queues/scoreboards,
backend variants, or VHDL widen. `.305` now selects `.306`, public contract
selection for bounded scalar read-data over generated multiple mixed
dynamic/static read response-demux, after finding that the scalar read-data
normalization/capture path can already handle arbitrary covered transaction
counts but the current mixed dynamic/static coverage branch only admits the
one-dynamic plus one-static completion sources. `.306` now selects `.307`,
direct generated behavior for that bounded scalar read-data contract over
generated multiple mixed dynamic/static read response-demux. The selected
samples are
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_read_data.ppif`
and
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data.ppif`;
the contract uses dynamic-then-static transaction coverage `r0, r1, r2` and
completion-validity strings
`generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse`
and
`generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse`.
`.307` now ships that generated bounded scalar read-data behavior through the
two support-accounted public samples. The generated behavior emits shared
`axi0_rdata`/`axi0_rresp` inputs, scalar data/status outputs for `r0`, `r1`,
and `r2`, one read-data capture rule per transaction guarded only by the
generated multiple mixed demux completion pulse, and report entries that bind
the ordered dynamic-then-static transaction set to the new completion-validity
strings while keeping raw `ARLEN`, runtime validation, multi-beat output
banks, broader cardinalities, same-cycle widening, queues/scoreboards,
backend variants, and VHDL deferred. `.307` selected `.308`, the next exact
IAL2 feature-completeness selector after widened multiple mixed read-data
behavior.
`.308` now selects `.309`, readiness audit for generated report-only
raw-`ARLEN` burst-length capture over generated multiple mixed dynamic/static
read burst-last response-demux and scalar last-beat read-data. The selector
changes no behavior; it chooses the audit because runtime validation and
multi-beat output banks over the multiple mixed shape depend on first settling
request-time raw-`ARLEN` capture for the dynamic transaction and both concrete
static transactions.
`.309` selected `.310`, direct bounded implementation of report-only
raw-`ARLEN` burst-length capture over generated multiple mixed dynamic/static
read burst-last response-demux and scalar last-beat read-data. `.310` now
ships that generated behavior through the support-accounted public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_burst_length.ppif`;
the generated IAL1 adds `axi0_arlen`, raw request-time storage
`axi0_r0_arlen_q`, `axi0_r1_arlen_q`, and `axi0_r2_arlen_q`, request-guarded
burst-length capture rules for `r0`, `r1`, and `r2`, report artifact lists,
and scalar last-beat payload capture still guarded only by generated multiple
mixed `RID && RLAST` completion pulses. `.310` selected `.311`, readiness
audit for generated runtime beat-count/`RLAST` validation over the same
multiple mixed raw-`ARLEN` boundary. Runtime validation, multi-beat output
banks, broader cardinalities, same-cycle widening, queues/scoreboards,
backend variants, and VHDL remain deferred.
`.311` now selects `.312`, direct bounded implementation of runtime
beat-count/`RLAST` validation over generated multiple mixed dynamic/static
raw-`ARLEN` last-beat read-data. The audit changes no behavior; it finds that
the existing runtime-validation machinery is already transaction-list driven
across `r0`, `r1`, and `r2` once the multiple mixed last-beat coverage branch
admits `validation runtime-assertion`. The selected public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_burst_length_runtime_assertion.ppif`;
multi-beat output banks, broader cardinalities, same-cycle widening,
queues/scoreboards, backend variants, and VHDL remain deferred.
`.312` now ships that runtime-validation behavior. FSMGen emits generated
`axi0_r0_expected_beats_q`, `axi0_r1_expected_beats_q`, and
`axi0_r2_expected_beats_q`, generated `axi0_r0_read_beat_count_q`,
`axi0_r1_read_beat_count_q`, and `axi0_r2_read_beat_count_q`, request-time
beat-count initialization, raw matched-read-beat increment rules, and four
runtime assertions per covered transaction. The public sample reports twelve
generated beat-count assertions and removes `generated_beat_count_validation`
from read-data residue while keeping scalar last-beat `RDATA`/`RRESP` capture
guarded by generated multiple mixed `RID && RLAST` completion pulses.
Multi-beat output banks, broader cardinalities, same-cycle widening,
queues/scoreboards, backend variants, and VHDL remain deferred.
`.312` selected `.313`, readiness audit for generated multiple mixed
dynamic/static multi-beat output banks over this runtime-validation boundary.
`.313` now selects `.314`, direct bounded implementation of generated
multiple mixed dynamic/static multi-beat output banks over that boundary. The
audit changes no behavior; it finds that `.312` already proves the required
runtime source shape for `r0`, `r1`, and `r2`, while `.291` and `.268`
already ship the public multi-beat syntax and report vocabulary. The selected
sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_multi_beat.ppif`;
the implementation should also add multiple mixed multi-beat residue
recognition so the sample reports empty read-data residue and only
same-ID-ordering response-demux residue.
`.314` now ships that generated multi-beat behavior through the
support-accounted public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_multi_beat.ppif`.
The sample emits 48 generated `RDATA` lane outputs, 48 generated `RRESP` lane
outputs, three valid masks, three length outputs, three scalar
worst-observed `RRESP` aggregate outputs, per-lane capture rules,
output-bank init rules, raw `ARLEN` storage, expected-beat storage,
read-beat counters, and twelve runtime assertions for `r0`, `r1`, and `r2`.
Reports use `bounded_multi_beat_read_data_contract`, leave `read_data.residue`
empty, and leave response-demux residue limited to `same_id_ordering`.
`.314` selected `.315`, the next exact-owner selector after multiple mixed
dynamic/static read-data reached multi-beat output banks.
`.315` now selects `.316`, readiness audit for broader mixed dynamic/static
transaction cardinality after the one-dynamic plus one- or two-static mixed
read-data chain reached multi-beat output banks. The selector changes no
behavior and does not choose a public sample yet; the audit must decide
whether the next owner should directly widen a bounded shape such as two
dynamic plus one static or one dynamic plus three static, first select a
public source/report contract for a capped mixed set, land helper/report
cleanup, or defer in favor of same-cycle, queue, scoreboard, backend, or VHDL
work.
`.316` now selects `.317`, public contract selection for the first broader
mixed dynamic/static transaction-cardinality shape. The audit changes no
behavior; it finds that mixed demux admission, mixed demux construction,
read burst-last normalization, read-data coverage, and multi-beat residue
predicates all still encode the exact one-dynamic plus one- or two-static
boundary, so the next owner must choose the first public broader shape,
report vocabulary, diagnostics, support-accounting stem, and validation
strategy before implementation.
`.317` now selects `.318`, direct generated behavior for bounded one-dynamic
plus three-concrete-static write `BID` response-demux. The contract selection
changes no behavior; it reuses the existing
`bounded_multi_mixed_dynamic_static_write_bid_demux_contract` report mode and
chooses public sample stem
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static3.ppif`.
`.318` now ships that sample and generated write behavior while preserving the
existing report mode. Mixed dynamic/static write response-demux is now bounded
to one dynamic plus one, two, or three concrete static write transactions;
`.319` now selects `.320`, readiness audit for bounded one-dynamic plus
three-concrete-static mixed dynamic/static read response-demux. The selector
changes no behavior and starts from the read single-beat `RID` boundary before
burst-last, read-data, two-dynamic-plus-static, general capped mixed sets,
same-cycle, queue/scoreboard, backend, and VHDL work.
`.320` now selects `.321`, public contract selection for bounded one-dynamic
plus three-concrete-static mixed dynamic/static read single-beat `RID`
response-demux. The audit changes no behavior; it finds the report/assertion
surface is list-shaped enough for contract selection, but read admission,
burst-last normalization, and read-data coverage still enforce one dynamic
plus one or two static reads.
`.321` now selects `.322`, direct generated behavior for bounded one-dynamic
plus three-concrete-static mixed dynamic/static read single-beat `RID`
response-demux. The selector changes no behavior and reuses existing
`response-demux.read` syntax, public sample stem
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3.ppif`,
and report mode `bounded_multi_mixed_dynamic_static_read_rid_demux_contract`.
`.322` now ships that public sample and generated read single-beat behavior.
Mixed dynamic/static read single-beat response-demux accepts exactly one
dynamic read transaction plus one, two, or three pairwise-distinct concrete
static read transactions, emits generated completion pulses/rules for the
full covered set, records list-shaped static ID reservations/exclusions, and
keeps the existing multi-mixed read report mode. Burst-last and read-data over
the three-static read boundary remain fail-closed. `.323` is the next
exact-owner selector after the three-static mixed read single-beat demux.
`.323` now selects `.324`, readiness audit for bounded one-dynamic plus
three-concrete-static mixed dynamic/static read burst-last `RID && RLAST`
response-demux. The selector changes no behavior and keeps read-data over the
three-static boundary behind final-beat completion semantics.
`.324` now selects `.325`, public contract selection for bounded one-dynamic
plus three-concrete-static mixed dynamic/static read burst-last `RID && RLAST`
response-demux. The audit changes no behavior and keeps the three-static
burst-last behavior, read-data, burst-length/runtime validation, and
multi-beat output banks behind future exact owners.
`.325` now selects `.326`, direct generated behavior for bounded one-dynamic
plus three-concrete-static mixed dynamic/static read burst-last `RID && RLAST`
response-demux. The selector changes no behavior and locks the public sample,
support identity, report vocabulary, diagnostics, validation gates, and
residue for the implementation owner.
`.326` now ships generated one-dynamic plus three-concrete-static mixed
dynamic/static read burst-last `RID && RLAST` response-demux through
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif`.
The generated report reuses
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract` with
list-shaped dynamic/static transactions, static ID reservations/exclusions
for `4'd3`, `4'd5`, and `4'd7`, raw `RID` active/unique assertions, and final
`RID && RLAST` completion pulses for `r0` through `r3`. Read-data over the
three-static boundary remains deferred.
`.327` now selects `.328`, readiness audit for bounded scalar read-data over
generated one-dynamic plus three-concrete-static mixed dynamic/static read
response-demux. The selector changes no behavior and keeps raw `ARLEN`,
runtime validation, multi-beat output banks, broader mixed cardinalities,
same-cycle widening, queues/scoreboards, backend variants, and VHDL behind
future exact owners.
`.328` now selects `.329`, public contract selection for bounded scalar
read-data over generated one-dynamic plus three-concrete-static mixed
dynamic/static read response-demux. The audit changes no behavior; the
implementation substrate is list-shaped after coverage admission, but public
source/report naming, support accounting, diagnostics, validation, and
residue need a contract-selection owner before behavior changes.
`.329` now selects `.330`, direct generated behavior for bounded scalar
read-data over generated one-dynamic plus three-concrete-static mixed
dynamic/static read response-demux. The selector changes no behavior and
keeps three-static `burst_length`, runtime beat-count/`RLAST` validation,
multi-beat output banks, broader mixed cardinalities, same-cycle widening,
queues/scoreboards, backend variants, and VHDL behind future exact owners.
`.330` now ships generated scalar read-data over that boundary. The public
single-beat and last-beat samples generate scalar `RDATA`/`RRESP` capture
for `r0`, `r1`, `r2`, and `r3`, report the existing multi-mixed read demux
contract modes, and bind read-data completion validity to the generated
single-beat or last-beat response-demux completion pulses. Three-static raw
`ARLEN`, runtime beat-count/`RLAST` validation, and multi-beat output banks
remain future exact owners. `.331` now selects `.332`, readiness audit for
report-only raw-`ARLEN` burst-length capture over generated one-dynamic plus
three-concrete-static mixed dynamic/static read burst-last response-demux and
scalar last-beat read-data. The selector changes no behavior and keeps
runtime validation, multi-beat output banks, two-dynamic-plus-static shapes,
broader cardinalities, same-cycle widening, queues/scoreboards, backend
variants, and VHDL behind later exact owners.
`.332` now selects `.333`, direct bounded implementation of report-only
raw-`ARLEN` burst-length capture over that same generated three-static
last-beat read-data boundary. The audit changes no behavior; the public
`burst-length` syntax and transaction-list driven raw-`ARLEN` storage,
capture-rule, and report helpers are already ready once coverage admits the
`r0`, `r1`, `r2`, `r3` transaction set. Three-static runtime validation and
multi-beat output banks remain deferred.
`.333` now ships that behavior. The support-accounted public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_burst_length.ppif`
generates width-8 `axi0_arlen`, raw-`ARLEN` storage and request capture rules
for `r0`, `r1`, `r2`, and `r3`, and scalar last-beat `RDATA`/`RRESP` capture
still guarded by generated mixed `RID && RLAST` completion pulses. Reports
mark `burst_length_validation` as `report_only`, list generated
burst-length input/storage/rules, and keep runtime beat-count/`RLAST`
validation and multi-beat output banks fail-closed. `.334` now audits runtime
validation readiness over this three-static raw-`ARLEN` boundary.
`.334` now selects `.335`, direct bounded implementation of runtime
beat-count/`RLAST` validation over the same three-static raw-`ARLEN`
last-beat read-data boundary. The audit changes no behavior; runtime
validation syntax/report vocabulary, expected-beat storage, beat-count
storage, beat-count rules, assertions, and residue movement are already
transaction-list driven after coverage admits the `r0`, `r1`, `r2`, `r3`
transaction set. Three-static multi-beat output banks remain fail-closed.
`.335` now ships that behavior. The support-accounted public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_burst_length_runtime_assertion.ppif`
generates raw-`ARLEN`, expected-beat, and read-beat-count storage for `r0`,
`r1`, `r2`, and `r3`; request-time expected-count initialization;
matched-read-beat counter increments; and four runtime assertions per
covered transaction. Reports mark `beat_count_validation_generated_behavior`
true and remove generated beat-count validation from residue while keeping
multi-beat output banks deferred. `.336` now audits multi-beat output-bank
readiness over this three-static runtime boundary.
`.336` now selects `.337`, direct bounded implementation of generated
multi-beat output banks over that same one-dynamic plus three-concrete-static
mixed dynamic/static runtime-validation read-data boundary. The audit changes
no behavior; public multi-beat syntax, output-bank report vocabulary,
runtime-assertion `ARLEN` metadata, and transaction-list-driven output-bank
helpers are already present. The remaining implementation gap is local to
three-static multi-beat coverage admission, response-demux residue
recognition, support publication, and focused assertions. Two-dynamic-plus
static shapes, broader mixed cardinalities, queues/scoreboards, backend
variants, and VHDL remain deferred.
`.337` now ships generated multi-beat output banks over that same
one-dynamic plus three-concrete-static runtime-validation boundary through
support-accounted public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_multi_beat.ppif`.
The sample emits per-transaction output banks for `r0`, `r1`, `r2`, and
`r3`, including 64 generated `RDATA` lanes, 64 generated `RRESP` lanes,
valid masks, length outputs, scalar worst-observed `RRESP` aggregates,
raw-`ARLEN` storage, expected-beat storage, beat counters, lane capture,
aggregate update, and sixteen runtime beat-count/`RLAST` assertions.
Reports mark read-data residue empty and keep response-demux residue limited
to `same_id_ordering`. Two-dynamic-plus-static shapes, broader mixed
cardinalities, same-cycle widening, queues/scoreboards, backend variants,
and VHDL remain deferred.
`.338` now selects `.339`, readiness audit for two-dynamic-plus-one-static
mixed dynamic/static write `BID` response-demux. The selector changes no
behavior and starts at write response-demux because it is the smallest
behavior-bearing boundary before read response-demux, read-data,
burst-length/runtime validation, or multi-beat output-bank widening can
depend on a combined multiple-dynamic-plus-static policy.
`.339` now selects `.340`, public contract selection for that
two-dynamic-plus-one-static mixed write `BID` response-demux boundary. The
audit changes no behavior; current mixed write admission and constructors
still require exactly one dynamic write transaction plus one, two, or three
concrete static write transactions, while the two-dynamic-plus-static shape
needs an owned public report/assertion contract that combines multi-dynamic
active selected-ID uniqueness with static concrete-ID reservations and
dynamic-vs-static exclusions.
`.340` now selects `.341`, direct generated behavior for bounded
two-dynamic-plus-one-static mixed dynamic/static write `BID` response-demux.
The selector changes no behavior. It chooses public sample stem
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif`,
support identity
`intent.ppif_axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic`,
focused behavior label `mixed_dynamic_static_write_demux_multi_dynamic`,
dynamic write transactions `w0`/`w1`, static write transaction `w2` with ID
`3`, the existing `bounded_multi_mixed_dynamic_static_write_bid_demux_contract`
report mode, `onehot0_mixed_write_request`, active dynamic selected-ID
uniqueness, static concrete-ID reservation/exclusion, and mixed response
active/unique assertion roles.
`.341` now ships that generated behavior through the support-accounted public
sample
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif`.
Mixed dynamic/static write response-demux now accepts exactly two dynamic
write transactions plus one concrete static write transaction, emits selected
dynamic ID/busy state for `w0`/`w1`, static busy state for `w2`, onehot0
mixed request assertions, per-dynamic request no-active-same-ID checks,
pairwise active dynamic selected-ID uniqueness, static-ID reservation and
request/active exclusion for `4'd3`, three raw `BID` completion pulses, and
list-shaped report fields while preserving the `.272`, `.295`, and `.318`
mixed write report contracts.
`.342` now selects `.343`, public contract selection for bounded
two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID`
response-demux. The audit changes no behavior; mixed read admission and
construction remain singular on the dynamic side while the lower substrate is
close after `.341` write behavior and `.251` multiple all-dynamic read
behavior. `.343` must settle the public sample stem, support identity,
behavior label, transaction order, static concrete ID, report mode,
completion source, `active_dynamic_ids_must_be_unique`, static-ID exclusions,
assertion names, diagnostics, validation, residue, rollback, and next
frontier before any parser, generator, PPIF sample, support-accounting, test,
JSON, or HDL behavior changes.
`.343` now selects `.344`, direct generated behavior for that bounded
two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID`
response-demux contract. The selector changes no behavior. It chooses public
sample stem
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif`,
support identity
`intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic`,
focused behavior label `mixed_dynamic_static_read_demux_multi_dynamic`,
dynamic read transactions `r0`/`r1`, static read transaction `r2` with ID
`3`, existing report mode
`bounded_multi_mixed_dynamic_static_read_rid_demux_contract`, completion
source `generated_multi_mixed_dynamic_static_read_demux`,
`onehot0_mixed_read_request`, active dynamic selected-ID uniqueness, static
concrete-ID reservation/exclusion, and raw `RID` response active/unique
assertion roles.
`.344` now ships that generated behavior through the support-accounted public
sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif`.
Mixed dynamic/static read single-beat response-demux now accepts exactly two
dynamic read transactions plus one concrete static read transaction, emits
selected dynamic ID/busy state for `r0`/`r1`, static busy state for `r2`,
onehot0 mixed request assertions, per-dynamic request no-active-same-ID
checks, pairwise active dynamic selected-ID uniqueness, static-ID reservation
and request/active exclusion for `4'd3`, three raw `RID` completion pulses,
and list-shaped report fields while preserving the `.276`, `.299`, and
`.322` mixed read single-beat report contracts.
`.345` now selects `.346`, public contract selection for bounded
two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID`/`RLAST`
response-demux. The audit changes no behavior. A scratch guarded strict-check
probe confirmed the current burst-last mixed dynamic/static boundary still
fails closed for this shape, while the lower substrate is close after `.344`
single-beat behavior and the `.303`/`.326` mixed burst-last patterns. `.346`
must settle the public sample stem, support identity, behavior label, last
signal policy, report mode
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`,
completion source `generated_multi_mixed_dynamic_static_read_demux_last_beat`,
raw `RID` beat ownership assertions, final `RID && RLAST` completions,
diagnostics, validation, residue, rollback, and next frontier before any
parser, generator, PPIF sample, support-accounting, test, JSON, or HDL
behavior changes.
`.346` now selects `.347`, direct generated behavior for that bounded
two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID`/`RLAST`
response-demux contract. The selector changes no behavior. It chooses public
sample stem
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last.ppif`,
support identity
`intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last`,
focused behavior label `mixed_dynamic_static_read_rlast_demux_multi_dynamic`,
dynamic read transactions `r0`/`r1`, static read transaction `r2` with ID
`3`, one-bit last signal `axi0_rlast`, report mode
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`,
completion source `generated_multi_mixed_dynamic_static_read_demux_last_beat`,
raw `RID` beat ownership assertions independent of `RLAST`, final
`RID && RLAST` generated completions, and explicit read-data, raw `ARLEN`,
runtime-validation, and multi-beat residue.
`.347` now ships that generated behavior through the support-accounted public
sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last.ppif`.
It accepts exactly two dynamic read transactions plus one concrete static read
transaction under `response-scope burst-last`, emits selected dynamic ID/busy
state for `r0`/`r1`, static busy state for `r2`, raw `RID` active/unique
response assertions independent of `RLAST`, and final `RID && RLAST` generated
completion pulses. Read-data, raw `ARLEN`, runtime-validation, and multi-beat
behavior over this shape remain explicit residue.
`.348` now selects `.349`, public contract selection for scalar last-beat
read-data over that generated two-dynamic-plus-one-static mixed dynamic/static
read burst-last `RID`/`RLAST` response-demux. The audit changes no behavior. A
scratch RAM-guarded strict-check probe reached the read-data coverage gate and
failed closed with the current one-dynamic plus two-static/three-static
diagnostic. `.349` must settle the public sample stem
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data.ppif`,
support identity
`intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data`,
focused behavior label `mixed_dynamic_static_read_data_multi_dynamic_last_beat`,
scalar output names, completion-validity vocabulary, validation, rollback, and
raw `ARLEN`/runtime/multi-beat residue before implementation.
`.349` now selects `.350`, direct generated behavior for scalar last-beat
read-data over that generated two-dynamic-plus-one-static mixed dynamic/static
read burst-last `RID`/`RLAST` response-demux. The selector changes no behavior.
It fixes public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data.ppif`,
support identity
`intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data`,
coverage key
`ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_pipeline_cli`,
behavior label `mixed_dynamic_static_read_data_multi_dynamic_last_beat`,
completion validity
`generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse`,
and exact fail-closed residue for the single-beat sibling, raw `ARLEN`, runtime
validation, multi-beat output banks, broader cardinalities, and backend
variants.
`.350` now ships that selected scalar last-beat read-data behavior through the
support-accounted public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data.ppif`.
It preserves the `.347` burst-last response-demux contract for dynamic
transactions `r0`/`r1` and static transaction `r2`, adds generated
`axi0_rdata`/`axi0_rresp` inputs plus `r0`/`r1`/`r2`
`last_rdata`/`last_rresp` outputs, and captures payload/status under the
generated final-beat completion pulses. The read-data report names
`bounded_last_beat_read_data_contract`,
`generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse`,
transactions `r0`, `r1`, `r2`, and capture rules
`axi0_r0_read_data_capture`, `axi0_r1_read_data_capture`, and
`axi0_r2_read_data_capture`. Raw `ARLEN`, runtime validation, multi-beat output
banks, broader cardinalities, the single-beat `.344` read-data sibling, and
backend variants remain future exact owners; `.351` selects the report-only
raw-`ARLEN` burst-length readiness boundary next.
`.351` now selects `.352`, readiness audit for report-only raw-`ARLEN`
burst-length capture over the shipped two-dynamic-plus-one-static mixed
dynamic/static scalar last-beat read-data boundary. The selector changes no
behavior. `.352` must decide whether the `.350` public sample should grow the
existing `burst-length` syntax directly, needs public contract selection first,
needs helper/report cleanup first, or should defer behind another prerequisite.
Runtime validation, multi-beat output banks, broader cardinalities, direct
backend behavior, backend-language variants, and VHDL remain separate owners.
`.352` now selects `.353`, direct implementation of report-only raw-`ARLEN`
burst-length capture over that generated two-dynamic-plus-one-static mixed
dynamic/static scalar last-beat read-data boundary. The audit changes no
behavior. Code review found the current coverage gate already admits the `.350`
shape only when `burst_length` is absent, while raw-`ARLEN` normalization,
storage, rule, artifact, and report helpers are transaction-list driven once
coverage admits the transaction set. `.353` owns the new public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length.ppif`,
support identity, coverage key, behavior label, generated `axi0_arlen`, and
per-transaction raw-`ARLEN` storage/capture rules while runtime validation,
multi-beat output banks, broader cardinalities, direct backend behavior,
backend-language variants, and VHDL remain separate owners.
`.353` now ships that selected report-only raw-`ARLEN` burst-length capture
through the support-accounted public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length.ppif`.
It preserves the `.350` scalar last-beat payload capture and `.347` final
`RID && RLAST` generated completions, adds generated input `axi0_arlen`,
per-transaction raw-`ARLEN` storage for `r0`, `r1`, and `r2`, and
request-guarded capture rules for all three transactions. The report names
validation mode `report_only` with runtime beat-count/`RLAST` validation still
residue. `.353` advanced the frontier to `.354`, the readiness audit for
runtime validation over this two-dynamic-plus-one-static raw-`ARLEN` boundary.
`.354` now selects `.355`, direct implementation of runtime
beat-count/`RLAST` validation over that generated two-dynamic-plus-one-static
mixed dynamic/static raw-`ARLEN` scalar last-beat read-data boundary. The audit
changes no behavior. The existing helpers already derive expected-beat storage,
read-beat counters, request-time initialization, raw matched-read-beat
increments, beat-count/`RLAST` assertions, and runtime report fields from the
covered transaction list once the exact two-dynamic-plus-one-static runtime
shape is admitted. `.355` owns the runtime sibling sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length_runtime_assertion.ppif`,
support identity, coverage key, and focused behavior label while preserving
two-dynamic-plus-one-static multi-beat output banks, broader cardinalities,
direct backend behavior, backend-language variants, and VHDL as separate
owners.
`.355` now ships that selected runtime beat-count/`RLAST` validation through
the support-accounted public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length_runtime_assertion.ppif`.
The generated surface preserves `.353` raw-`ARLEN` capture, `.350` scalar
last-beat `RDATA`/`RRESP` capture, and `.347` final `RID && RLAST`
completion pulses. It adds per-transaction expected-beat storage,
read-beat counters, request-time initialization from `ARLEN + 1`,
matched-read-beat counter increments, and four beat-count/`RLAST` assertions
for `r0`, `r1`, and `r2`. Reports name `runtime_assertion`,
`beat_count_validation_generated_behavior`, `arlen_plus_one`, and
`response_demux_matched_read_beat` for this exact scalar last-beat shape.
`.355` advanced the frontier to `.356`, readiness audit for
two-dynamic-plus-one-static multi-beat output banks over this runtime boundary.
`.356` now selects `.357`, direct implementation of generated multi-beat
output banks over that two-dynamic-plus-one-static runtime-validation
boundary. The audit changes no behavior. The direct candidate currently fails
only at the local multiple mixed dynamic/static read-data transaction-set
admission diagnostic; the public multi-beat syntax, output-bank report
vocabulary, runtime ARLEN validation, transaction-list-driven output-bank
helpers, and support/testing precedents are already present. `.357` owns the
public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_multi_beat.ppif`,
support identity, coverage key, focused behavior label, diagnostics,
validation, rollback, and residue.
`.357` now ships that selected generated multi-beat output-bank behavior
through the support-accounted public sample. The generated surface preserves
runtime beat-count/`RLAST` validation, raw `ARLEN` capture, and generated
final `RID && RLAST` completion pulses, then emits per-transaction `RDATA`
and `RRESP` lane outputs, valid masks, read-length outputs, and
worst-observed scalar `RRESP` aggregates for `r0`, `r1`, and `r2`. Reports
identify the shape as `bounded_multi_beat_read_data_contract`, set generated
status aggregation and multi-beat reassembly behavior, keep read-data residue
empty, and leave only `same_id_ordering` in response-demux residue. `.357`
advanced the frontier to `.358`, the next IAL2 feature-completeness selector
after this read-data chain reached multi-beat output banks.
`.358` now selects `.359`, readiness audit for scalar single-beat read-data
over the `.344` generated two-dynamic-plus-one-static mixed dynamic/static
read single-beat `RID` response-demux. The selector changes no behavior. It
records candidate sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data.ppif`,
support identity, coverage key, focused behavior label, diagnostics,
validation, rollback, and residue while preserving broader cardinalities,
same-cycle behavior, queues/scoreboards, backend variants, VHDL, aliases,
queued/blocking policy, and full-manager behavior as separate owners.
`.359` now selects `.360`, public contract selection for that scalar
single-beat read-data shape. The audit changes no behavior. The selected
candidate surface keeps `.344` response-demux mode
`bounded_multi_mixed_dynamic_static_read_rid_demux_contract`, read-data mode
`bounded_single_beat_read_data_contract`, completion validity
`generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse`,
and the candidate sample/support/coverage/behavior names selected by `.358`.
`.360` now selects `.361`, direct generated behavior for bounded scalar
single-beat read-data over the `.344` generated two-dynamic-plus-one-static
mixed dynamic/static read single-beat `RID` response-demux. The selector
changes no behavior. The selected public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data.ppif`,
with support identity
`intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data`,
coverage key
`ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data_pipeline_cli`,
and behavior label `mixed_dynamic_static_read_data_multi_dynamic`. The
selected report contract keeps `.344` response-demux mode/source and
`bounded_single_beat_read_data_contract` with completion validity
`generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse`.
`.361` now ships that selected scalar single-beat read-data behavior through
the support-accounted public sample
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data.ppif`.
The read-data coverage predicate admits only
`generated_multi_mixed_dynamic_static_read_demux`, response scope
`single_beat`, capture scope `single-beat`, no `burst_length` metadata,
dynamic reads `r0`/`r1`, concrete static read `r2`, and one generated
completion pulse per covered transaction. The generated surface adds shared
`axi0_rdata`/`axi0_rresp` inputs, scalar data/status outputs for `r0`, `r1`,
and `r2`, and capture rules guarded by the generated single-beat completion
pulses. Reports keep the `.344` response-demux contract and mark read-data as
`bounded_single_beat_read_data_contract` with completion validity
`generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse`.
Burst-last/last-beat siblings, raw `ARLEN`, runtime validation, multi-beat
output banks, broader mixed cardinalities, queues, scoreboards, backend
variants, VHDL, profile aliases, queued/blocking policy, and full-manager
behavior remain future exact-owner work.
`.362` now selects `.363`, readiness audit for same-cycle request/response
and release-and-recapture behavior across the generated dynamic and mixed
dynamic/static response-demux/read-data shapes. The selector changes no
behavior. The selected audit must read the shipped dynamic/mixed chains,
current onehot0 request policy, active dynamic selected-ID uniqueness,
request no-active-same-ID checks, static busy release, capacity accounting,
generated assertion helpers, and scheduler conflict assumptions before any
request-plus-completion or release-and-recapture behavior changes.
`.363` now selects `.364`, public contract selection for the first
single-active dynamic write `BID` same-cycle release-and-recapture boundary.
The audit found capacity admission already accepts same-cycle completion
fan-in, while response-demux capture still requires `!busy` and release uses
a separate generated completion rule. Single-active dynamic write recapture is
the smallest next contract owner before static recapture, sibling onehot0
request widening, read `RID`/`RLAST`, read-data payload behavior, queues,
scoreboards, backend variants, or VHDL work.
`.365` now ships direct generated behavior for single-active dynamic write
`BID` same-cycle release-and-recapture. The behavior reuses the existing public
dynamic write response-demux sample and source syntax, keeps
`bounded_dynamic_write_bid_demux_contract`, adds
`same_cycle_release_recapture_policy` report vocabulary, emits
`axi0_w0_dynamic_id_release_recapture`, changes release-only to exclude a
same-cycle request, and replaces the request-not-busy assertion with
`axi0_w0_dynamic_request_idle_or_releasing`. A same-cycle request plus generated
matching completion now pulses completion, captures the new `AWID`, and keeps
busy asserted using the pre-update selected ID for the response match.
That behavior advanced the frontier to `.366`, the next selector for
same-cycle and release-recapture residue after the single-active dynamic write
boundary.
`.366` now selects `.367`, public contract selection for first single-active
dynamic read same-cycle release-and-recapture. The selector changes no
behavior. Single-active dynamic read is the closest symmetric sibling because
the current single-beat `RID` and burst-last `RID && RLAST` paths share
selected-ID/busy ownership with the dynamic write path but still report
request-not-busy. The contract owner must settle whether the first behavior
slice covers only single-beat `RID`, includes burst-last `RID && RLAST`, or
splits those scopes, and must preserve existing dynamic read-data
completion-pulse consumers before implementation.
`.367` now selects `.368`, direct generated behavior for single-active dynamic
read single-beat `RID` same-cycle release-and-recapture. The selector changes
no behavior. The selected contract reuses the existing dynamic read
response-demux public sample/source syntax, keeps
`bounded_dynamic_read_rid_demux_contract`, adds read-side
`same_cycle_release_recapture_policy` report vocabulary, and replaces the
single-active dynamic read request-not-busy assertion role with
idle-or-releasing semantics. Burst-last `RID && RLAST`, scalar last-beat
read-data, burst-length/runtime/multi-beat recapture, multiple dynamic,
mixed dynamic/static, static busy, queue, scoreboard, backend variants, VHDL,
and full-manager behavior remain later owners.
`.368` now ships generated single-active dynamic read single-beat `RID`
same-cycle release-and-recapture under the existing public sample/source
syntax. FSMGen emits `axi0_r0_dynamic_id_release_recapture`, keeps release-only
disjoint from same-cycle requests, reports
`same_cycle_release_recapture_policy: single_active_dynamic_read`, replaces the
single-active request-not-busy assertion with
`axi0_r0_dynamic_request_idle_or_releasing`, and preserves scalar single-beat
dynamic read-data capture under the generated completion pulse. Burst-last
`RID && RLAST`, scalar last-beat read-data, burst-length/runtime/multi-beat
recapture, multiple dynamic, mixed dynamic/static, static busy, queue,
scoreboard, backend variants, VHDL, and full-manager behavior remain later
owners.
`.369` now selects `.370`, readiness audit for single-active dynamic read
burst-last `RID && RLAST` same-cycle release-and-recapture. The selector
changes no behavior. It chooses audit before direct implementation because the
burst-last boundary touches final-beat completion, matched non-last beats, raw
active-match assertions, scalar last-beat read-data, report-only raw-`ARLEN`,
runtime beat-count/`RLAST`, and multi-beat output-bank consumers.
Multiple dynamic request widening, mixed dynamic/static recapture, static busy
recapture, same-ID queues, scoreboards, backend variants, VHDL, and
full-manager behavior remain later owners.
`.370` now selects `.371`, public contract selection for single-active dynamic
read burst-last `RID && RLAST` same-cycle release-and-recapture. The audit
changes no behavior and found no lower cleanup prerequisite, but contract
selection must precede implementation because final-completion-only recapture,
matched non-last beats, raw active-match assertions, scalar last-beat
read-data preservation, raw-`ARLEN`/runtime/multi-beat consumer boundaries,
report vocabulary, and assertion semantics need exact public ownership before
generator behavior changes.
`.371` now selects `.372`, direct generated behavior for single-active dynamic
read burst-last `RID && RLAST` same-cycle release-and-recapture. The selector
changes no behavior. The selected contract reuses the existing burst-last
dynamic read response-demux source syntax and support identity, preserves
`bounded_dynamic_read_rid_rlast_demux_contract`, reports
`release_recapture_source: generated_dynamic_demux_last_beat_completion`,
replaces the single-active burst-last request-not-busy assertion with
idle-or-releasing semantics, preserves raw matched non-last beats and raw
active-match assertions, and treats scalar last-beat read-data, raw-`ARLEN`,
runtime beat-count/`RLAST`, and multi-beat output banks as payload/validation
preservation consumers.
`.372` now ships generated single-active dynamic read burst-last `RID && RLAST`
same-cycle release-and-recapture under the existing public sample/source
syntax. FSMGen emits `axi0_r0_dynamic_id_release_recapture`, keeps release-only
disjoint from same-cycle requests, reports
`release_recapture_source: generated_dynamic_demux_last_beat_completion`,
replaces the burst-last single-active request-not-busy assertion with
`axi0_r0_dynamic_request_idle_or_releasing`, preserves raw matched non-last
beats and raw active-match assertions, and keeps scalar last-beat read-data,
raw-`ARLEN`, runtime beat-count/`RLAST`, and multi-beat output-bank
payload/validation contracts intact. The frontier advances to `.373`, the next
same-cycle/release-recapture selector.
`.373` now selects `.374`, readiness audit for multiple all-dynamic
same-cycle release-and-recapture. The selector changes no behavior. Multiple
all-dynamic response-demux is the nearest broader recapture residue because it
still uses dynamic selected-ID/busy ownership, but it adds sibling onehot0
request policy, active dynamic selected-ID uniqueness, request
no-active-same-ID checks, unique-match assertions, and burst-last raw
non-final-beat handling. Mixed dynamic/static recapture, static busy recapture,
queues, scoreboards, backend variants, VHDL, and full-manager behavior remain
later owners.
`.374` now selects `.375`, generated support-detail prose alignment for the
shipped single-active dynamic read burst-last release-and-recapture behavior
before selecting any multiple-dynamic recapture contract. The audit changes no
behavior. Guarded probes confirmed the multiple dynamic write/read/read-RLAST
samples still report onehot0 request policy, active dynamic selected-ID
uniqueness, request no-active-same-ID checks, response unique-match assertions,
request-not-busy assertions, and no release-recapture fields. The same probes
exposed stale generated support prose saying the single-active dynamic read
burst-last `RID/RLAST` shape is supported without release-and-recapture and
listing same-cycle recapture as future outside only dynamic write plus read
single-beat.
`.375` now aligns that generated support-detail prose with shipped
single-active dynamic read burst-last release-and-recapture. The generated
dynamic transaction-ID support detail describes single-active dynamic read
single-beat `RID` matching and burst-last `RID/RLAST` matching as including
same-cycle release-and-recapture. At `.375`, same-cycle recapture remained
future only outside the selected single-active dynamic write `BID`, read
single-beat `RID`, and read burst-last `RID/RLAST` demux boundaries. Parser
syntax, PPIF samples, response-demux semantics, generated state/rules,
assertions, HDL, and runtime behavior are unchanged. The frontier advances to
`.376`, selection of the first multiple all-dynamic recapture contract owner.
`.376` now selects `.377`, public contract selection for multiple all-dynamic
write `BID` same-cycle release-and-recapture. The selector changes no
behavior. It starts on the write side because that shape exercises
multi-active dynamic selected-ID/busy ownership, onehot0 request policy,
active-ID uniqueness, request no-active-same-ID checks, response active-match,
response unique-match, and completion-active assertions without read-side
`RLAST`, raw non-final-beat, read-data, raw-`ARLEN`, runtime, or multi-beat
preservation coupling. That selector deliberately left read-side, mixed/static,
static busy, queue, scoreboard, backend-variant, VHDL, and full-manager
recapture behavior to later exact owners.
`.377` now selects `.378`, direct implementation of multiple all-dynamic write
`BID` same-cycle release-and-recapture for the existing
`ppif/axi_manager_capacity_status_dynamic_write_response_demux_multi.ppif`
sample. The contract preserves public syntax, support accounting,
`bounded_multi_dynamic_write_bid_demux_contract`, and onehot0 request policy;
adds per-transaction `release_recapture_rule`,
`same_cycle_release_recapture_policy: multi_active_unique_dynamic_write`,
`release_recapture_source: generated_dynamic_demux_completion`, and
`release_recapture_transaction` report fields; replaces per-transaction
request-not-busy assertions with idle-or-releasing assertions; and preserves
no-active-same-ID, active-ID uniqueness, response active/unique-match, and
completion-active assertions. The selector changes no behavior.
`.378` now ships that multiple all-dynamic write `BID` same-cycle
release-and-recapture behavior. FSMGen emits per-transaction
`axi0_w0_dynamic_id_release_recapture` and
`axi0_w1_dynamic_id_release_recapture`, keeps release-only updates disjoint
from same-cycle own requests, reports `same_cycle_release_recapture_policy:
multi_active_unique_dynamic_write`, replaces per-transaction request-not-busy
assertions with idle-or-releasing assertions, and preserves source syntax,
support identity, generated completion names,
`bounded_multi_dynamic_write_bid_demux_contract`, onehot0 request policy,
no-active-same-ID, active-ID uniqueness, response active/unique-match, and
completion-active assertions. `.379` now selects `.380`, public contract
selection for multiple all-dynamic read single-beat `RID` same-cycle
release-and-recapture. The selector changes no behavior. Single-beat read is
the next smallest multiple-dynamic recapture owner because it shares the
multi-active selected-ID/busy lifecycle and assertion structure without
`RLAST` final-beat, raw non-final beat, last-beat read-data, raw-`ARLEN`,
runtime, or multi-beat output-bank coupling. The `.380` contract selection must
settle report vocabulary, release-only and release-recapture guard semantics,
idle-or-releasing assertion replacement, scalar single-beat read-data
preservation, validation, rollback, and deferred burst-last boundaries before
implementation. At that point, multiple dynamic read burst-last recapture still
required a later exact owner; that burst-last work later shipped in `.385`, and
mixed dynamic/static recapture advanced through `.386`-`.388` to `.389` mixed
write implementation. Static busy-only recapture outside that selected
mixed write boundary, request arbitration beyond onehot0, queues, scoreboards,
backend variants, VHDL, and full-manager behavior remain later owners. `.380` now selects `.381`, direct implementation of
multiple all-dynamic read single-beat `RID` same-cycle release-and-recapture
for the existing multiple dynamic read response-demux sample. The selector
changes no behavior. The selected implementation must preserve public syntax,
support identity, `bounded_multi_dynamic_read_rid_demux_contract`, generated
demux rules, generated completions, onehot0 request policy, no-active-same-ID,
active-ID uniqueness, response active/unique-match, completion-active
assertions, and scalar single-beat read-data capture over generated completion
pulses while adding per-transaction `multi_active_unique_dynamic_read`
release-recapture report fields and idle-or-releasing request assertions.
`.381` now ships that same-cycle release-and-recapture behavior for the
existing multiple dynamic read response-demux sample. The generator emits
`axi0_r0_dynamic_id_release_recapture` and
`axi0_r1_dynamic_id_release_recapture`, reports
`same_cycle_release_recapture_policy: multi_active_unique_dynamic_read` under
`response_demux.read.dynamic_capture.transactions[]`, replaces the
per-transaction request-not-busy assertions with
idle-or-releasing assertions, and preserves
`bounded_multi_dynamic_read_rid_demux_contract`, onehot0 request policy,
no-active-same-ID, active-ID uniqueness, raw response active/unique-match,
completion-active assertions, generated completion names, support identity,
and scalar single-beat read-data capture over generated completions. Multiple
dynamic read burst-last recapture then advanced through `.382`-`.385`; mixed
dynamic/static recapture advanced through `.386`-`.388` to `.389` mixed write
implementation. Static busy-only recapture outside that selected mixed
write boundary, request arbitration beyond onehot0, queues, scoreboards,
backend variants, VHDL, and full-manager behavior remain later owners.
No behavior changed in
`.270`, `.271`, `.273`, `.274`, `.275`, `.277`, `.278`,
`.279`, `.281`, `.282`, `.283`, `.285`, `.286`, `.288`, `.290`, `.292`, or
`.293`, `.294`, `.296`, `.297`, `.298`, `.300`, `.301`, `.302`, `.304`,
`.305`, `.306`, `.308`, `.309`, `.311`, `.313`, `.315`, `.316`, `.317`, or
`.319`, `.320`, `.321`, `.323`, `.324`, `.325`, `.327`, `.328`, `.329`,
`.331`, `.332`, `.334`, `.336`, `.338`, `.339`, `.340`, `.342`, `.343`,
`.345`, `.346`, `.348`, `.349`, `.351`, `.352`, `.354`, `.356`, `.358`,
`.359`, `.360`, `.362`, `.363`, `.364`, `.366`, `.367`, `.369`, `.370`,
`.371`, `.373`, `.374`, `.376`, `.377`, `.379`, `.380`, `.382`, `.383`,
`.384`, `.386`, `.387`, or `.388`.
AXI-specific same-ID ordering stays profile vocabulary for now; common IAL2
factoring remains evidence-driven and should be promoted only when multiple
profiles need compatible semantics.
Verification-code generation is captured as a separate roadmap lane from the
synthesizable RTL/HDL feature-completeness path and is now task-tree owned by
`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER`. The selected starting stance is
IAL1 (`.isf`) to verification code. Audit `.2` found the shipped IAL1
assert/assume/cover/property/monitor surface sufficient for inline
SystemVerilog assertion projection but insufficient as the sole source
contract for first-class generated SV/UVM or VHDL-oriented verification
artifacts. Selector `.3` chose actor-level passive observation metadata,
`(observe NAME (role passive_monitor) (signals SIG...))`, as the first IAL1
verification-specific source feature. Implementation
`ISF-VERIFICATION-OBSERVATION-METADATA.1` shipped that metadata-only/report-only
source feature through parser validation, additive
`verification_observations[]` schedule JSON, public contract metadata,
supported-smoke coverage, and mdBook documentation before any output generator
was selected. Selector `.4` chose a passive UVM monitor skeleton package as
the first SV/UVM output target. The selected skeleton may declare inert UVM
1.2 snapshot item and monitor classes from `verification_observations[]`, but
it must not sample a DUT interface, publish transactions, infer events, build
an agent, generate a scoreboard, generate coverage, or emit reusable VIP
behavior. Public CLI, artifact layout, report/manifest shape,
support-accounting identity, and validation gates were selected by
`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.7`: the public command is
`--emit-verification-output uvm-passive-monitor --verification-outdir DIR
source.isf`, with artifacts under `DIR/uvm/` and
`DIR/verification-output-manifest.json`. `.8` implements that first bounded
inert UVM passive-monitor skeleton output and advertises it through the
capability manifest without claiming UVM compile support. VHDL-oriented
verification artifacts now have one bounded shipped target: `.5` selected no
VHDL assertion, PSL, testbench, or monitor-like behavior because the current
VHDL path is synthesizable scaffold-only and VHDL/GHDL validation is not
active; `.9` selected shape-only inert-artifact validation with explicit
no-compile/no-PSL manifest claims; `.10` selected an inert VHDL observation
metadata package; and `.11` implements `--emit-verification-output
vhdl-observation-package --verification-outdir DIR source.isf`, producing
`DIR/vhdl/<actor>_observation_vhdl_pkg.vhd` plus the manifest under canonical
target `vhdl_observation_package_skeleton`. It does not claim VHDL compile,
syntax, PSL, simulator, analyzer, scoreboard, coverage, reusable VIP, or
direct IAL2 support. Audit `.6` selects no direct IAL2-to-verification route
for the current lane: `.ppif` remains unsupported for verification-output CLI
modes, and future protocol-specific verification facts should first lower or
annotate generated IAL1 `.isf` review artifacts unless a later exact owner
proves a direct route is required.
Packed burst outputs, concrete same-ID queue variants beyond the shipped
read burst-last, write, and read single-beat depth-2 queue-head boundaries,
per-ID queues, queued policy, profile
aliases, full-manager behavior, direct backend lowering, and VHDL remain
deferred.
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
