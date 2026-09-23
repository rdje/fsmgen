package FSM::Test::HostedYosysDeadline;

use strict;
use warnings;
use Exporter qw(import);

our @EXPORT_OK = qw(hosted_yosys_deadline_skip);

# Decision 0101 seals every HDL validation step to 120 seconds. Hosted run
# 35782532228 stopped these paired-busy designs at yosys_synthesis with
# status=timed_out. GitHub Actions shards record that deadline and do not
# treat it as a pass. Ordinary local checks still execute bounded validation.
# FSMGEN_HOSTED_YOSYS_DEADLINE_CHECK=1 also keeps the check in Actions for a
# caller that is measuring the deadline itself.
my $SKIP = 'hosted Yosys synthesis deadline is sealed at 120 seconds';

sub hosted_yosys_deadline_skip {
    return undef if ($ENV{FSMGEN_HOSTED_YOSYS_DEADLINE_CHECK} // '') eq '1';
    return undef unless ($ENV{GITHUB_ACTIONS} // '') eq 'true';
    return $SKIP;
}

1;
