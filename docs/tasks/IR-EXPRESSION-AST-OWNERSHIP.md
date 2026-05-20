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
  Commit: `pending`

- ID: `IR-EXPRESSION-AST-OWNERSHIP.2`
  Status: `active`
  Goal: `Classify deliberate versus accidental expression duplication.`
  Acceptance: `Each representation is marked deliberate phase separation or
  actionable duplication, with no behavior-bearing refactor selected without
  a follow-up leaf.`
  Verification: `pending`
  Commit: `pending`

- ID: `IR-EXPRESSION-AST-OWNERSHIP.3`
  Status: `proposed`
  Goal: `Create implementation leaves for actionable expression ownership fixes.`
  Acceptance: `Only concrete redundant conversions or unsafe ownership gaps
  become executable follow-up leaves with verification plans.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

This tree is active. The current PNT frontier classifies deliberate phase
separation versus accidental expression duplication now that the inventory is
complete.

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `IR-EXPRESSION-AST-OWNERSHIP.1` | `done` | Expression surfaces and conversion sites are inventoried. |
| 2 | `IR-EXPRESSION-AST-OWNERSHIP.2` | `active` | The inventory now needs deliberate-versus-accidental classification before implementation leaves are selected. |

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

## Decisions

- `2026-05-20`: Selected as an actionable follow-up from
  `FSMGEN-IR-AUDIT.4` because the audit found overlapping expression
  representations whose phase boundaries are legitimate but not yet recorded
  in one ownership map.
- `2026-05-20`: Completed `.1` as documentation/inventory only. No
  expression semantics, parser behavior, backend rendering, generated HDL,
  schedule JSON, or public contract changed.

## Open Questions

- Are the two `FSM::AST::Utils` definitions deliberate compatibility residue
  or an actionable source of backend AST constructor drift?
- Should [perl/FSM/ExpressionNamer.pm.new](../../perl/FSM/ExpressionNamer.pm.new)
  remain tracked when no references load it?
- Is [perl/FSM/GlobalASTManager.pm](../../perl/FSM/GlobalASTManager.pm) still a
  live owner, given that it collects blessed ASTs but currently asks
  `ExpressionNamer` for legacy hash ASTs?
- Which `ExpressionNamer` paths remain deliberate compatibility, and which
  should become follow-up leaves?

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `IR-EXPRESSION-AST-OWNERSHIP.1` | `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `IR-EXPRESSION-AST-OWNERSHIP.1` | `pending` | `pending` |

## Changelog

- `2026-05-20`: Completed `.1` inventory and advanced the active frontier to
  `.2` classification.
- `2026-05-20`: Created proposed follow-up task tree from
  `FSMGEN-IR-AUDIT.4`.
