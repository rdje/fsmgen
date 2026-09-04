# End-to-End AHB HIAL/VIAL Tutorial

This tutorial runs one checked AHB design and verification pair from authored
intent to review artifacts, a target-neutral plan, and the selected public
runtime result. It then shows the separate portable-VHDL and OSVVM inspection
and qualification routes. All commands run from the repository root.

The public execution path is deliberately narrow:

```text
ppif/ahb_lite_subordinate.ppif                         HIAL design intent
             +
vial/ahb_subordinate_base_output_arbitration.vial     VIAL verification intent
             |
             v
check -> format -> reviewed IAL1/IAL0 bridge -> plan
             |
             v
public sv_portable_verilator run -> normalized result
```

Portable VHDL/GHDL and the OSVVM advanced tier are qualified private profiles,
not additional values accepted by public `fsmgen vial run`. Their checked
galleries and qualification reports are evidence, not a promise of a public
VHDL execution command.

If this workflow will replace an IAL1 observation skeleton or a handwritten
fixture in an existing consumer, use the
[legacy migration guide](16di-vial-legacy-migration.md) to keep the old route
stable until the new result and parity evidence are accepted.

## Read the two authored inputs

The HIAL source is `ppif/ahb_lite_subordinate.ppif`. It declares the AHB
subordinate, clock and reset, bus endpoints, one storage register, accepted
transfer shape, wait control, and two-cycle error completion. Planning routes
this IAL2 input through generated and reparsed IAL1, then generated IAL0.
There is no direct IAL2-to-verification shortcut.

The VIAL source is
`vial/ahb_subordinate_base_output_arbitration.vial`. It binds one fixture to
the HIAL unit and describes two scenarios:

- `success` starts a valid write, waits for completion and a stall, checks the
  response/read data/stored data, and closes its scoreboard;
- `unsupported_size` injects a one-cycle size substitution, waits for error
  completion, and proves storage was not changed.

The source names four typed observations used by the runtime and parity
oracles:

| VIAL name | HIAL semantic identity | Type | Access |
| --- | --- | --- | --- |
| `ready_out` | `endpoint/HREADYOUT` | `logic 1` | public output |
| `response` | `endpoint/HRESP` | `logic 1` | public output |
| `read_data` | `endpoint/HRDATA` | `logic 32` | public output |
| `stored_data` | `probe/reg_data_q` | `logic 32` | declared verification probe |

Only those bridge-declared endpoints and probe receive backend adapters.
Arbitrary hierarchy access is not part of this profile.

## Check and format the VIAL source

Check the authored projection without binding or writing an artifact:

```bash
./bin/fsmgen vial check --style auto \
  vial/ahb_subordinate_base_output_arbitration.vial
```

Expected success output is:

```text
VIAL check passed (normal_v1)
```

Render the explicit normal projection:

```bash
./bin/fsmgen vial format --style normal \
  vial/ahb_subordinate_base_output_arbitration.vial
```

It begins with `(vial` followed by `(version 1)`. Render the compact projection:

```bash
./bin/fsmgen vial format --style terse \
  vial/ahb_subordinate_base_output_arbitration.vial
```

It begins with `(vial 1` and removes only selected structural wrappers. The two
outputs have different source bytes, but reparsing them yields the same
provenance-free semantic digest. Terse form does not infer a type, value,
timeout, binding, event, decision, or target behavior.

## Build and inspect the target-neutral plan

Select the complete fixture by omitting `--scenario`; both scenarios remain in
authored order:

```bash
./bin/fsmgen vial plan \
  --dut ppif/ahb_lite_subordinate.ppif \
  --fixture base_output_arbitration \
  --profile core_directed_single_clock_execution_v1 \
  --outdir .artifacts/manual/vial-ahb-tutorial-plan \
  vial/ahb_subordinate_base_output_arbitration.vial
```

The first successful publication reports:

```text
VIAL plan planned (.artifacts/manual/vial-ahb-tutorial-plan)
```

The tree is small enough to review directly:

```text
.artifacts/manual/vial-ahb-tutorial-plan/
  vial-tool-manifest.json
  source/vial-normal.vial
  review/ahb_lite_subordinate.isf
  review/ahb_lite_subordinate.fsm
  hial-vial-bridge.json
  vial-plan.json
```

Read the files in that order:

- `source/vial-normal.vial` is the canonical author-facing source projection.
- The two `review/` files expose the generated IAL1 and IAL0 route used to
  establish HIAL truth.
- `hial-vial-bridge.json` binds the AHB transaction, events, endpoints, types,
  domains, and declared probe without exposing compiler objects.
- `vial-plan.json` contains the chosen scenarios, operations, fibers, seeded
  decision, bindings, source maps, resource summary, and logical-time policy.
- `vial-tool-manifest.json` inventories the other files and records the atomic
  publication/cleanup state.

