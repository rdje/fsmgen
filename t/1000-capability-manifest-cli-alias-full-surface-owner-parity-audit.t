#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);

subtest 'CLI capability manifest alias matches owner builder full surface' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-capability-manifest'],
    );

    ok($success, 'CLI capability manifest alias succeeds without an input source')
        or diag($error_message || join('', @{$full_buf || []}));
    is(join('', @{$stderr_buf || []}), '', 'CLI capability manifest alias does not print stderr');

    my $decoded = decode_json(join('', @{$stdout_buf || []}));
    is_deeply($decoded, build_capability_manifest(), 'CLI manifest alias JSON matches owner builder output');
};

done_testing();
