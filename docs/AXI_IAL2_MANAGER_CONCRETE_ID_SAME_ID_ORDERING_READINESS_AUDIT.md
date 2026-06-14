# AXI IAL2 Manager Concrete-ID Same-ID Ordering Readiness Audit

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.87`

Date: 2026-06-14

## Purpose

This audit decides the next AXI manager feature-completeness boundary after
bounded burst-residue alignment left only `concrete_id_same_id_ordering` and
`per_id_issue_order_queues` under the public multi-beat sample's
`same_id_ordering.residue`.

It is documentation and task-tree state only. It does not change parser,
generator, `.isf`, `.fsm`, SystemVerilog, sample, support-accounting, check
JSON, semantic JSON, or validation behavior.

## Inputs Read

- `docs/AXI_IAL2_MANAGER_POST_BURST_RESIDUE_NEXT_SLICE_SELECTION.md`
- `docs/AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE.md`
- `docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_READINESS_AUDIT.md`
- `docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_FIRST_SLICE.md`
- `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`
- `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`
- `docs/AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_READINESS_AUDIT.md`
- `docs/AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_SELECTION.md`
- live schedule JSON for
  `ppif/axi_manager_capacity_status_read_data_multi_beat.ppif`,
  `ppif/axi_manager_capacity_status_transaction_envelope.ppif`,
  `ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif`, and
  `ppif/axi_manager_capacity_status_response_demux.ppif`
- focused generator and PPIF/CLI tests around concrete-ID assertions,
  transaction event dispatch, response demux, and same-ID ordering metadata
- current implementation entrypoints:
  `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm` and
  `perl/FSM/Adapter/IAL2/PPIF.pm`
- IAL2 architecture decisions `0014`, `0015`, and `0018`

## Live Findings

The public generated auto-ID multi-beat sample reports:

```text
read_data.residue: []
response_demux.residue: []
same_id_ordering.residue:
  - concrete_id_same_id_ordering
  - per_id_issue_order_queues
```

The concrete-ID transaction samples report two equality assertions and still
leave same-ID ordering unresolved under `id_response_rule_engine.residue`:

```text
id_response_rule_engine.residue:
  - auto_id_allocation
  - id_release
  - same_id_ordering
  - response_demux
```

An in-memory generator probe with two read transactions using concrete ID `3`
and unique request/completion events is currently accepted. It emits four
request/response equality assertions and leaves:

```text
id_response_rule_engine.residue:
  - auto_id_allocation
  - id_release
  - same_id_ordering
  - response_demux
```

That proves the current concrete-ID assertion slice checks only that the
request and response ID signals equal the authored constant. It does not
preserve same-ID response issue order when more than one authored transaction
can share that ID.

## Readiness Conclusion

The next implementation should be a conservative static fail-closed diagnostic
for multiple authored concrete-ID transactions in the same response family
that use the same concrete ID value.

This does not require generated per-ID issue-order queue substrate first. The
safe near-term behavior is to reject unsupported concrete same-ID reuse until
a later exact owner selects one of these broader policies:

- generated per-ID issue-order queues or scoreboards;
- explicit public same-ID reuse policy with queue/block/reject semantics;
- stronger mutually-exclusive transaction assumptions with runtime checking;
- full manager issue scheduling that can serialize same-ID requests.

Runtime assertions alone are not enough for the next slice. Existing
assertions can prove `ARID == N` and `RID == N` or `AWID == N` and
`BID == N`, but they cannot prove response issue order without an issue-order
record, per-ID queue, scoreboard, or a selected static rejection rule.

## Selected Next Slice

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.88`:

```text
Implement AXI concrete-ID same-ID fail-closed static validation.
```

The `.88` implementation should:

- reject two or more concrete-ID transactions in the same `read` or `write`
  family when they use the same concrete ID value;
- keep read and write ID families separate, because AXI uses separate
  response families for `ARID/RID` and `AWID/BID`;
- preserve existing duplicate event diagnostics for non-unique request or
  completion events;
- leave generated auto-ID same-ID avoidance unchanged;
- leave single concrete-ID transaction samples unchanged;
- keep `id_response_rule_engine.residue` honest for successful concrete-ID
  samples until same-ID ordering is actually implemented;
- add focused generator and PPIF/CLI tests for the new diagnostic.

## Non-Goals

`.88` must not implement:

- per-ID issue-order queues or response scoreboards;
- concrete-ID same-ID ordering behavior;
- new public syntax;
- generated response-demux behavior for concrete IDs;
- generated `.isf`, `.fsm`, or HDL behavior changes for currently valid
  samples;
- read/write cross-family ordering;
- queued/blocking policy;
- profile aliases;
- full-manager behavior;
- verification-code generation;
- direct backend lowering;
- VHDL behavior.

## Validation For `.88`

Focused implementation gates should include:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t
perl -Iperl -c t/1436-ial2-ppif-parser-cli.t
prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t
prove -Iperl t/1436-ial2-ppif-parser-cli.t
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_transaction_envelope.ppif
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_multi_beat.ppif
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

This audit creates no behavior change. If `.88` discovers that the diagnostic
cannot be implemented without new public policy syntax or queue substrate, it
must stop and select that smaller prerequisite before changing behavior.
