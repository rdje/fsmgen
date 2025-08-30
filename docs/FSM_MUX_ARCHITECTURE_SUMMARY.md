# FSM Mux-Based Architecture Documentation

## Overview

FSM AST v6 implements the complete **mux-based architecture** where Decision Trees (DTs) control P-to-1 multiplexers through WEN/EN signals. This document explains the revolutionary architecture and its implementation.

## Core Architecture Principles

### 1. Decision Tree (DT) Structure
Each Decision Tree has:
- **1-bit enable condition**: Can be permanent HIGH, state decode signal, or OR of multiple conditions
- **Input signals**: Used by DT for decision logic (from FSM inputs, internal combinational, or flop outputs)
- **WEN/EN outputs**: 1-bit signals that control multiplexer selection (not encoded)

### 2. WEN/EN Signal Behavior
```verilog
wen_signal = dt_enable ? decision_tree_output : 1'b0;
```
- When DT enable is HIGH: WEN reflects internal logic result (0 or 1)
- When DT enable is LOW: All WENs forced to 0 (DT controls nothing)

### 3. Multiplexer Control Architecture

#### P-to-1 Mux for Combinational Signals
```
Input Values:  [Value1] [Value2] ... [ValueP]
                  |       |            |
EN Signals:    [EN1]   [EN2]  ...   [ENP]
                  |       |            |
AND Gates:    [AND1]   [AND2] ...  [ANDP]  <-- Layer 1
                  |       |            |
                  +-------+------------+
                          |
OR Gate:               [OUTPUT]              <-- Layer 2
```

#### (P+1)-to-1 Mux for Flop Signals (with Hold)
Same as above, plus:
- **Entry #0**: `F_q AND NOT(WEN1 OR WEN2 OR ... OR WENp)` for hold functionality
- Flop holds its value when all WENs are 0

### 4. FSM State Organization
- Each FSM state has **exactly one Decision Tree**
- At any time, **exactly one DT is active** (enforced by state encoding)
- State encoding options:
  - **Bit-blasted**: One bit per state (`state_en_STATE`)
  - **Encoded**: log₂(N) bits for N states (`current_state == encoding_value`)

## Implementation Classes

### Signal and Condition Classes
```perl
FSM::ASTv6::Signal           # N-bit signals
FSM::ASTv6::SignalCondition  # Single signal conditions
FSM::ASTv6::LogicalCondition # AND, OR, NOT, EQ, NE, etc.
```

### Multiplexer Classes
```perl
FSM::ASTv6::MuxInput        # One mux input (value + enable signal)
FSM::ASTv6::Multiplexer     # Complete P-to-1 or (P+1)-to-1 mux
```

### Decision Tree Classes
```perl
FSM::ASTv6::WENOutput       # DT output (WEN signal + condition)
FSM::ASTv6::DecisionTree    # Complete DT with enable + WEN outputs
```

### FSM Classes
```perl
FSM::ASTv6::DTState         # FSM state with one DT
FSM::ASTv6::FSM             # Complete FSM with states + multiplexers
```

## Generated Verilog Structure

### 1. State Encoding Signals
```verilog
// Bit-blasted
reg state_en_IDLE;
reg state_en_COUNT;

// Or encoded
reg [1:0] current_state;
```

### 2. Decision Tree WEN Generation
```verilog
// WEN = dt_enable ? condition : 1'b0
assign buffer_wen = state_en_IDLE ? (data_ready & ~buffer_full) : 1'b0;
```

### 3. Multiplexer Implementation
```verilog
// AND-gate layer
assign counter_mux_and_0 = {4{counter_wen_reset}} & 4'h0;
assign counter_mux_and_1 = {4{counter_wen_inc}} & (counter + 4'h1);

// Feedback for hold
assign counter_mux_feedback = {4{~(counter_wen_reset | counter_wen_inc)}} & counter_q;

// OR-gate layer
assign counter = counter_mux_and_0 | counter_mux_and_1 | counter_mux_feedback;
```

## Key Architectural Advantages

### 1. Resource Sharing
- Multiple DTs can control the same physical resource through different WEN signals
- OR-gate combination allows multiple control sources

### 2. Flexible Control
- Complex conditional logic in WEN activation
- DT enable provides coarse-grained control
- WEN conditions provide fine-grained control

### 3. Clean Separation
- Decision logic (DTs) separate from data flow (multiplexers)
- Hardware ensures only one WEN active per cycle per FSM state
- Hold logic preserves state when no WEN is active

### 4. Scalable Design
- Easy to add new states (new DTs)
- Easy to add new resources (new multiplexers)
- Easy to add new control paths (new WEN signals)

## Advanced Features Demonstrated

### 1. Complex Conditions
```perl
# AND of multiple conditions
my $write_condition = FSM::ASTv6::LogicalCondition->new('AND', 
    [$data_ready_cond, $not_buffer_full]);

# Nested logical expressions
my $complex_cond = FSM::ASTv6::LogicalCondition->new('OR', 
    [$simple_cond, $and_condition]);
```

### 2. Resource Conflict Analysis
The system can analyze:
- Which DTs control which WEN signals
- Which resources are controlled by multiple WEN signals
- Potential resource conflicts and sharing patterns

### 3. Multiple Encoding Strategies
- **Bit-blasted**: Better for sparse state usage, explicit state enables
- **Encoded**: More efficient for dense state usage, decoded enables

## Files in Implementation

1. **`FSM_ASTv6.pm`**: Complete FSM AST implementation
2. **`demo_mux_architecture.pl`**: Basic mux architecture demonstration
3. **`demo_advanced_mux.pl`**: Advanced resource sharing and complex conditions
4. **`FSM_MUX_ARCHITECTURE_SUMMARY.md`**: This documentation

## Usage Examples

### Basic FSM Creation
```perl
my $fsm = FSM::ASTv6::FSM->new("MyFSM", "bit_blasted");

# Create DT and add WEN outputs
my $dt = FSM::ASTv6::DecisionTree->new("state_dt", undef);
$dt->add_wen_output(FSM::ASTv6::WENOutput->new($wen_signal, $condition));

# Create state and add to FSM
my $state = FSM::ASTv6::DTState->new("STATE1", $dt, 0);
$fsm->add_state($state);

# Create multiplexer and add to FSM
my $mux = FSM::ASTv6::Multiplexer->new($output, \@inputs, 1);
$fsm->add_multiplexer($mux);

# Generate Verilog
print $fsm->generate_verilog();
```

### Advanced Resource Sharing
See `demo_advanced_mux.pl` for complete examples showing:
- Multiple DTs controlling shared resources
- Complex conditional WEN activation
- Resource conflict analysis
- Generated Verilog with proper mux implementation

## Conclusion

This architecture provides a **powerful, flexible, and scalable** foundation for FSM design that:

1. **Separates concerns**: Decision logic vs. data flow
2. **Enables resource sharing**: Multiple control paths for same resources
3. **Maintains correctness**: Hardware-enforced mutual exclusion
4. **Generates clean HDL**: Synthesizable Verilog with clear structure
5. **Supports analysis**: Resource usage and conflict detection

The mux-based architecture is revolutionary because it **decouples the decision-making logic from the data manipulation**, allowing for much more flexible and powerful FSM designs than traditional approaches.
