#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SerializablePlanReportContract qw(serializable_plan_report_json_safe_surface_keys);

subtest 'manifest JSON-safe surface keys survive JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $surface_keys = $decoded->{embedding}{serializable_plan_reports}{json_safe_surface_keys};

    is_deeply(
        $surface_keys,
        serializable_plan_report_json_safe_surface_keys(),
        'decoded manifest keeps canonical JSON-safe surface key list',
    );
    is(
        scalar(@{$surface_keys}),
        scalar(keys %{as_set($surface_keys)}),
        'decoded JSON-safe surface key list remains unique',
    );
};

done_testing();

sub as_set {
    my ($values) = @_;
    return {map { $_ => 1 } @{$values || []}};
}
