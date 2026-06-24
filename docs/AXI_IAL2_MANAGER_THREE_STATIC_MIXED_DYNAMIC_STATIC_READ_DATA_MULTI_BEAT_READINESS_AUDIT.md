# AXI IAL2 Manager Three-Static Mixed Dynamic/Static Read-Data Multi-Beat Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.336`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.336` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.337`, direct bounded implementation of
generated multi-beat output banks over generated one-dynamic plus
three-concrete-static mixed dynamic/static runtime-validation read-data.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The audit read or reverified:

- `.335` three-static mixed dynamic/static runtime-validation behavior.
- `.334` three-static mixed dynamic/static runtime-validation readiness audit.
- `.333` three-static mixed dynamic/static report-only raw-`ARLEN`
  burst-length behavior.
- `.330` three-static mixed dynamic/static scalar read-data behavior.
- `.326` three-static mixed dynamic/static read burst-last `RID && RLAST`
  response-demux behavior.
- `.322` three-static mixed dynamic/static read single-beat `RID`
  response-demux behavior.
- `.314` two-static mixed dynamic/static multi-beat output-bank behavior and
  `.313` readiness rationale.
- Current read-data coverage admission, multi-beat output-bank normalization,
  output-bank initialization, per-lane capture, scalar status aggregation,
  runtime beat-count validation, report, residue, support-accounting, and
  focused-validation helpers in
  `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus`.
- README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map state.

## Readiness Finding

The lower substrate is ready for a direct multi-beat implementation slice.

The `.335` runtime-validation implementation already proves the source
boundary needed by output-bank widening:

- generated one-dynamic plus three-concrete-static mixed dynamic/static read
  burst-last response-demux;
- ordered `r0`, `r1`, `r2`, and `r3` read-data transaction coverage;
- request-time raw `ARLEN` storage and `ARLEN + 1` expected-beat storage for
  every covered transaction;
- per-transaction read-beat counters and four runtime assertions per
  transaction; and
- raw matched-read-beat counting that is not gated by `RLAST`.

The `.314` two-static precedent already ships the public multi-beat syntax
and report vocabulary: `capture-scope multi-beat`, `status-policy per-beat`,
`status-aggregation.policy worst-observed`, `interleaving
multi-beat-by-rid`, runtime-assertion `ARLEN` burst-length metadata, and
per-transaction data prefix, status prefix, scalar status aggregate output,
valid-mask output, and length output bindings.

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

- `_read_data_response_demux_transaction_coverage` currently admits
  three-static mixed dynamic/static read-data only for scalar no-burst,
  scalar report-only raw-`ARLEN`, and scalar runtime-assertion raw-`ARLEN`
  last-beat shapes. It admits multi-beat runtime-assertion raw-`ARLEN` only
  at the existing one-dynamic plus two-static boundary.
- `_multi_mixed_dynamic_static_read_response_demux_covers_multi_beat_boundary`
  currently recognizes exactly one dynamic plus two static transactions for
  response-demux residue cleanup.

Because the public multi-beat syntax, output-bank contract, runtime
validation vocabulary, and generated helpers are already shipped, a separate
public contract-selection leaf would not add clarity. `.337` should be a
direct bounded behavior slice whose code changes are limited to three-static
multi-beat coverage admission, residue-boundary recognition, support
publication, focused assertions, and live docs.

## Selected .337 Boundary

`.337` should implement only the multi-beat sibling of the `.335` runtime
shape:

- exactly one transaction-local dynamic read transaction;
- exactly three pairwise-distinct concrete static read transactions;
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
- complete per-transaction output-bank bindings for `r0`, `r1`, `r2`, and
  `r3`;
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
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_multi_beat.ppif
```

The support-accounting entry should use:

```text
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_multi_beat
```

The coverage label should be:

```text
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_multi_beat_pipeline_cli
```

The focused behavior label should be:

```text
mixed_dynamic_static_read_data_multi_static3_multi_beat
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

`.337` should preserve fail-closed diagnostics for:

- three-static mixed dynamic/static multi-beat read-data without
  runtime-assertion `ARLEN` burst-length metadata;
- three-static mixed dynamic/static single-beat read-data with
  `burst-length`;
- transaction sets that are not exactly one dynamic read plus three concrete
  static reads for the new public multi-beat sample;
- missing, duplicate, partial, or extra read-data transaction bindings;
- missing output-bank prefixes, valid-mask outputs, length outputs, or scalar
  status aggregate outputs for the multi-beat shape;
- generated completion signal counts that do not match the covered
  transaction list;
- two-dynamic-plus-static shapes;
- broader mixed dynamic/static cardinalities;
- same-cycle request widening beyond the current onehot0 policy;
- same-cycle release-and-recapture;
- dynamic same-ID queues and scoreboards;
- direct backend behavior;
- backend-language variants; and
- VHDL.

The accepted diagnostic should name three-static mixed dynamic/static
multi-beat coverage as requiring generated burst-last demux plus
runtime-assertion burst-length metadata.

## Validation Gates For .337

The implementation owner should run:

- Perl syntax checks for touched modules/tests;
- guarded direct schedule/check/semantic/verify-HDL probes for the new
  multi-beat public sample, or recorded lightweight fallbacks if host-memory
  guards trip before execution;
- focused dynamic transaction-ID validation for the new sample, guarded if it
  runs long;
- preservation probes for `.335`, `.333`, `.330`, `.326`, `.314`, and `.291`
  public samples;
- support-accounting validation for the new multi-beat sample;
- focused fail-closed probes for unsupported three-static multi-beat variants;
- `mdbook build docs/book`;
- Knowledge Map generation/check;
- memory architecture and doctrine checks; and
- `git --no-pager diff --check`.

## Explicit Residue

Two-dynamic-plus-static shapes, broader mixed dynamic/static cardinalities,
same-cycle widening, release-and-recapture, dynamic same-ID queues,
scoreboards, direct backend behavior, backend-language variants, and VHDL
remain separate exact owners.

## Rollback

Rollback is the `.336` docs-only audit commit. Reverting it restores `.336`
as the active multi-beat readiness audit and removes the `.337` direct
implementation owner.
