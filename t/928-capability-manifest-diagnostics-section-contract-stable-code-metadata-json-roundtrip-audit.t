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

subtest 'manifest diagnostics section contract stable-code metadata survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{'diagnostics'}{section_contract};
    my $expected = build_diagnostics_contract();
    is_deeply($contract->{'stable_code_entry_presence_keys'}, $expected->{'stable_code_entry_presence_keys'}, 'decoded manifest diagnostics contract keeps stable_code_entry_presence_keys');
    is_deeply($contract->{'presence_key_family_map'}, $expected->{'presence_key_family_map'}, 'decoded manifest diagnostics contract keeps presence_key_family_map');
    is_deeply($contract->{'stable_code_family_values'}, $expected->{'stable_code_family_values'}, 'decoded manifest diagnostics contract keeps stable_code_family_values');
};
done_testing();
