# ISF-TRIGGER-ANCHOR: trigger vocabulary + monitor output-mode; remove `(contract …)`

## Metadata

- Tree ID: `ISF-TRIGGER-ANCHOR`
- Status: `in-progress`
- Roadmap lane: `R14` (ISF — verification intent)
- Created: `2026-06-02`
- Last updated: `2026-06-02`
- Owner: repo-local workflow
- Decisions: `docs/decisions/0009-trigger-anchor-vocabulary.md`,
  `docs/decisions/0008-verification-property-language-unification.md`

## Goal (closes `0008` — removes `(contract …)`)

Give a bounded-eventually check three ways to name the anchor point it measures
from (the user asked for all three: "Inline, event and ref"), plus a
synthesizable-monitor output-mode, so `(contract …)` dissolves into the property
engine and is removed with **no capability gap**.

Every form lowers to one shape: `TRIGGER |-> (bounded-eventually) CONSEQUENT`.

```lisp
;; Event  — anchor to a signal edge (module-global)
(assert (after start (within ack 3)))         ;; $rose(start) |-> ##[1:3] ack

;; Inline — positioned in the transaction body, anchors "from here"
(transaction main
  (on start)
  (assert (within ack 3))                      ;; from this point, ack within 3
  (complete done))

;; Ref    — explicit named handle on a transaction point
(transaction main (on start :as p0) (complete done))
(assert (=> (at p0) (within ack 3)))
```

## Design

See `docs/decisions/0009`. Two orthogonal additions:

1. **Trigger vocabulary** — `(after SIG …)` → `$rose(SIG)`; Inline position →
   state-active of the clause's point; `(at NAME)` → state-active of a named point.
   All produce the antecedent boolean of the existing generalized `(=> A …)` form.
2. **Synthesizable-monitor output-mode** — lower a `(within S N)` consequent to the
   existing arm/age/fail monitor (`_contract_monitor_signals`, generalized so `arm`
   pulses from any trigger), making bounded-eventually simulable (not only formal).

`(contract …)` is then one redundant caller of the same engine → removed last.

## Slice plan

- `.1` select + design — `0009` + this tree. **(this slice)**
- `.2` **Event trigger** `(after SIG (within S N))` → `$rose(SIG) |-> ##[1:N] (S)`
  (formal-only; smallest end-to-end warm-up of the trigger vocabulary) + tests + docs.
- `.3` **Monitor output-mode + Inline (positioned)** — `(assert (monitor (within S N)))`
  written in a transaction body anchors to its position via the arm/age/fail monitor
  (generalized `_build_eventually_monitor`); verilator-simulable; `verilator --binary
  --assert` proves arm→within-N→fail. (The explicit `(monitor …)` wrapper is the
  output-mode modifier per `0009`; it subsumes the planned standalone `.4` inline form —
  a bare `(within …)` stays the formal-only module-global property from `.2`, no
  ambiguous reinterpretation.)
- `.4` *(folded into `.3`)* — the inline/positioned trigger ships as the `(monitor …)`
  body form above.
- `.5` **Ref (named)** — `(on … :as NAME)` binding + `(at NAME)` trigger leaf.
- `.6` **Remove `(contract …)`** — retarget parse/validate/`_ir_temporal_contract`
  to the property path; delete the clause surface; migrate tests
  (`t/1175/1224/1225/1254/1255/1362/1364/1365/1366`, …) + docs (13d/13h/13k/13-intent);
  one deliberate golden-reviewed slice. Hard-to-reverse — user-authorized (`0008`).

## Non-Goals

- Full SVA sequences (`throughout`/`until`/`s_eventually`/multi-step `##`).
- Multiple in-flight overlapping arms per trigger (monitor keeps `contract`'s
  single-pending `overlap_policy => 'fail'` semantics).

## Acceptance Criteria

- All three trigger forms lower correctly; bounded-eventually is verilator-simulable
  via the monitor output-mode and formal-only otherwise (checkability split honored).
- `verilator --binary --assert` proves the monitor fires iff `SIG` is absent within
  `N` cycles of the trigger; `--verify-hdl` verilator-lint + yosys clean throughout.
- `(contract …)` fully removed with no capability gap; full suite green every slice;
  zero unexplained golden churn.

