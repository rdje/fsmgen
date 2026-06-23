# AXI IAL2 Manager Mixed Dynamic/Static Read-Data Runtime-Validation Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.288`

Date: 2026-06-23

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.288` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.289`, direct bounded implementation of
runtime beat-count/`RLAST` validation over generated mixed dynamic/static
read burst-last response-demux and scalar last-beat read-data.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The audit read or reverified:

- `.287` mixed dynamic/static report-only raw-`ARLEN` burst-length behavior
  and public sample.
- `.286` mixed dynamic/static read-data burst-length readiness audit.
- `.284` scalar read-data over generated mixed dynamic/static read
  response-demux.
- `.280` mixed dynamic/static read burst-last `RID && RLAST` response-demux.
- `.276` mixed dynamic/static read single-beat `RID` response-demux.
- `.264` multiple-dynamic runtime beat-count/`RLAST` validation behavior.
- `.240` single-active dynamic runtime beat-count/`RLAST` validation
  behavior.
- `.202` mixed auto-ID plus queue-head runtime beat-count/`RLAST` validation
  behavior.
- Current mixed read-data coverage, burst-length normalization,
  request-time raw-`ARLEN` capture, beat-count rule/assertion, report,
  residue, support-accounting, and focused-validation helpers.
- README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map state.

## Readiness Finding

The lower substrate is ready for a direct runtime-validation implementation
slice.

The `.287` report-only implementation already proves the mixed dynamic/static
last-beat source shape:

- generated mixed dynamic/static read burst-last response-demux;
- exactly one dynamic read transaction and one concrete static read
  transaction;
- complete ordered dynamic-plus-static read-data transaction bindings;
- request-time raw-`ARLEN` capture storage and rules per covered
  transaction; and
- scalar `RDATA`/`RRESP` capture guarded by generated mixed `RID && RLAST`
  completion pulses.

The generic runtime-validation machinery used by `.240`, `.264`, and `.202`
is not tied to an all-dynamic or queue-head-only transaction family. Once the
read-data coverage branch admits `validation runtime-assertion`, the common
normalizer and generation helpers already derive:

- expected-beat storage per transaction;
- read-beat counter storage per transaction;
- request-time expected-beat initialization from `ARLEN + 1`;
- raw matched-read-beat counter increments through
  `_read_data_matched_read_beat_expr`;
- four beat-count/`RLAST` assertions per covered transaction; and
- schedule/check/semantic report fields for generated expected-beat storage,
  beat-count storage, beat-count rules, assertions, and residue movement.

For the mixed dynamic/static read demux, the matched-beat expression resolves
through the same response-demux transaction states that `.280` already emits:
the dynamic transaction matches raw accepted read beats by captured dynamic
`RID`, while the static transaction matches raw accepted read beats by the
reserved concrete `RID`. The expression deliberately does not include
`RLAST`; the runtime assertions check whether `RLAST` appears exactly on the
expected final beat.

Because the public `burst-length` syntax and report vocabulary are already
shipped, a separate public contract-selection leaf would not add clarity. The
next owner can be a direct behavior slice whose main code change is widening
the mixed dynamic/static last-beat coverage predicate from report-only to
report-only or runtime-assertion.

## Selected .289 Boundary

`.289` should implement only the runtime-validation sibling of the `.287`
report-only shape:

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
  `validation runtime-assertion`;
- generated `axi0_arlen` input, raw `ARLEN` storage, expected-beat storage,
  read-beat counter storage, request-time beat-count initialization rules,
  raw matched-read-beat increment rules, and four runtime assertions per
  covered transaction; and
- scalar last-beat `RDATA`/`RRESP` capture remains guarded only by generated
  mixed `RID && RLAST` completion pulses.

The public sample should be the runtime sibling of `.287`:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_burst_length_runtime_assertion.ppif
```

The support-accounting entry should use:

```text
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_burst_length_runtime_assertion
```

## Diagnostics

`.289` should preserve fail-closed diagnostics for:

- mixed dynamic/static single-beat read-data with `burst-length`;
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

The accepted diagnostic should name both report-only and runtime-assertion
last-beat burst-length metadata for the mixed dynamic/static branch.

## Validation Gates For .289

The implementation owner should run:

- Perl syntax checks for touched modules/tests;
- direct schedule/check/semantic/verify-HDL probes for the new runtime public
  sample;
- support-accounting validation for the new runtime sample;
- focused mixed/dynamic generator test coverage, guarded if it runs long;
- preservation probes for the `.287` report-only sample;
- focused fail-closed probes for single-beat burst-length and mixed multi-beat
  shapes;
- `mdbook build docs/book`;
- Knowledge Map generation/check;
- memory architecture and doctrine checks; and
- `git --no-pager diff --check`.

## Explicit Residue

Mixed dynamic/static multi-beat output banks, multiple mixed dynamic/static
transactions, same-cycle widening, release-and-recapture, dynamic same-ID
queues, scoreboards, direct backend behavior, backend-language variants, and
VHDL remain separate exact owners.

## Rollback

Rollback is the `.288` docs-only audit commit. Reverting it restores `.288` as
the active runtime-validation readiness audit and removes the `.289` direct
implementation owner.
