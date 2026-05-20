# IR-EXPRESSION-AST-OWNERSHIP: Expression AST Ownership Audit

## Metadata

- Tree ID: `IR-EXPRESSION-AST-OWNERSHIP`
- Status: `active`
- Roadmap lane: `architecture backlog`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Rationalize expression representation ownership across direct `CoreAST`
expressions, legacy/backend `FSM::AST::*` nodes, and structural
`ConnectionExpr` nodes so each representation has an explicit phase role,
conversion owner, and public/private boundary.

## Non-Goals

- Do not collapse source-level expressions, backend factoring expressions, and
  structural connection expressions into one universal node type merely for
  naming uniformity.
- Do not change expression semantics before the conversion/ownership map is
  complete.
- Do not expose private expression nodes as downstream APIs.

## Acceptance Criteria

- Every live expression representation has a phase role and owner.
- Conversion points between expression representations are listed.
- Any redundant conversion or unsafe ownership ambiguity is split into
  behavior-preserving implementation leaves before code changes begin.
- Public docs/contracts are updated only when downstream-visible expression
  reporting changes.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `IR-EXPRESSION-AST-OWNERSHIP`
  Status: `active`
  Goal: `Rationalize expression AST ownership and conversion boundaries.`
  Children: `IR-EXPRESSION-AST-OWNERSHIP.1`,
  `IR-EXPRESSION-AST-OWNERSHIP.2`, `IR-EXPRESSION-AST-OWNERSHIP.3`

- ID: `IR-EXPRESSION-AST-OWNERSHIP.1`
  Status: `done`
  Goal: `Inventory expression representations and conversion sites.`
  Acceptance: `The task file lists direct CoreAST expressions, backend
  FSM::AST nodes, structural ConnectionExpr nodes, and conversion/reporting
  sites with owners and consumers.`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `74456538 IR-EXPRESSION-AST-OWNERSHIP.1: inventory expression surfaces`

- ID: `IR-EXPRESSION-AST-OWNERSHIP.2`
  Status: `done`
  Goal: `Classify deliberate versus accidental expression duplication.`
  Acceptance: `Each representation is marked deliberate phase separation or
  actionable duplication, with no behavior-bearing refactor selected without
  a follow-up leaf.`
  Verification: `git diff --check`; `mdbook build docs/book`
  Commit: `pending`

