# AXI IAL2 Manager Two-Dynamic/One-Static Mixed Dynamic/Static Read RLAST Response-Demux Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.346`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.346` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.347`, direct generated behavior for
bounded two-dynamic-plus-one-static mixed dynamic/static read burst-last
`RID`/`RLAST` response-demux.

The selected public contract reuses the existing explicit
`response-demux.read` syntax with `response-scope burst-last`, a one-bit
`last-signal`, and generated transaction completions. No new parser form,
source keyword, report mode name, support-accounting class, or behavioral
shortcut is selected in `.346`.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Public Source Shape

`.347` should add one support-accounted public PPIF sample:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last.ppif
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
    (response-scope burst-last)
    (last-signal axi0_rlast (width 1))
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
- `response-demux.read.response-scope` set to `burst-last`;
- one one-bit `last-signal` named `axi0_rlast`;
- `response-demux.read.transaction-completion` set to `generated`;
- no read `auto_id_lifecycle` metadata;
- no `same_id_ordering.read` policy; and
- no read-data, raw `ARLEN`, runtime validation, multi-beat output-bank,
  queue, scoreboard, direct backend, or VHDL behavior.

## Report Contract

`.347` should reuse the existing list-shaped multi-mixed read burst-last mode:

```text
bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract
```

Cardinality is represented through report lists, not a new mode name:

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

The report must list generated rules and completions in transaction order:

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

The existing `.280` one-dynamic plus one-static, `.303` one-dynamic plus
two-static, `.326` one-dynamic plus three-static, and `.344` two-dynamic plus
one-static single-beat read report contracts must remain unchanged.

## Generated Behavior Contract

`.347` should emit selected-ID and busy state for both dynamic read
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

Raw accepted read response-beat ownership is keyed by `RID` only. The
active-match and unique-match assertions must not include `RLAST`, matching
the `.255`, `.303`, and `.326` burst-last contracts.

Generated response-demux rules complete and release only on the final matching
beat:

```text
axi0_read_complete && axi0_r0_dynamic_busy_q && axi0_rid == axi0_r0_dynamic_id_q && axi0_rlast
axi0_read_complete && axi0_r1_dynamic_busy_q && axi0_rid == axi0_r1_dynamic_id_q && axi0_rlast
axi0_read_complete && axi0_r2_static_busy_q  && axi0_rid == 4'd3                 && axi0_rlast
```

Same-cycle release-and-recapture remains unselected.

## Assertion Contract

The generated assertion list should make both policy axes machine-readable:
dynamic-vs-dynamic active selected-ID uniqueness and dynamic-vs-static
concrete-ID exclusion, while keeping raw response ownership independent of
`RLAST`. Expected local-helper names are:

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

The implementation may compose existing all-dynamic and mixed helpers, but
schedule JSON and focused tests must expose these roles.

## Support Accounting

The support-accounting identity for `.347` is:

```text
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last
```

The focused coverage key is:

```text
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_pipeline_cli
```

The focused behavior label is:

```text
mixed_dynamic_static_read_rlast_demux_multi_dynamic
```

## Diagnostics

`.347` should fail closed with explicit diagnostics for:

- mixed read burst-last response-demux shapes outside exactly two dynamic
  plus one concrete static read transaction in this selected boundary;
- duplicate, missing, malformed, or out-of-range static concrete read IDs;
- missing positive-width read ID-family metadata;
- dynamic/static mixed read response-demux combined with read
  `auto_id_lifecycle`;
- dynamic/static mixed read response-demux combined with
  `same_id_ordering.read`;
- missing generated transaction-completion ownership;
- generated completion names colliding with the raw response event;
- `response-scope single-beat` attempts using the `_burst_last` public sample
  stem;
- missing, malformed, or non-one-bit `last-signal` metadata; and
- read-data, raw `ARLEN`, runtime-validation, or multi-beat output-bank
  attempts that assume the new shape before those later owners select them.

The existing `.345` fail-closed diagnostic for this unimplemented shape may
be widened by `.347` only as needed to include the new two-dynamic-plus-one-
static burst-last contract.

## Validation Plan

The `.347` implementation owner should run:

- syntax checks for touched Perl modules/tests;
- guarded direct schedule JSON for the new public sample;
- guarded strict check JSON for the new sample and support-accounting match;
- guarded semantic JSON for the new sample;
- guarded default SystemVerilog generation for the new sample;
- guarded `--verify-hdl` for the new sample where memory permits;
- focused `t/1438` coverage for `mixed_dynamic_static_read_rlast_demux_multi_dynamic`;
- guarded `t/248-regression-corpus-accounting.t`;
- preservation probes for `.344`, `.255`, `.303`, `.326`, and adjacent
  read-data samples;
- Knowledge Map generation/check;
- mdBook build;
- memory architecture check;
- diff whitespace check; and
- `scripts/check_doctrines.sh`.

Broad `t/1438` or direct CLI probes that trip the default 88% host-memory
guard should be narrowed and recorded as resource caveats instead of forced
unbounded.

## Residue

`.347` must keep the following as explicit future exact owners:

- read-data over the new two-dynamic/one-static burst-last demux;
- raw `ARLEN` burst-length capture over the new shape;
- runtime beat-count/`RLAST` validation over the new shape;
- multi-beat output banks over the new shape;
- broader capped mixed dynamic/static sets;
- same-cycle request widening beyond onehot0;
- same-cycle release-and-recapture;
- dynamic same-ID queues and scoreboards;
- direct backend behavior outside the selected generated SystemVerilog path;
- backend-language variants;
- VHDL;
- profile aliases;
- queued/blocking policy; and
- full-manager behavior.

## Rollback

Rollback is the `.346` documentation commit. Reverting it removes only the
contract-selection record, task-tree frontier movement, docs, Memory, and
Knowledge Map fact, restoring `.346` as the active contract-selection
frontier.
