# AXI IAL2 Manager Dynamic Read Burst-Last Depth-3 Same-ID Issue-Order Queue Read-Data Burst-Length Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.493`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.493` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.494`, direct bounded implementation of
report-only raw-`ARLEN` burst-length capture over the generated all-dynamic
read burst-last `RID && RLAST` same-ID `issue-order-queue` depth-3 scalar
read-data behavior shipped in `.491`.

No parser, generator, PPIF sample, support-accounting catalog, generated
artifact, report JSON, test, HDL/runtime behavior, external converter
dependency, arbitrary-cardinality queue behavior, direct backend behavior,
backend-language variant, or VHDL behavior changed in this audit.

## Audit Result

The selected implementation can be local because the only observed blocker is
the dynamic issue-order queue read-data coverage predicate.

The current `_read_data_response_demux_transaction_coverage` dynamic
issue-order queue branch has two relevant paths:

- a depth-2 queue path that already allows last-beat scalar read-data with
  report-only or runtime-assertion `burst_length` metadata; and
- a depth-3 last-beat path from `.491` that allows exactly three dynamic
  transactions only when `burst_length` metadata is absent.

The read-data burst-length normalization is already public and bounded:
`source arlen`, width-8 signal, `axlen-plus-one` encoding, request capture,
`max-beats` in range, and `validation report-only` or `runtime-assertion`.
For a normalized read-data contract with burst-length metadata, the generator
already assigns one `*_arlen_q` storage variable and one
`*_burst_length_capture` rule per covered read-data transaction, and the
generated-artifact report already enumerates the burst-length input, storage,
and rules from the transaction list.

## Temporary Candidate Probe

A RAM-guarded in-memory candidate was built from:

```text
ppif/axi_manager_capacity_status_dynamic_read_burst_last_depth3_same_id_issue_order_queue_read_data.ppif
```

The probe inserted this existing `read-data.read` metadata before the three
transaction bindings:

```lisp
(burst-length
  (source arlen)
  (signal axi0_arlen (width 8))
  (encoding axlen-plus-one)
  (capture request)
  (max-beats 16)
  (validation report-only))
```

It failed closed at the expected local diagnostic:

```text
AXI manager capacity/status IAL2 contract read_data.read dynamic issue-order queue coverage requires generated dynamic read issue-order queue single-beat response_demux with capture_scope single-beat and no burst_length metadata, generated dynamic read issue-order queue burst-last response_demux with capture_scope last-beat and no burst_length metadata over two dynamic transactions or one depth-3 all-dynamic queue, generated dynamic read issue-order queue burst-last response_demux with capture_scope last-beat and report-only/runtime-assertion burst_length metadata over two dynamic transactions, or generated dynamic read issue-order queue burst-last response_demux with capture_scope multi-beat and runtime-assertion burst_length metadata over two dynamic transactions in this slice
```

The probe ran under `scripts/run_with_ram_guard.sh`; host memory was below the
cutoff and the command exited cleanly with the expected fail-closed result.

## Selected Implementation Boundary

`.494` should implement only this shape:

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
burst-length.validation: report-only
```

Expected generated/report artifacts for the direct implementation are:

- generated input `axi0_arlen`;
- per-transaction storage `axi0_r0_arlen_q`, `axi0_r1_arlen_q`, and
  `axi0_r2_arlen_q`;
- per-transaction capture rules `axi0_r0_burst_length_capture`,
  `axi0_r1_burst_length_capture`, and `axi0_r2_burst_length_capture`;
- existing scalar last-beat read-data capture rules for `r0`, `r1`, and `r2`;
- completion validity
  `generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse`;
- `burst_length_source: arlen_signal`;
- `burst_length_validation: report_only`; and
- residue that keeps runtime beat-count/`RLAST` validation, multi-beat
  output banks, and broader queue work explicit.

## Validation Plan For `.494`

The implementation owner should run:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c t/1436-ial2-ppif-parser-cli.t
perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t
perl -Iperl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
perl -Iperl -c t/248-regression-corpus-accounting.t
scripts/run_with_ram_guard.sh -- ./bin/fsmgen --emit-schedule-json ppif/<new-sample>.ppif
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

Full focused `t/1438`, strict check JSON, semantic JSON, and HDL generation
should be attempted only under the RAM guard; if the host-memory cutoff trips,
the implementation owner should record the caveat instead of retrying
unguarded or raising the cutoff unsafely.

## Deferred Work

`.493` leaves these future owners unchanged:

- runtime beat-count/`RLAST` validation over the depth-3 dynamic RLAST queue;
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
the `.493` task-tree, README, ROADMAP_V2, mdBook, and Memory updates, and
returns the active frontier to `.493`. No code or runtime behavior rollback is
needed.
