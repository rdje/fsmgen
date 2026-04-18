# FSMGen
This file is the **single entry point** for the project.
Use it first for objective, navigation, and where to find code/docs quickly.

## Session safety invariant
- The commit workflow in `COMMIT.md` is mandatory and non-negotiable.
- After every completed task/activity, run that workflow before starting the next slice.
- Do not batch several finished tasks into one later cleanup commit.
- The reason is operational, not stylistic: task-scoped commits are the project's crash-recovery mechanism for session loss, app crashes, and machine crashes.
- If a task is complete but not committed, that task is not safely finished yet.

## Project objective
FSMGen compiles Lisp-like `.fsm` state machine specifications into synthesizable HDL.
Current primary target is SystemVerilog, with Verilog conversion support and explicit VHDL not-implemented signaling.
The project objective is robust, traceable FSM-to-HDL generation with clear assignment semantics, optimization via AST factorization, and behavior-preserving refactoring toward a modular architecture.

## Fast ramp-up order
1. `README.md` (this file): project objective + navigation.
2. `COMMIT.md`: mandatory commit workflow and safety invariant for crash recovery.
3. `SESSION_BOOTSTRAP.md`: default first task for a new engineering session.
4. `ROADMAP_STATUS.md`: canonical live roadmap/workstream status.
5. `ROADMAP_V2.md`: detailed post-`R0`..`R7` roadmap intent and sequencing.
6. `docs/book/src/SUMMARY.md`: progressive mdBook table of contents.
7. `docs/USER_GUIDE.md`: broad live reference during the book split.
8. `docs/COMPOSITION_SCOPE.md`: concrete `R6` composition scope and acceptance boundary.
9. `docs/COMPOSITION_LEGACY_MAPPING.md`: historical `fx/bin/fsmgen` composition behavior mapped onto the active `R6` plan.
10. `docs/EXTENSION_MODEL.md`: active `R7` typed extension boundary replacing legacy `.plg` / `PPlugin` as architecture direction.
11. `docs/SPECFORGE_FEEDBACK_RESPONSE.md`: FSMGen's tracked response and alignment plan for SPECFORGE adapter feedback.
12. `docs/INTENT_SCHEDULING_BRAINSTORM.md`: living brainstorm log for an intent-scheduling layer above explicit cycle-authored `.fsm`.
13. `CHANGES.md`: chronological technical changes.
14. `DEVELOPMENT_NOTES.md`: design rationale and decisions.
15. `MEMORY.md`: continuity/handoff state.
16. `WARP.md`: repository-specific agent/development guidance.
17. `.agents/workflows/commit.md`: automation-oriented commit workflow description.

## Documentation index (all `.md` files in this repo)
- `README.md` — single entry point and navigation hub.
- `SESSION_BOOTSTRAP.md` — canonical first-task file for a new engineering session.
- `ROADMAP_STATUS.md` — canonical live roadmap/workstream status board.
- `ROADMAP_V2.md` — detailed post-`R0`..`R7` roadmap intent and sequencing.
- `docs/book/` — mdBook source for the progressive FSMGen book.
- `docs/BOOK_PLAN.md` — migration plan from the monolithic guide into the mdBook.
- `docs/USER_GUIDE.md` — broad live reference and command usage during the split.
- `docs/COMPOSITION_SCOPE.md` — concrete composition scope and acceptance boundary for the active architecture.
- `docs/COMPOSITION_LEGACY_MAPPING.md` — historical legacy-composition behavior mapped onto the active architecture.
- `docs/EXTENSION_MODEL.md` — typed extension boundary for the active `R7` replacement path.
- `docs/SPECFORGE_FEEDBACK_RESPONSE.md` — tracked FSMGen response to SPECFORGE adapter/tool-integration feedback.
- `docs/INTENT_SCHEDULING_BRAINSTORM.md` — living brainstorm log for inferring/scheduling cycles from a hardware-native intent layer above explicit `.fsm`.
- `CHANGES.md` — persistent technical change history.
- `DEVELOPMENT_NOTES.md` — architecture notes and engineering rationale.
- `MEMORY.md` — live continuity context and recovery notes.
- `COMMIT.md` — canonical commit workflow specification.
- `WARP.md` — project guidance for Warp/agent workflows.
- `.agents/workflows/commit.md` — agent workflow definition for commit operations.

