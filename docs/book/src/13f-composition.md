# Composition

Composition lets transactions call other transactions.

## `(do child)` — Blocking Call

```lisp
(transaction parent
  (on start)
  (do read_phase)
  (do write_phase)
  (complete done))
```

Sequential, blocking. One instance of each child is intended to be reused by
the parent transaction.

The base form is exact: `(do child)`, with one scalar child transaction
operand. The parameterized/bound form accepts nested subclauses:
`(do child (domain NAME) (params (NAME value) ...) (bind ...))`. At most one
`domain` block, one `params` block, and one `bind` block may appear. Malformed
missing, nested, duplicate, or unsupported operands fail before child-target
resolution.

**Current local lowering**:
1. Parent asserts `child_start` and awaits `child_done`
2. Child's idle state is rewired to watch `child_start`
3. Child's terminal state pulses `child_done` with `<1`

The child target must name a declared transaction in the same actor. Forward
references are accepted because lowering validates after the full actor body
is parsed; missing targets fail before scheduled `.fsm` emission.

The rewired child idle state enters the first non-entry child state; the child
body may start with a drive, await, data operation, or other scheduled state.

```lisp
(parent_do_1
  (= (read_phase_start 1))
  (<read_phase_done
    (-> parent_do_2)))

(read_phase_idle_0
  (<read_phase_start
    (-> read_phase_drive_0)))

(read_phase_done_5
  (<1 (done> 1))
  (<1 (read_phase_done 1))
  (-> read_phase_idle_0))
```

The internal child-done signal is a one-cycle delayed pulse. This matters when
the parent invokes the same child more than once: each `(do child)` waits for a
fresh completion instead of seeing a sticky done bit left from the previous
call.

Top-level repeat bodies may also use the plain local `(do child)` form. In
that repeat-body subset, the child remains in the parent scheduled module, the
repeat-body `do` state waits for `child_done`, and the repeat check back-edge
is reachable only after that fresh done pulse. Repeat-body generated `do` may
use static `(params ...)`, optional `(bind ...)`, and optional same-domain
`(domain NAME)` metadata for one lexical generated instance. Cross-domain
repeat-body `do`, repeat-body `do` targeting an already generated child, and
sample-before/after-do timing are still backlog.

Parameterized blocking `do` uses the generated child activation path instead
of rewiring a local child body. The child is emitted as its own scheduled
module, the generated top instantiates a deterministic child instance named
`{parent}_{child}_do_{ordinal}`, and the parent asserts that instance's
`start` handoff while awaiting its `done` handoff. Parameter overrides are
applied in the generated top `?fsmc` `(params ...)` block:

```lisp
(transaction parent
  (on start)
  (do worker
    (params
      (WIDTH 16))
    (bind
      (input addr req_addr)
      (output data resp)))
  (complete done))
```

Representative scheduled parent artifacts:

```lisp
(parent_do_1
  (= (parent_worker_do_0_start> 1))
  (<parent_worker_do_0_done
    (-> parent_complete_2)))

(-parent_worker_do_0_port_bindings
  (= (parent_worker_do_0_addr> req_addr))
  (= (resp> parent_worker_do_0_data) <parent_worker_do_0_done))
```

Input bindings may use scalar signals, numeric/exact-width literals, or
non-empty list expressions as the parent-owned payload source. Spawned child
input-binding source signals are consumed by the explicit parent handoff and
are not also same-name wired into the child instance.

Representative generated top instance:

```lisp
(?fsmc:parent_worker_do_0 worker
  (params
    (WIDTH 16)))
```

Input bindings are same-cycle handoff assignments owned by the parent. Output
bindings are guarded by the generated child instance's `done` pulse so the
parent copies the child output when the blocking call completes. A plain
`(do child)` remains local when the child is not otherwise generated. If the
same child transaction is already emitted as a generated child because of
spawn or a parameterized `do`, a plain `do` to that child also uses a generated
activation instance so the parent never targets a skipped local child body.

## `(spawn child as name)` — Parallel Fork

```lisp
(transaction parent
  (on start)
  (spawn worker as w0)
  (spawn worker as w1)
  (spawn worker as w2)
  (await_all done)
  (complete done))
```

Non-blocking. Each spawn declares a separate intended instance.

`spawn` is an elaboration construct with runtime activation semantics. The
generated hardware instance is static: it exists for the lifetime of the
generated module. Executing the spawn state at runtime asserts that instance's
start path; completing the child transaction returns the same static instance
to its start-gated idle state. Completion never destroys the instance, and a
later activation reuses the same child hardware.

This matters for loops. In the shipped repeat-body subset, `(spawn ...)` does
not mean "create N child instances." It means "activate the same lexically
named child instance once per loop iteration." A design that needs parallel
workers should author distinct spawn instance names, or use a future
static-generation surface if one is added. The shipped repeat-body subset
requires same-body `(await_all done)`, or same-body `(await_any done)` when
exactly one spawn is pending, before the repeat check can loop. The scheduler
rejects paths that could start the static child instance again before its
fresh `done` pulse has been observed.

The base form is exact: `(spawn child as name)`. Optional nested subclauses add
static parameter overrides, explicit port bindings, or declared same-domain
ownership metadata: `(spawn child as name (domain NAME) (params (NAME value)
...) (bind ...))`. The child, instance, and domain names must be scalar, and
the literal `as` separator is required. Malformed spawn forms fail before
spawned child collection, so the scheduler does not invent a default instance
name for an invalid clause.

**Lowering**:
- One `.fsm` per unique child module
- Spawn targets must name declared transactions in the same actor
- Parent `.fsm` declares per-instance `name_start`/`name_done` signals
- Each spawn state asserts its matching `name_start` signal
- `(await_all done)` → one transition guarded by the logical AND of all done
  signals
- `(await_any done)` → one guard per done signal, advancing on the first one
  that fires
Both synchronization forms have focused regressions.

Composition-top instantiation is shipped for the covered generated-child
fixture set. Spawn parameter declaration, blocking `do` parameter declaration,
validation, scheduled child `+params` emission, per-instance override
preservation, and generated-top application now flow through the existing
composition pipeline:

- Multi-file generated-child actors use an explicit generated top over the
  scheduled parent module and child modules.
- The scheduled parent keeps the actor name; the generated top uses a distinct
  deterministic name, initially `{actor}_top`.
- The top re-exports the actor public interface.
- Per-instance `name_start` and `name_done` are internal top handoff links, not
  public top ports.
- The scheduled parent exposes `name_start` as an output and `name_done` as an
  input for each spawned instance.
- Each generated child exposes `start` as an input and `done` as an output.
- Named drive calls in spawned children expose per-drive handoff outputs that
  the top wires back into parent per-instance handoff inputs.
- After completion, a spawned child returns to its `start`-guarded idle state
  and waits for the next start pulse.

Parameterized spawn and parameterized blocking `do` use one optional nested
`params` block:

```lisp
(transaction worker
  (params
    (WIDTH 8))
  ...)

(transaction parent
  (on start)
  (spawn worker as w0
    (params
      (WIDTH 16)))
  (await_all done)
  (complete done))
```

The shipped activation-parameter surface covers spawned child instances and
blocking `do` generated child activations. Override names must match child
transaction parameters, duplicate instance/parameter names fail, scalar
literal overrides are width-flexible, and aggregate defaults require
compatible aggregate overrides. Actor-local constants, actor-local scalar
parameter defaults, local or package-qualified enum members, and qualified
imported package scalar constants may be used as scalar override values, or as
scalar leaves inside aggregate/list override values. These static override
sources resolve to literal values before generated-top emission; package
constants must be qualified scalar package `+constants` entries, and
unqualified, aggregate, or package member/item paths fail closed.

A generated child `.fsm` emits the child transaction defaults in `+params`;
parameter declarations on non-generated transactions without a supported
same-transaction static use fail closed; the parent lowerer IR preserves
per-instance override lists, and the generated top applies those overrides
through `?fsmc` `(params ...)` blocks.

```lisp
(parent_main_await_all_4
  (-> parent_main_done_5 <(& w0_done w1_done w2_done))
)
```

