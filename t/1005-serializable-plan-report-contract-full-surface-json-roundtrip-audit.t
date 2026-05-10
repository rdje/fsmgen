#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::SerializablePlanReportContract qw(build_serializable_plan_report_contract);

subtest 'serializable plan/report contract full surface survives JSON round trip' => sub {
    my $expected = build_serializable_plan_report_contract();
    my $decoded = decode_json(encode_json($expected));
    is_deeply($decoded, $expected, 'decoded serializable plan/report contract matches direct owner contract');
};

done_testing();
