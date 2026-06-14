# AXI IAL2 Manager Same-ID Issue-Order Queue Metadata First Slice

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.96`

Date: 2026-06-14

## Purpose

This slice ships metadata-first support for the AXI same-ID
`issue-order-queue` policy selected by `.94` and bounded by the `.95`
readiness audit. It accepts the selected public source spelling and reports it
honestly without accepting duplicated concrete same-ID reuse or generating
queue-head behavior.

## Source Contract

The PPIF adapter now accepts `issue-order-queue` as a `concrete-id-reuse`
value in the existing read/write `same-id-ordering` family arms:

```lisp
(same-id-ordering
  (read
    (concrete-id-reuse issue-order-queue)))
```

`reject` behavior is unchanged. `scoreboard` remains unsupported.

The runnable sample is:

```text
ppif/axi_manager_capacity_status_same_id_issue_order_queue_policy.ppif
```

It is support-accounted as:

```text
intent.ppif_axi_manager_capacity_status_same_id_issue_order_queue_policy
```

## Report Contract

Schedule JSON normalizes the source spelling to `issue_order_queue` and
reports the implementation boundary explicitly:

```yaml
same_id_ordering:
  mode: concrete_id_reuse_policy
  generated_behavior: false
  concrete_id_reuse_policy:
    read:
      policy: issue_order_queue
      enforcement: not_generated
      implementation_status: selected_not_generated
      accepted_same_id_reuse: false
      generated_queue_behavior: false
  residue:
    - concrete_id_same_id_ordering
    - per_id_issue_order_queues
```

The generated `.isf`, `.fsm`, and SystemVerilog remain unchanged for valid
metadata-only sources.

## Fail-Closed Boundary

The selected policy does not yet accept duplicated concrete same-ID
transactions. A source that selects `issue-order-queue` and reuses one
concrete ID in the selected family still fails closed with a specific
diagnostic:

```text
AXI manager capacity/status IAL2 contract concrete read ID value 3 is reused by transactions 'r0' and 'r1'; selected same-id-ordering.read concrete-id-reuse issue-order-queue policy is selected_not_generated, so concrete same-ID reuse remains unsupported until generated issue-order queue behavior ships
```

This protects users from reading metadata selection as generated queue-head
behavior.

## Deferred Behavior

Generated behavior still requires:

- admitted per-transaction request enqueue guards;
- concrete transaction queue identity state;
- per-ID queue storage and bounds;
- enqueue/dequeue rules;
- queue-head response-demux for write, read single-beat, and read burst-last
  completion;
- queue overflow/underflow and response ambiguity assertions;
- residue movement from selected-not-generated metadata to generated behavior.

Direct backend lowering and VHDL remain deferred.

## Validation

Focused gates:

```bash
perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t
prove -Iperl t/1436-ial2-ppif-parser-cli.t
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_same_id_issue_order_queue_policy.ppif
```

Broader commit gates are recorded in the task tree.
