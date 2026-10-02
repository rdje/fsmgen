package FSM::Test::ConstructorCauseSubstring;
use strict;
use warnings;
use FSM::Test::DiagnosticCause ();
no warnings 'redefine';
*FSM::Test::DiagnosticCause::diagnostic_cause_matches = sub {
    my ($error, $expected) = @_;
    return ($error // '') =~ /\Q$expected\E/ ? 1 : 0;
};
1;
