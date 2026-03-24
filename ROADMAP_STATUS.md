# ROADMAP_STATUS
This is the canonical live roadmap status board for FSMGen.
Use it to answer, at any time, what is done, what is left, and which lane is currently active.

## Current roadmap generation
- `v2` is now the active roadmap generation.
- `R0` through `R7` remain the closed foundation workstreams from the completed first roadmap.
- `R8` through `R14` are the active/planned workstreams for the post-modernization roadmap.
- [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) is the detailed companion roadmap; this file remains the canonical live status board.
- Long-term horizon goals beyond the active `R8`..`R14` lanes are also tracked in [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md), but they are intentionally gated behind the “make the tool state-of-the-art and very stable first” rule.
- The current saved `H1` guidance is that a future Rust implementation should likely start in this same repository beside the Perl reference implementation, not in a separate repository plus submodule arrangement, unless release cadence or ownership later diverge enough to justify a split.
- The current saved `H3` guidance is that any future HDL-to-`.fsm` direction should be framed as bounded synthesizable-RTL import / intent recovery, not as a promise of exact reverse compilation, with `fsmgen`-generated `SystemVerilog` as the most honest first round-trip target and richer handwritten hierarchy/generate/macro recovery treated as deliberate later widening after real frontend semantic compilation plus elaboration, even when no full backend compile/synthesis flow is involved; the saved architecture direction is also to keep separate syntax/front-end trees but converge both directions onto a shared semantic middle centered on `Intent HIR` and `Lowered RTL IR` rather than two unrelated semantic stacks.

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
  - The first shipped “overridden” and “blocked” reporting slices are now both in place for successful composition runs, the bounded failure-path blocked-wording slice now covers plain explicit top-port same-name convention, undeclared top-input/top-output/internal-carrier inference, explicit-toplink-driven undeclared top-port inference, explicit `?toplink` validation failures, explicit-link top-wiring and realized-child-wiring failures, explicit-link lane-entry/topology failures, top-level composition lane/shape gates, explicit top-output re-export mismatches for inferred same-name internal carriers, declared `=name` connect-by-name failures, `C1` passthrough exposure failures, duplicate top-port/child-instance declaration shape conflicts, reserved-system/unsupported-endpoint endpoint-shape conflicts, malformed `?ports` and `?toplink` parser items when top-port or top-link token flatness/shape/sizing would otherwise fail through older raw wording, malformed child-entry structure when empty child entries, non-string child headers, or dotted-pair child payloads would otherwise fail through older raw wording or warnings, unsupported child kinds when a composition child header falls outside the active `?fsmc` / `?dtc` / `?rtl` / `?ports` / `?toplink` family, malformed generated-child source payloads when `?fsmc` / `?dtc` payloads use nested option structures or the wrong number of flat source names, unsupported composition backend targets, generated child-source resolution/realization failures, blocked `C2` lane selection for one-generated-child explicit-link tops, blocked external RTL metadata resolution for missing `.rtlif` sidecars or embedded roots, blocked external RTL metadata structure when a reachable `.rtlif` file omits the required `?rtlif:<module>` root, blocked external RTL metadata port typing when a reachable `.rtlif` token resolves to an unsupported explicit type, blocked external RTL metadata token shape when a reachable `.rtlif` token is syntactically invalid for the active flat port-token contract, blocked external RTL metadata port sizing when a reachable `.rtlif` token declares a non-positive explicit width, blocked external RTL metadata port declaration uniqueness when a reachable `.rtlif` file repeats the same port name, blocked external RTL metadata port presence when a reachable `.rtlif` file declares no ports under the required root, blocked external RTL metadata flatness when a reachable `.rtlif` file contains nested structure under the required root, and blocked embedded RTL metadata root uniqueness when the same composition source contains multiple embedded `?rtlif:<module>` roots for one external RTL child.
  - The first bounded failed-run composition-summary slice is now also shipped for non-quiet CLI runs: when a composition failure exposes a blocked boundary in the raised diagnostic, the CLI now prints a small composition-failure summary with the failing top or external RTL module context, a `Lane:` line when the blocked diagnostic names the active `C1` / `C2` / `C3` / `C4` lane, a `Construct:` line when that same diagnostic points clearly at one active syntax construct such as `?ports`, `?toplink`, `?rtl`, `?fsmc`, `?dtc`, or `=port`, a generated-child source-file line when a blocked `?fsmc` / `?dtc` realization failure already names the resolved external `.fsm` file, an external RTL metadata-file line when a blocked `.rtlif` structure, token, sizing, typing, flatness, or declaration failure already names the resolved metadata file, an additional concise child/top-port/explicit-endpoint/token/repeated-RTL-port/RTL-root context line when that subject can be identified honestly, plus the blocked boundary label and a concise blocked-reason line before re-raising the original error.
  - That same failed-run summary path is now regression-locked for the reachable `C1` exposure families at CLI level too, so blocked top-port mismatch and blocked omitted-child-port cases now both keep their `Top port` / `Child port` context lines instead of relying only on pipeline-level extraction coverage.
  - That same failed-run summary path is now regression-locked for the reachable `C2` lane-selection family at CLI level too, so one-generated-child explicit-link tops now keep `Lane: C2` and the concise blocked lane-selection reason instead of relying only on generic extractor coverage.
  - That same failed-run summary path is now regression-locked for a reachable `C4` declared connect-by-name family at CLI level too, so blocked `=port` missing-endpoint failures now keep `Lane: C4`, `Construct: =port`, and the blocked top-port context instead of relying only on generic extractor coverage.
  - That same failed-run summary path is now regression-locked for a reachable ambiguous `C4` declared connect-by-name family at CLI level too, so blocked same-name ambiguity failures now keep the compatible-child-endpoint list in the concise `Reason:` line instead of leaving those candidates only in the raw exception text.
  - That same failed-run summary path is now regression-locked for a reachable width-mismatch `C4` declared connect-by-name family at CLI level too, so blocked width mismatches now keep the conflicting same-name endpoint set in the concise `Reason:` line instead of collapsing to only the declared width mismatch itself.
  - That same failed-run summary path is now regression-locked for a reachable incompatible-direction `C4` declared connect-by-name family at CLI level too, so blocked same-name direction conflicts now keep the conflicting endpoint set in the concise `Reason:` line instead of leaving those candidates only in the raw exception text.
  - That same failed-run summary path is now regression-locked for the reachable shared-system-port `=port` family too, so blocked attempts to declare system ports through connect-by-name keep the concise system-contract reason and top-port context without inventing a lane the raw diagnostic does not expose.
  - That same failed-run summary path is now regression-locked for the reachable missing top-level explicit-link endpoint family too, so blocked `?toplink` references to undeclared top-level endpoints keep `Construct: ?toplink`, `Context: Top endpoint 'missing_top'`, the blocked `explicit link endpoint resolution` boundary, and the concise `'?ports' declares no top port with that name` reason instead of relying only on the raw exception text.
  - That same failed-run summary path is now regression-locked for the reachable existing-instance missing-port explicit-link endpoint family too, so blocked `?toplink` references to child endpoints like `uart_tx.missing_port` keep `Construct: ?toplink`, `Context: Child endpoint 'uart_tx.missing_port'`, the blocked `explicit link endpoint resolution` boundary, and the concise `instance 'uart_tx' has no port named 'missing_port'` reason instead of relying only on the raw exception text.
  - That same failed-run summary path now also recognizes blocked `uses child endpoint '...'` direction-mismatch diagnostics as `Child endpoint` context, so explicit-link direction mismatches like `uart_tx.txd` no longer leave the active child endpoint token only in the raw exception text.
  - That same failed-run summary path is now regression-locked for the reachable explicit-link top-port role-mismatch family too, so blocked `?toplink` uses of a top port like `result_data` as the wrong endpoint role keep `Construct: ?toplink`, `Context: Top port 'result_data'`, the blocked `explicit link` boundary, and the concise top-port role reason instead of relying only on the raw exception text.
  - That same failed-run summary path now also recognizes blocked `assigns explicit link driver '...' to target '...'` duplicate-driver diagnostics as target context, so duplicate-driver conflicts no longer leave the conflicted target only in the raw exception text.
  - The duplicate-driver failed-run summary contract is now explicitly locked for both target families: top-boundary targets keep `Top port '...'` context, and child-input targets keep `Child endpoint 'instance.port'` context, while the concise reason still names the earlier explicit link that already reserved that target.
  - Failed-run summaries now also recognize blocked explicit-link width-mismatch diagnostics as target context instead of reason-only failures, so these runs keep `Top port '...'` or `Child endpoint 'instance.port'` context depending on the blocked target while preserving the concise `exact width agreement` reason.
  - The explicit-link width-mismatch failed-run summary contract is now explicitly locked for both reachable target families too: child-target mismatches keep `Child endpoint 'instance.port'` context, and top-boundary mismatches keep `Top port '...'` context while preserving the same concise exact-width-agreement reason.
  - Failed-run summaries now also recognize the blocked explicit-link topology family where one resolved source tries to drive multiple top outputs, keeping `Lane: C2`, `Construct: ?toplink`, and `Child endpoint 'instance.port'` context for the resolved source instead of leaving that source only in the raw exception text.
  - The sibling explicit-link topology family where a top input is wired directly to a top output is now also summary-backed with `Lane: C2`, `Construct: ?toplink`, and `Top port '...'` context for the blocked top-input source instead of leaving that source only in the raw exception text.
  - The missing-`?toplink` explicit-link lane-entry family is now also summary-backed, keeping `Lane: C2`, `Construct: ?toplink`, the blocked `explicit-link lane entry` boundary, and the concise reason while explicitly avoiding any invented context line when the diagnostic itself does not name one.
  - Failed-run duplicate-declaration summaries now also surface duplicate-name context instead of leaving it only in the raw exception text: blocked duplicate top-port declarations keep `Construct: ?ports` plus `Top port '...'` context, while blocked duplicate child-instance declarations keep `Child '...'` context with the same blocked `shape` boundary and uniqueness reason.
  - The explicit-link role-mismatch failed-run summary contract is now also symmetric across the remaining sibling families: blocked child-endpoint sources keep `Child endpoint 'instance.port'` context with the concise `input instead of output` reason, and blocked top-port targets keep `Top port '...'` context with the concise `input instead of output` reason, instead of relying only on the previously locked child-target and top-source families.
  - The missing generated-child source-resolution failed-run summary contract is now also explicit for both source families: unresolved `?fsmc` children keep `Construct: ?fsmc` plus `Child '...'` context and the concise missing-child-FSM reason, while unresolved `?dtc` children keep `Construct: ?dtc` plus `Child '...'` context and the concise missing-standalone-DT reason, without inventing a `Child source file:` artifact when no external file was actually resolved.
  - The wrong-kind generated-child realization failed-run summary contract is now also explicit for both realization families: wrong-kind `?fsmc` resolutions keep `Construct: ?fsmc`, `Child source file`, and `Child '...'` context with the concise non-FSM-child reason, while wrong-kind `?dtc` resolutions keep `Construct: ?dtc`, `Child source file`, and `Child '...'` context with the concise non-standalone-DT reason.
  - Failed-run parser-boundary summaries now also cover two more construct-scoped families explicitly: blocked `?ports` mapping directives keep `Construct: ?ports` plus `Mapping directive '...'` context and the concise declaration-mode reason, while blocked malformed `?toplink` tokens keep `Construct: ?toplink` plus `Token '...'` context and the concise token-shape reason.
  - The `?ports` token-family failed-run summary contract is now also explicit for the remaining parser token siblings: invalid explicit top-port tokens keep `Construct: ?ports` plus `Token '...'` context with the concise token-shape reason, and non-positive `?ports` width tokens keep `Construct: ?ports` plus `Token '...'` context with the concise sizing reason.
  - Failed-run parser-boundary summaries now also surface named-child context for malformed generated-child declarations instead of leaving that child name only in the raw exception text: blocked `?fsmc` source-count failures keep `Construct: ?fsmc` plus `Child '...'` context, while blocked `?dtc` source-shape failures keep `Construct: ?dtc` plus `Child '...'` context, both with the existing blocked child-source boundary labels and concise parser reasons.
  - That same generated-child parser-summary path now also keeps unnamed-child context when the blocked diagnostic exposes it directly, and the unnamed family is now symmetric across both parser boundaries: blocked unnamed `?fsmc` source-count and source-shape failures keep `Construct: ?fsmc` plus `Child '?fsmc'`, while blocked unnamed `?dtc` source-count and source-shape failures keep `Construct: ?dtc` plus `Child '?dtc'` instead of dropping child context from the short summary.
