# `bin/fsmgen` Import Tree Analysis

This is a live architecture note.

Use it to keep one current, high-signal picture of:
- what [bin/fsmgen](bin/fsmgen) actually does,
- which project-owned packages sit in its transitive import tree,
- what the real runtime spine is,
- and where the current architectural hotspots still are.

Refresh this document at the start of a later session whenever the effective entrypoint/import-tree architecture has moved enough that this note is no longer honest.

Current baseline:
- Reviewed on `2026-05-15`.
- Startup bootstrap refreshed on `2026-05-15`; the live static trace still
  includes the R14 `.isf` intent-scheduling path and the selected line-count
  measurements below were refreshed from source.
- Scope is the project-owned transitive `FSM::...` tree reachable from [bin/fsmgen](bin/fsmgen).
- Perl core and non-project helper modules are treated as support dependencies, not as part of the architectural map.
- Static trace from [bin/fsmgen](bin/fsmgen) currently reaches `195` project files total, `194` `.pm` packages.
- The R14 `.isf` front door is reachable from [bin/fsmgen](bin/fsmgen)
  through conditional runtime requires of [perl/FSM/Adapter/ISF.pm](perl/FSM/Adapter/ISF.pm)
  and [perl/FSM/Scheduler/ISF.pm](perl/FSM/Scheduler/ISF.pm). That path lowers
  `.isf` actors into scheduled `.fsm` text, optionally emits schedule JSON, and
  then hands the scheduled `.fsm` source to the existing direct/composition
  pipeline.
- The former composition-local parameter/generic helper is now a compatibility shim; the active neutral owner is [perl/FSM/ParameterValueSupport.pm](perl/FSM/ParameterValueSupport.pm), including bounded scalar expressions and matching-shape leafwise aggregate expression folding.
- Shared integer literal parsing is now reachable through [perl/FSM/Package/IntegerLiteralSupport.pm](perl/FSM/Package/IntegerLiteralSupport.pm), keeping common decimal, `0d`, based SystemVerilog, `0x`, `0b`, `0o`, and intent-level sized `.fsm` spellings such as `5'23`, `8'-10`, `8'-0xA`, `8'-0b1010`, and `20'x1` consistent across scalar widths, constants, and direct `+size` expression terms while normalizing to legal target-HDL literals before backend emission.
- The top-level manifest owner [perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm) is now intentionally thin: it is a small assembler over dedicated top-level public section builders in [perl/FSM/Support/ProducerSection.pm](perl/FSM/Support/ProducerSection.pm), [perl/FSM/Support/SupportAccountingSection.pm](perl/FSM/Support/SupportAccountingSection.pm), [perl/FSM/Support/DiagnosticsSection.pm](perl/FSM/Support/DiagnosticsSection.pm), [perl/FSM/Support/SemanticExportsSection.pm](perl/FSM/Support/SemanticExportsSection.pm), [perl/FSM/Support/BackendValidationSection.pm](perl/FSM/Support/BackendValidationSection.pm), [perl/FSM/Support/EmbeddingSection.pm](perl/FSM/Support/EmbeddingSection.pm), [perl/FSM/Support/LanguageSurfaceSection.pm](perl/FSM/Support/LanguageSurfaceSection.pm), and [perl/FSM/Support/DocumentationSection.pm](perl/FSM/Support/DocumentationSection.pm), while [perl/FSM/Support/CapabilityManifestContract.pm](perl/FSM/Support/CapabilityManifestContract.pm) continues to own the bounded manifest shell and grouped discovery tables.
- The machine-readable support/API surface is now reachable through [perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm), which builds `bin/fsmgen --capability-manifest` JSON from [perl/FSM/Support/RegressionCorpus.pm](perl/FSM/Support/RegressionCorpus.pm), the bounded top-level manifest shell contract in [perl/FSM/Support/CapabilityManifestContract.pm](perl/FSM/Support/CapabilityManifestContract.pm), the bounded manifest-facing `embedding` section contract in [perl/FSM/Support/EmbeddingContract.pm](perl/FSM/Support/EmbeddingContract.pm), the bounded manifest-facing `diagnostics` section contract in [perl/FSM/Support/DiagnosticsContract.pm](perl/FSM/Support/DiagnosticsContract.pm), the bounded manifest-facing `producer` section contract in [perl/FSM/Support/ProducerContract.pm](perl/FSM/Support/ProducerContract.pm), the bounded manifest-facing `semantic_exports` section contract in [perl/FSM/Support/SemanticExportsContract.pm](perl/FSM/Support/SemanticExportsContract.pm), the bounded manifest-facing `backend_validation` section contract in [perl/FSM/Support/BackendValidationContract.pm](perl/FSM/Support/BackendValidationContract.pm), the bounded manifest-facing `documentation` section contract in [perl/FSM/Support/DocumentationContract.pm](perl/FSM/Support/DocumentationContract.pm), the bounded manifest-facing `language_surface` section contract in [perl/FSM/Support/LanguageSurfaceContract.pm](perl/FSM/Support/LanguageSurfaceContract.pm), the stable diagnostic-code registry in [perl/FSM/Support/DiagnosticCodes.pm](perl/FSM/Support/DiagnosticCodes.pm), the bounded manifest-facing diagnostic-code registry contract in [perl/FSM/Support/DiagnosticCodeRegistryContract.pm](perl/FSM/Support/DiagnosticCodeRegistryContract.pm), the bounded support-accounting contract in [perl/FSM/Support/SupportAccountingContract.pm](perl/FSM/Support/SupportAccountingContract.pm), the bounded shared support-accounting match-object contract in [perl/FSM/Support/SupportAccountingMatchContract.pm](perl/FSM/Support/SupportAccountingMatchContract.pm), the bounded shared public report-producer object contract in [perl/FSM/Support/ReportProducerContract.pm](perl/FSM/Support/ReportProducerContract.pm), the bounded shared public report-source object contract in [perl/FSM/Support/ReportSourceContract.pm](perl/FSM/Support/ReportSourceContract.pm), the bounded shared public report-command object contract in [perl/FSM/Support/ReportCommandContract.pm](perl/FSM/Support/ReportCommandContract.pm), the bounded shared public report-generated-output object contract in [perl/FSM/Support/ReportGeneratedOutputContract.pm](perl/FSM/Support/ReportGeneratedOutputContract.pm), the bounded check-JSON report builder in [perl/FSM/Support/CheckDiagnostics.pm](perl/FSM/Support/CheckDiagnostics.pm), the bounded check-JSON key-presence contract in [perl/FSM/Support/CheckDiagnosticsContract.pm](perl/FSM/Support/CheckDiagnosticsContract.pm), the bounded shared public failure-diagnostic object contract in [perl/FSM/Support/CheckFailureDiagnosticContract.pm](perl/FSM/Support/CheckFailureDiagnosticContract.pm), the bounded check-JSON success-result object contract in [perl/FSM/Support/CheckResultContract.pm](perl/FSM/Support/CheckResultContract.pm), the bounded normalized semantic report builder in [perl/FSM/Support/NormalizedSemanticReport.pm](perl/FSM/Support/NormalizedSemanticReport.pm), the bounded normalized semantic composition-summary object contract in [perl/FSM/Support/NormalizedSemanticCompositionContract.pm](perl/FSM/Support/NormalizedSemanticCompositionContract.pm), the bounded normalized semantic explicit-system-contract object contract in [perl/FSM/Support/NormalizedSemanticExplicitSystemContract.pm](perl/FSM/Support/NormalizedSemanticExplicitSystemContract.pm), the bounded normalized semantic forward-IR object contract in [perl/FSM/Support/NormalizedSemanticForwardIRContract.pm](perl/FSM/Support/NormalizedSemanticForwardIRContract.pm), the bounded normalized semantic lowered-RTL object contract in [perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm](perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm), the bounded normalized semantic intent-hir object contract in [perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm](perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm), the bounded normalized semantic module-summary object contract in [perl/FSM/Support/NormalizedSemanticModuleContract.pm](perl/FSM/Support/NormalizedSemanticModuleContract.pm), the bounded normalized semantic signal-analysis object contract in [perl/FSM/Support/NormalizedSemanticSignalAnalysisContract.pm](perl/FSM/Support/NormalizedSemanticSignalAnalysisContract.pm), the bounded normalized semantic system-contract object contract in [perl/FSM/Support/NormalizedSemanticSystemContract.pm](perl/FSM/Support/NormalizedSemanticSystemContract.pm), the bounded normalized semantic symbol-contract object contract in [perl/FSM/Support/NormalizedSemanticSymbolContract.pm](perl/FSM/Support/NormalizedSemanticSymbolContract.pm), the bounded normalized semantic success-payload object contract in [perl/FSM/Support/NormalizedSemanticPayloadContract.pm](perl/FSM/Support/NormalizedSemanticPayloadContract.pm), the bounded normalized semantic key-presence contract in [perl/FSM/Support/NormalizedSemanticReportContract.pm](perl/FSM/Support/NormalizedSemanticReportContract.pm), the optional external HDL validation lane in [perl/FSM/Support/HDLExternalValidation.pm](perl/FSM/Support/HDLExternalValidation.pm), the bounded external validation contract in [perl/FSM/Support/HDLExternalValidationContract.pm](perl/FSM/Support/HDLExternalValidationContract.pm), the bounded sanitized composition-report contract in [perl/FSM/Support/CompositionReportContract.pm](perl/FSM/Support/CompositionReportContract.pm), the bounded typed-extension/context contract in [perl/FSM/Support/ExtensionContract.pm](perl/FSM/Support/ExtensionContract.pm), the bounded nested `HDLGenerator` `source_info` contract in [perl/FSM/Support/HDLGeneratorSourceInfoContract.pm](perl/FSM/Support/HDLGeneratorSourceInfoContract.pm), the bounded nested `HDLGenerator` `module_info` contract in [perl/FSM/Support/HDLGeneratorModuleInfoContract.pm](perl/FSM/Support/HDLGeneratorModuleInfoContract.pm), the bounded nested `HDLGenerator` `statistics` contract in [perl/FSM/Support/HDLGeneratorStatisticsContract.pm](perl/FSM/Support/HDLGeneratorStatisticsContract.pm), the bounded shell-only `HDLGenerator` `composition_plan` contract in [perl/FSM/Support/HDLGeneratorCompositionPlanContract.pm](perl/FSM/Support/HDLGeneratorCompositionPlanContract.pm), the bounded shell-only `HDLGenerator` `composition_spec` contract in [perl/FSM/Support/HDLGeneratorCompositionSpecContract.pm](perl/FSM/Support/HDLGeneratorCompositionSpecContract.pm), the bounded shell-only `HDLGenerator` `fsm_module` contract in [perl/FSM/Support/HDLGeneratorFSMModuleContract.pm](perl/FSM/Support/HDLGeneratorFSMModuleContract.pm), the bounded shell-only `HDLGenerator` `raw_ast` contract in [perl/FSM/Support/HDLGeneratorRawASTContract.pm](perl/FSM/Support/HDLGeneratorRawASTContract.pm), the bounded shell-only `HDLGenerator` `resolved_package_imports` contract in [perl/FSM/Support/HDLGeneratorResolvedPackageImportsContract.pm](perl/FSM/Support/HDLGeneratorResolvedPackageImportsContract.pm), and the bounded in-process `HDLGenerator` result contract in [perl/FSM/Support/HDLGeneratorResultContract.pm](perl/FSM/Support/HDLGeneratorResultContract.pm).
- The bounded in-process `HDLGenerator` result contract now also makes both halves of the compatibility seam explicit: `fsm_module`, `raw_ast`, `resolved_package_imports`, `composition_spec`, `composition_plan`, and raw `composition_report` are compatibility shells/artifacts for in-process Perl embedders, `source_info`, `module_info`, and `statistics` advertise bounded stable subsurfaces rather than whole-hash promises, `source_info`, `module_info`, and `statistics` now each advertise their own nested-object contract owner, `composition_plan`, `composition_spec`, `fsm_module`, `raw_ast`, and `resolved_package_imports` now also each advertise their own shell-only contract owner, and the top-level `intent_hir` / `lowered_rtl_ir` / `structural_rtl_ir` hashes are explicitly treated as reused normalized-semantic shell contracts rather than separately stabilized full trees; structured downstream consumers should stay on those advertised semantic/summary paths or the sanitized `semantic_exports.normalized_semantic_json.semantic.composition.provenance_report` fragment advertised through [perl/FSM/Support/CompositionReportContract.pm](perl/FSM/Support/CompositionReportContract.pm).
- That same machine-readable support/API surface now also includes the bounded normalized semantic structural-RTL object contract in [perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm](perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm).
- The embedding-facing support/API surface now also includes the bounded in-process debug-runtime child contract in [perl/FSM/Support/DebugRuntimeContract.pm](perl/FSM/Support/DebugRuntimeContract.pm) and the bounded public `HDLGenerator` facade child contract in [perl/FSM/Support/HDLGeneratorFacadeContract.pm](perl/FSM/Support/HDLGeneratorFacadeContract.pm), advertised as `embedding.debug_runtime` and `embedding.hdl_generator_facade`.
- The latest support/API surface also reaches the serializable plan/report
  snapshot family in
  [perl/FSM/Support/SerializablePlanReportContract.pm](perl/FSM/Support/SerializablePlanReportContract.pm),
  [perl/FSM/Support/SerializableCompositionPlanSnapshot.pm](perl/FSM/Support/SerializableCompositionPlanSnapshot.pm),
  [perl/FSM/Support/SerializableGenerationResultSnapshot.pm](perl/FSM/Support/SerializableGenerationResultSnapshot.pm),
  and [perl/FSM/Support/SerializableDiagnosticSummary.pm](perl/FSM/Support/SerializableDiagnosticSummary.pm).
  These owners keep embedders on bounded JSON-safe summaries instead of raw
  pipeline objects.

