# DOCS-RELATIVE-PATHS: doc file-path references are repo-root-relative, never absolute

## Metadata

- Tree ID: `DOCS-RELATIVE-PATHS`
- Status: `done`
- Roadmap lane: docs / hygiene
- Created: `2026-06-02`
- Last updated: `2026-06-02`
- Owner: repo-local workflow
- Decision: `docs/decisions/0011-doc-file-paths-relative-to-repo-root.md`

## Goal

No file-path reference in the live docs is an absolute machine-local path; every one is
relative to the git repo root (user directive, decision `0011`).

## Slice plan / changelog

- `2026-06-02`: `.1` done.
  - Swept `docs/**/*.md` + generated book HTML + capability-manifest output: already
    path-relative; the only absolute local path was a cross-repo `specforge` reference in
    `docs/tasks/MEMORY-ARCHITECTURE-ADOPTION.md` → fixed to `../specforge/MEMORY_ARCHITECTURE.md`.
    Confirmed `FSM::Support::CheckDiagnostics::_canonical_path` canonicalizes to absolute only
    for internal corpus-path *comparison* (never displayed) — not a leak.
  - Decision `0011` records the policy.
  - Guard `t/1414-docs-relative-paths-audit.t` scans `docs/**/*.md` (excluding the
    gitignored generated `docs/book/book/`) and fails on any absolute home-directory
    prefix (a macOS or Linux user-home path) — keeps the invariant from regressing.

## Acceptance Criteria

- `t/1414` green; no absolute machine-local path in `docs/**/*.md`.

## Open follow-up

- If the user points at an absolute-path surface outside `docs/**/*.md` (e.g. a specific
  report/command output), extend the guard's scope to cover it.
