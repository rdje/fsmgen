# DOC-PATH-RELATIVE-KNOWLEDGE-MAP: extend relative-path audits to the Knowledge Map

## Metadata

- Tree ID: `DOC-PATH-RELATIVE-KNOWLEDGE-MAP`
- Status: `done`
- Roadmap lane: infra / continuity
- Created: `2026-06-07`
- Last updated: `2026-06-07`
- Owner: repo-local workflow
- Decision: `docs/decisions/0012-knowledge-map-paths-relative-to-repo-root.md`

## Goal

Ensure the documented file-path invariant covers the live documentation surfaces named
by the user: live docs, mdBook source, task trees, and `KNOWLEDGE_MAP.md`. All file
references in those surfaces must be repo-root-relative, never machine-local absolute
paths.

## Non-Goals

- Changing runtime internals that temporarily canonicalize paths for comparison without
  emitting or documenting them.
- Flagging ordinary URLs or non-local system paths such as `/tmp`, `/usr`, or `/bin`.
- Editing generated mdBook HTML output under `docs/book/book/`.

## Acceptance Criteria

- The task-tree owner records the scope, verification, and completion evidence.
- A decision record captures the Knowledge Map scope clarification without relying on
  conversation-only memory.
- A Knowledge Map fact card makes the invariant discoverable before future archaeology.
- The path-audit guard covers `docs/**/*.md` and root `KNOWLEDGE_MAP.md`.
- Focused validation proves no machine-local absolute file paths remain in the guarded
  surfaces.
- The slice is committed through `COMMIT.md`.

## Task Tree

- ID: `DOC-PATH-RELATIVE-KNOWLEDGE-MAP`
  Status: `done`
  Goal: `Extend and verify the repo-root-relative file-path invariant for docs plus the Knowledge Map.`
  Children: `DOC-PATH-RELATIVE-KNOWLEDGE-MAP.1`

- ID: `DOC-PATH-RELATIVE-KNOWLEDGE-MAP.1`
  Status: `done`
  Goal: `Extend the relative-path guard to KNOWLEDGE_MAP.md, record the durable scope decision, audit/remediate violations, and commit the completed slice.`
  Acceptance: `Decision/index/task-tree/memory updates are in sync; the guard scans docs plus KNOWLEDGE_MAP.md; focused path validation passes; no behavior-bearing project surface changes.`
  Verification: `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check`
  Commit: `DOC-PATH-RELATIVE-KNOWLEDGE-MAP.1: extend path audit to Knowledge Map`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `DOC-PATH-RELATIVE-KNOWLEDGE-MAP.1` | `done` | Guard extension, durable records, and focused validation complete. |

## Decisions

- `2026-06-07`: `DOC-PATH-RELATIVE-KNOWLEDGE-MAP.1` is a documentation-path invariant slice; any behavior-bearing implementation remains out of scope.
- `2026-06-07`: Decision `0012` extends the repo-root-relative path invariant to `KNOWLEDGE_MAP.md` and fact-card sources.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-07` | `DOC-PATH-RELATIVE-KNOWLEDGE-MAP.1` | `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `DOC-PATH-RELATIVE-KNOWLEDGE-MAP.1` | `DOC-PATH-RELATIVE-KNOWLEDGE-MAP.1: extend path audit to Knowledge Map` | Guard scans `docs/**/*.md` plus root `KNOWLEDGE_MAP.md`; decision `0012`; fact card `docs/knowledge/doc-paths-relative-to-repo-root.md`. |

## Changelog

- `2026-06-07`: Created task tree for the docs/Knowledge Map relative-path invariant audit.
- `2026-06-07`: `.1` done — extended `t/1414-docs-relative-paths-audit.t`, added decision `0012`, added the Knowledge Map fact card, regenerated `KNOWLEDGE_MAP.md`, and verified no absolute machine-local paths in the guarded surfaces.
