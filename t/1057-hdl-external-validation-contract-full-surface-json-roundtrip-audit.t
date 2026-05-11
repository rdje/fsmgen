#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::HDLExternalValidationContract qw(build_hdl_external_validation_contract);

subtest 'HDL external validation contract full surface survives JSON round trip' => sub {
    my $contract = build_hdl_external_validation_contract();
    my $decoded = decode_json(encode_json($contract));
    is_deeply($decoded, $contract, 'decoded HDL external validation contract matches owner contract');
};

done_testing();
