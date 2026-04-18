# Generated HDL, Debugging, and Inspection

This chapter covers the CLI loop, what to expect from emitted HDL, and how to
inspect deeper semantic surfaces.

## Basic CLI Flow

From repository root:

```bash
./bin/fsmgen [options] <fsm_file>
```

Common commands:

```bash
./bin/fsmgen fsm/trial_0.fsm
./bin/fsmgen --output /tmp/trial_0.sv fsm/trial_0.fsm
./bin/fsmgen --language verilog --output /tmp/trial_0.v fsm/trial_0.fsm
./bin/fsmgen --debug=3 fsm/lte_dif_pmaster.fsm
./bin/fsmgen --verify-hdl --output /tmp/lte_dif_pmaster.sv fsm/lte_dif_pmaster.fsm
```

## Output Shape

Today, direct FSM/DT lowering is flattened.

That means the emitted HDL emphasizes:

- explicit control enables
- explicit mux/default logic
- explicit state registers and next-state handling
- factored intermediate expressions where useful

This is deliberate. The current default generation mode is the debug-friendly
flattened path.

## Reading The Generated HDL

When inspecting emitted SystemVerilog, look for:

- module interface first
- any generated packed typedefs for aggregate aliases
- declared registers and wires
- factored intermediate expressions
- unified mux/default logic
- sequential blocks
- any generated assertions or helper nets

## External SystemVerilog Validation

When Verilator and Yosys are installed, FSMGen can validate generated
SystemVerilog after emission:

```bash
./bin/fsmgen --verify-hdl --output /tmp/lte_dif_pmaster.sv fsm/lte_dif_pmaster.fsm
```

`--validate-hdl` is the same mode. The command first runs FSMGen's own parser,
semantic checks, pre-generation operand/type/width checks, and emitter. After
the `.sv` file is written, it runs:

- Verilator with `--lint-only --sv`
- Yosys with `read_verilog -sv -noautowire`, `hierarchy -check`, `proc`,
  `opt`, and `stat`

This split is intentional. Verilator and Yosys are independent backend
validation gates for the emitted HDL; they do not replace FSMGen's internal AST
and semantic contracts. VHDL validation with GHDL is intentionally deferred
until FSMGen has an active VHDL backend. The current regression gate is a
focused SystemVerilog smoke, not yet a claim that every historical sample in
`fsm/` is externally warning-clean.

The focused smoke currently includes `fsm/lte_dif_pmaster.fsm`, the MIPI
byte-serial/timer examples that rely on inferred widths from slices,
selectors, and guards, and every supported direct protocol actor in the
regression corpus: `fsm/apb_requester.fsm`, `fsm/apb_completer.fsm`, and
`fsm/amba_requester.fsm` today.

The AMBA requester is a useful example of why source intent and backend
validation both matter. Its Q-named state registers must use `<-`, not `<=`,
because `<=` names the D-input/next-value carrier. When a D-input assignment
reads the same LHS name on its RHS or guard, FSMGen now rejects that feedback
before generation rather than relying on Verilator to discover an `UNOPTFLAT`
loop after the fact.

AMBA also gives a good arithmetic rendering example:
`(% addr_q (* beats_total_q addr_step_q))` must render as
`addr_q % (beats_total_q * addr_step_q)`. If generated HDL flattens that to
`addr_q % beats_total_q * addr_step_q`, the target language's left-associative
operator rules have changed the AST meaning.

When reading flattened enable logic, remember that `.fsm` truthiness is
intent-level. A multibit signal used as a predicate means “non-zero,” so the
SystemVerilog backend may emit `(|COUNT)` or `(~|bytept)` in one-bit enable
trees instead of bare `COUNT` or `!bytept`. Those reductions are deliberate:
they preserve the predicate meaning while keeping independent HDL tools happy.

For composition tops, also inspect:

- top ports
- instance bindings
- auxiliary assignments
- inferred internal carrier nets

## Trace Workflow

Recommended debug run:

```bash
./bin/fsmgen --trace-verbosity=debug --trace-log=trace.log \
  --output /tmp/example.sv \
  fsm/lte_dif_pmaster.fsm
```

Trace behavior:

- `--trace-verbosity` controls detail
- `--trace-log` routes trace output to a file
- trace lines carry origin metadata
- non-quiet failures keep more composition/diagnostic context

## Useful Options

- `-o, --output <file>`
- `-l, --language <systemverilog|sv|verilog|v|vhdl>`
- `-d, --debug[=N]`
- `--trace-verbosity <none|low|medium|high|debug>`
- `--trace-log[=FILE]`
- `--path <dir>`
- `--extension-module <Module::Name>`
- `--extension-config <file>`
- `--capability-manifest`
- `--check --json`
- `--verify-hdl`
- `-q, --quiet`

`--capability-manifest` is different from the HDL-generation options: it emits
schema-versioned JSON describing the current support/capability surface and
exits without requiring an input `.fsm`.

`--check --json` is also different from HDL generation: it still runs the full
pipeline, but it writes no HDL file. It emits a schema-versioned JSON check
report to stdout and exits non-zero when the check fails.

## Input Resolution

FSMGen resolves source names by:

1. repeated `--path DIR`
2. `FSMLIB`
3. current directory

Example:

```bash
export FSMLIB="/project/fsm:/shared/fsm"
./bin/fsmgen --path ./fsm --path ../shared_fsm lte_dif_pmaster
```

## IR And Metadata Surfaces

The pipeline now preserves more than just emitted text.

Important live surfaces include:

- `intent_hir`
- `lowered_rtl_ir`
- `structural_rtl_ir`
- `module_info`
- composition provenance/report summaries

These are especially useful for:

- embedders
- validation tooling
- regression checks
- understanding what the planner decided before emission

## Composition Inspection

For composition runs, non-quiet output now carries bounded report/failure
context such as:

- lane
- construct
- child source file
- expected metadata file
- top-port or endpoint context
- blocked reason

That matters because many composition issues are planning-boundary issues, not
backend text-generation issues.

## Current Boundary

The default emitted HDL story is still:

- flattened debug-first direct generation
- typed, structural planning for composition
- strong pre-generation validation

The future structured/non-flattened generation discussion is real, but it is
not the shipped default path today.
