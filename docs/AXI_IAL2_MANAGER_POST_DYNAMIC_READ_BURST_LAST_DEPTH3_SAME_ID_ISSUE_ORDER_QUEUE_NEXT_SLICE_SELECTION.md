# AXI IAL2 Manager Post Dynamic Read Burst-Last Depth-3 Same-ID Issue-Order Queue Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.489`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.489` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.490`, readiness audit for scalar
last-beat read-data over the generated all-dynamic read burst-last
`RID && RLAST` same-ID `issue-order-queue` depth-3 behavior shipped in
`.488`.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, generated artifact, report JSON, test, HDL/runtime behavior,
read-data behavior, mixed dynamic/static queue behavior, scoreboard behavior,
direct backend behavior, backend-language variant, external converter
dependency, arbitrary cardinality, or VHDL behavior.

## Why Read-Data Over This Queue Next

`.488` now provides the missing queue-owned response-demux prerequisite:
three all-dynamic read transactions, captured runtime `ARID` slots, generated
burst-last `RID/RLAST` completions, and the distinct
`read_rid_rlast_three_dynamic_transactions` report scope.

The nearest generated read-data precedent is the `.465` through `.473`
dynamic issue-order queue read-data chain. That chain proves scalar
single-beat and scalar last-beat read-data, report-only raw `ARLEN`,
runtime beat-count/`RLAST` validation, and multi-beat output banks for the
existing two-transaction dynamic read same-ID issue-order queue. The concrete
depth-3 queue-head chain also proves that read-data over depth-3 response
demux needs its own explicit readiness audit before implementation.

The next smallest IAL2 slice is therefore not a mixed dynamic/static queue,
scoreboard, arbitrary-cardinality change, or backend-language slice. It is a
local readiness audit asking whether the existing scalar last-beat read-data
coverage can safely widen from the two-transaction dynamic RLAST queue to the
new exactly-three-transaction dynamic RLAST queue.

## Selected Next Leaf

`.490` should audit this exact candidate:

```text
read transactions: r0, r1, r2
all transaction IDs: dynamic
same-id-ordering.read: dynamic-id-reuse issue-order-queue
response-demux.read: response-scope burst-last, generated RID/RLAST completion
response-demux.read.last-signal: one bit
transaction_completion_source: generated_dynamic_issue_order_queue_demux_last_beat
first_generated_scope: read_rid_rlast_three_dynamic_transactions
read-data.read.capture-scope: last-beat
read-data.read.completion-source: response-demux
read-data.read.status-policy: last-beat
read-data.read.interleaving: last-beat-by-rid
read-data transaction coverage: exactly r0, r1, r2
```

The selected audit should decide whether direct implementation can add one
support-accounted scalar last-beat read-data sample over the `.488` queue, or
whether a smaller coverage/report prerequisite is needed first.

## Audit Questions For `.490`

The audit should verify:

- whether `_read_data_response_demux_transaction_coverage` admits generated
  dynamic issue-order queue last-beat completions only for the two-transaction
  queue today;
- whether the lower read-data artifact generation, report projection, residue
  movement, and focused tests already iterate over the covered transaction
  list once coverage admits `r0`, `r1`, and `r2`;
- whether a temporary candidate PPIF fails closed only at a local
  dynamic-queue read-data coverage diagnostic;
- whether the existing `read-data.read` public syntax is sufficient, without
  adding parser fields; and
- which focused syntax, schedule/report, support-accounting, and guarded test
  probes the direct implementation owner would need.

## Deferred Alternatives

`.489` explicitly defers:

- read-data report-only raw `ARLEN` over depth-3 dynamic queues;
- runtime beat-count/`RLAST` validation over depth-3 dynamic queues;
- multi-beat output banks over depth-3 dynamic queues;
- mixed dynamic/static dynamic issue-order queues;
- dynamic scoreboards;
- arbitrary dynamic queue cardinality;
- direct backend behavior;
- backend-language variants;
- external converter dependency selection; and
- VHDL.

FSMGen-owned generation and lowering remain the default. External converters
such as `sv2v` remain optional future audit candidates only and are not
selected dependencies for this IAL2 slice.

## Validation

This selector closes with documentation and continuity gates only:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

No syntax, parser, generator, PPIF, support-accounting, schedule/check/
semantic JSON, HDL, or runtime behavior validation is claimed for `.489`
because it changes no behavior.

## Rollback

Rollback removes this selector document and its Knowledge Map fact card,
reverts the `.489` task-tree, README, ROADMAP_V2, mdBook, and Memory updates,
and returns the active frontier to `.489`. No code or runtime behavior
rollback is needed.
