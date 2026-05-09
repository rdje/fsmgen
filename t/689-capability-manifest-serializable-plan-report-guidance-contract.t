#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);

subtest 'manifest embeds structured serializable plan/report guidance' => sub {
    my $manifest = build_capability_manifest();
    my $guidance = $manifest->{embedding}{serializable_plan_reports}{guidance};

    ok(ref($guidance) eq 'ARRAY', 'manifest guidance is an array');
    ok(@{$guidance} > 0, 'manifest guidance is non-empty');
    is(
        scalar(@{$guidance}),
        scalar(keys %{as_set($guidance)}),
        'manifest guidance entries are unique',
    );

    for my $index (0 .. $#{$guidance}) {
        ok(
            defined($guidance->[$index]) && !ref($guidance->[$index]) && length($guidance->[$index]),
            "manifest guidance entry $index is a non-empty scalar",
        );
    }

    ok(
        grep({ /JSON-safe report surfaces/ } @{$guidance}),
        'manifest guidance points embedders toward JSON-safe report surfaces',
    );
    ok(
        grep({ /raw HDLGenerator branches/ } @{$guidance}),
        'manifest guidance warns about raw HDLGenerator branches',
    );
};

done_testing();

sub as_set {
    my ($values) = @_;
    return {map { $_ => 1 } @{$values || []}};
}
