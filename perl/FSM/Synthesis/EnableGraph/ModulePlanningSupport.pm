package FSM::Synthesis::EnableGraph::ModulePlanningSupport;

=head1 NAME

FSM::Synthesis::EnableGraph::ModulePlanningSupport - Own module-boundary and state-register planning for EnableGraph

=head1 DESCRIPTION

This package owns the bounded module/state/declaration planning family that
used to live inline inside C<FSM::Synthesis::EnableGraph>. It centralizes:

=over 4

=item *

effective system-contract resolution for one prepared backend context

=item *

state-register plan construction

=item *

module interface declaration planning

=item *

internal and auxiliary declaration planning

=back

The broader synthesis owner still owns assignment analysis, signal
classification, AST rendering, and HDL-generation policy around these plans.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use Data::Dumper;
use FSM::Debug;

=head2 new

Construct a module-planning support owner bound to one live
C<FSM::HDL::FlattenedDT> context.

=cut

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[ModulePlanningSupport.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

=head2 build_state_register_plan

Build the normalized state-register plan for one semantic FSM/DT module.

=cut

sub build_state_register_plan ($self, $fsm_module = undef) {
    my $ctx = $self->{flattened_dt};
    $fsm_module //= $ctx->{fsm_module};

    my @regular_states = $fsm_module
        ? grep { $_->can('is_regular_state') ? $_->is_regular_state : $_->name !~ /^-/ } @{$fsm_module->states}
        : ();
    my $state_count = scalar(@regular_states);
    my $state_bits = $state_count > 1 ? int(log($state_count) / log(2)) + 1 : 1;
    my @encodings;

    for my $i (0 .. $#regular_states) {
        push @encodings, {
            state_name => $regular_states[$i]->name,
            localparam_name => uc($regular_states[$i]->name),
            encoded_value => $i,
        };
    }

    return {
        has_state_registers => $state_count > 0 ? 1 : 0,
        state_count => $state_count,
        state_bits => $state_bits,
        reset_state_name => @encodings ? $encodings[0]{localparam_name} : 'IDLE',
        encodings => \@encodings,
    };
}

=head2 effective_system_contract

Resolve the effective system contract for one semantic FSM/DT module, falling
back to the implicit direct-backend default when no explicit contract is
available on the module itself.

=cut

sub effective_system_contract ($self, $fsm_module = undef) {
    my $ctx = $self->{flattened_dt};
    $fsm_module //= $ctx->{fsm_module};

    if ($fsm_module && $fsm_module->can('effective_system_contract')) {
        return $fsm_module->effective_system_contract;
    }

    return {
        clock => 'clk',
        reset => 'rst_n',
        reset_keyword => 'areset',
        reset_kind => 'async',
        reset_active_level => 0,
        implicit => 1,
    };
}

=head2 effective_clock_name

Return the effective clock signal name for one semantic FSM/DT module.

=cut

sub effective_clock_name ($self, $fsm_module = undef) {
    return $self->effective_system_contract($fsm_module)->{clock};
}

=head2 effective_reset_name

Return the effective reset signal name for one semantic FSM/DT module.

=cut

sub effective_reset_name ($self, $fsm_module = undef) {
    return $self->effective_system_contract($fsm_module)->{reset};
}

=head2 effective_reset_policy

Return the normalized reset policy for one semantic FSM/DT module.

=cut

sub effective_reset_policy ($self, $fsm_module = undef) {
    my $system_contract = $self->effective_system_contract($fsm_module);
    my $reset_name = $system_contract->{reset};
    unless (defined($reset_name) && !ref($reset_name) && length($reset_name)) {
        return {
            present => 0,
            kind => 'none',
            active_level => undef,
            keyword => undef,
        };
    }

    my $reset_keyword = $system_contract->{reset_keyword} // '';
    my $reset_kind = $system_contract->{reset_kind}
        // ($reset_keyword eq 'sreset' ? 'sync' : 'async');
    my $reset_active_level = exists($system_contract->{reset_active_level})
        ? ($system_contract->{reset_active_level} ? 1 : 0)
        : ($reset_kind eq 'sync' ? 1 : 0);

    return {
        present => 1,
        kind => $reset_kind,
        active_level => $reset_active_level,
        keyword => $reset_keyword,
    };
}

=head2 sequential_event_control

Return the SystemVerilog event control body for a reset-aware sequential block.

=cut

sub sequential_event_control ($self, $fsm_module = undef) {
    my $clock_name = $self->effective_clock_name($fsm_module);
    my $reset_name = $self->effective_reset_name($fsm_module);
    my $reset_policy = $self->effective_reset_policy($fsm_module);

    return "posedge $clock_name"
        if !$reset_policy->{present} || $reset_policy->{kind} eq 'sync';

    my $reset_edge = $reset_policy->{active_level} ? 'posedge' : 'negedge';
    return "posedge $clock_name or $reset_edge $reset_name";
}

=head2 reset_condition_expr

Return the SystemVerilog reset-active condition expression.

=cut

sub reset_condition_expr ($self, $fsm_module = undef) {
    my $reset_name = $self->effective_reset_name($fsm_module);
    my $reset_policy = $self->effective_reset_policy($fsm_module);

    return undef unless $reset_policy->{present};
    return $reset_policy->{active_level} ? $reset_name : "!$reset_name";
}

=head2 build_internal_signal_declaration_plan

Build the normalized internal-storage and auxiliary-declaration plan for one
prepared direct backend context.

=cut

sub build_internal_signal_declaration_plan ($self, $fsm_module, $declared_ports = undef) {
    my $ctx = $self->{flattened_dt};
    my %declared_ports = ();
    if (ref($declared_ports) eq 'HASH') {
        %declared_ports = %{$declared_ports};
    } elsif ($ctx->{declared_port_signals}) {
        %declared_ports = %{$ctx->{declared_port_signals}};
    }

    my %signal_decls;
    my %aux_decls;
    my %signal_signed;
    my %aux_signed;
    my %signal_state_model;
    my %aux_state_model;
    my %signal_declared_type_name;
    my %aux_declared_type_name;
    my %signal_declared_type_spec;
    my %aux_declared_type_spec;
    my %signals = %{$fsm_module->signals || {}};

    my $state_plan = $self->build_state_register_plan($fsm_module);
    if ($state_plan->{has_state_registers}) {
        $declared_ports{current_state} = 1;
        $declared_ports{next_state} = 1;
    }

    for my $lhs (sort keys %{$ctx->{assignment_analysis} || {}}) {
        my $lhs_analysis = $ctx->{assignment_analysis}{$lhs};
        next unless $lhs_analysis;

        my $width = $ctx->{enable_graph_assignment_support}->get_lhs_width_from_analysis($lhs_analysis);
        my $assignment_type = $ctx->{enable_graph_assignment_support}->get_signal_assignment_type($lhs, $lhs_analysis);
        my $multiplexer_type = $lhs_analysis->{multiplexer}->{type} || 'comb';
        my $lhs_signed = _signal_signed($signals{$lhs});
        my $lhs_state_model = _signal_state_model($signals{$lhs});
        my $lhs_declared_type_name = _signal_declared_type_name($signals{$lhs});
        my $lhs_declared_type_spec = _signal_declared_type_spec($signals{$lhs});
        if (!$lhs_signed && $lhs_analysis->{lhs_ast} && ref($lhs_analysis->{lhs_ast}) && $lhs_analysis->{lhs_ast}->can('signal')) {
            $lhs_signed = _signal_signed($lhs_analysis->{lhs_ast}->signal);
        }
        if (!defined($lhs_state_model) && $lhs_analysis->{lhs_ast} && ref($lhs_analysis->{lhs_ast}) && $lhs_analysis->{lhs_ast}->can('signal')) {
            $lhs_state_model = _signal_state_model($lhs_analysis->{lhs_ast}->signal);
        }
        if (!defined($lhs_declared_type_name) && $lhs_analysis->{lhs_ast} && ref($lhs_analysis->{lhs_ast}) && $lhs_analysis->{lhs_ast}->can('signal')) {
            $lhs_declared_type_name = _signal_declared_type_name($lhs_analysis->{lhs_ast}->signal);
        }
        if (!defined($lhs_declared_type_spec) && $lhs_analysis->{lhs_ast} && ref($lhs_analysis->{lhs_ast}) && $lhs_analysis->{lhs_ast}->can('signal')) {
            $lhs_declared_type_spec = _signal_declared_type_spec($lhs_analysis->{lhs_ast}->signal);
        }

        unless ($declared_ports{$lhs}) {
            $signal_decls{$lhs} = $width;
            $signal_signed{$lhs} = $lhs_signed;
            $signal_state_model{$lhs} = $lhs_state_model if defined $lhs_state_model;
            $signal_declared_type_name{$lhs} = $lhs_declared_type_name if defined $lhs_declared_type_name;
            $signal_declared_type_spec{$lhs} = $lhs_declared_type_spec if defined $lhs_declared_type_spec;
        }

        if ($multiplexer_type eq 'flop' && ($assignment_type eq 'register_out' || $assignment_type eq 'register_out_dual')) {
            my $next_name = "${lhs}_next";
            unless ($declared_ports{$next_name}) {
                $aux_decls{$next_name} = $width;
                $aux_signed{$next_name} = $lhs_signed;
                $aux_state_model{$next_name} = $lhs_state_model if defined $lhs_state_model;
                $aux_declared_type_name{$next_name} = $lhs_declared_type_name if defined $lhs_declared_type_name;
                $aux_declared_type_spec{$next_name} = $lhs_declared_type_spec if defined $lhs_declared_type_spec;
            }
        } elsif ($multiplexer_type eq 'flop' && ($assignment_type eq 'register_in' || $assignment_type eq 'register_in_dual')) {
            my $q_name = "${lhs}_q";
            unless ($declared_ports{$q_name}) {
                $aux_decls{$q_name} = $width;
                $aux_signed{$q_name} = $lhs_signed;
                $aux_state_model{$q_name} = $lhs_state_model if defined $lhs_state_model;
                $aux_declared_type_name{$q_name} = $lhs_declared_type_name if defined $lhs_declared_type_name;
                $aux_declared_type_spec{$q_name} = $lhs_declared_type_spec if defined $lhs_declared_type_spec;
            }
        } elsif ($assignment_type eq 'pulse_delayed') {
            my $delay_cycles = $ctx->{enable_graph_assignment_support}->get_pulse_delay_cycles_for_lhs($lhs, $lhs_analysis);
            if ($delay_cycles > 0) {
                my $pipe_name = "${lhs}_pulse_delay_pipe";
                unless ($declared_ports{$pipe_name}) {
                    $aux_decls{$pipe_name} = $delay_cycles;
                    $aux_signed{$pipe_name} = 0;
                }
            }
        }
    }

    return {
        signal_decls => \%signal_decls,
        aux_decls => \%aux_decls,
        signal_signed => \%signal_signed,
        aux_signed => \%aux_signed,
        signal_state_model => \%signal_state_model,
        aux_state_model => \%aux_state_model,
        signal_declared_type_name => \%signal_declared_type_name,
        aux_declared_type_name => \%aux_declared_type_name,
        signal_declared_type_spec => \%signal_declared_type_spec,
        aux_declared_type_spec => \%aux_declared_type_spec,
    };
}

=head2 build_module_declaration_plan

Build the normalized module-boundary declaration plan for one semantic FSM/DT
module, including base system ports, declared interface signals, and the final
direction inventory.

=cut

sub build_module_declaration_plan ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    my $system_contract = $self->effective_system_contract($fsm_module);
    my $clock_name = $system_contract->{clock};
    my $reset_name = $system_contract->{reset};
    my @base_ports;
    if ($system_contract->{declare_ports} // 1) {
        push @base_ports,
            {
                direction => 'input',
                storage => 'wire',
                name => $clock_name,
                width => 1,
            };
        push @base_ports,
            {
                direction => 'input',
                storage => 'wire',
                name => $reset_name,
                width => 1,
            }
            if defined($reset_name) && !ref($reset_name) && length($reset_name);
    }

    my $signals = $fsm_module->signals;
    my @inputs;
    my @outputs;

    fsm_debug("HDL Generation: Processing " . scalar(keys %$signals) . " signals for module declaration", 3);

    my %seen_signals;
    my %port_directions;
    if ($system_contract->{declare_ports} // 1) {
        %seen_signals = ($clock_name => 1);
        %port_directions = ($clock_name => 'input');
        if (defined($reset_name) && !ref($reset_name) && length($reset_name)) {
            $seen_signals{$reset_name} = 1;
            $port_directions{$reset_name} = 'input';
        }
    }
    my %driven_signals = $ctx->{enable_graph_assignment_support}->get_driven_signals();

    for my $sig_name (sort keys %$signals) {
        if ($seen_signals{$sig_name}) {
            fsm_debug("HDL Signal Processing: SKIPPING duplicate signal '$sig_name'", 3);
            next;
        }
        $seen_signals{$sig_name} = 1;

        my $signal = $signals->{$sig_name};

        my $is_intermediate = 0;
        if ($signal->can('get_attribute')) {
            my $signal_role = $signal->get_attribute('signal_role');
            $is_intermediate = ($signal_role && $signal_role eq 'INTERNAL_INTERMEDIATE');
        } elsif ($signal->can('attributes') && $signal->attributes) {
            $is_intermediate = $signal->attributes->{is_intermediate} || 0;
        }

        if ($is_intermediate) {
            fsm_debug("HDL Signal Processing: SKIPPING intermediate signal '$sig_name' from interface", 3);
            next;
        }

        fsm_debug("HDL Signal Processing: $sig_name", 3);
        fsm_debug("  Signal object type: " . ref($signal), 3);
        fsm_debug("  Signal dump: " . Dumper($signal), 3);

        my $signal_width = 1;
        if ($signal->can('width')) {
            $signal_width = $signal->width;
            $signal_width = 1 unless ($signal_width && $signal_width > 0);
            fsm_debug("  Signal width from ->width(): $signal_width", 3);
        } else {
            fsm_debug("  Signal does not have width() method", 3);
        }

        my $is_output = 0;
        if ($driven_signals{$sig_name}) {
            $is_output = 1;
            fsm_debug("  Signal '$sig_name' is DRIVEN by FSM -> OUTPUT", 3);
        } else {
            if ($signal->can('is_output')) {
                $is_output = $signal->is_output;
            } elsif ($signal->can('attributes') && $signal->attributes && $signal->attributes->{is_output}) {
                $is_output = $signal->attributes->{is_output};
            } elsif ($sig_name =~ />$/) {
                $is_output = 1;
            }

            fsm_debug("  Signal '$sig_name' direction: " . ($is_output ? "OUTPUT" : "INPUT"), 3);
        }

        my $port_plan = {
            direction => $is_output ? 'output' : 'input',
            storage => $is_output ? 'reg' : 'wire',
            name => $sig_name,
            width => $signal_width,
            signed => _signal_signed($signal),
            state_model => _signal_state_model($signal),
            declared_type_name => _signal_declared_type_name($signal),
            declared_type_spec => _signal_declared_type_spec($signal),
        };

        if ($is_output) {
            push @outputs, $port_plan;
            $port_directions{$sig_name} = 'output';
        } else {
            push @inputs, $port_plan;
            $port_directions{$sig_name} = 'input';
        }
    }

    return {
        base_ports => \@base_ports,
        inputs => \@inputs,
        outputs => \@outputs,
        declared_port_signals => \%seen_signals,
        port_directions => \%port_directions,
    };
}