- The top-level child-structure parser family now also keeps child-entry context instead of dropping it completely in the short summary: blocked empty child entries keep `Child entry 'missing header'` with the blocked `child structure` boundary, while blocked non-string child headers keep `Child entry 'non-string header'` with the blocked `child header shape` boundary.
- The top-level composition lane/shape gate family now also has explicit failed-run summary coverage: blocked no-child tops keep the concise `lane entry` summary without invented construct/context, while blocked multiple-`?ports`, omitted-`?ports`, and empty-`?ports` tops now keep `Construct: ?ports` with the blocked `shape` boundary and the shorter shape-gate reason instead of falling through to a misclassified `?toplink` construct or the longer lane-exception clause.
- The nested-item parser family now also keeps the nested child-block identity in the short summary: blocked nested `?ports` items keep `Construct: ?ports` plus `Child '?ports'` with the blocked `port declaration flatness` boundary, while blocked nested `?toplink` items keep `Construct: ?toplink` plus `Child '?toplink'` with the blocked `explicit top-link token flatness` boundary.
- The named generated-child parser-summary family is now symmetric across count and shape failures too: blocked named `?fsmc` source-shape failures keep `Construct: ?fsmc` plus `Child 'child'`, and blocked named `?dtc` source-count failures keep `Construct: ?dtc` plus `Child 'child'`, instead of leaving those siblings only implicitly covered by generic extractor behavior.
- That same parser-summary path now also surfaces construct context for malformed child item-list payloads when the blocked diagnostic still names a real child header: blocked dotted-pair payloads like `?fsmc:child` now keep `Construct: ?fsmc` plus `Child '?fsmc:child'` context with the blocked `child item-list shape` boundary and the concise dotted-pair-contract reason.
  - That same child-item parser-summary path is now explicit for the `?toplink` sibling too: blocked dotted-pair payloads like `?toplink:wiring` now keep `Construct: ?toplink` plus `Child '?toplink:wiring'` context with the same blocked `child item-list shape` boundary and concise dotted-pair-contract reason.
  - That same child-item parser-summary path is now explicit for the `?ports` sibling as well: blocked dotted-pair payloads like `?ports` now keep `Construct: ?ports` plus `Child '?ports'` context with the same blocked `child item-list shape` boundary and concise dotted-pair-contract reason.
  - That same child-item parser-summary path is now explicit for the `?dtc` sibling as well: blocked dotted-pair payloads like `?dtc:child` now keep `Construct: ?dtc` plus `Child '?dtc:child'` context with the same blocked `child item-list shape` boundary and concise dotted-pair-contract reason.
  - That same child-item parser-summary path is now explicit for the `?rtl` sibling as well: blocked dotted-pair payloads like `?rtl:uart_tx` now keep `Construct: ?rtl` plus `Child '?rtl:uart_tx'` context with the same blocked `child item-list shape` boundary and concise dotted-pair-contract reason.
  - That same failed-run summary path is now regression-locked for the reachable unsupported explicit-endpoint syntax family too, so blocked `?toplink` endpoint-shape failures keep the unsupported endpoint token and concise “that syntax is unsupported” reason instead of relying only on the raw exception text.
  - That same failed-run summary path now covers both embedded `.rtlif` duplicate-root failures and file-based root-scoped `.rtlif` failures such as missing-root and empty-port cases through the same concise `RTL root` context line, instead of leaving the active `?rtlif:<module>` token buried in the raw exception text.
  - That same file-based `RTL root` summary path is now regression-locked through the flatness family too, so missing-root, empty-port, and nested-structure `.rtlif` failures all surface the active `?rtlif:<module>` token consistently.
  - The token-scoped `.rtlif` summary path is now also regression-locked through unsupported-type and non-positive-width failures, so token-shape, port-sizing, and port-typing failures all keep the offending token beside the resolved `RTL metadata file:` artifact line.
  - The governing future rule is now explicit too: convention should stay primary, but explicit port/link declarations should override inference locally instead of forcing whole-interface restatement.
  - A second future convention-over-configuration lane is now explicitly recorded too: whether scalar and aggregate signal types should be inferred by default from LHS/RHS/member/index usage, with explicit declarations used mainly as overrides.
  - A third future syntax-cleanup note is now recorded too: whether `?toplink` should stay canonical or gain a clearer preferred alias such as `?wiring`, ideally without breaking existing composition sources abruptly.
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
- Start extracting explicit forward compiler IR layers out of the active `.fsm` to HDL path instead of leaving proto-HIR/proto-lowered semantics implicit:
  - first one bounded `Intent HIR` slice for direct generated roots and realized generated children,
  - then one bounded `Lowered RTL IR` slice once that first forward semantic surface is stable,
  - then one bounded `Structural RTL IR` / connectivity slice once the lowered layer no longer has to stand in for emitted wiring structure,
  - while keeping those forward IR shapes aligned with the future shared-middle/import architecture rather than growing a separate forward-only semantic stack.
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
- That same future `R11` direction now also records:
  - interface bundles/protocol groups, enum-first `case` / `match`, small local alias/default blocks, bounded replication, first-class RTL intent helpers, terse invariant/assertion forms, and stronger explain/report surfaces as the current highest-leverage candidates for keeping the language powerful without making it noisy,
  - and a bounded meta-programming rule: if a future generic/meta lane exists at all, it should stay semantic, list-oriented, elaboration-bounded, and RTL-focused rather than becoming a broad macro/template system.
