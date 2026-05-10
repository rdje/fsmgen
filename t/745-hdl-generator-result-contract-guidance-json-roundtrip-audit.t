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

subtest 'HDLGenerator result guidance survives JSON round trip' => sub {
    my $decoded = decode_json(encode_json(build_hdl_generator_result_contract()));

    ok(ref($decoded->{guidance}) eq 'ARRAY', 'decoded guidance remains an array');
    ok(@{$decoded->{guidance}} > 0, 'decoded guidance remains non-empty');
    is(
        scalar(@{$decoded->{guidance}}),
        scalar(keys %{as_set($decoded->{guidance})}),
        'decoded guidance remains unique',
    );
    ok(
        contains_matching_guidance($decoded->{guidance}, qr/Do not treat the entire HDLGenerator result hash as a stable JSON document/),
        'decoded guidance keeps whole-result non-stability warning',
    );
    ok(
        contains_matching_guidance($decoded->{guidance}, qr/Use --emit-semantic-json or FSM::Support::NormalizedSemanticReport/),
        'decoded guidance keeps sanitized interchange recommendation',
    );
};

done_testing();

sub as_set {
    my ($values) = @_;
    return {map { $_ => 1 } @{$values || []}};
}

sub contains_matching_guidance {
    my ($values, $pattern) = @_;
    for my $value (@{$values || []}) {
        return 1 if defined($value) && !ref($value) && $value =~ $pattern;
    }
    return 0;
}
