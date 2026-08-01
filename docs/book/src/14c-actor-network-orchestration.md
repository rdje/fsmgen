# Actor Network Orchestration Backlog

## Intent Scheduling Format

### Actor Network Orchestration

Status: shipped bounded ATL v0 public contract; broader ATL remains backlog.

Static metadata, scalar handoffs, bounded temporary trigger-batch scheduling,
parent trigger/event handoffs, resolved child `.fsm` artifact emission,
generated ATL tops, and selected scalar generated-child routes are shipped
under the selected ATL v0 public contract. The owning task tree is closed;
remaining ATL behavior changes need a new task-tree leaf before
implementation.

Historical task-tree record:
[ISF-ACTOR-NETWORK-ORCHESTRATION](../../tasks/ISF-ACTOR-NETWORK-ORCHESTRATION.md).
That tree is closed; future ATL behavior changes need a new task-tree leaf
before implementation.

Concrete design proposal:
[ISF_ATL_DESIGN_PROPOSAL](../../ISF_ATL_DESIGN_PROPOSAL.md).

Goal: move ISF up one abstraction level while staying in explicit `.isf`.

The working name is Actor Transfer Level (`ATL`): where RTL describes data
movement between flops/registers, ATL describes data, information, and
activation movement between actors. The actor is the transfer endpoint.

The intended source model is a top-level actor whose structure/content is a
static actor network. Transactions and rules in the top-level actor can
trigger actors or transactions inside the network. Actor instances can
synchronize on scheduler-visible events, move data to other actors, move data
within concurrent actor groups, and move data between actors and the
top-level pins. FSMGen owns scheduling and lowering to explicit `.fsm`, with
the inferred schedule remaining reviewable.

The syntax should stay intent-expressive and should also have a verbose
variant for maximum readability, so the network topology, orchestration,
data movement, and generated schedule evidence can be reviewed without
reading lowering code.

Current ATL v0 proposal:

The top-level root remains `(actor name ...)`. The first metadata-only
implementation slices are shipped: static actor instances may be declared with
the direct actor-level `(instance NAME of ACTOR_TYPE)` clause or compact
`(NAME : ACTOR_TYPE)` alias, and static concurrent groups may be declared with
direct actor-level `(group NAME (members ACTOR...) (mode concurrent))` clauses
or compact `(concurrent NAME ACTOR...)` aliases.

The enclosing actor is the network boundary; `(network ...)` is not part of
the shipped source surface. The accepted forms lower to parser shell and
schedule-report metadata under `actor_network`; verbose instances report
`declaration: "actor"` and compact instance aliases report
`declaration: "instance_alias"`.

Unqualified static instances remain metadata-only external intent.

Library-qualified static instances now resolve to report metadata and emit
their resolved child scheduled `.fsm` artifacts; they still do not emit a
generated ATL top, infer parent/child handoff wiring, schedule groups, or wire
HDL. Multiple instances outside the shipped
scalar handoff and report-only group metadata subsets, broader event/trigger
behavior beyond the single parent-handoff subsets, and wider endpoint movement
remain backlog.

Actor-to-actor and pin-to-actor movement is not expressed as top-level
`connect` clauses. The selected ATL v0 proposal reuses existing drive
definitions and drive calls: a drive body keeps its shipped `(sink source)`
assignment-pair order, while ATL widens `sink` and `source` to qualified actor
endpoints and top-level pins. FSMGen discriminates endpoint roles during
scheduling; the source does not add a new movement keyword.

The rationale is uniform ISF syntax: ATL should not make downstream emitters
or users learn a second data-movement form when existing drive bodies and
drive calls can carry the same intent.

The first `.5` data-movement implementation sequence shipped fail-closed
reservation for unsupported endpoint drive-body pairs, then shipped the first
generated actor-to-actor handoff subset. The shipped subset is exactly
two direct static actor instances, one named drive body with one
`(sink_actor.endpoint source_actor.endpoint)` pair, matching endpoint widths,
and one top-level transaction drive call. It emits external parent handoff
ports named `source_actor_source_endpoint` and `sink_actor_sink_endpoint`, uses
a one-cycle route lifetime, and reports through
`actor_network.data_movements[]`.

Storage, muxing, broader pin movement, inline/expression movement, width
adaptation, fan-in/fan-out, groups, CDC, and trigger/await coupling outside
the selected generated-child top sequence remain separate backlog leaves.

The first pin-movement subsets are shipped in both scalar directions:
top-level input pin to actor endpoint as `(actor.endpoint pins.input_pin)`,
and actor endpoint to top-level output pin as
`(pins.output_pin actor.endpoint)`. Each shipped direction accepts one named
drive body, one direct static actor instance, one top-level transaction drive
call, and one-bit top-level pins only. Wider pin payloads and mixed
pin/actor movement in one drive remain later leaves.