- The first reusable standalone-DT slice is now shipped in the active toolchain:
  - top-level `?dt:name` roots are classified, parsed, and generated end to end,
  - the active standalone-DT top-level contract currently supports the conventional `(+system ...)` form, `(+size ...)`, `(+constants ...)`, `(+enums ...)`, `(+define ...)`, `(+params ...)`, compact top-level `(:= signal=value)` directives, and general DT blocks such as `(-foo ...)`,
  - standalone-DT roots still reject regular FSM-state blocks and dedicated reset-state blocks at top level,
  - explicit conventional `(+system ...)` now yields `clk` / `rstn` in standalone-DT roots and composition-facing `?dtc` children,
  - without explicit `(+system ...)`, purely combinational `?dt:name` modules expose no implicit `clk` / `rst_n`,
  - without explicit `(+system ...)`, sequential `?dt:name` modules expose implicit `clk` / `rst_n`,
  - driven non-intermediate targets in `?dt:name` become module outputs by default,
  - and standalone `?dt:name` generation stays out of the encoded `current_state` / `next_state` plan.
- [t/82-standalone-dt-root-support.t](/Users/richarddje/Documents/github/fsmgen/t/82-standalone-dt-root-support.t) now locks both the combinational and sequential `?dt:name` success paths.
- The next reusable-root naming slice is now also shipped:
  - `?mod:name` and `?module:name` now act as active standalone-DT root aliases beside `?dt:name`,
  - those aliases classify, parse, and generate through the same standalone-DT contract,
  - and composition `?dtc` children may now realize embedded or external standalone-DT sources rooted at any of those three spellings.
- The first reusable-source lookup slice is now also shipped:
  - the CLI accepts repeatable `--path DIR` roots for bare `.fsm` input resolution,
  - explicit `--path` roots are searched before `FSMLIB`,
  - and the same explicit search roots now also feed external `.rtlif` metadata lookup for the current composition lane.
- [t/83-reusable-source-path-resolution.t](/Users/richarddje/Documents/github/fsmgen/t/83-reusable-source-path-resolution.t) now locks bare-name `--path` lookup, `--path` precedence over `FSMLIB`, and `--path`-driven external RTL metadata lookup.
- The first broader reusable-root/reference composition follow-up is now also shipped:
  - `?top:name` can now realize `?fsmc` children from embedded child FSM sources or from external searchable `.fsm` child sources,
  - named `?fsmc:name` and `?dtc:name` children may now omit the explicit source token and default it to the child name,
  - external child source lookup checks beside the composition source first, then repeated `--path DIR` roots, then `FSMLIB`, then the current directory,
  - and existing `C1` / `C2` / `C3` composition lanes can therefore reuse child FSM modules across several `.fsm` files without reviving the legacy plugin/eval path.
- [t/84-composition-external-fsm-child-sources.t](/Users/richarddje/Documents/github/fsmgen/t/84-composition-external-fsm-child-sources.t) and [t/135-composition-generated-child-default-source-names.t](/Users/richarddje/Documents/github/fsmgen/t/135-composition-generated-child-default-source-names.t) now lock sibling external-child realization, default-source named generated children, `--path`-driven external child realization, and `--path` precedence over `FSMLIB` for generated-child lookup.
- The first composition-facing standalone-DT child slice is now also shipped:
  - composition now accepts `?dtc:instance child_source` as a generated-child kind beside `?fsmc`,
  - `?dtc` child sources can be embedded `?dt:name` roots or external searchable `.fsm` standalone-DT sources,
  - purely combinational `?dtc` children keep an honest non-system interface instead of growing fake `clk` / `rst_n` ports in composition,
  - and the current `C1` / `C2` / `C3` generated-child lanes now cover standalone-DT child realization too.
- [t/85-composition-standalone-dt-children.t](/Users/richarddje/Documents/github/fsmgen/t/85-composition-standalone-dt-children.t) now locks:
  - embedded combinational `?dtc` success without fake system ports,
  - mixed `?fsmc` + `?dtc` explicit-link composition,
  - and external `?dtc` plus `?rtl` composition through repeated `--path DIR` roots.
- The next reusable standalone-DT system-contract slice is now also shipped:
  - standalone-DT roots may now opt into the same conventional explicit `(+system ...)` contract already used by `?fsm:name`,
  - that explicit standalone-DT system contract now flows through direct generation and composition-facing `?dtc` child realization,
  - and reusable standalone-DT modules may therefore choose the shared `clk` / `rstn` system-input contract explicitly instead of relying only on the implicit `clk` / `rst_n` fallback for sequential roots.
- [t/134-standalone-dt-explicit-system-support.t](/Users/richarddje/Documents/github/fsmgen/t/134-standalone-dt-explicit-system-support.t) now locks:
  - direct standalone-DT generation with explicit conventional `+system`,
  - and `C1` composition auto-wiring for `?dtc` children that expose explicit `clk` / `rstn`.
- The next reusable standalone-DT enable-surfacing slice is now also shipped:
  - direct standalone-DT generation now reports plain-scalar block names and stable per-block enable-signal families through `module_info`,
  - realized `?dtc` children now preserve that same standalone-DT enable metadata through composition,
  - and `module_info` now also groups those block enables into one module-level family summary without yet turning them into child interface ports.
- [t/136-standalone-dt-enable-family-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/136-standalone-dt-enable-family-metadata.t) now locks:
  - direct standalone-DT block-enable metadata,
  - and preservation of that same metadata for realized `?dtc` children.
- The next reusable standalone-DT arbitration-metadata slice is now also shipped:
  - direct standalone-DT generation now reports grouped multi-drive target families through `module_info`,
  - those grouped target families include the affected target name, contributing standalone-DT block names, RHS families, DT-specific enable names, and grouped LHS enable names,
  - and realized `?dtc` children now preserve that same grouped multi-drive metadata through composition.
- [t/137-standalone-dt-multi-drive-family-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/137-standalone-dt-multi-drive-family-metadata.t) now locks:
  - direct standalone-DT grouped multi-drive target metadata,
  - and preservation of that same metadata for realized `?dtc` children.
