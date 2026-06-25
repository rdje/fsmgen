# AXI IAL2 Manager Dynamic Same-ID Issue-Order Queue Policy Metadata-First Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.450`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.450` implements the `.449` public
contract for metadata-first dynamic same-ID `issue-order-queue` policy.

The PPIF parser and generator now accept family-local
`(dynamic-id-reuse issue-order-queue)` under `same-id-ordering` read/write
arms:

```lisp
(same-id-ordering
  (read (dynamic-id-reuse issue-order-queue)))
```

The existing `dynamic-id-reuse reject` spelling remains supported. Dynamic
`scoreboard` remains unsupported.

## Public Sample

The new support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_dynamic_same_id_issue_order_queue_policy.ppif
```

The sample is intentionally metadata-first. It has the same generated IAL1 and
IAL0 artifacts as:

```text
ppif/axi_manager_capacity_status_dynamic_transaction_id.ppif
```

The behavior difference is the schedule/check/semantic report metadata and
support-accounting identity.

## Report Contract

For the dynamic-only read sample, the schedule report includes:

```yaml
same_id_ordering:
  mode: dynamic_id_reuse_policy
  generated_behavior: false
  dynamic_id_reuse_policy:
    read:
      policy: issue_order_queue
      implementation_status: selected_not_generated
      enforcement: not_generated
      accepted_same_id_reuse: false
      request_conflict_policy: dynamic_issue_order_queue_selected_not_generated
      generated_queue_behavior: false
      generated_scoreboard_behavior: false
  residue:
    - dynamic_id_same_id_ordering
    - dynamic_per_id_issue_order_queues
```

If a concrete same-ID policy and a dynamic same-ID issue-order policy coexist
in one family, the report mode is `id_reuse_policy` and the report carries
both `concrete_id_reuse_policy.<family>` and
`dynamic_id_reuse_policy.<family>`. The residue keeps both concrete and
dynamic work visible, including `dynamic_per_id_issue_order_queues`.

## Diagnostics

The parser and generator fail closed for unsupported or underspecified dynamic
same-ID policy inputs:

- `dynamic-id-reuse scoreboard` is rejected;
- a dynamic same-ID policy requires `transactions` metadata;
- the selected family must contain at least one same-family dynamic
  transaction;
- duplicate dynamic policy clauses remain invalid;
- dynamic transaction IDs selected with only a concrete same-ID policy now
  diagnose that the source must select either `dynamic-id-reuse reject` or
  `dynamic-id-reuse issue-order-queue`.

## Support Accounting

The new public sample is registered as:

```text
intent.ppif_axi_manager_capacity_status_dynamic_same_id_issue_order_queue_policy
```

with coverage bucket:

```text
ial2_ppif_manager_capacity_status_dynamic_same_id_issue_order_queue_policy_pipeline_cli
```

It is a strict-supported `supported_smoke` PPIF entry and is covered by the
check JSON and semantic JSON support-accounting corpus paths.

## Non-Generated Boundary

This slice does not generate dynamic same-ID queue behavior. In particular, it
does not add dynamic queue state, enqueue/dequeue rules, queue-head response
demux, accepted same-ID reuse, dynamic scoreboard behavior, HDL, VHDL, direct
backend behavior, or backend-language variants.

Generated dynamic same-ID reject mappings from `.438`, `.442`, and `.446`
remain reject-only mappings and are not reused for dynamic
`issue-order-queue`.

## Validation Notes

Focused validation for `.450` passed:

```bash
perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c t/1436-ial2-ppif-parser-cli.t
perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t
perl -Iperl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_same_id_issue_order_queue_policy.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_dynamic_same_id_issue_order_queue_policy.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_dynamic_same_id_issue_order_queue_policy.ppif
scripts/run_with_ram_guard.sh -- env FSMGEN_DYNAMIC_CASE_FILTER="dynamic same-ID issue-order queue policy metadata" env -u PERL5LIB prove -Iperl t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
scripts/run_with_ram_guard.sh -- env -u PERL5LIB prove -Iperl t/248-regression-corpus-accounting.t
```

A guarded full `t/1437-axi-ial2-manager-capacity-status-generator.t` attempt
was stopped after 18 minutes. Before termination, TAP reported that all 77
subtests had passed, but the run did not reach `done_testing`, so it is
recorded as inconclusive rather than passed.

## Next Slice

`.450` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.451`, the post-metadata
selector for the next dynamic same-ID policy slice.
