# FSMGen User Guide

## 1) What FSMGen is
FSMGen converts Lisp-like `.fsm` state-machine descriptions into HDL.

Primary output:
- SystemVerilog (`.sv`)

Also supported:
- Verilog (`.v`) via conversion from SystemVerilog

Current limitation:
- VHDL target is recognized by CLI but backend is not yet implemented.
- Composition/top-level multi-block generation is only partially implemented in the active toolchain.
- The currently shipped composition lane is narrow:
  - one `?top:name`,
  - one explicit `?ports` block,
  - one or more embedded `?fsmc` children in the same file,
  - `C1` single-child passthrough via deterministic same-name wiring,
  - `C2` multi-child FSM composition via explicit `?toplink` wiring with `instance.port` child endpoints.
  - `C3` mixed FSM plus external RTL composition via explicit `?toplink` wiring and sidecar `<module>.rtlif` interface metadata.
- See [docs/COMPOSITION_SCOPE.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_SCOPE.md) for the scoped `R6` plan and [docs/COMPOSITION_LEGACY_MAPPING.md](/Users/richarddje/Documents/github/fsmgen/docs/COMPOSITION_LEGACY_MAPPING.md) for historical context.

## 2) Core concepts
### FSM input file
A `.fsm` file defines states, decision trees, conditions, assignments, and transitions.

### Terms and concepts
- **State**: named execution context in the FSM.
- **Decision tree (DT)**: conditional/action structure evaluated within a state.
- **Conditional branch**: guard plus actions (assignments or transitions).
- **Transition**: state change action written as `->`.
- **Standalone/reset-style DTs**: top-level DT blocks that are not normal runtime states (for reset/clear style control).
- **Intermediate signal**: generated internal wire used to factor repeated expressions.
- **Enable-style control (WEN/EN)**: internal enable signals used by generation stages to drive selected assignments.

### DT/mux enable architecture (reference)
This model is important for understanding generated RTL behavior.

- A DT has an enable condition and emits one or more enable-like controls (WEN/EN) for assignments.
- Conceptually, each DT-local enable is gated by DT activity:
  - `dt_local_en = dt_enable & condition`
- For combinational targets, selected values are merged through enable gating (mux-equivalent behavior).
- For flopped targets, next-value logic typically includes hold/feedback behavior when no write-enable path is active.
- Multiple candidate write paths to a target are reduced through enable composition, then applied according to assignment type (`=`, `<-`, `<=`).
- State decoding/selection controls which DT logic is active at a time for normal FSM progression.

Notes:
- Internal implementation details can evolve, but this execution model is the intended mental model for users.
- Debug traces (`--debug=3`) are the best way to inspect exact enable composition for a specific FSM.

### Assignment operators
- `A <- expr` : synchronous/flopped assignment
- `A <= expr` : synchronous/flopped assignment variant
- `A = expr`  : combinational assignment

### Combinational safety rule
For `=` assignments, RHS must not depend on the same LHS through any combinational path.
Examples rejected by parser:
- direct: `A = A`
- indirect: `A = B` and `B = A`

Synchronous loopback remains valid:
- `A <- A`

## 3) Basic usage
From repository root:
```bash
./bin/fsmgen [options] <fsm_file>
```

Examples:
```bash
./bin/fsmgen fsm/trial_0.fsm
./bin/fsmgen --output /tmp/trial_0.sv fsm/trial_0.fsm
./bin/fsmgen --language verilog --output /tmp/trial_0.v fsm/trial_0.fsm
```

Current narrow composition example:
```lisp
(?top:single_child_top
  (?ports:public_io
    clk
    rstn
    output_data>8
  )
  (?fsmc:child_ctrl child_ctrl_src)
)

(?fsm:child_ctrl_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (output_data> <= 8'1)
  )
  (+size
    (output_data 8)
  )
)
```

This currently works because:
- the child FSM is embedded in the same file,
- the child exposes `output_data` explicitly as an output,
- the top `?ports` block matches the realized child interface exactly.

