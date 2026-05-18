# ISF Actor Transfer Level Design Proposal

Status: active ATL v0 public contract, partially implemented.

Task-tree owner:
[docs/tasks/ISF-ACTOR-NETWORK-ORCHESTRATION.md](tasks/ISF-ACTOR-NETWORK-ORCHESTRATION.md).

## Purpose

Actor Transfer Level (`ATL`) is the proposed ISF actor-network layer. The
mental model is deliberately close to RTL, but the transfer endpoints are
actors instead of flops/registers.

- RTL describes how values move between registers and logic.
- ATL describes how data, information, and activation move between actors.
- ATL movement uses the existing drive-body assignment-pair shape widened to
  actor endpoints, not a new permanent actor-to-actor wire construct. Like RTL
  mux inputs feeding one flop at different cycles, multiple source actors may
  feed one sink actor only when the scheduler can prove the selected source
  and cycle.
- FSMGen still owns scheduling and lowers the result to explicit scheduled
  `.fsm`.
- The generated schedule remains reviewable; ATL does not hide cycles.

This remains `IAL1` while authors write explicit `.isf` actor/network syntax.
It becomes an `IAL2` candidate only if a later source asks FSMGen to infer the
actor graph from higher-level protocol or platform intent.

## Source Shape

The proposed root stays the existing ISF actor root:

```lisp
(actor top_name
  actor_clause...
  atl_declaration...)
```

The top-level actor is the network boundary. Its `interface` declares the
top-level pins. Its `transaction` and `rule` clauses can orchestrate the actor
network. Static actor declarations are direct actor clauses. Data/information
movement should reuse existing drive bodies and drive calls by allowing drive
body assignment pairs to reference actor endpoints and top-level pins.

### Actor-Body ATL Clauses

```lisp
(actor top_name
  actor_clause...
  (instance instance_name of actor_type)
  (group group_name group_clause...))
```

ATL clauses are direct clauses of the top-level actor. There is no
`(network ...)` wrapper. The actor body itself is the network. This is the
selected source shape because it:

- matches the user's mental model most directly: the actor content is the
  actor network;
- removes one nesting level;
- makes top-level actor transactions/rules and actor-network clauses feel like
  one unified ATL surface;
- avoids a second lexical section that could be mistaken for a semantic root.

The first metadata-only implementation slice accepts this direct
`(instance ...)` form for one static actor instance and lowers it to
`actor_network` report metadata. `(network ...)`, broader `group` placement,
and multi-instance scheduling are still deferred.

This keeps the model natural:

- the whole system is still an actor;
- the actor's content includes a static actor network;
- top-level transactions/rules sequence network behavior and express
  actor-to-actor movement by activating existing drive bodies;
- actors inside the network remain reusable ISF actors with local schedules;
- FSMGen builds the network schedule from explicit triggers, waits, events,
  drive body endpoint pairs, and constraints.
- ATL v0 should minimize friction in the ISF format by reusing the current
  data-movement vocabulary wherever the semantics fit. Scheduler-side endpoint
  classification is preferred over adding another author-facing movement
  syntax family.

## ATL V0 Public Contract

ATL v0 now has a selected public source direction:

- The source root remains `(actor NAME ...)`.
- The actor body is the network boundary; `(network ...)` is not accepted.
- Static actor instances use direct actor-body
  `(instance NAME of ACTOR_TYPE)` clauses.
- Verbose source forms are normative. Compact forms are optional future
  aliases only after they lower to the same ATL IR and diagnostics.
- Endpoint-aware movement reuses existing drive-body assignment pairs in
  `(sink source)` order and existing drive calls as timing points. ATL v0 does
  not add `connect`, `transfer`, or `move` as the public movement surface.
- Qualified endpoints use `pins.name`, `actor.port`, `actor.transaction`,
  `actor.event`, and `group.name`.
- Blocking actor-transaction orchestration uses
  `(do actor.transaction)` when that future implementation ships.
- Nonblocking actor-transaction orchestration uses
  `(spawn actor.transaction as NAME)` when that future implementation ships.
- Rule-level actor-transaction orchestration uses
  `(trigger actor.transaction)` when that future implementation ships.
- Actor event synchronization uses `(await actor.event)` when that future
  implementation ships. Event payloads are not part of ATL v0.
- Concurrent actor groups use
  `(group NAME (members ACTOR...) (mode concurrent))` when that future
  implementation ships. Groups express schedulable intent, not an override for
  safety.

