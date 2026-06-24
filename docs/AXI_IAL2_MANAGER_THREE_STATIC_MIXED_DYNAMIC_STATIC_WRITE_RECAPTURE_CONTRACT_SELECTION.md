# AXI IAL2 Manager Three-Static Mixed Dynamic/Static Write Recapture Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.402`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.402` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.403`, direct implementation of
one-dynamic plus three-static mixed dynamic/static write `BID` same-cycle
release-and-recapture for the existing support-accounted public sample:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static3.ppif
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
    (id (value 3)))
  (write w2
    (tag wr2)
    (request axi0_w2_request)
    (completion axi0_w2_complete)
    (id (value 5)))
  (write w3
    (tag wr3)
    (request axi0_w3_request)
    (completion axi0_w3_complete)
    (id (value 7))))

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

No new public syntax is selected. The implementation owner remains bounded to
exactly one dynamic write transaction and exactly three pairwise-distinct
concrete static write transactions in the selected public sample.

## Selected Report Contract

`.403` must preserve:

- top-level and write `mode: bounded_multi_mixed_dynamic_static_write_bid_demux_contract`;
- `transaction_completion_source: generated_multi_mixed_dynamic_static_demux`;
- `transaction_completion_semantics: matched_dynamic_or_static_concrete_id`;
- public source path and support-accounting identity;
- `dynamic_transactions: [w0]`;
- `static_transactions: [w1, w2, w3]`;
- `mixed_transactions: { dynamic: [w0], static: [w1, w2, w3] }`;
- `static_id_reservations` for `w1` at concrete ID `3` / `4'd3`, `w2` at
  concrete ID `5` / `4'd5`, and `w3` at concrete ID `7` / `4'd7`, each with
  `dynamic_capture_policy: dynamic_id_must_not_equal_static_concrete_id`;
- generated demux rules `axi0_w0_response_demux`,
  `axi0_w1_response_demux`, `axi0_w2_response_demux`, and
  `axi0_w3_response_demux`; and
- generated completion signals `axi0_w0_complete`, `axi0_w1_complete`,
  `axi0_w2_complete`, and `axi0_w3_complete`.

The dynamic capture report keeps the existing list shape and adds recapture
fields to the covered transaction entry:

```yaml
dynamic_capture:
  request_id_source: axi0_awid
  capture_event_source: admitted_dynamic_write_request
  ownership: multi_mixed_dynamic_static_unique_write_ids
  simultaneous_request_policy: onehot0_mixed_write_request
  static_id_conflict_policy: static_concrete_ids_reserved
  static_id_exclusions: [4'd3, 4'd5, 4'd7]
  transactions:
    - transaction: w0
      selected_id_signal: axi0_w0_dynamic_id_q
      busy_signal: axi0_w0_dynamic_busy_q
      capture_rule: axi0_w0_dynamic_id_capture
      release_rule: axi0_w0_dynamic_id_release
      release_recapture_rule: axi0_w0_dynamic_id_release_recapture
      same_cycle_release_recapture_policy: mixed_dynamic_static_dynamic_write
      release_recapture_source: generated_multi_mixed_dynamic_static_demux_completion
      release_recapture_transaction: w0
```

The static concrete-ID busy lifecycle is reported through list-shaped
`response_demux.write.static_capture` entries ordered like
`static_transactions`:

```yaml
static_capture:
  - transaction: w1
    concrete_id: 3
    concrete_id_literal: 4'd3
    capture_event_source: admitted_static_write_request
    ownership: mixed_dynamic_static_concrete_write_id
    simultaneous_request_policy: onehot0_mixed_write_request
    busy_signal: axi0_w1_static_busy_q
    capture_rule: axi0_w1_static_busy_capture
    release_rule: axi0_w1_static_busy_release
    release_recapture_rule: axi0_w1_static_busy_release_recapture
    same_cycle_release_recapture_policy: mixed_dynamic_static_static_write
    release_recapture_source: generated_multi_mixed_dynamic_static_demux_completion
    release_recapture_transaction: w1
  - transaction: w2
    concrete_id: 5
    concrete_id_literal: 4'd5
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
  - transaction: w3
    concrete_id: 7
    concrete_id_literal: 4'd7
    capture_event_source: admitted_static_write_request
    ownership: mixed_dynamic_static_concrete_write_id
    simultaneous_request_policy: onehot0_mixed_write_request
    busy_signal: axi0_w3_static_busy_q
    capture_rule: axi0_w3_static_busy_capture
    release_rule: axi0_w3_static_busy_release
    release_recapture_rule: axi0_w3_static_busy_release_recapture
    same_cycle_release_recapture_policy: mixed_dynamic_static_static_write
    release_recapture_source: generated_multi_mixed_dynamic_static_demux_completion
    release_recapture_transaction: w3
```

