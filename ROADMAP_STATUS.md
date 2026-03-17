# ROADMAP_STATUS
This is the canonical live roadmap status board for FSMGen.
Use it to answer, at any time, what is done, what is left, and which lane is currently active.

## Current roadmap generation
- `v2` is now the active roadmap generation.
- `R0` through `R7` remain the closed foundation workstreams from the completed first roadmap.
- `R8` through `R14` are the active/planned workstreams for the post-modernization roadmap.
- [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) is the detailed companion roadmap; this file remains the canonical live status board.
- Long-term horizon goals beyond the active `R8`..`R14` lanes are also tracked in [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), but they are intentionally gated behind the “make the tool state-of-the-art and very stable first” rule.

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
- `R11` Composition contract strengthening.
- Current next decision point:
  - Keep the reusable-root lane moving while `?dt:name`, explicit search-root behavior, `?dtc` composition child reuse, embedded `.rtlif` roots, and the new broader external-RTL `C3`/`C4` slices are all fresh in the tree.
  - The `.rtlif` interface-source family now covers typed ports, embedded same-file roots, and single-/multi-`?rtl` composition edges across both explicit-link and declared by-name lanes, `C3` now covers multi-generated-child mixed explicit-link tops as long as at least one `?rtl` child is present, `C4` now covers the same broader mixed child set with exact-one-match top outputs and fanout-capable top inputs, `C1` now supports omitted/empty-`?ports` passthrough inference, and `C2`/`C3` now support bounded omitted/empty-`?ports`, explicit-toplink-driven top-port inference, undeclared top-interface, and same-name internal-carrier inference when child-side evidence is unambiguous, including explicit top-output re-export of those carriers.
  - The next bounded convention-over-configuration choice is now above that: how much farther top-boundary inference and local override should go beyond the newly shipped explicit-link omitted/empty-`?ports` slice without turning composition back into hidden broad auto-wiring.
  - The new composition provenance metadata is now visible in both pipeline results and non-quiet CLI summaries, so the next honest diagnostics step is broader “blocked” / “overridden” reporting rather than more hidden inference.
  - The first shipped “overridden” and “blocked” reporting slices are now both in place for successful composition runs, and the bounded failure-path blocked-wording slice now covers plain explicit top-port same-name convention, undeclared top-input/top-output/internal-carrier inference, explicit-toplink-driven undeclared top-port inference, explicit top-output re-export mismatches for inferred same-name internal carriers, and declared `=name` connect-by-name failures, so the next honest diagnostics step is broader failure-path wording beyond those composition families rather than more hidden inference.
  - The governing future rule is now explicit too: convention should stay primary, but explicit port/link declarations should override inference locally instead of forcing whole-interface restatement.
  - A second future convention-over-configuration lane is now explicitly recorded too: whether scalar and aggregate signal types should be inferred by default from LHS/RHS/member/index usage, with explicit declarations used mainly as overrides.
  - Keep `R8` hardening opportunistic unless it directly blocks a feature lane.

## Workstreams
### Closed v1 foundation workstreams
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
Status: `done`
Done:
- Terminology and sequencing were clarified in the docs.
- `docs/COMPOSITION_SCOPE.md` now defines the first concrete active composition scope grounded in the current `bin/fsmgen` / `HDLGenerator` / `FSMGenFull::Parser` architecture.
- The same scope document now defines the first executable acceptance matrix (`C1`..`C6`) and the initial planned test-file split for composition work.
- The active pipeline now classifies top-level source kind explicitly, so `?top:name` is recognized before the FSM-only parser runs.
- Unsupported composition input now fails with a composition-specific boundary diagnostic in both `HDLGenerator` and direct FSM-only parser calls, with focused regression coverage.
- The active pipeline now parses `?top:name` through a typed composition parser/IR boundary.
- The typed parser/IR slice now creates `CompositionSpec`, `CompositionTop`, typed `fsmc` / `dtc` / `rtl` child instances, `PortsBlock`, `TopLink`, and typed per-port/per-link planning objects.
- `docs/COMPOSITION_LEGACY_MAPPING.md` now records how the obsolete `fx/bin/fsmgen` composition lane maps onto the active `R6` plan without reviving `.plg` / `PPlugin` behavior.
- The first shipped composition runtime lane now exists for `C1`: one `?top:name`, one `?fsmc` child source realized either from the same file or from a searchable external `.fsm` source, one explicit `?ports` block, deterministic same-name top wiring, and generated top emission through `bin/fsmgen`.
- Realized child interface data is now carried as typed composition ports, with the current active child contract treating effective child system inputs explicitly:
  - explicit conventional `+system` children expose `clk` / `rstn`,
  - children without `+system` expose implicit `clk` / `rst_n`,
  - and explicit user-facing child ports from the FSM pipeline continue to ride alongside those system ports.
- `t/20-composition-single-fsm-top.t` now locks the first end-to-end composition acceptance slice across pipeline, plan, HDL text, and CLI output.
- The first shipped `C2` runtime slice now exists for multi-child generated-child composition: two or more generated children (`?fsmc` / `?dtc`), typed explicit `?toplink` endpoint resolution, deterministic instance ordering, deterministic internal-net creation for child-to-child wiring, and duplicate-driver rejection.
- `t/21-composition-two-fsm-linking.t` and [t/85-composition-standalone-dt-children.t](/Users/richarddje/Documents/github/fsmgen/t/85-composition-standalone-dt-children.t) now lock the generated-child `C2` success paths.
- The first shipped `C3` runtime slice now exists for mixed composition: exactly one generated child (`?fsmc` or `?dtc`) plus one external `?rtl` child, typed explicit `?toplink` endpoint resolution across mixed children, deterministic internal-net creation, and explicit RTL instantiation without regenerating external RTL internals.
- External RTL interface metadata is now loaded through a typed sidecar contract (`<module>.rtlif`) searched relative to the composition source and existing source-library roots, which keeps `?rtl` as a composition-time interface-binding concern instead of reviving legacy plugin/eval loaders.
- `t/22-composition-fsm-plus-rtl.t` and [t/85-composition-standalone-dt-children.t](/Users/richarddje/Documents/github/fsmgen/t/85-composition-standalone-dt-children.t) now lock the first mixed generated-child + `?rtl` success paths, and `t/23-composition-errors.t` now also locks duplicate-driver, unknown external-port, and direction-mismatch diagnostics.
- The first shipped `C4` runtime slice now exists for declared top-port connect-by-name: `?ports` can mark a top port as `=name`, top outputs still require exactly one same-named child output with matching width, and top inputs can now fan out to all same-named child inputs with matching width.
- `t/24-composition-connect-by-name.t` now locks the first `C4` success path plus ambiguous-match and unknown-name failures, and `t/14-composition-parser.t` now locks the `=port` parser shape.
- The first shipped `C5` diagnostic boundary now exists across both explicit links and declared connect-by-name:
  - explicit `?toplink` width mismatches are locked by regression,
  - declared connect-by-name width mismatches now name the top port, the child endpoint, and the conflicting widths directly.
- The first shipped `C6` boundary now exists for out-of-scope legacy composition constructs:
  - legacy macro/plugin children,
  - nested `?top` blocks,
  - legacy `?ports` mapping directives,
  - and nested `?toplink` structures
  now fail explicitly and point to the scoped composition docs instead of falling through to generic parser behavior.
- `t/25-composition-legacy-scope-errors.t` now locks the parser, pipeline, and CLI failure boundary for legacy macro/plugin constructs plus focused parser coverage for the other out-of-scope legacy shapes.
Left:
- No remaining acceptance-matrix slices are blocking `R6`.
- The `.rtlif` follow-up remains recorded as a future refinement note, not an `R6` closure blocker:
  - document the exact grammar / allowed token forms clearly,
  - and decide whether later work should evolve from sidecar metadata toward a stronger interface-source contract.
Exit criteria:
- Composition capabilities exist in the active architecture, not just in notes/terminology.

