# AXI IAL2 Manager Post Dynamic Read Burst-Last Depth-3 Same-ID Issue-Order Queue Read-Data Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.492`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.492` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.493`, readiness audit for report-only
raw-`ARLEN` burst-length capture over the generated all-dynamic read
burst-last `RID && RLAST` same-ID `issue-order-queue` depth-3 scalar
read-data behavior shipped in `.491`.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, generated artifact, report JSON, test, HDL/runtime behavior,
external converter dependency, arbitrary-cardinality queue behavior, direct
backend behavior, backend-language variant, or VHDL behavior.

## Why Raw ARLEN Readiness Next

`.491` supplies the missing three-transaction queue-owned scalar last-beat
read-data surface:

- read transactions `r0`, `r1`, and `r2`;
- all read transaction IDs are dynamic;
- `same-id-ordering.read` uses `dynamic-id-reuse issue-order-queue`;
- `response-demux.read` uses `response-scope burst-last`;
- the queue completion source is
  `generated_dynamic_issue_order_queue_demux_last_beat`;
- the report scope is `read_rid_rlast_three_dynamic_transactions`; and
- the `read-data.read` contract captures scalar last-beat `RDATA`/`RRESP`
  for each of the three transactions.

The closest already-shipped ladder is the two-transaction dynamic queue
read-data chain:

- `.467` ships scalar last-beat read-data;
- `.469` ships report-only raw-`ARLEN` capture;
- `.471` ships runtime beat-count/`RLAST` validation; and
- `.473` ships multi-beat output banks.

That ladder suggests the smallest next owner after `.491` is not runtime
validation, multi-beat output banks, mixed dynamic/static queues, scoreboards,
arbitrary cardinality, a backend-language variant, or an external converter.
It is a local readiness audit asking whether the `.469` report-only
raw-`ARLEN` path can safely widen from the two-transaction dynamic RLAST queue
to the exact three-transaction dynamic RLAST queue read-data shape.

## Selected Next Leaf

`.493` should audit this exact candidate:

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
read-data transactions: r0, r1, r2
burst-length.source: arlen
burst-length.signal: axi0_arlen, width 8
burst-length.encoding: axlen-plus-one
burst-length.capture: request
burst-length.max-beats: 16
burst-length.validation: report-only
```

The audit should decide whether direct implementation can add one
support-accounted public sample for depth-3 dynamic RLAST queue read-data
raw-`ARLEN`, or whether a smaller coverage/report prerequisite is required.

## Audit Questions For `.493`

The audit should verify:

- whether `_read_data_response_demux_transaction_coverage` accepts the `.491`
  three-transaction queue shape only when `burst-length` is absent today;
- whether the `.469` raw-`ARLEN` helpers already enumerate covered
  transactions once the local coverage predicate admits the shape;
- whether report projection can emit `axi0_r0_arlen_q`,
  `axi0_r1_arlen_q`, `axi0_r2_arlen_q`, and matching capture rules without
  new parser syntax;
- whether a temporary candidate PPIF fails closed only at a local dynamic
  queue read-data/burst-length coverage diagnostic;
- which focused syntax, report, generated IAL1/IAL0, support-accounting, and
  RAM-guarded sample checks the implementation owner would need; and
- how the validation record should handle the existing host-memory caveats
  from `.491`.

## Deferred Alternatives

`.492` explicitly defers:

- runtime beat-count/`RLAST` validation over the depth-3 dynamic RLAST queue;
- multi-beat output banks over the depth-3 dynamic RLAST queue;
- mixed dynamic/static issue-order queues;
- scoreboards;
- same-cycle queue widening beyond the already-owned queue recapture records;
- arbitrary queue cardinality;
- verification-code generation;
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
semantic JSON, HDL, or runtime behavior validation is claimed for `.492`
because it changes no behavior.

## Rollback

Rollback removes this selector document and its Knowledge Map fact card,
reverts the `.492` task-tree, README, ROADMAP_V2, mdBook, and Memory updates,
and returns the active frontier to `.492`. No code or runtime behavior
rollback is needed.
