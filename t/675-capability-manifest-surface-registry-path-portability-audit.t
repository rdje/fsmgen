#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);

subtest 'manifest-embedded surface registry paths are portable logical paths' => sub {
    my $manifest = build_capability_manifest();
    my $registry = $manifest->{embedding}{serializable_plan_reports}{surface_registry};

    for my $surface (sort keys %{$registry}) {
        for my $path (@{$registry->{$surface}{primary_report_paths} || []}) {
            ok($path !~ m{\A/}, "$surface manifest path is not absolute: $path");
            ok($path !~ m{/Users/}, "$surface manifest path is not machine-local: $path");
            ok($path =~ /\A[A-Za-z0-9_]+(?:\.[A-Za-z0-9_]+)*\z/, "$surface manifest path is dotted: $path");
        }
    }
};

done_testing();
