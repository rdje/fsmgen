# DOWNSTREAM-BOOK-CONTRACT-INCLUDE: render the downstream contract in the book

## Metadata

- Tree ID: `DOWNSTREAM-BOOK-CONTRACT-INCLUDE`
- Status: `done`
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
  Status: `done`
  Goal: `Render the canonical downstream contract inside the mdBook.`
  Acceptance: `The published chapter contains the four contract parts through includes, and its links resolve inside the book.`
  Verification: `The current canonical includes and rendered chapter pass independent source and HTML review: readiness, actor, rules and diagnostics anchors are present, source-of-truth text is rendered, and every local chapter href resolves to a generated file and existing fragment. mdbook build succeeds. No source/provenance behavior changes; the separately proposed provenance contract and HIAL launch gate remain open.`
  Commit: `DOWNSTREAM-BOOK-CONTRACT-INCLUDE.2: close verified downstream book activity`
  Children: `DOWNSTREAM-BOOK-CONTRACT-INCLUDE.1, DOWNSTREAM-BOOK-CONTRACT-INCLUDE.2`
- ID: `DOWNSTREAM-BOOK-CONTRACT-INCLUDE.1`
  Status: `done`
  Goal: `Include the four canonical contract parts in the downstream chapter.`
  Acceptance: `A repository-local mdBook build renders the source-of-truth heading and the four part headings, and every rendered href in that chapter resolves to a generated book page.`
  Verification: `mdbook build docs/book -d .artifacts/mdbook-lockstep-check wrote the chapter. The chapter contains the source-of-truth heading and the readiness, actor, rules, and diagnostics parts. Every rendered href resolves inside the book. The issue-reporting path is named in the included part and linked from the chapter navigation. The disposable build directory is deleted after the check.`
  Commit: `this commit`

- ID: `DOWNSTREAM-BOOK-CONTRACT-INCLUDE.2`
  Status: `done`
  Goal: `Independently verify the rendered contract and close the completed parent activity.`
  Acceptance: `Build the current book in a disposable repository-local directory, confirm the four exact canonical includes and rendered part headings, and check every chapter href against generated files and fragments. Close the root and remove its active-index row only after these checks and doctrine validation; preserve the separate unresolved provenance contract and HIAL launch question.`
  Verification: `mdbook build docs/book -d .artifacts/mdbook-downstream-closeout succeeds. Independent HTMLParser/urlsplit review checks the exact ordered canonical includes, all four section anchors, source-of-truth text, repository-contained generated link targets and target fragments. Output: downstream-closeout: exact canonical includes, four section anchors, source-of-truth text and all chapter-local links/fragments pass. The disposable generated book is removed exactly after review. Parent acceptance is met; doctrine and task-tree gates run before commit.`
  Commit: `this commit`

## Acceptance Checklist (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S '{{#include ../../ISF_DOWNSTREAM_INTEGRATION_SPEC.md}}' -1 --format='%H %s' -- docs/book/src/13i-downstream-integration.md` identifies the include of the landing page. A repository-local mdBook build rendered that chapter with part hrefs that did not exist as book pages.
- [x] **ADDRESSED (verified)** — The chapter now includes the four canonical contract parts. A rebuilt chapter contains the source-of-truth heading and the readiness, actor, rules, and diagnostics parts. Every rendered href resolves inside the book.
- [x] **NO REGRESSION** — `[doctrine] all doctrine checks passed` after the include, knowledge-map refresh, and claim disposition. `knowledge-map: OK` preserves the lockstep questions.

## Acceptance Checklist (parent closeout .2)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'DOWNSTREAM-BOOK-CONTRACT-INCLUDE.1'` identifies `0fc987bff`. The sole implementation leaf is done while its parent and cross-tree index still say active, leaving no executable frontier despite completed acceptance.
- [x] **ADDRESSED (verified)** — Current source has exactly the ordered canonical includes; the rebuilt chapter contains all contract sections and source-of-truth text. Independent HTML parsing checks every local generated file and fragment target. Both leaves and the root are now terminal, and the stale active row is removed. The required history remains in the task and Git.
- [x] **NO REGRESSION** — `knowledge-map: OK` retains the canonical downstream lockstep routes. `mdbook build docs/book -d .artifacts/mdbook-downstream-closeout` succeeds; every checked link and fragment resolves. Re-derive: exact current include sources and rendered HTML; falsify: missing-file, missing-fragment and outside-book assertions on every local href; durability: canonical source includes and this task's exact closure criteria. This closes book inclusion only, without changing the deferred source-provenance contract or authorizing a HIAL launch.
