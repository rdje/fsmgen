# AXI IAL2 Manager Mixed Auto-ID Queue-Head Multi-Beat Readiness Audit

Status: readiness audit for `IAL2-FEATURE-COMPLETENESS-FRONTIER.206` on
2026-06-21.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.206`

## Decision

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.207`, direct bounded
implementation of generated multi-beat read-data output-bank behavior over
the selected same-family mixed auto-ID plus depth-2 concrete same-ID
queue-head read burst-last runtime-validation shape.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation, generated-artifact, test, or HDL behavior.

## Evidence Read

The audit read:

- `.205` selector:
  `docs/AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_SUPPORT_CLEANUP_NEXT_SLICE_SELECTION.md`.
- `.204` support cleanup:
  `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_SUPPORT_RESIDUE_CLEANUP.md`.
- `.202` runtime-validation behavior:
  `docs/AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md`.
- `.200` report-only raw-`ARLEN` behavior, `.197` mixed scalar read-data
  behavior, and `.194` mixed response-demux behavior.
- Adjacent generated multi-beat precedents:
  auto-ID multi-beat output-bank behavior, concrete depth-2 queue-head
  multi-beat behavior, one-depth-3 queue-head readiness/behavior, depth-2
  multi-group queue-head behavior, and multiple/mixed depth-3 readiness and
  behavior.
- Current implementation and focused-test surfaces:
  `_read_data_response_demux_transaction_coverage`,
  `_normalize_read_data_read`, `_read_data_multi_beat_output_init_rule_lines`,
  `_read_data_capture_rule_lines`, `_read_data_generated_artifacts`,
  `assert_read_data_multi_beat_report`, and the focused PPIF case builders.
- README, `ROADMAP_V2.md`, mdBook, downstream integration spec, public
  interface contract, task tree, Memory, and Knowledge Map.

## Live Probe Findings

The shipped `.202` runtime sample remains scalar last-beat read-data and
already generates runtime beat-count/`RLAST` validation:

```text
ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length_runtime_assertion.ppif
  mode=bounded_last_beat_read_data_contract
  capture=last_beat
  completion=generated_mixed_auto_id_queue_head_response_demux_last_beat_completion_pulse
  validation=runtime_assertion
  beat_count=1
  transactions=r0,r1,r2
  beat_storage=3
  beat_rules=6
  beat_assertions=12
  residue=multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation
```

The `.200` report-only sibling is preserved and still keeps
`generated_beat_count_validation` residue:

```text
ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length.ppif
  mode=bounded_last_beat_read_data_contract
  capture=last_beat
  completion=generated_mixed_auto_id_queue_head_response_demux_last_beat_completion_pulse
  validation=report_only
  residue=generated_beat_count_validation,multi_beat_read_data_reassembly,per_beat_outputs,rresp_aggregation
```

A temporary `/tmp` PPIF mutation changed only the `.202` read-data shape to
multi-beat output-bank bindings for `r0`, `r1`, and `r2`:

```text
capture-scope multi-beat
status-policy per-beat
status-aggregation worst-observed
interleaving multi-beat-by-rid
runtime-assertion ARLEN burst-length metadata
per-transaction data/status prefixes, valid masks, length outputs,
and scalar status aggregate outputs
```

That candidate fails closed at the mixed read-data coverage predicate:

```text
AXI manager capacity/status IAL2 contract read_data.read mixed auto-ID plus
queue-head coverage requires one read auto-ID transaction and one depth-2
concrete same-ID read queue group with capture_scope single-beat or last-beat
in this slice
```

The failure happens before multi-beat normalization and artifact projection.
It does not point to a parser, support-accounting, report, IAL1, IAL0,
SystemVerilog, or HDL-validation prerequisite.

The adjacent multi-beat precedents confirm the expected transaction-list
behavior:

```text
ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data.ppif
  transactions=r0,r1,r2
  capture_rules=48
  residue=

ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data.ppif
  transactions=r0,r1,r2,r3
  capture_rules=64
  residue=

ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_multi_beat_read_data.ppif
  transactions=r0,r1,r2,r3,r4
  data_outputs=80
  status_outputs=80
  valid_outputs=5
  length_outputs=5
  init_rules=5
  capture_rules=80
  aggregate_outputs=5
  aggregate_rules=5
  residue=
```

The `.202` target has three covered transactions, so the later implementation
should emit 48 multi-beat `RDATA` lane outputs, 48 multi-beat `RRESP` lane
outputs, three valid masks, three length outputs, three scalar aggregate
outputs, three output-init rules, 48 per-lane capture rules, three aggregate
update rules, three raw-`ARLEN` storage signals, three expected-beat storage
signals, three read-beat counters, six beat-count rules, and twelve
beat-count/`RLAST` assertions.

## Code Findings

`_read_data_response_demux_transaction_coverage` already has a mixed
`generated_demux_and_queue_head_demux` branch that admits the exact target
transaction set for `single-beat` and `last-beat`. Its current diagnostic is
the only local blocker because the branch does not admit `multi-beat`.

After that branch admits the target, the generated behavior is already
transaction-list driven:

- `_normalize_read_data_read` expands per-transaction multi-beat lane names,
  valid masks, length outputs, scalar `RRESP` aggregate outputs, raw `ARLEN`
  storage, expected-beat state, beat counters, and runtime assertions.
