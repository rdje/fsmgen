# AXI IAL2 Manager Transaction Event Dispatch First Slice

Status: shipped for the public `.ppif` AXI manager capacity/status object.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

This slice implements the additive transaction event dispatch and direction
fan-in behavior selected by
[docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_SELECTION.md](AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_SELECTION.md)
and scoped by
[docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_READINESS_AUDIT.md](AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_READINESS_AUDIT.md).

## Shipped Public Syntax

The existing optional `(transactions ...)` clause may now bind each logical
transaction to distinct request and completion events:

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
      (request axi0_w0_request)
      (completion axi0_w0_complete)
      (id auto))
    (write w1
      (tag wr1)
      (request axi0_w1_request)
      (completion axi0_w1_complete)
      (id auto))
    (read r0
      (tag rd0)
      (request axi0_r0_request)
      (completion axi0_r0_complete)
      (id (value 3))))
  (status
    ...))
```

If `(transactions ...)` is absent, the capacity/status shell still uses the
direction-level `read-submit`, `read-complete`, `write-submit`, and
`write-complete` events. If a transaction group contains exactly one event for
a direction and phase, the generated guard uses that scalar event directly. If
a group contains multiple unique events, the generated guard uses an OR fan-in
expression.

## Structural Contract

The parser still normalizes source syntax to machine-readable structural
entries:

```perl
transactions => [
    {
        kind             => 'write',
        name             => 'w0',
        tag              => 'wr0',
        request_event    => 'axi0_w0_request',
        completion_event => 'axi0_w0_complete',
        id               => { policy => 'auto' },
    },
    {
        kind             => 'read',
        name             => 'r0',
        tag              => 'rd0',
        request_event    => 'axi0_r0_request',
        completion_event => 'axi0_r0_complete',
        id               => { value => 3 },
    },
]
```

No raw assignment-line strings are introduced. The transaction AST remains the
contract carried by the generator and report surfaces.

## Generated Behavior

For the checked-in dispatch sample, generated IAL1 declares the transaction
events as inputs:

```text
(input axi0_w0_request)
(input axi0_w1_request)
(input axi0_w0_complete)
(input axi0_w1_complete)
(input axi0_r0_request)
(input axi0_r0_complete)
```

The write rule matrix uses OR fan-in for the two write transactions:

```text
(& (| axi0_w0_request axi0_w1_request)
   (! (| axi0_w0_complete axi0_w1_complete))
   (== axi0_pending_writes_q 0))
```

The read rule matrix keeps scalar guards because the sample has one read
transaction:

```text
(& axi0_r0_request (! axi0_r0_complete) (== axi0_pending_reads_q 0))
```

The generated `.fsm` preserves those guard expressions, and the
SystemVerilog backend lowers the OR fan-ins through the existing expression
path.

This slice also widens the IAL1 rule-conflict proof enough to understand the
bounded OR/negated-OR guard shape used by the generated rule matrix. That keeps
the generated idle, submit-only, complete-only, and submit+complete rules
provably disjoint without adding a direct IAL2-to-IAL0 lowering path.

## Runnable Sample

The checked-in sample is:

```text
ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif
```

Useful commands:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif
./bin/fsmgen --outdir generated ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif
./bin/fsmgen --outdir generated --verify-hdl ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif
```

The sample is support-accounted as:

```text
intent.ppif_axi_manager_capacity_status_transaction_event_dispatch
```

## Report Contract

Schedule/report JSON keeps the existing schema:

```text
fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1
```

The report additively emits `transaction_event_dispatch` when the source
supplies `(transactions ...)`:

```text
transaction_event_dispatch:
  mode: per_transaction_event_fanin
  directions:
    - direction: write
      request_events:
        - axi0_w0_request
        - axi0_w1_request
      completion_events:
        - axi0_w0_complete
        - axi0_w1_complete
      request_fanin: "(| axi0_w0_request axi0_w1_request)"
      completion_fanin: "(| axi0_w0_complete axi0_w1_complete)"
    - direction: read
      request_events:
        - axi0_r0_request
      completion_events:
        - axi0_r0_complete
      request_fanin: axi0_r0_request
      completion_fanin: axi0_r0_complete
```

Existing `transactions[]` entries remain structural metadata with `name`,
`kind`, `tag`, `request_event`, `completion_event`, `id`, and source anchors.

## Diagnostics

The implementation fails closed on:

- missing transaction names, tags, request events, completion events, or ID
  clauses;
- unsupported transaction kinds;
- duplicate transaction names or tags;
- malformed request or completion event identifiers;
- transaction event names that collide with clock, reset, status outputs,
  generated storage, ID-family signals, transaction names, or transaction tags;
- write transactions bound to the read direction-level event, or read
  transactions bound to the write direction-level event;
- duplicate per-direction request or completion event names when the source
  uses per-transaction dispatch;
- one event reused across different transaction event roles;
- concrete requested IDs when `id_families` is absent, zero-width, or too
  narrow for the requested value.

## Explicit Residue

This slice does not implement ID allocation algorithms, dynamic user-ID
validation while issuing work, ID release, per-ID scoreboards, same-ID
ordering queues, different-ID interleaving, `BID`/`RID` response matching,
burst and last-beat tracking, address/data/control payload binding,
transaction-specific completion routing beyond event provenance,
queued/blocking policy, profile aliases, full AXI manager syntax, `.pif`,
`.ppi`, `.axi`, or VHDL backend/reroute behavior.
