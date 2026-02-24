# MEMORY
This is the live continuity document for fast session recovery after crashes, restarts, or agent handoffs.
## Purpose
- Preserve the minimum complete context needed to resume work immediately.
- Capture key technical decisions and current implementation status.
- Reference canonical docs for deeper details instead of duplicating everything.
## Non-negotiable workflow (user requirement)
After each completed task, always do this in order:
1. Update `MEMORY.md` with new state and next actionable direction.
2. Update other live docs as needed (`CHANGES.md`, `DEVELOPMENT_NOTES.md`, and any user-facing docs impacted by the change).
3. Run validation for the task scope (syntax checks + regression tests when applicable).
4. Run commit workflow:
   - write `git_message_brief.txt`
   - commit with `git commit -F git_message_brief.txt`
   - include `Co-Authored-By: Warp <agent@warp.dev>`
   - clear `git_message_brief.txt` after commit (`truncate -s 0 git_message_brief.txt`)
## Current technical status (updated 2026-02-24)
- Assignment families are implemented and stabilized: `c`, `r`, `m`, `rm`, `mr`, `pN`.
- `pN` semantics are authoritative and must not regress:
  - `<N` means exact delay to cycle `Q+N` (not duration).
  - one-cycle pulse only.
  - `<N 1`: positive pulse (`0->1->0`), `<N 0`: negative pulse (`1->0->1`).
- Regression baseline is currently green:
  - `prove -I perl t`
  - `Files=5, Tests=117, PASS`.
## EnableGraph extraction status
Behavior-preserving extraction from `FlattenedDT` into `EnableGraph` is active and working.
### Already moved into `perl/FSM/Synthesis/EnableGraph.pm`
- `build_unified_assignment_analysis`
- `group_assignments_by_rhs`
- `generate_complete_enable_structure`
- `build_multiplexer_config`
- `generate_unified_wen_en_signals`
- `generate_dt_enables_from_analysis`
- `generate_lhs_enables_from_analysis`
- `generate_signal_assignments`
- `generate_unified_comb_mux`
- `generate_unified_flop_mux`
- `generate_unified_pulse_delay_logic`
- `get_pulse_delay_cycles_for_lhs`
- `get_pulse_active_level_for_lhs`
- `normalize_rhs_logic_level`
- `clean_signal_name`
- `generate_rhs_based_enable_name`
- `signal_uses_register_assignment`
- `get_signal_assignment_type`
- `get_driven_signals`
- `get_reset_value`
- `get_default_value`
- `get_signal_info`
- `get_explicit_reset_value`
- `get_fsm_reset_state`
- `get_reset_value_from_ast`
- `get_default_value_from_ast`
- `set_explicit_reset_values`
- `set_fsm_module_reference`
- `is_register`
- `fallback_register_analysis_from_assignments`
- `extract_signal_name_from_ast`
- `get_lhs_width_from_analysis`
- `track_ast_intermediate_signals`
- `is_intermediate_signal`
- `is_signal_ast_based_intermediate`
- `_ast_contains_factorizable_operators`
- `is_arithmetic_operation`
- `is_logical_operation`
- `should_factor_logical_operation`
- `contains_frequently_used_operations`
- `get_intermediate_signal_expression`
- `generate_expression_from_signal_name`
### Still strong candidates for next slices
- remaining phase-3/per-assignment support helpers still owned by `FlattenedDT` are narrowing; continue incremental extraction with parity checks.
- broader synthesis-layer boundary tightening once helper ownership is sufficiently centralized in `EnableGraph`.
## Recent milestone commits (most recent first)
- `WORKTREE (pending commit)` Delegate intermediate-signal expression synthesis helper ownership to `EnableGraph` (`generate_expression_from_signal_name`) with compatibility delegation in `FlattenedDT`
- `4fec56e` Delegate intermediate-signal expression resolver ownership to `EnableGraph`
- `4a0cd02` Delegate frequent-logical-usage helper ownership to `EnableGraph`
- `0a4dd6e` Delegate logical-factorization policy helper ownership to `EnableGraph`
- `b3f5f73` Delegate logical-operation helper ownership to `EnableGraph`
- `7b1f2b8` Delegate arithmetic-operation helper ownership to `EnableGraph`
- `ddaaabe` Delegate AST factorization operator helper ownership to `EnableGraph`
- `eb1de0d` Delegate AST-based intermediate classification helper ownership to `EnableGraph`
- `8c5f23b` Delegate intermediate-signal classification helper ownership to `EnableGraph`
- `9bb41eb` Delegate intermediate-signal AST tracker ownership to `EnableGraph`
- `fe6360c` Delegate LHS-width analysis helper ownership to `EnableGraph`
- `e087dac` Delegate AST signal-name extraction helper ownership to `EnableGraph`
- `01312fa` Delegate register-classification helper ownership to `EnableGraph`
- `9ebea2f` Delegate FSM module-reference setter ownership to `EnableGraph`
- `250a55f` Delegate explicit-reset config setter ownership to `EnableGraph`
- `30d21cc` Delegate AST default-value helper ownership to `EnableGraph`
- `c3dcf04` Delegate AST reset-value helper ownership to `EnableGraph`
- `7705725` Delegate FSM reset-state helper ownership to `EnableGraph`
- `0465b90` Delegate explicit-reset helper ownership to `EnableGraph`
- `0aeb0fc` Delegate signal-info helper ownership to `EnableGraph`
- `2ee1c64` Delegate default-value helper ownership to `EnableGraph`
- `820481c` Delegate reset-value helper ownership to `EnableGraph`
- `dfc92dd` Delegate driven-signal classification to `EnableGraph`
- `c18c35b` Delegate assignment-type helper ownership to EnableGraph
- `a82d5cd` Delegate enable naming helper ownership to EnableGraph
- `59a86d3` Delegate pulse helper analysis ownership to EnableGraph
- `d65e86a` Delegate unified pulse-delay emission to EnableGraph
- `a2725c9` Add live MEMORY.md continuity document and update workflow policy
- `0bf08d4` Delegate unified flop mux emission to EnableGraph
- `1f29750` Delegate unified combinational mux emission to EnableGraph
- `d4dc317` Delegate unified phase-3 assignment orchestration to EnableGraph
- `32892d4` Delegate unified phase-2 WEN/EN emission to EnableGraph
- `f62d6fe` Extract unified assignment-analysis orchestration into EnableGraph
- `6bb94d4` Extract multiplexer config assembly into EnableGraph synthesis layer
- `36a574f` Extract RHS grouping orchestration into EnableGraph synthesis layer
- `2a05831` Add assignment edge/snapshot regressions and extract initial EnableGraph layer
- `fe1cc3c` Implement c/r/m/rm/mr/pN assignment semantics and document pN as Q+N delay
## Quick resume checklist
1. Read `MEMORY.md` first.
2. Read latest entries in `CHANGES.md` and `DEVELOPMENT_NOTES.md`.
3. Check repo state: `git --no-pager status --short`.
4. Run baseline regression: `prove -I perl t`.
5. Continue the next extraction slice with behavior-preserving delegation.
6. Before committing, update `MEMORY.md` and related live docs again.
## Live document references
- `CHANGES.md`: persistent technical change history.
- `DEVELOPMENT_NOTES.md`: rationale, architecture, and policy-level technical knowledge.
- `docs/USER_GUIDE.md`: user-facing usage guidance.
- `README.md`: project overview and quickstart.
