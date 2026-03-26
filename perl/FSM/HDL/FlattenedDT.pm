#!/usr/bin/perl

package FSM::HDL::FlattenedDT;
use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin";
use FSM::Debug;  # Global debug system
use FSM::ExpressionNamer;
use FSM::Synthesis::EnableGraph;
use FSM::HDL::FlattenedDT::Orchestrator;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::ScaffoldEmitter;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog;
use FSM::HDL::FlattenedDT::Backend::Verilog;

=head1 NAME

FSM::HDL::FlattenedDT - Flattened Decision Tree SystemVerilog Generator

=head1 DESCRIPTION

This module implements a sophisticated HDL generation approach that flattens
decision trees into enable-based logic with write enables (WENs) and enables (ENs).

Key features:
- Flattens entire FSM/DT hierarchy
- Uses concurrent assignments (assign) instead of procedural blocks  
- Generates WEN/EN signals for each LHS
- Allows sub-DT sharing between states
- Creates flat Boolean expressions from DT traversal

=cut

sub new ($class, %args) {
    my $debug_mode = $args{debug} // 0;
    
    my $self = bless {
        debug => $debug_mode,
        # Storage for flattened analysis
        state_enables => {},      # state_name => enable_condition
        dt_enables => {},         # dt_name => enable_condition  
        lhs_assignments => {},    # lhs_name => [ {dt, conditions, rhs, is_state_trans}, ... ]
        intermediate_signals => {},# signal_name => metadata hash; avoid raw string entries
        all_lhs => {},           # Track all LHS signals across all DTs
        reset_assignments => {},  # LHS that need reset handling
        expr_namer => FSM::ExpressionNamer->new(debug => $debug_mode),  # Expression parser and namer with debug
        # Global expression factoring for cross-DT reuse
        global_expressions => {}, # canonical_expr => signal_name (for reuse)
        expression_usage => {},   # signal_name => usage_count (for optimization)
        factorization_fixpoint_max_passes => $args{factorization_fixpoint_max_passes} // 16,
        
        # UNIFIED PHASE 1 DATA STRUCTURES - Complete assignment analysis
        assignment_analysis => {},  # The unified data structure for all assignment info
        # Structure: {
        #   lhs_signal => {
        #     assignments => [ { dt, conditions, rhs, operator, is_state_trans }, ... ],
        #     rhs_groups => {
        #       rhs_value => {
        #         assignments => [ assignment_refs... ],
        #         dt_specific_enables => [ { dt, enable_name, enable_expr, shared_signal }, ... ],
        #         lhs_level_enable => { name, expr, rhs_value },
        #         multiplexer_info => { enable_signal, rhs_value, priority }
        #       }, ...
        #     },
        #     signal_info => { width, is_flop, reset_value, default_value },
        #     multiplexer => {
        #       type => 'flop'|'comb',
        #       enables => [ { enable_signal, rhs_value, priority }, ... ],
        #       default_value => ...
        #     }
        #   }, ...
        # }
    }, $class;
    
    # Initial extraction slice: dedicated enable synthesis/orchestration layer.
    $self->{enable_graph} = FSM::Synthesis::EnableGraph->new(flattened_dt => $self);
    $self->{orchestrator} = FSM::HDL::FlattenedDT::Orchestrator->new(flattened_dt => $self);
    $self->{backend_sv_scaffold} = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ScaffoldEmitter->new(flattened_dt => $self);
    $self->{backend_sv} = FSM::HDL::FlattenedDT::Backend::SystemVerilog->new(flattened_dt => $self);
    $self->{backend_verilog} = FSM::HDL::FlattenedDT::Backend::Verilog->new(flattened_dt => $self);
    
    return $self;
}


sub generate_systemverilog ($self, $fsm_module) {
    return $self->{orchestrator}->generate_systemverilog($fsm_module);
}

sub generate_verilog ($self, $fsm_module) {
    return $self->{backend_verilog}->generate_verilog($fsm_module);
}

sub convert_systemverilog_to_verilog ($self, $sv_hdl) {
    return $self->{backend_verilog}->convert_systemverilog_to_verilog($sv_hdl);
}

sub generate_vhdl ($self, $fsm_module) {
    die "[FlattenedDT.pm][generate_vhdl()] VHDL backend is not implemented yet. Use --language systemverilog or --language verilog.\n";
}

sub get_signal_assignment_type ($self, $lhs, $lhs_analysis) {
    return $self->{enable_graph}->get_signal_assignment_type($lhs, $lhs_analysis);
}

1;
