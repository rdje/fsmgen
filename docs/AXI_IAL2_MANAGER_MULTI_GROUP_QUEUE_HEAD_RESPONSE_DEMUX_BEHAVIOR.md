# AXI IAL2 Manager Multi-Group Queue-Head Response-Demux Behavior

Status: shipped.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.124`

## Summary

This slice ships generated read burst-last queue-head response-demux behavior
for multiple independent duplicate concrete read-ID groups. It widens the
previous one-group read burst-last behavior without changing read-data,
write-family, read single-beat, deeper-queue, direct-backend, or VHDL
coverage.

The public support-accounted sample is:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif
./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_read_multi_group_same_id_queue_head_response_demux.sv ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif
```

## Supported Shape

The supported boundary is deliberately narrow:

- read family only;
- `response-demux.read.response-scope burst-last`;
- no `read-data` clause;
- two or more duplicate concrete read-ID groups;
- exactly two read transactions in each duplicate concrete-ID group;
- computed queue depth 2 for every generated group;
- selected `same-id-ordering.read concrete-id-reuse issue-order-queue`;
- no same-family `auto-id-lifecycle` response demux;
- one family-wide admitted-request mutual-exclusion assertion across all
  selected read request events.

The checked-in sample uses `r0`/`r1` with concrete `RID` `3` and `r2`/`r3`
with concrete `RID` `5`.

## Generated Behavior

FSMGen generates one compact one-hot queue per duplicate concrete read ID.
Each generated queue has its own concrete-ID-scoped storage, transition rules,
queue assertions, and queue-head response-demux rules.

For `RID` `5`, the generated response-demux rule shape is:

```lisp
(rule axi0_r2_response_demux
  (& axi0_read_complete (== axi0_rid 4'd5) axi0_rlast
     axi0_read_id5_same_id_issue_order_slot0_r2_q)
  (pulse axi0_r2_complete))
```

The existing family-wide admitted-request boundary is unchanged. The generated
sample still reports one `axi0_read_issue_order_queue_request_onehot0`
assertion across `axi0_r0_request`, `axi0_r1_request`, `axi0_r2_request`, and
`axi0_r3_request`; the slice does not claim simultaneous group-local enqueue
support for different concrete IDs.

## Report Contract

Schedule JSON reports both queue groups under
`response_demux.read.same_id_issue_order_queues`:

```text
response_demux.read.generated_behavior: true
response_demux.read.generated_queue_behavior_boundary:
  generated_read_burst_last_queue_head_demux
response_demux.read.generated_completion_signals:
  axi0_r0_complete
  axi0_r1_complete
  axi0_r2_complete
  axi0_r3_complete
response_demux.read.same_id_issue_order_queues:
  - concrete_id: 3
    transactions: [r0, r1]
    depth: 2
  - concrete_id: 5
    transactions: [r2, r3]
    depth: 2
response_demux.residue:
  read_data_interleaving
  bursts
```

The same-ID policy report lists both generated queue groups and marks
`accepted_same_id_reuse` and `generated_queue_behavior` true. The
ID/response rule-engine residue removes `same_id_ordering` and
`response_demux` for the covered response-demux behavior, leaving the broader
auto-ID allocation/release residue.

## Deferred

The slice still fails closed or defers:

- read-data consumption over multiple queue-head groups;
- queue groups deeper than two slots;
- same-family mixed auto-ID plus concrete queue-head response demux;
- write-family multiple-group queue-head behavior;
- read single-beat multiple-group queue-head behavior;
- generalized per-ID issue-order queues;
- packed burst-vector outputs and alternate payload assembly;
- direct backend lowering;
- VHDL.

## Validation

The slice was validated with focused generator and PPIF/CLI tests; direct
schedule JSON, strict check JSON, strict semantic JSON, and `--verify-hdl`
probes for the new public sample; preservation probes for existing one-group
read burst-last, read single-beat, write, queue-head read-data, queue-head
burst-length, queue-head runtime-validation, and queue-head multi-beat
read-data samples; support accounting; mdBook; documentation path audit;
Knowledge Map generation/check; memory architecture; diff hygiene; README
numbering; and frontier scans.