- The next reusable standalone-DT composition-export slice is now also shipped:
  - composition-top `module_info` now aggregates reusable `?dtc` child exports through `composition_standalone_dt_child_count`, `composition_standalone_dt_block_count`, `composition_standalone_dt_multi_drive_target_count`, and `composition_standalone_dt_children`,
  - those child exports now surface instance/module/source identity together with the already-shipped standalone-DT enable-family and grouped shared-target metadata,
  - and non-quiet `bin/fsmgen` composition runs now print one concise reusable standalone-DT child summary section from that top-level export surface instead of leaving callers to crawl realized children manually.
- [t/138-composition-standalone-dt-export-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/138-composition-standalone-dt-export-metadata.t) now locks:
  - composition-top aggregation of reusable standalone-DT child export metadata,
  - and the non-quiet CLI summary for that same composition-facing export surface.
- The next reusable standalone-DT assertion slice is now also shipped:
  - grouped standalone-DT multi-drive target families now also surface onehot0-style assertion metadata over their DT-specific driver-enable signals,
  - direct SystemVerilog standalone-DT roots now emit bounded non-synthesis guard assertions from that metadata,
  - realized `?dtc` children now also emit those same grouped-target guard assertions inside generated composition HDL,
  - and Verilog output keeps that standalone-DT assertion emission disabled.
- [t/154-standalone-dt-assertion-runtime-hdl.t](/Users/richarddje/Documents/github/fsmgen/t/154-standalone-dt-assertion-runtime-hdl.t) now locks:
  - SystemVerilog onehot0 assertion emission for direct standalone-DT grouped multi-drive targets,
  - absence of that assertion emission on the Verilog target,
  - and preservation of that assertion emission inside realized `?dtc` child modules in generated composition HDL.
- The first explicit forward-compiler IR extraction slice is now also shipped:
  - direct generated roots now build one explicit `FSM::IR::IntentHIR` summary before `module_info` is derived,
  - direct generation results now expose that serialized `intent_hir` summary,
  - realized generated children now also preserve that same serialized forward intent summary through their `module_info`,
  - and the shipped slice currently covers root identity, system contract, regular-state versus standalone-DT families, stable signal-analysis summaries, and standalone-DT enable families.
- [t/155-forward-intent-hir-surface.t](/Users/richarddje/Documents/github/fsmgen/t/155-forward-intent-hir-surface.t) now locks:
  - direct-result `intent_hir` surfacing for generated roots,
  - and preservation of that same forward intent summary through realized generated-child `module_info`.
- The first explicit forward `Lowered RTL IR` extraction slice is now also shipped:
  - new `FSM::IR::LoweredRTLIR` now captures one explicit lowered forward summary for generated output-drive families and standalone-DT grouped multi-drive targets,
  - direct generated roots now expose that serialized `lowered_rtl_ir` summary,
  - realized generated children now also preserve that same serialized lowered summary through their `module_info`,
  - and selected downstream composition/export consumers now prefer the extracted `lowered_rtl_ir` surface when present instead of re-reading only the legacy module-info fields.
- [t/156-forward-lowered-rtl-ir-surface.t](/Users/richarddje/Documents/github/fsmgen/t/156-forward-lowered-rtl-ir-surface.t) now locks:
  - direct-result `lowered_rtl_ir` surfacing for standalone-DT generated roots,
  - and preservation of the same lowered summary through realized generated-child `module_info` for both `?fsmc` and `?dtc` paths.
- The first forward-IR widening step into a top-level composition export surface is now also shipped:
  - aggregated `composition_standalone_dt_children` entries now preserve each realized `?dtc` child's serialized `intent_hir` summary,
  - those same exports now also preserve each realized child's serialized `lowered_rtl_ir` summary,
  - that same reusable standalone-DT child export now also lives inside composition-top `intent_hir`,
  - and the reusable standalone-DT export surface no longer drops the new explicit forward IR layers at the composition-top boundary.
- [t/157-composition-standalone-dt-forward-ir-exports.t](/Users/richarddje/Documents/github/fsmgen/t/157-composition-standalone-dt-forward-ir-exports.t) now locks:
  - preservation of reusable standalone-DT child exports through composition-top `intent_hir`,
  - preservation of child `intent_hir` through aggregated `composition_standalone_dt_children`,
  - and preservation of child `lowered_rtl_ir` through that same top-level composition export surface.
- The next forward-IR widening step into one broader generated-child composition export is now also shipped:
  - top-level `composition_generated_children` now covers realized `?fsmc` and `?dtc` children together,
  - that broader generated-child export now preserves each child's serialized `intent_hir` and serialized `lowered_rtl_ir`,
  - and non-quiet `bin/fsmgen` runs now print one concise generated-child summary derived from that exported surface.
- [t/158-composition-generated-child-forward-ir-exports.t](/Users/richarddje/Documents/github/fsmgen/t/158-composition-generated-child-forward-ir-exports.t) now locks:
  - `composition_generated_child_count`, `composition_generated_fsm_child_count`, and `composition_generated_dt_child_count`,
  - preservation of child `intent_hir` and `lowered_rtl_ir` through top-level `composition_generated_children`,
  - and the matching non-quiet CLI generated-child summary lines.
- The next forward-IR widening step through the shared-datapath candidate surface is now also shipped:
  - shared-datapath candidate contributors now preserve each realized child's serialized `intent_hir` and serialized `lowered_rtl_ir`,
  - those same contributor entries now also preserve the exact selected `output_drive_family` from that child's serialized `lowered_rtl_ir`,
  - and the existing bounded `drive_intent` summary is now derived from that extracted family instead of standing alone,
  - those contributor entries now also preserve stable generated-child identity through `kind` and `source_name`,
  - and non-quiet `bin/fsmgen` runs now print one concise contributor-context line from that surface before the existing drive-intent details.
- [t/159-composition-shared-datapath-forward-ir-exports.t](/Users/richarddje/Documents/github/fsmgen/t/159-composition-shared-datapath-forward-ir-exports.t) now locks:
  - preservation of child `intent_hir` and `lowered_rtl_ir` through shared-datapath candidate contributors,
  - preservation of the exact selected contributor `output_drive_family` from child `lowered_rtl_ir`,
  - preservation of contributor `kind` and `source_name`,
  - and the matching non-quiet CLI contributor-context lines.
- The next forward-IR widening step through composition tops themselves is now also shipped:
  - direct `?top` generation results now expose serialized top-level `intent_hir` and serialized top-level `lowered_rtl_ir`,
  - those composition-top forward layers now carry stable top-port analysis plus composition child-count / lane metadata on the intent side,
  - that same composition-top `intent_hir` surface now also carries the broader generated-child export instead of leaving it only as a separate top-level compatibility summary,
  - those same composition-top forward layers now also carry stable internal-net / instance / auxiliary-assignment summaries plus the bounded shared-datapath candidate surface on the lowered side,
  - and `module_info` now mirrors those same serialized composition-top forward IR layers instead of leaving composition tops as the remaining explicit forward-IR gap.
- [t/160-composition-top-forward-ir-surface.t](/Users/richarddje/Documents/github/fsmgen/t/160-composition-top-forward-ir-surface.t) now locks:
  - direct-result `intent_hir` surfacing for `?top` composition roots,
  - direct-result `lowered_rtl_ir` surfacing for `?top` composition roots,
  - preservation of those same serialized forward IR layers through composition-top `module_info`,
  - preservation of the reusable standalone-DT child export through composition-top `intent_hir`,
  - preservation of the broader generated-child export through composition-top `intent_hir`,
  - and the initial bounded composition-top fields for top-port analysis, child counts, lane, internal nets, instances, auxiliary assignments, and shared-datapath candidates.
