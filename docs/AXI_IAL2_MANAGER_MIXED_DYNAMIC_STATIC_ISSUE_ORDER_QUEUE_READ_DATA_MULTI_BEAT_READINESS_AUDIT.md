# AXI IAL2 Manager Mixed Dynamic/Static Issue-Order Queue Read-Data Multi-Beat Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.519`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.519` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.520`, direct bounded implementation of
multi-beat output banks over generated mixed dynamic/static read burst-last
same-ID `issue-order-queue` runtime-validation read-data.

The selected `.520` implementation should remain limited to the `.518` queue
shape:

- exactly one dynamic read transaction and one concrete static read transaction;
- exactly one generated mixed dynamic/static same-ID queue with depth 2;
- `response-demux.read` generated with `response-scope burst-last`;
- transaction completion source
  `generated_mixed_dynamic_static_issue_order_queue_demux_last_beat`;
- `read-data.read.capture-scope multi-beat`;
- `burst-length.validation runtime-assertion`;
- complete per-transaction data/status output prefixes, scalar status aggregate
  outputs, valid-mask outputs, and length outputs; and
- completion validity
  `generated_mixed_dynamic_static_read_issue_order_queue_response_demux_last_beat_completion_pulse`.

Broader mixed queue cardinality, scoreboards, same-cycle widening, packed burst
vectors, alternate full burst payload assembly, direct backend behavior,
backend-language variants, verification-output generation, external converter
dependencies, and VHDL remain future exact-owner work.

## Evidence Read

This audit read:

- `.518` mixed dynamic/static issue-order queue runtime-validation behavior;
- `.516` mixed queue report-only raw-`ARLEN` behavior;
- `.514` mixed queue scalar read-data behavior;
- `.473` two-transaction dynamic issue-order queue multi-beat behavior;
- `.500` depth-3 dynamic issue-order queue multi-beat behavior;
- `.291` one-dynamic plus one-static mixed response-demux multi-beat behavior;
- `.314` multiple mixed response-demux multi-beat behavior; and
- the current read-data normalization, coverage, multi-beat output-bank,
  beat-count assertion, report-residue, parser/CLI, generator-test, support
  accounting, public-doc, mdBook, task-tree, Memory, and Knowledge Map surfaces.

## Readiness Findings

The remaining implementation blocker is local to
`_read_data_response_demux_transaction_coverage`.

The dynamic issue-order queue branch already has a `multi-beat` supported
boundary, requires runtime-assertion burst-length metadata for multi-beat, and
uses the generated queue last-beat completion source. The mixed dynamic/static
issue-order queue branch currently lists only `single-beat` and `last-beat`
supported boundaries. It admits report-only/runtime-assertion `burst_length`
metadata only for scalar last-beat capture.

The shared downstream machinery is otherwise already present:

- `read-data.read` normalization already emits `bounded_multi_beat_read_data_contract`
  report fields, per-beat output-bank metadata, valid-mask/length outputs,
  status aggregation, `response_demux_matched_read_beat`, and runtime
  beat-count metadata for explicit multi-beat runtime contracts;
- generated rule helpers already emit output-bank initialization, per-lane
  `RDATA`/`RRESP` capture, valid-mask/length updates, scalar worst-observed
  `RRESP` aggregation, request-time expected-beat initialization, matched-beat
  counters, and beat-count/`RLAST` assertions;
- response-state lookup already includes same-ID issue-order queue response
  states, so multi-beat lane capture can reuse the mixed queue match predicate;
- the report-residue helper already recognizes read-data multi-beat-by-RID when
  same-ID ordering covers the read response-demux family; and
- the existing parser syntax and test helper vocabulary already cover
  `capture-scope multi-beat`, output prefixes, valid masks, length outputs,
  status aggregation, and runtime burst-length metadata.

## Selected `.520` Boundary

`.520` should add exactly one public sample:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_burst_last_same_id_issue_order_queue_read_data_multi_beat.ppif
```

The sample should be the multi-beat sibling of the `.518` runtime sample. It
should keep the same manager object, transactions, mixed issue-order queue,
generated burst-last response-demux, raw-`ARLEN` runtime validation, and
`max-beats 16`, while replacing scalar last-beat outputs with:

```lisp
(transaction r0
  (data-output-prefix axi0_r0_beat_rdata)
  (status-output-prefix axi0_r0_beat_rresp)
  (status-aggregate-output axi0_r0_rresp)
  (valid-mask-output axi0_r0_beat_valid)
  (length-output axi0_r0_read_beats))
(transaction r1
  (data-output-prefix axi0_r1_beat_rdata)
  (status-output-prefix axi0_r1_beat_rresp)
  (status-aggregate-output axi0_r1_rresp)
  (valid-mask-output axi0_r1_beat_valid)
  (length-output axi0_r1_read_beats))
```

The expected report surface is:

```text
read_data.mode: bounded_multi_beat_read_data_contract
read_data.read.capture_scope: multi_beat
read_data.read.completion_validity: generated_mixed_dynamic_static_read_issue_order_queue_response_demux_last_beat_completion_pulse
read_data.read.beat_match_source: response_demux_matched_read_beat
read_data.read.beat_count_match_source: response_demux_matched_read_beat
read_data.read.output_shape: per_beat_output_bank
read_data.read.valid_output: per_transaction_valid_mask
read_data.read.length_output: per_transaction_beat_count
read_data.read.status_aggregation: worst_observed
read_data.read.multi_beat_reassembly_generated_behavior: true
read_data.read.burst_length_validation: runtime_assertion
read_data.residue: []
```

For the default `max-beats 16` sample, `.520` should expect 32 generated
`RDATA` lane outputs, 32 generated `RRESP` lane outputs, two valid-mask outputs,
two length outputs, two scalar status aggregate outputs, two output-bank init
rules, 32 lane-capture rules, two status aggregate update rules, four
beat-count rules, and eight beat-count/`RLAST` assertions.

## Validation Plan For `.520`

The implementation slice should run focused syntax checks for touched modules
and tests, support-accounting tests, capability-manifest tests if public wording
changes, guarded schedule JSON for the new public sample where RAM permits,
Knowledge Map generation/check, mdBook build, docs path audit, memory
architecture check, diff hygiene, and doctrine enforcement.

If host memory is already above the 88% RAM-guard cutoff, `.520` must record the
caveat and must not rerun the sample unguarded or raise the cutoff without an
explicit owner decision.

## Non-Goals

`.520` should not widen mixed dynamic/static issue-order queue cardinality beyond
the selected one dynamic plus one concrete static read queue. It should not
change parser syntax, dynamic queue behavior, ordinary mixed response-demux
behavior, queue-head behavior, scoreboards, backend behavior, external converter
dependencies, verification-output generation, backend-language variants, or
VHDL behavior except for the explicitly selected support-accounted sample and
the local coverage/report/doc/test updates required by that sample.

## Rollback

`.519` is audit-only. Rollback removes this readiness record, its Knowledge Map
fact card, and the task-tree/README/ROADMAP_V2/mdBook/Memory pointers that
select `.520`. No parser, generator, PPIF sample, support-accounting catalog,
generated artifact, schedule/check/semantic JSON, test, HDL/runtime behavior,
backend behavior, external converter dependency, verification-output, or VHDL
behavior changes in this audit.
