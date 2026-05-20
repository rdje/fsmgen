# EXPR-NAMER-LEGACY-PARSE-BOUNDARY: ExpressionNamer Legacy Parse Boundary

## Metadata

- Tree ID: `EXPR-NAMER-LEGACY-PARSE-BOUNDARY`
- Status: `done`
- Roadmap lane: `architecture backlog`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Make the `FSM::ExpressionNamer` legacy string/hash parser boundary explicit
before any caller cleanup changes behavior.

## Non-Goals

- Do not replace direct `CoreAST` parsing.
- Do not make `ExpressionNamer` hash ASTs public API.
- Do not rewrite backend factorization in this tree unless a later leaf proves
  it is necessary and behavior-preserving.

## Acceptance Criteria

- Every live `ExpressionNamer->parse_expression` caller is classified by
  whether it accepts blessed AST objects, legacy hash ASTs, or both.
- Focused tests guard the current accepted return shapes before cleanup.
- Any selected caller cleanup has its own leaf and verification plan.
- Live docs and roadmap status are updated when ownership status changes.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `EXPR-NAMER-LEGACY-PARSE-BOUNDARY`
  Status: `done`
  Goal: `Make ExpressionNamer legacy parse boundaries explicit.`
  Children: `EXPR-NAMER-LEGACY-PARSE-BOUNDARY.1`,
  `EXPR-NAMER-LEGACY-PARSE-BOUNDARY.2`

- ID: `EXPR-NAMER-LEGACY-PARSE-BOUNDARY.1`
  Status: `done`
  Goal: `Audit parse_expression callers and accepted return forms.`
  Acceptance: `The task file lists every live caller and whether it expects
  blessed AST, legacy hash AST, string fallback, or mixed compatibility.`
  Verification: `static caller audit`; `git diff --check`; `mdbook build docs/book`
  Commit: `EXPR-NAMER-LEGACY-PARSE-BOUNDARY.1: audit legacy parse boundary`

- ID: `EXPR-NAMER-LEGACY-PARSE-BOUNDARY.2`
  Status: `done`
  Goal: `Add focused guards for the accepted legacy parse boundary.`
  Acceptance: `Regression coverage locks the accepted caller behavior before
  any cleanup or conversion leaf is selected.`
  Verification: `focused legacy parse boundary regression passed`
  Commit: `EXPR-NAMER-LEGACY-PARSE-BOUNDARY.2: guard legacy parse boundary`

## Current Frontier

This tree is closed. The current accepted `ExpressionNamer` legacy parse
boundary is documented and guarded before any cleanup or conversion is
selected.

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `EXPR-NAMER-LEGACY-PARSE-BOUNDARY.1` | `done` | Caller classification completed before parser/caller cleanup. |
| 2 | `EXPR-NAMER-LEGACY-PARSE-BOUNDARY.2` | `done` | Guarded the accepted legacy hash and blessed-only boundaries. |

## Decisions

- `2026-05-20`: Created from `IR-EXPRESSION-AST-OWNERSHIP.3` because
  `ExpressionNamer` deliberately supports object-AST naming but also owns
  private legacy hash/string parsing that must not become accidental compiler
  truth.
- `2026-05-20`: Classified `FSM::ExpressionNamer->parse_expression` as a
  private string-to-legacy-hash parser. It does not return blessed `CoreAST`
  or `FSM::AST::*` nodes today. Callers either consume that hash form, accept
  hash-or-blessed trees through recursive collectors, or currently no-op
  because they only act on blessed ASTs.
- `2026-05-20`: Added
  [t/521-expression-namer-legacy-parse-boundary-audit.t](../../t/521-expression-namer-legacy-parse-boundary-audit.t)
  to guard the current boundary: representative hash shapes,
  `parse_and_name_expression` hash-backed definitions, hash-aware collectors,
  and blessed-only no-op hooks.

## Open Questions

- Which blessed-only legacy paths should be retired, converted to hash-aware
  consumers, or left as no-op compatibility hooks after `.2` guards the
  current behavior?

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `EXPR-NAMER-LEGACY-PARSE-BOUNDARY.1` | `rg -n -- '->parse_expression|->parse_and_name_expression' perl/FSM`; `rg -n -- 'expr_namer.*parse_expression|parse_and_name_expression' perl/FSM`; `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-20` | `EXPR-NAMER-LEGACY-PARSE-BOUNDARY.2` | `perl -Iperl -c t/521-expression-namer-legacy-parse-boundary-audit.t`; `prove -Iperl t/520-expression-namer-query-defensive-copy-boundary-audit.t t/521-expression-namer-legacy-parse-boundary-audit.t`; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `EXPR-NAMER-LEGACY-PARSE-BOUNDARY.1` | `EXPR-NAMER-LEGACY-PARSE-BOUNDARY.1: audit legacy parse boundary` | Classifies current hash, mixed, string-name, and blessed-only caller expectations. |
| `EXPR-NAMER-LEGACY-PARSE-BOUNDARY.2` | `EXPR-NAMER-LEGACY-PARSE-BOUNDARY.2: guard legacy parse boundary` | Adds focused regression coverage for the documented boundary and closes the tree. |

