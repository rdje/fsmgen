# AXI IAL2 Manager Mixed Dynamic Static Read RLAST Recapture Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.396`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.396` ships mixed dynamic/static read
burst-last `RID && RLAST` same-cycle release-and-recapture for the AXI manager
capacity/status IAL2 object.

The support-accounted public sample is unchanged:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif
```

No new PPIF syntax is required. The behavior remains bounded to exactly one
dynamic read transaction, exactly one concrete static read transaction,
`response-scope burst-last`, and one one-bit `last-signal`.

## Generated Behavior

FSMGen now emits a dynamic release-recapture rule for `r0`:

```text
axi0_r0_dynamic_id_release_recapture
```

The rule fires only from the generated final-beat completion pulse for the
active dynamic transaction. It requires an admitted dynamic read request,
`axi0_r0_complete`, `axi0_r0_dynamic_busy_q`, no admitted static read request
in the same cycle, and `axi0_arid != 4'd3`. It captures the new `axi0_arid`
and keeps `axi0_r0_dynamic_busy_q` asserted.

FSMGen also emits a static release-recapture rule for `r1`:

```text
axi0_r1_static_busy_release_recapture
```

The static rule fires only from the generated final-beat completion pulse for
the concrete static transaction. It requires an admitted static read request,
`axi0_r1_complete`, `axi0_r1_static_busy_q`, and no admitted dynamic read
request in the same cycle. It keeps `axi0_r1_static_busy_q` asserted.

The release-only rules now exclude same-transaction same-cycle requests:

```text
axi0_r0_dynamic_id_release: axi0_r0_complete && axi0_r0_dynamic_busy_q && !axi0_r0_request
axi0_r1_static_busy_release: axi0_r1_complete && axi0_r1_static_busy_q && !axi0_r1_request
```

The response-demux match rules remain final-beat matches and still use the
pre-update selected ID or static busy state:

```text
axi0_read_complete && axi0_r0_dynamic_busy_q && axi0_rid == axi0_r0_dynamic_id_q && axi0_rlast
axi0_read_complete && axi0_r1_static_busy_q  && axi0_rid == 4'd3                 && axi0_rlast
```

Matched non-final `RID` beats remain raw-response consumers only. They do not
release or recapture either transaction.

## Report Contract

The response-demux mode and scope remain:

```text
bounded_mixed_dynamic_static_read_rid_rlast_demux_contract
response_scope: burst_last
transaction_completion_source: generated_mixed_dynamic_static_read_demux_last_beat
```

The dynamic capture report now includes:

```yaml
release_recapture_rule: axi0_r0_dynamic_id_release_recapture
same_cycle_release_recapture_policy: mixed_dynamic_static_dynamic_read
release_recapture_source: generated_mixed_dynamic_static_read_demux_last_beat_completion
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
  release_recapture_source: generated_mixed_dynamic_static_read_demux_last_beat_completion
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

The implementation preserves public source syntax, support-accounting identity,
the burst-last mode and scope, `last_signal: axi0_rlast`, generated last-beat
completion source, static-ID reservation, onehot0 mixed read request policy,
raw response active-match and unique-match assertions, and completion-active
assertions.

Layered consumers over this demux remain preserved: scalar last-beat
`RDATA`/`RRESP` capture, report-only raw-`ARLEN`, runtime beat-count/`RLAST`
validation, and multi-beat output banks still consume the generated final
completion pulse or raw matched beats according to their existing contracts.

## Validation

Closeout validation covered syntax checks:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -c t/1437-axi-ial2-manager-capacity-status-generator.t
perl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
```

Guarded schedule JSON and focused `t/1438` runtime validation were attempted
under the repository RAM guard. The schedule probe stopped immediately at
96.5% host memory against the 88% cutoff, a retry stopped at 97.0%, and the
focused `t/1438` probe stopped at 89.6% against the same cutoff. No cutoff was
raised.

Continuity gates also passed at closeout: Knowledge Map generation/check,
mdBook build, memory architecture check, diff whitespace check, and doctrine
checks.

## Deferred Boundaries

Multiple mixed dynamic/static recapture, static-busy-only recapture outside
the selected mixed read/write samples, request arbitration beyond onehot0,
dynamic same-ID queues, scoreboards, queued/blocking policy, profile aliases,
direct backend behavior, backend-language variants, VHDL, and full AXI
manager behavior remain later exact owners.
