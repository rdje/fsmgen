# 0021 — `README.md` is a bounded discovery entry point, not an append log

- Date: 2026-07-25
- Type: convention
- Status: accepted (executed in `README-ENTRYPOINT-APPEND-LOG-DRIFT.2`/`.3`/`.4`)
- Extends: [0007](0007-memory-architecture-supersedes-blob-narration.md)

## Context

`README.md` is the declared single entry point. `AGENTS.md` step 1 and
`MEMORY_ARCHITECTURE.md` §7 route every agent, in every harness, through it
before anything else.

By `2026-07-25` it had grown to **9,911 lines / 928 KiB**, and a single
`## Project objective` section spanned lines 74–7265: **7,191 lines and
~507,000 characters — 73% of the file** — containing **1,827 short-form leaf
references** (`` `.NNN` ``) and 423 `ships`/`shipped`/`selected` narration
lines. Sampling confirmed that from roughly line 183 onward the section is
continuous per-leaf chronology of the form "`.286` selected `.287`, and `.287`
now ships …".

This is the same failure `0007` diagnosed, relocated one file over.
`MEMORY_ARCHITECTURE.md` §12 names it directly — "re-narrating git history into
prose docs (duplication that goes stale)" and "one giant file you must read
top-to-bottom to find 'what's next'". `0007` froze the four legacy prose blobs
and `MEMORY-ARCHITECTURE-ADOPTION` demoted `MEMORY.md` from 38,776 lines to a
**mechanically capped** 60. `README.md` had no equivalent cap, so the growth
migrated into the one file the bootstrap chain guarantees will be read.

Two costs, both real:

- **Ramp-up.** Reading the objective section in full is roughly 127k tokens
  before any work starts, paid on every session, in every harness. In practice
  agents skim it instead — so the file is simultaneously expensive and unread.
- **Silent drift.** Prose describing 800+ shipped leaves cannot be mechanically
  checked against the code. The task-trees, the mdBook, the support-accounting
  catalog, and the Knowledge Map *are* checked; this narration was not.

The `README maintenance policy` section already said the file "does **not** need
to be updated on every commit — only when meaningful for onboarding accuracy."
The append log grew in violation of the README's own stated policy, which is
precisely the §9 lesson: **a rule nothing checks is a rule nothing follows.**

## Decision

Director instruction, `2026-07-25`: *"README.md shall NOT be used as a per-leaf
append log, please strictly follow the doctrine MEMORY_ARCHITECTURE.md
advocates."*

1. **`README.md` is a bounded discovery entry point.** It carries the project
   objective, the layer model, the repository layout, the standard commands,
   the working invariants, and navigation. Nothing else.
2. **It must not narrate per-leaf history.** Work-unit chronology belongs to
   git (layer D, greppable by `git log --grep=<UNIT-ID>`) and to the owning
   task-trees (layer B). Durable cross-cutting facts belong to
   `docs/decisions/` (layer C). User-facing behavior belongs to the mdBook.
   Sample inventory belongs to `docs/REGRESSION_CORPUS.md` and the
   support-accounting catalog.
3. **Nothing is deleted from the project.** `README.md` is tracked, so removed
   prose stays recoverable via `git log -p -- README.md` — the same treatment
   `MEMORY.md`'s 38,776-line predecessor received. We stop carrying it forward;
   we do not destroy it.
4. **The rule is mechanically enforced.** A registered doctrine check gates
   README size and per-leaf-chronology density, so this regrowth fails the
   build rather than recurring silently.

## Consequences

- A fresh agent's mandatory first read drops by roughly two orders of magnitude,
  and what remains is navigational — pointers to layers that are checked.
- Per-leaf detail is not lost; it moves to the layer that already owns it and is
  reachable by `git log --grep`, the task-tree node lists, and the Knowledge Map.
- Writing a slice no longer includes "append what I shipped to the README". The
  `COMMIT.md` write path (task-tree → decision record → bounded `MEMORY.md`)
  is the complete route; the README is touched only when onboarding facts change,
  as its own maintenance policy always required.
- Adding the check makes the doctrine registry the single place where "how big
  may the entry point be" is answered, consistent with §9 E2.
- Accepted trade-off: a reader who wants the shipped-behavior narrative must run
  `git log --grep=<UNIT-ID>` or open the owning tree instead of scrolling one
  file. That is the intended direction — those sources are current by
  construction, while the prose was not.
