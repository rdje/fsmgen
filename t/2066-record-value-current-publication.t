use strict;
use warnings;
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;

my $result = FSM::Test::SourceQueryRunner::_capture([
    'python3', '-B', '-m', 'unittest', 'discover', '-s', 't/python',
    '-p', 'test_record_value_current_publication.py'], '');
is($result->{exit_code}, 0, 'current publication preserves target custody and permits qualified unrelated progress')
    or diag($result->{stdout} . $result->{stderr});
like($result->{stdout} . $result->{stderr}, qr/^OK$/m, 'current source, query, scope and kind controls completed');
done_testing;
