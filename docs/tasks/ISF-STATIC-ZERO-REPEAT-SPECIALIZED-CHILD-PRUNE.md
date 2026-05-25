# ISF-STATIC-ZERO-REPEAT-SPECIALIZED-CHILD-PRUNE: Static Zero Repeat Specialized Child Activation Pruning

## Metadata

- Tree ID: `ISF-STATIC-ZERO-REPEAT-SPECIALIZED-CHILD-PRUNE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Finish the bounded static-zero repeat child-activation pruning surface by
allowing syntactically valid parameterized, bound, or domain-annotated child
activation clauses inside statically zero repeat bodies to lower as true
zero-iteration no-ops without emitting generated-child specialization
artifacts.

## Non-Goals

- Do not widen positive repeat behavior.
- Do not change known-width runtime repeat zero-bypass behavior.
- Do not implement per-activation specialization for nonzero repeat bodies.
- Do not validate dead activation payloads against child parameter, port, or
  domain declarations beyond existing activation subclause shape validation.
- Do not change repeat-body child re-entry rules for nonzero or runtime counts.

## Acceptance Criteria

- A statically zero repeat body containing `(spawn child as inst (params ...))`
  lowers as a zero-iteration no-op when the activation subclause shape is
  valid.
- A statically zero repeat body containing `(do child (params ...) (bind ...)
  (domain ...))` lowers as a zero-iteration no-op when the activation
  subclause shapes are valid.
- The pruned specialized cases emit no repeat counter, repeat init/check
  state, repeat-body state, generated child `.fsm`, generated top `.fsm`,
  generated child activation instance, local child start/done handoff, or
  `transaction_loops[]` entry.
- Targets that are referenced by nonzero/live child activation sites, rule
  triggers, or explicit external transaction entry guards are not pruned.
- Malformed activation subclause syntax inside static-zero repeat bodies still
  fails closed through the existing activation clause shape diagnostics.
- Positive static repeat counts, runtime scalar repeat counts, and existing
  repeat-body child activation re-entry validation are unchanged.
- ISF spec, downstream handoff, public contract, mdBook, roadmap, task tree,
  README index, and live docs are synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-STATIC-ZERO-REPEAT-SPECIALIZED-CHILD-PRUNE`
  Status: `done`
  Goal: `Prune bounded static-zero repeat specialized child activation artifacts.`
  Children: `ISF-STATIC-ZERO-REPEAT-SPECIALIZED-CHILD-PRUNE.1`

- ID: `ISF-STATIC-ZERO-REPEAT-SPECIALIZED-CHILD-PRUNE.1`
  Status: `done`
  Goal: `Implement and document specialized child-activation pruning for static zero repeat bodies.`
  Acceptance: `Parameterized, bound, and domain-annotated static-zero repeat
  spawn/do bodies no-op without stale generated-child or local-child artifacts;
  malformed activation subclause syntax remains fail-closed; focused and
  public docs are synchronized.`
  Verification: `syntax checks; focused repeat/parameter/child-boundary tests; focused public/book audits; full ISF regression; mdBook build; git diff --check`
  Commit: `ISF-STATIC-ZERO-REPEAT-SPECIALIZED-CHILD-PRUNE.1: prune specialized zero children`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `ISF-STATIC-ZERO-REPEAT-SPECIALIZED-CHILD-PRUNE.1` shipped specialized static-zero repeat child activation pruning and closed the tree. |

## Decisions

- `2026-05-25`: Treat syntactically valid activation payloads under
  statically zero repeats as dead payloads. The lowerer should validate the
  activation clause shape, then prune the unreachable activation and any
  otherwise-dead child transaction without validating the dead payload against
  child parameter, port, or domain declarations.

## Open Questions

- None blocking this bounded leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-STATIC-ZERO-REPEAT-SPECIALIZED-CHILD-PRUNE.1` | syntax checks; focused repeat/parameter/child-boundary tests with `Files=4, Tests=72`; focused public/book audits with `Files=5, Tests=334`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | passed; full ISF regression `Files=275, Tests=1759` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-STATIC-ZERO-REPEAT-SPECIALIZED-CHILD-PRUNE.1` | `ISF-STATIC-ZERO-REPEAT-SPECIALIZED-CHILD-PRUNE.1: prune specialized zero children` | task-scoped commit subject |

## Changelog

- `2026-05-25`: Created task tree and selected the first implementation leaf.
- `2026-05-25`: Shipped specialized static-zero repeat child activation
  pruning and closed the tree.
