
## 15. Diagnostics And Fail-Closed Policy

FSMGen must reject unsupported or malformed public ISF forms before emitting
misleading scheduled artifacts. Downstream tools should surface diagnostics as
source errors and should not assume a malformed form was partially accepted.

Required fail-closed examples:

- Unknown actor, transaction, rule, drive, storage, domain, or resource names
  where a declaration is required.
- Duplicate singleton actor clauses.
- Duplicate names in interfaces, drives, storage, rules, transactions,
  parameters, domains, imports, or instances.
- Unsupported transaction clause heads in a lowered context.
- Unsupported `(on ...)` body forms such as `(params ...)`.
- Rule triggers targeting unknown transactions.
- Direct/local rule-trigger output bindings.
- Literal-zero, actor-constant-zero, actor-parameter-zero, and
  same-transaction-parameter-zero divisor operands in shipped runtime
  division/modulo expression contexts.
- Watchdog limits that name actor-level transaction parameters,
  nested-control-flow transaction parameters, cross-transaction parameters,
  runtime interface signals, unknown symbolic names, arbitrary expressions,
  constants that resolve to zero, actor/transaction parameters that resolve to
  zero or non-scalar values, or distinct per-await limits in one transaction.
- Repeat counts that name cross-transaction parameters, unknown symbolic
  names, arbitrary expressions, malformed scalar tokens, actor/transaction
  parameters that resolve to non-scalar values, runtime names without width
  evidence, or statically zero bodies containing malformed child activation
  subclause syntax.
- Latency min/max bounds that name cross-transaction parameters, runtime
  interface signals, unknown symbolic names, arbitrary expressions, constants
  that resolve to zero, or actor/transaction parameters that resolve to zero
  or non-scalar values.
- Generated child activation overrides that change child transaction
  parameters consumed by repeat, wait, latency, or top-level await-local
  watchdog lowering. Same-value overrides are accepted; mismatches fail closed
  until per-activation static timing specialization is shipped.
- Generated child activation overrides that change child transaction
  parameters consumed by data-operation widths (`shift_left`, `shift_right`,
  `assemble`, `extract`). Same-value overrides are accepted; mismatches fail
  closed with a targeted `static-width parameter` diagnostic until
  per-activation data-op width specialization is shipped.
- Generated child activation overrides that change child transaction
  parameters consumed by transaction port widths
  (`(ports (input/output NAME (width PARAM)))`). Same-value overrides are
  accepted; mismatches fail closed with a targeted `static port-width
  parameter` diagnostic until per-activation transaction port width
  specialization is shipped.
- Cross-domain repeat-body `do`: a `(do TARGET (domain X))` annotation
  where the target transaction is in a different clock domain than the
  calling transaction now fails closed with a targeted "cross-domain
  repeat-body do remains deferred" diagnostic instead of the generic
  same-domain-feature `(params)` requirement message. Cross-domain do
  without the `(domain ...)` annotation still emits the generic
  clock-domain violation message. Cross-domain repeat-body do lowering
  itself remains backlog.
- Temporal contract windows that need activation-site override-specialized
  lowering beyond same-value generated child activation overrides,
  transaction parameters from other transactions, runtime interface signals,
  unknown symbolic names, arbitrary expressions,
  unknown or unqualified package constants, aggregate package constants,
  package member/item paths, ambiguous
  local-enum/package-constant spellings, constants that resolve to zero, or
  actor/transaction parameters that resolve to zero or non-scalar values.
- Direct cross-domain access without a shipped crossing primitive.
- Width mismatch where width evidence is known.
- Parameter override unknown names, duplicate names, symbolic values, and
  incompatible aggregate/list shapes.
- Unknown type aliases, `(width ...)` plus `(type ...)` on the same
  declaration, package import aliases, aggregate type aliases outside
  actor-owned storage variables, unknown aggregate members, out-of-range list
  indexes, aggregate storage member/item paths outside direct transaction
  `set` RHS values, direct transaction `set` target tokens, transaction
  condition scalar values or expression operands, transaction `switch`
  selectors or branch values, rule assignment target tokens, rule assignment
  RHS values/expression operands, rule guard scalar values/expression
  operands, drive target tokens, drive body RHS scalar values/expression
  operands, inline drive target tokens, inline drive assignment RHS scalar
  values/expression operands,

  or drive-call actual scalar values/expression operands, aggregate paths in
  expression operator position, subaggregate operands/updates, and enum
  member references outside the shipped actor-constant, actor parameter
  scalar default or aggregate/list default leaf, actor-constant-backed actor
  parameter default scalar or aggregate/list leaf, generated child transaction
  scalar parameter default or aggregate/list default leaf, scalar activation
  parameter override, activation aggregate/list override leaf,
  reusable-library use-site parameter override value or leaf, actor-static
  library use-site override value or leaf, package-constant-backed library
  use-site override value or leaf, transaction
  condition scalar value or expression operand, transaction `set` RHS
  scalar/expression operand, transaction `switch` selector/branch-value, rule
  guard scalar/expression operand, rule assignment RHS scalar/expression
  operand,

  drive body RHS scalar/expression operand, inline drive RHS
  scalar/expression operand, and drive-call actual scalar/expression-operand
  contexts.
- Unsupported raw `assign` compatibility forms. The removed transaction
  `(assign ...)` keyword has targeted migration guidance to existing explicit
  timing constructs; it is not accepted or auto-mapped.

Compatibility rule:

- Deprecated handshake metadata is validated for shape and ignored. It is not a
  public ready/valid lowering feature.

## 16. Conformance Fixtures And Checks

Representative shipped fixtures:

