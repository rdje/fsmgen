#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::BackendValidationContract qw(build_backend_validation_contract);

subtest 'manifest backend-validation contract advertisement flags and guidance survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{'backend_validation'}{'section_contract'};
    my $expected = build_backend_validation_contract();
    is($contract->{'systemverilog_external_contract_advertised'} ? 1 : 0, $expected->{'systemverilog_external_contract_advertised'} ? 1 : 0, 'decoded manifest backend-validation contract keeps systemverilog_external_contract_advertised');
    is($contract->{'full_backend_validation_section_stable'} ? 1 : 0, $expected->{'full_backend_validation_section_stable'} ? 1 : 0, 'decoded manifest backend-validation contract keeps full_backend_validation_section_stable');
    is_deeply($contract->{'guidance'}, $expected->{'guidance'}, 'decoded manifest backend-validation contract keeps guidance');
};
done_testing();
