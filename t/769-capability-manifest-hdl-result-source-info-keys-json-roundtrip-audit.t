#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::HDLGeneratorResultContract qw(
    build_hdl_generator_result_contract
);

subtest 'manifest-embedded HDLGenerator source_info keys survive JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{hdl_generator_result};
    my $expected = build_hdl_generator_result_contract();

    for my $field (qw(
        source_info_identity_presence_keys
        source_info_summary_presence_keys
        source_info_stable_subsurfaces
    )) {
        is_deeply(
            $contract->{$field},
            $expected->{$field},
            "decoded manifest result contract keeps $field",
        );
    }
    is($contract->{source_info_package_import_summary_copy_policy}, $expected->{source_info_package_import_summary_copy_policy}, 'decoded manifest result contract keeps source_info copy policy');

};

done_testing();
