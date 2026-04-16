#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::FSMGenFull::ExpressionBuilder;
use FSM::Adapter::FSMGenFull::SignalManager;
use FSM::Package::ScalarWidthSupport;

my @positive_cases = (
    [ '8', 8, 'plain decimal' ],
    [ '1_024', 1024, 'underscore decimal' ],
    [ '0d16', 16, 'prefixed decimal' ],
    [ '0b1000', 8, 'prefixed binary' ],
    [ '0b1_000', 8, 'underscore prefixed binary' ],
    [ '0o10', 8, 'prefixed octal' ],
    [ '0o1_0', 8, 'underscore prefixed octal' ],
    [ '0x10', 16, 'prefixed hex' ],
    [ '0x1_0', 16, 'underscore prefixed hex' ],
    [ q{'b1000}, 8, 'unsized SV binary' ],
    [ q{'o10}, 8, 'unsized SV octal' ],
    [ q{'h10}, 16, 'unsized SV hex' ],
    [ q{8'h10}, 16, 'sized SV hex' ],
    [ q{8'sh10}, 16, 'signed positive SV hex' ],
    [ { kind => 'scalar', payload => q{'h10} }, 16, 'scalar payload hash' ],
);

for my $case (@positive_cases) {
    my ($payload, $expected, $label) = @$case;
    is(
        FSM::Package::ScalarWidthSupport->positive_integer_from_literal_like($payload),
        $expected,
        "positive integer width resolves from $label",
    );
}

my @rejected_cases = (
    [ '0', 'zero decimal' ],
    [ '0d0', 'zero prefixed decimal' ],
    [ '0b0', 'zero prefixed binary' ],
    [ q{8'sd-1}, 'negative signed decimal' ],
    [ q{'sh-1}, 'negative signed hex' ],
    [ '0xG', 'invalid hex' ],
    [ { kind => 'list', items => [ { kind => 'scalar', payload => '1' } ] }, 'aggregate payload' ],
);

for my $case (@rejected_cases) {
    my ($payload, $label) = @$case;
    is(
        FSM::Package::ScalarWidthSupport->positive_integer_from_literal_like($payload),
        undef,
        "positive integer width rejects $label",
    );
}

subtest 'expression builder accepts common integer literal spellings' => sub {
    my $signal_manager = FSM::Adapter::FSMGenFull::SignalManager->new(debug => 0);
    my $builder = FSM::Adapter::FSMGenFull::ExpressionBuilder->new(
        debug => 0,
        signal_manager => $signal_manager,
    );

    my @literal_cases = (
        [ '0xA_5', "8'hA5", 'prefixed hex' ],
        [ '0b1010_0101', "8'b10100101", 'prefixed binary' ],
        [ '0o10', "6'o10", 'prefixed octal' ],
        [ q{'hA5}, "8'hA5", 'unsized SV hex' ],
        [ q{'b1010}, "4'b1010", 'unsized SV binary' ],
        [ q{'o10}, "6'o10", 'unsized SV octal' ],
        [ q{8'shA5}, "8'hA5", 'signed positive sized SV hex' ],
    );

    for my $case (@literal_cases) {
        my ($token, $expected_sv, $label) = @$case;
        my $expr = $builder->parse_scalar_expression($token);
        is($expr->to_systemverilog, $expected_sv, "expression builder parses $label");
    }
};

done_testing;
