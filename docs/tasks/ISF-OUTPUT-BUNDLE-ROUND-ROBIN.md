# ISF-OUTPUT-BUNDLE-ROUND-ROBIN: Output-Bundle Round-Robin Arbitration

## Metadata

- Tree ID: `ISF-OUTPUT-BUNDLE-ROUND-ROBIN`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Ship a bounded `round_robin` arbiter for declared rule users that share an
`output_bundle` resource.

## Non-Goals

- Do not add `round_robin` for `storage_port`, `interface_bundle`,
  `named_drive`, `child_instance`, generated-child resources, actor-network
  triggers, actor-network endpoints, or arbitrary backlog resource kinds.
- Do not add transaction users, named-drive users, output-target users,
  child-instance users, dynamic resource names, multi-capacity resources,
  route mux/storage, ready/backpressure, payload protocols, storage locks, or
  lifetime hold/release semantics.
- Do not change existing `output_bundle` + `priority`,
  `rule_slot` + `round_robin`, or `transaction_start` + `round_robin`
  behavior.
- Do not infer resource users from rule bodies; the first shipped subset
  remains explicit `(users rule_a rule_b ...)`.

## Acceptance Criteria

- The selection leaf creates clear task-tree ownership before lowerer code
  changes.
- The implementation leaf accepts:
  `(resource NAME (kind output_bundle) (arbiter round_robin) (users RULE...))`
  for declared rule users, with or without the shipped explicit
  `(members OUTPUT_OR_STORAGE_SIGNAL...)` list.
- Explicit output-bundle members keep the current validation contract:
  members must be declared actor outputs or concrete actor-owned storage
  signals, every listed member must be written by a bound rule, and bound
  rules may not write declared output/storage targets outside the list.
- A generated actor-local pointer records the next preferred rule user and
  resets to the first listed user under existing scheduled `.fsm` reset
  semantics.
- In a cycle with one or more requesting rules, the first requesting rule at
  or after the pointer in circular `(users ...)` order wins; the pointer
  advances to the next rule after the winner only when a grant executes.
- The generated grant gates the whole winning rule DT and suppresses losing
  bound rule DTs for the shared output-bundle ownership cycle.
- Schedule reports keep the existing `resource_arbitration[]` key family and
  identify grants with `kind: output_bundle` and `arbiter: round_robin`.
- Explicit member lists continue to report through
  `resource_arbitration[].members`.
- The pointer appears in `inferred_storage[]` with the existing
  `resource_round_robin_pointer` role.
- Unsupported `round_robin` kind/user combinations continue to fail closed.
- The ISF spec, downstream integration handoff, public contract, mdBook, task
  index, roadmap status, `MEMORY.md`, `CHANGES.md`,
  `DEVELOPMENT_NOTES.md`, and `LIVE_ACHIEVEMENT_STATUS.md` stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-OUTPUT-BUNDLE-ROUND-ROBIN`
  Status: `active`
  Goal: `Enforce bounded round_robin arbitration for output_bundle rule users.`
  Children: `ISF-OUTPUT-BUNDLE-ROUND-ROBIN.1`,
  `ISF-OUTPUT-BUNDLE-ROUND-ROBIN.2`

- ID: `ISF-OUTPUT-BUNDLE-ROUND-ROBIN.1`
  Status: `done`
  Goal: `Select the bounded output-bundle round-robin resource slice.`
  Acceptance: `The roadmap, task index, README index, and live docs identify the active implementation leaf, document the exact boundary, and confirm no compiler behavior changed.`
  Verification: `passed: feature-backlog audit, mdBook build, and diff check`
  Commit: `ISF-OUTPUT-BUNDLE-ROUND-ROBIN.1: select output-bundle round robin`

- ID: `ISF-OUTPUT-BUNDLE-ROUND-ROBIN.2`
  Status: `pending`
  Goal: `Implement output_bundle round_robin arbitration for declared rule users.`
  Acceptance: `Lowering enforces the selected output_bundle round-robin boundary, member validation/reporting remains intact, reports expose grants and pointer storage, unsupported combinations fail closed, docs are synchronized, and focused plus broader checks pass.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-OUTPUT-BUNDLE-ROUND-ROBIN.2` | `pending` | The selected output-bundle round-robin boundary is documented and ready for implementation. |

Current frontier: `ISF-OUTPUT-BUNDLE-ROUND-ROBIN.2`.

## Decisions

- `2026-05-24`: Select `output_bundle` after `transaction_start` because it
  already has declared rule users, current member validation/reporting, and
  the same whole-rule-DT grant shape as the shipped `rule_slot` and
  `transaction_start` round-robin paths. The first widening must preserve the
  existing output-bundle member contract and avoid route mux/storage or
  lifetime ownership semantics.

## Open Questions

- None for the selected first slice. Storage-port fairness and broader
  resource/lifetime ownership remain backlog.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `ISF-OUTPUT-BUNDLE-ROUND-ROBIN.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-OUTPUT-BUNDLE-ROUND-ROBIN.1` | `ISF-OUTPUT-BUNDLE-ROUND-ROBIN.1: select output-bundle round robin` | `selection slice` |
| `ISF-OUTPUT-BUNDLE-ROUND-ROBIN.2` | `pending` | `implementation slice` |

## Changelog

- `2026-05-24`: Created and activated the task tree, selected
  `ISF-OUTPUT-BUNDLE-ROUND-ROBIN.2` as the implementation frontier, and
  confirmed that the selection slice has no compiler behavior change.
