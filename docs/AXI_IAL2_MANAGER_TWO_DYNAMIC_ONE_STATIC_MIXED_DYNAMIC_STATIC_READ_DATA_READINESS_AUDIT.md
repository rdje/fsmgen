# AXI IAL2 Manager Two-Dynamic/One-Static Mixed Dynamic/Static Read-Data Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.359`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.359` audits scalar single-beat read-data
readiness over the `.344` generated two-dynamic-plus-one-static mixed
dynamic/static read single-beat `RID` response-demux.

The audit selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.360`, public contract
selection for scalar single-beat `RDATA`/`RRESP` capture over that exact
demux. It changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, or HDL behavior.

## Current Boundary

The `.344` response-demux sample is already support-accounted:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif
```

It covers dynamic reads `r0` and `r1`, concrete static read `r2` at ID `3`,
`response-scope single-beat`, response-demux mode
`bounded_multi_mixed_dynamic_static_read_rid_demux_contract`, and completion
source `generated_multi_mixed_dynamic_static_read_demux`.

Existing scalar single-beat read-data behavior over generated multiple mixed
dynamic/static read demux already defines the expected public shape:

```lisp
(read-data
  (read
    (capture-scope single-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (interleaving single-beat-by-rid)
    (transaction r0
      (data-output axi0_r0_rdata)
      (status-output axi0_r0_rresp))
    (transaction r1
      (data-output axi0_r1_rdata)
      (status-output axi0_r1_rresp))
    (transaction r2
      (data-output axi0_r2_rdata)
      (status-output axi0_r2_rresp))))
```

## Current Hard Stop

The current hard stop is local and intentional. The
`_read_data_response_demux_transaction_coverage` branch for generated
multiple mixed dynamic/static read demux admits:

- one dynamic plus two static read transactions for scalar single-beat and
  scalar last-beat read-data;
- one dynamic plus three static read transactions for scalar single-beat and
  scalar last-beat read-data;
- two dynamic plus one static read transactions for scalar last-beat
  read-data over burst-last response-demux;
- two dynamic plus one static read transactions for report-only raw-`ARLEN`
  scalar last-beat read-data;
- two dynamic plus one static read transactions for runtime-validation scalar
  last-beat read-data; and
- two dynamic plus one static read transactions for runtime-validation
  multi-beat output banks.

It does not yet admit two dynamic plus one static read transactions for
scalar single-beat read-data over the `.344` single-beat demux. That keeps the
candidate fail-closed until a contract owner chooses the exact public shape.

## Selected Next Contract Owner

`.360` must settle the exact public contract before implementation. The
selected candidate surface is:

```text
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data.ppif
intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data
ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data_pipeline_cli
mixed_dynamic_static_read_data_multi_dynamic
```

The contract should preserve the `.344` response-demux report mode and source:

```text
response_demux.read.mode = bounded_multi_mixed_dynamic_static_read_rid_demux_contract
response_demux.read.transaction_completion_source =
  generated_multi_mixed_dynamic_static_read_demux
response_demux.read.transaction_completion_semantics =
  matched_dynamic_or_static_concrete_id_single_beat
```

The read-data report should use the existing scalar single-beat vocabulary:

```text
read_data.mode = bounded_single_beat_read_data_contract
read_data.read.completion_validity =
  generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse
read_data.read.transactions = r0, r1, r2
read_data.read.generated_inputs = axi0_rdata, axi0_rresp
read_data.read.generated_outputs =
  axi0_r0_rdata, axi0_r0_rresp,
  axi0_r1_rdata, axi0_r1_rresp,
  axi0_r2_rdata, axi0_r2_rresp
read_data.read.generated_rules =
  axi0_r0_read_data_capture,
  axi0_r1_read_data_capture,
  axi0_r2_read_data_capture
read_data.residue =
  rlast_completion, bursts, multi_beat_read_data_reassembly
```

The implementation owner after `.360` should only widen scalar no-`ARLEN`
single-beat read-data coverage for this exact two-dynamic-plus-one-static
transaction set. It should not widen broader mixed cardinalities,
same-cycle behavior, release-and-recapture, dynamic same-ID queues,
scoreboards, direct backend behavior, backend-language variants, VHDL,
profile aliases, queued/blocking policy, or full-manager behavior.

## Validation Plan

`.360` is a selector and should remain documentation-only. The later behavior
owner should validate:

- syntax checks for touched Perl modules and focused tests;
- guarded direct schedule/check/semantic/default-HDL/`--verify-hdl` probes for
  the new public sample;
- schedule JSON assertions for the preserved `.344` response-demux mode/source
  plus the new scalar single-beat read-data report fields;
- strict check JSON support-accounting for the new public sample;
- focused `t/1438` coverage for `mixed_dynamic_static_read_data_multi_dynamic`,
  with CLI JSON skipped only if the RAM guard trips at the default cutoff;
- `t/248-regression-corpus-accounting.t`; and
- preservation checks for `.344`, `.347`, `.350`, `.357`, the two-static and
  three-static mixed scalar read-data samples, and representative all-dynamic
  read-data.

## Rollback

Rollback for `.359` is documentation-only: revert this audit, the
task-tree/MEMORY/README/ROADMAP/mdBook updates, and the Knowledge Map fact
card. Since no behavior changed, generated `.ppif`, support accounting,
schedule/check/semantic JSON, and HDL outputs remain at the `.358` state.