```text
isf/apb_requester.isf
isf/i2c_master.isf
isf/spi_master.isf
isf/spawn_parent.isf
isf/rule_resource_arbiter.isf
isf/full_featured.isf
isf/clock_domain_event_crossing.isf
isf/clock_domain_dual_event_crossing.isf
isf/clock_domain_no_reset_event_crossing.isf
isf/common/fifo.isf
isf/fifo_controller.isf
isf/fifo_data_path.isf
isf/fifo_library_use.isf
isf/atl_trigger_batch_pipeline.isf
isf/atl_data_route_pipeline.isf
isf/atl_pin_ingress_pipeline.isf
isf/atl_pin_egress_pipeline.isf
isf/atl_trigger_wait_pipeline.isf
isf/atl_trigger_batch_wait_pipeline.isf
isf/atl_trigger_batch_multi_wait_pipeline.isf
isf/atl_resolved_child_pipeline.isf
isf/atl_resolved_child_pin_ingress_pipeline.isf
isf/atl_resolved_child_pin_ingress_vector_pipeline.isf
isf/atl_resolved_child_pin_ingress_vector_multi_pipeline.isf
isf/atl_resolved_child_pin_ingress_mixed_pipeline.isf
isf/atl_resolved_child_pin_ingress_multi_pipeline.isf
isf/atl_resolved_child_pin_egress_pipeline.isf
isf/atl_resolved_child_pin_egress_vector_pipeline.isf
isf/atl_resolved_child_pin_egress_vector_multi_pipeline.isf
isf/atl_resolved_child_pin_egress_mixed_pipeline.isf
isf/atl_two_child_pipeline.isf
isf/atl_two_child_data_pipeline.isf
isf/atl_two_child_vector_data_pipeline.isf
isf/atl_two_child_multi_data_pipeline.isf
```

The SPI-like fixture and I2C-like fixture are bounded realistic examples, not
complete external protocol compliance suites.

SPI is covered by `t/1228-isf-spi-fixture-coverage.t`.

I2C is covered by `t/1309-isf-i2c-fixture-coverage.t`, which proves strict
schedule JSON parity, scheduled `.fsm` structure, plain and strict HDL
generation, switch-branch repeats, read-data shifting, sampled write-data bit
selection from `data[7]`, and no implicit `data_bit` input.

The burst-reader fixture is covered by `t/1310-isf-burst-fixture-coverage.t`,
which proves strict schedule JSON parity, scheduled `.fsm` structure, plain
and strict HDL generation, dynamic repeat counter storage, watchdog and
latency counter roles, sampled aliases, and completion/timeout pulse fan-in.

The UART-like transmit fixture is covered by
`t/1311-isf-uart-fixture-coverage.t`, which proves strict schedule JSON
parity, scheduled `.fsm` structure, plain and strict HDL generation,
sampled-byte LSB drive selection from `byte_data[0]`, known-width
`shift_right`, repeat counter storage, busy drive sequencing, and completion
pulse behavior.

The phase fixture is covered by `t/1312-isf-phase-fixture-coverage.t`, which
proves strict schedule JSON parity, scheduled `.fsm` structure, plain and
strict HDL generation, transaction phase pass-through states, no reusable
`done` drive storage, and delayed completion pulse behavior without claiming
runtime actor-level phase scheduling.

The switch fixture is covered by `t/1313-isf-switch-fixture-coverage.t`,
which proves strict schedule JSON parity, scheduled `.fsm` structure, plain
and strict HDL generation, sampled selector capture, explicit branch
dispatch, default fallthrough to completion, named-drive branch starts, and
delayed completion pulse behavior.

The when fixture is covered by `t/1314-isf-when-fixture-coverage.t`, which
proves strict schedule JSON parity, scheduled `.fsm` structure, plain and
strict HDL generation, entry drive setup, two conditional decision states,
multi-step true-body drives, false-path fallthrough, compatible named-drive
start fan-in, and delayed completion pulse behavior.

The generated-composition fixture is covered by
`t/1315-isf-generated-composition-fixture-coverage.t`, which proves strict
schedule JSON parity, strict `--outdir` file emission, generated top, parent,
and child scheduled `.fsm` artifacts, start/done handoffs, named-drive
request/payload handoffs, public input fanout, `await_all` synchronization,
and strict HDL generation for the generated top, parent, and child artifacts.

This is the representative downstream handoff path for spawned
generated-child composition; it is not a protocol compliance claim.

The rule/resource fixture is covered by
`t/1316-isf-rule-resource-fixture-coverage.t`, which proves strict schedule
JSON parity, scheduled `.fsm` structure, plain and strict HDL generation,
rule-over-transaction priority suppression, `rule_slot`/`priority` resource
metadata, lower-priority rule gating by a higher-priority rule, and delayed
completion pulse behavior.

Dedicated resource arbitration tests now cover the shipped priority arbiter
for `rule_slot`, `output_bundle`, `transaction_start`, and `storage_port`,
including explicit output-bundle member-list validation,
transaction-start trigger-user validation, storage-port storage-member
validation, and `resource_arbitration[].members` report evidence. They also
cover bounded `rule_slot`/`round_robin`, `output_bundle`/`round_robin`,
`transaction_start`/`round_robin`, and `storage_port`/`round_robin` grants,
generated pointer storage metadata, report projection, and fail-closed
unsupported round-robin combinations.
The fixture above remains a `rule_slot` fixture; it does not claim
weighted, token bucket, interface-bundle, named-drive, child-instance, or
broader round-robin resource support.

