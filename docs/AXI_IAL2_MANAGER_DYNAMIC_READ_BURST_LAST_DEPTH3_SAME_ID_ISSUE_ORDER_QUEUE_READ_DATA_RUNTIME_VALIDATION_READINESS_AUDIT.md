# AXI IAL2 Manager Dynamic Read Burst-Last Depth-3 Same-ID Issue-Order Queue Read-Data Runtime Validation Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.496`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.496` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.497`, direct bounded implementation of
runtime beat-count/`RLAST` validation over the generated all-dynamic read
burst-last `RID && RLAST` same-ID `issue-order-queue` depth-3 scalar
read-data raw-`ARLEN` behavior shipped in `.494`.

No parser, generator, PPIF sample, support-accounting catalog, generated
artifact, report JSON, test, HDL/runtime behavior, external converter
dependency, arbitrary-cardinality queue behavior, direct backend behavior,
backend-language variant, multi-beat output-bank behavior, or VHDL behavior
changed in this audit.

## Audit Result

The selected implementation can be local because the only confirmed blocker is
the dynamic issue-order queue read-data coverage predicate.

The current dynamic issue-order queue branch in
`_read_data_response_demux_transaction_coverage` already supports:

- the two-transaction queue with last-beat report-only or runtime-assertion
  `burst_length` metadata;
- the two-transaction queue with multi-beat runtime-assertion `burst_length`
  metadata;
- the depth-3 queue with last-beat scalar read-data and no `burst_length`
  metadata; and
- the depth-3 queue with last-beat report-only raw-`ARLEN` metadata from
  `.494`.

It does not yet admit the same depth-3 queue when `burst_length.validation` is
`runtime-assertion`. That rejection is deliberate coverage gating, not parser
syntax, report schema, generated-artifact, or external-tool dependency.

The runtime-validation helpers are already per-transaction. Once a read-data
contract is normalized with `burst_length_validation: runtime_assertion`, the
generator assigns each covered transaction:

- raw-`ARLEN` storage and request-time capture;
- expected-beat storage;
- read-beat counter storage;
- one init rule;
- one read-beat increment rule; and
- four assertion specs: `ARLEN` within max, beat before expected count,
  `RLAST` only on expected beat, and expected final beat has `RLAST`.

## Temporary Candidate Probes

A RAM-guarded candidate was built from:

```text
ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_burst_length.ppif
```

The candidate changed only:

```lisp
(validation report-only)
```

to:

```lisp
(validation runtime-assertion)
```

Against the unmodified repo code, the candidate failed closed at the expected
local diagnostic:

```text
AXI manager capacity/status IAL2 contract read_data.read dynamic issue-order queue coverage requires generated dynamic read issue-order queue single-beat response_demux with capture_scope single-beat and no burst_length metadata, generated dynamic read issue-order queue burst-last response_demux with capture_scope last-beat and no burst_length metadata over two dynamic transactions or one depth-3 all-dynamic queue, generated dynamic read issue-order queue burst-last response_demux with capture_scope last-beat and report-only/runtime-assertion burst_length metadata over two dynamic transactions, generated dynamic read issue-order queue burst-last response_demux with capture_scope last-beat and report-only burst_length metadata over one depth-3 all-dynamic queue, or generated dynamic read issue-order queue burst-last response_demux with capture_scope multi-beat and runtime-assertion burst_length metadata over two dynamic transactions in this slice
```

A second RAM-guarded probe used a temporary out-of-tree module overlay that changed
only that depth-3 queue predicate from report-only to report-only or
runtime-assertion. With that one-line predicate widening, the existing parser
and generator produced:

```text
generated_expected_beat_count_storage:
  axi0_r0_expected_beats_q
  axi0_r1_expected_beats_q
  axi0_r2_expected_beats_q

generated_beat_count_storage:
  axi0_r0_read_beat_count_q
  axi0_r1_read_beat_count_q
  axi0_r2_read_beat_count_q

generated_beat_count_rules:
  axi0_r0_beat_count_init
  axi0_r0_read_beat_count
  axi0_r1_beat_count_init
  axi0_r1_read_beat_count
  axi0_r2_beat_count_init
  axi0_r2_read_beat_count

generated_beat_count_assertions:
  axi0_r0_arlen_within_max
  axi0_r0_read_beat_before_expected_count
  axi0_r0_rlast_on_expected_beat
  axi0_r0_expected_final_beat_has_rlast
  axi0_r1_arlen_within_max
  axi0_r1_read_beat_before_expected_count
  axi0_r1_rlast_on_expected_beat
  axi0_r1_expected_final_beat_has_rlast
  axi0_r2_arlen_within_max
  axi0_r2_read_beat_before_expected_count
  axi0_r2_rlast_on_expected_beat
  axi0_r2_expected_final_beat_has_rlast
```

The overlay also confirmed generated IAL1 carries the `r2` expected-beat
storage, read-beat counter storage, init rule, and increment rule. Temporary
probe artifacts were removed after the audit.

## Selected Implementation Boundary

`.497` should implement only this shape:

```text
read transactions: r0, r1, r2
all transaction IDs: dynamic
same-id-ordering.read: dynamic-id-reuse issue-order-queue
response-demux.read: response-scope burst-last, one-bit last-signal
transaction_completion_source: generated_dynamic_issue_order_queue_demux_last_beat
first_generated_scope: read_rid_rlast_three_dynamic_transactions
read-data.read.capture-scope: last-beat
read-data.read.completion-source: response-demux
read-data.read.status-policy: last-beat
read-data.read.interleaving: last-beat-by-rid
read-data transactions: exactly r0, r1, r2
burst-length.source: arlen
burst-length.signal: axi0_arlen, width 8
burst-length.encoding: axlen-plus-one
burst-length.capture: request
burst-length.max-beats: 16
burst-length.validation: runtime-assertion
```

Expected implementation artifacts are:

- public sample
  `ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data_burst_length_runtime_assertion.ppif`;
- support-accounting entry and regression-corpus docs for that sample;
- generated input `axi0_arlen`;
- per-transaction raw-`ARLEN` storage
  `axi0_r0_arlen_q`, `axi0_r1_arlen_q`, and `axi0_r2_arlen_q`;
- per-transaction expected-beat storage;
- per-transaction read-beat counter storage;
- six beat-count rules across `r0`/`r1`/`r2`;
- twelve generated beat-count/`RLAST` assertion specs; and
- focused parser/generator/dynamic/support-accounting tests.

The implementation should not add multi-beat output banks, RRESP aggregation,
mixed dynamic/static queues, arbitrary queue cardinality, direct backend
behavior, backend-language variants, external converter dependencies, or VHDL.

## Validation Plan For `.497`

The implementation owner should run:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c t/1436-ial2-ppif-parser-cli.t
perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t
perl -Iperl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
perl -Iperl -c t/248-regression-corpus-accounting.t
scripts/run_with_ram_guard.sh -- ./bin/fsmgen --emit-schedule-json ppif/<new-runtime-sample>.ppif
scripts/run_with_ram_guard.sh -- perl -Iperl <targeted adapter/report/generated-artifact probe>
prove -Iperl t/248-regression-corpus-accounting.t
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

Full focused `t/1436`, `t/1437`, `t/1438`, strict check JSON, semantic JSON,
and HDL generation should run only under the RAM guard. If the host-memory or
RSS cutoff trips, record the caveat instead of retrying unguarded or raising
the cutoff unsafely.

## Deferred Work

`.496` leaves these future owners unchanged:

- multi-beat output banks over the depth-3 dynamic RLAST queue;
- mixed dynamic/static issue-order queues;
- scoreboards;
- same-cycle queue widening beyond already-owned queue recapture records;
- arbitrary queue cardinality;
- verification-code generation;
- direct backend behavior;
- backend-language variants;
- external converter dependency selection; and
- VHDL.

FSMGen-owned generation and lowering remain the default. External converters
such as `sv2v` remain optional future audit candidates only and are not
selected dependencies for this IAL2 slice.

## Rollback

Rollback removes this audit document and its Knowledge Map fact card, reverts
the `.496` task-tree, README, ROADMAP_V2, mdBook, and Memory updates, and
returns the active frontier to `.496`. No code or runtime behavior rollback is
needed.
