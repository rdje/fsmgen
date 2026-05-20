# FSMGEN-IR-AUDIT: IR Inventory And Consolidation Audit

## Metadata

- Tree ID: `FSMGEN-IR-AUDIT`
- Status: `active`
- Roadmap lane: `architecture backlog`
- Created: `2026-05-14`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Audit the IR structures currently used across FSMGen, decide which ones are
canonical phase boundaries versus local implementation conveniences, and define
a standard for when future work may introduce, reuse, merge, or retire an IR.

The goal is not to force one universal IR. The goal is to prevent accidental
IR sprawl: every IR should have a named owner, source-of-truth role, consumer
set, lifecycle, and documented handoff contract.

## Non-Goals

- Do not pause the active `R14` ISF feature work for this audit.
- Do not refactor compiler internals before the inventory and recommendation
  leaves establish the exact target.
- Do not freeze every private implementation structure as public API.
- Do not collapse semantically different phases into one oversized IR merely
  for naming uniformity.

## Acceptance Criteria

- The current IR and IR-like structures are inventoried with file/package
  ownership, producers, consumers, serialized/report surfaces, and mutability
  assumptions.
- Each structure is classified as parsed syntax, semantic intent, scheduling,
  lowered behavior, structural/connectivity, backend/emission, composition
  planning, or report/contract projection.
- Redundant or overlapping structures are called out with concrete risks and
  possible consolidation paths.
- A repo-local IR policy defines when a new feature should reuse an existing
  IR, extend an existing IR, create a new IR, or emit through a textual
  handoff.
- Any accepted refactor follow-up is split into executable leaves before code
  changes start.
- Live docs, roadmap status, and task-tree state stay synchronized.

## Task Tree

- ID: `FSMGEN-IR-AUDIT`
  Status: `active`
  Goal: `Audit and rationalize FSMGen IR ownership, boundaries, and creation policy.`
  Children: `FSMGEN-IR-AUDIT.1`, `FSMGEN-IR-AUDIT.2`,
  `FSMGEN-IR-AUDIT.3`, `FSMGEN-IR-AUDIT.4`

- ID: `FSMGEN-IR-AUDIT.1`
  Status: `done`
  Goal: `Inventory current IR and IR-like structures.`
  Acceptance: `The task file or companion doc lists all known IR structures,
  including ISF AST/lowering IR, CoreAST, IntentHIR, LoweredRTLIR,
  StructuralRTLIR, composition parse/plan objects, backend helper structures,
  and normalized report contracts, with producer and consumer notes.`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `FSMGEN-IR-AUDIT.1: inventory current IR surfaces`

- ID: `FSMGEN-IR-AUDIT.2`
  Status: `done`
  Goal: `Classify canonical boundaries versus local projections.`
  Acceptance: `Every inventoried structure has a phase classification,
  source-of-truth status, public/private status, and reason it should be kept,
  merged, or treated as derived data.`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `FSMGEN-IR-AUDIT.2: classify IR boundaries`

- ID: `FSMGEN-IR-AUDIT.3`
  Status: `active`
  Goal: `Define the repo-local policy for adding or extending IRs.`
  Acceptance: `The policy says what a new IR must document before landing:
  owner, producer, consumers, invariants, serialization/report contract,
  defensive-copy boundary, and migration/retirement plan if temporary.`
  Verification: `pending`
  Commit: `pending`

