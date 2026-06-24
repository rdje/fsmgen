# AXI IAL2 Manager Two-Dynamic/One-Static Mixed Dynamic/Static Read Recapture Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.427`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.427` ships
two-dynamic-plus-one-static mixed dynamic/static read single-beat `RID`
same-cycle release-and-recapture for the AXI manager capacity/status IAL2
object.

The support-accounted public sample is unchanged:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif
```

No new PPIF syntax is required.

## Public Shape

The shipped behavior uses the existing explicit two-dynamic/one-static mixed
read response-demux source shape:

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

The read ID family still supplies `axi0_arid` and `axi0_rid` at width 4.

## Generated Behavior

FSMGen now emits dynamic release-recapture rules for `r0` and `r1`:

```text
axi0_r0_dynamic_id_release_recapture
axi0_r1_dynamic_id_release_recapture
```

For each dynamic transaction, the rule fires when the same transaction has an
admitted read request, generated matched-`RID` completion, and active dynamic
busy state in the same cycle, while:

- the sibling dynamic transaction has no admitted request;
- the sibling dynamic transaction is not already active with the new `ARID`;
- the static `r2` transaction has no admitted request; and
- `axi0_arid` is not `4'd3`.

The rule captures the new `axi0_arid` into the same transaction's selected-ID
state and keeps its busy bit asserted. The raw response-demux match still uses
the pre-update selected ID for the completed response.

FSMGen also emits one static busy release-recapture rule:

```text
axi0_r2_static_busy_release_recapture
```

The static rule fires when `r2` has an admitted request, generated `r2`
completion, and active static busy state in the same cycle, while neither
dynamic transaction has an admitted request. The rule keeps the static busy
bit asserted.

The dynamic and static release-only rules now exclude same-transaction
same-cycle requests:

```text
axi0_r0_dynamic_id_release: axi0_r0_complete && axi0_r0_dynamic_busy_q && !axi0_r0_request
axi0_r1_dynamic_id_release: axi0_r1_complete && axi0_r1_dynamic_busy_q && !axi0_r1_request
axi0_r2_static_busy_release: axi0_r2_complete && axi0_r2_static_busy_q && !axi0_r2_request
```

The response-demux match rules remain unchanged and still use pre-update
state:

```text
axi0_read_complete && axi0_r0_dynamic_busy_q && axi0_rid == axi0_r0_dynamic_id_q
axi0_read_complete && axi0_r1_dynamic_busy_q && axi0_rid == axi0_r1_dynamic_id_q
axi0_read_complete && axi0_r2_static_busy_q  && axi0_rid == 4'd3
```

## Report Contract

The response-demux mode and scope remain:

```text
bounded_multi_mixed_dynamic_static_read_rid_demux_contract
response_scope: single_beat
transaction_completion_source: generated_multi_mixed_dynamic_static_read_demux
transaction_completion_semantics: matched_dynamic_or_static_concrete_id_single_beat
```

The dynamic capture report now includes release-recapture fields for both
dynamic transaction entries:

```yaml
response_demux:
  read:
    dynamic_capture:
      transactions:
        - transaction: r0
          selected_id_signal: axi0_r0_dynamic_id_q
          busy_signal: axi0_r0_dynamic_busy_q
          capture_rule: axi0_r0_dynamic_id_capture
          release_rule: axi0_r0_dynamic_id_release
          release_recapture_rule: axi0_r0_dynamic_id_release_recapture
          same_cycle_release_recapture_policy: mixed_dynamic_static_multi_active_dynamic_read
          release_recapture_source: generated_multi_mixed_dynamic_static_read_demux_completion
          release_recapture_transaction: r0
        - transaction: r1
          selected_id_signal: axi0_r1_dynamic_id_q
          busy_signal: axi0_r1_dynamic_busy_q
          capture_rule: axi0_r1_dynamic_id_capture
          release_rule: axi0_r1_dynamic_id_release
          release_recapture_rule: axi0_r1_dynamic_id_release_recapture
          same_cycle_release_recapture_policy: mixed_dynamic_static_multi_active_dynamic_read
          release_recapture_source: generated_multi_mixed_dynamic_static_read_demux_completion
          release_recapture_transaction: r1
```

The static capture report is list-shaped for this multi-mixed mode:

```yaml
response_demux:
  read:
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

Generated assertions for the selected sample now start with:

```text
axi0_r0_dynamic_request_idle_or_releasing
axi0_r1_dynamic_request_idle_or_releasing
axi0_r2_static_request_idle_or_releasing
axi0_read_mixed_dynamic_static_request_onehot0
```

The no-active-same-ID, active dynamic-ID uniqueness, static-ID exclusion,
response active-match, pairwise unique-match, and completion-active assertions
remain present.

## Preservation

The implementation preserves public syntax, support-accounting identity,
static ID reservation for `4'd3`, generated response-demux rules, generated
completion signals, onehot0 mixed read request policy, request no-active-same-ID
assertions, active dynamic-ID uniqueness, dynamic request/static-ID exclusion
assertions, active dynamic/static-ID exclusion assertions, response
active-match, pairwise response unique-match, and completion-active assertions.

Existing one-/two-/three-static mixed read recapture behavior is unchanged.
The two-dynamic mixed read burst-last sample remains no-recapture, and the
two-dynamic read-data, raw-`ARLEN`, runtime-validation, and multi-beat
consumer samples remain no-recapture preservation boundaries for this slice.
