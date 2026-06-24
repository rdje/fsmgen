# AXI IAL2 Manager Mixed Dynamic Static Read Recapture Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.392`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.392` ships mixed dynamic/static read
single-beat `RID` same-cycle release-and-recapture for the AXI manager
capacity/status IAL2 object.

The support-accounted public sample is unchanged:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux.ppif
```

## Public Shape

The shipped behavior uses the existing explicit mixed dynamic/static read
single-beat response-demux source shape:

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
    (id concrete 3)))

(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope single-beat)
    (transaction-completion generated)))
```

No new PPIF syntax is required.

## Generated Behavior

FSMGen now emits a dynamic release-recapture rule for `r0`:

```text
axi0_r0_dynamic_id_release_recapture
```

The rule fires when the admitted dynamic read request, generated dynamic
completion, and dynamic busy state are present, while the static request is not
admitted in the same cycle and `axi0_arid != 4'd3`. It captures the new
`axi0_arid` and keeps `axi0_r0_dynamic_busy_q` asserted.

FSMGen also emits a static release-recapture rule for `r1`:

```text
axi0_r1_static_busy_release_recapture
```

The static rule fires when the admitted static read request, generated static
completion, and static busy state are present while the dynamic request is not
admitted in the same cycle. It keeps `axi0_r1_static_busy_q` asserted; no
selected-ID register exists for the static concrete-ID slot.

The dynamic and static release-only rules now exclude same-transaction
same-cycle requests:

```text
axi0_r0_dynamic_id_release: axi0_r0_complete && axi0_r0_dynamic_busy_q && !axi0_r0_request
axi0_r1_static_busy_release: axi0_r1_complete && axi0_r1_static_busy_q && !axi0_r1_request
```

The response-demux match rules remain unchanged and still use the pre-update
state for the accepted single-beat `RID` response:

```text
axi0_read_complete && axi0_r0_dynamic_busy_q && axi0_rid == axi0_r0_dynamic_id_q
axi0_read_complete && axi0_r1_static_busy_q  && axi0_rid == 4'd3
```

## Report Contract

The response-demux mode and scope remain:

```text
bounded_mixed_dynamic_static_read_rid_demux_contract
response_scope: single_beat
```

The dynamic capture report now includes:

```yaml
release_recapture_rule: axi0_r0_dynamic_id_release_recapture
same_cycle_release_recapture_policy: mixed_dynamic_static_dynamic_read
release_recapture_source: generated_mixed_dynamic_static_read_demux_completion
release_recapture_transaction: r0
```

The read report now includes a public static busy lifecycle block:

```yaml
static_capture:
  transaction: r1
  concrete_id: 3
  concrete_id_literal: 4'd3
  capture_event_source: admitted_static_read_request
  ownership: mixed_dynamic_static_concrete_read_id
  simultaneous_request_policy: onehot0_mixed_read_request
  busy_signal: axi0_r1_static_busy_q
  capture_rule: axi0_r1_static_busy_capture
  release_rule: axi0_r1_static_busy_release
  release_recapture_rule: axi0_r1_static_busy_release_recapture
  same_cycle_release_recapture_policy: mixed_dynamic_static_static_read
  release_recapture_source: generated_mixed_dynamic_static_read_demux_completion
  release_recapture_transaction: r1
```

Generated assertions for the selected sample are now:

```text
axi0_r0_dynamic_request_idle_or_releasing
axi0_r1_static_request_idle_or_releasing
axi0_read_mixed_dynamic_static_request_onehot0
axi0_r0_dynamic_request_not_static_id
axi0_r0_dynamic_active_not_static_id
axi0_read_mixed_dynamic_static_response_active_match
axi0_r0_r1_read_mixed_dynamic_static_response_unique_match
axi0_r0_dynamic_completion_active
axi0_r1_static_completion_active
```

## Preservation

The implementation preserves public syntax, support-accounting identity, the
mixed read report mode and single-beat response scope, generated mixed read
completion source, dynamic selected-ID and static concrete busy ownership,
static-ID reservation, onehot0 mixed read request policy, dynamic
request/static-ID exclusion, active dynamic/static-ID exclusion, response
active-match, response unique-match, and completion-active assertions.

At `.392` closeout, the mixed read burst-last `RID && RLAST` sample remained
unchanged: it still had `bounded_mixed_dynamic_static_read_rid_rlast_demux_contract`,
final-beat completion source, request-not-busy assertions, no recapture policy,
and no `static_capture` report block.

As of `IAL2-FEATURE-COMPLETENESS-FRONTIER.396`, that burst-last sibling has
also shipped same-cycle release-and-recapture under its own behavior record:
`docs/AXI_IAL2_MANAGER_MIXED_DYNAMIC_STATIC_READ_RLAST_RECAPTURE_BEHAVIOR.md`.

## Validation

Closeout validation covered:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -c t/1436-ial2-ppif-parser-cli.t
perl -c t/1437-axi-ial2-manager-capacity-status-generator.t
perl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --output /tmp/fsmgen_mixed_read_recapture_impl.sv ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux.ppif
```

The guarded focused `t/1438` mixed-read run was attempted with
`FSMGEN_DYNAMIC_CASE_FILTER=mixed_dynamic_static_read_demux` and
`FSMGEN_DYNAMIC_SKIP_CLI_JSON=1`; the RAM guard stopped it at the 88% host
memory cutoff before TAP completed. No cutoff was raised.

Continuity gates also passed: Knowledge Map generation/check, mdBook build,
memory architecture check, diff whitespace check, and doctrine checks.

## Deferred Boundaries

Mixed read burst-last recapture, multiple mixed dynamic/static transaction
recapture, static-busy-only recapture outside the selected mixed read/write
samples, request arbitration beyond onehot0, dynamic same-ID queues,
scoreboards, queued/blocking policy, profile aliases, direct backend behavior,
backend-language variants, VHDL, and full AXI manager behavior remain later
exact owners.

## Rollback

Rollback is the `.392` implementation commit. Reverting it removes the mixed
read dynamic/static release-recapture rules, report fields, assertion renames,
docs, and facts, restoring the `.391` selected contract as the active
frontier.
