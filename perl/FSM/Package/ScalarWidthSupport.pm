package FSM::Package::ScalarWidthSupport;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Package::IntegerLiteralSupport;

sub positive_integer_from_literal_like ($class, $literal_like, $decimal_ref = undef) {
    return FSM::Package::IntegerLiteralSupport->positive_integer_from_literal_like($literal_like, $decimal_ref);
}

1;

=head1 NAME

FSM::Package::ScalarWidthSupport - Shared scalar width literal projection

=head2 positive_integer_from_literal_like($value, $decimal_ref = undef)

Delegates positive integer parsing and optional exact decimal output to
FSM::Package::IntegerLiteralSupport. The native numeric return is unchanged;
the optional scalar output reference is cleared on refusal.

=cut
