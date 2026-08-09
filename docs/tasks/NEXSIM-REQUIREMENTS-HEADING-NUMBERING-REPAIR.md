# NEXSIM-REQUIREMENTS-HEADING-NUMBERING-REPAIR: Restore section/subsection numbering alignment

## Metadata

- Tree ID: `NEXSIM-REQUIREMENTS-HEADING-NUMBERING-REPAIR`
- Status: `proposed`
- Roadmap lane: `NEXSIM requirements / document integrity`
- Created: `2026-08-09`
- Last updated: `2026-08-09`
- Owner: repo-local workflow

## Origin

The IAL2 mdBook coherence audit found a deterministic numbering defect in
`docs/NEXSIM_API_MCP_AGENT_CONSUMER_REQUIREMENTS.md`: top-level section 36 owns
subsections numbered `35.x`, section 37 owns `36.x`, and the one-section lag
continues through the section-42 subsections. Requirement identities remain
stable; the human-facing hierarchy is inconsistent.

## Goal

Align NEXSIM subsection numbers with their owning top-level sections while
preserving every normative requirement identity and technical statement.

## Non-Goals

- Do not change NEXSIM scope, requirements, priority, APIs, MCP schemas, or
  conformance meaning.
- Do not activate NEXSIM implementation work.

## Task Tree

- ID: `NEXSIM-REQUIREMENTS-HEADING-NUMBERING-REPAIR`
  Status: `proposed`
  Goal: `Repair deterministic subsection numbering drift without changing requirements semantics.`
  Children: `NEXSIM-REQUIREMENTS-HEADING-NUMBERING-REPAIR.1`

- ID: `NEXSIM-REQUIREMENTS-HEADING-NUMBERING-REPAIR.1`
  Status: `pending`
  Goal: `Audit and mechanically align subsections under sections 36 through 42.`
  Acceptance: `On clean activation, census all top-level and subsection headings, change only lagging human-facing subsection numbers so each matches its parent, verify heading/link/navigation integrity and zero normative requirement-ID/text changes, then pass path/doctrine gates.`
  Verification: `Pending. Discovery evidence: section 36 begins at line 1501 but its subsections begin 35.1; the same one-section lag is present for sections 37, 38, 41, and 42 in the current file.`
  Commit: `pending activation`

## Decisions

- `2026-08-09`: Park the mechanical repair independently; it is unrelated to
  IAL2/AXI semantics and must not widen the active documentation slice.

## Blockers

- Clean explicit activation after the current selected tree completes or parks.