The ready/valid stage and assertion-property surfaces are covered by the live
stage and property tests: `t/1179-isf-phase-stage-boundary.t`,
`t/1223-isf-stage-lowering.t`, `t/1252-isf-actor-phase-stage-report.t`,
`t/1410-isf-assert-carrier.t`, `t/1411-isf-assert-emit.t`,
`t/1412-isf-property-implication.t`,
`t/1417-isf-property-sampled-value.t`, and
`t/1418-isf-property-window-range.t`. Together they cover ready/valid stage
lowering, phase/stage report projection, assertion carriers, SystemVerilog
assertion emission, implication properties, sampled-value properties, and
window-range property parsing/lowering.

This coverage proves the shipped top-level ready/valid stage substrate and
assertion-property path; it does not claim nested stages, nested contracts,
stage-local compute, full AXI Valid-Ready protocol monitoring, source-anchor
IAL2 reports, min/max temporal monitor implementation, or broader temporal
operators.

The FIFO datapath fixture is covered by
`t/1319-isf-fifo-datapath-fixture-coverage.t`, which proves strict schedule
JSON parity, scheduled `.fsm` structure, bounded `bank_accesses[]` metadata,
plain and strict HDL generation, scalarized `data_0` through `data_3` bank
storage, pointer-guarded accepted pushes, and pointer-guarded accepted pops.

This fixture covers the shipped depth-4 scalarized bank store/load surface;
it does not claim general memory-array HDL emission, write-first collision
behavior, bypassing, or arbitrary-depth parameterized FIFOs.

The FIFO controller fixture is covered by
`t/1320-isf-fifo-controller-fixture-coverage.t`, which proves strict schedule
JSON parity, scheduled `.fsm` structure, compatible same-value fan-in
metadata, plain and strict HDL generation, idle cycles, push-only, pop-only,
simultaneous push+pop occupancy updates, actor-maintained full/empty flags,
and 2-bit pointer wrap.

This fixture is controller-only; it does not claim data-bank storage or
`data_out` datapath transfer behavior.

The FIFO library fixture is covered by
`t/1321-isf-fifo-library-fixture-coverage.t`, which proves strict schedule
JSON parity, generated importer/child/top scheduled `.fsm` artifacts, strict
`--outdir` file emission, fixed parameter overrides, use-site bindings,
scalarized FIFO data entries, plain and strict generated-top HDL generation,
and generated top wiring for `isf/fifo_library_use.isf`.

The ATL temporary trigger-batch fixture is covered by
`t/1324-isf-atl-fixture-coverage.t`, which proves strict schedule JSON
parity, scheduled `.fsm` structure, one same-cycle external trigger-batch
state, per-target trigger handoffs, canonical `association_schedules[]`,
compatibility `group_schedules[]`, static actor-network report metadata, and
plain plus strict HDL generation for `isf/atl_trigger_batch_pipeline.isf`.

It intentionally does not declare a permanent `(group ...)` association.

The ATL scalar data-route fixture is covered by
`t/1325-isf-atl-data-route-fixture-coverage.t`, which proves strict schedule
JSON parity, scheduled `.fsm` structure, generated parent handoff ports
`producer_payload` and `consumer_payload`, one
`actor_network.data_movements[]` entry with route lifetime
`drive_call_cycle`, empty association/group schedule arrays, and plain plus
strict HDL generation for `isf/atl_data_route_pipeline.isf`.

It intentionally does not claim generated ATL children, generated ATL tops,
route mux/storage, trigger/data coupling, wider payloads, fan-in/fan-out,
CDC, ready/backpressure, or permanent actor grouping.

The ATL scalar pin-ingress fixture is covered by
`t/1326-isf-atl-pin-ingress-fixture-coverage.t`, which proves strict schedule
JSON parity, scheduled `.fsm` structure, the existing top-level input source
pin `payload`, generated actor handoff output `consumer_payload`, one
`actor_network.data_movements[]` entry with kind
`scalar_pin_to_actor_handoff`, empty association/group schedule arrays, and
plain plus strict HDL generation for `isf/atl_pin_ingress_pipeline.isf`.

It intentionally does not claim generated ATL children, generated ATL tops,
actor-to-pin egress, bidirectional pin movement, route mux/storage,
trigger/data coupling, wider payloads, fan-in/fan-out, CDC,
ready/backpressure, or permanent actor grouping.

The ATL scalar pin-egress fixture is covered by
`t/1327-isf-atl-pin-egress-fixture-coverage.t`, which proves strict schedule
JSON parity, scheduled `.fsm` structure, generated actor source handoff input
`producer_payload`, existing top-level output sink `result`, one
`actor_network.data_movements[]` entry with kind
`scalar_actor_to_pin_handoff`, empty association/group schedule arrays, and
plain plus strict HDL generation for `isf/atl_pin_egress_pipeline.isf`.

It intentionally does not claim generated ATL children, generated ATL tops,
bidirectional pin movement, route mux/storage, trigger/data coupling, wider
payloads, fan-in/fan-out, CDC, ready/backpressure, or permanent actor
grouping.

The ATL trigger-wait fixture is covered by
`t/1328-isf-atl-trigger-wait-fixture-coverage.t`, which proves strict
schedule JSON parity, scheduled `.fsm` structure, one `(trigger
worker.process)` parent output pulse, one `(await worker.done)` parent event
input wait, one `actor_network.transaction_triggers[]` entry, one
`actor_network.event_waits[]` entry, empty association/group/data-movement
arrays, and plain plus strict HDL generation for
`isf/atl_trigger_wait_pipeline.isf`.

It intentionally does not claim generated ATL children, generated ATL tops,
actor type resolution, HDL child wiring, temporary trigger-batch plus event
coupling, data movement coupling, fan-in/fan-out, CDC, ready/backpressure, or
permanent actor grouping.