## Changelog

- `2026-05-20`: Created proposed follow-up task tree from
  `IR-EXPRESSION-AST-OWNERSHIP.3`.
- `2026-05-20`: Activated `.1`, classified live `ExpressionNamer`
  legacy-parse callers, and advanced `.2` for focused guard coverage.
- `2026-05-20`: Completed `.2` by adding focused guard coverage and closing
  the tree.

## Legacy Parse Boundary Audit

`FSM::ExpressionNamer->parse_expression` is a private compatibility parser.
For string input it returns an unblessed legacy hash AST, not `CoreAST` and
not `FSM::AST::*`.

The accepted hash node families today are:

- `literal` and `constant` for fallback literals and parsed numeric/encoded
  constants.
- `signal` for simple names, bit selects, ranges, width annotations, and
  output-marked names.
- `unary_op`, `binary_op`, `comparison`, and `arithmetic` for recursively
  parsed expression strings.

| Caller / surface | Input source | Accepted return form today | Boundary classification |
| --- | --- | --- | --- |
| `FSM::ExpressionNamer::parse_and_name_expression` | String expressions from legacy naming paths. | Legacy hash AST only. It immediately calls `generate_signal_name`, `infer_width`, and `ast_to_verilog`, all of which are hash-oriented. | Canonical private hash consumer. |
| `FSM::ExpressionNamer::name_ast_expression` unknown-object fallback and `name_signal_ref_ast` slice fallback | Blessed AST object converted through `to_systemverilog`. | String-name result only; the intermediate parse result stays private to `parse_and_name_expression`. | String fallback bridge from unknown/blessed objects into legacy hash naming. |
| `FSM::Synthesis::EnableGraph::SignalSupport::generate_assignment_enable_name` | Assignment RHS string that is not a simple signal/slice. | String-name result from `parse_and_name_expression`; caller does not inspect the hash. | Name-only legacy string consumer. |
| `FSM::HDL::FlattenedDT::Backend::SystemVerilog::OperandContractValidationSupport::_validate_named_expression` | Named intermediate expression text. | Hash or blessed tree. `_collect_signal_operand_names` explicitly recurses through unblessed hash nodes and blessed AST objects. | Mixed hash/blessed validator. |
| `FSM::Synthesis::EnableGraph::FactorizationSupport` assignment-RHS fallback | Assignment `rhs` that is not already blessed. | Hash or blessed tree. `ast_contains_signal` handles both forms. | Mixed hash/blessed signal-use fallback. |
| `FSM::Synthesis::EnableGraph::FactorizationPolicySupport` assignment-RHS fallback | Assignment `rhs` that is not already blessed. | Hash or blessed tree. `ast_contains_intermediate_signals` handles hash `signal`, `binary_op`, and `unary_op` nodes and blessed AST objects. | Mixed hash/blessed second-pass factorization fallback. |
| `FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport` dependency fallback parse | Runtime-AST-miss rendered expressions and cleaned expressions. | Mixed. `recover_runtime_ast_from_dependency_expression` only accepts blessed ASTs and therefore ignores current hash results, while the later dependency extraction path passes hash trees to `SignalSupport->extract_intermediate_signals_from_ast`, which supports hash recursion. | Split mixed boundary: one blessed-only no-op hook plus one hash-aware dependency fallback. |
| `FSM::Synthesis::EnableGraph::SignalSupport::_signal_name_indicates_ast_operators` | `global_expressions` expression strings. | Blessed-only in practice because it checks `blessed($ast)` before asking AST support for operators; current hash results are treated as not operator-backed. | Blessed-only legacy hook; current `ExpressionNamer` hash output does not satisfy it. |
| `FSM::Synthesis::EnableGraph::IntermediateSignalSupport::_parse_intermediate_expression_to_ast` | Intermediate signal compatibility expression text. | Blessed-only; current hash results are ignored and the method returns `undef`. | Blessed-only legacy hook; current `ExpressionNamer` hash output does not satisfy it. |
| `FSM::GlobalASTManager::collect_all_asts_from_design` | LHS condition strings and assignment-analysis enable strings. | Blessed-only after parse because `collect_ast` drops unblessed values. Current hash results are not collected. | Legacy mismatch/no-op for `ExpressionNamer` hash output. |

## Selected Guard Scope For `.2`

`EXPR-NAMER-LEGACY-PARSE-BOUNDARY.2` should add focused coverage for the
current behavior, not change it:

- `parse_expression` returns unblessed hash ASTs for representative signal,
  unary, binary, comparison, arithmetic, constant, slice, and empty/fallback
  inputs.
- `parse_and_name_expression` stores a legacy hash AST-backed definition with
  stable rendered SystemVerilog and inferred width.
- Hash-aware collectors still accept the legacy hash shape where current code
  relies on it.
- Blessed-only hooks remain guarded as blessed-only/no-op for current
  `ExpressionNamer` hash output so later cleanup can change them deliberately.
