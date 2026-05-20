# R9-STRICT-LEGACY-LTEPLUS-BOUNDARY: Strict Legacy <=+ Boundary

## Metadata

- Tree ID: `R9-STRICT-LEGACY-LTEPLUS-BOUNDARY`
- Status: `active`
- Roadmap lane: `R9`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Make strict mode reject the legacy `<=+` D-input dual-output assignment alias
while preserving default-mode compatibility and the preferred strict-supported
`<=-` spelling.

## Non-Goals

- Do not remove default-mode `<=+` compatibility.
- Do not change the preferred `<=-` assignment semantics.
- Do not change D-input self-dependency validation.
- Do not widen assignment operators, partial-LHS semantics, delayed-pulse
  semantics, or HDL lowering in this tree.
- Do not change ISF/ATL scheduling behavior.

## Acceptance Criteria

- The R9 strict-mode lane has task-tree ownership before source, test,
  fixture, or generated-artifact changes.
- The selected strict-mode cut is explicit: `<=+` is compatibility residue and
  strict users must author the preferred `<=-` spelling.
- Default mode continues to accept `<=+`.
- Strict mode rejects `<=+` through the shared frontend path with a targeted
  migration hint toward `<=-` and no HDL output.
- Strict mode still accepts canonical `<=-` pair forms, including the
  maintained partial-LHS fixture family.
- The maintained regression corpus separates strict-supported preferred
  partial-LHS fixtures from legacy `<=+` compatibility evidence.
- The mdBook, corpus documentation, roadmap, task tree, and live docs are
  synchronized with the behavior.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R9-STRICT-LEGACY-LTEPLUS-BOUNDARY`
  Status: `active`
  Goal: `Reject legacy '<=+' in strict mode while preserving default-mode
  compatibility.`
  Children: `R9-STRICT-LEGACY-LTEPLUS-BOUNDARY.1`,
  `R9-STRICT-LEGACY-LTEPLUS-BOUNDARY.2`

- ID: `R9-STRICT-LEGACY-LTEPLUS-BOUNDARY.1`
  Status: `done`
  Goal: `Select the legacy '<=+' strict-mode cut and scope fixture/doc
  reshaping.`
  Acceptance: `The task tree records '<=+' as the next high-signal R9
  compatibility cut after preferred '<=-' partial-LHS coverage, identifies the
  needed corpus fixture split, and selects '.2' as the bounded implementation
  leaf.`
  Verification: `static strict/corpus/book coverage audit`; `git diff --check`;
  `mdbook build docs/book`
  Commit: `R9-STRICT-LEGACY-LTEPLUS-BOUNDARY.1: select lteplus strict cut`

- ID: `R9-STRICT-LEGACY-LTEPLUS-BOUNDARY.2`
  Status: `pending`
  Goal: `Implement the strict-mode '<=+' rejection and corpus/doc sync.`
  Acceptance: `Shared frontend strict mode rejects pair and infix '<=+'
  compatibility forms with an '<=-' migration hint, default mode still accepts
  '<=+', preferred '<=-' fixtures remain strict-supported, the legacy alias is
  cataloged as compatibility residue, and focused plus corpus checks pass.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R9-STRICT-LEGACY-LTEPLUS-BOUNDARY.1` | `done` | Selected the next bounded strict-mode support-tier cut before code. |
| 2 | `R9-STRICT-LEGACY-LTEPLUS-BOUNDARY.2` | `pending` | Implement the selected strict-mode rejection and reshape strict/corpus docs. |

## Decisions

- `2026-05-20`: Selected this R9 tree after the R8 preferred `<=-`
  partial-LHS coverage and delayed-pulse fail-closed boundary reached
  completion. The project now has direct evidence for the preferred `<=-`
  partial-LHS spelling, so `<=+` can move from strict-supported alias
  compatibility to default-mode-only compatibility residue.
- `2026-05-20`: The implementation leaf must preserve the default-mode
  compatibility path for `<=+`. The strict-mode change is a support-tier
  boundary, not a removal of the legacy source surface.
- `2026-05-20`: The maintained partial-LHS fixtures currently mix preferred
  `<=-` and legacy `<=+` coverage while being tagged `strict_supported`.
  `.2` must split or rewrite those fixtures so strict-supported entries prove
  preferred syntax, while a separate legacy asset proves default-mode
  compatibility and strict-mode rejection.

## Open Questions

- None for `.2`.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `R9-STRICT-LEGACY-LTEPLUS-BOUNDARY.1` | `static strict/corpus/book coverage audit`; `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-20` | `R9-STRICT-LEGACY-LTEPLUS-BOUNDARY.2` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R9-STRICT-LEGACY-LTEPLUS-BOUNDARY.1` | `R9-STRICT-LEGACY-LTEPLUS-BOUNDARY.1: select lteplus strict cut` | Selects `<=+` as the next R9 strict-mode support-tier cut. |
| `R9-STRICT-LEGACY-LTEPLUS-BOUNDARY.2` | `pending` | `pending` |

## Changelog

- `2026-05-20`: Created and activated the tree, completed `.1`, and selected
  `.2` for strict-mode `<=+` rejection and corpus/doc synchronization.
