# AXI IAL2 Manager Dynamic Same-ID Issue-Order Queue Identity Recapture Report Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.479`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.479` ships the positive queue-owned report
surface for generated dynamic same-ID `issue-order-queue` identity recapture.

Each generated dynamic queue report entry under
`same_id_ordering.dynamic_id_reuse_policy.{read,write}.generated_queues[]`
now reports:

```text
same_transaction_recapture_policy: refresh_captured_request_id
same_transaction_recapture_rule_scope: state_key_preserving_selected_dequeue_enqueue
same_transaction_recapture_id_source: <request_id_source>
```

For the shipped bounded two-transaction dynamic queue families,
`same_transaction_recapture_id_source` is `axi0_awid` for write BID queues and
`axi0_arid` for read RID and read RID/RLAST queues.

## Evidence Boundary

`generated_update_rules` remains the literal emitted-rule evidence. The
positive fields summarize the state-key-preserving same-transaction refresh
contract, while the rule list still names concrete one-entry and tail-selected
rules such as:

```text
axi0_write_dynamic_same_id_issue_order_w0_dequeue_enqueue_w0
axi0_write_dynamic_same_id_issue_order_w1_w0_dequeue_enqueue_w0
axi0_read_dynamic_same_id_issue_order_r0_dequeue_enqueue_r0
axi0_read_dynamic_same_id_issue_order_r1_r0_dequeue_enqueue_r0
```

Queue reports do not use classic response-demux recapture vocabulary.
`same_cycle_release_recapture_policy`, `release_recapture_rule`,
`release_recapture_source`, and `release_recapture_transaction` remain
exclusive to response-demux capture-state reports.

## Static And Support Text

The enforced static-rule and unsupported-residue prose now name
state-key-preserving same-transaction captured request-ID refresh as part of
the selected generated bounded two-transaction dynamic issue-order queue
support. The text still keeps broader dynamic queue cardinality, mixed
dynamic/static queues, scoreboards, direct backend behavior, backend-language
variants, and VHDL as future exact-owner work.

## Scope Preserved

`.479` does not change parser syntax, PPIF source samples,
support-accounting catalog entries, generated sample artifacts, generated
queue transition behavior, direct backend behavior, backend-language variants,
broader queue cardinality, mixed dynamic/static queues, scoreboards, or VHDL
behavior.

## Validation

Run for closeout:

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

RAM-guarded focused generation/prove probes should run only when host memory
is below the default guard cutoff. This report-alignment slice must not bypass
the RAM guard.

## Rollback

Rollback removes the three `same_transaction_*` queue report fields, their
focused report expectations, the static/support prose alignment, this behavior
record, its Knowledge Map fact card, and the README/ROADMAP/mdBook/task-tree
and MEMORY updates. `.477` generated queue behavior remains independently
owned by its behavior record.
