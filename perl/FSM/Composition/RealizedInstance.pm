package FSM::Composition::RealizedInstance;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';
use FSM::IR::StructuralRTLIR::ConnectionExpr qw(signal_ref_expr expr_signal_name);

sub new ($class, %args) {
    return bless {
        kind => $args{kind},
        instance_name => $args{instance_name},
        module_name => $args{module_name},
        source_name => $args{source_name},
        interface_ports => $args{interface_ports} || [],
        port_bindings => _normalize_port_bindings($args{port_bindings} || []),
        module_info => $args{module_info},
        hdl_code => $args{hdl_code},
    }, $class;
}

sub kind ($self) { return $self->{kind} }
sub instance_name ($self) { return $self->{instance_name} }
sub module_name ($self) { return $self->{module_name} }
sub source_name ($self) { return $self->{source_name} }
sub interface_ports ($self) { return $self->{interface_ports} }
sub port_bindings ($self) { return $self->{port_bindings} }
sub module_info ($self) { return $self->{module_info} }
sub hdl_code ($self) { return $self->{hdl_code} }

sub _normalize_port_bindings ($bindings) {
    return [] unless ref($bindings) eq 'ARRAY';
    return [ map { _normalize_port_binding($_) } @$bindings ];
}

sub _normalize_port_binding ($binding) {
    confess "RealizedInstance port bindings must be hash entries"
        unless ref($binding) eq 'HASH';

    my $port_name = $binding->{port_name};
    my $signal_name = $binding->{signal_name};
    my $connection_expr = _clone($binding->{connection_expr});

    if (!defined($signal_name) || !length($signal_name)) {
        $signal_name = expr_signal_name($connection_expr);
    }

    if ((!ref($connection_expr) || ref($connection_expr) ne 'HASH')
        && defined($signal_name) && length($signal_name))
    {
        $connection_expr = signal_ref_expr($signal_name);
    }

    return {
        port_name => $port_name,
        signal_name => $signal_name,
        connection_expr => $connection_expr,
    };
}

sub _clone ($value) {
    return undef unless defined $value;

    if (ref($value) eq 'HASH') {
        return {
            map { $_ => _clone($value->{$_}) } sort keys %$value
        };
    }

    if (ref($value) eq 'ARRAY') {
        return [ map { _clone($_) } @$value ];
    }

    return $value;
}

1;
