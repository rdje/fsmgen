# `bin/fsmgen` Import Tree Analysis

This is a live architecture note.

Use it to keep one current, high-signal picture of:
- what [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) actually does,
- which project-owned packages sit in its transitive import tree,
- what the real runtime spine is,
- and where the current architectural hotspots still are.

Refresh this document at the start of a later session whenever the effective entrypoint/import-tree architecture has moved enough that this note is no longer honest.

Current baseline:
- Reviewed on `2026-03-26`.
- Scope is the project-owned transitive `FSM::...` tree reachable from [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen).
- Perl core and non-project helper modules are treated as support dependencies, not as part of the architectural map.

## Executive read
[bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) is a thin CLI/reporting shell.
[perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm)
is now down to the honest facade role we wanted: shared pipeline
configuration plus the single top-level `generate_hdl_from_file(...)`
entrypoint.

The real coordinator gravity is now the orchestrator family beneath it:
- [perl/FSM/Pipeline/SourceGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceGenerationOrchestrator.pm)
- [perl/FSM/Pipeline/DirectGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/DirectGenerationOrchestrator.pm)
- [perl/FSM/Composition/GenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GenerationOrchestrator.pm)

The best current architecture in the tree is the newer composition/forward-IR/backend-emitter slice:
- [perl/FSM/IR/IntentHIR.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/IntentHIR.pm)
- [perl/FSM/IR/IntentHIRBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/IntentHIRBuilder.pm)
- [perl/FSM/IR/LoweredRTLIR.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/LoweredRTLIR.pm)
- [perl/FSM/IR/LoweredRTLIRBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/LoweredRTLIRBuilder.pm)
- [perl/FSM/IR/StructuralRTLIR.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIR.pm)
- [perl/FSM/IR/StructuralRTLIRBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIRBuilder.pm)
- [perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm)

The heaviest remaining complexity is still the direct single-module HDL backend path centered on:
- [perl/FSM/Backend/GeneratedModuleEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Backend/GeneratedModuleEmitter.pm)
- [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/InternalDeclarationEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/InternalDeclarationEmitter.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ScaffoldEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ScaffoldEmitter.pm)
- [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm)

## What `bin/fsmgen` actually owns
[bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) directly imports:
- [perl/FSM/Composition/FailureReportBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/FailureReportBuilder.pm)
- [perl/FSM/Composition/ProvenanceReportBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/ProvenanceReportBuilder.pm)
- [perl/FSM/Debug.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Debug.pm)
- [perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm)
- [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm)
- [perl/FSM/SourcePathResolver.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/SourcePathResolver.pm)

It mainly owns:
- CLI option parsing
- source-file lookup
- debug/trace routing
- output-file writing
- user-facing summaries for composition provenance, override/block events, failure summaries, generated children, and shared-datapath metadata

It does not own the compiler architecture.
Its only non-trivial local logic is presentation/reporting glue.

## Runtime spine
Normal execution is best understood like this:

```text
bin/fsmgen
  -> FSM::SourcePathResolver
  -> FSM::Pipeline::HDLGenerator->generate_hdl_from_file
     -> FSM::Pipeline::SourceGenerationOrchestrator
        -> FSM::Pipeline::SourceFrontend
        -> parse_fsm_file
        -> classify_source_ast
        -> direct single-module path
        -> FSM::Pipeline::DirectGenerationOrchestrator
        -> FSM::Pipeline::SourceFrontend
        -> FSM::Adapter::FSMGenFull
        -> IntentHIR
        -> FSM::Pipeline::GeneratedModuleInfoBuilder
        -> FSM::Backend::GeneratedModuleEmitter
        -> FSM::HDL::FlattenedDT
           -> FlattenedDT::Orchestrator
           -> Synthesis::EnableGraph
           -> FlattenedDT::Backend::SystemVerilog::ScaffoldEmitter
           -> FlattenedDT::Backend::SystemVerilog::InternalDeclarationEmitter
           -> FlattenedDT::Backend::SystemVerilog or Verilog
        -> LoweredRTLIR
        -> StructuralRTLIR
        -> composition path
        -> FSM::Composition::GenerationOrchestrator
        -> FSM::Composition::Parser
        -> generated-child realization / external RTL child realization / RTL interface loading
        -> composition plan building / composition builders
        -> StructuralRTLIRBuilder
        -> StructuralRTLIREmitter
        -> IntentHIR / LoweredRTLIR
        -> provenance + shared-datapath reporting
```

