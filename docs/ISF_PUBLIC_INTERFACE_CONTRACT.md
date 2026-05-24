# ISF Public Interface Contract

This is the live downstream-consumer contract for the `.isf` intent-scheduling
surface.
The single self-contained human integration handoff for downstream producers
and consumers is
[docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md](ISF_DOWNSTREAM_INTEGRATION_SPEC.md).
That document must stay synchronized with this contract, the live `.isf` spec,
the mdBook, manifest metadata, regression tests, and implementation behavior.

It is intentionally a live document: any implementation slice that changes
supported ISF syntax, CLI behavior, public in-process facade behavior, scheduled
`.fsm` result shape, or schedule-report shape must update this file and the
downstream integration spec in the same commit.

This contract is not frozen. Exact audits in this document and in
`embedding.isf_public_interface` mean the current advertised surface is
discoverable and regression-backed; they do not prevent the ISF API from
evolving alongside FSMGen.

Parser acceptance is not sufficient to make an ISF construct public or
supported. A shipped construct must have an explicit accepted source shape,
fail-closed malformed-form diagnostics, a documented lowering path into
scheduled `.fsm` or an intentional diagnostic before emission, a runtime
semantic in terms of cycles/activation/storage/conflicts/completion, and
focused regression coverage. Constructs without that full chain remain deferred,
backlog, or validated compatibility input.

The intent-layer terminology used by the docs is also part of this live
contract: `.fsm` is Intent Abstraction Layer 0 (`IAL0`), the explicit
cycle-authored review artifact, and current `.isf` is Intent Abstraction Layer
1 (`IAL1`), the scheduling-intent layer that lowers to reviewable IAL0 `.fsm`.
No higher layer is currently shipped.

Machine-readable discovery lives in
[perl/FSM/Support/ISFPublicInterfaceContract.pm](../perl/FSM/Support/ISFPublicInterfaceContract.pm)
and is advertised through:

```text
./bin/fsmgen --capability-manifest
  -> embedding.isf_public_interface
```

