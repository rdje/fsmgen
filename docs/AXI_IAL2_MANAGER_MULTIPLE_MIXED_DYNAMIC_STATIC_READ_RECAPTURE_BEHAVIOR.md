# AXI IAL2 Manager Multiple Mixed Dynamic/Static Read Recapture Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.411`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.411` ships
one-dynamic-plus-two-static mixed dynamic/static read single-beat `RID`
same-cycle release-and-recapture for the AXI manager capacity/status IAL2
object.

The support-accounted public sample is unchanged:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif
```

No new PPIF syntax is required.

## Public Shape

The shipped behavior uses the existing explicit multiple mixed
dynamic/static read single-beat response-demux source shape:

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
    (id (value 3)))
  (read r2
    (tag rd2)
    (request axi0_r2_request)
    (completion axi0_r2_complete)
    (id (value 5))))

(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope single-beat)
    (transaction-completion generated)))
```

The read ID family still supplies `axi0_arid` and `axi0_rid` at width 4.

## Generated Behavior

FSMGen now emits a dynamic release-recapture rule for `r0`:

```text
axi0_r0_dynamic_id_release_recapture
```

The rule fires when an admitted `r0` read request arrives in the same cycle as
the generated `r0` completion while `axi0_r0_dynamic_busy_q` is active. It
also requires no admitted `r1` or `r2` static request and requires
`axi0_arid` to be different from both reserved static IDs, `4'd3` and `4'd5`.
It captures the new `axi0_arid` and keeps `axi0_r0_dynamic_busy_q` asserted.

FSMGen also emits static release-recapture rules for `r1` and `r2`:

```text
axi0_r1_static_busy_release_recapture
axi0_r2_static_busy_release_recapture
```

Each static rule fires when the matching admitted static read request arrives
in the same cycle as the matching generated completion while that static busy
slot is active. It blocks the admitted dynamic request and the admitted
sibling static request, then keeps the matching static busy bit asserted.

The release-only rules now exclude their own same-transaction requests:

```text
axi0_r0_dynamic_id_release: axi0_r0_complete && axi0_r0_dynamic_busy_q && !axi0_r0_request
axi0_r1_static_busy_release: axi0_r1_complete && axi0_r1_static_busy_q && !axi0_r1_request
axi0_r2_static_busy_release: axi0_r2_complete && axi0_r2_static_busy_q && !axi0_r2_request
```

The response-demux match rules remain unchanged and still use pre-update
state for the accepted single-beat `RID` response.

## Report Contract

The response-demux mode and scope remain:

```text
bounded_multi_mixed_dynamic_static_read_rid_demux_contract
response_scope: single_beat
transaction_completion_source: generated_multi_mixed_dynamic_static_read_demux
transaction_completion_semantics: matched_dynamic_or_static_concrete_id_single_beat
```

The dynamic capture report keeps the existing transaction-list shape and now
adds recapture fields to `dynamic_capture.transactions[0]`:

```yaml
dynamic_capture:
  transactions:
    - transaction: r0
      selected_id_signal: axi0_r0_dynamic_id_q
      busy_signal: axi0_r0_dynamic_busy_q
      capture_rule: axi0_r0_dynamic_id_capture
      release_rule: axi0_r0_dynamic_id_release
      release_recapture_rule: axi0_r0_dynamic_id_release_recapture
      same_cycle_release_recapture_policy: mixed_dynamic_static_dynamic_read
      release_recapture_source: generated_multi_mixed_dynamic_static_read_demux_completion
      release_recapture_transaction: r0
```

The read report now includes list-shaped static busy lifecycle entries:

```yaml
static_capture:
  - transaction: r1
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
    release_recapture_source: generated_multi_mixed_dynamic_static_read_demux_completion
    release_recapture_transaction: r1
  - transaction: r2
    concrete_id: 5
    concrete_id_literal: 4'd5
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

Generated assertions for the selected sample are now:

```text
axi0_r0_dynamic_request_idle_or_releasing
axi0_r1_static_request_idle_or_releasing
axi0_r2_static_request_idle_or_releasing
axi0_read_mixed_dynamic_static_request_onehot0
axi0_r0_r1_read_dynamic_request_not_static_id
axi0_r0_r1_read_dynamic_active_not_static_id
axi0_r0_r2_read_dynamic_request_not_static_id
axi0_r0_r2_read_dynamic_active_not_static_id
axi0_read_mixed_dynamic_static_response_active_match
axi0_r0_r1_read_mixed_dynamic_static_response_unique_match
axi0_r0_r2_read_mixed_dynamic_static_response_unique_match
axi0_r1_r2_read_mixed_dynamic_static_response_unique_match
axi0_r0_dynamic_completion_active
axi0_r1_static_completion_active
axi0_r2_static_completion_active
```

## Preservation

The implementation preserves public syntax, support-accounting identity,
static ID reservations for `4'd3` and `4'd5`, generated response-demux rules,
generated completion signals, onehot0 mixed read request policy, dynamic
request/static-ID exclusion assertions, active dynamic/static-ID exclusion
assertions, response active-match, pairwise response unique-match, and
completion-active assertions.

The existing one-dynamic/one-static mixed read recapture sample keeps its
singular `static_capture` hash and
`generated_mixed_dynamic_static_read_demux_completion` source.

The one-dynamic-plus-three-static mixed read single-beat sample remains
outside this owner: it still has no `static_capture` and still uses
request-not-busy assertions.

Scalar single-beat read-data over the one-dynamic-plus-two-static mixed read
response-demux remains preserved. The read-data report for
`ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_read_data.ppif`
still has:

```text
read_data.mode = bounded_single_beat_read_data_contract
read_data.read.completion_validity =
  generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse
read_data.read.transactions = r0, r1, r2
```

## Validation

Closeout validation covered:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -c t/1436-ial2-ppif-parser-cli.t
perl -c t/1437-axi-ial2-manager-capacity-status-generator.t
perl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --output /tmp/fsmgen_411_multi_static_read.sv ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --verify-hdl --output /tmp/fsmgen_411_multi_static_read_verify.sv ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif
```

The selected guarded schedule probe passed at 84.5% host memory and produced
a 46200-byte report. Guarded strict check JSON, semantic JSON, SystemVerilog
generation, and `--verify-hdl` also passed under the default 88% host cutoff.

The guarded focused `t/1438` selected-case rerun was attempted with
`FSMGEN_DYNAMIC_CASE_FILTER=mixed_dynamic_static_read_demux_multi_static` and
`FSMGEN_DYNAMIC_SKIP_CLI_JSON=1`, but the RAM guard stopped it at 88.2% host
memory before TAP output completed. No cutoff was raised. Smaller guarded
direct adapter probes verified the selected report/rule names and the
singular read, three-static read, and scalar read-data preservation
boundaries.

Continuity gates also pass as part of closeout: Knowledge Map
generation/check, mdBook build, memory architecture check, diff whitespace
check, and doctrine checks.

## Deferred Boundaries

One-dynamic plus two-static mixed read burst-last recapture,
one-dynamic-plus-three-static read recapture, two-dynamic-plus-one-static read
recapture, raw non-final `RID` preservation for burst-last recapture,
read-data/raw-`ARLEN`/runtime/multi-beat behavior changes, static-busy-only
recapture outside selected public mixed samples, request arbitration beyond
onehot0, dynamic same-ID queues, scoreboards, queued/blocking policy, profile
aliases, direct backend behavior, backend-language variants, VHDL, and full
AXI manager behavior remain later exact owners.

## Rollback

Rollback is the `.411` implementation commit. Reverting it removes the
one-dynamic-plus-two-static mixed read release-recapture widening, report
fields, assertion renames, docs, and facts, restoring the `.410` selected
contract as the active frontier.
