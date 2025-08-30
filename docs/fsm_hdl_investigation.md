# FSM HDL Investigation Status

## Current Problem Statement

The FSM HDL generation system has a critical issue where **intermediate signals are used in the generated SystemVerilog code but are not declared**. This creates syntactically invalid Verilog that cannot be synthesized.

### Specific Symptoms
- Generated Verilog references signals like `s_rst_n_and_pready`, `not_s_rst_n`, and other intermediate signals
- These signals appear in expressions but have no corresponding `wire` declarations
- The code compiles in Perl but produces broken Verilog output

## Root Cause Analysis

### Original Implementation Problems
The original AST factorization system in `FSM::HDL::FlattenedDT` had fundamental design flaws:

1. **String-based fragility**: Used `to_systemverilog()` output as keys for tracking expressions
   - Different formatting could cause the same logical expression to be treated as different
   - Inconsistent string representations led to missed matches

2. **FSM-specific hardcoding**: 
   - Hardcoded signal names and assumptions
   - Not generic across different FSM designs
   - Brittle when switching to new FSM files

3. **Incomplete factorization flow**:
   - `identify_factorization_candidates()` promoted sub-ASTs for factorization
   - `generate_factorized_signals()` created systematic signal names and updated registries
   - However, the actual **declaration generation** was inconsistent

### Current Investigation Focus

The core disconnect is: **signals collected for use are not making it into the declarations phase**.

#### Key Functions Identified
- `ast_to_clean_systemverilog`: Converts AST to SystemVerilog text
- `get_intermediate_signal_for_ast`: Retrieves or creates intermediate signal names
- `track_ast_intermediate_signals`: Tracks intermediate signals for later declaration

#### Likely Root Causes
1. **Incomplete intermediate signal declaration phase**:
   - Method responsible for generating wire declarations may not be properly invoked
   - Collected intermediate signals might not be propagated to declaration generation

2. **Signal tracking inconsistency**:
   - Signals tracked during expression flattening may not get added reliably to declaration lists
   - Data structure synchronization issues

3. **Conditional generation skips**:
   - Conditions or flags that skip generating declarations when bookkeeping structures are empty
   - Premature clearing or scoping problems

## Investigation Status

### Files Examined
- `FSM/HDL/FlattenedDT.pm` - Main FSM HDL generation logic
- Generated SystemVerilog output files showing missing declarations
- AST factorization code and intermediate signal tracking methods

### Next Steps Required
1. **Find declaration generation method**: Look for methods like `generate_intermediate_signal_declarations`
2. **Verify signal collection**: Ensure all intermediate signals used are properly tracked
3. **Check invocation order**: Confirm declaration code runs at the correct point in HDL generation
4. **Debug signal propagation**: Trace how tracked signals flow to declaration generation
5. **Enable diagnostic logging**: Look for debug flags to trace signal discovery and declaration

## Generic AST Factorization Implementation

### New Module: `FSM::HDL::ASTFactorization.pm`
A complete rewrite using pure AST structural identity:

- **Deterministic structural hashing**: Uses JSON serialization + SHA-256 for AST identity
- **No string-based fragility**: Avoids `to_systemverilog()` as keys entirely  
- **Generic design**: No FSM-specific hardcoded assumptions
- **Clean integration**: `feed_asts_to_factorizer()` method for existing codebase
- **Systematic naming**: Generates unique signal names derived from AST structure

### Integration Status
- `run_global_ast_factorization()` updated to use new generic factorizer
- Initializes factorizer, feeds ASTs, runs analysis, stores instance for HDL generation
- **However**, the fundamental declaration generation issue persists

## Critical Gap

Despite the improved AST factorization system, the **declaration generation disconnection** remains the primary blocker. The new factorization correctly identifies and names intermediate signals, but something in the HDL output pipeline is not generating the required `wire` declarations.

## Files Modified/Created
- `FSM/HDL/ASTFactorization.pm` - New generic factorization module
- `FSM/HDL/FlattenedDT.pm` - Updated to use new factorizer (partial integration)

## Status for Next AI
The investigation has reached the point where:
1. ✅ Root cause of string-based factorization fragility identified and addressed
2. ✅ Generic AST factorization system implemented
3. ❌ **Fundamental declaration generation bug still exists**
4. ❌ Need to locate and fix the HDL generation code that emits wire declarations

**Priority**: Fix the declaration generation pipeline before any further factorization improvements.