## Executive read
[bin/fsmgen](bin/fsmgen) is a thin CLI/reporting shell plus the R14 `.isf`
pre-lowering front door.
[perl/FSM/Pipeline/HDLGenerator.pm](perl/FSM/Pipeline/HDLGenerator.pm)
is now down to the honest facade role we wanted: shared pipeline
configuration plus the single top-level `generate_hdl_from_file(...)`
entrypoint.

The real coordinator gravity is now the orchestrator family beneath it:
- [perl/FSM/Pipeline/SourceGenerationOrchestrator.pm](perl/FSM/Pipeline/SourceGenerationOrchestrator.pm)
- [perl/FSM/Pipeline/DirectGenerationOrchestrator.pm](perl/FSM/Pipeline/DirectGenerationOrchestrator.pm)
- [perl/FSM/Composition/GenerationOrchestrator.pm](perl/FSM/Composition/GenerationOrchestrator.pm)

For `.isf` inputs, [bin/fsmgen](bin/fsmgen) first asks
[perl/FSM/Adapter/ISF.pm](perl/FSM/Adapter/ISF.pm) and
[perl/FSM/Scheduler/ISF.pm](perl/FSM/Scheduler/ISF.pm) to parse, lower, and
optionally report the schedule before the ordinary `.fsm` pipeline sees the
generated source.

The best current architecture in the tree is the newer composition/forward-IR/backend-emitter slice:
- [perl/FSM/IR/IntentHIR.pm](perl/FSM/IR/IntentHIR.pm)
- [perl/FSM/IR/IntentHIRBuilder.pm](perl/FSM/IR/IntentHIRBuilder.pm)
- [perl/FSM/IR/LoweredRTLIR.pm](perl/FSM/IR/LoweredRTLIR.pm)
- [perl/FSM/IR/LoweredRTLIRBuilder.pm](perl/FSM/IR/LoweredRTLIRBuilder.pm)
- [perl/FSM/IR/StructuralRTLIR.pm](perl/FSM/IR/StructuralRTLIR.pm)
- [perl/FSM/IR/StructuralRTLIRBuilder.pm](perl/FSM/IR/StructuralRTLIRBuilder.pm)
- [perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm](perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm)

The most visible growth since the previous snapshot is the semantic package /
type support family beneath [perl/FSM/Package/](perl/FSM/Package). That growth is intentional: reusable named values,
package imports, scalar/list/record type aliases, aggregate paths, and
aggregate expression contracts now have explicit owners instead of being
parser-local string rules.

The visible `R11` composition cleanup since the previous snapshot is the new
[perl/FSM/Composition/ActualLiteralSupport.pm](perl/FSM/Composition/ActualLiteralSupport.pm) owner for open/numeric actual parsing, concat-operand intrinsic-width literal lowering, target-width widening, and actual binding type contracts. That moved roughly one thousand lines of literal-specific policy out of [perl/FSM/Composition/LinkedPlanBuilder.pm](perl/FSM/Composition/LinkedPlanBuilder.pm) while preserving the planner's explicit-link role and diagnostic ownership.
The follow-on `R11` source-expression cleanup is the new
[perl/FSM/Composition/SourceExpressionSpecSupport.pm](perl/FSM/Composition/SourceExpressionSpecSupport.pm)
owner for bounded explicit-wiring source-expression specs: top/child bit and
slice forms, aggregate paths, concat groups, repeat groups, literal operands,
top-symbol payload lookup, and inference/child-base collection now live below
the planner too.
The newest shared scalar-width slice keeps
[perl/FSM/Package/IntegerLiteralSupport.pm](perl/FSM/Package/IntegerLiteralSupport.pm)
as the common integer-literal parser for scalar width symbols and direct
`+size` expression terms. It also owns the target-HDL normalization rule for
intent-level `.fsm` sized literals so parser/CoreAST/pure-AST rendering do not
leak source-only spellings such as `2'3` or `20'x1` into generated SV.
The newest parameter/generic semantic-value slice keeps
[perl/FSM/ParameterValueSupport.pm](perl/FSM/ParameterValueSupport.pm)
as the scalar/aggregate literal, bounded scalar-expression, and matching-shape
leafwise aggregate-expression owner for direct `+params`, `.rtlif` defaults, external
`?rtl` overrides, and generated `?fsmc` / `?dtc` overrides, keeping that value
policy out of both the parser and backend emitter.
A composition symbolic parameter override slice uses
[perl/FSM/Composition/ParameterOverrideResolver.pm](perl/FSM/Composition/ParameterOverrideResolver.pm)
as the post-import owner that resolves deferred child parameter/generic override
values through composition-top and imported-package symbols before planning or
backend emission.
The newest direct-backend coordination slice keeps
[perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStageSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStageSupport.pm)
as the live consolidated-intermediate stage handoff over prescan preparation,
prepared-block reconstruction, pre-generation operand-contract validation, and rendering, so
[perl/FSM/HDL/FlattenedDT/Orchestrator.pm](perl/FSM/HDL/FlattenedDT/Orchestrator.pm)
no longer coordinates prepared-block internals directly.
The newest post-flattening assembly slice keeps
[perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/PostFlatteningAssemblySupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/PostFlatteningAssemblySupport.pm)
as the live owner of direct SystemVerilog scaffold/declaration/enable/stage/tail
assembly after decision-tree flattening, so
[perl/FSM/HDL/FlattenedDT/Orchestrator.pm](perl/FSM/HDL/FlattenedDT/Orchestrator.pm)
now stops at reset, module attachment, flattening, and final assembly handoff.
It now also documents the subtle but deliberate ordering contract inside that
assembly owner: the consolidated intermediate stage is prepared before internal
declarations so prescan/factorization-discovered helpers are visible to the
declaration pass, while the rendered stage text is still emitted after enable
conditions in the final HDL.
The newest downstream-tool support slice adds
[perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm)
plus [perl/FSM/Support/CapabilityManifestContract.pm](perl/FSM/Support/CapabilityManifestContract.pm)
plus [perl/FSM/Support/EmbeddingContract.pm](perl/FSM/Support/EmbeddingContract.pm)
plus [perl/FSM/Support/DiagnosticsContract.pm](perl/FSM/Support/DiagnosticsContract.pm)
plus [perl/FSM/Support/DocumentationContract.pm](perl/FSM/Support/DocumentationContract.pm)
plus [perl/FSM/Support/LanguageSurfaceContract.pm](perl/FSM/Support/LanguageSurfaceContract.pm)
plus [perl/FSM/Support/ProducerContract.pm](perl/FSM/Support/ProducerContract.pm)
plus [perl/FSM/Support/SemanticExportsContract.pm](perl/FSM/Support/SemanticExportsContract.pm)
plus [perl/FSM/Support/BackendValidationContract.pm](perl/FSM/Support/BackendValidationContract.pm)
plus [perl/FSM/Support/CheckDiagnostics.pm](perl/FSM/Support/CheckDiagnostics.pm)
plus [perl/FSM/Support/CheckDiagnosticsContract.pm](perl/FSM/Support/CheckDiagnosticsContract.pm)
plus [perl/FSM/Support/CompositionReportContract.pm](perl/FSM/Support/CompositionReportContract.pm)
plus [perl/FSM/Support/DiagnosticCodes.pm](perl/FSM/Support/DiagnosticCodes.pm)
plus [perl/FSM/Support/DiagnosticCodeRegistryContract.pm](perl/FSM/Support/DiagnosticCodeRegistryContract.pm)
plus [perl/FSM/Support/ExtensionContract.pm](perl/FSM/Support/ExtensionContract.pm)
plus [perl/FSM/Support/HDLGeneratorResultContract.pm](perl/FSM/Support/HDLGeneratorResultContract.pm)
plus [perl/FSM/Support/HDLExternalValidation.pm](perl/FSM/Support/HDLExternalValidation.pm)
plus [perl/FSM/Support/HDLExternalValidationContract.pm](perl/FSM/Support/HDLExternalValidationContract.pm)
plus [perl/FSM/Support/SupportAccountingContract.pm](perl/FSM/Support/SupportAccountingContract.pm)
plus [perl/FSM/Support/SupportAccountingMatchContract.pm](perl/FSM/Support/SupportAccountingMatchContract.pm)
plus [perl/FSM/Support/ReportProducerContract.pm](perl/FSM/Support/ReportProducerContract.pm)
plus [perl/FSM/Support/ReportSourceContract.pm](perl/FSM/Support/ReportSourceContract.pm)
plus [perl/FSM/Support/ReportCommandContract.pm](perl/FSM/Support/ReportCommandContract.pm)
plus [perl/FSM/Support/ReportGeneratedOutputContract.pm](perl/FSM/Support/ReportGeneratedOutputContract.pm)
plus [perl/FSM/Support/CheckFailureDiagnosticContract.pm](perl/FSM/Support/CheckFailureDiagnosticContract.pm)
plus [perl/FSM/Support/CheckResultContract.pm](perl/FSM/Support/CheckResultContract.pm)
plus [perl/FSM/Support/NormalizedSemanticCompositionContract.pm](perl/FSM/Support/NormalizedSemanticCompositionContract.pm)
plus [perl/FSM/Support/NormalizedSemanticForwardIRContract.pm](perl/FSM/Support/NormalizedSemanticForwardIRContract.pm)
plus [perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm](perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm)
plus [perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm](perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm)
plus [perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm](perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm)
plus [perl/FSM/Support/NormalizedSemanticModuleContract.pm](perl/FSM/Support/NormalizedSemanticModuleContract.pm)
plus [perl/FSM/Support/NormalizedSemanticSymbolContract.pm](perl/FSM/Support/NormalizedSemanticSymbolContract.pm)
plus [perl/FSM/Support/NormalizedSemanticReport.pm](perl/FSM/Support/NormalizedSemanticReport.pm)
plus [perl/FSM/Support/NormalizedSemanticPayloadContract.pm](perl/FSM/Support/NormalizedSemanticPayloadContract.pm)
plus [perl/FSM/Support/NormalizedSemanticReportContract.pm](perl/FSM/Support/NormalizedSemanticReportContract.pm)
and [perl/FSM/Support/RegressionCorpus.pm](perl/FSM/Support/RegressionCorpus.pm)
as the live owners for schema-versioned capability JSON plus its explicit top-level shell contract and bounded embedding/diagnostics/producer/semantic-exports/backend-validation/documentation/language-surface section contracts, bounded check-JSON
reports plus their explicit key-presence contract, support accounting plus its explicit contract, optional external validation plus its explicit contract, bounded sanitized composition-report contracts, stable diagnostic-code
metadata plus its explicit manifest-facing registry contract, bounded typed-extension/context contracts, bounded `HDLGenerator`
result contracts plus their nested identity-key slices, bounded source/module/statistics summary slices, an explicitly raw shell-only resolved-package-import branch, and advertised top-level semantic-layer shells, shared support-accounting match-object contracts, shared public report-producer object contracts, shared public report-source object contracts, shared public report-command object contracts, shared public report-generated-output object contracts, explicit check-success result object contracts, explicit normalized-semantic success-payload object contracts, optional Verilator/Yosys generated-SystemVerilog validation,
explicit normalized-semantic forward-IR and symbol-contract object contracts, bounded normalized semantic JSON plus its explicit key-presence contract, and production
support-accounting data. The manifest now also advertises the bounded
support-accounting owner through `support_accounting.section_contract`, so that
section follows the same nested contract-discovery seam as the other public
manifest sections. The check-JSON support surface is now corpus-covered on both sides:
supported-smoke / strict-supported entries must produce clean success JSON with
matched success support-accounting data, ad-hoc successes must report unmatched
support accounting, and expected-failure entries must produce the exact stable
code/support-accounting contract. The semantic JSON surface now projects
module/root, system/reset, sanitized signal-analysis, and forward-IR metadata
without leaking private Perl objects or HDL text, and every current
supported-smoke / strict-supported entry must now produce clean semantic JSON
with matched support-accounting data and no HDL emission. Every current
expected-failure entry must now produce clean semantic failure JSON with the
exact stable code/support-accounting contract, no HDL emission, and no partial
semantic payload. This deliberately keeps the public manifest, diagnostic
reports, and semantic reports out of the test-only `t/lib` tree while leaving a
thin test compatibility wrapper behind. The raw in-process `HDLGenerator`
result is now covered as a bounded top-level presence contract, typed
extensions now have a bounded hook/context contract, and composition
provenance now has a sanitized semantic-JSON report fragment, but the raw
result is explicitly not advertised as a JSON-safe document because nested
compatibility payloads can still carry live CoreAST/AST objects. The external
validation support surface is intentionally post-emission and SystemVerilog-only:
it runs Verilator lint and ABC-free Yosys structural synthesis when those tools
are installed, while leaving VHDL/GHDL validation behind the future VHDL
backend and leaving ABC-specific timeout/mapping behavior for a later lane.

