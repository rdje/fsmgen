# `bin/fsmgen` Import Tree Analysis

This is a live architecture note.

Use it to keep one current, high-signal picture of:
- what [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) actually does,
- which project-owned packages sit in its transitive import tree,
- what the real runtime spine is,
- and where the current architectural hotspots still are.

Refresh this document at the start of a later session whenever the effective entrypoint/import-tree architecture has moved enough that this note is no longer honest.

Current baseline:
- Reviewed on `2026-03-25`.
- Scope is the project-owned transitive `FSM::...` tree reachable from [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen).
- Perl core and non-project helper modules are treated as support dependencies, not as part of the architectural map.

## Executive read
[bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) is a thin CLI/reporting shell.
The real center of gravity is still [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm).

The best current architecture in the tree is the newer composition/forward-IR/backend-emitter slice:
- [perl/FSM/IR/IntentHIR.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/IntentHIR.pm)
- [perl/FSM/IR/LoweredRTLIR.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/LoweredRTLIR.pm)
- [perl/FSM/IR/StructuralRTLIR.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIR.pm)
- [perl/FSM/IR/StructuralRTLIRBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIRBuilder.pm)
- [perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm)

The heaviest remaining complexity is still the direct single-module HDL backend path centered on:
- [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm)
- [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm)

## What `bin/fsmgen` actually owns
[bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) directly imports:
- [perl/FSM/Debug.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Debug.pm)
- [perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm)
- [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm)
- [perl/FSM/SourcePathResolver.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/SourcePathResolver.pm)

It mainly owns:
- CLI option parsing
- source-file lookup
- debug/trace routing
- output-file writing
- user-facing summaries for composition provenance, override/block events, generated children, and shared-datapath metadata

It does not own the compiler architecture.
Its only non-trivial local logic is presentation/reporting glue.

## Runtime spine
Normal execution is best understood like this:

```text
bin/fsmgen
  -> FSM::SourcePathResolver
  -> FSM::Pipeline::HDLGenerator->generate_hdl_from_file
     -> parse_fsm_file
     -> classify_source_ast
     -> direct single-module path
        -> FSM::Adapter::FSMGenFull
        -> IntentHIR
        -> module analysis / module_info
        -> FSM::HDL::FlattenedDT
           -> FlattenedDT::Orchestrator
           -> Synthesis::EnableGraph
           -> FlattenedDT::Backend::SystemVerilog or Verilog
        -> LoweredRTLIR
        -> StructuralRTLIR
     -> composition path
        -> FSM::Composition::Parser
        -> child realization / interface loading
        -> composition builders
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

This is still the architectural hub. It currently coordinates:
- source parsing and dispatch
- child realization
- composition lane selection
- forward IR construction
- module-info/statistics assembly
- failure summarization
- backend coordination

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
- [perl/FSM/Composition/SameNameLinkBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/SameNameLinkBuilder.pm)
- [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm)
- [perl/FSM/Composition/TopPortInferenceBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/TopPortInferenceBuilder.pm)
- [perl/FSM/Composition/InterfacePortBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/InterfacePortBuilder.pm)
- [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm)
- [perl/FSM/Composition/SharedDatapathSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/SharedDatapathSupport.pm)
- [perl/FSM/Composition/ProvenanceReportBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/ProvenanceReportBuilder.pm)

This layer is the clearest evidence that the monolith breakdown is real.
These packages mostly have narrow, believable ownership boundaries.
`ChildExportBuilder` now also owns the unified realized-child export surface plus
the narrower generated-child and standalone-DT child views that later
intent/module-info/reporting consumers reuse.

### Forward IR layer
- [perl/FSM/IR/IntentHIR.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/IntentHIR.pm)
- [perl/FSM/IR/LoweredRTLIR.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/LoweredRTLIR.pm)
- [perl/FSM/IR/StructuralRTLIR.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIR.pm)
- [perl/FSM/IR/StructuralRTLIRBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIRBuilder.pm)
- [perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm)

Current layer meaning:
- `IntentHIR`: semantic forward intent
- `LoweredRTLIR`: normalized lowered facts and grouped lowered families
- `StructuralRTLIR`: netlist-like structure plus typed connectivity
- `ConnectionExpr`: typed actual-connection AST and binding-summary/query helpers

### New backend-emitter split
- [perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm)

This is the first real backend package that emits HDL by walking structural IR.
Right now it is composition-top focused and Verilog-family focused.

### Older direct HDL synthesis/backend path
- [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm)
- [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm)
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm)
- `FSM::HDL::FlattenedDT::Backend::Verilog`
- `FSM::HDL::Factorization::Fixpoint`
- `FSM::HDL::ASTFactorization`
- [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm)
- `FSM::ExpressionNamer`
- `FSM::AST::Node`

This stack still owns the direct generated HDL path for single-module FSM/DT roots.
It remains the densest and least fully split part of the tree.

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
- The forward IR layer now looks real enough to steer architecture, not just document aspiration.
- [perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm) has become a meaningful structural API, not just formatting glue.
- [perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm) is the right directional move for backend emission.

### Current hotspots
- [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) is still too broad.
- [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm) is still a very large semantic/synthesis gravity well.
- The direct single-module generation path has not yet converged on the same clean `StructuralRTLIR -> backend emitter` shape that the composition path is starting to use.
- `module_info` and reporting/statistics surfaces still create pressure for the coordinator to know too much.

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
- one oversized pipeline coordinator
- one oversized synthesis owner
- and a direct single-module backend path that has not fully caught up with the composition-side architectural cleanup

That is the honest current state this document should keep tracking.
