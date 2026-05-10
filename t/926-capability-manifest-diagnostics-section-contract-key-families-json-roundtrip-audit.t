#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::DiagnosticsContract qw(build_diagnostics_contract);

subtest 'manifest diagnostics section contract public scalar list and nested key families survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{'diagnostics'}{section_contract};
    my $expected = build_diagnostics_contract();
    is_deeply($contract->{'public_top_level_presence_keys'}, $expected->{'public_top_level_presence_keys'}, 'decoded manifest diagnostics contract keeps public_top_level_presence_keys');
    is_deeply($contract->{'scalar_string_keys'}, $expected->{'scalar_string_keys'}, 'decoded manifest diagnostics contract keeps scalar_string_keys');
    is_deeply($contract->{'list_keys'}, $expected->{'list_keys'}, 'decoded manifest diagnostics contract keeps list_keys');
    is_deeply($contract->{'nested_contract_keys'}, $expected->{'nested_contract_keys'}, 'decoded manifest diagnostics contract keeps nested_contract_keys');
};
done_testing();
