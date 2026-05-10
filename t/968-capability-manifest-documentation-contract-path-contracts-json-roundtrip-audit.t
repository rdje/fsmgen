#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::DocumentationContract qw(build_documentation_contract);

subtest 'manifest documentation contract path contract maps survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{'documentation'}{'section_contract'};
    my $expected = build_documentation_contract();
    is_deeply($contract->{'path_contract'}, $expected->{'path_contract'}, 'decoded manifest documentation contract keeps path_contract');
    is_deeply($contract->{'path_list_contract_map'}, $expected->{'path_list_contract_map'}, 'decoded manifest documentation contract keeps path_list_contract_map');
};
done_testing();