The heaviest remaining complexity is still the direct single-module HDL backend path centered on:
- [perl/FSM/Backend/GeneratedModuleEmitter.pm](perl/FSM/Backend/GeneratedModuleEmitter.pm)
- [perl/FSM/HDL/FlattenedDT.pm](perl/FSM/HDL/FlattenedDT.pm)
- [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](perl/FSM/HDL/FlattenedDT/Orchestrator.pm)
- [perl/FSM/HDL/FlattenedDT/DecisionTreeFlatteningSupport.pm](perl/FSM/HDL/FlattenedDT/DecisionTreeFlatteningSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPrescanPreparationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPrescanPreparationSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationTailSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationTailSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/PostFlatteningAssemblySupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/PostFlatteningAssemblySupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GlobalFactorizationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GlobalFactorizationSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ASTFactorizationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ASTFactorizationSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalRecoverySupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalRecoverySupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalFilterPolicySupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalFilterPolicySupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateNormalizationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateNormalizationSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateClassificationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateClassificationSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSelectionSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSelectionSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateDependencySupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateDependencySupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePlanningSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePlanningSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePreparedBlockSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePreparedBlockSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStagePreparationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStagePreparationSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStageSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStageSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateRenderingSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateRenderingSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateAssignmentSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateAssignmentSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateDeclarationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateDeclarationSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/InternalDeclarationEmitter.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/InternalDeclarationEmitter.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ScaffoldEmitter.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ScaffoldEmitter.pm)
- [perl/FSM/HDL/Factorization/Fixpoint.pm](perl/FSM/HDL/Factorization/Fixpoint.pm)
- [perl/FSM/HDL/Factorization/Fixpoint/LoopStateSupport.pm](perl/FSM/HDL/Factorization/Fixpoint/LoopStateSupport.pm)
- [perl/FSM/HDL/Factorization/Fixpoint/PassExecutionSupport.pm](perl/FSM/HDL/Factorization/Fixpoint/PassExecutionSupport.pm)
- [perl/FSM/HDL/Factorization/Fixpoint/PassSupport.pm](perl/FSM/HDL/Factorization/Fixpoint/PassSupport.pm)
- [perl/FSM/Synthesis/EnableGraph.pm](perl/FSM/Synthesis/EnableGraph.pm)
- [perl/FSM/Synthesis/EnableGraph/AssignmentSupport.pm](perl/FSM/Synthesis/EnableGraph/AssignmentSupport.pm)
- [perl/FSM/Synthesis/EnableGraph/ASTSupport.pm](perl/FSM/Synthesis/EnableGraph/ASTSupport.pm)
- [perl/FSM/Synthesis/EnableGraph/CaptureSupport.pm](perl/FSM/Synthesis/EnableGraph/CaptureSupport.pm)
- [perl/FSM/Synthesis/EnableGraph/EnableSupport.pm](perl/FSM/Synthesis/EnableGraph/EnableSupport.pm)
- [perl/FSM/Synthesis/EnableGraph/FactorizationPolicySupport.pm](perl/FSM/Synthesis/EnableGraph/FactorizationPolicySupport.pm)
- [perl/FSM/Synthesis/EnableGraph/FactorizationSupport.pm](perl/FSM/Synthesis/EnableGraph/FactorizationSupport.pm)
- [perl/FSM/Synthesis/EnableGraph/IntermediateSignalSupport.pm](perl/FSM/Synthesis/EnableGraph/IntermediateSignalSupport.pm)
- [perl/FSM/Synthesis/EnableGraph/ModulePlanningSupport.pm](perl/FSM/Synthesis/EnableGraph/ModulePlanningSupport.pm)
- [perl/FSM/Synthesis/EnableGraph/SignalSupport.pm](perl/FSM/Synthesis/EnableGraph/SignalSupport.pm)

## Measured snapshot
This is the current static measurement view behind the qualitative assessment
above.

Reachable package-family counts from [bin/fsmgen](bin/fsmgen):
- total reachable project files: `195`
- reachable `.pm` packages: `194`
- `Support`: `65`
- `Composition`: `35`
- `HDL`: `32`
- `Package`: `14`
- `Synthesis`: `10`
- `Adapter`: `8`
- `IR`: `7`
- `Pipeline`: `5`
- `Scheduler`: `5`
- `Backend`: `3`
- `Extension`: `3`
- `AST`: `1`
- singleton support surfaces: `CoreAST.pm`, `Debug.pm`, `ExpressionNamer.pm`, `ParameterValueSupport.pm`, `SourceClassifier.pm`, `SourcePathResolver.pm`

Current thin-coordinator / public-surface assembler line counts:
- [bin/fsmgen](bin/fsmgen): `1097`
- [perl/FSM/Pipeline/HDLGenerator.pm](perl/FSM/Pipeline/HDLGenerator.pm): `418`
- [perl/FSM/Pipeline/SourceGenerationOrchestrator.pm](perl/FSM/Pipeline/SourceGenerationOrchestrator.pm): `175`
- [perl/FSM/Pipeline/DirectGenerationOrchestrator.pm](perl/FSM/Pipeline/DirectGenerationOrchestrator.pm): `117`
- [perl/FSM/Composition/GenerationOrchestrator.pm](perl/FSM/Composition/GenerationOrchestrator.pm): `172`
- [perl/FSM/HDL/FlattenedDT.pm](perl/FSM/HDL/FlattenedDT.pm): `172`
- [perl/FSM/Adapter/ISF.pm](perl/FSM/Adapter/ISF.pm): `50`
- [perl/FSM/Adapter/ISF/Parser.pm](perl/FSM/Adapter/ISF/Parser.pm): `1669`
- [perl/FSM/Adapter/ISF/LispishAdapter.pm](perl/FSM/Adapter/ISF/LispishAdapter.pm): `99`
- [perl/FSM/Scheduler/ISF.pm](perl/FSM/Scheduler/ISF.pm): `58`
- [perl/FSM/Scheduler/ISF/LoweringIR.pm](perl/FSM/Scheduler/ISF/LoweringIR.pm): `5471`
- [perl/FSM/Scheduler/ISF/Emitter/FSM.pm](perl/FSM/Scheduler/ISF/Emitter/FSM.pm): `428`
- [perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm](perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm): `137`
- [perl/FSM/Scheduler/ISF/Emitter/JSON.pm](perl/FSM/Scheduler/ISF/Emitter/JSON.pm): `623`
- [perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm): `34`
- [perl/FSM/Support/CapabilityManifestContract.pm](perl/FSM/Support/CapabilityManifestContract.pm): `265`
- [perl/FSM/Support/ProducerSection.pm](perl/FSM/Support/ProducerSection.pm): `62`
- [perl/FSM/Support/SupportAccountingSection.pm](perl/FSM/Support/SupportAccountingSection.pm): `94`
- [perl/FSM/Support/DiagnosticsSection.pm](perl/FSM/Support/DiagnosticsSection.pm): `49`
- [perl/FSM/Support/SemanticExportsSection.pm](perl/FSM/Support/SemanticExportsSection.pm): `36`
- [perl/FSM/Support/BackendValidationSection.pm](perl/FSM/Support/BackendValidationSection.pm): `30`
- [perl/FSM/Support/EmbeddingSection.pm](perl/FSM/Support/EmbeddingSection.pm): `32`
- [perl/FSM/Support/LanguageSurfaceSection.pm](perl/FSM/Support/LanguageSurfaceSection.pm): `88`
- [perl/FSM/Support/DocumentationSection.pm](perl/FSM/Support/DocumentationSection.pm): `28`
- [perl/FSM/Support/DebugRuntimeContract.pm](perl/FSM/Support/DebugRuntimeContract.pm): `184`
- [perl/FSM/Support/HDLGeneratorFacadeContract.pm](perl/FSM/Support/HDLGeneratorFacadeContract.pm): `223`
- [perl/FSM/Support/CheckDiagnostics.pm](perl/FSM/Support/CheckDiagnostics.pm): `266`
- [perl/FSM/Support/NormalizedSemanticReport.pm](perl/FSM/Support/NormalizedSemanticReport.pm): `383`

Current largest reachable files by line count:
- [perl/FSM/Scheduler/ISF/LoweringIR.pm](perl/FSM/Scheduler/ISF/LoweringIR.pm): `5471`
- [perl/FSM/Adapter/FSMGenFull/Parser.pm](perl/FSM/Adapter/FSMGenFull/Parser.pm): `3530`
- [perl/FSM/CoreAST.pm](perl/FSM/CoreAST.pm): `2429`
- [perl/FSM/Composition/LinkedPlanBuilder.pm](perl/FSM/Composition/LinkedPlanBuilder.pm): `1827`
- [perl/FSM/Composition/Parser.pm](perl/FSM/Composition/Parser.pm): `1674`
- [perl/FSM/Adapter/ISF/Parser.pm](perl/FSM/Adapter/ISF/Parser.pm): `1669`
- [perl/FSM/Synthesis/EnableGraph/AssignmentSupport.pm](perl/FSM/Synthesis/EnableGraph/AssignmentSupport.pm): `1471`
- [perl/FSM/Support/ISFPublicInterfaceContract.pm](perl/FSM/Support/ISFPublicInterfaceContract.pm): `1464`
- [perl/FSM/ExpressionNamer.pm](perl/FSM/ExpressionNamer.pm): `1443`
- [perl/FSM/Composition/TopPortInferenceBuilder.pm](perl/FSM/Composition/TopPortInferenceBuilder.pm): `1301`
- [perl/FSM/HDL/ASTFactorization.pm](perl/FSM/HDL/ASTFactorization.pm): `1219`
- [perl/FSM/Composition/ActualLiteralSupport.pm](perl/FSM/Composition/ActualLiteralSupport.pm): `1191`
- [bin/fsmgen](bin/fsmgen): `1097`
- [perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm](perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm): `990`
- [perl/FSM/Composition/ProvenanceReportBuilder.pm](perl/FSM/Composition/ProvenanceReportBuilder.pm): `937`

Interpretation:
- line count alone is not the same thing as current architectural risk,
- the R14 ISF runtime-lowering owner
  [perl/FSM/Scheduler/ISF/LoweringIR.pm](perl/FSM/Scheduler/ISF/LoweringIR.pm)
  is now the largest reachable file by a wide margin after the recent
  transaction, library, composition, storage, and dynamic-wait expansion work,
- the older direct parser/core AST/expression infrastructure is still large:
  [perl/FSM/Adapter/FSMGenFull/Parser.pm](perl/FSM/Adapter/FSMGenFull/Parser.pm)
  and [perl/FSM/CoreAST.pm](perl/FSM/CoreAST.pm) remain major shared owners
  after recent direct `+size`, canonical init/default, and canonical
  assignment-pair language widening,
