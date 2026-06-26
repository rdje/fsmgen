# IAL1 VHDL Observation Package Contract Selection

## Metadata

- Owner leaf: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.10`
- Date: `2026-06-26`
- Status: `complete`
- Selected next owner: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.11`

## Decision

The first VHDL-oriented verification artifact is an inert VHDL observation
metadata package skeleton.

The selected future CLI target is:

```text
./bin/fsmgen --emit-verification-output vhdl-observation-package \
  --verification-outdir DIR source.isf
```

The canonical target id is:

```text
vhdl_observation_package_skeleton
```

The selected artifact consumes only shipped `.isf` passive observation
metadata in `verification_observations[]`. It does not generate VHDL
assertions, PSL, a testbench, a monitor process, a scoreboard, coverage, a
reusable VIP package, or direct IAL2 protocol behavior.

## Artifact Layout

The selected future output directory layout is:

```text
DIR/
  verification-output-manifest.json
  vhdl/
    <actor>_observation_vhdl_pkg.vhd
```

The package name is actor-derived:

```text
<actor>_observation_vhdl_pkg
```

The package body is not generated. The artifact is a declaration-only package
with static metadata constants derived from `verification_observations[]`.

For each observation, the package may emit constants equivalent to:

```text
<OBS>_OBSERVATION_NAME
<OBS>_OBSERVATION_ROLE
<OBS>_OBSERVATION_CLOCK
<OBS>_OBSERVATION_RESET
<OBS>_SIGNAL_COUNT
<OBS>_SIGNAL_<N>_NAME
<OBS>_SIGNAL_<N>_DIRECTION
<OBS>_SIGNAL_<N>_WIDTH
```

Identifiers must be sanitized deterministically. Signal metadata must preserve
the source order already reported by `verification_observations[].signals[]`.

## Validation Contract

The first implementation must use the substrate selected by
`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.9`: artifact-shape and
inert-behavior checks only.

The generated manifest must include VHDL-specific validation non-claims
equivalent to:

```text
claimed_vhdl_compile_support: false
vhdl_syntax_validator: none
claimed_psl_support: false
psl_validator: none
artifact_shape_checked: true
inert_behavior_checked: true
```

The implementation must not claim VHDL syntax, compile, GHDL, NVC, `vcom`,
PSL, simulation, formal, coverage, scoreboard, reusable VIP, or analyzer
support.

## Capability Manifest

The implementation owner must widen the `verification_outputs` capability
manifest deliberately and with tests. The target entry must advertise:

```text
id: vhdl_observation_package_skeleton
cli_target: vhdl-observation-package
source_suffixes: [.isf]
requires_verification_observations: true
artifact_language: vhdl
artifact_relpath_pattern: vhdl/<actor>_observation_vhdl_pkg.vhd
manifest_relpath: verification-output-manifest.json
status: selected_pending_implementation
```

If implementation `.11` ships the target, the status must become
`shipped_bounded_public`. The manifest key-family contract must be widened only
for fields that the new artifact and validation metadata actually emit.

## Support Accounting

The selected future support-accounting entry is:

```text
id: feature.isf_verification_observation_vhdl_package_skeleton
relpath: isf/verification_observation_metadata.isf
family: language_feature_fixture
classification: supported_smoke
coverage: isf_verification_output_vhdl_observation_package_skeleton_cli
source_kind: isf
strict_supported: true
```

This entry must be separate from the report-only observation metadata fixture
and the UVM passive-monitor skeleton fixture.

## Required Implementation Gates

`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.11` must at least prove:

- CLI acceptance for `--emit-verification-output vhdl-observation-package
  --verification-outdir DIR source.isf`;
- rejection of missing `--verification-outdir`, unsupported sources, sources
  without passive observation metadata, and incompatible HDL/report options
  before writing artifacts;
- artifact path `vhdl/<actor>_observation_vhdl_pkg.vhd`;
- manifest target `vhdl_observation_package_skeleton`;
- package name and metadata constants for observation name, role, clock, reset,
  signal names, directions, and widths;
- absence of VHDL assertions, PSL, testbench entities, processes, monitor
  behavior, sampling, publication, scoreboards, coverage, reusable VIP, and
  direct IAL2 protocol behavior;
- capability-manifest discovery and support-accounting coverage; and
- mdBook, Knowledge Map, docs path, memory, diff, and doctrine gates.

## Non-Goals

- `.10` does not implement the VHDL package generator or CLI target.
- `.10` does not select VHDL assertion, PSL, testbench, process, monitor,
  scoreboard, coverage, reusable VIP, direct IAL2, GHDL, NVC, `vcom`,
  simulator, formal, analyzer, or syntax validation behavior.
- `.10` does not change the shipped UVM skeleton target or the existing
  schedule/check/semantic JSON surfaces.

## Rollback

This selector is documentation-only. If `.11` discovers that even this package
skeleton needs a smaller prerequisite, it must record that deferral in the task
tree, public docs, Memory, and Knowledge Map before implementation.
