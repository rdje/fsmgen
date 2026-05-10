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

subtest 'manifest-embedded composition report map and ordered key families survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{composition_report};
    my $expected = build_composition_report_contract();
    is_deeply($contract->{'count_map_keys'}, $expected->{'count_map_keys'}, 'decoded manifest composition report keeps count_map_keys');
    is_deeply($contract->{'example_map_keys'}, $expected->{'example_map_keys'}, 'decoded manifest composition report keeps example_map_keys');
    is_deeply($contract->{'ordered_list_keys'}, $expected->{'ordered_list_keys'}, 'decoded manifest composition report keeps ordered_list_keys');
    is_deeply($contract->{'presence_key_family_map'}, $expected->{'presence_key_family_map'}, 'decoded manifest composition report keeps presence_key_family_map');
};
done_testing();