- [perl/FSM/Composition/LinkedPlanBuilder.pm](perl/FSM/Composition/LinkedPlanBuilder.pm) remains a major `R11` planning hotspot because source-expression resolution, aggregate shape checks, carrier allocation, and binding-type preservation still meet there, but open/numeric actual literal policy now has an explicit owner in [perl/FSM/Composition/ActualLiteralSupport.pm](perl/FSM/Composition/ActualLiteralSupport.pm), source-expression parsing/spec collection now has an explicit owner in [perl/FSM/Composition/SourceExpressionSpecSupport.pm](perl/FSM/Composition/SourceExpressionSpecSupport.pm), parameter/generic scalar plus aggregate value normalization and bounded expression folding now has an explicit neutral owner in [perl/FSM/ParameterValueSupport.pm](perl/FSM/ParameterValueSupport.pm), and child override-value symbol resolution now has a post-import owner in [perl/FSM/Composition/ParameterOverrideResolver.pm](perl/FSM/Composition/ParameterOverrideResolver.pm),
- [perl/FSM/Pipeline/SourceFrontend.pm](perl/FSM/Pipeline/SourceFrontend.pm) is now a real mid-sized owner in its own right rather than a facade wrapper, which is a healthier failure mode than leaving the same frontend mass hidden inside `HDLGenerator`,
- the active `R11` change-risk gravity is still the direct backend stack plus
  the package/type layer and a few large composition builders, not the thinned
  top-level pipeline facade.
- the next honest seams are no longer the raw recursive flattening cluster in
  `Orchestrator`, the whole post-flattening SystemVerilog assembly sequence,
  the older generation-pipeline compatibility shell, the older
  generation-prelude compatibility shell, the older generation-structural-prelude
  compatibility shell, the older generation-enable-preparation compatibility shell,
  or the extracted
  post-stage WEN/EN/assignment/endmodule sequence now owned by
  `GenerationTailSupport`,
- the remaining seams are now lower-level direct-backend planning/stage/tail
  coordination after the stage handoff absorbed prescan preparation and operand-contract validation,
  plus broader convergence in the older `FlattenedDT` path.

## What `bin/fsmgen` actually owns
[bin/fsmgen](bin/fsmgen) directly imports:
- [perl/FSM/Composition/FailureReportBuilder.pm](perl/FSM/Composition/FailureReportBuilder.pm)
- [perl/FSM/Composition/ProvenanceReportBuilder.pm](perl/FSM/Composition/ProvenanceReportBuilder.pm)
- [perl/FSM/Debug.pm](perl/FSM/Debug.pm)
- [perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm](perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm)
- [perl/FSM/Pipeline/HDLGenerator.pm](perl/FSM/Pipeline/HDLGenerator.pm)
- [perl/FSM/SourcePathResolver.pm](perl/FSM/SourcePathResolver.pm)
- [perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm)
- [perl/FSM/Support/CheckDiagnostics.pm](perl/FSM/Support/CheckDiagnostics.pm)
- [perl/FSM/Support/HDLExternalValidation.pm](perl/FSM/Support/HDLExternalValidation.pm)
- [perl/FSM/Support/NormalizedSemanticReport.pm](perl/FSM/Support/NormalizedSemanticReport.pm)

For `.isf` inputs, [bin/fsmgen](bin/fsmgen) also conditionally requires:
- [perl/FSM/Adapter/ISF.pm](perl/FSM/Adapter/ISF.pm)
- [perl/FSM/Scheduler/ISF.pm](perl/FSM/Scheduler/ISF.pm)

It mainly owns:
- CLI option parsing
- source-file lookup
- `.isf` input detection, schedule-report exit, temporary scheduled `.fsm`
  handoff, and multi-file scheduled `.fsm` output routing
- debug/trace routing
- output-file writing
- capability-manifest JSON emission
- check-JSON lifecycle routing
- semantic-JSON lifecycle routing
- external HDL validation lifecycle routing
- user-facing summaries for composition provenance, override/block events, failure summaries, generated children, and shared-datapath metadata

[bin/fsmgen](bin/fsmgen) is `1097` lines today, so it is not tiny, but most of
that weight is presentation/reporting and `.isf` pre-lowering glue rather than
semantic compiler ownership.

It does not own the compiler architecture.
Its only non-trivial local logic is presentation/reporting glue.

## Runtime spine
Normal execution is best understood as one optional `.isf` pre-spine feeding two
sibling `.fsm` spines under the same CLI and top-level facade.

```text
ISF pre-spine
bin/fsmgen
  -> FSM::SourcePathResolver
  -> FSM::Adapter::ISF
     -> FSM::Adapter::ISF::Parser
     -> FSM::Adapter::ISF::LispishAdapter
  -> FSM::Scheduler::ISF
     -> FSM::Scheduler::ISF::LoweringIR
     -> FSM::Scheduler::ISF::Emitter::FSM
     -> FSM::Scheduler::ISF::Emitter::JSON
  -> scheduled .fsm source
  -> Direct-root spine below, unless --emit-schedule-json exits earlier

Direct-root spine
bin/fsmgen
  -> FSM::SourcePathResolver
  -> FSM::Pipeline::HDLGenerator->generate_hdl_from_file
  -> FSM::Pipeline::SourceGenerationOrchestrator
     -> FSM::Pipeline::SourceFrontend
     -> parse_fsm_file
     -> classify_source_ast
     -> FSM::Pipeline::DirectGenerationOrchestrator
     -> FSM::Pipeline::SourceFrontend
     -> FSM::Adapter::FSMGenFull
     -> FSM::Package::* declaration, import, payload, aggregate-path, and aggregate-expression support
     -> FSM::ParameterValueSupport parameter/generic semantic value normalization
     -> FSM::IR::IntentHIRBuilder
     -> FSM::Pipeline::GeneratedModuleInfoBuilder
        -> FSM::Backend::GeneratedModuleEmitter
     -> FSM::HDL::FlattenedDT
        -> FlattenedDT::Orchestrator
        -> FlattenedDT::DecisionTreeFlatteningSupport
        -> Synthesis::EnableGraph
        -> Synthesis::EnableGraph::AssignmentSupport
        -> Synthesis::EnableGraph::ASTSupport
        -> Synthesis::EnableGraph::CaptureSupport
        -> Synthesis::EnableGraph::EnableSupport
        -> Synthesis::EnableGraph::FactorizationPolicySupport
        -> Synthesis::EnableGraph::FactorizationSupport
        -> Synthesis::EnableGraph::IntermediateSignalSupport
        -> Synthesis::EnableGraph::ModulePlanningSupport
        -> Synthesis::EnableGraph::SignalSupport
        -> FlattenedDT::Backend::SystemVerilog::GlobalFactorizationSupport
        -> FlattenedDT::Backend::SystemVerilog::ASTFactorizationSupport
        -> FlattenedDT::Backend::SystemVerilog::ScaffoldEmitter
        -> FlattenedDT::Backend::SystemVerilog::InternalDeclarationEmitter
        -> FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport
        -> FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport
        -> FlattenedDT::Backend::SystemVerilog::IntermediateSignalFilterPolicySupport
        -> FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport
        -> FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport
        -> FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateClassificationSupport
        -> FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSelectionSupport
        -> FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateDependencySupport
        -> FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediatePlanningSupport
        -> FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediatePreparedBlockSupport
        -> FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateStagePreparationSupport
        -> FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateRenderingSupport
        -> FlattenedDT::Backend::SystemVerilog::GenerationPrescanPreparationSupport
        -> FlattenedDT::Backend::SystemVerilog::GenerationTailSupport
        -> FlattenedDT::Backend::SystemVerilog::PostFlatteningAssemblySupport
        -> FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateAssignmentSupport
        -> FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateDeclarationSupport
        -> HDL::Factorization::Fixpoint
        -> HDL::Factorization::Fixpoint::LoopStateSupport
        -> HDL::Factorization::Fixpoint::PassExecutionSupport
        -> HDL::Factorization::Fixpoint::PassSupport
        -> FlattenedDT::Backend::Verilog
     -> FSM::IR::StructuralRTLIRBuilder

Composition spine
bin/fsmgen
  -> FSM::SourcePathResolver
  -> FSM::Pipeline::HDLGenerator->generate_hdl_from_file
  -> FSM::Pipeline::SourceGenerationOrchestrator
     -> FSM::Pipeline::SourceFrontend
     -> parse_fsm_file
     -> classify_source_ast
     -> parse_composition_source
     -> FSM::Package::* plus FSM::ParameterValueSupport plus FSM::Composition::PackageImportResolver
        -> FSM::Composition::ParameterOverrideResolver
     -> FSM::Composition::GenerationOrchestrator
     -> FSM::Composition::PlanBuilder
     -> generated-child realization / external RTL child realization / RTL interface loading
     -> composition plan building / composition builders
     -> FSM::IR::StructuralRTLIRBuilder
     -> FSM::Composition::ChildExportBuilder
     -> FSM::IR::IntentHIRBuilder
     -> FSM::Composition::ProvenanceReportBuilder
     -> FSM::IR::LoweredRTLIRBuilder
     -> FSM::Backend::VerilogFamily::StructuralRTLIREmitter
     -> FSM::Composition::ResultMetadataBuilder
```

Important distinction:
- the direct single-module path still relies on the older `FlattenedDT`/`EnableGraph` backend family
- the composition path already uses the newer structural-emitter split more honestly

## Static import tree grouped by responsibility
### CLI and source routing
- [bin/fsmgen](bin/fsmgen)
- [perl/FSM/Debug.pm](perl/FSM/Debug.pm)
- [perl/FSM/SourcePathResolver.pm](perl/FSM/SourcePathResolver.pm)
- [perl/FSM/SourceClassifier.pm](perl/FSM/SourceClassifier.pm)

### ISF intent-scheduling pre-lowering
- [perl/FSM/Adapter/ISF.pm](perl/FSM/Adapter/ISF.pm)
- [perl/FSM/Adapter/ISF/Parser.pm](perl/FSM/Adapter/ISF/Parser.pm)
- [perl/FSM/Adapter/ISF/LispishAdapter.pm](perl/FSM/Adapter/ISF/LispishAdapter.pm)
- [perl/FSM/Scheduler/ISF.pm](perl/FSM/Scheduler/ISF.pm)
- [perl/FSM/Scheduler/ISF/LoweringIR.pm](perl/FSM/Scheduler/ISF/LoweringIR.pm)
- [perl/FSM/Scheduler/ISF/Emitter/FSM.pm](perl/FSM/Scheduler/ISF/Emitter/FSM.pm)
- [perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm](perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm)
- [perl/FSM/Scheduler/ISF/Emitter/JSON.pm](perl/FSM/Scheduler/ISF/Emitter/JSON.pm)

This R14 layer is intentionally before the main `HDLGenerator` facade: it turns
intent-scheduled `.isf` sources into explicit `.fsm` artifacts or a schedule
JSON report. The generated `.fsm` then uses the ordinary direct-root pipeline,
so `.isf` does not create a second HDL backend path.

