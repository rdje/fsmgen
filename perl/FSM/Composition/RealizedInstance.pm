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
use FSM::IR::StructuralRTLIR::ConnectionExpr qw(normalized_binding);

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
    return [ map { normalized_binding($_) } @$bindings ];
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

=head2 module_info

Returns the generated child module metadata hash, when one exists.

=head2 hdl_code

Returns the realized HDL text payload associated with the child, when one
exists.

=head2 _normalize_port_bindings

Clones and normalizes an array of structural bindings into the stored runtime
shape used by realized children.

=cut
