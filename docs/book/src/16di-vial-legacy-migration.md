# Migrating Legacy Observation Outputs and Handwritten Fixtures to VIAL

FSMGen does not replace its older verification surfaces in place. Migration is
additive: keep the legacy artifact when a consumer still needs its exact
contract, add VIAL beside it for executable verification behavior, prove the
new path, and roll the consumer back independently if needed.

Use these terms precisely:

- **retain** means the current source, command, artifact, and nonclaims stay
  valid;
- **parallel successor** means VIAL supplies a separate behavioral path without
  changing the legacy bytes or identity; and
- **migrate** means moving authored verification intent or a consuming workflow
  to `.vial`, not translating or relabelling a generated legacy package.

Nothing in this guide deprecates `(observe ...)`, `uvm-passive-monitor`,
`vhdl-observation-package`, or the handwritten AHB qualification harness.

## Choose the migration state

| Existing surface | State | Keep using it for | Move to VIAL for |
| --- | --- | --- | --- |
| IAL1 `(observe ...)` metadata | **retain** | naming a passive observation and its public interface signals in HIAL schedule metadata | scenarios, stimulus, events, transactions, checks, models, scoreboards, coverage, faults, and normalized results |
| UVM 1.2 passive-monitor package | **retain + parallel successor** | an inert snapshot/monitor declaration and its version-1 verification-output manifest | executable portable verification or separately reviewed native-UVM VIAL emission |
| VHDL observation package | **retain + parallel successor** | inert observation constants and its version-1 verification-output manifest | executable provider-free VIAL VHDL or the separately qualified OSVVM tier |
| handwritten AHB harness | **retain as bounded oracle + migrate authorship** | independent comparison against the identical generated AHB DUT | the checked `.vial` scenario source and ordinary public portable-SystemVerilog run |

The matrix is capability-based. A metadata consumer need not migrate merely
because VIAL exists. A workflow that needs driving, sampling, expected-versus-
actual comparison, or a result manifest should add VIAL because the legacy
skeletons deliberately provide none of those behaviors.

## Inspect the retained IAL1 observation contract

The checked legacy source is
`isf/verification_observation_metadata.isf`. Its observation is ordinary IAL1
actor metadata:

```lisp
(observe link_rx
  (role passive_monitor)
  (signals valid ready data))
```

Inspect the public schedule projection:

```bash
./bin/fsmgen --emit-schedule-json \
  isf/verification_observation_metadata.isf \
  | jq '{verification_bridge, verification_observations}'
```

The checked projection contains `verification_bridge: null` and one
`verification_observations[]` entry named `link_rx`. It inherits `clk` and the
asynchronous active-low `rst_n`, retains the source order `valid`, `ready`,
`data`, and records each signal's direction and width.

That declaration remains report metadata. It does not create scheduled `.fsm`
content, sample a DUT, publish a transaction, or describe a VIAL scenario. A
version-1 `HIALVIALBridgeManifest` may project the same declaration as
`observation/link_rx` with authored-order endpoint identities, but the bridge
record is still binding metadata rather than executable intent.

### Compatibility promise

Keep `(observe ...)` when another tool consumes the schedule report or either
legacy package. Do not reinterpret the signal list as a sampling event or
transaction boundary: the source does not say when a transfer occurs, what is
expected, or how observations correlate.

When behavior is required, author those missing decisions explicitly in a
`.vial` fixture. The IAL1 observation may remain beside it; VIAL does not need
to delete or rewrite the declaration.

## Keep the UVM 1.2 skeleton as an inert compatibility output

Generate the retained artifact into its own repository-local root:

```bash
./bin/fsmgen --quiet \
  --emit-verification-output uvm-passive-monitor \
  --verification-outdir .artifacts/manual/vial-legacy-uvm \
  isf/verification_observation_metadata.isf
```

This writes exactly:

```text
.artifacts/manual/vial-legacy-uvm/
  verification-output-manifest.json
  uvm/verification_observation_metadata_observation_uvm_pkg.sv
```

Inspect the boundary rather than inferring capability from the `.sv` suffix:

```bash
jq '{schema_version, mode, target, actor, validation}' \
  .artifacts/manual/vial-legacy-uvm/verification-output-manifest.json
```

The manifest retains `schema_version: 1`, mode `verification_output`, target
`uvm_passive_monitor_skeleton`, and actor
`verification_observation_metadata`. Its validation record says
`artifact_shape_checked: true`, `inert_behavior_checked: true`,
`claimed_uvm_compile_support: false`, and `uvm_compile_validator: none`.

