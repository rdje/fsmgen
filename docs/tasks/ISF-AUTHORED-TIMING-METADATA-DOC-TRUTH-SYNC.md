# ISF-AUTHORED-TIMING-METADATA-DOC-TRUTH-SYNC: Authored Timing Metadata Doc Truth Sync

## Metadata

- Tree ID: `ISF-AUTHORED-TIMING-METADATA-DOC-TRUTH-SYNC`
- Status: `done`
- Roadmap lane: `R14 documentation truth sync`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Synchronize stale backlog/non-claim wording after
`authored_timing_mode` shipped as public transaction-port binding report
metadata.

## Non-Goals

- Do not change parser behavior, scheduler lowering, generated `.fsm`, HDL,
  schedule-report payloads, public API, or runtime behavior.
- Do not select or implement another transaction-port binding report field.
- Do not change the authored timing mode implementation.

## Acceptance Criteria

- The ISF spec no longer says shipped report metadata stops at endpoint-kind
  and binding-timing fields.
- The mdBook feature matrix non-claims include authored timing-mode metadata
  in the shipped binding-report field boundary.
- Live docs record the documentation-only truth sync and validation evidence.
- Focused doc/book validation passes.
- The completed slice is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-AUTHORED-TIMING-METADATA-DOC-TRUTH-SYNC`
  Status: `done`
  Goal: `Synchronize stale authored timing metadata backlog wording.`
  Children: `ISF-AUTHORED-TIMING-METADATA-DOC-TRUTH-SYNC.1`

- ID: `ISF-AUTHORED-TIMING-METADATA-DOC-TRUTH-SYNC.1`
  Status: `done`
  Goal: `Update stale spec and book non-claim wording after authored_timing_mode shipped.`
  Acceptance: `The stale endpoint-kind/binding-timing-only report metadata boundary is replaced with endpoint-kind, binding-timing, and authored timing-mode metadata in the ISF spec and feature matrix.`
  Verification: `feature-backlog/live-book/book matrix audits; mdBook build; git diff --check`
  Commit: `ISF-AUTHORED-TIMING-METADATA-DOC-TRUTH-SYNC.1: sync authored timing metadata docs`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| `_None_` | `_None_` | `_None_` | Tree closed. |

## Decisions

- `2026-05-25`: Keep this as a documentation truth-sync slice because the
  implementation and public contract already shipped in
  `ISF-TRANSACTION-PORT-BINDING-TIMING-REQUEST-METADATA.2`.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-AUTHORED-TIMING-METADATA-DOC-TRUTH-SYNC.1` | `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-AUTHORED-TIMING-METADATA-DOC-TRUTH-SYNC.1` | `ISF-AUTHORED-TIMING-METADATA-DOC-TRUTH-SYNC.1: sync authored timing metadata docs` | `documentation truth-sync commit` |

## Changelog

- `2026-05-25`: Created and completed documentation truth-sync tree for stale
  authored timing metadata non-claim wording.
