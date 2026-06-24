# AXI IAL2 Manager Two-Dynamic/One-Static Mixed Dynamic/Static Write Recapture Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.406`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.406` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.407`, direct implementation of
two-dynamic-plus-one-static mixed dynamic/static write `BID` same-cycle
release-and-recapture for the existing support-accounted public sample:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif
```

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, or runtime behavior.

## Existing Public Shape

The selected implementation must preserve the existing source syntax:

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

The write ID family remains:

```lisp
(id-families
  (write (width 4) (request-id axi0_awid) (response-id axi0_bid)))
```

No new public source syntax is selected. The implementation owner is bounded
to exactly two dynamic write transactions and exactly one concrete static
write transaction in the selected public sample.

## Selected Report Contract

`.407` must preserve:

- top-level and write `mode: bounded_multi_mixed_dynamic_static_write_bid_demux_contract`;
- `transaction_completion_source: generated_multi_mixed_dynamic_static_demux`;
- `transaction_completion_semantics: matched_dynamic_or_static_concrete_id`;
- public source path and support-accounting identity;
- `dynamic_transactions: [w0, w1]`;
- `static_transactions: [w2]`;
- `mixed_transactions: { dynamic: [w0, w1], static: [w2] }`;
- `static_id_reservations` for `w2` at concrete ID `3` / `4'd3` with
  `dynamic_capture_policy: dynamic_id_must_not_equal_static_concrete_id`;
- generated demux rules `axi0_w0_response_demux`,
  `axi0_w1_response_demux`, and `axi0_w2_response_demux`; and
- generated completion signals `axi0_w0_complete`, `axi0_w1_complete`, and
  `axi0_w2_complete`.

The dynamic capture report keeps the existing transaction-list shape and adds
recapture fields to both covered dynamic transaction entries. The dynamic
policy is a new combined policy string:

```text
mixed_dynamic_static_multi_active_dynamic_write
```

That string is selected because the rule must carry both multi-active dynamic
same-ID guards and mixed dynamic/static concrete-ID guards.

```yaml
dynamic_capture:
  request_id_source: axi0_awid
  capture_event_source: admitted_dynamic_write_request
  ownership: multi_mixed_dynamic_static_unique_write_ids
  simultaneous_request_policy: onehot0_mixed_write_request
  same_id_conflict_policy: active_dynamic_ids_must_be_unique
  static_id_conflict_policy: static_concrete_ids_reserved
  static_id_exclusions: [4'd3]
  transactions:
    - transaction: w0
      selected_id_signal: axi0_w0_dynamic_id_q
      busy_signal: axi0_w0_dynamic_busy_q
      capture_rule: axi0_w0_dynamic_id_capture
      release_rule: axi0_w0_dynamic_id_release
      release_recapture_rule: axi0_w0_dynamic_id_release_recapture
      same_cycle_release_recapture_policy: mixed_dynamic_static_multi_active_dynamic_write
      release_recapture_source: generated_multi_mixed_dynamic_static_demux_completion
      release_recapture_transaction: w0
    - transaction: w1
      selected_id_signal: axi0_w1_dynamic_id_q
      busy_signal: axi0_w1_dynamic_busy_q
      capture_rule: axi0_w1_dynamic_id_capture
      release_rule: axi0_w1_dynamic_id_release
      release_recapture_rule: axi0_w1_dynamic_id_release_recapture
      same_cycle_release_recapture_policy: mixed_dynamic_static_multi_active_dynamic_write
      release_recapture_source: generated_multi_mixed_dynamic_static_demux_completion
      release_recapture_transaction: w1
```

The static concrete-ID busy lifecycle is reported through list-shaped
`response_demux.write.static_capture` in this multi-mixed mode, even though
there is only one static transaction:

```yaml
static_capture:
  - transaction: w2
    concrete_id: 3
    concrete_id_literal: 4'd3
    capture_event_source: admitted_static_write_request
    ownership: mixed_dynamic_static_concrete_write_id
    simultaneous_request_policy: onehot0_mixed_write_request
    busy_signal: axi0_w2_static_busy_q
    capture_rule: axi0_w2_static_busy_capture
    release_rule: axi0_w2_static_busy_release
    release_recapture_rule: axi0_w2_static_busy_release_recapture
    same_cycle_release_recapture_policy: mixed_dynamic_static_static_write
    release_recapture_source: generated_multi_mixed_dynamic_static_demux_completion
    release_recapture_transaction: w2
```

The one-dynamic/one-static mixed write recapture report keeps its existing
singular `static_capture` shape. This selector only chooses list-shaped static
capture for the multi-mixed two-dynamic/one-static mode.

