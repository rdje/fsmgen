# AXI IAL2 Manager Deeper Queue-Head Groups Readiness Audit

Status: readiness audit for `IAL2-FEATURE-COMPLETENESS-FRONTIER.148` on
2026-06-16.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.148`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.149`, generated read single-beat
depth-3 concrete same-ID queue-head response-demux through a generalized
shared same-ID issue-order queue-state core.

No parser, generator, PPIF sample, support-accounting, test, generated
artifact, or HDL behavior changes are made by this audit slice.

## Evidence Read

The audit read:

- `.147` selector:
  `docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md`
- `.146` read single-beat multi-group queue-head read-data behavior:
  `docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR.md`
- `.143` read single-beat multi-group response-demux behavior:
  `docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md`
- `.140` write multi-group response-demux behavior:
  `docs/AXI_IAL2_MANAGER_WRITE_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md`
- `.124`, `.127`, `.130`, `.132`, and `.135` read burst-last multi-group
  response-demux/read-data behavior notes;
- one-group queue-head behavior, read-data, burst-length, runtime-validation,
  and multi-beat notes;
- current same-ID group detection, queue-head behavior builder, queue-state
  storage, transition, assignment, state/full, assertion, response-state,
  read-data coverage, report, residue, PPIF parser, focused generator tests,
  PPIF/CLI tests, public samples, support accounting, README, roadmap, mdBook,
  task tree, Memory, and Knowledge Map.

## Live Report Findings

Public depth-2 representatives remain generated:

```text
ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_read_data.ppif
  family=read generated=1 impl=generated_read_single_beat_queue_head_demux
  queues=3:d2[r0,r1];5:d2[r2,r3]
  read_data generated=1 mode=bounded_single_beat_read_data_contract

ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif
  family=read generated=1 impl=generated_read_burst_last_queue_head_demux
  queues=3:d2[r0,r1];5:d2[r2,r3]
  read_data absent

ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif
  family=read generated=1 impl=generated_read_burst_last_queue_head_demux
  queues=3:d2[r0,r1];5:d2[r2,r3]
  read_data generated=1 mode=bounded_last_beat_read_data_contract

ppif/axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux.ppif
  family=write generated=1 impl=generated_write_bid_queue_head_demux
  queues=3:d2[w0,w1];5:d2[w2,w3]
  read_data absent
```

Temporary depth-3 response-demux-only probes are accepted as selected
same-ID queue-head metadata, but remain selected-not-generated:

```text
/tmp/fsmgen_ial2_148_read_single_beat_depth3.ppif
  family=read generated=0 impl=admitted_request_pulses_generated
  demux_impl=selected_not_generated
  queues=3:d3[r0,r1,r2]
  check=pass semantic=pass support_accounting=unmatched

/tmp/fsmgen_ial2_148_read_burst_last_depth3.ppif
  family=read generated=0 impl=admitted_request_pulses_generated
  demux_impl=selected_not_generated
  queues=3:d3[r0,r1,r2]
  check=pass semantic=pass support_accounting=unmatched

/tmp/fsmgen_ial2_148_write_depth3.ppif
  family=write generated=0 impl=admitted_request_pulses_generated
  demux_impl=selected_not_generated
  queues=3:d3[w0,w1,w2]
  check=pass semantic=pass support_accounting=unmatched
```

Temporary depth-3 read-data probes failed closed during the `.148` audit
because generated read response-demux metadata did not yet exist for depth-3
queue-head groups:

```text
AXI manager capacity/status IAL2 contract read_data requires generated read response_demux metadata
```

Current-status note: `.149` later shipped the selected read single-beat
depth-3 response-demux shape, and `.153` later shipped its selected scalar
read-data sibling.

That diagnostic was expected during `.148`. `.149` later generated the
selected depth-3 read single-beat response metadata, and `.153` later widened
the read-data coverage gate only for one selected scalar read-data sibling.

The temporary probes were removed after use.

## Code Findings

`_same_id_duplicate_concrete_groups` can already describe deeper duplicate
concrete-ID groups. When three transactions share one concrete ID and the
family pending limit admits them, the report-visible group depth is `3`.

Generation was deliberately depth-2 specialized at the `.148` audit point:

- `_build_same_id_issue_order_queue_behavior` rejects any generated group
  whose `depth` is not exactly `2` or whose transaction count is not exactly
  `2`;
- storage allocation creates only `slot0` and `slot1`;
- `_same_id_issue_order_queue_transition_specs` destructures exactly two
  transactions and hand-enumerates the depth-2 update matrix;
