# AXI IAL2 Manager Three-Static Mixed Dynamic/Static Read-Data Runtime-Validation Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.334`

Date: 2026-06-23

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.334` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.335`, direct bounded implementation of
runtime beat-count/`RLAST` validation over generated one-dynamic plus
three-concrete-static mixed dynamic/static raw-`ARLEN` last-beat read-data.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The audit read or reverified:

- `.333` three-static mixed dynamic/static report-only raw-`ARLEN`
  burst-length behavior and its public sample.
- `.332` three-static mixed dynamic/static raw-`ARLEN` readiness audit.
- `.330` three-static mixed dynamic/static scalar read-data behavior.
- `.326` three-static mixed dynamic/static read burst-last `RID && RLAST`
  response-demux behavior.
- `.322` three-static mixed dynamic/static read single-beat `RID`
  response-demux behavior.
- `.312` two-static mixed dynamic/static runtime beat-count/`RLAST`
  validation behavior.
- `.314` two-static mixed dynamic/static multi-beat output-bank behavior.
- Current read-data coverage, burst-length normalization, request-time
  raw-`ARLEN` capture, beat-count rule/assertion, response-demux match,
  report, residue, support-accounting, and focused-validation helpers in
  `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus`.
- README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map state.

## Readiness Finding

The lower substrate is ready for a direct runtime-validation implementation
slice.

The `.333` report-only implementation already proves the exact three-static
last-beat source shape:

- generated one-dynamic plus three-concrete-static mixed dynamic/static read
  burst-last response-demux;
- exactly one transaction-local dynamic read transaction and exactly three
  concrete static read transactions;
- complete ordered `r0`, `r1`, `r2`, and `r3` read-data transaction
  bindings;
- request-time raw-`ARLEN` storage and capture rules per covered transaction;
  and
- scalar `RDATA`/`RRESP` capture guarded by generated mixed `RID && RLAST`
  completion pulses.

The generic runtime-validation machinery used by `.312` is already
transaction-list driven. Once the multiple mixed last-beat read-data coverage
branch admits `validation runtime-assertion` for the three-static
cardinality, the common normalizer and generation helpers derive:

- expected-beat storage per covered transaction;
- read-beat counter storage per covered transaction;
- request-time expected-beat initialization from `ARLEN + 1`;
- request-time beat-counter reset;
- raw matched-read-beat counter increments through
  `_read_data_matched_read_beat_expr`;
- four beat-count/`RLAST` assertions per covered transaction; and
- schedule/check/semantic report fields for generated expected-beat storage,
  beat-count storage, beat-count rules, assertions, and residue movement.

For the three-static mixed read demux, the matched-beat expression resolves
through the response-demux transaction states already emitted by `.326` and
consumed by `.330` and `.333`: the dynamic transaction matches raw accepted
read beats by captured dynamic `RID`, while each static transaction matches
raw accepted read beats by its reserved concrete `RID`. The matched-beat
expression does not include `RLAST`; the runtime assertions check whether
`RLAST` appears exactly on the expected final beat.

Because the public `burst-length` syntax and runtime report vocabulary are
already shipped by earlier runtime slices, a separate public
contract-selection leaf would not add clarity. The next owner can be a direct
behavior slice whose main code change is widening the three-static last-beat
coverage predicate from report-only to report-only or runtime-assertion,
while preserving the fail-closed three-static single-beat `burst-length` and
multi-beat output-bank boundaries.

## Selected .335 Boundary

`.335` should implement only the runtime-validation sibling of the `.333`
report-only shape:

- exactly one transaction-local dynamic read transaction;
- exactly three pairwise-distinct concrete static read transactions;
- generated multiple mixed dynamic/static `response-demux.read` with
  `response-scope burst-last`, one-bit `last-signal`, and
  `transaction-completion generated`;
- `read-data.read` with `capture-scope last-beat`, `completion-source
  response-demux`, `status-policy last-beat`, `interleaving
  last-beat-by-rid`, and complete transaction bindings for `r0`, `r1`, `r2`,
  and `r3`;
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

The public sample should be the runtime sibling of `.333`:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_burst_length_runtime_assertion.ppif
```

The support-accounting entry should use:

```text
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_burst_length_runtime_assertion
```

The coverage label should be:

```text
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_burst_length_runtime_assertion_pipeline_cli
```

The focused behavior label should be:

```text
mixed_dynamic_static_read_data_multi_static3_burst_length_runtime_assertion
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

`.335` should preserve fail-closed diagnostics for:

- three-static mixed dynamic/static single-beat read-data with
  `burst-length`;
- three-static mixed dynamic/static multi-beat read-data;
- transaction sets that are not exactly one dynamic read plus three concrete
  static reads for the new public runtime sample;
- missing, duplicate, partial, or extra read-data transaction bindings;
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

The accepted diagnostic should name both report-only and runtime-assertion
last-beat burst-length metadata for the three-static mixed dynamic/static
branch, without admitting three-static multi-beat output banks.

## Validation Gates For .335

The implementation owner should run:

- Perl syntax checks for touched modules/tests;
- guarded direct schedule/check/semantic/verify-HDL probes for the new runtime
  public sample, or recorded lightweight fallbacks if host-memory guards trip
  before execution;
- preservation probes for the `.333` report-only sample and `.314`
  two-static multi-beat sample;
- support-accounting validation for the new runtime sample;
- focused mixed/dynamic generator test coverage, guarded if it runs long;
- focused fail-closed probes for three-static single-beat `burst-length` and
  three-static multi-beat shapes if practical;
- `mdbook build docs/book`;
- Knowledge Map generation/check;
- memory architecture and doctrine checks; and
- `git --no-pager diff --check`.

## Explicit Residue

Three-static mixed dynamic/static multi-beat output banks, two-dynamic-plus
static shapes, broader mixed dynamic/static cardinalities, same-cycle
widening, release-and-recapture, dynamic same-ID queues, scoreboards, direct
backend behavior, backend-language variants, and VHDL remain separate exact
owners.

## Rollback

Rollback is the `.334` docs-only audit commit. Reverting it restores `.334`
as the active runtime-validation readiness audit and removes the `.335`
direct implementation owner.
