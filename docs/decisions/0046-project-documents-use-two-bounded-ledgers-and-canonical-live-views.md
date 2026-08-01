# 0046 — Project documents use two bounded ledgers and canonical live views

- Date: 2026-08-01
- Type: architecture/convention
- Status: partially superseded by `0047` (changelog), `0048` (achievement
  history), and `0049` (roadmap status)
- Refines: [0007](0007-memory-architecture-supersedes-blob-narration.md), [0025](0025-project-document-interim-lifecycle.md), [0041](0041-live-documents-use-bounded-views-over-durable-stores.md)
- Evidence owner: `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1`

## Context

The interim split in decision 0025 deliberately postponed the long-term roles
of `CHANGES.md`, `DEVELOPMENT_NOTES.md`, `ROADMAP_STATUS.md`, and
`LIVE_ACHIEVEMENT_STATUS.md`. The focused audit now shows that the first two
serve distinct human questions, while the two frozen status narratives no
longer do.

`CHANGES.md` and `DEVELOPMENT_NOTES.md` grew into multi-megabyte append-only
files, but their useful content is separable at whole-entry boundaries. The
roadmap-status and achievement-status files froze on `2026-06-01`; their
claimed live questions are now answered more accurately by the roadmap,
task-tree, bounded Memory pointer, retained changelog, and Git. One test and
one composition note still couple to `ROADMAP_STATUS.md`; those are migration
work, not evidence for retaining a stale live authority.

## Decision

1. Retain `CHANGES.md` as a curated rolling ledger. Every completed slice
   continues to receive one concise human-readable entry. Exact task evidence
   and chronology remain authoritative in task trees and Git.
2. Re-form that ledger as a bounded current/index view over sealed, ordered,
   whole-entry historical ranges with digest, dimension, reconstruction, and
   deterministic repository-relative retrieval proof.
3. Retain `DEVELOPMENT_NOTES.md` as a conditional rolling rationale ledger.
   Add an entry only for useful non-obvious implementation rationale,
   constraints, or local tradeoffs that have no better decision, fact, task,
   user-document, source-comment, or commit home.
4. Give the rationale ledger the same bounded current/index and sealed
   whole-entry integrity model. Never require a placeholder or per-slice note.
5. Supersede `ROADMAP_STATUS.md` as a live source. `ROADMAP_V2.md` owns
   direction, `docs/TASK_TREE.md` owns active work, and `MEMORY.md` owns the
   resume pointer. Preserve the exact frozen object under an archive/revision
   retrieval contract, migrate current consumers, then retire its live path.
6. Supersede `LIVE_ACHIEVEMENT_STATUS.md` as a live source. `CHANGES.md` owns
   the concise human summary; task trees and Git own exact completion evidence.
   Preserve its distinct exact frozen object, migrate current consumers, then
   retire its live path.
7. Do not merge or generate another status blob. Route each question to its
   canonical layer.
8. Decision 0025 remains the operational transition rule until containment
   leaves `.3`, `.4`, `.5`, and `.11` implement this selection. This decision
   alone does not permit either frozen file to change.

## Consequences

- Human change communication and exceptional local rationale remain available
  without making either root file an unbounded historical store.
- Current direction, execution state, recovery state, and completion history
  each have one canonical authority rather than synchronized prose copies.
- `t/1332-isf-atl-doc-status-audit.t`, the composition legacy note, workflow
  surfaces, README routes, book navigation, and lifecycle registries must be
  migrated before either frozen path is removed.
- Historical task and decision mentions remain intact as truthful evidence.
- Failed reconstruction, retrieval, consumer, or negative-control proof stops
  the affected migration without changing the other three selected outcomes.

## Later Refinement

Decision `0047` rejects the selected `CHANGES.md` ledger after the director
reopened its present value and the `.4` audit found no independent content or
executable consumer. The generic ledger schema remains available, and the
conditional-rationale and roadmap-status selections remain separately owned.
Because the achievement-status comparison relied partly on the retained
changelog, `.11` must re-audit its value and obtain an independent director
selection before changing that lifecycle.

The `2026-08-01` independent audit now finds no executable/content consumer or
current recovery/status role. Direct browsing of the frozen 23-day prose
digest is the one distinct retention case. The director selects retirement;
decision `0048` supersedes clause 6, preserves exact version retrieval, and
routes current questions to task evidence, the mdBook, bounded Memory, and Git.

The separate `ROADMAP_STATUS.md` audit fixed the unchanged 15,039-line object
and all 70 referring files, found no product/runtime/build consumer, one stale
negative test scan, one inaccurate active-source link, and no unique current
authority. Direct browsing of the March-June 2026 chronology plus R0-R14
snapshot was the sole distinct retention case. The director independently
selected retirement; decision `0049` supersedes clause 5, preserves exact
version retrieval, and routes current questions to the maintained roadmap,
task trees, bounded Memory, the mdBook, and Git.
