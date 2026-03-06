# DEVELOPMENT_NOTES
This document captures engineering rationale, design constraints, and working decisions behind recent FSMGen behavior.
## 2026-02-28: Backend extraction of final-expression usage-check helper
- Continued structure-first `FlattenedDT` decomposition by moving `is_signal_actually_used_in_final_expressions` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains compatibility delegation for this entrypoint (`backend_sv->is_signal_actually_used_in_final_expressions(...)`).
- Rationale:
  - final-expression usage checking is consumed directly in backend-owned filtering paths and is better co-located with that logic,
  - extraction continues reducing `FlattenedDT` monolith size while preserving facade compatibility.
- Safety/compatibility:
  - no intended semantic change in usage-check behavior,
  - backend AST/string filtering now calls backend-local usage-check helper while keeping recursive signal-reference checks anchored through existing `FlattenedDT` helper context.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-28: Backend extraction of string-fallback filtering helper
- Continued structure-first `FlattenedDT` decomposition by moving `should_filter_string_based` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains compatibility delegation for this entrypoint (`backend_sv->should_filter_string_based(...)`).
- Rationale:
  - string-fallback filtering is invoked from backend-owned consolidated filtering flow and is better co-located with that logic,
  - extraction continues reducing `FlattenedDT` monolith size while preserving facade compatibility.
- Safety/compatibility:
  - no intended semantic change in fallback filtering behavior,
  - backend consolidated filtering now calls backend-local fallback helper (`$self->should_filter_string_based(...)`) while preserving existing dependency checks through `FlattenedDT` context access.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-28: Backend extraction of simple-comparison helper
- Continued structure-first `FlattenedDT` decomposition by moving `is_simple_comparison` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains compatibility delegation for this entrypoint (`backend_sv->is_simple_comparison(...)`).
- Rationale:
  - simple-comparison classification is consumed directly in backend-owned AST filtering flow and is better co-located with that logic,
  - extraction continues reducing `FlattenedDT` monolith size while preserving facade compatibility.
- Safety/compatibility:
  - no intended semantic change in simple-comparison detection behavior,
  - backend AST filtering now invokes backend-local helper (`$self->is_simple_comparison(...)`) while preserving all existing downstream filtering decisions.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-28: Backend extraction of simple-negation helper
- Continued structure-first `FlattenedDT` decomposition by moving `is_simple_negation` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains compatibility delegation for this entrypoint (`backend_sv->is_simple_negation(...)`).
- Rationale:
  - simple-negation classification is consumed directly in backend-owned AST filtering flow and is better co-located with that logic,
  - extraction continues reducing `FlattenedDT` monolith size while preserving facade compatibility.
- Safety/compatibility:
  - no intended semantic change in simple-negation detection behavior,
  - backend AST filtering now invokes backend-local helper (`$self->is_simple_negation(...)`) while preserving all existing downstream filtering decisions.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-28: Backend extraction of AST-based filtering helper
- Continued structure-first `FlattenedDT` decomposition by moving `should_filter_ast_based` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains compatibility delegation for this entrypoint (`backend_sv->should_filter_ast_based(...)`).
- Rationale:
  - this helper is directly coupled to backend-owned consolidated-signal filtering flow and is better co-located in `Backend::SystemVerilog`,
  - extraction further reduces `FlattenedDT` monolith size while preserving compatibility at the facade layer.
- Safety/compatibility:
  - no intended semantic change in AST-first filtering decisions,
  - backend filtering flow now calls backend-local helper (`$self->should_filter_ast_based(...)`) while using existing `FlattenedDT` helper context for dependent checks.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-28: Backend extraction of consolidated-signal filtering entrypoint
- Continued structure-first `FlattenedDT` decomposition by moving `should_filter_consolidated_signal` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains compatibility delegation for this entrypoint (`backend_sv->should_filter_consolidated_signal(...)`).
- Rationale:
  - this filtering entrypoint is consumed directly in backend consolidated intermediate-signal generation and is better owned in `Backend::SystemVerilog`,
  - extraction reduces `FlattenedDT` monolith size while preserving compatibility at the facade surface.
- Safety/compatibility:
  - no intended semantic change in AST-first filtering behavior or fallback path,
  - backend filtering callsite now invokes backend-local helper (`$self->should_filter_consolidated_signal(...)`) while still using unchanged `FlattenedDT` analysis helpers through context access.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-27: Backend extraction of intermediate-reference helper
- Continued structure-first `FlattenedDT` decomposition by moving `extract_intermediate_signals_from_expression` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains compatibility delegation for this entrypoint (`backend_sv->extract_intermediate_signals_from_expression(...)`).
- Rationale:
  - this helper is consumed by backend-owned dependency analysis and substitution trace paths, so ownership is more coherent in `Backend::SystemVerilog`,
  - extraction reduces `FlattenedDT` monolith size while preserving existing call-surface compatibility.
- Safety/compatibility:
  - no intended semantic change in how referenced intermediate signals are identified across AST-factorizer/global/FSMGenFull/pre-scan registries,
  - backend callsites now invoke backend-local helper (`$self->extract_intermediate_signals_from_expression(...)`) while using unchanged analysis state.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-27: Clarified legacy `?fsmc` semantics for composition work
- `?fsmc` is treated as composition-layer interface extraction/wiring support for child FSM blocks in parent compositions.
- `?fsmc` intent is interface visibility/port exposure to the parent layer; WEN/EN generation is not the purpose of `?fsmc` itself.
- This clarification is now the working interpretation for ongoing composition-oriented roadmap work.
## 2026-02-27: Backend extraction of substituted-intermediate AST resolver
- Continued structure-first `FlattenedDT` decomposition by moving `get_substituted_ast_for_signal` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains compatibility delegation for this entrypoint (`backend_sv->get_substituted_ast_for_signal(...)`).
- Rationale:
  - this helper is consumed in backend consolidated-intermediate emission and belongs with adjacent backend-owned factorization/substitution helpers,
  - extraction reduces `FlattenedDT` monolith size and improves backend-local helper ownership coherence.
- Safety/compatibility:
  - no intended semantic change to substituted-AST lookup behavior from factorizer intermediate-signal results,
  - backend emission path now calls backend-local resolver (`$self->get_substituted_ast_for_signal(...)`) while using the same source data.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-27: Terminology and roadmap clarification
- Clarified project term: `fsmc` means FSM Compile / FSM Compiler.
- Sequencing intent:
  - first ensure `(?fsm:name ...)`, `(+fsm ...)`, and related FSM description forms are handled robustly,
  - then proceed to composition DSL capability work.
