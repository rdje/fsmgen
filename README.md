# FSMGen: Hardware Finite State Machine Compiler 

FSMGen is a powerful, extensible Perl 5 compiler designed to translate human-readable Lispish definitions of finite state machines (`.fsm`) into syntactically flawless, highly factored SystemVerilog/VHDL RTL (Register-Transfer Level) code.

## Architecture

At its core, `fsmgen` relies on a multi-pass compilation strategy:
1. **Lispish Parser:** A parser adapter transforms custom text arrays (e.g. `(+system (clock myclock))`) into a tokenized AST.
2. **SignalManager & ExpressionBuilder:** Extracts raw operands into `CoreAST` objects, handles multi-dimensional bit width inference, and factors nested boolean logic into safe, isolated intermediate combinational logic (`wire`).
3. **SignalAnalyzer:** Cross-references all register reads and LHS assignments spanning across states and decision trees, enforcing strict separation of synchronous (flops) and asynchronous (combinational multiplexers) blocks in standard IC design conventions.

## Installation & Setup

1. **Prerequisites:** FSMGen runs on standard Perl (5.20+). No external CPAN modules are strictly required beyond `Test::More` for developer regression testing.
2. **Setup:** FSMGen ships with embedded language specifications (`specs/`) and syntax plugins (`plugin/`) stored natively in the repository root. Ensure they remain alongside the perl modules!
3. **Execution:** Ensure the `bin/fsmgen` file is executable.
   ```bash
   chmod +x bin/fsmgen
   ```

## Usage

You can compile any finite state machine definition file by passing it to the CLI:

```bash
./bin/fsmgen [options] <input FSM file>
```

### CLI Options
- `-o <file>` / `--output <file>` : Specify an explicit output file path for the generated SystemVerilog/VHDL.
- `--debug` : Enable detailed AST dump and node compilation logs (useful for developers).
- `--quiet` : Suppress noisy logging warnings.

**Example:**
```bash
./bin/fsmgen -o mipicsi2_controller.sv fsm/mipicsi2_txdcore_hs.fsm
```

## FSM Syntax (`WARP.md`)

The exact language semantics and acceptable syntactic elements (e.g. `?fsm:`, `<-`, `->`) are exhaustively documented in the repository's native `WARP.md` guide. Review `WARP.md` if you are authoring new state machine topologies.

## Development & Testing

This project employs an automated IPC regression test suite running over 20+ isolated FSM topologies. Developers must ensure this suite passes 100% green before opening any Pull Requests.

```bash
# Run the test suite
prove -v t/01-regression.t
```

If a test fails, `fsmgen` will safely trap execution faults using `Carp::confess` stack traces to assist debugging AST failures deeply within the recursive parser.
