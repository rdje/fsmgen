#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SemanticIntrospectionMCPAdapter;

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $adapter = FSM::Support::SemanticIntrospectionMCPAdapter->new(
    repo_root => $repo_root,
    workspace_root => $repo_root,
);

subtest 'serverInfo exposes stable identity and display title' => sub {
    my $result = $adapter->initialize_result({ protocolVersion => '2025-06-18' });
    is($result->{serverInfo}{name}, 'fsmgen-semantic-introspection', 'server name is stable');
    is($result->{serverInfo}{title}, 'FSMGen Semantic Introspection', 'server title is stable');
    ok(length($result->{serverInfo}{version} || ''), 'server version remains present');
};

subtest 'instructions stay compact and do not advertise unshipped authority' => sub {
    my $result = $adapter->initialize_result({ protocolVersion => '2025-06-18' });
    my $instructions = $result->{instructions};

    like($instructions, qr/Read-only/, 'instructions advertise read-only profile');
    like($instructions, qr/semantic introspection/, 'instructions name semantic introspection');
    unlike($instructions, qr/\b(?:write|generation|shell|network|commit|push)\b/i, 'instructions do not advertise blocked authority');
    unlike($instructions, qr/\b(?:prompts|logging|sampling|elicitation|completion|roots|subscribe)\b/i, 'instructions do not advertise unshipped optional MCP features');
    cmp_ok(length($instructions), '<=', 220, 'instructions stay compact');
};

done_testing();
