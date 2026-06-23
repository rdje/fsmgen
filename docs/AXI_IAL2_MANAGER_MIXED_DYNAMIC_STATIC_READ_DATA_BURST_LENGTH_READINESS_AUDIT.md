# AXI IAL2 Manager Mixed Dynamic/Static Read-Data Burst-Length Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.286`

Date: 2026-06-23

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.286` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.287`, direct bounded implementation of
report-only raw-`ARLEN` burst-length capture over generated mixed
dynamic/static read burst-last response-demux and scalar last-beat read-data.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The audit read or reverified:

- `.285` post mixed dynamic/static read-data selector:
  `docs/AXI_IAL2_MANAGER_POST_MIXED_DYNAMIC_STATIC_READ_DATA_NEXT_SLICE_SELECTION.md`
- `.284` mixed dynamic/static scalar read-data behavior and its public
  single-beat and last-beat samples.
- `.283` mixed dynamic/static read-data contract selection and `.282`
  readiness audit.
- `.280` mixed dynamic/static read burst-last `RID && RLAST` response-demux
  behavior.
- `.276` mixed dynamic/static read single-beat response-demux behavior.
- `.272` mixed dynamic/static write response-demux behavior.
- `.263`/`.264` multiple dynamic burst-length/runtime behavior.
- `.238`/`.240` single-active dynamic burst-length/runtime behavior.
- `.200`/`.202` mixed auto-ID plus queue-head burst-length/runtime behavior.
- Current read-data coverage, burst-length normalization,
  request-time raw-`ARLEN` capture, runtime-validation, multi-beat
  output-bank, report, residue, support-accounting, and focused-validation
  helpers in `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus`.
- README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map state.

## Readiness Finding

The lower substrate is ready for a direct report-only implementation slice.

The current mixed dynamic/static read-data branch in
`_read_data_response_demux_transaction_coverage` already verifies the
important ownership facts for the generated mixed read demux family:

- `generated_mixed_dynamic_static_read_demux` pairs only with scalar
  `capture-scope single-beat`;
- `generated_mixed_dynamic_static_read_demux_last_beat` pairs only with scalar
  `capture-scope last-beat`;
- the covered read transaction set is exactly one dynamic read transaction
  followed by one concrete static read transaction; and
- generated completion signal count must match the covered transaction list.

That branch currently rejects any `burst_length` metadata. The next
implementation only needs to widen the last-beat half of that predicate for
`validation report-only` and keep the single-beat half fail-closed.

The generic burst-length machinery is already present:

- `_normalize_read_data_burst_length` accepts `source arlen`, width-8 signal,
  `axlen-plus-one` encoding, request capture, `max_beats` in `1..256`, and
  `report-only` or `runtime-assertion`;
- `_normalize_read_data_read` attaches per-transaction raw-`ARLEN` storage and
  capture-rule names once burst-length metadata is accepted;
- `_read_data_burst_length_capture_rule_lines` emits one request-guarded raw
  `ARLEN` capture rule per covered read transaction; and
- `_report_read_data` already exposes generated burst-length inputs, storage,
  rules, validation mode, and residue movement.

Because the public `read-data.read` `burst-length` syntax is already shipped
and the implementation boundary is only the mixed coverage admission plus
sample/support/test/docs publication, a separate public contract-selection
leaf would add process churn without clarifying the behavior. The direct
owner can name the source shape and diagnostics precisely.

## Selected .287 Boundary

`.287` should implement only the report-only mixed dynamic/static raw-`ARLEN`
shape:

- exactly one transaction-local dynamic read transaction;
- exactly one concrete static read transaction;
- generated mixed dynamic/static `response-demux.read` with
  `response-scope burst-last`, one-bit `last-signal`, and
  `transaction-completion generated`;
- `read-data.read` with `capture-scope last-beat`, `completion-source
  response-demux`, `status-policy last-beat`, `interleaving
  last-beat-by-rid`, and complete transaction bindings for the dynamic and
  static read transactions;
- existing `burst-length` syntax with `source arlen`, width-8 signal,
  `axlen-plus-one`, request capture, `max-beats` in `1..256`, and
  `validation report-only`;
- generated `axi0_arlen` input, per-transaction raw-`ARLEN` storage
  (`axi0_r0_arlen_q`, `axi0_r1_arlen_q` for the public sample),
  request-guarded raw-`ARLEN` capture rules, and generated burst-length report
  fields; and
- scalar last-beat `RDATA`/`RRESP` capture remains guarded only by the
  generated mixed `RID && RLAST` completion pulses selected by `.284`.

The public sample should extend the `.284` last-beat read-data shape and use:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_burst_length.ppif
```

The support-accounting entry should use:

```text
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_burst_length
```

## Diagnostics

`.287` should preserve fail-closed diagnostics for:

- mixed dynamic/static single-beat read-data with `burst-length`;
- mixed dynamic/static last-beat read-data with `validation runtime-assertion`;
- mixed dynamic/static multi-beat read-data;
- more than one dynamic read transaction or more than one concrete static read
  transaction;
- missing, partial, duplicate, or extra read-data transaction bindings;
- generated completion signal counts that do not match the covered dynamic
  plus static transaction set;
- multiple mixed transactions;
- same-cycle request widening beyond the current onehot0 policy;
- same-cycle release-and-recapture;
- dynamic same-ID queues and scoreboards;
- direct backend behavior;
- backend-language variants; and
- VHDL.

The accepted diagnostic should no longer claim that all mixed dynamic/static
last-beat read-data requires no burst-length metadata; it should name the
report-only raw-`ARLEN` exception.

## Validation Gates For .287

The implementation owner should run:

- Perl syntax checks for touched modules/tests;
- direct schedule/check/semantic/verify-HDL probes for the new public sample;
- support-accounting validation for the new public sample;
- focused mixed/dynamic generator test coverage, guarded if it runs long;
- focused fail-closed probes for single-beat burst-length and runtime
  assertion shapes;
- `mdbook build docs/book`;
- Knowledge Map generation/check;
- memory architecture and doctrine checks; and
- `git --no-pager diff --check`.

## Explicit Residue

Runtime beat-count/`RLAST` validation over the mixed raw-`ARLEN` shape,
multi-beat output banks, multiple mixed dynamic/static transactions,
same-cycle widening, release-and-recapture, dynamic same-ID queues,
scoreboards, direct backend behavior, backend-language variants, and VHDL
remain separate exact owners.

## Rollback

Rollback is the `.286` docs-only audit commit plus any later `.287`
implementation commit, if present. Reverting `.286` restores `.286` as the
active readiness audit and removes the `.287` direct implementation owner.