The selected pin-route widening is exact-width vector movement for the
generated-child top-level pin routes. It is tracked by
`ISF-ATL-PIN-ROUTE-VECTOR-WIDTH`. The first implementation leaf is shipped for
one top-level input pin to one resolved child input when both endpoints have
the same positive width, and the inverse resolved-child output to top-level
output pin route is now shipped under the same exact-width policy. The selected
boundary is same-width only, with no packing, truncation, storage, muxing,
fan-in/fan-out, ready/backpressure, CDC/reset remapping, mixed route sets,
broader pin route sets outside the same-child exact-width vector subsets, or
payload protocol inference.

The next selected pin-route widening is exact-width vector multi-route sets.
It is tracked by `ISF-ATL-PIN-VECTOR-MULTI-ROUTE`. The same-child
pin-ingress vector multi-route leaf and inverse same-child pin-egress vector
multi-route leaf are shipped. Each route keeps the existing `(sink source)`
spelling and must prove a matching top-level pin and resolved child endpoint
width. Width adaptation, storage, muxing, fan-in/fan-out,
ready/backpressure, CDC/reset remapping, repeated activation, and payload
protocol inference remain deferred.

The next selected pin-route widening is mixed scalar/vector route sets. It is
tracked by `ISF-ATL-PIN-MIXED-ROUTE-SETS`. The selected sequence keeps the
same `(sink source)` spelling and drive-call timing while allowing one
same-child route set to contain both scalar one-bit routes and exact-width
vector routes in one direction. The pin-ingress leaf is shipped as
`isf/atl_resolved_child_pin_ingress_mixed_pipeline.isf`: `(worker.payload
pins.payload)` is an exact-width vector route at width 8 and `(worker.valid
pins.valid)` is a scalar one-bit route into the same resolved child through
adjacent pre-trigger drive calls. Each route keeps route-local `kind`, `width`,
and `width_source` metadata. The pin-egress leaf is also shipped as
`isf/atl_resolved_child_pin_egress_mixed_pipeline.isf`: `(pins.result
worker.payload)` is an exact-width vector route at width 8 and `(pins.valid
worker.valid)` is a scalar one-bit route from the same resolved child through
adjacent post-event drive calls. The task tree is closed. Width adaptation,
storage, muxing, fan-in/fan-out, ready/backpressure, CDC/reset remapping,
repeated activation, and payload protocol inference remain deferred.

The selected orchestration vocabulary reuses existing ISF activation forms:
`(do actor.transaction)` for blocking actor transaction activation, `(spawn
actor.transaction as NAME)` for nonblocking activation, `(trigger
actor.transaction)` for rule-level or transaction-body activation, and
`(await actor.event)` for one-cycle actor event synchronization.

The bounded transaction-body trigger/event-wait parent-handoff subsets are
shipped today. One top-level rule action `(trigger actor.transaction)` is also
shipped as a parent-handoff pulse.

Event payloads are not part of ATL v0.

Concurrent groups use `(group NAME (members ACTOR...)

(mode concurrent))` as schedulable intent, not as a bypass for ordering,
fan-in, width, lifetime, or CDC safety.

The group axis started with fail-closed diagnostics, then shipped report-only
static group metadata for verbose `(group ...)` declarations.

The compact `(concurrent NAME ACTOR...)` alias is now shipped by
`ISF-ATL-COMPACT-GROUP-ALIAS`. It is only a readability alias for the verbose
group form and keeps group behavior report-only. Runtime group scheduling,
group endpoints, group handoff routing, generated HDL behavior, and compact
movement syntax remain later leaves.

Source-authored `group.name` endpoints now have a targeted fail-closed
boundary. If the qualifier names a declared static group, transaction-body
`(trigger group.name)`, `(await group.name)`, `(await_all group.name)`,
`(await_any group.name)`, and rule-action `(trigger group.name)` fail with an
ATL group-endpoint diagnostic. Accepting those forms still requires a later
contract for group-level trigger arbitration/fanout, event aggregation,
storage/lifetime, and generated-child wiring semantics.

The compact `(NAME : ACTOR_TYPE)` instance alias is now shipped by
`ISF-ATL-COMPACT-INSTANCE-ALIAS`. It is only a readability alias for verbose
`(instance NAME of ACTOR_TYPE)` static instance declarations. Verbose
instances report `declaration: "actor"`; compact instance aliases report
`declaration: "instance_alias"`. Instance scheduling behavior, actor type
resolution, generated child emission, generated ATL tops, compact movement
syntax, and route behavior are unchanged by the alias.

The first multi-actor trigger scheduling leaf is shipped as a same-cycle
external trigger batch over existing transaction-body
`(trigger actor.transaction)` clauses: one contiguous batch, distinct static
actor instances, generated external trigger outputs pulsed from one parent
state, and `actor_network.association_schedules[]` report evidence. Static
`(group ...)` declarations are not required and remain review metadata only.

Noncontiguous batches, repeated members, generated children, group endpoints,
data-movement coupling, hidden same-cycle event joins, route mux/storage, and
CDC remain later leaves.

The compatibility `actor_network.group_schedules[]` array remains for schedule
JSON `schema_version: 1`. The canonical association entry uses
`kind: "temporary_trigger_batch"` and `lifetime: "task_scoped"`. This report
contract does not add source syntax or generated HDL behavior.