## Project file and directory map
### Core entrypoints and pipeline
- `bin/fsmgen` — main CLI entrypoint.
- `perl/FSM/Pipeline/HDLGenerator.pm` — generation orchestration.
- `perl/FSM/Composition/Net.pm` — typed internal net plan for multi-child composition wiring.
- `perl/FSM/Composition/Parser.pm` — first typed composition parser/IR boundary.
- `perl/FSM/Composition/Plan.pm` — typed realized top-planning object for active composition work.
- `perl/FSM/Composition/RTLInterfaceLoader.pm` — sidecar external-RTL interface loader for the shipped `C3` composition lane.
- `perl/FSM/Extension/Loader.pm` — explicit typed extension-module loader for the active `R7` replacement seam.
- `perl/FSM/Extension/Registry.pm` — typed extension registry for the active `R7` replacement seam.
- `perl/FSM/Extension/Context.pm` — typed hook context object passed to active extensions.
- `perl/FSM/Support/CapabilityManifest.pm` — machine-readable capability manifest builder for downstream tool integration.
- `perl/FSM/Support/CapabilityManifestContract.pm` — bounded top-level capability-manifest shell contract advertised through the manifest itself.
- `perl/FSM/Support/DiagnosticsContract.pm` — bounded manifest-facing contract for the `diagnostics` section's public top-level and stable-code entry families.
- `perl/FSM/Support/EmbeddingContract.pm` — bounded manifest-facing contract for the `embedding` section's public top-level and nested contract-owner map.
- `perl/FSM/Support/DocumentationContract.pm` — bounded manifest-facing contract for the `documentation` section's public path-list keys.
- `perl/FSM/Support/LanguageSurfaceContract.pm` — bounded manifest-facing contract for the `language_surface` section's public top-level and first nested key lists.
- `perl/FSM/Support/ProducerContract.pm` — bounded manifest-facing contract for the `producer` section's public identity/build metadata keys.
- `perl/FSM/Support/SemanticExportsContract.pm` — bounded manifest-facing contract for the `semantic_exports` section's public top-level and nested contract-owner map.
- `perl/FSM/Support/CheckDiagnostics.pm` — bounded `--check --json` report builder and stable-code classifier.
- `perl/FSM/Support/CheckDiagnosticsContract.pm` — bounded `--check --json` key-presence contract advertised through the capability manifest.
- `perl/FSM/Support/CompositionReportContract.pm` — bounded sanitized composition provenance/report contract for semantic JSON.
- `perl/FSM/Support/DiagnosticCodes.pm` — stable diagnostic-code registry consumed by support accounting and the capability manifest.
- `perl/FSM/Support/DiagnosticCodeRegistryContract.pm` — bounded stable-code registry contract advertised through the capability manifest.
- `perl/FSM/Support/ExtensionContract.pm` — bounded typed-extension/context contract advertised to embedders through the capability manifest.
- `perl/FSM/Support/HDLGeneratorResultContract.pm` — bounded top-level result contract for in-process `HDLGenerator` embedders.
- `perl/FSM/Support/HDLExternalValidation.pm` — optional Verilator/Yosys validation lane for generated SystemVerilog.
- `perl/FSM/Support/HDLExternalValidationContract.pm` — bounded external validation contract advertised through the capability manifest.
- `perl/FSM/Support/NormalizedSemanticReport.pm` — bounded normalized semantic JSON report builder for downstream tool integration.
- `perl/FSM/Support/NormalizedSemanticReportContract.pm` — bounded normalized semantic JSON key-presence contract advertised through the capability manifest.
- `perl/FSM/Support/SupportAccountingContract.pm` — bounded support-accounting section contract advertised through the capability manifest.
- `perl/FSM/Support/RegressionCorpus.pm` — production support-accounting catalog owner consumed by the manifest and regression tests.
- `perl/FSM/SourceClassifier.pm` — top-level source-kind classification for FSM vs composition inputs.
- `perl/FSM/Adapter/FSMGenFull.pm` — FSM adapter/parsing entry.
- `perl/FSM/HDL/FlattenedDT.pm` — Flattened decision-tree facade.
- `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/PostFlatteningAssemblySupport.pm` — live direct SystemVerilog post-flattening assembly owner.
- `perl/FSM/Package/IntegerLiteralSupport.pm` — shared `.fsm` integer-literal interpreter and target-HDL normalizer for decimal, based, prefixed, and intent-level sized spellings such as `5'23`, `8'-10`, and `20'x1`.
- `perl/FSM/Synthesis/EnableGraph.pm` — enable synthesis/helper ownership.

