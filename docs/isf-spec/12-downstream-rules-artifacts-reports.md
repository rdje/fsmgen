
## 12. Rules, Priorities, Resources

Rule forms:

```lisp
(rule name condition
  action...)

(rule name
  (when condition)
  action...)
```

Actions:

```lisp
(target expr)
(set target expr)
(store bank index value)
(load bank index as target)
(trigger transaction)
(trigger transaction (params ...) (bind ...))
(priority over other_rule_or_transaction)
```

Rules:

- Rule guards may be scalar conditions or non-empty list expressions.
- Rule DTs are non-state concurrent logic guarded by the rule condition.
- Same-target rule writes are accepted only when direct contradictory guard
  facts prove they cannot fire in the same cycle.
- Rule/rule, rule-over-transaction, and transaction-over-rule same-target data
  conflicts can be resolved by declared priority when both writes use the same
  timing operator and the priority graph has one winner. Transaction-over-rule
  lowering uses scheduled `.fsm` `(state_active STATE)` guard syntax to disable
  the lower-priority rule assignment while the winning transaction state is
  active; that guard lowers to internal state-register comparison logic, not
  downstream-visible module input ports.
- The same actor-level rule/transaction priority covers a named drive with
  exactly one distinct local transaction caller and no generated caller.
  Suppression remains target-local in both directions; a unique unordered
  different-value overlap and prioritized ambiguous drive ownership fail
  closed. Shared/generated/mixed or unused-drive overlap without an applicable
  priority remains the explicit `isf_unproven_rule_drive_overlap/not_doable`
  warning. Private caller/source/provenance metadata does not widen downstream
  report or semantic schemas.
- Rule triggers emit one-cycle delayed per-rule trigger sources.
- Multiple rules triggering the same local transaction lower through a
  deterministic trigger fan-in DT unless the target is generated.
- Parameterized triggers use generated child activation instances.
- Generated-child rule triggers may bind scalar output ports back to actor
  targets under the per-trigger done observer; direct/local rule-trigger output
  bindings remain rejected.

Resource arbitration:

```lisp
(resources
  (resource work
    (kind transaction_start)
    (arbiter priority)
    (users high_pri low_pri))
  (resource store_bus
    (kind storage_port)
    (arbiter priority)
    (members slot shadow)
    (users writer_a writer_b))
  (resource response_outputs
    (kind output_bundle)
    (arbiter priority)
    (members valid ready status)
    (users rule_a rule_b))
  (resource fair_response
    (kind output_bundle)
    (arbiter round_robin)
    (members valid ready status)
    (users fair_rule_a fair_rule_b))
  (resource fair_slot
    (kind rule_slot)
    (arbiter round_robin)
    (users rr_high rr_low))
  (resource fair_work
    (kind transaction_start)
    (arbiter round_robin)
    (users fair_start_a fair_start_b)))
```

Rules:

- Current enforced resource kinds are `rule_slot`, `output_bundle`,
  `transaction_start`, and `storage_port` with `priority` arbitration for
  declared rule users. All four also support bounded `round_robin`
  arbitration for declared rule users.
- A bounded `round_robin` `rule_slot`, `output_bundle`, `transaction_start`,
  or `storage_port` uses the `(users ...)` list as a circular grant order.
  FSMGen emits a generated pointer counter named
  `isf_rr_<resource>_turn`, grants the first requesting rule at or after the
  current pointer, advances the pointer only from the winning rule DT, and
  reports the pointer in `inferred_storage[]` with role
  `resource_round_robin_pointer`. The generated pointer name must not collide
  with existing actor ports, constants, parameters, declared storage, or
  generated counters.
- A `transaction_start` resource is named by the local transaction it
  arbitrates. Each listed rule user must trigger that transaction through the
  shipped non-generated rule-trigger surface. Priority suppression and
  bounded round-robin grants gate rule DTs before their per-rule trigger
  source pulses feed the generated `{transaction}_trigger_fanin` DT; the
  fan-in owner and timing stay unchanged.
- An unmembered `output_bundle` keeps the historical implicit surface: the
  bound rule users and the outputs or other LHS targets they drive describe
  the bundle intent.
- `output_bundle` resources may include `(members name...)`; every member
  must name a declared actor output port or concrete actor-owned storage
  signal. Concrete storage signals include scalar storage variables and
  scalarized bank element signals; bank roots, aggregate paths, inferred
  undeclared LHS targets, and arbitrary expressions remain outside this
  explicit member domain. When members are explicit, every listed member must
  be written by at least one bound rule user, and no bound rule user may write
  a declared actor output or actor-owned storage signal outside the list.
- `storage_port` resources with bound users require `(members name...)`; every
  member must name a concrete actor-owned storage signal. Concrete storage
  signals are scalar storage variables and scalarized bank element signals.
  Bank roots, aggregate paths, inferred undeclared LHS targets, transaction
  ports, actor input ports, and arbitrary expressions remain outside this
  explicit member domain. Every listed member must be written by at least one
  bound rule user, and no bound rule user may write a concrete actor-owned
  storage signal outside the list. Under bounded `round_robin`, the same
  mandatory member validation and `resource_arbitration[].members` report
  evidence apply while the generated pointer selects the winning bound rule
  for the cycle.
- Reports expose `resource_arbitration[]`.
- Each `resource_arbitration[]` entry includes `resource`, `kind`, `arbiter`,
  `user`, `user_kind`, `members`, and `suppressed_by`. `members` is an array
  and is empty when the resource has no explicit member list. For `priority`
  resources, `suppressed_by` names higher-priority bound rule users. For
  bounded `round_robin` resources, `suppressed_by` names the dynamic peer
  users that can block the grant for a given pointer position and request set.
- Additional resource kinds may be cataloged as backlog but are not enforced
  unless listed as enforced by the public contract. Generated-child
  transaction starts, generated-child storage arbitration, actor-network
  triggers, actor-network endpoint users, transaction users, named-drive
  users, output-target users, lifetime ownership, route mux/storage,
  `round_robin` for backlog resource kinds, and other non-selected resource
  surfaces remain outside the shipped resource-arbitration subset.

## 12.5. Static Actor Network Metadata

FSMGen now accepts bounded Actor Transfer Level (`ATL`) source surfaces owned
by the top-level actor: direct static actor declarations, compact static actor
declaration aliases, report-only static groups, selected scalar handoffs,
selected parent event/trigger handoffs, and the exact same-cycle temporary
trigger batch.

The static declarations record actor-network intent for downstream discovery;
behavior-bearing leaves add only the explicitly documented parent handoff
ports and scheduled states.

FSMGen now resolves library-qualified child actor types, emits their child
scheduled `.fsm` artifacts, and emits the first generated ATL top for the
selected one-resolved-child trigger/event subset.

The shipped source contract for ATL actor type resolution is explicit library
qualification in `(instance NAME of ALIAS.EXPORT)` or compact
`(NAME : ALIAS.EXPORT)`, not sibling actor roots and not implicit lookup of
unqualified `ACTOR_TYPE` names.

