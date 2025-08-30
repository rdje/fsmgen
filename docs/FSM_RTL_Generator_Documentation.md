# FSM RTL Generator Documentation

## Overview

This document provides comprehensive documentation for the FSM (Finite State Machine) RTL Generator development project. The system converts FSM specifications into SystemVerilog RTL code using a sophisticated flattened decision tree approach with enable-based logic.

## Project Structure

```
/Users/richarddje/Downloads/AFX/fsm/afx/cursor/fx/perl/
├── FSM/                            # FSM module directory
│   ├── HDL/
│   │   └── FlattenedDT.pm         # Core flattened decision tree HDL generator
│   ├── Adapter/
│   │   └── FSMGenFull.pm          # Full FSM parser and adapter
│   ├── CoreAST.pm                 # Core AST node definitions
│   └── ExpressionNamer.pm         # Expression parsing and naming utilities
├── generate_fsm_hdl.pl            # Generic FSM HDL generator script
├── generate_lte_dif_pmaster.pl    # Legacy script (superseded)
├── debug_intermediate.pl          # Debug script for intermediate signals
├── lte_dif_pmaster.fsm            # Sample FSM specification file
└── FSM_RTL_Generator_Documentation.md  # This documentation
```

## System Architecture

### Core Components

1. **FSM::Adapter::FSMGenFull**: Full FSM parser that converts FSM specifications into Abstract Syntax Tree (AST)
   - Located at: `FSM/Adapter/FSMGenFull.pm`
   - Parses FSM files using Lispish format
   - Creates signal definitions with proper width handling
   - Handles conditions, assignments, and state transitions
   - Generates CoreAST nodes for downstream processing

2. **FSM::HDL::FlattenedDT**: Flattened Decision Tree HDL Generator
   - Located at: `FSM/HDL/FlattenedDT.pm`
   - Implements enable-based methodology with WEN/EN signals
   - Flattens decision trees into Boolean expressions
   - Generates DT-specific and LHS-level write enable signals
   - Creates multiplexer logic for signal assignments

3. **FSM::ExpressionNamer**: Expression utilities for complex signal handling
   - Located at: `FSM/ExpressionNamer.pm`
   - Parses and names complex expressions
   - Provides intermediate signal generation
   - Handles expression factoring and reuse
   - Features clean signal naming with underscore normalization

4. **FSM::CoreAST**: Core AST node definitions
   - Located at: `FSM/CoreAST.pm`
   - Defines fundamental AST node types
   - Provides base classes for FSM constructs

## Key Achievements

### 1. Signal Width Propagation Fix ✅
- **Issue**: Multi-bit signal widths were lost during object construction
- **Root Cause**: Perl's defined-or operator (`//=`) and inline hash notation caused width information to be overwritten
- **Solution**: Changed Signal object construction from inline hash to step-by-step key assignment
- **Result**: Proper SystemVerilog declarations with correct widths (e.g., `[15:0] apb_rdata`)

### 2. Enhanced Debug Logging System ✅
- **Achievement**: Comprehensive debug tracing throughout the entire pipeline
- **Features**:
  - Decision tree flattening with node type identification
  - Condition stack tracking and expression building
  - Assignment recording with complete context
  - WEN/EN signal generation logging
  - Step-by-step SystemVerilog generation tracing

### 3. Condition Extraction Improvements ✅
- **Issue**: UnaryOp nodes returning "condition" placeholder instead of actual conditions
- **Root Cause**: UnaryOp.operator method returned literal string "operator" instead of actual operator
- **Solution**: Enhanced condition extraction to check `type` field and handle negation properly
- **Result**: Proper negated conditions like `<!apb_rq` → `!(apb_rq)` in SystemVerilog

### 4. Flattened Decision Tree Architecture ✅
- **Implementation**: Enable-based logic with assign statements
- **Features**:
  - DT-specific WEN/EN signals: `DTk_LHS_RHS_en`
  - LHS-level WEN signals: `LHS_v0_en`, `LHS_v1_en`, etc.
  - Multiplexer logic for both combinational and sequential assignments
  - Global expression factoring for optimization

