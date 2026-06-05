# COMPOSITION-TYPE-BACKLOG-EXHAUSTION: Composition And Type Backlog Exhaustion

## Metadata

- Tree ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION`
- Status: `active`
- Roadmap lane: `Composition` / `Aggregate Types And Data`
- Created: `2026-06-05`
- Last updated: `2026-06-05`
- Owner: repo-local workflow

## Goal

Exhaust the combined Composition/type backlog by selecting and completing
bounded, reviewable leaves until no executable Composition/type backlog item
remains or a real prerequisite blocker is reached.

## Non-Goals

- Do not treat this broad tree as permission to change behavior without a
  selected executable leaf.
- Do not widen public composition, type, aggregate, or VHDL contracts without
  synchronized mdBook/public documentation and focused regression coverage.
- Do not bypass the existing R11/R14 audit evidence; use it as the starting
  boundary for each selected leaf.

## Acceptance Criteria

- Every Composition/type backlog item named in the remaining-work inventory is
  represented as a leaf or explicit deferral/blocker.
- The current frontier always points to one executable next leaf.
- Each behavior-bearing leaf updates source, tests, public docs/mdBook, and
  downstream-visible contracts as warranted.
- Focused validation passes for each leaf; broader gates run when the blast
  radius warrants them.
- Each completed leaf is committed through `COMMIT.md` before selecting the
  next one.

## Task Tree

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION`
  Status: `active`
  Goal: `Exhaust the Composition/type backlog through bounded task-scoped leaves.`
  Children: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.1`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.2`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.3`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.4`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.5`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.6`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.7`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.8`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.9`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.10`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.11`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.12`,
    `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.13`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.1`
  Status: `done`
  Goal: `Activate the Composition/type backlog tree and inventory the named leaves.`
  Acceptance: `The tree exists, is active in docs/TASK_TREE.md, and lists every Composition/type item from the remaining-work inventory.`
  Verification: `passed: memory architecture, mdBook, feature-backlog status, doc path, knowledge-map, and diff checks`
  Commit: `PROJECT-REMAINING-WORK-TASKTREE-OWNERSHIP.1: track remaining backlog owners`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.2`
  Status: `done`
  Goal: `Select the first executable Composition/type implementation or deferral leaf from evidence.`
  Acceptance: `Existing R11/R14 audit evidence and the mdBook backlog are reviewed, one bounded next behavior/doc/test slice is selected, and the selected leaf is either made executable in this tree or explicitly deferred with a prerequisite.`
  Verification: `passed: memory architecture, mdBook, feature-backlog status, doc path, knowledge-map, and diff checks`
  Commit: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.2: select aggregate equality leaf`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.3`
  Status: `done`
  Goal: `Select the next shared-datapath route/storage/protocol contract or blocker from evidence.`
  Acceptance: `Existing R11 shared-datapath evidence, mdBook text, and regression coverage are reviewed; one exact executable leaf is added or activated, or the backlog item is explicitly deferred with a prerequisite. No code/test/source change may occur under this leaf unless that exact executable owner exists first.`
  Verification: `passed: focused shared-datapath evidence, memory architecture, mdBook, feature-backlog status, doc path, knowledge-map, and diff checks`
  Commit: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.3: defer shared-datapath widening`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.4`
  Status: `pending`
  Goal: `Select the next reusable standalone-DT module interface/export or lookup contract or blocker from evidence.`
  Acceptance: `Existing reusable standalone-DT/module evidence, mdBook text, and regression coverage are reviewed; one exact executable leaf is added or activated, or the backlog item is explicitly deferred with a prerequisite. No code/test/source change may occur under this leaf unless that exact executable owner exists first.`
  Verification: `pending`
  Commit: `pending`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.5`
  Status: `pending`
  Goal: `Evaluate top-boundary convention widening and hidden child-to-child/public re-export policy.`
  Acceptance: `One exact convention widening, re-export, conflict, interface-bundle, or protocol-group rule is selected, implemented or explicitly deferred, documented, and regression-covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.6`
  Status: `pending`
  Goal: `Broaden generated-child top instantiation beyond the shipped spawn and parameterized blocking-do patterns.`
  Acceptance: `One exact generated-child top surface is selected, implemented or explicitly deferred, documented, and regression-covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.7`
  Status: `pending`
  Goal: `Broaden spawn/blocking-do parameter and value binding surfaces.`
  Acceptance: `One exact static value, parameter, binding, package, aggregate, or specialization rule is selected, implemented or explicitly deferred, documented, and regression-covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.8`
  Status: `pending`
  Goal: `Close remaining repeat-body child-activation variants that intersect Composition/type behavior.`
  Acceptance: `One exact undrained, multi-pending, cross-domain, nested, or binding-related repeat-body child-activation variant is selected, implemented or explicitly deferred, documented, and regression-covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.9`
  Status: `pending`
  Goal: `Select and implement or defer the next portable type-core contract.`
  Acceptance: `One exact enum-as-type, fixed-array, array-of-record, signedness/state-model, inference, or backend-neutral type contract is selected, implemented or explicitly deferred, documented, and regression-covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.10`
  Status: `pending`
  Goal: `Broaden aggregate member/index autogrowth from partial use.`
  Acceptance: `One exact member/index autogrowth proof surface is selected, implemented or explicitly deferred, documented, and regression-covered.`
  Verification: `pending`
  Commit: `pending`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.11`
  Status: `done`
  Goal: `Implement binary semantic parameter/generic aggregate equality and inequality.`
  Acceptance: `Direct +params, .rtlif defaults, external RTL overrides, and generated-child overrides accept binary (== A B) and (!= A B) only when both operands resolve to aggregate values with matching shape. The operators fold before HDL lowering to exact-width scalar literals 1'b1 or 1'b0. Bad arity, mixed scalar/aggregate operands, mismatched shapes, runtime direct .fsm aggregate expressions, ISF runtime aggregate expressions, VHDL aggregate lowering, scalar/aggregate mixing, and mismatched-shape operators remain fail-closed or deferred.`
  Verification: `passed: focused language/composition/corpus checks, mdBook, feature-backlog status, doc path, knowledge-map, memory-architecture, and diff checks`
  Commit: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.11: implement aggregate comparison operators`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.12`
  Status: `pending`
  Goal: `Broaden backend-owned struct/record default lowering policy.`
  Acceptance: `One exact aggregate-like value class is selected for backend-owned lowering or explicit fail-closed deferral, with docs and regression coverage.`
  Verification: `pending`
  Commit: `pending`