The shipped resolution subset reports metadata for that qualified form:
`type_resolution: library_actor_export`, the resolved `library`, `alias`, and
`export`, plus `module` and `scheduled_fsm` names.

It emits the child `.fsm` artifact named by `scheduled_fsm`; when the source
also has exactly one matching parent trigger/event pair, it emits the
matching `<parent>_top.fsm` and reports it through
`actor_network.generated_tops[]`.

### 12.5.1. Actor-As-Network Boundary And Direct Instances

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

The enclosing actor is the network boundary. Downstream emitters must not wrap
static ATL declarations in `(network ...)`; that spelling fails closed in the
current shipped surface.

The schedule report exposes this through top-level `actor_network`:

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

Verbose `(instance NAME of ACTOR_TYPE)` declarations report
`declaration: "actor"`. Compact `(NAME : ACTOR_TYPE)` aliases report
`declaration: "instance_alias"`. Both forms share the same validation and
metadata surface. Current fail-closed boundaries include multiple instances
outside the shipped actor-to-actor handoff or report-only group metadata
subsets, `(network ...)`, dynamic/non-scalar names, direct recursive
instantiation, qualified actor/event behavior beyond the selected single
parent-handoff event wait and single parent-handoff transaction trigger
subsets, and group scheduling behavior beyond the exact same-cycle trigger
batch subset documented below.

### 12.5.2. Drive-Body Data Movement And Endpoint Vocabulary

The broader ATL v0 contract is selected for future slices, but downstream
producers must not emit it until the corresponding support appears in the
capability manifest and this handoff:

- Endpoint-aware movement reuses existing drive bodies and drive calls. A
  drive body pair stays `(sink source)` while ATL widens each side to
  `pins.name`, `actor.port`, `actor.transaction`, `actor.event`, or
  `group.name` where a later leaf explicitly permits that endpoint kind.
- `connect`, `transfer`, and `move` are not public ATL v0 movement clauses.
  Movement is temporal scheduling intent, not a permanent actor-to-actor wire.
- Future resolved actor types use `(instance NAME of ALIAS.EXPORT)`, where
  `ALIAS` names an imported library and `EXPORT` names a library actor export.
  That qualified spelling is reserved today and fails closed before scheduled
  `.fsm` emission; unqualified `(instance NAME of ACTOR_TYPE)` stays
  metadata-only until a later leaf explicitly widens it.
- The first endpoint-movement code leaf shipped fail-closed reservation for
  unsupported qualified actor endpoint drive-body pairs, and the generated
  actor-to-actor handoff subset is now downstream-emittable for one-bit scalar
  and exact-width vector generated-child routes.

  Downstream producers may emit exactly two direct static actor instances,
  one named drive body with one `(sink_actor.endpoint source_actor.endpoint)`
  pair, and one top-level transaction drive call. For generated-child routes,
  the source endpoint must be a child output, the sink endpoint must be a
  child input, and both resolved child endpoints must have the same positive
  width.

  FSMGen rewrites the pair to generated parent handoff signals and emits
  external parent handoff ports named `source_actor_source_endpoint` for the
  source input and `sink_actor_sink_endpoint` for the sink output. The handoff
  width is one for scalar one-bit endpoints or the exact matching child
  endpoint width for vector endpoints.

  The `actor_network.data_movements[]` report keys are `kind`, `transaction`,
  `context`, `drive`, `source_instance`, `source_endpoint`, `source_signal`,
  `sink_instance`, `sink_endpoint`, `sink_signal`, `width`, `width_source`,
  `route_lifetime`, `storage`, `source`, and `sink`.

  Route lifetime is one drive-call cycle, with no storage, mux, width
  adaptation, pin movement in that actor-to-actor route, inline/expression
  movement, fan-in/fan-out, groups, CDC, or trigger/await coupling beyond the
  selected generated-child top sequence.
- The first top-level pin movement subset is now downstream-emittable. The
  accepted source form is exactly one direct static actor instance, one named
  drive body with one `(actor.endpoint pins.input_pin)` scalar pair, and one
  top-level transaction drive call. The source pin must be a scalar one-bit
  top-level actor input. FSMGen reads that input pin directly, rewrites the
  actor sink to generated handoff output `actor_endpoint`, and reports kind
  `scalar_pin_to_actor_handoff` with `source => top_level_pin`.
- The actor-to-top-level output pin direction is now downstream-emittable.
  The accepted form is exactly one direct static actor instance, one named
  drive body with one `(pins.output_pin actor.endpoint)` scalar pair, and one
  top-level transaction drive call. The output pin must be a scalar one-bit
  top-level actor output. FSMGen exposes the actor endpoint as generated
  input `actor_endpoint`, drives the existing top-level output pin, and
  reports kind `scalar_actor_to_pin_handoff` with
  `sink => top_level_pin`.
- Blocking actor-transaction orchestration is reserved as
  `(do actor.transaction)`, and nonblocking orchestration as
  `(spawn actor.transaction as NAME)`.
- Rule-level actor-transaction orchestration has a bounded parent-handoff
  subset: one top-level rule action `(trigger actor.transaction)` may target a
  declared static actor instance and lower to a generated one-cycle parent
  output handoff.
- Actor event waits use `(await actor.event)`. The shipped subset is one
  top-level transaction-body wait against a direct static actor instance,
  either alone for one actor or after one selected temporary trigger batch;
  events are one-cycle control pulses and event payloads are not supported.
- Concurrent actor groups may still use
  `(group NAME (members ACTOR...) (mode concurrent))`, but groups are static
  review metadata only. They are not required for task-scoped ATL trigger
  associations and never create permanent runtime associations or override
  fan-in, lifetime, ordering, width, or CDC safety.
- The concurrent-group implementation axis has shipped targeted diagnostics,
  report-only metadata, and the compact readability alias. Downstream
  producers may emit either direct actor-body
  `(group NAME (members ACTOR...) (mode concurrent))` declarations or compact
  `(concurrent NAME ACTOR...)` aliases for the shipped metadata subset: at
  least two already declared direct static actor instances, single-clock actor
  scope, no dynamic membership, no nested groups, and no scheduling behavior.
  Verbose groups report `declaration: "group"`; compact aliases report
  `declaration: "concurrent_alias"`.
- The first multi-actor trigger scheduling subset is now
  downstream-emittable.

  Downstream producers may emit one contiguous top-level transaction-body
  batch of `(trigger actor.transaction)` clauses targeting distinct static
  actor instances.

  FSMGen lowers the batch as one same-cycle external trigger-batch state,
  preserves per-target `actor_network.transaction_triggers[]`, and reports
  canonical batch evidence through `actor_network.association_schedules[]`.

  `actor_network.group_schedules[]` remains a schema-version-1 compatibility
  view.

  If the trigger set matches one declared static group, the compatibility
  `group` field names that group; otherwise it carries a synthetic
  transaction-scoped name such as `run_trigger_batch`.

  Downstream producers must still avoid repeated members, noncontiguous
  batches, generated child assumptions, group endpoints, data-movement
  coupling, hidden same-cycle event joins, storage/mux insertion, CDC,
  compact movement aliases, and broader fan-in/fan-out.

  If a source endpoint qualifier names a declared static group, authored
  `group.name` forms are rejected before generic enum-member handling.
  Transaction-body `(trigger group.name)`, `(await group.name)`, `(await_all
  group.name)`, `(await_any group.name)`, and rule-action
  `(trigger group.name)` fail with the ATL group-endpoint diagnostic. The
  missing downstream contract is group-level trigger arbitration/fanout, event
  aggregation, storage/lifetime, and generated-child wiring semantics.

