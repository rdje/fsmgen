# ISF-PROCEDURES: Reusable Procedures With Inline *or* Handshake Calls

## Metadata

- Tree ID: `ISF-PROCEDURES`
- Status: `active`
- Roadmap lane: `R14` (ISF — high-level language richness)
- Created: `2026-06-01`
- Last updated: `2026-06-01`
- Owner: repo-local workflow

## Goal

Give ISF a first-class **reusable procedure** — a named, parameterized block of
clauses — that the author can call **two ways, picked cleanly at the call site**:

1. **Inline substitution** (default): the procedure body is macro-expanded at the
   call site with actuals substituted into its expressions/signals; proc-local
   signals are uniquified per call. Zero runtime cost, no start/done handshake — the
   emitted `.fsm` is identical to writing the clauses out by hand.
2. **Port-binding handshake**: the procedure is synthesized as a one-shot block
   instance with start/done plus argument ports, and called with the existing
   `(do)`-style handshake (drive arg wires → pulse start → wait done → read result).

This is the "callable block of code with its own actual arguments" of a high-level
language, realized at both the lightweight (inline) and heavyweight (instantiated)
ends, per the user's direction (2026-06-01: "implement both … user shall be able to
choose or pick between them cleanly"). It is an **ISF (IAL1)** construct: the inline
form desugars to existing scheduling primitives and the handshake form reuses the
existing child-activation machinery — neither raises the abstraction level (see the
`isf-abstraction-layering` memory; the genuinely-higher *instantiated-service /
topology* model is ATL).

Reads like:

```lisp
(actor acc_demo
  (interface (input start) (input din (width 8)) (output done) (output total (width 8)))

  ;; a reusable procedure: add `in` into `acc`
  (proc accumulate (in (width 8)) (out acc (width 8))
    (update acc (+ acc in)))

  (transaction main
    (on start)
    (sample din as s)
    (call accumulate s total)          ;; INLINE: expands to (update total (+ total s))
    (call accumulate s total as a0)    ;; HANDSHAKE: instance a0, start/done + arg ports
    (complete done)))
```

## Ground truth (investigated `2026-06-01`)

- ISF already has the **heavyweight, instantiated** form of a function-with-args: a
  `(transaction name ...)` called via `(do name (params ...) (bind (input a x)
  (output r y)))` — a real `.fsm` instance, compile-time `(params)` (generics) and
  runtime in/out `(bind)` (arguments/return). What is missing is (a) the
  **lightweight inline** form (no instance, pure expansion) and (b) a single
  definition the author can call **either** way.
- `%SUPPORTED_TRANSACTION_CLAUSES` (`FSM/Scheduler/ISF/LoweringIR.pm`) has no `proc`
  or `call` keyword. There is no actor-level `(proc ...)` definition form in the
  parser/adapter (`FSM::Adapter::ISF`).
- The activation machinery (`_ir_do`, `_register_generated_activation_instance`,
  `_wire_external_activations`, `_spawn_ref_from_clause`, `(bind ...)` handling) is
  the reusable substrate for the handshake call; `(spawn child as inst)` is the
  precedent for the `as inst` instance-naming discriminator.

## Design

### Definition

`(proc NAME (PARAM-SPEC...) BODY...)` at actor level. A `PARAM-SPEC` is:

- `(NAME (width N))` — an **in** (value) parameter (default direction).
- `(out NAME (width N))` — an **out** parameter (an lvalue the call writes back).
- (optionally later) `(inout NAME (width N))`.

The `BODY` is a clause list using the same vocabulary a transaction body allows,
referencing the params by name plus proc-local signals.

### Call + convention pick (the clean choice)

- `(call NAME ACTUAL...)` → **inline** (default). One actual per param, positional.
- `(call NAME ACTUAL... as INST)` → **handshake**, instance `INST`. The `as INST`
  marker is the single, clean discriminator (mirrors `(spawn … as …)`).

### Inline lowering (the genuinely new part)

A pre-scheduling **expansion pass** (in the adapter or an early lowering step):
- Resolve `(call NAME a b)` to its `(proc NAME …)` definition; arity/width-check the
  actuals.
- Substitute each **in** param name → the actual expression; each **out** param name
  → the actual lvalue (signal).
- Uniquify proc-local signal names per call site (`<proc>__<callsite>__<sig>`), so two
  calls don't collide.
- Splice the substituted body clauses into the caller's clause list in place of the
  `(call ...)`. The scheduler then lowers them as ordinary clauses — no new scheduler
  concept, identical `.fsm`.
- Fail closed on: unknown proc, arity mismatch, width mismatch, an **in** actual used
  as an **out**, and **recursion** (a proc whose expansion reaches itself — no
  hardware call stack).

### Handshake lowering (reuse existing machinery)

- Synthesize the proc body as a one-shot block with a start-gated entry, a done
  terminal, and one port per param (in → input port, out → output port).
- Emit a `(do)`-style activation at the call site bound to the instance `INST`:
  drive the in-arg ports, pulse `<INST>_start`, block on `<INST>_done`, read the
  out-arg ports — reusing `_ir_do` / the spawn-ref / `(bind ...)` substrate.
- The synthesized block is instantiated and wired in the (generated) composition top,
  exactly like a generated child.

### Boundaries / fail-closed

