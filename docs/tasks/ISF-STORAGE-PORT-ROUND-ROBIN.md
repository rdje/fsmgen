# ISF-STORAGE-PORT-ROUND-ROBIN: Storage-Port Round-Robin Arbitration

## Metadata

- Tree ID: `ISF-STORAGE-PORT-ROUND-ROBIN`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Ship a bounded `round_robin` arbiter for declared rule users that share a
`storage_port` resource.

## Non-Goals

- Do not add `round_robin` for `interface_bundle`, `named_drive`,
  `child_instance`, generated-child resources, actor-network triggers,
  actor-network endpoints, or arbitrary backlog resource kinds.
- Do not add transaction users, named-drive users, output-target users,
  child-instance users, dynamic resource names, multi-capacity resources,
  route mux/storage, ready/backpressure, payload protocols, storage locks, or
  lifetime hold/release semantics.
- Do not change existing `rule_slot`, `output_bundle`, or
  `transaction_start` `round_robin` behavior.
- Do not infer resource users from rule bodies; the first shipped subset
  remains explicit `(users rule_a rule_b ...)`.
- Do not broaden `storage_port` members beyond concrete actor-owned storage
  signals.

## Acceptance Criteria

- The selection leaf creates clear task-tree ownership before lowerer code
  changes.
- The implementation leaf accepts:
  `(resource NAME (kind storage_port) (arbiter round_robin) (members STORAGE_SIGNAL...) (users RULE...))`
  for declared rule users.
- Explicit storage-port members remain mandatory when users are bound.
- Members must name concrete actor-owned storage signals: scalar storage
  variables or scalarized bank element signals.
- Every listed member must be written by at least one bound rule.
- Bound rules may not write concrete actor-owned storage targets outside the
  explicit member list.
- A generated actor-local pointer records the next preferred rule user and
  resets to the first listed user under existing scheduled `.fsm` reset
  semantics.
- In a cycle with one or more requesting rules, the first requesting rule at
  or after the pointer in circular `(users ...)` order wins; the pointer
  advances to the next rule after the winner only when a grant executes.
- The generated grant gates the whole winning rule DT and suppresses losing
  bound rule DTs for the shared storage-port ownership cycle.
- Schedule reports keep the existing `resource_arbitration[]` key family and
  identify grants with `kind: storage_port` and `arbiter: round_robin`.
- Explicit member lists continue to report through
  `resource_arbitration[].members`.
- The pointer appears in `inferred_storage[]` with the existing
  `resource_round_robin_pointer` role.
- Unsupported `round_robin` kind/user/member combinations continue to fail
  closed.
- The ISF spec, downstream integration handoff, public contract, mdBook, task
  index, roadmap status, `MEMORY.md`, `CHANGES.md`,
  `DEVELOPMENT_NOTES.md`, and `LIVE_ACHIEVEMENT_STATUS.md` stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-STORAGE-PORT-ROUND-ROBIN`
  Status: `done`
  Goal: `Enforce bounded round_robin arbitration for storage_port rule users.`
  Children: `ISF-STORAGE-PORT-ROUND-ROBIN.1`,
  `ISF-STORAGE-PORT-ROUND-ROBIN.2`

- ID: `ISF-STORAGE-PORT-ROUND-ROBIN.1`
  Status: `done`
  Goal: `Select the bounded storage-port round-robin resource slice.`
  Acceptance: `The roadmap, task index, README index, and live docs identify the active implementation leaf, document the exact boundary, and confirm no compiler behavior changed.`
  Verification: `passed: feature-backlog audit, mdBook build, and diff check`
  Commit: `pending`

- ID: `ISF-STORAGE-PORT-ROUND-ROBIN.2`
  Status: `done`
  Goal: `Implement storage_port round_robin arbitration for declared rule users.`
  Acceptance: `Lowering enforces the selected storage_port round-robin boundary, mandatory member validation/reporting remains intact, reports expose grants and pointer storage, unsupported combinations fail closed, docs are synchronized, and focused plus broader checks pass.`
  Verification: `passed: syntax checks; focused resource arbitration test; public contract/report/book audits; feature-backlog audit; ISF regression gate; mdBook build; diff check`
  Commit: `ISF-STORAGE-PORT-ROUND-ROBIN.2: ship storage-port round robin`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-STORAGE-PORT-ROUND-ROBIN.2` | `done` | The bounded storage-port round-robin resource widening is implemented, documented, and validated. |

Current frontier: `closed`.

## Decisions

- `2026-05-24`: Select `storage_port` after `output_bundle` because it is the
  remaining parser-recognized, priority-enforced resource kind with declared
  rule users and mandatory explicit member validation. The first widening must
  preserve the concrete actor-owned storage member contract and avoid storage
  locks, route mux/storage, memory-port protocols, or lifetime ownership.

## Open Questions

- None for the selected first slice. Broader storage lifetime, lock, and route
  ownership remain backlog.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `ISF-STORAGE-PORT-ROUND-ROBIN.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |
| `2026-05-24` | `ISF-STORAGE-PORT-ROUND-ROBIN.2` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFResourceCatalog.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1218-isf-rule-slot-resource-arbitration.t`; focused public/report/book audits; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed: resource arbitration Files=1, Tests=15; public/report/book audits Files=9, Tests=370; ISF gate Files=250, Tests=1682` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-STORAGE-PORT-ROUND-ROBIN.1` | `ISF-STORAGE-PORT-ROUND-ROBIN.1: select storage-port round robin` | `selection slice` |
| `ISF-STORAGE-PORT-ROUND-ROBIN.2` | `ISF-STORAGE-PORT-ROUND-ROBIN.2: ship storage-port round robin` | `implementation slice` |

## Changelog

- `2026-05-24`: Created and activated the task tree, selected
  `ISF-STORAGE-PORT-ROUND-ROBIN.2` as the implementation frontier, and
  confirmed that the selection slice has no compiler behavior change.
- `2026-05-24`: Shipped bounded `storage_port` + `round_robin` arbitration
  for declared rule users. The lowerer now accepts
  `(resource NAME (kind storage_port) (arbiter round_robin) (members STORAGE_SIGNAL...) (users RULE...))`,
  preserves mandatory concrete actor-owned storage member validation and
  `resource_arbitration[].members` reporting, emits and reports the generated
  `isf_rr_<resource>_turn` pointer, and keeps broader storage locks,
  route mux/storage, memory-port protocols, lifetime ownership, generated-child
  resources, and backlog resource kinds deferred.
