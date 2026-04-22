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
use FSM::Support::DocumentationSection qw(build_documentation_section);

my $repo_root = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));
my $expected_section = build_documentation_section();

my @manifest_views = (
    {
        label => 'in-process capability manifest',
        section => build_capability_manifest()->{documentation},
    },
    {
        label => 'CLI capability manifest',
        section => run_capability_manifest('--capability-manifest')->{documentation},
    },
    {
        label => 'CLI alias capability manifest',
        section => run_capability_manifest('--emit-capability-manifest')->{documentation},
    },
);

subtest 'documentation section keeps exact dedicated-builder parity' => sub {
    for my $view (@manifest_views) {
        is_deeply(
            $view->{section},
            $expected_section,
            "$view->{label} keeps documentation as an exact dedicated-builder projection",
        );
    }
};

subtest 'published documentation paths stay relative, unique, and present on disk' => sub {
    for my $view (@manifest_views) {
        my $section = $view->{section};
        my $label = $view->{label};

        for my $list_key (qw(human_contract downstream_alignment)) {
            my $paths = $section->{$list_key};
            ok(ref($paths) eq 'ARRAY', "$label keeps $list_key as an array");
            ok(@{$paths || []}, "$label keeps $list_key non-empty");

            my %seen;
            for my $path (@{$paths || []}) {
                ok($path !~ m{\A/}, "$label keeps $list_key path $path relative to the repo root");
                ok(index($path, '..') == -1, "$label keeps $list_key path $path free of parent traversal");
                ok(!$seen{$path}++, "$label keeps $list_key path $path unique");

                my $abs_path = File::Spec->catfile($repo_root, split m{/}, $path);
                ok(-f $abs_path, "$label keeps $list_key path $path present on disk");
            }
        }
    }
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
