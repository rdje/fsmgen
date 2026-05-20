# ISF-LOWERINGIR-BOUNDARY-EXTRACTION: Private LoweringIR Boundary Extraction

## Metadata

- Tree ID: `ISF-LOWERINGIR-BOUNDARY-EXTRACTION`
- Status: `active`
- Roadmap lane: `architecture backlog`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Reduce private ISF `LoweringIR` growth by identifying stable sub-boundaries
that can move into helper owners or typed private carriers while preserving
the current public contract: emitted `.fsm`, schedule JSON, generated
composition artifacts, and HDL behavior.

## Non-Goals

- Do not expose raw `LoweringIR` hashes as public API.
- Do not change schedule JSON schema, generated state naming, generated child
  artifact shape, or emitted HDL unless a later behavior-bearing leaf
  explicitly selects that change.
- Do not split `LoweringIR` only for line count. Each extraction must have a
  stable owner and invariant.

## Acceptance Criteria

- Stable `LoweringIR` subfamilies are inventoried with owners, invariants, and
  public projection points.
- At least one safe extraction or typed-private-carrier candidate is selected,
  or the tree records why no extraction is justified.
- Implementation leaves preserve schedule JSON/artifact behavior unless the
  selected leaf explicitly says otherwise.
- Focused ISF schedule/report tests and broader gates run when behavior-bearing
  code changes land.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-LOWERINGIR-BOUNDARY-EXTRACTION`
  Status: `active`
  Goal: `Extract stable private LoweringIR sub-boundaries where justified.`
  Children: `ISF-LOWERINGIR-BOUNDARY-EXTRACTION.1`,
  `ISF-LOWERINGIR-BOUNDARY-EXTRACTION.2`,
  `ISF-LOWERINGIR-BOUNDARY-EXTRACTION.3`

- ID: `ISF-LOWERINGIR-BOUNDARY-EXTRACTION.1`
  Status: `done`
  Goal: `Inventory stable LoweringIR subfamilies and projection points.`
  Acceptance: `Actor-network, domain/CDC, storage/provenance, activation
  handoff, and generated-composition subfamilies are mapped with invariants
  and report/artifact consumers.`
  Verification: `static LoweringIR/emitter inventory`; `git diff --check`; `mdbook build docs/book`
  Commit: `ISF-LOWERINGIR-BOUNDARY-EXTRACTION.1: inventory LoweringIR subfamilies`

- ID: `ISF-LOWERINGIR-BOUNDARY-EXTRACTION.2`
  Status: `active`
  Goal: `Select one private extraction candidate.`
  Acceptance: `The selected candidate names its owner, inputs, outputs,
  invariants, unchanged public surfaces, and focused tests before code
  changes begin.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-LOWERINGIR-BOUNDARY-EXTRACTION.3`
  Status: `proposed`
  Goal: `Implement the selected private LoweringIR extraction.`
  Acceptance: `The selected subfamily moves behind the new owner/carrier with
  unchanged public schedule/artifact behavior and passing focused gates.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

The active frontier is `ISF-LOWERINGIR-BOUNDARY-EXTRACTION.2`, which must
select one private extraction candidate before source changes begin.

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-LOWERINGIR-BOUNDARY-EXTRACTION.1` | `done` | Stable subfamily inventory completed before private extraction. |
| 2 | `ISF-LOWERINGIR-BOUNDARY-EXTRACTION.2` | `active` | Select one extraction candidate with unchanged public surfaces and focused tests. |
| 3 | `ISF-LOWERINGIR-BOUNDARY-EXTRACTION.3` | `proposed` | Implement only after `.2` selects the owner and invariants. |

## Decisions

- `2026-05-20`: Selected as an actionable follow-up from
  `FSMGEN-IR-AUDIT.4` because `LoweringIR` is a legitimate private scheduler
  boundary but now owns enough stable feature families that helper-owner
  extraction should be considered deliberately.
- `2026-05-20`: Completed the `.1` inventory. Stable candidates exist, but
  raw `LoweringIR` remains private; public truth is still emitted `.fsm`,
  schedule JSON schema/versioned projections, generated composition artifacts,
  and HDL behavior.

## Open Questions

- Which `LoweringIR` subfamily is stable enough to extract first without
  widening public API?

## Blockers

- None while proposed.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `ISF-LOWERINGIR-BOUNDARY-EXTRACTION.1` | `rg -n 'LoweringIR|Emitter::FSM|Emitter::JSON|Emitter::CompositionTop|schedule JSON|lowering_ir' perl/FSM/Scheduler/ISF.pm perl/FSM/Scheduler/ISF docs/tasks/ISF-LOWERINGIR-BOUNDARY-EXTRACTION.md docs/tasks/FSMGEN-IR-AUDIT.md ROADMAP_STATUS.md`; `rg -n '^sub ' perl/FSM/Scheduler/ISF/LoweringIR.pm`; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-LOWERINGIR-BOUNDARY-EXTRACTION.1` | `ISF-LOWERINGIR-BOUNDARY-EXTRACTION.1: inventory LoweringIR subfamilies` | Inventories stable private subfamilies and projection points. |

## Changelog

- `2026-05-20`: Created proposed follow-up task tree from
  `FSMGEN-IR-AUDIT.4`.
- `2026-05-20`: Activated `.1`, inventoried stable private subfamilies, and
  advanced `.2` for candidate selection.

## LoweringIR Subfamily Inventory

`FSM::Scheduler::ISF::LoweringIR` is still one private scheduler phase
boundary. The following subfamilies are stable enough to reason about as
candidate helper-owner boundaries, but none is a public API by itself.