The advertised contract object is full-surface JSON-round-trip audited by
[t/1113-isf-public-interface-contract-json-roundtrip-audit.t](../t/1113-isf-public-interface-contract-json-roundtrip-audit.t).
Downstream tools can treat that contract metadata as JSON-safe discovery data.
It is also defensive-copy audited by
[t/1114-isf-public-interface-contract-defensive-copy-audit.t](../t/1114-isf-public-interface-contract-defensive-copy-audit.t),
so callers can mutate a received copy without polluting later contract builds.
The identity and stability metadata is checked by
[t/1141-isf-public-identity-flags-metadata-audit.t](../t/1141-isf-public-identity-flags-metadata-audit.t)
to keep schema version, bounded status, owner list, and stability flags exact
across direct and manifest views.
The downstream guidance metadata is checked by
[t/1142-isf-public-guidance-metadata-audit.t](../t/1142-isf-public-guidance-metadata-audit.t)
to keep the advertised consumer advice exact and duplicate-free across direct
and manifest views.
The ISF-specific `tested_by` provenance metadata is checked by
[t/1144-isf-public-tested-by-metadata-audit.t](../t/1144-isf-public-tested-by-metadata-audit.t)
to keep the advertised audit list exact, duplicate-free, repo-relative, and
present on disk across direct and manifest views.
Both capability-manifest CLI spellings are audited by
[t/1115-isf-public-interface-cli-manifest-audit.t](../t/1115-isf-public-interface-cli-manifest-audit.t)
to keep the in-process contract and CLI-advertised contract aligned.
The `public_top_level_presence_keys` discovery list is checked by
[t/1131-isf-public-top-level-discovery-audit.t](../t/1131-isf-public-top-level-discovery-audit.t)
to stay unique and exact across direct, manifest, and CLI manifest views.
The advertised entrypoint metadata is checked by
[t/1135-isf-public-entrypoint-metadata-audit.t](../t/1135-isf-public-entrypoint-metadata-audit.t)
to stay exact and duplicate-free across the same views.
The advertised ISF CLI option list is checked by
[t/1136-isf-public-cli-option-metadata-audit.t](../t/1136-isf-public-cli-option-metadata-audit.t)
to stay exact and duplicate-free across direct and manifest views.
The advertised CLI success-shape metadata is checked by
[t/1153-isf-public-cli-success-metadata-audit.t](../t/1153-isf-public-cli-success-metadata-audit.t)
to keep the schedule JSON, `--outdir`, and plain HDL-generation success
surfaces exact across direct and manifest views.
The advertised `--strict` HDL-generation success metadata is checked by
[t/1155-isf-public-cli-strict-success-metadata-audit.t](../t/1155-isf-public-cli-strict-success-metadata-audit.t)
to keep the accepted strict `file.isf` generation shape exact across direct and
manifest views and aligned with the APB strict CLI path.
The advertised in-process facade return-shape metadata is checked by
[t/1154-isf-public-facade-return-metadata-audit.t](../t/1154-isf-public-facade-return-metadata-audit.t)
to keep the `parse_file(...)`, `parse_source(...)`, `lower(...)`, and
`report(...)` return containers exact across direct and manifest views and
aligned with real APB facade results.
The advertised parser and scheduler method-name lists are checked by
[t/1137-isf-public-method-name-metadata-audit.t](../t/1137-isf-public-method-name-metadata-audit.t)
to stay exact and duplicate-free across those views.
The advertised constructor option list is checked by
[t/1138-isf-public-constructor-option-metadata-audit.t](../t/1138-isf-public-constructor-option-metadata-audit.t)
to stay exact and duplicate-free across those views.
The plain `file.isf` HDL-generation path is checked by
[t/1123-isf-public-cli-hdl-generation-audit.t](../t/1123-isf-public-cli-hdl-generation-audit.t)
to reach generated HDL with clean stderr for the APB fixture.
The advertised `--strict` option on that path is checked by
[t/1124-isf-public-cli-strict-mode-audit.t](../t/1124-isf-public-cli-strict-mode-audit.t).
The compact SPI-like serial fixture is checked by
[t/1228-isf-spi-fixture-coverage.t](../t/1228-isf-spi-fixture-coverage.t)
to keep file-backed schedule JSON, scheduled `.fsm`, plain HDL generation,
strict HDL generation, explicit MOSI bit selection, and ISF shift handoff
covered without claiming full external SPI protocol compliance.
The compact I2C-like serial fixture is checked by
[t/1309-isf-i2c-fixture-coverage.t](../t/1309-isf-i2c-fixture-coverage.t)
to keep file-backed schedule JSON, scheduled `.fsm`, plain HDL generation,
strict HDL generation, switch-branch repeats, read-data shifting, sampled
write-data bit selection, and absence of an implicit `data_bit` input covered
without claiming full external I2C protocol compliance.
The burst-reader fixture is checked by
[t/1310-isf-burst-fixture-coverage.t](../t/1310-isf-burst-fixture-coverage.t)
to keep file-backed schedule JSON, scheduled `.fsm`, plain HDL generation,
strict HDL generation, dynamic repeat counter storage, watchdog and latency
counter roles, sampled aliases, and completion/timeout pulse fan-in covered.
The UART-like transmit fixture is checked by
[t/1311-isf-uart-fixture-coverage.t](../t/1311-isf-uart-fixture-coverage.t)
to keep file-backed schedule JSON, scheduled `.fsm`, plain HDL generation,
strict HDL generation, sampled-byte LSB drive selection, known-width
`shift_right`, repeat counter storage, busy drive sequencing, and completion
pulse behavior covered without claiming full external UART protocol
compliance.
The phase fixture is checked by
[t/1312-isf-phase-fixture-coverage.t](../t/1312-isf-phase-fixture-coverage.t)
to keep file-backed schedule JSON, scheduled `.fsm`, plain HDL generation,
strict HDL generation, transaction phase pass-through states, absence of
reusable `done` drive storage, and delayed completion pulse behavior covered
without claiming executable actor-level phase scheduling.
The switch fixture is checked by
[t/1313-isf-switch-fixture-coverage.t](../t/1313-isf-switch-fixture-coverage.t)
to keep file-backed schedule JSON, scheduled `.fsm`, plain HDL generation,
strict HDL generation, sampled selector capture, explicit branch dispatch,
default fallthrough, named-drive branch starts, and delayed completion pulse
behavior covered.
The when fixture is checked by
[t/1314-isf-when-fixture-coverage.t](../t/1314-isf-when-fixture-coverage.t)
to keep file-backed schedule JSON, scheduled `.fsm`, plain HDL generation,
strict HDL generation, entry drive setup, conditional decision states,
multi-step true-body drives, false-path fallthrough, compatible named-drive
start fan-in, and delayed completion pulse behavior covered.
The generated-composition fixture is checked by
[t/1315-isf-generated-composition-fixture-coverage.t](../t/1315-isf-generated-composition-fixture-coverage.t)
to keep file-backed strict schedule JSON, strict `--outdir` file emission,
parent/child/generated-top scheduled `.fsm` artifacts, start/done handoffs,
named-drive request/payload handoffs, public input fanout, `await_all`
synchronization, and strict top/parent/child HDL generation covered.
The rule/resource fixture is checked by
[t/1316-isf-rule-resource-fixture-coverage.t](../t/1316-isf-rule-resource-fixture-coverage.t)
to keep file-backed schedule JSON, scheduled `.fsm`, plain HDL generation,
strict HDL generation, rule-over-transaction priority suppression,
`rule_slot`/`priority` arbitration metadata, lower-priority rule gating, and
delayed completion pulse behavior covered. Focused resource tests additionally
cover bounded `rule_slot`/`round_robin` and
`transaction_start`/`round_robin` grants, generated pointer storage metadata,
report projection, and fail-closed unsupported round-robin combinations.
The stage/contract fixture is checked by
[t/1317-isf-stage-contract-fixture-coverage.t](../t/1317-isf-stage-contract-fixture-coverage.t)
to keep file-backed schedule JSON, scheduled `.fsm`, plain HDL generation,
strict HDL generation, sampled payload handoff, ready/valid barrier metadata,
bounded eventual contract metadata, temporal monitor storage roles,
SystemVerilog sticky-fail assertion projection, and delayed completion pulse
behavior covered.
The FIFO datapath fixture is checked by
[t/1319-isf-fifo-datapath-fixture-coverage.t](../t/1319-isf-fifo-datapath-fixture-coverage.t)
to keep file-backed strict schedule JSON, scheduled `.fsm`, bounded
`bank_accesses[]` metadata, plain HDL generation, strict HDL generation,
scalarized depth-4 bank storage, pointer-guarded accepted pushes, and
pointer-guarded accepted pops covered.
The FIFO controller fixture is checked by
[t/1320-isf-fifo-controller-fixture-coverage.t](../t/1320-isf-fifo-controller-fixture-coverage.t)
to keep file-backed strict schedule JSON, scheduled `.fsm`, compatible
same-value fan-in metadata, plain HDL generation, strict HDL generation,
occupancy/full/empty updates, and 2-bit pointer wrap covered without claiming
data-bank storage or `data_out` datapath transfer behavior.
The FIFO reusable-library fixture is checked by
[t/1321-isf-fifo-library-fixture-coverage.t](../t/1321-isf-fifo-library-fixture-coverage.t)
to keep file-backed strict schedule JSON, generated importer/child/top
scheduled `.fsm` artifacts, strict `--outdir` emission, fixed parameter
overrides, use-site bindings, scalarized FIFO data entries, and plain plus
strict generated-top HDL generation covered without claiming use-site
parameter-driven FIFO interface shape, bank-depth specialization, generated-top
respecialization, or nested library imports.
The ATL temporary trigger-batch fixture is checked by
[t/1324-isf-atl-fixture-coverage.t](../t/1324-isf-atl-fixture-coverage.t)
to keep file-backed static actor instances, one task-scoped same-cycle
external trigger batch, strict schedule JSON parity,
scheduled `.fsm` structure, and plain plus strict HDL generation covered
without claiming peer events, endpoint data movement, generated ATL child
artifacts, generated ATL tops, group endpoints, compact movement aliases, CDC,
payloads, ready/backpressure, route mux/storage, or permanent actor grouping.
The ATL resolved-child fixture is checked by
[t/1330-isf-atl-resolved-child-fixture-coverage.t](../t/1330-isf-atl-resolved-child-fixture-coverage.t)
to keep file-backed resolved child artifact emission, generated ATL top
emission, strict schedule JSON parity, parent/child/top scheduled `.fsm`
structure, resolved
`actor_network.instances[]` metadata, one actor-transaction trigger handoff,
one actor-event wait handoff, and `actor_network.generated_tops[]` metadata
covered.
The same ATL fixture now has plain plus strict CLI HDL generation coverage,
asserting the generated top, parent, child, and selected internal
trigger/event links in SystemVerilog without widening the report schema.
The same focused coverage now also covers the shipped scalar pin-ingress route,
the exact-width vector pin-ingress route, the same-child scalar pin-ingress
multi-route extension, the same-child vector pin-ingress multi-route
extension, the same-child mixed scalar/vector pin-ingress route-set extension,
the scalar pin-egress route, the exact-width vector pin-egress route, the
same-child scalar pin-egress multi-route extension, and the same-child vector
pin-egress multi-route extension, and the same-child mixed scalar/vector
pin-egress route-set extension through the generated top.
Public consumers should read each route from
`actor_network.data_movements[]`, discover the top from
`actor_network.generated_tops[]`, and treat the generated-top data-link plumbing
as private implementation detail.
The same focused coverage also covers
[isf/atl_two_child_pipeline.isf](../isf/atl_two_child_pipeline.isf), the
first data-free two-child generated-top subset. It proves parent, reader,
writer, and generated top `.fsm` artifacts, strict schedule JSON parity,
plain plus strict HDL generation, and per-child generated-top wiring metadata
under `actor_network.generated_tops[].children[]`.
The same focused coverage now covers
[isf/atl_two_child_data_pipeline.isf](../isf/atl_two_child_data_pipeline.isf),
the first one-bit generated-child actor-to-actor data route through that
two-child top. Public consumers should read the route from
`actor_network.data_movements[]` with `kind: "scalar_actor_handoff"` and
discover parent/reader/writer/top wiring from `actor_network.generated_tops[]`
with `children[]`; no public `data_links` key is exposed.
The same focused coverage now covers
[isf/atl_two_child_vector_data_pipeline.isf](../isf/atl_two_child_vector_data_pipeline.isf),
the exact-width vector generated-child actor-to-actor route through that
two-child top. Public consumers should read the route from
`actor_network.data_movements[]` with `kind: "vector_actor_handoff"`,
`width` equal to the resolved child endpoint width, and
`width_source: "resolved_child_endpoint_exact_width"`; generated-top discovery
still comes from `actor_network.generated_tops[]` with `children[]`, and no
public `data_links` key is exposed.
The same focused coverage now covers
[isf/atl_two_child_multi_data_pipeline.isf](../isf/atl_two_child_multi_data_pipeline.isf),
the bounded same-source, same-sink multi-route extension of that generated
top. Public consumers still read each scalar route as a separate
`actor_network.data_movements[]` entry with `kind: "scalar_actor_handoff"` and
still use `actor_network.generated_tops[].children[]` for generated-top
discovery; no public `data_links` key is exposed.
The shipped hardening around that route keeps the same public surface: it adds
focused fail-closed coverage for source child output validation, sink child
input validation, one endpoint pair per route drive body, and one top-level
drive call per route, without adding report keys or new ATL movement syntax.
The shipped width hardening widens only the generated-child actor-to-actor
public route values: matching source-output and sink-input child endpoint
widths greater than one report as `vector_actor_handoff` with
`width_source: "resolved_child_endpoint_exact_width"`. It does not add public
data-link keys, width adaptation, payload protocols, or conversion semantics.
The shipped clock/reset hardening likewise keeps the public surface
unchanged: generated-child actor-to-actor routes remain same-domain
generated-top wiring, and child clock/reset mismatches fail closed until a
later contract explicitly adds CDC or reset-remap metadata.
The shipped self-route hardening keeps the public surface unchanged:
generated-child actor-to-actor routes remain between two distinct resolved
children, and same-child source/sink route pairs fail closed until a later
contract explicitly adds loopback, storage, or bypass metadata.
The shipped repeated-trigger hardening also keeps the public surface
unchanged: generated-child actor-to-actor routes remain one source trigger
and one sink trigger per selected sequence, and extra route-child triggers
fail closed until a later contract explicitly adds repeated-activation
metadata.
The shipped repeated-wait hardening keeps that same public surface
unchanged: generated-child actor-to-actor routes remain one source event wait
and one sink event wait per selected sequence, and extra route-child waits
fail closed until a later contract explicitly adds event fan-in/fan-out or
repeated wait sequencing metadata.
The shipped same-parent-transaction hardening also keeps the public surface
unchanged: the selected route sequence must remain inside one parent
transaction, and split route clauses fail closed until a later contract
explicitly adds continuation or cross-transaction route scheduling metadata.
The shipped sink-trigger ordering hardening keeps that public surface
unchanged as well: the data drive call must occur before the sink child
trigger, and sink-before-drive clauses fail closed until a later contract
explicitly adds storage, backpressure, or delayed payload delivery metadata.
The shipped sink-event-wait ordering hardening keeps the same public surface
unchanged: the sink child event wait must occur after the sink child trigger,
and sink-wait-before-trigger clauses fail closed until a later contract
explicitly adds sticky event, replay, or pre-trigger acknowledgement
metadata.
The shipped source-event-wait ordering hardening keeps the same public
surface unchanged: the source child event wait must occur after the source
child trigger, and source-wait-before-trigger clauses fail closed until a
later contract explicitly adds sticky event, replay, or pre-trigger
acknowledgement metadata.
The shipped route-contiguity hardening also keeps the public surface
unchanged: the source trigger, source event wait, data drive call, sink
trigger, and sink event wait must remain one contiguous transaction-body
segment until a later contract explicitly adds interleaved parent work, local
side-effect, pre/post route sampling, continuation, storage, muxing,
backpressure, or payload metadata.
The shipped route-isolation hardening keeps the same public surface
unchanged: the contiguous route segment must remain the only executable
parent transaction-body work between the transaction start condition and
completion until a later contract explicitly adds pre-route setup,
post-route sampling, local side-effect, cleanup, continuation, storage,
muxing, backpressure, or payload metadata.
The shipped route-boundary cardinality hardening also keeps the public
surface unchanged: the isolated route must remain bounded by exactly one
simple start boundary and one simple completion boundary until a later
contract explicitly adds activation fan-in, completion fan-out,
start-condition arbitration, setup/cleanup, continuation, storage, muxing,
backpressure, or payload metadata.
The shared route-drive argument boundary also keeps the public surface
unchanged: selected ATL route drive definitions are unparameterized and
selected route drive calls are argument-free for actor-to-actor, pin-ingress,
and pin-egress data-movement routes. Parameterized route drives and route
drive-call actuals fail closed before drive actual binding, payload protocols,
route mux/storage, or additional report keys are claimed.
The shipped boundary-simplicity hardening keeps that surface unchanged as
well: the start and completion boundaries must remain body-free until a later
contract explicitly adds activation-body sampling, completion payload/fan-out,
setup/cleanup, continuation, storage, muxing, backpressure, or payload
metadata.
The compatibility CLI parity path is checked by
[t/1229-isf-compatibility-cli-parity.t](../t/1229-isf-compatibility-cli-parity.t)
so accepted ignored handshake compatibility source reaches CLI schedule JSON
and strict HDL, while removed transaction `(assign ...)` fails through the CLI
with migration guidance.
The first reusable-library import path is checked by
[t/1230-isf-library-import-resolution.t](../t/1230-isf-library-import-resolution.t)
so file-backed `(imports ...)` / `(use ...)` source resolves exported library
actors, validates use-site parameter and binding errors, emits specialized
child scheduled `.fsm` artifacts, and reports bounded `library_uses`
provenance.
Generated top wiring for resolved library actor instances is checked by
[t/1231-isf-library-generated-top.t](../t/1231-isf-library-generated-top.t)
so a library actor wrapper reaches CLI `--outdir`, generated top `.fsm`, and
SystemVerilog output through the normal composition path, including explicit
generated-top links when a library actor uses different clock/reset names than
the importing actor. Those links are name remaps inside the current
single-clock-domain ISF model; they do not advertise CDC or interacting
clock-domain semantics.
The current APB schedule report is checked against the advertised key families
by [t/1116-isf-public-schedule-report-key-family-audit.t](../t/1116-isf-public-schedule-report-key-family-audit.t).
The shipped stage/contract report projection is checked by
[t/1225-isf-stage-contract-schedule-report.t](../t/1225-isf-stage-contract-schedule-report.t).
The advertised schedule-report metadata itself is checked by
[t/1140-isf-public-schedule-report-metadata-audit.t](../t/1140-isf-public-schedule-report-metadata-audit.t)
to keep key families, grouped family maps, ordering, multi-file scope, and
successful `compile_issues` shape exact across direct and manifest views.
The schedule-report DT assignment-count shape is checked by
[t/1147-isf-public-report-dt-assignment-count-audit.t](../t/1147-isf-public-report-dt-assignment-count-audit.t)
to keep `dt_blocks[*].assignments` documented as a non-negative assignment
count, not an assignment payload list.
The schedule-report DT kind metadata is checked by
[t/1158-isf-public-report-dt-kind-metadata-audit.t](../t/1158-isf-public-report-dt-kind-metadata-audit.t)
to keep advertised `dt_blocks[*].kind` values exact across direct and manifest
views and aligned with APB, full-featured, and temporal-contract reports.
Stage and contract schedule-report key/value families are audited across
direct and manifest views and checked against generated JSON.
The inferred-storage metadata is checked by
[t/1148-isf-public-storage-metadata-audit.t](../t/1148-isf-public-storage-metadata-audit.t)
to keep advertised storage `kind` values, optional `role` values, and optional
`width` shape exact across direct and manifest views. Data-operation storage
roles and widths are checked by
[t/1226-isf-data-width-storage-report.t](../t/1226-isf-data-width-storage-report.t)
for sampled aliases, extracted fields, assembled targets, explicit-width
shift registers, and completion pulses.
Actor-owned fixed storage declarations are checked by
[t/1232-isf-actor-storage-declarations.t](../t/1232-isf-actor-storage-declarations.t)
for parser shape, authored `(var ...)` / `(variable ...)` scalar storage
forms, scalarized bank lowering, `actor_storage` report metadata, fail-closed
diagnostics, and SystemVerilog generation for used storage.
Actor-owned scalar storage widths backed by actor-local scalar parameter
defaults are checked by
[t/1334-isf-scalar-storage-actor-param-widths.t](../t/1334-isf-scalar-storage-actor-param-widths.t)
so accepted `(var NAME (width PARAM))` and
`(variable NAME (width PARAM))` entries resolve to positive integer storage
widths, scheduled `.fsm` `+size` declarations, schedule-report widths, and HDL
register ranges while unknown symbolic names, runtime interface signals,
zero-valued or non-scalar actor parameters, and arbitrary expressions fail
closed.
Actor-owned scalar storage widths backed by declared actor constants are
checked by
[t/1339-isf-scalar-storage-actor-constant-widths.t](../t/1339-isf-scalar-storage-actor-constant-widths.t)
so accepted `(var NAME (width CONST))` and
`(variable NAME (width CONST))` entries resolve to positive integer storage
widths, scheduled `.fsm` `+size` declarations, schedule-report widths, and HDL
register ranges while zero-valued actor constants, unknown symbolic names,
runtime interface signals, and arbitrary expressions fail closed.
Actor-owned bank storage widths backed by actor-local scalar parameter
defaults are checked by
[t/1335-isf-bank-storage-actor-param-widths.t](../t/1335-isf-bank-storage-actor-param-widths.t)
so accepted `(bank NAME (width PARAM) (depth N))` entries resolve to positive
integer bank element widths, scheduled `.fsm` `+size` declarations,
schedule-report storage and `bank_accesses[]` widths, and HDL register ranges
while unsupported width sources fail closed.
Actor-owned bank storage widths backed by declared actor constants are checked
by
[t/1340-isf-bank-storage-actor-constant-widths.t](../t/1340-isf-bank-storage-actor-constant-widths.t)
so accepted `(bank NAME (width CONST) (depth N))` entries resolve to positive
integer bank element widths, scheduled `.fsm` `+size` declarations,
schedule-report storage and `bank_accesses[]` widths, and HDL register ranges
while zero-valued actor constants, unknown symbolic names, runtime interface
signals, and arbitrary expressions fail closed.
Actor-owned bank storage depths backed by actor-local scalar parameter
defaults are checked by
[t/1337-isf-bank-storage-actor-param-depths.t](../t/1337-isf-bank-storage-actor-param-depths.t)
so accepted `(bank NAME (width W) (depth PARAM))` entries resolve to positive
integer bank depths, deterministic scalarized storage families, scheduled
`.fsm` `+size` declarations, schedule-report storage and `bank_accesses[]`
depth/scalar-entry metadata, and HDL register declarations while unknown
symbolic names, runtime interface signals, zero-valued or non-scalar actor
parameters, arbitrary expressions, and duplicate scalarized signal names fail
closed.
Actor-owned bank storage depths backed by declared actor constants are checked
by
[t/1341-isf-bank-storage-actor-constant-depths.t](../t/1341-isf-bank-storage-actor-constant-depths.t)
so accepted `(bank NAME (width W) (depth CONST))` entries resolve to positive
integer bank depths, deterministic scalarized storage families, scheduled
`.fsm` `+size` declarations, schedule-report storage and `bank_accesses[]`
depth/scalar-entry metadata, and HDL register declarations while zero-valued
actor constants, unknown symbolic names, runtime interface signals, arbitrary
expressions, and duplicate scalarized signal names fail closed.
Transaction-local port widths backed by actor-local scalar parameter defaults
are checked by
[t/1336-isf-transaction-port-actor-param-widths.t](../t/1336-isf-transaction-port-actor-param-widths.t)
so accepted transaction `(ports ...)` `(input NAME (width PARAM))` and
`(output NAME (width PARAM))` entries resolve to positive integer port widths,
scheduled `.fsm` `+size` declarations, activation handoff widths,
`transaction_port_bindings[]` report widths, and HDL register ranges while
transaction parameters, unknown symbolic names, runtime interface signals,
zero-valued or non-scalar actor parameters, and arbitrary expressions fail
closed.
Transaction-local port widths backed by declared actor constants are checked by
[t/1342-isf-transaction-port-actor-constant-widths.t](../t/1342-isf-transaction-port-actor-constant-widths.t)
so accepted transaction `(ports ...)` `(input NAME (width CONST))` and
`(output NAME (width CONST))` entries resolve to positive integer port widths,
scheduled `.fsm` `+size` declarations, activation handoff widths,
`transaction_port_bindings[]` report widths, and HDL register ranges while
transaction parameters, unknown symbolic names, runtime interface signals,
zero-valued actor constants, non-scalar actor constants, and arbitrary
expressions fail closed.
Rule expression guards are checked by
[t/1233-isf-rule-expression-guards.t](../t/1233-isf-rule-expression-guards.t)
for shorthand and long-form guard normalization, scheduled `.fsm` DT-DTE
emission, HDL generation, and targeted parser diagnostics.
The depth-4 FIFO controller matrix is checked by
[t/1235-isf-fifo-same-cycle-update-matrix.t](../t/1235-isf-fifo-same-cycle-update-matrix.t)
for the real controller interface, actor-maintained full/empty flags,
pointer/occupancy state updates, equality-based disjoint-rule proof, scheduled
`.fsm`, schedule report, and SystemVerilog reachability without inventing a
FIFO data-bank datapath.
Actor-owned bank access is checked by
[t/1236-isf-bank-access-lowering.t](../t/1236-isf-bank-access-lowering.t)
for `(store <bank-name> <index> <value>)` and
`(load <bank-name> <index> as <target>)` parsing,
scalarized guarded lowering, bounded `bank_accesses` report metadata,
fail-closed diagnostics, and depth-4 FIFO data-path HDL reachability.
The fixed-shape reusable FIFO library fixture is checked by
[t/1237-isf-fifo-library-fixture.t](../t/1237-isf-fifo-library-fixture.t)
for file-backed import of [isf/common/fifo.isf](../isf/common/fifo.isf),
specialized child scheduled `.fsm` emission, generated top wiring, fixed
parameter provenance, same-cycle full push/pop case visibility, bank-backed
accepted push/pop artifacts, and `library_uses` report metadata.
Generated-top SystemVerilog for that FIFO fixture is checked by
[t/1238-isf-fifo-library-hdl-generation.t](../t/1238-isf-fifo-library-hdl-generation.t)
for FIFO child parameter bindings, scalarized data entries, pointer-gated
accepted push/pop selectors, and AST factorization preserving distinct
`CoreAST` signal identities.
The reusable-library catalog contract is checked by
[t/1239-isf-library-catalog-contract.t](../t/1239-isf-library-catalog-contract.t)
so the machine-readable public contract advertises
[docs/ISF_LIBRARY_CATALOG.md](ISF_LIBRARY_CATALOG.md), the shipped catalog
entry key family, and the current shipped reusable definition list.
The transaction-summary metadata is checked by
[t/1149-isf-public-transaction-metadata-audit.t](../t/1149-isf-public-transaction-metadata-audit.t)
to keep transaction `states` and `count` shapes exact across direct and
manifest views.
The transaction-ordering metadata is checked by
[t/1157-isf-public-report-transaction-ordering-audit.t](../t/1157-isf-public-report-transaction-ordering-audit.t)
to keep transaction summaries lexically sorted by name while each
transaction's `states` array follows scheduled `.fsm` state emission order.
The reset-summary metadata is checked by
[t/1150-isf-public-reset-metadata-audit.t](../t/1150-isf-public-reset-metadata-audit.t)
to keep advertised reset `kind` and `polarity` values exact across direct and
manifest views.
The reset container/null shape is checked by
[t/1159-isf-public-report-reset-shape-metadata-audit.t](../t/1159-isf-public-report-reset-shape-metadata-audit.t)
to keep configured and defaulted legacy single-clock reset summaries as hashes
and domain-owned omitted resets as JSON null.
The schedule-report count metadata is checked by
[t/1151-isf-public-report-count-metadata-audit.t](../t/1151-isf-public-report-count-metadata-audit.t)
to keep interface and state-count semantics exact across direct and manifest
views.
The schedule-report scalar metadata is checked by
[t/1152-isf-public-report-scalar-metadata-audit.t](../t/1152-isf-public-report-scalar-metadata-audit.t)
to keep `source`, `scheduled_fsm`, `clock`, and `watchdog` shapes exact across
direct and manifest views.
The public `--emit-schedule-json` CLI path is checked by
[t/1121-isf-public-cli-schedule-report-audit.t](../t/1121-isf-public-cli-schedule-report-audit.t)
to emit clean-stderr JSON matching the in-process scheduler report.
The explicit schedule-report freeze boundary is checked by
[t/1227-isf-schedule-report-freeze-boundary.t](../t/1227-isf-schedule-report-freeze-boundary.t)
so the contract stays bounded-public, does not claim whole-schema stability,
and keeps the presence-family map scoped to key families.
The successful `compile_issues` report shape is checked by
[t/1130-isf-public-compile-issues-success-audit.t](../t/1130-isf-public-compile-issues-success-audit.t)
for both in-process and CLI report paths.
The nonfatal `compile_issues` projection is checked by
[t/1212-isf-schedule-report-compile-issues-projection.t](../t/1212-isf-schedule-report-compile-issues-projection.t)
for both in-process and CLI report paths.
The compatible fan-in projection is checked by
[t/1213-isf-schedule-report-compatible-fanin-projection.t](../t/1213-isf-schedule-report-compatible-fanin-projection.t)
for both in-process and CLI report paths.
Rejected conflict diagnostics are checked by
[t/1214-isf-rejected-conflict-diagnostics.t](../t/1214-isf-rejected-conflict-diagnostics.t)
for both in-process scheduler calls and the CLI schedule-report path.
Generated composition-top lowering is checked by
[t/1216-isf-generated-composition-top.t](../t/1216-isf-generated-composition-top.t),
including contextual diagnostics for generated handoff port-name conflicts.
The accepted generated-composition report projection is a top-level
`generated_composition` field and is checked by
[t/1217-isf-generated-composition-schedule-report.t](../t/1217-isf-generated-composition-schedule-report.t).
Non-generated-top reports use JSON null, while generated-child reports use a
bounded object with `kind`, `top_module`, `top_fsm`, `parent`, `children`, and
`instances`. The `kind` value is `spawn_generated_top` for spawn-only generated
tops and `activation_generated_top` when another activation kind such as
blocking `do` or parameterized rule `trigger` participates. Parent entries expose `module` and
`scheduled_fsm`; child entries expose `transaction`, `module`, `scheduled_fsm`,
and `parameters`; instance entries expose `instance`, `child`,
`activation_kind`, `start`, `done`, `parameter_bindings`, and
`drive_handoffs`. Parameter binding entries expose `name`, `source`, and
stringified `value`; drive handoff entries expose `drive`, `request`, and
`payloads`, with each payload naming the drive `parameter`, child/parent ports,
and `width`. This projection must stay a bounded live review/discovery summary,
not a raw LoweringIR or `?wiring` dump.
Reusable library actor uses are reported through a top-level `library_uses`
array. Each entry exposes the bounded identity of the resolved use
(`library`, `alias`, `export`, `kind`, `instance`), generated artifact names
(`module`, `scheduled_fsm`), parameter summaries, and explicit binding
summaries. Parameter entries expose `name`, `source` (`default` or
`override`), and stringified `value`. Binding entries expose `role`,
`library_name`, `parent_name`, and `width`; clock/reset bindings use JSON null
for `library_name`, and width is `1`. Raw library resolver state, raw exported
actor hashes, and generated top planning details remain non-public.
The lower-result `files` map is checked for both single-file and multi-file
lowering by [t/1117-isf-public-lower-result-files-audit.t](../t/1117-isf-public-lower-result-files-audit.t).
The lower-result discovery metadata is checked by
[t/1139-isf-public-lower-result-metadata-audit.t](../t/1139-isf-public-lower-result-metadata-audit.t)
to keep `lower_result_presence_keys` and `lower_result_file_map_shape` exact
across direct and manifest views.
The lower-result file sub-shape metadata is checked by
[t/1156-isf-public-lower-result-file-shape-audit.t](../t/1156-isf-public-lower-result-file-shape-audit.t)
to keep scheduled `.fsm` basename keys and scheduled-text roots exact across
direct and manifest views and aligned with single-file plus multi-file
lowering.
The public `--outdir` CLI path is checked by
[t/1122-isf-public-cli-outdir-lowering-audit.t](../t/1122-isf-public-cli-outdir-lowering-audit.t)
to write scheduled `.fsm` artifacts matching the in-process lower-result
`files` map for a multi-file fixture.
The current multi-file schedule-report scope is checked by
[t/1128-isf-public-multifile-schedule-report-audit.t](../t/1128-isf-public-multifile-schedule-report-audit.t).
The multi-domain clock-domain report projection and event-crossing fixture are
checked by [t/1247-isf-clock-domain-partition.t](../t/1247-isf-clock-domain-partition.t).
That test now also covers the file-backed dual event-crossing fixture, proving
two generated CDC child modules and both source/destination endpoint roles in
one top.
The `parse_source(...)` facade method is checked by
[t/1118-isf-public-parse-source-facade-audit.t](../t/1118-isf-public-parse-source-facade-audit.t)
to ensure in-memory source text returns a scheduler-consumable actor with the
same public lower/report identities as `parse_file(...)` for a real fixture.
Generated `.fsm` DT block order and schedule-report `dt_blocks` order are
checked by
[t/1119-isf-deterministic-dt-block-order.t](../t/1119-isf-deterministic-dt-block-order.t)
for both `parse_file(...)` and `parse_source(...)` on the APB fixture.
The scheduled `.fsm` artifact metadata is checked by
[t/1145-isf-public-scheduled-fsm-metadata-audit.t](../t/1145-isf-public-scheduled-fsm-metadata-audit.t)
to keep `scheduled_fsm_dt_ordering`, its paired schedule-report ordering
policy, and the review-artifact flag exact across direct and manifest views.
The DT assignment operator metadata is checked by
[t/1146-isf-public-dt-assignment-metadata-audit.t](../t/1146-isf-public-dt-assignment-metadata-audit.t)
to keep the combinational and sequential assignment families exact across
direct and manifest views.
The `live_document_paths` list is checked by
[t/1120-isf-public-live-document-path-audit.t](../t/1120-isf-public-live-document-path-audit.t)
to keep the direct owner, in-process manifest, and both CLI manifest spellings
aligned on repo-relative Markdown paths that exist on disk, including the
format-agnostic downstream issue-reporting protocol used for local
reproduction bundles.
The ISF mdBook path subset is checked by
[t/1303-isf-public-live-book-paths-audit.t](../t/1303-isf-public-live-book-paths-audit.t)
to keep every Intent Scheduling chapter from
[docs/book/src/SUMMARY.md](book/src/SUMMARY.md), plus the canonical feature
backlog and reference map, advertised through the same public contract and
manifest views.
The book-facing shipped feature matrix is checked by
[t/1305-isf-book-feature-matrix-audit.t](../t/1305-isf-book-feature-matrix-audit.t)
so the user-facing book keeps an explicit review surface for the shipped ISF
feature families.
The public constructor option boundary is checked by
[t/1125-isf-public-constructor-boundary-audit.t](../t/1125-isf-public-constructor-boundary-audit.t)
for both adapter and scheduler facades.
The public constructor receiver boundary is checked by
[t/1133-isf-public-constructor-receiver-boundary-audit.t](../t/1133-isf-public-constructor-receiver-boundary-audit.t).
The public parser facade method boundary is checked by
[t/1126-isf-public-parser-method-boundary-audit.t](../t/1126-isf-public-parser-method-boundary-audit.t).
The public `parse_file(...)` path boundary is checked by
[t/1134-isf-public-parse-file-path-boundary-audit.t](../t/1134-isf-public-parse-file-path-boundary-audit.t).
The public scheduler facade method boundary is checked by
[t/1127-isf-public-scheduler-method-boundary-audit.t](../t/1127-isf-public-scheduler-method-boundary-audit.t).
The parser and scheduler method receiver boundary is checked by
[t/1132-isf-public-method-receiver-boundary-audit.t](../t/1132-isf-public-method-receiver-boundary-audit.t).
The public facade failure diagnostic metadata is checked by
[t/1161-isf-public-facade-failure-diagnostic-metadata-audit.t](../t/1161-isf-public-facade-failure-diagnostic-metadata-audit.t)
to keep constructor, parser, and scheduler facade boundary failures advertised
as bounded scalar diagnostics.
The scheduler-consumable actor shell returned by the public parser facades is
checked by
[t/1129-isf-public-actor-shell-contract-audit.t](../t/1129-isf-public-actor-shell-contract-audit.t).
The actor-shell value-shape metadata is checked by
[t/1160-isf-public-actor-shell-value-shape-audit.t](../t/1160-isf-public-actor-shell-value-shape-audit.t)
to keep the `actor_name`, `transactions`, and `interface` public handoff
shapes exact across direct and manifest views.
The actor-shell interface subshape is checked by
[t/1162-isf-public-actor-shell-interface-shape-audit.t](../t/1162-isf-public-actor-shell-interface-shape-audit.t)
to keep the parser-returned `interface` inputs/outputs arrays and public port
entry `name`/`width` shape exact across direct and manifest views without
freezing the rest of the raw actor hash.
Actor top-level interface widths backed by actor-local scalar parameter
defaults are checked by
[t/1333-isf-interface-actor-param-widths.t](../t/1333-isf-interface-actor-param-widths.t)
so accepted `(width PARAM)` entries resolve to positive integer public port
widths, scheduled `.fsm` `+size` declarations, and HDL port ranges while
unknown symbolic names, runtime interface signals, zero-valued or non-scalar
actor parameters, and arbitrary expressions fail closed.
Actor top-level interface widths backed by declared actor constants are checked
by
[t/1338-isf-interface-actor-constant-widths.t](../t/1338-isf-interface-actor-constant-widths.t)
so accepted `(width CONST)` entries resolve to positive integer public port
widths, scheduled `.fsm` `+size` declarations, and HDL port ranges while
zero-valued actor constants, unknown symbolic names, runtime interface
signals, and arbitrary expressions fail closed.
The interface-port boundary is checked by
[t/1188-isf-interface-port-boundary.t](../t/1188-isf-interface-port-boundary.t)
so port names are unique across both input and output directions before an
actor shell is returned.
The actor-shell transaction subshape is checked by
[t/1163-isf-public-actor-shell-transaction-shape-audit.t](../t/1163-isf-public-actor-shell-transaction-shape-audit.t)
to keep parser-returned transaction entries discoverable as unique non-empty
scalar `name`, a `ports` hash with `inputs`/`outputs` arrays, and a `clauses`
array shell while leaving the clause payload contents private scheduler input.
The transaction-port declaration boundary is checked by
[t/1240-isf-transaction-port-declarations.t](../t/1240-isf-transaction-port-declarations.t)
so parser-accepted `(ports ...)` clauses normalize to directional
`name`/`width` entries and malformed direction, duplicate, width, or option
forms fail before scheduler lowering.
Actor-parameter-backed transaction port width declarations are checked by
[t/1336-isf-transaction-port-actor-param-widths.t](../t/1336-isf-transaction-port-actor-param-widths.t)
so the same public transaction shell exposes resolved positive integer widths
for accepted actor-local scalar parameter defaults and rejects transaction
parameters or unsupported symbolic sources before scheduler lowering.
Actor-constant-backed transaction port width declarations are checked by
[t/1342-isf-transaction-port-actor-constant-widths.t](../t/1342-isf-transaction-port-actor-constant-widths.t)
so the same public transaction shell exposes resolved positive integer widths
for accepted declared actor constants and rejects transaction parameters or
unsupported symbolic sources before scheduler lowering.
The first activation-binding lowering boundary is checked by
[t/1241-isf-transaction-port-bindings.t](../t/1241-isf-transaction-port-bindings.t)
so `do`, `spawn`, and rule-trigger input bindings accept scalar signals,
numeric/exact-width literals, and non-empty list expressions where shipped,
are direction- and known-width-checked, keep actor inputs read-only, reject
actor output readback, produce hidden generated-top handoffs for spawned
bindings, avoid duplicate same-name child wiring for explicit spawn binding
sources, and use per-rule source signals before trigger fan-in.
Repeat-body spawn bindings are checked by
[t/1215-isf-spawn-parameter-binding.t](../t/1215-isf-spawn-parameter-binding.t):
the shipped top-level repeat-body spawn plus same-body `await_all` subset may
also carry `(bind ...)` input and output handoffs on the same static generated
child instance used by top-level spawn.
The actor-pin binding conflict boundary is checked by
[t/1242-isf-port-binding-conflict-semantics.t](../t/1242-isf-port-binding-conflict-semantics.t)
so spawned output bindings keep parent-transaction ownership in assignment
provenance, conflicting rule writes fail through the existing
rule/transaction conflict path, and accepted spawn or rule-trigger binding
fan-in reaches the backend's verification-only selector instrumentation.
The transaction-port binding schedule-report projection is checked by
[t/1243-isf-port-binding-schedule-report.t](../t/1243-isf-port-binding-schedule-report.t)
so successful in-process and CLI reports expose bounded binding provenance
without exporting raw `LoweringIR` assignment internals.
The transaction wait boundary is checked by
[t/1244-isf-wait-clause-lowering.t](../t/1244-isf-wait-clause-lowering.t)
so `(wait N)` accepts non-negative integer literals and actor constants in
transaction body contexts, accepts actor-local scalar parameter defaults as
static wait counts when they resolve to non-negative integer literals, lowers
positive resolved counts to reviewable fixed wait-state chains, treats
resolved zero as a transparent no-op, accepts the known-width runtime scalar
and runtime expression count subsets including
consecutive top-level runtime waits and waits after shipped `await`, `stage`,
`repeat` exit, `await_all`, `await_any`, bank load/store, and loop-decision
predecessors,
reaches HDL generation, exposes `actor_constants[]` and
`actor_params[]` plus `transaction_waits[]` provenance, and rejects malformed,
unknown, unsupported parameter, unknown-width expression, or unsupported
dynamic counts.
Inline `when`, `repeat`, `switch`, `while`, and
`until` body dynamic waits are covered for the no-pending-sample subset. Branch
and loop decision states preserve their alternate exits while splitting the
selected dynamic-wait edge into positive-count load/entry and zero-count
bypass paths. Pending samples before top-level runtime waits are covered: the
positive path materializes samples in the first wait state, counts greater
than one continue through a no-resample wait-loop state, and the zero path uses
a sample-preserving clone of the following state when that state can carry the
sample without changing timing, including completion states that preserve their
delayed pulse and return-to-idle transition, independent scalar setter states,
independent shift states, independent assemble states, and independent extract
states, plus independent bank-load and bank-store states that neither read nor
overwrite a pending sample alias, plus top-level await_all/await_any sync
states whose collected done ports do not reference a pending sample alias,
plus top-level spawn states whose generated start handoff does not overwrite a
pending sample alias, plus top-level transaction phase pass-through states
that carry no assignments or guards, plus top-level ready/valid stage states
that neither read nor overwrite a pending sample alias, plus top-level
bounded-eventual contract arm states that neither read nor overwrite a pending
sample alias, plus repeat/while/until loop decision states whose assignments
and conditions do not touch a pending sample alias. Consecutive top-level
runtime waits carry pending samples across zero-count wait links by using generated
sample-preserving downstream wait-entry clones for zero-then-positive paths and
final compatible target clones for all-zero paths. Top-level zero-count
successors that cannot yet carry pending samples fail closed.
Pending samples before `when`-body and `switch`-branch runtime waits are now
covered by the same one-shot positive sample and zero-clone contract when the
selected successor can carry samples, including selected completion and
independent scalar setter, shift, assemble, extract, and bank-load successors.
Bank stores use the same sample-compatible contract when they are independent.
Setters, shifts, assemble states, extract states, bank-load states, or
bank-store states that read or overwrite a pending sample alias remain
fail-closed.
Pending samples before `repeat`, `while`, and `until` dynamic waits are covered
by the same contract for sample-compatible body successors while preserving
loop-back and loop-exit edges. Dynamic waits whose selected zero-count
successor cannot yet carry samples fail closed with diagnostics that name the
body context.
The runtime divisor safety boundary is checked by
[t/1308-isf-dynamic-divisor-safety.t](../t/1308-isf-dynamic-divisor-safety.t)
so shipped runtime expression contexts reject numeric/exact-width literal-zero
actor-constant-zero, and actor-parameter-zero division and modulo divisors
before scheduled `.fsm` emission while preserving nonzero literal divisors,
nonzero actor-constant divisors, nonzero actor-parameter divisors, and dynamic
scalar divisors unchanged.
The transaction loop boundary is checked by
[t/1245-isf-transaction-loop-lowering.t](../t/1245-isf-transaction-loop-lowering.t)
so top-level transaction `(while cond body...)` lowers as a pre-test
zero-or-more loop, `(until cond body...)` lowers as a body-first one-or-more
loop, conditions are sampled in generated decision states, successful reports
expose `transaction_loops[]`, and unsupported loop body combinations fail
closed.
The transaction-name boundary is checked by
[t/1185-isf-transaction-name-boundary.t](../t/1185-isf-transaction-name-boundary.t)
so duplicate transaction names fail before actor-shell return and downstream
target-resolution code sees one unambiguous same-actor transaction namespace.
The actor-shell actor-name shape is checked by
[t/1164-isf-public-actor-shell-actor-name-shape-audit.t](../t/1164-isf-public-actor-shell-actor-name-shape-audit.t)
to keep parser-returned `actor_name` discoverable as the non-empty scalar
identifier preserved from the ISF actor root.
The parser accepts exactly one top-level compile/report actor root. Multiple
top-level `(actor ...)` roots fail closed with a targeted diagnostic; sibling
actor roots are not ATL child type definitions until actor type resolution is
explicitly selected. One actor root plus `(library ...)` roots remains part of
the supported reusable-library source model.
The shipped ATL actor type-resolution spellings are library-qualified
`(instance NAME of ALIAS.EXPORT)` and compact `(NAME : ALIAS.EXPORT)`, where
`ALIAS` is an explicit library import alias and `EXPORT` is a library actor
export. The shipped resolution reports metadata and emits child artifacts:
`actor_network.instances[]` adds
`type_resolution`, `library`,
`alias`, `export`, `module`, and `scheduled_fsm` only for resolved
`ALIAS.EXPORT` actor types, and the lowerer emits the child scheduled `.fsm`
named by `scheduled_fsm` while keeping the parent scheduled `.fsm` unchanged.
The machine-readable contract advertises those keys through
`schedule_report_actor_network_resolved_instance_keys` while preserving
`schedule_report_actor_network_instance_keys` for unqualified metadata-only
instances. The first generated ATL top is now shipped for exactly one
resolved child, one parent trigger handoff, and one parent event wait with
matching parent/child clock and reset policy; its report entry is advertised
through `schedule_report_actor_network_generated_top_keys` under
`actor_network.generated_tops[]`. The bounded scalar top-level input-pin to
resolved-child input route, one exact-width vector top-level input-pin to
resolved-child input route, the same-child scalar pin-ingress multi-route
extension, the same-child vector pin-ingress multi-route extension, the
same-child mixed scalar/vector pin-ingress route-set extension, one scalar
resolved-child output to top-level output route, one
exact-width vector resolved-child output to top-level output route, and the
same-child scalar, vector, and mixed scalar/vector pin-egress route-set
extensions described below are also shipped for that same one-child top. The
first
control-only two-child generated top is shipped for sequential trigger/event
handoffs with no data movement; its generated-top entry uses `children[]`
records advertised through
`schedule_report_actor_network_generated_top_multi_child_keys` and
`schedule_report_actor_network_generated_top_child_keys`. The first
generated-child actor-to-actor route through that two-child top is also
shipped for `(writer.payload reader.payload)` when the parent transaction is
ordered as source trigger, source event wait, drive call, sink trigger, and
sink event wait. One-bit routes report `kind: "scalar_actor_handoff"` and
`width_source: "scalar_one_bit"`. Same-width vector routes report
`kind: "vector_actor_handoff"` and
`width_source: "resolved_child_endpoint_exact_width"`. The bounded multi-route
extension is shipped only for routes that share that same source child, sink
child, parent transaction, and contiguous route segment, with matching
source/sink endpoint widths per route. Each route uses existing
`schedule_report_actor_network_data_movement_keys`; no new report family is
introduced. The nearby hardening slices lock fail-closed diagnostics for
missing or wrong-direction child payload ports, width mismatches, and route
cardinality, but still do not expose new public keys. Broader generated ATL
tops, fan-in/fan-out data routing, broader data-route coupling, route
mux/storage, width adaptation, and inferred payload/ready/backpressure binding
remain unshipped behavior.
Unqualified
`(instance NAME of ACTOR_TYPE)` remains the current metadata-only external
intent surface.
The HDL coverage promotion for that same resolved-child generated-top fixture
is shipped: no new report keys were selected, and the proof asserts that plain
and strict CLI SystemVerilog contains the generated top, scheduled parent,
resolved child, and selected internal trigger/event links.
The first generated-child scalar pin-ingress route is shipped for one
top-level input pin to one resolved-child input through the generated top. One
exact-width vector pin-ingress route is also shipped when the top-level input
pin and resolved child input endpoint declare the same positive width; it
reports `kind: "vector_pin_to_actor_handoff"` and
`width_source: "top_level_input_pin_resolved_child_endpoint_exact_width"`.
The bounded multi-route extensions are shipped for multiple scalar top-level
input pins feeding multiple scalar inputs on that same resolved child, and for
multiple vector top-level input pins feeding matching vector child inputs on
that same resolved child, through adjacent drive-call cycles. Vector route-set
entries keep `kind: "vector_pin_to_actor_handoff"` and
`width_source: "top_level_input_pin_resolved_child_endpoint_exact_width"` per
route. The mixed scalar/vector pin-ingress route-set extension is also shipped
for scalar one-bit and exact-width vector routes into that same resolved child
through the same adjacent pre-trigger drive-call policy; each route preserves
its own `kind`, `width`, and `width_source`. All forms use the existing
`actor_network.data_movements[]` route metadata and
`actor_network.generated_tops[]` top discovery metadata; no new public report
family or public `data_links` key is exposed. The generated child `.fsm` may
include generated `+interface` role metadata for the selected child inputs so
the HDL backend preserves those child inputs as module ports.
The inverse generated-child pin-egress route is also shipped for one or more
one-bit resolved-child outputs to one or more one-bit top-level outputs through
the generated top. One exact-width vector pin-egress route is also shipped when
the resolved child output endpoint and top-level output pin declare the same
positive width; it reports `kind: "vector_actor_to_pin_handoff"` and
`width_source: "top_level_output_pin_resolved_child_endpoint_exact_width"`.
The same-child vector pin-egress multi-route subset accepts multiple such
routes when every route has unique child outputs/top-level pins and exact
matching route-local widths. The mixed scalar/vector pin-egress route-set
extension is also shipped for scalar one-bit and exact-width vector routes from
that same resolved child through the same adjacent post-event drive-call
policy; each route preserves its own `kind`, `width`, and `width_source`.
The scalar fixture uses `(pins.result worker.payload)`, and the bounded
route-set fixture uses `(pins.result worker.payload)` plus
`(pins.status worker.status)` from the same child after the event wait. All
forms use the existing `actor_network.data_movements[]` route metadata plus
`actor_network.generated_tops[]` top discovery metadata; no new public report
family or public `data_links` key is exposed. The generated child `.fsm` may
include generated `+interface` role metadata for each selected child output so
the HDL backend preserves those child outputs as module ports.
Generated-child actor-to-actor data movement across two resolved children is
shipped only for the documented same-source/same-sink scalar or exact-width
vector route set through the generated top. Width-mismatched or broader
actor-to-actor route fabrics still fail closed before FSMGen infers remapping,
storage, muxing, fan-in/fan-out, payload adaptation, or backpressure behavior;
no public data-link key is added for them.
The actor-shell timing shape is checked by
[t/1165-isf-public-actor-shell-timing-shape-audit.t](../t/1165-isf-public-actor-shell-timing-shape-audit.t)
to keep parser-returned `clock`, `reset`, and `watchdog` timing fields
discoverable as bounded current handoff metadata.
The default timing convention is checked by
[t/1331-isf-timing-conventions.t](../t/1331-isf-timing-conventions.t)
to keep omitted legacy single-clock timing normalized to clock `clk`, async
active-low reset `rst_n`, and watchdog `65535`, and to keep positive
actor-constant and actor-scalar-parameter watchdog limits resolved to the same
numeric public shape as literals.
The actor-shell rule shape is checked by
[t/1166-isf-public-actor-shell-rule-shape-audit.t](../t/1166-isf-public-actor-shell-rule-shape-audit.t)
to keep parser-returned rule entries discoverable as unique non-empty scalar
`name`, optional `when`, and `actions` array shells while leaving rule payload
contents private scheduler input.
The rule-name boundary is checked by
[t/1186-isf-rule-name-boundary.t](../t/1186-isf-rule-name-boundary.t)
so duplicate rule names fail before actor-shell return and generated rule DTs
plus rule-trigger source prefixes remain unambiguous.
The rule-action parser boundary is checked by
[t/1181-isf-rule-action-boundary.t](../t/1181-isf-rule-action-boundary.t)
so accepted rule actions have explicit `(set port expr)`, `(port expr)`,
`(trigger transaction)`, or `(priority over other_rule)` shapes before a rule
enters the actor shell. Assignment RHS values may be scalar tokens or
non-empty list expressions with scalar expression heads.
The scalar setter syntax boundary is checked by
[t/1246-isf-setter-syntax.t](../t/1246-isf-setter-syntax.t)
so `(set lhs expr)` is accepted in rule and transaction contexts, malformed
setter forms fail closed with targeted diagnostics, rule setters lower as
guarded flopped rule assignments, and transaction setters lower as ordered
flopped transaction states that reach HDL generation.
The rule-expression assignment lowering path is checked by
[t/1221-isf-rule-expression-assignment.t](../t/1221-isf-rule-expression-assignment.t)
so expression-valued rule assignments preserve through scheduled `.fsm`
emission, assignment provenance, normal `.fsm` frontend parsing, and HDL
generation while keeping the existing flopped `<-` rule assignment family.
The expression-valued rule conflict/report path is checked by
[t/1222-isf-rule-expression-conflict-report.t](../t/1222-isf-rule-expression-conflict-report.t)
so same-expression rule writes appear as compatible fan-in, different
expression writes fail closed through `isf_conflicting_rule_writes`, and
priority-resolved expression conflicts project through `priority_resolutions`.
The disjoint-rule write path is checked by
[t/1234-isf-disjoint-rule-writes.t](../t/1234-isf-disjoint-rule-writes.t)
so same-target FIFO-style rule writes are accepted when direct contradictory
guard literals prove the rules cannot fire in the same cycle, while
overlapping expression guards still fail closed through
`isf_conflicting_rule_writes`.
The rule-trigger target boundary is checked by
[t/1182-isf-rule-trigger-target-boundary.t](../t/1182-isf-rule-trigger-target-boundary.t)
so `(trigger transaction)` must name a declared transaction in the same actor.
Forward references are accepted because validation runs after the full actor
body is collected; missing targets fail before actor-shell return.
The rule-guard scheduled `.fsm` DTE-header shape is checked by
[t/1168-isf-rule-guard-factoring.t](../t/1168-isf-rule-guard-factoring.t)
so rule actions remain grouped under one guarded non-state DT enable in review
artifacts.
The shorthand rule-guard parser/lowering path is checked by
[t/1169-isf-rule-shorthand-guard.t](../t/1169-isf-rule-shorthand-guard.t)
to keep `(rule name condition actions...)` normalized to the same public
`when` field as `(rule name (when condition) actions...)`.
The rule-trigger fan-in path is checked by
[t/1171-isf-rule-trigger-fanin.t](../t/1171-isf-rule-trigger-fanin.t)
so multiple rule triggers for one transaction preserve distinct trigger
sources before generated combinational fan-in.
The schedule-report projection of that same fan-in path is checked by
[t/1172-isf-rule-trigger-fanin-schedule-report.t](../t/1172-isf-rule-trigger-fanin-schedule-report.t)
so downstream consumers can rely on the advertised DT kind/order and one-bit
inferred-storage summaries for the generated trigger sources.
The static rule-conflict path is checked by
[t/1209-isf-static-conflict-detection.t](../t/1209-isf-static-conflict-detection.t)
so provable incompatible rule/rule data writes fail closed, compatible
same-value rule writes remain accepted, rule/drive overlap is flagged
internally as `proof_status => not_doable`, and ordinary transaction state
mux behavior remains accepted.
The rule-priority conflict-resolution path is checked by
[t/1210-isf-priority-conflict-resolution.t](../t/1210-isf-priority-conflict-resolution.t)
so rule-local and actor-level rule priorities can suppress lower-priority
same-target rule assignments, while priority cycles fail closed.
The verification-only runtime selector instrumentation path is checked by
[t/1211-isf-runtime-selector-conflict-instrumentation.t](../t/1211-isf-runtime-selector-conflict-instrumentation.t)
so same-value source selector checks, whole-mux value selector checks, and the
Verilog no-assertion boundary remain regression-backed after ISF lowers through
scheduled `.fsm` into HDL.
The explicit-width `shift_right` data-operation path is checked by
[t/1173-isf-shift-right-explicit-width.t](../t/1173-isf-shift-right-explicit-width.t)
so explicit `(width N|PARAM|CONST)` fills otherwise missing register-width
evidence, known-width shifts do not need the option, conflicting explicit
widths fail closed, and accepted `shift_right` source no longer emits
placeholder `WIDTH` terms.
The explicit-width `shift_left` data-operation path is checked by
[t/1318-isf-shift-left-explicit-width.t](../t/1318-isf-shift-left-explicit-width.t)
so optional `(width N|PARAM|CONST)` fills missing register-width evidence for
later data operations and schedule-report storage metadata, conflicting
explicit widths fail closed, and ordinary widthless `shift_left` source
remains accepted.
The explicit-width `extract` data-operation path is checked by
[t/1174-isf-extract-explicit-widths.t](../t/1174-isf-extract-explicit-widths.t)
so authors can avoid placeholder slice bounds when extract field widths are
not declared elsewhere.
Static data-operation width sources are checked by
[t/1343-isf-data-op-static-width-sources.t](../t/1343-isf-data-op-static-width-sources.t),
so `shift_left`, `shift_right`, and `extract` explicit width evidence may use
positive integer literals, actor-local scalar parameter defaults, or declared
actor constants that resolve to positive integers. Unsupported transaction
parameters, runtime interface signals, unknown names, arbitrary expressions,
zero values, and aggregate values fail closed.
Assemble static part widths are checked by
[t/1344-isf-assemble-static-part-widths.t](../t/1344-isf-assemble-static-part-widths.t),
so `(assemble part... as target (widths N|PARAM|CONST...))` supplies ordered
part-width evidence from the same accepted static source set while preserving
the emitted concat assignment shape.
The single-missing-field `extract` inference path is checked by
[t/1101-isf-extract-slices.t](../t/1101-isf-extract-slices.t), so one
unknown destination field can derive its width from a known source word and
known sibling fields before later data operations consume that width evidence.
The temporal-contract lowering boundary is checked by
[t/1175-isf-contract-fail-closed.t](../t/1175-isf-contract-fail-closed.t)
and [t/1224-isf-contract-lowering.t](../t/1224-isf-contract-lowering.t).
The shipped subset is the top-level transaction form
`(contract name (eventually signal within cycles))`. The older nested
`(contract name (eventually signal (within cycles)))` spelling remains an
accepted alias; both lower to one arm state plus an always-on monitor DT with
pending, age, and sticky-fail storage. The `cycles` token may be a positive
integer literal, a declared actor constant, or an actor-local scalar parameter
default that resolves to a positive integer. Transaction parameters, runtime
signals, arbitrary expressions, unknown names, zero-valued constants, and
zero-valued or non-scalar actor parameters remain outside the contract-window
surface.
Schedule reports classify that DT as `temporal_contract_monitor` and classify
the generated pending/fail storage as registers and age storage as a counter.
Those three monitor storage entries also carry the advertised
`temporal_contract_monitor` `inferred_storage[].role`; the bounded
`temporal_contracts[]` summary remains the public place to distinguish the
pending, counter, and fail signal names.
The bounded `temporal_contracts` summary projection reports the public trigger,
observed signal, cycle bound, generated storage names, reset policy, overlap
policy, and assertion projection status for downstream consumers.
Actor-constant and actor-scalar-parameter windows report the resolved positive
integer in `within_cycles`; no public source-token field is added.
Unsupported top-level bodies and nested contracts still fail closed with
targeted diagnostics. Verification-only assertion text is not advertised yet.
The parser boundary for resource and priority metadata is checked by
[t/1176-isf-resource-priority-boundary.t](../t/1176-isf-resource-priority-boundary.t)
so malformed `(resources ...)`, actor-level `(priority lhs over rhs)`, and
rule-local `(priority over other_rule)` forms are rejected before an actor
shell is returned. Current parser metadata carries resource names, arbiter
strings, and optional resource-kind/user/member metadata. A resource name is the
author-defined instance handle; the resource kind is the public registry entry
that says what type of shareable thing the instance represents. The enforced
resource kinds are `rule_slot`, a one-cycle mutual-exclusion slot for rule
users; `output_bundle`, a named bundle of actor outputs or rule-written LHS
targets for rule users; `transaction_start`, one-cycle arbitration for
rule-trigger request fan-in into one local transaction; and `storage_port`,
one-cycle arbitration for rule users that update explicit actor-owned storage
signals. `output_bundle` may carry explicit
`(members target...)` metadata naming declared actor output ports or concrete
actor-owned storage signals. Explicit members are narrower than the unmembered
implicit bundle surface: they validate/report declared outputs and storage
signals, not bank roots, aggregate paths, inferred LHS targets, arbitrary
storage ownership, or route ownership. A `transaction_start` resource name
must be the target local transaction name; every bound rule user must trigger
that transaction through the shipped non-generated rule-trigger surface. Under
`priority`, the resource suppresses lower-priority rule DTs before their
trigger source pulses feed the generated `{transaction}_trigger_fanin` DT.
Under bounded `round_robin`, the generated pointer grant gates the winning
rule DT before the same trigger-source fan-in path. A `storage_port` resource
with bound users must carry explicit `(members target...)` metadata naming
concrete actor-owned storage signals: scalar storage variables or scalarized
bank element signals. Storage-port members do not include bank roots,
aggregate paths, inferred LHS targets, transaction ports, actor input ports,
or arbitrary expressions. Shipped resource kinds use the static `priority`
arbiter, and `rule_slot`, `output_bundle`, `transaction_start`, and
`storage_port` also support bounded `round_robin` arbitration for declared
rule users. Bounded
round-robin uses the `(users ...)` list as a circular grant order, emits
`isf_rr_<resource>_turn` pointer storage, grants the first requesting rule at
or after the current pointer, and advances the pointer from the winning rule
DT. The pointer is public report metadata in `inferred_storage[]` with role
`resource_round_robin_pointer`. The generated pointer name must not collide
with existing actor ports, constants, parameters, declared storage, or
generated counters.
The current shareable resource registry is: `rule_slot` (shipped for
`priority` and bounded `round_robin` arbitration), `output_bundle` (shipped
for `priority` and bounded `round_robin` arbitration), `transaction_start`
(shipped for `priority` and bounded `round_robin` arbitration),
`storage_port` (shipped for `priority` and bounded `round_robin`
arbitration),
`interface_bundle`, `named_drive`, and `child_instance`. The non-shipped kinds
are public catalog/backlog names, not public runtime behavior, until their
lowering paths, runtime semantics, diagnostics, report surfaces, and
regressions ship. `round_robin` remains unsupported for backlog resource
kinds and other non-selected resource surfaces.
The code owner for that registry is `FSM::Support::ISFResourceCatalog`; the
parser and this public contract both consume it. Downstream consumers can
discover the current values through `resource_arbiter_values`,
`resource_kind_values`, `resource_kind_status_map`,
`resource_kind_meaning_map`, `enforced_resource_kind_values`, and
`backlog_resource_kind_values` on `embedding.isf_public_interface`.
The first resource-arbitration path is checked by
[t/1218-isf-rule-slot-resource-arbitration.t](../t/1218-isf-rule-slot-resource-arbitration.t)
for parser metadata, `rule_slot`, `output_bundle`, `transaction_start`, and
`storage_port` scheduled `.fsm` DTE gating, bounded `rule_slot`/`round_robin`,
`output_bundle`/`round_robin`, `transaction_start`/`round_robin`, and
`storage_port`/`round_robin` grant gating and pointer state, output-bundle
output/storage member-list coverage,
transaction-start trigger-user validation, storage-port storage-member
validation, HDL handoff, and fail-closed unsupported arbitration cases.
The first rule/transaction priority path is checked by
[t/1219-isf-rule-transaction-priority.t](../t/1219-isf-rule-transaction-priority.t)
for accepted rule-over-transaction suppression, accepted transaction-over-rule
suppression through scheduled `.fsm` state-active guards, unordered conflict
rejection, and cycle rejection.
The arbitration schedule-report projection is checked by
[t/1220-isf-arbitration-schedule-report.t](../t/1220-isf-arbitration-schedule-report.t)
for bounded successful `priority_resolutions` and `resource_arbitration`
entries across the in-process scheduler and CLI JSON path.
The rule-local priority target boundary is checked by
[t/1190-isf-rule-priority-target-boundary.t](../t/1190-isf-rule-priority-target-boundary.t)
so `other_rule` in `(priority over other_rule)` must resolve to a declared
same-actor rule before actor-shell return. Forward references remain accepted.
The actor-level priority target boundary is checked by
[t/1191-isf-actor-priority-target-boundary.t](../t/1191-isf-actor-priority-target-boundary.t)
so both sides of `(priority lhs over rhs)` must resolve to declared same-actor
transactions or rules before actor-shell return. Forward references remain
accepted.
The singleton actor-clause boundary is checked by
[t/1192-isf-singleton-actor-clause-boundary.t](../t/1192-isf-singleton-actor-clause-boundary.t)
so `(clock ...)`, `(reset ...)`, `(watchdog ...)`, `(interface ...)`, and
`(resources ...)`, and `(storage ...)` fail closed when repeated instead of
letting later clauses overwrite earlier public actor-shell fields.
The blocking `do` child-completion handoff is checked by
[t/1177-isf-do-child-done-pulse.t](../t/1177-isf-do-child-done-pulse.t)
so the generated internal `child_done` signal remains a one-cycle delayed pulse
through scheduled `.fsm` parsing and HDL generation.
The child transaction target boundary is checked by
[t/1184-isf-child-transaction-target-boundary.t](../t/1184-isf-child-transaction-target-boundary.t)
so `(do child ...)` and `(spawn child as instance ...)` must resolve `child`
to a declared same-actor transaction before scheduled `.fsm` emission, while
forward references remain accepted. Parameterized/generated `do` uses a
generated child activation instance; local unparameterized `do` keeps the
rewired child-completion pulse path.
The deprecated handshake compatibility boundary is checked by
[t/1178-isf-handshake-compatibility-boundary.t](../t/1178-isf-handshake-compatibility-boundary.t)
so `(handshake name (valid signal) (ready signal))` metadata requires exactly
one scalar `valid` and one scalar `ready`, rejects duplicate handshake names,
and remains ignored after validation. Old handshake semantics are still not
lowered.
The phase/stage boundary is checked by
[t/1179-isf-phase-stage-boundary.t](../t/1179-isf-phase-stage-boundary.t)
so actor-level phase/stage metadata and transaction phase/stage clauses have
scalar names plus list-form body entries before an actor shell is returned.
Transaction `(phase ...)` remains a pass-through state marker; transaction
`(stage name (ready ready_signal) (valid valid_signal))` has its first
bounded lowering path checked by
[t/1223-isf-stage-lowering.t](../t/1223-isf-stage-lowering.t): it emits one
ready-gated state that drives `valid_signal = 1` while active, parses through
the normal `.fsm` frontend, and reaches SystemVerilog generation. The older
`(stage name (input ready_signal) (output valid_signal))` spelling remains an
accepted alias for the same public schedule-report projection. The generated
valid drive remains a transaction assignment, so the existing same-target
conflict diagnostics still apply when another owner writes that signal.
Actor-level phase/stage metadata is also checked by
[t/1252-isf-actor-phase-stage-report.t](../t/1252-isf-actor-phase-stage-report.t):
it is copied into `LoweringIR` only for bounded `actor_phases[]` and
`actor_stages[]` schedule-report projection, and it still does not create
generated `.fsm`, generated composition-top, or HDL runtime behavior.
The unsupported transaction-clause boundary is checked by
[t/1180-isf-unsupported-transaction-clause-boundary.t](../t/1180-isf-unsupported-transaction-clause-boundary.t)
so removed or future transaction clause heads, including `(assign ...)`, fail
closed instead of disappearing from scheduled `.fsm` output. Removed
`(assign ...)` has targeted migration guidance, while unknown future keywords
keep the generic unsupported-clause diagnostic. The nested `when`, `switch`,
and `repeat` body contexts use the same shipped-lowerer boundary, while
unsupported `contract` clauses and deferred nested/unsupported `stage` forms
keep their dedicated diagnostics. The shipped top-level
bounded-eventual `contract` subset is covered separately by
[t/1224-isf-contract-lowering.t](../t/1224-isf-contract-lowering.t).
The actor-shell drive shape is checked by
[t/1167-isf-public-actor-shell-drive-shape-audit.t](../t/1167-isf-public-actor-shell-drive-shape-audit.t)
to keep parser-returned drive definitions discoverable as a unique
drive-name-keyed hash of `params` and `body` arrays with body entries
validated as scalar `(port value)` pairs while leaving richer drive semantics
private scheduler input.
The drive-name boundary is checked by
[t/1187-isf-drive-name-boundary.t](../t/1187-isf-drive-name-boundary.t)
so duplicate drive definitions fail before actor-shell return instead of
silently overwriting an earlier drive body in the parser handoff.
The drive-body boundary is checked by
[t/1194-isf-drive-body-boundary.t](../t/1194-isf-drive-body-boundary.t)
so malformed body entries fail before actor-shell return instead of being
skipped during drive-DT construction or stringified as unsupported payloads.
The drive-call arity boundary is checked by
[t/1193-isf-drive-call-arity-boundary.t](../t/1193-isf-drive-call-arity-boundary.t)
so known drive calls require exactly one actual value per declared formal
parameter. Missing actuals and extra actuals fail during lowering instead of
emitting unbound parameter signals or ignoring author-provided values.
The sample-clause boundary is checked by
[t/1195-isf-sample-clause-boundary.t](../t/1195-isf-sample-clause-boundary.t)
so standalone samples and `(on ...)` inline samples must use exactly
`(sample port as name)` with scalar names. Unsupported `(on ...)` body forms
fail closed instead of being ignored. Direct `(on ...)` activation is not a
parameter-override site; `(on start (params ...))` stays outside the public
syntax and must fail closed like any other unsupported entry-body form.
The complete-clause boundary is checked by
[t/1196-isf-complete-clause-boundary.t](../t/1196-isf-complete-clause-boundary.t)
so `(complete port)` must name exactly one scalar completion target before
scheduled `.fsm` emission.
The latency-clause boundary is checked by
[t/1197-isf-latency-clause-boundary.t](../t/1197-isf-latency-clause-boundary.t)
so `(latency ...)` accepts positive-integer literal or declared positive
actor-constant or actor-local scalar-parameter `(min N)` and `(max N)`
options, rejects duplicates, requires `min <= max` when both are present,
rejects transaction parameters, runtime interface signals, unknown symbols,
arbitrary expressions, zero-valued constants, and zero-valued or non-scalar
actor parameters, and uses valid explicit `max` bounds for the generated
counter width/max check. Actor-constant and actor-scalar-parameter latency
bounds resolve to the same generated `.fsm` and schedule-report storage shape
as the equivalent literal; there is no separate latency-bound source-token
report field.
The update-clause boundary is checked by
[t/1198-isf-update-clause-boundary.t](../t/1198-isf-update-clause-boundary.t)
so `(update var expr)` has exactly one scalar target and one scalar or list
expression payload, and nested expression payloads are formatted as `.fsm`
expressions instead of Perl reference strings.
The shift-clause boundary is checked by
[t/1199-isf-shift-clause-boundary.t](../t/1199-isf-shift-clause-boundary.t)
so `(shift_left reg bit [(width N|PARAM|CONST)])` and
`(shift_right reg bit [(width N|PARAM|CONST)])` require scalar register/bit
operands before scheduled `.fsm` emission.
The assemble-clause boundary is checked by
[t/1200-isf-assemble-clause-boundary.t](../t/1200-isf-assemble-clause-boundary.t)
so `(assemble part... as target [(widths N|PARAM|CONST...)])` requires one or
more scalar parts, one scalar target, and any optional trailing width list to
match the part count before scheduled `.fsm` emission. The same regression
covers the width-evidence boundary: explicit widths derive target evidence for
later data operations, known part-width sums must match any already-known
target width, and when exactly one part width is missing, a known target width
and known sibling part widths infer that missing width as a positive
remainder. Multiple unknown parts remain non-evidence concat operands unless
explicit widths make them known.
The extract-clause boundary is checked by
[t/1201-isf-extract-clause-boundary.t](../t/1201-isf-extract-clause-boundary.t)
so `(extract word as field... [(widths N|PARAM|CONST...)])` requires one
scalar source word, one or more scalar fields, and at most one ordered
positive static-width `(widths ...)` option before scheduled `.fsm` emission.
The exact-slice extraction behavior is checked by
[t/1101-isf-extract-slices.t](../t/1101-isf-extract-slices.t), so accepted
`extract` source emits concrete descending slices, infers exactly one missing
field width from known source and sibling widths, and fails closed for multiple
unknown field widths, non-positive inferred remainders, or known source/field
width disagreement instead of emitting placeholder slice bounds.
The repeat-clause boundary is checked by
[t/1202-isf-repeat-clause-boundary.t](../t/1202-isf-repeat-clause-boundary.t)
so `(repeat count body...)` requires one scalar non-empty count and at least
one list-form body clause before repeat counter emission.
Repeat counter width inference is checked by
[t/1102-isf-repeat-counter-widths.t](../t/1102-isf-repeat-counter-widths.t),
so positive decimal literal counts use the minimum width for the loaded count,
positive actor constants and actor scalar parameter defaults use their resolved
integer value as width evidence while preserving the authored load token, and
sampled/runtime names continue to use known source width.
The same boundary test also checks that literal zero repeat counts and actor
constants or actor scalar parameters resolving to zero fail closed before
scheduled `.fsm` emission.
Known-width runtime scalar repeat counts now split the repeat init edge:
nonzero values enter the repeat body, while zero values bypass the body and
repeat check to the state after the repeat region. Unknown names, non-scalar
actor parameters, transaction parameters, malformed scalar tokens, and
expression-valued counts fail closed before scheduled `.fsm` emission.
The shipped repeat-body clause surface is named drive calls, `await`, `sample`,
`update`, `set`, `shift_left`, `shift_right`, `assemble`, `extract`,
actor-owned bank `store` and `load`, shipped `wait` clauses, the top-level
local blocking `(do child)` subset, and top-level generated blocking
`(do child)` when the target child is already emitted as a generated child by
another activation site, plus
`(do child (params ...) [(bind ...)] [(domain NAME)])` with static parameter
overrides, optional input/output port bindings, and optional declared
same-domain ownership metadata. Local repeat-body `do` starts a child
transaction that remains in the parent scheduled module and waits for the
child's fresh `child_done` pulse before the repeat check can loop. Repeats
directly inside a top-level `when` body also accept that local `(do child)`
form, plain generated-child `(do child)` when the target child is already
emitted as a generated child by another activation site, and generated
blocking `(do child (params ...))` with static parameter overrides. The
generated when-contained forms emit one deterministic
`{parent}_{child}_repeat_do_{ordinal}` instance for the lexical nested do
site, apply parameter overrides once when present, preserve source-order
samples around the nested do, and gate the branch-owned repeat check on that
generated instance's fresh done handoff.
The same switch-contained local, plain generated-child, and static-parameter
generated `do` forms are shipped for repeats directly inside a top-level
`switch` branch, with the same deterministic generated-instance naming,
static parameter application once when present, source-order sample timing,
and done-gated branch-owned repeat check. When-contained and switch-contained
generated nested `do` also accept `(bind ...)` when static `(params ...)`
overrides are present; the generated top wires those input/output binding
handoffs once for the lexical nested do site. When-contained and
switch-contained generated nested `do` also accept `(domain NAME)` as declared
same-domain metadata when static `(params ...)` overrides are present. Deeper
branch nesting and loop-contained repeats remain
outside both nested subsets. Generated
repeat-body `do` emits one generated child instance for the lexical do site,
applies the parameter override once in the generated top, wires optional
binding handoff ports once for that generated instance, records same-domain
ownership for generated-composition and clock-domain report summaries when
`(domain NAME)` is present, and waits for that generated instance's done
handoff before the repeat check. Samples may appear before or after
repeat-body `do`; pending samples before `do` materialize before the do state,
while pending samples after `do` materialize after the do state's fresh done
guard and before the repeat check. Cross-domain repeat-body `do` remains
deferred. The shipped repeat-body clause surface
also includes the top-level spawn plus same-body `await_all` subset with
optional static `(params ...)` overrides, optional `(bind ...)` port handoffs,
and optional declared same-domain `(domain NAME)` ownership metadata.
Single-pending repeat-body `await_any` is also shipped when exactly one
repeat-body spawn is pending. Multi-pending repeat-body `await_any` is shipped
only as an observation point when a later same-body `await_all` drains the same
outstanding spawned children before the repeat check; new repeat-body `spawn`
or `do` clauses before that drain remain rejected. Cross-domain repeat-body
`do`, generated or spawned nested activation beyond the documented top-level
branch-contained generated do cases, broader outstanding-child semantics,
`stage`, `contract`, deeper branch nesting, nested `while`, and nested
`until` remain outside the shipped repeat-body subset.
Samples may appear before or after repeat-body spawn as long as the same
repeat body reaches same-body `await_all`, single-pending `await_any`, or
multi-pending `await_any` followed by same-body `await_all` before the repeat
check can loop. Pending samples materialize in an explicit sample state at
their source-order timing point: before a later spawn state for
sample-before-spawn ordering, or before the sync state for sample-after-spawn
ordering. A repeat directly inside a top-level `when` body also accepts one
or more generated
`(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])` sites when
the same nested repeat body reaches `(await_all done)` before the nested
repeat check can loop. A repeat directly inside a top-level `switch` branch
accepts the same multiple generated-spawn plus same-body `await_all` subset.
Both branch-contained paths may use single-pending `(await_any done)` directly
when exactly one generated child is pending. Both branch-contained paths may
also use multi-pending `(await_any done)` as an observation point when a later
same-body `(await_all done)` drains the same outstanding generated children
before the nested repeat check can loop. Those branch-contained nested spawns
reuse the static generated-child handoff model and preserve source-order
samples before the nested spawn or sync states. The top-level `when` body and
top-level `switch` branch nested-repeat forms may also run a local plain
`(do child)` while generated nested spawns remain pending either before or
after a prior multi-pending `(await_any done)` observation, provided a later
same-body `(await_all done)` drains every outstanding generated child before
the nested repeat check can loop. That local do remains in the parent
scheduled module, waits for its own fresh local done pulse, and does not clear
the generated-spawn done set. The top-level `when` body and top-level
`switch` branch nested-repeat subsets also accept plain generated-child
`(do child)`
while generated nested spawns remain pending when the target child is already
emitted as a generated child by another activation site. The top-level `when`
body and top-level `switch` branch subsets may also place that generated-child
do after a prior multi-pending `(await_any done)` observation. That generated
do owns one deterministic
`{parent}_{child}_repeat_do_{ordinal}` instance, waits for that instance's
fresh done handoff, and leaves pending generated-spawn done handoffs live for
the later same-body `await_all` drain. The documented top-level `when` body
and top-level `switch` branch nested subsets also support static-parameter
generated `(do child (params ...))` after a prior multi-pending `await_any`,
with the same later same-body `await_all` drain requirement. The documented
top-level `when` body nested subset additionally supports static-parameter
generated `(do child (params ...) (bind ...))` after a prior multi-pending
`await_any`, with generated-top input/output binding handoffs and the same
later same-body `await_all` drain requirement; the documented top-level
`switch` branch nested subset now supports the same bound generated-do
after-`await_any` contract. The documented top-level `when` body and
top-level `switch` branch nested subsets additionally support static-
parameter same-domain generated
`(do child (params ...) [(bind ...)] (domain NAME))` after a prior
multi-pending `await_any`, with declared ownership metadata and the same later
same-body `await_all` drain requirement. `await_any` after that do and new
nested `spawn` after that do before the drain remain fail-closed.
The shipped repeat-body child-activation subset is
local `(do child)`, generated-child `(do child)`, generated
`(do child (params ...) [(bind ...)] [(domain NAME)])`, plus
`(spawn child as instance [(params ...)] [(bind ...)] [(domain NAME)])`
followed by a same-body `(await_all done)` before the repeat check can loop,
including the documented top-level when-body and switch-branch nested
generated-spawn subsets and the documented top-level when-body nested local
`do` after a prior multi-pending `await_any`, top-level when-body nested
plain generated-child `do` including after a prior multi-pending `await_any`,
top-level when-body nested static-parameter generated `do` after a prior
multi-pending `await_any`, plus top-level switch-branch nested local, plain
generated-child, and static-parameter generated `do` after a prior multi-
pending `await_any` while generated nested spawns are pending before a same-
body `await_all` drain.
The local `(do child)` subset is also shipped inside a repeat directly inside
a top-level `when` body or top-level `switch` branch. Those top-level nested
repeat subsets also accept plain generated-child `(do child)` for a target
already generated elsewhere. The top-level `when` nested repeat subset also
accepts static `(params ...)` on generated blocking `do`, optionally paired
with `(bind ...)` handoffs and same-domain `(domain NAME)` metadata; those
generated nested do forms remain done-gated before the nested repeat check.
Local repeat-body `do` reuses the local child start/done pulse contract.
Generated repeat-body `do` reuses the generated child start/done handoff
contract with a deterministic `{parent}_{child}_repeat_do_{ordinal}` instance;
plain generated-child repeat `do` uses that handoff without local overrides,
while parameterized generated repeat `do` reuses the generated-child
input/output binding handoff contract when `(bind ...)` is present and reuses
same-domain ownership metadata when `(domain NAME)` is present.
Repeat-body spawn reuses one static generated child instance across
iterations. Optional parameter overrides specialize that instance once in the
generated top, optional input/output bindings create generated handoff ports
once for the same static instance, and optional domain annotations group the
static child with a declared same-domain activation owner without implying CDC
behavior.
`(await_any done)` may replace `await_all` directly only for the
exactly-one-pending spawn case. Top-level repeat bodies and the documented
branch-contained nested repeat subsets may also use multi-pending `await_any` as
an observation point before a later same-body `await_all` drain. Samples after
the spawn lower before the sync state; a later spawn after a pending sample
remains outside the shipped subset.
In the documented top-level `when` body and top-level `switch` branch nested
subsets, local plain `(do child)` may run while generated nested spawns are
pending before or after a prior multi-pending `await_any` observation. The
local do uses only the parent-module local child start/done contract and
leaves the generated-spawn done set live until the later same-body
`await_all` drain. In the top-level `when` body and top-level `switch` branch
subsets, local plain `(do child)` may also run before a post-do multi-pending
`await_any` observation when that later same-body `await_all` still drains
every pending generated spawn before nested repeat re-entry. Generated `do`
forms with parameters, binding handoffs, or domain metadata are separate
contracts from that local do subset; generated-child, static-parameter, and
the documented top-level when-body bound generated `do` after prior multi-
pending `await_any` are shipped through their own bounded contracts, while
domain-qualified generated `do` after prior multi-pending `await_any` is
shipped for the documented top-level branch-contained same-domain subsets.
In the top-level `when` body subset, plain generated-child `(do child)` may
also run before a post-do multi-pending `await_any` observation when that
later same-body `await_all` still drains every pending generated spawn before
nested repeat re-entry. The top-level `switch` branch plain generated-child
subset supports the same post-do multi-pending `await_any` observation and
later same-body `await_all` drain contract. In the top-level `when` body
subset, static-parameter generated `(do child (params ...))` may also run
before a post-do multi-pending `await_any` observation when the generated do
waits for its deterministic generated do instance's fresh done handoff and
the later same-body `await_all` still drains every pending generated spawn
before nested repeat re-entry. The top-level `switch` branch subset supports
the same static-parameter generated-do post-do `await_any` observation and
later same-body `await_all` drain contract. The top-level `when` body subset
also supports static-parameter bound generated
`(do child (params ...) (bind ...))` before post-do `await_any`, wiring the
generated-top input/output binding handoffs for that generated do instance
while preserving the same later-drain contract. The top-level `switch` branch
subset supports the same static-parameter bound generated-do post-do
`await_any` observation and later-drain contract. Domain-qualified
generated-do post-do `await_any` and new spawn after the do before the drain
remain outside the public shipped subset.
In the documented top-level `when` body and top-level `switch` branch nested
subsets, plain generated-child `(do child)` may also run while generated
nested spawns are pending. In the top-level `when` body and top-level
`switch` branch subsets, that plain generated-child do may also run after a
prior multi-pending `await_any` observation. The generated do uses only its
deterministic generated do instance's start/done handoff and leaves the
generated-spawn done set live until the later same-body `await_all` drain. In
the documented top-level `when` body and top-level `switch` branch nested subsets,
static-parameter generated `(do child (params ...))` may also run while
generated nested spawns are pending. In both top-level branch-contained
subsets, that static-parameter generated do may also run after a prior multi-
pending `await_any` observation. The generated do uses its deterministic
generated do instance, preserves static generated-top parameter binding, and
leaves the generated spawn done set live until the later same-body
`await_all` drain. In the documented top-level `when` body and top-level
`switch` branch nested subsets, static-parameter generated
`(do child (params ...) (bind ...))` may also run while generated nested spawns
are pending. The generated do wires generated-top input/output binding
handoffs once, waits for its own fresh done handoff, and leaves the generated
spawn done set live until the later same-body `await_all` drain. In the top-
level `when` body and top-level `switch` branch subsets, that bound generated
do may also run after a prior multi-pending `await_any` observation.
In the documented top-level `when` body and top-level `switch` branch nested
subsets, static-parameter generated
`(do child (params ...) [(bind ...)] (domain NAME))` may also run while
generated nested spawns are pending. The domain annotation is declared
same-domain ownership metadata only for the deterministic generated do
instance; generated-composition/domain partition metadata and schedule JSON
`clock_domains[].child_instances[]` retain that ownership without implying
CDC. In the top-level `when` body and top-level `switch` branch subsets, that
same-domain generated do may also run after a prior multi-pending `await_any`
observation, still requiring the later same-body `await_all` drain before
nested repeat re-entry. Later `await_any` after generated `do` and new spawn
after that generated do before the drain remain outside the public shipped
subset.
The count is a runtime counter load value, not a hardware-elaboration count:
literal counts provide fixed loop bounds, while named scalar counts may be
dynamic when their width is known. Dynamic counts make latency data-dependent
and require explicit zero-count and verification-bound policy before the
repeat surface is widened further.
The await-sync clause boundary is checked by
[t/1203-isf-await-sync-clause-boundary.t](../t/1203-isf-await-sync-clause-boundary.t)
so `(await_all done_port)` and `(await_any done_port)` require exactly one
scalar done-port operand before sync-state emission.
The child-composition clause boundary is checked by
[t/1204-isf-child-composition-clause-boundary.t](../t/1204-isf-child-composition-clause-boundary.t)
so `(do transaction [(domain NAME)] [(params (NAME value) ...)] [(bind ...)])` and
`(spawn transaction as instance [(domain NAME)] [(params (NAME value) ...)] [(bind ...)])`
require exact scalar child/instance operands before child-target resolution or
generated-child collection.
Spawn and blocking `do` parameter binding are checked by
[t/1215-isf-spawn-parameter-binding.t](../t/1215-isf-spawn-parameter-binding.t).
Rule-trigger parameter binding is checked by
[t/1248-isf-rule-trigger-parameter-binding.t](../t/1248-isf-rule-trigger-parameter-binding.t).
Actor constants and actor-local scalar parameter defaults as activation
parameter override values are checked by
[t/1249-isf-activation-parameter-constants.t](../t/1249-isf-activation-parameter-constants.t).
Generated composition-top wiring for generated child activations is checked by
[t/1216-isf-generated-composition-top.t](../t/1216-isf-generated-composition-top.t).
The shipped surface preserves validated per-instance spawn and generated `do`
overrides plus parameterized rule-trigger overrides in lowerer metadata, emits
child transaction defaults into generated child scheduled `.fsm` `+params`
blocks, resolves actor-local constants, actor-local scalar parameter defaults,
and scalar enum members in activation parameter override values and matching
leaves inside activation aggregate/list override values, rejects duplicate
instances, duplicate parameters, unknown overrides, unsupported runtime or
expression values, non-scalar actor parameters, aggregate shape mismatches,
and rejects
parameter declarations on non-generated transactions.
The public ISF surface now accepts the scalar type-alias subset plus one
aggregate storage-carrier subset: actor-local `(types ...)` declarations,
`(imports (package NAME) ...)` for existing `.fsm` package roots, `(type
NAME)` scalar aliases on width-bearing actor interface ports,
transaction-local ports, and actor-owned storage entries, and packed `list` or
`record` aliases only on actor-owned storage variables. Transaction `(set
target aggregate_leaf)` clauses may read scalar member/item leaves from those
declared storage variables, transaction `set` RHS expressions may use scalar
member/item leaves as operands, transaction `when`/`while`/`until` condition
expressions may use scalar member/item leaves as operands, and transaction
`(set aggregate_leaf value)` clauses may write scalar member/item leaves on
those same declared storage variables. Rule assignment RHS values and RHS
expressions may read scalar member/item leaves from those same declared storage
variables. Rule guard expressions may also read scalar member/item leaves as
operands. Transaction `when`/`while`/`until` conditions may read scalar
member/item leaves directly or as operands inside condition expressions;
direct aggregate conditions use computed `.fsm` selector syntax in review
artifacts. Transaction `switch` selectors and branch values may read scalar
member/item leaves from those same declared storage variables; aggregate
selectors use computed `.fsm` selector syntax in review artifacts. Named drive
body scalar RHS values and scalar operands inside RHS
expressions may also read scalar member/item leaves from those same declared
storage variables. Named drive body targets may also write scalar member/item
leaves on those same declared storage variables. Inline drive assignment
scalar RHS values and scalar operands inside RHS expressions may also read
scalar member/item leaves from those same declared storage variables. Inline
drive targets may also write scalar member/item leaves on those same declared
storage variables. Named drive-call scalar actual values may also read scalar
member/item leaves from those same declared storage
variables, and drive-call actual expressions may use them as scalar operands.
Rule guards may also read scalar member/item leaves directly or as scalar
operands inside guard expressions. Lowering
preserves `+types`, `+import`, typed `+size` entries, and embedded imported
package roots in scheduled `.fsm` review artifacts. Unknown aliases, package
aliases, `(width ...)` plus `(type ...)` conflicts, aggregate aliases outside
actor-owned storage variables, unknown aggregate members, out-of-range list
indexes, aggregate paths outside direct transaction `set` RHS values, direct
transaction `set` target tokens, transaction condition scalar values or
expression operands, transaction `switch` selectors or branch values, rule
assignment RHS values/expression operands, rule assignment target tokens, or
rule guard scalar values/expression operands, drive target tokens, drive body RHS scalar
values/expression operands, inline drive target tokens, inline drive
assignment RHS scalar values/expression operands, or drive-call actual scalar
values/expression operands, aggregate paths in expression
operator position, and subaggregate operands/updates fail closed.
Actor-local `(enums ...)`
declarations are preserved as scheduled `.fsm` `+enums`. Enum member
references are public as actor constant values, scalar actor parameter
defaults or scalar leaves inside actor aggregate/list parameter defaults,
generated child transaction scalar parameter defaults or scalar leaves inside
generated child transaction aggregate/list parameter defaults, direct
transaction `set` RHS scalar values or scalar operands inside transaction
`set` RHS expressions, scalar operands inside transaction `when`/`while`/`until`
condition expressions, standalone transaction `when`/`while`/`until` scalar
conditions, transaction `switch` selector or branch values, scalar drive body
RHS values, named drive-call scalar actual values or scalar operands inside
drive-call actual expressions, scalar activation parameter overrides, and
scalar leaves inside activation aggregate/list parameter overrides, scalar rule
assignment RHS values or scalar operands inside rule assignment RHS expressions,
standalone scalar rule guard values or scalar operands inside rule guard
expressions, inline drive assignment RHS scalar values, and scalar operands
inside inline drive RHS expressions in this slice, using local `mode.BUSY` or package-qualified
`shared.mode.BUSY` spelling and resolving to non-negative integer literal
values before lowering.
Declared actor constants are public as scalar actor parameter defaults or
scalar leaves inside actor aggregate/list parameter defaults. Those defaults
preserve authored constant tokens in scheduled `.fsm` `+params` and
`actor_params[]` while carrying resolved literals internally for scalar
parameter consumers.
Earlier actor-local scalar parameter defaults are public as scalar actor
parameter defaults or scalar leaves inside actor aggregate/list parameter
defaults. Source order is the only dependency model: the referenced actor
parameter must appear earlier and already resolve to a scalar numeric or
exact-width literal. Forward references, self references, cycles, non-scalar
actor parameters, transaction parameters, runtime interface signals, and
arbitrary expressions remain fail-closed.
Enum member references in expression operator position, targets, rules outside
scalar trigger parameter overrides, transaction
condition, rule guard, or rule assignment expression operator position, drive
targets, inline drive assignment RHS expression
operator position, drive-call expression operator position, and other ISF
value contexts, additional aggregate carriers, and aggregate field/slice/update
semantics remain outside the parser/scheduler contract.
The scalar type-alias subset is checked by
[t/1257-isf-scalar-type-aliases.t](../t/1257-isf-scalar-type-aliases.t),
covering actor-local aliases, package aliases, typed `+size` review artifacts,
embedded package roots, CLI HDL generation, declaration-only enum preservation,
and fail-closed diagnostics.
Actor-constant enum member references are checked by
[t/1258-isf-enum-member-constants.t](../t/1258-isf-enum-member-constants.t),
covering local and package enum members, authored `+constants` review
artifacts, schedule-report value preservation, CLI HDL generation, and
fail-closed diagnostics.
Direct transaction `set` RHS enum member values are checked by
[t/1263-isf-enum-member-set-values.t](../t/1263-isf-enum-member-set-values.t),
covering local and package enum members, scheduled `.fsm` review artifacts,
CLI HDL generation, and fail-closed diagnostics for unknown members and
deferred operator and target contexts.
Transaction `set` RHS enum member expression operands are checked by
[t/1264-isf-enum-member-set-expression-values.t](../t/1264-isf-enum-member-set-expression-values.t),
covering local and package enum member operands, scheduled `.fsm` review
artifacts, CLI HDL generation, and fail-closed diagnostics for unknown members
and expression operator position.
Transaction `switch` branch enum values are checked by
[t/1265-isf-enum-member-switch-branch-values.t](../t/1265-isf-enum-member-switch-branch-values.t),
covering local and package enum member branch values, scheduled `.fsm` review
artifacts, CLI HDL generation, and fail-closed diagnostics for unknown members
and non-switch contexts.
Transaction `switch` selector enum values are checked by
[t/1295-isf-enum-member-switch-selector-values.t](../t/1295-isf-enum-member-switch-selector-values.t),
covering local and package enum member selectors, computed `.fsm` selector
review artifacts, CLI HDL generation, and fail-closed diagnostics for unknown
members and non-switch contexts.
Scalar drive body RHS enum member values are checked by
[t/1266-isf-enum-member-drive-values.t](../t/1266-isf-enum-member-drive-values.t),
covering local and package enum member drive RHS values, scheduled `.fsm`
review artifacts, CLI HDL generation, and fail-closed diagnostics for unknown
members and deferred drive target and rule contexts.
Drive body RHS expression enum member operands are checked by
[t/1282-isf-enum-member-drive-expression-values.t](../t/1282-isf-enum-member-drive-expression-values.t),
covering local and package enum member operands inside named drive body RHS
expressions, scheduled `.fsm` drive-DT review artifacts, CLI HDL generation,
recursive drive-parameter substitution in body expressions, and fail-closed
diagnostics for unknown members and expression operator position.
Named drive-call scalar actual enum member values are checked by
[t/1267-isf-enum-member-drive-call-values.t](../t/1267-isf-enum-member-drive-call-values.t),
covering local and package enum member drive-call actuals, scheduled `.fsm`
review artifacts, CLI HDL generation, and fail-closed diagnostics for unknown
members.
Drive-call actual expression enum member operands are checked by
[t/1268-isf-enum-member-drive-call-expression-values.t](../t/1268-isf-enum-member-drive-call-expression-values.t),
covering local and package enum member drive-call expression operands,
scheduled `.fsm` review artifacts, CLI HDL generation, and fail-closed
diagnostics for unknown members and expression operator position.
Inline drive assignment RHS enum member values are checked by
[t/1279-isf-enum-member-inline-drive-values.t](../t/1279-isf-enum-member-inline-drive-values.t),
covering local and package enum member inline-drive RHS values, scheduled
`.fsm` review artifacts, CLI HDL generation, and fail-closed diagnostics for
unknown members and inline drive targets.
Inline drive RHS expression enum member operands are checked by
[t/1280-isf-enum-member-inline-drive-expression-values.t](../t/1280-isf-enum-member-inline-drive-expression-values.t),
covering local and package enum member inline-drive RHS expression operands,
scheduled `.fsm` review artifacts, CLI HDL generation, and fail-closed
diagnostics for unknown members and expression operator position.
Actor scalar parameter default enum member values are checked by
[t/1269-isf-enum-member-actor-params.t](../t/1269-isf-enum-member-actor-params.t),
covering local and package enum member actor parameter defaults, scheduled
`.fsm` `+params` review artifacts, schedule-report value preservation, CLI HDL
generation, and fail-closed diagnostics for unknown members and other
non-shipped contexts.
Actor aggregate/list parameter default enum member leaves are checked by
[t/1277-isf-enum-member-actor-aggregate-params.t](../t/1277-isf-enum-member-actor-aggregate-params.t),
covering local and package enum member leaves in actor aggregate/list parameter
defaults, scheduled `.fsm` `+params` review artifacts, `actor_params[]`
schedule-report preservation, strict CLI HDL generation, and fail-closed
diagnostics for unknown leaves.
Actor-constant-backed actor parameter defaults are checked by
[t/1345-isf-actor-param-actor-constants.t](../t/1345-isf-actor-param-actor-constants.t),
covering scalar defaults, aggregate/list leaves, resolved width consumption,
scheduled `.fsm` `+params` review artifacts, `actor_params[]` preservation,
strict CLI HDL generation, and fail-closed diagnostics for unknown symbols,
forward actor-parameter dependencies, transaction parameters, and runtime
signals.
Actor-parameter-backed actor parameter defaults are checked by
[t/1346-isf-actor-param-actor-params.t](../t/1346-isf-actor-param-actor-params.t),
covering earlier scalar actor parameter defaults, aggregate/list leaves,
resolved width consumption, scheduled `.fsm` `+params` review artifacts,
`actor_params[]` preservation, strict CLI HDL generation, and fail-closed
diagnostics for forward, self, non-scalar, unknown, transaction-parameter, and
runtime-signal sources.
Generated child transaction scalar parameter default enum member values are
checked by
[t/1270-isf-enum-member-transaction-params.t](../t/1270-isf-enum-member-transaction-params.t),
covering local and package enum member transaction parameter defaults,
generated child `.fsm` `+params` review artifacts, generated-composition
schedule-report value preservation, CLI HDL generation, and fail-closed
diagnostics for unknown members, aggregate/list parameter leaves, and
reusable-library use-site override contexts.
Generated child transaction aggregate/list parameter default enum member leaves
are checked by
[t/1278-isf-enum-member-transaction-aggregate-params.t](../t/1278-isf-enum-member-transaction-aggregate-params.t),
covering local and package enum member leaves in generated child transaction
aggregate/list parameter defaults, generated child `.fsm` `+params` review
artifacts, generated-composition child parameter summaries and default
instance bindings, strict CLI HDL generation, and fail-closed diagnostics for
unknown leaves.
Actor-static generated child transaction parameter defaults are checked by
[t/1347-isf-transaction-param-actor-static-defaults.t](../t/1347-isf-transaction-param-actor-static-defaults.t),
covering actor constants and actor-local scalar parameter defaults in scalar
transaction defaults and aggregate/list leaves, literalized generated child
`.fsm` `+params`, generated-composition child summaries and default instance
bindings, enum-token preservation, strict CLI HDL generation, and fail-closed
diagnostics for transaction-parameter dependencies, non-scalar actor
parameters, runtime interface signals, and unknown symbols.
Scalar activation parameter override enum member values are checked by
[t/1271-isf-enum-member-activation-params.t](../t/1271-isf-enum-member-activation-params.t),
covering local and package enum member overrides on spawn, generated blocking
`do`, and rule-trigger activation sites, generated-top literal parameter
bindings, generated-composition schedule-report bindings, and fail-closed
diagnostics for unknown members and non-activation structural targets.
Aggregate/list activation parameter override enum member leaves are checked by
[t/1276-isf-enum-member-activation-aggregate-params.t](../t/1276-isf-enum-member-activation-aggregate-params.t),
covering local and package enum member leaves on generated activation sites,
literal generated-top bindings, generated-composition schedule-report bindings,
strict CLI HDL generation, and unknown-member diagnostics.
Reusable-library use-site parameter override actor-static and enum values and leaves are
checked by
[t/1281-isf-enum-member-library-use-params.t](../t/1281-isf-enum-member-library-use-params.t),
covering importing-actor constants, importing-actor scalar parameter defaults,
local and package enum members in scalar and aggregate/list use-site
overrides, literal generated-top bindings, `library_uses[]` schedule-report
values, strict CLI HDL generation, unknown-member diagnostics, runtime-signal
rejection, non-scalar actor-parameter rejection, and the unknown-symbolic
use-site boundary.
Scalar rule assignment RHS enum member values are checked by
[t/1272-isf-enum-member-rule-values.t](../t/1272-isf-enum-member-rule-values.t),
covering local and package enum member explicit `(set port value)` and shorthand
`(port value)` rule assignments, scheduled `.fsm` review artifacts, assignment
provenance, strict CLI HDL generation, strict guarded-DT parsing, and
fail-closed diagnostics for unknown members and rule targets.
Rule assignment RHS expression enum member operands are checked by
[t/1273-isf-enum-member-rule-expression-values.t](../t/1273-isf-enum-member-rule-expression-values.t),
covering local and package enum member operands inside explicit and shorthand
rule assignment RHS expressions, scheduled `.fsm` review artifacts, assignment
provenance, strict CLI HDL generation, and fail-closed diagnostics for unknown
members and expression operator position.
Rule guard expression enum member operands are checked by
[t/1274-isf-enum-member-rule-guard-values.t](../t/1274-isf-enum-member-rule-guard-values.t),
covering local and package enum member operands inside shorthand and long-form
rule guard expressions, scheduled `.fsm` review artifacts, strict CLI HDL
generation, public `when` normalization, and fail-closed diagnostics for
unknown members and expression operator position.
Transaction condition expression enum member operands are checked by
[t/1275-isf-enum-member-condition-values.t](../t/1275-isf-enum-member-condition-values.t),
covering local and package enum member operands inside transaction
`when`/`while`/`until` condition expressions, scheduled `.fsm` computed-test
review artifacts, strict CLI HDL generation, and fail-closed diagnostics for
unknown members and expression operator position.
Standalone transaction condition enum member values are checked by
[t/1300-isf-enum-member-standalone-condition-values.t](../t/1300-isf-enum-member-standalone-condition-values.t),
covering local and package enum member values used directly as
`when`/`while`/`until` conditions, computed `.fsm` selector review artifacts,
strict CLI HDL generation, and unknown-member diagnostics.
Standalone rule guard enum member values are checked by
[t/1301-isf-enum-member-rule-standalone-guard-values.t](../t/1301-isf-enum-member-rule-standalone-guard-values.t),
covering local and package enum member values used directly as shorthand and
long-form rule guards, non-state DT header guard review artifacts, strict CLI
HDL generation, public `when` normalization, and unknown-member diagnostics.
Actor-owned aggregate storage variable carriers are checked by
[t/1259-isf-aggregate-storage-type-aliases.t](../t/1259-isf-aggregate-storage-type-aliases.t),
covering local and package aggregate aliases, typed `+size` review artifacts,
bounded `inferred_storage[].type` / `type_kind` report metadata, CLI HDL
generation, and fail-closed diagnostics for non-carrier aggregate aliases.
Transaction `set` RHS aggregate leaf reads are checked by
[t/1260-isf-aggregate-storage-leaf-reads.t](../t/1260-isf-aggregate-storage-leaf-reads.t),
covering record member reads, package list item reads, scheduled `.fsm`
review artifacts, CLI HDL generation, and fail-closed diagnostics for unknown
members and aggregate paths inside broader expressions.
Transaction `set` target aggregate leaf writes are checked by
[t/1261-isf-aggregate-storage-leaf-writes.t](../t/1261-isf-aggregate-storage-leaf-writes.t),
covering record member writes, package list item writes, scheduled `.fsm`
review artifacts, CLI HDL generation, and fail-closed diagnostics for unknown
members, subaggregate writes, and aggregate paths outside direct transaction
`set` positions.
Transaction `set` RHS expression aggregate leaf operands are checked by
[t/1262-isf-aggregate-storage-leaf-expression-reads.t](../t/1262-isf-aggregate-storage-leaf-expression-reads.t),
covering record member and package list item expression operands, scheduled
`.fsm` review artifacts, CLI HDL generation, and fail-closed diagnostics for
unknown members, operator-position paths, and subaggregate operands.
Transaction condition expression aggregate leaf operands are checked by
[t/1286-isf-aggregate-condition-values.t](../t/1286-isf-aggregate-condition-values.t),
covering local and package aggregate leaf operands inside transaction
`when`/`while`/`until` condition expressions, scheduled `.fsm` computed-test
review artifacts, CLI HDL generation, and fail-closed diagnostics for unknown
members, operator-position paths, and subaggregate operands.
Standalone transaction condition aggregate leaf values are checked by
[t/1299-isf-aggregate-standalone-condition-values.t](../t/1299-isf-aggregate-standalone-condition-values.t),
covering local and package aggregate leaf reads as standalone
`when`/`while`/`until` conditions, computed `.fsm` selector review artifacts,
CLI HDL generation, and fail-closed diagnostics for unknown members and
subaggregate conditions.
Rule assignment RHS aggregate leaf values are checked by
[t/1283-isf-aggregate-rule-values.t](../t/1283-isf-aggregate-rule-values.t),
covering explicit and shorthand rule assignment RHS aggregate leaf reads,
scheduled `.fsm` review artifacts, assignment provenance, CLI HDL generation,
and fail-closed diagnostics for unknown members and subaggregate RHS values.
Rule assignment target aggregate leaf writes are checked by
[t/1296-isf-aggregate-rule-target-values.t](../t/1296-isf-aggregate-rule-target-values.t),
covering explicit and shorthand rule assignment target aggregate leaf writes,
scheduled `.fsm` review artifacts, assignment provenance, CLI HDL generation,
and fail-closed diagnostics for unknown members and subaggregate targets.
Rule assignment RHS expression aggregate leaf operands are checked by
[t/1284-isf-aggregate-rule-expression-values.t](../t/1284-isf-aggregate-rule-expression-values.t),
covering explicit and shorthand rule assignment RHS expression aggregate leaf
operands, scheduled `.fsm` review artifacts, assignment provenance, CLI HDL
generation, and fail-closed diagnostics for unknown members, operator-position
paths, and subaggregate operands.
Rule guard expression aggregate leaf operands are checked by
[t/1285-isf-aggregate-rule-guard-values.t](../t/1285-isf-aggregate-rule-guard-values.t),
covering shorthand and long-form rule guard expression aggregate leaf operands,
scheduled `.fsm` review artifacts, public `when` normalization, CLI HDL
generation, and fail-closed diagnostics for unknown members, operator-position
paths, and subaggregate operands.
Standalone rule guard aggregate leaf values are checked by
[t/1302-isf-aggregate-rule-standalone-guard-values.t](../t/1302-isf-aggregate-rule-standalone-guard-values.t),
covering local and package aggregate leaf reads as shorthand and long-form
rule guards, non-state DT header guard review artifacts, public `when`
normalization, CLI HDL generation, and fail-closed diagnostics for unknown
paths, out-of-range indexes, and subaggregate guards.
Drive body RHS aggregate leaf values are checked by
[t/1287-isf-aggregate-drive-values.t](../t/1287-isf-aggregate-drive-values.t),
covering local and package aggregate leaf reads in named drive body scalar RHS
values, scheduled `.fsm` drive-DT review artifacts, CLI HDL generation, and
fail-closed diagnostics for unknown members and subaggregate RHS values.
Drive target aggregate leaf writes are checked by
[t/1297-isf-aggregate-drive-target-values.t](../t/1297-isf-aggregate-drive-target-values.t),
covering local and package aggregate leaf writes as named drive body targets,
scheduled `.fsm` drive-DT review artifacts, assignment provenance, CLI HDL
generation, and fail-closed diagnostics for unknown members and subaggregate
targets.
Drive body RHS expression aggregate leaf operands are checked by
[t/1288-isf-aggregate-drive-expression-values.t](../t/1288-isf-aggregate-drive-expression-values.t),
covering local and package aggregate leaf operands inside named drive body RHS
expressions, scheduled `.fsm` drive-DT review artifacts, CLI HDL generation,
and fail-closed diagnostics for unknown members, operator-position paths, and
subaggregate operands.
Drive-call actual aggregate leaf values are checked by
[t/1289-isf-aggregate-drive-call-values.t](../t/1289-isf-aggregate-drive-call-values.t),
covering local and package aggregate leaf reads as named drive-call scalar
actual values, scheduled `.fsm` drive-parameter review artifacts, CLI HDL
generation, and fail-closed diagnostics for unknown members, inline drive
assignments, and subaggregate actuals.
Drive-call actual expression aggregate leaf operands are checked by
[t/1290-isf-aggregate-drive-call-expression-values.t](../t/1290-isf-aggregate-drive-call-expression-values.t),
covering local and package aggregate leaf operands inside named drive-call
actual expressions, scheduled `.fsm` drive-parameter review artifacts, CLI HDL
generation, and fail-closed diagnostics for unknown members, operator-position
paths, and subaggregate operands.
Inline drive assignment RHS aggregate leaf values are checked by
[t/1291-isf-aggregate-inline-drive-values.t](../t/1291-isf-aggregate-inline-drive-values.t),
covering local and package aggregate leaf reads as inline drive assignment
scalar RHS values, scheduled `.fsm` state-assignment review artifacts, CLI HDL
generation, and fail-closed diagnostics for unknown members and subaggregate
RHS values.
Inline drive RHS expression aggregate leaf operands are checked by
[t/1292-isf-aggregate-inline-drive-expression-values.t](../t/1292-isf-aggregate-inline-drive-expression-values.t),
covering local and package aggregate leaf operands inside inline drive RHS
expressions, scheduled `.fsm` state-assignment review artifacts, CLI HDL
generation, and fail-closed diagnostics for unknown members, operator-position
paths, and subaggregate operands.
Inline drive target aggregate leaf writes are checked by
[t/1298-isf-aggregate-inline-drive-target-values.t](../t/1298-isf-aggregate-inline-drive-target-values.t),
covering local and package aggregate leaf writes as inline drive targets,
scheduled `.fsm` state-assignment review artifacts, assignment provenance, CLI
HDL generation, and fail-closed diagnostics for unknown members and
subaggregate targets.
Transaction switch branch aggregate leaf values are checked by
[t/1293-isf-aggregate-switch-branch-values.t](../t/1293-isf-aggregate-switch-branch-values.t),
covering local and package aggregate leaf reads as transaction `switch` branch
values, scheduled `.fsm` switch review artifacts, CLI HDL generation, and
fail-closed diagnostics for unknown members and
subaggregate branch values.
Transaction switch selector aggregate leaf values are checked by
[t/1294-isf-aggregate-switch-selector-values.t](../t/1294-isf-aggregate-switch-selector-values.t),
covering local and package aggregate leaf reads as transaction `switch`
selectors, computed `.fsm` selector review artifacts, CLI HDL generation, and
fail-closed diagnostics for unknown members and subaggregate selectors.
Generated composition-top links use the canonical Lisp-ish `?wiring` list
spelling, for example `(parent.instance_start instance.start)`, rather than
the older slash-token compatibility spelling.
The switch-clause boundary is checked by
[t/1205-isf-switch-clause-boundary.t](../t/1205-isf-switch-clause-boundary.t)
so `(switch signal (value body...)...)` requires one scalar signal, one or more
list-form branches, and scalar branch values before branch expansion.
The when-clause boundary is checked by
[t/1206-isf-when-clause-boundary.t](../t/1206-isf-when-clause-boundary.t)
so `(when condition body...)` requires one scalar or list-form condition and at
least one list-form body clause before branch expansion.
ISF switch fallback scheduling is checked by
[t/1103-isf-switch-branch-exits.t](../t/1103-isf-switch-branch-exits.t)
and the generated `.fsm` default selector contract is checked by
[t/42-language-contract-test-selector-boundary.t](../t/42-language-contract-test-selector-boundary.t)
and [t/37-language-contract-computed-test-selector.t](../t/37-language-contract-computed-test-selector.t).
The facade shape metadata that advertises those constructor, method, path, and
actor-shell boundaries is checked by
[t/1143-isf-public-facade-shape-metadata-audit.t](../t/1143-isf-public-facade-shape-metadata-audit.t)
to stay exact across direct and manifest views.

