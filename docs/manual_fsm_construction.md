# FSM Object Construction for lte_dif_pmaster.fsm

Based on our earlier analysis using Lispish, here's how the FSM::CoreAST objects would be constructed from the raw lte_dif_pmaster.fsm file:

## Raw Structure We Discovered:

```perl
# Top level: ['?fsm:lte_dif_pmaster', [contents...]]
# Contents: 6 elements
# [0] idle (state)
# [1] setup (state)  
# [2] end_write (state)
# [3] end_read (state)
# [4] -syncreset (standalone DT)
# [5] -clr_valid (standalone DT)
```

## FSM Object Construction:

### 1. FSM Module Object
```perl
$fsm_module = FSM::CoreAST::FSMModule->new(
    name => 'lte_dif_pmaster',
    signals => {},  # populated during parsing
    states => [],   # populated below
    standalone_decision_trees => []  # populated below
);
```

### 2. State Objects

#### State: 'idle'
```perl
# Raw structure from our analysis:
# ['idle', [
#   ['<s_rst_n', [
#     ['<apb_rq', [nested actions...]]
#   ]]
# ]]

$idle_state = FSM::CoreAST::State->new(name => 'idle');

$idle_dt = FSM::CoreAST::DecisionTree->new(name => 'idle_dt');

# First condition: <s_rst_n (reset signal high)
$reset_condition = FSM::CoreAST::ConditionalBranch->new(
    condition => FSM::CoreAST::BinaryOp->new(
        'eq',
        FSM::CoreAST::SignalRef->new(
            $adapter->get_or_create_signal('s_rst_n', type => 'wire')
        ),
        FSM::CoreAST::Literal->new('1')
    ),
    actions => [
        # Nested condition: <apb_rq
        FSM::CoreAST::ConditionalBranch->new(
            condition => FSM::CoreAST::BinaryOp->new(
                'eq',
                FSM::CoreAST::SignalRef->new(
                    $adapter->get_or_create_signal('apb_rq', type => 'wire')
                ),
                FSM::CoreAST::Literal->new('1')
            ),
            actions => [
                # From our deep dive: assignments and transitions
                FSM::CoreAST::RegisterAssignment->new(
                    target => FSM::CoreAST::SignalRef->new(
                        $adapter->get_or_create_signal('psel', type => 'wire')
                    ),
                    source => FSM::CoreAST::Literal->new('1')
                ),
                FSM::CoreAST::RegisterAssignment->new(
                    target => FSM::CoreAST::SignalRef->new(
                        $adapter->get_or_create_signal('penable', type => 'wire')
                    ),
                    source => FSM::CoreAST::Literal->new('0')
                ),
                FSM::CoreAST::RegisterAssignment->new(
                    target => FSM::CoreAST::SignalRef->new(
                        $adapter->get_or_create_signal('pwrite', type => 'wire', direction => 'output')
                    ),
                    source => FSM::CoreAST::SignalRef->new(
                        $adapter->get_or_create_signal('apb_wrn', type => 'wire')
                    )
                ),
                # Test node: ?apb_wrn with (=0 ...) (=1 ...) branches
                FSM::CoreAST::TestNode->new(
                    test_signal => FSM::CoreAST::SignalRef->new(
                        $adapter->get_or_create_signal('apb_wrn', type => 'wire')
                    ),
                    test_branches => [
                        {
                            value => '0',
                            actions => [
                                FSM::CoreAST::RegisterAssignment->new(
                                    target => FSM::CoreAST::SignalRef->new(
                                        $adapter->get_or_create_signal('paddr', type => 'wire', width => 8)
                                    ),
                                    source => FSM::CoreAST::SignalRef->new(
                                        $adapter->get_or_create_signal('apb_read_addr', type => 'wire')
                                    )
                                )
                            ]
                        },
                        {
                            value => '1', 
                            actions => [
                                FSM::CoreAST::RegisterAssignment->new(
                                    target => FSM::CoreAST::SignalRef->new(
                                        $adapter->get_or_create_signal('paddr', type => 'wire')
                                    ),
                                    source => FSM::CoreAST::SignalRef->new(
                                        $adapter->get_or_create_signal('apb_waddr', type => 'wire')
                                    )
                                ),
                                FSM::CoreAST::RegisterAssignment->new(
                                    target => FSM::CoreAST::SignalRef->new(
                                        $adapter->get_or_create_signal('pwdata', type => 'wire', width => 16)
                                    ),
                                    source => FSM::CoreAST::SignalRef->new(
                                        $adapter->get_or_create_signal('apb_wdata', type => 'wire')
                                    )
                                )
                            ]
                        }
                    ]
                ),
                FSM::CoreAST::CombinatorialAssignment->new(
                    target => FSM::CoreAST::SignalRef->new(
                        $adapter->get_or_create_signal('apb_ack', type => 'wire')
                    ),
                    source => FSM::CoreAST::Literal->new('1')
                ),
                FSM::CoreAST::StateTransitionFSM->new(
                    target_state => 'setup'
                )
            ]
        )
    ]
);

$idle_dt->add_element($reset_condition);
$idle_state->add_decision_tree($idle_dt);
```

