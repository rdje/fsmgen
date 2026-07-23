# MDBOOK-RUSTDOC-NON-RUST-FENCE-REPAIR: Stop Rustdoc From Compiling Plain-Text Diagrams

## Metadata

- Tree ID: `MDBOOK-RUSTDOC-NON-RUST-FENCE-REPAIR`
- Status: `proposed`
- Roadmap lane: `documentation validation / mdBook`
- Created: `2026-07-23`
- Last updated: `2026-07-23`
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
  Status: `proposed`
  Goal: `Repair the four pre-existing untyped plain-text fences so mdbook test is a trustworthy gate again.`
  Children: `MDBOOK-RUSTDOC-NON-RUST-FENCE-REPAIR.1`

- ID: `MDBOOK-RUSTDOC-NON-RUST-FENCE-REPAIR.1`
  Status: `pending`
  Goal: `Classify the four known diagrams as text and restore clean mdBook doctests.`
  Acceptance: `Change only the four opening fences from untyped to text; prove no diagram-content drift; run mdbook test/build and doctrine gates; synchronize task/index/MEMORY/Knowledge Map and commit.`
  Verification: `pending`
  Commit: `pending`

## Decisions

- `2026-07-23`: Keep this proposed and outside the active AXI PNT frontier;
  tracking the discovered validation defect must not silently pivot product
  scope while `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.23` is active.

## Blockers

- None technical. Activation/order follows the task-tree pivot doctrine.
