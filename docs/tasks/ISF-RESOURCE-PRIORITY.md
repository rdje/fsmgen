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
  Status: `pending`
  Goal: `Inventory current resource and priority metadata behavior.`
  Acceptance: `The task file lists accepted resource forms, accepted priority
  forms, existing validations, schedule-report exposure, and enforcement gaps.`
  Verification: `pending`
  Commit: `pending`

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
| 1 | `ISF-RESOURCE-PRIORITY.1` | `pending` | Existing metadata validation must be inventoried before scheduler semantics are promised. |

## Decisions

- `2026-05-14`: Resource and priority enforcement is tracked separately from
  same-target output conflicts, but it must consume the conflict-domain policy
  defined by `ISF-CONFLICTS`.

## Open Questions

- Which resource arbiter names are implementation-ready in the first shipped
  slice?
- Should priority resolution be allowed to choose among same-target data
  drives, or only among transaction/rule activation candidates?

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-14` | `ISF-RESOURCE-PRIORITY` | `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-RESOURCE-PRIORITY` | `R14: map ISF objectives to task trees` | Initial tree creation belongs to the ISF objective task-tree coverage slice. |

## Changelog

- `2026-05-14`: Created the active ISF resource/priority task tree.
