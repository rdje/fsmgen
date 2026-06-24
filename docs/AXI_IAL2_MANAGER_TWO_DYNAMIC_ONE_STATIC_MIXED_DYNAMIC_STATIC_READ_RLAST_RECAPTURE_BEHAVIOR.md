# AXI IAL2 Manager Two-Dynamic/One-Static Mixed Dynamic/Static Read RLAST Recapture Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.431`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.431` ships
two-dynamic-plus-one-static mixed dynamic/static read burst-last `RID &&
RLAST` same-cycle release-and-recapture for the AXI manager capacity/status
IAL2 object.

The support-accounted public sample is unchanged:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last.ppif
```

No new PPIF syntax, support-accounting entry, or public sample is required.

## Public Shape

The shipped behavior uses the existing burst-last mixed read response-demux
source shape:

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

## Generated Behavior

FSMGen now emits dynamic release-recapture rules for `r0` and `r1`:

```text
axi0_r0_dynamic_id_release_recapture
axi0_r1_dynamic_id_release_recapture
```

For each dynamic transaction, the rule fires when the same transaction has an
admitted read request, generated final-beat `RID && RLAST` completion, and
active dynamic busy state in the same cycle, while:

- the sibling dynamic transaction has no admitted request;
- the sibling dynamic transaction is not already active with the new `ARID`;
- the static `r2` transaction has no admitted request; and
- `axi0_arid` is not `4'd3`.

The rule captures the new `axi0_arid` into the same transaction's selected-ID
state and keeps its busy bit asserted. The response-demux match for the
completed read response still uses the pre-update selected ID.

FSMGen also emits one static busy release-recapture rule:

```text
axi0_r2_static_busy_release_recapture
```

The static rule fires when `r2` has an admitted request, generated final-beat
`r2` completion, and active static busy state in the same cycle, while neither
dynamic transaction has an admitted request. The rule keeps the static busy
bit asserted.

Release-only rules now exclude same-transaction same-cycle requests:

```text
axi0_r0_dynamic_id_release: axi0_r0_complete && axi0_r0_dynamic_busy_q && !axi0_r0_request
axi0_r1_dynamic_id_release: axi0_r1_complete && axi0_r1_dynamic_busy_q && !axi0_r1_request
axi0_r2_static_busy_release: axi0_r2_complete && axi0_r2_static_busy_q && !axi0_r2_request
```

The response-demux completion rules remain final-beat matches over pre-update
state:

```text
axi0_read_complete && axi0_r0_dynamic_busy_q && axi0_rid == axi0_r0_dynamic_id_q && axi0_rlast
axi0_read_complete && axi0_r1_dynamic_busy_q && axi0_rid == axi0_r1_dynamic_id_q && axi0_rlast
axi0_read_complete && axi0_r2_static_busy_q  && axi0_rid == 4'd3                 && axi0_rlast
```

Raw non-final `RID` beats remain active/unique-match assertion evidence only;
they do not release or recapture a transaction before the generated final-beat
completion pulse.

## Report Contract

The response-demux mode remains:

```text
bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract
```

The dynamic capture report now includes release-recapture fields for both
dynamic entries:

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
          release_recapture_source: generated_multi_mixed_dynamic_static_read_demux_last_beat_completion
          release_recapture_transaction: r0
        - transaction: r1
          selected_id_signal: axi0_r1_dynamic_id_q
          busy_signal: axi0_r1_dynamic_busy_q
          capture_rule: axi0_r1_dynamic_id_capture
          release_rule: axi0_r1_dynamic_id_release
          release_recapture_rule: axi0_r1_dynamic_id_release_recapture
          same_cycle_release_recapture_policy: mixed_dynamic_static_multi_active_dynamic_read
          release_recapture_source: generated_multi_mixed_dynamic_static_read_demux_last_beat_completion
          release_recapture_transaction: r1
```

The static capture report is list-shaped:

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
        release_recapture_source: generated_multi_mixed_dynamic_static_read_demux_last_beat_completion
        release_recapture_transaction: r2
```

## Assertion Contract

Generated assertions for the selected sample now start with:

```text
axi0_r0_dynamic_request_idle_or_releasing
axi0_r1_dynamic_request_idle_or_releasing
axi0_r2_static_request_idle_or_releasing
axi0_read_mixed_dynamic_static_request_onehot0
```

The implementation preserves:

- `axi0_r0_dynamic_request_no_active_same_id`;
- `axi0_r1_dynamic_request_no_active_same_id`;
- `axi0_r0_r1_read_dynamic_active_id_unique`;
- dynamic request/static-ID and active/static-ID exclusions for `r0`/`r2`
  and `r1`/`r2`;
- raw `RID` response active-match and pairwise unique-match assertions across
  `r0`, `r1`, and `r2`; and
- completion-active assertions for `r0`, `r1`, and `r2`.

## Preservation

The implementation preserves public syntax, support-accounting identity,
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`,
`response_scope: burst_last`, `axi0_rlast`, transaction-completion source
`generated_multi_mixed_dynamic_static_read_demux_last_beat`, completion
semantics `matched_dynamic_or_static_concrete_id_and_last_signal`, dynamic/
static/mixed transaction lists, static-ID reservation for `r2`, generated
final-beat response-demux rules, generated final-beat completions, onehot0
request policy, no-active-same-ID checks, active dynamic-ID uniqueness,
static-ID exclusions, raw `RID` response active-match and pairwise
unique-match assertions, and completion-active assertions.

The `.427` two-dynamic-plus-one-static mixed read single-beat recapture
behavior remains intact. One-dynamic plus one/two/three-static burst-last read
recapture behavior remains intact. The layered two-dynamic-plus-one-static
read-data, raw-`ARLEN`, runtime beat-count/`RLAST`, and multi-beat output-bank
consumers preserve their payload, validation, output-bank, and public syntax
behavior; they may continue to surface the widened upstream response-demux
report fields.

## Validation

Closeout validation covered syntax checks for touched Perl modules/tests. A
guarded focused `t/1438` selected-case run stopped immediately because host
memory was already 93.0% against the default 88% cutoff; no cutoff was raised.

Direct focused probes covered the selected behavior:

- adapter/report/ISF/FSM probe passed for the selected public sample and
  confirmed the response-demux mode, idle-or-releasing assertions, `r0`/`r1`
  dynamic release-recapture fields, `r2` list-shaped static recapture field,
  release-only request exclusions, and scheduled recapture rules;
- FSM-to-SystemVerilog probe passed and confirmed generated `ARID`, `RID`,
  `RLAST`, `r0`/`r1` dynamic ID state, `r2` static busy state, final-beat
  `RID && RLAST` guards, and active sibling-ID expressions; and
- continuity gates covered Knowledge Map generation/check, mdBook build,
  memory architecture check, diff whitespace check, and doctrine checks.

## Deferred Boundaries

Parser syntax, new PPIF samples, support-accounting catalog entries, layered
recapture-specific read-data/raw-`ARLEN`/runtime/multi-beat behavior,
dynamic same-ID queues, scoreboards, request arbitration beyond onehot0,
queued/blocking policy, profile aliases, direct backend behavior,
backend-language variants, VHDL, and full AXI manager behavior remain later
exact owners.