- The first bounded `Structural RTL IR` extraction slice is now also shipped:
  - new `FSM::IR::StructuralRTLIR` now captures one explicit AST/netlist-like connectivity surface for composition tops,
  - direct `?top` generation results now expose serialized `structural_rtl_ir`,
  - composition-top `module_info` now mirrors that same serialized structural surface,
  - the shipped slice currently covers explicit top ports, internal nets, realized instances, pin bindings, and auxiliary assignments,
  - those structural instance pin bindings now also preserve a first typed `connection_expr` node, currently bounded to backend-neutral `signal_ref`,
  - and realized composition-plan instances now also preserve that same typed `signal_ref` node before structural serialization instead of forcing the structural layer to synthesize it late,
  - with that earlier binding normalization now owned by `FSM::Composition::RealizedInstance` itself instead of only by `HDLGenerator`,
  - and the current bounded `signal_ref` construction, signal-name recovery, and backend-neutral text rendering for those actual-connection nodes now also live in dedicated `FSM::IR::StructuralRTLIR::ConnectionExpr` helpers instead of staying split across pipeline glue,
  - with the remaining “effective binding expression” fallback now also centralized there, so structural serialization no longer re-synthesizes `signal_ref` nodes ad hoc from `signal_name` inside `HDLGenerator`,
  - and the first bounded signal-ref binding constructor/update helpers now also live there, so the pipeline no longer hand-pairs `signal_name` and `connection_expr` when creating or rebinding structural instance bindings,
  - with normalized binding cloning/backfilling now also centralized there, so both `FSM::Composition::RealizedInstance` and structural instance-binding serialization consume the same bounded binding contract,
  - and the first bounded signal-ref binding-list ensure/set operations now also live there, so `HDLGenerator` no longer owns the low-level “reuse this binding versus append/update it” rules for structural port-binding lists,
  - and the active composition-top emitter now walks that structural layer instead of re-reading only plan state directly during top-module dumping.
- [t/162-composition-top-structural-rtl-ir-surface.t](/Users/richarddje/Documents/github/fsmgen/t/162-composition-top-structural-rtl-ir-surface.t) now locks:
  - direct-result `structural_rtl_ir` surfacing for `?top` composition roots,
  - preservation of that same serialized structural surface through composition-top `module_info`,
  - stable top-port / net / instance / pin-binding connectivity details in the first bounded structural slice,
  - stable typed `connection_expr` nodes on those instance pin bindings,
  - stable typed `connection_expr` nodes on the underlying realized composition-plan instance bindings too,
  - and direct runtime normalization of `signal_name` / `connection_expr` alignment on `FSM::Composition::RealizedInstance`,
  - and that the active composition-top emitter can render the top module by walking the serialized structural layer.
- The next structural widening step is now also shipped:
  - direct generated `?fsm` / `?dt` results now expose a bounded structural module-interface slice through `structural_rtl_ir`,
  - that direct-root structural slice currently covers explicit module ports plus empty nets/instances/auxiliary structure,
  - and realized generated-child export surfaces now preserve that same child `structural_rtl_ir` beside `intent_hir` and `lowered_rtl_ir`.
- [t/163-forward-structural-rtl-ir-surface.t](/Users/richarddje/Documents/github/fsmgen/t/163-forward-structural-rtl-ir-surface.t) now locks:
  - direct-result `structural_rtl_ir` surfacing for generated `?fsm` roots,
  - stable direct-module boundary port metadata in that bounded structural slice,
  - and the effective system boundary (`clock` / `reset`) being preserved there when those ports are really part of the generated module contract.
- The next structural-consumption step is now also shipped:
  - realized generated-child interface planning now consumes `structural_rtl_ir` as its first boundary source of truth instead of rebuilding child ports only from signal analysis,
  - and that handoff explicitly normalizes low-level declaration types like `wire` / `logic` back into plain semantic data ports so composition type-matching does not accidentally tighten.
- [t/164-realized-child-interface-ports-from-structural-rtl-ir.t](/Users/richarddje/Documents/github/fsmgen/t/164-realized-child-interface-ports-from-structural-rtl-ir.t) now locks:
  - realized `?fsmc` child interface ports mirroring the child structural boundary summary,
  - realized `?dtc` child interface ports mirroring the child structural boundary summary,
  - and the structural-to-interface normalization boundary for generic `wire`-typed data ports.
- The next IR-to-IR handoff step is now also shipped:
  - composition-top `lowered_rtl_ir` now consumes `structural_rtl_ir` for internal-net names, realized-instance names, and auxiliary-assignment counts instead of rebuilding that bounded connectivity summary directly from the plan.
- [t/160-composition-top-forward-ir-surface.t](/Users/richarddje/Documents/github/fsmgen/t/160-composition-top-forward-ir-surface.t) now also locks:
  - composition-top `lowered_rtl_ir` internal-net counts/names mirroring `structural_rtl_ir`,
  - composition-top `lowered_rtl_ir` realized-instance counts/names mirroring `structural_rtl_ir`,
  - and composition-top `lowered_rtl_ir` auxiliary-assignment counts mirroring `structural_rtl_ir`.
- The next structural-consumption step is now also shipped:
  - composition-top `module_info` and `statistics` now consume `structural_rtl_ir` for child, top-port, and internal-net counts instead of rereading those bounded accounting fields directly from plan internals.
- [t/162-composition-top-structural-rtl-ir-surface.t](/Users/richarddje/Documents/github/fsmgen/t/162-composition-top-structural-rtl-ir-surface.t) now also locks:
  - composition-top `module_info` child/net counts mirroring `structural_rtl_ir`,
  - and composition statistics child/top-port/net counts mirroring `structural_rtl_ir`.
- The next IR-to-IR handoff step is now also shipped through top-level bookkeeping:
  - `module_info` now derives internal-net names/counts, instance names/counts, auxiliary-assignment count, and composition lane from `lowered_rtl_ir` / `intent_hir` instead of falling back straight to raw plan bookkeeping,
  - and `statistics` now derives composition lane and shared-datapath candidate count from `intent_hir` / `lowered_rtl_ir` instead of only carrying those fields straight from plan/runtime state.
- [t/160-composition-top-forward-ir-surface.t](/Users/richarddje/Documents/github/fsmgen/t/160-composition-top-forward-ir-surface.t) now also locks:
  - `module_info` internal-net names/counts, instance names/counts, and auxiliary-assignment count mirroring `lowered_rtl_ir`,
  - `module_info` composition lane mirroring `intent_hir`,
  - and composition statistics lane/shared-datapath candidate count mirroring `intent_hir` / `lowered_rtl_ir`.
- The next structural-consumption step is now also shipped through composition provenance:
  - `composition_report` now consumes `structural_rtl_ir` for top-port metadata and resolved-link endpoint lookup instead of rereading those bounded boundary/interface details directly from plan internals.
- [t/161-composition-provenance-origin-examples.t](/Users/richarddje/Documents/github/fsmgen/t/161-composition-provenance-origin-examples.t) now also locks:
  - provenance report top-port metadata mirroring `structural_rtl_ir`,
  - and resolved-link endpoint direction/width/type metadata mirroring child structural interface ports.
- The next structural widening step is now also shipped through declared connectivity:
  - composition-top `structural_rtl_ir` now preserves declared explicit-toplink connectivity separately through `declared_links` instead of only carrying the post-resolution link graph,
  - and block-event reasoning for explicit child links now consumes that structural declared-link surface instead of rereading declared toplinks directly from plan internals.
- [t/162-composition-top-structural-rtl-ir-surface.t](/Users/richarddje/Documents/github/fsmgen/t/162-composition-top-structural-rtl-ir-surface.t) and [t/106-composition-blocked-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/106-composition-blocked-reporting.t) now also lock:
  - structural declared-link identity/origin summaries,
  - and blocked undeclared-top inference reasoning aligned with `structural_rtl_ir->{declared_links}`.
- The next structural-consumption step is now also shipped through override/block reporting:
  - composition override/block event grouping and candidate-context lookup now consume `structural_rtl_ir` for top-port and child-interface metadata instead of rereading those same interface families directly from plan internals.
