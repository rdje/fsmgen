# AXI IAL2 Manager Dynamic Read RLAST Recapture Behavior

Status: behavior shipped by `IAL2-FEATURE-COMPLETENESS-FRONTIER.372` on
2026-06-24.

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.372`

## Summary

FSMGen now generates same-cycle release-and-recapture behavior for the selected
single-active dynamic read burst-last `RID && RLAST` response-demux contract:

```text
ppif/axi_manager_capacity_status_dynamic_read_response_demux_burst_last.ppif
```

The public source syntax and support-accounting identity are unchanged. The
report mode remains `bounded_dynamic_read_rid_rlast_demux_contract`, and the
response-demux completion source remains `generated_dynamic_demux_last_beat`.

The generated response match still uses the pre-update selected dynamic ID and
busy state. When the generated `RID && RLAST` completion occurs in the same
cycle as a new admitted `r0` request, FSMGen captures the new `ARID` into the
selected-ID state and keeps the busy bit asserted for the next cycle.

Matched non-last beats remain legal raw response beats. They do not pulse
`axi0_r0_complete`, release the dynamic slot, or recapture a new ID.

## Generated Update Rules

The capture-only rule remains the idle-slot path:

```lisp
(rule axi0_r0_dynamic_id_capture
  (& (& axi0_r0_request (| (< axi0_pending_reads_q 4) axi0_r0_complete))
     (! axi0_r0_dynamic_busy_q))
  (axi0_r0_dynamic_id_q axi0_arid)
  (axi0_r0_dynamic_busy_q 1))
```

The response-demux rule pulses completion only from the pre-update active ID and
`RLAST`:

```lisp
(rule axi0_r0_response_demux
  (& axi0_read_complete
     axi0_r0_dynamic_busy_q
     (== axi0_rid axi0_r0_dynamic_id_q)
     axi0_rlast)
  (pulse axi0_r0_complete))
```

The release-and-recapture rule owns the same-cycle final-beat path:

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

The old burst-last single-active dynamic read request-not-busy assertion is
superseded by idle-or-releasing semantics:

```text
axi0_r0_dynamic_request_idle_or_releasing:
  admitted_dynamic_read_request -> (!axi0_r0_dynamic_busy_q || axi0_r0_complete)
```

The existing raw response active-match and completion-active assertions remain:

```text
axi0_read_dynamic_response_active_match
axi0_r0_dynamic_completion_active
```

The active-match assertion is intentionally raw-read-response based and does not
require `RLAST`, so matched non-last beats remain legal while mismatched beats
are still diagnosed.

## Report Surface

The response-demux report keeps the existing generated response-demux rule and
completion signal lists, and adds release-recapture ownership under
`dynamic_capture`:

```yaml
response_demux:
  mode: bounded_dynamic_read_rid_rlast_demux_contract
  read:
    mode: bounded_dynamic_read_rid_rlast_demux_contract
    response_scope: burst_last
    transaction_completion_source: generated_dynamic_demux_last_beat
    transaction_completion_semantics: matched_dynamic_id_and_last_signal
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
      release_recapture_source: generated_dynamic_demux_last_beat_completion
      release_recapture_transaction: r0
    generated_rules: [axi0_r0_response_demux]
    generated_completion_signals: [axi0_r0_complete]
    generated_assertions:
      - axi0_r0_dynamic_request_idle_or_releasing
      - axi0_read_dynamic_response_active_match
      - axi0_r0_dynamic_completion_active
```

## Preservation Consumers

The selected behavior changes the shared single-active burst-last response-demux
state lifetime. It does not change the payload or validation contracts layered
over that completion pulse:

- scalar last-beat dynamic read-data still captures `RDATA/RRESP` under
  `axi0_r0_complete`;
- report-only raw-`ARLEN` still captures request metadata under the request
  rule and leaves runtime validation absent;
- runtime beat-count/`RLAST` validation still counts raw matched read beats and
  checks the final `RLAST` boundary; and
- multi-beat output banks still capture per-beat payloads from raw matched
  dynamic read beats while the final completion ends the transaction.

The read-data completion-validity strings remain:

```text
generated_dynamic_read_response_demux_last_beat_completion_pulse
response_demux_matched_read_beat
```

## Public Checks

Useful focused checks:

```bash
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_response_demux_burst_last.ppif
scripts/run_with_ram_guard.sh -- env FSMGEN_DYNAMIC_CASE_FILTER=dynamic_read_rlast_demux FSMGEN_DYNAMIC_SKIP_CLI_JSON=1 prove -l t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
```

Preservation samples:

```bash
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_data_last_beat.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_data_burst_length.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_data_burst_length_runtime_assertion.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_dynamic_read_data_multi_beat.ppif
```

## Residue

Multiple dynamic burst-last recapture, mixed dynamic/static recapture, static
busy recapture, dynamic same-ID queues, scoreboards, queued/blocking policy,
profile aliases, direct backend behavior, backend-language variants, VHDL, and
full AXI manager behavior remain later exact-owner tasks.
