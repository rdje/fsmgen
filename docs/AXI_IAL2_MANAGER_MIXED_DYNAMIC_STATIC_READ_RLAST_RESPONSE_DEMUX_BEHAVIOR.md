# AXI IAL2 Manager Mixed Dynamic/Static Read RLAST Response-Demux Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.280`

Date: 2026-06-23

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.280` ships generated bounded mixed
dynamic/static read burst-last `RID && RLAST` response-demux behavior for the
AXI manager capacity/status IAL2 object.

The support-accounted public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif`.
It uses the existing explicit `response-demux.read` opt-in with
`response-scope burst-last`, one one-bit `last-signal`, exactly one dynamic
read transaction, and exactly one concrete static read transaction.

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
    (response-scope burst-last)
    (last-signal axi0_rlast (width 1))
    (transaction-completion generated)))
```

The read ID family supplies the shared request ID source and response ID
signal:

```lisp
(id-families
  (write (width 4) (request-id-signal axi0_awid) (response-id-signal axi0_bid))
  (read  (width 4) (request-id-signal axi0_arid) (response-id-signal axi0_rid)))
```

The bounded slice requires:

- exactly one selected dynamic read transaction;
- exactly one selected concrete static read transaction;
- `response-scope burst-last`;
- one one-bit `last-signal`;
- no read `auto_id_lifecycle`;
- no `same_id_ordering.read`;
- onehot0 same-cycle mixed read requests; and
- dynamic capture excluding the static concrete ID.

Read-data, burst-length/runtime validation, multi-beat output banks, multiple
mixed transactions, same-cycle widening, release-and-recapture, dynamic
same-ID queues, scoreboards, direct backend behavior, backend-language
variants, and VHDL remain future exact-owner work.

## Generated Behavior

For the public mixed read burst-last sample, FSMGen emits dynamic selected-ID
state for `r0` and static busy state for `r1`:

```text
axi0_r0_dynamic_id_q
axi0_r0_dynamic_busy_q
axi0_r1_static_busy_q
```

The dynamic transaction captures `axi0_arid` at its admitted read request only
when the dynamic transaction is not busy, the static request is not admitted in
the same cycle, and `axi0_arid != 4'd3`.

The static transaction captures only a busy bit at its admitted read request
when it is not already busy and the dynamic request is not admitted in the
same cycle.

Generated response-demux rules match the final accepted read response beat:

```text
axi0_read_complete && axi0_r0_dynamic_busy_q && axi0_rid == axi0_r0_dynamic_id_q && axi0_rlast
axi0_read_complete && axi0_r1_static_busy_q  && axi0_rid == 4'd3                 && axi0_rlast
```

The matched final-beat rule pulses that transaction's generated completion
output. Generated release rules clear the dynamic busy bit or static busy bit
from the corresponding completion pulse.

Raw `RID` beat assertions remain deliberately separate from final completion:
the active-match and unique-match assertions observe accepted read response
beats matched by `RID` while the completion rules additionally require
`RLAST`. This lets non-final beats prove ownership without releasing the
transaction before the final beat.

## Report Contract

Schedule JSON reports the mixed dynamic/static read burst-last contract with:

```yaml
response_demux:
  mode: bounded_mixed_dynamic_static_read_rid_rlast_demux_contract
  generated_behavior: true
  read:
    mode: bounded_mixed_dynamic_static_read_rid_rlast_demux_contract
    response_event: axi0_read_complete
    response_event_role: raw_accepted_read_response_beat
    response_scope: burst_last
    response_id_signal: axi0_rid
    response_id_direction: generated_input
    last_signal: axi0_rlast
    last_signal_direction: generated_input
    last_signal_width: 1
    transaction_completion_source: generated_mixed_dynamic_static_read_demux_last_beat
    transaction_completion_semantics: matched_dynamic_or_static_concrete_id_and_last_signal
    beat_valid_output: none
    burst_length_source: rlast_only
    burst_length_validation: not_generated
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
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif
```

Useful focused checks:

```bash
env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --output /tmp/fsmgen_mixed_dynamic_static_read_rlast_demux.sv ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_mixed_dynamic_static_read_rlast_demux_verify.sv ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif
```

The behavior is covered by the bounded focused dynamic test
`t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t` and by
support-accounting test `t/248-regression-corpus-accounting.t`.

## Residue

The implementation moves only the one-dynamic plus one-static concrete read
burst-last `RID && RLAST` response-demux shape out of dynamic residue. These
remain fail-closed or unshipped:

- read-data over mixed dynamic/static read response-demux;
- burst-length/runtime behavior over mixed dynamic/static read response-demux;
- multi-beat output banks over mixed dynamic/static read response-demux;
- multiple mixed dynamic/static read or write transactions;
- same-cycle dynamic/static request widening beyond onehot0;
- same-cycle release-and-recapture;
- dynamic same-ID ordering;
- dynamic same-ID queues and scoreboards;
- direct backend behavior outside the selected generated SystemVerilog path;
- backend-language variants; and
- VHDL.

## Validation

Closeout validation covered syntax checks for touched Perl modules/tests,
strict check JSON, semantic JSON, direct report inspection, generated
SystemVerilog, `--verify-hdl`, focused dynamic validation through
`t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t`, and
support-accounting validation through
`t/248-regression-corpus-accounting.t`.

Full `t/1437-axi-ial2-manager-capacity-status-generator.t` remains a broad
generator-suite validation candidate; the shipped public sample, direct report
probes, semantic/check/HDL probes, and focused dynamic suite cover the bounded
public behavior in this slice.

## Rollback

Rollback is the `.280` implementation commit. Reverting it removes the public
mixed dynamic/static read burst-last PPIF sample, support-accounting entry,
generated mixed dynamic/static read `RID && RLAST` demux behavior, focused
coverage, docs, and facts, restoring `.280` as the active frontier.