- Recursion (direct or mutual) — rejected (no call stack in hardware).
- Dynamic/data-dependent procedure selection ("call whatever this signal names") —
  not supported; the callee is statically resolved.
- A `proc` is not a transaction entry point (no `(on ...)`); it is only reachable via
  `(call ...)`.

## Slice plan

- `.1` select (this doc) — design both conventions + the `as INST` pick; ground truth.
- `.2` **inline** `(proc)` + `(call NAME actuals)` for **in** (value) params — the
  pre-scheduling expansion pass + arity/width/recursion fail-closed; golden `.fsm`
  (identical to hand-written) + HDL.
- `.3` inline **out** params (write-back lvalue substitution).
- `.4` **handshake** `(call NAME actuals as INST)` — synthesize the one-shot block +
  `(do)`-style activation; reuse the child-activation substrate; golden `.fsm` + HDL.
- `.5` **thorough, example-rich mdBook documentation** — a dedicated high-level-language
  constructs chapter (or a substantial `13d`/`13b` section) that explains procedures,
  both calling conventions, parameter directions, the inline-vs-handshake trade-off,
  and the fail-closed boundaries, with **many runnable examples** progressing from
  trivial to realistic (per the user's standing directive, 2026-06-01: "extremely
  well and thoroughly documented in the mdBook with lot of examples"). Plus
  feature-matrix/doc-truth + ISF_SPEC index sync.

> **Documentation is a first-class deliverable for every slice, not just `.5`.** Each
> implementation leaf (`.2`–`.4`) ships its own runnable mdBook example(s) the same
> slice it lands (per the per-slice mdBook-sync doctrine); `.5` consolidates them into
> a coherent, example-dense chapter. Examples must lower cleanly (audited by `t/1376`).

## Non-Goals

- Recursion / a call stack.
- First-class procedure values / function pointers / dynamic dispatch.
- Cross-domain handshake calls in this tree (orthogonal; the cross-domain `(do)`
  machinery already exists and can be layered later).
- Higher-layer instantiated *services* / topology — that is ATL, not this tree.

## Acceptance Criteria

- A `(proc ...)` defines a reusable parameterized block; `(call NAME actuals)` inlines
  it (identical `.fsm` to hand-written clauses) and `(call NAME actuals as INST)`
  calls it through a start/done + arg-port handshake; both lower with golden `.fsm` +
  HDL evidence; arity/width/recursion/misuse fail closed with targeted diagnostics;
  the mdBook documents both conventions **thoroughly, with many runnable examples**
  (trivial → realistic), and every example lowers cleanly (`t/1376`); feature-matrix/
  doc-truth/ISF_SPEC audits pass. Each leaf committed via `COMMIT.md`, and each leaf
  ships its own runnable mdBook example(s) the same slice it lands.

## Task Tree

- ID: `ISF-PROCEDURES`
  Status: `active`
  Goal: `Reusable (proc) callable inline (substitution) or via a port-binding handshake, picked at the call site.`
  Children: `.1` (select), `.2` (inline in-params), `.3` (inline out-params), `.4` (handshake call), `.5` (docs)

- ID: `ISF-PROCEDURES.1`
  Status: `done`
  Goal: `Select; design both calling conventions + the `as INST` pick; ground truth.`
  Acceptance: `Task tree committed before any code change.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ship commit (this slice)`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `.1` | `done` | Selection/design (this doc). |
| 2 | `.2` | `pending` | Inline `(proc)` + `(call NAME actuals)` for in-params — the genuinely new pre-scheduling expansion, lowest risk (desugars to existing clauses). |
| 3 | `.3`–`.5` | `pending` | Inline out-params; handshake `(call … as INST)`; docs/examples. |

## Decisions

- `2026-06-01` (user direction): implement BOTH calling conventions — inline
  substitution AND port-binding handshake — with a clean per-call-site pick. Encoded
  as one `(proc)` definition + `(call …)` where a trailing `as INST` selects the
  handshake form (mirrors `(spawn … as …)`); absent it, the call inlines.
- `2026-06-01` (layering): this is an ISF (IAL1) construct — the inline form desugars
  to existing scheduling primitives, the handshake form reuses the existing
  child-activation substrate. Neither raises the abstraction level (per
  `isf-abstraction-layering`). Build inline first (`.2`) because it is the new part
  and lowers by pure expansion (the scheduler never sees a new concept).

## Open Questions

- `.2`: where the expansion pass lives — in `FSM::Adapter::ISF` (parser-adjacent,
  before the actor hash reaches the lowerer) vs. an early `LoweringIR` pass. Adapter
  is cleaner (keeps `proc`/`call` out of the scheduler entirely). Resolve in `.2`.
- `.4`: whether a synthesized handshake proc reuses the generated-child instance
  machinery verbatim or needs a dedicated naming/registration path.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-01` | `.1` | `mdbook build docs/book`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `ISF-PROCEDURES.1: select reusable procedures (inline + handshake calls)` | `ship commit (this slice)` |

## Changelog

- `2026-06-01`: Created as a language-richness theme #3 construct (per the user's
  direction to implement both calling conventions, pickable per call site). Designed
  `(proc NAME (params) body)` callable as `(call NAME actuals)` (inline substitution,
  default) or `(call NAME actuals as INST)` (port-binding handshake). Recorded the
  ISF/IAL1 layering rationale (desugars to existing primitives) and the
  inline-first slice plan.
