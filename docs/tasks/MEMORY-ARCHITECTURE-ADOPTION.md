# MEMORY-ARCHITECTURE-ADOPTION: adopt the durable-agent-memory standard in fsmgen

## Metadata

- Tree ID: `MEMORY-ARCHITECTURE-ADOPTION`
- Status: `done`
- Roadmap lane: infrastructure / continuity (cross-cutting)
- Created: `2026-06-02`
- Last updated: `2026-06-02`
- Owner: repo-local workflow

## Goal

Adopt the portable **Durable Agent Memory Architecture** standard
(`../specforge/MEMORY_ARCHITECTURE.md`, the sibling repo) in this
repo, end-to-end, per its §11 adoption checklist and §9.1 enforcement kit — so
fsmgen's agent memory survives session loss, crash, machine loss, and harness/model
switches, and is **mechanically enforced** (hard to be non-compliant).

## Why now

The user asked for it explicitly ("read, digest and implement everything
recommended in MEMORY_ARCHITECTURE.md before switching to +assert"). fsmgen today
violates the standard in two of its named anti-patterns (§12):
- the repo-root `MEMORY.md` is a **38,776-line / 2.7 MB append-only blob** (mixing
  current-state, durable facts, and history) — it must become the bounded layer-A
  resume pointer;
- durable facts/preferences live in **harness home-dir memory**
  (`~/.claude/.../memory/`) — invisible to any other tool; they must move in-repo to
  `docs/decisions/` (layer C).

fsmgen already has layer B (`docs/tasks/` + `docs/TASK_TREE.md`), `README.md`,
`COMMIT.md`, and CI (`.github/workflows/regression.yml` → `bin/ci-regression`), so
this is an additive adoption, not a rebuild.

## Ground truth (the standard's four layers)

- **A** resume pointer = the demoted `MEMORY.md` (≤ ~60 lines, overwrite-only).
- **B** work memory = `docs/tasks/` task-trees (already present).
- **C** decision records = `docs/decisions/` (ADR-style; new).
- **D** audit trail = `git log` (already present).
Plus **E1–E4** enforcement: ubiquitous bootstrap pointers · one self-check script ·
git hooks · CI gate.

## Slice plan (mirrors the specforge reference adoption)

- `.1` add `MEMORY_ARCHITECTURE.md` at the repo root (the standard) + a `README.md`
  doc-map pointer to it / the task-trees / `COMMIT.md`.
- `.2` create `docs/decisions/` (layer C) with `INDEX.md`; migrate the durable
  cross-cutting facts out of harness-home `~/.claude/.../memory/` into dated ADR
  records (abstraction-layering, language-richness frontier, PNT autonomy, doc
  standard, push policy, the "simulate control flow" lesson).
- `.3` demote `MEMORY.md` from the 38,776-line blob to the §6 resume-pointer
  template (≤ ~60 lines); the full history stays recoverable in git.
- `.4` enforcement kit (§9): `scripts/check_memory_architecture.sh` (E2),
  `.githooks/pre-commit` + `.githooks/commit-msg` (E3) + `git config core.hooksPath
  .githooks`, tool-neutral bootstrap pointers `AGENTS.md` / `CLAUDE.md` /
  `.cursorrules` / `.github/copilot-instructions.md` / `GEMINI.md` / `.windsurfrules`
  (E1), and wire the self-check into CI (E4, `regression.yml`). Adapt the two knobs
  (line cap; commit-subject regex to fsmgen's `UNIT-ID[.leaf]:` scheme incl. the
  `.2/.3` multi-leaf form).
- `.5` verify end-to-end: the self-check passes; the hooks *bite* (a non-compliant
  subject / an over-cap `MEMORY.md` are rejected, a compliant one accepted); the CI
  step runs the check; sync live docs (`docs/TASK_TREE.md`); close the tree.

## Non-Goals

- Deleting the old `MEMORY.md` content (it stays in git history — recoverable).
- Rewriting the task-tree (layer B) system — it already exists and is the model.
- Migrating the harness-home memory *files* themselves out of `~/.claude` (the
  system of record becomes `docs/decisions/`; the harness copies may remain as
  convenience but are no longer authoritative).

## Acceptance Criteria

- `scripts/check_memory_architecture.sh` exits 0; `MEMORY.md` ≤ cap and is a pure
  resume pointer; `docs/decisions/INDEX.md` present and in sync; every harness
  bootstrap file points at `MEMORY_ARCHITECTURE.md` + `README.md`; hooks active via
  `core.hooksPath`; CI runs the check. The hooks demonstrably reject a
  non-compliant commit and accept a compliant one. Full regression still green.
  Each leaf committed via `COMMIT.md` with its unit id in the subject.

## Blockers

- None.

## Changelog

- `2026-06-02`: Created at the user's request. Surveyed fsmgen: repo-root
  `MEMORY.md` is a 2.7 MB blob; no bootstrap pointers / `docs/decisions/` /
  `scripts/` / `.githooks/`; `README.md`, `COMMIT.md`, `docs/tasks/`,
  `docs/TASK_TREE.md`, and CI (`regression.yml`) already present. Reference kit
  copied/adapted from specforge (`scripts/check_memory_architecture.sh`,
  `.githooks/`, bootstrap-pointer shape).
- `2026-06-02`: `.1` done — `MEMORY_ARCHITECTURE.md` at root + README "Memory &
  continuity" doc-map section; tree registered in `docs/TASK_TREE.md`. Commit
  `de7a6e17`.
- `2026-06-02`: `.2` done — `docs/decisions/` (layer C) + `INDEX.md` + 7 ADRs
  migrating durable facts out of harness-home memory: 0001 abstraction layering,
  0002 language-richness frontier, 0003 autonomous-PNT/no-pausing, 0004 simulate-
  to-catch-codegen-bugs, 0005 push-only-on-request, 0006 thorough-mdBook, 0007
  memory-architecture-supersedes-blob-narration (the COMMIT.md reconciliation,
  executed in `.3`/`.4`).
- `2026-06-02`: `.3` done — demoted `MEMORY.md` from 38,776 lines → 24-line bounded
  resume pointer (§6 template; old content recoverable via `git log -- MEMORY.md`).
  Reconciled `COMMIT.md` per ADR 0007: `MEMORY.md` = overwrite-only layer-A pointer
  (capped); `ROADMAP_STATUS.md`/`CHANGES.md`/`DEVELOPMENT_NOTES.md`/
  `LIVE_ACHIEVEMENT_STATUS.md` marked FROZEN; the required-order doc step now routes
  to layers B → C → A (git is the audit trail); close-out snapshot reads the
  task-trees, not the frozen `ROADMAP_STATUS.md`.
- `2026-06-02`: `.5` done — **verified the gates bite and closed**. `commit-msg` rejects a
  non-compliant subject (exit 1) and accepts a work-unit-id incl. the `.2/.3` multi-leaf
  form (exit 0); the self-check rejects an over-cap `MEMORY.md` (exit 1, clear message)
  and passes when restored; the `pre-commit` hook runs the check; the `.4` install commit
  passed through its own newly-active hooks. Full `prove -j6 t/` regression green
  (adoption is docs/infra-only — no `perl/`/`t/` changes). **Tree complete** — fsmgen now
  carries the durable-agent-memory standard with E1–E4 enforcement.
- `2026-06-02`: `.4` done — enforcement kit (§9). `scripts/check_memory_architecture.sh`
  (E2, copied from the specforge reference — knobs already match fsmgen);
  `.githooks/pre-commit` (runs the check) + `.githooks/commit-msg` (E3; regex adapted to
  fsmgen's `UNIT-ID[.leaf]:` scheme incl. the `.2/.3` multi-leaf form), activated via
  `git config core.hooksPath .githooks`; tool-neutral bootstrap pointers `AGENTS.md`
  (canonical) + `CLAUDE.md`/`GEMINI.md`/`.cursorrules`/`.windsurfrules`/
  `.github/copilot-instructions.md` (E1, each routes to the standard); CI gate (E4) wired
  as the first step of `regression.yml` (runs the check + asserts every branch commit
  subject carries a work-unit id). The check passes; this `.4` commit passes through its
  own newly-active hooks.