- ID: `IR-EXPRESSION-AST-OWNERSHIP.3`
  Status: `active`
  Goal: `Create implementation leaves for actionable expression ownership fixes.`
  Acceptance: `Only concrete redundant conversions or unsafe ownership gaps
  become executable follow-up leaves with verification plans.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

This tree is active. The current PNT frontier creates concrete implementation
leaves for the actionable ownership fixes selected by `.2`.

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `IR-EXPRESSION-AST-OWNERSHIP.1` | `done` | Expression surfaces and conversion sites are inventoried. |
| 2 | `IR-EXPRESSION-AST-OWNERSHIP.2` | `done` | Deliberate phase boundaries and actionable duplication are classified. |
| 3 | `IR-EXPRESSION-AST-OWNERSHIP.3` | `active` | Actionable concerns need concrete behavior-preserving follow-up leaves before code changes. |

## Expression Representation Inventory

`IR-EXPRESSION-AST-OWNERSHIP.1` found the following live expression surfaces
and handoff points. This inventory is factual only; classification happens in
`.2`.

| Surface | Owner/files | Phase role | Producers | Consumers / conversion sites | Notes |
| --- | --- | --- | --- | --- | --- |
| Direct semantic expression AST | [perl/FSM/CoreAST.pm](../../perl/FSM/CoreAST.pm), [perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm](../../perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm) | Source-level semantic model for parsed `.fsm` expressions, conditions, assignments, aggregate refs, parameters, literals, concat, function calls, and typed signal access. | Full `.fsm` parser through `ExpressionBuilder`; package symbol resolution; ISF-generated `.fsm` text when it re-enters the normal direct parser. | `to_systemverilog` renderers, direct parser assignment/control nodes, `FSM::Adapter::FSMGenFull::SignalAnalyzer`, `FSM::Synthesis::EnableGraph::*`, `FSM::Package::AggregateExpressionTypeSupport`, and `FSM::ExpressionNamer`. | This is the broadest expression source-of-truth in the direct path and carries widths/types through `CoreAST::SignalRef`, `ParameterRef`, `AggregateRef`, `Literal`, `BinaryOp`, `UnaryOp`, `Concatenation`, `IndexedRef`, `ConditionalExpression`, and `FunctionCall`. |
| Backend pure AST nodes | [perl/FSM/AST/Node.pm](../../perl/FSM/AST/Node.pm) | Backend-local enable/factorization expression nodes for signal refs, literals, unary/binary operations, and logical constants. | `FSM::Synthesis::EnableGraph::CaptureSupport` converts condition/test selectors from `CoreAST` into `FSM::AST::*`; `EnableSupport` and `AssignmentSupport` synthesize enable trees. | `FSM::Synthesis::EnableGraph::ASTSupport`, factorization/filter/width helpers under `FSM::Synthesis::EnableGraph::*` and `FSM::HDL::FlattenedDT::Backend::SystemVerilog::*`, and `FSM::ExpressionNamer` naming paths. | This family is intentionally smaller than `CoreAST`: it is useful for backend enable logic, but it does not carry the full source semantic contract. |
| Backend AST utility package | [perl/FSM/AST/Node.pm](../../perl/FSM/AST/Node.pm), [perl/FSM/AST/Utils.pm](../../perl/FSM/AST/Utils.pm) | Convenience factory surface for backend AST nodes. | Callers mostly load `FSM::AST::Node` and use the in-file `FSM::AST::Utils` package. | `CaptureSupport`, `EnableSupport`, and `AssignmentSupport`. | There are two tracked `FSM::AST::Utils` package definitions. The in-file package creates `FSM::AST::Literal` / `BinaryOp` / `UnaryOp` correctly; the standalone file references `FSM::AST::Node::Literal` / `BinaryOp` / `UnaryOp`, which do not match the classes defined in `Node.pm`. `.2` must classify this as either unused residue or an actionable ownership fix. |
| Legacy ExpressionNamer hash AST | [perl/FSM/ExpressionNamer.pm](../../perl/FSM/ExpressionNamer.pm) | Backward-compatible string-expression parser/namer surface. | `parse_and_name_expression` and `parse_expression` parse expression strings into legacy hash nodes with `type`, `op`, `left`, `right`, `operand`, `name`, `width`, and literal metadata. | `generate_signal_name`, `infer_width`, `ast_to_verilog`, string-to-name caches, and fallback naming paths. | This is not the same as `FSM::AST::*`. It is a private compatibility surface and is a primary classification target because it overlaps with object AST naming. |
| ExpressionNamer object-AST naming | [perl/FSM/ExpressionNamer.pm](../../perl/FSM/ExpressionNamer.pm) | Naming/factorization metadata over `FSM::CoreAST::*` and `FSM::AST::*` objects. | Direct callers pass object ASTs to `name_ast_expression` / `name_ast_node`; unknown object ASTs fall back through `to_systemverilog` then legacy string parsing. | Signal-definition cache, width inference, semantic name generation, and backend intermediate naming. | This owner currently straddles three input forms: `CoreAST` objects, backend `FSM::AST` objects, and legacy hash/string ASTs. |
| Tracked ExpressionNamer copy | [perl/FSM/ExpressionNamer.pm.new](../../perl/FSM/ExpressionNamer.pm.new) | Tracked source residue declaring the same `FSM::ExpressionNamer` package name as the live module. | None found in `bin`, `perl`, `t`, or `docs` references. | None found by static search. | Because it is tracked and package-identical, `.2` must classify whether this is deliberate archival residue or should become a cleanup leaf. No code was changed in `.1`. |
| Global AST manager | [perl/FSM/GlobalASTManager.pm](../../perl/FSM/GlobalASTManager.pm) | Claimed centralized global AST factorization/naming manager. | Reads `lhs_assignments` and `assignment_analysis` string fields and asks `expr_namer->parse_expression(...)` for ASTs. | Structural duplicate analysis, factorization decisions, sub-AST naming. | Inventory found a contract mismatch worth classifying: `collect_ast` accepts only blessed AST objects, while `ExpressionNamer->parse_expression` returns legacy hash ASTs. This may make the manager stale or ineffective for those paths. |
| EnableGraph expression capture/render surfaces | [perl/FSM/Synthesis/EnableGraph/CaptureSupport.pm](../../perl/FSM/Synthesis/EnableGraph/CaptureSupport.pm), [perl/FSM/Synthesis/EnableGraph/ASTSupport.pm](../../perl/FSM/Synthesis/EnableGraph/ASTSupport.pm), [perl/FSM/Synthesis/EnableGraph/FactorizationSupport.pm](../../perl/FSM/Synthesis/EnableGraph/FactorizationSupport.pm), [perl/FSM/Synthesis/EnableGraph/FactorizationPolicySupport.pm](../../perl/FSM/Synthesis/EnableGraph/FactorizationPolicySupport.pm) | Direct backend capture-time and render-time expression handoff. | `CaptureSupport` stores `lhs_ast`, `conditions_ast`, string `rhs`, and assignment intent; it converts conditions/tests from `CoreAST` into backend AST nodes and renders RHS `CoreAST` expressions to strings for assignment metadata. | `ASTSupport` renders both `FSM::AST::*` and `FSM::CoreAST::*`; factorization support updates substituted ASTs in assignment/enable structures and reparses some RHS strings through `ExpressionNamer`. | This is the densest conversion boundary between source semantic AST, backend AST, and string RHS metadata. |
| Package aggregate expression type support | [perl/FSM/Package/AggregateExpressionTypeSupport.pm](../../perl/FSM/Package/AggregateExpressionTypeSupport.pm) | Type-shape inference for aggregate/list/record expression fragments. | Receives `FSM::CoreAST::Concatenation`, `SignalRef`, `AggregateRef`, and `IndexedRef` from direct parser and backend capture helpers. | Direct parser aggregate contracts and enable-graph fragment typing. | This is a consumer of `CoreAST`; it does not define a new expression node family. |
| Structural connection expressions | [perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm](../../perl/FSM/IR/StructuralRTLIR/ConnectionExpr.pm) | Backend-neutral structural actual-binding expression helpers for composition/top structural RTL. | `signal_ref_expr`, `member_access_expr`, `index_access_expr`, `bit_select_expr`, `slice_expr`, `concat_expr`, `repeat_expr`, `bit_vector_literal_expr`, `open_expr`, and `normalized_binding`. | `StructuralRTLIRBuilder`, `LinkedPlanBuilder`, `StructuralRTLIREmitter`, composition snapshots/provenance, and binding summaries. | This hash-node family is deliberately structural-connection oriented, not a source semantic expression AST. |
| Composition source-expression specs | [perl/FSM/Composition/SourceExpressionSpecSupport.pm](../../perl/FSM/Composition/SourceExpressionSpecSupport.pm), [perl/FSM/Composition/LinkedPlanBuilder.pm](../../perl/FSM/Composition/LinkedPlanBuilder.pm) | Pre-structural composition endpoint expression specs for explicit wiring sources. | Parses top/child bit-select, slice, aggregate path, concat, repeat, literal operands, and child-base collection from wiring endpoint text. | `LinkedPlanBuilder` resolves widths/types, lowers specs into `ConnectionExpr` nodes, creates child carriers, and rebinds child-source expressions. | This is an intermediate planner spec, private to composition planning. Its public output is structural binding metadata/provenance, not the spec hash itself. |
| Composition actual literals | [perl/FSM/Composition/ActualLiteralSupport.pm](../../perl/FSM/Composition/ActualLiteralSupport.pm) | Composition actual payload parser/lowerer for open and numeric actuals. | Parses `=open`, scalar bits, sized/unsized binary/octal/decimal/hex, signed variants, and aggregate literal payloads. | `LinkedPlanBuilder` asks for target-width-bound `connection_expr` values, usually `open_expr` or `bit_vector_literal_expr`. | This is a literal-lowering owner, not a general expression AST. |
| ISF expression payloads | [perl/FSM/Adapter/ISF/Parser.pm](../../perl/FSM/Adapter/ISF/Parser.pm), [perl/FSM/Scheduler/ISF/LoweringIR.pm](../../perl/FSM/Scheduler/ISF/LoweringIR.pm), [perl/FSM/Scheduler/ISF/Emitter/FSM.pm](../../perl/FSM/Scheduler/ISF/Emitter/FSM.pm) | Intent-scheduler local expression payloads represented as Lispish scalars/arrays until emitted as scheduled `.fsm` text or schedule metadata. | ISF parser validates rule guards/actions, activation bindings, wait counts, drive bodies, ATL data movement, and enum/aggregate-path restrictions over raw scalar/list expression shapes. | `LoweringIR` stringifies with `_format_isf_expr`, validates domain reads/widths, builds guards/assignments, and emits scheduled `.fsm` where the direct parser later rebuilds `CoreAST`; schedule JSON carries formatted expression text and metadata. | This is a private scheduler expression representation. It should not be conflated with direct `CoreAST` unless the handoff has crossed into generated `.fsm` parsing. |

## Expression Ownership Classification

`IR-EXPRESSION-AST-OWNERSHIP.2` classifies the inventory into deliberate phase
separation, deliberate compatibility seams, and actionable ownership concerns.
No behavior-bearing cleanup is selected here; `.3` owns the follow-up leaf
creation.

| Surface / concern | Classification | Rationale | Follow-up disposition |
| --- | --- | --- | --- |
| Direct semantic `CoreAST` expression family | Deliberate phase boundary | It is the source semantic expression model for parsed `.fsm` and for scheduled `.isf` once the generated `.fsm` text re-enters the direct parser. It carries signal/type/width context and richer source constructs than backend enable ASTs or structural binding expressions. | Keep as the direct semantic owner. No consolidation selected. |
| Backend `FSM::AST::*` node family in `Node.pm` | Deliberate phase boundary | The backend only needs a compact enable/factorization model for signal refs, literals, logical constants, unary/binary operations, and generated enable trees. Keeping it smaller than `CoreAST` avoids forcing backend-only enable structure into source semantic nodes. | Keep, but route constructor ownership through one utility surface in a follow-up. |
| Structural `ConnectionExpr` hash family | Deliberate phase boundary | These nodes model structural binding expressions for ports, child carriers, aggregate paths, literals, open bindings, concat, and repeat in composition/structural RTL. They are not source semantic expressions and should remain backend-neutral structural projections. | Keep as structural binding owner. No consolidation selected. |
| Composition source-expression specs | Deliberate private planner boundary | They preserve endpoint text, child-base discovery, top/child inference, and width/type resolution before lowering to `ConnectionExpr`. This is a planner-local step, not a public expression model. | Keep private and continue lowering into `ConnectionExpr`. |
| Composition actual literal support | Deliberate literal-lowering owner | It owns actual payload parsing and target-width-bound literal/open connection expression creation. That is narrower than a general expression AST and does not duplicate `CoreAST`. | Keep as literal owner. No consolidation selected. |
| Package aggregate expression type support | Deliberate `CoreAST` consumer | It infers list/record/scalar type shape from `CoreAST` expressions but does not define another expression representation. | Keep as a consumer. No follow-up needed. |
| Private ISF scalar/list expression payloads | Deliberate scheduler-private boundary | ISF parser/lowerer validates raw Lispish scalars/arrays for guards, waits, activations, drive bodies, enum/aggregate restrictions, and schedule metadata before stringifying to scheduled `.fsm`. It becomes `CoreAST` only after the generated `.fsm` handoff. | Keep private. Do not expose as downstream expression IR. |
| EnableGraph `CoreAST` to backend-AST condition conversion | Deliberate conversion seam | Conditions/tests are captured into backend enable trees so direct backend passes can factor and render them independently of full source nodes. | Keep, but follow-up leaves should make string/RHS reparsing boundaries explicit. |
| `ExpressionNamer` object-AST plus legacy hash/string paths | Deliberate compatibility seam with ownership risk | The object-AST naming paths are live, but the same owner also carries a legacy hash parser and fallback string parsing. That overlap is tolerable only as private compatibility, not as another canonical AST. | `.3` should create a behavior-preserving audit/guard leaf around `parse_expression` callers and accepted return forms before any parser change. |
| `GlobalASTManager` | Actionable legacy ownership concern | Static search found no runtime import/use outside its own module and a compatibility audit test. Its `run_global_factorization` path parses strings through `ExpressionNamer`, while `collect_ast` drops unblessed values; that conflicts with its "single authority" header and with the current live SystemVerilog `GlobalFactorizationSupport` owner. | `.3` should create a leaf to either retire this legacy manager or prove and document its remaining supported boundary. |
| Standalone [perl/FSM/AST/Utils.pm](../../perl/FSM/AST/Utils.pm) versus in-file `FSM::AST::Utils` in `Node.pm` | Actionable duplicate owner | Callers use the in-file package loaded by `FSM::AST::Node`; the standalone file defines the same package and references `FSM::AST::Node::Literal` / `BinaryOp` / `UnaryOp`, which do not match the actual classes. | `.3` should create a small cleanup/guard leaf to collapse this to one constructor owner or turn the standalone file into a correct compatibility shim. |
| Tracked [perl/FSM/ExpressionNamer.pm.new](../../perl/FSM/ExpressionNamer.pm.new) | Actionable tracked residue | It declares the same package as the live module, is tracked, and no references load it. It creates source-of-truth ambiguity for review even if runtime cannot load it through normal `use FSM::ExpressionNamer`. | `.3` should create a cleanup leaf to remove it or explicitly reclassify it as archival test data with a non-package-bearing name. |

### Classification Result

- Keep multiple expression representations where they match real compiler
  phase boundaries: direct source semantics, backend enable/factorization,
  structural binding, composition planning, literal lowering, and private ISF
  scheduling.
- Do not introduce a universal expression node type.
- Do not expose any private expression representation as a downstream API in
  this task tree.
- Create follow-up leaves only for concrete ownership risks:
  `ExpressionNamer` legacy hash/string boundaries, `GlobalASTManager` legacy
  status, duplicate `FSM::AST::Utils`, and tracked `ExpressionNamer.pm.new`.

## Decisions

- `2026-05-20`: Selected as an actionable follow-up from
  `FSMGEN-IR-AUDIT.4` because the audit found overlapping expression
  representations whose phase boundaries are legitimate but not yet recorded
  in one ownership map.
- `2026-05-20`: Completed `.1` as documentation/inventory only. No
  expression semantics, parser behavior, backend rendering, generated HDL,
  schedule JSON, or public contract changed.
- `2026-05-20`: Completed `.2` by classifying phase-specific expression
  representations as deliberate, and selecting only concrete legacy/duplicate
  ownership concerns for `.3` follow-up leaf creation.

## Open Questions

- Which implementation leaves in `.3` should be done as removals versus
  compatibility shims?
- Should `ExpressionNamer` hash parsing be guarded as private compatibility
  before any behavior-preserving caller cleanup?

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `IR-EXPRESSION-AST-OWNERSHIP.1` | `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-20` | `IR-EXPRESSION-AST-OWNERSHIP.2` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `IR-EXPRESSION-AST-OWNERSHIP.1` | `74456538 IR-EXPRESSION-AST-OWNERSHIP.1: inventory expression surfaces` | Inventory committed; no compiler behavior changed. |
| `IR-EXPRESSION-AST-OWNERSHIP.2` | `pending` | `pending` |

## Changelog

- `2026-05-20`: Completed `.1` inventory and advanced the active frontier to
  `.2` classification.
- `2026-05-20`: Completed `.2` classification and advanced the active frontier
  to `.3` follow-up leaf creation.
- `2026-05-20`: Created proposed follow-up task tree from
  `FSMGEN-IR-AUDIT.4`.
