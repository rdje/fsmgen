#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ProducerContract qw(build_producer_contract);

subtest 'manifest producer section contract public key families survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{'producer'}{section_contract};
    my $expected = build_producer_contract();
    is_deeply($contract->{'public_top_level_presence_keys'}, $expected->{'public_top_level_presence_keys'}, 'decoded manifest producer contract keeps public_top_level_presence_keys');
    is_deeply($contract->{'scalar_string_keys'}, $expected->{'scalar_string_keys'}, 'decoded manifest producer contract keeps scalar_string_keys');
    is_deeply($contract->{'boolean_keys'}, $expected->{'boolean_keys'}, 'decoded manifest producer contract keeps boolean_keys');
};
done_testing();
