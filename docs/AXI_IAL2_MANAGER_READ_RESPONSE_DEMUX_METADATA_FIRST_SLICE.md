# AXI IAL2 Manager Read Response Demux Metadata First Slice

Status: shipped for the public `.ppif` AXI manager capacity/status object.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.39`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

This slice implements the parser/report metadata boundary selected by
[docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md](AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md).

## Shipped Public Syntax

The existing optional `response-demux` clause under `manager-capacity-status`
now accepts a read family arm:

```text
(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope single-beat)
    (transaction-completion generated)))
```

The clause may contain one write arm, one read arm, or both. The shipped write
arm remains behavior-bearing:

```text
(response-demux
  (write
    (response-event axi0_write_complete)
    (transaction-completion generated))
  (read
    (response-event axi0_read_complete)
    (response-scope single-beat)
    (transaction-completion generated)))
```

For the first read contract, `response-scope single-beat` is mandatory.
`response-event` must equal top-level `read-complete` and denotes the raw
accepted single-beat read response transfer under the explicit opt-in.
`transaction-completion generated` records that the selected read transaction
completion names are owned by future generated read response demux. Without a
read `response-demux` arm, read transaction completion names remain authored
environment inputs.

## Static Validation

The parser and generator now fail closed on:

- duplicate `response-demux` clauses;
- unsupported response-demux families other than `read` or `write`;
- duplicate read or write family arms;
- missing, duplicate, malformed, or unsupported read response-demux
  subclauses;
- read response scopes other than `single-beat`;
- read `response-event` values that differ from top-level `read-complete`;
- read `transaction-completion` values other than `generated`;
- read response demux without `id_families`, `transactions`, or
  `auto_id_lifecycle` metadata;
- read response demux without a declared positive-width read ID family;
- read response demux without explicit read `auto_id_lifecycle` metadata;
- read response demux without at least one read auto-ID transaction;
- generated/read transaction completion names that collide with the raw read
  response event.

The existing write response-demux diagnostics and generated behavior remain
intact.

## Report Contract

Schedule/report JSON keeps the existing schema:

```text
fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1
```

For a read-only metadata slice, `response_demux` now reports:

```text
response_demux:
  mode: bounded_response_demux_contract
  generated_behavior: false
  read:
    mode: bounded_read_rid_demux_contract
    generated_behavior: false
    response_event: axi0_read_complete
    response_event_role: raw_accepted_read_response
    response_scope: single_beat
    response_id_signal: axi0_rid
    response_id_direction: generated_input
    transaction_completion_source: generated_demux
    auto_transactions:
      - r0
      - r1
  residue:
    - generated_read_rid_demux
    - read_data_interleaving
    - bursts
```

For mixed write/read contracts, the existing write arm keeps generated write
`BID` demux behavior while the read arm reports `generated_behavior: false`.
Per-family generated behavior prevents a mixed contract from implying generated
read `RID` demux before that behavior is task-owned.

## Generated Behavior

This slice intentionally does not generate read `RID` demux behavior.

For the checked-in read sample:

- read transaction completion events remain authored IAL1 inputs;
- `axi0_rid` is not added as a generated IAL1 input by response demux;
- read transaction completion names are not generated outputs yet;
- no read response-demux rules, read demux assertions, `.fsm` pulse rules, or
  HDL logic are emitted by this slice.

The metadata exists so the later behavior owner can implement generated read
`RID` matching without changing the public source syntax again.

## Runnable Sample

The checked-in sample is:

```text
ppif/axi_manager_capacity_status_read_response_demux.ppif
```

Useful commands:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_response_demux.ppif
./bin/fsmgen --outdir generated ppif/axi_manager_capacity_status_read_response_demux.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_response_demux.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_response_demux.ppif
```

Support-accounting entry:

```text
intent.ppif_axi_manager_capacity_status_read_response_demux
```

## Explicit Residue

Generated read `RID` demux rules, generated read transaction completion
pulses, unmatched/inactive read response assertions, ambiguous read match
assertions, read-data interleaving/reassembly, burst or last-beat tracking,
per-ID response queues, authored concrete-ID same-ID ordering, repeated
instances of one logical transaction, queued/blocking policy, full AXI manager
syntax, `.pif`, `.ppi`, `.axi`, and VHDL backend/reroute behavior remain
future exact-owner work.

Next selected owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.40`, a readiness
audit for generated read `RID` response-demux behavior after this parser/report
metadata is shipped.
