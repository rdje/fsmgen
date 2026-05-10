#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CompositionReportContract qw(
    composition_report_json_fragment_path
);
use FSM::Support::HDLGeneratorResultContract qw(
    build_hdl_generator_result_contract
);

subtest 'HDLGenerator result composition_report shell surfaces survive JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_hdl_generator_result_contract()));

    is(
        $decoded->{composition_report_json_fragment_path},
        composition_report_json_fragment_path(),
        'decoded result contract keeps canonical composition_report JSON fragment path',
    );
    is_deeply(
        $decoded->{shell_only_fallback_surface_map}{composition_report},
        [$decoded->{composition_report_json_fragment_path}],
        'decoded grouped shell fallback map mirrors composition_report JSON fragment path',
    );
    is_deeply(
        $decoded->{shell_only_fallback_surface_family_map}{composition_report}{sanitized_json_fragment},
        [$decoded->{composition_report_json_fragment_path}],
        'decoded grouped shell fallback family map mirrors composition_report JSON fragment family',
    );
    is($decoded->{composition_report_raw_hash_json_safe}, 0, 'decoded raw composition_report hash remains not JSON-safe');
};

done_testing();
