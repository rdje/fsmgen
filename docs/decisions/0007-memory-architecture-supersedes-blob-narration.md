# 0007 — Memory architecture supersedes prose-blob narration

- Date: 2026-06-02
- Type: architecture
- Status: accepted (executed in MEMORY-ARCHITECTURE-ADOPTION.3/.4)

## Context

`COMMIT.md` mandated appending to several prose files on **every** commit:
`MEMORY.md`, `ROADMAP_STATUS.md`, `CHANGES.md`, `DEVELOPMENT_NOTES.md` (and
`LIVE_ACHIEVEMENT_STATUS.md`). That mandate is the engine that grew them into
multi-MB append-only blobs (`MEMORY.md` 2.7 MB / 38,776 lines; `CHANGES.md` 30k
lines; `DEVELOPMENT_NOTES.md` 34k lines; `ROADMAP_STATUS.md` 15k lines) — exactly
the anti-pattern `MEMORY_ARCHITECTURE.md` §1/§12 exists to eliminate
("an ever-growing MEMORY.md"; "re-narrating git history into prose docs"). The
mandate also directly contradicts the §6 size cap and the §9 self-check.

## Decision

The adopted `MEMORY_ARCHITECTURE.md` standard **supersedes** the blob-narration
parts of `COMMIT.md`:

- **`MEMORY.md` = layer A only**: the bounded, overwrite-only resume pointer
  (≤ ~60 lines, mechanically capped). `COMMIT.md`'s "update `MEMORY.md` first" now
  means *overwrite its current-state block*, never append.
- **Audit trail = git (layer D)** + the task-tree logs (layer B). Durable
  cross-cutting facts = `docs/decisions/` (layer C).
- **The legacy prose blobs** (`CHANGES.md`, `DEVELOPMENT_NOTES.md`,
  `ROADMAP_STATUS.md`, `LIVE_ACHIEVEMENT_STATUS.md`) are **frozen**: not appended to
  going forward. Their existing content stays in git history (recoverable;
  per §6 "existing bloat is not deleted — you stop carrying it forward"). They are
  no longer the system of record.
- `COMMIT.md` is updated to point its memory/continuity steps at this standard.

## Consequences

- `COMMIT.md`'s required-order doc updates collapse to: task-tree (B) + the
  `MEMORY.md` pointer (A) + a decision record (C) when a durable fact appears + the
  commit (D). No more mandatory appends to the four blobs.
- The enforced self-check (`scripts/check_memory_architecture.sh`) caps `MEMORY.md`;
  a regression to blob-growth fails the pre-commit hook and CI.
- Future cleanup (optional): trim the frozen blobs to short "legacy — see git
  history / docs/decisions/" stubs. Not required for compliance; left for a
  follow-up so this adoption stays non-destructive.
