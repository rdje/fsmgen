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

subtest 'manifest producer section contract presence key family map survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{'producer'}{section_contract};
    my $expected = build_producer_contract();
    is_deeply($contract->{'presence_key_family_map'}, $expected->{'presence_key_family_map'}, 'decoded manifest producer contract keeps presence_key_family_map');
    is_deeply($contract->{'identity_contract'}, $expected->{'identity_contract'}, 'decoded manifest producer contract keeps identity_contract');
};
done_testing();
