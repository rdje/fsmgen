# AXI IAL2 Manager Two-Dynamic/One-Static Mixed Dynamic/Static Read RLAST Read-Data Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.348`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.348` audits scalar last-beat read-data
readiness over the `.347` generated two-dynamic-plus-one-static mixed
dynamic/static read burst-last `RID`/`RLAST` response-demux.

The audit selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.349`, public contract
selection for scalar last-beat `RDATA`/`RRESP` capture over that exact demux.
It changes no parser, generator, PPIF sample, support-accounting catalog,
validation behavior, generated artifact, test, schedule/check/semantic JSON, or
HDL behavior.

## Current Boundary

The `.347` response-demux sample is already support-accounted:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last.ppif
```

It covers dynamic reads `r0` and `r1`, concrete static read `r2` at ID `3`,
`response-scope burst-last`, one-bit `axi0_rlast`, response-demux mode
`bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract`, and
completion source `generated_multi_mixed_dynamic_static_read_demux_last_beat`.

Existing scalar last-beat read-data behavior over generated multiple mixed
dynamic/static read demux already defines the expected public shape:

```lisp
(read-data
  (read
    (capture-scope last-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (status-policy last-beat)
    (interleaving last-beat-by-rid)
    (transaction r0
      (data-output axi0_r0_last_rdata)
      (status-output axi0_r0_last_rresp))
    (transaction r1
      (data-output axi0_r1_last_rdata)
      (status-output axi0_r1_last_rresp))
    (transaction r2
      (data-output axi0_r2_last_rdata)
      (status-output axi0_r2_last_rresp))))
```

The current hard stop is local and intentional. The
`_read_data_response_demux_transaction_coverage` branch for
`generated_multi_mixed_dynamic_static_read_demux_last_beat` still requires one
dynamic read plus either two concrete static reads, or the selected one-dynamic
plus three-static variants. It does not yet admit the `.347` two-dynamic plus
one-static transaction set.

## Live Probe

A temporary guarded strict-check probe composed the `.347` response-demux with
the scalar last-beat read-data shape above:

```text
/tmp/fsmgen_348_two_dynamic_static_read_rlast_read_data_probe.ppif
```

The probe failed closed under:

```text
scripts/run_with_ram_guard.sh ./bin/fsmgen --strict --check --json /tmp/fsmgen_348_two_dynamic_static_read_rlast_read_data_probe.ppif
```

The diagnostic was the expected coverage boundary:

```text
AXI manager capacity/status IAL2 contract read_data.read multiple mixed dynamic/static coverage requires exactly one dynamic read transaction and two concrete static read transactions, scalar single-beat/last-beat read-data with exactly one dynamic read transaction and three concrete static read transactions and no burst_length metadata, scalar last-beat raw-ARLEN read-data with report-only or runtime-assertion validation and exactly one dynamic read transaction and three concrete static read transactions, or runtime-assertion multi-beat output-bank read-data with exactly one dynamic read transaction and three concrete static read transactions, in this slice
```

This confirms the parser and public shape are coherent enough to reach the
read-data transaction-coverage gate, and the gate still fails closed before any
unowned behavior is generated.

## Selected Next Contract Owner

`.349` must settle the exact public contract before implementation. The selected
candidate surface is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data.ppif
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_pipeline_cli
mixed_dynamic_static_read_data_multi_dynamic_last_beat
```

The contract should preserve the `.347` response-demux report mode and source:

```text
response_demux.read.mode = bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract
response_demux.read.transaction_completion_source =
  generated_multi_mixed_dynamic_static_read_demux_last_beat
response_demux.read.transaction_completion_semantics =
  matched_dynamic_or_static_concrete_id_and_last_signal
```

The read-data report should use the existing scalar last-beat vocabulary:

```text
read_data.mode = bounded_last_beat_read_data_contract
read_data.read.completion_validity =
  generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse
read_data.read.transactions = r0, r1, r2
read_data.read.generated_inputs = axi0_rdata, axi0_rresp
read_data.read.generated_outputs =
  axi0_r0_last_rdata, axi0_r0_last_rresp,
  axi0_r1_last_rdata, axi0_r1_last_rresp,
  axi0_r2_last_rdata, axi0_r2_last_rresp
read_data.read.generated_rules =
  axi0_r0_read_data_capture,
  axi0_r1_read_data_capture,
  axi0_r2_read_data_capture
read_data.residue =
  multi_beat_read_data_reassembly, per_beat_outputs, rresp_aggregation,
  arlen_or_beat_count_validation
```

The implementation owner after `.349` should only widen the scalar no-`ARLEN`
last-beat read-data coverage predicate for this exact two-dynamic plus one-static
transaction set. It should not widen single-beat read-data for `.344` unless the
contract selector explicitly chooses that sibling too; this audit is scoped to
scalar last-beat read-data over the `.347` burst-last demux.

## Validation Plan

`.349` is a selector and should remain documentation-only. The later behavior
owner should validate:

- syntax checks for the touched Perl modules and focused tests;
- guarded direct schedule/check/semantic/default-HDL/`--verify-hdl` probes for
  the new public sample;
- schedule JSON assertions for the preserved `.347` response-demux mode/source
  plus the new scalar last-beat read-data report fields;
- strict check JSON support-accounting for the new public sample;
- focused `t/1438` coverage for `mixed_dynamic_static_read_data_multi_dynamic_last_beat`,
  with CLI JSON skipped only if the RAM guard trips at the default cutoff;
- `t/248-regression-corpus-accounting.t`; and
- preservation checks for `.347`, `.344`, the two-static and three-static mixed
  scalar last-beat read-data samples, and representative all-dynamic read-data.

Raw `ARLEN` report-only capture, runtime beat-count/`RLAST` validation,
multi-beat output banks, single-beat read-data over `.344`, broader mixed
cardinalities, same-cycle widening, release-and-recapture, dynamic same-ID
queues, scoreboards, direct backend behavior, backend-language variants, VHDL,
profile aliases, queued/blocking policy, and full-manager behavior remain future
exact-owner work.

## Rollback

Rollback for `.348` is doc-only: revert this audit, the task-tree/MEMORY/README/
ROADMAP/mdBook updates, and the Knowledge Map fact card. Since no behavior
changed, generated `.ppif`, support accounting, schedule/check/semantic JSON, and
HDL outputs remain at the `.347` state.
