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

subtest 'manifest-embedded composition report JSON-safety flags survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{composition_report};
    my $expected = build_composition_report_contract();
    is($contract->{'raw_report_json_safe'} ? 1 : 0, $expected->{'raw_report_json_safe'} ? 1 : 0, 'decoded manifest composition report keeps raw_report_json_safe');
    is($contract->{'sanitized_report_json_safe'} ? 1 : 0, $expected->{'sanitized_report_json_safe'} ? 1 : 0, 'decoded manifest composition report keeps sanitized_report_json_safe');
    is($contract->{'sanitizes_private_perl_objects'} ? 1 : 0, $expected->{'sanitizes_private_perl_objects'} ? 1 : 0, 'decoded manifest composition report keeps sanitizes_private_perl_objects');
    is($contract->{'stable_nested_content'} ? 1 : 0, $expected->{'stable_nested_content'} ? 1 : 0, 'decoded manifest composition report keeps stable_nested_content');
};
done_testing();
