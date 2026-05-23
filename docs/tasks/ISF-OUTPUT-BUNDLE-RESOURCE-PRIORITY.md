# ISF-OUTPUT-BUNDLE-RESOURCE-PRIORITY: Output Bundle Priority Resource

## Metadata

- Tree ID: `ISF-OUTPUT-BUNDLE-RESOURCE-PRIORITY`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-23`
- Last updated: `2026-05-23`
- Owner: repo-local workflow

## Goal

Ship the first non-`rule_slot` shareable resource kind by enforcing
`output_bundle` resources for declared rule users under the existing static
`priority` arbiter.

The selected implementation boundary treats the named resource as an
author-declared bundle of actor outputs or LHS targets. In the current
resource grammar, bundle membership is represented by the participating rule
users and their driven assignments; there is not yet a separate member-list
subclause. The lowerer should therefore reuse the existing priority grant
shape to gate losing rule DTs for that named bundle while preserving the
current report key family.

## Non-Goals

- Do not implement `interface_bundle`, `named_drive`, `transaction_start`,
  `child_instance`, or `storage_port` enforcement.
- Do not implement `round_robin` arbitration.
- Do not implement transaction users, named-drive users, output-target users,
  dynamic resource names, multi-capacity resources, fairness state, hold/release
  semantics, or per-resource route mux/storage.
- Do not add a new output-bundle member-list syntax in this tree.
- Do not change shipped `rule_slot` behavior, priority declarations, or
  rule/transaction priority conflict handling.

## Acceptance Criteria

- `output_bundle` remains parser-recognized metadata and becomes an enforced
  resource kind only for declared rule users with `(arbiter priority)`.
- The lowerer rejects unsupported `output_bundle` combinations with targeted
  diagnostics: non-`priority` arbiters, unknown/non-rule users, incomplete
  priority orderings, and priority cycles.
- For a valid `output_bundle`, the lower-priority rule DT is guarded off when
  a higher-priority rule user requests the bundle in the same cycle.
- Assignment provenance and schedule reports expose the existing
  `resource_arbitration[]` shape for `output_bundle` grants without changing
  the report key family.
- Existing `rule_slot`, priority, conflict, public contract, and resource
  catalog behavior remains unchanged except for the newly enforced
  `output_bundle` status.
- ISF spec, downstream integration handoff, public contract, mdBook, roadmap
  status, task-tree index, and live docs are synchronized.
- Focused validation covers parser metadata, successful output-bundle grant
  gating, HDL handoff, report projection, public resource catalog metadata,
  and fail-closed unsupported surfaces; broader ISF regression runs if focused
  checks pass.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-OUTPUT-BUNDLE-RESOURCE-PRIORITY`
  Status: `active`
  Goal: `Enforce output_bundle resources for rule users under priority arbitration`
  Children: `ISF-OUTPUT-BUNDLE-RESOURCE-PRIORITY.1`,
  `ISF-OUTPUT-BUNDLE-RESOURCE-PRIORITY.2`

- ID: `ISF-OUTPUT-BUNDLE-RESOURCE-PRIORITY.1`
  Status: `done`
  Goal: `Select the bounded output_bundle priority resource slice`
  Acceptance: `The active tree, frontier, non-goals, acceptance criteria, and
  live roadmap/docs identify the exact selected implementation boundary before
  any code changes.`
  Verification: `documentation-only selection review, live-doc audits,
  git diff check`
  Commit: `pending this commit`

- ID: `ISF-OUTPUT-BUNDLE-RESOURCE-PRIORITY.2`
  Status: `active`
  Goal: `Implement output_bundle priority resource enforcement`
  Acceptance: `The resource catalog status, scheduler lowering, tests,
  public contract metadata, specs, mdBook, and live docs are updated and
  validated.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-OUTPUT-BUNDLE-RESOURCE-PRIORITY.2` | `active` | `The selected output_bundle boundary is recorded; behavior-bearing work can start after this selection commit.` |

## Decisions

- `2026-05-23`: Select `output_bundle` as the next R14 scheduler limitation
  because it is already a parser-recognized resource-kind catalog value, its
  bounded rule-user/priority subset can reuse the shipped static grant shape,
  and it advances resource arbitration without inventing route muxes,
  fairness state, or new syntax.
- `2026-05-23`: Keep the first `output_bundle` surface rule-user-only. The
  current grammar names a resource and its users, but it does not name bundle
  members separately. Broader target-member syntax and output-target users
  remain deferred until their ownership and diagnostics are explicit.

## Open Questions

- None for the selected leaf. Broader resource kinds, arbiters, users, and
  membership syntax remain backlog and are not required for this tree.

## Blockers

- None for selection. Implementation depends on reusing the existing
  priority resource grant shape without weakening `rule_slot` coverage.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-23` | `ISF-OUTPUT-BUNDLE-RESOURCE-PRIORITY.1` | `documentation-only selection review` | `passed` |
| `2026-05-23` | `ISF-OUTPUT-BUNDLE-RESOURCE-PRIORITY.1` | `prove -Iperl t/1303-isf-public-live-book-paths-audit.t t/1250-isf-spec-focused-test-index-audit.t` | `passed: Files=2, Tests=25` |
| `2026-05-23` | `ISF-OUTPUT-BUNDLE-RESOURCE-PRIORITY.1` | `git diff --check` | `passed` |
| `2026-05-23` | `ISF-OUTPUT-BUNDLE-RESOURCE-PRIORITY.2` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-OUTPUT-BUNDLE-RESOURCE-PRIORITY.1` | `pending this commit: ISF-OUTPUT-BUNDLE-RESOURCE-PRIORITY.1: select output_bundle priority resource` | `selection slice` |
| `ISF-OUTPUT-BUNDLE-RESOURCE-PRIORITY.2` | `pending` | `pending` |

## Changelog

- `2026-05-23`: Created and activated task tree; selected
  `ISF-OUTPUT-BUNDLE-RESOURCE-PRIORITY.2` as the implementation frontier after
  the selection commit.
