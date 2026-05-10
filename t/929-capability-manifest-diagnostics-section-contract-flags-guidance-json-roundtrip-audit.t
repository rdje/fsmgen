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

subtest 'manifest diagnostics section contract advertisement flags and guidance survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{'diagnostics'}{section_contract};
    my $expected = build_diagnostics_contract();
    is($contract->{'stable_code_registry_contract_advertised'} ? 1 : 0, $expected->{'stable_code_registry_contract_advertised'} ? 1 : 0, 'decoded manifest diagnostics contract keeps stable_code_registry_contract_advertised');
    is($contract->{'check_json_contract_advertised'} ? 1 : 0, $expected->{'check_json_contract_advertised'} ? 1 : 0, 'decoded manifest diagnostics contract keeps check_json_contract_advertised');
    is($contract->{'full_diagnostics_section_stable'} ? 1 : 0, $expected->{'full_diagnostics_section_stable'} ? 1 : 0, 'decoded manifest diagnostics contract keeps full_diagnostics_section_stable');
    is_deeply($contract->{'guidance'}, $expected->{'guidance'}, 'decoded manifest diagnostics contract keeps guidance');
};
done_testing();
