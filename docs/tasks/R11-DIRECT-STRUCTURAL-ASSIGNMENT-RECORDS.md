# R11-DIRECT-STRUCTURAL-ASSIGNMENT-RECORDS: Direct Structural Assignment Records

## Metadata

- Tree ID: `R11-DIRECT-STRUCTURAL-ASSIGNMENT-RECORDS`
- Status: `active`
- Roadmap lane: `R11`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Add a machine-readable direct `StructuralRTLIR` assignment-record surface for
generated enable assignments, so downstream consumers can inspect structured
left-hand side, right-hand side, assignment kind, and provenance without
parsing HDL text.

## Non-Goals

- Do not remove the existing `auxiliary_assignments[]` scalar-string field in
  this slice; it is already advertised by the public contract and remains a
  compatibility mirror until a later explicit compatibility owner changes it.
- Do not reroute HDL emission through `StructuralRTLIR`.
- Do not parse arbitrary HDL text back into records.
- Do not add direct instances, declared links, resolved links, or net
  source/target connectivity in this slice; direct net connectivity is tracked
  separately by `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY`.
- Do not reroute HDL emission through `StructuralRTLIR`; direct HDL rerouting
  is tracked separately by `R11-DIRECT-STRUCTURAL-HDL-REROUTING`.
- Do not widen beyond generated enable assignments already prepared by the
  direct backend.

## Acceptance Criteria

- Direct roots expose machine-readable assignment records for top-level
  state/standalone-DT enable assignments, DT-specific WEN/EN assignments, and
  LHS-level WEN/EN assignments.
- Each record includes stable structured fields for assignment kind, `lhs`,
  `rhs`, rendered SystemVerilog text, and source/provenance metadata where the
  backend already has it.
- Direct `auxiliary_assignments[]` remains present as the existing scalar
  string compatibility mirror, but tests and docs make the structured record
  surface the meaningful downstream interface.
- Public contracts, mdBook, roadmap, Knowledge Map, and task-tree evidence are
  updated.
- Focused direct structural tests, public contract tests, mdBook checks,
  Knowledge Map, memory architecture, and diff whitespace checks pass before
  commit.

## Task Tree

- ID: `R11-DIRECT-STRUCTURAL-ASSIGNMENT-RECORDS`
  Status: `active`
  Goal: `Add direct StructuralRTLIR machine-readable assignment records.`
  Children: `R11-DIRECT-STRUCTURAL-ASSIGNMENT-RECORDS.1`, `R11-DIRECT-STRUCTURAL-ASSIGNMENT-RECORDS.2`

- ID: `R11-DIRECT-STRUCTURAL-ASSIGNMENT-RECORDS.1`
  Status: `done`
  Goal: `Select the direct assignment-record scope and track related structural follow-on trees.`
  Acceptance: `The assignment-record scope, scalar compatibility boundary, direct net source/target connectivity follow-on, and direct HDL rerouting follow-on are task-tree tracked before code changes.`
  Verification: `pending`
  Commit: `pending`

- ID: `R11-DIRECT-STRUCTURAL-ASSIGNMENT-RECORDS.2`
  Status: `pending`
  Goal: `Project direct generated enable assignments as structured StructuralRTLIR records.`
  Acceptance: `Direct structural_rtl_ir exposes assignment_records[] entries for generated enable assignments while retaining auxiliary_assignments[] as a compatibility mirror and without changing HDL emission.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-DIRECT-STRUCTURAL-ASSIGNMENT-RECORDS.2` | `pending` | The scalar assignment-line mirror exists, but downstream consumers need AST/structural records instead of parsing strings. |

## Decisions

- `2026-06-12`: Keep `auxiliary_assignments[]` as the advertised compatibility
  mirror for this slice, but introduce `assignment_records[]` as the preferred
  machine-readable direct structural surface. Removing or deprecating the
  scalar-string field requires a later compatibility-specific owner.
- `2026-06-12`: Track direct net source/target connectivity and direct HDL
  rerouting through `StructuralRTLIR` as separate proposed R11 task trees, so
  this assignment-record slice stays bounded.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `R11-DIRECT-STRUCTURAL-ASSIGNMENT-RECORDS.1` | `scripts/check_memory_architecture.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `git --no-pager diff --check` | `pass` |
| `2026-06-12` | `R11-DIRECT-STRUCTURAL-ASSIGNMENT-RECORDS.2` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-DIRECT-STRUCTURAL-ASSIGNMENT-RECORDS.1` | `R11-DIRECT-STRUCTURAL-ASSIGNMENT-RECORDS.1: select direct assignment records` | Selected the structural assignment-record scope and proposed separate owners for direct net connectivity and direct HDL rerouting. |
| `R11-DIRECT-STRUCTURAL-ASSIGNMENT-RECORDS.2` | `pending` | `pending` |

## Changelog

- `2026-06-12`: Created task tree, selected the assignment-record scope, and
  proposed separate follow-on task trees for direct net connectivity and direct
  HDL rerouting before implementation leaf `.2`.
