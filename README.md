# FSMGen
This file is the **single entry point** for the project.
Use it first for objective, navigation, and where to find code/docs quickly.

## Project objective
FSMGen compiles Lisp-like `.fsm` state machine specifications into synthesizable HDL.
Current primary target is SystemVerilog, with Verilog conversion support and explicit VHDL not-implemented signaling.
The project objective is robust, traceable FSM-to-HDL generation with clear assignment semantics, optimization via AST factorization, and behavior-preserving refactoring toward a modular architecture.

## Fast ramp-up order
1. `README.md` (this file): project objective + navigation.
2. `ROADMAP_STATUS.md`: canonical live roadmap/workstream status.
3. `docs/USER_GUIDE.md`: usage and CLI behavior.
4. `docs/COMPOSITION_SCOPE.md`: concrete `R6` composition scope and acceptance boundary.
5. `CHANGES.md`: chronological technical changes.
6. `DEVELOPMENT_NOTES.md`: design rationale and decisions.
7. `MEMORY.md`: continuity/handoff state.
8. `COMMIT.md`: commit workflow requirements.
9. `WARP.md`: repository-specific agent/development guidance.
10. `.agents/workflows/commit.md`: automation-oriented commit workflow description.

## Documentation index (all `.md` files in this repo)
- `README.md` — single entry point and navigation hub.
- `ROADMAP_STATUS.md` — canonical live roadmap/workstream status board.
- `docs/USER_GUIDE.md` — end-user guide and command usage.
- `docs/COMPOSITION_SCOPE.md` — concrete composition scope and acceptance boundary for the active architecture.
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
./bin/fsmgen --debug=3 fsm/trial_1.fsm
```

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
- `-q, --quiet`: suppress informational output.

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
