# AXI IAL2 Manager RLAST Completion Behavior Readiness Audit

Status: selected direct generated behavior implementation next; no parser,
generator, HDL, sample, CLI, or test behavior changed by this audit.

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.52`.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Builds on:

- [docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_METADATA_FIRST_SLICE.md](AXI_IAL2_MANAGER_RLAST_COMPLETION_METADATA_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_CONTRACT_SELECTION.md](AXI_IAL2_MANAGER_RLAST_COMPLETION_CONTRACT_SELECTION.md)
- [docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md](AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md)
- [docs/AXI_IAL2_MANAGER_READ_DATA_METADATA_FIRST_SLICE.md](AXI_IAL2_MANAGER_READ_DATA_METADATA_FIRST_SLICE.md)

## Purpose

This audit decides whether the shipped `response-scope burst-last` metadata
can move directly to generated `RLAST` completion behavior, or whether a
smaller IAL1, IAL0/SystemVerilog, report, or static-validation prerequisite
must land first.

The selected next owner is direct generated behavior. The existing
SystemVerilog-backed lowering path already supports the required pieces:
width-bearing generated inputs, one-bit generated pulse outputs, guarded
rules, assertion carriers, generated artifact reporting, read capacity
release, and read auto-ID release.

## Inputs Read

The audit read:

- the `.51` metadata note and checked-in burst-last sample;
- schedule JSON for
  `ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif`;
- focused generator and PPIF tests proving `.51` leaves generated IAL1/IAL0
  artifacts unchanged from the read auto-ID lifecycle baseline;
- the shipped single-beat read response-demux behavior implementation and
  report docs;
- the shipped single-beat read-data capture behavior and the `.51` rejection
  of read-data paired with burst-last response demux;
- the auto-ID lifecycle release and same-ID report/coverage helpers;
- the IAL1 rule, interface, pulse, and assertion generation helpers;
- the mdBook, roadmap, task tree, and Knowledge Map.

## Readiness Findings

No new lower-layer substrate is required.

The existing response-demux generation path already emits generated completion
outputs, guarded pulse rules, response-ID inputs, active-match assertions,
unique-match assertions, report artifacts, auto-ID lifecycle residue removal,
and same-ID `response_demux_covered` residue movement for generated families.

The burst-last behavior can reuse that path with bounded additions:

- include the configured one-bit `last_signal` as a generated IAL1 input;
- keep `response_event` as the raw accepted read response beat input;
- keep `response_id_signal` as the generated `RID` input;
- emit one generated completion pulse output per read auto-ID transaction;
- guard each read response-demux pulse by `response_event`, the transaction
  busy bit, matching `RID`, and asserted `last_signal`;
- keep the existing active-match and unique-match assertions on accepted read
  response beats, so every accepted beat still has an active matching RID and
  at most one matching transaction;
- drive read capacity release and read auto-ID release from the generated
  transaction completion pulses, which now occur only on matched last beats;
- mark read same-ID ordering as response-demux-covered once burst-last read
  demux behavior is generated;
- leave read-data capture disabled for burst-last contracts.

The behavior must not infer burst length, `ARLEN`, missing-beat validation,
extra-beat validation, per-transaction beat-valid outputs, multi-beat
`RDATA`/`RRESP` reassembly, or per-ID response queues.

## Expected Report Movement

The next behavior slice should change the burst-last sample report to:

```text
response_demux.generated_behavior: true
response_demux.read.generated_behavior: true
response_demux.read.response_scope: burst_last
response_demux.read.last_signal: axi0_rlast
response_demux.read.transaction_completion_source: generated_demux_last_beat
response_demux.read.transaction_completion_semantics: matched_rid_and_last_signal
response_demux.read.generated_rules:
  - axi0_r0_response_demux
  - axi0_r1_response_demux
response_demux.read.generated_completion_signals:
  - axi0_r0_complete
  - axi0_r1_complete
response_demux.read.generated_assertions:
  - axi0_read_response_demux_active_match
  - axi0_r0_r1_read_response_demux_unique_match
response_demux.residue:
  - read_data_interleaving
  - bursts
```

For the same sample, `auto_id_lifecycle.residue` should remove
`response_demux`, and the read same-ID family should report
`response_demux_covered: true`.

## Expected Generated Artifacts

Generated IAL1 should add:

```text
(input axi0_read_complete)
(input axi0_rid (width 4))
(input axi0_rlast)
(output axi0_r0_complete)
(output axi0_r1_complete)
```

Generated read demux rules should use a last-beat guard:

```text
(rule axi0_r0_response_demux
  (& axi0_read_complete axi0_r0_auto_id_busy_q
     (== axi0_rid axi0_r0_auto_id_q)
     axi0_rlast)
  (pulse axi0_r0_complete))
```

The generated `.fsm` and SystemVerilog should carry those inputs, outputs,
rules, and assertions through the existing `IAL2 -> IAL1 -> IAL0 ->
SystemVerilog` path. The sample must pass `--verify-hdl`.

## Diagnostics And Guardrails

The `.51` static diagnostics remain the behavior-slice guardrails:

- unsupported response scopes still fail closed;
- `last-signal` remains illegal on `single-beat`;
- `burst-last` still requires exactly one width-1 `last-signal`;
- name collisions involving the `last-signal` still fail closed;
- read-data remains rejected with burst-last response demux until a later
  reassembly contract selects behavior.

The next slice should add positive checks for generated `RLAST` behavior and
keep the negative diagnostics already covered by `.51`.

## Selected Next Slice

`IAL2-FEATURE-COMPLETENESS-FRONTIER.53` should implement generated
burst-last/`RLAST` completion behavior directly.

The behavior scope is intentionally narrow: generate the `RLAST` input,
generated `RID` input, last-beat completion pulse outputs/rules/assertions,
report artifacts, auto-ID lifecycle residue movement, same-ID report movement,
and HDL reachability for the existing burst-last sample. Do not extend
`read-data`, do not add beat-count or `ARLEN` metadata, do not generate
per-beat outputs, and do not reopen VHDL or direct backend lowering.