## Stabilized Surface

The current bounded public surface is deliberately narrow.
The machine-readable contract's `public_top_level_presence_keys` list is the
exact top-level discovery list for the contract payload. It is not a partial
hint list.
The schema/status/owner identity fields and stability flags are exact discovery
metadata for the contract's current bounded-public stance.
The `guidance` list is exact downstream-consumer advice for interpreting the
current bounded contract: facade pairs are public, raw internals are not, human
contract documents must evolve with public ISF changes, and feature-driven
public changes must move the matching public contract and manifest audit tests
in the same implementation slice.
The `tested_by` list is exact audit-provenance metadata for this ISF contract
owner; every path must stay repo-relative and present on disk.
The `library_catalog_paths`, `library_catalog_entry_keys`, and
`shipped_library_definitions` fields are live discovery metadata for reusable
ISF libraries. They advertise where downstream consumers can find the human
catalog, which fields each catalog entry carries, and which reusable
definitions are shipped in this repository today. They do not expose the raw
library resolver state or freeze future library kinds.

Supported ISF syntax remains a live surface. For `(switch signal ...)`, explicit
case values remain unique branch selectors, and one fallback branch may be
written as `(default body...)` or `(_ body...)`. Those fallback spellings are
aliases and are rejected if both appear in the same switch. When no authored
fallback branch is present, ISF lowering emits an implicit scheduled `.fsm`
`(default (-> next_state))` fallthrough branch. In the downstream `.fsm`
language, that default selector means the logical negation of the OR of every
explicit sibling branch predicate, so the fallback path is true only when no
explicit branch matched.

