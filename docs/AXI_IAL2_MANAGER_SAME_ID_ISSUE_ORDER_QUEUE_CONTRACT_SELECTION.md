# AXI IAL2 Manager Same-ID Issue-Order Queue Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.94`

Date: 2026-06-14

## Purpose

This selector chooses the public AXI manager capacity/status source and report
contract for accepted concrete-ID same-ID reuse through issue-order queues.

It is documentation and task-tree state only. It does not change parser,
generator, `.isf`, `.fsm`, SystemVerilog, sample, support-accounting, check
JSON, semantic JSON, or validation behavior.

## Inputs Read

- `docs/AXI_IAL2_MANAGER_POST_SAME_ID_REJECT_POLICY_NEXT_SLICE_SELECTION.md`
- `docs/AXI_IAL2_MANAGER_SAME_ID_REJECT_POLICY_FIRST_SLICE.md`
- `docs/AXI_IAL2_MANAGER_SAME_ID_REUSE_POLICY_CONTRACT_SELECTION.md`
- `docs/AXI_IAL2_MANAGER_PER_ID_QUEUE_READINESS_AUDIT.md`
- `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`
- `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`
- current PPIF `same-id-ordering` parser behavior in
  `perl/FSM/Adapter/IAL2/PPIF.pm`
- current same-ID policy normalization/report behavior in
  `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- live schedule JSON for:
  - `ppif/axi_manager_capacity_status_same_id_reject_policy.ppif`
  - `ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif`
  - `ppif/axi_manager_capacity_status_read_data_multi_beat.ppif`
  - `ppif/axi_manager_capacity_status_response_demux.ppif`
- README, roadmap, mdBook, task tree, Memory, and Knowledge Map fact cards

## Live State

`.92` shipped only explicit reject policy parser/report metadata:

```text
(same-id-ordering
  (read
    (concrete-id-reuse reject)))
```

The parser still rejects `issue-order-queue` and `scoreboard` values. The
reject-policy sample reports:

```text
same_id_ordering.mode: concrete_id_reuse_policy
same_id_ordering.generated_behavior: false
same_id_ordering.concrete_id_reuse_policy.read.policy: reject
same_id_ordering.concrete_id_reuse_policy.read.generated_queue_behavior: false
same_id_ordering.residue:
  - concrete_id_same_id_ordering
  - per_id_issue_order_queues
```

Generated auto-ID samples remain a separate conservative case: they avoid
same-ID concurrency by allocation policy and assertions. They do not accept
authored concrete-ID same-ID reuse.

Current generated response demux is also not enough for authored same-ID
reuse. Matching only `RID == constant` or `BID == constant` cannot identify
which authored same-ID transaction completes first. Same-ID reuse needs queue
state and queue-head transaction identity.

## Selected Source Contract

Keep the existing AXI-profile-local `same-id-ordering` clause shape and add
one new family-local policy value:

```lisp
(same-id-ordering
  (read
    (concrete-id-reuse issue-order-queue))
  (write
    (concrete-id-reuse issue-order-queue)))
