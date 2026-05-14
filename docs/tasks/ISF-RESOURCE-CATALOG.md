# ISF-RESOURCE-CATALOG: Shareable Resource Kind Registry

## Metadata

- Tree ID: `ISF-RESOURCE-CATALOG`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-14`
- Last updated: `2026-05-14`
- Owner: repo-local workflow

## Goal

Publish a small, growable list of ISF shareable resource kinds so authors and
downstream consumers can distinguish shipped runtime behavior from named
backlog resource categories.

## Non-Goals

- Do not implement new resource arbiters or resource kinds in this tree.
- Do not treat parser acceptance as a runtime support claim.
- Do not reopen the completed resource/priority implementation tree.

## Acceptance Criteria

- The public ISF spec lists the current resource-kind catalog.
- The mdBook rules chapter lists the same catalog and corrects stale resource
  enforcement text.
- The public ISF contract document describes shipped versus backlog resource
  kinds.
- The feature backlog keeps the same resource-kind names visible for future
  implementation slices.
- Live docs and roadmap status record the completed catalog slice.
- The slice is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-RESOURCE-CATALOG`
  Status: `done`
  Goal: `Publish the shareable resource kind registry.`
  Children: `ISF-RESOURCE-CATALOG.1`, `ISF-RESOURCE-CATALOG.2`

- ID: `ISF-RESOURCE-CATALOG.1`
  Status: `done`
  Goal: `List current ISF shareable resource kinds in public docs.`
  Acceptance: `The spec, mdBook, public contract, backlog, live docs, and
  task-tree index agree on the current growable resource-kind catalog.`
  Verification: `prove -l t/1176-isf-resource-priority-boundary.t t/1218-isf-rule-slot-resource-arbitration.t`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-RESOURCE-CATALOG.1: publish resource kind catalog`

- ID: `ISF-RESOURCE-CATALOG.2`
  Status: `done`
  Goal: `Clarify that the catalog is the public growable registry of shareable resources.`
  Acceptance: `The spec, mdBook rules chapter, public contract, and backlog
  explicitly describe the table as the current public registry, distinguish
  resource names from resource kinds, and preserve the shipped/backlog
  boundary.`
  Verification: `prove -l t/1176-isf-resource-priority-boundary.t t/1218-isf-rule-slot-resource-arbitration.t`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-RESOURCE-CATALOG.2: clarify shareable resource registry`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| - | - | `closed` | `ISF-RESOURCE-CATALOG.2` completed the requested registry clarification. |

## Decisions

- `2026-05-14`: The resource catalog is public documentation, not a blanket
  support claim. `rule_slot` is the only shipped enforced kind today; other
  names stay backlog until each has a lowering path, runtime semantics,
  diagnostics, report surface, and tests.
- `2026-05-14`: The catalog belongs in the spec, book, public contract, and
  backlog. The completed resource/priority implementation tree remains closed.
- `2026-05-14`: The resource table is the public growable registry of
  shareable resource kinds. Resource names remain author-defined instance
  handles; resource kinds are the registry entries that say what class of
  hardware or scheduler-controlled ownership domain is being shared.

## Open Questions

- None for this documentation slice.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-14` | `ISF-RESOURCE-CATALOG.1` | `prove -l t/1176-isf-resource-priority-boundary.t t/1218-isf-rule-slot-resource-arbitration.t`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-14` | `ISF-RESOURCE-CATALOG.2` | `prove -l t/1176-isf-resource-priority-boundary.t t/1218-isf-rule-slot-resource-arbitration.t`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-RESOURCE-CATALOG.1` | `ISF-RESOURCE-CATALOG.1: publish resource kind catalog` | Documentation-only registry slice. |
| `ISF-RESOURCE-CATALOG.2` | `ISF-RESOURCE-CATALOG.2: clarify shareable resource registry` | Documentation-only clarification that the catalog is the public growable registry. |

## Changelog

- `2026-05-14`: Created and completed the documentation-only resource-kind
  catalog tree.
- `2026-05-14`: Clarified the catalog as the public growable registry of ISF
  shareable resource kinds.
