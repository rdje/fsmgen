# AXI IAL2 Manager Dynamic Multi-Beat Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.242`

Date: 2026-06-22

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.243`, direct bounded
implementation of generated dynamic multi-beat read-data output-bank behavior
over the selected single-active dynamic read runtime-validation boundary.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Evidence Read

The audit read or used:

- `.241` post-runtime selector:
  `docs/AXI_IAL2_MANAGER_POST_DYNAMIC_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md`
- `.240` dynamic runtime-validation behavior:
  `docs/AXI_IAL2_MANAGER_DYNAMIC_RUNTIME_VALIDATION_BEHAVIOR.md`
- `.239` runtime readiness audit and `.238` report-only dynamic
  raw-`ARLEN` behavior.
- `.236` bounded dynamic focused-suite cleanup.
- `.234` scalar dynamic read-data behavior.
- `.231` dynamic read burst-last `RID && RLAST` response-demux behavior.
- Non-dynamic output-bank precedents for auto-ID, concrete queue-head,
  multiple/mixed queue-head, and same-family mixed auto-ID plus concrete
  queue-head response-demux.
- Current implementation surfaces:
  `_read_data_response_demux_transaction_coverage`,
  `_normalize_read_data_read`, `_read_data_response_states_by_transaction`,
  `_read_data_matched_read_beat_expr`,
  `_read_data_multi_beat_output_init_rule_lines`,
  `_read_data_capture_rule_lines`, `_read_data_generated_artifacts`,
  `_read_data_covers_multi_beat_by_rid_interleaving`, and
  `_read_data_covers_bounded_multi_beat_burst_output`.
- `t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t`, PPIF/CLI
  support-accounting surfaces, README, `ROADMAP_V2.md`, mdBook, task tree,
  Memory, and Knowledge Map.

## Live Probe

An in-memory mutation of
`ppif/axi_manager_capacity_status_dynamic_read_data_burst_length_runtime_assertion.ppif`
changed only the selected read-data shape to:

```text
capture-scope multi-beat
status-policy per-beat
status-aggregation worst-observed
interleaving multi-beat-by-rid
runtime-assertion ARLEN burst-length metadata
transaction r0:
  data-output-prefix axi0_r0_beat_rdata
  status-output-prefix axi0_r0_beat_rresp
  status-aggregate-output axi0_r0_rresp
  valid-mask-output axi0_r0_beat_valid
  length-output axi0_r0_read_beats
