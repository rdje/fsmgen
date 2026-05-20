# GLOBAL-AST-MANAGER-BOUNDARY: Legacy Global AST Manager Boundary

## Metadata

- Tree ID: `GLOBAL-AST-MANAGER-BOUNDARY`
- Status: `done`
- Roadmap lane: `architecture backlog`
- Created: `2026-05-20`
- Last updated: `2026-05-20`
- Owner: repo-local workflow

## Goal

Resolve the ownership status of `FSM::GlobalASTManager` against the live
SystemVerilog factorization owners without changing generated behavior
accidentally.

## Non-Goals

- Do not replace the live `FSM::HDL::FlattenedDT::Backend::SystemVerilog`
  factorization support in this tree without a separate behavior-selected
  leaf.
- Do not expose `GlobalASTManager` as a public API.
- Do not remove tests or source files until their live/runtime role is proven.

## Acceptance Criteria

- Static and focused runtime evidence establish whether `GlobalASTManager` is
  runtime-owned, test-only compatibility, or dead residue.
- The module header and docs no longer claim broad ownership if the live owner
  is elsewhere.
- Any retirement, shim, or guard change is split into its own leaf.
- Focused validation covers the chosen boundary.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `GLOBAL-AST-MANAGER-BOUNDARY`
  Status: `done`
  Goal: `Classify and resolve GlobalASTManager ownership.`
  Children: `GLOBAL-AST-MANAGER-BOUNDARY.1`,
  `GLOBAL-AST-MANAGER-BOUNDARY.2`

- ID: `GLOBAL-AST-MANAGER-BOUNDARY.1`
  Status: `done`
  Goal: `Prove current runtime reachability and supported boundary.`
  Acceptance: `The task file records imports, direct callers, tests, and
  whether the module is runtime-owned or compatibility-only.`
  Verification: `static reachability audit plus focused owner tests passed`
  Commit: `GLOBAL-AST-MANAGER-BOUNDARY.1: classify GlobalASTManager boundary`

- ID: `GLOBAL-AST-MANAGER-BOUNDARY.2`
  Status: `done`
  Goal: `Implement the selected boundary cleanup or guard.`
  Acceptance: `The selected retirement, shim, or documentation guard is
  implemented with focused validation and no generated behavior drift.`
  Verification: `focused compatibility and live-owner tests passed`
  Commit: `GLOBAL-AST-MANAGER-BOUNDARY.2: correct GlobalASTManager boundary`

## Current Frontier

This tree is closed. `FSM::GlobalASTManager` is documented as legacy
compatibility support for explicitly collected blessed AST objects, not the
live direct-backend factorization owner.

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `GLOBAL-AST-MANAGER-BOUNDARY.1` | `done` | Runtime reachability and compatibility-only status are classified. |
| 2 | `GLOBAL-AST-MANAGER-BOUNDARY.2` | `done` | Corrected stale ownership claims and validated the compatibility boundary. |

## Decisions

- `2026-05-20`: Created from `IR-EXPRESSION-AST-OWNERSHIP.3` because static
  search found no runtime import outside the module itself and compatibility
  tests, while the live backend factorization owner appears to be the
  SystemVerilog backend support family.
- `2026-05-20`: Classified
  [perl/FSM/GlobalASTManager.pm](../../perl/FSM/GlobalASTManager.pm) as
  compatibility-only, not runtime-owned. Production `perl/` and `bin/` code
  do not import it. The live direct SystemVerilog first-pass factorization
  owner is
  [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GlobalFactorizationSupport.pm](../../perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GlobalFactorizationSupport.pm).
- `2026-05-20`: Selected `.2` to correct stale "single authority" module
  wording and guard/document the compatibility boundary rather than remove
  the module immediately. Existing compatibility tests still cover blessed
  `FSM::AST::*` object inputs.
- `2026-05-20`: Corrected
  [perl/FSM/GlobalASTManager.pm](../../perl/FSM/GlobalASTManager.pm) POD and
  comments so the module no longer claims production-wide "single authority"
  ownership. The live runtime owner remains
  `FSM::HDL::FlattenedDT::Backend::SystemVerilog::GlobalFactorizationSupport`.

## Open Questions

