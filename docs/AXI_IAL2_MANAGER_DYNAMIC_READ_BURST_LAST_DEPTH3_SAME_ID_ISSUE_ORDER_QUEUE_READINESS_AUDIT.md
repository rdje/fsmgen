# AXI IAL2 Manager Dynamic Read Burst-Last Depth-3 Same-ID Issue-Order Queue Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.487`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.487` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.488`, direct bounded implementation of
one generated all-dynamic read burst-last `RID && RLAST` same-ID
`issue-order-queue` with exactly three dynamic read transactions, generated
burst-last `RID/RLAST` response-demux completion, one-bit last signal,
`read-max-pending` at least 3, and queue depth 3.

No parser, generator, PPIF sample, support-accounting catalog, generated
artifact, report JSON, test, HDL/runtime behavior, read-data, mixed
dynamic/static queue, scoreboard, direct backend behavior, backend-language
variant, external converter dependency, arbitrary cardinality, or VHDL
behavior changes in this audit.

## Candidate Shape

The selected implementation candidate is deliberately narrow:

```text
read transactions: r0, r1, r2
all transaction IDs: dynamic
same-id-ordering.read: dynamic-id-reuse issue-order-queue
response-demux.read: response-scope burst-last, generated RID/RLAST completion
response-demux.read.last-signal: one bit
read-max-pending: at least 3
queue depth: 3
queue groups: one generated dynamic read burst-last group
```

The public PPIF syntax already exists through the shipped two-transaction
dynamic read burst-last queue and the shipped three-transaction read
single-beat queue. `.488` should add one support-accounted PPIF sample using
the same syntax with `r0`, `r1`, and `r2`.

## Readiness Findings

The implementation boundary is local and explicit.

`_response_demux_dynamic_read_issue_order_queue_plan` already derives the
dynamic read transaction list, shared `ARID` source, read ID-family metadata,
queue group depth, and per-transaction dynamic queue state. It currently
admits exactly two all-dynamic read transactions, or exactly three only when
the raw `response_scope` is `single-beat`. `.488` should widen that local
admission to the selected `burst-last` depth-3 shape and update the diagnostic
text.

`_normalize_response_demux_read` already projects burst-last dynamic queue
plans into the required report contract:

```text
mode: bounded_dynamic_read_rid_rlast_issue_order_queue_demux_contract
response_event_role: raw_accepted_read_response_beat
transaction_completion_source: generated_dynamic_issue_order_queue_demux_last_beat
transaction_completion_semantics: earliest_matching_captured_runtime_id_and_last_signal
beat_valid_output: none
burst_length_source: rlast_only
burst_length_validation: not_generated
```

`_build_dynamic_same_id_issue_order_queue_behavior` already builds dynamic
runtime-ID queue state from the plan, but currently admits read depth 3 only
for `single_beat` entries without `last_signal`. `.488` should add the
selected `burst_last`/one-bit-`last_signal` read depth-3 branch.

Same-ID ordering report scope currently maps any read entry with `last_signal`
to `read_rid_rlast_two_dynamic_transactions`. `.488` should report a distinct
depth-3 RLAST scope for the selected shape, such as
`read_rid_rlast_three_dynamic_transactions`, while preserving the shipped
two-transaction RLAST scope.

## Helper Probe

A direct synthetic helper probe of the existing shared transition/assertion
machinery for a depth-3 dynamic read burst-last queue produced:

```text
rules=99
assertions=20
duplicates=0
tail_refresh=1
cross_disambiguated=1
nonlast_assert=1
r2_selected=1
slot2_onehot=1
```

This confirms the shared generated queue helpers already handle the depth-3
RLAST-gated shape, including the non-final no-dequeue assertion, slot2
onehot check, `r2` completion-selected-match assertion, tail-selected
same-transaction recapture, and disambiguated cross-transaction enqueue rule.

## Implementation Scope For .488

`.488` should update only:

- dynamic read issue-order queue admission for the selected depth-3
  burst-last shape;
- dynamic queue builder admission for read `burst_last` depth 3 with one-bit
  `last_signal`;
- same-ID ordering first-generated-scope reporting for read RLAST depth 3;
- one PPIF sample and support-accounting entry;
- focused t/1436, t/1437, t/1438, and t/248 expectations;
- README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map.

## Deferred Alternatives

Read-data over depth-3 dynamic queues, raw `ARLEN`, runtime beat-count/`RLAST`
validation, multi-beat output banks, mixed dynamic/static dynamic queues,
dynamic scoreboards, arbitrary dynamic queue cardinality, direct backend
behavior, backend-language variants, external converter dependency selection,
and VHDL remain deferred.

FSMGen-owned generation/lowering remains the default. External converters
such as `sv2v` are not selected dependencies in this IAL2 queue slice.

## Validation

This readiness audit ran the direct helper probe above and closed with
documentation/continuity gates. `.488` owns the generated behavior probe,
sample, support-accounting, report JSON, focused test, and syntax validation
for the implementation.

## Rollback

Rollback removes this readiness audit, its Knowledge Map fact card, and the
README/ROADMAP/mdBook/task-tree/MEMORY updates. The `.485` generated read
single-beat depth-3 behavior, `.463` generated read burst-last depth-2
behavior, and `.482` generated write depth-3 behavior remain unchanged.
