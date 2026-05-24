# BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING: Backend-Owned Struct/Record Default Lowering

## Metadata

- Tree ID: `BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING`
- Status: `active`
- Roadmap lane: `aggregate types and data`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Determine and implement the safe path, if any, for making backend-owned
structured `struct`/record lowering the default where it is portable,
synthesizable, and already backed by exact aggregate type contracts.

## Non-Goals

- Do not switch every aggregate-like value to structured lowering in one
  slice.
- Do not change VHDL aggregate lowering under this tree.
- Do not infer anonymous record shapes from partial member/index use.
- Do not make backend-owned lowering the default where frontend/type-contract
  evidence is incomplete.
- Do not change public API/type-export surfaces under this tree.

## Acceptance Criteria

- The current structured lowering boundary is audited across direct `.fsm`,
  composition, ISF lowering, generated SystemVerilog, tests, corpus accounting,
  mdBook, and live docs.
- Each behavior-bearing leaf names one bounded lowering surface before code
  changes begin.
- Shipped behavior and remaining deferrals are documented in the mdBook and
  live docs in the same slice as implementation.
- Focused validation covers accepted, rejected, and still-deferred structured
  lowering cases for the changed surface.
- Broader validation runs when a leaf touches shared aggregate type contracts,
  declaration planning, generated ports, or backend emitters.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING`
  Status: `active`
  Goal: `Broaden backend-owned structured aggregate lowering only where exact contracts already exist.`
  Children: `BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING.1`,
    `BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING.2`

- ID: `BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING.1`
  Status: `done`
  Goal: `Select the task tree and establish the first executable frontier.`
  Acceptance: `The active tree, roadmap status, live docs, mdBook backlog owner stance, and README index name this tree, and the next leaf is limited to an audit/design boundary before behavior changes.`
  Verification: `passed: feature-backlog audit, mdBook build, and diff check`
  Commit: `BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING.1: select struct lowering work`

- ID: `BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING.2`
  Status: `pending`
  Goal: `Audit shipped backend-owned struct/record lowering and choose one bounded implementation or close-out surface.`
  Acceptance: `The audit identifies current typedef/declaration emission paths, aggregate contract sources, supported and deferred lowering surfaces, relevant tests/docs/corpus entries, and one bounded next implementation leaf or a documented close-out decision. No behavior changes are made in this audit leaf.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING.2` | `pending` | Backend-owned aggregate typedef emission exists for declared and inferred SystemVerilog aggregate contracts, but the default-lowering boundary must be audited before any broader policy change. |

## Decisions

- `2026-05-24`: The first executable leaf is an audit/design slice, not an
  implementation slice. Default structured lowering can affect declaration
  planning, generated ports, aggregate assignment validation, and backend
  portability, so behavior-bearing work must first identify one exact
  contract-backed surface.

## Open Questions

- Whether any backend-owned lowering default can widen safely beyond existing
  aggregate typedef-backed ports and declarations is the active `.2` audit
  question.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING.1` | `BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING.1: select struct lowering work` | `selection slice` |
| `BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING.2` | `pending` | `audit/design slice` |

## Changelog

- `2026-05-24`: Created active task tree and selected the audit/design
  frontier.
