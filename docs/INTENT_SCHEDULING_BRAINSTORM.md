# Intent Scheduling Brainstorm

This file is the git-tracked living log for FSMGen brainstorming about a
higher-than-cycle-authored intent layer.

Purpose:

- preserve Q/A exchanges precisely and literally so the original design spark
  is not lost,
- distinguish this lane from C-to-HDL and from exact protocol-PDF extraction,
- explore how FSMGen could infer and schedule cycles while still lowering to
  explicit `.fsm`, SystemVerilog, or VHDL,
- and keep open questions, including the eventual 3-letter source extension,
  in one place for future discussion.

Working name:

- `Intent Scheduling`

Core thesis:

- `.fsm` is already an abstraction above SystemVerilog and VHDL, but today
  `?fsm` authoring is still explicitly cycle-aware because state DTs encode the
  schedule directly.
- A future layer may let authors describe transactions, rules, handshakes,
  phases, resources, and constraints without choosing every state/cycle
  manually.
- The compiler would then lower that intent into an explicit schedule and
  explicit `.fsm`/SV/VHDL.
- Cycles would not disappear from the final semantics. They would become an
  inferred, scheduled, and reviewable compiler result.

## Design Note: 2026-05-18 Actor Network Orchestration

The actor-network direction is fruitful and is now tracked as active ISF
clarification work. The useful abstraction is a static hierarchy or graph of
explicit actors where one or more actors orchestrate the larger system by
triggering peer or sub-actors, synchronizing on named one-cycle event pulses,
and moving data through scheduler-visible bindings.

The refined mental model is Actor Transfer Level (`ATL`). RTL describes how
data moves between flops/registers; ATL describes how data, information, and
activation move between actors. The transfer endpoints are actors instead of
flops. The whole network is itself a top-level actor whose structure/content
is the actor network. Transactions and rules in that top-level actor can
trigger actors or specific transactions inside the network, and data movement
must cover actor-to-actor links, concurrent groups of actors, and movement
between top-level pins and actors inside the network.

This direction should stay intent-expressive while also offering a verbose
variant for maximum readability. Compact forms can serve experienced authors,
but the public contract must also expose a spelling that makes the
orchestration, data movement, and scheduling evidence easy to review.

This remains IAL1 while it is authored as explicit `.isf`: actors, events,
bindings, resources, and timing constraints are still present in source form,
and FSMGen owns scheduling/lowering into explicit `.fsm`. It becomes an IAL2
candidate only if the source model moves above explicit actor/network syntax,
for example by asking FSMGen to infer the actor network from protocol or
platform intent.

The first design task is clarification, not implementation. The source shape
needs to decide how to spell the top-level actor-as-network model: nested
actor declarations, a `(network ...)` body inside an actor, top-level peer
actors plus explicit topology, reusable library actors, or a smaller
first-slice construct. The event model also needs a crisp contract: whether
orchestrator signals are transaction starts, actor-level starts, named
one-cycle event outputs, event payloads, or some combination. The data
movement model must likewise be explicit enough for concurrent group
scheduling, schedule reports, top-level pin wiring, and generated-top wiring
to remain reviewable.

Tracked task tree:
[docs/tasks/ISF-ACTOR-NETWORK-ORCHESTRATION.md](docs/tasks/ISF-ACTOR-NETWORK-ORCHESTRATION.md).

Concrete ATL v0 proposal:
[docs/ISF_ATL_DESIGN_PROPOSAL.md](ISF_ATL_DESIGN_PROPOSAL.md).

The current proposal keeps `(actor top_name ...)` as the source root. The
container spelling is intentionally open: ATL clauses may be scoped inside a
`(network ...)` clause, or they may appear directly as flat top-level actor
clauses if that proves cleaner. The proposed endpoint vocabulary is
`pins.name`, `actor.port`, `actor.transaction`, `actor.event`, and
`group.name`. The verbose syntax is the normative target; compact syntax is a
semantics-preserving alias only after it maps to the same ATL IR and
diagnostics. The proposal now removes top-level `connect` from the preferred
ATL v0 movement model. Movement should be expressed through existing drive
definitions and drive calls where possible, not through a new
`(drive source sink)` action. The selected ATL v0 movement path widens the
shipped drive-body pair `(sink source)` so `sink` and `source` may name actor
endpoints and top-level pins. Source actors, top-level pins, or actor outputs
can provide information to sink actors at selected points in time, much like
mux inputs can feed one flop in different cycles. FSMGen must infer the
selected route, mux/enable, handoff storage, and generated connectivity from
the drive body pair, drive-call timing point, triggers, sink-valid conditions,
disjoint timing, and generated evidence, or reject the case. The scheduler,
not a new user-surface movement keyword, discriminates which side is an actor
endpoint, top-level pin, or local value. This keeps ISF uniform and low
friction: ATL adds actor-network endpoint resolution to an existing movement
surface instead of asking users or downstream emitters to learn another one.
The scheduler also owns the dynamic runtime routing control. Authors describe
movement intent; FSMGen derives the route selects, mux inputs, enables,
handoffs, and generated connectivity needed to move information between
actors without hand-authored route clauses.

