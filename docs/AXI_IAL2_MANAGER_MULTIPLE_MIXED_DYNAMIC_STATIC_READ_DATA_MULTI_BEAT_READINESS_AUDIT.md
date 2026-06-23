# AXI IAL2 Manager Multiple Mixed Dynamic/Static Read-Data Multi-Beat Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.313`

Date: 2026-06-23

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.313` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.314`, direct bounded implementation of
generated multiple mixed dynamic/static multi-beat output banks over the
generated multiple mixed runtime-validation boundary.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The audit read or reverified:

- `.312` multiple mixed dynamic/static runtime-validation behavior.
- `.311` multiple mixed dynamic/static runtime-validation readiness audit.
- `.310` multiple mixed dynamic/static report-only raw-`ARLEN` behavior.
- `.307` multiple mixed dynamic/static scalar read-data behavior.
- `.303` multiple mixed dynamic/static read burst-last `RID && RLAST`
  response-demux behavior.
- `.299` multiple mixed dynamic/static read single-beat `RID` response-demux
  behavior.
- `.291` one-dynamic plus one-static mixed dynamic/static multi-beat
  output-bank behavior.
- `.268` multiple all-dynamic multi-beat output-bank behavior.
- Current read-data coverage, multi-beat normalization, per-lane output naming,
  output-bank init, lane capture, scalar status aggregation, beat-count
  validation, report, residue, support-accounting, and focused-validation
  helpers in `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus`.
- README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map state.

## Readiness Finding

The lower substrate is ready for a direct multi-beat implementation slice.

The `.312` runtime-validation implementation already proves the exact source
boundary needed by multi-beat output banks:

- generated multiple mixed dynamic/static read burst-last response-demux;
- exactly one transaction-local dynamic read transaction;
- exactly two concrete static read transactions;
- ordered `r0`, `r1`, and `r2` transaction coverage;
- request-time raw-`ARLEN` storage and `ARLEN + 1` expected-beat storage;
- per-transaction read-beat counters and four runtime assertions; and
- raw matched-read-beat counting that is not gated by `RLAST`.

The `.291` and `.268` precedents already ship the public multi-beat syntax and
report vocabulary: `capture-scope multi-beat`, `status-policy per-beat`,
`status-aggregation.policy worst-observed`, `interleaving multi-beat-by-rid`,
runtime-assertion `ARLEN` burst-length metadata, and per-transaction data
prefix, status prefix, scalar status aggregate, valid-mask, and length output
bindings. Schedule/check/semantic JSON already uses
`bounded_multi_beat_read_data_contract`, `per_beat_output_bank`,
`multi_beat_reassembly_generated_behavior`, and the existing generated
multi-beat output/init/capture artifact lists.

The implementation gap is local. The multiple mixed dynamic/static read-data
coverage branch currently admits:

- single-beat read-data over generated multiple mixed single-beat demux;
- scalar last-beat read-data over generated multiple mixed burst-last demux;
  and
- scalar last-beat read-data with report-only or runtime-assertion
  burst-length metadata.

It does not yet admit `capture-scope multi-beat` for the same generated
multiple mixed burst-last demux. Once that branch admits only the runtime
multi-beat boundary, the common normalizer and generation helpers derive
transaction-list-shaped lane outputs, output-bank initialization rules,
per-lane capture rules, valid-mask and length outputs, scalar
worst-observed `RRESP` aggregation, raw `ARLEN` capture, expected-beat
storage, read-beat counters, and runtime assertions for all of `r0`, `r1`,
and `r2`.

The report-residue cleanup needs one matching implementation detail:
`_read_data_covers_multi_beat_by_rid_interleaving` currently recognizes
same-ID queue-head, all-dynamic, and one-dynamic plus one-static mixed
multi-beat response-demux boundaries. The `.314` owner should add equivalent
recognition for the multiple mixed dynamic/static burst-last demux so the new
sample removes `read_data_interleaving` and `bursts` from response-demux
residue and removes multi-beat read-data residue.

Because the public syntax, output-bank contract, and report vocabulary are
already shipped by earlier multi-beat slices, a separate public
contract-selection leaf would not add clarity. `.314` can be a direct bounded
behavior slice whose code changes are limited to coverage admission, residue
recognition, and focused assertions/support publication for the selected
sample.

## Selected .314 Boundary

`.314` should implement only the multi-beat sibling of the `.312` runtime
shape:

- exactly one transaction-local dynamic read transaction;
- exactly two pairwise-distinct concrete static read transactions;
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
  multiple mixed `RID && RLAST` completion pulses remain the transaction
  completion and release boundary.

The public sample should be:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_multi_beat.ppif
```

The support-accounting entry should use:

```text
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_multi_beat
```

The coverage label should be:

```text
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_multi_beat_pipeline_cli
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

`.314` should preserve fail-closed diagnostics for:

- multiple mixed dynamic/static single-beat read-data with `burst-length`;
- multiple mixed dynamic/static multi-beat read-data without runtime-assertion
  `ARLEN` burst-length metadata;
- multiple mixed dynamic/static transaction sets that are not exactly one
  dynamic read plus two concrete static reads;
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

The accepted diagnostic should name multiple mixed dynamic/static multi-beat
coverage as requiring generated burst-last demux plus runtime-assertion
burst-length metadata.

## Validation Gates For .314

The implementation owner should run:

- Perl syntax checks for touched modules/tests;
- guarded direct schedule/check/semantic/verify-HDL probes for the new
  multi-beat public sample, or recorded lightweight fallbacks if host-memory
  guards trip before execution;
- focused dynamic transaction-ID validation for the new sample, guarded if it
  runs long;
- preservation probes for `.312`, `.310`, `.307`, `.291`, and `.268` public
  samples;
- support-accounting validation for the new multi-beat sample;
- focused fail-closed probes for unsupported multiple mixed multi-beat
  variants;
- `mdbook build docs/book`;
- Knowledge Map generation/check;
- memory architecture and doctrine checks; and
- `git --no-pager diff --check`.

## Explicit Residue

Broader mixed dynamic/static cardinalities, same-cycle widening,
release-and-recapture, dynamic same-ID queues, scoreboards, direct backend
behavior, backend-language variants, and VHDL remain separate exact owners.

## Rollback

Rollback is the `.313` docs-only audit commit. Reverting it restores `.313` as
the active multi-beat readiness audit and removes the `.314` direct
implementation owner.
