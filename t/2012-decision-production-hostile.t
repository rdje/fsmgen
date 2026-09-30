use strict;
use warnings;
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;

my $result = FSM::Test::SourceQueryRunner::_capture([
    'python3', '-B', '-m', 'unittest', 'discover', '-s', 't/python',
    '-p', 'test_decision_production_hostile.py'], '');
is($result->{exit_code}, 0, 'complete production alias/index/body controls refuse every selected mode')
    or diag($result->{stdout} . $result->{stderr});
like($result->{stdout} . $result->{stderr}, qr/^OK$/m, 'Python hostile qualification completed');
note($result->{stdout}) if $result->{exit_code} == 0;
done_testing;
