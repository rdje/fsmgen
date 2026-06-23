# AXI IAL2 Manager Multiple Mixed Dynamic/Static Write Response-Demux Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.295`

Date: 2026-06-23

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.295` ships generated bounded multiple
mixed dynamic/static write `BID` response-demux behavior for the AXI manager
capacity/status IAL2 object.

The support-accounted public sample is
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static.ppif`.
It uses the existing explicit `response-demux.write` opt-in with exactly one
dynamic write transaction and exactly two concrete static write transactions.

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
    (id (value 3)))
  (write w2
    (tag wr2)
    (request axi0_w2_request)
    (completion axi0_w2_complete)
    (id (value 5))))

(response-demux
  (write
    (response-event axi0_write_complete)
    (transaction-completion generated)))
```

The write ID family supplies positive-width `AWID`/`BID` signals:

```lisp
(id-families
  (write (width 4) (request-id axi0_awid) (response-id axi0_bid))
  (read  (width 4) (request-id axi0_arid) (response-id axi0_rid)))
```

The bounded slice requires:

- exactly one selected dynamic write transaction;
- exactly two selected concrete static write transactions;
- pairwise-distinct static concrete ID values;
- no write `auto_id_lifecycle`;
- no `same_id_ordering.write`;
- onehot0 same-cycle mixed write requests across all selected write
  transactions; and
- dynamic capture excluding every selected static concrete ID.

Two-dynamic plus one-static mixed writes, broader mixed cardinalities, read
multiple mixed demux, read-data, burst-length/runtime validation, multi-beat
output banks, same-cycle widening, release-and-recapture, dynamic same-ID
queues, scoreboards, direct backend behavior, backend-language variants, and
VHDL remain future exact-owner work.

## Generated Behavior

For the public multi-static mixed write sample, FSMGen emits dynamic
selected-ID state for `w0` and static busy state for `w1`/`w2`:

```text
axi0_w0_dynamic_id_q
axi0_w0_dynamic_busy_q
axi0_w1_static_busy_q
axi0_w2_static_busy_q
```

The dynamic transaction captures `axi0_awid` at its admitted write request
only when the dynamic transaction is not busy, no selected static request is
admitted in the same cycle, and `axi0_awid` is neither `4'd3` nor `4'd5`.

Each static transaction captures only its busy bit at its admitted write
request when it is not already busy and no selected dynamic or sibling static
request is admitted in the same cycle.

Generated response-demux rules match one raw accepted write response:

```text
axi0_write_complete && axi0_w0_dynamic_busy_q && axi0_bid == axi0_w0_dynamic_id_q
axi0_write_complete && axi0_w1_static_busy_q  && axi0_bid == 4'd3
axi0_write_complete && axi0_w2_static_busy_q  && axi0_bid == 4'd5
```

Each matched rule pulses that transaction's generated completion output.
Generated release rules clear dynamic or static busy state from the matching
completion pulse.

## Report Contract

Schedule JSON reports the multiple mixed dynamic/static write contract with:

```yaml
response_demux:
  mode: bounded_multi_mixed_dynamic_static_write_bid_demux_contract
  generated_behavior: true
  write:
    mode: bounded_multi_mixed_dynamic_static_write_bid_demux_contract
    response_event: axi0_write_complete
    response_event_role: raw_accepted_write_response
    response_id_signal: axi0_bid
    response_id_direction: generated_input
    transaction_completion_source: generated_multi_mixed_dynamic_static_demux
    transaction_completion_semantics: matched_dynamic_or_static_concrete_id
    dynamic_transactions: [w0]
    static_transactions: [w1, w2]
    mixed_transactions:
      dynamic: [w0]
      static: [w1, w2]
    static_id_reservations:
      - transaction: w1
        concrete_id: 3
        concrete_id_literal: 4'd3
      - transaction: w2
        concrete_id: 5
        concrete_id_literal: 4'd5
    dynamic_capture:
      request_id_source: axi0_awid
      ownership: multi_mixed_dynamic_static_unique_write_ids
      simultaneous_request_policy: onehot0_mixed_write_request
      static_id_conflict_policy: static_concrete_ids_reserved
      static_id_exclusions: [4'd3, 4'd5]
```

The existing one-dynamic plus one-static `.272` public sample keeps the
singular `bounded_mixed_dynamic_static_write_bid_demux_contract` mode and
singular `static_id_reservation` field unchanged.

## Public Sample And Checks

The public sample is support-accounted:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static.ppif
```

Useful focused checks:

```bash
env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_axi_multi_static_write_demux.sv ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static.ppif
```

The behavior is covered by the bounded focused dynamic test
`t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t` and by
support-accounting test `t/248-regression-corpus-accounting.t`.

## Validation

Closeout validation covered syntax checks for touched Perl modules/tests,
strict check JSON, semantic JSON, and `--verify-hdl` probes for the new public
sample, strict compatibility check for the existing one-static mixed write
sample, guarded support-accounting validation, and guarded filtered focused
dynamic validation for the mixed write cases.

The full dynamic focused test was attempted under the default 88% host-memory
RAM guard and again with a documented 90% host cutoff, but the host crossed
the guard before any assertion failure output. The behavior was therefore
validated through separate guarded strict/semantic/HDL probes plus filtered
adapter/report/HDL focused test runs that keep the same test harness but avoid
the memory-heavy all-case CLI subtest in this interactive environment.

## Rollback

Rollback is the `.295` implementation commit. Reverting it removes the public
multi-static mixed write PPIF sample, support-accounting entry, generated
multi-static mixed write demux behavior, focused coverage, docs, and facts,
restoring `.295` as the active frontier.
