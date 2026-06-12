# IAL2-PROFILE-EXTENSION-REFINEMENT-CAPTURE: IAL2 Profile Extension Refinement Capture

## Metadata

- Tree ID: `IAL2-PROFILE-EXTENSION-REFINEMENT-CAPTURE`
- Status: `done`
- Roadmap lane: `IAL2 horizon exploration`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Capture the refined IAL2 file-surface model: protocol/platform-generic
containers remain valid, and protocol-specific extensions may later exist as
vocabulary/profile entrypoints over the same IAL2 layer.

## Non-Goals

- Do not implement any IAL2 parser, extension dispatch, profile selection,
  lowering, `.isf`, `.fsm`, HDL, tests, or generated artifacts.
- Do not finalize the exact generic extension spelling.
- Do not approve any specific protocol profile extension yet.
- Do not weaken the mandatory `IAL2 -> IAL1 -> IAL0` lowering invariant.

## Acceptance Criteria

- A new decision record refines decision `0014`: protocol-specific extensions
  are not the architectural layer boundary, but may later be accepted as
  vocabulary/profile aliases over the generic IAL2 model.
- The decision preserves the required `IAL2 -> IAL1/.isf -> IAL0/.fsm -> HDL`
  lowering chain.
- The IAL2 evaluation, AXI manager API brainstorm, mdBook backlog, task tree,
  Knowledge Map, README, and memory are synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `IAL2-PROFILE-EXTENSION-REFINEMENT-CAPTURE`
  Status: `done`
  Goal: `Persist the refined IAL2 generic-container plus protocol-profile extension model.`
  Children: `IAL2-PROFILE-EXTENSION-REFINEMENT-CAPTURE.1`

- ID: `IAL2-PROFILE-EXTENSION-REFINEMENT-CAPTURE.1`
  Status: `done`
  Goal: `Capture protocol-specific extensions as possible IAL2 vocabulary/profile aliases.`
  Acceptance: `Record that .axi/.chi/.ace/.ahb/.apb/.atb-style extensions may be accepted later as profile aliases, not separate semantic layers or direct-lowering paths; preserve generic .pif/.ppi/.ppif candidates and the layered lowering invariant.`
  Verification: `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `scripts/check_memory_architecture.sh`; `knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check`
  Commit: `IAL2-PROFILE-EXTENSION-REFINEMENT-CAPTURE.1: allow IAL2 profile extension aliases`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `IAL2-PROFILE-EXTENSION-REFINEMENT-CAPTURE.1` | `done` | The profile-extension refinement is captured as a durable decision. |

## Decisions

- `2026-06-12`: Capture this as a refinement to `0014`, not as an
  implementation selection.
- `2026-06-12`: Protocol-specific extensions may later exist as
  vocabulary/profile aliases over the same IAL2 layer, while generic
  `.pif`/`.ppi`/`.ppif` container candidates remain valid.

## Open Questions

- Exact generic extension spelling remains open.
- Exact protocol-profile extension set and dispatch syntax remain open.
- Whether profile aliases are separate file extensions, declared profiles
  inside a generic file, or both remains future design work.

## Blockers

- None for decision capture. Future implementation needs a new exact
  task-tree owner.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `.1` | `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `scripts/check_memory_architecture.sh`; `knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check` | pass |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `IAL2-PROFILE-EXTENSION-REFINEMENT-CAPTURE.1: allow IAL2 profile extension aliases` | Records protocol-profile extensions as vocabulary aliases, not separate layers. |

## Changelog

- `2026-06-12`: Created active task tree for IAL2 profile-extension
  refinement capture.
- `2026-06-12`: Added decision `0015`, synchronized IAL2/AXI/mdBook/README
  surfaces, added a Knowledge Map signpost, and preserved no-implementation
  status.
