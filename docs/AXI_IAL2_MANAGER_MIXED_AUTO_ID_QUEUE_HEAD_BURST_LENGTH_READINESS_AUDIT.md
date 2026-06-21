# AXI IAL2 Manager Mixed Auto-ID Queue-Head Burst-Length Readiness Audit

Status: readiness audit for `IAL2-FEATURE-COMPLETENESS-FRONTIER.199` on
2026-06-21.

Selected next owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.200`.

## Decision

Select `.200`, direct bounded support/publication of generated report-only
raw-`ARLEN` burst-length capture over the same-family mixed auto-ID lifecycle
plus concrete same-ID queue-head read burst-last scalar last-beat read-data
shape.

The selected implementation should publish one support-accounted public PPIF
sample for the report-only shape and align support/residue prose so report-only
mixed burst-length is no longer classified as deferred. It should also keep
runtime beat-count/`RLAST` validation separately owned. The audit found that
runtime metadata already flows through the current transaction-list helpers in
temporary probes; `.200` must either lock that runtime path fail-closed or
otherwise preserve the public boundary so the report-only slice does not
silently broaden into runtime validation.

No parser, generator, PPIF sample, support-accounting catalog, validation,
generated-artifact, test, or HDL behavior changes are made by this audit
slice.

## Evidence Read

The audit read:

- `.198` selector:
  `docs/AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md`;
- `.197` mixed scalar read-data behavior:
  `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_READ_DATA_BEHAVIOR.md`;
- `.196` mixed read-data readiness audit;
- `.194` mixed response-demux behavior;
- one-group, multi-group, and multiple/mixed depth-3 concrete queue-head
  report-only burst-length, runtime-validation, and multi-beat precedents;
- `_read_data_response_demux_transaction_coverage`,
  `_normalize_read_data_read`, `_normalize_read_data_burst_length`,
  burst-length storage/capture/report helpers, PPIF parser burst-length
  syntax, focused generator/PPIF expectations, support accounting, README,
  ROADMAP_V2, mdBook, public contract/handoff docs, task tree, Memory, and
  Knowledge Map surfaces.

## Temporary Probe Findings

Two temporary candidates were created under `/tmp` from the `.197` public
mixed burst-last scalar read-data sample:

```text
/tmp/fsmgen_199_mixed_burst_length.ppif
/tmp/fsmgen_199_mixed_burst_length_runtime_assertion.ppif
```

The report-only candidate inserts existing syntax:

```lisp
(burst-length
  (source arlen)
  (signal axi0_arlen (width 8))
  (encoding axlen-plus-one)
  (capture request)
  (max-beats 16)
  (validation report-only))
```

The report-only probe strict-checks cleanly, semantic-exports cleanly, and
HDL-verifies. It is not support-accounted because no public sample/support
catalog entry exists yet.

Compact schedule report summary:

```text
validation=report_only
generated_inputs=axi0_rdata,axi0_rresp,axi0_arlen
burst_inputs=axi0_arlen
burst_storage=axi0_r0_arlen_q,axi0_r1_arlen_q,axi0_r2_arlen_q
burst_rules=axi0_r0_burst_length_capture,axi0_r1_burst_length_capture,axi0_r2_burst_length_capture
beat_rules=
beat_assertions=0
completion_validity=generated_mixed_auto_id_queue_head_response_demux_last_beat_completion_pulse
transactions=r0,r1,r2
residue=generated_beat_count_validation,multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation
```

The runtime-assertion comparison probe also strict-checks and emits schedule
metadata today:

```text
validation=runtime_assertion
generated_inputs=axi0_rdata,axi0_rresp,axi0_arlen
burst_inputs=axi0_arlen
burst_storage=axi0_r0_arlen_q,axi0_r1_arlen_q,axi0_r2_arlen_q
burst_rules=axi0_r0_burst_length_capture,axi0_r1_burst_length_capture,axi0_r2_burst_length_capture
beat_rules=axi0_r0_beat_count_init,axi0_r0_read_beat_count,axi0_r1_beat_count_init,axi0_r1_read_beat_count,axi0_r2_beat_count_init,axi0_r2_read_beat_count
beat_assertions=12
completion_validity=generated_mixed_auto_id_queue_head_response_demux_last_beat_completion_pulse
transactions=r0,r1,r2
residue=multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation
```

This runtime finding is not selected for publication in `.200`. It is evidence
that the next implementation owner must make the report-only boundary explicit
instead of leaving runtime support as an unowned side effect.

The existing `.197` public sample still strict-checks cleanly and remains
support-accounted:

```text
ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_read_data.ppif
  support_accounting.matched=true
  coverage=ial2_ppif_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_read_data_pipeline_cli