### Input, tests, and support
- `fsm/` — sample/input `.fsm` files.
- `t/` — regression and behavior tests.
- `docs/` — user and technical docs.
- `generated/` — generated parser/output artifacts.
- `grammars/` — grammar definitions.
- `rust/Makefile` — makefile used for rust-side build/management tasks.

## Quick start
```bash
./bin/fsmgen fsm/trial_0.fsm
./bin/fsmgen --output /tmp/trial_0.sv fsm/trial_0.fsm
./bin/fsmgen --debug=3 fsm/lte_dif_pmaster.fsm
./bin/fsmgen --verify-hdl --output /tmp/lte_dif_pmaster.sv fsm/lte_dif_pmaster.fsm
```

## Documentation quick preview
```bash
mdbook build docs/book
cd docs/book && mdbook serve
```
- The mdBook is the progressive learning surface.
- `docs/USER_GUIDE.md` remains the broad live reference while that split is still in progress.

## Local CI / pre-push regression
```bash
./bin/ci-regression
```
- `bin/ci-regression` is the local entrypoint for the same checks used by `.github/workflows/regression.yml`.
- The script resolves the repository root itself, so you can invoke it without depending on your current working directory.
- It runs the full Perl regression suite with `prove -I perl t`.
- When `verilator` and `yosys` are installed, the external SystemVerilog validation smoke runs too; otherwise that test is skipped.

## CLI quick reference
```bash
./bin/fsmgen [options] <fsm_file>
```
- `-o, --output <file>`: explicit output path.
- `-l, --language <systemverilog|sv|verilog|v|vhdl>`: target language.
- `-d, --debug[=N]`: numeric debug compatibility level (`0..4`; bare `--debug` implies `4`).
- `--trace-verbosity <none|low|medium|high|debug>`: named trace verbosity.
- `--trace-log[=FILE]`: trace output file (default `trace.log`).
- `--trace-emojis` / `--notrace-emojis`: emoji marker toggle.
- `--extension-module <Module::Name>`: load an explicit typed extension module from `@INC` (may be repeated).
- `--extension-config <file>`: load typed extension modules from an explicit config file (may be repeated).
- `--capability-manifest`: print the versioned JSON FSMGen capability manifest and exit.
- `--check --json`: run the full pipeline as a check, emit JSON diagnostics, and do not write HDL.
- `--emit-semantic-json`: run the full pipeline, emit bounded normalized semantic JSON, and do not write HDL.
- `--verify-hdl`: after writing generated SystemVerilog, run Verilator lint and ABC-free Yosys structural synthesis.
- `-q, --quiet`: suppress informational output.

