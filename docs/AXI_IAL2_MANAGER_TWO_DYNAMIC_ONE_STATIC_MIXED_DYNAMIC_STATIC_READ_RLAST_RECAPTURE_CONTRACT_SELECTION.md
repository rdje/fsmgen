# AXI IAL2 Manager Two-Dynamic/One-Static Mixed Dynamic/Static Read RLAST Recapture Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.430`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.430` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.431`, direct implementation of
two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID &&
RLAST` same-cycle release-and-recapture for the existing public sample:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last.ppif
```

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, or runtime behavior.

## Evidence Read

The selector read or used:

- `.429` readiness audit and `.428` selector.
- `.427` and `.426` two-dynamic-plus-one-static mixed read single-beat
  recapture behavior and contract.
- `.347` two-dynamic-plus-one-static mixed read burst-last response-demux
  behavior.
- `.350`, `.353`, `.355`, `.357`, and `.361`
  two-dynamic-plus-one-static read-data, raw-`ARLEN`, runtime-validation,
  multi-beat, and single-beat read-data consumer records.
- `.415` and `.423` one-dynamic plus two/three-static mixed read burst-last
  recapture precedents.
- Current read response-demux normalization, mixed dynamic/static state
  builders, release-only and release-recapture rule helpers, assertion/report
  helpers, focused `t/1438` expectation surfaces, support accounting, README,
  ROADMAP_V2, mdBook, Memory, task tree, and Knowledge Map.

A guarded baseline schedule probe for the selected public sample stopped
before output at host memory 92.3% against the default 88% cutoff. The cutoff
was not raised. The selector therefore relies on the `.429` direct baseline
evidence plus the current code audit.

## Selected Contract

The implementation owner should preserve the existing public source shape:

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

The selected report contract remains:

```text
mode: bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract
response_scope: burst_last
last_signal: axi0_rlast
last_signal_width: 1
transaction_completion_source: generated_multi_mixed_dynamic_static_read_demux_last_beat
transaction_completion_semantics: matched_dynamic_or_static_concrete_id_and_last_signal
dynamic_transactions: r0, r1
static_transactions: r2
static_id_reservations: r2 => 4'd3
```

Generated response-demux completion rules remain final-beat matches over
pre-update state:

```text
axi0_read_complete && axi0_r0_dynamic_busy_q && axi0_rid == axi0_r0_dynamic_id_q && axi0_rlast
axi0_read_complete && axi0_r1_dynamic_busy_q && axi0_rid == axi0_r1_dynamic_id_q && axi0_rlast
axi0_read_complete && axi0_r2_static_busy_q  && axi0_rid == 4'd3                 && axi0_rlast
```

Raw non-final `RID` beats remain ownership evidence for active/unique-match
assertions only. They must not release or recapture any transaction before the
generated final-beat completion pulse fires.

The implementation should add dynamic release-recapture report fields under
both dynamic capture entries:

```yaml
dynamic_capture:
  transactions:
    - transaction: r0
      release_recapture_rule: axi0_r0_dynamic_id_release_recapture
      same_cycle_release_recapture_policy: mixed_dynamic_static_multi_active_dynamic_read
      release_recapture_source: generated_multi_mixed_dynamic_static_read_demux_last_beat_completion
      release_recapture_transaction: r0
    - transaction: r1
      release_recapture_rule: axi0_r1_dynamic_id_release_recapture
      same_cycle_release_recapture_policy: mixed_dynamic_static_multi_active_dynamic_read
      release_recapture_source: generated_multi_mixed_dynamic_static_read_demux_last_beat_completion
      release_recapture_transaction: r1
```

The implementation should add list-shaped static busy lifecycle report data:

```yaml
static_capture:
  - transaction: r2
    concrete_id: 3
    concrete_id_literal: 4'd3
    capture_event_source: admitted_static_read_request
    ownership: mixed_dynamic_static_concrete_read_id
    simultaneous_request_policy: onehot0_mixed_read_request
    busy_signal: axi0_r2_static_busy_q
    capture_rule: axi0_r2_static_busy_capture
    release_rule: axi0_r2_static_busy_release
    release_recapture_rule: axi0_r2_static_busy_release_recapture
    same_cycle_release_recapture_policy: mixed_dynamic_static_static_read
    release_recapture_source: generated_multi_mixed_dynamic_static_read_demux_last_beat_completion
    release_recapture_transaction: r2
```