## Design Note: 2026-05-13 Rule Trigger Fan-In

ISF rule-trigger lowering now preserves rule-source provenance before driving
the target transaction start signal. The earlier direct-start shape was:

```lisp
(-rule_a
  (<guard_a
    (<1 (work_start 1))
  )
)

(-rule_b
  (<guard_b
    (<1 (work_start 1))
  )
)
```

That worked for activation because the downstream `.fsm` backend consolidated
same-LHS enables, making the generated HDL OR-equivalent. The limitation was
observability: if both rules triggered `work` in the same cycle, the scheduled
artifact exposed one `work_start` pulse and not distinct trigger-source pulses
for `rule_a` and `rule_b`.

The shipped scheduler now implements the more general proposal. Each
rule/transaction pair produces a distinct one-bit trigger source, and the
target transaction start is driven by a generated combinational OR fan-in:

```lisp
(-rule_a
  (<guard_a
    (<1 (rule_a_work 1))
  )
)

(-rule_b
  (<guard_b
    (<1 (rule_b_work 1))
  )
)

(-work_trigger_fanin
  (= (work_start (| rule_a_work rule_b_work)))
)
```

The implemented behavior preserves the existing one-cycle delayed pulse
semantics for each rule trigger and adds no extra latency on the fan-in. The
benefit is provenance: schedule reports, debug traces, assertions, future
arbitration, and priority/conflict policy can inspect which rule sources fired
before they are ORed into the transaction start.

## Verbatim Exchange: 2026-05-13 Rule Trigger Fan-In

### User

````text
More discussion: rules are lowered as non-DTs with guard and they can trigger transactions. Now, let's say N rules trigger the same transaction at different point in time. Does the scheduler OR those triggers together to drive the transaction's start input ?

This shall be considered, because such case will be very, very common.
````

### Assistant

````text
Yes, it must be considered. I checked the current implementation.

Current state:

- The ISF scheduler does not explicitly synthesize an OR aggregator for rule triggers.
- It emits one rule DT per rule, each assigning the same transaction start signal:

```lisp
(-ra
  (<a
    (<1 (work_start 1))
  )
)

(-rb
  (<b
    (<1 (work_start 1))
  )
)
```

- The downstream `.fsm -> .sv` backend then consolidates same-LHS enables and ORs them:

```systemverilog
assign work_start_1_en = ra_work_start_1_en | rb_work_start_1_en;
```

So the generated SV does OR them today, but that behavior is currently an implicit backend consequence, not an explicit ISF scheduler contract.

My take: for ISF, this should become an explicit documented semantic guarantee:

> Multiple `(trigger transaction)` actions targeting the same transaction are OR-equivalent request sources for that transaction's `transaction_start` pulse.

That guarantee can be implemented either by continuing to rely on fsmgen's LHS-level enable consolidation, or by making the ISF scheduler emit a clearer canonical aggregator. For public-interface stability and readable scheduled `.fsm`, I think the better long-term shape is explicit aggregation in the ISF lowering contract, because multi-rule trigger fan-in will be common and users should not have to infer it from backend mux synthesis.
````

### User

````text
Wait, I thought each rule that triggers a transaction foo has its own trigger signal, but no, the trigger construct in the rules directly pulse the start input of the transaction.

To me it shall not be that we way. Each rule R shall output a distinct trigger signal per trigered transactions. Triggered Tk transaction shall be associated with output <Rj>_<Tk> from the rule Rj. All those trigger(j, k), aka <Rj>_<Tk> shall be Ored for a given k, that is for transaction Tk, and this 1b output of the logical-or shall then drive the start input of transaction Tk.
````