For the first reusable-library import surface, actor roots may use one
`(imports ...)` clause and one or more `(use ...)` clauses. Library roots use
`(library name ...)` with one `(exports ...)` clause, and the first supported
export kind is `actor`. A use such as
`(use pulse_lib.pulse_actor as rx (params (WIDTH 4)) (bind ...))` resolves a
namespaced exported actor, validates instance-local parameter overrides and
explicit clock/reset/interface bindings, and emits a specialized child
scheduled `.fsm` artifact named `<importing_actor>__<instance>.fsm`.
`parse_file(...)` resolves external library files from the importing source
directory, `FSMLIB`, and the current directory, checking both dotted and
path-like file names such as `common.pulse.isf` and `common/pulse.isf`.
`parse_source(...)` can resolve same-source library roots; general external
resolution requires a real source path, so file-backed library use should call
`parse_file(...)`. Resolved library actor instances emit a generated top when
lowered for HDL: bound library inputs/outputs link directly between top ports
and the library child instance. Same-name clock/reset bindings can be inferred
when the parent and child clock names match and the reset name/kind/polarity
matches; they use the existing composition system-port auto-wiring path and
are still reported in `library_uses[].bindings[]`. Differently named
clock/reset bindings emit explicit generated-top `?wiring` list links such as
`(clk rx.lib_clk)` to the library child system ports; the reusable actor still
owns reset kind and polarity. That reusable-library system-binding surface is
still signal-name binding, not CDC behavior by itself.
The clock-domain lowering slices add parser and scheduler handoff metadata for
the selected `(clock-domains ...)` and `(crossings ...)` source model.
Accepted multi-domain actors are partitioned by declared domain inside
`LoweringIR`, and direct unowned cross-domain reads, writes, triggers,
activations, bindings, and drive reuse fail closed before emission. Public
`lower(...)` now emits domain-specific scheduled `.fsm` artifacts named
`<actor>__domain_<domain>.fsm` plus a generated multi-domain top that wires
domain modules and explicit CDC child interfaces. Public `report(...)` and
`--emit-schedule-json` now describe the generated top at the top level and
expose bounded per-domain and event-crossing metadata through
`clock_domains[]` and `crossings[]`. Plain generated HDL for accepted
SystemVerilog/Verilog-family event-crossing actors now emits the generated top
and a concrete generated acknowledged-event CDC child when each emitted domain
artifact satisfies the current scheduled `.fsm` clock/reset HDL contract.
The current shipped reusable library catalog contains `common.fifo.fifo` with
source [isf/common/fifo.isf](../isf/common/fifo.isf), import fixture
[isf/fifo_library_use.isf](../isf/fifo_library_use.isf), fixed parameters
`DATA_WIDTH=8`, `DEPTH=4`, `PTR_WIDTH=2`, and `OCC_WIDTH=3`, the public FIFO
interface, actor-owned storage, runtime semantics, tests, and limitations.
The same information is mirrored in `shipped_library_definitions` for
machine-readable discovery. The file-backed import fixture is also the
strict reusable-library handoff example: it emits the importing actor,
specialized child, and generated top scheduled `.fsm` artifacts, records
fixed parameter overrides and binding provenance in `library_uses[]`, and
reaches plain plus strict generated-top SystemVerilog.

