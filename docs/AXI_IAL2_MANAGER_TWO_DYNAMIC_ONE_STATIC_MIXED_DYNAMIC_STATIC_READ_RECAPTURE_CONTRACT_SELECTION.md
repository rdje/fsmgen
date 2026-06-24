# AXI IAL2 Manager Two-Dynamic/One-Static Mixed Dynamic/Static Read Recapture Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.426`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.426` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.427`, direct implementation of
two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID`
same-cycle release-and-recapture for the existing public sample:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif
```

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, or runtime behavior.

## Evidence Read

The selector read or used:

- `.425` two-dynamic-plus-one-static mixed read recapture readiness audit.
- `.424` post-three-static RLAST recapture next-slice selection.
- `.423` and `.419` three-static mixed read burst-last and single-beat
  recapture behavior.
- `.415` and `.411` one-dynamic-plus-two-static mixed read burst-last and
  single-beat recapture behavior.
- `.407` two-dynamic-plus-one-static mixed write recapture behavior.
- `.344` two-dynamic-plus-one-static mixed read single-beat response-demux
  behavior.
- `.347` two-dynamic-plus-one-static mixed read burst-last no-recapture
  boundary.
- `.350`, `.353`, `.355`, `.357`, and `.361`
  two-dynamic-plus-one-static read-data, raw-`ARLEN`, runtime-validation, and
  multi-beat consumer records.
- Current read response-demux normalization, mixed dynamic/static state
  builders, release-only and release-recapture rule helpers, assertion/report
  helpers, focused `t/1438` expectation surfaces, support accounting, README,
  ROADMAP_V2, mdBook, Memory, task tree, and Knowledge Map.

## Selected Contract

The implementation owner should preserve the public source shape exactly:

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

The selected report contract remains:

```text
mode: bounded_multi_mixed_dynamic_static_read_rid_demux_contract
response_scope: single_beat
transaction_completion_source: generated_multi_mixed_dynamic_static_read_demux
transaction_completion_semantics: matched_dynamic_or_static_concrete_id_single_beat
dynamic_transactions: r0, r1
static_transactions: r2
static_id_reservations: r2 => 4'd3
```

Generated response-demux match and completion rules remain pre-update-state
single-beat `RID` matches:

```text
axi0_read_complete && axi0_r0_dynamic_busy_q && axi0_rid == axi0_r0_dynamic_id_q
axi0_read_complete && axi0_r1_dynamic_busy_q && axi0_rid == axi0_r1_dynamic_id_q
axi0_read_complete && axi0_r2_static_busy_q  && axi0_rid == 4'd3
```

The implementation should add dynamic release-recapture report fields under
both dynamic capture entries:

```yaml
dynamic_capture:
  transactions:
    - transaction: r0
      release_recapture_rule: axi0_r0_dynamic_id_release_recapture
      same_cycle_release_recapture_policy: mixed_dynamic_static_multi_active_dynamic_read
      release_recapture_source: generated_multi_mixed_dynamic_static_read_demux_completion
      release_recapture_transaction: r0
    - transaction: r1
      release_recapture_rule: axi0_r1_dynamic_id_release_recapture
      same_cycle_release_recapture_policy: mixed_dynamic_static_multi_active_dynamic_read
      release_recapture_source: generated_multi_mixed_dynamic_static_read_demux_completion
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
    release_recapture_source: generated_multi_mixed_dynamic_static_read_demux_completion
    release_recapture_transaction: r2
```

The dynamic recapture rules should be:

```text
axi0_r0_dynamic_id_release_recapture
axi0_r1_dynamic_id_release_recapture
```

For each dynamic transaction, the rule should require the same transaction's
admitted read request, generated same-transaction completion, and active busy
state. It should additionally block:

- the sibling dynamic request in the same cycle;
- an active sibling dynamic transaction already holding the new `axi0_arid`;
- the static `r2` request in the same cycle; and
- the static concrete ID `4'd3`.

The rule captures the new `axi0_arid` into that transaction's selected-ID
state and keeps that transaction busy. The raw response-demux match still
uses the pre-update selected ID for the completed response.

The static recapture rule should be:

```text
axi0_r2_static_busy_release_recapture
```

It should require an admitted `r2` request, generated `r2` completion, and
active `axi0_r2_static_busy_q`, while blocking both dynamic requests. It keeps
the static busy bit asserted.

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

- extend the mixed read recapture marker to accept exactly two dynamic read
  states plus exactly one concrete static read state;
- introduce or recognize the read-side dynamic policy
  `mixed_dynamic_static_multi_active_dynamic_read`;
- make dynamic recapture lowerer guards for that read policy combine sibling
  dynamic request blocks, active sibling same-ID blocks, static request
  blocks, and static ID blocks;
- keep static recapture on the existing `mixed_dynamic_static_static_read`
  policy; and
- update focused `t/1438` report/ISF/FSM expectations for the selected
  single-beat public sample only.

No parser syntax, PPIF sample, support-accounting entry, direct backend
behavior, VHDL behavior, or full-manager behavior is selected.

## Preservation

The implementation owner must preserve:

- one-dynamic/one-static mixed read recapture;
- one-dynamic-plus-two-static mixed read single-beat and burst-last
  recapture;
- one-dynamic-plus-three-static mixed read single-beat and burst-last
  recapture;
- two-dynamic-plus-one-static mixed write recapture;
- two-dynamic-plus-one-static mixed read burst-last no-recapture behavior;
- two-dynamic-plus-one-static read-data, raw-`ARLEN`, runtime-validation, and
  multi-beat consumer behavior; and
- direct backend, backend-language variant, VHDL, and full-manager
  boundaries.

## Validation Plan

The implementation owner should run syntax checks for the touched generator
and focused test, guarded selected schedule/check/semantic/SystemVerilog/
verify-HDL probes where RAM permits, and direct fallback adapter/report,
ISF/FSM, and SystemVerilog probes if the RAM guard stops heavier paths.

Focused validation should cover:

- dynamic recapture fields for `r0` and `r1`;
- list-shaped `static_capture[]` for `r2`;
- `mixed_dynamic_static_multi_active_dynamic_read`;
- `generated_multi_mixed_dynamic_static_read_demux_completion`;
- dynamic guards for sibling request, active same-ID, static request, and
  static ID `4'd3`;
- static guards that block both dynamic requests;
- release-only same-transaction exclusions;
- idle-or-releasing assertion names for `r0`, `r1`, and `r2`; and
- preservation of the burst-last no-recapture sibling and read-data
  consumers.

`.426` itself is docs-only. Closeout validation is:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
mdbook build docs/book
scripts/check_doctrines.sh
```

## Deferred Boundaries

Direct implementation of the selected contract is deferred to `.427`.
Two-dynamic-plus-one-static read burst-last recapture, layered
recapture-specific consumer changes, static-busy-only recapture outside
selected public mixed samples, request arbitration beyond onehot0, dynamic
same-ID queues, scoreboards, queued/blocking policy, profile aliases, direct
backend behavior, backend-language variants, VHDL, and full AXI manager
behavior remain later exact owners.

## Rollback

Rollback is the `.426` selector commit. Reverting it restores `.426` as the
active contract-selection leaf and removes `.427` as the selected
implementation owner.
