# Agent bootstrap — read this first, whatever AI or harness you are

This is the tool-neutral entrypoint (the common `AGENTS.md` convention). Other
harnesses' bootstrap files (`CLAUDE.md`, `.cursorrules`,
`.github/copilot-instructions.md`, `GEMINI.md`, `.windsurfrules`) point back here.
The system of record is **`README.md`** + **`MEMORY_ARCHITECTURE.md`**.

## On every session start / resume

1. Read **`README.md`** — project objective, layout, standard commands.
2. Read **`MEMORY_ARCHITECTURE.md`** — how memory + continuity work here (MANDATORY;
   it is enforced — see below).
3. Resume from **`MEMORY.md`** — the bounded resume pointer: latest commit, the active
   task-tree frontier, the single next action, any in-flight uncommitted work.
4. Open the active **task-tree** under `docs/tasks/` (index: `docs/TASK_TREE.md`); its
   frontier row is your precise next step.
5. Pull only the relevant **decision records** under `docs/decisions/`
   (index: `docs/decisions/INDEX.md`).

## Non-negotiable working rules

- **No code/test/source/artifact/config change without an owning task-tree leaf first**
  (`docs/TASK_TREE.md` + a `docs/tasks/*.md` tree, from `docs/tasks/TEMPLATE.md`).
- **Route every durable thing to a layer and commit before the turn ends** — task-trees
  (`docs/tasks/`, layer B) / decision records (`docs/decisions/`, layer C) / the bounded
  `MEMORY.md` pointer (layer A, overwrite-only, capped) / git history (layer D). Nothing
  important may live only in this conversation. The legacy prose blobs
  (`CHANGES.md`, `DEVELOPMENT_NOTES.md`, `ROADMAP_STATUS.md`, `LIVE_ACHIEVEMENT_STATUS.md`)
  are FROZEN — do not append to them (`docs/decisions/0007`).
- **Commit per `COMMIT.md`** after every slice, with the **work-unit id in the subject**
  (e.g. `ISF-SWAP: …`, `MEMORY-ARCHITECTURE-ADOPTION.4: …`).
- **The mdBook (`docs/book/`) is user-facing** — keep it synced in the same slice with
  runnable, lowering-clean examples (`docs/decisions/0006`).
- **Before committing, run `scripts/check_memory_architecture.sh`** — git hooks and CI
  run it too, and a non-compliant change fails the build and cannot merge. Activate the
  hooks once per clone: `git config core.hooksPath .githooks`.

Nothing important may live only in this conversation — route it to a layer and commit.