Supported CLI entrypoints:

```bash
./bin/fsmgen path/to/file.isf
./bin/fsmgen --emit-schedule-json path/to/file.isf
./bin/fsmgen --outdir path/to/outdir path/to/file.isf
```

Supported in-process facade entrypoints:

```perl
my $actor = FSM::Adapter::ISF->new(%args)->parse_file($path);
my $actor = FSM::Adapter::ISF->new(%args)->parse_source($text, $label);

my $lowered = FSM::Scheduler::ISF->new(%args)->lower($actor);
my $json    = FSM::Scheduler::ISF->new(%args)->report($actor);
```

The advertised entrypoint lists are exact discovery metadata, not examples with
additional unlisted public entrypoints implied.
The `parser_method_names` and `scheduler_method_names` lists are exact
discovery metadata for the public facade method families.
The parser facade return-shape fields advertise that `parse_file(...)` and
`parse_source(...)` return scheduler-consumable actor hash references with the
advertised `actor_shell_required_keys`. The scheduler facade return-shape
fields advertise that `lower(...)` returns a hash reference with
`lower_result_presence_keys`, and that `report(...)` returns a JSON string
encoding `schedule_report_top_level_keys`.
These fields are exact return-shape metadata. They do not freeze the raw actor
hash, the full lower-result hash, or every schedule-report field beyond the
bounded metadata advertised by this contract.

