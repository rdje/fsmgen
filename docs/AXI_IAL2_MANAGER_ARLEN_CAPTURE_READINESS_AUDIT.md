# AXI IAL2 Manager ARLEN Capture Readiness Audit

Status: audit complete; no parser, generator, HDL, sample,
support-accounting, check JSON, semantic JSON, or validation behavior changed
by this note.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.65`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_POST_BURST_LENGTH_METADATA_NEXT_SLICE_SELECTION.md](AXI_IAL2_MANAGER_POST_BURST_LENGTH_METADATA_NEXT_SLICE_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_METADATA_FIRST_SLICE.md](AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_METADATA_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md)

## Evidence Read

The `.63` opt-in sample already carries report-only ARLEN metadata:

```text
read_data.read.burst_length_source: arlen_signal
read_data.read.burst_length_signal: axi0_arlen
read_data.read.burst_length_signal_width: 8
read_data.read.burst_length_encoding: axlen_plus_one
read_data.read.burst_length_capture: transaction_request
read_data.read.burst_length_generated_behavior: false
read_data.read.burst_length_validation: report_only
```

Generated last-beat `RDATA`/`RRESP` capture already proves:

- generated source inputs can be width-bearing IAL1 inputs;
- generated per-transaction outputs and guarded capture rules lower through
  `.fsm` to SystemVerilog;
- report artifact lists can expose generated input/output/rule names;
- the opt-in last-beat sample passes HDL verification.

Generated auto-ID lifecycle already proves:

- generated per-transaction storage variables lower through `.fsm` to HDL
  registers;
- per-transaction request events can guard generated allocation rules;
- generated priority and assertion records are accepted by the existing
  scheduler/lowering path;
- same-family auto-ID request mutual-exclusion assertions already reject
  simultaneous same-family auto-ID requests, which is the only ambiguous case
  for sampling a single ARLEN signal for multiple logical read transactions in
  one cycle.

The read response-demux path already identifies transaction completions with
`RID` plus `RLAST`, but it has no request-side length storage. That storage is
the missing prerequisite before honest beat-count/RLAST validation or
multi-beat read-data reassembly.

## Audit Conclusion

No new IAL1, IAL0, or SystemVerilog substrate prerequisite is needed for the
first generated ARLEN capture behavior slice.

The next exact owner is:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.66
```

`.66` should implement generated raw-ARLEN capture for the existing
`burst-length` contract.

## Selected Behavior Boundary For `.66`

The behavior slice should:

- add `axi0_arlen` as a generated IAL1 input with width 8 for the opt-in
  burst-length sample;
- declare one generated raw-ARLEN storage variable per covered read
  transaction, with width 8;
- emit one generated capture rule per covered read transaction, guarded by
  that transaction's request event, assigning the raw ARLEN signal into that
  transaction's storage;
- lower the generated input, storage, and rules through `.fsm` to
  SystemVerilog;
- report `burst_length_generated_behavior: true` while keeping
  `burst_length_validation: report_only`;
- expose generated ARLEN input, per-transaction storage names, and capture
  rule names in schedule JSON;
- remove `generated_burst_length_capture` from opt-in read-data residue.

The selected storage representation is raw `ARLEN`, not `ARLEN + 1`.
This keeps `.66` free of arithmetic-width questions. The report continues to
state `burst_length_encoding: axlen_plus_one`, so later validation/reassembly
owners know the expected beat count is raw ARLEN plus one.

Recommended generated names:

```text
storage:
  axi0_r0_arlen_q
  axi0_r1_arlen_q
rules:
  axi0_r0_burst_length_capture
  axi0_r1_burst_length_capture
```

Those names follow the existing `axi0_r0_*` per-transaction pattern and avoid
claiming expected-beat counter or payload-storage behavior.

## Diagnostics And Ambiguity

The existing explicit auto-ID lifecycle requirement already provides runtime
same-family request mutual-exclusion assertions for the read transactions in
the opt-in sample. `.66` should rely on that existing assertion boundary for
same-cycle multi-request ambiguity, and should not invent a new queued or
multi-AR-channel policy.

If `.66` discovers a contract shape that can use `burst-length` without the
generated auto-ID lifecycle/request mutual-exclusion substrate, it must fail
closed or stop for a narrower prerequisite. The current public sample remains
inside the generated auto-ID lifecycle shape.

## Explicit Deferrals

`.66` must not implement:

- derived expected-beat-count arithmetic;
- beat counters or beat-index state;
- missing, extra, early, or late `RLAST` validation;
- length outputs or valid outputs;
- bounded payload beat storage;
- per-beat or packed-burst outputs;
- full read-data reassembly;
- all-beat `RRESP` aggregation;
- per-ID read-data queues;
- queued/blocking policy, profile aliases, or full-manager syntax;
- direct backend lowering;
- VHDL backend or reroute behavior.

## Validation Gates For `.65`

Because `.65` is documentation/task-tree audit only, validation should run at
least:

- `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_burst_length.ppif`
- `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_last_beat.ppif`
- `bash knowledge-map/scripts/gen_knowledge_map.sh`
- `mdbook build docs/book`
- `prove -Iperl t/1414-docs-relative-paths-audit.t`
- `bash knowledge-map/scripts/check_knowledge_map.sh`
- `scripts/check_memory_architecture.sh`
- `git --no-pager diff --check`
- stale active `.65` frontier search

## Rollback

This audit changes only documentation, task-tree, mdBook, roadmap, memory, and
Knowledge Map state. Reverting it returns the frontier to `.65`, with `.64`
having selected generated ARLEN capture readiness but no direct behavior owner
recorded.
