# Agent bootstrap — read this first, whatever AI or harness you are

This is the tool-neutral entrypoint (the common `AGENTS.md` convention). Other
harnesses' bootstrap files (`CLAUDE.md`, `.cursorrules`,
`.github/copilot-instructions.md`, `GEMINI.md`, `.windsurfrules`) point back here.
The system of record is **`README.md`** + **`MEMORY_ARCHITECTURE.md`** +
**`LIVE_DOCUMENT_SIZE_CONTAINMENT.md`** + **`DOCTRINE_ENFORCEMENT.md`** +
**`TOOLBOX.md`**.

## On every session start / resume

1. Read **`README.md`** — project objective, layout, standard commands.
2. Read **`MEMORY_ARCHITECTURE.md`** — how memory + continuity work here (MANDATORY;
   it is enforced — see below).
3. Read **`LIVE_DOCUMENT_SIZE_CONTAINMENT.md`**,
   **`DOCTRINE_ENFORCEMENT.md`**, and **`TOOLBOX.md`** — how live documentation
   stays bounded, how repository doctrines are mechanically checked, and which
   FSMGEN tools to use first for issue diagnosis.
4. Resume from **`MEMORY.md`** — the bounded resume pointer: latest commit, the active
   task-tree frontier, the single next action, any in-flight uncommitted work.
5. Open the active **task-tree** under `docs/tasks/` (index: `docs/TASK_TREE.md`); its
   frontier row is your precise next step.
6. Pull only the relevant **decision records** under `docs/decisions/`
   (index: `docs/decisions/INDEX.md`).
7. Before re-deriving any durable fact from code or runtime, consult
   **`KNOWLEDGE_MAP.md`** — a derived *question → fact* index (generated from the
   front-mattered fact cards under `docs/knowledge/`; see `knowledge-map/`). Find
   your question, follow the one pointer to the canonical home, and trust the dated
   fact or run its `reverify` command. Only if the fact is genuinely not there is
   new investigation warranted — then write a fact card so it never recurs.

## Non-negotiable working rules

- **No code/test/source/artifact/config change without an owning task-tree leaf first**
  (`docs/TASK_TREE.md` + a `docs/tasks/*.md` tree, from `docs/tasks/TEMPLATE.md`).
- **Every staged implementation slice must pass `TASK_ACCEPTANCE.md`** — add
  fresh checked ROOT CAUSE, ADDRESSED, and NO REGRESSION boxes to one owning
  task file, with box-scoped declared evidence, then run the staged-index gate.
- **Route every durable thing to a layer and commit before the turn ends** — task-trees
  (`docs/tasks/`, layer B) / decision records (`docs/decisions/`, layer C) / the bounded
  `MEMORY.md` pointer (layer A, overwrite-only, capped) / git history (layer D). Nothing
  important may live only in this conversation. Add one concise `CHANGES.md`
  entry for every completed slice; update `DEVELOPMENT_NOTES.md` only when a
  slice produces durable engineering rationale, constraints, or working
  decisions. `ROADMAP_STATUS.md` and `LIVE_ACHIEVEMENT_STATUS.md` remain frozen
  until decision `0046` is implemented; decision `0025` remains the transition
  workflow.
- **Commit per `COMMIT.md`** after every slice, with the **work-unit id in the subject**
  (e.g. `ISF-SWAP: …`, `MEMORY-ARCHITECTURE-ADOPTION.4: …`).
- **The mdBook (`docs/book/`) is user-facing** — keep it synced in the same slice with
  runnable, lowering-clean examples (`docs/decisions/0006`).
- **Before committing, run `scripts/check_doctrines.sh`** — git hooks and CI
  run it too, including the memory-architecture and Knowledge Map gates, and a
  non-compliant change fails the build and cannot merge. Activate the hooks
  once per clone: `git config core.hooksPath .githooks`.

Nothing important may live only in this conversation — route it to a layer and commit.
