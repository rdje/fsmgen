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

  ;; a reusable procedure: add `in` into the actor's `total`
  (proc accumulate (params (in (width 8)))
    (update total (+ total in)))

  (transaction main
    (on start)
    (sample din as s)
    (call accumulate s)                ;; INLINE (shipped .2): expands to (update total (+ total s))
    (call accumulate s as a0)          ;; HANDSHAKE (.4): instance a0, start/done + arg ports
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

`(proc NAME (params PARAM-SPEC...) BODY...)` at actor level — the parameters are
wrapped in an explicit `(params ...)` sub-clause (shipped in `.2`; this refines the
bare-paramspec sketch from the original design, to disambiguate the params from the
body clauses). A `PARAM-SPEC` is:

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
  Commit: `76d7f01b`

- ID: `ISF-PROCEDURES.2`
  Status: `done`
  Goal: `Inline (proc) + (call NAME actuals) for value (in) parameters — the parse-time expansion.`
  Acceptance: `(proc NAME (params (P (width N))...) BODY...) parsed into $actor->{procs}; a parse-time pass in FSM::Adapter::ISF::Parser (_expand_procedure_calls, run after _build_actor's clause loop and before the finalizers) replaces each inline (call NAME actuals) with the proc body, substituting each in-param name with its actual (a signal OR a whole expression), recursing into when/switch/while/until/repeat bodies and into the substituted body. The emitted .fsm is byte-identical to writing the substituted clauses by hand (verified against a hand-written actor); procs/calls never reach the lowerer. Fails closed: unknown proc, arity mismatch, recursion (direct/transitive; no call stack), the handshake form (call ... as INST) (deferred .4), out-params (deferred .3), and malformed (proc ...) (no name / no (params ...) / empty body). --check-json + verilator/yosys PASS. 13b gains an example-rich procedures section (4 runnable examples); 13k row; ISF_SPEC registers t/1390. NOTE: the shipped definition syntax wraps the parameters in an explicit (params ...) sub-clause — (proc NAME (params PARAMSPEC...) BODY...) — refining the .1-design's bare-paramspec sketch, to disambiguate params from body clauses.`
  Verification: `prove -Iperl t/1390 (6 subtests) t/1250 t/1376 t/1305 t/1303 t/1304 t/1307 PASS; identical-.fsm + when/while-body + --check-json + --verify-hdl + all fail-closed verified; full ./bin/ci-regression isf --no-book PASS; perl -c; mdbook build; git diff --check`
  Commit: `e680f967`

- ID: `ISF-PROCEDURES.3`
  Status: `done`
  Goal: `Inline out-parameters — (out NAME (width N)) writes back into a caller-chosen signal.`
  Acceptance: `The .2 out-parameter deferral is lifted: an (out P (width N)) parameter substitutes its caller actual into the proc body like an in-parameter, but the actual must be a plain signal lvalue (an expression actual fails closed: "out-parameter ... requires a plain signal actual to write back into, not an expression"). The caller picks the write-back destination per call, so one proc can drive different signals. In- and out-params mix freely (positional). --check-json + verilator/yosys PASS. 13b gains an out-parameter example; 13k row updated; t/1390 replaces the out-param-deferral subtest with a positive out-param subtest + the expression-as-out-actual rejection.`
  Verification: `Spike: (proc compute (params (in (width 8)) (out r (width 8))) (update r (+ in 1))) + (call compute s r1)/(call compute (+ s 1) r2) -> (update r1 (+ s 1))/(update r2 (+ (+ s 1) 1)); expression-as-out-actual rejected; --check-json SUCCESS; --verify-hdl verilator_lint+yosys_synthesis PASS. prove -Iperl t/1390 (7 subtests) t/1376 t/1305 PASS; full ./bin/ci-regression isf --no-book PASS; perl -c; mdbook build; git diff --check`
  Commit: `e06ad8db`

- ID: `ISF-PROCEDURES.4`
  Status: `done`
  Goal: `Handshake call (call NAME actuals as INST) — synthesize the proc as a one-shot child transaction and drive it with the bound (do) handshake.`
  Acceptance: `(call NAME actuals as INST) lowers to a bound (do NAME (bind (input <in-param> <actual>)... (output <out-param> <actual>)...)) against a child transaction synthesized from the proc (params -> typed ports: in->input, out->output; body -> transaction body terminated by (complete NAME_done)). _expand_handshake_call builds the bound do + records the synthesis need; _expand_procedure_calls drains a worklist of synthesis targets (a synthesized body may reach further handshake calls); _synthesize_proc_transaction builds + parses the child transaction (and expands inline calls in its body, recursion-guarded). The as INST suffix is the discriminator (the proc body keeps its param NAMES as port names; no substitution). The call site asserts <NAME>_start, binds the in-args, reads the out-args on done, and blocks on <NAME>_done; --check-json + verilator/yosys PASS. Fails closed: missing instance name after as, and a proc/transaction name collision. KNOWN LIMITATION: the synthesized child is a reused sibling, so INST is currently a label (distinct instances per call is a future refinement). 13b gains a handshake section + an inline-vs-handshake comparison table + example; 13k row updated; t/1390 replaces the handshake-deferral assertion with a positive handshake subtest + two handshake fail-closed cases.`
  Verification: `Spike: (call inc_into s result as a0) synthesizes the inc_into child + bound do; main asserts inc_into_start, binds (in s)/(result> r), blocks on <inc_into_done; child runs r=in+1; --check-json SUCCESS; --verify-hdl verilator_lint+yosys_synthesis PASS; missing-INST + name-collision fail closed. prove -Iperl t/1390 (9 subtests) t/1376 t/1305 PASS; full ./bin/ci-regression isf --no-book PASS; perl -c; mdbook build; git diff --check`
  Commit: `ship commit (this slice)`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `.1` | `done` | Selection/design (this doc). |
| 2 | `.2` | `done` | Inline `(proc)` + `(call NAME actuals)` for in-params: a parse-time expansion pass in `FSM::Adapter::ISF::Parser` substitutes actuals into the proc body (identical `.fsm` to hand-written); fails closed on unknown/arity/recursion/handshake-deferred/out-param-deferred/malformed. `--check-json` + verilator/yosys PASS. `t/1390`. |
| 3 | `.3` | `done` | Inline **out-params** — `(out NAME (width N))` writes back into a caller-chosen signal (the out-actual must be a plain lvalue, not an expression). `--check-json` + verilator/yosys PASS. `t/1390`. |
| 4 | `.4` | `done` | **Handshake** `(call … as INST)` — synthesizes the proc as a one-shot child transaction (in→input ports, out→output ports) + a bound `(do)` call; reuses the child-activation substrate. **Both calling conventions now ship.** `--check-json` + verilator/yosys PASS. `t/1390`. |
| 5 | `.5` | `pending` | Dedicated example-dense docs chapter + matrix/spec sync. |

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
| `2026-06-01` | `.4` | Spike: `(call inc_into s result as a0)` synthesizes the `inc_into` child + bound `(do)`; main asserts `inc_into_start`, binds `(in s)`/`(result> r)`, blocks on `<inc_into_done`; child runs `r=in+1`; `--check-json` SUCCESS; `--verify-hdl` verilator_lint+yosys_synthesis PASS; missing-INST + name-collision fail closed. `prove -Iperl t/1390` (9 subtests) `t/1376 t/1305` PASS; full `./bin/ci-regression isf --no-book` PASS; `perl -c`; `mdbook build`; `git diff --check` | `PASS` |
| `2026-06-01` | `.3` | Spike: out-param `(out r (width 8))` writes into the caller signal (`(call compute s r1)` -> `(update r1 (+ s 1))`); expression-as-out-actual rejected; `--check-json` + verilator/yosys PASS. `prove -Iperl t/1390` (7 subtests) `t/1376 t/1305` PASS; full `./bin/ci-regression isf --no-book` PASS; `perl -c`; `mdbook build`; `git diff --check` | `PASS` |
| `2026-06-01` | `.2` | Spike: `(proc accumulate (params (in (width 8))) (update total (+ total in)))` + `(call accumulate s)`/`(call accumulate (+ s 1))` expands to identical `.fsm`; calls in when/while bodies lower; `--check-json` SUCCESS; `--verify-hdl` verilator_lint+yosys_synthesis PASS; unknown/arity/recursion/handshake/out-param/malformed fail closed. `prove -Iperl t/1390` (6 subtests) `t/1250 t/1376` (45) `t/1305 t/1303 t/1304 t/1307` PASS; full `./bin/ci-regression isf --no-book` PASS; `perl -c`; `mdbook build`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `ISF-PROCEDURES.1: select reusable procedures (inline + handshake calls)` | `76d7f01b` |
| `.2` | `ISF-PROCEDURES.2: inline (proc)/(call) reusable procedures (in-params)` | `e680f967` |
| `.3` | `ISF-PROCEDURES.3: inline out-parameters (write-back)` | `e06ad8db` |
| `.4` | `ISF-PROCEDURES.4: handshake (call ... as INST) via synthesized child transaction` | `ship commit (this slice)` |

## Changelog

- `2026-06-01`: Created as a language-richness theme #3 construct (per the user's
  direction to implement both calling conventions, pickable per call site). Designed
  `(proc NAME (params) body)` callable as `(call NAME actuals)` (inline substitution,
  default) or `(call NAME actuals as INST)` (port-binding handshake). Recorded the
  ISF/IAL1 layering rationale (desugars to existing primitives) and the
  inline-first slice plan.