### 5. Clean Intermediate Signal Naming ✅
- **Issue**: Intermediate signal names had multiple underscores and leading/trailing underscores
- **Example**: `_s_rst_n___and_pready___and_pready__`
- **Solution**: Enhanced FSM::ExpressionNamer with proper underscore normalization
- **Result**: Clean, professional signal names like `s_rst_n_and_pready`
- **Features**: Remove consecutive underscores, trim leading/trailing underscores, ensure valid identifiers

### 6. Complete Intermediate Signal Generation ✅
- **Issue**: Some factored intermediate signals appeared in RTL without proper wire declarations
- **Root Cause**: Global factored expressions were not included in intermediate signal generation
- **Solution**: Enhanced `generate_intermediate_signals()` to merge all factored expressions
- **Result**: All intermediate signals properly declared and assigned in RTL

### 7. Proper Perl Module Organization ✅
- **Achievement**: Restructured codebase to follow Perl namespace best practices
- **Changes**:
  - Moved modules to proper directory hierarchy: `FSM/HDL/`, `FSM/Adapter/`, etc.
  - Updated package declarations to match namespaces: `FSM::HDL::FlattenedDT`
  - Fixed all module imports to use proper `use` statements
- **Result**: Clean, maintainable codebase with consistent module structure

### 8. Generic FSM HDL Generator Script ✅
- **Achievement**: Replaced hardcoded script with flexible, reusable generator
- **Features**:
  - Accepts any `.fsm` file as positional argument
  - Smart output file naming: `<fsm_name>_generated.sv`
  - Cross-platform path handling with `File::Spec`
  - Comprehensive argument validation and help text
- **Impact**: Single script works for any FSM file, improved workflow efficiency

### 9. Comprehensive Constants, Enums, Defines, and Params Support ✅
- **Achievement**: Full support for all 4 types of FSM symbol definitions with automatic resolution
- **Constants** (`+constants`):
  - Format: `['+constants', [['IDLE_VALUE', "4'b0000"], ['BUSY_VALUE', "4'b0001"], ...]]`
  - Usage: `(status_reg <- IDLE_VALUE)` - direct constant assignment
  - Auto-width inference: LHS signals get width from constant literals
- **Enums** (`+enums`):
  - Format: `['+enums', [['state_codes', [['IDLE', [0]], ['ACTIVE', [1]], ...]], ...]]`
  - Usage: `(state_code <- state_codes.IDLE)` - dot notation enum access
  - Multiple enums supported with member value resolution
- **Defines** (`+define`):
  - Format: `['+define', ['MAX_COUNT', "8'd100"]]` - multiple defines supported
  - Usage: `(count_reg <- MAX_COUNT)` - define value substitution
  - Width inference: `8'd100` → 8-bit LHS signal width
- **Params** (`+params`):
  - Format: `['+params', [['DATA_WIDTH', [16]], ['ADDR_WIDTH', [8]], ...]]`
  - Usage: Available for parameterized expressions like `{DATA_WIDTH}'b0`
  - Numeric parameter values for design configuration
- **Symbol Resolution Priority**: Constants → Defines → Enum Members → Params
- **Smart Width Propagation**: All symbol types automatically infer LHS signal widths
- **RHS Width Inference Fix**: Corrected `const_*` to be input signals, not width sources
- **Integration**: Seamless symbol resolution in all assignment contexts

## Usage Instructions

### Running the Generic FSM HDL Generator

#### Command-Line Options
The new generic script supports flexible FSM file processing:

```bash
perl generate_fsm_hdl.pl [OPTIONS] <fsm_file>

Arguments:
  fsm_file        Path to the .fsm file to process (required)

Options:
  -d, --debug     Enable full debug mode (default: disabled)
  -q, --quiet     Suppress informational messages
  -o, --output    Specify output file (default: <fsm_name>_generated.sv)
  -h, --help      Show this help message
```

#### Basic Usage Examples

**Clean RTL Generation (Production Mode):**
```bash
# Generate clean SystemVerilog from any FSM file
perl generate_fsm_hdl.pl my_fsm.fsm

# Generate from LTE DIF P-Master FSM
perl generate_fsm_hdl.pl lte_dif_pmaster.fsm

# Generate quietly to specific file
perl generate_fsm_hdl.pl --quiet --output my_output.sv my_fsm.fsm
```

