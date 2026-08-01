# 0047 — Change history is task-tree evidence plus Git

- Date: 2026-08-01
- Type: architecture/convention/feedback
- Status: accepted
- Supersedes: the `CHANGES.md` clauses of `0025` and `0046`
- Evidence owner: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.4`

## Context

Decision `0025` reactivated a manually curated entry for every completed
slice, and decision `0046` selected a bounded rolling-ledger representation.
Before migration, the director reopened whether that view provides value
independent of the continuity architecture now enforced by the repository.

The exact `329d7cf1b:CHANGES.md` object is 32,299 lines / 2,696,664 bytes /
2,987 level-three entries at SHA-256
`6a1b0819fd44036130324d0a178c9e147e4e41fc91b8faca20ef5a170d6b2f98`.
The complete consumer census finds 64 tracked references outside the file.
Only one is executable, and it is the route-pressure test for the policy that
requires the file. The other live references create that policy/navigation
loop or record historical evidence. No product, build, runtime, user guide,
or continuity mechanism consumes its content.

The claimed reader question—what materially changed in a work unit—is already
answered more exactly by the owning task node and the work-unit-bearing Git
commit subject/diff. `MEMORY.md` answers what is active, decisions and fact
cards answer why/what is established, and the mdBook is the user-facing view
of shipped behavior. Maintaining another editorial summary adds no unique
fact and can drift from those authorities.

## Decision

1. Retire and delete the live `CHANGES.md` path. Do not migrate it into a
   bounded ledger and do not generate a replacement changelog.
2. Stop requiring a per-slice changelog entry. Each completed slice still
   updates its owning task evidence and bounded Memory pointer, uses its work-
   unit ID in the Git subject, updates decisions/facts/mdBook when warranted,
   passes the staged doctrine gate, and commits before the next slice.
3. Route current change queries to the owning task tree and
   `git log --grep=<UNIT-ID>`; Git remains the exact chronological audit trail.
4. Preserve the exact retired object through the
   `fsmgen_required_history` version-retention contract and an executed archive
   descriptor. Its deterministic retrieval is
   `git show 329d7cf1b09319899fb59cc9863cdfffddfa40dc:CHANGES.md`.
5. Keep the generic bounded-ledger schema shipped by containment `.3`; other
   adopters and the separately reviewed conditional rationale ledger may still
   use it. This decision does not select a lifecycle for
   `DEVELOPMENT_NOTES.md`, `ROADMAP_STATUS.md`, or
   `LIVE_ACHIEVEMENT_STATUS.md`.
6. Permit a transition baseline to move only downward when an atomic,
   verified content reduction makes the prior baseline incompatible with the
   required stale-headroom ratchet. Baseline increases and shape changes remain
   forbidden; baseline plus owned growth must still fit below the reduced
   ceiling.

## Consequences

- One 2.7-MB duplicate live history and its mandatory per-slice write burden
  leave the working tree without losing exact recovery.
- Task trees and Git become the only change-history authorities; no manually
  synchronized third narration can disagree with them.
- README routing, commit workflow, bootstrap instructions, tooling guidance,
  mdBook navigation, Knowledge Map facts, live-size surfaces, and regression
  fixtures must all stop treating the retired path as current.
- The broader agent-era continuity-document review remains owned by `.26`.
- The root-document surface ratchets its file-count, per-document line-count,
  aggregate-line, and aggregate-byte baseline/ceiling dimensions downward in
  the same atomic retirement instead of keeping impossible stale headroom.