- [t/105-composition-override-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/105-composition-override-reporting.t) and [t/106-composition-blocked-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/106-composition-blocked-reporting.t) now also lock:
  - override/block event top-port and child-endpoint direction/width/type metadata mirroring `structural_rtl_ir`,
  - and internal-carrier re-export / kept-internal candidate contexts using the same structural interface metadata surface.
- The next IR-to-IR handoff step is now also shipped through composition-top semantic summaries:
  - composition-top `intent_hir` now consumes `structural_rtl_ir` for top-port names, counts, and grouped signal-analysis families,
  - and compatible top-level `module_info` signal metadata now mirrors that same structural top-port boundary instead of rebuilding it separately from plan internals.
- [t/160-composition-top-forward-ir-surface.t](/Users/richarddje/Documents/github/fsmgen/t/160-composition-top-forward-ir-surface.t) now also locks:
  - composition-top `intent_hir` signal names/counts mirroring `structural_rtl_ir`,
  - composition-top `intent_hir` grouped input/output signal-analysis families mirroring `structural_rtl_ir`,
  - and compatible `module_info` signal metadata mirroring the same structural top-port boundary.
- The next structural widening step is now also shipped through explicit resolved connectivity:
  - composition-top `structural_rtl_ir` now preserves resolved links as first-class structural connectivity entries alongside ports/nets/instances/bindings,
  - `composition_report` now derives its resolved-link identity/origin list from that structural layer instead of rereading plan-only link state,
  - and compatible top-level accounting now keeps resolved-link counts aligned with `structural_rtl_ir`.
- [t/162-composition-top-structural-rtl-ir-surface.t](/Users/richarddje/Documents/github/fsmgen/t/162-composition-top-structural-rtl-ir-surface.t) and [t/161-composition-provenance-origin-examples.t](/Users/richarddje/Documents/github/fsmgen/t/161-composition-provenance-origin-examples.t) now also lock:
  - structural resolved-link count and explicit source/target/origin connectivity,
  - provenance resolved-link identity/origin mirroring `structural_rtl_ir`,
  - and compatible module/statistics resolved-link counts aligned with that same structural layer.
- The next structural-consumption step is now also shipped through override/block resolved-link handling:
  - composition override events now take their explicit-toplink and inferred-reexport connectivity from `structural_rtl_ir->{resolved_links}`,
  - and the kept-internal internal-carrier block path now also derives its family detection from that same structural resolved-link surface instead of rereading resolved links from the plan.
- [t/105-composition-override-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/105-composition-override-reporting.t) and [t/106-composition-blocked-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/106-composition-blocked-reporting.t) now also lock:
  - override event source/target endpoints aligned with structural resolved-link entries,
  - re-export override source/top-port endpoints aligned with structural resolved-link entries,
  - and kept-internal carrier family detection aligned with structural resolved-link raw tokens.
- The next forward-IR widening step through the composition provenance/reporting surface is now also shipped:
  - `composition_report` now preserves per-resolved-link endpoint context instead of only raw endpoint strings,
  - those endpoint contexts now carry bounded forward child summaries when a resolved link touches a realized generated child endpoint,
  - and top-port / resolved-link provenance kinds now each preserve one stable example subject so non-quiet CLI composition summaries are no longer counts-only in that area.
- [t/161-composition-provenance-origin-examples.t](/Users/richarddje/Documents/github/fsmgen/t/161-composition-provenance-origin-examples.t) now locks:
  - preservation of resolved-link source/target endpoint context in `composition_report`,
  - preservation of child `intent_hir` and `lowered_rtl_ir` through those generated-child endpoint contexts,
  - preservation of `port_origin_examples` and `resolved_link_origin_examples`,
  - and the matching non-quiet CLI provenance example lines.
- The next forward-IR widening step through the composition override/block reporting surface is now also shipped:
  - override and block events now preserve structured top-port / child-endpoint context instead of only flat signal names,
  - those generated-child endpoint contexts now carry bounded `intent_hir` / `lowered_rtl_ir` child summaries,
  - and non-quiet CLI override/block sections now print richer link/endpoint examples instead of count-plus-name examples only.
- [t/105-composition-override-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/105-composition-override-reporting.t) and [t/106-composition-blocked-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/106-composition-blocked-reporting.t) now also lock:
  - preservation of structured source/target / candidate endpoint context in override/block events,
  - preservation of child `intent_hir` and `lowered_rtl_ir` through generated-child endpoint examples,
  - and the matching richer non-quiet CLI override/block example lines.
- The next forward-IR widening step through the broader composition child semantic surface is now also shipped:
  - composition-top `intent_hir` now carries one unified `composition_child_count` / `composition_children` export across all realized child kinds (`?fsmc`, `?dtc`, and `?rtl`),
  - compatible top-level `module_info` now mirrors that same unified child export instead of leaving child identity split across narrower side channels only,
  - those unified child entries preserve stable child identity together with each realized child's `intent_hir`, `lowered_rtl_ir`, and `structural_rtl_ir` summaries when present,
  - and composition provenance / override / block endpoint context lookup now consumes that unified semantic child export instead of rereading realized child identity only from plan instances.
- [t/165-composition-child-forward-ir-exports.t](/Users/richarddje/Documents/github/fsmgen/t/165-composition-child-forward-ir-exports.t) now locks:
  - preservation of mixed generated-child plus RTL child order/kind/root identity through `composition_children`,
  - preservation of child `intent_hir`, `lowered_rtl_ir`, and `structural_rtl_ir` through that unified child export when present,
  - and reuse of that same unified child semantic surface in override/reporting endpoint context.
- The next structural-consumption step is now also shipped through the unified composition child export itself:
  - `composition_children` now derives child identity and order from `structural_rtl_ir->{instances}` instead of rereading realized child identity directly from `composition_plan->instances`,
  - and the narrower generated-child and reusable standalone-DT export builders now reuse that same computed child surface in the top-generation path instead of each rebuilding it again.
- [t/165-composition-child-forward-ir-exports.t](/Users/richarddje/Documents/github/fsmgen/t/165-composition-child-forward-ir-exports.t) now also locks:
  - unified child identity and order aligned with `structural_rtl_ir->{instances}`,
  - while keeping the existing mixed child-kind/root and forward-IR export surface stable.
- The next narrowing step is now also shipped through the generated-child export path:
  - the narrower `composition_generated_children` export now derives from the broader semantic `composition_children` layer,
  - so generated-child export identity no longer gets reconstructed separately from plan instances,
  - and the existing generated-child surface stays stable while depending more directly on the explicit forward semantic layer.
- [t/158-composition-generated-child-forward-ir-exports.t](/Users/richarddje/Documents/github/fsmgen/t/158-composition-generated-child-forward-ir-exports.t) now also locks:
  - `composition_generated_children` as the filtered semantic view over `composition_children`,
  - while keeping the existing generated-child forward IR surface stable.
- The sibling narrowing step is now also shipped through the reusable standalone-DT export path:
  - the narrower `composition_standalone_dt_children` export now derives from the broader semantic `composition_children` layer,
  - so reusable standalone-DT child export identity no longer gets reconstructed separately from plan instances,
  - child standalone-DT names and enable families now come from child `intent_hir`, grouped multi-drive targets now come from child `lowered_rtl_ir`,
  - and the existing reusable standalone-DT export surface stays stable while depending more directly on the explicit forward semantic and lowered layers.
- [t/157-composition-standalone-dt-forward-ir-exports.t](/Users/richarddje/Documents/github/fsmgen/t/157-composition-standalone-dt-forward-ir-exports.t) now also locks:
  - `composition_standalone_dt_children` as the filtered reusable standalone-DT view over `composition_children`,
  - derivation of standalone-DT names and enable families from child `intent_hir`,
  - derivation of grouped standalone-DT multi-drive targets from child `lowered_rtl_ir`,
  - while keeping the existing reusable standalone-DT export surface stable.
- The next lowering step is now also shipped through shared-datapath candidate discovery:
  - shared-datapath candidate discovery now consumes `structural_rtl_ir` for top-output / child-interface connectivity instead of rereading those bounded families directly from plan ports/instances,
  - contributor identity and lowered contributor context now come from the unified semantic `composition_children` export,
  - and the existing candidate surface stays behaviorally the same while depending less on ad hoc plan crawling inside `HDLGenerator`.
