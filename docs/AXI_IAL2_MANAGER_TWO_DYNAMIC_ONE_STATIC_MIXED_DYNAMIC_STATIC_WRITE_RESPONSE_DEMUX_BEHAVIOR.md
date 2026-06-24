# AXI IAL2 Manager Two-Dynamic/One-Static Mixed Dynamic/Static Write Response-Demux Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.341`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.341` ships generated bounded
two-dynamic-plus-one-static mixed dynamic/static write `BID`
response-demux behavior for the AXI manager capacity/status IAL2 object.

The support-accounted public sample is
`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif`.
It uses the existing explicit `response-demux.write` opt-in with exactly two
dynamic write transactions and exactly one concrete static write transaction.

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
    (id dynamic))
  (write w2
    (tag wr2)
    (request axi0_w2_request)
    (completion axi0_w2_complete)
    (id (value 3))))

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

- exactly two selected dynamic write transactions;
- exactly one selected concrete static write transaction;
- static concrete ID value `3`;
- no write `auto_id_lifecycle`;
- no `same_id_ordering.write`;
- onehot0 same-cycle mixed write requests across all selected write
  transactions;
- dynamic capture excluding the selected static concrete ID; and
- active dynamic selected IDs remaining pairwise unique.

Read response-demux, read-data, burst-length/runtime validation, multi-beat
output banks, broader capped mixed sets, same-cycle widening,
release-and-recapture, dynamic same-ID queues, scoreboards, direct backend
behavior, backend-language variants, and VHDL remain future exact-owner work.

## Generated Behavior

For the public mixed two-dynamic/one-static write sample, FSMGen emits dynamic
selected-ID state for `w0` and `w1` and static busy state for `w2`:

```text
axi0_w0_dynamic_id_q
axi0_w0_dynamic_busy_q
axi0_w1_dynamic_id_q
axi0_w1_dynamic_busy_q
axi0_w2_static_busy_q
```

Each dynamic transaction captures `axi0_awid` at its admitted write request
only when that transaction is not busy, no selected sibling request is
admitted in the same cycle, no active sibling dynamic transaction already
holds the same selected ID, and `axi0_awid` is not `4'd3`.

The static transaction captures only its busy bit at its admitted write
request when it is not already busy and no selected dynamic request is
admitted in the same cycle.

Generated response-demux rules match one raw accepted write response:

```text
axi0_write_complete && axi0_w0_dynamic_busy_q && axi0_bid == axi0_w0_dynamic_id_q
axi0_write_complete && axi0_w1_dynamic_busy_q && axi0_bid == axi0_w1_dynamic_id_q
axi0_write_complete && axi0_w2_static_busy_q  && axi0_bid == 4'd3
```

Each matched rule pulses that transaction's generated completion output.
Generated release rules clear only the matching transaction's busy state from
the matching completion pulse.

## Report Contract

Schedule JSON reports the existing list-shaped multiple mixed write mode:

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
    dynamic_transactions: [w0, w1]
    static_transactions: [w2]
    mixed_transactions:
      dynamic: [w0, w1]
      static: [w2]
    static_id_reservations:
      - transaction: w2
        concrete_id: 3
        concrete_id_literal: 4'd3
        dynamic_capture_policy: dynamic_id_must_not_equal_static_concrete_id
    dynamic_capture:
      request_id_source: axi0_awid
      capture_event_source: admitted_dynamic_write_request
      ownership: multi_mixed_dynamic_static_unique_write_ids
      simultaneous_request_policy: onehot0_mixed_write_request
      same_id_conflict_policy: active_dynamic_ids_must_be_unique
      static_id_conflict_policy: static_concrete_ids_reserved
      static_id_exclusions: [4'd3]
```

Generated rules and completions are reported in transaction order:

```text
axi0_w0_response_demux
axi0_w1_response_demux
axi0_w2_response_demux

axi0_w0_complete
axi0_w1_complete
axi0_w2_complete
```

The existing `.272` one-dynamic plus one-static, `.295` one-dynamic plus
two-static, and `.318` one-dynamic plus three-static mixed write report
contracts remain unchanged.

## Assertion Contract

The generated assertion list records both policy axes:

```text
axi0_w0_dynamic_request_not_busy
axi0_w1_dynamic_request_not_busy
axi0_w2_static_request_not_busy
axi0_write_mixed_dynamic_static_request_onehot0
axi0_w0_dynamic_request_no_active_same_id
axi0_w1_dynamic_request_no_active_same_id
axi0_w0_w1_write_dynamic_active_id_unique
axi0_w0_w2_write_dynamic_request_not_static_id
axi0_w0_w2_write_dynamic_active_not_static_id
axi0_w1_w2_write_dynamic_request_not_static_id
axi0_w1_w2_write_dynamic_active_not_static_id
axi0_write_mixed_dynamic_static_response_active_match
axi0_w0_w1_write_mixed_dynamic_static_response_unique_match
axi0_w0_w2_write_mixed_dynamic_static_response_unique_match
axi0_w1_w2_write_mixed_dynamic_static_response_unique_match
axi0_w0_dynamic_completion_active
axi0_w1_dynamic_completion_active
axi0_w2_static_completion_active
```

The dynamic request assertions prevent request-time capture of a static ID
and request-time capture of an ID already held by another active dynamic
transaction. The pairwise dynamic active-ID assertion keeps both active
dynamic selected IDs unique after capture. Response active-match and
unique-match assertions prevent unmatched or ambiguous `BID` completions.

## Public Sample And Checks

The public sample is support-accounted:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif
```

Useful focused checks:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif
./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_multi_dynamic_mixed_write_verify.sv ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif
```

The behavior is covered by the bounded focused dynamic test
`t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t` and by
support-accounting test `t/248-regression-corpus-accounting.t`.

## Validation

Closeout validation covered syntax checks for touched Perl modules/tests,
filtered focused `t/1438` coverage for the new behavior, guarded direct
schedule/check/semantic/default-HDL/`--verify-hdl` probes for the new public
sample, guarded support-accounting validation, and preservation filters for
the all-dynamic write baseline, existing mixed write widths, multiple mixed
read demux, and representative multiple mixed read-data samples.

One broad multi-static read-data preservation filter was stopped by the
default RAM guard when host memory reached the configured 88% cutoff. The
check was narrowed to individual public sample paths instead of raising the
cutoff; both representative single-beat and last-beat read-data samples
passed.

## Rollback

Rollback is the `.341` implementation commit. Reverting it removes the public
two-dynamic/one-static mixed write PPIF sample, support-accounting entry,
generated mixed two-dynamic/one-static write demux behavior, focused
coverage, docs, and facts, restoring `.341` as the active frontier.
