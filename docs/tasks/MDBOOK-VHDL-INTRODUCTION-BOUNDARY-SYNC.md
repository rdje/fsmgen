# MDBOOK-VHDL-INTRODUCTION-BOUNDARY-SYNC: Align Introductory VHDL Claims

## Metadata

- Tree ID: `MDBOOK-VHDL-INTRODUCTION-BOUNDARY-SYNC`
- Status: `active`
- Roadmap lane: `roadmap/documentation alignment / VHDL`
- Created: `2026-07-29`
- Last updated: `2026-07-29`
- Owner: repo-local workflow

## Goal

Align the mdBook's introductory/backend-summary VHDL wording with the bounded
direct and composition VHDL subsets documented by the live backlog and
implemented code, without implying that the full backend or GHDL validation is
shipped.

## Non-Goals

- Do not widen VHDL generation or validation behavior.
- Do not claim full backend completeness.

## Acceptance Criteria

- `00-introduction.md`, the backend-expectations section in Chapter 10, and the
  canonical Chapter 14 VHDL boundary tell one consistent story.
- Examples and links distinguish bounded generated VHDL from the still-backlog
  full backend and GHDL validation.
- Focused mdBook, doctrine, memory, and diff gates pass and the leaf is
  committed through `COMMIT.md`.

## Task Tree

- ID: `MDBOOK-VHDL-INTRODUCTION-BOUNDARY-SYNC`
  Status: `active`
  Goal: `Synchronize the mdBook's introductory VHDL boundary.`
  Children: `MDBOOK-VHDL-INTRODUCTION-BOUNDARY-SYNC.1`

- ID: `MDBOOK-VHDL-INTRODUCTION-BOUNDARY-SYNC.1`
  Status: `active`
  Goal: `Audit and repair stale introductory VHDL non-implementation wording.`
  Acceptance: `Introductory and troubleshooting claims match the bounded shipped surface and preserve full-backend/GHDL deferrals.`
  Verification: `Activated only after clean parent selector commit 191a65151. Activation changes continuity pointers only; Chapters 00/10 retain their stale wording until this commit is clean, while Chapter 14, generated behavior, direct/composition VHDL support, qualification boundaries, and all other roadmap owners remain unchanged. Book/status/path truth passes 5 files/329 tests. Knowledge Map generation/check passes at 1,062 facts/5,466 question keys. The mdBook renders exactly 72 files/16,528,171 bytes and its repository-local output is removed. .artifacts/tmp/tests is empty, MEMORY.md is 49 lines, README.md is 2,349 lines, and diff hygiene passes. Activation-closeout canonical Stats-compatible capacity is 18,294,226,944/25,769,803,776 bytes = 17.038/24.000 GiB = 70.99%, with separate macOS kernel pressure level 1 and memory_pressure 75% free; guard occupancy is excluded from capacity truth. No background job remains.`
  Commit: `MDBOOK-VHDL-INTRODUCTION-BOUNDARY-SYNC.1: activate book truth repair`

## Decisions

- `2026-07-29`: Startup review found Chapter 00 still says explicit VHDL
  support is not implemented, while Chapter 14 documents a substantial bounded
  direct/composition VHDL subset. This is a public truth-sync repair, not a
  backend feature slice.
- `2026-07-30`: Parent selector
  `IAL2-FEATURE-COMPLETENESS-FRONTIER.833` selects `.1` as the smallest current
  truth-sync owner after assertion-precedence repair. The tree remains proposed
  until the selector commits cleanly.
- `2026-07-30`: Clean selector commit `191a65151` activates `.1`
  continuity-only; no book claim or product behavior changes during activation.

## Blockers

- Active only after clean parent selector commit `191a65151`; align Chapters
  00 and 10 with the canonical Chapter 14 boundary without changing behavior.
