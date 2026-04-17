# COMMIT WORKFLOW
This file is the authoritative commit workflow for this repository.
Its purpose is to let any new AI resume work safely and follow the same commit hygiene.

## When to run this workflow
- Run after each completed task/activity.
- Run when the user explicitly says `commit workflow`.
- Do not wait for approval for commit-workflow steps.

## Files involved and precise role
- `COMMIT.md`
  - This workflow specification (tracked in git).
- `MEMORY.md`
  - Live continuity state for crash recovery/handoff.
  - Must be updated first when recording completed work.
- `ROADMAP_STATUS.md`
  - Canonical live roadmap/workstream board.
  - Must be updated before commit whenever a task changes status, deliverables, remaining work, or the current active lane.
  - Every workstream in this board must keep explicit `Description`, `Deliverables`, `Status`, `Done`, `Left`, and `Exit criteria`.
- `CHANGES.md`
  - Persistent technical change history.
  - Must be updated after `MEMORY.md` and any needed `ROADMAP_STATUS.md` refresh.
  - When live status changes, this is the required historical log of that status transition.
- `DEVELOPMENT_NOTES.md`
  - Design rationale and engineering context.
  - Must be updated after `CHANGES.md`.
- `git_message_brief.txt`
  - Short-lived commit message input file for `git commit -F`.
  - Must be overwritten for each commit and truncated to zero bytes after commit.
  - This file is intentionally ephemeral.
- Changed source/test/config files
  - All files touched by the task implementation.

## Required order of operations
1. Complete the task implementation.
2. Update docs in this exact order:
   1. `MEMORY.md`
   2. `ROADMAP_STATUS.md` if the task changed roadmap status, deliverables, remaining work, or the current active lane
   3. `CHANGES.md` and explicitly log any live-status change there
   4. `DEVELOPMENT_NOTES.md`
3. Run validation appropriate to the scope:
   - For code changes: syntax + tests/regression.
   - For doc-only changes: basic repo state checks are sufficient.
4. Write `git_message_brief.txt` with:
   - concise subject line,
   - key bullet points.
   - Do not add attribution trailers unless the user explicitly asks for them.
5. Stage intended tracked files (`git add ...`).
6. Commit using:
   - `git --no-pager commit -F git_message_brief.txt`
7. Truncate message file:
   - `truncate -s 0 git_message_brief.txt`
8. Verify final state:
   - `git --no-pager status --short`
9. The user-facing close-out must always include the current live status snapshot from `ROADMAP_STATUS.md`.
   - If live status changed, explicitly state how the completed task affected that snapshot.
   - If live status did not change, explicitly state that the snapshot is unchanged for this task.
   - For every `Rj`, show at least `Status` + brief `Description`.
   - When useful, also show brief sub-bullets for the active lane, the changed lane, or any phase whose next step matters for understanding current progress.

## Safety and consistency rules
- Keep commits task-scoped (only files relevant to the completed task).
- Do not stage unrelated untracked directories (for example local sandboxes).
- Keep behavior-preserving refactor slices small and verifiable.
- Ensure the co-author trailer is present in every commit message created by AI.
