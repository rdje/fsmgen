# AXI IAL2 Manager Write Response Demux Metadata First Slice

Status: shipped for the public `.ppif` AXI manager capacity/status object.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

This slice implements the parser/report metadata boundary selected by
[docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md](AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md).
Generated write `BID` demux behavior remains a later owner.

## Shipped Public Syntax

The existing `manager-capacity-status` object now accepts one optional
write-only `response-demux` clause:

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
  (response-demux
    (write
      (response-event axi0_write_complete)
      (transaction-completion generated)))
  (status
    ...))
```

The first supported family is `write` only. `response-event` must equal the
top-level `write-complete` event in this bounded slice. The
`transaction-completion generated` marker records that write transaction
completion names are owned by the response-demux contract under this explicit
opt-in. Without `response-demux`, transaction completion names remain authored
environment inputs.

## Generated Behavior

This slice is intentionally metadata-only. It does not change generated
`.isf`, generated `.fsm`, or HDL behavior.

For the shipped sample, `axi0_bid` is not yet added as an IAL1 input by
response demux, and no generated demux rules are emitted. Generated request-ID
drive from `auto-id-lifecycle` remains unchanged.

## Report Contract

Schedule/report JSON keeps the existing schema:

```text
fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1
```

The report additively emits `response_demux`:

```text
response_demux:
  mode: bounded_write_bid_demux_contract
  generated_behavior: false
  write:
    response_event: axi0_write_complete
    response_id_signal: axi0_bid
    response_id_direction: generated_input
    transaction_completion_source: generated_demux
    auto_transactions:
      - w0
      - w1
  residue:
    - generated_write_bid_demux
    - read_response_demux
    - same_id_ordering
    - read_data_interleaving
    - bursts
```

The response ID direction records the future generated input for `BID`; it
does not add that input to generated artifacts in this slice.

## Runnable Sample

The checked-in sample is:

```text
ppif/axi_manager_capacity_status_response_demux.ppif
```

Useful commands:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_response_demux.ppif
./bin/fsmgen --outdir generated ppif/axi_manager_capacity_status_response_demux.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_response_demux.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_response_demux.ppif
```

Support-accounting entry:

```text
intent.ppif_axi_manager_capacity_status_response_demux
```

## Diagnostics

The implementation fails closed on:

- duplicate `response-demux` clauses;
- unsupported families such as `read`;
- duplicate `write` family clauses;
- missing, duplicate, malformed, or non-generated response-demux subclauses;
- `response-event` values that differ from top-level `write-complete`;
- `response_demux` without `id_families`, `transactions`, or
  `auto_id_lifecycle` metadata;
- `response_demux.write` without write `auto_id_lifecycle` metadata;
- zero-width or absent write ID-family metadata;
- no auto-ID write transactions.

## Explicit Residue

This slice does not implement generated write `BID` demux rules, generated
transaction completion signals, unmatched-response assertions,
inactive-response assertions, ambiguous-match assertions, read `RID` demux,
same-ID ordering queues, read-data interleaving/reassembly, burst or
last-beat tracking, address/data/control payload binding, queued/blocking
policy, profile aliases, full AXI manager syntax, `.pif`, `.ppi`, `.axi`, or
VHDL backend/reroute behavior.

Follow-up: `IAL2-FEATURE-COMPLETENESS-FRONTIER.28` completed the behavior
readiness audit and selected `IAL2-FEATURE-COMPLETENESS-FRONTIER.29` as a
small IAL1 prerequisite. `.29` is now shipped: generated write `BID` demux
completion names can lower as rule-owned `(pulse TARGET)` one-cycle pulses.
The next owner is `.30`, generated write `BID` response-demux behavior.
