#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::HDLGeneratorCompositionPlanContract qw(build_hdl_generator_composition_plan_contract);

subtest 'composition plan contract full surface survives JSON round trip' => sub {
    my $contract = build_hdl_generator_composition_plan_contract();
    my $decoded = decode_json(encode_json($contract));
    is_deeply($decoded, $contract, 'decoded composition plan contract matches owner contract');
};

done_testing();
