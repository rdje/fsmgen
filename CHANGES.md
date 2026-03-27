# CHANGES
This is the persistent technical change history for FSMGen.
## 2026-03-28
### direct SystemVerilog global factorization now has a dedicated backend owner
- Added [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GlobalFactorizationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GlobalFactorizationSupport.pm) as the owner of the live direct first-pass AST-factorization pipeline: factorizer construction, substitution, original-AST refresh, fixpoint delegation, and factorizer persistence.
- Updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) and [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm) so the live direct backend now instantiates and uses that owner directly.
- Narrowed [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ASTFactorizationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ASTFactorizationSupport.pm) to substituted-AST lookup plus the legacy direct intermediate-signal rendering helper, added [t/211-systemverilog-global-factorization-support.t](/Users/richarddje/Documents/github/fsmgen/t/211-systemverilog-global-factorization-support.t), tightened [t/201-systemverilog-ast-factorization-support.t](/Users/richarddje/Documents/github/fsmgen/t/201-systemverilog-ast-factorization-support.t) and [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t), and refreshed the live architecture/roadmap notes.

## 2026-03-27
### EnableGraph factorization policy now has a dedicated owner
- Added [perl/FSM/Synthesis/EnableGraph/FactorizationPolicySupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph/FactorizationPolicySupport.pm) as the owner of the synthesis-side factorization-policy family: logical-operation counting, first-pass AST collection and factorizer feed preparation, second-pass AST feed eligibility, and high-count logical-operation policy.
- Updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm), [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ASTFactorizationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ASTFactorizationSupport.pm), [perl/FSM/HDL/Factorization/Fixpoint.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint.pm), and [perl/FSM/Synthesis/EnableGraph/ASTSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph/ASTSupport.pm) so the live direct backend and factorization loop now ask that owner directly.
- Narrowed [perl/FSM/Synthesis/EnableGraph/FactorizationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph/FactorizationSupport.pm) to the substitution/live-usage side, added [t/210-enable-graph-factorization-policy-support.t](/Users/richarddje/Documents/github/fsmgen/t/210-enable-graph-factorization-policy-support.t), tightened [t/203-enable-graph-factorization-support.t](/Users/richarddje/Documents/github/fsmgen/t/203-enable-graph-factorization-support.t) and [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t), and refreshed the live architecture/roadmap notes.

### EnableGraph factorization support now has a dedicated owner
- Added [perl/FSM/Synthesis/EnableGraph/FactorizationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph/FactorizationSupport.pm) as the owner of the synthesis-side factorization-analysis and substitution/live-usage evidence family: logical-operation counting, factorizer feed preparation, second-pass AST feed selection, substitution synchronization, signal-reference checks, and intermediate live-usage derivation.
- Updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm), [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ASTFactorizationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ASTFactorizationSupport.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm), and [perl/FSM/HDL/Factorization/Fixpoint.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint.pm) so the live backend and iterative factorization callers now use that owner directly instead of keeping the whole family inline in `EnableGraph`.
- Removed the extracted factorization-support family from [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm), added [t/203-enable-graph-factorization-support.t](/Users/richarddje/Documents/github/fsmgen/t/203-enable-graph-factorization-support.t), tightened [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t), and refreshed the live architecture/roadmap notes; the new direct owner lock also preserves the honest nuance that prepared-backend live evidence for a factorized signal can be substitution-only rather than final-expression presence.

### EnableGraph intermediate-signal support now has a dedicated owner
- Added [perl/FSM/Synthesis/EnableGraph/IntermediateSignalSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph/IntermediateSignalSupport.pm) as the owner of the synthesis-side intermediate-signal registry and dependency-recovery family: normalized registry access, native defining-AST lookup, compatibility-expression parsing, rendered-expression recovery, signal-name dependency AST recovery, and referenced-intermediate declaration tracking.
- Updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm), [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm), and [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm) so the direct backend path plus synthesis callers now use that owner directly instead of keeping the whole pocket inline in `EnableGraph`.
- Added [t/202-enable-graph-intermediate-signal-support.t](/Users/richarddje/Documents/github/fsmgen/t/202-enable-graph-intermediate-signal-support.t), tightened [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t) to point the ownership checks at the new support package, and refreshed the live architecture/roadmap notes.

### direct SystemVerilog AST factorization support now has a dedicated backend owner and the old backend package is retired
- Added [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ASTFactorizationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ASTFactorizationSupport.pm) as the owner of the bounded direct generated-module AST-factorization/substitution family: global AST factorization, iterative post-substitution fixpoint delegation, substituted-AST lookup, and the older direct intermediate-signal rendering helper.
- Updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm), and [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm) so the live direct backend path now instantiates and uses that owner directly.
- Removed [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm) from the live backend path, added [t/201-systemverilog-ast-factorization-support.t](/Users/richarddje/Documents/github/fsmgen/t/201-systemverilog-ast-factorization-support.t) as the direct owner lock, and refreshed the live architecture/roadmap notes.

### direct SystemVerilog consolidated intermediate emission now has a dedicated backend owner
- Added [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm) as the owner of the bounded direct generated-module consolidated intermediate-signal emission family: AST-factorized plus pre-scanned signal merging, dependency-aware filtering, topological ordering, and final wire/assign emission before unified WEN/EN generation.
- Updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) and [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm) so the older direct backend path now instantiates and uses that owner directly instead of keeping the consolidated emitter inline in the broader SystemVerilog backend.
- Reduced [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm) by removing the inline consolidated emitter and its topological-sort helper, added [t/200-systemverilog-consolidated-intermediate-emitter.t](/Users/richarddje/Documents/github/fsmgen/t/200-systemverilog-consolidated-intermediate-emitter.t) as the direct owner lock, and refreshed the live architecture/roadmap notes.

### direct SystemVerilog intermediate-signal support now has a dedicated backend owner
- Added [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm) as the owner of the bounded direct generated-module runtime-AST/intermediate-signal support family: runtime AST recovery, rendered-expression caching, dependency recovery, width inference, and AST-aware filtering for the consolidated intermediate-signal path.
- Updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) and [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm) so the older direct backend path now instantiates and uses that owner directly instead of keeping that support family inline in the broader SystemVerilog renderer.
- Updated [t/07-runtime-ast-miss-dependency-recovery.t](/Users/richarddje/Documents/github/fsmgen/t/07-runtime-ast-miss-dependency-recovery.t) and [t/08-driving-ast-canonicalization.t](/Users/richarddje/Documents/github/fsmgen/t/08-driving-ast-canonicalization.t) so those long-lived runtime-AST regression locks now point at the explicit owner, and refreshed the live architecture/roadmap notes.

### direct SystemVerilog internal declaration rendering now has a dedicated backend owner
- Added [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/InternalDeclarationEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/InternalDeclarationEmitter.pm) as the owner of the bounded direct generated-module internal declaration family: internal storage `reg` declarations and auxiliary helper-register declarations rendered from the enable-graph declaration plan.
- Updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) and [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm) so the older direct backend path now instantiates and uses that owner directly instead of keeping the declaration renderer inline in the broader SystemVerilog backend.
- Reduced [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm) by removing the inline declaration-rendering pocket, added [t/199-systemverilog-internal-declaration-emitter.t](/Users/richarddje/Documents/github/fsmgen/t/199-systemverilog-internal-declaration-emitter.t) as the direct owner lock, and refreshed the live architecture/roadmap notes.

## 2026-03-26
### direct SystemVerilog scaffold rendering now has a dedicated backend owner
- Added [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ScaffoldEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ScaffoldEmitter.pm) as the owner of the bounded direct generated-module scaffold family: header rendering, module declaration rendering, state encoding rendering, and state register rendering.
- Updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) and [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm) so the older direct backend path now instantiates and uses that owner directly instead of keeping the scaffold family inline in the broader SystemVerilog renderer.
- Reduced [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm) by removing that scaffold family from the general renderer, added [t/198-systemverilog-scaffold-emitter.t](/Users/richarddje/Documents/github/fsmgen/t/198-systemverilog-scaffold-emitter.t) as the direct owner lock, and refreshed the live architecture/roadmap notes.

### old source-frontend wrapper residue is now gone from the pipeline facade
- Updated the remaining regression callers in [t/13-composition-source-classification.t](/Users/richarddje/Documents/github/fsmgen/t/13-composition-source-classification.t), [t/184-composition-generated-child-realizer.t](/Users/richarddje/Documents/github/fsmgen/t/184-composition-generated-child-realizer.t), [t/185-composition-rtl-child-realizer.t](/Users/richarddje/Documents/github/fsmgen/t/185-composition-rtl-child-realizer.t), [t/186-composition-plan-builder.t](/Users/richarddje/Documents/github/fsmgen/t/186-composition-plan-builder.t), [t/190-pipeline-direct-generation-orchestrator.t](/Users/richarddje/Documents/github/fsmgen/t/190-pipeline-direct-generation-orchestrator.t), and [t/197-pipeline-source-frontend.t](/Users/richarddje/Documents/github/fsmgen/t/197-pipeline-source-frontend.t) so they now ask [perl/FSM/Pipeline/SourceFrontend.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceFrontend.pm) directly instead of relying on facade wrappers.
- Removed the final frontend pass-through methods from [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm), leaving that file with shared pipeline configuration plus `generate_hdl_from_file(...)`.
- Refreshed the live architecture/roadmap notes so they now describe `HDLGenerator` as the top-level public entry facade, not a facade plus leftover frontend wrapper residue.

### old direct generated-module helper residue is now gone from the pipeline facade
- Updated [perl/FSM/Pipeline/DirectGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/DirectGenerationOrchestrator.pm), [perl/FSM/Composition/GeneratedChildRealizer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GeneratedChildRealizer.pm), and [perl/FSM/Composition/GenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GenerationOrchestrator.pm) so they now call [perl/FSM/IR/IntentHIRBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/IntentHIRBuilder.pm), [perl/FSM/IR/StructuralRTLIRBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIRBuilder.pm), [perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm), [perl/FSM/Backend/GeneratedModuleEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Backend/GeneratedModuleEmitter.pm), and [perl/FSM/Pipeline/SourceFrontend.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceFrontend.pm) directly instead of routing that family through `HDLGenerator`.
- Removed the now-dead direct generated-module helper methods from [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm), leaving that file as a much thinner public facade around shared configuration, `generate_hdl_from_file(...)`, and the small source-frontend surface.
- Updated the direct-owner and composition-owner regression coverage in [t/191-forward-intent-hir-builder-direct-root.t](/Users/richarddje/Documents/github/fsmgen/t/191-forward-intent-hir-builder-direct-root.t), [t/192-forward-lowered-rtl-ir-builder-direct-root.t](/Users/richarddje/Documents/github/fsmgen/t/192-forward-lowered-rtl-ir-builder-direct-root.t), [t/193-forward-structural-rtl-ir-builder-direct-root.t](/Users/richarddje/Documents/github/fsmgen/t/193-forward-structural-rtl-ir-builder-direct-root.t), [t/194-generated-module-emitter.t](/Users/richarddje/Documents/github/fsmgen/t/194-generated-module-emitter.t), [t/196-generated-module-info-builder.t](/Users/richarddje/Documents/github/fsmgen/t/196-generated-module-info-builder.t), [t/182-composition-result-metadata-builder.t](/Users/richarddje/Documents/github/fsmgen/t/182-composition-result-metadata-builder.t), and [t/189-composition-generation-orchestrator.t](/Users/richarddje/Documents/github/fsmgen/t/189-composition-generation-orchestrator.t) so they now anchor directly to the real owner packages, and refreshed the live architecture/roadmap notes.

### old composition reporting helper residue is now gone from the pipeline facade
- Removed the old composition failure-summary and provenance/override/block label helper methods from [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm), so that file is a bit more honestly just the generation facade instead of one more report-helper owner.
- Updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) to read failure summaries from [perl/FSM/Composition/FailureReportBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/FailureReportBuilder.pm) and provenance/override/block labels from [perl/FSM/Composition/ProvenanceReportBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/ProvenanceReportBuilder.pm) directly.
- Updated [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) to call the failure-report builder owner directly instead of anchoring that coverage to a stale pipeline facade method, and refreshed the live architecture/roadmap notes.

### bounded source parsing and semantic-module creation now live in a dedicated frontend package
- Added [perl/FSM/Pipeline/SourceFrontend.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceFrontend.pm) as the owner of the bounded source-frontend family: Lispish file parsing, top-level source-kind classification, typed composition parsing, and semantic FSM/DT module creation through `FSMGenFull`.
- Updated [perl/FSM/Pipeline/SourceGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceGenerationOrchestrator.pm), [perl/FSM/Pipeline/DirectGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/DirectGenerationOrchestrator.pm), [perl/FSM/Composition/GenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GenerationOrchestrator.pm), [perl/FSM/Composition/GeneratedChildRealizer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GeneratedChildRealizer.pm), and [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so that frontend family is now owned there instead of being kept inline in the pipeline facade.
- Added [t/197-pipeline-source-frontend.t](/Users/richarddje/Documents/github/fsmgen/t/197-pipeline-source-frontend.t) to lock the extracted owner directly against the pipeline facade surface, and refreshed [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the live package map reflects the new frontend owner boundary.

### bounded generated-module module_info construction now lives in a dedicated pipeline builder
- Added [perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm) as the owner of bounded generated-module `module_info` construction, lowered generated-analysis enrichment, and the normalized query surface over output-drive families and grouped standalone-DT targets.
- Updated [perl/FSM/Pipeline/DirectGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/DirectGenerationOrchestrator.pm), [perl/FSM/Composition/GeneratedChildRealizer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GeneratedChildRealizer.pm), and [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so generated-module metadata build/enrich/query logic is now owned there instead of being spread across the pipeline facade and the direct/generated-child flows.
- Added [t/196-generated-module-info-builder.t](/Users/richarddje/Documents/github/fsmgen/t/196-generated-module-info-builder.t) to lock the extracted owner directly, and tightened [t/194-generated-module-emitter.t](/Users/richarddje/Documents/github/fsmgen/t/194-generated-module-emitter.t) so it normalizes non-semantic intermediate declaration ordering instead of overfitting to backend line order.
- Refreshed [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the live package map reflects the new generated-module metadata owner boundary.

### top-level source/file dispatch now lives in a dedicated pipeline orchestrator
- Added [perl/FSM/Pipeline/SourceGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceGenerationOrchestrator.pm) as the owner of top-level parse/classify/dispatch orchestration, including extension-hook dispatch and final result finalization around direct-root and composition generation.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so `generate_hdl_from_file(...)` now delegates there instead of keeping the source-level coordinator inline.
- Added [t/195-pipeline-source-generation-orchestrator.t](/Users/richarddje/Documents/github/fsmgen/t/195-pipeline-source-generation-orchestrator.t) to lock the new owner directly across direct-root, composition, and extension-hook paths, and refreshed [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the live package map reflects the new source-level orchestrator boundary.

### bounded direct generated-module backend execution now lives in a dedicated backend package
- Added [perl/FSM/Backend/GeneratedModuleEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Backend/GeneratedModuleEmitter.pm) as the owner of the bounded direct generated-module backend family used by direct FSM/DT roots and realized generated children.
- Moved backend-method selection, direct HDL emission through the existing `FlattenedDT` family, backend statistics collection, and standalone-DT assertion postprocessing under that package instead of leaving those helpers split across [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm), [perl/FSM/Pipeline/DirectGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/DirectGenerationOrchestrator.pm), and [perl/FSM/Composition/GeneratedChildRealizer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GeneratedChildRealizer.pm).
- Added [t/194-generated-module-emitter.t](/Users/richarddje/Documents/github/fsmgen/t/194-generated-module-emitter.t) to lock the new backend owner directly against the full pipeline result surface, and refreshed [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the live package map reflects the new backend owner boundary.

### direct-root StructuralRTLIR construction now lives in the IR builder package
- Widened [perl/FSM/IR/StructuralRTLIRBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIRBuilder.pm) so it now owns bounded direct-root `StructuralRTLIR` construction from generated-module analysis, including module-boundary port assembly and implicit-system-port structural projection.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so its direct-root `build_structural_rtl_ir` path now delegates to the IR-layer builder instead of keeping that structural helper family inline.
- Added [t/193-forward-structural-rtl-ir-builder-direct-root.t](/Users/richarddje/Documents/github/fsmgen/t/193-forward-structural-rtl-ir-builder-direct-root.t) to lock the widened builder directly, and refreshed [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the live package map reflects the new direct-root structural builder boundary.

### direct-root LoweredRTLIR construction now lives in the IR builder package
- Widened [perl/FSM/IR/LoweredRTLIRBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/LoweredRTLIRBuilder.pm) so it now owns bounded direct-root `LoweredRTLIR` construction from generated-module analysis plus direct backend analysis state, including output-drive-family analysis, standalone-DT lowered-target assembly, and onehot-style multi-drive assertion metadata.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so its direct-root `build_lowered_rtl_ir` path now delegates to the IR-layer builder instead of keeping that lowered helper family inline.
- Added [t/192-forward-lowered-rtl-ir-builder-direct-root.t](/Users/richarddje/Documents/github/fsmgen/t/192-forward-lowered-rtl-ir-builder-direct-root.t) to lock the widened builder directly, and refreshed [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the live package map reflects the new direct-root lowered builder boundary.

### direct-root IntentHIR construction now lives in the IR builder package
- Widened [perl/FSM/IR/IntentHIRBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/IntentHIRBuilder.pm) so it now owns bounded direct-root `IntentHIR` construction from a semantic FSM/DT module, including direct-root signal-analysis grouping, signal-direction inference, and standalone-DT enable-family assembly.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so its direct-root `build_intent_hir` path now delegates to the IR-layer builder instead of keeping that semantic helper family inline.
- Added [t/191-forward-intent-hir-builder-direct-root.t](/Users/richarddje/Documents/github/fsmgen/t/191-forward-intent-hir-builder-direct-root.t) to lock the widened builder directly, and refreshed [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the live package map reflects the new direct-root semantic builder boundary.

### direct-root generation orchestration now lives in a dedicated pipeline package
- Added [perl/FSM/Pipeline/DirectGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/DirectGenerationOrchestrator.pm) as the owner of bounded non-composition source-to-result orchestration, including semantic module creation, forward-IR extraction, direct HDL generation, module-info enrichment, structural IR export, and statistics collection.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the pipeline now delegates the direct-root generation/result path there instead of keeping the whole cluster inline.
- Added [t/190-pipeline-direct-generation-orchestrator.t](/Users/richarddje/Documents/github/fsmgen/t/190-pipeline-direct-generation-orchestrator.t) to lock the extracted owner directly, and refreshed [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the live package map reflects the new direct-root orchestrator boundary.

### composition generation orchestration now lives in a dedicated composition package
- Added [perl/FSM/Composition/GenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GenerationOrchestrator.pm) as the owner of bounded composition source-to-result orchestration, including plan construction, child-export projection, composition-top forward-IR assembly, structural top emission, and result-metadata/statistics assembly.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the pipeline now delegates the composition-top generation/result path there instead of keeping the whole cluster inline, and removed the dead inline composition result-assembly wrappers that no longer had honest callers.
- Added [t/189-composition-generation-orchestrator.t](/Users/richarddje/Documents/github/fsmgen/t/189-composition-generation-orchestrator.t) to lock the extracted owner directly, and refreshed [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the live package map reflects the new orchestrator owner boundary.

### composition-top LoweredRTLIR construction now lives in a dedicated IR builder package
- Added [perl/FSM/IR/LoweredRTLIRBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/LoweredRTLIRBuilder.pm) as the owner of bounded composition-top `LoweredRTLIR` construction from an already-built composition plan plus structural, semantic, and shared-datapath inputs.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the pipeline now delegates that composition-top lowered-IR assembly path to the IR-layer builder instead of keeping it inline.
- Added [t/188-composition-lowered-rtl-ir-builder.t](/Users/richarddje/Documents/github/fsmgen/t/188-composition-lowered-rtl-ir-builder.t) to lock the extracted owner directly, and refreshed [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the live package map reflects the new forward-IR owner boundary.

## 2026-03-25
### composition-top IntentHIR construction now lives in a dedicated IR builder package
- Added [perl/FSM/IR/IntentHIRBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/IntentHIRBuilder.pm) as the owner of bounded composition-top `IntentHIR` construction from an already-built composition plan plus structural and child-export inputs.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the pipeline now delegates that composition-top semantic-HIR assembly path to the IR-layer builder instead of keeping it inline.
- Added [t/187-composition-intent-hir-builder.t](/Users/richarddje/Documents/github/fsmgen/t/187-composition-intent-hir-builder.t) to lock the extracted owner directly, and refreshed [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the live package map reflects the new forward-IR owner boundary.

### composition plan orchestration now lives in a dedicated builder package
- Added [perl/FSM/Composition/PlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/PlanBuilder.pm) as the owner of the bounded composition-plan orchestration family, including child realization dispatch, `?ports` shape gating, top-port inference handoff, lane selection, and shared-datapath plan augmentation.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the pipeline now delegates full composition-plan construction to that package instead of keeping the orchestration cluster inline.
- Added [t/186-composition-plan-builder.t](/Users/richarddje/Documents/github/fsmgen/t/186-composition-plan-builder.t) to lock the extracted owner directly, and refreshed [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the live package map reflects the new owner boundary.

### rtl child realization now lives in a dedicated composition package
- Added [perl/FSM/Composition/RTLChildRealizer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLChildRealizer.pm) as the owner of the bounded `?rtl` child realization family, including projection of embedded-root or sidecar `.rtlif` metadata into normalized `FSM::Composition::RealizedInstance` carriers.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the pipeline now delegates `?rtl` child realization to that package instead of keeping the external-RTL child projection pocket inline, while [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm) remains the narrower owner of `.rtlif` metadata loading and validation.
- Added [t/185-composition-rtl-child-realizer.t](/Users/richarddje/Documents/github/fsmgen/t/185-composition-rtl-child-realizer.t) to lock the extracted owner directly, and refreshed [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the live package map reflects the new owner boundary.

### generated-child realization now lives in a dedicated composition package
- Added [perl/FSM/Composition/GeneratedChildRealizer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GeneratedChildRealizer.pm) as the owner of the `?fsmc` / `?dtc` realization family, including embedded/external generated-child source loading, wrong-kind source validation, child compilation, shared-datapath export augmentation for realized `?fsmc` children, and normalized `FSM::Composition::RealizedInstance` construction.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the pipeline now delegates generated-child realization and generated-child source loading to that package instead of keeping the family inline.
- Added [t/184-composition-generated-child-realizer.t](/Users/richarddje/Documents/github/fsmgen/t/184-composition-generated-child-realizer.t) to lock the extracted owner directly, and refreshed [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the live package map reflects the new owner.

### shared-datapath candidate assembly now lives in a dedicated builder package
- Added [perl/FSM/Composition/SharedDatapathCandidateBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/SharedDatapathCandidateBuilder.pm) as the owner of the shared-datapath candidate family, including candidate discovery plus normalized contributor, peer-read, drive-intent, and aggregate-enable metadata derived from structural bindings and lowered child drive families.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the pipeline now delegates shared-datapath candidate assembly and per-plan candidate caching to that builder instead of keeping the family inline.
- Updated [t/168-structural-binding-leaf-consumers.t](/Users/richarddje/Documents/github/fsmgen/t/168-structural-binding-leaf-consumers.t) so the direct leaf-vs-nonleaf binding contract now points at the new builder owner, added [t/183-composition-shared-datapath-candidate-builder.t](/Users/richarddje/Documents/github/fsmgen/t/183-composition-shared-datapath-candidate-builder.t) to lock the extracted builder directly, and refreshed [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the live package map reflects the new owner.

### composition result metadata now lives in a dedicated builder package
- Added [perl/FSM/Composition/ResultMetadataBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/ResultMetadataBuilder.pm) as the owner of the success-path composition result-metadata family, including `module_info` and `statistics` assembly once composition planning, provenance, child exports, and forward IR layers already exist.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the pipeline now delegates composition `module_info` and `statistics` assembly to that builder instead of keeping those result-metadata surfaces inline.
- Added [t/182-composition-result-metadata-builder.t](/Users/richarddje/Documents/github/fsmgen/t/182-composition-result-metadata-builder.t) to lock the extracted builder directly, and refreshed [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the live package map reflects the new owner.

### composition failure summaries now live in a dedicated builder package
- Added [perl/FSM/Composition/FailureReportBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/FailureReportBuilder.pm) as the owner of the bounded failed-run composition summary family, including blocked-boundary, construct, artifact, context, and concise-reason extraction from raised composition diagnostics.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the pipeline now delegates composition failure-report construction to that builder instead of keeping the whole summary extractor inline.
- Added [t/181-composition-failure-report-builder.t](/Users/richarddje/Documents/github/fsmgen/t/181-composition-failure-report-builder.t) to lock the extracted builder directly, and refreshed [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the live package map reflects the new owner.

### composition child exports now live in a dedicated builder package
- Added [perl/FSM/Composition/ChildExportBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/ChildExportBuilder.pm) as the owner of the composition child-export family, including the unified realized-child export surface plus the narrower generated-child and standalone-DT child export views.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so composition intent/module-info/shared-datapath consumers now use that builder instead of keeping child export assembly inside the pipeline monolith.
- Added [t/180-composition-child-export-builder.t](/Users/richarddje/Documents/github/fsmgen/t/180-composition-child-export-builder.t) to lock the extracted builder directly, and synced [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the live package map reflects the new owner.

### added a dedicated live architecture note for `bin/fsmgen` and its transitive import tree
- Added [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) as a dedicated live architecture note for the [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) entrypoint, its project-owned transitive import tree, the real runtime spine, and the current package-hotspot assessment.
- Saved the maintenance rule inside that note itself: it is intended to be refreshed at the start of a later session whenever the effective entrypoint/runtime spine or ownership picture has changed enough that the note is no longer honest.
- Synced [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the project now has an explicit breadcrumb that this architecture note exists and should be maintained across sessions.

## 2026-03-24
### inferred same-name composition link planning now lives in a composition builder package
- Added [perl/FSM/Composition/SameNameLinkBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/SameNameLinkBuilder.pm) as the owner of the bounded inferred same-name convention link family used by the active `C2` and `C3` lanes, including inferred top-input fanout, inferred top-output selection, and inferred internal same-name carrier links.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so those same-name convention links now come from that composition-side builder package instead of keeping the whole implicit-link family inside the pipeline monolith.
- Added [t/175-composition-same-name-link-builder.t](/Users/richarddje/Documents/github/fsmgen/t/175-composition-same-name-link-builder.t) to lock the extracted builder directly, and synced [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next composition-planner split is tracked honestly.

### keep the product name, defer the internal namespace rename
- Logged the saved naming direction that `fsmgen` remains the product/repository/tool identity for historical reasons, while the broader internal `FSM::...` umbrella namespace is treated as a likely late-roadmap cleanup target rather than an urgent rename.
- Synced [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so that deferred naming policy is saved for the end-of-roadmap cleanup phase.

### active forward-ir packages now carry explicit pod contracts
- Added package-level POD near the top of the active forward-IR packages and newly extracted builder/emitter packages, so the currently active architecture layers have an immediate package contract instead of staying documentation-thin while the split is still underway.
- Added routine-level POD for the functions owned by those same active forward-IR packages, builders, and the first structural backend emitter, so the new package boundaries describe what they do as they land instead of waiting for a later documentation sweep.
- Synced [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this POD standard is part of the saved forward-IR implementation guidance.

### declared connect-by-name link planning now lives in a composition builder package
- Added [perl/FSM/Composition/DeclaredByNameLinkBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/DeclaredByNameLinkBuilder.pm) as the owner of bounded `C4` declared connect-by-name link construction, including system-port exclusion, same-name endpoint matching, input fanout, unique-output selection, and direction/width validation for `=port` top declarations.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so `C4` lane setup now runs through that composition-side builder package instead of keeping the declared connect-by-name link planner inside the pipeline monolith.
- Added [t/174-composition-declared-by-name-link-builder.t](/Users/richarddje/Documents/github/fsmgen/t/174-composition-declared-by-name-link-builder.t) to lock the extracted builder directly, and synced [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next composition-plan split slice is tracked honestly.

### c1 passthrough plan building now lives in a composition builder package
- Added [perl/FSM/Composition/C1PlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/C1PlanBuilder.pm) as the owner of bounded single-child passthrough `C1` plan construction, including explicit passthrough exposure validation, implicit top-port inference from one realized child interface, and direct passthrough link/binding assembly.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so `C1` lane selection now runs through that composition-side builder package instead of keeping the single-child passthrough planner inside the pipeline monolith.
- Added [t/173-composition-c1-plan-builder.t](/Users/richarddje/Documents/github/fsmgen/t/173-composition-c1-plan-builder.t) to lock the extracted builder directly, and synced [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next composition-plan split slice is tracked honestly.

### realized-child interface port planning now lives in a composition builder package
- Added [perl/FSM/Composition/InterfacePortBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/InterfacePortBuilder.pm) as the owner of realized generated-child interface port construction from `module_info`, along with the shared interface-type normalization and system-port ordering rules used by composition planning.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so realized child construction and the remaining composition interface/type consumers now call that composition-side builder package instead of keeping those rules inside the pipeline monolith.
- Updated [t/164-realized-child-interface-ports-from-structural-rtl-ir.t](/Users/richarddje/Documents/github/fsmgen/t/164-realized-child-interface-ports-from-structural-rtl-ir.t) and [t/172-intent-hir-interface-boundary-helpers.t](/Users/richarddje/Documents/github/fsmgen/t/172-intent-hir-interface-boundary-helpers.t) so the interface-port helper locks now point at the extracted builder package directly, and synced [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next package-breakdown slice is tracked honestly.

### composition-top StructuralRTLIR building now lives in a builder package
- Added [perl/FSM/IR/StructuralRTLIRBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIRBuilder.pm) as the first dedicated builder package for extracted composition-top `StructuralRTLIR` construction and structural object/hash coercion.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so composition-top structural IR construction/coercion now runs through that builder package instead of pipeline-owned helper methods.
- Updated [t/162-composition-top-structural-rtl-ir-surface.t](/Users/richarddje/Documents/github/fsmgen/t/162-composition-top-structural-rtl-ir-surface.t) so the structural object used in the contract test now comes from the builder package directly, and added a direct coercion lock for the serialized structural graph.
- Synced [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this matching pipeline-side split is tracked honestly.

### composition-top structural text emission now lives in a backend emitter package
- Added [perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm) as the first dedicated backend emitter package for extracted `StructuralRTLIR` in the current Verilog-family composition lane.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so composition-top structural text emission now runs through that backend package instead of a pipeline-owned `emit_composition_top_module` method.
- Updated [t/162-composition-top-structural-rtl-ir-surface.t](/Users/richarddje/Documents/github/fsmgen/t/162-composition-top-structural-rtl-ir-surface.t) and [t/167-structural-connection-expr-helpers.t](/Users/richarddje/Documents/github/fsmgen/t/167-structural-connection-expr-helpers.t) so the structural emitter locks now point at the backend package directly, and added one explicit target-language boundary check for that new emitter.
- Synced [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this first backend-emitter split slice is tracked honestly.

### clarified that no compatibility pretext should preserve the HDLGenerator monolith
- Updated [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the saved breakdown policy is now stronger and more explicit.
- The logged clarification is:
  - FSMGen does not yet have a published public compatibility contract worth preserving,
  - the strongest architecture therefore matters more than preserving the current `HDLGenerator` monolith,
  - the target split remains “compiler/orchestrator builds IRs, backend emitter walks `StructuralRTLIR` and emits HDL text,”
  - and any internal shim is acceptable only as a clearly transitional migration aid toward that split.

### composition-top port metadata now lives in StructuralRTLIR
- Updated [perl/FSM/IR/StructuralRTLIR.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIR.pm) so the structural layer now also owns `port_metadata` and `port_metadata_from_input`, the reusable rule for projecting explicit top ports into compatible `signals`, `signal_names`, and grouped input/output/multi-bit/single-bit signal-analysis metadata.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so composition-top `IntentHIR` construction and compatible `module_info` signal metadata now consume that structural helper surface instead of rebuilding the same top-port projection locally.
- Updated [t/162-composition-top-structural-rtl-ir-surface.t](/Users/richarddje/Documents/github/fsmgen/t/162-composition-top-structural-rtl-ir-surface.t) to lock both the object and serialized-hash structural helper paths, and synced [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next structural ownership slice is tracked honestly.

### clarified the intended HDLGenerator breakdown in the forward-ir plan
- Updated [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the saved architecture now distinguishes the current implementation reality from the target layering more explicitly.
- The logged clarification is:
  - the target forward spine remains `IntentHIR -> LoweredRTLIR -> StructuralRTLIR -> backend emission`,
  - `StructuralRTLIR` is still the intended last IR before HDL text,
  - the current [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) still acts as a combined compiler driver, lowering coordinator, and emitter,
  - and direct `IntentHIR` / `LoweredRTLIR` lookups there are therefore treated as transitional coordinator cleanup rather than as the desired final backend boundary.
- The planned convergence stays the same:
  - orchestration may still see all three forward IR layers,
  - but the pure HDL-emitter path should converge toward mostly walking `StructuralRTLIR`.

## 2026-03-23
### semantic interface-boundary lookup now lives in IntentHIR
- Updated [perl/FSM/IR/IntentHIR.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/IntentHIR.pm) so the semantic layer now owns `system_contract_from_input`, `signal_analysis_entries`, and `signal_analysis_entries_from_input` for normalized system-contract and signal-analysis boundary lookup.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so realized-child interface fallback now consumes that semantic helper surface instead of rereading system-contract and signal-analysis boundary data directly from raw `module_info` fields.
- Added [t/172-intent-hir-interface-boundary-helpers.t](/Users/richarddje/Documents/github/fsmgen/t/172-intent-hir-interface-boundary-helpers.t) to lock both the new `IntentHIR` helper surface and the realized-child interface fallback handoff, and synced [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next forward-IR ownership slice is tracked honestly.

### lowered standalone-dt target lookup now lives in LoweredRTLIR
- Updated [perl/FSM/IR/LoweredRTLIR.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/LoweredRTLIR.pm) so the lowered layer now owns `standalone_dt_multi_drive_targets_from_input`, `standalone_dt_multi_drive_targets_by_signal`, `standalone_dt_multi_drive_targets_by_signal_from_input`, `standalone_dt_multi_drive_target`, and `standalone_dt_multi_drive_target_from_input` for normalized grouped standalone-DT target lookup.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so standalone-DT assertion emission, reusable standalone-DT child export assembly, and module standalone-DT target access now consume that lowered helper surface instead of rereading the same lowered arrays directly.
- Added [t/171-forward-lowered-rtl-ir-standalone-dt-target-helpers.t](/Users/richarddje/Documents/github/fsmgen/t/171-forward-lowered-rtl-ir-standalone-dt-target-helpers.t) to lock both full `LoweredRTLIR` objects and the existing partial lowered-hash callers, and synced [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next forward-IR ownership slice is tracked honestly.

### lowered output-drive-family lookup now lives in LoweredRTLIR
- Updated [perl/FSM/IR/LoweredRTLIR.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/LoweredRTLIR.pm) so the lowered layer now owns `output_drive_families_from_input`, `output_drive_families_by_signal`, `output_drive_families_by_signal_from_input`, `output_drive_family`, and `output_drive_family_from_input` for normalized per-signal output-drive-family lookup.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so module output-drive-family access and composition shared-datapath contributor drive-family lookup now consume that lowered helper surface instead of rebuilding the same lowered signal map locally.
- Added [t/170-forward-lowered-rtl-ir-output-drive-helpers.t](/Users/richarddje/Documents/github/fsmgen/t/170-forward-lowered-rtl-ir-output-drive-helpers.t) to lock both full `LoweredRTLIR` objects and the existing partial lowered-hash callers, and synced [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next forward-IR ownership slice is tracked honestly.

### semantic composition-child lookup now lives in IntentHIR
- Updated [perl/FSM/IR/IntentHIR.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/IntentHIR.pm) so the forward semantic layer now owns `composition_children_by_instance` and `composition_child`, the reusable rule for “instance name to semantic child export” lookup over `composition_children`.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so composition child export access, provenance endpoint context lookup, and shared-datapath candidate assembly now consume that `IntentHIR` lookup surface instead of rebuilding the same semantic child map locally.
- Added [t/169-intent-hir-composition-child-helpers.t](/Users/richarddje/Documents/github/fsmgen/t/169-intent-hir-composition-child-helpers.t) to lock the new semantic-owner boundary directly, and synced [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next forward-IR ownership slice is tracked honestly.

### structural top-port and resolved-link queries now live in StructuralRTLIR
- Updated [perl/FSM/IR/StructuralRTLIR.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIR.pm) so the structural layer now also owns `top_port` and `resolved_links_touching` for explicit top-port lookup and “which resolved links touch endpoint X?” queries.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so composition provenance endpoint resolution and explicit-toplink override reporting now consume those structural queries instead of rebuilding the same lookups locally.
- Updated [t/162-composition-top-structural-rtl-ir-surface.t](/Users/richarddje/Documents/github/fsmgen/t/162-composition-top-structural-rtl-ir-surface.t) to lock the new structural query surface directly, and synced [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next structural ownership slice is tracked honestly.

### structural endpoint-query helpers now live in StructuralRTLIR
- Updated [perl/FSM/IR/StructuralRTLIR.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIR.pm) so the structural layer now owns `interface_endpoint`, `interface_signal_endpoints`, and `interface_signal_endpoint_groups` for explicit child-interface endpoint lookup and signal-family grouping.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so composition provenance, override reporting, block reporting, and signal-family context discovery now consume that structural endpoint-query API instead of hand-walking nested `instances` / `interface_ports` loops locally.
- Updated [t/162-composition-top-structural-rtl-ir-surface.t](/Users/richarddje/Documents/github/fsmgen/t/162-composition-top-structural-rtl-ir-surface.t) to lock the new structural endpoint-query surface directly, and synced [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next structural ownership slice is tracked honestly.

### structural binding-summary indexing now lives in the structural helper layer
- Updated [perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm) so the structural layer now also owns `binding_signal_summaries_by_port`, the reusable rule for turning one binding list into a normalized per-port summary index.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so composition system-signal inference and shared-datapath candidate assembly now consume that structural helper instead of rebuilding the same per-port summary map locally.
- Updated [t/167-structural-connection-expr-helpers.t](/Users/richarddje/Documents/github/fsmgen/t/167-structural-connection-expr-helpers.t) to lock the new helper directly, and synced [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next structural ownership slice is tracked honestly.

### structural summary metadata export now lives in the structural helper layer
- Updated [perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm) so the structural layer now also owns `binding_signal_summary_metadata`, the reusable rule for normalized cloned `bound_signal` / `bound_signals` / `bound_connection_expr` payload export.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so shared-datapath contributor and peer-read endpoint metadata now consume that structural helper instead of hand-copying the same summary fields locally.
- Updated [t/167-structural-connection-expr-helpers.t](/Users/richarddje/Documents/github/fsmgen/t/167-structural-connection-expr-helpers.t) to lock the new helper directly, and synced [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next structural ownership slice is tracked honestly.

### structural summary text rendering now lives in the structural helper layer
- Updated [perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm) so the structural layer now owns `binding_signal_summary_text`, the reusable rule for rendering a summary entry from `bound_connection_expr` first and then falling back to flat/dependency mirrors.
- Updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) so non-quiet shared-datapath summary rendering now consumes that structural helper instead of keeping its own local `shared_binding_summary` logic.
- Updated [t/167-structural-connection-expr-helpers.t](/Users/richarddje/Documents/github/fsmgen/t/167-structural-connection-expr-helpers.t) to lock the new helper directly, and synced [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next structural ownership slice is tracked honestly.

### structural summary leaf-carrier lookup now lives in the structural helper layer
- Updated [perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm) so the structural layer now owns `binding_signal_summary_leaf_signal`, the reusable rule for “typed summary entry to true flat leaf carrier.”
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so shared-datapath candidate planning now consumes that structural helper instead of keeping a pipeline-local `shared_datapath_entry_leaf_binding_signal` copy.
- Updated [t/167-structural-connection-expr-helpers.t](/Users/richarddje/Documents/github/fsmgen/t/167-structural-connection-expr-helpers.t) and [t/168-structural-binding-leaf-consumers.t](/Users/richarddje/Documents/github/fsmgen/t/168-structural-binding-leaf-consumers.t) to lock the new structural-owner boundary directly, and synced [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next ownership slice is tracked honestly.

### structural binding signal summaries now live in the structural helper layer
- Updated [perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm) so the structural layer now owns one `binding_signal_summary` projection over flat leaf carrier name, broader dependency names, and cloned typed binding expression payload.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so composition system-signal inference and shared-datapath candidate metadata now consume that structural summary helper instead of rebuilding the same projection locally.
- Updated [t/167-structural-connection-expr-helpers.t](/Users/richarddje/Documents/github/fsmgen/t/167-structural-connection-expr-helpers.t) to lock the new helper surface directly, and synced [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this structural ownership slice is tracked honestly.

### shared-datapath cli summaries now render typed contributor bindings too
- Updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) so non-quiet shared-datapath candidate summary lines now render contributor binding text from `bound_connection_expr` instead of printing only contributor endpoints.
- Updated [t/159-composition-shared-datapath-forward-ir-exports.t](/Users/richarddje/Documents/github/fsmgen/t/159-composition-shared-datapath-forward-ir-exports.t) to lock the richer contributor-line shape.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next structural-summary consumer slice is tracked honestly.

### shared-datapath cli summaries now render typed peer-read bindings
- Updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) so non-quiet shared-datapath summaries now render peer-read binding text from `bound_connection_expr` instead of printing only endpoint names.
- Updated [t/143-composition-shared-datapath-visibility-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/143-composition-shared-datapath-visibility-metadata.t) and [t/144-composition-shared-datapath-combinational-peer-read-policy.t](/Users/richarddje/Documents/github/fsmgen/t/144-composition-shared-datapath-combinational-peer-read-policy.t) to lock the richer CLI line shape.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this structural-summary consumer slice is tracked honestly.

### structural bit-vector literals now render honestly for vhdl too
- Updated [perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm) so the existing bounded `bit_vector_literal` connection-expression node now also renders through the current VHDL helper path instead of staying Verilog-only.
- Updated [t/167-structural-connection-expr-helpers.t](/Users/richarddje/Documents/github/fsmgen/t/167-structural-connection-expr-helpers.t) to lock both vector and single-bit VHDL literal rendering.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this structural actual-connection portability slice is tracked honestly.

### shared-datapath planning now prefers typed binding expressions
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so shared-datapath carrier/top-output/peer-input planning now derives flat leaf carrier names from `bound_connection_expr` first, with `bound_signal` only as a compatibility fallback.
- Updated [t/168-structural-binding-leaf-consumers.t](/Users/richarddje/Documents/github/fsmgen/t/168-structural-binding-leaf-consumers.t) to lock that helper boundary directly, including the stale-mirror and non-leaf-expression cases.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next structural-consumer handoff slice is tracked honestly.

### shared-datapath metadata now preserves typed binding expressions
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so shared-datapath contributors and peer-input endpoints now preserve `bound_connection_expr` alongside the older `bound_signal` and `bound_signals` summaries.
- Updated [t/139-composition-shared-datapath-candidate-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/139-composition-shared-datapath-candidate-metadata.t), [t/140-composition-shared-datapath-drive-intent-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/140-composition-shared-datapath-drive-intent-metadata.t), [t/143-composition-shared-datapath-visibility-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/143-composition-shared-datapath-visibility-metadata.t), [t/148-composition-shared-datapath-mixed-reexport-runtime.t](/Users/richarddje/Documents/github/fsmgen/t/148-composition-shared-datapath-mixed-reexport-runtime.t), and [t/168-structural-binding-leaf-consumers.t](/Users/richarddje/Documents/github/fsmgen/t/168-structural-binding-leaf-consumers.t) to lock both flat-leaf and richer structural-expression cases.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this structural metadata handoff slice is tracked honestly.

### structural slice and concat expressions now render honestly for vhdl too
- Updated [perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm) so the existing bounded `bit_select`, `slice`, and `concat` connection-expression families now also render through the current VHDL helper path instead of staying Verilog-only.
- Updated [t/167-structural-connection-expr-helpers.t](/Users/richarddje/Documents/github/fsmgen/t/167-structural-connection-expr-helpers.t) to lock VHDL rendering for fixed-bit selects, descending and ascending slices, and nested concatenations.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this structural actual-connection portability slice is tracked honestly.

### structural leaf-signal consumers now distinguish flat carriers from richer dependencies
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so composition system-signal inference and shared-datapath candidate bookkeeping now treat `bound_signal` as a true flat leaf binding only, while `bound_signals` continues to carry the broader dependency list for richer structural expressions.
- Added [t/168-structural-binding-leaf-consumers.t](/Users/richarddje/Documents/github/fsmgen/t/168-structural-binding-leaf-consumers.t) to lock that distinction for both system-signal inference and shared-datapath contributor metadata.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next structural-consumer handoff slice is tracked honestly.

### structural connection expressions now cover bounded fixed-size index access
- Updated [perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm) so the structural helper layer now also owns a bounded backend-neutral `index_access` actual-connection node over a source expression plus one numeric index.
- Updated [t/167-structural-connection-expr-helpers.t](/Users/richarddje/Documents/github/fsmgen/t/167-structural-connection-expr-helpers.t) to lock that fixed-size index-access node through helper rendering, dependency discovery, and the composition structural emitter, including the VHDL parenthesized rendering path.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next structural actual-connection widening slice is tracked honestly.

### structural connection expressions now cover bounded member access
- Updated [perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm) so the structural helper layer now also owns a bounded backend-neutral `member_access` actual-connection node over a source expression plus one identifier-like member name.
- Updated [t/167-structural-connection-expr-helpers.t](/Users/richarddje/Documents/github/fsmgen/t/167-structural-connection-expr-helpers.t) to lock that member-access node through helper rendering, dependency discovery, and the composition structural emitter, while keeping the backend boundary honest by failing explicitly for plain Verilog.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next structural actual-connection widening slice is tracked honestly.

### structural connection expressions now cover explicit open actuals
- Updated [perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm) so the structural helper layer now also owns an explicit backend-neutral `open` actual-connection node beside the existing reference/slice/concat/literal families.
- Updated [t/167-structural-connection-expr-helpers.t](/Users/richarddje/Documents/github/fsmgen/t/167-structural-connection-expr-helpers.t) to lock that `open` node through both helper rendering and the composition structural emitter, including the current Verilog-family empty-actual form and the VHDL `open` helper rendering.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next structural actual-connection widening slice is tracked honestly.

### structural binding-list mutation now lives in the structural helper module too
- Updated [perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm) so the structural helper layer now also owns the first bounded signal-ref binding-list ensure/set operations.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so structural port-binding reuse/append/rebind paths now consume those helpers instead of keeping low-level list mutation rules locally.
- Updated [t/167-structural-connection-expr-helpers.t](/Users/richarddje/Documents/github/fsmgen/t/167-structural-connection-expr-helpers.t) to lock the new binding-list helper surface directly.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next structural-helper ownership slice is tracked honestly.

### structural binding normalization now lives in the structural helper module too
- Updated [perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm) so the structural helper layer now also owns normalized binding cloning/backfilling for the current bounded binding contract.
- Updated [perl/FSM/Composition/RealizedInstance.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RealizedInstance.pm) so realized child-binding normalization now consumes that shared structural helper instead of carrying its own private normalization logic.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so structural instance-binding serialization now also consumes that same normalized binding helper.
- Updated [t/167-structural-connection-expr-helpers.t](/Users/richarddje/Documents/github/fsmgen/t/167-structural-connection-expr-helpers.t) to lock the new normalized binding helper surface directly.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next structural-helper ownership slice is tracked honestly.

### structural signal-ref binding construction now lives in the structural helper module too
- Updated [perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm) so the structural helper layer now also owns the first bounded `signal_ref` binding constructor and in-place rebinding helpers.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so `C1` passthrough bindings, broader composition planned child bindings, and structural rebinding paths now consume those helpers instead of hand-pairing `signal_name` and `connection_expr` locally.
- Updated [t/167-structural-connection-expr-helpers.t](/Users/richarddje/Documents/github/fsmgen/t/167-structural-connection-expr-helpers.t) to lock the new binding-constructor and rebinding helper surface directly.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next structural-helper ownership slice is tracked honestly.

### structural binding-expression fallback now lives in the structural helper module too
- Updated [perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm) so the structural helper layer now also owns the effective binding-expression fallback for bindings that only still carry the compatibility `signal_name` mirror.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so composition-top structural instance-binding serialization now consumes that helper instead of re-synthesizing `signal_ref` nodes locally.
- Updated [t/167-structural-connection-expr-helpers.t](/Users/richarddje/Documents/github/fsmgen/t/167-structural-connection-expr-helpers.t) to lock the new fallback helper surface directly.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next structural-helper cleanup slice is tracked honestly.

### structural connection-expression helpers now live in the structural ir layer
- Added [perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm) as the first dedicated helper module for bounded structural actual-connection nodes.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the pipeline now consumes that module for `signal_ref` construction, structural binding signal-name recovery, and backend-neutral connection-expression text rendering instead of keeping those helpers locally.
- Updated [perl/FSM/Composition/RealizedInstance.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RealizedInstance.pm) so plan-side child-binding normalization now uses that same structural helper module when backfilling `signal_name` / `connection_expr`.
- Added [t/167-structural-connection-expr-helpers.t](/Users/richarddje/Documents/github/fsmgen/t/167-structural-connection-expr-helpers.t) to lock the current bounded `signal_ref` helper surface directly, including fallback and unsupported-kind behavior.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), and [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md) so this next structural-IR extraction slice is tracked honestly.

### structural rtl ir instance bindings now preserve typed connection expressions
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so composition-top `structural_rtl_ir` instance pin bindings now preserve a backend-neutral `connection_expr` node beside the compatibility `signal_name` mirror.
- That first actual-connection node is intentionally bounded to `signal_ref`, but the composition-top emitter now already walks that node when rendering instance actual connections instead of trusting only the mirrored string field.
- The same update now also makes shared-datapath candidate discovery read structural binding signal names through that typed binding node, so one more structural consumer no longer depends on the legacy flat binding string alone.
- The same forward path now also preserves those typed `signal_ref` binding nodes earlier on realized composition-plan instances, so the structural layer carries them through instead of synthesizing them only during structural serialization.
- That earlier normalization now lives in [perl/FSM/Composition/RealizedInstance.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RealizedInstance.pm) itself, so the runtime child-binding carrier now owns the `signal_name` / `connection_expr` alignment contract instead of leaving it as an `HDLGenerator`-only convention.
- Updated [t/162-composition-top-structural-rtl-ir-surface.t](/Users/richarddje/Documents/github/fsmgen/t/162-composition-top-structural-rtl-ir-surface.t) to lock the new structural `connection_expr` shape on realized instance pin bindings.
- Added [t/166-realized-instance-binding-normalization.t](/Users/richarddje/Documents/github/fsmgen/t/166-realized-instance-binding-normalization.t) to lock direct `RealizedInstance` binding normalization, backfilling, and cloning behavior.
- Updated [perl/FSM/IR/StructuralRTLIR.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIR.pm), [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next structural-IR widening slice is tracked honestly.

### composition bookkeeping now mirrors the explicit ir layers more directly
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so composition-top `module_info` now derives internal-net names/counts, instance names/counts, auxiliary-assignment count, and composition lane from `lowered_rtl_ir` / `intent_hir` instead of falling back straight to raw plan bookkeeping.
- The same update now makes composition `statistics` derive composition lane and shared-datapath candidate count from `intent_hir` / `lowered_rtl_ir` instead of only carrying those fields straight from plan/runtime state.
- Updated [t/160-composition-top-forward-ir-surface.t](/Users/richarddje/Documents/github/fsmgen/t/160-composition-top-forward-ir-surface.t) to lock the tighter bookkeeping alignment between `module_info`, `statistics`, and the explicit forward IR layers.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next forward-IR handoff slice is tracked honestly.

### structural rtl ir now carries declared toplinks too
- Updated [perl/FSM/IR/StructuralRTLIR.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIR.pm) and [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so composition-top `structural_rtl_ir` now preserves declared explicit-toplink connectivity separately through `declared_links` instead of only carrying the resolved link graph.
- The same update now makes blocked undeclared-top inference reasoning consume `structural_rtl_ir->{declared_links}` instead of rereading declared toplinks directly from `composition_plan`.
- Updated [t/162-composition-top-structural-rtl-ir-surface.t](/Users/richarddje/Documents/github/fsmgen/t/162-composition-top-structural-rtl-ir-surface.t) and [t/106-composition-blocked-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/106-composition-blocked-reporting.t) to lock both the new structural declared-link surface and the matching structural-consumption handoff in block reporting.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next structural-layer widening/consumption slice is tracked honestly.

### structural rtl ir architecture now explicitly requires typed connection expressions
- Updated [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) to record that the planned `Structural RTL IR` / connectivity layer should stay backend-neutral and extensible rather than collapsing into raw SystemVerilog/VHDL syntax.
- The same architecture note now says child actual-pin connections should eventually be modeled through typed structural connection expressions / actual-connection AST nodes, with richer portable forms such as references, literals, slices/part-selects, concatenations, member/index access, and bounded open/default associations added deliberately over time.
- It also records the normalization rule that backend-specific or inelegant connection shapes should be lowered earlier into helper nets or auxiliary assignments before they reach the structural binding boundary.
- Mirrored that design constraint into [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the forward-IR implementation has one stable reference point.

### unified composition child exports now derive from the structural child layer
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so `composition_children` now derives child identity and order from `structural_rtl_ir->{instances}` instead of rereading realized child identity directly from `composition_plan->instances`.
- The same update now reuses that same computed unified child surface in the top-generation path for the narrower `composition_generated_children` and `composition_standalone_dt_children` sibling exports instead of rebuilding it again.
- Updated [t/165-composition-child-forward-ir-exports.t](/Users/richarddje/Documents/github/fsmgen/t/165-composition-child-forward-ir-exports.t) so it now locks `composition_children` identity/order against `structural_rtl_ir->{instances}` while keeping the existing mixed child-kind and forward-IR export surface stable.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next structural-consumption cleanup slice is tracked honestly.

### reusable standalone-DT child exports now derive from the unified composition child semantic layer
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so `composition_standalone_dt_children` now derives from the broader `composition_children` semantic export instead of rebuilding `?dtc` child identity separately from `composition_plan->instances`.
- The same update now sources standalone-DT names and enable families from each child's `intent_hir`, and grouped standalone-DT multi-drive targets from each child's `lowered_rtl_ir`, while keeping the existing reusable standalone-DT export shape stable.
- Updated [t/157-composition-standalone-dt-forward-ir-exports.t](/Users/richarddje/Documents/github/fsmgen/t/157-composition-standalone-dt-forward-ir-exports.t) so it now locks `composition_standalone_dt_children` as the filtered reusable standalone-DT view over `composition_children`.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next forward-IR cleanup slice is tracked honestly.

## 2026-03-22
### standalone-dt multi-drive targets now emit guard assertions
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so grouped standalone-DT multi-drive targets now carry onehot0-style assertion metadata over the DT-specific driver-enable signals, and SystemVerilog direct `?dt` roots plus realized `?dtc` children now emit bounded non-synthesis guard assertions from that metadata.
- The same update keeps the backend boundary honest by leaving standalone-DT assertion emission disabled for the Verilog target.
- Updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) so non-quiet composition runs now print one concise reusable standalone-DT child assertion summary for grouped shared targets.
- Updated [t/137-standalone-dt-multi-drive-family-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/137-standalone-dt-multi-drive-family-metadata.t) and [t/138-composition-standalone-dt-export-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/138-composition-standalone-dt-export-metadata.t) to lock the widened metadata/export surface, and added [t/154-standalone-dt-assertion-runtime-hdl.t](/Users/richarddje/Documents/github/fsmgen/t/154-standalone-dt-assertion-runtime-hdl.t) to lock the emitted HDL behavior.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next reusable-module `R11` feature slice is tracked honestly.

### combinational shared-datapath lifting now covers the public-only fanout sibling
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so bounded combinational shared-datapath families can now lift even when they are only preserved as multiple public top outputs and have no peer-read child inputs. Those families now emit one shared top-facing combinational carrier, rebind contributor outputs to private raw nets, and fan that lifted carrier back out to the preserved public top outputs.
- Updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) so non-quiet composition runs now report that sibling runtime as `combinational shared public fanout active`.
- Added [t/153-composition-shared-datapath-combinational-public-fanout-runtime.t](/Users/richarddje/Documents/github/fsmgen/t/153-composition-shared-datapath-combinational-public-fanout-runtime.t) to lock the new metadata, emitted HDL, and CLI summary for the public-only combinational fanout slice.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next `R11` shared-datapath feature slice is tracked honestly.

### registered shared-datapath lifting now covers the public-only fanout sibling
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so bounded registered shared-datapath families can now lift even when they are only preserved as multiple public top outputs and have no peer-read child inputs. Those families now emit one shared top-level register plus next-value logic, rebind contributor outputs to private raw nets, and fan the lifted register back out to the preserved public top outputs.
- Updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) so non-quiet composition runs now report that sibling runtime as `registered shared public fanout active`.
- Added [t/152-composition-shared-datapath-public-fanout-register-runtime.t](/Users/richarddje/Documents/github/fsmgen/t/152-composition-shared-datapath-public-fanout-register-runtime.t) to lock the new metadata, emitted HDL, and CLI summary for the public-only registered fanout slice.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next `R11` shared-datapath feature slice is tracked honestly.

### systemverilog composition tops now emit shared-datapath guard assertions
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the existing shared-datapath onehot0 assertion metadata now becomes real emitted guard logic on SystemVerilog composition tops. Same-value `P_Q_multi_src_conflict` signals and whole-target `P_multi_value_conflict` signals now drive non-synthesis immediate `assert` checks in the generated top.
- The same update keeps the backend boundary honest by leaving assertion emission disabled for the Verilog target.
- Added [t/151-composition-shared-datapath-assertion-runtime-hdl.t](/Users/richarddje/Documents/github/fsmgen/t/151-composition-shared-datapath-assertion-runtime-hdl.t) to lock both the emitted SystemVerilog assertion shape and the absence of that emission on Verilog.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next `R11` shared-datapath feature slice is tracked honestly.

### combinational shared-datapath peer-read families now also cover the internal-only top-local sibling
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so bounded combinational peer-read shared families can now lift even when no public top output from that family is being preserved. Those families now advertise a distinct `top_local_only` policy, use `top_local` as their lifted-visibility surface, and emit one shared top-local combinational carrier in the generated top instead of stopping at metadata only.
- The same update also fixes peer-read child-input rebinding for the new internal-only combinational runtime so those inputs now bind to the emitted shared combinational carrier rather than falling through the registered-lift path.
- Updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) so non-quiet composition runs now report that sibling runtime as `combinational shared top-local carrier active` and print the new top-local combinational peer-read policy label.
- Added [t/150-composition-shared-datapath-combinational-internal-runtime.t](/Users/richarddje/Documents/github/fsmgen/t/150-composition-shared-datapath-combinational-internal-runtime.t) to lock the new metadata, emitted HDL, and CLI summary for the internal-only combinational slice.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next `R11` shared-datapath feature slice is tracked honestly.

### combinational shared-datapath peer-read families now have a first top-facing runtime slice
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the bounded combinational peer-read public-preserving case now emits one shared top-facing combinational carrier built from the aggregate value-enable families, rebinds peer-read child inputs to that carrier, rebinds contributor outputs to private raw nets, and preserves public top outputs from the shared carrier instead of binding them directly to one child output.
- The same update also narrows `peer_input_endpoints` to inputs actually bound to contributor carriers before candidate planning/runtime, which keeps the combinational and registered ownership surfaces equally honest.
- Updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) so non-quiet composition runs now report that bounded combinational runtime as `combinational shared top-facing carrier active`.
- Updated [t/144-composition-shared-datapath-combinational-peer-read-policy.t](/Users/richarddje/Documents/github/fsmgen/t/144-composition-shared-datapath-combinational-peer-read-policy.t) to lock the refined top-facing policy wording, and added [t/149-composition-shared-datapath-combinational-runtime.t](/Users/richarddje/Documents/github/fsmgen/t/149-composition-shared-datapath-combinational-runtime.t) to lock the emitted HDL and CLI summary for the new runtime slice.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next `R11` shared-datapath feature slice is tracked honestly.

### shared-datapath lifting now covers mixed public/internal registered peer-read families
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the bounded registered public-preserving lift path no longer assumes every contributor and peer-read endpoint rides a preserved public top output. Mixed-boundary families can now lift when one contributor preserves a public top output and a sibling contributor in the same shared family is consumed only through an internal carrier.
- The same update now also filters `peer_input_endpoints` down to inputs actually bound to contributor carriers before the shared-datapath candidate is planned, so the mixed lift path rebinds only real readers of the shared family.
- Added [t/148-composition-shared-datapath-mixed-reexport-runtime.t](/Users/richarddje/Documents/github/fsmgen/t/148-composition-shared-datapath-mixed-reexport-runtime.t) to lock both the mixed-boundary candidate metadata and the emitted lifted-runtime HDL/CLI summary.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next `R11` shared-datapath feature slice is tracked honestly.

### shared-datapath lifting now covers the internal-only registered peer-read sibling
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the bounded registered loopback lift path no longer requires public top re-exports to exist before it can activate. Registered peer-read shared families with no preserved public status outputs now still emit the lifted shared register, rebind peer-read child inputs to it, and rebind contributor outputs to private raw nets.
- Updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) so non-quiet composition runs distinguish the new `registered shared internal lift active` runtime from the earlier public re-export case.
- Added [t/147-composition-shared-datapath-internal-lifted-register-runtime.t](/Users/richarddje/Documents/github/fsmgen/t/147-composition-shared-datapath-internal-lifted-register-runtime.t) to lock both emitted HDL and the non-quiet CLI summary for the internal-only lifted-register case.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next `R11` shared-datapath feature slice is tracked honestly.

## 2026-03-21
### shared-datapath candidates now surface planned conflict-bit names
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so shared-datapath candidate metadata now also carries `same_value_conflict_signal` on each aggregate value family and `multi_value_conflict_signal` on the whole target, following the existing `P_Q_multi_src_conflict` / `P_multi_value_conflict` naming direction recorded in the roadmap notes.
- Updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) so non-quiet composition runs now print those planned same-value and cross-value conflict names under each shared-datapath candidate.
- Updated [t/139-composition-shared-datapath-candidate-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/139-composition-shared-datapath-candidate-metadata.t), [t/140-composition-shared-datapath-drive-intent-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/140-composition-shared-datapath-drive-intent-metadata.t), and [t/141-composition-shared-datapath-aggregate-enable-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/141-composition-shared-datapath-aggregate-enable-metadata.t) to lock the widened conflict-name surface and matching non-quiet CLI summary lines.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next shared-datapath `R11` feature slice is tracked as shipped.

### shared-datapath candidates now surface aggregate enable families
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so generated-child `output_drive_families` now preserve per-RHS family metadata, and shared-datapath candidates now surface one deterministic whole-target aggregate enable plus per-value aggregate enable families built from contributor `P_Q` families.
- Updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) so non-quiet composition runs now print the planned whole-target and per-value aggregate enable names under each shared-datapath candidate.
- Updated [t/139-composition-shared-datapath-candidate-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/139-composition-shared-datapath-candidate-metadata.t) and [t/140-composition-shared-datapath-drive-intent-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/140-composition-shared-datapath-drive-intent-metadata.t) to lock the widened candidate and drive-intent metadata shape.
- Added [t/141-composition-shared-datapath-aggregate-enable-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/141-composition-shared-datapath-aggregate-enable-metadata.t) to lock both aggregate-enable metadata and the matching non-quiet CLI summary for a same-value shared family across contributors.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next shared-datapath `R11` feature slice is tracked as shipped.

### shared-datapath candidates now carry per-child drive intent
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so generated roots and realized generated children now surface `output_drive_family_count` and `output_drive_families` in `module_info`, and shared-datapath candidate contributors now carry one bounded `drive_intent` summary derived from generated assignment analysis.
- Updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) so non-quiet composition runs now print one concise per-child drive-intent line under each shared-datapath candidate.
- Updated [t/139-composition-shared-datapath-candidate-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/139-composition-shared-datapath-candidate-metadata.t) to lock the first single-driver `drive_intent` form inside candidate contributors.
- Added [t/140-composition-shared-datapath-drive-intent-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/140-composition-shared-datapath-drive-intent-metadata.t) to lock realized generated-child `output_drive_families`, multi-driver candidate `drive_intent`, and the matching non-quiet CLI summary.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this next shared-datapath `R11` feature slice is tracked as shipped.

### composition tops now surface first shared-datapath candidate metadata
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so composition-top `module_info` now reports first shared-datapath candidate families through `composition_shared_datapath_candidate_count` and `composition_shared_datapath_candidates`.
- Updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) so non-quiet composition runs now print one concise `Shared-Datapath Candidates` summary section from that metadata surface.
- Added [t/139-composition-shared-datapath-candidate-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/139-composition-shared-datapath-candidate-metadata.t) to lock both the pipeline-facing candidate metadata and the matching non-quiet CLI summary for multi-`?fsmc` tops.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this first shared-datapath candidate-discovery slice is tracked as shipped `R11` feature work.

### composition tops now aggregate reusable standalone-DT child exports
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so composition-top `module_info` now aggregates realized `?dtc` child exports through `composition_standalone_dt_child_count`, `composition_standalone_dt_block_count`, `composition_standalone_dt_multi_drive_target_count`, and `composition_standalone_dt_children`.
- Updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) so non-quiet composition runs now print one concise reusable standalone-DT child summary section built from that top-level export surface.
- Added [t/138-composition-standalone-dt-export-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/138-composition-standalone-dt-export-metadata.t) to lock both the pipeline-facing aggregated export metadata and the matching non-quiet CLI summary.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reusable-module composition-export slice is tracked as shipped `R11` feature work.

### standalone-DT roots now surface grouped multi-drive target metadata
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so post-generation `module_info` now reports grouped standalone-DT multi-drive target families, including target name, contributing block names, RHS families, DT-specific enable names, and grouped LHS enable names.
- Added [t/137-standalone-dt-multi-drive-family-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/137-standalone-dt-multi-drive-family-metadata.t) to lock both direct standalone-DT grouped multi-drive metadata and preservation of that same metadata for realized `?dtc` children inside composition.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reusable-module arbitration-metadata slice is tracked as shipped `R11` feature work.

### standalone-DT roots now surface stable block-enable family metadata
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so `module_info` now reports plain-scalar standalone-DT block names plus stable per-block enable-signal families and one grouped module-level enable-family summary.
- Added [t/136-standalone-dt-enable-family-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/136-standalone-dt-enable-family-metadata.t) to lock both direct standalone-DT metadata and preservation of that same metadata for realized `?dtc` children inside composition.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reusable-module enable-surfacing slice is tracked as shipped `R11` feature work.

## 2026-03-20
### named generated children may now default their source name locally in composition
- Updated [perl/FSM/Composition/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Parser.pm) so named `?fsmc:name` and `?dtc:name` children may now omit the explicit child-source token and default it to `name`, while unnamed generated children still fail as before.
- Added [t/135-composition-generated-child-default-source-names.t](/Users/richarddje/Documents/github/fsmgen/t/135-composition-generated-child-default-source-names.t) to lock both embedded named `?fsmc` default-source realization and `--path`-driven named `?dtc` default-source realization.
- Updated [t/130-composition-generated-child-source-shape-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/130-composition-generated-child-source-shape-diagnostics.t) and [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) to retire the old named zero-source failure contract now that that spelling is a shipped feature.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reusable-root/reference composition slice is tracked as shipped `R11` feature work.

### standalone-DT roots now also accept the conventional explicit `+system` contract
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so standalone-DT roots now accept the same conventional `(+system (clock clk) (sreset rstn))` / `(+system (clock clk) (asreset rstn))` section already used by `?fsm:name`, instead of rejecting `+system` outright at the `?dt:name` boundary.
- Added [t/134-standalone-dt-explicit-system-support.t](/Users/richarddje/Documents/github/fsmgen/t/134-standalone-dt-explicit-system-support.t) to lock both direct standalone-DT generation with explicit `clk` / `rstn` and `C1` composition auto-wiring for `?dtc` children that expose those explicit system ports.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reusable-module system-contract slice is tracked as shipped `R11` feature work rather than future-only intent.

### standalone-DT roots now also accept `?mod:name` and `?module:name`
- Updated [perl/FSM/SourceClassifier.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/SourceClassifier.pm), [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm), [perl/FSM/Composition/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Parser.pm), and [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so `?mod:name` and `?module:name` now act as active standalone-DT root aliases beside `?dt:name`.
- Added [t/133-standalone-dt-root-aliases.t](/Users/richarddje/Documents/github/fsmgen/t/133-standalone-dt-root-aliases.t) to lock direct standalone generation, bare-name CLI compilation, and composition `?dtc` child realization across those alias roots.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reusable-module naming slice is tracked as shipped feature work instead of a future naming question.

### composition override/block summaries now keep one example subject per kind
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) and [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) so composition provenance reporting now carries and prints one concise example subject for each shipped override kind and block kind instead of stopping at counts only.
- Updated [t/105-composition-override-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/105-composition-override-reporting.t) and [t/106-composition-blocked-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/106-composition-blocked-reporting.t) to lock both the pipeline-side `composition_report` examples and the non-quiet CLI summary output.
- Updated [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this `R11` reporting refinement is tracked as shipped rather than left as a counts-only gap.

### active CLI help now names `bin/fsmgen` honestly
- Updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) so the built-in help and missing-argument usage now name the active `./bin/fsmgen` entrypoint instead of the old `generate_fsm_hdl.pl` wrapper.
- Updated the same help surface so its default-output wording now matches the shipped runtime too: without `-o`, output is written in the current working directory, not a legacy “script directory”.
- Added [t/132-cli-help-wording.t](/Users/richarddje/Documents/github/fsmgen/t/132-cli-help-wording.t) to lock both the `--help` surface and the missing-argument usage branch.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this small remaining `R11` hotspot is tracked as retired instead of ambient debt.

### top-level composition lane and `?ports` shape gates now summarize cleanly
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) and [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) so failed composition summaries now cover the top-level lane/shape gate family explicitly:
  - no-child tops keep the blocked `lane entry` summary without invented construct/context,
  - and blocked multiple-`?ports`, omitted-`?ports`, and empty-`?ports` tops now keep `Construct: ?ports` with the blocked `shape` boundary.
- This keeps the slice narrow and honest:
  - planner and parser behavior are unchanged,
  - the runtime change is limited to failed-run summary extraction and concise-reason trimming for the already-shipped top-level lane/shape diagnostics,
  - and the new coverage proves those runs no longer misclassify the shape-gate family as `?toplink` just because the raw diagnostic mentions the explicit-link `C2/C3` inference exception.

### named generated-child parser summaries are now symmetric across count and shape failures
- Updated [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) so the named generated-child parser-summary family is now fully locked across both parser boundaries too:
  - named `?fsmc` source-count and source-shape failures,
  - named `?dtc` source-count and source-shape failures.
- This keeps the slice narrow and honest:
  - runtime extractor behavior is unchanged,
  - parser behavior is unchanged,
  - and the new coverage proves that non-quiet CLI failures keep `Construct: ?fsmc` plus `Context: Child 'child'` and `Construct: ?dtc` plus `Context: Child 'child'` consistently across both count and shape branches.

### blocked nested `?ports` and `?toplink` items now keep child context in CLI summaries
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) and [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) so failed composition summaries now preserve the nested child-block identity for the parser flatness family instead of showing only construct + boundary.
- This keeps the slice narrow and honest:
  - parser behavior is unchanged,
  - the only runtime change is summary extraction for the already-shipped nested `?ports` and nested `?toplink` diagnostics,
  - and the new coverage proves that non-quiet CLI failures preserve `Context: Child '?ports'` for blocked port-declaration flatness and `Context: Child '?toplink'` for blocked explicit top-link token flatness.

### blocked empty child entries and non-string child headers now keep child-entry context in CLI summaries
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) and [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) so failed composition summaries now recognize the top-level child-structure parser family as child-entry context instead of leaving it context-free.
- This keeps the slice narrow and honest:
  - parser behavior is unchanged,
  - the only runtime change is summary extraction for the already-shipped empty-child-entry and non-string-child-header diagnostics,
  - and the new coverage proves that non-quiet CLI failures preserve `Context: Child entry 'missing header'` for blocked child-structure failures and `Context: Child entry 'non-string header'` for blocked child-header-shape failures, while correctly avoiding any invented `Construct:` line.

## 2026-03-19
### unnamed generated-child parser summaries are now symmetric across count and shape failures
- Updated [t/130-composition-generated-child-source-shape-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/130-composition-generated-child-source-shape-diagnostics.t) and [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) so the unnamed generated-child parser-summary family is now fully locked across both parser boundaries:
  - unnamed `?fsmc` source-count and source-shape failures,
  - unnamed `?dtc` source-count and source-shape failures.
- This keeps the slice narrow and honest:
  - runtime extractor behavior is unchanged,
  - parser behavior is unchanged,
  - and the new coverage proves that non-quiet CLI failures keep `Construct: ?fsmc` plus `Context: Child '?fsmc'` and `Construct: ?dtc` plus `Context: Child '?dtc'` consistently across both count and shape branches.

### blocked unnamed generated-child parser failures now keep child context in CLI summaries
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm), [t/130-composition-generated-child-source-shape-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/130-composition-generated-child-source-shape-diagnostics.t), and [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) so failed composition summaries now recognize blocked parser diagnostics of the form `contains '?fsmc' child without a name` / `contains '?dtc' child without a name` as child context instead of dropping child identity entirely.
- This keeps the slice narrow and honest:
  - parser behavior is unchanged,
  - the only runtime change is summary extraction for two already-shipped generated-child parser families,
  - and the new coverage proves that non-quiet CLI failures preserve `Construct: ?fsmc` plus `Context: Child '?fsmc'` for unnamed source-count failures and `Construct: ?dtc` plus `Context: Child '?dtc'` for unnamed source-shape failures.

### blocked explicit-link duplicate-driver failures now keep target context in CLI summaries
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) and [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) so failed composition summaries now recognize `assigns explicit link driver '...' to target '...'` diagnostics as target context instead of leaving that conflict point only in the raw exception text.
- This keeps the slice narrow and honest:
  - planner behavior is unchanged,
  - the only runtime change is summary extraction for an already-shipped explicit-link conflict family,
  - and the new coverage proves that non-quiet CLI failures preserve `Construct: ?toplink`, `Context: Top port 'result_data'`, the blocked `explicit link` boundary, and the concise duplicate-driver reason.

### blocked explicit-link top-port role mismatches now keep top-port context in CLI summaries
- Updated [t/23-composition-errors.t](/Users/richarddje/Documents/github/fsmgen/t/23-composition-errors.t) and [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) so the existing failed-run summary path is now explicitly locked for the reachable explicit-link family where a declared top port is used with the wrong role.
- This keeps the slice narrow and honest:
  - behavior is unchanged,
  - the extractor already knew how to classify `uses top port '...'` diagnostics as `Top port` context,
  - and the new coverage simply proves that non-quiet CLI failures preserve `Construct: ?toplink`, `Context: Top port 'result_data'`, the blocked `explicit link` boundary, and the concise `that top port is declared as output instead of input` reason.

### blocked explicit-link direction mismatches now keep child-endpoint context in CLI summaries
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) and [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) so failed composition summaries now recognize `uses child endpoint '...'` diagnostics as `Child endpoint` context instead of leaving that token only in the raw exception text.
- This keeps the slice narrow and honest:
  - planner behavior is unchanged,
  - the only runtime change is summary extraction for an already-shipped explicit-link failure family,
  - and the new coverage proves that non-quiet CLI failures preserve `Construct: ?toplink`, `Context: Child endpoint 'uart_tx.txd'`, the blocked `explicit link` boundary, and the concise `that child port is output instead of input` reason.

### blocked existing-instance missing-port explicit-link failures now keep child-endpoint context in CLI summaries
- Updated [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) so the existing failed-run summary path is now explicitly locked for the reachable explicit-link endpoint-resolution family where the child instance exists but the named child port does not.
- This keeps the slice narrow and honest:
  - behavior is unchanged,
  - the extractor already knew how to preserve `Child endpoint 'uart_tx.missing_port'`,
  - and the new coverage simply proves that non-quiet CLI failures preserve `Construct: ?toplink`, `Context: Child endpoint 'uart_tx.missing_port'`, the blocked `explicit link endpoint resolution` boundary, and the concise `instance 'uart_tx' has no port named 'missing_port'` reason.

### blocked missing top-level explicit-link endpoint failures now keep top-endpoint context in CLI summaries
- Updated [t/23-composition-errors.t](/Users/richarddje/Documents/github/fsmgen/t/23-composition-errors.t) and [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) so the existing failed-run summary path is now explicitly locked for the reachable missing top-level explicit-link endpoint family too.
- This keeps the slice narrow and honest:
  - behavior is unchanged,
  - the extractor already knew how to classify `references top-level endpoint '...'` as `Top endpoint` context,
  - and the new coverage simply proves that non-quiet CLI failures preserve `Construct: ?toplink`, `Context: Top endpoint 'missing_top'`, the blocked `explicit link endpoint resolution` boundary, and the concise `'?ports' declares no top port with that name` reason.

### blocked unsupported explicit-endpoint syntax now stays visible in CLI failure summaries
- Updated [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) so the existing failed-run summary path is now explicitly locked for the reachable unsupported explicit-endpoint syntax family too.
- This keeps the slice narrow and honest:
  - behavior is unchanged,
  - the summary already knew how to expose `?toplink` plus endpoint context,
  - and the new coverage simply proves that non-quiet CLI failures preserve the unsupported endpoint token and concise “that syntax is unsupported” reason without relying only on the raw exception text.

### blocked shared-system-port `=port` failures now keep concise system-contract reasons in CLI summaries
- Updated [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) so the existing failed-run summary path is now explicitly locked for the reachable shared-system-port declared connect-by-name family too.
- This keeps the slice narrow and honest:
  - behavior is unchanged,
  - the summary already knew how to show `=port` plus top-port context,
  - and the new coverage simply proves that non-quiet CLI failures preserve the concise dedicated-system-input-contract reason without inventing a `Lane:` line the raw diagnostic does not actually provide.

### blocked incompatible-direction `C4` declared connect-by-name failures now keep endpoint sets in CLI summaries
- Updated [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) so the existing failed-run summary path is now explicitly locked for a reachable incompatible-direction `C4` declared connect-by-name family at CLI level too.
- This keeps the slice narrow and honest:
  - behavior is unchanged,
  - the extractor already knew how to keep the blocked `=port` top-port context and conflicting same-name endpoint set,
  - and the new coverage simply proves that non-quiet CLI failures preserve the endpoint evidence in the concise `Reason:` line for same-name direction conflicts too.

### blocked width-mismatch `C4` declared connect-by-name failures now keep endpoint sets in CLI summaries
- Updated [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) so the existing failed-run summary path is now explicitly locked for a reachable width-mismatch `C4` declared connect-by-name family at CLI level too.
- This keeps the slice narrow and honest:
  - behavior is unchanged,
  - the extractor already knew how to keep the blocked `=port` top-port context and conflicting same-name endpoint set,
  - and the new coverage simply proves that non-quiet CLI failures preserve the endpoint evidence in the concise `Reason:` line instead of collapsing it to only the declared-width mismatch.

### blocked ambiguous `C4` declared connect-by-name failures now keep candidate lists in CLI summaries
- Updated [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) so the existing failed-run summary path is now explicitly locked for a reachable ambiguous `C4` declared connect-by-name family at CLI level too.
- This keeps the slice narrow and honest:
  - behavior is unchanged,
  - the extractor already knew how to keep the blocked `=port` top-port context and ambiguous same-name reason,
  - and the new coverage simply proves that non-quiet CLI failures preserve the compatible-child-endpoint list in the concise `Reason:` line instead of leaving it only in the raw exception text.

### blocked `C4` declared connect-by-name failures now keep `Lane: C4` and `=port` context in CLI summaries
- Updated [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) so the existing failed-run summary path is now explicitly locked for a reachable `C4` declared connect-by-name family at CLI level too.
- This keeps the slice narrow and honest:
  - behavior is unchanged,
  - the extractor already knew how to surface `C4`, `=port`, and top-port context from blocked declared connect-by-name diagnostics,
  - and the new coverage simply proves that non-quiet CLI failures preserve `Lane: C4`, `Construct: =port`, `Context: Top port 'missing_port'`, and the concise missing-endpoint reason.

### blocked `C2` lane-selection failures now keep `Lane: C2` in CLI summaries
- Updated [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) so the existing failed-run summary path is now explicitly locked for the reachable `C2` lane-selection family at CLI level too.
- This keeps the slice narrow and honest:
  - behavior is unchanged,
  - the lane extractor already knew how to surface `C2`,
  - and the new coverage simply proves that non-quiet CLI failures preserve both `Lane: C2` and the concise blocked lane-selection reason for one-generated-child explicit-link tops.

### blocked `C1` exposure failures now keep top-port and child-port context in CLI summaries
- Updated [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) so the existing failed-run summary path is now explicitly locked for the reachable `C1` exposure families at CLI level too:
  - blocked top-port mismatch keeps `Context: Top port 'output_data'`,
  - and blocked omitted-child-port exposure keeps `Context: Child port 'output_data'`.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the pipeline-side extraction for those contexts was already in place,
  - and the new coverage simply proves that the same concise context survives through the non-quiet CLI summary surface.
- Focused validation covered [t/23-composition-errors.t](/Users/richarddje/Documents/github/fsmgen/t/23-composition-errors.t) beside the updated [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t), then [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) were updated so this coverage is preserved as an explicit `R11` reporting refinement.

### future note logged: high-leverage syntax-power direction should stay bounded and RTL-focused
- Updated [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the recent design discussion is now preserved as future language guidance instead of conversation-only memory.
- The saved direction is:
  - the highest-leverage future additions are aggregate types with inference, interface bundles, enum-first match/case capture, small alias/default forms, bounded replication, intent helpers, assertions, and stronger explain/report mode,
  - the language should stay convention-first, terse, portable, and readable,
  - and if a future generic/meta-programming lane exists at all, it should be a very small semantic RTL layer, not a broad macro/template system.

### `.rtlif` width/type failures now keep token context in failed-run summaries
- Updated [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) so the already-supported token-summary path is now explicitly locked for blocked `.rtlif` port-sizing and port-typing failures too, not just token-shape failures.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the resolved `.rtlif` path still stays the primary `RTL metadata file:` artifact line,
  - and the new regression coverage proves that `Context: Token '...'` and the concise `Reason:` line survive the same summary path across invalid-token, non-positive-width, and unsupported-type families.
- Updated [t/119-composition-rtlif-type-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/119-composition-rtlif-type-diagnostics.t), [t/120-composition-rtlif-token-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/120-composition-rtlif-token-diagnostics.t), [t/121-composition-rtlif-width-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/121-composition-rtlif-width-diagnostics.t), and [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) together in focused validation, then updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this coverage is preserved as an explicit `R11` reporting refinement.

### future note logged: Rust FSMGen should likely start in the same repository
- Updated [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the recent Rust-brainstorming exchange is now tracked explicitly as horizon guidance.
- The saved direction is:
  - a Rust implementation remains a long-term `H1` goal rather than an active lane,
  - it is expected to be faster in practice but should be treated as a second implementation of a stable contract rather than a line-by-line rewrite,
  - and its first serious execution path should likely live in this same repository beside the Perl reference implementation so both versions can share one roadmap, one corpus, one diagnostics contract, and one differential-test story before any later split is considered.

### flatness `.rtlif` failures now keep RTL root context in failed-run summaries
- Updated [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) so the already-supported `RTL root` summary path is now explicitly locked for blocked `.rtlif` flatness failures too, alongside the existing missing-root and empty-port root-scoped cases.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the resolved `.rtlif` path still stays the primary `RTL metadata file:` artifact line,
  - and the flatness summary now proves that `Context: RTL root '?rtlif:uart_tx'` and `Reason: contains nested structure under '?rtlif:uart_tx'` survive the same summarization path cleanly.
- Updated [t/124-composition-rtlif-flatness-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/124-composition-rtlif-flatness-diagnostics.t) and [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) together in focused validation, then updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this coverage is preserved as an explicit `R11` reporting refinement.

### file-based `.rtlif` root failures now keep RTL root context in failed-run summaries
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so failed composition summaries now keep `Context: RTL root '?rtlif:...'` for file-based root-scoped `.rtlif` failures when the blocked diagnostic already names the active root token, including missing-root and empty-port cases.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the summary still keeps the resolved `.rtlif` path as the primary `RTL metadata file:` artifact line,
  - and the new root-context extraction only appears when the raised diagnostic already exposes a stable `?rtlif:<module>` token.
- Updated [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) to lock both the pipeline-side failure-report extraction and the non-quiet CLI summary for blocked file-based root-scoped `.rtlif` failures, including the existing missing-root path plus the empty-port path.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the next bounded failed-run reporting refinement under `R11`.

### embedded `.rtlif` duplicate-root failures now keep RTL root context in failed-run summaries
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so failed composition summaries now keep `Context: RTL root '?rtlif:...'` when a blocked embedded `.rtlif` duplicate-root diagnostic already names the repeated embedded root token.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the summary still does not invent an `RTL metadata file:` artifact line for embedded-root failures because the metadata lives in the composition source itself,
  - and the new context extraction only appears when the raised diagnostic already exposes a stable embedded root token such as `?rtlif:uart_tx`.
- Updated [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) to lock both the pipeline-side failure-report extraction and the non-quiet CLI summary for blocked embedded `.rtlif` duplicate-root failures, including `Construct: ?rtl`, `Context: RTL root '?rtlif:uart_tx'`, `Blocked boundary: RTL interface metadata embedded-root uniqueness`, and the concise embedded-root uniqueness reason.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the next bounded failed-run reporting refinement under `R11`.

### duplicate-port `.rtlif` failures now keep repeated RTL port context in failed-run summaries
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so failed composition summaries now keep `Context: RTL port '...'` when a blocked external `.rtlif` declaration failure repeats a port name while the same summary is already surfacing the resolved `RTL metadata file:` artifact line.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - duplicate-port `.rtlif` failures still keep the resolved metadata file as the primary artifact line,
  - and the new context extraction only appears when the raised diagnostic already exposes a stable repeated port name such as `txd`.
- Updated [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) to lock both the pipeline-side failure-report extraction and the non-quiet CLI summary for blocked duplicate-port `.rtlif` failures, including `RTL metadata file:`, `Context: RTL port 'txd'`, `Blocked boundary: RTL interface metadata port declaration uniqueness`, and `Reason: repeats port 'txd'`.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the next bounded failed-run reporting refinement under `R11`.

## 2026-03-18
### non-quiet failed composition runs now print a first bounded failure summary
- Updated [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm) so blocked `.rtlif` token-shape, port-sizing, and port-typing diagnostics now name the declaring metadata file directly instead of only naming the offending token.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the pipeline can derive a small composition failure report from blocked composition diagnostics, including the failing top name or external RTL module when available, the active `C1` / `C2` / `C3` / `C4` lane when the raised diagnostic names it, the active syntax construct when the blocked diagnostic points clearly at one such as `?ports`, `?toplink`, `?rtl`, `?fsmc`, `?dtc`, or `=port`, a generated-child source-file artifact line when a blocked `?fsmc` / `?dtc` realization failure names the resolved external `.fsm` file, an external RTL metadata-file artifact line when a blocked `.rtlif` structure, token, sizing, typing, flatness, or declaration failure names the resolved metadata file, plus one concise context subject such as the offending child header, top port, explicit endpoint, or token, alongside the blocked boundary label and a concise blocked-reason excerpt.
- Updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) so non-quiet failed composition runs now print a first bounded `=== Composition Failure Summary ===` section with `Lane:`, `Construct:`, `Child source file:`, `RTL metadata file:`, `Context:`, and `Reason:` lines when those details can be extracted honestly before re-raising the original error.
- This shipped slice stays deliberately narrow:
  - quiet-mode failure behavior is unchanged,
  - the original exception text still surfaces unchanged after the summary,
  - and the new summary only appears when the raised diagnostic exposes a blocked composition boundary the CLI can classify honestly.
- Added [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) to lock both the pipeline-side failure-report extraction and the non-quiet CLI summary for blocked composition failures, including concise reason extraction for parser-scoped, `.rtlif`, and generated-child realization failures, concise subject extraction for unsupported-child, top-port, explicit-link endpoint, and `.rtlif` token failures, generated-child source-file extraction for wrong-kind `?fsmc` realization failures, external RTL metadata-file extraction for blocked `.rtlif` structure and token failures, lane extraction for `C1`- and `C3`-scoped failures, and construct extraction for `?ports`, `?rtl`, `?fsmc`, and `?toplink` while still avoiding invented construct summaries for unsupported child headers.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the first bounded move from pure exception text into richer failed-run composition reporting.

### malformed generated-child source payloads now say source shape/count is blocked
- Updated [perl/FSM/Composition/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Parser.pm) so malformed `?fsmc` / `?dtc` payloads now say blocked generated-child source-shape or source-count failures when nested option structures appear or when the wrong number of flat source names is declared.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the offending child kind, child name, and source-count context still appear in the exception text,
  - and the wording now lines up with the rest of the active blocked diagnostics lane.
- Added [t/130-composition-generated-child-source-shape-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/130-composition-generated-child-source-shape-diagnostics.t) to lock those diagnostics through both pipeline and CLI entrypoints, and updated [t/14-composition-parser.t](/Users/richarddje/Documents/github/fsmgen/t/14-composition-parser.t) so the direct parser checks now cover both nested-payload and wrong-count branches for `?fsmc` and `?dtc`.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the next bounded failure-path wording slice under `R11`.

### unsupported composition child kinds now say child-kind support is blocked
- Updated [perl/FSM/Composition/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Parser.pm) so unsupported composition child kinds now say composition child-kind support is blocked instead of using the older raw “unsupported child” wording.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the offending child header still appears in the exception text,
  - and the wording now lines up with the rest of the active blocked diagnostics lane.
- Added [t/129-composition-unsupported-child-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/129-composition-unsupported-child-diagnostics.t) to lock that diagnostic through both pipeline and CLI entrypoints, and updated [t/25-composition-legacy-scope-errors.t](/Users/richarddje/Documents/github/fsmgen/t/25-composition-legacy-scope-errors.t) so the direct parser check expects the same wording.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the next bounded failure-path wording slice under `R11`.

### malformed composition child entries now say child structure is blocked
- Updated [perl/FSM/Composition/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Parser.pm) so malformed composition child entries now say blocked child-structure failures for empty child entries, non-string child headers, and dotted-pair child payloads.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the malformed child-entry context still appears in the exception text,
  - and the wording now lines up with the rest of the active blocked diagnostics lane while also retiring the old undef-header warning path.
- Added [t/128-composition-child-structure-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/128-composition-child-structure-diagnostics.t) to lock those malformed child-entry diagnostics through both pipeline and CLI entrypoints.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the next bounded failure-path wording slice under `R11`.

### future note logged: `?toplink` naming may later gain a clearer alias
- Updated [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the recent design discussion is now tracked explicitly:
  - `?toplink` is acceptable but not ideal from a naming/ergonomics point of view,
  - a future syntax-cleanup pass may decide whether to keep it canonical or add a clearer preferred alias such as `?wiring`,
  - and that decision is now recorded as future work rather than left as conversation residue.

### legacy `?ports` mapping directives now say port declaration mode is blocked
- Updated [perl/FSM/Composition/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Parser.pm) so legacy `?ports` mapping directives like `/foo/bar/` now say composition port declaration mode is blocked instead of using the older raw wording.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the offending mapping directive still appears in the exception text,
  - and the wording now lines up with the rest of the active blocked diagnostics lane.
- Added [t/127-composition-ports-mapping-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/127-composition-ports-mapping-diagnostics.t) to lock that diagnostic through both pipeline and CLI entrypoints, and updated [t/25-composition-legacy-scope-errors.t](/Users/richarddje/Documents/github/fsmgen/t/25-composition-legacy-scope-errors.t) so the direct parser check expects the same wording.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the task and the future naming note are both preserved in the live continuity trail.

### malformed `?ports` and `?toplink` parser items now say parser token boundaries are blocked
- Updated [perl/FSM/Composition/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Parser.pm) so malformed composition parser items now say blocked token-boundary failures for nested `?ports`, invalid `?ports` tokens, non-positive `?ports` widths, nested `?toplink` items, and unsupported `?toplink` tokens.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the offending parser token or nested block context still appears in the exception text,
  - and the wording now lines up with the rest of the active blocked diagnostics lane.
- Added [t/126-composition-parser-token-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/126-composition-parser-token-diagnostics.t) to lock those parser token-boundary diagnostics through both pipeline and CLI entrypoints.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the next bounded failure-path wording slice under `R11`.

### duplicate embedded `.rtlif` roots now say embedded-root uniqueness is blocked
- Updated [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm) so composition sources with multiple embedded `?rtlif:<module>` roots for the same external RTL child now say embedded-root uniqueness is blocked.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the duplicate embedded root family and active source path still appear in the exception text,
  - and the wording now lines up with the rest of the active blocked diagnostics lane.
- Added [t/125-composition-embedded-rtlif-duplicate-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/125-composition-embedded-rtlif-duplicate-diagnostics.t) to lock blocked wording for duplicate embedded `.rtlif` roots through both pipeline and CLI entrypoints, and updated [t/89-composition-embedded-rtlif-roots.t](/Users/richarddje/Documents/github/fsmgen/t/89-composition-embedded-rtlif-roots.t) so the direct loader check expects the same wording.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the next bounded failure-path wording slice under `R11`.

### nested `.rtlif` metadata now says flatness is blocked
- Updated [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm) so external RTL interface metadata now says flatness is blocked when a reachable `.rtlif` file contains nested structure under the required `?rtlif:<module>` root.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the nested root context and metadata path still appear in the exception text,
  - and the wording now lines up with the rest of the active blocked diagnostics lane.
- Added [t/124-composition-rtlif-flatness-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/124-composition-rtlif-flatness-diagnostics.t) to lock blocked wording for nested external `.rtlif` metadata through both pipeline and CLI entrypoints.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the next bounded failure-path wording slice under `R11`.

### empty `.rtlif` interfaces now say metadata port presence is blocked
- Updated [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm) so external RTL interface metadata now says port presence is blocked when a reachable `.rtlif` file declares no ports under the required `?rtlif:<module>` root.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the empty root and metadata path still appear in the exception text,
  - and the wording now lines up with the rest of the active blocked diagnostics lane.
- Added [t/123-composition-rtlif-empty-port-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/123-composition-rtlif-empty-port-diagnostics.t) to lock blocked wording for empty external `.rtlif` interfaces through both pipeline and CLI entrypoints.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the next bounded failure-path wording slice under `R11`.

### duplicate `.rtlif` ports now say declaration uniqueness is blocked
- Updated [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm) so external RTL interface metadata now says port declaration uniqueness is blocked when a reachable `.rtlif` file repeats the same port name.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the repeated port name and metadata path still appear in the exception text,
  - and the wording now lines up with the rest of the active blocked diagnostics lane.
- Added [t/122-composition-rtlif-duplicate-port-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/122-composition-rtlif-duplicate-port-diagnostics.t) to lock blocked wording for duplicate external `.rtlif` ports through both pipeline and CLI entrypoints.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the next bounded failure-path wording slice under `R11`.

### non-positive `.rtlif` widths now say metadata port sizing is blocked
- Updated [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm) so external RTL interface metadata now says port sizing is blocked when a reachable `.rtlif` token declares a non-positive explicit width such as `0`.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the offending token and non-positive width still appear in the exception text,
  - and the wording now lines up with the rest of the active blocked diagnostics lane.
- Added [t/121-composition-rtlif-width-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/121-composition-rtlif-width-diagnostics.t) to lock blocked wording for non-positive external `.rtlif` widths through both pipeline and CLI entrypoints.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the next bounded failure-path wording slice under `R11`.

### invalid `.rtlif` port tokens now say metadata token shape is blocked
- Updated [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm) so external RTL interface metadata now says token shape is blocked when a reachable `.rtlif` token is syntactically invalid for the current flat port-token contract.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the offending token and active module name still appear in the exception text,
  - and the wording now lines up with the rest of the active blocked diagnostics lane.
- Added [t/120-composition-rtlif-token-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/120-composition-rtlif-token-diagnostics.t) to lock blocked wording for invalid external `.rtlif` port tokens through both pipeline and CLI entrypoints.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the next bounded failure-path wording slice under `R11`.

## 2026-03-17
### unsupported `.rtlif` port types now say metadata typing is blocked
- Updated [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm) so external RTL interface metadata now says port typing is blocked when a reachable `.rtlif` token resolves to an unsupported explicit type such as `status`.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the offending token and unsupported type still appear in the exception text,
  - and the wording now lines up with the rest of the active blocked diagnostics lane.
- Added [t/119-composition-rtlif-type-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/119-composition-rtlif-type-diagnostics.t) to lock blocked wording for unsupported external `.rtlif` port types through both pipeline and CLI entrypoints.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the next bounded failure-path wording slice under `R11`.

### external `.rtlif` files without the expected root now say metadata structure is blocked
- Updated [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm) so external RTL interface metadata now says structure is blocked when a reachable `.rtlif` file does not contain the required `?rtlif:<module>` root for that `?rtl` child.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the active module name and metadata path still appear in the exception text,
  - and the wording now lines up with the rest of the active blocked diagnostics lane.
- Added [t/118-composition-rtlif-root-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/118-composition-rtlif-root-diagnostics.t) to lock blocked wording for wrong-root or garbage external `.rtlif` metadata through both pipeline and CLI entrypoints.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the next bounded failure-path wording slice under `R11`.

### missing external `.rtlif` metadata now says resolution is blocked
- Updated [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm) so missing external RTL interface metadata now says resolution is blocked when no declared `uart_tx.rtlif`-style metadata can be found for a `?rtl` child.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the search-root evidence still appears in the exception text,
  - and the wording now lines up with the rest of the active blocked diagnostics lane.
- Added [t/117-composition-rtlif-metadata-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/117-composition-rtlif-metadata-diagnostics.t) to lock blocked wording for missing external `.rtlif` metadata through both pipeline and CLI entrypoints.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the next bounded failure-path wording slice under `R11`.

### blocked `C2` lane selection now says so explicitly
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so one-generated-child explicit-link tops now say `C2` lane selection is blocked when they do not satisfy the minimum two-generated-child `C2` shape.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the existing `C2` minimum-shape rule is unchanged,
  - and the wording now lines up with the rest of the active blocked diagnostics lane.
- Added [t/116-composition-c2-lane-selection-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/116-composition-c2-lane-selection-diagnostics.t) to lock blocked wording for one-generated-child explicit-link tops through both pipeline and CLI entrypoints.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the next bounded failure-path wording slice under `R11`.

### generated child-source failures now say resolution or realization is blocked
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so external `?fsmc` / `?dtc` lookup failures now say child-source resolution is blocked when no active child source can be found, and wrong-kind resolved child files now say child-source realization is blocked when they are rooted under the wrong active source kind.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the resolved path, detected root, and search-root evidence still appear in the exception text,
  - and wrong-kind `?fsmc` / `?dtc` failures now point users to the correct shipped child kind instead of leaving an outdated roadmap-era hint in place.
- Added [t/115-composition-child-source-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/115-composition-child-source-diagnostics.t) to lock missing-child, wrong-kind-`?fsmc`, and wrong-kind-`?dtc` wording across pipeline and CLI entrypoints.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the next bounded failure-path wording slice under `R11`.

### unsupported composition backend targets now say target support is blocked
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so valid composition sources now say composition target support is blocked when they request a backend outside the currently emitted SystemVerilog/Verilog composition lanes.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the requested target language still appears in the exception text,
  - and the wording now lines up with the rest of the active blocked diagnostics lane.
- Added [t/114-composition-target-support-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/114-composition-target-support-diagnostics.t) to lock unsupported composition backend target wording through both pipeline and CLI entrypoints.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the next bounded failure-path wording slice under `R11`.

### endpoint-shape diagnostics now say when binding is blocked
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so reserved-system `=name` declarations and unsupported explicit endpoint syntax now say binding is blocked when those endpoint-shape errors make the composition contract invalid.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the same endpoint detail still appears in the exception text,
  - and the wording now lines up with the rest of the active blocked diagnostics lane.
- Added [t/113-composition-endpoint-shape-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/113-composition-endpoint-shape-diagnostics.t) to lock reserved-system `=name` and unsupported explicit endpoint syntax wording.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the next bounded failure-path wording slice under `R11`.

### duplicate composition declarations now say when shape is blocked
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so duplicate top-port and duplicate child-instance declaration failures now say composition shape is blocked when those declarations make planning ambiguous.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the same duplicate declaration detail still appears in the exception text,
  - and the wording now lines up with the rest of the active blocked diagnostics lane.
- Added [t/112-composition-duplicate-declaration-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/112-composition-duplicate-declaration-diagnostics.t) to lock duplicate top-port and duplicate child-instance wording.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the next bounded failure-path wording slice under `R11`.

### `C1` passthrough exposure failures now say when exposure is blocked
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so `C1` passthrough exposure failures now say exposure is blocked when explicit top exposure omits a realized child port or disagrees with the realized child interface on name, width, or direction.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the same child-port detail still appears in the exception text,
  - and the wording now lines up with the rest of the active blocked diagnostics lane.
- Added [t/111-composition-c1-port-exposure-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/111-composition-c1-port-exposure-diagnostics.t) to lock missing-exposure, unknown-port, width-mismatch, and direction-mismatch wording for the public `C1` exposure contract.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the next bounded failure-path wording slice under `R11`.

### top-level composition lane and shape gates now say they are blocked
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so top-level composition lane/shape gates now say they are blocked when no child instances exist, when `?ports` multiplicity is invalid, or when omitted/empty `?ports` appears outside the bounded inference cases.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the same top-level composition context still appears in the exception text,
  - and the wording now lines up with the rest of the active blocked diagnostics lane.
- Updated [t/13-composition-source-classification.t](/Users/richarddje/Documents/github/fsmgen/t/13-composition-source-classification.t) and added [t/110-composition-shape-gate-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/110-composition-shape-gate-diagnostics.t) to lock the no-child, multi-`?ports`, omitted-`?ports`, and empty-`?ports` blocked wording.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the next bounded failure-path wording slice under `R11`.

### explicit-link lane-entry and topology failures now say they are blocked
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so explicit-link lane-entry and topology failures now say they are blocked when explicit-link lanes are entered without `?toplink`, when top inputs try to drive top outputs directly, or when one source tries to drive multiple top outputs.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the same endpoint/source detail still appears in the exception text,
  - and the wording now lines up with the rest of the active blocked diagnostics lane.
- Added [t/109-composition-explicit-link-topology-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/109-composition-explicit-link-topology-diagnostics.t) to lock missing-`?toplink`, top-input-to-top-output, and multi-top-output-source diagnostics.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the next bounded failure-path wording slice under `R11`.

### explicit-link unwired-port failures now say wiring is blocked
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so explicit-link unwired-port failures now say wiring is blocked when declared top ports or realized child ports remain unwired in explicit-link lanes.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the same top-port or child-port detail still appears in the exception text,
  - and the wording now lines up with the rest of the active blocked diagnostics lane.
- Added [t/108-composition-explicit-link-wiring-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/108-composition-explicit-link-wiring-diagnostics.t) to lock unused declared top-input, unused declared top-output, and unconnected realized-child-port diagnostics.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the next bounded failure-path wording slice under `R11`.

### explicit toplink validation failures now say when the declared link is blocked
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so explicit `?toplink` validation failures now say the declared link is blocked when endpoint resolution, direction, duplicate-drive, or width evidence prevents the declared link from applying.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the same endpoint/detail evidence still appears in the exception text,
  - and the wording now lines up with the other convention-first and explicit-link diagnostics we have already shipped.
- Updated [t/23-composition-errors.t](/Users/richarddje/Documents/github/fsmgen/t/23-composition-errors.t) to lock blocked wording across duplicate-driver, width-mismatch, unknown-endpoint, and direction-mismatch explicit-link failures.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the next bounded failure-path wording slice under `R11`.

### explicit top-output re-export mismatches now say when re-export is blocked
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so explicit top-output re-export mismatches for inferred same-name internal carriers now say that bounded re-export path is blocked when width or interface type disagrees.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the resolved child-side width/type still appears in the exception text,
  - and the wording now lines up with the rest of the convention-first blocked diagnostics.
- Expanded [t/100-composition-internal-carrier-top-reexport.t](/Users/richarddje/Documents/github/fsmgen/t/100-composition-internal-carrier-top-reexport.t) to lock both width-mismatch and type-mismatch blocked wording for explicit top-output re-export.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the next bounded failure-path wording slice under `R11`.

### declared connect-by-name failures now say when the declared match is blocked
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so declared `=name` connect-by-name failures now say the declared match is blocked when direction, width, ambiguity, or missing-endpoint evidence prevents the `C4` rule from applying.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the same-name endpoint detail remains in the exception text,
  - and the wording now aligns better with the already-shipped `Convention Blocks` reporting surface.
- Updated [t/24-composition-connect-by-name.t](/Users/richarddje/Documents/github/fsmgen/t/24-composition-connect-by-name.t) and [t/95-composition-connect-by-name-input-fanout.t](/Users/richarddje/Documents/github/fsmgen/t/95-composition-connect-by-name-input-fanout.t) to lock blocked-wording diagnostics across the declared connect-by-name family.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the next bounded failure-path blocked-wording slice under `R11`.

### explicit-toplink top-port inference failures now say when inference is blocked
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so explicit-toplink-driven undeclared top-port inference failures now say the inference path is blocked when direction, width, or type evidence disagrees.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the explicit-link evidence remains in the exception text,
  - and the wording now aligns better with the already-shipped `Convention Blocks` reporting surface.
- Updated [t/101-composition-explicit-link-implicit-ports.t](/Users/richarddje/Documents/github/fsmgen/t/101-composition-explicit-link-implicit-ports.t) to lock mixed-role, width-mismatch, and type-mismatch blocked diagnostics for explicit-toplink-driven undeclared top-port inference.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the next bounded failure-path blocked-wording slice under `R11`.

### undeclared inference failure diagnostics now say when convention is blocked
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so undeclared top-input, undeclared top-output, and undeclared same-name internal-carrier inference failures now say those convention-first paths are blocked instead of only saying they cannot choose a width/type/driver.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the conflicting endpoint detail remains in the exception text,
  - and the wording now aligns better with the already-shipped `Convention Blocks` reporting surface.
- Updated [t/97-composition-implicit-multi-child-inputs.t](/Users/richarddje/Documents/github/fsmgen/t/97-composition-implicit-multi-child-inputs.t), [t/98-composition-implicit-multi-child-outputs.t](/Users/richarddje/Documents/github/fsmgen/t/98-composition-implicit-multi-child-outputs.t), and [t/99-composition-implicit-internal-carriers.t](/Users/richarddje/Documents/github/fsmgen/t/99-composition-implicit-internal-carriers.t) to lock blocked-wording failure diagnostics across those three undeclared inference families.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the next bounded failure-path blocked-wording slice under `R11`.

### plain explicit top-port failure diagnostics now say when convention is blocked
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the plain explicit top-port same-name convention failure paths now say the convention is blocked instead of only implying it.
- This shipped slice stays deliberately narrow:
  - behavior is unchanged,
  - the existing concrete child-endpoint detail remains in the exception text,
  - and the wording now aligns better with the already-shipped `Convention Blocks` reporting surface.
- Added [t/107-composition-blocked-failure-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/107-composition-blocked-failure-diagnostics.t) to lock blocked-wording failure diagnostics for plain explicit top-input and top-output convention.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the first bounded failure-path blocked-wording slice under `R11`.

### composition provenance now reports blocked convention cases too
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so `composition_report` now surfaces the first shipped blocked convention events:
  - explicit child links blocking undeclared top-input inference,
  - explicit child links blocking undeclared top-output inference,
  - and inferred internal carriers staying internal by default.
- Updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) so non-quiet composition runs now print a `Convention Blocks` section when those blocked events are present.
- This shipped slice stays additive:
  - it builds on the earlier provenance summary plus override summary,
  - it also flows the block count through composition `module_info` and `statistics`,
  - and it leaves the next diagnostics gap mainly on the failure-path wording side.
- Added [t/106-composition-blocked-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/106-composition-blocked-reporting.t) to lock:
  - pipeline-side blocked reporting for explicit child links consuming otherwise-inferable top-interface families,
  - pipeline-side blocked reporting for inferred internal carriers kept internal by default,
  - and CLI blocked-summary output.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as the first shipped blocked-case reporting slice under `R11`.

### composition provenance now reports local override events too
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so `composition_report` now surfaces the first shipped override events:
  - explicit toplinks overriding same-name top-input convention,
  - explicit toplinks overriding same-name top-output convention,
  - and explicit top outputs re-exporting inferred internal carriers.
- Updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) so non-quiet composition runs now print a `Convention Overrides` section when those override events are present.
- This shipped slice stays additive:
  - it builds on the earlier provenance summary instead of replacing it,
  - it also flows the override count through composition `module_info` and `statistics`,
  - and it leaves the next diagnostics gap clearly on the “blocked” side.
- Added [t/105-composition-override-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/105-composition-override-reporting.t) to lock:
  - pipeline-side override reporting for explicit toplinks overriding same-name convention,
  - pipeline-side override reporting for explicit top-output re-export of inferred internal carriers,
  - and CLI override-summary output.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this is tracked as a deliberate `R11` reporting slice.

### composition provenance now reaches the result hash and CLI summary
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so composition runs now produce `composition_report`, including top-port and resolved-link provenance counts grouped from the earlier `origin_kind` metadata.
- Updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) so non-quiet composition runs now print:
  - the active composition lane,
  - child/top-port/resolved-link/internal-net counts,
  - and top-port / resolved-link provenance counts.
- This shipped slice is intentionally layered on top of the earlier metadata:
  - it does not replace `composition_plan`,
  - it keeps `origin_kind` / `resolved_links` as the lower-level typed source of truth,
  - and it makes that same information visible to both embedding callers and CLI users.
- Added [t/104-composition-provenance-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/104-composition-provenance-reporting.t) to lock:
  - pipeline-facing `composition_report` counts,
  - and CLI-facing provenance summary output.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as a deliberate user-facing transparency slice instead of an incidental print change.

### typed composition plans now surface first-pass provenance metadata
- Updated [perl/FSM/Composition/Port.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Port.pm), [perl/FSM/Composition/Link.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Link.pm), and [perl/FSM/Composition/Plan.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Plan.pm) so typed composition results can now expose provenance explicitly.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm), [perl/FSM/Composition/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Parser.pm), and [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm) so:
  - top ports expose `origin_kind`,
  - links expose `origin_kind`,
  - and composition plans expose `resolved_links` as the full resolved link set used by planning.
- This shipped slice is intentionally additive:
  - the existing `links` field remains as-is for compatibility,
  - `resolved_links` is the new full planned-link view,
  - and the new provenance values now cover declared explicit ports/links, declared `=name`, inferred passthrough ports/links, explicit-toplink-driven inferred top ports, plain-explicit-port convention links, internal-carrier links/re-exports, and auto system-port links.
- Added [t/103-composition-provenance-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/103-composition-provenance-metadata.t) to lock:
  - parser-side declared provenance,
  - `C1` inferred passthrough provenance,
  - explicit-toplink inferred top-port provenance,
  - and resolved-link provenance for convention and override paths.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this reads as a deliberate transparency contract, not just extra fields.

### explicit-link `C2` / `C3` plain explicit top ports can now reuse same-name convention
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so explicit-link `C2` / `C3` tops may now keep ordinary explicit top-port declarations such as `payload_in<8` or `result_data>8` while still reusing the same-name convention when the child-side evidence stays exact.
- This shipped slice is intentionally bounded:
  - plain explicit top inputs may fan out by same name when compatible child inputs keep one direction plus exact width/type agreement,
  - plain explicit top outputs may adopt one unique same-name top-facing child output when that child-side evidence stays exact,
  - mixed input/output same-name families still flow through the already-shipped internal-carrier rule instead of this new slice,
  - explicit top-boundary links still override that convention locally,
  - mixed-direction plain-input families now fail explicitly,
  - and multi-output plain-output families now fail explicitly.
- Added [t/102-composition-explicit-port-convention.t](/Users/richarddje/Documents/github/fsmgen/t/102-composition-explicit-port-convention.t) to lock:
  - generated-child `C2` success for plain explicit top-input fanout and plain explicit top-output adoption,
  - mixed generated-plus-`?rtl` `C3` success for the same plain-explicit-port convention,
  - mixed-direction rejection for plain explicit top-input convention,
  - and ambiguous same-name output rejection for plain explicit top-output convention.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this now reads as shipped convention-first behavior rather than a future question.

### recorded the current architecture hotspot set for future bounded refactor work
- Saved the current hotspot/refactor snapshot into the live roadmap/continuity docs instead of leaving it as one-off analysis only.
- The recorded future seams are:
  - `FSM::Pipeline::HDLGenerator` still carrying too much composition policy/orchestration/planning surface,
  - `FSM::Synthesis::EnableGraph` still acting as the largest synthesis gravity well,
  - `FSM::HDL::FlattenedDT::Backend::SystemVerilog` still owning too much planning/normalization for a “backend” boundary,
  - the still-implicit bridge between `FSM::CoreAST::*` and `FSM::AST::*`,
  - the unresolved status of `FSM::ExpressionNamer` as either live surface or residue,
  - stale compatibility wording in `bin/fsmgen`,
  - and the global-state shape in `FSM::Debug` ahead of future embedding/API work.
- Updated [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so those seams are now tracked as deliberate future work instead of ambient debt.

### explicit-link `C2` / `C3` can now infer top ports directly from explicit `?toplink`
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so explicit-link tops may now omit `?ports` entirely, or use an empty `(?ports)`, when the missing top boundary can be realized honestly from explicit `?toplink` endpoints themselves.
- This shipped slice is intentionally bounded:
  - it applies to explicit-link `C2` / `C3`,
  - undeclared top endpoints may now be renamed because the explicit links themselves supply the top-boundary names,
  - each undeclared top endpoint still has to keep one consistent direction plus exact width/type agreement across the explicit links that mention it,
  - same-name explicit top-input links still infer the top port declaration without duplicating the already-declared child bindings,
  - and mixed-role undeclared top endpoints still fail explicitly instead of being guessed through.
- Added [t/101-composition-explicit-link-implicit-ports.t](/Users/richarddje/Documents/github/fsmgen/t/101-composition-explicit-link-implicit-ports.t) to lock:
  - generated-child `C2` success with omitted `?ports` and renamed top endpoints,
  - RTL-backed `C3` success with an empty `(?ports)` block and renamed top endpoints,
  - and mixed-role undeclared top-endpoint rejection.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane records this explicit-link omitted/empty-`?ports` slice as shipped behavior.

### explicit-link `C2` / `C3` can now re-export inferred same-name internal carriers through explicit top outputs
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so explicit-link tops can now keep convention-first same-name internal-carrier inference while letting a matching explicit top output adopt and expose that carrier.
- This shipped override is intentionally bounded:
  - it applies only to same-name internal-carrier families that already qualify for inference,
  - the top override must be an output with exact width/type agreement,
  - the carrier still stays internal by default when no such top output is declared,
  - and several same-name child outputs still fail explicitly instead of being guessed through.
- Added [t/100-composition-internal-carrier-top-reexport.t](/Users/richarddje/Documents/github/fsmgen/t/100-composition-internal-carrier-top-reexport.t) to lock:
  - generated-child internal-carrier re-export success in explicit-link `C2`,
  - mixed generated-plus-`?rtl` internal-carrier re-export success in explicit-link `C3`,
  - same-name output ambiguity rejection even with an explicit re-export request,
  - and explicit top-output type-mismatch rejection for re-export.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane records this local-override slice as shipped behavior rather than future intent.

### explicit-link `C2` / `C3` can now infer same-name internal carriers
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so explicit-link tops can now infer internal same-name child-to-child carriers when:
  - no explicit top port of that name exists,
  - no explicit link already touches that name family,
  - exactly one same-name child output remains available,
  - and one or more same-name child inputs remain available.
- This shipped slice is intentionally bounded:
  - it applies to explicit-link `C2` / `C3` tops,
  - inferred carriers stay internal by default instead of being re-exported automatically,
  - and several same-name child outputs still fail explicitly instead of being guessed through.
- Added [t/99-composition-implicit-internal-carriers.t](/Users/richarddje/Documents/github/fsmgen/t/99-composition-implicit-internal-carriers.t) to lock:
  - generated-child internal-carrier fanout success in explicit-link `C2`,
  - mixed generated-plus-`?rtl` internal-carrier success in explicit-link `C3`,
  - and ambiguity rejection for several same-name child outputs feeding the same-name input family.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane now records this bounded internal-carrier slice honestly.

### explicit-link `C2` / `C3` can now infer undeclared unique top outputs
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so explicit-link tops can now infer undeclared top outputs when:
  - exactly one same-name child output remains top-facing,
  - that child output is not already consumed by explicit child-to-child wiring,
  - and the planner can therefore bind it deterministically back to a generated top output.
- This shipped slice is intentionally bounded:
  - it applies to explicit-link `C2` / `C3` tops,
  - it still does not create internal same-name producer-to-consumer carriers automatically,
  - and several same-name top-facing child outputs still fail explicitly instead of being guessed through.
- Added [t/98-composition-implicit-multi-child-outputs.t](/Users/richarddje/Documents/github/fsmgen/t/98-composition-implicit-multi-child-outputs.t) to lock:
  - inferred undeclared unique top-output success in explicit-link `C2`,
  - inferred undeclared unique top-output success in explicit-link `C3`,
  - and ambiguity rejection for several same-name top-facing child outputs.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane now records this bounded top-output inference slice honestly.

### future `R11` now records convention-first inference plus local override control
- Updated [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so future composition work is now governed by an explicit convention-over-configuration rule:
  - convention should remain the primary integration path,
  - explicit port/link declarations should override inference locally rather than forcing full parent-interface restatement,
  - and ambiguity diagnostics should say whether a connection was inferred, blocked, or overridden.
- Updated [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this policy is preserved as continuity guidance for future `R11` work rather than left as conversational context only.

### explicit-link `C2` / `C3` can now infer undeclared top inputs
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so explicit-link multi-child tops can now infer undeclared top inputs when:
  - the same-name child ports are all inputs,
  - they agree exactly on width and type metadata,
  - and they are not already consumed by explicit child-to-child links.
- This shipped slice is intentionally bounded:
  - it infers top inputs only,
  - it applies to explicit-link `C2` / `C3` tops,
  - and it does not yet create undeclared top outputs or internal same-name carriers.
- Added [t/97-composition-implicit-multi-child-inputs.t](/Users/richarddje/Documents/github/fsmgen/t/97-composition-implicit-multi-child-inputs.t) to lock:
  - inferred undeclared shared top-input success in explicit-link `C2`,
  - and width-mismatch rejection for undeclared shared top-input inference.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane now records this bounded multi-child inference slice honestly.

### single-child `C1` can now infer the top interface when `?ports` is omitted or empty
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the single-child `C1` composition lane now accepts either:
  - no `?ports` block at all,
  - or an empty `(?ports)` block,
  - and in that bounded case infers the top interface directly from the lone realized child interface.
- The shipped inference is intentionally narrow:
  - it works only for single-child passthrough,
  - it covers generated children and external `?rtl` children,
  - and it does not yet widen into multi-child inferred carriers or broader undeclared top-interface inference.
- Added [t/96-composition-implicit-single-child-ports.t](/Users/richarddje/Documents/github/fsmgen/t/96-composition-implicit-single-child-ports.t) to lock:
  - omitted-`?ports` single-child `?fsmc` passthrough inference,
  - and empty-`?ports` single-child `?rtl` passthrough inference.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane now records this first undeclared-top-interface slice honestly.

### future `R11` now includes a portable synthesizable-type and inference-first lane
- Updated [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) so `R11` now carries a concrete future sub-lane for portable synthesizable scalar/aggregate types instead of leaving that topic as informal brainstorming.
- The saved future contract now records:
  - a portable type core built around bits/vectors, enums, records, fixed-size arrays, arrays of records, and aliases/subtypes,
  - a strong convention-over-configuration preference for inferring scalar versus aggregate signal and port types from LHS/RHS/member/index usage,
  - a future explicit syntax centered on `(+types ...)`,
  - and phased implementation boundaries from type AST and explicit declarations through inference, member access, exact-type aggregate assignment, and backend-specific conversion helpers.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the future type/inference lane is tracked as explicit `R11` work rather than remembered conversationally only.

### declared top-input `=name` now fans out across matching child inputs
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so declared connect-by-name is now direction-asymmetric at the top boundary:
  - `=name` top outputs still require exactly one matching child output,
  - `=name` top inputs now fan out to all matching child inputs with the same name and width,
  - and mixed-direction or width-mismatched same-name candidates now fail explicitly instead of being ignored.
- Added [t/95-composition-connect-by-name-input-fanout.t](/Users/richarddje/Documents/github/fsmgen/t/95-composition-connect-by-name-input-fanout.t) to lock:
  - top-input fanout success across multiple same-name child inputs,
  - and mixed-direction same-name rejection for declared top-input connect-by-name.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), [CHANGES.md](/Users/richarddje/Documents/github/fsmgen/CHANGES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane now describes the asymmetric by-name rule honestly.

### declared connect-by-name `C4` now covers multi-generated-plus-`?rtl` tops too
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so `C4` no longer stops after one generated child when external RTL already participates in the by-name plan. The active `C4` contract now accepts one or more generated children, one or more `?rtl` children, or any mixture of those generated and external RTL children under the same exact-match rule.
- Added [t/94-composition-multi-generated-plus-rtl-connect-by-name.t](/Users/richarddje/Documents/github/fsmgen/t/94-composition-multi-generated-plus-rtl-connect-by-name.t) to lock the first multi-generated-plus-`?rtl` declared connect-by-name `C4` success path.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane now records the broader `C4` truthfully.

### explicit-link `C3` now covers multi-generated-plus-`?rtl` tops too
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so `C3` no longer stops after one generated child whenever external RTL already participates in the explicit-link plan. The active `C3` contract now requires at least one `?rtl` child and otherwise allows any number of generated children (`?fsmc` / `?dtc`) beside those RTL children.
- Added [t/93-composition-multi-generated-plus-rtl-children.t](/Users/richarddje/Documents/github/fsmgen/t/93-composition-multi-generated-plus-rtl-children.t) to lock the first multi-generated-plus-`?rtl` explicit-link `C3` success path.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane now records the broader `C3` truthfully.

## 2026-03-16
### declared connect-by-name `C4` now covers multi-`?rtl` tops too
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so `C4` no longer stops at one external RTL child. The active declared-by-name contract now accepts either:
  - one or more `?rtl` children,
  - or exactly one generated child (`?fsmc` or `?dtc`) plus one or more `?rtl` children.
- Added [t/92-composition-multi-rtl-connect-by-name.t](/Users/richarddje/Documents/github/fsmgen/t/92-composition-multi-rtl-connect-by-name.t) to lock:
  - pure multi-`?rtl` declared connect-by-name success,
  - one-generated-plus-multi-`?rtl` declared connect-by-name success,
  - and ambiguous multi-`?rtl` by-name rejection.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane now records the broadened `C4` truthfully.

### explicit-link `C3` now covers multi-`?rtl` tops too
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so `C3` no longer stops at one external RTL child. The active explicit-link contract now accepts either:
  - one or more `?rtl` children,
  - or exactly one generated child (`?fsmc` or `?dtc`) plus one or more `?rtl` children.
- Added [t/91-composition-multi-rtl-children.t](/Users/richarddje/Documents/github/fsmgen/t/91-composition-multi-rtl-children.t) to lock:
  - pure multi-`?rtl` explicit-link success,
  - and one-generated-plus-multi-`?rtl` explicit-link success.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane now records the broadened `C3` truthfully.

### single external `?rtl` child composition now has a first shipped `R11` slice
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so a lone `?rtl` child is no longer rejected as “not enough generated children”.
- Shipped behavior now includes:
  - `C1` passthrough tops with one external `?rtl` child and exact same-name top exposure,
  - `C3` explicit-toplink tops with one external `?rtl` child and renamed top ports,
  - and `C4` declared connect-by-name tops with one external `?rtl` child.
- Added [t/90-composition-single-rtl-child.t](/Users/richarddje/Documents/github/fsmgen/t/90-composition-single-rtl-child.t) to lock the single-`?rtl` `C1`, `C3`, and `C4` success paths, and updated [t/13-composition-source-classification.t](/Users/richarddje/Documents/github/fsmgen/t/13-composition-source-classification.t) so the “no children” boundary now names `?rtl` honestly too.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane now records this bounded single-RTL broadening explicitly.

### embedded `?rtlif` roots now have a first shipped `R11` slice
- Updated [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm) and [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so external RTL children can realize their interface from an embedded `(?rtlif:module_name ...)` companion root in the same composition source.
- Shipped behavior now includes:
  - embedded same-file `?rtlif` metadata taking precedence over sidecar `<module>.rtlif` files,
  - mixed generated-child plus `?rtl` composition succeeding without a separate sidecar file when that local interface root exists,
  - and explicit rejection of duplicate embedded `?rtlif` roots for the same RTL module name.
- Added [t/89-composition-embedded-rtlif-roots.t](/Users/richarddje/Documents/github/fsmgen/t/89-composition-embedded-rtlif-roots.t) to lock embedded-root precedence, no-sidecar mixed composition success, and duplicate embedded-root rejection.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane now records embedded `.rtlif` interface roots as shipped behavior.

### typed `.rtlif` ports now have a first deliberate `R11` contract slice
- Updated [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm) so sidecar RTL metadata now accepts typed default-input tokens such as `core_clk:clock` and `rst_async_n:reset` in addition to the earlier compact forms.
- The shipped `.rtlif` contract now includes:
  - one flat `(?rtlif:module_name ...)` root,
  - declaration-ordered port tokens,
  - compact tokens like `clk`, `data_in<8`, and `txd>`,
  - typed tokens like `core_clk:clock`, `rst_async_n:reset`, and `data_in<8:data`,
  - and explicit type annotations limited to `data`, `clock`, and `reset`.
- Mixed generated-child plus external RTL composition now auto-wires custom-named RTL system ports honestly when their `.rtlif` metadata marks them as `:clock` or `:reset`.
- Added [t/88-rtlif-typed-port-contract.t](/Users/richarddje/Documents/github/fsmgen/t/88-rtlif-typed-port-contract.t) to lock:
  - direct typed-token parsing,
  - custom named RTL system-port auto-wiring,
  - and rejection of unsupported explicit `.rtlif` type names.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane now records the `.rtlif` mini-contract as shipped behavior instead of only a future note.

### mixed generated-child plus external RTL declared connect-by-name now has a first shipped `R11` slice
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so composition-facing child interface direction now prefers semantic `signal_role` over the older name-based output heuristic when building realized child interfaces.
- Shipped behavior now includes:
  - declared `=name` success for mixed one-generated-child plus one-`?rtl` tops,
  - mixed `C4` tops that combine explicit child-to-child `?toplink` wiring with by-name top exposure,
  - and correct standalone-DT child input classification for RHS-only signals such as `payload_in`.
- Added [t/87-composition-mixed-connect-by-name.t](/Users/richarddje/Documents/github/fsmgen/t/87-composition-mixed-connect-by-name.t) to lock mixed `?fsmc` + `?rtl` success, mixed `?dtc` + `?rtl` success, and cross-kind same-name ambiguity rejection.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane now records that mixed `C4` slice explicitly.

### single-child declared connect-by-name now has a first shipped `R11` slice
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so declared `=name` connect-by-name no longer starts only beyond the single-child passthrough case.
- Shipped behavior now includes:
  - one generated child (`?fsmc` or `?dtc`) with declared by-name top input/output binding,
  - the same exact same-name, same-direction, same-width matching rule as the broader `C4` lane,
  - and honest non-system interfaces for combinational standalone-DT children in that single-child by-name lane too.
- Added [t/86-composition-single-child-connect-by-name.t](/Users/richarddje/Documents/github/fsmgen/t/86-composition-single-child-connect-by-name.t) to lock single-child `?fsmc` and `?dtc` declared connect-by-name success through pipeline and CLI.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane now records that bounded `C4` extension explicitly.

### composition-facing standalone-DT children now have a first shipped `R11` slice
- Updated [perl/FSM/Composition/Spec.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Spec.pm), [perl/FSM/Composition/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Parser.pm), and [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so composition now accepts `?dtc:instance child_source` as a generated-child kind beside `?fsmc`.
- Shipped behavior now includes:
  - embedded `?dt:name` child realization,
  - external searchable `.fsm` standalone-DT child realization,
  - mixed generated-child composition across `?fsmc` / `?dtc`,
  - mixed `?dtc` plus `?rtl` composition,
  - and honest realized child interfaces for purely combinational DT modules without fake `clk` / `rst_n` ports.
- Added [t/85-composition-standalone-dt-children.t](/Users/richarddje/Documents/github/fsmgen/t/85-composition-standalone-dt-children.t) and extended [t/14-composition-parser.t](/Users/richarddje/Documents/github/fsmgen/t/14-composition-parser.t) to lock:
  - typed `?dtc` parsing,
  - embedded combinational `?dtc` success,
  - mixed `?fsmc` + `?dtc` success,
  - and external `?dtc` plus `?rtl` success through `--path`.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane now records the first composition-facing standalone-DT child slice.
### external composition child FSM reuse now has a first shipped `R11` slice
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so `?top:name` now realizes `?fsmc` children from either:
  - embedded child FSM sources in the same file,
  - or external searchable `.fsm` child sources.
- External `?fsmc` child lookup now checks beside the composition source first, then repeated `--path DIR` roots, then `FSMLIB`, then the current directory.
- Added [t/84-composition-external-fsm-child-sources.t](/Users/richarddje/Documents/github/fsmgen/t/84-composition-external-fsm-child-sources.t) to lock:
  - sibling external child-source realization,
  - `--path`-driven multi-file child realization,
  - and `--path` precedence over `FSMLIB` for `?fsmc` child lookup.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active `R11` lane now records the first broader reusable-root/reference follow-up beyond bare top-level inputs and `.rtlif`.
### reusable-source lookup now has a first shipped `R11` slice
- Added [perl/FSM/SourcePathResolver.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/SourcePathResolver.pm) so explicit search-root handling is no longer hardcoded independently in the CLI and composition metadata loader.
- Updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen), [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm), and [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so:
  - the CLI now accepts repeatable `--path DIR`,
  - bare `.fsm` input lookup searches explicit `--path` roots before `FSMLIB`,
  - and external `.rtlif` metadata lookup now uses the same explicit roots ahead of `FSMLIB`.
- Added [t/83-reusable-source-path-resolution.t](/Users/richarddje/Documents/github/fsmgen/t/83-reusable-source-path-resolution.t) to lock:
  - bare standalone-DT input lookup through `--path`,
  - `--path` precedence over `FSMLIB`,
  - and `--path`-driven external RTL metadata lookup for the current composition lane.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so `R11` now records the first shipped reusable-source lookup slice instead of leaving lookup as roadmap-only intent.
### first `R11` standalone `?dt:name` slice is now shipped
- Updated [perl/FSM/SourceClassifier.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/SourceClassifier.pm), [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm), [perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm), [perl/FSM/CoreAST.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/CoreAST.pm), [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm), and [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the live toolchain now recognizes and generates standalone `?dt:name` roots end to end.
- The active shipped `?dt:name` contract now includes:
  - top-level general DT blocks such as `(-foo ...)`,
  - directive sections `(+size ...)`, `(+constants ...)`, `(+enums ...)`, `(+define ...)`, and `(+params ...)`,
  - compact top-level `(:= signal=value)` directives,
  - implicit `clk` / `rst_n` only when the `?dt:name` source contains sequential assignments,
  - default output exposure for driven non-intermediate targets,
  - and no encoded `current_state` / `next_state` plan.
- Added [t/82-standalone-dt-root-support.t](/Users/richarddje/Documents/github/fsmgen/t/82-standalone-dt-root-support.t) to lock both combinational and sequential `?dt:name` generation paths.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so `R11` now tracks a live shipped slice instead of pure future notes.
### malformed `:=` directive shapes now have explicit end-to-end coverage
- Added [t/81-language-contract-init-directive-shape-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/81-language-contract-init-directive-shape-boundary.t) so the malformed-shape side of the active top-level `:=` family is now locked explicitly:
  - malformed non-scalar payloads such as `(:= (tester_reset=1 extra))`,
  - malformed compact directives such as `(:= BROKEN)`,
  - and parser, pipeline, and CLI entry points all fail without emitting HDL for those malformed forms.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the live contract now says the `:=` family is bounded on both the malformed-RHS side and the malformed-payload/shape side.
### reset-naming continuity now distinguishes current `?fsm` residue from future/default convention
- Refined [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), and [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) so the wording now says this explicitly:
  - current shipped explicit `(?fsm:name ... (+system ...))` compatibility residue still spells `rstn`,
  - but the forward/default async-reset convention remains `rst_n`,
  - including the implicit no-`+system` path and the planned `?top:name` / sequential `?dt:name` lanes.
- Updated [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) to preserve that distinction in continuity notes too.
### non-conventional `+system` reset names now have explicit coverage
- Added [t/80-language-contract-system-reset-name-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/80-language-contract-system-reset-name-boundary.t) to lock the reset-name side of the conventional `+system` family:
  - `(sreset reset)`,
  - and `(asreset reset_async_n)`.
- The same file also locks pipeline and CLI no-output behavior for those malformed reset-name cases, and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now names both rejected reset-name variants explicitly.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the live contract accounting stays aligned.
### malformed `+system` entry structures now have explicit coverage
- Added [t/79-language-contract-system-section-structure-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/79-language-contract-system-section-structure-boundary.t) to lock the malformed-entry-structure side of the conventional `+system` family:
  - scalar entries like `BROKEN` inside `(+system ...)`,
  - and wrong-arity entries like `(clock clk extra)`.
- The same file also locks pipeline and CLI no-output behavior for those malformed `+system` structures, and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents that malformed-entry-structure rule explicitly too.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the live contract accounting stays aligned.
### malformed symbol-definition identifier and scalar-token cases now have full coverage
- Added [t/78-language-contract-symbol-definition-token-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/78-language-contract-symbol-definition-token-boundary.t) to lock the token-validity side of the symbol-definition family:
  - bad identifiers in `+constants`, `+define`, and `+params`,
  - and non-scalar member values in `+enums`.
- The same file also locks pipeline and CLI no-output behavior for those malformed token cases, so the symbol-definition family is no longer fully end-to-end only for malformed shapes while leaving identifier/scalar-token validation implicit.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) to keep the live contract accounting aligned.
### malformed ordinary RHS expression forms now have full entrypoint coverage
- Added [t/77-language-contract-expression-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/77-language-contract-expression-entrypoints.t) to lock pipeline and CLI no-output behavior for the malformed side of ordinary RHS expressions:
  - unsupported operators such as `(bogus B C)`,
  - malformed active-operator arity such as `(== B)`,
  - and guard-only tokens such as `<start` in ordinary RHS expression position.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the malformed ordinary-expression family is now tracked as end-to-end across parser, pipeline, and CLI instead of parser-covered only.
### malformed symbol-definition sections now have full entrypoint coverage
- Added [t/76-language-contract-symbol-definition-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/76-language-contract-symbol-definition-entrypoints.t) to lock pipeline and CLI no-output behavior for the malformed side of:
  - `+constants`,
  - `+define`,
  - and `+params`.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the symbol-definition family is now tracked as end-to-end across parser, pipeline, and CLI instead of having that deeper coverage only for malformed `+enums`.
### inline compound modifiers now have an explicit active boundary
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so the inline compound-modifier family is now explicit instead of partly accidental:
  - bare inline `(+=)` and `(-=)` remain supported as delta-`1` variants,
  - malformed payloads such as `(+= 2 3)` now fail explicitly instead of silently truncating,
  - and duplicate inline modifiers such as `(+= 2) (-= 1)` now fail through a targeted duplicate-modifier boundary instead of falling through a bare-suffix error.
- Added [t/75-language-contract-inline-compound-modifier-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/75-language-contract-inline-compound-modifier-boundary.t) to lock supported bare inline modifiers plus parser/pipeline/CLI rejection for malformed and duplicate inline modifier forms.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the active contract and continuity notes now describe both the supported and malformed sides of that family.
### future `R11` conflict-detection note now records the naming split from the saved response
- Refined [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the saved future `R11` conflict-detection direction now also records the naming/reporting split:
  - per-value-source overlap signals such as `P_Q_multi_src_conflict`,
  - and whole-target overlap signals such as `P_multi_value_conflict`.
### future `R11` shared-drive notes now prefer assertion bits over default arbitration
- Refined [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so the future shared-datapath lane now says:
  - do not auto-resolve or auto-prioritize same-target conflicts by default,
  - generate per-`(P, Q)` onehot0-style assertion bits over source enables such as `A_P_Q_en`, `B_P_Q_en`, and `C_P_Q_en`,
  - and generate whole-target `P` assertion bits that detect multiple value families becoming active in the same cycle.
- Updated [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the saved `R11` direction now preserves “detect/report through assertions” instead of “prevent/resolve by default”.
### future `R11` reusable-DT and shared-drive notes were refined again
- Refined [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so the future reusable standalone-DT lane now also says:
  - `?dt:name` may contain any number of internal general DT blocks such as `(-foo ...)`,
  - `?fsm:name` keeps implicit `clk` / `rst_n`,
  - `?dt:name` gets implicit `clk` / `rst_n` only when at least one sequential assignment exists,
  - and standalone DT arbitration should be expressed through generated enable families rather than a blanket structural conflict ban.
- Refined the same roadmap notes so the future shared-datapath lane now distinguishes:
  - same-target/same-value aggregation,
  - from same-target/different-value conflicts,
  - and records that multiple FSMs must not drive different values to the same target `P` in the same cycle unless a later explicit priority contract is added.
- Updated [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so those refined `R11` rules are preserved in continuity notes too.
### roadmap v2 now includes a reusable standalone-DT/module-library sub-lane under `R11`
- Updated [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) so `R11` now also carries one concrete bounded future lane for reusable standalone module roots:
  - `?dt:name` as the smallest standalone module description,
  - standalone DT modules allowed to mix combinational and sequential outputs,
  - root-family naming follow-up around `?top:name`, `?mod:name`, and `?module:name`,
  - and reusable-source lookup through `FSMLIB` plus repeatable `--path DIR` CLI roots.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so that future lane is now tracked as explicit `R11` contract work instead of loose brainstorming only.
### implicit no-`+system` generation now uses one centralized `clk` / `rst_n` contract
- Added an explicit module-level effective-system accessor in [perl/FSM/CoreAST.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/CoreAST.pm) so clock/reset naming is defined once and referenced by generation paths instead of being hardcoded independently.
- Updated [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm), [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm), and [perl/FSM/Backend.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Backend.pm) so:
  - FSMs without `+system` now generate with implicit `clk` / `rst_n`,
  - explicit conventional `+system` still keeps the declared `clk` / `rstn` pair,
  - and composition child realization/auto-wiring now follows the effective child system ports instead of assuming `rstn`.
- Added [t/74-language-contract-implicit-system-defaults.t](/Users/richarddje/Documents/github/fsmgen/t/74-language-contract-implicit-system-defaults.t) to lock:
  - standalone implicit default generation,
  - explicit `+system` override behavior,
  - and single-child composition realization with implicit `rst_n`.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the contract and continuity notes now say plainly that the implicit default is `clk` / `rst_n`.
### duplicate `+system` declarations are now regression-backed explicitly
- Added [t/73-language-contract-system-section-duplicate-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/73-language-contract-system-section-duplicate-boundary.t) to lock the duplicate-declaration side of the conventional `+system` family:
  - duplicate `(clock clk)` entries are rejected explicitly,
  - duplicate reset declarations are rejected explicitly,
  - and mixed `(sreset rstn)` plus `(asreset rstn)` is also rejected as a duplicate reset declaration.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the conventional `+system` contract now states “exactly one clock declaration and exactly one reset declaration” explicitly.
### shared-datapath `R11` note now captures default top-export versus peer-read internalization
- Refined [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so the future shared-datapath lane now says:
  - outputs from child FSMs or the shared datapath block are top-level outputs by default,
  - peer-read registered outputs become top-internal by default,
  - explicit user direction is needed to re-export those now-internal registered signals,
  - and combinational outputs remain illegal as peer-FSM read sources, which keeps that rule consistent with the new internalization rule.
- Updated [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the same refined export/internalization rule is preserved in the continuity notes.
### shared-datapath `R11` note now uses the “written by at least two FSMs” rule
- Refined [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so the future shared-datapath lane is now explicit about the ownership split:
  - outputs assigned in at least two child FSMs are the shared-datapath candidates,
  - outputs assigned in only one child FSM are not shared and remain directly child-owned.
- Updated [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the same rule is preserved in the continuity notes.
### roadmap v2 now includes a concrete shared-datapath composition sub-lane under `R11`
- Updated [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) so `R11` now includes one concrete bounded future composition lane:
  - multi-FSM top generation from one `.fsm` source or several `.fsm` sources,
  - optional lifting of selected child-owned targets into one shared datapath block,
  - deterministic per-child drive-intent enable families such as `A_P_Q_en`,
  - registered-output loopback rules,
  - and the saved rule that combinational outputs must not become cross-FSM read sources.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this direction is now tracked as an explicit future `R11` contract lane instead of loose brainstorming only.
## 2026-03-15
### malformed `+system` boundaries now have pipeline and CLI coverage too
- Added [t/72-language-contract-system-section-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/72-language-contract-system-section-entrypoints.t) to lock pipeline and CLI no-output behavior for:
  - non-conventional `+system` clock names like `(clock core_clk)`,
  - unsupported `+system` entries like `(areset rstn)`,
  - and incomplete `+system` sections.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the malformed side of the conventional `+system` family is now tracked as an end-to-end entrypoint boundary instead of parser-only coverage.
### legacy generic/template placeholder boundaries now have pipeline and CLI coverage too
- Added [t/71-language-contract-generic-placeholder-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/71-language-contract-generic-placeholder-entrypoints.t) to lock pipeline and CLI no-output behavior for:
  - legacy placeholder selectors such as `?[READ]`,
  - legacy repeat macros such as `?repeat:[MAX_COUNT]`,
  - and legacy placeholder tokens such as `[DATAIN]`.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the legacy generic/template placeholder family is now tracked as an end-to-end entrypoint boundary instead of parser-only coverage.
### unsupported top-level `+...` directive boundaries now have pipeline and CLI coverage too
- Added [t/70-language-contract-top-level-directive-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/70-language-contract-top-level-directive-entrypoints.t) to lock pipeline and CLI no-output behavior for:
  - unknown top-level `+` directives like `(+bogus ...)`,
  - and unsupported future-style top-level directives like `(+clock clk)`.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the unsupported top-level `+...` directive family is now tracked as an end-to-end entrypoint boundary instead of parser-only coverage.
### malformed test-selector boundaries now have pipeline and CLI coverage too
- Added [t/69-language-contract-test-selector-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/69-language-contract-test-selector-entrypoints.t) to lock pipeline and CLI no-output behavior for:
  - bare symbolic test selectors like `(BUSY ...)`,
  - and bare numeric test selectors like `(0 ...)`.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the malformed test-selector family is now tracked as an end-to-end entrypoint boundary instead of parser-only coverage.
### malformed test-branch boundaries now have pipeline and CLI coverage too
- Added [t/68-language-contract-test-branch-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/68-language-contract-test-branch-entrypoints.t) to lock pipeline and CLI no-output behavior for:
  - empty test-node branches like `(?MODE (=0))`,
  - and single malformed test-branch bodies that still omit a nested action.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the malformed test-branch family is now tracked as an end-to-end entrypoint boundary instead of parser-only coverage.
### bare condition-suffix boundaries now have pipeline and CLI coverage too
- Added [t/67-language-contract-condition-suffix-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/67-language-contract-condition-suffix-entrypoints.t) to lock pipeline and CLI no-output behavior for:
  - bare assignment condition suffixes like `(A <= B start)`,
  - and bare transition condition suffixes like `(-> busy full)`.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the malformed bare-suffix family is now tracked as an end-to-end entrypoint boundary instead of parser-only coverage.
### malformed action-family boundaries now have pipeline and CLI coverage too
- Added [t/66-language-contract-malformed-action-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/66-language-contract-malformed-action-entrypoints.t) to lock pipeline and CLI no-output behavior for:
  - single-token malformed DT actions like `(BROKEN)`,
  - and empty guarded blocks like `(<req)`.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the malformed-action family is now tracked as an end-to-end entrypoint boundary instead of parser-only coverage.
### malformed legacy `+fsm` root bodies are now regression-backed explicitly
- Added [t/65-language-contract-plus-fsm-body-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/65-language-contract-plus-fsm-body-boundary.t) to lock the malformed-body side of the already-shipped legacy `+fsm` root family:
  - explicit rejection of empty `(+fsm plus_empty)` roots,
  - explicit rejection of scalar body items like `(+fsm plus_scalar BROKEN)`,
  - and pipeline/CLI no-output behavior for those malformed legacy roots.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so the live top-level source contract now calls out the legacy `+fsm` body boundary explicitly too.
### malformed structured `?fsm` root bodies now fail through an explicit boundary
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so structured `?fsm:name` roots now require a non-empty top-level item list and reject scalar top-level body items explicitly instead of relying on incidental later-stage fallout.
- Added [t/64-language-contract-fsm-root-body-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/64-language-contract-fsm-root-body-boundary.t) to lock:
  - explicit rejection of empty structured roots like `(?fsm:empty_root)`,
  - explicit rejection of scalar top-level items like `(?fsm:scalar_root BROKEN)`,
  - and pipeline/CLI no-output behavior for those malformed structured roots.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so the top-level source contract now documents the structured-root body boundary explicitly.
### bare top-level FSM content now fails through an explicit source-root boundary
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so unwrapped top-level FSM content now fails through a dedicated source-root diagnostic instead of the old generic “expected `?fsm:name` or `+fsm`” parser error.
- Added [t/63-language-contract-source-root-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/63-language-contract-source-root-boundary.t) to lock:
  - explicit rejection of bare top-level forms like `(+system ...)` and `(idle ...)`,
  - classifier truth for files that stay outside the active source-root family,
  - and pipeline/CLI no-output behavior for those malformed roots.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so the top-level source contract now documents the unwrapped-root boundary explicitly.
### malformed update-shorthand tails now fail through an explicit boundary
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so update shorthand now rejects stray extra positional tail payloads through a dedicated update-shorthand-tail diagnostic instead of leaking them through the generic suffix-guard boundary.
- Added [t/62-language-contract-update-shorthand-tail-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/62-language-contract-update-shorthand-tail-boundary.t) to lock:
  - continued support for valid guarded forms like `(+= counter 4 <start)`,
  - explicit rejection of malformed tails like `(+= counter 4 3)` and `(+= counter 4 3 2)`,
  - and pipeline/CLI no-output behavior for those malformed forms.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so the update-shorthand family now documents its trailing-tail boundary explicitly.
### malformed update-shorthand targets now fail explicitly instead of disappearing silently
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so recognized update-shorthand forms now reject malformed non-scalar targets through a dedicated update-shorthand diagnostic instead of returning `undef` and disappearing from the DT body.
- Added [t/61-language-contract-update-shorthand-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/61-language-contract-update-shorthand-boundary.t) to lock:
  - malformed targets such as `(++ (counter))` and `(+= (byte_count) 4)`,
  - and pipeline/CLI no-output behavior for malformed update-shorthand forms.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so the update-shorthand family now documents its malformed-target boundary explicitly.
### alternate compound-update shorthand spellings are now part of the active contract
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) so the active update-shorthand family now documents the already-supported separated spellings:
  - `(+= sig)` / `(-= sig)` as delta-`1` forms,
  - `(+= sig N)` / `(-= sig N)` as separated delta-carrying forms,
  - alongside the previously documented `++`, `--`, `+=N`, and `-=N` spellings.
- Added [t/60-language-contract-update-shorthand-variants.t](/Users/richarddje/Documents/github/fsmgen/t/60-language-contract-update-shorthand-variants.t) to lock:
  - separated delta-`1` update forms,
  - separated delta-carrying update forms,
  - and end-to-end HDL generation for those alternate spellings.
- Updated the support snapshot in [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) and continuity notes in [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so the live contract now matches the shipped parser truthfully.
### unsupported assignment operators now fail through an explicit contract boundary
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so unsupported assignment operators now surface through a dedicated user-facing assignment-operator diagnostic instead of a raw internal parser `confess`.
- Added [t/59-language-contract-assignment-operator-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/59-language-contract-assignment-operator-boundary.t) to lock:
  - explicit rejection of unsupported operators such as `?=` and `=>`,
  - and pipeline/CLI no-output behavior for malformed assignment forms.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so the active assignment-operator family and its malformed boundary are now documented explicitly.
### malformed guard shorthand and inline comparison tokens now fail through explicit boundaries
- Updated [perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm) so malformed guard shorthand payloads and malformed inline comparison tokens now surface through their dedicated contract diagnostics instead of falling through to generic unsupported-expression-token errors.
- Added [t/58-language-contract-condition-expression-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/58-language-contract-condition-expression-boundary.t) to lock:
  - malformed guard shorthand payloads such as `mode=` and `==3`,
  - malformed inline comparison tokens such as `cnt[2:1]!=` and `=3`,
  - and pipeline/CLI no-output behavior for both malformed families.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so the active contract now documents both malformed boundaries explicitly.
### delayed-pulse `<N` RHS values now fail through an explicit contract boundary
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so malformed delayed-pulse RHS values now surface through a clean user-facing contract diagnostic instead of raw internal parser messages.
- Added [t/57-language-contract-pulse-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/57-language-contract-pulse-boundary.t) to lock:
  - explicit rejection of malformed delayed-pulse RHS values such as `B` and `2'0`,
  - and pipeline/CLI no-output behavior for malformed delayed-pulse assignments.
- Updated [t/04-assignment-edge-cases.t](/Users/richarddje/Documents/github/fsmgen/t/04-assignment-edge-cases.t), [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so the active pulse boundary is described and checked consistently.
### `:=` reset/default RHS values now fail through the dedicated init contract
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so malformed `:=` RHS values now surface through the dedicated init/reset boundary instead of leaking raw expression-parser failures.
- Added [t/56-language-contract-init-directive-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/56-language-contract-init-directive-boundary.t) to lock:
  - explicit rejection of unsupported RHS reset/default values such as `[DATAIN]` and `<start`,
  - and pipeline/CLI no-output behavior for malformed `:=` RHS values.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so the active `:=` contract now documents the malformed-RHS boundary explicitly.
### computed test selectors now have an explicit malformed-boundary contract
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so computed test selectors must start with a real selector expression and include at least one branch instead of falling through to incidental parser/expression failures.
- Added [t/55-language-contract-computed-test-selector-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/55-language-contract-computed-test-selector-boundary.t) to lock:
  - rejection of missing-expression computed selectors such as `(? (=0 ...))`,
  - rejection of branchless computed selectors such as `(?(| A B))`,
  - and pipeline/CLI no-output behavior for those malformed forms.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so the active `?(expr)` boundary is documented explicitly on both the success and malformed sides.
### plain `?SIG` test-node signal names now have an explicit boundary
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so plain test nodes now require `?signal_name` with an HDL-identifier-compatible signal name, while keeping computed selectors `?(expr)` on their existing supported path.
- Added focused regression coverage in [t/54-language-contract-test-signal-name-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/54-language-contract-test-signal-name-boundary.t) for:
  - successful parsing/generation of a conventional `?SIG` test node,
  - explicit rejection of malformed plain test-node signal names like `?bad-name` and `?0`,
  - and pipeline/CLI confirmation that malformed plain test-node signal names do not emit HDL.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the live contract now states the plain-`?SIG` naming rule explicitly.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
### transition targets now have an explicit active boundary
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so state transitions are now validated explicitly:
  - target names must be HDL-identifier-compatible,
  - target names must refer to a declared regular FSM-state DT block inside the same FSM source,
  - and malformed/unknown transition targets now fail before they can leak into `STATE_*` HDL generation.
- Added focused regression coverage in [t/53-language-contract-transition-target-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/53-language-contract-transition-target-boundary.t) for:
  - successful parsing/generation with declared forward transition targets,
  - explicit rejection of malformed target names like `bad-name`,
  - explicit rejection of non-state targets like `-comb`,
  - explicit rejection of unknown targets like `missing_state`,
  - and pipeline/CLI confirmation that unknown targets do not emit HDL.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the live contract now states the transition-target rule explicitly.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
### state and DT block names now have an explicit active boundary
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so state/DT names are now validated explicitly:
  - regular FSM-state DT names must be HDL-identifier-compatible,
  - general/combinational DT names must use exactly one leading `-` plus an HDL-identifier-compatible base name,
  - and reset-state names remain limited to the existing supported reset spellings.
- Added focused regression coverage in [t/52-language-contract-state-name-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/52-language-contract-state-name-boundary.t) for:
  - successful parsing/generation with valid regular and standalone DT names,
  - explicit rejection of malformed regular state names like `bad-name`,
  - explicit rejection of malformed standalone DT names like `-bad-name` and `--bad`,
  - and pipeline/CLI confirmation that malformed state names do not emit HDL.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the live contract now states the state/DT naming rule explicitly.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
### malformed symbol-definition sections now fail explicitly
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so the symbol-definition family no longer relies on loose Perl list unpacking for malformed input:
  - `+constants` now requires a non-empty list of `(NAME scalar_value)` entries,
  - `+define` now requires exactly one `(NAME scalar_value)` pair,
  - `+params` now requires a non-empty list of `(NAME scalar_value)` entries,
  - and `+enums` now requires a non-empty list of `(enum_name (MEMBER value) ...)` definitions with at least one member per enum.
- Added focused regression coverage in [t/51-language-contract-symbol-definition-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/51-language-contract-symbol-definition-boundary.t) for:
  - empty symbol-definition sections,
  - malformed section payloads and malformed entry/member shapes,
  - and pipeline/CLI confirmation that malformed symbol-definition sections do not emit HDL.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the live contract now states the malformed-boundary rules explicitly.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
### `+size` now has an explicit active contract
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so `+size` is now parsed through an explicit contract helper instead of being partially ignored:
  - the legacy empty form `(+size)` remains supported as a no-op,
  - valid `(signal width)` entries still register widths,
  - malformed payloads and malformed entries now fail with targeted diagnostics.
- Added focused regression coverage in [t/50-language-contract-size-section-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/50-language-contract-size-section-boundary.t) for:
  - successful parsing/generation with legacy empty `(+size)`,
  - explicit rejection of malformed `+size` payloads like `(+size BROKEN)`,
  - explicit rejection of malformed entries like `(A)`,
  - explicit rejection of non-positive widths like `(A 0)`,
  - and pipeline/CLI confirmation that malformed `+size` sections do not emit HDL.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the live contract now states the `+size` boundary explicitly.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
### empty or scalar-only state/DT bodies now fail explicitly
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so state/DT blocks must contain at least one real nested decision-tree body or action form instead of being accepted as empty pseudo-states.
- Added focused regression coverage in [t/49-language-contract-state-body-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/49-language-contract-state-body-boundary.t) for:
  - empty FSM-state DT blocks like `(idle)`,
  - empty general/combinational DT blocks like `(-misc)`,
  - and pipeline/CLI confirmation that these malformed blocks no longer emit HDL.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the live language contract now states that state/DT blocks need a real body.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
### general/combinational DT blocks now have an explicit standalone contract
- Updated [perl/FSM/CoreAST.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/CoreAST.pm) so `FSM::CoreAST::State` now exposes `is_standalone_dt` and treats standalone DTs through explicit state-role semantics instead of only inferring them from the leading hyphen in the name.
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so hyphen-prefixed non-reset DT blocks now parse with `state_type => standalone_dt`.
- Added focused regression coverage in [t/48-language-contract-standalone-dt-classification.t](/Users/richarddje/Documents/github/fsmgen/t/48-language-contract-standalone-dt-classification.t) for:
  - explicit `standalone_dt` AST classification,
  - exclusion of general/combinational DT blocks from the encoded-state plan,
  - and DT-style enable emission for those blocks.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the live language contract now states that general/combinational DT blocks are explicitly standalone DTs, not accidental pseudo-states.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
### tagged source names now have an explicit whole-name boundary
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so top-level `?fsm:module_name` roots now validate the whole source name and reject malformed names like `?fsm:bad-name` explicitly instead of truncating to `bad`.
- Updated [perl/FSM/Composition/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Parser.pm) so top-level `?top:top_name` roots and embedded composition child sources like `?fsm:source_name` now also validate the whole source name instead of truncating malformed names silently.
- Added focused regression coverage in [t/47-language-contract-source-name-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/47-language-contract-source-name-boundary.t) for:
  - malformed top-level `?fsm:bad-name` roots,
  - malformed top-level `?top:bad-name` roots,
  - and malformed embedded composition child sources like `?fsm:bad-name`.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the live contract now states the tagged source-name rule explicitly.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
### legacy `+fsm` roots now have an explicit contract boundary
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so the legacy `+fsm` source family is now validated explicitly before module-name decoding:
  - accepted:
    - the flattened sibling layout with a first top-level `(+fsm module_name)` entry followed by sibling sections and state/DT blocks
    - the nested legacy root layout `(+fsm module_name ...)`
  - rejected: malformed `+fsm` roots without a scalar module name
- Added focused regression coverage in [t/46-language-contract-flat-plus-fsm-root.t](/Users/richarddje/Documents/github/fsmgen/t/46-language-contract-flat-plus-fsm-root.t) for:
  - source classification of `+fsm`,
  - direct adapter parsing of both shipped legacy layouts,
  - pipeline and CLI generation for both valid paths,
  - and explicit parser/pipeline/CLI rejection of malformed `+fsm` roots.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the live language contract now describes the real legacy `+fsm` family truthfully.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
### user-facing DT-versus-state terminology is now sharper
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) so the supported-language section now uses the more precise user-facing distinction:
  - both `(aState ...)` and `(-foobar ...)` are decision trees,
  - `(aState ...)` is an FSM-state DT,
  - `(-foobar ...)` is a general/combinational DT block.
- Updated [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so this terminology choice is preserved for future wording and roadmap work.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task.
### reset-state spellings now have a real supported contract
- Updated [perl/FSM/CoreAST.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/CoreAST.pm) so `FSM::CoreAST::State` now preserves `state_type` and exposes `state_type`, `is_reset_state`, and `is_regular_state`, instead of silently dropping reset-state classification metadata.
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so:
  - `-syncrst` and `-syncreset` now normalize to the same `syncreset` reset-state identity,
  - `-asyncrst` and `-asyncreset` now normalize to the same `asyncreset` reset-state identity,
  - and the top-level FSM parser now accepts those legacy long spellings as part of the same reset-state family.
- Updated [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm), [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm), and [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so reset-state blocks are treated as DT-like blocks instead of regular encoded states.
- Added focused regression coverage in [t/45-language-contract-reset-state-spellings.t](/Users/richarddje/Documents/github/fsmgen/t/45-language-contract-reset-state-spellings.t) for:
  - canonical and legacy reset-state spelling normalization,
  - exclusion of reset-state blocks from the encoded-state plan,
  - and DT-style enable emission for reset-state blocks.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the live language contract now describes the reset-state family truthfully.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
### n-ary relational operators are now part of the active contract
- Updated [perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm) so the active operator family now executes the previously saved broader contract instead of documenting only part of it:
  - n-ary relational operators such as `(< low mid high)` and `(== a b c d)` now lower as adjacent-pair comparison chains,
  - relational aliases such as `eq`, `ne`, `lt`, `le`, `gt`, and `ge` now lower to their canonical comparison operators,
  - unary alias `not` now lowers to `!`,
  - and malformed supported-operator arity is now checked against the new contract (`!` requires exactly one operand; the infix-style families require at least two).
- Updated [perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm) so parser-created intermediate expression signals now contribute their driving-AST source signals to interface-role analysis, which keeps inputs like `low`, `mid`, and `high` live in generated modules instead of hiding them behind the intermediate name alone.
- Added focused regression coverage in [t/44-language-contract-relational-operators.t](/Users/richarddje/Documents/github/fsmgen/t/44-language-contract-relational-operators.t) for:
  - n-ary relational chains,
  - relational aliases,
  - unary alias `not`,
  - guarded-block use of chained relational expressions,
  - and emitted HDL input visibility for parser-generated relational intermediates.
- Updated [t/40-language-contract-expression-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/40-language-contract-expression-boundary.t) so malformed comparison arity is still locked now that `(== a b c)` is a supported form; the active rejection case is now `(== a)`.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the live contract and continuity notes now match the executable operator-arity boundary truthfully.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
### unsupported top-level bare forms now fail explicitly
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so unsupported top-level bare forms inside `(?fsm:name ...)` now fail explicitly instead of being skipped silently.
- Added focused regression coverage in [t/43-language-contract-top-level-form-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/43-language-contract-top-level-form-boundary.t) for:
  - future-looking bare init syntax like `(tester_reset := 1)`,
  - malformed bare scalar forms like `(BROKEN 1)`,
  - and pipeline/CLI confirmation that these forms do not disappear silently or emit HDL output.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the active contract now states that directive sections, `:=` init/reset directives, and state/DT blocks are the only supported top-level forms inside `(?fsm:name ...)`.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
### test-node selectors now require explicit operator prefixes
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so test-node branches now require explicit operator-prefixed selector tokens such as `=0`, `=OTHER`, `!=8'0`, or `>8'3`, instead of accepting malformed bare selectors implicitly.
- Updated [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm) so runtime lowering enforces the same selector boundary for direct AST callers.
- Added focused regression coverage in [t/42-language-contract-test-selector-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/42-language-contract-test-selector-boundary.t) for:
  - explicit rejection of bare symbolic selectors like `BUSY`,
  - explicit rejection of bare numeric selectors like `0`,
  - and continued support for explicit symbolic equality selectors like `=OTHER`.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the active test-node contract now states the explicit-selector rule plainly.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
### unsupported tagged top-level sources now fail explicitly
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so unsupported tagged top-level source kinds such as `?define:legacy_template` now fail explicitly before the nested-`?fsm` fallback can parse inner FSM content accidentally.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the active pipeline and CLI reject the same tagged-source boundary directly instead of relying on later parser fallout.
- Added focused regression coverage in [t/41-language-contract-top-level-source-kind-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/41-language-contract-top-level-source-kind-boundary.t) for:
  - source classification,
  - direct adapter rejection,
  - pipeline rejection,
  - and CLI rejection without emitted HDL output.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the active contract now calls out unsupported tagged top-level source roots explicitly.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
### unsupported expression forms now fail explicitly
- Updated [perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm) so unsupported expression forms no longer drift through soft parser fallthrough:
  - real inline scalar comparison tokens such as `cnt[2:1]!=2'2` now parse as comparison ASTs explicitly instead of relying on accidental fallback behavior,
  - unknown operators such as `(bogus B C)` now fail explicitly,
  - malformed active-operator arity such as `(== B C D)` now fails explicitly,
  - empty expression lists and unsupported expression payload types now fail explicitly,
  - and guard-only tokens like `<start` now fail when used in ordinary RHS expression position.
- Added focused regression coverage in [t/40-language-contract-expression-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/40-language-contract-expression-boundary.t) for:
  - supported inline scalar comparison tokens,
  - unsupported RHS operators,
  - malformed RHS operator arity,
  - and invalid RHS scalar tokens.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the active contract now documents this as an explicit rejection boundary instead of leaving it implicit.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
### shorthand guard comparisons are now active and regression-backed
- Updated [perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm) so guarded blocks and suffix guards now lower the shorthand family explicitly instead of treating only the old equality form as special:
  - `(<foo ...)` now means `foo != 0`
  - `(<!foo ...)` now means `foo == 0`
  - `(<foo=value ...)` and `(<foo==value ...)` mean equality
  - `(<foo!=value ...)`, `(<foo<value ...)`, `(<foo<=value ...)`, `(<foo>value ...)`, and `(<foo>=value ...)` now lower to their matching comparison ASTs
- Added focused regression coverage in [t/39-language-contract-guard-shorthand.t](/Users/richarddje/Documents/github/fsmgen/t/39-language-contract-guard-shorthand.t) for shorthand guarded blocks, shorthand suffix guards, and emitted HDL comparisons.
- Updated [t/29-language-contract-core-forms.t](/Users/richarddje/Documents/github/fsmgen/t/29-language-contract-core-forms.t) so the existing core guard/suffix regression now expects explicit comparison ASTs for `<foo` and `<!foo`.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the active contract now treats the shorthand guard family as supported instead of future-only.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
### future placeholder syntax direction was saved
- Updated [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) to preserve the current design conclusion for any future generic/template lane:
  - prefer `$(VAR)` as the canonical placeholder syntax,
  - allow `$VAR` only as optional sugar if that lane is ever implemented,
  - and do not reuse `<VAR>` because `<...` is already reserved for guarded-block and suffix-guard syntax.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`.
### legacy generic placeholder forms now fail explicitly
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so legacy generic/template placeholder selectors such as `?[READ]` and repeat macros such as `?repeat:[MAX_COUNT]` now fail with targeted diagnostics instead of drifting into ordinary `?sig` parsing.
- Updated [perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm) so placeholder tokens such as `[DATAIN]` or `[?size: ...]` now fail explicitly instead of being registered as ordinary signal names in the active parser.
- Added focused regression coverage in [t/38-language-contract-generic-placeholder-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/38-language-contract-generic-placeholder-boundary.t) for:
  - placeholder selectors like `?[READ]`,
  - repeat macros like `?repeat:[MAX_COUNT]`,
  - and placeholder tokens like `[DATAIN]`.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) so the legacy generic/template placeholder family is now called out explicitly in the out-of-support bucket.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so `R8` tracking reflects that one more parser-visible legacy family is now explicitly rejected instead of ambiguously accepted.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
- Validation:
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm` (pass)
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm` (pass)
  - `perl -I perl -c t/38-language-contract-generic-placeholder-boundary.t` (pass)
  - `prove -I perl t/38-language-contract-generic-placeholder-boundary.t` (pass)
### computed test selectors now synthesize real intermediate wires end to end
- Updated [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm) so parser-created computed-selector signals marked as intermediate remain visible to later dependency and filtering passes instead of being dropped by AST-factorization heuristics.
- Updated [perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm) so `?(expr)` test nodes now analyze the selector signal's driving AST as well as the synthetic selector signal itself, which keeps the underlying selector inputs live in the generated interface.
- Added focused regression coverage in [t/37-language-contract-computed-test-selector.t](/Users/richarddje/Documents/github/fsmgen/t/37-language-contract-computed-test-selector.t) for:
  - the computed-selector form `(?(| A B) ...)`,
  - intermediate condition-signal capture in phase 1,
  - live input exposure for the selector source signals,
  - and emitted HDL that declares and drives the computed-selector wire before branch comparisons reuse it.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) so the active test-node contract now includes the computed-selector form `?(expr)` explicitly instead of describing only `?SIG`.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so `R8` tracking reflects that one more real parser/runtime-visible construct family is now both documented and regression-backed.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
- Validation:
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm` (pass)
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c t/37-language-contract-computed-test-selector.t` (pass)
  - `prove -I perl t/12-enablegraph-capture-registry.t t/37-language-contract-computed-test-selector.t` (pass)
### relational test-node selectors are now explicit and regression-backed
- Updated [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm) so `?sig` selector branches now lower relational selectors with their actual comparison operators instead of collapsing the active selector family to equality-only behavior.
- Added focused regression coverage in [t/36-language-contract-test-branch-selectors.t](/Users/richarddje/Documents/github/fsmgen/t/36-language-contract-test-branch-selectors.t) for:
  - `!=` selector lowering,
  - `>` selector lowering,
  - `<=` selector lowering,
  - both captured condition ASTs and emitted HDL text.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) so the active test-node contract now documents the broader shipped selector family explicitly instead of describing only equality selectors.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so `R8` done/left tracking reflects that the selector family is now both truthfully documented and regression-backed.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c t/36-language-contract-test-branch-selectors.t` (pass)
  - `prove -I perl t/36-language-contract-test-branch-selectors.t` (pass)
### malformed empty test-node branches now fail explicitly
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so malformed empty `?sig` / case-style test branches now fail with a targeted diagnostic instead of leaking through a generic internal `undef` action path.
- Added focused regression coverage in [t/35-language-contract-test-branch-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/35-language-contract-test-branch-boundary.t) for:
  - empty branches such as `(?MODE (=0))`,
  - and mixed test nodes where one branch is valid and another branch is empty.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) so the active test-node contract now says explicitly that each branch requires a selector plus at least one nested action, and malformed empty branches are now called out in the out-of-support bucket.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so `R8` done/left tracking reflects the removal of this generic parser-failure path from the test-node family.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
- Validation:
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm` (pass)
  - `perl -I perl -c t/35-language-contract-test-branch-boundary.t` (pass)
  - `prove -I perl t/35-language-contract-test-branch-boundary.t` (pass)
### top-level `:=` is now explicit, and malformed DT actions now fail explicitly
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so top-level `:=` is now an explicit init/reset directive that records reset/default metadata for the target signal, while malformed decision-tree actions and empty guarded blocks no longer disappear silently during parsing.
- Added focused regression coverage in [t/34-language-contract-malformed-actions.t](/Users/richarddje/Documents/github/fsmgen/t/34-language-contract-malformed-actions.t) for:
  - supported top-level `:=` directive parsing,
  - malformed single-token DT action rejection,
  - malformed `:=` directive rejection,
  - and empty guarded-block rejection.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) so the active `:=` boundary is documented explicitly, malformed action forms and empty guarded blocks are now explicitly called out in the out-of-support bucket, and the guarded-block contract now says plainly that a guarded block must contain at least one action.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so `R8` done/left tracking reflects both the explicit `:=` support slice and the removal of this silent parser-drop path. [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) also now preserves the future-syntax discussion for `(:= (lhs value))` and `(lhs := value)`.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
- Validation:
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm` (pass)
  - `perl -I perl -c t/34-language-contract-malformed-actions.t` (pass)
  - `prove -I perl t/34-language-contract-malformed-actions.t` (pass)
### bare condition suffixes now fail explicitly
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so bare suffix tails no longer slip through as implicit positive conditions in assignment or transition suffix positions.
- Added focused regression coverage in [t/33-language-contract-condition-suffix-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/33-language-contract-condition-suffix-boundary.t) for:
  - bare assignment suffix rejection,
  - and bare transition suffix rejection.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) so the suffix-guard contract now says plainly that active suffix guards must use explicit `<...` / `<!...` forms and that bare tails such as `(A <= B start)` are out of support.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so `R8` done/left tracking reflects the removal of this implicit legacy guard path.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
- Validation:
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm` (pass)
  - `perl -I perl -c t/33-language-contract-condition-suffix-boundary.t` (pass)
  - `prove -I perl t/33-language-contract-condition-suffix-boundary.t` (pass)
### unsupported top-level `+...` directives now fail explicitly
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so unsupported top-level `+...` directive sections no longer drift into fake state parsing and now fail with a targeted diagnostic that lists the supported top-level directive family.
- Added focused regression coverage in [t/32-language-contract-top-level-directive-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/32-language-contract-top-level-directive-boundary.t) for:
  - unknown directive sections such as `(+bogus ...)`,
  - and future-looking but currently unsupported directive spellings such as `(+clock clk)`.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) so unsupported top-level directive sections are now explicitly called out in the out-of-support bucket instead of being left implicit.
- Updated [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) to preserve the syntax-namespace rationale from the latest language discussion:
  - why `(?foo:...)` exists,
  - why the `+...` family exists,
  - and why any future redesign should be treated as a family-level syntax decision rather than as a one-off `+system` rename.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), and [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md) so `R8` done/left tracking reflects the landed explicit-rejection slice.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
- Validation:
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm` (pass)
  - `perl -I perl -c t/32-language-contract-top-level-directive-boundary.t` (pass)
  - `prove -I perl t/32-language-contract-top-level-directive-boundary.t` (pass)
### conventional `+system` contract slice is now live and regression-backed
- Promoted the conventional `+system` declaration into the active supported-language boundary in [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md):
  - `(+system (clock clk) (sreset rstn))`
  - `(+system (clock clk) (asreset rstn))`
- Added focused regression coverage in [t/31-language-contract-system-section.t](/Users/richarddje/Documents/github/fsmgen/t/31-language-contract-system-section.t) for:
  - accepted conventional `+system` parsing,
  - explicit rejection of non-conventional clock names,
  - explicit rejection of unsupported system directives,
  - and explicit rejection of incomplete `+system` sections.
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so the parser now validates the current `+system` contract explicitly instead of silently ignoring `+system`, and now records:
  - default clock domain `clk`,
  - default reset domain `rstn`,
  - and typed system signals for `clk` and `rstn`.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so `R8` done/left tracking reflects the landed `+system` slice.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
- Validation:
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm` (pass)
  - `perl -I perl -c t/31-language-contract-system-section.t` (pass)
  - `prove -I perl t/31-language-contract-system-section.t` (pass)
### `R8` symbol-definition contract slice is now live and regression-backed
- Promoted the symbol-definition families into the active supported-language boundary in [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md):
  - `(+constants ...)`,
  - `(+enums ...)`,
  - `(+define ...)`,
  - `(+params ...)`.
- Added focused regression coverage in [t/30-language-contract-symbol-definitions.t](/Users/richarddje/Documents/github/fsmgen/t/30-language-contract-symbol-definitions.t) for:
  - symbol-summary counts,
  - RHS literal resolution,
  - and guard equality resolution through the active parser/generator path.
- Fixed the parser-side scalar-unwrapping bug in [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so the current Lispish AST packing for `+constants`, `+define`, `+params`, and enum member values is handled consistently instead of leaking `undef` into scalar-expression parsing.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so `R8` done/left tracking reflects the landed symbol-definition slice.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
- Validation:
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm` (pass)
  - `perl -I perl -c t/30-language-contract-symbol-definitions.t` (pass)
  - `prove -I perl t/30-language-contract-symbol-definitions.t` (pass)
## 2026-03-14
### first `R8` language-contract slice is now live and regression-backed
- Promoted the first `R8` draft normative language-contract slice into [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md).
- The live supported-language boundary now explicitly includes:
  - nested guarded blocks,
  - condition suffixes,
  - compound update shorthand,
  - inline compound modifiers,
  - and the currently regression-backed broader operator-expression families.
- Added focused regression coverage in [t/29-language-contract-core-forms.t](/Users/richarddje/Documents/github/fsmgen/t/29-language-contract-core-forms.t) for:
  - guarded blocks and suffix guards,
  - shorthand and inline updates,
  - and broader operator lowering.
- Hardened two small warning paths exposed by the new regression:
  - [perl/FSM/ExpressionNamer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/ExpressionNamer.pm) now guards undefined legacy expression/signal strings,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm) now debug-renders driving ASTs without avoidable warning noise.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so `R8` done/left tracking reflects the landed first contract slice.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - `R8` remains `in progress`, but its `Done`/`Left` detail advanced materially.
- Validation:
  - `perl -I perl -c perl/FSM/ExpressionNamer.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t/29-language-contract-core-forms.t` (pass)
### long-term horizon goals are now captured in roadmap v2
- Extended [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) with an explicit long-term horizon section.
- The roadmap now records two long-term goals:
  - `H1` Rust FSMGen,
  - `H2` a beautiful, dynamic public project website.
- The saved gating rule is explicit:
  - first make FSMGen state-of-the-art, rock solid, and really stable through the active `R8`..`R13` work,
  - only then treat the Rust implementation or public website as serious execution lanes.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so this horizon is visible in both live roadmap context and continuity docs.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task.
- Validation:
  - `git diff --check` (pass)
### roadmap v2 is now opened and `R8` is the active lane
- Added [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) as the detailed companion roadmap for the post-`R0`..`R7` workstreams.
- Refreshed [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so roadmap generation `v2` is now active, while `R0` through `R7` remain the closed foundation workstreams from the completed first roadmap.
- The live board now defines and tracks:
  - `R8` language-contract hardening,
  - `R9` strict mode and support-tier enforcement,
  - `R10` source provenance and diagnostics,
  - `R11` composition contract strengthening,
  - `R12` regression corpus and support accounting,
  - `R13` public embedding/API stabilization,
  - `R14` VHDL backend, if still wanted.
- Updated [README.md](/Users/richarddje/Documents/github/fsmgen/README.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so onboarding and continuity now point at the new roadmap structure directly.
- Live roadmap status change:
  - the current active lane moved from `none` to `R8`,
  - `R8` is now `in progress`,
  - `R9` through `R14` are now explicit roadmap workstreams and currently `not started`.
- Validation:
  - `git diff --check` (pass)
### future operator-form RHS design direction is now preserved
- Extended [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) with the current working direction for `(6)` operator-form RHS expressions.
- The saved direction now states:
  - combinational and sequential assignments should share the same RHS expression grammar,
  - operator aliases should lower to canonical operators,
  - infix-style operator families should be treated as unlimited-ary wherever their semantics can be explained deterministically,
  - unlimited-ary `+`, `*`, `&`, `|`, and `^` use explicit fold semantics,
  - unlimited-ary `-`, `/`, and `%` use left-associative left-fold semantics,
  - chained relational operators use adjacent-pair conjunction, for example `(< a b c)` means `((a < b) && (b < c))`,
  - and any allowed operator form must have an explicit unambiguous interpretation with examples.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task.
- Validation:
  - `git diff --check` (pass)
### future language-design agreements for `(3)`, `(4)`, and `(5)` are now preserved
- Saved the current design agreements in [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) for:
  - guarded blocks `(3)`,
  - condition suffixes `(4)`,
  - and update shorthand `(5)`.
- The saved agreement set now states:
  - guarded blocks are first-class,
  - nesting is unlimited,
  - nested guards compose by logical `AND`,
  - `<foo` and `<!foo` are shorthand for non-zero and zero tests,
  - relational shorthand such as `<foo==3` lowers to the same guarded-block semantics,
  - condition suffixes have exactly the same semantics as guarded blocks and desugar to a single guarded action,
  - and update shorthand captures increment/decrement semantics for multi-bit register/flop targets.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task.
- Validation:
  - `git diff --check` (pass)
### post-roadmap improvement priorities are now preserved in engineering notes
- Saved the suggested post-`R0`..`R7` improvement order in [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) as candidate future workstreams rather than as live roadmap items.
- The saved recommendation order is:
  - language-contract hardening,
  - strict mode/support-tier enforcement,
  - diagnostics/provenance,
  - composition-contract strengthening,
  - regression corpus/support accounting,
  - public embedding/API stabilization,
  - and VHDL only after the contract work above.
- The notes also preserve the specific gray-zone cluster that should be resolved first in any future roadmap.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task.
- Validation:
  - `git diff --check` (pass)
### user guide now contains a live supported-constructs boundary for `.fsm`
- Expanded [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) with a new live section, `Currently supported .fsm constructs (live reference)`.
- The new section distinguishes three things explicitly:
  - what is fully supported right now,
  - what is implemented but not yet strong enough to present as fully regression-backed,
  - and what is explicitly out of active support.
- The guide now calls out standalone decision-tree blocks such as `(-alpha_dt ...)`, `(-misc ...)`, and `(-mycombit ...)` as part of the active supported surface, with the current runtime behavior stated plainly:
  - DT-only inputs are supported,
  - and they generate without a state-register plan.
- Tightened the top-level composition wording in the guide so it now says composition is implemented in a deliberately narrow shipped model rather than "partially implemented", which better matches the closed scoped `R6` boundary.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task.
- Validation:
  - `git diff --check` (pass)
### `R7` closed with the shipped source-frontier hook
- Extended [perl/FSM/Extension/Context.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Context.pm) so hook contexts now carry:
  - `stage`,
  - and `raw_ast` when the hook runs at the parsed-source frontier.
- Extended [perl/FSM/Extension/Registry.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Registry.pm) so the shipped typed hook set now includes:
  - `after_parse_source($context)`,
  - and `after_generate_result($context)`.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so `after_parse_source($context)` runs:
  - after source parsing and classification for normal FSM inputs,
  - and after source parsing/classification plus typed composition-IR parsing for top-level composition inputs.
- Updated [t/26-extension-mechanism.t](/Users/richarddje/Documents/github/fsmgen/t/26-extension-mechanism.t), [t/lib/FSM/TestExtension/Marker.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/TestExtension/Marker.pm), and [t/27-extension-loading.t](/Users/richarddje/Documents/github/fsmgen/t/27-extension-loading.t) so the new hook boundary is now locked across:
  - direct object injection,
  - explicit module-name loading,
  - and CLI loading.
- Updated [docs/EXTENSION_MODEL.md](/Users/richarddje/Documents/github/fsmgen/docs/EXTENSION_MODEL.md), [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the now-complete `R7` boundary is described truthfully.
- Live roadmap status change:
  - `R7` moved from `mostly done` to `done`,
  - the current active lane moved from `R7` to `none`,
  - all currently defined roadmap workstreams `R0` through `R7` are now complete.
- Validation:
  - `perl -I perl -I t/lib -c perl/FSM/Extension/Context.pm` (pass)
  - `perl -I perl -I t/lib -c perl/FSM/Extension/Registry.pm` (pass)
  - `perl -I perl -I t/lib -c perl/FSM/Pipeline/HDLGenerator.pm` (pass)
  - `perl -I perl -I t/lib -c t/26-extension-mechanism.t` (pass)
  - `prove -I perl -I t/lib t/26-extension-mechanism.t t/27-extension-loading.t t/28-extension-config-loading.t` (pass)
  - `git diff --check` (pass)
### `R7` shipped explicit extension-config loading and moved to mostly-done
- Extended [perl/FSM/Extension/Loader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Loader.pm) so it can parse explicit extension-config files, with the current narrow config contract being:
  - blank lines allowed,
  - `# ...` comment lines allowed,
  - and one active `module Module::Name` declaration per extension line.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so callers may now pass `extension_config_files => [ ... ]` in addition to direct objects and explicit module names.
- Updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) so repeated `--extension-config <file>` flags can load typed extensions from explicit config files.
- Added [t/28-extension-config-loading.t](/Users/richarddje/Documents/github/fsmgen/t/28-extension-config-loading.t) to lock:
  - config-file parsing through the loader,
  - programmatic pipeline loading through `extension_config_files`,
  - CLI loading through `--extension-config`,
  - and malformed-config diagnostics with file/line reporting.
- Updated [docs/EXTENSION_MODEL.md](/Users/richarddje/Documents/github/fsmgen/docs/EXTENSION_MODEL.md), [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [README.md](/Users/richarddje/Documents/github/fsmgen/README.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the explicit config-file layer is described truthfully.
- Live roadmap status change:
  - `R7` moved from `in progress` to `mostly done`,
  - the active lane stays `R7`,
  - the next honest `R7` step is now choosing the next typed hook boundary, not finishing extension loading.
- Validation:
  - `perl -I perl -I t/lib -c perl/FSM/Extension/Loader.pm` (pass)
  - `perl -I perl -I t/lib -c perl/FSM/Pipeline/HDLGenerator.pm` (pass)
  - `perl -I perl -I t/lib -c bin/fsmgen` (pass)
  - `perl -I perl -I t/lib -c t/28-extension-config-loading.t` (pass)
  - `prove -I perl -I t/lib t/27-extension-loading.t t/28-extension-config-loading.t` (pass)
  - `git diff --check` (pass)
### `R7` shipped explicit typed extension loading for pipeline and CLI
- Added [perl/FSM/Extension/Loader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Loader.pm) as the explicit typed module loader for the new extension architecture. It:
  - validates module-name syntax before `require`,
  - instantiates extensions through `new()`,
  - and rejects non-object returns with targeted diagnostics.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so callers may now pass `extension_modules => [ 'Module::Name', ... ]` in addition to direct `extensions => [ $object, ... ]`.
- Updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) so repeated `--extension-module Module::Name` flags can load explicit typed extensions from `@INC` without reviving `.plg` scanning or implicit discovery.
- Added [t/lib/FSM/TestExtension/Marker.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/TestExtension/Marker.pm) and [t/27-extension-loading.t](/Users/richarddje/Documents/github/fsmgen/t/27-extension-loading.t) to lock:
  - explicit module loading through the loader,
  - programmatic pipeline loading through `extension_modules`,
  - CLI loading through `--extension-module`,
  - and targeted failure for missing extension modules.
- Updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/EXTENSION_MODEL.md](/Users/richarddje/Documents/github/fsmgen/docs/EXTENSION_MODEL.md), [README.md](/Users/richarddje/Documents/github/fsmgen/README.md), [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the new explicit loading path is described truthfully.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task,
  - but `R7` `Done` / `Left` advanced because loading is now explicit programmatic-plus-CLI rather than programmatic-only.
- Validation:
  - `perl -I perl -I t/lib -c perl/FSM/Extension/Loader.pm` (pass)
  - `perl -I perl -I t/lib -c perl/FSM/Pipeline/HDLGenerator.pm` (pass)
  - `perl -I perl -I t/lib -c bin/fsmgen` (pass)
  - `perl -I perl -I t/lib -c t/27-extension-loading.t` (pass)
  - `prove -I perl -I t/lib t/26-extension-mechanism.t t/27-extension-loading.t` (pass)
  - `git diff --check` (pass)
### typed-extension docs now explain the shipped boundary with concrete examples
- Expanded [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) with a new user-facing section explaining what a typed extension is in the current `R7` architecture.
- The guide now makes the current boundary concrete:
  - a typed extension is a normal blessed Perl object,
  - the shipped hook is an explicit method (`after_generate_result($context)`),
  - and the hook receives a typed context object rather than legacy string-dispatch data.
- Added realistic examples in the user guide for:
  - annotating the returned generation result,
  - and collecting post-generation telemetry across multiple runs.
- Tightened [docs/EXTENSION_MODEL.md](/Users/richarddje/Documents/github/fsmgen/docs/EXTENSION_MODEL.md) so it now explains what "typed" means explicitly in this project: object + method + context, not `.plg` scanning plus `AUTOLOAD` / eval lookup.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task.
- Validation:
  - `git diff --check` (pass)
### `R7` started with a typed extension registry and first live hook
- Added [docs/EXTENSION_MODEL.md](/Users/richarddje/Documents/github/fsmgen/docs/EXTENSION_MODEL.md) to define the first modern replacement seam for legacy `.plg` / `PPlugin`, including the deliberately narrow current boundary and explicit non-goals.
- Added [perl/FSM/Extension/Registry.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Registry.pm) and [perl/FSM/Extension/Context.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Context.pm) as the first typed extension primitives for the active architecture.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so callers can pass programmatic `extensions => [ ... ]` objects and the live pipeline now dispatches `after_generate_result($context)` for both FSM and composition results before returning them.
- Added [t/26-extension-mechanism.t](/Users/richarddje/Documents/github/fsmgen/t/26-extension-mechanism.t) to lock:
  - registry rejection of non-object extension entries,
  - hook dispatch for a normal FSM generation result,
  - and hook dispatch for a composition generation result.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [README.md](/Users/richarddje/Documents/github/fsmgen/README.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the first shipped `R7` boundary is stated truthfully in the live board and onboarding docs.
- Live roadmap status change:
  - `R7` moved from `not started` to `in progress`,
  - the active lane stays `R7`,
  - the next honest `R7` decision is now whether loading remains programmatic-only or grows an explicit config/CLI path, and which typed hook boundary comes next.
- Validation:
  - `perl -I perl -c perl/FSM/Extension/Context.pm` (pass)
  - `perl -I perl -c perl/FSM/Extension/Registry.pm` (pass)
  - `perl -I perl -c perl/FSM/Pipeline/HDLGenerator.pm` (pass)
  - `perl -I perl -c t/26-extension-mechanism.t` (pass)
  - `prove -I perl t/26-extension-mechanism.t` (pass)
  - `git diff --check` (pass)
### `R6` shipped `C6` legacy-scope failures and closed the composition lane
- Tightened [perl/FSM/Composition/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Parser.pm) so the remaining reachable legacy composition shapes now fail explicitly and consistently with scope-doc pointers instead of relying on generic parser fallout.
- The tightened explicit-scope failures now cover:
  - legacy macro/plugin children such as `?&name`,
  - nested `?top` blocks,
  - legacy `?ports` mapping directives,
  - and nested `?toplink` structures.
- Added [t/25-composition-legacy-scope-errors.t](/Users/richarddje/Documents/github/fsmgen/t/25-composition-legacy-scope-errors.t) to lock:
  - parser failure for the remaining out-of-scope legacy shapes,
  - and parser/pipeline/CLI failure for legacy macro/plugin composition input.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the shipped `C6` boundary and the resulting roadmap transition are stated truthfully.
- Live roadmap status change:
  - `R6` moved from `mostly done` to `done`,
  - the active lane moved from `R6` to `R7`,
  - `R7` is now the next honest roadmap lane,
  - the `.rtlif` grammar / stronger-interface-contract note remains recorded as a future refinement and is not an `R6` blocker.
- Validation:
  - `perl -I perl -c perl/FSM/Composition/Parser.pm` (pass)
  - `perl -I perl -c t/25-composition-legacy-scope-errors.t` (pass)
  - `prove -I perl t/25-composition-legacy-scope-errors.t` (pass)
  - `prove -I perl t/14-composition-parser.t t/13-composition-source-classification.t` (pass)
  - `prove -I perl t` (pass)
  - `git diff --check` (pass)
### `R6` shipped `C5` width-mismatch diagnostics and moved to mostly-done
- Tightened [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so declared connect-by-name width mismatches now name both endpoints and their conflicting widths directly instead of only reporting an indirect “no compatible endpoint” miss.
- Locked explicit-link width-mismatch behavior in [t/23-composition-errors.t](/Users/richarddje/Documents/github/fsmgen/t/23-composition-errors.t).
- Extended [t/24-composition-connect-by-name.t](/Users/richarddje/Documents/github/fsmgen/t/24-composition-connect-by-name.t) so declared connect-by-name now also locks the width-mismatch case with both endpoints and widths called out directly.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the shipped `C5` boundary and the narrowed remaining `R6` work are stated truthfully.
- Live roadmap status change:
  - `R6` moved from `in progress` to `mostly done`,
  - the active lane stays `R6`,
  - the next honest slice is now `C6` explicit failure for out-of-scope legacy composition constructs,
  - and the `.rtlif` grammar / stronger-interface-contract follow-up remains recorded explicitly on the roadmap board.
- Validation:
  - `perl -I perl -c perl/FSM/Pipeline/HDLGenerator.pm` (pass)
  - `perl -I perl -c t/23-composition-errors.t` (pass)
  - `perl -I perl -c t/24-composition-connect-by-name.t` (pass)
  - `prove -I perl t/23-composition-errors.t t/24-composition-connect-by-name.t` (pass)
  - `prove -I perl t` (pass)
  - `git diff --check` (pass)
### `R6` user-guide clarification for realistic `=name` usage
- Expanded [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) with realistic `C4` `=name` examples instead of only the minimal synthetic one.
- The guide now shows:
  - direct top-level exposure of child FSM outputs by the same name,
  - pass-through of a top-level control input into one child by the same name,
  - and direct same-name exposure of an external RTL output backed by `.rtlif` metadata.
- Added practical guidance in the user guide for when `=name` is appropriate versus when explicit `?toplink` is still the right tool.
- Live roadmap status change:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task.
- Validation:
  - `git diff --check` (pass)
### `R6` first shipped `C4` declared connect-by-name lane
- Landed the first active declared connect-by-name runtime slice in [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm).
- The shipped `C4` boundary is intentionally narrow:
  - top ports may be declared as `=name` inside `?ports`,
  - connect-by-name applies only to those explicitly declared top ports,
  - and planning succeeds only when exactly one same-named child endpoint matches by direction and width.
- Updated [perl/FSM/Composition/Port.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Port.pm) and [perl/FSM/Composition/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Parser.pm) so `?ports` tokens can now carry explicit connect-by-name intent through a `binding_mode` on typed ports.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the composition path now:
  - recognizes a dedicated `C4` lane when `?ports` contains `=name` declarations,
  - synthesizes typed by-name links for those declarations,
  - and rejects ambiguous or missing matches explicitly instead of widening implicit inference.
- Tightened [t/14-composition-parser.t](/Users/richarddje/Documents/github/fsmgen/t/14-composition-parser.t) so the parser now locks `=port` shape and connect-by-name preservation on typed ports.
- Added [t/24-composition-connect-by-name.t](/Users/richarddje/Documents/github/fsmgen/t/24-composition-connect-by-name.t) to lock:
  - the first `C4` success path,
  - ambiguous same-name match rejection,
  - and missing-child-endpoint rejection.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_LEGACY_MAPPING.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_LEGACY_MAPPING.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the docs now describe the shipped `C4` subset truthfully.
- Live roadmap status change:
  - no phase status changed,
  - `R6` remains `in progress`,
  - but `R6` `Done` / `Left` moved forward because the first `C4` slice is now shipped, the next honest slice is `C5`, and the `.rtlif` grammar/stronger-interface-contract follow-up is now recorded explicitly in the roadmap board.
- Validation:
  - `perl -I perl -c perl/FSM/Composition/Port.pm` (pass)
  - `perl -I perl -c perl/FSM/Composition/Parser.pm` (pass)
  - `perl -I perl -c perl/FSM/Pipeline/HDLGenerator.pm` (pass)
  - `perl -I perl -c t/14-composition-parser.t` (pass)
  - `perl -I perl -c t/24-composition-connect-by-name.t` (pass)
  - `prove -I perl t/14-composition-parser.t t/20-composition-single-fsm-top.t t/21-composition-two-fsm-linking.t t/22-composition-fsm-plus-rtl.t t/23-composition-errors.t t/24-composition-connect-by-name.t` (pass)
  - `prove -I perl t` (pass)
  - `git diff --check` (pass)
### `R6` first shipped `C3` mixed FSM-plus-RTL lane
- Landed the first active mixed composition runtime slice in [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm).
- The shipped `C3` boundary is intentionally narrow:
  - exactly one embedded `?fsmc` child,
  - exactly one external `?rtl` child,
  - one explicit `?ports` block,
  - explicit `?toplink` wiring using top-port names and `instance.port` child endpoints,
  - and sidecar external-interface metadata loaded from `<module>.rtlif`.
- Added [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm) as the first modern external-RTL interface loader. It:
  - searches for `<module>.rtlif` first beside the composition source and then through existing `FSMLIB` roots,
  - parses a typed `?rtlif:<module>` root,
  - and materializes typed composition ports for external RTL validation/wiring.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the composition path now:
  - realizes `?rtl` children through the typed sidecar metadata loader instead of hard-rejecting them,
  - chooses a dedicated `C3` plan when the source contains one `?fsmc` child plus one `?rtl` child,
  - reuses the explicit-link planner across mixed-child wiring,
  - instantiates the external RTL child without regenerating its internals.
- Added [t/22-composition-fsm-plus-rtl.t](/Users/richarddje/Documents/github/fsmgen/t/22-composition-fsm-plus-rtl.t) to lock:
  - the shipped `C3` success path,
  - typed external-interface loading,
  - mixed `?fsmc` + `?rtl` binding plans,
  - generated top HDL,
  - and CLI output generation for the mixed lane.
- Extended [t/23-composition-errors.t](/Users/richarddje/Documents/github/fsmgen/t/23-composition-errors.t) so mixed composition now also locks:
  - unknown external-RTL port rejection,
  - and direction-mismatch rejection for external-RTL endpoints.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [README.md](/Users/richarddje/Documents/github/fsmgen/README.md), [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [docs/COMPOSITION_LEGACY_MAPPING.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_LEGACY_MAPPING.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the docs now describe the shipped `C3` subset truthfully.
- Live roadmap status change:
  - no phase status changed,
  - `R6` remains `in progress`,
  - but `R6` `Done` / `Left` moved forward because `C3` is now shipped and the next honest slice is `C4` declared connect-by-name.
- Validation:
  - `perl -I perl -c perl/FSM/Composition/RTLInterfaceLoader.pm` (pass)
  - `perl -I perl -c perl/FSM/Pipeline/HDLGenerator.pm` (pass)
  - `perl -I perl -c t/22-composition-fsm-plus-rtl.t` (pass)
  - `perl -I perl -c t/23-composition-errors.t` (pass)
  - `prove -I perl t/20-composition-single-fsm-top.t t/21-composition-two-fsm-linking.t t/22-composition-fsm-plus-rtl.t t/23-composition-errors.t` (pass)
  - `prove -I perl t` (pass)
  - `git diff --check` (pass)
### `R6` first shipped `C2` FSM-linking lane
- Landed the first active multi-child composition runtime slice in [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm).
- The shipped `C2` boundary is still intentionally bounded:
  - two or more embedded `?fsmc` children,
  - one explicit `?ports` block,
  - explicit `?toplink` wiring using top-port names and `instance.port` child endpoints,
  - deterministic instance ordering,
  - deterministic internal-net creation for child-to-child links,
  - duplicate-driver rejection before emission.
- Added [perl/FSM/Composition/Net.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Net.pm) and extended the typed runtime plan:
  - [perl/FSM/Composition/Plan.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Plan.pm) now carries typed internal nets,
  - [perl/FSM/Composition/RealizedInstance.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RealizedInstance.pm) now carries per-instance port bindings used during top emission.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the composition path now:
  - supports a `C2` planning lane when multiple embedded `?fsmc` children and explicit `?toplink` blocks are present,
  - resolves explicit link endpoints as either top-port names or `instance.port` child endpoints,
  - validates source/target roles and exact width agreement,
  - auto-wires shared `clk` / `rstn` system inputs across realized children,
  - creates deterministic internal nets for child-to-child links,
  - emits multi-child top modules using planned port bindings rather than recomputing wiring during emission.
- Tightened the parser regression in [t/14-composition-parser.t](/Users/richarddje/Documents/github/fsmgen/t/14-composition-parser.t) so dotted `instance.port` link endpoints are now locked explicitly.
- Added [t/21-composition-two-fsm-linking.t](/Users/richarddje/Documents/github/fsmgen/t/21-composition-two-fsm-linking.t) to lock:
  - the shipped `C2` success path,
  - deterministic internal-net naming,
  - deterministic instance ordering,
  - per-instance binding plans,
  - and CLI output generation for the two-child explicit-link lane.
- Added [t/23-composition-errors.t](/Users/richarddje/Documents/github/fsmgen/t/23-composition-errors.t) to lock duplicate-driver rejection for explicit composition links.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [README.md](/Users/richarddje/Documents/github/fsmgen/README.md), [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the docs now describe the shipped `C2` subset truthfully.
- Live roadmap status change:
  - no phase status changed,
  - `R6` remains `in progress`,
  - but `R6` `Done` / `Left` moved forward again because the next honest slice is now `C3` mixed `?fsmc` + `?rtl` realization rather than more FSM-only linking groundwork.
- Validation:
  - `perl -I perl -c perl/FSM/Composition/Net.pm` (pass)
  - `perl -I perl -c perl/FSM/Pipeline/HDLGenerator.pm` (pass)
  - `perl -I perl -c t/21-composition-two-fsm-linking.t` (pass)
  - `perl -I perl -c t/23-composition-errors.t` (pass)
  - `prove -I perl t/13-composition-source-classification.t t/14-composition-parser.t t/20-composition-single-fsm-top.t t/21-composition-two-fsm-linking.t t/23-composition-errors.t` (pass: `Files=5`, `Tests=120`)
  - `prove -I perl t` (pass)
  - `git diff --check` (pass)
### `R6` first shipped `C1` composition generation lane
- Landed the first active composition runtime slice in [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm).
- The shipped `C1` boundary is intentionally narrow:
  - one `?top:name`,
  - one embedded `?fsmc` child source in the same file,
  - one explicit `?ports` block,
  - deterministic same-name top wiring,
  - generated child HDL plus generated top HDL through `bin/fsmgen`.
- Added typed composition planning objects for this runtime slice:
  - [perl/FSM/Composition/Port.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Port.pm)
  - [perl/FSM/Composition/Link.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Link.pm)
  - [perl/FSM/Composition/Plan.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Plan.pm)
  - [perl/FSM/Composition/RealizedInstance.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RealizedInstance.pm)
- Updated [perl/FSM/Composition/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Parser.pm) so:
  - `?ports` are parsed into typed `Port` objects,
  - `?toplink` entries are parsed into typed `Link` objects.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the composition path now:
  - realizes one embedded `?fsmc` child through the active FSM pipeline,
  - captures the realized child interface as typed ports,
  - treats `clk` / `rstn` as the current implicit system-input part of that child interface,
  - validates explicit top-port exposure against the realized child interface,
  - emits the generated top module and returns composition-aware `module_info` / statistics.
- Added [t/20-composition-single-fsm-top.t](/Users/richarddje/Documents/github/fsmgen/t/20-composition-single-fsm-top.t) as the first end-to-end composition acceptance test. It locks:
  - typed composition planning for `C1`,
  - child realization,
  - generated top HDL,
  - deterministic same-name instance wiring,
  - and CLI output generation through `bin/fsmgen`.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [README.md](/Users/richarddje/Documents/github/fsmgen/README.md), [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the docs now describe the shipped `C1` boundary truthfully instead of still calling composition entirely unimplemented.
- Live roadmap status change:
  - no phase status changed,
  - `R6` remains `in progress`,
  - but `R6` `Done` / `Left` moved forward to reflect that `C1` is now shipped and the next honest slice is `C2`-oriented multi-child/link planning.
- Validation:
  - `perl -I perl -c perl/FSM/Composition/RealizedInstance.pm` (pass)
  - `perl -I perl -c perl/FSM/Pipeline/HDLGenerator.pm` (pass)
  - `perl -I perl -c t/20-composition-single-fsm-top.t` (pass)
  - `prove -I perl t/13-composition-source-classification.t t/14-composition-parser.t t/20-composition-single-fsm-top.t` (pass: `Files=3`, `Tests=79`)
  - `prove -I perl t` (pass)
  - `git diff --check` (pass)
### `R6` legacy mapping note and first typed composition parser/IR slice
- Added [docs/COMPOSITION_LEGACY_MAPPING.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_LEGACY_MAPPING.md) as the historical-context note for composition work.
- The note records:
  - the obsolete composition call tree in `fx/bin/fsmgen` / `fx/perl/FSMGen.pm`,
  - the role of legacy `top_exec(...)`,
  - the surviving language concepts (`?top`, `?fsmc`, `?rtl`, `?ports`, `?toplink`),
  - and the mechanisms the active architecture must not revive (`AUTOLOAD`, `PPlugin`, `.plg`, late architecture plugins).
- Added the first typed composition parser/IR packages:
  - [perl/FSM/Composition/Spec.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Spec.pm)
  - [perl/FSM/Composition/Top.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Top.pm)
  - [perl/FSM/Composition/Instance.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Instance.pm)
  - [perl/FSM/Composition/PortsBlock.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/PortsBlock.pm)
  - [perl/FSM/Composition/TopLink.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/TopLink.pm)
  - [perl/FSM/Composition/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Parser.pm)
- Behavior change in [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm):
  - `?top:name` inputs are now not only classified, but also parsed through the first typed composition parser/IR boundary before failing at the still-unimplemented child-realization/top-emission stage.
- The typed parser currently supports:
  - `?top:name`
  - `?fsmc`
  - `?rtl`
  - `?ports`
  - `?toplink`
- The typed parser now rejects several legacy-only shapes explicitly instead of silently inheriting them:
  - inline top-port shorthand under `?top:name`
  - multi-source `?fsmc`
  - nested `?top`
  - unknown child kinds
- Updated [t/13-composition-source-classification.t](/Users/richarddje/Documents/github/fsmgen/t/13-composition-source-classification.t) so the pipeline/CLI boundary is now locked after typed composition parsing.
- Added [t/14-composition-parser.t](/Users/richarddje/Documents/github/fsmgen/t/14-composition-parser.t) to cover:
  - typed parsing of a real legacy composition fixture (`fsm/trial_1.fsm`)
  - typed parsing of explicit `?ports` / `?fsmc` / `?rtl` / `?toplink` blocks
  - explicit parser errors for unsupported legacy shorthand
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [README.md](/Users/richarddje/Documents/github/fsmgen/README.md), [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md), [MEMORY.md](/Users/richarddje/Documents/github/fsmgen/MEMORY.md), and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) so the active `R6` state now reflects parser/IR progress rather than only scope-plus-boundary classification.
- Validation:
  - `perl -I perl -c perl/FSM/Composition/Spec.pm` (pass)
  - `perl -I perl -c perl/FSM/Composition/Top.pm` (pass)
  - `perl -I perl -c perl/FSM/Composition/Instance.pm` (pass)
  - `perl -I perl -c perl/FSM/Composition/PortsBlock.pm` (pass)
  - `perl -I perl -c perl/FSM/Composition/TopLink.pm` (pass)
  - `perl -I perl -c perl/FSM/Composition/Parser.pm` (pass)
  - `perl -I perl -c perl/FSM/Pipeline/HDLGenerator.pm` (pass)
  - `perl -I perl -c t/14-composition-parser.t` (pass)
  - `prove -I perl t/13-composition-source-classification.t t/14-composition-parser.t` (pass: `Files=2`, `Tests=38`)
### Composition source classification at the active pipeline boundary
- Added [perl/FSM/SourceClassifier.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/SourceClassifier.pm) as the shared top-level source-kind classifier for raw Lispish ASTs.
- Updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the active pipeline now classifies source kind before invoking the FSM-only adapter path.
- Behavior change:
  - `?fsm:name` / `+fsm` inputs continue through the existing single-FSM pipeline unchanged,
  - `?top:name` inputs are now recognized explicitly and fail at the composition boundary with a deliberate diagnostic pointing to [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md),
  - unsupported composition input no longer falls through to the generic `Expected FSM structure containing '?fsm:name' or '+fsm'` parser error.
- Updated [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) so direct FSM-only parser callers also get a composition-specific boundary error for `?top:name`.
- Added [t/13-composition-source-classification.t](/Users/richarddje/Documents/github/fsmgen/t/13-composition-source-classification.t) to lock:
  - `?fsm:name` vs `?top:name` classification,
  - pipeline rejection of unsupported composition input,
  - direct adapter rejection of composition input at the FSM-only parser boundary,
  - CLI surfacing of the composition-boundary diagnostic.
- Tightened [t/01-regression.t](/Users/richarddje/Documents/github/fsmgen/t/01-regression.t) so the broad sample compile sweep now includes only active FSM-root fixtures according to the new shared classifier, instead of treating top-level composition samples as supported single-FSM inputs.
- Retargeted [t/09-ast-first-intermediate-registry.t](/Users/richarddje/Documents/github/fsmgen/t/09-ast-first-intermediate-registry.t) and [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t) from `fsm/trial_1.fsm` to `fsm/lte_dif_pmaster.fsm`, because those architecture tests are supposed to exercise the active single-FSM pipeline rather than a legacy composition fixture.
- Updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md), [README.md](/Users/richarddje/Documents/github/fsmgen/README.md), [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), and [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md) so the active boundary now reflects explicit composition source detection even though full composition support is still not implemented.
- Validation:
  - `perl -I perl -c perl/FSM/SourceClassifier.pm` (pass)
  - `perl -I perl -c perl/FSM/Pipeline/HDLGenerator.pm` (pass)
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm` (pass)
  - `perl -I perl -c t/01-regression.t` (pass)
  - `prove -I perl t/01-regression.t` (pass)
  - `prove -I perl t/13-composition-source-classification.t` (pass: `Files=1`, `Tests=14`)
### Roadmap phase transition (`R6` not started -> in progress)
- Started the first concrete `R6` slice by turning composition work into a scoped active-architecture plan instead of leaving it as roadmap terminology.
- Updated `ROADMAP_STATUS.md` to record the live status change:
  - `R6` moved from `not started` to `in progress`,
  - the active lane remains `R6`,
  - the next decision point is now implementation of the first typed `?top:name` composition classifier/parser slice above the current FSM-only parser boundary.
- Validation:
  - `git diff --check` (pass)
  - `rg -n "COMPOSITION_SCOPE\\.md|\\?top:name|\\?fsmc|\\?rtl|\\?ports|\\?toplink|R6.*in progress|Composition-oriented language" README.md docs/USER_GUIDE.md docs/COMPOSITION_SCOPE.md ROADMAP_STATUS.md MEMORY.md CHANGES.md DEVELOPMENT_NOTES.md` (pass)
### Composition scope definition for active architecture
- Added [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md) as the normative scope and acceptance-boundary document for the first `R6` composition lane.
- Grounded the scope in the active architecture instead of the obsolete legacy flow:
  - current boundary is `bin/fsmgen` -> `FSM::Pipeline::HDLGenerator` -> `FSM::Adapter::FSMGenFull::Parser`,
  - current parser accepts only `?fsm:name` / `+fsm`,
  - first composition lane is defined around a separate `?top:name` path plus typed composition IR and deterministic top emission.
- Defined the first in-scope composition model:
  - `?fsmc` child FSM instances,
  - `?rtl` external RTL instances,
  - `?ports` top interface declarations,
  - `?toplink` explicit wiring,
  - deterministic connect-by-name only when declared and unambiguous.
- Defined the executable acceptance matrix for composition (`C1`..`C6`) and the planned focused test-file split (`t/20`..`t/23`).
- Updated [README.md](/Users/richarddje/Documents/github/fsmgen/README.md) and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) so the scope doc is discoverable and the user guide explicitly states that composition is not yet implemented in the active toolchain.
- Validation:
  - `git diff --check` (pass)
  - `rg -n "COMPOSITION_SCOPE\\.md|\\?top:name|\\?fsmc|\\?rtl|\\?ports|\\?toplink|R6.*in progress|Composition-oriented language" README.md docs/USER_GUIDE.md docs/COMPOSITION_SCOPE.md ROADMAP_STATUS.md MEMORY.md CHANGES.md DEVELOPMENT_NOTES.md` (pass)
### Roadmap snapshot hardening (show `Rj` descriptions)
- Tightened the roadmap board and commit workflow so every live-status snapshot now shows each `Rj` with at least `status + brief description`.
- Added explicit `Description` fields to every workstream in `ROADMAP_STATUS.md`, so the board now answers not only “where are we?” but also “what does this phase do?” without requiring the user to infer it from deliverables.
- Updated `COMMIT.md`, `.agents/workflows/commit.md`, and `MEMORY.md` so commit close-outs must:
  - show `status + description` for every `Rj`,
  - and optionally add brief sub-bullets for the active lane, changed lane, or any phase whose next step matters right now.
- Validation:
  - `git diff --check` (pass)
  - `rg -n '^Description:|status \\+ description|show every' ROADMAP_STATUS.md COMMIT.md .agents/workflows/commit.md MEMORY.md CHANGES.md DEVELOPMENT_NOTES.md` (pass)
### Roadmap phase transition (`R3` done, active lane -> `R6`)
- Audited the remaining runtime-convergence residue after removing direct stored-expression parsing from normal backend runtime-AST resolution.
- Audit result:
  - `resolve_intermediate_signal_runtime_ast(...)` no longer parses stored expressions directly,
  - the remaining compatibility residue is now explicit and narrow: miss-recovery parsing in `recover_runtime_ast_from_dependency_expression(...)` plus the owner-side compatibility parser in `EnableGraph` for legacy registry/global-expression entries,
  - that satisfies the `R3` exit criteria because compatibility parsing is no longer part of the default runtime path.
- Updated `ROADMAP_STATUS.md` to record the live status change:
  - `R3` moved from `mostly done` to `done`,
  - current active lane changed from `R3` to `R6`,
  - `R6` next decision point is now concrete scope definition plus acceptance tests for composition work in the active architecture.
- Validation:
  - `git diff --check` (pass)
  - focused regression `prove -I perl t/07-runtime-ast-miss-dependency-recovery.t` (pass: `Files=1`, `Tests=21`)
  - full regression `prove -I perl t` (pass: `Files=12`, `Tests=413`)
### AST/CoreAST convergence (`R3`: remove direct stored-expression runtime parse)
- Removed the direct stored-expression compatibility parse from `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm::resolve_intermediate_signal_runtime_ast(...)`.
- Behavior change:
  - stored-expression-only runtime-AST resolution now records `runtime_ast_miss_reason = no_ast_source` instead of synthesizing `parsed_expression_ast` / `cleaned_expression_ast`,
  - explicit runtime-AST-miss dependency recovery remains the only backend path that can promote `runtime_ast` from a compatibility expression.
- Extended `t/07-runtime-ast-miss-dependency-recovery.t` so it now proves:
  - direct stored-expression runtime-AST resolution no longer parses compatibility expressions on the normal path,
  - stored-expression-only runtime-AST resolution records a missing state,
  - explicit cleaned-expression miss recovery still works.
- Updated `ROADMAP_STATUS.md` to reflect that `R3` is now complete and `R6` is the next active lane.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `perl -I perl -c t/07-runtime-ast-miss-dependency-recovery.t` (pass)
  - `prove -I perl t/07-runtime-ast-miss-dependency-recovery.t` (pass: `Files=1`, `Tests=21`)
### Commit workflow hardening (always display live-status tracker)
- Tightened the commit workflow so the user-facing close-out must now always display the current live-status snapshot from `ROADMAP_STATUS.md` whenever the commit workflow runs.
- Clarified the expected close-out language:
  - if the task changed live status, the close-out must state how the snapshot changed,
  - if the task did not change live status, the close-out must explicitly say the snapshot is unchanged for that task.
- Updated the authoritative workflow docs in `COMMIT.md`, `.agents/workflows/commit.md`, `ROADMAP_STATUS.md`, and `MEMORY.md` to encode that rule consistently.
- Validation:
  - `git diff --check` (pass)
  - `rg -n "current live status snapshot|snapshot is unchanged|commit workflow runs" COMMIT.md .agents/workflows/commit.md ROADMAP_STATUS.md MEMORY.md CHANGES.md DEVELOPMENT_NOTES.md` (pass)
### AST/CoreAST convergence (`R3`: remove render-time late hydration)
- Removed the render-time “late hydration” retry from `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm::render_intermediate_signal_expression(...)`.
- Behavior change:
  - an intermediate signal that first misses runtime-AST resolution with `runtime_ast_miss_reason = no_ast_source` no longer silently promotes `runtime_ast` during plain expression rendering,
  - the remaining promotion path in this area is the explicit runtime-AST-miss dependency-recovery flow.
- Fixed `resolve_intermediate_signal_width(...)` so the backend’s explicit dependency-recovery path can call it with the shorter live argument list it already uses.
- Extended `t/07-runtime-ast-miss-dependency-recovery.t` so it now proves:
  - render-time expression fallback preserves the original `no_ast_source` miss state,
  - render-time fallback does not silently hydrate `runtime_ast`,
  - explicit dependency recovery can still promote `runtime_ast` from a cleaned compatibility expression and records that source explicitly.
- Updated `ROADMAP_STATUS.md` to narrow the remaining `R3` residue:
  - `R3` status stays `mostly done`,
  - `R3` `Left` now points specifically at the remaining direct raw/cleaned expression parsing inside backend runtime-AST resolution and dependency recovery.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t/07-runtime-ast-miss-dependency-recovery.t` (pass: `Files=1`, `Tests=17`)
### Roadmap phase transition (`R2` done, active lane -> `R3`)
- Audited the remaining `FlattenedDT` backend/orchestrator ownership boundary against the explicit `R2` deliverables in `ROADMAP_STATUS.md`.
- Audit result:
  - `Backend::SystemVerilog` no longer directly owns `assignment_analysis` / `lhs_assignments` mutation or owner-side analysis,
  - the remaining backend pocket is runtime AST recovery/filtering, dependency rescue/topological ordering, and emitted-signal rendering flow,
  - that matches the intended post-migration `R2` boundary.
- Updated `ROADMAP_STATUS.md` to record the live status change:
  - `R2` moved from `in progress` to `done`,
  - current active lane changed from `R2` to `R3`,
  - `R3` next decision point is now the remaining runtime-AST-miss / compatibility-parse fallback residue in `Backend::SystemVerilog`.
- Validation:
  - `git diff --check` (pass)
  - `rg -n "resolve_intermediate_signal_runtime_ast|should_filter_ast_based|should_filter_runtime_ast_miss|topologically_sort_signals|generate_consolidated_intermediate_signals" perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - backend audit confirms no remaining `assignment_analysis` / `lhs_assignments` matches in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
### FlattenedDT live ownership (EnableGraph live-usage evidence ownership)
- Moved intermediate-signal live-usage evidence helpers off `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` and under `perl/FSM/Synthesis/EnableGraph.pm`.
- Added `ast_contains_signal(...)` to `EnableGraph`, so owner-side AST signal-reference inspection now lives with the owner of the enable/capture structures being inspected.
- Added `is_signal_referenced_in_substitutions(...)`, `is_signal_actually_used_in_final_expressions(...)`, and `resolve_intermediate_signal_live_usage(...)` to `EnableGraph`.
- Updated `Backend::SystemVerilog` so consolidated intermediate-signal filtering now consumes owner-provided live-usage metadata instead of exposing those evidence helpers on the backend.
- Extended `t/10-ast-first-enable-structure.t` so:
  - the backend is asserted to stay free of the former live-usage evidence helper pocket,
  - and `EnableGraph` is asserted to own AST signal-reference inspection, substituted-expression/final-expression usage evidence, and cached live-usage metadata derivation on the live path.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=176`)
  - `prove -I perl t` (pass: `Files=12`, `Tests=400`)
### Roadmap deliverables hardening
- Tightened `ROADMAP_STATUS.md` so every `R0`..`R7` workstream now carries explicit deliverables, not just status labels and narrative summaries.
- Updated the board structure so each workstream must state:
  - `Deliverables`
  - `Status`
  - `Done`
  - `Left`
  - `Exit criteria`
- Re-defined the status scale on the live board so `done` now means all listed deliverables are complete and the exit criteria are met.
- Updated `MEMORY.md`, `COMMIT.md`, and `.agents/workflows/commit.md` so roadmap-board refreshes now also cover deliverable changes, not just status/remaining-work/active-lane changes.
- Validation:
  - `git diff --check` (pass)
  - `rg -n "^Deliverables:|roadmap deliverables|All listed `Deliverables`" ROADMAP_STATUS.md MEMORY.md COMMIT.md .agents/workflows/commit.md CHANGES.md DEVELOPMENT_NOTES.md` (pass)
### Live status visibility hardening
- Tightened the roadmap workflow so live-status changes are now both persistent and visible in the task close-out.
- Updated `ROADMAP_STATUS.md` so any workstream-status change or active-lane change now requires:
  - refreshing the live board,
  - logging the change in `CHANGES.md`,
  - and displaying the current live status snapshot in the user-facing close-out.
- Updated `MEMORY.md`, `COMMIT.md`, and `.agents/workflows/commit.md` so the same rule is part of the standard post-task workflow and not just an informal convention.
- Validation:
  - `git diff --check` (pass)
  - `rg -n "live status|status snapshot|ROADMAP_STATUS\\.md|CHANGES\\.md" ROADMAP_STATUS.md MEMORY.md COMMIT.md .agents/workflows/commit.md CHANGES.md DEVELOPMENT_NOTES.md` (pass)
### FlattenedDT live ownership (EnableGraph substitution synchronization ownership)
- Moved substitution-era AST rewrite/debug passes off `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` and under `perl/FSM/Synthesis/EnableGraph.pm`.
- Added `count_unary_negations_in_original_expressions(...)` to `EnableGraph`, so the same owner that already owns `assignment_analysis` and captured condition ASTs now also owns the unary-negation debug scan around substitution.
- Added `update_original_asts_with_substituted_versions(...)` and `update_original_asts_with_second_pass_substitutions(...)` to `EnableGraph`, plus a shared context-to-AST map helper used by both update passes.
- Updated `Backend::SystemVerilog::run_global_ast_factorization(...)` so first-pass substitution synchronization and the surrounding unary-negation debug scans now go through `EnableGraph`.
- Updated `perl/FSM/HDL/Factorization/Fixpoint.pm` so second-pass substitution synchronization now also goes through `EnableGraph`.
- Extended `t/10-ast-first-enable-structure.t` so:
  - the backend is asserted to stay free of the former substitution-update/debug helper pocket,
  - and `EnableGraph` is asserted to own the unary-negation debug scan plus first-pass and second-pass substitution synchronization on the live path.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/Factorization/Fixpoint.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=168`)
  - `prove -I perl t` (pass: `Files=12`, `Tests=392`)
### FlattenedDT live ownership (EnableGraph factorization AST-feed ownership)
- Moved factorization input feeding off `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` and under `perl/FSM/Synthesis/EnableGraph.pm`.
- Added `feed_asts_to_factorizer(...)` to `EnableGraph`, so the same owner that already owns `assignment_analysis`, captured condition ASTs, and intermediate-signal semantics now also owns the primary factorization AST feed.
- Added `feed_current_asts_to_second_pass(...)` to `EnableGraph` and moved the supporting second-pass eligibility helpers with it:
  - `ast_contains_intermediate_signals(...)`
  - `ast_has_intermediate_signals_recursive(...)`
- Updated `Backend::SystemVerilog::run_global_ast_factorization(...)` so primary factorization now feeds ASTs through `EnableGraph`.
- Updated `perl/FSM/HDL/Factorization/Fixpoint.pm` so second-pass AST collection now also goes through `EnableGraph`.
- Extended `t/10-ast-first-enable-structure.t` so:
  - the backend is asserted to stay free of the former factorization-feed helper pocket,
  - and `EnableGraph` is asserted to own first-pass AST feeding, second-pass AST feeding, and second-pass intermediate-signal eligibility checks on the live path.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/Factorization/Fixpoint.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=162`)
  - `prove -I perl t` (pass: `Files=12`, `Tests=386`)
### Roadmap tracking infrastructure hardening
- Added new tracked file `ROADMAP_STATUS.md` as the canonical live roadmap/workstream status board.
- Defined the allowed status values explicitly:
  - `done`
  - `mostly done`
  - `in progress`
  - `not started`
- Recorded the current baseline workstreams there with stable IDs, exact `Done` / `Left` summaries, and the current active lane.
- Updated the repo workflow/docs so this board is part of normal operating practice instead of optional narrative reconstruction:
  - `README.md` now points to `ROADMAP_STATUS.md` near the top of the ramp-up order,
  - `MEMORY.md` now treats `ROADMAP_STATUS.md` as the canonical live board for “done vs left” tracking,
  - `COMMIT.md` and `.agents/workflows/commit.md` now require refreshing `ROADMAP_STATUS.md` before commit when a task changes roadmap status, remaining work, or the active lane.
- Validation:
  - `git diff --check` (pass)
  - `rg -n "ROADMAP_STATUS\.md" README.md MEMORY.md COMMIT.md .agents/workflows/commit.md CHANGES.md DEVELOPMENT_NOTES.md` (pass)
### FlattenedDT live ownership (EnableGraph logical-op counting ownership)
- Moved binary logical-operation counting off `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` and under `perl/FSM/Synthesis/EnableGraph.pm`.
- Added `count_binary_logical_operation_occurrences(...)` to `EnableGraph`, so the same owner that already applies logical factorization policy now also owns the live counting pass that produces `binary_logical_op_counts`.
- Moved the supporting AST collection/traversal helper pocket with it:
  - `collect_all_wen_en_ast_expressions(...)`
  - `_count_logical_ops_in_ast(...)`
  - `_is_factorizable_sub_expression(...)`
- Updated `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` so step 4 now calls `enable_graph->count_binary_logical_operation_occurrences(...)` directly.
- Updated `Backend::SystemVerilog::run_global_ast_factorization(...)` so its defensive recount path now also goes through `EnableGraph`, and removed the former backend-side counting helper pocket.
- Extended `t/10-ast-first-enable-structure.t` so:
  - the backend is asserted to stay free of the former counting helper pocket,
  - and `EnableGraph` is asserted to own binary logical-operation counting on the live path.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=155`)
  - `prove -I perl t` (pass: `Files=12`, `Tests=379`)
### FlattenedDT live ownership (EnableGraph WEN/EN prescan ownership)
- Moved WEN/EN intermediate-signal prescan off `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` and under `perl/FSM/Synthesis/EnableGraph.pm`.
- Added `prescan_wen_en_for_intermediate_signals(...)` to `EnableGraph`, so the same owner that already owns `assignment_analysis`, DT/LHS enable ASTs, and `track_ast_intermediate_signals(...)` now also owns the live prescan that populates `referenced_intermediate_signals`.
- Updated `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` so step 5 now calls `enable_graph->prescan_wen_en_for_intermediate_signals(...)` directly.
- Removed the former backend-side `prescan_wen_en_for_intermediate_signals(...)` entrypoint from `Backend::SystemVerilog`.
- Extended `t/10-ast-first-enable-structure.t` so:
  - the backend is asserted to stay free of the former prescan entrypoint,
  - and `EnableGraph` is asserted to own WEN/EN intermediate-signal prescan on the live path.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=150`)
  - `prove -I perl t` (pass: `Files=12`, `Tests=374`)
### FlattenedDT live ownership (EnableGraph state register planning)
- Moved state-structure planning off backend-local regular-state scans and under `perl/FSM/Synthesis/EnableGraph.pm`.
- Added `build_state_register_plan(...)` to `EnableGraph`, so it now owns:
  - whether the FSM has regular states and therefore dedicated state registers,
  - regular-state encoding order and localparam names,
  - the current state-bit width contract,
  - and the reset-state localparam name used by the dedicated state register.
- Updated `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` so `generate_state_encoding(...)` and `generate_state_register(...)` now render the owner-provided state plan instead of recomputing regular-state structure locally.
- Updated `build_internal_signal_declaration_plan(...)` and `get_fsm_reset_state(...)` in `EnableGraph` to reuse the same state plan, removing duplicate regular-state scans from the live path.
- Extended focused regression coverage:
  - `t/11-flatteneddt-generation-reset.t` now inspects the state plan directly for standalone-DT-only FSMs,
  - `t/12-enablegraph-capture-registry.t` now inspects the state plan directly for regular-state FSMs,
  - `t/10-ast-first-enable-structure.t` now asserts `EnableGraph` owns state register planning on the live path.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t t/11-flatteneddt-generation-reset.t t/12-enablegraph-capture-registry.t` (pass)
  - `prove -I perl t` (pass)
### FlattenedDT live ownership (EnableGraph module declaration planning)
- Moved module/interface declaration planning off backend-local synthesis decisions and under `perl/FSM/Synthesis/EnableGraph.pm`.
- Added `build_module_declaration_plan(...)` to `EnableGraph`, so it now owns the live interface plan derived from signal and driven-signal classification, including:
  - base ports (`clk`, `rstn`),
  - input vs output direction,
  - `wire` vs `reg` storage,
  - signal width metadata,
  - and the derived `declared_port_signals` / `port_directions` registries consumed later in generation.
- Updated `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` so `generate_module_declaration(...)` now renders the owner-provided plan instead of recomputing those interface decisions locally.
- Preserved the legacy output-port formatting contract by teaching the backend renderer to keep `output reg  ...` spacing exactly stable.
- Extended focused regression coverage:
  - `t/03-assignment-intent-metadata.t` now inspects the live module declaration plan directly for representative input/output ownership and port-registry metadata,
  - `t/10-ast-first-enable-structure.t` now asserts `EnableGraph` owns module declaration planning on the live path,
  - `t/05-assignment-hdl-snapshots.t` locks that emitted module-port text remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t/05-assignment-hdl-snapshots.t` (pass: `Files=1`, `Tests=12`)
  - `prove -I perl t/03-assignment-intent-metadata.t t/10-ast-first-enable-structure.t` (pass: `Files=2`, `Tests=242`)
  - `prove -I perl t` (pass: `Files=12`, `Tests=364`)
### FlattenedDT live ownership (EnableGraph internal declaration planning)
- Moved internal declaration planning off backend-local synthesis decisions and under `perl/FSM/Synthesis/EnableGraph.pm`.
- Added `build_internal_signal_declaration_plan(...)` to `EnableGraph`, so it now owns the live declaration plan derived from `assignment_analysis`, including:
  - plain internal reg declarations for non-port driven LHS signals,
  - dual-family helper regs such as `I_next` and `K_q`,
  - and pulse-delay helper declarations such as `P1_pulse_delay_pipe` / `P0_pulse_delay_pipe`.
- Updated `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` so `generate_internal_signal_declarations(...)` now renders the owner-provided declaration plan instead of recomputing those synthesis decisions locally.
- Extended focused regression coverage:
  - `t/03-assignment-intent-metadata.t` now inspects the live declaration plan directly for dual-output and pulse-delay helper declarations and verifies exposed ports like `next_I` / `K_r` are not redeclared internally,
  - `t/10-ast-first-enable-structure.t` now asserts `EnableGraph` owns internal declaration planning on the live path.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t/03-assignment-intent-metadata.t t/10-ast-first-enable-structure.t` (pass: `Files=2`, `Tests=224`)
  - `prove -I perl t` (pass: `Files=12`, `Tests=346`)
### FlattenedDT live ownership (EnableGraph unified WEN/EN emission)
- Moved stage-7 unified WEN/EN emission off the backend wrapper path and directly onto `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` so step 7 now calls `enable_graph->generate_unified_wen_en_signals(...)` directly.
- Removed the now-wrapper-only `generate_wen_en_signals(...)` method from `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- Extended `t/10-ast-first-enable-structure.t` so:
  - the backend is asserted to stay free of the former wrapper entrypoint,
  - and `EnableGraph` is asserted to own unified WEN/EN emission on the live path.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=145`)
  - `prove -I perl t` (pass: `Files=12`, `Tests=337`)
### FlattenedDT live ownership (EnableGraph top-level enable emission)
- Moved top-level state/DT enable emission off `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` and under `perl/FSM/Synthesis/EnableGraph.pm`.
- Added `generate_enable_conditions(...)` to `EnableGraph`, so the same owner that initializes and now AST-backs `state_enables` / `dt_enables` also emits their `*_en` assign statements.
- Updated `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` so step 3 of live generation now calls `enable_graph->generate_enable_conditions(...)` instead of the backend entrypoint.
- Removed the now-ownerless `generate_enable_conditions(...)` method from `Backend::SystemVerilog`.
- Extended `t/10-ast-first-enable-structure.t` so:
  - the backend is now asserted to stay free of the former top-level enable-emission helper,
  - and `EnableGraph` is asserted to own that live entrypoint.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t t/12-enablegraph-capture-registry.t` (pass: `Files=2`, `Tests=164`)
  - `prove -I perl t` (pass: `Files=12`, `Tests=335`)
### FlattenedDT AST-first live convergence (AST-backed top-level enable registries)
- Converted the live top-level `state_enables` / `dt_enables` registries from plain strings to AST-backed conditions.
- Added `build_state_enable_condition_ast(...)` and `build_dt_enable_condition_ast(...)` to `perl/FSM/Synthesis/EnableGraph.pm`, so top-level enable-condition construction for regular states and standalone DTs is now owned and produced there as AST.
- Updated `initialize_state_and_dt_enable_conditions(...)` so:
  - regular states now store an AST for `current_state == STATE`,
  - standalone DTs now store an AST for `1'b1`,
  - and downstream logic continues to use the same registry keys while consuming typed values.
- Updated `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` so `generate_enable_conditions(...)` renders those top-level enable conditions from AST objects instead of assuming raw strings.
- Extended regression coverage:
  - `t/10-ast-first-enable-structure.t` now asserts top-level `state_enables` / `dt_enables` are AST-backed,
  - `t/11-flatteneddt-generation-reset.t` now asserts standalone DT enable entries remain AST-backed and semantically `1'b1` across generator reuse.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t t/11-flatteneddt-generation-reset.t` (pass: `Files=2`, `Tests=158`)
  - `prove -I perl t/12-enablegraph-capture-registry.t` (pass: `Files=1`, `Tests=21`)
  - `prove -I perl t` (pass: `Files=12`, `Tests=333`)
## 2026-03-13
### FlattenedDT live ownership (EnableGraph test-condition AST ownership)
- Moved the remaining live test-node condition AST construction off `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` and under `perl/FSM/Synthesis/EnableGraph.pm`.
- Added `build_test_condition_ast(...)` to `EnableGraph`, which now owns:
  - extraction/normalization of the test signal name,
  - test-branch literal conversion through the existing `convert_test_value_to_ast(...)` path,
  - and assembly of the `signal == value` AST used for `FSM::CoreAST::TestNode` branches.
- Updated `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` so `flatten_decision_tree(...)` now delegates test-branch equality AST construction to `enable_graph` instead of building it inline.
- Extended `t/12-enablegraph-capture-registry.t` so the focused capture fixture now includes a real `?MODE` test node and asserts:
  - pre-factorization assignment capture preserves `MODE == 1'b1` as the branch condition AST,
  - pre-factorization transition capture preserves the same test-node condition AST,
  - and full generation still emits enable logic containing the test comparison.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `prove -I perl t/12-enablegraph-capture-registry.t` (pass: `Files=1`, `Tests=21`)
  - `prove -I perl t/10-ast-first-enable-structure.t t/12-enablegraph-capture-registry.t` (pass: `Files=2`, `Tests=160`)
  - `prove -I perl t` (pass: `Files=12`, `Tests=327`)
### FlattenedDT live ownership (EnableGraph capture-entrypoint ownership)
- Moved the live assignment/transition capture entrypoints themselves under `perl/FSM/Synthesis/EnableGraph.pm`.
- Added `capture_assignment_from_ast(...)` and `capture_transition_from_ast(...)` to `EnableGraph`, so it now owns:
  - condition-stack-to-condition-AST assembly for capture,
  - assignment debug/capture preparation,
  - transition debug/capture preparation,
  - and the final registry writes already localized there in the previous slices.
- Updated `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` so `flatten_decision_tree(...)` now delegates assignment and transition capture directly to `enable_graph`.
- Removed the now-ownerless local `record_assignment_from_ast(...)` and `record_transition_from_ast(...)` methods from `Orchestrator`.
- Extended `t/10-ast-first-enable-structure.t` so the live internal architecture now also asserts the `Orchestrator` object no longer exposes those dead helper names.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t t/12-enablegraph-capture-registry.t` (pass: `Files=2`, `Tests=157`)
  - `prove -I perl t` (pass: `Files=12`, `Tests=324`)
### FlattenedDT live ownership (EnableGraph assignment-metadata normalization)
- Moved live assignment operator/intent/provenance normalization under `perl/FSM/Synthesis/EnableGraph.pm`.
- Added `extract_assignment_capture_metadata(...)` to `EnableGraph`, which now owns:
  - `assignment_intent` extraction/copy,
  - operator resolution from `operator_symbol` / intent fallback,
  - pulse-operator derivation from `pulse_cycles`,
  - strict validation of the supported operator set,
  - and capture of `source_provenance` / `output_exposure`.
- Updated `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` so `record_assignment_from_ast(...)` now delegates that normalization to `EnableGraph` before registering the capture.
- Extended `t/03-assignment-intent-metadata.t` so live generation now also asserts the captured assignment registry preserves:
  - ordinary register-style metadata (`A`),
  - explicit output exposure (`G`),
  - dual-output intent metadata (`I`),
  - and pulse operator / delay metadata (`P1`).
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `prove -I perl t/03-assignment-intent-metadata.t t/12-enablegraph-capture-registry.t` (pass: `Files=2`, `Tests=88`)
  - `prove -I perl t` (pass: `Files=12`, `Tests=322`)
### FlattenedDT live ownership (EnableGraph capture-shape normalization)
- Moved the remaining live LHS/RHS capture-shape normalization off `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` and under `perl/FSM/Synthesis/EnableGraph.pm`.
- Added `extract_rhs_capture_value(...)` to `EnableGraph` and broadened `extract_signal_name_from_ast(...)` so the owner-local signal-name helper now also handles indexed/reference-style AST renderings by leading identifier.
- Updated `Orchestrator` so:
  - assignment-node debug naming now uses `enable_graph->extract_signal_name_from_ast(...)`,
  - `record_assignment_from_ast(...)` now derives the captured LHS key through `EnableGraph`,
  - and captured RHS text now goes through `enable_graph->extract_rhs_capture_value(...)` instead of the local `extract_rhs_from_expression(...)` helper.
- Removed the now-ownerless local `extract_lhs_name_from_ast(...)` and `extract_rhs_from_expression(...)` helpers from `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `prove -I perl t/12-enablegraph-capture-registry.t t/11-flatteneddt-generation-reset.t` (pass: `Files=2`, `Tests=31`)
  - `prove -I perl t` (pass: `Files=12`, `Tests=314`)
### FlattenedDT live ownership (EnableGraph capture-registry ownership)
- Moved live capture-registry mutation for assignments and state transitions under `perl/FSM/Synthesis/EnableGraph.pm`.
- Added `register_assignment_capture(...)` and `register_transition_capture(...)` to `EnableGraph`, so the owner that later analyzes `lhs_assignments`, `all_lhs`, and `lhs_ast_map` now also owns registration of that data.
- Updated `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` so:
  - `record_assignment_from_ast(...)` still performs AST/intent extraction and validation locally,
  - but the actual registry write for captured assignment state now goes through `enable_graph->register_assignment_capture(...)`,
  - and state-transition capture now goes through `enable_graph->register_transition_capture(...)`.
- Added `t/12-enablegraph-capture-registry.t`, which exercises live generation on a small stateful FSM and asserts:
  - normal captured assignments remain AST-backed,
  - `next_state` transition capture is still registered with state-transition metadata,
  - the synthetic `next_state` AST remains available in `lhs_ast_map`,
  - and generated HDL still emits the expected state-enable and assignment-enable logic.
- Root cause / rationale:
  - `Orchestrator` was still directly mutating capture registries that are semantically phase-1 analysis input owned and consumed later by `EnableGraph`,
  - the next truthful structural step after the per-run reset slice was to move those live registry writes under the same owner that builds `assignment_analysis`,
  - this narrows another real ownership seam without changing traversal order or emitted HDL behavior.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `prove -I perl t/12-enablegraph-capture-registry.t` (pass: `Files=1`, `Tests=18`)
  - `prove -I perl t` (pass: `Files=12`, `Tests=314`)
### FlattenedDT live-state reset (per-run generation reset + enable-registry ownership)
- Added `reset_generation_state()` to `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` and now call it at the start of `generate_systemverilog(...)`.
- The reset clears per-run generation registries before each live generation pass, including:
  - `state_enables`, `dt_enables`,
  - `lhs_assignments`, `all_lhs`, `lhs_ast_map`, `assignment_analysis`,
  - `intermediate_signals`, `referenced_intermediate_signals`,
  - `global_expressions`, `expression_usage`,
  - `declared_port_signals`, `port_directions`,
  - and transient scratch like `binary_logical_op_counts`, `ast_factorizer`, and the cached `fsm_module`.
- Moved state/DT enable-registry seeding into `perl/FSM/Synthesis/EnableGraph.pm` via `initialize_state_and_dt_enable_conditions(...)`, so `Orchestrator::flatten_all_decision_trees(...)` now traverses while `EnableGraph` owns the enable-condition registries it later synthesizes.
- Added `t/11-flatteneddt-generation-reset.t`, which reuses one `FSM::HDL::FlattenedDT` object across two distinct FSM generations and asserts the second run does not leak first-run DT enables, assignment captures, assignment analysis, or signal names.
- Root cause / rationale:
  - the live generation path initialized most mutable registries only once in `new(...)`, which left same-object reuse vulnerable to stale per-run state,
  - the state/DT enable maps were also still seeded in `Orchestrator` even though they are consumed as enable-synthesis data by `EnableGraph` and the backend,
  - this slice makes generation re-entrant for the tested live path and narrows one more real ownership seam instead of continuing cleanup-only wrapper pruning.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `prove -I perl t/11-flatteneddt-generation-reset.t` (pass: `Files=1`, `Tests=13`)
  - `prove -I perl t` (pass: `Files=11`, `Tests=296`)
### FlattenedDT cleanup (retire residual analysis/declaration facade delegates)
- Removed the residual analysis/declaration delegate pocket from `perl/FSM/HDL/FlattenedDT.pm`:
  - deleted `generate_internal_signal_declarations(...)`,
  - deleted `get_lhs_width_from_analysis(...)`,
  - deleted `is_register(...)`,
  - deleted `fallback_register_analysis_from_assignments(...)`,
  - deleted `generate_intermediate_signals(...)`,
  - deleted `get_pulse_delay_cycles_for_lhs(...)`,
  - deleted `get_pulse_active_level_for_lhs(...)`,
  - deleted `get_signal_info(...)`.
- Extended `t/10-ast-first-enable-structure.t` to assert that live generation no longer exposes those analysis/declaration helper names on the `FlattenedDT` facade.
- Root cause / rationale:
  - repo-wide call-graph auditing showed these names had no remaining callers on the `FlattenedDT` facade anywhere in the active code or tests,
  - the matching methods remain live on `EnableGraph` or `Backend::SystemVerilog`, and the active flow already reaches them there directly,
  - `get_signal_assignment_type(...)` was intentionally kept because `t/03-assignment-intent-metadata.t` still exercises it as part of the tested `FlattenedDT` surface.
- Scope remains behavior-preserving cleanup of dead compatibility surface; live analysis/declaration behavior is unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=137`)
  - `prove -I perl t` (pass: `Files=10`, `Tests=283`)
### FlattenedDT cleanup (retire dead backend factorization/substitution facade delegates)
- Removed the dead backend factorization/substitution delegate pocket from `perl/FSM/HDL/FlattenedDT.pm`:
  - deleted `prescan_wen_en_for_intermediate_signals(...)`,
  - deleted `feed_asts_to_factorizer(...)`,
  - deleted `count_unary_negations_in_original_expressions(...)`,
  - deleted `ast_contains_signal(...)`,
  - deleted `update_original_asts_with_substituted_versions(...)`,
  - deleted `run_second_pass_factorization(...)`,
  - deleted `feed_current_asts_to_second_pass(...)`,
  - deleted `ast_contains_intermediate_signals(...)`,
  - deleted `ast_has_intermediate_signals_recursive(...)`,
  - deleted `update_original_asts_with_second_pass_substitutions(...)`,
  - deleted `get_substituted_ast_for_signal(...)`,
  - deleted `is_signal_referenced_in_substitutions(...)`,
  - deleted `topologically_sort_signals(...)`.
- Extended `t/10-ast-first-enable-structure.t` to assert that live generation no longer exposes those backend-owned factorization/substitution helper names on the `FlattenedDT` facade.
- Root cause / rationale:
  - repo-wide call-graph auditing showed these names had no remaining callers on the `FlattenedDT` facade anywhere in the active code or tests,
  - the matching methods remain live inside `Backend::SystemVerilog`, and the active flow already reaches them there directly from `Orchestrator`, `FSM::HDL::Factorization::Fixpoint`, or backend-local calls,
  - removing the dead facade delegates is safer than preserving an uncalled compatibility surface for factorization/substitution internals.
- Scope remains behavior-preserving cleanup of dead compatibility surface; live backend factorization/substitution behavior is unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=129`)
  - `prove -I perl t` (pass: `Files=10`, `Tests=275`)
### FlattenedDT cleanup (retire dead utility/rendering facade delegates)
- Removed a dead `EnableGraph` utility/rendering helper delegate pocket from `perl/FSM/HDL/FlattenedDT.pm`:
  - deleted `generate_ast_based_signal_name(...)`,
  - deleted `extract_signal_name_from_ast(...)`,
  - deleted `map_operator_to_name(...)`,
  - deleted `is_arithmetic_operation(...)`,
  - deleted `is_logical_operation(...)`,
  - deleted `should_factor_logical_operation(...)`,
  - deleted `contains_frequently_used_operations(...)`,
  - deleted `get_driven_signals(...)`,
  - deleted `track_ast_intermediate_signals(...)`,
  - deleted `is_intermediate_signal(...)`,
  - deleted `is_signal_ast_based_intermediate(...)`,
  - deleted `_ast_contains_factorizable_operators(...)`,
  - deleted `_signal_name_indicates_ast_operators(...)`,
  - deleted `ast_to_systemverilog(...)`,
  - deleted `_ast_to_systemverilog_internal(...)`,
  - deleted `_render_binary_op(...)`,
  - deleted `_render_unary_op(...)`,
  - deleted `_choose_operator_symbol(...)`,
  - deleted `_operand_is_single_bit(...)`,
  - deleted `_signal_is_single_bit(...)`,
  - deleted `_get_operator_precedence(...)`,
  - deleted `_needs_parentheses(...)`,
  - deleted `_map_binary_operator(...)`,
  - deleted `_map_unary_operator(...)`,
  - deleted `_operand_needs_parens_for_negation(...)`,
  - deleted `get_intermediate_signal_expression(...)`.
- Extended `t/10-ast-first-enable-structure.t` to assert that live generation no longer exposes those utility/rendering helper names on the `FlattenedDT` facade.
- Root cause / rationale:
  - repo-wide call-graph auditing showed these names had no remaining facade callers anywhere in the active code or tests,
  - the matching methods remain live in `EnableGraph`, so the `FlattenedDT` delegates had become dead compatibility surface rather than a real ownership seam,
  - `get_signal_assignment_type(...)` was intentionally kept because `t/03-assignment-intent-metadata.t` still exercises it as part of the tested `FlattenedDT` surface.
- Scope remains behavior-preserving cleanup of dead compatibility surface; live `EnableGraph` utility/rendering behavior is unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t/03-assignment-intent-metadata.t` (pass: `Files=1`, `Tests=62`)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=116`)
  - `prove -I perl t` (pass: `Files=10`, `Tests=262`)
### FlattenedDT cleanup (retire dead orchestrator/backend facade pocket)
- Removed the dead orchestrator/backend helper delegate pocket from `perl/FSM/HDL/FlattenedDT.pm`:
  - deleted `flatten_all_decision_trees(...)`,
  - deleted `extract_lhs_name_from_ast(...)`,
  - deleted `flatten_decision_tree(...)`,
  - deleted `generate_header(...)`,
  - deleted `generate_module_declaration(...)`,
  - deleted `generate_state_encoding(...)`,
  - deleted `generate_state_register(...)`,
  - deleted `generate_enable_conditions(...)`,
  - deleted `generate_consolidated_intermediate_signals(...)`,
  - deleted `generate_wen_en_signals(...)`,
  - deleted `record_assignment_from_ast(...)`,
  - deleted `record_transition_from_ast(...)`,
  - deleted `extract_rhs_from_expression(...)`.
- Extended `t/10-ast-first-enable-structure.t` to assert that live generation no longer exposes those orchestrator/backend-owned helper names on the `FlattenedDT` facade.
- Root cause / rationale:
  - repo-wide call-graph auditing showed these names had no remaining facade callers anywhere in the active code or tests,
  - the matching methods remain live and are now reached directly from `Orchestrator` or `backend_sv`,
  - removing the dead delegates is safer than preserving an uncalled flattening/emission compatibility surface on the facade.
- Scope remains behavior-preserving cleanup of dead compatibility surface; live orchestrator/backend behavior is unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=90`)
  - `prove -I perl t` (pass: `Files=10`, `Tests=236`)
### FlattenedDT cleanup (retire dead EnableGraph facade delegates)
- Removed the dead `EnableGraph`-owned helper delegate pocket from `perl/FSM/HDL/FlattenedDT.pm`:
  - deleted `normalize_rhs_logic_level(...)`,
  - deleted `get_reset_value(...)`,
  - deleted `get_fsm_reset_state(...)`,
  - deleted `get_explicit_reset_value(...)`,
  - deleted `set_fsm_module_reference(...)`,
  - deleted `get_default_value_from_ast(...)`,
  - deleted `get_reset_value_from_ast(...)`,
  - deleted `get_default_value(...)`,
  - deleted `convert_condition_to_ast(...)`,
  - deleted `convert_test_value_to_ast(...)`.
- Extended `t/10-ast-first-enable-structure.t` to assert that live generation no longer exposes those `EnableGraph`-owned helper names on the `FlattenedDT` facade.
- Root cause / rationale:
  - repo-wide call-graph auditing showed these names had no remaining facade callers anywhere in the active code or tests,
  - the matching `EnableGraph` methods remain live and are now reached directly from `EnableGraph` itself or from `Orchestrator`,
  - removing the dead delegates is safer than preserving an uncalled setup/reset/default/AST-conversion compatibility surface on the facade.
- Scope remains behavior-preserving cleanup of dead compatibility surface; live `EnableGraph` behavior is unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=77`)
  - `prove -I perl t` (pass: `Files=10`, `Tests=223`)
### FlattenedDT cleanup (retire dead logical-op facade delegates)
- Removed the dead logical-operation helper delegate pocket from `perl/FSM/HDL/FlattenedDT.pm`:
  - deleted `run_global_ast_factorization(...)`,
  - deleted `collect_all_wen_en_ast_expressions(...)`,
  - deleted `count_binary_logical_operation_occurrences(...)`,
  - deleted `_count_logical_ops_in_ast(...)`,
  - deleted `_is_factorizable_sub_expression(...)`.
- Extended `t/10-ast-first-enable-structure.t` to assert that live generation no longer exposes those backend-internal logical-op helper names on the `FlattenedDT` facade.
- Root cause / rationale:
  - repo-wide call-graph auditing showed these names had no remaining facade callers anywhere in the active code or tests,
  - the matching backend methods remain live and still serve the backend/orchestrator path, so the `FlattenedDT` delegates no longer described a real ownership boundary,
  - removing the dead delegates is safer than preserving an uncalled logical-op compatibility surface on the facade.
- Scope remains behavior-preserving cleanup of dead compatibility surface; live backend logical-op counting/factorization behavior is unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=67`)
  - `prove -I perl t` (pass: `Files=10`, `Tests=213`)
### FlattenedDT cleanup (retire dead filtering facade delegates)
- Removed the dead filtering helper delegate pocket from `perl/FSM/HDL/FlattenedDT.pm`:
  - deleted `should_filter_consolidated_signal(...)`,
  - deleted `should_filter_ast_based(...)`,
  - deleted `is_simple_negation(...)`,
  - deleted `is_simple_comparison(...)`,
  - deleted `is_signal_actually_used_in_final_expressions(...)`.
- Extended `t/10-ast-first-enable-structure.t` to assert that live generation no longer exposes those backend-internal filtering helper names on the `FlattenedDT` facade.
- Root cause / rationale:
  - repo-wide call-graph auditing showed these names had no remaining facade callers anywhere in the active code or tests,
  - the matching backend methods are still live but now serve only as backend-internal helpers, so the `FlattenedDT` delegates no longer represented a real ownership boundary,
  - removing the dead delegates is safer than preserving an uncalled compatibility surface on the facade.
- Scope remains behavior-preserving cleanup of dead compatibility surface; live backend filtering behavior is unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=62`)
  - `prove -I perl t` (pass: `Files=10`, `Tests=208`)
### FlattenedDT/backend cleanup (retire dead mux/simple helper pocket)
- Removed the dead mux/simple helper pocket from `perl/FSM/HDL/FlattenedDT.pm` and `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`:
  - deleted the `FlattenedDT` facade delegates `is_simple_ast_expression(...)`, `generate_comb_mux(...)`, and `generate_flop_mux(...)`,
  - deleted the matching backend implementations `is_simple_ast_expression(...)`, `generate_comb_mux(...)`, and `generate_flop_mux(...)`.
- Extended `t/10-ast-first-enable-structure.t` to assert that live generation no longer exposes those dead helper names on either the `FlattenedDT` facade or the backend `SystemVerilog` helper object.
- Root cause / rationale:
  - repo-wide call-graph auditing showed those three helpers had no remaining callers anywhere in the active code or tests,
  - the mux helpers still depended on the long-retired `lhs_to_enable_value_pairs` state, which confirmed they were dead compatibility residue rather than inactive live code,
  - removing both sides together is safer than preserving an uncalled alternate mux/simple-expression surface in the facade or backend.
- Scope remains behavior-preserving cleanup of dead compatibility surface; live AST/CoreAST generation, mux emission, and backend lowering behavior are unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=57`)
  - `prove -I perl t` (pass: `Files=10`, `Tests=203`)
### FlattenedDT/EnableGraph cleanup (retire dead AST helper pocket)
- Removed the dead AST helper pocket from `perl/FSM/HDL/FlattenedDT.pm` and `perl/FSM/Synthesis/EnableGraph.pm`:
  - deleted the `FlattenedDT` facade delegates `get_or_create_ast_signal_name(...)`, `canonicalize_expression(...)`, `is_complex_ast(...)`, `should_factor_ast(...)`, `analyze_ast_complexity(...)`, and `_traverse_ast_for_complexity(...)`,
  - deleted the matching `EnableGraph` owner methods `get_or_create_ast_signal_name(...)`, `canonicalize_expression(...)`, `is_complex_ast(...)`, `should_factor_ast(...)`, `analyze_ast_complexity(...)`, and `_traverse_ast_for_complexity(...)`.
- Extended `t/10-ast-first-enable-structure.t` to assert that live generation no longer exposes those dead helper names on either the `FlattenedDT` facade or the `EnableGraph` helper object.
- Root cause / rationale:
  - repo-wide call-graph auditing showed this entire AST helper pocket had no remaining callers anywhere in the active code or tests,
  - `is_complex_ast(...)` and `_traverse_ast_for_complexity(...)` were only still used by the other already-dead methods in that same pocket, so the slice removes the owner-local chain instead of leaving half of it behind,
  - removing both the owner methods and their matching facade delegates together is safer than preserving an uncalled alternate AST analysis/naming surface.
- Scope remains behavior-preserving cleanup of dead compatibility surface; live AST/CoreAST generation, intermediate naming, factorization, and backend emission behavior are unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=51`)
  - `prove -I perl t` (pass: `Files=10`, `Tests=197`)
### FlattenedDT/backend cleanup (retire dead sub-expression analysis helpers)
- Removed the dead sub-expression analysis pocket from `perl/FSM/HDL/FlattenedDT.pm` and `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`:
  - deleted the `FlattenedDT` facade delegates `analyze_ast_sub_expressions(...)` and `find_all_ast_sub_expressions(...)`,
  - deleted the matching backend implementations `analyze_ast_sub_expressions(...)` and `find_all_ast_sub_expressions(...)`.
- Extended `t/10-ast-first-enable-structure.t` to assert that live generation no longer exposes those dead helper names on either the `FlattenedDT` facade or the backend `SystemVerilog` helper object.
- Root cause / rationale:
  - repo-wide call-graph auditing showed `analyze_ast_sub_expressions(...)` had no remaining callers anywhere in the active code or tests,
  - `find_all_ast_sub_expressions(...)` only existed to support that already-dead analysis entrypoint, so the pair formed a self-contained dead helper island,
  - removing both sides together is safer than preserving an uncalled alternate analysis surface in either the facade or backend.
- Scope remains behavior-preserving cleanup of dead compatibility surface; live AST/CoreAST generation, logical-operation counting, and backend emission behavior are unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=185`)
  - `prove -I perl t` (pass: `Files=10`, `Tests=185`)
### EnableGraph cleanup (retire dead owner-only helper pocket)
- Removed the dead owner-only helper pocket from `perl/FSM/Synthesis/EnableGraph.pm`:
  - deleted `get_or_create_global_expression(...)`,
  - deleted `should_factor_condition(...)`,
  - deleted `needs_parentheses(...)`,
  - deleted `signal_uses_register_assignment(...)`.
- Extended `t/10-ast-first-enable-structure.t` to assert that live generation no longer exposes those dead helper names on the `EnableGraph` helper object.
- Root cause / rationale:
  - repo-wide call-graph auditing showed these four helpers had no remaining callers anywhere in the active code or tests,
  - they no longer participated in a live compatibility boundary because the matching facade delegates were already gone or the behavior had already localized elsewhere,
  - removing the owner-only pocket is safer than preserving unused helper implementations that could be mistaken for active supported entrypoints.
- Scope remains behavior-preserving cleanup of dead compatibility residue; live AST/CoreAST generation, enable synthesis, and backend emission behavior are unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=35`)
  - `prove -I perl t` (pass: `Files=10`, `Tests=181`)
### FlattenedDT cleanup (retire dead orphan helper pocket)
- Removed the dead helper pocket shared between `perl/FSM/HDL/FlattenedDT.pm` and `perl/FSM/Synthesis/EnableGraph.pm`:
  - deleted `create_condition_expression_signal_name(...)`,
  - deleted `set_explicit_reset_values(...)`,
  - deleted `parentheses_are_redundant(...)`,
  - deleted `generate_expression_from_signal_name(...)`.
- Extended `t/10-ast-first-enable-structure.t` to assert that live generation no longer exposes those dead helper names on either the `FlattenedDT` facade or the `EnableGraph` helper object.
- Root cause / rationale:
  - repo-wide call-graph auditing showed these four helpers had no remaining callers anywhere in the active code or tests,
  - each helper already represented dead compatibility or dead legacy fallback surface rather than a live ownership boundary,
  - removing the owner methods and their matching facade delegates together is safer than leaving uncalled helper definitions lingering on one side of the boundary.
- Scope remains behavior-preserving cleanup of dead compatibility surface; live AST/CoreAST generation, enable synthesis, and backend emission behavior are unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=31`)
  - `prove -I perl t` (pass: `Files=10`, `Tests=177`)
### FlattenedDT cleanup (retire dead unified helper delegates)
- Removed the dead unified-analysis / unified-emission helper delegate pocket from `perl/FSM/HDL/FlattenedDT.pm`:
  - deleted `build_unified_assignment_analysis(...)`,
  - deleted `group_assignments_by_rhs(...)`,
  - deleted `generate_complete_enable_structure(...)`,
  - deleted `build_multiplexer_config(...)`,
  - deleted `generate_unified_wen_en_signals(...)`,
  - deleted `generate_dt_enables_from_analysis(...)`,
  - deleted `generate_lhs_enables_from_analysis(...)`,
  - deleted `generate_signal_assignments(...)`,
  - deleted `generate_unified_flop_mux(...)`,
  - deleted `generate_unified_pulse_delay_logic(...)`,
  - deleted `signal_uses_register_assignment(...)`,
  - deleted `generate_unified_comb_mux(...)`.
- Extended `t/10-ast-first-enable-structure.t` to assert that live generation no longer exposes that dead unified helper surface on the `FlattenedDT` facade.
- Root cause / rationale:
  - repo-wide call-graph auditing showed the live phase-1/2/3 flow now runs directly through `Orchestrator -> EnableGraph` and no longer routes through the matching facade delegates,
  - the removed methods were pure compatibility wrappers around helper ownership that had already localized in `EnableGraph`,
  - removing the whole delegate cluster is safer than preserving an untested alternate entry surface for unified analysis and mux/WEN generation.
- Scope remains behavior-preserving cleanup of dead compatibility surface; live assignment analysis, enable generation, and mux emission behavior are unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=23`)
  - `prove -I perl t` (pass: `Files=10`, `Tests=169`)
### FlattenedDT cleanup (retire dead signal-AST facade helper)
- Removed the dead `get_signal_ast_node(...)` helper from `perl/FSM/HDL/FlattenedDT.pm`.
- Removed the now-unused `FSM::GlobalASTManager`, `FSM::AST::Node`, and `FSM::CoreAST` imports from `perl/FSM/HDL/FlattenedDT.pm`.
- Extended `t/10-ast-first-enable-structure.t` to assert that live generation no longer exposes the dead `get_signal_ast_node(...)` facade helper.
- Root cause / rationale:
  - repo-wide call-graph auditing showed `get_signal_ast_node(...)` had no remaining callers anywhere in the active code or tests,
  - the helper depended on a stale `fsm_module` slot that is not populated on the live AST/CoreAST-first path,
  - removing the helper and its last facade-only imports is safer than preserving an untested alternate signal-lookup surface on `FlattenedDT`.
- Scope remains behavior-preserving cleanup of dead compatibility surface; live signal lookup, enable synthesis, and backend emission behavior are unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=11`)
  - `prove -I perl t` (pass: `Files=10`, `Tests=157`)
### FlattenedDT cleanup (retire dead substituted-AST matching helpers)
- Removed the dead substituted-AST matching helper pocket from `perl/FSM/HDL/FlattenedDT.pm`:
  - deleted `signal_name_matches_operation(...)`,
  - deleted `find_substituted_ast(...)`,
  - deleted `ast_contains_intermediate_signal_references(...)`,
  - deleted `expressions_are_equivalent(...)`,
  - deleted `extract_expression_structure(...)`,
  - deleted `ast_structures_match(...)`.
- Removed the now-unused `Data::Dumper`, `Scalar::Util qw(blessed)`, and `List::Util qw(min max)` imports from `perl/FSM/HDL/FlattenedDT.pm`.
- Root cause / rationale:
  - repo-wide auditing showed that this entire substituted-AST matching pocket had become dead compatibility surface with no remaining code callers,
  - the live substitution/factorization flow already uses backend-owned helpers such as `update_original_asts_with_substituted_versions(...)`, `get_substituted_ast_for_signal(...)`, and `is_signal_referenced_in_substitutions(...)`,
  - removing the dead pocket is safer than preserving dormant AST/string matching heuristics in the `FlattenedDT` facade.
- Scope remains behavior-preserving cleanup of dead compatibility helpers; no live backend emission or factorization path changed.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=10`, `Tests=156`)
### FlattenedDT cleanup (retire dead standalone declaration helpers)
- Removed the dead standalone intermediate-declaration helper lane from `perl/FSM/HDL/FlattenedDT.pm`:
  - deleted `schedule_intermediate_signal_for_declaration(...)`,
  - deleted the compatibility-only `generate_intermediate_signal_declarations(...)` delegate,
  - deleted the adjacent unreferenced combinational-wire helper `get_combinational_lhs_signals(...)`.
- Removed the backend-side `generate_intermediate_signal_declarations(...)` implementation from `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`; the live declaration path already goes through consolidated intermediate emission plus `generate_internal_signal_declarations(...)`.
- Extended `t/10-ast-first-enable-structure.t` to assert that live generation leaves no legacy `intermediate_signals_to_declare` scratch state behind.
- Root cause / rationale:
  - repo-wide auditing showed the standalone declaration lane had become pure dead compatibility surface after consolidated intermediate emission became the authoritative runtime declaration path,
  - neither the `FlattenedDT` wrappers nor the backend helper had any remaining callsites, and the only scratch state they used was similarly unreferenced,
  - removing the whole lane is safer than leaving an alternate declaration path available for accidental reuse.
- Scope remains behavior-preserving cleanup of dead compatibility state; live intermediate declaration and emission behavior is unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=10`)
  - `prove -I perl t` (pass: `Files=10`, `Tests=156`)
### FlattenedDT cleanup (retire dead LHS/RHS completeness tracking)
- Removed the dormant LHS/RHS completeness-tracking family from `perl/FSM/HDL/FlattenedDT.pm`:
  - deleted the legacy `expected_lhs_rhs`, `actual_lhs_rhs`, and `missing_lhs_rhs` state hashes from object construction,
  - deleted the raw-AST validation helpers `track_expected_lhs_rhs(...)`, `validate_lhs_rhs_completeness(...)`, `extract_lhs_rhs_from_raw_ast(...)`, `_traverse_raw_ast_for_lhs_rhs(...)`, and `_format_raw_rhs(...)`,
  - removed the no-longer-needed `track_actual_lhs_rhs(...)` compatibility delegate from `FlattenedDT`.
- Removed the remaining writes into that dead lane from `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` so live assignment/transition capture no longer records unused `actual_lhs_rhs` entries.
- Extended `t/10-ast-first-enable-structure.t` to assert that live generation leaves no legacy LHS/RHS tracking state behind (`expected_lhs_rhs`, `actual_lhs_rhs`, `missing_lhs_rhs`).
- Root cause / rationale:
  - repo-wide auditing showed the LHS/RHS completeness family had become pure dead compatibility/debug surface after the AST-first assignment/transition capture move,
  - the only live writes into the family came from `Orchestrator`, and no active runtime/backend path read that state or invoked the validation helpers,
  - deleting the dead lane is safer than preserving unused instrumentation because it shrinks the `FlattenedDT` facade and reduces the chance of reviving parallel non-semantic bookkeeping.
- Scope remains behavior-preserving cleanup of dead compatibility state; the live AST/CoreAST assignment capture and enable-synthesis path is unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `prove -I perl t/10-ast-first-enable-structure.t` (pass: `Files=1`, `Tests=9`)
  - `prove -I perl t` (pass: `Files=10`, `Tests=155`)
## 2026-03-11
### EnableGraph/SystemVerilog defining-AST metadata for consolidated filtering
- Updated `perl/FSM/Synthesis/EnableGraph.pm` so `track_ast_intermediate_signals()` now records `reference_ast` separately and attaches a native `defining_ast` for referenced intermediate signals when one is already available from AST-backed sources.
- Added `resolve_intermediate_signal_defining_ast()` to `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` and updated the consolidated filtering/runtime path to use it before reparsing expressions.
- Updated the live backend flow so:
  - `should_filter_consolidated_signal()` prefers a resolved defining AST on the primary path,
  - prescan-referenced intermediate entries are merged into consolidated generation with cached defining-AST metadata,
  - consolidated dependency-map construction resolves defining ASTs before falling back to expression-only compatibility handling.
- Root cause / rationale:
  - after the AST-first dependency-extraction slice, the remaining live weakness on the same path was that expression-only entries could still force reparsing even when native defining ASTs were already derivable,
  - the next truthful cut was therefore to carry defining-AST metadata forward and centralize AST resolution on the consolidated filtering path rather than introducing another localized parse fallback.
- Scope remains behavior-preserving AST/CoreAST-first convergence on the live consolidated intermediate filtering path; no public backend entrypoint or emitter API changed in this slice.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### EnableGraph/SystemVerilog AST-first intermediate dependency extraction
- Added `extract_intermediate_signals_from_ast()` and `_collect_intermediate_signals_from_ast()` to `perl/FSM/Synthesis/EnableGraph.pm` so the live code can recover referenced intermediate signals by traversing AST nodes instead of scanning rendered SystemVerilog text.
- Updated `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` so:
  - consolidated intermediate-signal dependency-map construction now uses AST traversal whenever a defining AST is available,
  - factorization substitution tracing now extracts referenced intermediate signals directly from substituted ASTs,
  - pre-scan referenced signals are seeded with their defining AST from `get_intermediate_signal_ast()` when available.
- Updated `extract_intermediate_signals_from_expression()` to attempt expression parsing and delegate to AST traversal before falling back to legacy string scanning only when parsing fails.
- Root cause / rationale:
  - a fresh re-scan showed that `get_or_create_global_expression()` was not the strongest live runtime seam after the previous slice,
  - the real active string dependency was in consolidated intermediate-signal dependency extraction, which still identified referenced intermediates by regex over rendered expressions even when ASTs were already present,
  - this slice converts that live dependency-discovery path to AST-first behavior and narrows string scanning to compatibility fallback only.
- Scope remains behavior-preserving AST/CoreAST-first convergence on the live dependency/filtering path; no public backend entrypoint or emitter API changed in this slice.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### EnableGraph AST-backed intermediate-signal registry metadata
- Reworked `perl/FSM/Synthesis/EnableGraph.pm` so the live intermediate-signal registry can store structured entries with `ast`, `expression`, `name`, and `source` metadata instead of only bare expression strings when native ASTs are available.
- Updated `get_or_create_ast_signal_name()` and `get_or_create_global_expression()` to register that structured metadata on intermediate-signal creation/reuse, preserving the canonical expression string only as compatibility data rather than the primary semantic owner.
- Updated `is_signal_ast_based_intermediate()` and `get_intermediate_signal_ast()` so the live detection/lookup path now prefers AST factorizer data, AST-backed intermediate-registry entries, and FSM-module `driving_ast` metadata before any narrow compatibility parsing fallback.
- Updated `get_intermediate_signal_expression()` so intermediate-signal rendering now uses the defining AST when available and otherwise returns stored registry/global-expression text; the previous signal-name reconstruction fallback is no longer part of the live render path.
- Updated `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` so `count_binary_logical_operation_occurrences()` resolves native intermediate-signal ASTs through `EnableGraph` instead of reparsing `ctx->{intermediate_signals}` string payloads.
- Removed the leftover duplicate compatibility-parse line in `get_intermediate_signal_ast()` that was still triggering a Perl redeclaration warning after the registry conversion.
- Root cause / rationale:
  - the live intermediate-signal path still treated registry meaning as strings even when the surrounding pipeline already had defining ASTs,
  - that kept counting, lookup, and render decisions dependent on reparsing or reconstructing expressions instead of carrying AST/CoreAST-native ownership forward,
  - this slice converts the primary ownership path to AST-backed metadata while preserving narrow compatibility parsing only for legacy entries that still lack a stored defining AST.
- Scope remains behavior-preserving AST-first convergence on the live registry/count/render path; no public backend entrypoint or emitter API changed in this slice.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### EnableGraph AST-first logical-operation factor detection
- Reworked `contains_frequently_used_operations()` in `perl/FSM/Synthesis/EnableGraph.pm` so the live logical-operation factoring decision now recursively inspects AST nodes and resolved intermediate-signal ASTs instead of scanning rendered expressions and generated signal strings.
- Added `get_intermediate_signal_ast()` and `_parse_intermediate_expression_to_ast()` so existing registries can provide native ASTs first and only use expression parsing as a narrow compatibility fallback when no defining AST is stored yet.
- Updated `get_intermediate_signal_expression()` to render from the defining AST when one is available.
- Root cause / rationale:
  - the factorization decision path was still using a live string-based algorithm inside `EnableGraph`, even though the surrounding flow already had ASTs,
  - this made the next truthful AST/CoreAST-first slice a decision-path rewrite rather than more helper relocation from `FlattenedDT`,
  - the new implementation makes the reuse check AST-first while preserving behavior through narrow compatibility fallback where the registries still expose expression strings.
- Scope remains behavior-preserving decision-path convergence; no public backend entrypoint or output-stage API changed in this slice.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph redundant-parentheses helper ownership)
- Moved `parentheses_are_redundant()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to the new `enable_graph` helper implementation.
- Root cause / rationale:
  - after the prior `clean_intermediate_expression()` slice, no stronger still-live seam emerged in the same local parenthesis/sanitation pocket,
  - `parentheses_are_redundant()` was the smallest remaining helper in that in-flight lane, so moving it finished the slice cleanly without widening scope,
  - the user has now explicitly directed future convergence toward AST/CoreAST-native algorithms, so this closes the current string-helper cleanup lane rather than setting the default pattern for subsequent work.
- Scope remains behavior-preserving helper convergence only; no public backend entrypoint or live HDL emission call path changed in this slice.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph expression sanitation helper ownership)
- Moved `clean_intermediate_expression()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to the new `enable_graph` helper implementation.
- Root cause / rationale:
  - after re-scanning the nearby formatting and substitution pockets, no stronger still-live seam emerged than the already-moved `needs_parentheses()` helper,
  - `clean_intermediate_expression()` remained the smallest self-contained helper in the same string-expression sanitation lane, so moving it reduced facade ownership without overstating the amount of remaining live boundary there.
- Scope remains behavior-preserving helper convergence only; no public backend entrypoint or live HDL emission call path changed in this slice.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph string parenthesis helper ownership)
- Moved `needs_parentheses()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to the new `enable_graph` helper implementation.
- Root cause / rationale:
  - after the AST factorization-analysis pair moved, `needs_parentheses()` was the smallest remaining nearby helper with a clear live use on the DT-specific enable-generation path,
  - moving just this helper reduced facade ownership without pulling in the broader and less clearly justified legacy string-formatting pocket.
- Scope remains behavior-preserving helper convergence only; no public backend entrypoint or live HDL emission call path changed in this slice.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph AST factorization-analysis helper ownership)
- Moved `is_complex_ast()` and `should_factor_ast()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to the new `enable_graph` helper implementations.
- Root cause / rationale:
  - `EnableGraph::should_factor_condition()` already pointed at `should_factor_ast()` as the preferred AST-native path, but the actual AST factorization-analysis pair still lived in the `FlattenedDT` facade,
  - moving the pair into `EnableGraph` keeps the AST-native factorization decision logic with the adjacent condition-factorization helpers already localized there.
- Scope remains behavior-preserving helper convergence only; no public backend entrypoint or live HDL emission call path changed in this slice.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph legacy condition-factorization helper ownership)
- Moved `should_factor_condition()`, `analyze_ast_complexity()`, and `_traverse_ast_for_complexity()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to the new `enable_graph` helper implementations.
- Root cause / rationale:
  - these legacy condition-factorization helpers remained in the `FlattenedDT` facade immediately next to the registry/naming helpers already moved,
  - they analyze the same enable-expression space and fit `EnableGraph` more naturally than the compatibility shell.
- Scope remains behavior-preserving helper convergence only; no public backend entrypoint or live HDL emission call path changed in this slice.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
## 2026-03-10
### FlattenedDT backend convergence (EnableGraph global-expression registry helper ownership)
- Moved `get_or_create_global_expression()` and `canonicalize_expression()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to the new `enable_graph` helper implementations.
- Root cause / rationale:
  - these helpers still owned shared global-expression registry behavior in the `FlattenedDT` facade immediately next to the AST naming helpers already moved,
  - the underlying state they mutate (`global_expressions`, `expression_usage`, and `intermediate_signals`) already lives on the shared synthesis context that `EnableGraph` manages.
- Scope remains behavior-preserving helper convergence only; no public backend entrypoint or live HDL emission call path changed in this slice.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph AST signal-naming helper ownership)
- Moved `create_condition_expression_signal_name()`, `get_or_create_ast_signal_name()`, `generate_ast_based_signal_name()`, and `map_operator_to_name()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to the new `enable_graph` helper implementations.
- Root cause / rationale:
  - this AST signal-naming cluster still mutated `global_expressions`, `expression_usage`, and `intermediate_signals` from the `FlattenedDT` facade,
  - those registries already sit on the shared synthesis context used by `EnableGraph`, so ownership there is more coherent than leaving the helper pocket in the facade.
- Scope remains behavior-preserving helper convergence only; no public backend entrypoint or live HDL emission call path changed in this slice.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Verilog backend SystemVerilog-entry callsite convergence)
- Localized the live `generate_systemverilog()` call in `perl/FSM/HDL/FlattenedDT/Backend/Verilog.pm` from the `FlattenedDT` facade to direct `orchestrator` ownership.
- Updated `Backend::Verilog::generate_verilog()` so SystemVerilog generation now goes through `$ctx->{orchestrator}->generate_systemverilog(...)`.
- Scope remains behavior-preserving callsite convergence only; no helper ownership or delegate structure changed in `perl/FSM/HDL/FlattenedDT.pm`.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/Verilog.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Fixpoint second-pass update callsite convergence)
- Localized the live `update_original_asts_with_second_pass_substitutions()` call in `perl/FSM/HDL/Factorization/Fixpoint.pm` from the `FlattenedDT` facade to direct `backend_sv` ownership.
- Updated `run_post_substitution_factorization()` so second-pass AST updates now go through `$ctx->{backend_sv}->update_original_asts_with_second_pass_substitutions(...)`.
- Scope remains behavior-preserving callsite convergence only; no helper ownership or delegate structure changed in `perl/FSM/HDL/FlattenedDT.pm`.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/Factorization/Fixpoint.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Fixpoint second-pass feed callsite convergence)
- Localized the live `feed_current_asts_to_second_pass()` call in `perl/FSM/HDL/Factorization/Fixpoint.pm` from the `FlattenedDT` facade to direct `backend_sv` ownership.
- Updated `run_post_substitution_factorization()` so second-pass AST feeding now goes through `$ctx->{backend_sv}->feed_current_asts_to_second_pass(...)`.
- Scope remains behavior-preserving callsite convergence only; no helper ownership or delegate structure changed in `perl/FSM/HDL/FlattenedDT.pm`.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/Factorization/Fixpoint.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (SystemVerilog prescan intermediate-tracking callsite convergence)
- Localized the two live `track_ast_intermediate_signals()` callsites in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from the `FlattenedDT` facade to direct `EnableGraph` ownership.
- Updated DT-specific and LHS-level pre-scan tracking inside `prescan_wen_en_for_intermediate_signals()` to use `$ctx->{enable_graph}->track_ast_intermediate_signals(...)`.
- Scope remains behavior-preserving callsite convergence only; no helper ownership or delegate structure changed in `perl/FSM/HDL/FlattenedDT.pm`.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Factorization Fixpoint AST-to-SV callsite convergence)
- Localized the remaining non-local `ast_to_systemverilog()` callsites in `perl/FSM/HDL/Factorization/Fixpoint.pm` from the `FlattenedDT` facade to direct `EnableGraph` entry ownership.
- Updated pass-level debug rendering of new second-pass intermediate signals and `_build_expression_signature()` to use `$ctx->{enable_graph}->ast_to_systemverilog(...)`.
- Scope remains behavior-preserving callsite convergence only; no helper ownership or delegate structure changed in `perl/FSM/HDL/FlattenedDT.pm`.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/Factorization/Fixpoint.pm` (pass)
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
## 2026-03-08
### CI workflow unification for local pre-push execution
- Added a shared repo-owned CI entrypoint, `bin/ci-regression`, and updated `.github/workflows/regression.yml` to call it instead of inlining `prove -v t/01-regression.t`.
- The shared CI script now:
  - resolves the repository root automatically,
  - runs the full Perl regression suite with `prove -I perl t`.
- Removed the discarded Rust-specific `bin/check-rust-include-paths` guard after confirming the active CI path is Perl-only.
- Added `README.md` documentation for the local pre-push CI command.
- Validation:
  - `bash -lc 'cd /tmp && /Users/richarddje/Documents/github/fsmgen/bin/ci-regression'` (pass)
  - full regression passed (`Files=6`, `Tests=125`)
  - audited tracked `.github`, `bin`, `perl`, `t`, `README.md`, and `docs` content and found no active references to untracked `fx/`, `plugin/`, `specs/`, or machine-specific `/Users/...` paths
## 2026-03-09
### FlattenedDT backend convergence (EnableGraph binary operator-selection helper ownership)
- Moved `_choose_operator_symbol()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `enable_graph->_choose_operator_symbol(...)`.
- Added the matching `List::Util::min` import in `EnableGraph.pm` so the copied helper keeps its existing debug-path behavior intact.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph binary operand-width helper ownership)
- Moved `_operand_is_single_bit()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `enable_graph->_operand_is_single_bit(...)`.
- Scope remains behavior-preserving helper convergence only; binary rendering stays unchanged and `_choose_operator_symbol()` is now the remaining binary-support helper on the operator-selection path.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph binary signal-width helper ownership)
- Moved `_signal_is_single_bit()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `enable_graph->_signal_is_single_bit(...)`.
- Retargeted FSM-module metadata access inside the moved helper through `EnableGraph`'s existing `flattened_dt` context so behavior stays unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph binary operator-mapping helper ownership)
- Moved `_map_binary_operator()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `enable_graph->_map_binary_operator(...)`.
- Scope remains behavior-preserving helper convergence only; binary rendering stays unchanged and the remaining binary-support helpers are now concentrated in the bit-width/operator-selection path.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph binary precedence helper ownership)
- Moved `_get_operator_precedence()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `enable_graph->_get_operator_precedence(...)`.
- Scope remains behavior-preserving helper convergence only; binary rendering stays unchanged and `_choose_operator_symbol()` / `_operand_is_single_bit()` are the remaining binary-support delegates.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph binary parenthesis-decision helper ownership)
- Moved `_needs_parentheses()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `enable_graph->_needs_parentheses(...)`.
- Scope remains behavior-preserving helper convergence only; binary rendering stays unchanged and `_get_operator_precedence()` is now the smallest remaining isolated binary-support delegate.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph binary AST-to-SV render helper ownership)
- Moved `_render_binary_op()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `enable_graph->_render_binary_op(...)`.
- Added narrow `EnableGraph` compatibility delegates for `_get_operator_precedence()`, `_choose_operator_symbol()`, `_needs_parentheses()`, and `_operand_is_single_bit()` so binary rendering stays behavior-preserving while the deeper binary-support helper cluster remains in `FlattenedDT`.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph unary negation parenthesization helper ownership)
- Moved `_operand_needs_parens_for_negation()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `enable_graph->_operand_needs_parens_for_negation(...)`.
- Scope remains behavior-preserving helper convergence only; unary rendering stays unchanged and the unary-support helper lane is now exhausted.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph unary operator mapping helper ownership)
- Moved `_map_unary_operator()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `enable_graph->_map_unary_operator(...)`.
- Scope remains behavior-preserving helper convergence only; unary rendering stays unchanged and `_operand_needs_parens_for_negation()` remains as the last isolated unary-support delegate.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph unary AST-to-SV render helper ownership)
- Moved `_render_unary_op()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `enable_graph->_render_unary_op(...)`.
- Added narrow `EnableGraph` compatibility delegates for `_map_unary_operator()` and `_operand_needs_parens_for_negation()` so unary rendering stays behavior-preserving while those smaller support helpers remain in `FlattenedDT`.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph AST-to-SV internal helper ownership)
- Moved `_ast_to_systemverilog_internal()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `enable_graph->_ast_to_systemverilog_internal(...)`.
- Added temporary `EnableGraph` compatibility delegates for `_render_binary_op()` and `_render_unary_op()` so the recursive render path stays behavior-preserving while the deeper render-helper cluster remains in `FlattenedDT`.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph AST-to-SV internal delegate callsite convergence)
- Localized the `ast_to_systemverilog()` render-internal callsite in `perl/FSM/Synthesis/EnableGraph.pm` so it no longer reaches directly into the `FlattenedDT` object for `_ast_to_systemverilog_internal(...)`.
- Updated `ast_to_systemverilog()` to route through a new `EnableGraph` compatibility delegate, `$self->_ast_to_systemverilog_internal(...)`, which preserves the existing `FlattenedDT` implementation boundary for now.
- Scope remains behavior-preserving callsite convergence only; the deeper render-helper family still lives in `perl/FSM/HDL/FlattenedDT.pm`, and no operator-selection or precedence behavior changed.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph LHS-enable intermediate tracking callsite convergence)
- Localized the `track_ast_intermediate_signals()` callsite in `perl/FSM/Synthesis/EnableGraph.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` self ownership.
- Updated `generate_lhs_enables_from_analysis()` so LHS-enable intermediate-signal tracking now goes through `$self->track_ast_intermediate_signals(...)`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/Synthesis/EnableGraph.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph mux-config callsite convergence)
- Localized the phase-1 `build_multiplexer_config()` callsite in `perl/FSM/Synthesis/EnableGraph.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` self ownership.
- Updated `build_unified_assignment_analysis()` so multiplexer-config assembly now goes through `$self->build_multiplexer_config(...)`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/Synthesis/EnableGraph.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph enable-structure callsite convergence)
- Localized the phase-1 `generate_complete_enable_structure()` callsite in `perl/FSM/Synthesis/EnableGraph.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` self ownership.
- Updated `build_unified_assignment_analysis()` so enable-structure generation now goes through `$self->generate_complete_enable_structure(...)`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/Synthesis/EnableGraph.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (EnableGraph RHS-grouping callsite convergence)
- Localized the phase-1 `group_assignments_by_rhs()` callsite in `perl/FSM/Synthesis/EnableGraph.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` self ownership.
- Updated `build_unified_assignment_analysis()` so RHS grouping now goes through `$self->group_assignments_by_rhs(...)`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/Synthesis/EnableGraph.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Orchestrator signal-assignment callsite convergence)
- Localized the stage-8 `generate_signal_assignments()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` ownership.
- Updated `generate_systemverilog()` so final signal-assignment emission now goes through `$ctx->{enable_graph}->generate_signal_assignments(...)`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/Synthesis/EnableGraph.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Orchestrator WEN/EN-signal callsite convergence)
- Localized the stage-7 `generate_wen_en_signals()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Updated `generate_systemverilog()` so WEN/EN signal emission now goes through `$ctx->{backend_sv}->generate_wen_en_signals(...)`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Orchestrator consolidated-intermediate-signals callsite convergence)
- Localized the stage-6 `generate_consolidated_intermediate_signals()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Updated `generate_systemverilog()` so consolidated intermediate signal emission now goes through `$ctx->{backend_sv}->generate_consolidated_intermediate_signals(...)`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### Repository asset tracking (plugin/ and specs/ now versioned)
- Added the existing `plugin/` and `specs/` trees to version control without changing their contents.
- This records the legacy `.plg` plugin inventory and spec/reference files directly in the repository for continuity and future modernization work.
- Validation:
  - post-commit `git --no-pager status --short` leaves only `?? fx/`
### FlattenedDT backend convergence (Orchestrator WEN/EN prescan callsite convergence)
- Localized the stage-5 `prescan_wen_en_for_intermediate_signals()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Updated `generate_systemverilog()` so the post-count pre-scan step now goes through `$ctx->{backend_sv}->prescan_wen_en_for_intermediate_signals()`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Orchestrator logical-op-count callsite convergence)
- Localized the stage-4 `count_binary_logical_operation_occurrences()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Updated `generate_systemverilog()` so the pre-prescan logical-op counting step now goes through `$ctx->{backend_sv}->count_binary_logical_operation_occurrences()`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Orchestrator generate-enable-conditions callsite convergence)
- Localized the stage-3 `generate_enable_conditions()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Updated `generate_systemverilog()` so enable-condition emission now goes through `$ctx->{backend_sv}->generate_enable_conditions(...)`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Orchestrator generate-internal-signal-declarations callsite convergence)
- Localized the stage-2 `generate_internal_signal_declarations()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Updated `generate_systemverilog()` so internal signal declaration emission now goes through `$ctx->{backend_sv}->generate_internal_signal_declarations(...)`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Orchestrator generate-state-register callsite convergence)
- Localized the stage-2 `generate_state_register()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Updated `generate_systemverilog()` so state-register emission now goes through `$ctx->{backend_sv}->generate_state_register(...)`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Orchestrator generate-state-encoding callsite convergence)
- Localized the stage-2 `generate_state_encoding()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Updated `generate_systemverilog()` so state-encoding emission now goes through `$ctx->{backend_sv}->generate_state_encoding(...)`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Orchestrator generate-module-declaration callsite convergence)
- Localized the stage-2 `generate_module_declaration()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Updated `generate_systemverilog()` so module-declaration emission now goes through `$ctx->{backend_sv}->generate_module_declaration(...)`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Orchestrator generate-header callsite convergence)
- Localized the stage-2 `generate_header()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Updated `generate_systemverilog()` so initial HDL assembly now goes through `$ctx->{backend_sv}->generate_header(...)`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Orchestrator unified-assignment-analysis callsite convergence)
- Localized the unified phase-1 `build_unified_assignment_analysis()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` ownership.
- Updated `flatten_all_decision_trees()` so phase-1 analysis now goes through `$ctx->{enable_graph}->build_unified_assignment_analysis(...)`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/Synthesis/EnableGraph.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Orchestrator stage-0 FSM-module-reference callsite convergence)
- Localized the stage-0 `set_fsm_module_reference()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` ownership.
- Updated `generate_systemverilog()` so FSM-module reference storage now goes through `$ctx->{enable_graph}->set_fsm_module_reference(...)`.
- Scope remains behavior-preserving callsite convergence only; helper ownership already lived in `perl/FSM/Synthesis/EnableGraph.pm`, and the `FlattenedDT` compatibility delegate remains unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (Orchestrator condition-helper callsite convergence)
- Localized the active Orchestrator condition-helper round-trips from `FlattenedDT` facade delegates to direct `EnableGraph` ownership in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`.
- Updated the following runtime callsites:
  - `convert_condition_to_ast()` in conditional-branch traversal,
  - `convert_test_value_to_ast()` in test-node branch construction,
  - `create_condition_expression()` in assignment and transition capture.
- Scope remains behavior-preserving callsite convergence only; helper ownership was already in `perl/FSM/Synthesis/EnableGraph.pm`, and `FlattenedDT` compatibility delegates remain unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (actual LHS/RHS tracking orchestration ownership)
- Moved `track_actual_lhs_rhs()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `orchestrator->track_actual_lhs_rhs(...)`.
- Updated the orchestrator-owned assignment and transition capture paths so actual LHS/RHS validation tracking now stays local to `FlattenedDT::Orchestrator` instead of round-tripping through the façade.
- Scope remains behavior-preserving structural convergence only; the dormant expected/raw-AST completeness helpers were intentionally left in `FlattenedDT` because they are not part of the active runtime path.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### Architecture documentation (frontend parser/input-format decoupling direction)
- Added a living architecture note to `DEVELOPMENT_NOTES.md` describing how FSMGen should decouple source file format / parser concerns from the semantic core.
- Recorded the current validated boundary:
  - `FSM::Pipeline::HDLGenerator` still directly depends on `Lispish`,
  - `FSM::Adapter::FSMGenFull::*` still decodes current `.fsm` / Lispish syntax,
  - downstream analysis and backend code already operate mostly on `FSM::CoreAST`.
- Recorded the architectural rule that future frontends should lower into `FSM::CoreAST` rather than teaching synthesis/backend code multiple parser-specific raw AST shapes.
- Scope is documentation-only; no HDL-generation behavior changed.
### FlattenedDT backend convergence (assignment-capture orchestration ownership)
- Moved `extract_lhs_name_from_ast()`, `record_assignment_from_ast()`, and `extract_rhs_from_expression()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `orchestrator->extract_lhs_name_from_ast(...)`, `orchestrator->record_assignment_from_ast(...)`, and `orchestrator->extract_rhs_from_expression(...)`.
- Updated the orchestrator-owned recursive flattener so assignment handling now stays local to `FlattenedDT::Orchestrator` instead of round-tripping through the façade for LHS-name extraction, assignment capture, and RHS-expression recursion.
- Scope remains behavior-preserving structural convergence only; assignment intent handling, condition capture, LHS/RHS validation tracking, and emitted HDL semantics are unchanged.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (state-transition capture orchestration ownership)
- Moved `record_transition_from_ast()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `orchestrator->record_transition_from_ast(...)`.
- Updated the orchestrator-owned recursive flattener so state-transition handling now stays local to `FlattenedDT::Orchestrator` instead of round-tripping through the façade for this capture step.
- Scope remains behavior-preserving structural convergence only; state-transition capture still uses the existing shared condition-construction and tracking helpers and does not change emitted HDL semantics.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (recursive flattener orchestration ownership)
- Moved `flatten_decision_tree()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `orchestrator->flatten_decision_tree(...)`.
- Updated the orchestrator-owned traversal flow so recursion now stays local to `FlattenedDT::Orchestrator` instead of round-tripping through the façade for each nested decision-tree node.
- Scope remains behavior-preserving structural convergence only; the recursive flattener still delegates to the existing `FlattenedDT` AST-capture helpers and does not change emitted HDL semantics.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (flatten-all-decision-trees orchestration ownership)
- Moved `flatten_all_decision_trees()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `orchestrator->flatten_all_decision_trees(...)`.
- Updated `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` so `generate_systemverilog()` now invokes the orchestrator-owned entrypoint directly.
- Scope remains behavior-preserving structural convergence only; this localizes a live flattening step under orchestration ownership without changing downstream enable or backend behavior.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (AST condition-helper ownership)
- Moved `create_condition_expression()`, `convert_condition_to_ast()`, and `convert_test_value_to_ast()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `enable_graph` for all three helpers.
- Scope remains behavior-preserving structural convergence only; this localizes the live AST condition-construction helper trio beside the existing enable-synthesis helper layer without changing flattening callsites.
- Important implementation note:
  - an explicit `use FSM::AST::Utils;` in `EnableGraph` was intentionally not kept because it exposes an incompatible AST helper load path in this repository; the final slice preserves the existing working runtime path.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
## 2026-03-07
### FlattenedDT backend convergence (WEN/EN prescan entrypoint ownership)
- Moved `prescan_wen_en_for_intermediate_signals()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->prescan_wen_en_for_intermediate_signals()`.
- Scope remains behavior-preserving structural convergence only; this localizes the live WEN/EN intermediate-signal prescan step beside the backend-owned intermediate-signal generation flow without changing Orchestrator call order.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (AST sub-expression analysis helper ownership)
- Moved `analyze_ast_sub_expressions()`, `find_all_ast_sub_expressions()`, and `is_simple_ast_expression()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to the backend for all three helpers.
- Scope remains behavior-preserving structural convergence only; the moved trio is a cohesive AST-analysis seam from the adjacent factorization helper cluster.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (intermediate-signal generation entrypoint ownership)
- Moved `generate_intermediate_signals()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->generate_intermediate_signals(...)`.
- Scope remains behavior-preserving structural convergence only; the moved entrypoint now lives beside its backend-owned `run_global_ast_factorization()` dependency.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (logical-op-count helper-pair ownership)
- Moved `_count_logical_ops_in_ast()` and `_is_factorizable_sub_expression()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->_count_logical_ops_in_ast(...)` and `backend_sv->_is_factorizable_sub_expression(...)`.
- Updated the backend-owned logical-op-count flow to recurse through `$self->_count_logical_ops_in_ast(...)` instead of round-tripping back through `FlattenedDT`.
- Scope remains behavior-preserving structural convergence only; this completes backend-local ownership of the active logical-op-count helper family.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (logical-op-count collector ownership)
- Moved `collect_all_wen_en_ast_expressions()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->collect_all_wen_en_ast_expressions()`.
- Updated the backend-owned logical-op-count flow to collect AST expressions through `$self->collect_all_wen_en_ast_expressions()` instead of round-tripping back through `FlattenedDT`.
- Scope remains behavior-preserving structural convergence only; the remaining logical-op-count helper move is `_count_logical_ops_in_ast()` together with its coupled `_is_factorizable_sub_expression()` policy helper.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (logical-op-count entrypoint ownership)
- Moved `count_binary_logical_operation_occurrences()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->count_binary_logical_operation_occurrences()`.
- The backend-owned entrypoint still calls back into `FlattenedDT` for the currently unmoved helpers `collect_all_wen_en_ast_expressions()` and `_count_logical_ops_in_ast()`, so scope remains a small behavior-preserving ownership step rather than a full family move.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (logical-op-count wrapper callsite)
- Localized the remaining direct `run_global_ast_factorization` backend method-call round-trip in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by routing `count_binary_logical_operation_occurrences()` through a backend-local helper.
- Added backend-local helper `count_binary_logical_operation_occurrences()` and switched the factorization fallback callsite from direct `FlattenedDT` invocation to `$self->count_binary_logical_operation_occurrences()`.
- Scope remains behavior-preserving structural convergence only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (bare intermediate-signal trace render callsite)
- Localized one remaining backend render/helper round-trip in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `$ctx->ast_to_clean_systemverilog(...)` to `$ctx->{enable_graph}->ast_to_systemverilog(...)`.
- The change is in the bare `FSM::HDL::IntermediateSignalRef` trace render inside `ast_contains_intermediate_signals`, continuing direct `EnableGraph` ownership convergence inside backend code.
- Scope remains behavior-preserving structural convergence only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (factorizer substituted-AST trace render callsite)
- Localized one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `$ctx->ast_to_systemverilog(...)` to `$ctx->{enable_graph}->ast_to_systemverilog(...)`.
- The change is in the factorizer substituted-AST trace render inside `get_substituted_ast_for_signal`, continuing direct `EnableGraph` ownership convergence inside backend code.
- Scope remains behavior-preserving structural convergence only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (assignment-condition second-pass substituted-AST debug render callsite)
- Localized one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `$ctx->ast_to_systemverilog(...)` to `$ctx->{enable_graph}->ast_to_systemverilog(...)`.
- The change is in the assignment-condition substituted-AST debug render inside `update_original_asts_with_second_pass_substitutions`, continuing direct `EnableGraph` ownership convergence inside backend code.
- Scope remains behavior-preserving structural convergence only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (assignment-condition second-pass original-AST debug render callsite)
- Localized one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `$ctx->ast_to_systemverilog(...)` to `$ctx->{enable_graph}->ast_to_systemverilog(...)`.
- The change is in the assignment-condition original-AST debug render inside `update_original_asts_with_second_pass_substitutions`, continuing direct `EnableGraph` ownership convergence inside backend code.
- Scope remains behavior-preserving structural convergence only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (LHS-level second-pass substituted-AST debug render callsite)
- Localized one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `$ctx->ast_to_systemverilog(...)` to `$ctx->{enable_graph}->ast_to_systemverilog(...)`.
- The change is in the LHS-level substituted-AST debug render inside `update_original_asts_with_second_pass_substitutions`, continuing direct `EnableGraph` ownership convergence inside backend code.
- Scope remains behavior-preserving structural convergence only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (LHS-level second-pass original-AST debug render callsite)
- Localized one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `$ctx->ast_to_systemverilog(...)` to `$ctx->{enable_graph}->ast_to_systemverilog(...)`.
- The change is in the LHS-level original-AST debug render inside `update_original_asts_with_second_pass_substitutions`, continuing direct `EnableGraph` ownership convergence inside backend code.
- Scope remains behavior-preserving structural convergence only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (DT-specific second-pass substituted-AST debug render callsite)
- Localized one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `$ctx->ast_to_systemverilog(...)` to `$ctx->{enable_graph}->ast_to_systemverilog(...)`.
- The change is in the DT-specific substituted-AST debug render inside `update_original_asts_with_second_pass_substitutions`, continuing direct `EnableGraph` ownership convergence inside backend code.
- Scope remains behavior-preserving structural convergence only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (original-AST consolidated fallback render callsite)
- Localized one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `$ctx->ast_to_systemverilog(...)` to `$ctx->{enable_graph}->ast_to_systemverilog(...)`.
- The change is in the original-AST fallback branch of consolidated intermediate-signal assign generation (`generate_consolidated_intermediate_signals`), continuing direct `EnableGraph` ownership convergence inside backend code.
- Scope remains behavior-preserving structural convergence only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (substituted-AST consolidated render callsite)
- Localized one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `$ctx->ast_to_systemverilog(...)` to `$ctx->{enable_graph}->ast_to_systemverilog(...)`.
- The change is in the substituted-AST branch of consolidated intermediate-signal assign generation (`generate_consolidated_intermediate_signals`), continuing direct `EnableGraph` ownership convergence inside backend code.
- Scope remains behavior-preserving structural convergence only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
## 2026-03-06
### FlattenedDT backend convergence (final-filtered debug AST render callsite)
- Localized one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `$ctx->ast_to_systemverilog(...)` to `$ctx->{enable_graph}->ast_to_systemverilog(...)`.
- The change is in the final-filtered debug listing of consolidated intermediate-signal generation (`generate_consolidated_intermediate_signals`), continuing direct `EnableGraph` ownership convergence inside backend code.
- Scope remains behavior-preserving structural convergence only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (rescued-signal debug AST render callsite)
- Localized one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `$ctx->ast_to_systemverilog(...)` to `$ctx->{enable_graph}->ast_to_systemverilog(...)`.
- The change is in the rescued-signal debug listing of consolidated intermediate-signal generation (`generate_consolidated_intermediate_signals`), continuing direct `EnableGraph` ownership convergence inside backend code.
- Scope remains behavior-preserving structural convergence only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (initial-filtering AST render callsite)
- Localized one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `$ctx->ast_to_systemverilog(...)` to `$ctx->{enable_graph}->ast_to_systemverilog(...)`.
- The change is in the initial filtering pass of consolidated intermediate-signal generation (`generate_consolidated_intermediate_signals`), continuing direct `EnableGraph` ownership convergence inside backend code.
- Scope remains behavior-preserving structural convergence only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend convergence (dependency-map AST render callsite)
- Localized one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `$ctx->ast_to_systemverilog(...)` to `$ctx->{enable_graph}->ast_to_systemverilog(...)`.
- The change is in consolidated intermediate-signal dependency-map construction (`generate_consolidated_intermediate_signals`), further aligning backend callsites with direct `EnableGraph` ownership.
- Scope remains behavior-preserving structural convergence only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### README promoted as project single entry point
- Reworked `README.md` into the canonical onboarding hub for the repository.
- Added explicit project objective and ramp-up sequence.
- Added complete markdown index for all repository `.md` files:
  - `README.md`
  - `CHANGES.md`
  - `DEVELOPMENT_NOTES.md`
  - `MEMORY.md`
  - `COMMIT.md`
  - `WARP.md`
  - `docs/USER_GUIDE.md`
  - `.agents/workflows/commit.md`
- Added key project file/path references for core pipeline, backend, synthesis, tests, and support directories.
- Added README maintenance policy clarifying that README is updated when onboarding-critical information changes, not necessarily on every commit.
## 2026-02-28
### FlattenedDT backend decomposition continuation (final-expression usage-check helper)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving final-expression usage-check helper ownership (`is_signal_actually_used_in_final_expressions`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->is_signal_actually_used_in_final_expressions(...)`.
- Updated backend AST/string filtering paths to invoke backend-local usage-check helper (`$self->is_signal_actually_used_in_final_expressions(...)`) while preserving behavior.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend decomposition continuation (string-fallback filtering helper)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving string-fallback filtering helper ownership (`should_filter_string_based`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->should_filter_string_based(...)`.
- Updated backend consolidated-signal filtering fallback path to invoke backend-local helper (`$self->should_filter_string_based(...)`) while preserving behavior.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend decomposition continuation (simple-comparison helper)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving simple-comparison helper ownership (`is_simple_comparison`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->is_simple_comparison(...)`.
- Updated backend AST-based filtering flow to invoke backend-local simple-comparison helper (`$self->is_simple_comparison(...)`) while preserving behavior.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend decomposition continuation (simple-negation helper)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving simple-negation helper ownership (`is_simple_negation`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->is_simple_negation(...)`.
- Updated backend AST-based filtering flow to invoke backend-local simple-negation helper (`$self->is_simple_negation(...)`) while preserving behavior.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend decomposition continuation (AST-based filtering helper)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving AST-based filtering helper ownership (`should_filter_ast_based`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->should_filter_ast_based(...)`.
- Updated backend consolidated-signal filtering flow to invoke backend-local AST filtering helper (`$self->should_filter_ast_based(...)`) while preserving behavior.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend decomposition continuation (consolidated-signal filtering entrypoint)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving consolidated-signal filtering ownership (`should_filter_consolidated_signal`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->should_filter_consolidated_signal(...)`.
- Updated backend consolidated intermediate-signal generation callsite to use backend-local helper invocation (`$self->should_filter_consolidated_signal(...)`) while preserving behavior.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
## 2026-02-27
### FlattenedDT backend decomposition continuation (intermediate-reference extraction helper)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving intermediate-reference extraction ownership (`extract_intermediate_signals_from_expression`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->extract_intermediate_signals_from_expression(...)`.
- Updated backend dependency/trace callsites to use backend-local helper invocation (`$self->extract_intermediate_signals_from_expression(...)`) while preserving behavior.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend decomposition continuation (substituted intermediate AST resolver)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving substituted intermediate AST resolver ownership (`get_substituted_ast_for_signal`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->get_substituted_ast_for_signal(...)`.
- Updated backend consolidated-intermediate emission flow to use backend-local resolver call (`$self->get_substituted_ast_for_signal(...)`) while preserving behavior.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend decomposition continuation (recursive intermediate-signal detector)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving recursive intermediate-signal detector ownership (`ast_has_intermediate_signals_recursive`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->ast_has_intermediate_signals_recursive(...)`.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend decomposition continuation (second-pass intermediate-expression filter)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving second-pass intermediate-expression filter ownership (`ast_contains_intermediate_signals`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->ast_contains_intermediate_signals(...)`.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend decomposition continuation (second-pass substitution update helper)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving second-pass AST substitution update ownership (`update_original_asts_with_second_pass_substitutions`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->update_original_asts_with_second_pass_substitutions(...)`.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend decomposition continuation (second-pass AST feed helper)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving second-pass AST feeding ownership (`feed_current_asts_to_second_pass`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->feed_current_asts_to_second_pass(...)`.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### Shared post-substitution factorization package extraction
- Added new backend-neutral package `perl/FSM/HDL/Factorization/Fixpoint.pm` with purpose-specific naming: `FSM::HDL::Factorization::Fixpoint`.
- Moved iterative post-substitution factorization algorithm ownership from `Backend::SystemVerilog` into this shared package so all backends can consume the same convergence engine.
- Updated `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`:
  - imports `FSM::HDL::Factorization::Fixpoint`,
  - `run_second_pass_factorization(...)` is now a compatibility delegate that calls the shared package.
- Factorization convergence behavior remains deterministic and bounded by explicit termination guards (no candidates/progress, repeated signature, max-pass cap).
- Validation:
  - `perl -I perl -c perl/FSM/HDL/Factorization/Fixpoint.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### FlattenedDT backend decomposition continuation
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving second-pass factorization orchestration ownership (`run_second_pass_factorization`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->run_second_pass_factorization(...)`.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving AST substitution-backpropagation helper ownership (`update_original_asts_with_substituted_versions`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->update_original_asts_with_substituted_versions(...)`.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving unary-negation counting helper ownership (`count_unary_negations_in_original_expressions`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->count_unary_negations_in_original_expressions()`.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving AST-factorizer input feeding ownership (`feed_asts_to_factorizer`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->feed_asts_to_factorizer(...)`.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving global AST-factorization orchestration ownership (`run_global_ast_factorization`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->run_global_ast_factorization()`.
- Added required backend import support for migrated logic (`List::Util::min`) in `Backend::SystemVerilog`.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving consolidated intermediate-signal emission ownership (`generate_consolidated_intermediate_signals`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->generate_consolidated_intermediate_signals(...)`.
- Added required backend import support for migrated logic (`Scalar::Util::blessed`) in `Backend::SystemVerilog`.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `prove -I perl t` (pass: `Files=6`, `Tests=125`)
### First-class multi-level tracing rollout
- Implemented first-class tracing core in `perl/FSM/Debug.pm` with named verbosity levels (`none`, `low`, `medium`, `high`, `debug`) mapped to `0..4`.
- Preserved numeric compatibility via existing debug-level flow (`--debug[=N]`), with bare `--debug` treated as max verbosity.
- Added structured trace helpers and formatting primitives for topic/enter/exit/decision tracing with source metadata (`file`, `function`, `line`) and indentation-aware output.
- Added configurable trace output routing:
  - new trace filehandle controls in debug core,
  - trace output now routes to `trace.log` (or selected file) instead of stdout when trace-log routing is enabled.
- Integrated CLI trace controls in `bin/fsmgen`:
  - `--trace-verbosity <none|low|medium|high|debug>`,
  - `--trace-log[=FILE]` (default `trace.log`),
  - `--trace-emojis` / `--notrace-emojis`.
- Removed legacy tee-based debug-log handling from `bin/fsmgen` and aligned run-finalization cleanup with trace-file lifecycle handling.
- Added structured trace hooks across key generation/parsing surfaces:
  - `perl/FSM/Pipeline/HDLGenerator.pm`,
  - `perl/FSM/Adapter/FSMGenFull.pm`,
  - `perl/FSM/Adapter/FSMGenFull/Parser.pm`.
- Updated user-facing docs:
  - `README.md`,
  - `docs/USER_GUIDE.md`.
- Added tracing regression coverage:
  - `t/06-tracing-system.t` validating trace-file capture and trace metadata format.
- Validation:
  - syntax checks for touched Perl modules/scripts: pass,
  - full suite: `prove -I perl t` -> `Files=6, Tests=125, PASS`.
### Commit workflow documentation hardening
- Added new tracked workflow document `COMMIT.md` as the canonical commit-process reference for AI handoff continuity.
- Documented precise commit workflow scope and cadence:
  - run after each completed task/activity,
  - include required file update order and post-commit cleanup.
- Documented exact role of involved files:
  - `COMMIT.md`, `MEMORY.md`, `CHANGES.md`, `DEVELOPMENT_NOTES.md`, `git_message_brief.txt`, and task-touched source/test files.
- Documented exact operational sequence:
  - task completion, ordered doc updates, validation, commit message preparation, staging, commit, message-file truncation, and final status verification.
## 2026-02-26
### FlattenedDT backend decomposition continuation
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving WEN/EN emission entrypoint ownership (`generate_wen_en_signals`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->generate_wen_en_signals(...)`.
- Scope of this slice remains behavior-preserving refactor only (ownership move + delegation), with no intended HDL semantic change.
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving intermediate-signal declaration emission ownership (`generate_intermediate_signal_declarations`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->generate_intermediate_signal_declarations(...)`.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving combinational-mux emission ownership (`generate_comb_mux`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->generate_comb_mux(...)`.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
- Continued backend extraction in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by moving flop-mux emission ownership (`generate_flop_mux`) out of `FlattenedDT`.
- Updated `perl/FSM/HDL/FlattenedDT.pm` to keep compatibility behavior via delegation to `backend_sv->generate_flop_mux(...)`.
- Scope remains behavior-preserving structural decomposition only, with no intended HDL semantic change.
## 2026-02-24
### FlattenedDT decomposition kickoff: explicit orchestrator track
- Recorded and aligned roadmap direction to decompose remaining `FlattenedDT` responsibilities across two direct breakdown tracks:
  - `Orchestrator` for top-level generation sequencing,
  - backend emitter modules for rendering ownership.
- Clarified ownership language: `FSM::Synthesis::EnableGraph` remains a synthesis helper module used by `FlattenedDT`, not a direct `FlattenedDT` submodule breakdown track.
- Added a dedicated orchestrator module:
  - `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`.
- Moved `generate_systemverilog` pipeline sequencing ownership out of `FlattenedDT` into `FlattenedDT::Orchestrator` without changing generated HDL behavior.
- Updated `FlattenedDT` to instantiate the orchestrator and delegate `generate_systemverilog(...)` through a compatibility facade.
- Added dedicated backend module namespace:
  - `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- Moved module declaration emission ownership (`generate_module_declaration`) out of `FlattenedDT` into `FlattenedDT::Backend::SystemVerilog` without changing generated HDL behavior.
- Updated `FlattenedDT` to instantiate the backend module and delegate `generate_module_declaration(...)` through a compatibility facade.
- Continued backend decomposition with state-encoding emission ownership (`generate_state_encoding`) moved out of `FlattenedDT` into `FlattenedDT::Backend::SystemVerilog` without changing generated HDL behavior.
- Updated `FlattenedDT` to delegate `generate_state_encoding(...)` through the backend compatibility facade.
- Continued backend decomposition with state-register emission ownership (`generate_state_register`) moved out of `FlattenedDT` into `FlattenedDT::Backend::SystemVerilog` without changing generated HDL behavior.
- Updated `FlattenedDT` to delegate `generate_state_register(...)` through the backend compatibility facade.
- Continued backend decomposition with enable-conditions emission ownership (`generate_enable_conditions`) moved out of `FlattenedDT` into `FlattenedDT::Backend::SystemVerilog` without changing generated HDL behavior.
- Updated `FlattenedDT` to delegate `generate_enable_conditions(...)` through the backend compatibility facade.
- Continued backend decomposition with header emission ownership (`generate_header`) moved out of `FlattenedDT` into `FlattenedDT::Backend::SystemVerilog` without changing generated HDL behavior.
- Updated `FlattenedDT` to delegate `generate_header(...)` through the backend compatibility facade.
- Continued backend decomposition with internal-signal declaration ownership (`generate_internal_signal_declarations`) moved out of `FlattenedDT` into `FlattenedDT::Backend::SystemVerilog` without changing generated HDL behavior.
- Updated `FlattenedDT` to delegate `generate_internal_signal_declarations(...)` through the backend compatibility facade.
- Added dedicated Verilog backend module:
  - `perl/FSM/HDL/FlattenedDT/Backend/Verilog.pm`.
- Moved Verilog generation ownership (`generate_verilog`, `convert_systemverilog_to_verilog`) out of `FlattenedDT` into `FlattenedDT::Backend::Verilog` without changing generated HDL behavior.
- Updated `FlattenedDT` to instantiate `Backend::Verilog` and delegate Verilog-generation entrypoints through the compatibility facade.
- Validation:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/Verilog.pm` (pass)
  - `prove -I perl t` (pass: 5 files, 117 tests)

## 2026-02-22
### Phase 1 modernization slice: explicit assignment intent metadata
- Added explicit assignment-intent metadata to CoreAST assignment objects:
  - `assignment_intent` (operator symbol, sequencing mode, register style, assignment family)
  - `source_provenance` (raw operator/signal/value context)
  - `output_exposure` (`auto`/`explicit`)
- Added assignment-level accessors:
  - `assignment_intent`, `source_provenance`, `output_exposure`, `operator_symbol`, `register_style`.

### Parser wiring for intent-first semantics
- Updated `perl/FSM/Adapter/FSMGenFull/Parser.pm` signal-action construction to emit explicit intent for:
  - `<-` => clocked `output_named`, `lhs_binding=flop_q_output`
  - `<=` => clocked `input_named`, `lhs_binding=flop_d_input`, `immediate_visibility=same_cycle_on_d_input`, `hold_policy=q_feedback_when_no_enable`
  - `=`  => combinatorial
- Added parser provenance capture and explicit-output exposure propagation from `>` LHS marker.

### Backend updates
- Updated `perl/FSM/HDL/FlattenedDT.pm` assignment recording to consume assignment-intent metadata directly and fail fast on missing/invalid operator intent.
- Added intent metadata to synthesized state-transition assignment records for uniform downstream handling.
- Tightened assignment-type classification (`register_out` / `register_in` / `mux_out`) to require explicit operator presence in analysis records.

### Tests
- Added `t/03-assignment-intent-metadata.t` to validate:
  - parser metadata emission for `<-`, `<=`, `=`
  - explicit-output exposure from `>` marker
  - backend assignment-type classifier behavior.
- Validation run:
  - `prove -v t/03-assignment-intent-metadata.t t/02-combinational-self-dependency.t t/01-regression.t` (pass).

### Legacy reference documentation and semantic clarification
- Archived the full legacy `fx/perl/FSMGen.pm` analysis in `DEVELOPMENT_NOTES.md` for future modernization work.
- Clarified authoritative `<N` / `pN` semantics from framework intent:
  - `<N` means an exact one-cycle pulse emitted at decision cycle `Q+N` (N is delay, not pulse width).
  - Legacy code has intent markers/comments for pulse behavior but does not implement a dedicated pulse backend yet.

### Assignment-family completion (`c`, `r`, `m`, `rm`, `mr`, `pN`)
- Extended parser/operator handling to cover all requested operator families:
  - `=`, `<-`, `<=`, `<-=`, `<=+`, `<N`.
- Added/normalized intent metadata and backend classification for:
  - `register_out`, `register_in`, `register_out_dual`, `register_in_dual`, `pulse_delayed`, `mux_out`.
- Implemented rm/mr auxiliary exposure behavior in emitted HDL:
  - `<-=` exposes `next_<lhs>`
  - `<=+` exposes `<lhs>_r`
- Implemented delayed pulse backend generation for `<N` with authoritative semantics:
  - exact `Q+N` emission,
  - fixed one-cycle pulse width,
  - polarity from RHS (`<N 1` positive pulse, `<N 0` negative pulse),
  - **delay** semantics (not duration).
- Fixed signal metadata/width propagation issues that affected auxiliary port direction/width:
  - auxiliary outputs now emit as outputs (not inferred inputs),
  - auxiliary widths track parent signal widths even when `+size` appears after assignment actions.
- Validation:
  - `prove -I perl t/03-assignment-intent-metadata.t` (pass)
  - `prove -I perl t/02-combinational-self-dependency.t t/01-regression.t` (pass)
  - `prove -I perl t` (full suite pass)

### Assignment semantics hardening: edge cases + golden snapshots
- Added focused edge-case regression `t/04-assignment-edge-cases.t`:
  - validates `<0 1` / `<0 0` immediate delayed-pulse semantics (`Q+0`, no delay pipeline register),
  - rejects invalid `<N` RHS values (must be literal `0` or `1`),
  - rejects mixed incompatible assignment families on same LHS:
    - combinational + sequential,
    - pulse-delayed + non-pulse sequential,
    - multiple conflicting pulse delays.
- Added golden snapshot regression `t/05-assignment-hdl-snapshots.t` and fixtures under `t/golden/` for:
  - module port exposure/widths (including `next_*` and `*_r`),
  - rm (`<-=`) emitted block shape,
  - mr (`<=+`) emitted block shape,
  - pN delayed pulse blocks for `<2 0` and `<3 1`.

### Architecture slice start: enable synthesis extraction
- Added initial dedicated enable-synthesis layer:
  - `perl/FSM/Synthesis/EnableGraph.pm`
- Refactored `FlattenedDT` to delegate complete enable-structure synthesis via `EnableGraph`:
  - keeps current behavior unchanged while establishing an extraction seam for subsequent slices.
- Follow-up extraction increment:
  - moved RHS grouping orchestration (`group_assignments_by_rhs`) from `FlattenedDT` into `EnableGraph`,
  - `FlattenedDT` now delegates this step to the synthesis layer as part of unified assignment analysis.
- Latest extraction increment:
  - moved multiplexer configuration assembly (`build_multiplexer_config`) from `FlattenedDT` into `EnableGraph`,
  - `FlattenedDT` now delegates this step as well, expanding the synthesis-layer seam while preserving behavior.
- Newest extraction increment:
  - moved unified assignment-analysis orchestration (`build_unified_assignment_analysis`) from `FlattenedDT` into `EnableGraph`,
  - `FlattenedDT` now delegates the top-level per-LHS analysis loop to the synthesis layer.
- Latest extraction increment:
  - moved unified phase-2 WEN/EN generation (`generate_unified_wen_en_signals`) into `EnableGraph`,
  - moved DT-specific and LHS-level enable emission helpers (`generate_dt_enables_from_analysis`, `generate_lhs_enables_from_analysis`) into `EnableGraph`,
  - `FlattenedDT` now delegates these phase-2 enable emission entrypoints to the synthesis layer.
- Newest extraction increment:
  - moved unified phase-3 multiplexer orchestration (`generate_signal_assignments`) into `EnableGraph`,
  - `FlattenedDT` now delegates the phase-3 assignment-emission entrypoint to the synthesis layer while keeping mux-specific emitters behavior-identical.
- Latest extraction increment:
  - moved unified combinational mux emitter (`generate_unified_comb_mux`) into `EnableGraph`,
  - updated phase-3 orchestration in `EnableGraph` to call its local combinational mux emitter,
  - `FlattenedDT` now delegates the combinational mux emitter entrypoint to the synthesis layer.
- Newest extraction increment:
  - moved unified flop mux emitter (`generate_unified_flop_mux`) into `EnableGraph`,
  - updated phase-3 orchestration in `EnableGraph` to call its local flop mux emitter,
  - `FlattenedDT` now delegates the flop mux emitter entrypoint to the synthesis layer.
- Latest continuity increment:
  - added new live recovery document `MEMORY.md` for crash/session-handoff continuity,
  - documented mandatory workflow: update `MEMORY.md` and other live docs before every commit workflow,
  - documented compact resume checklist and current extraction status snapshot for successor agents.
- Newest extraction increment:
  - moved unified pulse-delay emitter (`generate_unified_pulse_delay_logic`) into `EnableGraph`,
  - updated phase-3 orchestration in `EnableGraph` to call its local pulse-delay emitter,
  - `FlattenedDT` now delegates the pulse-delay emitter entrypoint to the synthesis layer.
- Latest extraction increment:
  - moved pulse helper analysis methods (`get_pulse_delay_cycles_for_lhs`, `get_pulse_active_level_for_lhs`, `normalize_rhs_logic_level`) into `EnableGraph`,
  - updated `EnableGraph` pulse-delay emission path to use local helper methods,
  - `FlattenedDT` now keeps compatibility delegations for those helper entrypoints.
- Newest extraction increment:
  - moved enable naming helpers (`clean_signal_name`, `generate_rhs_based_enable_name`) into `EnableGraph`,
  - updated enable-structure generation in `EnableGraph` to use local naming helper ownership,
  - `FlattenedDT` now keeps compatibility delegations for those naming helper entrypoints.
- Latest extraction increment:
  - moved assignment-type helpers (`signal_uses_register_assignment`, `get_signal_assignment_type`) into `EnableGraph`,
  - updated `EnableGraph` phase-3 paths to resolve assignment family through local helper ownership,
  - `FlattenedDT` now keeps compatibility delegations for these assignment-type helper entrypoints.
- Latest extraction increment:
  - moved driven-signal classification (`get_driven_signals`) into `EnableGraph`,
  - module declaration output-direction inference still resolves driven signals through `FlattenedDT` compatibility delegation,
  - `EnableGraph` now owns auxiliary-output driven classification for `rm` (`next_<lhs>`) and `mr` (`<lhs>_r`) using local assignment-type ownership.
- Newest extraction increment:
  - moved reset-value resolution helper (`get_reset_value`) into `EnableGraph`,
  - `FlattenedDT` now delegates reset-value lookup to `EnableGraph` via compatibility shim,
  - `EnableGraph` currently resolves reset-state and signal reset metadata through existing `FlattenedDT` reset-info helpers to preserve behavior during staged extraction.
- Latest extraction increment:
  - moved default-value resolution helper (`get_default_value`) into `EnableGraph`,
  - `FlattenedDT` now delegates default-value lookup to `EnableGraph` via compatibility shim,
  - `get_default_value_from_ast` behavior remains unchanged and now resolves through the delegated default-value ownership path.
- Newest extraction increment:
  - moved signal-info helper (`get_signal_info`) into `EnableGraph`,
  - `FlattenedDT` now delegates signal-info lookup to `EnableGraph` via compatibility shim,
  - reset-value resolution in `EnableGraph` now uses local signal-info ownership while preserving existing reset-state/explicit-reset helper paths.
- Latest extraction increment:
  - moved explicit-reset helper (`get_explicit_reset_value`) into `EnableGraph`,
  - `FlattenedDT` now delegates explicit-reset lookup to `EnableGraph` via compatibility shim,
  - reset-value resolution in `EnableGraph` now uses local explicit-reset ownership while preserving existing reset-state helper path.
- Newest extraction increment:
  - moved FSM reset-state helper (`get_fsm_reset_state`) into `EnableGraph`,
  - `FlattenedDT` now delegates reset-state lookup to `EnableGraph` via compatibility shim,
  - reset-value resolution in `EnableGraph` now uses local reset-state ownership for `next_state` semantics.
- Latest extraction increment:
  - moved AST reset-value helper (`get_reset_value_from_ast`) into `EnableGraph`,
  - updated `EnableGraph` flop-mux emission to call local AST reset-value ownership,
  - `FlattenedDT` now delegates AST reset-value lookup to `EnableGraph` via compatibility shim.
- Newest extraction increment:
  - moved AST default-value helper (`get_default_value_from_ast`) into `EnableGraph`,
  - updated `EnableGraph` multiplexer config assembly to call local AST default-value ownership,
  - `FlattenedDT` now delegates AST default-value lookup to `EnableGraph` via compatibility shim.
- Latest extraction increment:
  - moved explicit-reset configuration setter (`set_explicit_reset_values`) into `EnableGraph`,
  - `FlattenedDT` now delegates explicit-reset configuration to `EnableGraph` via compatibility shim,
  - `EnableGraph` now owns writes to explicit reset-value configuration consumed by reset-resolution helpers.
- Newest extraction increment:
  - moved FSM module-reference setter (`set_fsm_module_reference`) into `EnableGraph`,
  - `FlattenedDT` now delegates FSM module-reference storage to `EnableGraph` via compatibility shim,
  - `EnableGraph` now owns writes to the shared FSM module reference used by signal-info/reset helper paths.
- Latest extraction increment:
  - moved register-classification helpers (`is_register`, `fallback_register_analysis_from_assignments`) into `EnableGraph`,
  - updated `EnableGraph` multiplexer configuration assembly to resolve register-vs-combinational selection through local helper ownership,
  - `FlattenedDT` now delegates register-classification helper entrypoints to `EnableGraph` via compatibility shims.
- Newest extraction increment:
  - moved AST signal-name extraction helper (`extract_signal_name_from_ast`) into `EnableGraph`,
  - updated `EnableGraph` AST reset/default helper paths to resolve signal names through local helper ownership,
  - `FlattenedDT` now delegates AST signal-name extraction to `EnableGraph` via compatibility shim.
- Latest extraction increment:
  - moved LHS-width analysis helper (`get_lhs_width_from_analysis`) into `EnableGraph`,
  - updated `EnableGraph` pulse-delay emission path to resolve target width through local helper ownership,
  - `FlattenedDT` now delegates LHS-width analysis to `EnableGraph` via compatibility shim.
- Newest extraction increment:
  - moved intermediate-signal AST tracker (`track_ast_intermediate_signals`) into `EnableGraph`,
  - updated `EnableGraph` DT/LHS enable emission paths to call local intermediate-signal tracking ownership,
  - `FlattenedDT` now delegates intermediate-signal AST tracking to `EnableGraph` via compatibility shim.
- Latest extraction increment:
  - moved intermediate-signal classification helper (`is_intermediate_signal`) into `EnableGraph`,
  - updated `EnableGraph` intermediate-signal AST tracking path to call local classification ownership,
  - `FlattenedDT` now delegates intermediate-signal classification to `EnableGraph` via compatibility shim.
- Newest extraction increment:
  - moved AST-based intermediate classification helper (`is_signal_ast_based_intermediate`) into `EnableGraph`,
  - updated `EnableGraph` intermediate-signal classification path to call local AST-based classification ownership,
  - `FlattenedDT` now delegates AST-based intermediate classification to `EnableGraph` via compatibility shim.
- Latest extraction increment:
  - moved AST factorization operator helper (`_ast_contains_factorizable_operators`) into `EnableGraph`,
  - updated `EnableGraph` AST-based intermediate classification path to call local operator-analysis ownership,
  - `FlattenedDT` now delegates AST operator-analysis helper entrypoints to `EnableGraph` via compatibility shim.
- Newest extraction increment:
  - moved arithmetic-operation helper (`is_arithmetic_operation`) into `EnableGraph`,
  - updated `EnableGraph` AST factorization operator-analysis path to call local arithmetic-operation ownership,
  - `FlattenedDT` now delegates arithmetic-operation helper entrypoints to `EnableGraph` via compatibility shim.
- Latest extraction increment:
  - moved logical-operation helper (`is_logical_operation`) into `EnableGraph`,
  - updated `EnableGraph` AST factorization operator-analysis path to call local logical-operation ownership,
  - `FlattenedDT` now delegates logical-operation helper entrypoints to `EnableGraph` via compatibility shim.
- Newest extraction increment:
  - moved logical-factorization policy helper (`should_factor_logical_operation`) into `EnableGraph`,
  - updated `EnableGraph` AST factorization operator-analysis path to call local logical-factorization policy ownership,
  - `FlattenedDT` now delegates logical-factorization policy helper entrypoints to `EnableGraph` via compatibility shim.
- Latest extraction increment:
  - moved frequent-logical-usage helper (`contains_frequently_used_operations`) into `EnableGraph`,
  - updated `EnableGraph` logical-factorization policy path to call local frequent-logical-usage ownership,
  - `FlattenedDT` now delegates frequent-logical-usage helper entrypoints to `EnableGraph` via compatibility shim.
- Newest extraction increment:
  - moved intermediate-signal expression resolver (`get_intermediate_signal_expression`) into `EnableGraph`,
  - updated `EnableGraph` frequent-logical-usage helper path to call local intermediate-signal expression ownership,
  - `FlattenedDT` now delegates intermediate-signal expression resolver entrypoints to `EnableGraph` via compatibility shim.
- Latest extraction increment:
  - moved intermediate-signal expression synthesis helper (`generate_expression_from_signal_name`) into `EnableGraph`,
  - updated `EnableGraph` intermediate-signal expression resolver path to call local expression-synthesis ownership,
  - `FlattenedDT` now delegates intermediate-signal expression synthesis helper entrypoints to `EnableGraph` via compatibility shim.
- Newest extraction increment:
  - moved AST-based intermediate-name metadata helper (`_signal_name_indicates_ast_operators`) into `EnableGraph`,
  - updated `EnableGraph` AST intermediate classification path to call local intermediate-name metadata ownership,
  - `FlattenedDT` now delegates AST-based intermediate-name metadata helper entrypoints to `EnableGraph` via compatibility shim.
- Latest extraction increment:
  - moved AST-to-SystemVerilog rendering helper (`ast_to_systemverilog`) into `EnableGraph`,
  - updated `EnableGraph` DT/LHS enable emission paths to call local AST rendering ownership,
  - `FlattenedDT` now delegates AST-to-SystemVerilog rendering helper entrypoints to `EnableGraph` via compatibility shim.
- Newest extraction increment:
  - moved AST signal-reference traversal helper (`ast_contains_signal`) into `Backend::SystemVerilog`,
  - updated backend final-expression usage checks to call local AST signal-reference traversal ownership,
  - `FlattenedDT` now delegates AST signal-reference traversal entrypoints to backend ownership via compatibility shim.
- Latest extraction increment:
  - moved substitution-reference usage helper (`is_signal_referenced_in_substitutions`) into `Backend::SystemVerilog`,
  - updated backend AST/string filtering paths to call local substitution-reference usage ownership,
  - `FlattenedDT` now delegates substitution-reference usage entrypoints to backend ownership via compatibility shim.
- Newest extraction increment:
  - moved intermediate-signal dependency ordering helper (`topologically_sort_signals`) into `Backend::SystemVerilog`,
  - updated backend consolidated intermediate-signal emission to call local dependency ordering ownership,
  - `FlattenedDT` now delegates dependency ordering entrypoints to backend ownership via compatibility shim.
- Latest extraction increment:
  - localized backend factorization/filtering callsites to backend-owned helpers in `Backend::SystemVerilog`,
  - updated backend paths to call local ownership for `is_signal_referenced_in_substitutions`, `run_global_ast_factorization`, `feed_asts_to_factorizer`, `count_unary_negations_in_original_expressions`, `update_original_asts_with_substituted_versions`, and `run_second_pass_factorization`,
  - reduced backend round-trips through `FlattenedDT` compatibility shims without changing behavior.
- Newest extraction increment:
  - localized second-pass AST feed checks to backend-owned intermediate-signal detection in `Backend::SystemVerilog`,
  - updated second-pass DT/LHS/assignment condition gating to call local `ast_contains_intermediate_signals` ownership,
  - removed remaining backend round-trips through `FlattenedDT` for this helper path without behavior changes.
- Latest extraction increment:
  - localized backend unified WEN/EN generation callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated backend WEN/EN emission to call `enable_graph->generate_unified_wen_en_signals(...)` directly,
  - removed the remaining backend round-trip through `FlattenedDT` for this phase-2 generation path.
- Newest extraction increment:
  - localized backend intermediate-signal expression lookup callsites to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated consolidated and declaration emission paths to call `enable_graph->get_intermediate_signal_expression(...)` directly,
  - removed remaining backend round-trips through `FlattenedDT` for intermediate-signal expression resolution.
- Latest extraction increment:
  - localized backend driven-signal classification callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated module-declaration port-direction analysis to call `enable_graph->get_driven_signals(...)` directly,
  - removed the backend round-trip through `FlattenedDT` for driven-signal lookup in this path.
- Newest extraction increment:
  - localized backend assignment-type classification callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated internal-signal declaration analysis to call `enable_graph->get_signal_assignment_type(...)` directly,
  - removed the backend round-trip through `FlattenedDT` for assignment-type lookup in this path.
- Latest extraction increment:
  - localized backend LHS-width analysis callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated internal-signal declaration analysis to call `enable_graph->get_lhs_width_from_analysis(...)` directly,
  - removed the backend round-trip through `FlattenedDT` for LHS-width lookup in this path.
- Newest extraction increment:
  - localized backend pulse-delay-cycle lookup callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated internal-signal declaration analysis to call `enable_graph->get_pulse_delay_cycles_for_lhs(...)` directly,
  - removed the backend round-trip through `FlattenedDT` for pulse-delay-cycle lookup in this path.
- Latest extraction increment:
  - localized backend reset-value lookup callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated flop-mux reset emission to call `enable_graph->get_reset_value(...)` directly,
  - removed the backend round-trip through `FlattenedDT` for reset-value lookup in this path.
- Newest extraction increment:
  - localized backend default-value lookup callsites to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated comb/flop mux default assignment emission to call `enable_graph->get_default_value(...)` directly,
  - removed backend round-trips through `FlattenedDT` for default-value lookup in these paths.
- Latest extraction increment:
  - localized backend intermediate-signal classification callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated recursive intermediate-signal detection to call `enable_graph->is_intermediate_signal(...)` directly,
  - removed the backend round-trip through `FlattenedDT` for this classification path.
- Newest extraction increment:
  - localized backend arithmetic-operation classification callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated AST filtering to call `enable_graph->is_arithmetic_operation(...)` directly,
  - removed the backend round-trip through `FlattenedDT` for this arithmetic classification path.
- Latest extraction increment:
  - localized backend logical-operation classification callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated AST filtering to call `enable_graph->is_logical_operation(...)` directly,
  - removed the backend round-trip through `FlattenedDT` for this logical classification path.
- Newest extraction increment:
  - localized backend logical-factorization policy callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated AST filtering to call `enable_graph->should_factor_logical_operation(...)` directly,
  - removed the backend round-trip through `FlattenedDT` for this logical-factorization policy path.
- Latest extraction increment:
  - localized one backend AST signal-name extraction callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated backend AST signal-reference traversal (`ast_contains_signal`) to call `enable_graph->extract_signal_name_from_ast(...)` directly,
  - removed one backend round-trip through `FlattenedDT` for AST signal-name extraction in this traversal path.
- Newest extraction increment:
  - localized one second-pass bare-signal AST name-extraction callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated second-pass AST intermediate-signal gating (`ast_contains_intermediate_signals`) to call `enable_graph->extract_signal_name_from_ast(...)` directly,
  - removed one backend round-trip through `FlattenedDT` for AST signal-name extraction in this second-pass filtering path.
- Latest extraction increment:
  - localized one recursive AST intermediate-signal name-extraction callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated recursive second-pass AST intermediate detection (`ast_has_intermediate_signals_recursive`) to call `enable_graph->extract_signal_name_from_ast(...)` directly,
  - removed one backend round-trip through `FlattenedDT` for AST signal-name extraction in this recursive detection path.
- Newest extraction increment:
  - localized one second-pass AST render callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated second-pass bare-signal debug rendering (`ast_contains_intermediate_signals`) to call `enable_graph->ast_to_systemverilog(...)` directly,
  - removed one backend round-trip through `FlattenedDT` for AST rendering in this second-pass filtering path.
- Latest extraction increment:
  - localized one second-pass DT-enable AST render callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated second-pass DT-enable debug rendering (`feed_current_asts_to_second_pass`) to call `enable_graph->ast_to_systemverilog(...)` directly,
  - removed one backend round-trip through `FlattenedDT` for AST rendering in this second-pass DT-enable path.
- Newest extraction increment:
  - localized one second-pass LHS-enable AST render callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated second-pass LHS-enable debug rendering (`feed_current_asts_to_second_pass`) to call `enable_graph->ast_to_systemverilog(...)` directly,
  - removed one backend round-trip through `FlattenedDT` for AST rendering in this second-pass LHS-enable path.
- Latest extraction increment:
  - localized one second-pass assignment-condition AST render callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated second-pass assignment-condition debug rendering (`feed_current_asts_to_second_pass`) to call `enable_graph->ast_to_systemverilog(...)` directly,
  - removed one backend round-trip through `FlattenedDT` for AST rendering in this second-pass assignment-condition path.
- Newest extraction increment:
  - localized one DT-specific substituted-AST render callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated DT-specific substitution debug rendering (`update_original_asts_with_substituted_versions`) to call `enable_graph->ast_to_systemverilog(...)` directly for `original_sv`,
  - removed one backend round-trip through `FlattenedDT` for AST rendering in this DT-specific substitution path.
- Latest extraction increment:
  - localized one DT-specific substituted-AST updated-render callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated DT-specific substitution debug rendering (`update_original_asts_with_substituted_versions`) to call `enable_graph->ast_to_systemverilog(...)` directly for `substituted_sv`,
  - removed one backend round-trip through `FlattenedDT` for AST rendering in this DT-specific substitution-update path.
- Newest extraction increment:
  - localized one LHS-level substituted-AST original-render callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated LHS-level substitution debug rendering (`update_original_asts_with_substituted_versions`) to call `enable_graph->ast_to_systemverilog(...)` directly for `original_sv`,
  - removed one backend round-trip through `FlattenedDT` for AST rendering in this LHS-level substitution path.
- Latest extraction increment:
  - localized one LHS-level substituted-AST updated-render callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated LHS-level substitution debug rendering (`update_original_asts_with_substituted_versions`) to call `enable_graph->ast_to_systemverilog(...)` directly for `substituted_sv`,
  - removed one backend round-trip through `FlattenedDT` for AST rendering in this LHS-level substitution-update path.
- Newest extraction increment:
  - localized one assignment-condition substituted-AST original-render callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated assignment-condition substitution debug rendering (`update_original_asts_with_substituted_versions`) to call `enable_graph->ast_to_systemverilog(...)` directly for `original_sv`,
  - removed one backend round-trip through `FlattenedDT` for AST rendering in this assignment-condition substitution path.
- Latest extraction increment:
  - localized one assignment-condition substituted-AST updated-render callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated assignment-condition substitution debug rendering (`update_original_asts_with_substituted_versions`) to call `enable_graph->ast_to_systemverilog(...)` directly for `substituted_sv`,
  - removed one backend round-trip through `FlattenedDT` for AST rendering in this assignment-condition substitution-update path.
- Newest extraction increment:
  - localized one second-pass DT-specific original-render callsite to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - updated second-pass DT-specific substitution debug rendering (`update_original_asts_with_second_pass_substitutions`) to call `enable_graph->ast_to_systemverilog(...)` directly for `original_sv`,
  - removed one backend round-trip through `FlattenedDT` for AST rendering in this second-pass DT-specific substitution path.
- Avoided loading conflicting legacy `FSM::AST::Utils` implementation in the new module to preserve existing AST utility behavior path.
### Latest AST/CoreAST convergence slice
- Audited `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` and confirmed the live runtime declaration path emits intermediate wires through `generate_consolidated_intermediate_signals(...)`; the older standalone `generate_intermediate_signal_declarations(...)` helper is not on the active path.
- Hardened live consolidated intermediate width handling in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`:
  - added backend-local width normalization that prefers native FSM signal metadata from `EnableGraph::get_signal_info(...)`,
  - falls back to defining AST analysis before any parsed-expression compatibility path,
  - normalizes widths across AST-factorization, prescan-reference, and FSMGen-native intermediate-signal sources before filtering/declaration emission.
- Removed the live-path prescan merge placeholder `width => 1` and made consolidated wire declarations resolve width again at emission time so declarations no longer trust stale placeholder metadata.
- Added live backend handling for factorizer-substituted AST node classes during width inference (`FSM::HDL::IntermediateSignalRef`, `FSM::HDL::SubstitutedUnaryOp`, `FSM::HDL::SubstitutedBinaryOp`) without widening dormant compatibility-only declaration helpers.

### Validation (latest slice)
- `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
- `prove -I perl t` (pass: 6 files, 125 tests)
### Newest AST/CoreAST convergence slice
- Further reduced expression-string handling on the live consolidated intermediate path in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by normalizing a per-signal runtime AST before dependency analysis, filtering, and assign emission.
- Added backend-local runtime-AST/render helpers so the active consolidated path now prefers:
  - substituted factorizer ASTs first,
  - resolved defining ASTs second,
  - parsed stored expressions only as a narrow compatibility fallback.
- Updated the live consolidated dependency/filter/emit phases to consume the normalized runtime AST / AST-rendered expression instead of each branching independently on raw `expression` metadata.
- Kept legacy compatibility behavior isolated:
  - `extract_intermediate_signals_from_expression(...)` remains only the dependency fallback when runtime AST resolution still misses,
  - `should_filter_string_based(...)` remains only the compatibility-only last resort when no runtime AST can be resolved.

### Validation (newest slice)
- `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
- `prove -I perl t` (pass: 6 files, 125 tests)
### Latest AST/CoreAST convergence slice
- Normalized consolidated intermediate dependency metadata in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` behind a backend-local helper so the live dependency graph consumes cached per-signal dependency data instead of performing inline fallback branching.
- The active consolidated path now:
  - resolves dependency lists from runtime ASTs first,
  - caches dependency metadata on each consolidated signal entry,
  - keeps expression-based dependency extraction isolated to one compatibility-only helper path when runtime AST resolution still misses.
- Updated the live consolidated dependency-map construction to consume normalized dependency metadata instead of re-running AST/expression selection inline.

### Validation (latest slice)
- `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
- `prove -I perl t` (pass: 6 files, 125 tests)
### Newest AST/CoreAST convergence slice
- Normalized consolidated rendered-expression metadata in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` so the live path now caches and reuses one rendered-expression value per intermediate signal instead of recomputing or re-falling-back at each use site.
- Reduced eager expression-text handling on prescan-backed consolidated entries:
  - when a runtime AST is already available, prescan merge now keeps AST/runtime metadata without also eagerly hydrating `expression` text,
  - expression text is only carried forward at merge time when runtime AST resolution still misses.
- Added an explicit rendered-expression normalization pass before dependency-aware filtering so the active consolidated path consumes cached render metadata.

### Validation (newest slice)
- `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
- `prove -I perl t` (pass: 6 files, 125 tests)
### Latest AST/CoreAST convergence slice
- Normalized and cached consolidated runtime-AST miss state in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` so AST-resolution failures are recorded once per signal instead of being re-discovered at each live-path callsite.
- The active consolidated path now:
  - records whether runtime-AST resolution is `resolved` or `missing`,
  - stores a miss reason for compatibility-only fallback cases,
  - reuses cached miss state on later dependency/filter/render passes instead of retrying the same AST recovery path repeatedly.

### Validation (latest slice)
- `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
- `prove -I perl t` (pass: 6 files, 125 tests)
### Newest AST/CoreAST convergence slice
- Reduced the remaining compatibility-only miss path in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by recovering runtime ASTs after late expression hydration.
- The live consolidated path now:
  - retries runtime-AST resolution when `EnableGraph` provides an expression for a signal that had previously missed only because no expression source was available yet,
  - upgrades those former `no_ast_source` misses into real runtime ASTs when parsing succeeds,
  - lets dependency extraction consume that recovered AST in the same pass instead of immediately falling back to expression-based dependency extraction.

### Validation (newest slice)
- `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
- `prove -I perl t` (pass: 6 files, 125 tests)
### Latest AST/CoreAST convergence slice
- Further narrowed the explicit runtime-AST miss path in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` during dependency extraction.
- The live consolidated path now:
  - routes runtime-AST misses through a dedicated dependency-recovery helper instead of going straight to the legacy compatibility extractor,
  - skips redundant parse retries for the same stored expression when that expression already produced an `expression_parse_failed` runtime-AST miss,
  - tries alternate known expressions from `EnableGraph` before the final identifier-scan fallback,
  - caches any dependency-time AST recovery back onto the signal metadata so later live-path phases can reuse the recovered runtime AST and refreshed width.
- Reduced the true string-era remainder in this lane:
  - the legacy `extract_intermediate_signals_from_expression(...)` entrypoint now delegates to the explicit runtime-AST-miss helper,
  - the final compatibility-only behavior is narrower and centralized in the last-resort identifier scan, which now defers intermediate-signal identity checks to `EnableGraph::is_intermediate_signal(...)`.

### Validation (latest slice)
- `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
- `prove -I perl t` (pass: 6 files, 125 tests)
### Newest AST/CoreAST convergence slice
- Retired the remaining dead string-era condition / WEN helper island from `perl/FSM/HDL/FlattenedDT.pm`.
- Removed the unused legacy helpers that implemented a parallel string-based path for condition formatting, assignment recording, and DT-specific/LHS-level WEN generation:
  - `record_assignment(...)`
  - `record_transition(...)`
  - `create_condition_expression(...)`
  - `format_condition(...)`
  - `format_signal_expression(...)`
  - `invert_condition(...)`
  - `format_test_value(...)`
  - `resolve_rhs_value(...)`
  - `generate_dt_specific_wens(...)`
  - `generate_lhs_level_wens(...)`
  - `extract_condition_string(...)`
- Removed the now-unused delegators that only existed to support that dead string-era path:
  - `clean_signal_name(...)`
  - `generate_rhs_based_enable_name(...)`
  - `is_complex_expression(...)`
  - `get_or_create_global_expression(...)`
  - `should_factor_condition(...)`
  - `needs_parentheses(...)`
- Added focused regression coverage in `t/10-ast-first-enable-structure.t` to assert that live generation:
  - stores DT-specific and LHS-level enable metadata inside `assignment_analysis->{rhs_groups}`,
  - leaves no legacy top-level `dt_specific_enables` or `lhs_to_enable_value_pairs` state behind.
- Backed this cleanup with a repo-wide reference audit showing that the live path already runs through `FlattenedDT::Orchestrator` AST recorders and `EnableGraph` AST-backed enable synthesis, while the retired helper names remained only in docs.

### Validation (newest slice)
- `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
- `prove -I perl t/09-ast-first-intermediate-registry.t t/10-ast-first-enable-structure.t` (pass: 2 files, 9 tests)
- `prove -I perl t` (pass: 10 files, 152 tests)
### Newest AST/CoreAST convergence slice
- Retired a dead string-era intermediate-signal producer cluster from `perl/FSM/HDL/FlattenedDT.pm`.
- Removed the unused legacy factorization helpers that still created plain-string `intermediate_signals` entries:
  - `perform_global_expression_factorization(...)`
  - `is_simple_expression_for_factorization(...)`
  - `extract_sub_expressions_from_ast(...)`
  - `is_leaf_node(...)`
  - `is_redundant_intermediate_signal(...)`
  - `identify_factorization_candidates(...)`
  - `generate_factorized_signals(...)`
- Tightened the remaining registry contract in `FlattenedDT.pm` so `intermediate_signals` is documented as metadata-hash storage rather than raw string-expression storage.
- Added focused regression coverage in `t/09-ast-first-intermediate-registry.t` to assert that live generation leaves no plain-string or `legacy_string_registry` intermediate entries behind.
- Backed this cleanup with a live audit on known-good fixtures (`fsm/trial_0.fsm`, `fsm/trial_1.fsm`, `fsm/trial_2.fsm`, `fsm/mipicsi2_tester_ctrl.fsm`), which showed the runtime generator already finishing with an empty `intermediate_signals` registry; the removed helpers were dead compatibility residue rather than live behavior.

### Validation (newest slice)
- `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
- `prove -I perl t/09-ast-first-intermediate-registry.t` (pass: 1 file, 3 tests)
- `prove -I perl t` (pass: 9 files, 146 tests)
### Newest AST/CoreAST convergence slice
- Retired the last regex identifier-scan dependency fallback from `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- The explicit runtime-AST-miss dependency path now:
  - attempts AST-backed recovery from rendered/registered expressions,
  - attempts cleaned-expression recovery,
  - attempts structured signal-name AST recovery,
  - and otherwise records the miss as `runtime_ast_miss_unresolved` instead of mining identifiers from opaque strings.
- Removed the dead compatibility helper `scan_intermediate_signal_names_in_expression(...)` from the live backend.
- Strengthened `t/07-runtime-ast-miss-dependency-recovery.t` so opaque invalid legacy expressions like `mid @@ aux` no longer infer `mid`/`aux` dependencies via regex identifier scanning.
- Backed this cleanup with a live audit on known-good fixtures (`fsm/trial_0.fsm`, `fsm/trial_1.fsm`, `fsm/trial_2.fsm`, `fsm/mipicsi2_tester_ctrl.fsm`), which produced zero identifier-scan hits before removal.

### Validation (newest slice)
- `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
- `prove -I perl t/07-runtime-ast-miss-dependency-recovery.t` (pass: 1 file, 8 tests)
- `prove -I perl t` (pass: 8 files, 143 tests)
### Newest AST/CoreAST convergence slice
- Narrowed the remaining explicit runtime-AST-miss filtering residue in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- The live consolidated path now:
  - normalizes per-signal AST-derived live-usage metadata (`referenced_in_substitutions`, `used_in_final_expressions`) before filtering,
  - makes both AST-backed filtering and runtime-AST-miss filtering consume that cached usage metadata instead of re-running the same live-usage scans at each branch,
  - routes explicit runtime-AST misses through a dedicated `should_filter_runtime_ast_miss(...)` helper.
- Reduced the legacy-shaped fallback surface:
  - `should_filter_consolidated_signal(...)` no longer uses `should_filter_string_based(...)` as the live explicit-miss decision point,
  - `should_filter_string_based(...)` is now only a compatibility wrapper that delegates to the runtime-AST-miss helper.

### Validation (newest slice)
- `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
- `prove -I perl t` (pass: 6 files, 125 tests)
### Latest AST/CoreAST convergence slice
- Retired unused legacy-named wrapper entrypoints from the repo:
  - removed `should_filter_string_based(...)` from `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` and from the `perl/FSM/HDL/FlattenedDT.pm` facade,
  - removed `extract_intermediate_signals_from_expression(...)` from `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` and from the `perl/FSM/HDL/FlattenedDT.pm` facade.
- This keeps the live consolidated path aligned with the current AST/CoreAST-first runtime shape:
  - explicit runtime-AST misses are handled through `should_filter_runtime_ast_miss(...)`,
  - dependency fallback is handled through `extract_intermediate_signals_from_runtime_ast_miss(...)`,
  - the remaining compatibility-only residue on this lane is now concentrated in the final identifier scan rather than in legacy wrapper API surface.

### Validation (latest slice)
- `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
- `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm` (pass)
- `prove -I perl t` (pass: 6 files, 125 tests)
### Newest AST/CoreAST convergence slice
- Narrowed the last live dependency compatibility fallback in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- The explicit runtime-AST-miss dependency path now:
  - attempts direct compatibility parsing through a dedicated recovery helper,
  - then tries one cleaned-expression AST recovery pass before the final identifier scan,
  - caches any cleaned-expression recovery back onto runtime-AST metadata so later live-path phases can reuse the AST-backed signal.
- Kept this slice behavior-safe:
  - cleaned-expression recovery preserves already-rendered expression text when the AST is recovered from a cleaned variant,
  - the identifier scan remains only as the final compatibility-only fallback when both raw and cleaned AST recovery still fail.

### Validation (newest slice)
- `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
- `prove -I perl t` (pass: 6 files, 125 tests)
### Latest AST/CoreAST convergence slice
- Moved cleaned-expression compatibility recovery earlier in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` so normal runtime-AST resolution can recover more signals before the dependency helper reaches its final identifier scan.
- The live consolidated path now:
  - attempts cleaned-expression parsing during `resolve_intermediate_signal_runtime_ast(...)` after a stored-expression parse miss,
  - records cleaned-expression recovery as runtime-AST metadata,
  - preserves the original stored expression text during rendering when the recovered AST came from a cleaned compatibility expression.
- This narrows the remaining final dependency fallback population:
  - more signals now arrive at dependency extraction with a real runtime AST already resolved,
  - the identifier scan remains only for the subset of signals that still fail both raw and cleaned runtime-AST recovery.

### Validation (latest slice)
- `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
- `prove -I perl t` (pass: 6 files, 125 tests)
### Newest AST/CoreAST convergence slice
- Narrowed the last explicit runtime-AST-miss dependency fallback by inserting an AST-first signal-name recovery step before the final identifier scan.
- `perl/FSM/Synthesis/EnableGraph.pm` now:
  - recognizes AST-generated intermediate signal names backed by factorizer/global-expression metadata,
  - builds a small dependency-recovery AST that preserves direct intermediate-signal operands instead of flattening them transitively,
  - returns that AST only when it recovers at least one direct intermediate dependency.
- `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` now uses that recovered AST before dropping to `scan_intermediate_signal_names_in_expression(...)`, so the remaining raw identifier scan is limited to legacy/non-AST-named hard misses.
- Added focused regression coverage in `t/07-runtime-ast-miss-dependency-recovery.t` for:
  - direct-dependency preservation through the new signal-name AST path,
  - legacy-source signals staying on the final identifier-scan fallback.

### Validation (newest slice)
- `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
- `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` (pass)
- `prove -I perl t` (pass: 7 files, 130 tests)
### Latest AST/CoreAST convergence slice
- Closed a CoreAST-native signal-definition gap that was still forcing some parser-created intermediates onto compatibility recovery paths.
- `perl/FSM/CoreAST.pm` now canonicalizes `driving_ast` through the real signal field even when older code writes it via `set_attribute('driving_ast', ...)`, so backend/native AST lookup sees the same defining AST the signal was created with.
- `perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm` and `perl/FSM/Adapter/FSMGenFull/Parser.pm` now write intermediate-signal defining ASTs through `set_driving_ast(...)` directly instead of storing them only in the attribute bag.
- Added focused regression coverage in `t/08-driving-ast-canonicalization.t` for:
  - canonical `driving_ast` storage through the CoreAST signal API,
  - factored parser/frontend intermediates keeping their defining AST natively,
  - backend runtime-AST recovery resolving those intermediates through the native defining-AST path.

### Validation (latest slice)
- `perl -I perl -c perl/FSM/CoreAST.pm` (pass)
- `perl -I perl -c perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm` (pass)
- `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm` (pass)
- `prove -I perl t` (pass: 8 files, 140 tests)
### Newest AST/CoreAST convergence slice
- Narrowed the remaining regex identifier scan again by extending the existing signal-name AST dependency recovery path to conservative `legacy_string_registry` names.
- `perl/FSM/Synthesis/EnableGraph.pm` now allows legacy registry entries onto the same structured signal-name AST recovery path already used for AST-generated names, instead of forcing all such names directly to regex scanning.
- This keeps the behavior narrow:
  - systematic legacy names like `not_mid_and_aux_legacy` can now recover dependencies through AST construction/traversal,
  - opaque legacy names still fall through to `scan_intermediate_signal_names_in_expression(...)`.
- Updated focused regression coverage in `t/07-runtime-ast-miss-dependency-recovery.t` for:
  - AST-generated signal-name recovery,
  - conservative legacy signal-name recovery,
  - opaque legacy names staying on the final identifier-scan fallback.

### Validation (newest slice)
- `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm` (pass)
- `prove -I perl t` (pass: 8 files, 143 tests)

### Validation (post-hardening + extraction)
- `prove -I perl t/04-assignment-edge-cases.t t/05-assignment-hdl-snapshots.t` (pass)
- `prove -I perl t` (full suite pass: 5 files, 117 tests)

## 2026-02-21
### Parser and expression handling
- Added parser support for compound update shorthand and inline modifiers:
  - `(++ sig)`, `(-- sig)`, `(+=K sig)`, `(-=K sig)`
  - Inline forms in assignments such as `(A <- B (+= 2))` and `(A = B (-= 1))`
- Fixed nested packed conditional parsing for forms encoded as:
  - `['<',  [cond, action1, ...]]`
  - `['<!', [cond, action1, ...]]`
- Improved expression parsing for packed recursive operands and scalar negation tokens (e.g. `!wren`).

### Backend behavior hardening
- Added explicit `generate_verilog()` path in `perl/FSM/HDL/FlattenedDT.pm` with SystemVerilog-to-Verilog conversion (`always_comb`→`always @*`, `always_ff` lowering).
- Added explicit `generate_vhdl()` method that fails with a clear not-implemented error instead of method-missing crashes.
- Fixed indexed-target handling in flattening paths where direct `->name` assumptions caused runtime failures.

### Combinational self-dependency safety rule (`=`)
- Enforced generalized rule: combinational assignment RHS must not depend (directly or transitively) on the same LHS.
- Implemented graph-based dependency tracking for `=` assignments in `perl/FSM/Adapter/FSMGenFull/Parser.pm`:
  - Record `LHS -> RHS signals` for each combinational assignment.
  - Detect cycles per LHS and reject with `Carp::confess`.
- Preserved synchronous legality: loopback forms like `(A <- A)` remain allowed.

### Tests
- Added focused regression file: `t/02-combinational-self-dependency.t`
  - Direct reject: `(A = A)`
  - Indirect reject: `(A = B)` + `(B = A)`
  - Positive allow: `(A <- A)`
- Validated with:
  - `prove -v t/02-combinational-self-dependency.t`
  - `prove -v t/01-regression.t` (20/20 pass).

### Documentation consolidation
- Consolidated and refreshed root docs (`README.md`, `CHANGES.md`, `DEVELOPMENT_NOTES.md`).
- Promoted and renamed user guide to `docs/USER_GUIDE.md`.
- Removed stale/duplicate investigation-era markdown files from `docs/`.

## 2025-08 (consolidated historical highlights)
- Fixed intermediate signal declaration/filtering defects in `FlattenedDT.pm`, including reference-aware and multi-registry dependency tracking.
- Fixed intermediate self-reference generation during multi-pass substitution.
- Fixed conditional transition suffix parsing (`<sig`, `<!sig`) for correct enable differentiation.
- Fixed operator selection and register feedback defaults for cleaner, synthesis-friendly RTL.
- Stabilized width inference behavior and parser/generator robustness across large FSM inputs.

## Earlier foundational changes
- Refactored monolithic FSM adapter flow into modular parser components (`SignalManager`, `ExpressionBuilder`, `Parser`, `SignalAnalyzer`).
- Standardized fatal error reporting with `Carp::confess`.
- Established baseline regression infrastructure (`t/01-regression.t`) and project self-containment.

## 2026-03-19
- Failed-run composition summaries now keep duplicate-driver target context for both explicit-link target families:
  - top-boundary duplicate drivers keep `Context: Top port '...'`
  - child-input duplicate drivers keep `Context: Child endpoint 'instance.port'`
- This is a reporting-contract hardening slice only:
  - planning behavior is unchanged,
  - the concise reason still names the earlier explicit link that already reserved the target.
- Failed-run composition summaries now also keep blocked explicit-link width-mismatch target context:
  - top-boundary width mismatches can summarize as `Context: Top port '...'`
  - child-target width mismatches can summarize as `Context: Child endpoint 'instance.port'`
- This slice includes a small extractor improvement in `perl/FSM/Pipeline/HDLGenerator.pm`; planning behavior is unchanged.
- The explicit-link width-mismatch summary contract is now regression-locked for both reachable target families:
  - child-target mismatches
  - top-boundary mismatches
- This follow-on slice is coverage/contract hardening only; runtime behavior is unchanged from the prior extractor improvement.
- Failed-run composition summaries now also keep source-endpoint context for the blocked explicit-link topology family where one resolved source tries to drive multiple top outputs.
- This slice includes a small extractor improvement in `perl/FSM/Pipeline/HDLGenerator.pm`; planner behavior is unchanged.
- Failed-run composition summaries now also keep top-port source context for the sibling blocked explicit-link topology family where a top input is wired directly to a top output.
- This follow-on slice is another small extractor improvement in `perl/FSM/Pipeline/HDLGenerator.pm`; planner behavior is unchanged.
- The missing-`?toplink` explicit-link lane-entry summary contract is now regression-locked too:
  - `Lane: C2`
  - `Construct: ?toplink`
  - blocked boundary + concise reason preserved
  - no fabricated `Context:` line
- This slice is coverage/contract hardening only; runtime behavior is unchanged.
- Failed-run duplicate-declaration summaries now also surface duplicate-name context instead of leaving it only in the raw exception text:
  - duplicate top-port declarations keep `Construct: ?ports` plus `Context: Top port '...'`
  - duplicate child-instance declarations keep `Context: Child '...'`
- This slice includes a small extractor improvement in `perl/FSM/Pipeline/HDLGenerator.pm`; planner behavior is unchanged.
- The explicit-link role-mismatch summary contract is now locked for the remaining sibling families too:
  - child-endpoint sources keep `Context: Child endpoint 'instance.port'` with the concise `input instead of output` reason
  - top-port targets keep `Context: Top port '...'` with the concise `input instead of output` reason
- This follow-on slice is regression/contract hardening only; runtime behavior was already covered by the existing summary extractor.
- The missing generated-child source-resolution summary contract is now locked for both construct families too:
  - unresolved `?fsmc` children keep `Construct: ?fsmc` plus `Context: Child '...'`
  - unresolved `?dtc` children keep `Construct: ?dtc` plus `Context: Child '...'`
  - both keep the blocked `child-source resolution` boundary and the concise missing-source reason without inventing a `Child source file:` artifact
- This follow-on slice is also regression/contract hardening only; runtime behavior was already covered by the existing summary extractor.
- The wrong-kind generated-child realization summary contract is now locked for both construct families too:
  - wrong-kind `?fsmc` resolutions keep `Construct: ?fsmc`, `Child source file`, and `Context: Child '...'`
  - wrong-kind `?dtc` resolutions keep `Construct: ?dtc`, `Child source file`, and `Context: Child '...'`
  - both keep the blocked `child-source realization` boundary and the concise wrong-kind reason
- This follow-on slice is again regression/contract hardening only; runtime behavior was already covered by the existing summary extractor.
- Failed-run parser-boundary summaries now also cover two construct-scoped families explicitly:
  - blocked `?ports` mapping directives keep `Construct: ?ports` plus `Context: Mapping directive '...'`
  - blocked malformed `?toplink` tokens keep `Construct: ?toplink` plus `Context: Token '...'`
  - both keep their existing blocked-boundary labels and concise parser reasons
- This slice includes a small extractor improvement in `perl/FSM/Pipeline/HDLGenerator.pm` for `?ports` mapping-directive context; parser behavior is unchanged.
- The remaining `?ports` token-family summaries are now locked too:
  - invalid explicit top-port tokens keep `Construct: ?ports` plus `Context: Token 'bad-name>8'`
  - non-positive width tokens keep `Construct: ?ports` plus `Context: Token 'data_in<0'`
  - both keep the blocked parser-boundary labels and the existing concise parser reasons
- This follow-on slice is regression/contract hardening only; runtime behavior was already covered by the existing summary extractor.
- Failed-run parser-boundary summaries now also keep named-child context for malformed generated-child declarations:
  - blocked `?fsmc` source-count failures keep `Construct: ?fsmc` plus `Context: Child 'child'`
  - blocked `?dtc` source-shape failures keep `Construct: ?dtc` plus `Context: Child 'child'`
  - both keep their existing blocked child-source boundary labels and concise parser reasons
- This slice includes a small extractor improvement in `perl/FSM/Pipeline/HDLGenerator.pm`; parser behavior is unchanged.
- Failed-run parser-boundary summaries now also keep construct context for malformed child item-list payloads when the raised diagnostic still names a real child header:
  - blocked dotted-pair payloads like `?fsmc:child` keep `Construct: ?fsmc`
  - they also keep `Context: Child '?fsmc:child'`
  - and preserve the blocked `child item-list shape` boundary plus the existing concise dotted-pair-contract reason
- This slice includes another small extractor improvement in `perl/FSM/Pipeline/HDLGenerator.pm`; parser behavior is unchanged.
- That same child-item parser-summary contract is now locked for the `?toplink` sibling too:
  - blocked dotted-pair payloads like `?toplink:wiring` keep `Construct: ?toplink`
  - they also keep `Context: Child '?toplink:wiring'`
  - and preserve the same blocked `child item-list shape` boundary plus the concise dotted-pair-contract reason
- This follow-on slice is regression/contract hardening only; runtime behavior was already covered by the existing summary extractor.
- That same child-item parser-summary contract is now locked for the `?ports` sibling too:
  - blocked dotted-pair payloads like `?ports` keep `Construct: ?ports`
  - they also keep `Context: Child '?ports'`
  - and preserve the same blocked `child item-list shape` boundary plus the concise dotted-pair-contract reason
- This follow-on slice is also regression/contract hardening only; runtime behavior was already covered by the existing summary extractor.
- That same child-item parser-summary contract is now locked for the `?dtc` sibling too:
  - blocked dotted-pair payloads like `?dtc:child` keep `Construct: ?dtc`
  - they also keep `Context: Child '?dtc:child'`
  - and preserve the same blocked `child item-list shape` boundary plus the concise dotted-pair-contract reason
- This follow-on slice is again regression/contract hardening only; runtime behavior was already covered by the existing summary extractor.
- That same child-item parser-summary contract is now locked for the `?rtl` sibling too:
  - blocked dotted-pair payloads like `?rtl:uart_tx` keep `Construct: ?rtl`
  - they also keep `Context: Child '?rtl:uart_tx'`
  - and preserve the same blocked `child item-list shape` boundary plus the concise dotted-pair-contract reason
- This follow-on slice is again regression/contract hardening only; runtime behavior was already covered by the existing summary extractor.
- Shared-datapath candidate metadata now also exposes one bounded assertion-planning layer on top of the already-shipped aggregate-enable and conflict-bit surface:
  - deterministic per-child source-enable aliases for each shared-value contributor family,
  - onehot0-style same-value assertion metadata over those source-enable aliases,
  - and onehot0-style whole-target assertion metadata over the aggregate value-enable families.
- Non-quiet `bin/fsmgen` composition runs now also print those planned multi-value and same-value onehot0 inputs under `Shared-Datapath Candidates`.
- Shared-datapath candidate metadata now also exposes the first lifted-ownership planning layer for registered peer-read families:
  - storage-class classification,
  - peer-read input endpoint metadata,
  - internal-by-default lifted visibility for registered peer-read families,
  - planned top re-export signals for those internalized public outputs,
  - and a bounded loopback-allowed flag.
- Non-quiet `bin/fsmgen` composition runs now also print those planned visibility/re-export/loopback decisions under `Shared-Datapath Candidates`.
- Logged a new long-term horizon direction in the roadmap:
  - a future HDL-to-`.fsm` lane should be treated as bounded HDL import / intent recovery rather than exact reverse compilation,
  - the most honest first target would be `fsmgen`-generated `SystemVerilog`,
  - and any later broader `SystemVerilog` / `VHDL` support should surface recognized structure, heuristic recovery, and unsupported residue explicitly.
- Refined that saved horizon direction further:
  - synthesizable RTL is now the explicit import boundary rather than arbitrary HDL,
  - richer composition hierarchy, generate-heavy RTL, and macro/preprocessor-heavy RTL are in scope as later widening targets rather than being ruled out,
  - parser support alone is explicitly not enough and the note now calls for preprocessing/elaboration plus a typed canonical RTL IR with provenance,
  - and the note now keeps one core honesty rule explicit: do not force weak HDL evidence into fake high-level elegance when residue reporting would be more truthful.
- Clarified the elaboration point in that same saved horizon note:
  - HDL import would not need a full backend compile/synthesis flow,
  - but it would still need substantial frontend semantic compilation work before elaboration can happen honestly,
  - so the saved pipeline is now explicit about preprocess -> parse -> semantic resolution -> elaboration -> canonical RTL IR -> intent recovery.
- Refined that same long-term HDL-import note again with the planned IR architecture:
  - forward compilation is now explicitly framed as `.fsm AST -> semantic Intent HIR -> lowered RTL IR -> backend emission`,
  - reverse recovery is now explicitly framed as `HDL CST/AST -> semantic HDL HIR -> elaborated RTL IR -> Flat IR -> recovered Intent IR -> .fsm + recovery report`,
  - the note now explicitly rejects the phrase “non-semantic HIR” for the reverse path because the non-semantic layer is just the parsed HDL tree,
  - and the saved architecture direction is now to share the semantic middle (`Intent HIR`, `Lowered RTL IR`, maybe `Flat IR`/provenance later) rather than building two unrelated semantic stacks.
- Started the first active forward IR extraction slice under `R11` instead of leaving forward IR work as horizon-only guidance:
  - added `FSM::IR::IntentHIR` as the first explicit forward semantic summary layer,
  - direct generated roots now expose serialized `intent_hir` in pipeline results,
  - realized generated children now preserve that same serialized intent summary through `module_info`,
  - and `HDLGenerator` now derives the compatible `module_info` semantic core from that extracted intent layer before later generated-analysis enrichment.
- Started the first active forward lowered IR extraction slice under `R11` on top of that intent layer:
  - added `FSM::IR::LoweredRTLIR` as the first explicit forward lowered summary layer,
  - direct generated roots now expose serialized `lowered_rtl_ir` in pipeline results,
  - realized generated children now preserve that same serialized lowered summary through `module_info`,
  - and selected composition/export consumers now prefer the extracted lowered surface when present so HDL emission and composition planning no longer rely only on ad hoc legacy fields for those normalized families.
- Widened those explicit forward IR layers one step further into a top-level composition export:
  - aggregated `composition_standalone_dt_children` entries now preserve each realized `?dtc` child's serialized `intent_hir`,
  - and those same reusable-child exports now also preserve each child's serialized `lowered_rtl_ir` instead of stripping the forward IR layers back off at the composition-top boundary.
  - that same reusable standalone-DT child export now also lives inside composition-top `intent_hir`, and the compatible top-level `module_info` surface mirrors it back out from that explicit semantic layer.
- Widened the same forward IR story into one broader generated-child composition export:
  - top-level `composition_generated_children` now covers realized `?fsmc` and `?dtc` children together,
  - those exported generated-child summaries preserve both serialized `intent_hir` and serialized `lowered_rtl_ir`,
  - and non-quiet `bin/fsmgen` runs now print one concise generated-child summary from that broader exported surface.
- Widened the same forward IR story into the shared-datapath candidate surface:
  - shared-datapath contributor entries now preserve both serialized `intent_hir` and serialized `lowered_rtl_ir`,
  - those same contributor entries now also preserve the exact selected `output_drive_family` from child `lowered_rtl_ir`,
  - and the existing bounded `drive_intent` summary is now derived from that extracted family instead of standing alone,
  - those contributor entries now also preserve stable generated-child identity through `kind` and `source_name`,
  - and non-quiet `bin/fsmgen` runs now print one concise contributor-context line before the existing shared-datapath drive-intent summary.
- Widened the same forward IR story through composition tops themselves:
  - direct `?top` generation results now expose serialized top-level `intent_hir` and serialized top-level `lowered_rtl_ir`,
  - that same composition-top `intent_hir` now also carries the broader generated-child export instead of leaving it only as a separate top-level compatibility summary,
  - those composition-top forward layers now carry bounded top-port / child-count / lane summaries on the intent side plus bounded internal-net / instance / auxiliary-assignment summaries and the shared-datapath candidate surface on the lowered side,
  - and composition `module_info` now mirrors those same serialized forward IR layers instead of leaving composition tops as the remaining explicit forward-IR gap.
- Widened the same forward IR story through the composition provenance/reporting surface:
  - `composition_report` resolved-link entries now preserve source/target endpoint context instead of only raw endpoint strings,
  - generated-child endpoint contexts now preserve bounded `intent_hir` / `lowered_rtl_ir` child summaries,
  - and top-port / resolved-link provenance kinds now keep one stable example subject so non-quiet CLI composition summaries are no longer counts-only in that area.
- Widened the same forward IR story through the composition override/block reporting surface:
  - override and block events now preserve structured top-port / child-endpoint context instead of only flat signal names,
  - generated-child endpoint contexts there now also preserve bounded `intent_hir` / `lowered_rtl_ir` child summaries,
  - and non-quiet `bin/fsmgen` runs now print richer link/endpoint examples in those sections instead of count-plus-name examples only.
- Started the first active forward structural/connectivity extraction slice under `R11`:
  - added `FSM::IR::StructuralRTLIR` as the first explicit AST/netlist-like connectivity layer,
  - direct `?top` composition results now expose serialized `structural_rtl_ir`,
  - composition-top `module_info` now mirrors that same structural surface,
  - and composition-top HDL emission now walks the extracted structural layer for explicit ports, nets, instances, pin bindings, and auxiliary assignments instead of re-reading only plan state during top-module dumping.
- Widened that structural extraction slice into direct generated roots and child exports:
  - direct generated `?fsm` / `?dt` results now expose a bounded structural module-interface slice through `structural_rtl_ir`,
  - and realized generated-child export surfaces now preserve that same child `structural_rtl_ir` beside `intent_hir` and `lowered_rtl_ir`.
- Started consuming that structural layer in realized-child planning too:
  - generated-child interface ports are now derived from `structural_rtl_ir` first instead of rebuilding only from signal analysis,
  - and the structural-to-interface handoff now normalizes low-level declaration types like `wire` / `logic` back to plain semantic data ports while preserving `clock` / `reset`.
- Started consuming that structural layer in composition-top lowered summaries too:
  - composition-top `lowered_rtl_ir` now derives internal-net names, realized-instance names, and auxiliary-assignment counts from `structural_rtl_ir` instead of rebuilding that bounded connectivity slice directly from the plan.
- Started consuming that structural layer in top-level composition accounting too:
  - composition-top `module_info` and `statistics` now derive child, top-port, and internal-net counts from `structural_rtl_ir` instead of rereading those bounded accounting fields directly from the plan.
- Started consuming that structural layer in composition provenance too:
  - `composition_report` now derives top-port metadata and resolved-link endpoint lookup from `structural_rtl_ir` instead of rereading those bounded boundary/interface details directly from the plan.
- Started consuming that structural layer in override/block reporting too:
  - composition override/block event grouping and candidate-context lookup now derive top-port and child-interface metadata from `structural_rtl_ir` instead of rereading those same interface families directly from the plan.
- Started consuming that structural layer in composition-top semantic summaries too:
  - composition-top `intent_hir` now derives top-port names, counts, and grouped input/output signal-analysis families from `structural_rtl_ir`,
  - and compatible top-level `module_info` signal metadata now mirrors that same structural top-port boundary instead of rebuilding it separately from the plan.
- Widened that structural layer through explicit resolved connectivity too:
  - composition-top `structural_rtl_ir` now preserves resolved links as first-class structural connectivity entries,
  - `composition_report` now derives its resolved-link identity/origin list from that structural layer instead of rereading plan-only link state,
  - and compatible top-level resolved-link counts now stay aligned with `structural_rtl_ir`.
- Started consuming that structural resolved-link layer in override/block reporting too:
  - override events now take explicit-toplink and inferred-reexport connectivity from `structural_rtl_ir->{resolved_links}`,
  - and kept-internal carrier block detection now also derives its family token from that same structural resolved-link surface instead of rereading resolved links directly from the plan.
- Widened the forward semantic layer through one unified composition child export:
  - composition-top `intent_hir` now carries `composition_child_count` plus `composition_children` across realized `?fsmc`, `?dtc`, and `?rtl` children,
  - compatible top-level `module_info` now mirrors that same unified child surface,
  - those child entries preserve stable identity plus child `intent_hir`, `lowered_rtl_ir`, and `structural_rtl_ir` summaries when present,
  - and composition provenance / override / block endpoint lookup now consumes that unified child semantic surface instead of rereading realized child identity only from plan instances.
- Narrowed one more composition export seam onto the explicit semantic layer:
  - the narrower `composition_generated_children` export now derives from the broader `composition_children` semantic surface,
  - so generated-child export identity is no longer rebuilt separately from plan instances,
  - while the existing generated-child forward IR surface remains stable.
- Lowered one more composition seam onto the explicit IR layers through shared-datapath candidate discovery:
  - shared-datapath candidate discovery now consumes `structural_rtl_ir` for top-output / child-interface connectivity,
  - contributor identity and lowered contributor context now come from the unified semantic `composition_children` export,
  - and the existing shared-datapath candidate surface remains stable while depending less on ad hoc plan crawling inside `HDLGenerator`.
- Logged the next forward-IR architecture refinement for future implementation:
  - the current extracted `Lowered RTL IR` is now explicitly treated as a lowered summary layer rather than the final full connectivity graph,
  - the forward compiler is now steered toward `Intent HIR -> Lowered RTL IR -> Structural RTL IR / Connectivity IR -> backend`,
  - and the eventual HDL backend boundary is expected to mostly walk that AST-like structural connectivity layer, with explicit ports/nets/instances/pin bindings and top/child wiring, instead of rediscovering that graph ad hoc during emission.
- Extracted another real composition-planning family out of `HDLGenerator`:
  - generic explicit-link linked-plan assembly for the active `C2`/`C3`/`C4`
    lanes now lives in `FSM::Composition::LinkedPlanBuilder`,
  - including system auto-wiring, endpoint resolution, role/width validation,
    deterministic carrier-net allocation, and realized-child rebinding.
- Extracted another real composition-planning family out of `HDLGenerator`:
  - inferred multi-child top-port projection now lives in
    `FSM::Composition::TopPortInferenceBuilder`,
  - including explicit-toplink top-port inference plus undeclared same-name
    top-input and top-output inference.
- Extracted another real composition-support family out of `HDLGenerator`:
  - shared-datapath naming, generated-child source-export metadata, assertion
    metadata/rendering, and runtime plan augmentation now live in
    `FSM::Composition::SharedDatapathSupport`.
- Extracted another real composition-reporting family out of `HDLGenerator`:
  - composition provenance report assembly, override/block event detection,
    endpoint-context projection, and provenance label/example helpers now
    live in `FSM::Composition::ProvenanceReportBuilder`.
- Extracted another real synthesis/backend family out of `EnableGraph`:
  - effective system-contract lookup, effective clock/reset lookup,
    state-register planning, module-boundary port planning, and internal
    signal declaration planning now live in
    `FSM::Synthesis::EnableGraph::ModulePlanningSupport`.
- Extracted the matching direct assignment/mux support family out of
  `EnableGraph`:
  - unified assignment-analysis construction, RHS grouping, mux-plan
    construction, driven-signal discovery, reset/default/width recovery, and
    delayed-pulse / flop / combinational assignment emission now live in
    `FSM::Synthesis::EnableGraph::AssignmentSupport`.
- Extracted the matching enable-family support out of `EnableGraph`:
  - top-level state/DT enable initialization, WEN/EN prescan tracking,
    top-level enable emission, and unified DT/LHS WEN/EN emission now live
    in `FSM::Synthesis::EnableGraph::EnableSupport`.
- Extracted the matching AST capture/conversion support out of `EnableGraph`:
  - condition-stack normalization, assignment/transition capture,
    test-selector conversion, capture-time RHS rendering, and AST
    signal-name extraction now live in
    `FSM::Synthesis::EnableGraph::CaptureSupport`.
- Extracted the matching AST rendering/classification support out of
  `EnableGraph`:
  - AST-to-SystemVerilog rendering, operand-width-aware logical-versus-
    bitwise operator selection, factorizable-operator discovery, and
    arithmetic/logical/factorization classification now live in
    `FSM::Synthesis::EnableGraph::ASTSupport`.
- Extracted the matching signal/intermediate support out of `EnableGraph`:
  - AST-based intermediate naming, reset/default lookup, direct
    intermediate-dependency extraction, signal/intermediate classification,
    backend-safe signal-name cleanup, and RHS-based enable naming now live in
    `FSM::Synthesis::EnableGraph::SignalSupport`.
- Shared-datapath candidate metadata now also makes the bounded combinational peer-read rule explicit: peer-read combinational families stay top-output-only, surface a block reason, and no longer look loopback-eligible in non-quiet `bin/fsmgen` summaries.
- Shared-datapath runtime behavior now exists in generated composition HDL, not just metadata: realized `?fsmc` children export hidden per-value enable families for composition use, and composition tops now synthesize aggregate-enable and conflict helper wires from those exports.
- Shared-datapath lifting now has its first actual ownership/runtime slice on top of that helper HDL:
  - shared registered peer-read families with explicit public re-exports now synthesize one lifted top-level shared register in the generated composition top,
  - peer-read child inputs are rebound to that lifted shared register,
  - explicit top outputs are re-exported from that lifted shared register instead of binding directly to one child output,
  - and non-quiet `bin/fsmgen` runs now print the active lifted-runtime signal/reset summary for that bounded case.
# 2026-03-23

- Widened `FSM::IR::StructuralRTLIR::ConnectionExpr` beyond plain `signal_ref`
  with bounded indexed and sliced connection-expression nodes, and taught the
  composition-top structural emitter to render those typed forms through the
  current Verilog-family backend instead of limiting the structural binding
  surface to unsliced signal references only.
- Widened `FSM::IR::StructuralRTLIR::ConnectionExpr` again with bounded
  concatenation support over nested structural operands, and locked that the
  composition-top structural emitter now walks those typed concat expressions
  directly through the current Verilog-family backend.
- Added recursive signal-discovery helpers for typed structural connection
  expressions, and moved composition system-signal detection plus
  shared-datapath contributor binding metadata onto that richer structural
  dependency surface instead of a flat mirrored signal-name assumption.
- Added bounded backend-neutral bit-vector literal actual-connection nodes to
  `FSM::IR::StructuralRTLIR::ConnectionExpr`, and locked that the composition
  structural emitter now walks those literal bindings directly through the
  current Verilog-family backend.