The package declares `link_rx_snapshot`, `link_rx_monitor`, typed snapshot
fields, and `observed_ap`. It deliberately has no virtual interface,
`run_phase`, sampling edge, `uvm_config_db` lookup, `observed_ap.write(...)`,
agent, scoreboard, or coverage behavior.

### Parallel native-UVM successor

Do not edit or relabel this UVM 1.2 package into native VIAL output. Native
VIAL has the separate review profile `sv_uvm_emit.accellera_2020_3_1`, a
separate artifact graph, and compiler-private mappings from typed VIAL intent.
Its current evidence is deterministic structural emission, not qualified
compile or runtime support.

Review the checked native gallery without changing it:

```bash
perl scripts/refresh_vial_native_uvm_gallery.pl --check
```

There is no public `fsmgen vial run --backend sv_uvm_qualified` path today.
Trying an unavailable public backend fails with `VIAL_BACKEND_UNSUPPORTED` and
must not publish a bridge, plan, artifact, or result. Keep the legacy skeleton
for its existing consumer; move behavioral authorship to `.vial` and select a
qualified runtime only when public capability discovery reports one.

## Keep the VHDL package as inert metadata

Generate the retained VHDL artifact into a different root:

```bash
./bin/fsmgen --quiet \
  --emit-verification-output vhdl-observation-package \
  --verification-outdir .artifacts/manual/vial-legacy-vhdl \
  isf/verification_observation_metadata.isf
```

This writes exactly:

```text
.artifacts/manual/vial-legacy-vhdl/
  verification-output-manifest.json
  vhdl/verification_observation_metadata_observation_vhdl_pkg.vhd
```

Inspect its validation record:

```bash
jq '{schema_version, mode, target, actor, validation}' \
  .artifacts/manual/vial-legacy-vhdl/verification-output-manifest.json
```

The target is `vhdl_observation_package_skeleton`. The package carries the
`LINK_RX_*` observation and signal constants, but it has no entity,
architecture, process, assertion, PSL, sampling, scoreboard, or coverage
behavior. The manifest keeps `claimed_vhdl_compile_support: false`,
`vhdl_syntax_validator: none`, `claimed_psl_support: false`, and
`psl_validator: none`.

### Parallel executable VHDL successors

Portable VIAL VHDL does not import, compile, wrap, or rewrite that package.
Profile `vhdl_portable_ghdl` emits a separate provider-free fixture from the
same target-neutral VIAL plan. Profile `vhdl_osvvm_qualified` then wraps the
portable foundation without changing its logical result.

Inspect the byte-locked successor galleries with:

```bash
perl scripts/refresh_vial_vhdl_portable_gallery.pl --check
perl scripts/refresh_vial_vhdl_osvvm_gallery.pl --check
```

Their separate qualification reports prove only the checked profiles. They do
not turn `vhdl-observation-package` into compiled verification behavior, and
neither profile is a value accepted by public `fsmgen vial run` today.

## Move behavioral intent to typed VIAL

The checked migration example uses:

```text
ppif/ahb_lite_subordinate.ppif
vial/ahb_subordinate_base_output_arbitration.vial
```

The VIAL fixture names public observations and a declared HIAL probe instead
of borrowing raw backend hierarchy:

```lisp
(endpoints
  (endpoint ready_out "endpoint/HREADYOUT" (logic 1) public_port)
  (endpoint response "endpoint/HRESP" (logic 1) public_port)
  (endpoint read_data "endpoint/HRDATA" (logic 32) public_port)
  (endpoint stored_data "probe/reg_data_q" (logic 32)
    verification_probe))
```

Plan it through the reviewable HIAL route:

```bash
./bin/fsmgen vial plan \
  --dut ppif/ahb_lite_subordinate.ppif \
  --fixture base_output_arbitration \
  --profile core_directed_single_clock_execution_v1 \
  --outdir .artifacts/manual/vial-migration-plan \
  vial/ahb_subordinate_base_output_arbitration.vial
```

The plan publishes `hial-vial-bridge.json` and `vial-plan.json` beside the
generated/reparsed IAL1 and generated IAL0 review artifacts. The bridge uses
schema `fsmgen.hial_vial_bridge_manifest.v1`; it exposes semantic endpoint and
probe identities, not the generated UVM/VHDL legacy packages and not a raw
hierarchy path.

Inspect the migration boundary:

