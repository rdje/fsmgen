# ISF-TRANSACTION-START-ROUND-ROBIN: Transaction-Start Round-Robin Arbitration

## Metadata

- Tree ID: `ISF-TRANSACTION-START-ROUND-ROBIN`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Ship a bounded `round_robin` arbiter for declared rule users that request one
local transaction through a `transaction_start` resource.

## Non-Goals

- Do not add `round_robin` for `output_bundle`, `storage_port`,
  `interface_bundle`, `named_drive`, `child_instance`, generated-child
  transaction starts, actor-network triggers, or actor-network endpoints.
- Do not add transaction users, named-drive users, output-target users,
  child-instance users, dynamic resource names, multi-capacity resources,
  route mux/storage, ready/backpressure, payload protocols, storage locks, or
  transaction lifetime hold/release semantics.
- Do not change the existing `transaction_start` + `priority` contract.
- Do not infer resource users from rule bodies; the first shipped subset
  remains explicit `(users rule_a rule_b ...)`.

## Acceptance Criteria

- The selection leaf creates clear task-tree ownership before lowerer code
  changes.
- The implementation leaf accepts:
  `(resource TX (kind transaction_start) (arbiter round_robin) (users RULE...))`
  when `TX` is a local non-generated transaction and every listed rule triggers
  `TX` through the shipped non-generated rule-trigger surface.
- A generated actor-local pointer records the next preferred rule user and
  resets to the first listed user under existing scheduled `.fsm` reset
  semantics.
- In a cycle with one or more requesting rules, the first requesting rule at or
  after the pointer in circular `(users ...)` order wins; the pointer advances
  to the next rule after the winner only when a grant executes.
- The generated grant gates the whole winning rule DT and suppresses losing
  bound rule DTs before their per-rule trigger-source pulses feed the existing
  transaction trigger fan-in.
- Schedule reports keep the existing `resource_arbitration[]` key family and
  identify grants with `kind: transaction_start` and `arbiter: round_robin`.
- The pointer appears in `inferred_storage[]` with the existing
  `resource_round_robin_pointer` role.
- Unsupported `round_robin` kind/user combinations and generated-child
  transaction-start resources continue to fail closed.
- The ISF spec, downstream integration handoff, public contract, mdBook, task
  index, roadmap status, `MEMORY.md`, `CHANGES.md`,
  `DEVELOPMENT_NOTES.md`, and `LIVE_ACHIEVEMENT_STATUS.md` stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-TRANSACTION-START-ROUND-ROBIN`
  Status: `active`
  Goal: `Enforce bounded round_robin arbitration for transaction_start rule users.`
  Children: `ISF-TRANSACTION-START-ROUND-ROBIN.1`,
  `ISF-TRANSACTION-START-ROUND-ROBIN.2`

- ID: `ISF-TRANSACTION-START-ROUND-ROBIN.1`
  Status: `done`
  Goal: `Select the bounded transaction-start round-robin resource slice.`
  Acceptance: `The roadmap, task index, README index, and live docs identify the active implementation leaf, document the exact boundary, and confirm no compiler behavior changed.`
  Verification: `passed: feature-backlog audit, mdBook build, and diff check`
  Commit: `ISF-TRANSACTION-START-ROUND-ROBIN.1: select transaction-start round robin`

- ID: `ISF-TRANSACTION-START-ROUND-ROBIN.2`
  Status: `pending`
  Goal: `Implement transaction_start round_robin arbitration for declared rule users.`
  Acceptance: `Lowering enforces the selected transaction_start round-robin boundary, reports expose grants and pointer storage, unsupported combinations fail closed, docs are synchronized, and focused plus broader checks pass.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-TRANSACTION-START-ROUND-ROBIN.2` | `pending` | The selected slice is a bounded public-facing resource-arbitration widening that combines the shipped `transaction_start` rule-user contract with the shipped `rule_slot` round-robin machinery. |

Current frontier: `ISF-TRANSACTION-START-ROUND-ROBIN.2`.

## Decisions

- `2026-05-24`: Select `transaction_start` before other non-`rule_slot`
  round-robin resource kinds. It already has a local transaction resource
  identity, declared rule users, parser validation, rule-trigger membership
  checks, and an existing trigger-fan-in owner. The first widening can reuse
  the shipped round-robin grant/pointer model while preserving the current
  trigger fan-in timing.
- `2026-05-24`: Keep generated-child transaction starts deferred. The bounded
  implementation must target only the shipped non-generated rule-trigger
  surface so no generated-top lifetime, parameter specialization, or child
  start-handoff policy changes are hidden inside this slice.

## Open Questions

- None for the selected first slice. Broader resource kinds and lifetime
  ownership remain backlog.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `ISF-TRANSACTION-START-ROUND-ROBIN.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-TRANSACTION-START-ROUND-ROBIN.1` | `ISF-TRANSACTION-START-ROUND-ROBIN.1: select transaction-start round robin` | `selection slice` |
| `ISF-TRANSACTION-START-ROUND-ROBIN.2` | `pending` | `implementation slice` |

## Changelog

- `2026-05-24`: Created and activated the task tree, selected
  `ISF-TRANSACTION-START-ROUND-ROBIN.2` as the implementation frontier, and
  confirmed that the selection slice has no compiler behavior change.