### 12.5.3. Static Groups Versus Task-Scoped Associations

Static group declarations are review metadata unless a later leaf explicitly
selects scheduling behavior. A `(group NAME (members ACTOR...) (mode
concurrent))` declaration or compact `(concurrent NAME ACTOR...)` alias alone
reports `actor_network.groups[]` with `scheduling: "metadata_only"` and does
not run actors concurrently, create a permanent association, infer
dependencies, insert storage, or bypass CDC, width, ordering, or lifetime
checks.

Task-scoped associations are scheduled evidence created by accepted behavior,
not permanent membership. The shipped temporary trigger-batch subset reports
`actor_network.association_schedules[]` with `lifetime: "task_scoped"` for
the one parent state that pulses the selected actor triggers in the same
cycle. `actor_network.group_schedules[]` remains a schema-version-1
compatibility view of that same timing evidence.

### 12.5.4. Trigger And Event Pulses

Current ATL event-wait handoff subset: downstream producers may emit exactly
one top-level transaction-body `(await actor.event)` against a declared direct
static actor instance. The event name must be a scalar HDL identifier. The
wait may stand alone for a single static actor, or follow one selected
same-cycle temporary trigger batch. FSMGen maps that wait to a generated
one-bit parent event input named `actor_event`; for example, `reader.done`
maps to `reader_done`. The scheduled parent `.fsm` exposes that input and
waits on it. The producer of that event is external in this subset: no actor
type resolution, generated ATL child `.fsm`, generated ATL top, or event
wiring is emitted.

Schedule JSON reports accepted waits under `actor_network.event_waits[]`.
Each entry exposes `transaction`, `context`, `instance`, `event`, `signal`,
and `source`; the current source is `external_handoff`.

The selected multi-event parent-handoff subset is also supported after one
temporary trigger batch. Downstream producers may emit a contiguous,
source-ordered chain of top-level `(await actor.event)` clauses immediately
after the accepted trigger-batch state when every wait targets a distinct
triggered actor instance and the transaction segment has no ATL data
movement. FSMGen preserves the chain as sequential wait states; it does not
collapse them into a hidden same-cycle event join.

The rest of the ATL event boundary remains fail-closed.

Downstream producers must not emit nested actor-event waits, repeated waits
to one actor instance, non-batch multi-wait forms, interleaved parent work
inside the multi-wait segment, fan-in/fan-out event joins, event payloads,
cross-clock actor events, concurrent group events, or source that relies on
generated ATL child artifacts or generated ATL top event wiring until the
corresponding support is documented here and advertised in the manifest.
Repeated waits after a temporary trigger batch fail closed with a diagnostic
that names the missing event re-arm or per-event generation/lifetime contract.
Downstream producers must also not spell actor-event all-of/any-of joins with
`await_all` or `await_any` qualified operands; those sync clauses remain
generated-child completion forms in the shipped surface and now fail with a
targeted ATL event-join diagnostic when they carry actor events.

Existing unqualified local forms are unchanged: `(await signal)` remains a
local transaction wait, and rule-level `(trigger transaction)` remains a
local transaction trigger.

Dotted enum-looking names that do not name a static actor instance or static
group keep their prior diagnostics. Dotted names that do name a static group
fail with the ATL group-endpoint diagnostic.

The regression suite specifically covers the accepted source-ordered
multi-event wait form through `isf/atl_trigger_batch_multi_wait_pipeline.isf`
and keeps repeated target waits outside that subset with the targeted
event re-arm/lifetime diagnostic.

Current actor-transaction trigger handoff subset: downstream producers may
emit a top-level transaction-body `(trigger actor.transaction)` against a
static actor instance either as a single handoff or as part of the exact
temporary trigger-batch subset documented above. Downstream producers may also
emit one top-level rule action `(trigger actor.transaction)` against a static
actor instance. The target transaction name must be a scalar HDL identifier.
FSMGen maps each accepted trigger to a one-cycle parent output named `actor_transaction_start`;
for example, `reader.capture` maps to `reader_capture_start`, and a rule
action `worker.process` maps to `worker_process_start`. The scheduled parent
`.fsm` exposes and pulses that output at the trigger point, either in the
single-trigger state, in the accepted grouped trigger state, or in the guarded
rule DT. The sink of that trigger is external in this subset.

Schedule JSON reports accepted triggers under
`actor_network.transaction_triggers[]`. Each entry exposes
`owner_transaction`, `context`, `instance`, `target_transaction`, `signal`,
and `sink`; the current sink is `external_handoff`.

Downstream producers must not emit nested qualified triggers, repeated
triggers to the same actor instance, repeated rule-action qualified triggers,
fan-in/fan-out trigger structures, generated handoff signal conflicts, trigger
payloads or bindings, ready/backpressure assumptions, cross-clock actor
triggers, concurrent group endpoints, or source that relies on generated ATL
child artifacts or generated ATL top wiring outside the explicitly shipped
resolved-child subset until the corresponding support is documented here and
advertised in the manifest. Rule-action `group.name` triggers remain in that
unsupported group-endpoint category and use the same targeted diagnostic as
transaction-body group triggers.

The generated-child actor-to-actor route now has focused generated-handoff
collision coverage. Downstream producers should treat parent-declared
collisions with the selected trigger, event, data, or named-drive request
handoff names as fail-closed input; FSMGen does not support handoff
remapping, route mux/storage, fan-in/fan-out, ready/backpressure, or payload
protocols for that route.

Normal downstream `.isf` source sees those generated-handoff collisions as
parser-owned failures. FSMGen also has a lowerer defensive backstop for
malformed or mutated scheduler-facing actor metadata, so generated-top wiring
cannot reuse, suppress, or shadow those same handoff names if metadata
bypasses normal parser finalization. This is a safety backstop only, not a
new source or report feature.

### 12.5.5. Generated-Child Route Terms And Boundaries

The mdBook has an audit-backed dedicated generated-child route terminology
section for these terms. Downstream consumers should treat that book section
and this handoff as the truth sources for current route support and explicit
non-support.

The documentation precision slice now makes that book section a term-by-term
support boundary. It does not change the downstream source surface,
schedule-report contract, generated artifact shape, or shipped ATL behavior.

For downstream implementation, the current route terms mean:

- Route lifetime is one named drive-call cycle.
- Generated handoffs are deterministic parent-visible signals such as
  `reader_payload`, `writer_payload`, `reader_capture_start`, `writer_emit_start`,
  `reader_done`, `writer_done`, and `forward_payload_start`.
- Handoff remapping is not shipped; collisions with authored parent interface
  or actor-owned storage names fail closed.
