package FSM::Package::ExpressionOperatorSupport;

use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(is_reduction_operator);

# This classification applies in unary position. The same tokens retain their
# existing vector semantics in binary expressions.
sub is_reduction_operator {
    my ($operator) = @_;
    return defined($operator) && !ref($operator)
        && $operator =~ /\A[&|^]\z/ ? 1 : 0;
}

1;
