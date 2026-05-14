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
  Children: `ISF-RESOURCE-CATALOG.1`

- ID: `ISF-RESOURCE-CATALOG.1`
  Status: `done`
  Goal: `List current ISF shareable resource kinds in public docs.`
  Acceptance: `The spec, mdBook, public contract, backlog, live docs, and
  task-tree index agree on the current growable resource-kind catalog.`
  Verification: `prove -l t/1176-isf-resource-priority-boundary.t t/1218-isf-rule-slot-resource-arbitration.t`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-RESOURCE-CATALOG.1: publish resource kind catalog`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| - | - | `closed` | `ISF-RESOURCE-CATALOG.1` completed the requested catalog publication. |

## Decisions

- `2026-05-14`: The resource catalog is public documentation, not a blanket
  support claim. `rule_slot` is the only shipped enforced kind today; other
  names stay backlog until each has a lowering path, runtime semantics,
  diagnostics, report surface, and tests.
- `2026-05-14`: The catalog belongs in the spec, book, public contract, and
  backlog. The completed resource/priority implementation tree remains closed.

## Open Questions

- None for this documentation slice.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-14` | `ISF-RESOURCE-CATALOG.1` | `prove -l t/1176-isf-resource-priority-boundary.t t/1218-isf-rule-slot-resource-arbitration.t`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-RESOURCE-CATALOG.1` | `ISF-RESOURCE-CATALOG.1: publish resource kind catalog` | Documentation-only registry slice. |

## Changelog

- `2026-05-14`: Created and completed the documentation-only resource-kind
  catalog tree.
