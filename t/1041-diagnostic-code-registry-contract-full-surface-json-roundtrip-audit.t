#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::DiagnosticCodeRegistryContract qw(build_diagnostic_code_registry_contract);

subtest 'diagnostic code registry contract full surface survives JSON round trip' => sub {
    my $contract = build_diagnostic_code_registry_contract();
    my $decoded = decode_json(encode_json($contract));
    is_deeply($decoded, $contract, 'decoded diagnostic code registry contract matches owner contract');
};

done_testing();