- After `.2`, should a later retirement tree remove
  `FSM::GlobalASTManager`, or should it remain as legacy compatibility support
  while old tests still exercise it?

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-20` | `GLOBAL-AST-MANAGER-BOUNDARY.1` | `rg -n -- 'use FSM::GlobalASTManager|FSM::GlobalASTManager->new|GlobalFactorizationSupport' perl t bin`; `perl -Iperl -c perl/FSM/GlobalASTManager.pm`; `prove -Iperl t/542-global-ast-manager-signal-ref-name-compatibility-audit.t t/211-systemverilog-global-factorization-support.t`; `git diff --check`; `mdbook build docs/book` | `passed` |
| `2026-05-20` | `GLOBAL-AST-MANAGER-BOUNDARY.2` | `perl -Iperl -c perl/FSM/GlobalASTManager.pm`; `prove -Iperl t/542-global-ast-manager-signal-ref-name-compatibility-audit.t t/211-systemverilog-global-factorization-support.t`; `git diff --check`; `mdbook build docs/book` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `GLOBAL-AST-MANAGER-BOUNDARY.1` | `GLOBAL-AST-MANAGER-BOUNDARY.1: classify GlobalASTManager boundary` | Classifies the module as compatibility-only and selects wording/guard cleanup. |
| `GLOBAL-AST-MANAGER-BOUNDARY.2` | `GLOBAL-AST-MANAGER-BOUNDARY.2: correct GlobalASTManager boundary` | Corrects stale module ownership wording and closes the tree. |

## Changelog

- `2026-05-20`: Created proposed follow-up task tree from
  `IR-EXPRESSION-AST-OWNERSHIP.3`.
- `2026-05-20`: Activated `.1`, classified the current reachability boundary,
  and advanced `.2` for stale ownership wording/guard cleanup.
- `2026-05-20`: Completed `.2` by correcting module ownership wording and
  closing the tree.

## Reachability And Ownership Audit

`FSM::GlobalASTManager` is not the live direct-backend global factorization
owner today.

| Surface | Evidence | Boundary |
| --- | --- | --- |
| Production imports | Static search finds no `use FSM::GlobalASTManager` or direct `FSM::GlobalASTManager->new` in production `perl/` or `bin/` paths. | Not runtime-owned by production code. |
| Compatibility tests | [t/542-global-ast-manager-signal-ref-name-compatibility-audit.t](../../t/542-global-ast-manager-signal-ref-name-compatibility-audit.t) instantiates the module and proves repeated blessed `FSM::AST::*` object trees can still be structurally analyzed and factored. [t/521-expression-namer-legacy-parse-boundary-audit.t](../../t/521-expression-namer-legacy-parse-boundary-audit.t) now proves unblessed `ExpressionNamer` hash output is ignored by `collect_ast`. | Test-covered compatibility support for blessed legacy AST objects. |
| Live first-pass SystemVerilog factorization | [perl/FSM/HDL/FlattenedDT.pm](../../perl/FSM/HDL/FlattenedDT.pm) constructs `backend_sv_global_factorization` from [GlobalFactorizationSupport.pm](../../perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GlobalFactorizationSupport.pm). `ASTFactorizationSupport` and `ConsolidatedIntermediateSupport` delegate to that backend owner. | Runtime owner is the SystemVerilog backend support family, not `FSM::GlobalASTManager`. |
| String parse collection path | `GlobalASTManager::collect_all_asts_from_design` parses strings through `expr_namer->parse_expression(...)`, but `collect_ast` accepts only blessed AST objects. Current `ExpressionNamer` returns unblessed legacy hash ASTs for strings. | Existing string-parse collection path is a no-op for current `ExpressionNamer` hash output. |

## Selected `.2` Boundary

`GLOBAL-AST-MANAGER-BOUNDARY.2` should keep behavior stable and correct the
stale ownership story:

- Update `perl/FSM/GlobalASTManager.pm` documentation/header comments so it no
  longer claims to be the single live authority for all AST analysis and
  naming in the design.
- State that the module is legacy compatibility support for blessed
  `FSM::AST::*` object trees.
- Keep the production runtime owner as
  `FSM::HDL::FlattenedDT::Backend::SystemVerilog::GlobalFactorizationSupport`.
- Preserve the existing compatibility test and add/update focused evidence if
  the source wording changes.
