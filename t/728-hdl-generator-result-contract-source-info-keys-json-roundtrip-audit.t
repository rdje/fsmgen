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
    hdl_generator_result_source_info_identity_keys
    hdl_generator_result_source_info_summary_keys
);

subtest 'HDLGenerator result source_info keys survive JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_hdl_generator_result_contract()));

    is_deeply(
        $decoded->{source_info_identity_presence_keys},
        hdl_generator_result_source_info_identity_keys(),
        'decoded contract keeps canonical source_info identity keys',
    );
    is_deeply(
        $decoded->{source_info_summary_presence_keys},
        hdl_generator_result_source_info_summary_keys(),
        'decoded contract keeps canonical source_info summary keys',
    );
    ok(!$decoded->{source_info_full_hash_stable}, 'decoded contract keeps source_info full hash non-stable');
    like(
        $decoded->{source_info_package_import_summary_copy_policy},
        qr/fresh caller-owned array/,
        'decoded contract keeps source_info package-import copy policy',
    );
};

done_testing();
