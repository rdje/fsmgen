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

- `.1` select + design (this doc) + precise read-only mechanics map.
- `.2` the `.fsm` `+assert` carrier: ISF emits it, FSMGenFull parses it onto the
  module, it round-trips (a focused round-trip test); no SV yet.
- `.3` HDL emission: `module_info` surfaces the assertion;
  `augment_with_immediate_assertions` emits the guarded SVA; verilator-lint +
  yosys clean; a `verilator --binary` testbench drives a passing and a failing
  case (the assertion fires only on violation).
- `.4` ISF surface polish: optional message, expression conditions, fail-closed
  validation; 13e/13g doc section + 13k row; `ISF_SPEC` registers the t/.

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
