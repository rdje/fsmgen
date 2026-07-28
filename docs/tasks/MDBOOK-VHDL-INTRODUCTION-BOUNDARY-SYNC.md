# MDBOOK-VHDL-INTRODUCTION-BOUNDARY-SYNC: Align Introductory VHDL Claims

## Metadata

- Tree ID: `MDBOOK-VHDL-INTRODUCTION-BOUNDARY-SYNC`
- Status: `proposed`
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
  Status: `proposed`
  Goal: `Synchronize the mdBook's introductory VHDL boundary.`
  Children: `MDBOOK-VHDL-INTRODUCTION-BOUNDARY-SYNC.1`

- ID: `MDBOOK-VHDL-INTRODUCTION-BOUNDARY-SYNC.1`
  Status: `proposed`
  Goal: `Audit and repair stale introductory VHDL non-implementation wording.`
  Acceptance: `Introductory and troubleshooting claims match the bounded shipped surface and preserve full-backend/GHDL deferrals.`
  Verification: `pending`
  Commit: `pending`

## Decisions

- `2026-07-29`: Startup review found Chapter 00 still says explicit VHDL
  support is not implemented, while Chapter 14 documents a substantial bounded
  direct/composition VHDL subset. This is a public truth-sync repair, not a
  backend feature slice.

## Blockers

- Inactive until selected from a clean tree after the current adoption closes.