- Route muxing and route storage are not shipped; the selected route set has
  one source child, one sink child, one named drive call per route, no
  route-local selector, and no route-local storage.
- Fan-in and fan-out are not shipped for route triggers, events, or data.
- Ready/backpressure is not shipped; there is no ready signal, retry,
  buffering, or replay contract.
- Payload protocols are not shipped beyond the current exact-width
  drive-call-cycle handoff value. Vector routes preserve matching child
  endpoint widths; they do not define packing, framing, ready/valid, or retry
  semantics.
- Route endpoint expressions are not shipped. The route source must be the
  scalar endpoint `reader.payload`; a source expression such as
  `(+ reader.payload 1)` fails closed before expression movement, value
  transformation, width conversion, storage, or payload protocols are
  inferred. The route sink must likewise be the scalar endpoint
  `writer.payload`; a sink expression such as `(+ writer.payload 1)` fails
  closed before expression destinations, route-side transforms, width
  conversion, storage, or payload protocols are inferred.
- The route sink-expression diagnostic is source-order independent for
  endpoint-looking route sinks. If a drive body appears before the relevant
  `(instance ...)` clauses, FSMGen defers that malformed ATL-looking sink
  expression until the full actor instance set is known, then reports the same
  ATL sink-expression diagnostic. Ordinary malformed local drive targets such
  as `((out) 1)` keep the generic drive-body scalar-head diagnostic.
- The route source-expression diagnostic is source-order independent for
  endpoint-looking route sources. If a drive body appears before the relevant
  `(instance ...)` clauses, FSMGen defers that malformed ATL-looking source
  expression until the full actor instance set is known, then reports the same
  ATL source-expression diagnostic. This does not select expression movement
  or payload behavior.
- The accepted actor-to-actor route is also source-order independent. A named route
  drive such as `forward_payload` may appear before or after the relevant
  direct static actor instances; FSMGen resolves the same scalar
  `reader.payload` to `writer.payload` route after the full actor body is
  parsed, emits the same generated ATL top handoffs, and reports the same
  `actor_network.data_movements[]` metadata.

### 12.5.6. Generated Child Artifacts And Top Data Routes

Current generated-artifact contract: the parent scheduled `.fsm` may include
the selected one-bit actor-event handoff input, selected one-cycle
actor-transaction trigger output, selected scalar data-movement handoff
ports, and selected same-cycle trigger-batch handoff outputs.

Resolved library-qualified ATL instances also emit child scheduled `.fsm`
artifacts.

FSMGen now emits generated ATL tops for the selected one-resolved-child
trigger/event subset and the selected two-resolved-child control-only
trigger/event subset, reporting them through
`actor_network.generated_tops[]`.

FSMGen still emits no generated ATL route mux, data-route storage,
generated-child data wiring beyond the selected one-child scalar and
exact-width vector pin-ingress routes, selected one-child scalar and
exact-width vector pin-egress routes, selected same-child mixed scalar/vector
pin-ingress and pin-egress route sets, and selected same-source/same-sink
scalar or exact-width vector two-child actor-to-actor route set, CDC child
wiring, payload/ready/backpressure binding, or broader HDL event wiring.

The selected generated-child actor-to-actor data route set is shipped only for
same-source/same-sink two-child shapes that use qualified trigger/event
handoffs, one named drive-call cycle per route, deterministic generated
handoffs, and matching source-output/sink-input endpoint widths. Malformed
routes or mismatched-width route shapes still fail closed before FSMGen infers
remapping, storage, muxing, fan-in/fan-out, payload adaptation, or
backpressure behavior.

The selected generated-child actor-to-actor data route remains bounded by a
simple parent input start boundary and a simple parent output completion
boundary. Output-as-start, input-as-completion, undeclared, and wider
boundary pins are targeted fail-closed cases before downstream producers can
rely on interface remapping, activation fan-in, completion fan-out, boundary
expressions, route storage, route muxing, ready/backpressure, or payload
protocols.

Downstream consumers must treat `actor_network` as discovery/review metadata
plus the explicitly reported `event_waits[]`, `transaction_triggers[]`,
`data_movements[]`, `association_schedules[]`, `group_schedules[]`, and
`generated_tops[]` entries until a later task-tree leaf documents broader
generated artifact names and report keys in this handoff.

The HDL promotion slice does not change downstream source or report
requirements: the already shipped `isf/atl_resolved_child_pipeline.isf`
generated top now has plain and strict CLI SystemVerilog coverage proving the
generated top, parent, child, and selected internal trigger/event links.

Downstream producers should not infer any broader ATL HDL wiring from that
coverage.

The first generated-child data slice is now shipped:
`isf/atl_resolved_child_pin_ingress_pipeline.isf` wires one scalar
`(worker.payload pins.payload)` route into one resolved child through the
generated top.

Downstream consumers should read the public route evidence from
`actor_network.data_movements[]` and the generated-top discovery evidence
from `actor_network.generated_tops[]`; no new public report family is
exposed.

The generated child `.fsm` carries generated `+interface` role metadata for
the selected child input so HDL generation preserves the child `payload`
port.

The exact-width vector generated-child pin-ingress leaf is also shipped:
`isf/atl_resolved_child_pin_ingress_vector_pipeline.isf` wires one vector
`(worker.payload pins.payload)` route from a top-level input pin through the
parent and generated top into one resolved child input.

Downstream producers may emit that route only when the source is a declared
top-level input pin, the sink is a resolved child input endpoint, and the two
endpoint widths are the same positive value.

Downstream consumers should read the public route evidence from
`actor_network.data_movements[]` with
`kind: "vector_pin_to_actor_handoff"`, `width` equal to the endpoint width,
and
`width_source: "top_level_input_pin_resolved_child_endpoint_exact_width"`.
Generated-top discovery remains in `actor_network.generated_tops[]`; the
private generated-top data-link list is still not a public report family.

Width mismatch fails before scheduled `.fsm` emission. Downstream producers
must not rely on width adaptation, packing, truncation, extension, slicing,
route mux/storage, fan-in/fan-out, ready/backpressure, payload protocols, or
mixed scalar/vector route behavior from this one-route vector leaf.

The exact-width vector multi-route extension of that same pin-ingress
generated top is now shipped:
`isf/atl_resolved_child_pin_ingress_vector_multi_pipeline.isf` wires
`(worker.payload pins.payload)` and `(worker.sideband pins.sideband)` through
one resolved child and one parent transaction at route-local widths 8 and 4.

Downstream producers may emit multiple named vector pin-ingress drive bodies
in the same parent transaction only when all routes target the same resolved
child, each route has a matching top-level input pin and child input width,
source pins and child inputs are unique, and drive calls are adjacent before
the child trigger. Downstream consumers should read each route from
`actor_network.data_movements[]` as `vector_pin_to_actor_handoff` with
`width_source: "top_level_input_pin_resolved_child_endpoint_exact_width"`.
Broader mixed scalar/vector route sets outside the bounded pin-ingress subset
below and width adaptation remain unshipped.

