# COMMIT WORKFLOW
This file is the authoritative commit workflow for this repository.
Its purpose is to let any new AI resume work safely and follow the same commit hygiene.

This workflow is strict and non-negotiable.
It exists so the project can recover swiftly, seamlessly, and accurately after session loss, application crashes, machine crashes, or agent handoff.
Ignoring it is not a style issue; it is a project-safety failure.

## Non-negotiable invariant
- If a task/activity is complete but not committed, that task is not finished.
- No code, test, source, generated-artifact, or config change may start unless
  the activity already has task-tree ownership, either through an existing
  leaf or a newly created `docs/tasks/*.md` tree/leaf.
- Every matching implementation change must satisfy `TASK_ACCEPTANCE.md` in
  the owning staged task file: fresh checked ROOT CAUSE, ADDRESSED, and NO
  REGRESSION boxes with the required box-scoped project-declared evidence.
- Run this workflow after every completed task, slice, lane, or task-scoped activity without exception.
- Do not let a long `pnt` streak, apparent momentum, or "just one more small thing" override this rule.
- Do not expect the user to remind you. The workflow must be followed automatically.
- Do not ask for user approval before running the commit workflow after a task is complete.
- Do not accumulate several completed slices in the worktree for a later cleanup commit.
- If you discover that multiple tasks have been mixed together, stop new work and recover them into the smallest honest task-scoped commits before continuing.

## When to run this workflow
- Run after each completed task, slice, lane, or task-scoped activity.
- Run when the user explicitly says `commit workflow`.
- Run before starting the next task/activity, before replying as if a slice is done, and before any context switch that could blur task boundaries.
- Do not wait for approval for commit-workflow steps.

## Files involved and precise role
- `COMMIT.md`
  - This workflow specification (tracked in git).
  - This is the only normative source of commit-workflow policy.
- `.agents/workflows/commit.md`
  - Agent-tooling helper only.
  - Must stay a thin wrapper that points back to `COMMIT.md`.
  - Must never define, extend, or contradict commit policy independently.
- `MEMORY.md`
  - **Layer-A bounded resume pointer** (see `MEMORY_ARCHITECTURE.md`): current state +
    the single next action only.
  - **OVERWRITE** its "Current state" block when recording completed work — never append.
    Keep it ≤ ~60 lines; this is mechanically capped by
    `scripts/check_doctrines.sh` (pre-commit hook + CI). Rationale and the
    reconciliation of this workflow with the memory standard: `docs/decisions/0007`.
- Former roadmap-status board
  - **RETIRED** under decision `0049`. `ROADMAP_V2.md` owns direction, task
    trees own live status/evidence, bounded Memory owns resume state, and Git
    owns exact chronology. Do not recreate a combined status projection.
- `docs/TASK_TREE.md` and `docs/tasks/*.md`
  - Repo-local task-tree workflow and per-top-level task files.
  - Must be updated before commit whenever a task-tree-managed activity changes a node status, current frontier, blocker, decision, validation evidence, or completion evidence.
  - Must stay below this file for commit policy: task-tree docs may require task IDs and evidence, but must not redefine the commit workflow independently.
- `DEVELOPMENT_NOTES.md`
  - **Conditional engineering rationale.** Update it only when the slice
    produces a useful design constraint, implementation rationale, or working
    decision that is not better owned by a decision record, fact card,
    task-tree entry, user document, or git. Do not add a placeholder entry for
    slices that do not warrant one. See `docs/decisions/0025`.
- Former achievement-status journal
  - **RETIRED** under decision `0048`. Do not recreate a live completion-history
    projection; task evidence, the mdBook, bounded Memory, and work-unit Git
    commits own its former questions, with exact old prose version-retrievable.
- `TASK_ACCEPTANCE.md`
  - Project-neutral code-slice acceptance contract. Its checker reads staged
    paths, task snapshots, and changed-line freshness from the Git index using
    the data-only declarations under `doctrine/task_acceptance/`.
- `git_message_brief.txt`
  - Short-lived commit message input file for `git commit -F`.
  - Must be overwritten for each commit and truncated to zero bytes after commit.
  - This file is intentionally ephemeral.
- Changed source/test/config files
  - All files touched by the task implementation.

## Required order of operations
1. Before changing code, tests, source files, generated artifacts, or config,
   verify the task-tree owner and current leaf. If none exists, create the
   smallest honest task tree or leaf from `docs/tasks/TEMPLATE.md` first.