The compact transition suffix above is equivalent to nested guards over the
same done ports, but the scheduled `.fsm` artifact uses the direct conjunction
so the all-done condition is visible at the transition site.

## `(await_all port)` / `(await_any port)`

```lisp
(await_all done)     ;; wait for ALL spawned children
(await_any done)     ;; wait for ANY spawned child
```

The forms are exact: `(await_all done_port)` and `(await_any done_port)`, with
one scalar done-port operand. Malformed missing, nested, or extra operands fail
before sync-state emission.

## Composition Architecture

```
spawn_parent.isf
    │
    ▼ LoweringIR
    │
    ├── child_worker.fsm       (child module with start/done ports)
    ├── spawn_parent.fsm       (parent with per-instance handoff signals)
    └── spawn_parent_top.fsm   (generated composition top wiring parent and children)
```

The `--outdir DIR` flag writes all generated `.fsm` files:

```bash
./bin/fsmgen --strict --outdir output/ isf/spawn_parent.isf
# Writes: output/child_worker.fsm, output/spawn_parent.fsm,
#         and output/spawn_parent_top.fsm.
# If --output is also provided, HDL generation uses spawn_parent_top.fsm.
```

## Reusable ISF Libraries

ISF libraries are reusable source-intent roots. They are not textual includes:
an imported definition still lowers to scheduled `.fsm` review artifacts before
HDL generation.

The first shipped root shape is:

```lisp
(library common.fifo
  (exports
    (actor fifo))

  (actor fifo
    ... reusable actor body ...))
```

Actor roots import libraries with `(imports (library name as alias) ...)` and
instantiate exported actors with `(use alias.actor as instance ...)`. Use-site
parameter overrides are instance-local, and bindings are explicit
(the example assumes the sibling `isf/common/fifo.isf` library is on
the search path):

```text
(actor fifo_library_use
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input write_req)
    (input data_in (width 8))
    (input read_req)
    (output full)
    (output empty)
    (output data_out (width 8)))
  (imports
    (library common.fifo as fifo_lib))
  (use fifo_lib.fifo as u_fifo
    (params
      (DATA_WIDTH 8)
      (DEPTH 4)
      (PTR_WIDTH 2)
      (OCC_WIDTH 3))
    (bind
      (clock clk)
      (reset rst_n)
      (input write_req write_req)
      (input data_in data_in)
      (input read_req read_req)
      (output full full)
      (output empty empty)
      (output data_out data_out))))
```

The first shipped reusable definition is
[isf/common/fifo.isf](../../isf/common/fifo.isf), exported as
`common.fifo.fifo`, with
[isf/fifo_library_use.isf](../../isf/fifo_library_use.isf) as the file-backed
import/use fixture. It is a fixed-shape `DATA_WIDTH=8`, `DEPTH=4`,
`PTR_WIDTH=2`, `OCC_WIDTH=3` FIFO actor. The actor owns write and read
pointers, occupancy, full/empty flags, and a four-entry data bank. It models
idle, push-only, pop-only, and push-plus-pop cases every cycle, with
read-before-write bank semantics for same-cycle store/load.

The shipped catalog is
[docs/ISF_LIBRARY_CATALOG.md](../../ISF_LIBRARY_CATALOG.md). The public ISF
contract advertises the catalog through `library_catalog_paths`, the bounded
entry fields through `library_catalog_entry_keys`, and the current shipped
entries through `shipped_library_definitions`. Actor top-level interface width
parameters, actor-owned scalar storage width parameters, actor-owned bank
width parameters, and actor-owned bank depth parameters are shipped for
positive actor-local scalar defaults, but use-site FIFO interface shape,
use-site bank-depth specialization, generated-top respecialization,
memory-array backend emission, standalone transaction or drive exports, and
nested library imports remain future work.

## Static Actor-Network Metadata

### Actor-As-Network Boundary And Direct Instances

The first Actor Transfer Level (`ATL`) implementation slice is intentionally
small: a top-level actor may declare one static actor instance, and FSMGen
preserves that declaration in the parser shell and schedule report. The
shipped source surface accepts the verbose `(instance NAME of ACTOR_TYPE)`
form and the compact `(NAME : ACTOR_TYPE)` readability alias.

Accepted form:

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

Compact equivalent:

```lisp
(actor packet_pipe_compact
  (clock clk)
  (interface
    (input start)
    (output done))
  (reader : packet_reader)
  (transaction run
    (on start)
    (complete done)))
```

The enclosing actor is the network boundary; there is no `(network ...)`
wrapper in the shipped ATL static-instance surface.

The report field is `actor_network`:

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
  "groups": [],
  "association_schedules": [],
  "group_schedules": [],
  "data_movements": [],
  "event_waits": [],
  "transaction_triggers": []
}
```

Verbose instances report `declaration: "actor"`. Compact instance aliases
report `declaration: "instance_alias"` so downstream reviewers can recover
the source spelling. Both forms share the same validation and scheduling
boundary.

This is not generated-child composition yet. FSMGen does not resolve
`packet_reader`, emit a child `.fsm`, build an ATL top, or wire `reader`
transactions/events to child artifacts in this slice. Broader multiple
instances outside the shipped scalar handoff and group metadata subsets,
broader group scheduling outside the exact trigger-batch subset, pin
movement, event fan-in/fan-out, trigger fan-in/fan-out, and generated ATL
wiring remain backlog under the actor-network task tree.

The broader ATL v0 contract is selected for later slices.

The source root stays `(actor ...)`, and future ATL declarations remain
direct actor-body clauses rather than a `(network ...)` section.

### Drive-Body Data Movement

Actor-to-actor and scalar top-level pin movement reuse the existing
drive-body pair shape in `(sink source)` order plus ordinary drive-call
timing points.

`connect`, `transfer`, and `move` are not part of ATL v0 movement syntax.

The first endpoint-movement implementation sequence first shipped fail-closed
reservation for unsupported endpoint drive-body pairs, then shipped the
generated actor-to-actor handoff subset for one-bit scalar and exact-width
vector generated-child routes.

The accepted subset is intentionally narrow: exactly two direct static actor
instances, one named drive body with one `(sink_actor.endpoint
source_actor.endpoint)` pair, matching source-output and sink-input endpoint
widths, and one top-level transaction drive call.

The generated parent `.fsm` exposes an external source input named
`source_actor_source_endpoint` and an external sink output named
`sink_actor_sink_endpoint`. Their width is one for scalar one-bit routes or
the exact matching child endpoint width for vector routes. The route lasts for
the drive-call cycle and does not imply storage, a mux, pin movement in that
actor-to-actor route, fan-in/fan-out, groups, CDC, or trigger/await coupling
beyond the selected generated-child top sequence.

```lisp
(actor atl_scalar_data_movement
  (clock clk)
  (interface (input start) (output done))
  (instance producer of packet_reader)
  (instance consumer of packet_writer)
  (drive feed_consumer
    (consumer.payload producer.payload))
  (transaction run
    (on start)
    (drive feed_consumer)
    (complete done)))
```

FSMGen rewrites the drive body to generated parent handoff signals before
lowering. The scheduled parent `.fsm` exposes `producer_payload` as the
source input and `consumer_payload` as the sink output, then the named drive
request drives `consumer_payload` from `producer_payload` for that call cycle.

The schedule report records the movement in `actor_network.data_movements[]`
with source/sink instance, endpoint, generated signal, width, route lifetime,
and storage fields.

The next selected ATL pin-movement subset reuses the same drive-body timing
model for one top-level input pin feeding one actor endpoint:

```lisp
(actor pin_feed
  (clock clk)
  (interface (input start) (input in_bit) (output done))
  (instance consumer of packet_writer)
  (drive feed_consumer
    (consumer.payload pins.in_bit))
  (transaction run
    (on start)
    (drive feed_consumer)
    (complete done)))
```

This pin-to-actor subset is shipped. The source is the existing one-bit
top-level input pin, and the sink is a generated scalar external actor
handoff output named `consumer_payload`.

The inverse actor-to-top-level output pin direction is also shipped:

```lisp
(actor pin_publish
  (clock clk)
  (interface (input start) (output out_bit) (output done))
  (instance producer of packet_reader)
  (drive publish_result
    (pins.out_bit producer.payload))
  (transaction run
    (on start)
    (drive publish_result)
    (complete done)))
