# AXI IAL2 Manager Dynamic Burst-Length Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.238`

Date: 2026-06-22

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.238` ships the bounded report-only
dynamic raw-`ARLEN` burst-length shape selected by `.237`.

The public contract reuses the existing `read-data.read` `burst-length`
syntax. The accepted dynamic shape is exactly one transaction-local dynamic
read transaction, a generated `response-demux.read` in `burst-last` scope, a
one-bit `last-signal`, scalar last-beat dynamic read-data capture, and
`validation report-only`.

The support-accounted public sample is
`ppif/axi_manager_capacity_status_dynamic_read_data_burst_length.ppif`.

## Public Shape

The selected clause is:

```lisp
(read-data
  (read
    (capture-scope last-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (status-policy last-beat)
    (interleaving last-beat-by-rid)
    (burst-length
      (source arlen)
      (signal axi0_arlen (width 8))
      (encoding axlen-plus-one)
      (capture request)
      (max-beats 16)
      (validation report-only))
    (transaction r0
      (data-output axi0_r0_last_rdata)
      (status-output axi0_r0_last_rresp))))
```

It must be paired with:

- one `(id dynamic)` read transaction;
- `response-demux.read` with `(response-scope burst-last)`;
- a one-bit `last-signal`; and
- generated transaction completion.

## Generated Behavior

The generated IAL1/IAL0/SystemVerilog path now emits:

- generated `axi0_arlen` input metadata;
- per-transaction raw-`ARLEN` storage, for the public sample
  `axi0_r0_arlen_q`;
- request-guarded raw-`ARLEN` capture through
  `axi0_r0_burst_length_capture`;
- scalar last-beat `RDATA`/`RRESP` capture through
  `axi0_r0_read_data_capture`, still guarded by the generated dynamic
  last-beat completion pulse; and
- report fields including `burst_length_generated_behavior: true`,
  `burst_length_validation: report_only`,
  `generated_burst_length_inputs`, `generated_burst_length_storage`, and
  `generated_burst_length_rules`.

Schedule JSON reports
`generated_dynamic_read_response_demux_last_beat_completion_pulse` as the
read-data completion validity. Strict check JSON and semantic JSON now match
support-accounting entry
`intent.ppif_axi_manager_capacity_status_dynamic_read_data_burst_length`.

## Non-Generated Boundaries

This slice deliberately keeps the following fail-closed:

- dynamic `burst-length` on single-beat dynamic read-data;
- dynamic `burst-length` with `validation runtime-assertion`;
- dynamic multi-beat read-data output banks;
- multiple or mixed dynamic response demux;
- same-cycle dynamic recapture beyond the `.372` single-active burst-last
  response-demux state lifetime;
- dynamic same-ID ordering;
- queues and scoreboards;
- direct backend behavior; and
- VHDL behavior.

## Validation

Closeout validation covered syntax for touched modules and tests; direct
schedule/check/semantic/default-HDL probes for the new public sample; guarded
focused dynamic validation through
`t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t`; guarded support
accounting through `t/248-regression-corpus-accounting.t`; and a focused
runtime-validation fail-closed probe.

Full guarded `t/1436-ial2-ppif-parser-cli.t` and
`t/1437-axi-ial2-manager-capacity-status-generator.t` attempts were stopped
by the host-memory guard when host memory crossed the default 88% cutoff. The
bounded focused dynamic suite, direct generator/CLI probes, and doctrine gates
cover the new behavior for this slice.

## Rollback

Rollback is the `.238` implementation commit. Reverting it removes the public
dynamic burst-length PPIF sample, support-accounting entry, focused
validation, dynamic gate widening, and docs/fact-card updates, restoring
`.238` as the active frontier.