- Legacy `.plg` plugin surface is expected to be redesigned or retired in its current form.
- Prior macro-like attempts (`cclausearch`, `declarch`, `beginarch`, `endarch`, etc.) are treated as historical prototypes rather than target architecture.
## 2026-02-27: Backend extraction of recursive intermediate-signal detector
- Continued structure-first `FlattenedDT` decomposition by moving `ast_has_intermediate_signals_recursive` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains compatibility delegation for this entrypoint (`backend_sv->ast_has_intermediate_signals_recursive(...)`).
- Rationale:
  - this helper is the direct recursive partner of `ast_contains_intermediate_signals` and belongs in the same backend-owned second-pass filtering cluster,
  - extraction further reduces `FlattenedDT` monolith size and improves locality of second-pass factorization helper ownership.
- Safety/compatibility:
  - no intended semantic change in recursive intermediate-signal detection behavior,
  - backend implementation uses the same `FlattenedDT` state/helpers through context delegation while keeping recursion local to backend method ownership.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-27: Backend extraction of second-pass intermediate-expression filter
- Continued structure-first `FlattenedDT` decomposition by moving `ast_contains_intermediate_signals` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains compatibility delegation for this entrypoint (`backend_sv->ast_contains_intermediate_signals(...)`).
- Rationale:
  - this helper is tightly coupled to second-pass factorization expression collection and belongs with adjacent backend-owned second-pass helpers,
  - extraction further reduces `FlattenedDT` monolith size while preserving current shared factorization call paths.
- Safety/compatibility:
  - no intended semantic change to second-pass filter rules (bare-signal rejection, intermediate-signal detection, compound-expression gating),
  - backend implementation uses the same `FlattenedDT` state/helpers through context delegation.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-27: Backend extraction of second-pass AST substitution update helper
- Continued structure-first `FlattenedDT` decomposition by moving `update_original_asts_with_second_pass_substitutions` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains compatibility delegation for this entrypoint (`backend_sv->update_original_asts_with_second_pass_substitutions(...)`).
- Rationale:
  - this helper is part of the same backend-side factorization orchestration lane as the newly extracted second-pass feed helper and primary substitution update helper,
  - extraction further reduces `FlattenedDT` monolith size while preserving call-surface compatibility for `FSM::HDL::Factorization::Fixpoint`.
- Safety/compatibility:
  - no intended semantic change in second-pass AST synchronization behavior back into assignment analysis and assignment-condition structures,
  - helper still operates on the same `FlattenedDT` state and AST conversion helpers through backend context delegation.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-27: Backend extraction of second-pass AST feeding helper
- Continued structure-first `FlattenedDT` decomposition by moving `feed_current_asts_to_second_pass` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains compatibility delegation for this entrypoint (`backend_sv->feed_current_asts_to_second_pass(...)`).
- Rationale:
  - this helper is directly coupled to backend-side AST-factorization orchestration and now aligns with adjacent backend-owned factorization methods,
  - extraction reduces `FlattenedDT` monolith size while preserving call-surface compatibility used by `FSM::HDL::Factorization::Fixpoint`.
- Safety/compatibility:
  - no intended semantic change in candidate-expression collection for iterative post-substitution factorization,
  - helper behavior still uses the same `FlattenedDT` analysis state and AST filtering rules through backend context delegation.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-27: Shared factorization engine package (`FSM::HDL::Factorization::Fixpoint`)
- Added backend-neutral package `perl/FSM/HDL/Factorization/Fixpoint.pm` with package name `FSM::HDL::Factorization::Fixpoint`.
- Moved iterative post-substitution convergence logic out of `FlattenedDT::Backend::SystemVerilog` and into the shared package.
- `Backend::SystemVerilog` now keeps compatibility ownership at API surface level (`run_second_pass_factorization`) but delegates execution to the shared package.
- Rationale:
  - convergence/fixpoint factorization is synthesis-stage logic and should not be tied to one HDL emitter,
  - package naming now reflects algorithm purpose and is reusable by all present/future backends,
  - this preserves ongoing decomposition strategy (`FlattenedDT` facade + backend delegation + shared synthesis utilities).
- Convergence/termination policy preserved in shared module:
  - no factorable post-substitution expressions,
  - no new factorization candidates,
  - repeated expression signature (oscillation/replay guard),
  - no substitution progress in pass,
  - max pass cap reached.
- Verification:
  - syntax checks for `Fixpoint.pm`, `Backend/SystemVerilog.pm`, and `FlattenedDT.pm` pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-27: Backend extraction of second-pass factorization orchestration
- Continued structure-first `FlattenedDT` decomposition by moving `run_second_pass_factorization` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains only compatibility delegation for this entrypoint (`backend_sv->run_second_pass_factorization(...)`).
- Rationale:
  - this method is orchestration logic for second-pass AST factorization and belongs with adjacent backend factorization helpers already moved,
  - co-locating this orchestration in backend ownership further reduces `FlattenedDT` monolith pressure.
- Safety/compatibility:
  - no intended semantic change in second-pass factorization behavior, substitution, or diagnostics,
  - migrated routine continues to use existing `FlattenedDT` helper/state interfaces through backend context delegation.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-27: Backend extraction of AST substitution-backpropagation helper
- Continued structure-first `FlattenedDT` decomposition by moving `update_original_asts_with_substituted_versions` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains only compatibility delegation for this entrypoint (`backend_sv->update_original_asts_with_substituted_versions(...)`).
- Rationale:
  - this helper is part of backend-side AST-factorization orchestration where substitution results are propagated back into analysis structures,
  - extracting it co-locates substitution orchestration helpers with the backend factorization flow and reduces `FlattenedDT` monolith size.
- Safety/compatibility:
  - no intended semantic change in AST substitution synchronization behavior,
  - migrated routine continues using the same `FlattenedDT` analysis data and AST conversion helpers through backend context delegation.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-27: Backend extraction of unary-negation counting helper
- Continued structure-first `FlattenedDT` decomposition by moving `count_unary_negations_in_original_expressions` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains only compatibility delegation for this entrypoint (`backend_sv->count_unary_negations_in_original_expressions()`).
- Rationale:
  - this helper is part of backend-side AST-factorization orchestration diagnostics and belongs with adjacent factorization backend methods,
  - extracting it further reduces `FlattenedDT` monolith size while preserving existing call flow.
