# AXI IAL2 Manager Post-Read-Demux Next Slice Selection

Status: selection complete; no parser/generator/HDL behavior changes in this
slice.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.42`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

This selector follows
[docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md).

## Post-`.41` State

Generated single-beat read `RID` response demux is now shipped for explicit
read response-demux contracts. The checked-in read sample reports:

```text
response_demux.residue:
  - read_data_interleaving
  - bursts

same_id_ordering.residue:
  - concrete_id_same_id_ordering
  - per_id_issue_order_queues
  - read_data_interleaving
  - bursts
```

The write response-demux sample still reports `read_response_demux` residue
because that sample only opts into the write demux family. That is not a
current-frontier blocker; the mixed/read samples cover generated read behavior.

## Selection

The next exact slice is:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.43
```

`IAL2-FEATURE-COMPLETENESS-FRONTIER.43` is a readiness audit for AXI read-data
payload, burst/`RLAST`, and per-ID ordering/reassembly ownership after
generated read response demux.

The audit is selected instead of direct implementation because the remaining
read-side residues are interdependent:

- read data payload capture needs a public structural shape before HDL
  behavior can claim user-visible read data;
- burst/`RLAST` ownership changes what `read-complete` means and whether it is
  a beat event, last-beat event, transaction-complete event, or generated
  demux output;
- different-ID read data interleaving needs per-ID collection or an explicit
  issue constraint;
- same-ID response ordering for authored concrete-ID cases needs either
  per-ID issue-order queues or a fail-closed constraint;
- full-manager behavior, queued/blocking policy, profile aliases, direct
  backend lowering, and VHDL remain too broad for the next slice.

## `.43` Audit Questions

The readiness audit must decide:

- whether the next implementation should be parser/report metadata only,
  generated behavior, or another prerequisite;
- whether the first read-data scope is single-beat payload capture, burst
  last-beat completion, a structural `read-data` report contract, a per-ID
  queue primitive, or a fail-closed constraint;
- how `read-complete` should relate to raw `RVALID/RREADY`, `RLAST`, and
  generated logical transaction completion pulses;
- whether `RDATA`, `RRESP`, and `RLAST` need explicit generated input
  ownership before any read-data behavior can ship;
- whether read-data interleaving can be supported directly, must be disabled
  by a static capability contract, or must defer behind per-ID reassembly
  queues;
- what report residue must move from `response_demux`,
  `same_id_ordering`, and `unsupported_residue` if a bounded subset ships;
- which focused generator, PPIF/CLI, schedule JSON, semantic JSON, and
  `--verify-hdl` gates are required.

## Explicit Non-Goals

The selector does not change public syntax, parser behavior, generated
`.isf`, generated `.fsm`, HDL, support accounting, check JSON, or semantic
JSON behavior.

The next audit must keep full AXI manager behavior, profile aliases,
queued/blocking policy, broad transaction classes, direct backend lowering,
and VHDL deferred unless it records a later exact owner.