The first realistic ATL fixture is shipped as
`isf/atl_trigger_batch_pipeline.isf`. It is deliberately bounded to already
shipped surfaces: three direct static actor instances and one contiguous
transaction-body trigger batch. It proves scheduled `.fsm`, strict schedule
JSON, and HDL reachability coverage. It does not claim peer event
synchronization, endpoint data movement, generated ATL child artifacts,
generated ATL tops, group endpoints, compact movement aliases, CDC, route mux/storage,
payloads, ready/backpressure, trigger/data/event coupling, or permanent actor
grouping.

The scalar data-route ATL fixture is now shipped as
`isf/atl_data_route_pipeline.isf`. It uses the already shipped scalar
actor-to-actor data movement surface: two direct static actors, one named
drive body with `(consumer.payload producer.payload)`, and one transaction
drive call. The fixture proves generated parent handoff ports,
`actor_network.data_movements[]` route metadata, empty association/group
schedule arrays, strict schedule JSON, and plain plus strict HDL reachability
without claiming generated children, route mux/storage, trigger/data coupling,
wider payloads, fan-in/fan-out, CDC, ready/backpressure, or permanent
grouping.

The scalar pin-ingress ATL fixture is now shipped as
`isf/atl_pin_ingress_pipeline.isf`. It uses the already shipped scalar
top-level input-pin to actor movement surface: one direct static actor, one
top-level input pin `payload`, one named drive body with
`(consumer.payload pins.payload)`, and one transaction drive call. The fixture
proves the existing top-level pin as the source, generated actor handoff
output `consumer_payload`, `actor_network.data_movements[]` route metadata
with kind `scalar_pin_to_actor_handoff`, strict schedule JSON, and plain plus
strict HDL reachability without claiming actor-to-pin egress, bidirectional
pin movement, generated children, route mux/storage, trigger/data coupling,
wider payloads, fan-in/fan-out, CDC, ready/backpressure, or permanent
grouping.

The scalar pin-egress ATL fixture is now shipped as
`isf/atl_pin_egress_pipeline.isf`. It uses the already shipped scalar
actor-to-top-level output pin movement surface: one direct static actor, one
top-level output pin `result`, one named drive body with
`(pins.result producer.payload)`, and one transaction drive call. The fixture
proves the generated actor source handoff input `producer_payload`, existing
top-level output sink `result`, `actor_network.data_movements[]` route
metadata with kind `scalar_actor_to_pin_handoff`, strict schedule JSON, and
plain plus strict HDL reachability without claiming bidirectional pin
movement, generated children, route mux/storage, trigger/data coupling, wider
payloads, fan-in/fan-out, CDC, ready/backpressure, or permanent grouping.

The ATL trigger-wait fixture is now shipped as
`isf/atl_trigger_wait_pipeline.isf`. It uses the shipped parent handoff
subsets rather than generated child wiring: one static actor `worker`, one
`(trigger worker.process)` one-cycle output handoff, one following
`(await worker.done)` event input wait, and one completion pulse. The fixture
proves single-actor orchestration sequencing, strict schedule JSON, and plain
plus strict HDL reachability without claiming temporary trigger-batch plus
event coupling, multiple waits or triggers, generated children, generated ATL
tops, actor type resolution, HDL child wiring, data movement coupling,
fan-in/fan-out, CDC, ready/backpressure, or permanent grouping.

The ATL trigger-batch wait fixture is now shipped as
`isf/atl_trigger_batch_wait_pipeline.isf`. It couples the shipped temporary
trigger-batch surface to one following actor event wait: a parent transaction
triggers reader, filter, and writer in one same-cycle batch, waits on
`writer.done`, then completes. The fixture proves parent-level
trigger-batch/event sequencing, strict schedule JSON, and plain plus strict
HDL reachability without claiming hidden actor-event fan-in, generated
children, generated ATL tops, actor type resolution, HDL child wiring, data
movement coupling, CDC, ready/backpressure, or permanent grouping.

The bounded multi-event wait widening is now shipped through
`isf/atl_trigger_batch_multi_wait_pipeline.isf`. It keeps the existing
`(await actor.event)` syntax and preserves each authored wait as a
source-ordered scheduled wait state after one temporary trigger batch. The
accepted subset requires contiguous top-level waits, distinct triggered actor
instances, and no ATL data movement in the same transaction segment. It is
not a hidden same-cycle join and does not claim repeated waits, event
payloads, event fan-out, generated-child route coupling, group endpoints,
CDC, or ready/backpressure. Repeated waits to the same triggered actor after
a trigger batch fail closed with a diagnostic that names the missing event
re-arm or per-event generation/lifetime contract. `await_all`/`await_any`
clauses with qualified actor-event operands fail closed too; those sync forms
remain generated-child completion joins until an explicit actor-event join
contract adds event latch/storage and lifetime semantics.

