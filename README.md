# FSMGen
This file is the **single entry point** for the project.
Use it first for objective, navigation, and where to find code/docs quickly.

## Project objective
FSMGen compiles Lisp-like `.fsm` state machine specifications into synthesizable HDL.
Current primary target is SystemVerilog, with Verilog conversion support and explicit VHDL not-implemented signaling.
The project objective is robust, traceable FSM-to-HDL generation with clear assignment semantics, optimization via AST factorization, and behavior-preserving refactoring toward a modular architecture.

## Fast ramp-up order
1. `README.md` (this file): project objective + navigation.
2. `SESSION_BOOTSTRAP.md`: default first task for a new engineering session.
3. `ROADMAP_STATUS.md`: canonical live roadmap/workstream status.
4. `ROADMAP_V2.md`: detailed post-`R0`..`R7` roadmap intent and sequencing.
5. `docs/book/src/SUMMARY.md`: progressive mdBook table of contents.
6. `docs/USER_GUIDE.md`: broad live reference during the book split.
7. `docs/COMPOSITION_SCOPE.md`: concrete `R6` composition scope and acceptance boundary.
8. `docs/COMPOSITION_LEGACY_MAPPING.md`: historical `fx/bin/fsmgen` composition behavior mapped onto the active `R6` plan.
9. `docs/EXTENSION_MODEL.md`: active `R7` typed extension boundary replacing legacy `.plg` / `PPlugin` as architecture direction.
10. `docs/SPECFORGE_FEEDBACK_RESPONSE.md`: FSMGen's tracked response and alignment plan for SPECFORGE adapter feedback.
11. `CHANGES.md`: chronological technical changes.
12. `DEVELOPMENT_NOTES.md`: design rationale and decisions.
13. `MEMORY.md`: continuity/handoff state.
14. `COMMIT.md`: commit workflow requirements.
15. `WARP.md`: repository-specific agent/development guidance.
16. `.agents/workflows/commit.md`: automation-oriented commit workflow description.

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
- `perl/FSM/Support/CheckDiagnostics.pm` — bounded `--check --json` report builder and stable-code classifier.
- `perl/FSM/Support/DiagnosticCodes.pm` — stable diagnostic-code registry consumed by support accounting and the capability manifest.
- `perl/FSM/Support/NormalizedSemanticReport.pm` — bounded normalized semantic JSON report builder for downstream tool integration.
- `perl/FSM/Support/RegressionCorpus.pm` — production support-accounting catalog owner consumed by the manifest and regression tests.
- `perl/FSM/SourceClassifier.pm` — top-level source-kind classification for FSM vs composition inputs.
- `perl/FSM/Adapter/FSMGenFull.pm` — FSM adapter/parsing entry.
- `perl/FSM/HDL/FlattenedDT.pm` — Flattened decision-tree facade.
- `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog.pm` — SystemVerilog backend implementation.
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
- `-q, --quiet`: suppress informational output.

The bounded machine-readable surfaces are backed by support accounting:
`--check --json` is corpus-covered across supported, strict-supported, and
expected-failure entries, while `--emit-semantic-json` is corpus-covered across
current supported and strict-supported accepted entries.

## Assignment semantics (quick reference)
- `A <- expr`: synchronous/flopped assignment.
- `A <= expr`: synchronous/flopped variant.
- `A = expr`: combinational assignment.
- Safety rule: combinational `=` cannot create direct/indirect RHS feedback to same LHS.

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
