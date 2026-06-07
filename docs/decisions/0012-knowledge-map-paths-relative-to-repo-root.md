# 0012 — Knowledge Map path references are relative to the repo root

- Date: 2026-06-07
- Type: convention
- Status: accepted
- Extends: `docs/decisions/0011-doc-file-paths-relative-to-repo-root.md`

## Context

Decision `0011` already requires file-path references in live docs and mdBook source to
be relative to the repository root. The user clarified the same invariant for every
documentation-facing continuity surface, explicitly including task trees and the root
`KNOWLEDGE_MAP.md` generated from fact cards and decision records.

`KNOWLEDGE_MAP.md` is read during session resume and fact retrieval, so an absolute
machine-local path in that generated index would leak local checkout structure and would
mislead agents using another clone.

## Decision

Extend the repo-root-relative path convention to `KNOWLEDGE_MAP.md` and its source fact
cards. File references in live docs, mdBook source, task trees, knowledge cards, and the
generated Knowledge Map must be relative to the git repository root.

The existing guard `t/1414-docs-relative-paths-audit.t` now scans both `docs/**/*.md`
and root `KNOWLEDGE_MAP.md` for machine-local home-directory prefixes.

## Consequences

- Future fact cards must use paths such as `docs/tasks/NAME.md` or
  `perl/FSM/Module.pm`, not a machine-local home-directory checkout path.
- Regenerating `KNOWLEDGE_MAP.md` remains safe because the guard checks the generated
  map after the fact-card/decision sources are rendered into it.
- Runtime path canonicalization remains allowed when it is internal and not emitted or
  documented, per `0011`.
