# CHANGES
This is the persistent technical change history for FSMGen.
## 2026-03-13
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