The mixed scalar/vector pin-ingress extension of that same generated top is
now shipped:
`isf/atl_resolved_child_pin_ingress_mixed_pipeline.isf` wires
`(worker.payload pins.payload)` and `(worker.valid pins.valid)` through one
resolved child and one parent transaction. `payload` is an exact-width vector
route at width 8; `valid` is a scalar one-bit route.

Downstream producers may emit mixed scalar/vector pin-ingress drive bodies in
the same parent transaction only when all routes target the same resolved
child, every route uses a unique top-level input pin and child input endpoint,
vector route widths match exactly, scalar routes are one bit, and drive calls
are adjacent before the child trigger. Downstream consumers should read each
route from `actor_network.data_movements[]` with route-local `kind`, `width`,
and `width_source` values: `vector_pin_to_actor_handoff` plus
`top_level_input_pin_resolved_child_endpoint_exact_width` for vector routes,
and `scalar_pin_to_actor_handoff` plus `top_level_pin_scalar_one_bit` for
scalar routes. Width adaptation remains unshipped.

The bounded multi-route extension of that same pin-ingress generated top is now
shipped: `isf/atl_resolved_child_pin_ingress_multi_pipeline.isf` wires
`(worker.payload pins.payload)` and `(worker.sideband pins.sideband)` through
one resolved child and one parent transaction.

Downstream producers may emit multiple named scalar pin-ingress drive bodies in
the same parent transaction only when all routes target the same resolved child,
use one scalar `(child.endpoint pins.input_pin)` endpoint pair per drive body,
have unique top-level input pins and unique child input endpoints, and are
activated by adjacent argument-free top-level drive calls before the child
trigger/event wait sequence.

Downstream consumers still read every public route from
`actor_network.data_movements[]` with `kind: "scalar_pin_to_actor_handoff"` and
still discover the generated top through `actor_network.generated_tops[]`. No
new report family or public `data_links` key is exposed.

The inverse generated-child data slice is also shipped:
`isf/atl_resolved_child_pin_egress_pipeline.isf` wires one scalar
`(pins.result worker.payload)` route from one resolved child output through
the generated top to one top-level output.

Downstream consumers should read the public route evidence from
`actor_network.data_movements[]` and the generated-top discovery evidence
from `actor_network.generated_tops[]`; no new public report family is
exposed.

The generated child `.fsm` carries generated `+interface` role metadata for
the selected child output so HDL generation preserves the child `payload`
port.

The exact-width vector generated-child pin-egress leaf is also shipped:
`isf/atl_resolved_child_pin_egress_vector_pipeline.isf` wires one vector
`(pins.result worker.payload)` route from one resolved child output through
the parent and generated top to one top-level output pin.

Downstream producers may emit that one-route form when the source is a
resolved child output endpoint, the sink is a declared top-level output pin,
and the two endpoint widths are the same positive value.

Downstream consumers should read the public route evidence from
`actor_network.data_movements[]` with
`kind: "vector_actor_to_pin_handoff"`, `width` equal to the endpoint width,
and
`width_source: "top_level_output_pin_resolved_child_endpoint_exact_width"`.
Generated-top discovery remains in `actor_network.generated_tops[]`; the
private generated-top data-link list is still not a public report family.

Width mismatch fails before scheduled `.fsm` emission. Downstream producers
must not rely on width adaptation, packing, truncation, extension, slicing,
route mux/storage, fan-in/fan-out, ready/backpressure, payload protocols, or
mixed scalar/vector route behavior from this one-route vector leaf.

The exact-width vector generated-child pin-egress multi-route leaf is also
shipped:
`isf/atl_resolved_child_pin_egress_vector_multi_pipeline.isf` wires
`(pins.result worker.payload)` at width 8 and
`(pins.status worker.status)` at width 4 from one resolved child through the
parent and generated top to two top-level output pins.

Downstream producers may emit that route-set form only when every route shares
the same resolved child and parent transaction, each route has one
argument-free drive call, the drive calls are adjacent after the child event
wait, child output endpoints and top-level output pins are unique across the
set, and every child-output/top-output pair has the same positive width.

Downstream consumers should read each route as a separate
`actor_network.data_movements[]` entry with
`kind: "vector_actor_to_pin_handoff"` and
`width_source: "top_level_output_pin_resolved_child_endpoint_exact_width"`.
Generated-top discovery remains in `actor_network.generated_tops[]`; private
generated-top data links remain out of the public report contract.

The mixed scalar/vector pin-egress extension of that same generated top is now
shipped:
`isf/atl_resolved_child_pin_egress_mixed_pipeline.isf` wires
`(pins.result worker.payload)` and `(pins.valid worker.valid)` through one
resolved child and one parent transaction. `result` is an exact-width vector
route at width 8; `valid` is a scalar one-bit route.

Downstream producers may emit mixed scalar/vector pin-egress drive bodies in
the same parent transaction only when all routes source the same resolved
child, every route uses a unique child output endpoint and top-level output
pin, vector route widths match exactly, scalar routes are one bit, and drive
calls are adjacent after the child event wait. Downstream consumers should read
each route from `actor_network.data_movements[]` with route-local `kind`,
`width`, and `width_source` values: `vector_actor_to_pin_handoff` plus
`top_level_output_pin_resolved_child_endpoint_exact_width` for vector routes,
and `scalar_actor_to_pin_handoff` plus `top_level_output_pin_scalar_one_bit`
for scalar routes. Width adaptation remains unshipped.

The first two-child generated-top data-free slice is also shipped:
`isf/atl_two_child_pipeline.isf` emits parent, reader, writer, and generated
top `.fsm` artifacts for sequential `reader.capture`/`reader.done` then
`writer.emit`/`writer.done` handoffs.

Downstream consumers should read the resolved child metadata from
`actor_network.instances[]`, trigger evidence from
`actor_network.transaction_triggers[]`, event evidence from
`actor_network.event_waits[]`, and the generated-top discovery plus per-child
wiring metadata from `actor_network.generated_tops[].children[]`.

The selected resolved-child trigger-batch generated-top slice is also
shipped: `isf/atl_two_child_trigger_batch_pipeline.isf` emits parent, reader,
writer, and generated top `.fsm` artifacts for one contiguous same-cycle
trigger batch over `reader.capture` and `writer.emit`, followed by
source-ordered waits on `reader.done` and `writer.done`.

Downstream producers may emit that exact form only when there are exactly two
resolved children, no static group declaration, no ATL data movement in the
transaction segment, and no repeated child activations or waits. Downstream
consumers should read trigger evidence from
`actor_network.transaction_triggers[]`, wait evidence from
`actor_network.event_waits[]`, task-scoped temporary association evidence from
`actor_network.association_schedules[]`, schema-version-1 compatibility
schedule evidence from `actor_network.group_schedules[]`, and generated-top
discovery from `actor_network.generated_tops[]` with kind
`resolved_children_trigger_batch_event_sequence`.

The first generated-child actor-to-actor route through that generated top is
shipped by `isf/atl_two_child_data_pipeline.isf`.

Downstream producers may emit one named drive body pair `(writer.payload
reader.payload)` between two resolved children when the parent transaction is
ordered as `trigger reader.capture`, `await reader.done`, `drive
forward_payload`, `trigger writer.emit`, `await writer.done`, then complete.

