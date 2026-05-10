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

subtest 'HDLGenerator result tested_by provenance survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_hdl_generator_result_contract()));

    ok(ref($decoded->{tested_by}) eq 'ARRAY', 'decoded tested_by remains an array');
    ok(
        contains_scalar($decoded->{tested_by}, 't/305-hdl-generator-result-contract.t'),
        'decoded tested_by keeps the primary contract test',
    );
    ok(
        contains_scalar($decoded->{tested_by}, 't/438-hdl-generator-result-contract-defensive-copy-boundary-audit.t'),
        'decoded tested_by keeps the defensive-copy boundary audit',
    );
    ok(
        contains_scalar($decoded->{tested_by}, 't/495-source-info-package-import-summary-defensive-copy-boundary-audit.t'),
        'decoded tested_by keeps the source-info package summary audit',
    );
};

done_testing();

sub contains_scalar {
    my ($values, $wanted) = @_;
    return 0 unless ref($values) eq 'ARRAY';
    return scalar grep { defined($_) && !ref($_) && $_ eq $wanted } @{$values};
}
