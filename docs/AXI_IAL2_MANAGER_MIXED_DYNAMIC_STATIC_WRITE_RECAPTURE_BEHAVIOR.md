# AXI IAL2 Manager Mixed Dynamic Static Write Recapture Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.389`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.389` ships mixed dynamic/static write
`BID` same-cycle release-and-recapture for the AXI manager capacity/status
IAL2 object.

The support-accounted public sample is unchanged:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux.ppif
```

## Public Shape

The shipped behavior uses the existing explicit mixed dynamic/static write
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
    (id (value 3))))

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

The rule fires when the admitted dynamic write request, generated dynamic
completion, and dynamic busy state are present, while the static request is
not admitted in the same cycle and `axi0_awid != 4'd3`. It captures the new
`axi0_awid` and keeps `axi0_w0_dynamic_busy_q` asserted.

FSMGen also emits a static release-recapture rule for `w1`:

```text
axi0_w1_static_busy_release_recapture
```

The static rule fires when the admitted static write request, generated static
completion, and static busy state are present while the dynamic request is not
admitted in the same cycle. It keeps `axi0_w1_static_busy_q` asserted; no
selected-ID register exists for the static concrete-ID slot.

The dynamic and static release-only rules now exclude same-transaction
same-cycle requests:

```text
axi0_w0_dynamic_id_release: axi0_w0_complete && axi0_w0_dynamic_busy_q && !axi0_w0_request
axi0_w1_static_busy_release: axi0_w1_complete && axi0_w1_static_busy_q && !axi0_w1_request
```

The response-demux match rules remain unchanged and still use the pre-update
state for the accepted `BID` response:

```text
axi0_write_complete && axi0_w0_dynamic_busy_q && axi0_bid == axi0_w0_dynamic_id_q
axi0_write_complete && axi0_w1_static_busy_q  && axi0_bid == 4'd3
```

## Report Contract

The response-demux mode remains:

```text
bounded_mixed_dynamic_static_write_bid_demux_contract
```

The dynamic capture report now includes:

```yaml
release_recapture_rule: axi0_w0_dynamic_id_release_recapture
same_cycle_release_recapture_policy: mixed_dynamic_static_dynamic_write
release_recapture_source: generated_mixed_dynamic_static_demux_completion
release_recapture_transaction: w0
```

The write report now includes a public static busy lifecycle block:

```yaml
static_capture:
  transaction: w1
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
  release_recapture_source: generated_mixed_dynamic_static_demux_completion
  release_recapture_transaction: w1
```

Generated assertions for the selected sample are now:

```text
axi0_w0_dynamic_request_idle_or_releasing
axi0_w1_static_request_idle_or_releasing
axi0_write_mixed_dynamic_static_request_onehot0
axi0_w0_dynamic_request_not_static_id
axi0_w0_dynamic_active_not_static_id
axi0_write_mixed_dynamic_static_response_active_match
axi0_w0_w1_write_mixed_dynamic_static_response_unique_match
axi0_w0_dynamic_completion_active
axi0_w1_static_completion_active
```

## Preservation

The implementation preserves public syntax, support-accounting identity, the
mixed write report mode, generated mixed completion source, dynamic selected-ID
and static concrete busy ownership, static-ID reservation, onehot0 mixed write
request policy, dynamic request/static-ID exclusion, active dynamic/static-ID
exclusion, response active-match, response unique-match, and completion-active
assertions.

## Validation

Closeout validation covered:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -c t/1436-ial2-ppif-parser-cli.t
perl -c t/1437-axi-ial2-manager-capacity-status-generator.t
perl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux.ppif
```

A direct adapter/generator probe confirmed the generated IAL1 rules, generated
FSM rules, report policies, and idle-or-releasing assertion names.

The guarded focused `t/1438` mixed-write run was attempted with
`FSMGEN_DYNAMIC_CASE_FILTER=mixed_dynamic_static_write_demux` and
`FSMGEN_DYNAMIC_SKIP_CLI_JSON=1`; the RAM guard stopped it at the 88% host
memory cutoff before TAP completed. No cutoff was raised.

Continuity gates also passed: Knowledge Map generation/check, mdBook build,
memory architecture check, diff whitespace check, and doctrine checks.

## Deferred Boundaries

Mixed read single-beat recapture, mixed read burst-last recapture, multiple
mixed dynamic/static transaction recapture, static-busy-only recapture outside
the selected mixed write sample, request arbitration beyond onehot0, dynamic
same-ID queues, scoreboards, queued/blocking policy, profile aliases, direct
backend behavior, backend-language variants, VHDL, and full AXI manager
behavior remain later exact owners.

## Rollback

Rollback is the `.389` implementation commit. Reverting it removes the mixed
write dynamic/static release-recapture rules, report fields, assertion
renames, docs, and facts, restoring the `.388` selected contract as the active
frontier.
