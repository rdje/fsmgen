# AXI IAL2 Manager Dynamic Read-Data Behavior

Status: implementation record for `IAL2-FEATURE-COMPLETENESS-FRONTIER.234` on
2026-06-22.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.234`

## Summary

FSMGen now generates bounded scalar read-data capture over the generated
single-active dynamic read response-demux family.

The public contract is intentionally narrow:

- exactly one read transaction in the selected read family uses `(id dynamic)`;
- `response-demux.read` is present and owns the generated completion pulse;
- `read-data.read` uses `completion-source response-demux`;
- scalar `capture-scope single-beat` is supported only with dynamic
  `response-scope single-beat`;
- scalar `capture-scope last-beat` is supported only with dynamic
  `response-scope burst-last`, a one-bit `last-signal`, and
  `status-policy last-beat`;
- `read-data.read` binds exactly the same single dynamic read transaction;
- dynamic `burst-length`, runtime beat-count/`RLAST` validation, and
  multi-beat output banks later shipped as bounded dynamic consumers.
  Single-active dynamic read single-beat recapture shipped in `.368`, and
  single-active dynamic burst-last `RID && RLAST` recapture shipped in `.372`
  while preserving the payload capture contracts described here. Multiple
  dynamic reads, mixed dynamic/static demux, dynamic same-ID ordering, queues,
  scoreboards, direct backend behavior, and VHDL remain future exact-owner
  work.

The generated behavior reuses the already shipped dynamic read selected-ID and
busy state. Read-data capture consumes the generated per-transaction completion
pulse and does not create a second raw `RID`/`RLAST` match path.

## Runnable PPIF

The support-accounted public samples are:

```text
ppif/axi_manager_capacity_status_dynamic_read_data.ppif
ppif/axi_manager_capacity_status_dynamic_read_data_last_beat.ppif
```

The single-beat sample shape is:

```lisp
(transactions
  (read r0
    (tag rd0)
    (request axi0_r0_request)
    (completion axi0_r0_complete)
    (id dynamic)))

(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope single-beat)
    (transaction-completion generated)))

(read-data
  (read
    (capture-scope single-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (interleaving single-beat-by-rid)
    (transaction r0
      (data-output axi0_r0_rdata)
      (status-output axi0_r0_rresp))))
```

The last-beat sample uses the same transaction and adds the dynamic RLAST
response-demux boundary:

```lisp
(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope burst-last)
    (last-signal axi0_rlast (width 1))
    (transaction-completion generated)))

