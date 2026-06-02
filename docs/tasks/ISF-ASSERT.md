# ISF-ASSERT: `(assert COND [message])` verification intent

## Metadata

- Tree ID: `ISF-ASSERT`
- Status: `active`
- Roadmap lane: `R14` (ISF — high-level language richness, theme #3 intent capture)
- Created: `2026-06-02`
- Last updated: `2026-06-02`
- Owner: repo-local workflow

## Goal

Capture a design-intent assertion in ISF and project it to a verification-only
SystemVerilog assertion — "at this point in the transaction, `COND` must hold":

```lisp
(assert (< level depth))                 ;; level must stay below depth here
(assert ready "ready must be high after grant")
```

This is genuine **intent capture** (the user's vision), not sugar — it does not
desugar to existing `.fsm` data ops, so it is a new (thin) lowering primitive.

## Architectural constraint (from the user)

There is **no direct ISF → SV path** — only **ISF → `.fsm` → SV** — and the
codebase honours that: both HDL-generation callers of
`GeneratedModuleEmitter::augment_with_runtime_assertions` build their
`module_info` from a parsed `.fsm` `$fsm_module`. The single-actor path
(`FSM::Pipeline::DirectGenerationOrchestrator`) is `.fsm` → `FSMGenFull` →
`$fsm_module` → `GeneratedModuleInfoBuilder` → `module_info` → emitter → SV; the
ATL generated-child path (`FSM::Composition::GeneratedChildRealizer`) is the same
shape over a parsed child `.fsm`. So the assertion must survive the `.fsm` text
and reach the backend through `module_info`.

The working assertions (selector-conflict `$onehot0`, standalone-DT) are emitted
from `module_info`. The temporal-contract assert emitter
(`temporal_contract_assertion_runtime_lines`) instead reads a `schedule_report`
argument — but **no HDL-generation caller passes one** (both callers pass only
`module_info`), so that block is effectively dead: it is *not* a back channel,
just an unwired parameter. That is exactly why `(contract …)` emits its computed
*fail signal* into the SV but never an `assert` statement — the gap this construct
must avoid by riding through `module_info` like the `$onehot0` assertions do.

## Design (thin `.fsm` carrier, lean variant)

The expression machinery already round-trips perfectly (state assignments lower to
`.fsm` and back), so let the FSM compute the truth of the assertion and carry only
a **thin directive** naming the signal:

1. **ISF lowering** (`Scheduler::ISF`): `(assert COND)` at a transaction point
   lowers to (a) a combinational "hold" signal computed by ordinary FSM logic —
   `<tx>_assert_<n>_hold = (| (! <here-active>) COND)` ("when control is here,
   `COND` holds") — and (b) a `.fsm` directive `+assert` carrying the hold signal
   name + optional message. The hold signal round-trips like any FSM signal.
2. **`.fsm` carrier**: a `+assert` directive (mirroring `+size` / `+params`) of the
   form `(+assert (signal <hold>) (message "<msg>"))` — trivial to parse (a name
   + a string; no expression parsing needed in the directive itself).
3. **FSMGenFull parse**: parse `+assert` onto `$fsm_module` (an `assertions` list).
4. **module_info**: `GeneratedModuleInfoBuilder` surfaces `assertions` into
   `module_info` (parallel to the selector/standalone assertion metadata).
5. **HDL emission** (`GeneratedModuleEmitter`): a new
   `augment_with_immediate_assertions` reads `module_info`, emitting
   `assert (<hold>) else $error("...");` inside `` `ifndef SYNTHESIS `` (Verilog
   output stays assertion-free), wired into `augment_with_runtime_assertions`.

(The precise "here-active" guard signal and the exact directive shape are pinned
by the `.2` investigation; the lean carrier keeps `.fsm`/FSMGenFull changes
minimal.)

## Slice plan

- `.1` select + design (this doc) + precise read-only mechanics map. `done`.
- `.2` the `.fsm` `+assert` carrier: ISF emits it, FSMGenFull parses it onto the
  module, it round-trips (a focused round-trip test); no SV yet.
- `.3` HDL emission: `module_info` surfaces the assertion;
  `augment_with_immediate_assertions` emits the guarded SVA; verilator-lint +
  yosys clean; a `verilator --binary` testbench drives a passing and a failing
  case (the assertion fires only on violation).
- `.4` ISF surface polish: optional message, expression conditions, fail-closed
  validation; 13e/13g doc section + 13k row; `ISF_SPEC` registers the t/.

## First-cut semantic (decided 2026-06-02)

`(assert COND [message])` is a **transaction-level combinational invariant** —
"COND must hold every cycle" — emitted as `assert (COND) else $error(message)` in
an `always_comb` under `` `ifndef SYNTHESIS `` (Verilog output stays
assertion-free). This is the simplest *correct* semantic, genuinely useful for
safety/structural invariants, and end-to-end verifiable. State-guarded /
point-in-time asserts and temporal (`|->`) properties are explicit non-goals here
(temporal is what `(contract …)` already does); a later slice may add
`(assert COND at STATE)`-style guarding using the `<STATE>_en` signals.

## Implementation map (code-grounded; from the `.1` investigation)

Token shape: `(+assert (NAME COND_SEXPR "message") …)` — one section per module,
mirroring `+size`. Carry COND as an s-expr (FSMGenFull `ExpressionBuilder`
parses it); no pre-computed signal.

- **ISF lowerer** (`Scheduler/ISF/LoweringIR.pm`): add `assert` to
  `%SUPPORTED_TRANSACTION_CLAUSES{transaction}`; a clause case in
  `_build_transaction` (~L4970, mirroring `contract`) collects into a per-tx
  `@asserts` via a new `_ir_assert` (name `<tx>_assert_<n>`, cond, message; no
  state — it is combinational); thread `\@asserts` as the **11th** element of the
  `_build_transaction` return tuple (~L5045) and destructure it at **both** call
  sites — `_build_child_ir` (~L129) and `_build_parent_ir` (~L1127) — collecting
  into `@immediate_assertions`; add `immediate_assertions => …` to the parent IR
  (~L1213) and child IR (~L173) module hashes.
- **ISF emitter** (`Scheduler/ISF/Emitter/FSM.pm`): `_emit_asserts($ir)` after
  `_emit_size` (~L50) emits the `(+assert …)` section from
  `$ir->{immediate_assertions}`.
- **FSMGenFull parse** (`Adapter/FSMGenFull/Parser.pm`): add `+assert` to
  `supported_directives_description` (~L524) + a first-pass collector + a
  `parse_asserts_section` (mirroring `parse_size_section` ~L660) that parses each
  `(NAME COND msg)` (COND via `$self->{expression_builder}->parse_expression`),
  storing on `$fsm_module->{attributes}{immediate_assertions}`.
- **module_info** (`Pipeline/GeneratedModuleInfoBuilder.pm` `build_from_fsm_module`
  ~L48-62): surface `immediate_assertions => $fsm_module->{attributes}{immediate_assertions}`.
- **emit SVA** (`Backend/GeneratedModuleEmitter.pm`): new
  `immediate_assertion_runtime_lines` (template: `selector_conflict_assertion_runtime_lines`
  ~L122) emitting `` `ifndef SYNTHESIS `` / `always_comb` / `assert (COND) else
  $error("msg")` / `endif`, wired into `augment_with_runtime_assertions` (~L310).

## Non-Goals

- Temporal / multi-cycle assertions (`assert property (… |-> …)`) — that is the
  existing `(contract …)`. This is an immediate boolean assertion at a point.
- Assertions in Verilog (non-SV) output — kept assertion-free, like contracts.
- `assume` / `cover` — possible later siblings.

## Acceptance Criteria

- `(assert COND [message])` projects to a verification-only SV assertion that
  fires exactly when `COND` is violated at that transaction point; verilator-lint
  + yosys clean; Verilog output assertion-free; a `verilator --binary` testbench
  confirms pass-vs-fail behaviour; malformed forms fail closed; a doc section +
  13k row + `ISF_SPEC` entry. Each leaf committed via `COMMIT.md`; full suite
  green.

## Blockers

- None — but it is a 4-layer feature (ISF lowerer, `.fsm`, FSMGenFull, backend
  emitter); sliced deliberately with verification at each layer.

## Changelog

- `2026-06-02`: Created at the user's request ("continue on (assert COND)"). Traced
  the single-actor assertion pipeline and confirmed the ISF → `.fsm` → SV
  constraint (no side channel); chose a thin `+assert` `.fsm` carrier over reusing
  the temporal-contract machinery (which does not emit an `assert` statement in the
  single-actor flow).
- `2026-06-02`: `.1` done — design + a precise read-only mechanics map of all four
  layers; first-cut semantic decided (transaction-level combinational invariant).
- `2026-06-02`: `.2` done — the `.fsm` `+assert` carrier round-trips.
  - ISF lowerer (`LoweringIR.pm`): `assert` added to the transaction clause
    allow-list; `_ir_assert` collects `(assert COND [msg])` into a per-tx `@asserts`
    (name `<tx>_assert_<n>`, COND rendered via `_format_isf_expr`, optional message),
    threaded as the 11th `_build_transaction` return element into the parent + child
    module IR `immediate_assertions`.
  - ISF emitter (`Emitter/FSM.pm`): `_emit_asserts` writes `(+assert (NAME COND
    ["msg"]) …)` after `+size` (skipped when empty).
  - FSMGenFull (`Parser.pm`): `+assert` added to the supported directives + first-pass
    collector + skip-list; `parse_asserts_section` parses each entry (Lispish
    head+grouped-rest form), parsing COND via the shared `ExpressionBuilder` and
    stashing on `$fsm_module->{attributes}{immediate_assertions}`.
  - `t/1410` (4 subtests): carrier emitted + round-trips; COND parses to a CoreAST
    expression rendering to SV (`level < depth`); optional message round-trips;
    multiple asserts; fail-closed (no condition / extra operands). Non-assert actors
    unaffected (verify-hdl clean; representative regression green). No SV emission
    yet — that is `.3`.