#### State: 'setup'
```perl
$setup_state = FSM::CoreAST::State->new(name => 'setup');
$setup_dt = FSM::CoreAST::DecisionTree->new(name => 'setup_dt');

# Similar structure with <s_rst_n condition and nested actions
# including penable assignments and multiple state transitions
```

### 3. Standalone Decision Trees

#### Standalone DT: 'syncreset'
```perl
# Raw: ['-syncreset', [['<!s_rst_n', [assignments and transitions]]]]

$syncreset_dt = FSM::CoreAST::DecisionTree->new(
    name => 'syncreset', 
    standalone => 1
);

$reset_low_condition = FSM::CoreAST::ConditionalBranch->new(
    condition => FSM::CoreAST::BinaryOp->new(
        'eq',
        FSM::CoreAST::SignalRef->new(
            $adapter->get_or_create_signal('s_rst_n', type => 'wire')
        ),
        FSM::CoreAST::Literal->new('0')  # Negated condition
    ),
    actions => [
        FSM::CoreAST::RegisterAssignment->new(
            target => FSM::CoreAST::SignalRef->new(
                $adapter->get_or_create_signal('psel', type => 'wire')
            ),
            source => FSM::CoreAST::Literal->new('0')
        ),
        FSM::CoreAST::RegisterAssignment->new(
            target => FSM::CoreAST::SignalRef->new(
                $adapter->get_or_create_signal('penable', type => 'wire')
            ),
            source => FSM::CoreAST::Literal->new('0')
        ),
        FSM::CoreAST::RegisterAssignment->new(
            target => FSM::CoreAST::SignalRef->new(
                $adapter->get_or_create_signal('pwrite', type => 'wire')
            ),
            source => FSM::CoreAST::Literal->new('0')
        ),
        FSM::CoreAST::RegisterAssignment->new(
            target => FSM::CoreAST::SignalRef->new(
                $adapter->get_or_create_signal('paddr', type => 'wire', width => 8)
            ),
            source => FSM::CoreAST::Literal->new('0', width => 8, radix => 'binary')  # const_8b0
        ),
        FSM::CoreAST::RegisterAssignment->new(
            target => FSM::CoreAST::SignalRef->new(
                $adapter->get_or_create_signal('pwdata', type => 'wire', width => 16)
            ),
            source => FSM::CoreAST::Literal->new('0', width => 16, radix => 'binary')  # const_16b0
        ),
        FSM::CoreAST::StateTransitionFSM->new(
            target_state => 'idle'
        )
    ]
);

$syncreset_dt->add_element($reset_low_condition);
```

#### Standalone DT: 'clr_valid'
```perl
# Raw: ['-clr_valid', [['apb_rvalid', ['<-', '0', '<apb_rvalid']]]]

$clr_valid_dt = FSM::CoreAST::DecisionTree->new(
    name => 'clr_valid',
    standalone => 1
);

# This shows conditional assignment: assign 0 when <apb_rvalid
$conditional_clear = FSM::CoreAST::RegisterAssignment->new(
    target => FSM::CoreAST::SignalRef->new(
        $adapter->get_or_create_signal('apb_rvalid', type => 'wire')
    ),
    source => FSM::CoreAST::Literal->new('0'),
    condition => FSM::CoreAST::BinaryOp->new(
        'eq',
        FSM::CoreAST::SignalRef->new(
            $adapter->get_or_create_signal('apb_rvalid', type => 'wire')
        ),
        FSM::CoreAST::Literal->new('1')
    )
);

$clr_valid_dt->add_element($conditional_clear);
```

### 4. Final Module Assembly
```perl
$fsm_module->add_state($idle_state);
$fsm_module->add_state($setup_state);
$fsm_module->add_state($end_write_state);  # Similar construction
$fsm_module->add_state($end_read_state);   # Similar construction

$fsm_module->add_standalone_decision_tree($syncreset_dt);
$fsm_module->add_standalone_decision_tree($clr_valid_dt);

# Signal registration happens automatically during parsing
# All signals referenced in assignments and conditions get registered
```

## Key Patterns Discovered:

1. **Nested Conditional Structure**: `<s_rst_n` then `<apb_rq` creates nested ConditionalBranch objects
2. **Signal Width Annotations**: `paddr'8`, `pwdata'16` become signals with explicit widths
3. **Output Markers**: `pwrite>` becomes signal with direction => 'output'
4. **Test Nodes**: `?apb_wrn` becomes TestNode with value-based branching
5. **Predefined Constants**: `const_8b0` becomes Literal with width/radix specifications
6. **Conditional Assignments**: Third parameter becomes condition on assignment
7. **Standalone DTs**: `-syncreset` becomes DecisionTree with standalone => 1

This shows how the FSMGen adapter transforms the complex nested Lisp-like structure into a rich, semantic object hierarchy that preserves all the timing, conditional, and structural information while making it accessible for analysis and code generation.