```

FSMGen exposes `producer.payload` as a generated scalar external parent input
named `producer_payload`, drives the existing one-bit top-level output pin
`out_bit` for the drive-call cycle, and reports kind
`scalar_actor_to_pin_handoff`. Wider pins, storage, muxing, generated
children, group scheduling combined with pin movement, CDC, and
trigger/await coupling remain deferred.

### Trigger And Event Pulses

ATL orchestration spellings are `(do actor.transaction)`,
`(spawn actor.transaction as NAME)`, `(trigger actor.transaction)`, and
`(await actor.event)`, with only the bounded transaction-body trigger and
event-wait parent-handoff subsets shipped today. Events are one-cycle control
pulses with no payloads in ATL v0.

### Static Groups Versus Task-Scoped Associations

Concurrent groups may still use
`(group NAME (members ACTOR...) (mode concurrent))` or the compact
`(concurrent NAME ACTOR...)` alias, but each declaration is static review metadata, not a permanent runtime association, and not a way to bypass
fan-in, ordering, width, lifetime, or CDC safety.

The first multi-actor trigger scheduling leaf is shipped as a same-cycle
external trigger batch. It uses only existing transaction-body
`(trigger actor.transaction)` clauses: a contiguous batch may target distinct
static actor instances, lower to one parent state that pulses all selected
trigger outputs, and report canonical evidence through
`actor_network.association_schedules[]`. The compatibility
`actor_network.group_schedules[]` array remains present for schedule JSON
`schema_version: 1`. The association exists for that scheduled trigger state;
it is not permanent group membership.

Report-only static group metadata is now shipped for the verbose form:

```lisp
(actor grouped_pipeline
  (clock clk)
  (interface (input start) (output done))
  (instance reader of packet_reader)
  (instance writer of packet_writer)
  (group pipeline
    (members reader writer)
    (mode concurrent))
  (transaction run
    (on start)
    (complete done)))
```

The compact alias is equivalent for scheduling purposes:

```lisp
(actor grouped_pipeline_compact
  (clock clk)
  (interface (input start) (output done))
  (instance reader of packet_reader)
  (instance writer of packet_writer)
  (concurrent pipeline reader writer)
  (transaction run
    (on start)
    (complete done)))
```

The group appears in `actor_network.groups[]` with `scheduling:
"metadata_only"`. Verbose groups report `declaration: "group"`; compact
aliases report `declaration: "concurrent_alias"` so downstream reviewers can
recover the source spelling. By itself, either declaration names a static
review set; it does not run actors concurrently, infer dependencies, insert
storage or muxes, emit child artifacts, or cross clock domains.

Source-authored group endpoints remain fail-closed. If `pipeline` names a
static group, forms such as `(trigger pipeline.capture)`, `(await
pipeline.done)`, `(await_all pipeline.done)`, `(await_any pipeline.done)`, or
a rule action `(trigger pipeline.capture)` fail before scheduled `.fsm`
emission with the ATL group-endpoint diagnostic. The missing contract is
group-level trigger arbitration/fanout, event aggregation, storage/lifetime,
and generated-child wiring semantics.

The accepted temporary trigger batch does not require a group declaration:

```lisp
(actor trigger_batch_pipeline
  (clock clk)
  (interface (input start) (output done))
  (instance reader of packet_reader)
  (instance writer of packet_writer)
  (transaction run
    (on start)
    (trigger reader.capture)
    (trigger writer.emit)
    (complete done)))
```

FSMGen emits one trigger-batch state in the scheduled parent and pulses both
generated outputs in the same cycle. The report keeps individual entries in
`actor_network.transaction_triggers[]` and adds one
`actor_network.association_schedules[]` entry with a transaction-scoped
association name such as `run_trigger_batch`, kind
`temporary_trigger_batch`, lifetime `task_scoped`, owner transaction,
members, target transactions, generated signals, same-cycle schedule,
no-storage policy, and external handoff boundary. The compatibility
`actor_network.group_schedules[]` entry carries the same timing evidence for
schema-version-1 consumers; if the same trigger set also matches one declared
static group, that compatibility entry may name the group instead.

The first realistic ATL fixture is shipped as
`isf/atl_trigger_batch_pipeline.isf`. It uses only that shipped temporary
trigger-batch surface: three direct static actor instances and one contiguous
transaction-body trigger batch. The fixture proves scheduled parent `.fsm`,
strict schedule JSON, and HDL reachability for the bounded task-scoped
orchestration surface. It is not a claim for peer event
synchronization, endpoint data movement, generated ATL child `.fsm` artifacts,
generated ATL tops, group endpoints, route mux/storage, CDC, payloads,
ready/backpressure, or permanent actor grouping.

The scalar data-route ATL fixture is shipped as
`isf/atl_data_route_pipeline.isf`. It uses the existing drive-body
`(sink source)` movement syntax with two direct static actors:

```lisp
(drive feed_consumer
  (consumer.payload producer.payload))
```

One transaction drive call activates the route for that drive-call cycle. The
scheduled parent exposes `producer_payload` as the generated source handoff
input and `consumer_payload` as the generated sink handoff output. Schedule
JSON reports the route in `actor_network.data_movements[]` with
`route_lifetime: "drive_call_cycle"` and `storage: "none"`. The fixture keeps
`association_schedules[]` and `group_schedules[]` empty because it is a
drive-activated data route, not a trigger-batch association. It does not claim
generated ATL child `.fsm` artifacts, generated ATL tops, route mux/storage,
trigger/data coupling, wider payloads, fan-in/fan-out, CDC, ready/backpressure,
compact movement aliases, or permanent actor grouping.

Two-child data routes have two fail-closed shapes that the current
subset rejects with targeted diagnostics. The first is **repeated
activation**: the parent transaction triggers the source or sink
child more than once across the route segment, so the route's
exactly-one-trigger requirement no longer holds.

```text
(transaction parent
  (on start)
  (trigger producer.run)
  (await producer.done)
  (drive feed_consumer
    (consumer.payload producer.payload))
  (trigger producer.run)             ;; <-- second activation of the source
  (complete done))
```

The validator emits `parent two-child data route requires exactly
one transaction trigger per source and sink child in the current
subset; repeated activation remains deferred`. The deferred lane is
multi-activation routes; until it ships, each source/sink child
must be triggered exactly once within the route segment.

The second is **pre/post route parent work**: the parent does
other transaction-body work either before or after the route
segment in the same transaction, so the route segment is no longer
the only executable parent work.

```text
(transaction parent
  (on start)
  (wait 4)                          ;; <-- pre-route parent work
  (trigger producer.run)
  (await producer.done)
  (drive feed_consumer
    (consumer.payload producer.payload))
  (trigger consumer.run)
  (await consumer.done)
  (complete done))
```

The validator emits `parent two-child data route requires the route
segment to be the only executable parent transaction-body work in
the current subset; pre/post route parent work remains deferred`.
The deferred lane is broader parent-transaction integration; until
it ships, the route segment must be the only executable
transaction body content (the entry guard plus completion are
allowed because they are not transaction-body work).

The scalar pin-ingress ATL fixture is shipped as
`isf/atl_pin_ingress_pipeline.isf`. It uses the same drive-body movement
syntax to move a top-level actor input into an actor in the network:

```lisp
(drive feed_consumer
  (consumer.payload pins.payload))
```

One transaction drive call activates the route for that drive-call cycle. The
scheduled parent preserves `payload` as the existing top-level input source and
exposes `consumer_payload` as the generated actor handoff output. Schedule
JSON reports the route in `actor_network.data_movements[]` with kind
`scalar_pin_to_actor_handoff`, `source: "top_level_pin"`, `sink:
"external_handoff"`, `route_lifetime: "drive_call_cycle"`, and `storage:
"none"`. The fixture keeps `association_schedules[]` and `group_schedules[]`
empty because it is a drive-activated data route, not a trigger-batch
association. It does not claim generated ATL child `.fsm` artifacts, generated
ATL tops, actor-to-pin egress, bidirectional pin movement, route mux/storage,
trigger/data coupling, wider payloads, fan-in/fan-out, CDC, ready/backpressure,
compact movement aliases, or permanent actor grouping.

The scalar pin-egress ATL fixture is shipped as
`isf/atl_pin_egress_pipeline.isf`. It uses the same drive-body movement syntax
to move an actor endpoint value to a top-level actor output:

```lisp
(drive publish_result
  (pins.result producer.payload))
