#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializablePlanReportContract qw(
    build_serializable_plan_report_contract
    serializable_plan_report_public_top_level_keys
);

subtest 'serializable plan/report public top-level keys survive JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_serializable_plan_report_contract()));
    my $public_keys = $decoded->{public_top_level_presence_keys};

    is_deeply(
        $public_keys,
        serializable_plan_report_public_top_level_keys(),
        'decoded contract keeps canonical plan/report public key list',
    );
    is_deeply(
        as_set($public_keys),
        as_set([keys %{$decoded}]),
        'decoded public key list matches decoded contract keys',
    );
};

done_testing();

sub as_set {
    my ($values) = @_;
    return {map { $_ => 1 } @{$values || []}};
}
