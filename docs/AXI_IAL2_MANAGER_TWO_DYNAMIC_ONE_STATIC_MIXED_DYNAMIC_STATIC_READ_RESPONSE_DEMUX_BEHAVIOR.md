# AXI IAL2 Manager Two-Dynamic/One-Static Mixed Dynamic/Static Read Response-Demux Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.344`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.344` ships generated bounded
two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID`
response-demux behavior for the AXI manager capacity/status IAL2 object.

The support-accounted public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif`.
It uses explicit `response-demux.read` opt-in with exactly two dynamic read
transactions and exactly one concrete static read transaction.

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
    (id dynamic))
  (read r2
    (tag rd2)
    (request axi0_r2_request)
    (completion axi0_r2_complete)
    (id (value 3))))

(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope single-beat)
    (transaction-completion generated)))
```

The read ID family supplies positive-width `ARID`/`RID` signals:

```lisp
(id-families
  (write (width 4) (request-id axi0_awid) (response-id axi0_bid))
  (read  (width 4) (request-id axi0_arid) (response-id axi0_rid)))
```

The bounded slice requires:

- exactly two selected dynamic read transactions;
- exactly one selected concrete static read transaction;
- static concrete ID value `3`;
- `response-scope single-beat`;
- no read `auto_id_lifecycle`;
- no `same_id_ordering.read`;
- onehot0 same-cycle mixed read requests across all selected read
  transactions;
- dynamic capture excluding the selected static concrete ID; and
- active dynamic selected IDs remaining pairwise unique.

Read burst-last response-demux, read-data, burst-length/runtime validation,
multi-beat output banks, broader capped mixed sets, same-cycle widening,
release-and-recapture, dynamic same-ID queues, scoreboards, direct backend
behavior, backend-language variants, VHDL, profile aliases, queued/blocking
policy, and full-manager behavior remain future exact-owner work.

## Generated Behavior

For the public mixed two-dynamic/one-static read sample, FSMGen emits dynamic
selected-ID state for `r0` and `r1` and static busy state for `r2`:

```text
axi0_r0_dynamic_id_q
axi0_r0_dynamic_busy_q
axi0_r1_dynamic_id_q
axi0_r1_dynamic_busy_q
axi0_r2_static_busy_q
```

Each dynamic transaction captures `axi0_arid` at its admitted read request
only when that transaction is not busy, no selected sibling request is
admitted in the same cycle, no active sibling dynamic transaction already
holds the same selected ID, and `axi0_arid` is not `4'd3`.

The static transaction captures only its busy bit at its admitted read request
when it is not already busy and no selected dynamic request is admitted in the
same cycle.

Generated response-demux rules match one raw accepted single-beat read
response:

```text
axi0_read_complete && axi0_r0_dynamic_busy_q && axi0_rid == axi0_r0_dynamic_id_q
axi0_read_complete && axi0_r1_dynamic_busy_q && axi0_rid == axi0_r1_dynamic_id_q
axi0_read_complete && axi0_r2_static_busy_q  && axi0_rid == 4'd3
```

Each matched rule pulses that transaction's generated completion output.
Generated release rules clear only the matching transaction's busy state from
the matching completion pulse.

## Report Contract

Schedule JSON reports the existing list-shaped multiple mixed read mode:

```yaml
response_demux:
  mode: bounded_multi_mixed_dynamic_static_read_rid_demux_contract
  generated_behavior: true
  read:
    mode: bounded_multi_mixed_dynamic_static_read_rid_demux_contract
    response_event: axi0_read_complete
    response_event_role: raw_accepted_read_response
    response_scope: single_beat
    response_id_signal: axi0_rid
    response_id_direction: generated_input
    transaction_completion_source: generated_multi_mixed_dynamic_static_read_demux
    transaction_completion_semantics: matched_dynamic_or_static_concrete_id_single_beat
    dynamic_transactions: [r0, r1]
    static_transactions: [r2]
    mixed_transactions:
      dynamic: [r0, r1]
      static: [r2]
    static_id_reservations:
      - transaction: r2
        concrete_id: 3
        concrete_id_literal: 4'd3
        dynamic_capture_policy: dynamic_id_must_not_equal_static_concrete_id
    dynamic_capture:
      request_id_source: axi0_arid
      capture_event_source: admitted_dynamic_read_request
      ownership: multi_mixed_dynamic_static_unique_read_ids
      simultaneous_request_policy: onehot0_mixed_read_request
      same_id_conflict_policy: active_dynamic_ids_must_be_unique
      static_id_conflict_policy: static_concrete_ids_reserved
      static_id_exclusions: [4'd3]
```