The current generated-artifact contract is also explicit: FSMGen may add the
selected one-bit actor-event handoff input to the parent scheduled `.fsm`,
may add the selected one-cycle actor-transaction trigger handoff output to
the parent scheduled `.fsm`, and reports those handoffs through
`actor_network.event_waits[]` and `actor_network.transaction_triggers[]`. It
still emits no generated ATL child `.fsm`, generated ATL top, route mux,
internal handoff storage, child instance, or HDL event wiring. Later leaves
must add their generated artifact names, report keys, examples, and
fail-closed diagnostics in the same slice that ships the behavior.

## Shipped First Actor-Event Wait Subset

The first behavior-bearing event wait subset is shipped:

```lisp
(actor packet_pipe
  (clock clk)
  (interface
    (input start)
    (output done))
  (instance reader of packet_reader)
  (transaction run
    (on start)
    (await reader.done)
    (complete done)))
```

The shipped lowering is intentionally narrow. A single top-level
transaction-body `(await actor.event)` may target the current single declared
static actor instance. The event name must be a scalar HDL identifier. FSMGen
lowers that wait to a deterministic one-bit parent handoff input named
`actor_event`; for example, `reader.done` becomes `reader_done`. The parent
scheduled `.fsm` exposes and waits on that input.

The event producer is external in this subset. FSMGen does not resolve
`packet_reader`, emit a child `.fsm`, generate an ATL top, trigger an actor
transaction, or route event wiring yet. This subset only gives the parent
schedule a reviewable one-cycle event input and records the wait in
actor-network report metadata.

Schedule JSON records accepted waits in `actor_network.event_waits[]` with
`transaction`, `context`, `instance`, `event`, `signal`, and `source` keys.
The current `source` value is `external_handoff`.

The first subset explicitly excludes fan-in, fan-out, multiple actor-event
waits, nested actor-event waits, event payloads, cross-clock actor events,
generated ATL child artifacts, generated ATL tops, and concurrent group
events. Those forms stay fail-closed until later leaves select their exact
artifact and scheduling contracts.

## Shipped First Actor-Transaction Trigger Subset

The first behavior-bearing actor-transaction trigger subset is shipped:

```lisp
(actor packet_pipe
  (clock clk)
  (interface
    (input start)
    (output done))
  (instance reader of packet_reader)
  (transaction run
    (on start)
    (trigger reader.capture)
    (await reader.done)
    (complete done)))
```

The selected lowering is one top-level transaction-body
`(trigger actor.transaction)` targeting the current single declared static
actor instance. The target transaction name must be a scalar HDL identifier.
FSMGen lowers that trigger to a deterministic one-cycle parent output handoff
named `actor_transaction_start`; for example, `reader.capture` becomes
`reader_capture_start`. The scheduled parent `.fsm` exposes and pulses that
output at the trigger point.

The trigger sink is external in this subset. FSMGen does not resolve
`packet_reader`, emit a child `.fsm`, generate an ATL top, connect the start
pulse to an actor instance, add ready/backpressure, or carry trigger payloads
yet. Schedule JSON records accepted triggers in
`actor_network.transaction_triggers[]` with `owner_transaction`, `context`,
`instance`, `target_transaction`, `signal`, and `sink` keys. The selected
`sink` value is `external_handoff`.

The selected subset explicitly excludes rule-level qualified triggers, nested
qualified triggers, multiple qualified triggers, generated handoff signal
conflicts, fan-in, fan-out, trigger payloads or bindings, ready/backpressure,
cross-clock actor triggers, generated ATL child artifacts, generated ATL tops,
and concurrent group triggers. Those forms stay fail-closed until later leaves
select their exact artifact and scheduling contracts.

## Shipped Static Metadata Slice

The first shipped slice accepts exactly one static actor instance:

```lisp
(actor packet_pipe
  (clock clk)
  (interface
    (input start)
    (output done))
  (instance reader of packet_reader)
  (transaction run
    (on start)
    (complete done)))
```

The direct actor-body form preserves schedule-report metadata:

```json
{
  "kind": "static_declaration",
  "instances": [
    {
      "name": "reader",
      "actor_type": "packet_reader",
      "declaration": "actor"
    }
  ],
  "event_waits": []
}
```

