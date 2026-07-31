# 0041 — Live documents use bounded views over durable stores

- Date: 2026-07-31
- Type: architecture/convention
- Status: accepted
- Refines: [0007](0007-memory-architecture-supersedes-blob-narration.md), [0019](0019-task-tree-in-file-secondary-views-are-historical.md), [0025](0025-project-document-interim-lifecycle.md), [0040](0040-readme-routing-must-close-destination-pressure.md)
- Evidence owner: `README-POLICY-ROUTED-DESTINATION-PRESSURE-CLOSURE.2`

## Context

Decision 0040 proved that bounding one entry point is insufficient when its
overflow destinations can grow indefinitely. The clean follow-up census found
the same pressure pattern across document families: the roadmap and task index
are above 86% of their line ceilings; one active task file is 4,662,385 bytes;
one book chapter is above 88% of both per-part dimensions; the change and
rationale ledgers are above 90% of their line ceilings; and the generated
Knowledge Map is a 6,130,630-byte monolith even though its canonical fact cards
are already partitioned.

Simply splitting each blob into more files would bound a single read but leave
aggregate growth unchanged. Moving every old byte only to version history
would reduce working-tree pressure but would make maintained user reference
material needlessly obscure. The correct storage topology depends on whether
the information is current state, unique browsable reference, a generated
projection, or exact historical evidence.

The existing architecture already demonstrates the useful primitives.
Decision 0007 makes `MEMORY.md` a bounded overwrite-only view and version
history the exact audit trail. Decision 0019 rejects manually maintained
task-tree views that duplicate canonical nodes plus history. Decision 0025
keeps a concise live changelog and conditional rationale ledger while freezing
two legacy status files pending their own review. Those are specialized cases
of one broader document-lifecycle rule.

The implementation census added an important boundary that the original
destination audit missed. Top-level `README.md` is itself a governed surface,
and GitHub renders its contents as the public project landing page. Containing
its size must preserve its purpose, first-use path, architecture summary, and
navigation in that interface; moving the entire landing function behind a link
would satisfy a byte count while violating the user contract. The complete
2,772-path Markdown inventory also exposed aggregate root documents, focused
`docs/*.md`, ancillary documents, and canonical knowledge cards as collections
that need explicit coverage independent of README routing.

## Decision

1. Adopt `LIVE_DOCUMENT_SIZE_CONTAINMENT.md` as the project-owned doctrine.
   Its normative body is project-neutral, project-agnostic, and harness-
   neutral. FSMGen owner/date, measurements, limits, paths, and migrations live
   only in the fenced local adoption note, local audit, and future data
   registry. Agent bootstrap files are discovery pointers, never authority.
2. Separate each governed family into a bounded live view and the durable store
   appropriate to its information role. Current state overwrites; unique
   maintained reference uses navigable semantic partitions; generated views
   shard from smaller canonical units; ordered ledgers rotate and eventually
   archive; exact old evidence uses query-first immutable terminals; frozen
   legacy records cannot receive new content.
3. Sharding is not sufficient containment. Every collection has per-part,
   file-count, and aggregate controls plus a transition that prevents sealed
   shards from becoming the next unbounded neighbor.
4. Locally, warning begins at 80%, rollover is required at 90%, and the existing
   declared ceiling is the 100% hard failure. A warning requires an owned
   remediation. The clean census pins pre-existing transition debt; only
   continuity needed to implement this containment program may extend an
   already-over-rollover ledger before its migration. No hard limit or limit
   increase is excused merely to admit growth.
5. Removing bytes from the working tree requires a tracked descriptor that
   records the former path/range, immutable revision locator, line and byte
   counts, digest, current/replacement pointers, and a tool-neutral retrieval
   proof. User-facing material remains directly navigable unless a richer
   canonical user-facing home is proved.
6. Durable local storage is repository-root-relative and same-volume. Generated
   caches may live under `.artifacts/`, but they are disposable and cannot own
   unique information.
7. `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION` owns common registry/checker
   implementation and the exact family migrations selected in
   `docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_AUDIT.md`. This selection leaf performs
   no migration, content deletion, limit change, or product change.
8. The long-term roles of `CHANGES.md`, `DEVELOPMENT_NOTES.md`,
   `ROADMAP_STATUS.md`, and `LIVE_ACHIEVEMENT_STATUS.md` remain with the
   previously scheduled `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1`.
   Interim decision 0025 continues unchanged. The adoption tree may consume
   the review outcome and apply the selected containment topology, but does
   not pre-empt the files' semantic lifecycle owner.
9. The local machine registry uses JSON Lines rather than a positional table.
   Each line is one named, typed object; arrays carry paths and route targets,
   nested objects carry budgets/milestones/baselines, and unknown or malformed
   fields fail closed. This avoids the shifting-column and sentinel ambiguity
   already visible in the 22-column prototype while retaining line-oriented
   diffs and streaming. JSONL is the local serialization, not the doctrine:
   the neutral contract remains independent of project and harness identity.
10. An adoption baseline is immutable. When the containment program itself
    must add continuity records before a debt surface migrates, a distinct
    `transition` record names this adoption tree and a finite maximum growth in
    every budget dimension. The common checker rejects ownerless or excess
    growth. This preserves the original measurement instead of disguising each
    accepted append as a refreshed baseline.

## Consequences

- The memory doctrine becomes one consumer of a common architecture instead of
  the only bounded live-document policy.
- Maintained manuals stay approachable and directly browsable; engineering
  chronology stays exact without remaining in mandatory current reads.
- Per-file sharding cannot conceal unbounded aggregate growth.
- Every current high-water or structural outlier has a clean, separately
  committable owner before any destructive-looking migration begins.
- The common policy can be copied into another project or used by another
  harness without inheriting FSMGen nouns, paths, limits, or tool authority.
- README containment cannot hollow out the rendered project landing page.
- The common registry is self-describing and extensible without positional
  column drift; Perl's core `JSON::PP` keeps enforcement dependency-free here.