```

Each `read` or `write` arm remains optional and independent. A read
`issue-order-queue` policy does not select write behavior, and a write policy
does not select read behavior. Mixed policies are legal at the contract level:
one family may use `reject` while the other selects `issue-order-queue`.

No new public `queue-depth` source clause is selected in this first contract.
The queue is bounded by already public manager metadata, not by a hidden
unbounded implementation setting.

`scoreboard` remains unsupported until a later owner selects a broader
matching policy.

## Queue Bounds

For each selected response family and concrete ID value, the generated queue
depth must be statically bounded by:

```text
min(<family max-pending>, <number of concrete-ID transactions in that family using that ID>)
```

For reads, `<family max-pending>` is `read-max-pending`. For writes, it is
`write-max-pending`. A queue is only meaningful for concrete-ID transactions
that share one concrete ID value in the selected family.

This contract does not permit hidden unbounded queues, dynamic allocation, or
profile-global queue state. The queue is family-local, ID-value-local, and
transaction-inventory-local.

## Issue-Order Semantics

For selected concrete-ID same-ID reuse, request issue order defines response
completion order inside the selected AXI response family.

Later generated behavior must enqueue transaction identity when a transaction
request is admitted by the generated capacity/status rule matrix. It must not
enqueue a raw request event that is blocked by capacity or policy.

Later generated behavior must dequeue only when the queue-head transaction
completes through the selected response-demux completion semantics:

- write: one accepted `BID` response completes the queue head for that write
  ID value;
- read single-beat: one accepted `RID` response beat completes the queue head
  for that read ID value;
- read burst-last or multi-beat: the queue head remains selected across the
  response beats and is dequeued only on the selected last-beat completion
  event.

## Queue-Head Response Demux

Generated same-ID response demux must use queue-head transaction identity.
An ID-only match is insufficient when multiple in-flight transactions share
the same concrete ID.

The selected expectation is:

```text
raw_response_event
&& queue_for_response_id_nonempty
&& response_id == queue_head_id
=> complete queue_head_transaction
```

For same-ID transactions, the ID match chooses the per-ID queue and the queue
head chooses the authored transaction. Existing generated auto-ID response
demux by selected ID remains separate; it must not be treated as accepted
concrete-ID same-ID reuse.

## Diagnostics

Future parser/report or behavior slices must fail closed when selected
`issue-order-queue` policy lacks required metadata. At minimum:

- selected family has no declared ID family;
- selected family has zero-width IDs;
- selected family has no transaction metadata;
- selected family has no concrete-ID transactions;
- selected family has no duplicated concrete ID value;
- duplicated concrete-ID transactions do not have distinct request events;
- selected family lacks a generated response-demux completion contract that a
  queue-head demux implementation can use;
- unsupported policy values such as `scoreboard` remain selected without an
  owner;
- duplicate `same-id-ordering` clauses, duplicate family arms, or duplicate
  `concrete-id-reuse` clauses are still invalid.

If an intermediate metadata-only slice accepts the spelling before behavior,
it must not claim `accepted_same_id_reuse: true` for duplicated concrete-ID
transactions. Accepted same-ID reuse becomes true only when generated
queue-head behavior is present.

## Report Contract

The selected normalized policy value is snake_case:

```text
issue_order_queue
```

For final generated behavior, the family report vocabulary is:

```text
same_id_ordering.concrete_id_reuse_policy.<family>.policy: issue_order_queue
same_id_ordering.concrete_id_reuse_policy.<family>.enforcement: generated_issue_order_queue
same_id_ordering.concrete_id_reuse_policy.<family>.accepted_same_id_reuse: true
same_id_ordering.concrete_id_reuse_policy.<family>.generated_queue_behavior: true
same_id_ordering.concrete_id_reuse_policy.<family>.queue_depth_bound_source: max_pending_and_transaction_inventory
same_id_ordering.concrete_id_reuse_policy.<family>.enqueue_event_source: admitted_transaction_request
same_id_ordering.concrete_id_reuse_policy.<family>.dequeue_event_source: queue_head_response_completion
same_id_ordering.concrete_id_reuse_policy.<family>.response_demux_strategy: queue_head_issue_order
```

An intermediate metadata-only slice may report the selected policy, but must
use:

```text
accepted_same_id_reuse: false
generated_queue_behavior: false
implementation_status: selected_not_generated
```

until generated queue-head response-demux behavior ships.

When generated behavior covers every same-ID concrete-ID group for a selected
family, `same_id_ordering.residue` may remove the corresponding
`per_id_issue_order_queues` and `concrete_id_same_id_ordering` residue for
that covered scope. Uncovered families or unsupported scopes must keep honest
residue.

`id_response_rule_engine.residue` may remove `same_id_ordering` and
`response_demux` only for a source whose remaining ID/response behavior is
actually covered by generated queue-head response demux. Auto-ID allocation,
ID release, and unrelated response behavior remain separate residue.

## Generated Artifact Boundary

This selector generates no artifacts.

Later generated behavior may introduce:

- per-family, per-ID queue state with a static finite depth;
- queue validity/count/head/tail or equivalent bounded shift state;
- transaction-identity storage for queue entries;
- enqueue rules tied to admitted request events;
- dequeue rules tied to queue-head response completion;
- queue-head response-demux rules;
- assertions for overflow, underflow, empty response, inactive response, and
  ambiguous completion;
- report fields for generated queue state, rules, and assertions.

The first behavior remains on the SystemVerilog-backed IAL2 -> IAL1 -> IAL0
path. Direct backend lowering and VHDL remain deferred.

## Selected Next Slice

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.95`:

```text
Audit AXI same-ID issue-order queue behavior readiness.
```

The next leaf should decide whether the selected `issue-order-queue` contract
can safely ship as parser/report metadata first, must ship parser support
together with generated queue-head behavior, or requires a smaller prerequisite
such as concrete-ID response-demux refactoring, queue-state helper substrate,
or report-contract restructuring.

## Why Not Parser/Report Metadata Directly

Accepting `issue-order-queue` as a public source value is not enough to accept
same-ID reuse. If duplicated concrete-ID transactions are accepted before
queue-head response demux exists, generated completion behavior is ambiguous.
The current response-demux implementation is auto-ID-oriented and does not
already provide queue-head concrete-ID demux. A readiness audit is the smaller
safe next step.

## Why Not Add Queue-Depth Syntax Now

The first queue contract can be bounded by existing public source metadata:
family `max-pending` and the concrete transaction set. Adding a public
`queue-depth` clause now would create another configuration surface without a
demonstrated need.

## Why Not Select Scoreboard

A scoreboard is broader than AXI same-ID response issue-order. The current
gap is the minimal queue-head ordering behavior required for same-ID response
families. Scoreboards stay deferred.

## Validation For This Selector

Selector gates:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_same_id_reject_policy.ppif
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_multi_beat.ppif
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_response_demux.ppif
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
```

## Rollback Boundary

This selector changes no behavior. If `.95` finds the selected contract still
too broad, it must select the smaller prerequisite before parser, generator,
sample, support-accounting, check JSON, semantic JSON, or HDL behavior
changes.