This slice is intentionally not ATL scheduling. It does not resolve
`packet_reader`, emit a child `.fsm`, build a generated ATL top, move data
between actors, trigger `reader` transactions, or wait on `reader` events.
Those behaviors remain separate task-tree leaves with their own artifact and
report contracts.

## Endpoints

ATL needs a reviewable endpoint vocabulary:

| Endpoint | Meaning |
| --- | --- |
| `pins.name` | A top-level actor interface pin. |
| `actor.port` | A named interface port on an actor instance. |
| `actor.transaction` | A named transaction on an actor instance. |
| `actor.event` | A named scheduler-visible event emitted by an actor instance. |
| `group.name` | A named concurrent group, used only where group-level semantics are explicit. |

The first implementation rejects unresolved endpoint movement by not accepting
qualified endpoint drive lowering yet. It also rejects ambiguous or dynamic
instance declarations, multiple instances, recursive self-instantiation,
groups, implicit default transactions, and dynamic instance names.

## Verbose Syntax Candidate

The verbose syntax should be the normative form because it is easiest to audit
and easiest for downstream tools to emit.

```lisp
(actor packet_pipe
  (clock clk)
  (reset (rst_n async active_low))

  (interface
    (input  start)
    (input  in_data  (width 32))
    (output out_data (width 32))
    (output done))

  (instance reader of packet_reader)
  (instance crc    of crc32_unit)
  (instance writer of packet_writer)

  (group pipeline
    (members reader crc writer)
    (mode concurrent))

  (drive feed_reader
    (reader.data_i pins.in_data))

  (drive feed_crc
    (crc.payload reader.payload))

  (drive feed_writer
    (writer.crc crc.result))

  (drive publish_output
    (pins.out_data writer.data_o))

  (transaction run_packet
    (on start)
    (drive feed_reader)
    (trigger reader.capture)
    (await reader.done)
    (drive feed_crc)
    (trigger crc.compute)
    (await crc.done)
    (drive feed_writer)
    (trigger writer.emit)
    (await writer.done)
    (drive publish_output)
    (complete done)))
```

Proposed clause meanings:

- `(instance name of actor_type ...)` statically instantiates a reusable actor.
- `(drive name (sink source) ...)` keeps the existing drive-body assignment
  pair shape. ATL widens what `sink` and `source` may name: actor endpoints,
  top-level pins, and compatible local values become legal candidates in
  addition to today's actor-local drive targets and values. The first position
  remains the driven target/sink, matching shipped drive-body semantics; the
  second position remains the value/source.
- `(drive name args...)` in a transaction keeps its existing drive-call
  meaning. The call site gives the scheduler the timing point for the
  endpoint movement recorded in the drive body.
- `(trigger actor.transaction)` activates a qualified actor transaction.
- `(await actor.event)` waits for a scheduler-visible actor event.
- `(group name ...)` declares an intentional concurrent actor group. It does
  not force unsafe concurrency; it gives the scheduler an explicit group to
  analyze, schedule, report, or reject.

There is no preferred top-level `connect` clause in this v0 proposal. If a
later slice needs an explicit physical/static pin binding, it should be a
separate construct with a different contract from actor-to-actor temporal
movement.

## Compact Syntax Candidate

Compact syntax should be a readability alias for the verbose form, not a
different semantic surface.

```lisp
(reader : packet_reader)
(crc    : crc32_unit)
(writer : packet_writer)

(concurrent pipeline reader crc writer)

(drive feed_reader (reader.data_i pins.in_data))
(drive feed_crc (crc.payload reader.payload))
(drive feed_writer (writer.crc crc.result))
(drive publish_output (pins.out_data writer.data_o))

(transaction run_packet
  (on start)
  (drive feed_reader)
  (trigger reader.capture)
  (await reader.done)
  (drive feed_crc)
  (trigger crc.compute)
  (await crc.done)
  (drive feed_writer)
  (trigger writer.emit)
  (await writer.done)
  (drive publish_output)
  (complete done))
```

Candidate compact aliases:

| Compact form | Verbose meaning |
| --- | --- |
| `(inst : actor_type)` | `(instance inst of actor_type)` |
| `(concurrent name actor...)` | `(group name (members actor...) (mode concurrent))` |

The verbose form should be accepted first if implementation risk requires
phasing. The compact form should only ship once it is proven to lower to the
same internal ATL IR and diagnostics.

No new compact movement spelling is planned for ATL v0. The movement surface
is the existing drive definition and drive-call surface with endpoint-aware
body pairs.