The ATL trigger-batch wait fixture is covered by
`t/1329-isf-atl-trigger-batch-wait-fixture-coverage.t`, which proves strict
schedule JSON parity, scheduled `.fsm` structure, three same-cycle generated
trigger output pulses, one following `writer_done` event input wait,
`actor_network.association_schedules[]` temporary-association metadata,
`actor_network.group_schedules[]` compatibility metadata, one
`actor_network.event_waits[]` entry, empty data movement, and plain plus
strict HDL generation for `isf/atl_trigger_batch_wait_pipeline.isf`.

It intentionally does not claim generated ATL children, generated ATL tops,
actor type resolution, HDL child wiring, hidden multi-event fan-in joins, data
movement coupling, CDC, ready/backpressure, or permanent actor grouping.

The ATL trigger-batch multi-event wait fixture is covered by the same test. It
proves strict schedule JSON parity, scheduled `.fsm` structure, three
same-cycle generated trigger output pulses, three following source-ordered
event input waits (`reader_done`, `filter_done`, and `writer_done`), three
`actor_network.event_waits[]` entries, one task-scoped
`association_schedules[]` entry, one compatibility `group_schedules[]` entry,
empty data movement, and plain plus strict HDL generation for
`isf/atl_trigger_batch_multi_wait_pipeline.isf`.

It intentionally remains sequential parent-handoff orchestration and does not
claim hidden same-cycle actor-event joins, repeated waits to one actor, event
payloads, generated ATL child event wiring, data route coupling, CDC,
ready/backpressure, or permanent actor grouping. Repeated waits to one
triggered actor fail closed until an event re-arm or per-event lifetime
contract exists.

The ATL resolved-child fixture is covered by
`t/1330-isf-atl-resolved-child-fixture-coverage.t`, which proves strict
schedule JSON parity, exactly three lower-result artifacts
`atl_resolved_child_pipeline.fsm`, `atl_resolved_child_pipeline__worker.fsm`,
and `atl_resolved_child_pipeline_top.fsm`, resolved
`actor_network.instances[]` metadata for `worker`, one
`actor_network.transaction_triggers[]` entry, one
`actor_network.event_waits[]` entry, one `actor_network.generated_tops[]`
entry, and empty data/association/group schedule arrays for
`isf/atl_resolved_child_pipeline.isf`.

It also proves strict `--outdir` top emission and fail-closed diagnostics for
missing child transactions, non-scalar child activation, missing child event
outputs, and parent/child clock mismatches.

It intentionally does not claim multiple resolved children, trigger batches,
data-route coupling, route mux/storage, actor-event fan-in, CDC,
ready/backpressure, recursive actor networks, or permanent actor grouping.

The HDL promotion leaf keeps the same source and report contract and proves
this fixture through plain and strict CLI HDL generation, requiring the
emitted SystemVerilog to contain the generated top, scheduled parent,
resolved child, and selected internal trigger/event links.

The generated-child pin-ingress leaf extends that shipped downstream
contract: `isf/atl_resolved_child_pin_ingress_pipeline.isf` proves one
top-level input pin to one resolved child input through the generated top.

The same `t/1330-isf-atl-resolved-child-fixture-coverage.t` regression proves
strict schedule JSON parity, parent/child/top `.fsm` artifacts, generated
child input role preservation, plain and strict CLI HDL generation, and a
fail-closed missing child input diagnostic for that route.

The generated-child exact-width vector pin-ingress leaf extends that same
downstream contract: `isf/atl_resolved_child_pin_ingress_vector_pipeline.isf`
proves one vector top-level input pin to one vector input on the resolved
child through the generated top.

The same `t/1330-isf-atl-resolved-child-fixture-coverage.t` regression proves
strict schedule JSON parity, parent/child/top `.fsm` artifacts, one
`vector_pin_to_actor_handoff` `data_movements[]` entry, generated child input
role preservation at width 8, generated-top wiring for the exact-width route,
strict outdir materialization, plain plus strict CLI HDL generation, and a
fail-closed top-input/child-input width mismatch diagnostic.

The generated-child exact-width vector pin-ingress multi-route leaf extends
that same downstream contract:
`isf/atl_resolved_child_pin_ingress_vector_multi_pipeline.isf` proves multiple
vector top-level input pins to multiple vector inputs on one resolved child
through the generated top.

The same `t/1330-isf-atl-resolved-child-fixture-coverage.t` regression proves
strict schedule JSON parity, parent/child/top `.fsm` artifacts, two
`vector_pin_to_actor_handoff` `data_movements[]` entries, route-local widths
8 and 4, generated child input role preservation for both routed vector
signals, generated-top wiring for both exact-width handoffs, strict outdir
materialization, plain plus strict CLI HDL generation, and a fail-closed
route-local top-input/child-input width mismatch diagnostic.

The generated-child mixed scalar/vector pin-ingress route-set leaf extends that
same downstream contract:
`isf/atl_resolved_child_pin_ingress_mixed_pipeline.isf` proves one exact-width
vector top-level input pin and one scalar top-level input pin to matching
inputs on one resolved child through the generated top.

The same `t/1330-isf-atl-resolved-child-fixture-coverage.t` regression proves
strict schedule JSON parity, parent/child/top `.fsm` artifacts, one
`vector_pin_to_actor_handoff` entry, one `scalar_pin_to_actor_handoff` entry,
route-local widths 8 and 1, generated child input role preservation for both
routed signals, generated-top wiring for both handoffs, strict outdir
materialization, plain plus strict CLI HDL generation, and a fail-closed
route-local top-input/child-input width mismatch diagnostic for the vector
route.

The generated-child pin-ingress multi-route leaf extends that same downstream
contract: `isf/atl_resolved_child_pin_ingress_multi_pipeline.isf` proves
multiple top-level input pins to multiple inputs on one resolved child through
the generated top.