sub _signal_signed ($signal) {
    return 0 unless $signal;
    return ($signal->signed // 0) ? 1 : 0
        if ref($signal) && $signal->can('signed');
    return ($signal->get_attribute('signed') // 0) ? 1 : 0
        if ref($signal) && $signal->can('get_attribute');
    return ($signal->attributes->{signed} // 0) ? 1 : 0
        if ref($signal) && $signal->can('attributes') && $signal->attributes;
    return 0;
}

sub _signal_state_model ($signal) {
    return undef unless $signal;
    return $signal->state_model
        if ref($signal) && $signal->can('state_model');
    return $signal->get_attribute('state_model')
        if ref($signal) && $signal->can('get_attribute') && defined $signal->get_attribute('state_model');
    return $signal->attributes->{state_model}
        if ref($signal) && $signal->can('attributes') && $signal->attributes && exists $signal->attributes->{state_model};
    return undef;
}

sub _signal_declared_type_name ($signal) {
    return undef unless $signal;
    return $signal->declared_type_name
        if ref($signal) && $signal->can('declared_type_name');
    return $signal->get_attribute('declared_type_name')
        if ref($signal) && $signal->can('get_attribute') && defined $signal->get_attribute('declared_type_name');
    return $signal->attributes->{declared_type_name}
        if ref($signal) && $signal->can('attributes') && $signal->attributes && exists $signal->attributes->{declared_type_name};
    return undef;
}

sub _signal_declared_type_spec ($signal) {
    return undef unless $signal;
    return $signal->declared_type_spec
        if ref($signal) && $signal->can('declared_type_spec');
    return $signal->get_attribute('declared_type_spec')
        if ref($signal) && $signal->can('get_attribute') && defined $signal->get_attribute('declared_type_spec');
    return $signal->attributes->{declared_type_spec}
        if ref($signal) && $signal->can('attributes') && $signal->attributes && exists $signal->attributes->{declared_type_spec};
    return undef;
}

1;

__END__

=head1 METHODS

=head2 new

Constructs one module-planning support owner bound to a specific
C<FSM::HDL::FlattenedDT> backend context.

=head2 build_state_register_plan

Builds the normalized state-register plan for one semantic FSM/DT module.

=head2 effective_system_contract

Resolves the effective system contract for one semantic FSM/DT module.

=head2 effective_clock_name

Returns the effective clock signal name from the resolved system contract.

=head2 effective_reset_name

Returns the effective reset signal name from the resolved system contract.

=head2 build_internal_signal_declaration_plan

Builds the internal-storage and auxiliary declaration plan used by the direct
generated-module backend after module-boundary declaration planning.

=head2 build_module_declaration_plan

Builds the normalized module-boundary declaration plan used by the direct
generated-module backend scaffold.

=cut
