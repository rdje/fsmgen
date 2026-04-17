#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::FSMGenFull::ExpressionBuilder;
use FSM::Adapter::FSMGenFull::SignalManager;
use FSM::Package::IntegerLiteralSupport;
use FSM::Pipeline::HDLGenerator;

subtest 'integer literal support accepts intent-level sized values' => sub {
    my @cases = (
        [ q{5'23}, q{5'd23}, 'sized unbased positive decimal' ],
        [ q{8'-10}, q{8'd246}, 'sized unbased negative decimal lowers to two-complement bits' ],
        [ q{8'-0xA}, q{8'hF6}, 'sized negative hex lowers to two-complement bits' ],
        [ q{8'-0b1010}, q{8'b11110110}, 'sized negative binary lowers to two-complement bits' ],
        [ q{20'x1}, q{20'h1}, 'x radix alias lowers to legal SV hex radix' ],
        [ q{-0xA}, q{-10}, 'unsized negative hex remains a signed integer value' ],
        [ q{-0b1010}, q{-10}, 'unsized negative binary remains a signed integer value' ],
    );

    for my $case (@cases) {
        my ($token, $expected_sv, $label) = @$case;
        my $parts = FSM::Package::IntegerLiteralSupport->literal_parts_from_scalar($token);
        ok($parts, "literal parts parse $label");
        is(
            FSM::Package::IntegerLiteralSupport->systemverilog_literal_from_parts(%$parts),
            $expected_sv,
            "SystemVerilog normalization for $label",
        );
    }
};

subtest 'expression builder preserves target-HDL-safe literal payloads' => sub {
    my $signal_manager = FSM::Adapter::FSMGenFull::SignalManager->new(debug => 0);
    my $builder = FSM::Adapter::FSMGenFull::ExpressionBuilder->new(
        debug => 0,
        signal_manager => $signal_manager,
    );

    my @cases = (
        [ q{5'23}, q{5'd23}, 'sized unbased decimal' ],
        [ q{8'-10}, q{8'd246}, 'sized negative decimal' ],
        [ q{8'-0xA}, q{8'hF6}, 'sized negative hex' ],
        [ q{8'-0b1010}, q{8'b11110110}, 'sized negative binary' ],
        [ q{20'x1}, q{20'h1}, 'x radix alias' ],
    );

    for my $case (@cases) {
        my ($token, $expected_sv, $label) = @$case;
        my $expr = $builder->parse_scalar_expression($token);
        is($expr->to_systemverilog, $expected_sv, "expression builder normalizes $label");
    }
};

subtest 'generated SystemVerilog never leaks intent-only integer literal spelling' => sub {
    my $fsm_file = File::Spec->catfile($FindBin::Bin, 'corpus', 'direct_intent_integer_literals.fsm');
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $result;
    {
        local $SIG{__WARN__} = sub { };
        $result = $pipeline->generate_hdl_from_file($fsm_file);
    }

    my $hdl = $result->{hdl_code} || '';
    ok($hdl ne '', 'pipeline emits HDL for intent integer literal fixture');
    unlike($hdl, qr/\b(?:5'23|8'-10|8'-0xA|8'-0b1010|20'x1)\b/, 'intent-only spellings do not leak into generated SV');
    like($hdl, qr/\bDEC_CODE\s*=\s*5'd23\s*;/, 'sized decimal shorthand emits legal SV decimal literal');
    like($hdl, qr/\bNEG_DEC\s*=\s*8'd246\s*;/, 'negative decimal shorthand emits legal two-complement SV decimal literal');
    like($hdl, qr/\bNEG_HEX\s*=\s*8'hF6\s*;/, 'negative hex shorthand emits legal two-complement SV hex literal');
    like($hdl, qr/\bNEG_BIN\s*=\s*8'b11110110\s*;/, 'negative binary shorthand emits legal two-complement SV binary literal');
    like($hdl, qr/\bHEX_ALIAS\s*=\s*20'h1\s*;/, 'x radix alias emits legal SV h radix literal');
    like($hdl, qr/\bFROM_CONST\s*=\s*8'hF6\s*;/, 'constant canonicalization preserves normalized two-complement payload');
};

done_testing();
