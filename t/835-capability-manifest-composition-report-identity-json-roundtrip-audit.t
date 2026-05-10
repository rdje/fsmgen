#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::CompositionReportContract qw(build_composition_report_contract);

subtest 'manifest-embedded composition report identity metadata survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{composition_report};
    my $expected = build_composition_report_contract();
    is($contract->{'status'}, $expected->{'status'}, 'decoded manifest composition report keeps status');
    is($contract->{'contract_source'}, $expected->{'contract_source'}, 'decoded manifest composition report keeps contract_source');
    is($contract->{'report_builder'}, $expected->{'report_builder'}, 'decoded manifest composition report keeps report_builder');
    is($contract->{'raw_result_key'}, $expected->{'raw_result_key'}, 'decoded manifest composition report keeps raw_result_key');
    is($contract->{'json_fragment_path'}, $expected->{'json_fragment_path'}, 'decoded manifest composition report keeps json_fragment_path');
    is($contract->{schema_version}, $expected->{schema_version}, 'decoded manifest composition report keeps schema version');
};
done_testing();
