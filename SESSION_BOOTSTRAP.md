# SESSION_BOOTSTRAP

This file defines the default first task for a new engineering session in this
repository.

Use it when you want one short instruction such as:

> Read `SESSION_BOOTSTRAP.md` and start from there.

## Purpose
Keep every new session grounded in the current documented architecture before
new implementation work starts.

This is not a generic onboarding note.
It is the explicit session-start ritual for ongoing FSMGen architecture work.

## Default start-of-session task
Before doing anything else, perform this task first:

> Read `README.md` and all the referenced `.md` files, then thoroughly,
> meticulously and precisely analyze `bin/fsmgen` and its import tree.
>
> When done then update `docs/BIN_FSMGEN_IMPORT_TREE.md` if deemed necessary,
> then help fulfil all the objectives as captured in `ROADMAP_V2.md`.

## Expected behavior
For a normal new session, the agent should:

1. Read [README.md](/Users/richarddje/Documents/github/fsmgen/README.md).
2. Read the Markdown files referenced from [README.md](/Users/richarddje/Documents/github/fsmgen/README.md).
3. Rebuild a current understanding of:
   - the live roadmap state,
   - the current architecture,
   - the current active lane,
   - and the continuity/history notes that matter for the ongoing work.
4. Analyze [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) and the project-owned transitive `FSM::...` import tree from source.
5. Compare that live source picture against [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md).
6. Update [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) if the saved picture is stale, incomplete, or no longer honest.
7. Then continue by helping fulfil the objectives captured in [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) and tracked live in [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md).

## Expected close-out from that startup task
After completing the bootstrap task, the agent should report:

- whether the documentation pass was completed,
- the current understanding of the project and architecture,
- the current `bin/fsmgen` runtime spine and hotspot assessment,
- whether [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) was updated,
- and the next honest roadmap seam to work on.

## Scope note
This file is meant for normal FSMGen engineering sessions.

If a future session is for a very narrow one-off question unrelated to the
active roadmap, you can still override this ritual explicitly.
But the default expectation is to start here.
