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
use FSM::Support::DiagnosticsSection qw(build_diagnostics_section);

my $expected_section = build_diagnostics_section();

subtest 'diagnostics manifest section stays an exact dedicated-builder projection in-process' => sub {
    my $manifest = build_capability_manifest();

    is_deeply(
        $manifest->{diagnostics},
        $expected_section,
        'in-process diagnostics section matches the exact dedicated builder projection',
    );
};

subtest 'diagnostics manifest section stays an exact dedicated-builder projection through the public CLI' => sub {
    my $decoded = run_capability_manifest('--capability-manifest');

    is_deeply(
        $decoded->{diagnostics},
        $expected_section,
        'CLI diagnostics section matches the exact dedicated builder projection',
    );
};

subtest 'diagnostics manifest alias keeps the same exact dedicated-builder projection' => sub {
    my $decoded = run_capability_manifest('--emit-capability-manifest');

    is_deeply(
        $decoded->{diagnostics},
        $expected_section,
        'CLI alias diagnostics section matches the exact dedicated builder projection',
    );
};

done_testing();

sub run_capability_manifest {
    my ($mode) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', $mode],
    );

    ok($success, "$mode succeeds");
    is(join('', @{$stderr_buf || []}), '', "$mode keeps stderr clean");

    return decode_json(join('', @{$stdout_buf || []}));
}
