# IAL1 VHDL Verification Output Contract Selection

## Metadata

- Owner leaf: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.5`
- Date: `2026-06-26`
- Status: `complete`
- Selected next owner: `IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.9`

## Decision

No VHDL-oriented verification output artifact is selected yet.

`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.5` audited the current VHDL
generation and validation surface and found that the repository can emit a
bounded synthesizable VHDL scaffold, but does not yet have a selected VHDL
verification artifact contract or a VHDL verification validation substrate.
The next smaller prerequisite is therefore
`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.9`, which must select how a future
VHDL verification artifact would be validated before any VHDL assertion,
testbench, PSL, package, or monitor-like output is implemented.

This keeps the verification-output lane honest: the shipped verification-output
target remains the inert SystemVerilog/UVM passive-monitor skeleton selected
by `.4`, surfaced by `.7`, and implemented by `.8`.

## Evidence Read

- `docs/VHDL_SCOPE.md`.
- `docs/knowledge/direct-vhdl-scaffold.md`.
- `docs/knowledge/vhdl-deferred-until-sv-ial-complete.md`.
- `perl/FSM/Support/HDLExternalValidationContract.pm`.
- `perl/FSM/Support/HDLExternalValidation.pm`.
- `perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm`.
- `perl/FSM/Backend/VHDL/StructuralRTLIREmitter.pm`.
- `t/1420-vhdl-direct-backend-scaffold.t`.
- Current CLI help and capability-manifest surfaces.
- A smoke emission of `isf/verification_observation_metadata.isf` through
  `--language vhdl`.
- Local tool availability for `ghdl`, `verilator`, and `yosys`.

## Findings

The direct VHDL path is a synthesizable scaffold, not a verification-output
path. It covers bounded direct-root and selected composition VHDL shapes
through the existing HDL pipeline. The fixture
`isf/verification_observation_metadata.isf` can lower through
`--language vhdl`, but the emitted file is a normal entity/architecture with
state, reset, and process scaffolding. It does not contain VHDL assertion,
PSL, testbench, package, monitor, observation, scoreboard, coverage, or
verification-output constructs.

The external HDL validation contract is SystemVerilog-only. It advertises
Verilator/Yosys validation for generated SystemVerilog and explicitly defers
VHDL validation until a separate GHDL validation lane is runnable, documented,
support-accounted, and regression-backed. In the local environment for this
selector, `ghdl` was not available, while Verilator and Yosys were available
for the existing SystemVerilog validation lane.

The current VHDL scope also keeps VHDL package emission, full record/array
aggregate lowering, broad expression parity, composition parity, and GHDL
validation deferred. Those boundaries matter for verification artifacts
because even an inert VHDL verification shell needs a reviewable syntax and
validation story before it can be advertised.

## Non-Selection Rationale

A VHDL assertion, PSL sidecar, VHDL testbench shell, VHDL package, or
VHDL monitor-like artifact would currently have weaker validation than the
already-shipped inert UVM skeleton. The UVM skeleton has an explicit CLI
surface, artifact manifest, support-accounting identity, generated-file shape
tests, and public documentation, while clearly not claiming UVM compile
support. No equivalent VHDL verification validation substrate has been
selected.

`verification_observations[]` is still useful future source metadata for VHDL
verification, but it identifies only passive observation names, public actor
signals, and clock/reset context. It does not select PSL syntax, VHDL assertion
style, testbench topology, package layout, simulator/analyzer expectations, or
manifest/support-accounting behavior.

## Selected Prerequisite

`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.9` must select the first VHDL
verification validation substrate before any VHDL-oriented verification output
artifact is implemented.

The prerequisite selector must audit at least:

- whether GHDL, PSL-aware analysis, or a narrower text-shape-only gate is the
  first honest validation boundary;
- which artifact family could be validated first, such as a PSL sidecar, VHDL
  package shell, or VHDL testbench shell;
- how a future artifact manifest and capability-manifest target would state
  validation limits;
- whether support accounting can distinguish generated VHDL verification
  artifacts from synthesizable VHDL HDL output;
- which user-facing docs and mdBook examples would be required before the
  first artifact ships.

## Non-Goals

- No CLI option, capability-manifest target, support-accounting entry, parser
  behavior, scheduler report, semantic/check JSON behavior, HDL backend, VHDL
  backend, UVM output, or generated artifact changes are made by `.5`.
- No VHDL assertion, PSL, VHDL testbench, VHDL package, VHDL monitor,
  scoreboard, coverage, reusable VIP, or direct IAL2 verification route is
  selected by `.5`.
- No GHDL, PSL, simulator, analyzer, or VHDL compile support is claimed.

## Rollback

This selector is documentation-only. If later evidence selects a different
VHDL prerequisite, update this record, the task tree, public docs, mdBook,
Memory, and Knowledge Map in a new task-tree-owned slice before implementing
any VHDL verification artifact.