### Assistant

````text
Yes. I agree with that architecture.

The current lowering collapses two concepts that should be separate:

1. Rule-local trigger source: "rule `Rj` requests transaction `Tk`"
2. Transaction start input: "transaction `Tk` sees at least one active request"

Those should not be the same signal.

The better lowering contract is:

```lisp
(rule r0 a
  (trigger work))

(rule r1 b
  (trigger work))
```

lowers conceptually to:

```lisp
(-r0
  (<a
    (<1 (r0_work 1))
  )
)

(-r1
  (<b
    (<1 (r1_work 1))
  )
)

(-work_trigger_fanin
  (= (work_start (| r0_work r1_work)))
)
```

Key points:

- Each `(trigger Tk)` inside rule `Rj` produces a distinct 1-bit rule trigger source, e.g. `Rj_Tk`.
- The rule trigger source should keep the current `<1` pulse semantics.
- The transaction start input should be driven by a generated combinational OR fan-in.
- The OR fan-in must not add another cycle of latency.
- Rules should no longer directly assign `Tk_start`.

This gives clearer generated `.fsm`, preserves provenance, makes schedule reports/debugging better, and avoids relying on backend same-LHS enable consolidation as an implicit semantic contract.
````

### User

````text
ok, my proposal is one way of doing things. but we can also stick to what is implemented today, since it also work, but we can't check multiple trigger in the same cycle to the same transaction.
````

### Assistant

````text
Correct. The current implementation is functionally enough to start the transaction because backend enable consolidation ORs the same `Tk_start` writers.

But it loses observability/provenance:

- You can know `Tk_start` was requested.
- You cannot directly know which rule(s) requested it in that same cycle.
- If `r0` and `r1` both trigger `Tk` together, the final effect is just one `Tk_start` pulse.
- That is fine for transaction activation, but weak for debug, scheduling reports, priority handling, arbitration, assertions, and future conflict policy.

So I'd frame it this way:

Current contract candidate:

```text
(trigger Tk) directly contributes to Tk_start.
Multiple contributors are OR-equivalent.
Per-rule trigger identity is not preserved after lowering.
```

Your proposed contract:

```text
(trigger Tk) creates Rj_Tk.
Tk_start is OR(R0_Tk, R1_Tk, ...).
Per-rule trigger identity is preserved before fan-in.
```

I prefer your proposed shape for ISF long-term because it makes the scheduler's intent explicit and inspectable. But if we want the smaller stabilization step, we can first document the current behavior as "OR-equivalent but not provenance-preserving," then later upgrade to explicit `Rj_Tk` fan-in without changing the functional meaning.
````

### User

````text
I'm ok with your plan, provided my proposed and more general solution is explicitly part of the backlog so that we do not forget.

This exchange shall also be logged in the live docs and clearly captured in the book, until my proposal is fully implemented.
````

## Verbatim Exchange: 2026-04-18

### User

````text
An interlude for brainstorming.

.fsm file format is a layer of abstraction atop Systemverilog and VHDL.

But it is still cycle accurate, I mean clock-cycle is still an important concept in its semantic.


I am not sure if there is a way move a way from cycle accurate mindset, but still lower to FSM format or SV or VHDL, without the intrinsic need to capture this cycle-by-cycle behavior.

Some tried from C to HDL or other very high level language. For me, C or similar languages are way too high level, and were not   created for HDL capture.

Do you see any way to abstract or improve .fsm higher and move away from cycle accuracy ?

Just brainstorming.
````

### Assistant

````text
Yes, I think there is a path, but I would phrase it carefully:

We probably cannot remove cycle semantics from the final meaning, because SV/VHDL hardware must eventually answer: “what changes on this clock edge?” But we can move cycle choice out of the author’s face and make cycles a lowering/scheduling result rather than the primary authoring unit.

The sweet spot may be: not C-to-HDL, but intent-to-FSM/RTL.

C is too sequential, memory-model-heavy, and software-shaped. A better abstraction above `.fsm` would still be hardware-native: actors, handshakes, transactions, guards, phases, latency bounds, resources, and invariants.

A few promising layers:

1. Transaction-Level `.fsm`
   Instead of writing every state and transition, the user writes something like:

   ```lisp
   (transaction read_burst
     (accept cmd_valid cmd_ready)
     (drive address_phase
       HADDR = cmd_addr
       HTRANS = NONSEQ
       HWRITE = 0)
     (repeat beats
       (await HREADY)
       (capture HRDATA -> data_fifo))
     (complete done))
   ```

   The compiler lowers that into explicit `.fsm` states, waits, counters, enables, and outputs.

2. Handshake/Channel Semantics
   Users think in terms of `valid/ready`, request/response, streams, and FIFOs:

   ```lisp
   (when input.fire
     (send output transformed_data))
   ```

   The tool decides whether that is one state, multiple states, skid-buffered, pipelined, etc. The generated `.fsm` is still cycle-accurate, but the source is more protocol-intent accurate.

3. Guarded Rule Semantics
   This is hardware-friendly. The user writes atomic rules:

   ```lisp
   (rule accept_cmd
     (when cmd_valid && cmd_ready)
     (set active_cmd cmd)
     (start burst_engine))
   ```

   The compiler checks conflicts, priorities, mutual exclusion, and emits explicit FSM/DT logic. This feels higher-level than cycle-by-cycle FSM authoring, but still maps naturally to hardware.

4. Latency-Insensitive Blocks
   The source says “this operation happens eventually when inputs are available,” with optional latency constraints:

   ```lisp
   (stage crc_update
     input  byte_stream
     output crc_stream
     latency <= 3)
   ```

   FSMGen could generate the control FSM, ready/valid plumbing, and maybe pipeline registers.

5. Temporal Contracts Plus Synthesis
   Instead of saying exactly how, the user states properties:

   ```lisp
   (contract
     (always request -> eventually[1..8] grant)
     (never grant_without_request)
     (onehot state_group))
   ```

   Then the tool either generates a controller satisfying those constraints or uses them as assertions around generated FSMs.

My instinct: keep `.fsm` as the explicit, cycle-aware middle layer, but introduce a higher “intent layer” above it.

Something like:

```text
.intent / .protofsm / ?actor / ?transaction
        lowers to
.fsm explicit states/DTs
        lowers to
SystemVerilog / VHDL
```

That would preserve debuggability. The user can inspect the lowered `.fsm` when needed, just like one inspects generated SV today.

The key design rule would be:

> The higher layer may hide cycle counting, but it must produce an explicit schedule/report showing what cycle behavior was chosen.

So the abstraction is not “cycles do not exist.” It is “cycles are inferred, scheduled, and made reviewable.”

That feels much more aligned with FSMGen than C-to-HDL. It stays hardware-native, keeps intent explicit, and still gives deterministic RTL.
````

### User Follow-Up

````text
Please precisely literally log the Q/A exchange we've just had in a git-tracked file so that we can expand later and discuss and fine tune.

I like your various idea of inferring cycles, and scheduling cycles, that's infact what I was thinking without being able to formalize it fully. For example, right now, FSM capture using ?fsm are explicitly aware of cycles with state DTs. I want to be able to move away from that cycle thinking.

The document you'll be creating to capture our current and future exchange of that abstraction, shall git-tracked and updated following each of our future discussion, brainstorming about this really interesting topic.

We'll need to find a 3-letter extension too ! :-)
````

## Initial Design Axes

These are not decisions yet. They are handles for future discussion.

- Authoring level:
  transaction, rule, actor, channel, phase, contract, or some combination.
- Lowering target:
  explicit `.fsm` first, then SV/VHDL from the existing backend path.
- Scheduling output:
  every inferred state, wait, counter, pipeline stage, latency, and handshake
  decision should be visible in a generated schedule report.
- User control:
  default schedule inferred by convention, with explicit constraints available
  when the user needs to force latency, ordering, resource sharing, or
  throughput.
- Debuggability:
  generated `.fsm` should remain inspectable and should carry provenance back
  to the higher-level intent construct.
- Honesty:
  if timing cannot be inferred safely, the compiler must fail with an
  actionable ambiguity report rather than choosing a hidden schedule.

## Open 3-Letter Extension Question

No extension is chosen yet.

Candidate directions to discuss later:

- `.ist`: intent scheduling text
- `.isf`: intent-scheduled FSM
- `.hif`: hardware intent format
- `.xfs`: executable FSM spec
- `.txf`: transaction-to-FSM
- `.act`: actor/control transaction

Working rule for choosing the extension:

- it should be short,
- it should not sound like C/SystemC or a software language,
- it should imply hardware intent and scheduling,
- and it should leave `.fsm` as the explicit cycle-aware middle layer rather
  than replacing it.

## Future Updates

Append future exchanges under dated sections.

When the discussion moves from brainstorming into implementation planning, add:

- a glossary,
- one or more concrete source examples,
- the lowered `.fsm` shape,
- the generated schedule report shape,
- ambiguity/failure examples,
- and a support-accounting plan for when the first slice becomes real.

## Verbatim Exchange: 2026-04-18 SPECFORGE Target Shape

### User

````text
SPECFORGE's goal right is to goes from PDF to IntentIR to .fsm, so why not replace .fsm by this now format (lisp-ish) then from the new format to .fsm and from .fsm down to .sv or .svh.
````

### Assistant

````text
Yes. I think that is actually a very strong architecture.

I would not say “replace `.fsm`” completely, though. I would say:

```text
PDF/spec
  -> SPECFORGE IntentIR
  -> new higher-level hardware-intent format
  -> explicit cycle-scheduled .fsm
  -> SystemVerilog / VHDL
```

The key is that `.fsm` should remain the cycle-accurate lowered middle layer, not necessarily the first authoring target for every workflow.

So SPECFORGE would not need to jump directly from prose/spec IntentIR into explicit states and cycle-by-cycle DTs. It could instead emit the new Lisp-ish “intent scheduling” format, where things are still hardware-native but not manually cycle-scheduled yet.

Something like:

```lisp
(?actor:ahb_requester
  (transaction read_burst
    (accept cmd_valid cmd_ready)
    (request bus)
    (drive address_phase
      HADDR = cmd_addr
      HWRITE = 0
      HTRANS = NONSEQ)
    (repeat beats
      (await HREADY)
      (capture HRDATA -> read_data))
    (complete done))
)
```

Then FSMGen’s new scheduler lowers that to explicit `.fsm`:

```text
idle
decode
request
transfer_nseq
transfer_seq
complete
```

with the generated schedule report explaining exactly what cycles/states were inferred.

Why keep `.fsm` in the chain?

Because `.fsm` is already the precise, debuggable, cycle-accurate contract. It is the point where we can say: “Here is exactly what hardware will do every clock.” That makes it a great intermediate representation and escape hatch. Users can inspect it, patch it, test it, and compare it to generated SV/VHDL.

So the new format should probably become the preferred high-level authoring / SPECFORGE target, while `.fsm` remains the explicit scheduled IR.

That gives us three clean abstraction levels:

```text
SPECFORGE IntentIR
  Meaning recovered from spec/prose/PDF.
  May contain ambiguity, confidence, source citations, actors, transactions.

Intent Scheduling Format
  Hardware-native, Lisp-ish, not manually cycle-by-cycle.
  Describes actors, handshakes, rules, transactions, latency constraints.

.fsm
  Explicit cycle-accurate scheduled form.
  States, DTs, assignments, transitions, enables.

SV/VHDL
  Concrete HDL backend output.
```

This also avoids asking SPECFORGE to know too much too early. SPECFORGE can say “this transaction waits for HREADY and then captures HRDATA” without deciding the exact state layout. FSMGen then owns scheduling, cycle inference, conflict analysis, and lowering.

My take: this is probably the right long-term split. SPECFORGE should target the new hardware-intent format when the source spec is behavioral/transactional, and target `.fsm` directly only when the cycle schedule is already explicit or intentionally hand-authored.
````

### Captured Direction

- Do not replace `.fsm` as the explicit scheduled/cycle-accurate middle layer.
- Do introduce a higher Lisp-ish hardware-intent format as a preferred target
  for SPECFORGE when SPECFORGE recovers behavioral/transactional intent from
  PDF/spec prose.
- Keep the split:
  - `PDF/spec -> SPECFORGE IntentIR`
  - `SPECFORGE IntentIR -> Intent Scheduling Format`
  - `Intent Scheduling Format -> explicit scheduled .fsm`
  - `.fsm -> SV/VHDL`
- Let SPECFORGE preserve source evidence, ambiguity, confidence, citations,
  actors, and transactions.
- Let FSMGen own scheduling, cycle inference, conflict analysis, lowering to
  `.fsm`, schedule reports, and backend emission.
- Allow SPECFORGE to target `.fsm` directly only when a cycle schedule is
  already explicit or intentionally hand-authored.