The ATL source-root boundary is shipped before generated child resolution. A
sibling top-level `(actor ...)` root in the same `.isf` source fails closed
until FSMGen has an explicit actor type-resolution and generated child
artifact contract. Same-source `(library ...)` roots remain accepted.

The explicit actor type-resolution source contract is now selected for future
ATL leaves. Resolved static actor types use the library-qualified form
`(instance NAME of ALIAS.EXPORT)`, where `ALIAS` is declared by the enclosing
actor's `(imports (library ... as ALIAS))` clause and `EXPORT` is an actor
export from that library. Unqualified `(instance NAME of ACTOR_TYPE)` remains
metadata-only external intent until a later leaf widens it, and sibling actor
roots remain rejected. Existing `(use alias.actor as instance ...)` remains
the separate reusable-library generated-top surface with explicit bindings.

The targeted fail-closed reservation for the qualified ATL syntax is now
shipped: missing imports, non-explicit import aliases, unknown aliases,
and unknown exports still fail before scheduled `.fsm` emission. Resolved
qualified entries add `type_resolution`, `library`, `alias`, `export`,
`module`, and `scheduled_fsm` to resolved `actor_network.instances[]` entries
and now emit their child `.fsm` files. The first generated ATL top is shipped
for one resolved child plus one trigger/event handoff pair, and the scalar
pin-ingress route, exact-width vector pin-ingress route, same-child scalar
pin-ingress multi-route extension, same-child vector pin-ingress multi-route
extension, same-child mixed scalar/vector pin-ingress route-set extension,
scalar pin-egress route, exact-width vector pin-egress route, scalar
same-child pin-egress multi-route extension, vector same-child pin-egress
multi-route extension, and same-child mixed scalar/vector pin-egress route-set
extension below are shipped for that same one-child top. Broader
generated ATL tops, HDL child wiring outside that selected pair plus shipped
scalar/vector pin routes,
interface binding inference, event fan-in, route mux/storage, CDC, recursive
actor networks, and ready/backpressure remain later leaves.

The resolved-child fixture is now shipped as
`isf/atl_resolved_child_pipeline.isf`. It proves the generated-top boundary
with one same-source library actor export, one resolved child instance, one
parent trigger handoff, one parent event wait, exactly three lower-result
artifacts, strict schedule JSON parity, and generated parent/child handoff
wiring through `atl_resolved_child_pipeline_top.fsm`.

HDL promotion for that resolved-child shape is shipped. It keeps the source
and report schema unchanged and proves plain plus strict CLI SystemVerilog
generation contains the generated top, scheduled parent, resolved child, and
selected internal trigger/event links.

The first generated-child data-route slice is shipped as one scalar top-level
input-pin route into one resolved child through the generated top, written as
`(worker.payload pins.payload)` in a named drive body. The fixture
`isf/atl_resolved_child_pin_ingress_pipeline.isf` proves parent/child/top
artifacts, generated-top wiring, route metadata, child input port
preservation, and plain plus strict HDL generation.

The exact-width vector version of that pin-ingress slice is shipped as
`isf/atl_resolved_child_pin_ingress_vector_pipeline.isf`. It uses the same
drive-body spelling and routes one top-level input pin into one resolved child
input when both endpoints have the same width. The fixture proves
parent/child/top artifacts, exact-width handoff ports, generated-top wiring,
route metadata with `vector_pin_to_actor_handoff`, child input port
preservation, strict outdir materialization, plain plus strict HDL generation,
and a fail-closed top-input/child-input width mismatch diagnostic.

The exact-width vector multi-route extension of that pin-ingress shape is now
shipped as `isf/atl_resolved_child_pin_ingress_vector_multi_pipeline.isf`. It
routes `(worker.payload pins.payload)` and
`(worker.sideband pins.sideband)` through adjacent top-level drive calls before
the child trigger, with route-local widths 8 and 4. The fixture proves
parent/child/top artifacts, exact-width handoff ports, generated-top wiring,
route metadata with two `vector_pin_to_actor_handoff` entries, child vector
input port preservation, strict outdir materialization, plain plus strict HDL
generation, and a fail-closed route-local top-input/child-input width mismatch
diagnostic.

The mixed scalar/vector route-set extension of that one-child pin-ingress shape
is now shipped as `isf/atl_resolved_child_pin_ingress_mixed_pipeline.isf`. It
routes `(worker.payload pins.payload)` at width 8 and
`(worker.valid pins.valid)` at width 1 through adjacent top-level drive calls
before the child trigger. The fixture proves parent/child/top artifacts,
route-local vector and scalar handoff ports, generated-top wiring, route
metadata with `vector_pin_to_actor_handoff` and
`scalar_pin_to_actor_handoff` entries, child input port preservation, strict
outdir materialization, plain plus strict HDL generation, and a fail-closed
route-local vector top-input/child-input width mismatch diagnostic.

