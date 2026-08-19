# 0067 — Layer A carries no decision or lane summaries

- Date: 2026-08-19
- Type: infra/continuity governance
- Status: selected by `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.5`
- Refines: [0007](0007-memory-architecture-supersedes-blob-narration.md), [0066](0066-memory-pointer-size-is-two-externally-owned-criteria.md)
- Implementation owner: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.5`

## Context

`.2`, `.4`, and this record were all opened by the same recurring complaint:
`MEMORY.md` keeps running out of room. Two slices treated it as a limit problem
and moved limits. This one measured the file instead.

Of 50 lines, **23 — 46% — were a `## Durable context` block** holding two kinds
of content that `MEMORY_ARCHITECTURE.md` §6 explicitly excludes from layer A:

- one-line summaries of 14 cross-cutting decisions (`0034`, `0036`, `0037`,
  `0039`, `0041`, `0042`, `0043`, `0044`, `0045`, `0050`, `0051`, `0058`,
  `0059`, `0062`); and
- completion status for 10 task leaves (`.10.1`–`.10.4`, `.11`, `.15.1`–`.15.7`,
  `.17.4`).

Every item was verified against its authority before removal. All 14 decisions
exist on disk with exactly one `docs/decisions/INDEX.md` row each. All 10 leaves
exist as real nodes with goals and statuses in
`docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md`. Nothing in the
block was unique, so nothing was lost by removing it.

The audit also found the drift a convenient copy produces. The block attributed
"PNT is autonomous" to decision `0062`, which is about push cadence. Its actual
authority is decision `0003`. The duplicate had been quietly wrong, and the
authority was correct all along — the failure mode `MEMORY_ARCHITECTURE.md` §10
describes as "supersede, don't mutate" applied to a copy nobody was superseding.

The `## Resume` block had begun the same drift. Its `current_state` field was
**9 lines restating what decisions `0065` and `0066` said** — the identical
duplication, relocated one section up. Removing the `Durable context` block
alone would have left the mechanism intact.

That mechanism is an incentive, not an accident, and it is worth naming
precisely because it will recur:

- `COMMIT.md` step 3.3 makes **every** slice overwrite this file, so it is the
  one durable layer an agent is guaranteed to have open at the end of a slice.
- At that moment the agent holds fresh context and writing one summary line
  into the open file is cheaper than opening `docs/decisions/INDEX.md` and
  trusting a future session to find it there.
- Nothing objected. The only control was a whole-file line count that fired at
  60 — many slices after the drift began — and when it did fire, twice on
  2026-08-19, the response was to raise the cap rather than to ask what was in
  the wrong layer.

Each individual line is locally defensible and locally free. The cost is only
visible in aggregate, which is exactly the class of problem a mechanical check
exists to catch. Raising a cap buys time proportional to the raise and changes
nothing about the slope.

## Decision

1. Layer A holds no summaries of decisions and no lane or leaf completion
   status. Cross-cutting rationale is `docs/decisions/INDEX.md`; lane status is
   the owning tree under `docs/tasks/`; both are reachable in one bounded query
   through `knowledge-map/scripts/query_knowledge_map.sh`.
2. `MEMORY.md` may name the decisions the **current frontier** depends on, in
   the overwrite-only `## Durable context` block. That is layer A's own job —
   context for the next action — and it is bounded by construction, because it
   is rewritten with the frontier rather than appended to.
3. Do not rebuild the removed block. A future session that wants the semantic
   landscape reads `docs/decisions/INDEX.md`, which already carries a one-line
   summary per record and is 81 lines for 66 decisions.
4. Every field in the `## Resume` block is **state, not narration**, and is
   capped at 5 lines by `MEMORY_POINTER_FIELD_LINE_CAP` in
   `scripts/check_memory_architecture.sh`. A field that needs more than five
   lines is carrying rationale or lane status and must route to layer C or B.
   This is the control that makes the rule hold: it fails on the offending
   write itself rather than many slices later, and it is knob-configurable so
   another adopter can set its own value.
5. When `MEMORY.md` next approaches its whole-file cap, the first question is
   which content is in the wrong layer — not what the cap should be. A cap
   change is the answer only after that audit finds nothing to route.

## Consequences

- `MEMORY.md` drops from 50 lines / 3,800 bytes to **30 lines / 1,690 bytes** —
  25% of its line cap and 5% of its byte maximum. More importantly it loses the
  growth vector: what remains is overwritten each update rather than appended,
  and a field that starts narrating now fails the gate.
- The 120-line cap and 32,768-byte maximum from `0066` are unchanged and now sit
  well above steady-state use. They are deliberately not lowered in the same
  slice that reduced the content, because a target should be derived from a
  surface that has been stable, not from one measured mid-compaction. A later
  audit may ratchet them down; `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.3` is the
  natural owner.
- One real cost: a resuming agent no longer gets the semantic landscape for free
  in layer A. It costs one extra read of `docs/decisions/INDEX.md`, which is the
  read path `MEMORY_ARCHITECTURE.md` §5 prescribes.
- `0003`'s ownership of autonomous PNT is restored by removing the copy that
  mis-attributed it to `0062`.
- No limit, milestone, ratchet, verifier, authority requirement, or decision
  pairing changes. This record needs no ceiling authority.

## Containment

One bounded rationale record under the existing decision collection limits. The
rule is restated in the `MEMORY.md` block it governs and in fact card
`memory-pointer-layer-a-content`, so an author meets it before rebuilding the
block rather than after.
