# ISF Public Interface Contract

This is the live downstream-consumer contract for the `.isf` intent-scheduling
surface.
The single self-contained human integration handoff for downstream producers
and consumers is
[docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md](../ISF_DOWNSTREAM_INTEGRATION_SPEC.md).
That document must stay synchronized with this contract, the live `.isf` spec,
the mdBook, manifest metadata, support-accounting catalog, regression tests,
explicit deferrals, and implementation behavior.

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
`.ppif` is the first shipped Intent Abstraction Layer 2 (`IAL2`) public file
surface. It is Protocol/Platform Intent Format source and always lowers through
generated `.isf` before generated `.fsm`; direct IAL2-to-IAL0 lowering is not a
public contract. The machine-readable downstream-consumer boundary for shipped
suffixes, CLI modes, lowering order, and per-suffix status lives in
`./bin/fsmgen --capability-manifest` under `language_surface.file_surfaces`.
The public `.ppif` surface is the generic protocol/platform IAL2 container:
AXI is the first shipped IAL2 profile/example, not the definition of IAL2.
Future protocol-specific suffixes such as `.axi`, `.chi`, `.ace`, `.ahb`,
`.apb`, `.atb`, `.smbus`, or `.i2s` are profile aliases over IAL2 rather
than separate layers. Common IAL2 constructs stay small until compatible reuse
is proven across multiple profiles.

Current bounded `.ppif` coverage includes one-channel Valid-Ready sources,
including the AXI AW first-profile sample and the protocol-neutral
valid-ready handshake sample, the AXI AW/W multi-channel Valid-Ready bundle,
the protocol-neutral dual-channel Valid-Ready bundle, and one-object AXI
manager capacity/status sources. Support-accounted AXI manager
coverage includes capacity/status,
ID-family metadata, transaction envelopes and fan-in, concrete-ID assertions,
bounded auto-ID lifecycle, same-ID reject and issue-order-queue policy,
generated auto-ID write/read response-demux, generated single/last/multi-beat
read-data capture, burst-length/runtime validation, scalar `RRESP`
aggregation, one-or-more read burst-last queue-head groups, one-or-more write
queue-head groups, read single-beat and read burst-last queue-head
response-demux including multiple/mixed depth-3 scalar, raw-`ARLEN`,
runtime-validation, and multi-beat output-bank read-data groups, same-family
mixed auto-ID plus concrete queue-head response-demux with scalar,
raw-`ARLEN`, runtime-validation, and multi-beat output-bank read-data over the
selected read burst-last shape, generated single-active and multiple
all-dynamic write/read response-demux, generated all-dynamic same-ID
issue-order queues for selected write `BID`, read single-beat `RID`, and read
burst-last `RID && RLAST` depth-2/depth-3 shapes, selected read-data,
raw-`ARLEN`, runtime-validation, and multi-beat output-bank behavior over
generated all-dynamic read burst-last issue-order queues, generated mixed
dynamic/static response-demux families, generated one-dynamic plus
one-concrete-static mixed dynamic/static same-ID issue-order queue behavior
for write `BID`, read single-beat `RID`, and read burst-last `RID && RLAST`,
generated one-dynamic plus two-concrete-static mixed dynamic/static write
`BID` same-ID issue-order queue behavior, paired scalar read-data over the
generated mixed read single-beat and burst-last queue completions, report-only
raw-`ARLEN` burst-length capture, and runtime beat-count/`RLAST` validation
over the generated mixed read burst-last queue completion, and
runtime-validation multi-beat output banks over the generated mixed read
burst-last queue completion. Broader mixed issue-order queue cardinality
beyond that selected write `BID` multi-static shape, scoreboards,
group-local simultaneous enqueue widening, packed
burst-vector outputs, alternate full burst payload assembly, aliases, platform
clauses, full AXI manager behavior, direct backend lowering,
backend-language variants, and VHDL remain deferred. The first explicit
verification-output surface now ships as `--emit-verification-output
uvm-passive-monitor --verification-outdir DIR source.isf`, emitting an inert
UVM monitor skeleton package plus `verification-output-manifest.json` for
`.isf` sources with passive `verification_observations[]`. That surface is
separate from schedule/check/semantic JSON and does not claim UVM compile
support. The bounded VHDL verification-output surface also now ships as
`--emit-verification-output vhdl-observation-package --verification-outdir DIR
source.isf`, emitting an inert VHDL observation metadata package plus
`verification-output-manifest.json` for the same passive observation metadata.
It remains under the `.9` shape-only validation substrate and makes no VHDL
compile, VHDL syntax, PSL, simulator, analyzer, scoreboard, coverage, reusable
VIP, or direct IAL2 support claim.

Machine-readable discovery lives in
[perl/FSM/Support/ISFPublicInterfaceContract.pm](../../perl/FSM/Support/ISFPublicInterfaceContract.pm)
and is advertised through:

```text
./bin/fsmgen --capability-manifest
  -> embedding.isf_public_interface
```

