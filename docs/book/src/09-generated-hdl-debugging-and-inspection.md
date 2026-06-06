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
./bin/fsmgen --capability-manifest
./bin/fsmgen --strict --check --json fsm/apb_requester.fsm
./bin/fsmgen --strict --emit-semantic-json fsm/apb_requester.fsm
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
- Yosys with `read_verilog -sv -noautowire`, `synth -noabc -top`, and `stat`

This split is intentional. Verilator and Yosys are independent backend
validation gates for the emitted HDL; they do not replace FSMGen's internal AST
and semantic contracts. More specifically, Verilator answers “did FSMGen emit
valid lint-clean SystemVerilog?” while Yosys answers “can that SystemVerilog be
lowered into structural logic?” The Yosys lane uses `synth -noabc` on purpose:
ABC optimization/mapping can have timeout-sensitive edge cases, and those
belong to a later dedicated hardening lane rather than this garbage-code gate.
The support surface can also report the first optional ABC executable it finds
from `yosys-abc`, `berkeley-abc`, and `abc`. That discovery is metadata only:
ABC is not required for `--verify-hdl`, and the validation command sequence
does not run a standalone ABC pass.

Direct VHDL generation now has a scaffold subset for direct single-FSM roots,
including delayed-pulse clock-branch lowering, generic-bearing direct-root
module headers with typed scalar/vector sized-literal defaults, scalar addition
and multiplication RHS/chain lowering, binary scalar subtraction RHS lowering,
and same-width addition/subtraction/multiplication, division/modulo, and XOR
RHS/chain lowering.
VHDL validation with GHDL is intentionally deferred until a separate GHDL
validation lane is runnable, documented, support-accounted, and regression-backed. The current
regression gate is a focused SystemVerilog smoke, not yet a claim that every
historical sample in `fsm/` is externally warning-clean. Both deferred items
are tracked in [Feature Backlog](14-feature-backlog.md).

The focused smoke currently includes `fsm/lte_dif_pmaster.fsm`, every current
MIPI sample under `fsm/`, the warning-clean historical direct samples
`fsm/trial_0.fsm` and `fsm/trial_1.fsm`, and every
supported direct protocol actor in the regression corpus:
`fsm/apb_requester.fsm`, `fsm/apb_completer.fsm`, and
`fsm/amba_requester.fsm` today. It also includes the supported APB
composition protocol top, `fsm/apb_tb.fsm`.

Composed generated-child tops may contain internal
`shared_dp_unused_<instance>_<export>` sink wires. Those wires intentionally
terminate generated-child shared-datapath export-enable pins that are not used
by a given top-level composition, keeping Verilator's `PINMISSING` lint clean
without changing the user-visible top interface.

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

- `--trace-verbosity` accepts `none`, `low`, `medium`, `high`, and `debug`
- `--trace-log[=FILE]` routes trace output to a file, defaulting to
  `trace.log` when the option is present without an explicit path
- every trace line carries origin metadata: file, function, and line number
- trace formatting is indentation-aware and grouped by topic
- non-quiet failures keep more composition/diagnostic context
- report-only JSON modes keep stdout JSON-only and route trace text away from
  stdout when tracing is enabled

## Useful Options

- `-o, --output <file>` writes generated HDL to the requested path.
- `-l, --language <systemverilog|sv|verilog|v|vhdl>` selects the target
  language. `sv` aliases SystemVerilog, `v` aliases Verilog, and VHDL is
  routed through the direct single-FSM scaffold subset.
- `-d, --debug[=N]` enables numeric trace compatibility levels `0..4`; a bare
  `--debug` means level `4`.
- `--trace-verbosity <none|low|medium|high|debug>` selects named trace detail.
- `--trace-log[=FILE]` sends trace output to `FILE`, or to `trace.log` when no
  path is provided.
- `--trace-emojis` / `--notrace-emojis` enables or disables emoji trace
  markers without changing trace content.
- `--path <dir>` adds one source search root for bare `.fsm` names and related
  lookup; the option may be repeated.
- `--extension-module <Module::Name>` loads one typed extension module from
  `@INC`; the option may be repeated.
- `--extension-config <file>` loads typed extension modules from one config
  file; the option may be repeated.
- `--capability-manifest` prints the schema-versioned support/capability
  manifest and exits without requiring an input `.fsm`.
- `--check --json` / `--check-json` runs the full pipeline as a check, emits a
  schema-versioned JSON report, and writes no HDL.