- ID: `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.13`
  Status: `pending`
  Goal: `Track VHDL aggregate lowering and VHDL generic-map lowering prerequisites.`
  Acceptance: `The VHDL-backed Composition/type work is either activated under a VHDL backend owner or explicitly blocked behind that prerequisite with the book and task tree synchronized.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.4` | `pending` | Shared-datapath widening is explicitly deferred behind a precise route/storage/protocol or adjacent prerequisite; the next Composition/type item needs reusable standalone-DT evidence selection before any code. |

## Selection Result

`COMPOSITION-TYPE-BACKLOG-EXHAUSTION.2` selected
`COMPOSITION-TYPE-BACKLOG-EXHAUSTION.11` as the first executable
Composition/type implementation leaf.

The selected slice is intentionally narrow:

- It stays in `FSM::ParameterValueSupport`, the existing fold-before-HDL
  normalizer for semantic parameter/generic aggregate values.
- It applies only to direct `+params`, `.rtlif` defaults, external RTL
  parameter/generic overrides, and generated-child parameter overrides after
  those values resolve to semantic payloads.
- It adds only binary `(== A B)` and `(!= A B)` for matching aggregate
  shapes, returning one scalar exact-width literal.
- It does not add runtime direct `.fsm` aggregate operators, ISF runtime
  aggregate operators, mixed scalar/aggregate operators, mismatched-shape
  operators, VHDL aggregate lowering, or backend-rendered aggregate operators.

Other candidates remain deferred for now:

- VHDL aggregate and generic-map lowering are still blocked by the full VHDL
  backend/composition target prerequisite.
- Member/index-root autogrowth remains unsafe without a complete root-shape
  proof source.
- Shared-datapath, reusable-module, top-boundary, generated-child top, and
  parameter-binding broadenings still need a more specific route/storage,
  reusable-module, convention, or activation contract before code.

## Implementation Result

`COMPOSITION-TYPE-BACKLOG-EXHAUSTION.11` shipped binary semantic
parameter/generic aggregate comparison:

- `(== A B)` and `(!= A B)` are accepted by the existing
  `FSM::ParameterValueSupport` fold-before-HDL normalizer when both operands
  resolve to matching list/record aggregate shapes.
- The result folds to scalar exact-width `1'b1` or `1'b0`.
- The supported surfaces are direct `+params`, `.rtlif` parameter/generic
  defaults, external RTL parameter/generic overrides, and generated-child
  parameter overrides.
- Bad arity, scalar/aggregate mixing, mismatched shapes, runtime aggregate
  expressions, ISF runtime aggregate expressions, and VHDL aggregate lowering
  remain fail-closed or deferred.
- The user-facing contract is documented in `docs/book/` and indexed by
  `docs/knowledge/aggregate-parameter-comparison.md`.

## Shared-Datapath Selection Result

`COMPOSITION-TYPE-BACKLOG-EXHAUSTION.3` reviewed the closed
`R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT`, the current mdBook boundary,
and the focused shared-datapath regression suite.

No new shared-datapath implementation leaf is selected from this tree. The
existing shipped contract already covers the bounded same-name generated-FSM
output family surface, candidate metadata, helper wiring, guard assertions,
registered lifted runtimes, combinational lifted carriers, public/internal
visibility cases, typed contributor compatibility, CLI summaries, and
forward-IR exports.

