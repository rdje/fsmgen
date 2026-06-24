# AXI IAL2 Manager Two-Dynamic/One-Static Mixed Dynamic/Static Read Response-Demux Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.343`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.343` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.344`, direct generated behavior for
bounded two-dynamic-plus-one-static mixed dynamic/static read single-beat
`RID` response-demux.

The selected public contract reuses the existing explicit
`response-demux.read` syntax with `response-scope single-beat` and generated
transaction completions. No new parser form, source keyword, report mode name,
support-accounting class, or behavioral shortcut is selected in `.343`.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Public Source Shape

The `.344` implementation owner should add one support-accounted public PPIF
sample:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif
```

The sample is intentionally minimal and read-family only:

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

The selected boundary requires:

- a positive-width `id-families.read` entry with one request ID source such
  as `axi0_arid` and one response ID signal such as `axi0_rid`;
- exactly two selected dynamic read transactions named `r0` and `r1`;
- exactly one selected concrete static read transaction named `r2`;
- concrete static read ID `3`, reported as `4'd3` for the existing four-bit
  AXI manager samples;
- distinct request and generated completion events for all three
  transactions;
- `response-demux.read.response-scope` set to `single-beat`;
- `response-demux.read.transaction-completion` set to `generated`;
- no read `auto_id_lifecycle` metadata;
- no `same_id_ordering.read` policy;
- no `last-signal` metadata in this first single-beat boundary; and
- no read-data, burst-length/runtime validation, multi-beat output-bank,
  burst-last, queue, scoreboard, direct backend, or VHDL behavior.

## Report Contract

`.344` should reuse the existing list-shaped multi-mixed read single-beat
mode:

```text
bounded_multi_mixed_dynamic_static_read_rid_demux_contract
```

Cardinality is represented through report lists, not a new mode name:

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
      transactions:
        - transaction: r0
          selected_id_signal: axi0_r0_dynamic_id_q
          busy_signal: axi0_r0_dynamic_busy_q
          capture_rule: axi0_r0_dynamic_id_capture
          release_rule: axi0_r0_dynamic_id_release
        - transaction: r1
          selected_id_signal: axi0_r1_dynamic_id_q
          busy_signal: axi0_r1_dynamic_busy_q
          capture_rule: axi0_r1_dynamic_id_capture
          release_rule: axi0_r1_dynamic_id_release
```

The report must also list generated rules and completions in transaction
order:

```text
generated_rules = [
  axi0_r0_response_demux,
  axi0_r1_response_demux,
  axi0_r2_response_demux,
]

generated_completion_signals = [
  axi0_r0_complete,
  axi0_r1_complete,
  axi0_r2_complete,
]
```

The existing `.276` one-dynamic plus one-static, `.299` one-dynamic plus
two-static, and `.322` one-dynamic plus three-static read report contracts
must remain unchanged.

## Generated Behavior Contract

`.344` should emit selected-ID and busy state for both dynamic read
transactions and busy state for the concrete static read transaction:

```text
axi0_r0_dynamic_id_q
axi0_r0_dynamic_busy_q
axi0_r1_dynamic_id_q
axi0_r1_dynamic_busy_q
axi0_r2_static_busy_q
```

Each dynamic capture guard is valid only when:

- that dynamic transaction's admitted read request is present;
- that dynamic transaction is not already busy;
- no sibling selected read transaction request is admitted in the same cycle;
- no active sibling dynamic read transaction holds the same selected ID as
  the current `axi0_arid`; and
- the current `axi0_arid` is not equal to the selected static concrete ID
  `4'd3`.

The static busy capture guard is valid only when:

- the static transaction's admitted read request is present;
- the static transaction is not already busy; and
- no selected dynamic read request is admitted in the same cycle.

Generated response-demux rules match one raw accepted single-beat read
response:

```text
axi0_read_complete && axi0_r0_dynamic_busy_q && axi0_rid == axi0_r0_dynamic_id_q
axi0_read_complete && axi0_r1_dynamic_busy_q && axi0_rid == axi0_r1_dynamic_id_q
axi0_read_complete && axi0_r2_static_busy_q  && axi0_rid == 4'd3
```

Each matched rule pulses that transaction's generated completion output and
the release rule clears only that transaction's busy state. Same-cycle
release-and-recapture remains unselected.

## Assertion Contract

The generated assertion list should make both policy axes machine-readable:
dynamic-vs-dynamic active selected-ID uniqueness and dynamic-vs-static
concrete-ID exclusion. Expected local-helper names are:

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

The implementation may route these through a combined helper or compose the
existing all-dynamic and mixed helpers, but schedule JSON and focused tests
must expose these roles.

## Support Accounting

The support-accounting identity for `.344` is:

```text
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic
```

The focused coverage key is:

```text
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_pipeline_cli
```

The focused behavior label is:

```text
mixed_dynamic_static_read_demux_multi_dynamic
```

## Diagnostics

`.344` should fail closed with explicit diagnostics for:

- mixed read response-demux shapes outside exactly two dynamic plus one
  concrete static read transaction in this selected boundary;
- duplicate, missing, malformed, or out-of-range static concrete read IDs;
- missing positive-width read ID-family metadata;
- dynamic/static mixed read response-demux combined with read
  `auto_id_lifecycle`;
- dynamic/static mixed read response-demux combined with
  `same_id_ordering.read`;
- missing generated transaction-completion ownership;
- generated completion names colliding with the raw response event;
- any `last-signal` or `response-scope burst-last` attempt for this
  single-beat boundary;
- read-data attempts for the two-dynamic-plus-one-static shape before a later
  read-data owner; and
- broader capped mixed sets until a later exact owner selects them.

## Validation Gates

`.343` is selector-only, so documentation and continuity gates are
sufficient:

```bash
knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

The `.344` behavior owner should run:

- syntax checks for touched Perl modules and focused tests;
- filtered focused `t/1438` coverage for
  `mixed_dynamic_static_read_demux_multi_dynamic`;
- `t/248-regression-corpus-accounting.t` after adding the public sample;
- direct schedule/check/semantic/default-HDL/`--verify-hdl` probes for the new
  sample under the RAM guard where host and descendant memory permit;
- preservation filters for `.251`, `.276`, `.299`, `.322`, `.341`, and
  adjacent read-data samples;
- mdBook build;
- Knowledge Map generation/check;
- memory architecture check;
- diff whitespace check; and
- doctrine checks.

## Explicit Residue

Read burst-last response-demux, read-data, burst-length/runtime validation,
multi-beat output banks, broader capped mixed dynamic/static sets,
same-cycle request widening, release-and-recapture, dynamic same-ID queues,
scoreboards, direct backend behavior, backend-language variants, profile
aliases, queued/blocking policy, full-manager behavior, and VHDL remain
separate exact owners.

## Rollback

Rollback is documentation-only for `.343`: remove this contract note and fact
card, restore `.343` to pending, and restore README, ROADMAP_V2, mdBook, task
tree, Memory, and Knowledge Map to the post-`.342` state.
