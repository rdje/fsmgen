# AXI IAL2 Manager RRESP Aggregation Behavior First Slice

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.79`

Date: 2026-06-14

## Scope

This slice implements generated scalar AXI read-response status aggregation
for the already-selected multi-beat read-data contract:

- read-level `status_aggregation: worst_observed`
- per-transaction `status_aggregate_output` bindings
- width-2 `RRESP` status values
- per-beat `RRESP` output-bank lanes still generated and mandatory
- runtime-assertion burst-length validation still required for multi-beat
  output-bank behavior

It does not add width-3 response ordering, alternate aggregation policies,
aggregate-only status output shapes, packed output vectors, per-ID read-data
queues, queued/blocking issue policy, direct backend lowering, or VHDL
generation.

## Generated Behavior

For each read transaction with a scalar aggregate output, the generator now
emits one width-2 output:

```text
(output axi0_r0_rresp (width 2))
```

The transaction's existing output-bank initialization rule also initializes
the scalar aggregate to AXI `OKAY`:

```text
(rule axi0_r0_read_data_output_init axi0_r0_request
  ...
  (axi0_r0_rresp 2'd0)
  ...)
```

The generator then emits a transaction-local aggregate update rule after the
per-beat lane capture rules:

```text
(rule axi0_r0_rresp_aggregate
  (& MATCHED_READ_BEAT
     (! axi0_r0_request)
     (< axi0_r0_rresp axi0_rresp))
  (axi0_r0_rresp axi0_rresp))
```

The less-than guard implements the selected width-2 `worst_observed` ordering:

```text
OKAY < EXOKAY < SLVERR < DECERR
```

The `! request_event` boundary is intentionally the same boundary used by the
multi-beat output bank. It prevents same-cycle request clearing and response
capture from writing the same generated output in the same cycle.

## Report Contract

Schedule JSON now reports that scalar aggregation behavior is generated:

```text
read_data:
  mode: bounded_multi_beat_read_data_contract
  residue: []
  read:
    status_aggregation: worst_observed
    status_aggregation_generated_behavior: true
    status_aggregate_output: per_transaction_scalar
    status_aggregate_output_width: 2
    generated_status_aggregate_outputs:
      - axi0_r0_rresp
      - axi0_r1_rresp
    generated_status_aggregate_init_rules:
      - axi0_r0_read_data_output_init
      - axi0_r1_read_data_output_init
    generated_status_aggregate_update_rules:
      - axi0_r0_rresp_aggregate
      - axi0_r1_rresp_aggregate
```

The public multi-beat sample no longer reports
`generated_rresp_aggregation` in `read_data.residue`. No-aggregation
multi-beat contracts remain valid and continue to report
`status_aggregation: none` with `read_data.residue: [rresp_aggregation]`.

## Validation

The slice is covered by focused generator and PPIF/CLI tests that prove:

- generated `.isf` declares scalar aggregate outputs and rules
- generated `.fsm` lowers request-time initialization and matched-beat update
  rules
- SystemVerilog exposes scalar aggregate output registers
- SystemVerilog preserves the `aggregate < current RRESP` comparison
- schedule JSON reports generated aggregate output/init/update artifacts
- no-aggregation multi-beat contracts remain compatible