**Debug Mode (Development):**
```bash
# Enable full debug tracing
perl generate_fsm_hdl.pl --debug lte_dif_pmaster.fsm

# Debug with custom output file
perl generate_fsm_hdl.pl -d -o debug_output.sv my_fsm.fsm

# Debug with filtered output
perl generate_fsm_hdl.pl --debug my_fsm.fsm 2>&1 | grep "HDL-FLAT-DEBUG"
```

**Quiet Mode (Minimal Output):**
```bash
# Generate RTL with minimal console output
perl generate_fsm_hdl.pl --quiet my_fsm.fsm

# Completely silent generation
perl generate_fsm_hdl.pl -q my_fsm.fsm > /dev/null
```

### Legacy Script (Deprecated)

The old `generate_lte_dif_pmaster.pl` script is still available but is superseded by the generic `generate_fsm_hdl.pl` script:

```bash
# Legacy usage (still works, but not recommended)
perl generate_lte_dif_pmaster.pl [OPTIONS]
```

### Debug Output Analysis

#### Key Debug Patterns to Search For

1. **Signal Width Processing**:
```bash
grep -E "(Signal width|Generated width string)" debug.log
```

2. **Condition Extraction**:
```bash
grep -E "(EXTRACT_CONDITION|SignalRef|UnaryOp)" debug.log
```

3. **Assignment Recording**:
```bash
grep -E "(RECORDING ASSIGNMENT|Final Condition Expression)" debug.log
```

4. **WEN/EN Generation**:
```bash
grep -E "(GENERATING DT-SPECIFIC|assign.*_en)" debug.log
```

5. **Decision Tree Flattening**:
```bash
grep -E "(FLATTEN_DT_NODE|Node Type|Condition Stack)" debug.log
```

### Configuration Options

#### FSM_HDL_FlattenedDT Debug Mode
```perl
my $hdl_generator = FSM::HDL::FlattenedDT->new(debug => 1);
```

#### FSMGenFull Debug Levels
- Default: Comprehensive debug output enabled
- Control via FSMGenFull constructor or environment variables

## System Features

### Input Format Support
- **FSM Files**: Lispish format with condition blocks and actions
- **Signal Definitions**: Width specifications, input/output attributes
- **State Machines**: Regular states and standalone decision trees
- **Conditions**: Nested conditions, negation, test nodes

### Output Generation
- **SystemVerilog RTL**: Industry-standard HDL output
- **Enable-based Logic**: Concurrent assign statements
- **State Encoding**: Automatic state bit calculation
- **Module Declaration**: Complete port lists with proper widths

### Key Methodologies

#### 1. Flattened Decision Tree Approach
- Converts hierarchical decision trees into flat Boolean expressions
- Enables parallel processing and optimization
- Simplifies timing analysis and synthesis

#### 2. Enable-based Logic Generation
- **DT-Specific Enables**: `DTk_LHS_RHS_en = DT_EN && (conditions)`
- **LHS-Level Enables**: OR of all DT-specific enables for each LHS
- **Multiplexer Logic**: Conditional assignment based on enable signals

#### 3. Expression Factoring
- Reuses common sub-expressions across decision trees
- Creates intermediate signals for complex expressions
- Optimizes area and timing

## Debugging Guide

### Common Issues and Solutions

#### 1. Signal Width Problems
- **Symptom**: Generated signals have wrong bit widths
- **Debug**: Look for "Signal width" debug messages
- **Solution**: Check Signal object construction in FSMGenFull.pm

#### 2. Condition Extraction Failures
- **Symptom**: "condition" placeholders in output
- **Debug**: Search for "EXTRACT_CONDITION.*Unknown type"
- **Solution**: Add support for new condition node types in extract_condition_string()

#### 3. Assignment Recording Issues
- **Symptom**: Missing or incorrect assignments
- **Debug**: Look for "RECORDING ASSIGNMENT" sections
- **Solution**: Check condition stack building and expression creation

### Debug Output Structure

#### Decision Tree Flattening
```
=== FLATTEN_DT_NODE ====
  DT: <decision_tree_name>
  Node Type: <AST_node_type>
  Condition Stack: [<list_of_conditions>]
```

#### Assignment Recording
```
*** RECORDING ASSIGNMENT ***
  DT: <decision_tree_name>
  LHS: <left_hand_side_signal>
  RHS: <right_hand_side_value>
  Operator: <assignment_operator>
  Raw Condition Stack: [<conditions>]
  Final Condition Expression: <boolean_expression>
```

