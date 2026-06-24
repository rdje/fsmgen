# AXI IAL2 Manager Multiple Mixed Dynamic/Static Read Response-Demux Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.299`

Date: 2026-06-23

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.299` ships generated bounded multiple
mixed dynamic/static read single-beat `RID` response-demux behavior for the
AXI manager capacity/status IAL2 object.

The support-accounted public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif`.
It uses the existing explicit `response-demux.read` opt-in with
`response-scope single-beat`, exactly one dynamic read transaction, and
exactly two concrete static read transactions.

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

- exactly one selected dynamic read transaction;
- exactly two selected concrete static read transactions;
- pairwise-distinct static concrete ID values;
- `response-scope single-beat`;
- no read `auto_id_lifecycle`;
- no `same_id_ordering.read`;
- onehot0 same-cycle mixed read requests across all selected read
  transactions; and
- dynamic capture excluding every selected static concrete ID.

Burst-last `RID && RLAST`, read-data, burst-length/runtime validation,
multi-beat output banks, two-dynamic plus one-static mixed read cardinality,
broader mixed cardinalities, dynamic same-ID queues, scoreboards, direct
backend behavior, backend-language variants, and VHDL remain future
exact-owner work. One-dynamic-plus-two-static single-beat same-cycle
release-and-recapture for this public sample is now documented in
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR](AXI_IAL2_MANAGER_MULTIPLE_MIXED_DYNAMIC_STATIC_READ_RECAPTURE_BEHAVIOR.md).
The one-dynamic-plus-three-static mixed read sample remains outside that owner
and keeps request-not-busy assertions with no `static_capture`.

## Generated Behavior

For the public multi-static mixed read sample, FSMGen emits dynamic
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

Generated response-demux rules match one raw accepted single-beat read
response:

```text
axi0_read_complete && axi0_r0_dynamic_busy_q && axi0_rid == axi0_r0_dynamic_id_q
axi0_read_complete && axi0_r1_static_busy_q  && axi0_rid == 4'd3
axi0_read_complete && axi0_r2_static_busy_q  && axi0_rid == 4'd5
```

Each matched rule pulses that transaction's generated completion output.
Generated release rules clear dynamic or static busy state from the matching
completion pulse.

## Report Contract

Schedule JSON reports the multiple mixed dynamic/static read contract with:

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
names. For the one-dynamic-plus-two-static public sample, generated assertions
now use dynamic/static idle-or-releasing request assertions because same-cycle
release-and-recapture is generated. The remaining assertion roles are
preserved:

- mixed read request onehot0;
- dynamic request does not use any selected static concrete ID;
- active dynamic ID is not any selected static concrete ID;
- raw response active match;
- pairwise raw response unique match across dynamic/static/static matches;
- dynamic completion-active release; and
- static completion-active release for every selected static transaction.

The one-dynamic-plus-three-static mixed read sample still uses the original
dynamic/static request-not-busy assertions and does not report
`static_capture`.

The existing one-dynamic plus one-static `.276` public sample keeps the
singular `bounded_mixed_dynamic_static_read_rid_demux_contract` mode,
singular `mixed_transactions` role values, and singular
`static_id_reservation` field unchanged.

## Public Sample And Checks

The public sample is support-accounted:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif
```

Useful focused checks:

```bash
env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif
env -u PERL5LIB ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_axi_multi_static_read_demux.sv ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif
```

The behavior is covered by the bounded focused dynamic test
`t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t` and by
support-accounting test `t/248-regression-corpus-accounting.t`.

## Validation

Closeout validation covered syntax checks for touched Perl modules/tests,
strict check JSON, semantic JSON, and `--verify-hdl` probes for the new public
sample, strict compatibility check for the existing one-static mixed read
sample, guarded support-accounting validation, and guarded filtered focused
dynamic validation for the multi-static mixed read case.

Initial guarded direct CLI probes were stopped when concurrent probe attempts
and then one sequential retry crossed the host-memory cutoff. After host
memory pressure dropped, sequential guarded strict check JSON, semantic JSON,
and `--verify-hdl` probes all passed at the standard 88% host cutoff.

## Rollback

Rollback is the `.299` implementation commit. Reverting it removes the public
multi-static mixed read PPIF sample, support-accounting entry, generated
multi-static mixed read demux behavior, focused coverage, docs, and facts,
restoring `.299` as the active frontier.