- [t/139-composition-shared-datapath-candidate-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/139-composition-shared-datapath-candidate-metadata.t) and [t/159-composition-shared-datapath-forward-ir-exports.t](/Users/richarddje/Documents/github/fsmgen/t/159-composition-shared-datapath-forward-ir-exports.t) now also lock:
  - shared-datapath candidate top-output bindings aligned with structural output-port metadata,
  - and contributor `intent_hir` / `lowered_rtl_ir` / `structural_rtl_ir` aligned with the unified `composition_children` export.
- The first shared-datapath candidate-discovery slice is now also shipped:
  - composition-top `module_info` now reports `composition_shared_datapath_candidate_count` and `composition_shared_datapath_candidates`,
  - those candidate families are currently bounded to same-name output families across multiple realized `?fsmc` children that agree on width and interface type,
  - generated roots and realized generated children now also report `output_drive_family_count` and `output_drive_families` in `module_info`,
  - each shared-datapath candidate now carries contributor instance/module/endpoint identity plus any current top-output bindings,
  - and those contributors now also carry one bounded `drive_intent` summary with mux type, driver blocks, RHS families, and enable-signal families,
  - each shared-datapath candidate now also carries one deterministic whole-target aggregate enable plus per-value aggregate enable families built from the child-local `P_Q` families,
  - realized `?fsmc` children now also carry hidden shared-datapath source-export metadata for those per-value enable families,
  - and generated composition tops now also synthesize the first actual shared-datapath helper HDL from that surface through hidden child source-enable export bindings plus per-value/whole-target aggregate and conflict wires,
  - and SystemVerilog composition tops now also emit the first actual shared-datapath assertion HDL from that surface through non-synthesis same-value and whole-target conflict guards while Verilog stays free of emitted assertion syntax,
  - and those candidate families now also carry first lifted-ownership planning metadata through storage-class, peer-read endpoint, default lifted visibility, planned top re-export, and loopback-policy fields,
  - and those candidate families now also carry explicit peer-read policy metadata for bounded combinational peer-read cases, distinguishing public-preserving top-output-only families from internal-only top-local carrier families instead of making them look loopback-eligible,
  - and the bounded combinational peer-read public-preserving case now also realizes a first top-facing shared-carrier runtime through one emitted shared combinational carrier plus peer-input rebinding and preserved top-output re-export assignments,
  - and the sibling bounded combinational peer-read internal-only case now also realizes a first top-local shared-carrier runtime through one emitted shared combinational carrier plus peer-input rebinding without invented public top re-export assignments,
  - and the sibling bounded combinational public-only fanout case now also realizes that shared-carrier runtime through the same emitted shared combinational carrier plus preserved public top-output fanout without requiring peer-read child inputs,
  - and the bounded registered peer-read public-preserving case now also realizes the first actual lifted shared-target behavior through one emitted shared top-level register plus peer-input rebinding and preserved top-output re-export assignments, including mixed public/internal carrier families,
  - and the sibling bounded registered peer-read internal-only case now also realizes that lifted shared-target behavior through the same emitted shared register plus peer-input rebinding without inventing public top re-export assignments,
  - and the sibling bounded registered public-only fanout case now also realizes that lifted shared-target behavior through the same emitted shared register plus preserved public top-output fanout without requiring peer-read child inputs,
  - and non-quiet `bin/fsmgen` composition runs now print one concise `Shared-Datapath Candidates` summary section from that metadata surface.
- [t/139-composition-shared-datapath-candidate-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/139-composition-shared-datapath-candidate-metadata.t) now locks:
  - composition-top shared-datapath candidate metadata for multi-`?fsmc` tops,
  - the first single-driver `drive_intent` form inside those candidate contributors,
  - and the matching non-quiet CLI summary.
- [t/140-composition-shared-datapath-drive-intent-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/140-composition-shared-datapath-drive-intent-metadata.t) now locks:
  - realized generated-child `output_drive_families` metadata for a multi-driver output family,
  - shared-datapath candidate contributor `drive_intent` metadata for that same multi-driver family,
  - and the matching per-child drive-intent CLI summary lines.
- [t/141-composition-shared-datapath-aggregate-enable-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/141-composition-shared-datapath-aggregate-enable-metadata.t) now locks:
  - shared-datapath candidate whole-target aggregate enable naming,
  - per-value aggregate enable family metadata for both single-contributor and shared-value cases,
  - the first planned same-value and cross-value conflict-bit names on top of that aggregate surface,
  - and the matching non-quiet CLI aggregate-enable/conflict summary lines.
- [t/142-composition-shared-datapath-assertion-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/142-composition-shared-datapath-assertion-metadata.t) now locks:
  - deterministic per-child shared-datapath source-enable aliases for shared-value families,
  - onehot0-style same-value assertion metadata over those source-enable aliases,
  - onehot0-style whole-target assertion metadata over aggregate value enables,
  - and the matching non-quiet CLI assertion-planning summary lines.
- [t/143-composition-shared-datapath-visibility-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/143-composition-shared-datapath-visibility-metadata.t) now locks:
  - peer-read endpoint metadata for shared registered output families,
  - internal-by-default lifted visibility planning for those registered peer-read families,
  - planned top re-export metadata for the still-top-visible public outputs,
  - loopback-allowed planning for that bounded registered case,
  - registered loopback-eligible peer-read policy metadata for that bounded case,
  - and the matching non-quiet CLI visibility-planning summary lines.
- [t/144-composition-shared-datapath-combinational-peer-read-policy.t](/Users/richarddje/Documents/github/fsmgen/t/144-composition-shared-datapath-combinational-peer-read-policy.t) now locks:
  - public-preserving top-output-only peer-read policy metadata for shared combinational output families,
  - the surfaced top-facing combinational peer-read constraint,
  - and the matching non-quiet CLI peer-read-policy summary lines.
- [t/149-composition-shared-datapath-combinational-runtime.t](/Users/richarddje/Documents/github/fsmgen/t/149-composition-shared-datapath-combinational-runtime.t) now locks:
  - lifted-runtime metadata for the bounded combinational peer-read public-preserving case,
  - the emitted shared top-facing combinational carrier and value-family mux logic for that case,
  - peer-read child-input rebinding to that shared combinational carrier,
  - preserved top-output re-export assignments from that carrier,
  - and the matching non-quiet CLI lifted-runtime summary lines.
- [t/150-composition-shared-datapath-combinational-internal-runtime.t](/Users/richarddje/Documents/github/fsmgen/t/150-composition-shared-datapath-combinational-internal-runtime.t) now locks:
  - top-local peer-read policy metadata for the bounded internal-only combinational shared family,
  - the emitted shared top-local combinational carrier and value-family mux logic for that case,
  - peer-read child-input rebinding to that shared combinational carrier across multiple consumers,
  - absence of invented public top re-export assignments for that internal-only runtime,
  - and the matching non-quiet CLI lifted-runtime summary lines.
- [t/153-composition-shared-datapath-combinational-public-fanout-runtime.t](/Users/richarddje/Documents/github/fsmgen/t/153-composition-shared-datapath-combinational-public-fanout-runtime.t) now locks:
  - lifted-runtime metadata for the bounded combinational public-only fanout case,
  - the emitted lifted shared combinational carrier runtime for that no-peer-read sibling case,
  - preserved public top-output fanout assignments from the lifted carrier,
  - and the matching non-quiet CLI summary lines.
- [t/145-composition-shared-datapath-runtime-hdl.t](/Users/richarddje/Documents/github/fsmgen/t/145-composition-shared-datapath-runtime-hdl.t) now locks:
  - hidden realized-`?fsmc` source-enable export metadata for shared-datapath per-value families,
  - hidden child export-port injection in generated child HDL,
  - top-level binding of those hidden exports into deterministic per-child source-enable alias nets,
  - and generated composition-top aggregate/conflict helper HDL for shared-datapath families.
