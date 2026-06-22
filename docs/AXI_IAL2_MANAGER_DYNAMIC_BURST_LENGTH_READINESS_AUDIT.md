# AXI IAL2 Manager Dynamic Burst-Length Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.237`

Date: 2026-06-22

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.237` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.238`, direct bounded implementation of
report-only raw-`ARLEN` burst-length capture over generated single-active
dynamic read burst-last response-demux and scalar last-beat dynamic
read-data.

The selected next slice does not need a new public contract-selection leaf.
The existing `read-data.read` `burst-length` clause already defines the public
syntax, source `arlen`, width-8 signal, `axlen-plus-one` encoding,
request-time capture, `max-beats` range, and `report-only` versus
`runtime-assertion` validation vocabulary. The generated raw-`ARLEN`
input/storage/rule/report scaffolding also already exists for non-dynamic
last-beat and queue-head read-data shapes.

## Evidence Read

The audit read the dynamic focused-suite cleanup from `.236`, the `.235`
selector, the `.234` dynamic read-data behavior, the `.233` dynamic read-data
readiness audit, the `.231` dynamic read burst-last/`RLAST` behavior, the
`.227` dynamic read single-beat behavior, `.223` dynamic write behavior, `.219`
dynamic metadata behavior, non-dynamic burst-length/read-data/runtime
precedents, the current dynamic focused test, PPIF samples, support
accounting, README, roadmap, mdBook, Memory, and Knowledge Map.

The current implementation has a deliberately narrow dynamic gate:
`_read_data_response_demux_transaction_coverage` admits generated dynamic
read-data only for `generated_dynamic_demux` plus `capture_scope single-beat`
or `generated_dynamic_demux_last_beat` plus `capture_scope last-beat`, and it
currently requires no `burst_length` metadata. The diagnostic explicitly says
dynamic coverage requires no burst-length metadata in this slice.

The neighboring substrate is already present:

- `_normalize_read_data_burst_length` accepts only `source arlen`, a width-8
  signal, `axlen-plus-one` encoding, request capture, `max_beats` in
  `1..256`, and `report-only` or `runtime-assertion`.
- `_normalize_read_data_read` attaches per-transaction
  `burst_length_storage` and `burst_length_capture_rule` once burst-length
  metadata is accepted for last-beat or multi-beat read-data.
- `_read_data_burst_length_capture_rule_lines` emits request-guarded raw
  `ARLEN` capture from the transaction request event.
- `_read_data_generated_artifacts` and `_report_read_data` already publish
  generated burst-length inputs, storage, and rules.
- `t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t` now provides the
  bounded dynamic-family validation target that `.235` required before more
  dynamic behavior is widened.

## Selected Implementation Boundary

`.238` should implement only the report-only dynamic raw-`ARLEN` shape:

- exactly one transaction-local dynamic read transaction;
- generated `response-demux.read` with `response-scope burst-last`, one-bit
  `last-signal`, and `transaction_completion_source`
  `generated_dynamic_demux_last_beat`;
- `read-data.read` with `capture-scope last-beat`, `completion-source
  response-demux`, `status-policy last-beat`, and `interleaving
  last-beat-by-rid`;
- existing `burst-length` syntax with `source arlen`, width-8 signal,
  `axlen-plus-one`, request capture, `max-beats` in `1..256`, and
  `validation report-only`;
- generated `axi0_arlen` input, per-transaction raw-`ARLEN` storage,
  request-guarded capture rule, and report fields
  `burst_length_generated_behavior: true`,
  `burst_length_validation: report_only`,
  `generated_burst_length_inputs`,
  `generated_burst_length_storage`, and
  `generated_burst_length_rules`;
- scalar last-beat dynamic `RDATA`/`RRESP` capture remains guarded by the
  generated dynamic completion pulse; and
- a support-accounted public PPIF sample plus focused validation in the
  bounded dynamic target.

The next implementation should update the dynamic coverage gate so this one
last-beat/report-only shape is admitted. It should keep single-beat dynamic
read-data with `burst-length` rejected, because burst length is only meaningful
for last-beat or multi-beat capture in the current public contract.

## Diagnostics

The next slice should preserve fail-closed diagnostics for:

- dynamic single-beat read-data with `burst-length`;
- dynamic last-beat read-data with `validation runtime-assertion`;
- dynamic multi-beat read-data;
- more than one dynamic read transaction;
- mixed dynamic/static response-demux;
- dynamic response-demux without the generated burst-last completion source;
  and
- missing or malformed `burst-length` fields.

The accepted diagnostic should no longer claim that all dynamic last-beat
coverage requires no burst-length metadata; it should name the report-only
dynamic raw-`ARLEN` exception.

## Non-Goals

This audit does not change parser behavior, generator behavior, public PPIF
samples, support-accounting catalog entries, validation behavior, generated
artifacts, tests, schedule/check/semantic JSON, or HDL behavior.

`.238` must still not enable dynamic runtime validation, dynamic multi-beat
output banks, multiple or mixed dynamic demux, same-cycle recapture, dynamic
same-ID ordering, queues, scoreboards, direct backend behavior, or VHDL.

## Validation Gates For `.238`

The implementation owner should run:

- Perl syntax checks for touched modules/tests;
- the bounded dynamic focused test under the RAM guard;
- direct schedule/check/semantic/default-HDL probes for the new dynamic
  burst-length sample;
- a support-accounting check for the new public sample;
- focused fail-closed diagnostic probes for unsupported dynamic
  burst-length/runtime/multi-beat shapes;
- `mdbook build docs/book`;
- Knowledge Map generation/check;
- memory architecture and doctrine checks; and
- `git --no-pager diff --check`.

## Rollback

Rollback is the `.237` docs-only commit plus the later `.238` implementation
commit, if present. Reverting `.237` only removes the readiness record and
restores `.237` as the active frontier; it does not affect runtime behavior.

