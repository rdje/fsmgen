# AXI IAL2 Manager RRESP Aggregation Behavior Readiness Audit

Status: shipped readiness audit; the selected generated scalar aggregation
behavior shipped later in `IAL2-FEATURE-COMPLETENESS-FRONTIER.79`.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.78`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_METADATA_FIRST_SLICE.md](AXI_IAL2_MANAGER_RRESP_AGGREGATION_METADATA_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_CONTRACT_SELECTION.md](AXI_IAL2_MANAGER_RRESP_AGGREGATION_CONTRACT_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_OUTPUT_BANK_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_OUTPUT_BANK_BEHAVIOR_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md](AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md)

## Purpose

This audit decides whether the scalar `RRESP` aggregation metadata shipped by
`.77` can move directly into generated behavior, or whether a smaller
IAL1/IAL0/SystemVerilog prerequisite is needed first.

The result is direct implementation readiness. Existing generated outputs,
guarded rule assignments, less-than expressions, request-event initialization,
matched-read-beat guards, disjoint guard proof, `.fsm` lowering, and
SystemVerilog lowering are sufficient for the first width-2
`worst_observed` aggregate behavior.

No source parser, generator, schedule report, `.isf`, `.fsm`, HDL, sample, or
test behavior changes in this audit slice.

## Behavior Selected For Follow-Up Slice

The follow-up behavior slice was selected to generate one scalar status
aggregate output per transaction that provided `(status-aggregate-output
NAME)`:

```text
(output axi0_r0_rresp (width 2))
```

For the width-2 AXI response contract selected by `.76`, the severity order is
numeric:

```text
OKAY=0 < EXOKAY=1 < SLVERR=2 < DECERR=3
```

The implementation can therefore compute `worst_observed` as a numeric max:

- initialize the aggregate output to `2'd0` (`OKAY`) on the transaction
  request event;
- on each accepted matched read-data beat for that transaction, update the
  aggregate output only when the current scalar aggregate is less than the
  current `RRESP` signal;
- leave the aggregate unchanged when the beat status is not worse than the
  current aggregate.

The intended update guard is:

```text
(& MATCHED_READ_BEAT (! REQUEST_EVENT) (< STATUS_AGGREGATE_OUTPUT RRESP_SIGNAL))
```

The assignment is:

```text
(STATUS_AGGREGATE_OUTPUT RRESP_SIGNAL)
```

## Same-Cycle Boundary

The generated aggregate update keeps the same boundary used by the shipped
multi-beat output-bank capture rules:

```text
(& MATCHED_READ_BEAT (! REQUEST_EVENT) ...)
```

That means a same-cycle transaction request and read beat initializes the
aggregate to `OKAY` and suppresses the beat update for that cycle. This is
consistent with `.74` output-bank behavior, where request-time output clearing
and matched-beat lane capture do not race each other.

## Substrate Audit

The existing substrate covers the selected behavior:

- `_width_output_line` already emits width-bearing IAL1 outputs.
- `_read_data_multi_beat_output_init_rule_lines` already owns request-time
  output initialization for generated multi-beat read-data behavior.
- `_read_data_capture_rule_lines` already owns matched-read-beat guarded
  per-transaction/per-lane capture and uses the same `!request_event`
  boundary.
- `_lt_expr`, `_and_expr`, `_not_expr`, and sized decimal literals already
  support the needed update guard and `OKAY` initialization.
- IAL1 rule lowering can keep output registers as assignment targets.
- The scheduler's same-target conflict proof recognizes `REQUEST_EVENT` and
  `(! REQUEST_EVENT)` as disjoint literal guard terms, even when the update
  guard also contains the non-literal `<` comparison.
- A transient in-memory probe using request-time `2'd0` initialization plus
  `(& matched (! req) (< agg rresp))` update lowered through the scheduler and
  reached SystemVerilog with the `agg < rresp` comparison intact.

The `.79` implementation slice added focused regression coverage for the
actual generated IAL2 path, because the probe validated the substrate shape
but not the production artifact lists, report fields, public sample, or
residue movement.

## Report Boundary

The `.79` generated behavior slice made these report movements together with
the behavior:

- set `status_aggregation_generated_behavior: true`;
- keep `status_aggregation: worst_observed`;
- keep `status_aggregate_output: per_transaction_scalar`;
- include scalar aggregate outputs in the generated output/artifact lists;
- include aggregate initialization and update rules in the generated rule
  artifact lists;
- remove `generated_rresp_aggregation` from `read_data.residue` when scalar
  behavior is generated.

Multi-beat contracts that omit `status-aggregation` should remain unchanged:
they should continue to report `status_aggregation: none` and
`read_data.residue: [rresp_aggregation]`.

## Deferrals

This audit does not select or implement:

- width-3 AXI response aggregation;
- alternate aggregation policies;
- aggregate-only output shapes that remove per-beat status lanes;
- packed burst outputs;
- per-ID read-data queues;
- authored concrete-ID same-ID ordering;
- queued/blocking policy;
- profile aliases;
- full-manager behavior;
- direct-backend lowering;
- VHDL behavior.

## Validation Gates

The audit validation was:

- code read of `.77` parser/report metadata and `.76` selected contract;
- code read of `.74` output-bank behavior and `.69` beat-count/RLAST
  validation substrate;
- code read of IAL1 expression helpers, rule/output generation helpers,
  scheduler disjoint guard proof, and IAL0/SystemVerilog lowering boundaries;
- transient in-memory scheduler/HDL probe for the intended init/update rule
  shape;
- Knowledge Map generation/check, mdBook build, docs path audit, memory
  architecture check, diff hygiene, and stale-frontier scan.

## Rollback

Reverting this audit removes only the readiness decision and the `.79`
implementation owner. As of the historical `.78` audit, the `.77`
parser/report metadata remained the latest shipped behavior, with
`status_aggregation_generated_behavior: false` and
`read_data.residue: [generated_rresp_aggregation]`.
