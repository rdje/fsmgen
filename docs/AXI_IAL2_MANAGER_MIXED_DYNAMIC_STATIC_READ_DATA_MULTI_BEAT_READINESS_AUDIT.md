# AXI IAL2 Manager Mixed Dynamic/Static Read-Data Multi-Beat Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.290`

Date: 2026-06-23

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.290` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.291`, direct bounded implementation of
generated mixed dynamic/static multi-beat read-data output banks over the
`.289` mixed runtime-validation boundary.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The audit read or reverified:

- `.289` mixed dynamic/static runtime beat-count/`RLAST` validation behavior
  and public sample.
- `.288` mixed dynamic/static runtime-validation readiness audit.
- `.287` mixed dynamic/static report-only raw-`ARLEN` burst-length behavior.
- `.284` scalar read-data over generated mixed dynamic/static read
  response-demux.
- `.280` mixed dynamic/static read burst-last `RID && RLAST` response-demux.
- `.268` multiple dynamic multi-beat output-bank behavior.
- `.243` single-active dynamic multi-beat output-bank behavior.
- `.207` mixed auto-ID plus concrete queue-head multi-beat output-bank
  behavior and `.202` mixed auto-ID plus queue-head runtime-validation
  behavior.
- Current read-data coverage, output-bank, matched-beat, burst-length,
  beat-count, status-aggregation, report, support-accounting, and focused
  validation helpers.
- README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map state.

## Readiness Finding

The lower substrate is ready for a direct mixed dynamic/static multi-beat
implementation slice.

The `.289` runtime-validation implementation already proves the exact mixed
dynamic/static source boundary needed by multi-beat read-data:

- generated mixed dynamic/static read burst-last response-demux;
- exactly one dynamic read transaction and one concrete static read
  transaction;
- request-captured raw `ARLEN`;
- expected-beat storage and read-beat counters;
- raw matched-read-beat increment expressions for the dynamic captured `RID`
  and the static concrete `RID`; and
- four beat-count/`RLAST` assertions per covered transaction.

The `.243`, `.268`, and `.207` multi-beat slices prove that the existing
output-bank machinery is transaction-list driven once coverage returns the
ordered transaction set and completion-signal map. It already emits
per-transaction data/status lanes, valid masks, length outputs, scalar
worst-observed `RRESP` aggregates, output-bank initialization, raw
matched-beat lane capture, and report fields for `bounded_multi_beat_read_data_contract`.

The current blocking point is deliberately local: the mixed dynamic/static
read-data coverage branch accepts single-beat, last-beat, and last-beat
`burst-length` metadata, but does not yet admit `capture-scope multi-beat`.
A temporary candidate using the expected multi-beat source shape failed closed
only at that coverage diagnostic:

```text
AXI manager capacity/status IAL2 contract read_data.read mixed dynamic/static
coverage requires generated mixed dynamic/static read single-beat response_demux
with capture_scope single-beat and no burst_length metadata, generated mixed
dynamic/static read burst-last response_demux with capture_scope last-beat and
no burst_length metadata, or generated mixed dynamic/static read burst-last
response_demux with capture_scope last-beat and report-only or runtime-assertion
burst_length metadata in this slice
```

That failure happens before lower-layer emission. It shows the implementation
boundary is the mixed coverage predicate, public sample/support entry,
focused tests, docs, and report/residue expectations, not a new IAL1, IAL0,
or SystemVerilog prerequisite.

## Selected .291 Boundary

`.291` should implement only the bounded multi-beat sibling of the `.289`
runtime shape:

- exactly one transaction-local dynamic read transaction;
- exactly one concrete static read transaction;
- generated mixed dynamic/static `response-demux.read` with
  `response-scope burst-last`, one-bit `last-signal`, and
  `transaction-completion generated`;
- `read-data.read` with `capture-scope multi-beat`, `completion-source
  response-demux`, `status-policy per-beat`, `status-aggregation
  worst-observed`, and `interleaving multi-beat-by-rid`;
- existing `burst-length` syntax with `source arlen`, width-8 signal,
  `axlen-plus-one`, request capture, `max-beats` in `1..256`, and
  `validation runtime-assertion`;
- complete output-bank bindings for the dynamic and static read transactions:
  `data-output-prefix`, `status-output-prefix`,
  `status-aggregate-output`, `valid-mask-output`, and `length-output`;
- generated `axi0_arlen` input, raw `ARLEN` storage, expected-beat storage,
  read-beat counter storage, request-time output-bank initialization and
  beat-count initialization, raw matched-read-beat lane capture rules,
  scalar `RRESP` aggregate update rules, and four runtime assertions per
  covered transaction; and
- report mode `bounded_multi_beat_read_data_contract`,
  `completion_validity:
  generated_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse`,
  `beat_match_source: response_demux_matched_read_beat`,
  `output_shape: per_beat_output_bank`,
  empty read-data residue, and response-demux residue limited to
  `same_id_ordering`.

The public sample should be:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_multi_beat.ppif
```

The support-accounting entry should use:

```text
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_multi_beat
```

## Diagnostics

`.291` should preserve fail-closed diagnostics for:

- mixed dynamic/static multi-beat read-data without runtime-assertion
  `burst-length` metadata;
- missing `status-aggregation` or non-`worst-observed` status aggregation;
- `status-policy` other than `per-beat`;
- `interleaving` other than `multi-beat-by-rid`;
- missing, duplicate, partial, or extra output-bank transaction bindings;
- more than one dynamic read transaction or more than one concrete static
  read transaction;
- generated completion signal counts that do not match the covered dynamic
  plus static transaction set;
- multiple mixed dynamic/static transactions;
- same-cycle request widening beyond the current onehot0 policy;
- same-cycle release-and-recapture;
- dynamic same-ID queues and scoreboards;
- direct backend behavior;
- backend-language variants; and
- VHDL.

## Validation Gates For .291

The implementation owner should run:

- Perl syntax checks for touched modules/tests;
- direct schedule/check/semantic/verify-HDL probes for the new multi-beat
  public sample;
- direct report preservation probes for `.289` runtime scalar and `.287`
  report-only samples;
- support-accounting validation for the new multi-beat sample;
- focused mixed/dynamic generator test coverage, guarded if it runs long;
- focused fail-closed probes for malformed multi-beat bindings and unsupported
  mixed multi-beat shapes;
- `mdbook build docs/book`;
- Knowledge Map generation/check;
- memory architecture and doctrine checks; and
- `git --no-pager diff --check`.

## Explicit Residue

Multiple mixed dynamic/static transactions, same-cycle widening,
release-and-recapture, dynamic same-ID queues, scoreboards, direct backend
behavior, backend-language variants, and VHDL remain separate exact owners.

## Rollback

Rollback is the `.290` docs-only audit commit. Reverting it restores `.290` as
the active mixed dynamic/static multi-beat readiness audit and removes the
`.291` direct implementation owner.
