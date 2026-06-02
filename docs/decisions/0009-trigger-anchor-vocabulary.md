# 0009 — Trigger-anchor vocabulary for bounded-eventually properties

- Date: 2026-06-02
- Type: architecture
- Status: accepted
- Resolves: the open "transaction-point trigger anchor" piece of
  [0008](0008-verification-property-language-unification.md) (the precondition for
  removing `(contract …)` with no capability gap).

## Context

`0008` decided to remove `(contract NAME (eventually SIG (within N)))` and replace
its bounded-liveness intent with the property language, but left one piece open:
how a check names the **anchor point** the bound is measured *from*.

`(contract …)` is a *positioned* clause — it sits at a point in a transaction's
clause sequence and lowers (today) to an arm-state + synthesizable monitor
(`arm`/`pending`/`age`/`fail`) meaning "from the cycle control reaches this point,
`SIG` must hold within `N` cycles." Plain `(assert/assume/cover …)` (after
`ISF-ASSERT-CONCURRENT`) is the opposite: a *module-global* concurrent property
checked every clock edge. To subsume `contract` losslessly the check needs a way to
say "from *this* point," and the user asked for all three natural spellings of that
(message 2026-06-02: "Inline, event and ref").

## Decision

"Support all three" decomposes into **two orthogonal additions**, not three
features — every form produces the same shape `TRIGGER |-> (bounded-eventually) CONSEQUENT`:

### 1. A small trigger vocabulary (three spellings of the antecedent)

| Form | Example | `TRIGGER` lowers to | Anchoring |
| --- | --- | --- | --- |
| **Event** | `(assert (after start (within ack 3)))` | `$rose(start)` (edge-detect in the monitor) | a signal edge; module-global |
| **Inline** (positioned) | `(assert (within ack 3))` *written inside the transaction body* | state-active of the clause's own position | implicit "from here" |
| **Ref** (named) | `(assert (=> (at p0) (within ack 3)))` with `(on start :as p0)` | state-active of the named point `p0` | explicit handle |

The already-shipped `(=> A B)` overlapping implication is just the most general
case where the trigger is an arbitrary boolean and the consequent is same-cycle;
these three are sugar that *produce* an antecedent boolean for the generalized form.
Top-level `(assert …)` (not inside a transaction, no trigger form) stays exactly as
today: module-global, every-cycle. No existing behavior changes.

### 2. A synthesizable-monitor output-mode for `(within …)` consequents

A bounded-eventually `(within S N)` consequent is **formal-only** as a pure SVA
property (`##[1:N]` — a delayed/sequence consequent verilator cannot simulate; see
`ISF-PROPERTY-IMPLICATION`). To keep `contract`'s *simulable* runtime checker, the
property carries an optional output-mode that lowers it to the same arm/age/fail
monitor `contract` uses today, generalized so the `arm` pulse comes from any of the
three triggers above (not only a positioned clause). This is the
"synthesizable-monitor-as-output-mode" `0008` deferred — decided here: **reuse and
generalize the existing `_contract_monitor_signals` machinery**; do not fork a second
monitor.

### Consequence: `contract` dissolves into the engine

`(contract NAME (eventually SIG (within N)))` ≡ a positioned (Inline) bounded-eventually
check lowered through the monitor output-mode. Once Inline + the monitor output-mode
exist, the `contract` clause is one (now-redundant) caller of the same engine and is
removed (its parse/validate/`_ir_temporal_contract` surface retargeted to the property
path, not the monitor machinery deleted). That removal is the last, deliberate,
golden-reviewed slice — tracked in `docs/tasks/ISF-TRIGGER-ANCHOR.md`.

## Consequences / staging

- Build order is dependency-driven (not the user's enumeration order): **Event**
  (smallest, formal-only warm-up of the trigger vocabulary) → **monitor output-mode**
  (makes bounded-eventually simulable) → **Inline** (positioned, via the monitor —
  achieves contract parity) → **Ref** (named handle) → **remove `(contract …)`**.
- Checkability split (`0008`) is preserved: a `(within …)` with no monitor output-mode
  stays formal-only under `` `ifdef FORMAL ``; with the monitor output-mode it is a
  real synthesizable checker simulable by verilator.
- No capability gap at any slice: `contract` keeps working until the engine fully
  subsumes it, then is removed in one slice.