The plan's logical phase order is:

```text
drive -> sample -> react -> check
```

Each scenario starts at cycle zero. Timeout comparison includes the last
declared cycle. Within a phase, domain rank, static operation rank, local
emission order, and semantic identity break ties. A backend may use native
scheduling machinery internally, but it may not redefine this order.

The checked seed deterministically chooses the success scenario's wait value.
The choice is plan data and is replayable; the backend does not rerandomize it.
The `parallel all` children are separate fibers whose satisfaction is latched
at the same logical barrier before the parent advances.

## Run the selected public backend

Preflight the installed profile with capability discovery if the tool setup is
unfamiliar:

```bash
./bin/fsmgen vial capabilities --json
```

Then run both scenarios through the only public execution backend:

```bash
./bin/fsmgen vial run \
  --dut ppif/ahb_lite_subordinate.ppif \
  --backend sv_portable_verilator \
  --fixture base_output_arbitration \
  --profile core_directed_single_clock_execution_v1 \
  --outdir .artifacts/manual/vial-ahb-tutorial-run \
  vial/ahb_subordinate_base_output_arbitration.vial
```

With the exact qualified `Verilator 5.046` profile installed, the first
successful publication reports:

```text
VIAL run executed (.artifacts/manual/vial-ahb-tutorial-run)
```

The plan artifacts remain, and the run adds:

```text
backends/sv_portable_verilator/backend-manifest.json
backends/sv_portable_verilator/backend-source-map.json
backends/sv_portable_verilator/commands/compile-command.json
backends/sv_portable_verilator/commands/run-command.json
backends/sv_portable_verilator/evidence/compile-transcript.txt
backends/sv_portable_verilator/evidence/run-transcript.txt
backends/sv_portable_verilator/evidence/runtime-trace.jsonl
backends/sv_portable_verilator/evidence/tool-profile.json
backends/sv_portable_verilator/src/base_output_arbitration_tb.sv
backends/sv_portable_verilator/src/dut/ahb-lite-subordinate.sv
backends/sv_portable_verilator/src/fsmgen_vial_runtime_pkg.sv
verification-output-manifest.json
results/<result-digest>/verification-result-manifest.json
```

The recorded compile and run commands are evidence; they are not an invitation
to edit and replay private backend plumbing. The backend stages on the
repository volume, validates the closed trace, constructs the normalized
result, atomically publishes the complete tree, and removes its owned staging
area before returning.

The result manifest is the portable review boundary. It reports both scenario
statuses and completion reasons plus decisions, events, drives, samples,
transactions, expectations, models, scoreboards, coverage, faults, fibers,
diagnostics, semantic metrics, and logical times. Each runtime logical time has
`domain_id`, `cycle`, `phase`, and phase-local `ordinal`; generated HDL timing
or process ordering is not the semantic result.

For this fixture the normalized portable outcome is:

| Scenario | Status | AHB accepts | Ready-low cycles used by parity | Error-response cycles | Final storage |
| --- | --- | --- | --- | --- | --- |
| `success` | `pass` | `1` | `15` | `0` | `cafebabe` |
| `unsupported_size` | `pass` | `1` | excluded | `2` | `00000000` |

Claim verification for that table:

- Re-derive: the guarded public runtime test produces the result, and the
  handwritten AHB parity test reconstructs the projection from its streams.
- Falsify: the parity test changes success storage to `deadbeef` and requires
  one mismatch at `/outcomes/0/storage_hex` for `probe/reg_data_q`.
- Durability: `t/1558-vial-verilator-run-integration.t`,
  `t/1559-vial-ahb-runtime-parity.t`, and this chapter's watcher retain the
  command, normalized fields, negative control, and cleanup checks.

## Understand the bounded parity oracle

Ordinary `vial run` does not publish a parity report. The separate checked AHB
qualification runs the generated VIAL harness and the handwritten harness in
`t/data/ahb_generated_subordinate_base_output_arbitration_tb.svt` against
byte-identical generated DUT source. It compares these exact nineteen paths:

```text
/outcomes/0/scenario_id
/outcomes/0/status
/outcomes/0/bus_accepts
/outcomes/0/ready_low_cycles
/outcomes/0/response_error_cycles
/outcomes/0/nonzero_read_data_cycles
/outcomes/0/final_ready
/outcomes/0/final_response
/outcomes/0/final_read_data_hex
/outcomes/0/storage_hex
/outcomes/1/scenario_id
/outcomes/1/status
/outcomes/1/bus_accepts
/outcomes/1/response_error_cycles
/outcomes/1/nonzero_read_data_cycles
/outcomes/1/final_ready
/outcomes/1/final_response
/outcomes/1/final_read_data_hex
/outcomes/1/storage_hex
```

