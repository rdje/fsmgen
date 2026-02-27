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
## Current technical status (updated 2026-02-27)
- Assignment families are implemented and stabilized: `c`, `r`, `m`, `rm`, `mr`, `pN`.
- `pN` semantics are authoritative and must not regress:
  - `<N` means exact delay to cycle `Q+N` (not duration).
  - one-cycle pulse only.
  - `<N 1`: positive pulse (`0->1->0`), `<N 0`: negative pulse (`1->0->1`).
- Regression baseline is currently green:
  - `prove -I perl t`
  - `Files=6, Tests=125, PASS`.
- FlattenedDT decomposition direction is now explicitly two-track:
  - `Orchestrator` (pipeline sequencing ownership),
  - `Backend` (render/emitter ownership).
- `EnableGraph` remains a synthesis helper module (`FSM::Synthesis::EnableGraph`) used by `FlattenedDT`, not a direct submodule in the `FlattenedDT` breakdown.
- First orchestrator decomposition slice is complete:
  - `generate_systemverilog` orchestration has been moved into `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`,
  - `FlattenedDT` now delegates this entrypoint through a compatibility facade.
- First backend decomposition slice is complete:
  - module declaration emission (`generate_module_declaration`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Second backend decomposition slice is complete:
  - state-encoding emission (`generate_state_encoding`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Third backend decomposition slice is complete:
  - state-register emission (`generate_state_register`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Fourth backend decomposition slice is complete:
  - enable-conditions emission (`generate_enable_conditions`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Fifth backend decomposition slice is complete:
  - header emission (`generate_header`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Sixth backend decomposition slice is complete:
  - internal-signal declaration emission (`generate_internal_signal_declarations`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Seventh backend decomposition slice is complete:
  - Verilog generation ownership (`generate_verilog`, `convert_systemverilog_to_verilog`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/Verilog.pm`,
  - `FlattenedDT` now delegates these Verilog backend entrypoints through a compatibility facade.
- Eighth backend decomposition slice is complete:
  - WEN/EN emission entrypoint ownership (`generate_wen_en_signals`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Ninth backend decomposition slice is complete:
  - intermediate-signal declaration emission ownership (`generate_intermediate_signal_declarations`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Tenth backend decomposition slice is complete:
  - combinational-mux emission ownership (`generate_comb_mux`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Eleventh backend decomposition slice is complete:
  - flop-mux emission ownership (`generate_flop_mux`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Twelfth backend decomposition slice is complete:
  - consolidated intermediate-signal emission ownership (`generate_consolidated_intermediate_signals`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Thirteenth backend decomposition slice is complete:
  - global AST-factorization orchestration ownership (`run_global_ast_factorization`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Fourteenth backend decomposition slice is complete:
  - AST-factorizer input feeding ownership (`feed_asts_to_factorizer`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Fifteenth backend decomposition slice is complete:
  - unary-negation counting helper ownership (`count_unary_negations_in_original_expressions`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Sixteenth backend decomposition slice is complete:
  - AST substitution-backpropagation helper ownership (`update_original_asts_with_substituted_versions`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Seventeenth backend decomposition slice is complete:
  - second-pass factorization orchestration ownership (`run_second_pass_factorization`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Eighteenth backend decomposition slice is complete:
  - created shared backend-neutral factorization package `perl/FSM/HDL/Factorization/Fixpoint.pm`,
  - moved iterative post-substitution factorization loop ownership into `FSM::HDL::Factorization::Fixpoint`,
  - `Backend::SystemVerilog` now delegates `run_second_pass_factorization` to the shared package via compatibility entrypoint.
- Post-substitution factorization behavior now uses iterative convergence until stable with deterministic termination guards:
  - stops on no factorizable expressions, no new candidates, repeated expression signature, no substitution progress, or max-pass cap.
- Commit workflow documentation is now explicit and tracked:
  - added `COMMIT.md` as the canonical workflow reference for future AI handoff,
  - includes involved files, exact execution order, and run frequency (after each completed task/activity).
- First-class tracing is now integrated into FSMGen runtime surfaces:
  - canonical trace verbosity names are supported: `none`, `low`, `medium`, `high`, `debug` (mapped to levels `0..4`),
  - numeric debug compatibility remains supported through `--debug[=N]` with bare `--debug` mapped to level `4`,
  - CLI now supports trace controls: `--trace-verbosity`, `--trace-log[=FILE]`, `--trace-emojis`/`--notrace-emojis`,
  - when trace-file routing is enabled, trace output is routed to `trace.log` (or configured file) instead of stdout,
  - trace records include source metadata (`file`, `function`, `line`) and structured kinds (`topic`, `enter`, `exit`, `decision`) with indentation-aware formatting.
- Trace instrumentation was integrated in key pipeline/parser facades:
  - `perl/FSM/Pipeline/HDLGenerator.pm`,
  - `perl/FSM/Adapter/FSMGenFull.pm`,
  - `perl/FSM/Adapter/FSMGenFull/Parser.pm`.
- User-facing and regression coverage for tracing were updated:
  - docs updated in `README.md` and `docs/USER_GUIDE.md`,
  - new trace regression `t/06-tracing-system.t` added and passing.
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
- `_signal_name_indicates_ast_operators`
- `ast_to_systemverilog`
### Still strong candidates for next slices
- the direct EnableGraph-to-FlattenedDT helper seam is now essentially exhausted for this extraction lane; any further moves would be deeper AST-render internals.
- broader decomposition remains the next architectural lever:
  - continue `EnableGraph` helper ownership where clear,
  - extract backend emitters into dedicated modules,
  - keep `FlattenedDT` as thin facade/compatibility shell.
## Recent milestone commits (most recent first)
- `WORKTREE (pending commit)` Extract shared iterative post-substitution factorization into `FSM::HDL::Factorization::Fixpoint` and delegate `Backend::SystemVerilog` compatibility entrypoint to it
- `7c44abc` Extract AST substitution-backpropagation helper into SV backend
- `586a2f8` Extract unary-negation counter helper into SV backend
- `f2c4422` Extract AST factorizer input feeding into SV backend
- `c9db9e2` Extract global AST factorization orchestration into SV backend
- `07329fb` Extract consolidated intermediate signal emission into SV backend
- `c2dfaaf` Add first-class multi-level tracing with structured metadata, trace.log routing, CLI controls, parser/pipeline hooks, and regression coverage
- `886b5f1` Add canonical `COMMIT.md` with precise commit workflow definition for AI handoff continuity
- `3adf1f8` Continue backend decomposition by extracting `generate_flop_mux` into `FlattenedDT::Backend::SystemVerilog` with compatibility delegation in `FlattenedDT`
- `ebf90f2` Continue backend decomposition by extracting `generate_comb_mux` into `FlattenedDT::Backend::SystemVerilog` with compatibility delegation in `FlattenedDT`
- `a89fa9c` Continue backend decomposition by extracting `generate_intermediate_signal_declarations` into `FlattenedDT::Backend::SystemVerilog` with compatibility delegation in `FlattenedDT`
- `b9c81dc` Continue backend decomposition by extracting `generate_wen_en_signals` into `FlattenedDT::Backend::SystemVerilog` with compatibility delegation in `FlattenedDT`
- `5de2f44` Add dedicated `FlattenedDT::Backend::Verilog` and move `generate_verilog`/`convert_systemverilog_to_verilog` ownership there with compatibility delegation in `FlattenedDT`
- `1f0b44b` Continue backend decomposition by extracting `generate_internal_signal_declarations` into `FlattenedDT::Backend::SystemVerilog` with compatibility delegation in `FlattenedDT`
- `0313969` Continue backend decomposition by extracting `generate_header` into `FlattenedDT::Backend::SystemVerilog` with compatibility delegation in `FlattenedDT`
- `0d80108` Continue backend decomposition by extracting `generate_enable_conditions` into `FlattenedDT::Backend::SystemVerilog` with compatibility delegation in `FlattenedDT`
- `637678f` Continue backend decomposition by extracting `generate_state_register` into `FlattenedDT::Backend::SystemVerilog` with compatibility delegation in `FlattenedDT`
- `7dc5461` Continue backend decomposition by extracting `generate_state_encoding` into `FlattenedDT::Backend::SystemVerilog` with compatibility delegation in `FlattenedDT`
- `082eab2` Start backend decomposition by extracting `generate_module_declaration` into `FlattenedDT::Backend::SystemVerilog` with compatibility delegation in `FlattenedDT`
- `dd82368` Start explicit `FlattenedDT` decomposition by extracting `generate_systemverilog` pipeline sequencing into `FlattenedDT::Orchestrator` with compatibility delegation in `FlattenedDT`
- `1b1036a` Delegate AST-to-SystemVerilog rendering helper ownership to `EnableGraph` (`ast_to_systemverilog`) with compatibility delegation in `FlattenedDT`
- `4840580` Delegate AST-based intermediate-name metadata helper ownership to `EnableGraph`
- `ac9b39e` Delegate intermediate-signal expression synthesis helper ownership to `EnableGraph`
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
