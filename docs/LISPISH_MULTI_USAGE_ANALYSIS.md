# Lispish::multi Usage Analysis in FSM Processing Pipeline

## Overview

This document analyzes how `Lispish::multi` is used in the FSM (Finite State Machine) processing pipeline to parse external FSM descriptions and convert them into internal representations for HDL generation.

## Key Usage Pattern

### 1. Entry Point: FSM File Loading
```perl
# From generate_fsm_hdl.pl line 127
my $raw_ast = Lispish::multi($fsm_file);
```

**Purpose**: Parse `.fsm` files containing FSM descriptions in Lispish format into raw Abstract Syntax Trees (ASTs).

### 2. Integration Points in FSMGen.pm

#### A. Direct File Loading (line 56)
```perl
sub fsm_file_load  {map {Lispish::multi($_)}  @_};
```
**Usage**: Batch processing of multiple FSM files, each parsed into separate AST structures.

#### B. Macro Processing (line 2952)  
```perl
fsm_analyze ($lcr, [map {$$lcr{fsm}{$_} //= Lispish::multi(PathSearch->go($_, 'fsm'))} grep {!ref && !/^(?:\/|=)/} @{$ar->[1]}]);
```
**Usage**: Dynamic loading of FSM files during macro expansion and hierarchical processing.

## Data Flow Architecture

```
.fsm File → Lispish::multi() → Raw AST → FSMGen Adapter → Semantic AST → HDL Generator
    ↓              ↓              ↓            ↓              ↓            ↓
Input Format   Lisp Parser   Raw Structure  FSM Parser   Core AST    SystemVerilog
```

### Raw AST Structure (from Lispish::multi)
The function returns nested array structures representing the Lispish syntax:

```perl
[
  [
    "?fsm:module_name",
    [
      ["state_name", [nested_conditions_and_actions]],
      ["-special_dt", [standalone_decision_tree]],
      # ... more states and DTs
    ]
  ]
]
```

### Key Parsed Elements
1. **FSM Module Declaration**: `?fsm:module_name`
2. **State Definitions**: `["state_name", [actions]]`
3. **Standalone Decision Trees**: `["-dt_name", [conditions]]`
4. **Signal Assignments**: `["signal", ["<-", "value"]]`
5. **State Transitions**: `["->"", ["target_state"]]`
6. **Test Conditions**: `["?signal", [branches]]`

## Processing Pipeline Details

### Stage 1: Raw Parsing (Lispish::multi)
- **Input**: `.fsm` file with Lispish syntax
- **Output**: Nested array structure preserving original syntax
- **Function**: Pure syntactic parsing, no semantic interpretation

### Stage 2: Semantic Analysis (FSM Adapters)
The raw AST is processed by specialized adapters:

#### FSMGenFull Adapter (Primary)
```perl
my $adapter = FSM::Adapter::FSMGenFull->new(debug => $debug_mode);
my $fsm_module = $adapter->parse_fsm($raw_ast);
```

**Key Processing Steps**:
1. **Module Creation**: Extract FSM name from `?fsm:name` header
2. **Signal Registry**: Build signal database with width/direction inference
3. **State Processing**: Convert each state to DecisionTree structures
4. **Action Parsing**: Transform assignments, transitions, tests into CoreAST nodes

#### Example Transformation
**Raw AST** (from Lispish::multi):
```perl
["psel", ["<-", "1"]]
```

**Semantic AST** (after adapter):
```perl
FSM::CoreAST::RegisterAssignment->new(
    target => FSM::CoreAST::SignalRef->new($psel_signal),
    source => FSM::CoreAST::Literal->new(1),
    assignment_type => 'clocked'
)
```

### Stage 3: HDL Generation
The semantic AST is used by HDL generators to produce:
- SystemVerilog (.sv)
- Verilog (.v) 
- VHDL (.vhd)

## Critical Integration Points

### 1. Signal Handling
The adapter processes signals from the raw AST:
```perl
sub get_or_create_signal {
    # Extract signal name, infer width, determine direction
    # Create FSM::CoreAST::Signal objects
    # Register in signal database
}
```

### 2. Width Inference
```perl
# From raw: "paddr'8" 
# Inferred: 8-bit signal named "paddr"
if ($signal_name =~ /(\w+)'(\d+)/) {
    my ($name, $width) = ($1, $2);
    # Create signal with explicit width
}
```

### 3. Condition Processing
```perl
# From raw: "<s_rst_n" or "<!s_rst_n"
sub parse_condition {
    if ($condition =~ /^<(!)?([a-zA-Z]\w*)$/) {
        my ($negated, $signal_name) = ($1, $2);
        return ($negated ? 1 : 0, $signal_name);
    }
}
```

## Debug Output Analysis

From the provided debug trace, we can see the complete flow:

```
=== FSM HDL Generator ===
Loading FSM file: /path/to/lte_dif_pmaster.fsm
Parsing FSM file with Lispish...    ← Lispish::multi() called here
Raw AST loaded, creating FSMGen adapter...
DEBUG:[FSMGenFull::parse_fsm] Starting full FSMGen parsing
...
```

The debug shows:
1. **File Loading**: Lispish::multi processes the .fsm file
2. **AST Creation**: Raw nested arrays are created
3. **Semantic Processing**: FSMGenFull adapter converts to CoreAST
4. **Signal Processing**: Signals are registered and typed
5. **HDL Generation**: Final SystemVerilog output is produced

## Usage in Different Contexts

### 1. Command-Line Tools
```perl
# generate_fsm_hdl.pl
my $raw_ast = Lispish::multi($fsm_file);
```

### 2. Batch Processing
```perl
# FSMGen.pm
sub fsm_file_load {map {Lispish::multi($_)} @_};
```

### 3. Dynamic Loading
```perl
# During macro expansion
$$lcr{fsm}{$_} //= Lispish::multi(PathSearch->go($_, 'fsm'))
```

## Error Handling

The system handles various error conditions:
1. **File Not Found**: Lispish::multi returns undef
2. **Parse Errors**: Invalid Lispish syntax causes parse failure
3. **Semantic Errors**: Adapter validates FSM structure

## Performance Considerations

- **Caching**: Results are cached to avoid re-parsing
- **Lazy Loading**: Files are loaded only when needed
- **Memory Usage**: Large FSM files create substantial AST structures

## Conclusion

`Lispish::multi` serves as the critical entry point for the entire FSM processing pipeline. It transforms external FSM descriptions in Lispish syntax into internal data structures that can be semantically analyzed and converted to HDL. The function's output provides the foundation for all subsequent FSM processing, making it essential for the system's operation.

The raw AST structure preserves the original Lispish syntax while providing a foundation for semantic analysis by specialized adapters that understand FSM constructs like states, signals, assignments, and transitions.
