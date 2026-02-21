# FSMGen
FSMGen compiles Lisp-like `.fsm` state machine files into HDL, with SystemVerilog as the primary target.

## What it does
- Parses FSM descriptions into semantic ASTs.
- Builds decision-tree driven assignments and transitions.
- Generates HDL output (`.sv` by default, `.v` optional).
- Supports detailed debug tracing for parser and generation internals.

## Quick start
```bash
./bin/fsmgen fsm/trial_0.fsm
./bin/fsmgen --output /tmp/trial_0.sv fsm/trial_0.fsm
./bin/fsmgen --debug=3 fsm/trial_1.fsm
```

## CLI
```bash
./bin/fsmgen [options] <fsm_file>
```

Key options:
- `-o, --output <file>`: explicit output path.
- `-l, --language <systemverilog|sv|verilog|v|vhdl>`: target language.
- `-d, --debug[=N]`: debug level (`1..3`; bare `--debug` implies `3`).
- `-q, --quiet`: suppress informational output.
- `-h, --help`: help text.

Notes:
- Verilog generation is available through SystemVerilog-to-Verilog conversion.
- VHDL backend currently reports explicit not-implemented status.

## Assignment semantics
- `A <- expr`: synchronous/flopped assignment.
- `A <= expr`: synchronous/flopped assignment variant.
- `A = expr`: combinational assignment.

Combinational safety rule:
- `=` assignments cannot create direct or indirect dependence of RHS on the same LHS through combinational chains.
- `A <- A` remains legal for register loopback behavior.

## Documentation map
- User guide: `docs/USER_GUIDE.md`
- Change history: `CHANGES.md`
- Design rationale and engineering context: `DEVELOPMENT_NOTES.md`

## Development test
```bash
prove -v t/01-regression.t
```
