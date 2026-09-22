# DOWNSTREAM-BOOK-CONTRACT-INCLUDE: render the downstream contract in the book

## Metadata

- Tree ID: `DOWNSTREAM-BOOK-CONTRACT-INCLUDE`
- Status: `active`
- Roadmap lane: `downstream integration`
- Created: `2026-09-23`
- Last updated: `2026-09-23`
- Owner: repo-local workflow

## Goal

Make the mdBook downstream integration chapter render the same contract the
canonical handoff already names.

## Non-Goals

- Do not change public ISF behavior, the capability manifest, or the hosted
  VIAL gate.
- Do not copy the handoff into a second maintained book source.
- Do not select the absolute `source.resolved_path` migration. That remains
  proposed tree `DOWNSTREAM-SOURCE-PROVENANCE-CONTRACT`.

## Acceptance Criteria

- The rendered downstream chapter contains the four contract parts.
- Those parts stay one include of the canonical files.
- The rendered chapter links stay inside the book.
- The doctrine gate passes.

## Task Tree

- ID: `DOWNSTREAM-BOOK-CONTRACT-INCLUDE`
  Status: `active`
  Goal: `Render the canonical downstream contract inside the mdBook.`
  Acceptance: `The published chapter contains the four contract parts through includes, and its links resolve inside the book.`
  Verification: `pending`
  Commit: `pending`
  Children: `DOWNSTREAM-BOOK-CONTRACT-INCLUDE.1`
- ID: `DOWNSTREAM-BOOK-CONTRACT-INCLUDE.1`
  Status: `done`
  Goal: `Include the four canonical contract parts in the downstream chapter.`
  Acceptance: `A repository-local mdBook build renders the source-of-truth heading and the four part headings, and every rendered href in that chapter resolves to a generated book page.`
  Verification: `mdbook build docs/book -d .artifacts/mdbook-lockstep-check wrote the chapter. The chapter contains the source-of-truth heading and the readiness, actor, rules, and diagnostics parts. Every rendered href resolves inside the book. The issue-reporting path is named in the included part and linked from the chapter navigation. The disposable build directory is deleted after the check.`
  Commit: `this commit`

## Acceptance Checklist (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S '{{#include ../../ISF_DOWNSTREAM_INTEGRATION_SPEC.md}}' -1 --format='%H %s' -- docs/book/src/13i-downstream-integration.md` identifies the include of the landing page. A repository-local mdBook build rendered that chapter with part hrefs that did not exist as book pages.
- [x] **ADDRESSED (verified)** — The chapter now includes the four canonical contract parts. A rebuilt chapter contains the source-of-truth heading and the readiness, actor, rules, and diagnostics parts. Every rendered href resolves inside the book.
- [x] **NO REGRESSION** — `[doctrine] all doctrine checks passed` after the include, knowledge-map refresh, and claim disposition. `knowledge-map: OK` preserves the lockstep questions.
