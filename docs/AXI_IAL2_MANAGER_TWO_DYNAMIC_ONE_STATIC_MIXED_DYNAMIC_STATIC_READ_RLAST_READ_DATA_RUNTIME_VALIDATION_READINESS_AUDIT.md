# AXI IAL2 Manager Two-Dynamic/One-Static Mixed Dynamic/Static Read RLAST Read-Data Runtime-Validation Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.354`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.354` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.355`, direct bounded implementation of
runtime beat-count/`RLAST` validation over the generated
two-dynamic-plus-one-static mixed dynamic/static raw-`ARLEN` scalar last-beat
read-data boundary shipped by `.353`.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The audit read or reverified:

- `.353` two-dynamic-plus-one-static mixed dynamic/static report-only
  raw-`ARLEN` burst-length behavior and its public sample.
- `.352` report-only raw-`ARLEN` readiness audit.
- `.350` scalar last-beat read-data behavior over the generated
  two-dynamic-plus-one-static mixed read burst-last response-demux.
- `.347` generated two-dynamic-plus-one-static mixed read burst-last
  `RID && RLAST` response-demux behavior.
- `.344` generated two-dynamic-plus-one-static mixed read single-beat `RID`
  response-demux behavior.
- `.312` two-static mixed dynamic/static runtime beat-count/`RLAST`
  validation behavior and `.314` two-static multi-beat output-bank behavior.
- `.335` three-static mixed dynamic/static runtime beat-count/`RLAST`
  validation behavior and `.337` three-static multi-beat output-bank behavior.
- Multiple all-dynamic runtime and multi-beat precedents.
- Current read-data coverage, burst-length normalization, expected-beat
  storage, beat-count/`RLAST` assertion, report, generated-artifact,
  support-accounting, focused-validation, and RAM-guard behavior.
- README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map state.

## Readiness Finding

The lower substrate is ready for a direct runtime-validation implementation
slice.

The `.353` report-only implementation already proves the exact source shape:

- generated two-dynamic-plus-one-static mixed dynamic/static read burst-last
  response-demux;
- exactly two transaction-local dynamic read transactions, `r0` and `r1`;
- exactly one concrete static read transaction, `r2`, with reserved `RID`
  `4'd3`;
- generated final-beat completion pulses for all three covered transactions;
- request-time raw-`ARLEN` storage and capture rules per covered transaction;
  and
- scalar `RDATA`/`RRESP` capture guarded by generated `RID && RLAST`
  completion pulses.

The current coverage gate already recognizes report-only burst-length metadata
for this exact cardinality, while the generic runtime-validation machinery is
transaction-list driven once coverage admits the transaction set. The same
helpers used by the all-dynamic, two-static, and three-static runtime slices
derive:

- expected-beat storage per covered transaction;
- read-beat counter storage per covered transaction;
- request-time expected-beat initialization from `ARLEN + 1`;
- request-time beat-counter reset;
- raw matched-read-beat counter increments through
  `_read_data_matched_read_beat_expr`;
- four beat-count/`RLAST` assertions per covered transaction; and
- schedule/check/semantic report fields for generated expected-beat storage,
  beat-count storage, beat-count rules, beat-count assertions, and residue
  movement.

For this two-dynamic-plus-one-static mixed read demux, the matched-beat
expression resolves through the response-demux transaction states already
emitted by `.347` and consumed by `.350` and `.353`: `r0` and `r1` match raw
accepted read beats by their captured dynamic `RID` values, while `r2` matches
raw accepted read beats by reserved concrete `RID` `4'd3`. The matched-beat
expression intentionally does not include `RLAST`; the runtime assertions
check whether `RLAST` appears exactly on the expected final beat.

Because the public `burst-length` syntax, runtime report vocabulary, and
assertion semantics are already shipped by earlier runtime slices, a separate
public contract-selection leaf would not add clarity. The next owner can be a
direct behavior slice whose main code change is adding the exact
two-dynamic-plus-one-static runtime-admission predicate, while preserving the
existing report-only behavior and leaving multi-beat output banks to a later
owner.

## Selected .355 Boundary

`.355` should implement only the runtime-validation sibling of the `.353`
report-only shape:

- exactly two transaction-local dynamic read transactions, `r0` and `r1`;
- exactly one concrete static read transaction, `r2`, reserved to `RID`
  `4'd3`;