- [t/151-composition-shared-datapath-assertion-runtime-hdl.t](/Users/richarddje/Documents/github/fsmgen/t/151-composition-shared-datapath-assertion-runtime-hdl.t) now locks:
  - emitted SystemVerilog same-value and whole-target shared-datapath guard assertions in generated composition tops,
  - and absence of that assertion emission on the Verilog target.
- [t/146-composition-shared-datapath-lifted-register-runtime.t](/Users/richarddje/Documents/github/fsmgen/t/146-composition-shared-datapath-lifted-register-runtime.t) now locks:
  - reset-aware shared-datapath candidate metadata for the bounded registered peer-read public-preserving case,
  - the emitted shared top-level register and next-value logic for that case,
  - peer-read child-input rebinding to the lifted shared register,
  - preserved top-output re-export assignments from the lifted shared register,
  - and the matching non-quiet CLI lifted-runtime summary lines.
- [t/147-composition-shared-datapath-internal-lifted-register-runtime.t](/Users/richarddje/Documents/github/fsmgen/t/147-composition-shared-datapath-internal-lifted-register-runtime.t) now locks:
  - reset-aware shared-datapath candidate metadata for the bounded registered peer-read internal-only case,
  - the emitted shared top-level register and next-value logic for that sibling case,
  - peer-read child-input rebinding to the lifted shared register,
  - absence of invented public re-export assignments for that internal-only runtime,
  - and the matching non-quiet CLI lifted-runtime summary lines.
- [t/148-composition-shared-datapath-mixed-reexport-runtime.t](/Users/richarddje/Documents/github/fsmgen/t/148-composition-shared-datapath-mixed-reexport-runtime.t) now locks:
  - mixed-boundary shared-datapath candidate metadata for the bounded registered public-preserving case,
  - peer-read endpoint filtering down to only inputs actually bound to contributor carriers,
  - the emitted lifted shared-register runtime for one-public-one-internal contributor families,
  - preserved public top re-exports without invented internal-carrier re-export assignments,
  - and the matching non-quiet CLI summary lines.
- [t/152-composition-shared-datapath-public-fanout-register-runtime.t](/Users/richarddje/Documents/github/fsmgen/t/152-composition-shared-datapath-public-fanout-register-runtime.t) now locks:
  - lifted-runtime metadata for the bounded registered public-only fanout case,
  - the emitted lifted shared-register runtime for that no-peer-read sibling case,
  - preserved public top-output fanout assignments from the lifted register,
  - and the matching non-quiet CLI summary lines.
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
- The next bounded reporting refinement is now also shipped:
  - `composition_report` now keeps one concise example subject for each shipped override kind and block kind instead of stopping at counts only,
  - those example subjects now also flow through `module_info` and `statistics` via the same carried `composition_provenance` payload,
  - and non-quiet `bin/fsmgen` runs now print those examples inline with the existing `Convention Overrides` and `Convention Blocks` counts.
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
- The stale compatibility wording in `bin/fsmgen` help/usage output is now retired for the active CLI path:
  - built-in help now names `./bin/fsmgen` instead of the old `generate_fsm_hdl.pl` wrapper,
  - built-in examples now use the active entrypoint consistently,
  - and help text now describes the default output location as the current working directory, which matches the shipped runtime.
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
  - direct child-owned outputs vs multiply-assigned lifted shared-datapath targets beyond the now-shipped discovery/metadata/helper/runtime/assertion slices,
  - lifted shared-target mux/register ownership beyond the now-shipped registered peer-read public-preserving, mixed-boundary, internal-only, and public-fanout slices,
  - public re-export/default-visibility policy beyond the now-shipped bounded registered peer-read/public-fanout cases and combinational peer-read/public-fanout cases,
  - and realized combinational behavior beyond the now-shipped bounded peer-read public-preserving, internal-only, and public-fanout slices.
- Turn the reusable standalone-DT/module-library direction into a real contract:
  - decide whether unnamed reusable DT roots such as `?dt:` exist at all,
  - extend the current shipped `?dt:name` interface rule into a fuller reusable-module contract beyond the now-shipped multi-block enable, grouped shared-target, assertion, and composition-facing child-export metadata surfaces,
  - define how multi-`(-foo ...)` standalone DT modules expose block-level and module-level enable families beyond those current metadata/export summaries,
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
  - and keep any such convention top-boundary-oriented rather than turning child-to-child wiring into hidden inference everywhere.
- Track and later retire the current architectural hotspot set deliberately instead of letting it stay ambient debt:
  - widen the now-shipped first `Intent HIR` extraction slice beyond direct generated roots, realized generated children, the standalone-DT composition-export surface, the broader generated-child composition-export surface, and the shared-datapath candidate contributor surface into the rest of the forward pipeline,
  - widen the now-shipped first explicit `Lowered RTL IR` extraction slice beyond generated output-drive families, standalone-DT grouped multi-drive targets, the standalone-DT composition-export surface, the broader generated-child composition-export surface, and the shared-datapath candidate contributor surface into the rest of the forward pipeline,
  - start one bounded `Structural RTL IR` / connectivity extraction so explicit ports, nets, instances, pin bindings, and full top/child wiring stop living only in composition plans and backend-adjacent emitter code,
  - keep that `Structural RTL IR` backend-neutral, expressive, and extensible enough for rich top/child wiring, with child actual-pin connections growing as typed structural connection expressions / actual-connection AST nodes instead of raw HDL strings,
  - normalize any backend-specific or inelegant connection shape into helper nets / auxiliary assignments before it reaches the structural binding boundary,
  - keep those forward IR layers aligned with the future shared-middle/import architecture instead of allowing a second incompatible semantic stack to form,
  - split composition policy, interface inference, and top emission back out of `FSM::Pipeline::HDLGenerator`,
  - shrink `FSM::Synthesis::EnableGraph` toward a clearer synthesis boundary,
  - move planning/normalization residue out of `FSM::HDL::FlattenedDT::Backend::SystemVerilog` so backend responsibilities are more honest,
  - make the `FSM::CoreAST::*` versus `FSM::AST::*` bridge explicit instead of rediscovering it inside `EnableGraph`,
  - decide whether `FSM::ExpressionNamer` remains live architectural surface or should be retired as compatibility residue,
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
- `R11`: `StructuralRTLIR` connection expressions now cover bounded indexed and
  sliced signal forms in addition to plain `signal_ref`, with the composition
  emitter walking those typed forms through the current Verilog-family backend.
- `R11`: `StructuralRTLIR` connection expressions now also cover bounded concat
  forms over nested operands, with the composition emitter walking those typed
  actual-connection nodes directly through the current Verilog-family backend.
- `R11`: those already-shipped bounded `bit_select`, `slice`, and `concat`
  forms now also render honestly through the current VHDL helper path,
  including `downto`/`to` slice direction and VHDL `&` concatenation, so the
  structural AST is a bit more genuinely cross-backend instead of only looking
  portable on paper.
- `R11`: `StructuralRTLIR` connection expressions now also expose recursive
  referenced-signal discovery, and composition consumers are starting to use
  that richer dependency surface instead of assuming every binding is one flat
  signal name.
- `R11`: `StructuralRTLIR` connection expressions now also cover bounded
  bit-vector literal actuals, so the structural connection AST can represent
  simple constant tie-offs without falling back to raw HDL strings.
- `R11`: `StructuralRTLIR` connection expressions now also cover explicit
  backend-neutral `open` actuals, so the structural connection AST can model
  intentionally unconnected child formals without using raw backend syntax.
- `R11`: `StructuralRTLIR` connection expressions now also cover bounded
  `member_access` actuals, so the structural connection AST has started the
  richer aggregate/member connectivity lane without falling back to raw HDL
  strings.
- `R11`: `StructuralRTLIR` connection expressions now also cover bounded
  `index_access` actuals, so the structural connection AST has started the
  fixed-size array/index connectivity lane too.
- `R11`: structural consumers that still need one flat carrier name now also
  distinguish that leaf-only case from the broader dependency lists exposed by
  richer structural connection expressions.
