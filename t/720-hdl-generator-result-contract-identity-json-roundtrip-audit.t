#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::HDLGeneratorResultContract qw(
    build_hdl_generator_result_contract
    hdl_generator_result_contract_source
);

subtest 'HDLGenerator result contract identity survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_hdl_generator_result_contract()));

    is($decoded->{schema_version}, 1, 'decoded contract keeps schema version');
    is($decoded->{status}, 'bounded_top_level_presence', 'decoded contract keeps bounded status');
    is(
        $decoded->{contract_source},
        hdl_generator_result_contract_source(),
        'decoded contract keeps canonical owner',
    );
    is(
        $decoded->{entrypoint},
        'FSM::Pipeline::HDLGenerator->new(...)->generate_hdl_from_file($path)',
        'decoded contract keeps public entrypoint',
    );
    ok(ref($decoded->{tested_by}) eq 'ARRAY', 'decoded contract keeps tested_by list');
    ok(
        grep({ $_ eq 't/305-hdl-generator-result-contract.t' } @{$decoded->{tested_by}}),
        'decoded contract keeps primary contract test reference',
    );
};

done_testing();
