# AXI IAL2 Manager Transaction-Envelope First Slice

Status: shipped for the public `.ppif` AXI manager capacity/status object.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

This slice implements the static transaction-envelope metadata selected by
[docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_SELECTION.md](AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_SELECTION.md)
and scoped by
[docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_READINESS_AUDIT.md](AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_READINESS_AUDIT.md).

## Shipped Public Syntax

The existing `manager-capacity-status` object may now include an optional
`(transactions ...)` clause:

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
  (transactions
    (write w0
      (tag wr0)
      (request axi0_write_submit)
      (completion axi0_write_complete)
      (id auto))
    (read r0
      (tag rd0)
      (request axi0_read_submit)
      (completion axi0_read_complete)
      (id (value 3))))
  (status
    ...))
```

`(id auto)` records an automatic-ID policy. `(id (value N))` records a
concrete requested ID value and requires the matching `read` or `write`
ID-family to be present with a positive width.

If `(transactions ...)` is omitted, the original capacity/status and
ID-family samples remain valid and behavior-compatible.

## Structural Contract

The parser normalizes source syntax to machine-readable structural entries,
not raw source-line strings:

```perl
transactions => [
    {
        kind             => 'write',
        name             => 'w0',
        tag              => 'wr0',
        request_event    => 'axi0_write_submit',
        completion_event => 'axi0_write_complete',
        id               => { policy => 'auto' },
    },
    {
        kind             => 'read',
        name             => 'r0',
        tag              => 'rd0',
        request_event    => 'axi0_read_submit',
        completion_event => 'axi0_read_complete',
        id               => { value => 3 },
    },
]
```

For this first slice, request and completion bindings must reference the
existing direction-level abstract events. A `write` transaction binds to
`write-submit`/`write-complete`; a `read` transaction binds to
`read-submit`/`read-complete`.

## Runnable Sample

The checked-in sample is:

```text
ppif/axi_manager_capacity_status_transaction_envelope.ppif
```

Useful commands:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_transaction_envelope.ppif
./bin/fsmgen --outdir generated ppif/axi_manager_capacity_status_transaction_envelope.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_transaction_envelope.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_transaction_envelope.ppif
./bin/fsmgen --outdir generated --verify-hdl ppif/axi_manager_capacity_status_transaction_envelope.ppif
```

The sample is support-accounted as:

```text
intent.ppif_axi_manager_capacity_status_transaction_envelope
```

## Report Contract

Schedule/report JSON keeps the existing schema:

```text
fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1
```

The report additively emits `transactions` when the source supplies the
clause:

```text
transactions:
  - name: w0
    kind: write
    tag: wr0
    request_event: axi0_write_submit
    completion_event: axi0_write_complete
    id:
      policy: auto
    source_anchors: [...]
  - name: r0
    kind: read
    tag: rd0
    request_event: axi0_read_submit
    completion_event: axi0_read_complete
    id:
      policy: concrete
      value: 3
      family: read
      family_width: 4
      fits: true
    source_anchors: [...]
```

## Generated Artifact Boundary

At the time this slice shipped, transaction-envelope data was static metadata
only. The later concrete-ID assertion slice now makes transactions with
concrete `(id (value N))` behavior-bearing: generated `.isf` declares the used
ID-family request/response signals, generated `.fsm` carries `+assert`
entries, and SystemVerilog emits verification-only concrete-ID assertions.
Transactions that use `(id auto)` remain report-only until a later allocator
slice ships.

See
[docs/AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE.md](AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE.md)
for the current generated artifact boundary.

## Diagnostics

The implementation fails closed on:

- missing transaction names, tags, request events, completion events, or ID
  clauses;
- unsupported transaction kinds;
- duplicate transaction names or tags;
- transaction names or tags that collide with existing manager signals or
  each other;
- write transactions bound to read events, or read transactions bound to
  write events;
- concrete requested IDs when `id_families` is absent;
- concrete requested IDs when the matching ID-family width is `0`;
- concrete requested IDs that do not fit the declared ID-family width;
- malformed `(id ...)` forms or unsupported transaction clauses.

## Explicit Residue

This slice does not implement ID allocation algorithms, dynamic user-ID
validation while issuing work, same-ID ordering queues, different-ID
interleaving, `BID`/`RID` response matching, bursts, queued/blocking policy,
address/data/control payload binding, per-transaction event ports, dynamic
dispatch, transaction classes, profile aliases, full AXI manager behavior, or
VHDL backend/reroute work.

Concrete transaction ID request/response assertions are no longer residue;
they are shipped by
[docs/AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE.md](AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE.md).
