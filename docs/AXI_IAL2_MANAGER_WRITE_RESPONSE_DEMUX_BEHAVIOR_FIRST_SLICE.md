# AXI IAL2 Manager Write Response-Demux Behavior First Slice

This note records the behavior-bearing follow-up to the write response-demux
metadata slice. The owner is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.30`.

## Shipped Boundary

For an explicit public `.ppif` contract:

```text
(response-demux
  (write
    (response-event axi0_write_complete)
    (transaction-completion generated)))
```

FSMGen now generates bounded write `BID` demux behavior through the mandatory
`IAL2 -> IAL1 -> IAL0 -> SystemVerilog` chain.

The generated IAL1 actor:

- declares the raw write response accepted event, such as
  `axi0_write_complete`, as an input;
- declares the write response ID signal, such as `axi0_bid`, as a generated
  input with the declared write ID width;
- treats write transaction completion names, such as `axi0_w0_complete`, as
  generated pulse outputs instead of authored event inputs;
- emits one rule per auto-ID write transaction:

```text
(rule axi0_w0_response_demux
  (& axi0_write_complete axi0_w0_auto_id_busy_q
     (== axi0_bid axi0_w0_auto_id_q))
  (pulse axi0_w0_complete))
```

The generated IAL0 `.fsm` lowers each completion through `<1` pulse-domain
assignments. The existing capacity matrix and auto-ID release rules continue
to consume the transaction completion names, so capacity release and selected
ID release are driven by the generated demux pulses.

## Assertions And Report Shape

The generated IAL1 assertion transaction emits runtime assertions for:

- a write response matching at least one active auto-ID write transaction;
- a write response matching at most one active auto-ID write transaction.

The schedule/report surface keeps schema
`fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1` and now reports:

```text
response_demux:
  mode: bounded_write_bid_demux_contract
  generated_behavior: true
  write:
    response_event: axi0_write_complete
    response_id_signal: axi0_bid
    response_id_direction: generated_input
    transaction_completion_source: generated_demux
    auto_transactions: [w0, w1]
    generated_rules: [axi0_w0_response_demux, axi0_w1_response_demux]
    generated_completion_signals: [axi0_w0_complete, axi0_w1_complete]
    generated_assertions:
      - axi0_write_response_demux_active_match
      - axi0_w0_w1_write_response_demux_unique_match
  residue:
    - read_response_demux
    - same_id_ordering
    - read_data_interleaving
    - bursts
```

The `id_response_rule_engine.residue` also removes `response_demux` when the
explicit write response-demux behavior is present; same-ID ordering remains
residue.

Follow-up selector `.31` found one remaining report-contract alignment issue:
`auto_id_lifecycle.residue` still lists `response_demux` even though generated
demux completion pulses now drive auto-ID release. `.32` shipped that narrow
report cleanup before larger ordering or read-response behavior.

## Runnable Sample

The checked-in sample is:

```text
ppif/axi_manager_capacity_status_response_demux.ppif
```

Useful commands:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_response_demux.ppif
./bin/fsmgen --outdir generated ppif/axi_manager_capacity_status_response_demux.ppif
./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_response_demux.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_response_demux.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_response_demux.ppif
```

## Residue

This slice does not implement read `RID` response demux, same-ID response
ordering queues, read-data interleaving/reassembly, bursts, queued/blocking
policy, profile aliases, full AXI manager behavior, or VHDL backend/reroute
behavior.
