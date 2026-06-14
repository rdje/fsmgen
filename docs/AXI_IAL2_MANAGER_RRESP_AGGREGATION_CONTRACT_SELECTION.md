# AXI IAL2 Manager RRESP Aggregation Contract Selection

Status: selected public contract; no parser, generator, HDL, sample,
support-accounting, check JSON, semantic JSON, or validation behavior changed
by this note.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.76`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_POST_MULTI_BEAT_OUTPUT_NEXT_SLICE_SELECTION.md](AXI_IAL2_MANAGER_POST_MULTI_BEAT_OUTPUT_NEXT_SLICE_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_OUTPUT_BANK_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_OUTPUT_BANK_BEHAVIOR_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_CONTRACT_SELECTION.md](AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_CONTRACT_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_METADATA_FIRST_SLICE.md](AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_METADATA_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md](AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md)

Source evidence:

- `docs/vendor/arm/amba/axi/IHI0022_L_2025-08_AMBA_AXI_Protocol_Specification.pdf`,
  section A3.3.2, tables A3.29 through A3.32.

## Purpose

This selector chooses the public source and report contract for scalar
multi-beat `RRESP` aggregation after generated output-bank behavior shipped.

The current public multi-beat sample already exposes one `RRESP` lane per
accepted beat and reports:

```text
read_data:
  mode: bounded_multi_beat_read_data_contract
  generated_behavior: true
  residue:
    - rresp_aggregation
  read:
    status_policy: per_beat
    status_aggregation: none
    output_shape: per_beat_output_bank
    multi_beat_reassembly_generated_behavior: true
```

The selected contract adds a scalar aggregate status output without removing
the per-beat status lanes. The detailed lanes remain the lossless inspection
surface; the scalar output is a convenience and policy surface for consumers
that need one transaction-level response code.

## AXI Response Evidence

The local AXI specification says the read data channel carries read data and
read response information, with one `RRESP` value per read data transfer. It
also says the response value is not required to be the same for every transfer
in a transaction.

For the two-bit `RRESP` width already enforced by this project slice, the
base encodings are:

```text
0b00 OKAY
0b01 EXOKAY
0b10 SLVERR
0b11 DECERR
```

The spec also documents that `DECERR` can be consistent across a transaction
or appear on only some transfers, depending on the `Consistent_DECERR`
property. A scalar contract that samples only the last beat could miss an
earlier response. A first-non-OK contract could also hide a later stronger
status. The first scalar aggregate therefore has to inspect every accepted
matched beat.

This selector intentionally keeps the first contract to width-2 `RRESP`.
Three-bit `RRESP` encodings and optional AXI features that require them remain
deferred until a separate public width-extension owner.

## Selected Public Syntax

Extend the existing multi-beat `read-data` read arm with one read-level
aggregation policy clause and one transaction-local scalar output binding:

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
      (length-output axi0_r0_read_beats))
    (transaction r1
      (data-output-prefix axi0_r1_beat_rdata)
      (status-output-prefix axi0_r1_beat_rresp)
      (status-aggregate-output axi0_r1_rresp)
      (valid-mask-output axi0_r1_beat_valid)
      (length-output axi0_r1_read_beats))))
```

`status-aggregation` is accepted only for `capture-scope multi-beat` in this
first contract. The read-level clause selects the policy once for all
transactions in that read arm.

`status-aggregate-output NAME` is required for every transaction when
`status-aggregation` is present. The output width is inherited from
`status-signal` and is fixed at 2 for this selected contract.

`status-output-prefix` stays mandatory. The scalar aggregate does not replace
per-beat `RRESP` lanes because the aggregate is intentionally lossy.

## Selected Policy

The first policy spelling is:

```text
worst-observed
```

The normalized report spelling is:

```text
worst_observed
```

For two-bit base AXI responses, `worst-observed` uses this ordering:

```text
OKAY < EXOKAY < SLVERR < DECERR
```

Generated behavior later should initialize the scalar aggregate output to
`OKAY` on the transaction request. On each accepted matched read-data beat for
that transaction, it should update the scalar output to the maximum of the
current aggregate and the current `RRESP` under the selected ordering.

This policy was selected over:

- `last-beat`, because `RRESP` is per beat and can differ across beats;
- `first-non-OK`, because an earlier `EXOKAY` or `SLVERR` could hide a later
  `DECERR`;
- sticky non-OK without severity ordering, for the same reason.