The parent exposes `reader_payload` as the generated source handoff input and
`writer_payload` as the generated sink handoff output; the generated top
wires `reader.payload` to parent `reader_payload` and parent `writer_payload`
to `writer.payload`.

Downstream consumers should read one-bit route provenance from
`actor_network.data_movements[]` with `kind: "scalar_actor_handoff"` and
generated-top discovery from `actor_network.generated_tops[]` with
`children[]`.

No new report family or public `data_links` key is exposed.

The exact-width vector generated-child actor-to-actor route is shipped by
`isf/atl_two_child_vector_data_pipeline.isf`.

Downstream producers may emit the same `(sink source)` drive-body pair between
two resolved children when the source endpoint is a child output, the sink
endpoint is a child input, and both endpoint declarations have the same
positive width. The parent source handoff, parent sink handoff, child
interface roles, generated top links, and generated HDL links use that exact
width. Schedule JSON keeps the same route entry shape and reports
`kind: "vector_actor_handoff"`, `width` equal to the endpoint width, and
`width_source: "resolved_child_endpoint_exact_width"`.

The bounded multi-route form is shipped by
`isf/atl_two_child_multi_data_pipeline.isf`.

Downstream producers may emit multiple named actor-to-actor drive bodies in
the same parent transaction only when all routes share the same resolved source
child, the same resolved sink child, one direct endpoint pair per drive body,
matching source/sink endpoint widths for each route, and one argument-free
top-level drive call per route.

The accepted route segment is contiguous: source trigger, source event wait,
all route drive calls, sink trigger, sink event wait. The shipped fixture moves
`payload` and `sideband` from `reader` to `writer` through separate route drive
calls and separate generated parent handoffs.

Downstream consumers still read every route from
`actor_network.data_movements[]`: scalar one-bit routes use
`kind: "scalar_actor_handoff"`, and exact-width vector routes use
`kind: "vector_actor_handoff"`. Generated-top discovery still uses
`actor_network.generated_tops[]` with `children[]`. No new report family or
public `data_links` key is exposed.

Downstream producers must still treat broader actor-to-actor generated-child
routes, fan-in/fan-out source or sink sets, width adaptation, route
mux/storage, CDC/reset remapping, ready/backpressure, payload protocols,
recursive actor networks, repeated triggers, trigger-batch plus data movement
coupling, groups, cross-transaction continuation, and permanent actor grouping
as deferred. A shipped route segment fails closed if
its drive calls do not follow the source event wait and precede the sink
trigger.

Downstream producers must also keep the route drive unparameterized and the
route drive call argument-free. Parameterized route drive definitions and
route drive calls with actual arguments remain fail-closed before drive
actual binding, expression movement, or payload protocols are inferred.
That same route-drive argument boundary applies to the shipped generated-top
pin-ingress and pin-egress route families; route drive calls are one-cycle
timing points, not parameterized payload-binding calls.

The route source must remain one scalar endpoint. A drive-body source
expression such as `(writer.payload (+ reader.payload 1))` remains
fail-closed before FSMGen infers expression movement, payload transformation,
storage, muxing, or backpressure behavior.

The shipped FSMGen hardening around this route keeps the downstream surface
bounded.

It adds focused fail-closed coverage for adjacent invalid shapes: the source
endpoint must be a scalar output on the source child, the sink endpoint must
be a scalar input on the sink child, every selected route drive body must
contain exactly one endpoint pair, and each route must be activated by exactly
one top-level drive call.

Downstream producers should keep emitting only the shipped same-source,
same-sink scalar or exact-width vector route set until a later spec update
explicitly widens the contract.

The shipped width hardening now accepts same-width generated-child
actor-to-actor routes. Wider source child outputs paired with one-bit sink
inputs, one-bit source outputs paired with wider sink inputs, and any other
source/sink width mismatch remain fail-closed. Downstream producers should not
assume truncation, extension, packing, slicing, payload protocols, muxing, or
storage insertion.

The shipped clock/reset hardening keeps the generated-child actor-to-actor
route in one parent clock/reset policy.

Source or sink child clock/reset mismatches fail closed until FSMGen
publishes an explicit CDC bridge or reset-remapping contract; downstream
producers should not assume generated system-port remapping, async crossing
logic, route storage, muxing, or backpressure insertion.

The shipped self-route hardening keeps the generated-child actor-to-actor
route between two distinct resolved children.

Same-child source/sink route pairs fail closed; downstream producers should
not assume self-route, loopback, child-internal bypass, storage, muxing,
fan-in/fan-out, backpressure, or payload insertion until FSMGen publishes an
explicit contract for those behaviors.

The shipped repeated-trigger hardening keeps the route sequence to one
source-child trigger and one sink-child trigger.

Extra route-child triggers fail closed; downstream producers should not
assume repeated activation, restart, pending-request merging, trigger
fan-in/fan-out, or multi-activation scheduling until FSMGen publishes an
explicit contract for those behaviors.

The shipped repeated-wait hardening keeps the same route sequence to one
source-child event wait and one sink-child event wait.

Extra route-child waits fail closed; downstream producers should not assume
event fan-in/fan-out, repeated wait sequencing, child replay, route-level
wait storage, muxing, backpressure, or payload insertion until FSMGen
publishes an explicit contract for those behaviors.

The shipped same-parent-transaction hardening keeps the entire route sequence
inside one parent transaction.

Downstream producers must not split the source trigger, source wait, data
drive call, sink trigger, and sink wait across multiple parent transactions
or assume route continuation, pending handoff storage, transaction
rendezvous, cross-transaction scheduling, muxing, backpressure, or payload
insertion until FSMGen publishes an explicit contract for those behaviors.

The shipped sink-trigger ordering hardening keeps the route data drive call
before the sink child trigger.

Downstream producers must not trigger the sink child before the drive call or
assume speculative sink activation, delayed payload delivery, route storage,
muxing, backpressure, or payload insertion until FSMGen publishes an explicit
contract for those behaviors.

The shipped sink-event-wait ordering hardening keeps the sink child event
wait after the sink child trigger.

Downstream producers must not wait on the sink child event before triggering
that child or assume pre-trigger acknowledgement, sticky event sampling,
event replay, route storage, muxing, backpressure, or payload insertion until
FSMGen publishes an explicit contract for those behaviors.

The shipped source-event-wait ordering hardening keeps the source child event
wait after the source child trigger.

Downstream producers must not wait on the source child event before
triggering that child or assume pre-trigger acknowledgement, sticky event
sampling, event replay, route storage, muxing, backpressure, or payload
insertion until FSMGen publishes an explicit contract for those behaviors.

The shipped route-contiguity hardening keeps the same route as one contiguous
transaction-body segment.

Downstream producers must not interleave unrelated parent transaction clauses
between the source trigger, source event wait, data drive call, sink trigger,
and sink event wait or assume interleaved parent work, local side effects,
pre/post route sampling, route continuation, pending handoff storage, muxing,
backpressure, or payload insertion until FSMGen publishes an explicit
contract for those behaviors.