The bounded multi-route extension of that one-child pin-ingress shape is now
shipped as `isf/atl_resolved_child_pin_ingress_multi_pipeline.isf`. It routes
`(worker.payload pins.payload)` and `(worker.sideband pins.sideband)` through
adjacent top-level drive calls before the child trigger, with separate drive
states, generated handoffs, generated child interface roles, generated-top
wiring, and route metadata for each scalar path. Actor-to-actor generated-child
routes outside their own two-child subset, multi-child data wiring, route
mux/storage, fan-in/fan-out, CDC/reset remapping, ready/backpressure, and
payload protocols remain deferred.

The inverse generated-child data-route slice is now shipped as one scalar
resolved-child output route to one top-level output through the generated top,
written as `(pins.result worker.payload)` in a named drive body after the
parent triggers `worker.process` and awaits `worker.done`. The fixture
`isf/atl_resolved_child_pin_egress_pipeline.isf` proves parent/child/top
artifacts, generated-top wiring, route metadata, child output port
preservation, plain plus strict HDL generation, missing child output failure,
and pre-event drive-order failure. That one-child pin route does not include
actor-to-actor generated-child routing, multi-child data wiring, route
mux/storage, CDC/reset remapping, ready/backpressure, or payload protocols.

The exact-width vector version of that pin-egress slice is shipped as
`isf/atl_resolved_child_pin_egress_vector_pipeline.isf`. It uses the same
drive-body spelling and routes one resolved child output into one top-level
output pin when both endpoints have the same width. The fixture proves
parent/child/top artifacts, exact-width handoff ports, generated-top wiring,
route metadata with `vector_actor_to_pin_handoff`, child output port
preservation, strict outdir materialization, plain plus strict HDL generation,
and a fail-closed child-output/top-output width mismatch diagnostic.

The exact-width vector multi-route extension of that pin-egress shape is now
shipped as `isf/atl_resolved_child_pin_egress_vector_multi_pipeline.isf`. It
routes `(pins.result worker.payload)` and `(pins.status worker.status)` through
adjacent top-level drive calls after the child event wait, with route-local
widths 8 and 4. The fixture proves parent/child/top artifacts, exact-width
handoff ports, generated-top wiring, route metadata with two
`vector_actor_to_pin_handoff` entries, child vector output port preservation,
strict outdir materialization, plain plus strict HDL generation, and a
fail-closed route-local child-output/top-output width mismatch diagnostic.

The mixed scalar/vector route-set extension of that one-child pin-egress shape
is now shipped as `isf/atl_resolved_child_pin_egress_mixed_pipeline.isf`. It
routes `(pins.result worker.payload)` at width 8 and `(pins.valid
worker.valid)` at width 1 through adjacent top-level drive calls after the
child event wait. The fixture proves parent/child/top artifacts, route-local
vector and scalar handoff ports, generated-top wiring, route metadata with
`vector_actor_to_pin_handoff` and `scalar_actor_to_pin_handoff` entries, child
output port preservation, strict outdir materialization, plain plus strict HDL
generation, and a fail-closed route-local vector child-output/top-output width
mismatch diagnostic.

The bounded multi-route extension of that one-child pin-egress shape is now
shipped as `isf/atl_resolved_child_pin_egress_multi_pipeline.isf`. It routes
`(pins.result worker.payload)` and `(pins.status worker.status)` through
adjacent top-level drive calls after the child event wait, with separate drive
states, generated handoffs, generated child interface roles, generated-top
wiring, and route metadata for each scalar path. That one-child route set does
not include actor-to-actor generated-child routing, multi-child data wiring,
route mux/storage, fan-in/fan-out, CDC/reset remapping, ready/backpressure, or
payload protocols.

The selected generated-child actor-to-actor data movement across two resolved
children is shipped only for same-source/same-sink two-child routes that use
qualified trigger/event handoffs and matching endpoint widths. The source
shape reuses the existing `(sink source)` drive-body pair; malformed or
mismatched-width routes still fail closed before remapping, storage, muxing,
fan-in/fan-out, payload adaptation, or backpressure behavior is inferred.

The first positive two-child generated top is now shipped for the control-only
case: `isf/atl_two_child_pipeline.isf` triggers `reader.capture`, waits on
`reader.done`, triggers `writer.emit`, waits on `writer.done`, and completes.

Lowering emits parent, both children, and one generated top; schedule JSON
records the generated-top child wiring under
`actor_network.generated_tops[].children[]`.

The selected resolved-child trigger-batch generated-top case is also shipped
as `isf/atl_two_child_trigger_batch_pipeline.isf`. It keeps two resolved
children and no data movement, emits one same-cycle parent trigger-batch state
for `reader.capture` and `writer.emit`, waits on `reader.done` and
`writer.done` in source order, and writes parent, both children, and one
generated top. Schedule JSON preserves `transaction_triggers[]`,
`event_waits[]`, `association_schedules[]`, and `group_schedules[]`, then
advertises the generated top with kind
`resolved_children_trigger_batch_event_sequence`.

The first one-bit generated-child actor-to-actor route through that two-child
top is now shipped as `isf/atl_two_child_data_pipeline.isf`. The source uses
`(writer.payload reader.payload)` in a named drive body, called after
`reader.done` and before `writer.emit`. Lowering emits parent, both children,
and one generated top. The parent exposes `reader_payload` and
`writer_payload` handoffs, the parent drive body moves the scalar payload for
the drive-call cycle, and the generated top wires `reader.payload` to the
parent source handoff plus the parent sink handoff to `writer.payload`.