Index zero is `success`; index one is `unsupported_size`. Ready-low duration
for the error scenario is intentionally absent because the handwritten oracle
does not qualify it. Internal capture, hold, and completion counters are also
excluded because they are not declared typed VIAL probes. A mismatch records
the JSON path, baseline and candidate values, semantic identity, and candidate
logical time. Source-text or waveform similarity cannot override it.

This is the bounded capability
`vial.parity.ahb_base_output_arbitration.v1`, not general cross-backend
parity.

## Inspect and qualify portable VHDL

The provider-free `vhdl_portable_ghdl` profile has a byte-locked review gallery
for the same plan and sources. Check the gallery without rewriting it:

```bash
perl scripts/refresh_vial_vhdl_portable_gallery.pl --check
```

Start at
`vial/review_gallery/vhdl_portable_ghdl/ahb_base_output_portable_semantics/README.md`.
Review the generated HIAL VHDL DUT, typed value and logical-time packages,
fixture metadata, testbench, declared-probe adapter, mapping matrix, workflow,
and migration proof. Gallery inspection invokes no simulator.

The exact checked qualification uses repository-local `GHDL 6.0.0` LLVM-JIT:

```bash
scripts/run_with_ram_guard.sh --process-max-rss-mb 4096 -- \
  perl scripts/run_vial_vhdl_portable_ghdl_qualification.pl --check
```

It checks analysis, elaboration, bounded execution, timed four-state
observation, deterministic rerun, normalized results, the analogous nineteen
portable outcome paths, and cleanup for this fixture. It does not establish
complete VHDL, PSL, another simulator, mixed-language execution, or general
parity.

## Inspect and qualify the OSVVM tier

The `vhdl_osvvm_qualified` profile wraps the byte-identical portable VHDL
sources with isolated advanced-provider services. Check its gallery:

```bash
perl scripts/refresh_vial_vhdl_osvvm_gallery.pl --check
```

Start at
`vial/review_gallery/vhdl_osvvm_qualified/ahb_base_output_advanced_services/README.md`.
Its provider materialization, advanced mapping matrix, semantic-preservation
record, and qualification reference show exactly what the wrapper adds and
what remains portable authority.

Run the checked `OSVVM 2026.05` plus `GHDL 6.0.0` qualification under the
repository guard:

```bash
scripts/run_with_ram_guard.sh --process-max-rss-mb 4096 -- \
  perl scripts/run_vial_vhdl_osvvm_ghdl_qualification.pl --check
```

The report's `portable_result_parity` proves the same normalized outcome set;
OSVVM reports remain supplementary. Provider randomization, coverage,
scoreboard, report, memory, and barrier probes do not redefine VIAL decisions,
logical phases, comparison, trace, or results.

Claim verification for the two VHDL routes:

- Re-derive: the two `--check` qualification runners reconstruct the checked
  reports from their selected source, provider, and tool inputs.
- Falsify: `t/1595-vial-vhdl-portable-ghdl-qualification.t` and
  `t/1599-vial-vhdl-osvvm-ghdl-qualification.t` reject changed tool identities,
  traces, results, parity paths, sources, provider evidence, and cleanup.
- Durability: both runner scripts, both qualification JSON files, both
  galleries, their focused tests, and this tutorial watcher are tracked.

## Expected failures are evidence too

Do not translate these outcomes into a pass:

- a backend other than `sv_portable_verilator` at the public command returns
  `VIAL_BACKEND_UNSUPPORTED` and publishes no partial tree;
- a missing or wrong tool reports `VIAL_RUN_TOOL_ERROR`;
- compilation, runtime, trace, or normalized-result failure retains its
  corresponding `VIAL_RUN_*` diagnostic and no committed result tree;
- a non-identical existing target reports a collision and is not overwritten;
- complete four-state public runtime, native-UVM runtime, public VHDL run,
  mixed-language execution, general parity, and arbitrary-tool capacity remain
  unavailable or unclaimed.

Exact diagnostics contain repository-relative source/artifact identities, not
machine-local paths or raw exceptions.

## Repeat and clean up

Repeating the same plan or run against its complete output root returns
`unchanged` and preserves every byte. Different content never overwrites an
existing root.

After review, remove only the two tutorial-owned roots:

```bash
rm -rf .artifacts/manual/vial-ahb-tutorial-plan
rm -rf .artifacts/manual/vial-ahb-tutorial-run
```

Do not remove them while a command is running. Internal staging has already
been removed before a successful command returns.

For field-by-field public tooling details, return to the
[Public VIAL Lifecycle Reference](16dg-vial-public-lifecycle-reference.md).
For backend architecture and evidence depth, use
[HIAL/VIAL Verification: Start Here](16d-hial-vial-verification-architecture.md)
and its specialist chapters. The
[capability and support reference](16dj-vial-capability-support-reference.md)
is the compact status, provider, parity, scale, and troubleshooting index.
