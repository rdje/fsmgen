# CHANGES
This is the persistent technical change history for FSMGen.
## 2026-03-08
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
