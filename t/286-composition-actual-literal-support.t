#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::ActualLiteralSupport;
use FSM::IR::StructuralRTLIR::ConnectionExpr qw(
    bit_vector_literal_expr
    open_expr
);

subtest 'actual literal support parses direct actual payload families' => sub {
    my $open = FSM::Composition::ActualLiteralSupport->resolve_actual_payload(
        'open',
        raw => '=open',
        key => 'actual:=open',
        fsm_file => 'actual_literals.fsm',
        header => 'actual_literals',
    );
    is($open->{kind}, 'actual_open', 'open actual preserves the open kind');
    is_deeply($open->{connection_expr}, open_expr(), 'open actual lowers to the structural open expression');

    my $one = FSM::Composition::ActualLiteralSupport->resolve_actual_payload(
        '1',
        raw => '=1',
        key => 'actual:=1',
        fsm_file => 'actual_literals.fsm',
        header => 'actual_literals',
    );
    is($one->{kind}, 'actual_scalar_literal', 'scalar one actual preserves scalar literal kind');
    is($one->{scalar_bit}, '1', 'scalar one actual preserves its bit payload');

    my $hex = FSM::Composition::ActualLiteralSupport->resolve_actual_payload(
        'A_5',
        raw => '=A_5',
        key => 'actual:=A_5',
        fsm_file => 'actual_literals.fsm',
        header => 'actual_literals',
    );
    is($hex->{kind}, 'actual_unsized_hex', 'bare hex actual preserves unsized hex kind');
    is($hex->{hex_digits}, 'A5', 'bare hex actual strips digit separators');

    my $signed_decimal = FSM::Composition::ActualLiteralSupport->resolve_actual_payload(
        '-1',
        raw => '=-1',
        key => 'actual:=-1',
        fsm_file => 'actual_literals.fsm',
        header => 'actual_literals',
    );
    is($signed_decimal->{kind}, 'actual_unsized_signed_decimal', 'negative decimal actual preserves signed-decimal kind');
    is($signed_decimal->{decimal_digits}, '1', 'negative decimal actual stores normalized magnitude digits');

    my $exact_signed = FSM::Composition::ActualLiteralSupport->resolve_actual_payload(
        q{8'sd-1},
        raw => q{=8'sd-1},
        key => q{actual:=8'sd-1},
        fsm_file => 'actual_literals.fsm',
        header => 'actual_literals',
    );
    is($exact_signed->{kind}, 'actual_literal', 'exact-width signed decimal actual preserves literal kind');
    is($exact_signed->{port}{width}, 8, 'exact-width signed decimal actual preserves target-independent width');
    is_deeply(
        $exact_signed->{connection_expr},
        bit_vector_literal_expr('11111111'),
        'exact-width signed decimal actual lowers through two-complement bits',
    );

    my $intent_sized = FSM::Composition::ActualLiteralSupport->resolve_actual_payload(
        q{8'-0xA},
        raw => q{=8'-0xA},
        key => q{actual:=8'-0xA},
        fsm_file => 'actual_literals.fsm',
        header => 'actual_literals',
    );
    is($intent_sized->{kind}, 'actual_literal', 'intent-sized exact-width actual preserves literal kind');
    is($intent_sized->{port}{width}, 8, 'intent-sized exact-width actual preserves declared width');
    is_deeply(
        $intent_sized->{connection_expr},
        bit_vector_literal_expr('11110110'),
        'intent-sized exact-width actual lowers through normalized two-complement bits',
    );

    my $ambiguous_direct_error = do {
        local $@;
        eval {
            FSM::Composition::ActualLiteralSupport->resolve_actual_payload(
                '00001110',
                raw => '=00001110',
                key => 'actual:=00001110',
                fsm_file => 'actual_literals.fsm',
                header => 'actual_literals',
            );
        };
        $@;
    };
    like(
        $ambiguous_direct_error,
        qr/uses actual endpoint '=00001110'.*ambiguous bare integer literal.*=0b00001110.*=N'b00001110.*=0d00001110/s,
        'direct actual support rejects ambiguous bare bitstring-looking payloads',
    );
};

subtest 'actual literal support keeps concat operands intrinsic width' => sub {
    is_deeply(
        [FSM::Composition::ActualLiteralSupport->expression_literal_bits_and_width('0b1_0')],
        ['10', 2],
        'unsized binary concat operand keeps digit-implied width',
    );
    is_deeply(
        [FSM::Composition::ActualLiteralSupport->expression_literal_bits_and_width('170')],
        ['10101010', 8],
        'unsized decimal concat operand keeps numeric intrinsic width',
    );
    is_deeply(
        [FSM::Composition::ActualLiteralSupport->expression_literal_bits_and_width('-1')],
        ['1', 1],
        'unsized signed decimal concat operand keeps minimum signed width',
    );
    is_deeply(
        [FSM::Composition::ActualLiteralSupport->expression_literal_bits_and_width(q{8'sd-1})],
        ['11111111', 8],
        'exact-width signed decimal concat operand keeps declared width',
    );
    is_deeply(
        [FSM::Composition::ActualLiteralSupport->expression_literal_bits_and_width(q{5'23})],
        ['10111', 5],
        'intent-sized decimal concat operand keeps declared width',
    );
    is_deeply(
        [FSM::Composition::ActualLiteralSupport->expression_literal_bits_and_width(q{20'x1})],
        ['00000000000000000001', 20],
        'intent-sized x-radix concat operand lowers through legal binary bits',
    );

    my $ambiguous_concat_error = do {
        local $@;
        eval {
            FSM::Composition::ActualLiteralSupport->expression_literal_bits_and_width(
                '00001110',
                raw => '=00001110',
                fsm_file => 'actual_literals.fsm',
                header => 'actual_literals',
            );
        };
        $@;
    };
    like(
        $ambiguous_concat_error,
        qr/uses literal actual '=00001110' inside a top expression.*ambiguous bare integer literal.*=0b00001110.*=N'b00001110.*=0d00001110/s,
        'concat literal support rejects ambiguous bare bitstring-looking payloads',
    );
};

subtest 'actual literal support widens direct actuals against target width' => sub {
    my $one = FSM::Composition::ActualLiteralSupport->resolve_actual_payload(
        '1',
        raw => '=1',
        key => 'actual:=1',
        fsm_file => 'actual_literals.fsm',
        header => 'actual_literals',
    );
    is_deeply(
        FSM::Composition::ActualLiteralSupport->actual_connection_expr_for_target(
            $one,
            4,
            'actual_literals.fsm',
            'actual_literals',
        ),
        bit_vector_literal_expr('0001'),
        'scalar one direct actual widens to the target width',
    );

    my $hex = FSM::Composition::ActualLiteralSupport->resolve_actual_payload(
        '0x10',
        raw => '=0x10',
        key => 'actual:=0x10',
        fsm_file => 'actual_literals.fsm',
        header => 'actual_literals',
    );
    my $overflow = do {
        local $@;
        eval {
            FSM::Composition::ActualLiteralSupport->actual_connection_expr_for_target(
                $hex,
                4,
                'actual_literals.fsm',
                'actual_literals',
            );
        };
        $@;
    };
    like(
        $overflow,
        qr/unsized hex actual value does not fit direct target width 4/,
        'unsigned target-width lowering rejects overflowing direct hex actuals',
    );

    ok(
        FSM::Composition::ActualLiteralSupport->is_target_width_bound_actual_kind('actual_unsized_decimal'),
        'support exposes the shared target-width-bound actual-kind predicate',
    );
};

done_testing();
