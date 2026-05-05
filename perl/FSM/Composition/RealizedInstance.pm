package FSM::Composition::RealizedInstance;

=head1 NAME

FSM::Composition::RealizedInstance - Runtime carrier for one realized composition child

=head1 DESCRIPTION

Represents one realized composition child together with its interface metadata,
bindings, generated module information, and HDL payload. The constructor also
normalizes stored structural bindings so later planning and emission code sees a
stable binding shape.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';
use Scalar::Util qw(blessed);
use FSM::IR::StructuralRTLIR::ConnectionExpr qw(normalized_binding);

sub new ($class, %args) {
    return bless {
        kind => $args{kind},
        instance_name => $args{instance_name},
        module_name => $args{module_name},
        source_name => $args{source_name},
        interface_ports => _clone_interface_ports($args{interface_ports} || []),
        port_bindings => _normalize_port_bindings($args{port_bindings} || []),
        parameter_overrides => _clone($args{parameter_overrides} || []),
        module_info => _clone($args{module_info}),
        hdl_code => $args{hdl_code},
    }, $class;
}

sub kind ($self) { return $self->{kind} }
sub instance_name ($self) { return $self->{instance_name} }
sub module_name ($self) { return $self->{module_name} }
sub source_name ($self) { return $self->{source_name} }
sub interface_ports ($self) { return _clone_interface_ports($self->{interface_ports}) }
sub port_bindings ($self) { return _clone($self->{port_bindings}) }
sub parameter_overrides ($self) { return _clone($self->{parameter_overrides}) }
sub module_info ($self) { return _clone($self->{module_info}) }
sub hdl_code ($self) { return $self->{hdl_code} }

sub _normalize_port_bindings ($bindings) {
    return [] unless ref($bindings) eq 'ARRAY';
    return [ map { normalized_binding($_) } @$bindings ];
}

sub _clone_interface_ports ($ports) {
    return [] unless ref($ports) eq 'ARRAY';
    return [ map { _clone_interface_port($_) } @$ports ];
}

sub _clone_interface_port ($port) {
    return _clone($port)
        unless blessed($port)
            && $port->can('name')
            && $port->can('direction')
            && $port->can('width')
            && $port->can('new');

    my $class = ref($port);
    return $class->new(
        name => $port->name,
        direction => $port->direction,
        width => $port->width,
        width_token => ($port->can('width_token') ? $port->width_token : undef),
        signed => ($port->can('signed') ? $port->signed : undef),
        state_model => ($port->can('state_model') ? $port->state_model : undef),
        declared_type_name => ($port->can('declared_type_name') ? $port->declared_type_name : undef),
        declared_type_spec => ($port->can('declared_type_spec') ? $port->declared_type_spec : undef),
        type => ($port->can('type') ? $port->type : undef),
        binding_mode => ($port->can('binding_mode') ? $port->binding_mode : undef),
        raw_token => ($port->can('raw_token') ? $port->raw_token : undef),
        origin_kind => ($port->can('origin_kind') ? $port->origin_kind : undef),
    );
}

sub _clone ($value) {
    return undef unless defined $value;
    if (ref($value) eq 'HASH') {
        return { map { $_ => _clone($value->{$_}) } keys %$value };
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

Constructs a realized child instance record and normalizes any supplied
structural port bindings.

=head2 kind

Returns the realized child kind, such as C<?fsmc>, C<?dtc>, or C<?rtl>.

=head2 instance_name

Returns the realized instance name used inside the composition plan.

=head2 module_name

Returns the generated or imported module name for the realized child.

=head2 source_name

Returns the source-level child name or external source reference.

=head2 interface_ports

Returns the normalized realized child interface port list.

=head2 port_bindings

Returns the normalized structural binding list currently attached to the child.

=head2 parameter_overrides

Returns the validated parameter/generic override list attached to this realized
child instance.

=head2 module_info

Returns the generated child module metadata hash, when one exists.

=head2 hdl_code

Returns the realized HDL text payload associated with the child, when one
exists.

=head2 _normalize_port_bindings

Clones and normalizes an array of structural bindings into the stored runtime
shape used by realized children.

=head2 _clone_interface_ports

Clones the realized child interface port list, including fresh
C<FSM::Composition::Port> objects for the normal port-object payload.

=cut
