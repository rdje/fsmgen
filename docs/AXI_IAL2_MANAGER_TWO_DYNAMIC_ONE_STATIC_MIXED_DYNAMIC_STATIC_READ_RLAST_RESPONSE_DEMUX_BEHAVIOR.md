# AXI IAL2 Manager Two-Dynamic/One-Static Mixed Dynamic/Static Read RLAST Response-Demux Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.347`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.347` ships generated bounded
two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID`/`RLAST`
response-demux behavior for the AXI manager capacity/status IAL2 object.

The support-accounted public sample is
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last.ppif`.
It uses exactly two dynamic read transactions, `r0` and `r1`, plus exactly one
concrete static read transaction, `r2` at ID `3`.

## Public Shape

The public source shape is explicit:

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
    (response-scope burst-last)
    (last-signal axi0_rlast (width 1))
    (transaction-completion generated)))
```

The bounded slice requires a positive-width read ID family, no read
`auto_id_lifecycle`, no `same_id_ordering.read`, onehot0 selected mixed read
requests, dynamic capture exclusion for static literal `4'd3`, and pairwise
active dynamic selected-ID uniqueness.

Read-data capture over this two-dynamic/one-static burst-last demux,
burst-length/runtime validation, multi-beat output banks, broader capped mixed
sets, same-cycle widening, release-and-recapture, dynamic same-ID queues,
scoreboards, direct backend behavior, backend-language variants, VHDL, profile
aliases, queued/blocking policy, and full-manager behavior remain future
exact-owner work.

## Generated Behavior

FSMGen emits selected-ID and busy state for both dynamic reads and busy state
for the static read:

```text
axi0_r0_dynamic_id_q
axi0_r0_dynamic_busy_q
axi0_r1_dynamic_id_q
axi0_r1_dynamic_busy_q
axi0_r2_static_busy_q
```

Each dynamic request captures `axi0_arid` only when the transaction is not busy,
no selected sibling request is admitted in the same cycle, no active sibling
dynamic transaction already holds the same selected ID, and `axi0_arid` is not
`4'd3`.

Raw response ownership assertions match by `RID` alone, independent of
`RLAST`. Generated completion rules pulse only on the final matching beat:

```text
axi0_read_complete && axi0_r0_dynamic_busy_q && axi0_rid == axi0_r0_dynamic_id_q && axi0_rlast
axi0_read_complete && axi0_r1_dynamic_busy_q && axi0_rid == axi0_r1_dynamic_id_q && axi0_rlast
axi0_read_complete && axi0_r2_static_busy_q  && axi0_rid == 4'd3                 && axi0_rlast
```

## Report Contract

Schedule JSON reports:

```yaml
response_demux:
  mode: bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract
  generated_behavior: true
  read:
    mode: bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract
    response_event_role: raw_accepted_read_response_beat
    response_scope: burst_last
    last_signal: axi0_rlast
    last_signal_width: 1
    transaction_completion_source: generated_multi_mixed_dynamic_static_read_demux_last_beat
    transaction_completion_semantics: matched_dynamic_or_static_concrete_id_and_last_signal
    beat_valid_output: none
    burst_length_source: rlast_only
    burst_length_validation: not_generated
    dynamic_transactions: [r0, r1]
    static_transactions: [r2]
    mixed_transactions:
      dynamic: [r0, r1]
      static: [r2]
    static_id_reservations:
      - transaction: r2
        concrete_id: 3
        concrete_id_literal: 4'd3
    dynamic_capture:
      request_id_source: axi0_arid
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

The existing one-dynamic plus one/two/three-static burst-last read report
contracts and the `.344` two-dynamic/one-static single-beat read report
contract remain unchanged.

## Validation

Closeout validation passed syntax checks for touched Perl modules/tests,
RAM-guarded direct schedule/check/semantic/default-HDL/`--verify-hdl` probes
for the new public sample, and `t/248-regression-corpus-accounting.t`
with 4548 tests.

The exact focused `t/1438` filter hit the default 88% host-memory cutoff when
the CLI JSON subtest was included. The same focused behavior passed under the
RAM guard with `FSMGEN_DYNAMIC_SKIP_CLI_JSON=1`. Direct strict preservation
checks passed for the `.344` two-dynamic/one-static single-beat sample, the
multiple all-dynamic read burst-last sample, and the two-static mixed read
burst-last sample. The three-static mixed read burst-last preservation probe hit
the default 88% host-memory cutoff and was not forced unbounded.

## Rollback

Rollback is the `.347` implementation commit. Reverting it removes the public
two-dynamic/one-static mixed read burst-last PPIF sample, support-accounting
entry, generated mixed two-dynamic/one-static read RLAST demux behavior,
focused coverage, docs, and facts, restoring `.347` as the unimplemented active
behavior owner selected by `.346`.
