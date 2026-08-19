# 0068 — MEMORY.md is the frontier pointer, and COMMIT.md stops asking for anything else

- Date: 2026-08-19
- Type: infra/continuity governance
- Status: selected by `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.6`
- Refines: [0067](0067-layer-a-carries-no-decision-or-lane-summaries.md); amends the `MEMORY.md` steps of `COMMIT.md`
- Implementation owner: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.6`

## Context

`0067` removed the misplaced content and added a per-field control, but left the
instruction that produced it in place. The director's correction was direct:
`MEMORY.md` shall be a pointer to the frontier and nothing else, and the part of
`COMMIT.md` that grows it for no objective reason must change.

Three phrases in `COMMIT.md` were the driver, and each is executed by every
slice:

1. *"**OVERWRITE** its 'Current state' block **when recording completed work**"* —
   this literally instructs the agent to record completed work in layer A.
   Completed work is task-tree evidence.
2. *"current state + the single next action only"* — "current state" is broad
   enough to admit narration, and it did: the `current_state` field had reached
   nine lines restating two decision records.
3. *"point at the new **latest commit** / active leaf / next action"* — this asks
   for a stored `HEAD`, which also contradicts the `active_resume_repository_head`
   derive-on-read contract in
   `doctrine/live_document_size/derived_state_contracts.jsonl`.

No doctrine created the bloat and no agent was asked for it. The workflow step
asked for it, every slice, and nothing checked the result until the whole-file
cap fired many slices later.

## Decision

1. `MEMORY.md` holds the **frontier pointer only**: the active work unit, the
   single next action, and the in-flight/blocker flags, plus the reader
   derivation for `HEAD` that the derived-state contract requires. Nothing else.
2. The `current_state`, `push_state`, and `## Durable context` blocks are
   removed. Leaf status is the owning tree under `docs/tasks/`; push cadence is
   `COMMIT.md`'s own `Push cadence` section and decision `0062`; cross-cutting
   rationale is `docs/decisions/INDEX.md`. Each was a duplicate of a live
   authority, not a unique record.
3. `COMMIT.md` no longer says "when recording completed work" or "current
   state" for this file, and no longer asks for the latest commit. It now states
   the prohibition directly: never record here what the slice completed, never
   summarise a decision or a lane, never store `HEAD`.
4. The rule survives on three enforced controls rather than prose: the
   whole-file caps from `0066`, the per-field cap from `0067`, and the
   derive-on-read contract that already forbids a stored commit.

## Consequences

- `MEMORY.md` is **14 lines / 654 bytes**, from 50 / 3,800 at the start of the
  session and 30 / 1,690 after `0067`. It is 12% of its line cap and 2% of its
  byte maximum.
- A resume now costs one more hop by design: read the pointer, then open the
  named task tree whose frontier row is the precise next step. That is exactly
  the read path `MEMORY_ARCHITECTURE.md` §5 prescribes, and it was being
  short-circuited by a copy that drifted.
- The `0066` limits are now far above steady-state use. They are still not
  lowered here, for the reason `0067` gave: derive a target from a stable
  surface, not from one measured mid-compaction.
  `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.3` owns that audit.
- The lesson is recorded rather than the incident: a workflow step that runs on
  every slice is a stronger force than a written rule about restraint. When a
  bounded surface drifts, check what the workflow tells the agent to write
  before changing what the surface may hold.

## Containment

One bounded rationale record under the existing decision collection limits. The
prohibition lives in `COMMIT.md`, where the write happens, and in fact card
`memory-pointer-layer-a-content`; this record is the rationale home.