## Interaction With Existing Outputs

`valid-mask-output` and `length-output` remain unchanged. They continue to
describe which output-bank lanes were filled and how many beats were observed
for the completed burst.

The scalar aggregate is valid at the same transaction boundary as the
per-beat output bank: the generated transaction completion pulse from
burst-last read response demux. Existing beat-count/`RLAST` runtime
assertions remain the authority for incomplete, early-last, missing-last, and
extra-beat failures. The aggregate output reports the worst observed
transaction `RRESP`; it does not make an invalid burst valid.

The later generated behavior owner should use the same matched-read-beat and
`!request_event` boundary as the existing output-bank capture rules so
same-cycle request/output clearing does not race a response beat.

## Static Contract

The parser/report metadata owner must enforce:

- `status-aggregation` is accepted only under `(read-data (read ...))` with
  `capture-scope multi-beat`;
- the only first policy is `(policy worst-observed)`;
- `status-signal` width must remain 2;
- `status-policy per-beat` remains required;
- `status-output-prefix`, `valid-mask-output`, and `length-output` remain
  required for every transaction;
- every transaction must provide exactly one `status-aggregate-output` when
  aggregation is present;
- no transaction may provide `status-aggregate-output` without the read-level
  `status-aggregation` clause;
- scalar aggregate output names must be unique and collision-free against all
  generated inputs, generated outputs, storage, rules, assertions, and existing
  authored names;
- width-3 `RRESP`, alternate policies, per-transaction mixed policies,
  aggregate-only output shape, packed burst outputs, report-only beat-count
  validation, direct backend behavior, and VHDL behavior fail closed.

Existing single-beat, last-beat, and no-aggregation multi-beat read-data
contracts remain valid and unchanged.

## Report Contract

The parser/report metadata slice should keep schema
`fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1` and report the
selected aggregate without claiming generated scalar behavior yet:

```text
read_data:
  mode: bounded_multi_beat_read_data_contract
  generated_behavior: true
  read:
    capture_scope: multi_beat
    status_policy: per_beat
    status_aggregation: worst_observed
    status_aggregation_generated_behavior: false
    status_aggregate_output: per_transaction_scalar
    status_aggregate_output_width: 2
    output_shape: per_beat_output_bank
    valid_output: per_transaction_valid_mask
    length_output: per_transaction_beat_count
    multi_beat_reassembly_generated_behavior: true
    transactions:
      - transaction: r0
        status_output_prefix: axi0_r0_beat_rresp
        status_aggregate_output: axi0_r0_rresp
        status_aggregate_output_width: 2
```

The metadata slice should keep `rresp_aggregation` in residue or replace it
with a more precise generated-behavior residue such as
`generated_rresp_aggregation`. The behavior owner that emits scalar outputs,
initialization rules, update rules, and report artifact lists may then remove
that residue.

## Selected Next Owner

The next exact owner is:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.77
```

`.77` owns parser/report metadata and static validation for the selected
public scalar `RRESP` aggregation contract. It must not generate scalar
aggregation behavior unless it proves and records that it is itself scoped as
a behavior owner.

## Future Behavior Boundary

After `.77` ships parser/report metadata, later exact owners may implement:

- generated scalar aggregate outputs;
- request-time aggregate initialization to `OKAY`;
- matched-beat aggregate update rules using the selected ordering;
- generated aggregate artifact report lists;
- residue removal for generated scalar `RRESP` aggregation;
- focused HDL reachability tests.

Per-ID read-data queues, authored concrete-ID same-ID ordering queues,
queued/blocking policy, profile aliases, full-manager syntax, direct backend
lowering, width-3 AXI responses, and VHDL remain deferred.

## Validation Gates For `.76`

Because `.76` is selection only, validation should run at least:

- `./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_multi_beat.ppif`
- `bash knowledge-map/scripts/gen_knowledge_map.sh`
- `mdbook build docs/book`
- `prove -Iperl t/1414-docs-relative-paths-audit.t`
- `bash knowledge-map/scripts/check_knowledge_map.sh`
- `scripts/check_memory_architecture.sh`
- `git --no-pager diff --check`
- stale active `.76` frontier search

## Rollback

This selector changes only documentation, task-tree, mdBook, roadmap, memory,
and Knowledge Map state. Reverting it returns the active frontier to `.76`
with `.75` having selected scalar `RRESP` aggregation as the next owner but no
concrete public syntax or policy recorded.
