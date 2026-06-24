# AXI IAL2 Manager Dynamic Write Same-Cycle Recapture Behavior

Status: behavior shipped by `IAL2-FEATURE-COMPLETENESS-FRONTIER.365` on
2026-06-24.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.365`

## Summary

FSMGen now generates same-cycle release-and-recapture behavior for the selected
single-active dynamic write `BID` response-demux contract:

```text
ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif
```

The public source syntax and support-accounting identity are unchanged. The
report mode remains `bounded_dynamic_write_bid_demux_contract`.

The generated behavior still matches the raw write response `BID` against the
pre-update selected dynamic ID. When that generated completion occurs in the
same cycle as a new admitted `w0` request, FSMGen captures the new `AWID` into
the selected-ID state and keeps the single-active busy bit asserted for the next
cycle.

## Generated Update Rules

The capture-only rule remains the idle-slot path:

```lisp
(rule axi0_w0_dynamic_id_capture
  (& (& axi0_w0_request (| (< axi0_pending_writes_q 2) axi0_w0_complete))
     (! axi0_w0_dynamic_busy_q))
  (axi0_w0_dynamic_id_q axi0_awid)
  (axi0_w0_dynamic_busy_q 1))
```

The response-demux rule pulses completion from the pre-update active ID:

```lisp
(rule axi0_w0_response_demux
  (& axi0_write_complete
     axi0_w0_dynamic_busy_q
     (== axi0_bid axi0_w0_dynamic_id_q))
  (pulse axi0_w0_complete))
```

The release-and-recapture rule owns the same-cycle path:

```lisp
(rule axi0_w0_dynamic_id_release_recapture
  (& (& axi0_w0_request (| (< axi0_pending_writes_q 2) axi0_w0_complete))
     axi0_w0_complete
     axi0_w0_dynamic_busy_q)
  (axi0_w0_dynamic_id_q axi0_awid)
  (axi0_w0_dynamic_busy_q 1))
```

The release-only rule is now explicitly guarded by no same-cycle request:

```lisp
(rule axi0_w0_dynamic_id_release
  (& axi0_w0_complete axi0_w0_dynamic_busy_q (! axi0_w0_request))
  (axi0_w0_dynamic_busy_q 0))
```

## Assertions

The old single-active dynamic write request-not-busy assertion is superseded by
idle-or-releasing semantics:

```text
axi0_w0_dynamic_request_idle_or_releasing:
  admitted_dynamic_write_request -> (!axi0_w0_dynamic_busy_q || axi0_w0_complete)
```

The existing response active-match and completion-active assertions remain:

```text
axi0_write_dynamic_response_active_match
axi0_w0_dynamic_completion_active
```

## Report Surface

The response-demux report keeps the existing generated response-demux rule and
completion signal lists, and adds explicit update-rule ownership under
`dynamic_capture`:

```yaml
response_demux:
  mode: bounded_dynamic_write_bid_demux_contract
  write:
    mode: bounded_dynamic_write_bid_demux_contract
    dynamic_capture:
      request_id_source: axi0_awid
      capture_event_source: admitted_dynamic_write_request
      ownership: single_active_dynamic_write
      selected_id_signal: axi0_w0_dynamic_id_q
      busy_signal: axi0_w0_dynamic_busy_q
      capture_rule: axi0_w0_dynamic_id_capture
      release_rule: axi0_w0_dynamic_id_release
      release_recapture_rule: axi0_w0_dynamic_id_release_recapture
      same_cycle_release_recapture_policy: single_active_dynamic_write
      release_recapture_source: generated_dynamic_demux_completion
      release_recapture_transaction: w0
    generated_rules: [axi0_w0_response_demux]
    generated_completion_signals: [axi0_w0_complete]
    generated_assertions:
      - axi0_w0_dynamic_request_idle_or_releasing
      - axi0_write_dynamic_response_active_match
      - axi0_w0_dynamic_completion_active
```

The normalized semantic report includes the new
`-axi0_w0_dynamic_id_release_recapture` standalone transition and keeps
`standalone_dt_multi_drive_target_count` at zero for the generated sample.

## Public Checks

Useful focused checks:

```bash
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --strict --check --json ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --strict --output /tmp/fsmgen_dynamic_write_response_demux.sv ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif
```

## Residue

This slice does not widen multiple dynamic write request policy, mixed
dynamic/static recapture, static busy recapture, read `RID`/`RLAST` recapture,
read-data payload capture, dynamic same-ID queues, scoreboards, queued/blocking
policy, profile aliases, direct backend behavior, backend-language variants,
VHDL, or full AXI manager behavior. Those remain later exact-owner tasks.