Constructors must be called with the exact public class invocants
`FSM::Adapter::ISF` or `FSM::Scheduler::ISF`. The only public constructor
option currently advertised for the ISF parser and scheduler facades is
`debug`. Constructors reject malformed invocants, odd option lists, and
unsupported option names before object creation. The machine-readable contract
advertises the invocant requirement through `constructor_receiver_shape`.
The `constructor_option_names` list is exact discovery metadata for the public
constructor option family.
The constructor receiver and argument-shape strings are exact discovery
metadata for the public constructor boundary.

Parser methods must be called on an object returned by
`FSM::Adapter::ISF->new(...)`. Scheduler methods must be called on an object
returned by `FSM::Scheduler::ISF->new(...)`. The machine-readable contract
advertises those receiver boundaries through `parser_method_receiver_shape` and
`scheduler_method_receiver_shape`.
Those receiver-shape strings are exact discovery metadata.

`parse_file(...)` requires exactly one defined scalar path argument, and that
path must have a `.isf` suffix and name a readable regular file before private
parsing begins. The machine-readable contract advertises this through
`parse_file_path_requirement`.
`parse_source(...)` requires exactly two defined scalar arguments: source text
and source label.
`lower(...)` and `report(...)` require exactly one scheduler-consumable actor
hash reference from the ISF adapter. The current public actor shell requires
scalar `actor_name`, array `transactions`, and hash `interface` fields.
The machine-readable contract advertises those required shell fields through
`actor_shell_required_keys` and the value shapes through
`actor_shell_value_shape`. That promise is intentionally a shell contract: the
full raw actor hash remains non-public.
Actor roots may also carry parser-validated actor-owned storage declarations
through a singleton `(storage ...)` clause. That field is not a required actor
shell key, but the advertised value-shape string records that `storage` is an
optional array reference when present. The shipped storage entries include
scalar declarations authored with preferred `(var ...)` or verbose
`(variable ...)`, where widths may be positive integer literals or
actor-local scalar parameters that resolve to positive integers, plus
fixed-depth `bank` declarations whose widths and depths may use the same
actor-local scalar parameter source and whose scalarized element names are
scheduler input.
Schedule reports still use coarse `kind: register` for generated storage
class; that report value is not the source vocabulary.
Actor roots may also carry parser-validated actor-local constants through a
singleton `(constants ...)` clause. That field is not a required actor shell
key, but the advertised value-shape string records that `constants` is an
optional array reference when present.
Actor roots may also carry the first bounded ATL static actor-network
metadata through direct actor-level `(instance NAME of ACTOR_TYPE)` clauses or
compact `(NAME : ACTOR_TYPE)` aliases. The enclosing actor is the network
boundary; `(network ...)` wrappers are not part of the shipped source surface.
That field is not a required actor shell key. When present, `actor_network` is
a `static_declaration` hash with direct static instance metadata, optional
report-only group metadata, shipped event, trigger, data movement, exact
temporary trigger-batch metadata, resolved library-qualified child artifact
metadata, and the bounded generated ATL top families. Schedule reports project
it through top-level `actor_network`. Verbose instances report
`declaration: "actor"`; compact instance aliases report
`declaration: "instance_alias"`. Resolved instance entries report actor type
provenance and child artifact names. The generated-top subset wires the
selected one-child trigger/event
forms, the selected one-child scalar pin-ingress route, the selected
one-child exact-width vector pin-ingress route, the same-child scalar
pin-ingress multi-route extension, the same-child vector pin-ingress
multi-route extension, the same-child mixed scalar/vector pin-ingress
route-set extension, the selected one-child pin-egress route, the selected
one-child exact-width vector pin-egress route, the same-child pin-egress
multi-route extension, the same-child vector pin-egress multi-route extension,
the same-child mixed scalar/vector pin-egress route-set extension, the selected
two-child trigger/event
sequence, and the selected two-child scalar or exact-width vector
generated-child actor-to-actor route set. No group endpoints,
route mux/storage, broader HDL event wiring, or
broader generated-top data routing is promised by this field.
The selected broader ATL v0 public direction is direct actor-body syntax plus
existing drive-body movement syntax, but most of those forms remain future
behavior until advertised by capability metadata. Endpoint-aware movement
will keep drive body pair order as `(sink source)` and may later admit
qualified `pins.name`, `actor.port`, `actor.transaction`, `actor.event`, and
`group.name` endpoints. `connect`, `transfer`, and `move` are not public ATL
v0 movement clauses. Unsupported qualified actor endpoint drive-body pairs
naming a declared static actor instance reject with ATL data-movement
diagnostics unless they match the shipped actor-to-actor subset.
The generated actor-to-actor handoff subset is now implemented in the public
API for one-bit scalar and exact-width vector child endpoint routes. That
subset admits exactly two direct static actor instances, one named drive body
with one `(sink_actor.endpoint source_actor.endpoint)` pair, and one top-level
transaction drive call. FSMGen rewrites the pair to generated parent handoff
signals named `source_actor_source_endpoint` and
`sink_actor_sink_endpoint`; their width is the resolved matching child endpoint
width. The schedule-report surface is `actor_network.data_movements[]` with
`kind`, `transaction`, `context`, `drive`, `source_instance`,
`source_endpoint`, `source_signal`, `sink_instance`, `sink_endpoint`,
`sink_signal`, `width`, `width_source`, `route_lifetime`, `storage`,
`source`, and `sink`. Scalar one-bit routes use
`kind: "scalar_actor_handoff"` and `width_source: "scalar_one_bit"`;
same-width vector routes use `kind: "vector_actor_handoff"` and
`width_source: "resolved_child_endpoint_exact_width"`. Storage, muxing,
broader pin movement, inline/expression movement, width adaptation,
fan-in/fan-out, broader group scheduling outside the exact trigger-batch
subset, CDC, and trigger/await coupling beyond the selected generated-child
top sequence remain future public contracts.
The first top-level pin movement public subset is implemented: one
`(actor.endpoint pins.input_pin)` scalar pair in one named drive body, one
direct static actor instance, and one top-level transaction drive call. The
report kind is `scalar_pin_to_actor_handoff`, with
`source => top_level_pin` and `sink => external_handoff`.
The generated-child top-level input-pin movement subset also accepts one
exact-width vector `(actor.endpoint pins.input_pin)` route for a resolved child
when the top-level input pin and child input endpoint widths match exactly.
The public route entry reports `kind: "vector_pin_to_actor_handoff"`,
`width` equal to that endpoint width, and
`width_source: "top_level_input_pin_resolved_child_endpoint_exact_width"`;
the same-child vector pin-ingress multi-route subset accepts multiple such
routes when every route has unique pins/endpoints and exact matching
route-local widths. The same-child mixed scalar/vector pin-ingress route-set
subset accepts scalar one-bit and exact-width vector routes together when all
routes target the same resolved child, share one parent transaction, use unique
top-level input pins and child input endpoints, and keep adjacent pre-trigger
drive calls. Each route keeps its own public `kind`, `width`, and
`width_source`. Width adaptation and mixed pin-egress route sets remain outside
the public contract.
The inverse actor-to-top-level output pin public subset is implemented: one
`(pins.output_pin actor.endpoint)` scalar pair in one named drive body, one
direct static actor instance, and one top-level transaction drive call. The
report kind is `scalar_actor_to_pin_handoff`, with
`source => external_handoff` and `sink => top_level_pin`.
The generated-child top-level output-pin movement subset also accepts one
exact-width vector `(pins.output_pin actor.endpoint)` route for a resolved
child when the child output endpoint and top-level output pin widths match
exactly. The public route entry reports
`kind: "vector_actor_to_pin_handoff"`, `width` equal to that endpoint width,
and
`width_source: "top_level_output_pin_resolved_child_endpoint_exact_width"`;
the same-child vector pin-egress multi-route subset accepts multiple such
routes when every route has unique child outputs/top-level pins and exact
matching route-local widths. The same-child mixed scalar/vector pin-egress
route-set subset accepts scalar one-bit and exact-width vector routes together
when all routes source the same resolved child, share one parent transaction,
use unique child output endpoints and top-level output pins, and keep adjacent
post-event drive calls. Each route keeps its own public `kind`, `width`, and
`width_source`. Width adaptation and broader mixed route fabrics remain outside
the public contract.
Future blocking and nonblocking orchestration spellings are reserved as
`(do actor.transaction)` and `(spawn actor.transaction as NAME)`, with event
payloads deferred. Transaction-body `(trigger actor.transaction)` has a
bounded parent-handoff subset; rule-level qualified triggers remain future.
Concurrent groups may still be declared with
`(group NAME (members ACTOR...) (mode concurrent))`, but groups are static
review metadata only. They are not required for task-scoped ATL trigger
associations and do not create permanent runtime associations or override
safety checks.
The concurrent-group implementation axis has shipped targeted diagnostics and
report-only metadata:
direct actor-body `(group NAME (members ACTOR...) (mode concurrent))`
declarations now report static `actor_network.groups[]` metadata when every
member names an already declared direct static actor instance. Compact
`(concurrent NAME ACTOR...)` aliases now normalize to the same report-only
metadata surface and report `declaration: "concurrent_alias"` instead of the
verbose form's `declaration: "group"`. Group entries also keep
`source: "actor_body"` and `scheduling: "metadata_only"` in this subset. No
public group endpoint behavior is implemented yet.
The first public multi-actor trigger scheduling contract is a same-cycle
external trigger batch over existing top-level transaction-body
`(trigger actor.transaction)` clauses. The batch is a task-scoped temporary
association: one contiguous trigger run may target distinct static actor
instances, lowers to one trigger-batch state, and advertises scheduling
evidence through canonical `actor_network.association_schedules[]` entries.
The existing `actor_network.group_schedules[]` array remains a
schema-version-1 compatibility view for current downstream consumers. If the
trigger set matches one declared static group, the compatibility `group` field
names that group; otherwise it carries a synthetic transaction-scoped name
such as `run_trigger_batch`. Public reports therefore separate static
membership (`groups[]`) from scheduled temporary associations
(`association_schedules[]`).
The current shipped actor-event wait subset accepts top-level transaction-body
`(await actor.event)` in the bounded selected ATL contexts. The external
parent-handoff subset supports one declared static actor instance and lowers
to a generated one-bit parent event handoff input named `actor_event`; for
example, `reader.done` lowers through `reader_done`. The generated-top subset
also uses these event wait records for the selected one-child and two-child
resolved-library forms. A temporary trigger batch may also be followed by a
contiguous source-ordered chain of multiple top-level waits when each wait
targets a distinct triggered actor instance and no ATL data movement is in
that transaction segment; the waits remain sequential scheduled states, not a
hidden same-cycle join. Schedule reports expose waits through
`actor_network.event_waits[]` entries with `transaction`, `context`,
`instance`, `event`, `signal`, and `source` keys, where `source` is currently
`external_handoff`. Nested event waits, repeated actor waits, hidden fan-in or
fan-out event joins, event payloads, cross-clock actor events, concurrent
group events, and waits outside the selected generated-top/source-order
shapes remain fail-closed/deferred.
Existing unqualified local `(await signal)` and rule-level
`(trigger transaction)` behavior remains unchanged, and dotted enum-looking
names outside actor-network instances keep their prior diagnostics.
Regression coverage includes the accepted temporary trigger-batch multi-event
wait fixture and negative repeated-wait boundaries; repeated waits fail before
scheduled `.fsm` emission with the multi-event wait diagnostic.
The current qualified actor-trigger subset is one top-level transaction-body
`(trigger actor.transaction)` for a static actor instance, plus the exact
same-cycle temporary trigger batch described above. Each trigger lowers to a
generated one-cycle parent output handoff
named `actor_transaction_start`. For example, `reader.capture` lowers through
`reader_capture_start`, and the scheduled parent `.fsm` pulses that output at
the trigger point. The trigger sink is external until actor type resolution,
ATL child generation, generated ATL tops, trigger payloads, and
ready/backpressure semantics ship. Rule-level qualified triggers, nested
triggers, repeated triggers to the same instance, generated handoff signal
conflicts, fan-in/fan-out, cross-clock actor triggers, and broader concurrent
group behavior remain deferred. Schedule reports expose this through
`actor_network.transaction_triggers[]` entries with `owner_transaction`,
`context`, `instance`, `target_transaction`, `signal`, and `sink` keys, where
`sink` is currently `external_handoff`.
Actor roots may also carry parser-validated clock-domain declarations through
a singleton `(clock-domains ...)` clause. That field is not a required actor
shell key, but the advertised value-shape string records that `clock_domains`
is null for legacy one-clock actors or optional live metadata for accepted
domain declarations. When `clock_domains` is present, the compatibility
`clock` and `reset` fields expose the selected default domain only.
The bank access forms `(store <bank-name> <index> <value>)` and
`(load <bank-name> <index> as <target>)` are now public parser support for
declared actor-owned banks in rules and supported transaction contexts. The
second item is the authored bank name; actors may declare multiple banks. They
lower to scalarized guarded `.fsm` assignments and successful reports expose
bounded `bank_accesses` metadata with the access kind, owner, container, bank
name, index token, width/depth, scalarized entries, value or target, and
the read-before-write same-cycle policy. The file-backed
`isf/fifo_data_path.isf` fixture is the public bank datapath example and is
covered by `t/1319-isf-fifo-datapath-fixture-coverage.t` for strict schedule
JSON parity plus plain and strict HDL generation.
The sibling `isf/fifo_controller.isf` fixture is the public controller-only
example for occupancy, full/empty, and pointer updates; it is covered by
`t/1320-isf-fifo-controller-fixture-coverage.t`.
The `isf/fifo_library_use.isf` fixture is the public fixed reusable-library
example for the combined controller/datapath FIFO actor; it is covered by
`t/1321-isf-fifo-library-fixture-coverage.t` for strict schedule JSON parity,
multi-file scheduled `.fsm` emission, fixed parameter/binding provenance, and
plain plus strict generated-top HDL generation.
`store` is bank-entry-only public syntax. Scalar storage updates remain the
ordinary rule assignment and transaction `update` surfaces.
The current public parser handoff also advertises one bounded subshape inside
that shell: `interface` contains `inputs` and `outputs` arrays, and each public
port entry has unique non-empty scalar `name` plus positive integer `width`,
with omitted source widths normalized to `1`. Source `(width PARAM)` and
`(width CONST)` are accepted only when they name an actor-local scalar
parameter default or declared actor constant that resolves to a positive
integer; the public port entry still carries the resolved integer width, not
the authored token. Accepted clock-domain sources may carry scalar `domain`
ownership metadata on those port entries. The machine-readable contract
advertises this through
`actor_shell_interface_shape`.
This is current live-contract metadata for scheduler-consumable parser output;
it does not make actor fields outside the advertised shell public or freeze
future ISF interface extensions before they are documented and audited.
The current public parser handoff also advertises a bounded transaction-entry
shell: `transactions` is an array of entries with unique non-empty scalar
`name`, `ports.inputs[]` / `ports.outputs[]` entries that carry resolved
positive integer `width` values, `clauses` array fields, and optional scalar
`domain` ownership metadata. Transaction-local `(width PARAM)` and
`(width CONST)` entries are accepted only when the symbol names an actor-local
scalar parameter default or declared actor constant that resolves to a positive
integer; the public port entry carries the resolved integer width, not the
authored token. The machine-readable contract advertises this through
`actor_shell_transaction_shape`. The `clauses` array is a scheduler-consumable
container; its payload contents are intentionally not frozen as a public API by
this field.
The current public parser handoff also advertises the actor identity shell:
`actor_name` is a non-empty scalar actor identifier preserved from the ISF actor
root. The machine-readable contract advertises this through
`actor_shell_actor_name_shape`.
The current public parser handoff also advertises bounded actor timing fields:
`clock` is a non-empty scalar, with omitted legacy single-clock actor clocks
defaulting to `clk`; `reset` is a default-domain hash with scalar `name`,
`kind`, and `polarity`, with omitted legacy single-clock actor resets
defaulting to async active-low `rst_n`; and `watchdog` is a positive resolved
integer, with omitted watchdog clauses defaulting to `65535` exactly
`(2^16 - 1)`. Actor-level watchdog constants and actor-local scalar parameter
defaults are accepted when they resolve to positive integers; the parser
returns the resolved integer in `watchdog` and keeps the authored declaration
visible through `actor_constants[]` or `actor_params[]`. Await-local watchdog
constants and actor scalar parameters resolve during lowering. One transaction
still has one watchdog counter, so distinct per-await watchdog limits in the
same transaction fail closed.
When `clock_domains` is present, `clock` and `reset` expose the selected
default-domain timing, and `reset` is null only when that domain omits reset.
Public multi-domain `lower(...)` emits domain-specific scheduled `.fsm`
artifacts plus a generated multi-domain top, and public `report(...)` exposes
bounded domain and crossing report metadata. The machine-readable contract
advertises this through `actor_shell_timing_shape`.
Those timing fields, along with `interface`, parser-carried `resources`,
parser-carried `storage`, and parser-carried `crossings`, are source-level
singleton actor clauses. The `clock-domains` clause is also singleton and is
mutually exclusive with
actor-level `clock` and `reset`. Repeating one is a parser boundary error; the
parser does not merge duplicate interface/resources/storage/clock-domain
blocks or let later clock/reset/watchdog clauses overwrite earlier ones.
The current public parser handoff also advertises a bounded rule-entry shell:
`rules` is an array of entries with unique non-empty scalar `name`, optional
`when`, `actions` array fields, and optional scalar `domain` ownership
metadata. The machine-readable contract advertises this through
`actor_shell_rule_shape`. Rule condition/action payload contents remain private
scheduler input.
Authored `(rule name condition actions...)` shorthand and long-form
`(rule name (when condition) actions...)` normalize to the same public `when`
field. The guard may be a scalar condition or a list expression using the
normal `.fsm` expression spelling. Rule-local `(when condition)` is a
guard-only clause; it is not the transaction `(when condition body...)`
control-flow construct.
Current scheduled `.fsm` review artifacts emit a rule's `when` guard as the
non-state DT header DTE for that rule's lowered actions. This keeps the
generated text aligned with the source rule structure without widening the
actor-shell rule payload contract.
Within that scheduled `.fsm` review artifact, ordinary rule `(port expr)`
actions remain flopped assignments inside the guarded DT, while
`(trigger transaction)` actions use `<1` on a generated `rule_transaction`
trigger source inside that same guarded DT. A rule trigger is therefore a
one-cycle delayed pulse, not a sticky flopped request bit.
Multiple rules may trigger the same transaction. The current scheduled `.fsm`
artifact exposes those triggers as distinct one-bit `rule_transaction` sources
and emits a generated combinational `transaction_trigger_fanin` DT for each
triggered transaction. The fan-in drives `transaction_start` from the OR of the
rule sources without adding latency, so downstream consumers can inspect
per-rule trigger provenance before the transaction start OR.
Parser handoff now requires each rule trigger target to resolve to a declared
transaction in the same actor. This prevents a misspelled rule trigger from
inventing an otherwise unowned `transaction_start` fan-in path.
Lowering also performs best-effort static conflict checks for rule data writes:
provable incompatible rule/rule writes to the same target fail closed, while
same-target rule writes with direct contradictory guard facts are accepted as
disjoint. This proof is conservative and currently recognizes simple signal
and negated-signal terms plus equality facts, including conjunctions used by
FIFO fire predicates and pointer/occupancy matrix cases. Rule/drive
same-target overlap is marked internally because
compile-time proof is not doable in that case. Nonfatal rule/drive overlap is
now projected into successful schedule-report `compile_issues`; reports with
no nonfatal issues still keep that array empty.
For same-target rule/rule data conflicts, rule-local and actor-level priority
edges can now select a target-local winner by guarding the lower-priority
assignment with the inverse higher-priority rule condition. This changes the
scheduled `.fsm` review artifact and does not itself add a compile issue.
Actor-level rule-over-transaction priority is also enforced for the covered
same-target data case when both assignments use the same timing operator: the
transaction-state assignment is guarded with the inverse active rule
condition. Spawned transaction output bindings are also treated as
transaction-owned data for this conflict pass, so a spawned child output bound
to an actor output cannot silently coexist with a conflicting rule writer.
Actor-level transaction-over-rule priority is enforced for the covered
same-target data case too: the transaction-state assignment stays unchanged,
and the lower-priority rule assignment is guarded with the inverse scheduled
`.fsm` `(state_active STATE)` predicate for the winning transaction state.
That predicate lowers to an internal `current_state == STATE` comparison
without creating fake module inputs for `current_state`, state constants, or
generated state-enable names. Unordered rule/transaction conflicts, priority
cycles, and mixed timing operators still fail closed.
After scheduled `.fsm` reaches the HDL backend, generated SystemVerilog now
adds verification-only selector assertions derived from backend assignment
analysis. Same-value source selectors for one `LHS`/`VAL` selector and
different-value selectors for one `LHS` mux are checked with `$onehot0` under
`` `ifndef SYNTHESIS``. Verilog emission remains free of those assertions.
This does not widen the successful public ISF schedule-report schema; the
selector metadata lives in the downstream HDL-generation/lowered-RTL result
surface, whose full hash remains outside the ISF public contract.
The current public parser handoff also advertises a bounded drive-definition
shell: `drives` is a hash of entries keyed by unique non-empty drive name, and
each entry has unique scalar `params` and `body` arrays. Body entries are
parser-validated as scalar `(port value)` pairs. The machine-readable contract
advertises this through `actor_shell_drive_shape`. Richer drive semantics
remain private scheduler input.
Drive parameter names are also parser-validated before actor-shell return:
[t/1189-isf-drive-parameter-boundary.t](../t/1189-isf-drive-parameter-boundary.t)
keeps parameterized drive declarations from reusing one parameter name for
multiple positional arguments.
Known drive calls are exact-arity calls: the number of actual values must match
the drive's declared parameter count. Extra actuals are rejected during
lowering rather than silently discarded, and missing actuals keep the existing
targeted missing-parameter diagnostic.
The parser/scheduler argument-shape fields and actor-shell key list are exact
facade-shape discovery metadata.
Public facade boundary failures produce bounded scalar diagnostics before
object creation, private parsing, or private lowering/reporting begins. The
machine-readable contract advertises this through
`facade_failure_diagnostic_shape`.

The advertised ISF-specific CLI option family is `--emit-schedule-json`,
`--outdir`, and `--strict`.
The `cli_option_names` list is exact discovery metadata for that option family.
The CLI success-shape fields are exact discovery metadata for successful public
CLI runs: `--emit-schedule-json` writes schedule-report JSON to stdout with
empty stderr, `--outdir DIR` writes lower-result `.fsm` files by basename into
`DIR`, and plain single-clock `file.isf` generation lowers through scheduled
`.fsm` and any generated composition top before writing the requested HDL
output with empty stderr. Plain multi-domain `file.isf` HDL generation for
accepted event-crossing actors writes the generated domain/top `.fsm`
artifacts, then emits SystemVerilog/Verilog-family HDL containing the
generated multi-domain top and concrete acknowledged-event CDC child modules
for accepted crossings when each emitted domain artifact satisfies the current
scheduled `.fsm` clock/reset HDL contract.
`--emit-schedule-json` succeeds for accepted multi-domain actors.
The strict CLI success-shape field advertises that accepted `--strict
file.isf` generation follows the public HDL-generation success shape and keeps
stderr empty on success.
For `.isf` inputs, `--check --json` and `--check-json` now preserve the public
check JSON failure surface for parser, lowering, schedule-report, and
downstream semantic check failures. These failures exit nonzero, write
`success: false` JSON to stdout, keep stderr clean for the machine-readable
mode, and preserve the normalized diagnostic text in `diagnostics[0].message`.

## Lower Result

`FSM::Scheduler::ISF->lower($actor)` returns a hash with the advertised top-level
key:

```text
files
```

`files` is a hash reference mapping `.fsm` basenames to scheduled module,
resolved ATL child module, generated ATL top, multi-domain domain scheduled
module, specialized library-child module, generated multi-domain top, or
generated composition-top `.fsm` source text.
The generated `.fsm` text is a reviewable compiler artifact and then flows
through the existing `.fsm` pipeline where that path is implemented.
The plain single-clock `file.isf` CLI path lowers through that pipeline into
generated HDL.
Each public `files` key is a `.fsm` basename with no directory components.
Scheduled module values, including emitted multi-domain domain artifacts, are
`.fsm` source text rooted at `(?fsm:<basename-stem> ...)`; generated top
values are `.fsm` source text rooted at `(?top:<basename-stem> ...)` and may
append embedded `(?rtlif:...)` declarations for explicit CDC child interfaces.

The `--outdir` CLI path materializes the same lower-result `.fsm`
basename/text map on disk for HDL-ready multi-file lowerings. Accepted
multi-domain event-crossing actors now use that materialized generated top as
the HDL entry and emit the concrete generated CDC child beside the domain
modules.

The full lower-result hash is not yet a broad public API beyond the advertised
keys.
The `lower_result_presence_keys`, `lower_result_file_map_shape`,
`lower_result_file_name_shape`, and `lower_result_file_text_shape` fields are
exact lower-result discovery metadata for the currently public `files` map.

## DT Assignment Operators

Scheduled `.fsm` text can contain assignment operators in state DT blocks and
non-state DT blocks. DT selector logic is combinational; the assignment
family decides what kind of target the selected value drives, not whether the
DT itself is combinational or sequential:

- `=` drives a combinational target mux output.
- `<-` and `<=` drive sequential/flopped targets.
- `<1` requests a one-cycle delayed pulse.

When scheduled `.fsm` text assigns a declared actor output port, the emitted
LHS carries the normal `.fsm` output marker for every assignment family, such
as `done>`, `last_error>`, or `rdata>`.

The machine-readable contract advertises these target-behavior families through
`dt_assignment_operator_family_map`.

ISF `(complete port)` lowering uses `<1`, not `<-`, so completion outputs are
one-cycle delayed pulses rather than sticky flopped status bits. The source
form is exact and requires one scalar `port` target. Drive phases that precede
completion should not also assign the same completion signal with `<-`; the
`.fsm` backend rejects mixed pulse-delayed and non-pulse sequential operators
on one LHS.
Blocking `(do child)` lowering also uses `<1` for the internal
`child_transaction_done` handoff generated in the rewired child terminal state.
That keeps each parent-visible child completion as a pulse, so repeated `do`
calls wait for fresh child completions instead of observing a sticky
already-done bit.
Blocking `(do child ...)` and parallel `(spawn child as instance ...)`
lowering also require the child target to resolve to a declared transaction in
the same actor before scheduled `.fsm` text is emitted. Forward references are
accepted, but missing child targets fail closed so they cannot synthesize dead
`child_start`/`child_done` or `instance_start`/`instance_done` paths.
Parameterized/generated `do` activations use generated instance handoffs such
as `{parent}_{child}_do_{ordinal}_start` and `_done`.
Spawned child instances are static generated HDL. Runtime spawn states only
activate the persistent child instance through its start path, and child
completion returns that instance to start-gated idle. Repeat-body spawn reuses
the same lexical instance on each iteration, including optional static
parameter overrides and optional input/output binding handoff ports, and the
shipped repeat-body subset requires same-body `await_all` sequencing, or
single-pending same-body `await_any`, before the repeat check can re-enter the
spawn. Repeat-body local `(do child)` reuses the local child start/done pulse
contract and reaches the repeat check only after the child done pulse is seen.
ISF rule `(trigger transaction)` lowering also uses `<1`, not `<-`, for the
generated `rule_transaction` trigger source. Generated combinational fan-in
then drives `transaction_start` from every source for that transaction. This
keeps rule-driven transaction starts pulse-shaped instead of leaving a sticky
start request active after the rule fires, while preserving per-rule trigger
provenance in the scheduled `.fsm` artifact.

ISF `(sample port as name)` lowering is a D-input contract. The source form is
structurally exact: `port` and `name` are scalar names, `as` is required, and
extra operands are rejected. Scheduled `.fsm` artifacts use `<=`, not `<-`, so
the authored sampled name denotes the D-input/next-value side in the state
where the sample appears. This preserves same-state visibility for sample
piggybacking, especially when a drive follows the samples and its parameter
wiring consumes a sampled alias in the same scheduled state. Lowering samples
with `<-` would instead make the alias denote the previous Q/output value in
that state and could require an extra state to avoid stale data.

## Schedule Report

`FSM::Scheduler::ISF->report($actor)` and `--emit-schedule-json` produce a
machine-readable schedule report. On success, the CLI report path is expected
to keep stderr clean and emit the JSON payload on stdout.

The bounded public top-level key family is:

```text
schema_version
source
scheduled_fsm
clock
reset
watchdog
actor_phases
actor_stages
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

