package FSM::Test::DiagnosticCause;

use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(diagnostic_cause_matches);

# Compare the complete cause. Both stack frames and the primary message can
# contain caller-controlled text that happens to include a wanted substring.
sub diagnostic_cause_matches {
    my ($error, $expected) = @_;
    return 0 if !defined($error) || !defined($expected)
        || ref($error) || ref($expected) || !length($expected);
    my ($cause) = split /\n/, $error;
    return defined($cause) && $cause eq $expected ? 1 : 0;
}

1;
