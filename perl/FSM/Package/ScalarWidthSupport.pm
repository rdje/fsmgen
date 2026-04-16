package FSM::Package::ScalarWidthSupport;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Package::IntegerLiteralSupport;

sub positive_integer_from_literal_like ($class, $literal_like) {
    return FSM::Package::IntegerLiteralSupport->positive_integer_from_literal_like($literal_like);
}

1;
