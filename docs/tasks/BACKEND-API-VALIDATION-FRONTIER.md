# BACKEND-API-VALIDATION-FRONTIER: Backend, Validation, And Public API Frontier

## Metadata

- Tree ID: `BACKEND-API-VALIDATION-FRONTIER`
- Status: `active`
- Roadmap lane: `Backends And Validation` / `Embedding And Public APIs`
- Created: `2026-06-05`
- Last updated: `2026-06-05`
- Owner: repo-local workflow

## Goal

Own the backend, external-validation, embedding, and public-export backlog
items named in the 2026-06-05 remaining-work inventory.

## Non-Goals

- Do not implement backend or API behavior without an active exact child leaf.
- Do not claim VHDL, GHDL, ABC, structured generation, or embedding API
  behavior as shipped without matching code, tests, and mdBook coverage.
- Do not leak unstable internal objects as public API surfaces.

## Acceptance Criteria

- Each backend/API backlog item has a leaf-level owner.
- When selected, the tree activates one executable leaf at a time.
- Public docs/mdBook and API contracts are synchronized for every shipped
  behavior.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `BACKEND-API-VALIDATION-FRONTIER`
  Status: `active`
  Goal: `Track backend, validation, embedding, and public API backlog directions.`
  Children: `BACKEND-API-VALIDATION-FRONTIER.1`,
    `BACKEND-API-VALIDATION-FRONTIER.2`,
    `BACKEND-API-VALIDATION-FRONTIER.2.1`,
    `BACKEND-API-VALIDATION-FRONTIER.3`,
    `BACKEND-API-VALIDATION-FRONTIER.4`,
    `BACKEND-API-VALIDATION-FRONTIER.5`,
    `BACKEND-API-VALIDATION-FRONTIER.6`,
    `BACKEND-API-VALIDATION-FRONTIER.7`,
    `BACKEND-API-VALIDATION-FRONTIER.8`

- ID: `BACKEND-API-VALIDATION-FRONTIER.1`
  Status: `done`
  Goal: `Select the next executable backend/API leaf from evidence.`
  Acceptance: `Activated the backend/API frontier after the broad ISF/R14 frontier exhausted and selected BACKEND-API-VALIDATION-FRONTIER.2.1, the first scoped direct-root VHDL backend scaffold leaf.`
  Verification: `Selection audit/read: docs/TASK_TREE.md, docs/book/src/14-feature-backlog.md Backends And Validation section, docs/VHDL_SCOPE.md, docs/tasks/COMPOSITION-TYPE-BACKLOG-EXHAUSTION.md VHDL prerequisite result, README.md backend/API pointers, perl/FSM/HDL/FlattenedDT.pm generate_vhdl not-implemented boundary, perl/FSM/HDL/FlattenedDT/Backend/Verilog.pm conversion pattern, t/386-hdl-generator-facade-target-language-boundary-audit.t, and t/114-composition-target-support-diagnostics.t. Evidence shows VHDL is the first listed backend/API backlog item, unblocks GHDL/composition VHDL work, and has a narrow direct-root SV-first conversion plan while composition VHDL remains fail-closed.`
  Commit: `this slice`