Current bounded nested and array summary families:

```text
reset: name, kind, polarity
actor_phases entries: name, body
actor_stages entries: name, body
actor_params entries: name, value
actor_constants entries: name, value
actor_network: kind, instances, groups, generated_tops, association_schedules, group_schedules, data_movements, event_waits, transaction_triggers
actor_network instances entries: name, actor_type, declaration
actor_network instance declaration values: actor, instance_alias
actor_network groups entries: name, members, mode, declaration, source, scheduling
actor_network generated_tops entries: kind, top_module, top_fsm, parent_module, parent_scheduled_fsm, instance, child_module, child_scheduled_fsm, target_transaction, trigger_parent_port, trigger_child_port, event, event_parent_port, event_child_port, clock, reset
actor_network generated_tops multi-child entries: kind, top_module, top_fsm, parent_module, parent_scheduled_fsm, children, clock, reset
actor_network generated_tops child entries: instance, child_module, child_scheduled_fsm, target_transaction, trigger_parent_port, trigger_child_port, event, event_parent_port, event_child_port
actor_network association_schedules entries: association, kind, lifetime, owner_transaction, context, members, target_transactions, signals, schedule, dependency_policy, storage, source, sink
actor_network group_schedules entries: group, owner_transaction, context, members, target_transactions, signals, schedule, dependency_policy, storage, source, sink
actor_network event_waits entries: transaction, context, instance, event, signal, source
actor_network transaction_triggers entries: owner_transaction, context, instance, target_transaction, signal, sink
inferred_storage entries: name, kind, optional role, optional type, optional type_kind, optional width
transactions entries: name, states, count
transaction_waits entries: transaction, cycles, count_kind, count_source, entry_state, exit_state, counter_signal, counter_width
transaction_waits count_kind values: static, runtime_scalar, runtime_expression
transaction_loops entries: transaction, kind, condition, entry_state, decision_states, body_start, body_states, exit_state, body_clause_count
transaction_stages entries: transaction, name, kind, state, ready, valid
temporal_contracts entries: transaction, name, kind, trigger, signal, within_cycles, pending_signal, counter_signal, fail_signal, overlap_policy, reset_policy, assertion_projection
dt_blocks entries: name, kind, assignments
compile_issues entries: code, severity, target, domain, proof_status, reason, sources
compile_issues source entries: owner, owner_kind, source_kind, target, operator, rhs, domain
compile_issues with no nonfatal issues: empty array
compatible_fanin_groups entries: kind, domain, sources, optional target/value keys
compatible_fanin_groups source entries: same bounded source keys as compile_issues
priority_resolutions entries: target, winner, winner_kind, loser, loser_kind
resource_arbitration entries: resource, kind, arbiter, user, user_kind, members, suppressed_by
library_uses entries: library, alias, export, kind, instance, module, scheduled_fsm, parameters, bindings
library_uses parameter entries: name, source, value
library_uses binding entries: role, library_name, parent_name, width
bank_accesses entries: kind, owner, owner_kind, container_kind, container_name, bank, index, width, depth, scalar_entries, same_cycle_policy, value, target
transaction_port_bindings entries: site_kind, owner, owner_kind, target_transaction, role, port, actor_signal, actor_expression, width, instance, parent_port, child_port, start_signal, done_signal, trigger_source, payload_source
clock_domains entries: name, default, clock, reset, scheduled_fsm, ports, storage, transactions, rules, library_uses, child_instances, crossings, state_count, dt_block_count
clock_domains child_instances entries: kind, owner, child, instance
clock_domains crossings entries: event, role, signal, ready
crossings entries: name, kind, source_domain, source_signal, destination_domain, destination_signal, ready_signal, instance, module, outstanding_policy, payload, top_fsm
```

For each `dt_blocks` entry, `assignments` is a non-negative integer count of
assignment forms in the matching scheduled `.fsm` DT block. It is not an
assignment payload list. The machine-readable contract advertises this through
`schedule_report_dt_assignments_shape`.
For each `dt_blocks` entry, `kind` is currently one of `drive`,
`do_port_binding`, `latency_counter`, `rule`, `rule_trigger_fanin`,
`spawn_port_binding`, `temporal_contract_monitor`, or
`trigger_generated_activation`. The machine-readable contract advertises this
through `schedule_report_dt_kind_values`.

