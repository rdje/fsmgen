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
    hdl_generator_result_known_top_level_keys
);

subtest 'HDLGenerator result top-level key families survive JSON round trip' => sub {
    my $contract = build_hdl_generator_result_contract();
    my $decoded = decode_json(encode_json($contract));

    for my $field (qw(
        public_top_level_presence_keys
        direct_root_top_level_keys
        composition_root_top_level_keys
    )) {
        is_deeply(
            $decoded->{$field},
            $contract->{$field},
            "decoded contract keeps $field",
        );
    }

    my %decoded_known;
    for my $field (qw(
        public_top_level_presence_keys
        direct_root_top_level_keys
        composition_root_top_level_keys
    )) {
        $decoded_known{$_} = 1 for @{$decoded->{$field} || []};
    }

    is_deeply(
        [sort keys %decoded_known],
        hdl_generator_result_known_top_level_keys(),
        'decoded top-level key families match canonical known top-level key helper',
    );
};

done_testing();
