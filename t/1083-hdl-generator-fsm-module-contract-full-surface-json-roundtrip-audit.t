#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::HDLGeneratorFSMModuleContract qw(build_hdl_generator_fsm_module_contract);

subtest 'FSM module contract full surface survives JSON round trip' => sub {
    my $contract = build_hdl_generator_fsm_module_contract();
    my $decoded = decode_json(encode_json($contract));
    is_deeply($decoded, $contract, 'decoded FSM module contract matches owner contract');
};

done_testing();
