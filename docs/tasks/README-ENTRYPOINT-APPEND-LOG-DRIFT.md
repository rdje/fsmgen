# README-ENTRYPOINT-APPEND-LOG-DRIFT: Entry-Point README Has Become A Per-Leaf Append Log

## Metadata

- Tree ID: `README-ENTRYPOINT-APPEND-LOG-DRIFT`
- Status: `proposed`
- Roadmap lane: `infra/continuity / entry-point documentation`
- Created: `2026-07-25`
- Last updated: `2026-07-25`
- Owner: repo-local workflow
- Activation: **director-activated only.** Not PNT-eligible. Restructuring the
  system-of-record entry point is a judgment call, not a routine slice.

## Finding

`README.md` is the declared single entry point (`AGENTS.md` step 1,
`MEMORY_ARCHITECTURE.md` §7). It is now **9,911 lines / 928 KiB**, and its
`## Project objective` section alone spans **lines 74-7265 - 7,191 lines and
~507,000 characters, i.e. 73% of the whole file**. Inside that one section
there are **1,827 short-form leaf references** (`` `.NNN` ``) and **423 lines**
carrying `ships` / `shipped` / `selected` narration.

That section is no longer a project objective. It is a chronological, per-leaf
account of what each work-unit shipped - the same information git (layer D)
already holds and `git log --grep=<UNIT-ID>` already reconstructs.

## Why This Matters

This is the exact failure mode the repo's own memory standard was adopted to
kill, now recurring one file over:

- `MEMORY_ARCHITECTURE.md` §12 lists "Re-narrating git history into prose docs
  (duplication that goes stale)" and "One giant file you must read top-to-bottom
  to find 'what's next'" as anti-patterns.
- `MEMORY-ARCHITECTURE-ADOPTION` demoted `MEMORY.md` from 38,776 lines to a
  bounded 60-line pointer for this reason, and that cap is mechanically
  enforced. `README.md` carries no equivalent cap, so the growth moved here.
- The cost is paid on **every** session ramp-up in **every** harness, because
  the bootstrap chain routes every fresh agent to this file first. Reading the
  objective section in full is roughly 127k tokens before any work begins.
- Correctness risk: prose describing 800+ shipped leaves cannot be mechanically
  checked against the code, so it can drift silently. The task-trees and the
  mdBook are the surfaces that *are* checked.

## Non-Goals

- Not proposing deletion of any history. Everything in the section is already
  in git and recoverable.
- Not proposing changes to `MEMORY.md`, the task-trees, the decision store, or
  the Knowledge Map - those layers are working as designed.
- Not proposing an mdBook change; the book is user-facing product documentation
  and is a separate, healthy surface.
- Not proposing a mechanical README line cap in the same slice as any content
  move; a cap without an agreed target shape would just fail the build.

## Candidate Shapes (for director decision, none selected)

1. **Trim to a real entry point.** Keep objective, layout, navigation, and
   invariants; replace the per-leaf narration with pointers to
   `docs/TASK_TREE.md`, the owning trees, and `git log --grep`. Largest
   ramp-up saving; loses nothing recoverable.
2. **Split.** Keep `README.md` short and move the shipped-behavior narrative to
   a clearly-labelled `docs/SHIPPED_BEHAVIOR_LOG.md` that the bootstrap chain
   does *not* route agents through. Preserves the prose verbatim; halves the
   mandatory read.
3. **Cap and enforce.** Add a `README` size doctrine check under
   `scripts/check_doctrines.sh` after either 1 or 2, so the regrowth that
   produced this finding cannot recur silently. Only meaningful as a follow-up.
4. **Accept as-is.** Explicitly record that the entry point is intentionally an
   append log, and amend `MEMORY_ARCHITECTURE.md` §12 so doctrine and practice
   stop contradicting each other. Cheapest; keeps the ramp-up cost.

## Acceptance Criteria (if activated)

- A shape is selected and recorded as a decision record under `docs/decisions/`.
- No information is lost that is not already recoverable from git.
- The bootstrap chain (`AGENTS.md`, `CLAUDE.md`, `.cursorrules`,
  `GEMINI.md`, `.windsurfrules`, `.github/copilot-instructions.md`) still routes
  a fresh agent to a coherent system of record.
- `scripts/check_doctrines.sh` passes, including `DOCTRINE-BOOTSTRAP`, which
  asserts the bootstrap pointers.
- Committed through `COMMIT.md` with the leaf id in the subject.

## Task Tree

- ID: `README-ENTRYPOINT-APPEND-LOG-DRIFT`
  Status: `proposed`
  Goal: `Decide and apply the entry-point README shape so ramp-up cost and doctrine self-consistency are restored.`
  Children: `README-ENTRYPOINT-APPEND-LOG-DRIFT.1`

- ID: `README-ENTRYPOINT-APPEND-LOG-DRIFT.1`
  Status: `pending`
  Goal: `Select one candidate shape with the director and record it as a decision record.`
  Acceptance: `A decision record exists naming the selected shape and its rationale; this tree moves to active with implementation leaves, or to superseded if shape 4 is chosen.`
  Verification: `pending`
  Commit: `pending`

## Decisions

- `2026-07-25`: Filed as `proposed` and explicitly **not** PNT-eligible. The
  entry point is the system of record for every harness; changing its shape is
  the director's call, not an autonomous slice.
- `2026-07-25`: Measurements recorded here rather than left in a session
  transcript, so the finding survives session loss per
  `MEMORY_ARCHITECTURE.md` §4.

## Open Questions

- Which candidate shape does the director want? This blocks `.1` and nothing
  else; no active work depends on it.

## Blockers

- Awaiting director selection. Not blocking any other tree.
