# ISF-TRANSACTION-START-RESOURCE-PRIORITY: Transaction-Start Resource Priority

## Metadata

- Tree ID: `ISF-TRANSACTION-START-RESOURCE-PRIORITY`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-23`
- Last updated: `2026-05-23`
- Owner: repo-local workflow

## Goal

Ship a bounded `transaction_start` resource kind under the existing static
`priority` arbiter for declared rule users that trigger one local transaction.

## Non-Goals

- Do not add `round_robin`, fairness state, hold/release ownership,
  transaction lifetime ownership, or multi-capacity resources.
- Do not add `interface_bundle`, `named_drive`, `child_instance`, or
  `storage_port` enforcement.
- Do not add transaction users, named-drive users, output-target users, actor
  network trigger resources, child-instance resources, dynamic resource names,
  generated-child transaction-start arbitration, ready/backpressure, or route
  mux/storage.
- Do not change the existing rule-trigger fan-in pulse timing or add a cycle.

## Acceptance Criteria

- The selected syntax is `(resource TRANSACTION (kind transaction_start)
  (arbiter priority) (users rule_a rule_b ...))`, where `TRANSACTION` names a
  declared local transaction and each user is a declared rule.
- Each bound rule user must trigger the named local transaction in the shipped
  non-generated rule-trigger surface; rules that do not trigger it fail closed.
- The existing priority model provides a total order between users, rejects
  cycles/incomplete ordering, and gates lower-priority rule DTs before their
  trigger source pulse can request the transaction.
- The existing `rule_trigger_fanin` DT remains the transaction-start fan-in
  owner; the resource only suppresses lower-priority request sources in the
  same cycle.
- Schedule reports expose successful grants through
  `resource_arbitration[]` with `kind: transaction_start` and no member list.
- The ISF resource catalog, spec, downstream integration handoff, public
  contract, mdBook, task index, roadmap status, MEMORY, CHANGES,
  DEVELOPMENT_NOTES, and LIVE_ACHIEVEMENT_STATUS stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-TRANSACTION-START-RESOURCE-PRIORITY`
  Status: `active`
  Goal: `Enforce bounded transaction_start priority arbitration for rule users`
  Children: `ISF-TRANSACTION-START-RESOURCE-PRIORITY.1`,
  `ISF-TRANSACTION-START-RESOURCE-PRIORITY.2`

- ID: `ISF-TRANSACTION-START-RESOURCE-PRIORITY.1`
  Status: `done`
  Goal: `Select the bounded transaction-start resource priority slice`
  Acceptance: `The roadmap, task index, and live docs identify the active
  implementation leaf, document the exact boundary, and confirm no compiler
  behavior changed`
  Verification: `documentation-only selection review, live-doc audits,
  git diff check`
  Commit: `pending this commit`

- ID: `ISF-TRANSACTION-START-RESOURCE-PRIORITY.2`
  Status: `pending`
  Goal: `Implement priority-arbitrated transaction_start resources for rule users`
  Acceptance: `Parser and lowerer enforce the selected transaction_start
  boundary, reports expose grants, docs are synchronized, and focused plus
  broad checks pass`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-TRANSACTION-START-RESOURCE-PRIORITY.2` | `pending` | `The selection leaf is complete; implementation can now proceed under this task-tree owner.` |

## Decisions

- `2026-05-23`: Select `transaction_start` before broader resource kinds
  because the existing rule-trigger fan-in surface already has explicit
  per-rule trigger source pulses and a generated fan-in DT. Static priority
  can suppress lower-priority rule DTs before those source pulses request the
  transaction without changing timing.
- `2026-05-23`: Require the resource name to be the target local transaction
  name for this bounded slice. That keeps ownership reviewable and avoids a
  separate member or endpoint syntax.
- `2026-05-23`: Keep the first slice rule-user-only. Transaction users,
  generated-child transaction starts, actor-network triggers, and lifetime
  ownership need separate scheduling and diagnostic contracts.

## Open Questions

- None for this bounded slice. Broader start fan-in ownership remains backlog.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-23` | `ISF-TRANSACTION-START-RESOURCE-PRIORITY.1` | `prove -Iperl t/1303-isf-public-live-book-paths-audit.t t/1250-isf-spec-focused-test-index-audit.t` | `passed: Files=2, Tests=25` |
| `2026-05-23` | `ISF-TRANSACTION-START-RESOURCE-PRIORITY.1` | `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-TRANSACTION-START-RESOURCE-PRIORITY.1` | `pending this commit: ISF-TRANSACTION-START-RESOURCE-PRIORITY.1: select transaction-start resources` | `selection slice` |
| `ISF-TRANSACTION-START-RESOURCE-PRIORITY.2` | `pending` | `implementation slice` |

## Changelog

- `2026-05-23`: Created and activated the task tree.
