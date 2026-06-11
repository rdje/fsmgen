# ISF-ATL-GENERATED-TOP-PLANNER-EXTRACTION: ATL Generated-Top Planner Extraction

## Metadata

- Tree ID: `ISF-ATL-GENERATED-TOP-PLANNER-EXTRACTION`
- Status: `done`
- Roadmap lane: `architecture backlog`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Reduce private `FSM::Scheduler::ISF::LoweringIR` generated-top coupling by
extracting one proven, behavior-preserving ATL generated-top helper boundary at
a time.

## Non-Goals

- Do not expose raw LoweringIR hashes or ATL generated-top internals as public
  API.
- Do not change emitted `.fsm`, generated top, schedule JSON, or generated HDL
  behavior under this architecture label.
- Do not extract the full ATL generated-top planner in one broad refactor.
- Do not move parser-owned ATL source validation or scheduler-owned state
  lowering out of their current owners in this tree.

## Acceptance Criteria

- A stable ATL generated-top helper boundary is selected before source changes.
- Each implementation leaf preserves existing public artifacts and reports.
- Focused `t/1330` generated-top coverage passes after any source change.
- Broader ISF/documentation gates run when the blast radius warrants it.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-ATL-GENERATED-TOP-PLANNER-EXTRACTION`
  Status: `done`
  Goal: `Extract stable private ATL generated-top helper ownership without behavior drift.`
  Children: `ISF-ATL-GENERATED-TOP-PLANNER-EXTRACTION.1`,
  `ISF-ATL-GENERATED-TOP-PLANNER-EXTRACTION.2`

- ID: `ISF-ATL-GENERATED-TOP-PLANNER-EXTRACTION.1`
  Status: `done`
  Goal: `Select the first exact ATL generated-top extraction boundary.`
  Acceptance: `Audit recent ATL generated-top work, name one safe private helper-owner boundary, record unchanged public surfaces, and activate one implementation leaf.`
  Verification: `scripts/check_memory_architecture.sh`; `knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `git diff --check`
  Commit: `ISF-ATL-GENERATED-TOP-PLANNER-EXTRACTION.1: select projection extraction`

- ID: `ISF-ATL-GENERATED-TOP-PLANNER-EXTRACTION.2`
  Status: `done`
  Goal: `Extract ATL generated-top report projection and child-interface marking helpers into a private scheduler helper module.`
  Acceptance: `Move only the pure generated-top report-entry projection and data-link child interface marking helpers out of LoweringIR into a private module; keep generated-top selection, route validation, state lowering, schedule JSON shape, generated top artifacts, and HDL byte behavior unchanged.`
  Verification: `perl -Iperl -c perl/FSM/Scheduler/ISF/ATLGeneratedTop.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1112-isf-public-interface-contract.t t/1113-isf-public-interface-contract-json-roundtrip-audit.t t/1114-isf-public-interface-contract-defensive-copy-audit.t t/1414-docs-relative-paths-audit.t`; mdBook generated-top sync audit; `mdbook build docs/book`; `scripts/check_memory_architecture.sh`; `knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check`
  Commit: `ISF-ATL-GENERATED-TOP-PLANNER-EXTRACTION.2: extract generated-top projection helper`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-ATL-GENERATED-TOP-PLANNER-EXTRACTION.1` | `done` | Recent ATL generated-top leaves shipped one-child, two-child, data-route, and trigger-batch variants under stable file-backed coverage. |
| 2 | `ISF-ATL-GENERATED-TOP-PLANNER-EXTRACTION.2` | `done` | The selected report projection and child-interface marking helpers have bounded inputs, no parser ownership, and focused `t/1330` coverage across every shipped ATL generated-top family. |

## Decisions

- `2026-06-12`: Selected the ATL generated-top report projection and
  child-interface marking helpers as the first extraction boundary. The prior
  `ISF-LOWERINGIR-BOUNDARY-EXTRACTION` and `ARCHITECTURE-DEBT-FRONTIER.3`
  trees deferred extraction until a stable family was proven; the recent ATL
  generated-top sequence now provides a stable behavior family with one
  focused regression suite, `t/1330-isf-atl-resolved-child-fixture-coverage.t`.
- `2026-06-12`: Rejected a full generated-top planner extraction as the first
  leaf. `_select_atl_generated_top_instances` still owns behavior selection,
  diagnostics, and route validation, and it depends on many LoweringIR-private
  helpers. The smaller projection/marking boundary removes private projection
  logic without moving behavior selection.
- `2026-06-12`: Extracted the selected private projection/marking boundary to
  `FSM::Scheduler::ISF::ATLGeneratedTop`. The new helper owns generated-top
  schedule-report projection and data-link child-interface marking only; it
  does not own generated-top selection, route validation, scheduler state
  lowering, emitted `.fsm` artifacts, or public report schema evolution.
- `2026-06-12`: Checked the mdBook generated-top/ATL pages after the extraction.
  Feature behavior examples and public-surface descriptions remain unchanged
  because the slice is behavior-preserving; the backlog/status tail was
  refreshed to name the new private helper owner.

## Open Questions

- Whether later leaves should extract route-data-link validation or the full
  generated-top planner remains open. That does not block `.2`.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `.1` | Evidence review: `ARCHITECTURE-DEBT-FRONTIER.3`, `ISF-LOWERINGIR-BOUNDARY-EXTRACTION`, `perl/FSM/Scheduler/ISF/LoweringIR.pm`, `t/1330-isf-atl-resolved-child-fixture-coverage.t`; `scripts/check_memory_architecture.sh`; `knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `git diff --check` | pass |
| `2026-06-12` | `.2` | `perl -Iperl -c perl/FSM/Scheduler/ISF/ATLGeneratedTop.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1112-isf-public-interface-contract.t t/1113-isf-public-interface-contract-json-roundtrip-audit.t t/1114-isf-public-interface-contract-defensive-copy-audit.t t/1414-docs-relative-paths-audit.t`; mdBook generated-top sync audit; `mdbook build docs/book`; `scripts/check_memory_architecture.sh`; `knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check` | pass |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `ISF-ATL-GENERATED-TOP-PLANNER-EXTRACTION.1: select projection extraction` | Selection-only owner creation and implementation-leaf activation. |
| `.2` | `ISF-ATL-GENERATED-TOP-PLANNER-EXTRACTION.2: extract generated-top projection helper` | Added the private ATL generated-top helper owner and rewired `LoweringIR` callers without changing public artifacts or user-facing behavior. |

## Changelog

- `2026-06-12`: Created active task tree, completed selection leaf `.1`, and
  activated `.2`.
- `2026-06-12`: Completed `.2`, closed this extraction tree, refreshed the
  import-tree/README/mdBook architecture maps, and recorded that the public
  behavior surface remains unchanged.
