# AXI IAL2 Manager Two-Dynamic/One-Static Mixed Dynamic/Static Write Response-Demux Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.340`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.340` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.341`, direct generated behavior for
bounded two-dynamic-plus-one-static mixed dynamic/static write `BID`
response-demux.

The selected public contract reuses the existing explicit
`response-demux.write` syntax with generated transaction completions. No new
parser form, source keyword, report mode name, support-accounting class, or
behavioral shortcut is selected in `.340`.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Public Source Shape

The `.341` implementation owner should add one support-accounted public PPIF
sample:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif
```

The sample is intentionally minimal and write-family only:

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

The selected boundary requires:

- a positive-width `id-families.write` entry with one request ID source such
  as `axi0_awid` and one response ID signal such as `axi0_bid`;
- exactly two selected dynamic write transactions named `w0` and `w1`;
- exactly one selected concrete static write transaction named `w2`;
- concrete static write ID `3`, reported as `4'd3` for the existing four-bit
  AXI manager samples;
- distinct request and generated completion events for all three
  transactions;
- `response-demux.write.transaction-completion` set to `generated`;
- no write `auto_id_lifecycle` metadata;
- no `same_id_ordering.write` policy; and
- no read response-demux, read-data, burst-length/runtime validation,
  multi-beat output-bank, queue, scoreboard, direct backend, or VHDL behavior.

## Report Contract

`.341` should reuse the existing list-shaped multi-mixed write mode:

```text
bounded_multi_mixed_dynamic_static_write_bid_demux_contract
```

Cardinality is represented through report lists, not a new mode name:

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
      transactions:
        - transaction: w0
          selected_id_signal: axi0_w0_dynamic_id_q
          busy_signal: axi0_w0_dynamic_busy_q
          capture_rule: axi0_w0_dynamic_id_capture
          release_rule: axi0_w0_dynamic_id_release
        - transaction: w1
          selected_id_signal: axi0_w1_dynamic_id_q
          busy_signal: axi0_w1_dynamic_busy_q
          capture_rule: axi0_w1_dynamic_id_capture
          release_rule: axi0_w1_dynamic_id_release
```

The report must also list generated rules and completions in transaction
order:

```text
generated_rules = [
  axi0_w0_response_demux,
  axi0_w1_response_demux,
  axi0_w2_response_demux,
]

generated_completion_signals = [
  axi0_w0_complete,
  axi0_w1_complete,
  axi0_w2_complete,
]
```

The existing one-dynamic plus one-static `.272`, one-dynamic plus two-static
`.295`, and one-dynamic plus three-static `.318` report contracts must remain
unchanged.

## Generated Behavior Contract

`.341` should emit selected-ID and busy state for both dynamic write
transactions and busy state for the concrete static write transaction:

```text
axi0_w0_dynamic_id_q
axi0_w0_dynamic_busy_q
axi0_w1_dynamic_id_q
axi0_w1_dynamic_busy_q
axi0_w2_static_busy_q
```

Each dynamic capture guard is valid only when:

- that dynamic transaction's admitted write request is present;
- that dynamic transaction is not already busy;
- no sibling selected write transaction request is admitted in the same cycle;
- no active sibling dynamic write transaction holds the same selected ID as
  the current `axi0_awid`; and
- the current `axi0_awid` is not equal to the selected static concrete ID
  `4'd3`.

The static busy capture guard is valid only when:

- the static transaction's admitted write request is present;
- the static transaction is not already busy; and
- no selected dynamic write request is admitted in the same cycle.

Generated response-demux rules match one raw accepted write response:

```text
axi0_write_complete && axi0_w0_dynamic_busy_q && axi0_bid == axi0_w0_dynamic_id_q
axi0_write_complete && axi0_w1_dynamic_busy_q && axi0_bid == axi0_w1_dynamic_id_q
axi0_write_complete && axi0_w2_static_busy_q  && axi0_bid == 4'd3
```

Each matched rule pulses that transaction's generated completion output and
the release rule clears only that transaction's busy state. Same-cycle
release-and-recapture remains unselected.

## Assertion Contract

The generated assertion list should make both policy axes machine-readable:
dynamic-vs-dynamic active selected-ID uniqueness and dynamic-vs-static
concrete-ID exclusion. Expected local-helper names are:

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

The implementation may route these through a combined helper or compose the
existing all-dynamic and mixed helpers, but schedule JSON and focused tests
must expose these roles.

## Support Accounting

The support-accounting identity for `.341` is:

```text
intent.ppif_axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic
```

The focused coverage key is:

```text
ial2_ppif_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic_pipeline_cli
```

The focused behavior label is:

```text
mixed_dynamic_static_write_demux_multi_dynamic
```

## Diagnostics

`.341` should fail closed with explicit diagnostics for:

- mixed write response-demux shapes outside exactly two dynamic plus one
  concrete static write transaction in this selected boundary;
- duplicate, missing, malformed, or out-of-range static concrete write IDs;
- missing positive-width write ID-family metadata;
- dynamic/static mixed write response-demux combined with write
  `auto_id_lifecycle`;
- dynamic/static mixed write response-demux combined with
  `same_id_ordering.write`;
- missing generated transaction-completion ownership;
- generated completion names colliding with the raw response event;
- read-side or read-data attempts for the two-dynamic-plus-one-static shape;
  and
- broader capped mixed sets until a later exact owner selects them.

## Validation Gates

`.340` is selector-only, so documentation and continuity gates are
sufficient:

```bash
knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

The `.341` behavior owner should run:

- syntax checks for touched Perl modules and focused tests;
- filtered focused `t/1438` coverage for
  `mixed_dynamic_static_write_demux_multi_dynamic`;
- `t/248-regression-corpus-accounting.t` after adding the public sample;
- direct schedule/check/semantic/default-HDL/`--verify-hdl` probes for the new
  sample under the RAM guard where host and descendant memory permit;
- preservation filters for `.247`, `.272`, `.295`, `.318`, and adjacent
  read/read-data samples;
- mdBook build;
- Knowledge Map generation/check;
- memory architecture check;
- diff whitespace check; and
- doctrine checks.

## Explicit Residue

Read single-beat response-demux, read burst-last response-demux, read-data,
burst-length/runtime validation, multi-beat output banks, broader capped
mixed dynamic/static sets, same-cycle request widening,
release-and-recapture, dynamic same-ID queues, scoreboards, direct backend
behavior, backend-language variants, profile aliases, queued/blocking policy,
full-manager behavior, and VHDL remain separate exact owners.

## Rollback

Rollback is documentation-only for `.340`: remove this contract note and fact
card, restore `.340` to pending, and restore README, ROADMAP_V2, mdBook, task
tree, Memory, and Knowledge Map to the post-`.339` state.
