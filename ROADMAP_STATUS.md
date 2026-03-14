# ROADMAP_STATUS
This is the canonical live roadmap status board for FSMGen.
Use it to answer, at any time, what is done, what is left, and which lane is currently active.

## Update rule
- Update this file before every commit if the completed task changes:
  - any workstream status,
  - the `Done` summary,
  - the `Left` summary,
  - or the current active lane.
- Whenever any workstream status or the current active lane changes:
  - refresh this board first,
  - log the change in `CHANGES.md`,
  - and display the current live status snapshot in the user-facing close-out for that task.
- Allowed status values are exactly:
  - `done`
  - `mostly done`
  - `in progress`
  - `not started`

## Status scale
- `done`
  - Roadmap intent for this workstream is satisfied.
  - Only incidental bugfixes or unrelated future reuse may remain.
- `mostly done`
  - Core architecture is landed.
  - Only a bounded finish-up lane remains.
- `in progress`
  - Active implementation is underway.
  - Multiple meaningful slices still remain.
- `not started`
  - The target architecture/work has not been implemented yet.
  - Notes or terminology may exist, but they do not count as implementation progress.

## Current active lane
- `R2` Live ownership migration from `FlattenedDT` backend/orchestrator into `EnableGraph`
- Current next decision point:
  - Re-audit the remaining backend-side filtering and live-usage checks around consolidated intermediate-signal emission to confirm they are truly backend-local and not owner-side analysis residue.

## Workstreams
### R0. Live roadmap tracking infrastructure
Status: `done`
Done:
- `ROADMAP_STATUS.md` is the canonical live status board.
- `README.md`, `MEMORY.md`, `COMMIT.md`, and `.agents/workflows/commit.md` are wired to this board and its update rule.
Left:
- Keep the board current before every commit when a task changes status, remaining work, or the active lane.
Exit criteria:
- Already met; this is now an ongoing maintenance obligation.

### R1. FlattenedDT dead-surface retirement
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
Status: `in progress`
Done:
- Per-run generation reset and state/DT enable-registry seeding cleanup.
- Capture registry, capture shape, capture metadata, capture entrypoints, and test-condition AST ownership.
- Top-level enable emission and unified WEN/EN emission.
- Internal declaration planning, module declaration planning, and state register planning.
- WEN/EN prescan and logical-op counting.
- First-pass and second-pass factorization AST feeding, plus second-pass intermediate-signal eligibility checks.
- First-pass and second-pass substitution synchronization, plus the unary-negation debug scan over owner-side AST structures.
Left:
- Audit the remaining backend-side filtering and live-usage checks that still inspect `assignment_analysis` or captured condition ASTs during consolidated intermediate-signal emission.
- Move only the pieces that are truly synthesis/analysis ownership, not backend-local factorization or rendering.
- Declare this lane complete once the remaining backend code is clearly backend-local by responsibility.
Exit criteria:
- The active path no longer has ownership confusion around synthesis analysis versus backend rendering/factorization.

### R3. AST/CoreAST-first runtime convergence
Status: `mostly done`
Done:
- Top-level enable registries are AST-backed.
- Intermediate-signal registry, dependency recovery, runtime-AST normalization, and driving-AST storage were pushed toward AST/CoreAST-first behavior.
- Compatibility fallback breadth was reduced substantially; unresolved cases are narrower and explicit.
Left:
- Re-audit the remaining compatibility fallbacks and unresolved runtime-AST miss paths.
- Either remove them, replace them with native AST/CoreAST data, or explicitly keep them with a justified boundary.
Exit criteria:
- Live intermediate-signal/runtime behavior is fully native AST/CoreAST-first, with only deliberate and well-justified compatibility residue if any.

### R4. Assignment semantics and capture contract modernization
Status: `done`
Done:
- Assignment intent metadata, provenance, and output exposure are explicit in the parsed/CoreAST model.
- Live capture preserves that metadata and the tests lock representative families (`<-`, `<=`, `=`, `<-=`, `<=+`, pulse delay).
Left:
- No dedicated roadmap lane remains here; future work should reuse this model rather than redesign it.
Exit criteria:
- Already met for the current roadmap intent.

### R5. Generator reuse / per-run state safety
Status: `done`
Done:
- Per-run generation state is reset explicitly before each generation.
- Generator reuse is covered by regression tests and no longer leaks prior-run registries into the next run.
Left:
- No dedicated roadmap lane remains here; only regressions/bugfixes if new leaks are discovered.
Exit criteria:
- Already met for the current roadmap intent.

### R6. Composition-oriented language / architecture work
Status: `not started`
Done:
- Terminology and sequencing were clarified in the docs.
Left:
- Design and implement the actual composition-oriented language and architecture work.
- Define concrete scope and acceptance tests before starting.
Exit criteria:
- Composition capabilities exist in the active architecture, not just in notes/terminology.

### R7. Extension/plugin redesign replacing legacy `.plg` / `PPlugin`
Status: `not started`
Done:
- Roadmap direction is explicit: legacy `.plg` / `PPlugin.pm` support is to be retired, not preserved as the future architecture.
Left:
- Define the replacement typed hook/extension mechanism.
- Implement it and migrate off the legacy plugin model.
Exit criteria:
- Legacy plugin support is no longer the architectural extension path and the replacement mechanism is active.
