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
    hdl_generator_result_known_top_level_keys
);

subtest 'manifest-embedded HDLGenerator top-level key families survive JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{hdl_generator_result};
    my $expected = build_hdl_generator_result_contract();

    for my $field (qw(
        public_top_level_presence_keys
        direct_root_top_level_keys
        composition_root_top_level_keys
    )) {
        is_deeply(
            sorted($contract->{$field}),
            sorted($expected->{$field}),
            "decoded manifest result contract keeps $field",
        );
    }

    is_deeply(
        known_top_level_keys_from($contract),
        hdl_generator_result_known_top_level_keys(),
        'decoded manifest result contract still advertises the known top-level key union',
    );
};

done_testing();

sub known_top_level_keys_from {
    my ($contract) = @_;
    my %known;
    for my $field (qw(
        public_top_level_presence_keys
        direct_root_top_level_keys
        composition_root_top_level_keys
    )) {
        $known{$_} = 1 for @{$contract->{$field} || []};
    }
    return [sort keys %known];
}

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}
