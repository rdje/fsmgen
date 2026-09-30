use strict;
use warnings;
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;

my $result = FSM::Test::SourceQueryRunner::_capture([
    'python3', '-B', '-m', 'unittest', 'discover', '-s', 't/python',
    '-p', 'test_decision_reader_snapshots.py'], '');
is($result->{exit_code}, 0, 'published selected reader and atomic continuity controls pass')
    or diag($result->{stdout} . $result->{stderr});
like($result->{stdout} . $result->{stderr}, qr/^OK$/m, 'Python controls completed');
done_testing;
