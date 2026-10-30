package FSM::Package::ExpressionOperatorSupport;

use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(is_reduction_operator is_shift_operator);

# This classification applies in unary position. The same tokens retain their
# existing vector semantics in binary expressions.
sub is_reduction_operator {
    my ($operator) = @_;
    return defined($operator) && !ref($operator)
        && $operator =~ /\A[&|^]\z/ ? 1 : 0;
}

sub is_shift_operator {
    my ($operator) = @_;
    return defined($operator) && !ref($operator)
        && $operator =~ /\A(?:<<|>>|<<<|>>>|shl|shr|sal|sar)\z/ ? 1 : 0;
}

1;

=head1 NAME

FSM::Package::ExpressionOperatorSupport - Shared expression operator classification

=head1 FUNCTIONS

=head2 is_reduction_operator

Classify C<&>, C<|> and C<^> in unary position. Their binary vector meaning is
separate. Undefined, reference-valued and unrecognized inputs return false.

=head2 is_shift_operator

Classify the canonical binary shifts C<< << >>, C<< >> >>, C<< <<< >> and
C<< >>> >> and their existing C<shl>, C<shr>, C<sal> and C<sar> aliases.
Width consumers use this family to preserve the left operand's result width
independently of the amount width. Classification alone supplies no operand
legality, signedness, source admission or generic target proof. Undefined,
reference-valued and unrecognized inputs return false.

=cut
