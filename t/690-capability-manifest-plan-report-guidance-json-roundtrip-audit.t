#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);

subtest 'manifest plan/report guidance survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $guidance = $decoded->{embedding}{serializable_plan_reports}{guidance};

    ok(ref($guidance) eq 'ARRAY', 'decoded guidance is an array');
    ok(@{$guidance} > 0, 'decoded guidance is non-empty');
    is(
        scalar(@{$guidance}),
        scalar(keys %{as_set($guidance)}),
        'decoded guidance entries are unique',
    );

    for my $index (0 .. $#{$guidance}) {
        ok(
            defined($guidance->[$index]) && !ref($guidance->[$index]) && length($guidance->[$index]),
            "decoded guidance entry $index is a non-empty scalar",
        );
    }

    ok(
        grep({ /JSON-safe report surfaces/ } @{$guidance}),
        'decoded guidance points embedders toward JSON-safe report surfaces',
    );
    ok(
        grep({ /raw HDLGenerator branches/ } @{$guidance}),
        'decoded guidance warns about raw HDLGenerator branches',
    );
};

done_testing();

sub as_set {
    my ($values) = @_;
    return {map { $_ => 1 } @{$values || []}};
}