- generated multiple mixed dynamic/static `response-demux.read` with
  `response-scope burst-last`, one-bit `last-signal`, and
  `transaction-completion generated`;
- `read-data.read` with `capture-scope last-beat`, `completion-source
  response-demux`, `status-policy last-beat`, `interleaving
  last-beat-by-rid`, and complete transaction bindings for `r0`, `r1`, and
  `r2`;
- existing `burst-length` syntax with `source arlen`, width-8 signal,
  `axlen-plus-one`, request capture, `max-beats` in `1..256`, and
  `validation runtime-assertion`;
- generated `axi0_arlen` input;
- per-transaction raw `ARLEN` storage, expected-beat storage, read-beat
  counter storage, request-time beat-count initialization rules, raw
  matched-read-beat increment rules, and four runtime assertions per covered
  transaction; and
- scalar last-beat `RDATA`/`RRESP` capture remains guarded only by generated
  mixed `RID && RLAST` completion pulses.

The public sample should be the runtime sibling of `.353`:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length_runtime_assertion.ppif
```

The support-accounting entry should use:

```text
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length_runtime_assertion
```

The coverage label should be:

```text
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length_runtime_assertion_pipeline_cli
```

The focused behavior label should be:

```text
mixed_dynamic_static_read_data_multi_dynamic_burst_length_runtime_assertion
```

The generated report should keep:

```text
read_data.mode = bounded_last_beat_read_data_contract
read_data.read.completion_validity =
  generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse
read_data.read.burst_length_source = arlen_signal
read_data.read.burst_length_validation = runtime_assertion
read_data.read.beat_count_validation_generated_behavior = true
read_data.read.expected_beat_count_encoding = arlen_plus_one
read_data.read.beat_count_match_source = response_demux_matched_read_beat
```

## Diagnostics

`.355` should preserve fail-closed diagnostics for:

- two-dynamic-plus-one-static mixed dynamic/static single-beat read-data with
  `burst-length`;
- two-dynamic-plus-one-static mixed dynamic/static multi-beat read-data;
- transaction sets that are not exactly two dynamic reads plus one concrete
  static read for the new public runtime sample;
- missing, duplicate, partial, or extra read-data transaction bindings;
- generated completion signal counts that do not match the covered
  transaction list;
- broader mixed dynamic/static cardinalities;
- same-cycle request widening beyond the current onehot0 policy;
- same-cycle release-and-recapture;
- dynamic same-ID queues and scoreboards;
- direct backend behavior;
- backend-language variants; and
- VHDL.

The accepted diagnostic should name both report-only and runtime-assertion
last-beat raw-`ARLEN` read-data for the two-dynamic-plus-one-static mixed
dynamic/static branch, without admitting the two-dynamic-plus-one-static
multi-beat output-bank shape.

## Validation Gates For .355

The implementation owner should run:

- Perl syntax checks for touched modules/tests;
- guarded direct schedule/check/semantic/default-HDL/verify-HDL probes for the
  new runtime public sample, or recorded lightweight fallbacks if host-memory
  guards trip before execution;
- preservation probes for the `.353` report-only runtime sibling input, `.350`
  scalar read-data sample, `.347` burst-last demux sample, and `.344`
  single-beat demux sample;
- preservation probes for representative two-static, three-static, and
  all-dynamic runtime-validation samples;
- support-accounting validation for the new runtime sample;
- focused t/1438 coverage for the new behavior label, guarded and narrowed
  when RAM pressure requires it;
- focused fail-closed probes for two-dynamic-plus-one-static multi-beat and
  broader-cardinality variants if practical;
- `mdbook build docs/book`;
- Knowledge Map generation/check;
- memory architecture and doctrine checks; and
- `git --no-pager diff --check`.

## Explicit Residue

Two-dynamic-plus-one-static multi-beat output banks, single-beat read-data over
the `.344` demux, broader mixed dynamic/static cardinalities, same-cycle
widening, release-and-recapture, dynamic same-ID queues, scoreboards, direct
backend behavior, backend-language variants, VHDL, profile aliases,
queued/blocking policy, and full-manager behavior remain separate exact
owners.

## Rollback

Rollback is the `.354` docs-only audit commit. Reverting it restores `.354`
as the active runtime-validation readiness audit and removes the `.355`
direct implementation owner.