The shipped route-isolation hardening keeps that contiguous segment as the
only executable parent transaction-body work between the transaction start
condition and completion.

Downstream producers must not emit unrelated parent clauses before the source
trigger or after the sink event wait, or assume pre-route setup, post-route
sampling, local side effects, cleanup work, route continuation, pending
handoff storage, muxing, backpressure, or payload insertion until FSMGen
publishes an explicit contract for those behaviors.

The shipped route-boundary cardinality hardening keeps that isolated route
bounded by exactly one simple `(on ...)` start condition and exactly one
simple `(complete ...)` completion pulse.

Downstream producers must not emit extra start boundaries or extra completion
boundaries around the route, or assume activation fan-in, completion fan-out,
start-condition arbitration, local setup/cleanup, route continuation, pending
handoff storage, muxing, backpressure, or payload insertion until FSMGen
publishes an explicit contract for those behaviors.

The shipped boundary-simplicity hardening keeps those two route boundaries
body-free.

Downstream producers must not emit `(on ...)` activation-body samples or
`(complete ...)` extra payload operands around the route, or assume
activation-body sampling, completion payload/fan-out, local setup/cleanup,
route continuation, pending handoff storage, muxing, backpressure, or payload
insertion until FSMGen publishes an explicit contract for those behaviors.

## 13. Scheduled `.fsm` Review Artifact

Downstream tools should treat the scheduled `.fsm` files as review artifacts
and as the input to FSMGen's HDL backend, not as a general stable AST API.
Stable machine consumption should prefer the schedule JSON and manifest key
families.

Important `.fsm` lowering conventions:

- Every accepted transaction lowers to explicit state blocks.
- Drives and rules lower to non-state DT blocks.
- `=` is combinational.
- `<-`, `<=`, and `<1` are sequential/operator families in the public contract.
- `<1` is used for one-cycle delayed pulses such as completion and rule
  trigger sources.
- Generated top files use canonical Lisp-ish `?wiring` links.
- Multi-domain accepted event-crossing actors emit domain `.fsm` artifacts, a
  generated top `.fsm`, and generated CDC child interface metadata.
- Multiple accepted event crossings in one actor emit one generated CDC child
  interface and one report entry per crossing.

Deterministic DT ordering:

```text
transaction and rule DT blocks keep construction order;
generated rule-trigger fan-in DT blocks follow rule DTs by transaction name;
hash-backed drive DT blocks are sorted lexically by drive name
```

## 14. Schedule JSON Report

`--emit-schedule-json` and `FSM::Scheduler::ISF->report(...)` expose the
bounded schedule report. Top-level keys currently advertised:

```text
schema_version
source
scheduled_fsm
clock
reset
watchdog
actor_phases
actor_stages
verification_observations
actor_params
actor_constants
port_count
inputs
outputs
state_count
inferred_storage
transactions
transaction_waits
transaction_loops
loop_early_exits
transaction_stages
temporal_contracts
bank_accesses
transaction_port_bindings
dt_blocks
actor_network
generated_composition
library_uses
compatible_fanin_groups
priority_resolutions
resource_arbitration
compile_issues
clock_domains
crossings
```

Generated names in reports and generated artifacts are deterministic for the
same source and FSMGen version. They can be used as report-local or
artifact-local identifiers when another public field explicitly references the
same name. They are not a semantic string grammar for downstream tools to
parse. Downstream consumers should use explicit bounded fields such as
`owner`, `owner_kind`, `role`, `kind`, `instance`, `parent_port`,
`child_port`, `trigger_source`, `payload_source`, storage `role`, and
generated-composition summaries. Before the whole schedule JSON schema is
frozen, generated spelling may change only in a feature-scoped slice that also
updates docs, contract metadata where applicable, and tests.

Schedule-report evolution rules:

- New top-level keys, new nested optional keys, and new advertised value-family
  members are additive only when the same slice updates public contract
  metadata, focused tests, this handoff, and the book/spec.
- Removing an advertised key, renaming a key, changing required/optional
  status, changing a value type, or changing an advertised value's meaning is
  breaking.
- Breaking schedule-report changes require a `schema_version` bump and
  migration or deprecation documentation in the same slice.
- Deprecated fields stay documented until the schema version that removes them.

Actor-level passive observation metadata is report-only. The accepted source
form is `(observe NAME (role passive_monitor) (signals SIG...))`, where
`SIG...` must name public actor interface signals in a single-clock actor.
Downstream consumers may read `verification_observations[]` to discover
authored passive monitor intent, inherited clock/reset context, and
source-ordered signal `name`/`direction`/`width` summaries. They must not infer
generated `.fsm`, HDL, UVM, VHDL, scoreboard, coverage, or VIP artifacts from
that schedule metadata alone. Current releases also expose the first explicit
verification-output surface as `--emit-verification-output uvm-passive-monitor
--verification-outdir DIR source.isf`, with artifacts under `DIR/uvm/` and a
`DIR/verification-output-manifest.json` manifest. That explicit mode consumes
passive `verification_observations[]` to emit an inert UVM passive-monitor
skeleton; it does not widen the schedule/check/semantic JSON surfaces and does
not claim UVM compile support. The sibling VHDL verification-output mode is
`--emit-verification-output vhdl-observation-package --verification-outdir DIR
source.isf`, with artifacts under `DIR/vhdl/` and the same
`DIR/verification-output-manifest.json` manifest. Downstream tools may inspect
the inert observation constants and manifest metadata, but they must not treat
the artifact as a VHDL syntax/compile/PSL/simulation/formal/analyzer result or
as scoreboard, coverage, reusable VIP, direct IAL2, schedule JSON, check JSON,
or semantic JSON behavior.

Direct `.ppif` verification-output generation is intentionally not selected
for the current lane. IAL2 sources remain reviewable through generated `.isf`
before generated `.fsm`; future protocol-specific checker, scoreboard,
coverage, or VIP work must first define how PPIF facts annotate or lower into
generated IAL1 verification metadata unless a later exact task-tree owner
proves that a direct IAL2 route is required.

Golden fixture matrix:

- `t/1255-isf-schedule-report-golden-matrix.t` is the executable matrix for
  the advertised schedule-report branches.
- Each matrix case runs through both `FSM::Scheduler::ISF->report(...)` and
  `./bin/fsmgen --emit-schedule-json`, and the test requires equal payloads.
- Every advertised `schedule_report_*` contract branch has a matrix owner
  where that branch is a schedule-report payload family.
- `schedule_report_full_schema_stable` is true for schedule JSON
  `schema_version: 1`.

Assignment and child-summary boundary:

- Raw assignment provenance, private assignment indexes, and activation proof
  internals are not public schedule-report fields.
- Public substitutes are bounded summaries: `compile_issues[]` source
  summaries, `compatible_fanin_groups[]`, `priority_resolutions[]`,
  `resource_arbitration[]`, `transaction_port_bindings[]`, `bank_accesses[]`,
  and aggregate counts such as `dt_blocks[].assignments`.
- Parent reports do not embed recursive child schedule reports. Public
  multi-file detail is the `lower(...)` files map, generated `.fsm` artifacts,
  `actor_network`, `generated_composition`, `library_uses[]`, and
  `clock_domains[]` / `crossings[]`.
