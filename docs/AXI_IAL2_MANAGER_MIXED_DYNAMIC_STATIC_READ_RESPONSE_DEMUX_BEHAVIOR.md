# AXI IAL2 Manager Mixed Dynamic/Static Read Response-Demux Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.276`

Date: 2026-06-23

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.276` ships generated bounded mixed
dynamic/static read single-beat `RID` response-demux behavior for the AXI
manager capacity/status IAL2 object.

The support-accounted public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux.ppif`.
It uses the existing explicit `response-demux.read` opt-in with
`response-scope single-beat`, exactly one dynamic read transaction, and exactly
one concrete static read transaction.

## Public Shape

The shipped public source shape is explicit:

```lisp
(transactions
  (read r0
    (tag rd0)
    (request axi0_r0_request)
    (completion axi0_r0_complete)
    (id dynamic))
  (read r1
    (tag rd1)
    (request axi0_r1_request)
    (completion axi0_r1_complete)
    (id concrete 3)))

(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope single-beat)
    (transaction-completion generated)))
```

The read ID family supplies the shared request ID source and response ID signal:

```lisp
(id-families
  (write (width 4) (request-id-signal axi0_awid) (response-id-signal axi0_bid))
  (read  (width 4) (request-id-signal axi0_arid) (response-id-signal axi0_rid)))
```

The bounded slice requires:

- exactly one selected dynamic read transaction;
- exactly one selected concrete static read transaction;
- `response-scope single-beat`;
- no read `auto_id_lifecycle`;
- no `same_id_ordering.read`;
- onehot0 same-cycle mixed read requests; and
- dynamic capture excluding the static concrete ID.

Burst-last `RID && RLAST`, read-data, burst-length/runtime, multi-beat output
banks, multiple mixed transactions, mixed burst-last recapture, broader
same-cycle widening, dynamic same-ID queues, scoreboards, direct backend
behavior, backend-language variants, and VHDL remain future exact-owner work.
Single-beat same-cycle release-and-recapture for this public sample is now
documented in
[AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR](AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md).

## Generated Behavior

For the public mixed read sample, FSMGen emits dynamic selected-ID state for
`r0` and static busy state for `r1`:

```text
axi0_r0_dynamic_id_q
axi0_r0_dynamic_busy_q
axi0_r1_static_busy_q
```

The dynamic transaction captures `axi0_arid` at its admitted read request only
when the dynamic transaction is not busy, the static request is not admitted in
the same cycle, and `axi0_arid != 4'd3`.

The static transaction captures only a busy bit at its admitted read request
when it is not already busy and the dynamic request is not admitted in the same
cycle.

Generated response-demux rules match the raw accepted read response:

```text
axi0_read_complete && axi0_r0_dynamic_busy_q && axi0_rid == axi0_r0_dynamic_id_q
axi0_read_complete && axi0_r1_static_busy_q  && axi0_rid == 4'd3
```

The matched rule pulses that transaction's generated completion output.
Generated release rules clear the dynamic busy bit or static busy bit from the
corresponding completion pulse.

## Report Contract

Schedule JSON reports the mixed dynamic/static read contract with:

```yaml
response_demux:
  mode: bounded_mixed_dynamic_static_read_rid_demux_contract
  generated_behavior: true
  read:
    mode: bounded_mixed_dynamic_static_read_rid_demux_contract
    response_event: axi0_read_complete
    response_event_role: raw_accepted_read_response
    response_scope: single_beat
    response_id_signal: axi0_rid
    response_id_direction: generated_input
    transaction_completion_source: generated_mixed_dynamic_static_read_demux
    transaction_completion_semantics: matched_dynamic_or_static_concrete_id_single_beat
    mixed_transactions:
      dynamic: r0
      static: r1
    static_id_reservation:
      transaction: r1
      concrete_id: 3
      concrete_id_literal: 4'd3
      dynamic_capture_policy: dynamic_id_must_not_equal_static_concrete_id
    dynamic_capture:
      request_id_source: axi0_arid
      ownership: mixed_dynamic_static_unique_read_ids
      simultaneous_request_policy: onehot0_mixed_read_request
```

The read report also lists generated completion signals, response-demux rules,
and generated assertion names. The shipped assertion roles are:

- dynamic request not busy;
- static request not busy;
- mixed read request onehot0;
- dynamic request does not use the static concrete ID;
- active dynamic ID is not the static concrete ID;
- raw response active match;
- raw response unique match;
- dynamic completion-active release; and
- static completion-active release.

## Public Sample And Checks

The public sample is support-accounted:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux.ppif
```

Useful focused checks:

```bash
env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --output /tmp/fsmgen_mixed_dynamic_static_read_demux.sv ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_mixed_dynamic_static_read_demux_verify.sv ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux.ppif
```

The behavior is covered by the bounded focused dynamic test
`t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t` and by
support-accounting test `t/248-regression-corpus-accounting.t`.

## Residue

The implementation moves only the one-dynamic plus one-static concrete read
single-beat `RID` response-demux shape out of dynamic residue. These remain
fail-closed or unshipped:

- mixed dynamic/static read burst-last `RID && RLAST` response-demux;
- read-data over mixed dynamic/static read response-demux;
- burst-length/runtime behavior over mixed dynamic/static read response-demux;
- multi-beat output banks over mixed dynamic/static read response-demux;
- multiple mixed dynamic/static read or write transactions;
- same-cycle dynamic/static request widening beyond onehot0;
- mixed read burst-last release-and-recapture and broader recapture shapes;
- dynamic same-ID ordering;
- dynamic same-ID queues and scoreboards;
- direct backend behavior outside the selected generated SystemVerilog path;
- backend-language variants; and
- VHDL.

## Validation

Closeout validation covered syntax checks for touched Perl modules/tests, strict
check JSON, semantic JSON, direct report inspection, generated SystemVerilog,
and `--verify-hdl` probes for the new public sample, focused dynamic validation
through `t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t`, and
support-accounting validation through
`t/248-regression-corpus-accounting.t`.

Full `t/1437-axi-ial2-manager-capacity-status-generator.t` was attempted but
interrupted after remaining CPU-bound in the interactive run; process sampling
showed active Perl regex work. The new generator assertions in that file were
syntax-clean, and direct public-sample schedule/check/semantic/HDL/focused
regression probes covered the shipped behavior.

## Rollback

Rollback is the `.276` implementation commit. Reverting it removes the public
mixed dynamic/static read PPIF sample, support-accounting entry, generated
mixed dynamic/static read demux behavior, focused coverage, docs, and facts,
restoring `.276` as the active frontier.