Important distinction:
- the direct single-module path still relies on the older `FlattenedDT`/`EnableGraph` backend family
- the composition path already uses the newer structural-emitter split more honestly

## Static import tree grouped by responsibility
### CLI and source routing
- [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen)
- [perl/FSM/Debug.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Debug.pm)
- [perl/FSM/SourcePathResolver.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/SourcePathResolver.pm)
- [perl/FSM/SourceClassifier.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/SourceClassifier.pm)

### Main orchestration hub
- [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm)
- [perl/FSM/Pipeline/DirectGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/DirectGenerationOrchestrator.pm)
- [perl/FSM/Pipeline/SourceGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceGenerationOrchestrator.pm)

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

The important improvement is that [HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm)
no longer owns the top-level file/source dispatch cluster inline:
[SourceGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceGenerationOrchestrator.pm)
now owns parsed file dispatch into the direct-root or composition path plus the
surrounding extension-hook/finalization flow.
[HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm)
also no longer owns the full direct-root result-assembly cluster inline:
[DirectGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/DirectGenerationOrchestrator.pm)
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
- [perl/FSM/Pipeline/SourceFrontend.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceFrontend.pm)

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
- [perl/FSM/Backend/GeneratedModuleEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Backend/GeneratedModuleEmitter.pm)

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
- [perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm)

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
- [perl/FSM/Adapter/FSMGenFull.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull.pm)
- [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm)
- `FSM::Adapter::FSMGenFull::{SignalAnalyzer,SignalManager,ExpressionBuilder}`
- [perl/FSM/CoreAST.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/CoreAST.pm)

This layer turns Lispish/raw AST into a semantic module.
The parser is strict about current source-root contracts and rejects unsupported tagged top-level forms explicitly.

### Composition parsing and typed value model
- [perl/FSM/Composition/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Parser.pm)
- `FSM::Composition::{Spec,Top,Instance,Port,Link,TopLink,PortsBlock,Net,Plan,RealizedInstance}`

This is a typed composition frontend, not loose ad hoc parsing.
It is one of the cleaner parts of the tree.

### Composition builders and support owners
- [perl/FSM/Composition/C1PlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/C1PlanBuilder.pm)
- [perl/FSM/Composition/ChildExportBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/ChildExportBuilder.pm)
- [perl/FSM/Composition/DeclaredByNameLinkBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/DeclaredByNameLinkBuilder.pm)
- [perl/FSM/Composition/GeneratedChildRealizer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GeneratedChildRealizer.pm)
- [perl/FSM/Composition/PlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/PlanBuilder.pm)
- [perl/FSM/Composition/RTLChildRealizer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLChildRealizer.pm)
- [perl/FSM/Composition/SameNameLinkBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/SameNameLinkBuilder.pm)
- [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm)
- [perl/FSM/Composition/TopPortInferenceBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/TopPortInferenceBuilder.pm)
- [perl/FSM/Composition/InterfacePortBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/InterfacePortBuilder.pm)
- [perl/FSM/Composition/SharedDatapathCandidateBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/SharedDatapathCandidateBuilder.pm)
- [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm)
- [perl/FSM/Composition/SharedDatapathSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/SharedDatapathSupport.pm)
- [perl/FSM/Composition/ProvenanceReportBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/ProvenanceReportBuilder.pm)
- [perl/FSM/Composition/FailureReportBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/FailureReportBuilder.pm)
- [perl/FSM/Composition/GenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GenerationOrchestrator.pm)
- [perl/FSM/Composition/ResultMetadataBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/ResultMetadataBuilder.pm)

This layer is the clearest evidence that the monolith breakdown is real.
These packages mostly have narrow, believable ownership boundaries.
`ChildExportBuilder` now also owns the unified realized-child export surface plus
the narrower generated-child and standalone-DT child views that later
intent/module-info/reporting consumers reuse.
`SharedDatapathCandidateBuilder` now also owns shared-datapath candidate
discovery and normalized contributor/peer-read/aggregate-family metadata,
leaving [SharedDatapathSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/SharedDatapathSupport.pm)
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
`PlanBuilder` now also owns the bounded composition-plan orchestration family:
child realization dispatch, `?ports` shape gating, top-port inference handoff,
lane selection, and shared-datapath plan augmentation.
`RTLChildRealizer` now also owns `?rtl` child realization into normalized
`RealizedInstance` carriers, while
[RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm)
stays the narrower owner of `.rtlif` metadata loading and validation.

