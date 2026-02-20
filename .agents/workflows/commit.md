---
description: Commits code using the user-defined commit workflow, generating detailed changelogs and development notes
---
# The Commit Workflow

This workflow enforces rigorous documentation before performing a Git commit.

1. Write a short, concise commit summary in the untracked file `git_message_brief.txt` using `write_to_file` (with Overwrite=true) or `replace_file_content`.
2. Append detailed, gory descriptions of the changes made to the codebase in the tracked file `CHANGES.md`.
3. Append design constraints, context, decisions, and architectural choices made alongside the changes in the tracked file `DEVELOPMENT_NOTES.md`.
// turbo
4. Stage the files including the two documentation files: `git add CHANGES.md DEVELOPMENT_NOTES.md` (plus whatever other files are modified).
5. Perform the commit referencing the message file: `git commit -F git_message_brief.txt` (This will block and ask the user for approval before running)
// turbo
6. Clear the brief message file in preparation for the next cycle: `> git_message_brief.txt`
