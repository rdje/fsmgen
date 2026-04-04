# MEMORY
This is the live continuity document for fast session recovery after crashes, restarts, or agent handoffs.
## 2026-04-04: future structured HDL mode should branch at the backend, with flattened staying default
- Recorded one future-steering note for generated-module emission.
- Important continuity note:
  - a second selectable HDL generation route that preserves FSM/DT control structure now looks architecturally plausible,
  - flattened generation should stay the default mode and current debug-first path,
  - the clean future branch point is [perl/FSM/Backend/GeneratedModuleEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Backend/GeneratedModuleEmitter.pm), with [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) and [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) carrying one future generation-style option,
  - and the semantic frontend, validations, provenance, and forward IR layers should stay shared so the two modes differ in HDL shape, not in accepted semantics.

## 2026-04-04: next likely structural-actual widening is unsized decimal/hex direct bindings, not looser exact-width coercion
- Recorded one steering decision for the next `R11` sibling after the shipped scalar `=0` / `=1` widening.
- Important continuity note:
  - unsized positive decimal and hex direct actuals now look like the next honest widening for [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm): treat them as numeric values, widen them to the direct binding target width, and fail explicitly on overflow,
  - exact-width forms such as `=8'd5` and `=8'hA5` should remain exact-width contracts instead of being silently widened again,
  - and bounded concat operands should stay stricter than direct bindings unless a later slice opens a separate concat-numeric inference contract on purpose.

## 2026-04-04: direct scalar `=0` and `=1` actuals now widen to direct binding targets
- Stayed in the active `R11` lane and kept this as the next honest structural-actual refinement instead of switching away from feature work while the planner path was already localized.
- Important continuity note:
  - [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm) now treats direct explicit-actual sources `=0` and `=1` as scalar numeric zero/one sources that widen to the realized child-input or declared top-output target width instead of behaving like accidental one-bit-only direct bindings,
  - bounded concat operands still keep `=0` / `=1` as one-bit operands unless the author spells an exact-width literal there, so the widening stays on the direct-binding path rather than silently changing concat semantics too,
  - [t/262-composition-structural-actual-toplinks.t](/Users/richarddje/Documents/github/fsmgen/t/262-composition-structural-actual-toplinks.t) now locks widened scalar direct actuals on child inputs and declared top outputs,
  - [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now keeps the family wording honest by saying the shipped structural-actual slice covers `=open`, scalar `=0` / `=1`, and exact-width binary/decimal/hex literal actuals,
  - and `=open` remains the only child-input-only sibling in that family because “unconnected” is still not honest top-output wiring.

## 2026-04-04: direct literal actuals may now drive declared top outputs too
- Stayed in the active `R11` lane and kept this as the next honest sibling after the shipped top-expression/top-output slice instead of switching back to hardening-only work.
- Important continuity note:
  - [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm) now emits direct top-output assignments for literal actual sources such as `=0`, `=1`, `=8'b10100101`, `=8'd165`, and `=8'hA5` instead of limiting those direct actual tokens to realized child-input bindings,
  - that means direct literal actuals and bounded concat operands now both reach declared top outputs through the same typed structural-expression/rendering path rather than splitting into “concat can, direct actual cannot,”
  - [t/262-composition-structural-actual-toplinks.t](/Users/richarddje/Documents/github/fsmgen/t/262-composition-structural-actual-toplinks.t) now locks direct linked-plan plus pipeline/CLI success for literal-actual top-output assignments,
  - [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now keeps the still-blocked sibling honest by locking `=open`-to-top-output as the remaining explicit-actual source-role failure,
  - `=open` remains child-input-only on purpose because a declared top output still needs a concrete driven expression,
  - and the next honest sibling after this slice is no longer “actual-source to top-output” in general, but rather whether any broader non-literal explicit-actual family is worth opening at all.

## 2026-04-04: source-side top expressions may now drive top outputs directly too
- Stayed in the active `R11` lane and kept this as another expression/top-boundary feature slice rather than widening actual-source rules at the same time.
- Important continuity note:
  - [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm) now emits direct top-output assignments from source-side top-port bit/slice and bounded concat expressions instead of blocking those expressions at the top boundary,
  - sibling child-input consumers may still reuse those same typed expressions in the same top without synthetic carrier nets, so direct child-input and direct top-output expression uses now share one planner path,
  - [t/263-composition-toplink-top-expressions.t](/Users/richarddje/Documents/github/fsmgen/t/263-composition-toplink-top-expressions.t) and [t/267-composition-top-expression-top-outputs.t](/Users/richarddje/Documents/github/fsmgen/t/267-composition-top-expression-top-outputs.t) now lock the linked-plan plus pipeline/CLI contract for that widened top-boundary expression slice,
  - the old “direct actual-source to top-output” sibling is now partially closed by the later literal-actual slice, with `=open` still intentionally excluded there,
  - and the next honest sibling beyond these top-boundary expression/actual slices is now likely another structural-actual or shared-boundary widening rather than more top-expression hardening.

## 2026-04-04: declared top inputs may now fan out directly to top outputs too
- Stayed in the active `R11` lane and kept this as another feature slice instead of circling back into summary-only or hardening-only work.
- Important continuity note:
  - [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm) now allows one declared top input to drive one or more top outputs directly through explicit top-output assignments while sibling child-input consumers reuse that same top input without a synthetic helper carrier,
  - [perl/FSM/Composition/SharedDatapathSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/SharedDatapathSupport.pm) now preserves those preexisting auxiliary assignments when shared-datapath runtime rewriting is also active instead of overwriting them later,
  - [t/176-composition-linked-plan-builder.t](/Users/richarddje/Documents/github/fsmgen/t/176-composition-linked-plan-builder.t) and [t/266-composition-top-input-top-output-fanout.t](/Users/richarddje/Documents/github/fsmgen/t/266-composition-top-input-top-output-fanout.t) now lock the direct linked-plan and mixed-runtime pipeline/CLI contract for that widened topology,
  - [t/109-composition-explicit-link-topology-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/109-composition-explicit-link-topology-diagnostics.t) and [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) no longer expect the old blocked top-input-to-top-output failure family,
  - the remaining blocked sibling in this narrower topology family is still source-side top-expression directly to top-output, not plain declared top-input fanout,
  - and the full regression stayed green after the slice (`Files=261`, `Tests=1978`, `PASS`).

## 2026-04-04: one child source may now fan out to multiple top outputs in explicit-link tops
- Stayed in the active `R11` lane and kept this as another real composition-feature widening before returning to hardening-only work.
- Important continuity note:
  - [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm) now realizes one child output source driving multiple top outputs through one deterministic shared carrier net plus explicit top-output assignments instead of blocking that topology,
  - sibling child-input consumers in the same explicit-link top now reuse that same carrier net instead of forcing one public top output to double as the internal carrier,
  - [t/176-composition-linked-plan-builder.t](/Users/richarddje/Documents/github/fsmgen/t/176-composition-linked-plan-builder.t) and [t/265-composition-multi-top-output-fanout.t](/Users/richarddje/Documents/github/fsmgen/t/265-composition-multi-top-output-fanout.t) now lock the linked-plan and end-to-end pipeline/CLI contract for that widened topology,
  - [t/109-composition-explicit-link-topology-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/109-composition-explicit-link-topology-diagnostics.t) and [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) no longer expect the old blocked multi-top-output failure family,
  - and the still-blocked explicit-link topology sibling remains top-input directly to top-output, not child-output fanout.

## 2026-04-04: exact-width decimal actuals now ride the same structural literal path
- Stayed in the active `R11` lane and kept this as another bounded structural-actual widening rather than introducing a new connection-expression family.
- Important continuity note:
  - [perl/FSM/Composition/LinkedPlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/LinkedPlanBuilder.pm) now accepts exact-width decimal literal actuals such as `=8'd165` beside the existing binary and hex forms, normalizing them into the same `bit_vector_literal_expr` payload used throughout the structural binding path,
  - the same exact-width decimal literal family now also works inside bounded source-side concat operands, so direct child-input actuals and concat-literal operands still share one backend-neutral literal contract,
  - unsized decimal-like spellings still fail explicitly, and decimal payloads whose numeric value exceeds the declared width now fail explicitly instead of truncating,
  - [t/262-composition-structural-actual-toplinks.t](/Users/richarddje/Documents/github/fsmgen/t/262-composition-structural-actual-toplinks.t), [t/264-composition-toplink-concat-expressions.t](/Users/richarddje/Documents/github/fsmgen/t/264-composition-toplink-concat-expressions.t), and [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now lock the widened direct/concat/summary contract,
  - and the full regression stayed green after the slice (`Files=259`, `Tests=1980`, `PASS`).

## 2026-04-02: explicit-actual failure summaries now keep the actual token context too
- Stayed in the active `R11` lane, but kept this as a follow-on contract-hardening slice rather than a new runtime-capability widening.
- Important continuity note:
  - [perl/FSM/Composition/FailureReportBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/FailureReportBuilder.pm) now recognizes the shipped structural-actual diagnostic wording directly, so blocked `?toplink` failures that say `uses actual source '...'` or `uses actual endpoint '...'` surface bounded `Actual source '...'` or `Actual endpoint '...'` context lines in the non-quiet composition failure summary,
  - [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now locks both the pipeline and CLI summary shape for blocked literal-source role failures and blocked actual-endpoint target failures on that explicit-toplink path,
  - this does not widen runtime support beyond the already-shipped `=open` / `=0` / `=1` / exact-width `=N'b...` child-input binding slice,
  - and the full regression stayed green after the summary-only follow-up (`Files=257`, `Tests=1959`, `PASS`).

## 2026-04-02: README quick-start and import-tree note now match the live runtime again
- Stayed on a documentation-honesty slice instead of changing roadmap state after executing the current README workflow end-to-end.
- Important continuity note:
  - [README.md](/Users/richarddje/Documents/github/fsmgen/README.md), [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md), and [WARP.md](/Users/richarddje/Documents/github/fsmgen/WARP.md) now point their debug/known-good example commands at [fsm/lte_dif_pmaster.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/lte_dif_pmaster.fsm) instead of the stale [fsm/trial_1.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/trial_1.fsm) quick-start reference,
  - the trigger for that refresh was a live README execution pass: the first two `trial_0` commands still succeeded, but the old `trial_1` debug example now fails on unsupported `!&` operator residue while the documented support boundary no longer claims that operator,
  - [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) is now refreshed against the current 2026-04-02 static import walk, keeping the measured reachable set at `97` project files / `96` packages while updating the stale line-count snapshot (`bin/fsmgen` now `820`, [perl/FSM/Pipeline/SourceGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceGenerationOrchestrator.pm) now `152`, [perl/FSM/Synthesis/EnableGraph/AssignmentSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph/AssignmentSupport.pm) now `1320`, and related entries),
  - and the documented local regression entrypoint still finished green after this doc-only slice (`Files=256`, `Tests=1950`, `PASS`), so the continuity update is about documentation/runtime alignment rather than a new behavior change.

## 2026-04-02: strict mode now narrows the direct module-root alias family too
- Switched back into `R9` after the recent `R10` diagnostics slice so the support-tier lane keeps moving alongside the visible diagnostics work.
- Important continuity note:
  - [perl/FSM/Pipeline/SourceFrontend.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceFrontend.pm) now rejects the long direct-root alias `?module:` in strict mode and points users to canonical `?mod:module_name`,
  - default mode still accepts `?module:` on the current shared single-module path as a compatibility alias,
  - this does not collapse module roots into `?dt:` and does not reopen the broader module-root semantics you clarified earlier; it only narrows one alias family in the strict lane,
  - and [t/240-strict-mode-standalone-dt-alias-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/240-strict-mode-standalone-dt-alias-boundary.t) now locks the split through shared-frontend, pipeline, and CLI coverage while keeping the earlier `?dtc` child-root strict boundary intact.

## 2026-04-02: missing composition lookup failures now keep explicit search-root context too
- Switched back into a visible `R10` slice after the recent `R12` corpus widening so the diagnostics lane keeps moving in a user-facing way.
- Important continuity note:
  - [perl/FSM/Composition/GeneratedChildRealizer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GeneratedChildRealizer.pm) now promotes missing external `?fsmc` / `?dtc` lookup details into explicit `Search roots:` and `Searched locations:` lines alongside the earlier `Source file:` and `Expected child source file:` labels,
  - [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm) now does the same for missing external `.rtlif` lookup through an explicit `Search roots:` line beside `Source file:` and `Expected RTL metadata file:`,
  - [perl/FSM/Composition/FailureReportBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/FailureReportBuilder.pm) plus [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) now surface that same `Search roots:` context inside the non-quiet composition failure summary without displacing the earlier artifact or child-context lines,
  - and [t/115-composition-child-source-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/115-composition-child-source-diagnostics.t), [t/117-composition-rtlif-metadata-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/117-composition-rtlif-metadata-diagnostics.t), [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t), [t/255-composition-missing-rtl-metadata-diagnostic-context.t](/Users/richarddje/Documents/github/fsmgen/t/255-composition-missing-rtl-metadata-diagnostic-context.t), and [t/256-composition-missing-child-source-artifact-context.t](/Users/richarddje/Documents/github/fsmgen/t/256-composition-missing-child-source-artifact-context.t) now lock both the raw and summarized shape.

## 2026-04-02: regression corpus now counts partial-write support as named supported features
- Switched lanes deliberately into `R12` so the new partial indexed/sliced LHS support does not live only in focused contract tests.
- Important continuity note:
  - [t/corpus/partial_lhs_with_size.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/partial_lhs_with_size.fsm) and [t/corpus/partial_lhs_inferred_width.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/partial_lhs_inferred_width.fsm) now exist as stable corpus fixtures for the supported partial-write surface,
  - [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm) now records them as `feature.partial_lhs_with_size` and `feature.partial_lhs_inferred_width` under `supported_smoke`,
  - [t/261-regression-corpus-supported-language-features.t](/Users/richarddje/Documents/github/fsmgen/t/261-regression-corpus-supported-language-features.t) now checks those entries through both pipeline and CLI while also locking key HDL-shape expectations,
  - and this means the supported side of `R12` is no longer only imported protocol seeds; it now also includes shipped language features with explicit semantic-output checks.

## 2026-04-02: static numeric partial LHS writes now lower correctly through the direct backend
- Continued with a visible language/correctness slice instead of more backend-only decomposition.
- Important continuity note:
  - the parser had already accepted static numeric indexed/sliced LHS targets such as `SIG[3]` and `SIG[7:0]`, but the direct enable/mux path had still been collapsing those writes onto the base signal name too early,
  - [perl/FSM/Synthesis/EnableGraph/AssignmentSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph/AssignmentSupport.pm) now normalizes same-context partial writes into one full-width effective assignment family before RHS grouping, WEN/EN shaping, and mux emission,
  - that means same-context piecewise combinational writes now assemble into one full-width mux input, and same-context piecewise `<-` / `<=` writes now assemble into one full-width sequential mux input too,
  - partial sequential writes that leave some bits untouched now retain those bits through the right feedback source (`Q` for `<-`, `_q` for `<=`) instead of replacing the whole signal,
  - [t/258-partial-lhs-assignment-lowering.t](/Users/richarddje/Documents/github/fsmgen/t/258-partial-lhs-assignment-lowering.t) now locks the shipped contract for `=`, `<-`, and `<=`,
  - and the full suite stayed green after the fix (`Files=253`, `Tests=1928`, `PASS`), so this is now real supported behavior rather than only parsed syntax.

## 2026-04-02: partial dual-output writes now keep full-width auxiliary outputs too
- Continued the same visible language/correctness lane because the first partial-LHS fix still left `<-=` / `<=+` auxiliary outputs narrowed to the fragment width in the emitted module ports.
- Important continuity note:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now derives a base-signal width for indexed/sliced LHS targets from the registered signal width plus the slice/index bounds,
  - that base width is now fed back into the signal registry itself and into the dual-output auxiliary ports for `<-=` and `<=+`,
  - so partial writes such as `(ROD[3:2] <-= HI)` and `(RID[3:2] <=+ HI)` now keep `next_ROD` and `RID_r` at the full base-signal width instead of narrowing them to the fragment width,
  - [t/259-partial-dual-output-lhs-lowering.t](/Users/richarddje/Documents/github/fsmgen/t/259-partial-dual-output-lhs-lowering.t) now locks that contract for both `+size`-before-state and `+size`-after-state ordering,
  - and this closes the honest support gap that was still left after the earlier `=`, `<-`, `<=` partial-write slice.

## 2026-04-02: partial target width inference is now regression-backed without +size too
- Continued with one small contract-hardening follow-up instead of leaving the new partial-write support dependent on a one-off manual HDL probe.
- Important continuity note:
  - [t/260-partial-target-width-inference.t](/Users/richarddje/Documents/github/fsmgen/t/260-partial-target-width-inference.t) now locks the no-`+size` case where the base signal width must come only from the static slice/index bounds,
  - that regression covers slice-only partial targets such as `OUT[3:2]` and index-only partial targets such as `IDXOUT[4]`,
  - and it explicitly keeps full-width internal declarations plus full-width `next_*` / `*_r` auxiliary outputs regression-backed in those inference-only cases too.

## 2026-04-02: strict mode now rejects the compact top-level `:=` directive too
- Continued the visible `R9` lane by widening strict mode into another section-level compatibility cut instead of staying only on root families and `+system` residue.
- Important continuity note:
  - [perl/FSM/Pipeline/SourceFrontend.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceFrontend.pm) now rejects the legacy compact top-level `(:= signal=value)` directive in strict mode on the current `?fsm:` / `?dt:` direct-root path while leaving default-mode compatibility unchanged,
  - that check lives in the shared direct-root strict owner, so it reaches those direct roots and generated child sources through the same semantic-module path while still leaving top-level `?mod:` / `?module:` roots unchanged,
  - [t/257-strict-mode-compact-init-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/257-strict-mode-compact-init-boundary.t) now locks the boundary through the shared frontend plus pipeline and CLI entry points for both direct roots and external `?dtc` child sources,
  - and the shipped strict-mode note is intentionally honest: the current strict surface does not yet provide a canonical replacement for the compatibility `:=` form.

## 2026-04-01: the corpus now counts missing generated-child lookup as composition-contract behavior too
- Continued the visible `R12` lane by widening the composition-contract bucket beyond missing `.rtlif` sidecars into missing external generated-child source lookup too.
- Important continuity note:
  - [t/corpus/missing_fsm_child_source_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/missing_fsm_child_source_top.fsm) and [t/corpus/missing_dt_child_source_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/missing_dt_child_source_top.fsm) now exist as static composition-top expected-failure corpus assets,
  - [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm) now records `contract.missing_fsm_child_source` and `contract.missing_dt_child_source` under the existing `composition_contract_rejection_pipeline_cli` coverage bucket,
  - those entries lock the normal unresolved external `?fsmc` / `?dtc` composition boundary through the new `Expected child source file:` diagnostic family rather than leaving that behavior only in focused diagnostics tests,
  - [t/249-regression-corpus-classified-behavior.t](/Users/richarddje/Documents/github/fsmgen/t/249-regression-corpus-classified-behavior.t) now exercises those missing-child composition rejection paths through both pipeline and CLI,
  - and [docs/REGRESSION_CORPUS.md](/Users/richarddje/Documents/github/fsmgen/docs/REGRESSION_CORPUS.md) now records that the composition-contract rejection bucket spans both missing external child-source lookup and missing external `.rtlif` sidecars.

## 2026-04-01: missing external child failures now name the expected child artifact
- Continued the visible `R10` lane by tightening unresolved external `?fsmc` / `?dtc` lookup instead of leaving missing child-source resolution slightly less actionable than wrong-kind child failures or missing `.rtlif` sidecars.
- Important continuity note:
  - [perl/FSM/Composition/GeneratedChildRealizer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GeneratedChildRealizer.pm) now wraps unresolved external child lookup with `Source file: '...'`, `Expected child source file: 'source_name.fsm'`, and `Generated child source: '?fsmc/?dtc' 'source_name'`,
  - that means missing child lookup no longer stops at only the containing composition path plus generated-child identity while still avoiding a fake resolved `Child source file:` artifact,
  - [perl/FSM/Composition/FailureReportBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/FailureReportBuilder.pm) now also extracts that expected-child filename, so non-quiet composition failure summaries can show the missing external `.fsm` target directly,
  - [t/256-composition-missing-child-source-artifact-context.t](/Users/richarddje/Documents/github/fsmgen/t/256-composition-missing-child-source-artifact-context.t) now locks the raw pipeline and CLI diagnostic shape for both missing `?fsmc` and missing `?dtc` lookup,
  - and the missing-child summary subtests in [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now lock the new `Expected child source file:` summary artifact too.

## 2026-04-01: the corpus now includes a composition-contract expected-failure asset
- Continued the visible `R12` lane by widening support accounting beyond strict-mode and direct language-contract rejection into one real composition-contract rejection family.
- Important continuity note:
  - [t/corpus/missing_rtl_metadata_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/missing_rtl_metadata_top.fsm) now exists as the first static composition-top expected-failure corpus asset,
  - [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm) now records `contract.missing_rtl_metadata_sidecar` under the new `composition_contract_rejection_pipeline_cli` coverage bucket,
  - that entry locks the normal missing-`.rtlif` composition boundary with the new `Expected RTL metadata file:` artifact label rather than treating it as only a focused diagnostics test,
  - [t/249-regression-corpus-classified-behavior.t](/Users/richarddje/Documents/github/fsmgen/t/249-regression-corpus-classified-behavior.t) now exercises that composition rejection path through both pipeline and CLI,
  - and [docs/REGRESSION_CORPUS.md](/Users/richarddje/Documents/github/fsmgen/docs/REGRESSION_CORPUS.md) now records the new coverage bucket beside the earlier strict and language-contract rejection buckets.

## 2026-04-01: missing external `.rtlif` failures now name the expected sidecar artifact
- Continued the visible `R10` lane by tightening one remaining `?rtl` diagnostics gap instead of dropping back into backend-only cleanup.
- Important continuity note:
  - [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm) now wraps unresolved external `.rtlif` lookup failures with `Source file: '...'`, `Expected RTL metadata file: 'module.rtlif'`, and `RTL child module: '?rtl' 'module_name'`,
  - that means missing sidecar metadata no longer falls back to only the raw search-root/search-location prose while still avoiding a fake resolved `RTL metadata file:` artifact,
  - [perl/FSM/Composition/FailureReportBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/FailureReportBuilder.pm) now also extracts that expected-artifact label, so non-quiet composition failure summaries can show the missing sidecar target directly,
  - [t/255-composition-missing-rtl-metadata-diagnostic-context.t](/Users/richarddje/Documents/github/fsmgen/t/255-composition-missing-rtl-metadata-diagnostic-context.t) now locks the raw pipeline and CLI diagnostic shape,
  - and the missing-rtlif subtests in [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now lock the new `Expected RTL metadata file:` summary artifact too.

## 2026-04-01: strict mode now rejects explicit `(asreset rstn)` too
- Continued the visible `R9` lane by widening strict mode beyond the first root-family and empty-`(+size)` cuts into another explicit section-level compatibility-residue rule.
- Important continuity note:
  - [perl/FSM/Pipeline/SourceFrontend.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceFrontend.pm) now rejects the legacy explicit `(asreset rstn)` `+system` spelling in strict mode while leaving default-mode compatibility intact,
  - that check lives in the same shared direct-root strict owner as the earlier empty-`(+size)` rule, so it reaches both top-level direct roots and generated child sources,
  - [perl/FSM/Pipeline/SourceGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceGenerationOrchestrator.pm) now passes `raw_ast` into the shared top-level strict hook too, so section-level strict cuts fire consistently at the file-orchestration boundary,
  - and [t/254-strict-mode-asreset-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/254-strict-mode-asreset-boundary.t) now locks the new boundary through the shared frontend plus pipeline and CLI entry points for both direct roots and external `?fsmc` child sources.

## 2026-04-01: the corpus now accounts for child-root compatibility residue too
- Continued the visible `R12` lane by widening support accounting into generated-child source-root residue instead of stopping at direct-root and section-level legacy cases.
- Important continuity note:
  - [t/corpus/legacy_fsm_child_root_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_fsm_child_root_top.fsm) plus [t/corpus/legacy_fsm_child_root_src.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_fsm_child_root_src.fsm) now exist as the first explicit `?fsmc` child-root compatibility corpus pair,
  - [t/corpus/legacy_dt_child_root_top.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_dt_child_root_top.fsm) plus [t/corpus/legacy_dt_child_root_src.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_dt_child_root_src.fsm) now exist as the matching `?dtc` child-root compatibility corpus pair,
  - [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm) now records both default-mode compatibility and strict-mode expected-rejection contracts for those child-root fixtures, including explicit `search_path_relpaths`,
  - [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t) now locks the new child-root coverage buckets plus the existence of per-entry search roots,
  - and [t/249-regression-corpus-classified-behavior.t](/Users/richarddje/Documents/github/fsmgen/t/249-regression-corpus-classified-behavior.t) now knows how to exercise composition entries with explicit search-path realization through both pipeline and CLI.

## 2026-04-01: typed extension loading failures now keep artifact labels too
- Continued the visible `R10` lane by widening the same diagnostics family one step earlier, into extension loading and pipeline construction.
- Important continuity note:
  - [perl/FSM/Extension/Loader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Loader.pm) now annotates malformed config-file failures with `Extension config file: '...'` and module-load / constructor failures with `Extension module: '...'`,
  - [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) now wraps `HDLGenerator->new(...)` in the cleaned CLI error path, so constructor failures no longer dump a raw `bin/fsmgen` script line,
  - [t/253-extension-loader-diagnostic-context.t](/Users/richarddje/Documents/github/fsmgen/t/253-extension-loader-diagnostic-context.t) now locks both pipeline and CLI behavior for malformed extension config input and constructor-failing extension modules,
  - and [t/lib/FSM/TestExtension/BadNew.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/TestExtension/BadNew.pm) now exists as the dedicated regression helper for constructor-failure coverage.

## 2026-04-01: the corpus now accounts for section-level compatibility residue too
- Continued the visible `R12` lane by turning the empty-`(+size)` strict/default split into an explicit dual-contract corpus asset instead of leaving it only as an isolated strict-mode regression.
- Important continuity note:
  - [t/corpus/legacy_empty_size_noop.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/legacy_empty_size_noop.fsm) now exists as the first section-level compatibility-residue corpus asset,
  - [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm) now records both `legacy.empty_size_noop.default_compat` and `legacy.empty_size_noop.strict_rejection` for the same file,
  - [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t) now knows the new `legacy_section_default_pipeline_cli` and `strict_section_rejection_pipeline_cli` coverage buckets,
  - and [t/249-regression-corpus-classified-behavior.t](/Users/richarddje/Documents/github/fsmgen/t/249-regression-corpus-classified-behavior.t) now treats strict support-tier expected failures as a broader family instead of only the earlier root-family case.

## 2026-04-01: typed extension hook failures now keep source-local context too
- Continued the visible `R10` lane by widening the same artifact-label pattern into typed extension hook failures instead of letting those failures fall back to raw hook text.
- Important continuity note:
  - [perl/FSM/Extension/Registry.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Registry.pm) now annotates ordinary extension-hook failures with `Extension module: '...'` and `Extension stage: '...'`,
  - [perl/FSM/Pipeline/SourceGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceGenerationOrchestrator.pm) now runs `after_parse_source` and `after_generate_result` under the same `Source file: '...'` wrapper used by the earlier top-level diagnostic slices,
  - [t/252-extension-diagnostic-context.t](/Users/richarddje/Documents/github/fsmgen/t/252-extension-diagnostic-context.t) now locks that full `Source file` + `Extension module` + `Extension stage` shape through both pipeline and CLI entry points,
  - and [t/lib/FSM/TestExtension/Exploding.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/TestExtension/Exploding.pm) now exists as the dedicated regression helper for extension-hook failure-shape coverage.

## 2026-04-01: strict mode now rejects the legacy empty `(+size)` no-op
- Continued the visible `R9` lane by making the first section-level compatibility-residue cut instead of only tightening root-family boundaries.
- Important continuity note:
  - [perl/FSM/Pipeline/SourceFrontend.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceFrontend.pm) now rejects the legacy empty `(+size)` no-op section in strict mode while leaving default-mode compatibility intact,
  - that check lives in the shared direct-root strict owner, so it reaches top-level sources and generated child sources through the same semantic-module path,
  - [t/251-strict-mode-empty-size-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/251-strict-mode-empty-size-boundary.t) now locks the boundary through the shared frontend plus pipeline and CLI entry points,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now states the correct split explicitly: default mode still tolerates empty `(+size)` as compatibility residue, while strict mode requires explicit width entries or no `+size` section at all.

## 2026-04-01: CLI entrypoint failures now keep requested-source and output-file context
- Switched back to the visible `R10` lane after the recent `R12` streak and widened the CLI error shape one step earlier in the flow.
- Important continuity note:
  - [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) now prefixes unresolved source-lookup failures with `Requested source: '...'` instead of surfacing only the raw search failure body,
  - output-open failures now also keep `Source file: '...'` plus `Output file: '...'` before the underlying `Cannot write to output file:` diagnostic,
  - [t/250-cli-entrypoint-file-context.t](/Users/richarddje/Documents/github/fsmgen/t/250-cli-entrypoint-file-context.t) now locks both pre-pipeline CLI failure families,
  - and this is explicitly a pre-pipeline artifact-context slice, not a claim that deeper parse/generation provenance is complete.

## 2026-04-01: the corpus now includes a static malformed-language expected-failure asset
- Widened the `R12` catalog again so `expected_failure` no longer means only “strict-mode legacy root rejection.”
- Important continuity note:
  - [t/corpus/language_contract_bad_size_entry.fsm](/Users/richarddje/Documents/github/fsmgen/t/corpus/language_contract_bad_size_entry.fsm) is now the first static malformed-language corpus asset,
  - `contract.language_contract_bad_size_entry` in [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm) is classified as `expected_failure` with the normal `Malformed '+size' entry` boundary,
  - [t/249-regression-corpus-classified-behavior.t](/Users/richarddje/Documents/github/fsmgen/t/249-regression-corpus-classified-behavior.t) now checks that ordinary pipeline and CLI rejection path in addition to the earlier strict `+fsm` rejection path,
  - and [docs/REGRESSION_CORPUS.md](/Users/richarddje/Documents/github/fsmgen/docs/REGRESSION_CORPUS.md) now carries the `language_contract_rejection_pipeline_cli` coverage bucket beside the earlier legacy/strict buckets.

## 2026-04-01: the first corpus catalog now carries explicit non-supported classifications too
- Widened the new `R12` catalog beyond `supported_smoke` so the support story now includes one explicit compatibility-retained entry and one explicit expected rejection.
- Important continuity note:
  - [fsm/mipicsi2_txccore_ulp.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/mipicsi2_txccore_ulp.fsm) is now used as the first real dual-contract asset in [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm),
  - `legacy.mipicsi2_txccore_ulp.default_compat` is classified as `legacy_out_of_scope` and must still compile through pipeline and CLI in default mode,
  - `legacy.mipicsi2_txccore_ulp.strict_rejection` is classified as `expected_failure` and must keep the strict `+fsm` rejection boundary through pipeline and CLI,
  - [t/249-regression-corpus-classified-behavior.t](/Users/richarddje/Documents/github/fsmgen/t/249-regression-corpus-classified-behavior.t) now locks those two first non-supported contracts,
  - and [docs/REGRESSION_CORPUS.md](/Users/richarddje/Documents/github/fsmgen/docs/REGRESSION_CORPUS.md) now explains that corpus entries are contracts, so the same file may appear more than once when the supported behavior differs by mode.

## 2026-04-01: first protocol corpus slice now has explicit catalog/accounting structure
- Strengthened the first `R12` slice so it is not just one hardcoded smoke test anymore.
- Important continuity note:
  - [t/lib/FSM/Test/RegressionCorpus.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/Test/RegressionCorpus.pm) now records the first named corpus entries and their classification / coverage buckets in one machine-checked place,
  - [t/247-protocol-fixture-regression-smoke.t](/Users/richarddje/Documents/github/fsmgen/t/247-protocol-fixture-regression-smoke.t) now compiles the first protocol fixtures from that catalog instead of embedding the list inline,
  - [t/248-regression-corpus-accounting.t](/Users/richarddje/Documents/github/fsmgen/t/248-regression-corpus-accounting.t) now checks uniqueness, known classifications, known coverage buckets, and real asset existence,
  - [docs/REGRESSION_CORPUS.md](/Users/richarddje/Documents/github/fsmgen/docs/REGRESSION_CORPUS.md) is now the human-readable companion note for the same slice,
  - and the saved `R12` growth rule is now “add a classified catalog entry and matching automated checks,” not “point at an example file and assume it counts.”

## 2026-04-01: protocol fixture smoke now starts the regression corpus lane
- Started `R12` for real by turning the imported protocol fixtures into live regression-backed corpus entries instead of leaving them as uncounted examples only.
- Important continuity note:
  - [t/247-protocol-fixture-regression-smoke.t](/Users/richarddje/Documents/github/fsmgen/t/247-protocol-fixture-regression-smoke.t) now locks direct-root smoke for [fsm/apb_requester.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/apb_requester.fsm), [fsm/apb_completer.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/apb_completer.fsm), and [fsm/amba_requester.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/amba_requester.fsm),
  - that same test also locks the composed protocol harness [fsm/apb_tb.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/apb_tb.fsm) through both pipeline and CLI, so the first `R12` slice covers a real generated-child / explicit-link path,
  - and the saved rule is now explicit: imported/example assets only count toward support claims once they are regression-backed.

## 2026-04-01: CLI failure output now suppresses raw Perl stack traces
- Continued the active `R10` diagnostics lane by cleaning the last-mile CLI presentation of the source-local diagnostics we already shipped.
- Important continuity note:
  - [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) now normalizes ordinary string errors before printing them so the CLI keeps the actual diagnostic text and context lines but drops raw Perl `confess` stack frames,
  - top-level parse failures and generated-child failures still keep their earlier `Source file:` / `Parent composition source:` / `Generated child source:` framing,
  - [t/246-cli-error-output-cleanup.t](/Users/richarddje/Documents/github/fsmgen/t/246-cli-error-output-cleanup.t) locks the cleaned CLI output for both a top-level parse failure and a generated-child failure,
  - and the saved `R10` story is now “source-local context first, then cleaner CLI presentation”.

## 2026-04-01: strict mode now requires canonical `?fsm:` roots under `?fsmc`
- Continued the active `R9` lane by making the FSM-child side of the strict child-root contract explicit instead of leaving it to the broader top-level `+fsm` rejection wording.
- Important continuity note:
  - [perl/FSM/Pipeline/SourceFrontend.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceFrontend.pm) now rejects legacy `+fsm` specifically when it is used as the root of a `?fsmc` child source and points users to canonical `?fsm:source_name`,
  - [perl/FSM/Composition/GeneratedChildRealizer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GeneratedChildRealizer.pm) already applies that helper before semantic realization, so the child-specific migration hint now reaches pipeline and CLI entry points with the same generated-child source context as other child failures,
  - [t/245-strict-mode-fsm-child-root-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/245-strict-mode-fsm-child-root-boundary.t) locks that updated boundary through both pipeline and CLI for external flattened and nested legacy `+fsm` child roots,
  - and the saved `R9` story is now “top-level `+fsm`, then `?dtc` canonical `?dt`, then `?fsmc` canonical `?fsm`”.

## 2026-04-01: generated-child resolution failures now keep the same source-local framing
- Continued the active `R10` diagnostics lane by widening the generated-child context helper into the two adjacent external-child failure families that were still surfacing only raw search or wrong-kind text.
- Important continuity note:
  - [perl/FSM/Composition/GeneratedChildRealizer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GeneratedChildRealizer.pm) now routes unresolved external child and wrong-kind external child failures through `_with_generated_child_source_context(...)`,
  - wrong-kind external child failures now keep `Source file: 'child_source.fsm'`, `Parent composition source: 'top_source.fsm'`, and `Generated child source: '?fsmc/?dtc' 'source_name'`,
  - unresolved external child failures now keep `Source file: 'top_source.fsm'` plus the same generated-child identity line without inventing a missing child-file artifact,
  - [t/244-composition-child-resolution-diagnostic-context.t](/Users/richarddje/Documents/github/fsmgen/t/244-composition-child-resolution-diagnostic-context.t) locks both failure families through pipeline and CLI,
  - and the saved `R10` story is now “top-level failures, then generated-child parse/semantic failures, then generated-child resolution/wrong-kind failures, then RTL-child metadata failures”.

## 2026-04-01: strict mode now requires canonical `?dt:` roots under `?dtc`
- Continued the active `R9` lane by tightening the standalone-DT child-source contract without collapsing top-level module roots.
- Important continuity note:
  - [perl/FSM/Pipeline/SourceFrontend.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceFrontend.pm) now owns a child-specific strict helper in addition to the earlier top-level `+fsm` root-family boundary,
  - [perl/FSM/Composition/GeneratedChildRealizer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GeneratedChildRealizer.pm) now applies that helper so strict mode rejects `?mod:` / `?module:` when they are used as `?dtc` child roots and points users to canonical `?dt:source_name`,
  - top-level `?mod:` / `?module:` roots remain accepted in strict mode,
  - and [t/240-strict-mode-standalone-dt-alias-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/240-strict-mode-standalone-dt-alias-boundary.t) now locks the updated child-root boundary through both pipeline and CLI for embedded and external child sources.

## 2026-04-01: RTL child metadata failures now keep metadata-file and parent-source context
- Continued the active `R10` diagnostics lane by teaching [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm) to prepend stable context around blocked sidecar or embedded `.rtlif` metadata loading.
- Important continuity note:
  - sidecar `.rtlif` failures now keep `RTL metadata file: 'module.rtlif'`, `Parent composition source: 'top_source.fsm'`, and `RTL child module: '?rtl' 'module_name'`,
  - embedded `?rtlif` failures now keep `Source file: 'top_source.fsm'` plus the same RTL-child identity line,
  - [t/243-composition-rtl-child-diagnostic-context.t](/Users/richarddje/Documents/github/fsmgen/t/243-composition-rtl-child-diagnostic-context.t) locks both the external-sidecar and embedded-metadata failure families through pipeline and CLI,
  - and the saved `R10` story is now “top-level failures, then generated-child failures, then RTL-child metadata failures”.

## 2026-03-31: generated-child failures now keep child-source and parent-source context
- Continued the active `R10` diagnostics lane by teaching [perl/FSM/Composition/GeneratedChildRealizer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GeneratedChildRealizer.pm) to prepend stable source-local context around generated-child parse/semantic-generation failures.
- Important continuity note:
  - external child failures now keep `Source file: 'child_source.fsm'`, `Parent composition source: 'top_source.fsm'`, and `Generated child source: '?fsmc/?dtc' 'source_name'`,
  - embedded child failures now keep `Source file: 'top_source.fsm'` plus `Generated child source: '?fsmc/?dtc' 'source_name'`,
  - [t/242-composition-child-source-file-diagnostic-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/242-composition-child-source-file-diagnostic-boundary.t) locks that error shape through both pipeline and CLI,
  - and the saved `R10` story is now “top-level failures first, then generated-child failures” rather than only the initial top-level boundary.

## 2026-03-31: top-level pipeline and CLI failures now keep `Source file:` context
- Started the first dedicated `R10` slice by teaching [perl/FSM/Pipeline/SourceGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceGenerationOrchestrator.pm) to prepend `Source file: '...'` when top-level parse/generation work raises a normal string error.
- Important continuity note:
  - this is intentionally a top-level orchestration boundary, not a claim that fine-grained line/construct provenance is finished,
  - the same source-file context now appears for ordinary top-level parser/adapter failures and for strict-mode support-tier failures,
  - [t/241-top-level-source-file-diagnostic-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/241-top-level-source-file-diagnostic-boundary.t) locks the new error shape through both pipeline and CLI entry points,
  - and `R10` should now be treated as active rather than untouched.

## 2026-03-31: AXI intent-capture case study and executable-PDF target are now frozen in repo memory
- Reviewed the full external AXI workspace under `/Users/richarddje/Documents/livework/protocols/arm/axi/` and preserved the detailed method/conclusions in [docs/INTENT_CAPTURE_AXI_CASE_STUDY.md](/Users/richarddje/Documents/github/fsmgen/docs/INTENT_CAPTURE_AXI_CASE_STUDY.md).
- The saved durable direction is:
  - use normalized `Markdown`, not raw `PDF`, as the working textual surface,
  - work actor-first rather than protocol-as-a-monolith,
  - define phases before final FSM states,
  - justify persistent state from protocol rules,
  - keep source facts, derived machine rules, local design decisions, and explicit abstractions separate,
  - recover invariants/contracts/gates/assertions before `.fsm` emission,
  - and treat reusable transport micro-actors plus explicit interconnect actors as first-class capture outputs rather than implementation details.
- The saved long-term target is now stronger too:
  - future intent capture should aim toward an almost-fully-staged automated “executable PDF” flow that can emit `.fsm` sets, harness/testbench surfaces, scenario/test intent, verification plans, functional-coverage plans, and an honesty-preserving capture report.
- The saved process constraint is that every stage should have explicit gates:
  - normalization,
  - dossier/section mapping,
  - actor discovery,
  - interface/phase extraction,
  - invariant/contract/gate/assertion capture,
  - abstraction logging,
  - decomposition,
  - emission,
  - verification-asset generation,
  - and back-annotation/residue reporting.

## 2026-03-31: strict mode no longer collapses `?mod:` / `?module:` into `?dt:`
- Corrected shipped behavior:
  - [perl/FSM/Pipeline/SourceFrontend.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceFrontend.pm) still owns the shared strict-mode root-family boundary,
  - [perl/FSM/Pipeline/DirectGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/DirectGenerationOrchestrator.pm) and [perl/FSM/Composition/GeneratedChildRealizer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GeneratedChildRealizer.pm) still carry strict-mode enforcement through direct-root semantic module creation and generated child realization,
  - but strict mode no longer rejects `?mod:` / `?module:` or suggests migrating them to `?dt:`,
  - and [t/240-strict-mode-standalone-dt-alias-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/240-strict-mode-standalone-dt-alias-boundary.t) now locks strict-mode acceptance for top-level `?dt:` / `?mod:` / `?module:` roots plus `?dtc` child realization through `?mod:` / `?module:`.
- Important continuity note:
  - `?dt` means one decision tree,
  - `?mod:` / `?module:` remain distinct module/entity-architecture roots in the intended language model,
  - the current implementation may still route those roots through shared direct single-module machinery,
  - but docs and strict mode should not describe them as semantic aliases of `?dt:`,
  - and the live strict-mode root-family boundary is currently only the legacy `+fsm` family.

## 2026-03-31: strict mode now exists and its first shipped boundary rejects legacy `+fsm` roots
- Saved shipped behavior:
  - updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) so the CLI now accepts `--strict`,
  - updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the public pipeline facade now accepts `strict_mode => 1`,
  - updated [perl/FSM/Pipeline/SourceGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceGenerationOrchestrator.pm) so strict mode now rejects the legacy `+fsm` root family with a targeted migration hint toward `?fsm:module_name`,
  - added [t/239-strict-mode-legacy-fsm-root-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/239-strict-mode-legacy-fsm-root-boundary.t),
  - and updated [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) plus the roadmap/continuity set so the first strict-mode boundary is explicit.
- Important continuity note:
  - `R9` is no longer purely hypothetical; the first enforcement slice is live,
  - the current strict-mode surface is intentionally narrow and should be widened in bounded high-signal cuts,
  - and the next strict-mode candidate should be another compatibility-vs-supported boundary that is already well documented in `R8`.

## 2026-03-31: execution cadence now alternates cleanup and feature work more deliberately
- Saved continuity rule:
  - do not let long uninterrupted consolidation-only streaks become the default working pattern,
  - after a cleanup/debt-reduction slice, the next honest move should usually be a visibly user-facing capability slice,
  - and repeated cleanup slices are still allowed, but only when they are the clear blocker for the next feature/contract/diagnostic step.
- Important continuity note:
  - future sessions should treat this as an execution-policy rule rather than a one-off preference,
  - and roadmap steering should now rebalance more often between internal architecture work and externally visible capability progress.

## 2026-03-31: live direct backend no longer instantiates the generation-structural-prelude shell
- Saved shipped behavior:
  - updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) so the live direct backend no longer instantiates `backend_sv_generation_structural_prelude_support`,
  - updated [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm) so the live backend now reaches scaffold/header/module/state/internal-declaration assembly directly before enable-condition generation,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationStructuralPreludeSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationStructuralPreludeSupport.pm) so it now survives only as a compatibility shell outside the live backend path,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm) and [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPreludeSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPreludeSupport.pm) so the older compatibility shells now rebuild their structural prefix directly over the scaffold and internal-declaration owners,
  - retargeted [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t), [t/232-systemverilog-generation-pipeline-support.t](/Users/richarddje/Documents/github/fsmgen/t/232-systemverilog-generation-pipeline-support.t), [t/233-systemverilog-generation-prelude-support.t](/Users/richarddje/Documents/github/fsmgen/t/233-systemverilog-generation-prelude-support.t), [t/234-systemverilog-generation-tail-support.t](/Users/richarddje/Documents/github/fsmgen/t/234-systemverilog-generation-tail-support.t), and [t/237-systemverilog-generation-structural-prelude-support.t](/Users/richarddje/Documents/github/fsmgen/t/237-systemverilog-generation-structural-prelude-support.t),
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `97` reachable project files and `96` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the live generation-structural-prelude shell itself,
  - it is the remaining lower-level coordination across the extracted prescan-preparation owner, consolidated-intermediate planning/stage owners, extracted tail owner, and the still-central top-level sequencing in [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm),
  - and future sessions should read the live direct backend assembly path as “flatten first, build scaffold/header/module/state/internal declarations directly, emit enable conditions, run the dedicated prescan owner, generate the consolidated intermediate stage, then let the tail owner close out the module.”

## 2026-03-31: live direct backend no longer instantiates the generation-enable-preparation shell
- Saved shipped behavior:
  - updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) so the live direct backend no longer instantiates `backend_sv_generation_enable_preparation_support`,
  - updated [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm) so the live backend now emits enable conditions and runs the extracted prescan-preparation owner directly after the structural prelude,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationEnablePreparationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationEnablePreparationSupport.pm) so it now survives only as a compatibility shell outside the live backend path,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm) and [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPreludeSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPreludeSupport.pm) so the older compatibility shells now rebuild their pre-stage flow over direct enable-condition generation plus the extracted prescan owner,
  - retargeted [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t), [t/232-systemverilog-generation-pipeline-support.t](/Users/richarddje/Documents/github/fsmgen/t/232-systemverilog-generation-pipeline-support.t), [t/233-systemverilog-generation-prelude-support.t](/Users/richarddje/Documents/github/fsmgen/t/233-systemverilog-generation-prelude-support.t), [t/234-systemverilog-generation-tail-support.t](/Users/richarddje/Documents/github/fsmgen/t/234-systemverilog-generation-tail-support.t), and [t/236-systemverilog-generation-enable-preparation-support.t](/Users/richarddje/Documents/github/fsmgen/t/236-systemverilog-generation-enable-preparation-support.t),
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `98` reachable project files and `97` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the live generation-enable-preparation shell itself,
  - it is the remaining lower-level coordination across the extracted structural-prelude owner, prescan-preparation owner, consolidated-intermediate planning/stage owners, extracted tail owner, and the still-central top-level direct backend sequencing in [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm),
  - and future sessions should read the live direct backend assembly path as “flatten first, build the structural prelude, emit enable conditions directly, run the dedicated prescan owner, generate the consolidated intermediate stage, then let the tail owner close out the module.”

## 2026-03-31: live direct backend no longer instantiates the generation-pipeline shell
- Saved shipped behavior:
  - updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) so the live direct backend no longer instantiates `backend_sv_generation_pipeline_support`,
  - updated [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm) so the live backend now composes structural-prelude generation, enable-oriented preparation, consolidated intermediate stage generation, and tail closeout directly after flattening,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm) so it now survives only as a compatibility shell outside the live backend path,
  - retargeted [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t) and [t/232-systemverilog-generation-pipeline-support.t](/Users/richarddje/Documents/github/fsmgen/t/232-systemverilog-generation-pipeline-support.t),
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `99` reachable project files and `98` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the live generation-pipeline shell itself,
  - it is the remaining lower-level coordination across the extracted structural-prelude owner, prescan-preparation owner, narrowed enable-preparation owner, consolidated-intermediate planning/stage owners, extracted tail owner, and the still-central top-level direct backend sequencing in [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm),
  - and future sessions should read the live direct backend assembly path as “flatten first, then let `Orchestrator` compose structural prelude, enable preparation, consolidated intermediate stage, and tail closeout directly.”

## 2026-03-31: live direct backend no longer instantiates the generation-prelude shell
- Saved shipped behavior:
  - updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) so the live direct backend no longer instantiates `backend_sv_generation_prelude_support`,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm) so the live pipeline now composes [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationStructuralPreludeSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationStructuralPreludeSupport.pm) plus [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationEnablePreparationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationEnablePreparationSupport.pm) directly before the consolidated stage and tail owners,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPreludeSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPreludeSupport.pm) so it now survives only as a compatibility shell outside the live backend path,
  - retargeted [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t), [t/232-systemverilog-generation-pipeline-support.t](/Users/richarddje/Documents/github/fsmgen/t/232-systemverilog-generation-pipeline-support.t), [t/233-systemverilog-generation-prelude-support.t](/Users/richarddje/Documents/github/fsmgen/t/233-systemverilog-generation-prelude-support.t), and [t/234-systemverilog-generation-tail-support.t](/Users/richarddje/Documents/github/fsmgen/t/234-systemverilog-generation-tail-support.t),
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `100` reachable project files and `99` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the live generation-prelude shell itself,
  - it is the remaining lower-level coordination across the extracted structural-prelude owner, prescan-preparation owner, narrowed enable-preparation owner, consolidated-intermediate planning/stage owners, extracted tail owner, narrowed generation pipeline owner, and broader direct-backend convergence,
  - and future sessions should read the live direct backend assembly path as “flatten first, build the dedicated structural prelude, emit enable conditions, run the dedicated prescan-preparation owner, generate the consolidated intermediate stage, then let the tail owner emit WEN/EN, assignments, and module closeout.”

## 2026-03-31: live direct backend prescan preparation now has a dedicated owner
- Saved shipped behavior:
  - added [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPrescanPreparationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPrescanPreparationSupport.pm) as the live owner of logical-operation counting plus WEN/EN prescan after enable-condition emission and before consolidated intermediate generation,
  - updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) so the direct backend now instantiates `backend_sv_generation_prescan_preparation_support`,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationEnablePreparationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationEnablePreparationSupport.pm) so it now keeps enable-condition emission plus composition of that extracted prescan owner instead of keeping logical-op counting and WEN/EN prescan inline,
  - added [t/238-systemverilog-generation-prescan-preparation-support.t](/Users/richarddje/Documents/github/fsmgen/t/238-systemverilog-generation-prescan-preparation-support.t), retargeted [t/236-systemverilog-generation-enable-preparation-support.t](/Users/richarddje/Documents/github/fsmgen/t/236-systemverilog-generation-enable-preparation-support.t) and [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t),
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `101` reachable project files and `100` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the logical-op counting / WEN-EN prescan pocket inside `GenerationEnablePreparationSupport`,
  - it is the remaining lower-level coordination across the extracted structural-prelude owner, the new prescan-preparation owner, the narrowed enable-preparation owner, consolidated-intermediate planning/stage owners, the extracted tail owner, the narrowed generation pipeline owner, and broader direct-backend convergence,
  - and future sessions should read the direct backend assembly path as “flatten first, build the dedicated structural prelude, emit enable conditions, run the dedicated prescan-preparation owner, generate the consolidated intermediate stage, then let the tail owner emit WEN/EN, assignments, and module closeout.”

## 2026-03-31: live direct backend structural pre-stage prelude now has a dedicated owner
- Saved shipped behavior:
  - added [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationStructuralPreludeSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationStructuralPreludeSupport.pm) as the live owner of scaffold rendering plus internal declaration rendering before enable-oriented pre-stage preparation,
  - updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) so the direct backend now instantiates `backend_sv_generation_structural_prelude_support`,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPreludeSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPreludeSupport.pm) so it now keeps structural-prelude plus enable-preparation composition instead of keeping the structural prefix inline,
  - added [t/237-systemverilog-generation-structural-prelude-support.t](/Users/richarddje/Documents/github/fsmgen/t/237-systemverilog-generation-structural-prelude-support.t), retargeted [t/233-systemverilog-generation-prelude-support.t](/Users/richarddje/Documents/github/fsmgen/t/233-systemverilog-generation-prelude-support.t) and [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t),
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `100` reachable project files and `99` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the structural header/module/state/internal-declaration prefix inside `GenerationPreludeSupport`,
  - it is the remaining lower-level coordination across the extracted structural-prelude owner, enable-preparation owner, consolidated-intermediate planning/stage owners, the extracted tail owner, the narrowed generation pipeline owner, and broader direct-backend convergence,
  - and future sessions should read the direct backend assembly path as “flatten first, build the dedicated structural prelude, run the dedicated enable-preparation owner, generate the consolidated intermediate stage, then let the tail owner emit WEN/EN, assignments, and module closeout.”

## 2026-03-31: live direct backend enable-oriented pre-stage preparation now has a dedicated owner
- Saved shipped behavior:
  - added [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationEnablePreparationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationEnablePreparationSupport.pm) as the live owner of enable-condition generation, logical-operation counting, and WEN/EN prescan before consolidated intermediate generation,
  - updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) so the direct backend now instantiates `backend_sv_generation_enable_preparation_support`,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPreludeSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPreludeSupport.pm) so it now keeps scaffold/declaration composition plus delegation to that extracted owner instead of keeping the enable/prescan cluster inline,
  - added [t/236-systemverilog-generation-enable-preparation-support.t](/Users/richarddje/Documents/github/fsmgen/t/236-systemverilog-generation-enable-preparation-support.t), retargeted [t/233-systemverilog-generation-prelude-support.t](/Users/richarddje/Documents/github/fsmgen/t/233-systemverilog-generation-prelude-support.t) and [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t),
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `99` reachable project files and `98` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the live enable-condition / logical-op-counting / WEN-EN prescan cluster inside `GenerationPreludeSupport`,
  - it is the remaining lower-level coordination across the extracted prelude owner, the new enable-preparation owner, consolidated-intermediate planning/stage owners, the extracted tail owner, the narrowed generation pipeline owner, and broader direct-backend convergence,
  - and future sessions should read the direct backend assembly path as “flatten first, build the structural prelude, run the dedicated enable-preparation owner, generate the consolidated intermediate stage, then let the tail owner emit WEN/EN, assignments, and module closeout.”

## 2026-03-31: live direct backend recursive decision-tree flattening now has a dedicated owner
- Saved shipped behavior:
  - added [perl/FSM/HDL/FlattenedDT/DecisionTreeFlatteningSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/DecisionTreeFlatteningSupport.pm) as the live owner of recursive regular-state and standalone-DT flattening plus the final unified assignment-analysis handoff,
  - updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) so the direct backend now instantiates `decision_tree_flattening_support`,
  - updated [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm) so `flatten_all_decision_trees(...)` and `flatten_decision_tree(...)` now delegate to that owner instead of keeping the recursive traversal inline,
  - added [t/235-flatteneddt-decision-tree-flattening-support.t](/Users/richarddje/Documents/github/fsmgen/t/235-flatteneddt-decision-tree-flattening-support.t), retargeted [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t),
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `98` reachable project files and `97` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the raw recursive decision-tree flattening cluster in `Orchestrator`,
  - it is the remaining lower-level coordination across the extracted prelude/stage/tail/pipeline owners plus broader direct-backend convergence around the now-thinner top-level generation sequence,
  - and future sessions should read the direct backend path as “reset state, attach module context, flatten through the dedicated flattening owner, then assemble HDL through the extracted generation owners.”

## 2026-03-31: live direct backend post-stage SystemVerilog tail now has a dedicated owner
- Saved shipped behavior:
  - added [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationTailSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationTailSupport.pm) as the live owner of unified WEN/EN emission, signal-assignment emission, and final `endmodule` closeout after consolidated intermediate generation,
  - updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) so the direct backend now instantiates `backend_sv_generation_tail_support`,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm) so it now composes the extracted tail owner instead of owning WEN/EN emission, assignment emission, and module closeout inline,
  - added [t/234-systemverilog-generation-tail-support.t](/Users/richarddje/Documents/github/fsmgen/t/234-systemverilog-generation-tail-support.t), retargeted [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t) and [t/232-systemverilog-generation-pipeline-support.t](/Users/richarddje/Documents/github/fsmgen/t/232-systemverilog-generation-pipeline-support.t),
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `97` reachable project files and `96` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the live direct backend post-stage WEN/EN/assignment/endmodule sequence inside `GenerationPipelineSupport`,
  - it is the remaining lower-level coordination across the extracted prelude owner, consolidated-intermediate planning/stage composition, the extracted tail owner, the narrowed generation pipeline owner, and broader direct-backend convergence,
  - and future sessions should read the direct backend assembly path as “flatten first, build the prelude, generate the consolidated intermediate stage, then let the tail owner emit WEN/EN, assignments, and module closeout.”

## 2026-03-31: live direct backend pre-stage SystemVerilog prelude now has a dedicated owner
- Saved shipped behavior:
  - added [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPreludeSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPreludeSupport.pm) as the live owner of scaffold/declaration/enable/factorization-policy/prescan preparation before consolidated intermediate generation,
  - updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) so the direct backend now instantiates `backend_sv_generation_prelude_support`,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm) so it now composes the extracted prelude owner plus the existing stage/WEN-EN/assignment/closeout steps,
  - added [t/233-systemverilog-generation-prelude-support.t](/Users/richarddje/Documents/github/fsmgen/t/233-systemverilog-generation-prelude-support.t), retargeted [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t) and [t/232-systemverilog-generation-pipeline-support.t](/Users/richarddje/Documents/github/fsmgen/t/232-systemverilog-generation-pipeline-support.t),
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `96` reachable project files and `95` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the live direct backend pre-stage scaffold/declaration/enable/prescan sequence inside `GenerationPipelineSupport`,
  - it is the remaining lower-level coordination across the extracted prelude owner, consolidated-intermediate planning/stage composition, the narrowed generation pipeline owner, and broader direct-backend convergence,
  - and future sessions should read the direct backend assembly path as “flatten first, build the prelude, generate the consolidated intermediate stage, then emit WEN/EN, assignments, and module closeout.”

## 2026-03-31: live direct backend post-flattening SystemVerilog assembly now has a dedicated pipeline owner
- Saved shipped behavior:
  - added [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GenerationPipelineSupport.pm) as the live owner of the full step-2-through-step-7 post-flattening SystemVerilog assembly sequence,
  - updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) so the direct backend now instantiates `backend_sv_generation_pipeline_support`,
  - updated [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm) so it now keeps reset/module-attachment/flattening while delegating post-flattening HDL assembly,
  - added [t/232-systemverilog-generation-pipeline-support.t](/Users/richarddje/Documents/github/fsmgen/t/232-systemverilog-generation-pipeline-support.t), retargeted [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t),
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `95` reachable project files and `94` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the whole post-flattening SystemVerilog assembly sequence in `Orchestrator`,
  - it is the remaining lower-level coordination across consolidated-intermediate planning, stage preparation, live stage generation, the new generation pipeline owner, and broader direct-backend convergence,
  - and future sessions should read the direct backend split as “flatten first, then let the generation-pipeline owner assemble the module,” with `Orchestrator` now only bridging per-run state, flattening, and final pipeline handoff.

## 2026-03-31: live direct backend stage 6 now has its own explicit consolidated stage owner
- Saved shipped behavior:
  - added [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStageSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStageSupport.pm) as the live owner of full consolidated intermediate stage generation over stage preparation plus rendering,
  - updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) so the direct backend now instantiates `backend_sv_consolidated_intermediate_stage_support`,
  - updated [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm) so live stage 6 now delegates through that owner instead of hand-composing stage preparation plus rendering inline,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm) so the compatibility shell now delegates to the real live stage owner when it exists,
  - retargeted [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t) and [t/224-systemverilog-consolidated-intermediate-generation-support.t](/Users/richarddje/Documents/github/fsmgen/t/224-systemverilog-consolidated-intermediate-generation-support.t), added [t/231-systemverilog-consolidated-intermediate-stage-support.t](/Users/richarddje/Documents/github/fsmgen/t/231-systemverilog-consolidated-intermediate-stage-support.t),
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `94` reachable project files and `93` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the raw live stage-6 handoff in `Orchestrator`,
  - it is the remaining lower-level coordination across consolidated-intermediate planning, stage preparation, the new live stage owner, and broader direct-backend sequencing/convergence,
  - and future sessions should read the direct backend stage as “collect, normalize, classify, rescue/select, dependency-map/order, plan, project the prepared block, prepare the stage block, generate the live stage block, and then continue with WEN/EN plus assignment emission,” with the older generation, block, emitter, and intermediate dispatcher shells all remaining outside the live runtime spine.

## 2026-03-30: live direct backend no longer instantiates the consolidated intermediate generation compatibility shell
- Saved shipped behavior:
  - updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) so the direct backend no longer instantiates `backend_sv_consolidated_intermediate_generation_support`,
  - updated [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm) so live stage 6 now composes [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStagePreparationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStagePreparationSupport.pm) plus [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateRenderingSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateRenderingSupport.pm) directly,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm) so it now survives only as a compatibility-shell test surface outside the live backend path,
  - retargeted [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t) and [t/224-systemverilog-consolidated-intermediate-generation-support.t](/Users/richarddje/Documents/github/fsmgen/t/224-systemverilog-consolidated-intermediate-generation-support.t),
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `93` reachable project files and `92` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the live consolidated generation wrapper,
  - it is the remaining lower-level coordination across consolidated-intermediate planning, stage preparation, rendering, and direct orchestrator sequencing,
  - and future sessions should read the live direct backend stage as “collect, normalize, classify, rescue/select, dependency-map/order, plan, project the prepared block, prepare the stage block, render it, and sequence that directly from the orchestrator,” with the old generation, block, emitter, and intermediate dispatcher shells all outside the live runtime spine.

## 2026-03-30: live consolidated intermediate prepared-block rendering now has a dedicated backend owner
- Saved shipped behavior:
  - added [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateRenderingSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateRenderingSupport.pm) as the live owner of prepared-block rendering over the extracted declaration and assignment owners,
  - updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) so the direct backend now instantiates `backend_sv_consolidated_intermediate_rendering_support`,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm) so the live stage is now only the wrapper that composes stage preparation plus the rendering owner,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm) so the compatibility shell delegates to the new live rendering owner when that owner exists,
  - retargeted [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t) and [t/224-systemverilog-consolidated-intermediate-generation-support.t](/Users/richarddje/Documents/github/fsmgen/t/224-systemverilog-consolidated-intermediate-generation-support.t), and added [t/230-systemverilog-consolidated-intermediate-rendering-support.t](/Users/richarddje/Documents/github/fsmgen/t/230-systemverilog-consolidated-intermediate-rendering-support.t),
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `94` reachable project files and `93` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer final prepared-block rendering inside the live generation owner,
  - it is the remaining stage-level coordination across stage preparation, prepared-block rendering, and the narrowed generation wrapper,
  - and future sessions should read the direct backend stage as “collect, normalize, classify, rescue/select, dependency-map/order, plan, project the prepared block, prepare the stage block, render the prepared block, and hand that stage through the wrapper,” with the older block and emitter shells both outside the live runtime spine.

## 2026-03-30: live consolidated intermediate stage preparation now has a dedicated backend owner
- Saved shipped behavior:
  - added [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStagePreparationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateStagePreparationSupport.pm) as the live owner of prepared-block reconstruction from the extracted collection, planning, and prepared-block projection owners,
  - updated [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) so the direct backend now instantiates `backend_sv_consolidated_intermediate_stage_preparation_support`,
  - updated [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm) so the live stage now composes stage preparation plus final prepared-block rendering instead of rebuilding the prepared block inline,
  - kept [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateBlockSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateBlockSupport.pm) as a compatibility-shell test surface outside the live backend path with corrected POD about the new live owner,
  - retargeted [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t) and [t/224-systemverilog-consolidated-intermediate-generation-support.t](/Users/richarddje/Documents/github/fsmgen/t/224-systemverilog-consolidated-intermediate-generation-support.t), and added [t/229-systemverilog-consolidated-intermediate-stage-preparation-support.t](/Users/richarddje/Documents/github/fsmgen/t/229-systemverilog-consolidated-intermediate-stage-preparation-support.t),
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `93` reachable project files and `92` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer live prepared-block reconstruction inside generation support,
  - it is the remaining lower-level coordination across consolidated-intermediate planning, prepared-block projection, stage preparation, and final generation/rendering,
  - and future sessions should read the direct backend stage as “collect, normalize, classify, rescue/select, dependency-map/order, plan, project the prepared block, prepare the live stage block, and render,” with the old block and emitter shells both outside the runtime spine.

## 2026-03-30: live direct backend no longer instantiates the consolidated emitter compatibility shell
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) no longer instantiates `backend_sv_consolidated_intermediate`,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm) now owns final prepared-block rendering directly in addition to collection/planning/prepared-block stage handoff,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm) now survives only as a compatibility-shell test surface outside the live backend path,
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `92` reachable project files and `91` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the old consolidated emitter shell,
  - it is the remaining lower-level coordination across consolidated-intermediate planning, prepared-block projection, and live generation support,
  - and future sessions should read the live direct backend path as “collect, normalize, classify, rescue/select, dependency-map/order, plan, project the prepared block, and render,” with the old emitter shell outside the runtime spine.

## 2026-03-30: future `.fsm` hierarchy should be authored bottom-up but compiled from the top
- Saved direction:
  - whole `.fsm` designs should eventually behave like authored bottom-up N-level hierarchies with non-leaf composition nodes and leaf implementation nodes,
  - `fsmgen top.fsm` should remain the public UX and recursively realize child nodes level by level until the full top is emitted,
  - internal non-leaf reusable composition modules should eventually become first-class authored artifacts instead of composition remaining only a one-top shell over leaf children,
  - interface and semantic summaries should flow upward from children while binding/wiring is resolved at each parent level,
  - and the important implementation distinction is authored tree vs elaborated instance tree: source reuse may make the authored graph a DAG, while elaboration still produces a hierarchical instance tree.
- Important continuity note:
  - this was logged from explicit brainstorming as future architecture steering, not as a command to widen the current composition contract immediately,
  - future sessions should treat it as guidance for the reusable-source/composition lane under `R11`,
  - and the intended user experience stays simple even if the implementation becomes recursive: build leaves first, invoke only the top.

## 2026-03-30: actor-first protocol extraction guidance and first imported APB/AMBA fixtures are now saved
- Saved direction:
  - reviewed the external protocol-extraction references under `/Users/richarddje/Documents/livework/protocols/arm/amba/`,
  - the useful working method there is strongly aligned with the saved `H4` direction: start from normalized `Markdown`, work actor-first instead of protocol-as-a-monolith, and keep source facts, derived machine rules, local design decisions, and explicit abstractions separate,
  - the method artifacts worth preserving are: protocol dossier, actor catalog, actor sheet per actor, assertion ledger, abstraction/boundedness log, FSM mapping sheet, and validation log,
  - actor interfaces plus invariants/contracts/gates should be captured in plain English before `.fsm` emission,
  - and the repo now has first imported protocol fixtures in [fsm/apb_requester.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/apb_requester.fsm), [fsm/apb_completer.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/apb_completer.fsm), [fsm/apb_tb.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/apb_tb.fsm), and [fsm/amba_requester.fsm](/Users/richarddje/Documents/github/fsmgen/fsm/amba_requester.fsm).
- Important continuity note:
  - the imported APB top now resolves against prefixed child source names `apb_requester` and `apb_completer` so the dataset fits cleanly inside the repo-wide `fsm/` corpus,
  - all four imported fixtures were validated through the live `bin/fsmgen` entrypoint,
  - and this is dataset seeding plus method capture, not a roadmap lane switch away from active `R11`.

## 2026-03-30: protocol/TRM spec-to-`.fsm` intent capture is now saved as a separate future direction
- Saved direction:
  - treat future `PDF` / TRM / protocol-`Markdown` to `.fsm` work as a separate intent-capture lane rather than as HDL import under another name,
  - prefer the term `intent capture` over `intent synthesis` when the source is prose/specification text, because the output should stay honest about ambiguity and human confirmation,
  - model the likely pipeline as `PDF -> .md -> normalized spec IR -> recovered roles/transactions/timing rules/invariants -> .fsm + capture report`,
  - expect bounded outputs such as requester/initiator roles, completer/target roles, checker/monitor assets, reusable assertions/invariants, and optional `.fsm` composition/testbench harnesses for protocols like `APB`, `AMBA`, `AXI`, `I2C`, and `I2S`,
  - and treat this as assisted capture with explicit confidence/heuristic/ambiguity residue reporting, not as magical one-shot conversion.
- Important continuity note:
  - this was logged from explicit brainstorming and strong user agreement, not as an instruction to leave the active `R11` lane,
  - future sessions should treat it as a real long-term roadmap direction worth design/probe work,
  - and it should stay distinct from HDL import / intent recovery even if both directions eventually share middle-layer IRs.

## 2026-03-30: reusable library, semantic parameters, and phased intent-recovery start are now saved guidance
- Saved direction:
  - future reusable-library work should start as ordinary reusable `.fsm` assets flowing through the normal parser/IR/emitter path,
  - that library should begin with a small curated gold set rather than a broad primitive zoo or magical builtins,
  - future parameterization should use explicit semantic parameters plus explicit override binding that survives into IR rather than text/template preprocessing,
  - and HDL import / intent recovery can start with design/probe work plus bounded round-trip experiments, but serious implementation should stay behind the active forward/backend cleanup and language-contract hardening.
- Important continuity note:
  - this was logged from explicit brainstorming and is saved as guidance, not as an immediate lane switch,
  - future sessions should treat it as roadmap steering for when those lanes open, not as a command to stop `R11`.

## 2026-03-30: live direct backend no longer instantiates the consolidated block compatibility shell
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) no longer instantiates `backend_sv_consolidated_intermediate_block_support`,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm) now composes collection, planning, prepared-block projection, and final rendering directly,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateBlockSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateBlockSupport.pm) now survives only as a directly testable compatibility shell outside the live backend path,
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `93` reachable project files and `92` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the old consolidated block shell,
  - it is the remaining lower-level coordination across planning, prepared-block projection, stage generation, and final emission,
  - and future sessions should read the direct consolidated-intermediate path as “collect, normalize, classify, rescue/select, dependency-map/order, plan, project the prepared block, and render,” with the old block shell outside the live runtime spine.

## 2026-03-29: prepared consolidated intermediate block projection now has a dedicated owner
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePreparedBlockSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePreparedBlockSupport.pm) now owns prepared block-contract projection for the direct consolidated intermediate path,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateBlockSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateBlockSupport.pm) is now narrowed to collection-plus-planning handoff into that prepared-block owner,
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `94` reachable project files and `93` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer prepared block-contract projection inside the direct consolidated intermediate path,
  - it is the remaining lower-level coordination across block handoff, stage generation, and final emission,
  - and future sessions should now read that backend stage as “collect, normalize, classify, rescue/select, dependency-map/order, plan, hand off the block, project the prepared contract, and render.”

## 2026-03-29: consolidated intermediate dependency mechanics now have a dedicated owner
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateDependencySupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateDependencySupport.pm) now owns dependency-map construction plus dependency-safe ordering for the direct consolidated intermediate path,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePlanningSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePlanningSupport.pm) is now narrowed to overall plan composition over the extracted selection and dependency owners,
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `93` reachable project files and `92` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the dependency-map or ordering split inside the direct consolidated intermediate path,
  - it is the remaining lower-level coordination across plan composition, block preparation, and final emission,
  - and future sessions should now read that backend stage as “collect, normalize, classify, rescue/select, dependency-map/order, plan, prepare, and render.”

## 2026-03-28: consolidated intermediate classification now has a dedicated owner
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateClassificationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateClassificationSupport.pm) now owns the initial AST-first keep/filter partition for the direct consolidated intermediate path,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSelectionSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSelectionSupport.pm) is now narrowed to dependency-aware rescue plus final kept/filtered summary projection,
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `92` reachable project files and `91` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the first-pass classification split inside the direct consolidated intermediate path,
  - it is the remaining lower-level coordination across selection, planning, block preparation, and final emission,
  - and future sessions should read that backend stage as “collect, normalize, classify, rescue/select, plan, prepare, and render.”

## 2026-03-28: consolidated intermediate normalization now has a dedicated owner
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateNormalizationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateNormalizationSupport.pm) now owns runtime AST, width, dependency, rendered-expression, and live-usage normalization over the merged direct consolidated intermediate set,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSupport.pm) is now narrowed to trace plus merged-signal collection,
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `91` reachable project files and `90` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the collection-vs-normalization split inside the direct consolidated intermediate path,
  - it is the remaining lower-level coordination across selection, planning, block preparation, and final emission,
  - and future sessions should read that backend stage as “collect, normalize, select, plan, prepare, and render,” with collection and normalization now named as separate owners.

## 2026-03-28: consolidated intermediate stage generation now has a dedicated owner
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateGenerationSupport.pm) now owns the full direct consolidated-intermediate stage handoff for one FSM module,
  - [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm) no longer coordinates that stage inline,
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `90` reachable project files and `89` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the stage handoff from `Orchestrator`,
  - it is the remaining lower-level coordination inside the selection/planning/block/emitter cluster,
  - and the live import-tree note should now be read as “the direct consolidated-intermediate path has explicit owners for preparation, selection, planning, block prep, assignment emission, declaration rendering, stage generation, and final block composition.”

## 2026-03-28: consolidated intermediate declaration rendering now has a dedicated owner
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateDeclarationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateDeclarationSupport.pm) now owns prepared consolidated wire declarations on the direct backend path,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm) is now narrowed to final block composition over declaration and assignment owners,
  - and [t/223-systemverilog-consolidated-intermediate-declaration-support.t](/Users/richarddje/Documents/github/fsmgen/t/223-systemverilog-consolidated-intermediate-declaration-support.t) plus the tightened owner checks now lock that split directly.
- Important continuity note:
  - the next likely seam is no longer “who owns prepared consolidated wire declarations,”
  - it is the remaining coordination between selection, planning, block preparation, and the narrowed emitter,
  - and the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) should now be read as “the direct consolidated intermediate path is split into preparation, selection, planning, block preparation, assignment emission, declaration rendering, and final block composition.”

## 2026-03-28: live direct backend no longer instantiates the intermediate dispatcher shell
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSelectionSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSelectionSupport.pm) now owns the live AST-first consolidated keep/filter dispatch directly by combining the recovery and filter-policy owners,
  - [perl/FSM/HDL/FlattenedDT.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT.pm) no longer instantiates `backend_sv_intermediate_support`,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm) now survives only as a compatibility-shell package for direct owner tests,
  - and [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now records the measured post-change snapshot of `88` reachable project files and `87` reachable `.pm` packages.
- Important continuity note:
  - the next likely seam is no longer the old intermediate dispatcher shell,
  - it is the remaining coordination across selection, planning, block preparation, and the narrowed consolidated emitter,
  - and future sessions should read the direct consolidated-intermediate path as “collection, live selection, planning, block preparation, assignment emission, and final block/declaration emission,” with the old dispatcher shell outside the runtime spine.

## 2026-03-28: consolidated intermediate assignment emission now has a dedicated owner
- Saved shipped behavior:
- [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateAssignmentSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateAssignmentSupport.pm) now owns prepared consolidated assign emission on the direct backend path,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm) is now narrowed to block composition plus consolidated wire-declaration rendering,
  - and [t/222-systemverilog-consolidated-intermediate-assignment-support.t](/Users/richarddje/Documents/github/fsmgen/t/222-systemverilog-consolidated-intermediate-assignment-support.t) plus the tightened owner checks now lock that split directly.
- Important continuity note:
  - the next likely seam is no longer “who owns prepared consolidated assign emission,”
  - it is the remaining coordination between prepared block composition, declaration rendering, and the narrowed emitter shell,
  - and the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) should now be read as “the direct consolidated intermediate path is split into preparation, selection, planning, block preparation, assignment emission, and block/declaration emission.”

## 2026-03-28: consolidated intermediate selection now has a dedicated owner
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSelectionSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSelectionSupport.pm) now owns dependency-aware keep/filter/rescue selection over the normalized consolidated intermediate set on the direct backend path,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePlanningSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePlanningSupport.pm) is now narrowed to dependency-map construction, dependency-safe ordering, and overall plan composition,
  - and [t/221-systemverilog-consolidated-intermediate-selection-support.t](/Users/richarddje/Documents/github/fsmgen/t/221-systemverilog-consolidated-intermediate-selection-support.t) plus the tightened planning/owner checks now lock that split directly.
- Important continuity note:
  - the next likely seam is no longer “who owns set-level keep/filter/rescue selection” in the direct consolidated intermediate path,
  - it is the remaining coordination between normalized collection, selection, planning, block preparation, and final emission,
  - and the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) should now be read as “the direct consolidated intermediate path is split into preparation, selection, planning, block preparation, and emission.”

## 2026-03-28: new-session bootstrap is now a dedicated root document
- Saved shipped behavior:
  - [SESSION_BOOTSTRAP.md](/Users/richarddje/Documents/github/fsmgen/SESSION_BOOTSTRAP.md) now exists as the canonical first-task file for a normal new engineering session,
  - it tells a new agent to read [README.md](/Users/richarddje/Documents/github/fsmgen/README.md), read the README-linked Markdown set, analyze [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) and its import tree, refresh [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) if needed, and then continue against [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md),
  - and [README.md](/Users/richarddje/Documents/github/fsmgen/README.md) now points to that file explicitly in fast ramp-up, the documentation index, and a fresh-session shortcut note.
- Important continuity note:
  - for future sessions, the shortest reliable startup instruction is now:
    - `Read SESSION_BOOTSTRAP.md and start from there.`
  - this is meant to be the default engineering-session ritual, not a ban on narrower one-off tasks when the user explicitly wants something else.

## 2026-03-28: refreshed `bin/fsmgen` import-tree measurement snapshot
- Saved current analysis:
  - [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes measured package-family counts, thin-coordinator line counts, and the current largest reachable files by line count,
  - the saved static trace still lands at `87` project files / `86` `.pm` packages reachable from [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen),
  - and the saved interpretation is explicit: `HDLGenerator` is now honestly thin, while the remaining active `R11` gravity is still lower in the direct backend/support stack and a few large composition/reporting builders.
- Important continuity note:
  - future sessions should treat the measured hotspot list as context, not as an automatic refactor order,
  - the next roadmap slice should still be chosen by architectural leverage, not by raw file size alone.

## 2026-03-28: direct intermediate width normalization now has a dedicated backend owner
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm) now owns direct intermediate width normalization and recursive width inference,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalRecoverySupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalRecoverySupport.pm) is now narrowed to runtime-AST lookup, rendered-expression recovery, and dependency recovery,
  - and [t/220-systemverilog-intermediate-signal-width-support.t](/Users/richarddje/Documents/github/fsmgen/t/220-systemverilog-intermediate-signal-width-support.t) now locks the extracted width owner directly.
- Important continuity note:
  - the next likely seam is no longer “who owns intermediate width normalization,”
  - it is the remaining direct-backend coordination around consolidated intermediate rendering/filter/ordering and any still-muddied handoff between the neighboring intermediate owners,
  - and the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) should now be read as “the direct intermediate path is split into recovery, width, filter heuristics, filter dispatch, consolidated preparation, consolidated planning, block preparation, and final emission.”

## 2026-03-28: consolidated intermediate block preparation now has a dedicated owner
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateBlockSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateBlockSupport.pm) now owns the collection-plus-planning handoff for one prepared consolidated intermediate block on the direct backend path,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm) is now narrowed to pure rendering from that prepared block contract,
  - and [t/219-systemverilog-consolidated-intermediate-block-support.t](/Users/richarddje/Documents/github/fsmgen/t/219-systemverilog-consolidated-intermediate-block-support.t) now locks the extracted owner directly.
- Important continuity note:
  - the next likely seam is no longer collection-plus-planning handoff inside the direct consolidated emitter,
  - it is the remaining direct rendering/sequence coordination around the consolidated intermediate path and the neighboring intermediate recovery/filter owners,
  - and the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) should now be read as “the direct consolidated intermediate path is split into support, planning, block preparation, and rendering.”

## 2026-03-28: fixpoint loop state now has a dedicated owner
- Saved shipped behavior:
  - [perl/FSM/HDL/Factorization/Fixpoint/LoopStateSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint/LoopStateSupport.pm) now owns aggregate loop-state creation, accepted-pass outcome application, and final termination/result normalization for the iterative post-substitution factorization path,
  - [perl/FSM/HDL/Factorization/Fixpoint.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint.pm) is now narrowed further to pass scheduling and top-level coordination,
  - and [t/218-factorization-fixpoint-loop-state-support.t](/Users/richarddje/Documents/github/fsmgen/t/218-factorization-fixpoint-loop-state-support.t) now locks the extracted owner directly against continue, terminate, terminate-after-accept, and pass-cap finalization paths.
- Important continuity note:
  - the next likely seam is no longer the fixpoint aggregate loop-state contract,
  - it is the remaining direct-backend dispatcher/planning/emission coordination around the consolidated intermediate path,
  - and the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) should now be read as “the direct fixpoint path is split into pass scheduling, loop state, pass execution, and pass helpers.”

## 2026-03-28: fixpoint pass execution now has a dedicated factorization owner
- Saved shipped behavior:
  - [perl/FSM/HDL/Factorization/Fixpoint/PassExecutionSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint/PassExecutionSupport.pm) now owns one-pass factorizer construction, repeated-signature short-circuit detection, and per-pass substitution/update execution,
  - [perl/FSM/HDL/Factorization/Fixpoint.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint.pm) is now narrowed further to the outer loop, pass-cap, and aggregate-result contract,
  - and [t/217-factorization-fixpoint-pass-execution-support.t](/Users/richarddje/Documents/github/fsmgen/t/217-factorization-fixpoint-pass-execution-support.t) now locks the extracted owner directly against the prepared no-new-candidate and repeated-signature paths.
- Important continuity note:
  - the next likely seam is no longer “who owns one prepared second-pass execution,”
  - it is the remaining aggregate termination/policy gravity in [perl/FSM/HDL/Factorization/Fixpoint.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint.pm) plus the downstream direct-backend planning/emission convergence,
  - and the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) should now be read as “the direct fixpoint path is split into outer loop, pass execution, and pass helpers.”

## 2026-03-28: direct intermediate filter heuristics now have a dedicated backend owner
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalFilterPolicySupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalFilterPolicySupport.pm) now owns AST-aware keep/filter heuristics, runtime-AST-miss live-usage fallback, and the small AST-shape predicates for the direct intermediate-signal path,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm) is now narrowed to consolidated-signal filter dispatch over recovery lookup plus that extracted policy owner,
  - and [t/216-systemverilog-intermediate-signal-filter-policy-support.t](/Users/richarddje/Documents/github/fsmgen/t/216-systemverilog-intermediate-signal-filter-policy-support.t) plus the tightened [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t) now lock that backend split directly.
- Important continuity note:
  - the next likely seam is no longer “who owns the AST-vs-runtime filter heuristics,”
  - it is the remaining post-factorization loop/planning/emission gravity around [perl/FSM/HDL/Factorization/Fixpoint.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePlanningSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePlanningSupport.pm), and [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm),
  - and the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) should now be read as “the direct intermediate path is split into recovery, filter heuristics, filter dispatch, consolidated preparation, consolidated planning, and final emission.”

## 2026-03-28: consolidated intermediate planning now has a dedicated backend owner
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePlanningSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediatePlanningSupport.pm) now owns dependency-map construction, dependency-aware rescue/filter planning, and dependency-safe emission ordering for consolidated intermediates,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm) is now narrowed to final wire/assign emission from that extracted plan,
  - and [t/215-systemverilog-consolidated-intermediate-planning-support.t](/Users/richarddje/Documents/github/fsmgen/t/215-systemverilog-consolidated-intermediate-planning-support.t) now locks that owner directly.
- Important continuity note:
  - the next likely seam is no longer “who owns consolidated rescue/order planning,”
  - it is the remaining post-factorization/filter-policy gravity in [perl/FSM/HDL/Factorization/Fixpoint.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint.pm) and [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm),
  - and the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) should now be read as “the direct consolidated intermediate path is split into preparation, planning, and emission.”

## 2026-03-28: fixpoint pass support now has a dedicated factorization owner
- Saved shipped behavior:
  - [perl/FSM/HDL/Factorization/Fixpoint/PassSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint/PassSupport.pm) now owns the iterative second-pass helper family: primary intermediate lookup, deterministic pass signatures, second-pass name-collision recovery, and new-signal projection/debugging,
  - [perl/FSM/HDL/Factorization/Fixpoint.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint.pm) is now narrowed to the loop, termination, and aggregate-result contract,
  - and [t/214-factorization-fixpoint-pass-support.t](/Users/richarddje/Documents/github/fsmgen/t/214-factorization-fixpoint-pass-support.t) now locks that extracted owner directly.
- Important continuity note:
  - the next likely seam is no longer “who owns the fixpoint pass helpers,”
  - it is the remaining post-factorization policy/termination gravity in [perl/FSM/HDL/Factorization/Fixpoint.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint.pm) plus the downstream direct-backend filter/order/recovery owners,
  - and the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) should now be read as “the direct factorization path is split into first-pass owner, fixpoint loop owner, and per-pass helper owner.”

## 2026-03-28: direct SystemVerilog global factorization now has a dedicated backend owner
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GlobalFactorizationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GlobalFactorizationSupport.pm) now owns the direct first-pass AST-factorization pipeline: factorizer construction, substitution, original-AST refresh, fixpoint delegation, and factorizer persistence,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm) now asks that owner directly for first-pass factorization,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ASTFactorizationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ASTFactorizationSupport.pm) is now narrowed to substituted-AST lookup plus the legacy direct intermediate-signal rendering helper,
  - and [t/211-systemverilog-global-factorization-support.t](/Users/richarddje/Documents/github/fsmgen/t/211-systemverilog-global-factorization-support.t) plus the tightened [t/201-systemverilog-ast-factorization-support.t](/Users/richarddje/Documents/github/fsmgen/t/201-systemverilog-ast-factorization-support.t) and [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t) now lock that split directly.
- Important continuity note:
  - the next likely seam is no longer “who owns the first factorization pass,”
  - it is the remaining post-factorization/fixpoint gravity around [perl/FSM/HDL/Factorization/Fixpoint.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm), and [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm).

## 2026-03-27: EnableGraph factorization support now has a dedicated owner
- Saved shipped behavior:
  - [perl/FSM/Synthesis/EnableGraph/FactorizationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph/FactorizationSupport.pm) now owns the synthesis-side factorization-analysis and substitution/live-usage evidence family: logical-operation counting, factorizer feed preparation, second-pass feed selection, substitution synchronization, signal-reference checks, and live-usage derivation for factorized intermediates,
  - [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ASTFactorizationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ASTFactorizationSupport.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm), and [perl/FSM/HDL/Factorization/Fixpoint.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint.pm) now ask that owner directly,
  - and [t/203-enable-graph-factorization-support.t](/Users/richarddje/Documents/github/fsmgen/t/203-enable-graph-factorization-support.t) plus [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t) now lock the extracted owner boundary.
- Important continuity note:
  - this is the second real owner pulled out of the larger `EnableGraph` gravity well, so the remaining pressure is now even more clearly broader planning/policy plus fixpoint iteration,
  - the direct owner test also records an honest nuance we should preserve: in the prepared backend context, a factorized signal like `A_or_B` can be live by substitution evidence only rather than by final owner-side expression presence,
  - and the next likely seam is broader cleanup in [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm) or narrower iterative-factorization policy cleanup in [perl/FSM/HDL/Factorization/Fixpoint.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint.pm).

## 2026-03-27: EnableGraph intermediate-signal support now has a dedicated owner
- Saved shipped behavior:
  - [perl/FSM/Synthesis/EnableGraph/IntermediateSignalSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph/IntermediateSignalSupport.pm) now owns normalized intermediate-signal registry access, native defining-AST lookup, compatibility-expression parsing, rendered-expression recovery, signal-name dependency AST recovery, and referenced-intermediate declaration tracking for the synthesis side,
  - [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm), [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm), and [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm) now ask that owner directly,
  - and [t/202-enable-graph-intermediate-signal-support.t](/Users/richarddje/Documents/github/fsmgen/t/202-enable-graph-intermediate-signal-support.t) plus [t/10-ast-first-enable-structure.t](/Users/richarddje/Documents/github/fsmgen/t/10-ast-first-enable-structure.t) now lock the extracted owner boundary.
- Important continuity note:
  - this is the first real owner pulled out of the larger `EnableGraph` synthesis gravity well, not another direct SystemVerilog package split,
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) should now be read as “remaining backend pressure is broader `EnableGraph` planning plus `Fixpoint`, with intermediate-signal support already separated,”
  - and the next likely seam is deeper cleanup in [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm) or [perl/FSM/HDL/Factorization/Fixpoint.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint.pm), not another intermediate-signal extraction.

## 2026-03-27: direct SystemVerilog AST factorization support now has a dedicated backend owner and the old backend package is retired
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ASTFactorizationSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ASTFactorizationSupport.pm) now owns direct generated-module AST factorization, post-substitution fixpoint delegation, substituted-AST lookup, and the legacy direct intermediate-signal rendering helper,
  - the live direct backend owners now ask that package directly instead of routing through [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm),
  - and [t/201-systemverilog-ast-factorization-support.t](/Users/richarddje/Documents/github/fsmgen/t/201-systemverilog-ast-factorization-support.t) now locks the extracted owner directly against a realistic shared-expression factorization fixture.
- Important continuity note:
  - this retires the last live direct SystemVerilog monolith instead of keeping a fake compatibility shell,
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) should now be read as “direct backend gravity lives in explicit owners plus `EnableGraph` / fixpoint support,”
  - and the next likely seam is deeper cleanup in [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm) or [perl/FSM/HDL/Factorization/Fixpoint.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/Factorization/Fixpoint.pm), not more SystemVerilog package splitting.

## 2026-03-27: direct SystemVerilog consolidated intermediate emission now has a dedicated backend owner
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateEmitter.pm) now owns direct generated-module consolidated intermediate-signal emission from the prepared AST-factorization plus pre-scan context,
  - [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm) now asks that owner directly for the consolidated wire/assign block before unified WEN/EN generation,
  - and [t/200-systemverilog-consolidated-intermediate-emitter.t](/Users/richarddje/Documents/github/fsmgen/t/200-systemverilog-consolidated-intermediate-emitter.t) now locks the extracted owner directly against the emitted backend prefix for a realistic shared-expression direct-root fixture.
- Important continuity note:
  - this is another real backend split under the older direct generated-module path, not more pipeline work,
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes the new consolidated-intermediate owner explicitly,
  - and the next likely seam is deeper cleanup inside the remaining AST-factorization/substitution side of [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm) or the planning surface in [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm).

## 2026-03-27: direct SystemVerilog intermediate-signal support now has a dedicated backend owner
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalSupport.pm) now owns direct generated-module runtime AST recovery, rendered-expression caching, dependency recovery, width inference, and AST-aware filtering for consolidated intermediate signals,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm) now asks that owner directly during consolidated intermediate-signal generation,
  - and [t/07-runtime-ast-miss-dependency-recovery.t](/Users/richarddje/Documents/github/fsmgen/t/07-runtime-ast-miss-dependency-recovery.t) plus [t/08-driving-ast-canonicalization.t](/Users/richarddje/Documents/github/fsmgen/t/08-driving-ast-canonicalization.t) now lock the extracted owner directly.
- Important continuity note:
  - this is another real backend split under the older direct generated-module path, not pipeline work,
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes the new intermediate-signal support owner explicitly,
  - and the next likely seam is deeper cleanup inside the remaining consolidated intermediate-signal emission/factorization core in [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm) or the planning surface in [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm).

## 2026-03-27: direct SystemVerilog internal declaration rendering now has a dedicated backend owner
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/InternalDeclarationEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/InternalDeclarationEmitter.pm) now owns direct generated-module internal storage and helper-register declaration rendering,
  - [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm) now asks that owner directly for the declaration block after scaffold rendering,
  - and [t/199-systemverilog-internal-declaration-emitter.t](/Users/richarddje/Documents/github/fsmgen/t/199-systemverilog-internal-declaration-emitter.t) now locks the extracted owner against the emitted backend prefix for a realistic declaration-heavy direct-root fixture.
- Important continuity note:
  - this is another real backend split under the older direct generated-module path, not pipeline work,
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes the new declaration owner explicitly,
  - and the next likely seam is deeper cleanup inside the remaining [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm) intermediate-signal/consolidation core or the planning surface in [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm).

## 2026-03-26: direct SystemVerilog scaffold rendering now has a dedicated backend owner
- Saved shipped behavior:
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ScaffoldEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ScaffoldEmitter.pm) now owns direct generated-module header, module declaration, state encoding, and state register rendering,
  - [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm) now asks that owner directly for the top-of-module scaffold family,
  - and [t/198-systemverilog-scaffold-emitter.t](/Users/richarddje/Documents/github/fsmgen/t/198-systemverilog-scaffold-emitter.t) now locks the extracted owner against the emitted backend prefix for both regular-state and standalone-DT roots.
- Important continuity note:
  - this is a real backend split under the older direct generated-module path, not more pipeline facade cleanup,
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes the new scaffold owner explicitly,
  - and the next likely seam is deeper cleanup inside the remaining [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm) / [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm) core.

## 2026-03-26: old source-frontend wrapper residue is now gone from the pipeline facade
- Saved shipped behavior:
  - the remaining regression callers now ask [perl/FSM/Pipeline/SourceFrontend.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceFrontend.pm) directly for parse/classify/composition-parse/semantic-module creation,
  - [t/197-pipeline-source-frontend.t](/Users/richarddje/Documents/github/fsmgen/t/197-pipeline-source-frontend.t) now locks `SourceFrontend` against the real pipeline result surface rather than the removed facade wrappers,
  - and [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) no longer carries any frontend pass-through methods.
- Important continuity note:
  - `HDLGenerator` is now effectively the public entry facade plus shared config only,
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) should now be read as “orchestrators plus explicit owners do the work; `HDLGenerator` just starts it,”
  - and the next likely seam is now deeper cleanup under the older direct backend family rather than more facade trimming.

## 2026-03-26: old direct generated-module helper residue is now gone from the pipeline facade
- Saved shipped behavior:
  - [perl/FSM/Pipeline/DirectGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/DirectGenerationOrchestrator.pm), [perl/FSM/Composition/GeneratedChildRealizer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GeneratedChildRealizer.pm), and [perl/FSM/Composition/GenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GenerationOrchestrator.pm) now ask the explicit direct-root/generated-module owner packages directly instead of routing through `HDLGenerator` wrappers,
  - the direct-owner coverage in [t/191-forward-intent-hir-builder-direct-root.t](/Users/richarddje/Documents/github/fsmgen/t/191-forward-intent-hir-builder-direct-root.t), [t/192-forward-lowered-rtl-ir-builder-direct-root.t](/Users/richarddje/Documents/github/fsmgen/t/192-forward-lowered-rtl-ir-builder-direct-root.t), [t/193-forward-structural-rtl-ir-builder-direct-root.t](/Users/richarddje/Documents/github/fsmgen/t/193-forward-structural-rtl-ir-builder-direct-root.t), [t/194-generated-module-emitter.t](/Users/richarddje/Documents/github/fsmgen/t/194-generated-module-emitter.t), [t/196-generated-module-info-builder.t](/Users/richarddje/Documents/github/fsmgen/t/196-generated-module-info-builder.t), [t/182-composition-result-metadata-builder.t](/Users/richarddje/Documents/github/fsmgen/t/182-composition-result-metadata-builder.t), and [t/189-composition-generation-orchestrator.t](/Users/richarddje/Documents/github/fsmgen/t/189-composition-generation-orchestrator.t) now points at those real owners too,
  - and [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) no longer carries the old direct helper family for direct-root IR building, generated-module metadata helpers, backend glue, or statistics seed access.
- Important continuity note:
  - `HDLGenerator` is now much closer to the intended thin facade shape,
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) should now be read as “orchestrator family is the hub, `HDLGenerator` is the public facade” rather than the older monolith reading,
  - and the next likely seam is now the small remaining public source-frontend facade or deeper cleanup under the older direct backend family.

## 2026-03-26: old composition reporting helper residue is now gone from the pipeline facade
- Saved shipped behavior:
  - [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) no longer owns the old composition failure-summary and provenance/override/block label helper family,
  - [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) now asks [perl/FSM/Composition/FailureReportBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/FailureReportBuilder.pm) and [perl/FSM/Composition/ProvenanceReportBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/ProvenanceReportBuilder.pm) for those reporting surfaces directly,
  - and [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now anchors direct failure-summary coverage to the failure-report builder owner instead of the pipeline facade.
- Important continuity note:
  - this is another real `HDLGenerator` thinning step, not just a docs rename,
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now reflects that `bin/fsmgen` directly imports those builder owners,
  - and the next likely seam remains the thinner remaining `HDLGenerator` facade/helper residue or deeper cleanup under the older direct generated-module backend family.

## 2026-03-26: bounded source parsing and semantic-module creation now live in a dedicated frontend package
- Saved shipped behavior:
  - [perl/FSM/Pipeline/SourceFrontend.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceFrontend.pm) now owns bounded source parsing, source-kind classification, typed composition parsing, and semantic FSM/DT module creation,
  - the top-level source orchestrator, direct-root orchestrator, composition generation orchestrator, and generated-child realizer now call that owner directly,
  - and [t/197-pipeline-source-frontend.t](/Users/richarddje/Documents/github/fsmgen/t/197-pipeline-source-frontend.t) now locks the extracted owner directly against the pipeline facade surface.
- Important continuity note:
  - `HDLGenerator` no longer keeps that frontend family inline,
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes `SourceFrontend` explicitly in the pipeline/frontend layer,
  - and the next likely seam is now the thinner remaining `HDLGenerator` facade/helper residue or deeper cleanup under the older direct generated-module backend family.

## 2026-03-26: bounded generated-module module_info construction now lives in a dedicated pipeline builder
- Saved shipped behavior:
  - [perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm) now owns bounded generated-module `module_info` construction from semantic FSM/DT modules plus their intent HIR,
  - that package now also owns lowered generated-analysis enrichment and the normalized query surface over output-drive families and grouped standalone-DT multi-drive targets,
  - and [t/196-generated-module-info-builder.t](/Users/richarddje/Documents/github/fsmgen/t/196-generated-module-info-builder.t) now locks the extracted owner directly against the pipeline result surface.
- Important continuity note:
  - `DirectGenerationOrchestrator` and `GeneratedChildRealizer` no longer keep that generated-module metadata family inline,
  - `HDLGenerator` now only keeps thin delegations for the same family,
  - [t/194-generated-module-emitter.t](/Users/richarddje/Documents/github/fsmgen/t/194-generated-module-emitter.t) was also tightened to ignore non-semantic intermediate declaration ordering,
  - and the next likely seam is now the thinner remaining `HDLGenerator` facade/helper residue or deeper cleanup under the older `FlattenedDT` / `EnableGraph` backend family.

## 2026-03-26: top-level source/file dispatch now lives in a dedicated pipeline orchestrator
- Saved shipped behavior:
  - [perl/FSM/Pipeline/SourceGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/SourceGenerationOrchestrator.pm) now owns top-level source-file orchestration,
  - that package now parses one source file, classifies the root kind, dispatches into the direct-root or composition orchestrator, and drives the surrounding extension-hook/final-result boundary,
  - and [t/195-pipeline-source-generation-orchestrator.t](/Users/richarddje/Documents/github/fsmgen/t/195-pipeline-source-generation-orchestrator.t) now locks the extracted owner directly across direct-root, composition, and extension-hook paths.
- Important continuity note:
  - `HDLGenerator` no longer keeps the top-level parse/classify/dispatch/finalization cluster inline,
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes `SourceGenerationOrchestrator` explicitly in the pipeline hub family,
  - and the next likely seam is now the thinner remaining `HDLGenerator` facade residue or deeper cleanup under the older `FlattenedDT` / `EnableGraph` backend family.

## 2026-03-26: bounded direct generated-module backend execution now lives in a dedicated backend package
- Saved shipped behavior:
  - [perl/FSM/Backend/GeneratedModuleEmitter.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Backend/GeneratedModuleEmitter.pm) now owns bounded direct generated-module backend execution for direct FSM/DT roots and realized generated children,
  - that package now also owns backend-method selection, backend statistics collection, and standalone-DT assertion postprocessing around the existing `FlattenedDT` backend family,
  - and [t/194-generated-module-emitter.t](/Users/richarddje/Documents/github/fsmgen/t/194-generated-module-emitter.t) now locks the extracted backend owner directly against the full pipeline result surface.
- Important continuity note:
  - `HDLGenerator`, `DirectGenerationOrchestrator`, and `GeneratedChildRealizer` no longer keep that bounded direct backend family inline,
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes `GeneratedModuleEmitter` explicitly in the direct single-module backend family,
  - and the next likely seam is now broader `HDLGenerator` facade/coordinator cleanup or deeper cleanup under the older `FlattenedDT` / `EnableGraph` backend family.

## 2026-03-26: direct-root StructuralRTLIR construction now lives in the IR builder package
- Saved shipped behavior:
  - [perl/FSM/IR/StructuralRTLIRBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/StructuralRTLIRBuilder.pm) now owns bounded direct-root structural-IR construction from generated-module analysis,
  - that package now also owns direct-root module-boundary port assembly and implicit-system-port structural projection,
  - and [t/193-forward-structural-rtl-ir-builder-direct-root.t](/Users/richarddje/Documents/github/fsmgen/t/193-forward-structural-rtl-ir-builder-direct-root.t) now locks the extracted direct-root owner directly against the pipeline result surface.
- Important continuity note:
  - `HDLGenerator` no longer owns those direct-root structural helper families inline,
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now describes `StructuralRTLIRBuilder` as a direct-root plus composition-top structural builder,
  - and the next likely seam is now the remaining direct-path backend residue or a broader `HDLGenerator` facade split.

## 2026-03-26: direct-root LoweredRTLIR construction now lives in the IR builder package
- Saved shipped behavior:
  - [perl/FSM/IR/LoweredRTLIRBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/LoweredRTLIRBuilder.pm) now owns bounded direct-root lowered-IR construction from generated-module analysis plus direct backend analysis state,
  - that package now also owns direct-root output-drive-family analysis, standalone-DT lowered-target assembly, and onehot-style multi-drive assertion metadata,
  - and [t/192-forward-lowered-rtl-ir-builder-direct-root.t](/Users/richarddje/Documents/github/fsmgen/t/192-forward-lowered-rtl-ir-builder-direct-root.t) now locks the extracted direct-root owner directly against the pipeline result surface.
- Important continuity note:
  - `HDLGenerator` no longer owns those direct-root lowered helper families inline,
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now describes `LoweredRTLIRBuilder` as a direct-root plus composition-top lowered builder,
  - and the next likely seam is now the remaining direct-path structural builder residue or a broader `HDLGenerator` facade split.

## 2026-03-26: direct-root IntentHIR construction now lives in the IR builder package
- Saved shipped behavior:
  - [perl/FSM/IR/IntentHIRBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/IntentHIRBuilder.pm) now owns bounded direct-root semantic-HIR construction from a semantic FSM/DT module,
  - that package now also owns direct-root signal-analysis grouping, direction inference, and standalone-DT enable-family assembly,
  - and [t/191-forward-intent-hir-builder-direct-root.t](/Users/richarddje/Documents/github/fsmgen/t/191-forward-intent-hir-builder-direct-root.t) now locks the extracted direct-root owner directly against the pipeline result surface.
- Important continuity note:
  - `HDLGenerator` no longer owns those direct-root semantic helper families inline,
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now describes `IntentHIRBuilder` as a direct-root plus composition-top semantic builder,
  - and the next likely seam is now the remaining direct-path lowered/structural builder residue or a broader `HDLGenerator` facade split.

## 2026-03-26: direct-root generation orchestration now lives in a dedicated pipeline package
- Saved shipped behavior:
  - [perl/FSM/Pipeline/DirectGenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/DirectGenerationOrchestrator.pm) now owns bounded non-composition source-to-result orchestration,
  - that package now coordinates semantic module creation, forward-IR extraction, direct HDL generation, module-info enrichment, structural IR export, and statistics collection,
  - and [t/190-pipeline-direct-generation-orchestrator.t](/Users/richarddje/Documents/github/fsmgen/t/190-pipeline-direct-generation-orchestrator.t) now locks the new owner directly against the pipeline result surface.
- Important continuity note:
  - this removes the last obvious direct-root result-assembly cluster from [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm),
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes `DirectGenerationOrchestrator` in the pipeline/orchestration layer,
  - and the next likely seam is now direct-path builder/backend residue or a broader `HDLGenerator` facade split rather than one more result-assembly extraction.

## 2026-03-26: composition generation orchestration now lives in a dedicated composition package
- Saved shipped behavior:
  - [perl/FSM/Composition/GenerationOrchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GenerationOrchestrator.pm) now owns bounded composition source-to-result orchestration,
  - that package now coordinates plan construction, child-export projection, composition-top forward-IR assembly, structural top emission, and result-metadata/statistics assembly,
  - and [t/189-composition-generation-orchestrator.t](/Users/richarddje/Documents/github/fsmgen/t/189-composition-generation-orchestrator.t) now locks the new owner directly against the pipeline result surface.
- Important continuity note:
  - this removes the last obvious composition-top result-assembly cluster from [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm),
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes `GenerationOrchestrator` in the composition layer,
  - and the next likely seam is now the broader non-composition/direct-root coordinator path rather than one more composition-top helper extraction.

## 2026-03-26: composition-top LoweredRTLIR construction now lives in a dedicated IR builder package
- Saved shipped behavior:
  - [perl/FSM/IR/LoweredRTLIRBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/LoweredRTLIRBuilder.pm) now owns bounded composition-top `LoweredRTLIR` construction,
  - that package now builds the lowered top surface from an already-built composition plan plus structural, semantic, and shared-datapath inputs,
  - and [t/188-composition-lowered-rtl-ir-builder.t](/Users/richarddje/Documents/github/fsmgen/t/188-composition-lowered-rtl-ir-builder.t) now locks the new owner directly against the pipeline result surface.
- Important continuity note:
  - this removes another real forward-IR assembly seam from [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm),
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes `LoweredRTLIRBuilder` in the forward-IR layer,
  - and the next likely seam is now a broader direct-root/orchestrator split or another remaining coordinator pocket rather than one more inline composition-top IR builder.

## 2026-03-25: composition-top IntentHIR construction now lives in a dedicated IR builder package
- Saved shipped behavior:
  - [perl/FSM/IR/IntentHIRBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/IR/IntentHIRBuilder.pm) now owns bounded composition-top `IntentHIR` construction,
  - that package now builds the semantic top surface from an already-built composition plan plus structural and child-export inputs,
  - and [t/187-composition-intent-hir-builder.t](/Users/richarddje/Documents/github/fsmgen/t/187-composition-intent-hir-builder.t) now locks the new owner directly against the pipeline result surface.
- Important continuity note:
  - this removes another real forward-IR assembly seam from [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm),
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes `IntentHIRBuilder` in the forward-IR layer,
  - and the next likely seam is the matching lowered-IR builder split or a broader direct-root/orchestrator split.

## 2026-03-25: composition plan orchestration now lives in a dedicated builder package
- Saved shipped behavior:
  - [perl/FSM/Composition/PlanBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/PlanBuilder.pm) now owns the bounded composition-plan orchestration family,
  - that package now handles child realization dispatch, `?ports` shape gating, top-port inference handoff, lane selection, and shared-datapath plan augmentation,
  - and [t/186-composition-plan-builder.t](/Users/richarddje/Documents/github/fsmgen/t/186-composition-plan-builder.t) now locks the new owner directly across bounded `C1`, `C3`, and `C4` rebuilds.
- Important continuity note:
  - this removes one of the last obvious composition-shape coordination clusters from [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm),
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes `PlanBuilder` in the composition-builder layer,
  - and the next likely seam is another remaining result/orchestration pocket or a direct-root/orchestrator split.

## 2026-03-25: rtl child realization now lives in a dedicated composition package
- Saved shipped behavior:
  - [perl/FSM/Composition/RTLChildRealizer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLChildRealizer.pm) now owns the bounded `?rtl` child realization family,
  - that package now turns already-loaded embedded or sidecar `.rtlif` metadata into normalized realized-child carriers,
  - and [t/185-composition-rtl-child-realizer.t](/Users/richarddje/Documents/github/fsmgen/t/185-composition-rtl-child-realizer.t) now locks the new owner directly across both embedded-root and sidecar metadata paths.
- Important continuity note:
  - this removes another real child/source-orchestration pocket from [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm),
  - [perl/FSM/Composition/RTLInterfaceLoader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/RTLInterfaceLoader.pm) still owns `.rtlif` metadata loading and validation while `RTLChildRealizer` owns projection into `FSM::Composition::RealizedInstance`,
  - and the next likely seam is another remaining composition-shape coordination cluster or result/orchestration pocket.

## 2026-03-25: generated-child realization now lives in a dedicated composition package
- Saved shipped behavior:
  - [perl/FSM/Composition/GeneratedChildRealizer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/GeneratedChildRealizer.pm) now owns the `?fsmc` / `?dtc` realization family,
  - that package now covers embedded/external generated-child source loading, wrong-kind source validation, child compilation, shared-datapath export augmentation for realized `?fsmc` children, and normalized realized-child construction,
  - and [t/184-composition-generated-child-realizer.t](/Users/richarddje/Documents/github/fsmgen/t/184-composition-generated-child-realizer.t) now locks the new owner directly while the older child-source/default-source/shared-datapath tests keep the surrounding contract honest.
- Important continuity note:
  - this removes another real child/source-orchestration pocket from [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm),
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes this package in the composition-builder layer,
  - and the next likely seam is another remaining child/source owner such as the `?rtl` realization pocket or the next composition-shape coordination cluster.

## 2026-03-25: shared-datapath candidate assembly now lives in a dedicated builder package
- Saved shipped behavior:
  - [perl/FSM/Composition/SharedDatapathCandidateBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/SharedDatapathCandidateBuilder.pm) now owns the shared-datapath candidate family,
  - that package now builds candidate discovery plus normalized contributor, peer-read, drive-intent, and aggregate-enable metadata from structural bindings and lowered child drive families,
  - and [t/183-composition-shared-datapath-candidate-builder.t](/Users/richarddje/Documents/github/fsmgen/t/183-composition-shared-datapath-candidate-builder.t) now locks the new owner directly while [t/168-structural-binding-leaf-consumers.t](/Users/richarddje/Documents/github/fsmgen/t/168-structural-binding-leaf-consumers.t) points its direct leaf-binding contract at that builder.
- Important continuity note:
  - this removes another real composition metadata family from [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm),
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes this package in the composition-builder layer,
  - and the next likely seam is another monolith-breakdown slice such as generated-child realization/source-loading.

## 2026-03-25: composition result metadata now lives in a dedicated builder package
- Saved shipped behavior:
  - [perl/FSM/Composition/ResultMetadataBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/ResultMetadataBuilder.pm) now owns the success-path composition result-metadata family,
  - that package now builds `module_info` and `statistics` once composition planning, provenance, child exports, and forward IR layers already exist,
  - and [t/182-composition-result-metadata-builder.t](/Users/richarddje/Documents/github/fsmgen/t/182-composition-result-metadata-builder.t) now locks the new owner directly.
- Important continuity note:
  - this removes another real result-assembly family from [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm),
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes this package in the composition-builder layer,
  - and the next likely seam is another monolith-breakdown slice such as shared-datapath candidate assembly or the generated-child realization/source-loading family.

## 2026-03-25: composition failure summaries now live in a dedicated builder package
- Saved shipped behavior:
  - [perl/FSM/Composition/FailureReportBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/FailureReportBuilder.pm) now owns the bounded failed-run composition summary family,
  - that package now builds blocked-boundary, construct, artifact, context, and concise-reason summary data from raised composition diagnostics,
  - and [t/181-composition-failure-report-builder.t](/Users/richarddje/Documents/github/fsmgen/t/181-composition-failure-report-builder.t) now locks the new owner directly.
- Important continuity note:
  - this removes another real reporting/result-assembly family from [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm),
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now includes this package in the composition-builder layer,
  - and the next likely seam is another monolith-breakdown slice such as another remaining result-assembly or reporting pocket.

## 2026-03-25: composition child exports now live in a dedicated builder package
- Saved shipped behavior:
  - [perl/FSM/Composition/ChildExportBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/ChildExportBuilder.pm) now owns the composition child-export family,
  - that package now builds the unified realized-child export surface plus the narrower generated-child and standalone-DT child export views,
  - and [t/180-composition-child-export-builder.t](/Users/richarddje/Documents/github/fsmgen/t/180-composition-child-export-builder.t) now locks the new owner directly.
- Important continuity note:
  - this removes another real result-assembly family from [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm),
  - the live import-tree note in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md) now also includes this package in the composition-builder layer,
  - and the next likely seam is another monolith-breakdown slice such as the failure-summary family or another remaining result-assembly pocket.

## 2026-03-25: the `bin/fsmgen` import-tree analysis now lives in its own dedicated architecture note
- Saved continuity rule:
  - the current deep analysis of [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) and its transitive project-owned import tree now lives in [docs/BIN_FSMGEN_IMPORT_TREE.md](/Users/richarddje/Documents/github/fsmgen/docs/BIN_FSMGEN_IMPORT_TREE.md),
  - that file is intentionally a live document and should be updated at the start of a later session when the entrypoint/runtime spine or hotspot picture has materially changed,
  - and future sessions should treat it as the current architecture map for the CLI entrypoint rather than trying to reconstruct the tree from scattered conversation history.
- Important continuity note:
  - this is especially relevant while `R11` keeps changing package ownership under [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm),
  - the document is meant to stay honest about which layers are clean, which are transitional, and where the current hotspots still are.

## 2026-03-24: inferred same-name composition link planning now lives in a composition builder package
- Saved shipped behavior:
  - `FSM::Composition::SameNameLinkBuilder` now owns the bounded inferred same-name convention link family used by the active `C2` and `C3` lanes,
  - that package now handles inferred top-input fanout, inferred top-output selection, inferred internal same-name carrier links, and the shared candidate-grouping / explicit-child-endpoint exclusion rules behind those bounded conventions,
  - and the extracted builder now has a direct contract test beside the existing end-to-end same-name convention coverage.
- Important continuity note:
  - this removes another real composition-planning family from `HDLGenerator`,
  - it gives the future linked-plan split a cleaner separation between generic linked-plan assembly and bounded same-name convention inference,
  - and the next likely seam is another bounded lane/inference builder or a broader linked-plan extraction step.

## 2026-03-24: keep the product name, defer the internal namespace rename
- Saved direction:
  - keep `fsmgen` as the product/tool identity for historical reasons,
  - treat the internal `FSM::...` umbrella namespace as a likely late-roadmap cleanup target instead,
  - and do not spend current roadmap energy on that rename while package boundaries are still moving.
- Important continuity note:
  - this is a deferred naming cleanup, not an active implementation task,
  - the rename should be revisited only when the roadmap is much closer to complete and the package split is largely settled.

## 2026-03-24: active forward-ir packages now carry explicit pod contracts
- Saved shipped behavior:
  - active forward-IR packages, builders, and the first structural backend emitter now carry package-level POD near the top of the file,
  - those same packages now also carry routine-level POD for the functions they own,
  - and the saved rule is that new extracted packages in this lane should ship with POD instead of waiting for a later cleanup pass.
- Important continuity note:
  - this is an architecture-clarity move, not just cosmetic editing,
  - it keeps the active three-layer forward-IR plan reviewable while the package split is still in motion,
  - and the monolith split should inherit the same documentation standard as more responsibilities leave `HDLGenerator`.

## 2026-03-24: declared connect-by-name link planning now lives in a composition builder package
- Saved shipped behavior:
  - `FSM::Composition::DeclaredByNameLinkBuilder` now owns the bounded `C4` declared connect-by-name link family,
  - that package now handles system-port exclusion, same-name endpoint matching, input fanout, unique-output selection, and direction/width validation for `=port` top declarations,
  - and the extracted builder now has a direct contract test beside the existing end-to-end connect-by-name coverage.
- Important continuity note:
  - this removes another real composition-planning family from `HDLGenerator`,
  - it gives the future linked-plan split a cleaner separation between lane-specific declared-by-name logic and generic linked-plan assembly,
  - and the next likely seam is another bounded lane/inference builder or one of the remaining implicit-link helpers.

## 2026-03-24: c1 passthrough plan building now lives in a composition builder package
- Saved shipped behavior:
  - `FSM::Composition::C1PlanBuilder` now owns the bounded single-child passthrough `C1` lane,
  - that package now handles explicit passthrough exposure validation, implicit top-port inference from one realized child interface, and direct passthrough link/binding assembly,
  - and the extracted builder now has a direct contract test beside the existing end-to-end `C1` coverage.
- Important continuity note:
  - this is the first real composition-lane planner split, not just another helper move,
  - it gives the future composition-plan breakdown a concrete lane package to grow from,
  - and the next likely seam is another bounded composition-lane extraction or one of the remaining top-port/link inference helpers.

## 2026-03-24: realized-child interface port planning now lives in a composition builder package
- Saved shipped behavior:
  - `FSM::Composition::InterfacePortBuilder` now owns realized generated-child interface port construction from `module_info`,
  - that same package now also owns the shared interface-type normalization and system-port ordering rules used by composition planning,
  - and the direct interface helper tests now call that package directly instead of asking `HDLGenerator` to build realized-child boundary ports.
- Important continuity note:
  - this removes another real builder/planning pocket from the pipeline monolith,
  - it gives the future composition-plan split a cleaner seam because child-interface projection now has an explicit owner,
  - and the next likely seam is another composition builder extraction or a deeper orchestrator breakdown step.

## 2026-03-24: composition-top StructuralRTLIR building now lives in a builder package
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIRBuilder` now owns composition-top structural IR construction from `FSM::Composition::Plan`,
  - that same package now also owns structural hash/object coercion for later pipeline/reporting consumers,
  - and structural tests now call the builder package directly instead of asking `HDLGenerator` to manufacture the structural object.
- Important continuity note:
  - this is the matching pipeline-side split to the new backend-emitter extraction,
  - it removes one real structural assembly pocket from the coordinator monolith,
  - and the next likely seam is another builder extraction, especially on the direct-root side, or another backend-emitter ownership move.

## 2026-03-24: composition-top structural text emission now lives in a backend emitter
- Saved shipped behavior:
  - `FSM::Backend::VerilogFamily::StructuralRTLIREmitter` now owns composition-top structural HDL text emission for the current Verilog-family lane,
  - `HDLGenerator` now assembles composition results around that backend package instead of owning the direct top-module text-rendering method itself,
  - and the structural emitter tests now call the backend package directly.
- Important continuity note:
  - this is the first concrete backend-emitter split slice, not just another helper extraction,
  - it moves one real text-rendering responsibility out of the pipeline coordinator,
  - and the next likely seam is another backend-emitter ownership move or the matching orchestrator/builder extraction on the pipeline side.

## 2026-03-24: no compatibility excuse should preserve the current HDLGenerator shape
- Saved architecture clarification:
  - FSMGen does not yet have a published public compatibility contract that would justify preserving `HDLGenerator` as a monolith,
  - the target remains a split orchestrator/compiler side that builds `IntentHIR`, `LoweredRTLIR`, and `StructuralRTLIR`,
  - and a separate backend-emitter side that mostly walks `StructuralRTLIR` to emit HDL text.
- Important continuity note:
  - internal shims are acceptable only when they are clearly temporary migration aids,
  - they are not a reason to keep accidental monolithic ownership alive,
  - and future extraction choices should optimize for the strongest architecture rather than for compatibility theater.

## 2026-03-24: composition-top port metadata now lives in StructuralRTLIR
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR` now owns `port_metadata` and `port_metadata_from_input`,
  - composition-top `IntentHIR` now consumes that helper for `signal_names` and grouped port signal-analysis summaries,
  - and composition-top `module_info->{signals}` now consumes that same helper instead of rebuilding a local top-port summary map.
- Important continuity note:
  - this removes another small structural-boundary projection from `HDLGenerator`,
  - it keeps top-level boundary metadata closer to the IR layer that already owns explicit ports and top-port lookups,
  - and the next likely seam is still another structural owner handoff or a real module breakdown step for the combined pipeline/emitter layer.

## 2026-03-24: keep the forward-ir target separate from the current HDLGenerator reality
- Saved architecture clarification:
  - the intended forward spine is still `IntentHIR -> LoweredRTLIR -> StructuralRTLIR -> backend emission`,
  - `StructuralRTLIR` remains the intended last IR before HDL text,
  - and the current direct `IntentHIR` / `LoweredRTLIR` queries in `FSM::Pipeline::HDLGenerator` are transitional coordinator cleanup, not the desired long-term emitter boundary.
- Important continuity note:
  - `HDLGenerator` still currently acts as compiler driver, lowering coordinator, and emitter at the same time,
  - so it is acceptable for that combined module to touch earlier IR owners while we keep extracting responsibilities out of local ad hoc code,
  - but the future breakdown should leave orchestration free to see all three forward IR layers while the pure HDL emitter mostly walks `StructuralRTLIR`.

## 2026-03-23: structural top-port and resolved-link queries now live in StructuralRTLIR
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR` now owns `top_port` and `resolved_links_touching`,
  - composition provenance endpoint resolution now consumes `top_port` instead of rebuilding a local top-port lookup table,
  - and explicit-toplink override reporting now consumes `resolved_links_touching` instead of grepping resolved links locally for each top port.
- Important continuity note:
  - this removes another pair of small but real structural-query pockets from `HDLGenerator`,
  - it keeps more top/child connectivity lookup behavior with the structural layer that owns the ports and links,
  - and the next likely seam is still another structural query/helper ownership move or the next bounded structural-AST widening.

## 2026-03-23: structural endpoint-query helpers now live in StructuralRTLIR
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR` now owns `interface_endpoint`, `interface_signal_endpoints`, and `interface_signal_endpoint_groups`,
  - composition provenance endpoint resolution now consumes those structural queries instead of grepping structural instances/ports locally,
  - and override/block reporting plus signal-family context discovery now consume that same structural endpoint-query surface instead of rebuilding nested-loop endpoint groups.
- Important continuity note:
  - this removes another real connectivity-query pocket from `HDLGenerator`,
  - it makes `StructuralRTLIR` a clearer owner of explicit child-interface endpoint lookup instead of leaving that logic spread across reporting consumers,
  - and the next likely seam is still another structural query/helper ownership move or the next bounded structural-AST widening.

## 2026-03-23: structural binding-summary indexing now lives in the structural helper layer
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR::ConnectionExpr` now owns `binding_signal_summaries_by_port`, the reusable rule for turning one binding list into a normalized per-port summary index,
  - composition system-signal inference now consumes that helper instead of rebuilding a local per-port summary map,
  - and shared-datapath candidate assembly now consumes that same helper instead of rebuilding the same map again in a second pipeline seam.
- Important continuity note:
  - this removes another small but real binding-list indexing pocket from `HDLGenerator`,
  - it keeps binding-list to summary-index semantics together with the structural helper layer that already owns summary construction and export rules,
  - and the next likely seam is still either another real consumer handoff or one more bounded `connection_expr` widening.

## 2026-03-23: structural summary metadata export now lives in the structural helper layer
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR::ConnectionExpr` now owns `binding_signal_summary_metadata`, the reusable rule for normalized cloned summary-export payloads,
  - shared-datapath contributor metadata now consumes that helper instead of hand-copying `bound_signal` / `bound_signals` / `bound_connection_expr`,
  - and shared peer-read endpoint metadata now consumes that same helper instead of keeping a second local copy of the same projection.
- Important continuity note:
  - this removes another small but real summary-payload ownership pocket from `HDLGenerator`,
  - it keeps exported summary payload semantics together with the structural helper layer that already owns summary construction, leaf selection, and rendering,
  - and the next likely seam is still either another real consumer handoff or one more bounded `connection_expr` widening.

## 2026-03-23: structural summary text rendering now lives in the structural helper layer
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR::ConnectionExpr` now owns `binding_signal_summary_text`, the reusable rule for rendering summary entries from typed binding expressions first and then falling back to flat/dependency mirrors,
  - `bin/fsmgen` now consumes that helper for shared-datapath summary rendering instead of keeping its own local summary-rendering copy,
  - and the helper now also normalizes the current short CLI target-language aliases such as `sv` and `v`.
- Important continuity note:
  - this removes another small but real structural-summary rule from the CLI edge,
  - it keeps summary-entry rendering semantics together with the structural summary helpers that already own the underlying data contract,
  - and the next likely seam is still either another real consumer handoff or one more bounded `connection_expr` widening.

## 2026-03-23: structural summary leaf-carrier lookup now lives in the structural helper layer
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR::ConnectionExpr` now owns `binding_signal_summary_leaf_signal`, the reusable rule for “typed summary entry to true flat leaf carrier,”
  - shared-datapath planning now consumes that structural helper instead of keeping the same leaf-carrier rule as a pipeline-local method,
  - and the shared-datapath leaf-binding tests now point at the structural owner directly.
- Important continuity note:
  - this removes another small but real binding-semantics pocket from `HDLGenerator`,
  - it keeps typed-summary leaf-carrier rules together with the structural summary helpers that produce those entries,
  - and the next likely seam is still either another real consumer handoff or one more bounded `connection_expr` widening.

## 2026-03-23: structural binding signal summaries now live in the structural helper layer
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR::ConnectionExpr` now owns one `binding_signal_summary` helper over flat leaf carrier name, broader dependency names, and cloned typed binding expression payload,
  - composition system-signal inference now consumes that structural summary instead of rebuilding the same projection locally,
  - and shared-datapath candidate metadata now consumes that same structural summary instead of carrying another pipeline-local copy of the rule.
- Important continuity note:
  - this is another ownership move toward the structural layer rather than a new syntax feature,
  - it gives later structural consumers one stable signal-summary contract instead of repeating `bound_signal` / `bound_signals` / cloned-expression assembly in `HDLGenerator`,
  - and the next likely seam is still either another real consumer handoff or one more bounded `connection_expr` widening.

## 2026-03-23: shared-datapath cli summaries now render typed contributor bindings too
- Saved shipped behavior:
  - non-quiet `bin/fsmgen` shared-datapath candidate summary lines now also render contributor binding text from `bound_connection_expr`,
  - flat `signal_ref` contributor bindings now print as lines like `left.status_bus <= left_status`,
  - and the CLI keeps the richer contributor line aligned with the same structural AST surface already used for peer-read summaries.
- Important continuity note:
  - this makes the top candidate line itself a real structural-expression consumer instead of leaving typed bindings only in detail lines,
  - it keeps contributor summaries from collapsing back to endpoint-only reporting at the first line of the shared-datapath section,
  - and the next likely seam is still either another real consumer handoff or one more bounded `connection_expr` widening.

## 2026-03-23: shared-datapath cli summaries now render typed peer-read bindings
- Saved shipped behavior:
  - non-quiet `bin/fsmgen` shared-datapath summaries now render peer-read binding text from `bound_connection_expr`,
  - flat `signal_ref` peer-read bindings now print as lines like `consumer.status_bus <= left_status`,
  - and the CLI falls back to older summary fields only when no typed binding expression is available.
- Important continuity note:
  - this is a real downstream consumer of the structural AST rather than passive metadata carriage,
  - it keeps the CLI from collapsing back to endpoint-only summaries at the reporting boundary,
  - and the next likely seam is still either another real consumer handoff or one more bounded `connection_expr` widening.

## 2026-03-23: structural bit-vector literals now render honestly for vhdl too
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR::ConnectionExpr` now renders bounded `bit_vector_literal` nodes through the current VHDL helper path too,
  - multi-bit literals now render as VHDL bit-string style `"1010"` forms,
  - and single-bit literals now render as VHDL character literals like `'1'`.
- Important continuity note:
  - this closes another obvious “portable on paper but not in rendering” gap in the structural AST,
  - it keeps constant actual connections backend-neutral without forcing a separate VHDL-only literal family,
  - and the next likely seam is still either one more bounded `connection_expr` widening or another consumer moving further off compatibility mirrors.

## 2026-03-23: shared-datapath planning now prefers typed binding expressions
- Saved shipped behavior:
  - shared-datapath planning now derives flat carrier names from `bound_connection_expr` first,
  - the older `bound_signal` field is now only a compatibility fallback for that specific leaf-carrier decision,
  - and stale mirrors no longer win over the typed structural binding AST when the two disagree.
- Important continuity note:
  - this is a real consumer handoff onto the structural layer rather than just more metadata,
  - it makes carrier/top-output/peer-input planning depend less on compatibility mirrors,
  - and the next likely seam is still either another consumer moving onto typed binding expressions or one more bounded `connection_expr` widening.

## 2026-03-23: shared-datapath metadata now preserves typed binding expressions
- Saved shipped behavior:
  - shared-datapath contributor metadata now preserves `bound_connection_expr` beside `bound_signal` and `bound_signals`,
  - peer-read endpoint metadata now preserves that same typed binding expression too,
  - and richer bindings such as `member_access` now stay visible as actual structural AST nodes instead of collapsing to names-only summaries.
- Important continuity note:
  - this is a real structural handoff, not just more reporting,
  - it gives later planning/reporting consumers the actual bound expression without having to reconstruct it from the plan again,
  - and the next likely seam is still either another consumer moving onto those typed binding expressions or one more bounded `connection_expr` widening.

## 2026-03-23: structural slice and concat expressions now render honestly for vhdl too
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR::ConnectionExpr` now renders bounded `bit_select`, `slice`, and `concat` nodes through the current VHDL helper path,
  - descending and ascending slice bounds now preserve `downto` versus `to` direction honestly,
  - and nested concatenations now render as VHDL `&` chains instead of failing as unsupported.
- Important continuity note:
  - this strengthens the existing structural AST without inventing another node family,
  - it makes the current bounded connectivity shapes more honestly cross-backend,
  - and the next likely seam is still either one more bounded `connection_expr` widening or another consumer moving further off compatibility mirrors.

## 2026-03-23: structural leaf-signal consumers now distinguish flat carriers from richer dependencies
- Saved shipped behavior:
  - composition system-signal inference now requires a true flat leaf binding before it accepts a clock/reset carrier name,
  - shared-datapath contributor and peer-input metadata now keep `bound_signal` reserved for that true flat leaf case,
  - and `bound_signals` continues to carry the broader dependency list for richer expressions such as `member_access` and `index_access`.
- Important continuity note:
  - this keeps the new structural expression forms honest in real downstream consumers,
  - it prevents “depends on one base signal” from being silently misread as “is bound directly to one flat carrier,”
  - and the next likely seam is still either another structural consumer moving onto the typed distinction or one more bounded `connection_expr` widening.

## 2026-03-23: structural connection expressions now cover bounded fixed-size index access
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR::ConnectionExpr` now also owns a bounded `index_access` actual-connection node,
  - helper rendering supports that node for SystemVerilog, Verilog, and VHDL, with VHDL using parenthesized index syntax,
  - recursive dependency discovery now follows the base source signal through that node,
  - and the composition structural emitter now walks the typed index-access node directly.
- Important continuity note:
  - this starts the roadmap’s fixed-size array/index-access lane in the structural AST without collapsing into raw HDL strings,
  - it keeps indexed connectivity as real typed structure rather than a flat compatibility mirror,
  - and the next likely seam is still either one bounded `connection_expr` widening or another consumer moving further off compatibility mirrors.

## 2026-03-23: structural connection expressions now cover bounded member access
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR::ConnectionExpr` now also owns a bounded `member_access` actual-connection node,
  - helper rendering supports that node for SystemVerilog and VHDL while failing explicitly for plain Verilog,
  - recursive dependency discovery now follows the base source signal through that node,
  - and the composition structural emitter now walks the typed member-access node directly.
- Important continuity note:
  - this starts the roadmap’s member/field-access lane in the structural AST without collapsing into raw HDL strings,
  - it keeps aggregate/member connectivity as real typed structure rather than a flat compatibility mirror,
  - and the next likely seam is still either one bounded `connection_expr` widening or another consumer moving further off compatibility mirrors.

## 2026-03-23: structural connection expressions now cover explicit open actuals
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR::ConnectionExpr` now also owns an explicit backend-neutral `open` actual-connection node,
  - helper rendering already maps that node to Verilog-family empty actuals and to the VHDL `open` keyword,
  - and the composition structural emitter now walks that typed node directly.
- Important continuity note:
  - this keeps “intentionally unconnected formal” as real structural semantics instead of a backend-specific text trick,
  - it makes the structural binding AST more honest for richer top/child connectivity,
  - and the next likely seam is still either one bounded `connection_expr` widening or another consumer moving further off compatibility mirrors.

## 2026-03-23: structural binding-list mutation now lives in the structural helper module too
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR::ConnectionExpr` now also owns the first bounded signal-ref binding-list ensure/set operations,
  - `HDLGenerator` now uses those helpers when deciding whether to reuse, append, or rebind structural instance port bindings,
  - and the current bounded signal-ref binding behavior stays stable.
- Important continuity note:
  - this removes another low-level binding-ownership pocket from `HDLGenerator`,
  - it makes the structural helper module a more complete owner of the first bounded binding family,
  - and the next likely seam is still either one bounded `connection_expr` widening or another higher-level wiring consumer moving further off compatibility mirrors.

## 2026-03-23: structural binding normalization now lives in the structural helper module too
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR::ConnectionExpr` now also owns normalized binding cloning/backfilling for the current bounded binding contract,
  - `RealizedInstance` now uses that helper instead of carrying its own private binding-normalization logic,
  - `HDLGenerator` now also uses the same helper while serializing structural instance bindings,
  - and the current `signal_ref` structural behavior stays stable.
- Important continuity note:
  - this removes another duplicated binding-semantics pocket from the runtime/pipeline boundary,
  - it makes the structural helper module the clearer owner of the first bounded binding contract,
  - and the next likely seam is still either one bounded `connection_expr` widening or another consumer moving further off compatibility mirrors.

## 2026-03-23: structural signal-ref binding construction now lives in the structural helper module too
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR::ConnectionExpr` now also owns the first bounded `signal_ref` binding constructor and in-place rebinding helpers,
  - `HDLGenerator` now uses those helpers when building `C1` passthrough bindings, broader composition planned child bindings, and structural rebinding paths,
  - and the existing bounded `signal_ref` structural surface stays stable.
- Important continuity note:
  - this removes another repeated `signal_name` / `connection_expr` pairing rule from the pipeline,
  - it keeps the first bounded actual-connection family together in one helper surface,
  - and the next likely seam is still either one bounded `connection_expr` widening or another consumer moving fully off the compatibility mirror.

## 2026-03-23: structural binding-expression fallback now lives in the structural helper module too
- Saved shipped behavior:
  - `FSM::IR::StructuralRTLIR::ConnectionExpr` now also owns the effective binding-expression fallback for bindings that only still carry the compatibility `signal_name` mirror,
  - `HDLGenerator` now uses that structural helper during structural instance-binding serialization instead of rebuilding `signal_ref` nodes locally,
  - and the current bounded `signal_ref` structural surface stays stable.
- Important continuity note:
  - this removes one more small piece of connection semantics from pipeline-only code,
  - it makes structural serialization a cleaner consumer of the structural layer,
  - and the next likely seam is still either one bounded `connection_expr` widening or another consumer moving fully off the compatibility mirror.

## 2026-03-23: structural connection-expression helpers now live in the structural ir layer
- Saved shipped behavior:
  - new `FSM::IR::StructuralRTLIR::ConnectionExpr` now owns the current bounded `signal_ref` constructor plus signal-name recovery and backend-neutral text rendering for structural binding expressions,
  - `HDLGenerator` now consumes those structural helpers instead of keeping local connection-expression helper subs,
  - `RealizedInstance` now uses that same structural helper module while normalizing plan-side child bindings,
  - and the existing bounded `signal_ref` structural behavior stays stable.
- Important continuity note:
  - this moves the first actual-connection helper semantics onto the structural layer that owns them,
  - it gives later `connection_expr` widening one cleaner place to extend,
  - and the next likely seam is either another structural consumer moving fully onto `connection_expr` or one bounded portable widening beyond plain `signal_ref`.

## 2026-03-23: composition bookkeeping now mirrors the explicit ir layers more directly
- Saved shipped behavior:
  - composition-top `module_info` now derives internal-net names/counts, instance names/counts, auxiliary-assignment count, and composition lane from `lowered_rtl_ir` / `intent_hir`,
  - composition `statistics` now also derives composition lane and shared-datapath candidate count from `intent_hir` / `lowered_rtl_ir`,
  - and the compatible bookkeeping surface stays stable.
- Important continuity note:
  - this keeps the top-level result mirrors aligned with the extracted forward IRs,
  - it removes another small class of raw bookkeeping fallback from `HDLGenerator`,
  - and the next likely seam is another bounded helper that still rebuilds composition state instead of consuming `IntentHIR`, `LoweredRTLIR`, or `StructuralRTLIR` first.

## 2026-03-23: structural rtl ir now carries declared toplinks too
- Saved shipped behavior:
  - composition-top `structural_rtl_ir` now preserves declared explicit-toplink connectivity separately through `declared_links`,
  - block-event reasoning for explicit child links now consumes that structural declared-link surface instead of rereading declared toplinks directly from plan internals,
  - and the existing resolved-link structural surface stays intact.
- Important continuity note:
  - this makes the structural layer a more honest source of truth for explicit top/child wiring intent,
  - it removes another plan-only connectivity read from `HDLGenerator`,
  - and the next likely seam is another bounded helper that still rebuilds composition state instead of consuming `IntentHIR`, `LoweredRTLIR`, or `StructuralRTLIR` first.

## 2026-03-23: unified composition child exports now derive from the structural child layer
- Saved shipped behavior:
  - `composition_children` now derives child identity and order from `structural_rtl_ir->{instances}` instead of rereading realized child identity directly from plan instances,
  - the narrower `composition_generated_children` and `composition_standalone_dt_children` sibling exports now reuse that same computed child surface in the top-generation path instead of rebuilding it again,
  - and the existing unified child export shape stays stable.
- Important continuity note:
  - this makes the semantic child export line up more honestly with the structural source of truth it already feeds,
  - it removes another duplicated plan walk from `HDLGenerator`,
  - and the next likely seam is another bounded helper that still rebuilds composition state instead of consuming `IntentHIR`, `LoweredRTLIR`, or `StructuralRTLIR` first.

## 2026-03-23: reusable standalone-DT child exports now derive from the unified composition child semantic layer
- Saved shipped behavior:
  - `composition_standalone_dt_children` now derives from the broader semantic `composition_children` export instead of rebuilding `?dtc` child identity separately from plan instances,
  - child standalone-DT names and enable-family summaries now come from each child `intent_hir`,
  - grouped standalone-DT multi-drive targets now come from each child `lowered_rtl_ir`,
  - and the existing reusable standalone-DT export shape stays stable.
- Important continuity note:
  - this keeps the reusable standalone-DT sibling aligned with the already-shipped generated-child narrowing step,
  - it removes one more ad hoc plan-instance walk from `HDLGenerator`,
  - and the next likely seam is another remaining plan-shaped export/report helper that should consume `IntentHIR`, `LoweredRTLIR`, or `StructuralRTLIR` first.

## 2026-03-22: standalone-dt multi-drive targets now emit guard assertions
- Saved shipped behavior:
  - grouped standalone-DT multi-drive targets now carry onehot0 assertion metadata over the DT-specific driver-enable signals,
  - direct SystemVerilog `?dt` roots now emit bounded non-synthesis guard assertions from that metadata,
  - realized `?dtc` children now emit those same grouped-target guard assertions inside generated composition HDL,
  - and Verilog output keeps that assertion emission disabled.
- Important continuity note:
  - this turns the reusable standalone-DT arbitration lane into real emitted behavior instead of metadata only,
  - it keeps the backend boundary honest by not leaking SystemVerilog assertion syntax into Verilog output,
  - and the next likely seam is a fuller reusable-module/interface/export contract rather than more passive standalone-DT metadata.

## 2026-03-22: combinational shared-datapath lifting now covers the public-only fanout sibling
- Saved shipped behavior:
  - bounded combinational shared families can now lift even when they have no peer-read child inputs,
  - generated tops now emit one shared top-facing combinational carrier for that public-only sibling,
  - contributor outputs are rebound to private raw nets,
  - and preserved public top outputs are fanned back out from the lifted carrier.
- Important continuity note:
  - this widens the combinational shared-target ownership lane beyond the earlier peer-read-only slices,
  - it makes the combinational public-output contract more concrete instead of leaving it as roadmap prose,
  - and the next likely seam is broader automatic-lift/default-visibility policy rather than another missing combinational sibling.

## 2026-03-22: registered shared-datapath lifting now covers the public-only fanout sibling
- Saved shipped behavior:
  - bounded registered shared families can now lift even when they have no peer-read child inputs,
  - generated tops now emit one shared top-level register plus next-value logic for that public-only sibling,
  - contributor outputs are rebound to private raw nets,
  - and preserved public top outputs are fanned back out from the lifted register.
- Important continuity note:
  - this widens the registered shared-target ownership lane beyond the earlier peer-read-only slices,
  - it starts making the public re-export/default-visibility contract concrete instead of purely roadmap prose,
  - and the next likely seam is broader automatic-lift policy for registered families or further widening of the combinational sibling lane.

## 2026-03-22: systemverilog composition tops now emit shared-datapath guard assertions
- Saved shipped behavior:
  - SystemVerilog composition tops now emit non-synthesis same-value and whole-target shared-datapath guard assertions in the generated top,
  - those assertions are driven from the already-shipped deterministic conflict wires and onehot0 metadata,
  - and Verilog targets keep that assertion emission disabled.
- Important continuity note:
  - this turns the shared-datapath assertion lane into real emitted HDL instead of planning/reporting only,
  - it keeps the backend boundary honest by not leaking SystemVerilog assertion syntax into Verilog output,
  - and the next likely seam is still broader lifted shared-target ownership/visibility behavior rather than more assertion naming work.

## 2026-03-22: combinational shared-datapath peer-read families now also cover the internal-only top-local sibling
- Saved shipped behavior:
  - bounded combinational peer-read shared families can now lift even when no public top output from that family is preserved,
  - generated tops now emit one shared top-local combinational carrier for that internal-only case,
  - peer-read child inputs are rebound to that carrier, contributor outputs are rebound to private raw nets, and no public top re-export assignments are invented,
  - and the peer-read policy surface now distinguishes `top_output_only` from the new `top_local_only` sibling.
- Important continuity note:
  - this closes the most obvious missing sibling in the combinational shared-carrier lane,
  - it also makes the combinational ownership/runtime surface more honest for internal-only peer-read families,
  - and the next likely seam is broader combinational widening or default-visibility policy beyond the now-shipped public-preserving/internal-only pair.

## 2026-03-22: combinational shared-datapath peer-read families now have a first top-facing runtime slice
- Saved shipped behavior:
  - the bounded combinational peer-read public-preserving case now emits one shared top-facing combinational carrier in the generated top,
  - peer-read child inputs are rebound to that carrier, preserved public outputs are re-exported from it, and contributor outputs move to private raw nets,
  - and candidate peer-read endpoints are now filtered to inputs actually bound to contributor carriers before that runtime is planned.
- Important continuity note:
  - this turns the combinational peer-read lane into real emitted behavior instead of policy metadata only,
  - it also keeps the peer-read metadata surface honest for later ownership work,
  - and the next likely seam is how far the combinational top-facing lane should widen beyond the bounded public-preserving case.

## 2026-03-22: shared-datapath lifting now covers mixed public/internal registered peer-read families
- Saved shipped behavior:
  - the bounded registered public-preserving lift path now also works when one contributor preserves a public top output while sibling contributors in the same shared family are consumed only internally,
  - candidate peer-read endpoints are now filtered to inputs actually bound to contributor carriers before lift planning/runtime,
  - and the lifted runtime still preserves only the actual public top re-exports instead of inventing new public assignments for internal carriers.
- Important continuity note:
  - this closes the mixed-boundary sibling of the first registered shared-datapath runtime lane,
  - it also makes peer-read metadata more honest for later ownership work,
  - and the next likely seam is broader ownership/default-visibility policy beyond the now-shipped public-preserving, mixed-boundary, and internal-only trio.

## 2026-03-22: shared-datapath lifting now covers the internal-only registered peer-read sibling
- Saved shipped behavior:
  - the bounded registered loopback lift path no longer requires planned public re-exports before it activates,
  - generated tops now still emit one lifted shared register plus next-value logic when the shared family is only consumed internally,
  - contributor outputs are rebound to private raw nets and peer-read child inputs are rebound to that lifted register,
  - and non-quiet `bin/fsmgen` runs now distinguish the internal-only lifted runtime from the earlier public re-export runtime.
- Important continuity note:
  - this closes the most obvious sibling gap in the first lifted shared-target behavior,
  - it keeps the bounded registered lifting lane honest as an ownership/runtime feature instead of a public re-export special case only,
  - and the next likely seam is broader ownership policy beyond the now-shipped explicit-reexport/internal-only pair.

## 2026-03-21: shared-datapath candidates now surface planned conflict-bit names
- Saved shipped behavior:
  - each aggregate value family now carries one deterministic `P_Q_multi_src_conflict`-style name,
  - each whole target now carries one deterministic `P_multi_value_conflict`-style name,
  - and non-quiet `bin/fsmgen` runs now print those planned conflict names under each shared-datapath candidate.
- Important continuity note:
  - this is the first shipped explicit conflict-naming slice in the shared-datapath lane,
  - it makes the same-value versus different-value split concrete in runtime metadata,
  - and it still does not generate lifted shared-datapath HDL or assertion logic yet.

## 2026-03-21: shared-datapath candidates now surface aggregate enable families
- Saved shipped behavior:
  - generated-child `output_drive_families` now preserve per-RHS family metadata,
  - shared-datapath candidates now also expose one deterministic whole-target aggregate enable plus per-value aggregate enable families,
  - and those aggregate value families now explicitly list the child-local family enables they aggregate.
- Important continuity note:
  - this is the first shipped slice of the roadmap’s shared aggregate-enable lane,
  - it gives later onehot/conflict/assertion work one stable target/value-family metadata surface,
  - and it still does not lift those families into generated shared-datapath HDL yet.

## 2026-03-21: shared-datapath candidates now carry per-child drive intent
- Saved shipped behavior:
  - generated roots and realized generated children now surface `output_drive_family_count` and `output_drive_families` in `module_info`,
  - shared-datapath candidate contributors now also carry one bounded `drive_intent` summary with mux type, driver blocks, RHS families, and enable-signal families,
  - and non-quiet `bin/fsmgen` runs now print one concise per-child drive-intent line under each shared-datapath candidate.
- Important continuity note:
  - this is the first real shipped slice of the roadmap’s per-child drive-intent aggregation lane,
  - it still does not lift those families into a shared synthesized block yet,
  - and it gives later shared-datapath ownership/export work one honest child-owned metadata surface to build on.

## 2026-03-21: composition tops now surface first shared-datapath candidate metadata
- Saved shipped behavior:
  - composition-top `module_info` now reports shared-datapath candidate families through `composition_shared_datapath_candidate_count` and `composition_shared_datapath_candidates`,
  - those candidates are currently bounded to same-name output families across multiple realized `?fsmc` children that agree on width and interface type,
  - and each candidate now carries contributor instance/module/endpoint identity plus any current top-output bindings.
- Important continuity note:
  - this is the first real shared-datapath `R11` feature slice, not just another roadmap note,
  - it still does not lift or rewrite ownership into a shared datapath block yet,
  - and it gives later shared-datapath extraction work one stable discovery/reporting surface to build on.

## 2026-03-21: composition tops now aggregate reusable standalone-DT child exports
- Saved shipped behavior:
  - composition-top `module_info` now aggregates realized `?dtc` child exports through `composition_standalone_dt_child_count`, `composition_standalone_dt_block_count`, `composition_standalone_dt_multi_drive_target_count`, and `composition_standalone_dt_children`,
  - each exported child summary now carries instance/module/source identity plus the already-shipped standalone-DT enable-family and grouped shared-target metadata,
  - and non-quiet `bin/fsmgen` composition runs now print one concise reusable standalone-DT child summary section from that same top-level export surface.
- Important continuity note:
  - this is real `R11` feature growth in the reusable-module lane,
  - it retires the immediate “composition-facing exposure” gap for the already-shipped standalone-DT metadata slices,
  - and it still leaves broader reusable-module interface/export rules for a later deliberate contract pass.

## 2026-03-21: standalone-DT roots now surface grouped multi-drive target metadata
- Saved shipped behavior:
  - direct standalone-DT generation now reports grouped multi-drive target families through `module_info`,
  - those grouped families now carry target name, contributing standalone-DT block names, RHS families, DT-specific enable names, and grouped LHS enable names,
  - and realized `?dtc` children now preserve that same grouped multi-drive metadata through composition.
- Important continuity note:
  - this is real `R11` feature growth in the reusable-module lane,
  - it gives future assertion/shared-datapath work one honest grouped summary for same-target standalone-DT behavior,
  - and it still leaves child interface/export widening for a later deliberate contract slice.

## 2026-03-21: standalone-DT roots now surface stable block-enable family metadata
- Saved shipped behavior:
  - direct standalone-DT generation now reports plain-scalar block names and stable per-block enable-signal families through `module_info`,
  - realized `?dtc` children now preserve that same standalone-DT enable metadata through composition,
  - and `module_info` now also groups those block enable signals into one module-level family summary.
- Important continuity note:
  - this is real `R11` feature growth in the reusable-module lane,
  - it gives future composition/shared-datapath work one honest metadata surface for standalone-DT block enables,
  - and it keeps child interfaces unchanged for now instead of widening them before the reusable-module export contract is settled.

## 2026-03-20: named generated children now default their source name locally in composition
- Saved shipped behavior:
  - named `?fsmc:name` and `?dtc:name` children may now omit the explicit child-source token and default it to `name`,
  - the defaulted source then goes through the same embedded/sibling/`--path`/`FSMLIB` lookup order as before,
  - and unnamed generated children still keep the explicit missing-source failure path.
- Important continuity note:
  - this is real `R11` feature growth in the reusable-root/reference lane,
  - it retires the old named zero-source parser-failure contract,
  - and it gives composition one bounded shorthand for reusable child references without reopening legacy implicit hierarchy.

## 2026-03-20: standalone-DT roots now also accept the conventional explicit `+system` contract
- Saved shipped behavior:
  - standalone-DT roots may now use the same conventional explicit `(+system (clock clk) (sreset rstn))` / `(+system (clock clk) (asreset rstn))` section already accepted by `?fsm:name`,
  - direct standalone-DT generation now preserves that explicit `clk` / `rstn` contract,
  - and composition-facing `?dtc` children now expose and auto-wire those explicit system ports too.
- Important continuity note:
  - this is real `R11` feature growth in the reusable-module lane,
  - it does not replace the existing implicit `clk` / `rst_n` fallback for sequential standalone-DT roots,
  - and it gives reusable standalone-DT modules one deliberate interface-stability knob without reopening broad implicit hierarchy.

## 2026-03-20: standalone-DT roots now also accept `?mod:name` and `?module:name`
- Saved shipped behavior:
  - `?mod:name` and `?module:name` became accepted on the same live direct single-module path as `?dt:name`,
  - and composition `?dtc` children may now realize embedded or external standalone-DT sources rooted at any of those three spellings.
- Important continuity note:
  - later continuity corrected the semantic interpretation: this shared path should not be read as proving that `?mod:` / `?module:` mean the same thing as `?dt:`,
  - this is real `R11` feature growth, not just hardening,
  - it keeps the semantic root family unified under the existing `dt` runtime path,
  - and it retires the old roadmap question about whether those aliases should exist at all.

## 2026-03-20: composition override/block summaries now keep one example subject per kind
- Saved shipped behavior:
  - `composition_report` now keeps one concise example subject for each shipped override kind and block kind,
  - and non-quiet `bin/fsmgen` runs now print those examples inline with the existing `Convention Overrides` and `Convention Blocks` summaries.
- Important continuity note:
  - this slice does not widen planning or convention behavior,
  - it only promotes already-known override/block event structure into more actionable reporting,
  - and it closes the old counts-only reporting gap that was still left on the `R11` board.

## 2026-03-20: active CLI help now names `bin/fsmgen` honestly
- Saved shipped behavior:
  - the built-in help and missing-argument usage now name `./bin/fsmgen` instead of the old `generate_fsm_hdl.pl` wrapper,
  - the built-in examples now use the active CLI entrypoint consistently,
  - and the help text now describes the default output location as the current working directory, which matches the shipped runtime.
- Important continuity note:
  - this slice does not change parsing, planning, or HDL emission behavior,
  - it retires a small user-facing `R11` hotspot the roadmap had already called out explicitly,
  - and [t/132-cli-help-wording.t](/Users/richarddje/Documents/github/fsmgen/t/132-cli-help-wording.t) now locks both the `--help` surface and the missing-argument usage branch.

## 2026-03-20: top-level composition lane and `?ports` shape gates now summarize cleanly
- Saved shipped behavior:
  - failed composition summaries now keep clean top-level gate handling: no-child tops stay construct-free with the blocked `lane entry` summary, and blocked multiple-`?ports`, omitted-`?ports`, and empty-`?ports` tops now keep `Construct: ?ports` plus the shorter `shape` reason.
- Important continuity note:
  - this slice did widen extractor behavior slightly and narrowed concise-reason text slightly,
  - but only at the failed-run summary layer,
  - and it fixes a real misclassification where top-level `?ports` shape gates could previously show up as `?toplink` because the raw diagnostic mentioned the explicit-link `C2/C3` inference exception.

## 2026-03-20: named generated-child parser summaries are now symmetric across count and shape failures
- Saved shipped behavior:
  - named generated-child parser summaries now have explicit regression coverage across both parser boundaries, so named `?fsmc` and named `?dtc` failures both keep child context through count and shape branches.
- Important continuity note:
  - this slice did not widen extractor behavior,
  - it hardens the already-shipped named-child summary path,
  - and it closes the remaining symmetry gap in the named generated-child parser family.

## 2026-03-20: blocked nested `?ports` and `?toplink` items now keep child context in CLI summaries
- Saved shipped behavior:
  - failed composition summaries now keep `Child '?ports'` for blocked nested `?ports` items and `Child '?toplink'` for blocked nested `?toplink` items.
- Important continuity note:
  - this slice did widen extractor behavior slightly,
  - but only at the failed-run summary layer,
  - and it closes the remaining context-thin pocket in the parser flatness family without changing parser behavior.

## 2026-03-20: blocked empty child entries and non-string child headers now keep child-entry context in CLI summaries
- Saved shipped behavior:
  - failed composition summaries now keep `Child entry 'missing header'` for blocked empty child entries and `Child entry 'non-string header'` for blocked non-string child headers.
- Important continuity note:
  - this slice did widen extractor behavior slightly,
  - but only at the failed-run summary layer,
  - and it closes the remaining context-free pocket in the top-level child-structure parser family without inventing a fake construct line.

## 2026-03-19: unnamed generated-child parser summaries are now symmetric across count and shape failures
- Saved shipped behavior:
  - unnamed generated-child parser summaries now have explicit regression coverage across both parser boundaries, so unnamed `?fsmc` and unnamed `?dtc` failures both keep child context through count and shape branches.
- Important continuity note:
  - this slice did not widen extractor behavior,
  - it hardens the already-shipped unnamed-child summary path,
  - and it closes the remaining symmetry gap in the unnamed generated-child parser family.

## 2026-03-19: blocked unnamed generated-child parser failures now keep child context in CLI summaries
- Saved shipped behavior:
  - failed composition summaries now recognize blocked unnamed `?fsmc` / `?dtc` parser diagnostics as child context, so these runs can keep `Child '?fsmc'` / `Child '?dtc'` instead of losing child identity in the short summary.
- Important continuity note:
  - this slice did widen extractor behavior slightly,
  - but only at the failed-run summary layer,
  - and it keeps unnamed generated-child parser failures aligned with the already improved named-child generated-source summary family.

## 2026-03-19: blocked explicit-link duplicate-driver failures now keep target context in CLI summaries
- Saved shipped behavior:
  - failed composition summaries now recognize duplicate-driver blocked diagnostics as target context, so the conflicted target `result_data` stays visible in the summary.
- Important continuity note:
  - this slice did widen extractor behavior slightly,
  - but only at the failed-run summary layer,
  - and it keeps duplicate-driver conflicts aligned with the already improved direction-mismatch family instead of leaving their target only in the raw exception text.

## 2026-03-19: blocked explicit-link top-port role mismatches are now explicitly locked at CLI level
- Saved shipped behavior:
  - failed composition summaries now have explicit CLI regression coverage for blocked explicit-link top-port role mismatches, including `Top port 'result_data'` context and the concise top-port role reason.
- Important continuity note:
  - this slice did not widen extractor behavior,
  - it hardens another already-shipped explicit-link summary family at the CLI boundary,
  - and it keeps top-port role mismatches aligned with the previously locked child-endpoint direction mismatch, missing-child-endpoint, missing-top-endpoint, existing-instance missing-port, and unsupported explicit-endpoint families.

## 2026-03-19: blocked explicit-link direction mismatches now keep child-endpoint context in CLI summaries
- Saved shipped behavior:
  - failed composition summaries now recognize blocked `uses child endpoint '...'` diagnostics as `Child endpoint` context, so explicit-link direction mismatches keep `uart_tx.txd` visible in the summary.
- Important continuity note:
  - this slice did widen extractor behavior slightly,
  - but only at the failed-run summary layer,
  - and it keeps direction-mismatch failures aligned with the already locked missing-child-endpoint, missing-top-endpoint, existing-instance missing-port, and unsupported explicit-endpoint families.

## 2026-03-19: blocked existing-instance missing-port explicit-link summaries are now explicitly locked at CLI level
- Saved shipped behavior:
  - failed composition summaries now have explicit CLI regression coverage for blocked explicit-link endpoint-resolution failures where the child instance exists but the named child port does not, including `Child endpoint 'uart_tx.missing_port'` context and the concise missing-port reason.
- Important continuity note:
  - this slice did not widen extractor behavior,
  - it hardens another already-shipped explicit-link summary family at the CLI boundary,
  - and it keeps existing-instance missing-port failures aligned with the previously locked missing child-endpoint, missing top-endpoint, and unsupported explicit-endpoint summary families.

## 2026-03-19: blocked missing top-level explicit-link endpoint summaries are now explicitly locked at CLI level
- Saved shipped behavior:
  - failed composition summaries now have explicit CLI regression coverage for blocked missing top-level explicit-link endpoint failures, including `Top endpoint` context and the concise `'?ports' declares no top port with that name` reason.
- Important continuity note:
  - this slice did not widen extractor behavior,
  - it hardens another already-shipped explicit-link summary family at the CLI boundary,
  - and it keeps missing top-level endpoint failures aligned with the previously locked missing child-endpoint and unsupported explicit-endpoint summary families.

## 2026-03-19: blocked unsupported explicit-endpoint syntax is now explicitly locked at CLI level
- Saved shipped behavior:
  - failed composition summaries now have explicit CLI regression coverage for blocked unsupported explicit-endpoint syntax, including the offending endpoint token and concise unsupported-syntax reason.
- Important continuity note:
  - this slice did not widen extractor behavior,
  - it hardens another already-shipped explicit-link summary family at the CLI boundary,
  - and it keeps unsupported explicit-endpoint syntax aligned with the previously locked missing-endpoint and declared connect-by-name summary families.

## 2026-03-19: blocked shared-system-port `=port` summaries are now explicitly locked at CLI level
- Saved shipped behavior:
  - failed composition summaries now have explicit CLI regression coverage for blocked shared-system-port declared connect-by-name failures, including the concise dedicated-system-input-contract reason and top-port context.
- Important continuity note:
  - this slice did not widen extractor behavior,
  - it hardens another already-shipped `=port` summary family at the CLI boundary,
  - and it keeps the shared-system-port path aligned with the previously locked ambiguity, width-mismatch, incompatible-direction, missing-endpoint, and `C1` / `C2` / `C3` summary families.

## 2026-03-19: blocked incompatible-direction `C4` declared connect-by-name summaries now keep endpoint sets at CLI level
- Saved shipped behavior:
  - failed composition summaries now have explicit CLI regression coverage for a reachable blocked incompatible-direction `C4` declared connect-by-name failure, including the conflicting same-name endpoint set in the concise `Reason:` line.
- Important continuity note:
  - this slice did not widen extractor behavior,
  - it hardens another already-shipped `C4` summary family at the CLI boundary,
  - and it keeps incompatible-direction, width-mismatch, ambiguity, missing-endpoint, and the previously locked `C1` / `C2` / `C3` summary families aligned under the same reporting contract.

## 2026-03-19: blocked width-mismatch `C4` declared connect-by-name summaries now keep endpoint sets at CLI level
- Saved shipped behavior:
  - failed composition summaries now have explicit CLI regression coverage for a reachable blocked width-mismatch `C4` declared connect-by-name failure, including the conflicting same-name endpoint set in the concise `Reason:` line.
- Important continuity note:
  - this slice did not widen extractor behavior,
  - it hardens another already-shipped `C4` summary family at the CLI boundary,
  - and it keeps width-mismatch, ambiguity, missing-endpoint, and the previously locked `C1` / `C2` / `C3` summary families aligned under the same reporting contract.

## 2026-03-19: blocked ambiguous `C4` declared connect-by-name summaries now keep candidate lists at CLI level
- Saved shipped behavior:
  - failed composition summaries now have explicit CLI regression coverage for a reachable blocked ambiguous `C4` declared connect-by-name failure, including the compatible-child-endpoint list in the concise `Reason:` line.
- Important continuity note:
  - this slice did not widen extractor behavior,
  - it hardens another already-shipped `C4` summary family at the CLI boundary,
  - and it keeps ambiguity, missing-endpoint, and the previously locked `C1` / `C2` / `C3` summary families aligned under the same reporting contract.

## 2026-03-19: blocked `C4` declared connect-by-name summaries are now explicitly locked at CLI level
- Saved shipped behavior:
  - failed composition summaries now have explicit CLI regression coverage for a reachable blocked `C4` declared connect-by-name failure through the existing `Lane: C4`, `Construct: =port`, and `Top port` context lines.
- Important continuity note:
  - this slice did not widen extractor behavior,
  - it hardens an already-shipped `C4` summary family at the CLI boundary,
  - and it keeps the reachable declared connect-by-name path aligned with the previously locked `C1`, `C2`, and `C3` failed-run summary coverage.

## 2026-03-19: blocked `C2` lane-selection summaries are now explicitly locked at CLI level
- Saved shipped behavior:
  - failed composition summaries now have explicit CLI regression coverage for blocked `C2` lane-selection failures through the existing `Lane: C2` line and concise blocked-lane reason.
- Important continuity note:
  - this slice did not widen extractor behavior,
  - it hardens an already-shipped lane-summary family at the CLI boundary,
  - and it keeps the reachable `C2` path aligned with the previously locked `C1` / `C3` failed-run summary coverage.

## 2026-03-19: blocked `C1` exposure summaries are now explicitly locked at CLI level
- Saved shipped behavior:
  - failed composition summaries now have explicit CLI regression coverage for blocked `C1` top-port mismatch and blocked `C1` omitted-child-port exposure failures through the existing `Top port` / `Child port` context lines.
- Important continuity note:
  - this slice did not widen extractor behavior,
  - it hardens already-shipped failure-summary behavior at the CLI boundary,
  - and it keeps the reachable `C1` exposure families aligned across pipeline extraction and user-visible summary output.

## 2026-03-19: future syntax-power guidance is now saved
- Saved future note:
  - the current highest-leverage language-growth candidates are aggregate types with inference, interface bundles, enum-first case/match capture, small alias/default forms, bounded replication, intent helpers, assertions, and stronger explain/report mode.
- Important continuity note:
  - the saved rule is still “bounded semantic power, not a general macro system”,
  - and the follow-up nuance is preserved too: a later list-oriented meta-programming lane can exist only if it stays semantic, elaboration-bounded, and 100% RTL/synthesis-focused.

## 2026-03-19: `.rtlif` width/type failures are now explicitly locked through the token-summary path
- Saved shipped behavior:
  - failed composition summaries now have explicit regression coverage for blocked `.rtlif` port-sizing and port-typing failures through the same `RTL metadata file:` plus `Context: Token '...'` pairing used by the token-shape family.
- Important continuity note:
  - this slice did not widen extractor behavior,
  - it hardens the already-shipped token-scoped summary contract,
  - and it keeps the invalid-token / non-positive-width / unsupported-type trio aligned under one tested `Token` summary family.

## 2026-03-19: Rust FSMGen repo strategy is now saved
- Saved future note:
  - the existing `H1` Rust FSMGen horizon now carries an explicit initial repo recommendation,
  - namely: start a future Rust implementation in this same repository beside the Perl reference implementation instead of beginning with a separate repository plus Perl submodule split.
- Important continuity note:
  - the saved rationale is shared contract/corpus/differential-test leverage and avoidance of submodule drift while semantic parity is still being proven,
  - and a later repository split is still allowed if release cadence, packaging, or ownership eventually diverge enough to justify it.
## 2026-03-19: flatness `.rtlif` failures are now explicitly locked through the RTL-root summary path
- Saved shipped behavior:
  - failed composition summaries now have explicit regression coverage for blocked `.rtlif` flatness failures through the same `RTL metadata file:` plus `Context: RTL root '?rtlif:...'` pairing used by the other file-based root-scoped families.
- Important continuity note:
  - this slice did not widen extractor behavior,
  - it hardens the already-shipped root-scoped summary contract,
  - and it keeps the missing-root / empty-port / flatness trio aligned under one tested `RTL root` summary family.

## 2026-03-19: file-based `.rtlif` root failures now keep RTL root context in failed-run summaries
- Saved shipped behavior:
  - failed composition summaries can now keep `Context: RTL root '?rtlif:...'` for file-based root-scoped `.rtlif` failures such as missing-root and empty-port cases,
  - while still preserving the resolved `.rtlif` path as the separate `RTL metadata file:` artifact line.
- Important continuity note:
  - this is a narrow reporting refinement only,
  - it relies on the existing blocked diagnostic already naming the active `?rtlif:<module>` token,
  - and it keeps the failed-run summary model consistent across embedded and file-based `.rtlif` root families.

## 2026-03-19: embedded `.rtlif` duplicate-root failures now keep RTL root context in failed-run summaries
- Saved shipped behavior:
  - failed composition summaries can now keep `Context: RTL root '?rtlif:...'` for blocked embedded `.rtlif` duplicate-root failures,
  - and those same summaries still avoid inventing an `RTL metadata file:` artifact line because the metadata lives in the composition source itself.
- Important continuity note:
  - this is a narrow reporting refinement only,
  - it relies on the existing blocked diagnostic already naming the repeated embedded root token,
  - and it keeps the current failed-run summary lane moving by surfacing stable context instead of inventing parallel reporting logic.

## 2026-03-19: duplicate-port `.rtlif` failures now keep repeated RTL port context in failed-run summaries
- Saved shipped behavior:
  - failed composition summaries can now keep `Context: RTL port '...'` for blocked duplicate-port `.rtlif` declaration failures,
  - while still preserving the resolved `.rtlif` path as the separate `RTL metadata file:` artifact line.
- Important continuity note:
  - this is a narrow reporting refinement only,
  - it relies on the existing blocked diagnostic already naming the repeated port,
  - and it keeps the current failed-run summary lane moving by surfacing stable context rather than inventing parallel summary logic.

## 2026-03-18: non-quiet failed composition runs now print a first bounded failure summary
- Saved shipped behavior:
  - the pipeline can now derive a small composition failure report from blocked composition diagnostics,
  - and the CLI now prints a bounded composition-failure summary during non-quiet failed composition runs when the raised diagnostic exposes a blocked composition boundary, including a `Lane:` line when that diagnostic already names the active `C1` / `C2` / `C3` / `C4` lane, a `Construct:` line when that same diagnostic points clearly at one active syntax construct such as `?ports`, `?toplink`, `?rtl`, `?fsmc`, `?dtc`, or `=port`, a `Child source file:` line when a blocked generated-child realization failure already names the resolved external `.fsm` file, an `RTL metadata file:` line when a blocked `.rtlif` structure, token, sizing, typing, flatness, or declaration failure already names the resolved metadata file, a concise context line for the offending child/top-port/explicit-endpoint/metadata/token when that context can be separated honestly from longer follow-up detail, plus a concise blocked-reason line.
- Important continuity note:
  - quiet-mode failure behavior stays unchanged,
  - the original exception text still surfaces after the summary,
  - and this is the first deliberate move from pure exception text into richer failed-run composition reporting.

## 2026-03-18: malformed generated-child source payloads now say source shape/count is blocked
- Saved shipped behavior:
  - composition parser diagnostics now say blocked generated-child source-shape failures for nested `?fsmc` / `?dtc` payloads,
  - and blocked generated-child source-count failures when those same payloads declare zero or multiple flat source names instead of exactly one.
- Important continuity note:
  - this closes another older-wording pocket on a real generated-child parser boundary,
  - it keeps the one-source-per-generated-child contract unchanged,
  - and it adds focused direct parser plus pipeline and CLI coverage for both `?fsmc` and `?dtc`.

## 2026-03-18: unsupported composition child kinds now say child-kind support is blocked
- Saved shipped behavior:
  - composition parser diagnostics now say explicitly when composition child-kind support is blocked because a child header falls outside the active `?fsmc` / `?dtc` / `?rtl` / `?ports` / `?toplink` family.
- Important continuity note:
  - this closes another older-wording pocket on a real composition parser family boundary,
  - it keeps the child-kind contract unchanged,
  - and it adds focused direct parser plus pipeline and CLI coverage instead of relying on incidental raw “unsupported child” wording.

## 2026-03-18: malformed composition child entries now say child structure is blocked
- Saved shipped behavior:
  - composition parser diagnostics now say blocked child-structure failures for empty child entries, blocked child-header-shape failures for non-string child headers, and blocked child item-list-shape failures for dotted-pair child payloads.
- Important continuity note:
  - this closes another older-wording pocket on real malformed composition parser input,
  - it keeps the child-kind contract unchanged,
  - and it removes the older undef-header warning path while adding focused pipeline plus CLI coverage.

## 2026-03-18: `?toplink` naming cleanup is now tracked as future syntax work
- Saved future note:
  - `?toplink` is acceptable but not ideal as composition wiring syntax,
  - a future syntax-cleanup pass may later decide whether it stays canonical or gains a clearer preferred alias such as `?wiring`,
  - and compatibility should be preferred over abrupt source breakage if that future lane is taken.

## 2026-03-18: legacy `?ports` mapping directives now say port declaration mode is blocked
- Saved shipped behavior:
  - composition parser diagnostics now say explicitly when composition port declaration mode is blocked because `?ports` contains a legacy mapping directive like `/foo/bar/` instead of explicit top-port declarations.
- Important continuity note:
  - this closes another older-wording pocket on a real composition parser boundary,
  - it keeps the parser contract unchanged,
  - and it adds focused pipeline plus CLI coverage on top of the existing direct parser check.

## 2026-03-18: malformed `?ports` and `?toplink` parser items now say parser token boundaries are blocked
- Saved shipped behavior:
  - composition parser diagnostics now say blocked token-boundary failures for nested `?ports`, invalid `?ports` tokens, non-positive `?ports` widths, nested `?toplink` items, and unsupported `?toplink` tokens.
- Important continuity note:
  - this closes another older-wording pocket on real composition parser boundaries,
  - it keeps the parser token contract unchanged,
  - and it adds focused pipeline plus CLI coverage instead of relying on incidental parser exceptions.

## 2026-03-18: duplicate embedded `.rtlif` roots now say embedded-root uniqueness is blocked
- Saved shipped behavior:
  - embedded RTL metadata now says explicitly when RTL interface metadata embedded-root uniqueness is blocked because the same composition source contains multiple embedded `?rtlif:<module>` roots for one external RTL child.
- Important continuity note:
  - this closes another older-wording pocket on a real embedded-RTL metadata-contract boundary,
  - it keeps the embedded-root precedence/uniqueness contract unchanged,
  - and it adds focused pipeline plus CLI coverage on top of the existing direct-loader check.

## 2026-03-18: nested external `.rtlif` metadata now says flatness is blocked
- Saved shipped behavior:
  - reachable external RTL metadata now says explicitly when RTL interface metadata flatness is blocked because a `.rtlif` file contains nested structure under the required `?rtlif:<module>` root.
- Important continuity note:
  - this closes another older-wording pocket on a real external-RTL interface-contract boundary,
  - it keeps the `.rtlif` flat-token contract unchanged,
  - and it adds focused pipeline plus CLI coverage instead of relying on incidental nested-metadata failures.

## 2026-03-18: empty external `.rtlif` interfaces now say metadata port presence is blocked
- Saved shipped behavior:
  - reachable external RTL metadata now says explicitly when RTL interface metadata port presence is blocked because a `.rtlif` file declares no ports under the required `?rtlif:<module>` root.
- Important continuity note:
  - this closes another older-wording pocket on a real external-RTL interface-contract boundary,
  - it keeps the `.rtlif` port-presence contract unchanged,
  - and it adds focused pipeline plus CLI coverage instead of relying on incidental empty-interface failures.

## 2026-03-18: duplicate external `.rtlif` ports now say declaration uniqueness is blocked
- Saved shipped behavior:
  - reachable external RTL metadata now says explicitly when RTL interface metadata port declaration uniqueness is blocked because a `.rtlif` file repeats the same port name.
- Important continuity note:
  - this closes another older-wording pocket on a real external-RTL declaration-contract boundary,
  - it keeps the `.rtlif` declaration contract unchanged,
  - and it adds focused pipeline plus CLI coverage instead of relying on incidental duplicate-port failures.

## 2026-03-18: non-positive external `.rtlif` widths now say metadata port sizing is blocked
- Saved shipped behavior:
  - reachable external RTL metadata now says explicitly when RTL interface metadata port sizing is blocked because a `.rtlif` token declares a non-positive explicit width.
- Important continuity note:
  - this closes another older-wording pocket on a real external-RTL token-contract boundary,
  - it keeps the `.rtlif` width contract unchanged,
  - and it adds focused pipeline plus CLI coverage instead of relying on incidental non-positive-width failures.

## 2026-03-18: invalid external `.rtlif` port tokens now say metadata token shape is blocked
- Saved shipped behavior:
  - reachable external RTL metadata now says explicitly when RTL interface metadata token shape is blocked because a `.rtlif` token is syntactically invalid for the current flat port-token contract.
- Important continuity note:
  - this closes another older-wording pocket on a real external-RTL token-contract boundary,
  - it keeps the `.rtlif` contract unchanged,
  - and it adds focused pipeline plus CLI coverage instead of relying on incidental invalid-token failures.

## 2026-03-17: unsupported external `.rtlif` port types now say metadata typing is blocked
- Saved shipped behavior:
  - reachable external RTL metadata now says explicitly when RTL interface metadata port typing is blocked because a `.rtlif` token resolves to an unsupported explicit type outside the current `data|clock|reset` contract.
- Important continuity note:
  - this closes another older-wording pocket on a real external-RTL token-contract boundary,
  - it keeps the `.rtlif` contract unchanged,
  - and it adds focused pipeline plus CLI coverage while keeping the older direct loader coverage meaningful.

## 2026-03-17: wrong-root external `.rtlif` metadata now says structure is blocked
- Saved shipped behavior:
  - reachable external RTL metadata now says explicitly when RTL interface metadata structure is blocked because the `.rtlif` file does not contain the required `?rtlif:<module>` root for that `?rtl` child.
- Important continuity note:
  - this closes another older-wording pocket on a real external-RTL interface-source boundary,
  - it keeps the `.rtlif` contract unchanged,
  - and it adds focused pipeline plus CLI coverage instead of relying on incidental wrong-root failures.

## 2026-03-17: missing external `.rtlif` metadata now says resolution is blocked
- Saved shipped behavior:
  - missing external RTL metadata now says explicitly when RTL interface metadata resolution is blocked because no declared `.rtlif` metadata can be found for a `?rtl` child.
- Important continuity note:
  - this closes another older-wording pocket on a real mixed-composition integration boundary,
  - it keeps the external-RTL contract unchanged,
  - and it adds focused pipeline plus CLI coverage instead of relying on incidental metadata lookup failures.
## 2026-03-17: blocked `C2` lane selection now says so explicitly
- Saved shipped behavior:
  - one-generated-child explicit-link tops now say explicitly when `C2` lane selection is blocked because the active `C2` lane requires at least two generated children.
- Important continuity note:
  - this closes another older-wording pocket on a real explicit-link composition path,
  - it keeps the `C2` planner behavior unchanged,
  - and it adds focused pipeline plus CLI coverage instead of relying on incidental lane-selection fallout.
## 2026-03-17: generated child-source failures now say resolution or realization is blocked
- Saved shipped behavior:
  - external `?fsmc` / `?dtc` lookup failures now say explicitly when child-source resolution is blocked because no active child source can be found,
  - and wrong-kind resolved child files now say explicitly when child-source realization is blocked because the resolved source is rooted under the wrong active source kind.
  - wrong-kind `?fsmc` failures now point users to `?dtc`,
  - and wrong-kind `?dtc` failures now point users to `?fsmc`.
- Important continuity note:
  - this closes another older-wording pocket on a real reusable-module integration boundary,
  - it fixes an outdated note that still described standalone-DT child realization as future work,
  - and it adds focused pipeline plus CLI coverage instead of relying on incidental child-load failures.
## 2026-03-17: unsupported composition backend targets now say target support is blocked
- Saved shipped behavior:
  - valid composition sources now say explicitly when composition target support is blocked because the current composition lanes only emit SystemVerilog/Verilog tops,
  - and the diagnostic still names the unsupported requested target language directly.
- Important continuity note:
  - this closes another older-wording pocket on a real composition CLI boundary,
  - it keeps backend behavior unchanged,
  - and it adds focused pipeline and CLI coverage instead of relying on incidental target-selection failures.
## 2026-03-17: endpoint-shape diagnostics now say when binding is blocked
- Saved shipped behavior:
  - reserved-system `=name` declarations now say explicitly when declared connect-by-name is blocked because shared system ports already use the dedicated system-input contract,
  - and unsupported explicit endpoint syntax now says explicitly when explicit link endpoint resolution is blocked because only top-port names and `instance.port` child endpoints are supported.
- Important continuity note:
  - this closes another older-wording pocket on the public composition endpoint surface,
  - it keeps binding behavior unchanged,
  - and it adds focused coverage instead of relying on incidental endpoint-shape failures.
## 2026-03-17: duplicate composition declarations now say when shape is blocked
- Saved shipped behavior:
  - duplicate top-port declarations now say explicitly when composition shape is blocked because top port names must be unique,
  - and duplicate realized child instance names now say explicitly when composition shape is blocked because child instance names must be unique.
- Important continuity note:
  - this closes another older-wording pocket in public composition-shape diagnostics,
  - it keeps planning behavior unchanged,
  - and it adds focused coverage instead of relying on incidental duplicate-declaration failures.
## 2026-03-17: `C1` passthrough exposure failures now say when exposure is blocked
- Saved shipped behavior:
  - `C1` passthrough exposure now says explicitly when it is blocked because explicit top exposure omitted a realized child port,
  - and it now says the same thing when an explicitly declared top port disagrees with the realized child interface on existence, width, or direction.
- Important continuity note:
  - this closes another older-wording pocket in the public single-child composition path,
  - it keeps the planner behavior unchanged,
  - and it adds focused regression coverage instead of relying only on existing `C1` success tests.
## 2026-03-17: top-level composition lane and shape gates now say they are blocked
- Saved shipped behavior:
  - top-level composition lane entry now says explicitly when it is blocked because no child instances exist,
  - and top-level composition shape now says explicitly when it is blocked because `?ports` multiplicity is invalid or omitted/empty `?ports` appears outside the bounded inference cases.
- Important continuity note:
  - this extends the blocked-wording surface from explicit-link execution into the top-level composition gates,
  - it updates the existing no-child coverage and adds focused shape-gate coverage,
  - and it keeps the planner behavior unchanged.
## 2026-03-17: explicit-link lane-entry and topology failures now say they are blocked
- Saved shipped behavior:
  - explicit-link lane entry now says explicitly when it is blocked because `C2`/`C3` was entered without any `?toplink`,
  - and explicit-link topology now says explicitly when it is blocked because a top input tries to drive a top output directly or one source tries to drive multiple top outputs.
- Important continuity note:
  - this closes another older-wording pocket in the explicit-link family,
  - it adds focused coverage instead of widening planner behavior,
  - and it keeps the same endpoint/source detail in the exception text.
## 2026-03-17: explicit-link unwired-port failures now say wiring is blocked
- Saved shipped behavior:
  - explicit-link top-port failures now say explicitly when top wiring is blocked because a declared non-system top port remains unused,
  - and explicit-link child-port failures now say explicitly when realized child wiring is blocked because a realized child port remains unconnected.
- Important continuity note:
  - this closes the remaining unwired-port wording pocket in the explicit-link family,
  - it adds focused regression coverage instead of widening planner behavior,
  - and it keeps the same top-port and child-port detail in the exception text.
## 2026-03-17: explicit toplink validation failures now say when the declared link is blocked
- Saved shipped behavior:
  - explicit `?toplink` endpoint resolution failures now say explicitly when the declared link is blocked by a missing endpoint,
  - and explicit `?toplink` validation now says the declared link is blocked when direction, duplicate-drive, or width evidence prevents it from applying.
- Important continuity note:
  - this broadens the blocked-wording surface into the core explicit-link validation family,
  - it reuses the existing composition-error coverage rather than widening planner behavior,
  - and it keeps the detailed endpoint evidence intact in the exception text.
## 2026-03-17: explicit top-output re-export mismatches now say when re-export is blocked
- Saved shipped behavior:
  - explicit top-output re-export mismatches for inferred same-name internal carriers now say explicitly when that bounded re-export path is blocked,
  - and the width/type mismatch branches still keep the resolved child-side width/type detail in the exception text.
- Important continuity note:
  - this closes the remaining older-wording pocket in the internal-carrier re-export branch,
  - it reuses the existing local-override rule instead of widening planner behavior,
  - and it adds focused coverage for both width and type mismatch wording in [t/100-composition-internal-carrier-top-reexport.t](/Users/richarddje/Documents/github/fsmgen/t/100-composition-internal-carrier-top-reexport.t).
## 2026-03-17: declared connect-by-name failures now say when the declared match is blocked
- Saved shipped behavior:
  - declared `=name` connect-by-name failures now say explicitly when the declared match is blocked,
  - and the mixed-direction, width-mismatch, ambiguity, and missing-endpoint branches all keep their same-name endpoint evidence in the exception text.
- Important continuity note:
  - this broadens the blocked-wording diagnostics into the `C4` declared connect-by-name family,
  - it reuses existing focused coverage instead of widening planner behavior,
  - and the next diagnostics seam is now broader failure-path wording beyond these major composition families.
- Updated [t/24-composition-connect-by-name.t](/Users/richarddje/Documents/github/fsmgen/t/24-composition-connect-by-name.t) and [t/95-composition-connect-by-name-input-fanout.t](/Users/richarddje/Documents/github/fsmgen/t/95-composition-connect-by-name-input-fanout.t) to lock the broadened blocked-wording surface for declared connect-by-name.
## 2026-03-17: explicit-toplink top-port inference failures now say when inference is blocked
- Saved shipped behavior:
  - explicit-toplink-driven undeclared top-port inference failures now say explicitly when that inference path is blocked,
  - and the mixed-role, width-mismatch, and type-mismatch branches all keep their explicit-link evidence in the exception text.
- Important continuity note:
  - this broadens the blocked-wording diagnostics into the explicit-toplink inference family,
  - it also closes previously untested width/type wording branches there,
  - and the next diagnostics seam is now broader failure-path wording beyond these major convention-over-configuration inference paths.
- Updated [t/101-composition-explicit-link-implicit-ports.t](/Users/richarddje/Documents/github/fsmgen/t/101-composition-explicit-link-implicit-ports.t) to lock the broadened blocked-wording surface for explicit-toplink-driven undeclared top-port inference.
## 2026-03-17: undeclared inference failure diagnostics now say when convention is blocked
- Saved shipped behavior:
  - undeclared top-input inference failures now say explicitly when that convention-first path is blocked,
  - undeclared top-output inference failures now say explicitly when that convention-first path is blocked,
  - and undeclared same-name internal-carrier inference failures now do the same.
- Important continuity note:
  - this broadens the earlier blocked-wording slice beyond plain explicit top ports,
  - it keeps the concrete child-endpoint detail intact,
  - and the next diagnostics seam is now broader failure-path wording outside these main convention-first composition families.
- Updated [t/97-composition-implicit-multi-child-inputs.t](/Users/richarddje/Documents/github/fsmgen/t/97-composition-implicit-multi-child-inputs.t), [t/98-composition-implicit-multi-child-outputs.t](/Users/richarddje/Documents/github/fsmgen/t/98-composition-implicit-multi-child-outputs.t), and [t/99-composition-implicit-internal-carriers.t](/Users/richarddje/Documents/github/fsmgen/t/99-composition-implicit-internal-carriers.t) to lock the broadened blocked-wording failure surface.
## 2026-03-17: plain explicit top-port failure diagnostics now say when convention is blocked
- Saved shipped behavior:
  - plain explicit top-port same-name convention failures now say explicitly when that convention is blocked,
  - and they still list the conflicting child endpoints instead of collapsing into generic ambiguity text.
- Important continuity note:
  - this is the first bounded failure-path blocked-wording slice,
  - it lines up the exception surface with the already-shipped successful-run `Convention Blocks` reporting,
  - and the next diagnostics seam is now broader failure-path wording beyond these plain explicit top-port cases.
- [t/107-composition-blocked-failure-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/107-composition-blocked-failure-diagnostics.t) locks the new blocked-wording failure surface.
## 2026-03-17: composition provenance now reports blocked convention cases too
- Saved shipped behavior:
  - `composition_report` now includes the first surfaced blocked-event family,
  - non-quiet `bin/fsmgen` runs now print a `Convention Blocks` summary when those events are present,
  - and composition `module_info` / `statistics` now carry the block count too.
- Important continuity note:
  - the currently shipped blocked events are bounded to explicit child links blocking undeclared top-input/top-output inference and inferred internal carriers staying internal by default,
  - this closes the first successful-run “blocked” visibility gap,
  - and the next reporting/diagnostics seam is now broader failure-path wording rather than more successful-run hidden behavior.
- [t/106-composition-blocked-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/106-composition-blocked-reporting.t) locks the new blocked-report surface.
## 2026-03-17: composition provenance now reports local override events too
- Saved shipped behavior:
  - `composition_report` now includes the first surfaced override-event family,
  - non-quiet `bin/fsmgen` runs now print a `Convention Overrides` summary when those events are present,
  - and composition `module_info` / `statistics` now carry the override count too.
- Important continuity note:
  - the currently shipped override events are bounded to explicit toplinks overriding same-name top-input/top-output convention and explicit top-output re-export of inferred internal carriers,
  - this closes the first “overridden” visibility gap,
  - and the next reporting/diagnostics gap is now mostly “blocked” cases rather than more successful-run override visibility.
- [t/105-composition-override-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/105-composition-override-reporting.t) locks the new override-report surface.
## 2026-03-17: composition provenance now reaches the result hash and CLI summary
- Saved shipped behavior:
  - composition runs now return `composition_report`,
  - that report summarizes top-port and resolved-link provenance from the earlier `origin_kind` / `resolved_links` metadata,
  - and non-quiet `bin/fsmgen` runs now print the same composition provenance summary directly.
- Important continuity note:
  - this is the first user-facing reporting layer on top of the earlier typed provenance metadata,
  - it also populates composition-side resolved-link counts in `module_info` and `statistics`,
  - and the next remaining diagnostics lane is broader failure/report wording for “blocked” / “overridden” cases, not another hidden inference jump.
- [t/104-composition-provenance-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/104-composition-provenance-reporting.t) locks the new report surface.
## 2026-03-17: typed composition plans now expose provenance metadata
- Saved shipped behavior:
  - top ports now carry `origin_kind`,
  - links now carry `origin_kind`,
  - and composition plans now carry `resolved_links` as the full planned-link set instead of exposing only the original `links` input.
- Important continuity note:
  - this is additive, not a replacement of the older `links` field,
  - the current metadata now distinguishes declared explicit ports/links, declared `=name`, inferred passthrough ports/links, explicit-toplink inferred ports, plain-explicit-port convention links, internal-carrier links/re-exports, and auto system-port links,
  - and this is the first bounded step toward the roadmap goal of explaining whether a port/link was inferred, blocked, or overridden.
- [t/103-composition-provenance-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/103-composition-provenance-metadata.t) locks the new provenance surface.
## 2026-03-17: explicit-link `C2` / `C3` plain explicit top ports now reuse same-name convention
- Saved shipped behavior:
  - plain explicit top inputs in explicit-link `C2` / `C3` may now fan out by same name when compatible child inputs still keep one direction plus exact width/type agreement,
  - plain explicit top outputs in explicit-link `C2` / `C3` may now adopt one unique same-name top-facing child output when that child-side evidence stays exact,
  - and explicit top-boundary links still override that convention locally instead of forcing whole-interface restatement.
- Important continuity note:
  - this slice is intentionally separate from `=name` `C4`,
  - mixed input/output same-name families still rely on the already-shipped internal-carrier rule,
  - mixed-direction plain-input families now fail explicitly,
  - and ambiguous plain-output same-name families now fail explicitly too.
- [t/102-composition-explicit-port-convention.t](/Users/richarddje/Documents/github/fsmgen/t/102-composition-explicit-port-convention.t) locks generated-child `C2` success, mixed generated-plus-`?rtl` `C3` success, mixed-direction rejection for plain explicit top inputs, and ambiguity rejection for plain explicit top outputs.
## 2026-03-17: architecture hotspot snapshot saved for future refactor work
- Saved the latest architecture read-through from [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) down the active imported `FSM::*` tree into the continuity docs and roadmap.
- The recorded future seams are:
  - [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) still owning too much composition orchestration/policy/planning,
  - [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm) remaining the main synthesis gravity well,
  - [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm) still carrying enough planning/normalization logic that the backend boundary is not purely rendering-oriented,
  - the still-implicit bridge between [perl/FSM/CoreAST.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/CoreAST.pm) and the `FSM::AST::*` family,
  - [perl/FSM/ExpressionNamer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/ExpressionNamer.pm) still needing an eventual “live surface vs residue” decision,
  - stale compatibility wording still present in [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen),
  - and global debug state in [perl/FSM/Debug.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Debug.pm) that should be revisited before deeper embedding/API work.
- Continuity note:
  - this is now explicit roadmap work, not just one-session analysis,
  - and the intended follow-up is bounded seam-by-seam retirement while `R11` is still actively shaping composition/type contracts.
## 2026-03-17: explicit-link `C2` / `C3` now infer top ports directly from explicit `?toplink`
- Saved shipped behavior:
  - explicit-link multi-child tops may now omit `?ports` entirely, or use an empty `(?ports)`,
  - and the top boundary is now realized directly from explicit `?toplink` endpoints when those undeclared top endpoints imply one consistent direction plus exact width/type agreement.
- Important continuity note:
  - same-name explicit top-input links now infer the top port declaration without duplicating the already-declared explicit bindings,
  - renamed top endpoints are now supported through explicit `?toplink` evidence instead of requiring an explicit top-port declaration,
  - and undeclared top endpoints still fail explicitly when they are used as both inputs and outputs.
- [t/101-composition-explicit-link-implicit-ports.t](/Users/richarddje/Documents/github/fsmgen/t/101-composition-explicit-link-implicit-ports.t) locks generated-child renamed-endpoint success, RTL-backed renamed-endpoint success, and mixed-role undeclared-endpoint rejection.

## 2026-03-17: explicit-link `C2` / `C3` now re-export inferred same-name internal carriers through explicit top outputs
- Saved shipped behavior:
  - explicit-link tops may still infer same-name internal child-to-child carriers conventionally,
  - those carriers still stay internal by default,
  - but an explicit same-name top output may now adopt and re-export one of those inferred carriers when direction, width, and type metadata still match.
- Important continuity note:
  - explicit links touching that family still suppress the inference locally,
  - several same-name child outputs still fail through the dedicated internal-carrier ambiguity diagnostic,
  - and type-mismatched explicit top-output re-export requests now fail explicitly instead of silently riding the old width-only link path.
- [t/100-composition-internal-carrier-top-reexport.t](/Users/richarddje/Documents/github/fsmgen/t/100-composition-internal-carrier-top-reexport.t) locks generated-child success, mixed generated-plus-`?rtl` success, ambiguity rejection, and top-output type-mismatch rejection for the shipped re-export slice.

## 2026-03-17: explicit-link `C2` / `C3` now infer same-name internal carriers
- Saved shipped behavior:
  - explicit-link tops may now infer internal same-name child-to-child carriers when exactly one same-name child output and one or more same-name child inputs remain available,
  - and the inferred carrier uses the shared signal name and stays internal by default.
- Important continuity note:
  - any explicit top port or explicit link touching that name family suppresses the inference locally,
  - several same-name child outputs now fail through a dedicated internal-carrier diagnostic,
  - and that follow-up question is now answered by the newer shipped explicit top-output re-export slice recorded above.
- [t/99-composition-implicit-internal-carriers.t](/Users/richarddje/Documents/github/fsmgen/t/99-composition-implicit-internal-carriers.t) locks generated-child fanout success, mixed generated-plus-`?rtl` success, and several-output ambiguity rejection.

## 2026-03-17: explicit-link `C2` / `C3` now infer undeclared unique top outputs
- Saved shipped behavior:
  - explicit-link tops may now infer undeclared top outputs when exactly one same-name child output remains top-facing,
  - and that inferred top output binds directly back to the unique child output.
- Important continuity note:
  - child outputs already consumed by explicit child-to-child links are not re-inferred as top outputs,
  - several same-name top-facing child outputs now fail through a dedicated inference diagnostic,
  - and that top-output slice is now complemented by a separate shipped internal-carrier slice for same-name producer-to-consumer families.
- [t/98-composition-implicit-multi-child-outputs.t](/Users/richarddje/Documents/github/fsmgen/t/98-composition-implicit-multi-child-outputs.t) locks generated-child success, single-`?rtl` explicit-link success, and same-name output ambiguity rejection.

## 2026-03-17: future `R11` now carries a convention-first, local-override composition rule
- Saved future direction:
  - convention should stay the default integration path wherever child/top wiring is unambiguous,
  - explicit port/link declarations should override inference locally instead of forcing whole-interface restatement,
  - and configuration should stay elegant and expressive rather than verbose duplicate wiring.
- Important continuity note:
  - ambiguity should still fail instead of being guessed through,
  - and future diagnostics should explain whether a connection was inferred, blocked, or overridden.

## 2026-03-17: explicit-link `C2` / `C3` now infer undeclared top inputs
- Saved shipped behavior:
  - explicit-link multi-child tops may now infer undeclared top inputs when same-name child inputs remain top-facing,
  - and the inference requires exact agreement on direction, width, and type metadata.
- Important continuity note:
  - child inputs already consumed by explicit child-to-child links are not re-inferred as top ports,
  - this slice still does not infer undeclared top outputs,
  - and it still does not create internal same-name producer-to-consumer carriers automatically.
- [t/97-composition-implicit-multi-child-inputs.t](/Users/richarddje/Documents/github/fsmgen/t/97-composition-implicit-multi-child-inputs.t) locks shared-input success and width-mismatch rejection.

## 2026-03-17: single-child `C1` now infers top ports when `?ports` is omitted or empty
- Saved shipped behavior:
  - `C1` single-child passthrough now accepts no `?ports` block or an empty `(?ports)` block,
  - and in that bounded case the generated top interface is inferred directly from the lone realized child interface.
- Important continuity note:
  - this is deliberately not broad multi-child inference yet,
  - it works because both generated children and external `?rtl` children already realize typed interfaces,
  - and the next convention-over-configuration question is whether undeclared inference should widen beyond this simple passthrough slice.
- [t/96-composition-implicit-single-child-ports.t](/Users/richarddje/Documents/github/fsmgen/t/96-composition-implicit-single-child-ports.t) locks omitted-`?ports` `?fsmc` passthrough inference and empty-`?ports` `?rtl` passthrough inference.

## 2026-03-17: future `R11` now includes a portable synthesizable-type and inference-first lane
- Saved future direction:
  - `R11` now explicitly includes portable synthesizable scalar/aggregate types as a concrete sub-lane instead of relying on conversation memory,
  - the saved portable type core is bits/vectors, enums, records, fixed arrays, arrays of records, and aliases/subtypes,
  - and the preferred user workflow is inference-first: infer scalar versus aggregate signal/port types from LHS/RHS/member/index usage whenever that is honest.
- Important continuity note:
  - explicit type declarations are still part of the future design, but mainly as overrides, ambiguity anchors, and interface-stability controls rather than as mandatory boilerplate,
  - and the future frontend contract should not promise SystemVerilog-only packed-casting convenience that would make a later VHDL backend dishonest.
- [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) now records proposed `(+types ...)` syntax plus phased implementation boundaries for that lane, and [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) tracks it under `R11 Left`.

## 2026-03-17: declared top-input `=name` now fans out across matching child inputs
- Saved shipped behavior:
  - `=name` top outputs still stay exact-one-match against child outputs,
  - `=name` top inputs now fan out to all matching child inputs with the same name and width.
- Important continuity note:
  - mixed-direction or width-mismatched same-name candidates now fail explicitly instead of being silently filtered,
  - so the current boundary is more integration-friendly without becoming broad undeclared inference.
- [t/95-composition-connect-by-name-input-fanout.t](/Users/richarddje/Documents/github/fsmgen/t/95-composition-connect-by-name-input-fanout.t) locks the new fanout behavior plus mixed-direction rejection.

## 2026-03-17: declared connect-by-name `C4` now covers multi-generated-plus-`?rtl` tops too
- Saved shipped behavior:
  - `C4` declared connect-by-name still uses the same exact same-name, same-direction, same-width rule,
  - and it now also works when multiple generated children participate beside one or more external `?rtl` children.
- Important continuity note:
  - this slice still did not add hidden inference or a new lane; it just lets the already-general by-name linker admit the broader mixed topology honestly.
- [t/94-composition-multi-generated-plus-rtl-connect-by-name.t](/Users/richarddje/Documents/github/fsmgen/t/94-composition-multi-generated-plus-rtl-connect-by-name.t) locks the first multi-generated-plus-`?rtl` `C4` success path.

## 2026-03-17: explicit-link `C3` now covers multi-generated-plus-`?rtl` tops too
- Saved shipped behavior:
  - `C3` explicit-link composition still requires at least one external `?rtl` child,
  - and it now also works when multiple generated children participate beside those external RTL children.
- Important continuity note:
  - this slice still did not invent a new lane or hidden inference; it just lets the already-general explicit-link planner admit the broader mixed topology honestly.
- [t/93-composition-multi-generated-plus-rtl-children.t](/Users/richarddje/Documents/github/fsmgen/t/93-composition-multi-generated-plus-rtl-children.t) locks the first multi-generated-plus-`?rtl` `C3` success path.

## 2026-03-17: declared connect-by-name `C4` now covers multi-`?rtl` tops too
- Saved shipped behavior:
  - `C4` declared connect-by-name now works for multiple external `?rtl` children,
  - and `C4` now also works for exactly one generated child plus multiple external `?rtl` children.
- Important continuity note:
  - this slice stayed on the same exact-match rule as the earlier by-name work; it did not add hidden inference or arbitration, it only lifted the old one-RTL guard.
- [t/92-composition-multi-rtl-connect-by-name.t](/Users/richarddje/Documents/github/fsmgen/t/92-composition-multi-rtl-connect-by-name.t) locks the first multi-RTL and generated-plus-multi-RTL `C4` success paths plus ambiguity rejection.

## 2026-03-16: explicit-link `C3` now covers multi-`?rtl` tops too
- Saved shipped behavior:
  - `C3` explicit-link composition now works for multiple external `?rtl` children,
  - and `C3` now also works for exactly one generated child plus multiple external `?rtl` children.
- Important continuity note:
  - this slice did not add a new lane or hidden inference; it only widened the already-shipped explicit-link `C3` guard to match what the planner/emitter already handled structurally.
- [t/91-composition-multi-rtl-children.t](/Users/richarddje/Documents/github/fsmgen/t/91-composition-multi-rtl-children.t) locks the first all-RTL and generated-plus-multi-RTL `C3` success paths.

## 2026-03-16: single external `?rtl` child composition now has a first shipped `R11` slice
- Saved shipped behavior:
  - a lone `?rtl` child now works in `C1` passthrough tops,
  - a lone `?rtl` child now works in `C3` explicit-toplink tops,
  - and a lone `?rtl` child now works in `C4` declared connect-by-name tops.
- Important continuity note:
  - the broadened planner rules do not invent a new lane or new syntax; they reuse the already-shipped C1/C3/C4 wiring contracts for a smaller child set.
- [t/90-composition-single-rtl-child.t](/Users/richarddje/Documents/github/fsmgen/t/90-composition-single-rtl-child.t) locks those single-RTL success paths, and [t/13-composition-source-classification.t](/Users/richarddje/Documents/github/fsmgen/t/13-composition-source-classification.t) now names `?rtl` honestly in the no-child boundary.

## 2026-03-16: embedded `?rtlif` roots now have a first shipped `R11` slice
- Saved shipped behavior:
  - `?top:name` sources may now carry embedded `(?rtlif:module_name ...)` companion roots for external RTL children,
  - embedded same-file interface roots take precedence over sidecar `<module>.rtlif` files,
  - and mixed generated-child plus `?rtl` composition can now succeed without a separate sidecar file when the interface contract is declared locally.
- Important continuity note:
  - duplicate embedded `?rtlif` roots for the same RTL module name are rejected explicitly, so local precedence does not silently collapse into ambiguous metadata selection.
- [t/89-composition-embedded-rtlif-roots.t](/Users/richarddje/Documents/github/fsmgen/t/89-composition-embedded-rtlif-roots.t) locks embedded-root precedence, no-sidecar mixed composition success, and duplicate embedded-root rejection.

## 2026-03-16: typed `.rtlif` ports now have a first deliberate `R11` contract slice
- Saved shipped `.rtlif` contract:
  - one flat `(?rtlif:module_name ...)` root,
  - declaration-ordered port tokens,
  - compact tokens such as `clk`, `data_in<8`, and `txd>`,
  - typed tokens such as `core_clk:clock`, `rst_async_n:reset`, and `data_in<8:data`,
  - and explicit type annotations currently limited to `data`, `clock`, and `reset`.
- Important runtime consequence:
  - mixed generated-child plus `?rtl` composition can now auto-wire custom-named RTL system ports honestly through typed `.rtlif` metadata instead of depending on literal `clk` / `rst_n` naming.
- [t/88-rtlif-typed-port-contract.t](/Users/richarddje/Documents/github/fsmgen/t/88-rtlif-typed-port-contract.t) locks direct typed-token parsing, custom-system-port auto-wiring, and rejection of unsupported explicit type names.

## 2026-03-16: mixed generated-child plus external RTL declared connect-by-name now has a first shipped `R11` slice
- `?top:name` now has regression-backed declared `=name` support for the mixed one-generated-child plus one-`?rtl` lane too.
- Saved shipped behavior:
  - mixed tops may combine explicit child-to-child `?toplink` wiring with by-name top exposure,
  - mixed `?fsmc` + `?rtl` and mixed `?dtc` + `?rtl` declared connect-by-name both work,
  - and cross-kind same-name ambiguity still fails explicitly.
- Important bug fix continuity:
  - composition-facing standalone-DT child interfaces now trust semantic `signal_role` before the old name-based heuristic,
  - so RHS-only DT signals like `payload_in` no longer get misclassified as outputs just because they start with `p`.
- [t/87-composition-mixed-connect-by-name.t](/Users/richarddje/Documents/github/fsmgen/t/87-composition-mixed-connect-by-name.t) locks the mixed-lane success and ambiguity cases.

## 2026-03-16: single-child declared connect-by-name now has a first shipped `R11` slice
- `?top:name` now accepts declared `=name` connect-by-name with exactly one generated child (`?fsmc` or `?dtc`) instead of starting only beyond the single-child passthrough case.
- The bounded rule stays the same:
  - exactly one same-named child endpoint,
  - same direction,
  - same width.
- Purely combinational standalone-DT children still keep an honest non-system interface in that single-child by-name lane.
- [t/86-composition-single-child-connect-by-name.t](/Users/richarddje/Documents/github/fsmgen/t/86-composition-single-child-connect-by-name.t) locks the first single-child `?fsmc` and `?dtc` by-name success paths.

## 2026-03-16: composition-facing standalone-DT children now have a first shipped `R11` slice
- Saved shipped behavior:
  - composition now accepts `?dtc:instance child_source` beside `?fsmc`,
  - `?dtc` child sources can be embedded `?dt:name` roots or external searchable `.fsm` standalone-DT sources,
  - and the current generated-child composition lanes now cover standalone-DT child realization too.
- Important continuity note:
  - purely combinational `?dtc` children keep an honest non-system interface in composition,
  - sequential `?dtc` children still expose implicit `clk` / `rst_n` when the standalone `?dt:name` contract requires them.
- [t/85-composition-standalone-dt-children.t](/Users/richarddje/Documents/github/fsmgen/t/85-composition-standalone-dt-children.t) locks the first success-path slice for `?dtc`.
## 2026-03-16: external composition child FSM reuse now has a first shipped `R11` slice
- Saved shipped behavior:
  - `?top:name` can now realize `?fsmc` children from embedded child FSM sources or from external searchable `.fsm` child sources,
  - external child-source lookup checks beside the composition source first, then repeated `--path DIR` roots, then `FSMLIB`, then the current directory,
  - and that broader reusable-root/reference slice now covers live composition child reuse instead of stopping at bare input lookup and `.rtlif` lookup.
- [t/84-composition-external-fsm-child-sources.t](/Users/richarddje/Documents/github/fsmgen/t/84-composition-external-fsm-child-sources.t) locks sibling external child realization, `--path`-driven child realization, and `--path` precedence over `FSMLIB` for `?fsmc` child lookup.
## 2026-03-16: reusable-source lookup now has a first shipped `R11` slice
- Saved shipped behavior:
  - the CLI now accepts repeatable `--path DIR` roots,
  - bare `.fsm` input lookup searches explicit `--path` roots before `FSMLIB`,
  - and current external `.rtlif` metadata lookup also uses those explicit roots before `FSMLIB`.
- [perl/FSM/SourcePathResolver.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/SourcePathResolver.pm) now centralizes that root ordering so we do not duplicate it again in the CLI and metadata loader.
- [t/83-reusable-source-path-resolution.t](/Users/richarddje/Documents/github/fsmgen/t/83-reusable-source-path-resolution.t) locks the bare-input lookup, precedence, and `.rtlif` lookup parts of that slice.
## 2026-03-16: first `R11` standalone `?dt:name` slice is now shipped
- `R11` is no longer purely future-note territory. The first reusable standalone-DT slice is now live.
- Saved shipped contract:
  - `?dt:name` is now a classified/generating source root,
  - top-level `?dt:name` content currently supports `(+size ...)`, `(+constants ...)`, `(+enums ...)`, `(+define ...)`, `(+params ...)`, compact `(:= signal=value)` directives, and general DT blocks such as `(-foo ...)`,
  - explicit `+system` is rejected inside `?dt:name`,
  - purely combinational `?dt:name` modules expose no implicit `clk` / `rst_n`,
  - sequential `?dt:name` modules expose implicit `clk` / `rst_n`,
  - driven non-intermediate targets in `?dt:name` become module outputs by default,
  - and `?dt:name` generation does not synthesize `current_state` / `next_state`.
- [t/82-standalone-dt-root-support.t](/Users/richarddje/Documents/github/fsmgen/t/82-standalone-dt-root-support.t) locks both the combinational and sequential success paths.
## 2026-03-16: malformed `:=` directive shapes now have explicit end-to-end coverage
- [t/81-language-contract-init-directive-shape-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/81-language-contract-init-directive-shape-boundary.t) now locks:
  - malformed non-scalar payloads such as `(:= (tester_reset=1 extra))`,
  - malformed compact directives such as `(:= BROKEN)`,
  - and parser, pipeline, and CLI no-output behavior for the malformed-shape side of the active `:=` family.
## 2026-03-16: reset naming now distinguishes current `?fsm` residue from future/default convention
- Saved wording split:
  - current shipped explicit `(?fsm:name ... (+system ...))` compatibility residue still uses `rstn`,
  - but the forward/default async-reset convention remains `rst_n`,
  - including the implicit no-`+system` path and the planned `?top:name` / sequential `?dt:name` lanes.
## 2026-03-16: non-conventional `+system` reset names now have full coverage
- [t/80-language-contract-system-reset-name-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/80-language-contract-system-reset-name-boundary.t) now locks:
  - `(sreset reset)`,
  - and `(asreset reset_async_n)`.
- Those malformed reset-name cases are now covered through direct parser checks plus pipeline and CLI no-output behavior, so the conventional `+system` family is no longer fully explicit only on clock names while leaving reset names as docs-only claims.
- Wording note preserved:
  - the synchronous rejected example now uses `reset` instead of `reset_n`,
  - because `_n` implies active-low naming and was misleading in the synchronous case.
## 2026-03-16: malformed `+system` entry structures now have full coverage
- [t/79-language-contract-system-section-structure-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/79-language-contract-system-section-structure-boundary.t) now locks:
  - scalar entries like `BROKEN` inside `(+system ...)`,
  - and wrong-arity entries like `(clock clk extra)`.
- Those malformed `+system` structures are now covered through direct parser checks plus pipeline and CLI no-output behavior, so the conventional `+system` family is no longer fully explicit only on names/directives/incompleteness/duplicates.
## 2026-03-16: malformed symbol-definition token cases now have full coverage
- [t/78-language-contract-symbol-definition-token-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/78-language-contract-symbol-definition-token-boundary.t) now locks:
  - bad identifiers in `+constants`, `+define`, and `+params`,
  - and non-scalar member values in `+enums`.
- Those token-validity failures are now covered through direct parser checks plus pipeline and CLI no-output behavior, so the symbol-definition family is no longer fully end-to-end only on the malformed-shape side.
## 2026-03-16: malformed ordinary RHS expression forms now have full entrypoint coverage
- [t/77-language-contract-expression-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/77-language-contract-expression-entrypoints.t) now locks pipeline and CLI no-output behavior for malformed ordinary RHS expressions:
  - unsupported operators such as `(bogus B C)`,
  - malformed active-operator arity such as `(== B)`,
  - and guard-only tokens such as `<start` in ordinary RHS expression position.
- This closes the remaining end-to-end gap for the malformed ordinary-expression family that was already explicit at direct parser level.
## 2026-03-16: malformed symbol-definition sections now have full entrypoint coverage
- [t/76-language-contract-symbol-definition-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/76-language-contract-symbol-definition-entrypoints.t) now locks pipeline and CLI no-output behavior for malformed:
  - `+constants`,
  - `+define`,
  - and `+params`.
- This closes the remaining end-to-end gap inside the malformed symbol-definition family, which previously had deeper entrypoint coverage only for malformed `+enums`.
## 2026-03-16: inline compound modifiers now have an explicit active boundary
- The active assignment family now also records:
  - bare inline `(+=)` and `(-=)` forms are supported as delta-`1` variants,
  - malformed inline modifier payloads such as `(+= 2 3)` no longer truncate silently,
  - duplicate inline modifiers such as `(+= 2) (-= 1)` no longer fall through a bare-suffix error,
  - and [t/75-language-contract-inline-compound-modifier-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/75-language-contract-inline-compound-modifier-boundary.t) now locks parser, pipeline, and CLI behavior for that family.
## 2026-03-16: future `R11` conflict-detection note now records the naming split too
- The saved future shared-drive direction now also records:
  - per-value-source overlap signals such as `P_Q_multi_src_conflict`,
  - and whole-target overlap signals such as `P_multi_value_conflict`.
## 2026-03-16: future `R11` shared-drive notes now prefer assertion bits over default arbitration
- The future shared-datapath lane now records:
  - no default auto-resolution or auto-priority for same-target conflicts,
  - per-`(P, Q)` onehot0-style assertion bits over source enables such as `A_P_Q_en`, `B_P_Q_en`, and `C_P_Q_en`,
  - and whole-target `P` assertion bits that detect multiple value families becoming active in the same cycle.
## 2026-03-16: future `R11` reusable-DT and shared-drive notes were refined again
- The future reusable standalone-DT lane now also records:
  - `?dt:name` may contain any number of internal general DT blocks such as `(-foo ...)`,
  - `?fsm:name` always implicitly declares `clk` / `rst_n`,
  - `?dt:name` implicitly declares `clk` / `rst_n` only when at least one sequential assignment exists,
  - and standalone DT arbitration should be expressed through generated enable families rather than a blanket structural conflict ban.
- The future shared-datapath lane now also records:
  - same-target/same-value aggregation is a separate case from same-target/different-value conflict,
  - and multiple FSMs must not drive different values to the same target `P` in the same cycle unless a later explicit priority contract is introduced.
## 2026-03-16: future `R11` now also includes a reusable standalone-DT/module-library lane
- [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) now records a second concrete future `R11` composition direction beyond shared datapath extraction.
- Saved direction:
  - add `?dt:name` as the smallest standalone module description,
  - allow `?dt:name` to mix combinational outputs and sequential outputs in the same standalone DT module,
  - keep the semantic split from `?fsm:name` about control model rather than output kind,
  - keep `?top:name` as the explicit composition-root concept unless a later family-level decision introduces aliases such as `?mod:name` or `?module:name`,
  - and grow reusable-source lookup through existing `FSMLIB` semantics plus repeatable per-invocation `--path DIR` roots.
- Open questions intentionally preserved in the roadmap/design notes:
  - whether unnamed reusable DT roots such as `?dt:` should exist at all,
  - how standalone DT interfaces are declared/exposed,
  - and how lookup precedence/diagnostics work across explicit paths, `--path`, `FSMLIB`, and local files.
## 2026-03-16: implicit no-`+system` generation now defaults to `clk` / `rst_n`
- The effective system contract is now centralized at module level instead of being hardcoded separately in multiple generation paths.
- Saved rule:
  - if explicit conventional `+system` is present, generation keeps the declared `clk` / `rstn` pair,
  - if `+system` is absent, generation defaults to implicit `clk` / asynchronous active-low `rst_n`.
- The sweep updated:
  - [perl/FSM/CoreAST.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/CoreAST.pm) for the shared effective-system accessor,
  - [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm) and [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm) for emitted HDL/reset naming,
  - and [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so composition child interfaces and auto-wiring follow the effective child system ports too.
- [t/74-language-contract-implicit-system-defaults.t](/Users/richarddje/Documents/github/fsmgen/t/74-language-contract-implicit-system-defaults.t) now locks the standalone implicit-default path, explicit `+system` override path, and single-child composition realization path.
## 2026-03-16: duplicate `+system` declarations are now locked explicitly
- [t/73-language-contract-system-section-duplicate-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/73-language-contract-system-section-duplicate-boundary.t) now locks the duplicate-declaration side of the conventional `+system` family:
  - duplicate `(clock clk)` entries are rejected,
  - duplicate reset declarations are rejected,
  - and mixed `(sreset rstn)` plus `(asreset rstn)` is also rejected as a duplicate reset declaration.
- This is mostly a regression/doc slice: parser behavior was already correct, but the contract now says plainly that `+system` means exactly one clock declaration plus exactly one reset declaration.
## 2026-03-16: future `R11` now includes a concrete shared-datapath composition lane
- [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) now treats the previously discussed multi-FSM shared-datapath idea as a concrete future `R11` sub-lane instead of an informal architecture note.
- The saved direction is:
  - one generated top may be built from one `.fsm` source or several `.fsm` sources,
  - some child outputs remain directly child-owned,
  - only outputs assigned in at least two child FSMs are candidates to be lifted into one shared datapath block instantiated by the generated top,
  - outputs assigned in only one child FSM are not shared and stay directly child-owned,
  - outputs from child FSMs or the shared datapath block are top-level outputs by default,
  - peer-read registered outputs become top-internal by default unless the user explicitly asks to re-export them,
  - per-child drive-intent enables should be surfaced deterministically (for example `A_P_Q_en`) and aggregated in the shared block/top,
  - lifted registered outputs may loop back into child FSM inputs,
  - and combinational outputs must not become peer-FSM read sources.
- [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) now reflects that `R11` deliverable/left/exit shape explicitly, and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) now records the same design rules in narrative form.
## 2026-03-15: malformed `+system` boundaries are now locked across entry points
- [t/72-language-contract-system-section-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/72-language-contract-system-section-entrypoints.t) now locks pipeline and CLI no-output behavior for:
  - non-conventional `+system` clock names like `(clock core_clk)`,
  - unsupported `+system` entries like `(areset rstn)`,
  - and incomplete `+system` sections.
- This is a regression-only hardening slice: parser behavior was already correct, but the malformed side of the conventional `+system` family is now covered end to end instead of only at direct parser level.
## 2026-03-15: legacy generic/template placeholder boundaries are now locked across entry points
- [t/71-language-contract-generic-placeholder-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/71-language-contract-generic-placeholder-entrypoints.t) now locks pipeline and CLI no-output behavior for:
  - legacy placeholder selectors such as `?[READ]`,
  - legacy repeat macros such as `?repeat:[MAX_COUNT]`,
  - and legacy placeholder tokens such as `[DATAIN]`.
- This is a regression-only hardening slice: parser behavior was already correct, but the legacy generic/template placeholder family is now covered end to end instead of only at direct parser level.
## 2026-03-15: unsupported top-level `+...` directive boundaries are now locked across entry points
- [t/70-language-contract-top-level-directive-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/70-language-contract-top-level-directive-entrypoints.t) now locks pipeline and CLI no-output behavior for:
  - unknown top-level `+` directives like `(+bogus ...)`,
  - and unsupported future-style top-level directives like `(+clock clk)`.
- This is a regression-only hardening slice: parser behavior was already correct, but the unsupported top-level `+...` directive family is now covered end to end instead of only at direct parser level.
## 2026-03-15: malformed test-selector boundaries are now locked across entry points
- [t/69-language-contract-test-selector-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/69-language-contract-test-selector-entrypoints.t) now locks pipeline and CLI no-output behavior for:
  - bare symbolic test selectors like `(BUSY ...)`,
  - and bare numeric test selectors like `(0 ...)`.
- This is a regression-only hardening slice: parser behavior was already correct, but the malformed test-selector family is now covered end to end instead of only at direct parser level.
## 2026-03-15: malformed test-branch boundaries are now locked across entry points
- [t/68-language-contract-test-branch-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/68-language-contract-test-branch-entrypoints.t) now locks pipeline and CLI no-output behavior for:
  - empty test-node branches like `(?MODE (=0))`,
  - and single malformed test-branch bodies that still omit a nested action.
- This is a regression-only hardening slice: parser behavior was already correct, but the malformed test-branch family is now covered end to end instead of only at direct parser level.
## 2026-03-15: bare condition-suffix boundaries are now locked across entry points
- [t/67-language-contract-condition-suffix-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/67-language-contract-condition-suffix-entrypoints.t) now locks pipeline and CLI no-output behavior for:
  - bare assignment condition suffixes like `(A <= B start)`,
  - and bare transition condition suffixes like `(-> busy full)`.
- This is a regression-only hardening slice: parser behavior was already correct, but the malformed bare-suffix family is now covered end to end instead of only at direct parser level.
## 2026-03-15: malformed action-family boundaries are now locked across entry points
- [t/66-language-contract-malformed-action-entrypoints.t](/Users/richarddje/Documents/github/fsmgen/t/66-language-contract-malformed-action-entrypoints.t) now locks pipeline and CLI no-output behavior for:
  - single-token malformed DT actions like `(BROKEN)`,
  - and empty guarded blocks like `(<req)`.
- This is a regression-only hardening slice: parser behavior was already correct, but the malformed-action family is now covered end to end instead of only at direct parser level.
## 2026-03-15: malformed legacy `+fsm` root bodies are now locked explicitly
- [t/65-language-contract-plus-fsm-body-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/65-language-contract-plus-fsm-body-boundary.t) now locks the malformed-body side of the legacy `+fsm` root family directly:
  - empty `(+fsm plus_empty)` roots are rejected,
  - scalar body items like `(+fsm plus_scalar BROKEN)` are rejected,
  - and pipeline/CLI do not emit HDL for those malformed legacy roots.
- [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now states that legacy `+fsm` roots must carry real sibling or nested body content instead of an empty or scalar payload.
## 2026-03-15: malformed structured `?fsm` root bodies now fail early through an explicit boundary
- [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now requires structured `?fsm:name` roots to carry a non-empty top-level item list and rejects scalar top-level body items explicitly.
- [t/64-language-contract-fsm-root-body-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/64-language-contract-fsm-root-body-boundary.t) now locks:
  - explicit rejection of `(?fsm:empty_root)`,
  - explicit rejection of `(?fsm:scalar_root BROKEN)`,
  - and pipeline/CLI no-output behavior for malformed structured root bodies.
- [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now states that structured `?fsm:name` roots must contain a real top-level item list rather than an empty or scalar payload.
## 2026-03-15: bare top-level FSM content now fails early through an explicit source-root boundary
- [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now turns unwrapped top-level FSM content into a dedicated source-root diagnostic instead of the old generic “expected `?fsm:name` or `+fsm`” parser error.
- [t/63-language-contract-source-root-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/63-language-contract-source-root-boundary.t) now locks:
  - explicit rejection of bare top-level forms like `(+system ...)` and `(idle ...)`,
  - classifier truth for files that remain outside active source kinds,
  - and pipeline/CLI no-output behavior for those malformed roots.
- [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now states that files must wrap FSM content in `?fsm:module_name` or the legacy `+fsm` root family instead of starting directly with sections or state/DT blocks.
## 2026-03-15: malformed update-shorthand tails now fail early through an explicit boundary
- [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now turns stray extra positional update-shorthand tails into a dedicated user-facing diagnostic instead of letting them fall through the generic suffix-guard boundary.
- [t/62-language-contract-update-shorthand-tail-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/62-language-contract-update-shorthand-tail-boundary.t) now locks:
  - continued support for guarded forms like `(+= counter 4 <start)`,
  - explicit rejection of malformed tails like `(+= counter 4 3)` and `(+= counter 4 3 2)`,
  - and pipeline/CLI no-output behavior for those malformed forms.
- [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now states that update shorthand accepts only an optional delta plus an explicit guard suffix after that.
## 2026-03-15: malformed update-shorthand targets now fail early instead of disappearing silently
- [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now turns malformed update-shorthand targets into a dedicated user-facing diagnostic instead of returning `undef` for recognized update-shorthand forms.
- [t/61-language-contract-update-shorthand-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/61-language-contract-update-shorthand-boundary.t) now locks:
  - malformed targets such as `(++ (counter))` and `(+= (byte_count) 4)`,
  - and pipeline/CLI no-output behavior for malformed update-shorthand forms.
- [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now states that update shorthand must target a scalar signal name and that malformed nested targets are rejected explicitly.
## 2026-03-15: alternate update-shorthand spellings are now explicitly documented and regression-backed
- [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents the full active update-shorthand family more honestly:
  - `(++ sig)` / `(-- sig)`,
  - `(+= sig)` / `(-= sig)`,
  - `(+=N sig)` / `(-=N sig)`,
  - `(+= sig N)` / `(-= sig N)`.
- [t/60-language-contract-update-shorthand-variants.t](/Users/richarddje/Documents/github/fsmgen/t/60-language-contract-update-shorthand-variants.t) now locks the separated delta-`1` and separated delta-carrying variants directly, including HDL generation through the active backend.
- [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) now records those alternate spellings as part of the active `R8` update-shorthand contract instead of leaving them as undocumented parser behavior.
## 2026-03-15: unsupported assignment operators now fail early through an explicit boundary
- [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now turns unsupported assignment operators into a dedicated user-facing assignment-operator diagnostic instead of a raw internal parser `confess`.
- [t/59-language-contract-assignment-operator-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/59-language-contract-assignment-operator-boundary.t) now locks:
  - unsupported operators such as `?=` and `=>`,
  - and pipeline/CLI no-output behavior for malformed assignment forms.
- [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now states the active assignment-operator family explicitly and documents rejection of unsupported operators.
## 2026-03-15: malformed guard shorthand and inline comparison tokens now fail early through explicit boundaries
- [perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm) now turns malformed guard shorthand payloads and malformed inline comparison tokens into their dedicated contract diagnostics instead of generic unsupported-expression-token errors.
- [t/58-language-contract-condition-expression-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/58-language-contract-condition-expression-boundary.t) now locks:
  - malformed guard shorthand payloads such as `mode=` and `==3`,
  - malformed inline comparison tokens such as `cnt[2:1]!=` and `=3`,
  - and pipeline/CLI no-output behavior for both malformed families.
- [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents both malformed boundaries explicitly in the active contract section.

## 2026-03-15: malformed delayed-pulse RHS values now fail early through a contract boundary
- [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now turns malformed delayed-pulse `<N` RHS values into a clean user-facing contract diagnostic instead of raw internal parser messages.
- [t/57-language-contract-pulse-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/57-language-contract-pulse-boundary.t) now locks:
  - malformed delayed-pulse RHS values such as `B` and `2'0`,
  - and pipeline/CLI no-output behavior for malformed delayed-pulse assignments.
- [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now states that malformed delayed-pulse RHS values are rejected explicitly.
## Purpose
- Preserve the minimum complete context needed to resume work immediately.
- Capture key technical decisions and current implementation status.
- Reference canonical docs for deeper details instead of duplicating everything.
- Use `ROADMAP_STATUS.md` as the canonical live board for what is done versus what is left.
## Non-negotiable workflow (user requirement)
After each completed task, always do this in order:
1. Update `MEMORY.md` with new state and next actionable direction.
2. Update `ROADMAP_STATUS.md` if the completed task changes roadmap status, roadmap deliverables, remaining work, or the current active lane.
3. If live status changed, log that status change in `CHANGES.md`.
4. Update other live docs as needed (`DEVELOPMENT_NOTES.md`, and any user-facing docs impacted by the change).
5. Display the current live status snapshot in the user-facing close-out every time the commit workflow runs.
6. If live status changed, explicitly state how the completed task changed the snapshot; if it did not change, explicitly state that the snapshot is unchanged for this task.
7. In that snapshot, show every `Rj` with at least `Status` + brief `Description`; add brief sub-bullets for the active lane or changed lane when helpful.
8. Run validation for the task scope (syntax checks + regression tests when applicable).
9. Run commit workflow:
   - write `git_message_brief.txt`
   - commit with `git commit -F git_message_brief.txt`
   - include `Co-Authored-By: Oz <oz-agent@warp.dev>`
   - clear `git_message_brief.txt` after commit (`truncate -s 0 git_message_brief.txt`)
## 2026-03-15: plain `?SIG` test-node names now fail early if malformed
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now validates the signal name in plain `?SIG` test nodes explicitly,
  - [t/54-language-contract-test-signal-name-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/54-language-contract-test-signal-name-boundary.t) now locks valid plain-`?SIG` behavior plus malformed-name rejection through parser, pipeline, and CLI,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents the distinction between plain `?SIG` and computed `?(expr)` explicitly.
- Scope of the landed contract slice:
  - explicit support remains for plain `?SIG` with HDL-identifier-compatible signal names,
  - explicit support remains for computed selectors `?(expr)`,
  - explicit rejection now covers malformed plain test-node signal names like `?bad-name` and `?0`.
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more test-node family boundary as fully bucketed.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible language edges,
  - and keep aligning every accepted construct with an explicit source-level contract.
## 2026-03-15: transition targets now fail early if malformed or undeclared
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now validates transition target spelling while parsing `->` and validates declared-target membership after the FSM is fully parsed,
  - [t/53-language-contract-transition-target-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/53-language-contract-transition-target-boundary.t) now locks valid forward-reference transitions plus malformed/unknown target rejection through parser, pipeline, and CLI entry points,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents the transition-target rule directly.
- Scope of the landed contract slice:
  - explicit support remains for transitions to declared regular FSM-state DT blocks,
  - explicit rejection now covers malformed target names like `bad-name`,
  - explicit rejection now covers non-state targets like `-comb`,
  - explicit rejection now covers undeclared targets like `missing_state`.
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more control-flow construct family as fully bucketed.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible language edges,
  - and keep moving validation closer to the source-level construct boundary.
## 2026-03-15: state and DT block names now fail early if malformed
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now validates regular FSM-state DT names and general/combinational DT names explicitly,
  - [t/52-language-contract-state-name-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/52-language-contract-state-name-boundary.t) now locks valid-name success plus malformed-name rejection through parser, pipeline, and CLI entry points,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents the naming rule directly.
- Scope of the landed contract slice:
  - explicit support remains for regular FSM-state DT names like `state_0`,
  - explicit support remains for general/combinational DT names like `-comb_1`,
  - explicit rejection now covers malformed names like `bad-name`, `-bad-name`, and `--bad`.
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more source-visible construct family as fully bucketed.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible language edges,
  - and keep failing malformed constructs at the language boundary instead of later in HDL generation.
## 2026-03-15: malformed symbol-definition sections now fail explicitly
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now validates `+constants`, `+define`, `+params`, and `+enums` explicitly instead of relying on loose list unpacking,
  - [t/51-language-contract-symbol-definition-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/51-language-contract-symbol-definition-boundary.t) now locks empty-section rejection, malformed entry/member rejection, and pipeline/CLI rejection without HDL output,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents the section/entry shapes and malformed-boundary rules explicitly.
- Scope of the landed contract slice:
  - explicit support remains for the already documented symbol-definition family,
  - explicit rejection now covers empty sections and malformed payloads for `+constants`, `+define`, `+params`, and `+enums`,
  - and this family no longer relies on incidental AST/list-shape fallout to fail.
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more family as fully bucketed across both happy-path support and malformed-boundary rejection.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible language edges,
  - and keep turning accidental parser tolerance into either explicit support or explicit rejection.
## 2026-03-15: `+size` now has an explicit contract
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now parses `+size` through an explicit helper,
  - the legacy empty form `(+size)` remains supported as a no-op,
  - [t/50-language-contract-size-section-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/50-language-contract-size-section-boundary.t) now locks explicit rejection of malformed payloads, malformed entries, and non-positive widths,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents the `+size` boundary explicitly.
- Scope of the landed contract slice:
  - explicit support now includes the legacy empty `(+size)` no-op because it exists in the shipped corpus,
  - explicit support still includes regular `(signal width)` declarations,
  - explicit rejection now covers malformed `+size` payloads and malformed/non-positive entries.
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more directive-family boundary as explicitly documented and regression-backed.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible language edges,
  - and keep turning silent tolerated legacy no-ops into explicit support or explicit rejection.
## 2026-03-15: state/DT blocks now need a real body
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now rejects empty state/DT blocks instead of building empty pseudo-states,
  - [t/49-language-contract-state-body-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/49-language-contract-state-body-boundary.t) now locks parser, pipeline, and CLI behavior for empty FSM-state DT blocks and empty general DT blocks,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now states that state/DT blocks must contain a real body.
- Scope of the landed contract slice:
  - explicit support still includes FSM-state DT blocks and general/combinational DT blocks,
  - explicit rejection now covers empty blocks like `(idle)` and `(-misc)`,
  - and malformed empty pseudo-states no longer drift through to later runtime stages.
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more parser-visible block-shape boundary as explicitly documented and regression-backed.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible language edges,
  - and keep replacing silent fallthrough behavior with explicit contract diagnostics.
## 2026-03-15: general/combinational DT blocks now carry explicit standalone classification
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/CoreAST.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/CoreAST.pm) now exposes `is_standalone_dt` on `FSM::CoreAST::State` and treats general/combinational DTs as an explicit state-role family,
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now classifies hyphen-prefixed non-reset DT blocks as `state_type => standalone_dt`,
  - [t/48-language-contract-standalone-dt-classification.t](/Users/richarddje/Documents/github/fsmgen/t/48-language-contract-standalone-dt-classification.t) now locks AST classification plus non-encoding/DT-enable behavior,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now states the standalone DT role explicitly.
- Scope of the landed contract slice:
  - explicit support now includes a real AST/runtime distinction between FSM-state DTs and general/combinational standalone DT blocks,
  - standalone DT blocks now stay out of the encoded-state plan by explicit role classification, not only by name heuristics,
  - and they continue to use DT-style enables instead of joining the `current_state` family.
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more formerly implicit DT-role boundary as explicitly documented and regression-backed.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible language edges,
  - and keep replacing naming-heuristic behavior with explicit construct-role contracts where the language model already expects them.
## 2026-03-15: tagged source-name boundary is now explicit
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now validates top-level `?fsm:module_name` roots as a whole,
  - [perl/FSM/Composition/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Composition/Parser.pm) now validates top-level `?top:top_name` roots and embedded `?fsm:source_name` child sources as a whole,
  - [t/47-language-contract-source-name-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/47-language-contract-source-name-boundary.t) now locks the malformed-name boundary for all three paths,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now states that tagged source names must be HDL-identifier-compatible.
- Scope of the landed contract slice:
  - explicit support now includes whole-name validation for tagged FSM/composition roots,
  - explicit rejection now covers malformed tagged names like `?fsm:bad-name` and `?top:bad-name`,
  - and malformed embedded composition child source names no longer truncate silently.
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more source-boundary family as explicitly documented and regression-backed.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible language edges,
  - and keep replacing implicit parser truncation/fallthrough behavior with explicit contract boundaries.
## 2026-03-15: legacy `+fsm` root contract is now explicit
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now validates the legacy `+fsm` source family before decoding the module name,
  - [t/46-language-contract-flat-plus-fsm-root.t](/Users/richarddje/Documents/github/fsmgen/t/46-language-contract-flat-plus-fsm-root.t) now locks both shipped legacy `+fsm` layouts plus explicit rejection of malformed `+fsm` roots,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now states the two active legacy layouts truthfully.
- Scope of the landed contract slice:
  - explicit support now includes the real shipped legacy `+fsm` family as a regression-backed active source kind,
  - explicit rejection now covers malformed `+fsm` roots that omit the scalar module name.
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more documented legacy source form as an explicit supported-or-rejected contract boundary.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible language edges,
  - and keep replacing under-validated legacy compatibility paths with explicit contract checks.
## 2026-03-15: DT-versus-state wording is now clarified
- Current worktree is a terminology-only follow-up:
  - [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now says both syntaxes are decision trees,
  - a regular named block like `(aState ...)` is an FSM-state DT,
  - and a hyphen-prefixed top-level block like `(-foobar ...)` is a general/combinational DT block.
- Scope of the clarification:
  - no runtime behavior changed,
  - the goal is to keep user-facing wording aligned with the intended language model.
- Roadmap board update:
  - no phase status changed,
  - the live roadmap snapshot is unchanged for this task.
- Immediate next direction after commit:
  - keep `R8` active,
  - keep tightening the language contract,
  - and keep the terminology in the docs as precise as the behavior.
## 2026-03-15: reset-state spelling and classification contract is now live
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/CoreAST.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/CoreAST.pm) now preserves `state_type` on `FSM::CoreAST::State` and exposes `state_type`, `is_reset_state`, and `is_regular_state`,
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now treats `-syncrst` / `-syncreset` and `-asyncrst` / `-asyncreset` as the same two reset-state families,
  - [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm), [perl/FSM/HDL/FlattenedDT/Orchestrator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Orchestrator.pm), and [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) now keep reset-state blocks out of the regular encoded-state set and treat them as DT-like blocks,
  - [t/45-language-contract-reset-state-spellings.t](/Users/richarddje/Documents/github/fsmgen/t/45-language-contract-reset-state-spellings.t) now locks spelling normalization, non-encoding of reset blocks, and DT-style enable emission,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents the reset-state family as a real supported contract.
- Scope of the landed contract slice:
  - explicit support now includes both short and long reset-state spellings,
  - reset-state blocks now normalize to shared internal identities (`syncreset` / `asyncreset`),
  - and reset-state blocks are no longer treated as ordinary encoded `current_state` states.
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more formerly accidental parser/runtime edge as an explicit supported construct family.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible language edges,
  - and keep converting accidental behavior into either regression-backed support or explicit rejection.
## 2026-03-15: n-ary relational operator contract is now executable
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm) now supports n-ary relational chains such as `(< low mid high)` and `(== a b c d)`, relational aliases such as `eq`, `ne`, `lt`, `le`, `gt`, and `ge`, and unary alias `not`,
  - [perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm) now walks the driving AST of parser-created intermediate expression signals during signal-role analysis, so underlying source inputs stay live in generated module interfaces,
  - [t/44-language-contract-relational-operators.t](/Users/richarddje/Documents/github/fsmgen/t/44-language-contract-relational-operators.t) now locks the new relational/operator contract slice end to end,
  - [t/40-language-contract-expression-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/40-language-contract-expression-boundary.t) now keeps malformed-arity rejection aligned with the broader operator contract by rejecting `(== a)`,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents the broader operator family truthfully.
- Scope of the landed contract slice:
  - explicit support now includes chained adjacent-pair relational lowering for `==`, `!=`, `<`, `<=`, `>`, and `>=`,
  - explicit support now includes word aliases `not`, `eq`, `ne`, `lt`, `le`, `gt`, `ge`, `add`, `sub`, `mul`, `div`, `mod`, `and`, `or`, and `xor`,
  - explicit rejection now covers malformed supported-operator arity against that broader contract instead of pretending chained comparisons are unsupported.
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more adopted operator family as regression-backed and normatively documented.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible language edges,
  - and either promote them with focused regressions or reject them explicitly.
## 2026-03-15: unsupported top-level bare forms now fail explicitly
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now rejects unsupported top-level bare forms inside `(?fsm:name ...)` instead of skipping them silently,
  - [t/43-language-contract-top-level-form-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/43-language-contract-top-level-form-boundary.t) now locks parser, pipeline, and CLI behavior for future-looking bare init syntax like `(tester_reset := 1)` and malformed bare scalar forms like `(BROKEN 1)`,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents those forms as explicitly out of active support.
- Scope of the landed contract slice:
  - explicit support remains limited to directive sections, `:=` init/reset directives, and state/DT blocks at the top level of `(?fsm:name ...)`
  - explicit rejection now covers unsupported bare top-level forms such as `(tester_reset := 1)` and `(BROKEN foo)`
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more silently-skipped legacy/malformed family as explicitly rejected instead.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible language edges,
  - and keep converting silent skips/fallbacks into explicit supported-or-rejected boundaries.
## 2026-03-15: test-node selectors now require explicit operator prefixes
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now validates test-branch selectors explicitly and rejects bare selectors like `BUSY` or `0`,
  - [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm) now enforces the same explicit-selector rule during runtime lowering,
  - [t/42-language-contract-test-selector-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/42-language-contract-test-selector-boundary.t) now locks parser/runtime support for explicit operator-prefixed selectors and rejection of malformed bare selectors,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents that active test-node selectors must be operator-prefixed tokens.
- Scope of the landed contract slice:
  - explicit support remains for selectors like `=0`, `=OTHER`, `!=8'0`, and `>8'3`
  - explicit rejection now covers bare selectors like `BUSY` and `0`
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more selector-boundary family as explicitly documented and regression-backed.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible language edges,
  - and keep tightening the contract where legacy permissiveness still leaks through.
## 2026-03-15: unsupported tagged top-level sources now fail explicitly
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now rejects unsupported tagged top-level source kinds such as `?define:legacy_template` before any nested `?fsm` fallback can fire,
  - [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) now rejects the same boundary in the active pipeline and CLI path,
  - [t/41-language-contract-top-level-source-kind-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/41-language-contract-top-level-source-kind-boundary.t) now locks classifier, adapter, pipeline, and CLI behavior for that boundary,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents unsupported tagged top-level source roots explicitly.
- Scope of the landed contract slice:
  - explicit support remains limited to `?fsm:name`, `+fsm`, and `?top:name`
  - explicit rejection now covers unsupported tagged roots such as `?define:...`
  - nested live `?fsm` content inside an unsupported tagged root no longer makes that root parseable
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more top-level legacy wrapper family as explicitly rejected instead of ambiguously accepted.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible language edges,
  - and keep tightening the contract at the root/source and construct-family boundaries.
## 2026-03-15: unsupported expression forms now fail explicitly
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm) now parses real inline scalar comparison tokens such as `cnt[2:1]!=2'2` explicitly while rejecting unsupported expression operators, malformed active-operator arity, empty expression lists, unsupported payload types, and guard-only tokens in ordinary RHS expression position,
  - [t/40-language-contract-expression-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/40-language-contract-expression-boundary.t) now locks that rejection boundary directly,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents unsupported/malformed expression forms explicitly in the out-of-support bucket.
- Scope of the landed contract slice:
  - explicit support for inline scalar comparison tokens such as `cnt[2:1]!=2'2`
  - explicit rejection of unsupported RHS operators such as `(bogus B C)`
  - explicit rejection of malformed active-operator arity such as `(== B C D)`
  - explicit rejection of guard-only tokens such as `<start` when used in ordinary expression position
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more parser-visible legacy/fallthrough boundary as explicitly rejected instead of implicit.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing the remaining parser/runtime-visible language edges,
  - and keep making the current support boundary explicit construct family by construct family.
## 2026-03-15: shorthand guard comparisons are now part of the active contract
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm) now lowers the shorthand guard family explicitly for both guarded blocks and suffix guards,
  - [t/39-language-contract-guard-shorthand.t](/Users/richarddje/Documents/github/fsmgen/t/39-language-contract-guard-shorthand.t) now locks that family directly,
  - [t/29-language-contract-core-forms.t](/Users/richarddje/Documents/github/fsmgen/t/29-language-contract-core-forms.t) now expects explicit comparison ASTs for the simple `<foo` / `<!foo` cases,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents the shorthand family as part of the active contract instead of keeping it future-only.
- Scope of the landed contract slice:
  - explicit support for `(<foo ...)` as `foo != 0`
  - explicit support for `(<!foo ...)` as `foo == 0`
  - explicit support for inline comparison shorthand such as `(<foo==3 ...)`, `(<foo!=0 ...)`, and `(<foo<=3 ...)`
  - explicit support for the same shorthand family in suffix-guard position
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more saved design agreement as actively supported and regression-backed.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible legacy forms,
  - and keep promoting or rejecting each construct family explicitly with focused regressions.
## 2026-03-15: future placeholder syntax direction is now preserved
- Current task was design-history only, not a support-boundary change:
  - [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) now records the preferred future placeholder direction for any later generic/template lane.
- Saved conclusion from the discussion:
  - do not revive legacy `[VAR]` as the canonical placeholder form,
  - do not use `<VAR>` because `<...` is already core guard syntax,
  - prefer `$(VAR)` as the future canonical placeholder form,
  - and treat `$VAR` only as possible sugar over `$(VAR)` if a real generic/template lane ever exists.
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - and there is no active-contract expansion from this note alone.
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible legacy forms,
  - and keep separating active contract truth from future language-design ideas.
## 2026-03-15: legacy generic/template placeholders now fail explicitly
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now rejects placeholder selectors like `?[READ]` and repeat macros like `?repeat:[MAX_COUNT]` with targeted diagnostics,
  - [perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm) now rejects placeholder scalar tokens like `[DATAIN]` explicitly instead of registering them as ordinary signals,
  - [t/38-language-contract-generic-placeholder-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/38-language-contract-generic-placeholder-boundary.t) now locks that boundary,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents the whole placeholder/generic family as explicitly out of active support.
- Scope of the landed contract slice:
  - explicit rejection of placeholder selectors such as `?[READ]`
  - explicit rejection of legacy repeat-expansion macros such as `?repeat:[MAX_COUNT]`
  - explicit rejection of placeholder tokens such as `[DATAIN]` and `[?size: ...]`
- Design context preserved in [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md):
  - user clarified that `[READ]`-style forms act like generics to be populated later,
  - so they belong to a future generic/template lane, not the active `R8` support boundary.
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more parser-visible legacy family as explicitly rejected instead of ambiguously parser-visible.
- Validation for this slice:
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm`
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm`
  - `perl -I perl -c t/38-language-contract-generic-placeholder-boundary.t`
  - `prove -I perl t/38-language-contract-generic-placeholder-boundary.t`
  - `prove -I perl t`
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing the remaining parser/runtime-visible legacy forms,
  - and keep classifying each one into supported or explicitly rejected buckets.
## 2026-03-15: computed test selectors now synthesize real intermediate wires end to end
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm) now analyzes `?(expr)` selector-driving ASTs so selector source signals remain live in the generated interface,
  - [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm) now treats parser-created computed-selector signals marked as intermediate as real intermediates during dependency/filtering analysis,
  - [t/37-language-contract-computed-test-selector.t](/Users/richarddje/Documents/github/fsmgen/t/37-language-contract-computed-test-selector.t) now locks that end-to-end behavior,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents `?(expr)` as part of the active test-node contract.
- Scope of the landed contract slice:
  - explicit support for computed-selector test nodes such as `(?(| A B) (=0 ...) (=1 ...))`
  - explicit emission of the synthesized intermediate selector wire in generated HDL
  - explicit preservation of the computed selector's source signals as live interface inputs
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more real parser/runtime-visible test-node family as fully documented and regression-backed.
- Validation for this slice:
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm`
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c t/37-language-contract-computed-test-selector.t`
  - `prove -I perl t/12-enablegraph-capture-registry.t t/37-language-contract-computed-test-selector.t`
  - `prove -I perl t`
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser/runtime-visible legacy constructs,
  - and keep promoting or rejecting each construct family explicitly with focused regressions.
## 2026-03-15: `:=` init/reset directives are now explicit, and malformed DT actions fail explicitly
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now treats top-level `:=` as an explicit init/reset directive,
  - records reset/default metadata for the target signal,
  - and rejects malformed DT actions and empty guarded blocks instead of silently dropping them,
  - [t/34-language-contract-malformed-actions.t](/Users/richarddje/Documents/github/fsmgen/t/34-language-contract-malformed-actions.t) now locks that boundary,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents both the active `:=` contract and the malformed-form rejection boundary explicitly.
- Scope of the landed contract slice:
  - explicit support for top-level compact init/reset directives such as `(:= tester_reset=1)`
  - explicit rejection of malformed single-token DT actions such as `(BROKEN)`
  - explicit rejection of empty guarded blocks such as `(<req)`
  - saved future-syntax note in [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md):
    - possible canonical future form `(:= (lhs value))`
    - and possible sugar form `(lhs := value)`
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records that the active contract includes top-level `:=` and one less silent parser-drop behavior in the DT action family.
- Validation for this slice:
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm`
  - `perl -I perl -c t/34-language-contract-malformed-actions.t`
  - `prove -I perl t/34-language-contract-malformed-actions.t`
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser-visible implicit fallthroughs,
  - and keep turning them into either supported or explicitly rejected behavior.
## 2026-03-15: malformed empty test-node branches now fail explicitly
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now emits a targeted malformed-test-branch diagnostic for empty `?sig` branches,
  - [t/35-language-contract-test-branch-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/35-language-contract-test-branch-boundary.t) now locks that boundary,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now says explicitly that each test-node branch needs a selector plus at least one nested action.
- Scope of the landed contract slice:
  - explicit rejection of empty test branches such as `(?MODE (=0))`
  - explicit rejection of mixed test nodes where one branch is valid and another branch is empty
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one less generic parser-failure path in the test-node family.
- Validation for this slice:
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm`
  - `perl -I perl -c t/35-language-contract-test-branch-boundary.t`
  - `prove -I perl t/35-language-contract-test-branch-boundary.t`
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser-visible legacy constructs,
  - and keep replacing generic parser artifacts with supported or explicitly rejected behavior.
## 2026-03-15: relational test-node selectors are now explicit and regression-backed
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Synthesis/EnableGraph.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Synthesis/EnableGraph.pm) now lowers relational `?sig` selectors using their actual operators instead of collapsing them to equality,
  - [t/36-language-contract-test-branch-selectors.t](/Users/richarddje/Documents/github/fsmgen/t/36-language-contract-test-branch-selectors.t) now locks captured AST and emitted-HDL behavior for `!=`, `>`, and `<=`,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents the broader active selector family explicitly.
- Scope of the landed contract slice:
  - explicit support for exact and relational `?sig` selectors such as `=0`, `!=8'0`, `>8'3`, and `<=8'3`
  - removal of the incorrect equality-only lowering in the active generation path
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one more parser/runtime-visible language family as regression-backed and truthfully documented.
- Validation for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c t/36-language-contract-test-branch-selectors.t`
  - `prove -I perl t/36-language-contract-test-branch-selectors.t`
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing remaining parser-visible legacy constructs and underspecified live behavior,
  - and keep promoting or rejecting each family explicitly.
## 2026-03-15: bare condition suffixes now fail explicitly
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now rejects bare suffix tails in assignment/transition suffix positions,
  - [t/33-language-contract-condition-suffix-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/33-language-contract-condition-suffix-boundary.t) now locks that boundary,
  - and [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now states that suffix guards must use explicit `<...` / `<!...` forms.
- Scope of the landed contract slice:
  - explicit rejection of malformed bare suffixes such as `(A <= B start)`
  - explicit rejection of malformed bare transition tails such as `(-> busy full)`
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` now records one less implicit parser-accepted legacy path in the guard family.
- Validation for this slice:
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm`
  - `perl -I perl -c t/33-language-contract-condition-suffix-boundary.t`
  - `prove -I perl t/33-language-contract-condition-suffix-boundary.t`
- Immediate next direction after commit:
  - keep `R8` active,
  - continue auditing the remaining non-directive parser-visible legacy constructs,
  - and keep shrinking implicit acceptance paths into either supported or explicitly rejected behavior.
## 2026-03-15: unsupported top-level `+...` directives now fail explicitly
- Current worktree is the next `R8` implementation slice:
  - [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now rejects unsupported top-level `+...` directive sections explicitly instead of parsing them as fake states,
  - [t/32-language-contract-top-level-directive-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/32-language-contract-top-level-directive-boundary.t) now locks that boundary,
  - and [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) now preserves the syntax-namespace rationale from the latest language-design discussion.
- Scope of the landed contract slice:
  - explicit rejection of unknown top-level directive sections such as `(+bogus ...)`
  - explicit rejection of future-looking but currently unsupported directive spellings such as `(+clock clk)`
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` and `ROADMAP_V2.md` now record that unsupported top-level `+...` directives are no longer in an ambiguous parser-accepted bucket.
- Validation for this slice:
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm`
  - `perl -I perl -c t/32-language-contract-top-level-directive-boundary.t`
  - `prove -I perl t/32-language-contract-top-level-directive-boundary.t`
- Immediate next direction after commit:
  - keep `R8` active,
  - audit the remaining non-directive parser-visible legacy constructs that still lack a clean support-tier bucket,
  - then continue tightening the normative reference and regressions family by family.
## 2026-03-15: conventional `+system` contract slice is landed under `R8`
- Current worktree is the next `R8` implementation slice:
  - [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now treats the conventional `+system` declaration as fully supported and documents its normative contract,
  - [t/31-language-contract-system-section.t](/Users/richarddje/Documents/github/fsmgen/t/31-language-contract-system-section.t) now locks the active accepted/rejected boundary,
  - and [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now validates `+system` explicitly instead of silently ignoring it.
- Scope of the landed contract slice:
  - accepted conventional shared-system declaration:
    - `(+system (clock clk) (sreset rstn))`
    - `(+system (clock clk) (asreset rstn))`
  - explicit rejection of:
    - alternative clock names,
    - unsupported system directives,
    - and incomplete `+system` sections
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` and `ROADMAP_V2.md` now record that the conventional `+system` boundary moved into the supported, regression-backed contract.
- Validation for this slice:
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm`
  - `perl -I perl -c t/31-language-contract-system-section.t`
  - `prove -I perl t/31-language-contract-system-section.t`
- Immediate next direction after commit:
  - keep `R8` active,
  - audit the remaining parser-visible legacy constructs that still lack a clean support-tier bucket,
  - then continue tightening the normative reference and regressions family by family.
## 2026-03-15: symbol-definition contract slice is landed under `R8`
- Current worktree is the second real `R8` implementation slice:
  - [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now treats the symbol-definition families as fully supported and documents their current normative contract,
  - [t/30-language-contract-symbol-definitions.t](/Users/richarddje/Documents/github/fsmgen/t/30-language-contract-symbol-definitions.t) now locks the active behavior,
  - and [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now unwraps packed scalar tokens correctly for symbol-definition parsing.
- Scope of the landed contract slice:
  - `(+constants ...)`
  - `(+enums ...)`
  - `(+define ...)`
  - `(+params ...)`
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` and `ROADMAP_V2.md` now record that symbol-definition sections moved into the supported, regression-backed contract.
- Validation for this slice:
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm`
  - `perl -I perl -c t/30-language-contract-symbol-definitions.t`
  - `prove -I perl t/30-language-contract-symbol-definitions.t`
- Immediate next direction after commit:
  - keep `R8` active,
  - resolve the remaining `(+system ...)` semantics beyond the conventional `clk` / `rstn` path,
  - then continue bucketing any remaining parser-visible legacy constructs with focused regressions.
## 2026-03-14: first `R8` contract-hardening slice is landed
- Current worktree is the first real `R8` implementation slice:
  - the first draft normative language-contract section is now live in [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md),
  - focused regression coverage exists in [t/29-language-contract-core-forms.t](/Users/richarddje/Documents/github/fsmgen/t/29-language-contract-core-forms.t),
  - and two small warning-noise fixes landed in [perl/FSM/ExpressionNamer.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/ExpressionNamer.pm) and [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm).
- Scope of the landed contract slice:
  - nested guarded blocks,
  - condition suffixes,
  - compound update shorthand and inline compound modifiers,
  - and the currently regression-backed broader operator-expression families.
- Roadmap board update:
  - no phase status changed,
  - `R8` remains `in progress`,
  - but `ROADMAP_STATUS.md` and `ROADMAP_V2.md` now record that the first normative-contract/regression slice is complete.
- Validation for this slice:
  - `perl -I perl -c perl/FSM/ExpressionNamer.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/29-language-contract-core-forms.t`
- Immediate next direction after commit:
  - keep `R8` active,
  - resolve the remaining gray-zone families around `(+system ...)` and symbol-definition sections,
  - then continue contract-hardening regressions family by family.
## 2026-03-14: long-term horizon goals added to roadmap v2
- Current worktree is a doc-only roadmap-continuity slice adding explicit long-term horizon goals without changing the active priority order.
- Scope of this slice:
  - extended [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) with:
    - `H1` Rust FSMGen,
    - `H2` a beautiful, dynamic public project website,
  - recorded the gating rule that these are long-term goals only after FSMGen is first made state-of-the-art, rock solid, and really stable,
  - updated [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) to mention that horizon goals exist but are intentionally outside the active `R8`..`R14` lanes.
- Roadmap board update:
  - no roadmap status/deliverable/active-lane change for this slice,
  - the live roadmap snapshot remains unchanged.
- Validation is green for this slice:
  - `git diff --check`
- Immediate next direction after commit:
  - keep `R8` as the active lane,
  - treat the Rust implementation and public website as horizon goals, not near-term execution lanes.
## 2026-03-14: roadmap v2 is now active
- Current worktree is the roadmap-opening slice that turns the previously saved post-roadmap ideas into an actual second roadmap generation.
- Scope of this slice:
  - added [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) as the detailed companion roadmap for the post-`R0`..`R7` workstreams,
  - refreshed [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) so `v2` is now the active roadmap generation,
  - opened `R8` as the current active lane,
  - defined `R9` through `R14` as explicit follow-on workstreams,
  - updated [README.md](/Users/richarddje/Documents/github/fsmgen/README.md) so onboarding points to the new roadmap companion directly.
- Roadmap board update:
  - the active lane moved from `none` to `R8`,
  - `R8` is now `in progress`,
  - `R9` through `R14` now exist explicitly on the board and are `not started`.
- Validation is green for this slice:
  - `git diff --check`
- Immediate next direction after commit:
  - continue on `R8`,
  - first turn the saved guarded-block / suffix-guard / update-shorthand / operator-arity agreements into a draft normative language-reference section,
  - then classify the remaining unresolved `(+system ...)` and symbol-definition families.
## 2026-03-14: operator-form RHS design direction preserved
- Current worktree is a doc-only design-continuity slice saving the working direction for `(6)` operator-form RHS expressions.
- Scope of this slice:
  - saved in [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) that combinational and sequential assignments should share one RHS expression grammar,
  - saved that operator aliases should lower to canonical operators,
  - saved the broader agreement that infix-style operator families should be treated as unlimited-ary whenever their semantics can be defined deterministically,
  - saved natural unlimited-ary fold semantics for `+`, `*`, `&`, `|`, and `^`,
  - saved unary semantics for `!`,
  - saved left-associative unlimited-ary semantics for `-`, `/`, and `%`,
  - saved chained relational semantics as adjacent-pair conjunction, for example `(< a b c)` => `((a < b) && (b < c))`,
  - and saved the meta-rule that any allowed operator form must have an explicit unambiguous interpretation with examples.
- Roadmap board update:
  - no roadmap status/deliverable/active-lane change for this slice,
  - the live roadmap snapshot remains unchanged.
- Validation is green for this slice:
  - `git diff --check`
- Immediate next direction after commit:
  - no roadmap lane is active,
  - the next natural discussion is whether the operator-family contract above should be fully adopted as-is or narrowed before becoming normative.
## 2026-03-14: guarded-block and suffix-guard design agreements preserved
- Current worktree is a doc-only design-continuity slice saving the agreed semantics for future language-contract hardening.
- Scope of this slice:
  - saved in [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md) that guarded blocks `(3)` are first-class,
  - saved that guarded-block nesting is unlimited and composes by logical `AND`,
  - saved the sugar and shorthand rules:
    - `(<foo ...)` => `foo != 0`
    - `(<!foo ...)` => `foo == 0`
    - `(<foo==3 ...)` => guarded relational shorthand
  - saved that condition suffixes `(4)` have exactly the same semantics as guarded blocks and desugar to a guarded block around a single action,
  - saved the agreed increment/decrement semantics for update shorthand `(5)`.
- Roadmap board update:
  - no roadmap status/deliverable/active-lane change for this slice,
  - the live roadmap snapshot remains unchanged.
- Validation is green for this slice:
  - `git diff --check`
- Immediate next direction after commit:
  - no roadmap lane is active,
  - the next natural discussion is whether `(6)` broader arithmetic/operator forms should get an equally explicit semantic contract or be intentionally narrowed first.
## 2026-03-14: post-roadmap improvement priorities preserved for later roadmap work
- Current worktree is a doc-only continuity slice to save the suggested post-`R0`..`R7` improvement order before any new roadmap is opened.
- Scope of this slice:
  - saved the recommended next-workstream order in [DEVELOPMENT_NOTES.md](/Users/richarddje/Documents/github/fsmgen/DEVELOPMENT_NOTES.md),
  - preserved the specific gray-zone cluster that should be resolved first in any future language-contract hardening work,
  - kept those notes as future recommendations rather than reopening the closed current roadmap.
- Roadmap board update:
  - no roadmap status/deliverable/active-lane change for this slice,
  - the live roadmap snapshot remains unchanged.
- Validation is green for this slice:
  - `git diff --check`
- Immediate next direction after commit:
  - no roadmap lane is active,
  - the natural follow-up is discussion/brainstorming on the gray-zone constructs before deciding whether to open a new explicit roadmap.
## 2026-03-14: user-guide support boundary clarified for current `.fsm` language
- Current worktree is a doc-only clarification pass driven by the need to state the real active `.fsm` support boundary precisely.
- Scope of this slice:
  - expanded [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) with a live supported-constructs section,
  - separated:
    - fully supported constructs,
    - implemented-but-not-fully-regression-backed constructs,
    - and explicitly unsupported constructs,
  - clarified that standalone decision-tree blocks like `(-alpha_dt ...)`, `(-misc ...)`, and `(-mycombit ...)` are part of the active supported surface,
  - clarified the current runtime consequence of DT-only inputs: no state-register plan is synthesized when only standalone DT blocks are present,
  - tightened the guide wording so composition is described as a deliberately narrow shipped model instead of as merely "partially implemented".
- Roadmap board update:
  - no roadmap status/deliverable/active-lane change for this slice,
  - the live roadmap snapshot remains unchanged.
- Validation is green for this slice:
  - `git diff --check`
- Immediate next direction after commit:
  - no roadmap lane is active,
  - if follow-up work is wanted from this clarification, the most natural next slice is turning the same support boundary into a more formal language-reference table or opening a new explicit roadmap workstream.
## 2026-03-14: `R7` closed with the shipped source-frontier hook
- Current worktree finishes the bounded `R7` lane by adding the next small typed hook boundary instead of growing the loading surface further.
- Scope of this slice:
  - extended [perl/FSM/Extension/Context.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Context.pm) so hook contexts now carry `stage` and `raw_ast` where appropriate,
  - extended [perl/FSM/Extension/Registry.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Registry.pm) so the shipped typed hook set now includes `after_parse_source($context)` in addition to `after_generate_result($context)`,
  - updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so the new hook runs after parsing/classification and after composition IR parsing for top-level composition sources,
  - updated [t/26-extension-mechanism.t](/Users/richarddje/Documents/github/fsmgen/t/26-extension-mechanism.t), [t/lib/FSM/TestExtension/Marker.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/TestExtension/Marker.pm), and [t/27-extension-loading.t](/Users/richarddje/Documents/github/fsmgen/t/27-extension-loading.t) to lock the new hook boundary across direct, module-loaded, and CLI-loaded extension paths.
- Roadmap board update:
  - [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) now moves `R7` from `mostly done` to `done`,
  - the current active lane is now `none` because all currently defined roadmap workstreams `R0` through `R7` are complete,
  - any future continuation should open a new explicit workstream instead of stretching the closed current roadmap.
- Validation is green for this slice:
  - `perl -I perl -I t/lib -c perl/FSM/Extension/Context.pm`
  - `perl -I perl -I t/lib -c perl/FSM/Extension/Registry.pm`
  - `perl -I perl -I t/lib -c perl/FSM/Pipeline/HDLGenerator.pm`
  - `perl -I perl -I t/lib -c t/26-extension-mechanism.t`
  - `prove -I perl -I t/lib t/26-extension-mechanism.t t/27-extension-loading.t t/28-extension-config-loading.t`
  - `git diff --check`
- Immediate next direction after commit:
  - no blocking roadmap lane remains,
  - future work should start from a newly defined workstream if the project adds another objective beyond the closed `R0`..`R7` plan.
## 2026-03-14: `R7` shipped explicit extension-config loading
- Current worktree continues `R7` by adding the explicit config-file layer that was still left open after the object/module loading slices.
- Scope of this slice:
  - extended [perl/FSM/Extension/Loader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Loader.pm) so it can parse explicit extension-config files and report malformed lines with file/line context,
  - updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so callers may pass `extension_config_files => [ ... ]`,
  - updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) so repeated `--extension-config <file>` flags can load typed extensions from explicit config files,
  - added [t/28-extension-config-loading.t](/Users/richarddje/Documents/github/fsmgen/t/28-extension-config-loading.t) to lock loader, pipeline, and CLI config-file loading plus malformed-config diagnostics.
- Roadmap board update:
  - [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) now moves `R7` from `in progress` to `mostly done`,
  - the active lane remains `R7`,
  - the next decision point is now the next typed hook boundary, with constructor/config-parameter richness left as a later follow-up rather than a blocker on the current loading stack.
- Validation is green for this slice:
  - `perl -I perl -I t/lib -c perl/FSM/Extension/Loader.pm`
  - `perl -I perl -I t/lib -c perl/FSM/Pipeline/HDLGenerator.pm`
  - `perl -I perl -I t/lib -c bin/fsmgen`
  - `perl -I perl -I t/lib -c t/28-extension-config-loading.t`
  - `prove -I perl -I t/lib t/27-extension-loading.t t/28-extension-config-loading.t`
  - `git diff --check`
- Immediate next direction after commit:
  - continue `R7`,
  - choose the next small typed hook boundary in the active architecture,
  - keep any future loading/config growth explicit rather than drifting toward `.plg`-style discovery.
## 2026-03-14: `R7` shipped explicit typed extension loading
- Current worktree continues `R7` by widening the first typed extension seam from programmatic object injection into an explicit module-loading path that still stays well clear of `.plg` discovery.
- Scope of this slice:
  - added [perl/FSM/Extension/Loader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Loader.pm) to validate explicit module names, require them, instantiate them through `new()`, and reject non-object returns,
  - updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so callers may pass `extension_modules => [ ... ]` in addition to direct extension objects,
  - updated [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) so repeated `--extension-module Module::Name` flags now load typed extensions explicitly from `@INC`,
  - added [t/lib/FSM/TestExtension/Marker.pm](/Users/richarddje/Documents/github/fsmgen/t/lib/FSM/TestExtension/Marker.pm) and [t/27-extension-loading.t](/Users/richarddje/Documents/github/fsmgen/t/27-extension-loading.t) to lock loader, pipeline, and CLI behavior plus targeted missing-module diagnostics.
- Roadmap board update:
  - no phase status changed,
  - [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) still keeps `R7` at `in progress`,
  - `R7` `Done` / `Left` moved forward because explicit loading is no longer programmatic-only,
  - the next decision point is now whether to stay at programmatic-plus-CLI loading or add a config-file layer, and which typed hook boundary comes next.
- Validation is green for this slice:
  - `perl -I perl -I t/lib -c perl/FSM/Extension/Loader.pm`
  - `perl -I perl -I t/lib -c perl/FSM/Pipeline/HDLGenerator.pm`
  - `perl -I perl -I t/lib -c bin/fsmgen`
  - `perl -I perl -I t/lib -c t/27-extension-loading.t`
  - `prove -I perl -I t/lib t/26-extension-mechanism.t t/27-extension-loading.t`
  - `git diff --check`
- Immediate next direction after commit:
  - continue `R7`,
  - decide whether explicit loading needs a config-file layer beyond direct CLI/programmatic module names,
  - then add the next small typed hook boundary.
## 2026-03-14: typed-extension docs clarified with concrete examples
- Current worktree is a doc-only follow-up to the first shipped `R7` typed extension seam.
- Scope of this slice:
  - expanded [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) with a user-facing explanation of what a typed extension is,
  - added concrete examples for result annotation and telemetry collection through the shipped `after_generate_result($context)` hook,
  - clarified in [docs/EXTENSION_MODEL.md](/Users/richarddje/Documents/github/fsmgen/docs/EXTENSION_MODEL.md) what "typed" means in this project: explicit object + method + context, not `.plg` scanning plus string-dispatch.
- Roadmap board update:
  - no roadmap status/deliverable/active-lane change for this slice,
  - the live roadmap snapshot remains unchanged.
- Validation is green for this slice:
  - `git diff --check`
- Immediate next direction after commit:
  - continue `R7`,
  - decide whether extension loading stays programmatic-only for now or gains an explicit config/CLI path,
  - then land the next small typed hook boundary.
## 2026-03-14: `R7` started with the first typed extension seam
- Current worktree starts the active `R7` lane with one real typed hook in the live pipeline instead of a broad speculative plugin rewrite.
- Scope of this slice:
  - added [perl/FSM/Extension/Registry.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Registry.pm) and [perl/FSM/Extension/Context.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Context.pm) as the first typed extension primitives,
  - updated [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) so callers can pass `extensions => [ ... ]` and receive a live `after_generate_result($context)` callback for both FSM and composition generation paths,
  - added [docs/EXTENSION_MODEL.md](/Users/richarddje/Documents/github/fsmgen/docs/EXTENSION_MODEL.md) to define the first modern replacement boundary and its deliberate non-goals,
  - added [t/26-extension-mechanism.t](/Users/richarddje/Documents/github/fsmgen/t/26-extension-mechanism.t) to lock registry validation plus live hook dispatch across both supported source kinds.
- Roadmap board update:
  - [ROADMAP_STATUS.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_STATUS.md) now moves `R7` from `not started` to `in progress`,
  - the active lane remains `R7`,
  - the next decision point is now whether the next extension step stays programmatic-only or adds an explicit config/CLI loading path, and which typed hook boundary should come next.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Extension/Context.pm`
  - `perl -I perl -c perl/FSM/Extension/Registry.pm`
  - `perl -I perl -c perl/FSM/Pipeline/HDLGenerator.pm`
  - `perl -I perl -c t/26-extension-mechanism.t`
  - `prove -I perl t/26-extension-mechanism.t`
  - `git diff --check`
- Immediate next direction after commit:
  - continue `R7`,
  - decide whether to keep extension loading programmatic-only for now or add an explicit config/CLI path,
  - then land the next small typed hook boundary without reopening `.plg` / `PPlugin` semantics.
## 2026-03-14: `R6` shipped `C6` and closed the scoped composition lane
- Current worktree finishes the last bounded `R6` acceptance slice by making the remaining out-of-scope legacy composition shapes fail explicitly and consistently.
- Scope of this slice:
  - tightened `FSM::Composition::Parser` boundary messages for legacy macro/plugin children and the remaining reachable out-of-scope legacy parser shapes,
  - added `t/25-composition-legacy-scope-errors.t` to lock parser/pipeline/CLI behavior for those scope-boundary failures.
- Roadmap board update:
  - `ROADMAP_STATUS.md` now moves `R6` from `mostly done` to `done`,
  - the active lane moves from `R6` to `R7`,
  - the `.rtlif` follow-up remains recorded as a future refinement note, not an `R6` blocker.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Composition/Parser.pm`
  - `perl -I perl -c t/25-composition-legacy-scope-errors.t`
  - `prove -I perl t/25-composition-legacy-scope-errors.t`
  - `prove -I perl t/14-composition-parser.t t/13-composition-source-classification.t`
  - `prove -I perl t`
- Immediate next direction after commit:
  - continue on `R7`,
  - define the replacement typed hook/extension mechanism without reviving `.plg` / `PPlugin`.
## 2026-03-14: `R6` shipped `C5` width-mismatch diagnostics
- Current worktree tightens the composition diagnostic boundary rather than widening the language surface again.
- Scope of this slice:
  - explicit `?toplink` width mismatches are now locked by focused regression,
  - declared connect-by-name width mismatches now name both endpoints and both widths directly.
- Roadmap board update:
  - `ROADMAP_STATUS.md` now moves `R6` from `in progress` to `mostly done`,
  - the active lane remains `R6`,
  - the current next decision point is now `C6` explicit failure for out-of-scope legacy composition constructs,
  - the `.rtlif` follow-up remains recorded explicitly on the roadmap board.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Pipeline/HDLGenerator.pm`
  - `perl -I perl -c t/23-composition-errors.t`
  - `perl -I perl -c t/24-composition-connect-by-name.t`
  - `prove -I perl t/23-composition-errors.t t/24-composition-connect-by-name.t`
  - `prove -I perl t`
- Immediate next direction after commit:
  - continue `R6` with `C6`,
  - make remaining out-of-scope legacy composition constructs fail explicitly and consistently.
## 2026-03-14: user-guide clarification for realistic `=name` usage
- Current worktree is a doc-only follow-up to the shipped `C4` lane.
- Scope of this slice:
  - expanded `docs/USER_GUIDE.md` with realistic `=name` patterns rather than only a synthetic minimal example,
  - added one child-FSM output passthrough example, one child-input passthrough example, and one external-RTL output passthrough example,
  - added practical guidance about when to prefer `=name` versus explicit `?toplink`.
- Roadmap board update:
  - no roadmap status/deliverable/active-lane change for this slice,
  - the live roadmap snapshot remains unchanged.
- Validation is green for this slice:
  - `git diff --check`
- Immediate next direction after commit:
  - continue the active `R6` lane at `C5`,
  - tighten width-mismatch diagnostics across explicit and declared-by-name endpoints.
## 2026-03-14: `R6` first shipped `C4` declared connect-by-name lane
- Current worktree widens the shipped composition runtime from explicit-link-only lanes into the first declared connect-by-name slice.
- Scope of this slice:
  - typed composition ports now preserve explicit connect-by-name intent via `=name` declarations inside `?ports`,
  - `FSM::Pipeline::HDLGenerator` now recognizes a dedicated `C4` lane and synthesizes by-name links from those declarations,
  - the first shipped `C4` behavior is top-port only and requires exactly one same-named child endpoint with the same direction and width.
- Regression coverage update:
  - tightened `t/14-composition-parser.t` so `=port` parser shape and `binding_mode` preservation are now locked,
  - added `t/24-composition-connect-by-name.t` for the shipped `C4` success path plus ambiguous-match and no-match failures.
- Roadmap board update:
  - `ROADMAP_STATUS.md` still keeps `R6` at `in progress`,
  - `R6` `Done` now includes the first shipped `C4` declared connect-by-name slice,
  - the current next decision point is now `C5` width-mismatch diagnostics,
  - and the `.rtlif` follow-up is now recorded explicitly in the board so we do not forget to document exact grammar and revisit the stronger interface-source contract question later.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Composition/Port.pm`
  - `perl -I perl -c perl/FSM/Composition/Parser.pm`
  - `perl -I perl -c perl/FSM/Pipeline/HDLGenerator.pm`
  - `perl -I perl -c t/14-composition-parser.t`
  - `perl -I perl -c t/24-composition-connect-by-name.t`
  - `prove -I perl t/14-composition-parser.t t/20-composition-single-fsm-top.t t/21-composition-two-fsm-linking.t t/22-composition-fsm-plus-rtl.t t/23-composition-errors.t t/24-composition-connect-by-name.t`
  - `prove -I perl t`
- Immediate next direction after commit:
  - move to `C5`,
  - tighten width-mismatch diagnostics across explicit and declared-by-name endpoints.
## 2026-03-14: `R6` first shipped `C3` mixed FSM-plus-RTL lane
- Current worktree widens the shipped composition runtime from FSM-only linking into the first mixed external-RTL lane.
- Scope of this slice:
  - added `FSM::Composition::RTLInterfaceLoader` as the first modern external-RTL interface loader,
  - external RTL interface metadata now comes from a sidecar `<module>.rtlif` artifact searched beside the composition source and through existing `FSMLIB` roots,
  - updated `FSM::Pipeline::HDLGenerator` so `?rtl` children are realized instead of rejected and mixed `?fsmc` + `?rtl` tops plan through a dedicated `C3` lane,
  - kept the composition boundary truthful by instantiating the external RTL child without regenerating its internals.
- Regression coverage update:
  - added `t/22-composition-fsm-plus-rtl.t` for the shipped `C3` success path and CLI generation,
  - extended `t/23-composition-errors.t` so mixed composition now locks unknown external-port and direction-mismatch diagnostics as well as duplicate-driver rejection.
- Roadmap board update:
  - `ROADMAP_STATUS.md` still keeps `R6` at `in progress`,
  - `R6` `Done` now includes the first shipped `C3` mixed external-RTL lane,
  - the current next decision point is now `C4` declared connect-by-name, not more external-interface loading groundwork.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Composition/RTLInterfaceLoader.pm`
  - `perl -I perl -c perl/FSM/Pipeline/HDLGenerator.pm`
  - `perl -I perl -c t/22-composition-fsm-plus-rtl.t`
  - `perl -I perl -c t/23-composition-errors.t`
  - `prove -I perl t/20-composition-single-fsm-top.t t/21-composition-two-fsm-linking.t t/22-composition-fsm-plus-rtl.t t/23-composition-errors.t`
  - `prove -I perl t`
- Immediate next direction after commit:
  - move to `C4`,
  - define the first narrow declared connect-by-name rule beyond the current explicit-link-only composition lanes.
## 2026-03-14: `R6` first shipped `C2` FSM-linking lane
- Current worktree widens the shipped composition runtime from single-child passthrough into the first explicit multi-child FSM-linking lane.
- Scope of this slice:
  - added `FSM::Composition::Net` and extended the typed runtime plan so multi-child tops can carry deterministic internal-net and binding data,
  - updated `FSM::Pipeline::HDLGenerator` to choose between `C1` and `C2` planning lanes,
  - shipped `C2` support for multiple embedded `?fsmc` children with explicit `?toplink` endpoint resolution using top-port names and `instance.port` child endpoints,
  - added exact source/target role checks, exact width checks, deterministic internal-net naming, deterministic instance order preservation, and duplicate-driver rejection,
  - kept the active child-interface contract truthful by continuing to auto-wire only the shared `clk` / `rstn` system inputs and requiring explicit wiring for other child ports.
- Regression coverage update:
  - tightened `t/14-composition-parser.t` so dotted `instance.port` endpoints in `?toplink` are now locked explicitly,
  - added `t/21-composition-two-fsm-linking.t` for the shipped `C2` success path and CLI generation,
  - added `t/23-composition-errors.t` for duplicate-driver diagnostics.
- Roadmap board update:
  - `ROADMAP_STATUS.md` still keeps `R6` at `in progress`,
  - `R6` `Done` now includes the first shipped `C2` FSM-only linking lane,
  - the current next decision point is now `C3` mixed `?fsmc` + `?rtl` realization, not more FSM-only multi-child groundwork.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Composition/Net.pm`
  - `perl -I perl -c perl/FSM/Pipeline/HDLGenerator.pm`
  - `perl -I perl -c t/21-composition-two-fsm-linking.t`
  - `perl -I perl -c t/23-composition-errors.t`
  - `prove -I perl t/13-composition-source-classification.t t/14-composition-parser.t t/20-composition-single-fsm-top.t t/21-composition-two-fsm-linking.t t/23-composition-errors.t` (`Files=5`, `Tests=120`, `PASS`)
  - `prove -I perl t`
- Immediate next direction after commit:
  - move to `C3`,
  - add `?rtl` child realization with declared interface metadata and mixed `?fsmc` + `?rtl` planning/emission.
## 2026-03-14: `R6` first shipped `C1` composition lane
- Current worktree moves `R6` from parser/planning groundwork into the first real shipped composition runtime slice.
- Scope of this slice:
  - added typed composition planning/runtime packages: `Port`, `Link`, `Plan`, and `RealizedInstance`,
  - updated `FSM::Composition::Parser` so `?ports` and `?toplink` payloads are now stored as typed port/link objects instead of raw payloads,
  - updated `FSM::Pipeline::HDLGenerator` so `?top:name` can now realize one embedded `?fsmc` child, build a typed `C1` plan, validate explicit top-port exposure, and emit a generated top module,
  - captured the realized child interface as typed ports,
  - matched the active child-generator contract truthfully by treating `clk` / `rstn` as implicit system inputs and requiring user-facing child ports to be explicitly exposed by the child FSM itself.
- Regression coverage update:
  - added `t/20-composition-single-fsm-top.t` to lock the first end-to-end composition acceptance slice through pipeline, plan, HDL text, and CLI output,
  - the fixture was tightened so the child FSM explicitly exposes `output_data` as an output, which matches the current active FSM pipeline contract instead of inventing a looser composition rule.
- Roadmap board update:
  - `ROADMAP_STATUS.md` still keeps `R6` at `in progress`,
  - `R6` `Done` now includes the first shipped `C1` realization/top-emission lane,
  - the current next decision point is now `C2`-style multi-child planning plus typed `?toplink`/net resolution, not more single-child boundary work.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Composition/RealizedInstance.pm`
  - `perl -I perl -c perl/FSM/Pipeline/HDLGenerator.pm`
  - `perl -I perl -c t/20-composition-single-fsm-top.t`
  - `prove -I perl t/13-composition-source-classification.t t/14-composition-parser.t t/20-composition-single-fsm-top.t` (`Files=3`, `Tests=79`, `PASS`)
  - `prove -I perl t`
- Immediate next direction after commit:
  - widen from shipped `C1` to `C2`,
  - add multi-child top planning, typed explicit `?toplink`/net resolution, deterministic instance ordering, and duplicate-driver diagnostics.
## 2026-03-14: `R6` legacy mapping note plus first typed `?top` parser/IR slice
- Current worktree continues `R6` by turning the composition boundary into a real typed parser seam instead of only a classifier/error seam.
- Scope of this slice:
  - added `docs/COMPOSITION_LEGACY_MAPPING.md` to capture the obsolete `fx/bin/fsmgen` composition call tree (`start_from_file` -> `fsm_initialize` -> `top_exec`) and map legacy concepts onto the active architecture,
  - documented the main historical lesson: keep `?top`, `?fsmc`, `?rtl`, `?ports`, and `?toplink` as language ideas, but do not revive the old `AUTOLOAD` / `PPlugin` / `.plg` mechanism,
  - added typed composition packages under `perl/FSM/Composition/` for the first active parser boundary: `Spec`, `Top`, `Instance`, `PortsBlock`, `TopLink`, and `Parser`,
  - `FSM::Pipeline::HDLGenerator` now parses `?top:name` through `FSM::Composition::Parser` before failing at the still-unimplemented realization/emission stage,
  - the parser now recognizes typed child-block structure for `?fsmc`, `?rtl`, `?ports`, and `?toplink`,
  - explicit unsupported legacy residue is now called out truthfully:
    - inline top-port shorthand under `?top:name`,
    - multi-source `?fsmc`,
    - nested `?top`,
    - and unknown child kinds.
- Regression coverage update:
  - `t/13-composition-source-classification.t` now proves the pipeline boundary happens after typed composition parsing and points at both composition docs,
  - added `t/14-composition-parser.t` to lock typed parsing of real and synthetic `?top` inputs plus explicit rejection of unsupported legacy residue.
- Roadmap board update:
  - `ROADMAP_STATUS.md` still keeps `R6` at `in progress`,
  - `R6` `Done` now includes the first typed composition parser/IR slice and the legacy-to-modern mapping note,
  - the current next decision point is now the first child-realization/top-planning lane for `C1`, not another parser-only slice.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Composition/Spec.pm`
  - `perl -I perl -c perl/FSM/Composition/Top.pm`
  - `perl -I perl -c perl/FSM/Composition/Instance.pm`
  - `perl -I perl -c perl/FSM/Composition/PortsBlock.pm`
  - `perl -I perl -c perl/FSM/Composition/TopLink.pm`
  - `perl -I perl -c perl/FSM/Composition/Parser.pm`
  - `perl -I perl -c perl/FSM/Pipeline/HDLGenerator.pm`
  - `perl -I perl -c t/14-composition-parser.t`
  - `prove -I perl t/13-composition-source-classification.t t/14-composition-parser.t` (`Files=2`, `Tests=38`, `PASS`)
- Immediate next direction after commit:
  - define typed parsing/planning for explicit `?ports` / `?toplink` payloads instead of storing them as raw items,
  - then implement the first `C1` realization path: one `?top:name`, one `?fsmc` child, explicit top-port exposure, and deterministic top planning.
## 2026-03-14: `R6` composition source-classification boundary slice
- Current worktree lands the first executable composition-aware code path in the active architecture without claiming full composition support yet.
- Scope of this slice:
  - added `perl/FSM/SourceClassifier.pm` as the shared top-level source-kind classifier for raw Lispish ASTs,
  - `perl/FSM/Pipeline/HDLGenerator.pm` now classifies source kind before adapter parsing and rejects `?top:name` with an explicit composition-boundary diagnostic,
  - `perl/FSM/Adapter/FSMGenFull/Parser.pm` now also rejects `?top:name` with a composition-specific FSM-only-parser error for direct callers,
  - added `t/13-composition-source-classification.t` to lock classification of `?fsm:name` vs `?top:name` and the user-facing failure mode through pipeline, adapter, and CLI,
  - tightened `t/01-regression.t` so the broad sample compile sweep now covers only active FSM-root sources and no longer treats composition-shaped fixtures as supported single-FSM inputs,
  - retargeted `t/09-ast-first-intermediate-registry.t` and `t/10-ast-first-enable-structure.t` from the legacy composition sample `fsm/trial_1.fsm` to the real FSM-root sample `fsm/lte_dif_pmaster.fsm`.
- Roadmap board update:
  - `ROADMAP_STATUS.md` still keeps `R6` at `in progress`,
  - `R6` `Done` now includes explicit top-level source classification plus deliberate composition-boundary failure,
  - the current `R6` next decision point is now the first typed composition parser/IR slice for `?top:name` contents (`?ports`, `?fsmc`, `?rtl`, `?toplink`).
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/SourceClassifier.pm`
  - `perl -I perl -c perl/FSM/Pipeline/HDLGenerator.pm`
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm`
  - `perl -I perl -c t/01-regression.t`
  - `prove -I perl t/01-regression.t`
  - `prove -I perl t/13-composition-source-classification.t` (`Files=1`, `Tests=14`, `PASS`)
- Immediate next direction after commit:
  - build the first typed composition parser/IR objects for `?top:name` contents rather than only classifying the root,
  - start the first executable acceptance slice from `docs/COMPOSITION_SCOPE.md`, likely `C1` around a single `?fsmc` child and explicit top-port exposure.
## 2026-03-14: Roadmap phase transition (`R2` done, active lane -> `R3`)
- Current worktree is a roadmap-state update driven by an ownership-boundary audit, not by another code move.
- Audit result:
  - `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` no longer directly owns `assignment_analysis` / `lhs_assignments` mutation or analysis,
  - the remaining backend pocket is runtime AST recovery/filtering, dependency rescue/topological ordering, and emitted-signal rendering flow,
  - that matches the `R2` deliverables currently stated in `ROADMAP_STATUS.md`.
- Roadmap transition recorded in `ROADMAP_STATUS.md`:
  - `R2` moved from `in progress` to `done`,
  - the current active lane switched to `R3` (`AST/CoreAST-first runtime convergence`),
  - `R3` next decision point is now the remaining runtime-AST-miss / compatibility-parse fallback residue in `Backend::SystemVerilog`.
- Validation is green for this slice:
  - `git diff --check`
  - `rg -n "resolve_intermediate_signal_runtime_ast|should_filter_ast_based|should_filter_runtime_ast_miss|topologically_sort_signals|generate_consolidated_intermediate_signals" perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - backend audit confirms no remaining `assignment_analysis` / `lhs_assignments` matches in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
- Immediate next direction after commit:
  - follow `R3` and re-audit the remaining compatibility/runtime-AST-miss fallback paths,
  - remove them where they are no longer justified, or keep them explicitly as deliberate residue if they still serve a necessary boundary.
## 2026-03-14: Roadmap phase transition (`R3` done, active lane -> `R6`)
- Current worktree closes the `R3` runtime-convergence lane after removing the last implicit stored-expression runtime-AST promotion path from normal backend resolution.
- Audit result:
  - `resolve_intermediate_signal_runtime_ast(...)` no longer parses stored expressions directly,
  - the only remaining string reconstruction in this area is explicit miss-recovery parsing in `recover_runtime_ast_from_dependency_expression(...)` plus the owner-side compatibility parser in `EnableGraph` for legacy registry/global-expression entries,
  - that matches the `R3` exit criteria because compatibility residue is now narrow, explicit, and justified rather than being part of the default runtime path.
- Roadmap transition recorded in `ROADMAP_STATUS.md`:
  - `R3` moved from `mostly done` to `done`,
  - the current active lane switched to `R6` (`Composition-oriented language / architecture work`),
  - `R6` next decision point is now to define concrete active-architecture scope and acceptance tests before implementation.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/07-runtime-ast-miss-dependency-recovery.t` (`Files=1`, `Tests=21`, `PASS`)
  - `prove -I perl t` (`Files=12`, `Tests=413`, `PASS`)
- Immediate next direction after commit:
  - start `R6` with a scope-definition slice grounded in the active `bin/fsmgen` architecture,
  - write acceptance tests and developer-facing scope notes before implementing composition behavior.
## 2026-03-14: Composition scope-definition slice (`R6` enters `in progress`)
- Current worktree starts the first concrete `R6` slice by defining composition scope for the active architecture instead of leaving it as roadmap shorthand.
- Scope of this slice:
  - added `docs/COMPOSITION_SCOPE.md` as the normative scope and acceptance-boundary document for the first composition lane,
  - grounded the scope in the active pipeline boundary: `bin/fsmgen` -> `FSM::Pipeline::HDLGenerator` -> `FSM::Adapter::FSMGenFull::Parser`, which currently only supports `?fsm:name` / `+fsm`,
  - defined the first supported composition source model around `?top:name`, `?fsmc`, `?rtl`, `?ports`, and `?toplink`,
  - defined the first executable acceptance matrix (`C1`..`C6`) plus the planned focused composition test-file split.
- Roadmap board update:
  - `ROADMAP_STATUS.md` now marks `R6` as `in progress`,
  - `R6` deliverables now explicitly include acceptance-matrix definition as a tracked sub-deliverable,
  - the active-lane next step is now implementation of the first typed composition classifier/parser slice rather than more scope discovery.
- Validation is green for this slice:
  - `git diff --check`
  - `rg -n "COMPOSITION_SCOPE\\.md|\\?top:name|\\?fsmc|\\?rtl|\\?ports|\\?toplink|R6.*in progress|Composition-oriented language" README.md docs/USER_GUIDE.md docs/COMPOSITION_SCOPE.md ROADMAP_STATUS.md MEMORY.md CHANGES.md DEVELOPMENT_NOTES.md`
- Immediate next direction after commit:
  - implement the first typed composition source classifier above the existing FSM-only parser,
  - then add the first executable composition acceptance tests from `docs/COMPOSITION_SCOPE.md`.
## 2026-03-14: AST/CoreAST convergence micro-slice (remove render-time late hydration)
- Current worktree continues the `R3` runtime convergence lane and narrows one compatibility behavior inside `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- Scope of this slice:
  - removed the render-time “late hydration” retry from `render_intermediate_signal_expression(...)`, so an initial `no_ast_source` miss no longer silently promotes `runtime_ast` during plain expression rendering,
  - kept the explicit runtime-AST-miss dependency-recovery path intact, so cleaned compatibility expressions can still recover dependencies when that fallback is intentionally invoked,
  - fixed `resolve_intermediate_signal_width(...)` so the explicit recovery path can call it with the shorter live form used by the backend.
- Regression coverage update:
  - `t/07-runtime-ast-miss-dependency-recovery.t` now proves that render-time expression fallback preserves the original `no_ast_source` miss state and does not silently hydrate `runtime_ast`,
  - the same test now proves that explicit dependency recovery can still promote `runtime_ast` from a cleaned compatibility expression and records that source as `dependency_cleaned_rendered_expression_ast`.
- Roadmap board update:
  - `ROADMAP_STATUS.md` still keeps `R3` at `mostly done`,
  - `R3` `Done` / `Left` now reflect that late hydration is gone and the remaining residue is the direct raw/cleaned expression parsing inside runtime-AST resolution and dependency recovery.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/07-runtime-ast-miss-dependency-recovery.t` (`Files=1`, `Tests=17`, `PASS`)
- Immediate next direction after commit:
  - re-audit the remaining direct compatibility parsing inside `resolve_intermediate_signal_runtime_ast(...)` and `recover_runtime_ast_from_dependency_expression(...)`,
  - decide whether that residue can be removed, replaced with native AST/CoreAST data, or kept explicitly as the final compatibility boundary.
## 2026-03-14: AST/CoreAST convergence micro-slice (remove direct stored-expression runtime parse)
- Current worktree continues the `R3` runtime convergence lane and removes the direct stored-expression compatibility parse from normal backend runtime-AST resolution.
- Scope of this slice:
  - `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm::resolve_intermediate_signal_runtime_ast(...)` no longer parses `signal_info->{expression}` directly,
  - stored-expression-only runtime-AST resolution now records `no_ast_source` and leaves recovery to the explicit runtime-AST-miss path instead of synthesizing `parsed_expression_ast` / `cleaned_expression_ast`,
  - `t/07-runtime-ast-miss-dependency-recovery.t` now proves the removed implicit path and keeps explicit cleaned-expression recovery covered.
- Roadmap board update:
  - this slice closes the remaining `R3` ambiguity around implicit runtime string parsing,
  - `ROADMAP_STATUS.md` now marks `R3` as `done` and pivots the active lane to `R6`.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/07-runtime-ast-miss-dependency-recovery.t` (`Files=1`, `Tests=21`, `PASS`)
- Immediate next direction after commit:
  - move to `R6` and define the composition-oriented scope and acceptance boundary before implementation.
## 2026-03-14: FlattenedDT live ownership micro-slice (EnableGraph live-usage evidence ownership)
- Current worktree continues the `R2` live ownership lane and moves intermediate-signal live-usage evidence derivation under `EnableGraph`.
- Scope of this slice:
  - `perl/FSM/Synthesis/EnableGraph.pm` now owns `ast_contains_signal(...)`,
  - `EnableGraph` now also owns `is_signal_referenced_in_substitutions(...)`, `is_signal_actually_used_in_final_expressions(...)`, and `resolve_intermediate_signal_live_usage(...)`,
  - `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` now consumes that owner-provided live-usage metadata directly during consolidated intermediate-signal filtering and no longer exposes the owner-side evidence helpers itself.
- Regression coverage update:
  - `t/10-ast-first-enable-structure.t` now asserts that the backend stays free of the former live-usage evidence helper pocket,
  - the same test now asserts that `EnableGraph` owns AST signal-reference inspection, substituted-expression/final-expression usage evidence, and cached live-usage metadata derivation on the live path.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=176`, `PASS`)
  - `prove -I perl t` (`Files=12`, `Tests=400`, `PASS`)
- Immediate next direction after commit:
  - re-audit the remaining backend filtering decision logic around consolidated intermediate-signal emission,
  - move only the pieces that are truly synthesis/analysis ownership, not backend-local factorization or rendering.
## 2026-03-14: Live status visibility hardening
- Current worktree tightens the roadmap-status workflow so status changes are both persistent and visible at close-out time.
- Scope of this slice:
  - `ROADMAP_STATUS.md` now explicitly requires three actions whenever any workstream status or the active lane changes: refresh the board, log the change in `CHANGES.md`, and display the current live status snapshot in the user-facing close-out,
  - `COMMIT.md` and `.agents/workflows/commit.md` now treat status-transition logging plus close-out display as part of the standard post-task workflow,
  - `MEMORY.md` now records this as a non-negotiable workflow rule for future sessions.
- Validation is green for this slice:
  - `git diff --check`
  - `rg -n "live status|status snapshot|ROADMAP_STATUS\\.md|CHANGES\\.md" ROADMAP_STATUS.md MEMORY.md COMMIT.md .agents/workflows/commit.md CHANGES.md DEVELOPMENT_NOTES.md`
- Immediate next direction after commit:
  - whenever a workstream status or active lane changes, refresh `ROADMAP_STATUS.md`, record the transition in `CHANGES.md`, and show the current live snapshot in the close-out,
  - continue using `ROADMAP_STATUS.md` as the canonical current-state board and `CHANGES.md` as the historical log of status transitions.
## 2026-03-14: Roadmap deliverables hardening
- Current worktree tightens the roadmap board so each `Rx` phase has explicit deliverables, not just status labels.
- Scope of this slice:
  - `ROADMAP_STATUS.md` now requires each workstream to state `Deliverables`, `Status`, `Done`, `Left`, and `Exit criteria`,
  - the status-scale definitions are now tied directly to deliverable completion, so `done` means all listed deliverables are complete and the exit criteria are met,
  - each current `R0`..`R7` workstream now has concrete deliverables written out in the board itself.
- Validation is green for this slice:
  - `git diff --check`
  - `rg -n "^Deliverables:|roadmap deliverables|All listed `Deliverables`" ROADMAP_STATUS.md MEMORY.md COMMIT.md .agents/workflows/commit.md CHANGES.md DEVELOPMENT_NOTES.md`
- Immediate next direction after commit:
  - keep workstream deliverables explicit and current whenever the roadmap interpretation changes,
  - use those deliverables, not narrative intuition, when deciding whether a phase is `done`, `mostly done`, `in progress`, or `not started`.
## 2026-03-14: FlattenedDT live ownership micro-slice (EnableGraph substitution synchronization ownership)
- Current worktree continues the `R2` live ownership lane and moves substitution-era AST rewrite/debug passes under `EnableGraph`.
- Scope of this slice:
  - `perl/FSM/Synthesis/EnableGraph.pm` now owns `count_unary_negations_in_original_expressions(...)`,
  - `EnableGraph` now also owns `update_original_asts_with_substituted_versions(...)` and `update_original_asts_with_second_pass_substitutions(...)`, plus a shared context-to-AST map helper for the two update passes,
  - `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` now routes first-pass substitution synchronization and the surrounding unary-negation debug scans through `enable_graph`,
  - `perl/FSM/HDL/Factorization/Fixpoint.pm` now routes second-pass substitution synchronization through `enable_graph` instead of the backend.
- Regression coverage update:
  - `t/10-ast-first-enable-structure.t` now asserts that the backend stays free of the former substitution-update/debug helper pocket,
  - the same test now asserts that `EnableGraph` owns the unary-negation debug scan plus first-pass and second-pass substitution synchronization on the live path.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `perl -I perl -c perl/FSM/HDL/Factorization/Fixpoint.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=168`, `PASS`)
  - `prove -I perl t` (`Files=12`, `Tests=392`, `PASS`)
- Immediate next direction after commit:
  - re-audit the remaining backend-side filtering and live-usage checks around consolidated intermediate-signal emission,
  - move only the pieces that are truly synthesis/analysis ownership, not backend-local factorization or rendering.
## 2026-03-14: FlattenedDT live ownership micro-slice (EnableGraph factorization AST-feed ownership)
- Current worktree continues the `R2` live ownership lane and moves factorization input feeding under `EnableGraph`.
- Scope of this slice:
  - `perl/FSM/Synthesis/EnableGraph.pm` now owns `feed_asts_to_factorizer(...)`,
  - `EnableGraph` now also owns `feed_current_asts_to_second_pass(...)` plus the second-pass intermediate-signal eligibility helpers `ast_contains_intermediate_signals(...)` and `ast_has_intermediate_signals_recursive(...)`,
  - `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` now calls `enable_graph->feed_asts_to_factorizer(...)` during primary factorization and no longer exposes those feeders/helpers itself,
  - `perl/FSM/HDL/Factorization/Fixpoint.pm` now routes second-pass AST collection through `enable_graph` instead of the backend.
- Regression coverage update:
  - `t/10-ast-first-enable-structure.t` now asserts that the backend stays free of the former factorization-feed helper pocket,
  - the same test now asserts that `EnableGraph` owns first-pass AST feeding, second-pass AST feeding, and second-pass intermediate-signal eligibility checks on the live path.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `perl -I perl -c perl/FSM/HDL/Factorization/Fixpoint.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=162`, `PASS`)
  - `prove -I perl t` (`Files=12`, `Tests=386`, `PASS`)
- Immediate next direction after commit:
  - re-audit whether the remaining substitution-update/debug passes over `assignment_analysis` and captured condition ASTs still belong in the backend,
  - move only the pieces that are truly synthesis/analysis ownership, not backend-local factorization or rendering.
## 2026-03-14: Roadmap tracking infrastructure hardening
- Current worktree establishes a canonical live roadmap board so status can be checked precisely at any time without reconstructing it from narrative history.
- Scope of this slice:
  - added `ROADMAP_STATUS.md` as the canonical four-state board (`done`, `mostly done`, `in progress`, `not started`),
  - recorded the current baseline workstreams, current active lane, and exact “done vs left” summaries there,
  - updated `README.md`, `MEMORY.md`, `COMMIT.md`, and `.agents/workflows/commit.md` so this board is part of the normal repo workflow rather than optional documentation.
- Validation is green for this slice:
  - `git diff --check`
  - `rg -n "ROADMAP_STATUS\.md" README.md MEMORY.md COMMIT.md .agents/workflows/commit.md CHANGES.md DEVELOPMENT_NOTES.md`
- Immediate next direction after commit:
  - keep `ROADMAP_STATUS.md` updated before every commit whenever a task changes status, remaining work, or the active lane,
  - continue using it as the primary answer source for “how much is done?” instead of reconstructing status ad hoc from `CHANGES.md` / `DEVELOPMENT_NOTES.md`.
## 2026-03-14: FlattenedDT live ownership micro-slice (EnableGraph logical-op counting ownership)
- Current worktree continues the live ownership lane and moves binary logical-operation counting under `EnableGraph`.
- Scope of this slice:
  - `perl/FSM/Synthesis/EnableGraph.pm` now owns `count_binary_logical_operation_occurrences(...)`,
  - the same owner now also holds the supporting AST collection and traversal helpers used by that pass (`collect_all_wen_en_ast_expressions(...)`, `_count_logical_ops_in_ast(...)`, `_is_factorizable_sub_expression(...)`),
  - `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` now routes step 4 directly through `enable_graph`,
  - `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` now relies on `enable_graph` for the fallback recount inside global AST factorization and no longer exposes the former counting entrypoints.
- Regression coverage update:
  - `t/10-ast-first-enable-structure.t` now asserts that the backend stays free of the logical-op counting helper pocket,
  - the same test now asserts that `EnableGraph` owns binary logical-operation counting on the live path.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=155`, `PASS`)
  - `prove -I perl t` (`Files=12`, `Tests=379`, `PASS`)
- Immediate next direction after commit:
  - re-audit whether any remaining backend stage still analyzes `assignment_analysis` or other `EnableGraph`-owned enable structures instead of doing backend-local factorization/rendering,
  - if that lane is now exhausted, pivot to the next truthful runtime seam rather than continuing owner-churn on the same edge.
## 2026-03-14: FlattenedDT live ownership micro-slice (EnableGraph WEN/EN prescan ownership)
- Current worktree continues the live ownership lane and moves WEN/EN intermediate-signal prescan under `EnableGraph`.
- Scope of this slice:
  - `perl/FSM/Synthesis/EnableGraph.pm` now owns `prescan_wen_en_for_intermediate_signals(...)`,
  - the prescan now walks `EnableGraph`-owned `assignment_analysis` and the AST-backed DT/LHS enable structures from the same owner that already owns `track_ast_intermediate_signals(...)`,
  - `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` now routes step 5 directly through `enable_graph`,
  - `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` no longer exposes the former backend-side prescan entrypoint.
- Regression coverage update:
  - `t/10-ast-first-enable-structure.t` now asserts that the backend stays free of `prescan_wen_en_for_intermediate_signals(...)`,
  - the same test now asserts that `EnableGraph` owns WEN/EN intermediate-signal prescan on the live path.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=150`, `PASS`)
  - `prove -I perl t` (`Files=12`, `Tests=374`, `PASS`)
- Immediate next direction after commit:
  - re-audit whether any remaining backend stage still performs live analysis over `assignment_analysis` or other synthesis-owned enable structures instead of rendering or backend-local factorization work,
  - if that lane is exhausted, pivot to the next truthful runtime seam instead of continuing owner-churn.
## 2026-03-14: FlattenedDT live ownership micro-slice (EnableGraph state register planning)
- Current worktree continues the same live synthesis ownership lane and moves state-structure planning under `EnableGraph`.
- Scope of this slice:
  - `perl/FSM/Synthesis/EnableGraph.pm` now owns `build_state_register_plan(...)`,
  - that plan now decides whether state registers exist at all, the regular-state encoding order, state-bit width, and the reset-state localparam name,
  - `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` now renders state encoding and state-register HDL from that owner-provided plan instead of recomputing regular-state structure locally,
  - `build_internal_signal_declaration_plan(...)` and `get_fsm_reset_state(...)` now also reuse the same state plan instead of maintaining separate regular-state scans.
- Regression coverage update:
  - `t/11-flatteneddt-generation-reset.t` now inspects the state plan for standalone-DT-only FSMs and locks that reused generators keep state-register planning disabled there,
  - `t/12-enablegraph-capture-registry.t` now inspects the state plan for a regular-state FSM and locks reset-state selection plus encoding order,
  - `t/10-ast-first-enable-structure.t` now asserts that `EnableGraph` owns state register planning on the live path.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t t/11-flatteneddt-generation-reset.t t/12-enablegraph-capture-registry.t` (`PASS`)
  - `prove -I perl t` (`PASS`)
- Immediate next direction after commit:
  - re-audit whether any remaining backend stage still computes synthesis-domain structure instead of rendering an owner-provided plan,
  - if the planning/rendering lane is now thin, pivot to the next truthful live runtime seam instead of stretching it artificially.
## 2026-03-14: FlattenedDT live ownership micro-slice (EnableGraph module declaration planning)
- Current worktree continues the same live synthesis ownership lane and moves module/interface declaration planning under `EnableGraph`.
- Scope of this slice:
  - `perl/FSM/Synthesis/EnableGraph.pm` now owns `build_module_declaration_plan(...)`,
  - that plan now decides live interface-port shape from synthesis-owned signal classification, including base ports, input vs output direction, `reg` vs `wire` storage, signal widths, and the derived `declared_port_signals` / `port_directions` registries,
  - `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` now only renders the returned plan instead of re-deriving interface decisions from synthesis metadata locally.
- Regression coverage update:
  - `t/03-assignment-intent-metadata.t` now inspects the live module declaration plan directly and locks representative input/output ownership for `B`, `D`, `G`, `J`, `L`, `next_I`, and `K_r`,
  - `t/05-assignment-hdl-snapshots.t` stayed green after restoring the exact legacy `output reg  ...` port-spacing contract in the backend renderer,
  - `t/10-ast-first-enable-structure.t` now asserts that `EnableGraph` owns module declaration planning on the live path.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/05-assignment-hdl-snapshots.t` (`Files=1`, `Tests=12`, `PASS`)
  - `prove -I perl t/03-assignment-intent-metadata.t t/10-ast-first-enable-structure.t` (`Files=2`, `Tests=242`, `PASS`)
  - `prove -I perl t` (`Files=12`, `Tests=364`, `PASS`)
- Immediate next direction after commit:
  - re-audit whether any remaining backend emission stage still mixes synthesis-domain planning with rendering,
  - if this declaration-planning seam is now exhausted, pivot to the next truthful live runtime seam instead of forcing another interface-only move.
## 2026-03-14: FlattenedDT live ownership micro-slice (EnableGraph internal declaration planning)
- Current worktree pivots from wrapper-only convergence to the next real live synthesis seam: internal declaration planning.
- Scope of this slice:
  - `perl/FSM/Synthesis/EnableGraph.pm` now owns `build_internal_signal_declaration_plan(...)`,
  - that plan now decides, from live `assignment_analysis`, which internal regs and aux helper regs must exist (`I_next`, `K_q`, pulse-delay pipes, etc.),
  - `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` now only renders the returned plan instead of re-deriving declaration decisions itself from synthesis metadata.
- Regression coverage update:
  - `t/03-assignment-intent-metadata.t` now inspects the live declaration plan directly and locks the expected helper declarations for dual-output and pulse-delay families,
  - `t/10-ast-first-enable-structure.t` now asserts that `EnableGraph` owns internal declaration planning on the live path.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/03-assignment-intent-metadata.t t/10-ast-first-enable-structure.t` (`Files=2`, `Tests=224`, `PASS`)
  - `prove -I perl t` (`Files=12`, `Tests=346`, `PASS`)
- Immediate next direction after commit:
  - re-audit whether any other backend emission steps still make synthesis-domain planning decisions that now belong in `EnableGraph`,
  - if not, pivot to the next truthful live runtime seam instead of continuing declaration-planning convergence.
## 2026-03-14: FlattenedDT live ownership micro-slice (EnableGraph unified WEN/EN emission)
- Current worktree continues the same enable-synthesis ownership lane and removes the remaining stage-7 backend wrapper around unified WEN/EN emission.
- Scope of this slice:
  - `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` now calls `enable_graph->generate_unified_wen_en_signals(...)` directly in step 7,
  - `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` no longer exposes the wrapper-only `generate_wen_en_signals(...)` entrypoint,
  - the live emission owner is now consistent with the existing implementation owner in `perl/FSM/Synthesis/EnableGraph.pm`.
- Architecture guard update in `t/10-ast-first-enable-structure.t`:
  - the backend is now asserted to stay free of `generate_wen_en_signals(...)`,
  - the live `EnableGraph` object is asserted to own `generate_unified_wen_en_signals(...)`.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=145`, `PASS`)
  - `prove -I perl t` (`Files=12`, `Tests=337`, `PASS`)
- Immediate next direction after commit:
  - re-audit whether any other active generation stage is still only a routing wrapper around `EnableGraph` ownership,
  - if that lane is now exhausted, pivot to the next truthful live runtime seam instead of continuing wrapper-only convergence.
## 2026-03-14: FlattenedDT live ownership micro-slice (EnableGraph top-level enable emission)
- Current worktree continues the same enable-synthesis lane and moves top-level state/DT enable emission under `EnableGraph`.
- Scope of this slice:
  - `perl/FSM/Synthesis/EnableGraph.pm` now owns `generate_enable_conditions(...)`,
  - that method emits the top-level `state_enables` / `dt_enables` registries that `EnableGraph` already initializes and now stores as AST-backed conditions,
  - `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` now calls `enable_graph->generate_enable_conditions(...)`,
  - `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` no longer exposes the old top-level enable-emission entrypoint.
- Architecture guard update in `t/10-ast-first-enable-structure.t`:
  - the live backend is now asserted to stay free of `generate_enable_conditions(...)`,
  - the live `EnableGraph` object is asserted to own that emission entrypoint.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t t/12-enablegraph-capture-registry.t` (`Files=2`, `Tests=164`, `PASS`)
  - `prove -I perl t` (`Files=12`, `Tests=335`, `PASS`)
- Immediate next direction after commit:
  - re-audit whether any other live top-level enable/declaration emission still sits on the backend side while the owning synthesis semantics already live in `EnableGraph`,
  - if that lane is now exhausted, pivot to the next truthful live runtime seam instead of stretching enable-emission ownership further.
## 2026-03-13: FlattenedDT AST-first live micro-slice (AST-backed top-level enable registries)
- Current worktree pivots slightly away from the shrinking `Orchestrator` seam and hardens the next real live AST/CoreAST-first boundary: top-level `state_enables` / `dt_enables`.
- Scope of this slice:
  - `perl/FSM/Synthesis/EnableGraph.pm` now owns `build_state_enable_condition_ast(...)` and `build_dt_enable_condition_ast(...)`,
  - `initialize_state_and_dt_enable_conditions(...)` now stores AST-backed enable conditions in the live top-level registries instead of plain strings,
  - `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` now renders those top-level enable conditions from AST objects when emitting the `*_en` assigns.
- Regression coverage update:
  - `t/10-ast-first-enable-structure.t` now asserts the top-level `state_enables` / `dt_enables` registries are populated with AST-backed conditions,
  - `t/11-flatteneddt-generation-reset.t` now asserts reused generators keep standalone DT enable entries AST-backed across runs and still render as `1'b1`.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t t/11-flatteneddt-generation-reset.t` (`Files=2`, `Tests=158`, `PASS`)
  - `prove -I perl t/12-enablegraph-capture-registry.t` (`Files=1`, `Tests=21`, `PASS`)
  - `prove -I perl t` (`Files=12`, `Tests=333`, `PASS`)
- Immediate next direction after commit:
  - re-audit whether any other live top-level enable/declaration registries are still string-backed without a real semantic reason,
  - if not, pivot away from registry-shape work and choose the next truthful live runtime seam elsewhere in the active generation flow.
## 2026-03-13: FlattenedDT live ownership micro-slice (EnableGraph test-condition AST ownership)
- Current worktree continues the same live `Orchestrator` / `EnableGraph` seam and moves the remaining test-node condition AST construction under `EnableGraph`.
- Scope of this slice:
  - `perl/FSM/Synthesis/EnableGraph.pm` now owns `build_test_condition_ast(...)`,
  - that helper now centralizes `signal == value` AST construction for `FSM::CoreAST::TestNode` branches by combining the test signal ref with the already-owner-local `convert_test_value_to_ast(...)` path,
  - `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` no longer constructs test-branch equality ASTs inline inside `flatten_decision_tree(...)`.
- Regression coverage update in `t/12-enablegraph-capture-registry.t`:
  - the fixture now exercises a real `?MODE` test node,
  - capture-registry assertions inspect the pre-factorization phase immediately after `flatten_all_decision_trees(...)`,
  - the test now locks that both assignment and transition capture preserve the expected `MODE == 1'b1` condition AST before later factorization rewrites it into an intermediate signal ref during full generation.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `prove -I perl t/12-enablegraph-capture-registry.t` (`Files=1`, `Tests=21`, `PASS`)
  - `prove -I perl t/10-ast-first-enable-structure.t t/12-enablegraph-capture-registry.t` (`Files=2`, `Tests=160`, `PASS`)
  - `prove -I perl t` (`Files=12`, `Tests=327`, `PASS`)
- Immediate next direction after commit:
  - re-audit the remaining `Orchestrator` / `EnableGraph` seam one more time for any similarly small live ownership move around condition-stack preparation,
  - if that seam is now exhausted, pivot to the next truthful live runtime seam elsewhere in the active generation flow instead of inventing more wrapper work.
## 2026-03-13: FlattenedDT live ownership micro-slice (EnableGraph capture-entrypoint ownership)
- Current worktree continues the same live assignment-capture seam and now moves the capture entrypoints themselves under `EnableGraph`.
- Scope of this slice:
  - `perl/FSM/Synthesis/EnableGraph.pm` now owns `capture_assignment_from_ast(...)` and `capture_transition_from_ast(...)`,
  - these methods now assemble capture condition ASTs, perform capture-time debug logging, and delegate into the already-owner-local capture registration helpers,
  - `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` no longer exposes local `record_assignment_from_ast(...)` / `record_transition_from_ast(...)` methods and now delegates directly from `flatten_decision_tree(...)`.
- Architecture guard update:
  - `t/10-ast-first-enable-structure.t` now asserts that the live `Orchestrator` object no longer exposes `record_assignment_from_ast` or `record_transition_from_ast`.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t t/12-enablegraph-capture-registry.t` (`Files=2`, `Tests=157`, `PASS`)
  - `prove -I perl t` (`Files=12`, `Tests=324`, `PASS`)
- Immediate next direction after commit:
  - continue on the live `Orchestrator` / `EnableGraph` seam only if there is still a coherent runtime ownership move left,
  - otherwise re-audit the broader active flow and choose the next truthful slice outside capture-entrypoint convergence.
## 2026-03-13: FlattenedDT live ownership micro-slice (EnableGraph assignment-metadata normalization)
- Current worktree continues on the same live assignment-capture seam.
- Scope of this slice:
  - `perl/FSM/Synthesis/EnableGraph.pm` now owns assignment operator/intent/provenance normalization through `extract_assignment_capture_metadata(...)`,
  - that helper now centralizes `assignment_intent` copy, operator resolution, pulse-operator derivation from `pulse_cycles`, strict operator validation, and `source_provenance` / `output_exposure` capture,
  - `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` still performs traversal, condition assembly, and RHS extraction, but no longer keeps local operator/intent extraction logic inside `record_assignment_from_ast(...)`.
- Regression coverage added in `t/03-assignment-intent-metadata.t`:
  - after live generation, captured assignment registry entries are now checked for preserved operator/intent/provenance data on representative assignment families (`A`, `G`, `I`, `P1`).
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `prove -I perl t/03-assignment-intent-metadata.t t/12-enablegraph-capture-registry.t` (`Files=2`, `Tests=88`, `PASS`)
  - `prove -I perl t` (`Files=12`, `Tests=322`, `PASS`)
- Immediate next direction after commit:
  - continue on the live phase-1 seam rather than reopening cleanup-only work,
  - the next likely move is to narrow `Orchestrator`’s remaining direct dependence on assignment-node traversal semantics, if any final capture preparation can move under `EnableGraph` without making the flow less clear.
## 2026-03-13: FlattenedDT live ownership micro-slice (EnableGraph capture-shape normalization)
- Current worktree continues the same live phase-1 ownership seam after capture-registry mutation moved under `EnableGraph`.
- Scope of this slice:
  - `perl/FSM/Synthesis/EnableGraph.pm` now also owns the remaining capture-shape normalization used by assignment capture,
  - `extract_signal_name_from_ast(...)` is broadened to recover the leading identifier from AST renderings like indexed references,
  - new `extract_rhs_capture_value(...)` owns the recursive RHS-to-captured-text normalization for literals, signal refs, binary ops, and concatenations,
  - `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` now calls those owner-local helpers and no longer keeps local `extract_lhs_name_from_ast(...)` / `extract_rhs_from_expression(...)` helpers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `prove -I perl t/12-enablegraph-capture-registry.t t/11-flatteneddt-generation-reset.t` (`Files=2`, `Tests=31`, `PASS`)
  - `prove -I perl t` (`Files=12`, `Tests=314`, `PASS`)
- Immediate next direction after commit:
  - continue on the live phase-1 seam rather than reopening wrapper cleanup,
  - the next likely move is to narrow `Orchestrator`’s remaining direct knowledge of assignment-node capture semantics, especially operator/intent extraction if that can be moved without widening risk.
## 2026-03-13: FlattenedDT live ownership micro-slice (EnableGraph capture-registry ownership)
- Current worktree continues on the live `Orchestrator` / `EnableGraph` seam instead of returning to cleanup-only work.
- Scope of this slice:
  - `perl/FSM/Synthesis/EnableGraph.pm` now owns mutation of the captured assignment/transition registries through `register_assignment_capture(...)` and `register_transition_capture(...)`,
  - `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` still performs traversal, AST condition assembly, RHS extraction, and operator validation,
  - but the actual writes into `lhs_assignments`, `all_lhs`, and `lhs_ast_map` now go through `EnableGraph`, which is the module that later consumes those registries to build `assignment_analysis`.
- New regression coverage:
  - `t/12-enablegraph-capture-registry.t` generates a small two-state FSM and asserts that:
    - ordinary captured assignments remain AST-backed,
    - `next_state` transition capture is still registered with `state_transition` metadata,
    - synthetic `next_state` AST registration still occurs,
    - and generated HDL still emits the expected state-enable and assignment-enable logic.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `prove -I perl t/12-enablegraph-capture-registry.t` (`Files=1`, `Tests=18`, `PASS`)
  - `prove -I perl t` (`Files=12`, `Tests=314`, `PASS`)
- Immediate next direction after commit:
  - continue along the live phase-1 ownership seam instead of revisiting facade cleanup,
  - the next likely move is to narrow the remaining direct `Orchestrator` dependency on capture-shape details such as local LHS/RHS extraction or condition-stack-to-capture assembly.
## 2026-03-13: FlattenedDT live-state reset micro-slice (per-run generation reset + enable-registry ownership)
- Current worktree moves back onto a live ownership seam instead of more facade cleanup.
- Scope of this slice:
  - `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` now resets per-run generation state at the start of `generate_systemverilog(...)`,
  - the reset clears stale run-local registries (`state_enables`, `dt_enables`, `lhs_assignments`, `all_lhs`, `lhs_ast_map`, `assignment_analysis`, `intermediate_signals`, `referenced_intermediate_signals`, `global_expressions`, `expression_usage`, `declared_port_signals`, `port_directions`) and drops transient scratch (`binary_logical_op_counts`, `ast_factorizer`, cached `fsm_module`),
  - `perl/FSM/Synthesis/EnableGraph.pm` now owns state/DT enable-registry initialization via `initialize_state_and_dt_enable_conditions(...)`,
  - `Orchestrator::flatten_all_decision_trees(...)` now relies on `EnableGraph` for enable-registry seeding and only performs traversal/recording.
- New regression coverage:
  - `t/11-flatteneddt-generation-reset.t` reuses one `FSM::HDL::FlattenedDT` object across two distinct FSMs and asserts the second run does not leak first-run DT enables, assignment captures, assignment analysis, or HDL signal names.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `prove -I perl t/11-flatteneddt-generation-reset.t` (`Files=1`, `Tests=13`, `PASS`)
  - `prove -I perl t` (`Files=11`, `Tests=296`, `PASS`)
- Immediate next direction after commit:
  - keep the cleanup lane closed unless a future audit finds new genuinely dead supported surface,
  - continue on the next live AST/CoreAST-first seam inside the remaining `Orchestrator` / `EnableGraph` / backend data flow, most likely around assignment-capture or enable-structure state ownership.
## 2026-03-13: FlattenedDT cleanup micro-slice (retire residual analysis/declaration facade delegates)
- Current worktree removes the last residual analysis/declaration helper pocket from the `FlattenedDT` facade.
- Scope remains a small behavior-preserving cleanup slice:
  - repo-wide call-graph auditing showed `generate_internal_signal_declarations(...)`, `get_lhs_width_from_analysis(...)`, `is_register(...)`, `fallback_register_analysis_from_assignments(...)`, `generate_intermediate_signals(...)`, `get_pulse_delay_cycles_for_lhs(...)`, `get_pulse_active_level_for_lhs(...)`, and `get_signal_info(...)` had no remaining callers on the `FlattenedDT` facade,
  - the matching methods remain live on `EnableGraph` or `Backend::SystemVerilog`, and the active flow already reaches them directly there,
  - `get_signal_assignment_type(...)` stays on the facade because `t/03-assignment-intent-metadata.t` still exercises it as part of the tested public surface,
  - `t/10-ast-first-enable-structure.t` now asserts that live `FlattenedDT` objects no longer expose those analysis/declaration helper names.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=137`, `PASS`)
  - `prove -I perl t` (`Files=10`, `Tests=283`, `PASS`)
- Immediate next direction after commit:
  - treat the wrapper-pruning lane as effectively exhausted unless a future audit finds a new genuinely dead supported surface,
  - pivot back to the next live AST/CoreAST-first ownership seam from the remaining active `Orchestrator` / `EnableGraph` / backend interactions.
## 2026-03-13: FlattenedDT cleanup micro-slice (retire dead backend factorization/substitution facade delegates)
- Current worktree removes a dead backend factorization/substitution helper pocket from the `FlattenedDT` facade.
- Scope remains a small behavior-preserving cleanup slice:
  - repo-wide call-graph auditing showed `prescan_wen_en_for_intermediate_signals(...)`, `feed_asts_to_factorizer(...)`, `count_unary_negations_in_original_expressions(...)`, `ast_contains_signal(...)`, `update_original_asts_with_substituted_versions(...)`, `run_second_pass_factorization(...)`, `feed_current_asts_to_second_pass(...)`, `ast_contains_intermediate_signals(...)`, `ast_has_intermediate_signals_recursive(...)`, `update_original_asts_with_second_pass_substitutions(...)`, `get_substituted_ast_for_signal(...)`, `is_signal_referenced_in_substitutions(...)`, and `topologically_sort_signals(...)` had no remaining callers on the `FlattenedDT` facade,
  - the matching methods remain live in `Backend::SystemVerilog`, and the active path already reaches them directly from `Orchestrator`, `FSM::HDL::Factorization::Fixpoint`, or backend-local calls,
  - `t/10-ast-first-enable-structure.t` now asserts that live `FlattenedDT` objects no longer expose those backend-owned factorization/substitution helper names.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=129`, `PASS`)
  - `prove -I perl t` (`Files=10`, `Tests=275`, `PASS`)
- Immediate next direction after commit:
  - rerun the remaining facade audit and confirm whether any `FlattenedDT` wrappers still form a coherent dead pocket,
  - if not, stop the cleanup lane and pivot back to the next live AST/CoreAST-first ownership seam.
## 2026-03-13: FlattenedDT cleanup micro-slice (retire dead utility/rendering facade delegates)
- Current worktree removes a dead `EnableGraph` utility/rendering helper pocket from the `FlattenedDT` facade.
- Scope remains a small behavior-preserving cleanup slice:
  - repo-wide call-graph auditing showed `generate_ast_based_signal_name(...)`, `extract_signal_name_from_ast(...)`, `map_operator_to_name(...)`, `is_arithmetic_operation(...)`, `is_logical_operation(...)`, `should_factor_logical_operation(...)`, `contains_frequently_used_operations(...)`, `get_driven_signals(...)`, `track_ast_intermediate_signals(...)`, `is_intermediate_signal(...)`, `is_signal_ast_based_intermediate(...)`, `_ast_contains_factorizable_operators(...)`, `_signal_name_indicates_ast_operators(...)`, `ast_to_systemverilog(...)`, `_ast_to_systemverilog_internal(...)`, `_render_binary_op(...)`, `_render_unary_op(...)`, `_choose_operator_symbol(...)`, `_operand_is_single_bit(...)`, `_signal_is_single_bit(...)`, `_get_operator_precedence(...)`, `_needs_parentheses(...)`, `_map_binary_operator(...)`, `_map_unary_operator(...)`, `_operand_needs_parens_for_negation(...)`, and `get_intermediate_signal_expression(...)` had no remaining callers on the `FlattenedDT` facade,
  - the matching methods remain live in `EnableGraph`, so the facade delegates were dead compatibility surface rather than a real ownership seam,
  - `get_signal_assignment_type(...)` stays on the facade because `t/03-assignment-intent-metadata.t` still exercises it as part of the tested public surface,
  - `t/10-ast-first-enable-structure.t` now asserts that live `FlattenedDT` objects no longer expose those utility/rendering helper names.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t/03-assignment-intent-metadata.t` (`Files=1`, `Tests=62`, `PASS`)
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=116`, `PASS`)
  - `prove -I perl t` (`Files=10`, `Tests=262`, `PASS`)
- Immediate next direction after commit:
  - re-run the remaining facade audit and confirm whether any wrappers are still truly dead rather than just thin compatibility veneers,
  - if the cleanup lane is no longer yielding coherent dead pockets, pivot back to the next live AST/CoreAST-first ownership seam.
## 2026-03-13: FlattenedDT cleanup micro-slice (retire dead orchestrator/backend facade pocket)
- Current worktree removes a dead orchestrator/backend helper pocket from the `FlattenedDT` facade.
- Scope remains a small behavior-preserving cleanup slice:
  - repo-wide call-graph auditing showed `flatten_all_decision_trees(...)`, `extract_lhs_name_from_ast(...)`, `flatten_decision_tree(...)`, `generate_header(...)`, `generate_module_declaration(...)`, `generate_state_encoding(...)`, `generate_state_register(...)`, `generate_enable_conditions(...)`, `generate_consolidated_intermediate_signals(...)`, `generate_wen_en_signals(...)`, `record_assignment_from_ast(...)`, `record_transition_from_ast(...)`, and `extract_rhs_from_expression(...)` had no remaining callers on the `FlattenedDT` facade,
  - the matching orchestrator/backend methods are still live and are now reached directly from `Orchestrator` or `backend_sv`, so the facade delegates were dead compatibility surface rather than a real ownership seam,
  - `t/10-ast-first-enable-structure.t` now asserts that live `FlattenedDT` objects no longer expose those orchestrator/backend-owned helper names.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=90`, `PASS`)
  - `prove -I perl t` (`Files=10`, `Tests=236`, `PASS`)
- Immediate next direction after commit:
  - rerun the facade audit; if the remaining wrappers are only legacy utility veneers and no longer form a compelling dead pocket, stop the cleanup lane,
  - pivot back to the next live AST/CoreAST-first ownership seam.
## 2026-03-13: FlattenedDT cleanup micro-slice (retire dead EnableGraph facade delegates)
- Current worktree removes a dead `EnableGraph`-owned helper pocket from the `FlattenedDT` facade.
- Scope remains a small behavior-preserving cleanup slice:
  - repo-wide call-graph auditing showed `normalize_rhs_logic_level(...)`, `get_reset_value(...)`, `get_fsm_reset_state(...)`, `get_explicit_reset_value(...)`, `set_fsm_module_reference(...)`, `get_default_value_from_ast(...)`, `get_reset_value_from_ast(...)`, `get_default_value(...)`, `convert_condition_to_ast(...)`, and `convert_test_value_to_ast(...)` had no remaining callers on the `FlattenedDT` facade,
  - the matching `EnableGraph` methods are still live and are now reached directly from `EnableGraph` itself or from `Orchestrator`, so the facade delegates were dead compatibility surface rather than a real ownership seam,
  - `t/10-ast-first-enable-structure.t` now asserts that live `FlattenedDT` objects no longer expose those `EnableGraph`-owned helper names.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=77`, `PASS`)
  - `prove -I perl t` (`Files=10`, `Tests=223`, `PASS`)
- Immediate next direction after commit:
  - rerun the remaining facade audit one last time; if it is finally empty, stop the cleanup lane,
  - pivot back to the next live AST/CoreAST-first ownership seam rather than continuing wrapper pruning.
## 2026-03-13: FlattenedDT cleanup micro-slice (retire dead logical-op facade delegates)
- Current worktree removes a dead logical-operation helper pocket from the `FlattenedDT` facade.
- Scope remains a small behavior-preserving cleanup slice:
  - repo-wide call-graph auditing showed `run_global_ast_factorization(...)`, `collect_all_wen_en_ast_expressions(...)`, `count_binary_logical_operation_occurrences(...)`, `_count_logical_ops_in_ast(...)`, and `_is_factorizable_sub_expression(...)` had no remaining callers on the `FlattenedDT` facade,
  - the matching backend methods are still live and still used internally by `Backend::SystemVerilog` and `Orchestrator`, so the facade delegates were dead compatibility surface rather than a real ownership seam,
  - `t/10-ast-first-enable-structure.t` now asserts that live `FlattenedDT` objects no longer expose those backend-internal logical-op helper names.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=67`, `PASS`)
  - `prove -I perl t` (`Files=10`, `Tests=213`, `PASS`)
- Immediate next direction after commit:
  - re-run the remaining facade audit one last time to confirm whether any meaningful dead delegates still remain,
  - if not, stop the cleanup lane and pivot back to the next live AST/CoreAST-first ownership seam.
## 2026-03-13: FlattenedDT cleanup micro-slice (retire dead filtering facade delegates)
- Current worktree removes a dead facade-only filtering helper pocket from `perl/FSM/HDL/FlattenedDT.pm`.
- Scope remains a small behavior-preserving cleanup slice:
  - repo-wide call-graph auditing showed `should_filter_consolidated_signal(...)`, `should_filter_ast_based(...)`, `is_simple_negation(...)`, `is_simple_comparison(...)`, and `is_signal_actually_used_in_final_expressions(...)` had no remaining callers on the `FlattenedDT` facade,
  - the matching backend methods are still live, but only as backend-internal helpers, so keeping the `FlattenedDT` delegates exposed a dead compatibility surface rather than a real ownership seam,
  - `t/10-ast-first-enable-structure.t` now asserts that live `FlattenedDT` objects no longer expose those backend-internal helper names.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=62`, `PASS`)
  - `prove -I perl t` (`Files=10`, `Tests=208`, `PASS`)
- Immediate next direction after commit:
  - re-run the remaining `FlattenedDT` facade / backend audit one last time to see whether any final dead delegates remain,
  - if the facade audit is now empty, pivot back to the next live AST/CoreAST-first ownership seam.
## 2026-03-13: FlattenedDT/backend cleanup micro-slice (retire dead mux/simple helper pocket)
- Current worktree removes a dead backend-wrapper pocket from `perl/FSM/HDL/FlattenedDT.pm` and `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- Scope remains a small behavior-preserving cleanup slice:
  - repo-wide call-graph auditing showed `is_simple_ast_expression(...)`, `generate_comb_mux(...)`, and `generate_flop_mux(...)` had no remaining callers anywhere in the active tree,
  - the two mux helpers still referenced long-retired `lhs_to_enable_value_pairs` state, which confirmed they were stranded compatibility residue rather than dormant live behavior,
  - `t/10-ast-first-enable-structure.t` now asserts that live `FlattenedDT` and backend `SystemVerilog` objects no longer expose those dead helper names.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=57`, `PASS`)
  - `prove -I perl t` (`Files=10`, `Tests=203`, `PASS`)
- Immediate next direction after commit:
  - run one more narrow audit on the remaining `FlattenedDT` facade / backend delegate edge for any final dead wrapper residue,
  - if that audit comes up empty, pivot back to the next live AST/CoreAST-first ownership seam instead of stretching the cleanup lane further.
## 2026-03-13: FlattenedDT/EnableGraph cleanup micro-slice (retire dead AST helper pocket)
- Current worktree removes a dead AST helper pocket from `perl/FSM/HDL/FlattenedDT.pm` and `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a small behavior-preserving cleanup slice:
  - repo-wide call-graph auditing showed `get_or_create_ast_signal_name(...)`, `canonicalize_expression(...)`, `is_complex_ast(...)`, `should_factor_ast(...)`, `analyze_ast_complexity(...)`, and `_traverse_ast_for_complexity(...)` had no remaining callers anywhere in the active tree,
  - `is_complex_ast(...)` and `_traverse_ast_for_complexity(...)` were only still alive through dead owner-local callers inside that same pocket, so removing the whole pocket together is safer than leaving a partially stranded cluster,
  - `t/10-ast-first-enable-structure.t` now asserts that live `FlattenedDT` and `EnableGraph` objects no longer expose those dead helper names.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=51`, `PASS`)
  - `prove -I perl t` (`Files=10`, `Tests=197`, `PASS`)
- Immediate next direction after commit:
  - continue the narrow dead-surface audit on the remaining `FlattenedDT` facade / backend delegate edge, especially small backend-owned wrappers like dead mux/factorization helpers,
  - if that audit comes up empty, switch back to the next live AST/CoreAST-first ownership seam instead of forcing more cleanup-only slices.
## 2026-03-13: FlattenedDT/backend cleanup micro-slice (retire dead sub-expression analysis helpers)
- Current worktree removes a small dead sub-expression analysis pocket from `perl/FSM/HDL/FlattenedDT.pm` and `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- Scope remains a small behavior-preserving cleanup slice:
  - repo-wide call-graph auditing showed `analyze_ast_sub_expressions(...)` had no remaining callers anywhere in the active tree,
  - that method was the only caller of `find_all_ast_sub_expressions(...)`, so the pair formed a self-contained dead helper island rather than a live backend seam,
  - `t/10-ast-first-enable-structure.t` now asserts that live `FlattenedDT` and backend `SystemVerilog` objects no longer expose those dead helper names.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=185`, `PASS`)
  - `prove -I perl t` (`Files=10`, `Tests=185`, `PASS`)
- Immediate next direction after commit:
  - run one more narrow audit on the remaining `FlattenedDT` facade / backend delegate edge for any final provably dead residue,
  - if that audit comes up empty, switch back to the next live AST/CoreAST-first ownership seam instead of forcing more cleanup-only pruning.
## 2026-03-13: EnableGraph cleanup micro-slice (retire dead owner-only helper pocket)
- Current worktree removes a small owner-only dead helper pocket from `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a small behavior-preserving cleanup slice:
  - repo-wide call-graph auditing showed `get_or_create_global_expression(...)`, `should_factor_condition(...)`, `needs_parentheses(...)`, and `signal_uses_register_assignment(...)` had no remaining callers anywhere in the active tree,
  - these names were no longer mirrored by live `FlattenedDT` delegates and no longer described an active ownership boundary, so leaving them in `EnableGraph` only preserved uncalled compatibility residue,
  - `t/10-ast-first-enable-structure.t` now asserts that live `EnableGraph` objects no longer expose that dead owner-only helper surface.
- Validation is green so far for this slice:
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=35`, `PASS`)
  - `prove -I perl t` (`Files=10`, `Tests=181`, `PASS`)
- Immediate next direction after commit:
  - re-audit the remaining `FlattenedDT` / `EnableGraph` edge one more time to decide whether the dead-surface cleanup lane is actually exhausted,
  - if no more dead residue remains, switch back to the next live AST/CoreAST-first ownership seam.
## 2026-03-13: FlattenedDT cleanup micro-slice (retire dead orphan helper pocket)
- Current worktree removes a small dead helper pocket from both `perl/FSM/HDL/FlattenedDT.pm` and `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a small behavior-preserving cleanup slice:
  - repo-wide call-graph auditing showed `create_condition_expression_signal_name(...)`, `set_explicit_reset_values(...)`, `parentheses_are_redundant(...)`, and `generate_expression_from_signal_name(...)` had no remaining callers anywhere in the active tree,
  - the matching `FlattenedDT` compatibility delegates and `EnableGraph` owner methods are gone together, rather than leaving dead definitions stranded on one side,
  - `t/10-ast-first-enable-structure.t` now asserts that live `FlattenedDT` and `EnableGraph` objects no longer expose that dead helper surface.
- Validation is green so far for this slice:
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=31`, `PASS`)
  - `prove -I perl t` (`Files=10`, `Tests=177`, `PASS`)
- Immediate next direction after commit:
  - continue re-auditing the remaining `FlattenedDT` / `EnableGraph` compatibility edge for any last dead helper residue,
  - if the dead-surface lane is now exhausted, switch back to the next live AST/CoreAST-first ownership seam.
## 2026-03-13: FlattenedDT cleanup micro-slice (retire dead unified helper delegates)
- Current worktree removes a dead unified-analysis / unified-emission helper delegate pocket from `perl/FSM/HDL/FlattenedDT.pm`.
- Scope remains a small behavior-preserving cleanup slice:
  - repo-wide call-graph auditing showed the live phase-1/2/3 path now runs directly through `Orchestrator -> EnableGraph` and no longer uses the matching `FlattenedDT` facade delegates,
  - removed dead facade wrappers for `build_unified_assignment_analysis(...)`, `group_assignments_by_rhs(...)`, `generate_complete_enable_structure(...)`, `build_multiplexer_config(...)`, `generate_unified_wen_en_signals(...)`, `generate_dt_enables_from_analysis(...)`, `generate_lhs_enables_from_analysis(...)`, `generate_signal_assignments(...)`, `generate_unified_flop_mux(...)`, `generate_unified_pulse_delay_logic(...)`, `signal_uses_register_assignment(...)`, and `generate_unified_comb_mux(...)`,
  - `t/10-ast-first-enable-structure.t` now asserts that live `FlattenedDT` objects no longer expose that dead unified helper surface.
- Validation is green so far for this slice:
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=23`, `PASS`)
  - `prove -I perl t` (`Files=10`, `Tests=169`, `PASS`)
- Immediate next direction after commit:
  - continue re-auditing the remaining `FlattenedDT` facade delegates for any final dead surface that only mirrors direct `EnableGraph` / backend ownership,
  - if the dead-surface audit is exhausted, pivot back to the next smallest live AST/CoreAST-first ownership seam.
## 2026-03-13: FlattenedDT cleanup micro-slice (retire dead signal-AST facade helper)
- Current worktree removes the dead `get_signal_ast_node(...)` helper from `perl/FSM/HDL/FlattenedDT.pm` and drops the now-unused `FSM::GlobalASTManager`, `FSM::AST::Node`, and `FSM::CoreAST` imports from the same facade.
- Scope remains a small behavior-preserving cleanup slice:
  - repo-wide call-graph auditing showed `get_signal_ast_node(...)` had no callers anywhere in the active tree,
  - the helper depended on a stale `fsm_module` slot that is not part of the live AST/CoreAST generation path,
  - `t/10-ast-first-enable-structure.t` now asserts that live generation no longer exposes that dead helper on the `FlattenedDT` facade.
- Validation is green so far for this slice:
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` (`Files=1`, `Tests=11`, `PASS`)
  - `prove -I perl t` (`Files=10`, `Tests=157`, `PASS`)
- Immediate next direction after commit:
  - continue re-auditing the remaining `FlattenedDT` facade for truly dead delegates or stale state assumptions before taking more cleanup-only slices,
  - if that dead-surface audit runs dry, return to the next smallest live AST/CoreAST-first ownership seam instead of forcing more facade-only pruning.
## 2026-03-11: Backend convergence micro-slice (EnableGraph/SystemVerilog defining-AST metadata for consolidated filtering)
- Current worktree carries native defining-AST metadata forward on the live consolidated intermediate filtering path.
- Scope remains a small behavior-preserving AST-first slice:
  - `track_ast_intermediate_signals()` now stores `reference_ast` separately and records a native `defining_ast` when one already exists,
  - the backend now resolves defining ASTs through `resolve_intermediate_signal_defining_ast()` before reparsing expressions,
  - prescan-referenced intermediate entries are merged into consolidated generation with cached defining-AST metadata.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue targeting the remaining expression-only compatibility cases on the consolidated path where AST-derived metadata is still absent,
  - keep prioritizing slices that remove live reparsing pressure over nearby but less active helper or registry cleanup.
## 2026-03-11: Backend convergence micro-slice (EnableGraph/SystemVerilog AST-first intermediate dependency extraction)
- Current worktree converts the live consolidated intermediate-signal dependency-discovery path from rendered-string scanning toward AST traversal.
- Scope remains a small behavior-preserving AST-first slice:
  - `EnableGraph` now exposes `extract_intermediate_signals_from_ast()` for recursive intermediate-reference recovery from ASTs,
  - consolidated dependency-map construction in `Backend/SystemVerilog` now uses defining ASTs when available instead of scanning rendered expressions first,
  - substituted-AST debug tracing now extracts referenced intermediates directly from the substituted AST,
  - pre-scan referenced signals are now seeded with defining ASTs through `get_intermediate_signal_ast()` when that AST is available,
  - string-based intermediate extraction remains only as a compatibility fallback after parse failure.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue targeting the remaining expression-only compatibility entries on the consolidated filtering path so runtime dependency/filtering logic sees native ASTs more consistently,
  - keep re-evaluating `get_or_create_global_expression()` against live call paths rather than assuming it is the next best seam from locality alone.
## 2026-03-11: Backend convergence micro-slice (EnableGraph AST-backed intermediate-signal registry metadata)
- Current worktree converts the live intermediate-signal registry/count/render path from string-backed ownership toward AST-backed metadata in `perl/FSM/Synthesis/EnableGraph.pm` and `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`.
- Scope remains a small behavior-preserving AST-first slice:
  - `get_or_create_ast_signal_name()` and `get_or_create_global_expression()` now record structured intermediate-signal registry entries with `ast`, `expression`, `name`, and `source` when an AST is available,
  - `is_signal_ast_based_intermediate()` and `get_intermediate_signal_ast()` now prefer native AST sources on the live path instead of reparsing `global_expressions` or raw registry strings first,
  - `get_intermediate_signal_expression()` no longer falls back to reconstructing logic from signal-name patterns,
  - `count_binary_logical_operation_occurrences()` now resolves native intermediate-signal ASTs through `EnableGraph` instead of reparsing stored registry strings.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - keep targeting live semantic compatibility fallbacks around intermediate-signal registration and lookup, especially places where `get_or_create_global_expression()` still seeds names from string parsing when no AST seed is present,
  - continue treating the older `FlattenedDT.pm` condition/value helpers as secondary until a slice can eliminate a live string dependency instead of only relocating it.
## 2026-03-11: Backend convergence micro-slice (EnableGraph AST-first logical-operation factor detection)
- Current worktree replaces a live string-based factorization-decision path in `perl/FSM/Synthesis/EnableGraph.pm` with AST-first traversal.
- Scope remains a small behavior-preserving AST-first slice:
  - `contains_frequently_used_operations()` now walks AST nodes and resolved intermediate-signal ASTs instead of scanning rendered expressions for operator substrings,
  - `get_intermediate_signal_ast()` now resolves defining ASTs from the AST factorizer and FSM-module signal metadata before falling back to compatibility parsing of string registries,
  - `get_intermediate_signal_expression()` now prefers rendering from a defining AST when one exists.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - keep targeting live algorithmic string dependencies rather than dormant helper residue,
  - likely next seams are the remaining compatibility fallbacks around intermediate-signal expression reconstruction and the older `FlattenedDT.pm` condition/value helpers only when they can be replaced by AST/CoreAST-native behavior instead of merely moved.
## 2026-03-11: Backend convergence micro-slice (EnableGraph redundant-parentheses helper ownership)
- Current worktree finishes the in-flight legacy string-expression parenthesis cleanup by moving `parentheses_are_redundant()` from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a small helper-ownership reduction step:
  - `parentheses_are_redundant()` now lives in `EnableGraph`,
  - `FlattenedDT` keeps a compatibility delegate for the helper,
  - no public backend entrypoint or active HDL emission call path changed in this slice.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Important architectural direction from the user:
  - this slice completes an already-started string-compatibility helper lane, but future convergence work should preferentially eliminate string-based algorithmic handling instead of continuing string-helper relocation by default,
  - target state is full AST/CoreAST-first algorithms with an AST/CoreAST representation that is complete, flexible, general, extensible, elegant, and robust.
- Immediate next direction after commit:
  - update the roadmap plan so AST/CoreAST-first convergence is explicit,
  - re-scan `FlattenedDT.pm` for the next truthful AST/CoreAST-native slice, especially remaining string-based algorithmic helpers such as `extract_condition_string()` and adjacent formatting/condition paths only when they can be replaced by AST/CoreAST-native behavior rather than merely moved.
## 2026-03-11: Backend convergence micro-slice (EnableGraph expression sanitation helper ownership)
- Current worktree moves the legacy string-expression sanitation helper from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a small helper-ownership reduction step:
  - `clean_intermediate_expression()` now lives in `EnableGraph`,
  - `FlattenedDT` keeps a compatibility delegate for the helper,
  - no public backend entrypoint or active HDL emission call path changed in this slice.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - re-scan the remaining residual helper pockets in `FlattenedDT.pm` now that the nearby string-formatting lane has been reduced again,
  - treat `parentheses_are_redundant()` and the older condition-formatting helpers as possible next candidates only if they still form a similarly coherent ownership move,
  - keep preferring truthful ownership reduction over broad dormant cleanup.
## 2026-03-11: Backend convergence micro-slice (EnableGraph string parenthesis helper ownership)
- Current worktree moves the legacy string-expression parenthesis helper from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a small helper-ownership reduction step:
  - `needs_parentheses()` now lives in `EnableGraph`,
  - `FlattenedDT` keeps a compatibility delegate for the helper,
  - no public backend entrypoint or active HDL emission call path changed in this slice.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - re-scan the remaining nearby string-formatting helpers in `FlattenedDT.pm`,
  - treat `clean_intermediate_expression()` and the older `format_condition()` / `format_signal_expression()` lane as possible next candidates only if they still form a similarly coherent, truthful ownership reduction,
  - keep preferring small real boundary reductions over paper moves in dormant helper pockets.
## 2026-03-11: Backend convergence micro-slice (EnableGraph AST factorization-analysis helper ownership)
- Current worktree moves the AST factorization-analysis helper pair from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a small helper-ownership reduction step:
  - `is_complex_ast()` now lives in `EnableGraph`,
  - `should_factor_ast()` now lives in `EnableGraph`,
  - `FlattenedDT` keeps compatibility delegates for both helper names,
  - no public backend entrypoint or active HDL emission call path changed in this slice.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - keep re-scanning the remaining nearby legacy expression-formatting helpers in `FlattenedDT.pm`, with `needs_parentheses()` now the most plausible next lane,
  - consider adjacent formatting cleanup such as `clean_intermediate_expression()` only if it forms a similarly small coherent ownership move,
  - keep preferring small coherent ownership reductions over broad dormant cleanup.
## 2026-03-11: Backend convergence micro-slice (EnableGraph legacy condition-factorization helper ownership)
- Current worktree moves the legacy condition-factorization helper trio from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a small helper-ownership reduction step:
  - `should_factor_condition()` now lives in `EnableGraph`,
  - `analyze_ast_complexity()` now lives in `EnableGraph`,
  - `_traverse_ast_for_complexity()` now lives in `EnableGraph`,
  - `FlattenedDT` keeps compatibility delegates for the same helper names,
  - no public backend entrypoint or active HDL emission call path changed in this slice.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - keep re-scanning the remaining nearby legacy expression/factorization helpers in `FlattenedDT.pm`, with `needs_parentheses()` and adjacent formatting helpers still the most plausible next lane,
  - keep preferring small coherent ownership reductions over broad dormant cleanup.
## 2026-03-10: Backend convergence micro-slice (EnableGraph global-expression registry helper ownership)
- Current worktree moves the adjacent global-expression registry helper pair from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a small helper-ownership reduction step:
  - `get_or_create_global_expression()` now lives in `EnableGraph`,
  - `canonicalize_expression()` now lives in `EnableGraph`,
  - `FlattenedDT` keeps compatibility delegates for both helper names,
  - no public backend entrypoint or active HDL emission call path changed in this slice.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - keep re-scanning the remaining non-delegate utility pockets in `FlattenedDT.pm`, with adjacent legacy expression/factorization helpers still the most plausible next ownership lane,
  - keep preferring small coherent ownership reductions over speculative dormant cleanup.
## 2026-03-10: Backend convergence micro-slice (EnableGraph AST signal-naming helper ownership)
- Current worktree moves the AST signal-naming helper cluster from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a small helper-ownership reduction step:
  - `create_condition_expression_signal_name()`, `get_or_create_ast_signal_name()`, `generate_ast_based_signal_name()`, and `map_operator_to_name()` now live in `EnableGraph`,
  - `FlattenedDT` keeps compatibility delegates for the same helper names,
  - no public backend entrypoint or active HDL emission call path changed in this slice.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - re-scan the remaining non-delegate utility pockets in `FlattenedDT.pm` for the next small coherent owner, with nearby AST-support / legacy factorization helpers as the most plausible lane,
  - keep preferring truthful ownership reduction over speculative dormant cleanup that does not improve the active boundary.
## 2026-03-10: Backend convergence micro-slice (Verilog backend SystemVerilog-entry callsite convergence)
- Current worktree localizes the live `generate_systemverilog()` call in `perl/FSM/HDL/FlattenedDT/Backend/Verilog.pm` away from the `FlattenedDT` facade to direct `orchestrator` ownership.
- Scope remains a single orchestrator-boundary callsite convergence step:
  - `Backend::Verilog::generate_verilog()` now obtains SystemVerilog through `$ctx->{orchestrator}->generate_systemverilog(...)`,
  - the `FlattenedDT::generate_systemverilog()` compatibility delegate remains unchanged for non-local callers,
  - no Verilog conversion semantics or orchestrator ownership changed in this slice.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/Verilog.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - re-scan the broader orchestrator/facade boundary now that the obvious `Backend::Verilog` round-trip is localized,
  - keep preferring live round-trip convergence over dormant compatibility delegate cleanup in `FlattenedDT.pm`.
## 2026-03-10: Backend convergence micro-slice (Fixpoint second-pass update callsite convergence)
- Current worktree localizes the live `update_original_asts_with_second_pass_substitutions()` call in `perl/FSM/HDL/Factorization/Fixpoint.pm` away from the `FlattenedDT` facade to direct `backend_sv` ownership.
- Scope remains a single second-pass factorization callsite convergence step:
  - `run_post_substitution_factorization()` now applies second-pass AST updates through `$ctx->{backend_sv}->update_original_asts_with_second_pass_substitutions(...)`,
  - the `FlattenedDT::update_original_asts_with_second_pass_substitutions()` compatibility delegate remains unchanged for any non-local callers,
  - the direct `Fixpoint` second-pass callsite lane now appears exhausted.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/Factorization/Fixpoint.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - re-scan the broader factorization/backend facade boundaries now that the direct `Fixpoint` second-pass lane is exhausted,
  - keep preferring live round-trip convergence over dormant compatibility delegate cleanup in `FlattenedDT.pm`.
## 2026-03-10: Backend convergence micro-slice (Fixpoint second-pass feed callsite convergence)
- Current worktree localizes the live `feed_current_asts_to_second_pass()` call in `perl/FSM/HDL/Factorization/Fixpoint.pm` away from the `FlattenedDT` facade to direct `backend_sv` ownership.
- Scope remains a single second-pass factorization callsite convergence step:
  - `run_post_substitution_factorization()` now feeds post-substitution ASTs through `$ctx->{backend_sv}->feed_current_asts_to_second_pass(...)`,
  - the `FlattenedDT::feed_current_asts_to_second_pass()` compatibility delegate remains unchanged for any non-local callers,
  - no second-pass update or render ownership changed in this slice.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/Factorization/Fixpoint.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - localize the matching live `update_original_asts_with_second_pass_substitutions(...)` call in `Fixpoint.pm`, which is now the obvious adjacent second-pass round-trip still routed through `FlattenedDT`,
  - keep `FlattenedDT` as the compatibility shell while continuing one callsite at a time.
## 2026-03-10: Backend convergence micro-slice (SystemVerilog prescan intermediate-tracking callsite convergence)
- Current worktree localizes the two live `track_ast_intermediate_signals()` callsites in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` away from the `FlattenedDT` facade to direct `EnableGraph` ownership.
- Scope remains a single backend-prescan callsite convergence step:
  - DT-specific enable pre-scan tracking now goes through `$ctx->{enable_graph}->track_ast_intermediate_signals(...)`,
  - LHS-level enable pre-scan tracking now goes through the same direct `EnableGraph` entry,
  - `FlattenedDT` helper/delegate ownership is unchanged in this slice.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - re-scan `perl/FSM/HDL/Factorization/Fixpoint.pm` for the remaining live second-pass helper round-trips through `FlattenedDT`, especially `feed_current_asts_to_second_pass(...)` and `update_original_asts_with_second_pass_substitutions(...)`,
  - keep `FlattenedDT` as the compatibility shell while continuing behavior-preserving live callsite convergence before dormant cleanup.
## 2026-03-10: Backend convergence micro-slice (Factorization Fixpoint AST-to-SV callsite convergence)
- Current worktree localizes the remaining non-local `ast_to_systemverilog()` callsites in `perl/FSM/HDL/Factorization/Fixpoint.pm` away from the `FlattenedDT` facade to direct `EnableGraph` entry ownership.
- Scope remains a single render/factorization callsite convergence step:
  - pass-level debug rendering of new second-pass intermediate signals now goes through `$ctx->{enable_graph}->ast_to_systemverilog(...)`,
  - `_build_expression_signature()` now uses the same `EnableGraph` render entry for pass-signature construction,
  - `FlattenedDT` helper/delegate ownership is unchanged in this slice.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/Factorization/Fixpoint.pm`
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - re-scan the remaining render/factorization callsites that still round-trip through `FlattenedDT`, with `find_substituted_ast()` and adjacent canonical-expression matching inside `FlattenedDT.pm` as the most obvious surviving AST-to-SV seam,
  - keep `FlattenedDT` as the compatibility shell while continuing behavior-preserving callsite convergence before broader delegate cleanup.
## 2026-03-09: Backend convergence micro-slice (EnableGraph binary operator-selection helper ownership)
- Current worktree moves `_choose_operator_symbol()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a single binary-support helper convergence step:
  - `FlattenedDT::_choose_operator_symbol()` is now a compatibility delegate to `enable_graph`,
  - `EnableGraph` now owns the full binary operator-selection lane on top of already-local precedence, operand-width, and operator-mapping helpers,
  - the binary-support helper ownership lane under the render cluster is now exhausted, while `FlattenedDT` remains the compatibility facade.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - re-scan the remaining render-cluster / facade-boundary seams now that binary-support helper ownership is fully localized in `EnableGraph`,
  - keep `FlattenedDT` as the compatibility shell while choosing the next smallest truthful non-binary-support slice.
## 2026-03-09: Backend convergence micro-slice (EnableGraph binary operand-width helper ownership)
- Current worktree moves `_operand_is_single_bit()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a single binary-support helper convergence step:
  - `FlattenedDT::_operand_is_single_bit()` is now a compatibility delegate to `enable_graph`,
  - `EnableGraph` now owns recursive operand single-bit classification on top of the already-local `_signal_is_single_bit()` helper,
  - `_choose_operator_symbol()` is now the next remaining binary-support helper on the operator-selection path.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - re-evaluate `_choose_operator_symbol()` as the next truthful binary-support seam now that operand-width analysis is local,
  - keep `FlattenedDT` as the compatibility facade while the final binary operator-selection helper is localized.
## 2026-03-09: Backend convergence micro-slice (EnableGraph binary signal-width helper ownership)
- Current worktree moves `_signal_is_single_bit()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a single binary-support helper convergence step:
  - `FlattenedDT::_signal_is_single_bit()` is now a compatibility delegate to `enable_graph`,
  - `EnableGraph` now owns single-bit signal classification, including FSM-module metadata access retargeted through `$self->{flattened_dt}`,
  - `_operand_is_single_bit()` and `_choose_operator_symbol()` remain as the next binary-support helpers on the heavier operand-analysis/operator-selection path.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - move `_operand_is_single_bit()` as the next truthful binary-support seam now that its `_signal_is_single_bit()` dependency is local,
  - then re-evaluate `_choose_operator_symbol()` once operand-width analysis is fully localized.
## 2026-03-09: Backend convergence micro-slice (EnableGraph binary AST-to-SV render helper ownership)
- Current worktree moves `_render_binary_op()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a single binary-render helper convergence step:
  - `FlattenedDT::_render_binary_op()` is now a compatibility delegate to `enable_graph`,
  - `EnableGraph` now owns binary AST rendering,
  - narrow compatibility delegates for `_get_operator_precedence()`, `_choose_operator_symbol()`, `_needs_parentheses()`, and `_operand_is_single_bit()` preserve behavior while the deeper binary-support helpers remain in `FlattenedDT`.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue with the smallest isolated binary-support helpers, most likely `_get_operator_precedence()` and/or `_needs_parentheses()` before the larger `_choose_operator_symbol()` path,
  - keep the compatibility facade in `FlattenedDT` intact until the binary-render cluster converges further.
## 2026-03-09: Backend convergence micro-slice (EnableGraph unary negation parenthesization helper ownership)
- Current worktree moves `_operand_needs_parens_for_negation()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a single unary-support helper convergence step:
  - `FlattenedDT::_operand_needs_parens_for_negation()` is now a compatibility delegate to `enable_graph`,
  - `EnableGraph` now owns the full unary-render support lane,
  - no binary-render helper ownership changed in this slice.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - unary-support delegates are now exhausted,
  - re-scan the larger binary-render cluster starting at `_render_binary_op()` and its adjacent precedence/operator helpers for the next truthful micro-slice.
## 2026-03-09: Backend convergence micro-slice (EnableGraph unary operator mapping helper ownership)
- Current worktree moves `_map_unary_operator()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a single unary-support helper convergence step:
  - `FlattenedDT::_map_unary_operator()` is now a compatibility delegate to `enable_graph`,
  - `EnableGraph` now owns unary operator symbol mapping,
  - `_operand_needs_parens_for_negation()` remains the last isolated unary-support delegate before the larger binary-render cluster.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - move `_operand_needs_parens_for_negation()` as the remaining unary-support helper seam,
  - then re-evaluate the larger `_render_binary_op()` cluster for the next truthful micro-slice.
## 2026-03-09: Backend convergence micro-slice (EnableGraph unary AST-to-SV render helper ownership)
- Current worktree moves `_render_unary_op()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a single render-helper convergence step:
  - `FlattenedDT::_render_unary_op()` is now a compatibility delegate to `enable_graph`,
  - `EnableGraph` now owns unary AST rendering,
  - narrow compatibility delegates for `_map_unary_operator()` and `_operand_needs_parens_for_negation()` preserve behavior while those unary-support helpers still live in `FlattenedDT`.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue with the smallest remaining unary-support helper delegates, most likely `_map_unary_operator()` before `_operand_needs_parens_for_negation()`,
  - keep deferring the broader `_render_binary_op()` cluster until the smaller unary-adjacent seams are exhausted.
## 2026-03-09: Backend convergence micro-slice (EnableGraph AST-to-SV internal helper ownership)
- Current worktree moves `_ast_to_systemverilog_internal()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`.
- Scope remains a single render-boundary helper convergence step:
  - `FlattenedDT::_ast_to_systemverilog_internal()` is now a compatibility delegate to `enable_graph`,
  - `EnableGraph` now owns the recursive AST-to-SystemVerilog dispatcher,
  - temporary compatibility delegates for `_render_binary_op()` and `_render_unary_op()` keep the deeper render cluster behavior-preserving for now.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue with the smallest adjacent render helper still round-tripping through `FlattenedDT`, most likely `_render_unary_op()` before the larger `_render_binary_op()` path,
  - keep the compatibility facade in `FlattenedDT` intact until the render cluster converges further.
## 2026-03-09: Backend convergence micro-slice (EnableGraph AST-to-SV internal delegate callsite convergence)
- Current worktree localizes the `ast_to_systemverilog()` render-internal callsite in `perl/FSM/Synthesis/EnableGraph.pm` away from a direct `FlattenedDT` object method reach-in.
- Scope remains a single active runtime callsite convergence step:
  - `ast_to_systemverilog()` now routes through `$self->_ast_to_systemverilog_internal(...)`,
  - the new `EnableGraph` compatibility delegate still forwards to `FlattenedDT`'s `_ast_to_systemverilog_internal(...)`,
  - deeper render-helper ownership remains unchanged for this slice.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - if this render-boundary lane continues, the next truthful seam is the heavier `_ast_to_systemverilog_internal()` helper family itself together with the adjacent render/precedence/operator helpers it depends on,
  - keep preferring behavior-preserving slices over broad render-cluster moves.
## 2026-03-09: Backend convergence micro-slice (EnableGraph LHS-enable intermediate tracking callsite convergence)
- Current worktree localizes the `track_ast_intermediate_signals()` callsite in `perl/FSM/Synthesis/EnableGraph.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` self ownership.
- Scope remains a single active runtime callsite convergence step:
  - `generate_lhs_enables_from_analysis()` now tracks intermediate signals through `$self->track_ast_intermediate_signals(...)`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - the same-pattern direct self-owned round-trips inside `EnableGraph.pm` now appear exhausted,
  - re-scan for the next smallest behavior-preserving seam, with the remaining direct `EnableGraph` -> `FlattenedDT` method dependency currently narrowed to `ast_to_systemverilog()` calling `_ast_to_systemverilog_internal(...)`.
## 2026-03-09: Backend convergence micro-slice (EnableGraph mux-config callsite convergence)
- Current worktree localizes the phase-1 `build_multiplexer_config()` callsite in `perl/FSM/Synthesis/EnableGraph.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` self ownership.
- Scope remains a single active phase-1 analysis callsite convergence step:
  - `build_unified_assignment_analysis()` now assembles multiplexer config through `$self->build_multiplexer_config(...)`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue with the next smallest remaining direct self-owned round-trip in `EnableGraph`, currently the `track_ast_intermediate_signals()` callsite in `generate_lhs_enables_from_analysis()`,
  - keep prioritizing live helper-family self-localization over dormant compatibility cleanup.
## 2026-03-09: Backend convergence micro-slice (EnableGraph enable-structure callsite convergence)
- Current worktree localizes the phase-1 `generate_complete_enable_structure()` callsite in `perl/FSM/Synthesis/EnableGraph.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` self ownership.
- Scope remains a single active phase-1 analysis callsite convergence step:
  - `build_unified_assignment_analysis()` now generates enable structures through `$self->generate_complete_enable_structure(...)`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue with the adjacent phase-1 analysis round-trip, most likely the `build_multiplexer_config()` callsite in `build_unified_assignment_analysis()`,
  - keep prioritizing live helper-family self-localization over dormant compatibility cleanup.
## 2026-03-09: Backend convergence micro-slice (EnableGraph RHS-grouping callsite convergence)
- Current worktree localizes the phase-1 `group_assignments_by_rhs()` callsite in `perl/FSM/Synthesis/EnableGraph.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` self ownership.
- Scope remains a single active phase-1 analysis callsite convergence step:
  - `build_unified_assignment_analysis()` now groups RHS assignments through `$self->group_assignments_by_rhs(...)`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue with the adjacent phase-1 analysis round-trip, most likely the `generate_complete_enable_structure()` callsite in `build_unified_assignment_analysis()`,
  - keep prioritizing live helper-family self-localization over dormant compatibility cleanup.
## 2026-03-08: Local CI entrypoint + workflow unification
- Current worktree routes `.github/workflows/regression.yml` through a shared repo script, `bin/ci-regression`, so the same CI logic can be run locally before push without depending on GitHub-hosted execution.
- Scope of this slice:
  - added `bin/ci-regression`, which resolves the repository root itself and runs `prove -I perl t`,
  - removed the discarded Rust-specific `check-rust-include-paths` guard after confirming this repository’s active CI path is Perl-only,
  - updated `.github/workflows/regression.yml` to call the shared script instead of inlining a narrower one-test command,
  - documented the local pre-push entrypoint in `README.md`.
- Validation is green for this slice:
  - `bash -lc 'cd /tmp && /Users/richarddje/Documents/github/fsmgen/bin/ci-regression'`
  - result: full regression passed (`Files=6`, `Tests=125`, `PASS`)
  - audited tracked `.github`, `bin`, `perl`, `t`, `README.md`, and `docs` content for active references to untracked `fx/`, `plugin/`, `specs/`, or machine-specific `/Users/...` paths and found none.
- Important current-state note:
  - `bin/ci-regression` is the only new active CI file that needed to be brought under git control,
  - the remaining untracked `fx/` tree is not referenced by the active workflow/runtime/test path and is therefore not a current GitHub CI dependency.
- Immediate next direction after commit:
  - if more CI automation is added later, keep routing it through repo-owned scripts so local and GitHub execution stay aligned,
  - keep re-checking active tracked workflow/runtime/test references whenever new untracked trees or helper scripts are introduced.
## 2026-03-08: Backend convergence micro-slice (Orchestrator signal-assignment callsite convergence)
- Current worktree localizes the stage-8 `generate_signal_assignments()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` ownership.
- Scope remains a single active stage-level callsite convergence step:
  - `generate_systemverilog()` now emits final signal assignments through `$ctx->{enable_graph}->generate_signal_assignments(...)`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - re-scan the remaining live `FlattenedDT` facade round-trips now that the active `generate_systemverilog()` stage chain is fully localized,
  - prioritize the next smallest behavior-preserving runtime seam rather than removing dormant compatibility delegates.
## 2026-03-08: Backend convergence micro-slice (Orchestrator WEN/EN-signal callsite convergence)
- Current worktree localizes the stage-7 `generate_wen_en_signals()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Scope remains a single active backend-emission callsite convergence step:
  - `generate_systemverilog()` now emits WEN/EN signals through `$ctx->{backend_sv}->generate_wen_en_signals(...)`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue with the next active Orchestrator round-trip, most likely the stage-8 `generate_signal_assignments()` callsite in `generate_systemverilog()`,
  - keep prioritizing live callsite convergence over dormant validation/helper families.
## 2026-03-08: Backend convergence micro-slice (Orchestrator consolidated-intermediate-signals callsite convergence)
- Current worktree localizes the stage-6 `generate_consolidated_intermediate_signals()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Scope remains a single active backend-emission callsite convergence step:
  - `generate_systemverilog()` now emits consolidated intermediate signals through `$ctx->{backend_sv}->generate_consolidated_intermediate_signals(...)`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue with the next active Orchestrator/backend round-trip, most likely the stage-7 `generate_wen_en_signals()` callsite in `generate_systemverilog()`,
  - keep prioritizing live callsite convergence over dormant validation/helper families.
## 2026-03-08: Repository tracking change (plugin/ and specs/ now versioned)
- Added the existing `plugin/` and `specs/` trees to git so the repository now carries the legacy `.plg` plugin assets and spec/reference files directly.
- Scope is repository tracking only:
  - no content changes were made inside `plugin/` or `specs/`,
  - no intended HDL generation or runtime behavior changes were introduced by tracking these files.
- Validation for this scope:
  - post-commit `git --no-pager status --short` should leave only `?? fx/`
- Immediate next direction after commit:
  - keep `fx/` untracked for now,
  - resume backend convergence at the next live Orchestrator/backend seam, most likely stage-6 `generate_consolidated_intermediate_signals()`.
## 2026-03-08: Backend convergence micro-slice (Orchestrator WEN/EN prescan callsite convergence)
- Current worktree localizes the stage-5 `prescan_wen_en_for_intermediate_signals()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Scope remains a single active backend-analysis callsite convergence step:
  - `generate_systemverilog()` now performs the post-count pre-scan through `$ctx->{backend_sv}->prescan_wen_en_for_intermediate_signals()`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue with the next active Orchestrator/backend round-trip, most likely the stage-6 `generate_consolidated_intermediate_signals()` callsite in `generate_systemverilog()`,
  - keep prioritizing live callsite convergence over dormant validation/helper families.
## 2026-03-08: Backend convergence micro-slice (Orchestrator logical-op-count callsite convergence)
- Current worktree localizes the stage-4 `count_binary_logical_operation_occurrences()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Scope remains a single active backend-analysis callsite convergence step:
  - `generate_systemverilog()` now performs the pre-prescan logical-op counting through `$ctx->{backend_sv}->count_binary_logical_operation_occurrences()`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue with the next active Orchestrator/backend round-trip, most likely the stage-5 `prescan_wen_en_for_intermediate_signals()` callsite in `generate_systemverilog()`,
  - keep prioritizing live callsite convergence over dormant validation/helper families.
## 2026-03-08: Backend convergence micro-slice (Orchestrator generate-enable-conditions callsite convergence)
- Current worktree localizes the stage-3 `generate_enable_conditions()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Scope remains a single active backend-emission callsite convergence step:
  - `generate_systemverilog()` now emits enable conditions through `$ctx->{backend_sv}->generate_enable_conditions(...)`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue with the next active Orchestrator/backend round-trip, most likely the stage-4 `count_binary_logical_operation_occurrences()` callsite in `generate_systemverilog()`,
  - keep prioritizing live callsite convergence over dormant validation/helper families.
## 2026-03-08: Backend convergence micro-slice (Orchestrator generate-internal-signal-declarations callsite convergence)
- Current worktree localizes the stage-2 `generate_internal_signal_declarations()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Scope remains a single active backend-emission callsite convergence step:
  - `generate_systemverilog()` now appends internal signal declarations through `$ctx->{backend_sv}->generate_internal_signal_declarations(...)`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue with the next active Orchestrator/backend round-trip, most likely the stage-3 `generate_enable_conditions()` callsite in `generate_systemverilog()`,
  - keep prioritizing live callsite convergence over dormant validation/helper families.
## 2026-03-08: Backend convergence micro-slice (Orchestrator generate-state-register callsite convergence)
- Current worktree localizes the stage-2 `generate_state_register()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Scope remains a single active backend-emission callsite convergence step:
  - `generate_systemverilog()` now appends state-register emission through `$ctx->{backend_sv}->generate_state_register(...)`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue through the remaining stage-2 backend-emission Orchestrator round-trips in `generate_systemverilog()`, most likely `generate_internal_signal_declarations()`,
  - keep prioritizing live callsite convergence over dormant validation/helper families.
## 2026-03-08: Backend convergence micro-slice (Orchestrator generate-state-encoding callsite convergence)
- Current worktree localizes the stage-2 `generate_state_encoding()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Scope remains a single active backend-emission callsite convergence step:
  - `generate_systemverilog()` now appends state encoding through `$ctx->{backend_sv}->generate_state_encoding(...)`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue through the remaining stage-2 backend-emission Orchestrator round-trips in `generate_systemverilog()`, most likely `generate_state_register()`,
  - keep prioritizing live callsite convergence over dormant validation/helper families.
## 2026-03-08: Backend convergence micro-slice (Orchestrator generate-module-declaration callsite convergence)
- Current worktree localizes the stage-2 `generate_module_declaration()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Scope remains a single active backend-emission callsite convergence step:
  - `generate_systemverilog()` now appends the module declaration through `$ctx->{backend_sv}->generate_module_declaration(...)`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue through the remaining stage-2 backend-emission Orchestrator round-trips in `generate_systemverilog()`, most likely `generate_state_encoding()`,
  - keep prioritizing live callsite convergence over dormant validation/helper families.
## 2026-03-08: Backend convergence micro-slice (Orchestrator generate-header callsite convergence)
- Current worktree localizes the stage-2 `generate_header()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `SystemVerilog` backend ownership.
- Scope remains a single active backend-emission callsite convergence step:
  - `generate_systemverilog()` now starts HDL assembly through `$ctx->{backend_sv}->generate_header(...)`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue through the remaining stage-2 backend-emission Orchestrator round-trips in `generate_systemverilog()`, most likely `generate_module_declaration()`,
  - keep prioritizing live callsite convergence over dormant validation/helper families.
## 2026-03-08: Backend convergence micro-slice (Orchestrator unified-assignment-analysis callsite convergence)
- Current worktree localizes the unified phase-1 `build_unified_assignment_analysis()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` ownership.
- Scope remains a single active stage-level callsite convergence step:
  - `flatten_all_decision_trees()` now invokes `$ctx->{enable_graph}->build_unified_assignment_analysis(...)`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue through the remaining active stage-level Orchestrator round-trips in `generate_systemverilog()`, likely starting with the earliest backend-emission callsites,
  - keep prioritizing live callsite convergence over dormant validation/helper families.
## 2026-03-08: Backend convergence micro-slice (Orchestrator stage-0 FSM-module-reference callsite convergence)
- Current worktree localizes the stage-0 `set_fsm_module_reference()` callsite in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` from the `FlattenedDT` facade delegate to direct `EnableGraph` ownership.
- Scope remains a single active callsite convergence step:
  - `generate_systemverilog()` now stores the FSM module reference through `$ctx->{enable_graph}->set_fsm_module_reference(...)`,
  - the `FlattenedDT` compatibility delegate remains in place for any non-local callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue with the next stage-level Orchestrator round-trip, most likely `build_unified_assignment_analysis()` in `flatten_all_decision_trees()`,
  - keep prioritizing live callsite convergence over dormant validation/helper families.
## 2026-03-08: Backend convergence micro-slice (Orchestrator condition-helper callsite convergence)
- Current worktree localizes the active Orchestrator condition-helper round-trips from `FlattenedDT` facade delegates to direct `EnableGraph` ownership.
- Updated runtime callsites in `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`:
  - `convert_condition_to_ast()` for conditional-branch traversal,
  - `convert_test_value_to_ast()` for test-node branch construction,
  - `create_condition_expression()` for assignment capture and transition capture.
- Scope remains callsite convergence only:
  - helper ownership stays in `perl/FSM/Synthesis/EnableGraph.pm`,
  - `FlattenedDT` compatibility delegates remain for non-local or dormant callers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue through the remaining active stage-level Orchestrator round-trips, most likely `build_unified_assignment_analysis()` or `set_fsm_module_reference()`,
  - keep treating dormant validation helpers and legacy code as lower priority than live callsite convergence.
## 2026-03-08: Backend convergence micro-slice (actual LHS/RHS tracking orchestration ownership)
- Current worktree moves `track_actual_lhs_rhs()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`, while keeping `FlattenedDT` as a compatibility delegate.
- This slice follows the now-orchestrator-owned assignment/transition capture flow:
  - `record_assignment_from_ast()` and `record_transition_from_ast()` now both keep actual-pair validation tracking local to the orchestrator instead of round-tripping through the facade,
  - the adjacent `track_expected_lhs_rhs()` / raw-AST completeness helpers remain in `FlattenedDT` for now because they are dormant validation support rather than part of the active runtime path.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - re-scan the remaining live Orchestrator/backend call surface for the next smallest active ownership seam now that actual-pair tracking is local,
  - continue deferring the dormant expected/raw-AST validation family until it becomes worth extracting as a cohesive support block.
## 2026-03-08: Living architecture note added (frontend parser/input-format decoupling)
- Added a living design note in `DEVELOPMENT_NOTES.md` describing the desired boundary between source-format parsing and the FSMGen semantic core.
- Current validated read captured there:
  - the pipeline already has a partial separation because `FSM::Pipeline::HDLGenerator` parses source first, then lowers into `FSM::CoreAST::FSMModule`, and downstream analysis/backend code mostly consumes semantic CoreAST objects,
  - the remaining hard coupling is still at the frontend boundary because `HDLGenerator` directly calls `Lispish`, and `FSM::Adapter::FSMGenFull::*` still decodes the current `.fsm` / Lispish surface syntax directly.
- Architectural rule now recorded:
  - `FSM::CoreAST` is the canonical semantic contract,
  - parser-specific raw ASTs and syntax tokens should stop at the frontend/lowering boundary rather than leaking into synthesis/backend layers.
- Immediate next direction:
  - treat any future non-Lispish format as another frontend that lowers into `FSM::CoreAST`, not as a reason to branch backend behavior by input format,
  - when implementation work begins, isolate the direct `Lispish` dependency behind a dedicated frontend boundary first.
## 2026-03-08: Backend convergence micro-slice (assignment-capture orchestration ownership)
- Current worktree moves `extract_lhs_name_from_ast()`, `record_assignment_from_ast()`, and `extract_rhs_from_expression()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`, while keeping `FlattenedDT` as compatibility delegates.
- This slice completes the active assignment-capture trio on the live recursive flattener path:
  - `flatten_decision_tree()` now routes assignment capture locally through orchestrator-owned helpers instead of round-tripping through the facade,
  - the RHS extraction helper moved with the assignment recorder to avoid leaving that recursion split across facade/orchestrator ownership,
  - the LHS-name helper moved too because its only live callers are now the orchestrator-owned assignment traversal/capture path.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue on the remaining shared tracking helper seam now adjacent to the orchestrator-owned assignment/transition capture path, most likely `track_actual_lhs_rhs()`,
  - keep deferring dormant legacy helpers such as `extract_condition_string()` until they become part of an active ownership path again.
## 2026-03-08: Backend convergence micro-slice (state-transition capture orchestration ownership)
- Current worktree moves `record_transition_from_ast()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`, while keeping `FlattenedDT` as a compatibility delegate.
- This slice is the next smallest active seam in the post-flattener AST-capture family: `record_transition_from_ast()` now has a single live caller inside the orchestrator-owned recursive flattener and is materially smaller than the adjacent assignment-capture path.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue on the adjacent assignment-capture path (`record_assignment_from_ast()` together with `extract_rhs_from_expression()` and any tightly coupled support),
  - keep deferring dormant legacy factorization helpers until they matter to the active path again.
## 2026-03-08: Backend convergence micro-slice (recursive flattener orchestration ownership)
- Current worktree moves `flatten_decision_tree()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`, while keeping `FlattenedDT` as a compatibility delegate.
- This slice extends the immediately adjacent orchestration move from `flatten_all_decision_trees()`: the orchestrator now owns both the live entrypoint and its recursive traversal body, while still calling back into `FlattenedDT` for the unmoved AST-capture helpers.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue on the adjacent live AST-capture helper family used by the recursive flattener (`record_assignment_from_ast()`, `record_transition_from_ast()`, `extract_rhs_from_expression()`, and any tightly coupled helpers),
  - keep ignoring dormant legacy factorization code until it becomes part of the active generation path again.
## 2026-03-08: Backend convergence micro-slice (flatten-all-decision-trees orchestration ownership)
- Current worktree moves `flatten_all_decision_trees()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`, while keeping `FlattenedDT` as a compatibility delegate.
- This slice follows the recent live-path focus: the moved entrypoint is exercised directly by `generate_systemverilog()` and is a smaller truthful orchestration seam than the adjacent deeper flattener helper family.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue scanning the live flattening/orchestration path for the next smallest helper family adjacent to this entrypoint,
  - keep deprioritizing dormant legacy factorization helpers until they become operationally relevant again.
## 2026-03-08: Backend convergence micro-slice (AST condition-helper ownership)
- Current worktree moves `create_condition_expression()`, `convert_condition_to_ast()`, and `convert_test_value_to_ast()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/Synthesis/EnableGraph.pm`, while keeping `FlattenedDT` as compatibility delegates.
- This slice targets the next smallest still-live helper family after confirming the nearby legacy factorization and AST naming helpers are mostly dormant, while the moved trio is exercised directly during branch/test flattening and assignment/transition condition construction.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Important note:
  - explicit `use FSM::AST::Utils;` in `EnableGraph` is currently unsafe in this repo because it exposes an incompatible helper load path; the moved methods work when left on the existing runtime path without that import.
- Immediate next direction after commit:
  - continue scanning for the next smallest active helper or entrypoint still exercised by the live flattening/orchestration/backend path,
  - keep deprioritizing dormant legacy helper blocks until they become operationally relevant.
## 2026-03-07: Backend convergence micro-slice (WEN/EN prescan entrypoint ownership)
- Current worktree moves `prescan_wen_en_for_intermediate_signals()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, while keeping `FlattenedDT` as a compatibility delegate.
- This slice picks the smallest still-live helper on the active SystemVerilog generation path after confirming the nearby AST-based naming helpers are mostly idle compatibility code.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue through the remaining active helper/ownership seams in `FlattenedDT`,
  - prioritize another behavior-preserving seam that is still exercised by the live Orchestrator/backend path rather than the mostly idle legacy naming utilities.
## 2026-03-07: Backend convergence micro-slice (AST sub-expression analysis helper ownership)
- Current worktree moves `analyze_ast_sub_expressions()`, `find_all_ast_sub_expressions()`, and `is_simple_ast_expression()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, while keeping `FlattenedDT` as compatibility delegates.
- This slice localizes a small cohesive AST-analysis trio from the adjacent factorization helper cluster without pulling in the larger legacy string-based factorization family.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue through the remaining adjacent factorization/helper cluster in `FlattenedDT`,
  - prioritize the next smallest cohesive family that reduces `FlattenedDT` ownership without behavior change.
## 2026-03-07: Backend convergence micro-slice (intermediate-signal generation entrypoint ownership)
- Current worktree moves `generate_intermediate_signals()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, while keeping `FlattenedDT` as a compatibility delegate.
- The moved entrypoint is a clean backend-facing seam because its active dependency, `run_global_ast_factorization()`, is already backend-owned.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue shrinking the adjacent legacy factorization/helper cluster around intermediate-signal generation in `FlattenedDT`,
  - prioritize the next smallest backend-owned entrypoint or helper family that can move without changing behavior.
## 2026-03-07: Backend convergence micro-slice (logical-op-count helper-pair ownership)
- Current worktree moves `_count_logical_ops_in_ast()` and `_is_factorizable_sub_expression()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, while keeping `FlattenedDT` as compatibility delegates.
- The backend logical-op-count family is now locally self-contained for the active counting flow:
  - `count_binary_logical_operation_occurrences()`
  - `collect_all_wen_en_ast_expressions()`
  - `_count_logical_ops_in_ast()`
  - `_is_factorizable_sub_expression()`
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Roadmap decision update:
  - roadmap item 5 now assumes retiring legacy `.plg` / `PPlugin.pm` support in favor of a more standard typed-hook mechanism rather than preserving plugin compatibility.
- Immediate next direction after commit:
  - re-scan `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` for the next smallest backend/facade ownership seam beyond the now-local logical-op-count family,
  - keep the same one-slice, regression-first cadence.
## 2026-03-07: Backend convergence micro-slice (logical-op-count collector ownership)
- Current worktree moves `collect_all_wen_en_ast_expressions()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, while keeping `FlattenedDT` as a compatibility delegate.
- The backend logical-op-count flow now calls `$self->collect_all_wen_en_ast_expressions()` locally; the remaining direct backend `FlattenedDT` helper round-trip inside this family is `_count_logical_ops_in_ast()`, which still relies on `_is_factorizable_sub_expression()`.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - move `_count_logical_ops_in_ast()` ownership into backend together with the coupled `_is_factorizable_sub_expression()` policy helper,
  - then re-scan the logical-op-count family for any remaining backend/facade round-trips.
## 2026-03-07: Backend convergence micro-slice (logical-op-count entrypoint ownership)
- Current worktree moves `count_binary_logical_operation_occurrences()` ownership from `perl/FSM/HDL/FlattenedDT.pm` into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, while keeping `FlattenedDT` as a compatibility delegate.
- The backend entrypoint now owns the counting flow directly; remaining direct backend `FlattenedDT` helper calls inside this family are:
  - `collect_all_wen_en_ast_expressions()`
  - `_count_logical_ops_in_ast()`
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue shrinking the logical-op-count family by localizing the remaining backend helper round-trips,
  - likely start with `collect_all_wen_en_ast_expressions()` before the deeper `_count_logical_ops_in_ast()` / `_is_factorizable_sub_expression()` pair.
## 2026-03-07: Backend convergence micro-slice (logical-op-count wrapper callsite)
- Current worktree localizes the remaining direct `run_global_ast_factorization` backend method-call round-trip in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` by routing `count_binary_logical_operation_occurrences()` through a backend-local helper instead of calling `FlattenedDT` directly from the factorization flow.
- The slice adds a backend-local `count_binary_logical_operation_occurrences()` helper and switches the `run_global_ast_factorization` fallback callsite to `$self->count_binary_logical_operation_occurrences()`.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - move the logical-op-count implementation family itself into backend ownership so the new backend-local helper stops delegating through `FlattenedDT`,
  - then re-scan for the next smallest backend/helper ownership seam.
## 2026-03-07: Backend convergence micro-slice (bare intermediate-signal trace render callsite)
- Current worktree localizes one remaining backend render/helper round-trip in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from a `FlattenedDT` method call (`$ctx->ast_to_clean_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- The slice is the bare `FSM::HDL::IntermediateSignalRef` trace render in `ast_contains_intermediate_signals`.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - direct backend `$ctx->method(...)` round-trips in `Backend/SystemVerilog.pm` are now reduced to one,
  - prioritize the remaining `count_binary_logical_operation_occurrences()` callsite in `run_global_ast_factorization`.
## 2026-03-07: Backend convergence micro-slice (factorizer substituted-AST trace render callsite)
- Current worktree localizes one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- The slice is the factorizer substituted-AST trace render in `get_substituted_ast_for_signal`.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - exact backend `$ctx->ast_to_systemverilog(...)` pass-throughs in `perl/FSM/HDL/FlattenedDT/Backend` are now exhausted,
  - re-scan for the next smallest remaining backend ownership seam beyond this exact render-pass-through pattern.
## 2026-03-07: Backend convergence micro-slice (assignment-condition second-pass substituted-AST debug render callsite)
- Current worktree localizes one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- The slice is the assignment-condition substituted-AST debug render in `update_original_asts_with_second_pass_substitutions`.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue remaining backend `ast_to_systemverilog` round-trips in `Backend/SystemVerilog.pm`,
  - prioritize the later factorizer substituted-AST trace render callsite in `get_substituted_ast_for_signal`.
## 2026-03-07: Backend convergence micro-slice (assignment-condition second-pass original-AST debug render callsite)
- Current worktree localizes one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- The slice is the assignment-condition original-AST debug render in `update_original_asts_with_second_pass_substitutions`.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue remaining backend `ast_to_systemverilog` round-trips in `Backend/SystemVerilog.pm`,
  - prioritize the adjacent assignment-condition substituted-AST debug render callsite and then the later factorizer substituted-AST trace render.
## 2026-03-07: Backend convergence micro-slice (LHS-level second-pass substituted-AST debug render callsite)
- Current worktree localizes one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- The slice is the LHS-level substituted-AST debug render in `update_original_asts_with_second_pass_substitutions`.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue remaining backend `ast_to_systemverilog` round-trips in `Backend/SystemVerilog.pm`,
  - prioritize the assignment-condition second-pass original/substituted debug render callsites and then the later factorizer substituted-AST trace render.
## 2026-03-07: Backend convergence micro-slice (LHS-level second-pass original-AST debug render callsite)
- Current worktree localizes one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- The slice is the LHS-level original-AST debug render in `update_original_asts_with_second_pass_substitutions`.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue remaining backend `ast_to_systemverilog` round-trips in `Backend/SystemVerilog.pm`,
  - prioritize the adjacent LHS-level substituted-AST debug render and then the assignment-condition second-pass debug render callsites with the same one-callsite cadence.
## 2026-03-07: Backend convergence micro-slice (DT-specific second-pass substituted-AST debug render callsite)
- Current worktree localizes one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- The slice is the DT-specific substituted-AST debug render in `update_original_asts_with_second_pass_substitutions`.
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue remaining backend `ast_to_systemverilog` round-trips in `Backend/SystemVerilog.pm`,
  - prioritize the adjacent LHS-level and assignment-condition second-pass debug render callsites with the same one-callsite cadence.
## 2026-03-07: Backend convergence micro-slice (original-AST consolidated fallback render callsite)
- Current worktree localizes one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- The slice is the original-AST fallback branch of consolidated intermediate-signal assign generation (`generate_consolidated_intermediate_signals`).
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue remaining backend `ast_to_systemverilog` round-trips in `Backend/SystemVerilog.pm`,
  - prioritize the remaining second-pass update render callsites with the same one-callsite cadence.
## 2026-03-07: Backend convergence micro-slice (substituted-AST consolidated render callsite)
- Current worktree localizes one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- The slice is the substituted-AST branch of consolidated intermediate-signal assign generation (`generate_consolidated_intermediate_signals`).
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue remaining backend `ast_to_systemverilog` round-trips in `Backend/SystemVerilog.pm`,
  - prioritize the adjacent original-AST fallback in consolidated assign generation or the later second-pass update paths with the same one-callsite cadence.
## 2026-03-06: Backend convergence micro-slice (final-filtered debug AST render callsite)
- Current worktree localizes one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- The slice is in the final-filtered debug listing inside consolidated intermediate-signal generation (`generate_consolidated_intermediate_signals`).
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue remaining backend `ast_to_systemverilog` round-trips in `Backend/SystemVerilog.pm`,
  - prioritize the consolidated-intermediate substituted-AST render path or the later second-pass update paths with the same one-callsite cadence.
## 2026-03-06: Backend convergence micro-slice (rescued-signal debug AST render callsite)
- Current worktree localizes one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- The slice is in the rescued-signal debug listing inside consolidated intermediate-signal generation (`generate_consolidated_intermediate_signals`).
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue remaining backend `ast_to_systemverilog` round-trips in `Backend/SystemVerilog.pm`,
  - prioritize the adjacent final-filtered debug render or the later substituted-AST render/update paths with the same one-callsite cadence.
## 2026-03-06: Backend convergence micro-slice (initial-filtering AST render callsite)
- Current worktree localizes one remaining backend AST-render callsite in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` from `FlattenedDT` pass-through (`$ctx->ast_to_systemverilog(...)`) to direct `EnableGraph` ownership (`$ctx->{enable_graph}->ast_to_systemverilog(...)`).
- The slice is in the initial filtering pass inside consolidated intermediate-signal generation (`generate_consolidated_intermediate_signals`).
- Validation is green for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` (`Files=6`, `Tests=125`, `PASS`)
- Immediate next direction after commit:
  - continue remaining backend `ast_to_systemverilog` round-trips in `Backend/SystemVerilog.pm`,
  - keep the same one-callsite micro-slice cadence with full validation and commit workflow.
## 2026-03-06: README onboarding hub update
- `README.md` was restructured to serve as the single entry point to the project.
- README now includes:
  - explicit project objective,
  - full markdown index for fast ramp-up (`README.md`, `CHANGES.md`, `DEVELOPMENT_NOTES.md`, `MEMORY.md`, `COMMIT.md`, `WARP.md`, `docs/USER_GUIDE.md`, `.agents/workflows/commit.md`),
  - key project file/path map for core entrypoints and supporting directories,
  - README maintenance policy clarifying update cadence (when it materially affects onboarding).
- `README.md` remains tracked in git; change is prepared for commit workflow completion.
## Current technical status (updated 2026-02-27)
- Assignment families are implemented and stabilized: `c`, `r`, `m`, `rm`, `mr`, `pN`.
- `pN` semantics are authoritative and must not regress:
  - `<N` means exact delay to cycle `Q+N` (not duration).
  - one-cycle pulse only.
  - `<N 1`: positive pulse (`0->1->0`), `<N 0`: negative pulse (`1->0->1`).
- Regression baseline is currently green:
  - `prove -I perl t`
  - `Files=6, Tests=125, PASS`.
- FlattenedDT decomposition direction is now explicitly two-track:
  - `Orchestrator` (pipeline sequencing ownership),
  - `Backend` (render/emitter ownership).
- `EnableGraph` remains a synthesis helper module (`FSM::Synthesis::EnableGraph`) used by `FlattenedDT`, not a direct submodule in the `FlattenedDT` breakdown.
- First orchestrator decomposition slice is complete:
  - `generate_systemverilog` orchestration has been moved into `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`,
  - `FlattenedDT` now delegates this entrypoint through a compatibility facade.
- First backend decomposition slice is complete:
  - module declaration emission (`generate_module_declaration`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Second backend decomposition slice is complete:
  - state-encoding emission (`generate_state_encoding`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Third backend decomposition slice is complete:
  - state-register emission (`generate_state_register`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Fourth backend decomposition slice is complete:
  - enable-conditions emission (`generate_enable_conditions`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Fifth backend decomposition slice is complete:
  - header emission (`generate_header`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Sixth backend decomposition slice is complete:
  - internal-signal declaration emission (`generate_internal_signal_declarations`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Seventh backend decomposition slice is complete:
  - Verilog generation ownership (`generate_verilog`, `convert_systemverilog_to_verilog`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/Verilog.pm`,
  - `FlattenedDT` now delegates these Verilog backend entrypoints through a compatibility facade.
- Eighth backend decomposition slice is complete:
  - WEN/EN emission entrypoint ownership (`generate_wen_en_signals`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Ninth backend decomposition slice is complete:
  - intermediate-signal declaration emission ownership (`generate_intermediate_signal_declarations`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Tenth backend decomposition slice is complete:
  - combinational-mux emission ownership (`generate_comb_mux`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Eleventh backend decomposition slice is complete:
  - flop-mux emission ownership (`generate_flop_mux`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Twelfth backend decomposition slice is complete:
  - consolidated intermediate-signal emission ownership (`generate_consolidated_intermediate_signals`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Thirteenth backend decomposition slice is complete:
  - global AST-factorization orchestration ownership (`run_global_ast_factorization`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Fourteenth backend decomposition slice is complete:
  - AST-factorizer input feeding ownership (`feed_asts_to_factorizer`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Fifteenth backend decomposition slice is complete:
  - unary-negation counting helper ownership (`count_unary_negations_in_original_expressions`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Sixteenth backend decomposition slice is complete:
  - AST substitution-backpropagation helper ownership (`update_original_asts_with_substituted_versions`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Seventeenth backend decomposition slice is complete:
  - second-pass factorization orchestration ownership (`run_second_pass_factorization`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Eighteenth backend decomposition slice is complete:
  - created shared backend-neutral factorization package `perl/FSM/HDL/Factorization/Fixpoint.pm`,
  - moved iterative post-substitution factorization loop ownership into `FSM::HDL::Factorization::Fixpoint`,
  - `Backend::SystemVerilog` now delegates `run_second_pass_factorization` to the shared package via compatibility entrypoint.
- Nineteenth backend decomposition slice is complete:
  - second-pass AST feeding ownership (`feed_current_asts_to_second_pass`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Twentieth backend decomposition slice is complete:
  - second-pass AST substitution update ownership (`update_original_asts_with_second_pass_substitutions`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Twenty-first backend decomposition slice is complete:
  - second-pass intermediate-expression filter ownership (`ast_contains_intermediate_signals`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Twenty-second backend decomposition slice is complete:
  - recursive intermediate-signal detection helper ownership (`ast_has_intermediate_signals_recursive`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Twenty-third backend decomposition slice is complete:
  - substituted-intermediate AST resolver ownership (`get_substituted_ast_for_signal`) has been moved into `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`,
  - `FlattenedDT` now delegates this backend entrypoint through a compatibility facade.
- Post-substitution factorization behavior now uses iterative convergence until stable with deterministic termination guards:
  - stops on no factorizable expressions, no new candidates, repeated expression signature, no substitution progress, or max-pass cap.
- Commit workflow documentation is now explicit and tracked:
  - added `COMMIT.md` as the canonical workflow reference for future AI handoff,
  - includes involved files, exact execution order, and run frequency (after each completed task/activity).
- First-class tracing is now integrated into FSMGen runtime surfaces:
  - canonical trace verbosity names are supported: `none`, `low`, `medium`, `high`, `debug` (mapped to levels `0..4`),
  - numeric debug compatibility remains supported through `--debug[=N]` with bare `--debug` mapped to level `4`,
  - CLI now supports trace controls: `--trace-verbosity`, `--trace-log[=FILE]`, `--trace-emojis`/`--notrace-emojis`,
  - when trace-file routing is enabled, trace output is routed to `trace.log` (or configured file) instead of stdout,
  - trace records include source metadata (`file`, `function`, `line`) and structured kinds (`topic`, `enter`, `exit`, `decision`) with indentation-aware formatting.
- Trace instrumentation was integrated in key pipeline/parser facades:
  - `perl/FSM/Pipeline/HDLGenerator.pm`,
  - `perl/FSM/Adapter/FSMGenFull.pm`,
  - `perl/FSM/Adapter/FSMGenFull/Parser.pm`.
- User-facing and regression coverage for tracing were updated:
  - docs updated in `README.md` and `docs/USER_GUIDE.md`,
  - new trace regression `t/06-tracing-system.t` added and passing.
## EnableGraph extraction status
Behavior-preserving extraction from `FlattenedDT` into `EnableGraph` is active and working.
### Already moved into `perl/FSM/Synthesis/EnableGraph.pm`
- `build_unified_assignment_analysis`
- `group_assignments_by_rhs`
- `generate_complete_enable_structure`
- `build_multiplexer_config`
- `generate_unified_wen_en_signals`
- `generate_dt_enables_from_analysis`
- `generate_lhs_enables_from_analysis`
- `generate_signal_assignments`
- `generate_unified_comb_mux`
- `generate_unified_flop_mux`
- `generate_unified_pulse_delay_logic`
- `get_pulse_delay_cycles_for_lhs`
- `get_pulse_active_level_for_lhs`
- `normalize_rhs_logic_level`
- `clean_signal_name`
- `generate_rhs_based_enable_name`
- `signal_uses_register_assignment`
- `get_signal_assignment_type`
- `get_driven_signals`
- `get_reset_value`
- `get_default_value`
- `get_signal_info`
- `get_explicit_reset_value`
- `get_fsm_reset_state`
- `get_reset_value_from_ast`
- `get_default_value_from_ast`
- `set_explicit_reset_values`
- `set_fsm_module_reference`
- `is_register`
- `fallback_register_analysis_from_assignments`
- `extract_signal_name_from_ast`
- `get_lhs_width_from_analysis`
- `track_ast_intermediate_signals`
- `is_intermediate_signal`
- `is_signal_ast_based_intermediate`
- `_ast_contains_factorizable_operators`
- `is_arithmetic_operation`
- `is_logical_operation`
- `should_factor_logical_operation`
- `contains_frequently_used_operations`
- `get_intermediate_signal_expression`
- `generate_expression_from_signal_name`
- `_signal_name_indicates_ast_operators`
- `ast_to_systemverilog`
### Still strong candidates for next slices
- the direct EnableGraph-to-FlattenedDT helper seam is now essentially exhausted for this extraction lane; any further moves would be deeper AST-render internals.
- broader decomposition remains the next architectural lever:
  - continue `EnableGraph` helper ownership where clear,
  - extract backend emitters into dedicated modules,
  - keep `FlattenedDT` as thin facade/compatibility shell.
## Recent milestone commits (most recent first)
- `WORKTREE (pending commit)` Continue backend decomposition by extracting `get_substituted_ast_for_signal` into `FlattenedDT::Backend::SystemVerilog` with compatibility delegation in `FlattenedDT`
- `7c44abc` Extract AST substitution-backpropagation helper into SV backend
- `586a2f8` Extract unary-negation counter helper into SV backend
- `f2c4422` Extract AST factorizer input feeding into SV backend
- `c9db9e2` Extract global AST factorization orchestration into SV backend
- `07329fb` Extract consolidated intermediate signal emission into SV backend
- `c2dfaaf` Add first-class multi-level tracing with structured metadata, trace.log routing, CLI controls, parser/pipeline hooks, and regression coverage
- `886b5f1` Add canonical `COMMIT.md` with precise commit workflow definition for AI handoff continuity
- `3adf1f8` Continue backend decomposition by extracting `generate_flop_mux` into `FlattenedDT::Backend::SystemVerilog` with compatibility delegation in `FlattenedDT`
- `ebf90f2` Continue backend decomposition by extracting `generate_comb_mux` into `FlattenedDT::Backend::SystemVerilog` with compatibility delegation in `FlattenedDT`
- `a89fa9c` Continue backend decomposition by extracting `generate_intermediate_signal_declarations` into `FlattenedDT::Backend::SystemVerilog` with compatibility delegation in `FlattenedDT`
- `b9c81dc` Continue backend decomposition by extracting `generate_wen_en_signals` into `FlattenedDT::Backend::SystemVerilog` with compatibility delegation in `FlattenedDT`
- `5de2f44` Add dedicated `FlattenedDT::Backend::Verilog` and move `generate_verilog`/`convert_systemverilog_to_verilog` ownership there with compatibility delegation in `FlattenedDT`
- `1f0b44b` Continue backend decomposition by extracting `generate_internal_signal_declarations` into `FlattenedDT::Backend::SystemVerilog` with compatibility delegation in `FlattenedDT`
- `0313969` Continue backend decomposition by extracting `generate_header` into `FlattenedDT::Backend::SystemVerilog` with compatibility delegation in `FlattenedDT`
- `0d80108` Continue backend decomposition by extracting `generate_enable_conditions` into `FlattenedDT::Backend::SystemVerilog` with compatibility delegation in `FlattenedDT`
- `637678f` Continue backend decomposition by extracting `generate_state_register` into `FlattenedDT::Backend::SystemVerilog` with compatibility delegation in `FlattenedDT`
- `7dc5461` Continue backend decomposition by extracting `generate_state_encoding` into `FlattenedDT::Backend::SystemVerilog` with compatibility delegation in `FlattenedDT`
- `082eab2` Start backend decomposition by extracting `generate_module_declaration` into `FlattenedDT::Backend::SystemVerilog` with compatibility delegation in `FlattenedDT`
- `dd82368` Start explicit `FlattenedDT` decomposition by extracting `generate_systemverilog` pipeline sequencing into `FlattenedDT::Orchestrator` with compatibility delegation in `FlattenedDT`
- `1b1036a` Delegate AST-to-SystemVerilog rendering helper ownership to `EnableGraph` (`ast_to_systemverilog`) with compatibility delegation in `FlattenedDT`
- `4840580` Delegate AST-based intermediate-name metadata helper ownership to `EnableGraph`
- `ac9b39e` Delegate intermediate-signal expression synthesis helper ownership to `EnableGraph`
- `4fec56e` Delegate intermediate-signal expression resolver ownership to `EnableGraph`
- `4a0cd02` Delegate frequent-logical-usage helper ownership to `EnableGraph`
- `0a4dd6e` Delegate logical-factorization policy helper ownership to `EnableGraph`
- `b3f5f73` Delegate logical-operation helper ownership to `EnableGraph`
- `7b1f2b8` Delegate arithmetic-operation helper ownership to `EnableGraph`
- `ddaaabe` Delegate AST factorization operator helper ownership to `EnableGraph`
- `eb1de0d` Delegate AST-based intermediate classification helper ownership to `EnableGraph`
- `8c5f23b` Delegate intermediate-signal classification helper ownership to `EnableGraph`
- `9bb41eb` Delegate intermediate-signal AST tracker ownership to `EnableGraph`
- `fe6360c` Delegate LHS-width analysis helper ownership to `EnableGraph`
- `e087dac` Delegate AST signal-name extraction helper ownership to `EnableGraph`
- `01312fa` Delegate register-classification helper ownership to `EnableGraph`
- `9ebea2f` Delegate FSM module-reference setter ownership to `EnableGraph`
- `250a55f` Delegate explicit-reset config setter ownership to `EnableGraph`
- `30d21cc` Delegate AST default-value helper ownership to `EnableGraph`
- `c3dcf04` Delegate AST reset-value helper ownership to `EnableGraph`
- `7705725` Delegate FSM reset-state helper ownership to `EnableGraph`
- `0465b90` Delegate explicit-reset helper ownership to `EnableGraph`
- `0aeb0fc` Delegate signal-info helper ownership to `EnableGraph`
- `2ee1c64` Delegate default-value helper ownership to `EnableGraph`
- `820481c` Delegate reset-value helper ownership to `EnableGraph`
- `dfc92dd` Delegate driven-signal classification to `EnableGraph`
- `c18c35b` Delegate assignment-type helper ownership to EnableGraph
- `a82d5cd` Delegate enable naming helper ownership to EnableGraph
- `59a86d3` Delegate pulse helper analysis ownership to EnableGraph
- `d65e86a` Delegate unified pulse-delay emission to EnableGraph
- `a2725c9` Add live MEMORY.md continuity document and update workflow policy
- `0bf08d4` Delegate unified flop mux emission to EnableGraph
- `1f29750` Delegate unified combinational mux emission to EnableGraph
- `d4dc317` Delegate unified phase-3 assignment orchestration to EnableGraph
- `32892d4` Delegate unified phase-2 WEN/EN emission to EnableGraph
- `f62d6fe` Extract unified assignment-analysis orchestration into EnableGraph
- `6bb94d4` Extract multiplexer config assembly into EnableGraph synthesis layer
- `36a574f` Extract RHS grouping orchestration into EnableGraph synthesis layer
- `2a05831` Add assignment edge/snapshot regressions and extract initial EnableGraph layer
- `fe1cc3c` Implement c/r/m/rm/mr/pN assignment semantics and document pN as Q+N delay
## Quick resume checklist
1. Read `MEMORY.md` first.
2. Read latest entries in `CHANGES.md` and `DEVELOPMENT_NOTES.md`.
3. Check repo state: `git --no-pager status --short`.
4. Run baseline regression: `prove -I perl t`.
5. Continue the next extraction slice with behavior-preserving delegation.
6. Before committing, update `MEMORY.md` and related live docs again.
## Live document references
- `CHANGES.md`: persistent technical change history.
- `DEVELOPMENT_NOTES.md`: rationale, architecture, and policy-level technical knowledge.
- `docs/USER_GUIDE.md`: user-facing usage guidance.
- `README.md`: project overview and quickstart.
## AST/CoreAST convergence status (March 11, 2026)
- Live declaration path confirmation:
  - `perl/FSM/HDL/FlattenedDT/Orchestrator.pm` calls `generate_consolidated_intermediate_signals(...)` on the active SystemVerilog runtime path,
  - `generate_intermediate_signal_declarations(...)` is currently compatibility-only and was intentionally left out of this slice.
- Latest completed slice in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`:
  - consolidated intermediate-signal widths are now normalized across AST-factorization, prescan-reference, and FSMGen-native sources,
  - width resolution now prefers `EnableGraph::get_signal_info(...)` and defining ASTs,
  - parsed expression re-entry remains only as a narrow compatibility fallback,
  - substituted factorizer AST nodes (`FSM::HDL::IntermediateSignalRef`, `FSM::HDL::SubstitutedUnaryOp`, `FSM::HDL::SubstitutedBinaryOp`) are handled in the live backend width resolver so emitted wire widths are no longer driven by placeholder `1` values.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` => `Files=6`, `Tests=125`, `PASS`
- Recent AST/CoreAST convergence commits immediately before this slice:
  - `e853005` `SystemVerilog: cache defining ASTs for filtering`
  - `82809ac` `SystemVerilog: use AST traversal for intermediate deps`
  - `ec61da7` `EnableGraph: store AST-backed intermediate registry metadata`
- Highest-value next seam after this slice:
  - continue removing expression-only compatibility fallbacks from consolidated intermediate handling,
  - only spend cleanup effort on dormant declaration helpers when they are either reactivated on the runtime path or can be retired outright.
## AST/CoreAST convergence update (March 11, 2026, later slice)
- Latest completed slice in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`:
  - consolidated intermediate handling now normalizes a runtime AST per signal before dependency analysis, filtering, and assign emission,
  - runtime AST resolution prefers substituted factorizer ASTs first, then defining ASTs, and parses stored expressions only as compatibility fallback,
  - the active consolidated path now renders/debugs/emits from that runtime AST-first view instead of maintaining separate raw-expression branches in each phase.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` => `Files=6`, `Tests=125`, `PASS`
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `0d91234` `SystemVerilog: derive consolidated intermediate widths from AST`
  - `e853005` `SystemVerilog: cache defining ASTs for filtering`
  - `82809ac` `SystemVerilog: use AST traversal for intermediate deps`
- Highest-value next seam after this slice:
  - narrow or eliminate the remaining compatibility-only misses where runtime-AST resolution still falls back to `extract_intermediate_signals_from_expression(...)` or `should_filter_string_based(...)`,
  - keep ignoring dormant standalone declaration helpers unless they become live again or are being retired outright.
## AST/CoreAST convergence update (March 11, 2026, dependency slice)
- Latest completed slice in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`:
  - consolidated intermediate dependencies are now normalized and cached per signal before dependency-aware filtering,
  - dependency metadata is resolved from runtime AST traversal first,
  - expression-based dependency extraction remains only as the compatibility fallback inside `resolve_intermediate_signal_dependencies(...)`.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` => `Files=6`, `Tests=125`, `PASS`
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `5ea13ab` `SystemVerilog: normalize consolidated intermediate runtime ASTs`
  - `0d91234` `SystemVerilog: derive consolidated intermediate widths from AST`
  - `e853005` `SystemVerilog: cache defining ASTs for filtering`
- Highest-value next seam after this slice:
  - narrow or eliminate the remaining compatibility-only runtime-AST misses that still fall through to `extract_intermediate_signals_from_expression(...)` or `should_filter_string_based(...)`,
  - keep deferring dormant standalone declaration-helper cleanup unless it becomes live or can be removed outright.
## AST/CoreAST convergence update (March 11, 2026, render slice)
- Latest completed slice in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`:
  - consolidated rendered-expression metadata is now normalized and cached per signal before the live dependency/filter/emit phases run,
  - prescan merge no longer eagerly stores `expression` text for entries that already have runtime AST coverage,
  - expression text remains merge-time/live-time compatibility metadata only for runtime-AST misses.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` => `Files=6`, `Tests=125`, `PASS`
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `2480832` `SystemVerilog: cache consolidated intermediate dependencies`
  - `5ea13ab` `SystemVerilog: normalize consolidated intermediate runtime ASTs`
  - `0d91234` `SystemVerilog: derive consolidated intermediate widths from AST`
- Highest-value next seam after this slice:
  - narrow the remaining compatibility-only runtime-AST miss path itself, especially the cases that still fall through to `extract_intermediate_signals_from_expression(...)` or `should_filter_string_based(...)`,
  - keep deferring dormant standalone declaration-helper cleanup unless it becomes live or is being removed outright.
## AST/CoreAST convergence update (March 11, 2026, miss-state slice)
- Latest completed slice in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`:
  - consolidated runtime-AST miss state is now cached per signal,
  - signals now carry explicit runtime-AST resolution state (`resolved` or `missing`) plus a miss reason,
  - later live-path helpers reuse that cached miss state instead of retrying the same AST recovery path repeatedly.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` => `Files=6`, `Tests=125`, `PASS`
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `548ca11` `SystemVerilog: cache consolidated rendered expressions`
  - `2480832` `SystemVerilog: cache consolidated intermediate dependencies`
  - `5ea13ab` `SystemVerilog: normalize consolidated intermediate runtime ASTs`
- Highest-value next seam after this slice:
  - narrow the compatibility behavior that still hangs off explicit runtime-AST misses, especially `extract_intermediate_signals_from_expression(...)` and the legacy-named filter fallback,
  - keep deferring dormant standalone declaration-helper cleanup unless it becomes live or is being removed outright.
## AST/CoreAST convergence update (March 11, 2026, recovery slice)
- Latest completed slice in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`:
  - late expression hydration can now recover runtime ASTs for signals whose earlier miss was only `no_ast_source`,
  - dependency extraction now renders first and then re-checks runtime AST availability, so recovered ASTs are used in the same consolidated pass,
  - this reduces the population of true compatibility-only misses without touching dormant helper paths.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` => `Files=6`, `Tests=125`, `PASS`
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `e4af447` `SystemVerilog: cache runtime AST miss state`
  - `548ca11` `SystemVerilog: cache consolidated rendered expressions`
  - `2480832` `SystemVerilog: cache consolidated intermediate dependencies`
- Highest-value next seam after this slice:
  - narrow the remaining hard compatibility misses where runtime-AST recovery still cannot succeed, especially expression-parse failures and the fallback helper path that still carries the old string-era name,
  - keep deferring dormant standalone declaration-helper cleanup unless it becomes live or is being removed outright.
## AST/CoreAST convergence update (March 12, 2026, dependency-miss recovery slice)
- Latest completed slice in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`:
  - explicit runtime-AST misses during dependency extraction now flow through `extract_intermediate_signals_from_runtime_ast_miss(...)`,
  - the live path skips re-parsing the same stored expression after a known `expression_parse_failed` miss,
  - dependency extraction now probes alternate known expressions from `EnableGraph` before dropping to identifier scanning,
  - when one of those alternate expressions parses, the backend caches the recovered runtime AST and refreshes width metadata so later live-path phases can reuse the AST-backed signal.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` => `Files=6`, `Tests=125`, `PASS`
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `85aa70d` `SystemVerilog: recover runtime ASTs after late expressions`
  - `e4af447` `SystemVerilog: cache runtime AST miss state`
  - `548ca11` `SystemVerilog: cache consolidated rendered expressions`
- Highest-value next seam after this slice:
  - narrow the remaining explicit-miss filtering residue, especially the legacy-named `should_filter_string_based(...)` path,
  - after that, reduce or retire the final identifier-scan compatibility fallback if no additional AST-backed recovery source remains.
## AST/CoreAST convergence update (March 12, 2026, live-usage filtering slice)
- Latest completed slice in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`:
  - the live consolidated path now caches AST-derived live-usage metadata per intermediate signal,
  - AST-backed filtering and explicit runtime-AST-miss filtering both consume that normalized metadata,
  - explicit misses now flow through `should_filter_runtime_ast_miss(...)` while `should_filter_string_based(...)` remains only as a compatibility wrapper.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` => `Files=6`, `Tests=125`, `PASS`
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `8342857` `SystemVerilog: recover runtime ASTs in dependency fallback`
  - `85aa70d` `SystemVerilog: recover runtime ASTs after late expressions`
  - `e4af447` `SystemVerilog: cache runtime AST miss state`
- Highest-value next seam after this slice:
  - retire or bypass the remaining legacy-named filtering wrapper entirely once no live path needs it,
  - then tighten the last identifier-scan compatibility fallback in dependency extraction if another AST-backed recovery source can replace it.
## AST/CoreAST convergence update (March 12, 2026, unresolved-miss cleanup slice)
- Latest completed slice in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` and `t/07-runtime-ast-miss-dependency-recovery.t`:
  - removed the final `scan_intermediate_signal_names_in_expression(...)` regex fallback from runtime-AST-miss dependency recovery,
  - explicit hard misses now stop at AST-backed recovery sources and record `runtime_ast_miss_unresolved` instead of inferring dependencies from opaque invalid strings,
  - the focused regression now proves opaque invalid expressions like `mid @@ aux` no longer recover `mid`/`aux` through identifier mining.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/07-runtime-ast-miss-dependency-recovery.t` => `Files=1`, `Tests=8`, `PASS`
  - `prove -I perl t` => `Files=8`, `Tests=143`, `PASS`
- Additional audit completed for this slice:
  - read-only instrumentation on known-good fixtures (`fsm/trial_0.fsm`, `fsm/trial_1.fsm`, `fsm/trial_2.fsm`, `fsm/mipicsi2_tester_ctrl.fsm`) reported zero live hits on the identifier-scan fallback before removal.
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `9a3e386` `EnableGraph: recover legacy signal-name deps via AST`
  - `621da16` `CoreAST: canonicalize driving AST storage`
  - `3243d00` `SystemVerilog: recover deps from signal-name ASTs`
- Highest-value next seam after this slice:
  - characterize which remaining opaque `legacy_string_registry` producers still fail to provide native defining AST or typed dependency metadata,
  - keep shrinking or retiring other dormant string-era compatibility helpers once they are proven dead in the live path.
## AST/CoreAST convergence update (March 13, 2026, dead-LHS/RHS-tracking cleanup slice)
- Latest completed slice in `perl/FSM/HDL/FlattenedDT.pm`, `perl/FSM/HDL/FlattenedDT/Orchestrator.pm`, and `t/10-ast-first-enable-structure.t`:
  - removed the dormant LHS/RHS completeness-tracking family from `FlattenedDT`, including the legacy `expected_lhs_rhs` / `actual_lhs_rhs` / `missing_lhs_rhs` state and the raw-AST walker/formatter helpers that only existed to feed that validation lane,
  - removed the assignment/transition capture instrumentation in `Orchestrator` that still wrote `actual_lhs_rhs` entries even though no live path consumed them,
  - extended the AST-first enable-structure regression to assert that live generation leaves no legacy LHS/RHS tracking state behind.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Orchestrator.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` => `Files=1`, `Tests=9`, `PASS`
  - `prove -I perl t` => `Files=10`, `Tests=155`, `PASS`
- Additional audit completed for this slice:
  - repo-wide reference checks showed the retired LHS/RHS tracking helpers and state names remained only in docs and the new regression assertions,
  - the only live writes into that lane had been the `Orchestrator` assignment/transition capture hooks, and no runtime/backend path read the resulting hashes.
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `0aa9a84` `FlattenedDT: retire dead string-era condition and WEN helpers`
  - `918a2ca` `FlattenedDT: retire dead string-era factorization helpers`
  - `45d3320` `SystemVerilog: retire identifier-scan dependency fallback`
- Highest-value next seam after this slice:
  - re-audit the remaining unreferenced `FlattenedDT` helper pockets, especially declaration-scheduling and substituted-AST matching helpers, to find the next dead surface that can be retired without perturbing the live AST/CoreAST path,
  - keep preferring slices that delete provably dead compatibility state over widening live backend/orchestrator behavior.
## AST/CoreAST convergence update (March 13, 2026, dead-standalone-declaration-helper cleanup slice)
- Latest completed slice in `perl/FSM/HDL/FlattenedDT.pm`, `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`, and `t/10-ast-first-enable-structure.t`:
  - removed the dead standalone intermediate-declaration helper lane from `FlattenedDT`, including `schedule_intermediate_signal_for_declaration(...)`, the compatibility-only `generate_intermediate_signal_declarations(...)` delegate, and the adjacent unreferenced `get_combinational_lhs_signals(...)` helper,
  - removed the backend-side `generate_intermediate_signal_declarations(...)` implementation that no live call path used once consolidated intermediate emission became authoritative,
  - extended the AST-first enable-structure regression to assert that live generation leaves no legacy `intermediate_signals_to_declare` scratch state behind.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t/10-ast-first-enable-structure.t` => `Files=1`, `Tests=10`, `PASS`
  - `prove -I perl t` => `Files=10`, `Tests=156`, `PASS`
- Additional audit completed for this slice:
  - repo-wide reference checks showed the retired declaration helper names had no remaining code callers and only the new regression assertion mentions the retired scratch-state name,
  - the live declaration path already emits intermediate wires through consolidated emission/internal declarations rather than the old standalone helper lane.
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `413d6cb` `FlattenedDT: retire dead LHS/RHS tracking`
  - `0aa9a84` `FlattenedDT: retire dead string-era condition and WEN helpers`
  - `918a2ca` `FlattenedDT: retire dead string-era factorization helpers`
- Highest-value next seam after this slice:
  - re-audit the remaining substituted-AST matching helper pocket in `FlattenedDT` (`find_substituted_ast`, `ast_contains_intermediate_signal_references`, `expressions_are_equivalent`, `extract_expression_structure`, `ast_structures_match`) to confirm whether it is now fully dead,
  - keep deleting provably dead compatibility helpers before considering larger live-path ownership moves.
## AST/CoreAST convergence update (March 13, 2026, dead-substituted-AST-matching-helper cleanup slice)
- Latest completed slice in `perl/FSM/HDL/FlattenedDT.pm`:
  - removed the dead substituted-AST matching helper pocket, including `signal_name_matches_operation(...)`, `find_substituted_ast(...)`, `ast_contains_intermediate_signal_references(...)`, `expressions_are_equivalent(...)`, `extract_expression_structure(...)`, and `ast_structures_match(...)`,
  - removed the now-unused `Data::Dumper`, `Scalar::Util qw(blessed)`, and `List::Util qw(min max)` imports that only supported that dead helper lane.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` => `Files=10`, `Tests=156`, `PASS`
- Additional audit completed for this slice:
  - repo-wide reference checks showed the retired helper names had no remaining code callers and only historical docs still mention the old pocket,
  - the active substitution/factorization flow already routes through backend-owned helpers such as `update_original_asts_with_substituted_versions(...)`, `get_substituted_ast_for_signal(...)`, and `is_signal_referenced_in_substitutions(...)`.
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `ce1d9b9` `FlattenedDT: retire dead declaration helpers`
  - `413d6cb` `FlattenedDT: retire dead LHS/RHS tracking`
  - `0aa9a84` `FlattenedDT: retire dead string-era condition and WEN helpers`
- Highest-value next seam after this slice:
  - re-audit the remaining substitution-era helper surface in `FlattenedDT` and `Backend/SystemVerilog` to identify the next truly dead residue versus the still-live backend-owned helpers,
  - if no more dead pockets remain nearby, shift back to the next smallest live AST/CoreAST-first ownership seam rather than forcing more facade cleanup.
## AST/CoreAST convergence update (March 12, 2026, dead-condition-and-wen-helper cleanup slice)
- Latest completed slice in `perl/FSM/HDL/FlattenedDT.pm` and `t/10-ast-first-enable-structure.t`:
  - removed the dormant string-era condition/WEN helper island that still exposed a parallel string-based path for assignment recording, condition formatting, raw condition-string extraction, and DT-specific/LHS-level WEN generation,
  - removed the delegator helpers that only existed to support that dead path (`clean_signal_name`, `generate_rhs_based_enable_name`, `is_complex_expression`, `get_or_create_global_expression`, `should_factor_condition`, `needs_parentheses`),
  - added a focused regression proving that live enable synthesis stores AST-backed DT/LHS enable metadata inside `assignment_analysis->{rhs_groups}` and does not repopulate the old top-level `dt_specific_enables` / `lhs_to_enable_value_pairs` state.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t/09-ast-first-intermediate-registry.t t/10-ast-first-enable-structure.t` => `Files=2`, `Tests=9`, `PASS`
  - `prove -I perl t` => `Files=10`, `Tests=152`, `PASS`
- Additional audit completed for this slice:
  - repo-wide reference checks showed the retired helper names remained only in `DEVELOPMENT_NOTES.md` and `MEMORY.md`,
  - the live path already records assignments/transitions through `FlattenedDT::Orchestrator` and synthesizes DT/LHS enable metadata inside `EnableGraph`-owned `assignment_analysis->{rhs_groups}`.
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `918a2ca` `FlattenedDT: retire dead string-era factorization helpers`
  - `45d3320` `SystemVerilog: retire identifier-scan dependency fallback`
  - `9a3e386` `EnableGraph: recover legacy signal-name deps via AST`
- Highest-value next seam after this slice:
  - re-audit the remaining `FlattenedDT` compatibility/helper surface to find the next dead string-era island or delegation round-trip that can be removed without touching the live AST/CoreAST path,
  - keep validating against the AST-backed `assignment_analysis->{rhs_groups}` enable structure instead of reintroducing top-level compatibility state.
## AST/CoreAST convergence update (March 12, 2026, dead-factorization-cluster cleanup slice)
- Latest completed slice in `perl/FSM/HDL/FlattenedDT.pm` and `t/09-ast-first-intermediate-registry.t`:
  - removed the dormant string-era factorization/helper cluster that still wrote plain-string `intermediate_signals` entries in the old `FlattenedDT` facade,
  - updated the remaining `intermediate_signals` comment/contract to reflect metadata-hash storage rather than raw expression-string storage,
  - added a focused regression proving that live generation leaves no plain-string or `legacy_string_registry` intermediate entries behind.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t/09-ast-first-intermediate-registry.t` => `Files=1`, `Tests=3`, `PASS`
  - `prove -I perl t` => `Files=9`, `Tests=146`, `PASS`
- Additional audit completed for this slice:
  - read-only runs on known-good fixtures (`fsm/trial_0.fsm`, `fsm/trial_1.fsm`, `fsm/trial_2.fsm`, `fsm/mipicsi2_tester_ctrl.fsm`) showed the live generator already finishing with an empty `intermediate_signals` registry, confirming the removed helpers were dead compatibility residue.
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `45d3320` `SystemVerilog: retire identifier-scan dependency fallback`
  - `9a3e386` `EnableGraph: recover legacy signal-name deps via AST`
  - `621da16` `CoreAST: canonicalize driving AST storage`
- Highest-value next seam after this slice:
  - audit and retire the remaining dead string-era `FlattenedDT.pm` condition / DT-specific WEN helper cluster if it is still unreferenced,
  - otherwise keep moving source-side compatibility producers onto native AST/CoreAST metadata instead of rebuilding fallback logic downstream.
## AST/CoreAST convergence update (March 12, 2026, wrapper-retirement slice)
- Latest completed slice in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` and `perl/FSM/HDL/FlattenedDT.pm`:
  - removed the unused legacy-named wrapper entrypoints `should_filter_string_based(...)` and `extract_intermediate_signals_from_expression(...)`,
  - the repo surface now exposes only the runtime-shape helpers that are still semantically meaningful on this lane (`should_filter_runtime_ast_miss(...)`, `extract_intermediate_signals_from_runtime_ast_miss(...)`).
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT.pm`
  - `prove -I perl t` => `Files=6`, `Tests=125`, `PASS`
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `8467c9f` `SystemVerilog: cache live usage for miss filtering`
  - `8342857` `SystemVerilog: recover runtime ASTs in dependency fallback`
  - `85aa70d` `SystemVerilog: recover runtime ASTs after late expressions`
- Highest-value next seam after this slice:
  - tighten or replace the final identifier-scan compatibility fallback in `extract_intermediate_signals_from_runtime_ast_miss(...)`,
  - keep ignoring dormant standalone declaration helpers unless they become live or can be retired outright.
## AST/CoreAST convergence update (March 12, 2026, cleaned-dependency-recovery slice)
- Latest completed slice in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`:
  - `extract_intermediate_signals_from_runtime_ast_miss(...)` now tries cleaned-expression AST recovery before dropping to identifier scanning,
  - cleaned compatibility parse success is cached back onto runtime-AST metadata,
  - the slice preserves already-rendered expression text when the recovered AST came from the cleaned variant.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` => `Files=6`, `Tests=125`, `PASS`
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `12df12b` `SystemVerilog: retire dead string-era wrapper helpers`
  - `8467c9f` `SystemVerilog: cache live usage for miss filtering`
  - `8342857` `SystemVerilog: recover runtime ASTs in dependency fallback`
- Highest-value next seam after this slice:
  - reduce or replace the remaining identifier-scan fallback itself inside `extract_intermediate_signals_from_runtime_ast_miss(...)`,
  - keep ignoring dormant standalone declaration helpers unless they become live or can be retired outright.
## AST/CoreAST convergence update (March 12, 2026, signal-name-dependency-AST slice)
- Latest completed slice in `perl/FSM/Synthesis/EnableGraph.pm` and `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`:
  - `EnableGraph` can now recover a dependency-oriented AST from AST-generated intermediate signal names when factorizer/global-expression metadata says the name came from AST naming,
  - that recovery keeps direct intermediate operands as leaf refs instead of expanding them transitively,
  - explicit runtime-AST misses now use this signal-name AST path before the final regex identifier scan.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` => `Files=7`, `Tests=130`, `PASS`
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `8c445bf` `SystemVerilog: recover runtime ASTs before dep scan`
  - `d9a12dd` `SystemVerilog: recover deps from cleaned expressions`
  - `12df12b` `SystemVerilog: retire dead string-era wrapper helpers`
- Highest-value next seam after this slice:
  - shrink or replace the last regex identifier scan for legacy/non-AST-named hard misses,
  - keep ignoring dormant standalone declaration helpers unless they become live or can be retired outright.
## AST/CoreAST convergence update (March 12, 2026, canonical-driving-ast slice)
- Latest completed slice in `perl/FSM/CoreAST.pm`, `perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm`, and `perl/FSM/Adapter/FSMGenFull/Parser.pm`:
  - `FSM::CoreAST::Signal` now canonicalizes `set_attribute('driving_ast', ...)` onto the real `driving_ast` field and returns that canonical value through `get_attribute('driving_ast')`,
  - active frontend intermediate-signal creation now uses `set_driving_ast(...)` directly,
  - backend runtime-AST normalization can therefore recover those parser-created intermediates through the native defining-AST path instead of depending on downstream compatibility recovery.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/CoreAST.pm`
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm`
  - `perl -I perl -c perl/FSM/Adapter/FSMGenFull/Parser.pm`
  - `prove -I perl t` => `Files=8`, `Tests=140`, `PASS`
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `3243d00` `SystemVerilog: recover deps from signal-name ASTs`
  - `8c445bf` `SystemVerilog: recover runtime ASTs before dep scan`
  - `d9a12dd` `SystemVerilog: recover deps from cleaned expressions`
- Highest-value next seam after this slice:
  - re-audit the remaining regex identifier scan after this upstream native-AST fix and remove any now-dead compatibility residue,
  - keep ignoring dormant standalone declaration helpers unless they become live or can be retired outright.
## AST/CoreAST convergence update (March 12, 2026, conservative-legacy-signal-name slice)
- Latest completed slice in `perl/FSM/Synthesis/EnableGraph.pm` and `t/07-runtime-ast-miss-dependency-recovery.t`:
  - conservative `legacy_string_registry` names can now use the same signal-name AST dependency recovery path as AST-generated names,
  - systematic legacy names now recover dependencies through AST construction/traversal,
  - only opaque legacy names still fall through to the final regex identifier scan.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/Synthesis/EnableGraph.pm`
  - `prove -I perl t` => `Files=8`, `Tests=143`, `PASS`
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `621da16` `CoreAST: canonicalize driving AST storage`
  - `3243d00` `SystemVerilog: recover deps from signal-name ASTs`
  - `8c445bf` `SystemVerilog: recover runtime ASTs before dep scan`
- Highest-value next seam after this slice:
  - inspect whether any live callers still need the final regex identifier scan at all once opaque legacy names are characterized,
  - keep ignoring dormant standalone declaration helpers unless they become live or can be retired outright.
## AST/CoreAST convergence update (March 12, 2026, earlier-cleaned-runtime-AST slice)
- Latest completed slice in `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`:
  - `resolve_intermediate_signal_runtime_ast(...)` now attempts cleaned-expression parsing after a stored-expression parse miss,
  - cleaned-expression success is cached as runtime-AST metadata,
  - `render_intermediate_signal_expression(...)` preserves the original stored expression text when the recovered runtime AST came from a cleaned compatibility expression.
- Validation completed for this slice:
  - `perl -I perl -c perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm`
  - `prove -I perl t` => `Files=6`, `Tests=125`, `PASS`
- Recent AST/CoreAST convergence commits immediately before the next commit:
  - `d9a12dd` `SystemVerilog: recover deps from cleaned expressions`
  - `12df12b` `SystemVerilog: retire dead string-era wrapper helpers`
  - `8467c9f` `SystemVerilog: cache live usage for miss filtering`
- Highest-value next seam after this slice:
  - reduce or replace the remaining identifier-scan fallback itself inside `extract_intermediate_signals_from_runtime_ast_miss(...)`,
  - keep ignoring dormant standalone declaration helpers unless they become live or can be retired outright.
## 2026-03-15: malformed `:=` RHS values now fail early through the directive contract
- [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now turns malformed `:=` RHS values into the dedicated init/reset-contract diagnostic instead of leaking raw expression-parser failures.
- [t/56-language-contract-init-directive-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/56-language-contract-init-directive-boundary.t) now locks:
  - unsupported RHS values such as `[DATAIN]` and `<start`,
  - and pipeline/CLI no-output behavior for malformed `:=` RHS values.
- [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now documents the malformed-RHS side of the active `:=` boundary explicitly.

## 2026-03-15: computed test-selector malformed forms now fail early
- [perl/FSM/Adapter/FSMGenFull/Parser.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Adapter/FSMGenFull/Parser.pm) now rejects malformed `?(expr)` forms explicitly instead of letting them fall into incidental expression/parser errors.
- [t/55-language-contract-computed-test-selector-boundary.t](/Users/richarddje/Documents/github/fsmgen/t/55-language-contract-computed-test-selector-boundary.t) now locks:
  - missing-expression computed selectors like `(? (=0 ...))`,
  - branchless computed selectors like `(?(| A B))`,
  - and pipeline/CLI no-output behavior for those malformed forms.
- [docs/USER_GUIDE.md](/Users/richarddje/Documents/github/fsmgen/docs/USER_GUIDE.md) now states the malformed boundary explicitly next to the supported `?(expr)` form.

## 2026-03-19: duplicate-driver failed summaries now keep child-target context too
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now explicitly locks both blocked explicit-link duplicate-driver target families:
  - top-boundary targets keep `Context: Top port '...'`
  - child-input targets keep `Context: Child endpoint 'instance.port'`
- Runtime behavior was already extractor-based from the raised diagnostic; this slice makes the child-target side provable and keeps the concise reason focused on the earlier explicit link that already reserved the target.

## 2026-03-19: explicit-link width-mismatch failed summaries now keep target context
- [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) now recognizes the existing blocked explicit-link width-mismatch diagnostic shape (`links '...' (width ...) to '...' (width ...)`) as target context.
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now locks the reachable child-target width-mismatch summary shape so non-quiet failed runs keep:
  - `Construct: ?toplink`
  - `Context: Child endpoint 'consumer.input_data'`
  - `Blocked boundary: explicit link`
  - `Reason: the current active composition lanes require exact width agreement`

## 2026-03-19: explicit-link width-mismatch summary coverage now locks the top-port side too
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now also locks the sibling explicit-link width-mismatch family where the blocked target is the declared top output.
- Non-quiet failed runs are now explicitly regression-backed to keep:
  - `Context: Top port 'result_data'`
  - `Blocked boundary: explicit link`
  - `Reason: the current active composition lanes require exact width agreement`

## 2026-03-19: explicit-link multi-top-output summaries now keep source context
- [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) now recognizes the existing blocked explicit-link topology diagnostic shape `drives multiple top outputs from '...'` as structured context.
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now locks the reachable summary shape so non-quiet failed runs keep:
  - `Lane: C2`
  - `Construct: ?toplink`
  - `Context: Child endpoint 'producer.output_data'`
  - `Blocked boundary: explicit-link topology`
  - `Reason: the current active C2 lane supports at most one top-output target per resolved source`

## 2026-03-19: explicit-link top-to-top summaries now keep top-port source context
- [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) now recognizes the sibling blocked topology diagnostic shape `links top input '...' directly to top output '...'` as structured context.
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now locks the reachable summary shape so non-quiet failed runs keep:
  - `Lane: C2`
  - `Construct: ?toplink`
  - `Context: Top port 'start'`
  - `Blocked boundary: explicit-link topology`
  - `Reason: the current active C2 lane only supports top inputs driving child inputs`

## 2026-03-19: explicit-link lane-entry summaries now explicitly avoid fabricated context
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now locks the missing-`?toplink` explicit-link lane-entry family so non-quiet failed runs keep:
  - `Lane: C2`
  - `Construct: ?toplink`
  - `Blocked boundary: explicit-link lane entry`
  - `Reason: the current active C2 lane requires explicit '?toplink' wiring`
  - and no `Context:` line
- Runtime behavior was already correct here; this slice makes the no-invented-context contract provable.

## 2026-03-19: duplicate-declaration summaries now keep duplicate-name context
- [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) now recognizes duplicate top-port and duplicate child-instance declaration diagnostics as structured failed-run summary context.
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now locks the reachable summary shapes so non-quiet failed runs keep:
  - `Construct: ?ports` plus `Context: Top port 'output_data'` for duplicate top-port declarations
  - `Context: Child 'dup'` for duplicate child-instance declarations
  - `Blocked boundary: shape` plus the existing uniqueness reason for both families
- This is a small extractor/classification improvement only; planner behavior is unchanged.

## 2026-03-19: explicit-link role-mismatch summaries now cover the remaining sibling families too
- [t/23-composition-errors.t](/Users/richarddje/Documents/github/fsmgen/t/23-composition-errors.t) now locks the direct blocked diagnostics for:
  - child-endpoint sources used as explicit-link sources when that child port is input instead of output
  - top-port targets used as explicit-link targets when that top port is input instead of output
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now locks the matching failed-run summary shapes so non-quiet runs keep:
  - `Context: Child endpoint 'consumer.input_data'`
  - `Context: Top port 'start'`
  - the blocked `explicit link` boundary and the existing concise role-mismatch reasons
- Runtime behavior was already correct here; this slice makes the sibling role-mismatch summary contract explicit.

## 2026-03-19: missing generated-child source-resolution summaries now cover both constructs
- [t/115-composition-child-source-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/115-composition-child-source-diagnostics.t) now also locks the direct blocked missing-`?dtc` source-resolution diagnostic beside the earlier missing-`?fsmc` one.
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now locks the matching failed-run summary shapes so non-quiet runs keep:
  - `Construct: ?fsmc` plus `Context: Child 'missing_src'`
  - `Construct: ?dtc` plus `Context: Child 'missing_dt_src'`
  - the blocked `child-source resolution` boundary and the existing concise missing-source reason
  - and no invented `Child source file:` artifact when no external file was resolved
- Runtime behavior was already correct here; this slice makes the unresolved-source summary contract explicit for both generated-child constructs.

## 2026-03-19: wrong-kind generated-child realization summaries now cover both constructs
- [t/115-composition-child-source-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/115-composition-child-source-diagnostics.t) now also locks the direct CLI diagnostic for wrong-kind external `?dtc` children beside the earlier wrong-kind `?fsmc` one.
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now locks the matching failed-run summary shapes so non-quiet runs keep:
  - `Construct: ?fsmc` plus `Child source file` and `Context: Child 'route_src'`
  - `Construct: ?dtc` plus `Child source file` and `Context: Child 'child_src'`
  - the blocked `child-source realization` boundary and the existing concise wrong-kind reason
- Runtime behavior was already correct here; this slice makes the wrong-kind realization summary contract explicit for both generated-child constructs.

## 2026-03-19: parser-boundary summaries now cover mapping directives and malformed top-link tokens
- [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) now recognizes `mapping directive '...'` diagnostics as structured failed-run summary context.
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now locks the matching failed-run summary shapes so non-quiet runs keep:
  - `Construct: ?ports` plus `Context: Mapping directive '/foo/bar/'`
  - `Construct: ?toplink` plus `Context: Token 'child.result_data->result_data'`
  - the blocked parser-boundary labels and the existing concise parser reasons
- Parser behavior was already correct here; this slice improves only the failed-run summary surface for the `?ports` mapping-directive family and makes both parser-boundary summary contracts explicit.

## 2026-03-19: the remaining ?ports token-family summaries now have explicit contracts
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now also locks the matching failed-run summary shapes so non-quiet runs keep:
  - `Construct: ?ports` plus `Context: Token 'bad-name>8'` for invalid explicit top-port tokens
  - `Construct: ?ports` plus `Context: Token 'data_in<0'` for non-positive width tokens
  - the blocked parser-boundary labels and the existing concise parser reasons for both siblings
- Runtime behavior was already correct here; this slice makes the remaining `?ports` parser-token summary contracts explicit.

## 2026-03-19: malformed generated-child parser summaries now keep child context too
- [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) now recognizes blocked `contains '?fsmc' child '...'` / `contains '?dtc' child '...'` parser diagnostics as structured child context in failed-run summaries.
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now locks the matching failed-run summary shapes so non-quiet runs keep:
  - `Construct: ?fsmc` plus `Context: Child 'child'` for blocked source-count failures
  - `Construct: ?dtc` plus `Context: Child 'child'` for blocked source-shape failures
  - the blocked child-source boundary labels and the existing concise parser reasons for both families
- Parser behavior is unchanged here; this slice improves only the failed-run summary surface for malformed generated-child declarations.

## 2026-03-19: malformed child item-list parser summaries now keep construct context too
- [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) now recognizes known child headers like `?fsmc:child` inside blocked `contains child '...'` parser diagnostics as construct-scoped failed-run summaries too.
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now locks the matching failed-run summary shape so non-quiet runs keep:
  - `Construct: ?fsmc`
  - `Context: Child '?fsmc:child'`
  - the blocked `child item-list shape` boundary and the existing concise dotted-pair-contract reason
- Parser behavior is unchanged here; this slice improves only the failed-run summary surface for malformed child item-list payloads.

## 2026-03-19: the dotted-pair child-item summary contract now covers ?toplink too
- [t/128-composition-child-structure-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/128-composition-child-structure-diagnostics.t) now also locks the direct blocked dotted-pair `?toplink:wiring` diagnostic beside the earlier `?fsmc:child` case.
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now locks the matching failed-run summary shape so non-quiet runs keep:
  - `Construct: ?toplink`
  - `Context: Child '?toplink:wiring'`
  - the blocked `child item-list shape` boundary and the existing concise dotted-pair-contract reason
- Runtime behavior was already correct here; this slice makes the `?toplink` child-item summary contract explicit too.

## 2026-03-19: the dotted-pair child-item summary contract now covers ?ports too
- [t/128-composition-child-structure-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/128-composition-child-structure-diagnostics.t) now also locks the direct blocked dotted-pair `?ports` diagnostic beside the earlier `?fsmc:child` and `?toplink:wiring` cases.
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now locks the matching failed-run summary shape so non-quiet runs keep:
  - `Construct: ?ports`
  - `Context: Child '?ports'`
  - the blocked `child item-list shape` boundary and the existing concise dotted-pair-contract reason
- Runtime behavior was already correct here; this slice makes the `?ports` child-item summary contract explicit too.

## 2026-03-19: the dotted-pair child-item summary contract now covers ?dtc too
- [t/128-composition-child-structure-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/128-composition-child-structure-diagnostics.t) now also locks the direct blocked dotted-pair `?dtc:child` diagnostic beside the earlier `?fsmc:child`, `?toplink:wiring`, and `?ports` cases.
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now locks the matching failed-run summary shape so non-quiet runs keep:
  - `Construct: ?dtc`
  - `Context: Child '?dtc:child'`
  - the blocked `child item-list shape` boundary and the existing concise dotted-pair-contract reason
- Runtime behavior was already correct here; this slice makes the `?dtc` child-item summary contract explicit too.

## 2026-03-19: the dotted-pair child-item summary contract now covers ?rtl too
- [t/128-composition-child-structure-diagnostics.t](/Users/richarddje/Documents/github/fsmgen/t/128-composition-child-structure-diagnostics.t) now also locks the direct blocked dotted-pair `?rtl:uart_tx` diagnostic beside the earlier `?fsmc:child`, `?toplink:wiring`, `?ports`, and `?dtc:child` cases.
- [t/131-composition-failure-summary-reporting.t](/Users/richarddje/Documents/github/fsmgen/t/131-composition-failure-summary-reporting.t) now locks the matching failed-run summary shape so non-quiet runs keep:
  - `Construct: ?rtl`
  - `Context: Child '?rtl:uart_tx'`
  - the blocked `child item-list shape` boundary and the existing concise dotted-pair-contract reason
- Runtime behavior was already correct here; this slice makes the `?rtl` child-item summary contract explicit too.

## 2026-03-21: shared-datapath candidates now expose source-enable aliases and onehot0 assertion metadata
- [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) now extends shared-datapath candidate metadata with:
  - deterministic per-child `source_enable_signal` aliases on aggregate value-family contributors,
  - `same_value_assertion` onehot0 metadata over those source-enable aliases,
  - and `multi_value_assertion` onehot0 metadata over the aggregate value-enable families.
- [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) now prints those planned multi-value and same-value onehot0 inputs in non-quiet `Shared-Datapath Candidates` summaries.
- [t/142-composition-shared-datapath-assertion-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/142-composition-shared-datapath-assertion-metadata.t) locks the new assertion-planning metadata directly, while [t/139-composition-shared-datapath-candidate-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/139-composition-shared-datapath-candidate-metadata.t), [t/140-composition-shared-datapath-drive-intent-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/140-composition-shared-datapath-drive-intent-metadata.t), and [t/141-composition-shared-datapath-aggregate-enable-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/141-composition-shared-datapath-aggregate-enable-metadata.t) now also include the new nested metadata surface.
- This is still planning/export metadata, not lifted shared-datapath HDL emission, but it makes the assertion side of the contract explicit enough for later lifting work.

## 2026-03-21: shared-datapath candidates now expose lifted-ownership planning metadata
- [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm) now extends shared-datapath candidate metadata with:
  - `storage_class`,
  - `peer_input_count`,
  - `peer_input_endpoints`,
  - `default_lifted_visibility`,
  - `planned_reexport_top_output_signals`,
  - and `loopback_allowed`.
- [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen) now prints those planned storage/visibility/re-export/loopback decisions in non-quiet `Shared-Datapath Candidates` summaries.
- [t/143-composition-shared-datapath-visibility-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/143-composition-shared-datapath-visibility-metadata.t) locks the bounded registered peer-read case directly, while [t/139-composition-shared-datapath-candidate-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/139-composition-shared-datapath-candidate-metadata.t), [t/140-composition-shared-datapath-drive-intent-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/140-composition-shared-datapath-drive-intent-metadata.t), and [t/141-composition-shared-datapath-aggregate-enable-metadata.t](/Users/richarddje/Documents/github/fsmgen/t/141-composition-shared-datapath-aggregate-enable-metadata.t) now include the new default top-output case too.
- This is still planning/export metadata rather than emitted lifted shared-datapath HDL, but it makes the registered peer-read internalization rule concrete enough for later lifting work.

## 2026-03-21: logged long-term HDL import / intent recovery direction
- [ROADMAP_V2.md](/Users/richarddje/Documents/github/fsmgen/ROADMAP_V2.md) now tracks a new long-term horizon goal for HDL-to-`.fsm` work.
- The saved guidance is explicit:
  - treat this as bounded HDL import / intent recovery rather than exact reverse compilation,
  - start with `fsmgen`-generated `SystemVerilog` as the first honest round-trip/import target,
  - keep synthesizable RTL as the real import boundary,
  - then only later widen into bounded handwritten `SystemVerilog` / `VHDL` recovery,
  - and always surface what was recognized, heuristically recovered, or left unsupported.
- This is a logged design direction only; no runtime behavior changed.

## 2026-03-21: refined the HDL-import horizon note around synthesizable RTL and recovery scope
- The saved HDL-import direction now also records the stronger follow-up refinement:
  - “start with simpler recognizable hierarchy” is sequencing guidance, not a permanent ceiling,
  - richer hierarchy, generate-heavy RTL, macro/preprocessor-heavy RTL, and some optimized logic are still valid later targets,
  - parser support alone is not enough and the note now explicitly calls for preprocessing/elaboration plus a typed canonical RTL IR with provenance,
  - and `.fsm` is allowed to grow new first-class semantic constructs if repeated honest recovery work shows that the current design-intent vocabulary is too small.
- The saved honesty rule is also explicit now:
  - recover real intent where the evidence is strong,
  - and keep ambiguity or opaque logic visible as residue instead of forcing a fake high-level reconstruction.

## 2026-03-21: clarified that HDL import still needs frontend semantic compilation before elaboration
- The saved HDL-import direction now also distinguishes “no full backend compile needed” from “no compilation work needed,” because those are not the same.
- The saved clarification is:
  - no synthesis/backend compile is required for the import lane itself,
  - but elaboration still depends on real frontend semantic compilation work after preprocessing,
  - so the expected importer shape is now explicitly `preprocess -> parse -> semantic resolution -> elaboration -> canonical RTL IR -> intent recovery -> recovery report`.
- `R11` shared-datapath planning now also exposes a bounded combinational peer-read policy surface: shared combinational output families that feed peer child inputs stay top-output-only, report a block reason, and print that rule in non-quiet `bin/fsmgen` summaries.
- `R11` shared-datapath now has a first real runtime HDL slice on top of the earlier metadata: realized `?fsmc` children export hidden per-value enable ports, composition tops bind those exports into deterministic source-enable alias nets, and the top now emits aggregate/conflict helper wires from that surface.
- `R11` shared-datapath now also has its first actual lifted registered ownership/runtime slice:
  - bounded registered peer-read families with explicit public re-exports now surface reset-aware lifted-runtime metadata,
  - generated tops emit one shared lifted register plus next-value logic for that case,
  - peer-read child inputs are rebound to that lifted shared register,
  - contributor outputs are rebound to private raw nets,
  - and the kept public top outputs are re-exported from the lifted shared register rather than directly from one child.

## 2026-03-22: logged the planned shared IR architecture for forward compilation and HDL recovery
- The saved long-term HDL-import note now also records the IR split more explicitly:
  - forward `.fsm -> HDL` should converge toward `AST -> semantic Intent HIR -> Lowered RTL IR -> Structural RTL IR / Connectivity IR -> backend`,
  - reverse `HDL -> .fsm` should converge toward `HDL CST/AST -> semantic HDL HIR -> elaborated RTL IR -> Flat IR -> recovered Intent IR -> .fsm + recovery report`,
  - and the reverse path should not call its early layer a “non-semantic HIR” because the non-semantic layer is just the parsed HDL tree.
- The saved architecture rule is now:
  - keep surface trees separate,
  - keep early HDL-specific semantic work separate,
  - but share the semantic middle where possible through `Intent HIR`, `Lowered RTL IR`, one future `Structural RTL IR` / connectivity layer, and maybe a shared `Flat IR`/provenance model later.

## 2026-03-22: forward IR focus now explicitly includes a structural connectivity layer
- We clarified that the current extracted `Lowered RTL IR` is still a lowered summary layer, not yet the full explicit connectivity graph of the emitted HDL.
- Saved direction:
  - keep pushing on `Intent HIR`,
  - keep pushing on `Lowered RTL IR`,
  - and plan for one explicit `Structural RTL IR` / connectivity layer that behaves like an AST/netlist for ports, nets, instances, pin bindings, and auxiliary connectivity so the backend can walk full top/child wiring directly.
- Structural-layer refinement now also saved:
  - `Structural RTL IR` should stay backend-neutral and extensible rather than becoming a raw SystemVerilog/VHDL syntax dump,
  - child actual-pin bindings should eventually be represented through typed structural connection expressions / actual-connection AST nodes,
  - those connection expressions should be able to grow toward durable connectivity forms such as references, literals, slices/part-selects, concatenations, member/index access, and bounded open/default associations,
  - and backend-specific or inelegant connection shapes should instead normalize earlier into helper nets or auxiliary assignments before the structural binding boundary.

## 2026-03-22: started the first active forward IR extraction slice under `R11`
- The first live forward `.fsm -> HDL` IR extraction is now in tree:
  - `FSM::IR::IntentHIR` exists as an explicit forward semantic summary,
  - direct generation results now expose `intent_hir`,
  - realized generated children now preserve that same summary through `module_info`,
  - and the active compiler now derives `module_info` from that extracted intent layer instead of only from ad hoc raw-module inspection.
- This is intentionally the first bounded slice only:
  - `Intent HIR` is started,
  - `Lowered RTL IR` was still left for later extraction at that point,
  - and the forward IR work is now an active `R11` implementation seam rather than just an `H3` horizon note.
- The next forward IR seam is now also live:
  - `FSM::IR::LoweredRTLIR` exists as the first explicit forward lowered summary,
  - direct generation results now expose `lowered_rtl_ir`,
  - realized generated children now preserve that same lowered summary through `module_info`,
  - and some composition/export consumers now prefer `lowered_rtl_ir` when present instead of only rereading legacy module-info fields.
- The first composition-export widening step is now also live:
  - aggregated `composition_standalone_dt_children` entries preserve child `intent_hir`,
  - and those same exports now also preserve child `lowered_rtl_ir`.
  - that same reusable standalone-DT child export now also lives inside composition-top `intent_hir`.
- The broader generated-child composition export is now also live:
  - top-level `composition_generated_children` covers realized `?fsmc` and `?dtc` children together,
  - and those exported child summaries preserve both `intent_hir` and `lowered_rtl_ir`.
- The shared-datapath candidate surface now preserves that same forward child context too:
  - candidate contributors keep `intent_hir`,
  - keep `lowered_rtl_ir`,
  - now also keep the exact selected contributor `output_drive_family` from child `lowered_rtl_ir`,
  - and keep the bounded `drive_intent` summary as a derived compatibility shape from that extracted family,
  - and also keep stable generated-child identity through `kind` and `source_name`.
- Composition tops themselves now preserve the same forward-IR story too:
  - direct `?top` results expose serialized top-level `intent_hir`,
  - direct `?top` results also expose serialized top-level `lowered_rtl_ir`,
  - that same composition-top `intent_hir` now also carries the broader generated-child export instead of leaving it only as a separate top-level compatibility summary,
  - and composition `module_info` mirrors those same serialized forward layers with bounded top-port, lane, internal-net, instance, auxiliary-assignment, and shared-datapath-candidate summaries.
- The first structural/connectivity extraction slice is now also live:
  - `FSM::IR::StructuralRTLIR` exists as the first explicit AST/netlist-like connectivity summary,
  - direct `?top` results now expose `structural_rtl_ir`,
  - composition-top `module_info` mirrors the same structural surface,
  - and the active composition-top emitter now walks that structural layer for top-module dumping.
- The next structural widening step is also live:
  - direct generated `?fsm` / `?dt` results now expose a bounded structural module-interface slice through `structural_rtl_ir`,
  - and realized generated-child export surfaces now preserve that same child `structural_rtl_ir` beside `intent_hir` and `lowered_rtl_ir`.
- The next structural-consumption step is also live:
  - realized generated-child interface planning now consumes `structural_rtl_ir` as its first boundary source of truth,
  - with low-level declaration types like `wire` / `logic` normalized back to plain semantic data ports on the way into composition interface planning.
- The next IR-to-IR handoff step is also live:
  - composition-top `lowered_rtl_ir` now consumes `structural_rtl_ir` for internal-net names, realized-instance names, and auxiliary-assignment counts instead of rebuilding that bounded connectivity slice directly from the plan.
- The next structural-consumption step is also live:
  - composition-top `module_info` and `statistics` now consume `structural_rtl_ir` for child, top-port, and internal-net counts instead of rereading those bounded accounting fields directly from plan internals.
- The next structural-consumption step is also live through composition provenance:
  - `composition_report` now consumes `structural_rtl_ir` for top-port metadata and resolved-link endpoint lookup instead of rereading those bounded boundary/interface details directly from plan internals.
- The next structural-consumption step is also live through override/block reporting:
  - composition override/block event grouping and candidate-context lookup now consume `structural_rtl_ir` for top-port and child-interface metadata instead of rereading those same interface families directly from plan internals.
- The next IR-to-IR handoff step is also live through composition-top semantic summaries:
  - composition-top `intent_hir` now consumes `structural_rtl_ir` for top-port names, counts, and grouped input/output signal-analysis families,
  - and compatible top-level `module_info` signal metadata now mirrors that same structural top-port boundary instead of rebuilding it separately from plan internals.
- The next structural widening step is also live through explicit resolved connectivity:
  - composition-top `structural_rtl_ir` now preserves resolved links as first-class structural connectivity entries,
  - `composition_report` now derives its resolved-link identity/origin list from that structural layer instead of rereading plan-only link state,
  - and compatible top-level resolved-link counts now stay aligned with `structural_rtl_ir`.
- The next structural widening step is also live through typed actual-connection nodes:
  - composition-top `structural_rtl_ir` instance pin bindings now preserve a backend-neutral `connection_expr` node beside the compatibility `signal_name` mirror,
  - that first actual-connection shape is intentionally bounded to `signal_ref`,
  - realized composition-plan instances now also preserve that same typed `signal_ref` node before structural serialization,
  - and that earlier binding normalization now lives in `FSM::Composition::RealizedInstance` itself so the runtime child-binding carrier owns the `signal_name` / `connection_expr` alignment contract directly,
  - the active composition-top emitter now walks that typed node when rendering instance actual connections,
  - and shared-datapath candidate discovery now also reads structural binding signal names through that same typed node instead of depending only on a flat binding string.
- The next structural-consumption step is also live through override/block resolved-link handling:
  - composition override events now take their explicit-toplink and inferred-reexport connectivity from `structural_rtl_ir->{resolved_links}`,
  - and the kept-internal internal-carrier block path now also derives its family detection from that same structural resolved-link surface instead of rereading resolved links from the plan.
- The next forward semantic widening step is also live through one unified composition child export:
  - composition-top `intent_hir` now carries `composition_child_count` plus one ordered `composition_children` export across realized `?fsmc`, `?dtc`, and `?rtl` children,
  - compatible top-level `module_info` now mirrors that same unified child semantic surface,
  - those child entries preserve stable identity plus child `intent_hir`, `lowered_rtl_ir`, and `structural_rtl_ir` summaries when present,
  - and composition provenance / override / block endpoint lookup now consumes that same unified child semantic surface instead of rereading realized child identity only from plan instances.
- The next narrowing step is also live through the generated-child export path:
  - the narrower `composition_generated_children` export now derives from the broader semantic `composition_children` layer,
  - so generated-child export identity is no longer rebuilt separately from plan instances,
  - while the existing generated-child forward IR surface remains stable.
- The next lowering step is also live through shared-datapath candidate discovery:
  - shared-datapath candidate discovery now consumes `structural_rtl_ir` for top-output / child-interface connectivity,
  - contributor identity and lowered contributor context now come from the unified semantic `composition_children` export,
  - and the existing candidate surface remains stable while depending less on ad hoc plan crawling inside `HDLGenerator`.
- The composition provenance/reporting surface now preserves that same forward context too:
  - resolved-link entries keep source/target endpoint context,
  - generated-child endpoint contexts keep `intent_hir`,
  - generated-child endpoint contexts keep `lowered_rtl_ir`,
  - and top-port / resolved-link provenance kinds now keep one stable example subject for non-quiet CLI reporting.
- The composition override/block reporting surface now preserves that same forward context too:
  - override and block events keep structured top-port / child-endpoint context,
  - generated-child endpoint contexts keep `intent_hir`,
  - generated-child endpoint contexts keep `lowered_rtl_ir`,
  - and override/block example lines now use richer link/endpoint subjects instead of plain count-plus-name examples.
2026-03-23
- StructuralRTLIR `connection_expr` now supports bounded indexed and sliced
  signal forms in addition to plain `signal_ref`.
- The current renderer is still intentionally narrow: those richer forms render
  through the current Verilog-family backend only, and fail explicitly for
  backends like VHDL until that emitter surface is implemented deliberately.
- StructuralRTLIR `connection_expr` now also supports bounded concat nodes over
  nested operands, with the same deliberate renderer boundary: current
  Verilog-family backend only, explicit failure elsewhere.
- StructuralRTLIR `connection_expr` now also exposes recursive referenced-signal
  discovery, and shared-datapath contributor metadata preserves `bound_signals`
  beside the older scalar compatibility field.
- StructuralRTLIR `connection_expr` now also supports bounded bit-vector
  literal actuals, rendered through the current Verilog-family backend only.
- StructuralRTLIR `connection_expr` now also supports explicit backend-neutral
  `open` actuals, rendered as empty named actuals for the Verilog family and
  as `open` through the current VHDL helper-rendering path.
- StructuralRTLIR `connection_expr` now also supports bounded `member_access`
  actuals, rendered through the current SystemVerilog and VHDL helper paths
  while failing explicitly for plain Verilog.
- StructuralRTLIR `connection_expr` now also supports bounded `index_access`
  actuals, rendered through the current SystemVerilog, Verilog, and VHDL
  helper paths.
- Downstream structural consumers now also distinguish flat leaf carriers from
  broader dependency lists, so `bound_signal` stays leaf-only while
  `bound_signals` stays dependency-oriented.
- IntentHIR now also owns semantic composition-child lookup by instance
  through `composition_children_by_instance` and `composition_child`, so
  provenance/shared-datapath consumers no longer need to rebuild that same
  semantic child index locally in `HDLGenerator`.
- LoweredRTLIR now also owns normalized output-drive-family lookup by signal
  through `output_drive_families_from_input`, `output_drive_families_by_signal`,
  and `output_drive_family`, so shared-datapath and module-output-drive
  consumers no longer need to rebuild that same lowered signal map locally in
  `HDLGenerator`.
- LoweredRTLIR now also owns grouped standalone-DT multi-drive target lookup
  through `standalone_dt_multi_drive_targets_from_input`,
  `standalone_dt_multi_drive_targets_by_signal`, and
  `standalone_dt_multi_drive_target`, so standalone-DT assertion/export
  consumers no longer need to reread that same lowered target surface locally
  in `HDLGenerator`.
- IntentHIR now also owns semantic system-contract and signal-analysis
  boundary lookup through `system_contract_from_input` and
  `signal_analysis_entries_from_input`, so realized-child interface fallback
  no longer needs to reread that same semantic boundary data directly from raw
  `module_info` fields in `HDLGenerator`.
- Generic explicit-link linked-plan assembly for the active `C2`/`C3`/`C4`
  lanes now also lives in `FSM::Composition::LinkedPlanBuilder`, so
  `HDLGenerator` no longer owns that family’s system auto-wiring, endpoint
  resolution, role/width validation, deterministic carrier-net allocation, or
  realized-child rebinding logic directly.
- Inferred multi-child top-port projection now also lives in
  `FSM::Composition::TopPortInferenceBuilder`, so `HDLGenerator` no longer
  owns explicit-toplink top-port inference or undeclared same-name top-input
  and top-output inference directly.
- Shared-datapath support now also lives in
  `FSM::Composition::SharedDatapathSupport`, so `HDLGenerator` no longer owns
  shared-datapath helper-signal naming, generated-child source-export
  metadata, assertion metadata/rendering, or runtime plan augmentation
  directly.
- Composition provenance reporting now also lives in
  `FSM::Composition::ProvenanceReportBuilder`, so `HDLGenerator` no longer
  owns the bounded provenance report / override event / block event /
  endpoint-context projection family directly.
- EnableGraph module/state/declaration planning now also lives in
  `FSM::Synthesis::EnableGraph::ModulePlanningSupport`, so `EnableGraph` no
  longer owns effective system-contract lookup, effective clock/reset lookup,
  state-register planning, module-boundary port planning, or internal signal
  declaration planning directly.
- EnableGraph assignment analysis and assignment emission now also live in
  `FSM::Synthesis::EnableGraph::AssignmentSupport`, so `EnableGraph` no
  longer owns unified assignment analysis, RHS grouping, mux-plan
  construction, driven-signal discovery, reset/default/width recovery, or
  delayed-pulse / flop / combinational assignment emission directly.
- EnableGraph top-level enable initialization and WEN/EN support now also
  live in `FSM::Synthesis::EnableGraph::EnableSupport`, so `EnableGraph` no
  longer owns top-level state/DT enable initialization, WEN/EN prescan
  tracking, top-level enable emission, or unified DT/LHS WEN/EN emission
  directly.
- EnableGraph AST capture and condition/test conversion now also live in
  `FSM::Synthesis::EnableGraph::CaptureSupport`, so `EnableGraph` no longer
  owns condition-stack normalization, assignment/transition capture,
  test-selector conversion, capture-time RHS rendering, or AST signal-name
  extraction directly.
- EnableGraph AST rendering and operator classification now also live in
  `FSM::Synthesis::EnableGraph::ASTSupport`, so `EnableGraph` no longer owns
  AST-to-SystemVerilog rendering, operand-width-aware logical-versus-bitwise
  operator selection, factorizable-operator discovery, or
  arithmetic/logical/factorization classification directly.
- EnableGraph signal/intermediate support now also lives in
  `FSM::Synthesis::EnableGraph::SignalSupport`, so `EnableGraph` no longer
  owns AST-based intermediate naming, reset/default lookup, direct
  intermediate-dependency extraction, signal/intermediate classification,
  backend-safe signal-name cleanup, or RHS-based enable naming directly.
- EnableGraph factorization policy now also lives in
  `FSM::Synthesis::EnableGraph::FactorizationPolicySupport`, so
  `FSM::Synthesis::EnableGraph::FactorizationSupport` no longer owns
  logical-operation counting, first-pass AST feed preparation, second-pass
  AST feed eligibility, or high-count logical-operation policy directly.
- Direct consolidated intermediate preparation/normalization now also lives
  in `FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport`,
  so the older `ConsolidatedIntermediateEmitter` no longer owns AST-
  factorized, prescanned, and FSMGen-parsed intermediate collection or
  runtime metadata normalization directly.
- The paired direct `ConsolidatedIntermediateEmitter` now narrows to
  dependency-aware filtering, topological ordering, and final wire/assign
  emission for that prepared consolidated signal set.
- Direct intermediate runtime recovery and metadata normalization now also
  live in `FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport`,
  so `IntermediateSignalSupport` no longer owns runtime AST lookup,
  rendered-expression caching, dependency recovery, or width inference
  directly.
- The paired direct `IntermediateSignalSupport` now narrows to filter policy
  over normalized intermediate metadata instead of mixing recovery and filter
  responsibilities together.
- Explicit `?toplink` wiring now has a first real structural-actual slice:
  `=open`, `=0`, `=1`, and exact-width `=N'b...` sources may now bind
  directly into realized child input ports.
- `FSM::Composition::LinkedPlanBuilder` now preserves those actuals as typed
  `connection_expr` bindings instead of inventing carrier nets, and
  top-port inference / provenance block detection now treat those child
  inputs as already explicitly linked.
- Explicit `?toplink` wiring may now also use declared top-port bit/slice
  expressions such as `payload_bus[15:8]` and `status_bus[0]` on the source
  side when the target is a realized child input.
- `FSM::Composition::LinkedPlanBuilder` now resolves those source-side
  top-port expressions into typed `bit_select_expr` / `slice_expr` bindings
  directly, and top-port inference / provenance block detection now treat
  those child inputs as already explicitly linked instead of inventing helper
  nets or undeclared same-name top ports.
- Omitted/empty `?ports` explicit-link tops may now also infer undeclared
  base top inputs directly from those source-side top expressions.
- `FSM::Composition::TopPortInferenceBuilder` now derives the inferred
  base-port width from the highest referenced bit while still rejecting
  incompatible exact-width full-port evidence instead of guessing one width
  contract silently.
- Explicit `?toplink` wiring may now also use the bounded flat comma-separated
  source-side concat form inside one `/source/target/` token, for example
  `header_bus,status_bus[0],=1,payload_bus[3:0]`, when the target is a
  realized child input.
- `FSM::Composition::LinkedPlanBuilder` now lowers those concat sources into
  typed structural `concat_expr` bindings directly instead of inventing
  carrier nets, and blocked unsupported concat operands keep the existing
  `Top expression '...'` summary context.
- Omitted/empty `?ports` explicit-link tops may now also see inferable
  `name[index]` / `name[msb:lsb]` operands inside those bounded concat
  sources, and one remaining undeclared whole-port concat operand may now
  also be sized exactly from the child-input target remainder width while
  several still-unsized whole-port operands continue to fail explicitly
  instead of guessing several widths at once.
- The same bounded structural-actual literal family now also covers exact-
  width hex forms such as `=8'hA5` for both direct actual sources and concat
  operands, with those literals normalized into the same structural
  bit-vector form instead of introducing a second backend-specific literal
  node.
