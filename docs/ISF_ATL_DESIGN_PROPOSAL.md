# ISF Actor Transfer Level Design Proposal

Status: active design proposal, not implemented.

Task-tree owner:
[docs/tasks/ISF-ACTOR-NETWORK-ORCHESTRATION.md](tasks/ISF-ACTOR-NETWORK-ORCHESTRATION.md).

## Purpose

Actor Transfer Level (`ATL`) is the proposed ISF actor-network layer. The
mental model is deliberately close to RTL, but the transfer endpoints are
actors instead of flops/registers.

- RTL describes how values move between registers and logic.
- ATL describes how data, information, and activation move between actors.
- ATL movement clauses are temporal route/capability declarations, not
  permanent actor-to-actor wires. Like RTL mux inputs feeding one flop at
  different cycles, multiple source actors may feed one sink actor only when
  the scheduler can prove the selected source and cycle.
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
  atl_clause...)
```

The top-level actor is the network boundary. Its `interface` declares the
top-level pins. Its `transaction` and `rule` clauses can orchestrate the actor
network. The exact container spelling for ATL clauses is still open.

There are two viable source-shape candidates.

### Candidate A: Scoped Network Clause

```lisp
(actor top_name
  actor_clause...
  (network
    network_clause...))
```

In this spelling, `(network ...)` is only a lexical scope for ATL clauses. It
is not a second semantic root. The whole system is still the enclosing actor.

Benefits:

- keeps instance/route/transfer/group clauses separate from existing actor
  clauses;
- gives diagnostics a clear "inside network" context;
- leaves room for future actor-local clauses without name collisions.

Costs:

- adds a wrapper even though the enclosing actor is already the network;
- may make simple systems look heavier than needed.

### Candidate B: Flat Actor Clauses

```lisp
(actor top_name
  actor_clause...
  (instance instance_name of actor_type)
  (connect (from endpoint) (to endpoint))
  (transfer source to destination)
  (group group_name group_clause...))
```

In this spelling, ATL clauses are direct clauses of the top-level actor. There
is no `(network ...)` wrapper. The actor body itself is the network.

Benefits:

- matches the user's mental model most directly: the actor content is the
  actor network;
- removes one nesting level;
- makes top-level actor transactions/rules and actor-network clauses feel like
  one unified ATL surface.

Costs:

- requires the parser and diagnostics to distinguish actor-local clauses from
  ATL clauses at the same level;
- raises name-collision questions sooner if future actor clauses use similar
  names.

The semantics below do not depend on either spelling. The first specification
slice should choose one spelling, or explicitly support both by lowering them
to the same ATL IR.

This keeps the model natural:

- the whole system is still an actor;
- the actor's content is a static actor network;
- top-level transactions/rules are allowed to sequence network behavior;
- actors inside the network remain reusable ISF actors with local schedules;
- FSMGen builds the network schedule from explicit triggers, waits, events,
  temporal movement routes, transfers, and constraints.

## Endpoints

ATL needs a reviewable endpoint vocabulary:

| Endpoint | Meaning |
| --- | --- |
| `pins.name` | A top-level actor interface pin. |
| `actor.port` | A named interface port on an actor instance. |
| `actor.transaction` | A named transaction on an actor instance. |
| `actor.event` | A named scheduler-visible event emitted by an actor instance. |
| `group.name` | A named concurrent group, used only where group-level semantics are explicit. |

The first implementation should reject unresolved endpoints, ambiguous names,
implicit default transactions, and dynamic instance names.

## Verbose Syntax Candidate

The verbose syntax should be the normative form because it is easiest to audit
and easiest for downstream tools to emit. The example below uses Candidate A
only to show the scoped form. Candidate B would place the same ATL clauses
directly under `(actor packet_pipe ...)`.

```lisp
(actor packet_pipe
  (clock clk)
  (reset (rst_n async active_low))

  (interface
    (input  start)
    (input  in_data  (width 32))
    (output out_data (width 32))
    (output done))

  (network
    (instance reader of packet_reader)
    (instance crc    of crc32_unit)
    (instance writer of packet_writer)

    (connect (from pins.start)   (to reader.start))
    (connect (from pins.in_data) (to reader.data_i))
    (connect (from writer.data_o) (to pins.out_data))
    (connect (from writer.done)   (to pins.done))

    (transfer reader.payload to crc.payload)
    (transfer crc.result     to writer.crc)

    (event reader_done (from reader.done))
    (event crc_done    (from crc.done))

    (trigger (from reader_done) (to crc.compute))
    (trigger (from crc_done)    (to writer.emit))

    (group pipeline
      (members reader crc writer)
      (mode concurrent))))