2. Complete the task implementation.
3. Route every durable thing to its memory layer (per `MEMORY_ARCHITECTURE.md`),
   in this order:
   1. `docs/TASK_TREE.md` and the owning `docs/tasks/*.md` file — the task-tree (layer B):
      node status, current frontier, blocker, decision, validation/completion evidence.
   2. A new `docs/decisions/NNNN-*.md` record (layer C) **iff** the slice produced a
      durable cross-cutting fact/decision/learning (and update `docs/decisions/INDEX.md`).
   3. `MEMORY.md` (layer A) — **overwrite** its "Current state" block to point at the new
      latest commit / active leaf / next action; keep it ≤ ~60 lines.
   4. `DEVELOPMENT_NOTES.md` — update only when the conditional rationale
      boundary above is met.
   - Decisions `0047`, `0048`, and `0049` retire the former changelog,
     achievement journal, and roadmap-status board. Task evidence, the mdBook,
     bounded Memory, the maintained roadmap, and Git own their former current
     questions; do not recreate replacement narration blobs.
4. Run validation appropriate to the scope:
   - For code changes: syntax + tests/regression.
   - For doc-only changes: basic repo state checks are sufficient.
5. For a matching implementation change, complete the owning task file's
   fresh `TASK_ACCEPTANCE.md` checklist with tool-backed ROOT CAUSE, ADDRESSED,
   and NO REGRESSION evidence.
6. Write `git_message_brief.txt` with:
   - concise subject line,
   - key body lines or bullet points,
   - no attribution trailer unless the user explicitly asks for one.
   - If the completed activity belongs to a task-tree leaf, identify the leaf ID in the subject or first body line.
7. Stage intended tracked files (`git add ...`).
   - This and every later git write step must run sequentially.
8. Run `scripts/check_doctrines.sh` against the staged index. This includes
   `TASK-ACCEPTANCE`; do not treat its docs-only exemption as a code-slice pass.
9. Commit using:
   - `git --no-pager commit -F git_message_brief.txt`
10. Truncate message file:
   - `truncate -s 0 git_message_brief.txt`
11. Verify final state:
   - `git --no-pager status --short`
12. The user-facing close-out should include the current live status from the
   task-trees (`docs/TASK_TREE.md` Active table + the owning `docs/tasks/*.md`
   frontier), since decision `0049` retires the former roadmap-status board.
   - State how the completed task changed the active task-tree's status/frontier, or
     that it is unchanged.
   - Show at least the active work-unit's `Status` + brief description and its next
     frontier leaf; add brief sub-bullets where the next step matters for understanding
     progress.

## Required stop conditions
- If `git status --short` shows older unfinished work from another slice, do not start a fresh implementation task until that state is understood and resolved.
- If you accidentally completed work without committing it, the immediate next task is recovery: document it, validate it, split it into honest task-scoped commits, and only then resume feature work.
- If the worktree contains unrelated untracked material, leave it alone unless the user explicitly asked for it.
- If the next task requires code, test, source, generated-artifact, or config
  changes and no task-tree leaf owns it yet, do not start implementation until
  the work is attached to an existing active task tree or a new
  `docs/tasks/*.md` tree is created from `docs/tasks/TEMPLATE.md`.
- If the next task is `R14` / ISF work, apply the stricter ISF synchronization
  expectations in `docs/TASK_TREE.md` after the task-tree owner is selected.

## Safety and consistency rules
- Keep commits task-scoped (only files relevant to the completed task).
- Do not stage unrelated untracked directories (for example local sandboxes).
- Keep behavior-preserving refactor slices small and verifiable.
- Keep attribution trailers out of task-scoped commits unless the user explicitly asks for them.
- Run broad or potentially heavyweight local Perl/`prove`/`fsmgen` commands
  under `scripts/run_with_ram_guard.sh` or an equivalent active monitor. The
  default guard stops before host memory reaches the 90% danger zone; if it
  trips, record the resource caveat in the owning task tree instead of
  continuing unbounded.
- Prefer one completed slice per commit cycle. If a task naturally fans out into multiple independently valid slices, close each slice with this workflow before moving on.

## Git index safety
- Never parallelize git index-mutating commands.
- `git add`, `git rm`, `git mv`, `git commit`, and any equivalent git write step must run one after another, never in overlapping tool calls.
- Do not overlap git write operations against the same repository state, even if they look short or independent.
- Treat a stale `.git/index.lock` as workflow recovery, not as a normal part of the task.
- If `.git/index.lock` exists, stop and confirm that no intended git write command is still running.
- If the lock is stale, remove only `.git/index.lock`, retry the same blocked workflow step, and then continue the normal order.
- Do not skip ahead to a later workflow step while the index is locked.
