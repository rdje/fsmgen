# AXI IAL2 Manager Post Mixed Dynamic/Static Read Same-ID Issue-Order Queue Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.507`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.507` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.508`, readiness audit for generated mixed
dynamic/static read burst-last `RID && RLAST` same-ID `issue-order-queue`
behavior.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, generated artifact, report JSON, test, HDL/runtime behavior, backend
behavior, backend-language variant, external converter dependency,
verification-code output, or VHDL behavior.

## Selection Rationale

`.506` shipped the one-dynamic plus one-concrete-static mixed read single-beat
`RID` issue-order queue. It stores `axi0_arid` for the dynamic enqueue, stores
the sized static literal for the static enqueue, and selects the earliest
matching queue slot by raw `RID`.

The smallest adjacent owner is the same one-dynamic plus one-concrete-static
queue semantics on the already-shipped burst-last read response surface:

```text
response-demux.read.response-scope: burst-last
response ID signal: axi0_rid
last signal: axi0_rlast
dynamic request ID source: axi0_arid
```

This is smaller than read-data over the mixed read queue because it settles
the queue-owned final completion pulse first. It is also smaller than raw
`ARLEN`, runtime beat-count validation, multi-beat output banks, multi-static
or two-dynamic-plus-static mixed queues, scoreboards, arbitrary cardinality,
backend behavior, backend-language variants, VHDL, or external converter
audits.

FSMGen-owned generation/lowering remains the default. External converters
such as `sv2v` remain optional future audit candidates only; `.508` should not
introduce an external dependency.

## Source Anchors

The audit should read these shipped records before implementation is selected:

- `.506` mixed dynamic/static read single-beat `RID` issue-order queue
  behavior;
- `.505` mixed read single-beat issue-order queue readiness audit;
- `.503` mixed dynamic/static write `BID` issue-order queue behavior;
- `.463` all-dynamic read burst-last `RID && RLAST` issue-order queue
  behavior;
- `.459` all-dynamic read single-beat `RID` issue-order queue behavior;
- `.280` mixed dynamic/static read burst-last response-demux behavior;
- `.276` mixed dynamic/static read single-beat response-demux behavior; and
- focused parser/generator/dynamic-ID/support-accounting surfaces.

RAM-guarded schedule-report probes in this selector confirmed:

```text
.506 mixed read queue:
  response_demux.read.mode = bounded_mixed_dynamic_static_read_rid_issue_order_queue_demux_contract
  transaction_completion_source = generated_mixed_dynamic_static_issue_order_queue_demux
  response_scope = single_beat

.463 all-dynamic read burst-last queue:
  response_demux.read.mode = bounded_dynamic_read_rid_rlast_issue_order_queue_demux_contract
  transaction_completion_source = generated_dynamic_issue_order_queue_demux_last_beat
  response_scope = burst_last
  last_signal = axi0_rlast

.280 mixed read RLAST demux:
  response_demux.read.mode = bounded_mixed_dynamic_static_read_rid_rlast_demux_contract
  transaction_completion_source = generated_mixed_dynamic_static_read_demux_last_beat
  transaction_completion_semantics = matched_dynamic_or_static_concrete_id_and_last_signal
  response_scope = burst_last
  last_signal = axi0_rlast
```

Together those records show the next question is local: whether the `.506`
mixed queue planner/report path can be extended to final selected
`RID && RLAST` completion while preserving queue-owned static/dynamic
runtime-ID overlap.

## Candidate Public Shape For `.508`

The likely candidate is a new support-accounted PPIF sample with this shape:

```text
read transactions: r0 dynamic, r1 concrete static value 3
id_families.read width: 4
request ID signal: axi0_arid
response ID signal: axi0_rid
last signal: axi0_rlast (width 1)
same-id-ordering.read: dynamic-id-reuse issue-order-queue
response-demux.read: generated burst-last RID && RLAST completion
submit-policy: try
read-max-pending: 2
queue depth: 2
```

Expected generated report terminology should mirror `.506` and `.463` while
staying mixed-read and burst-last specific:

```text
bounded_mixed_dynamic_static_read_rid_rlast_issue_order_queue_demux_contract
generated_mixed_dynamic_static_issue_order_queue_demux_last_beat
earliest_matching_captured_or_static_runtime_id_and_last_signal
captured_or_static_request_id
mixed_dynamic_static_issue_order_earliest_matching_slot
allowed_by_issue_order_queue
generated_mixed_dynamic_static_read_rid_rlast_issue_order_queue
```

## Non-Goals

`.507` explicitly leaves these for future exact owners:

- implementation until `.508` or a later selected owner;
- read-data over mixed read queues;
- raw `ARLEN`, runtime beat-count validation, and multi-beat output banks over
  mixed read queues;
- multi-static mixed queues;
- two-dynamic-plus-static mixed queues;
- scoreboards;
- arbitrary queue cardinality;
- same-cycle enqueue widening beyond onehot0;
- verification-code generation;
- direct backend behavior;
- backend-language variants;
- external converter dependency selection, including `sv2v`; and
- VHDL.

## Validation

This selector should close with documentation-only gates: Knowledge Map
generation/check, mdBook build, docs path audit, memory architecture check,
diff whitespace check, and doctrine gate. Because no code or sample behavior
changes in `.507`, no focused generator/test run is required for the selector.

## Rollback

Rollback is this selector commit. Reverting it restores `.507` as pending and
removes the `.508` audit selection without changing implementation behavior.
