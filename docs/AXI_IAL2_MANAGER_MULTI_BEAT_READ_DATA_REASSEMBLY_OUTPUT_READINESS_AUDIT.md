# AXI IAL2 Manager Multi-Beat Read-Data Reassembly/Output Readiness Audit

Status: completed readiness audit; no parser, generator, HDL, sample,
support-accounting, check JSON, semantic JSON, or validation behavior changed
by this note.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.73`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_METADATA_FIRST_SLICE.md](AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_METADATA_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_CONTRACT_SELECTION.md](AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_CONTRACT_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md](AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_ARLEN_CAPTURE_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_ARLEN_CAPTURE_BEHAVIOR_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md)

## Audit Question

Can the next owner emit generated AXI multi-beat read-data storage, per-beat
data/status output lanes, valid masks, length outputs, and capture rules
directly from the `.72` public output-bank metadata, or is a smaller
IAL1/IAL0/SystemVerilog prerequisite required first?

## Evidence Read

The selected public contract is already precise enough for behavior:

- `capture_scope: multi_beat`;
- `status_policy: per_beat`;
- `interleaving_policy: multi_beat_by_rid`;
- mandatory ARLEN `burst_length` with `validation runtime_assertion`;
- `output_shape: per_beat_output_bank`;
- per-transaction `generated_data_outputs` and
  `generated_status_outputs`;
- per-transaction `valid_mask_output` and `length_output`;
- `beat_match_source: response_demux_matched_read_beat`;
- `multi_beat_reassembly_generated_behavior: false`.

The existing generated behavior already supplies the prerequisites the
capture rules need:

- `.53` generated burst-last read response demux, including the raw
  read-response beat event, active transaction/RID match expression, `RLAST`
  completion pulse, and completion-pulse HDL path;
- `.66` generated raw ARLEN capture on each read request;
- `.69` generated expected-beat storage, matched-read-beat counters,
  initialization rules, increment rules, and runtime assertions for ARLEN
  bounds, extra beats, early `RLAST`, and missing final `RLAST`;
- `.60` generated last-beat `RDATA`/`RRESP` capture with ordinary held
  output assignments guarded by generated response-demux completion pulses.

The current code keeps multi-beat payload generation intentionally disabled:

- `_read_data_payload_capture_enabled` returns true only for `single_beat`
  and `last_beat`;
- `_read_data_source_inputs` emits `RDATA`/`RRESP` inputs only when payload
  capture is enabled;
- `_read_data_output_lines` emits only single-beat or last-beat
  data/status outputs;
- `_read_data_capture_rule_lines` emits only one scalar data/status capture
  rule per transaction;
- `_read_data_generated_artifacts` therefore reports ARLEN, expected-count,
  beat-count, and assertion artifacts for the `.72` sample, but no generated
  payload inputs, per-beat output lanes, valid masks, length outputs, or
  capture/reassembly rules.

Those are generator gates, not lower-layer gaps.

## Lowering Readiness

The existing IAL1/FSM/SystemVerilog path is ready for the first behavior
slice without array ports or dynamic indexed assignment:

- IAL1 interface output declarations already carry explicit widths, and the
  scheduler promotes assigned public outputs to module output ports.
- Actor-owned storage and public output registers lower through the existing
  `+size` path.
- Rule actions accept ordinary flopped assignments, including expression RHS
  values from the `.fsm` RHS expression domain.
- Rule guards can be list expressions. The scheduler records equality terms
  from expressions such as `(& MATCH (= beat_count 3))`, so lane-specific
  rules that differ by `beat_count` equality are provably mutually exclusive.
- Runtime expressions already include arithmetic, equality, logical AND/OR,
  bitwise OR, and exact-width literals. The behavior owner can therefore use
  constant full-mask values per lane instead of a dynamic shift or bit-select
  assignment.
- The shipped shift and rule-expression paths prove that raw `.fsm`
  expressions pass through to the SystemVerilog backend; no direct backend or
  VHDL path is required for this SV-backed slice.

The first behavior slice should stay within those proven primitives. It
should not introduce packed burst vectors, array outputs, dynamic indexed LHS
assignment, hidden variable-depth queues, or direct backend lowering.

## Readiness Conclusion

No new IAL1, IAL0, or SystemVerilog substrate prerequisite is required before
the first generated multi-beat read-data reassembly/output behavior slice.

The next exact owner is:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.74
```

`.74` should implement the first generated output-bank behavior for the
existing public `.72` contract.

## Selected Behavior Shape

The first generated behavior should treat the public per-beat output-bank
registers as the generated per-transaction beat storage. This matches the
selected `beat_storage: per_transaction_generated` contract while avoiding a
hidden duplicated storage bank. Later owners can still add internal queues or
packed views if a new public contract selects them.

For each generated multi-beat read transaction, `.74` should emit:

- generated `RDATA` and `RRESP` inputs when `capture_scope` is `multi_beat`;
- every generated data lane output from `generated_data_outputs`;
- every generated status lane output from `generated_status_outputs`;
- the transaction `valid_mask_output` with width `max_beats`;
- the transaction `length_output` with width `length_output_width`;
- request-time initialization that clears valid mask, length, and the output
  lanes to zero together with the existing beat-count initialization boundary;