The advertised contract object is full-surface JSON-round-trip audited by
[t/1113-isf-public-interface-contract-json-roundtrip-audit.t](../../t/1113-isf-public-interface-contract-json-roundtrip-audit.t).
Downstream tools can treat that contract metadata as JSON-safe discovery data.
It is also defensive-copy audited by
[t/1114-isf-public-interface-contract-defensive-copy-audit.t](../../t/1114-isf-public-interface-contract-defensive-copy-audit.t),
so callers can mutate a received copy without polluting later contract builds.
The identity and stability metadata is checked by
[t/1141-isf-public-identity-flags-metadata-audit.t](../../t/1141-isf-public-identity-flags-metadata-audit.t)
to keep schema version, bounded status, owner list, and stability flags exact
across direct and manifest views.
The downstream guidance metadata is checked by
[t/1142-isf-public-guidance-metadata-audit.t](../../t/1142-isf-public-guidance-metadata-audit.t)
to keep the advertised consumer advice exact and duplicate-free across direct
and manifest views.
The ISF-specific `tested_by` provenance metadata is checked by
[t/1144-isf-public-tested-by-metadata-audit.t](../../t/1144-isf-public-tested-by-metadata-audit.t)
to keep the advertised audit list exact, duplicate-free, repo-relative, and
present on disk across direct and manifest views.
Both capability-manifest CLI spellings are audited by
[t/1115-isf-public-interface-cli-manifest-audit.t](../../t/1115-isf-public-interface-cli-manifest-audit.t)
to keep the in-process contract and CLI-advertised contract aligned.
The `public_top_level_presence_keys` discovery list is checked by
[t/1131-isf-public-top-level-discovery-audit.t](../../t/1131-isf-public-top-level-discovery-audit.t)
to stay unique and exact across direct, manifest, and CLI manifest views.
The advertised entrypoint metadata is checked by
[t/1135-isf-public-entrypoint-metadata-audit.t](../../t/1135-isf-public-entrypoint-metadata-audit.t)
to stay exact and duplicate-free across the same views.
The advertised ISF CLI option list is checked by
[t/1136-isf-public-cli-option-metadata-audit.t](../../t/1136-isf-public-cli-option-metadata-audit.t)
to stay exact and duplicate-free across direct and manifest views.
The advertised CLI success-shape metadata is checked by
[t/1153-isf-public-cli-success-metadata-audit.t](../../t/1153-isf-public-cli-success-metadata-audit.t)
to keep the schedule JSON, `--outdir`, and plain HDL-generation success
surfaces exact across direct and manifest views.
The advertised `--strict` HDL-generation success metadata is checked by
[t/1155-isf-public-cli-strict-success-metadata-audit.t](../../t/1155-isf-public-cli-strict-success-metadata-audit.t)
to keep the accepted strict `file.isf` generation shape exact across direct and
manifest views and aligned with the APB strict CLI path.
The advertised in-process facade return-shape metadata is checked by
[t/1154-isf-public-facade-return-metadata-audit.t](../../t/1154-isf-public-facade-return-metadata-audit.t)
to keep the `parse_file(...)`, `parse_source(...)`, `lower(...)`, and
`report(...)` return containers exact across direct and manifest views and
aligned with real APB facade results.
The advertised parser and scheduler method-name lists are checked by
[t/1137-isf-public-method-name-metadata-audit.t](../../t/1137-isf-public-method-name-metadata-audit.t)
to stay exact and duplicate-free across those views.
The advertised constructor option list is checked by
[t/1138-isf-public-constructor-option-metadata-audit.t](../../t/1138-isf-public-constructor-option-metadata-audit.t)
to stay exact and duplicate-free across those views.
The plain `file.isf` HDL-generation path is checked by
[t/1123-isf-public-cli-hdl-generation-audit.t](../../t/1123-isf-public-cli-hdl-generation-audit.t)
to reach generated HDL with clean stderr for the APB fixture.
The advertised `--strict` option on that path is checked by
[t/1124-isf-public-cli-strict-mode-audit.t](../../t/1124-isf-public-cli-strict-mode-audit.t).
The compact SPI-like serial fixture is checked by
[t/1228-isf-spi-fixture-coverage.t](../../t/1228-isf-spi-fixture-coverage.t)
to keep file-backed schedule JSON, scheduled `.fsm`, plain HDL generation,
strict HDL generation, explicit MOSI bit selection, and ISF shift handoff
covered without claiming full external SPI protocol compliance.
The compact I2C-like serial fixture is checked by
[t/1309-isf-i2c-fixture-coverage.t](../../t/1309-isf-i2c-fixture-coverage.t)
to keep file-backed schedule JSON, scheduled `.fsm`, plain HDL generation,
strict HDL generation, switch-branch repeats, read-data shifting, sampled
write-data bit selection, and absence of an implicit `data_bit` input covered
without claiming full external I2C protocol compliance.
The burst-reader fixture is checked by
[t/1310-isf-burst-fixture-coverage.t](../../t/1310-isf-burst-fixture-coverage.t)
to keep file-backed schedule JSON, scheduled `.fsm`, plain HDL generation,
strict HDL generation, dynamic repeat counter storage, watchdog and latency
counter roles, sampled aliases, and completion/timeout pulse fan-in covered.
The UART-like transmit fixture is checked by
[t/1311-isf-uart-fixture-coverage.t](../../t/1311-isf-uart-fixture-coverage.t)
to keep file-backed schedule JSON, scheduled `.fsm`, plain HDL generation,
strict HDL generation, sampled-byte LSB drive selection, known-width
`shift_right`, repeat counter storage, busy drive sequencing, and completion
pulse behavior covered without claiming full external UART protocol
compliance.
The phase fixture is checked by
[t/1312-isf-phase-fixture-coverage.t](../../t/1312-isf-phase-fixture-coverage.t)
to keep file-backed schedule JSON, scheduled `.fsm`, plain HDL generation,
strict HDL generation, transaction phase pass-through states, absence of
reusable `done` drive storage, and delayed completion pulse behavior covered
without claiming executable actor-level phase scheduling.
The switch fixture is checked by
[t/1313-isf-switch-fixture-coverage.t](../../t/1313-isf-switch-fixture-coverage.t)
to keep file-backed schedule JSON, scheduled `.fsm`, plain HDL generation,
strict HDL generation, sampled selector capture, explicit branch dispatch,
default fallthrough, named-drive branch starts, and delayed completion pulse
behavior covered.
The when fixture is checked by
[t/1314-isf-when-fixture-coverage.t](../../t/1314-isf-when-fixture-coverage.t)
to keep file-backed schedule JSON, scheduled `.fsm`, plain HDL generation,
strict HDL generation, entry drive setup, conditional decision states,
multi-step true-body drives, false-path fallthrough, compatible named-drive
start fan-in, and delayed completion pulse behavior covered.
The generated-composition fixture is checked by
[t/1315-isf-generated-composition-fixture-coverage.t](../../t/1315-isf-generated-composition-fixture-coverage.t)
to keep file-backed strict schedule JSON, strict `--outdir` file emission,
parent/child/generated-top scheduled `.fsm` artifacts, start/done handoffs,
named-drive request/payload handoffs, public input fanout, `await_all`
synchronization, and strict top/parent/child HDL generation covered.
The rule/resource fixture is checked by
[t/1316-isf-rule-resource-fixture-coverage.t](../../t/1316-isf-rule-resource-fixture-coverage.t)
to keep file-backed schedule JSON, scheduled `.fsm`, plain HDL generation,
strict HDL generation, rule-over-transaction priority suppression,
`rule_slot`/`priority` arbitration metadata, lower-priority rule gating, and
delayed completion pulse behavior covered. Focused resource tests additionally
cover bounded `rule_slot`/`round_robin` and
`transaction_start`/`round_robin` grants, generated pointer storage metadata,
report projection, and fail-closed unsupported round-robin combinations.
The ready/valid stage path is checked by
[t/1179-isf-phase-stage-boundary.t](../../t/1179-isf-phase-stage-boundary.t)
and [t/1223-isf-stage-lowering.t](../../t/1223-isf-stage-lowering.t), and
actor-level phase/stage report metadata is checked by
[t/1252-isf-actor-phase-stage-report.t](../../t/1252-isf-actor-phase-stage-report.t).
The assertion/property path used by bounded-eventually monitors is checked by
[t/1410-isf-assert-carrier.t](../../t/1410-isf-assert-carrier.t),
[t/1411-isf-assert-emit.t](../../t/1411-isf-assert-emit.t),
[t/1412-isf-property-implication.t](../../t/1412-isf-property-implication.t),
[t/1417-isf-property-sampled-value.t](../../t/1417-isf-property-sampled-value.t),
and [t/1418-isf-property-window-range.t](../../t/1418-isf-property-window-range.t).
The FIFO datapath fixture is checked by
[t/1319-isf-fifo-datapath-fixture-coverage.t](../../t/1319-isf-fifo-datapath-fixture-coverage.t)
to keep file-backed strict schedule JSON, scheduled `.fsm`, bounded
`bank_accesses[]` metadata, plain HDL generation, strict HDL generation,
scalarized depth-4 bank storage, pointer-guarded accepted pushes, and
pointer-guarded accepted pops covered.
The FIFO controller fixture is checked by
[t/1320-isf-fifo-controller-fixture-coverage.t](../../t/1320-isf-fifo-controller-fixture-coverage.t)
to keep file-backed strict schedule JSON, scheduled `.fsm`, compatible
same-value fan-in metadata, plain HDL generation, strict HDL generation,
occupancy/full/empty updates, and 2-bit pointer wrap covered without claiming
data-bank storage or `data_out` datapath transfer behavior.
The FIFO reusable-library fixture is checked by
[t/1321-isf-fifo-library-fixture-coverage.t](../../t/1321-isf-fifo-library-fixture-coverage.t)
to keep file-backed strict schedule JSON, generated importer/child/top
scheduled `.fsm` artifacts, strict `--outdir` emission, fixed parameter
overrides, use-site bindings, scalarized FIFO data entries, and plain plus
strict generated-top HDL generation covered without claiming use-site
parameter-driven FIFO interface shape, bank-depth specialization, generated-top
respecialization, or nested library imports.
The ATL temporary trigger-batch fixture is checked by
[t/1324-isf-atl-fixture-coverage.t](../../t/1324-isf-atl-fixture-coverage.t)
to keep file-backed static actor instances, one task-scoped same-cycle
external trigger batch, strict schedule JSON parity,
scheduled `.fsm` structure, and plain plus strict HDL generation covered
without claiming peer events, endpoint data movement, generated ATL child
artifacts, generated ATL tops, group endpoints, compact movement aliases, CDC,
payloads, ready/backpressure, route mux/storage, or permanent actor grouping.
The ATL resolved-child fixture is checked by
[t/1330-isf-atl-resolved-child-fixture-coverage.t](../../t/1330-isf-atl-resolved-child-fixture-coverage.t)
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
[isf/atl_two_child_pipeline.isf](../../isf/atl_two_child_pipeline.isf), the
first data-free two-child generated-top subset. It proves parent, reader,
writer, and generated top `.fsm` artifacts, strict schedule JSON parity,
plain plus strict HDL generation, and per-child generated-top wiring metadata
under `actor_network.generated_tops[].children[]`.
The same focused coverage now covers
[isf/atl_two_child_trigger_batch_pipeline.isf](../../isf/atl_two_child_trigger_batch_pipeline.isf),
the selected resolved-child trigger-batch generated-top subset. It proves the
same parent/reader/writer/top artifact family, one same-cycle parent trigger
batch, source-ordered waits to both triggered children, strict schedule JSON
parity for `transaction_triggers[]`, `event_waits[]`,
`association_schedules[]`, `group_schedules[]`, and
`generated_tops[]`, strict outdir emission, and plain plus strict generated
top HDL.
The same focused coverage now covers
[isf/atl_two_child_data_pipeline.isf](../../isf/atl_two_child_data_pipeline.isf),
the first one-bit generated-child actor-to-actor data route through that
two-child top. Public consumers should read the route from
`actor_network.data_movements[]` with `kind: "scalar_actor_handoff"` and
discover parent/reader/writer/top wiring from `actor_network.generated_tops[]`
with `children[]`; no public `data_links` key is exposed.
The same focused coverage now covers
[isf/atl_two_child_vector_data_pipeline.isf](../../isf/atl_two_child_vector_data_pipeline.isf),
the exact-width vector generated-child actor-to-actor route through that
two-child top. Public consumers should read the route from
`actor_network.data_movements[]` with `kind: "vector_actor_handoff"`,
`width` equal to the resolved child endpoint width, and
`width_source: "resolved_child_endpoint_exact_width"`; generated-top discovery
still comes from `actor_network.generated_tops[]` with `children[]`, and no
public `data_links` key is exposed.
The same focused coverage now covers
[isf/atl_two_child_multi_data_pipeline.isf](../../isf/atl_two_child_multi_data_pipeline.isf),
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
[t/1229-isf-compatibility-cli-parity.t](../../t/1229-isf-compatibility-cli-parity.t)
so accepted ignored handshake compatibility source reaches CLI schedule JSON
and strict HDL, while removed transaction `(assign ...)` fails through the CLI
with migration guidance.
The first reusable-library import path is checked by
[t/1230-isf-library-import-resolution.t](../../t/1230-isf-library-import-resolution.t)
so file-backed `(imports ...)` / `(use ...)` source resolves exported library
actors, validates use-site parameter and binding errors, emits specialized
child scheduled `.fsm` artifacts, and reports bounded `library_uses`
provenance.
Generated top wiring for resolved library actor instances is checked by
[t/1231-isf-library-generated-top.t](../../t/1231-isf-library-generated-top.t)
so a library actor wrapper reaches CLI `--outdir`, generated top `.fsm`, and
SystemVerilog output through the normal composition path, including explicit
generated-top links when a library actor uses different clock/reset names than
the importing actor. Those links are name remaps inside the current
single-clock-domain ISF model; they do not advertise CDC or interacting
clock-domain semantics.
The current APB schedule report is checked against the advertised key families
by [t/1116-isf-public-schedule-report-key-family-audit.t](../../t/1116-isf-public-schedule-report-key-family-audit.t).
The shipped stage report projection is covered by the ready/valid stage and
schedule-report metadata tests, including
[t/1223-isf-stage-lowering.t](../../t/1223-isf-stage-lowering.t) and
[t/1140-isf-public-schedule-report-metadata-audit.t](../../t/1140-isf-public-schedule-report-metadata-audit.t).
The advertised schedule-report metadata itself is checked by
[t/1140-isf-public-schedule-report-metadata-audit.t](../../t/1140-isf-public-schedule-report-metadata-audit.t)
to keep key families, grouped family maps, ordering, multi-file scope, and
successful `compile_issues` shape exact across direct and manifest views.
The schedule-report DT assignment-count shape is checked by
[t/1147-isf-public-report-dt-assignment-count-audit.t](../../t/1147-isf-public-report-dt-assignment-count-audit.t)
to keep `dt_blocks[*].assignments` documented as a non-negative assignment
count, not an assignment payload list.
The schedule-report DT kind metadata is checked by
[t/1158-isf-public-report-dt-kind-metadata-audit.t](../../t/1158-isf-public-report-dt-kind-metadata-audit.t)
to keep advertised `dt_blocks[*].kind` values exact across direct and manifest
views and aligned with APB, full-featured, and temporal-contract reports.
Stage and contract schedule-report key/value families are audited across
direct and manifest views and checked against generated JSON.
The inferred-storage metadata is checked by
[t/1148-isf-public-storage-metadata-audit.t](../../t/1148-isf-public-storage-metadata-audit.t)
to keep advertised storage `kind` values, optional `role` values, and optional
`width` shape exact across direct and manifest views. Data-operation storage
roles and widths are checked by
[t/1226-isf-data-width-storage-report.t](../../t/1226-isf-data-width-storage-report.t)
for sampled aliases, extracted fields, assembled targets, explicit-width
shift registers, and completion pulses.
Package-constant-backed data-operation width evidence is checked by
[t/1358-isf-data-op-package-constant-widths.t](../../t/1358-isf-data-op-package-constant-widths.t)
so qualified imported package scalar constants can back explicit shift
`(width ...)`, assemble `(widths ...)`, and extract `(widths ...)` evidence
when they resolve to positive integers.
Actor-owned fixed storage declarations are checked by
[t/1232-isf-actor-storage-declarations.t](../../t/1232-isf-actor-storage-declarations.t)
for parser shape, authored `(var ...)` / `(variable ...)` scalar storage
forms, scalarized bank lowering, `actor_storage` report metadata, fail-closed
diagnostics, and SystemVerilog generation for used storage.
Declarative scalar storage field metadata is checked by
[t/1453-isf-storage-field-metadata.t](../../t/1453-isf-storage-field-metadata.t),
covering `(fields (field NAME (bits HI LO) ...))` parser validation,
optional access/reset/enum metadata, `inferred_storage[].fields` report
projection, byte-identical scheduled `.fsm` output versus opaque storage, and
fail-closed diagnostics for malformed field maps.
Actor-owned scalar storage widths backed by actor-local scalar parameter
defaults are checked by
[t/1334-isf-scalar-storage-actor-param-widths.t](../../t/1334-isf-scalar-storage-actor-param-widths.t)
so accepted `(var NAME (width PARAM))` and
`(variable NAME (width PARAM))` entries resolve to positive integer storage
widths, scheduled `.fsm` `+size` declarations, schedule-report widths, and HDL
register ranges while unknown symbolic names, runtime interface signals,
zero-valued or non-scalar actor parameters, and arbitrary expressions fail
closed.
Actor-owned scalar storage widths backed by declared actor constants are
checked by
[t/1339-isf-scalar-storage-actor-constant-widths.t](../../t/1339-isf-scalar-storage-actor-constant-widths.t)
so accepted `(var NAME (width CONST))` and
`(variable NAME (width CONST))` entries resolve to positive integer storage
widths, scheduled `.fsm` `+size` declarations, schedule-report widths, and HDL
register ranges while zero-valued actor constants, unknown symbolic names,
runtime interface signals, and arbitrary expressions fail closed.
Actor-owned scalar storage widths backed by qualified imported package scalar
constants are checked by
[t/1354-isf-scalar-storage-package-constant-widths.t](../../t/1354-isf-scalar-storage-package-constant-widths.t)
so accepted `(var NAME (width PACKAGE.CONSTANT))` and
`(variable NAME (width PACKAGE.CONSTANT))` entries resolve to positive integer
storage widths, scheduled `.fsm` `+size` declarations, schedule-report widths,
width evidence, and HDL register ranges while unknown, unqualified,
aggregate, path, ambiguous, zero-valued, runtime, and expression-valued
sources fail closed.
Actor-owned bank storage widths backed by actor-local scalar parameter
defaults are checked by
[t/1335-isf-bank-storage-actor-param-widths.t](../../t/1335-isf-bank-storage-actor-param-widths.t)
so accepted `(bank NAME (width PARAM) (depth N))` entries resolve to positive
integer bank element widths, scheduled `.fsm` `+size` declarations,
schedule-report storage and `bank_accesses[]` widths, and HDL register ranges
while unsupported width sources fail closed.
Actor-owned bank storage widths backed by declared actor constants are checked
by
[t/1340-isf-bank-storage-actor-constant-widths.t](../../t/1340-isf-bank-storage-actor-constant-widths.t)
so accepted `(bank NAME (width CONST) (depth N))` entries resolve to positive
integer bank element widths, scheduled `.fsm` `+size` declarations,
schedule-report storage and `bank_accesses[]` widths, and HDL register ranges
while zero-valued actor constants, unknown symbolic names, runtime interface
signals, and arbitrary expressions fail closed.
Actor-owned bank storage widths backed by qualified imported package scalar
constants are checked by
[t/1355-isf-bank-storage-package-constant-widths.t](../../t/1355-isf-bank-storage-package-constant-widths.t)
so accepted `(bank NAME (width PACKAGE.CONSTANT) (depth N))` entries resolve
to positive integer bank element widths, scheduled `.fsm` `+size`
declarations, schedule-report storage and `bank_accesses[]` widths, width
evidence, and HDL register ranges while unknown, unqualified, aggregate,
path, ambiguous, zero-valued, runtime, and expression-valued sources fail
closed.
Actor-owned bank storage depths backed by actor-local scalar parameter
defaults are checked by
[t/1337-isf-bank-storage-actor-param-depths.t](../../t/1337-isf-bank-storage-actor-param-depths.t)
so accepted `(bank NAME (width W) (depth PARAM))` entries resolve to positive
integer bank depths, deterministic scalarized storage families, scheduled
`.fsm` `+size` declarations, schedule-report storage and `bank_accesses[]`
depth/scalar-entry metadata, and HDL register declarations while unknown
symbolic names, runtime interface signals, zero-valued or non-scalar actor
parameters, arbitrary expressions, and duplicate scalarized signal names fail
closed.
Actor-owned bank storage depths backed by declared actor constants are checked
by
[t/1341-isf-bank-storage-actor-constant-depths.t](../../t/1341-isf-bank-storage-actor-constant-depths.t)
so accepted `(bank NAME (width W) (depth CONST))` entries resolve to positive
integer bank depths, deterministic scalarized storage families, scheduled
`.fsm` `+size` declarations, schedule-report storage and `bank_accesses[]`
depth/scalar-entry metadata, and HDL register declarations while zero-valued
actor constants, unknown symbolic names, runtime interface signals, arbitrary
expressions, and duplicate scalarized signal names fail closed.
Actor-owned bank storage depths backed by qualified imported package scalar
constants are checked by
[t/1356-isf-bank-storage-package-constant-depths.t](../../t/1356-isf-bank-storage-package-constant-depths.t)
so accepted `(bank NAME (width W) (depth PACKAGE.CONSTANT))` entries resolve
to positive integer bank depths, deterministic scalarized storage families,
scheduled `.fsm` `+size` declarations, schedule-report storage and
`bank_accesses[]` depth/scalar-entry metadata, and HDL register declarations
while unknown, unqualified, aggregate, path, ambiguous, zero-valued, runtime,
and expression-valued sources fail closed.
Transaction-local port widths backed by actor-local scalar parameter defaults
are checked by
[t/1336-isf-transaction-port-actor-param-widths.t](../../t/1336-isf-transaction-port-actor-param-widths.t)
so accepted transaction `(ports ...)` `(input NAME (width PARAM))` and
`(output NAME (width PARAM))` entries resolve to positive integer port widths,
scheduled `.fsm` `+size` declarations, activation handoff widths,
`transaction_port_bindings[]` report widths, and HDL register ranges while
transaction parameters, unknown symbolic names, runtime interface signals,
zero-valued or non-scalar actor parameters, and arbitrary expressions fail
closed.
Transaction-local port widths backed by declared actor constants are checked by
[t/1342-isf-transaction-port-actor-constant-widths.t](../../t/1342-isf-transaction-port-actor-constant-widths.t)
so accepted transaction `(ports ...)` `(input NAME (width CONST))` and
`(output NAME (width CONST))` entries resolve to positive integer port widths,
scheduled `.fsm` `+size` declarations, activation handoff widths,
`transaction_port_bindings[]` report widths, and HDL register ranges while
transaction parameters, unknown symbolic names, runtime interface signals,
zero-valued actor constants, non-scalar actor constants, and arbitrary
expressions fail closed.
Transaction-local port widths backed by qualified imported package scalar
constants are checked by
[t/1357-isf-transaction-port-package-constant-widths.t](../../t/1357-isf-transaction-port-package-constant-widths.t)
so accepted transaction `(ports ...)` `(input NAME (width PACKAGE.CONSTANT))`
and `(output NAME (width PACKAGE.CONSTANT))` entries resolve to positive
integer port widths, scheduled `.fsm` `+size` declarations, activation
handoff widths, `transaction_port_bindings[]` report widths, and HDL register
ranges while unknown, unqualified, aggregate, path, ambiguous, zero-valued,
runtime, and expression-valued sources fail closed.
Rule expression guards are checked by
[t/1233-isf-rule-expression-guards.t](../../t/1233-isf-rule-expression-guards.t)
for shorthand and long-form guard normalization, scheduled `.fsm` DT-DTE
emission, HDL generation, and targeted parser diagnostics.
The depth-4 FIFO controller matrix is checked by
[t/1235-isf-fifo-same-cycle-update-matrix.t](../../t/1235-isf-fifo-same-cycle-update-matrix.t)
for the real controller interface, actor-maintained full/empty flags,
pointer/occupancy state updates, equality-based disjoint-rule proof, scheduled
`.fsm`, schedule report, and SystemVerilog reachability without inventing a
FIFO data-bank datapath.
Actor-owned bank access is checked by
[t/1236-isf-bank-access-lowering.t](../../t/1236-isf-bank-access-lowering.t)
for `(store <bank-name> <index> <value>)` and
`(load <bank-name> <index> as <target>)` parsing,
scalarized guarded lowering, bounded `bank_accesses` report metadata,
fail-closed diagnostics, and depth-4 FIFO data-path HDL reachability.
The fixed-shape reusable FIFO library fixture is checked by
[t/1237-isf-fifo-library-fixture.t](../../t/1237-isf-fifo-library-fixture.t)
for file-backed import of [isf/common/fifo.isf](../../isf/common/fifo.isf),
specialized child scheduled `.fsm` emission, generated top wiring, fixed
parameter provenance, same-cycle full push/pop case visibility, bank-backed
accepted push/pop artifacts, and `library_uses` report metadata.
Generated-top SystemVerilog for that FIFO fixture is checked by
[t/1238-isf-fifo-library-hdl-generation.t](../../t/1238-isf-fifo-library-hdl-generation.t)
for FIFO child parameter bindings, scalarized data entries, pointer-gated
accepted push/pop selectors, and AST factorization preserving distinct
`CoreAST` signal identities.
The reusable-library catalog contract is checked by
[t/1239-isf-library-catalog-contract.t](../../t/1239-isf-library-catalog-contract.t)
so the machine-readable public contract advertises
[docs/ISF_LIBRARY_CATALOG.md](../ISF_LIBRARY_CATALOG.md), the shipped catalog
entry key family, and the current shipped reusable definition list.
The transaction-summary metadata is checked by
[t/1149-isf-public-transaction-metadata-audit.t](../../t/1149-isf-public-transaction-metadata-audit.t)
to keep transaction `states` and `count` shapes exact across direct and
manifest views.
The transaction-ordering metadata is checked by
[t/1157-isf-public-report-transaction-ordering-audit.t](../../t/1157-isf-public-report-transaction-ordering-audit.t)
to keep transaction summaries lexically sorted by name while each
transaction's `states` array follows scheduled `.fsm` state emission order.
The reset-summary metadata is checked by
[t/1150-isf-public-reset-metadata-audit.t](../../t/1150-isf-public-reset-metadata-audit.t)
to keep advertised reset `kind` and `polarity` values exact across direct and
manifest views.
The reset container/null shape is checked by
[t/1159-isf-public-report-reset-shape-metadata-audit.t](../../t/1159-isf-public-report-reset-shape-metadata-audit.t)
to keep configured and defaulted legacy single-clock reset summaries as hashes
and domain-owned omitted resets as JSON null.
The schedule-report count metadata is checked by
[t/1151-isf-public-report-count-metadata-audit.t](../../t/1151-isf-public-report-count-metadata-audit.t)
to keep interface and state-count semantics exact across direct and manifest
views.
The schedule-report scalar metadata is checked by
[t/1152-isf-public-report-scalar-metadata-audit.t](../../t/1152-isf-public-report-scalar-metadata-audit.t)
to keep `source`, `scheduled_fsm`, `clock`, and `watchdog` shapes exact across
direct and manifest views.
The public `--emit-schedule-json` CLI path is checked by
[t/1121-isf-public-cli-schedule-report-audit.t](../../t/1121-isf-public-cli-schedule-report-audit.t)
to emit clean-stderr JSON matching the in-process scheduler report.
The explicit schedule-report freeze boundary is checked by
[t/1227-isf-schedule-report-freeze-boundary.t](../../t/1227-isf-schedule-report-freeze-boundary.t)
so the contract stays bounded-public, does not claim whole-schema stability,
and keeps the presence-family map scoped to key families.
The successful `compile_issues` report shape is checked by
[t/1130-isf-public-compile-issues-success-audit.t](../../t/1130-isf-public-compile-issues-success-audit.t)
for both in-process and CLI report paths.
The nonfatal `compile_issues` projection is checked by
[t/1212-isf-schedule-report-compile-issues-projection.t](../../t/1212-isf-schedule-report-compile-issues-projection.t)
for both in-process and CLI report paths.
The compatible fan-in projection is checked by
[t/1213-isf-schedule-report-compatible-fanin-projection.t](../../t/1213-isf-schedule-report-compatible-fanin-projection.t)
for both in-process and CLI report paths.
Rejected conflict diagnostics are checked by
[t/1214-isf-rejected-conflict-diagnostics.t](../../t/1214-isf-rejected-conflict-diagnostics.t)
for both in-process scheduler calls and the CLI schedule-report path.
Generated composition-top lowering is checked by
[t/1216-isf-generated-composition-top.t](../../t/1216-isf-generated-composition-top.t),
including contextual diagnostics for generated handoff port-name conflicts.
The accepted generated-composition report projection is a top-level
`generated_composition` field and is checked by
[t/1217-isf-generated-composition-schedule-report.t](../../t/1217-isf-generated-composition-schedule-report.t).
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
lowering by [t/1117-isf-public-lower-result-files-audit.t](../../t/1117-isf-public-lower-result-files-audit.t).
The lower-result discovery metadata is checked by
[t/1139-isf-public-lower-result-metadata-audit.t](../../t/1139-isf-public-lower-result-metadata-audit.t)
to keep `lower_result_presence_keys` and `lower_result_file_map_shape` exact
across direct and manifest views.
The lower-result file sub-shape metadata is checked by
[t/1156-isf-public-lower-result-file-shape-audit.t](../../t/1156-isf-public-lower-result-file-shape-audit.t)
to keep scheduled `.fsm` basename keys and scheduled-text roots exact across
direct and manifest views and aligned with single-file plus multi-file
lowering.
The public `--outdir` CLI path is checked by
[t/1122-isf-public-cli-outdir-lowering-audit.t](../../t/1122-isf-public-cli-outdir-lowering-audit.t)
to write scheduled `.fsm` artifacts matching the in-process lower-result
`files` map for a multi-file fixture.
The current multi-file schedule-report scope is checked by
[t/1128-isf-public-multifile-schedule-report-audit.t](../../t/1128-isf-public-multifile-schedule-report-audit.t).
The multi-domain clock-domain report projection and event-crossing fixture are
checked by [t/1247-isf-clock-domain-partition.t](../../t/1247-isf-clock-domain-partition.t).
That test now also covers the file-backed dual event-crossing fixture, proving
two generated CDC child modules and both source/destination endpoint roles in
one top. It also covers the file-backed no-reset event-crossing fixture,
proving absent-reset CDC metadata in the generated top and schedule-report
surface while preserving the current no-reset HDL fail-closed boundary.
Cross-domain activation crossings are checked by
[t/1387-isf-cross-domain-activation-handshake-lowering.t](../../t/1387-isf-cross-domain-activation-handshake-lowering.t):
a blocking `(do child)` covered by `(crossings (activation child (from SRC)(to
DST)))` lowers to per-domain modules plus a top that routes the start/done
handshake through two generated CDC children at the transaction top level,
directly inside top-level `repeat` and `when`/`switch`/`while`/`until` bodies,
directly inside a `repeat` nested in a top-level `when` body or top-level
`switch` branch, directly inside supported nested `when` chains reached from
those top-level branch bodies, and directly inside a `repeat` under those
supported nested `when` chains. The schedule report exposes the crossing with
`kind: "activation"` (carrying `child`, `source_domain`/`destination_domain`,
`start_signal`/`done_signal`, `start_instance`/`start_module`,
`done_instance`/`done_module`, `outstanding_policy`, `payload`, `top_fsm`) plus
per-domain endpoints `{ activation, role, start, done }`. Uncovered,
declared-but-unused, or mis-placed activation crossings, cross-domain
`(spawn)`, payload CDC, auto-generated crossings, repeat-contained branch
contexts, nested `switch`, nested `while`, nested `until`, and unsupported
deeper cross-domain `(do)` placements fail closed.
The `parse_source(...)` facade method is checked by
[t/1118-isf-public-parse-source-facade-audit.t](../../t/1118-isf-public-parse-source-facade-audit.t)
to ensure in-memory source text returns a scheduler-consumable actor with the
same public lower/report identities as `parse_file(...)` for a real fixture.
Generated `.fsm` DT block order and schedule-report `dt_blocks` order are
checked by
[t/1119-isf-deterministic-dt-block-order.t](../../t/1119-isf-deterministic-dt-block-order.t)
for both `parse_file(...)` and `parse_source(...)` on the APB fixture.
The scheduled `.fsm` artifact metadata is checked by
[t/1145-isf-public-scheduled-fsm-metadata-audit.t](../../t/1145-isf-public-scheduled-fsm-metadata-audit.t)
to keep `scheduled_fsm_dt_ordering`, its paired schedule-report ordering
policy, and the review-artifact flag exact across direct and manifest views.
The DT assignment operator metadata is checked by
[t/1146-isf-public-dt-assignment-metadata-audit.t](../../t/1146-isf-public-dt-assignment-metadata-audit.t)
to keep the combinational and sequential assignment families exact across
direct and manifest views.
The `live_document_paths` list is checked by
[t/1120-isf-public-live-document-path-audit.t](../../t/1120-isf-public-live-document-path-audit.t)
to keep the direct owner, in-process manifest, and both CLI manifest spellings
aligned on repo-relative Markdown paths that exist on disk, including the
format-agnostic downstream issue-reporting protocol used for local
reproduction bundles.
The ISF mdBook path subset is checked by
[t/1303-isf-public-live-book-paths-audit.t](../../t/1303-isf-public-live-book-paths-audit.t)
to keep every Intent Scheduling chapter from
[docs/book/src/SUMMARY.md](../book/src/SUMMARY.md), plus the canonical feature
backlog and reference map, advertised through the same public contract and
manifest views.
The book-facing shipped feature matrix is checked by
[t/1305-isf-book-feature-matrix-audit.t](../../t/1305-isf-book-feature-matrix-audit.t)
so the user-facing book keeps an explicit review surface for the shipped ISF
feature families.
The public constructor option boundary is checked by
[t/1125-isf-public-constructor-boundary-audit.t](../../t/1125-isf-public-constructor-boundary-audit.t)
for both adapter and scheduler facades.
The public constructor receiver boundary is checked by
[t/1133-isf-public-constructor-receiver-boundary-audit.t](../../t/1133-isf-public-constructor-receiver-boundary-audit.t).
The public parser facade method boundary is checked by
[t/1126-isf-public-parser-method-boundary-audit.t](../../t/1126-isf-public-parser-method-boundary-audit.t).
The public `parse_file(...)` path boundary is checked by
[t/1134-isf-public-parse-file-path-boundary-audit.t](../../t/1134-isf-public-parse-file-path-boundary-audit.t).
The public scheduler facade method boundary is checked by
[t/1127-isf-public-scheduler-method-boundary-audit.t](../../t/1127-isf-public-scheduler-method-boundary-audit.t).
The parser and scheduler method receiver boundary is checked by
[t/1132-isf-public-method-receiver-boundary-audit.t](../../t/1132-isf-public-method-receiver-boundary-audit.t).
The public facade failure diagnostic metadata is checked by
[t/1161-isf-public-facade-failure-diagnostic-metadata-audit.t](../../t/1161-isf-public-facade-failure-diagnostic-metadata-audit.t)
to keep constructor, parser, and scheduler facade boundary failures advertised
as bounded scalar diagnostics.
The scheduler-consumable actor shell returned by the public parser facades is
checked by
[t/1129-isf-public-actor-shell-contract-audit.t](../../t/1129-isf-public-actor-shell-contract-audit.t).
The actor-shell value-shape metadata is checked by
[t/1160-isf-public-actor-shell-value-shape-audit.t](../../t/1160-isf-public-actor-shell-value-shape-audit.t)
to keep the `actor_name`, `transactions`, and `interface` public handoff
shapes exact across direct and manifest views.
The actor-shell interface subshape is checked by
[t/1162-isf-public-actor-shell-interface-shape-audit.t](../../t/1162-isf-public-actor-shell-interface-shape-audit.t)
to keep the parser-returned `interface` inputs/outputs arrays and public port
entry `name`/`width` shape exact across direct and manifest views without
freezing the rest of the raw actor hash.
Generated-IAL1 output reset/default metadata is checked by
[t/1476-isf-output-default-reset.t](../../t/1476-isf-output-default-reset.t).
Actor-level interface outputs may carry parser-validated `reset_value` and
`default_value` fields when the source uses `(reset V)` or `(default V)` with
a non-negative integer literal `V` that fits the resolved positive integer
width. Reset metadata lowers to generated `.fsm` `+size`; default metadata
lowers to idle/quiescent `<-` output assignments. Inputs, type-referenced
outputs, unresolved-width outputs, negative values, malformed arity, and
too-wide values fail closed.
Actor top-level interface widths backed by actor-local scalar parameter
defaults are checked by
[t/1333-isf-interface-actor-param-widths.t](../../t/1333-isf-interface-actor-param-widths.t)
so accepted `(width PARAM)` entries resolve to positive integer public port
widths, scheduled `.fsm` `+size` declarations, and HDL port ranges while
unknown symbolic names, runtime interface signals, zero-valued or non-scalar
actor parameters, and arbitrary expressions fail closed.
Actor top-level interface widths backed by declared actor constants are checked
by
[t/1338-isf-interface-actor-constant-widths.t](../../t/1338-isf-interface-actor-constant-widths.t)
so accepted `(width CONST)` entries resolve to positive integer public port
widths, scheduled `.fsm` `+size` declarations, and HDL port ranges while
zero-valued actor constants, unknown symbolic names, runtime interface
signals, and arbitrary expressions fail closed.
Actor top-level interface widths backed by qualified imported package scalar
constants are checked by
[t/1353-isf-interface-package-constant-widths.t](../../t/1353-isf-interface-package-constant-widths.t)
so accepted `(width PACKAGE.CONSTANT)` entries resolve to positive integer
public port widths, scheduled `.fsm` `+size` declarations, schedule reports,
and HDL port ranges while unknown, unqualified, aggregate, path, ambiguous,
zero-valued, runtime, and expression-valued sources fail closed.
The interface-port boundary is checked by
[t/1188-isf-interface-port-boundary.t](../../t/1188-isf-interface-port-boundary.t)
so port names are unique across both input and output directions before an
actor shell is returned.
The actor-shell transaction subshape is checked by
[t/1163-isf-public-actor-shell-transaction-shape-audit.t](../../t/1163-isf-public-actor-shell-transaction-shape-audit.t)
to keep parser-returned transaction entries discoverable as unique non-empty
scalar `name`, a `ports` hash with `inputs`/`outputs` arrays, and a `clauses`
array shell while leaving the clause payload contents private scheduler input.
The transaction-port declaration boundary is checked by
[t/1240-isf-transaction-port-declarations.t](../../t/1240-isf-transaction-port-declarations.t)
so parser-accepted `(ports ...)` clauses normalize to directional
`name`/`width` entries and malformed direction, duplicate, width, or option
forms fail before scheduler lowering.
Actor-parameter-backed transaction port width declarations are checked by
[t/1336-isf-transaction-port-actor-param-widths.t](../../t/1336-isf-transaction-port-actor-param-widths.t)
so the same public transaction shell exposes resolved positive integer widths
for accepted actor-local scalar parameter defaults and keeps unsupported
symbolic sources fail-closed before scheduler lowering.
Actor-constant-backed transaction port width declarations are checked by
[t/1342-isf-transaction-port-actor-constant-widths.t](../../t/1342-isf-transaction-port-actor-constant-widths.t)
so the same public transaction shell exposes resolved positive integer widths
for accepted declared actor constants and keeps unsupported symbolic sources
fail-closed before scheduler lowering.
Package-constant-backed transaction port width declarations are checked by
[t/1357-isf-transaction-port-package-constant-widths.t](../../t/1357-isf-transaction-port-package-constant-widths.t)
so the same public transaction shell exposes resolved positive integer widths
for accepted qualified imported package scalar constants and rejects unknown,
unqualified, aggregate, path, ambiguous, zero-valued, runtime, and expression
sources before scheduler lowering.
Same-transaction-parameter-backed transaction port width declarations are
checked by
[t/1368-isf-transaction-port-transaction-param-widths.t](../../t/1368-isf-transaction-port-transaction-param-widths.t)
so accepted generated child and direct/non-generated transaction `(ports ...)`
entries with `(width TX_PARAM)` expose resolved positive integer widths in the
parser handoff, scheduled `.fsm` `+size` declarations, generated parent
handoff storage where applicable, `transaction_port_bindings[]` report widths,
and HDL port or register ranges. Transaction-local names resolve before actor
constants and actor parameters in this value slot. Cross-transaction parameter
names, zero-valued or
aggregate transaction parameters, forward/self/cyclic transaction-parameter
defaults, runtime signals, and expressions fail closed in this slice.
The first activation-binding lowering boundary is checked by
[t/1241-isf-transaction-port-bindings.t](../../t/1241-isf-transaction-port-bindings.t)
so `do`, `spawn`, and rule-trigger input bindings accept scalar signals,
numeric/exact-width literals, and non-empty list expressions where shipped,
are direction- and known-width-checked, keep actor inputs read-only, reject
actor output readback, produce hidden generated-top handoffs for spawned
bindings, avoid duplicate same-name child wiring for explicit spawn binding
sources, and use per-rule source signals before trigger fan-in.
Repeat-body spawn bindings are checked by
[t/1215-isf-spawn-parameter-binding.t](../../t/1215-isf-spawn-parameter-binding.t):
the shipped top-level repeat-body spawn plus same-body `await_all` subset may
also carry `(bind ...)` input and output handoffs on the same static generated
child instance used by top-level spawn.
The actor-pin binding conflict boundary is checked by
[t/1242-isf-port-binding-conflict-semantics.t](../../t/1242-isf-port-binding-conflict-semantics.t)
so spawned output bindings keep parent-transaction ownership in assignment
provenance, conflicting rule writes fail through the existing
rule/transaction conflict path, and accepted spawn or rule-trigger binding
fan-in reaches the backend's verification-only selector instrumentation.
The transaction-port binding schedule-report projection is checked by
[t/1243-isf-port-binding-schedule-report.t](../../t/1243-isf-port-binding-schedule-report.t)
so successful in-process and CLI reports expose bounded binding provenance
without exporting raw `LoweringIR` assignment internals.
The transaction wait boundary is checked by
[t/1244-isf-wait-clause-lowering.t](../../t/1244-isf-wait-clause-lowering.t)
so `(wait N)` accepts non-negative integer literals and actor constants in
transaction body contexts, accepts actor-local scalar parameter defaults as
static wait counts when they resolve to non-negative integer literals, and
accepts same-transaction scalar parameter defaults as static wait counts when
they resolve to non-negative integer literals, with transaction parameters
shadowing actor-level static names in this value-domain slot. It also
accepts qualified imported package scalar constants as static wait counts
when they resolve to non-negative integer literals. The package-count slice is
checked by
[t/1359-isf-wait-package-constant-counts.t](../../t/1359-isf-wait-package-constant-counts.t)
so accepted package counts keep the authored `PACKAGE.CONSTANT` token in
`transaction_waits[]`, lower positive resolved counts to reviewable fixed
wait-state chains, and treat resolved zero as a transparent no-op. The
runtime wait boundary accepts the known-width runtime scalar and runtime
expression count subsets including
consecutive top-level runtime waits and waits after shipped `await`, `stage`,
`repeat` exit, repeat-check loop-back into a leading repeat-body wait,
`await_all`, `await_any`, bank load/store, loop-decision predecessors, and
loop-control `(exit-when ...)` / `(continue-when ...)` false-edge predecessors,
reaches HDL generation, exposes `actor_constants[]` and
`actor_params[]` plus `transaction_waits[]` provenance, and rejects malformed,
unknown, unsupported parameter, unsupported package, unknown-width expression,
or unsupported dynamic counts.
Inline `when`, `repeat`, `switch`, `while`, and
`until` body dynamic waits are covered for the no-pending-sample subset,
including a runtime wait as the first repeat-body state. Branch and loop
decision states preserve their alternate exits while splitting the selected
dynamic-wait edge into positive-count load/entry and zero-count bypass paths.
Loop-control decisions likewise preserve their true exit/continue edge while
splitting only the false fallthrough edge to a following runtime wait.
Pending samples before top-level runtime waits are covered: the
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
[t/1308-isf-dynamic-divisor-safety.t](../../t/1308-isf-dynamic-divisor-safety.t)
so shipped runtime expression contexts reject numeric/exact-width
literal-zero, actor-constant-zero, actor-parameter-zero, and
same-transaction-parameter-zero division and modulo divisors before scheduled
`.fsm` emission while preserving nonzero literal divisors, nonzero
actor-constant divisors, nonzero actor-parameter divisors, nonzero
same-transaction-parameter divisors, and dynamic scalar divisors unchanged.
The transaction loop boundary is checked by
[t/1245-isf-transaction-loop-lowering.t](../../t/1245-isf-transaction-loop-lowering.t)
so top-level transaction `(while cond body...)` lowers as a pre-test
zero-or-more loop, `(until cond body...)` lowers as a body-first one-or-more
loop, conditions are sampled in generated decision states, successful reports
expose `transaction_loops[]`, and unsupported loop body combinations fail
closed. The multi-bit truthiness boundary is checked by
[t/1510-isf-multibit-loop-predicate-truthiness.t](../../t/1510-isf-multibit-loop-predicate-truthiness.t):
bare known-width loop conditions wider than one bit lower through an explicit
width-matched nonzero comparison at every decision, one-bit loop conditions
retain their existing compact selector, and schedule reports retain the
authored condition text.
The transaction-name boundary is checked by
[t/1185-isf-transaction-name-boundary.t](../../t/1185-isf-transaction-name-boundary.t)
so duplicate transaction names fail before actor-shell return and downstream
target-resolution code sees one unambiguous same-actor transaction namespace.
The actor-shell actor-name shape is checked by
[t/1164-isf-public-actor-shell-actor-name-shape-audit.t](../../t/1164-isf-public-actor-shell-actor-name-shape-audit.t)
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
resolved-child trigger-batch generated top is shipped for exactly two
resolved children, one same-cycle temporary trigger batch, source-ordered
waits to both triggered children, no static group declaration, and no ATL data
movement; it reuses the same multi-child generated-top child-key surface and
adds generated-top kind `resolved_children_trigger_batch_event_sequence` while
preserving public trigger, wait, association, and compatibility schedule
records. The first
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
[t/1165-isf-public-actor-shell-timing-shape-audit.t](../../t/1165-isf-public-actor-shell-timing-shape-audit.t)
to keep parser-returned `clock`, `reset`, and `watchdog` timing fields
discoverable as bounded current handoff metadata.
The default timing convention is checked by
[t/1331-isf-timing-conventions.t](../../t/1331-isf-timing-conventions.t)
to keep omitted legacy single-clock timing normalized to clock `clk`, async
active-low reset `rst_n`, and watchdog `65535`, and to keep positive
actor-constant, actor-scalar-parameter, and qualified package-scalar-constant
actor-level watchdog limits, plus same-transaction scalar-parameter top-level
await-local watchdog limits, resolved to the same numeric public shape as
literals.
Qualified imported package scalar constants in actor-level and await-local
watchdog limits are checked by
[t/1363-isf-watchdog-package-constant-limits.t](../../t/1363-isf-watchdog-package-constant-limits.t),
which keeps accepted package constants on the same resolved-integer public
shape while unsupported package forms fail closed.
The actor-shell rule shape is checked by
[t/1166-isf-public-actor-shell-rule-shape-audit.t](../../t/1166-isf-public-actor-shell-rule-shape-audit.t)
to keep parser-returned rule entries discoverable as unique non-empty scalar
`name`, optional `when`, and `actions` array shells while leaving rule payload
contents private scheduler input.
The rule-name boundary is checked by
[t/1186-isf-rule-name-boundary.t](../../t/1186-isf-rule-name-boundary.t)
so duplicate rule names fail before actor-shell return and generated rule DTs
plus rule-trigger source prefixes remain unambiguous.
The rule-action parser boundary is checked by
[t/1181-isf-rule-action-boundary.t](../../t/1181-isf-rule-action-boundary.t)
so accepted rule actions have explicit `(set port expr)`, `(port expr)`,
`(trigger transaction)`, or `(priority over other_rule)` shapes before a rule
enters the actor shell. Assignment RHS values may be scalar tokens or
non-empty list expressions with scalar expression heads.
The scalar setter syntax boundary is checked by
[t/1246-isf-setter-syntax.t](../../t/1246-isf-setter-syntax.t)
so `(set lhs expr)` is accepted in rule and transaction contexts, malformed
setter forms fail closed with targeted diagnostics, rule setters lower as
guarded flopped rule assignments, and transaction setters lower as ordered
flopped transaction states that reach HDL generation.
The rule-expression assignment lowering path is checked by
[t/1221-isf-rule-expression-assignment.t](../../t/1221-isf-rule-expression-assignment.t)
so expression-valued rule assignments preserve through scheduled `.fsm`
emission, assignment provenance, normal `.fsm` frontend parsing, and HDL
generation while keeping the existing flopped `<-` rule assignment family.
The expression-valued rule conflict/report path is checked by
[t/1222-isf-rule-expression-conflict-report.t](../../t/1222-isf-rule-expression-conflict-report.t)
so same-expression rule writes appear as compatible fan-in, different
expression writes fail closed through `isf_conflicting_rule_writes`, and
priority-resolved expression conflicts project through `priority_resolutions`.
The disjoint-rule write path is checked by
[t/1234-isf-disjoint-rule-writes.t](../../t/1234-isf-disjoint-rule-writes.t)
so same-target FIFO-style rule writes are accepted when direct contradictory
guard literals prove the rules cannot fire in the same cycle, while
overlapping expression guards still fail closed through
`isf_conflicting_rule_writes`.
The rule-trigger target boundary is checked by
[t/1182-isf-rule-trigger-target-boundary.t](../../t/1182-isf-rule-trigger-target-boundary.t)
so `(trigger transaction)` must name a declared transaction in the same actor.
Forward references are accepted because validation runs after the full actor
body is collected; missing targets fail before actor-shell return.
The rule-guard scheduled `.fsm` DTE-header shape is checked by
[t/1168-isf-rule-guard-factoring.t](../../t/1168-isf-rule-guard-factoring.t)
so rule actions remain grouped under one guarded non-state DT enable in review
artifacts.
The shorthand rule-guard parser/lowering path is checked by
[t/1169-isf-rule-shorthand-guard.t](../../t/1169-isf-rule-shorthand-guard.t)
to keep `(rule name condition actions...)` normalized to the same public
`when` field as `(rule name (when condition) actions...)`.
The rule-trigger fan-in path is checked by
[t/1171-isf-rule-trigger-fanin.t](../../t/1171-isf-rule-trigger-fanin.t)
so multiple rule triggers for one transaction preserve distinct trigger
sources before generated combinational fan-in.
The schedule-report projection of that same fan-in path is checked by
[t/1172-isf-rule-trigger-fanin-schedule-report.t](../../t/1172-isf-rule-trigger-fanin-schedule-report.t)
so downstream consumers can rely on the advertised DT kind/order and one-bit
inferred-storage summaries for the generated trigger sources.
The static rule-conflict path is checked by
[t/1209-isf-static-conflict-detection.t](../../t/1209-isf-static-conflict-detection.t)
so provable incompatible rule/rule data writes fail closed, compatible
same-value rule writes remain accepted, shared-caller rule/drive overlap is
flagged internally as `proof_status => not_doable`, and ordinary transaction
state mux behavior remains accepted.
The rule-priority conflict-resolution path is checked by
[t/1210-isf-priority-conflict-resolution.t](../../t/1210-isf-priority-conflict-resolution.t)
so rule-local and actor-level rule priorities can suppress lower-priority
same-target rule assignments, while priority cycles fail closed.
The verification-only runtime selector instrumentation path is checked by
[t/1211-isf-runtime-selector-conflict-instrumentation.t](../../t/1211-isf-runtime-selector-conflict-instrumentation.t)
so same-value source selector checks, whole-mux value selector checks, and the
Verilog no-assertion boundary remain regression-backed after ISF lowers through
scheduled `.fsm` into HDL.
The explicit-width `shift_right` data-operation path is checked by
[t/1173-isf-shift-right-explicit-width.t](../../t/1173-isf-shift-right-explicit-width.t)
so explicit `(width N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT)` fills otherwise missing register-width
evidence, known-width shifts do not need the option, conflicting explicit
widths fail closed, and accepted `shift_right` source no longer emits
placeholder `WIDTH` terms.
The explicit-width `shift_left` data-operation path is checked by
[t/1318-isf-shift-left-explicit-width.t](../../t/1318-isf-shift-left-explicit-width.t)
so optional `(width N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT)` fills missing
register-width evidence for later data operations and schedule-report storage
metadata, conflicting explicit widths fail closed, and ordinary widthless
`shift_left` source remains accepted.
The explicit-width `extract` data-operation path is checked by
[t/1174-isf-extract-explicit-widths.t](../../t/1174-isf-extract-explicit-widths.t)
so authors can avoid placeholder slice bounds when extract field widths are
not declared elsewhere.
Static data-operation width sources are checked by
[t/1343-isf-data-op-static-width-sources.t](../../t/1343-isf-data-op-static-width-sources.t),
so `shift_left`, `shift_right`, and `extract` explicit width evidence may use
positive integer literals, actor-local scalar parameter defaults, declared
actor constants, or qualified imported package scalar constants that resolve
to positive integers. Unsupported unrelated or cross-transaction parameters,
runtime interface signals, unknown names, unknown or unqualified package constants,
aggregate package constants, package member/item paths, ambiguous
local-enum/package-constant spellings, arbitrary expressions, zero values, and
aggregate values fail closed.
Transaction-parameter data-operation width evidence is checked
by
[t/1367-isf-data-op-transaction-param-widths.t](../../t/1367-isf-data-op-transaction-param-widths.t),
so same-transaction scalar parameter defaults on generated child and
direct/non-generated transactions may provide `shift_left`/`shift_right`
`(width TX_PARAM)` and `extract`/`assemble` `(widths TX_PARAM...)` evidence
when they resolve to positive integers. Aggregate/list parameter defaults,
zero-valued defaults, unrelated or cross-transaction parameters,
activation-site override specialization, and generated-top respecialization
remain fail-closed for this data-operation width surface.
Assemble static part widths are checked by
[t/1344-isf-assemble-static-part-widths.t](../../t/1344-isf-assemble-static-part-widths.t),
so `(assemble part... as target (widths N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT...))`
supplies ordered part-width evidence from the same accepted static source set
while preserving the emitted concat assignment shape.
The single-missing-field `extract` inference path is checked by
[t/1101-isf-extract-slices.t](../../t/1101-isf-extract-slices.t), so one
unknown destination field can derive its width from a known source word and
known sibling fields before later data operations consume that width evidence.
The temporal-contract lowering boundary is checked by
[ISF stages/contracts task evidence](../tasks/ISF-STAGES-CONTRACTS.md)
and [ISF stages/contracts task evidence](../tasks/ISF-STAGES-CONTRACTS.md);
qualified imported package scalar constants in contract windows are checked by
[package-constant contract-window task evidence](../tasks/ISF-CONTRACT-PACKAGE-CONSTANT-WINDOWS.md),
and same-transaction scalar parameter defaults on generated child
transactions are checked by
[transaction-parameter contract-window task evidence](../tasks/ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.md).
Same-transaction scalar parameter defaults on direct/non-generated
transactions are checked by
[direct transaction-parameter contract-window task evidence](../tasks/ISF-CONTRACT-DIRECT-TRANSACTION-PARAM-WINDOWS.md).
Activation-site same-value override acceptance and mismatch diagnostics for
generated child transaction parameters used by child contract windows are
checked by
[activation-override contract-window task evidence](../tasks/ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS.md).
Activation-site same-value override acceptance and mismatch diagnostics for
generated child transaction parameters used by static timing lowering are
checked by
[t/1369-isf-timing-param-activation-override-gates.t](../../t/1369-isf-timing-param-activation-override-gates.t).
Activation-site same-value override acceptance and mismatch diagnostics for
generated child transaction parameters used by data-operation widths
(`shift_left`, `shift_right`, `assemble`, `extract`) are checked by
[t/1370-isf-data-op-activation-override-width-gate.t](../../t/1370-isf-data-op-activation-override-width-gate.t).
Activation-site same-value override acceptance and mismatch diagnostics for
generated child transaction parameters used by transaction port widths
(`(ports (input/output NAME (width PARAM)))`) are checked by
[t/1371-isf-transaction-port-activation-override-width-gate.t](../../t/1371-isf-transaction-port-activation-override-width-gate.t).
The static-timing override gate emits four sub-axis-specific
diagnostics — `repeat-count parameter`, `wait-count parameter`,
`latency-bound parameter`, and `watchdog-limit parameter` — each
with its own deferral phrase (`... repeat counts remain deferred`,
`... wait counts remain deferred`, etc.). The sub-axis split is
checked by
[t/1373-isf-timing-param-sub-axis-diagnostic.t](../../t/1373-isf-timing-param-sub-axis-diagnostic.t).
Cross-domain repeat-body `do` rejection emits a targeted
`cross-domain repeat-body do remains deferred` diagnostic and is
checked by
[t/1372-isf-cross-domain-repeat-body-do-diagnostic.t](../../t/1372-isf-cross-domain-repeat-body-do-diagnostic.t).
A plain local `(do child)` and a same-domain generated `(do child (params ...))`
(with `(bind ...)`/`(domain NAME)` when static params are present) inside a
`(repeat ...)` directly in a single `(while ...)`/`(until ...)` body lower; a
generated `do` instantiates its child in the `_top` composition. The
accept-path schedules are checked by
[t/1379-isf-loop-contained-repeat-body-local-do.t](../../t/1379-isf-loop-contained-repeat-body-local-do.t)
and [t/1380-isf-loop-contained-repeat-body-generated-do.t](../../t/1380-isf-loop-contained-repeat-body-generated-do.t).
The basic `(spawn child as inst)` + same-body `(await_all done)` (or
single-pending `(await_any done)`) drain also lowers inside a loop-contained or
deeper-nested repeat (lowering + composition parity with the top-level
repeat-body spawn; the full-HDL composition-wiring limitation is pre-existing
and applies equally there). A multi-pending `(await_any done)` followed by a
later same-body `(await_all done)` drain is also supported in these contexts
(as at top-level / when-body / switch-branch). A `while`- or body-first
`until`-contained repeat may also keep one or more generated spawns pending
across one plain local `(do child)` when effect proofs establish the local child
drain, deterministic generated-child handoffs, clean repeat/loop backedges, and
a later exact same-body `await_all` drain; a post-`do` multi-pending
`await_any` observation is accepted only when that later exact drain follows.
These widened local-do fanout paths are checked by
[t/1432-isf-loop-pending-spawn-local-do-effect-widening.t](../../t/1432-isf-loop-pending-spawn-local-do-effect-widening.t),
[t/1433-isf-until-pending-spawn-local-do-effect-widening.t](../../t/1433-isf-until-pending-spawn-local-do-effect-widening.t),
and [t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t](../../t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t).
An undrained loop-contained
spawn emits `loop-contained repeat-body spawn requires same-body '(await_all
done)' or single-pending '(await_any done)'`. A parent-body sync after the
repeat exits is not a valid drain for repeat-body spawned children; it emits
`repeat-body spawn cannot be drained by parent-body '(await_all done)' after
the repeat exits; use same-body '(await_all done)' before the repeat check can
loop` (with the authored sync form in the message). A multi-pending
`(await_any done)` without a later `(await_all done)` emits
`loop-contained repeat-body multi-pending await_any requires later same-body
'(await_all done)' before the repeat check can loop` (top-level and
deeper-nested forms use their matching context prefixes), a loop-contained
cross-domain generated `do` emits `cross-domain repeat-body do remains
deferred`, and a repeat reached through an additional loop ancestor
emits `loop-contained repeat-body do remains deferred`; these are checked by
[t/1374-isf-loop-contained-repeat-body-activation-diagnostic.t](../../t/1374-isf-loop-contained-repeat-body-activation-diagnostic.t),
[t/1380-isf-loop-contained-repeat-body-generated-do.t](../../t/1380-isf-loop-contained-repeat-body-generated-do.t),
[t/1383-isf-loop-and-deeper-repeat-body-spawn.t](../../t/1383-isf-loop-and-deeper-repeat-body-spawn.t),
and [t/1384-isf-loop-and-deeper-repeat-body-multi-pending-awaitany.t](../../t/1384-isf-loop-and-deeper-repeat-body-multi-pending-awaitany.t).
A plain local `(do child)`, a same-domain generated `(do child (params ...))`,
and the basic spawn + drain subset at deeper branch nesting (`when⁺ → repeat`,
`switch → when⁺ → repeat`) also lower; a generated `do` instantiates its child
in the `_top` (checked by
[t/1381-isf-deeper-nested-repeat-body-local-do.t](../../t/1381-isf-deeper-nested-repeat-body-local-do.t),
[t/1382-isf-deeper-nested-repeat-body-generated-do.t](../../t/1382-isf-deeper-nested-repeat-body-generated-do.t),
and [t/1383-isf-loop-and-deeper-repeat-body-spawn.t](../../t/1383-isf-loop-and-deeper-repeat-body-spawn.t)).
A deeper-nested cross-domain generated `do` emits `cross-domain repeat-body do
remains deferred` and an undrained deeper-nested `spawn` emits `deeper-nested
repeat-body spawn requires same-body '(await_all done)' or single-pending
'(await_any done)'`, checked by
[t/1375-isf-deeper-nested-repeat-body-activation-diagnostic.t](../../t/1375-isf-deeper-nested-repeat-body-activation-diagnostic.t)
and [t/1383-isf-loop-and-deeper-repeat-body-spawn.t](../../t/1383-isf-loop-and-deeper-repeat-body-spawn.t).
Every `lisp`-tagged example in the ISF book chapters
(`12-cookbook.md`, `13*.md`, `14-feature-backlog.md`) is required
to parse and lower cleanly, enforced by
[t/1376-isf-book-example-lowering-audit.t](../../t/1376-isf-book-example-lowering-audit.t).
The shipped subset is the top-level transaction form
`(contract name (eventually signal within cycles))`. The older nested
`(contract name (eventually signal (within cycles)))` spelling remains an
accepted alias; both lower to one arm state plus an always-on monitor DT with
pending, age, and sticky-fail storage. The `cycles` token may be a positive
integer literal, a declared actor constant, an actor-local scalar parameter
default, a qualified imported package scalar constant, or a same-transaction
scalar parameter default on a generated child or direct/non-generated
transaction that resolves to a positive integer. Activation-site overrides on
`spawn`, generated blocking `do`, or rule `trigger` that target a generated
child parameter used by the child contract window are accepted only when the
override resolves to the same positive integer cycle count as the child
transaction parameter default. Mismatched overrides fail closed with a targeted
diagnostic; override specialization remains outside the contract-window
surface. Runtime signals, arbitrary expressions, unknown names, unknown or
unqualified package constants, aggregate package constants, package
member/item paths, ambiguous
local-enum/package-constant spellings, zero-valued constants, and zero-valued
or non-scalar actor/transaction parameters remain outside the
contract-window surface.
Schedule reports classify that DT as `temporal_contract_monitor` and classify
the generated pending/fail storage as registers and age storage as a counter.
Those three monitor storage entries also carry the advertised
`temporal_contract_monitor` `inferred_storage[].role`; the bounded
`temporal_contracts[]` summary remains the public place to distinguish the
pending, counter, and fail signal names.
The bounded `temporal_contracts` summary projection reports the public trigger,
observed signal, cycle bound, generated storage names, reset policy, overlap
policy, and assertion projection status for downstream consumers.
Actor-constant, actor-scalar-parameter, qualified package-scalar-constant,
generated-child transaction-parameter, and direct transaction-parameter
windows all lower as the resolved positive integer; no public source-token
field is added. Direct transaction parameters remain local lowering inputs and
are not promoted to actor-level `.fsm` `+params`. The public parent schedule
report remains parent-scoped for generated child contracts; the generated
child scheduled `.fsm` is the review artifact for child-local temporal
monitors.
Unsupported top-level bodies and nested contracts still fail closed with
targeted diagnostics. Verification-only assertion text is not advertised yet.
The parser boundary for resource and priority metadata is checked by
[t/1176-isf-resource-priority-boundary.t](../../t/1176-isf-resource-priority-boundary.t)
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
[t/1218-isf-rule-slot-resource-arbitration.t](../../t/1218-isf-rule-slot-resource-arbitration.t)
for parser metadata, `rule_slot`, `output_bundle`, `transaction_start`, and
`storage_port` scheduled `.fsm` DTE gating, bounded `rule_slot`/`round_robin`,
`output_bundle`/`round_robin`, `transaction_start`/`round_robin`, and
`storage_port`/`round_robin` grant gating and pointer state, output-bundle
output/storage member-list coverage,
transaction-start trigger-user validation, storage-port storage-member
validation, HDL handoff, and fail-closed unsupported arbitration cases.
The first rule/transaction priority path is checked by
[t/1219-isf-rule-transaction-priority.t](../../t/1219-isf-rule-transaction-priority.t)
for accepted rule-over-transaction suppression, accepted transaction-over-rule
suppression through scheduled `.fsm` state-active guards, unordered conflict
rejection, and cycle rejection.
The named-drive rule/transaction priority path is checked by
[t/1542-isf-rule-transaction-named-drive-priority-readiness.t](../../t/1542-isf-rule-transaction-named-drive-priority-readiness.t)
for exact-one-local-caller ownership, target-local suppression in both priority
directions, non-conflicting-output survival, same-value compatibility,
unordered/cycle/ambiguous fail-closed behavior, unchanged public report key
sets, assertion-enabled SystemVerilog execution, native Verilog execution, and
the separately tracked direct-VHDL reduction-expression boundary.
The arbitration schedule-report projection is checked by
[t/1220-isf-arbitration-schedule-report.t](../../t/1220-isf-arbitration-schedule-report.t)
for bounded successful `priority_resolutions` and `resource_arbitration`
entries across the in-process scheduler and CLI JSON path.
The rule-local priority target boundary is checked by
[t/1190-isf-rule-priority-target-boundary.t](../../t/1190-isf-rule-priority-target-boundary.t)
so `other_rule` in `(priority over other_rule)` must resolve to a declared
same-actor rule before actor-shell return. Forward references remain accepted.
The actor-level priority target boundary is checked by
[t/1191-isf-actor-priority-target-boundary.t](../../t/1191-isf-actor-priority-target-boundary.t)
so both sides of `(priority lhs over rhs)` must resolve to declared same-actor
transactions or rules before actor-shell return. Forward references remain
accepted.
The singleton actor-clause boundary is checked by
[t/1192-isf-singleton-actor-clause-boundary.t](../../t/1192-isf-singleton-actor-clause-boundary.t)
so `(clock ...)`, `(reset ...)`, `(watchdog ...)`, `(interface ...)`, and
`(resources ...)`, and `(storage ...)` fail closed when repeated instead of
letting later clauses overwrite earlier public actor-shell fields.
The blocking `do` child-completion handoff is checked by
[t/1177-isf-do-child-done-pulse.t](../../t/1177-isf-do-child-done-pulse.t)
so the generated internal `child_done` signal remains a one-cycle delayed pulse
through scheduled `.fsm` parsing and HDL generation.
The child transaction target boundary is checked by
[t/1184-isf-child-transaction-target-boundary.t](../../t/1184-isf-child-transaction-target-boundary.t)
so `(do child ...)` and `(spawn child as instance ...)` must resolve `child`
to a declared same-actor transaction before scheduled `.fsm` emission, while
forward references remain accepted. Parameterized/generated `do` uses a
generated child activation instance; local unparameterized `do` keeps the
rewired child-completion pulse path.
The deprecated handshake compatibility boundary is checked by
[t/1178-isf-handshake-compatibility-boundary.t](../../t/1178-isf-handshake-compatibility-boundary.t)
so `(handshake name (valid signal) (ready signal))` metadata requires exactly
one scalar `valid` and one scalar `ready`, rejects duplicate handshake names,
and remains ignored after validation. Old handshake semantics are still not
lowered.
The phase/stage boundary is checked by
[t/1179-isf-phase-stage-boundary.t](../../t/1179-isf-phase-stage-boundary.t)
so actor-level phase/stage metadata and transaction phase/stage clauses have
scalar names plus list-form body entries before an actor shell is returned.
Transaction `(phase ...)` remains a pass-through state marker; transaction
`(stage name (ready ready_signal) (valid valid_signal))` has its first
bounded lowering path checked by
[t/1223-isf-stage-lowering.t](../../t/1223-isf-stage-lowering.t): it emits one
ready-gated state that drives `valid_signal = 1` while active, parses through
the normal `.fsm` frontend, and reaches SystemVerilog generation. The older
`(stage name (input ready_signal) (output valid_signal))` spelling remains an
accepted alias for the same public schedule-report projection. The generated
valid drive remains a transaction assignment, so the existing same-target
conflict diagnostics still apply when another owner writes that signal.
Actor-level phase/stage metadata is also checked by
[t/1252-isf-actor-phase-stage-report.t](../../t/1252-isf-actor-phase-stage-report.t):
it is copied into `LoweringIR` only for bounded `actor_phases[]` and
`actor_stages[]` schedule-report projection, and it still does not create
generated `.fsm`, generated composition-top, or HDL runtime behavior.
Actor-level passive observation metadata is checked by
[t/1260-isf-verification-observation-metadata.t](../../t/1260-isf-verification-observation-metadata.t):
`(observe NAME (role passive_monitor) (signals SIG...))` is copied into
`LoweringIR` only for bounded `verification_observations[]` schedule-report
projection, with source-ordered public interface signal summaries and no
generated `.fsm`, generated composition-top, HDL, UVM, VHDL, scoreboard,
coverage, or VIP behavior.
The unsupported transaction-clause boundary is checked by
[t/1180-isf-unsupported-transaction-clause-boundary.t](../../t/1180-isf-unsupported-transaction-clause-boundary.t)
so removed or future transaction clause heads, including `(assign ...)`, fail
closed instead of disappearing from scheduled `.fsm` output. Removed
`(assign ...)` has targeted migration guidance, while unknown future keywords
keep the generic unsupported-clause diagnostic. The nested `when`, `switch`,
and `repeat` body contexts use the same shipped-lowerer boundary, while
unsupported `contract` clauses and deferred nested/unsupported `stage` forms
keep their dedicated diagnostics. The shipped top-level
bounded-eventual `contract` subset is covered separately by
[ISF stages/contracts task evidence](../tasks/ISF-STAGES-CONTRACTS.md).
The actor-shell drive shape is checked by
[t/1167-isf-public-actor-shell-drive-shape-audit.t](../../t/1167-isf-public-actor-shell-drive-shape-audit.t)
to keep parser-returned drive definitions discoverable as a unique
drive-name-keyed hash of `params` and `body` arrays with body entries
validated as scalar `(port value)` pairs while leaving richer drive semantics
private scheduler input.
The drive-name boundary is checked by
[t/1187-isf-drive-name-boundary.t](../../t/1187-isf-drive-name-boundary.t)
so duplicate drive definitions fail before actor-shell return instead of
silently overwriting an earlier drive body in the parser handoff.
The drive-body boundary is checked by
[t/1194-isf-drive-body-boundary.t](../../t/1194-isf-drive-body-boundary.t)
so malformed body entries fail before actor-shell return instead of being
skipped during drive-DT construction or stringified as unsupported payloads.
The drive-call arity boundary is checked by
[t/1193-isf-drive-call-arity-boundary.t](../../t/1193-isf-drive-call-arity-boundary.t)
so known drive calls require exactly one actual value per declared formal
parameter. Missing actuals and extra actuals fail during lowering instead of
emitting unbound parameter signals or ignoring author-provided values.
The sample-clause boundary is checked by
[t/1195-isf-sample-clause-boundary.t](../../t/1195-isf-sample-clause-boundary.t)
so standalone samples and `(on ...)` inline samples must use exactly
`(sample port as name)` with scalar names. Unsupported `(on ...)` body forms
fail closed instead of being ignored. Direct `(on ...)` activation is not a
parameter-override site; `(on start (params ...))` stays outside the public
syntax and must fail closed with a diagnostic that says direct `(on ...)`
activation is an entry guard, not a generated activation-site parameter
override.
The complete-clause boundary is checked by
[t/1196-isf-complete-clause-boundary.t](../../t/1196-isf-complete-clause-boundary.t)
so `(complete port)` must name exactly one scalar completion target before
scheduled `.fsm` emission.
The latency-clause boundary is checked by
[t/1197-isf-latency-clause-boundary.t](../../t/1197-isf-latency-clause-boundary.t)
and
[t/1361-isf-latency-package-constant-bounds.t](../../t/1361-isf-latency-package-constant-bounds.t)
so `(latency ...)` accepts positive-integer literal, declared positive
actor-constant, actor-local scalar-parameter, same-transaction scalar
parameter, or qualified imported package scalar-constant `(min N)` and
`(max N)` options, rejects duplicates, requires `min <= max` when both are
present, rejects runtime interface signals, unknown symbols, unknown or
unqualified package constants, aggregate package constants, package
member/item paths, arbitrary expressions, zero-valued constants, zero-valued
or non-scalar actor/transaction parameters, and cross-transaction parameters,
and uses valid explicit `max` bounds for the generated counter width/max
check. Transaction-parameter, actor-constant, actor-scalar-parameter, and
package scalar constant latency bounds resolve to the same generated `.fsm` and
schedule-report storage shape as the equivalent literal; there is no separate
latency-bound source-token report field.
Generated child activation overrides for latency-bound transaction parameters
are accepted only when they resolve to the same positive integer as the child
default; mismatches fail closed until per-activation latency counter
specialization is shipped.
The update-clause boundary is checked by
[t/1198-isf-update-clause-boundary.t](../../t/1198-isf-update-clause-boundary.t)
so `(update var expr)` has exactly one scalar target and one scalar or list
expression payload, and nested expression payloads are formatted as `.fsm`
expressions instead of Perl reference strings.
The shift-clause boundary is checked by
[t/1199-isf-shift-clause-boundary.t](../../t/1199-isf-shift-clause-boundary.t)
so `(shift_left reg bit [(width N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT)])` and
`(shift_right reg bit [(width N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT)])` require
scalar register/bit operands before scheduled `.fsm` emission.
The assemble-clause boundary is checked by
[t/1200-isf-assemble-clause-boundary.t](../../t/1200-isf-assemble-clause-boundary.t)
so `(assemble part... as target [(widths N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT...)])`
requires one or more scalar parts, one scalar target, and any optional
trailing width list to match the part count before scheduled `.fsm` emission.
The same regression
covers the width-evidence boundary: explicit widths derive target evidence for
later data operations, known part-width sums must match any already-known
target width, and when exactly one part width is missing, a known target width
and known sibling part widths infer that missing width as a positive
remainder. Multiple unknown parts remain non-evidence concat operands unless
explicit widths make them known.
The extract-clause boundary is checked by
[t/1201-isf-extract-clause-boundary.t](../../t/1201-isf-extract-clause-boundary.t)
so `(extract word as field... [(widths N|TX_PARAM|PARAM|CONST|PACKAGE.CONSTANT...)])` requires one
scalar source word, one or more scalar fields, and at most one ordered
positive static-width `(widths ...)` option before scheduled `.fsm` emission.
The exact-slice extraction behavior is checked by
[t/1101-isf-extract-slices.t](../../t/1101-isf-extract-slices.t), so accepted
`extract` source emits concrete descending slices, infers exactly one missing
field width from known source and sibling widths, and fails closed for multiple
unknown field widths, non-positive inferred remainders, or known source/field
width disagreement instead of emitting placeholder slice bounds.
The repeat-clause boundary is checked by
[t/1202-isf-repeat-clause-boundary.t](../../t/1202-isf-repeat-clause-boundary.t)
so `(repeat count body...)` requires one scalar non-empty count and at least
one list-form body clause before repeat counter emission.
Repeat counter width inference is checked by
[t/1102-isf-repeat-counter-widths.t](../../t/1102-isf-repeat-counter-widths.t),
so positive decimal literal counts use the minimum width for the loaded count,
positive actor constants, actor scalar parameter defaults, and qualified
imported package scalar constants use their resolved integer value as width
evidence while preserving the authored load token, same-transaction scalar
parameter defaults use their resolved positive integer as width evidence and
scheduled `.fsm` load value, and sampled/runtime names continue to use known
source width. Static zero counts from literal zero, actor constants, actor
scalar parameters, same-transaction scalar parameters, or package scalar
constants lower as transparent no-op regions with no counter, repeat
init/check state, repeat-body state, or `transaction_loops[]` entry when the
body does not contain child activation, and the same no-artifact rule applies
to plain `(do child)` and plain `(spawn child as inst)` clauses inside
statically zero repeat bodies when the target transaction is not otherwise
live. Package-constant repeat counts are
checked by
[t/1360-isf-repeat-package-constant-counts.t](../../t/1360-isf-repeat-package-constant-counts.t).
The repeat boundary test also checks that static-zero child activations emit
no generated child `.fsm`, generated top, activation instance, local handoff,
or loop report entry, while preserving target transactions that are
explicitly actor-input guarded. Syntactically valid parameterized, bound, or
domain-annotated static-zero child activation subclauses are pruned as dead
payloads after shape validation; malformed activation subclause syntax still
fails closed before scheduled emission.
Generated child activation overrides for repeat-count transaction parameters
are accepted only when they resolve to the same positive integer as the child
default; mismatches fail closed until per-activation repeat counter
specialization is shipped.
Known-width runtime scalar repeat counts now split the repeat init edge:
nonzero values enter the repeat body, while zero values bypass the body and
repeat check to the state after the repeat region. Unknown names, non-scalar
actor parameters, non-scalar transaction parameters, cross-transaction
parameters, unqualified package constants, aggregate package constants,
package member/item paths, malformed scalar tokens, package constants inside
repeat-count expressions, and expression-valued counts fail closed before
scheduled `.fsm` emission.
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
branch nesting remains outside both nested subsets. A plain local `(do child)`,
a same-domain generated `(do child (params ...))`, and the basic `(spawn ...)` +
same-body `(await_all done)`/single-pending `(await_any done)` drain inside a
`(repeat ...)` directly in a single `(while ...)`/`(until ...)` body (and at
deeper branch nesting) are their own shipped subsets (a generated `do`
instantiates its child in the `_top`); undrained spawn, multi-pending
`(await_any done)`, and cross-domain generated `do` stay deferred. Generated
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
with the same later same-body `await_all` drain requirement. When no
multi-pending `await_any` observation is active before the drain, those same
static-parameter generated-do subsets may also start one or more later
generated nested spawns before the mandatory same-body `await_all`; the
generated do instance's fresh done handoff gates the later spawn state and
the final drain covers both pre-do and post-do generated spawns. Those static-
parameter prior-observation do-then-spawn subsets may also run a second
post-spawn multi-pending `await_any` before the final same-body `await_all`;
both observations leave the outstanding generated-spawn done set live for the
final drain. The documented
top-level `when` body nested subset additionally supports static-parameter
generated `(do child (params ...) (bind ...))` after a prior multi-pending
`await_any`, with generated-top input/output binding handoffs and the same
later same-body `await_all` drain requirement; the documented top-level
`switch` branch nested subset now supports the same bound generated-do
after-`await_any` contract. Those same bound generated-do subsets may also
start one or more later generated nested spawns before the mandatory
same-body `await_all`, either when no multi-pending `await_any` observation is
active before the later spawn or after the generated do follows a prior
multi-pending observation; the generated do instance's fresh done handoff
gates the later spawn state and generated-top binding handoffs stay scoped to
the do instance. In the prior-observation form, a second post-spawn
multi-pending `await_any` may run before the mandatory final `await_all`
drain; both observations leave the pre-do and post-do generated-spawn done
set live for that final drain. The documented top-level `when` body and
top-level `switch` branch nested subsets additionally support static-
parameter same-domain generated
`(do child (params ...) [(bind ...)] (domain NAME))` after a prior
multi-pending `await_any`, with declared ownership metadata and the same later
same-body `await_all` drain requirement. Those same-domain generated-do
subsets may also start one or more later generated nested spawns before the
mandatory same-body `await_all`, either when no multi-pending `await_any`
observation is active before the later spawn or after the generated do
follows a prior multi-pending observation; the generated do instance's fresh
done handoff gates the later spawn state and declared ownership metadata
remains scoped to the generated do instance. In the prior-observation form, a
second post-spawn multi-pending `await_any` may run before the mandatory
final `await_all` drain; both observations leave the pre-do and post-do
generated-spawn done set live for that final drain, and declared ownership
metadata stays scoped to the generated do instance. Plain
generated-child, static-parameter, bound, same-domain, and local-do
do-then-spawn subsets may also run a post-spawn multi-pending `await_any`
observation before the mandatory same-body `await_all` drain, provided no
prior multi-pending `await_any` observation is active before the later spawn;
the final drain still covers both pre-do and post-do generated spawns.
Local-do do-then-spawn subsets may also run that second post-spawn
multi-pending `await_any` after the local `do` follows a prior multi-pending
`await_any` observation, provided the final same-body `await_all` drains the
same outstanding generated-spawn set. Plain generated-child do-then-spawn
subsets may also run that second post-spawn multi-pending `await_any` after
the generated-child `do` follows a prior multi-pending `await_any`
observation, provided the generated do instance completes before the later
spawn and the final same-body `await_all` drains the same outstanding
generated-spawn set. Static-parameter generated-do do-then-spawn subsets may
also start the later spawn after the generated do follows a prior
multi-pending `await_any` observation, may run a second post-spawn
multi-pending `await_any`, and still require the final same-body `await_all`
to drain the same outstanding generated-spawn set. Bound generated-do
do-then-spawn subsets support the same prior-observation repeated-`await_any`
path, including the final same-body `await_all` drain. Same-domain
generated-do do-then-spawn subsets support that same prior-observation
repeated-`await_any` path while preserving declared ownership metadata on
the generated do instance; both observations leave the pre-do and post-do
generated-spawn done set live for the final same-body `await_all` drain.
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
`await_all` drain. Those same branch-contained local-do forms may then start
one or more additional generated nested spawns before the mandatory same-body
`await_all`, either with no active multi-pending `await_any` before the later
spawn or after the local `do` follows a prior multi-pending observation; the
local child's fresh done pulse must be observed first, and the later drain
covers both pre-do and post-do generated spawns. In the prior-observation
form, that local-do do-then-spawn path may also run a second post-spawn
multi-pending `await_any` observation before the mandatory same-body
`await_all` drain; both observations leave the outstanding generated-spawn
done set live for the final drain. In the top-level `when` body and
top-level `switch` branch subsets, that local-do do-then-spawn shape may also
run a post-spawn multi-pending `await_any` observation before the mandatory
same-body `await_all` drain when no prior multi-pending `await_any`
observation is active before the later generated spawn. The observation
leaves both pre-do and post-do generated-spawn done handoffs live for the
final drain. In the
top-level `when` body and top-level `switch` branch subsets, local plain
`(do child)` may also run before a post-do multi-pending
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
later same-body `await_all` drain contract. Those static-parameter
generated-do subsets may also start one or more later generated spawns, run a
post-spawn multi-pending `await_any` observation, and then use the mandatory
same-body `await_all` drain when no prior multi-pending `await_any`
observation is active before the later spawn. The top-level `when` body subset
also supports static-parameter bound generated
`(do child (params ...) (bind ...))` before post-do `await_any`, wiring the
generated-top input/output binding handoffs for that generated do instance
while preserving the same later-drain contract. The top-level `switch` branch
subset supports the same static-parameter bound generated-do post-do
`await_any` observation and later-drain contract. Those same bound
generated-do subsets may also start one or more later generated spawns, run a
post-spawn multi-pending `await_any` observation, and then use the mandatory
same-body `await_all` drain when no prior multi-pending `await_any`
observation is active before the later spawn; generated-top binding handoffs
stay scoped to the generated do instance. The top-level `when` body and
top-level `switch` branch same-domain generated
`(do child (params ...) [(bind ...)] (domain NAME))` subsets support the same
post-do `await_any` observation and later-drain contract while retaining
declared ownership metadata in generated-composition, domain-partition, and
schedule-report clock-domain summaries. Those same-domain generated-do
subsets may also start one or more later generated spawns, run a post-spawn
multi-pending `await_any` observation, and then use the mandatory same-body
`await_all` drain when no prior multi-pending `await_any` observation is
active before the later spawn; declared ownership metadata remains scoped to
the generated do instance. Those same same-domain generated-do subsets may
also run that second post-spawn multi-pending `await_any` observation after
the same-domain generated do follows a prior multi-pending `await_any`
observation, provided the mandatory same-body `await_all` still drains the
outstanding generated-spawn set and declared ownership metadata remains
scoped to the generated do instance.
In the documented top-level `when` body and top-level `switch` branch nested
subsets, plain generated-child `(do child)` may also run while generated
nested spawns are pending. In the top-level `when` body and top-level
`switch` branch subsets, that plain generated-child do may also run after a
prior multi-pending `await_any` observation. The generated do uses only its
deterministic generated do instance's start/done handoff and leaves the
generated-spawn done set live until the later same-body `await_all` drain.
That plain generated-child do may also be followed by one or more additional
generated nested spawns before the mandatory same-body `await_all`, either
with no active multi-pending `await_any` before the later spawn or after the
generated-child `do` follows a prior multi-pending observation; the generated
do instance's fresh done handoff gates the later spawn state. In the
prior-observation form, those branch-contained plain generated-child paths
may also run a second post-spawn multi-pending `await_any` observation before
the mandatory same-body `await_all` drain. Both observations leave the
outstanding generated-spawn done set live for that final drain. In
the documented top-level `when` body and top-level `switch` branch nested subsets,
static-parameter generated `(do child (params ...))` may also run while
generated nested spawns are pending. In both top-level branch-contained
subsets, that static-parameter generated do may also run after a prior multi-
pending `await_any` observation. The generated do uses its deterministic
generated do instance, preserves static generated-top parameter binding, and
leaves the generated spawn done set live until the later same-body
`await_all` drain. When no multi-pending `await_any` observation is active
before the drain, that static-parameter generated do may also be followed by
one or more later generated nested spawns before the mandatory same-body
`await_all`; the generated do instance's fresh done handoff gates the later
spawn state and the final drain covers both pre-do and post-do generated
spawns. In the documented top-level `when` body and top-level
`switch` branch nested subsets, static-parameter generated
`(do child (params ...) (bind ...))` may also run while generated nested spawns
are pending. The generated do wires generated-top input/output binding
handoffs once, waits for its own fresh done handoff, and leaves the generated
spawn done set live until the later same-body `await_all` drain. In the top-
level `when` body and top-level `switch` branch subsets, that bound generated
do may also run after a prior multi-pending `await_any` observation. When no
multi-pending `await_any` observation is active before the drain, that bound
generated do may also be followed by one or more later generated nested
spawns before the mandatory same-body `await_all`; the generated do
instance's fresh done handoff gates the later spawn state while generated-top
binding handoffs remain scoped to the do instance.
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
nested repeat re-entry. That same-domain generated do may also be followed by
one or more later generated nested spawns before the mandatory same-body
`await_all`, either when no multi-pending `await_any` observation is active
before the later spawn or after the generated do follows a prior multi-pending
observation; declared ownership metadata remains scoped to the generated do
instance. Later `await_any` after a post-do spawn remains public for local do,
generated-child do, static-parameter generated do, bound generated do, and
same-domain generated do with or without a prior multi-pending observation.
The count is a runtime counter load value, not a hardware-elaboration count:
literal counts provide fixed loop bounds, while named scalar counts may be
dynamic when their width is known. Dynamic counts make latency data-dependent
and require explicit zero-count and verification-bound policy before the
repeat surface is widened further.
The await-sync clause boundary is checked by
[t/1203-isf-await-sync-clause-boundary.t](../../t/1203-isf-await-sync-clause-boundary.t)
so `(await_all done_port)` and `(await_any done_port)` require exactly one
scalar done-port operand before sync-state emission.
The child-composition clause boundary is checked by
[t/1204-isf-child-composition-clause-boundary.t](../../t/1204-isf-child-composition-clause-boundary.t)
so `(do transaction [(domain NAME)] [(params (NAME value) ...)] [(bind ...)])` and
`(spawn transaction as instance [(domain NAME)] [(params (NAME value) ...)] [(bind ...)])`
require exact scalar child/instance operands before child-target resolution or
generated-child collection.
Spawn and blocking `do` parameter binding are checked by
[t/1215-isf-spawn-parameter-binding.t](../../t/1215-isf-spawn-parameter-binding.t).
Rule-trigger parameter binding is checked by
[t/1248-isf-rule-trigger-parameter-binding.t](../../t/1248-isf-rule-trigger-parameter-binding.t).
Actor constants and actor-local scalar parameter defaults as activation
parameter override values are checked by
[t/1249-isf-activation-parameter-constants.t](../../t/1249-isf-activation-parameter-constants.t).
Generated composition-top wiring for generated child activations is checked by
[t/1216-isf-generated-composition-top.t](../../t/1216-isf-generated-composition-top.t).
The shipped surface preserves validated per-instance spawn and generated `do`
overrides plus parameterized rule-trigger overrides in lowerer metadata, emits
child transaction defaults into generated child scheduled `.fsm` `+params`
blocks, resolves actor-local constants, actor-local scalar parameter defaults,
and scalar enum members in activation parameter override values and matching
leaves inside activation aggregate/list override values, rejects duplicate
instances, duplicate parameters, unknown overrides, unsupported runtime or
expression values, non-scalar actor parameters, aggregate shape mismatches,
and rejects parameter declarations on non-generated transactions without a
supported same-transaction static use.
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
An actor-local `(enums (NAME ...))` declaration establishes only the enum
member-value family `NAME`; it does **not** also establish a scalar type
alias named `NAME`. Using `(type NAME)` on a width-bearing interface port,
transaction port, or storage variable when only `(enums (NAME ...))` is
declared fails closed as an unknown type alias. To make an enum name usable
as a width-bearing type, co-declare a backing `(types (type NAME (bits k)))`
alongside `(enums (NAME ...))`. Co-declaring the same `NAME` in both
`(types ...)` and `(enums ...)` is accepted — they occupy distinct
declaration roles (the `(type)` carries the scalar width alias; the
`(enums)` carries the member values) and the co-declaration is not a
redeclaration conflict. The backing `(bits k)` width is the author's
assertion and is not cross-validated against enum member magnitudes;
downstream emitters that recover dense `0..N-1` enums should choose
`k = ceil(log2(member_count))`. Actor-local `(types ...)`, `(enums ...)`,
and `(constants ...)` declarations need not be referenced to be
contract-valid; unreferenced declarations lower cleanly and are preserved
in the corresponding scheduled `.fsm` review sections.
Declared actor constants are public as scalar actor parameter defaults or
scalar leaves inside actor aggregate/list parameter defaults. Those defaults
preserve authored constant tokens in scheduled `.fsm` `+params` and
`actor_params[]` while carrying resolved literals internally for scalar
parameter consumers.
Qualified imported package scalar constants are public as scalar actor
parameter defaults or scalar leaves inside actor aggregate/list parameter
defaults when the package is imported, the named package `+constants` entry
exists, and that package constant is a scalar numeric or exact-width literal.
Those defaults preserve the authored `PACKAGE.CONSTANT` token in scheduled
`.fsm` `+params` and `actor_params[]` while carrying resolved literals
internally for scalar parameter consumers. Unqualified imported package
constants, aggregate package constants, package constant member/item paths, and
ambiguous local-enum/package-constant spellings remain fail-closed.
Qualified imported package scalar constants are also public as generated
activation parameter override scalar values or scalar leaves inside compatible
aggregate/list override values. Those overrides resolve to literal generated-top
bindings and generated-composition report values; authored package-constant
tokens are not published in activation override bindings.
Qualified imported package scalar constants are also public as explicit
data-operation width evidence for `shift_left`, `shift_right`, `assemble`,
and `extract` when they resolve to positive integers. Those width evidence
tokens resolve inside scheduler publication and appear as concrete scheduled
`.fsm` shift positions, assemble/extract width facts, and
`inferred_storage[]` report widths; unsupported package shapes fail closed.
Same-transaction scalar parameter defaults on generated child and
direct/non-generated transactions are public as explicit data-operation width
evidence for `shift_left`, `shift_right`, `assemble`, and `extract` when they
resolve to positive integers. Those width facts use the transaction
definition default; activation-site override-specialized data widths remain
fail-closed.
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
[t/1257-isf-scalar-type-aliases.t](../../t/1257-isf-scalar-type-aliases.t),
covering actor-local aliases, package aliases, typed `+size` review artifacts,
embedded package roots, CLI HDL generation, declaration-only enum preservation,
and fail-closed diagnostics.
Actor-constant enum member references are checked by
[t/1258-isf-enum-member-constants.t](../../t/1258-isf-enum-member-constants.t),
covering local and package enum members, authored `+constants` review
artifacts, schedule-report value preservation, CLI HDL generation, and
fail-closed diagnostics.
Direct transaction `set` RHS enum member values are checked by
[t/1263-isf-enum-member-set-values.t](../../t/1263-isf-enum-member-set-values.t),
covering local and package enum members, scheduled `.fsm` review artifacts,
CLI HDL generation, and fail-closed diagnostics for unknown members and
deferred operator and target contexts.
Transaction `set` RHS enum member expression operands are checked by
[t/1264-isf-enum-member-set-expression-values.t](../../t/1264-isf-enum-member-set-expression-values.t),
covering local and package enum member operands, scheduled `.fsm` review
artifacts, CLI HDL generation, and fail-closed diagnostics for unknown members
and expression operator position.
Transaction `switch` branch enum values are checked by
[t/1265-isf-enum-member-switch-branch-values.t](../../t/1265-isf-enum-member-switch-branch-values.t),
covering local and package enum member branch values, scheduled `.fsm` review
artifacts, CLI HDL generation, and fail-closed diagnostics for unknown members
and non-switch contexts.
Transaction `switch` selector enum values are checked by
[t/1295-isf-enum-member-switch-selector-values.t](../../t/1295-isf-enum-member-switch-selector-values.t),
covering local and package enum member selectors, computed `.fsm` selector
review artifacts, CLI HDL generation, and fail-closed diagnostics for unknown
members and non-switch contexts.
Scalar drive body RHS enum member values are checked by
[t/1266-isf-enum-member-drive-values.t](../../t/1266-isf-enum-member-drive-values.t),
covering local and package enum member drive RHS values, scheduled `.fsm`
review artifacts, CLI HDL generation, and fail-closed diagnostics for unknown
members and deferred drive target and rule contexts.
Drive body RHS expression enum member operands are checked by
[t/1282-isf-enum-member-drive-expression-values.t](../../t/1282-isf-enum-member-drive-expression-values.t),
covering local and package enum member operands inside named drive body RHS
expressions, scheduled `.fsm` drive-DT review artifacts, CLI HDL generation,
recursive drive-parameter substitution in body expressions, and fail-closed
diagnostics for unknown members and expression operator position.
Named drive-call scalar actual enum member values are checked by
[t/1267-isf-enum-member-drive-call-values.t](../../t/1267-isf-enum-member-drive-call-values.t),
covering local and package enum member drive-call actuals, scheduled `.fsm`
review artifacts, CLI HDL generation, and fail-closed diagnostics for unknown
members.
Drive-call actual expression enum member operands are checked by
[t/1268-isf-enum-member-drive-call-expression-values.t](../../t/1268-isf-enum-member-drive-call-expression-values.t),
covering local and package enum member drive-call expression operands,
scheduled `.fsm` review artifacts, CLI HDL generation, and fail-closed
diagnostics for unknown members and expression operator position.
Inline drive assignment RHS enum member values are checked by
[t/1279-isf-enum-member-inline-drive-values.t](../../t/1279-isf-enum-member-inline-drive-values.t),
covering local and package enum member inline-drive RHS values, scheduled
`.fsm` review artifacts, CLI HDL generation, and fail-closed diagnostics for
unknown members and inline drive targets.
Inline drive RHS expression enum member operands are checked by
[t/1280-isf-enum-member-inline-drive-expression-values.t](../../t/1280-isf-enum-member-inline-drive-expression-values.t),
covering local and package enum member inline-drive RHS expression operands,
scheduled `.fsm` review artifacts, CLI HDL generation, and fail-closed
diagnostics for unknown members and expression operator position.
Actor scalar parameter default enum member values are checked by
[t/1269-isf-enum-member-actor-params.t](../../t/1269-isf-enum-member-actor-params.t),
covering local and package enum member actor parameter defaults, scheduled
`.fsm` `+params` review artifacts, schedule-report value preservation, CLI HDL
generation, and fail-closed diagnostics for unknown members and other
non-shipped contexts.
Actor aggregate/list parameter default enum member leaves are checked by
[t/1277-isf-enum-member-actor-aggregate-params.t](../../t/1277-isf-enum-member-actor-aggregate-params.t),
covering local and package enum member leaves in actor aggregate/list parameter
defaults, scheduled `.fsm` `+params` review artifacts, `actor_params[]`
schedule-report preservation, strict CLI HDL generation, and fail-closed
diagnostics for unknown leaves.
Actor-constant-backed actor parameter defaults are checked by
[t/1345-isf-actor-param-actor-constants.t](../../t/1345-isf-actor-param-actor-constants.t),
covering scalar defaults, aggregate/list leaves, resolved width consumption,
scheduled `.fsm` `+params` review artifacts, `actor_params[]` preservation,
strict CLI HDL generation, and fail-closed diagnostics for unknown symbols,
forward actor-parameter dependencies, transaction parameters, and runtime
signals.
Actor-parameter-backed actor parameter defaults are checked by
[t/1346-isf-actor-param-actor-params.t](../../t/1346-isf-actor-param-actor-params.t),
covering earlier scalar actor parameter defaults, aggregate/list leaves,
resolved width consumption, scheduled `.fsm` `+params` review artifacts,
`actor_params[]` preservation, strict CLI HDL generation, and fail-closed
diagnostics for forward, self, non-scalar, unknown, transaction-parameter, and
runtime-signal sources.
Package-constant-backed actor parameter defaults are checked by
[t/1349-isf-actor-param-package-constants.t](../../t/1349-isf-actor-param-package-constants.t),
covering qualified imported package scalar constants, aggregate/list leaves,
resolved width consumption, package root embedding, scheduled `.fsm`
`+params` review artifacts, `actor_params[]` preservation, strict CLI HDL
generation, and fail-closed diagnostics for unknown package constants,
aggregate package constants, package constant member/item paths, and ambiguous
local-enum/package-constant spellings.
Generated child transaction scalar parameter default enum member values are
checked by
[t/1270-isf-enum-member-transaction-params.t](../../t/1270-isf-enum-member-transaction-params.t),
covering local and package enum member transaction parameter defaults,
generated child `.fsm` `+params` review artifacts, generated-composition
schedule-report value preservation, CLI HDL generation, and fail-closed
diagnostics for unknown members, aggregate/list parameter leaves, and
reusable-library use-site override contexts.
Generated child transaction aggregate/list parameter default enum member leaves
are checked by
[t/1278-isf-enum-member-transaction-aggregate-params.t](../../t/1278-isf-enum-member-transaction-aggregate-params.t),
covering local and package enum member leaves in generated child transaction
aggregate/list parameter defaults, generated child `.fsm` `+params` review
artifacts, generated-composition child parameter summaries and default
instance bindings, strict CLI HDL generation, and fail-closed diagnostics for
unknown leaves.
Actor-static generated child transaction parameter defaults are checked by
[t/1347-isf-transaction-param-actor-static-defaults.t](../../t/1347-isf-transaction-param-actor-static-defaults.t),
covering actor constants and actor-local scalar parameter defaults in scalar
transaction defaults and aggregate/list leaves, literalized generated child
`.fsm` `+params`, generated-composition child summaries and default instance
bindings, enum-token preservation, strict CLI HDL generation, and fail-closed
diagnostics for transaction-parameter dependencies, non-scalar actor
parameters, runtime interface signals, and unknown symbols.
Child-local transaction-parameter dependency defaults are checked by
[t/1348-isf-transaction-param-transaction-params.t](../../t/1348-isf-transaction-param-transaction-params.t),
covering earlier scalar transaction parameter defaults, aggregate/list leaves,
generated child `.fsm` `+params` review artifacts, generated-composition child
parameter summaries and default instance bindings, strict CLI HDL generation,
and fail-closed diagnostics for forward, self, non-scalar, runtime-signal, and
unknown sources.
Package-constant-backed generated child transaction parameter defaults are
checked by
[t/1350-isf-transaction-param-package-constants.t](../../t/1350-isf-transaction-param-package-constants.t),
covering qualified imported package scalar constants, aggregate/list leaves,
generated child `.fsm` `+params`, embedded package roots,
generated-composition child summaries and default instance bindings, strict
CLI HDL generation, and fail-closed diagnostics for unknown package constants,
unqualified package constants, aggregate package constants, package
member/item paths, and ambiguous local-enum/package-constant spellings.
Scalar activation parameter override enum member values are checked by
[t/1271-isf-enum-member-activation-params.t](../../t/1271-isf-enum-member-activation-params.t),
covering local and package enum member overrides on spawn, generated blocking
`do`, and rule-trigger activation sites, generated-top literal parameter
bindings, generated-composition schedule-report bindings, and fail-closed
diagnostics for unknown members and non-activation structural targets.
Aggregate/list activation parameter override enum member leaves are checked by
[t/1276-isf-enum-member-activation-aggregate-params.t](../../t/1276-isf-enum-member-activation-aggregate-params.t),
covering local and package enum member leaves on generated activation sites,
literal generated-top bindings, generated-composition schedule-report bindings,
strict CLI HDL generation, and unknown-member diagnostics.
Package-constant-backed generated activation parameter overrides are checked by
[t/1351-isf-activation-param-package-constants.t](../../t/1351-isf-activation-param-package-constants.t),
covering qualified imported package scalar constants and aggregate/list leaves
on spawn, generated blocking `do`, and rule-trigger activation sites, literal
generated-top bindings, generated-composition report bindings, strict CLI HDL
generation for the spawn/do path, and fail-closed diagnostics for unknown
package constants, unqualified package constants, aggregate package constants,
package member/item paths, and ambiguous local-enum/package-constant spellings.
Reusable-library use-site parameter override actor-static and enum values and leaves are
checked by
[t/1281-isf-enum-member-library-use-params.t](../../t/1281-isf-enum-member-library-use-params.t),
covering importing-actor constants, importing-actor scalar parameter defaults,
local and package enum members in scalar and aggregate/list use-site
overrides, literal generated-top bindings, `library_uses[]` schedule-report
values, strict CLI HDL generation, unknown-member diagnostics, runtime-signal
rejection, non-scalar actor-parameter rejection, and the unknown-symbolic
use-site boundary.
Reusable-library use-site parameter override package scalar constants are
checked by
[t/1352-isf-library-use-package-constants.t](../../t/1352-isf-library-use-package-constants.t),
covering qualified imported package scalar constants, aggregate/list leaves,
literal generated-top bindings, `library_uses[]` schedule-report values,
strict CLI HDL generation, and fail-closed diagnostics for unknown package
constants, unqualified package constants, aggregate package constants,
package member/item paths, and ambiguous local-enum/package-constant
spellings.
Scalar rule assignment RHS enum member values are checked by
[t/1272-isf-enum-member-rule-values.t](../../t/1272-isf-enum-member-rule-values.t),
covering local and package enum member explicit `(set port value)` and shorthand
`(port value)` rule assignments, scheduled `.fsm` review artifacts, assignment
provenance, strict CLI HDL generation, strict guarded-DT parsing, and
fail-closed diagnostics for unknown members and rule targets.
Rule assignment RHS expression enum member operands are checked by
[t/1273-isf-enum-member-rule-expression-values.t](../../t/1273-isf-enum-member-rule-expression-values.t),
covering local and package enum member operands inside explicit and shorthand
rule assignment RHS expressions, scheduled `.fsm` review artifacts, assignment
provenance, strict CLI HDL generation, and fail-closed diagnostics for unknown
members and expression operator position.
Rule guard expression enum member operands are checked by
[t/1274-isf-enum-member-rule-guard-values.t](../../t/1274-isf-enum-member-rule-guard-values.t),
covering local and package enum member operands inside shorthand and long-form
rule guard expressions, scheduled `.fsm` review artifacts, strict CLI HDL
generation, public `when` normalization, and fail-closed diagnostics for
unknown members and expression operator position.
Transaction condition expression enum member operands are checked by
[t/1275-isf-enum-member-condition-values.t](../../t/1275-isf-enum-member-condition-values.t),
covering local and package enum member operands inside transaction
`when`/`while`/`until` condition expressions, scheduled `.fsm` computed-test
review artifacts, strict CLI HDL generation, and fail-closed diagnostics for
unknown members and expression operator position.
Standalone transaction condition enum member values are checked by
[t/1300-isf-enum-member-standalone-condition-values.t](../../t/1300-isf-enum-member-standalone-condition-values.t),
covering local and package enum member values used directly as
`when`/`while`/`until` conditions, computed `.fsm` selector review artifacts,
strict CLI HDL generation, and unknown-member diagnostics.
Standalone rule guard enum member values are checked by
[t/1301-isf-enum-member-rule-standalone-guard-values.t](../../t/1301-isf-enum-member-rule-standalone-guard-values.t),
covering local and package enum member values used directly as shorthand and
long-form rule guards, non-state DT header guard review artifacts, strict CLI
HDL generation, public `when` normalization, and unknown-member diagnostics.
Actor-owned aggregate storage variable carriers are checked by
[t/1259-isf-aggregate-storage-type-aliases.t](../../t/1259-isf-aggregate-storage-type-aliases.t),
covering local and package aggregate aliases, typed `+size` review artifacts,
bounded `inferred_storage[].type` / `type_kind` report metadata, CLI HDL
generation, and fail-closed diagnostics for non-carrier aggregate aliases.
Transaction `set` RHS aggregate leaf reads are checked by
[t/1260-isf-aggregate-storage-leaf-reads.t](../../t/1260-isf-aggregate-storage-leaf-reads.t),
covering record member reads, package list item reads, scheduled `.fsm`
review artifacts, CLI HDL generation, and fail-closed diagnostics for unknown
members and aggregate paths inside broader expressions.
Transaction `set` target aggregate leaf writes are checked by
[t/1261-isf-aggregate-storage-leaf-writes.t](../../t/1261-isf-aggregate-storage-leaf-writes.t),
covering record member writes, package list item writes, scheduled `.fsm`
review artifacts, CLI HDL generation, and fail-closed diagnostics for unknown
members, subaggregate writes, and aggregate paths outside direct transaction
`set` positions.
Transaction `set` RHS expression aggregate leaf operands are checked by
[t/1262-isf-aggregate-storage-leaf-expression-reads.t](../../t/1262-isf-aggregate-storage-leaf-expression-reads.t),
covering record member and package list item expression operands, scheduled
`.fsm` review artifacts, CLI HDL generation, and fail-closed diagnostics for
unknown members, operator-position paths, and subaggregate operands.
Transaction condition expression aggregate leaf operands are checked by
[t/1286-isf-aggregate-condition-values.t](../../t/1286-isf-aggregate-condition-values.t),
covering local and package aggregate leaf operands inside transaction
`when`/`while`/`until` condition expressions, scheduled `.fsm` computed-test
review artifacts, CLI HDL generation, and fail-closed diagnostics for unknown
members, operator-position paths, and subaggregate operands.
Standalone transaction condition aggregate leaf values are checked by
[t/1299-isf-aggregate-standalone-condition-values.t](../../t/1299-isf-aggregate-standalone-condition-values.t),
covering local and package aggregate leaf reads as standalone
`when`/`while`/`until` conditions, computed `.fsm` selector review artifacts,
CLI HDL generation, and fail-closed diagnostics for unknown members and
subaggregate conditions.
Rule assignment RHS aggregate leaf values are checked by
[t/1283-isf-aggregate-rule-values.t](../../t/1283-isf-aggregate-rule-values.t),
covering explicit and shorthand rule assignment RHS aggregate leaf reads,
scheduled `.fsm` review artifacts, assignment provenance, CLI HDL generation,
and fail-closed diagnostics for unknown members and subaggregate RHS values.
Rule assignment target aggregate leaf writes are checked by
[t/1296-isf-aggregate-rule-target-values.t](../../t/1296-isf-aggregate-rule-target-values.t),
covering explicit and shorthand rule assignment target aggregate leaf writes,
scheduled `.fsm` review artifacts, assignment provenance, CLI HDL generation,
and fail-closed diagnostics for unknown members and subaggregate targets.
Rule assignment RHS expression aggregate leaf operands are checked by
[t/1284-isf-aggregate-rule-expression-values.t](../../t/1284-isf-aggregate-rule-expression-values.t),
covering explicit and shorthand rule assignment RHS expression aggregate leaf
operands, scheduled `.fsm` review artifacts, assignment provenance, CLI HDL
generation, and fail-closed diagnostics for unknown members, operator-position
paths, and subaggregate operands.
Rule guard expression aggregate leaf operands are checked by
[t/1285-isf-aggregate-rule-guard-values.t](../../t/1285-isf-aggregate-rule-guard-values.t),
covering shorthand and long-form rule guard expression aggregate leaf operands,
scheduled `.fsm` review artifacts, public `when` normalization, CLI HDL
generation, and fail-closed diagnostics for unknown members, operator-position
paths, and subaggregate operands.
Standalone rule guard aggregate leaf values are checked by
[t/1302-isf-aggregate-rule-standalone-guard-values.t](../../t/1302-isf-aggregate-rule-standalone-guard-values.t),
covering local and package aggregate leaf reads as shorthand and long-form
rule guards, non-state DT header guard review artifacts, public `when`
normalization, CLI HDL generation, and fail-closed diagnostics for unknown
paths, out-of-range indexes, and subaggregate guards.
Drive body RHS aggregate leaf values are checked by
[t/1287-isf-aggregate-drive-values.t](../../t/1287-isf-aggregate-drive-values.t),
covering local and package aggregate leaf reads in named drive body scalar RHS
values, scheduled `.fsm` drive-DT review artifacts, CLI HDL generation, and
fail-closed diagnostics for unknown members and subaggregate RHS values.
Drive target aggregate leaf writes are checked by
[t/1297-isf-aggregate-drive-target-values.t](../../t/1297-isf-aggregate-drive-target-values.t),
covering local and package aggregate leaf writes as named drive body targets,
scheduled `.fsm` drive-DT review artifacts, assignment provenance, CLI HDL
generation, and fail-closed diagnostics for unknown members and subaggregate
targets.
Drive body RHS expression aggregate leaf operands are checked by
[t/1288-isf-aggregate-drive-expression-values.t](../../t/1288-isf-aggregate-drive-expression-values.t),
covering local and package aggregate leaf operands inside named drive body RHS
expressions, scheduled `.fsm` drive-DT review artifacts, CLI HDL generation,
and fail-closed diagnostics for unknown members, operator-position paths, and
subaggregate operands.
Drive-call actual aggregate leaf values are checked by
[t/1289-isf-aggregate-drive-call-values.t](../../t/1289-isf-aggregate-drive-call-values.t),
covering local and package aggregate leaf reads as named drive-call scalar
actual values, scheduled `.fsm` drive-parameter review artifacts, CLI HDL
generation, and fail-closed diagnostics for unknown members, inline drive
assignments, and subaggregate actuals.
Drive-call actual expression aggregate leaf operands are checked by
[t/1290-isf-aggregate-drive-call-expression-values.t](../../t/1290-isf-aggregate-drive-call-expression-values.t),
covering local and package aggregate leaf operands inside named drive-call
actual expressions, scheduled `.fsm` drive-parameter review artifacts, CLI HDL
generation, and fail-closed diagnostics for unknown members, operator-position
paths, and subaggregate operands.
Inline drive assignment RHS aggregate leaf values are checked by
[t/1291-isf-aggregate-inline-drive-values.t](../../t/1291-isf-aggregate-inline-drive-values.t),
covering local and package aggregate leaf reads as inline drive assignment
scalar RHS values, scheduled `.fsm` state-assignment review artifacts, CLI HDL
generation, and fail-closed diagnostics for unknown members and subaggregate
RHS values.
Inline drive RHS expression aggregate leaf operands are checked by
[t/1292-isf-aggregate-inline-drive-expression-values.t](../../t/1292-isf-aggregate-inline-drive-expression-values.t),
covering local and package aggregate leaf operands inside inline drive RHS
expressions, scheduled `.fsm` state-assignment review artifacts, CLI HDL
generation, and fail-closed diagnostics for unknown members, operator-position
paths, and subaggregate operands.
Inline drive target aggregate leaf writes are checked by
[t/1298-isf-aggregate-inline-drive-target-values.t](../../t/1298-isf-aggregate-inline-drive-target-values.t),
covering local and package aggregate leaf writes as inline drive targets,
scheduled `.fsm` state-assignment review artifacts, assignment provenance, CLI
HDL generation, and fail-closed diagnostics for unknown members and
subaggregate targets.
Transaction switch branch aggregate leaf values are checked by
[t/1293-isf-aggregate-switch-branch-values.t](../../t/1293-isf-aggregate-switch-branch-values.t),
covering local and package aggregate leaf reads as transaction `switch` branch
values, scheduled `.fsm` switch review artifacts, CLI HDL generation, and
fail-closed diagnostics for unknown members and
subaggregate branch values.
Transaction switch selector aggregate leaf values are checked by
[t/1294-isf-aggregate-switch-selector-values.t](../../t/1294-isf-aggregate-switch-selector-values.t),
covering local and package aggregate leaf reads as transaction `switch`
selectors, computed `.fsm` selector review artifacts, CLI HDL generation, and
fail-closed diagnostics for unknown members and subaggregate selectors.
Generated composition-top links use the canonical Lisp-ish `?wiring` list
spelling, for example `(parent.instance_start instance.start)`, rather than
the older slash-token compatibility spelling.
The switch-clause boundary is checked by
[t/1205-isf-switch-clause-boundary.t](../../t/1205-isf-switch-clause-boundary.t)
so `(switch signal (value body...)...)` requires one scalar signal, one or more
list-form branches, and scalar branch values before branch expansion.
The when-clause boundary is checked by
[t/1206-isf-when-clause-boundary.t](../../t/1206-isf-when-clause-boundary.t)
so `(when condition body...)` requires one scalar or list-form condition and at
least one list-form body clause before branch expansion.
ISF switch fallback scheduling is checked by
[t/1103-isf-switch-branch-exits.t](../../t/1103-isf-switch-branch-exits.t)
and the generated `.fsm` default selector contract is checked by
[t/42-language-contract-test-selector-boundary.t](../../t/42-language-contract-test-selector-boundary.t)
and [t/37-language-contract-computed-test-selector.t](../../t/37-language-contract-computed-test-selector.t).
The facade shape metadata that advertises those constructor, method, path, and
actor-shell boundaries is checked by
[t/1143-isf-public-facade-shape-metadata-audit.t](../../t/1143-isf-public-facade-shape-metadata-audit.t)
to stay exact across direct and manifest views.