- `_read_data_multi_beat_output_init_rule_lines` emits one output-bank clear
  rule per covered transaction.
- `_read_data_capture_rule_lines` emits per-lane capture rules using the
  matched read beat, the transaction request exclusion, and the current
  per-transaction beat counter.
- `_read_data_generated_artifacts` collects inputs, outputs, rules,
  multi-beat output lists, aggregate outputs/rules, burst-length artifacts,
  beat-count artifacts, and assertions by iterating `read.transactions`.
- `assert_read_data_multi_beat_report` already accepts an explicit
  `transactions => [...]` list and derives the expected names and counts from
  that list.

`_read_data_response_states_by_transaction` reuses the current response-demux
state list. For the mixed target that list contains the auto-ID state for
`r0` and the queue-head states for `r1` and `r2`; the matched-read-beat helper
therefore already has the two required match styles after admission.

## Selected .207 Boundary

`.207` should implement only:

- read family only;
- `response-demux.read.response-scope burst-last`;
- same-family mixed auto-ID lifecycle plus one concrete same-ID queue-head
  group;
- exactly one read auto-ID transaction (`r0`) and exactly one depth-2 concrete
  same-ID read queue group (`r1`, `r2`);
- generated mixed response-demux boundary
  `generated_demux_and_queue_head_demux`;
- generated queue behavior boundary
  `generated_read_burst_last_queue_head_demux`;
- one-bit `RLAST`;
- `read-data.read.capture-scope multi-beat`;
- `completion-source response-demux`;
- `status-policy per-beat`;
- `status-aggregation (policy worst-observed)`;
- `interleaving multi-beat-by-rid`;
- `burst-length` metadata with `source arlen`, signal `axi0_arlen` width 8,
  `encoding axlen-plus-one`, `capture request`, `max-beats 16`, and
  `validation runtime-assertion`;
- per-transaction `data-output-prefix`, `status-output-prefix`,
  `status-aggregate-output`, `valid-mask-output`, and `length-output`
  bindings for `r0`, `r1`, and `r2`;
- one public support-accounted PPIF sample expected to be named
  `ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_multi_beat_read_data.ppif`;
- focused generator and PPIF/CLI expectations, direct schedule/check/semantic
  JSON and HDL probes, README, roadmap, mdBook, task tree, Memory, and
  Knowledge Map updates.

Expected report movement:

- `read_data.mode: bounded_multi_beat_read_data_contract`;
- `read_data.read.completion_validity:
  generated_mixed_auto_id_queue_head_response_demux_last_beat_completion_pulse`;
- `read_data.read.beat_match_source:
  response_demux_matched_read_beat`;
- `read_data.read.beat_count_match_source:
  response_demux_matched_read_beat`;
- `read_data.read.output_shape: per_beat_output_bank`;
- `read_data.read.status_aggregation: worst_observed`;
- `read_data.read.status_aggregation_generated_behavior: true`;
- `read_data.read.multi_beat_reassembly_generated_behavior: true`;
- `read_data.residue: []`;
- `response_demux.residue: []`;
- `same_id_ordering.residue` continues to keep broader per-ID queue residue.

## Preservation Matrix

`.207` must preserve:

- `.202` mixed runtime-validation scalar last-beat sample and support
  identity;
- `.200` mixed report-only raw-`ARLEN` sample and support identity;
- `.197` mixed scalar read-data samples;
- `.194` mixed response-demux-only samples;
- auto-ID multi-beat behavior;
- concrete depth-2 queue-head multi-beat behavior;
- one-depth-3 queue-head multi-beat behavior;
- depth-2 multi-group queue-head multi-beat behavior;
- multiple/mixed depth-3 multi-beat behavior;
- existing support-accounting entries, strict check JSON, semantic JSON, and
  generated HDL for all existing samples.

## Validation Gates For .207

The implementation slice should run:

- syntax checks for every touched Perl module and focused test;
- direct schedule JSON, strict check JSON, strict semantic JSON, and
  `--verify-hdl` probes for the new public mixed multi-beat PPIF sample;
- preservation probes for `.202`, `.200`, `.197`, `.194`, and adjacent
  concrete/auto/multiple multi-beat samples;
- focused generator and PPIF/CLI tests, with the known oversized-harness
  caveat if they provide no output for several minutes;
- support-accounting catalog and supported-corpus gates if the support catalog
  changes;
- Knowledge Map generation/check, mdBook build, docs path audit, memory
  architecture check, diff hygiene, README numbering, and stale/positive
  frontier scans.

## Deferred Work

The following remain outside `.207`:

- broader concrete same-ID queues beyond the selected depth-2 mixed group;
- group-local simultaneous enqueue widening;
- write-family read-data;
- packed burst-vector outputs;
- alternate full burst payload assembly;
- aggregate-only status output shapes beyond the selected scalar aggregate;
- public aliases or full-manager syntax;
- direct backend lowering;
- verification-output generation;
- VHDL/backend-language variants.

## Rollback Boundary

Rollback should be local to the mixed multi-beat admission branch in
`_read_data_response_demux_transaction_coverage`, the new public PPIF sample,
support-accounting entry, focused generator/PPIF expectations, and the
documentation/Knowledge Map/Memory updates. It should not affect parser
syntax, existing mixed scalar/runtime behavior, generated response-demux
state helpers, transaction-list read-data artifact helpers, IAL1/IAL0
lowering, or previously shipped samples.
