package FSM::HDL::FlattenedDT::Orchestrator;

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Debug;

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[FlattenedDT::Orchestrator.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}
sub reset_generation_state ($self) {
    my $ctx = $self->{flattened_dt};

    # Clear per-run generation state so one generator instance can be reused safely.
    $ctx->{state_enables} = {};
    $ctx->{dt_enables} = {};
    $ctx->{lhs_assignments} = {};
    $ctx->{intermediate_signals} = {};
    $ctx->{all_lhs} = {};
    $ctx->{lhs_ast_map} = {};
    $ctx->{reset_assignments} = {};
    $ctx->{global_expressions} = {};
    $ctx->{expression_usage} = {};
    $ctx->{assignment_analysis} = {};
    $ctx->{referenced_intermediate_signals} = {};
    $ctx->{declared_port_signals} = {};
    $ctx->{port_directions} = {};

    delete $ctx->{binary_logical_op_counts};
    delete $ctx->{ast_factorizer};
    delete $ctx->{fsm_module};
}
sub flatten_all_decision_trees ($self, $fsm_module) {
    return $self->{flattened_dt}{decision_tree_flattening_support}
        ->flatten_all_decision_trees($fsm_module);
}
sub flatten_decision_tree ($self, $dt_name, $dt_node, $condition_stack) {
    return $self->{flattened_dt}{decision_tree_flattening_support}
        ->flatten_decision_tree($dt_name, $dt_node, $condition_stack);
}

sub generate_systemverilog ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};

    fsm_debug("Starting flattened DT SystemVerilog generation for " . $fsm_module->name, 3);
    fsm_debug("\n*** PIPELINE TIMING DEBUG: HDL Generation Pipeline Start ***", 3);

    $self->reset_generation_state();
    
    # Step 0: Store FSM module reference for proper signal and reset value analysis
    $ctx->{enable_graph_signal_support}->set_fsm_module_reference($fsm_module);
    fsm_debug("Step 0 - FSM module reference stored", 3);
    
    # Step 1: Analyze and flatten all decision trees
    $self->flatten_all_decision_trees($fsm_module);
    fsm_debug("Step 1 - Decision trees flattened", 3);
    
    my $hdl = $ctx->{backend_sv_generation_structural_prelude_support}
        ->generate_structural_prelude($fsm_module);
    $hdl .= $ctx->{enable_graph_enable_support}->generate_enable_conditions($fsm_module);
    fsm_debug("Step 3 - Enable conditions generated", 3);
    $ctx->{backend_sv_generation_prescan_preparation_support}
        ->prepare_enable_prescan();

    # Step 6: Generate consolidated intermediate signals (combining AST factorization + pre-scan)
    $hdl .= $ctx->{backend_sv_consolidated_intermediate_stage_support}
        ->generate_consolidated_intermediate_block($fsm_module);
    fsm_debug("Step 6 - Consolidated intermediate signals generated", 3);

    $hdl .= $ctx->{backend_sv_generation_tail_support}
        ->generate_systemverilog_tail($fsm_module);
    fsm_debug("*** PIPELINE TIMING DEBUG: HDL Generation Pipeline Complete ***\n", 3);
    
    return $hdl;
}

1;