(read-data
  (read
    (capture-scope last-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (status-policy last-beat)
    (interleaving last-beat-by-rid)
    (transaction r0
      (data-output axi0_r0_last_rdata)
      (status-output axi0_r0_last_rresp))))
```

Use the standard probes:

```sh
env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json \
  ppif/axi_manager_capacity_status_dynamic_read_data.ppif

env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json \
  ppif/axi_manager_capacity_status_dynamic_read_data.ppif

env -u PERL5LIB ./bin/fsmgen --quiet --strict --emit-semantic-json \
  ppif/axi_manager_capacity_status_dynamic_read_data.ppif

env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json \
  ppif/axi_manager_capacity_status_dynamic_read_data_last_beat.ppif

env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json \
  ppif/axi_manager_capacity_status_dynamic_read_data_last_beat.ppif

env -u PERL5LIB ./bin/fsmgen --quiet --strict --emit-semantic-json \
  ppif/axi_manager_capacity_status_dynamic_read_data_last_beat.ppif
```

## Generated Behavior

For single-beat dynamic read-data, the generated response-demux rule matches
the raw read response event against the captured dynamic ID and pulses the
transaction completion:

```lisp
(rule axi0_r0_response_demux
  (& axi0_read_complete axi0_r0_dynamic_busy_q
     (== axi0_rid axi0_r0_dynamic_id_q))
  (pulse axi0_r0_complete))
```

The read-data capture rule is guarded only by that generated completion pulse:

```lisp
(rule axi0_r0_read_data_capture axi0_r0_complete
  (axi0_r0_rdata axi0_rdata)
  (axi0_r0_rresp axi0_rresp))
```

For last-beat dynamic read-data, the response-demux completion also requires
the selected `RLAST` signal:

```lisp
(rule axi0_r0_response_demux
  (& axi0_read_complete axi0_r0_dynamic_busy_q
     (== axi0_rid axi0_r0_dynamic_id_q)
     axi0_rlast)
  (pulse axi0_r0_complete))
```

The scalar last-beat capture rule stores the final beat payload and status:

```lisp
(rule axi0_r0_read_data_capture axi0_r0_complete
  (axi0_r0_last_rdata axi0_rdata)
  (axi0_r0_last_rresp axi0_rresp))
```

No dynamic `ARLEN`, beat counter, per-beat payload bank, valid mask, length
output, or aggregate-only status output is generated by this slice.

## Report Contract

The dynamic single-beat read-data report uses this completion-validity
vocabulary:

```yaml
read_data:
  mode: bounded_single_beat_read_data_contract
  generated_behavior: true
  read:
    capture_scope: single_beat
    completion_source: response_demux
    completion_validity: generated_dynamic_read_response_demux_completion_pulse
    interleaving_policy: single_beat_by_rid
    transactions:
      - transaction: r0
        completion_signal: axi0_r0_complete
        data_output: axi0_r0_rdata
        status_output: axi0_r0_rresp
    generated_inputs: [axi0_rdata, axi0_rresp]
    generated_outputs: [axi0_r0_rdata, axi0_r0_rresp]
    generated_rules: [axi0_r0_read_data_capture]
```

The dynamic last-beat read-data report uses the last-beat completion vocabulary:

```yaml
read_data:
  mode: bounded_last_beat_read_data_contract
  generated_behavior: true
  read:
    capture_scope: last_beat
    completion_source: response_demux
    completion_validity: generated_dynamic_read_response_demux_last_beat_completion_pulse
    status_policy: last_beat
    interleaving_policy: last_beat_by_rid
    burst_length_source: rlast_only
    burst_length_validation: not_generated
    transactions:
      - transaction: r0
        completion_signal: axi0_r0_complete
        data_output: axi0_r0_last_rdata
        status_output: axi0_r0_last_rresp
    generated_inputs: [axi0_rdata, axi0_rresp]
    generated_outputs: [axi0_r0_last_rdata, axi0_r0_last_rresp]
    generated_rules: [axi0_r0_read_data_capture]
```

The dynamic response-demux report remains the source of selected-ID ownership:

```yaml
response_demux:
  read:
    transaction_completion_source: generated_dynamic_demux
    dynamic_transactions: [r0]
    generated_completion_signals: [axi0_r0_complete]
```

For the last-beat sample, `transaction_completion_source` is
`generated_dynamic_demux_last_beat`.

## Generated HDL Evidence

The SystemVerilog path exposes `RDATA` and `RRESP`, exposes the scalar
transaction outputs, and drives the capture enable from the generated dynamic
completion pulse:

```systemverilog
input  wire [31:0] axi0_rdata,
input  wire [1:0]  axi0_rresp,
output reg  [31:0] axi0_r0_rdata,
output reg  [1:0]  axi0_r0_rresp,

assign axi0_r0_read_data_capture_en = axi0_r0_complete;
```

The next-state assignments copy the raw response payload/status only when that
enable is active:

```systemverilog
axi0_r0_rdata_next = axi0_rdata;
axi0_r0_rresp_next = axi0_rresp;
```

The last-beat sample uses `axi0_r0_last_rdata` and `axi0_r0_last_rresp` instead.

## Preservation

This slice preserves:

- metadata-only `(id dynamic)` behavior when no response-demux behavior consumes
  the dynamic ID;
- generated single-active dynamic write `BID` response matching;
- generated single-active dynamic read single-beat and burst-last response-demux
  behavior without read-data;
- shipped auto-ID, concrete queue-head, mixed auto-ID/queue-head, scalar
  read-data, burst-length, runtime-validation, and multi-beat output-bank
  behavior for non-dynamic shapes;
- fail-closed diagnostics for dynamic read-data shapes outside exactly one
  scalar single-beat or scalar last-beat dynamic read transaction.
