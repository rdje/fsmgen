# AXI IAL2 Manager Same-ID Reject Policy First Slice

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.92`

## Scope

This slice ships parser/report metadata and static validation for the first
explicit AXI same-ID reuse policy under `manager-capacity-status`. It does not
generate per-ID issue-order queues, scoreboards, accepted same-ID reuse
behavior, concrete-ID response demux, queued/blocking policy, full-manager
behavior, direct backend lowering, or VHDL.

## Public PPIF Syntax

The PPIF adapter now accepts one optional `same-id-ordering` clause under a
`manager-capacity-status` object:

```lisp
(same-id-ordering
  (read
    (concrete-id-reuse reject))
  (write
    (concrete-id-reuse reject)))
```

Either `read`, `write`, or both may be present. Each selected family must
contain exactly one `(concrete-id-reuse reject)` policy. Duplicate
`same-id-ordering` clauses, duplicate family arms, duplicate
`concrete-id-reuse` clauses, missing policies, unsupported families, and
unsupported values such as `issue-order-queue` or `scoreboard` fail closed.

The checked-in runnable sample is
[`ppif/axi_manager_capacity_status_same_id_reject_policy.ppif`](../ppif/axi_manager_capacity_status_same_id_reject_policy.ppif).

## Report Contract

For valid policy-only contracts, schedule JSON reports the selected policy
under `same_id_ordering` without claiming generated queue behavior:

```yaml
same_id_ordering:
  mode: concrete_id_reuse_policy
  generated_behavior: false
  concrete_id_reuse_policy:
    read:
      policy: reject
      enforcement: static_validation
      accepted_same_id_reuse: false
      generated_queue_behavior: false
  residue:
    - concrete_id_same_id_ordering
    - per_id_issue_order_queues
```

Generated `.isf`, `.fsm`, and SystemVerilog remain unchanged for valid
single-concrete-ID samples. The new report metadata is additive and is also
covered by check JSON, normalized semantic JSON, and support accounting through
`intent.ppif_axi_manager_capacity_status_same_id_reject_policy`.

## Diagnostics

Omitting the policy preserves the existing `.88` unselected-policy diagnostic
for same-family concrete-ID reuse:

```text
AXI manager capacity/status IAL2 contract concrete read ID value 3 is reused by transactions 'r0' and 'r1'; concrete same-ID reuse requires a selected same-ID ordering policy or per-ID issue-order queue
```

Selecting `reject` for that family emits a policy-specific diagnostic:

```text
AXI manager capacity/status IAL2 contract concrete read ID value 3 is reused by transactions 'r0' and 'r1'; selected same-id-ordering.read concrete-id-reuse reject policy rejects concrete same-ID reuse
```

This keeps static rejection explicit while leaving accepted same-ID reuse and
generated issue-order behavior to later task-tree owners.

## Validation

Focused validation for this slice includes:

- `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- `perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm`
- `perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t`
- `perl -Iperl -c t/1436-ial2-ppif-parser-cli.t`
- `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t`
- `prove -Iperl t/1436-ial2-ppif-parser-cli.t`
- `prove -Iperl t/297-capability-manifest.t t/301-check-json-supported-corpus.t t/303-normalized-semantic-json-supported-corpus.t`
- `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_same_id_reject_policy.ppif`

Follow-up selector `IAL2-FEATURE-COMPLETENESS-FRONTIER.93` chose
`IAL2-FEATURE-COMPLETENESS-FRONTIER.94`, AXI same-ID issue-order queue policy
contract selection, before parser/report metadata or generated queue behavior.
