# AXI IAL2 Manager Dynamic Read Burst-Last Depth-3 Same-ID Issue-Order Queue Read-Data Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.490`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.490` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.491`, direct bounded implementation of
scalar last-beat read-data over the generated all-dynamic read burst-last
`RID && RLAST` same-ID `issue-order-queue` depth-3 behavior shipped in
`.488`.

No new public contract-selection leaf is required. The existing
`read-data.read` syntax already describes scalar last-beat `RDATA`/`RRESP`
capture from generated response-demux completions, and `.467` already proves
that syntax over the two-transaction generated dynamic RLAST issue-order
queue. The remaining blocker is local to dynamic issue-order queue read-data
coverage, which currently requires exactly two dynamic queue transactions and
a depth-2 queue.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check/
semantic JSON, HDL, runtime behavior, direct backend behavior,
backend-language variant, external converter dependency, arbitrary
cardinality, or VHDL behavior.

## Evidence Read

The audit read:

- `.489` selector.
- `.488` generated read burst-last `RID && RLAST` depth-3 dynamic queue
  behavior.
- `.487` readiness audit and `.486` selector.
- `.485` generated read single-beat `RID` depth-3 dynamic queue behavior.
- `.463` generated read burst-last `RID && RLAST` depth-2 dynamic queue
  behavior.
- `.467`, `.469`, `.471`, and `.473` generated dynamic issue-order queue
  read-data, raw-`ARLEN`, runtime-validation, and multi-beat records.
- Concrete depth-3 queue-head read-data readiness and behavior records.
- Current read-data coverage, artifact generation, report projection, residue
  movement, parser/CLI, generator-test, support-accounting, README,
  ROADMAP_V2, mdBook, Memory, task tree, and Knowledge Map surfaces.

## Current Boundary

`_read_data_response_demux_transaction_coverage` already recognizes generated
dynamic issue-order queue completion sources:

```text
generated_dynamic_issue_order_queue_demux
generated_dynamic_issue_order_queue_demux_last_beat
```

For scalar last-beat read-data, it already maps the completion validity to:

```text
generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse
```

The local gate currently requires:

```text
dynamic_transactions count: exactly 2
same_id_issue_order_queues count: exactly 1
queue depth: exactly 2
queue transactions: exactly the dynamic transaction list
generated_completion_signals count: one per transaction
```

That is the only blocker exposed by the audit. The lower read-data
normalizer, generated artifact collection, report helpers, and focused test
helpers already iterate over the covered transaction list after coverage
returns `r0`, `r1`, and `r2`.

## Temporary Candidate Probe

A temporary candidate PPIF under `/tmp` added scalar last-beat read-data
bindings for `r0`, `r1`, and `r2` to
`ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue.ppif`.

The RAM-guarded probe failed closed at the expected local diagnostic:

```text
AXI manager capacity/status IAL2 contract read_data.read dynamic issue-order queue coverage requires generated dynamic read issue-order queue single-beat response_demux with capture_scope single-beat and no burst_length metadata, generated dynamic read issue-order queue burst-last response_demux with capture_scope last-beat and no burst_length metadata, generated dynamic read issue-order queue burst-last response_demux with capture_scope last-beat and report-only/runtime-assertion burst_length metadata, or generated dynamic read issue-order queue burst-last response_demux with capture_scope multi-beat and runtime-assertion burst_length metadata in this slice
```

The candidate parsed far enough to reach the normalized read-data coverage
gate. No parser syntax, PPIF shape, IAL1, IAL0, SystemVerilog, direct backend,
backend-language, or VHDL prerequisite was exposed.

## Selected `.491` Implementation Boundary

`.491` should implement only:

- exactly three all-dynamic read transactions: `r0`, `r1`, and `r2`;
- `same-id-ordering.read (dynamic-id-reuse issue-order-queue)`;
- generated `response-demux.read` with `response-scope burst-last`, one-bit
  `last-signal`, generated transaction completion, and
  `transaction_completion_source`
  `generated_dynamic_issue_order_queue_demux_last_beat`;
- `first_generated_scope: read_rid_rlast_three_dynamic_transactions`;
- one generated dynamic read issue-order queue with depth 3 and transactions
  `r0`, `r1`, and `r2`;
- `read-data.read` with `capture-scope last-beat`,
  `completion-source response-demux`, `status-policy last-beat`,
  `interleaving last-beat-by-rid`, and scalar `data-output`/
  `status-output` bindings for all three transactions; and
- no `burst-length`, runtime beat-count/`RLAST` validation, or multi-beat
  output-bank metadata in the first depth-3 read-data owner.

The selected public sample is:

```text
ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data.ppif
```

The selected support-accounting identity and coverage bucket are:

```text
intent.ppif_axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data
ial2_ppif_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_pipeline_cli
```

## Expected Report Contract

The response-demux report should remain queue-owned:

```text
mode: bounded_dynamic_read_rid_rlast_issue_order_queue_demux_contract
transaction_completion_source: generated_dynamic_issue_order_queue_demux_last_beat
dynamic_transactions: [r0, r1, r2]
generated_completion_signals: [axi0_r0_complete, axi0_r1_complete, axi0_r2_complete]
```

The read-data report should remain the scalar last-beat contract:

```yaml
read_data:
  mode: bounded_last_beat_read_data_contract
  generated_behavior: true
  read:
    capture_scope: last_beat
    completion_source: response_demux
    completion_validity: generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse
    status_policy: last_beat
    interleaving_policy: last_beat_by_rid
    burst_length_source: rlast_only
    burst_length_validation: not_generated
    transactions: [r0, r1, r2]
    generated_inputs: [axi0_rdata, axi0_rresp]
    generated_rules: [axi0_r0_read_data_capture, axi0_r1_read_data_capture, axi0_r2_read_data_capture]
```

The read-data residue should match scalar last-beat behavior:

```text
multi_beat_read_data_reassembly
per_beat_outputs
rresp_aggregation
arlen_or_beat_count_validation
```

## Diagnostics

`.491` must fail closed when:

- the response-demux source is not
  `generated_dynamic_issue_order_queue_demux_last_beat`;
- the response scope is not `burst-last` or the one-bit `last-signal` is
  absent;
- the same-id policy is not dynamic `issue-order-queue`;
- the queue transaction list is not exactly the all-dynamic `r0`, `r1`, `r2`
  list in issue order;
- `read-data.read` omits any of `r0`, `r1`, or `r2`, duplicates a binding, or
  names an extra transaction;
- generated completion-signal count does not match the three covered
  transactions; or
- the request attempts raw `ARLEN`, runtime beat-count/`RLAST` validation,
  multi-beat output banks, mixed dynamic/static queues, scoreboards, direct
  backend behavior, backend-language variants, external converter dependency
  selection, arbitrary cardinality, or VHDL.

## Non-Goals

`.490` changes no behavior. `.491` should also leave these future exact
owners out of scope:

- raw `ARLEN` capture over depth-3 dynamic queues;
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

This readiness audit ran the RAM-guarded temporary candidate probe above and
closed with documentation and continuity gates:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

`.491` owns the generated behavior, sample, support-accounting, report JSON,
focused tests, and syntax validation for the implementation.

## Rollback

Rollback removes this readiness audit document and its Knowledge Map fact
card, reverts the `.490` task-tree, README, ROADMAP_V2, mdBook, and Memory
updates, and returns the active frontier to `.490`. No code or runtime
behavior rollback is needed.
