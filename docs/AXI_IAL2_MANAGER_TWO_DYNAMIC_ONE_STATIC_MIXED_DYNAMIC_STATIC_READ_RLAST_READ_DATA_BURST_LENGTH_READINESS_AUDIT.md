# AXI IAL2 Manager Two-Dynamic/One-Static Mixed Dynamic/Static Read RLAST Read-Data Burst-Length Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.352`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.352` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.353`, direct bounded implementation of
report-only raw-`ARLEN` burst-length capture over generated
two-dynamic-plus-one-static mixed dynamic/static read burst-last response-demux
and scalar last-beat read-data.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The audit read or reverified:

- `.351` post two-dynamic-plus-one-static mixed dynamic/static read-data
  selector:
  `docs/AXI_IAL2_MANAGER_POST_TWO_DYNAMIC_ONE_STATIC_MIXED_DYNAMIC_STATIC_READ_RLAST_READ_DATA_NEXT_SLICE_SELECTION.md`
- `.350` two-dynamic-plus-one-static mixed dynamic/static scalar read-data
  behavior and public sample.
- `.349` contract selection and `.348` readiness audit.
- `.347` two-dynamic-plus-one-static mixed dynamic/static read burst-last
  `RID && RLAST` response-demux behavior.
- `.344` two-dynamic-plus-one-static mixed dynamic/static read single-beat
  `RID` response-demux behavior.
- `.310`, `.312`, and `.314` two-static mixed dynamic/static raw-`ARLEN`,
  runtime-validation, and multi-beat precedents.
- `.333`, `.335`, and `.337` three-static mixed dynamic/static raw-`ARLEN`,
  runtime-validation, and multi-beat precedents.
- `.263`, `.264`, and `.268` multiple all-dynamic raw-`ARLEN`,
  runtime-validation, and multi-beat precedents.
- Current read-data coverage, burst-length normalization, request-time
  raw-`ARLEN` capture, runtime-validation, multi-beat output-bank, report,
  residue, support-accounting, and focused-validation helpers in
  `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus`.
- README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map state.

## Readiness Finding

The lower substrate is ready for a direct report-only implementation slice.

The current multiple mixed dynamic/static read-data branch in
`_read_data_response_demux_transaction_coverage` already verifies the important
ownership facts for the generated multiple mixed read demux family:

- `generated_multi_mixed_dynamic_static_read_demux` pairs only with scalar
  `capture-scope single-beat`;
- `generated_multi_mixed_dynamic_static_read_demux_last_beat` pairs with
  scalar `capture-scope last-beat` and, for existing owners, runtime-backed
  `capture-scope multi-beat`;
- the `.350` no-`burst_length` exception already admits exactly two dynamic
  read transactions followed by one concrete static read transaction; and
- generated completion signal count must match the covered transaction list.

That branch currently rejects the two-dynamic-plus-one-static last-beat shape
only because the two-dynamic exception is tied to `!has_burst_length`. The next
implementation only needs to widen the last-beat report-only predicate for
exactly two dynamic reads plus one concrete static read. It should keep
two-dynamic-plus-one-static `validation runtime-assertion` and
`capture-scope multi-beat` fail-closed so runtime validation and multi-beat
output banks remain later owners.

The generic burst-length machinery is already transaction-list driven:

- `_normalize_read_data_burst_length` accepts `source arlen`, width-8 signal,
  `axlen-plus-one` encoding, request capture, `max_beats` in `1..256`, and
  `report-only` or `runtime-assertion`;
- `_normalize_read_data_read` attaches per-transaction raw-`ARLEN` storage and
  capture-rule names once burst-length metadata is accepted;
- `_read_data_burst_length_capture_rule_lines` emits one request-guarded raw
  `ARLEN` capture rule per covered read transaction; and
- `_read_data_generated_artifacts` and `_report_read_data` already expose
  generated burst-length inputs, storage, rules, validation mode, and residue
  movement from the normalized transaction list.

Because the public `read-data.read` `burst-length` syntax is already shipped
and the implementation boundary is only the two-dynamic-plus-one-static
coverage admission plus sample/support/test/docs publication, a separate
public contract-selection leaf would not clarify behavior. The direct owner
can name the source shape and diagnostics precisely.

## Selected .353 Boundary

`.353` should implement only the report-only
two-dynamic-plus-one-static mixed dynamic/static raw-`ARLEN` shape:

- exactly two transaction-local dynamic read transactions;
- exactly one concrete static read transaction;
- generated two-dynamic-plus-one-static mixed dynamic/static
  `response-demux.read` with `response-scope burst-last`, one-bit
  `last-signal`, and `transaction-completion generated`;
- `read-data.read` with `capture-scope last-beat`, `completion-source
  response-demux`, `status-policy last-beat`, `interleaving
  last-beat-by-rid`, and complete transaction bindings for `r0`, `r1`, and
  `r2`;
- existing `burst-length` syntax with `source arlen`, width-8 signal,
  `axlen-plus-one`, request capture, `max-beats` in `1..256`, and
  `validation report-only`;
- generated `axi0_arlen` input, per-transaction raw-`ARLEN` storage
  `axi0_r0_arlen_q`, `axi0_r1_arlen_q`, and `axi0_r2_arlen_q`,
  request-guarded raw-`ARLEN` capture rules
  `axi0_r0_burst_length_capture`, `axi0_r1_burst_length_capture`, and
  `axi0_r2_burst_length_capture`, and generated burst-length report fields;
  and
- scalar last-beat `RDATA`/`RRESP` capture remains guarded only by the
  generated mixed `RID && RLAST` completion pulses selected by `.350`.

The public sample should extend the `.350` two-dynamic-plus-one-static
last-beat read-data shape and use:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length.ppif
```

The support-accounting entry should use:

```text
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length
```

The coverage label should be:

```text
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length_pipeline_cli
```

The focused behavior label should be:

```text
mixed_dynamic_static_read_data_multi_dynamic_burst_length
```

## Diagnostics

`.353` should preserve fail-closed diagnostics for:

- two-dynamic-plus-one-static mixed dynamic/static single-beat read-data with
  `burst-length`;
- two-dynamic-plus-one-static mixed dynamic/static last-beat read-data with
  `validation runtime-assertion`;
- two-dynamic-plus-one-static mixed dynamic/static multi-beat read-data;
- transaction sets that are not exactly two dynamic reads plus one concrete
  static read for this new public sample;
- missing, duplicate, partial, or extra read-data transaction bindings;
- generated completion signal counts that do not match the covered transaction
  list;
- broader mixed dynamic/static cardinalities;
- same-cycle request widening beyond the current onehot0 policy;
- same-cycle release-and-recapture;
- dynamic same-ID queues and scoreboards;
- direct backend behavior;
- backend-language variants; and
- VHDL.

The accepted diagnostic should name the
two-dynamic-plus-one-static report-only raw-`ARLEN` exception without moving
runtime validation or multi-beat output banks out of residue.

## Validation Gates For .353

The implementation owner should run:

- Perl syntax checks for touched modules/tests;
- guarded direct schedule/check/semantic/default-HDL/verify-HDL probes for the
  new public sample, or recorded lightweight fallbacks if host-memory guards
  trip before execution;
- support-accounting validation for the new public sample;
- focused mixed/dynamic generator test coverage for
  `mixed_dynamic_static_read_data_multi_dynamic_burst_length`;
- focused preservation checks for `.350` two-dynamic-plus-one-static scalar
  last-beat read-data, `.347` burst-last response-demux, `.344` single-beat
  response-demux, `.310` two-static report-only raw-`ARLEN`, `.333`
  three-static report-only raw-`ARLEN`, and a representative multiple
  all-dynamic report-only raw-`ARLEN` sample;
- focused fail-closed coverage for the two-dynamic-plus-one-static
  runtime-validation and multi-beat output-bank shapes if those probes can run
  without broad-suite cost;
- `mdbook build docs/book`;
- Knowledge Map generation/check;
- memory architecture and doctrine checks; and
- `git --no-pager diff --check`.

## Explicit Residue

Runtime beat-count/`RLAST` validation over the
two-dynamic-plus-one-static raw-`ARLEN` shape, multi-beat output banks,
single-beat read-data over `.344`, broader mixed dynamic/static cardinalities,
same-cycle widening, release-and-recapture, dynamic same-ID queues,
scoreboards, direct backend behavior, backend-language variants, VHDL, profile
aliases, queued/blocking policy, and full AXI manager behavior remain separate
exact owners.

## Rollback

Rollback is the `.352` docs-only audit commit plus any later `.353`
implementation commit, if present. Reverting `.352` restores `.352` as the
active readiness audit and removes the `.353` direct implementation owner.