For each `inferred_storage` entry, `kind` is currently one of `counter` or
`register`. Optional `role` values describe the stable scheduler purpose when
the lowerer has direct evidence. The current role family is
`activation_done_handoff`, `activation_start_handoff`, `actor_storage`,
`completion_pulse`, `data_register`, `dynamic_wait_counter`, `drive_payload`,
`drive_request`, `extract_field`, `latency_counter`, `repeat_counter`,
`resource_round_robin_pointer`, `rule_trigger_payload_source`,
`rule_trigger_source`, `sample_alias`, `temporal_contract_monitor`,
`transaction_port`, `transaction_port_binding`, `trigger_done_observe`, and
`watchdog_counter`.
Runtime scalar and runtime expression waits use `dynamic_wait_counter` for
their generated sampled-count storage. Rule-trigger source pulses use
`rule_trigger_source`, and per-input trigger payload-source storage uses
`rule_trigger_payload_source`. Generated activation start/done handoff storage
uses `activation_start_handoff` and `activation_done_handoff` when those
one-bit generated handoff signals appear in `inferred_storage[]`. Generated
activation port-binding handoff storage uses `transaction_port_binding`, and
generated rule-trigger completion observation uses `trigger_done_observe`.
Transaction-local port storage uses `transaction_port` when a declared
transaction port is materialized in the scheduled `.fsm` review artifact.
Bounded `round_robin` resource arbitration for `rule_slot`, `output_bundle`,
`transaction_start`, or `storage_port` uses
`resource_round_robin_pointer` for the generated pointer counter.
Temporal-contract pending/fail registers and age counters use
`temporal_contract_monitor`; use `temporal_contracts[]` to map those signal
names back to the specific bounded-eventual contract. Optional `width` values
are positive integer bit widths when present, and are currently present for
declared actor-owned storage, inferred scheduler counters, and register
storage with known ISF width evidence. Declared typed actor-owned storage may
also report the authored alias in `type` and the resolved top-level kind in
`type_kind`; these are bounded summaries and do not expose raw type-spec
hashes. The machine-readable contract advertises these through
`schedule_report_storage_kind_values`, `schedule_report_storage_role_values`,
`schedule_report_storage_optional_keys`, and
`schedule_report_storage_width_shape`.

Generated names in schedule reports and generated artifacts are deterministic
for the same source and FSMGen version, and bounded report fields may use them
as report-local or artifact-local identifiers. They are not a public semantic
string grammar. Downstream consumers should use explicit bounded fields such
as `owner`, `owner_kind`, `role`, `kind`, `instance`, `parent_port`,
`child_port`, `trigger_source`, `payload_source`, storage `role`, and
generated-composition summaries instead of deriving semantics from generated
name spelling. Before full schema freeze, a feature-scoped slice may change a
generated spelling only with synchronized docs, contract metadata where
applicable, and tests.
Schedule-report evolution is additive by default only for new top-level keys,
new nested optional keys, or new value-family members that are advertised in
the public contract metadata and covered by focused tests and docs in the same
slice. Removing an advertised key, renaming a key, changing a required key to
optional or vice versa, changing a value type, or changing an advertised
value's meaning is breaking and requires a `schema_version` bump plus
migration or deprecation documentation in the same slice. Deprecated fields
must remain documented until the schema version that removes them.

For each `bank_accesses` entry, `kind` is `store` or `load`;
`same_cycle_policy` is currently `read_before_write`; `scalar_entries` lists
the deterministic scalarized storage entries used in the scheduled `.fsm`;
`value` is populated for stores and JSON null for loads; `target` is populated
for loads and JSON null for stores. The machine-readable contract advertises
the exact key set and value families through
`schedule_report_bank_access_keys`,
`schedule_report_bank_access_kind_values`, and
`schedule_report_bank_access_policy_values`.

For each `transactions` entry, `states` is an array of scheduled state names
belonging to that transaction in emitted order, and `count` is a non-negative
integer equal to the `states` array length. The machine-readable contract
advertises this through `schedule_report_transaction_states_shape` and
`schedule_report_transaction_count_shape`.
The `transactions` array itself is sorted lexically by transaction name. Each
entry's `states` array keeps scheduled `.fsm` state emission order for that
transaction. The machine-readable contract advertises this through
`schedule_report_transaction_ordering`.

For each `actor_constants` entry, `name` is the actor-local constant name and
`value` is the stringified compile-time value emitted into scheduled `.fsm`
`+constants`. These constants are compile-time scheduler/source symbols, not
runtime ports, not overrideable params, and not inferred storage.

For each `actor_params` entry, `name` is the actor-level parameter name and
`value` is the JSON-safe default value emitted into scheduled `.fsm`
`+params`; scalar enum member defaults, actor-constant-backed scalar defaults,
actor-parameter-backed scalar defaults, and enum, actor-constant, or earlier
actor-parameter leaves inside aggregate/list defaults preserve the authored
tokens. Actor-static-backed defaults carry resolved literals internally for
scalar actor-parameter consumers such as widths and counts.
These are static specialization defaults, not runtime ports, and do not
replace the generated-composition or reusable-library parameter binding
reports for use sites. The
machine-readable contract advertises these through
`schedule_report_actor_param_keys`.

Generated-composition child `parameters[]` and instance
`parameter_bindings[]` entries preserve authored scalar enum member tokens and
aggregate/list enum leaves for generated child transaction parameter defaults.
Actor constants and actor-local scalar parameter defaults used by generated
child transaction parameter defaults are literalized before child `+params`
emission and report publication, so generated-composition child defaults and
default instance bindings stay self-contained. Actor constants, actor-local
scalar parameter defaults, scalar enum member values, and matching leaves
inside activation aggregate/list override values are resolved to literal values
before generated-top emission, so generated-composition instance
`parameter_bindings[]` entries carry the emitted literal override value for
those use sites.

For each `actor_phases` or `actor_stages` entry, `name` is the authored
actor-level metadata name and `body` is the JSON-safe copy of the
parser-validated list-form body. These arrays are informational report
metadata only; actor-level phases and stages still do not add scheduler,
generated `.fsm`, generated-top, or HDL runtime behavior. The
machine-readable contract advertises these through
`schedule_report_actor_phase_keys` and
`schedule_report_actor_stage_keys`.

For each `transaction_waits` entry, `transaction` is the authored transaction
name, `cycles` is the exact positive resolved static wait count or JSON null
for runtime waits, `count_kind` is `static`, `runtime_scalar`, or
`runtime_expression`, `count_source` is the literal, actor constant name,
actor parameter name, runtime scalar source signal, or normalized runtime
expression text,
`entry_state` is the generated wait state, and `exit_state` is the following
scheduled state after the wait. For consecutive runtime waits, that following
scheduled state can be the next generated wait entry; the generated edge split
may still bypass farther when the next runtime count is zero. Static waits
report `counter_signal` and `counter_width` as JSON null. Runtime waits report
the generated sampled counter name and width through those fields. `(wait 0)`
and symbolic waits that resolve to zero are no-ops and do not create report
entries. Actor-local constants used by symbolic waits are reported separately
through `actor_constants[]`. The machine-readable contract advertises these
through `schedule_report_transaction_wait_keys` and the count-kind value list
through `schedule_report_transaction_wait_count_kind_values`.

For each `transaction_loops` entry, `transaction` is the authored transaction
name, `kind` is `while` or `until`, `condition` is the normalized guard text
used in the scheduled `.fsm`, `entry_state` names the first state associated
with the loop, `decision_states` lists generated condition-sampling states,
`body_start` names the first body state, `body_states` lists generated body
states, `exit_state` names the state reached after the loop, and
`body_clause_count` is the authored body clause count. The machine-readable
contract advertises these through `schedule_report_transaction_loop_keys`.

For each `transaction_stages` entry, `kind` is currently
`ready_valid_barrier`. The entry preserves the authored transaction/stage
names and reports the generated stage state plus the ready input and valid
output. The machine-readable contract advertises these through
`schedule_report_transaction_stage_keys` and
`schedule_report_transaction_stage_kind_values`.

For each `temporal_contracts` entry, `kind` is currently
`bounded_eventually`, `overlap_policy` is currently `fail`, and
`assertion_projection` is currently `systemverilog_sticky_fail`. The entry
reports the generated trigger state, observed signal, positive cycle bound,
generated pending, counter, and fail signal names, and reset policy.
`reset_policy` uses the same bounded shape as the top-level reset summary when
reset is configured or defaulted and is null only when the selected
default-domain reset is omitted. For
SystemVerilog-family generation, FSMGen projects the generated sticky fail bit
into a verification-only assertion under `` `ifndef SYNTHESIS``; Verilog
output remains assertion-free. The machine-readable contract advertises these
through `schedule_report_temporal_contract_keys`,
`schedule_report_temporal_contract_kind_values`,
`schedule_report_temporal_contract_overlap_policy_values`,
`schedule_report_temporal_contract_assertion_projection_values`, and
`schedule_report_temporal_contract_reset_policy_shape`.
Raw monitor equations, internal arm request names, and backend assertion text
are not part of the public temporal-contract report entry.

For the `reset` summary, `kind` is currently `async` or `sync`, and `polarity`
is currently `active_high` or `active_low`. The machine-readable contract
advertises those value families through `schedule_report_reset_kind_values` and
`schedule_report_reset_polarity_values`.
When reset is configured or defaulted for a legacy single-clock actor, `reset`
is a hash reference with `schedule_report_reset_keys`. When the selected
default clock-domain reset is omitted, `reset` is null. The machine-readable
contract advertises this through `schedule_report_reset_shape`.

The top-level `inputs` and `outputs` values are non-negative integer counts.
Single-clock reports count interface ports by direction. Multi-domain reports
count generated-top public ports, including domain clocks/resets and actor
interface ports. `port_count` equals their sum. The top-level `state_count`
value is a non-negative integer count of scheduled `.fsm` state blocks in the
current report scope; multi-domain generated-top reports use zero and expose
domain-local counts in `clock_domains[]`. The machine-readable contract
advertises this through `schedule_report_interface_count_shape` and
`schedule_report_state_count_shape`.

The top-level `schema_version` value is integer `1` for the current
schedule-report payload shape and is separate from the
`embedding.isf_public_interface` contract metadata `schema_version`.
The top-level `source` value is an actor-derived `.isf` basename, and
`scheduled_fsm` is the scheduled `.fsm` basename for the current report scope.
Multi-domain reports use the generated `<actor>_top.fsm` artifact. `clock` is
the scalar clock signal name from the actor declaration, `clk` for omitted
legacy single-clock actor clocks, or the selected default-domain clock when
`clock_domains` is present. `watchdog` is a scalar resolved limit, with omitted
watchdog clauses normalized to `65535` and actor-constant actor watchdogs
reported as the resolved integer. The machine-readable contract
advertises these through
`schedule_report_source_shape`, `schedule_report_scheduled_fsm_shape`,
`schedule_report_clock_shape`, and `schedule_report_watchdog_shape`.

The current lowerer emits DT summaries in deterministic lowering order:
transaction/rule-created DTs retain their construction order, generated
rule-trigger fan-in DTs follow rule DTs by transaction name, and hash-backed
drive DTs are emitted lexically by drive name. This is a bounded
review-artifact and schedule-report stability promise, not a promise that raw
`LoweringIR` hashes are public. The machine-readable contract advertises the
same policy in `scheduled_fsm_dt_ordering` and `schedule_report_dt_ordering`.
Those ordering fields are exact shared-policy metadata for the current
scheduled `.fsm` review artifact and schedule report.

For single-clock multi-file lowerings, the current schedule report describes
the parent scheduled module only. Child scheduled `.fsm` text remains
available through the lower-result `files` map. For multi-domain lowerings,
the current schedule report describes the generated top at the top level and
projects domain-local artifact metadata through `clock_domains[]` plus
crossing metadata through `crossings[]`. The machine-readable contract
advertises this current scope in `schedule_report_multi_file_scope`.
For successful schedule reports, `compile_issues` is present as an array. It is
empty when the successful report has no nonfatal compile issues. The
machine-readable contract advertises that no-issue success shape in
`schedule_report_compile_issues_success_shape`.
Nonfatal conflict issue entries in `compile_issues` are bounded to stable
`code`, `severity`, `target`, `domain`, `proof_status`, diagnostic `reason`,
and capped `sources` summaries. The machine-readable contract advertises the
bounded issue keys in `schedule_report_compile_issue_keys`, source-summary keys
in `schedule_report_compile_issue_source_keys`, current severity values in
`schedule_report_compile_issue_severity_values`, and current proof-status
values in `schedule_report_compile_issue_proof_status_values`.
The current proof-status value that matters for nonfatal conflict reporting is
`not_doable`: it means the lowerer is explicitly flagging that compile-time
proof is NOT doable for that case, instead of silently treating the design as
conflict-free. Fail-closed conflict cases remain targeted diagnostics, not
successful schedule-report entries.
Those rejected diagnostics name the stable code, target, reason, conflicting
owners, source kinds, operators, and values. The CLI `--emit-schedule-json`
path does not emit successful JSON for those rejected conflicts.
Accepted fan-in metadata uses a top-level
`compatible_fanin_groups` array with bounded `kind`, `domain`, target/value
facts, and the same capped source summaries. The machine-readable contract
advertises required group keys in `schedule_report_fanin_group_required_keys`,
optional group keys in `schedule_report_fanin_group_optional_keys`, and current
group kinds in `schedule_report_fanin_group_kind_values`.
The public fan-in projection is narrower than internal classification: request
and pulse fan-in are reported through `request` and `pulse` groups rather than
duplicated as generic `same_target_value` groups.
Transaction port binding provenance uses a top-level
`transaction_port_bindings` array. Each entry is bounded to the advertised key
set and records the binding site kind (`do`, `spawn`, or `rule_trigger`),
owner, target transaction, port role/name, actor signal when the actor side is
a scalar endpoint, formatted actor expression, width, and generated handoff
signal names where applicable. Parameterized rule-trigger entries use the
generated trigger instance handoff names and preserve the per-rule trigger and
payload source names. For expression-valued input bindings,
`actor_signal` is JSON null and `actor_expression` carries the formatted
source expression. JSON null is used for non-applicable handoff fields. The
machine-readable contract advertises the entry key set in
`schedule_report_transaction_port_binding_keys` and the current site-kind
values in `schedule_report_transaction_port_binding_site_kind_values`.
Successful arbitration metadata uses top-level `priority_resolutions` and
`resource_arbitration` arrays. `priority_resolutions` records static
target-local suppressions with bounded winner/loser owner names and owner
kinds. `resource_arbitration` records bounded resource grant-shaping decisions
for enforced resources, including the resource name, resource kind, arbiter,
rule user, explicit member list, and users that can suppress that user's
grant. For `priority`, `suppressed_by` names higher-priority bound rule users.
For bounded `round_robin`, `suppressed_by` names dynamic peer rule users that
can block that grant for a given pointer position and request set. `members`
is an array; it is empty when the resource has no explicit member list and
contains declared actor output or concrete actor-owned storage signal names
for explicit output-bundle members. These entries describe the lowering
decision, not per-cycle runtime grant values.
Raw `assignment_provenance`, activation context, assignment indexes, and
priority/resource suppression bookkeeping remain non-public `LoweringIR`
internals unless a later slice deliberately advertises a narrower field.

Multi-domain schedule reports add two bounded top-level arrays.
`clock_domains[]` is empty for legacy one-clock actors. For accepted
`(clock-domains ...)` actors, each entry records the declared domain name,
default marker, clock/reset summary, scheduled domain artifact basename, local
port/storage/transaction/rule/library/child-instance names, local crossing
endpoints, and bounded domain report counts. Multi-domain reports describe the
generated top as the top-level report scope, so top-level `state_count` is
zero and domain-local scheduled state counts live in `clock_domains[]`.
`crossings[]` is empty when no crossing primitive is declared. For accepted
event crossings, each entry records the source domain/signal, destination
domain/pulse signal, ready signal, generated CDC instance/module names,
single-outstanding acknowledgement policy, no-payload policy, and generated
top basename. Plain SystemVerilog/Verilog-family HDL generation for accepted
event-crossing actors emits the generated top and concrete acknowledged-event
CDC child modules.

The schedule report is not yet a frozen full schema. Downstream consumers should
use the advertised contract metadata instead of assuming every current field,
generated state name, or private lowering decision is permanent.
The advertised schedule-report metadata fields are exact for the bounded public
key families and policy strings they name.

### Schedule-Report Freeze Readiness

`schedule_report_full_schema_stable` is currently true. Schedule JSON payload
schema version `1` is a public, stable schema under the evolution rules below.
Raw parser actor hashes and `LoweringIR` objects remain non-public.

Contractual now:

- The in-process `report(...)` path and `--emit-schedule-json` CLI path emit
  the same successful schedule report for accepted sources.
- `schedule_report_top_level_keys` and the advertised nested key/value
  families define the stable schema-version-1 public shape.
- Scalar count, reset/nullability, transaction ordering, DT ordering, storage
  kind/role/width, and feature-owned summary arrays are public to the extent
  described by their advertised metadata fields.

Stable, versioned evolution:

- New optional keys or value-family members may be added when the same slice
  updates this contract, the mdBook/spec, and focused regressions.
- `inferred_storage[].role`, `compile_issues[]`,
  `compatible_fanin_groups[]`, `priority_resolutions[]`,
  `resource_arbitration[]`, `actor_constants[]`, `actor_phases[]`,
  `actor_stages[]`, `actor_params[]`, `transaction_waits[]`,
  `transaction_stages[]`, `transaction_loops[]`, `temporal_contracts[]`,
  `transaction_port_bindings[]`, `actor_network`, `library_uses[]`, and
  `generated_composition` are bounded summaries, not raw IR exports.
- Raw assignment provenance, private assignment indexes, and activation proof
  internals remain private. Public substitutes are the bounded summary arrays
  advertised above plus aggregate fields such as `dt_blocks[].assignments`,
  which is a count rather than a serialized assignment list.
- Parent schedule reports do not recursively embed child schedule reports.
  Multi-file public detail is bounded to `actor_network`,
  `generated_composition`, `library_uses[]`, `clock_domains[]` /
  `crossings[]`, and the public `lower(...)` files map.

- Breaking schedule-report changes require a `schema_version` bump plus
  migration or deprecation documentation. The executable golden matrix in
  [t/1255-isf-schedule-report-golden-matrix.t](../t/1255-isf-schedule-report-golden-matrix.t)
  assigns every advertised `schedule_report_*` branch to at least one
  in-process/CLI parity case.

## Non-Public Internals

These are not stable public interfaces yet:

- The raw actor hash returned by the parser as a whole.
- Actor fields beyond the advertised `actor_shell_required_keys`.
- Raw library resolver state and raw exported library actor hashes.
- Transaction port behavior beyond parser-shell `ports.inputs[]` /
  `ports.outputs[]` `name`/`width` metadata, scalar/literal/list-expression
  input-binding lowering for `do`, `spawn`, and rule-trigger activation sites,
  plus the first conflict/runtime coverage for binding-generated assignments.
  Rule-trigger output bindings, explicit snapshot-vs-live timing selection,
  broader static conflict diagnostics, richer report fields, and full
  expression width inference remain deferred follow-on port-binding work.
- Transaction control-flow behavior beyond shipped static/symbolic actor
  constant and actor parameter/runtime scalar/runtime expression `(wait N)`,
  sample-compatible runtime wait pending
  samples, and top-level transaction `(while cond body...)` /
  `(until cond body...)` remains non-public except for the documented
  top-level repeat-body local `(do child)` subset, top-level repeat-body
  generated-child `(do child)` subset, top-level repeat-body generated
  `(do child (params ...) [(bind ...)] [(domain NAME)])` subset, repeat-body
  samples before or after shipped do states, and top-level
  repeat-body spawn
  plus optional static `(params ...)`, optional `(bind ...)` port handoffs,
  optional declared same-domain `(domain NAME)` metadata, same-body
  `await_all`, single-pending same-body `await_any`, and multi-pending
  same-body `await_any` followed by same-body `await_all` drain subset.
  Top-level when-body and switch-branch nested repeat generated spawns also
  support same-body `await_all`, single-pending same-body `await_any` when
  exactly one generated child is pending, or multi-pending same-body
  `await_any` followed by a mandatory same-body `await_all` drain. Top-level
  when-body and switch-branch nested repeats also support local `(do child)`
  while generated nested spawns are pending before or after a prior
  multi-pending `await_any` observation and before a later same-body
  `await_all` drain. Both top-level branch subsets
  support plain generated-child `(do child)` while generated nested spawns are
  pending before or after a prior multi-pending `await_any` observation and
  before that same later drain. Both top-level branch subsets support
  static-parameter generated
  `(do child (params ...))` while generated nested spawns are pending before
  that same later drain, and both top-level branch-contained subsets also
  support that static-parameter generated do after a prior multi-pending
  `await_any` observation. Both
  top-level branch subsets additionally support static-parameter generated
  `(do child (params ...) (bind ...))` while generated nested spawns are
  pending before that same later drain.
  Unsupported transaction parameter wait counts, non-scalar actor parameter
  wait counts, sample-incompatible runtime wait successors, nested loops, and
  loop bodies containing broader child activation, stages, or contracts need
  parser, lowering, report, and regression-backed contracts before downstream
  users can rely on them.
- `FSM::Scheduler::ISF::LoweringIR` internals.
- Emitter-private state objects.
- Any unadvertised keys in the lower-result hash or schedule report.

## Evolution Rule

This contract evolves with R14 implementation work.

When an ISF slice changes a downstream-visible behavior, update together:

- [docs/ISF_PUBLIC_INTERFACE_CONTRACT.md](ISF_PUBLIC_INTERFACE_CONTRACT.md)
- [docs/ISF_SPEC.md](ISF_SPEC.md)
- [docs/DOWNSTREAM_ISSUE_REPORTING.md](DOWNSTREAM_ISSUE_REPORTING.md) when the
  change affects downstream issue reproduction guidance
- [docs/book/src/13-intent-scheduling.md](book/src/13-intent-scheduling.md)
- [docs/book/src/13k-isf-feature-support-matrix.md](book/src/13k-isf-feature-support-matrix.md)
- [perl/FSM/Support/ISFPublicInterfaceContract.pm](../perl/FSM/Support/ISFPublicInterfaceContract.pm)
- focused regression tests for the changed public surface

The goal is not to freeze ISF prematurely. The goal is to make every public
promise explicit, discoverable, and regression-backed as the ISF compiler grows.
