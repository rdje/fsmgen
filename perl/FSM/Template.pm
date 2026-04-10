package FSM::Template;

use v5.20;
use strict;
use warnings;

use Carp;
use Exporter 'import';

our $VERSION = '2.0';
our @EXPORT_OK = qw(create_template_engine);

sub create_template_engine {
    my ($target) = @_;
    
    if ($target eq 'vhdl') {
        return FSM::Template::VHDL->new();
    } elsif ($target eq 'systemverilog' || $target eq 'sv') {
        return FSM::Template::SystemVerilog->new();
    } else {
        croak "Unknown template target: $target";
    }
}

1;

# Base template engine
package FSM::Template::Engine;

use v5.20;
use strict;
use warnings;
use Carp;

sub new {
    my ($class, %args) = @_;
    my $self = {
        templates => {},
        variables => {},
    };
    return bless $self, $class;
}

sub register_template {
    my ($self, $name, $template) = @_;
    $self->{templates}{$name} = $template;
}

sub set_variable {
    my ($self, $name, $value) = @_;
    $self->{variables}{$name} = $value;
}

sub render {
    my ($self, $template_name, %vars) = @_;
    my $template = $self->{templates}{$template_name}
        or croak "Template '$template_name' not found";

    # Merge instance variables with passed variables
    my %all_vars = (%{$self->{variables}}, %vars);

    # Simple template substitution - replace {{variable}} patterns
    my $result = $template;
    while ($result =~ /\{\{(\w+)\}\}/) {
        my $var_name = $1;
        my $value = $all_vars{$var_name} // '';
        $result =~ s/\{\{$var_name\}\}/$value/g;
    }

    return $result;
}

1;

# VHDL-specific template engine
package FSM::Template::VHDL;

use v5.20;
use strict;
use warnings;
use Carp;

our @ISA = qw(FSM::Template::Engine);

sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);
    $self->_register_vhdl_templates();
    return $self;
}

sub _register_vhdl_templates {
    my ($self) = @_;
    
    $self->register_template('entity', q{library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity {{entity_name}} is
{{generics}}{{ports}}end entity {{entity_name}};
});

    $self->register_template('architecture', q{architecture rtl of {{entity_name}} is
{{signals}}
begin
{{processes}}
end architecture rtl;
});

    $self->register_template('port', q{    {{name}} : {{direction}} {{type}}});
    $self->register_template('signal', q{    signal {{name}} : {{type}};});

    $self->register_template('fsm_process', q{fsm_proc: process(clk, rstn)
begin
    if rstn = '0' then
        {{reset_assignments}}
    elsif rising_edge(clk) then
        case {{state_signal}} is
{{state_cases}}            when others =>
                {{state_signal}} <= {{reset_state}};
        end case;
    end if;
end process fsm_proc;
});

    $self->register_template('state_case', q{            when {{state_name}} =>
{{assignments}}{{transitions}}});

    $self->register_template('assignment', q{                {{target}} <= {{expression}};});
    $self->register_template('transition', q{                if {{condition}} then
                    {{state_signal}} <= {{target_state}};
                end if;});
}

sub format_type {
    my ($self, $type, $width) = @_;
    $width ||= 1;
    
    if ($width == 1) {
        return 'std_logic';
    } else {
        return "std_logic_vector(" . ($width - 1) . " downto 0)";
    }
}

sub format_direction {
    my ($self, $direction) = @_;
    return lc $direction;
}

sub format_state_name {
    my ($self, $name) = @_;
    return uc $name;
}

1;

# SystemVerilog-specific template engine  
package FSM::Template::SystemVerilog;

use v5.20;
use strict;
use warnings;
use Carp;

our @ISA = qw(FSM::Template::Engine);

sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);
    $self->_register_systemverilog_templates();
    return $self;
}

sub _register_systemverilog_templates {
    my ($self) = @_;
    
    $self->register_template('module', q{module {{module_name}}{{parameters}}
(
{{ports}}
);
{{signals}}
{{logic}}
endmodule
});

    $self->register_template('port', q{    {{direction}} {{type}} {{name}}});
    $self->register_template('signal', q{    {{type}} {{name}};});

    $self->register_template('always_ff', q{always_ff @({{event_control}}) begin
    if ({{reset_condition}}) begin
        {{reset_assignments}}
    end else begin
        case ({{state_signal}})
{{state_cases}}            default:
                {{state_signal}} <= {{reset_state}};
        endcase
    end
end
});

    $self->register_template('state_case', q{            {{state_name}}: begin
{{assignments}}{{transitions}}            end
});

    $self->register_template('assignment', q{                {{target}} <= {{expression}};});
    $self->register_template('transition', q{                if ({{condition}})
                    {{state_signal}} <= {{target_state}};});
}

sub format_type {
    my ($self, $type, $width) = @_;
    $width ||= 1;
    
    if ($width == 1) {
        return 'logic';
    } else {
        return "logic [" . ($width - 1) . ":0]";
    }
}

sub format_direction {
    my ($self, $direction) = @_;
    return lc $direction;
}

sub format_state_name {
    my ($self, $name) = @_;
    return uc $name;
}

1;

__END__

=head1 NAME

FSM::Template - Template engine for FSM code generation

=head1 SYNOPSIS

    use FSM::Template;
    
    my $engine = FSM::Template::create_template_engine('vhdl');
    $engine->set_variable('entity_name', 'my_fsm');
    my $code = $engine->render('entity', ports => 'port definitions...');

=head1 DESCRIPTION

This module provides template engines for generating HDL code from FSM designs,
supporting VHDL and SystemVerilog targets with modern Perl 5.20+ features.

=head1 AUTHOR

FSMGen Team

=cut
