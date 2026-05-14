# ISF-RESOURCE-PRIORITY: Resource Arbitration And Priority Enforcement

## Metadata

- Tree ID: `ISF-RESOURCE-PRIORITY`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-14`
- Last updated: `2026-05-14`
- Owner: repo-local workflow

## Goal

Turn ISF `(resources ...)`, actor-level priority metadata, and rule-local
priority metadata from validated informational declarations into scheduler
behavior that enforces mutual exclusion, priority ordering, and clear
diagnostics for unresolved arbitration.

## Non-Goals

- Do not silently resolve incompatible same-cycle drives without an explicit
  resource, priority, or conflict policy.
- Do not implement a broad generic arbiter library beyond the resource
  arbiters accepted by the ISF contract.
- Do not duplicate `ISF-CONFLICTS`; that tree owns same-target conflict domain
  vocabulary and lower-level drive compatibility.

## Acceptance Criteria

- Existing resource and priority metadata parsing/validation is inventoried.
- The relationship between resource arbitration, priority resolution, and
  same-cycle conflict handling is documented.
- Resource mutual exclusion lowers into deterministic scheduler behavior or
  fails closed when the requested arbitration is not supported.
- Actor-level and rule-local priorities affect conflict/arbitration outcomes
  for the covered cases.
- Diagnostics identify missing, ambiguous, circular, or unsupported arbitration
  semantics.
- Focused tests, schedule-report metadata, ISF spec, public contract, mdBook,
  roadmap, and live docs agree.

## Task Tree

- ID: `ISF-RESOURCE-PRIORITY`
  Status: `active`
  Goal: `Ship resource arbitration and priority enforcement for ISF.`
  Children: `ISF-RESOURCE-PRIORITY.1`, `ISF-RESOURCE-PRIORITY.2`,
  `ISF-RESOURCE-PRIORITY.3`, `ISF-RESOURCE-PRIORITY.4`,
  `ISF-RESOURCE-PRIORITY.5`, `ISF-RESOURCE-PRIORITY.6`

- ID: `ISF-RESOURCE-PRIORITY.1`
  Status: `done`
  Goal: `Inventory current resource and priority metadata behavior.`
  Acceptance: `The task file lists accepted resource forms, accepted priority
  forms, existing validations, schedule-report exposure, and enforcement gaps.`
  Verification: `prove -l t/1176-isf-resource-priority-boundary.t t/1190-isf-rule-priority-target-boundary.t t/1191-isf-actor-priority-target-boundary.t t/1210-isf-priority-conflict-resolution.t`; `git diff --check`
  Commit: `ISF-RESOURCE-PRIORITY.1: inventory metadata behavior`

- ID: `ISF-RESOURCE-PRIORITY.2`
  Status: `pending`
  Goal: `Specify arbitration and priority semantics.`
  Acceptance: `The tree records mutual-exclusion rules, supported arbiters,
  actor-level priority ordering, rule-local priority ordering, ties, cycles,
  and unsupported cases.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-RESOURCE-PRIORITY.3`
  Status: `pending`
  Goal: `Implement resource mutual-exclusion lowering.`
  Acceptance: `The scheduler enforces the covered resource conflicts with
  deterministic generated artifacts or targeted fail-closed diagnostics.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-RESOURCE-PRIORITY.4`
  Status: `pending`
  Goal: `Implement priority resolution for covered rule/transaction conflicts.`
  Acceptance: `Actor-level and rule-local priority declarations affect the
  covered scheduler decisions and reject unresolved or cyclic cases.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-RESOURCE-PRIORITY.5`
  Status: `pending`
  Goal: `Integrate arbitration with conflict diagnostics and schedule reports.`
  Acceptance: `Accepted arbitration decisions and rejected conflicts are
  visible in bounded report metadata and targeted diagnostics.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-RESOURCE-PRIORITY.6`
  Status: `pending`
  Goal: `Add tests and synchronize docs.`
  Acceptance: `Tests cover accepted arbitration, priority ordering, ties,
  cycles, unsupported arbiters, diagnostics, and synchronized user-facing docs.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-RESOURCE-PRIORITY.2` | `pending` | The shipped parser/lowering boundary is now inventoried, so the next slice can define the supported arbitration semantics before implementation. |

## ISF-RESOURCE-PRIORITY.1 Inventory

This inventory records current shipped behavior. It is not a frozen API claim:
the ISF public surface is live and may evolve alongside FSMGen as the
resource/priority implementation becomes more complete.

### Accepted Resource Forms

- Resource declarations are accepted only as an actor-level singleton
  `(resources ...)` block.
- Each entry must have the exact shape
  `(resource name (arbiter priority))` or
  `(resource name (arbiter round_robin))`.
- `name` must be a non-empty scalar token.
- The only accepted arbiter names are `priority` and `round_robin`.
- Duplicate resource names in the same block are rejected.
- A repeated actor-level `(resources ...)` block is rejected by the general
  actor singleton-clause validation.

Current storage: the parser returns
`resources => [ { name => ..., arbiter => ... }, ... ]` in the actor shell.

### Accepted Priority Forms

- Actor-level priority is accepted as `(priority lhs over rhs)`.
- Actor-level `lhs` and `rhs` must be non-empty scalar tokens naming declared
  same-actor transactions or rules. Forward references are accepted because
  targets are validated after the full actor body is parsed.
- Actor-level priority is stored as
  `priorities => [ [ lhs, 'over', rhs ], ... ]`.
- Rule-local priority is accepted as a rule action
  `(priority over other_rule)`.
- Rule-local `other_rule` must be a non-empty scalar token naming a declared
  same-actor rule. Forward references are accepted.
- Rule-local priority is preserved in the rule action list as
  `[ 'priority', 'over', other_rule ]`.

### Existing Validations

- Malformed resource entries fail before actor-shell return.
- Unsupported arbiter names fail before actor-shell return.
- Duplicate resource names fail before actor-shell return.
- Repeated `(resources ...)` actor blocks fail before actor-shell return.
- Malformed actor-level priority forms fail before actor-shell return.
- Actor-level priority targets must resolve to declared same-actor
  transactions or rules before actor-shell return.
- Malformed rule-local priority forms fail before actor-shell return.
- Rule-local priority targets must resolve to declared same-actor rules before
  actor-shell return.
- Priority cycles in the currently enforced same-target rule/rule data-conflict
  path fail closed with `isf_priority_cycle_conflict`.
- Priority attempts to resolve mixed assignment timing operators fail closed
  with `isf_priority_mixed_timing_conflict`.

### Current Enforcement

- `(resources ...)` is not enforced by the scheduler today. A declared
  resource does not yet create mutual exclusion, grants, arbitration state, or
  generated HDL.
- Rule-local and actor-level priority are enforced only for same-target
  rule/rule data assignments when the conflicting owners are rules and the
  assignment operators match.
- Actor-level priority edges participate in that enforcement only when both
  priority endpoints are rules. Transaction endpoints are validated metadata
  today.
- A compatible same-target same-value rule write does not need priority; it is
  treated as compatible fan-in.
- When one rule dominates another through the priority graph, only the losing
  conflicting assignment is suppressed. The lowerer keeps unrelated actions in
  the losing rule alive.
- Suppression is implemented by ANDing the losing assignment guard with the
  inverse of the winning rule condition. Assignment provenance records
  `priority_suppressed_by` for internal analysis and downstream conflict
  filtering.
- If two conflicting rules are incomparable, the existing conflict diagnostic
  path remains responsible for failing closed.

### Schedule-Report Exposure

- Schedule JSON does not currently expose authored `resources`.
- Schedule JSON does not currently expose authored actor-level or rule-local
  priority declarations.
- Schedule JSON does not currently expose successful priority-resolution
  decisions or `priority_suppressed_by` bookkeeping.
- Nonfatal compile issues can appear in reports for other conflict domains,
  but the currently fatal priority-resolution issues stop lowering before a
  successful schedule report is emitted.

### Enforcement Gaps

- There is no source syntax yet that binds a transaction, rule, drive, or
  output to a declared resource.
- `round_robin` is parser-accepted but has no scheduler or HDL implementation.
- `priority` resource arbitration is parser-accepted but is not connected to
  resource users or generated grants.
- Actor-level priority that references transactions is validated but not
  enforced.
- Rule-local priority only orders rule/rule data conflicts. It does not yet
  order transaction starts, resource requests, named-drive calls, or broader
  owner-level scheduling.
- Successful arbitration decisions are not visible in bounded schedule-report
  metadata.
- The scheduler does not yet diagnose unused resources or priorities that are
  valid but have no effect.

### Regression Evidence

- [t/1176-isf-resource-priority-boundary.t](../../t/1176-isf-resource-priority-boundary.t)
  covers accepted resources/priorities, malformed resource syntax,
  unsupported arbiters, duplicate resources, malformed actor priority, and
  malformed rule priority.
- [t/1190-isf-rule-priority-target-boundary.t](../../t/1190-isf-rule-priority-target-boundary.t)
  covers rule-local priority forward references and unknown target rejection.
- [t/1191-isf-actor-priority-target-boundary.t](../../t/1191-isf-actor-priority-target-boundary.t)
  covers actor-level priority forward references and unknown lhs/rhs target
  rejection.
- [t/1210-isf-priority-conflict-resolution.t](../../t/1210-isf-priority-conflict-resolution.t)
  covers same-target rule/rule priority suppression, actor-level rule
  priority suppression, scheduled `.fsm` guard output, HDL handoff, and cycle
  rejection.

## Decisions

- `2026-05-14`: Resource and priority enforcement is tracked separately from
  same-target output conflicts, but it must consume the conflict-domain policy
  defined by `ISF-CONFLICTS`.
- `2026-05-14`: `ISF-RESOURCE-PRIORITY.1` records that resources are
  validated metadata only, while priority has one shipped enforcement path:
  same-target rule/rule data-conflict resolution through target-local
  suppression of the lower-priority assignment.
- `2026-05-14`: Resource/priority schedule-report exposure is intentionally
  not treated as frozen. Any new public metadata must be added as a bounded,
  documented, regression-backed surface when the feature implementation ships.

## Open Questions

- Which resource arbiter names are implementation-ready in the first shipped
  slice?
- Should priority resolution be allowed to choose among same-target data
  drives, or only among transaction/rule activation candidates?
- What authored syntax should bind rules, transactions, drives, or outputs to
  a declared resource?
- Should successful priority/resource arbitration decisions become schedule
  JSON metadata before or together with first resource enforcement?

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-14` | `ISF-RESOURCE-PRIORITY` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-RESOURCE-PRIORITY.1` | `prove -l t/1176-isf-resource-priority-boundary.t t/1190-isf-rule-priority-target-boundary.t t/1191-isf-actor-priority-target-boundary.t t/1210-isf-priority-conflict-resolution.t`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-RESOURCE-PRIORITY` | `R14: map ISF objectives to task trees` | Initial tree creation belongs to the ISF objective task-tree coverage slice. |
| `ISF-RESOURCE-PRIORITY.1` | `ISF-RESOURCE-PRIORITY.1: inventory metadata behavior` | Records accepted resource/priority forms, existing validation, current enforcement, schedule-report exposure gaps, and implementation gaps. |

## Changelog

- `2026-05-14`: Created the active ISF resource/priority task tree.
- `2026-05-14`: Completed the current-behavior inventory and moved the
  frontier to `ISF-RESOURCE-PRIORITY.2`.
