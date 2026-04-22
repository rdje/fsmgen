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
use FSM::Support::LanguageSurfaceSection qw(build_language_surface_section);

my $expected_section = build_language_surface_section();

subtest 'language-surface manifest section stays an exact dedicated-builder projection in-process' => sub {
    my $manifest = build_capability_manifest();

    is_deeply(
        $manifest->{language_surface},
        $expected_section,
        'in-process language-surface section matches the exact dedicated builder projection',
    );
};

subtest 'language-surface manifest section stays an exact dedicated-builder projection through the public CLI' => sub {
    my $decoded = run_capability_manifest('--capability-manifest');

    is_deeply(
        $decoded->{language_surface},
        $expected_section,
        'CLI language-surface section matches the exact dedicated builder projection',
    );
};

subtest 'language-surface manifest alias keeps the same exact dedicated-builder projection' => sub {
    my $decoded = run_capability_manifest('--emit-capability-manifest');

    is_deeply(
        $decoded->{language_surface},
        $expected_section,
        'CLI alias language-surface section matches the exact dedicated builder projection',
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
