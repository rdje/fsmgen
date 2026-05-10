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

subtest 'manifest-embedded HDLGenerator `live_or_unsanitized_keys` list survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_capability_manifest()));
    my $contract = $decoded->{embedding}{hdl_generator_result};
    my $expected = build_hdl_generator_result_contract();

    is_deeply(
        $contract->{live_or_unsanitized_keys},
        $expected->{live_or_unsanitized_keys},
        'decoded manifest result contract keeps live_or_unsanitized_keys list',
    );
    ok(grep({ $_ eq 'composition_report' } @{$contract->{live_or_unsanitized_keys}}), 'decoded manifest result contract keeps composition_report marked live or unsanitized');

};

done_testing();
