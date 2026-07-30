# MDBOOK-RUSTDOC-NON-RUST-FENCE-REPAIR: Stop Rustdoc From Compiling Plain-Text Diagrams

## Metadata

- Tree ID: `MDBOOK-RUSTDOC-NON-RUST-FENCE-REPAIR`
- Status: `active`
- Roadmap lane: `documentation validation / mdBook`
- Created: `2026-07-23`
- Last updated: `2026-07-30`
- Owner: repo-local workflow

## Goal

Restore a clean `mdbook test docs/book` by labeling four existing plain-text
ISF diagrams as non-Rust code while preserving their rendered content.

## Non-Goals

- Do not change ISF behavior, examples, generated artifacts, or prose meaning.
- Do not sweep or reclassify unrelated code fences.
- Do not alter the mdBook HTML renderer or rustdoc configuration.

## Root Cause

`mdbook test docs/book` treats untyped fenced blocks as Rust doctests. Four
plain-text diagrams contain Unicode arrows or Lisp-like pseudocode and are
therefore sent to rustdoc as invalid Rust:

- `docs/book/src/13-intent-scheduling.md` Pipeline diagram;
- `docs/book/src/13b-transactions.md` transaction-to-state sketch;
- `docs/book/src/13f-composition.md` composition architecture diagram;
- `docs/book/src/13h-lowering-reference.md` APB state summary.

Git blame dates every affected fence to 2026-05-12 through 2026-05-14, proving
the defect predates the AXI full-write slice that exposed it. `mdbook build
docs/book` remains clean; only the doctest classification is wrong.

## Acceptance Criteria

- Give only the four identified diagram fences an explicit non-Rust language
  classification suitable for mdBook/rustdoc.
- Preserve every diagram byte other than the opening fence annotation.
- `mdbook test docs/book` passes.
- `mdbook build docs/book`, whitespace, docs paths, Knowledge Map, and doctrine
  gates pass.
- Commit the repair through `COMMIT.md`.

## Task Tree

- ID: `MDBOOK-RUSTDOC-NON-RUST-FENCE-REPAIR`
  Status: `active`
  Goal: `Repair the four pre-existing untyped plain-text fences so mdbook test is a trustworthy gate again.`
  Children: `MDBOOK-RUSTDOC-NON-RUST-FENCE-REPAIR.1`

- ID: `MDBOOK-RUSTDOC-NON-RUST-FENCE-REPAIR.1`
  Status: `active`
  Goal: `Classify the four known diagrams as text and restore clean mdBook doctests.`
  Acceptance: `Change only the four opening fences from untyped to text; prove no diagram-content drift; run mdbook test/build and doctrine gates; synchronize task/index/MEMORY/Knowledge Map and commit.`
  Verification: `Activated only after clean selector commit 9e3308e5c. Current-HEAD evidence remains exactly four untyped opening fences at docs/book/src/13-intent-scheduling.md line 307, 13b-transactions.md line 121, 13f-composition.md line 250, and 13h-lowering-reference.md line 2217; every matching close remains intact. Activation changes continuity documentation only and leaves all four fences, their contents, tests, product behavior, and the scheduled lifecycle review unchanged until this commit is clean. Feature-backlog status, live-book-path, and relative-path audits pass with Files=3, Tests=40; Knowledge Map generation/check passes at 1,070 facts / 5,507 question keys; mdBook HTML build and diff hygiene pass; Memory remains 60 lines and README remains 246 lines.`
  Commit: `MDBOOK-RUSTDOC-NON-RUST-FENCE-REPAIR.1: activate plain-text fence repair`

## Decisions

- `2026-07-23`: Keep this proposed and outside the active AXI PNT frontier;
  tracking the discovered validation defect must not silently pivot product
  scope while `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.23` is active.
- `2026-07-30`: Clean parent selector commit `9e3308e5c` selects and activates
  only `.1`; the four opening fences remain unchanged until the continuity
  commit is clean.

## Blockers

- None. `.1` is active from the clean selector boundary.
