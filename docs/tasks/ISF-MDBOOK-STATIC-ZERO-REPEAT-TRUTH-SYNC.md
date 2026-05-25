# ISF-MDBOOK-STATIC-ZERO-REPEAT-TRUTH-SYNC: Static-Zero Repeat mdBook Truth Sync

## Metadata

- Tree ID: `ISF-MDBOOK-STATIC-ZERO-REPEAT-TRUTH-SYNC`
- Status: `done`
- Roadmap lane: `R14 documentation truth sync`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Synchronize the mdBook introduction to ISF with the shipped R14 static-zero
repeat child-activation pruning behavior. The book must no longer describe the
pre-pruning do/spawn zero-repeat limitation after the dedicated
child-activation pruning slices shipped.

## Non-Goals

- Do not change parser, scheduler, generated `.fsm`, HDL, public report,
  public API, test, or runtime behavior.
- Do not widen repeat-body child activation semantics.
- Do not alter the current fail-closed behavior for malformed activation
  subclause syntax or unsupported repeat count sources.
- Do not stage unrelated untracked local material.

## Acceptance Criteria

- `docs/book/src/13-intent-scheduling.md` describes static-zero repeat child
  activation pruning consistently with the shipped contract:
  plain and syntactically valid specialized `do`/`spawn` activations are
  pruned with no child/top/handoff artifacts when the target is not otherwise
  live.
- The stale pre-pruning do/spawn zero-repeat limitation sentence is removed.
- README, task tree, roadmap, live docs, change history, development notes,
  and memory are synchronized.
- Validation confirms the stale wording is gone, the mdBook builds, and
  `git diff --check` passes.
- The leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-MDBOOK-STATIC-ZERO-REPEAT-TRUTH-SYNC`
  Status: `done`
  Goal: `Synchronize mdBook static-zero repeat child-activation wording.`
  Children: `ISF-MDBOOK-STATIC-ZERO-REPEAT-TRUTH-SYNC.1`

- ID: `ISF-MDBOOK-STATIC-ZERO-REPEAT-TRUTH-SYNC.1`
  Status: `done`
  Goal: `Replace stale zero-count repeat do/spawn fail-closed wording in the ISF introduction.`
  Acceptance: `The mdBook introduction matches the shipped static-zero repeat child-activation pruning behavior and live docs are synchronized.`
  Verification: `stale wording grep; mdbook build docs/book; prove -Iperl t/1305-isf-book-feature-matrix-audit.t; git diff --check`
  Commit: `ISF-MDBOOK-STATIC-ZERO-REPEAT-TRUTH-SYNC.1: sync zero repeat book wording`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `ISF-MDBOOK-STATIC-ZERO-REPEAT-TRUTH-SYNC.1` removed stale mdBook static-zero repeat do/spawn fail-closed wording. |

## Decisions

- `2026-05-25`: Treat this as documentation-only. The shipped behavior already
  exists in the lowerer, public contract, downstream handoff, transaction
  chapter, lowering reference, feature matrix, and tests; this slice only
  corrects the stale ISF introduction prose.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-MDBOOK-STATIC-ZERO-REPEAT-TRUTH-SYNC.1` | stale wording grep; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `git diff --check` | passed |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-MDBOOK-STATIC-ZERO-REPEAT-TRUTH-SYNC.1` | `ISF-MDBOOK-STATIC-ZERO-REPEAT-TRUTH-SYNC.1: sync zero repeat book wording` | task-scoped commit subject |

## Changelog

- `2026-05-25`: Created and closed the documentation truth-sync tree after
  aligning the ISF introduction with shipped static-zero repeat child
  activation pruning.
