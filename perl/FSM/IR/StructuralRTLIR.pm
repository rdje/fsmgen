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
        declared_links => _clone($args{declared_links} || []),
        resolved_links => _clone($args{resolved_links} || []),
        auxiliary_assignments => _clone($args{auxiliary_assignments} || []),
    }, $class;
}

sub module_name ($self) { return $self->{module_name} }
sub source_root_kind ($self) { return $self->{source_root_kind} }
sub target_language ($self) { return $self->{target_language} }
sub ports ($self) { return $self->{ports} }
sub nets ($self) { return $self->{nets} }
sub instances ($self) { return $self->{instances} }
sub declared_links ($self) { return $self->{declared_links} }
sub resolved_links ($self) { return $self->{resolved_links} }
sub auxiliary_assignments ($self) { return $self->{auxiliary_assignments} }

sub interface_endpoint ($self, $endpoint) {
    return undef unless defined($endpoint) && length($endpoint);

    my ($instance_name, $port_name) = $endpoint =~ /^(\w+)\.(\w+)$/;
    return undef unless defined $port_name;

    for my $instance (@{$self->instances || []}) {
        next unless (($instance->{instance_name} || '') eq $instance_name);

        my ($port) = grep {
            ((($_->{name}) || '') eq $port_name)
        } @{$instance->{interface_ports} || []};

        return {
            endpoint => $endpoint,
            instance_name => $instance_name,
            port_name => $port_name,
            instance => _clone($instance),
            port => _clone($port),
        };
    }

    return undef;
}

sub interface_signal_endpoint_groups ($self, $direction = undef) {
    my %groups;

    for my $instance (@{$self->instances || []}) {
        for my $port (@{$instance->{interface_ports} || []}) {
            next if defined($direction) && length($direction) && (($port->{direction} || '') ne $direction);
            my $signal_name = $port->{name} || next;
            push @{$groups{$signal_name}}, {
                endpoint => (($instance->{instance_name} || 'unknown') . '.' . $signal_name),
                instance_name => $instance->{instance_name},
                port_name => $signal_name,
                instance => _clone($instance),
                port => _clone($port),
            };
        }
    }

    return _clone(\%groups);
}

sub interface_signal_endpoints ($self, $signal_name, $direction = undef) {
    return [] unless defined($signal_name) && length($signal_name);
    my $groups = $self->interface_signal_endpoint_groups($direction);
    return _clone($groups->{$signal_name} || []);
}

sub as_hashref ($self) {
    my $ports = _clone($self->ports || []);
    my $nets = _clone($self->nets || []);
    my $instances = _clone($self->instances || []);
    my $declared_links = _clone($self->declared_links || []);
    my $resolved_links = _clone($self->resolved_links || []);
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
        declared_link_count => scalar(@$declared_links),
        declared_links => $declared_links,
        resolved_link_count => scalar(@$resolved_links),
        resolved_links => $resolved_links,
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
used by the active `.fsm` to HDL pipeline. It currently has two bounded shapes:
composition tops carry explicit ports, nets, instances, pin bindings, resolved
links, declared links, and auxiliary assignments; direct generated roots carry an explicit
module-interface boundary slice with ports plus empty nets/instances/resolved
links/declared-links/auxiliary structure. Pin bindings now also preserve a first
typed `connection_expr` node for the actual connection expression, currently
bounded to `signal_ref`. That lets backend and export work begin walking one
explicit structural graph instead of rediscovering wiring shape ad hoc from mixed
plan/emitter state.

=cut
