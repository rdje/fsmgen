# AXI IAL2 Manager Two-Dynamic/One-Static Mixed Dynamic/Static Read RLAST Read-Data Multi-Beat Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.356`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.356` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.357`, direct bounded implementation of
generated multi-beat output banks over generated two-dynamic-plus-one-static
mixed dynamic/static runtime-validation read-data.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The audit read or reverified:

- `.355` two-dynamic-plus-one-static mixed dynamic/static runtime-validation
  behavior.
- `.354` runtime-validation readiness audit.
- `.353` report-only raw-`ARLEN` behavior.
- `.350` scalar last-beat read-data behavior.
- `.347` two-dynamic-plus-one-static mixed read burst-last `RID && RLAST`
  response-demux behavior.
- `.344` two-dynamic-plus-one-static mixed read single-beat `RID`
  response-demux behavior.
- `.314` two-static mixed dynamic/static multi-beat output-bank behavior and
  `.313` readiness rationale.
- `.337` three-static mixed dynamic/static multi-beat output-bank behavior and
  `.336` readiness rationale.
- `.268` multiple all-dynamic multi-beat output-bank behavior.
- Current read-data coverage admission, multi-beat output-bank normalization,
  output-bank initialization, per-lane capture, scalar status aggregation,
  runtime beat-count validation, response-demux residue cleanup,
  support-accounting, and focused-validation helpers in
  `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus`.
- README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map state.
- A temporary fail-closed strict-check probe for the likely
  two-dynamic-plus-one-static multi-beat source shape under `/tmp`, which
  failed only at the local multiple mixed dynamic/static transaction-set
  admission diagnostic.

## Readiness Finding

The lower substrate is ready for a direct multi-beat implementation slice.

The `.355` runtime-validation implementation already proves the exact source
boundary needed by output-bank widening:

- generated two-dynamic-plus-one-static mixed dynamic/static read burst-last
  response-demux;
- ordered `r0` and `r1` dynamic read transactions plus static `r2`;
- request-time raw `ARLEN` storage and `ARLEN + 1` expected-beat storage for
  every covered transaction;
- per-transaction read-beat counters and four runtime assertions per
  transaction; and
- raw matched-read-beat counting that is not gated by `RLAST`.

The `.314`, `.337`, and `.268` precedents already ship the public multi-beat
syntax and report vocabulary: `capture-scope multi-beat`, `status-policy
per-beat`, `status-aggregation.policy worst-observed`, `interleaving
multi-beat-by-rid`, runtime-assertion `ARLEN` burst-length metadata, and
per-transaction data prefix, status prefix, scalar status aggregate output,
valid-mask output, and length output bindings. Schedule/check/semantic JSON
already uses `bounded_multi_beat_read_data_contract`,
`per_beat_output_bank`, `multi_beat_reassembly_generated_behavior`, and the
generated multi-beat output/init/capture artifact lists.

The common normalizer and generation helpers are transaction-list driven once
coverage admits the source shape. `_normalize_read_data_read` derives
generated data/status lane outputs, valid masks, length outputs, scalar
aggregate status outputs, request-time output-bank init rules, lane capture
rules, raw `ARLEN` storage, expected-beat storage, read-beat counters,
beat-count rules, runtime assertions, and report artifact names from the
covered transaction list. `_read_data_multi_beat_output_init_rule_lines`,
`_read_data_capture_rule_lines`, scalar status aggregation, and the
beat-count assertion/rule helpers also iterate over that transaction list.

The remaining implementation gap is local to admission and residue
recognition:

- `_read_data_response_demux_transaction_coverage` currently admits the
  two-dynamic-plus-one-static source shape for scalar last-beat read-data
  without `burst-length`, report-only raw-`ARLEN`, and runtime-assertion
  raw-`ARLEN`, but not for `capture-scope multi-beat`.
- `_multi_mixed_dynamic_static_read_response_demux_covers_multi_beat_boundary`
  currently recognizes one dynamic plus two or three concrete static
  transactions for multi-beat response-demux residue cleanup, but not two
  dynamic plus one static.

The temporary candidate:

```text
/tmp/fsmgen_356_two_dynamic_one_static_multi_beat_candidate.ppif
```

failed closed with the current diagnostic requiring either the already
supported scalar two-dynamic-plus-one-static shapes or a runtime-assertion
multi-beat output-bank shape with exactly one dynamic read plus three
concrete static reads. That confirms the next behavior slice can be limited
to admitting the exact two-dynamic-plus-one-static multi-beat transaction
set, adding residue-boundary recognition, publishing the support entry, and
adding focused assertions.

