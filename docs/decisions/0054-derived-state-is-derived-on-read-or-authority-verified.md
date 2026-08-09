# 0054 — Derived state is computed on read or retained behind an authority verifier

- Date: 2026-08-09
- Type: architecture/convention
- Status: accepted
- Refines: [0007](0007-memory-architecture-supersedes-blob-narration.md), [0041](0041-live-documents-use-bounded-views-over-durable-stores.md), [0044](0044-external-live-document-review-corrections-precede-wider-reuse.md), [0053](0053-portable-containment-adoption-guide-expands-governance-interface.md)
- Evidence owner: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.28`

## Context

PGEN's `docs/DERIVED_STATE_CONTAINMENT.md` identifies a content-truth gap in
the memory and live-document doctrines: a bounded field may still be a stale
hand-maintained copy of a value another system owns exactly. The sharpest case
is self-invalidating state such as a tracked `HEAD` copy whose own commit makes
the recorded value old.

FSMGen reproduced that class in both `MEMORY.md` and the reusable resume-pointer
template. The project already has two sound retained-copy forms: generated
projections with canonical inputs and executed freshness, and the active task
index with an executed source-alignment oracle. Work-unit measurements in task
and decision evidence are instead historical observations tied to their
recorded revision or invocation; judgement, intent, blockers, and next action
are not mechanically derivable.

The director also requires
`docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_ADOPTION_GUIDE.md` to remain the one
downstream entry point for every portable containment-doctrine revision.

## Decision

1. A mechanically exact current-state field is either `derive_on_read` or a
   `verified_copy`. Derive-on-read stores the exact accessor and forbids the
   copied field. A verified copy names its authority and recomputation path and
   passes an executed `core:`, `adapter:`, or fail-closed `external:` oracle.
2. The neutral checker consumes a separate bounded JSONL registry of explicit
   exact markers. It never embeds adopter field names or guesses semantics from
   dates, numeric shapes, or prose. Contract paths must belong to their named
   current surface; adapter proofs use an independent `derived:ID` namespace.
3. Immutable evidence is not a mutable current-state exception. It must name an
   exact revision, digest, invocation, or external observation boundary and
   remain subject to the applicable evidence, retention, archive, or frozen
   contract. Generated projections retain their existing surface-level
   canonical-input freshness contract.
4. Replace FSMGen's two `latest_commit` shadows with the in-place derivation
   `git log -1 --format='%H %s'`. Classify the active task-index frontier as an
   existing verified copy backed by `scripts/check_task_tree_integrity.pl`.
5. Before removing a duplicate, compare it with its authority and inspect that
   authority for divergence hidden by the copy. Preserve the reader's question
   through the derivation and repair the authority first when needed.
6. Every future portable doctrine revision updates the adoption guide in the
   same slice so forwarding that guide always exposes the complete package and
   its current adoption obligations. The normative project-owned doctrine and
   checker contracts remain separate authorities reached from the guide.

## Consequences

- A clean doctrine run rejects reintroduction of the declared resume revision
  shadows, removal of their reader accessors, off-surface declarations, and
  missing or unexecuted verified-copy truth checks.
- FSMGen stores no current `HEAD` copy in its bounded resume path, while a fresh
  reader can still obtain the exact revision and subject at the moment of use.
- Historical task/decision measurements remain legitimate evidence and no
  global date, count, or prose heuristic is introduced.
- The change adds no pressure-ceiling, lifecycle, retained-history, product,
  compiler, runtime, or generated-product behavior expansion.