The bounded machine-readable surfaces are backed by support accounting:
`--check --json` is corpus-covered across supported, strict-supported, and
expected-failure entries, while `--emit-semantic-json` is corpus-covered across
current supported, strict-supported, and expected-failure entries.
The manifest-facing stable diagnostic-code registry now has its own explicit
bounded contract owner in
[perl/FSM/Support/DiagnosticCodeRegistryContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/DiagnosticCodeRegistryContract.pm),
so downstream tools can discover the public diagnostics sibling keys and stable
entry keys without treating the whole diagnostics tree as frozen.
The capability manifest shell now has that same explicit split too:
[perl/FSM/Support/CapabilityManifest.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CapabilityManifest.pm)
builds the JSON, while
[perl/FSM/Support/CapabilityManifestContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CapabilityManifestContract.pm)
owns the bounded top-level and first nested section key lists advertised under
`manifest_contract`.
The manifest's `embedding` section now follows that split too:
[perl/FSM/Support/CapabilityManifest.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CapabilityManifest.pm)
still publishes the current in-process embedding surfaces, while
[perl/FSM/Support/EmbeddingContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/EmbeddingContract.pm)
owns the bounded top-level and nested contract-owner map advertised through
`embedding.section_contract` without flattening the whole embedding tree into
one accidental API.
The manifest's `diagnostics` section now follows that split too:
[perl/FSM/Support/CapabilityManifest.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CapabilityManifest.pm)
still publishes the current registry/check surfaces, while
[perl/FSM/Support/DiagnosticsContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/DiagnosticsContract.pm)
owns the bounded top-level, scalar-string, and stable-code entry families
advertised through `diagnostics.section_contract` without flattening the whole
diagnostics tree into one accidental API.
The manifest's `producer` section now follows that split too:
[perl/FSM/Support/CapabilityManifest.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CapabilityManifest.pm)
still publishes the current FSMGen identity/build metadata, while
[perl/FSM/Support/ProducerContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/ProducerContract.pm)
owns the bounded top-level, scalar-string, and boolean field families
advertised through `producer.section_contract`. That keeps tool/build identity
discoverable without pretending this is already a package-manager release API.
The manifest's `semantic_exports` section now follows that split too:
[perl/FSM/Support/CapabilityManifest.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CapabilityManifest.pm)
still publishes the current bounded semantic interchange surfaces, while
[perl/FSM/Support/SemanticExportsContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/SemanticExportsContract.pm)
owns the bounded top-level and nested contract-owner map advertised through
`semantic_exports.section_contract`. That keeps `normalized_semantic_json`
discoverable without pretending every future semantic export format is already
frozen.
The manifest's `language_surface` section now follows the same pattern:
[perl/FSM/Support/CapabilityManifest.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CapabilityManifest.pm)
still publishes the authored-surface summary, while
[perl/FSM/Support/LanguageSurfaceContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/LanguageSurfaceContract.pm)
owns the bounded top-level and first nested section-key lists advertised
through `language_surface.surface_contract` without pretending the whole
authored language is frozen.
The manifest's `documentation` section now has the same split too:
[perl/FSM/Support/CapabilityManifest.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CapabilityManifest.pm)
still publishes the current doc pointers, while
[perl/FSM/Support/DocumentationContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/DocumentationContract.pm)
owns the bounded top-level and path-list contract advertised through
`documentation.section_contract` without freezing the exact file lists forever.

## Assignment semantics (quick reference)
- `A <- expr`: synchronous/flopped assignment where `A` names the flop output/Q value.
- `A <= expr`: synchronous/flopped variant where `A` names the D-input/next-value side.
- `A = expr`: combinational assignment.
- Safety rule: combinational `=` cannot create direct/indirect RHS feedback to same LHS.
- Safety rule: D-input-named `<=` / `<=+` cannot read the same LHS name from the RHS or guard; use `<-` for ordinary register feedback.

## README maintenance policy
- Keep `README.md` as the canonical onboarding hub.
- Update it when any of the following changes materially:
  - project objective/scope,
  - document set or purpose,
  - key file paths / architecture entrypoints,
  - onboarding workflow.
- It does **not** need to be updated on every commit—only when meaningful for onboarding accuracy.

## Fresh session shortcut
For a new engineering session, the preferred one-line instruction is:

```text
Read SESSION_BOOTSTRAP.md and start from there.
```

That startup ritual must still honor the session safety invariant above:
`COMMIT.md` is mandatory, and every completed slice must be committed before the next one starts.
