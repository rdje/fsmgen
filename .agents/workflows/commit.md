---
description: Commits code using the user-defined commit workflow, generating detailed changelogs and development notes
---
# The Commit Workflow

This workflow enforces rigorous documentation before performing a Git commit.

1. Refresh `MEMORY.md` first with the completed task state and immediate next direction.
2. Refresh `ROADMAP_STATUS.md` before the commit if the task changed roadmap status, remaining work, or the current active lane.
3. Append detailed technical change history to `CHANGES.md`, and explicitly log any live-status change there when one occurred.
4. Append design constraints, context, decisions, and architectural choices to `DEVELOPMENT_NOTES.md`.
// turbo
5. Write a short, concise commit summary in the untracked file `git_message_brief.txt` using `write_to_file` (with Overwrite=true) or `replace_file_content`.
6. Stage the intended tracked files, including the updated documentation files.
7. Perform the commit referencing the message file: `git commit -F git_message_brief.txt` (This will block and ask the user for approval before running)
// turbo
8. Clear the brief message file in preparation for the next cycle: `> git_message_brief.txt`
9. If live status changed, include the current live status snapshot from `ROADMAP_STATUS.md` in the user-facing close-out.