#### WEN/EN Generation
```
*** GENERATING DT-SPECIFIC WEN/EN SIGNALS ***
All LHS signals found: <comma_separated_list>

Processing LHS: <signal_name> (<count> assignments)
  Assignment: DT=<dt>, LHS=<lhs>, RHS=<rhs>, Cond=<condition>
```

## File Structure and Dependencies

### Core Files
- **FSM::HDL::FlattenedDT** (`FSM/HDL/FlattenedDT.pm`): Main HDL generation engine
- **FSM::Adapter::FSMGenFull** (`FSM/Adapter/FSMGenFull.pm`): FSM parsing and AST generation
- **FSM::ExpressionNamer** (`FSM/ExpressionNamer.pm`): Expression handling utilities
- **FSM::CoreAST** (`FSM/CoreAST.pm`): Core AST node definitions

### Test Files
- **generate_fsm_hdl.pl**: Generic FSM HDL generator script (recommended)
- **generate_lte_dif_pmaster.pl**: Legacy test script for LTE DIF P-Master FSM
- **debug_intermediate.pl**: Debug script for intermediate signals
- **lte_dif_pmaster.fsm**: Sample FSM specification

### Generated Output
- **SystemVerilog (.sv)**: RTL implementation
- **Debug logs**: Comprehensive execution traces

## Known Limitations and Future Work

### Current Limitations
1. **Complex Expressions**: Some advanced expression types may need additional parsing support
2. **Timing Constraints**: No explicit timing constraint generation
3. **Verification**: Limited built-in verification capabilities

### Future Enhancements
1. **Formal Verification**: Add SVA (SystemVerilog Assertions) generation
2. **Timing Analysis**: Include timing constraint generation
3. **Optimization**: Advanced expression optimization algorithms
4. **Documentation**: Auto-generated RTL documentation

## Development History

### Phase 1: Signal Width Fix
- **Date**: August 2024
- **Issue**: Multi-bit signals losing width information
- **Solution**: Fixed Signal object construction methodology
- **Impact**: Correct SystemVerilog port declarations

### Phase 2: Debug Infrastructure
- **Date**: August 2024
- **Achievement**: Comprehensive debug logging system
- **Features**: Step-by-step execution tracing, condition tracking
- **Impact**: Simplified debugging and development

### Phase 3: Condition Processing
- **Date**: August 2024
- **Issue**: UnaryOp condition extraction failures
- **Solution**: Enhanced AST node handling
- **Impact**: Proper negation and complex condition support

## Support and Maintenance

### For Issues
1. Enable debug logging: `debug => 1` in constructors
2. Examine debug output patterns using grep
3. Check signal creation and width assignment
4. Verify condition extraction and expression building

### For Extensions
1. Add new AST node types in FSMGenFull.pm
2. Extend condition extraction in extract_condition_string()
3. Add new debug patterns for new features
4. Update documentation with changes

## Command Reference

### Essential Commands with Generic Script
```bash
# Basic generation (any FSM file)
perl generate_fsm_hdl.pl my_fsm.fsm

# Debug analysis
perl generate_fsm_hdl.pl --debug my_fsm.fsm 2>&1 | grep "PATTERN"

# Clean output
perl generate_fsm_hdl.pl --quiet my_fsm.fsm > output.sv 2>/dev/null

# With timeout
timeout 30 perl generate_fsm_hdl.pl my_fsm.fsm > output.sv 2>debug.log
```

### Legacy Commands (Deprecated)
```bash
# Legacy script (hardcoded FSM file)
perl generate_lte_dif_pmaster.pl

# Legacy debug analysis
perl generate_lte_dif_pmaster.pl 2>&1 | grep "PATTERN"
```

### Useful Grep Patterns
```bash
# Signal processing
grep -E "(Signal width|width.*[0-9])" debug.log

# Condition handling  
grep -E "(EXTRACT_CONDITION|negation)" debug.log

# Assignment flow
grep -E "(RECORDING|Assignment.*DT=)" debug.log

# WEN/EN generation
grep -E "(assign.*_en|WEN.*signals)" debug.log

# Error detection
grep -E "(error|Error|ERROR|unknown|Unknown)" debug.log
```

---

*Last Updated: August 17, 2024*
*Project Status: Active Development*
*Next Milestone: Complete SystemVerilog generation pipeline testing*