- `--emit-semantic-json` / `--semantic-json` emits bounded normalized semantic
  JSON instead of HDL.
- `--emit-normalized-json` / `--normalized-json` are compatibility aliases for
  the semantic JSON export while the public wording settles.
- `--verify-hdl` / `--validate-hdl` runs external SystemVerilog validation
  after writing generated HDL.
- `-q, --quiet` suppresses informational messages, including the interactive
  banner, processing line, and success summaries. Human failure diagnostics
  still print, and machine JSON modes remain JSON-only.
- `-h, --help` prints the full CLI help.

`--capability-manifest` is different from the HDL-generation options: it emits
schema-versioned JSON describing the current support/capability surface and
exits without requiring an input `.fsm`.

`--check --json` is also different from HDL generation: it still runs the full
pipeline, but it writes no HDL file. It emits a schema-versioned JSON check
report to stdout and exits non-zero when the check fails.

`--emit-semantic-json` runs the full pipeline and emits the bounded normalized
semantic JSON report instead of writing HDL. It is the preferred CLI
interchange surface for downstream tools that need sanitized module/system,
signal-analysis, symbol, and forward-IR projections without depending on raw
Perl objects.

## Report-Only CLI Modes

The first bounded check-only JSON surface is:

```bash
./bin/fsmgen --strict --check --json path/to/file.fsm
```

`--check-json` is an alias for the same mode. The command runs the full
pipeline, emits JSON to stdout, exits non-zero when the check fails, and never
writes an HDL file even if `-o` is present.

Successful checks report:

- `success: true`
- an empty `diagnostics` array
- the resolved source path
- a small checked-result summary
- a report-level `support_accounting` object when the source is known to the
  support-accounting corpus

Failed checks report `success: false` plus a diagnostic object. When a failure
matches a support-accounting expected-failure entry, that diagnostic includes
the stable `FSMGEN_*` code, severity, stability, family, source file, matched
corpus entry, and migration-hint availability. Failures outside the current
classifier still return JSON with a `null` code rather than pretending a stable
diagnostic identity exists. For `.isf` inputs, parser, lowering,
schedule-report, and semantic check failures also use this JSON failure path
instead of leaving stdout empty.

The first bounded normalized semantic JSON surface is:

```bash
./bin/fsmgen --strict --emit-semantic-json path/to/file.fsm
```

`--semantic-json` is an alias for the same mode. Compatibility aliases
`--emit-normalized-json` and `--normalized-json` are accepted too.

Successful semantic reports use `normalized_semantic_schema_version: 1`,
`command.mode: semantic_export`, a report-level `support_accounting` object,
and a `semantic` payload containing bounded public projections of module/root
summary, system/reset metadata, signal analysis, symbols when present, and the
forward IR layers. Composition sources also include a sanitized composition
provenance/report fragment.

This is not a promise that every private pipeline object is public API. It is
the sanitized downstream-tool projection. Failed semantic exports reuse the
stable diagnostic-code classifier and do not expose partial semantics.

## Input Resolution

FSMGen resolves `<fsm_file>` by shape:

1. Bare names such as `foo` or `foo.fsm` are searched in repeated
   `--path DIR` roots, then `FSMLIB` roots, then the current directory.
2. Relative paths such as `../fsm/foo.fsm` are used directly.
3. Absolute paths are used directly.

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

Treat those names as different kinds of surfaces, not as one undifferentiated
dump.

`intent_hir`, `lowered_rtl_ir`, and `structural_rtl_ir` are the canonical
forward-IR projections exposed to users and tools. They are sanitized
projections of internal IR objects, not raw mutable compiler objects.

`module_info` is a compatibility/result surface. It mirrors useful forward-IR,
analysis, and planning facts for existing callers, but it is not a second
canonical compiler IR.

Composition provenance and plan snapshots are reviewable evidence derived from
the planner. They help explain what was connected and why, but the raw
composition plan object remains private.

For `.isf`, raw parser actor hashes and private `LoweringIR` hashes are not
public APIs. Downstream tools should consume the bounded schedule JSON,
normalized semantic JSON, public contract metadata, generated `.fsm` artifacts,
and generated HDL/artifact files instead.

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
not the shipped default path today. It is tracked in
[Feature Backlog](14-feature-backlog.md).
The capability manifest records that boundary through
`embedding.hdl_generator_facade.default_generation_mode`,
`generation_mode_names`, `structured_nonflattened_generation_enabled`, and
`structured_nonflattened_generation_status`. There is no public
`generation_mode` constructor option yet.
