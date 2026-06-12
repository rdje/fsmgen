# R11-DIRECT-STRUCTURAL-VHDL-REROUTING: Direct VHDL Rerouting Through StructuralRTLIR

## Metadata

- Tree ID: `R11-DIRECT-STRUCTURAL-VHDL-REROUTING`
- Status: `deferred`
- Roadmap lane: `R11`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Reroute selected direct VHDL emission through `StructuralRTLIR` only after the
SystemVerilog-backed IAL0, IAL1, and IAL2 path is feature complete and the
direct structural surface plus VHDL validation environment are sufficient for a
safe slice.

## Non-Goals

- Do not change behavior in selector `.1`.
- Do not include broader SystemVerilog rerouting; that has a separate proposed
  owner.
- Do not select or implement VHDL backend/reroute work before the
  SystemVerilog-backed IAL0/IAL1/IAL2 path is feature complete.
- Do not claim full aggregate record/array VHDL support or GHDL validation
  availability.
- Do not use raw HDL-string parsing as the rerouting contract.

## Acceptance Criteria

- A selector/readiness leaf records the SV-first/IAL-complete prerequisite
  before any direct VHDL reroute target is selected.
- Any implementation leaf emits only the selected VHDL portion from
  `StructuralRTLIR` and preserves existing supported behavior.
- Focused VHDL/backend tests plus available broader gates prove no unintended
  output drift; GHDL-dependent claims remain blocked unless the tool is
  available.
- Public contracts, mdBook, roadmap, README, and Knowledge Map are updated when
  behavior or user-visible inspection changes.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R11-DIRECT-STRUCTURAL-VHDL-REROUTING`
  Status: `deferred`
  Goal: `Reroute selected direct VHDL emission through StructuralRTLIR.`
  Children: `R11-DIRECT-STRUCTURAL-VHDL-REROUTING.1`,
    `R11-DIRECT-STRUCTURAL-VHDL-REROUTING.2`

- ID: `R11-DIRECT-STRUCTURAL-VHDL-REROUTING.1`
  Status: `done`
  Goal: `Record the SV-first prerequisite for direct VHDL StructuralRTLIR rerouting.`
  Acceptance: `The selector records that direct VHDL backend/reroute work is deferred until the SystemVerilog-backed IAL0/IAL1/IAL2 path is feature complete, and public docs/knowledge no longer present VHDL rerouting as a near-term proposed implementation target.`
  Verification: `passed`
  Commit: `R11-DIRECT-STRUCTURAL-VHDL-REROUTING.1: defer VHDL behind SV IAL completion`

- ID: `R11-DIRECT-STRUCTURAL-VHDL-REROUTING.2`
  Status: `deferred`
  Goal: `Select the first direct VHDL StructuralRTLIR reroute target after SV-backed IAL completion.`
  Acceptance: `No selector or implementation runs until IAL0, IAL1, and IAL2 are feature complete on the SystemVerilog-backed path and the VHDL validation environment is sufficient for a signoff-level slice.`
  Verification: `not run; deferred by selector .1`
  Commit: `deferred`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-DIRECT-STRUCTURAL-VHDL-REROUTING.1` | `done` | Selector recorded that VHDL backend/reroute work is not a near-term target before SV-backed IAL0/IAL1/IAL2 feature completion. |
| 2 | `R11-DIRECT-STRUCTURAL-VHDL-REROUTING.2` | `deferred` | Direct VHDL reroute target selection is blocked until the SystemVerilog-backed IAL path is feature complete and VHDL validation is sufficient. |

## Decisions

- `2026-06-12`: Track direct VHDL rerouting separately from SystemVerilog
  rerouting because VHDL support and external GHDL validation have distinct
  prerequisites and risk.
- `2026-06-12`: Defer direct VHDL backend/reroute work behind
  SystemVerilog-backed IAL0/IAL1/IAL2 feature completeness. VHDL is not a
  PNT-ready implementation lane while the primary SV-backed language and
  protocol-intent path is still incomplete.
- `2026-06-12`: Activate `IAL2-FEATURE-COMPLETENESS-FRONTIER` as the next
  feature-completeness owner. IAL2 completion may require explicitly selected
  IAL1 or IAL0/SystemVerilog prerequisites; those prerequisites are in scope
  only when task-tree owned.

## Open Questions

- None blocking while deferred.

## Blockers

- Not active.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `R11-DIRECT-STRUCTURAL-VHDL-REROUTING.1` | Audit/read: `docs/tasks/R11-DIRECT-STRUCTURAL-VHDL-REROUTING.md`; `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; `docs/TASK_TREE.md`; `README.md`; `ROADMAP_V2.md`; `docs/book/src/09-generated-hdl-debugging-and-inspection.md`; `docs/book/src/11-extensions-and-embedding.md`; `docs/book/src/14-feature-backlog.md`; `docs/knowledge/direct-structural-remaining-owner-coverage.md`; `docs/knowledge/vhdl-deferred-until-sv-ial-complete.md`; `docs/knowledge/ial2-feature-completeness-priority.md`; `docs/knowledge/axi-ial2-valid-ready-generator-first-slice.md`; `docs/knowledge/ial2-ppif-parser-cli-first-slice.md`; `docs/knowledge/ial2-ppif-bundle-hdl-entry-first-slice.md`; `docs/decisions/0001-isf-abstraction-layering.md`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check` | `passed`; VHDL backend/reroute work deferred behind SV-backed IAL feature completeness and IAL2 frontier activated |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-DIRECT-STRUCTURAL-VHDL-REROUTING.1` | `R11-DIRECT-STRUCTURAL-VHDL-REROUTING.1: defer VHDL behind SV IAL completion` | Selector records the SV-first/IAL-complete prerequisite for future VHDL work. |
| `R11-DIRECT-STRUCTURAL-VHDL-REROUTING.2` | `deferred` | No direct VHDL target selection runs before SV-backed IAL0/IAL1/IAL2 feature completion. |

## Changelog

- `2026-06-12`: Created proposed owner tree.
- `2026-06-12`: Completed selector `.1`; direct VHDL backend/reroute work is
  deferred until the SystemVerilog-backed IAL0/IAL1/IAL2 path is feature
  complete and VHDL validation is sufficient.
