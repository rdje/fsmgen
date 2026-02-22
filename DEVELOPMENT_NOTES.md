# DEVELOPMENT_NOTES
This document captures engineering rationale, design constraints, and working decisions behind recent FSMGen behavior.

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
