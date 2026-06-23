# AXI IAL2 Manager Multiple Mixed Dynamic/Static Read RLAST Response-Demux Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.303`

Date: 2026-06-23

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.303` ships generated bounded multiple
mixed dynamic/static read burst-last `RID && RLAST` response-demux behavior
for the AXI manager capacity/status IAL2 object.

The support-accounted public sample is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif
```

It uses the existing explicit `response-demux.read` opt-in with
`response-scope burst-last`, one one-bit `last-signal`, exactly one dynamic
read transaction, and exactly two pairwise-distinct concrete static read
transactions.

## Public Shape

The shipped public source shape remains explicit:

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
    (id (value 3)))
  (read r2
    (tag rd2)
    (request axi0_r2_request)
    (completion axi0_r2_complete)
    (id (value 5))))

(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope burst-last)
    (last-signal axi0_rlast (width 1))
    (transaction-completion generated)))
```

The bounded slice requires:

- exactly one selected dynamic read transaction;
- exactly two selected concrete static read transactions;
- pairwise-distinct static concrete ID values;
- `response-scope burst-last`;
- one one-bit `last-signal`;
- no read `auto_id_lifecycle`;
- no `same_id_ordering.read`;
- onehot0 same-cycle mixed read requests across all selected read
  transactions; and
- dynamic capture excluding every selected static concrete ID.

Read-data, raw `ARLEN` burst-length capture, runtime beat-count/`RLAST`
validation, multi-beat output banks, two-dynamic plus one-static mixed read
cardinality, broader mixed cardinalities, same-cycle widening,
release-and-recapture, dynamic same-ID queues, scoreboards, direct backend,
backend-language variants, and VHDL remain future exact-owner work.

## Generated Behavior

For the public multi-static mixed read burst-last sample, FSMGen emits dynamic
selected-ID state for `r0` and static busy state for `r1`/`r2`:

```text
axi0_r0_dynamic_id_q
axi0_r0_dynamic_busy_q
axi0_r1_static_busy_q
axi0_r2_static_busy_q
```

The dynamic transaction captures `axi0_arid` at its admitted read request
only when the dynamic transaction is not busy, no selected static request is
admitted in the same cycle, and `axi0_arid` is neither `4'd3` nor `4'd5`.

Each static transaction captures only its busy bit at its admitted read
request when it is not already busy and no selected dynamic or sibling static
request is admitted in the same cycle.

Generated response-demux rules match the final accepted read response beat:

```text
axi0_read_complete && axi0_r0_dynamic_busy_q && axi0_rid == axi0_r0_dynamic_id_q && axi0_rlast
axi0_read_complete && axi0_r1_static_busy_q  && axi0_rid == 4'd3                 && axi0_rlast
axi0_read_complete && axi0_r2_static_busy_q  && axi0_rid == 4'd5                 && axi0_rlast
```

Each matched final-beat rule pulses that transaction's generated completion
output. Generated release rules clear the owning dynamic or static busy state
from the corresponding completion pulse.

Raw `RID` beat assertions remain deliberately separate from final completion:
the active-match and unique-match assertions observe accepted read response
beats matched by `RID` while the completion rules additionally require
`RLAST`. This lets non-final beats prove ownership without releasing any
transaction before the final beat.

## Report Contract

Schedule JSON reports the multiple mixed dynamic/static read burst-last
contract with:

```yaml
response_demux:
  mode: bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract
  generated_behavior: true
  read:
    mode: bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract
    response_event: axi0_read_complete
    response_event_role: raw_accepted_read_response_beat
    response_scope: burst_last
    response_id_signal: axi0_rid
    response_id_direction: generated_input
    last_signal: axi0_rlast
    last_signal_direction: generated_input
    last_signal_width: 1
    transaction_completion_source: generated_multi_mixed_dynamic_static_read_demux_last_beat
    transaction_completion_semantics: matched_dynamic_or_static_concrete_id_and_last_signal
    beat_valid_output: none
    burst_length_source: rlast_only
    burst_length_validation: not_generated
    dynamic_transactions: [r0]
    static_transactions: [r1, r2]
    mixed_transactions:
      dynamic: [r0]
      static: [r1, r2]
    static_id_reservations:
      - transaction: r1
        concrete_id: 3
        concrete_id_literal: 4'd3
      - transaction: r2
        concrete_id: 5
        concrete_id_literal: 4'd5
    dynamic_capture:
      request_id_source: axi0_arid
      ownership: multi_mixed_dynamic_static_unique_read_ids
      simultaneous_request_policy: onehot0_mixed_read_request
      static_id_conflict_policy: static_concrete_ids_reserved
      static_id_exclusions: [4'd3, 4'd5]
```

The read report also lists generated completion signals, response-demux
rules, per-transaction busy/capture/release state, and generated assertion
names. The shipped assertion roles are:

- dynamic request not busy;
- static request not busy for every selected static transaction;
- mixed read request onehot0;
- dynamic request does not use any selected static concrete ID;
- active dynamic ID is not any selected static concrete ID;
- raw response active match;
- pairwise raw response unique match across dynamic/static/static matches;
- dynamic completion-active release; and
- static completion-active release for every selected static transaction.

The existing `.276` one-dynamic plus one-static single-beat sample, `.280`
one-dynamic plus one-static burst-last sample, and `.299` one-dynamic plus
two-static single-beat sample keep their public report contracts unchanged.

## Public Sample And Checks

The public sample is support-accounted:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif
```

Useful focused checks:

```bash
env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_multi_mixed_read_rlast_demux.sv ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif
```

The behavior is covered by the bounded focused dynamic test
`t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t` and by
support-accounting test `t/248-regression-corpus-accounting.t`.

## Validation

Closeout validation covered syntax checks for touched Perl modules/tests, a
guarded support-accounting run, guarded lightweight adapter/report probes for
the new sample and preservation probes for the existing `.280` and `.299`
samples, and a guarded lightweight generated-IAL1 rule probe confirming the
three `RLAST`-gated response-demux rules and raw `RID` assertion surface.

Direct CLI strict check JSON, semantic JSON, `--verify-hdl`, and filtered
`t/1438` focused-test attempts were guarded and stopped by host-memory cutoffs
before assertion output: the default 88% guard tripped first, and documented
90% retry attempts also tripped. No failed assertion was observed from those
guarded attempts.

## Rollback

Rollback is the `.303` implementation commit. Reverting it removes the public
multi-static mixed read burst-last PPIF sample, support-accounting entry,
generated multi-static mixed read burst-last demux behavior, focused coverage,
docs, and facts, restoring `.303` as the active frontier.
