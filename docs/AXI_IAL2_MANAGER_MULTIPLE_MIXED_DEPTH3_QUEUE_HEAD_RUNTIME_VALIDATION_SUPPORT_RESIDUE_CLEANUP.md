# AXI IAL2 Manager Multiple/Mixed Depth-3 Queue-Head Runtime-Validation Support Residue Cleanup

Task owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.188`

Date: 2026-06-19

## Scope

FSMGen now reports generated runtime beat-count/`RLAST` validation over
selected multiple/mixed depth-3 read burst-last queue-head scalar last-beat
read-data as supported in the AXI manager capacity/status static support
detail.

This slice cleans stale report/static prose after
`IAL2-FEATURE-COMPLETENESS-FRONTIER.186`. It does not change parser syntax,
queue-head admission, generated read-data rules, generated assertions, public
PPIF corpus membership, support-accounting identity, generated artifacts,
strict check/semantic JSON source identity, or HDL behavior.

## Corrected Support Detail

The AXI ID/order unsupported-residue detail now lists the following
multiple/mixed depth-3 read burst-last queue-head scalar last-beat read-data
shapes as supported:

- no `burst_length` metadata;
- report-only raw-`ARLEN` burst-length metadata;
- runtime-assertion beat-count/`RLAST` validation metadata.

It also lists generated raw-`ARLEN` capture and explicit runtime-assertion
beat-count/`RLAST` validation as supported for the selected multiple/mixed
depth-3 groups.

The unsupported residue now defers only the remaining payload/output family
for this shape:

```text
read burst-last multi-beat payload over multiple or mixed depth-3 queue-head groups
```

## Preserved Behavior

Compact schedule probes confirm the shipped behavior is unchanged:

- the two `.186` runtime-validation samples still report
  `burst_length_validation: runtime_assertion`,
  `beat_count_validation_generated_behavior: true`, and `read_data` residue
  limited to `multi_beat_read_data_reassembly`, `per_beat_outputs`, and
  `rresp_aggregation`;
- the `.183` report-only sibling still reports
  `burst_length_validation: report_only` and keeps
  `generated_beat_count_validation` residue;
- the `.180` no-`burst_length` sibling still reports
  `burst_length_validation: not_generated` and keeps the same multi-beat
  payload residue.

## Deferred Work

The cleanup does not enable:

- multi-beat output-bank behavior over multiple/mixed depth-3 runtime groups;
- write-family read-data;
- same-family mixed auto-ID plus concrete queue-head demux;
- group-local simultaneous enqueue widening;
- packed burst-vector outputs;
- alternate full burst payload assembly;
- verification-output generation;
- direct backend lowering;
- VHDL/backend-language variants.