| Subfamily | Current owner/functions | Private IR fields | Public projection points | Invariants to preserve |
| --- | --- | --- | --- | --- |
| Scheduler root and emitter handoff | `build_module`, `_build_parent_ir`, `_build_child_ir`, `_build_library_child_ir`, `_build_resolved_atl_child_ir`; consumed by `Emitter::FSM`, `Emitter::JSON`, and `Emitter::CompositionTop`. | Parent/child IR hashes with `actor_name`, timing, ports, states, `dt_blocks`, children, and metadata. | Scheduled `.fsm`, schedule JSON `schema_version: 1`, generated top/child artifacts, and HDL generated from those artifacts. | Raw hashes stay private; emitters must continue to consume one coherent private IR with unchanged public artifact shape. |
| Actor-network / ATL metadata | `_actor_network_for_ir`, `_select_atl_generated_top_instances`, `_atl_generated_top_data_links`, `_atl_generated_top_report_entry`, `_mark_atl_data_link_child_interface_ports`, and ATL validation helpers. | `actor_network`, `atl_top_instances`, ATL child entries, data links, generated top metadata. | Schedule JSON `actor_network.*`, generated ATL top `.fsm`/`?top` artifacts, and generated child interface metadata. | Bounded ATL v0 behavior remains unchanged; fail-closed unsupported routes stay fail-closed; report keys remain bounded projections. |
| Domain / CDC partitioning | `_build_domain_partition`, `_validate_*_domain_refs`, `_register_domain_signal`, `_domain_for_entry`, `_actor_domain_signal_map`, `_validate_drive_reuse_domains`. | `domain_partition`, `domains[]`, `crossings[]`, domain ports/storage/transactions/rules/library uses/child instances. | Schedule JSON `clock_domains[]` and `crossings[]`, multi-domain top/domain `.fsm` artifacts, CDC module artifacts. | Domain validation must reject unowned cross-domain access before emission; public JSON remains a bounded projection, not raw partition internals. |
| Activation handoff and generated children | `_collect_generated_child_transaction_refs`, `_register_generated_activation_instance`, `_ir_do`, `_ir_spawn`, activation parameter/binding/domain helpers, transaction-port binding helpers. | `children`, `spawn_instances`, generated child ports, activation binding handoff assignments, transaction port binding metadata. | Generated child `.fsm` files, generated composition top, schedule JSON generated-composition summaries and transaction port bindings. | Generated names, start/done handshakes, parameter overrides, bindings, and done-port drain semantics remain stable. |
| Storage roles, widths, bank access, and provenance | `_declared_storage_for_ir`, `_declared_storage_roles`, `_build_signal_width_map`, `_merge_*`, `_build_assignment_provenance`, `_state_assignment_provenance`, `_dt_assignment_provenance`, bank-access helpers. | `declared_storage`, `signal_widths`, `signal_type_refs`, `storage_roles`, `bank_accesses`, assignment provenance records. | Schedule JSON `inferred_storage`, `bank_accesses`, transaction/stage/contract summaries, storage-role report fields. | Width and role inference must remain deterministic; provenance is report metadata and must not become a public raw IR dump. |
| Conflict, fan-in, priority, and resource resolution | `_apply_rule_slot_resource_arbitration`, `_apply_rule_priority_resolution`, `_build_compatible_fanin_groups`, `_build_conflict_issues`, priority/resource suppression helpers. | `compatible_fanin_groups`, priority/resource suppression metadata, compile/conflict issue records. | Schedule JSON `compatible_fanin_groups`, `priority_resolutions`, `resource_arbitration`, `compile_issues`; strict check diagnostics. | Existing same-cycle conflict semantics and strict diagnostics must remain byte-for-byte stable unless a later behavior leaf selects otherwise. |
| Transaction control/data lowering | `_build_transaction`, `_validate_supported_transaction_clauses`, `_ir_*` state builders, branch/loop expansion, dynamic wait linking, rule builders. | `states`, `dt_blocks`, `counters`, transitions, guards, assignments, temporal contracts, dynamic-wait metadata. | Scheduled `.fsm` states/DTs and schedule JSON transaction, wait, loop, stage, and temporal-contract summaries. | State names, DT names, guard/assignment semantics, dynamic-wait zero-bypass behavior, and temporal-contract monitor behavior stay unchanged. |
| Actor/package/type metadata | `_actor_package_imports`, `_actor_type_declarations`, `_actor_enum_declarations`, `_actor_constant_declarations`, `_actor_param_declarations`, `_actor_metadata_declarations`. | `package_imports`, `package_roots`, `type_declarations`, `enum_declarations`, `constants`, `params`, `actor_phases`, `actor_stages`. | Scheduled `.fsm` import/type/enum/constant/param sections and schedule JSON actor metadata summaries. | Declarations remain source-owned and emitted in deterministic order; public schedule summaries remain projections. |

## Candidate Notes For `.2`

Likely safe first extraction candidates are the subfamilies with clear inputs
and bounded public projections:

- Domain / CDC partitioning has a coherent input (`actor`) and output
  (`domain_partition`) consumed by scheduler/report/artifact paths.
- Actor-network / ATL generated-top metadata is coherent but broader because
  it touches generated children, generated tops, data links, and report
  projections.
- Storage/provenance is stable but high-blast-radius because many schedule
  report summaries consume the same fields.

`.2` must choose one candidate and explicitly state unchanged public surfaces
and focused tests before `.3` changes source.
