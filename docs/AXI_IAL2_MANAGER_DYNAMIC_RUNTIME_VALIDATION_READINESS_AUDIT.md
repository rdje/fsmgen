# AXI IAL2 Manager Dynamic Runtime Validation Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.239`

Date: 2026-06-22

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.239` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.240`, direct bounded implementation of
generated dynamic runtime beat-count/`RLAST` validation over the shipped
single-active dynamic read burst-last response-demux, scalar last-beat
dynamic read-data, and report-only raw-`ARLEN` capture boundary.

The selected next slice does not need a new public contract-selection leaf.
The public `read-data.read` `burst-length` syntax already includes
`validation runtime-assertion`, and the generator already has the runtime
beat-count storage, rule, assertion, report, and residue vocabulary used by
non-dynamic last-beat and queue-head read-data shapes.

## Evidence Read

The audit read the `.238` dynamic burst-length behavior, `.237` readiness
audit, `.236` focused-suite cleanup, `.234` dynamic read-data behavior,
`.231` dynamic read burst-last/`RLAST` behavior, non-dynamic
runtime-validation and multi-beat precedents, current runtime assertion
helpers, the focused dynamic test, broad-suite caveats, public samples,
support accounting, README, roadmap, mdBook, Memory, and Knowledge Map.

The current dynamic coverage gate in
`_read_data_response_demux_transaction_coverage` admits:

- dynamic single-beat read-data with no `burst_length` metadata;
- dynamic last-beat read-data with no `burst_length` metadata; and
- dynamic last-beat read-data with `burst_length.validation report_only`.

It intentionally rejects dynamic `burst_length.validation runtime_assertion`
today. An in-memory probe that changed the public `.238` sample from
`(validation report-only)` to `(validation runtime-assertion)` failed at the
dynamic coverage diagnostic instead of at parser syntax, normalization, or
runtime helper construction. That makes the dynamic coverage admission gate
the local implementation boundary for `.240`.

The adjacent runtime substrate is already present:

- `_normalize_read_data_burst_length` accepts `runtime-assertion` as public
  syntax and normalized validation metadata.
- `_normalize_read_data_read` attaches expected beat-count storage, read-beat
  counter storage, initialization/increment rule names, and assertion names
  when `runtime_assertion` metadata is accepted.
- `_read_data_beat_count_rule_lines` emits the request-time expected-count
  initialization and matched-read-beat counter increment rules.
- `_read_data_beat_count_assertion_specs` emits the four runtime checks used
  by shipped non-dynamic slices.
- `_read_data_matched_read_beat_expr` and `_response_demux_match_expr` are
  transaction-list driven. For the generated dynamic read burst-last shape,
  the raw matched read beat is the accepted read response plus
  `RID == captured_id` while the scalar last-beat payload capture still uses
  the generated `RID && RLAST` completion pulse.
- The report path already emits
  `beat_count_validation_generated_behavior`,
  `expected_beat_count_encoding: arlen_plus_one`, and
  `beat_count_match_source: response_demux_matched_read_beat` for shipped
  runtime-validation shapes.

## Selected Implementation Boundary

`.240` should implement only this dynamic runtime-validation shape:

- exactly one transaction-local dynamic read transaction;
- generated `response-demux.read` with `response-scope burst-last`, one-bit
  `last-signal`, and completion source
  `generated_dynamic_demux_last_beat`;
- `read-data.read` with `capture-scope last-beat`, `completion-source
  response-demux`, `status-policy last-beat`, and `interleaving
  last-beat-by-rid`;
- existing `burst-length` syntax with `source arlen`, width-8 signal,
  `axlen-plus-one`, request capture, `max-beats` in `1..256`, and
  `validation runtime-assertion`;
- generated expected-beat storage initialized from request `ARLEN + 1`;
- generated matched-read-beat counter incremented by the raw dynamic
  `RID == captured_id` response beat, not only by the last-beat completion;
- the four existing beat-count/`RLAST` runtime assertions for underflow,
  last-at-expected-count, no-early-last, and expected-count bounds;
- report fields and residue cleanup matching the non-dynamic runtime
  validation families; and
- a support-accounted public PPIF sample plus bounded focused validation in
  `t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t`.

The next implementation should preserve the `.238` report-only dynamic
sample unchanged and should add a separate runtime-validation sample. The
generated scalar last-beat `RDATA`/`RRESP` capture must stay guarded by the
generated dynamic last-beat completion pulse.

## Diagnostics

`.240` should preserve fail-closed diagnostics for:

- dynamic single-beat read-data with `burst-length`;
- dynamic multi-beat read-data output banks;
- more than one dynamic read transaction;
- mixed dynamic/static response-demux;
- dynamic response-demux without generated burst-last completion;
- missing or malformed `burst-length` fields; and
- unsupported dynamic queue, same-cycle recapture, same-ID ordering, or
  scoreboard behavior.

The accepted diagnostic should no longer claim that dynamic last-beat
runtime validation is outside the current slice once `.240` ships. It should
still make the single-active generated dynamic last-beat boundary explicit.

## Non-Goals

This audit does not change parser behavior, generator behavior, public PPIF
samples, support-accounting catalog entries, validation behavior, generated
artifacts, tests, schedule/check/semantic JSON, or HDL behavior.

`.240` must still not enable dynamic multi-beat output banks, multiple or
mixed dynamic demux, same-cycle recapture, dynamic same-ID ordering, queues,
scoreboards, direct backend behavior, backend-language variants, or VHDL.

## Validation Gates For `.240`

The implementation owner should run:

- Perl syntax checks for touched modules and tests;
- the bounded dynamic focused test under the RAM guard;
- direct schedule/check/semantic/default-HDL probes for the new dynamic
  runtime-validation sample;
- a support-accounting check for the new public sample;
- focused fail-closed diagnostic probes for unsupported dynamic
  single-beat, multi-beat, multiple/mixed demux, and malformed burst-length
  shapes;
- a probe proving the `.238` report-only dynamic sample remains unchanged;
- `mdbook build docs/book`;
- Knowledge Map generation/check;
- memory architecture and doctrine checks; and
- `git --no-pager diff --check`.

## Rollback

Rollback is the `.239` docs-only commit plus the later `.240` implementation
commit, if present. Reverting `.239` only removes the readiness record and
restores `.239` as the active frontier; it does not affect runtime behavior.
