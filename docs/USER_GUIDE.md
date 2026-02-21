# FSMGen User Guide

## 1) What FSMGen is
FSMGen converts Lisp-like `.fsm` state-machine descriptions into HDL.

Primary output:
- SystemVerilog (`.sv`)

Also supported:
- Verilog (`.v`) via conversion from SystemVerilog

Current limitation:
- VHDL target is recognized by CLI but backend is not yet implemented.

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

## 4) Useful options
- `-o, --output <file>` : output file path
- `-l, --language <systemverilog|sv|verilog|v|vhdl>` : target language
- `-d, --debug[=N]` : debug level (`1..3`; bare `--debug` implies `3`)
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
./bin/fsmgen --debug=3 --output /tmp/example.sv fsm/trial_1.fsm
```

With debug enabled, a `.log` file is generated next to the output file.

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
