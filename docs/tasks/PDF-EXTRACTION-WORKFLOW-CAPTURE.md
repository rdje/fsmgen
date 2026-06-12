# PDF-EXTRACTION-WORKFLOW-CAPTURE: PDF Extraction Workflow Capture

## Metadata

- Tree ID: `PDF-EXTRACTION-WORKFLOW-CAPTURE`
- Status: `done`
- Roadmap lane: `documentation / workflow portability`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Document the repo-local PDF extraction workflow used for AXI evidence work so
other projects can replicate the text, table, diagram, image, validation, and
fallback approach.

## Non-Goals

- Do not install tools in this slice unless validation proves an existing
  installed tool is insufficient.
- Do not create a generic PDF parser or generated artifact.
- Do not embed copyrighted extracted PDF text or images in tracked docs.
- Do not change code, tests, parser behavior, lowering, HDL, or generated
  artifacts.

## Acceptance Criteria

- The task tree owns the workflow capture before the document is written.
- A git-tracked workflow document records the exact approach: source
  anchoring, PDF metadata/hash checks, text extraction, targeted search,
  page-window extraction, table handling, diagram/image rendering, visual QA,
  troubleshooting/fallbacks, copyright hygiene, cleanup, validation, and the
  rule that future flow enhancements must update the document.
- The mdBook backlog, README, task tree, Knowledge Map, and memory remain
  synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `PDF-EXTRACTION-WORKFLOW-CAPTURE`
  Status: `done`
  Goal: `Capture a portable PDF extraction workflow for source-anchored evidence work.`
  Children: `PDF-EXTRACTION-WORKFLOW-CAPTURE.1`

- ID: `PDF-EXTRACTION-WORKFLOW-CAPTURE.1`
  Status: `done`
  Goal: `Write and track the PDF extraction workflow document.`
  Acceptance: `Create a durable workflow note describing the exact text/table/diagram/image extraction sequence, fallback strategy, cleanup, and future-update policy, with docs/index/Knowledge Map/memory sync and no code changes.`
  Verification: `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `PDF-EXTRACTION-WORKFLOW-CAPTURE.1` | `done` | The workflow is recorded in `docs/PDF_EXTRACTION_WORKFLOW.md`; future flow enhancements must update that document in the same task-owned slice. |

## Decisions

- `2026-06-12`: Capture the workflow as a durable repository document and
  keep it updated whenever the PDF extraction flow improves.
- `2026-06-12`: The workflow document is the durable home for PDF extraction
  tooling, fallback, cleanup, validation, and future-update policy.

## Open Questions

- None for first workflow capture.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `.1` | `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `PDF-EXTRACTION-WORKFLOW-CAPTURE.1: document PDF extraction workflow` | Captures the portable source-anchored PDF extraction workflow and maintenance rule. |

## Changelog

- `2026-06-12`: Created active task tree for PDF extraction workflow capture.
- `2026-06-12`: Wrote `docs/PDF_EXTRACTION_WORKFLOW.md`, added a Knowledge
  Map signpost, and synchronized README, mdBook, task tree, and memory.