## Selected Rule Contract

Dynamic release-only must remain disjoint from same-transaction same-cycle
request recapture:

```text
axi0_w0_dynamic_id_release: axi0_w0_complete && axi0_w0_dynamic_busy_q && !axi0_w0_request
```

Static release-only rules must do the same for each concrete static slot:

```text
axi0_w1_static_busy_release: axi0_w1_complete && axi0_w1_static_busy_q && !axi0_w1_request
axi0_w2_static_busy_release: axi0_w2_complete && axi0_w2_static_busy_q && !axi0_w2_request
axi0_w3_static_busy_release: axi0_w3_complete && axi0_w3_static_busy_q && !axi0_w3_request
```

Dynamic release-recapture must require:

- admitted `w0` dynamic write request;
- generated `w0` completion;
- active `w0` dynamic busy state;
- no admitted `w1`, `w2`, or `w3` static request in the same cycle; and
- `axi0_awid` not equal to `4'd3`, `4'd5`, or `4'd7`.

Each static release-recapture must require:

- admitted request for its own static transaction;
- generated completion for its own static transaction;
- active busy state for its own static transaction;
- no admitted `w0` dynamic request in the same cycle; and
- no admitted sibling static request in the same cycle.

The onehot0 mixed write request assertion remains the public arbitration
contract; no request-priority or queued recapture arbitration is selected.

## Selected Assertion Contract

The selected implementation replaces these request-not-busy assertions:

```text
axi0_w0_dynamic_request_not_busy
axi0_w1_static_request_not_busy
axi0_w2_static_request_not_busy
axi0_w3_static_request_not_busy
```

with:

```text
axi0_w0_dynamic_request_idle_or_releasing
axi0_w1_static_request_idle_or_releasing
axi0_w2_static_request_idle_or_releasing
axi0_w3_static_request_idle_or_releasing
```

The implementation must preserve:

- `axi0_write_mixed_dynamic_static_request_onehot0`;
- dynamic request/static-ID exclusion assertions for `4'd3`, `4'd5`, and
  `4'd7`;
- dynamic active/static-ID exclusion assertions for `4'd3`, `4'd5`, and
  `4'd7`;
- `axi0_write_mixed_dynamic_static_response_active_match`;
- all six pairwise unique-match assertions across `w0`, `w1`, `w2`, and
  `w3`; and
- completion-active assertions for `w0`, `w1`, `w2`, and `w3`.

## Validation Gates

`.403` should run:

- Perl syntax checks for touched generator/test files;
- guarded schedule JSON for the selected three-static sample;
- guarded preservation schedule JSON for the one-static, two-static, and
  two-dynamic-plus-one-static mixed write samples;
- guarded focused `t/1438` for `mixed_dynamic_static_write_demux_multi_static3`
  where host RAM permits;
- strict check JSON, semantic JSON, and SystemVerilog generation probes where
  host RAM permits;
- Knowledge Map generation/check;
- mdBook build;
- memory architecture check;
- diff whitespace check; and
- doctrine checks.

No RAM cutoff increase is selected.

## Deferred Boundaries

Two-dynamic-plus-one-static mixed write recapture, broader mixed read
recapture, read-data/raw-`ARLEN`/runtime/multi-beat consumers,
static-busy-only recapture outside selected mixed samples, request arbitration
beyond onehot0, dynamic same-ID queues, scoreboards, queued/blocking policy,
profile aliases, direct backend behavior, backend-language variants, VHDL,
and full AXI manager behavior remain later exact owners.

## Rollback

Rollback is this docs-only selector commit. Reverting it removes only the
`.403` implementation selection record, fact card, task-tree advancement,
live-doc updates, and resume pointer update; generated behavior remains at
`.400`.
