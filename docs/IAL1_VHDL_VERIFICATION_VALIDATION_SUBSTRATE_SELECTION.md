# IAL1 VHDL Verification Validation Substrate Selection

## Metadata

- Owner leaf: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.9`
- Date: `2026-06-26`
- Status: `complete`
- Selected next owner: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.10`

## Decision

The first VHDL verification validation substrate is a deliberately limited
artifact-shape and inert-behavior gate with explicit manifest honesty. It does
not use GHDL, NVC, ModelSim/Questa `vcom`, PSL analysis, simulation,
elaboration, or syntax compilation.

This substrate may support a future inert, reviewable VHDL-oriented
verification skeleton only if that artifact records target-specific validation
metadata equivalent to:

```text
claimed_vhdl_compile_support: false
vhdl_syntax_validator: none
claimed_psl_support: false
psl_validator: none
artifact_shape_checked: true
inert_behavior_checked: true
```

Future implementation work may choose exact JSON spelling in the
`verification-output-manifest.json` contract, but it must preserve those
claims. If the future artifact is not inert, or if it claims VHDL/PSL syntax,
compile, simulation, formal, or analyzer support, this substrate is
insufficient and a new validation owner must be selected first.

`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.10` now owns selection of the
first VHDL-oriented verification artifact under this substrate.

## Evidence Read

- `.5` selector record:
  `docs/IAL1_VHDL_VERIFICATION_OUTPUT_CONTRACT_SELECTION.md`.
- VHDL scope:
  `docs/VHDL_SCOPE.md`.
- GHDL backlog and blocker summaries in `README.md`,
  `ROADMAP_V2.md`, and `docs/book/src/14-feature-backlog.md`.
- Direct VHDL fact card:
  `docs/knowledge/direct-vhdl-scaffold.md`.
- VHDL deferral fact card:
  `docs/knowledge/vhdl-deferred-until-sv-ial-complete.md`.
- External validation contract:
  `perl/FSM/Support/HDLExternalValidationContract.pm`.
- Verification-output manifest contract:
  `perl/FSM/Support/VerificationOutputsContract.pm`.
- Existing inert UVM skeleton implementation and tests:
  `perl/FSM/VerificationOutput/UVM/PassiveMonitorSkeleton.pm` and
  `t/1464-isf-verification-output-uvm-passive-monitor.t`.
- Capability manifest evidence from `./bin/fsmgen --capability-manifest`.
- Local tool probes for `ghdl`, `nvc`, `vcom`, `verilator`, and `yosys`.

## Candidate Substrates

### GHDL Syntax Validation

Rejected for the first VHDL verification-output substrate in this slice.
Repository docs and tests already record that GHDL validation is deferred, and
the local selector environment still has no `ghdl` executable. Choosing GHDL
as the first substrate would leave the immediate VHDL verification-output lane
blocked on an unavailable tool and would conflate an inert artifact skeleton
with a real VHDL validation lane.

GHDL remains the right future owner for any claim of VHDL syntax, elaboration,
or simulation validation.

### PSL-Aware Validation

Rejected for the first substrate. The current IAL1 observation metadata does
not select PSL syntax, property binding, clocking, reset policy, sampling
semantics, or tool behavior. No PSL-aware analyzer or simulator is selected in
the repository validation contract. Any PSL sidecar, inline PSL, or
property-bearing VHDL artifact needs a later exact owner.

### VHDL Package/Testbench Syntax Validation

Rejected for the first substrate because it still requires a VHDL analyzer or
simulator such as GHDL, NVC, or `vcom`; none is available in the local selector
environment. The current VHDL scope also keeps VHDL package emission deferred
for synthesizable HDL, so a verification package/testbench artifact must not
borrow package-readiness claims from the RTL backend.

### Artifact-Shape And Inert-Behavior Validation

Selected.

This is the only immediately honest substrate because it is deterministic,
repo-local, and already matches the validation posture used by the shipped
UVM passive-monitor skeleton: generated files can be checked for exact
location, naming, manifest fields, source identity, observation projection,
and absence of runtime behavior, while the manifest clearly states that no
compile/syntax/tool support is claimed.

## Requirements For The First VHDL Artifact Selector

`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.10` must use this substrate to
select or defer the first VHDL artifact. The selector must record:

- the exact artifact family, such as a VHDL package shell, VHDL testbench
  shell, PSL sidecar placeholder, or no artifact yet;
- the CLI target value and canonical capability-manifest target id;
- output directory layout and artifact relpath pattern;
- manifest source, artifact, observation, and validation fields;
- support-accounting identity, if the selected artifact becomes a shipped
  support-accounted sample;
- focused tests that prove artifact shape, manifest shape, and absence of
  non-inert behavior;
- explicit non-claims for VHDL compile, syntax, PSL, simulation, formal,
  coverage, scoreboard, reusable VIP, and direct IAL2 behavior.

## Non-Goals

- `.9` does not implement a CLI target, generator, manifest field, support
  entry, parser feature, scheduler report field, VHDL backend feature, or
  generated artifact.
- `.9` does not select a VHDL assertion, PSL sidecar, VHDL package, VHDL
  testbench, monitor shell, scoreboard, coverage collector, reusable VIP, or
  direct IAL2 route.
- `.9` does not claim GHDL, NVC, `vcom`, VHDL compile, VHDL syntax, PSL,
  simulation, formal, or analyzer support.

## Rollback

This selector is documentation-only. If a future slice installs or selects a
real VHDL analyzer first, create a new task-tree-owned selector that supersedes
this shape-only substrate before any artifact implementation claims syntax,
compile, simulation, or PSL validation.