- `2026-06-01`: `.2` shipped — inline `(proc)` + `(call NAME actuals)` for value (in)
  parameters. A `(proc NAME (params (P (width N))...) BODY...)` is parsed (new `proc`
  branch in `FSM::Adapter::ISF::Parser`'s `_build_actor`) into `$actor->{procs}`. A
  new parse-time pass `_expand_procedure_calls` (run right after the actor's clause
  loop and BEFORE the finalizers/validators) rewrites each inline `(call NAME
  actuals)` into the procedure body with each in-parameter name substituted by its
  actual — which may be a plain signal OR a whole expression (e.g. `(call accumulate
  (+ s 1))` → `(update total (+ total (+ s 1)))`). The expansion recurses into
  `when`/`switch`/`while`/`until`/`repeat` bodies and into the substituted body
  itself (so nested calls expand), with the proc name pushed on a recursion stack to
  reject direct/transitive recursion (no hardware call stack). Because expansion runs
  in the adapter, `proc`/`call` never reach the scheduler — the emitted `.fsm` is
  byte-identical to writing the substituted clauses by hand (asserted in `t/1390`
  against a hand-written actor). Fails closed with targeted diagnostics: unknown
  procedure, argument-count mismatch, recursion, the handshake form `(call ... as
  INST)` (deferred to `.4`), out-parameters (deferred to `.3`), and malformed
  `(proc ...)` (missing name / missing `(params ...)` / empty body). The empty
  `(params)` lisp-parse quirk (a trailing `undef`) is filtered. Verified `--check-json`
  SUCCEEDS and `--verify-hdl` passes (verilator_lint + yosys_synthesis). Book: `13b`
  gains an example-rich "Reusable Procedures" section (4 runnable examples: basic
  accumulate, expression actual, multi-param, call-in-loop); `13k` gains a procedures
  row; `docs/ISF_SPEC.md` registers `t/1390`. Shipped-syntax note: the parameters are
  wrapped in `(params ...)` (refines the `.1` bare-paramspec design) to disambiguate
  params from body clauses.
- `2026-06-01`: `.3` shipped — inline **out-parameters**. The `.2` out-parameter
  deferral is lifted: an `(out NAME (width N))` parameter substitutes its caller
  actual into the procedure body exactly like an in-parameter, except the actual must
  be a plain signal lvalue (an expression actual fails closed with "out-parameter ...
  requires a plain signal actual to write back into, not an expression"). The caller
  picks the write-back destination per call, so one procedure can drive different
  signals (`(call compute s r1)` → `(update r1 (+ s 1))`, `(call compute (+ s 1) r2)`
  → `(update r2 (+ (+ s 1) 1))`). In- and out-parameters mix freely and substitute
  positionally. `--check-json` SUCCEEDS and `--verify-hdl` passes (verilator_lint +
  yosys_synthesis). Book: `13b` gains an out-parameter example; the `13k` row is
  updated to describe both parameter directions. `t/1390` replaces the
  out-param-deferral subtest with a positive out-parameter subtest plus the
  expression-as-out-actual rejection.
- `2026-06-01`: `.4` shipped — the **handshake call** `(call NAME actuals... as INST)`,
  completing both calling conventions. Instead of inlining, the handshake form
  synthesizes the procedure as a one-shot child transaction (parameters become typed
  ports — in→input, out→output — and the body becomes the transaction body, terminated
  by `(complete NAME_done)`) and drives it at the call site with a bound
  `(do NAME (bind (input <in-param> <actual>)... (output <out-param> <actual>)...))`.
  `_expand_handshake_call` (`FSM::Adapter::ISF::Parser`) builds the bound `(do)` and
  records the synthesis need; `_expand_procedure_calls` drains a worklist of synthesis
  targets (a synthesized body may itself reach further handshake calls);
  `_synthesize_proc_transaction` builds and parses the child transaction (expanding
  inline calls in its body, recursion-guarded) and appends it to the actor. The proc
  body keeps its parameter NAMES (they are the port names — no substitution in the
  handshake form). Verified end-to-end: `(call inc_into s result as a0)` asserts
  `inc_into_start`, binds `(in s)` and reads `(result> r)` on done, blocks on
  `<inc_into_done`, and the synthesized child runs `r = in + 1`; `--check-json`
  SUCCEEDS and `--verify-hdl` passes (verilator_lint + yosys_synthesis). Fails closed:
  a handshake `(call ... as)` missing its instance name, and a handshake procedure
  whose name collides with an existing transaction. KNOWN LIMITATION: the synthesized
  child is a reused sibling, so `INST` is currently a label (giving each handshake call
  a distinct instance is a future refinement). Book: `13b` gains a handshake-call
  section with an inline-vs-handshake comparison table and a runnable example; the
  `13k` row describes both conventions. `t/1390` replaces the handshake-deferral
  assertion with a positive handshake subtest and two handshake fail-closed cases (9
  subtests). **The user's direction — implement both calling conventions, pickable
  cleanly at the call site — is now fully delivered: one `(proc)` definition, called
  inline with `(call NAME actuals)` or via the handshake with `(call NAME actuals as
  INST)`.**
