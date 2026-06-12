# AXI IAL2 Manager ID-Family First Slice

Status: shipped for the public `.ppif` AXI manager capacity/status object.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

This slice implements the static ID-family metadata selected by
[docs/AXI_IAL2_MANAGER_ID_FAMILY_SUBSET_SELECTION.md](AXI_IAL2_MANAGER_ID_FAMILY_SUBSET_SELECTION.md)
and scoped by
[docs/AXI_IAL2_MANAGER_ID_FAMILY_READINESS_AUDIT.md](AXI_IAL2_MANAGER_ID_FAMILY_READINESS_AUDIT.md).

## Shipped Public Syntax

The existing `manager-capacity-status` object may now include an optional
`(id-families ...)` clause:

```text
(manager-capacity-status axi0
  (clock clk)
  (reset (rst_n active_low async))
  (read-max-pending 4)
  (write-max-pending 2)
  (submit-policy try)
  (read-submit axi0_read_submit)
  (read-complete axi0_read_complete)
  (write-submit axi0_write_submit)
  (write-complete axi0_write_complete)
  (id-families
    (write (width 4) (request-id axi0_awid) (response-id axi0_bid))
    (read (width 4) (request-id axi0_arid) (response-id axi0_rid)))
  (status
    ...))
```

If `(id-families ...)` is omitted, the original capacity/status sample remains
valid and behavior-compatible.

When `(id-families ...)` is present, both `write` and `read` families must be
explicit. A zero-width family declares that the family is absent and must not
name request or response ID signals:

```text
(id-families
  (write (width 0))
  (read (width 0)))
```

## Runnable Sample

The new checked-in sample is:

```text
ppif/axi_manager_capacity_status_id_family.ppif
```

Useful commands:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_id_family.ppif
./bin/fsmgen --outdir generated ppif/axi_manager_capacity_status_id_family.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_id_family.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_id_family.ppif
./bin/fsmgen --outdir generated --verify-hdl ppif/axi_manager_capacity_status_id_family.ppif
```

The sample is support-accounted as:

```text
intent.ppif_axi_manager_capacity_status_id_family
```

## Report Contract

Schedule/report JSON keeps the existing schema:

```text
fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1
```

The report additively emits `id_families` when the source supplies the clause:

```text
id_families:
  write:
    width: 4
    present: true
    request_id_signal: axi0_awid
    response_id_signal: axi0_bid
    source_anchors: [...]
  read:
    width: 4
    present: true
    request_id_signal: axi0_arid
    response_id_signal: axi0_rid
    source_anchors: [...]
```

For width `0`, `present` is `false` and the request/response ID signal fields
are omitted.

## Generated Artifact Boundary

This slice is static metadata only. It does not change generated `.isf`,
generated `.fsm`, or SystemVerilog HDL behavior. The same generated
`axi0_capacity_status.isf`, `axi0_capacity_status.fsm`, and
`axi0_capacity_status` SystemVerilog module are produced with or without
`id_families`.

## Diagnostics

The implementation fails closed on:

- missing `read` or `write` family clauses when `(id-families ...)` is present;
- unsupported family names;
- duplicate family clauses;
- missing `(width ...)`;
- non-integer, negative, or greater-than-32 widths;
- positive-width families missing request or response ID signal names;
- zero-width families that supply request or response ID signal names;
- ID signal names that collide with clock, reset, submit/complete events,
  status outputs, generated storage names, or each other.

## Explicit Residue

This slice does not implement ID allocation, per-transaction user-ID
validation, same-ID ordering, different-ID interleaving, `BID`/`RID` response
matching, bursts, queued/blocking policy, transaction classes,
unique-in-flight behavior, profile aliases, full AXI manager behavior, or
VHDL backend/reroute work.