- ID: `BACKEND-API-VALIDATION-FRONTIER.2`
  Status: `active`
  Goal: `Implement or explicitly scope the full VHDL backend frontier.`
  Children: `BACKEND-API-VALIDATION-FRONTIER.2.1`
  Acceptance: `One exact VHDL backend surface is selected, implemented or blocked, documented, and regression-covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `BACKEND-API-VALIDATION-FRONTIER.2.1`
  Status: `pending`
  Goal: `Implement the first direct-root VHDL backend scaffold through an SV-first converter module.`
  Acceptance: `perl/FSM/HDL/FlattenedDT.pm routes direct single-FSM VHDL generation through a dedicated VHDL backend/converter instead of the blanket not-implemented die for accepted direct roots. The first accepted fixture covers a small direct FSM/DT surface with clock/reset, scalar/vector ports, state progression, and basic assignments, emitting deterministic VHDL text through the existing pipeline/CLI target path. Composition/top VHDL, GHDL validation, packages, multi-clock domains, aggregate VHDL, and full feature parity remain fail-closed or deferred with existing diagnostics. Focused tests, docs/mdBook, capability/API surfaces, and required gates pass.`
  Verification: `pending`
  Commit: `pending`

- ID: `BACKEND-API-VALIDATION-FRONTIER.3`
  Status: `pending`
  Goal: `Add GHDL validation once VHDL lowering has an executable subset.`
  Acceptance: `A runnable GHDL validation subset exists or remains blocked behind VHDL backend support.`
  Verification: `pending`
  Commit: `pending`

- ID: `BACKEND-API-VALIDATION-FRONTIER.4`
  Status: `pending`
  Goal: `Drive warning-clean external validation across historical samples.`
  Acceptance: `One exact historical sample family or tool gate is selected, cleaned or deferred, documented, and covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `BACKEND-API-VALIDATION-FRONTIER.5`
  Status: `pending`
  Goal: `Harden ABC mapping behavior.`
  Acceptance: `One exact ABC mapping edge is selected, implemented or deferred, documented, and covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `BACKEND-API-VALIDATION-FRONTIER.6`
  Status: `pending`
  Goal: `Broaden structured non-flattened generation.`
  Acceptance: `One exact non-flattened generation surface is selected, implemented or deferred, documented, and covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `BACKEND-API-VALIDATION-FRONTIER.7`
  Status: `pending`
  Goal: `Freeze the next programmatic embedding API surface.`
  Acceptance: `One exact embedding API surface is specified, implemented or deferred, documented, and regression-covered without exporting unstable internals.`
  Verification: `pending`
  Commit: `pending`

- ID: `BACKEND-API-VALIDATION-FRONTIER.8`
  Status: `pending`
  Goal: `Broaden normalized semantic export.`
  Acceptance: `One exact normalized export field family is specified, implemented or deferred, documented, and regression-covered.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `BACKEND-API-VALIDATION-FRONTIER.1` | `done` | Backend/API tree activated after broad ISF/R14 exhaustion; selected first exact VHDL direct-root scaffold leaf. |
| 2 | `BACKEND-API-VALIDATION-FRONTIER.2.1` | `pending` | First executable backend/API leaf: direct single-FSM VHDL scaffold through an SV-first converter, preserving composition/GHDL/full-parity deferrals. |

## Decisions

- `2026-06-05`: Activated after `ISF-REMAINING-BROAD-FRONTIER` exhausted. Select
  VHDL as the first backend/API lane because it is first in the book backlog,
  unblocks GHDL and VHDL composition work, and `docs/VHDL_SCOPE.md` already
  defines a narrow direct-root SV-first conversion scaffold.

## Open Questions

- None.

## Blockers

- VHDL-dependent leaves remain blocked until an executable VHDL backend subset
  is selected.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- |
| `2026-06-05` | `BACKEND-API-VALIDATION-FRONTIER.1` | Selection audit/read: `docs/TASK_TREE.md`, `docs/book/src/14-feature-backlog.md`, `docs/VHDL_SCOPE.md`, `docs/tasks/COMPOSITION-TYPE-BACKLOG-EXHAUSTION.md`, `README.md`, `perl/FSM/HDL/FlattenedDT.pm`, `perl/FSM/HDL/FlattenedDT/Backend/Verilog.pm`, `t/386-hdl-generator-facade-target-language-boundary-audit.t`, and `t/114-composition-target-support-diagnostics.t`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `mdbook build docs/book`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `BACKEND-API-VALIDATION-FRONTIER.1` | `BACKEND-API-VALIDATION-FRONTIER.1: select VHDL direct scaffold` | this slice |

## Changelog

- `2026-06-05`: Created proposed backend/API frontier owner tree.
- `2026-06-05`: Activated the tree and selected `.2.1`, the first direct-root
  VHDL backend scaffold through an SV-first converter, before backend code
  changes.
