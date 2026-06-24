# AXI IAL2 Manager Multiple Mixed Dynamic/Static Read RLAST Recapture Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.415`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.415` ships
one-dynamic-plus-two-static mixed dynamic/static read burst-last `RID &&
RLAST` same-cycle release-and-recapture for the AXI manager capacity/status
IAL2 object.

The support-accounted public sample is unchanged:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif
```

No new PPIF syntax is required. The behavior is bounded to exactly one
dynamic read transaction, exactly two pairwise-distinct concrete static read
transactions, `response-scope burst-last`, and one one-bit `last-signal`.

## Public Shape

The shipped behavior uses the existing explicit multiple mixed
dynamic/static read burst-last response-demux source shape:

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
    (response-scope burst-last)
    (last-signal axi0_rlast (width 1))
    (transaction-completion generated)))
```

The read ID family still supplies `axi0_arid` and `axi0_rid` at width 4.

## Generated Behavior

FSMGen now marks the multiple mixed read burst-last report with a dynamic
release-recapture rule for `r0`:

```text
axi0_r0_dynamic_id_release_recapture
```

The rule is tied to the generated `r0` final-beat completion pulse. It
requires an admitted `r0` read request, `axi0_r0_complete`,
`axi0_r0_dynamic_busy_q`, no admitted `r1` or `r2` static request in the same
cycle, and `axi0_arid` different from both reserved static IDs, `4'd3` and
`4'd5`. It captures the new `axi0_arid` and keeps
`axi0_r0_dynamic_busy_q` asserted.

FSMGen also marks static release-recapture rules for `r1` and `r2`:

```text
axi0_r1_static_busy_release_recapture
axi0_r2_static_busy_release_recapture
```

Each static rule is tied to the matching generated final-beat completion
pulse. It requires the matching admitted static read request, the matching
static busy bit, no admitted dynamic read request, and no admitted sibling
static read request in the same cycle. It keeps the matching static busy bit
asserted.

The release-only rules exclude their own same-transaction requests:

```text
axi0_r0_dynamic_id_release: axi0_r0_complete && axi0_r0_dynamic_busy_q && !axi0_r0_request
axi0_r1_static_busy_release: axi0_r1_complete && axi0_r1_static_busy_q && !axi0_r1_request
axi0_r2_static_busy_release: axi0_r2_complete && axi0_r2_static_busy_q && !axi0_r2_request
```

The response-demux match rules remain final-beat matches and still use the
pre-update selected ID or static busy state:

```text
axi0_read_complete && axi0_r0_dynamic_busy_q && axi0_rid == axi0_r0_dynamic_id_q && axi0_rlast
axi0_read_complete && axi0_r1_static_busy_q  && axi0_rid == 4'd3                 && axi0_rlast
axi0_read_complete && axi0_r2_static_busy_q  && axi0_rid == 4'd5                 && axi0_rlast
```

Matched non-final `RID` beats remain raw-response ownership evidence only.
They do not release or recapture any selected transaction.

## Report Contract

The response-demux mode and scope remain:

```text
bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract
response_scope: burst_last
transaction_completion_source: generated_multi_mixed_dynamic_static_read_demux_last_beat
transaction_completion_semantics: matched_dynamic_or_static_concrete_id_and_last_signal
```

The dynamic capture report keeps the existing transaction-list shape and now
adds final-beat recapture fields to `dynamic_capture.transactions[0]`:

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
      release_recapture_source: generated_multi_mixed_dynamic_static_read_demux_last_beat_completion
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
    release_recapture_source: generated_multi_mixed_dynamic_static_read_demux_last_beat_completion
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
    release_recapture_source: generated_multi_mixed_dynamic_static_read_demux_last_beat_completion
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

The implementation preserves public source syntax, support-accounting
identity, the burst-last mode and scope, `last_signal: axi0_rlast`, generated
final-beat completion source, static ID reservations for `4'd3` and `4'd5`,
generated response-demux rules, generated completion signals, onehot0 mixed
read request policy, raw response active-match and unique-match assertions,
and completion-active assertions.

The existing one-dynamic/one-static mixed read burst-last recapture sample
keeps its singular `static_capture` hash and
`generated_mixed_dynamic_static_read_demux_last_beat_completion` source.

The one-dynamic-plus-three-static mixed read burst-last sample remains outside
this owner: it still has no `static_capture` and still uses
request-not-busy assertions.

The two-dynamic-plus-one-static mixed read burst-last sample remains outside
this owner: it still has no release-recapture fields and still uses
request-not-busy assertions.

Layered consumers over the selected two-static burst-last demux remain
preserved: scalar last-beat `RDATA`/`RRESP` capture, report-only raw-`ARLEN`,
runtime beat-count/`RLAST` validation, and multi-beat output banks continue to
consume the generated final completion pulse or raw matched beats according
to their existing contracts.

## Validation

Closeout validation covered syntax checks:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
```

Guarded selected schedule JSON passed under the default host RAM 88% cutoff:

```bash
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif
```

The selected schedule probe started at 86.8% host memory and produced a
46549-byte report. It showed idle-or-releasing assertions for `r0`, `r1`, and
`r2`, final-beat dynamic recapture fields under
`dynamic_capture.transactions[0]`, and list-shaped static recapture entries
for `r1` and `r2`.

Guarded schedule preservation probes also passed for:

```bash
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last.ppif
```

Those probes confirmed that the one-static RLAST recapture shape remains
singular, the three-static burst-last report remains un-widened, and the
two-dynamic-plus-one-static burst-last report remains un-widened.

Guarded focused `t/1438`, strict check JSON, semantic JSON, SystemVerilog
generation, and `--verify-hdl` probes were attempted under the default 88%
host cutoff and stopped when the RAM guard observed host memory above the
cutoff. No cutoff was raised.

Continuity gates also pass as part of closeout: Knowledge Map
generation/check, mdBook build, memory architecture check, docs relative path
check, diff whitespace check, and doctrine checks.

## Deferred Boundaries

One-dynamic-plus-three-static read recapture, two-dynamic-plus-one-static read
recapture, layered recapture-specific consumer changes, static-busy-only
recapture outside selected public mixed samples, request arbitration beyond
onehot0, dynamic same-ID queues, scoreboards, queued/blocking policy, profile
aliases, direct backend behavior, backend-language variants, VHDL, and full
AXI manager behavior remain later exact owners.

## Rollback

Rollback is the `.415` implementation commit. Reverting it removes the
one-dynamic-plus-two-static mixed read burst-last release-recapture widening,
report fields, assertion renames, docs, and facts, restoring the `.414`
selected contract as the active frontier.
