#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::HDLGeneratorResultContract qw(build_hdl_generator_result_contract);

subtest 'HDLGenerator result nested owner map survives JSON round trip' => sub {
    my $contract = build_hdl_generator_result_contract();
    my $decoded = decode_json(encode_json($contract));
    my $owner_map = $decoded->{nested_contract_source_map};

    is_deeply(
        $owner_map,
        $contract->{nested_contract_source_map},
        'decoded contract keeps exact nested owner map',
    );
    is(
        $owner_map->{source_info},
        $decoded->{source_info_contract_source},
        'decoded source_info owner map entry matches scalar owner field',
    );
    is(
        $owner_map->{module_info},
        $decoded->{module_info_contract_source},
        'decoded module_info owner map entry matches scalar owner field',
    );
    is(
        $owner_map->{statistics},
        $decoded->{statistics_contract_source},
        'decoded statistics owner map entry matches scalar owner field',
    );
};

done_testing();
