# AXI IAL2 Manager Dynamic Read Same-Cycle Recapture Behavior

Status: behavior shipped by `IAL2-FEATURE-COMPLETENESS-FRONTIER.368` on
2026-06-24.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.368`

## Summary

FSMGen now generates same-cycle release-and-recapture behavior for the selected
single-active dynamic read single-beat `RID` response-demux contract:

```text
ppif/axi_manager_capacity_status_dynamic_read_response_demux.ppif
```

The public source syntax and support-accounting identity are unchanged. The
report mode remains `bounded_dynamic_read_rid_demux_contract`.

The generated behavior still matches the raw accepted read response `RID`
against the pre-update selected dynamic ID. When that generated completion
occurs in the same cycle as a new admitted `r0` request, FSMGen captures the new
`ARID` into the selected-ID state and keeps the single-active busy bit asserted
for the next cycle.

## Generated Update Rules

The capture-only rule remains the idle-slot path:

```lisp
(rule axi0_r0_dynamic_id_capture
  (& (& axi0_r0_request (| (< axi0_pending_reads_q 4) axi0_r0_complete))
     (! axi0_r0_dynamic_busy_q))
  (axi0_r0_dynamic_id_q axi0_arid)
  (axi0_r0_dynamic_busy_q 1))
```

The response-demux rule pulses completion from the pre-update active ID:

```lisp
(rule axi0_r0_response_demux
  (& axi0_read_complete
     axi0_r0_dynamic_busy_q
     (== axi0_rid axi0_r0_dynamic_id_q))
  (pulse axi0_r0_complete))
```

The release-and-recapture rule owns the same-cycle path:

```lisp
(rule axi0_r0_dynamic_id_release_recapture
  (& (& axi0_r0_request (| (< axi0_pending_reads_q 4) axi0_r0_complete))
     axi0_r0_complete
     axi0_r0_dynamic_busy_q)
  (axi0_r0_dynamic_id_q axi0_arid)
  (axi0_r0_dynamic_busy_q 1))
```

The release-only rule is explicitly guarded by no same-cycle request:

```lisp
(rule axi0_r0_dynamic_id_release
  (& axi0_r0_complete axi0_r0_dynamic_busy_q (! axi0_r0_request))
  (axi0_r0_dynamic_busy_q 0))
```

## Assertions

The old single-active dynamic read request-not-busy assertion is superseded by
idle-or-releasing semantics:

```text
axi0_r0_dynamic_request_idle_or_releasing:
  admitted_dynamic_read_request -> (!axi0_r0_dynamic_busy_q || axi0_r0_complete)
```

The existing response active-match and completion-active assertions remain:

```text
axi0_read_dynamic_response_active_match
axi0_r0_dynamic_completion_active
```

Burst-last `RID && RLAST`, multiple dynamic reads, mixed dynamic/static reads,
and static concrete reads still use their existing request-not-busy and
onehot0/uniqueness assertion families until separately selected.

## Report Surface

The response-demux report keeps the existing generated response-demux rule and
completion signal lists, and adds explicit update-rule ownership under
`dynamic_capture`:

```yaml
response_demux:
  mode: bounded_dynamic_read_rid_demux_contract
  read:
    mode: bounded_dynamic_read_rid_demux_contract
    response_scope: single_beat
    transaction_completion_source: generated_dynamic_demux
    transaction_completion_semantics: matched_dynamic_id_single_beat
    dynamic_capture:
      request_id_source: axi0_arid
      capture_event_source: admitted_dynamic_read_request
      ownership: single_active_dynamic_read
      selected_id_signal: axi0_r0_dynamic_id_q
      busy_signal: axi0_r0_dynamic_busy_q
      capture_rule: axi0_r0_dynamic_id_capture
      release_rule: axi0_r0_dynamic_id_release
      release_recapture_rule: axi0_r0_dynamic_id_release_recapture
      same_cycle_release_recapture_policy: single_active_dynamic_read
      release_recapture_source: generated_dynamic_demux_completion
      release_recapture_transaction: r0
    generated_rules: [axi0_r0_response_demux]
    generated_completion_signals: [axi0_r0_complete]
    generated_assertions:
      - axi0_r0_dynamic_request_idle_or_releasing
      - axi0_read_dynamic_response_active_match
      - axi0_r0_dynamic_completion_active
```

The scalar single-beat dynamic read-data consumer keeps its payload contract:

```yaml
read_data:
  read:
    completion_validity: generated_dynamic_read_response_demux_completion_pulse
    generated_rules: [axi0_r0_read_data_capture]
```

The read-data capture rule remains guarded only by the generated completion
pulse; `.368` changes the response-demux state lifetime, not the payload
capture surface.

## Public Checks

Useful focused checks:

```bash
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_response_demux.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_dynamic_read_response_demux.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_dynamic_read_response_demux.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --strict --output /tmp/fsmgen_dynamic_read_response_demux.sv ppif/axi_manager_capacity_status_dynamic_read_response_demux.ppif
```

The scalar read-data preservation sample is:

```bash
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_data.ppif
```

The burst-last preservation sample is:

```bash
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_response_demux_burst_last.ppif
```

## Residue

This slice does not widen dynamic read burst-last `RID && RLAST` recapture,
scalar last-beat read-data recapture, dynamic burst-length/runtime validation
recapture, dynamic multi-beat output-bank recapture, multiple dynamic request
widening, mixed dynamic/static recapture, static busy recapture, dynamic same-ID
queues, scoreboards, queued/blocking policy, profile aliases, direct backend
behavior, backend-language variants, VHDL, or full AXI manager behavior. Those
remain later exact-owner tasks.