- Safety/compatibility:
  - no intended semantic change in unary-negation diagnostics or debug output,
  - migrated routine continues operating on the same `FlattenedDT` analysis data through backend context access.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-27: Backend extraction of AST-factorizer input feeding
- Continued structure-first `FlattenedDT` decomposition by moving `feed_asts_to_factorizer` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains only compatibility delegation for this entrypoint (`backend_sv->feed_asts_to_factorizer(...)`).
- Rationale:
  - this routine is part of the same backend-side AST-factorization pipeline as `run_global_ast_factorization`,
  - extracting it keeps factorization orchestration and its input collection logic co-located in backend ownership.
- Safety/compatibility:
  - no intended semantic change in factorizer inputs (DT enables, LHS enables, assignment conditions, FSMGen intermediate ASTs),
  - migrated routine continues operating on existing `FlattenedDT` state through context delegation.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-27: Backend extraction of global AST-factorization orchestration
- Continued structure-first `FlattenedDT` decomposition by moving `run_global_ast_factorization` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains only compatibility delegation for this entrypoint (`backend_sv->run_global_ast_factorization()`).
- Rationale:
  - this routine is tightly coupled to intermediate-signal emission flow and is part of backend-side SystemVerilog generation orchestration,
  - extracting it further reduces `FlattenedDT` monolith size while preserving runtime call sites.
- Safety/compatibility:
  - behavior remains unchanged (factorizer setup, substitution flow, second-pass factorization, and trace output preserved),
  - migrated routine continues using existing `FlattenedDT` helper methods through context delegation,
  - added `List::Util::min` import in backend module to preserve existing debug/report loops.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-27: Backend extraction of consolidated intermediate signal emission
- Continued the structure-first `FlattenedDT` decomposition by moving `generate_consolidated_intermediate_signals` ownership into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- `FlattenedDT` now retains only compatibility delegation for this entrypoint (`backend_sv->generate_consolidated_intermediate_signals(...)`).
- Rationale:
  - this method is pure SystemVerilog emission/control-flow in the generation pipeline and belongs with backend ownership,
  - extracting it reduces monolithic pressure in `FlattenedDT` while preserving call-site compatibility.
- Safety/compatibility:
  - no intended semantic changes in intermediate-signal filtering/factorization behavior,
  - existing helper calls remain anchored through `FlattenedDT` context methods,
  - added `Scalar::Util::blessed` import in backend module to preserve runtime behavior of migrated signal-introspection logic.
- Verification:
  - syntax checks for touched modules pass,
  - full regression remains green (`prove -I perl t` -> `Files=6`, `Tests=125`).
## 2026-02-27: First-class tracing architecture and policy
- FSMGen tracing is now treated as a first-class runtime capability, not a best-effort debug print layer.
- Decision:
  - canonical verbosity model uses named levels (`none`, `low`, `medium`, `high`, `debug`) mapped to numeric levels `0..4`,
  - numeric `--debug` compatibility is preserved to avoid breaking existing workflows/scripts.
- Tracing substrate design in `perl/FSM/Debug.pm`:
  - centralized trace-level parsing/normalization,
  - structured trace events (`topic`, `enter`, `exit`, `decision`),
  - source metadata embedding (`file`, `function`, `line`) for each trace line,
  - indentation-aware formatting and optional emoji markers for readability in long runs.
- Routing policy:
  - when trace-log routing is enabled, trace output is written to `trace.log` (or configured path) instead of stdout,
  - trace sink lifecycle is explicitly managed (open/set, flush/close, clear) to avoid fd leaks and stale handles.
- CLI policy in `bin/fsmgen`:
  - explicit trace controls are provided (`--trace-verbosity`, `--trace-log[=FILE]`, `--trace-emojis`, `--notrace-emojis`),
  - legacy tee-based debug output plumbing was removed to avoid split behavior and to make trace routing deterministic.
- Instrumentation scope for this slice:
  - added structured enter/exit/decision/topic tracing in key adapter/pipeline facades:
    - `perl/FSM/Pipeline/HDLGenerator.pm`,
    - `perl/FSM/Adapter/FSMGenFull.pm`,
    - `perl/FSM/Adapter/FSMGenFull/Parser.pm`.
- Verification outcome:
  - syntax checks for touched files are clean,
  - added `t/06-tracing-system.t` and full suite remains green (`Files=6`, `Tests=125`).
- Boundaries:
  - this slice instruments current Perl pipeline surfaces only;
  - no Rust pipeline instrumentation was added because no active `rust/` tree exists in this repository.
## 2026-02-27: Canonical commit workflow document added
- Added `COMMIT.md` as a tracked, canonical workflow contract for future AI handoffs.
- The document defines:
  - when to execute commit workflow (after each completed task/activity, and on explicit commit-workflow requests),
  - exact file responsibilities (`COMMIT.md`, `MEMORY.md`, `CHANGES.md`, `DEVELOPMENT_NOTES.md`, `git_message_brief.txt`, changed source/test files),
  - exact operation order (task completion -> ordered doc updates -> validation -> stage/commit -> truncate brief message file -> status verification).
- Rationale:
  - reduce ambiguity across AI session boundaries,
  - enforce consistent commit hygiene and file-update ordering,
  - preserve a single authoritative process reference in-repo.
## 2026-02-24: FlattenedDT decomposition model formalized (Orchestrator + Backend, with EnableGraph as helper)
- The next architecture phase keeps `FSM::Synthesis::EnableGraph` as a synthesis helper module used by `FlattenedDT` (not a direct `FlattenedDT` submodule breakdown track).
- `FlattenedDT` decomposition is explicitly tracked as two direct module tracks:
  - `Orchestrator`: top-level generation pipeline sequencing ownership,
  - `Backend` modules: rendering/emitter ownership.
- Enable-synthesis helper extraction into `EnableGraph` continues in parallel with the direct `FlattenedDT` breakdown.
- First extraction slice for this phase is complete:
  - created `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`,
  - moved `generate_systemverilog` pipeline sequencing into the orchestrator,
  - kept `FlattenedDT` as compatibility facade delegating `generate_systemverilog(...)`.
