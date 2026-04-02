# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

FSMGen is a sophisticated finite state machine (FSM) HDL generator that converts Lisp-like `.fsm` files into synthesizable RTL code. The tool supports SystemVerilog, Verilog, and VHDL output formats with advanced features like AST factorization, intermediate signal optimization, and multi-pass dependency resolution.

## Core Commands

### Generate HDL from FSM Files

```bash
# Basic generation (SystemVerilog output)
./bin/fsmgen my_fsm.fsm

# Generate with debug logging
./bin/fsmgen --debug my_fsm.fsm

# Generate Verilog with custom output file
./bin/fsmgen --language verilog --output output.v my_fsm.fsm

# Generate VHDL quietly (suppress info messages)  
./bin/fsmgen --language vhdl --quiet my_fsm.fsm
```

### Development Testing

```bash
# Test with known-good FSM files
./bin/fsmgen fsm/trial_0.fsm
./bin/fsmgen fsm/lte_dif_pmaster.fsm

# Test complex FSM with comprehensive features
./bin/fsmgen fsm/mipicsi2_tester_ctrl.fsm --debug
```

### Debug Analysis

```bash
# Generate with full debug trace + log file
./bin/fsmgen --debug=3 my_fsm.fsm
# Creates: my_fsm.sv (output) + my_fsm.log (debug trace)

# Debug levels: 0=none, 1=basic, 2=detailed, 3=very detailed
./bin/fsmgen --debug=2 my_fsm.fsm
```

## Architecture Overview

### Core Pipeline Architecture

The FSM HDL generator follows a sophisticated multi-stage pipeline:

1. **FSM Parsing** (`FSM::Adapter::FSMGenFull`) - Converts .fsm files to internal AST
2. **AST Factorization** (`FSM::HDL::ASTFactorization`) - Identifies common expressions for optimization
3. **Decision Tree Flattening** (`FSM::HDL::FlattenedDT`) - Converts FSM structure to flat assignments
4. **HDL Generation** (`FSM::Pipeline::HDLGenerator`) - Produces final SystemVerilog/Verilog/VHDL

### Critical Subsystems

**FSM::CoreAST Architecture**: Production-quality AST framework with:
- Multiple assignment semantics (register, mux, pulse, combinatorial)
- Multi-target HDL generation (SystemVerilog/Verilog/VHDL)
- Clock domain awareness and signal analysis
- Extensible operator registry with precedence rules

**Intermediate Signal Management**: Four-registry system for complete signal tracking:
- AST Factorizer Registry (expression optimization)
- Global Expressions Registry (cross-DT reuse) 
- FSMGenFull Parsing Registry (FSMGen-specific signals like `or_*`)
- Pre-scan Referenced Registry (dependency analysis)

**Dependency-Aware Filtering**: Advanced system that:
- Builds complete dependency graphs across all signal registries
- Rescues referenced intermediate signals from filtering
- Prevents undefined reference errors in generated HDL

### Key Technical Capabilities

**Multi-Pass AST Substitution**: Iterative system with self-reference prevention for complex intermediate signal dependencies

**AST-Based Expression Factorization**: Identifies reusable expressions and generates intermediate signals automatically

**Width Inference System**: Bidirectional propagation supporting both explicit and default width handling

**Conditional State Transitions**: Supports conditional suffixes like `<pwrite` and `<!pwrite` in FSM transitions

## File Structure

- **`bin/fsmgen`** - Main CLI tool
- **`perl/FSM/`** - Core FSM framework modules
- **`fsm/`** - Example FSM input files  
- **`docs/`** - Technical documentation and development notes
- **`svg/`** - Generated diagrams and visualizations

### Key Development Files

- **`perl/FSM/Pipeline/HDLGenerator.pm`** - Main generation pipeline
- **`perl/FSM/Adapter/FSMGenFull.pm`** - FSM file parser
- **`perl/FSM/HDL/FlattenedDT.pm`** - Decision tree processing 
- **`perl/FSM/HDL/ASTFactorization.pm`** - Expression optimization
- **`perl/FSM/CoreAST.pm`** - Core AST framework

## FSM File Format

FSMGen uses a Lisp-like syntax for FSM specifications:

```lisp
(?fsm:my_fsm
  (+system (clock clk) (sreset rstn))
  (+size (A 32) (B 8) (enable 1))
  
  (-state_name
    (A <- B <enable)
    (C = 16'hFFFF <!reset)
    (?test_signal
      (=0 (-> next_state))
      (=1 (A <- C) (-> other_state))
    )
  )
)
```

## Development Practices

### Debugging Infrastructure

All major subsystems include comprehensive debug logging with `[module][function()]` prefixes for traceability. Use `--debug=3` for maximum visibility into:

- FSM parsing and signal registration
- AST factorization and substitution decisions  
- Dependency tracking and filtering logic
- HDL generation and operator selection

### Testing Strategy

1. **Start with simple FSM files** (`fsm/trial_0.fsm`) for basic functionality
2. **Progress to complex examples** (`fsm/lte_dif_pmaster.fsm`) for advanced features
3. **Use real-world FSMs** (`fsm/mipicsi2_*.fsm`) for production testing
4. **Always test with `--debug` mode** to validate internal pipeline behavior

### Operator Selection Logic

The system intelligently chooses between bitwise (`&`, `|`) and logical (`&&`, `||`) operators:
- **Single-bit signals** → bitwise operators (better synthesis)
- **Multi-bit expressions** → logical operators  
- **Intermediate signals** → always treated as single-bit boolean

### Signal Naming Conventions

- **Active-low reset signals** end with `_n` or `_b`
- **Intermediate signals** use descriptive names like `s_rst_n_and_pready`
- **Enable signals** follow pattern `{dt_name}_{signal}_{value}_en`
- **No double underscores** in generated signal names

## Key Design Insights

**Registry Architecture**: The four-registry system for intermediate signals ensures complete dependency tracking and prevents missing signal declarations in generated HDL.

**AST Factorization Benefits**: Automatically identifies common expressions and generates reusable intermediate signals, producing cleaner and more optimized HDL.

**Multi-Pass Substitution**: Handles complex nested intermediate signal dependencies with self-reference prevention to avoid invalid SystemVerilog.

**Register Feedback Design**: Uses current register values (not hardcoded defaults) for multiplexer default cases to maintain proper flop behavior.

This architecture represents a production-quality FSM-to-HDL generation framework with sophisticated optimization and analysis capabilities.