### Support accounting, capability manifest, semantic reports, and external HDL validation
- [perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm)
- [perl/FSM/Support/CapabilityManifestContract.pm](perl/FSM/Support/CapabilityManifestContract.pm)
- [perl/FSM/Support/ProducerSection.pm](perl/FSM/Support/ProducerSection.pm)
- [perl/FSM/Support/SupportAccountingSection.pm](perl/FSM/Support/SupportAccountingSection.pm)
- [perl/FSM/Support/DiagnosticsSection.pm](perl/FSM/Support/DiagnosticsSection.pm)
- [perl/FSM/Support/SemanticExportsSection.pm](perl/FSM/Support/SemanticExportsSection.pm)
- [perl/FSM/Support/BackendValidationSection.pm](perl/FSM/Support/BackendValidationSection.pm)
- [perl/FSM/Support/EmbeddingSection.pm](perl/FSM/Support/EmbeddingSection.pm)
- [perl/FSM/Support/LanguageSurfaceSection.pm](perl/FSM/Support/LanguageSurfaceSection.pm)
- [perl/FSM/Support/DocumentationSection.pm](perl/FSM/Support/DocumentationSection.pm)
- [perl/FSM/Support/EmbeddingContract.pm](perl/FSM/Support/EmbeddingContract.pm)
- [perl/FSM/Support/DiagnosticsContract.pm](perl/FSM/Support/DiagnosticsContract.pm)
- [perl/FSM/Support/DocumentationContract.pm](perl/FSM/Support/DocumentationContract.pm)
- [perl/FSM/Support/LanguageSurfaceContract.pm](perl/FSM/Support/LanguageSurfaceContract.pm)
- [perl/FSM/Support/ProducerContract.pm](perl/FSM/Support/ProducerContract.pm)
- [perl/FSM/Support/SemanticExportsContract.pm](perl/FSM/Support/SemanticExportsContract.pm)
- [perl/FSM/Support/BackendValidationContract.pm](perl/FSM/Support/BackendValidationContract.pm)
- [perl/FSM/Support/CheckDiagnostics.pm](perl/FSM/Support/CheckDiagnostics.pm)
- [perl/FSM/Support/CheckDiagnosticsContract.pm](perl/FSM/Support/CheckDiagnosticsContract.pm)
- [perl/FSM/Support/CompositionReportContract.pm](perl/FSM/Support/CompositionReportContract.pm)
- [perl/FSM/Support/DiagnosticCodes.pm](perl/FSM/Support/DiagnosticCodes.pm)
- [perl/FSM/Support/DiagnosticCodeRegistryContract.pm](perl/FSM/Support/DiagnosticCodeRegistryContract.pm)
- [perl/FSM/Support/DebugRuntimeContract.pm](perl/FSM/Support/DebugRuntimeContract.pm)
- [perl/FSM/Support/ExtensionContract.pm](perl/FSM/Support/ExtensionContract.pm)
- [perl/FSM/Support/HDLGeneratorCompositionPlanContract.pm](perl/FSM/Support/HDLGeneratorCompositionPlanContract.pm)
- [perl/FSM/Support/HDLGeneratorCompositionSpecContract.pm](perl/FSM/Support/HDLGeneratorCompositionSpecContract.pm)
- [perl/FSM/Support/HDLGeneratorFacadeContract.pm](perl/FSM/Support/HDLGeneratorFacadeContract.pm)
- [perl/FSM/Support/HDLGeneratorFSMModuleContract.pm](perl/FSM/Support/HDLGeneratorFSMModuleContract.pm)
- [perl/FSM/Support/HDLGeneratorRawASTContract.pm](perl/FSM/Support/HDLGeneratorRawASTContract.pm)
- [perl/FSM/Support/HDLGeneratorResultContract.pm](perl/FSM/Support/HDLGeneratorResultContract.pm)
- [perl/FSM/Support/HDLExternalValidation.pm](perl/FSM/Support/HDLExternalValidation.pm)
- [perl/FSM/Support/HDLExternalValidationContract.pm](perl/FSM/Support/HDLExternalValidationContract.pm)
- [perl/FSM/Support/SupportAccountingContract.pm](perl/FSM/Support/SupportAccountingContract.pm)
- [perl/FSM/Support/SupportAccountingMatchContract.pm](perl/FSM/Support/SupportAccountingMatchContract.pm)
- [perl/FSM/Support/ReportProducerContract.pm](perl/FSM/Support/ReportProducerContract.pm)
- [perl/FSM/Support/ReportSourceContract.pm](perl/FSM/Support/ReportSourceContract.pm)
- [perl/FSM/Support/ReportCommandContract.pm](perl/FSM/Support/ReportCommandContract.pm)
- [perl/FSM/Support/ReportGeneratedOutputContract.pm](perl/FSM/Support/ReportGeneratedOutputContract.pm)
- [perl/FSM/Support/CheckFailureDiagnosticContract.pm](perl/FSM/Support/CheckFailureDiagnosticContract.pm)
- [perl/FSM/Support/CheckResultContract.pm](perl/FSM/Support/CheckResultContract.pm)
- [perl/FSM/Support/NormalizedSemanticCompositionContract.pm](perl/FSM/Support/NormalizedSemanticCompositionContract.pm)
- [perl/FSM/Support/NormalizedSemanticForwardIRContract.pm](perl/FSM/Support/NormalizedSemanticForwardIRContract.pm)
- [perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm](perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm)
- [perl/FSM/Support/NormalizedSemanticModuleContract.pm](perl/FSM/Support/NormalizedSemanticModuleContract.pm)
- [perl/FSM/Support/NormalizedSemanticSymbolContract.pm](perl/FSM/Support/NormalizedSemanticSymbolContract.pm)
- [perl/FSM/Support/NormalizedSemanticPayloadContract.pm](perl/FSM/Support/NormalizedSemanticPayloadContract.pm)
- [perl/FSM/Support/NormalizedSemanticReport.pm](perl/FSM/Support/NormalizedSemanticReport.pm)
- [perl/FSM/Support/NormalizedSemanticReportContract.pm](perl/FSM/Support/NormalizedSemanticReportContract.pm)
- [perl/FSM/Support/SerializableCompositionPlanSnapshot.pm](perl/FSM/Support/SerializableCompositionPlanSnapshot.pm)
- [perl/FSM/Support/SerializableDiagnosticSummary.pm](perl/FSM/Support/SerializableDiagnosticSummary.pm)
- [perl/FSM/Support/SerializableGenerationResultSnapshot.pm](perl/FSM/Support/SerializableGenerationResultSnapshot.pm)
- [perl/FSM/Support/SerializablePlanReportContract.pm](perl/FSM/Support/SerializablePlanReportContract.pm)
- [perl/FSM/Support/RegressionCorpus.pm](perl/FSM/Support/RegressionCorpus.pm)

This layer owns the first machine-readable downstream-tool support surface.
The CLI now reaches it through one thin top-level manifest assembler plus
dedicated top-level public section builders, while the regression tests use the
same production corpus owner instead of keeping the catalog in test-only code
and expected-failure machine identities come from the production
diagnostic-code registry instead of human CLI wording. The same layer now owns
the bounded `documentation` and `language_surface` section contracts, the
bounded `--check --json` report shape, the bounded `--emit-semantic-json`
report shape, the bounded sanitized composition-report contract, the bounded
typed-extension/context contract, the bounded debug-runtime and
`HDLGenerator` facade child contracts, the bounded `HDLGenerator` result
contract, and JSON-safe serializable plan/report snapshots, so downstream
tools get machine-readable success/failure diagnostics, a sanitized semantic
projection, and explicit embedding boundaries without depending on private
pipeline objects.

### Main orchestration hub
- [perl/FSM/Pipeline/HDLGenerator.pm](perl/FSM/Pipeline/HDLGenerator.pm)
- [perl/FSM/Pipeline/DirectGenerationOrchestrator.pm](perl/FSM/Pipeline/DirectGenerationOrchestrator.pm)
- [perl/FSM/Pipeline/SourceGenerationOrchestrator.pm](perl/FSM/Pipeline/SourceGenerationOrchestrator.pm)

This is still the architectural hub family, but it is no longer fair to say
that `HDLGenerator` itself owns the center of that logic.
The orchestrator family currently coordinates:
- source dispatch
- direct-root orchestration
- composition orchestration
- forward IR construction
- module-info/statistics assembly
- backend coordination
- extension callbacks

The important improvement is that [HDLGenerator.pm](perl/FSM/Pipeline/HDLGenerator.pm)
no longer owns the top-level file/source dispatch cluster inline:
[SourceGenerationOrchestrator.pm](perl/FSM/Pipeline/SourceGenerationOrchestrator.pm)
now owns parsed file dispatch into the direct-root or composition path plus the
surrounding extension-hook/finalization flow.
[HDLGenerator.pm](perl/FSM/Pipeline/HDLGenerator.pm)
also no longer owns the full direct-root result-assembly cluster inline:
[DirectGenerationOrchestrator.pm](perl/FSM/Pipeline/DirectGenerationOrchestrator.pm)
now owns that bounded non-composition source-to-result path.
It also no longer owns the old composition failure/provenance label helper
residue that the CLI can ask the dedicated builder packages for directly.
It also no longer owns the old direct generated-module helper residue for
direct-root intent/lowered/structural builders, generated-module metadata
helpers, direct backend glue, or statistics seed access. Those callers now ask
the explicit owner packages directly. The remaining frontend wrapper residue is
gone too, leaving `HDLGenerator` with just:
- shared pipeline configuration/state
- `generate_hdl_from_file(...)`

### Source frontend owner
- [perl/FSM/Pipeline/SourceFrontend.pm](perl/FSM/Pipeline/SourceFrontend.pm)

This package now owns the bounded source-frontend family that was still inline
in `HDLGenerator`. It handles:
- Lispish file parsing into raw AST
- top-level source-kind classification
- typed composition-spec parsing
- semantic FSM/DT module creation through `FSMGenFull`

`SourceGenerationOrchestrator`, `DirectGenerationOrchestrator`,
`GenerationOrchestrator`, and `GeneratedChildRealizer` now depend on this
owner directly instead of asking the `HDLGenerator` facade to keep those
frontend details inline.

### Direct generated-module backend owner
- [perl/FSM/Backend/GeneratedModuleEmitter.pm](perl/FSM/Backend/GeneratedModuleEmitter.pm)

This is the new bounded direct backend owner for generated FSM/DT modules.
It now owns:
- backend-method selection
- direct HDL emission through the older `FlattenedDT` family
- backend statistics collection
- standalone-DT assertion postprocessing

It serves both direct roots and realized generated children.
It is a real extraction, but not the final backend end-state yet:
underneath it, the older `FlattenedDT` / `EnableGraph` backend family still
remains the deeper complexity hotspot.

### Generated module module_info owner
- [perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm](perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm)

This package now owns the bounded generated-module compatibility
`module_info` family used by direct roots and realized generated children. It
handles:
- semantic-module compatibility summary building from one intent HIR
- lowered generated-analysis enrichment
- normalized query helpers over output-drive families and grouped standalone-DT targets

This is still a compatibility/result surface, not one of the three forward IR
layers, but it is now an explicit owner instead of one more inline cluster in
`HDLGenerator`.

### Single-module semantic frontend
- [perl/FSM/Adapter/FSMGenFull.pm](perl/FSM/Adapter/FSMGenFull.pm)
- [perl/FSM/Adapter/FSMGenFull/Parser.pm](perl/FSM/Adapter/FSMGenFull/Parser.pm)
- [perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm](perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm)
- [perl/FSM/Adapter/FSMGenFull/SignalManager.pm](perl/FSM/Adapter/FSMGenFull/SignalManager.pm)
- [perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm](perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm)
- [perl/FSM/CoreAST.pm](perl/FSM/CoreAST.pm)

This layer turns Lispish/raw AST into a semantic module.
The parser is strict about current source-root contracts and rejects unsupported tagged top-level forms explicitly.

### Semantic package, symbol, type, and aggregate support
- [perl/FSM/Package/AggregateExpressionTypeSupport.pm](perl/FSM/Package/AggregateExpressionTypeSupport.pm)
- [perl/FSM/Package/AggregatePathSupport.pm](perl/FSM/Package/AggregatePathSupport.pm)
- [perl/FSM/Package/DeclarativeSymbolResolver.pm](perl/FSM/Package/DeclarativeSymbolResolver.pm)
- [perl/FSM/Package/DeclarativeTypeResolver.pm](perl/FSM/Package/DeclarativeTypeResolver.pm)
- [perl/FSM/Package/DeclarativeTypeSupport.pm](perl/FSM/Package/DeclarativeTypeSupport.pm)
- [perl/FSM/Package/ImportResolver.pm](perl/FSM/Package/ImportResolver.pm)
- [perl/FSM/Package/IntegerLiteralSupport.pm](perl/FSM/Package/IntegerLiteralSupport.pm)
- [perl/FSM/Package/Parser.pm](perl/FSM/Package/Parser.pm)
- [perl/FSM/Package/PayloadLiteralSupport.pm](perl/FSM/Package/PayloadLiteralSupport.pm)
- [perl/FSM/Package/PayloadTypeSupport.pm](perl/FSM/Package/PayloadTypeSupport.pm)
- [perl/FSM/Package/ScalarWidthSupport.pm](perl/FSM/Package/ScalarWidthSupport.pm)
- [perl/FSM/Package/SignalManagerProjectionSupport.pm](perl/FSM/Package/SignalManagerProjectionSupport.pm)
- [perl/FSM/Package/Spec.pm](perl/FSM/Package/Spec.pm)
- [perl/FSM/Package/Symbols.pm](perl/FSM/Package/Symbols.pm)

This is the shared intent-level declaration layer for bounded `?pkg:name`,
`+constants`, `+enums`, `+types`, `+import`, scalar width reuse, aggregate
literal lowering, aggregate path traversal, and CoreAST aggregate expression
type-shape inference. It is now part of the live [bin/fsmgen](bin/fsmgen)
import spine through both the direct parser and composition import/binding
paths, so future work should treat package/type behavior as shared semantic
infrastructure rather than parser-local syntax sugar.

### Composition parsing and typed value model
- [perl/FSM/Composition/Parser.pm](perl/FSM/Composition/Parser.pm)
- [perl/FSM/Composition/Spec.pm](perl/FSM/Composition/Spec.pm)
- [perl/FSM/Composition/Top.pm](perl/FSM/Composition/Top.pm)
- [perl/FSM/Composition/Instance.pm](perl/FSM/Composition/Instance.pm)
- [perl/FSM/Composition/Port.pm](perl/FSM/Composition/Port.pm)
- [perl/FSM/Composition/Link.pm](perl/FSM/Composition/Link.pm)
- [perl/FSM/Composition/WiringBlock.pm](perl/FSM/Composition/WiringBlock.pm)
- [perl/FSM/Composition/PortsBlock.pm](perl/FSM/Composition/PortsBlock.pm)
- [perl/FSM/Composition/Net.pm](perl/FSM/Composition/Net.pm)
- [perl/FSM/Composition/Plan.pm](perl/FSM/Composition/Plan.pm)
- [perl/FSM/Composition/RealizedInstance.pm](perl/FSM/Composition/RealizedInstance.pm)
- [perl/FSM/Composition/TopSymbols.pm](perl/FSM/Composition/TopSymbols.pm)
- [perl/FSM/Composition/PortWidthResolver.pm](perl/FSM/Composition/PortWidthResolver.pm)