- one capture rule per transaction per beat lane, guarded by the generated
  matched-read-beat expression, `! request_event`, and
  `beat_count_storage == lane_index`;
- capture assignments that write the current `RDATA`/`RRESP` into that lane,
  set the valid mask to the constant prefix mask for the accepted beat count,
  and set the length output to `lane_index + 1`;
- report fields that make the generated inputs, outputs, initialization
  rules, lane capture rules, and generated-behavior transition explicit.

The lane capture rule must use the current beat-count value before the
existing increment rule advances it. For beat lane `0`, the guard is the
matched read beat while `beat_count_storage == 0`; the capture writes lane
`0`, sets valid mask bit `0`, and sets length to `1`. For lane `N`, the rule
uses `beat_count_storage == N`, writes lane `N`, sets the mask to
`(1 << (N + 1)) - 1`, and sets length to `N + 1`.

The valid mask should use constant prefix values in the first slice, for
example:

```text
lane 0 -> max_beats'd1
lane 1 -> max_beats'd3
lane 2 -> max_beats'd7
```

This avoids dynamic indexing or dynamic shifts and keeps each same-target
mask/length assignment under mutually exclusive lane guards.

## Simultaneous Request/Response Boundary

The capture guard must mirror the existing beat-count increment guard:

```text
matched_read_beat && ! request_event
```

That preserves `.69` behavior. A same-cycle request for the same logical
transaction reinitializes the transaction state and must not also capture an
old beat into the just-cleared output bank. Other transactions can still
capture matched beats in the same cycle because their request guards are
transaction-local and response demux match expressions remain
transaction-local.

## Residue Movement

`.74` shipped this movement. The multi-beat sample moved from:

```text
multi_beat_read_data_reassembly
per_beat_outputs
rresp_aggregation
```

to:

```text
rresp_aggregation
```

`RRESP` aggregation remains residue because `.74` exposes per-beat status
lanes and does not select a scalar aggregate status policy. Per-ID read-data
queues, authored concrete-ID same-ID ordering beyond allocator avoidance,
queued/blocking submission policy, profile aliases, full-manager behavior,
direct backend lowering, and VHDL remain deferred.

## Diagnostics And Report Expectations

The generated rule names should be stable and transaction/lane specific. A
recommended shape is:

```text
axi0_r0_read_beat_0_capture
axi0_r0_read_beat_1_capture
...
axi0_r0_read_data_output_init
```

`.74` emits a dedicated request-time output initialization rule per covered
transaction, and the report lists that output initialization responsibility
explicitly so users can see that old lane values do not leak across requests.

Schedule JSON should change only for the multi-beat behavior fields and
artifact lists:

```text
multi_beat_reassembly_generated_behavior: true
generated_inputs:
  - axi0_rdata
  - axi0_rresp
  - axi0_arlen
generated_outputs:
  - per-beat data lanes
  - per-beat status lanes
  - valid mask outputs
  - length outputs
generated_rules:
  - request initialization rules
  - lane capture rules
  - existing ARLEN/beat-count rules
```

## Explicit Non-Goals

`.73` and the selected `.74` first behavior slice do not implement or select:

- packed burst-vector outputs;
- scalar `RRESP` aggregation;
- dynamic array output ports;
- dynamic indexed LHS assignment;
- hidden per-ID read-data queues;
- authored concrete-ID same-ID ordering queues;
- queued or blocking submission policy;
- profile aliases or full-manager syntax;
- direct backend lowering;
- VHDL backend or reroute behavior.

## Validation Gates For `.74`

The `.74` implementation should run at least:

- `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- `perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t`
- `perl -Iperl -c t/1436-ial2-ppif-parser-cli.t`
- `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t`
- `prove -Iperl t/1436-ial2-ppif-parser-cli.t`
- `prove -Iperl t/297-capability-manifest.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`
- `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_multi_beat.ppif`
- `./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_data_multi_beat.ppif`
- `./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_data_multi_beat.ppif`
- `./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen-ial2-74-multi-beat.sv ppif/axi_manager_capacity_status_read_data_multi_beat.ppif`
- compatibility schedule probes for the runtime-assertion and report-only
  burst-length samples;
- `bash knowledge-map/scripts/gen_knowledge_map.sh`
- `mdbook build docs/book`
- `prove -Iperl t/1414-docs-relative-paths-audit.t`
- `bash knowledge-map/scripts/check_knowledge_map.sh`
- `scripts/check_memory_architecture.sh`
- `git --no-pager diff --check`

## Validation Gates For `.73`

Because `.73` is documentation/task-tree audit only, validation should run at
least:

- `bash knowledge-map/scripts/gen_knowledge_map.sh`
- `mdbook build docs/book`
- `prove -Iperl t/1414-docs-relative-paths-audit.t`
- `bash knowledge-map/scripts/check_knowledge_map.sh`
- `scripts/check_memory_architecture.sh`
- `git --no-pager diff --check`

## Rollback

This audit changes only documentation, task-tree, mdBook, roadmap, memory, and
Knowledge Map state. Reverting it returns the frontier to `.73`, with `.72`
metadata shipped and generated multi-beat read-data reassembly/output behavior
still unselected.
