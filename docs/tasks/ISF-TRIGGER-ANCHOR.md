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
- `.3` **Monitor output-mode** — a property modifier that lowers a bounded-eventually
  `(within …)` to the arm/age/fail monitor (generalize `_contract_monitor_signals`);
  verilator-simulable; `verilator --binary --assert` proves arm→within-N→fail.
- `.4` **Inline (positioned)** — `(assert (within S N))` inside a transaction body
  anchors to its position (state-active trigger) via the monitor → contract parity.
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
