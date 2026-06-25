# AXI IAL2 Manager Post Mixed Dynamic/Static Write Same-ID Issue-Order Queue Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.504`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.504` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.505`, readiness audit for generated mixed
dynamic/static read single-beat `RID` same-ID `issue-order-queue` behavior.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, generated artifact, report JSON, test, HDL/runtime behavior, backend
behavior, backend-language variant, external converter dependency,
verification-code output, or VHDL behavior.

## Selection Rationale

`.503` shipped the first mixed dynamic/static issue-order queue:
one dynamic write transaction plus one concrete static write transaction,
with dynamic enqueues storing `axi0_awid`, static enqueues storing the sized
literal, and response matching ordered by compact runtime-ID queue position.

The smallest adjacent owner is the same one-dynamic plus one-concrete-static
queue semantics on the simpler read response surface:

```text
response-demux.read.response-scope: single-beat
response ID signal: axi0_rid
dynamic request ID source: axi0_arid
```

This is smaller than mixed read burst-last `RID && RLAST` queues because it
does not need last-beat completion gating, raw non-final beat assertion
splits, read-data, raw `ARLEN`, runtime beat-count validation, or multi-beat
output banks. It is also smaller than multi-static or two-dynamic-plus-static
mixed queues, scoreboards, arbitrary cardinality, backend behavior,
backend-language variants, VHDL, or external converter audits.

FSMGen-owned generation/lowering remains the default. External converters
such as `sv2v` remain optional future audit candidates only; `.505` should not
introduce an external dependency.

## Source Anchors

The audit should read these shipped records before implementation is selected:

- `.503` mixed dynamic/static write `BID` issue-order queue behavior;
- `.502` mixed write issue-order queue readiness audit;
- `.459` all-dynamic read single-beat `RID` issue-order queue behavior;
- `.463` all-dynamic read burst-last `RID && RLAST` issue-order queue
  behavior;
- `.276` mixed dynamic/static read single-beat response-demux behavior;
- `.280` mixed dynamic/static read burst-last response-demux behavior; and
- focused parser/generator/dynamic-ID/support-accounting surfaces.

The existing mixed read single-beat response-demux sample:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux.ppif
```

already has exactly one dynamic read transaction and one concrete static read
transaction, but it intentionally excludes static-ID overlap by reserving the
static concrete ID away from dynamic capture. `.505` should audit whether the
queue-owned variant can instead allow static/dynamic runtime-ID overlap and
order it by queue position, as `.503` now does for write `BID`.

## Candidate Public Shape For `.505`

The likely candidate is a new support-accounted PPIF sample with this shape:

```text
read transactions: r0 dynamic, r1 concrete static value 3
id_families.read width: 4
request ID signal: axi0_arid
response ID signal: axi0_rid
same-id-ordering.read: dynamic-id-reuse issue-order-queue
response-demux.read: generated single-beat RID completion
submit-policy: try
read-max-pending: 2
queue depth: 2
```

Expected generated report terminology should mirror `.503` while staying
read-single-beat specific:

```text
bounded_mixed_dynamic_static_read_rid_issue_order_queue_demux_contract
generated_mixed_dynamic_static_issue_order_queue_demux
earliest_matching_captured_or_static_runtime_id
captured_or_static_request_id
mixed_dynamic_static_issue_order_earliest_matching_slot
allowed_by_issue_order_queue
generated_mixed_dynamic_static_read_rid_issue_order_queue
```

## Non-Goals

`.504` explicitly leaves these for future exact owners:

- implementation until `.505` or a later selected owner;
- mixed read burst-last `RID && RLAST` issue-order queues;
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
changes in `.504`, no focused generator/test run is required for the selector.

## Rollback

Rollback is this selector commit. Reverting it restores `.504` as pending and
removes the `.505` audit selection without changing implementation behavior.
