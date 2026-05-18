# ISF Actor Transfer Level Design Proposal

Status: active design proposal, partially implemented.

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
network. Static actor declarations may be scoped or flat. Data/information
movement should reuse existing drive bodies and drive calls by allowing drive
body assignment pairs to reference actor endpoints and top-level pins.

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

- keeps instance/group declarations separate from existing actor clauses;
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

The first metadata-only implementation slice explicitly supports both
spellings for one static actor instance and lowers both to the same
`actor_network` report metadata. Broader `group` placement and multi-instance
scheduling are still deferred.

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

## Shipped Static Metadata Slice

The first shipped slice accepts exactly one static actor instance:

```lisp
(actor packet_pipe
  (clock clk)
  (interface
    (input start)
    (output done))
  (network
    (instance reader of packet_reader))
  (transaction run
    (on start)
    (complete done)))
```

or the flat alias:

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

Both forms preserve schedule-report metadata:

```json
{
  "kind": "static_declaration",
  "instances": [
    {
      "name": "reader",
      "actor_type": "packet_reader",
      "declaration": "network"
    }
  ]
}
```

This slice is intentionally not ATL scheduling. It does not resolve
`packet_reader`, emit a child `.fsm`, build a generated ATL top, move data
between actors, trigger `reader` transactions, or wait on `reader` events.
Those behaviors remain separate task-tree leaves.

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
and easiest for downstream tools to emit. The example below uses Candidate A
only to show scoped static actor declarations. Candidate B would place
`instance` and `group` directly under `(actor packet_pipe ...)`.

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

    (group pipeline
      (members reader crc writer)
      (mode concurrent)))

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
different semantic surface. It can also be scoped or flat, depending on the
source-shape decision.

```lisp
(network
  (reader : packet_reader)
  (crc    : crc32_unit)
  (writer : packet_writer)

  (concurrent pipeline reader crc writer))

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

Existing ISF activation vocabulary should be reused where possible:

- `(do actor.transaction)` can mean blocking activation.
- `(spawn actor.transaction as name)` can mean nonblocking activation.
- `(await actor.event)` can wait for a named actor event.
- `(trigger actor.transaction)` can be the verbose orchestration form in
  rules, matching the existing rule-trigger mental model.
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

## First Implementation Subset

The smallest useful implementation should be:

1. One top-level `(actor ...)` with ATL clauses, using either the selected
   scoped `(network ...)` form or the selected flat actor-clause form.
2. Single clock/reset only.
3. Static `(instance name of actor_type)` declarations.
4. One named drive body whose assignment pair references two qualified
   endpoints, plus one transaction drive call that activates it.
5. Explicit blocking orchestration from a top-level transaction to one
   qualified child transaction.
6. Schedule-report metadata for instance identity, endpoint bindings, and
   generated mux/enable/handoff or connectivity artifacts.

The next slices can add actor events, multiple sources feeding one sink,
top-level pin movement in both directions, compact aliases, and concurrent
groups.

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
- mixed scoped and flat ATL clauses unless that mixture is explicitly shipped;
- any endpoint-aware drive-body pair whose width, lifetime, endpoint
  direction, or ordering cannot be proven.

## Open Decisions

- Whether ATL v0 should use a scoped `(network ...)` clause, flat actor-level
  ATL clauses, or both as equivalent spellings.
- Whether the final verbose trigger spelling should be `(trigger ...)`,
  `(activate ...)`, or an extension of existing `(do ...)` / `(spawn ...)`.
- Whether later ergonomic sugar above endpoint-aware drive-body pairs is worth
  adding after the v0 drive-body reuse path is implemented and reviewed.
- Directional symbolic aliases such as `=>` should stay deferred unless they
  prove clearer than the simple two-operand word form.
- Whether concurrent groups need a stronger contract for expected overlap,
  or whether they should initially be report-only scheduling hints.
- Which realistic fixture should prove the first end-to-end ATL value.