```bash
jq '{schema, review_route, observations, probes}' \
  .artifacts/manual/vial-migration-plan/hial-vial-bridge.json
```

For the checked AHB fixture, the route is IAL2 -> generated/reparsed IAL1 ->
generated IAL0, `observations` is empty, and the declared storage probe is
`probe/reg_data_q` with `access: verification_probe` and
`adapter_requirement: equivalent_adapter_required`. Public HREADYOUT, HRESP,
and HRDATA remain `public_port` endpoints. An undeclared internal signal is not
made portable by naming its hierarchy path in prose or generated code.

The behavioral replacements are explicit:

| Legacy shape | Typed VIAL replacement |
| --- | --- |
| observed signal name | bridge-bound `public_port` endpoint |
| snapshot field with no sampling behavior | `(sample endpoint)` at logical `sample` phase |
| inert analysis-port declaration | typed transaction event and scoreboard `actual` stream |
| no expected outcome | `expect`, `scoreboard_check`, coverage, and normalized result records |
| raw internal hierarchy in a handwritten fixture | HIAL-declared `verification_probe` plus an equivalent adapter |
| procedural delay/order in one target language | deterministic `drive -> sample -> react -> check` logical time |

Run the selected public backend only after reviewing the plan:

```bash
./bin/fsmgen vial run \
  --dut ppif/ahb_lite_subordinate.ppif \
  --backend sv_portable_verilator \
  --outdir .artifacts/manual/vial-migration-run \
  vial/ahb_subordinate_base_output_arbitration.vial
```

The runnable details and expected normalized outcomes are in the
[end-to-end AHB tutorial](16dh-vial-ahb-end-to-end-tutorial.md).

## Preserve the handwritten AHB oracle during migration

The checked handwritten fixture is
`t/data/ahb_generated_subordinate_base_output_arbitration_tb.svt`. Do not
delete it when the `.vial` source begins to pass. T1559 executes the handwritten
and generated VIAL harnesses against byte-identical generated DUT source, then
compares only the shared bounded AHB outcome.

The migration is accepted only while:

1. both scenarios complete against the same DUT bytes;
2. the shared public outputs and declared `probe/reg_data_q` agree on all
   nineteen compared paths;
3. internal capture, hold, and completion counters remain explicit exclusions
   because they are not declared typed VIAL probes; and
4. malformed baseline output, a different DUT digest, an ineligible result, or
   a changed shared value fails closed.

This is `vial.parity.ahb_base_output_arbitration.v1`, not general parity. The
handwritten fixture remains a qualification oracle even after day-to-day
scenario authorship moves to VIAL.

## Rollout and rollback

Use separate roots and separate consumer switches:

1. retain the IAL1 source and regenerate any existing legacy artifacts in
   their current target shape;
2. add and check the `.vial` source without changing the legacy consumer;
3. review the HIAL bridge and target-neutral plan;
4. run the supported backend and, where applicable, the bounded handwritten
   parity gate;
5. switch only the intended consumer to the VIAL result; and
6. keep the old source/output route until its own versioned retirement owner
   exists.

Rollback means pointing that consumer back to the retained legacy route and
removing only the new operation-owned VIAL roots. It does not require reverting
HIAL, changing `(observe ...)`, or mutating a legacy package in place.

After inspecting this guide's examples, remove only their exact roots:

```bash
rm -rf .artifacts/manual/vial-legacy-uvm
rm -rf .artifacts/manual/vial-legacy-vhdl
rm -rf .artifacts/manual/vial-migration-plan
rm -rf .artifacts/manual/vial-migration-run
```

## Nonclaims that survive migration

Migration does not claim any of the following:

- UVM compile, elaboration, or runtime support for the UVM 1.2 skeleton;
- VHDL syntax, compile, runtime, or PSL support for the observation package;
- automatic translation from either legacy package to `.vial`;
- public native-UVM, portable-VHDL, OSVVM, or mixed-language execution;
- arbitrary hierarchy access or automatic promotion of internal counters to
  portable probes;
- general cross-backend parity; or
- retirement or deprecation of a legacy command, target ID, path, manifest, or
  source declaration.

Check mutable availability with `./bin/fsmgen --capability-manifest` and
`./bin/fsmgen vial capabilities --json`. Treat the generated manifests and
checked contracts as authority, not this chapter's prose, if the capability
set later evolves. Use the
[capability and support reference](16dj-vial-capability-support-reference.md)
to decide which successor is public, privately qualified, review-only,
experimental, or unavailable.
