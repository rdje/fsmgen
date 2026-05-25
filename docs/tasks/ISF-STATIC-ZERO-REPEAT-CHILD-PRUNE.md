# ISF-STATIC-ZERO-REPEAT-CHILD-PRUNE: Static Zero Repeat Child Activation Pruning

## Metadata

- Tree ID: `ISF-STATIC-ZERO-REPEAT-CHILD-PRUNE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Ship the next bounded static-zero repeat slice by allowing plain child
activation clauses inside statically zero repeat bodies to lower as true
zero-iteration no-ops without leaving parent, child, generated-top, or report
artifacts behind.

## Non-Goals

- Do not widen positive repeat behavior.
- Do not change known-width runtime repeat zero-bypass behavior.
- Do not implement static-zero pruning for parameterized, bound, or
  domain-annotated child activation sites.
- Do not implement activation-site override-specialized repeat lowering.
- Do not change repeat-body child re-entry rules for nonzero or runtime counts.

## Acceptance Criteria

- A statically zero repeat body containing plain `(spawn child as inst)` lowers
  as a zero-iteration no-op when the target is declared and the child
  transaction is reachable only through pruned static-zero activations.
- A statically zero repeat body containing plain `(do child)` lowers as a
  zero-iteration no-op when the target is declared and the child transaction
  is reachable only through pruned static-zero activations.
- The pruned cases emit no repeat counter, repeat init/check state,
  repeat-body state, generated child `.fsm`, generated top `.fsm`,
  generated child activation instance, local child start/done handoff, or
  `transaction_loops[]` entry.
- Targets that are referenced by nonzero/live child activation sites, rule
  triggers, or explicit external transaction entry guards are not pruned.
- Parameterized, bound, or domain-annotated child activation sites inside
  static-zero repeat bodies remain fail-closed with targeted diagnostics.
- Positive static repeat counts, runtime scalar repeat counts, and existing
  repeat-body child activation re-entry validation are unchanged.
- ISF spec, downstream handoff, public contract, mdBook, roadmap, task tree,
  README index, and live docs are synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-STATIC-ZERO-REPEAT-CHILD-PRUNE`
  Status: `done`
  Goal: `Prune bounded static-zero repeat child activation artifacts.`
  Children: `ISF-STATIC-ZERO-REPEAT-CHILD-PRUNE.1`

- ID: `ISF-STATIC-ZERO-REPEAT-CHILD-PRUNE.1`
  Status: `done`
  Goal: `Implement and document plain child-activation pruning for static zero repeat bodies.`
  Acceptance: `Plain static-zero repeat spawn/do bodies no-op without stale
  generated-child or local-child artifacts; parameterized/bound/domain forms
  remain fail-closed; focused and public docs are synchronized.`
  Verification: `syntax checks; focused repeat/parameter/child-boundary tests; focused public/book audits; full ISF regression; mdBook build; git diff --check`
  Commit: `ISF-STATIC-ZERO-REPEAT-CHILD-PRUNE.1: prune zero repeat children`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `ISF-STATIC-ZERO-REPEAT-CHILD-PRUNE.1` shipped plain static-zero repeat child activation pruning and closed the tree. |

## Decisions

- `2026-05-25`: Select a bounded pruning surface for plain child activations
  only. Parameterized, bound, and domain-annotated activation sites carry
  generated-child specialization metadata, so they remain deferred until a
  later slice explicitly specifies how to discard or validate unreachable
  specialization payloads.
- `2026-05-25`: Prune target transactions only when they have no live
  nonzero child activation/reference and no explicit external entry guard.
  This preserves independently activatable transactions while removing dead
  helper transactions that exist only for a statically skipped activation.

## Open Questions

- None blocking this bounded leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-STATIC-ZERO-REPEAT-CHILD-PRUNE.1` | syntax checks; focused repeat/parameter/child-boundary tests with `Files=4, Tests=71`; focused public/book audits with `Files=5, Tests=334`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | passed; full ISF regression `Files=275, Tests=1758` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-STATIC-ZERO-REPEAT-CHILD-PRUNE.1` | `ISF-STATIC-ZERO-REPEAT-CHILD-PRUNE.1: prune zero repeat children` | task-scoped commit subject |

## Changelog

- `2026-05-25`: Created task tree and selected the first implementation leaf.
- `2026-05-25`: Shipped plain static-zero repeat child activation pruning and
  closed the tree.