Because the public multi-beat syntax, output-bank contract, runtime
validation vocabulary, and generated helpers are already shipped, a separate
public contract-selection leaf would not add clarity.

## Selected .357 Boundary

`.357` should implement only the multi-beat sibling of the `.355` runtime
shape:

- exactly two transaction-local dynamic read transactions, `r0` and `r1`;
- exactly one concrete static read transaction, `r2`, reserved to `RID`
  `4'd3`;
- generated multiple mixed dynamic/static `response-demux.read` with
  `response-scope burst-last`, one-bit `last-signal`, and
  `transaction-completion generated`;
- `read-data.read` with `capture-scope multi-beat`, `completion-source
  response-demux`, `status-policy per-beat`,
  `status-aggregation.policy worst-observed`, and `interleaving
  multi-beat-by-rid`;
- existing `burst-length` syntax with `source arlen`, width-8 signal,
  `axlen-plus-one`, request capture, `max-beats` in `1..256`, and
  `validation runtime-assertion`;
- complete per-transaction output-bank bindings for `r0`, `r1`, and `r2`;
- generated per-transaction data and status lane outputs, valid-mask outputs,
  length outputs, scalar status aggregate outputs, output-bank init rules,
  per-lane capture rules, status aggregate update rules, raw `ARLEN` storage,
  expected-beat storage, read-beat counters, beat-count rules, and four
  runtime assertions per transaction; and
- lane capture remains driven by raw matched read beats, while generated
  mixed `RID && RLAST` completion pulses remain the transaction completion
  and release boundary.

The public sample should be:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_multi_beat.ppif
```

The support-accounting entry should use:

```text
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_multi_beat
```

The coverage label should be:

```text
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_multi_beat_pipeline_cli
```

The focused behavior label should be:

```text
mixed_dynamic_static_read_data_multi_dynamic_multi_beat
```

The generated report should use:

```text
read_data.mode = bounded_multi_beat_read_data_contract
read_data.read.completion_validity =
  generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse
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

For the response-demux report, the new sample should leave only
`same_id_ordering` residue.

## Diagnostics

`.357` should preserve fail-closed diagnostics for:

- two-dynamic-plus-one-static mixed dynamic/static multi-beat read-data
  without runtime-assertion `ARLEN` burst-length metadata;
- two-dynamic-plus-one-static mixed dynamic/static single-beat read-data with
  `burst-length`;
- transaction sets that are not exactly two dynamic reads plus one concrete
  static read for the new public multi-beat sample;
- missing, duplicate, partial, or extra read-data transaction bindings;
- missing output-bank prefixes, valid-mask outputs, length outputs, or scalar
  status aggregate outputs for the multi-beat shape;
- generated completion signal counts that do not match the covered
  transaction list;
- broader mixed dynamic/static cardinalities;
- same-cycle request widening beyond the current onehot0 policy;
- same-cycle release-and-recapture;
- dynamic same-ID queues and scoreboards;
- direct backend behavior;
- backend-language variants; and
- VHDL.

The accepted diagnostic should name the selected two-dynamic-plus-one-static
runtime-assertion multi-beat output-bank read-data branch without admitting
broader mixed dynamic/static cardinalities.

## Validation Gates For .357

The implementation owner should run:

- Perl syntax checks for touched modules/tests;
- guarded direct schedule/check/semantic/verify-HDL probes for the new
  multi-beat public sample, or recorded lightweight fallbacks if host-memory
  guards trip before execution;
- focused dynamic transaction-ID validation for the new behavior label,
  guarded and narrowed when RAM pressure requires it;
- preservation probes for `.355`, `.353`, `.350`, `.347`, `.344`, `.337`,
  `.314`, and `.268` public samples where practical;
- support-accounting validation for the new multi-beat sample;
- focused fail-closed probes for unsupported two-dynamic-plus-one-static
  multi-beat variants where practical;
- `mdbook build docs/book`;
- Knowledge Map generation/check;
- memory architecture and doctrine checks; and
- `git --no-pager diff --check`.

## Explicit Residue

Single-beat read-data over the `.344` demux, broader mixed dynamic/static
cardinalities, same-cycle widening, release-and-recapture, dynamic same-ID
queues, scoreboards, direct backend behavior, backend-language variants, VHDL,
profile aliases, queued/blocking policy, and full-manager behavior remain
separate exact owners.

## Rollback

Rollback is the `.356` docs-only audit commit. Reverting it restores `.356`
as the active multi-beat readiness audit and removes the `.357` direct
implementation owner.
