# ISF-STORAGE-PORT-RESOURCE-PRIORITY: Storage-Port Resource Priority

## Metadata

- Tree ID: `ISF-STORAGE-PORT-RESOURCE-PRIORITY`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-23`
- Last updated: `2026-05-23`
- Owner: repo-local workflow

## Goal

Ship a bounded `storage_port` resource kind under the existing static
`priority` arbiter for declared rule users that contend for explicit
actor-owned storage signals.

## Non-Goals

- Do not add `round_robin`, fairness state, hold/release ownership,
  multi-cycle storage locks, or multi-capacity resources.
- Do not add `interface_bundle`, `named_drive`, or `child_instance`
  enforcement.
- Do not add transaction users, named-drive users, output-target users,
  child-instance users, actor-network endpoint users, dynamic resource names,
  generated-child storage arbitration, ready/backpressure, or route
  mux/storage.
- Do not widen storage members to bank roots, aggregate paths, inferred
  undeclared targets, transaction ports, actor input ports, or arbitrary
  expressions.

## Acceptance Criteria

- The selected syntax is `(resource NAME (kind storage_port) (arbiter priority)
  (members storage_signal...) (users rule_a rule_b ...))`.
- Each explicit member must name a concrete actor-owned storage signal already
  recognized by the scheduler, including scalar storage variables and
  scalarized bank element signals.
- Each bound user must be a declared rule; the existing priority model provides
  a total order between users, rejects cycles/incomplete ordering, and gates
  lower-priority rule DTs before their assignments can update the protected
  storage signals.
- With members present, lowering fails closed if a bound rule writes a
  concrete actor-owned storage signal outside the explicit member list or if a
  listed member is not written by any bound rule user.
- Schedule reports expose successful grants through
  `resource_arbitration[]` with `kind: storage_port` and the explicit member
  list.
- The ISF resource catalog, spec, downstream integration handoff, public
  contract, mdBook, task index, roadmap status, MEMORY, CHANGES,
  DEVELOPMENT_NOTES, and LIVE_ACHIEVEMENT_STATUS stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-STORAGE-PORT-RESOURCE-PRIORITY`
  Status: `done`
  Goal: `Enforce bounded storage_port priority arbitration for rule users`
  Children: `ISF-STORAGE-PORT-RESOURCE-PRIORITY.1`,
  `ISF-STORAGE-PORT-RESOURCE-PRIORITY.2`

- ID: `ISF-STORAGE-PORT-RESOURCE-PRIORITY.1`
  Status: `done`
  Goal: `Select the bounded storage-port resource priority slice`
  Acceptance: `The roadmap, task index, and live docs identify the active
  implementation leaf, document the exact boundary, and confirm no compiler
  behavior changed`
  Verification: `documentation-only selection review, live-doc audits,
  git diff check`
  Commit: `8be2a572 ISF-STORAGE-PORT-RESOURCE-PRIORITY.1: select storage-port resources`

- ID: `ISF-STORAGE-PORT-RESOURCE-PRIORITY.2`
  Status: `done`
  Goal: `Implement priority-arbitrated storage_port resources for rule users`
  Acceptance: `Parser and lowerer enforce the selected storage_port boundary,
  reports expose grants with explicit members, docs are synchronized, and
  focused plus broad checks pass`
  Verification: `syntax checks; focused resource/report tests; public/spec/book
  audits; mdBook build; broad ISF regression; post-closure audits; git diff
  check`
  Commit: `c2db0a8a ISF-STORAGE-PORT-RESOURCE-PRIORITY.2: ship storage-port resources`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `The bounded storage_port priority slice is implemented, documented, validated, and ready for commit.` |

## Decisions

- `2026-05-23`: Select `storage_port` before `interface_bundle`,
  `named_drive`, `child_instance`, and `round_robin` because the current
  output-bundle member work already identified the exact concrete
  actor-owned storage signal domain. The first storage-port slice can reuse
  the existing static priority grant model and explicit member validation
  without inventing protocol ownership, drive-call ownership, child re-entry
  locks, or arbiter state.
- `2026-05-23`: Require explicit `(members ...)` for the first shipped
  `storage_port` subset. A storage-port resource without a member list would
  be too ambiguous to review because the resource name alone does not identify
  the storage signals it protects.
- `2026-05-23`: Keep the first slice rule-user-only. Transaction users,
  generated-child storage paths, actor-network endpoints, and lifetime
  ownership need separate scheduling and diagnostic contracts.

## Open Questions

- None for this bounded slice. Broader storage locks and memory-port
  protocols remain backlog.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-23` | `ISF-STORAGE-PORT-RESOURCE-PRIORITY.1` | `prove -Iperl t/1303-isf-public-live-book-paths-audit.t t/1250-isf-spec-focused-test-index-audit.t` | `passed: Files=2, Tests=25` |
| `2026-05-23` | `ISF-STORAGE-PORT-RESOURCE-PRIORITY.1` | `git diff --check` | `passed` |
| `2026-05-23` | `ISF-STORAGE-PORT-RESOURCE-PRIORITY.2` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm; perl -Iperl -c perl/FSM/Support/ISFResourceCatalog.pm` | `passed` |
| `2026-05-23` | `ISF-STORAGE-PORT-RESOURCE-PRIORITY.2` | `prove -Iperl t/1176-isf-resource-priority-boundary.t t/1218-isf-rule-slot-resource-arbitration.t t/1220-isf-arbitration-schedule-report.t` | `passed: Files=3, Tests=20` |
| `2026-05-23` | `ISF-STORAGE-PORT-RESOURCE-PRIORITY.2` | `prove -Iperl t/1176-isf-resource-priority-boundary.t t/1218-isf-rule-slot-resource-arbitration.t t/1220-isf-arbitration-schedule-report.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t` | `passed: Files=8, Tests=344` |
| `2026-05-23` | `ISF-STORAGE-PORT-RESOURCE-PRIORITY.2` | `mdbook build docs/book` | `passed` |
| `2026-05-23` | `ISF-STORAGE-PORT-RESOURCE-PRIORITY.2` | `./bin/ci-regression isf --no-book` | `passed: Files=250, Tests=1665` |
| `2026-05-23` | `ISF-STORAGE-PORT-RESOURCE-PRIORITY.2` | `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t` | `passed: Files=6, Tests=347` |
| `2026-05-23` | `ISF-STORAGE-PORT-RESOURCE-PRIORITY.2` | `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-STORAGE-PORT-RESOURCE-PRIORITY.1` | `8be2a572 ISF-STORAGE-PORT-RESOURCE-PRIORITY.1: select storage-port resources` | `selection slice` |
| `ISF-STORAGE-PORT-RESOURCE-PRIORITY.2` | `c2db0a8a ISF-STORAGE-PORT-RESOURCE-PRIORITY.2: ship storage-port resources` | `implementation slice` |

## Changelog

- `2026-05-23`: Created and activated the task tree.
- `2026-05-23`: Shipped bounded `storage_port` priority arbitration for
  declared rule users and closed the task tree.