The same `t/1330-isf-atl-resolved-child-fixture-coverage.t` regression proves
strict schedule JSON parity, parent/child/top `.fsm` artifacts, two
`scalar_pin_to_actor_handoff` `data_movements[]` entries, generated child input
role preservation for both routed scalar signals, generated-top wiring for both
pin-ingress handoffs, strict outdir materialization, plain plus strict CLI HDL
generation, and fail-closed missing-input, interleaved-drive-call, and
duplicate-source-pin diagnostics for that route set.

The generated-child pin-egress leaf extends the same downstream contract:
`isf/atl_resolved_child_pin_egress_pipeline.isf` proves one resolved child
output to one top-level output pin through the generated top.

The same `t/1330-isf-atl-resolved-child-fixture-coverage.t` regression proves
strict schedule JSON parity, parent/child/top `.fsm` artifacts, generated
child output role preservation, plain and strict CLI HDL generation, a
fail-closed missing child output diagnostic, and a fail-closed pre-event
drive-order diagnostic for that route.

The generated-child exact-width vector pin-egress leaf extends that same
downstream contract:
`isf/atl_resolved_child_pin_egress_vector_pipeline.isf` proves one vector
output from one resolved child to one vector top-level output pin through the
generated top.

The same `t/1330-isf-atl-resolved-child-fixture-coverage.t` regression proves
strict schedule JSON parity, parent/child/top `.fsm` artifacts, one
`vector_actor_to_pin_handoff` `data_movements[]` entry, generated child output
role preservation at width 8, generated-top wiring for the exact-width route,
strict outdir materialization, plain plus strict CLI HDL generation, and a
fail-closed child-output/top-output width mismatch diagnostic.

The generated-child exact-width vector pin-egress multi-route leaf extends
that same downstream contract:
`isf/atl_resolved_child_pin_egress_vector_multi_pipeline.isf` proves multiple
vector outputs from one resolved child to multiple vector top-level output pins
through the generated top. The same regression proves strict schedule JSON
parity, parent/child/top `.fsm` artifacts, two
`vector_actor_to_pin_handoff` `data_movements[]` entries, generated child
output role preservation at widths 8 and 4, generated-top wiring for both
exact-width routes, strict outdir materialization, plain plus strict CLI HDL
generation, and fail-closed child-output/top-output width mismatch
diagnostics.

The generated-child mixed scalar/vector pin-egress route-set leaf extends that
same downstream contract:
`isf/atl_resolved_child_pin_egress_mixed_pipeline.isf` proves one exact-width
vector resolved child output and one scalar resolved child output to matching
top-level output pins through the generated top. The same regression proves
strict schedule JSON parity, parent/child/top `.fsm` artifacts, one
`vector_actor_to_pin_handoff` entry, one `scalar_actor_to_pin_handoff` entry,
route-local widths 8 and 1, generated child output role preservation for both
routed signals, generated-top wiring for both handoffs, strict outdir
materialization, plain plus strict CLI HDL generation, and a fail-closed
route-local child-output/top-output width mismatch diagnostic for the vector
route.

The generated-child pin-egress multi-route leaf extends that downstream
contract without adding new source syntax:
`isf/atl_resolved_child_pin_egress_multi_pipeline.isf` proves multiple one-bit
outputs from one resolved child to multiple one-bit top-level output pins
through the generated top. The same regression proves strict schedule JSON
parity, parent/child/top `.fsm` artifacts, two
`scalar_actor_to_pin_handoff` `data_movements[]` entries, generated child
output role preservation for both routed scalar signals, generated-top wiring
for both pin-egress handoffs, strict outdir materialization, plain plus strict
CLI HDL generation, and fail-closed missing-output, interleaved-drive-call,
and duplicate-output-pin diagnostics for that route set.

The same focused regression also covers `isf/atl_two_child_pipeline.isf`:
parent/reader/writer/top `.fsm` artifacts, strict schedule JSON parity,
nested generated-top `children[]` metadata, generated-top wiring, and plain
plus strict CLI HDL generation for the data-free two-child trigger/event
subset.

The same focused regression now also covers
`isf/atl_two_child_data_pipeline.isf`: parent/reader/writer/top `.fsm`
artifacts, strict schedule JSON parity, `scalar_actor_handoff`
`data_movements[]` metadata, nested generated-top `children[]` metadata,
reader output and writer input `+interface` preservation, generated-top
payload wiring, plain plus strict CLI HDL generation, missing sink payload
diagnostics, and wrong-order diagnostics for the selected two-child scalar
data route.

The same focused regression now also covers
`isf/atl_two_child_vector_data_pipeline.isf`: parent/reader/writer/top `.fsm`
artifacts, strict schedule JSON parity, strict outdir materialization,
8-bit parent source/sink handoff ports, 8-bit generated child payload ports,
generated-top wiring, plain plus strict CLI HDL generation, and
`vector_actor_handoff` `data_movements[]` metadata with
`width_source: "resolved_child_endpoint_exact_width"` for the selected
same-width two-child vector data route.

The same focused regression now also covers
`isf/atl_two_child_multi_data_pipeline.isf`: parent/reader/writer/top `.fsm`
artifacts, strict schedule JSON parity, two `scalar_actor_handoff`
`data_movements[]` entries for the same reader-to-writer route segment,
generated child `+interface` preservation for both routed scalar signals,
generated-top wiring for both route handoffs, strict outdir materialization,
and plain plus strict CLI HDL generation.

Recommended downstream smoke commands:

```bash
./bin/fsmgen --emit-schedule-json isf/apb_requester.isf
./bin/fsmgen --strict --emit-schedule-json isf/i2c_master.isf
./bin/fsmgen --strict --emit-schedule-json isf/burst_reader.isf
./bin/fsmgen --strict --emit-schedule-json isf/uart_tx.isf
./bin/fsmgen --strict --emit-schedule-json isf/phase_test.isf
./bin/fsmgen --strict --emit-schedule-json isf/switch_test.isf
./bin/fsmgen --strict --emit-schedule-json isf/when_test.isf
./bin/fsmgen --strict --emit-schedule-json isf/spawn_parent.isf
./bin/fsmgen --strict --emit-schedule-json isf/rule_resource_arbiter.isf
./bin/fsmgen --strict --emit-schedule-json isf/stream_stage_contract.isf
./bin/fsmgen --strict --emit-schedule-json isf/fifo_controller.isf
./bin/fsmgen --strict --emit-schedule-json isf/fifo_data_path.isf
./bin/fsmgen --strict --emit-schedule-json isf/fifo_library_use.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_trigger_batch_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_data_route_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_pin_ingress_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_pin_egress_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_trigger_wait_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_trigger_batch_wait_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_trigger_batch_multi_wait_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_resolved_child_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_resolved_child_pin_ingress_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_resolved_child_pin_ingress_vector_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_resolved_child_pin_ingress_vector_multi_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_resolved_child_pin_ingress_mixed_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_resolved_child_pin_ingress_multi_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_resolved_child_pin_egress_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_resolved_child_pin_egress_vector_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_resolved_child_pin_egress_vector_multi_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_resolved_child_pin_egress_mixed_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_two_child_data_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_two_child_vector_data_pipeline.isf
./bin/fsmgen --strict --emit-schedule-json isf/atl_two_child_multi_data_pipeline.isf
./bin/fsmgen --strict isf/apb_requester.isf
./bin/fsmgen --strict --outdir /tmp/isf-build isf/spawn_parent.isf
./bin/fsmgen --strict --outdir /tmp/isf-fifo-library isf/fifo_library_use.isf
./bin/fsmgen --strict --outdir /tmp/isf-atl-resolved-child isf/atl_resolved_child_pipeline.isf
./bin/fsmgen --strict --outdir /tmp/isf-atl-resolved-child-pin-ingress isf/atl_resolved_child_pin_ingress_pipeline.isf
./bin/fsmgen --strict --outdir /tmp/isf-atl-resolved-child-pin-ingress-vector isf/atl_resolved_child_pin_ingress_vector_pipeline.isf
./bin/fsmgen --strict --outdir /tmp/isf-atl-resolved-child-pin-ingress-vector-multi isf/atl_resolved_child_pin_ingress_vector_multi_pipeline.isf
./bin/fsmgen --strict --outdir /tmp/isf-atl-resolved-child-pin-ingress-mixed isf/atl_resolved_child_pin_ingress_mixed_pipeline.isf
./bin/fsmgen --strict --outdir /tmp/isf-atl-resolved-child-pin-ingress-multi isf/atl_resolved_child_pin_ingress_multi_pipeline.isf
./bin/fsmgen --strict --outdir /tmp/isf-atl-resolved-child-pin-egress isf/atl_resolved_child_pin_egress_pipeline.isf
./bin/fsmgen --strict --outdir /tmp/isf-atl-resolved-child-pin-egress-vector isf/atl_resolved_child_pin_egress_vector_pipeline.isf
./bin/fsmgen --strict --outdir /tmp/isf-atl-resolved-child-pin-egress-vector-multi isf/atl_resolved_child_pin_egress_vector_multi_pipeline.isf
./bin/fsmgen --strict --outdir /tmp/isf-atl-resolved-child-pin-egress-mixed isf/atl_resolved_child_pin_egress_mixed_pipeline.isf
./bin/fsmgen --strict --outdir /tmp/isf-atl-two-child-data isf/atl_two_child_data_pipeline.isf
./bin/fsmgen --strict --outdir /tmp/isf-atl-two-child-vector-data isf/atl_two_child_vector_data_pipeline.isf
./bin/fsmgen --strict --outdir /tmp/isf-atl-two-child-multi-data isf/atl_two_child_multi_data_pipeline.isf
./bin/fsmgen --emit-schedule-json isf/clock_domain_event_crossing.isf
./bin/fsmgen --outdir /tmp/isf-cdc isf/clock_domain_dual_event_crossing.isf
./bin/fsmgen --emit-schedule-json isf/clock_domain_no_reset_event_crossing.isf
./bin/fsmgen --capability-manifest
```

Recommended FSMGen regression commands for integration contract changes:

```bash
prove -Iperl t/1112-isf-public-interface-contract.t \
  t/1115-isf-public-interface-cli-manifest-audit.t \
  t/1120-isf-public-live-document-path-audit.t \
  t/1144-isf-public-tested-by-metadata-audit.t \
  t/1255-isf-schedule-report-golden-matrix.t \
  t/1257-isf-scalar-type-aliases.t \
  t/1258-isf-enum-member-constants.t \
  t/1259-isf-aggregate-storage-type-aliases.t \
  t/1260-isf-aggregate-storage-leaf-reads.t \
  t/1261-isf-aggregate-storage-leaf-writes.t \
  t/1262-isf-aggregate-storage-leaf-expression-reads.t \
  t/1263-isf-enum-member-set-values.t \
  t/1264-isf-enum-member-set-expression-values.t \
  t/1265-isf-enum-member-switch-branch-values.t \
  t/1266-isf-enum-member-drive-values.t \
  t/1267-isf-enum-member-drive-call-values.t \
  t/1268-isf-enum-member-drive-call-expression-values.t \
  t/1269-isf-enum-member-actor-params.t \
  t/1270-isf-enum-member-transaction-params.t \
  t/1271-isf-enum-member-activation-params.t \
  t/1272-isf-enum-member-rule-values.t \
  t/1273-isf-enum-member-rule-expression-values.t \
  t/1274-isf-enum-member-rule-guard-values.t \
  t/1275-isf-enum-member-condition-values.t \
  t/1276-isf-enum-member-activation-aggregate-params.t \
  t/1277-isf-enum-member-actor-aggregate-params.t \
  t/1278-isf-enum-member-transaction-aggregate-params.t \
  t/1279-isf-enum-member-inline-drive-values.t \
  t/1280-isf-enum-member-inline-drive-expression-values.t \
  t/1281-isf-enum-member-library-use-params.t \
  t/1282-isf-enum-member-drive-expression-values.t \
  t/1283-isf-aggregate-rule-values.t \
  t/1284-isf-aggregate-rule-expression-values.t \
  t/1285-isf-aggregate-rule-guard-values.t \
  t/1286-isf-aggregate-condition-values.t \
  t/1287-isf-aggregate-drive-values.t \
  t/1288-isf-aggregate-drive-expression-values.t \
  t/1289-isf-aggregate-drive-call-values.t \
  t/1290-isf-aggregate-drive-call-expression-values.t \
  t/1291-isf-aggregate-inline-drive-values.t \
  t/1292-isf-aggregate-inline-drive-expression-values.t \
  t/1293-isf-aggregate-switch-branch-values.t \
  t/1294-isf-aggregate-switch-selector-values.t \
  t/1295-isf-enum-member-switch-selector-values.t \
  t/1296-isf-aggregate-rule-target-values.t \
  t/1297-isf-aggregate-drive-target-values.t \
  t/1298-isf-aggregate-inline-drive-target-values.t \
  t/1299-isf-aggregate-standalone-condition-values.t \
  t/1300-isf-enum-member-standalone-condition-values.t \
  t/1301-isf-enum-member-rule-standalone-guard-values.t \
  t/1302-isf-aggregate-rule-standalone-guard-values.t \
  t/1331-isf-timing-conventions.t \
  t/1333-isf-interface-actor-param-widths.t \
  t/1334-isf-scalar-storage-actor-param-widths.t \
  t/1335-isf-bank-storage-actor-param-widths.t \
  t/1336-isf-transaction-port-actor-param-widths.t \
  t/1337-isf-bank-storage-actor-param-depths.t \
  t/1338-isf-interface-actor-constant-widths.t \
  t/1353-isf-interface-package-constant-widths.t \
  t/1339-isf-scalar-storage-actor-constant-widths.t \
  t/1354-isf-scalar-storage-package-constant-widths.t \
  t/1340-isf-bank-storage-actor-constant-widths.t \
  t/1355-isf-bank-storage-package-constant-widths.t \
  t/1341-isf-bank-storage-actor-constant-depths.t \
  t/1356-isf-bank-storage-package-constant-depths.t \
  t/1342-isf-transaction-port-actor-constant-widths.t \
  t/1343-isf-data-op-static-width-sources.t \
  t/1344-isf-assemble-static-part-widths.t \
  t/1345-isf-actor-param-actor-constants.t \
  t/1346-isf-actor-param-actor-params.t \
  t/1347-isf-transaction-param-actor-static-defaults.t \
  t/1348-isf-transaction-param-transaction-params.t \
  t/1349-isf-actor-param-package-constants.t \
  t/1350-isf-transaction-param-package-constants.t \
  t/1351-isf-activation-param-package-constants.t \
  t/1352-isf-library-use-package-constants.t \
  t/1357-isf-transaction-port-package-constant-widths.t \
  t/1358-isf-data-op-package-constant-widths.t \
  t/1359-isf-wait-package-constant-counts.t \
  t/1360-isf-repeat-package-constant-counts.t \
  t/1367-isf-data-op-transaction-param-widths.t \
  t/1369-isf-timing-param-activation-override-gates.t

./bin/ci-regression isf
mdbook build docs/book
```

## 17. Machine-Readable Discovery

The machine-readable public contract is available through:

```bash
./bin/fsmgen --capability-manifest
```

Read:

```text
embedding.isf_public_interface
```

That object advertises:

- `schema_version`
- `status`
- public entrypoints
- CLI option names
- parser and scheduler method names
- constructor option names
- lower-result shape
- schedule-report top-level key list
- schedule-report key/value families
- resource catalog values
- library catalog metadata
- live document paths
- tested-by provenance
- downstream guidance

This document is the human integration contract. The manifest is the exact
JSON-safe discovery object for automated checks. If they disagree, treat that
as a documentation bug and update them in the same slice.

## 18. Deferred Or Non-Public Surface

The following are not public shipped integration surfaces today:

- Full raw parser actor hash as a stable API.
- Full `LoweringIR` as a stable API.
- Full schedule JSON schema beyond the advertised key families.
- Textual include semantics for libraries.
- Standalone transaction or drive library exports.
- Broader interface, transaction-port, storage width, or bank-depth
  expressions beyond actor-local scalar parameter defaults and the shipped
  qualified package-scalar-constant actor interface width and actor-owned
  scalar storage width, actor-owned bank storage width, and actor-owned bank
  storage depth subsets.
- Derived parameter expressions and package/imported constants outside the
  shipped qualified actor parameter, generated-child transaction parameter
  default, generated activation override, reusable-library use-site override,
  actor interface width, actor-owned scalar storage width, actor-owned bank
  storage width, and actor-owned bank storage depth scalar-constant subsets.
- General memory-array HDL emission for actor-owned banks.
- Arbitrary CDC, payload CDC, reset CDC, level sampling across domains, or
  FIFO-like cross-domain storage.