```

It fails closed at the expected dynamic coverage gate:

```text
AXI manager capacity/status IAL2 contract read_data.read dynamic coverage
requires generated dynamic read single-beat response_demux with capture_scope
single-beat and no burst_length metadata, or generated dynamic read burst-last
response_demux with capture_scope last-beat and no burst_length metadata,
report-only burst_length metadata, or runtime-assertion burst_length metadata
in this slice
```

The failure occurs before multi-beat output normalization or generated
artifact projection. It does not point to a parser, PPIF syntax,
support-accounting, IAL1, IAL0, SystemVerilog, or HDL prerequisite.

## Code Findings

The implementation substrate is already transaction-list driven after
coverage admission:

- `_normalize_read_data_read` accepts `capture_scope multi-beat`,
  `status_policy per-beat`, optional `status_aggregation worst-observed`,
  `interleaving multi-beat-by-rid`, runtime-assertion `burst_length`
  metadata, and per-transaction output-bank bindings.
- The same normalizer already creates raw `ARLEN` storage, expected-beat
  state, read-beat counters, beat-count rules/assertions, multi-beat output
  init rules, per-lane capture rule names, valid masks, length outputs, and
  optional scalar status aggregation for every covered transaction.
- `_read_data_response_states_by_transaction` reuses generated read
  response-demux transaction states. The dynamic state already includes
  selected-ID and busy storage.
- `_read_data_matched_read_beat_expr` builds the raw accepted read beat plus
  dynamic `RID == captured_id` match, without `RLAST`, which is the correct
  lane-capture source.
- `_read_data_multi_beat_output_init_rule_lines` and
  `_read_data_capture_rule_lines` already use the request event, matched read
  beat, transaction beat counter, and per-lane index to clear and capture the
  output bank.
- `_read_data_generated_artifacts` already projects generated inputs,
  outputs, multi-beat data/status lanes, valid masks, length outputs, output
  init rules, lane capture rules, scalar aggregate outputs/rules,
  burst-length storage/rules, expected-beat storage, beat-count storage/rules,
  and beat-count assertions.

Two local gates remain:

- `_read_data_response_demux_transaction_coverage` has dynamic branches only
  for `single-beat` and `last-beat` capture scopes. It should admit exactly
  one dynamic read transaction for `capture-scope multi-beat` only when the
  response demux is generated burst-last dynamic read, burst-length metadata
  exists, and validation is `runtime_assertion`.
- `_read_data_covers_multi_beat_by_rid_interleaving` and
  `_read_data_covers_bounded_multi_beat_burst_output` currently require the
  read family to be covered by same-ID ordering. The `.243` implementation
  should extend those recognition helpers to treat the selected generated
  dynamic read response-demux plus dynamic multi-beat read-data output-bank
  as covering read-data interleaving and burst output for report residue
  purposes.

No new public syntax selector is needed. The existing multi-beat `read-data`
syntax and runtime-assertion `burst-length` contract are already public.

## Selected .243 Boundary

`.243` should implement only:

- read family only;
- exactly one transaction-local dynamic read transaction;
- generated `response-demux.read` with `response-scope burst-last`, one-bit
  `last-signal`, generated transaction completion, and
  `generated_dynamic_demux_last_beat` transaction completion source;
- `read-data.read capture-scope multi-beat`;
- `completion-source response-demux`;
- `status-policy per-beat`;
- `status-aggregation (policy worst-observed)`;
- `interleaving multi-beat-by-rid`;
- `burst-length` metadata with `source arlen`, signal width `8`,
  `encoding axlen-plus-one`, `capture request`, bounded `max-beats`, and
  `validation runtime-assertion`;
- per-transaction `data-output-prefix`, `status-output-prefix`,
  `status-aggregate-output`, `valid-mask-output`, and `length-output`
  bindings for the one dynamic read transaction;
- per-lane capture from raw matched dynamic read beats, not the final
  `RID && RLAST` completion pulse;
- report fields for dynamic completion validity, output-bank shape, generated
  lane outputs, valid mask, length output, scalar aggregate output/rules,
  burst-length storage/rules, expected-beat storage, beat-count storage/rules,
  and beat-count assertions; and
- residue cleanup for the selected dynamic multi-beat sample.

Expected public sample:

```text
ppif/axi_manager_capacity_status_dynamic_read_data_multi_beat.ppif
```

Expected support-accounting entry and coverage bucket:

```text
intent.ppif_axi_manager_capacity_status_dynamic_read_data_multi_beat
ial2_ppif_manager_capacity_status_dynamic_read_data_multi_beat_pipeline_cli
```

For the default `max-beats 16` public sample, expected generated artifacts are:

- one raw `ARLEN` storage signal;
- one expected-beat storage signal;
- one read-beat counter;
- two beat-count rules;
- four beat-count/`RLAST` assertions;
- one output-bank init rule;
- sixteen `RDATA` lane outputs;
- sixteen `RRESP` lane outputs;
- sixteen per-lane capture rules;
- one valid-mask output;
- one length output;
- one scalar `RRESP` aggregate output; and
- one scalar aggregate update rule.

Expected report movement:

- `read_data.mode: bounded_multi_beat_read_data_contract`;
- `read_data.read.completion_validity:
  generated_dynamic_read_response_demux_last_beat_completion_pulse`;
- `read_data.read.beat_match_source:
  response_demux_matched_read_beat`;
- `read_data.read.beat_count_match_source:
  response_demux_matched_read_beat`;
- `read_data.read.output_shape: per_beat_output_bank`;
- `read_data.read.status_aggregation: worst_observed`;
- `read_data.read.status_aggregation_generated_behavior: true`;
- `read_data.read.multi_beat_reassembly_generated_behavior: true`;
- `read_data.residue: []`;
- `response_demux.residue` removes `read_data_interleaving` and `bursts` for
  the selected sample while keeping unrelated future dynamic residue.

## Preservation Matrix

`.243` must preserve:

- `.240` dynamic runtime-validation scalar last-beat sample and support
  identity;
- `.238` dynamic report-only raw-`ARLEN` sample and support identity;
- `.234` scalar dynamic read-data single-beat and last-beat samples;
- `.231` dynamic read burst-last response-demux-only sample;
- `.227` dynamic read single-beat response-demux sample;
- `.223` dynamic write response-demux sample;
- `.219` metadata-only dynamic transaction sample;
- all auto-ID, queue-head, multiple/mixed queue-head, and mixed auto-ID plus
  concrete queue-head multi-beat output-bank samples; and
- fail-closed diagnostics for dynamic single-beat burst-length, multiple
  dynamic read/write transactions, mixed dynamic/static demux, same-cycle
  recapture, dynamic same-ID ordering, queues, scoreboards, direct backend
  behavior, backend-language variants, and VHDL.

## Validation Gates

`.243` should run:

- syntax checks for touched Perl modules/tests;
- direct schedule JSON, strict check JSON, semantic JSON, default HDL, and
  `--verify-hdl` probes for the new public dynamic multi-beat sample;
- preservation schedule/strict/HDL probes for `.238` and `.240`;
- focused fail-closed probes for unsupported dynamic multi-beat variants;
- guarded `prove -Iperl t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t`;
- guarded `prove -Iperl t/248-regression-corpus-accounting.t`;
- Knowledge Map generation/check, mdBook build, memory architecture,
  doctrine checks, diff hygiene, and temporary-artifact cleanup.

Full `t/1436` and `t/1437` remain non-routine unless the implementation can
run a bounded filtered subset without exceeding host guard limits; `t/1438`
is the routine dynamic-family closeout target.

## Rollback

Rollback for `.242` is this audit record plus task-tree/live-doc/Memory and
Knowledge Map updates. No behavior-bearing file changes in this slice.

Rollback for `.243` should remove only the dynamic multi-beat PPIF sample,
support-accounting entry, dynamic multi-beat coverage/report widening,
focused tests, and matching docs/facts, while preserving `.238` and `.240`.
