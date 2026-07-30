# SESSION_BOOTSTRAP

This file defines the default first task for a new engineering session in this
repository.

Use it when you want one short instruction such as:

> Read `SESSION_BOOTSTRAP.md` and start from there.

## Purpose
Keep every new session grounded in the current documented architecture before
new implementation work starts.
Also force the session to adopt the repository's crash-recovery discipline
before momentum builds.

This is not a generic onboarding note.
It is the explicit session-start ritual for ongoing FSMGen architecture work.

## Default start-of-session task
Before doing anything else, perform this task first:

> Read `README.md`, the mandatory continuity/doctrine documents, the roadmap,
> and the mdBook, then thoroughly, meticulously and precisely analyze
> `bin/fsmgen` and its import tree.
> Treat `COMMIT.md` as a hard safety invariant, not a suggestion.
> Do not start code, test, generated-artifact, source, or config changes unless
> the selected work already has task-tree ownership.
>
> When done then update `docs/BIN_FSMGEN_IMPORT_TREE.md` if deemed necessary,
> then help fulfil all the objectives as captured in `ROADMAP_V2.md`.

## Expected behavior
For a normal new session, the agent should:

1. Read [README.md](README.md).
2. Read [COMMIT.md](COMMIT.md) early and adopt it as a non-negotiable session rule.
3. Read [MEMORY_ARCHITECTURE.md](MEMORY_ARCHITECTURE.md),
   [DOCTRINE_ENFORCEMENT.md](DOCTRINE_ENFORCEMENT.md),
   [TOOLBOX.md](TOOLBOX.md), and resume from [MEMORY.md](MEMORY.md).
4. Read [docs/TASK_TREE.md](docs/TASK_TREE.md) and the active task files it
   lists.
5. Read [ROADMAP_V2.md](ROADMAP_V2.md), the mdBook table of contents at
   [docs/book/src/SUMMARY.md](docs/book/src/SUMMARY.md), and the book chapters
   relevant to the active work. Pull other focused references from the README
   only when the current question needs them.
6. Consult [KNOWLEDGE_MAP.md](KNOWLEDGE_MAP.md) before re-deriving an existing
   durable fact.
7. Rebuild a current understanding of:
   - the live roadmap state,
   - the active task-tree frontier, if one exists,
   - the current architecture,
   - the current active lane,
   - and the continuity/history notes that matter for the ongoing work.
8. Before any future code, test, generated-artifact, source, or config change,
   verify the owning task-tree leaf or create one first.
9. Analyze [bin/fsmgen](bin/fsmgen) and the project-owned transitive `FSM::...` import tree from source.
10. Compare that live source picture against [docs/BIN_FSMGEN_IMPORT_TREE.md](docs/BIN_FSMGEN_IMPORT_TREE.md).
11. Update [docs/BIN_FSMGEN_IMPORT_TREE.md](docs/BIN_FSMGEN_IMPORT_TREE.md) if the saved picture is stale, incomplete, or no longer honest.
12. Then continue the high-level objectives in [ROADMAP_V2.md](ROADMAP_V2.md)
    through the exact live frontier in [docs/TASK_TREE.md](docs/TASK_TREE.md).
13. After every completed task, slice, lane, or task-scoped activity from that point on, run the full workflow in [COMMIT.md](COMMIT.md) before starting or switching to another one.
14. When that workflow reaches git write steps, run them sequentially and treat a stale `.git/index.lock` as a recovery event governed by [COMMIT.md](COMMIT.md).

## Expected close-out from that startup task
After completing the bootstrap task, the agent should report:

- whether the documentation pass was completed,
- the current understanding of the project and architecture,
- the current `bin/fsmgen` runtime spine and hotspot assessment,
- whether [docs/BIN_FSMGEN_IMPORT_TREE.md](docs/BIN_FSMGEN_IMPORT_TREE.md) was updated,
- and the next honest roadmap seam to work on.

## Scope note
This file is meant for normal FSMGen engineering sessions.

If a future session is for a very narrow one-off question unrelated to the
active roadmap, you can still override this ritual explicitly.
But the default expectation is to start here.
