# AXI IAL2 Manager Two-Dynamic/One-Static Mixed Dynamic/Static Write Recapture Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.407`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.407` ships
two-dynamic-plus-one-static mixed dynamic/static write `BID` same-cycle
release-and-recapture for the AXI manager capacity/status IAL2 object.

The support-accounted public sample is unchanged:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif
```

## Public Shape

The shipped behavior uses the existing explicit two-dynamic/one-static mixed
write response-demux source shape:

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

No new PPIF syntax is required.

## Generated Behavior

FSMGen now emits dynamic release-recapture rules for `w0` and `w1`:

```text
axi0_w0_dynamic_id_release_recapture
axi0_w1_dynamic_id_release_recapture
```

For each dynamic transaction, the rule fires when the same transaction has an
admitted write request, generated matched-`BID` completion, and active dynamic
busy state in the same cycle, while:

- the sibling dynamic transaction has no admitted request;
- the sibling dynamic transaction is not already active with the new `AWID`;
- the static `w2` transaction has no admitted request; and
- `axi0_awid` is not `4'd3`.

The rule captures the new `axi0_awid` into the same transaction's selected-ID
state and keeps its busy bit asserted. The raw response-demux match still uses
the pre-update selected ID for the completed response.

FSMGen also emits one static busy release-recapture rule:

```text
axi0_w2_static_busy_release_recapture
```

The static rule fires when `w2` has an admitted request, generated `w2`
completion, and active static busy state in the same cycle, while neither
dynamic transaction has an admitted request. The rule keeps the static busy
bit asserted.

The dynamic and static release-only rules now exclude same-transaction
same-cycle requests:

```text
axi0_w0_dynamic_id_release: axi0_w0_complete && axi0_w0_dynamic_busy_q && !axi0_w0_request
axi0_w1_dynamic_id_release: axi0_w1_complete && axi0_w1_dynamic_busy_q && !axi0_w1_request
axi0_w2_static_busy_release: axi0_w2_complete && axi0_w2_static_busy_q && !axi0_w2_request
```

The response-demux match rules remain unchanged and still use pre-update
state:

```text
axi0_write_complete && axi0_w0_dynamic_busy_q && axi0_bid == axi0_w0_dynamic_id_q
axi0_write_complete && axi0_w1_dynamic_busy_q && axi0_bid == axi0_w1_dynamic_id_q
axi0_write_complete && axi0_w2_static_busy_q  && axi0_bid == 4'd3
```

## Report Contract

The response-demux mode remains:

```text
bounded_multi_mixed_dynamic_static_write_bid_demux_contract
```

The dynamic capture report now includes release-recapture fields for both
dynamic transaction entries:

```yaml
response_demux:
  write:
    dynamic_capture:
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

The static capture report is list-shaped for this multi-mixed mode:

```yaml
response_demux:
  write:
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

## Assertion Contract

Generated assertions for the selected sample now start with:

```text
axi0_w0_dynamic_request_idle_or_releasing
axi0_w1_dynamic_request_idle_or_releasing
axi0_w2_static_request_idle_or_releasing
axi0_write_mixed_dynamic_static_request_onehot0
```

The implementation preserves:

- `axi0_w0_dynamic_request_no_active_same_id`;
- `axi0_w1_dynamic_request_no_active_same_id`;
- `axi0_w0_w1_write_dynamic_active_id_unique`;
- dynamic request/static-ID and active/static-ID exclusion assertions for
  `w0`/`w2` and `w1`/`w2`;
- `axi0_write_mixed_dynamic_static_response_active_match`;
- pairwise response unique-match assertions across `w0`, `w1`, and `w2`; and
- completion-active assertions for `w0`, `w1`, and `w2`.

## Preservation

The implementation preserves public syntax, support-accounting identity,
`bounded_multi_mixed_dynamic_static_write_bid_demux_contract`,
`generated_multi_mixed_dynamic_static_demux`,
`matched_dynamic_or_static_concrete_id`, dynamic/static/mixed transaction
lists, static-ID reservation for `w2`, generated response-demux rules,
generated completions, onehot0 request policy, no-active-same-ID checks,
active dynamic-ID uniqueness, static-ID exclusions, response active-match,
pairwise unique-match, and completion-active assertions.

The one-dynamic/one-static mixed write recapture report keeps its singular
`static_capture` shape. The one-dynamic/two-static and one-dynamic/
three-static mixed write recapture reports keep their existing list-shaped
static capture shapes. The multiple all-dynamic write recapture report keeps
`multi_active_unique_dynamic_write`.

## Validation

Closeout validation covered syntax checks for touched Perl modules/tests.
Guarded schedule JSON and focused `t/1438` probes for the selected sample were
attempted under the default RAM guard and stopped before usable output because
host memory was already above the 88% cutoff:

```text
schedule JSON: stopped at 94.5% host memory
focused t/1438: stopped at 92.5% host memory
```

The guarded schedule JSON output file was empty, and no cutoff was raised.
Continuity gates covered Knowledge Map generation/check, mdBook build, memory
architecture check, diff whitespace check, and doctrine checks.

## Deferred Boundaries

Broader mixed read recapture, read-data/raw-`ARLEN`/runtime/multi-beat
consumers, static-busy-only recapture outside selected mixed samples, request
arbitration beyond onehot0, dynamic same-ID queues, scoreboards,
queued/blocking policy, profile aliases, direct backend behavior,
backend-language variants, VHDL, and full AXI manager behavior remain later
exact owners.

## Rollback

Rollback is the `.407` implementation commit. Reverting it removes the
two-dynamic/one-static mixed write release-recapture rules and report fields,
restores request-not-busy assertions for `w0`/`w1`/`w2`, and leaves the
earlier `.341` two-dynamic/one-static write response-demux behavior intact.
