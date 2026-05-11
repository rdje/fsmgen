#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::HDLGeneratorModuleInfoContract qw(build_hdl_generator_module_info_contract);

subtest 'HDLGenerator module info contract full surface survives JSON round trip' => sub {
    my $contract = build_hdl_generator_module_info_contract();
    my $decoded = decode_json(encode_json($contract));
    is_deeply($decoded, $contract, 'decoded module info contract matches owner contract');
};

done_testing();