The remaining shared-datapath backlog stays deferred until an exact
route/storage/protocol, reusable-module, portable-type, VHDL/backend, or
architecture prerequisite is explicit. Deferred items include arbitrary route
mux/storage, general fan-in/fan-out protocols, ready/backpressure, payload
protocols, dynamic scheduling, external-RTL or standalone-DT contributors,
mixed registered/combinational runtime lifting, and broader shared-data
movement.

## Evidence To Reuse

- `R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT`
- `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT`
- `R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT`
- `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT`
- `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT`
- `R11-PARAMETER-GENERIC-FRONTIER-AUDIT`
- `AGGREGATE-AUTOGROWTH-FROM-USAGE`
- `BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING`
- `RICHER-AGGREGATE-OPERATORS`
- `ISF-SPAWN-IN-REPEAT` and later repeat-body child-activation trees

## Decisions

- `2026-06-05`: Activate this tree as the user-selected focus after the
  remaining-work inventory. It owns the combined Composition/type bullet until
  exhaustion.
- `2026-06-05`: Start with an evidence-led selection leaf because the shipped
  R11 audit trees explicitly deferred new implementation until a precise
  route/storage/protocol, reusable-module, portable-type, VHDL, or architecture
  contract is selected.
- `2026-06-05`: Select binary semantic parameter/generic aggregate equality
  and inequality as the first code-bearing leaf. This is the smallest
  non-blocked Composition/type widening found in the evidence sweep: it uses
  the existing aggregate value normalizer, has a precise type/shape/result
  contract, and avoids VHDL/runtime aggregate-expression blockers.
- `2026-06-05`: Do not select a new shared-datapath implementation leaf from
  `.3`. The R11 audit, book boundary, and focused regressions already cover
  the bounded shipped surface; broader work remains blocked until one exact
  route/storage/protocol or adjacent prerequisite is selected.

## Open Questions

- None before the next evidence-selection leaf. Any reusable standalone-DT
  code must first get an exact executable owner under this tree.

## Blockers

- VHDL aggregate and generic-map lowering remain blocked until the full VHDL
  backend/composition target is active enough to validate generated behavior.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- |
| `2026-06-05` | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.1` | `scripts/check_memory_architecture.sh`; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check` | `passed` |
| `2026-06-05` | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.2` | `scripts/check_memory_architecture.sh`; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check` | `passed` |
| `2026-06-05` | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.11` | `prove -Iperl t/30-language-contract-symbol-definitions.t t/51-language-contract-symbol-definition-boundary.t t/88-rtlif-typed-port-contract.t t/91-composition-multi-rtl-children.t t/248-regression-corpus-accounting.t t/261-regression-corpus-supported-language-features.t t/292-composition-generated-child-parameter-overrides.t`; `scripts/check_memory_architecture.sh`; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check` | `passed` |
| `2026-06-05` | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.3` | `prove -Iperl t/139-composition-shared-datapath-candidate-metadata.t t/140-composition-shared-datapath-drive-intent-metadata.t t/141-composition-shared-datapath-aggregate-enable-metadata.t t/142-composition-shared-datapath-assertion-metadata.t t/143-composition-shared-datapath-visibility-metadata.t t/144-composition-shared-datapath-combinational-peer-read-policy.t t/145-composition-shared-datapath-runtime-hdl.t t/146-composition-shared-datapath-lifted-register-runtime.t t/147-composition-shared-datapath-internal-lifted-register-runtime.t t/148-composition-shared-datapath-mixed-reexport-runtime.t t/149-composition-shared-datapath-combinational-runtime.t t/150-composition-shared-datapath-combinational-internal-runtime.t t/151-composition-shared-datapath-assertion-runtime-hdl.t t/152-composition-shared-datapath-public-fanout-register-runtime.t t/153-composition-shared-datapath-combinational-public-fanout-runtime.t t/159-composition-shared-datapath-forward-ir-exports.t t/178-composition-shared-datapath-support.t t/183-composition-shared-datapath-candidate-builder.t`; `scripts/check_memory_architecture.sh`; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.1` | `PROJECT-REMAINING-WORK-TASKTREE-OWNERSHIP.1: track remaining backlog owners` | `activated by the remaining-work ownership slice` |
| `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.2` | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.2: select aggregate equality leaf` | `selected .11 as the first executable Composition/type implementation leaf` |
| `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.11` | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.11: implement aggregate comparison operators` | `shipped binary matching-shape aggregate equality/inequality for semantic parameter/generic values; next frontier .3` |
| `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.3` | `COMPOSITION-TYPE-BACKLOG-EXHAUSTION.3: defer shared-datapath widening` | `closed shared-datapath selection as prerequisite-bound deferral; next frontier .4` |

## Changelog

- `2026-06-05`: Created active Composition/type backlog exhaustion tree.
- `2026-06-05`: Selected binary semantic parameter/generic aggregate equality
  and inequality as the first executable Composition/type implementation leaf.
- `2026-06-05`: Shipped binary semantic parameter/generic aggregate equality
  and inequality and advanced the frontier to shared-datapath evidence
  selection.
- `2026-06-05`: Closed shared-datapath selection as an explicit prerequisite
  deferral and advanced the frontier to reusable standalone-DT evidence
  selection.
