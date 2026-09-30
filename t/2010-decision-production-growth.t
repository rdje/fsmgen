use strict;
use warnings;
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;

my $result = FSM::Test::SourceQueryRunner::_capture([
    'python3', '-B', '-m', 'unittest', 'discover', '-s', 't/python',
    '-p', 'test_decision_production_growth.py'], '');
is($result->{exit_code}, 0, 'actual production-cohort birth, installed pins and unchanged capacity pass every mode')
    or diag($result->{stdout} . $result->{stderr});
like($result->{stdout} . $result->{stderr}, qr/^OK$/m, 'Python growth controls completed');
note($result->{stdout}) if $result->{exit_code} == 0;
done_testing;
