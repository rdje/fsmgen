# AXI IAL2 Manager Post-Read-Data Next Slice Selection

Status: selection complete; no parser/generator/HDL behavior changes in this
slice.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.48`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

This selector follows
[docs/AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md).

## Post-`.47` State

Generated single-beat read-data capture is now shipped for explicit bounded
`read-data` contracts. The checked-in read-data sample reports:

```text
read_data.generated_behavior: true
read_data.residue:
  - rlast_completion
  - bursts
  - multi_beat_read_data_reassembly

response_demux.residue:
  - read_data_interleaving
  - bursts

same_id_ordering.residue:
  - concrete_id_same_id_ordering
  - per_id_issue_order_queues
  - read_data_interleaving
  - bursts
```

The public contract is still intentionally single-beat:

- `response-demux.read.response_scope` accepts only `single-beat`;
- `read-data.read.capture_scope` accepts only `single-beat`;
- read-data validity is the generated read response-demux completion pulse;
- no authored `RLAST`, burst length, beat count, beat index, or reassembly
  state exists yet.

## Selection

The next exact slice is:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.49
```

`IAL2-FEATURE-COMPLETENESS-FRONTIER.49` is a readiness audit for AXI
burst/`RLAST` completion semantics after generated single-beat read-data
capture.

This audit is selected before multi-beat reassembly or per-ID queue behavior
because the current public surface has no reviewable definition of what a
read transaction completion means once a response contains more than one beat.
Multi-beat read-data reassembly needs that boundary first: a source syntax for
last-beat observation, report keys for burst-capable completion, generated
artifact expectations, diagnostics, and any IAL1/IAL0/SystemVerilog substrate
requirements.

## Why The Other Candidates Stay Deferred

- Multi-beat read-data reassembly depends on the selected last-beat/completion
  contract and any beat storage/counter substrate chosen by `.49`.
- Per-ID queues and authored concrete-ID same-ID ordering depend on the same
  response-completion boundary and remain broader than the next safe slice.
- Queued/blocking policy would change submit/acceptance semantics and should
  not be mixed with read-response completion semantics.
- Profile aliases and full-manager syntax widen entrypoints without closing
  the current read-side semantic gap.
- Direct backend lowering and VHDL remain deferred; the required chain stays
  `IAL2 -> IAL1 -> IAL0 -> SystemVerilog`.

## `.49` Audit Questions

The readiness audit must decide:

- whether the first burst-aware step is public contract selection,
  parser/report metadata, generated behavior, or a smaller IAL1/IAL0/SV
  prerequisite;
- whether `RLAST` is introduced as a generated read-data input, a structural
  report-only field first, or part of a broader burst contract;
- whether the completion source remains generated response demux, changes to a
  last-beat generated completion pulse, or splits beat-valid and
  transaction-complete events;
- whether the first public shape extends `response-demux`, `read-data`, or a
  new bounded burst/completion clause;
- what burst metadata is required before behavior, such as authored length,
  generated ARLEN ownership, beat counter state, or explicit fail-closed
  absence of that data;
- how `read_data.residue`, `response_demux.residue`,
  `same_id_ordering.residue`, and `unsupported_residue` should move when a
  later burst/`RLAST` subset ships;
- which diagnostics must reject missing read response-demux prerequisites,
  unsupported scopes, missing or malformed `RLAST`, absent burst length/beat
  count metadata, conflicting completion names, output collisions, and
  unsupported interleaving policies;
- which focused generator, PPIF/CLI, schedule JSON, semantic JSON,
  `--verify-hdl`, mdBook, Knowledge Map, memory, and architecture gates are
  required.

## Explicit Non-Goals

This selector does not change public syntax, parser behavior, generated
`.isf`, generated `.fsm`, HDL, support accounting, check JSON, semantic JSON,
or tests.

The `.49` audit must keep full-manager behavior, profile aliases,
queued/blocking policy, broader transaction classes, direct backend lowering,
and VHDL deferred unless it records a later exact owner.