```

One transaction drive call activates the route for that drive-call cycle. The
scheduled parent exposes `producer_payload` as the generated actor source
handoff input and preserves `result` as the existing top-level output sink.

Schedule JSON reports the route in `actor_network.data_movements[]` with kind
`scalar_actor_to_pin_handoff`, `source: "external_handoff"`, `sink:
"top_level_pin"`, `route_lifetime: "drive_call_cycle"`, and `storage: "none"`.

The fixture keeps `association_schedules[]` and `group_schedules[]` empty
because it is a drive-activated data route, not a trigger-batch association.

It does not claim generated ATL child `.fsm` artifacts, generated ATL tops,
bidirectional pin movement, route mux/storage, trigger/data coupling, wider
payloads, fan-in/fan-out, CDC, ready/backpressure, compact movement aliases, or
permanent actor grouping.

The ATL trigger-wait fixture is shipped as
`isf/atl_trigger_wait_pipeline.isf`. It uses one static actor instance and one
parent transaction that emits `(trigger worker.process)`, then waits on
`(await worker.done)`, then completes. The fixture proves parent-level
trigger/event sequencing with generated handoff ports `worker_process_start`
and `worker_done`, one `transaction_triggers[]` entry, one `event_waits[]`
entry, strict schedule JSON parity, scheduled `.fsm` structure with the
default await timeout state, and plain plus strict HDL generation. It does not
claim temporary trigger-batch plus event coupling, generated ATL child `.fsm`
artifacts, generated ATL tops, actor type resolution, HDL child wiring, event
payloads, data movement coupling, fan-in/fan-out, CDC, ready/backpressure,
compact movement aliases, or permanent actor grouping.

The ATL trigger-batch wait fixture is shipped as
`isf/atl_trigger_batch_wait_pipeline.isf`. It couples one same-cycle temporary
trigger batch to one following actor event wait. The parent transaction
triggers reader, filter, and writer in one state, waits on `writer.done`, then
completes. The fixture proves `association_schedules[]` temporary-association
metadata, `group_schedules[]` compatibility metadata, one `event_waits[]`
entry, strict schedule JSON parity, scheduled `.fsm` structure with the
default await timeout state, and plain plus strict HDL generation. It remains
parent-handoff orchestration: it does not claim generated ATL child `.fsm`
artifacts, generated ATL tops, actor type resolution, HDL child wiring,
hidden actor-event fan-in, data movement coupling, CDC, ready/backpressure,
compact movement aliases, or permanent actor grouping.

The ATL trigger-batch multi-event wait fixture is shipped as
`isf/atl_trigger_batch_multi_wait_pipeline.isf`. It uses the same task-scoped
trigger batch, then waits on `reader.done`, `filter.done`, and `writer.done`
as three explicit source-ordered wait states before completion. The fixture
proves three generated event handoff inputs, three `event_waits[]` entries,
strict schedule JSON parity, scheduled `.fsm` structure with the default
await timeout state, and plain plus strict HDL generation. This is sequential
parent-handoff orchestration, not a hidden same-cycle join. Repeated waits,
non-batch waits, interleaved parent work, event payloads, generated child
completion joins, data movement coupling, CDC, ready/backpressure, compact
aliases, and permanent actor grouping remain outside the shipped subset.
When repeated waits target the same triggered actor after a trigger batch,
FSMGen fails before `.fsm` emission and names the missing event re-arm or
per-event generation/lifetime contract.

The shipped ATL source-root safety boundary rejects a second top-level
`(actor ...)` root in the same `.isf` file. That sibling root is not yet a
resolved actor type for `(instance name of ActorType)` or the compact
`(name : ActorType)` alias. One actor root plus `(library ...)` roots remains
accepted, and the shipped library-qualified ATL subsets now emit generated
child `.fsm` artifacts and generated ATL tops.

Sibling-root child type resolution remains deferred.

The selected future source contract for ATL actor type resolution is explicit
library qualification (the example assumes a sibling `common.packet`
library on the search path; ATL actor type resolution is still on the
backlog so this fixture documents the future shape):

```text
(actor packet_system
  (clock clk)
  (interface (input start) (output done))
  (imports
    (library common.packet as pkt_lib))
  (instance reader of pkt_lib.packet_reader)
  (transaction run
    (on start)
    (trigger reader.capture)
    (await reader.done)
    (complete done)))
```

The alias before the dot must come from the enclosing actor's explicit library
imports, and the name after the dot must be an actor export from that library.

The compact `(reader : pkt_lib.packet_reader)` spelling shares the same
library-qualified type-resolution rules. Unqualified
`(instance name of ActorType)` and compact `(name : ActorType)` remain
metadata-only external intent for now, not an implicit search through sibling
actor roots or files.

Existing `(use alias.actor as instance ...)` remains the separate reusable
library generated-top path with explicit bindings. The targeted fail-closed
reservation for this qualified ATL syntax is shipped: missing imports,
non-explicit import aliases, unknown aliases, and unknown actor exports still
fail before scheduled `.fsm` emission with ATL-specific diagnostics.

Resolved qualified entries add `type_resolution`, `library`, `alias`, `export`,
`module`, and `scheduled_fsm`, with
`type_resolution: "library_actor_export"` and deterministic child
names `<parent_actor>__<instance>` / `<parent_actor>__<instance>.fsm` under
`actor_network.instances[]`. Lowering now emits those resolved child `.fsm`
files, and the first generated ATL top is shipped for the one-resolved-child
trigger/event subset. Broader generated ATL tops, interface binding inference,
data-route child wiring, and event/trigger/data handoff wiring outside that
selected pair remain later leaves.

The shipped resolved-child fixture is
`isf/atl_resolved_child_pipeline.isf`. It uses one same-source library actor
export, one resolved `(instance worker of pkt_lib.packet_worker)`, one parent
trigger handoff, and one parent event wait. Lowering emits exactly
`atl_resolved_child_pipeline.fsm`,
`atl_resolved_child_pipeline__worker.fsm`, and
`atl_resolved_child_pipeline_top.fsm`. The generated top wires public pins to
the parent, parent `worker_process_start` to child `process_start`, and child
`done` to parent `worker_done`, then reports the top under
`actor_network.generated_tops[]`.

HDL promotion for that same resolved-child shape is shipped. The source and
report schema stay unchanged; focused coverage proves plain and strict CLI
SystemVerilog generation contains the generated top, scheduled parent,
resolved child, and selected internal trigger/event links. Multi-child ATL
tops, data-route child wiring, CDC, payloads, ready/backpressure, route
mux/storage, recursive actor networks, and permanent actor grouping remain
unavailable.

### Generated-Child Top Data Routes

The first generated-child data route is also shipped for one scalar top-level
input-pin route into one resolved child through that generated top.

The source shape is a named drive body with `(worker.payload pins.payload)`,
activated by the same parent transaction that triggers `worker.process` and
awaits `worker.done`.

The fixture `isf/atl_resolved_child_pin_ingress_pipeline.isf` emits parent,
child, and top `.fsm` artifacts; the generated top wires top `payload` to the
parent, parent `worker_payload` to child input `payload`, parent
`worker_process_start` to child `process_start`, and child `done` to parent
`worker_done`.

The child `.fsm` includes generated `+interface` role metadata for the
selected child input so the HDL backend preserves `payload` as a child module
port.

The exact-width vector form of that one-child pin-ingress route is shipped as
`isf/atl_resolved_child_pin_ingress_vector_pipeline.isf`.

It uses the same `(sink source)` movement surface:

```lisp
(drive feed_worker
  (worker.payload pins.payload))
