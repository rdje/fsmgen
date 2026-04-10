package FSM::Backend;

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings qw(experimental::signatures experimental::postderef);

use Carp;
use FSM::Template;
use Exporter 'import';

our $VERSION = '2.0';
our @EXPORT_OK = qw();

# Base backend class
package FSM::Backend::Base {
    use v5.20;
    use strict;
    use warnings;
    use feature qw(signatures);
    no warnings qw(experimental::signatures);
    use Carp;

    sub new($class, %args) {
        my $self = {
            template_engine => $args{template_engine} // croak("Template engine required"),
            options => $args{options} // {},
        };
        return bless $self, $class;
    }

    sub template_engine($self) { return $self->{template_engine} }
    sub options($self) { return $self->{options} }

    sub generate($self, $ast_module) {
        croak "generate() must be implemented by subclass";
    }

    sub set_option($self, $key, $value) {
        $self->{options}{$key} = $value;
    }

    sub get_option($self, $key, $default = undef) {
        return $self->{options}{$key} // $default;
    }
}

# VHDL backend
package FSM::Backend::VHDL {
    use v5.20;
    use parent -norequire, 'FSM::Backend::Base';
    use strict;
    use warnings;
    use feature qw(signatures);
    no warnings qw(experimental::signatures);
    use Carp;

    sub new($class, %args) {
        my $template_engine = $args{template_engine} // 
            FSM::Template::create_template_engine('vhdl');
        
        my $self = $class->SUPER::new(
            template_engine => $template_engine,
            %args
        );

        # Set default VHDL options
        $self->{options} = {
            use_numeric_std => 1,
            reset_active_low => 1,
            state_encoding => 'auto', # auto, binary, onehot, gray
            %{$args{options} // {}}
        };

        return $self;
    }

    sub generate($self, $ast_module) {
        my $entity_code = $self->_generate_entity($ast_module);
        my $architecture_code = $self->_generate_architecture($ast_module);
        
        return $entity_code . "\n\n" . $architecture_code;
    }

    sub _generate_entity($self, $module) {
        my $template = $self->template_engine();
        
        # Generate generics section
        my $generics = '';
        my @generic_list = keys $module->generics()->%*;
        if (@generic_list) {
            $generics = "generic (\n";
            for my $i (0 .. $#generic_list) {
                my $name = $generic_list[$i];
                my $value = $module->generics()->{$name};
                $generics .= $template->render('generic', 
                    name => $name,
                    type => 'integer',
                    default => $value
                );
                $generics .= ";" if $i < $#generic_list;
                $generics .= "\n";
            }
            $generics .= ");\n";
        }

        # Generate ports section
        my $ports = '';
        my @port_list = $module->ports()->@*;
        if (@port_list) {
            $ports = "port (\n";
            for my $i (0 .. $#port_list) {
                my $port = $port_list[$i];
                $ports .= $template->render('port',
                    name => $port->name,
                    direction => $template->format_direction($port->direction),
                    type => $template->format_type($port->port_type, $port->width)
                );
                $ports .= ";" if $i < $#port_list;
                $ports .= "\n";
            }
            $ports .= ");\n";
        }

        return $template->render('entity',
            entity_name => $module->name,
            generics => $generics,
            ports => $ports
        );
    }

    sub _generate_architecture($self, $module) {
        my $template = $self->template_engine();

        # Generate signals
        my $signals = '';
        for my $signal ($module->signals()->@*) {
            my $initial = '';
            if (defined $signal->initial_value) {
                $initial = ' := ' . $signal->initial_value;
            }
            
            $signals .= $template->render('signal',
                name => $signal->name,
                type => $template->format_type($signal->signal_type, $signal->width),
                initial => $initial
            ) . "\n";
        }

        # Generate state type and signal if we have states
        my @states = $module->states()->@*;
        if (@states) {
            $signals .= "    type state_type is (" . 
                        join(', ', map { $template->format_state_name($_->name) } @states) .
                        ");\n";
            $signals .= "    signal current_state, next_state : state_type;\n";
        }

        # Generate processes
        my $processes = '';
        if (@states) {
            $processes = $self->_generate_fsm_process($module);
        }

        return $template->render('architecture',
            entity_name => $module->name,
            signals => $signals,
            constants => '',
            types => '',
            processes => $processes
        );
    }

    sub _generate_fsm_process($self, $module) {
        my $template = $self->template_engine();
        my @states = $module->states()->@*;

        # Find reset state
        my $reset_state = '';
        for my $state (@states) {
            if ($state->is_reset_state) {
                $reset_state = $template->format_state_name($state->name);
                last;
            }
        }
        $reset_state ||= $template->format_state_name($states[0]->name) if @states;

        # Generate reset assignments
        my $reset_assignments = "        current_state <= $reset_state;\n";

        # Generate state cases
        my $state_cases = '';
        for my $state (@states) {
            my $assignments = '';
            for my $assignment ($state->assignments()->@*) {
                if ($assignment->is_conditional) {
                    $assignments .= $template->render('conditional_assignment',
                        condition => $assignment->condition,
                        target => $assignment->target,
                        expression => $assignment->expression
                    ) . "\n";
                } else {
                    $assignments .= $template->render('assignment',
                        target => $assignment->target,
                        expression => $assignment->expression
                    ) . "\n";
                }
            }

            my $transitions = '';
            for my $transition ($state->transitions()->@*) {
                if ($transition->is_conditional) {
                    $transitions .= $template->render('transition',
                        condition => $transition->condition,
                        state_signal => 'current_state',
                        target_state => $template->format_state_name($transition->target_state)
                    ) . "\n";
                } else {
                    $transitions .= $template->render('default_transition',
                        state_signal => 'current_state',
                        target_state => $template->format_state_name($transition->target_state)
                    ) . "\n";
                }
            }

            $state_cases .= $template->render('state_case',
                state_name => $template->format_state_name($state->name),
                assignments => $assignments,
                transitions => $transitions
            );
        }

        return $template->render('fsm_process',
            reset_assignments => $reset_assignments,
            state_signal => 'current_state',
            state_cases => $state_cases,
            reset_state => $reset_state
        );
    }
}

# SystemVerilog backend
package FSM::Backend::SystemVerilog {
    use v5.20;
    use parent -norequire, 'FSM::Backend::Base';
    use strict;
    use warnings;
    use feature qw(signatures);
    no warnings qw(experimental::signatures);
    use Carp;

    sub new($class, %args) {
        my $template_engine = $args{template_engine} // 
            FSM::Template::create_template_engine('systemverilog');
        
        my $self = $class->SUPER::new(
            template_engine => $template_engine,
            %args
        );

        # Set default SystemVerilog options
        $self->{options} = {
            reset_active_low => 1,
            state_encoding => 'auto', # auto, binary, onehot, gray
            use_enum => 1,
            %{$args{options} // {}}
        };

        return $self;
    }

    sub generate($self, $ast_module) {
        return $self->_generate_module($ast_module);
    }

    sub _generate_module($self, $module) {
        my $template = $self->template_engine();

        # Generate parameters
        my $parameters = '';
        my @param_list = keys $module->generics()->%*;
        if (@param_list) {
            $parameters = "#(\n";
            for my $i (0 .. $#param_list) {
                my $name = $param_list[$i];
                my $value = $module->generics()->{$name};
                $parameters .= $template->render('parameter',
                    name => $name,
                    value => $value
                );
                $parameters .= "," if $i < $#param_list;
                $parameters .= "\n";
            }
            $parameters .= ")\n";
        }

        # Generate ports
        my $ports = '';
        my @port_list = $module->ports()->@*;
        if (@port_list) {
            for my $i (0 .. $#port_list) {
                my $port = $port_list[$i];
                $ports .= $template->render('port',
                    direction => $template->format_direction($port->direction),
                    type => $template->format_type($port->port_type, $port->width),
                    name => $port->name
                );
                $ports .= "," if $i < $#port_list;
                $ports .= "\n";
            }
        }

        # Generate signals
        my $signals = '';
        for my $signal ($module->signals()->@*) {
            my $initial = '';
            if (defined $signal->initial_value) {
                $initial = ' = ' . $signal->initial_value;
            }
            
            $signals .= $template->render('signal',
                type => $template->format_type($signal->signal_type, $signal->width),
                name => $signal->name,
                initial => $initial
            ) . "\n";
        }

        # Generate state enum and current state signal
        my @states = $module->states()->@*;
        if (@states && $self->get_option('use_enum')) {
            $signals .= "    typedef enum logic [" . 
                        ($self->_calculate_state_bits(scalar @states) - 1) . 
                        ":0] {\n";
            
            for my $i (0 .. $#states) {
                $signals .= "        " . $template->format_state_name($states[$i]->name);
                $signals .= "," if $i < $#states;
                $signals .= "\n";
            }
            $signals .= "    } state_t;\n";
            $signals .= "    state_t current_state, next_state;\n";
        }

        # Generate logic
        my $logic = '';
        if (@states) {
            $logic = $self->_generate_fsm_logic($module);
        }

        return $template->render('module',
            module_name => $module->name,
            parameters => $parameters,
            ports => $ports,
            signals => $signals,
            logic => $logic
        );
    }

    sub _generate_fsm_logic($self, $module) {
        my $template = $self->template_engine();
        my @states = $module->states()->@*;

        # Find reset state and clock/reset signals
        my $reset_state = '';
        for my $state (@states) {
            if ($state->is_reset_state) {
                $reset_state = $template->format_state_name($state->name);
                last;
            }
        }
        $reset_state ||= $template->format_state_name($states[0]->name) if @states;

        # Get clock and reset from system or assume defaults
        my $system_contract = $module->system();
        my $clock = $system_contract->{clock} // 'clk';
        my $reset = $system_contract->{reset} // 'rst_n';
        my $reset_policy = $self->_reset_policy_from_system_contract($system_contract);

        # Generate reset assignments
        my $reset_assignments = "        current_state <= $reset_state;\n";

        # Generate state cases
        my $state_cases = '';
        for my $state (@states) {
            my $assignments = '';
            for my $assignment ($state->assignments()->@*) {
                if ($assignment->is_conditional) {
                    $assignments .= $template->render('conditional_assignment',
                        condition => $assignment->condition,
                        target => $assignment->target,
                        expression => $assignment->expression
                    ) . "\n";
                } else {
                    $assignments .= $template->render('assignment',
                        target => $assignment->target,
                        expression => $assignment->expression
                    ) . "\n";
                }
            }

            my $transitions = '';
            for my $transition ($state->transitions()->@*) {
                if ($transition->is_conditional) {
                    $transitions .= $template->render('transition',
                        condition => $transition->condition,
                        state_signal => 'current_state',
                        target_state => $template->format_state_name($transition->target_state)
                    ) . "\n";
                } else {
                    $transitions .= $template->render('default_transition',
                        state_signal => 'current_state',
                        target_state => $template->format_state_name($transition->target_state)
                    ) . "\n";
                }
            }

            $state_cases .= $template->render('state_case',
                state_name => $template->format_state_name($state->name),
                assignments => $assignments,
                transitions => $transitions
            );
        }

        return $template->render('always_ff',
            event_control => $self->_sequential_event_control($clock, $reset, $reset_policy),
            reset_condition => $self->_reset_condition_expr($reset, $reset_policy),
            reset_assignments => $reset_assignments,
            state_signal => 'current_state',
            state_cases => $state_cases,
            reset_state => $reset_state
        );
    }

    sub _reset_policy_from_system_contract($self, $system_contract) {
        $system_contract = {} unless ref($system_contract) eq 'HASH';

        my $reset_keyword = $system_contract->{reset_keyword} // '';
        my $reset_kind = $system_contract->{reset_kind}
            // ($reset_keyword eq 'sreset' ? 'sync' : 'async');
        my $reset_active_level = exists($system_contract->{reset_active_level})
            ? ($system_contract->{reset_active_level} ? 1 : 0)
            : ($reset_kind eq 'sync' ? 1 : 0);

        return {
            kind => $reset_kind,
            active_level => $reset_active_level,
            keyword => $reset_keyword,
        };
    }

    sub _sequential_event_control($self, $clock_name, $reset_name, $reset_policy) {
        return "posedge $clock_name"
            if (($reset_policy->{kind} || '') eq 'sync');

        my $reset_edge = ($reset_policy->{active_level} || 0) ? 'posedge' : 'negedge';
        return "posedge $clock_name or $reset_edge $reset_name";
    }

    sub _reset_condition_expr($self, $reset_name, $reset_policy) {
        return ($reset_policy->{active_level} || 0) ? $reset_name : "!$reset_name";
    }

    sub _calculate_state_bits($self, $num_states) {
        return 1 if $num_states <= 1;
        my $bits = 1;
        while ((2 ** $bits) < $num_states) {
            $bits++;
        }
        return $bits;
    }
}

# Backend factory
sub create_backend($target, %options) {
    if ($target eq 'vhdl') {
        return FSM::Backend::VHDL->new(options => \%options);
    } elsif ($target eq 'systemverilog' || $target eq 'sv') {
        return FSM::Backend::SystemVerilog->new(options => \%options);
    } else {
        croak "Unknown backend target: $target";
    }
}

1;

__END__

=head1 NAME

FSM::Backend - Code generation backends for FSM designs

=head1 SYNOPSIS

    use FSM::Backend;
    
    my $backend = FSM::Backend::create_backend('vhdl', 
        state_encoding => 'onehot'
    );
    my $code = $backend->generate($ast_module);

=head1 DESCRIPTION

This module provides code generation backends for FSM designs, supporting VHDL 
and SystemVerilog targets with modern Perl 5.20+ features.

=head1 AUTHOR

FSMGen Team

=cut
