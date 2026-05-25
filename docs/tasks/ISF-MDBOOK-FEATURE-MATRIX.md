# ISF-MDBOOK-FEATURE-MATRIX: Book-Facing Shipped Feature Matrix

## Metadata

- Tree ID: `ISF-MDBOOK-FEATURE-MATRIX`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Add a single mdBook review surface that enumerates the shipped ISF feature
families, shows representative source examples, names the generated/reported
behavior authors can rely on, and points to the canonical deferred/backlog
boundary for anything not fully shipped.

## Non-Goals

- Do not widen ISF parser, scheduler, generated `.fsm`, generated HDL, or
  schedule-report behavior.
- Do not replace the detailed ISF chapters, live spec, downstream handoff, or
  public contract; the matrix is a book-facing index over those truths.
- Do not mark a backlog item as shipped unless the implementation, tests, live
  spec, downstream handoff, public contract, and book all already agree.

## Acceptance Criteria

- The mdBook contains an ISF shipped-feature matrix chapter reachable from
  `docs/book/src/SUMMARY.md`.
- The matrix covers the current shipped ISF surface at a feature-family level,
  with examples and explicit deferral pointers for not-fully-shipped areas.
- The public ISF live-document path list advertises the new chapter through the
  direct public contract and capability manifest.
- A focused audit verifies the chapter's required shipped-family markers.
- The live docs and task-tree state are synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-MDBOOK-FEATURE-MATRIX`
  Status: `done`
  Goal: `Add and audit a book-facing ISF shipped-feature matrix.`
  Children: `ISF-MDBOOK-FEATURE-MATRIX.1`

- ID: `ISF-MDBOOK-FEATURE-MATRIX.1`
  Status: `done`
  Goal: `Ship the ISF mdBook feature matrix and manifest discovery audit.`
  Acceptance: `The book matrix exists, is listed in SUMMARY, is advertised
  through live_document_paths, and focused checks prove required shipped-family
  markers remain present.`
  Verification: `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`;
  `prove -Iperl t/1305-isf-book-feature-matrix-audit.t
  t/1303-isf-public-live-book-paths-audit.t`; `mdbook build docs/book`;
  `./bin/ci-regression isf --no-book`; `git diff --check`
  Commit: `afdd2e87 ISF-MDBOOK-FEATURE-MATRIX.1: add ISF book feature matrix`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-MDBOOK-FEATURE-MATRIX.1` | `done` | A single book-facing support matrix directly answers the requirement that shipped ISF features be reviewable from the book without reading the code. |

## Decisions

- `2026-05-16`: The matrix is intentionally a chapter in the ISF book section,
  not only a live-doc/spec table, because the book is the required user-facing
  review surface for shipped behavior.
- `2026-05-16`: The matrix summarizes feature families and links to detailed
  chapters instead of duplicating every sentence from the spec. Detailed
  semantics remain in the dedicated chapters, spec, downstream handoff, and
  public contract.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-MDBOOK-FEATURE-MATRIX.1` | `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | passed; ISF gate Files=211, Tests=872 |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-MDBOOK-FEATURE-MATRIX.1` | `afdd2e87 ISF-MDBOOK-FEATURE-MATRIX.1: add ISF book feature matrix` | `completion commit` |

## Changelog

- `2026-05-16`: Added the book-facing ISF shipped feature matrix, advertised it
  through `live_document_paths`, and added a focused drift audit.
