#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::SerializablePlanReportContract qw(build_serializable_plan_report_contract);

subtest 'manifest-embedded serializable plan reports raw shell replacement map survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{serializable_plan_reports};
    my $expected = build_serializable_plan_report_contract();
    is_deeply($contract->{'raw_shell_replacement_map'}, $expected->{'raw_shell_replacement_map'}, 'decoded manifest serializable plan report contract keeps raw_shell_replacement_map');
};
done_testing();
