# Intermediate Signal Filtering Bug - Solution Options

## Problem Description

The FSM HDL generator has a bug where intermediate signals are **referenced but not declared** in the generated SystemVerilog. This occurs because the AST filtering phase removes intermediate signal declarations after they've already been substituted into expressions.

**Example Issue:**
- Signal `end_read_en_and_s_rst_n_and_pready_and_apb_rq` is referenced in lines 111, 118, 121, 127, 129
- But the wire declaration was filtered out during the AST filtering phase
- Root cause: Signal "contains no high-count operations" so was deemed redundant

## Solution Options

### 1. **Reference-Aware Filtering** ⭐ **RECOMMENDED & IMPLEMENTED**

Modify the AST filtering logic to check if an intermediate signal is already referenced in substituted expressions before filtering it out.

**Implementation Approach:**
```perl
sub should_keep_intermediate_signal {
    my ($signal_name, $expression, $substitution_map) = @_;
    
    # Check if signal contains high-count operations (current logic)
    if (contains_high_count_operations($expression)) {
        return 1; # Keep it
    }
    
    # NEW: Check if signal is already referenced in substituted expressions
    if (is_referenced_in_substitutions($signal_name, $substitution_map)) {
        log_debug("KEEPING signal $signal_name - already referenced in substitutions");
        return 1; # Keep it even if no high-count ops
    }
    
    # Filter out only if unused AND no high-count operations
    return 0;
}
```

**Advantages:**
- Fixes the immediate bug
- Preserves the optimization intent
- Minimal code changes
- No performance impact
- Surgical fix addressing exact problem

**Disadvantages:**
- None significant

---

### 2. **Two-Phase Filtering**

Split filtering into two phases: pre-substitution (aggressive) and post-substitution (conservative).

**Implementation Approach:**
```perl
# Phase 1: Filter before substitution (aggressive)
my $filtered_signals = filter_by_high_count_operations($candidate_signals);

# Phase 2: Perform AST substitution with filtered signals
my $substituted_ast = substitute_expressions($ast, $filtered_signals);

# Phase 3: Filter only truly unused signals (conservative)
my $final_signals = filter_unused_signals($filtered_signals, $substituted_ast);
```

**Advantages:**
- Clean separation of concerns
- Better optimization potential
- More predictable behavior

**Disadvantages:**
- Major architectural changes required
- Higher complexity
- Risk of introducing new bugs

---

### 3. **Conservative Solution: Disable Post-Substitution Filtering**

Simply disable the filtering phase that occurs after AST substitution.

**Implementation Approach:**
```perl
# Comment out or add a flag to disable post-substitution filtering
# $intermediate_signals = filter_redundant_signals($intermediate_signals);
log_debug("SKIPPING post-substitution filtering to avoid reference issues");
```

**Advantages:**
- Immediate fix with minimal risk
- Guaranteed correctness
- Easy to implement

**Disadvantages:**
- May keep some unnecessary intermediate signals
- Slightly larger generated code
- Loses optimization benefits

---

### 4. **Robust Solution: Dependency Graph**

Build a dependency graph to track which signals reference which other signals.

**Implementation Approach:**
```perl
sub build_signal_dependency_graph {
    my ($intermediate_signals, $substituted_expressions) = @_;
    my %dependencies;
    
    foreach my $expr (@$substituted_expressions) {
        my @referenced_signals = extract_intermediate_signal_references($expr);
        foreach my $sig (@referenced_signals) {
            $dependencies{$sig}++;
        }
    }
    return \%dependencies;
}

sub filter_with_dependencies {
    my ($signals, $dependencies) = @_;
    my @kept_signals;
    
    foreach my $signal (@$signals) {
        if ($dependencies->{$signal->{name}} || contains_high_count_operations($signal)) {
            push @kept_signals, $signal;
        }
    }
    return \@kept_signals;
}
```

**Advantages:**
- Most robust solution
- Handles complex dependency chains
- Future-proof
- Scales to larger designs

**Disadvantages:**
- More complex implementation
- Higher development effort
- Overkill for current problem

---

### 5. **Quick Fix: Add Missing Signal Declarations**

Automatically detect missing signal declarations and add them during code generation.

**Implementation Approach:**
```perl
sub add_missing_signal_declarations {
    my ($systemverilog_code, $intermediate_signals) = @_;
    
    # Find all intermediate signal references in the generated code
    my @referenced_signals = extract_signal_references($systemverilog_code);
    
    # Find missing declarations
    my %declared_signals = map { $_->{name} => $_ } @$intermediate_signals;
    my @missing_signals;
    
    foreach my $ref_signal (@referenced_signals) {
        if (!exists $declared_signals{$ref_signal}) {
            push @missing_signals, $ref_signal;
            log_warning("Adding missing declaration for: $ref_signal");
        }
    }
    
    # Generate missing declarations from original factorization data
    my $missing_declarations = generate_missing_declarations(\@missing_signals);
    
    return prepend_declarations($systemverilog_code, $missing_declarations);
}
```

**Advantages:**
- Immediate fix for any missing signals
- Works regardless of root cause
- Can be used as safety net

**Disadvantages:**
- Treats symptom rather than cause
- May mask other bugs
- Requires parsing generated code

---

## Implementation Status

- ✅ **Option #1 (Reference-Aware Filtering)** - **IMPLEMENTED**
- ⏸️ Option #2 (Two-Phase Filtering) - Not implemented
- ⏸️ Option #3 (Disable Filtering) - Not implemented  
- ⏸️ Option #4 (Dependency Graph) - Not implemented
- ⏸️ Option #5 (Quick Fix) - Not implemented

## Notes

- Option #1 was chosen as the best balance of effectiveness, simplicity, and risk
- The implementation preserves all existing optimization behavior while fixing the bug
- Other options remain available if future requirements change
