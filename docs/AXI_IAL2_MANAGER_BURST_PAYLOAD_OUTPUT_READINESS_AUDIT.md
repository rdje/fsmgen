# AXI IAL2 Manager Burst Payload/Output Readiness Audit

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.84`

Date: 2026-06-14

Status: completed readiness audit; no parser, generator, HDL, sample,
support-accounting, check JSON, semantic JSON, or validation behavior changed
by this note.

## Audit Question

After `.82` aligned read-data interleaving residue, the live public multi-beat
sample reports:

```text
read_data.residue: []
auto_id_lifecycle.residue: []
response_demux.residue:
  - bursts
same_id_ordering.residue:
  - concrete_id_same_id_ordering
  - per_id_issue_order_queues
  - bursts
```

This audit decides whether the next owner should move the remaining broad
`bursts` residue for the covered generated auto-ID multi-beat output-bank
subset, select a packed/full burst public contract first, add new generated
behavior, or wait on a lower-layer prerequisite.

## Evidence Read

The live public sample is:

```text
ppif/axi_manager_capacity_status_read_data_multi_beat.ppif
```

It already has the bounded per-beat burst output contract selected in `.71`,
parser/report metadata and static validation from `.72`, generated output-bank
behavior from `.74`, and generated scalar `RRESP` aggregation from `.79`.

The live schedule report shows these generated fields:

```text
read.capture_scope: multi_beat
read.completion_source: response_demux
read.completion_validity: generated_read_response_demux_last_beat_completion_pulse
read.beat_match_source: response_demux_matched_read_beat
read.beat_count_match_source: response_demux_matched_read_beat
read.output_shape: per_beat_output_bank
read.valid_output: per_transaction_valid_mask
read.length_output: per_transaction_beat_count
read.interleaving_policy: multi_beat_by_rid
read.burst_length_source: arlen_signal
read.burst_length_validation: runtime_assertion
read.multi_beat_reassembly_generated_behavior: true
read.status_aggregation: worst_observed
read.status_aggregation_generated_behavior: true
read.status_aggregate_output: per_transaction_scalar
```

Generated artifact counts for the sample are complete for the bounded
output-bank shape:

```text
generated_multi_beat_data_outputs: 32
generated_multi_beat_status_outputs: 32
generated_multi_beat_valid_outputs: 2
generated_multi_beat_length_outputs: 2
generated_multi_beat_output_init_rules: 2
generated_multi_beat_capture_rules: 32
generated_status_aggregate_outputs: 2
generated_status_aggregate_update_rules: 2
generated_beat_count_assertions: 8
```

Each covered read transaction has 16 data lanes, 16 status lanes, a valid
mask, a length output, scalar status output, and a beat-count register.

## Finding

The current generated behavior is enough for a bounded burst payload/output
claim for the selected public shape:

- burst-last read response demux supplies the raw accepted read beat, matched
  `RID`, and last-beat completion pulse;
- raw ARLEN capture and runtime beat-count/`RLAST` validation prove the
  expected beat count and fail closed for extra, early-last, and missing-last
  beats;
- generated multi-beat output-bank behavior captures every matched beat into
  per-transaction data/status lanes, valid masks, and length outputs;
- generated scalar `RRESP` aggregation covers the selected
  `worst_observed` scalar status output for the public sample;
- generated auto-ID same-ID avoidance plus matched-`RID` capture constrains
  the covered subset to generated auto-ID multi-beat-by-RID behavior.

That is not a packed burst vector and not full AXI burst payload assembly.
The selected public contract deliberately chose a per-beat output bank as the
first bounded burst output shape. Packed burst views, alternate output shapes,
authored/general different-ID interleaving outside the covered auto-ID subset,
per-ID queues, and full-manager behavior remain future exact-owner work.

## Selection

The next exact owner is:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.85
```

Goal:

```text
Align AXI burst residue after generated multi-beat output-bank behavior.
```

The selected `.85` slice should be report/static alignment only. It should
remove broad `bursts` residue from `response_demux` and `same_id_ordering`
only when the report can prove the covered generated auto-ID multi-beat
output-bank subset:

- generated same-ID avoidance covers the read family;
- generated burst-last read response demux covers the read family;
- read-data capture is `capture_scope: multi_beat`;
- `interleaving_policy` is `multi_beat_by_rid`;
- beat matching and beat-count matching use
  `response_demux_matched_read_beat`;
- ARLEN capture and runtime beat-count/`RLAST` validation are generated;
- output shape is `per_beat_output_bank`;
- per-transaction data/status lanes, valid masks, and length outputs are
  generated;
- multi-beat output-bank behavior is generated.

Scalar `RRESP` aggregation should not be required for burst residue movement,
because the output-bank shape already carries per-beat status lanes. Contracts
without scalar aggregation may still keep `read_data.residue:
[rresp_aggregation]`.

## Deferrals

This audit does not select implementation of:

- packed burst-vector outputs;
- alternate packed/full burst payload assembly;
- aggregate-only status output shapes;
- authored concrete-ID same-ID ordering;
- per-ID issue-order queues or response scoreboards;
- dynamic user-ID arbitration for multiple same-family requests in one cycle;
- queued/blocking policy;
- profile aliases;
- full-manager behavior;
- verification-code generation;
- direct backend lowering;
- VHDL behavior.

## Validation For `.85`

The `.85` implementation should prove report-only behavior movement:

- focused generator and PPIF/CLI tests for residue/report shape;
- direct schedule JSON probe for the public multi-beat sample;
- no-scalar-aggregation multi-beat compatibility probe;
- generated `.isf`, `.fsm`, and SystemVerilog no-drift checks where
  practical;
- Knowledge Map generation/check;
- mdBook build;
- docs relative-path audit;
- memory architecture check;
- diff hygiene and stale-frontier scan.
