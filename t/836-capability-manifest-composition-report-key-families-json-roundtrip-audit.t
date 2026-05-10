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

subtest 'manifest-embedded composition report public summary and collection key families survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{composition_report};
    my $expected = build_composition_report_contract();
    is_deeply($contract->{'public_top_level_keys'}, $expected->{'public_top_level_keys'}, 'decoded manifest composition report keeps public_top_level_keys');
    is_deeply($contract->{'summary_keys'}, $expected->{'summary_keys'}, 'decoded manifest composition report keeps summary_keys');
    is_deeply($contract->{'collection_keys'}, $expected->{'collection_keys'}, 'decoded manifest composition report keeps collection_keys');
};
done_testing();
