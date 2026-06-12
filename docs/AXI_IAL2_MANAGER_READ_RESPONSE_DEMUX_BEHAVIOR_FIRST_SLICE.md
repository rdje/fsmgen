# AXI IAL2 Manager Read Response Demux Behavior First Slice

Status: shipped for the public `.ppif` AXI manager capacity/status object.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.41`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

This slice implements the generated behavior selected by
[docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT.md](AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT.md).
It uses the public syntax shipped by
[docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md](AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md).

## Shipped Public Syntax

The behavior is enabled only by the explicit read response-demux arm:

```text
(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope single-beat)
    (transaction-completion generated)))
```

The first read scope remains single-beat/non-burst. The raw response event
must equal top-level `read-complete`, and the selected logical read
transaction completion names become generated demux pulse outputs under this
opt-in.

Mixed write/read contracts are also behavior-bearing:

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

## Generated IAL1 Boundary

For the checked-in read sample, generated IAL1 now contains:

```text
(input axi0_read_complete)
(input axi0_rid (width 4))
(output axi0_arid (width 4))
(output axi0_r0_complete)
(output axi0_r1_complete)

(rule axi0_r0_response_demux
  (& axi0_read_complete axi0_r0_auto_id_busy_q
     (== axi0_rid axi0_r0_auto_id_q))
  (pulse axi0_r0_complete))

(rule axi0_r1_response_demux
  (& axi0_read_complete axi0_r1_auto_id_busy_q
     (== axi0_rid axi0_r1_auto_id_q))
  (pulse axi0_r1_complete))
```

`axi0_read_complete` is the raw accepted read response input. `axi0_rid` is a
generated-width response-ID input. `axi0_r0_complete` and
`axi0_r1_complete` are no longer authored event inputs in this opt-in shape;
they are generated one-cycle pulse outputs.

Read capacity release and read auto-ID release consume those generated
completion pulses through the existing capacity and lifecycle rules.

## Generated Assertions

The slice emits read response-demux assertions through the existing assertion
lowering path:

```text
axi0_read_response_demux_active_match
axi0_r0_r1_read_response_demux_unique_match
```

The same-ID avoidance assertion for active generated read IDs remains present:

```text
axi0_r0_r1_auto_id_unique_active_id
```

SystemVerilog assertion emission reaches the same messages:

```text
axi0 read response matches active auto-ID transaction
axi0 read response matches at most one auto-ID transaction
axi0 read auto ID active selected IDs are unique
```

## Report Contract

Schedule/report JSON for the read sample now includes generated read behavior:

```text
response_demux:
  mode: bounded_response_demux_contract
  generated_behavior: true
  read:
    mode: bounded_read_rid_demux_contract
    generated_behavior: true
    response_event: axi0_read_complete
    response_event_role: raw_accepted_read_response
    response_scope: single_beat
    response_id_signal: axi0_rid
    response_id_direction: generated_input
    transaction_completion_source: generated_demux
    auto_transactions:
      - r0
      - r1
    generated_rules:
      - axi0_r0_response_demux
      - axi0_r1_response_demux
    generated_completion_signals:
      - axi0_r0_complete
      - axi0_r1_complete
    generated_assertions:
      - axi0_read_response_demux_active_match
      - axi0_r0_r1_read_response_demux_unique_match
  residue:
    - read_data_interleaving
    - bursts
```

`auto_id_lifecycle.residue` is empty for the read sample because generated
same-ID avoidance and generated read response demux now cover the selected
read auto-ID lifecycle family. `same_id_ordering.families[].response_demux_covered`
is true for the read family.

Mixed write/read contracts report generated artifacts under each family arm,
with write `BID` demux behavior preserved and read `RID` demux behavior added.

## Runnable Sample

The checked-in sample is:

```text
ppif/axi_manager_capacity_status_read_response_demux.ppif
```

Useful commands:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_response_demux.ppif
./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_read_response_demux.ppif
./bin/fsmgen --outdir generated ppif/axi_manager_capacity_status_read_response_demux.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_response_demux.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_response_demux.ppif
```

Support-accounting entry:

```text
intent.ppif_axi_manager_capacity_status_read_response_demux
```

## Explicit Residue

Read-data payload capture, read-data interleaving/reassembly, bursts or
`RLAST`, per-ID response queues, authored concrete-ID same-ID ordering,
repeated instances of one logical transaction, queued/blocking policy, full
AXI manager syntax, direct backend lowering, `.pif`, `.ppi`, `.axi`, and VHDL
backend/reroute behavior remain future exact-owner work.

Follow-on: `IAL2-FEATURE-COMPLETENESS-FRONTIER.42` is the next selector for
the next SV-backed IAL2 feature-completeness slice after generated read
response demux.
