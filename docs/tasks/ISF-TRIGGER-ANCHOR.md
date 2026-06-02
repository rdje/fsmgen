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
  output-mode modifier per `0009`; it subsumes the standalone inline form — a bare
  `(within …)` stays the formal-only module-global property from `.2`, no ambiguous
  reinterpretation.)
- `.4` **Window-source parity** — `(monitor (within S N))` resolves `N` from a literal,
  transaction/actor parameter, actor constant, or qualified package scalar constant via
  the shared resolver — the same window sources as `(contract …)`. Closes the only
  capability gap blocking a lossless contract removal.
- `.5` **Ref (named)** — `(point NAME)` body-position marker + `(on … as NAME)` activation
  label (bare `as`, like `(sample … as …)`/`(spawn … as …)` — NOT `:as`, user 2026-06-02);
  `(at NAME)` trigger leaf → `(state_active <bound state>)`. Module-wide name→state bindings
  collected during lowering; `(at NAME)` in a check condition resolved (post-lowering) to the
  bound state's `state_active`; fail-closed on an unbound NAME.
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
- `2026-06-02`: `.4` done — **window-source parity** for `(monitor (within S N))`. `N` now
  resolves from a literal, a same-transaction/actor scalar parameter, an actor constant, or a
  qualified package scalar constant (the shared `_temporal_contract_within_cycles` resolver) —
  the same window sources `(contract …)` accepts. This closes the last capability gap blocking a
  lossless contract removal.
  - The literal `N` keeps a clear monitor-specific message ("N must be a positive integer");
    identifier windows defer to the shared resolver. Extended the transaction-`params` usage gate
    (`_validate_transaction_parameter_clauses`) with `_transaction_params_used_by_monitor_window`
    + `_monitor_within_value_if_present`, so a param consumed only by a monitor window is accepted
    (its diagnostic now reads "temporal contract / monitor windows").
  - Verified: `t/1413` + a transaction/actor-param window subtest (age compares to N-1: ACK_WINDOW=4
    → 3, ACTOR_WIN=8 → 7); `--verify-hdl` verilator-lint + yosys clean on a param-window monitor;
    all contract-window tests (`t/1362/1364/1365/1366`) green (`t/1365` param-gate diagnostic
    updated for the new wording).
  - **`.6c` cleanup note:** the shared resolver still says "contract" / "temporal contract" / mentions
    `eventually` in its rarer identifier-window error paths; that wording is neutralized in `.6c` when
    the resolver is renamed as part of de-contract-ifying the lowerer.
  - Remaining: `.5` Ref named `(at NAME)`, `.6` remove `(contract …)`.
- `2026-06-02`: `.6` done — **`(contract …)` removed.** The clause is no longer recognized (it falls
  to the generic unsupported-clause diagnostic); the inline monitored form `(assert (monitor (within
  S N)))` is the lossless replacement (same arm/age/fail engine, now also asserting `(! fail)`).
  - **Lowerer/parser (LoweringIR + ISF Parser):** removed the `contract` whitelist entry, the clause
    validation + lowering dispatch, `_ir_contract`, `_parse_bounded_eventual_contract_clause`,
    `_bounded_eventual_contract_parts`, `_validate_contract_monitor_signal_names`,
    `_contract_monitor_signals`, the contract-window param-gate helpers
    (`_transaction_params_used_by_contract_window`/`_transaction_contract_window_param_names`/
    `_contract_within_value_if_present`), the rule activation-override contract-window checks
    (`_activation_override_preserves_contract_window_param`), and the parser's contract enum-rejection
    block + `_reject_contract_window_enum_member_value`. KEPT (shared with `(monitor …)`):
    `_build_eventually_monitor`, `_monitor_signals_for_prefix`, `_temporal_contract_within_cycles`,
    `_contract_package_constant_window_cycles`, the `kind=>'contract'` arm-state kind, and the
    `temporal_contracts` report plumbing (now always `[]`, retained for schema-version-1 stability).
  - **Report fix (latent `.3` bug):** `JSON::_transaction_summary` grouped states by a regex that knew
    `contract` but not `assert`/`cover`/`assume`, so a monitor arm state (`*_assert_N`) fell under an
    `undef` transaction key (uninitialized-value warning). Taught the regex the check-kind prefixes.
  - **Tests:** deleted 9 contract-only tests (`t/1175/1224/1225/1254/1317/1362/1364/1365/1366`);
    updated 6 mixed tests (`t/1158/1180/1244/1255/1323/1367`) to drop/repurpose the contract case
    (swapping to `(monitor …)` where the bounded-eventually hardware was genuinely needed); cleaned the
    9 deleted entries from `ISF_SPEC.md`, the `tested_by` provenance in `ISFPublicInterfaceContract.pm`,
    the t/1144 expected list, and the t/1183 CI-tier fixture (→ a live rule/resource fixture).
  - **Docs:** reframed the book (13d/13h/13k/13-intent/14-backlog) + book-matrix audit (`t/1305`) and the
    `ISF_SPEC.md` / downstream-spec clause-authoring sections to the `(assert (monitor (within S N)))`
    form. Swapped the broken `isf/stream_stage_contract.isf` fixture's contract clause to the monitor.
  - Remaining: `.5` Ref named `(at NAME)`; `.6c` neutralize residual "contract" wording (resolver rename
    + ISF_SPEC/downstream lowering/report-schema prose, which describe the now-empty field).
