# BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING: Backend-Owned Struct/Record Default Lowering

## Metadata

- Tree ID: `BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING`
- Status: `done`
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
  Status: `done`
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
  Status: `done`
  Goal: `Audit shipped backend-owned struct/record lowering and choose one bounded implementation or close-out surface.`
  Acceptance: `The audit identifies current typedef/declaration emission paths, aggregate contract sources, supported and deferred lowering surfaces, relevant tests/docs/corpus entries, and one bounded next implementation leaf or a documented close-out decision. No behavior changes are made in this audit leaf.`
  Verification: `passed: focused aggregate typedef/ISF boundary tests, feature-backlog audit, mdBook build, and diff check`
  Commit: `BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING.2: close struct lowering audit`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | The audited exact-contract Verilog-family surfaces already lower through backend-owned packed typedefs; broader default lowering needs future behavior-specific task trees. |

## Decisions

- `2026-05-24`: The first executable leaf is an audit/design slice, not an
  implementation slice. Default structured lowering can affect declaration
  planning, generated ports, aggregate assignment validation, and backend
  portability, so behavior-bearing work must first identify one exact
  contract-backed surface.
- `2026-05-24`: The audit closed the tree without a behavior change. The
  shipped backend-owned lowering already covers the exact Verilog-family
  aggregate declaration entries found in current direct generated modules,
  direct internal/helper declarations, structural composition ports/nets, and
  contract-backed inferred direct targets. Widening "default lowering" beyond
  those entries would require a future leaf with a specific proof source,
  because the backend must not invent a struct/record from partial use,
  width-only evidence, or a target family without a synthesizable lowering
  contract.

## Audit Result

Current backend-owned structured lowering is centralized in
`FSM::Backend::VerilogFamily::TypeDeclarationSupport`. The helper collects
entries that preserve both `declared_type_name` and aggregate
`declared_type_spec`, emits local `typedef struct packed` declarations, and
returns a lookup used by Verilog-family declaration renderers.

Supported audited surfaces:

- Direct generated-module SystemVerilog ports from the scaffold/module
  declaration plan.
- Direct generated-module internal signal and mux-helper declarations from
  the enable-graph internal declaration plan.
- Structural RTL IR SystemVerilog ports and nets, including composition-top
  aggregate ports, typed carrier nets, and projected child aggregate carriers.
- Direct `.fsm` aggregate aliases and the bounded inferred target contracts
  produced by whole aggregate constant roots or list-only RHS concat
  autogrowth.
- ISF actor-owned aggregate storage variables after scheduled `.fsm` lowering,
  because the scheduled output preserves the aggregate type alias for the
  direct `.fsm` backend.

Still-deferred surfaces:

- VHDL aggregate lowering.
- ISF aggregate aliases on interface ports, transaction ports, and banks.
- Backend-owned struct creation from partial member/index use, width-only
  matches, or anonymous record/list guesses.
- Public type/export API stabilization beyond the existing bounded contracts.
- Any broader "default for every aggregate-like value" policy not backed by a
  complete compile-time aggregate type contract.

## Open Questions

- None for this tree. Future widening must create a new task tree or leaf for
  one concrete surface before code changes begin.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |
| `2026-05-24` | `BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING.2` | `prove -Iperl t/198-systemverilog-scaffold-emitter.t t/204-enable-graph-module-planning-support.t t/280-declarative-aggregate-types.t t/167-structural-connection-expr-helpers.t t/282-composition-aggregate-source-expression-contracts.t t/1259-isf-aggregate-storage-type-aliases.t t/1321-direct-aggregate-autogrowth.t`; `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: focused tests Files=7, Tests=45; feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING.1` | `BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING.1: select struct lowering work` | `selection slice` |
| `BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING.2` | `BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING.2: close struct lowering audit` | `audit/design close-out slice` |

## Changelog

- `2026-05-24`: Created active task tree and selected the audit/design
  frontier.
- `2026-05-24`: Closed the audit tree after confirming that exact-contract
  Verilog-family surfaces already use backend-owned packed typedef lowering;
  broader default lowering remains future task-tree work.
