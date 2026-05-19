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
compatible aggregate overrides. Actor-local constants may be used as scalar
override values, or as scalar leaves inside aggregate/list override values;
they resolve to literal values before generated-top emission.
A generated child `.fsm` emits the child transaction defaults in `+params`;
parameter declarations on non-generated transactions fail closed; the parent
lowerer IR preserves per-instance override lists, and the generated top applies
those overrides through `?fsmc` `(params ...)` blocks.

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
parameter overrides are instance-local, and bindings are explicit:

```lisp
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
entries through `shipped_library_definitions`. Parameter-driven interface or
storage elaboration, memory-array backend emission, standalone transaction or
drive exports, and nested library imports remain future work.

## Static Actor-Network Metadata

The first Actor Transfer Level (`ATL`) implementation slice is intentionally
small: a top-level actor may declare one static actor instance, and FSMGen
preserves that declaration in the parser shell and schedule report.

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

This is not generated-child composition yet. FSMGen does not resolve
`packet_reader`, emit a child `.fsm`, build an ATL top, or wire `reader`
transactions/events to child artifacts in this slice. Broader multiple
instances outside the shipped scalar handoff and group metadata subsets,
broader group scheduling outside the exact trigger-batch subset, pin
movement, event fan-in/fan-out, trigger fan-in/fan-out, and generated ATL
wiring remain backlog under the actor-network task tree.

The broader ATL v0 contract is selected for later slices. The source root
stays `(actor ...)`, and future ATL declarations remain direct actor-body
clauses rather than a `(network ...)` section. Actor-to-actor and scalar
top-level pin movement reuse the existing drive-body pair shape in
`(sink source)` order plus ordinary drive-call timing points. `connect`,
`transfer`, and `move` are not part of ATL v0 movement syntax. The first
endpoint-movement implementation sequence first shipped fail-closed
reservation for unsupported endpoint drive-body pairs, then shipped the first
generated scalar actor-to-actor handoff subset. The accepted subset is
intentionally narrow: exactly two direct static actor instances, one named
drive body with one `(sink_actor.endpoint source_actor.endpoint)` scalar
pair, and one top-level transaction drive call. The generated parent `.fsm`
exposes a one-bit external source input named
`source_actor_source_endpoint` and a one-bit external sink output named
`sink_actor_sink_endpoint`; the route lasts for the drive-call cycle and
does not imply storage, a mux, generated child `.fsm` artifacts, an ATL top,
HDL child wiring, pin movement in that actor-to-actor route, fan-in/fan-out,
groups, CDC, or trigger/await coupling.

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

ATL orchestration spellings are `(do actor.transaction)`,
`(spawn actor.transaction as NAME)`, `(trigger actor.transaction)`, and
`(await actor.event)`, with only the bounded transaction-body trigger and
event-wait parent-handoff subsets shipped today. Events are one-cycle control
pulses with no payloads in ATL v0. Concurrent groups may still use
`(group NAME (members ACTOR...) (mode concurrent))`, but that declaration is
static review metadata, not a permanent runtime association and not a way to
bypass fan-in, ordering, width, lifetime, or CDC safety. Compact
`(concurrent ...)` aliases remain deferred.

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

The group appears in `actor_network.groups[]` with `scheduling:
"metadata_only"`. By itself, the declaration names a static review set; it
does not run actors concurrently, infer dependencies, insert storage or muxes,
emit child artifacts, cross clock domains, or accept compact
`(concurrent ...)` aliases.

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
compact aliases, or permanent actor grouping.

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
compact aliases, or permanent actor grouping.

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
payloads, fan-in/fan-out, CDC, ready/backpressure, compact aliases, or
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
compact aliases, or permanent actor grouping.

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
multiple event waits, actor-event fan-in, data movement coupling, CDC,
ready/backpressure, compact aliases, or permanent actor grouping.

FSMGen also has negative coverage for that boundary: one temporary trigger
batch followed by two actor event waits, for example `(await reader.done)`
then `(await writer.done)`, fails before scheduled `.fsm` emission with the
one-event-wait diagnostic. That regression keeps trigger-batch/event
sequencing separate from future actor-event fan-in or generated child
completion joins.

The shipped ATL source-root safety boundary rejects a second top-level
`(actor ...)` root in the same `.isf` file. That sibling root is not yet a
resolved actor type for `(instance name of ActorType)`. One actor root plus
`(library ...)` roots remains accepted, and the shipped library-qualified ATL
subsets now emit generated child `.fsm` artifacts and generated ATL tops.
Sibling-root child type resolution remains deferred.

The selected future source contract for ATL actor type resolution is explicit
library qualification:

```lisp
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
Unqualified `(instance name of ActorType)` remains metadata-only external
intent for now, not an implicit search through sibling actor roots or files.
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