```

Proposed clause meanings:

- `(instance name of actor_type ...)` statically instantiates a reusable actor.
- `(connect (from endpoint) (to endpoint))` is a provisional spelling for a
  scheduler-visible route between pin/port endpoints. It must not mean a
  permanent continuous actor-to-actor wire. The route is active only when the
  inferred schedule, trigger, or sink-valid condition selects it.
- `(transfer source to destination)` describes scheduler-owned data/information
  movement. FSMGen may allocate a mux input, handoff storage, activation
  binding, or scheduled transfer state when the producer and consumer cannot
  safely share the same cycle.
- `(event name (from actor.event))` names a one-cycle scheduler-visible event.
  Initial ATL events should carry no payload; payloads move through
  `transfer`.
- `(trigger (from event_or_guard) (to actor.transaction))` activates a
  transaction from an event or guard.
- `(group name ...)` declares an intentional concurrent actor group. It does
  not force unsafe concurrency; it gives the scheduler an explicit group to
  analyze, schedule, report, or reject.

## Compact Syntax Candidate

Compact syntax should be a readability alias for the verbose form, not a
different semantic surface. It can also be scoped or flat, depending on the
source-shape decision.

```lisp
(network
  (reader : packet_reader)
  (crc    : crc32_unit)
  (writer : packet_writer)

  (pins.start   -> reader.start)
  (pins.in_data -> reader.data_i)
  (writer.data_o -> pins.out_data)
  (writer.done   -> pins.done)

  (reader.payload => crc.payload)
  (crc.result     => writer.crc)

  (reader.done -> crc.compute)
  (crc.done    -> writer.emit)

  (concurrent pipeline reader crc writer))
```

Candidate compact aliases:

| Compact form | Verbose meaning |
| --- | --- |
| `(inst : actor_type)` | `(instance inst of actor_type)` |
| `(a -> b)` where both sides are ports/pins | provisional route spelling, equivalent to `(connect (from a) (to b))` if `connect` remains the chosen verbose name |
| `(a => b)` | `(transfer a to b)` |
| `(event -> actor.transaction)` | `(trigger (from event) (to actor.transaction))` |
| `(concurrent name actor...)` | `(group name (members actor...) (mode concurrent))` |

The verbose form should be accepted first if implementation risk requires
phasing. The compact form should only ship once it is proven to lower to the
same internal ATL IR and diagnostics.

## Top-Level Orchestration

Top-level transactions and rules should be able to orchestrate the network
using qualified actor endpoints.

Verbose candidate:

```lisp
(transaction run_packet
  (on start)
  (trigger reader.capture)
  (await reader.done)
  (trigger crc.compute)
  (await crc.done)
  (trigger writer.emit)
  (await writer.done)
  (complete done))
