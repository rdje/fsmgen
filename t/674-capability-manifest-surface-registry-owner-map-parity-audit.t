#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);

subtest 'manifest registry owners match manifest nested source map' => sub {
    my $manifest = build_capability_manifest();
    my $branch = $manifest->{embedding}{serializable_plan_reports};

    is_deeply(
        as_set([keys %{$branch->{surface_registry}}]),
        as_set([keys %{$branch->{nested_contract_source_map}}]),
        'manifest registry and source map cover same surfaces',
    );
    for my $surface (sort keys %{$branch->{nested_contract_source_map}}) {
        is(
            $branch->{surface_registry}{$surface}{contract_source},
            $branch->{nested_contract_source_map}{$surface},
            "$surface manifest registry owner matches embedded source map",
        );
    }
};

done_testing();

sub as_set {
    my ($values) = @_;
    return {map { $_ => 1 } @{$values || []}};
}
