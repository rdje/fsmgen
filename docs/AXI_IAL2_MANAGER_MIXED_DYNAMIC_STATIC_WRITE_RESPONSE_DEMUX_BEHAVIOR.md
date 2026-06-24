# AXI IAL2 Manager Mixed Dynamic/Static Write Response-Demux Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.272`

Date: 2026-06-23

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.272` ships generated bounded mixed
dynamic/static write `BID` response-demux behavior for the AXI manager
capacity/status IAL2 object.

The support-accounted public sample is
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux.ppif`.
It uses the existing explicit `response-demux.write` opt-in with exactly one
dynamic write transaction and exactly one concrete static write transaction.

## Public Shape

The shipped public source shape remains explicit:

```lisp
(transactions
  (write w0
    (tag wr0)
    (request axi0_w0_request)
    (completion axi0_w0_complete)
    (id dynamic))
  (write w1
    (tag wr1)
    (request axi0_w1_request)
    (completion axi0_w1_complete)
    (id concrete 3)))

(response-demux
  (write
    (response-event axi0_write_complete)
    (transaction-completion generated)))
```

The write ID family supplies the shared request ID source and response ID
signal:

```lisp
(id-families
  (write (width 4) (request-id-signal axi0_awid) (response-id-signal axi0_bid))
  (read  (width 4) (request-id-signal axi0_arid) (response-id-signal axi0_rid)))
```

The bounded slice requires:

- exactly one selected dynamic write transaction;
- exactly one selected concrete static write transaction;
- no write `auto_id_lifecycle`;
- no `same_id_ordering.write`;
- onehot0 same-cycle mixed write requests; and
- dynamic capture excluding the static concrete ID.

Read-side mixed dynamic/static demux, multiple mixed dynamic/static write
transactions, same-cycle request widening beyond onehot0, same-cycle
release-and-recapture outside the selected one-dynamic/one-static write
sample, dynamic same-ID queues, and scoreboards remain future exact-owner work.
Later `.389` extends this same public sample with mixed dynamic/static write
same-cycle release-and-recapture.

## Generated Behavior

For the public mixed write sample, FSMGen emits dynamic selected-ID state for
`w0` and static busy state for `w1`:

```text
axi0_w0_dynamic_id_q
axi0_w0_dynamic_busy_q
axi0_w1_static_busy_q
```

The dynamic transaction captures `axi0_awid` at its admitted write request
only when the dynamic transaction is not busy, the static request is not
admitted in the same cycle, and `axi0_awid != 4'd3`.

The static transaction captures only a busy bit at its admitted write request
when it is not already busy and the dynamic request is not admitted in the
same cycle.

Generated response-demux rules match the raw accepted write response:

```text
axi0_write_complete && axi0_w0_dynamic_busy_q && axi0_bid == axi0_w0_dynamic_id_q
axi0_write_complete && axi0_w1_static_busy_q  && axi0_bid == 4'd3
```

The matched rule pulses that transaction's generated completion output.
Generated release rules clear the dynamic busy bit or static busy bit from the
corresponding completion pulse.

## Report Contract

Schedule JSON reports the mixed dynamic/static write contract with:

```yaml
response_demux:
  mode: bounded_mixed_dynamic_static_write_bid_demux_contract
  generated_behavior: true
  write:
    mode: bounded_mixed_dynamic_static_write_bid_demux_contract
    response_event: axi0_write_complete
    response_event_role: raw_accepted_write_response
    response_id_signal: axi0_bid
    response_id_direction: generated_input
    transaction_completion_source: generated_mixed_dynamic_static_demux
    transaction_completion_semantics: matched_dynamic_or_static_concrete_id
    mixed_transactions:
      dynamic: w0
      static: w1
    static_id_reservation:
      transaction: w1
      concrete_id: 3
      concrete_id_literal: 4'd3
      dynamic_capture_policy: dynamic_id_must_not_equal_static_concrete_id
    dynamic_capture:
      request_id_source: axi0_awid
      ownership: mixed_dynamic_static_unique_write_ids
      simultaneous_request_policy: onehot0_mixed_write_request
```

The write report also lists generated completion signals, response-demux
rules, and generated assertion names. The shipped assertion roles are:

- dynamic request not busy;
- static request not busy;
- mixed write request onehot0;
- dynamic request does not use the static concrete ID;
- active dynamic ID is not the static concrete ID;
- raw response active match;
- raw response unique match;
- dynamic completion-active release; and
- static completion-active release.

Later `.389` changes the two request-not-busy roles for this same public sample
to idle-or-releasing and adds dynamic/static release-recapture report fields;
see
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR](AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_WRITE_RECAPTURE_BEHAVIOR.md).

## Public Sample And Checks

The public sample is support-accounted:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux.ppif
```

Useful focused checks:

```bash
env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --output /tmp/fsmgen_mixed_dynamic_static_write_demux.sv ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_mixed_dynamic_static_write_demux_verify.sv ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux.ppif
```

The behavior is covered by the bounded focused dynamic test
`t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t` and by
support-accounting test `t/248-regression-corpus-accounting.t`.

## Residue

The implementation moves only the one-dynamic plus one-static concrete write
`BID` response-demux shape out of dynamic residue. These remain fail-closed or
unshipped:

- mixed dynamic/static read response-demux;
- multiple mixed dynamic/static write response-demux transactions;
- same-cycle dynamic/static request widening beyond onehot0;
- same-cycle release-and-recapture outside the selected one-dynamic/one-static
  write sample;
- dynamic same-ID ordering;
- dynamic same-ID queues and scoreboards;
- direct backend behavior outside the selected generated SystemVerilog path;
- backend-language variants; and
- VHDL.

## Validation

Closeout validation covered syntax checks for touched Perl modules/tests,
direct schedule JSON, strict check JSON, semantic JSON, generated
SystemVerilog, and `--verify-hdl` probes for the new public sample, guarded
focused dynamic validation through
`t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t`, and guarded
support-accounting validation through
`t/248-regression-corpus-accounting.t`.

Guarded full `t/1437-axi-ial2-manager-capacity-status-generator.t` was
attempted but did not complete within the bounded interactive run; stack
sampling showed it remained in existing large test-regex compilation while CPU
and memory stayed bounded. The new generator assertions in that file were kept
syntax-clean, and direct public-sample schedule/check/semantic/HDL/focused
regression probes covered the shipped behavior.

## Rollback

Rollback is the `.272` implementation commit. Reverting it removes the public
mixed dynamic/static write PPIF sample, support-accounting entry, generated
mixed dynamic/static write demux behavior, focused coverage, docs, and facts,
restoring `.272` as the active frontier.
