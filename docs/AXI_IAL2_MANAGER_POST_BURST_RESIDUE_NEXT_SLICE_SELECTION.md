# AXI IAL2 Manager Post-Burst-Residue Next Slice Selection

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.86`

Date: 2026-06-14

## Selection Context

After `.85`, the public multi-beat read-data sample reports:

```text
read_data.residue: []
auto_id_lifecycle.residue: []
response_demux.residue: []
same_id_ordering.residue:
  - concrete_id_same_id_ordering
  - per_id_issue_order_queues
```

The generated auto-ID path already has same-ID ordering by avoidance: the
allocator does not issue two active generated auto-ID transactions with the
same selected ID, and generated assertions make that invariant explicit.

The remaining same-ID work is now the authored/concrete-ID side. Existing
concrete-ID slices generate request/response ID equality assertions, but they
do not decide what happens when multiple authored transactions intentionally
share an ID. AXI source evidence says same-ID responses are ordered by issue
order inside their response families, which normally implies per-ID
issue-order queues or an explicit fail-closed constraint.

## Inputs Read

- `docs/AXI_IAL2_MANAGER_BURST_RESIDUE_ALIGNMENT_FIRST_SLICE.md`
- `docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_FIRST_SLICE.md`
- `docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_READINESS_AUDIT.md`
- `docs/AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE.md`
- `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`
- `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`
- `docs/decisions/0014-protocol-platform-intent-surface-and-layered-lowering.md`
- `docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md`
- `docs/decisions/0018-ial-contracts-are-backend-language-neutral.md`
- live schedule JSON for
  `ppif/axi_manager_capacity_status_read_data_multi_beat.ppif`,
  `ppif/axi_manager_capacity_status_transaction_envelope.ppif`, and
  `ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif`
- focused generator and PPIF/CLI tests around concrete IDs and same-ID
  ordering metadata

## Selection

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.87`:

```text
Audit AXI concrete-ID same-ID ordering readiness after bounded burst residue alignment.
```

The audit should decide whether the next implementation can be a conservative
concrete-ID same-ID constraint, a report/static classification slice, a public
contract selection, or whether generated per-ID issue-order queue substrate is
required first.

The audit must explicitly evaluate these possible boundaries before any code
changes:

- fail-closed diagnostics when multiple active concrete-ID transactions can
  share an ID without selected queue semantics;
- runtime assertions for concrete-ID same-ID ordering when the events are
  already uniquely bound and response-demux semantics are sufficient;
- parser/report metadata for declaring an authored same-ID policy;
- generated per-ID issue-order queues or response scoreboards;
- whether write and read response families need separate first slices;
- how the result affects `same_id_ordering.residue` and
  `id_response_rule_engine.residue`.

## IAL2 Factoring Guidance

The user raised whether IAL2 should have shared common constructs or become
only protocol/platform-specific vocabulary. The current selector answer is a
conservative hybrid:

- keep IAL2 as one backend-neutral semantic layer;
- keep the generic `.ppif` container and mandatory
  `IAL2 -> IAL1/.isf -> IAL0/.fsm -> HDL` lowering chain;
- allow protocol/profile vocabularies such as AXI to own protocol-specific
  rules;
- promote a construct into common IAL2 only after at least two profiles need
  the same concept with compatible semantics;
- avoid making an AXI-shaped construct common just because AXI needed it first.

For the selected `.87` audit, concrete-ID same-ID ordering remains AXI
profile vocabulary. If later protocols need the same abstract concept, the
future owner can factor a shared IAL2 construct with evidence instead of
guessing now.

## Non-Goals

`.87` should not implement:

- per-ID issue-order queues or scoreboards;
- concrete-ID same-ID ordering behavior;
- new public syntax;
- generated `.isf`, `.fsm`, or HDL behavior changes;
- packed/full burst assembly;
- queued/blocking policy;
- profile aliases;
- full-manager behavior;
- verification-code generation;
- direct backend lowering;
- VHDL behavior.

## Validation For `.87`

The audit should include:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_multi_beat.ppif
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_transaction_envelope.ppif
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
```

If `.87` discovers that concrete-ID same-ID ordering cannot be audited without
implementing queue substrate or new syntax, it must stop at that finding and
select the smallest next owner before any behavior-bearing change.
