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
);

subtest 'HDLGenerator result live_or_unsanitized_keys survive JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_hdl_generator_result_contract()));

    ok(ref($decoded->{live_or_unsanitized_keys}) eq 'ARRAY', 'decoded live_or_unsanitized_keys remains an array');
    is_deeply(
        as_set($decoded->{live_or_unsanitized_keys}),
        as_set([qw(
            fsm_module
            raw_ast
            statistics
            module_info
            source_info
            resolved_package_imports
            composition_spec
            composition_plan
            composition_report
        )]),
        'decoded live-or-unsanitized list keeps the expected compatibility branches',
    );
    ok(
        !contains_scalar($decoded->{live_or_unsanitized_keys}, 'hdl_code'),
        'decoded live-or-unsanitized metadata does not mark hdl_code unsanitized',
    );
};

done_testing();

sub as_set {
    my ($values) = @_;
    return {map { $_ => 1 } @{$values || []}};
}

sub contains_scalar {
    my ($values, $wanted) = @_;
    return 0 unless ref($values) eq 'ARRAY';
    return scalar grep { defined($_) && !ref($_) && $_ eq $wanted } @{$values};
}
