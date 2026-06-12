# AXI IAL2 Manager Read Response-Demux Selection

This note records the selector outcome for
`IAL2-FEATURE-COMPLETENESS-FRONTIER.36`.

## Inputs Read

The selector reviewed the shipped AXI manager IAL2 path and current residue:

- `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`
- `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`
- `docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_FIRST_SLICE.md`
- `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md`
- `docs/AXI_IAL2_MANAGER_AUTO_ID_RESIDUE_ALIGNMENT_FIRST_SLICE.md`
- `docs/book/src/14-feature-backlog.md`
- `ROADMAP_V2.md`
- `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`
- `ppif/axi_manager_capacity_status_response_demux.ppif`

The current response-demux schedule report was inspected with:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_response_demux.ppif
```

## Finding

After generated write `BID` demux, auto-ID residue alignment, and generated
auto-ID same-ID avoidance, the current response-demux sample reports:

```text
auto_id_lifecycle.residue: []
response_demux.residue:
  - read_response_demux
  - read_data_interleaving
  - bursts
same_id_ordering.residue:
  - concrete_id_same_id_ordering
  - per_id_issue_order_queues
  - read_response_demux
  - read_data_interleaving
  - bursts
```

The remaining response-matching gap with the best immediate leverage is the
read side: `RID` must match `ARID`, same-`RID` responses are ordered by issue
order, and different read IDs can interleave. The current generator already
has read transaction metadata, read ID-family metadata, auto-ID request-ID
drive support for read families, concrete `ARID`/`RID` assertion input
support, and IAL1 rule-pulse completion support. However, read response demux
must be bounded carefully because full read-data interleaving/reassembly and
burst/last-beat semantics are larger than a write-style one-response pulse.

## Selected Next Slice

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.37`:

```text
Audit AXI read response-demux readiness after generated same-ID avoidance.
```

The next slice is a readiness audit, not an implementation. It should decide
whether the first read response-demux step can safely be:

- an explicit read-only opt-in contract analogous to the shipped write
  response-demux syntax;
- a bounded single-beat/non-burst `RID` match that generates transaction
  completion pulses;
- a metadata/static-validation slice before behavior;
- an IAL1/IAL0/SystemVerilog prerequisite for read completion pulse ownership;
- or a deferral until read-data interleaving/reassembly or burst/last-beat
  state has a smaller owner.

## Candidate Public Shape To Audit

The likely public shape, if the audit confirms it is honest, is additive under
the existing `response-demux` clause:

```text
(response-demux
  (read
    (response-event axi0_read_complete)
    (transaction-completion generated)))
```

The audit must decide whether `response-event` can mean a bounded accepted
single-beat read response event, whether the first implementation must require
explicit read `auto-id-lifecycle` metadata, and how to report any assumption
that full read-data interleaving/reassembly and bursts remain out of scope.

## Non-Goals

The selected readiness audit must not implement read `RID` behavior directly.
It must also keep these out of scope unless it explicitly selects a later
owner:

- read-data interleaving/reassembly;
- burst or last-beat tracking;
- per-ID same-ID response queues or scoreboards;
- authored concrete-ID same-ID ordering;
- queued/blocking policy;
- profile aliases or full AXI manager syntax;
- VHDL backend or VHDL reroute behavior.

## Validation Gates For `.37`

The readiness audit should include the AXI evidence, shipped response-demux
and same-ID docs, current generated report, focused generator/PPIF tests, and
the mdBook:

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
audit discovers that read `RID` demux needs code, tests, source syntax, report
shape, or generated-artifact changes, those changes must be owned by a later
task-tree leaf.