Generated rules and completions are reported in transaction order:

```text
axi0_r0_response_demux
axi0_r1_response_demux
axi0_r2_response_demux

axi0_r0_complete
axi0_r1_complete
axi0_r2_complete
```

The existing `.276` one-dynamic plus one-static, `.299` one-dynamic plus
two-static, and `.322` one-dynamic plus three-static mixed read single-beat
report contracts remain unchanged.

## Assertion Contract

The generated assertion list records both policy axes:

```text
axi0_r0_dynamic_request_not_busy
axi0_r1_dynamic_request_not_busy
axi0_r2_static_request_not_busy
axi0_read_mixed_dynamic_static_request_onehot0
axi0_r0_dynamic_request_no_active_same_id
axi0_r1_dynamic_request_no_active_same_id
axi0_r0_r1_read_dynamic_active_id_unique
axi0_r0_r2_read_dynamic_request_not_static_id
axi0_r0_r2_read_dynamic_active_not_static_id
axi0_r1_r2_read_dynamic_request_not_static_id
axi0_r1_r2_read_dynamic_active_not_static_id
axi0_read_mixed_dynamic_static_response_active_match
axi0_r0_r1_read_mixed_dynamic_static_response_unique_match
axi0_r0_r2_read_mixed_dynamic_static_response_unique_match
axi0_r1_r2_read_mixed_dynamic_static_response_unique_match
axi0_r0_dynamic_completion_active
axi0_r1_dynamic_completion_active
axi0_r2_static_completion_active
```

The dynamic request assertions prevent request-time capture of a static ID
and request-time capture of an ID already held by another active dynamic
transaction. The pairwise dynamic active-ID assertion keeps both active
dynamic selected IDs unique after capture. Response active-match and
unique-match assertions prevent unmatched or ambiguous `RID` completions.

## Public Sample And Checks

The public sample is support-accounted:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif
```

Useful focused checks:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif
./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_multi_dynamic_mixed_read_verify.sv ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif
```

The behavior is covered by the bounded focused dynamic test
`t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t` and by
support-accounting test `t/248-regression-corpus-accounting.t`.

## Validation

Closeout validation covered syntax checks for touched Perl modules/tests,
guarded direct schedule/check/semantic/default-HDL/`--verify-hdl` probes for
the new public sample, guarded support-accounting validation, and preservation
probes for the all-dynamic read single-beat baseline, existing one-dynamic
mixed read single-beat behavior, the two-static mixed read single-beat shape,
the `.341` two-dynamic/one-static mixed write sibling, and representative
mixed read-data samples.

The bounded support-accounting test `t/248-regression-corpus-accounting.t`
passed 4536 tests. Several heavier focused `t/1438` and direct preservation
filters were stopped by the default RAM guard at the configured 88%
host-memory cutoff; they were not forced unbounded. The recorded caveats were
for the new focused `mixed_dynamic_static_read_demux_multi_dynamic` filter,
some existing multi-static read demux/read-data filters, and the `.341` write
sibling focused test. Narrow direct probes that completed confirmed the new
sample, all-dynamic read single-beat, one-dynamic/static read single-beat,
two-static read single-beat, the `.341` write sibling, and adjacent one- and
two-static read-data samples. Schedule JSON for the existing three-static
single-beat read demux shape still reports the preserved
`bounded_multi_mixed_dynamic_static_read_rid_demux_contract`.

## Rollback

Rollback is the `.344` implementation commit. Reverting it removes the public
two-dynamic/one-static mixed read PPIF sample, support-accounting entry,
generated mixed two-dynamic/one-static read demux behavior, focused coverage,
docs, and facts, restoring `.344` as the unimplemented active behavior owner
selected by `.343`.
