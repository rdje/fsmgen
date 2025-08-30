# Reference-Aware Filtering Fix for Intermediate Signal Bug

## Problem Summary

The Perl FSM HDL generator was experiencing "undeclared signal" errors in generated SystemVerilog code. Specifically, intermediate signals like `end_read_en_and_s_rst_n_and_pready_and_apb_rq` were being referenced in final expressions but not declared in the HDL output.

## Root Cause Analysis

### The Issue
The problem occurred during the AST factorization and filtering pipeline:

1. **AST Factorization Phase**: Common sub-expressions were identified and converted into intermediate signals
2. **AST Substitution Phase**: Original expressions were replaced with references to intermediate signals
3. **Filtering Phase**: Intermediate signals were filtered out if they "contained no high-count operations"
4. **HDL Generation Phase**: References to filtered-out signals caused "undeclared signal" errors

### The Core Problem
The filtering logic operated **after** AST substitution had already created references to intermediate signals, but the filtering criteria didn't account for these newly-created references. This created a timing issue where:

- Intermediate signals were referenced in substituted expressions
- But then filtered out during consolidation because they didn't meet the "high-count operations" criteria
- Result: Referenced but undeclared signals in the final HDL

### Debug Process
The issue was identified through extensive debug logging that tracked:
- Logical operation counting (before intermediate signal creation)
- AST factorization and intermediate signal generation
- AST substitution with intermediate signal references
- Filtering decisions and their rationale
- Final HDL generation showing missing declarations

## The Solution: Reference-Aware Filtering

### Implementation Overview
The fix implements **Reference-Aware Filtering** that checks if a signal is actually referenced before filtering it out, regardless of other filtering criteria.

### Key Changes

#### 1. Modified `should_filter_ast_based()` method
Location: `FSM/HDL/FlattenedDT.pm` around line 4172

```perl
# REFERENCE-AWARE FILTERING: Check if signal is referenced in substituted expressions
# This is the fix for the bug where intermediate signals are referenced but not declared
my $referenced_in_substitutions = $self->is_signal_referenced_in_substitutions($signal_name);
if ($referenced_in_substitutions) {
    $self->{debug} && $self->debug("  AST_FILTER: Signal '$signal_name' is referenced in AST substitutions - KEEPING");
    return 0; # Keep signals that are already referenced in substituted expressions
}
```

#### 2. Added `is_signal_referenced_in_substitutions()` method
This new method performs comprehensive reference checking:

```perl
sub is_signal_referenced_in_substitutions ($self, $signal_name) {
    # Check AST factorizer results
    if ($self->{ast_factorizer} && $self->{ast_factorizer}->{ast_expressions}) {
        # Search through all factorized expressions
        for my $expr_info (@$ast_expressions) {
            if ($self->ast_contains_signal($expr_info->{ast}, $signal_name)) {
                return 1; # Signal is referenced
            }
        }
    }
    
    # Check current assignment analysis structures
    # ... (comprehensive search through all AST nodes)
    
    return 0; # Signal not found in any references
}
```

### How the Fix Works

1. **Before Filtering**: When `should_filter_ast_based()` is called for any intermediate signal
2. **Reference Check**: `is_signal_referenced_in_substitutions()` searches all factorized expressions
3. **Decision Logic**: If the signal is found in any substituted expression, return "don't filter" (0)
4. **Result**: Referenced intermediate signals are preserved and declared in HDL output

### Benefits of This Approach

✅ **Surgical Fix**: Only affects signals that are actually referenced
✅ **Preserves Optimization**: Maintains existing intermediate signal filtering benefits
✅ **Minimal Impact**: No changes to AST factorization or substitution logic
✅ **Robust**: Handles all types of intermediate signal references
✅ **Backward Compatible**: No changes to existing filtering criteria for unreferenced signals

## Test Results

After implementing the fix:
- ✅ No more "undeclared signal" errors in generated SystemVerilog
- ✅ Intermediate signals like `end_read_en_and_s_rst_n_and_pready_and_apb_rq` are properly declared
- ✅ Existing AST factorization optimizations remain intact
- ✅ Only truly unused intermediate signals are filtered out

## Debug Methodology

This fix was achieved through:

1. **Comprehensive Debug Logging**: Added extensive debug messages throughout the pipeline
2. **Pipeline Timing Analysis**: Tracked the sequence of factorization → substitution → filtering
3. **Reference Tracking**: Monitored when and where intermediate signals were created and referenced
4. **Root Cause Isolation**: Identified the exact point where referenced signals were being filtered out

## Key Lessons

- **Debug Logging is Critical**: The extensive debug output was essential for understanding the complex pipeline
- **Timing Matters**: The order of operations in complex pipelines can create subtle bugs
- **Reference Tracking**: Post-substitution filtering must be aware of substitution results
- **Surgical Fixes**: Sometimes a small, targeted change is better than a broad architectural change

## Files Modified

- `FSM/HDL/FlattenedDT.pm`: Added `is_signal_referenced_in_substitutions()` method and updated `should_filter_ast_based()`

## Future Considerations

This fix resolves the immediate issue, but future enhancements could include:
- More sophisticated reference tracking during AST transformations
- Unified filtering/substitution phases to avoid timing issues
- Enhanced debug tooling for complex AST pipeline analysis

## Verification

The fix can be verified by:
1. Checking that generated SystemVerilog compiles without "undeclared signal" errors
2. Confirming that intermediate signals referenced in expressions are declared as `wire` statements
3. Verifying that unreferenced intermediate signals are still properly filtered out