The exact-width vector route through that two-child top is now shipped as
`isf/atl_two_child_vector_data_pipeline.isf`. It uses the same
`(writer.payload reader.payload)` source shape and ordering, but both child
payload endpoints declare width 8. Lowering emits 8-bit parent handoffs,
8-bit child interface roles, generated-top wiring, SystemVerilog vector links,
and `actor_network.data_movements[]` metadata with
`kind: "vector_actor_handoff"` and
`width_source: "resolved_child_endpoint_exact_width"`.

The bounded multi-route extension of that same route shape is now shipped as
`isf/atl_two_child_multi_data_pipeline.isf`. It keeps the same parent
transaction and child pair, then routes both `(writer.payload reader.payload)`
and `(writer.sideband reader.sideband)` with adjacent top-level drive calls
between `reader.done` and `writer.emit`. Lowering emits separate drive states,
separate handoff signals, generated child interface roles for both scalar
paths, and generated-top wiring for both paths.

Fan-in/fan-out data routing, mux/storage, CDC/reset remapping,
ready/backpressure, payload protocols, repeated triggers, broader
trigger-batch combinations including data movement coupling, groups,
recursive actor networks, cross-transaction continuation, and permanent actor
grouping remain backlog.

The shipped hardening does not widen that support. It locks focused
fail-closed coverage for missing or wrong-direction child payload ports and
route-cardinality violations around the shipped same-source/same-sink route
fixtures before any mux/storage, fan-in/fan-out, or payload-protocol work is
claimed.

The shipped width hardening narrows that payload-protocol backlog further by
allowing only same-width generated-child actor-to-actor route endpoints.
Mismatched widths remain fail-closed until explicit packing, truncation,
extension, slicing, storage, or mux semantics are selected.

The shipped clock/reset hardening narrows the CDC/reset-remap backlog by
requiring source and sink children in the generated-child actor-to-actor
route to share the parent clock/reset policy; mismatches fail closed until
explicit CDC bridge or reset-remapping semantics are selected.

The shipped self-route hardening narrows the loopback/storage backlog by
requiring source and sink actor qualifiers in the generated-child
actor-to-actor route to name distinct resolved children; same-child pairs
fail closed until explicit self-route, bypass, storage, mux, or fan-in/fan-out
semantics are selected.

The shipped repeated-trigger hardening narrows the repeated-activation
backlog by requiring the generated-child actor-to-actor route sequence to
contain only one source-child trigger and one sink-child trigger; extra
route-child triggers fail closed until explicit restart, pending-request,
trigger fan-in/fan-out, or multi-activation scheduling semantics are
selected.

The shipped repeated-wait hardening narrows the event-coupling backlog by
requiring the same route sequence to contain only one source-child event wait
and one sink-child event wait; extra route-child waits fail closed until
explicit event fan-in/fan-out, repeated wait sequencing, route-level wait
storage, muxing, ready/backpressure, or payload semantics are selected.

The shipped same-parent-transaction hardening narrows the route continuation
backlog by requiring the route sequence to stay inside one parent
transaction; split route clauses remain fail-closed until explicit pending
handoff storage, transaction rendezvous, cross-transaction scheduling,
muxing, ready/backpressure, or payload semantics are selected.

The shipped sink-trigger ordering hardening narrows the speculative
activation backlog by requiring the data drive call to precede the sink child
trigger; sink-before-drive route clauses remain fail-closed until explicit
delayed payload delivery, route storage, muxing, ready/backpressure, or
payload semantics are selected.

The shipped sink-event-wait ordering hardening narrows the event sampling
backlog by requiring the sink child event wait to follow the sink child
trigger; sink-wait-before-trigger route clauses remain fail-closed until
explicit pre-trigger acknowledgement, sticky event sampling, event replay,
route storage, muxing, ready/backpressure, or payload semantics are selected.

The shipped source-event-wait ordering hardening applies the same
event-sampling boundary on the source side by requiring the source child
event wait to follow the source child trigger; source-wait-before-trigger
route clauses remain fail-closed until explicit pre-trigger acknowledgement,
sticky event sampling, event replay, route storage, muxing, ready/backpressure,
or payload semantics are selected.

The shipped route-contiguity hardening narrows the route-interleaving
backlog by requiring the same route sequence to stay one contiguous
transaction-body segment; unrelated parent clauses interleaved between route
clauses remain fail-closed until explicit interleaved parent work, local side
effects, pre/post route sampling, route continuation, storage, muxing,
ready/backpressure, or payload semantics are selected.

The shipped route-isolation hardening narrows the pre/post-route side-effect
backlog by requiring the contiguous route segment to remain the only
executable parent transaction-body work between start and completion; parent
clauses before the source trigger or after the sink event wait remain
fail-closed until explicit setup, cleanup, local side effects, continuation,
storage, muxing, ready/backpressure, or payload semantics are selected.