- `2026-06-02`: `.5a` done — **Ref via `(point NAME)` + `(at NAME)`**. `(point NAME)` is a no-op
  pass-through labeled state (`${tn}_point_$i`, modeled on `(phase …)`); it records a module-wide
  `name → state` binding. `(at NAME)` in a check condition is resolved (post-lowering, once all
  transactions/bindings exist) to `(state_active <bound state>)` → SV `current_state == <STATE>`.
  - Threaded a `%point_bindings` map through `_build_transaction` (new param); `_ir_point` records
    bindings; `_resolve_at_references` rewrites `(at NAME)` in the `+assert` conditions (both the
    parent and child IR paths). Whitelisted `point` in the transaction clause set. Module-wide:
    an `(at NAME)` may reference a `(point …)` in another transaction. Unknown name + duplicate
    name fail closed.
  - Verified: `--verify-hdl` verilator-lint + yosys clean (`(=> (at armed) (within ack 3))` →
    `(current_state == MAIN_POINT_1) |-> ##[1:3] (ack)`, formal-only); `t/1416` (5 subtests:
    render+resolve, cross-transaction, unknown-name fail-closed, duplicate fail-closed, malformed);
    13d "Named anchors" subsection; `ISF_SPEC` registers `t/1416`.
  - Remaining: `.5b` activation label `(on SIGNAL as NAME)` (bare `as`); `.6c` wording cleanup.
- `2026-06-02`: `.5b` done — **activation label `(on SIGNAL as NAME)`** (bare `as`, user-approved
  over `:as`). `_validate_on_clause` accepts a single top-level `as NAME` label (alongside
  `(sample … as …)` sub-clauses); `_ir_on` (via `_on_activation_label`) binds NAME to the entry
  state `${tn}_idle_$i` in the shared module-wide `%point_bindings` map, so `(at NAME)` anchors a
  check to the accept/entry state. `(point …)` and `(on … as …)` share one name space (collision
  fails closed); a missing label name fails closed; coexists with `(sample …)` sub-clauses.
  - Verified: `--verify-hdl` clean (`(=> (at fired) (! ack))` → `(current_state == MAIN_IDLE_0) |->
    (!(ack))`); `t/1416` extended (now 9 subtests). 13d "Named anchors" gains the `(on … as NAME)`
    form. **ISF-TRIGGER-ANCHOR.5 (Ref) complete** — `(point NAME)` + `(on … as NAME)` + `(at NAME)`.
  - Remaining: `.6c` neutralize residual internal "contract" wording (rename the shared resolver).
- `2026-06-02`: `.5c` done — **Ref boundary fix (signal, not `state_active`)**. User flagged that
  `(at NAME)` → `(state_active <state>)` made the lowered assertion reference the FSM's `current_state`,
  crossing the ISF↔FSM line (the event + monitor forms are already signal-based). Re-anchored: a
  referenced `(point …)`/`(on … as …)` state now drives a 1-bit `*_active` signal (combinational,
  high while there — like the monitor's `arm`), generated **lazily** in `_resolve_at_references` only
  for points an `(at NAME)` actually references (no dead signals); `(at NAME)` resolves to that bare
  signal leaf. The ISF-originated assertion references only the signal; the state→signal derivation
  stays FSM-side.
  - Verified: `--verify-hdl` clean — `(=> (at armed) (within ack 3))` →
    `(main_point_1_active) |-> ##[1:3] (ack)` with `current_state` **absent** from the assertion
    (`main_point_1_active` is driven by `main_point_1_en` on the FSM side). `t/1416` updated (signal,
    not `state_active`); 13d "Named anchors" reworded. All three anchor forms (event/inline/ref) are
    now uniformly signal-based — ISF verification never touches `current_state`.
  - Remaining: `.6c` wording cleanup.
- `2026-06-02`: docs thoroughness pass (user: "thoroughly documented … with lot of examples;
  codebase and mdBook shall be in sync") — added a "Complete, runnable verification examples"
  subsection to 13d with **7 complete `(actor …)` examples** (trivial invariant → assert/assume/cover
  → monitor → event → named anchors → parameterized window → cross-transaction anchoring), each a
  full actor so the book example-lowering audit (`t/1376`) lowers + verifies them (now 60 fixtures).
  All doc audits green (`t/1376/1305/1304/1303/1170`).