```

## Code Findings

`_read_data_response_demux_transaction_coverage` already has a mixed
`generated_demux_and_queue_head_demux` branch for `capture_scope last-beat`.
That branch validates the response scope and queue boundary, requires one
auto-ID transaction plus one depth-2 concrete same-ID read queue group, and
returns transaction coverage for `r0`, `r1`, and `r2`. It does not currently
inspect `has_burst_length` or `burst_length_validation`.

Because `_normalize_read_data_read` passes the admitted transaction list to
the existing transaction-list driven helpers, both report-only raw-`ARLEN`
storage/capture and runtime beat-count/`RLAST` metadata already generate in
temporary mixed probes:

- `_normalize_read_data_burst_length` normalizes existing `source arlen`,
  width-8 signal, `axlen-plus-one` encoding, request capture, max-beats, and
  report-only/runtime validation metadata;
- `_read_data_burst_length_storage_lines` and
  `_read_data_burst_length_capture_rule_lines` emit one raw-`ARLEN` storage
  signal and request-guarded capture rule per covered transaction;
- runtime helpers emit expected-beat storage, beat counters, and assertions
  when validation is `runtime_assertion`;
- report/generated-artifact helpers project those fields from the same
  normalized transaction list.

The stale boundary is therefore public support and residue accounting, with a
runtime side-effect that needs explicit ownership. Parser syntax and lower
layers are not blockers.

## Selected `.200` Boundary

`.200` should implement only the report-only public/support boundary:

- add one public PPIF sample, expected name
  `ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length.ppif`;
- keep the existing read burst-last same-family mixed auto-ID plus concrete
  queue-head shape: one auto-ID read transaction `r0`, one depth-2 concrete
  same-ID queue-head read group `r1/r2`, scalar last-beat `RDATA`/`RRESP`,
  one-bit `RLAST`, and `completion-source response-demux`;
- add existing report-only raw-`ARLEN` `burst-length` metadata with width-8
  `axi0_arlen`, request capture, `max-beats 16`, and
  `validation report-only`;
- support-account the public sample and add focused PPIF/CLI and generator
  expectations for `axi0_arlen`, per-transaction raw-`ARLEN` storage/capture
  rules, report-only validation, unchanged mixed completion validity, strict
  support accounting, semantic JSON, and HDL verification;
- align support/residue/capability prose so report-only mixed burst-length is
  supported while runtime validation and multi-beat output banks remain
  separately owned;
- explicitly preserve or lock the runtime-validation boundary so `.200` does
  not publish runtime beat-count/`RLAST` validation as an accidental side
  effect.

## Non-Goals

- Do not implement or support-account runtime beat-count/`RLAST` validation in
  `.200`.
- Do not implement mixed multi-beat output-bank behavior.
- Do not add single-beat burst-length behavior.
- Do not add new PPIF syntax.
- Do not widen group-local simultaneous enqueue behavior.
- Do not add write-family read-data behavior.
- Do not introduce packed burst-vector outputs or alternate full burst payload
  assembly.
- Do not change direct backend, verification-output, VHDL, or
  backend-language variant behavior.
- Do not bypass the `IAL2 -> IAL1 -> IAL0 -> SystemVerilog` lowering chain.

## Validation Gates

The `.200` implementation should run focused Perl syntax checks, direct
strict-check/schedule/semantic/HDL probes for the new public sample,
preservation probes for the `.197` mixed scalar read-data samples and adjacent
concrete queue-head burst-length/runtime samples, focused generator and
PPIF/CLI expectations, support-accounting corpus gates, Knowledge Map, mdBook,
docs path audit, memory architecture, diff hygiene, README numbering, and
stale/positive frontier scans.

## Rollback Boundary

Rollback for `.199` is limited to this audit document, task-tree frontier
movement, README, roadmap, mdBook, public contract/handoff wording, Memory,
and Knowledge Map/fact-card updates. No parser, generator, public sample,
support-accounting catalog, generated artifact, test, validation, or HDL
behavior changes in this audit slice.
