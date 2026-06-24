# AXI IAL2 Manager Three-Static Mixed Dynamic/Static Write Recapture Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.403`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.403` ships one-dynamic plus three-static
mixed dynamic/static write `BID` same-cycle release-and-recapture for the AXI
manager capacity/status IAL2 object.

The support-accounted public sample is unchanged:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static3.ppif
```

## Public Shape

The shipped behavior uses the existing explicit three-static mixed write
response-demux source shape:

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

No new PPIF syntax is required.

## Generated Behavior

FSMGen now emits a dynamic release-recapture rule for `w0`:

```text
axi0_w0_dynamic_id_release_recapture
```

The dynamic rule fires when the admitted `w0` write request, generated `w0`
completion, and dynamic busy state are present, while no selected static
request is admitted in the same cycle and `axi0_awid` is not `4'd3`, `4'd5`,
or `4'd7`. It captures the new `axi0_awid` and keeps
`axi0_w0_dynamic_busy_q` asserted.

FSMGen also emits one static busy release-recapture rule for each selected
concrete static write transaction:

```text
axi0_w1_static_busy_release_recapture
axi0_w2_static_busy_release_recapture
axi0_w3_static_busy_release_recapture
```

Each static rule fires when its admitted static write request, generated
static completion, and static busy state are present, while no admitted
dynamic request and no admitted sibling static request are present in the same
cycle. The rule keeps the static busy bit asserted; concrete static slots do
not have selected-ID registers.

The dynamic and static release-only rules now exclude same-transaction
same-cycle requests:

```text
axi0_w0_dynamic_id_release: axi0_w0_complete && axi0_w0_dynamic_busy_q && !axi0_w0_request
axi0_w1_static_busy_release: axi0_w1_complete && axi0_w1_static_busy_q && !axi0_w1_request
axi0_w2_static_busy_release: axi0_w2_complete && axi0_w2_static_busy_q && !axi0_w2_request
axi0_w3_static_busy_release: axi0_w3_complete && axi0_w3_static_busy_q && !axi0_w3_request
```

The response-demux match rules remain unchanged and still use the pre-update
state for the accepted `BID` response:

```text
axi0_write_complete && axi0_w0_dynamic_busy_q && axi0_bid == axi0_w0_dynamic_id_q
axi0_write_complete && axi0_w1_static_busy_q  && axi0_bid == 4'd3
axi0_write_complete && axi0_w2_static_busy_q  && axi0_bid == 4'd5
axi0_write_complete && axi0_w3_static_busy_q  && axi0_bid == 4'd7
```

## Report Contract

The response-demux mode remains:

```text
bounded_multi_mixed_dynamic_static_write_bid_demux_contract
```

The dynamic capture transaction report now includes:

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
          same_cycle_release_recapture_policy: mixed_dynamic_static_dynamic_write
          release_recapture_source: generated_multi_mixed_dynamic_static_demux_completion
          release_recapture_transaction: w0
```

The write report now includes list-shaped static busy lifecycle entries for
all three concrete static slots:

```yaml
response_demux:
  write:
    static_capture:
      - transaction: w1
        concrete_id: 3
        concrete_id_literal: 4'd3
        release_recapture_rule: axi0_w1_static_busy_release_recapture
        same_cycle_release_recapture_policy: mixed_dynamic_static_static_write
        release_recapture_source: generated_multi_mixed_dynamic_static_demux_completion
        release_recapture_transaction: w1
      - transaction: w2
        concrete_id: 5
        concrete_id_literal: 4'd5
        release_recapture_rule: axi0_w2_static_busy_release_recapture
        same_cycle_release_recapture_policy: mixed_dynamic_static_static_write
        release_recapture_source: generated_multi_mixed_dynamic_static_demux_completion
        release_recapture_transaction: w2
      - transaction: w3
        concrete_id: 7
        concrete_id_literal: 4'd7
        release_recapture_rule: axi0_w3_static_busy_release_recapture
        same_cycle_release_recapture_policy: mixed_dynamic_static_static_write
        release_recapture_source: generated_multi_mixed_dynamic_static_demux_completion
        release_recapture_transaction: w3
```

Generated assertions for the selected sample now start with:

```text
axi0_w0_dynamic_request_idle_or_releasing
axi0_w1_static_request_idle_or_releasing
axi0_w2_static_request_idle_or_releasing
axi0_w3_static_request_idle_or_releasing
axi0_write_mixed_dynamic_static_request_onehot0
```

Static-ID exclusion, response active-match, all six pairwise unique-match, and
completion-active assertions are preserved.

## Preservation

The implementation preserves public syntax, support-accounting identity,
`bounded_multi_mixed_dynamic_static_write_bid_demux_contract`,
`generated_multi_mixed_dynamic_static_demux`,
`matched_dynamic_or_static_concrete_id`, transaction lists, static-ID
reservations, generated response-demux rules, generated completions, onehot0
mixed write request policy, static-ID exclusion assertions, response
active-match assertions, pairwise unique-match assertions, and
completion-active assertions.

The one-static mixed write sample keeps its singular `static_capture` report
shape. The two-static mixed write sample keeps its list-shaped recapture
report shape. The two-dynamic-plus-one-static mixed write sample remains
outside this recapture slice.

## Validation

Closeout validation covered:

```bash
env -u PERL5LIB perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -c t/1436-ial2-ppif-parser-cli.t
perl -c t/1437-axi-ial2-manager-capacity-status-generator.t
perl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
```

Two guarded selected schedule JSON attempts stopped before usable output
because host memory was already above the default 88% RAM-guard cutoff:
88.3% on the first attempt and 95.3% on the retry. No cutoff was raised. A
guarded schedule retry should be run when host memory is below cutoff before
widening beyond this exact `.403` boundary.

Continuity gates also covered Knowledge Map generation/check, mdBook build,
memory architecture check, diff whitespace check, and doctrine checks.

## Deferred Boundaries

Two-dynamic-plus-one-static mixed write recapture, broader mixed read
recapture, read-data/raw-`ARLEN`/runtime/multi-beat consumers,
static-busy-only recapture outside selected mixed samples, request arbitration
beyond onehot0, dynamic same-ID queues, scoreboards, queued/blocking policy,
profile aliases, direct backend behavior, backend-language variants, VHDL,
and full AXI manager behavior remain later exact owners.

## Rollback

Rollback is the `.403` implementation commit. Reverting it removes the
three-static mixed write dynamic/static release-recapture rules, list-shaped
report fields, assertion renames, docs, and facts, restoring the `.402`
selected contract as the active frontier.
