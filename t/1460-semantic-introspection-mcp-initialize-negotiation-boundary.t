#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Spec;
use FindBin;
use JSON::PP;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SemanticIntrospectionMCPAdapter;

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(
    repo_root => $repo_root,
    workspace_root => $repo_root,
);

subtest 'initialize reports the single supported MCP protocol version' => sub {
    for my $case (
        [{ protocolVersion => '2025-06-18' }, 'requested supported version is echoed'],
        [{ protocolVersion => 'test-protocol' }, 'unsupported requested version is replaced'],
        [{}, 'missing requested version uses supported version'],
    ) {
        my ($params, $label) = @{$case};
        my $result = $adapter->initialize_result($params);
        is($result->{protocolVersion}, '2025-06-18', $label);
    }
};

subtest 'client capabilities do not widen server capabilities' => sub {
    my $result = $adapter->initialize_result({
        protocolVersion => '2025-06-18',
        capabilities => {
            roots => { listChanged => JSON::PP::true },
            sampling => {},
            elicitation => {},
            experimental => { anything => JSON::PP::true },
        },
    });

    is_deeply(
        [sort keys %{$result->{capabilities}}],
        [qw(resources tools)],
        'server advertises only shipped resources/tools capabilities',
    );
    ok(!$result->{capabilities}{resources}{listChanged}, 'resources listChanged stays false');
    ok(!$result->{capabilities}{tools}{listChanged}, 'tools listChanged stays false');
    ok(!exists $result->{capabilities}{prompts}, 'prompts remain unadvertised');
    ok(!exists $result->{capabilities}{logging}, 'logging remains unadvertised');
    ok(!exists $result->{capabilities}{completions}, 'completions remain unadvertised');
    ok(!exists $result->{capabilities}{sampling}, 'sampling remains unadvertised');
    ok(!exists $result->{capabilities}{elicitation}, 'elicitation remains unadvertised');
    ok(!exists $result->{capabilities}{roots}, 'client roots do not become server capabilities');
};

done_testing();
