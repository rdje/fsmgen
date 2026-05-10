#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP ();
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);

subtest 'CLI capability manifest uses canonical pretty JSON encoding' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--capability-manifest'],
    );

    ok($success, 'CLI capability manifest command succeeds')
        or diag($error_message || join('', @{$full_buf || []}));
    is(join('', @{$stderr_buf || []}), '', 'CLI capability manifest command emits no stderr');

    my $expected = JSON::PP->new->ascii->canonical->pretty->encode(build_capability_manifest());
    is(join('', @{$stdout_buf || []}), $expected, 'CLI manifest stdout matches canonical owner-builder JSON');
};

done_testing();
