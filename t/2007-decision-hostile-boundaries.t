use strict;
use warnings;
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;

my $result = FSM::Test::SourceQueryRunner::_capture([
    'python3', '-B', '-m', 'unittest', 'discover', '-s', 't/python',
    '-p', 'test_decision_hostile_boundaries.py'], '');
is($result->{exit_code}, 0, 'actual malformed store, authority, caller and bounded IPC controls pass')
    or diag($result->{stdout} . $result->{stderr});
like($result->{stdout} . $result->{stderr}, qr/^OK$/m, 'Python controls completed');
done_testing;
