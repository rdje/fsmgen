# AXI IAL2 Manager Same-ID Reuse Policy Contract Selection

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.91`

Date: 2026-06-14

## Purpose

This selector chooses the public AXI manager capacity/status source contract
that must exist before concrete-ID same-ID reuse can move from fail-closed
diagnostics toward per-ID issue-order queues or scoreboards.

It is documentation and task-tree state only. It does not change parser,
generator, `.isf`, `.fsm`, SystemVerilog, sample, support-accounting, check
JSON, semantic JSON, or validation behavior.

Follow-through: `IAL2-FEATURE-COMPLETENESS-FRONTIER.92` shipped this selected
contract in
[`AXI_IAL2_MANAGER_SAME_ID_REJECT_POLICY_FIRST_SLICE.md`](AXI_IAL2_MANAGER_SAME_ID_REJECT_POLICY_FIRST_SLICE.md).

## Inputs Read

- `docs/AXI_IAL2_MANAGER_PER_ID_QUEUE_READINESS_AUDIT.md`
- `docs/AXI_IAL2_MANAGER_CONCRETE_ID_SAME_ID_STATIC_VALIDATION_FIRST_SLICE.md`
- `docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_FIRST_SLICE.md`
- `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`
- `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`
- current `.ppif` manager-capacity parser shape
- public capacity/status `.ppif` samples
- focused generator and PPIF/CLI tests
- task tree, roadmap, mdBook, Memory, and Knowledge Map fact cards

## Selected Source Contract

Add one optional top-level clause under `manager-capacity-status`:

```lisp
(same-id-ordering
  (read
    (concrete-id-reuse reject))
  (write
    (concrete-id-reuse reject)))
```

The clause is AXI-profile-local and may appear at most once. Each family arm is
optional, but duplicate `read` or `write` arms fail closed. Each selected arm
requires exactly one `concrete-id-reuse` policy.

The first accepted policy is only:

```text
reject
```

`reject` means authored concrete-ID same-ID reuse in the selected response
family is intentionally rejected by public source policy. It does not accept
same-ID reuse, does not generate a queue, and does not change HDL behavior for
valid sources.

Future policy names such as `issue-order-queue` or `scoreboard` remain
deferred and must fail closed until a later task-tree owner selects their
behavior.

## Default Behavior

If `same-id-ordering` is omitted, today's behavior remains unchanged:
same-family concrete-ID reuse is rejected with the unselected-policy
diagnostic introduced by `.88`.

If `same-id-ordering` is present with `(concrete-id-reuse reject)`, duplicate
same-family concrete IDs are also rejected, but the diagnostic should identify
the selected reject policy rather than implying no policy was selected.

Read and write response families stay independent. Selecting a read policy
does not select a write policy, and vice versa.

## Report Contract

The first parser/report slice should publish additive metadata without
claiming generated queue behavior. The normalized report vocabulary should use
snake_case names:

```text
same_id_ordering.concrete_id_reuse_policy.<family>.policy: reject
same_id_ordering.concrete_id_reuse_policy.<family>.enforcement: static_validation
same_id_ordering.concrete_id_reuse_policy.<family>.accepted_same_id_reuse: false
same_id_ordering.concrete_id_reuse_policy.<family>.generated_queue_behavior: false
```

When generated auto-ID same-ID avoidance is also present, the report must
preserve that existing `same_id_ordering` section and add the concrete-ID
policy metadata without erasing generated auto-ID coverage.

`id_response_rule_engine.residue` remains honest. A selected reject policy does
not implement auto-ID allocation, ID release, concrete-ID response demux, or
accepted same-ID ordering behavior. The policy only explains why concrete-ID
same-ID reuse is rejected.

## Selected Next Slice

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.92`:

```text
Implement AXI same-ID reuse reject policy parser/report metadata and static validation.
```

The implementation should:

- parse the optional `same-id-ordering` clause;
- accept `read` and/or `write` family arms with `(concrete-id-reuse reject)`;
- reject duplicate family arms, missing `concrete-id-reuse`, duplicate policy
  clauses, and unsupported policy values;
- preserve omitted-policy behavior and diagnostics;
- emit policy-specific diagnostics for duplicate concrete IDs when explicit
  `reject` is selected;
- add additive schedule-report metadata for selected reject policies;
- keep generated `.isf`, `.fsm`, SystemVerilog, check JSON, and semantic JSON
  behavior unchanged except for the report metadata;
- keep per-ID issue-order queues, scoreboards, accepted same-ID reuse,
  concrete-ID response demux, queued/blocking policy, full-manager behavior,
  direct backend lowering, and VHDL deferred.

## Validation For `.92`

Focused implementation gates should include:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm
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

This selector changes no behavior. If `.92` finds that even explicit `reject`
policy metadata requires broader syntax or report restructuring, it must stop
and select that smaller prerequisite before behavior changes.
