package FSM::Composition::AggregatePathSupport;

=head1 NAME

FSM::Composition::AggregatePathSupport - Composition aggregate path lowering

=head1 DESCRIPTION

Wraps the shared package-level aggregate path resolver and folds resolved path
segments onto structural connection expressions for composition planning and
reporting.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::IR::StructuralRTLIR::ConnectionExpr qw(
    bit_select_expr
    member_access_expr
    slice_expr
);
use FSM::Package::AggregatePathSupport;

sub resolve ($class, %args) {
    my $result = FSM::Package::AggregatePathSupport->resolve(
        root_type_spec => $args{root_type_spec},
        path_text => $args{path_text},
    );
    return $result unless $result->{ok};

    my $connection_expr = $args{base_expr};
    if (defined $connection_expr) {
        for my $segment (@{ $result->{path_segments} || [] }) {
            my $kind = $segment->{kind} || '';
            if ($kind eq 'member') {
                $connection_expr = member_access_expr($connection_expr, $segment->{name});
                next;
            }
            if ($kind eq 'item') {
                $connection_expr = member_access_expr($connection_expr, 'item_'.$segment->{index});
                next;
            }
            if ($kind eq 'bit_index') {
                $connection_expr = bit_select_expr($connection_expr, $segment->{index});
                next;
            }
            if ($kind eq 'bit_slice') {
                $connection_expr = slice_expr($connection_expr, $segment->{high}, $segment->{low});
                next;
            }
            return {
                ok => 0,
                code => 'unsupported_path_segment',
                segment_kind => $kind,
            };
        }
    }

    return {
        %$result,
        connection_expr => $connection_expr,
    };
}

sub resolve_type_path ($class, %args) {
    return FSM::Package::AggregatePathSupport->resolve_type_path(%args);
}

sub clone_structured_value ($class, $value) {
    return FSM::Package::AggregatePathSupport->clone_structured_value($value);
}

1;

__END__

=head1 METHODS

=head2 resolve

Resolves one authored aggregate path through the package-level resolver and
optionally folds the resulting path segments onto a structural connection
expression.

=head2 resolve_type_path

Returns only the resolved leaf type spec and width, or C<(undef, undef)> when
the path cannot be resolved.

=head2 clone_structured_value

Clones a nested scalar/list/record type-spec structure.

=cut
