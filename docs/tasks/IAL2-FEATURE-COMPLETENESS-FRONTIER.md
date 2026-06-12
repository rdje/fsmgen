# IAL2-FEATURE-COMPLETENESS-FRONTIER: IAL2 Feature Completeness Frontier

## Metadata

- Tree ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER`
- Status: `active`
- Roadmap lane: `IAL2 / SV-backed feature completeness`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Drive IAL2 toward feature completeness on the SystemVerilog-backed lowering
path before reopening VHDL backend or VHDL rerouting work.

## Non-Goals

- Do not implement VHDL backend or VHDL reroute work from this tree.
- Do not claim IAL2 is feature complete until all selected protocol/platform
  intent surfaces, diagnostics, generated IAL1/IAL0 review artifacts, HDL
  generation, reports, and mdBook documentation are task-tree owned and
  verified.
- Do not bypass the required `IAL2 -> IAL1 -> IAL0 -> SystemVerilog` lowering
  chain.
- Do not widen `.isf` with IAL2 source forms by accident; any IAL1 feature
  required by IAL2 must be explicitly selected, task-tree owned, documented,
  and regression-backed.

## Acceptance Criteria

- The first leaf audits shipped IAL2 surfaces and selects the next exact
  feature-completeness slice before behavior changes.
- The audit explicitly records any IAL1 or IAL0/SV prerequisites required by
  the selected IAL2 slice.
- Every implementation leaf preserves reviewable generated IAL1 and IAL0
  artifacts before SystemVerilog HDL generation.
- Public contracts, diagnostics, mdBook, roadmap, and Knowledge Map are kept in
  sync for each shipped IAL2 capability.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER`
  Status: `active`
  Goal: `Make IAL2 feature-complete on the SystemVerilog-backed path before VHDL work resumes.`
  Children: `IAL2-FEATURE-COMPLETENESS-FRONTIER.1`

- ID: `IAL2-FEATURE-COMPLETENESS-FRONTIER.1`
  Status: `pending`
  Goal: `Audit the shipped IAL2 surface and select the next exact feature-completeness slice.`
  Acceptance: `The selector records shipped IAL2 capabilities, missing feature-completeness surfaces, likely next slice, required IAL1/IAL0/SV prerequisites, validation gates, rollback boundary, docs/contracts to update, and any blockers before behavior changes.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `IAL2-FEATURE-COMPLETENESS-FRONTIER.1` | `pending` | IAL2 is the current feature-completeness priority before any VHDL backend/reroute work. |

## Decisions

- `2026-06-12`: Prioritize IAL2 feature completeness on the
  SystemVerilog-backed path before reopening VHDL backend or direct VHDL
  rerouting work.
- `2026-06-12`: IAL2 feature-completeness slices may require new IAL1 and
  IAL0/SV support. Those prerequisites are in scope when explicitly selected
  by a task-tree leaf and must preserve the reviewable lowering chain.

## Open Questions

- The first selector must decide which IAL2 gap is the next signoff-sized
  slice; likely candidates include protocol rule coverage beyond Valid-Ready,
  profile aliases, additional `.ppif` clauses, diagnostics, reports, AXI
  manager subset boundaries, or required IAL1 support for those IAL2 features.

## Blockers

- Not blocked.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `IAL2-FEATURE-COMPLETENESS-FRONTIER.1` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `IAL2-FEATURE-COMPLETENESS-FRONTIER.1` | `pending` | `pending` |

## Changelog

- `2026-06-12`: Created active IAL2 feature-completeness frontier.
