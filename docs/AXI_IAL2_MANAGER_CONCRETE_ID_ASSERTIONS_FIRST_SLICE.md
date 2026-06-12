# AXI IAL2 Manager Concrete ID Assertions First Slice

Status: shipped for the public `.ppif` AXI manager capacity/status object.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

This slice implements the concrete transaction ID assertion boundary selected
by
[docs/AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_READINESS_AUDIT.md](AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_READINESS_AUDIT.md).

## Shipped Public Syntax

No new public clause is introduced. The existing `(id-families ...)` and
`(transactions ...)` clauses now become behavior-bearing when a transaction
uses a concrete requested ID:

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

`(id auto)` remains report-only. `(id (value N))` emits request and response
ID equality assertions when the matching ID family is present and positive
width.

## Generated Behavior

For a concrete read transaction with `(id (value 3))`, generated IAL1 declares
only the used read ID-family signals as inputs:

```text
(input axi0_arid (width 4))
(input axi0_rid (width 4))
```

It then emits an assertion-only transaction:

```text
(transaction axi0_id_response_checks
  (assert (=> axi0_read_submit (== axi0_arid 3))
          "axi0 r0 request ID matches concrete ID")
  (assert (=> axi0_read_complete (== axi0_rid 3))
          "axi0 r0 response ID matches concrete ID"))
```

The scheduled `.fsm` exposes matching `+size` entries and `+assert` carriers:

```text
(+size
  (axi0_arid 4)
  (axi0_rid 4))

(+assert
  (axi0_id_response_checks_assert_0 assert
    (=> axi0_read_submit (== axi0_arid 3))
    "axi0 r0 request ID matches concrete ID")
  (axi0_id_response_checks_assert_1 assert
    (=> axi0_read_complete (== axi0_rid 3))
    "axi0 r0 response ID matches concrete ID"))
```

SystemVerilog emission uses the existing verification-only assertion backend:

```systemverilog
`ifndef SYNTHESIS
  assert property (@(posedge clk) disable iff (!rst_n) ((axi0_read_submit) |-> (axi0_arid == 3))) else $error("axi0 r0 request ID matches concrete ID");
  assert property (@(posedge clk) disable iff (!rst_n) ((axi0_read_complete) |-> (axi0_rid == 3))) else $error("axi0 r0 response ID matches concrete ID");
`endif
```

When per-transaction dispatch is used, the assertions bind to the
per-transaction events, for example `axi0_r0_request` and
`axi0_r0_complete`, while the read/write capacity rule matrices keep their
existing dispatch fan-in behavior.

## Report Contract

Schedule/report JSON keeps the existing schema:

```text
fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1
```

The report additively emits:

```text
id_response_rule_engine:
  mode: concrete_id_assertions
  id_signal_inputs:
    - axi0_arid
    - axi0_rid
  checks:
    - transaction: r0
      tag: rd0
      kind: read
      phase: request
      event: axi0_read_submit
      id_signal: axi0_arid
      id_value: 3
      family_width: 4
      enforcement: runtime_assertion
      assertion_name: r0_request_id_matches
    - transaction: r0
      tag: rd0
      kind: read
      phase: response
      event: axi0_read_complete
      id_signal: axi0_rid
      id_value: 3
      family_width: 4
      enforcement: runtime_assertion
      assertion_name: r0_response_id_matches
  residue:
    - auto_id_allocation
    - id_release
    - same_id_ordering
    - response_demux
```

Existing `id_families`, `transactions`, and `transaction_event_dispatch`
metadata remain machine-readable structural records.

## Runnable Samples

Concrete-ID assertions are covered by the existing transaction samples:

```text
ppif/axi_manager_capacity_status_transaction_envelope.ppif
ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif
```

Useful commands:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_transaction_envelope.ppif
./bin/fsmgen --outdir generated ppif/axi_manager_capacity_status_transaction_envelope.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_transaction_envelope.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_transaction_envelope.ppif
./bin/fsmgen --outdir generated --verify-hdl ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif
```

Support-accounting entries remain:

```text
intent.ppif_axi_manager_capacity_status_transaction_envelope
intent.ppif_axi_manager_capacity_status_transaction_event_dispatch
```

## Diagnostics

The implementation fails closed on:

- concrete requested IDs when `id_families` is absent;
- concrete requested IDs when the matching ID-family width is `0`;
- concrete requested IDs that do not fit the declared ID-family width;
- ID-family signal collisions with events, status outputs, storage,
  transaction names, or transaction tags;
- duplicate request or response events among concrete-ID transactions, because
  shared events cannot uniquely identify which concrete transaction ID is being
  asserted.

## Explicit Residue

This slice does not implement auto-ID allocation, dynamic user-ID arbitration
while issuing, ID release, per-ID busy scoreboards, same-ID ordering,
different-ID interleaving, generated `BID`/`RID` response demux, burst or
last-beat tracking, address/data/control payload binding, queued/blocking
policy, profile aliases, full AXI manager syntax, `.pif`, `.ppi`, `.axi`, or
VHDL backend/reroute behavior.