```

Existing ISF activation vocabulary should be reused where possible:

- `(do actor.transaction)` can mean blocking activation.
- `(spawn actor.transaction as name)` can mean nonblocking activation.
- `(await actor.event)` can wait for a named actor event.
- `(trigger actor.transaction)` can be the verbose orchestration form in
  rules, matching the existing rule-trigger mental model.

The first ATL implementation should require explicit transaction targets such
as `reader.capture`. Actor-level default activation should remain deferred
until there is a declared default transaction or entry transaction contract.

## Data Movement Semantics

ATL should not model actor-to-actor data movement as permanent wiring. It
should model movement as temporal routes that the scheduler may activate at
specific points in the inferred schedule.

The RTL analogy is a mux feeding a flop. The mux input wires may exist in HDL,
but the semantic movement happens only when the selected input and write
enable are active for that cycle. ATL should capture the same intent one level
up: source actor `A` may move a value to sink actor `B`, but the actual
movement is selected by scheduling, activation, valid conditions, and
dependency analysis.

This matters most when several source actors can provide the same information
to one sink actor. ATL should treat that as a normal design shape only when
FSMGen can infer a reviewable mux/enable/handoff plan, or prove the sources
are active in disjoint cycles.

`connect`:

- is a provisional name for a scheduler-visible route capability between
  top-level pins and actor ports, actor ports and top-level pins, or compatible
  actor ports;
- is not permanent continuous wiring in ATL semantics;
- becomes active only when the schedule selects the route, for example because
  the source and sink actors are both active, because the sink actor is active
  and the route's valid condition is true, or because an explicit trigger/event
  establishes the dependency;
- may lower to mux input selection, enable gating, temporary storage, or an
  activation binding depending on timing;
- must reject multiple possible writers unless the scheduler can prove
  disjoint timing or emit a documented mux/arbitration plan;
- must preserve width/type evidence in diagnostics and schedule reports.

`transfer`:

- is a more explicit spelling for scheduler-owned data/information movement;
- is also temporal, not permanent;
- can allocate temporary storage, handoff registers, mux/enable selection, or
  generated activation bindings when producer and consumer schedules require
  it;
- must report source endpoint, destination endpoint, storage/lifetime class,
- selected cycle or dependency, valid/trigger evidence, and any generated mux
  or handoff plan;
- must reject unsupported lifetimes, ambiguous ordering, missing width
  evidence, and unsafe same-cycle assumptions.

Initial ATL transfers should be scalar or bit-vector only. Aggregates,
payload-carrying events, streaming channels, queues, and backpressure
protocols should be later leaves.

The final syntax may decide that `connect` is the wrong word because it sounds
too permanent. If so, a name such as `route`, `move`, or `flow` may better
express the temporal route semantics while preserving the same ATL IR.

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
single-clock actor instances with explicit transfer edges and no dynamic
membership.

## Scheduling Ownership

Scheduling should split cleanly:

- Each actor owns its local transaction/rule schedule.
- The ATL network scheduler owns instance elaboration, activation handoffs,
  actor-to-actor temporal route selection, mux/enable/handoff insertion, pin
  boundary movement, event fan-out/fan-in policy, and generated top
  scheduling.
- The generated `.fsm` remains the audit artifact for the inferred global
  schedule.
- The schedule report should expose `actor_network` metadata without requiring
  downstream consumers to parse generated `.fsm` text.

## First Implementation Subset

The smallest useful implementation should be:

1. One top-level `(actor ...)` with ATL clauses, using either the selected
   scoped `(network ...)` form or the selected flat actor-clause form.
2. Single clock/reset only.
3. Static `(instance name of actor_type)` declarations.
4. One explicit temporal route between top-level pins and one actor instance,
   using the selected spelling (`connect`, `route`, or another agreed name).
5. Explicit blocking orchestration from a top-level transaction to one
   qualified child transaction.
6. Schedule-report metadata for instance identity, endpoint bindings, and
   generated artifact names.

The next slices can add actor events, actor-to-actor `transfer`, top-level pin
movement in both directions, compact aliases, and concurrent groups.

## Fail-Closed Boundaries

ATL v0 should reject:

- dynamic actor creation or runtime instance names;
- unresolved actor, transaction, event, port, pin, or group endpoints;
- actor-level activation without an explicit transaction target;
- permanent continuous actor-to-actor movement assumptions;
- multiple writers to one endpoint without provably disjoint timing or a
  shipped mux/arbitration contract;
- event payloads;
- implicit data movement through events;
- cross-clock actor-network movement without explicit CDC syntax;
- recursive actor-network instantiation;
- combinational dependency cycles without storage;
- compact aliases before they are mapped to the same IR as verbose forms;
- mixed scoped and flat ATL clauses unless that mixture is explicitly shipped;
- any transfer whose width, lifetime, or ordering cannot be proven.

## Open Decisions

- Whether ATL v0 should use a scoped `(network ...)` clause, flat actor-level
  ATL clauses, or both as equivalent spellings.
- Whether the final verbose trigger spelling should be `(trigger ...)`,
  `(activate ...)`, or an extension of existing `(do ...)` / `(spawn ...)`.
- Whether `connect` is too permanent-sounding for temporal ATL movement, and
  whether `route`, `move`, or another word should be used instead.
- Whether compact `->` should mean a temporal route, while `=>` means an
  explicit scheduler-owned transfer, or whether that distinction is too subtle.
- Whether `->` should be avoided entirely if it suggests permanent wiring.
- Whether concurrent groups need a stronger contract for expected overlap,
  or whether they should initially be report-only scheduling hints.
- Which realistic fixture should prove the first end-to-end ATL value.
