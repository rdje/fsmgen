package FSM::TestExtension::BadNew;

use v5.20;
use strict;
use warnings;

sub new {
    die "BadNew test extension forced constructor failure\n";
}

1;