### Forward IR layer
- [perl/FSM/IR/IntentHIR.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/IntentHIR.pm)
- [perl/FSM/IR/IntentHIRBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/IntentHIRBuilder.pm)
- [perl/FSM/IR/LoweredRTLIR.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/LoweredRTLIR.pm)
- [perl/FSM/IR/LoweredRTLIRBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/LoweredRTLIRBuilder.pm)
- [perl/FSM/IR/StructuralRTLIR.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIR.pm)
- [perl/FSM/IR/StructuralRTLIRBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIRBuilder.pm)
- [perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm)

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

### New backend-emitter split
- [perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm)

This is the first real backend package that emits HDL by walking structural IR.
Right now it is composition-top focused and Verilog-family focused.

### Older direct HDL synthesis/backend path
- [perl/FSM/Backend/GeneratedModuleEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Backend/GeneratedModuleEmitter.pm)
- [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm)
- [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/InternalDeclarationEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/InternalDeclarationEmitter.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ScaffoldEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ScaffoldEmitter.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm)
- `FSM::HDL::FlattenedDT::Backend::Verilog`
- `FSM::HDL::Factorization::Fixpoint`
- `FSM::HDL::ASTFactorization`
- [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm)
- `FSM::ExpressionNamer`
- `FSM::AST::Node`

This stack, now fronted by
[GeneratedModuleEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Backend/GeneratedModuleEmitter.pm),
still owns the direct generated HDL path for single-module FSM/DT roots and
realized generated children. It remains the densest and least fully split part
of the tree, but the first bounded SystemVerilog scaffold family now has a
real owner in
[ScaffoldEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ScaffoldEmitter.pm)
and the internal declaration family now has a second owner in
[InternalDeclarationEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/InternalDeclarationEmitter.pm)
instead of both pockets living inline in the broader backend renderer.

### Extension surface
- [perl/FSM/Extension/Loader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Loader.pm)
- [perl/FSM/Extension/Registry.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Registry.pm)
- [perl/FSM/Extension/Context.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Context.pm)

This surface is intentionally small.
It behaves like a hook system, not a competing architecture.

## Package-level assessment
### Healthy or improving areas
- [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) is thin and reasonably honest.
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
- The forward IR layer now looks real enough to steer architecture, not just document aspiration.
- [perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm) has become a meaningful structural API, not just formatting glue.
- [perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm) is the right directional move for backend emission.

### Current hotspots
- [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) is still too broad.
- [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm) is still a very large semantic/synthesis gravity well.
- The direct single-module generation path still has not converged on the same clean `StructuralRTLIR -> backend emitter` shape that the composition path is starting to use, even though it now has its own direct-root orchestrator boundary and a dedicated generated-module backend owner.
- `module_info` and reporting/statistics surfaces still create pressure for the coordinator to know too much, even though the generated-module `module_info` family now has its own explicit owner.

## Important implications for future implementation
### 1. The composition path is the cleanest forward-looking model
If the project needs a template for “how the final architecture should feel,” it is closer to:
- typed frontend
- bounded builders
- explicit IR construction
- structural emitter

than to the older direct `FlattenedDT` path.

### 2. `HDLGenerator` is still a coordinator plus residue owner
The file name says “generator,” but in practice it is still:
- compiler driver
- source dispatcher
- composition orchestrator
- IR assembler
- report assembler
- and partial backend coordinator

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

### 4. `EnableGraph` remains the hardest backend seam
The composition-side package breakdown is moving well.
The older synthesis/backend side is still much more concentrated.
If there is one place likely to dominate future backend cleanup cost, it is [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm).

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
- one still-too-wide pipeline facade/coordinator
- one oversized synthesis owner
- and a direct single-module backend family that is better fronted than before,
  but still has not fully caught up with the composition-side architectural cleanup

That is the honest current state this document should keep tracking.
