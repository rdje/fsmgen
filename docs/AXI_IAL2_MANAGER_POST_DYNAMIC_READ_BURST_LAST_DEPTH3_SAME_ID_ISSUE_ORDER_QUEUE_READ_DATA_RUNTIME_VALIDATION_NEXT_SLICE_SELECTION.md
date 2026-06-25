# AXI IAL2 Manager Post Dynamic Read Burst-Last Depth-3 Same-ID Issue-Order Queue Read-Data Runtime Validation Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.498`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.498` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.499`, readiness audit for multi-beat
output banks over the generated all-dynamic read burst-last `RID && RLAST`
same-ID `issue-order-queue` depth-3 runtime-validation read-data behavior
shipped in `.497`.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, generated artifact, report JSON, test, HDL/runtime behavior,
external converter dependency, arbitrary-cardinality queue behavior, direct
backend behavior, backend-language variant, verification-code output, or VHDL
behavior.

## Why Multi-Beat Readiness Next

`.497` supplies the depth-3 dynamic queue runtime-validation surface:

- read transactions `r0`, `r1`, and `r2`;
- all read transaction IDs are dynamic;
- `same-id-ordering.read` uses `dynamic-id-reuse issue-order-queue`;
- `response-demux.read` uses `response-scope burst-last`;
- the queue completion source is
  `generated_dynamic_issue_order_queue_demux_last_beat`;
- `read-data.read` captures scalar last-beat `RDATA`/`RRESP`;
- raw `ARLEN` storage and capture are generated for all three transactions;
- expected-beat storage and read-beat counters are generated for all three
  transactions; and
- six beat-count rules plus twelve beat-count/`RLAST` runtime assertions are
  generated for the depth-3 queue.

The closest shipped ladder remains the two-transaction dynamic queue
read-data sequence:

- `.467` ships scalar last-beat read-data;
- `.469` ships report-only raw-`ARLEN` capture;
- `.471` ships runtime beat-count/`RLAST` validation; and
- `.473` ships multi-beat output banks.

After `.497`, the smallest adjacent owner is therefore not mixed
dynamic/static queues, scoreboards, arbitrary cardinality,
verification-code generation, direct backend behavior, backend-language
variants, VHDL, or an external converter audit. It is a readiness audit asking
whether the `.473` multi-beat output-bank path can safely widen from the
two-transaction dynamic RLAST queue to the exact three-transaction dynamic
RLAST queue runtime-validation read-data shape.

FSMGen-owned generation and lowering remain the default. External converters
such as `sv2v` remain optional future audit candidates only and are not
selected dependencies for this IAL2 slice.

## Selected Next Leaf

`.499` should audit this exact candidate:

```text
read transactions: r0, r1, r2
all transaction IDs: dynamic
same-id-ordering.read: dynamic-id-reuse issue-order-queue
response-demux.read: response-scope burst-last, generated RID/RLAST completion
response-demux.read.last-signal: one bit
transaction_completion_source: generated_dynamic_issue_order_queue_demux_last_beat
first_generated_scope: read_rid_rlast_three_dynamic_transactions
read-data.read.capture-scope: multi-beat
read-data.read.completion-source: response-demux
read-data.read.status-policy: per-beat
read-data.read.status-aggregation: worst-observed
read-data.read.interleaving: multi-beat-by-rid
read-data transactions: r0, r1, r2
burst-length.source: arlen
burst-length.signal: axi0_arlen, width 8
burst-length.encoding: axlen-plus-one
burst-length.capture: request
burst-length.max-beats: 16
burst-length.validation: runtime-assertion
```

The audit should decide whether direct implementation can add one
support-accounted public sample for depth-3 dynamic RLAST queue multi-beat
output banks, or whether a smaller coverage/report/runtime prerequisite is
required first.

## Audit Questions For `.499`

The audit should verify:

- whether `_read_data_response_demux_transaction_coverage` currently admits
  the `.497` three-transaction queue shape only for scalar last-beat
  runtime-validation read-data;
- whether the `.473` multi-beat helpers already enumerate covered
  transactions once the local coverage predicate admits the depth-3 shape;
- whether generated data/status lane outputs, valid-mask outputs,
  length outputs, scalar aggregate status outputs, raw-`ARLEN` storage,
  expected-beat storage, read-beat counters, output-init rules, lane-capture
  rules, aggregate-update rules, beat-count rules, and beat-count/`RLAST`
  assertions can extend to `r0`, `r1`, and `r2` without changing parser
  syntax;
- whether lane capture still uses matched raw read beats rather than the final
  queue completion pulse, while the completion pulse remains the response-demux
  transaction-completion validity;
- whether report projection can distinguish scalar runtime-validation read-data
  from bounded multi-beat output-bank read-data over the same depth-3 queue;
- whether a temporary multi-beat candidate PPIF fails closed only at a local
  dynamic queue read-data coverage diagnostic; and
- which focused syntax, report, generated IAL1/IAL0, support-accounting, and
  RAM-guarded sample checks the implementation owner would need.

## Deferred Alternatives

`.498` explicitly defers:

- direct implementation of multi-beat output banks until the `.499` readiness
  audit closes;
- mixed dynamic/static issue-order queues;
- scoreboards;
- same-cycle queue widening beyond already-owned queue recapture records;
- arbitrary queue cardinality;
- verification-code generation;
- direct backend behavior;
- backend-language variants;
- external converter dependency selection; and
- VHDL.

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
semantic JSON, HDL, or runtime behavior validation is claimed for `.498`
because it changes no behavior.

## Rollback

Rollback is documentation-only: revert this selector doc, the matching
Knowledge Map card/map entry, task-tree advancement, README/ROADMAP/mdBook
sync, and Memory pointer. No generated HDL or runtime artifact rollback is
required.