- ID: `FSMGEN-IR-AUDIT.4`
  Status: `proposed`
  Goal: `Propose consolidation or standardization follow-up slices.`
  Acceptance: `Concrete follow-up leaves are created only where the audit
  finds actionable duplication, unsafe handoffs, or missing canonical
  ownership. Non-actionable differences are documented as deliberate.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

This tree is active. The current PNT frontier is the repo-local policy for
adding, extending, freezing, or retiring IR boundaries.

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `FSMGEN-IR-AUDIT.1` | `done` | Completed factual inventory before prescribing consolidation. |
| 2 | `FSMGEN-IR-AUDIT.2` | `done` | Classified which inventoried structures are canonical phase boundaries versus private/local projections. |
| 3 | `FSMGEN-IR-AUDIT.3` | `active` | Turn the inventory/classification into repo-local policy for future IR changes. |

## Initial IR Inventory Targets

The first inventory leaf should at least inspect these families:

- ISF parse/actor shell: `FSM::Adapter::ISF` and
  `FSM::Adapter::ISF::LispishAdapter`.
- ISF scheduling/lowering IR: `FSM::Scheduler::ISF::LoweringIR` plus the
  `.fsm`, JSON, and generated-top emitters that consume it.
- Direct `.fsm` syntax and semantic model: `FSM::CoreAST` and related parser
  products.
- Forward compiler IRs: `FSM::IR::IntentHIR`, `FSM::IR::LoweredRTLIR`, and
  `FSM::IR::StructuralRTLIR`.
- Composition structures: `FSM::Composition::Top`, ports, child declarations,
  `RealizedInstance`, `Plan`, nets, links, and shared-datapath metadata.
- Backend/emission structures that are IR-like but not currently named as IR.
- Normalized public report contracts under `FSM::Support::NormalizedSemantic*`
  and related serializable snapshot helpers.

## Inventory: Current IR And IR-Like Structures

`FSMGEN-IR-AUDIT.1` inspected the named IR modules, parser outputs,
composition planning objects, backend-local AST/intermediate structures, and
public report projections. This is factual inventory only; canonical/private
classification and consolidation decisions are left to later leaves.

| Surface | Owners / files | Producers | Consumers | Serialized / report surface | Mutability and source-of-truth notes |
| --- | --- | --- | --- | --- | --- |
| Raw Lispish source AST | `Lispish::multi`, [FSM::Pipeline::SourceFrontend](../../perl/FSM/Pipeline/SourceFrontend.pm), [FSM::Adapter::ISF::Parser](../../perl/FSM/Adapter/ISF/Parser.pm) | Source-file parse for `.fsm`, `.dt`, `.top`, `.pkg`, and `.isf` roots | Source classifier, direct parser, composition parser, ISF Lispish adapter, extension `after_parse_source` context | In-process `raw_ast` result branch plus shell-only `HDLGeneratorRawASTContract`; not a stable external JSON schema | Mutable nested arrays treated as parser/debug input snapshots, not semantic truth. |
| Direct `.fsm` / `.dt` semantic CoreAST | [FSM::CoreAST](../../perl/FSM/CoreAST.pm), [FSM::Adapter::FSMGenFull::Parser](../../perl/FSM/Adapter/FSMGenFull/Parser.pm), [FSM::Adapter::FSMGenFull](../../perl/FSM/Adapter/FSMGenFull.pm) | Direct source parser after source classification and package/type resolution | `IntentHIRBuilder`, `GeneratedModuleEmitter`, `FlattenedDT`, signal analyzer, direct-root checks | Raw object remains in-process only; public surfaces are semantic summaries and `HDLGeneratorFSMModuleContract` fallback keys | Blessed object graph is the canonical in-process direct-root semantic model before forward IR extraction. |
| Legacy/backend expression AST | [FSM::AST::Node](../../perl/FSM/AST/Node.pm), [FSM::AST::Utils](../../perl/FSM/AST/Utils.pm), [FSM::ExpressionNamer](../../perl/FSM/ExpressionNamer.pm), [FSM::GlobalASTManager](../../perl/FSM/GlobalASTManager.pm) | Backend capture, expression naming, and factorization paths | `ASTFactorization`, `EnableGraph::*`, SystemVerilog backend support owners | No public report contract; some statistics expose counts or rendered expressions | Backend-local expression representation. It overlaps with `CoreAST` expression nodes but is not a source-level canonical IR. |
| ISF normalized Lispish form | [FSM::Adapter::ISF::LispishAdapter](../../perl/FSM/Adapter/ISF/LispishAdapter.pm) | Raw Lispish parse normalization for `.isf` | `FSM::Adapter::ISF::Parser` | None | Short-lived parsed-syntax adapter shape. It is intentionally discarded after typed actor construction. |
| ISF typed actor hash | [FSM::Adapter::ISF::Parser](../../perl/FSM/Adapter/ISF/Parser.pm), [FSM::Adapter::ISF](../../perl/FSM/Adapter/ISF.pm) | `.isf` parser after defaults, package/type/enum resolution, library resolution, ATL metadata resolution | [FSM::Scheduler::ISF::LoweringIR](../../perl/FSM/Scheduler/ISF/LoweringIR.pm), parser-focused tests | Raw actor hash is private. Bounded facts surface through schedule JSON, public contract metadata, and generated `.fsm` artifacts | Canonical parser output for ISF within the scheduler path, but not frozen for downstream consumers. |
| ISF actor-network metadata | `actor_network` subhash from [FSM::Adapter::ISF::Parser](../../perl/FSM/Adapter/ISF/Parser.pm) and [FSM::Scheduler::ISF::LoweringIR](../../perl/FSM/Scheduler/ISF/LoweringIR.pm) | Direct ATL `(instance ...)`, `(group ...)`, `(trigger actor.tx)`, `(await actor.event)`, and selected route drive parsing/lowering | ISF lowerer, schedule JSON emitter, composition-top emitter for generated ATL tops | Bounded `actor_network.*` schedule-report keys and generated top `.fsm` / `?top` artifacts | Private metadata in the parser/lowerer; public truth is the bounded report/artifact subset, not the whole hash. |
| ISF scheduler `LoweringIR` | [FSM::Scheduler::ISF::LoweringIR](../../perl/FSM/Scheduler/ISF/LoweringIR.pm) | ISF typed actor hash plus generated children, library uses, clock-domain partitioning, and rule/transaction lowering | [Emitter::FSM](../../perl/FSM/Scheduler/ISF/Emitter/FSM.pm), [Emitter::JSON](../../perl/FSM/Scheduler/ISF/Emitter/JSON.pm), [Emitter::CompositionTop](../../perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm), ISF module emitter | Scheduled `.fsm`, schedule JSON `schema_version: 1`, generated composition top source, generated child artifacts | Mutable hash assembled by the lowerer and finalized with assignment provenance/conflict data. The full hash is private. |
| ISF domain partition and CDC metadata | `domain_partition` and `crossings` in [FSM::Scheduler::ISF::LoweringIR](../../perl/FSM/Scheduler/ISF/LoweringIR.pm), JSON emitter domain helpers | Parser clock-domain declarations and acknowledged-event crossing lowering | Multi-domain ISF emitter/report path, generated domain `.fsm` artifacts, CDC module emitter | Public schedule JSON `clock_domains[]` and `crossings[]`; generated domain/top artifacts | Private scheduler sub-IR for multi-clock planning; public report entries are bounded projections. |
| Package/spec symbol model | [FSM::Package::Spec](../../perl/FSM/Package/Spec.pm), [FSM::Package::Symbols](../../perl/FSM/Package/Symbols.pm), package parser/support modules | `?pkg` roots, direct-root declarations, composition imports, ISF package imports | Direct parser, composition parser/planners, ISF parser/lowerer, `IntentHIRBuilder` symbol contract | Optional normalized `symbol_contract`, resolved-package-import shell contracts, generated package roots | In-process symbol tables and package specs are shared semantic support structures, not backend IR. |
| Composition parsed spec | [FSM::Composition::Spec](../../perl/FSM/Composition/Spec.pm), [Top](../../perl/FSM/Composition/Top.pm), [Instance](../../perl/FSM/Composition/Instance.pm), [Port](../../perl/FSM/Composition/Port.pm), [PortsBlock](../../perl/FSM/Composition/PortsBlock.pm), [WiringBlock](../../perl/FSM/Composition/WiringBlock.pm), [Link](../../perl/FSM/Composition/Link.pm), composition parser | `?top` source parser after source classification and package import resolution | `PlanBuilder`, package import resolver, extension/source-info surfaces | Raw `composition_spec` branch is shell-only; sanitized summaries appear through semantic reports | Parsed composition syntax/semantic object graph. It is a pre-plan input, not final connectivity truth. |
| Realized composition child carrier | [FSM::Composition::RealizedInstance](../../perl/FSM/Composition/RealizedInstance.pm), `GeneratedChildRealizer`, `RTLChildRealizer` | Child realization during `PlanBuilder` | `Composition::Plan`, `StructuralRTLIRBuilder`, composition top emitter/statistics/report builders | In-process child `module_info` and HDL payloads; public summary through composition reports and module info | Runtime carrier for one child instance. It normalizes bindings but is not itself a public IR. |
| Composition plan | [FSM::Composition::Plan](../../perl/FSM/Composition/Plan.pm), [PlanBuilder](../../perl/FSM/Composition/PlanBuilder.pm), `C1PlanBuilder`, [LinkedPlanBuilder](../../perl/FSM/Composition/LinkedPlanBuilder.pm) | Composition parsed spec plus realized children, top-port inference, endpoint resolution, carrier-net allocation, same-name/explicit links | `StructuralRTLIRBuilder`, `IntentHIRBuilder`, `LoweredRTLIRBuilder`, `ProvenanceReportBuilder`, `ResultMetadataBuilder`, structural emitter | `composition_plan_snapshot`, sanitized composition provenance report, semantic composition summary | Canonical composition-planning object for the composition lane; raw plan remains in-process/private. |
| Structural connection expressions | [FSM::IR::StructuralRTLIR::ConnectionExpr](../../perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm), `ActualLiteralSupport`, `SourceExpressionSpecSupport`, `LinkedPlanBuilder` | Composition link/source-expression and actual-literal lowering | `RealizedInstance`, `StructuralRTLIRBuilder`, structural emitter, provenance/report helpers | Binding summaries and rendered connection text in structural HDL/report projections | Hash-node expression family for structural actual connections. It is a meaningful structural API but not a full source AST. |
| Forward semantic HIR | [FSM::IR::IntentHIR](../../perl/FSM/IR/IntentHIR.pm), [IntentHIRBuilder](../../perl/FSM/IR/IntentHIRBuilder.pm) | Direct CoreAST modules and composition plans | `GeneratedModuleInfoBuilder`, `LoweredRTLIRBuilder`, `ProvenanceReportBuilder`, `ResultMetadataBuilder`, normalized semantic report | `semantic.forward_ir.intent_hir`, `module_info.intent_hir`, contract owners under `NormalizedSemantic*` | Named forward IR. Object accessors clone payloads; public surface is bounded and sanitized. |
| Forward lowered RTL IR | [FSM::IR::LoweredRTLIR](../../perl/FSM/IR/LoweredRTLIR.pm), [LoweredRTLIRBuilder](../../perl/FSM/IR/LoweredRTLIRBuilder.pm) | Direct generated-module analysis/backend state and composition plan plus structural/semantic/shared-datapath inputs | `GeneratedModuleInfoBuilder`, `ResultMetadataBuilder`, normalized semantic report, assertion postprocessing | `semantic.forward_ir.lowered_rtl_ir`, `module_info.lowered_rtl_ir`, storage/drive family summaries | Named forward IR for lowered grouped facts; object accessors clone payloads. |
| Forward structural RTL IR | [FSM::IR::StructuralRTLIR](../../perl/FSM/IR/StructuralRTLIR.pm), [StructuralRTLIRBuilder](../../perl/FSM/IR/StructuralRTLIRBuilder.pm) | Direct generated-module info or composition plan | [StructuralRTLIREmitter](../../perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm), `ProvenanceReportBuilder`, `IntentHIRBuilder`, `LoweredRTLIRBuilder`, normalized semantic report | `semantic.forward_ir.structural_rtl_ir`, `module_info.structural_rtl_ir`, structural HDL module text | Named forward IR for netlist-like connectivity. It is the clearest backend-facing structural boundary today. |
| Generated `module_info` compatibility surface | [GeneratedModuleInfoBuilder](../../perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm), [ResultMetadataBuilder](../../perl/FSM/Composition/ResultMetadataBuilder.pm) | Direct and composition orchestrators after IR extraction and backend/plan analysis | Runtime assertion augmentation, normalized reports, CLI/result consumers, contract modules | Public in-process result branch plus bounded `HDLGeneratorModuleInfoContract`; embeds forward IR hashes | Compatibility/result metadata surface. It overlaps with forward IR by design and should not become a second canonical IR. |
| Composition provenance/report projection | [ProvenanceReportBuilder](../../perl/FSM/Composition/ProvenanceReportBuilder.pm), `CompositionReportContract` | Composition plan plus structural/intent IR | `ResultMetadataBuilder`, normalized semantic report, CLI summaries | Sanitized `semantic.composition` and composition report contracts | Report projection over plan/structural facts. It is public-facing evidence, not planning truth. |
| Normalized semantic report | [FSM::Support::NormalizedSemanticReport](../../perl/FSM/Support/NormalizedSemanticReport.pm) and `NormalizedSemantic*Contract` modules | Successful or failed generation/check paths | Downstream tools, embedders, capability manifest, regression contracts | JSON `normalized_semantic_schema_version: 1` with `semantic.module`, `semantic.forward_ir`, `semantic.composition`, diagnostics, snapshots | Public sanitized contract. It freezes report shape, not raw compiler internals. |
| Serializable snapshots | [SerializableCompositionPlanSnapshot](../../perl/FSM/Support/SerializableCompositionPlanSnapshot.pm), [SerializableGenerationResultSnapshot](../../perl/FSM/Support/SerializableGenerationResultSnapshot.pm), [SerializableDiagnosticSummary](../../perl/FSM/Support/SerializableDiagnosticSummary.pm) | Report builders from in-process plan/result/diagnostic objects | Normalized semantic report, public contract tests | JSON-safe bounded snapshots | Deliberately shallow projections that avoid exporting raw object graphs. |
| Direct backend local intermediate state | [FSM::HDL::FlattenedDT](../../perl/FSM/HDL/FlattenedDT.pm), [FSM::Synthesis::EnableGraph](../../perl/FSM/Synthesis/EnableGraph.pm), `EnableGraph::*`, `ConsolidatedIntermediate*` backend support modules | Direct backend flattening, enable-graph capture, factorization, consolidated intermediate planning | SystemVerilog/Verilog backend emitters, generated-module statistics, lowered RTL metadata builders | HDL text, backend statistics, selected generated-module metadata | Backend-local mutable implementation state. It can inform lowered summaries, but it is not a stable cross-phase IR. |

Inventory observations for later leaves:

- `IntentHIR`, `LoweredRTLIR`, and `StructuralRTLIR` are the only currently
  named forward IR classes with explicit builders and public normalized
  semantic projections.
- ISF `LoweringIR` is a real scheduler phase boundary, but it is currently a
  private hash-based compiler IR whose public contract is the emitted `.fsm`,
  schedule JSON, and generated composition artifacts.
- `module_info` is intentionally a compatibility/result surface. It embeds or
  mirrors forward IR facts and should be treated carefully in the policy leaf
  to avoid making it a competing canonical IR.
- Composition has both a raw parsed spec and a planned connectivity object.
  `Composition::Plan` is the planner truth for composition lowering, while
  `composition_plan_snapshot` and provenance reports are reviewable public
  projections.
- The backend still carries legacy pure-AST and consolidated-intermediate
  state. Those structures are local implementation projections unless a later
  leaf promotes one of them to an explicit phase boundary.

## Classification: Canonical Boundaries And Local Projections

`FSMGEN-IR-AUDIT.2` classifies the inventory without changing runtime
behavior. The classification separates three meanings that were easy to blur:
canonical in-process compiler truth, public/report truth, and private local
implementation state.

| Surface | Phase classification | Source-of-truth status | Public/private status | Disposition |
| --- | --- | --- | --- | --- |
| Raw Lispish source AST | Parsed syntax | Parser/debug input truth only before semantic parsing | Private in-process, with shell-only debug/contract exposure | Keep as mutable parser input snapshot. Do not promote as semantic IR or downstream schema. |
| Direct `.fsm` / `.dt` semantic CoreAST | Semantic intent | Canonical direct-root semantic truth before forward IR extraction | Private object graph; public summaries are projections | Keep as direct semantic model. Future direct-root changes should extend this or documented forward IRs, not invent a parallel direct semantic carrier. |
| Legacy/backend expression AST | Backend/emission helper | Local backend expression truth during naming/factorization | Private implementation state | Keep as backend-local for now. Later consolidation may align expression ownership, but it is not a public or source-level canonical IR. |
| ISF normalized Lispish form | Parsed syntax adapter | Temporary source-shape truth during `.isf` parser normalization | Private | Keep as short-lived adapter output. It should stay discardable after typed actor construction. |
| ISF typed actor hash | Semantic intent plus parser-normalized actor shell | Canonical in-process ISF parser output before scheduler lowering | Private; bounded facts project to reports/artifacts | Keep private. If it grows further, the policy leaf should require owner/invariant documentation before turning it into a named typed IR object. |
| ISF actor-network metadata | Scheduling/structural intent metadata | Canonical ATL metadata inside the ISF parser/lowerer handoff | Private internals with bounded public schedule/artifact projections | Keep as feature-owned lowerer metadata. Public truth is `actor_network` schedule summaries and generated artifacts, not the raw hash. |
| ISF scheduler `LoweringIR` | Scheduling and lowered behavior | Canonical ISF scheduling truth until `.fsm`, schedule JSON, and generated-top emission | Private mutable compiler IR | Keep as private scheduler phase boundary. It is eligible for helper extraction/typing, not for downstream raw export. |
| ISF domain partition and CDC metadata | Scheduling / CDC planning | Canonical multi-domain planning truth inside `LoweringIR` | Private internals with bounded `clock_domains[]`, `crossings[]`, and artifact projections | Keep as a `LoweringIR` sub-boundary. Public reports remain bounded and versioned. |
| Package/spec symbol model | Semantic support | Canonical package/symbol/type truth shared by parser and planner paths | Internal support structures with selected public projections | Keep as shared semantic support, not as backend IR. |
| Composition parsed spec | Parsed syntax plus composition intent input | Canonical authored composition input before planning | Private object graph with sanitized report summaries | Keep as pre-plan input. It must not compete with `Composition::Plan` for final connectivity truth. |
| Realized composition child carrier | Composition planning carrier | Canonical per-child realization payload inside planning | Private runtime carrier | Keep as a local planning carrier. Public consumers should use plan/report projections instead. |
| Composition plan | Composition planning and structural/connectivity | Canonical in-process composition connectivity truth | Private plan object with bounded public snapshots/provenance | Keep as the canonical composition phase boundary. Snapshot/provenance surfaces are derived review evidence. |
| Structural connection expressions | Structural/connectivity expression API | Canonical structural actual-binding expression nodes once lowered | Internal structural API, public only through rendered/binding summaries | Keep. It is a meaningful API under the structural layer, not a full source AST. |
| Forward semantic HIR | Semantic intent forward IR | Canonical forward semantic IR boundary | Internal object with bounded normalized semantic and `module_info` projections | Keep as a canonical forward IR. Future semantic projections should prefer extending this layer. |
| Forward lowered RTL IR | Lowered behavior forward IR | Canonical lowered-fact IR boundary | Internal object with bounded normalized semantic and `module_info` projections | Keep as a canonical forward IR. Future lowered summaries should prefer extending this layer. |
| Forward structural RTL IR | Structural/connectivity forward IR | Canonical backend-facing structural IR boundary | Internal object with bounded normalized semantic, `module_info`, and HDL projections | Keep as a canonical forward IR and the preferred structural backend boundary. |
| Generated `module_info` compatibility surface | Report/contract projection | Compatibility/result truth for legacy callers, not compiler semantic truth | Public in-process result surface with bounded contract keys | Keep as a compatibility mirror. Do not let it become a second canonical IR beside forward IR objects. |
| Composition provenance/report projection | Report/contract projection | Derived evidence from plan and structural/intent facts | Public sanitized projection | Keep as review/debug evidence. `Composition::Plan` remains planning truth. |
| Normalized semantic report | Report/contract projection | Canonical public JSON/report shape, not raw compiler truth | Public versioned schema | Keep as the downstream-facing contract. It freezes sanitized projection shape only. |
| Serializable snapshots | Report/contract projection | Derived bounded snapshots for JSON-safe reporting | Public bounded snapshots | Keep as shallow projections that protect raw objects from export. |
| Direct backend local intermediate state | Backend/emission | Local emission truth only inside the direct backend | Private implementation state | Keep private. It may feed lowered summaries, but it should not become cross-phase IR unless a future refactor creates a named boundary. |

Classification conclusions:

- Canonical in-process compiler boundaries today are `CoreAST` for direct
  roots, the ISF typed actor hash plus private `LoweringIR` for the ISF
  scheduler path, `Composition::Plan` for composition connectivity, and the
  three named forward IRs.
- Canonical public downstream truth is not any raw compiler object. It is the
  bounded schedule JSON, normalized semantic JSON, public contract metadata,
  emitted `.fsm`/HDL artifacts, and generated composition artifacts.
- `module_info`, provenance reports, and serializable snapshots are useful and
  stable only as compatibility/report projections. They must not be treated as
  independent compiler truth.
- Backend-local expression/intermediate structures remain implementation
  details. A later follow-up may clean or standardize them, but `.2` does not
  select that refactor.

## Decisions

- `2026-05-14`: Multiple IRs are acceptable when they represent distinct
  compiler phases or public projection boundaries. The audit should reduce
  accidental duplication and unclear ownership, not collapse the compiler into
  a single mega-IR.
- `2026-05-14`: Future IR additions should be treated as architectural
  decisions. A new IR needs an owner, phase name, invariants, producer,
  consumers, public/private status, and an explanation of why extending an
  existing IR or using an existing handoff is not enough.
- `2026-05-14`: The current `.isf -> ISF LoweringIR -> scheduled .fsm text ->
  normal .fsm pipeline -> forward/backend IRs -> SV` flow is valid as a
  shipped boundary, but it should be audited as part of this tree because the
  textual `.fsm` handoff may or may not remain the best long-term boundary.
- `2026-05-20`: Activated the tree after all active R14 task-tree frontiers
  closed. The first leaf is inventory only; consolidation policy and refactor
  follow-ups remain later leaves.
- `2026-05-20`: `FSMGEN-IR-AUDIT.2` classifies the current boundaries without
  collapsing them: direct `CoreAST`, private ISF scheduler state,
  `Composition::Plan`, and the named forward IRs have legitimate phase roles;
  report and compatibility surfaces remain projections, not competing IR
  truth.

## Open Questions

- Should ISF eventually lower into an existing FSM/CoreAST or forward IR
  directly, or is the scheduled `.fsm` textual handoff the right reviewable
  and debuggable boundary?
- What exact repo-local policy should future work follow before adding,
  extending, freezing, or retiring an IR boundary?
- Which classifications deserve concrete follow-up refactors after the policy
  leaf, rather than documentation only?

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-14` | `FSMGEN-IR-AUDIT` | `git diff --check -- docs/tasks/FSMGEN-IR-AUDIT.md docs/TASK_TREE.md README.md ROADMAP_STATUS.md CHANGES.md DEVELOPMENT_NOTES.md MEMORY.md LIVE_ACHIEVEMENT_STATUS.md` | `pass` |
| `2026-05-20` | `FSMGEN-IR-AUDIT.1` | `git diff --check`; `mdbook build docs/book` | `pass` |
| `2026-05-20` | `FSMGEN-IR-AUDIT.2` | `git diff --check`; `mdbook build docs/book` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `FSMGEN-IR-AUDIT` | `FSMGEN-IR-AUDIT: capture IR audit task tree` | Created proposed task tree. |
| `FSMGEN-IR-AUDIT.1` | `FSMGEN-IR-AUDIT.1: inventory current IR surfaces` | Inventoried current IR and IR-like structures and advanced `.2` classification. |
| `FSMGEN-IR-AUDIT.2` | `FSMGEN-IR-AUDIT.2: classify IR boundaries` | Classified current IR boundaries/projections and advanced `.3` policy. |

## Changelog

- `2026-05-20`: Completed `FSMGEN-IR-AUDIT.2` classification and advanced the
  active frontier to `FSMGEN-IR-AUDIT.3` policy.
- `2026-05-20`: Completed `FSMGEN-IR-AUDIT.1` factual inventory and advanced
  the active frontier to `FSMGEN-IR-AUDIT.2` classification.
- `2026-05-14`: Created proposed task tree to capture IR inventory and
  consolidation audit work without interrupting active `R14` ISF feature
  delivery.
