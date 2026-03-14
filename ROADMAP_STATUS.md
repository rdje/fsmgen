# ROADMAP_STATUS
This is the canonical live roadmap status board for FSMGen.
Use it to answer, at any time, what is done, what is left, and which lane is currently active.

## Update rule
- Update this file before every commit if the completed task changes:
  - any workstream status,
  - any workstream deliverables,
  - the `Done` summary,
  - the `Left` summary,
  - or the current active lane.
- Whenever any workstream status or the current active lane changes:
  - refresh this board first,
  - log the change in `CHANGES.md`,
  - and display the current live status snapshot in the user-facing close-out for that task.
- Whenever the commit workflow runs, display the current live status snapshot from this board in the user-facing close-out, even if no status changed.
- Allowed status values are exactly:
  - `done`
  - `mostly done`
  - `in progress`
  - `not started`
- Every workstream must state:
  - `Description`: a brief statement of what the phase does and why it exists,
  - `Deliverables`: the concrete outputs required for the phase to count as complete,
  - `Status`: current achievement level against those deliverables,
  - `Done`: what is already landed,
  - `Left`: what still remains,
  - `Exit criteria`: the completion boundary.
- Every user-facing live-status snapshot derived from this board must show, for each `Rj`:
  - `Status`
  - `Description`
- When a phase has meaningful open sub-steps, the snapshot should also show brief sub-bullets for:
  - the current active lane,
  - any phase whose status changed in the completed task,
  - and any other phase where the next step is important to understand current progress.

## Status scale
- `done`
  - All listed `Deliverables` are complete.
  - `Exit criteria` are met.
  - Only incidental bugfixes or unrelated future reuse may remain.
- `mostly done`
  - Most listed `Deliverables` are complete.
  - Only a bounded finish-up lane remains.
- `in progress`
  - Some listed `Deliverables` are complete.
  - Multiple meaningful slices still remain.
- `not started`
  - The listed `Deliverables` are not yet implemented.
  - Notes or terminology may exist, but they do not count as implementation progress.

## Current active lane
- `R6` Composition-oriented language / architecture work
- Current next decision point:
  - Implement the first typed composition parser/IR slice for `?top:name` contents (`?ports`, `?fsmc`, `?rtl`, `?toplink`) now that source-kind classification is explicit.

## Workstreams
### R0. Live roadmap tracking infrastructure
Description:
- Keep one canonical, explicit live board for roadmap state and make status tracking part of the normal workflow.
Deliverables:
- One canonical tracked board that states live workstream status and the current active lane.
- A fixed four-level status taxonomy used consistently across the project.
- Workflow docs that require refreshing the board during normal task completion and status transitions.
Status: `done`
Done:
- `ROADMAP_STATUS.md` is the canonical live status board.
- `README.md`, `MEMORY.md`, `COMMIT.md`, and `.agents/workflows/commit.md` are wired to this board and its update rule.
Left:
- Keep the board current before every commit when a task changes status, remaining work, or the active lane.
Exit criteria:
- Already met; this is now an ongoing maintenance obligation.

### R1. FlattenedDT dead-surface retirement
Description:
- Remove dead helper/facade surface from the old `FlattenedDT` monolith so the active architecture reflects only supported behavior.
Deliverables:
- Remove dead facade/helper surface from `perl/FSM/HDL/FlattenedDT.pm` and adjacent dead owner-side helper pockets.
- Add regression protection so retired dead surface does not silently reappear.
- Explicitly close the cleanup-only lane unless a future audit finds genuinely dead supported surface.
Status: `done`
Done:
- The cleanup-only lane retired the large dead facade/helper pockets from `perl/FSM/HDL/FlattenedDT.pm` and adjacent dead owner-side pockets.
- `t/10-ast-first-enable-structure.t` locks the absence of the retired helper surface.
Left:
- No planned cleanup-only slices remain.
- Reopen only if a future audit finds new genuinely dead supported surface.
Exit criteria:
- Already met; the dedicated cleanup-only lane is considered exhausted.

### R2. Live ownership migration from `Orchestrator` / backend to `EnableGraph`
Description:
- Move live synthesis-domain ownership out of routing/rendering modules and into `EnableGraph`, so analysis and mutation live with their real owner.
Deliverables:
- `EnableGraph` owns live synthesis-domain capture, enable analysis, declaration planning, and other owner-side mutation of `assignment_analysis` / captured AST structures.
- `Backend::SystemVerilog` and `Orchestrator` retain only traversal, backend-local factorization, runtime AST recovery/filtering, and HDL rendering/orchestration responsibilities.
- Architecture tests lock the live owner boundary for moved entrypoints so ownership regressions are visible.
Status: `done`
Done:
- Per-run generation reset and state/DT enable-registry seeding cleanup.
- Capture registry, capture shape, capture metadata, capture entrypoints, and test-condition AST ownership.
- Top-level enable emission and unified WEN/EN emission.
- Internal declaration planning, module declaration planning, and state register planning.
- WEN/EN prescan and logical-op counting.
- First-pass and second-pass factorization AST feeding, plus second-pass intermediate-signal eligibility checks.
- First-pass and second-pass substitution synchronization, plus the unary-negation debug scan over owner-side AST structures.
- Live-usage evidence and signal-reference inspection for intermediate-signal retention.
- Backend audit now shows no remaining direct `assignment_analysis` / `lhs_assignments` ownership residue in `Backend::SystemVerilog`; the remaining backend pocket is runtime AST recovery/filtering plus emitted-signal ordering.
Left:
- No dedicated `R2` ownership slices remain.
- Reopen only if a future audit finds synthesis/analysis ownership drifting back into `Backend::SystemVerilog` or `Orchestrator`.
Exit criteria:
- Met: the active path no longer has ownership confusion around synthesis analysis versus backend rendering/factorization.