- Next extraction slice for this phase is complete:
  - created `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - moved `generate_module_declaration` backend emission into the backend module,
  - kept `FlattenedDT` as compatibility facade delegating `generate_module_declaration(...)`.
- Current extraction slice for this phase:
  - moved `generate_state_encoding` backend emission into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - kept `FlattenedDT` as compatibility facade delegating `generate_state_encoding(...)`.
- Latest extraction slice for this phase:
  - moved `generate_state_register` backend emission into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - kept `FlattenedDT` as compatibility facade delegating `generate_state_register(...)`.
- Current extraction slice for this phase:
  - moved `generate_enable_conditions` backend emission into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - kept `FlattenedDT` as compatibility facade delegating `generate_enable_conditions(...)`.
- Latest extraction slice for this phase:
  - moved `generate_header` backend emission into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - kept `FlattenedDT` as compatibility facade delegating `generate_header(...)`.
- Current extraction slice for this phase:
  - moved `generate_internal_signal_declarations` backend emission into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - kept `FlattenedDT` as compatibility facade delegating `generate_internal_signal_declarations(...)`.
- Latest extraction slice for this phase:
  - created `perl/FSM/HDL/FlattenedDT/Backend/Verilog.pm`,
  - moved Verilog generation ownership (`generate_verilog`, `convert_systemverilog_to_verilog`) into the dedicated Verilog backend module,
  - kept `FlattenedDT` as compatibility facade delegating Verilog-generation entrypoints.
- Current extraction slice for this phase:
  - moved WEN/EN emission entrypoint ownership (`generate_wen_en_signals`) into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - kept `FlattenedDT` as compatibility facade delegating `generate_wen_en_signals(...)`,
  - maintained strict behavior-preserving structure-first decomposition (no intended HDL semantic deltas).
- Latest extraction slice for this phase:
  - moved intermediate-signal declaration emission ownership (`generate_intermediate_signal_declarations`) into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - kept `FlattenedDT` as compatibility facade delegating `generate_intermediate_signal_declarations(...)`,
  - maintained strict behavior-preserving structure-first decomposition (no intended HDL semantic deltas).
- Current extraction slice for this phase:
  - moved combinational-mux emission ownership (`generate_comb_mux`) into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - kept `FlattenedDT` as compatibility facade delegating `generate_comb_mux(...)`,
  - maintained strict behavior-preserving structure-first decomposition (no intended HDL semantic deltas).
- Latest extraction slice for this phase:
  - moved flop-mux emission ownership (`generate_flop_mux`) into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - kept `FlattenedDT` as compatibility facade delegating `generate_flop_mux(...)`,
  - maintained strict behavior-preserving structure-first decomposition (no intended HDL semantic deltas).
- Rationale:
  - reduce monolithic file size and cognitive load,
  - improve ownership clarity before deeper backend splits,
  - preserve behavior by changing structure first and semantics later only when explicitly intended.
- Near-term follow-through:
  - continue backend-focused extractions in small parity-validated slices,
  - retain compatibility delegates until call sites converge and regressions remain stable.

## 2026-02-22: Phase-1 intent model clarification (`<-` vs `<=`)
- Assignment intent is now explicitly captured at AST assignment nodes (`assignment_intent`, `source_provenance`, `output_exposure`).
- The `<=` semantic intent is explicitly encoded as:
  - `register_style = input_named`
  - `lhs_binding = flop_d_input`
  - `immediate_visibility = same_cycle_on_d_input`
  - `hold_policy = q_feedback_when_no_enable`
- The `<-` semantic intent is explicitly encoded as:
  - `register_style = output_named`
  - `lhs_binding = flop_q_output`
  - `hold_policy = q_feedback_when_no_enable`

This preserves the intended modeling distinction:
- `<-` names/registers the flop output (`Q`) as LHS.
- `<=` names the flop input side (`D`) as LHS while maintaining storage behavior by feedback when enables are inactive.

## Current parser/generator model
- Parse flow is modularized into `SignalManager`, `ExpressionBuilder`, `Parser`, and `SignalAnalyzer`.
- Fail-fast behavior uses `Carp::confess` with stack traces instead of silent parser failures.
- The regression baseline remains CLI-level (`prove -v t/01-regression.t`) to validate real generation paths.

## Assignment semantics and safety policy
### Semantics
- `=` is combinational.
- `<-` and `<=` are synchronous/flopped forms.

### Safety rule
- Combinational assignments must not create self-dependency:
  - direct (`A = A`)
  - indirect/transitive (`A = f(B)`, `B = g(A)`)
- Synchronous feedback is valid (`A <- A`) and intentionally preserved.

## Why graph-based combinational validation was chosen
Direct text checks are insufficient because harmful dependence can be indirect.  
Decision:
- Track combinational dependencies as graph edges (`lhs -> rhs signal`) during parse.
- Validate cycle reachability per combinational target before module return.
- Reject with explicit error if any path returns to the same target.

Benefits:
- One generalized guard handles all `A = f(...)` cases.
- Order-independent detection (works regardless of statement order in source).
- Clear extension point for future combinational rule checks.

## Parser improvements retained
- Compound update shorthand and inline forms are supported:
  - `(++ sig)`, `(-- sig)`, `(+=K sig)`, `(-=K sig)`
  - `(A <- B (+= 2))`, `(A = B (-= 1))`
- Packed nested condition encoding is handled:
  - `['<', [cond, ...]]`
  - `['<!', [cond, ...]]`
- Scalar negation tokens and packed operands are normalized in expression parsing.

## Backend status rationale
- Verilog path exists via SystemVerilog emission followed by deterministic textual lowering.
- VHDL path is intentionally explicit not-implemented rather than failing with missing method errors.
- This prevents ambiguous failures and keeps CLI behavior predictable.

## Documentation consolidation policy (current)
- Canonical top-level docs:
  - `README.md` (overview + quickstart)
  - `CHANGES.md` (persistent technical history)
  - `DEVELOPMENT_NOTES.md` (this file; rationale and context)
- Canonical user guide:
  - `docs/USER_GUIDE.md`
- Investigation-era and duplicate docs are removed once their conclusions are merged into canonical files.

## Ongoing engineering expectations
- Keep debug messages traceable with clear `[file][function()]` context.
- Prefer AST-based generation/transforms over regex-driven rewrites.
- Add focused regression tests for every parser/generator rule that can silently regress.

## Legacy `fx/perl/FSMGen.pm` reference analysis (full)
This section preserves the detailed legacy analysis so future work can port behavior intentionally, not accidentally.

### Scope analyzed
The legacy flow analysis covered:
- `fx/bin/fsmgen`
- `fx/perl/FSMGen.pm`
- `fx/perl/PPlugin.pm`, `PathSearch.pm`, `Lispish.pm`, `LinkedSpec.pm`, `LinkedRE.pm`, `RTLUtils.pm`, `Global.pm`, `HUtils.pm`
- `fx/conf/fsmgen.conf`, `fx/conf/fxstart.conf`, `fx/perl/env.conf`
- `fx/plugin/fsmgen.plg`
- `fx/specs/Lispish.spec`, `fx/specs/DT.spec`, `fx/specs/pplugin.spec`

### Legacy execution model
Primary invocation:
- `fx/bin/fsmgen` parsed CLI options, then called `FSMGen::start_from_file(...)`.

Entry functions in `FSMGen.pm`:
- `start_from_file`
- `top_from_tree`
- `top_from_string`

Initialization chain:
1. Merge user config with `Global->set('fsmgen')`.
2. Parse source into Lispish ATree (`fsm_file_load` / `Lispish::multi`).
3. Classify top-level forms (`?define:*`, `?fsm:*`, `?top:*`) in `fsm_initialize`.
4. Run either FSM compile flow (`fsm_analyze`/`fsm_top_gen`) or top composition flow (`top_exec`) depending on form.

### Legacy FSM compile pipeline (from `FSMGen.pm`)
Main path:
- `fsm_analyze` -> `fsm_analyze_jo` -> `fsm_walk` -> `fsm_drive_wen` -> `fsm_entity_gen` -> `fsm_architecture_gen` -> `create_data_path` -> `create_top` -> `drive_modules`.

#### `fsm_walk` responsibilities
Handled per-FSM top entries:
- state decision trees (`state_name`)
- standalone decision trees (`-name`)
- async reset (`:=`)
- sync reset (`:<`; hook present, effectively not fully realized)
- shared sections (`+system`, `+size`, etc.)

#### DT propagation and node types
`dtree_walk` / `dtree_node_iterate` handled:
- assignments
- transitions (`->`)
- test nodes (`?signal`, boolean and shortcut forms)
- repeat expansion (`?repeat:N`)
- logical expressions
- increment/decrement shorthand rewrites

### Assignment semantics in legacy flow
Legacy intent encoded by operator families:
- `A <- B` : register output named `A` (`Q`-named style)
- `A <= B` : register input/mux side named `A` (D-input named style)
- `A = B`  : combinational
- `A <-= B` (`rm`) and `A <=+ B` (`mr`) variants for dual visibility needs
- `A <N B` (`pN`) pulse-style form with exact-delay intent (`Q+N`) for a one-cycle pulse
- auto update shorthands rewritten to canonical assignment structures:
  - `++`, `--`, `+=K`, `-=K`

RHS elaborations supported:
- slices (`sig[i]`, `sig[i:j]`)
- literal handling with width inference/normalization
- local helper RHS signals for slice/incdec elaboration

### Authoritative clarification for `<N` / `pN`
- User-intended semantics: `<N` means an exact delayed pulse request where the one-cycle pulse is emitted at decision cycle `Q+N`.
- `N` is a delay/latency parameter, not a pulse-width parameter.
- Legacy comments/code paths mention pulse behavior but pulse-specific backend realization was not completed in the original implementation.

### WEN/OWEN architecture (core legacy strength)
Legacy flow constructed enables in layered steps:
1. DT-local WENs:
   - built from condition stack (`cstack`) at each traversal point.
2. DT-level per-(assignment_type,LHS,RHS) OR enables:
   - `dtowens` aggregation.
3. FSM-level per-(assignment_type,LHS,RHS) enable:
   - OR across all controlling DTs (`fsmowens` mapping).

Notable behavior:
- State-variable-targeted enables were treated differently from non-state outputs.
- State-selection constants and selection signals were generated as one-hot controls.
- Enable naming and grouping were deterministic and central to generated mux/control structure.

### Legacy entity/architecture generation
`fsm_entity_gen` and `fsm_architecture_gen` emitted:
- system/control/output ports
- EQ signals
- local WEN and OR-WEN signals
- state type/encoding support
- state register process
- slice/helper assignments

This produced a control block with explicit, traceable control enables.

### Legacy datapath generation
`create_data_path` built datapath logic from assignment groupings:
- Grouped all assignments by LHS/RHS and assignment type.
- Built selection constants (typically one-hot) and selection signals.
- Built per-LHS mux-style next/output equations.
- Generated register processes for non-combinational classes.
- Applied hold/feedback defaults when no enable path active.
- Handled tricky LHS/RHS overlap cases (avoid accidental top exposure by default).

### Legacy top generation and interface policy
`create_top` and related architecture wiring implemented:
- connect-by-name composition across generated modules
- automatic top interface synthesis
- signal vs port classification based on producer/consumer directions
- explicit output override via `>` suffix semantics
- filtering of internal feedback nets from top outputs unless explicitly requested

This behavior was practical and production-oriented for control/datapath partitioning.

### Legacy composition DSL capabilities (`top_exec`)
`top_exec` supported a composition/meta flow with forms like:
- `?fsmc` (compile FSM collections)
- `?rtl` (bind external RTL entities)
- `?ports`
- `?toplink`
- `?top`
- macro expansion via `?&...`

Plus plugin hook phases (via `.plg`):
- `cclausearch`, `declarch`, `beginarch`, `endarch`, etc.

### Legacy strengths worth preserving
1. Layered enable architecture (DT local -> DT grouped -> FSM grouped).
2. Clear semantic split of `<-` vs `<=`.
3. Robust practical interface policy (`auto` + explicit override).
4. Datapath/control decomposition based on grouped assignment intent.
5. Rich composition workflow for building larger tops.

### Legacy fragilities to avoid reintroducing
1. Dynamic/eval-heavy parser/plugin infrastructure (`LinkedSpec` + plugin eval model).
2. Large mutable global hash state and implicit contracts between passes.
3. Partially implemented branches mixed into production paths.
4. Width/type inference scattered across many late-stage transformations.

### Modernization mapping (why this analysis matters)
Current modernization direction is to port legacy strengths into:
- explicit AST intent metadata (now in phase 1)
- deterministic synthesis passes (future `EnableGraph`/composition layers)
- backend-independent lowering
- typed extension APIs instead of eval-based plugin semantics

This section is the reference baseline for deciding whether a behavior is:
- intentionally preserved,
- intentionally changed,
- or still pending implementation.

## 2026-02-22: Assignment-family reference (`c`, `r`, `m`, `rm`, `mr`, `pN`)
This section captures the authoritative operator mapping and the finalized implementation intent.

### Operator family mapping (legacy intent, now explicit in modern metadata)
- `A = B`  -> `c` (combinational)
- `A <- B` -> `r` (register-output named; LHS is Q-facing)
- `A <= B` -> `m` (mux/D-input named; LHS is D-facing visible net)
- `A <-= B` -> `rm` (`r` + expose `next_A`)
- `A <=+ B` -> `mr` (`m` + expose `A_r`)
- `A <N B` -> `pN` (delayed pulse family)

### `<=+` (`mr`) behavior
- Classified as `mr`, with regular `m` behavior for main LHS datapath semantics.
- Also exposes a Q-side mirror output `<lhs>_r`.
- In generated HDL this is realized by driving `<lhs>_r` from the corresponding flop-feedback node.

### Authoritative `pN` interpretation (must not regress)
`pN` is **not** a duration operator.  
It is an exact-delay pulse request:
- Decision cycle is `Q`.
- Pulse emission cycle is exactly `Q+N`.
- Pulse width is exactly one cycle.
- Polarity is defined by RHS level:
  - `<N 1`: positive pulse (rest `0`, pulse `1`, i.e. `0->1->0`)
  - `<N 0`: negative pulse (rest `1`, pulse `0`, i.e. `1->0->1`)

### Legacy note vs modern implementation
- Legacy comments in `fx/perl/FSMGen.pm` mention pulse semantics and may read like “N-cycle pulse length”.
- Legacy backend path was incomplete for dedicated pulse realization.
- Modernized backend now treats `pN` as exact `Q+N` one-cycle pulse semantics (delay, not duration), matching the clarified framework intent.

## 2026-02-22: Hardening pass after assignment-family implementation
### Edge-case semantics now regression-locked
- Added explicit tests for `pN` with `N=0` to lock immediate-cycle delayed pulse behavior:
  - `<0 1` -> positive one-cycle pulse with rest `0`.
  - `<0 0` -> negative one-cycle pulse with rest `1`.
- Added explicit conflict-rejection regression coverage:
  - mixed combinational + sequential operators on same LHS,
  - mixed pulse-delayed + non-pulse sequential operators on same LHS,
  - multiple pulse delays on same LHS.
- Added explicit parser rejection coverage for invalid `<N` RHS (must be literal `0` or `1`).

### Snapshot strategy for rm/mr/pN
- Introduced targeted HDL golden snapshots (not only regex-based checks) for:
  - module ports (`next_*` and `*_r` exposure/width),
  - rm (`<-=`) emitted block,
  - mr (`<=+`) emitted block,
  - pN delayed pulse blocks.
- Rationale:
  - protect behavioral semantics *and* emitted structural shape from accidental drift.

### Enable-synthesis extraction seam (slice start)
- Added `FSM::Synthesis::EnableGraph` as an orchestration seam for enable synthesis.
- `FlattenedDT` now delegates complete enable-structure generation through this layer.
- This is an intentional first extraction step:
  - behavior-preserving refactor first,
  - deeper decomposition can proceed in subsequent slices with reduced risk.
- Latest behavior-preserving increment:
  - RHS grouping (`group_assignments_by_rhs`) now also runs through `EnableGraph`,
  - `FlattenedDT` delegates that step instead of owning the grouping implementation directly.
- Newest behavior-preserving increment:
  - multiplexer configuration assembly (`build_multiplexer_config`) now also runs through `EnableGraph`,
  - `FlattenedDT` delegates that step, further separating synthesis orchestration from backend monolith code.
- Latest behavior-preserving increment:
  - unified assignment-analysis orchestration (`build_unified_assignment_analysis`) now runs through `EnableGraph`,
  - `FlattenedDT` delegates the full per-LHS phase-1 analysis loop to the synthesis layer while reusing existing delegated sub-steps.
- Newest behavior-preserving increment:
  - unified phase-2 enable emission orchestration (`generate_unified_wen_en_signals`) now runs through `EnableGraph`,
  - DT-specific and LHS-level enable emitters (`generate_dt_enables_from_analysis`, `generate_lhs_enables_from_analysis`) now run through `EnableGraph`,
  - `FlattenedDT` delegates these phase-2 WEN/EN generation entrypoints to the synthesis layer.
- Latest behavior-preserving increment:
  - unified phase-3 assignment emission orchestration (`generate_signal_assignments`) now runs through `EnableGraph`,
  - `FlattenedDT` delegates this phase-3 multiplexer-emission entrypoint while retaining existing per-assignment-type mux emitters in `FlattenedDT`.
- Newest behavior-preserving increment:
  - unified combinational mux emission (`generate_unified_comb_mux`) now runs through `EnableGraph`,
  - phase-3 orchestration in `EnableGraph` now invokes its local combinational mux emitter,
  - `FlattenedDT` delegates the combinational mux emitter entrypoint to the synthesis layer.
- Latest behavior-preserving increment:
  - unified flop mux emission (`generate_unified_flop_mux`) now runs through `EnableGraph`,
  - phase-3 orchestration in `EnableGraph` now invokes its local flop mux emitter,
  - `FlattenedDT` delegates the flop mux emitter entrypoint to the synthesis layer.
- Session continuity policy increment:
  - added `MEMORY.md` as a live, compact resumption artifact for crash/session-handoff recovery,
  - mandated update order after each completed task: `MEMORY.md` first, then other affected live docs, then commit workflow,
  - `MEMORY.md` now carries fast-start context (recent milestones, active architecture status, and immediate next-step orientation).
- Latest behavior-preserving increment:
  - unified pulse-delay emission (`generate_unified_pulse_delay_logic`) now runs through `EnableGraph`,
  - phase-3 orchestration in `EnableGraph` now invokes its local pulse-delay emitter,
  - `FlattenedDT` delegates the pulse-delay emitter entrypoint to the synthesis layer.
- Newest behavior-preserving increment:
  - pulse helper analysis methods (`get_pulse_delay_cycles_for_lhs`, `get_pulse_active_level_for_lhs`, `normalize_rhs_logic_level`) now run through `EnableGraph`,
  - `EnableGraph` pulse-delay emission now resolves delay/active-level metadata through local helper ownership,
  - `FlattenedDT` retains compatibility delegations for these helper methods.
- Latest behavior-preserving increment:
  - enable naming helpers (`clean_signal_name`, `generate_rhs_based_enable_name`) now run through `EnableGraph`,
  - `EnableGraph` enable-structure generation now resolves naming through local helper ownership,
  - `FlattenedDT` retains compatibility delegations for these naming helper methods.
- Newest behavior-preserving increment:
  - assignment-type helpers (`signal_uses_register_assignment`, `get_signal_assignment_type`) now run through `EnableGraph`,
  - `EnableGraph` phase-3 mux/pulse selection path now resolves assignment families through local helper ownership,
  - `FlattenedDT` retains compatibility delegations for these assignment-type helper methods.
- Latest behavior-preserving increment:
  - driven-signal classification (`get_driven_signals`) now runs through `EnableGraph`,
  - `EnableGraph` now owns auxiliary output exposure classification for sequential dual families (`next_<lhs>` for `rm`, `<lhs>_r` for `mr`) using local assignment-type helper ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint so module declaration logic remains behavior-identical while ownership shifts.
- Newest behavior-preserving increment:
  - reset-value resolution (`get_reset_value`) now runs through `EnableGraph`,
  - `FlattenedDT` retains a compatibility delegation entrypoint for reset-value queries,
  - reset-state and reset-metadata discovery remains in existing `FlattenedDT` helper methods for now, enabling staged extraction without semantic drift.
- Latest behavior-preserving increment:
  - default-value resolution (`get_default_value`) now runs through `EnableGraph`,
  - `FlattenedDT` retains a compatibility delegation entrypoint for default-value queries,
  - AST-based default-value lookup flow (`get_default_value_from_ast`) remains behavior-identical and now lands on `EnableGraph` ownership through delegation.
- Newest behavior-preserving increment:
  - signal-info discovery (`get_signal_info`) now runs through `EnableGraph`,
  - `FlattenedDT` retains a compatibility delegation entrypoint for signal-info queries,
  - `EnableGraph` reset-value resolution now calls local signal-info ownership while preserving staged delegation for reset-state/explicit-reset helpers.
- Latest behavior-preserving increment:
  - explicit-reset discovery (`get_explicit_reset_value`) now runs through `EnableGraph`,
  - `FlattenedDT` retains a compatibility delegation entrypoint for explicit-reset queries,
  - `EnableGraph` reset-value resolution now calls local explicit-reset ownership while preserving staged delegation for reset-state helper logic.
- Newest behavior-preserving increment:
  - reset-state discovery (`get_fsm_reset_state`) now runs through `EnableGraph`,
  - `FlattenedDT` retains a compatibility delegation entrypoint for reset-state queries,
  - `EnableGraph` reset-value resolution now calls local reset-state ownership for state-variable reset behavior.
- Latest behavior-preserving increment:
  - AST reset-value lookup (`get_reset_value_from_ast`) now runs through `EnableGraph`,
  - `EnableGraph` unified flop-mux emission now calls local AST reset-value ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for AST reset-value queries.
- Newest behavior-preserving increment:
  - AST default-value lookup (`get_default_value_from_ast`) now runs through `EnableGraph`,
  - `EnableGraph` multiplexer config assembly now calls local AST default-value ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for AST default-value queries.
- Latest behavior-preserving increment:
  - explicit-reset configuration setter (`set_explicit_reset_values`) now runs through `EnableGraph`,
  - `FlattenedDT` retains a compatibility delegation entrypoint for explicit-reset configuration updates,
  - `EnableGraph` now owns writes to explicit reset configuration consumed by reset-resolution helper paths.
- Newest behavior-preserving increment:
  - FSM module-reference setter (`set_fsm_module_reference`) now runs through `EnableGraph`,
  - `FlattenedDT` retains a compatibility delegation entrypoint for FSM module-reference storage,
  - `EnableGraph` now owns writes to the shared FSM module reference used by signal-info/reset helper paths.
- Latest behavior-preserving increment:
  - register-classification helpers (`is_register`, `fallback_register_analysis_from_assignments`) now run through `EnableGraph`,
  - `EnableGraph` multiplexer configuration assembly now resolves register-vs-combinational classification through local helper ownership,
  - `FlattenedDT` retains compatibility delegation entrypoints for these register-classification helper paths.
- Newest behavior-preserving increment:
  - AST signal-name extraction helper (`extract_signal_name_from_ast`) now runs through `EnableGraph`,
  - `EnableGraph` AST reset/default helper paths now resolve signal names through local helper ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for AST signal-name extraction.
- Latest behavior-preserving increment:
  - LHS-width analysis helper (`get_lhs_width_from_analysis`) now runs through `EnableGraph`,
  - `EnableGraph` pulse-delay emission now resolves target width through local helper ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for LHS-width analysis.
- Newest behavior-preserving increment:
  - intermediate-signal AST tracker (`track_ast_intermediate_signals`) now runs through `EnableGraph`,
  - `EnableGraph` DT/LHS enable emission paths now call local intermediate-signal tracking ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for intermediate-signal AST tracking.
- Latest behavior-preserving increment:
  - intermediate-signal classification helper (`is_intermediate_signal`) now runs through `EnableGraph`,
  - `EnableGraph` intermediate-signal AST tracking path now calls local classification ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for intermediate-signal classification.
- Newest behavior-preserving increment:
  - AST-based intermediate classification helper (`is_signal_ast_based_intermediate`) now runs through `EnableGraph`,
  - `EnableGraph` intermediate-signal classification path now calls local AST-based classification ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for AST-based intermediate classification.
- Latest behavior-preserving increment:
  - AST factorization operator helper (`_ast_contains_factorizable_operators`) now runs through `EnableGraph`,
  - `EnableGraph` AST-based intermediate classification path now calls local operator-analysis ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for AST factorization operator analysis.
- Newest behavior-preserving increment:
  - arithmetic-operation helper (`is_arithmetic_operation`) now runs through `EnableGraph`,
  - `EnableGraph` AST factorization operator-analysis path now calls local arithmetic-operation ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for arithmetic-operation helper paths.
- Latest behavior-preserving increment:
  - logical-operation helper (`is_logical_operation`) now runs through `EnableGraph`,
  - `EnableGraph` AST factorization operator-analysis path now calls local logical-operation ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for logical-operation helper paths.
- Newest behavior-preserving increment:
  - logical-factorization policy helper (`should_factor_logical_operation`) now runs through `EnableGraph`,
  - `EnableGraph` AST factorization operator-analysis path now calls local logical-factorization policy ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for logical-factorization policy helper paths.
- Latest behavior-preserving increment:
  - frequent-logical-usage helper (`contains_frequently_used_operations`) now runs through `EnableGraph`,
  - `EnableGraph` logical-factorization policy path now calls local frequent-logical-usage ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for frequent-logical-usage helper paths.
- Newest behavior-preserving increment:
  - intermediate-signal expression resolver (`get_intermediate_signal_expression`) now runs through `EnableGraph`,
  - `EnableGraph` frequent-logical-usage helper path now calls local intermediate-signal expression ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for intermediate-signal expression resolver paths.
- Latest behavior-preserving increment:
  - intermediate-signal expression synthesis helper (`generate_expression_from_signal_name`) now runs through `EnableGraph`,
  - `EnableGraph` intermediate-signal expression resolver path now calls local expression-synthesis ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for intermediate-signal expression synthesis helper paths.
- Newest behavior-preserving increment:
  - AST-based intermediate-name metadata helper (`_signal_name_indicates_ast_operators`) now runs through `EnableGraph`,
  - `EnableGraph` AST intermediate classification path now calls local intermediate-name metadata ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for AST-based intermediate-name metadata helper paths.
- Latest behavior-preserving increment:
  - AST-to-SystemVerilog rendering helper (`ast_to_systemverilog`) now runs through `EnableGraph`,
  - `EnableGraph` DT/LHS enable emission paths now call local AST rendering ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for AST-to-SystemVerilog rendering helper paths.
- Newest behavior-preserving increment:
  - AST signal-reference traversal helper (`ast_contains_signal`) now runs through `Backend::SystemVerilog`,
  - backend final-expression usage-check paths now call local AST signal-reference traversal ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for AST signal-reference traversal helper paths.
- Latest behavior-preserving increment:
  - substitution-reference usage helper (`is_signal_referenced_in_substitutions`) now runs through `Backend::SystemVerilog`,
  - backend AST/string filtering paths now call local substitution-reference usage ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for substitution-reference usage helper paths.
- Newest behavior-preserving increment:
  - intermediate-signal dependency ordering helper (`topologically_sort_signals`) now runs through `Backend::SystemVerilog`,
  - backend consolidated intermediate-signal emission now calls local dependency ordering ownership,
  - `FlattenedDT` retains a compatibility delegation entrypoint for dependency ordering helper paths.
- Latest behavior-preserving increment:
  - backend factorization/filtering callsites were converged to backend-local ownership in `Backend::SystemVerilog`,
  - callsites now invoke local helper ownership for `is_signal_referenced_in_substitutions`, `run_global_ast_factorization`, `feed_asts_to_factorizer`, `count_unary_negations_in_original_expressions`, `update_original_asts_with_substituted_versions`, and `run_second_pass_factorization`,
  - this removes backend round-trips through `FlattenedDT` delegation while preserving output and test behavior.
- Newest behavior-preserving increment:
  - second-pass AST feed checks were converged to backend-local `ast_contains_intermediate_signals` ownership in `Backend::SystemVerilog`,
  - DT/LHS/assignment condition second-pass gating now calls local intermediate-signal detection ownership,
  - this removes remaining backend delegation round-trips for this helper path while preserving output/test behavior.
- Latest behavior-preserving increment:
  - backend unified WEN/EN generation callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - phase-2 WEN/EN emission now invokes `enable_graph->generate_unified_wen_en_signals(...)` directly,
  - this removes the backend delegation round-trip through `FlattenedDT` for this path while preserving output/test behavior.
- Newest behavior-preserving increment:
  - backend intermediate-signal expression lookup callsites were converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - consolidated and declaration emission paths now invoke `enable_graph->get_intermediate_signal_expression(...)` directly,
  - this removes remaining backend delegation round-trips through `FlattenedDT` for intermediate-signal expression resolution while preserving output/test behavior.
- Latest behavior-preserving increment:
  - backend driven-signal classification callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - module-declaration port-direction analysis now invokes `enable_graph->get_driven_signals(...)` directly,
  - this removes the backend delegation round-trip through `FlattenedDT` for driven-signal lookup while preserving output/test behavior.
- Newest behavior-preserving increment:
  - backend assignment-type classification callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - internal-signal declaration analysis now invokes `enable_graph->get_signal_assignment_type(...)` directly,
  - this removes the backend delegation round-trip through `FlattenedDT` for assignment-type lookup while preserving output/test behavior.
- Latest behavior-preserving increment:
  - backend LHS-width analysis callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - internal-signal declaration analysis now invokes `enable_graph->get_lhs_width_from_analysis(...)` directly,
  - this removes the backend delegation round-trip through `FlattenedDT` for LHS-width lookup while preserving output/test behavior.
- Newest behavior-preserving increment:
  - backend pulse-delay-cycle lookup callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - internal-signal declaration analysis now invokes `enable_graph->get_pulse_delay_cycles_for_lhs(...)` directly,
  - this removes the backend delegation round-trip through `FlattenedDT` for pulse-delay-cycle lookup while preserving output/test behavior.
- Latest behavior-preserving increment:
  - backend reset-value lookup callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - flop-mux reset emission now invokes `enable_graph->get_reset_value(...)` directly,
  - this removes the backend delegation round-trip through `FlattenedDT` for reset-value lookup while preserving output/test behavior.
- Newest behavior-preserving increment:
  - backend default-value lookup callsites were converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - comb/flop mux default assignment emission now invokes `enable_graph->get_default_value(...)` directly,
  - this removes backend delegation round-trips through `FlattenedDT` for default-value lookup while preserving output/test behavior.
- Latest behavior-preserving increment:
  - backend intermediate-signal classification callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - recursive intermediate-signal detection now invokes `enable_graph->is_intermediate_signal(...)` directly,
  - this removes the backend delegation round-trip through `FlattenedDT` for this classification path while preserving output/test behavior.
- Newest behavior-preserving increment:
  - backend arithmetic-operation classification callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - AST filtering now invokes `enable_graph->is_arithmetic_operation(...)` directly,
  - this removes the backend delegation round-trip through `FlattenedDT` for arithmetic classification while preserving output/test behavior.
- Latest behavior-preserving increment:
  - backend logical-operation classification callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - AST filtering now invokes `enable_graph->is_logical_operation(...)` directly,
  - this removes the backend delegation round-trip through `FlattenedDT` for logical classification while preserving output/test behavior.
- Newest behavior-preserving increment:
  - backend logical-factorization policy callsite was converged to `EnableGraph` ownership in `Backend::SystemVerilog`,
  - AST filtering now invokes `enable_graph->should_factor_logical_operation(...)` directly,
  - this removes the backend delegation round-trip through `FlattenedDT` for logical-factorization policy while preserving output/test behavior.
