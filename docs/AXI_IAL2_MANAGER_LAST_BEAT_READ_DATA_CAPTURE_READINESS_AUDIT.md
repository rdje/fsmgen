# AXI IAL2 Manager Last-Beat Read-Data Capture Readiness Audit

Status: completed readiness audit; no parser, generator, HDL, sample,
support-accounting, check JSON, semantic JSON, or validation behavior changed
by this note.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.59`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_METADATA_FIRST_SLICE.md](AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_METADATA_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_BURST_READ_DATA_CONTRACT_SELECTION.md](AXI_IAL2_MANAGER_BURST_READ_DATA_CONTRACT_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md)

## Audit Question

Can generated last-beat `RDATA`/`RRESP` capture behavior be implemented
directly from the `.58` metadata contract, or does it need a smaller IAL1,
IAL0/SystemVerilog, report, or static-validation prerequisite first?

## Existing Substrate

The generated single-beat read-data behavior already provides the required
IAL1 and IAL0/SystemVerilog substrate:

- `_read_data_source_inputs` declares the configured `RDATA` and `RRESP`
  signals when `read_data.generated_behavior` is true;
- `_read_data_output_lines` declares each transaction's data/status outputs
  with inherited widths;
- `_read_data_capture_rule_lines` emits one normal guarded capture rule per
  transaction;
- `_read_data_capture_rule` lowers the assignments through the same normal
  IAL1 rule path used by the existing single-beat capture behavior;
- `_read_data_generated_artifacts` reports generated input, output, and rule
  names when generated behavior is true.

Those helpers are not single-beat-specific except for the current
normalization gate that keeps `generated_behavior` true only for
`capture_scope single_beat`.

The generated burst-last response-demux behavior already provides the required
validity source:

- `response_demux.read.response_scope` is `burst_last`;
- `last_signal` is a generated width-1 input;
- selected read transaction completion names are generated one-cycle pulse
  outputs;
- each completion pulse is guarded by the raw read response event, active
  transaction state, matching `RID`, and asserted `RLAST`;
- read capacity release and auto-ID release already use those generated
  completion pulses.

The `.58` metadata contract binds each last-beat read-data transaction to the
same generated completion pulse through `completion_signal`, reports
`completion_validity:
generated_read_response_demux_last_beat_completion_pulse`, and keeps no beat
storage, valid output, length output, or aggregation requirement.

## Conclusion

No new IAL1, IAL0/SystemVerilog, static-validation, support-accounting, or
report-schema prerequisite is required before the first generated last-beat
capture behavior slice.

The next exact owner is:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.60
```

It should implement generated last-beat `RDATA`/`RRESP` capture behavior for
the existing `.58` contract.

## Selected Behavior Boundary

The `.60` implementation should:

- make explicit last-beat read-data contracts generated behavior, not
  report-only metadata;
- declare the configured `RDATA` and `RRESP` signals as generated IAL1 inputs
  for the last-beat sample;
- declare per-transaction last-beat data/status outputs with inherited widths;
- emit one normal guarded capture rule per read transaction;
- guard each capture rule with that transaction's generated burst-last
  response-demux completion pulse;
- keep the generated completion pulse as the only validity strobe;
- report `read_data.generated_behavior: true`;
- add generated input/output/rule artifact lists under `read_data.read`;
- remove `generated_last_beat_read_data_capture` from `read_data.residue`;
- preserve existing generated single-beat read-data behavior;
- preserve generated burst-last response-demux behavior;
- keep check JSON and normalized semantic JSON support accounting for the
  existing last-beat sample;
- prove HDL reachability with `--verify-hdl`.

## Explicit Non-Goals

The `.60` implementation must not claim or implement:

- full multi-beat read-data reassembly;
- per-beat outputs or packed burst outputs;
- `RRESP` aggregation across all beats;
- `ARLEN`, expected beat-count, fixed-depth, missing-beat, or extra-beat
  validation;
- different-ID multi-beat reassembly queues;
- same-ID concrete-ID issue-order queues;
- queued or blocking submission policy;
- full AXI manager syntax;
- direct backend lowering;
- VHDL backend or reroute behavior.

## Validation Gates For `.60`

The implementation should run at least:

- `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- `perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t`
- `perl -Iperl -c t/1436-ial2-ppif-parser-cli.t`
- `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t`
- `prove -Iperl t/1436-ial2-ppif-parser-cli.t`
- `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_last_beat.ppif`
- `./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_data_last_beat.ppif`
- `./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_data_last_beat.ppif`
- `./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen-last-beat-read-data.sv ppif/axi_manager_capacity_status_read_data_last_beat.ppif`
- `prove -Iperl t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`
- `bash knowledge-map/scripts/gen_knowledge_map.sh`
- `mdbook build docs/book`
- `prove -Iperl t/1414-docs-relative-paths-audit.t`
- `bash knowledge-map/scripts/check_knowledge_map.sh`
- `scripts/check_memory_architecture.sh`
- `git --no-pager diff --check`

## Rollback

This audit changes only documentation, task-tree, mdBook, roadmap, memory, and
Knowledge Map state. Reverting it returns the frontier to `.59`, with `.58`
metadata shipped and generated last-beat capture behavior still unselected.
