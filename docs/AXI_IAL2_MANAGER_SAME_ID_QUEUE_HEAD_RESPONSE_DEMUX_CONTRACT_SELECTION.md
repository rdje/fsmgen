# AXI IAL2 Manager Same-ID Queue-Head Response-Demux Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.102`

Date: 2026-06-14

## Purpose

This selector chooses the public contract for concrete same-ID queue-head
response demux after `.101` selected compact one-hot queue slots. It decides
how a source asks FSMGen to turn raw `BID` or `RID` responses into generated
transaction completions for the queue head, without implementing parser,
generator, `.isf`, `.fsm`, SystemVerilog, sample, support accounting, check
JSON, semantic JSON, or validation behavior in this slice.

## Inputs Read

- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_STATE_REPRESENTATION_SELECTION.md`
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_STATE_DEMUX_READINESS_AUDIT.md`
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_REQUEST_PULSES_FIRST_SLICE.md`
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md`
- existing write/read/burst-last response-demux contract selections and
  behavior notes
- current PPIF response-demux parser in `perl/FSM/Adapter/IAL2/PPIF.pm`
- current response-demux normalization/report/rule code in
  `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- public same-ID `issue-order-queue`, write response-demux, and read
  burst-last response-demux samples
- README, roadmap, mdBook, task tree, Memory, and Knowledge Map fact cards

## Current Contract Boundary

The public syntax already has the response source information that
queue-head demux needs:

```lisp
(response-demux
  (write
    (response-event axi0_write_complete)
    (transaction-completion generated)))
```

and for reads:

```lisp
(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope burst-last)
    (last-signal axi0_rlast (width 1))
    (transaction-completion generated)))
```

However, the current implementation gives those clauses only an auto-ID
interpretation. Normalization requires `auto-id-lifecycle` metadata for the
selected family and response rules match:

```text
raw_response_event && transaction_busy && response_id == selected_id
```

Concrete same-ID queues need a different interpretation:

```text
raw_response_event && response_id == concrete_id && queue_head_is_transaction
```

The syntax can be reused, but the selected semantic source must be explicit in
the report and validation.

## Selected Public Contract

Reuse the existing `response-demux` family arms. Do not add a new top-level
`queue-demux` clause for the first concrete same-ID contract.

For a selected same-ID read queue:

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

For a selected same-ID write queue:

```lisp
(same-id-ordering
  (write
    (concrete-id-reuse issue-order-queue)))

(response-demux
  (write
    (response-event axi0_write_complete)
    (transaction-completion generated)))
```

The family arm selects concrete same-ID queue-head demux only when:

- the same response family selects
  `same-id-ordering.<family>.concrete-id-reuse issue-order-queue`;
- the family has at least one concrete-ID group that contains two or more
  concrete transactions sharing the same ID value;
- the same family does not also select generated `auto-id-lifecycle` demux in
  this first contract.

Existing auto-ID response-demux behavior remains unchanged for families that
select `auto-id-lifecycle` and do not require concrete same-ID queue-head
demux.

## Mixed-Family And Mixed-Mode Rules

Read and write remain independent. A source may use existing auto-ID write
response demux and future concrete same-ID read queue-head demux in one
manager, or the reverse, because those are separate response families.

The first same-family mixed mode is not selected. If one family contains both
auto-ID transactions requiring generated auto-ID demux and duplicate concrete
same-ID transactions requiring queue-head demux, a later owner must select
the arbitration/report model. The `.103` metadata slice should fail closed for
same-family mixed auto-ID plus concrete same-ID queue-head demux.

## Write Semantics

For a write concrete-ID group, the future demux match is:

```text
write_response_event
&& BID == concrete_id
&& queue_nonempty
&& head_is_<transaction>
```

The matching rule pulses the generated transaction completion signal for the
head transaction and produces the group's `queue_dequeue_event`.

The report mode for the selected contract is:

```text
bounded_write_bid_queue_head_demux_contract
```

## Read Semantics

For `response-scope single-beat`, the future demux match is:

```text
read_response_event
&& RID == concrete_id
&& queue_nonempty
&& head_is_<transaction>
```

For `response-scope burst-last`, the future demux match is:

```text
read_response_event
&& RID == concrete_id
&& queue_nonempty
&& head_is_<transaction>
&& RLAST
```

Matched non-last beats must not dequeue the queue and must not pulse the
transaction completion. Burst payload collection, beat-count validation, and
read-data reassembly remain separate owners.

The report mode for both read scopes is:

```text
bounded_read_rid_queue_head_demux_contract
```

## Report Contract

The `.103` metadata slice should report selected concrete queue-head demux
without claiming generated behavior:

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

For writes, use `bounded_write_bid_queue_head_demux_contract`,
`response_event_role: raw_accepted_write_response`, and
`transaction_completion_semantics: matched_concrete_id_queue_head`.

The selected same-ID policy report should remain false until behavior ships:

```yaml
accepted_same_id_reuse: false
generated_queue_behavior: false
response_demux_strategy: queue_head_issue_order
response_demux_implementation_status: selected_not_generated
```

Only a later behavior owner may set `generated_behavior: true`,
`accepted_same_id_reuse: true`, or `generated_queue_behavior: true`.

## Diagnostics

The `.103` metadata/static-validation slice should fail closed for:

- selected concrete same-ID queue-head demux without matching
  `same-id-ordering.<family>.concrete-id-reuse issue-order-queue`;
- selected family with no positive-width ID family;
- selected family with no transactions metadata;
- selected family with no duplicate concrete-ID group;
- selected same-family auto-ID lifecycle plus concrete same-ID queue-head
  demux;
- write `response-event` not equal to top-level `write-complete`;
- read `response-event` not equal to top-level `read-complete`;
- unsupported read response scopes;
- `response-scope single-beat` with a `last-signal`;
- `response-scope burst-last` without a one-bit `last-signal`;
- `transaction-completion` other than `generated`;
- generated completion names that collide with the raw response event or other
  generated/authored names;
- `read-data` attempting to consume selected-not-generated concrete same-ID
  queue-head demux.

Duplicated concrete same-ID reuse must still fail closed until generated queue
state and generated queue-head demux behavior ship together for the covered
group.

## Next Slice

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.103`:

```text
Ship AXI same-ID queue-head response-demux metadata.
```

That slice should implement parser/report metadata and static validation for
the selected contract, keep generated `.isf`, `.fsm`, SystemVerilog, accepted
same-ID reuse, generated queue state, and queue-head demux behavior unchanged,
and keep duplicated concrete same-ID reuse fail-closed with a
selected-not-generated diagnostic.

## Non-Goals

This selector does not implement:

- parser/report metadata;
- public sample/support-accounting changes;
- generated queue state;
- generated queue-head response-demux rules;
- accepted concrete same-ID reuse;
- same-family mixed auto-ID plus concrete queue demux;
- read-data integration for concrete same-ID queue demux;
- direct backend lowering;
- VHDL.

## Validation For This Selector

Selector gates:

```bash
env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_same_id_issue_order_queue_policy.ppif
env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_response_demux.ppif
env -u PERL5LIB ./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
```

## Rollback Boundary

This selector changes only durable docs/task-tree state. Rolling it back
restores `.102` as the active queue-head response-demux contract-selection
owner and does not affect generated artifacts or public CLI behavior.
