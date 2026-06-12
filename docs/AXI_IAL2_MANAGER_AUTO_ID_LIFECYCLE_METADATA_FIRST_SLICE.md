# AXI IAL2 Manager Auto-ID Lifecycle Metadata First Slice

Status: shipped for the public `.ppif` AXI manager capacity/status object.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

This slice implements the parser/report metadata boundary selected by
[docs/AXI_IAL2_MANAGER_AUTO_ID_POOL_CONTRACT_SELECTION.md](AXI_IAL2_MANAGER_AUTO_ID_POOL_CONTRACT_SELECTION.md).

## Shipped Public Syntax

The existing `manager-capacity-status` object now accepts one optional
`(auto-id-lifecycle ...)` clause:

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
  (auto-id-lifecycle
    (write (pool 0 1)))
  (status
    ...))
```

Each listed family must be `write` or `read`, must have a positive-width
declared ID family, and must have at least one transaction in that family with
`(id auto)`. The `(pool ...)` list is required, author ordered, unique, and
bounded to one through four integer ID values that fit the declared family
width.

Existing `(id auto)` transactions remain structural/report-only when
`auto-id-lifecycle` is absent.

## Generated Behavior

This slice is intentionally metadata-only. It does not change generated
`.isf`, generated `.fsm`, or HDL behavior.

For the shipped sample, generated request ID drive is not emitted yet:

```text
(output axi0_awid ...)
```

is not present, and `axi0_awid` is not treated as an input either. Concrete ID
assertions for concrete transactions keep their existing behavior.

## Report Contract

Schedule/report JSON keeps the existing schema:

```text
fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1
```

The report additively emits `auto_id_lifecycle`:

```text
auto_id_lifecycle:
  mode: bounded_pool_contract
  generated_behavior: false
  max_pool_entries_per_family: 4
  families:
    - family: write
      request_id_signal: axi0_awid
      request_id_direction: generated_output
      response_id_signal: axi0_bid
      response_id_direction: generated_input
      pool:
        - 0
        - 1
      allocator: first_free_pool_order
      transaction_lifetime: single_active
      release: transaction_completion_event
      no_id_available: runtime_assertion
      auto_transactions:
        - w0
        - w1
  residue:
    - generated_request_id_drive
    - id_release_rules
    - same_id_ordering
    - response_demux
```

The request ID direction records the future manager-owned generated outputs
for `AWID` and `ARID`. The response ID direction records that `BID` and `RID`
remain generated inputs.

## Runnable Sample

The checked-in sample is:

```text
ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif
```

Useful commands:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif
./bin/fsmgen --outdir generated ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif
```

Support-accounting entry:

```text
intent.ppif_axi_manager_capacity_status_auto_id_lifecycle
```

## Diagnostics

The implementation fails closed on:

- unsupported or duplicate `auto-id-lifecycle` family clauses;
- missing, duplicate, malformed, empty, oversized, or non-unique `(pool ...)`
  lists;
- `auto_id_lifecycle` without `id_families` or `transactions` metadata;
- listed families with zero-width or absent ID families;
- pool values that do not fit the declared ID-family width;
- listed families with no auto-ID transaction.

## Explicit Residue

This slice does not implement generated request-ID drive, selected-ID storage,
busy/free storage, ID release rules, same-ID ordering, different-ID read-data
interleaving/reassembly, generated `BID`/`RID` response demux, burst or
last-beat tracking, address/data/control payload binding, queued/blocking
policy, profile aliases, full AXI manager syntax, `.pif`, `.ppi`, `.axi`, or
VHDL backend/reroute behavior.
