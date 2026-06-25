# AXI IAL2 Manager Dynamic Same-ID Issue-Order Queue Identity Recapture Report Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.478`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.478` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.479`, direct public report/static alignment
for the generated dynamic same-ID `issue-order-queue` identity-recapture
behavior shipped in `.477`.

The next implementation should add positive queue-owned report fields under
each generated dynamic queue entry:

```text
same_id_ordering.dynamic_id_reuse_policy.{read,write}.generated_queues[]
```

It should not add classic response-demux `release_recapture_*` or
`same_cycle_release_recapture_policy` fields to queue reports.

## Selected Public Fields

`.479` should add queue terminology, not response-demux terminology:

```text
same_transaction_recapture_policy: refresh_captured_request_id
same_transaction_recapture_rule_scope: state_key_preserving_selected_dequeue_enqueue
same_transaction_recapture_id_source: <request_id_source>
```

For the existing public generated dynamic queue families, the ID source is:

- `axi0_awid` for write BID dynamic issue-order queues; and
- `axi0_arid` for read RID and read RID/RLAST dynamic issue-order queues.

`generated_update_rules` remains a literal list of emitted rule names. The new
fields are the positive summary contract; the rule list remains the concrete
evidence and should continue to include one-entry and tail-selected refresh
forms such as:

```text
axi0_write_dynamic_same_id_issue_order_w0_dequeue_enqueue_w0
axi0_write_dynamic_same_id_issue_order_w1_w0_dequeue_enqueue_w0
axi0_read_dynamic_same_id_issue_order_r0_dequeue_enqueue_r0
axi0_read_dynamic_same_id_issue_order_r1_r0_dequeue_enqueue_r0
```

## Static And Support Text

`.479` should align the static-rule and unsupported-residue prose so users can
see that generated bounded two-transaction dynamic issue-order queues support
same-transaction identity recapture by refreshing the captured request ID.

The static/support text should keep the boundary narrow:

- generated dynamic write BID issue-order queues;
- generated dynamic read single-beat RID issue-order queues;
- generated dynamic read burst-last RID/RLAST issue-order queues; and
- read-data consumers that reuse those generated dynamic read queue
  completions.

The text should not claim broader queue cardinality, mixed dynamic/static
queues, scoreboards, direct backend behavior, backend-language variants, or
VHDL.

## Tests

`.479` should update focused generator, PPIF adapter, and dynamic-ID report
expectations to assert the new queue fields for write, read single-beat, read
burst-last, and read-data-consuming samples.

The checks should preserve the negative contract that queue reports do not gain
`same_cycle_release_recapture_policy`, `release_recapture_rule`,
`release_recapture_source`, or `release_recapture_transaction`.

## Validation Plan

`.479` should run:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -c t/1436-ial2-ppif-parser-cli.t
perl -c t/1437-axi-ial2-manager-capacity-status-generator.t
perl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

Where host memory allows, it should also run RAM-guarded focused `fsmgen` and
focused `prove` probes for the generated dynamic write/read/read-data queue
samples. The RAM cutoff must not be bypassed for this report-alignment slice.

## Non-Goals

`.478` does not change parser syntax, report JSON, static prose, PPIF samples,
support-accounting catalog entries, generated artifacts, tests, HDL/runtime
behavior, direct backend behavior, backend-language variants, broader queue
behavior, scoreboards, mixed dynamic/static queues, or VHDL behavior.

## Rollback

Rollback removes this contract-selection document, its Knowledge Map fact card,
and the README/ROADMAP/mdBook/task-tree/MEMORY updates. No generated behavior
or report surface changed in `.478`.
