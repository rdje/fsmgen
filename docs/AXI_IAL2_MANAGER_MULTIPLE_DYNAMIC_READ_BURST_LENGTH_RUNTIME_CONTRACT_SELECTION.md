# AXI IAL2 Manager Multiple Dynamic Read Burst-Length/Runtime Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.262`

Date: 2026-06-23

## Decision

Split the generated burst-length/runtime work over generated multiple dynamic
read response-demux into two implementation leaves:

- select `IAL2-FEATURE-COMPLETENESS-FRONTIER.263`, direct generated
  report-only raw-`ARLEN` burst-length capture over generated multiple dynamic
  read response-demux and scalar last-beat read-data; and
- select `IAL2-FEATURE-COMPLETENESS-FRONTIER.264` as the runtime
  beat-count/`RLAST` assertion sibling after the report-only boundary lands.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

Implementation status: `IAL2-FEATURE-COMPLETENESS-FRONTIER.263` implements
the report-only half of this split contract; see
`docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_BEHAVIOR.md`.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.264` implements the runtime
beat-count/`RLAST` sibling; see
`docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_BEHAVIOR.md`.

## Public Source Shapes

The `.263` report-only sample extends the shipped `.259` last-beat
multiple dynamic read-data sample:

```text
ppif/axi_manager_capacity_status_dynamic_read_data_multi_burst_length.ppif
```

The `.264` runtime sibling uses the same source shape and changes only the
`burst-length` validation mode:

```text
ppif/axi_manager_capacity_status_dynamic_read_data_multi_burst_length_runtime_assertion.ppif
```

Both samples use:

- two or more read transactions;
- every read transaction in the family uses `(id dynamic)`;
- `response-demux.read` uses `response-scope burst-last`, a one-bit
  `last-signal`, and `transaction-completion generated`;
- `read-data.read` uses `capture-scope last-beat`, `completion-source
  response-demux`, `status-policy last-beat`, and `interleaving
  last-beat-by-rid`;
- `read-data.read.transactions` binds every generated dynamic read demux
  transaction exactly once; and
- one family-level `ARLEN` signal is captured per transaction at that
  transaction's admitted request event.

The report-only clause is:

```lisp
(burst-length
  (source arlen)
  (signal axi0_arlen (width 8))
  (encoding axlen-plus-one)
  (capture request)
  (max-beats 16)
  (validation report-only))
```

The runtime sibling changes only:

```lisp
(validation runtime-assertion)
```

Mixed dynamic/static demux, single-beat burst-length metadata, multi-beat
output banks over multiple dynamic demux, same-cycle request widening beyond
the existing onehot0 policy, same-cycle release-and-recapture, dynamic same-ID
queues and scoreboards, direct backend behavior, backend-language variants,
and VHDL remain later exact owners.

## Report-Only Contract For .263

`.263` keeps the scalar last-beat read-data mode:

```text
read_data.mode = bounded_last_beat_read_data_contract
read_data.read.completion_validity =
  generated_dynamic_read_response_demux_last_beat_completion_pulse
read_data.read.burst_length_source = arlen_signal
read_data.read.burst_length_validation = report_only
```

For the public two-transaction sample, generated burst-length artifacts
include:

```text
generated_burst_length_inputs  = [axi0_arlen]
generated_burst_length_storage = [axi0_r0_arlen_q, axi0_r1_arlen_q]
generated_burst_length_rules   = [axi0_r0_burst_length_capture,
                                  axi0_r1_burst_length_capture]
```

Scalar last-beat `RDATA`/`RRESP` capture remains guarded only by each
transaction's generated `RID && RLAST` completion pulse. No expected-beat
storage, read-beat counter storage, beat-count rules, or runtime assertions
are generated in `.263`; `generated_beat_count_validation`,
`multi_beat_read_data_reassembly`, `per_beat_outputs`, and
`rresp_aggregation` remain read-data residue.

## Runtime Contract For .264

`.264` preserves the `.263` source shape, sample naming, transaction
coverage, raw-`ARLEN` storage, and scalar last-beat payload capture while
enabling runtime validation:

```text
read_data.read.burst_length_validation = runtime_assertion
read_data.read.beat_count_validation_generated_behavior = true
read_data.read.expected_beat_count_encoding = arlen_plus_one
read_data.read.beat_count_match_source = response_demux_matched_read_beat
```

For each covered dynamic read transaction, runtime generation adds:

- expected-beat storage initialized from request-time `ARLEN + 1`;
- read-beat counter storage initialized to zero on the transaction request;
- a read-beat counter increment on the raw accepted read beat whose `RID`
  matches that transaction's active selected dynamic ID, excluding the same
  transaction's request event;
- `arlen_within_max`;
- `read_beat_before_expected_count`;
- `rlast_on_expected_beat`; and
- `expected_final_beat_has_rlast`.

For the public two-transaction sample, the generated runtime assertion list
therefore has eight entries, four for `r0` and four for `r1`. Runtime removes
only the `generated_beat_count_validation` read-data residue; multi-beat
payload, per-beat outputs, and `RRESP` aggregation remain future owners.

## Diagnostics

The implementation preserves existing complete-coverage diagnostics and makes
the burst-length/runtime boundary explicit:

- reject missing read-data bindings for any generated dynamic read demux
  transaction;
- reject extra read-data bindings outside the generated dynamic read demux
  transaction set;
- reject duplicate read-data transaction bindings;
- reject mismatches between generated completion signal count and covered
  transaction count;
- reject multiple dynamic burst-length/runtime metadata unless the response
  demux is generated dynamic burst-last, the capture scope is last-beat, the
  transaction set has two or more all-dynamic read transactions, and the
  validation mode is `report-only` or `runtime-assertion`;
- keep single-beat burst-length metadata fail-closed; and
- keep multiple dynamic multi-beat output banks fail-closed until their own
  exact owner.

The existing single-active `.238` report-only and `.240` runtime samples
remain supported independently and are not reclassified as multiple dynamic
coverage.

## Validation Gates

`.263` includes focused syntax, direct CLI, support-accounting, docs, and
doctrine validation for the report-only sample:

```bash
env -u PERL5LIB perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
env -u PERL5LIB perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
env -u PERL5LIB perl -Iperl -c t/1436-ial2-ppif-parser-cli.t
env -u PERL5LIB perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t
env -u PERL5LIB perl -Iperl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
env -u PERL5LIB perl -Iperl -c t/248-regression-corpus-accounting.t
env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_data_multi_burst_length.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_dynamic_read_data_multi_burst_length.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_dynamic_read_data_multi_burst_length.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_dynamic_read_data_multi_burst_length.ppif
prove -Iperl t/248-regression-corpus-accounting.t
scripts/run_with_ram_guard.sh --host-max-pct 93 --process-max-rss-mb 4096 -- prove -Iperl t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

`.264` repeats the direct schedule/check/semantic/verify-HDL probes for the
runtime sample, proves that `.263` remains report-only, and keeps broader
`t/1436`/`t/1437` monoliths non-routine unless host resources allow them under
the RAM guard.

## Rollback

Rollback for this selector is the `.262` commit. Reverting it restores `.262`
as the active public-contract selection frontier and removes the `.263` and
`.264` implementation owners.
