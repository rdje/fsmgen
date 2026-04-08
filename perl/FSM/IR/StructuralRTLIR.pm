package FSM::IR::StructuralRTLIR;

=head1 NAME

FSM::IR::StructuralRTLIR - Explicit forward structural RTL connectivity summary

=head1 DESCRIPTION

Represents the netlist-like structural layer in the forward compiler. This
package owns explicit ports, nets, instances, declared links, resolved links,
auxiliary assignments, and the current typed actual-connection summaries that
the backend emitter and composition reporting surfaces consume.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed);
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

sub port_metadata ($self) {
    my (@inputs, @outputs, @multi_bit, @single_bit);
    my %signals;
    my @signal_names;

    for my $port (@{$self->ports || []}) {
        next unless ref($port) eq 'HASH';

        my $entry = {
            name => $port->{name},
            width => $port->{width},
            direction => $port->{direction},
            signed => ($port->{signed} // 0) ? 1 : 0,
        };

        push @signal_names, $port->{name};
        $signals{$port->{name}} = {
            width => $port->{width},
            direction => $port->{direction},
            signed => ($port->{signed} // 0) ? 1 : 0,
        };

        if (($port->{direction} || '') eq 'output') {
            push @outputs, _clone($entry);
        } else {
            push @inputs, _clone($entry);
        }

        if (($port->{width} || 0) > 1) {
            push @multi_bit, _clone($entry);
        } else {
            push @single_bit, _clone($entry);
        }
    }

    return {
        signals => \%signals,
        signal_names => \@signal_names,
        signal_analysis => {
            inputs => \@inputs,
            outputs => \@outputs,
            multi_bit => \@multi_bit,
            single_bit => \@single_bit,
        },
    };
}

sub port_metadata_from_input ($class, $structural_rtl_ir) {
    my $port_metadata = (
        blessed($structural_rtl_ir) && $structural_rtl_ir->can('port_metadata')
            ? $structural_rtl_ir->port_metadata
            : ref($structural_rtl_ir) eq 'HASH' && ref($structural_rtl_ir->{ports}) eq 'ARRAY'
                ? do {
                    my $object = $class->new(
                        module_name => ($structural_rtl_ir->{module_name} // '__anonymous__'),
                        source_root_kind => ($structural_rtl_ir->{source_root_kind} // 'fsm'),
                        target_language => ($structural_rtl_ir->{target_language} // 'systemverilog'),
                        ports => $structural_rtl_ir->{ports},
                    );
                    $object->port_metadata;
                }
                : undef
    );

    return {
        signals => {},
        signal_names => [],
        signal_analysis => {
            inputs => [],
            outputs => [],
            multi_bit => [],
            single_bit => [],
        },
    } unless ref($port_metadata) eq 'HASH';

    return _clone($port_metadata);
}

sub top_port ($self, $port_name) {
    return undef unless defined($port_name) && length($port_name);

    my ($port) = grep {
        ((($_->{name}) || '') eq $port_name)
    } @{$self->ports || []};

    return _clone($port);
}

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

sub resolved_links_touching ($self, $endpoint, $origin_kind = undef) {
    return [] unless defined($endpoint) && length($endpoint);

    my @links = grep {
        my $origin_matches = !defined($origin_kind) || !length($origin_kind)
            || ((($_->{origin_kind}) || '') eq $origin_kind);
        $origin_matches
            && (
                ((($_->{source}) || '') eq $endpoint)
                || ((($_->{target}) || '') eq $endpoint)
            )
    } @{$self->resolved_links || []};

    return _clone(\@links);
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

=head1 METHODS

=head2 new

Constructs a new structural RTL IR object and clones the supplied structural
payload.

=head2 module_name

Returns the structural module name.

=head2 source_root_kind

Returns the authored root kind that produced this structural layer.

=head2 target_language

Returns the active backend target language attached to the structural layer.

=head2 ports

Returns the explicit structural top-port list.

=head2 nets

Returns the explicit structural internal net list.

=head2 instances

Returns the explicit structural realized instance list.

=head2 declared_links

Returns the explicit structural declared top-link list.

=head2 resolved_links

Returns the explicit structural resolved connectivity list.

=head2 auxiliary_assignments

Returns the explicit structural auxiliary assignment list.

=head2 port_metadata

Builds the normalized top-port metadata projection used by intent, module-info,
and reporting surfaces.

=head2 port_metadata_from_input

Extracts normalized top-port metadata from a structural object or
structural-style hash payload.

=head2 top_port

Returns one structural top-port entry by name.

=head2 interface_endpoint

Returns the structural child-interface endpoint metadata for one
C<instance.port> endpoint string.

=head2 interface_signal_endpoint_groups

Returns structural child-interface endpoints grouped by signal name, optionally
filtered by direction.

=head2 interface_signal_endpoints

Returns structural child-interface endpoints for one signal name, optionally
filtered by direction.

=head2 resolved_links_touching

Returns the structural resolved links that touch one endpoint, optionally
filtered by origin kind.

=head2 as_hashref

Serializes the structural layer into the exported hash shape used by the
backend emitter, pipeline, and embedding surfaces.

=head2 _clone

Recursively clones nested hashes and arrays used by the structural layer.

=cut
