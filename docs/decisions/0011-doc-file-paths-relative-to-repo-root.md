# 0011 — File-path references in docs are relative to the repo root, never absolute

- Date: 2026-06-02
- Type: convention
- Status: accepted

## Context

Absolute file paths in documentation (e.g. a `<local-checkout>/perl/FSM/Debug.pm`
form with a machine-specific home-directory prefix) capture the author's local machine
layout. They are wrong for any other checkout/reader and leak local structure (user,
2026-06-02: "Every file path reference shall be relative to the git repo root directory
and not absolute").

## Decision

1. **Every file-path reference in the live docs (`docs/`, `docs/book/`) is relative to
   the git repo root** — e.g. `perl/FSM/Debug.pm`, `docs/decisions/0011-...md`. Never
   an absolute path, never a machine-local home-directory prefix.
2. **Cross-repo references** (a sibling repo outside this tree) use a repo-root-relative
   sibling path (e.g. `../specforge/MEMORY_ARCHITECTURE.md`) or a name-only reference —
   not an absolute path.
3. Runtime path *comparison* internals may canonicalize to absolute (e.g.
   `FSM::Support::CheckDiagnostics::_canonical_path` matches a source against the
   regression corpus) — that is fine because it is never displayed. Only *emitted /
   documented* paths must be repo-root-relative.

## Consequences

- Current state (2026-06-02 sweep): docs sources, generated book HTML, and the
  capability manifest were already path-relative; the only absolute local path was a
  cross-repo `specforge` reference in `docs/tasks/MEMORY-ARCHITECTURE-ADOPTION.md`,
  fixed to `../specforge/…`.
- A guard test scans `docs/**/*.md` for machine-local home-directory prefixes or the
  absolute repo prefix and fails if any appear, to keep the invariant from regressing.
