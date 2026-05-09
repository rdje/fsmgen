#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use Scalar::Util qw(blessed);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SerializablePlanReportContract qw(serializable_plan_report_surface_registry);

subtest 'manifest-embedded surface registry survives JSON round trip' => sub {
    my $manifest = build_capability_manifest();
    ok(length(encode_json($manifest)), 'manifest encodes as JSON');
    my $decoded = decode_json(encode_json($manifest));
    my $registry = $decoded->{embedding}{serializable_plan_reports}{surface_registry};

    ok(!contains_blessed($registry), 'decoded manifest registry contains no unexpected blessed values');
    is_deeply(
        $registry,
        serializable_plan_report_surface_registry(),
        'round-trip manifest registry matches canonical registry',
    );
};

done_testing();

sub contains_blessed {
    my ($value) = @_;
    return 0 if blessed($value) && blessed($value) eq 'JSON::PP::Boolean';
    return 1 if blessed($value);
    return 0 unless ref($value);

    if (ref($value) eq 'ARRAY') {
        return 1 if grep { contains_blessed($_) } @$value;
        return 0;
    }

    if (ref($value) eq 'HASH') {
        return 1 if grep { contains_blessed($_) } values %$value;
        return 0;
    }

    return 0;
}
