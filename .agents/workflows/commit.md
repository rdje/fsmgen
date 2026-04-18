---
description: Commits code using the user-defined commit workflow, generating detailed changelogs and development notes
---
# The Commit Workflow

This workflow is mandatory.
It exists to preserve task-scoped recovery after session loss, crashes, or handoff.
If a slice is complete but not committed, the slice is not finished yet.
Do not wait for the user to remind you.

1. Refresh `MEMORY.md` first with the completed task state and immediate next direction.
2. Refresh `ROADMAP_STATUS.md` before the commit if the task changed roadmap status, deliverables, remaining work, or the current active lane.
   Keep explicit `Description`, `Deliverables`, `Status`, `Done`, `Left`, and `Exit criteria` for every workstream.
3. Append detailed technical change history to `CHANGES.md`, and explicitly log any live-status change there when one occurred.
4. Append design constraints, context, decisions, and architectural choices to `DEVELOPMENT_NOTES.md`.
// turbo
5. Write a short, concise commit summary in the untracked file `git_message_brief.txt` using `write_to_file` (with Overwrite=true) or `replace_file_content`.
6. Stage the intended tracked files, including the updated documentation files.
7. Perform the commit referencing the message file: `git commit -F git_message_brief.txt` (This will block and ask the user for approval before running)
// turbo
8. Clear the brief message file in preparation for the next cycle: `> git_message_brief.txt`
9. Include the current live status snapshot from `ROADMAP_STATUS.md` in the user-facing close-out every time the commit workflow runs.
10. If live status changed, explicitly say how the completed task changed the snapshot; if it did not change, explicitly say the snapshot is unchanged for this task.
11. In that snapshot, show every `Rj` with at least `Status` + brief `Description`.
12. When helpful, include brief sub-bullets for the active lane, changed lane, or phases whose next step matters right now.
13. Run this workflow after every completed task/activity, before starting the next slice.
14. Never batch several finished tasks into one later cleanup commit.
15. If multiple completed slices are already mixed together, stop new work and recover them into the smallest honest task-scoped commits before continuing.