## Blockers

- Builds on `ISF-ASSERT-CONCURRENT` + `ISF-PROPERTY-IMPLICATION` (both done).

## Changelog

- `2026-06-02`: `.1` — created on the user's "support all three / Inline, event and
  ref" go-ahead; decision `0009` records the design; build order is dependency-driven
  (Event → monitor output-mode → Inline → Ref → remove contract).
- `2026-06-02`: `.2` done — **Event trigger** `(after SIG CONS)` → `$rose(SIG) |-> (CONS)`.
  - `FSMGenFull::parse_check_property` detects the `after` head and builds a tagged
    `{ __property__, op: after_event, trigger, consequent }` (both parsed recursively,
    so the consequent may be `(within …)`/`(next …)`); a malformed `(after SIG)` (not
    exactly trigger + consequent) fails closed.
  - `GeneratedModuleInfoBuilder::_render_check_condition_sv` renders it to
    `$rose(<trigger>) |-> (<consequent>)`; `_property_is_formal_only` recurses into
    `trigger`, so `(after SIG bool)` is simulable and `(after SIG (within …))` is
    formal-only (delayed consequent) — the existing two-guard partition then routes
    them to `` `ifndef SYNTHESIS `` vs `` `ifdef FORMAL ``. `SignalAnalyzer` keep-alive
    walks the `trigger` so the edge signal survives as a port. No ISF-lowerer change
    (`_format_isf_expr` re-serializes the s-expression transparently).
  - Verified: `--verify-hdl` verilator-lint + yosys clean; `verilator --binary
    --assert` on `$rose(start) |-> (ack)` — silent when `ack` high on the start edge,
    FIRES `$error` when `ack` low on the edge. `t/1413` (5 subtests: within/bool render,
    formal-only flag, two-guard partition, keep-alive, fail-closed); 13d "Trigger
    anchors — `(after SIG …)`" subsection; `ISF_SPEC` registers `t/1413`.
  - Remaining: `.3` monitor output-mode (simulable bounded-eventually), `.4` Inline
    positioned, `.5` Ref named, `.6` remove `(contract …)`.
- `2026-06-02`: `.3` done — **synthesizable-monitor output-mode** `(assert (monitor
  (within S N)))` (this also delivers the **Inline/positioned** trigger). Lowers to the
  same arm-state + `arm`/`pending`/`age`/`fail` monitor DT that `(contract …)` uses,
  asserting `(! fail)` — a same-cycle boolean, so the temporal logic is in synthesizable
  hardware and the assertion is verilator-simulable.
  - Refactored `_ir_contract`'s monitor builder out into `_build_eventually_monitor`
    (signals via `_monitor_signals_for_prefix`); `(contract …)` now lowers byte-identically
    through it (verified by diffing the `.fsm`). New `_ir_monitor_check` + `_is_monitor_check`
    detect `(assert|cover|assume (monitor (within S N)))` in the clause dispatch, inject the
    arm state (positioned where the clause sits) + monitor DT + counters, and push a derived
    `(NAME kind (! fail) "msg")` into the `+assert` carrier. Entirely ISF-lowerer-side — no
    FSMGenFull/emitter change (the `(! fail)` boolean re-parses with existing machinery; the
    monitor DT rides the existing `temporal_contract_monitor` emission path). The fail bit
    stays an internal register — the assert reference does not promote it to a port.
  - Verified: `--verify-hdl` verilator-lint + yosys clean; `verilator --binary --assert`
    proves it — `fail` latches and `$error` fires when `ack` is absent within 3 cycles of
    arming, and stays silent when `ack` arrives inside the window (window measured from the
    cycle after the arm pulse, same as `contract`). `t/1413` extended (now 9 subtests:
    + arm-state/monitor-DT/`!fail`-assert lowering, simulable-not-formal-only, internal-not-port,
    three fail-closed forms). 13d "Synthesizable-monitor output mode" subsection. All contract
    tests (`t/1175/1224/1225/1254/1255/1362/1364/1365/1366/1367`) green — refactor is
    regression-clean.
  - Remaining: `.5` Ref named `(at NAME)`, `.6` remove `(contract …)` (now redundant with the
    inline monitored form).
