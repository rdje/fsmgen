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