The compact `->` operator is intentionally not part of the preferred v0
proposal because it reads too much like a permanent wire or static route.

## Top-Level Orchestration

Top-level transactions and rules should be able to orchestrate the network
using qualified actor endpoints.

Verbose candidate:

```lisp
(transaction run_packet
  (on start)
  (drive feed_reader)
  (trigger reader.capture)
  (await reader.done)
  (drive feed_crc)
  (trigger crc.compute)
  (await crc.done)
  (drive feed_writer)
  (trigger writer.emit)
  (await writer.done)
  (drive publish_output)
  (complete done))
```

Existing ISF activation vocabulary is the selected ATL v0 direction:

- `(do actor.transaction)` means blocking activation once qualified
  transaction targets ship.
- `(spawn actor.transaction as name)` means nonblocking activation once
  qualified transaction targets ship.
- `(await actor.event)` waits for a named actor event once actor events ship.
- `(trigger actor.transaction)` is the verbose orchestration form in rules,
  matching the existing rule-trigger mental model once qualified rule triggers
  ship.
- `(drive name)` keeps the existing named drive-call shape. ATL movement is
  recorded by endpoint-aware assignment pairs inside the called drive body,
  without exposing the generated mux/connectivity plan in source.

The first ATL implementation should require explicit transaction targets such
as `reader.capture`. Actor-level default activation should remain deferred
until there is a declared default transaction or entry transaction contract.

## Data Movement Semantics

ATL should not model actor-to-actor data movement as permanent wiring, or even
as a separate top-level connectivity clause in the preferred v0 model. It
should model movement as endpoint-aware assignment pairs inside existing drive
bodies. Transaction drive calls, inline drive clauses, or later rule-level
activation sites provide the timing intent.

The RTL analogy is a mux feeding a flop. The sink actor is like the flop D
input. Source actors are like the mux data inputs. Over time, several source
actors may be eligible to move data/information to the same sink actor. On any
given cycle, mux selectors decide which source reaches the D input. ATL should
capture the same intent one level higher without asking the author to spell
out the mux or physical route.

In ATL source, a drive-body endpoint pair plus its activation site says only:

```text
when this drive body is activated, this source endpoint or value may drive
this sink endpoint
```

That is already the highest timing precision ATL should require. The scheduler
then derives the actual connectivity, mux input, enable, handoff storage, and
selected cycle when it lowers to explicit `.fsm` and HDL.
In practice, the author should not have to think much about routing. The
author names movement intent through existing drive-body pairs; FSMGen owns
the dynamic runtime routing control that selects the route, mux input, enable,
or handoff needed for the scheduled actor interaction.

This matters most when several source actors can provide the same information
to one sink actor. ATL should treat that as a normal design shape only when
FSMGen can infer a reviewable mux/enable/handoff plan, or prove the sources
are active in disjoint cycles.

An endpoint-aware drive-body assignment pair:

- is temporal, not permanent;
- records sink endpoint, source endpoint or value, and the drive activation
  site that gives the pair timing;
- can move data when both source and sink actors are active, or when the sink
  actor is active and the relevant input/data-valid condition is true;
- can cause FSMGen to derive temporary storage, handoff registers, mux/enable
  selection, generated activation bindings, or generated top connectivity;
- must report source endpoint, sink endpoint, storage/lifetime class, selected
  cycle or dependency, valid/trigger evidence, and any generated mux or handoff
  plan;
- must reject unsupported lifetimes, ambiguous ordering, missing width
  evidence, and unsafe same-cycle assumptions.

Initial ATL endpoint drives should be scalar or bit-vector only. Aggregates,
payload-carrying events, streaming channels, queues, and backpressure
protocols should be later leaves.

The selected ATL v0 movement source shape is not a new `(drive source sink)`
syntax. It is the existing drive body/call syntax with a wider endpoint
vocabulary in drive body pairs. FSMGen can infer whether the source, the sink,
or both are anchored at actor interfaces or top-level pins. The grammar must
remain fail-closed: existing named drive calls and inline drive assignments
keep their shipped meaning, the pair ordering stays target/sink first and
value/source second, and ambiguous endpoint references must be rejected.
This deliberately keeps ATL close to the rest of ISF: users already understand
that drive bodies describe data movement and drive calls place that movement
in the schedule.

## Concurrent Actor Groups

Concurrent groups express author intent that actors may operate together.
They are not an override for safety.

