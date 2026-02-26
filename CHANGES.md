# CHANGES
This is the persistent technical change history for FSMGen.
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