- Downstream integrations should report bugs with the runnable source,
  command, bundle, and observed output. They do not need to classify whether a
  failure belongs to `.fsm`, `.isf`, private provenance, or generated child
  internals.

Scalar summaries:

- `schema_version`: integer `1` for the current schedule-report payload
  shape. This is separate from the
  `embedding.isf_public_interface.schema_version` contract metadata.
- `source`: report source basename derived from the actor name with `.isf`.
- `scheduled_fsm`: scheduled `.fsm` basename for the report scope. Multi-domain
  reports use the generated `<actor>_top.fsm` artifact.
- `clock`: actor/default-domain clock name; omitted legacy single-clock
  clocks report `clk`.
- `reset`: object with `name`, `kind`, and `polarity` for configured or
  defaulted legacy single-clock resets; null only when the selected
  default-domain reset is omitted in a `(clock-domains ...)` actor.
- `watchdog`: scalar watchdog limit; omitted watchdogs report `65535`; accepted
  actor-level actor constants, actor scalar parameters, and qualified imported
  package scalar constants report as resolved integers.
- `inputs`, `outputs`, `port_count`, `state_count`: non-negative integer
  counts. Multi-domain generated-top reports use `state_count == 0` and put
  domain-local counts in `clock_domains[]`.
- `compile_issues`: array; empty on successful reports without nonfatal
  issues.

Important entry key families:

```text
actor_constants[]: name, value
actor_phases[]: name, body
actor_stages[]: name, body
verification_observations[]: name, role, clock, reset, signals
verification_observations[].signals[]: name, direction, width
actor_params[]: name, value
inferred_storage[] required: name, kind
inferred_storage[] optional: role, type, type_kind, width, fields
inferred_storage[].fields[]: name, msb, lsb, width, access, reset, enum
transactions[]: name, states, count
transaction_waits[]: transaction, cycles, count_kind, count_source,
  entry_state, exit_state, counter_signal, counter_width
transaction_loops[]: transaction, kind, condition, entry_state,
  decision_states, body_start, body_states, exit_state, body_clause_count
loop_early_exits[]: transaction, kind (exit_when|continue_when), state,
  condition, target
transaction_stages[]: transaction, name, kind, state, ready, valid
temporal_contracts[]: transaction, name, kind, trigger, signal,
  within_cycles, pending_signal, counter_signal, fail_signal,
  overlap_policy, reset_policy, assertion_projection
bank_accesses[]: kind, owner, owner_kind, container_kind, container_name,
  bank, index, width, depth, scalar_entries, same_cycle_policy, value, target
transaction_port_bindings[]: site_kind, owner, owner_kind, target_transaction,
  role, port, actor_signal, actor_expression, actor_endpoint_kind,
  binding_timing, authored_timing_mode, width, instance, parent_port,
  child_port, start_signal, done_signal, trigger_source, payload_source
dt_blocks[]: name, kind, assignments
actor_network: kind, instances, groups, association_schedules,
  group_schedules, data_movements, event_waits, transaction_triggers
actor_network.instances[]: name, actor_type, declaration
actor_network instance declaration values: actor, instance_alias
resolved actor_network.instances[] child-artifact metadata keys:
type_resolution, library, alias, export, module, scheduled_fsm
actor_network.groups[]: name, members, mode, declaration, source, scheduling
actor_network.association_schedules[]: association, kind, lifetime,
  owner_transaction, context, members, target_transactions, signals, schedule,
  dependency_policy, storage, source, sink
actor_network.group_schedules[]: group, owner_transaction, context, members,
  target_transactions, signals, schedule, dependency_policy, storage, source,
  sink
actor_network.event_waits[]: transaction, context, instance, event, signal,
  source
actor_network.transaction_triggers[]: owner_transaction, context, instance,
  target_transaction, signal, sink
library_uses[]: library, alias, export, kind, instance, module,
  scheduled_fsm, parameters, bindings
clock_domains[]: name, default, clock, reset, scheduled_fsm, ports, storage,
  transactions, rules, library_uses, child_instances, crossings, state_count,
  dt_block_count
crossings[]: name, kind, source_domain, source_signal, destination_domain,
  destination_signal, ready_signal, instance, module, outstanding_policy,
  payload, top_fsm
```

Generated composition summary:

```text
generated_composition required keys:
  kind, top_module, top_fsm, parent, children, instances

parent keys:
  module, scheduled_fsm

children[] keys:
  transaction, module, scheduled_fsm, parameters

children[].parameters[] keys:
  name, default

instances[] keys:
  instance, child, activation_kind, start, done, parameter_bindings,
  drive_handoffs

parameter_bindings[] keys:
  name, source, value

drive_handoffs[] keys:
  drive, request, payloads

payloads[] keys:
  parameter, child_port, parent_port, width
```

Known value families:

```text
reset.kind: async, sync
reset.polarity: active_high, active_low
transaction_waits.count_kind: static, runtime_scalar, runtime_expression
transaction_stages.kind: ready_valid_barrier
temporal_contracts.kind: bounded_eventually
temporal_contracts.overlap_policy: fail
temporal_contracts.assertion_projection: systemverilog_sticky_fail
bank_accesses.kind: store, load
bank_accesses.same_cycle_policy: read_before_write
transaction_port_bindings.site_kind: do, spawn, rule_trigger
transaction_port_bindings.actor_endpoint_kind: signal, literal, expression
transaction_port_bindings.binding_timing: activation_region,
  generated_live_handoff, trigger_payload, done_guarded
transaction_port_bindings.authored_timing_mode: snapshot, live, or JSON null
generated_composition.kind: activation_generated_top, spawn_generated_top
inferred_storage.kind: counter, register
inferred_storage.role: activation_done_handoff, activation_start_handoff,
  actor_storage, atl_trigger_start_handoff, completion_pulse, data_register,
  dynamic_wait_counter, drive_payload, drive_request, extract_field,
  latency_counter, repeat_counter, resource_round_robin_pointer,
  rule_trigger_payload_source, rule_trigger_source, sample_alias,
  scheduler_error_status, temporal_contract_monitor, transaction_port,
  transaction_port_binding, trigger_done_observe, watchdog_counter
inferred_storage.type/type_kind: optional bounded authored type token and
  resolved top-level type kind for declared typed actor-owned storage
dt_blocks.kind: drive, do_port_binding, latency_counter, rule,
  rule_trigger_fanin, spawn_port_binding, temporal_contract_monitor,
  trigger_generated_activation
compile_issues.severity: warning
compile_issues.proof_status: not_doable
```

Report stability rules:

- A downstream tool may rely on the listed key families and value families.
- JSON null is used for non-applicable optional fields.
- `dt_blocks[].assignments` is a non-negative assignment count, not an
  assignment payload list.
- Transaction summaries are sorted lexically by transaction name.
- Each `transactions[].states` array preserves emitted scheduled `.fsm` state
  order for that transaction.
- The full schema may grow; do not reject unknown keys unless your integration
  deliberately chooses strict mode for its own version pin.