FSMGen should:

- infer data and event dependencies inside the group;
- allow independent actors to run concurrently when dependencies permit;
- serialize or insert handoff storage when required by explicit dependencies;
- emit mux/enable plans when multiple sources can feed one sink at distinct
  scheduled moments;
- reject cycles with no storage, ambiguous fan-in, and unsupported lifetime
  overlap;
- report group membership, inferred dependencies, inserted storage, and any
  rejected ambiguity.

The first group implementation can be conservative. It can accept only
single-clock actor instances with explicit endpoint-aware drive body pairs and
no dynamic membership.

## Scheduling Ownership

Scheduling should split cleanly:

- Each actor owns its local transaction/rule schedule.
- The ATL network scheduler owns instance elaboration, activation handoffs,
  drive-body endpoint dependency analysis, derived mux/enable/handoff insertion,
  runtime route-select control, pin boundary movement, event fan-out/fan-in
  policy, and generated top scheduling.
- The generated `.fsm` remains the audit artifact for the inferred global
  schedule.
- The schedule report should expose `actor_network` metadata without requiring
  downstream consumers to parse generated `.fsm` text.

## Current Implementation Subset

The shipped first static implementation accepts one direct actor-body
`(instance name of actor_type)` clause and reports it under `actor_network`.

The shipped first behavior-bearing handoff subset accepts one top-level
transaction-body `(await actor.event)` and one top-level transaction-body
`(trigger actor.transaction)` for the current single static actor instance.
The event wait lowers to a parent input named `actor_event`; the transaction
trigger lowers to a parent output named `actor_transaction_start`. Both
handoffs are external: FSMGen does not resolve actor types, generate child
artifacts, emit an ATL top, or wire HDL event/trigger routes yet.

The parser still recognizes unsupported reserved qualified forms and rejects
them with ATL-specific diagnostics instead of letting them fall through as
enum-member, unknown-transaction, or unsupported local-clause errors when the
qualifier names a declared static actor instance. Rule-level qualified
`(trigger actor.transaction)`, nested waits/triggers, multiple waits/triggers,
generated handoff signal conflicts, and cross-clock ATL handoffs remain
fail-closed. Existing unqualified local behavior is preserved:
`(await signal)` remains a local transaction wait, and rule-level
`(trigger transaction)` remains the local transaction trigger surface.
Enum-looking dotted names whose qualifier is not a declared static actor
instance keep their prior diagnostics.

The smallest later data-movement ATL implementation should select explicit
generated artifact names and report keys before accepting endpoint-aware drive
movement. A likely useful next subset is:

1. One top-level `(actor ...)` with direct actor-body ATL clauses.
2. Single clock/reset only.
3. Static `(instance name of actor_type)` declarations.
4. One named drive body whose assignment pair references two qualified
   endpoints, plus one transaction drive call that activates it.
5. Schedule-report metadata for instance identity, event/endpoint bindings,
   generated artifact names, and
   generated mux/enable/handoff or connectivity artifacts.

The next slices can add multiple sources feeding one sink, top-level pin
movement in both directions, compact aliases, and concurrent groups.

## Fail-Closed Boundaries

ATL v0 should reject:

- dynamic actor creation or runtime instance names;
- unresolved actor, transaction, event, port, pin, or group endpoints;
- actor-level activation without an explicit transaction target;
- permanent continuous actor-to-actor movement assumptions;
- top-level `connect` clauses as actor-to-actor movement syntax in ATL v0;
- multiple writers to one endpoint without provably disjoint timing or a
  shipped mux/arbitration contract;
- event payloads;
- implicit data movement through events;
- cross-clock actor-network movement without explicit CDC syntax;
- recursive actor-network instantiation;
- combinational dependency cycles without storage;
- compact aliases before they are mapped to the same IR as verbose forms;
- `(network ...)` wrappers;
- any endpoint-aware drive-body pair whose width, lifetime, endpoint
  direction, or ordering cannot be proven.

## Open Decisions

- Whether later ergonomic sugar above endpoint-aware drive-body pairs is worth
  adding after the v0 drive-body reuse path is implemented and reviewed.
- Directional symbolic aliases such as `=>` should stay deferred unless they
  prove clearer than the selected drive-body source form.
- Whether concurrent groups need a stronger contract for expected overlap
  after the first conservative group scheduler ships.
- Which realistic fixture should prove the first end-to-end ATL value.