This is a typed composition frontend, not loose ad hoc parsing.
It is one of the cleaner parts of the tree.

### Composition builders and support owners
- [perl/FSM/Composition/C1PlanBuilder.pm](perl/FSM/Composition/C1PlanBuilder.pm)
- [perl/FSM/Composition/ChildExportBuilder.pm](perl/FSM/Composition/ChildExportBuilder.pm)
- [perl/FSM/Composition/DeclaredByNameLinkBuilder.pm](perl/FSM/Composition/DeclaredByNameLinkBuilder.pm)
- [perl/FSM/Composition/GeneratedChildRealizer.pm](perl/FSM/Composition/GeneratedChildRealizer.pm)
- [perl/FSM/Composition/PlanBuilder.pm](perl/FSM/Composition/PlanBuilder.pm)
- [perl/FSM/Composition/RTLChildRealizer.pm](perl/FSM/Composition/RTLChildRealizer.pm)
- [perl/FSM/Composition/SameNameLinkBuilder.pm](perl/FSM/Composition/SameNameLinkBuilder.pm)
- [perl/FSM/Composition/LinkedPlanBuilder.pm](perl/FSM/Composition/LinkedPlanBuilder.pm)
- [perl/FSM/Composition/ActualLiteralSupport.pm](perl/FSM/Composition/ActualLiteralSupport.pm)
- [perl/FSM/Composition/AggregatePathSupport.pm](perl/FSM/Composition/AggregatePathSupport.pm)
- [perl/FSM/Composition/SourceExpressionSpecSupport.pm](perl/FSM/Composition/SourceExpressionSpecSupport.pm)
- [perl/FSM/ParameterValueSupport.pm](perl/FSM/ParameterValueSupport.pm)
- [perl/FSM/Composition/PackageImportResolver.pm](perl/FSM/Composition/PackageImportResolver.pm)
- [perl/FSM/Composition/ParameterOverrideResolver.pm](perl/FSM/Composition/ParameterOverrideResolver.pm)
- [perl/FSM/Composition/TopPortInferenceBuilder.pm](perl/FSM/Composition/TopPortInferenceBuilder.pm)
- [perl/FSM/Composition/InterfacePortBuilder.pm](perl/FSM/Composition/InterfacePortBuilder.pm)
- [perl/FSM/Composition/SharedDatapathCandidateBuilder.pm](perl/FSM/Composition/SharedDatapathCandidateBuilder.pm)
- [perl/FSM/Composition/RTLInterfaceLoader.pm](perl/FSM/Composition/RTLInterfaceLoader.pm)
- [perl/FSM/Composition/SharedDatapathSupport.pm](perl/FSM/Composition/SharedDatapathSupport.pm)
- [perl/FSM/Composition/ProvenanceReportBuilder.pm](perl/FSM/Composition/ProvenanceReportBuilder.pm)
- [perl/FSM/Composition/FailureReportBuilder.pm](perl/FSM/Composition/FailureReportBuilder.pm)
- [perl/FSM/Composition/GenerationOrchestrator.pm](perl/FSM/Composition/GenerationOrchestrator.pm)
- [perl/FSM/Composition/ResultMetadataBuilder.pm](perl/FSM/Composition/ResultMetadataBuilder.pm)

This layer is the clearest evidence that the monolith breakdown is real.
These packages mostly have narrow, believable ownership boundaries.
`ChildExportBuilder` now also owns the unified realized-child export surface plus
the narrower generated-child and standalone-DT child views that later
intent/module-info/reporting consumers reuse.
`SharedDatapathCandidateBuilder` now also owns shared-datapath candidate
discovery and normalized contributor/peer-read/aggregate-family metadata,
leaving [SharedDatapathSupport.pm](perl/FSM/Composition/SharedDatapathSupport.pm)
focused on naming and runtime augmentation once candidates already exist.
`FailureReportBuilder` now also owns the bounded failed-run composition summary
family, so blocked-boundary, construct, artifact, context, and concise-reason
extraction no longer live inline in the pipeline coordinator.
`ResultMetadataBuilder` now also owns the success-path `module_info` and
`statistics` assembly family once composition planning, provenance, child
exports, and the forward IR layers already exist.
`GenerationOrchestrator` now also owns the remaining bounded composition
result-assembly cluster from parsed source to returned result surface, so plan
construction, forward-IR assembly, structural top emission, and result-hash
assembly no longer sit inline in `HDLGenerator`.
`GeneratedChildRealizer` now also owns `?fsmc` / `?dtc` realization plus the
external generated-child source-loading contract, leaving the pipeline
coordinator with less child-family-specific source and realization residue.
[perl/FSM/Composition/ActualLiteralSupport.pm](perl/FSM/Composition/ActualLiteralSupport.pm)
now owns composition open/numeric actual literal parsing, exact and intrinsic
width lowering, target-width direct binding expansion, overflow rejection, and
actual binding type-contract construction; [perl/FSM/Composition/LinkedPlanBuilder.pm](perl/FSM/Composition/LinkedPlanBuilder.pm)
keeps the higher-level explicit-link planning and symbol-resolution
diagnostics.
[perl/FSM/Composition/SourceExpressionSpecSupport.pm](perl/FSM/Composition/SourceExpressionSpecSupport.pm)
now owns composition source-expression parsing and spec collection for bounded
top/child bit/slice refs, aggregate paths, concat, repeat, literal operands,
top-symbol payload lookup, and inference/child-source collection; [perl/FSM/Composition/LinkedPlanBuilder.pm](perl/FSM/Composition/LinkedPlanBuilder.pm)
keeps endpoint resolution, aggregate compatibility, carrier allocation, and
diagnostics.
[perl/FSM/Composition/ParameterOverrideResolver.pm](perl/FSM/Composition/ParameterOverrideResolver.pm)
now owns symbolic child parameter override-value resolution after package
imports have populated composition `TopSymbols`, leaving `.rtlif` declaration
validation in `RTLChildRealizer`, generated-child override validation in
`GeneratedChildRealizer`, and scalar/aggregate normalization plus bounded
expression folding in [perl/FSM/ParameterValueSupport.pm](perl/FSM/ParameterValueSupport.pm).
`PlanBuilder` now also owns the bounded composition-plan orchestration family:
child realization dispatch, `?ports` shape gating, top-port inference handoff,
lane selection, and shared-datapath plan augmentation.
`RTLChildRealizer` now also owns `?rtl` child realization into normalized
`RealizedInstance` carriers, while
[RTLInterfaceLoader.pm](perl/FSM/Composition/RTLInterfaceLoader.pm)
stays the narrower owner of `.rtlif` metadata loading and validation.

### Forward IR layer
- [perl/FSM/IR/IntentHIR.pm](perl/FSM/IR/IntentHIR.pm)
- [perl/FSM/IR/IntentHIRBuilder.pm](perl/FSM/IR/IntentHIRBuilder.pm)
- [perl/FSM/IR/LoweredRTLIR.pm](perl/FSM/IR/LoweredRTLIR.pm)
- [perl/FSM/IR/LoweredRTLIRBuilder.pm](perl/FSM/IR/LoweredRTLIRBuilder.pm)
- [perl/FSM/IR/StructuralRTLIR.pm](perl/FSM/IR/StructuralRTLIR.pm)
- [perl/FSM/IR/StructuralRTLIRBuilder.pm](perl/FSM/IR/StructuralRTLIRBuilder.pm)
- [perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm](perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm)

Current layer meaning:
- `IntentHIR`: semantic forward intent
- `IntentHIRBuilder`: bounded semantic-HIR construction for both direct-root
  semantic modules and composition tops, from either a semantic FSM/DT module
  or an already-built composition plan plus structural/child-export inputs
- `LoweredRTLIR`: normalized lowered facts and grouped lowered families
- `LoweredRTLIRBuilder`: bounded lowered-IR construction for both direct-root
  generated modules and composition tops, from either generated-module
  analysis/backend state or an already-built composition plan plus
  structural/semantic/shared-datapath inputs
- `StructuralRTLIR`: netlist-like structure plus typed connectivity
- `StructuralRTLIRBuilder`: bounded structural-IR construction for both
  direct-root generated modules and composition tops, from either
  generated-module analysis or an already-built composition plan
- `ConnectionExpr`: typed actual-connection AST and binding-summary/query helpers

IR audit checkpoint:
- [docs/tasks/FSMGEN-IR-AUDIT.md](tasks/FSMGEN-IR-AUDIT.md) is the active
  architecture task tree for IR inventory and consolidation policy.
- `FSMGEN-IR-AUDIT.1` confirmed that `IntentHIR`, `LoweredRTLIR`, and
  `StructuralRTLIR` are the only named forward IR classes with explicit
  builders and normalized semantic projections.
- ISF `LoweringIR` is a real private scheduler phase boundary. Its public
  contract remains the emitted `.fsm`, schedule JSON, and generated
  composition artifacts, not the full mutable lowerer hash.
- `module_info`, normalized semantic reports, composition provenance, and
  serializable snapshots are compatibility/report projections.
- `FSMGEN-IR-AUDIT.2` completed classification without promoting those
  compatibility/report surfaces. Direct `CoreAST`, private ISF
  parser/scheduler state, `Composition::Plan`, and the named forward IRs keep
  distinct phase-boundary roles; public JSON, contract metadata,
  `module_info`, provenance, snapshots, and artifacts remain bounded
  projections.
- [docs/IR_POLICY.md](IR_POLICY.md) records the required gate for future IR
  changes: name, phase, owner, producers, consumers, invariants,
  mutation/defensive-copy policy, public/private status,
  serialization/report contract, validation, docs impact, and
  migration/retirement plan when needed.
- `FSMGEN-IR-AUDIT.4` closed the audit and created proposed follow-up task
  trees for direct-root structural backend convergence, expression AST
  ownership, private ISF `LoweringIR` boundary extraction, and `module_info`
  projection guarding. It deliberately did not select a generic all-IR
  rewrite or raw private IR export.

### New backend-emitter split
- [perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm](perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm)
- [perl/FSM/Backend/VerilogFamily/TypeDeclarationSupport.pm](perl/FSM/Backend/VerilogFamily/TypeDeclarationSupport.pm)

This is the first real backend package that emits HDL by walking structural IR.
Right now it is composition-top focused and Verilog-family focused.