The first generated-child data route is also shipped for one scalar top-level
input-pin route into one resolved child through that generated top. The
source shape is a named drive body with `(worker.payload pins.payload)`,
activated by the same parent transaction that triggers `worker.process` and
awaits `worker.done`. The fixture
`isf/atl_resolved_child_pin_ingress_pipeline.isf` emits parent, child, and top
`.fsm` artifacts; the generated top wires top `payload` to the parent,
parent `worker_payload` to child input `payload`, parent
`worker_process_start` to child `process_start`, and child `done` to parent
`worker_done`. The child `.fsm` includes generated `+interface` role metadata
for the selected child input so the HDL backend preserves `payload` as a
child module port. Actor-to-actor generated-child routes, multi-child data
wiring, route mux/storage, CDC/reset remapping, ready/backpressure, and
payload protocols remain unavailable.

The inverse generated-child data route is also shipped for one scalar
resolved-child output route to one top-level output pin through that generated
top. The source shape is a named drive body with
`(pins.result worker.payload)`, activated after the parent transaction
triggers `worker.process` and awaits `worker.done`. The fixture
`isf/atl_resolved_child_pin_egress_pipeline.isf` emits parent, child, and top
`.fsm` artifacts; the generated top wires child `payload` to parent
`worker_payload`, parent `result` to top `result`, parent
`worker_process_start` to child `process_start`, and child `done` to parent
`worker_done`. The child `.fsm` includes generated `+interface` role metadata
for the selected child output so the HDL backend preserves `payload` as a
child module port. Actor-to-actor generated-child routes, multi-child data
wiring, route mux/storage, CDC/reset remapping, ready/backpressure, and
payload protocols remain unavailable.

FSMGen now fails closed the reserved generated-child actor-to-actor
data-route shape across two resolved children when it is coupled to qualified
actor trigger/event handoffs. That shape reuses the existing `(sink source)`
drive-body movement surface and is now supported only for the selected
two-child scalar data route described below.

The first control-only two-child generated top is now shipped. The fixture
`isf/atl_two_child_pipeline.isf` declares resolved `reader` and `writer`
children, triggers `reader.capture`, waits on `reader.done`, triggers
`writer.emit`, waits on `writer.done`, and completes. Lowering emits parent,
reader, writer, and generated top `.fsm` artifacts. The generated top
instantiates all three modules, exposes only the parent public pins plus
clock/reset, wires `reader_capture_start` to `reader.capture_start`,
`reader.done` to `reader_done`, `writer_emit_start` to
`writer.emit_start`, and `writer.done` to `writer_done`. Schedule JSON keeps
the same actor-network families and uses
`actor_network.generated_tops[].children[]` for the per-child generated-top
wiring records. The first scalar generated-child actor-to-actor route through
that two-child top is also shipped as `isf/atl_two_child_data_pipeline.isf`.
It reuses a named drive body with `(writer.payload reader.payload)` and calls
it after `reader.done` and before `writer.emit`. The scheduled parent exposes
`reader_payload` as the source handoff input and `writer_payload` as the sink
handoff output, drives `writer_payload` from `reader_payload` only for the
`forward_payload` drive-call cycle, and the generated top wires
`reader.payload` to parent `reader_payload` plus parent `writer_payload` to
`writer.payload`. Schedule JSON records the route in
`actor_network.data_movements[]` and the generated top in
`actor_network.generated_tops[]` with `children[]`. Multi-route data wiring,
fan-in/fan-out, route mux/storage, CDC/reset remapping, ready/backpressure,
payload protocols, repeated triggers, trigger batches, groups, recursive
actor networks, and permanent actor grouping remain unavailable.
The shipped hardening around this one-route surface locks the nearby
fail-closed rules: the source endpoint must be a scalar output on the source
child, the sink endpoint must be a scalar input on the sink child, and only
one route drive body, one endpoint pair, and one top-level drive call may
participate.
The shipped width hardening keeps the route scalar one-bit only. Wider child
payload endpoints remain fail-closed until a later payload-width protocol
defines packing, truncation, extension, or storage behavior.
The shipped clock/reset hardening keeps the same route in one parent
clock/reset policy. Source or sink child clock/reset mismatches fail closed
until a later CDC or reset-remap contract is selected; the generated top does
not insert async crossing logic, system-port remapping, route storage, muxing,
or backpressure.
The shipped self-route hardening keeps the route between two distinct
resolved children. Same-child source/sink route pairs fail closed until a
later contract selects self-route, loopback, child-internal bypass, storage,
muxing, fan-in/fan-out, or payload behavior.

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
transactions, carry event payloads, or support fan-in/fan-out, multiple waits,
nested waits, cross-clock actor events, or concurrent group events.
Unqualified local forms keep their existing meaning: `(await signal)` waits
on a local transaction signal, and rule-level `(trigger transaction)` triggers
a local transaction. Dotted enum-looking names that do not name a static
actor instance keep their prior diagnostics.

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
behavior.

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