### R7. Extension/plugin redesign replacing legacy `.plg` / `PPlugin`
Description:
- Replace the legacy plugin path with a typed extension mechanism that fits the active architecture and can be tested and documented cleanly.
Deliverables:
- Define the replacement typed hook/extension mechanism for the active architecture.
- Implement that mechanism in the live toolchain.
- Migrate the project off legacy `.plg` / `PPlugin.pm` as the architectural extension path, with tests/docs for the replacement.
Status: `done`
Done:
- Roadmap direction is explicit: legacy `.plg` / `PPlugin.pm` support is to be retired, not preserved as the future architecture.
- [docs/EXTENSION_MODEL.md](/Users/richarddje/Documents/github/fsmgen/docs/EXTENSION_MODEL.md) now defines the first modern replacement seam and states its deliberate non-goals.
- The live toolchain now has typed extension packages:
  - [perl/FSM/Extension/Loader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Loader.pm)
  - [perl/FSM/Extension/Registry.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Registry.pm)
  - [perl/FSM/Extension/Context.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Context.pm)
- [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) now supports programmatic `extensions => [ ... ]` registration and dispatches the first live hook, `after_generate_result($context)`, for both FSM and composition generation results.
- The active architecture now also supports explicit extension-module loading:
  - programmatically through `extension_modules => [ ... ]` on `FSM::Pipeline::HDLGenerator->new(...)`,
  - and from the CLI through repeated `--extension-module Module::Name` flags on [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen).
- The active architecture now also supports explicit config-file loading:
  - programmatically through `extension_config_files => [ ... ]`,
  - and from the CLI through repeated `--extension-config <file>` flags,
  - with the current config contract being one explicit `module Module::Name` declaration per active line plus optional blank/comment lines.
- The shipped typed hook set now includes:
  - `after_parse_source($context)` at the parsed-source frontier,
  - and `after_generate_result($context)` at the returned-result frontier.
- [t/26-extension-mechanism.t](/Users/richarddje/Documents/github/fsmgen/t/26-extension-mechanism.t) now locks both shipped hook stages across FSM and composition generation.
- [t/27-extension-loading.t](/Users/richarddje/Documents/github/fsmgen/t/27-extension-loading.t) now locks explicit module-name loading through the loader, pipeline, and CLI, including targeted missing-module diagnostics.
- [t/28-extension-config-loading.t](/Users/richarddje/Documents/github/fsmgen/t/28-extension-config-loading.t) now locks explicit config-file loading through the loader, pipeline, and CLI, including malformed-config diagnostics with file/line reporting.
Left:
- No dedicated `R7` roadmap slices remain.
- Future extension growth should reuse this typed boundary deliberately rather than reopening `.plg` / `PPlugin.pm`.
- Richer constructor/config parameters or additional hooks are future enhancements, not blockers on the closed roadmap lane.
Exit criteria:
- Legacy plugin support is no longer the architectural extension path and the replacement mechanism is active.

### Active/planned v2 workstreams
### R8. Language-contract hardening
Description:
- Turn the current supported-language boundary into a normative `.fsm` contract so the active tool has a crisp, reviewable language surface instead of a gray zone between “parser accepts it” and “the project claims support”.
Deliverables:
- One normative `.fsm` language reference for the active tool.
- One explicit support-tier classification for every parser-visible construct:
  - fully supported,
  - intentionally experimental/deferred,
  - or explicitly rejected.
- Focused regression coverage that locks the adopted construct families and their intended semantics.
Status: `in progress`
Done:
- [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) already contains a live “currently supported `.fsm` constructs” section, which is the right foundation for a normative contract.
- [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) now preserves concrete semantic agreements for:
  - guarded blocks,
  - condition suffixes,
  - update shorthand,
  - and operator-arity semantics.