### Older direct HDL synthesis/backend path
- [perl/FSM/Backend/GeneratedModuleEmitter.pm](perl/FSM/Backend/GeneratedModuleEmitter.pm)
- [perl/FSM/HDL/FlattenedDT.pm](perl/FSM/HDL/FlattenedDT.pm)
- [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](perl/FSM/HDL/FlattenedDT/Orchestrator.pm)
- [perl/FSM/HDL/FlattenedDT/DecisionTreeFlatteningSupport.pm](perl/FSM/HDL/FlattenedDT/DecisionTreeFlatteningSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/Verilog.pm](perl/FSM/HDL/FlattenedDT/Backend/Verilog.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GlobalFactorizationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GlobalFactorizationSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ASTFactorizationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ASTFactorizationSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ScaffoldEmitter.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ScaffoldEmitter.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/InternalDeclarationEmitter.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/InternalDeclarationEmitter.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalRecoverySupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalRecoverySupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalFilterPolicySupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalFilterPolicySupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateNormalizationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateNormalizationSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateClassificationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateClassificationSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSelectionSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSelectionSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateDependencySupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateDependencySupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePlanningSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePlanningSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePreparedBlockSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePreparedBlockSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStagePreparationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStagePreparationSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateAssignmentSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateAssignmentSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateDeclarationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateDeclarationSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateRenderingSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateRenderingSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStageSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStageSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/OperandContractValidationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/OperandContractValidationSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPrescanPreparationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPrescanPreparationSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationTailSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationTailSupport.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/PostFlatteningAssemblySupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/PostFlatteningAssemblySupport.pm)
- [perl/FSM/HDL/Factorization/Fixpoint.pm](perl/FSM/HDL/Factorization/Fixpoint.pm)
- [perl/FSM/HDL/Factorization/Fixpoint/LoopStateSupport.pm](perl/FSM/HDL/Factorization/Fixpoint/LoopStateSupport.pm)
- [perl/FSM/HDL/Factorization/Fixpoint/PassExecutionSupport.pm](perl/FSM/HDL/Factorization/Fixpoint/PassExecutionSupport.pm)
- [perl/FSM/HDL/Factorization/Fixpoint/PassSupport.pm](perl/FSM/HDL/Factorization/Fixpoint/PassSupport.pm)
- [perl/FSM/HDL/ASTFactorization.pm](perl/FSM/HDL/ASTFactorization.pm)
- [perl/FSM/Synthesis/EnableGraph.pm](perl/FSM/Synthesis/EnableGraph.pm)
- [perl/FSM/Synthesis/EnableGraph/FactorizationPolicySupport.pm](perl/FSM/Synthesis/EnableGraph/FactorizationPolicySupport.pm)
- [perl/FSM/Synthesis/EnableGraph/FactorizationSupport.pm](perl/FSM/Synthesis/EnableGraph/FactorizationSupport.pm)
- [perl/FSM/Synthesis/EnableGraph/IntermediateSignalSupport.pm](perl/FSM/Synthesis/EnableGraph/IntermediateSignalSupport.pm)
- [perl/FSM/Synthesis/EnableGraph/ModulePlanningSupport.pm](perl/FSM/Synthesis/EnableGraph/ModulePlanningSupport.pm)
- [perl/FSM/Synthesis/EnableGraph/SignalSupport.pm](perl/FSM/Synthesis/EnableGraph/SignalSupport.pm)
- [perl/FSM/ExpressionNamer.pm](perl/FSM/ExpressionNamer.pm)
- [perl/FSM/AST/Node.pm](perl/FSM/AST/Node.pm)

This stack, now fronted by
[GeneratedModuleEmitter.pm](perl/FSM/Backend/GeneratedModuleEmitter.pm),
still owns the direct generated HDL path for single-module FSM/DT roots and
realized generated children. It remains the densest and least fully split part
of the tree, but the first bounded SystemVerilog scaffold family now has a
real owner in
[ScaffoldEmitter.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ScaffoldEmitter.pm),
the internal declaration family now has a second owner in
[InternalDeclarationEmitter.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/InternalDeclarationEmitter.pm),
the AST-factorization and substituted-AST recovery family now has a third owner in
[ASTFactorizationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ASTFactorizationSupport.pm),
the intermediate runtime-recovery/metadata family now has a fourth owner in
[IntermediateSignalRecoverySupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalRecoverySupport.pm),
the intermediate width family now has a fifth owner in
[IntermediateSignalWidthSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm),
the consolidated intermediate collection family now has a sixth owner in
[ConsolidatedIntermediateSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSupport.pm),
the consolidated intermediate normalization family now has a seventh owner in
[ConsolidatedIntermediateNormalizationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateNormalizationSupport.pm),
the consolidated intermediate classification family now has an eighth owner in
[ConsolidatedIntermediateClassificationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateClassificationSupport.pm),
the consolidated intermediate selection family now has a ninth owner in
[ConsolidatedIntermediateSelectionSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSelectionSupport.pm),
the consolidated intermediate dependency family now has a tenth owner in
[ConsolidatedIntermediateDependencySupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateDependencySupport.pm),
the consolidated intermediate planning family now has an eleventh owner in
[ConsolidatedIntermediatePlanningSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePlanningSupport.pm),
the prepared consolidated intermediate block-contract family now has a twelfth live owner in
[ConsolidatedIntermediatePreparedBlockSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePreparedBlockSupport.pm),
the consolidated intermediate assignment family now has a thirteenth owner in
[ConsolidatedIntermediateAssignmentSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateAssignmentSupport.pm),
the consolidated intermediate declaration family now has a fourteenth owner in
[ConsolidatedIntermediateDeclarationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateDeclarationSupport.pm),
while the older
`ConsolidatedIntermediateBlockSupport`
package now survives only as a directly testable compatibility shell outside
the live [bin/fsmgen](bin/fsmgen)
import spine and delegates to the live stage-preparation owner when available,
while the older
`ConsolidatedIntermediateEmitter`
package now survives only as a directly testable compatibility shell outside
the live [bin/fsmgen](bin/fsmgen)
import spine and delegates to the live rendering owner when available,
while the old
`IntermediateSignalSupport`
package now survives only as a directly testable compatibility shell outside
the live [bin/fsmgen](bin/fsmgen)
import spine instead of remaining one more active backend owner.
That iterative post-substitution factorization path is now split more honestly
too:
[Fixpoint.pm](perl/FSM/HDL/Factorization/Fixpoint.pm)
now narrows to pass scheduling and top-level coordination,
[LoopStateSupport.pm](perl/FSM/HDL/Factorization/Fixpoint/LoopStateSupport.pm)
owns aggregate loop-state application and final result normalization,
[PassExecutionSupport.pm](perl/FSM/HDL/Factorization/Fixpoint/PassExecutionSupport.pm)
owns one-pass factorizer execution, substitution, and owner-side AST updates,
while
[PassSupport.pm](perl/FSM/HDL/Factorization/Fixpoint/PassSupport.pm)
owns per-pass signature building, collision recovery, and new-signal
projection/debugging.
That direct intermediate-signal path is now split more honestly too:
[IntermediateSignalRecoverySupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalRecoverySupport.pm)
owns runtime-AST lookup, rendered-expression caching, and dependency recovery,
[IntermediateSignalWidthSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm)
owns width normalization and recursive width inference, while
[ConsolidatedIntermediateSelectionSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSelectionSupport.pm)
now owns the live AST-first keep/filter dispatch over those extracted recovery
and policy owners.
That direct consolidated-intermediate path is now split more honestly too:
[ConsolidatedIntermediateSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSupport.pm)
owns merged-signal collection and trace,
[ConsolidatedIntermediateNormalizationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateNormalizationSupport.pm)
owns runtime AST, width, dependency, rendered-expression, and live-usage normalization over that merged set,
[ConsolidatedIntermediateClassificationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateClassificationSupport.pm)
owns the initial AST-first keep/filter partition over that normalized set,
[ConsolidatedIntermediateSelectionSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSelectionSupport.pm)
owns dependency-aware rescue plus the final kept/filtered summary over that classified set,
[ConsolidatedIntermediateDependencySupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateDependencySupport.pm)
owns dependency-map construction plus dependency-safe ordering over that selected set,
[ConsolidatedIntermediatePlanningSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePlanningSupport.pm)
owns overall plan composition over the extracted selection and dependency owners,
[ConsolidatedIntermediatePreparedBlockSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePreparedBlockSupport.pm)
owns prepared block-contract projection from the collected normalized signal set plus the composed plan,
[ConsolidatedIntermediateAssignmentSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateAssignmentSupport.pm)
owns prepared assign-statement emission,
[ConsolidatedIntermediateDeclarationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateDeclarationSupport.pm)
owns prepared wire-declaration rendering,
[ConsolidatedIntermediateStagePreparationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStagePreparationSupport.pm)
owns live prepared-block reconstruction from the extracted collection, planning, and prepared-block projection owners,
[ConsolidatedIntermediateRenderingSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateRenderingSupport.pm)
owns final prepared-block rendering from that prepared contract,
[ConsolidatedIntermediateStageSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStageSupport.pm)
now composes live prescan, stage preparation, validation, and prepared-block rendering at direct backend stage 6,
[PostFlatteningAssemblySupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/PostFlatteningAssemblySupport.pm)
now composes the live post-flattening scaffold/declaration/enable/stage/tail assembly handoff,
`ConsolidatedIntermediateBlockSupport`
now survives only as a directly testable compatibility shell outside that live
path and delegates to the stage-preparation owner when available, while
`ConsolidatedIntermediateEmitter`
now survives only as a directly testable compatibility shell outside that live
path and delegates to the live rendering owner when available, and
`ConsolidatedIntermediateGenerationSupport`
now survives only as a directly testable compatibility shell outside that live path too.
The synthesis-side intermediate-signal registry and dependency-recovery family
now also has its own owner in
[EnableGraph/IntermediateSignalSupport.pm](perl/FSM/Synthesis/EnableGraph/IntermediateSignalSupport.pm)
instead of remaining inline in the broader synthesis owner.
The synthesis-side factorization-analysis and substitution/live-usage evidence
family now also has its own owner in
[EnableGraph/FactorizationSupport.pm](perl/FSM/Synthesis/EnableGraph/FactorizationSupport.pm)
instead of leaving AST-factorization bookkeeping inline in that same owner.

### Extension surface
- [perl/FSM/Extension/Loader.pm](perl/FSM/Extension/Loader.pm)
- [perl/FSM/Extension/Registry.pm](perl/FSM/Extension/Registry.pm)
- [perl/FSM/Extension/Context.pm](perl/FSM/Extension/Context.pm)

This surface is intentionally small.
It behaves like a hook system, not a competing architecture.

## Package-level assessment
### Healthy or improving areas
- [bin/fsmgen](bin/fsmgen) is thin and reasonably honest.
- The composition frontend and builder packages are much better factored than the older backend path.
- The composition path now also has a dedicated generation orchestrator instead
  of leaving the whole result-assembly cluster inline in `HDLGenerator`.
- The top-level file/source dispatch path now also has a dedicated pipeline
  orchestrator instead of leaving parse/classify/dispatch/finalization inline
  in `HDLGenerator`.
- The direct-root path now also has a dedicated pipeline orchestrator instead of
  leaving the whole non-composition result-assembly cluster inline there too.
- `IntentHIRBuilder` now also owns the direct-root semantic summary rather than
  leaving signal-analysis grouping, direction inference, and standalone-DT
  enable-family assembly inline in `HDLGenerator`.
- `LoweredRTLIRBuilder` now also owns the direct-root lowered summary rather
  than leaving output-drive-family and standalone-DT lowered-target assembly
  inline in `HDLGenerator`.
- `StructuralRTLIRBuilder` now also owns the direct-root structural summary
  rather than leaving module-boundary and implicit-system-port structural
  assembly inline in `HDLGenerator`.
- `GeneratedModuleEmitter` now also owns the bounded direct generated-module
  backend family rather than leaving backend-method selection, direct HDL
  emission, backend statistics, and standalone-DT assertion postprocessing
  spread across `HDLGenerator`, `DirectGenerationOrchestrator`, and realized
  generated-child handling.
- `GeneratedModuleInfoBuilder` now also owns the bounded generated-module
  `module_info` family rather than leaving semantic summary build, lowered
  enrichment, and output-drive-family / grouped-target queries split between
  `HDLGenerator`, `DirectGenerationOrchestrator`, and generated-child
  realization.
- `SourceFrontend` now also owns the bounded source-frontend family rather
  than leaving file parsing, source-kind classification, composition parsing,
  and semantic-module creation inline in `HDLGenerator`.
- `bin/fsmgen` now also reads composition failure summaries plus provenance /
  override / block labels directly from the dedicated builder packages instead
  of asking `HDLGenerator` to keep those reporting helpers as facade residue.
- `FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport`
  now also owns the merged-signal collection/trace half of the direct
  consolidated intermediate path rather than leaving AST-factorized,
  prescanned, and FSMGen-parsed intermediate collection mixed into the final
  emitter.
- `FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport`
  now also owns runtime metadata normalization for that same direct
  consolidated intermediate path rather than leaving runtime AST, width,
  dependency, rendered-expression, and live-usage normalization mixed into the
  collection owner.
- `FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateClassificationSupport`
  now also owns the initial AST-first keep/filter partition for that same
  direct consolidated intermediate path rather than leaving first-pass
  classification mixed together with dependency rescue and final selection
  summary projection.
- `FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateDependencySupport`
  now also owns dependency-map construction and dependency-safe ordering for
  the direct consolidated intermediate path rather than leaving graph
  mechanics mixed into the planning owner.
- `FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSelectionSupport`
  now also owns the dependency-aware rescue/final-selection half of the direct
  consolidated intermediate path rather than leaving set-level rescue policy
  mixed into planning or keeping first-pass classification inline.
- `FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediatePlanningSupport`
  now also owns overall plan composition for the direct consolidated
  intermediate path rather than leaving graph mechanics and selection policy
  mixed into the same owner.
- `FSM::HDL::Factorization::Fixpoint::PassSupport` now also owns the per-pass
  helper family around the iterative second-pass loop rather than leaving
  signature building, collision recovery, and new-signal projection inline in
  `Fixpoint`.
