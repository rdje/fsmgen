# AXI IAL2 Manager RRESP Aggregation Metadata First Slice

Status: shipped parser/report metadata and static validation; generated
scalar aggregation behavior remains deferred.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.77`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_CONTRACT_SELECTION.md](AXI_IAL2_MANAGER_RRESP_AGGREGATION_CONTRACT_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_OUTPUT_BANK_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_OUTPUT_BANK_BEHAVIOR_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_CONTRACT_SELECTION.md](AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_CONTRACT_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md](AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md)

## Purpose

This slice implements the public source and schedule-report metadata selected
by `.76` for scalar AXI read response aggregation, while deliberately keeping
the generated `.isf`, `.fsm`, and SystemVerilog behavior unchanged.

The public multi-beat sample now includes a read-level aggregation policy and
one transaction-local scalar aggregate output binding per read transaction:

```text
(read-data
  (read
    (capture-scope multi-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (status-policy per-beat)
    (status-aggregation
      (policy worst-observed))
    (interleaving multi-beat-by-rid)
    (burst-length
      (source arlen)
      (signal axi0_arlen (width 8))
      (encoding axlen-plus-one)
      (capture request)
      (max-beats 16)
      (validation runtime-assertion))
    (transaction r0
      (data-output-prefix axi0_r0_beat_rdata)
      (status-output-prefix axi0_r0_beat_rresp)
      (status-aggregate-output axi0_r0_rresp)
      (valid-mask-output axi0_r0_beat_valid)
      (length-output axi0_r0_read_beats))))
```

`status-output-prefix` remains mandatory. The scalar output is an additional
transaction-level report/contract binding, not a replacement for lossless
per-beat `RRESP` lane outputs.

## Static Validation

The `.ppif` parser and in-process normalizer now accept only this first public
aggregation shape:

- `status-aggregation` is allowed only with `capture-scope multi-beat`;
- the only supported policy is `(policy worst-observed)`;
- `status-policy per-beat`, two-bit `status-signal`, generated burst-last
  response-demux, and runtime-assertion `burst-length` metadata remain
  required;
- every transaction must provide exactly one `status-aggregate-output` when
  read-level aggregation is present;
- `status-aggregate-output` without read-level `status-aggregation` is
  rejected;
- scalar aggregate output names participate in the normal generated-name
  collision checks;
- unsupported policies, malformed clauses, duplicate clauses, aggregate-only
  shapes, single-beat/last-beat misuse, non-2 status width, and width-3
  response extensions fail closed.

## Report Contract

Schedule JSON keeps schema
`fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1` and reports the
selected aggregate as metadata:

```text
read_data:
  mode: bounded_multi_beat_read_data_contract
  generated_behavior: true
  residue:
    - generated_rresp_aggregation
  read:
    status_policy: per_beat
    status_aggregation: worst_observed
    status_aggregation_generated_behavior: false
    status_aggregate_output: per_transaction_scalar
    status_aggregate_output_width: 2
    output_shape: per_beat_output_bank
    multi_beat_reassembly_generated_behavior: true
    transactions:
      - transaction: r0
        status_output_prefix: axi0_r0_beat_rresp
        status_aggregate_output: axi0_r0_rresp
        status_aggregate_output_width: 2
```

The residue changed from broad `rresp_aggregation` to
`generated_rresp_aggregation`. That records that the public source/report
contract is now understood, while request-time initialization and matched-beat
aggregate update behavior still need a later exact owner.

Multi-beat read-data contracts that omit `status-aggregation` remain valid.
They continue to report `status_aggregation: none` and keep the broader
`rresp_aggregation` residue.

## Generated Behavior Boundary

This slice does not emit scalar aggregate outputs, initialization rules, update
rules, or aggregate artifact report lists. The generated output-bank behavior
from `.74` remains the only multi-beat read-data payload behavior:

```text
(output axi0_r0_beat_rresp_0 (width 2))
(output axi0_r0_beat_valid (width 16))
(output axi0_r0_read_beats (width 5))
```

There is intentionally no generated output such as:

```text
(output axi0_r0_rresp (width 2))
```

Existing generated `.fsm` and SystemVerilog output-bank behavior therefore
remain reviewable and behavior-identical while the scalar aggregate contract is
made visible to schedule/check/semantic consumers.

## Next Owner

The next exact owner is:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.78
```

`.78` should audit generated scalar `RRESP` aggregation readiness before
behavior changes. It should decide whether the existing IAL1/IAL0/SystemVerilog
substrate can emit request-time `OKAY` initialization, matched-beat
worst-observed updates, artifact report lists, and residue removal directly, or
whether a smaller IAL1/IAL0/SystemVerilog prerequisite is required first.

Width-3 AXI responses, alternate aggregation policies, aggregate-only output
shapes, packed burst outputs, per-ID queues, direct backend lowering, and VHDL
remain deferred.

## Validation Gates

The focused implementation gates are:

- `perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm`
- `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- `perl -Iperl -c t/1436-ial2-ppif-parser-cli.t`
- `perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t`
- `prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t`
- `prove -Iperl t/1436-ial2-ppif-parser-cli.t`
- direct schedule/check/semantic/HDL probes for
  `ppif/axi_manager_capacity_status_read_data_multi_beat.ppif`
- support-accounting corpus gates
- Knowledge Map generation/check, mdBook build, docs path audit, memory
  architecture check, diff hygiene, and stale-frontier scan

## Rollback

Reverting this slice removes the public parser/report metadata acceptance for
`status-aggregation`, returns the multi-beat sample to per-beat status lanes
only, and restores the broad `rresp_aggregation` residue. Generated
multi-beat output-bank behavior remains owned by `.74` and is not otherwise
affected.