## Selected Rule Contract

Dynamic release-only must be disjoint from same-transaction same-cycle request
recapture:

```text
axi0_w0_dynamic_id_release: axi0_w0_complete && axi0_w0_dynamic_busy_q && !axi0_w0_request
axi0_w1_dynamic_id_release: axi0_w1_complete && axi0_w1_dynamic_busy_q && !axi0_w1_request
```

Static release-only must do the same for the concrete static slot:

```text
axi0_w2_static_busy_release: axi0_w2_complete && axi0_w2_static_busy_q && !axi0_w2_request
```

Each dynamic release-recapture rule must require:

- admitted request for its own dynamic transaction;
- generated completion for its own dynamic transaction;
- active busy state for its own dynamic transaction;
- no admitted sibling dynamic request in the same cycle;
- no active sibling dynamic transaction already holding the new `AWID`;
- no admitted `w2` static request in the same cycle; and
- `axi0_awid != 4'd3`.

The selected dynamic release-recapture rules are:

```text
axi0_w0_dynamic_id_release_recapture
axi0_w1_dynamic_id_release_recapture
```

The `w2` static release-recapture rule must require:

- admitted `w2` request;
- generated `w2` completion;
- active `w2` busy state;
- no admitted `w0` dynamic request in the same cycle; and
- no admitted `w1` dynamic request in the same cycle.

The selected static release-recapture rule is:

```text
axi0_w2_static_busy_release_recapture
```

The onehot0 mixed write request assertion remains the public arbitration
contract; no request-priority, queued recapture arbitration, same-ID queue, or
scoreboard behavior is selected.

## Selected Assertion Contract

The selected implementation replaces these request-not-busy assertions:

```text
axi0_w0_dynamic_request_not_busy
axi0_w1_dynamic_request_not_busy
axi0_w2_static_request_not_busy
```

with:

```text
axi0_w0_dynamic_request_idle_or_releasing
axi0_w1_dynamic_request_idle_or_releasing
axi0_w2_static_request_idle_or_releasing
```

The implementation must preserve:

- `axi0_write_mixed_dynamic_static_request_onehot0`;
- `axi0_w0_dynamic_request_no_active_same_id`;
- `axi0_w1_dynamic_request_no_active_same_id`;
- `axi0_w0_w1_write_dynamic_active_id_unique`;
- `axi0_w0_w2_write_dynamic_request_not_static_id`;
- `axi0_w0_w2_write_dynamic_active_not_static_id`;
- `axi0_w1_w2_write_dynamic_request_not_static_id`;
- `axi0_w1_w2_write_dynamic_active_not_static_id`;
- `axi0_write_mixed_dynamic_static_response_active_match`;
- `axi0_w0_w1_write_mixed_dynamic_static_response_unique_match`;
- `axi0_w0_w2_write_mixed_dynamic_static_response_unique_match`;
- `axi0_w1_w2_write_mixed_dynamic_static_response_unique_match`; and
- completion-active assertions for `w0`, `w1`, and `w2`.

## Validation Gates

`.407` should run:

- Perl syntax checks for touched generator/test files;
- guarded schedule JSON for the selected two-dynamic/one-static sample where
  host RAM permits;
- guarded strict check JSON, semantic JSON, and SystemVerilog generation for
  the selected sample where host RAM permits;
- guarded focused `t/1438` for
  `mixed_dynamic_static_write_demux_multi_dynamic` where host RAM permits;
- guarded preservation probes for the all-dynamic multiple write recapture
  sample and the one-static, two-static, and three-static mixed write
  recapture samples where host RAM permits;
- Knowledge Map generation/check;
- mdBook build;
- memory architecture check;
- diff whitespace check; and
- doctrine checks.

No RAM cutoff increase is selected.

## Deferred Boundaries

Broader mixed read recapture remains deferred behind raw non-final `RID`
beats, final-only `RLAST` release sources, read-data, raw-`ARLEN`, runtime
beat-count/`RLAST` validation, and multi-beat output-bank consumers.

Static-busy-only recapture outside selected mixed samples, helper/report
cleanup outside the selected implementation, request arbitration beyond
onehot0, dynamic same-ID queues, scoreboards, queued/blocking policy, profile
aliases, direct backend behavior, backend-language variants, VHDL, and full
AXI manager behavior remain later exact owners.

## Rollback

Rollback is this docs-only selector commit. Reverting it removes only the
`.407` implementation selection record, fact card, task-tree advancement,
live-doc updates, and resume pointer update; generated behavior remains at
`.403` for three-static recapture and at `.341` for the two-dynamic/one-static
response-demux shape.
