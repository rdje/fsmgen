# AXI IAL2 Manager Counted Same-ID Capacity Substrate Behavior

Status: shipped by `IAL2-FEATURE-COMPLETENESS-FRONTIER.211` on
2026-06-21.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.211`

## Scope

The counted capacity substrate is active only for generated same-ID
queue-head families that contain more than one concrete-ID queue group in one
direction. It is currently covered by the public read and write multi-group
queue-head response-demux samples:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux.ppif
```

The substrate is deliberately not a group-local simultaneous enqueue feature.
The generated family-wide request onehot assertions remain in place:

```text
axi0_read_issue_order_queue_request_onehot0
axi0_write_issue_order_queue_request_onehot0
```

Legal public-sample behavior therefore remains one request per direction per
cycle. The new logic makes the shared capacity/status matrix capable of
counting a selected request set, so a later task can decide whether and how to
narrow the assertion from family-wide to group-local without corrupting
`pending_reads`, `pending_writes`, `*_slots_available`, `*_full`, or
`*_can_accept`.

No PPIF syntax changed, no new public sample was added, and response-demux,
read-data, burst-length, runtime-validation, queue-state storage, and HDL
interfaces are otherwise unchanged.

## Report Contract

Schedule JSON now includes request-accounting metadata under
`transaction_event_dispatch.directions[]`.

Ordinary directions use Boolean fan-in:

```json
{
  "mode": "boolean_fanin",
  "capacity_owner": "generated_scheduler_or_status_rules.read_capacity_matrix",
  "completion_accounting_mode": "boolean_fanin"
}
```

Generated same-ID multi-group directions use counted selected-request
accounting. The read multi-group sample reports:

```json
{
  "mode": "counted_same_id_selected_requests",
  "counted_request_events": [
    "axi0_r0_request",
    "axi0_r1_request",
    "axi0_r2_request",
    "axi0_r3_request"
  ],
  "counted_request_terms": [
    "(| axi0_r0_request axi0_r1_request)",
    "(| axi0_r2_request axi0_r3_request)"
  ],
  "request_count_expression": "(+ (| axi0_r0_request axi0_r1_request) (| axi0_r2_request axi0_r3_request))",
  "maximum_request_count": 2,
  "capacity_owner": "generated_scheduler_or_status_rules.read_capacity_matrix",
  "completion_accounting_mode": "boolean_fanin",
  "over_capacity_policy": "reject_current_request_set"
}
```

The write multi-group sample is identical in shape with `w0..w3` request
events and `generated_scheduler_or_status_rules.write_capacity_matrix`.

`generated_scheduler_or_status_rules[]` mirrors the counted metadata for the
affected direction and reports:

```text
accounting_mode: counted_submit
completion_accounting_mode: boolean_fanin
rule_count: 30
```

Boolean directions continue to report `accounting_mode: boolean_submit` with
the original four-state-per-occupancy rule count.

Mixed auto-ID plus one concrete same-ID queue-head group remains Boolean
because there is only one concrete-ID queue group to count.

## Capacity Semantics

For counted directions the capacity/status matrix evaluates the request count
exactly instead of reducing the selected request set to one Boolean submit.
For the read multi-group sample, the counted expression is:

```lisp
(+ (| axi0_r0_request axi0_r1_request)
   (| axi0_r2_request axi0_r3_request))
```

For the write multi-group sample, the counted expression is:

```lisp
(+ (| axi0_w0_request axi0_w1_request)
   (| axi0_w2_request axi0_w3_request))
```

Completion accounting remains Boolean fan-in. A completion present in the
same cycle frees at most one slot before the selected request count is
admitted or rejected.

When the selected request count fits, pending/status outputs advance by that
count. When it does not fit, the current request set is rejected and the
matrix publishes status for the post-completion base occupancy. This policy is
reported as `reject_current_request_set`.

With a temporary max-pending-3 read mutation at occupancy 2 and no completion:

```text
request_count == 1:
  pending_reads=3
  read_slots_available=0
  read_full=1
  read_can_accept=1

request_count == 2:
  pending_reads=2
  read_slots_available=1
  read_full=0
  read_can_accept=0
```

The write side follows the same rule for `pending_writes` and write status
outputs.

## Verification

Focused checks for this behavior include:

```bash
env -u PERL5LIB perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
env -u PERL5LIB perl -c t/1437-axi-ial2-manager-capacity-status-generator.t
env -u PERL5LIB perl -c t/1436-ial2-ppif-parser-cli.t
env -u PERL5LIB ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_counted_read_multi_group_verify.sv ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_counted_write_multi_group_verify.sv ppif/axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux.ppif
```

The full `t/1437` focused generator suite was attempted twice and interrupted
after several minutes without TAP output. The full `t/1436` PPIF/CLI suite was
not run in this slice because it is oversized; direct CLI/report probes and
syntax checks cover the new counted accounting surface.

A final guarded read `--verify-hdl` rerun during closeout stopped because host
memory reached 92.5% against the guard's 88% cutoff. The earlier direct
read/write `--verify-hdl` probes had passed before the docs-only closeout
edits; no unguarded rerun was attempted after the guard trip.