```

The top-level actor declares `payload` as an 8-bit input, and the resolved
child declares its `payload` input at the same width. Lowering emits the
parent, child, and top `.fsm` artifacts, keeps parent handoff
`worker_payload` at width 8, preserves the child `payload` input as an 8-bit
module port, and wires public top `payload` through the parent into child
`payload`.

Schedule JSON keeps the existing public route entry shape and reports
`kind: "vector_pin_to_actor_handoff"`, `width: 8`, and
`width_source: "top_level_input_pin_resolved_child_endpoint_exact_width"`.

If the top-level input width and child input width differ, lowering fails
before scheduled `.fsm` emission. FSMGen does not infer width adaptation,
packing, truncation, extension, slicing, route mux/storage,
fan-in/fan-out, ready/backpressure, or a payload protocol for the route.

The exact-width vector multi-route form of that same one-child pin-ingress
path is shipped as
`isf/atl_resolved_child_pin_ingress_vector_multi_pipeline.isf`.

It keeps the same `(sink source)` movement surface and uses adjacent route
drive calls before the child trigger:

```lisp
(drive feed_payload
  (worker.payload pins.payload))

(drive feed_sideband
  (worker.sideband pins.sideband))
```

The fixture proves route-local widths. Top `payload` and child `payload` are
8 bits; top `sideband` and child `sideband` are 4 bits. Lowering emits two
drive-call states, two generated parent-to-child handoff outputs, child
`+interface` roles for both vector inputs, and generated-top wiring at each
route's exact width.

Schedule JSON reports both routes as `vector_pin_to_actor_handoff` entries
with `width_source: "top_level_input_pin_resolved_child_endpoint_exact_width"`.

This vector multi-route subset is still not a route fabric. All accepted
routes must target the same resolved child, live in the same parent
transaction, use unique top-level input pins and child input endpoints, and be
activated by adjacent argument-free drive calls before the child trigger and
event wait. Broader mixed scalar/vector route sets outside the bounded
pin-ingress subset below, width adaptation, route mux/storage, fan-in/fan-out,
ready/backpressure, and payload protocols remain deferred.

The mixed scalar/vector form of that same one-child pin-ingress path is shipped
as `isf/atl_resolved_child_pin_ingress_mixed_pipeline.isf`.

It keeps the same `(sink source)` movement surface and uses adjacent route
drive calls before the child trigger:

```lisp
(drive feed_payload
  (worker.payload pins.payload))

(drive feed_valid
  (worker.valid pins.valid))
```

The fixture proves one exact-width vector route and one scalar route in the
same route set. Top `payload` and child `payload` are 8 bits. Top `valid` and
child `valid` are one-bit scalar pins. Lowering emits two drive-call states,
two generated parent-to-child handoff outputs, child `+interface` roles for
both inputs, and generated-top wiring at each route's own width.

Schedule JSON reports the payload route as `vector_pin_to_actor_handoff` with
`width_source: "top_level_input_pin_resolved_child_endpoint_exact_width"` and
the valid route as `scalar_pin_to_actor_handoff` with
`width_source: "top_level_pin_scalar_one_bit"`.

This mixed subset is still not a route fabric. All accepted routes must target
the same resolved child, live in the same parent transaction, use unique
top-level input pins and child input endpoints, and be activated by adjacent
argument-free drive calls before the child trigger and event wait. Width
adaptation, route mux/storage, fan-in/fan-out, ready/backpressure, and payload
protocols remain deferred.

The bounded multi-route extension of that same one-child pin-ingress shape is
also shipped as `isf/atl_resolved_child_pin_ingress_multi_pipeline.isf`.

It still uses the existing `(sink source)` drive-body movement surface. The
parent has two route drives:

```lisp
(drive feed_payload
  (worker.payload pins.payload))

(drive feed_sideband
  (worker.sideband pins.sideband))
```

The parent transaction calls both route drives in adjacent transaction-body
clauses, triggers `worker.process`, waits on `worker.done`, and completes.

Lowering emits two drive-call states, two generated drive request signals, two
parent-to-child handoff outputs (`worker_payload`, `worker_sideband`), and
child `+interface` roles for both routed inputs. The generated top wires top
`payload` and top `sideband` into the scheduled parent, then wires the parent
handoffs to child `payload` and `sideband`.

Schedule JSON reports each scalar path as its own
`actor_network.data_movements[]` entry with
`kind: "scalar_pin_to_actor_handoff"`. The generated-top discovery still uses
`actor_network.generated_tops[]`; the internal generated-top data-link list
remains private.

This extension is not a route fabric. All accepted pin-ingress routes must
target the same resolved child, live in the same parent transaction, use one
scalar `(child.endpoint pins.input_pin)` pair per drive body, use unique
top-level input pins and unique child input endpoints, and be activated by
adjacent argument-free top-level drive calls before the child trigger and event
wait.

These one-child pin-ingress routes do not include actor-to-actor
generated-child routing, multi-child data wiring, broader mixed
scalar/vector route sets outside the bounded same-child pin-ingress subset,
width adaptation, route mux/storage, fan-in/fan-out, CDC/reset remapping,
ready/backpressure, or payload protocols.

The inverse generated-child data route is also shipped for one scalar
resolved-child output route to one top-level output pin through that
generated top.

The source shape is a named drive body with `(pins.result worker.payload)`,
activated after the parent transaction triggers `worker.process` and awaits
`worker.done`.

The fixture `isf/atl_resolved_child_pin_egress_pipeline.isf` emits parent,
child, and top `.fsm` artifacts; the generated top wires child `payload` to
parent `worker_payload`, parent `result` to top `result`, parent
`worker_process_start` to child `process_start`, and child `done` to parent
`worker_done`.

The child `.fsm` includes generated `+interface` role metadata for the
selected child output so the HDL backend preserves `payload` as a child
module port.

This one-child pin-egress route does not include actor-to-actor
generated-child routing, multi-child data wiring, route mux/storage,
CDC/reset remapping, ready/backpressure, or payload protocols.

The exact-width vector form of that one-child pin-egress route is shipped as
`isf/atl_resolved_child_pin_egress_vector_pipeline.isf`.

It uses the same `(sink source)` movement surface:

```lisp
(drive publish_result
  (pins.result worker.payload))
```

The top-level actor declares `result` as an 8-bit output, and the resolved
child declares its `payload` output at the same width. Lowering emits the
parent, child, and top `.fsm` artifacts, keeps parent handoff `worker_payload`
at width 8, preserves the child `payload` output as an 8-bit module port, and
wires child `payload` through the parent to public top `result`.

Schedule JSON keeps the existing public route entry shape and reports
`kind: "vector_actor_to_pin_handoff"`, `width: 8`, and
`width_source: "top_level_output_pin_resolved_child_endpoint_exact_width"`.

If the child output width and top-level output width differ, lowering fails
before scheduled `.fsm` emission. FSMGen does not infer width adaptation,
packing, truncation, extension, slicing, route mux/storage,
fan-in/fan-out, ready/backpressure, or a payload protocol for the route.

The exact-width vector multi-route form of that same one-child pin-egress path
is shipped as `isf/atl_resolved_child_pin_egress_vector_multi_pipeline.isf`.

It routes both child outputs to top-level output pins after the child event
wait:

```lisp
(drive publish_result
  (pins.result worker.payload))
(drive publish_status
  (pins.status worker.status))
```

In that fixture, the result route is 8 bits and the status route is 4 bits.
Each route reports `kind: "vector_actor_to_pin_handoff"` with
`width_source: "top_level_output_pin_resolved_child_endpoint_exact_width"`.
The route set keeps the same one-child, same-parent-transaction,
unique-child-output, unique-top-output, contiguous post-event drive-call rules
as the scalar pin-egress multi-route subset. A route-local child-output to
top-output width mismatch fails closed before scheduled `.fsm` emission.

This vector multi-route subset is still not a route fabric. Broader mixed
scalar/vector route sets outside the bounded same-child pin-egress subset
below, width adaptation, storage, muxing, fan-in/fan-out, CDC/reset remapping,
ready/backpressure, and payload protocols remain deferred.

The mixed scalar/vector form of that same one-child pin-egress path is shipped
as `isf/atl_resolved_child_pin_egress_mixed_pipeline.isf`.

It keeps the same `(sink source)` movement surface and uses adjacent route
drive calls after the child event wait:

```lisp
(drive publish_result
  (pins.result worker.payload))

