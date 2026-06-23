# AXI IAL2 Manager Multiple Dynamic Multi-Beat Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.267`

Date: 2026-06-23

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.268`, direct generated
implementation of bounded multiple dynamic multi-beat read-data output-bank
behavior over the generated multiple dynamic read runtime-validation boundary.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The selector read or used:

- `.266` multiple dynamic multi-beat readiness audit:
  `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_MULTI_BEAT_READINESS_AUDIT.md`
- `.265` post-runtime selector:
  `docs/AXI_IAL2_MANAGER_POST_MULTIPLE_DYNAMIC_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md`
- `.264` multiple dynamic runtime beat-count/`RLAST` behavior:
  `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_RUNTIME_BEHAVIOR.md`
- `.263` multiple dynamic report-only raw-`ARLEN` behavior:
  `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_BURST_LENGTH_BEHAVIOR.md`
- `.259` multiple dynamic scalar read-data behavior:
  `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_DATA_BEHAVIOR.md`
- `.255` multiple dynamic read burst-last/`RLAST` response-demux behavior:
  `docs/AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_READ_RLAST_RESPONSE_DEMUX_BEHAVIOR.md`
- `.243` single-active dynamic multi-beat output-bank behavior:
  `docs/AXI_IAL2_MANAGER_DYNAMIC_MULTI_BEAT_BEHAVIOR.md`
- Current implementation surfaces in
  `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus`:
  `_read_data_response_demux_transaction_coverage`,
  `_normalize_read_data_read`,
  `_read_data_multi_beat_output_init_rule_lines`,
  `_read_data_capture_rule_lines`, `_read_data_generated_artifacts`,
  `_dynamic_read_response_demux_covers_multi_beat_boundary`,
  `_read_data_covers_multi_beat_by_rid_interleaving`, and
  `_read_data_covers_bounded_multi_beat_burst_output`.
- The public source shapes:
  `ppif/axi_manager_capacity_status_dynamic_read_data_multi_burst_length_runtime_assertion.ppif`
  and
  `ppif/axi_manager_capacity_status_dynamic_read_data_multi_beat.ppif`.
- Focused dynamic validation and support-accounting surfaces in
  `t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t`,
  `t/1436-ial2-ppif-parser-cli.t`,
  `t/1437-axi-ial2-manager-capacity-status-generator.t`,
  `perl/FSM/Support/RegressionCorpus.pm`, README, `ROADMAP_V2.md`, mdBook,
  task tree, Memory, and Knowledge Map.

## Public Source Shape

The `.268` public sample name is:

```text
ppif/axi_manager_capacity_status_dynamic_read_data_multi_transaction_multi_beat.ppif
```

The public intent name, source object, support-accounting entry, and coverage
label are:

```text
axi_manager_capacity_status_dynamic_read_data_multi_transaction_multi_beat
axi-manager-capacity-status-dynamic-read-data-multi-transaction-multi-beat
intent.ppif_axi_manager_capacity_status_dynamic_read_data_multi_transaction_multi_beat
ial2_ppif_manager_capacity_status_dynamic_read_data_multi_transaction_multi_beat_pipeline_cli
```

The `multi_transaction_multi_beat` stem is deliberately explicit. Existing
`dynamic_read_data_multi` samples use `multi` for multiple dynamic read
transactions, while the existing `dynamic_read_data_multi_beat` sample is the
single-active dynamic multi-beat output-bank shape. The new public stem
states both dimensions: multiple dynamic transactions and multi-beat payload
capture.

The selected source shape is the `.264` runtime sample with scalar last-beat
read-data replaced by complete multi-beat output-bank bindings:

```lisp
(read-data
  (read
    (capture-scope multi-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (status-policy per-beat)
    (status-aggregation
      (policy worst-observed))
    (interleaving multi-beat-by-rid)
    (burst-length
      (source arlen)
      (signal axi0_arlen (width 8))
      (encoding axlen-plus-one)
      (capture request)
      (max-beats 16)
      (validation runtime-assertion))
    (transaction r0
      (data-output-prefix axi0_r0_beat_rdata)
      (status-output-prefix axi0_r0_beat_rresp)
      (status-aggregate-output axi0_r0_rresp)
      (valid-mask-output axi0_r0_beat_valid)
      (length-output axi0_r0_read_beats))
    (transaction r1
      (data-output-prefix axi0_r1_beat_rdata)
      (status-output-prefix axi0_r1_beat_rresp)
      (status-aggregate-output axi0_r1_rresp)
      (valid-mask-output axi0_r1_beat_valid)
      (length-output axi0_r1_read_beats))))
```

The contract requires:

- two or more read transactions;
- every covered read transaction uses `(id dynamic)`;
- no mixed dynamic/static transaction family;
- generated `response-demux.read` with `response-scope burst-last`, one-bit
  `last-signal`, and `transaction-completion generated`;
- dynamic response-demux completion source
  `generated_dynamic_demux_last_beat`;
- `read-data.read capture-scope multi-beat`;
- `completion-source response-demux`;
- `status-policy per-beat`;
- `status-aggregation.policy worst-observed`;
- `interleaving multi-beat-by-rid`;
- `burst-length` with `source arlen`, width-8 signal, `encoding
  axlen-plus-one`, `capture request`, bounded `max-beats`, and `validation
  runtime-assertion`;
- `read-data.read.transactions` covers every generated dynamic read demux
  transaction exactly once; and
- every transaction binding carries `data-output-prefix`,
  `status-output-prefix`, `status-aggregate-output`, `valid-mask-output`, and
  `length-output`.

## Generated Behavior Contract For `.268`

Implementation `.268` should widen only the selected all-dynamic
multi-transaction multi-beat admission and residue-recognition gates. It
should preserve the already shipped `.243` single-active dynamic multi-beat
sample, `.259` scalar multiple dynamic read-data samples, `.263` report-only
burst-length sample, and `.264` runtime sample.

For the public two-transaction, 16-beat sample, generated behavior must
include:

- shared generated inputs `axi0_rdata`, `axi0_rresp`, and `axi0_arlen`;
- per-transaction raw `ARLEN` storage
  `axi0_r0_arlen_q` and `axi0_r1_arlen_q`;
- per-transaction expected-beat storage
  `axi0_r0_expected_beats_q` and `axi0_r1_expected_beats_q`;
- per-transaction read-beat counters
  `axi0_r0_read_beat_count_q` and `axi0_r1_read_beat_count_q`;
- request-time output-bank initialization rules
  `axi0_r0_read_data_output_init` and
  `axi0_r1_read_data_output_init`;
- 32 generated `RDATA` lane outputs, 16 per transaction;
- 32 generated `RRESP` lane outputs, 16 per transaction;
- valid-mask outputs `axi0_r0_beat_valid` and `axi0_r1_beat_valid`;
- length outputs `axi0_r0_read_beats` and `axi0_r1_read_beats`;
- scalar worst-observed status aggregate outputs
  `axi0_r0_rresp` and `axi0_r1_rresp`;
- one per-lane capture rule for each bounded beat of each transaction;
- scalar aggregate update rules
  `axi0_r0_rresp_aggregate` and `axi0_r1_rresp_aggregate`;
- per-transaction burst-length capture rules;
- per-transaction beat-count init and increment rules; and
- four runtime assertions per covered dynamic read transaction:
  `arlen_within_max`, `read_beat_before_expected_count`,
  `rlast_on_expected_beat`, and `expected_final_beat_has_rlast`.

Each transaction request initializes only that transaction's output bank:
all generated data lanes to zero, all generated status lanes to zero, scalar
aggregate status to zero, valid mask to all-zero, and length output to zero.

Lane capture uses the raw accepted dynamic read beat whose `RID` matches the
transaction's captured dynamic ID while the transaction is busy, excluding the
same transaction's request event. It does not wait for the final `RID &&
RLAST` completion pulse. The final `RID && RLAST` pulse remains the generated
response-demux transaction-completion validity and release boundary.

Scalar status aggregation uses worst-observed `RRESP`: each transaction's
aggregate output starts at zero at request time and updates when a matched
beat carries a numerically larger two-bit response status.

## Report Contract

Schedule/check/semantic JSON for `.268` should keep the existing multi-beat
report vocabulary:

```text
read_data.mode = bounded_multi_beat_read_data_contract
read_data.read.completion_validity =
  generated_dynamic_read_response_demux_last_beat_completion_pulse
read_data.read.capture_scope = multi_beat
read_data.read.status_policy = per_beat
read_data.read.status_aggregation = worst_observed
read_data.read.interleaving_policy = multi_beat_by_rid
read_data.read.burst_length_source = arlen_signal
read_data.read.burst_length_validation = runtime_assertion
read_data.read.beat_match_source = response_demux_matched_read_beat
read_data.read.beat_count_match_source = response_demux_matched_read_beat
read_data.read.output_shape = per_beat_output_bank
read_data.read.status_aggregation_generated_behavior = true
read_data.read.multi_beat_reassembly_generated_behavior = true
read_data.residue = []
```

The report must list both transactions in source order and aggregate the
per-transaction generated artifacts:

- `generated_multi_beat_data_outputs`;
- `generated_multi_beat_status_outputs`;
- `generated_multi_beat_valid_outputs`;
- `generated_multi_beat_length_outputs`;
- `generated_status_aggregate_outputs`;
- `generated_burst_length_inputs`, storage, and rules;
- `generated_expected_beat_count_storage`;
- `generated_beat_count_storage`;
- `generated_beat_count_rules`;
- `generated_beat_count_assertions`;
- `generated_multi_beat_output_init_rules`;
- `generated_multi_beat_capture_rules`;
- `generated_status_aggregate_init_rules`;
- `generated_status_aggregate_update_rules`; and
- aggregate `generated_outputs` and `generated_rules`.

For the selected public sample, read-data residue removes
`multi_beat_read_data_reassembly`, `per_beat_outputs`, and
`rresp_aggregation`. Response-demux residue recognition also treats the
selected sample as covering read-data interleaving and bounded burst-output
residue. Dynamic same-ID ordering, queueing, and scoreboard residue remain
future owners.

## Diagnostics

`.268` must preserve and extend the current fail-closed diagnostics:

- reject missing output-bank bindings for any generated dynamic read demux
  transaction;
- reject duplicate transaction bindings;
- reject bindings for transactions outside the generated dynamic read demux
  transaction set;
- reject mismatches between generated dynamic completion signal count and
  covered transaction count;
- reject partial multi-beat transaction bindings that omit
  `data-output-prefix`, `status-output-prefix`, `status-aggregate-output`,
  `valid-mask-output`, or `length-output`;
- reject scalar `data-output`/`status-output` fields in the multi-beat shape;
- reject output-name collisions with generated inputs, state, rules, or peer
  output banks;
- reject `capture-scope multi-beat` unless `status-policy` is `per-beat`,
  `status-aggregation.policy` is `worst-observed`, `interleaving` is
  `multi-beat-by-rid`, and `burst-length.validation` is
  `runtime-assertion`;
- reject multiple dynamic multi-beat coverage unless the response demux is
  generated dynamic read burst-last demux with two or more all-dynamic read
  transactions; and
- keep mixed dynamic/static demux fail-closed.

The diagnostic wording should replace the current single-active dynamic
multi-beat wording with the selected all-dynamic multi-transaction boundary
without loosening unrelated shapes.

## Validation Gates For `.268`

Implementation `.268` should include:

```bash
env -u PERL5LIB perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
env -u PERL5LIB perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
env -u PERL5LIB perl -Iperl -c t/1436-ial2-ppif-parser-cli.t
env -u PERL5LIB perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t
env -u PERL5LIB perl -Iperl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
env -u PERL5LIB perl -Iperl -c t/248-regression-corpus-accounting.t
scripts/run_with_ram_guard.sh --host-max-pct 93 --process-max-rss-mb 2048 -- ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_data_multi_transaction_multi_beat.ppif
scripts/run_with_ram_guard.sh --host-max-pct 93 --process-max-rss-mb 2048 -- ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_dynamic_read_data_multi_transaction_multi_beat.ppif
scripts/run_with_ram_guard.sh --host-max-pct 93 --process-max-rss-mb 2048 -- ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_dynamic_read_data_multi_transaction_multi_beat.ppif
scripts/run_with_ram_guard.sh --host-max-pct 93 --process-max-rss-mb 2048 -- ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen-ial2-268-multi-dyn-multi-beat.sv ppif/axi_manager_capacity_status_dynamic_read_data_multi_transaction_multi_beat.ppif
scripts/run_with_ram_guard.sh --host-max-pct 93 --process-max-rss-mb 2048 -- prove -Iperl t/248-regression-corpus-accounting.t
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

If broad focused dynamic validation such as
`t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t` is run, it must run
under the RAM guard. If the guard stops a run because host memory is already
above the configured cutoff, `.268` should record the caveat and rely only on
guarded direct public-sample probes that actually completed; it must not run
heavy probes unguarded.

## Non-Goals

`.267` changes no behavior.

`.268` should not widen mixed dynamic/static demux, same-cycle request
widening beyond the existing onehot0 policy, same-cycle
release-and-recapture, dynamic same-ID queues, scoreboards, direct backend
behavior, backend-language variants, or VHDL.

`.268` also should not reclassify the existing single-active dynamic
multi-beat sample as the multiple-transaction public sample.

## Rollback

Rollback for this selector is the `.267` commit. Reverting it restores `.267`
as the active contract-selection frontier and removes the `.268`
implementation owner.

Rollback for the later `.268` implementation will be the `.268` commit. It
should remove only the new public sample, support-accounting entry, tests,
implementation widening, docs, and fact card while preserving `.243`, `.259`,
`.263`, and `.264`.