- assignment, state, full, compactness, unique-slot, response-unique-head, and
  duplicate-after-dequeue helpers are specialized around slots `0` and `1`;
- response-demux response states and read-data coverage can iterate generated
  transactions after queue behavior exists, but they depend on a valid
  generated queue behavior object.

`.149` later generalized the shared queue-state helpers for the selected
one-group depth-3 read single-beat response-demux shape.

The next behavior owner is therefore not a safe one-line gate widening. It
must generalize the shared same-ID issue-order queue-state machinery first,
then expose one tightly bounded public depth-3 shape.

## Selected .149 Boundary

The implementation owner should be bounded to:

- read family only;
- `response-demux.read.response_scope single-beat`;
- generated queue-head response demux only, not read-data consumption;
- exactly one duplicate concrete read-ID group with three read transactions at
  computed depth `3`;
- selected `same-id-ordering.read concrete-id-reuse issue-order-queue`;
- compact one-hot transaction slots generalized to `slot0` through `slot2`;
- one admitted request per family per cycle, preserving the existing
  family-wide admitted-request onehot assertion;
- at most one raw read response event and one queue-head dequeue per cycle;
- deterministic next-state semantics implemented by shared helpers:
  optionally dequeue the active head on a matched queue-head response, shift
  remaining active entries toward `slot0`, append the single admitted request
  at the first free tail slot after any shift, and reject enqueue-when-full
  unless a same-cycle dequeue frees space;
- generated queue-head completion pulses only for the active head transaction
  whose concrete `RID` matches the raw response ID;
- generated compactness, slot onehot0, unique-slot, response-nonempty,
  response-unique-head, enqueue-space-or-dequeue, and duplicate-after-dequeue
  assertions generalized over all generated slots and transactions;
- schedule, check JSON, semantic JSON, generated HDL, and `--verify-hdl`
  coverage for a new public depth-3 read single-beat response-demux sample;
- preservation probes for all current depth-2 read single-beat, read
  burst-last, write, read-data, burst-length, runtime-validation, and
  multi-beat queue-head samples.

## Deferred Work

The following remain outside `.149`:

- the depth-3 scalar read-data sibling, later shipped for one selected read
  single-beat group by `.153`;
- read burst-last depth-3 response-demux;
- write depth-3 response-demux;
- multiple independent depth-3 groups in one manager object;
- mixed depth-2/depth-3 generated groups;
- group-local simultaneous same-cycle enqueue widening beyond the current
  family-wide one-admitted-request boundary;
- same-family mixed auto-ID plus concrete queue-head demux;
- packed burst-vector outputs or alternate payload assembly;
- direct backend lowering;
- VHDL.

## Diagnostics To Preserve

`.149` must preserve fail-closed behavior for:

- depth-3 read-data probes until a read-data owner widens coverage; `.153`
  later fulfilled that for one selected read single-beat scalar shape;
- write and read burst-last depth-3 probes unless explicitly selected later;
- multiple depth-3 groups and mixed depth-2/depth-3 generated groups;
- same-family mixed auto-ID plus concrete queue-head demux;
- missing generated completion metadata;
- partial read-data coverage;
- direct backend and VHDL assumptions.

## Validation Gates For .149

The implementation slice should run:

- syntax checks for touched Perl modules and tests;
- focused generator tests in
  `t/1437-axi-ial2-manager-capacity-status-generator.t`;
- focused PPIF/CLI tests in `t/1436-ial2-ppif-parser-cli.t`;
- support-accounting corpus checks if a new public sample is added;
- direct `--emit-schedule-json`, `--strict --check --json`,
  `--strict --emit-semantic-json`, generated HDL, and `--verify-hdl` probes for
  the new depth-3 public sample;
- negative schedule/check/semantic probes for depth-3 read-data at `.149`,
  write, burst-last, and multiple-group shapes that remain deferred;
- preservation probes for `.146`, `.143`, `.140`, `.135`, `.132`, `.130`,
  `.127`, `.124`, `.113`, and one-group queue-head samples;
- Knowledge Map generation/check, mdBook build, docs path audit, memory
  architecture check, diff hygiene, README numbering, and stale/positive
  frontier scans.

## Rollback Boundary

Because `.148` is audit-only, rollback is documentation, task-tree, Memory,
and Knowledge Map state only.

For `.149`, rollback should be the new public PPIF sample, support-accounting
entry, focused tests, and shared queue-state generalization that turns the
selected read single-beat depth-3 queue-head response-demux sample from
selected-not-generated into generated behavior.
