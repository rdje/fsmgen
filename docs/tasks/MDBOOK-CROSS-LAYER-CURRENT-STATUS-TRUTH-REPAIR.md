# MDBOOK-CROSS-LAYER-CURRENT-STATUS-TRUTH-REPAIR: Remove stale live-status narration from Chapter 11

## Metadata

- Tree ID: `MDBOOK-CROSS-LAYER-CURRENT-STATUS-TRUTH-REPAIR`
- Status: `done`
- Roadmap lane: `project documentation / cross-layer current truth`
- Created: `2026-08-09`
- Last updated: `2026-09-23`
- Owner: repo-local workflow

## Origin

The IAL2 mdBook coherence audit found Chapter 11 still calls
`BACKEND-API-VALIDATION-FRONTIER.104` the active backend/API frontier, says a
historical GHDL-unavailable leaf defines the current validation boundary, and
later says roadmap priority returned to `IAL2-FEATURE-COMPLETENESS-FRONTIER.197`.
Those live-status claims predate the current HIAL/VIAL decisions and task-tree
frontiers. They are independently reproducible but outside the selected
IAL2/AXI documentation tree.

## Goal

Make Chapter 11 describe durable shipped API/backend contracts and current
bounded residue without embedding obsolete task-frontier narration.

## Non-Goals

- Do not change backend, API, VHDL, GHDL, OSVVM, HIAL, VIAL, or MCP behavior.
- Do not infer the current qualification boundary from tool installation alone;
  reconcile decision, task, report, test, and runtime evidence first.

## Task Tree

- ID: `MDBOOK-CROSS-LAYER-CURRENT-STATUS-TRUTH-REPAIR`
  Status: `done`
  Goal: `Replace stale Chapter 11 live-status narration with durable shipped-contract truth.`
  Children: `MDBOOK-CROSS-LAYER-CURRENT-STATUS-TRUTH-REPAIR.1`

- ID: `MDBOOK-CROSS-LAYER-CURRENT-STATUS-TRUTH-REPAIR.1`
  Status: `done`
  Goal: `Audit and repair the stale Chapter 11 backend/API/VHDL status passages.`
  Acceptance: `On clean activation, reconcile Chapter 11 lines around the historical .104/.102/.197 claims with current BACKEND-API task history, decisions 0032/0051, HIAL/VIAL .15 qualification evidence, capability manifests, tests, and actual tool profiles. Replace volatile active-frontier narration with durable shipped capability and residue statements; update any directly dependent book prose; build the book and pass path/doctrine gates without changing behavior.`
  Verification: `Chapter 11 now states stable package-import metadata and direct-HIAL boundaries, keeps ordinary --verify-hdl SystemVerilog-only, and routes separate VIAL portable/OSVVM GHDL qualification to its architecture chapter. Both tracked qualification records are qualified under exact GHDL 6.0.0 LLVM-JIT, with OSVVM 2026.05 for its provider profile; their recorded execution and rerun statuses pass. No provider/tool execution or current PATH claim is inferred. Guarded public-contract/semantic/facade tests pass Files=7, Tests=110. The book builds, revised prose renders, old live-status/tool-absence strings are absent, and new architecture links resolve.`
  Commit: `this commit`

## Decisions

- `2026-08-09`: Track this separately from IAL2 AXI coherence because it spans
  backend/API and HIAL/VIAL qualification truth.

- `2026-09-23`: Keep the ordinary CLI validation contract distinct from
  profile-specific VIAL qualification. Use checked qualification records and
  public contract builders; do not infer support from PATH or inspect provider
  implementation. Retain all bounded direct-HIAL and legacy-output limits.

## Blockers

- None for this documentation correction, selected under unlimited PNT after
  clean NEXSIM evidence correction `a672e7dfd`. HIAL launch sequencing and
  full-CI/push prerequisites remain unchanged.

## Acceptance Checklist (Chapter 11 truth repair .1)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'BACKEND-API-VALIDATION-FRONTIER.104' -- docs/book/src/11-extensions-and-embedding.md` identifies `462060525`. Chapter 11 kept that selector as active after its owning node was done; it also retained the historical .102.1 GHDL-absence observation and the .197 IAL2 return as present-day status. Decisions 0032/0051 and the later checked .15 qualification reports separate VIAL profiles from the ordinary CLI validation lane.
- [x] **ADDRESSED (verified)** — Revised prose states durable package-name-list metadata, import-only package roots, aggregate structural VHDL rejection and the SystemVerilog-only --verify-hdl contract. It names the separately recorded VIAL portable/OSVVM qualification and directs live sequencing to task trees and Memory. Independent JSON inspection verifies each exact profile, qualified status, GHDL LLVM-JIT version, execution and deterministic-rerun status; the provider profile identifies OSVVM 2026.05. Book rendering confirms the new distinctions and working architecture links, with every targeted stale status statement absent.
- [x] **NO REGRESSION** — RAM-guarded `prove -Iperl` for t/277, t/278, t/313, t/335, t/339, t/386 and t/297 reports All tests successful, Files=7, Tests=110. Public semantic metadata, direct VHDL boundaries and capability contracts agree with the repaired text. `knowledge-map: OK` preserves existing profile facts and adds the explicit CLI/profile distinction. Re-derive: current contract builders and focused tests; falsify: exact qualified-profile metadata and rendered source/HTML checks against the stale assertions; durability: existing tracked reports, corrected book, canonical fact card and this task. This is documentation repair, not a new GHDL run, support promotion or release qualification; HIAL startup and full-CI/push gates remain intact.
