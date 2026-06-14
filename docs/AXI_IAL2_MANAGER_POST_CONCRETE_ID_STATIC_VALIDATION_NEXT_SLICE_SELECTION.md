# AXI IAL2 Manager Post Concrete-ID Static Validation Next Slice Selection

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.89`

Date: 2026-06-14

## Purpose

This selector chooses the next AXI manager feature-completeness owner after
`IAL2-FEATURE-COMPLETENESS-FRONTIER.88` shipped fail-closed static validation
for unsupported same-family concrete-ID reuse.

It is documentation and task-tree state only. It does not change parser,
generator, `.isf`, `.fsm`, SystemVerilog, sample, support-accounting, check
JSON, semantic JSON, or validation behavior.

## Inputs Read

- `docs/AXI_IAL2_MANAGER_CONCRETE_ID_SAME_ID_STATIC_VALIDATION_FIRST_SLICE.md`
- `docs/AXI_IAL2_MANAGER_CONCRETE_ID_SAME_ID_ORDERING_READINESS_AUDIT.md`
- `docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_FIRST_SLICE.md`
- `docs/AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE.md`
- `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`
- `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`
- live schedule JSON for:
  - `ppif/axi_manager_capacity_status_read_data_multi_beat.ppif`
  - `ppif/axi_manager_capacity_status_transaction_envelope.ppif`
  - `ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif`
- focused generator and PPIF/CLI diagnostics around concrete-ID same-ID reuse
- task tree, roadmap, mdBook, Memory, and Knowledge Map fact cards

## Live State After `.88`

The public generated auto-ID multi-beat sample still reports:

```text
read_data.residue: []
response_demux.residue: []
same_id_ordering.residue:
  - concrete_id_same_id_ordering
  - per_id_issue_order_queues
```

The concrete-ID envelope and dispatch samples still report two equality checks
and:

```text
id_response_rule_engine.residue:
  - auto_id_allocation
  - id_release
  - same_id_ordering
  - response_demux
```

That residue is still honest. `.88` rejects unsupported same-family
concrete-ID reuse; it does not implement accepted same-ID reuse behavior,
issue-order state, per-ID queues, response scoreboards, or a public same-ID
reuse policy.

## Selection

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.90`:

```text
Audit AXI per-ID issue-order queue readiness after concrete-ID static validation.
```

The readiness audit should decide the next exact boundary before behavior
changes. In particular, it must determine whether the next owner should be:

- public same-ID reuse policy selection;
- generated per-ID issue-order queue or scoreboard substrate;
- concrete-ID response-demux prerequisites;
- report/static residue refinement after the fail-closed boundary;
- a smaller IAL1/IAL0/SystemVerilog storage, queue, or assertion prerequisite;
- or a deliberate deferral in favor of queued/blocking policy, profile aliases,
  full-manager behavior, verification-code generation, direct backend work, or
  VHDL.

## Why Not Implement Queues Directly

Per-ID issue-order queues affect public source semantics, generated IAL1 state,
generated `.fsm` storage and rules, response demux ownership, diagnostics, and
schedule-report contracts. The current public `.ppif` syntax only expresses
transaction IDs and concrete/auto ID policy; it does not yet express whether
same-ID reuse should be rejected, queued, stalled, blocked, or accepted with a
specific ordering/scoreboard strategy.

Direct queue behavior would therefore be premature without first auditing the
required public contract and lowering substrate.

## Why Not Do Report-Only Alignment First

The post-`.88` residue is not stale. It still says accepted concrete-ID
same-ID ordering behavior and per-ID issue-order queues are not implemented.
The next useful narrowing must be driven by whether the system is ready to
model same-ID issue-order state or whether a public policy selector is needed
first.

## Validation For This Selector

Selector gates:

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

## Rollback Boundary

This selector changes no behavior. If `.90` finds that per-ID issue-order
queues require public policy syntax, a smaller IAL1/IAL0 substrate, or another
precondition, it must select that next owner before implementation.