### R3. AST/CoreAST-first runtime convergence
Description:
- Make the active runtime use native AST/CoreAST data by default, and confine legacy string reconstruction to explicit compatibility boundaries only.
Deliverables:
- Live top-level enable/intermediate registries are AST/CoreAST-backed by default.
- Runtime dependency recovery, width recovery, and driving-AST storage prefer native AST/CoreAST sources over string reconstruction.
- Any remaining compatibility fallbacks are narrow, explicit, and justified instead of being the default path.
Status: `done`
Done:
- Top-level enable registries are AST-backed.
- Intermediate-signal registry, dependency recovery, runtime-AST normalization, and driving-AST storage were pushed toward AST/CoreAST-first behavior.
- Compatibility fallback breadth was reduced substantially; unresolved cases are narrower and explicit.
- Render-time late hydration no longer silently promotes `runtime_ast` after an initial `no_ast_source` miss; explicit dependency recovery is now the remaining promotion path in that area.
 - Direct stored-expression parsing was removed from normal runtime-AST resolution, leaving only explicit miss-recovery parsing and the owner-side legacy registry/global-expression compatibility parser as the deliberate final boundary.
Left:
- No dedicated `R3` convergence slices remain.
- Reopen only if a future audit finds runtime behavior drifting back toward implicit string reconstruction instead of explicit compatibility boundaries.
Exit criteria:
- Met: live intermediate-signal/runtime behavior is now AST/CoreAST-first by default, with only deliberate and well-justified explicit compatibility residue remaining.

### R4. Assignment semantics and capture contract modernization
Description:
- Normalize assignment intent/provenance semantics in the parsed/CoreAST model and preserve that meaning all the way through runtime capture and HDL generation.
Deliverables:
- Parsed/CoreAST assignment nodes expose normalized assignment intent, provenance, output-exposure, and pulse metadata.
- Live capture preserves that metadata into runtime capture/analysis structures without lossy translation.
- Regression tests cover representative assignment families and their emitted HDL consequences.
Status: `done`
Done:
- Assignment intent metadata, provenance, and output exposure are explicit in the parsed/CoreAST model.
- Live capture preserves that metadata and the tests lock representative families (`<-`, `<=`, `=`, `<-=`, `<=+`, pulse delay).
Left:
- No dedicated roadmap lane remains here; future work should reuse this model rather than redesign it.
Exit criteria:
- Already met for the current roadmap intent.

### R5. Generator reuse / per-run state safety
Description:
- Guarantee that one generator instance can be reused safely across runs without leaking prior-run state into the next generation.
Deliverables:
- One generator instance can be reused across multiple generations without leaking prior-run registries or scratch state.
- Per-run state is reset deterministically before generation begins.
- Regression coverage proves reuse safety on live generation paths.
Status: `done`
Done:
- Per-run generation state is reset explicitly before each generation.
- Generator reuse is covered by regression tests and no longer leaks prior-run registries into the next run.
Left:
- No dedicated roadmap lane remains here; only regressions/bugfixes if new leaks are discovered.
Exit criteria:
- Already met for the current roadmap intent.

### R6. Composition-oriented language / architecture work
Description:
- Define and implement the composition model for the active tool so larger FSM systems can be expressed in the refactored architecture, not just in notes.
Deliverables:
- Define concrete composition-oriented language/architecture scope for the active tool, not just terminology.
- Define the executable acceptance matrix for the first active composition lane.
- Implement composition capabilities in the active `bin/fsmgen` architecture.
- Add acceptance tests and user/developer documentation for the composition model.
Status: `in progress`
Done:
- Terminology and sequencing were clarified in the docs.
- `docs/COMPOSITION_SCOPE.md` now defines the first concrete active composition scope grounded in the current `bin/fsmgen` / `HDLGenerator` / `FSMGenFull::Parser` architecture.
- The same scope document now defines the first executable acceptance matrix (`C1`..`C6`) and the initial planned test-file split for composition work.
- The active pipeline now classifies top-level source kind explicitly, so `?top:name` is recognized before the FSM-only parser runs.
- Unsupported composition input now fails with a composition-specific boundary diagnostic in both `HDLGenerator` and direct FSM-only parser calls, with focused regression coverage.
Left:
- Implement the actual typed composition parser and IR for `?top:name` contents in the active architecture.
- Add the executable acceptance tests for the scoped composition matrix.
- Extend user/developer docs from scope-plus-boundary detection to shipped composition behavior.
Exit criteria:
- Composition capabilities exist in the active architecture, not just in notes/terminology.

### R7. Extension/plugin redesign replacing legacy `.plg` / `PPlugin`
Description:
- Replace the legacy plugin path with a typed extension mechanism that fits the active architecture and can be tested and documented cleanly.
Deliverables:
- Define the replacement typed hook/extension mechanism for the active architecture.
- Implement that mechanism in the live toolchain.
- Migrate the project off legacy `.plg` / `PPlugin.pm` as the architectural extension path, with tests/docs for the replacement.
Status: `not started`
Done:
- Roadmap direction is explicit: legacy `.plg` / `PPlugin.pm` support is to be retired, not preserved as the future architecture.
Left:
- Define the replacement typed hook/extension mechanism.
- Implement it and migrate off the legacy plugin model.
Exit criteria:
- Legacy plugin support is no longer the architectural extension path and the replacement mechanism is active.