- [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) now captures the detailed post-`R0`..`R7` roadmap sequencing and intent.
- [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now promotes the first `R8` draft normative language-reference slice for:
  - guarded blocks,
  - condition suffixes,
  - update shorthand,
  - and the currently regression-backed operator-expression families.
- [t/29-language-contract-core-forms.t](/Users/richarddje/Documents/github/fsmgen/t/29-language-contract-core-forms.t) now locks the active parser/generator behavior for that same slice through focused regression coverage.
- [t/60-language-contract-update-shorthand-variants.t](/Users/richarddje/Documents/github/fsmgen/t/60-language-contract-update-shorthand-variants.t) now extends the active update-shorthand contract explicitly:
  - the separated forms `(+= sig)` and `(-= sig)` are now regression-backed as delta-`1` synonyms for `(++ sig)` and `(-- sig)`,
  - the separated forms `(+= sig N)` and `(-= sig N)` are now regression-backed as delta-carrying synonyms for `(+=N sig)` and `(-=N sig)`,
  - and those alternate spellings now generate HDL end to end through the active backend.
- [t/61-language-contract-update-shorthand-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/61-language-contract-update-shorthand-boundary.t) now locks the malformed-target side of the update-shorthand family explicitly:
  - malformed targets such as `(++ (counter))` and `(+= (byte_count) 4)` no longer disappear silently,
  - they now fail through a dedicated update-shorthand boundary,
  - and parser, pipeline, and CLI entry points now reject those malformed update-shorthand forms without emitting HDL.
- [t/62-language-contract-update-shorthand-tail-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/62-language-contract-update-shorthand-tail-boundary.t) now locks the malformed-tail side of the update-shorthand family explicitly:
  - valid guarded forms such as `(+= counter 4 <start)` remain supported,
  - malformed extra positional tails such as `(+= counter 4 3)` and `(+= counter 4 3 2)` now fail through a dedicated update-shorthand-tail boundary,
  - and parser, pipeline, and CLI entry points now reject those malformed forms without emitting HDL.
- [t/75-language-contract-inline-compound-modifier-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/75-language-contract-inline-compound-modifier-boundary.t) now locks the inline compound-modifier family explicitly:
  - bare inline forms such as `(ACC <- SRC (+=))` and `(COMB = SRC (-=))` are now regression-backed as delta-`1` variants,
  - malformed inline modifier payloads such as `(ACC <- SRC (+= 2 3))` now fail through a dedicated inline-modifier boundary instead of silently truncating their payload,
  - duplicate inline modifiers such as `(ACC <- SRC (+= 2) (-= 1))` now fail through a targeted duplicate-modifier boundary,
  - and parser, pipeline, and CLI entry points now reject those malformed inline modifiers without emitting HDL.
- [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now also promotes the shorthand guard family into the active contract instead of leaving it as future-only:
  - `(<foo ...)` means `foo != 0`,
  - `(<!foo ...)` means `foo == 0`,
  - and inline comparison shorthand such as `(<foo==3 ...)` and `(<foo<=3 ...)` is now supported in both guarded-block and suffix-guard positions.
- [t/39-language-contract-guard-shorthand.t](/Users/richarddje/Documents/github/fsmgen/t/39-language-contract-guard-shorthand.t) now locks that shorthand family directly, and [t/29-language-contract-core-forms.t](/Users/richarddje/Documents/github/fsmgen/t/29-language-contract-core-forms.t) now expects explicit comparison ASTs for the simple sugar forms too.
- [t/40-language-contract-expression-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/40-language-contract-expression-boundary.t) now locks explicit rejection of unsupported expression forms so the active operator family has a crisp parser boundary:
  - supported inline scalar comparison tokens such as `cnt[2:1]!=2'2`,
  - unsupported RHS operators such as `(bogus B C)`,
  - malformed active-operator arity such as `(== B)`,
  - and guard-only tokens such as `<start` when used in ordinary expression position.
- [t/77-language-contract-expression-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/77-language-contract-expression-entrypoints.t) now extends that malformed ordinary-expression family across entry points explicitly:
  - unsupported RHS operators, malformed active-operator arity, and guard-only ordinary RHS tokens now have focused pipeline and CLI no-output coverage too,
  - so the malformed ordinary-expression family is no longer parser-explicit but entrypoint-implicit,
  - and the active expression boundary is now regression-backed across parser, pipeline, and CLI for those malformed forms.
- [t/44-language-contract-relational-operators.t](/Users/richarddje/Documents/github/fsmgen/t/44-language-contract-relational-operators.t) now locks the broader operator-arity contract beyond arithmetic/logical folds:
  - n-ary relational chains such as `(< low mid high)` and `(== a b c d)`,
  - relational word aliases such as `(eq a b c d)` and `(ge high mid low)`,
  - the unary word alias `(not flag)`,
  - and generated HDL that keeps the source inputs from parser-created relational intermediates live in the module interface.
- [t/41-language-contract-top-level-source-kind-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/41-language-contract-top-level-source-kind-boundary.t) now locks explicit rejection of unsupported tagged top-level source kinds such as `?define:legacy_template`, so legacy wrapper/template roots no longer drift through the nested-`?fsm` fallback path.
- [t/46-language-contract-flat-plus-fsm-root.t](/Users/richarddje/Documents/github/fsmgen/t/46-language-contract-flat-plus-fsm-root.t) now locks the flattened legacy `+fsm` root directly:
  - both supported legacy `+fsm` layouts now generate HDL end to end:
    - the flattened sibling form with a first top-level `(+fsm module_name)` entry,
    - and the nested legacy root form `(+fsm module_name ...)`,
  - malformed `+fsm` roots without a scalar module name now fail with a targeted contract diagnostic instead of drifting through generic flat-header fallout.
- [t/47-language-contract-source-name-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/47-language-contract-source-name-boundary.t) now locks the tagged source-name boundary explicitly:
  - top-level `?fsm:module_name` and `?top:top_name` roots now require HDL-identifier-compatible names and fail clearly if malformed,
  - malformed embedded composition child sources like `?fsm:bad-name` now also fail explicitly instead of truncating to a valid prefix.
- [t/63-language-contract-source-root-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/63-language-contract-source-root-boundary.t) now locks the remaining unwrapped-source-root boundary explicitly:
  - bare top-level FSM content like `(+system ...)` or `(idle ...)` is rejected unless it is wrapped in `?fsm:module_name` or the legacy `+fsm` root family,
  - the classifier still leaves those files outside active source kinds (`kind => unknown`, no supported header),
  - and parser, pipeline, and CLI entry points now reject those malformed roots without emitting HDL.
- [t/64-language-contract-fsm-root-body-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/64-language-contract-fsm-root-body-boundary.t) now locks the structured FSM-root body boundary explicitly:
  - empty structured roots like `(?fsm:empty_root)` are rejected explicitly,
  - scalar top-level body items like `(?fsm:scalar_root BROKEN)` are rejected explicitly,
  - and parser, pipeline, and CLI entry points now reject those malformed structured roots without emitting HDL.
- [t/65-language-contract-plus-fsm-body-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/65-language-contract-plus-fsm-body-boundary.t) now locks the legacy `+fsm` body boundary explicitly:
  - empty `+fsm` roots like `(+fsm plus_empty)` are rejected explicitly,
  - scalar `+fsm` body items like `(+fsm plus_scalar BROKEN)` are rejected explicitly,
  - and parser, pipeline, and CLI entry points now reject those malformed legacy roots without emitting HDL.
- [t/66-language-contract-malformed-action-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/66-language-contract-malformed-action-entrypoints.t) now extends the malformed-action family across pipeline and CLI entry points explicitly:
  - single-token malformed DT actions like `(BROKEN)` no longer stay parse-only in the contract,
  - empty guarded blocks like `(<req)` are now also locked through pipeline and CLI no-output behavior,
  - and the malformed-action family now has end-to-end entrypoint coverage instead of parser-only coverage.
- [t/48-language-contract-standalone-dt-classification.t](/Users/richarddje/Documents/github/fsmgen/t/48-language-contract-standalone-dt-classification.t) now locks the general/combinational DT boundary explicitly:
  - hyphen-prefixed general DT blocks now carry explicit `standalone_dt` classification in the AST,
  - they stay out of the encoded-state plan,
  - and they emit DT-style enables instead of regular `current_state` comparisons.
- [t/49-language-contract-state-body-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/49-language-contract-state-body-boundary.t) now locks the state/DT body boundary explicitly:
  - empty FSM-state DT blocks like `(idle)` are rejected,
  - empty general DT blocks like `(-misc)` are rejected,
  - and malformed empty pseudo-states no longer drift through to later runtime stages.
- [t/52-language-contract-state-name-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/52-language-contract-state-name-boundary.t) now locks the state/DT name boundary explicitly:
  - regular FSM-state DT names must be HDL-identifier-compatible,
  - general/combinational DT names must use exactly one leading `-` plus an HDL-identifier-compatible base name,
  - and malformed names such as `bad-name`, `-bad-name`, or `--bad` now fail clearly through parser, pipeline, and CLI entry points.
- [t/53-language-contract-transition-target-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/53-language-contract-transition-target-boundary.t) now locks the transition-target boundary explicitly:
  - transition targets must use HDL-identifier-compatible names,
  - transition targets must resolve to a declared regular FSM-state DT block inside the same FSM source,
  - and malformed or unknown targets such as `bad-name`, `-comb`, or `missing_state` now fail clearly through parser, pipeline, and CLI entry points.
- [t/50-language-contract-size-section-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/50-language-contract-size-section-boundary.t) now locks the active `+size` boundary explicitly:
  - the legacy empty form `(+size)` is accepted as a no-op because it exists in the shipped corpus,
  - malformed `+size` payloads like `(+size BROKEN)` are rejected,
  - and malformed entries like `(A)` or non-positive widths are rejected with targeted diagnostics.
- [t/42-language-contract-test-selector-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/42-language-contract-test-selector-boundary.t) now locks the explicit-selector boundary for test-node branches:
  - operator-prefixed selectors such as `=0`, `=OTHER`, and `!=8'0` remain supported,
  - while malformed bare selectors such as `BUSY` or `0` are now rejected explicitly.
- [t/69-language-contract-test-selector-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/69-language-contract-test-selector-entrypoints.t) now locks pipeline and CLI no-output behavior for the same malformed test-selector family, so bare symbolic and numeric branch selectors now have end-to-end entrypoint coverage instead of parser-only coverage.
- [t/43-language-contract-top-level-form-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/43-language-contract-top-level-form-boundary.t) now locks explicit rejection of unsupported top-level bare forms inside `(?fsm:name ...)`, so future-looking forms such as `(lhs := value)` or malformed bare entries no longer disappear silently.
- [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now also promotes the symbol-definition families into the fully supported bucket and documents their current normative contract:
  - `(+constants ...)`,
  - `(+enums ...)`,
  - `(+define ...)`,
  - `(+params ...)`.
- [t/30-language-contract-symbol-definitions.t](/Users/richarddje/Documents/github/fsmgen/t/30-language-contract-symbol-definitions.t) now locks symbol-definition resolution through the active parser and generator for:
  - assignment RHS expressions,
  - and guard equality conditions.
- [t/51-language-contract-symbol-definition-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/51-language-contract-symbol-definition-boundary.t) now locks the malformed section/entry boundary for the same symbol-definition family:
  - empty `+constants`, `+define`, `+params`, and `+enums` sections are rejected explicitly,
  - malformed entry shapes such as `(+constants BROKEN)`, `(+define (D0))`, `(+params (P0))`, and `(+enums (mode BROKEN))` are rejected explicitly,
  - and the malformed side of the symbol-definition family now has explicit parser coverage instead of only happy-path resolution coverage.
- [t/76-language-contract-symbol-definition-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/76-language-contract-symbol-definition-entrypoints.t) now extends that malformed symbol-definition family across entry points explicitly:
  - malformed `+constants`, `+define`, and `+params` payloads now have focused pipeline and CLI no-output coverage too,
  - so the whole malformed symbol-definition family is no longer end-to-end only for `+enums`,
  - and the active symbol-definition boundary is now regression-backed across parser, pipeline, and CLI entry points.
- [t/78-language-contract-symbol-definition-token-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/78-language-contract-symbol-definition-token-boundary.t) now locks the token-validity side of that same symbol-definition family explicitly:
  - bad identifiers in `+constants`, `+define`, and `+params` now fail through targeted token-validity diagnostics,
  - non-scalar member values in `+enums` now fail through the corresponding member-token boundary,
  - and those malformed token cases are now regression-backed across parser, pipeline, and CLI entry points too.
- [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now also promotes the conventional `+system` section into the fully supported bucket and documents its current normative contract:
  - `(+system (clock clk) (sreset rstn))`,
  - `(+system (clock clk) (asreset rstn))`.
- [t/31-language-contract-system-section.t](/Users/richarddje/Documents/github/fsmgen/t/31-language-contract-system-section.t) now locks the active parser/generator behavior for that same slice:
  - accepted conventional shared-system declaration,
  - targeted rejection of non-conventional clock names,
  - targeted rejection of unsupported system directives,
  - and targeted rejection of incomplete `+system` sections.
- [t/72-language-contract-system-section-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/72-language-contract-system-section-entrypoints.t) now locks pipeline and CLI no-output behavior for the malformed side of that same `+system` family, so bad clock names, unsupported entries, and incomplete sections now have end-to-end entrypoint coverage instead of parser-only coverage.
- [t/73-language-contract-system-section-duplicate-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/73-language-contract-system-section-duplicate-boundary.t) now locks the duplicate-declaration side of the same `+system` family:
  - duplicate `(clock clk)` entries are rejected explicitly,
  - duplicate reset declarations are rejected explicitly, including mixed `(sreset rstn)` plus `(asreset rstn)`,
  - and parser, pipeline, and CLI entry points now fail without emitting HDL for those malformed duplicate sections.
- [t/79-language-contract-system-section-structure-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/79-language-contract-system-section-structure-boundary.t) now locks the malformed-entry-structure side of the same `+system` family explicitly:
  - scalar payloads like `BROKEN` inside `(+system ...)` are rejected explicitly,
  - wrong-arity entries like `(clock clk extra)` are rejected explicitly,
  - and parser, pipeline, and CLI entry points now fail without emitting HDL for those malformed `+system` structures too.
- [t/80-language-contract-system-reset-name-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/80-language-contract-system-reset-name-boundary.t) now locks the reset-name side of the same `+system` family explicitly:
  - non-conventional synchronous-reset names like `(sreset reset)` are rejected explicitly,
  - the same applies to `(asreset reset_async_n)`,
  - and parser, pipeline, and CLI entry points now fail without emitting HDL for those malformed reset-name cases too.
- [t/74-language-contract-implicit-system-defaults.t](/Users/richarddje/Documents/github/fsmgen/t/74-language-contract-implicit-system-defaults.t) now locks the no-`+system` default system contract explicitly:
  - FSMs without `+system` now generate with implicit `clk` / `rst_n`,
  - explicit conventional `+system` still keeps the declared `clk` / `rstn` pair,
  - and composition child realization now exposes and auto-wires the effective child system ports instead of hardcoding `rstn`.
- [t/32-language-contract-top-level-directive-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/32-language-contract-top-level-directive-boundary.t) now locks explicit rejection of unsupported top-level `+...` directive sections so they no longer drift into fake state parsing.
- [t/70-language-contract-top-level-directive-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/70-language-contract-top-level-directive-entrypoints.t) now locks pipeline and CLI no-output behavior for the same unsupported top-level `+...` directive family, so unknown and future-style `+` sections now have end-to-end entrypoint coverage instead of parser-only coverage.
- [t/33-language-contract-condition-suffix-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/33-language-contract-condition-suffix-boundary.t) now locks explicit rejection of bare condition suffixes so suffix guards must use the active `<...` / `<!...` forms instead of implicit bare-word tails.
- [t/67-language-contract-condition-suffix-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/67-language-contract-condition-suffix-entrypoints.t) now locks pipeline and CLI no-output behavior for the same malformed bare condition-suffix family, so assignment and transition bare tails now have end-to-end entrypoint coverage instead of parser-only coverage.
- [t/34-language-contract-malformed-actions.t](/Users/richarddje/Documents/github/fsmgen/t/34-language-contract-malformed-actions.t) now locks:
  - explicit support for top-level compact `:=` init/reset directives,
  - explicit rejection of malformed DT action forms,
  - and explicit rejection of empty guarded blocks so broken DT actions no longer disappear silently.
- [t/56-language-contract-init-directive-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/56-language-contract-init-directive-boundary.t) now locks the malformed-RHS side of the active `:=` directive explicitly:
  - unsupported reset/default RHS values such as `[DATAIN]` or `<start` now fail through the dedicated `:=` contract boundary,
  - and malformed `:=` RHS values now fail clearly through parser, pipeline, and CLI entry points without emitting HDL.
- [t/81-language-contract-init-directive-shape-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/81-language-contract-init-directive-shape-boundary.t) now locks the malformed-shape side of the same `:=` directive explicitly:
  - malformed non-scalar payloads such as `(:= (tester_reset=1 extra))` now fail through the dedicated `:=` payload boundary,
  - malformed compact directives such as `(:= BROKEN)` now have focused pipeline and CLI no-output coverage too,
  - and the active `:=` family is now regression-backed across parser, pipeline, and CLI for both malformed payload shape and malformed RHS value cases.
- [t/57-language-contract-pulse-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/57-language-contract-pulse-boundary.t) now locks the malformed-RHS side of delayed-pulse `<N` assignments explicitly:
  - malformed delayed-pulse RHS values such as `B` or `2'0` now fail through a dedicated delayed-pulse boundary,
  - and malformed delayed-pulse RHS values now fail clearly through parser, pipeline, and CLI entry points without emitting HDL.
- [t/58-language-contract-condition-expression-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/58-language-contract-condition-expression-boundary.t) now locks the malformed-boundary side of guard shorthand and inline comparison tokens explicitly:
  - malformed guard shorthand payloads such as `mode=` or `==3` now fail through the dedicated guard-condition boundary,
  - malformed inline comparison tokens such as `cnt[2:1]!=` or `=3` now fail through the dedicated inline-comparison boundary,
  - and both malformed families now fail clearly through parser, pipeline, and CLI entry points without emitting HDL.
- [t/59-language-contract-assignment-operator-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/59-language-contract-assignment-operator-boundary.t) now locks the assignment-operator boundary explicitly:
  - the active assignment family is `=`, `<-`, `<-=`, `<=`, `<=+`, and delayed-pulse forms like `<1`,
  - unsupported operators such as `?=` or `=>` now fail through a dedicated assignment-operator boundary,
  - and those malformed assignment forms now fail clearly through parser, pipeline, and CLI entry points without emitting HDL.
- [t/35-language-contract-test-branch-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/35-language-contract-test-branch-boundary.t) now locks explicit rejection of malformed empty test-node branches so `?sig` / case-style dispatch no longer fails through a generic internal `undef` action path.
- [t/68-language-contract-test-branch-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/68-language-contract-test-branch-entrypoints.t) now locks pipeline and CLI no-output behavior for the same malformed test-branch family, so empty or body-less `?sig` branches now have end-to-end entrypoint coverage instead of parser-only coverage.
- [t/36-language-contract-test-branch-selectors.t](/Users/richarddje/Documents/github/fsmgen/t/36-language-contract-test-branch-selectors.t) now locks active relational test-node selector lowering for `!=`, `>`, and `<=`, so the shipped `?sig` selector family is no longer documented more narrowly than the live lowering behavior.
- [t/37-language-contract-computed-test-selector.t](/Users/richarddje/Documents/github/fsmgen/t/37-language-contract-computed-test-selector.t) now locks the active `?(expr)` computed-selector form end to end:
  - computed selectors synthesize a real intermediate condition signal,
  - the source expression signals stay live in the generated interface,
  - and emitted HDL reuses that computed selector signal in its branch comparisons.
- [t/54-language-contract-test-signal-name-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/54-language-contract-test-signal-name-boundary.t) now locks the plain `?SIG` signal-name boundary explicitly:
  - plain test nodes must use an HDL-identifier-compatible signal name after `?`,
  - computed selectors `?(expr)` remain supported separately,
  - and malformed plain test-node signals such as `?bad-name` or `?0` now fail clearly through parser, pipeline, and CLI entry points.
- [t/55-language-contract-computed-test-selector-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/55-language-contract-computed-test-selector-boundary.t) now locks the malformed-boundary side of the active `?(expr)` form explicitly:
  - computed test selectors must start with a real selector expression,
  - computed test selectors must include at least one selector branch,
  - and malformed forms such as `(? (=0 ...))` or `(?(| A B))` now fail clearly through parser, pipeline, and CLI entry points.
- [t/45-language-contract-reset-state-spellings.t](/Users/richarddje/Documents/github/fsmgen/t/45-language-contract-reset-state-spellings.t) now locks the active reset-state spelling and classification contract:
  - `-syncrst` and `-syncreset` normalize to the same `syncreset` reset-state identity,
  - `-asyncrst` and `-asyncreset` normalize to the same `asyncreset` reset-state identity,
  - and those reset blocks stay out of the regular encoded-state plan while still generating DT-style enable handling.
- [t/38-language-contract-generic-placeholder-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/38-language-contract-generic-placeholder-boundary.t) now locks explicit rejection of the legacy generic/template placeholder family in the FSM-only parser:
  - placeholder selectors such as `?[READ]`,
  - repeat macros such as `?repeat:[MAX_COUNT]`,
  - and placeholder tokens such as `[DATAIN]`.
- [t/71-language-contract-generic-placeholder-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/71-language-contract-generic-placeholder-entrypoints.t) now locks pipeline and CLI no-output behavior for that same legacy generic/template placeholder family, so placeholder selectors, repeat macros, and placeholder tokens now have end-to-end entrypoint coverage instead of parser-only coverage.
Left:
- Resolve the remaining gray-zone families, especially:
  - any remaining parser-accepted legacy constructs not yet cleanly bucketed.
- Continue adding focused regression coverage per adopted construct family so support claims are continuously provable.
Exit criteria:
- Every parser-visible active-language construct is bucketed clearly and documented normatively, with matching regression coverage for the supported tier.

### R9. Strict mode and support-tier enforcement
Description:
- Add an explicit “supported-language only” mode so users can choose predictability over compatibility residue.
Deliverables:
- A strict mode in the CLI/pipeline.
- Targeted diagnostics for constructs outside the fully supported tier.
- User/developer docs that explain how strict mode interacts with support tiers.
Status: `not started`
Done:
- No live implementation yet.
Left:
- Define strict-mode surface and failure contract after `R8` clarifies the language boundary.
- Implement CLI/pipeline enforcement and tests.
Exit criteria:
- Users can run the tool in a mode that accepts only the fully supported language contract.

### R10. Source provenance and diagnostics
Description:
- Make parser/generator failures precise, source-local, and actionable enough for large real-world `.fsm` inputs.
Deliverables:
- File/line/construct provenance through parsing and generation.
- More targeted diagnostics instead of generic parser/runtime fallout.
- Clear remediation guidance for common construct-family failures.
Status: `not started`
Done:
- No dedicated v2 slice has started yet.
Left:
- Define provenance-carrying boundaries and upgrade key diagnostics.
- Add regression coverage for error shape and location reporting.
Exit criteria:
- Major parser/generator failures identify the offending source construct precisely and explain the intended fix path clearly.

### R11. Composition contract strengthening
Description:
- Deepen the shipped composition model and adjacent reusable module/type contracts without widening them carelessly.
Deliverables:
- Formalize the `.rtlif` contract clearly.
- Decide whether later work should keep `.rtlif` as-is or place a stronger interface-source contract above it.
- Define one bounded multi-FSM shared-datapath composition lane for generated tops:
  - one run may compose one top from one `.fsm` source or from several `.fsm` sources,
  - some child outputs remain directly child-owned,
  - outputs assigned in at least two child FSMs are the shared-datapath candidates and may be lifted into one shared datapath block with deterministic per-child drive-intent enables and shared aggregate enables,
  - outputs assigned in only one child FSM are not shared and stay directly child-owned,
  - outputs coming from child FSMs or the shared datapath block are top-level outputs by default,
  - peer-read registered outputs become top-internal by default unless the user explicitly asks to re-export them,
  - only lifted registered outputs may loop back into child FSM inputs,
  - combinational outputs must never become cross-FSM read sources, so they remain top-level outputs only,
  - same-target/same-value aggregation must stay distinct from same-target/different-value conflicts,
  - the default shared-drive contract should surface conflict/assertion bits rather than auto-resolve or auto-prioritize,
  - per-`(P, Q)` source-enable families should support onehot0-style checks,
  - and whole-target `P` families should support assertion bits that detect multiple value families becoming active in the same cycle.
- Define one bounded reusable standalone-DT/module-library lane:
  - `?dt:name` as the smallest standalone module description,
  - `?dt:name` may contain any number of internal general DT blocks such as `(-foo ...)`,
  - standalone DT modules may mix combinational and sequential outputs,
  - `?fsm:name` implicitly declares `clk` / `rst_n`,
  - `?dt:name` implicitly declares `clk` / `rst_n` only when at least one sequential assignment exists,
  - `?top:name` and sequential `?dt:name` should keep `rst_n` as the default async-reset convention even though the current explicit `?fsm` `+system` compatibility residue still spells `rstn`,
  - `?dt:name` output-driving semantics stay aligned with current DT handling inside `?fsm:name`,
  - multiple internal `(-foo ...)` blocks may assign the same target without structural rejection,
  - and generated enable families should support explicit mutual-exclusion assertions instead of relying on an over-broad conflict ban,
  - `?top:name` remains the explicit composition-root concept unless a later family-level root-syntax decision introduces aliases such as `?mod:name` or `?module:name`,
  - and reusable-source lookup should grow through existing `FSMLIB` semantics plus repeatable per-invocation `--path DIR` roots.
- Define one bounded portable synthesizable-type lane:
  - bits / bit-vectors, enums, records / packed-struct-like aggregates, fixed-size arrays, arrays of records, and named aliases / subtypes should become a deliberate frontend type core,
  - that type core should stay portable across SystemVerilog and future VHDL instead of promising backend-specific conveniences such as free aggregate-to-vector casting,
  - and type inference should be the default path for most signal and port declarations, with explicit type declarations mainly acting as overrides, disambiguation anchors, and interface-stability controls.
- Harden mixed generated-child / `?rtl` flows before broader composition syntax is considered.
Status: `in progress`
Done:
- The scoped `R6` composition lane is complete.
- The `.rtlif` follow-up and the bounded shared-datapath extraction direction are now both recorded as future `R11` contract work instead of loose brainstorming only.
- The first deliberate `.rtlif` contract-improvement slice is now also shipped:
  - sidecar metadata is now described as one flat `(?rtlif:module_name ...)` root with declaration-ordered port tokens,
  - compact tokens like `clk`, `data_in<8`, and `txd>` remain active,
  - typed tokens such as `core_clk:clock`, `rst_async_n:reset`, and `data_in<8:data` are now active too,
  - explicit type annotations are currently limited to `data`, `clock`, and `reset`,
  - and typed `clock` / `reset` metadata now lets mixed composition auto-wire custom-named RTL system ports honestly.
- The next bounded `.rtlif` contract-improvement slice is now also shipped:
  - `?top:name` sources may now carry embedded `(?rtlif:module_name ...)` companion roots for external RTL children,
  - embedded same-file `?rtlif` roots take precedence over sidecar `<module>.rtlif` files,
  - and mixed composition can therefore realize external RTL children without a separate sidecar file when the interface contract is declared locally.
- The first single-external-RTL composition broadening slice is now also shipped:
  - `C1` single-child passthrough now works for a lone `?rtl` child,
  - `C3` explicit-link composition now works for a lone `?rtl` child,
  - and `C4` declared connect-by-name now also works for a lone `?rtl` child.
- The next bounded external-RTL explicit-link broadening slice is now also shipped:
  - `C3` explicit-link composition now works for multiple `?rtl` children,
  - `C3` explicit-link composition now also works for exactly one generated child plus multiple `?rtl` children,
  - and `C3` explicit-link composition now also works for multiple generated children plus one or more `?rtl` children.
- The future reusable standalone-DT/module-library direction is now also recorded as explicit `R11` contract work instead of loose brainstorming only.
- The future portable synthesizable-type direction is now also recorded as explicit `R11` contract work instead of loose brainstorming only.
- That future `R11` direction now also records:
  - multi-`(-foo ...)` standalone `?dt:name` modules,
  - the implicit-system split between always-implicit `?fsm:name` `clk` / `rst_n` and conditional implicit `?dt:name` `clk` / `rst_n`,
  - and the need to express arbitration/conflict reporting through generated enable families instead of structural over-rejection.
- That same future `R11` direction now also records:
  - a portable synthesizable-type core built around bits/vectors, enums, records, fixed arrays, arrays of records, and aliases/subtypes,
  - a strong convention-over-configuration preference for inferring scalar versus aggregate signal/port types from LHS/RHS/member/index usage,
  - explicit type declarations as bounded overrides rather than the default authoring path,
  - proposed explicit syntax centered on a future `(+types ...)` family,
  - and phased boundaries that start with type AST plus explicit declarations before broadening into inference, member access, exact-type aggregate assignment, and backend-specific conversion helpers.
- The first reusable standalone-DT slice is now shipped in the active toolchain:
  - top-level `?dt:name` roots are classified, parsed, and generated end to end,
  - the active `?dt:name` top-level contract currently supports `(+size ...)`, `(+constants ...)`, `(+enums ...)`, `(+define ...)`, `(+params ...)`, compact top-level `(:= signal=value)` directives, and general DT blocks such as `(-foo ...)`,
  - `?dt:name` rejects explicit `+system`, regular FSM-state blocks, and dedicated reset-state blocks at top level,
  - purely combinational `?dt:name` modules expose no implicit `clk` / `rst_n`,
  - sequential `?dt:name` modules expose implicit `clk` / `rst_n`,
  - driven non-intermediate targets in `?dt:name` become module outputs by default,
  - and standalone `?dt:name` generation stays out of the encoded `current_state` / `next_state` plan.
- [t/82-standalone-dt-root-support.t](/Users/richarddje/Documents/github/fsmgen/t/82-standalone-dt-root-support.t) now locks both the combinational and sequential `?dt:name` success paths.
- The first reusable-source lookup slice is now also shipped:
  - the CLI accepts repeatable `--path DIR` roots for bare `.fsm` input resolution,
  - explicit `--path` roots are searched before `FSMLIB`,
  - and the same explicit search roots now also feed external `.rtlif` metadata lookup for the current composition lane.
- [t/83-reusable-source-path-resolution.t](/Users/richarddje/Documents/github/fsmgen/t/83-reusable-source-path-resolution.t) now locks bare-name `--path` lookup, `--path` precedence over `FSMLIB`, and `--path`-driven external RTL metadata lookup.
- The first broader reusable-root/reference composition follow-up is now also shipped:
  - `?top:name` can now realize `?fsmc` children from embedded child FSM sources or from external searchable `.fsm` child sources,
  - external child source lookup checks beside the composition source first, then repeated `--path DIR` roots, then `FSMLIB`, then the current directory,
  - and existing `C1` / `C2` / `C3` composition lanes can therefore reuse child FSM modules across several `.fsm` files without reviving the legacy plugin/eval path.
- [t/84-composition-external-fsm-child-sources.t](/Users/richarddje/Documents/github/fsmgen/t/84-composition-external-fsm-child-sources.t) now locks sibling external-child realization, `--path`-driven external child realization, and `--path` precedence over `FSMLIB` for `?fsmc` child lookup.
- The first composition-facing standalone-DT child slice is now also shipped:
  - composition now accepts `?dtc:instance child_source` as a generated-child kind beside `?fsmc`,
  - `?dtc` child sources can be embedded `?dt:name` roots or external searchable `.fsm` standalone-DT sources,
  - purely combinational `?dtc` children keep an honest non-system interface instead of growing fake `clk` / `rst_n` ports in composition,
  - and the current `C1` / `C2` / `C3` generated-child lanes now cover standalone-DT child realization too.
- [t/85-composition-standalone-dt-children.t](/Users/richarddje/Documents/github/fsmgen/t/85-composition-standalone-dt-children.t) now locks:
  - embedded combinational `?dtc` success without fake system ports,
  - mixed `?fsmc` + `?dtc` explicit-link composition,
  - and external `?dtc` plus `?rtl` composition through repeated `--path DIR` roots.
- The first `R11` connect-by-name broadening slice beyond the original multi-child success case is now also shipped:
  - declared `=name` connect-by-name now works for a single generated child (`?fsmc` or `?dtc`) instead of starting only beyond the single-child passthrough case,
  - single-child by-name planning still stays deterministic and bounded by the existing exact same-name, same-direction, same-width rule,
  - and purely combinational standalone-DT children keep their honest non-system interface even in the single-child by-name lane.
- [t/86-composition-single-child-connect-by-name.t](/Users/richarddje/Documents/github/fsmgen/t/86-composition-single-child-connect-by-name.t) now locks single-child `?fsmc` and combinational `?dtc` declared connect-by-name success paths across pipeline and CLI.
- The first mixed generated-child plus external RTL declared connect-by-name slice is now also shipped:
  - declared `=name` connect-by-name is now regression-backed for the one generated child plus one `?rtl` lane, not only for generated-child-only lanes,
  - mixed `C4` tops may combine explicit child-to-child `?toplink` wiring with declared by-name top exposure,
  - and standalone-DT child interfaces now respect semantic signal roles before the old name-based direction heuristic, so RHS-only signals like `payload_in` stay inputs in mixed composition.
- [t/87-composition-mixed-connect-by-name.t](/Users/richarddje/Documents/github/fsmgen/t/87-composition-mixed-connect-by-name.t) now locks:
  - mixed `?fsmc` plus `?rtl` declared connect-by-name success,
  - mixed `?dtc` plus `?rtl` declared connect-by-name success,
  - and ambiguous same-name declared connect-by-name rejection across generated and external RTL child kinds.
- The next bounded external-RTL declared connect-by-name broadening slice is now also shipped:
  - `C4` declared connect-by-name now works for multiple `?rtl` children,
  - `C4` now also works for exactly one generated child plus multiple `?rtl` children,
  - and `C4` now also works for multiple generated children plus one or more `?rtl` children.
- [t/88-rtlif-typed-port-contract.t](/Users/richarddje/Documents/github/fsmgen/t/88-rtlif-typed-port-contract.t) now locks:
  - direct `.rtlif` token parsing for declaration-ordered typed metadata,
  - custom-named RTL `clock` / `reset` auto-wiring in mixed `?dtc` plus `?rtl` composition,
  - and rejection of unsupported explicit `.rtlif` type names.
- [t/89-composition-embedded-rtlif-roots.t](/Users/richarddje/Documents/github/fsmgen/t/89-composition-embedded-rtlif-roots.t) now locks:
  - embedded `?rtlif` precedence over sidecar metadata,
  - mixed generated-child plus `?rtl` success without a separate sidecar file,
  - and rejection of duplicate embedded `?rtlif` roots for the same RTL module name.
- [t/90-composition-single-rtl-child.t](/Users/richarddje/Documents/github/fsmgen/t/90-composition-single-rtl-child.t) now locks:
  - single `?rtl` passthrough `C1` success,
  - single `?rtl` explicit-toplink `C3` success,
  - and single `?rtl` declared connect-by-name `C4` success.
- The first bounded undeclared top-interface inference slice is now also shipped:
  - `C1` single-child passthrough may now omit `?ports` entirely or use an empty `(?ports)` block,
  - in that bounded case the top interface is inferred directly from the lone realized child interface,
  - and that inference currently stays limited to the single-child passthrough lane instead of widening into broader multi-child carrier inference.
- [t/96-composition-implicit-single-child-ports.t](/Users/richarddje/Documents/github/fsmgen/t/96-composition-implicit-single-child-ports.t) now locks:
  - omitted-`?ports` single-child `?fsmc` passthrough inference,
  - and empty-`?ports` single-child `?rtl` passthrough inference.
- The next bounded undeclared top-interface inference slice is now also shipped:
  - explicit-link `C2` / `C3` tops may now omit some top-input declarations when those names remain top-facing child inputs,
  - undeclared top inputs are inferred only when all same-name child inputs agree exactly on direction, width, and type metadata,
  - and child inputs already consumed by explicit child-to-child links are not re-inferred as top inputs.
- [t/97-composition-implicit-multi-child-inputs.t](/Users/richarddje/Documents/github/fsmgen/t/97-composition-implicit-multi-child-inputs.t) now locks:
  - inferred undeclared shared top-input success in explicit-link `C2`,
  - and width-mismatch rejection for undeclared shared top-input inference.
- The next bounded undeclared top-interface inference slice is now also shipped:
  - explicit-link `C2` / `C3` tops may now omit some top-output declarations when exactly one same-name child output remains top-facing,
  - child outputs already consumed by explicit child-to-child links are not re-inferred as top outputs,
  - and several same-name top-facing child outputs now fail through a dedicated boundary instead of falling through as generic unconnected child ports.
- [t/98-composition-implicit-multi-child-outputs.t](/Users/richarddje/Documents/github/fsmgen/t/98-composition-implicit-multi-child-outputs.t) now locks:
  - inferred undeclared unique top-output success in explicit-link `C2`,
  - inferred undeclared unique top-output success in explicit-link `C3`,
  - and ambiguity rejection for several same-name top-facing child outputs.
- The next bounded convention-over-configuration slice is now also shipped:
  - explicit-link `C2` / `C3` tops may now omit same-name child-to-child links when exactly one same-name child output and one or more same-name child inputs remain available,
  - those inferred internal carriers stay internal by default instead of being re-exported automatically,
  - explicit top ports or explicit links touching that name family still suppress the inference locally,
  - and several same-name child outputs now fail through a dedicated internal-carrier boundary instead of falling through as generic unconnected child ports.
- [t/99-composition-implicit-internal-carriers.t](/Users/richarddje/Documents/github/fsmgen/t/99-composition-implicit-internal-carriers.t) now locks:
  - generated-child internal-carrier fanout success in explicit-link `C2`,
  - mixed generated-plus-`?rtl` internal-carrier success in explicit-link `C3`,
  - and ambiguity rejection for several same-name child outputs feeding the same-name input family.
- The next local-override refinement is now also shipped:
  - explicit-link `C2` / `C3` tops may now declare a same-name top output to adopt and re-export one of those inferred internal carriers,
  - the carrier still stays internal by default when no such top output is declared,
  - and the explicit top-output override must still match the child-side width and type metadata exactly.
- [t/100-composition-internal-carrier-top-reexport.t](/Users/richarddje/Documents/github/fsmgen/t/100-composition-internal-carrier-top-reexport.t) now locks:
  - generated-child internal-carrier re-export success in explicit-link `C2`,
  - mixed generated-plus-`?rtl` internal-carrier re-export success in explicit-link `C3`,
  - ambiguity rejection for several same-name child outputs even when re-export is requested,
  - and explicit top-output type-mismatch rejection for the re-export path.
- The next convention-first top-boundary slice is now also shipped:
  - explicit-link `C2` / `C3` tops may now omit `?ports` entirely, or use an empty `(?ports)`, when explicit `?toplink` endpoints themselves provide enough evidence to infer the missing top ports,
  - renamed top-boundary signals are now supported through those explicit links,
  - same-name explicit top-input links still infer the top port declaration without duplicating the already-declared explicit bindings,
  - and undeclared top endpoints still fail explicitly when they are used as both inputs and outputs.
- [t/101-composition-explicit-link-implicit-ports.t](/Users/richarddje/Documents/github/fsmgen/t/101-composition-explicit-link-implicit-ports.t) now locks:
  - generated-child `C2` success with omitted `?ports` and renamed top endpoints,
  - RTL-backed `C3` success with empty `(?ports)` and renamed top endpoints,
  - and mixed-role undeclared-endpoint rejection.
- The next convention-first top-boundary refinement is now also shipped:
  - explicit-link `C2` / `C3` plain explicit top inputs may now adopt same-name fanout convention when compatible child inputs still agree exactly on direction, width, and type metadata,
  - explicit-link `C2` / `C3` plain explicit top outputs may now adopt one unique same-name top-facing child output when that child-side evidence is still exact,
  - the same-name internal-carrier re-export rule still handles the mixed input/output family separately,
  - and explicit top-boundary links still override that convention locally instead of forcing a whole-interface restatement.
- [t/102-composition-explicit-port-convention.t](/Users/richarddje/Documents/github/fsmgen/t/102-composition-explicit-port-convention.t) now locks:
  - generated-child `C2` success for plain explicit top-input fanout and plain explicit top-output adoption,
  - mixed generated-plus-`?rtl` `C3` success for the same plain explicit top-port convention,
  - mixed-direction rejection for plain explicit top-input convention,
  - and multi-output ambiguity rejection for plain explicit top-output convention.
- The next transparency/provenance slice is now also shipped:
  - typed composition ports now expose `origin_kind` so declared versus inferred top-boundary decisions stay visible,
  - typed composition links now expose `origin_kind` so explicit toplinks, declared `=name`, same-name convention links, internal-carrier links, and auto system-port links can be distinguished,
  - and `FSM::Composition::Plan` now exposes `resolved_links` as the full resolved link set used by planning instead of only the originally declared `links` input.
- [t/103-composition-provenance-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/103-composition-provenance-metadata.t) now locks:
  - declared parser-side top-port and explicit-toplink provenance,
  - `C1` inferred passthrough provenance,
  - explicit-toplink-driven inferred top-port provenance,
  - and resolved-link provenance for plain-explicit-port convention plus internal-carrier re-export.
- The next user-facing transparency/reporting slice is now also shipped:
  - composition generation results now carry `composition_report`,
  - `module_info` and `statistics` now carry composition resolved-link counts and the same provenance summary,
  - and non-quiet `bin/fsmgen` runs now print a composition summary plus top-port/resolved-link provenance counts for composition sources.
- [t/104-composition-provenance-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/104-composition-provenance-reporting.t) now locks:
  - pipeline-side `composition_report` counts for a mixed explicit-link `C3` composition,
  - and CLI composition provenance summary output for the same bounded fixture.
- The next local-override reporting slice is now also shipped:
  - `composition_report` now surfaces the first shipped override events,
  - those override counts now also flow through composition `module_info` and `statistics`,
  - and non-quiet `bin/fsmgen` runs now print a dedicated `Convention Overrides` summary when override events are present.
- [t/105-composition-override-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/105-composition-override-reporting.t) now locks:
  - pipeline-side reporting when explicit toplinks override same-name top-input/top-output convention,
  - pipeline-side reporting when an explicit top output re-exports an inferred internal carrier,
  - and CLI override-summary output for a bounded mixed explicit-link fixture.
- The first blocked-case reporting slice is now also shipped:
  - `composition_report` now surfaces the first shipped blocked convention events,
  - those block counts now also flow through composition `module_info` and `statistics`,
  - and non-quiet `bin/fsmgen` runs now print a dedicated `Convention Blocks` summary when block events are present.
- [t/106-composition-blocked-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/106-composition-blocked-reporting.t) now locks:
  - pipeline-side reporting when explicit child links block undeclared top-input/top-output inference,
  - pipeline-side reporting when inferred internal carriers stay internal by default,
  - and CLI blocked-summary output for a bounded explicit-link fixture.
- [t/91-composition-multi-rtl-children.t](/Users/richarddje/Documents/github/fsmgen/t/91-composition-multi-rtl-children.t) now locks:
  - multi-`?rtl` explicit-toplink `C3` success,
  - and one-generated-plus-multi-`?rtl` explicit-toplink `C3` success.
- [t/93-composition-multi-generated-plus-rtl-children.t](/Users/richarddje/Documents/github/fsmgen/t/93-composition-multi-generated-plus-rtl-children.t) now locks:
  - multi-generated-plus-`?rtl` explicit-toplink `C3` success.
- [t/92-composition-multi-rtl-connect-by-name.t](/Users/richarddje/Documents/github/fsmgen/t/92-composition-multi-rtl-connect-by-name.t) now locks:
  - multi-`?rtl` declared connect-by-name `C4` success,
  - one-generated-plus-multi-`?rtl` declared connect-by-name `C4` success,
  - and ambiguous multi-`?rtl` declared connect-by-name rejection.
- [t/94-composition-multi-generated-plus-rtl-connect-by-name.t](/Users/richarddje/Documents/github/fsmgen/t/94-composition-multi-generated-plus-rtl-connect-by-name.t) now locks:
  - multi-generated-plus-`?rtl` declared connect-by-name `C4` success.
- The next bounded declared connect-by-name refinement is now also shipped:
  - top outputs still require exactly one matching child output,
  - top inputs declared with `=name` now fan out to all matching child inputs of the same name and width,
  - and mixed-direction same-name candidates now fail explicitly instead of being ignored.
- [t/95-composition-connect-by-name-input-fanout.t](/Users/richarddje/Documents/github/fsmgen/t/95-composition-connect-by-name-input-fanout.t) now locks:
  - top-input fanout success across multiple same-name child inputs,
  - and mixed-direction same-name rejection for declared top-input connect-by-name.
Left:
- Decide whether later work should keep the now-formalized `.rtlif` interface-source family as embedded-root plus sidecar metadata, or place a stronger interface-source contract above it.
- Turn the new shared-datapath extraction direction into a real contract:
  - direct child-owned outputs vs multiply-assigned lifted shared-datapath targets,
  - per-child drive-intent aggregation,
  - same-target/same-value aggregation vs same-target/different-value conflicts,
  - assertion-bit strategy for per-`(P, Q)` source-enable conflicts and whole-target `P` multi-value conflicts,
  - default top-export vs peer-read internalization for registered outputs,
  - explicit user-directed re-export of now-internal registered outputs,
  - registered-output loopback rules,
  - and the rule that combinational outputs may be top-level outputs but not peer-FSM inputs.
- Turn the reusable standalone-DT/module-library direction into a real contract:
  - decide whether the newly shipped `?dt:name` root is the final standalone-DT spelling or whether `?mod:name` / `?module:name` should later exist as aliases or distinct roots,
  - decide whether unnamed reusable DT roots such as `?dt:` exist at all,
  - extend the current shipped `?dt:name` interface rule into a fuller reusable-module contract, especially around multi-block enable surfacing and composition-facing exposure,
  - define how multi-`(-foo ...)` standalone DT modules expose block-level and module-level enable families,
  - extend the now-shipped implicit-system rule split between `?fsm:name` and `?dt:name` into the broader reuse/composition contract,
  - extend the now-shipped generated-child contract beyond the current `?fsmc` / `?dtc` `C1` / `C2` / `C3` plus generated-only and mixed-lane `C4` slices into reusable-module interface/export rules,
  - and extend the now-shipped `--path` / `FSMLIB` lookup slice beyond bare top-level inputs, generated child sources, and `.rtlif` metadata lookup.
- Turn the portable synthesizable-type direction into a real contract:
  - settle the portable type core and keep it honest across SystemVerilog and future VHDL,
  - decide how a future `(+types ...)` family coexists with the already-shipped `(+enums ...)` lane,
  - define how far inference may go before the tool must require an explicit type anchor,
  - define how inferred scalar/aggregate declarations are surfaced in generated interfaces and internal declarations,
  - add member/field and fixed-size array access without overcommitting to aggregate literals too early,
  - and keep explicit type declarations available as bounded overrides instead of the default authoring burden.
- Refine declared top-port connect-by-name into an asymmetric integration-oriented contract:
  - decide how far future convention-over-configuration work should widen undeclared top-interface inference beyond the newly shipped `C1` passthrough slice and the newly shipped `C2` / `C3` omitted/empty-`?ports`, undeclared top-input/top-output/internal-carrier slices,
  - decide how far future convention-over-configuration work should widen beyond the newly shipped plain-explicit-top-port same-name convention in `C2` / `C3`,
  - decide whether the newly shipped explicit top-output re-export slice is enough or whether lighter/further override forms are warranted,
  - keep convention as the default authoring path while making explicit port/link declarations override inference locally instead of replacing the whole inferred interface,
  - keep that explicit override layer elegant and expressive rather than verbose duplicate configuration,
  - extend the newly shipped result/CLI provenance reporting beyond the new composition summary plus override/block counts so failure-path diagnostics explain “blocked” and “overridden” consistently too,
  - and keep any such convention top-boundary-oriented rather than turning child-to-child wiring into hidden inference everywhere.
- Track and later retire the current architectural hotspot set deliberately instead of letting it stay ambient debt:
  - split composition policy, interface inference, and top emission back out of `FSM::Pipeline::HDLGenerator`,
  - shrink `FSM::Synthesis::EnableGraph` toward a clearer synthesis boundary,
  - move planning/normalization residue out of `FSM::HDL::FlattenedDT::Backend::SystemVerilog` so backend responsibilities are more honest,
  - make the `FSM::CoreAST::*` versus `FSM::AST::*` bridge explicit instead of rediscovering it inside `EnableGraph`,
  - decide whether `FSM::ExpressionNamer` remains live architectural surface or should be retired as compatibility residue,
  - remove stale compatibility wording in `bin/fsmgen` help/output,
  - and revisit the global-state shape in `FSM::Debug` before `R13` embedding/API work depends on it.
- Add any needed diagnostics/tests before considering broader composition growth.
Exit criteria:
- External-RTL composition uses a clearly specified interface contract that is stronger and easier to reason about than the current “implemented convention” state.
- The first multi-FSM shared-datapath composition lane is also bounded by an explicit ownership/readback/export/assertion contract instead of informal architecture notes.
- The first reusable standalone-DT/module-library lane is also bounded by an explicit root/interface/lookup/system-port/arbitration contract instead of informal brainstorming.
- The first portable synthesizable-type lane is also bounded by an explicit frontend type core plus inference/override contract instead of informal brainstorming.

### R12. Regression corpus and support accounting
Description:
- Make support claims measurable and continuously auditable instead of conversational.
Deliverables:
- A representative `.fsm` corpus for supported / expected-failure / legacy-out-of-scope cases.
- Per-case classification rules that match the language contract.
- Golden outputs or semantic checks where appropriate.
Status: `not started`
Done:
- Current regression tests already cover many focused behaviors, which is the starting point for a broader support-accounting corpus.
Left:
- Curate and classify the corpus.
- Wire corpus expectations into repeatable regression checks.
Exit criteria:
- Support claims can be backed by a maintained corpus and explicit classification, not only by ad hoc focused tests.

### R13. Public embedding/API stabilization
Description:
- Make FSMGen intentionally embeddable as a library/tooling component with a documented and stable integration surface.
Deliverables:
- Stabilize/document the `HDLGenerator` result contract.
- Document the embedding-facing typed extension/context contract.
- Consider a more explicit serializable plan/report boundary where useful.
Status: `not started`
Done:
- The active pipeline and typed extension system already provide the raw ingredients for a real embedding contract.
Left:
- Decide which parts of the current pipeline result/plan surface become stable API.
- Document and regression-lock those surfaces.
Exit criteria:
- Downstream tooling can embed FSMGen against a documented, intentionally stable contract.

### R14. VHDL backend, if still wanted
Description:
- Implement a real VHDL backend only after the language contract is tight enough to support a second backend honestly.
Deliverables:
- Define the VHDL backend scope.
- Implement the single-FSM VHDL emission lane first.
- Decide later whether composition-top VHDL generation should also exist.
Status: `not started`
Done:
- Current code recognizes the target and fails explicitly with a not-implemented message instead of crashing.
Left:
- Open the real backend scope, then implement and test it deliberately.
Exit criteria:
- VHDL is a real, tested backend for the agreed scope rather than a recognized-but-unimplemented target.