The shipped route-boundary cardinality hardening narrows the activation and
completion boundary backlog by requiring that isolated route to stay bounded
by exactly one simple start boundary and one simple completion boundary;
extra start or completion clauses remain fail-closed until explicit
activation fan-in, completion fan-out, start arbitration, setup/cleanup,
continuation, storage, muxing, ready/backpressure, or payload semantics are
selected.

The shipped boundary-simplicity hardening narrows the boundary-body backlog
by keeping those start/completion boundaries body-free; activation-body
samples in `(on ...)` and extra payload operands in `(complete ...)` remain
fail-closed until explicit activation-body sampling, completion payload,
setup/cleanup, continuation, storage, muxing, ready/backpressure, or payload
semantics are selected.

The shipped boundary-role hardening narrows the parent-interface boundary
backlog. For the generated-child actor-to-actor route, the start boundary
must remain a scalar top-level input pin, and the completion boundary must
remain a scalar top-level output pin. Output-as-start, input-as-completion,
undeclared, and wider boundary pins fail closed until explicit interface
remapping, activation fan-in, completion fan-out, boundary expressions,
storage, muxing, ready/backpressure, or payload semantics are selected.

The shipped generated-handoff collision hardening narrows collision coverage
for that same route. Parent interface or actor-owned storage declarations
that collide with generated trigger, event, data, or named-drive request
handoffs fail closed before any generated-handoff remapping, route
mux/storage, fan-in/fan-out, interface remapping, ready/backpressure, or
payload semantics are claimed.

The shipped lowerer defensive backstop covers the same handoff names for
malformed or mutated scheduler-facing actor metadata that bypasses normal
parser finalization. Those collisions now fail closed before generated-top
wiring. This did not select a new authoring surface, generated-handoff
remapping, route mux/storage, fan-in/fan-out, ready/backpressure, or payload
semantics.

The dedicated generated-child route terminology section is audit-backed in
the mdBook. This is a documentation truth guard for handoff remapping, route
mux/storage, fan-in/fan-out, ready/backpressure, payload protocols,
parser/lowerer collision ownership, and the current one-bit drive-call-cycle
boundary, not a behavior widening.

The selected documentation precision pass for that same section is now
shipped. The route terms are presented as a term-by-term support boundary so
the current definitions, shipped subset, and deferred behavior are reviewable
without reading implementation code.

Parameterized route drive definitions and route drive calls with actual
arguments also remain outside the shipped ATL actor-to-actor, pin-ingress, and
pin-egress route families. Those forms fail closed before drive actual binding,
expression movement, route mux/storage, or payload protocol behavior can be
inferred.

Route endpoint expressions also remain outside that route. The selected
source stays the scalar endpoint `reader.payload`; a source expression such
as `(+ reader.payload 1)` fails closed before expression movement, value
transformation, storage, or payload protocol behavior can be inferred. The
selected sink stays the scalar endpoint `writer.payload`; a sink expression
such as `(+ writer.payload 1)` fails closed before expression destinations,
route-side transforms, storage, or payload protocol behavior can be inferred.

The source-expression source-order diagnostic is now shipped:
drive-before-instance malformed source expressions such as
`(writer.payload (+ reader.payload 1))` report the same targeted ATL
source-expression diagnostic after actor instances are known. It does not
select expression movement, route-side transforms, storage, muxing,
ready/backpressure, or payload protocols.
That sink-expression diagnostic is source-order independent for
endpoint-looking malformed route sinks, while ordinary malformed local drive
targets such as `((out) 1)` keep the generic drive-body scalar-head
diagnostic.
The accepted scalar generated-child route is source-order independent too:
placing the named route drive before the direct static actor instances still
resolves to the same generated ATL top handoffs and
`actor_network.data_movements[]` metadata.

The first actor-event implementation boundary is a generated parent-handoff
wait, not full child orchestration. FSMGen accepts exactly one top-level
transaction-body `(await actor.event)` when the qualifier names a declared
direct static actor instance. The wait may stand alone for a single static
actor, or follow one selected same-cycle temporary trigger batch. That wait
lowers to a deterministic one-bit parent handoff input named `actor_event`;
for example, `reader.done` maps to `reader_done`. The scheduled parent `.fsm`
exposes and waits on that input, and schedule JSON records the wait under
`actor_network.event_waits[]`.

The producer of that pulse remains external until later ATL leaves resolve
actor types, generate child artifacts, emit ATL tops, and support qualified
actor transaction trigger wiring beyond the parent-handoff subset. Multiple
waits, nested waits, fan-in, fan-out, event payloads, cross-clock events, and
concurrent group events stay fail-closed/deferred. Existing unqualified local
forms stay unchanged:
`(await signal)` remains a transaction wait, and rule-level
`(trigger transaction)` remains a local transaction trigger. Dotted
enum-looking names that do not name a static actor instance keep their prior
diagnostics.