- `FSM::HDL::Factorization::Fixpoint::PassExecutionSupport` now also owns the
  single-pass execution family around the iterative second-pass loop rather
  than leaving factorizer construction, repeated-signature short-circuiting,
  and per-pass substitution/update work inline in `Fixpoint`.
- `FSM::HDL::Factorization::Fixpoint::LoopStateSupport` now also owns the
  aggregate loop-state lifecycle around the iterative second-pass loop rather
  than leaving accepted-signal adoption, aggregate counter updates, and final
  termination/result normalization inline in `Fixpoint`.
- `FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediatePreparedBlockSupport`
  now also owns prepared block-contract projection for the direct
  consolidated intermediate path rather than leaving contract assembly mixed
  into the block handoff owner.
- `FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateStagePreparationSupport`
  now also owns the live prepared-block reconstruction handoff for the direct
  consolidated intermediate path rather than leaving that coordination mixed
  into the old generation wrapper or the live orchestrator stage.
- `FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateRenderingSupport`
  now also owns final prepared-block rendering for the direct consolidated
  intermediate path rather than leaving that composition inline in the old
  generation wrapper or the live orchestrator stage.
- `FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateAssignmentSupport`
  now also owns the prepared assign-emission half of the direct consolidated
  intermediate path rather than leaving expression recovery plus final assign
  rendering mixed into the block emitter.
- `FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport`
  now also owns the runtime-AST/dependency/render half of the direct
  intermediate-signal path rather than leaving recovery mixed together with
  width normalization and final filter policy.
- `FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport`
  now also owns direct intermediate width normalization and recursive width
  inference rather than leaving width policy buried inside the broader
  recovery owner.
- `FSM::Synthesis::EnableGraph::ModulePlanningSupport` now also owns the
  module/state/declaration planning family rather than leaving effective
  system-contract lookup, state-register planning, module-boundary port
  planning, and internal declaration planning inside `EnableGraph`.
- `FSM::Synthesis::EnableGraph::AssignmentSupport` now also owns the bounded
  assignment-analysis / RHS-grouping / mux-plan / assignment-emission family
  rather than leaving unified assignment analysis, driven-signal discovery,
  reset/default/width recovery, and delayed-pulse / flop / combinational mux
  emission inline inside `EnableGraph`.
- `FSM::Synthesis::EnableGraph::CaptureSupport` now also owns the bounded AST
  capture/conversion family rather than leaving condition-stack
  normalization, assignment/transition capture, test-selector conversion, and
  AST signal-name extraction inline inside `EnableGraph`.
- `FSM::Synthesis::EnableGraph::EnableSupport` now also owns the bounded
  enable-family support rather than leaving top-level state/DT enable
  initialization, WEN/EN prescan tracking, and unified DT/LHS WEN/EN
  emission inline inside `EnableGraph`.
- `FSM::Synthesis::EnableGraph::FactorizationPolicySupport` now also owns the
  bounded factorization-policy family rather than leaving logical-operation
  counting, first-pass AST feed preparation, second-pass AST feed
  eligibility, and high-count logical-operation policy inline inside
  `FactorizationSupport`.
- `FSM::HDL::FlattenedDT::Backend::SystemVerilog::GlobalFactorizationSupport`
  now also owns the direct first-pass AST-factorization pipeline rather than
  leaving factorizer construction, substitution, original-AST refresh,
  fixpoint delegation, and factorizer persistence inline inside
  `ASTFactorizationSupport`.
- `FSM::Synthesis::EnableGraph::SignalSupport` now also owns the bounded
  signal/intermediate support family rather than leaving AST-based
  intermediate naming, reset/default lookup, direct intermediate dependency
  extraction, signal/intermediate classification, and backend-safe signal
  cleanup inline inside `EnableGraph`.
- `FSM::Package::*` now owns the shared package/symbol/type payload surface for
  direct roots, composition tops, and semantic package roots, including the
  newly shared aggregate expression type-shape inference owner. That is a
  healthier shape than letting direct and composition parsers carry parallel
  aggregate walkers.
- The forward IR layer now looks real enough to steer architecture, not just document aspiration.
- [perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm](perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm) has become a meaningful structural API, not just formatting glue.
- [perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm](perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm) is the right directional move for backend emission.

### Current hotspots
- [perl/FSM/Scheduler/ISF/LoweringIR.pm](perl/FSM/Scheduler/ISF/LoweringIR.pm)
  is now the largest reachable file. That growth is mostly active R14 feature
  delivery rather than abandoned legacy shape, but the file now owns enough
  parser-normalized transaction validation, lowering IR construction, dynamic
  wait edge-splitting, pending-sample materialization, generated-child/library
  handoff, storage/bank access, and report provenance that future ISF work
  should look for bounded helper-owner extractions when a behavior family
  becomes stable.
- [perl/FSM/Synthesis/EnableGraph.pm](perl/FSM/Synthesis/EnableGraph.pm) is now a thin synthesis-context shell at `75` lines, so the remaining backend gravity lives in the broader `EnableGraph::*` owner family rather than the shell package itself.
- The direct single-module generation path still has not converged on the same clean `StructuralRTLIR -> backend emitter` shape that the composition path is starting to use, even though it now has its own direct-root orchestrator boundary and a dedicated generated-module backend owner.
- [perl/FSM/Composition/LinkedPlanBuilder.pm](perl/FSM/Composition/LinkedPlanBuilder.pm) is no longer the largest reachable file after [perl/FSM/Composition/ActualLiteralSupport.pm](perl/FSM/Composition/ActualLiteralSupport.pm) took ownership of literal actual policy and [perl/FSM/Composition/SourceExpressionSpecSupport.pm](perl/FSM/Composition/SourceExpressionSpecSupport.pm) took ownership of source-expression parsing/spec collection. [perl/FSM/ParameterValueSupport.pm](perl/FSM/ParameterValueSupport.pm) is the same good shape at smaller scale for direct, external RTL, and generated-child parameter/generic scalar, aggregate, scalar-expression, and leafwise aggregate-expression values, and [perl/FSM/Composition/ParameterOverrideResolver.pm](perl/FSM/Composition/ParameterOverrideResolver.pm) now owns symbolic override-value resolution, but `LinkedPlanBuilder` remains a real composition hotspot because source-expression resolution, aggregate shape checks, carrier allocation, and binding-type preservation still meet there.
- [perl/FSM/Synthesis/EnableGraph/FactorizationPolicySupport.pm](perl/FSM/Synthesis/EnableGraph/FactorizationPolicySupport.pm), [perl/FSM/Synthesis/EnableGraph/FactorizationSupport.pm](perl/FSM/Synthesis/EnableGraph/FactorizationSupport.pm), [perl/FSM/Synthesis/EnableGraph/SignalSupport.pm](perl/FSM/Synthesis/EnableGraph/SignalSupport.pm), [perl/FSM/Synthesis/EnableGraph/IntermediateSignalSupport.pm](perl/FSM/Synthesis/EnableGraph/IntermediateSignalSupport.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GlobalFactorizationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GlobalFactorizationSupport.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalRecoverySupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalRecoverySupport.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSupport.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateNormalizationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateNormalizationSupport.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSelectionSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSelectionSupport.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateDependencySupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateDependencySupport.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePlanningSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePlanningSupport.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePreparedBlockSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePreparedBlockSupport.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStagePreparationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStagePreparationSupport.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateRenderingSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateRenderingSupport.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateAssignmentSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateAssignmentSupport.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateDeclarationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateDeclarationSupport.pm), [perl/FSM/HDL/Factorization/Fixpoint/LoopStateSupport.pm](perl/FSM/HDL/Factorization/Fixpoint/LoopStateSupport.pm), [perl/FSM/HDL/Factorization/Fixpoint/PassExecutionSupport.pm](perl/FSM/HDL/Factorization/Fixpoint/PassExecutionSupport.pm), and [perl/FSM/HDL/Factorization/Fixpoint/PassSupport.pm](perl/FSM/HDL/Factorization/Fixpoint/PassSupport.pm) now carry more of the remaining backend gravity than any single shell package.
- The remaining `EnableGraph`-family gravity is now narrower than before: module/state/declaration planning, assignment-analysis / mux-emission support, enable-family support, AST capture/conversion support, AST rendering/classification, signal/intermediate support, and factorization policy all have dedicated owners now, and the direct first-pass AST-factorization pipeline plus the iterative fixpoint loop-state/pass helper/pass execution families do too. So the next honest seams are no longer “who owns the first factorization pass,” “who owns the fixpoint pass helpers,” “who owns the fixpoint aggregate loop-state contract,” “who owns the consolidated intermediate dependency graph mechanics,” “who owns the old direct consolidated block shell,” “who owns the old direct consolidated emitter shell,” “who owns the live consolidated intermediate stage-6/prescan handoff,” “who owns the whole post-flattening SystemVerilog assembly sequence,” or “who owns the pre-stage scaffold/declaration/enable/prescan sequence”; they are the remaining lower-level direct-backend planning/stage coordination and broader direct-backend convergence rather than the old direct planning, capture, assembly, or WEN/EN clusters.
- [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](perl/FSM/HDL/FlattenedDT/Orchestrator.pm) is now a smaller sequencing handoff that keeps per-run reset, module attachment, recursive flattening, and final post-flattening assembly delegation.
- `module_info` and reporting/statistics surfaces still create pressure for the coordinator to know too much, even though the generated-module `module_info` family now has its own explicit owner.
- `EnableGraph` no longer owns AST rendering/operator-classification directly,
  and the old direct `IntermediateSignalSupport` shell is no longer on the
  live import spine, but the direct backend still depends deeply on the
  broader factorization and consolidated-intermediate families through
  `ASTSupport`, `FactorizationPolicySupport`, `FactorizationSupport`,
  `ConsolidatedIntermediateSelectionSupport`, and the older `Fixpoint` loop.

## Important implications for future implementation
### 1. The composition path is the cleanest forward-looking model
If the project needs a template for “how the final architecture should feel,” it is closer to:
- typed frontend
- bounded builders
- explicit IR construction
- structural emitter

than to the older direct `FlattenedDT` path.

### 2. `HDLGenerator` is now an honest facade, but the older direct backend is still the deeper hotspot
The main remaining architectural pressure is no longer the top-level pipeline
facade. It is the older direct backend family under `FlattenedDT`,
`FlattenedDT::Orchestrator`, `EnableGraph`, its support owners, and `Fixpoint`, where the
remaining AST-factorization, sequencing, and planning gravity still lives.

That means the long-term split is still warranted.

### 3. `StructuralRTLIR` is now real enough to matter
It is no longer just a placeholder summary object.
It already carries:
- ports
- nets
- instances
- declared links
- resolved links
- auxiliary assignments
- typed connection expressions
- query helpers over top ports and child endpoints

That makes it a believable last-IR-before-emission target.

### 4. The `EnableGraph` family remains the hardest backend seam
The composition-side package breakdown is moving well.
The older synthesis/backend side is still much more concentrated.
If there is one place likely to dominate future backend cleanup cost, it is the
broader [perl/FSM/Synthesis/EnableGraph](perl/FSM/Synthesis/EnableGraph)
family rather than the thin shell package alone.
The newer owner set is helping though: the direct backend’s AST rendering and
operator-classification family now lives in
[perl/FSM/Synthesis/EnableGraph/ASTSupport.pm](perl/FSM/Synthesis/EnableGraph/ASTSupport.pm)
and the remaining signal/intermediate family now lives in
[perl/FSM/Synthesis/EnableGraph/SignalSupport.pm](perl/FSM/Synthesis/EnableGraph/SignalSupport.pm)
and the factorization-policy family now lives in
[perl/FSM/Synthesis/EnableGraph/FactorizationPolicySupport.pm](perl/FSM/Synthesis/EnableGraph/FactorizationPolicySupport.pm)
instead of inside `EnableGraph` itself, which is a real reduction in owner
gravity even if it does not finish the backend cleanup by itself.

### 5. The extension system is not the architectural problem
It is small and bounded.
It should stay secondary while the compiler and backend ownership boundaries continue to be refined.

## Working conclusion
The current state of the import tree is encouraging but transitional.

The project already has:
- a thin CLI entrypoint
- a real forward IR story
- a meaningful structural connectivity layer
- the start of a real backend-emitter split
- and a cleaner composition architecture than it used to

But it also still has:
- one orchestrator family that is now the real coordination hub
- one broad semantic package/type surface that is improving but newly important
- one large active ISF lowering owner carrying most of the fast-moving R14
  transaction/lowering behavior
- a few large composition/source-expression builders that should not become
  the next quiet monolith
- and a direct single-module backend family that is better fronted than before,
  but still has not fully caught up with the composition-side architectural cleanup

That is the honest current state this document should keep tracking.
