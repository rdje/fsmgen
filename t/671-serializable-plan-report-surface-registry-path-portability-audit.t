#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializablePlanReportContract qw(serializable_plan_report_surface_registry);

subtest 'surface registry primary report paths are portable logical paths' => sub {
    my $registry = serializable_plan_report_surface_registry();

    for my $surface (sort keys %{$registry}) {
        my $paths = $registry->{$surface}{primary_report_paths};
        ok(ref($paths) eq 'ARRAY' && @{$paths}, "$surface has primary report paths");
        for my $path (@{$paths}) {
            ok(defined($path) && !ref($path), "$surface path is scalar");
            ok($path !~ m{\A/}, "$surface path is not absolute: $path");
            ok($path !~ m{/Users/}, "$surface path is not machine-local: $path");
            ok($path =~ /\A[A-Za-z0-9_]+(?:\.[A-Za-z0-9_]+)*\z/, "$surface path is a dotted logical path: $path");
        }
    }
};

done_testing();
