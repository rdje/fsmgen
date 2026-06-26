# IAL1 Verification Output Public Surface Contract Selection

## Metadata

- Owner leaf: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.7`
- Date: `2026-06-26`
- Status: `complete`
- Selected next owner: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.8`

## Decision

The first public verification-output surface is an explicit ISF-to-UVM
artifact command for the passive monitor skeleton selected by
`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4`.

The selected future CLI form is:

```text
./bin/fsmgen --emit-verification-output uvm-passive-monitor \
  --verification-outdir DIR source.isf
```

The selected target value is `uvm-passive-monitor`. Public reports and manifest
metadata must use the stable canonical target id
`uvm_passive_monitor_skeleton`.

This is a verification-artifact mode, not an HDL language mode. The first
implementation must not reuse `--language`, `--output`, or `--verify-hdl`.
Those options remain scoped to synthesizable HDL emission. The selected mode
also must not combine with `--check`, `--json`, `--check-json`,
`--emit-semantic-json`, `--emit-schedule-json`, `--outdir`, or `--output`.
The `--strict` and `--quiet` flags may remain accepted when they preserve the
existing parser/support-policy and human-output behavior.

## Source Boundary

The first implementation accepts `.isf` input only. The source must parse into
an actor with at least one schedule-report `verification_observations[]` entry
whose `role` is `passive_monitor`.

The command must reject direct `.fsm` input because IAL0 has no
`verification_observations[]` source contract. It must reject `.ppif` input
until a later owner selects how IAL2 protocol facts annotate or lower into IAL1
verification observations. It must also reject `.isf` sources with no passive
observation metadata before creating any verification artifact.

## Artifact Layout

The first implementation requires `--verification-outdir DIR`. It writes a
reviewable verification artifact tree under that directory:

```text
DIR/
  verification-output-manifest.json
  uvm/
    <actor>_observation_uvm_pkg.sv
```

The package filename and package name are derived from the actor name, not from
the observation name:

```text
<actor>_observation_uvm_pkg.sv
<actor>_observation_uvm_pkg
```

Each observation inside the package may declare the inert snapshot and monitor
classes selected by `.4`:

```text
<observation>_snapshot extends uvm_sequence_item
<observation>_monitor  extends uvm_monitor
```

The emitted skeleton must stay inert: no `run_phase`, virtual interface,
`uvm_config_db`, DUT sampling, transaction publication, assertion/property
body, coverage body, agent/env/test wrapper, scoreboard, expected/actual
comparison, reusable VIP behavior, or direct IAL2 protocol checker behavior.

## Artifact Manifest

The selected artifact manifest is `verification-output-manifest.json` at the
root of `--verification-outdir`.

The first manifest schema is:

```text
schema_version
mode
target
source
actor
artifacts
validation
```

The selected nested source keys are:

```text
resolved_path
source_kind
```

The selected artifact entry keys are:

```text
kind
language
uvm_version
relpath
package_name
observations
```

The selected observation entry keys are:

```text
name
role
snapshot_class
monitor_class
signals
```

The selected signal entry keys reuse the shipped
`verification_observations[].signals[]` keys:

```text
name
direction
width
```

The selected validation keys are:

```text
claimed_uvm_compile_support
uvm_compile_validator
artifact_shape_checked
inert_behavior_checked
```

For the first implementation, `claimed_uvm_compile_support` must be false and
`uvm_compile_validator` must be `none`. FSMGen may generate UVM-shaped source,
but it must not claim UVM compile support until a later task-tree owner selects
and regression-backs a UVM-aware validation environment.

## Capability Manifest

The implementation owner must add a bounded public capability-manifest
discovery surface for verification outputs. The selected shape is a new
`verification_outputs` manifest section with:

```text
schema_version
status
targets
artifact_manifest
validation
section_contract
```

The first `targets[]` entry must advertise:

```text
id: uvm_passive_monitor_skeleton
cli_target: uvm-passive-monitor
source_suffixes: [.isf]
requires_verification_observations: true
artifact_language: systemverilog
uvm_version: 1.2
artifact_relpath_pattern: uvm/<actor>_observation_uvm_pkg.sv
manifest_relpath: verification-output-manifest.json
status: shipped_bounded_public
```

The `.isf` language-surface entry must add the CLI mode
`--emit-verification-output uvm-passive-monitor --verification-outdir`.
The `.fsm` and `.ppif` entries must not advertise this mode in the first
implementation.

## Support Accounting

The implementation owner must add a distinct support-accounting entry for the
verification-output command rather than reusing the existing report-only
observation metadata entry.

The selected entry is:

```text
id: feature.isf_verification_observation_uvm_passive_monitor_skeleton
relpath: isf/verification_observation_metadata.isf
family: language_feature_fixture
classification: supported_smoke
coverage: isf_verification_output_uvm_passive_monitor_skeleton_cli
source_kind: isf
strict_supported: true
```

Focused tests must prove that this entry covers the CLI mode, artifact
manifest, generated package path, selected class names, observed signal fields,
and absence of deferred behavioral bodies.

## Public JSON Surfaces

Existing `--emit-schedule-json` behavior remains unchanged in the first
implementation: it continues to expose `verification_observations[]` and does
not list generated verification files.

Existing `--check --json` / `--check-json` and `--emit-semantic-json` behavior
also remains unchanged in the first implementation: those report modes do not
emit verification artifacts and the shared `generated_output.emitted` field
continues to describe HDL-generation side effects only.

The artifact manifest is the public machine-readable report for the new
verification-output mode. A later owner may select shared check/semantic JSON
references to verification artifacts, but `.8` must not widen those JSON
surfaces while implementing the first skeleton emitter.

## Diagnostics

The first implementation must fail closed before creating artifacts for:

- unsupported verification target values;
- missing `--verification-outdir`;
- incompatible option combinations;
- non-`.isf` source suffixes;
- `.isf` sources with no `verification_observations[]`;
- unsupported observation roles; and
- artifact-path collisions that would overwrite two generated files with
  different contents.

Diagnostics must identify the requested target, source path, and artifact
directory when those values are available.

## Validation Boundary

Required regression gates for `.8` are:

- Perl syntax checks for touched CLI/support/generator modules;
- a focused verification-output CLI test using
  `isf/verification_observation_metadata.isf`;
- manifest JSON shape and artifact path checks;
- generated package content checks for package/class names, UVM 1.2 skeleton
  shape, observed signal fields, and selected static metadata;
- negative checks proving the absence of `run_phase`, virtual interfaces,
  `uvm_config_db`, sampling, publication, agent, scoreboard, coverage, and VIP
  behavior;
- support-accounting and capability-manifest tests; and
- mdBook, Knowledge Map, docs-path, memory-architecture, diff, and doctrine
  gates.

Local `verilator`, `yosys`, and `iverilog` installations are not selected as
UVM compile validators for this slice. They do not by themselves provide a
tracked UVM-aware compile environment for the generated package. The first
implementation may not claim UVM compile-clean support.

## Non-Goals

- No generated verification files are emitted in `.7`.
- No parser, scheduler, CLI, support-accounting, manifest, report, or
  generated artifact behavior changes in `.7`.
- No direct `.fsm` or `.ppif` verification-output route is selected here.
- No VHDL/PSL/testbench verification output is selected here.
- No UVM agent, sequencer, driver, env, test, scoreboard, coverage collector,
  transaction sampler, event inference, virtual-interface binding, reusable
  VIP, or protocol checker is selected here.
- No UVM compile/lint support claim is selected here.

## Rollback

Rollback is documentation-local: remove this selector, restore `.7` as the
pending public-surface selector, remove `.8`, and return README, ROADMAP,
mdBook, Memory, downstream notes, and Knowledge Map wording to the prior
state. Because `.7` emits no code or artifacts, rollback does not affect
runtime behavior.
