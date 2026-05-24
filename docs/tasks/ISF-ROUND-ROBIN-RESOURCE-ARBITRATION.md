# ISF-ROUND-ROBIN-RESOURCE-ARBITRATION: Round-Robin Resource Arbitration

## Metadata

- Tree ID: `ISF-ROUND-ROBIN-RESOURCE-ARBITRATION`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Ship a bounded `round_robin` resource arbiter for declared rule users on the
existing `rule_slot` resource kind.

## Non-Goals

- Do not add `round_robin` for `output_bundle`, `transaction_start`,
  `storage_port`, `interface_bundle`, `named_drive`, or `child_instance`.
- Do not add transaction users, named-drive users, output-target users,
  child-instance users, actor-network endpoint users, generated-child
  resources, dynamic resource names, multi-capacity resources, storage
  lifetime ownership, hold/release ownership, ready/backpressure, or route
  mux/storage.
- Do not change the existing static `priority` resource behavior.
- Do not infer resource users from rule bodies in this slice.

## Acceptance Criteria

- The selected syntax is `(resource NAME (kind rule_slot)
  (arbiter round_robin) (users rule_a rule_b ...))`.
- Each bound user must be a declared rule.
- A generated actor-local pointer records the next preferred user and resets
  to the first listed user under existing scheduled `.fsm` reset semantics.
- In a cycle with one or more requesting users, the first requesting user at
  or after the pointer in circular `(users ...)` order wins; the pointer
  advances to the next user after the winner only when a grant executes.
- The generated grant gates the whole winning rule DT and suppresses all
  losing bound rule DTs for that cycle.
- Schedule reports keep the existing `resource_arbitration[]` key family and
  identify grants with `arbiter: round_robin`.
- The pointer appears in `inferred_storage[]` with a documented storage role.
- Unsupported `round_robin` kind/user combinations continue to fail closed.
- The ISF spec, downstream integration handoff, public contract, mdBook, task
  index, roadmap status, MEMORY, CHANGES, DEVELOPMENT_NOTES, and
  LIVE_ACHIEVEMENT_STATUS stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-ROUND-ROBIN-RESOURCE-ARBITRATION`
  Status: `done`
  Goal: `Enforce bounded round_robin arbitration for rule_slot rule users`
  Children: `ISF-ROUND-ROBIN-RESOURCE-ARBITRATION.1`,
  `ISF-ROUND-ROBIN-RESOURCE-ARBITRATION.2`

- ID: `ISF-ROUND-ROBIN-RESOURCE-ARBITRATION.1`
  Status: `done`
  Goal: `Select the bounded round-robin resource arbitration slice`
  Acceptance: `The roadmap, task index, and live docs identify the active
  implementation leaf, document the exact boundary, and confirm no compiler
  behavior changed`
  Verification: `live-doc/spec index audits; git diff check`
  Commit: `434fb8e7 ISF-ROUND-ROBIN-RESOURCE-ARBITRATION.1: select round-robin resources`

- ID: `ISF-ROUND-ROBIN-RESOURCE-ARBITRATION.2`
  Status: `done`
  Goal: `Implement round_robin rule_slot arbitration for declared rule users`
  Acceptance: `Lowering enforces the selected round-robin boundary, reports
  expose grants and pointer storage, unsupported combinations fail closed,
  docs are synchronized, and focused plus broader checks pass`
  Verification: `syntax checks; focused resource/report/public-contract tests; public documentation audits; mdBook build; git diff check`
  Commit: `pending this commit`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `The bounded rule_slot round_robin implementation is shipped and documented.` |

## Decisions

- `2026-05-24`: Select `rule_slot` before broader resource kinds because it
  has no member domain, payload ownership, transaction-start fan-in, or
  storage-port lifetime semantics. It can exercise real fairness state while
  reusing the existing whole-rule DT grant-gating model.
- `2026-05-24`: Keep the first implementation rule-user-only and explicit
  `(users ...)` only. Inferred requesters, transaction users, generated-child
  resources, and actor-network endpoint users need separate ownership and
  diagnostics.
- `2026-05-24`: Treat `round_robin` as a runtime arbiter, not a static
  priority graph. The listed user order defines the circular scan order and
  reset pointer position; no `(priority ...)` declarations are required.

## Open Questions

- None for this bounded slice. Broader resource kinds and lifetime ownership
  remain backlog.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `ISF-ROUND-ROBIN-RESOURCE-ARBITRATION.1` | `prove -Iperl t/1303-isf-public-live-book-paths-audit.t t/1250-isf-spec-focused-test-index-audit.t` | `passed: Files=2, Tests=25` |
| `2026-05-24` | `ISF-ROUND-ROBIN-RESOURCE-ARBITRATION.1` | `git diff --check` | `passed` |
| `2026-05-24` | `ISF-ROUND-ROBIN-RESOURCE-ARBITRATION.2` | `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm; perl -Iperl -c perl/FSM/Support/ISFResourceCatalog.pm; perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm` | `passed` |
| `2026-05-24` | `ISF-ROUND-ROBIN-RESOURCE-ARBITRATION.2` | `prove -Iperl t/1176-isf-resource-priority-boundary.t t/1218-isf-rule-slot-resource-arbitration.t t/1220-isf-arbitration-schedule-report.t t/1140-isf-public-schedule-report-metadata-audit.t t/1148-isf-public-storage-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t` | `passed: Files=11, Tests=378` |
| `2026-05-24` | `ISF-ROUND-ROBIN-RESOURCE-ARBITRATION.2` | `mdbook build docs/book` | `passed` |
| `2026-05-24` | `ISF-ROUND-ROBIN-RESOURCE-ARBITRATION.2` | `./bin/ci-regression isf --no-book` | `passed: Files=250, Tests=1667` |
| `2026-05-24` | `ISF-ROUND-ROBIN-RESOURCE-ARBITRATION.2` | `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ROUND-ROBIN-RESOURCE-ARBITRATION.1` | `434fb8e7 ISF-ROUND-ROBIN-RESOURCE-ARBITRATION.1: select round-robin resources` | `selection slice` |
| `ISF-ROUND-ROBIN-RESOURCE-ARBITRATION.2` | `pending this commit: ISF-ROUND-ROBIN-RESOURCE-ARBITRATION.2: ship rule-slot round robin` | `implementation slice` |

## Changelog

- `2026-05-24`: Created and activated the task tree.
- `2026-05-24`: Shipped and documented bounded `rule_slot`/`round_robin`
  arbitration for declared rule users, then closed the task tree.
