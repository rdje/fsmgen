# AXI IAL2 Manager Post Response-Demux Residue Alignment Selection

This note records the selector outcome for
`IAL2-FEATURE-COMPLETENESS-FRONTIER.31`.

## Inputs Read

The selector reviewed the shipped IAL2 AXI manager path through generated
write `BID` response demux:

- `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md`
- `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT.md`
- `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md`
- `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md`
- `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`
- `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`
- `docs/book/src/14-feature-backlog.md`
- `ROADMAP_V2.md`
- `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- `ppif/axi_manager_capacity_status_response_demux.ppif`

The selector also inspected the post-`.30` schedule report with:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_response_demux.ppif
```

## Finding

The generated response-demux report is now behavior-bearing and current:

```text
response_demux.generated_behavior: true
response_demux.residue:
  - read_response_demux
  - same_id_ordering
  - read_data_interleaving
  - bursts
id_response_rule_engine.residue:
  - same_id_ordering
```

However, the same report still leaves `response_demux` in
`auto_id_lifecycle.residue`:

```text
auto_id_lifecycle.residue:
  - same_id_ordering
  - response_demux
```

That was accurate before `.30`, when auto-ID release could not yet be driven by
generated demux completion pulses. After `.30`, explicit write response-demux
contracts generate the completion pulses consumed by auto-ID release, so the
remaining `auto_id_lifecycle.residue` entry is stale report-contract drift.

## Selected Next Slice

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.32`:

```text
Align auto-ID lifecycle report residue after generated write response-demux behavior.
```

The slice is intentionally narrow. It should remove `response_demux` from
`auto_id_lifecycle.residue` when explicit
`response_demux.generated_behavior` is true, and prove generated `.isf`,
generated `.fsm`, and SystemVerilog HDL text do not change.

## Non-Goals

The selected slice must not implement:

- read `RID` response demux;
- same-ID response ordering queues;
- read-data interleaving/reassembly;
- bursts or last-beat tracking;
- queued/blocking policy;
- profile aliases or full AXI manager syntax;
- VHDL backend or VHDL reroute behavior.

Those remain future exact-owner work after the report-contract drift is fixed.

## Validation Gates For `.32`

Focused gates should include:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t
prove -Iperl t/1436-ial2-ppif-parser-cli.t
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_response_demux.ppif
```

Continuity gates should include:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
```

## Rollback Boundary

The `.32` implementation should be a report-contract cleanup only. If it
touches generated IAL1, IAL0, or HDL behavior, split that work into a separate
task-tree leaf before proceeding.