The shipped qualified actor-transaction trigger subset mirrors that handoff
boundary. One top-level transaction-body `(trigger actor.transaction)` against
a direct static actor instance lowers to a generated one-cycle parent output
named `actor_transaction_start`; for example, `reader.capture`
maps to `reader_capture_start`. One top-level rule action may use the same
qualified trigger spelling; for example, `(trigger worker.process)` in a rule
lowers through `worker_process_start`. The scheduled parent `.fsm` exposes
and pulses that output at the trigger point, and schedule JSON records the
trigger under `actor_network.transaction_triggers[]`.

```lisp
(actor atl_rule_transaction_trigger
  (clock clk)
  (interface (input fire) (output done))
  (instance worker of packet_worker)
  (transaction run
    (on fire)
    (complete done))
  (rule kick fire
    (trigger worker.process)))
```

The trigger sink remains external until later ATL leaves resolve actor types,
generate child artifacts, emit ATL tops, and add ready/backpressure or payload
semantics. Nested triggers, repeated triggers to the same actor instance,
repeated rule-action qualified triggers, generated handoff signal conflicts,
fan-in, fan-out, rule-action trigger payloads or bindings, cross-clock
triggers, and broader concurrent group behavior stay fail-closed/deferred.

Direct actor-body proposal (backlog illustration; uses syntax that
is still on the deferred list, so the validator rejects this fixture
today — kept here to document the future direction):

```text
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

Proposed endpoint vocabulary:

| Endpoint | Meaning |
| --- | --- |
| `pins.name` | Top-level actor interface pin. |
| `actor.port` | Interface port on an actor instance. |
| `actor.transaction` | Transaction on an actor instance. |
| `actor.event` | Scheduler-visible one-cycle event from an actor instance. |
| `group.name` | Explicit concurrent group. |

Proposed semantic split:

| Form | Meaning |
| --- | --- |
| Drive body pair `(sink source)` | Selected ATL v0 movement source shape: existing drive-body assignment order with widened endpoint names. |
| Drive call `(drive name args...)` | Existing timing point that activates the drive body. |
| `transfer source sink` / `move source sink` | Not planned for ATL v0; possible later ergonomic sugar only if drive-body reuse proves inadequate. |
| `event` | Named one-cycle control pulse; payloads remain deferred. |
| `trigger` | Activation of a qualified actor transaction. |
| `group` | Intentional concurrent actor group for scheduling analysis/reporting. |

The ATL v0 movement proposal reuses existing drive bodies, for example
`(drive feed_crc (crc.payload reader.payload))`, where `crc.payload` is the
sink and `reader.payload` is the source. The scheduler knows whether the
source, the sink, or both are actor-interface endpoints or top-level pins, and
it derives the required routing/handoff plan. Directional symbolic aliases
such as `=>` are not preferred because they can look like physical routing
instead of intent-level movement.

The movement action is not intended to mean permanent actor-to-actor wiring.

The RTL analogy is a mux feeding a flop: the sink actor is like the flop D
input, and source actors are like mux data inputs. Several source actors may
be allowed to provide the same information to a sink actor at different
scheduled moments, but FSMGen must infer or reject the actual movement based
on the drive body's `(sink source)` pair, the drive-call timing point,
triggers, sink-valid conditions, disjoint timing, and any generated
mux/enable/handoff plan. The scheduler derives the connectivity; the source
does not need a separate `connect` clause for actor-to-actor movement.

The author should not have to hand-author routing. FSMGen owns the runtime
route-select control, mux selects, enables, and handoffs that dynamically move
information between actors once the scheduled interaction is inferred.

Current boundary: ISF actors currently decompose into actor-local
transactions, rules, stages, resources, storage, and generated child
transaction activations.

They now define public actor-network source surfaces: static actor instance
declarations and compact `(NAME : ACTOR_TYPE)` aliases, library-qualified
resolved child artifacts, and report-only static group declarations plus
compact `(concurrent NAME ACTOR...)` aliases recorded as `actor_network`
metadata. Parent transactions can use selected child trigger/event handoffs,
one bounded temporary trigger batch followed by source-ordered event waits to
distinct triggered actors, and selected generated-child data routes written
with existing drive-body `(sink source)` movement syntax.

Resolved ATL child `.fsm` files and bounded generated ATL tops are shipped for
the documented one-child/two-child resolved-child trigger/event and data-route
subsets. The public report surface includes `actor_network.generated_tops[]`
and `actor_network.data_movements[]` evidence for those subsets; private
generated-top data-link plumbing remains outside the public contract.

Route mux/storage, handoff remapping/storage, payload protocols,
ready/backpressure, CDC/reset remapping, fan-in/fan-out, compact movement
aliases, group endpoints, runtime group scheduling, inferred child interface
bindings outside the documented generated-child subsets, broader global
scheduling ownership, and broader fail-closed boundaries remain under
task-tree ownership.

This direction is still IAL1 if the source remains explicit actor/network
`.isf` syntax with scheduler-visible events, bindings, and constraints.

It becomes an IAL2 candidate only if the source model moves above explicit
ISF actor/network syntax into protocol/platform intent inference.