(drive publish_valid
  (pins.valid worker.valid))
```

The fixture proves one exact-width vector route and one scalar route in the
same route set. Child `payload` and top `result` are 8 bits. Child `valid` and
top `valid` are one-bit scalar pins. Lowering emits two post-event drive-call
states, two generated child-to-parent handoff inputs, child `+interface` roles
for both outputs, and generated-top wiring at each route's own width.

Schedule JSON reports the result route as `vector_actor_to_pin_handoff` with
`width_source: "top_level_output_pin_resolved_child_endpoint_exact_width"` and
the valid route as `scalar_actor_to_pin_handoff` with
`width_source: "top_level_output_pin_scalar_one_bit"`.

This mixed subset is still not a route fabric. All accepted routes must source
the same resolved child, live in the same parent transaction, use unique child
output endpoints and top-level output pins, and be activated by adjacent
argument-free drive calls after the child event wait. Width adaptation,
route mux/storage, fan-in/fan-out, CDC/reset remapping, ready/backpressure,
and payload protocols remain deferred.

The bounded multi-route extension of that one-child pin-egress path is shipped
as `isf/atl_resolved_child_pin_egress_multi_pipeline.isf`.

It routes `(pins.result worker.payload)` and
`(pins.status worker.status)` with adjacent argument-free drive calls after the
child event wait. The generated top wires both child output pins through
separate parent source handoffs to separate top-level output pins, and the
public report keeps both routes in `actor_network.data_movements[]` with
`kind: "scalar_actor_to_pin_handoff"`.

This is still a one-child one-to-one scalar route set. It does not include
width adaptation, fan-in/fan-out, route mux/storage, CDC/reset remapping,
ready/backpressure, or payload protocols.

The selected generated-child actor-to-actor data-route shape across two
resolved children reuses the existing `(sink source)` drive-body movement
surface and is shipped only for the two-child same-source/same-sink scalar or
exact-width vector data routes described below. Malformed or mismatched-width
actor-to-actor route shapes still fail closed before FSMGen infers remapping,
storage, muxing, fan-in/fan-out, payload adaptation, or backpressure behavior.

The first control-only two-child generated top is now shipped.

The fixture `isf/atl_two_child_pipeline.isf` declares resolved `reader` and
`writer` children, triggers `reader.capture`, waits on `reader.done`,
triggers `writer.emit`, waits on `writer.done`, and completes.

Lowering emits parent, reader, writer, and generated top `.fsm` artifacts.

The generated top instantiates all three modules, exposes only the parent
public pins plus clock/reset, wires `reader_capture_start` to
`reader.capture_start`, `reader.done` to `reader_done`, `writer_emit_start`
to `writer.emit_start`, and `writer.done` to `writer_done`.

Schedule JSON keeps the same actor-network families and uses
`actor_network.generated_tops[].children[]` for the per-child generated-top
wiring records.

The first resolved-child trigger-batch generated top is also shipped as
`isf/atl_two_child_trigger_batch_pipeline.isf`.

It keeps the same resolved `reader` and `writer` child modules, but the
parent transaction emits contiguous `(trigger reader.capture)` and `(trigger
writer.emit)` clauses before waiting on `reader.done` and then `writer.done`.
Lowering emits parent, reader, writer, and generated top `.fsm` artifacts.
The parent uses one `run_atl_trigger_batch_1` state that pulses both
`reader_capture_start` and `writer_emit_start` in the same cycle, then
preserves the authored waits as source-ordered sequential wait states.

Schedule JSON records the same individual `transaction_triggers[]` and
`event_waits[]` entries as parent-handoff trigger-batch sources, keeps the
task-scoped temporary association in `association_schedules[]`, keeps the
schema-version-1 compatibility evidence in `group_schedules[]`, and advertises
the generated top with `kind:
"resolved_children_trigger_batch_event_sequence"` under
`actor_network.generated_tops[]`. Static group declarations, data movement
coupled to the trigger batch, repeated child activations or waits,
non-source-ordered waits, nested waits/triggers, CDC, payload protocols,
ready/backpressure, route mux/storage, recursive actor networks, and permanent
actor grouping remain outside this generated-top subset.

The first one-bit generated-child actor-to-actor route through that two-child
top is also shipped as `isf/atl_two_child_data_pipeline.isf`.

It reuses a named drive body with `(writer.payload reader.payload)` and calls
it after `reader.done` and before `writer.emit`. The scheduled parent exposes
`reader_payload` as the source handoff input and `writer_payload` as the sink
handoff output, drives `writer_payload` from `reader_payload` only for the
`forward_payload` drive-call cycle, and the generated top wires
`reader.payload` to parent `reader_payload` plus parent `writer_payload` to
`writer.payload`. Schedule JSON records the route in
`actor_network.data_movements[]` and the generated top in
`actor_network.generated_tops[]` with `children[]`. Fan-in/fan-out, broader
route data wiring, route mux/storage, CDC/reset remapping, ready/backpressure,
payload protocols beyond exact-width handoff wiring, repeated triggers,
trigger-batch plus data movement coupling, groups, recursive actor networks,
and permanent actor grouping remain unavailable.

The exact-width vector extension of the same route is shipped as
`isf/atl_two_child_vector_data_pipeline.isf`.

It keeps the same `(writer.payload reader.payload)` drive-body pair and the
same trigger/await/drive/trigger/await transaction order. The reader
`payload` output and writer `payload` input are both declared with width 8,
so FSMGen emits 8-bit parent handoff ports `reader_payload` and
`writer_payload`, preserves the 8-bit child ports as generated `+interface`
roles, wires both 8-bit generated-top links, and emits vector HDL links.
Schedule JSON records this route with `kind: "vector_actor_handoff"`,
`width: 8`, and
`width_source: "resolved_child_endpoint_exact_width"`.

The bounded multi-route extension of that same shape is now shipped as
`isf/atl_two_child_multi_data_pipeline.isf`.

It still uses the same `(sink source)` drive-body movement surface. The parent
has two route drives:

```lisp
(drive forward_payload
  (writer.payload reader.payload))

(drive forward_sideband
  (writer.sideband reader.sideband))
