# DOCTRINE-ENFORCEMENT-ADOPTION: Adopt Mechanical Doctrine Enforcement And Toolbox Catalog

## Metadata

- Tree ID: `DOCTRINE-ENFORCEMENT-ADOPTION`
- Status: `active`
- Roadmap lane: `infra/continuity/doctrine enforcement`
- Created: `2026-06-22`
- Last updated: `2026-06-22`
- Owner: repo-local workflow

## Goal

Adopt the portable doctrine-enforcement architecture from the sibling PGEN
checkout's `DOCTRINE_ENFORCEMENT.md` into FSMGEN and add an FSMGEN-specific
`TOOLBOX.md` that catalogues the tools used to
pinpoint issues, including trace, schedule JSON, semantic JSON, support
accounting, HDL validation, mdBook, Knowledge Map, and memory/doctrine gates.

## Non-Goals

- Do not change parser, generator, scheduler, backend, HDL, PPIF, or runtime
  behavior in the adoption leaf unless a later exact owner is selected.
- Do not copy PGEN-specific Rust binaries, grammar commands, or certificate
  gates as if they were FSMGEN gates; translate only the portable doctrine
  model and write FSMGEN-native toolbox entries.
- Do not weaken the existing task-tree, memory-architecture, Knowledge Map,
  commit-message, or mdBook gates.

## Acceptance Criteria

- `DOCTRINE_ENFORCEMENT.md` exists at the FSMGEN repo root or an explicitly
  documented FSMGEN location and states the portable doctrine-enforcement
  standard as applied to this project.
- `TOOLBOX.md` exists at the FSMGEN repo root and lists the FSMGEN tools to
  use first when diagnosing parser, lowering, scheduler, PPIF, HDL, docs,
  memory, support-accounting, and task-tree issues, with exact commands and
  expected signals.
- Existing bootstrap docs point to README, `MEMORY_ARCHITECTURE.md`,
  `DOCTRINE_ENFORCEMENT.md`, and `TOOLBOX.md` where appropriate.
- Any check-driver or hook changes are explicit, deterministic, and compatible
  with existing `scripts/check_memory_architecture.sh`,
  `knowledge-map/scripts/check_knowledge_map.sh`, mdBook, and commit workflow
  gates.
- README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map are updated
  for the adoption.
- Focused validation and continuity gates pass, including the existing memory
  architecture gate.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `DOCTRINE-ENFORCEMENT-ADOPTION`
  Status: `active`
  Goal: `Adopt doctrine-enforcement architecture and an FSMGEN toolbox catalog.`
  Children: `DOCTRINE-ENFORCEMENT-ADOPTION.1`

- ID: `DOCTRINE-ENFORCEMENT-ADOPTION.1`
  Status: `pending`
  Goal: `Adopt the PGEN doctrine-enforcement standard and create the FSMGEN toolbox catalog.`
  Acceptance: `Read the sibling PGEN checkout's DOCTRINE_ENFORCEMENT.md and TOOLBOX.md; write the FSMGEN DOCTRINE_ENFORCEMENT.md adoption using portable doctrine-check, registry/driver, hook, and CI concepts; create TOOLBOX.md with FSMGEN-native diagnostic commands such as --debug/--trace-verbosity/--trace-log, --emit-schedule-json, --check --json, --emit-semantic-json, --verify-hdl, support-accounting tests, mdBook build, Knowledge Map generation/checks, docs relative-path audit, memory architecture gate, and git/diff hygiene; update bootstrap pointers, README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map; add focused docs/gate validation; do not change parser/generator/HDL behavior without a later exact owner.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `DOCTRINE-ENFORCEMENT-ADOPTION.1` | `pending` | User requested adoption of the PGEN doctrine-enforcement system and an FSMGEN issue-pinpointing toolbox after the in-flight `.223` slice completes. |

## Decisions

- `2026-06-22`: The adoption leaf will translate the portable doctrine model
  from PGEN but write FSMGEN-native toolbox commands; PGEN-specific grammar
  and Rust certificate commands are evidence for structure, not FSMGEN tools.

## Open Questions

- Whether FSMGEN already has enough doctrine checks for a general
  `scripts/check_doctrines.sh` driver in the first adoption slice, or whether
  `.1` should land documentation plus a check-driver selector before hook/CI
  wiring. This does not block reading and documenting the adoption source.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-22` | `DOCTRINE-ENFORCEMENT-ADOPTION.1` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `DOCTRINE-ENFORCEMENT-ADOPTION.1` | `pending` | `pending` |

## Changelog

- `2026-06-22`: Created task tree for the requested doctrine-enforcement and
  toolbox adoption work.
