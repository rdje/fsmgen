# AXI IAL2 Manager Dynamic Write Transaction-ID Capture Behavior

Status: behavior shipped by `IAL2-FEATURE-COMPLETENESS-FRONTIER.223` on
2026-06-22; same-cycle release-and-recapture extension shipped by
`IAL2-FEATURE-COMPLETENESS-FRONTIER.365` on 2026-06-24.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.223`

## Summary

FSMGen now generates the first bounded dynamic write transaction-ID behavior
for the AXI manager capacity/status IAL2 object. The supported shape is one
transaction-local dynamic write ID consumed by explicit `response-demux.write`
syntax:

```lisp
(transactions
  (write w0
    (tag wr0)
    (request axi0_w0_request)
    (completion axi0_w0_complete)
    (id dynamic)))

(response-demux
  (write
    (response-event axi0_write_complete)
    (transaction-completion generated)))
```

The contract captures the write-family request ID source at the admitted
write request, stores it in generated selected-ID state, tracks a single
active dynamic write with generated busy state, matches the raw accepted write
response `BID` against that captured ID, pulses the transaction completion,
and releases busy from that generated completion. The `.365` extension also
handles a same-cycle generated completion plus new admitted `w0` request by
recapturing the new `AWID` while keeping busy asserted.

## Generated IAL1 Shape

For `ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif`, the
generated reviewable `.isf` declares:

- `axi0_w0_request` and raw `axi0_write_complete` inputs;
- generated request/response ID inputs `axi0_awid` and `axi0_bid`, both width
  4 in the sample;
- generated completion output `axi0_w0_complete`;
- generated storage `axi0_w0_dynamic_id_q` and
  `axi0_w0_dynamic_busy_q`.

The capture rule is guarded by admitted-request capacity and single-active
ownership:

```lisp
(rule axi0_w0_dynamic_id_capture
  (& (& axi0_w0_request (| (< axi0_pending_writes_q 2) axi0_w0_complete))
     (! axi0_w0_dynamic_busy_q))
  (axi0_w0_dynamic_id_q axi0_awid)
  (axi0_w0_dynamic_busy_q 1))
```

The response-demux rule matches the active captured ID:

```lisp
(rule axi0_w0_response_demux
  (& axi0_write_complete
     axi0_w0_dynamic_busy_q
     (== axi0_bid axi0_w0_dynamic_id_q))
  (pulse axi0_w0_complete))
```

The release-and-recapture rule handles a same-cycle generated matched
completion plus admitted request. The response match still uses the pre-update
selected ID and busy state; the recapture assignment updates the next-cycle
selected ID:

```lisp
(rule axi0_w0_dynamic_id_release_recapture
  (& (& axi0_w0_request (| (< axi0_pending_writes_q 2) axi0_w0_complete))
     axi0_w0_complete
     axi0_w0_dynamic_busy_q)
  (axi0_w0_dynamic_id_q axi0_awid)
  (axi0_w0_dynamic_busy_q 1))
```

The release-only rule clears the single-active busy bit from the generated
matched completion pulse only when there is no same-cycle request:

```lisp
(rule axi0_w0_dynamic_id_release
  (& axi0_w0_complete axi0_w0_dynamic_busy_q (! axi0_w0_request))
  (axi0_w0_dynamic_busy_q 0))
```

The generated runtime assertions require:

- an admitted dynamic write request only when the slot is idle or releasing in
  the same cycle;
- a raw write response to match an active captured dynamic ID;
- a generated dynamic completion to release an active captured ID.

## Report Surface

The covered transaction keeps `policy: dynamic` and changes only the
implementation status to generated behavior:

```yaml
transactions:
  - name: w0
    kind: write
    id:
      policy: dynamic
      family: write
      family_width: 4
      request_id_source: axi0_awid
      response_id_signal: axi0_bid
      ownership: user_supplied
      implementation_status: generated_capture_matching
```

The response-demux report marks the dynamic write behavior explicitly:

```yaml
response_demux:
  mode: bounded_dynamic_write_bid_demux_contract
  generated_behavior: true
  write:
    mode: bounded_dynamic_write_bid_demux_contract
    response_event: axi0_write_complete
    response_event_role: raw_accepted_write_response
    response_id_signal: axi0_bid
    response_id_direction: generated_input
    transaction_completion_source: generated_dynamic_demux
    transaction_completion_semantics: matched_dynamic_id
    dynamic_transactions: [w0]
    dynamic_capture:
      request_id_source: axi0_awid
      capture_event_source: admitted_dynamic_write_request
      ownership: single_active_dynamic_write
      selected_id_signal: axi0_w0_dynamic_id_q
      busy_signal: axi0_w0_dynamic_busy_q
      capture_rule: axi0_w0_dynamic_id_capture
      release_rule: axi0_w0_dynamic_id_release
      release_recapture_rule: axi0_w0_dynamic_id_release_recapture
      same_cycle_release_recapture_policy: single_active_dynamic_write
      release_recapture_source: generated_dynamic_demux_completion
      release_recapture_transaction: w0
    generated_rules: [axi0_w0_response_demux]
    generated_completion_signals: [axi0_w0_complete]
    generated_assertions:
      - axi0_w0_dynamic_request_idle_or_releasing
      - axi0_write_dynamic_response_active_match
      - axi0_w0_dynamic_completion_active
```

The top-level response-demux residue remains:

```yaml
residue:
  - read_response_demux
  - same_id_ordering
  - read_data_interleaving
  - bursts
```

## Public Sample And Checks

The public sample is support-accounted:

```text
ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif
```

Useful focused checks:

```bash
env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --output /tmp/fsmgen_dynamic_write_response_demux.sv ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif
```

## Residue

Metadata-only `(id dynamic)` remains supported when no same-family behavior
clause consumes it. The single-active dynamic write behavior in this note is
extended by
[AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_BEHAVIOR](AXI_IAL2_MANAGER_MULTIPLE_DYNAMIC_WRITE_RESPONSE_DEMUX_BEHAVIOR.md)
for all-dynamic write families with two or more write transactions, and by
[AXI_IAL2_MANAGER_DYNAMIC_WRITE_SAME_CYCLE_RECAPTURE_BEHAVIOR](AXI_IAL2_MANAGER_DYNAMIC_WRITE_SAME_CYCLE_RECAPTURE_BEHAVIOR.md)
for the single-active same-cycle release-and-recapture boundary. Broader
generated dynamic behavior still fails closed for:

- dynamic read response matching outside the selected single-active
  single-beat and burst-last/`RLAST` contracts;
- mixed dynamic/static write response demux;
- multiple dynamic write shapes outside the all-dynamic bounded response-demux
  contract;
- same-cycle release-and-recapture outside the selected single-active dynamic
  write `BID` boundary;
- same-ID ordering for dynamic IDs;
- read-data routing outside the selected single-active dynamic read-data
  shapes;
- queues, scoreboards, generalized arbitration, and full manager behavior;
- direct backend behavior, HDL shapes outside this selected SystemVerilog path,
  and VHDL.
