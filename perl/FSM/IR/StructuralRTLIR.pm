package FSM::IR::StructuralRTLIR;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

sub new ($class, %args) {
    confess "FSM::IR::StructuralRTLIR requires 'module_name'"
        unless defined($args{module_name}) && $args{module_name} ne '';

    return bless {
        module_name => $args{module_name},
        source_root_kind => $args{source_root_kind} // 'fsm',
        target_language => $args{target_language} // 'systemverilog',
        ports => _clone($args{ports} || []),
        nets => _clone($args{nets} || []),
        instances => _clone($args{instances} || []),
        auxiliary_assignments => _clone($args{auxiliary_assignments} || []),
    }, $class;
}

sub module_name ($self) { return $self->{module_name} }
sub source_root_kind ($self) { return $self->{source_root_kind} }
sub target_language ($self) { return $self->{target_language} }
sub ports ($self) { return $self->{ports} }
sub nets ($self) { return $self->{nets} }
sub instances ($self) { return $self->{instances} }
sub auxiliary_assignments ($self) { return $self->{auxiliary_assignments} }

sub as_hashref ($self) {
    my $ports = _clone($self->ports || []);
    my $nets = _clone($self->nets || []);
    my $instances = _clone($self->instances || []);
    my $auxiliary_assignments = _clone($self->auxiliary_assignments || []);

    return {
        module_name => $self->module_name,
        source_root_kind => $self->source_root_kind,
        target_language => $self->target_language,
        port_count => scalar(@$ports),
        ports => $ports,
        net_count => scalar(@$nets),
        nets => $nets,
        instance_count => scalar(@$instances),
        instances => $instances,
        auxiliary_assignment_count => scalar(@$auxiliary_assignments),
        auxiliary_assignments => $auxiliary_assignments,
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

__END__

=head1 NAME

FSM::IR::StructuralRTLIR - Explicit forward structural RTL connectivity summary

=head1 DESCRIPTION

This module provides the first extracted forward structural RTL/connectivity layer
used by the active `.fsm` to HDL pipeline. It is currently bounded to composition
tops and captures explicit ports, nets, instances, pin bindings, and auxiliary
assignments so backend emission can begin walking one explicit structural graph
instead of rediscovering wiring shape ad hoc from mixed plan/emitter state.

=cut
