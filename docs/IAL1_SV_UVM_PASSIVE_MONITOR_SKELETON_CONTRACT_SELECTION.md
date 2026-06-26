# IAL1 SV/UVM Passive Monitor Skeleton Contract Selection

## Metadata

- Owner leaf: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4`
- Date: `2026-06-26`
- Status: `complete`
- Selected next owner: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.7`

## Decision

The first SV/UVM verification output target is a bounded passive UVM monitor
skeleton package derived from shipped IAL1 observation metadata.

The selected target consumes only schedule-report
`verification_observations[]` entries produced by:

```lisp
(observe NAME
  (role passive_monitor)
  (signals SIG...))
```

The first generated SV/UVM artifact must be a reviewable UVM 1.2 package
skeleton, not a behavioral monitor. It may declare per-observation passive
monitor classes and signal-snapshot item classes, but it must not sample a DUT
interface, publish transactions, infer a valid/ready event, construct a
scoreboard, generate coverage, build an agent, or emit reusable VIP behavior.

This deliberately follows the source truth available today: actor-level
passive observation metadata identifies observed public interface signals and
clock/reset context, but it does not yet describe transaction boundaries,
sampling events, expected/actual stream pairing, ordering policy, coverage
intent, virtual-interface binding, or protocol-specific IAL2 facts.

## Evidence Read

- `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.2` source-readiness audit.
- `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.3` observation contract
  selection.
- `ISF-VERIFICATION-OBSERVATION-METADATA.1` implementation task tree, fixture,
  and focused tests.
- `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md` schedule-report evolution and
  `verification_observations[]` contract.
- Local UVM 1.2 source mirror:
  - `src/comps/uvm_monitor.svh`
  - `src/comps/uvm_agent.svh`
  - `src/tlm1/uvm_analysis_port.svh`

The UVM source confirms the useful split for this selector: `uvm_monitor` is
the natural base class for user-defined monitors, a passive `uvm_agent`
typically contains only a monitor but still implies agent topology, and
`uvm_analysis_port` is the normal publication channel once a monitor has a
real sampled item stream. The shipped IAL1 source currently proves only the
passive monitor identity and observed signal list, so the first target is the
monitor skeleton, not the agent, scoreboard, coverage subscriber, or publishing
runtime monitor.

## Selected Output Contract

The selected future artifact family is:

```text
uvm/<actor>_observation_uvm_pkg.sv
```

The selected package name is:

```text
<actor>_observation_uvm_pkg
```

For each `verification_observations[]` entry, the package may declare:

```text
<observation>_snapshot extends uvm_sequence_item
<observation>_monitor  extends uvm_monitor
```

The skeleton monitor may include:

- `uvm_component_utils(<observation>_monitor)`;
- the standard `new(string name, uvm_component parent)` constructor;
- static metadata for observation name, role, clock, reset, and observed
  signal names; and
- an analysis port declaration
  `uvm_analysis_port #(<observation>_snapshot) observed_ap`.

The skeleton snapshot item may include scalar/vector fields corresponding to
the observed signals with the widths published in `verification_observations[]`.

The first implementation must keep these declarations inert:

- no `run_phase`;
- no virtual interface type or `uvm_config_db` lookup;
- no sampling edge or reset behavior;
- no `observed_ap.write(...)`;
- no assertion/property/coverage body;
- no agent/env/test wrapper; and
- no scoreboard or expected/actual comparison.

Those behaviors require later exact source and output owners.

## Public Surface Route

`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.4` selects the SV/UVM target but
does not select the public CLI or artifact-emission surface. The next owner is
`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.7`, which must choose the public
CLI, artifact directory layout, report/manifest shape, support-accounting
identity, review surfaces, diagnostics, and regression gates before any
implementation emits SV/UVM files.

The expected public surface questions for `.7` are:

- whether the first command is a new verification-output option, an output
  target selector, or an artifact-manifest mode;
- whether generated verification files live under an explicit user path, a
  git-ignored artifact root, or both;
- how schedule/check/semantic JSON reports advertise generated verification
  artifacts;
- what support-accounting fixture covers the first output; and
- which validation tool, if any, is required or optional for UVM syntax smoke.

## Validation Boundary

The eventual implementation must validate:

- input schedule JSON containing at least one `passive_monitor` observation;
- artifact names derived from actor and observation identifiers;
- UVM 1.2 import/include shape;
- monitor and snapshot class declarations;
- absence of sampling, publishing, driver, sequencer, agent, scoreboard,
  coverage, and VIP behavior; and
- diagnostics for missing or unsupported observation metadata.

If a local SV parser or UVM-aware compiler is unavailable, `.7` must make the
validation fallback explicit before implementation. Plain generated text tests
alone are not enough to claim UVM compile support.

## Non-Goals

- No generated SV/UVM code is emitted in `.4`.
- No public CLI, report, or support-accounting behavior changes in `.4`.
- No VHDL/PSL/testbench verification artifact is selected here.
- No direct IAL2-to-verification route is selected here.
- No transaction object extraction, event sampling policy, virtual-interface
  binding, scoreboarding, coverage, reusable VIP, or protocol checker behavior
  is selected here.

## Rollback

Rollback is documentation-local: remove this selector record, revert the `.4`
task-tree closeout, restore README/ROADMAP/mdBook/Memory/Knowledge Map wording
to `.4` as pending, and leave `ISF-VERIFICATION-OBSERVATION-METADATA.1`
untouched.
