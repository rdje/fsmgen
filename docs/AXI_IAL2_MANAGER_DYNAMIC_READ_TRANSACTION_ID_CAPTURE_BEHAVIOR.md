# AXI IAL2 Manager Dynamic Read Transaction-ID Capture Behavior

Status: implementation record for `IAL2-FEATURE-COMPLETENESS-FRONTIER.227` on
2026-06-22.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.227`

## Summary

FSMGen now generates bounded single-beat dynamic read transaction-ID capture and
`RID` response matching for the selected AXI manager capacity/status shape.

The supported public shape is intentionally narrow:

- exactly one read transaction in the selected read family uses `(id dynamic)`;
- `response-demux.read` is present with `response-scope single-beat`;
- `response-demux.read.transaction-completion` is `generated`;
- the generated transaction completion event is distinct from the raw read
  response event;
- the read family does not combine this dynamic shape with read
  `auto-id-lifecycle`, `same-id-ordering`, read-data, concrete queue-head
  demux, or mixed auto-ID/queue-head demux.

The burst-last sibling now ships separately under
`IAL2-FEATURE-COMPLETENESS-FRONTIER.231`; see
`docs/AXI_IAL2_MANAGER_DYNAMIC_READ_RLAST_TRANSACTION_ID_CAPTURE_BEHAVIOR.md`.
Dynamic read-data routing, burst-length/runtime validation, multiple dynamic
read transactions, mixed dynamic/static read demux, same-cycle recapture,
dynamic same-ID ordering, queues, scoreboards, direct backend behavior, and
VHDL remain future exact-owner work.

## Runnable PPIF

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_dynamic_read_response_demux.ppif
```

The relevant source shape is:

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
```

Use the standard report probes:

```sh
env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json \
  ppif/axi_manager_capacity_status_dynamic_read_response_demux.ppif

env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json \
  ppif/axi_manager_capacity_status_dynamic_read_response_demux.ppif

env -u PERL5LIB ./bin/fsmgen --quiet --strict --emit-semantic-json \
  ppif/axi_manager_capacity_status_dynamic_read_response_demux.ppif
```

## Generated Behavior

The dynamic read request-ID source is the read family request ID signal declared
under `id-families.read`, for example `axi0_arid`. FSMGen captures that ID only
when the dynamic read request is admitted by the read capacity matrix and the
single-active dynamic read busy bit is clear.

The generated capture rule stores the request ID and marks the dynamic read
transaction active:

```text
axi0_r0_dynamic_id_q   <= axi0_arid
axi0_r0_dynamic_busy_q <= 1
```

The generated read response-demux rule matches the raw accepted read response
against the captured selected ID:

```text
axi0_read_complete && axi0_r0_dynamic_busy_q &&
  (axi0_rid == axi0_r0_dynamic_id_q)
```

That match pulses `axi0_r0_complete`. The generated release rule clears
`axi0_r0_dynamic_busy_q` from the completion pulse.

## Report Contract

The transaction report changes the covered dynamic read transaction from
metadata-only `selected_not_generated` to generated capture/matching ownership:

```yaml
transactions:
  - name: r0
    kind: read
    id:
      policy: dynamic
      family: read
      family_width: 4
      request_id_source: axi0_arid
      response_id_signal: axi0_rid
      ownership: user_supplied
      implementation_status: generated_capture_matching
```

The response-demux report identifies the generated dynamic read contract:

```yaml
response_demux:
  mode: bounded_dynamic_read_rid_demux_contract
  generated_behavior: true
  read:
    mode: bounded_dynamic_read_rid_demux_contract
    response_event_role: raw_accepted_read_response
    response_scope: single_beat
    response_id_signal: axi0_rid
    transaction_completion_source: generated_dynamic_demux
    transaction_completion_semantics: matched_dynamic_id_single_beat
    dynamic_transactions: [r0]
    dynamic_capture:
      request_id_source: axi0_arid
      capture_event_source: admitted_dynamic_read_request
      ownership: single_active_dynamic_read
      selected_id_signal: axi0_r0_dynamic_id_q
      busy_signal: axi0_r0_dynamic_busy_q
      capture_rule: axi0_r0_dynamic_id_capture
      release_rule: axi0_r0_dynamic_id_release
    generated_rules: [axi0_r0_response_demux]
    generated_completion_signals: [axi0_r0_complete]
    generated_assertions:
      - axi0_r0_dynamic_request_not_busy
      - axi0_read_dynamic_response_active_match
      - axi0_r0_dynamic_completion_active
```

The response-demux residue for this first read shape remains:

```yaml
residue:
  - same_id_ordering
  - read_data_interleaving
  - bursts
```

## Generated HDL Evidence

The SystemVerilog path declares both dynamic ID inputs and generated state:

```systemverilog
input  wire [3:0] axi0_arid,
input  wire [3:0] axi0_rid,
output reg        axi0_r0_complete,
reg               axi0_r0_dynamic_busy_q;
reg [3:0]         axi0_r0_dynamic_id_q;
```

The lowered guard includes the selected-ID comparison:

```systemverilog
axi0_read_complete & axi0_r0_dynamic_busy_q &
  (axi0_rid == axi0_r0_dynamic_id_q)
```

The assertion backend emits read-specific dynamic checks for:

- admitted dynamic read request is not already active;
- raw read response matches an active captured ID;
- generated dynamic read completion releases active captured ID.

## Preservation

This slice preserves:

- metadata-only `(id dynamic)` behavior when no response-demux behavior consumes
  the dynamic ID;
- generated single-active dynamic write `BID` response matching;
- auto-ID, concrete queue-head, mixed auto-ID/queue-head, read single-beat,
  read burst-last, read-data, burst-length, runtime-validation, and multi-beat
  output-bank behavior already shipped for non-dynamic shapes;
- fail-closed diagnostics for the dynamic read shapes outside this selected
  single-beat contract.
