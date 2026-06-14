# AXI IAL2 Manager Same-ID Issue-Order Queue Admitted Request Pulses First Slice

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.98`

Date: 2026-06-14

## Purpose

This slice ships the admitted-request boundary selected by the `.97` audit for
AXI same-ID `issue-order-queue` policy families. It names the per-transaction
request points that later queue state can consume, without accepting duplicated
concrete same-ID reuse and without generating per-ID queue state or queue-head
response demux.

## Generated Boundary

For each concrete transaction in a family selecting:

```lisp
(same-id-ordering
  (read
    (concrete-id-reuse issue-order-queue)))
```

FSMGen emits one internal scalar storage pulse target and one rule-owned pulse.
For the public sample:

```lisp
(var axi0_r0_admitted_request_pulse_q (width 1))

(rule axi0_r0_admitted_request
  (& axi0_r0_request (| (< axi0_pending_reads_q 4) axi0_r0_complete))
  (pulse axi0_r0_admitted_request_pulse_q))
```

The guard is derived from:

- the concrete transaction request event;
- the current direction pending storage;
- the family `max-pending` bound;
- the same-cycle direction completion fan-in.

It does not read the generated `axi0_read_can_accept` or
`axi0_write_can_accept` status output.

The generated `.fsm` lowers the pulse as the existing one-cycle delayed pulse
form:

```lisp
(<1 (axi0_r0_admitted_request_pulse_q 1))
```

The pulse target remains internal storage in this slice. It is not a public
output and is not yet queue state.

## Mutual Exclusion

If a selected family has more than one concrete transaction, FSMGen emits one
runtime same-direction request mutual-exclusion assertion. For two read
transactions `r0` and `r1`, the assertion is:

```lisp
(assert (! (& axi0_r0_request axi0_r1_request))
  "axi0 read same-ID issue-order queue requests are mutually exclusive")
```

This preserves the current capacity/status shell contract: the direction-level
pending counter still accepts at most one request per direction per cycle, so
multiple concrete identities must not claim the admitted boundary in the same
cycle.

## Report Contract

Schedule JSON reports the generated admitted boundary under the selected
`same_id_ordering.concrete_id_reuse_policy.<family>` entry:

```yaml
same_id_ordering:
  mode: concrete_id_reuse_policy
  generated_behavior: false
  concrete_id_reuse_policy:
    read:
      policy: issue_order_queue
      enforcement: admitted_request_boundary
      implementation_status: admitted_request_pulses_generated
      accepted_same_id_reuse: false
      generated_queue_behavior: false
      admitted_request_boundary:
        guard_source: capacity_storage_and_completion_fanin
        pending_storage: axi0_pending_reads_q
        max_pending: 4
        completion_fanin: axi0_r0_complete
        selected_request_events:
          - axi0_r0_request
        generated_pulses:
          - transaction: r0
            tag: rd0
            concrete_id: 3
            request_event: axi0_r0_request
            pulse: axi0_r0_admitted_request_pulse_q
            rule: axi0_r0_admitted_request
            guard: (& axi0_r0_request (| (< axi0_pending_reads_q 4) axi0_r0_complete))
        generated_assertions: []
  residue:
    - concrete_id_same_id_ordering
    - per_id_issue_order_queues
```

`generated_behavior` stays false at the top-level same-ID ordering report
because accepted same-ID reuse and generated queue-head behavior are still not
implemented. `accepted_same_id_reuse` and `generated_queue_behavior` also remain
false under the selected family.

## Fail-Closed Boundary

This slice keeps duplicated concrete same-ID reuse fail-closed with the existing
selected-not-generated diagnostic. It also fails closed when an
`issue-order-queue` family has no positive ID family, no transaction metadata,
no concrete transaction in the selected family, or duplicate selected request
events.

Still deferred:

- accepted concrete same-ID reuse;
- per-ID issue-order queue storage;
- enqueue/dequeue queue state transitions;
- queue-head response demux;
- queue overflow/underflow assertions;
- scoreboard policy;
- queued/blocking policy;
- direct backend lowering;
- VHDL.

## Validation

Focused gates:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t
prove -Iperl t/1436-ial2-ppif-parser-cli.t
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_same_id_issue_order_queue_policy.ppif
```

Broader commit gates are recorded in the task tree.
