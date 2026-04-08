package FSM::Package::DeclarativeScalarTypeSupport;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Package::DeclarativeTypeSupport;

sub canonicalize_type_spec ($class, %args) {
    return FSM::Package::DeclarativeTypeSupport->canonicalize_type_spec(%args);
}

1;
