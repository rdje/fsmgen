# AXI IAL2 Manager Same-ID Ordering Readiness Selection

This note records the selector outcome for
`IAL2-FEATURE-COMPLETENESS-FRONTIER.33`.

## Inputs Read

The selector reviewed the shipped AXI manager IAL2 path and remaining residue:

- `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`
- `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`
- `docs/AXI_IAL2_MANAGER_AUTO_ID_RESIDUE_ALIGNMENT_FIRST_SLICE.md`
- `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md`
- `docs/book/src/14-feature-backlog.md`
- `ROADMAP_V2.md`
- `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- `ppif/axi_manager_capacity_status_response_demux.ppif`

The post-`.32` schedule report was inspected with:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_response_demux.ppif
```

## Finding

After generated write `BID` demux and auto-ID residue alignment, the report
now consistently leaves `same_id_ordering` as the common ID/auto-ID/write-demux
residue:

```text
auto_id_lifecycle.residue:
  - same_id_ordering

id_response_rule_engine.residue:
  - same_id_ordering

response_demux.residue:
  - read_response_demux
  - same_id_ordering
  - read_data_interleaving
  - bursts
```

The AXI evidence and rule matrix say same-ID read and write responses are
ordered by issue order inside their response families. The current generated
write response-demux slice can match `BID` against active selected IDs and
assert that a response matches at most one active auto-ID write transaction,
but it does not yet select an ordering model for same-ID issue, same-ID
response queues, or stronger allocation constraints.

## Selected Next Slice

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.34`:

```text
Audit AXI same-ID ordering readiness after generated write response demux.
```

The next slice is a readiness audit, not an implementation. It should decide
whether the first same-ID ordering step should be:

- static/report-only classification of same-ID ordering requirements;
- a generated assertion boundary over ambiguous same-ID outstanding state;
- an auto-ID allocator constraint that prevents multiple active transactions
  from sharing a selected ID;
- a per-ID issue-order queue or scoreboard prerequisite;
- or a smaller IAL1/IAL0/SystemVerilog prerequisite before any of those.

## Non-Goals

The selected readiness audit must not implement ordering behavior directly.
It must also keep these out of scope unless it explicitly selects a later
owner:

- read `RID` response demux;
- read-data interleaving/reassembly;
- bursts or last-beat tracking;
- queued/blocking policy;
- profile aliases or full AXI manager syntax;
- VHDL backend or VHDL reroute behavior.

## Validation Gates For `.34`

The readiness audit should include the AXI evidence and generated-artifact
surfaces:

```bash
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

This selector is documentation and task-tree state only. If the readiness
audit discovers that same-ID ordering needs code, tests, source syntax, report
shape, or generated-artifact changes, those changes must be owned by a later
task-tree leaf.