## Rule And Assertion Contract

The dynamic recapture rules should be:

```text
axi0_r0_dynamic_id_release_recapture
axi0_r1_dynamic_id_release_recapture
```

For each dynamic transaction, the rule should require the same transaction's
admitted read request, generated same-transaction final-beat completion, and
active busy state. It should also block:

- the sibling dynamic request in the same cycle;
- an active sibling dynamic transaction already holding the new `axi0_arid`;
- the static `r2` request in the same cycle; and
- the static concrete ID `4'd3`.

The rule captures the new `axi0_arid` into that transaction's selected-ID
state and keeps that transaction busy. The final-beat response-demux match
continues to use the pre-update selected ID for the completed response.

The static recapture rule should be:

```text
axi0_r2_static_busy_release_recapture
```

It should require an admitted `r2` request, generated `r2` final-beat
completion, and active `axi0_r2_static_busy_q`, while blocking both dynamic
requests. It keeps the static busy bit asserted.

Release-only rules should exclude only their own same-transaction request:

```text
axi0_r0_dynamic_id_release: axi0_r0_complete && axi0_r0_dynamic_busy_q && !axi0_r0_request
axi0_r1_dynamic_id_release: axi0_r1_complete && axi0_r1_dynamic_busy_q && !axi0_r1_request
axi0_r2_static_busy_release: axi0_r2_complete && axi0_r2_static_busy_q && !axi0_r2_request
```

Generated assertions should replace only the three request-not-busy names
with idle-or-releasing names:

```text
axi0_r0_dynamic_request_idle_or_releasing
axi0_r1_dynamic_request_idle_or_releasing
axi0_r2_static_request_idle_or_releasing
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

## Implementation Notes

The expected implementation is intentionally narrow:

- extend only the burst-last multi-mixed read normalizer selector to mark
  exactly two dynamic read states plus exactly one concrete static read state;
- keep `_response_demux_mark_mixed_dynamic_static_read_recapture` as the report
  projection owner for `mixed_dynamic_static_multi_active_dynamic_read` and
  list-shaped `static_capture[]`;
- rely on the existing read-side guard arrays from `.427` so dynamic recapture
  combines sibling dynamic request blocks, active sibling same-ID blocks,
  static request blocks, and static ID blocks;
- keep static recapture on the existing `mixed_dynamic_static_static_read`
  policy; and
- update focused `t/1438` report/ISF/FSM/SystemVerilog expectations for the
  selected burst-last public sample only.

No parser syntax, PPIF sample, support-accounting entry, direct backend
behavior, VHDL behavior, or full-manager behavior is selected.

## Preservation

The implementation owner must preserve:

- public syntax and support identity for the selected burst-last sample;
- existing one-dynamic/one-static, one-dynamic-plus-two-static, and
  one-dynamic-plus-three-static mixed read burst-last recapture shapes;
- `.427` two-dynamic-plus-one-static mixed read single-beat recapture;
- `.347` raw non-final `RID` active/unique-match assertion roles;
- scalar last-beat read-data over `.350`;
- report-only raw-`ARLEN` over `.353`;
- runtime beat-count/`RLAST` validation over `.355`;
- multi-beat output banks over `.357`; and
- scalar single-beat read-data over `.361`.

The layered read-data/raw-`ARLEN`/runtime/multi-beat consumer samples may
observe the widened response-demux recapture report as a preserved upstream
field, but they must not gain new payload, validation, output-bank, or source
syntax behavior in `.431`.

## Validation And Rollback

The implementation owner should run syntax checks for the touched Perl module
and focused test, guarded schedule/report probes where host memory permits,
direct adapter or ISF/FSM/SystemVerilog fallback probes for selected rules and
guards when broad probes stop at the RAM cutoff, preservation probes for the
read-data/raw-`ARLEN`/runtime/multi-beat siblings, mdBook build, Knowledge Map
generation/check, memory, diff, and doctrine gates.

Rollback is the `.431` implementation commit. Reverting it should remove only
the two-dynamic-plus-one-static mixed read burst-last release-recapture
widening, report fields, assertion renames, docs, and facts, restoring this
`.430` selected contract as the active frontier.

## Next Frontier

`.431` is the next exact owner: direct implementation of the selected
two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID &&
RLAST` release-and-recapture behavior.