- Direct cross-domain reads/writes/triggers/activations/bindings.
- Direct/local rule-trigger output bindings.
- Direct `(on ...)` activation parameter overrides.
- Snapshot-vs-live binding timing selection beyond the shipped binding timing.
- Proof that every dynamic division/modulo divisor is nonzero. Literal-zero,
  actor-constant-zero, actor-parameter-zero, and
  same-transaction-parameter-zero divisors are rejected, but arbitrary runtime
  scalar nonzero proof and use-site-specialized parameter divisor proof are
  not public shipped surfaces yet.
- A formal frozen EBNF grammar artifact or JSON Schema artifact. This document
  and the manifest are the current integration contract; a machine grammar or
  schema should be produced by a future task if required.

## 19. Integration Guidance

For a downstream producer:

- Emit only the source forms listed in this document.
- If FSMGen behavior looks wrong, follow the strict, format-agnostic
  reproduction bundle flow in
  [docs/DOWNSTREAM_ISSUE_REPORTING.md](../DOWNSTREAM_ISSUE_REPORTING.md). Do not
  guess whether the root cause is source syntax, lowering, reporting, HDL, or
  public API behavior; provide the exact FSMGen-facing artifacts and command
  transcript.
- Prefer explicit scalar names and explicit widths.
- Use transaction ports and `(bind ...)` for runtime-varying data.
- Use `(params ...)` only for static specialization on generated activation
  forms that explicitly support it.
- Use actor constants or actor-local scalar parameter defaults for static
  generated activation parameter override values.
- Use actor constants, actor-local scalar parameter defaults, or qualified
  imported package scalar constants for static latency bound symbols.
- Use actor constants, actor-local scalar parameter defaults, or qualified
  imported package scalar constants for static temporal-contract window
  symbols.
- Use actor constants, actor-local scalar parameter defaults, or qualified
  imported package scalar constants for static actor-level watchdog limits.
- Use actor constants, actor-local scalar parameter defaults,
  same-transaction scalar parameter defaults, or qualified imported package
  scalar constants for static top-level await-local watchdog limits.
- Use actor constants, actor-local scalar parameter defaults, or qualified
  imported package scalar constants for static wait-count symbols.
- Treat every fail-closed diagnostic as a source-generation bug.
- Use `--emit-schedule-json` in tests to confirm schedule/report shape.
- Use `--check --json` or `--check-json` when a downstream workflow needs a
  machine-readable pass/fail result. For `.isf` inputs, parser, lowering,
  schedule-report, and downstream semantic check failures exit nonzero while
  still emitting `success: false` JSON to stdout with the diagnostic message in
  `diagnostics[0].message`.
- Use generated `.fsm` as the human review artifact before HDL.
- Use `--capability-manifest` to check the current bounded public contract.

For a downstream analyzer:

- Consume schedule JSON key families listed here.
- Preserve unknown keys for forward compatibility.
- Do not depend on raw Perl object internals.
- Do not infer support from parser-carried private clause payloads.
- Treat `compile_issues[]` as nonfatal warnings on successful reports.
- Treat missing artifacts or diagnostics as integration failures, not partial
  success. Empty stdout from `--check --json` for an existing `.isf` input is
  a reportable FSMGen bug, not an expected downstream contract.

## 20. Source Of Truth And Evolution

This file is the canonical human downstream integration document for `.isf`
and the IAL2-to-IAL1 lowering stack used by `.ppif`. It is intentionally
duplicated into the mdBook by include, not by a second copy. It must always
remain synchronized with the live docs, the book, the machine-readable public
contracts, manifest metadata, support-accounting catalog, and shipped
implementation.

Supporting artifacts:

- `docs/ISF_SPEC.md`: detailed live language and lowering specification.
- `docs/DOWNSTREAM_ISSUE_REPORTING.md`: strict issue-reporting protocol for
  locally reproducible downstream bug reports.
- `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`: live public facade/report contract.
- `perl/FSM/Support/ISFPublicInterfaceContract.pm`: machine-readable contract
  owner advertised through the capability manifest.
- `docs/ISF_LIBRARY_CATALOG.md`: shipped reusable library catalog.
- `docs/book/src/13-intent-scheduling.md` and child chapters, especially
  `docs/book/src/13j-type-enum-aggregate.md` and
  `docs/book/src/13k-isf-feature-support-matrix.md`: tutorial, explanatory,
  and book-facing shipped-feature support documentation. The machine-readable
  ISF public contract advertises every Intent Scheduling chapter listed in
  `docs/book/src/SUMMARY.md`, plus the canonical feature backlog and reference
  map, through `live_document_paths`.
- `t/`: regression and audit evidence.

Evolution rule:

Any future change to public ISF syntax, PPIF lowering contract, parser facade
behavior, scheduler facade behavior, lower-result shape, schedule-report shape,
diagnostics, or downstream guidance must update this file in the same commit
as the behavior change.

Minimum same-slice update set for downstream-visible ISF or PPIF behavior
changes:

- source/parser/lowering/report/emitter code that implements the behavior;
- focused regression coverage;
- `docs/ISF_SPEC.md`;
- this file;
- the relevant mdBook chapter or included book page;
- `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md` and
  `perl/FSM/Support/LanguageSurfaceSection.pm` when shipped suffix/layer/CLI or
  per-suffix boundary metadata changes;
- support-accounting catalog/docs when supported sample or fixture coverage
  changes;
- `perl/FSM/Support/ISFPublicInterfaceContract.pm` when public facade, report,
  manifest, live-doc, or tested-by metadata changes;
- `docs/ISF_LIBRARY_CATALOG.md` when reusable library semantics change;
- owning task tree and live recovery docs.