Current narrow multi-child example:
```lisp
(?top:two_child_top
  (?ports:public_io
    clk
    rstn
    result_data>8
  )
  (?fsmc:producer producer_src)
  (?fsmc:consumer consumer_src)
  (?toplink:wiring
    /producer.output_data/consumer.input_data/
    /consumer.final_data/result_data/
  )
)
```

This currently works because:
- every child is an embedded `?fsmc`,
- `clk` and `rstn` use the shared system-input contract,
- non-system connections are expressed explicitly through `?toplink`,
- explicit link widths and endpoint roles must match exactly.

Current narrow mixed FSM + external RTL example:
```lisp
(?top:fsm_plus_rtl_top
  (?ports:public_io
    clk
    rstn
    serial_out>
  )
  (?fsmc:producer producer_src)
  (?rtl:uart_tx)
  (?toplink:wiring
    /producer.output_data/uart_tx.data_in/
    /uart_tx.txd/serial_out/
  )
)
```

With sidecar interface metadata in `uart_tx.rtlif`:
```lisp
(?rtlif:uart_tx
  clk
  rstn
  data_in<8
  txd>
)
```

This currently works because:
- the FSM child is still compiled through the active FSM pipeline,
- the external RTL child is instantiated but not regenerated,
- composition loads the RTL interface from `uart_tx.rtlif` beside the source file or through the existing `FSMLIB` search roots,
- non-system mixed-child connections remain explicit through `?toplink`.

## 4) Useful options
- `-o, --output <file>` : output file path
- `-l, --language <systemverilog|sv|verilog|v|vhdl>` : target language
- `-d, --debug[=N]` : numeric trace compatibility level (`0..4`; bare `--debug` implies `4`)
- `--trace-verbosity <none|low|medium|high|debug>` : named trace verbosity selector
- `--trace-log[=FILE]` : route trace output to FILE (default: `trace.log`)
- `--trace-emojis` / `--notrace-emojis` : enable/disable emoji markers in trace formatting
- `-q, --quiet` : suppress informational messages
- `-h, --help` : full CLI help

## 5) Input resolution and FSMLIB
`fsmgen` resolves `<fsm_file>` as:
1. bare name (`foo`) or `foo.fsm`: searched in `FSMLIB` paths, then current directory
2. relative path (`../fsm/foo.fsm`): used directly
3. absolute path: used directly

Example:
```bash
export FSMLIB="/project/fsm:/shared/fsm"
./bin/fsmgen lte_dif_pmaster
```

## 6) Debug workflow
Recommended debug run:
```bash
./bin/fsmgen --trace-verbosity=debug --trace-log=trace.log --output /tmp/example.sv fsm/trial_1.fsm
```

Tracing behavior:
- Verbosity levels: `none`, `low`, `medium`, `high`, `debug`
- Every trace line includes origin metadata (file, function, line number)
- Trace output uses indentation-aware formatting and topic separation
- When trace logging is enabled, trace lines are written to `trace.log` (or chosen file) instead of stdout

## 7) External compatibility flow (legacy environment)
If working in the external flow that uses `generate_fsm_hdl.pl`, the equivalent command pattern is:
```bash
perl generate_fsm_hdl.pl --debug /path/to/input.fsm -o output.sv
```
Use this only in environments where that script is part of the active toolchain.

## 8) Troubleshooting
### Parser rejects combinational self-dependency
If you see `Illegal combinational self-dependency`, rewrite the logic so combinational `=` assignments do not create feedback loops.

### Verilog/VHDL behavior
- Verilog: supported through conversion path
- VHDL: explicit not-implemented backend error is expected currently

### Regression check
Before committing parser/generator changes:
```bash
prove -v t/01-regression.t
```

## 9) Practical authoring guidelines
- Use `=` only for true combinational outputs.
- Use `<-`/`<=` for flopped behavior and register loopback.
- Prefer simple, explicit conditions; when conditions grow, expect intermediate signals in output RTL.
- Run with `--debug=3` when bringing up new FSM files.
