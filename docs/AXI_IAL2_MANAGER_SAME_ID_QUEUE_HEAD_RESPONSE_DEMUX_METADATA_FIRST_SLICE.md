# AXI IAL2 Manager Same-ID Queue-Head Response-Demux Metadata First Slice

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.103`

Date: 2026-06-14

## Purpose

This slice ships parser/report metadata and static validation for the
concrete same-ID queue-head response-demux contract selected by `.102`.
It reuses the existing public `response-demux` read/write family arms and
does not generate queue state, queue-head demux rules, accepted same-ID reuse,
direct backend behavior, or VHDL.

## Public Syntax

The public surface is the existing same-ID policy plus response-demux syntax:

```lisp
(same-id-ordering
  (read
    (concrete-id-reuse issue-order-queue)))

(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope burst-last)
    (last-signal axi0_rlast (width 1))
    (transaction-completion generated)))
```

The checked-in sample is:

```text
ppif/axi_manager_capacity_status_same_id_queue_head_response_demux.ppif
```

It has two concrete read transactions, `r0` and `r1`, sharing concrete ID
value `3`. The source is accepted only as selected-not-generated metadata:
`accepted_same_id_reuse` stays false and `generated_queue_behavior` stays
false.

## Report Shape

Schedule JSON now reports:

```yaml
response_demux:
  mode: bounded_response_demux_contract
  generated_behavior: false
  read:
    mode: bounded_read_rid_queue_head_demux_contract
    generated_behavior: false
    implementation_status: selected_not_generated
    response_event: axi0_read_complete
    response_event_role: raw_accepted_read_response_beat
    response_scope: burst_last
    response_id_signal: axi0_rid
    response_id_direction: generated_input
    last_signal: axi0_rlast
    last_signal_direction: generated_input
    last_signal_width: 1
    transaction_completion_source: generated_queue_head_demux
    transaction_completion_semantics: matched_concrete_id_queue_head_and_last_signal
    queue_state_representation: compact_onehot_transaction_slots
    same_id_issue_order_queues:
      - concrete_id: 3
        transactions: [r0, r1]
        depth: 2
        dequeue_event_source: queue_head_response_demux
  residue:
    - generated_same_id_queue_head_demux
    - read_data_interleaving
    - bursts
```

The same-ID policy report also records:

```yaml
same_id_ordering:
  concrete_id_reuse_policy:
    read:
      policy: issue_order_queue
      accepted_same_id_reuse: false
      generated_queue_behavior: false
      response_demux_strategy: queue_head_issue_order
      response_demux_implementation_status: selected_not_generated
```

## Static Validation

The slice keeps existing auto-ID response-demux behavior unchanged. A
`response-demux` family now normalizes as one of two modes:

- generated auto-ID demux, when the family has selected
  `auto-id-lifecycle`;
- selected-not-generated concrete same-ID queue-head metadata, when the same
  family selects `concrete-id-reuse issue-order-queue` and has at least one
  duplicate concrete-ID group.

Static validation rejects:

- response-demux without ID-family metadata;
- response-demux without transaction metadata;
- response-demux with neither selected-family `auto-id-lifecycle` nor a
  selected same-ID queue-head contract;
- selected same-ID queue-head demux without a duplicate concrete-ID group;
- same-family auto-ID demux mixed with concrete same-ID queue-head demux;
- response-event mismatch against the top-level family completion event;
- unsupported read response scopes;
- malformed or missing one-bit `last-signal` for `burst-last`;
- `transaction-completion` values other than `generated`;
- read-data consumption of selected-not-generated concrete same-ID
  queue-head demux.

## Generated Artifacts

For the selected queue-head sample:

- admitted request pulse generation from `.98` remains present;
- concrete ID request/response assertions remain present;
- no queue state is generated;
- no queue-head response-demux rules are generated;
- transaction completion names remain authored event inputs;
- generated `.isf`, `.fsm`, and SystemVerilog behavior do not claim accepted
  concrete same-ID reuse.

## Residue

Still deferred:

- generated compact one-hot queue slots;
- generated queue-head response-demux rules;
- accepted concrete same-ID reuse;
- read-data integration for concrete same-ID queue-head demux;
- same-family mixed auto-ID plus concrete queue-head demux;
- direct backend lowering;
- VHDL.

## Validation

Focused validation for this slice:

```bash
env -u PERL5LIB perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
env -u PERL5LIB perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
env -u PERL5LIB perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t
env -u PERL5LIB perl -Iperl -c t/1436-ial2-ppif-parser-cli.t
env -u PERL5LIB prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t
env -u PERL5LIB prove -Iperl t/1436-ial2-ppif-parser-cli.t
env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_same_id_queue_head_response_demux.ppif
```

The PPIF suite has several intentionally heavy `--verify-hdl`, check JSON,
and semantic JSON paths. This slice monitored those workers during validation
and confirmed the high-RSS workers exited rather than lingering.

## Rollback Boundary

Rollback removes the selected-not-generated queue-head response-demux metadata
branch, the public sample/support-accounting entry, and focused tests. Existing
generated auto-ID write/read response-demux behavior remains the rollback
baseline.