```

The parent transaction triggers `reader.capture`, waits on `reader.done`, calls
both route drives in adjacent transaction-body clauses, triggers `writer.emit`,
waits on `writer.done`, and completes.

Lowering emits two drive-call states, two generated drive request signals, two
reader-to-parent handoff inputs (`reader_payload`, `reader_sideband`), and two
parent-to-writer handoff outputs (`writer_payload`, `writer_sideband`). The
generated top wires `reader.payload` and `reader.sideband` into the parent
handoffs, and wires the parent handoffs to `writer.payload` and
`writer.sideband`.

Schedule JSON reports each path as its own
`actor_network.data_movements[]` entry. One-bit paths use
`kind: "scalar_actor_handoff"` and exact-width vector paths use
`kind: "vector_actor_handoff"`. The generated-top discovery still uses
`actor_network.generated_tops[]` with `children[]`; the internal generated-top
data-link list remains private.

This extension is not general muxing. All accepted routes must share the same
source child, the same sink child, the same parent transaction, one direct
endpoint pair with matching source/sink endpoint widths per drive body, and
one top-level drive call per route. The route segment must stay contiguous:
source trigger, source event wait, all route drive calls, sink trigger, and
sink event wait.

The shipped hardening around this route surface locks the nearby fail-closed
rules: every source endpoint must be an output on the source child, every sink
endpoint must be an input on the sink child, and each route drive body may
contribute exactly one endpoint pair activated by exactly one top-level drive
call.

The shipped width hardening accepts exact-width generated-child
actor-to-actor routes when the resolved source child output and sink child
input declare the same positive width. Width mismatches fail closed until a
later payload-width protocol defines packing, truncation, extension, slicing,
storage, or muxing behavior.

The shipped clock/reset hardening keeps the same route in one parent
clock/reset policy. Source or sink child clock/reset mismatches fail closed
until a later CDC or reset-remap contract is selected; the generated top does
not insert async crossing logic, system-port remapping, route storage, muxing,
or backpressure.

The shipped self-route hardening keeps the route between two distinct
resolved children. Same-child source/sink route pairs fail closed until a
later contract selects self-route, loopback, child-internal bypass, storage,
muxing, fan-in/fan-out, or payload behavior.

The shipped repeated-trigger hardening keeps the route sequence to one
source-child trigger and one sink-child trigger. Extra route-child triggers
fail closed until a later contract selects repeated activation, restart,
pending-request merging, trigger fan-in/fan-out, or multi-activation
scheduling.

The shipped repeated-wait hardening keeps the same route sequence to one
source-child event wait and one sink-child event wait. Extra route-child
waits fail closed until a later contract selects event fan-in/fan-out,
repeated wait sequencing, route-level wait storage, muxing, backpressure, or
payload behavior.

The shipped same-parent-transaction hardening keeps that same route inside
one parent transaction. Route clauses split across multiple parent
transactions stay fail-closed until a later contract selects route
continuation, pending handoff storage, transaction rendezvous,
cross-transaction scheduling, muxing, backpressure, or payload behavior.

The shipped sink-trigger ordering hardening keeps the data drive call before
the sink child trigger. Sink-before-drive route sequences stay fail-closed
until a later contract selects speculative sink activation, delayed payload
delivery, route storage, muxing, backpressure, or payload behavior.

The shipped sink-event-wait ordering hardening keeps the sink child event
wait after the sink child trigger. Sink-wait-before-trigger route sequences
stay fail-closed until a later contract selects pre-trigger acknowledgement,
sticky event sampling, event replay, route storage, muxing, backpressure, or
payload behavior.

The shipped source-event-wait ordering hardening keeps the source child
event wait after the source child trigger. Source-wait-before-trigger route
sequences stay fail-closed until a later contract selects pre-trigger
acknowledgement, sticky event sampling, event replay, route storage, muxing,
backpressure, or payload behavior.

The shipped route-contiguity hardening keeps that route as one contiguous
transaction-body segment. Interleaved parent clauses between the source
trigger, source event wait, data drive call, sink trigger, and sink event
wait stay fail-closed until a later contract selects interleaved parent work,
local side effects, pre/post route sampling, route continuation, storage,
muxing, backpressure, or payload behavior.

The shipped route-isolation hardening keeps that route segment as the only
executable parent transaction-body work between the transaction start
condition and completion. Parent-local clauses before the source trigger or
after the sink event wait stay fail-closed until a later contract selects
pre-route setup, post-route sampling, local side effects, cleanup work, route
continuation, storage, muxing, backpressure, or payload behavior.

The shipped route-boundary cardinality hardening keeps that isolated route
bounded by exactly one simple start condition and one simple completion
pulse. Extra start or completion boundaries stay fail-closed until a later
contract selects activation fan-in, completion fan-out, start-condition
arbitration, setup/cleanup, continuation, storage, muxing, backpressure, or
payload behavior.

The shipped boundary-simplicity hardening keeps those boundaries body-free.

Activation-body samples in `(on ...)` and extra payload operands in
`(complete ...)` stay fail-closed until a later contract selects
activation-body sampling, completion payload/fan-out, setup/cleanup,
continuation, storage, muxing, backpressure, or payload behavior.

The shipped boundary-role hardening keeps those route boundaries tied to
parent interface direction. The start boundary remains a scalar top-level
input and the completion boundary remains a scalar top-level output;
output-as-start, input-as-completion, undeclared, and wider boundary pins
fail closed until a later contract selects interface remapping, activation
fan-in, completion fan-out, boundary expressions, storage, muxing,
backpressure, or payload behavior.

The shipped generated-handoff collision hardening keeps generated parent
handoff names exclusive. Parent-declared interface or storage signals that
collide with the selected route's trigger, event, data, or named-drive
request handoffs fail closed before generated-top wiring can silently reuse
or suppress those ports. This does not select handoff remapping, route
muxing, route storage, fan-in/fan-out, ready/backpressure, or payload
behavior.

The shipped lowerer defensive backstop protects the same generated-handoff
names after parsing. Normal `.isf` source still fails in the parser, but
programmatic or mutated actor metadata also fails closed in lowering before
generated-top wiring can reuse, suppress, or shadow those handoffs. This does
not add syntax, remapping, muxing, storage, ready/backpressure,
fan-in/fan-out, or payload behavior.

#### Generated-Child Route Terms

The current generated-child actor-to-actor route set is intentionally small.
Each route means one child output reaches one child input through fixed
generated parent handoffs for exactly that route's named drive-call cycle.
The route width is one for scalar endpoints or the exact matching child
endpoint width for vector endpoints.

This terminology is part of the user-facing contract and is kept in this
dedicated section so route support, explicit non-support, and diagnostic
ownership stay reviewable in the book.

##### Route Lifetime And Value Boundary

The shipped route lifetime is one named drive-call cycle per route. In
`atl_two_child_data_pipeline`, that cycle is the parent transaction's
`(drive forward_payload)` clause between `await reader.done` and
`trigger writer.emit`. In `atl_two_child_multi_data_pipeline`, the payload and
sideband paths each have their own adjacent drive-call cycle in that same route
segment.

The shipped data value for each route is exactly the resolved child endpoint
width. The generated top presents the payload value as `reader.payload` to
parent handoff `reader_payload`, then parent handoff `writer_payload` to
`writer.payload`. The multi-route fixture adds the same pattern for
`reader.sideband`, `reader_sideband`, `writer_sideband`, and
`writer.sideband`. The vector fixture uses the same path at width 8. FSMGen
transfers each value during its named drive-call cycle and does not define a
multi-cycle route lifetime.

Structured payloads, replayed payloads, delayed delivery, or width adaptation
remain deferred until a later task tree selects and verifies a wider protocol.

Parameterized route drive definitions and drive-call actual arguments are
also outside the shipped ATL route families. `(drive (forward_payload value)
...)` and `(drive forward_payload value)` fail closed in the generated-child
actor-to-actor, pin-ingress, and pin-egress route subsets before drive actual
binding, expression movement, route mux/storage, or payload protocols can be
inferred.

Route endpoint expressions are also outside this route. The source half of
the drive-body pair must be the direct endpoint `reader.payload`; a source
expression such as `(+ reader.payload 1)` fails closed before FSMGen infers
expression movement, value transformation, width conversion, storage, or a
payload protocol.

The sink half of the drive-body pair must likewise be the direct endpoint
`writer.payload`. A sink expression such as `(+ writer.payload 1)` fails
closed before FSMGen infers expression destinations, route-side transforms,
width conversion, storage, or a payload protocol.

That ATL sink-expression diagnostic is source-order independent for
endpoint-looking route sinks. If a drive body appears before the corresponding
`(instance ...)` clauses, FSMGen defers that ATL-looking sink expression until
the actor instance set is known, then reports the same sink-expression
diagnostic. Ordinary malformed local drive targets such as `((out) 1)` keep
the generic drive-body scalar-head diagnostic.

The source-expression diagnostic is source-order independent too. If a drive
body appears before the corresponding `(instance ...)` clauses, FSMGen defers
that ATL-looking source expression until the actor instance set is known, then
reports the same source-expression diagnostic. Expression movement itself
remains outside the shipped contract.

The accepted actor-to-actor route is source-order independent too. The named
`forward_payload` drive may appear before or after the `reader` and `writer`
instance declarations; after the full actor body is parsed, FSMGen resolves
the same `reader.payload` to `writer.payload` route, emits the same generated
top handoffs, and records the same `actor_network.data_movements[]` metadata.

##### Generated Handoffs

Generated handoffs are the parent-visible signals that FSMGen creates for
the route.

In the shipped fixture, `reader_payload` carries the source child payload
into the parent, `writer_payload` carries the parent value out to the sink
child, `reader_capture_start` and `writer_emit_start` are one-cycle
child-start pulses, `reader_done` and `writer_done` are child completion
event inputs, and `forward_payload_start` is the named-drive request signal.

These generated names are deterministic. They are part of the current
support boundary and can be inspected in the scheduled `.fsm`, generated top
artifact, and schedule JSON route evidence.

##### Handoff Remapping

Handoff remapping would let the author choose different generated parent
handoff names or map the generated handoffs onto existing parent interface
or storage signals.

That is not shipped for this route. The current contract uses deterministic
generated names and rejects collisions with authored parent interface or
actor-owned storage names before generated-top wiring.

Downstream producers should not rely on aliasing, overriding, suppressing,
or reusing generated handoff names until an explicit remapping contract is
published.

##### Diagnostic Ownership

Parser-owned diagnostics reject normal `.isf` source that declares parent
interface or storage names matching the generated handoffs. This is the
normal downstream failure surface for authored source.

The lowerer repeats the safety check for scheduler-facing metadata and also
rejects already registered generated handoff duplicates before generated-top
wiring. That lowerer check is a defensive backstop for malformed or mutated
metadata, not a new author-facing feature.

##### Route Muxing And Route Storage

Route muxing would let several possible sources feed the same sink endpoint,
with a selector deciding which source is active in a given cycle.

Route storage would hold route data across cycles before the sink consumes
it.

The current route set has neither. It has one source child, one sink child,
one named drive call per route, no route-local storage, and no route-local
selector.

##### Fan-In And Fan-Out

Fan-in would let multiple triggers, events, or data sources converge onto one
generated handoff or child endpoint.

Fan-out would let one trigger, event, or data source drive multiple generated
handoffs or child endpoints.

The current route set has one source child, one sink child, one trigger and
event per child, and one or more data movements only when those movements
share the same source/sink child pair, have matching endpoint widths per
route, and occupy the same contiguous route segment.
Multi-source, multi-sink, multi-event, and multi-trigger route structures
remain fail-closed or deferred according to the surrounding diagnostics.

##### Ready/Backpressure

Ready/backpressure would let the sink child or generated top say "not ready"
so the parent stalls, retries, buffers, or replays the transfer.

The current route has no ready signal and no retry contract. The source
event wait, drive-call cycle, sink trigger, and sink event wait are fixed in
order.

Ready/valid-style route transfer, stall insertion, retry, buffering, and
replay are not part of this route.

##### Payload Protocols

Payload protocols would define data movement richer than the current exact
child-endpoint drive-call-cycle value, such as structured payloads,
valid/ready payload transfer, width adaptation, or multi-cycle packet
movement.

The current route preserves matching scalar or vector child endpoint widths
only. FSMGen does not truncate, extend, pack, unpack, buffer, or handshake
route payloads in this subset.

The current actor-event wait behavior is a narrow parent-handoff subset. One
top-level transaction-body `(await actor.event)` may target a declared direct
static actor instance. The wait may stand alone for a single static actor, or
follow one selected same-cycle temporary trigger batch. FSMGen lowers it to a
generated one-bit parent event input named `actor_event`; for example,
`reader.done` becomes `reader_done`. The scheduled parent `.fsm` exposes and
waits on that input, and schedule JSON records the wait under
`actor_network.event_waits[]`.

The event producer is external in this subset. FSMGen still does not resolve
the actor type, emit an ATL child `.fsm`, generate an ATL top, trigger actor
transactions, carry event payloads, or support fan-in/fan-out, unselected
multi-wait forms, repeated waits to one triggered actor, nested waits,
cross-clock actor events, or concurrent group events. Source-authored
`group.name` event waits fail closed with the ATL group-endpoint diagnostic.
Repeated trigger-batch waits fail closed with the event re-arm/lifetime
diagnostic.
`await_all` and `await_any` remain generated-child completion sync forms in
this surface; source that tries to use them as actor-event all-of/any-of joins
with operands such as `reader.done` and `writer.done` fails closed with the
ATL event-join diagnostic.

Unqualified local forms keep their existing meaning: `(await signal)` waits
on a local transaction signal, and rule-level `(trigger transaction)` triggers
a local transaction. Dotted enum-looking names that do not name a static
actor instance or static group keep their prior diagnostics.

The current qualified trigger behavior is the matching parent-handoff subset.

A top-level transaction-body `(trigger actor.transaction)` may target a
static actor instance either as a single handoff or as part of the temporary
trigger-batch subset. FSMGen lowers it to a generated one-cycle parent output
named `actor_transaction_start`; for example,
`reader.capture` becomes `reader_capture_start`. The scheduled parent `.fsm`
exposes and pulses that output at the trigger point, and schedule JSON records
the trigger under `actor_network.transaction_triggers[]`.

The trigger sink is external in this subset. FSMGen still does not resolve
the actor type, emit an ATL child `.fsm`, generate an ATL top, connect the
start pulse to an actor instance, add ready/backpressure, carry trigger
payloads, or support rule-level qualified triggers, nested triggers, repeated
triggers to the same actor instance, generated handoff signal conflicts,
fan-in/fan-out, cross-clock actor triggers, or broader concurrent group
behavior. Source-authored `group.name` triggers, including rule-action group
triggers, fail closed with the ATL group-endpoint diagnostic.

Until those later leaves ship, `actor_network` remains discovery metadata
plus selected event-wait, transaction-trigger, and exact trigger-batch
handoff metadata. It does not imply generated ATL child artifacts, generated
ATL top names, route muxes,
internal handoff storage, or HDL event wiring.

## Schedule Report Projection

The generated-composition schedule-report projection is a live bounded
downstream-discovery field. Successful reports keep ordinary transaction,
storage, and DT summaries parent-scoped, while the top-level
`generated_composition` field reports generated-top structure. For actors with
no generated composition top, that field is `null`. For generated-child
actors, it is an object with only review-facing composition facts:

```json
{
  "kind": "spawn_generated_top",
  "top_module": "spawn_parent_top",
  "top_fsm": "spawn_parent_top.fsm",
  "parent": {
    "module": "spawn_parent",
    "scheduled_fsm": "spawn_parent.fsm"
  },
  "children": [
    {
      "transaction": "child_worker",
      "module": "child_worker",
      "scheduled_fsm": "child_worker.fsm",
      "parameters": [
        { "name": "WIDTH", "default": "8" }
      ]
    }
  ],
  "instances": [
    {
      "instance": "w0",
      "child": "child_worker",
      "activation_kind": "spawn",
      "start": { "parent_port": "w0_start", "child_port": "start" },
      "done": { "child_port": "done", "parent_port": "w0_done" },
      "parameter_bindings": [
        { "name": "WIDTH", "source": "override", "value": "16" }
      ],
      "drive_handoffs": [
        {
          "drive": "rdata",
          "request": {
            "child_port": "rdata_start",
            "parent_port": "w0_rdata_start"
          },
          "payloads": [
            {
              "parameter": "val",
              "child_port": "rdata_val",
              "parent_port": "w0_rdata_val",
              "width": 32
            }
          ]
        }
      ]
    }
  ]
}
```

The projection is intentionally not a raw `LoweringIR` dump and not a parsed
`?wiring` dump. It reports the current bounded names that downstream
consumers can use to discover the generated top, parent, child modules,
instance identity, activation kind, start and done handoff, named-drive
handoff, and per-instance parameter binding. The `kind` value is
`spawn_generated_top` for spawn-only generated tops and
`activation_generated_top` when another activation kind such as blocking `do`
participates. This is live public discovery metadata, not a frozen schema for
all future ISF releases.

Generated handoff names are reserved by the generated composition boundary. If
an actor interface already declares a would-be generated start/done handoff,
port-binding handoff, named-drive request handoff, or named-drive payload
handoff, lowering fails before emitting the generated top. The diagnostic names
the transaction, generated instance, and the handoff role; named-drive
diagnostics also name the drive and payload parameter when relevant.

## Complete Example

```lisp
(actor bus_controller
  (clock clk)
  (reset (rst_n async active_low))

  (interface
    (input  start)
    (output done)
    (output rdata (width 32)))

  ;; Worker transaction
  (transaction read_word
    (sample rdata as val)
    (drive work (rdata val))
    (complete done))

  ;; Parent: three parallel reads
  (transaction scatter_read
    (on start)
    (spawn read_word as r0)
    (spawn read_word as r1)
    (spawn read_word as r2)
    (await_all done)
    (complete done)))
```
