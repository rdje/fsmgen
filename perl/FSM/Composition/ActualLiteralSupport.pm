package FSM::Composition::ActualLiteralSupport;

=head1 NAME

FSM::Composition::ActualLiteralSupport - Composition actual literal lowering

=head1 DESCRIPTION

Owns the bounded numeric/open actual literal forms accepted by composition
links. Direct actual bindings use target-width lowering for unsized forms, while
top-expression concat operands use intrinsic-width lowering.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use Carp qw(confess);
use Math::BigInt;

use FSM::IR::StructuralRTLIR::ConnectionExpr qw(
    bit_vector_literal_expr
    open_expr
);
use FSM::Package::IntegerLiteralSupport;
use FSM::Package::PayloadTypeSupport;

sub resolve_actual_payload ($class, $payload, %opts) {
    return undef unless defined($payload) && !ref($payload) && length($payload);

    my $raw = $opts{raw} // "=$payload";
    my $key = $opts{key} // "actual:$raw";
    my $fsm_file = $opts{fsm_file};
    my $header = $opts{header};

    if ($payload eq 'open') {
        return {
            raw => $raw,
            key => $key,
            kind => 'actual_open',
            port => {
                direction => 'actual',
                width => 0,
            },
            connection_expr => open_expr(),
        };
    }

    if ($payload =~ /\A([01])\z/) {
        return {
            raw => $raw,
            key => $key,
            kind => 'actual_scalar_literal',
            scalar_bit => $1,
            port => {
                direction => 'actual',
                width => 1,
            },
            connection_expr => bit_vector_literal_expr($1),
        };
    }

    if ($payload =~ /\A'b(.+)\z/i) {
        my $binary_bits = $class->_normalized_separated_digits($1, '[01]');
        return {
            raw => $raw,
            key => $key,
            kind => 'actual_unsized_binary',
            binary_bits => $binary_bits,
            port => {
                direction => 'actual',
                width => 0,
            },
        } if defined $binary_bits;
    }

    if ($payload =~ /\A0b(.+)\z/i) {
        my $binary_bits = $class->_normalized_separated_digits($1, '[01]');
        return {
            raw => $raw,
            key => $key,
            kind => 'actual_unsized_binary',
            binary_bits => $binary_bits,
            port => {
                direction => 'actual',
                width => 0,
            },
        } if defined $binary_bits;
    }

    if ($payload =~ /\A'sd(-?(?:[0-9](?:_?[0-9])*))\z/i) {
        if ($1 =~ /\A-(.+)\z/) {
            my $decimal_digits = $class->_normalized_separated_digits($1, '[0-9]');
            return {
                raw => $raw,
                key => $key,
                kind => 'actual_unsized_signed_decimal',
                decimal_digits => $decimal_digits,
                port => {
                    direction => 'actual',
                    width => 0,
                },
            } if defined $decimal_digits;
        }
    }

    if ($payload =~ /\A'sb(.+)\z/i) {
        my $binary_bits = $class->_normalized_separated_digits($1, '[01]');
        return {
            raw => $raw,
            key => $key,
            kind => 'actual_unsized_signed_binary',
            binary_bits => $binary_bits,
            port => {
                direction => 'actual',
                width => 0,
            },
        } if defined $binary_bits;
    }

    if ($payload =~ /\A'd(.+)\z/i) {
        my $decimal_digits = $class->_normalized_separated_digits($1, '[0-9]');
        return {
            raw => $raw,
            key => $key,
            kind => 'actual_unsized_decimal',
            decimal_digits => $decimal_digits,
            port => {
                direction => 'actual',
                width => 0,
            },
        } if defined $decimal_digits;
    }

    if ($payload =~ /\A0d(.+)\z/i) {
        if ($1 =~ /\A-(.+)\z/) {
            my $decimal_digits = $class->_normalized_separated_digits($1, '[0-9]');
            return {
                raw => $raw,
                key => $key,
                kind => 'actual_unsized_signed_decimal',
                decimal_digits => $decimal_digits,
                port => {
                    direction => 'actual',
                    width => 0,
                },
            } if defined $decimal_digits;
        }

        my $decimal_digits = $class->_normalized_separated_digits($1, '[0-9]');
        return {
            raw => $raw,
            key => $key,
            kind => 'actual_unsized_decimal',
            decimal_digits => $decimal_digits,
            port => {
                direction => 'actual',
                width => 0,
            },
        } if defined $decimal_digits;
    }

    if ($payload =~ /\A-(.+)\z/) {
        my $decimal_digits = $class->_normalized_separated_digits($1, '[0-9]');
        return {
            raw => $raw,
            key => $key,
            kind => 'actual_unsized_signed_decimal',
            decimal_digits => $decimal_digits,
            port => {
                direction => 'actual',
                width => 0,
            },
        } if defined $decimal_digits;
    }

    if ($payload =~ /\A'so(.+)\z/i) {
        my $octal_digits = $class->_normalized_separated_digits($1, '[0-7]');
        return {
            raw => $raw,
            key => $key,
            kind => 'actual_unsized_signed_octal',
            octal_digits => $octal_digits,
            port => {
                direction => 'actual',
                width => 0,
            },
        } if defined $octal_digits;
    }

    if ($payload =~ /\A'o(.+)\z/i) {
        my $octal_digits = $class->_normalized_separated_digits($1, '[0-7]');
        return {
            raw => $raw,
            key => $key,
            kind => 'actual_unsized_octal',
            octal_digits => $octal_digits,
            port => {
                direction => 'actual',
                width => 0,
            },
        } if defined $octal_digits;
    }

    if ($payload =~ /\A0o(.+)\z/i) {
        my $octal_digits = $class->_normalized_separated_digits($1, '[0-7]');
        return {
            raw => $raw,
            key => $key,
            kind => 'actual_unsized_octal',
            octal_digits => $octal_digits,
            port => {
                direction => 'actual',
                width => 0,
            },
        } if defined $octal_digits;
    }

    if ($payload =~ /\A'sh(.+)\z/i) {
        my $hex_digits = $class->_normalized_separated_digits($1, '[0-9A-Fa-f]');
        return {
            raw => $raw,
            key => $key,
            kind => 'actual_unsized_signed_hex',
            hex_digits => $hex_digits,
            port => {
                direction => 'actual',
                width => 0,
            },
        } if defined $hex_digits;
    }

    if ($payload =~ /\A'h(.+)\z/i) {
        my $hex_digits = $class->_normalized_separated_digits($1, '[0-9A-Fa-f]');
        return {
            raw => $raw,
            key => $key,
            kind => 'actual_unsized_hex',
            hex_digits => $hex_digits,
            port => {
                direction => 'actual',
                width => 0,
            },
        } if defined $hex_digits;
    }

    if ($payload =~ /\A0x(.+)\z/i) {
        my $hex_digits = $class->_normalized_separated_digits($1, '[0-9A-Fa-f]');
        return {
            raw => $raw,
            key => $key,
            kind => 'actual_unsized_hex',
            hex_digits => $hex_digits,
            port => {
                direction => 'actual',
                width => 0,
            },
        } if defined $hex_digits;
    }

    $class->_confess_on_ambiguous_bare_actual_literal(
        $payload,
        %opts,
        lane => 'direct_actual',
        raw => $raw,
    );

    my $bare_decimal_digits = $class->_normalized_separated_digits($payload, '[0-9]');
    if (defined $bare_decimal_digits) {
        return {
            raw => $raw,
            key => $key,
            kind => 'actual_unsized_decimal',
            decimal_digits => $bare_decimal_digits,
            port => {
                direction => 'actual',
                width => 0,
            },
        };
    }

    my $bare_hex_digits = $class->_normalized_separated_digits($payload, '[0-9A-Fa-f]');
    if (defined($bare_hex_digits) && $bare_hex_digits =~ /[A-Fa-f]/) {
        return {
            raw => $raw,
            key => $key,
            kind => 'actual_unsized_hex',
            hex_digits => $bare_hex_digits,
            port => {
                direction => 'actual',
                width => 0,
            },
        };
    }

    my ($bits, $width) = $class->literal_bits_and_width(
        $payload,
        fsm_file => $fsm_file,
        header => $header,
    );
    return {
        raw => $raw,
        key => $key,
        kind => 'actual_literal',
        port => {
            direction => 'actual',
            width => $width,
        },
        connection_expr => bit_vector_literal_expr($bits),
    };
}

sub literal_bits_and_width ($class, $payload, %opts) {
    my $fsm_file = $opts{fsm_file};
    my $header = $opts{header};

    if ($payload =~ /\A(\d+)'sb(.+)\z/i) {
        my ($declared_width, $raw_bits) = ($1, $2);
        my $bits = $class->_normalized_separated_digits($raw_bits, '[01]');
        return undef unless defined $bits;
        confess
            "Composition source '$header' in '$fsm_file' uses actual literal '=$payload', ".
            "but explicit actual binding is blocked because the declared signed binary width does not match the literal payload length. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless length($bits) == $declared_width;
        return ($bits, 0 + $declared_width);
    }

    if ($payload =~ /\A(\d+)'sd(-?(?:[0-9](?:_?[0-9])*))\z/i) {
        my ($declared_width, $signed_decimal_text) = ($1, $2);
        my ($bits, $width) = $class->_signed_decimal_literal_bits_and_width(
            $declared_width,
            $signed_decimal_text,
            on_overflow => sub {
                return
                    "Composition source '$header' in '$fsm_file' uses actual literal '=$payload', ".
                    "but explicit actual binding is blocked because the declared signed decimal width cannot represent the literal payload value. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            },
        );
        return ($bits, $width) if defined $bits;
    }

    if ($payload =~ /\A(\d+)'b(.+)\z/i) {
        my ($declared_width, $raw_bits) = ($1, $2);
        my $bits = $class->_normalized_separated_digits($raw_bits, '[01]');
        return undef unless defined $bits;
        confess
            "Composition source '$header' in '$fsm_file' uses actual literal '=$payload', ".
            "but explicit actual binding is blocked because the declared binary width does not match the literal payload length. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless length($bits) == $declared_width;
        return ($bits, 0 + $declared_width);
    }

    if ($payload =~ /\A(\d+)'d(.+)\z/i) {
        my ($declared_width, $raw_decimal_digits) = ($1, $2);
        my $decimal_digits = $class->_normalized_separated_digits($raw_decimal_digits, '[0-9]');
        return undef unless defined $decimal_digits;
        my ($bits, $width) = $class->_decimal_literal_bits_and_width(
            $declared_width,
            $decimal_digits,
            on_overflow => sub {
                return
                    "Composition source '$header' in '$fsm_file' uses actual literal '=$payload', ".
                    "but explicit actual binding is blocked because the declared decimal width cannot represent the literal payload value. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            },
        );
        return ($bits, $width) if defined $bits;
    }

    if ($payload =~ /\A(\d+)'o(.+)\z/i) {
        my ($declared_width, $raw_octal_digits) = ($1, $2);
        my $octal_digits = $class->_normalized_separated_digits($raw_octal_digits, '[0-7]');
        return undef unless defined $octal_digits;
        my ($bits, $width) = $class->_octal_literal_bits_and_width(
            $declared_width,
            $octal_digits,
            on_overflow => sub {
                return
                    "Composition source '$header' in '$fsm_file' uses actual literal '=$payload', ".
                    "but explicit actual binding is blocked because the declared octal width cannot represent the literal payload value. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            },
        );
        return ($bits, $width) if defined $bits;
    }

    if ($payload =~ /\A(\d+)'so(.+)\z/i) {
        my ($declared_width, $raw_octal_digits) = ($1, $2);
        my $octal_digits = $class->_normalized_separated_digits($raw_octal_digits, '[0-7]');
        return undef unless defined $octal_digits;
        my ($bits, $width) = $class->_octal_literal_bits_and_width(
            $declared_width,
            $octal_digits,
            on_overflow => sub {
                return
                    "Composition source '$header' in '$fsm_file' uses actual literal '=$payload', ".
                    "but explicit actual binding is blocked because the declared signed octal width cannot represent the literal payload value. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            },
        );
        return ($bits, $width) if defined $bits;
    }

    if ($payload =~ /\A(\d+)'h(.+)\z/i) {
        my ($declared_width, $raw_hex_digits) = ($1, $2);
        my $hex_digits = $class->_normalized_separated_digits($raw_hex_digits, '[0-9A-Fa-f]');
        return undef unless defined $hex_digits;
        my ($bits, $width) = $class->_hex_literal_bits_and_width(
            $declared_width,
            $hex_digits,
            on_overflow => sub {
                return
                    "Composition source '$header' in '$fsm_file' uses actual literal '=$payload', ".
                    "but explicit actual binding is blocked because the declared hex width cannot represent the literal payload value. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            },
        );
        return ($bits, $width) if defined $bits;
    }

    if ($payload =~ /\A(\d+)'sh(.+)\z/i) {
        my ($declared_width, $raw_hex_digits) = ($1, $2);
        my $hex_digits = $class->_normalized_separated_digits($raw_hex_digits, '[0-9A-Fa-f]');
        return undef unless defined $hex_digits;
        my ($bits, $width) = $class->_hex_literal_bits_and_width(
            $declared_width,
            $hex_digits,
            on_overflow => sub {
                return
                    "Composition source '$header' in '$fsm_file' uses actual literal '=$payload', ".
                    "but explicit actual binding is blocked because the declared signed hex width cannot represent the literal payload value. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            },
        );
        return ($bits, $width) if defined $bits;
    }

    my $intent_parts = FSM::Package::IntegerLiteralSupport->literal_parts_from_scalar($payload);
    if ($intent_parts && defined($intent_parts->{width})) {
        my $binary_payload = FSM::Package::IntegerLiteralSupport->core_literal_payload_from_parts(
            %$intent_parts,
            radix => 'binary',
        );
        if (ref($binary_payload) eq 'HASH' && defined($binary_payload->{width}) && defined($binary_payload->{value})) {
            my $bits = $class->_pad_binary_bits_to_width($binary_payload->{value}, $binary_payload->{width});
            return ($bits, 0 + $binary_payload->{width});
        }
    }

    confess
        "Composition source '$header' in '$fsm_file' uses actual endpoint '=$payload', ".
        "but explicit actual binding is blocked because the first structural-actual slice currently accepts only '=open', scalar '=0'/'=1', named literal actuals from composition-root '+constants' / '+enums' or imported packages like '=RESET_BYTE', '=mode.BUSY', '=shared.RESET_BYTE', or '=shared.mode.BUSY', unsized binary/decimal/octal/hex direct actual forms like '=0b10', '='b10', '=0d10', '='d10', '=0o7', '='o7', '=0xA', '='hA', '=170', or '=A5', unsized signed decimal direct actual forms like '=-1', '=0d-1', or '='sd-1', unsized signed binary/octal/hex direct actual forms like '='sb1010', '='so7', or '='shA', or exact-width binary/decimal/octal/hex literal forms in unsigned or signed form like '=8'b10100101', '=8'sb10100101', '=8'd165', '=8'sd-1', '=8'o245', '=8'so245', '=8'hA5', or '=8'shA5'. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
}

sub expression_literal_bits_and_width ($class, $payload, %opts) {
    return ($1, 1)
        if defined($payload) && $payload =~ /\A([01])\z/;

    if (defined($payload) && $payload =~ /\A0b(.+)\z/i) {
        my $binary_bits = $class->_normalized_separated_digits($1, '[01]');
        return undef unless defined $binary_bits;
        return ($binary_bits, length($binary_bits));
    }

    if (defined($payload) && $payload =~ /\A'b(.+)\z/i) {
        my $binary_bits = $class->_normalized_separated_digits($1, '[01]');
        return undef unless defined $binary_bits;
        return ($binary_bits, length($binary_bits));
    }

    if (defined($payload) && $payload =~ /\A'sb(.+)\z/i) {
        my $binary_bits = $class->_normalized_separated_digits($1, '[01]');
        return undef unless defined $binary_bits;
        return ($binary_bits, length($binary_bits));
    }

    if (defined($payload) && $payload =~ /\A0o(.+)\z/i) {
        my $octal_digits = $class->_normalized_separated_digits($1, '[0-7]');
        return undef unless defined $octal_digits;
        return $class->_octal_literal_bits_and_width(length($octal_digits) * 3, $octal_digits);
    }

    if (defined($payload) && $payload =~ /\A'so(.+)\z/i) {
        my $octal_digits = $class->_normalized_separated_digits($1, '[0-7]');
        return undef unless defined $octal_digits;
        return $class->_octal_literal_bits_and_width(length($octal_digits) * 3, $octal_digits);
    }

    if (defined($payload) && $payload =~ /\A'o(.+)\z/i) {
        my $octal_digits = $class->_normalized_separated_digits($1, '[0-7]');
        return undef unless defined $octal_digits;
        return $class->_octal_literal_bits_and_width(length($octal_digits) * 3, $octal_digits);
    }

    if (defined($payload) && $payload =~ /\A0x(.+)\z/i) {
        my $hex_digits = $class->_normalized_separated_digits($1, '[0-9A-Fa-f]');
        return undef unless defined $hex_digits;
        return $class->_hex_literal_bits_and_width(length($hex_digits) * 4, $hex_digits);
    }

    if (defined($payload) && $payload =~ /\A'h(.+)\z/i) {
        my $hex_digits = $class->_normalized_separated_digits($1, '[0-9A-Fa-f]');
        return undef unless defined $hex_digits;
        return $class->_hex_literal_bits_and_width(length($hex_digits) * 4, $hex_digits);
    }

    if (defined($payload) && $payload =~ /\A'sh(.+)\z/i) {
        my $hex_digits = $class->_normalized_separated_digits($1, '[0-9A-Fa-f]');
        return undef unless defined $hex_digits;
        return $class->_hex_literal_bits_and_width(length($hex_digits) * 4, $hex_digits);
    }

    if (defined($payload) && $payload =~ /\A'sd(-?(?:[0-9](?:_?[0-9])*))\z/i) {
        my $signed_decimal_text = $1;
        return undef unless $signed_decimal_text =~ /\A-/;
        return $class->_intrinsic_signed_decimal_literal_bits_and_width($signed_decimal_text);
    }

    if (defined($payload) && $payload =~ /\A0d(.+)\z/i) {
        my $decimal_text = $1;
        if ($decimal_text =~ /\A-/) {
            return $class->_intrinsic_signed_decimal_literal_bits_and_width($decimal_text);
        }
        my $decimal_digits = $class->_normalized_separated_digits($decimal_text, '[0-9]');
        return undef unless defined $decimal_digits;
        return $class->_intrinsic_decimal_literal_bits_and_width($decimal_digits);
    }

    if (defined($payload) && $payload =~ /\A'd(.+)\z/i) {
        my $decimal_digits = $class->_normalized_separated_digits($1, '[0-9]');
        return undef unless defined $decimal_digits;
        return $class->_intrinsic_decimal_literal_bits_and_width($decimal_digits);
    }

    if (defined($payload) && $payload =~ /\A-(.+)\z/) {
        my $decimal_digits = $class->_normalized_separated_digits($1, '[0-9]');
        return undef unless defined $decimal_digits;
        return $class->_intrinsic_signed_decimal_literal_bits_and_width("-$decimal_digits");
    }

    my $bare_hex_digits = $class->_normalized_separated_digits($payload, '[0-9A-Fa-f]');
    if (defined($bare_hex_digits) && $bare_hex_digits =~ /[A-Fa-f]/ && $payload !~ /\A0d/i) {
        return $class->_hex_literal_bits_and_width(length($bare_hex_digits) * 4, $bare_hex_digits);
    }

    $class->_confess_on_ambiguous_bare_actual_literal(
        $payload,
        %opts,
        lane => 'concat_operand',
        raw => ($opts{raw} // "=$payload"),
    );

    my $bare_decimal_digits = $class->_normalized_separated_digits($payload, '[0-9]');
    if (defined $bare_decimal_digits) {
        return $class->_intrinsic_decimal_literal_bits_and_width($bare_decimal_digits);
    }

    if (defined($payload) && $payload =~ /\A(\d+)'b(.+)\z/i) {
        my ($declared_width, $raw_bits) = ($1, $2);
        my $bits = $class->_normalized_separated_digits($raw_bits, '[01]');
        return undef unless defined $bits;
        return undef unless length($bits) == $declared_width;
        return ($bits, 0 + $declared_width);
    }

    if (defined($payload) && $payload =~ /\A(\d+)'sb(.+)\z/i) {
        my ($declared_width, $raw_bits) = ($1, $2);
        my $bits = $class->_normalized_separated_digits($raw_bits, '[01]');
        return undef unless defined $bits;
        return undef unless length($bits) == $declared_width;
        return ($bits, 0 + $declared_width);
    }

    if (defined($payload) && $payload =~ /\A(\d+)'sd(-?(?:[0-9](?:_?[0-9])*))\z/i) {
        return $class->_signed_decimal_literal_bits_and_width($1, $2);
    }

    if (defined($payload) && $payload =~ /\A(\d+)'d(.+)\z/i) {
        my $decimal_digits = $class->_normalized_separated_digits($2, '[0-9]');
        return undef unless defined $decimal_digits;
        return $class->_decimal_literal_bits_and_width($1, $decimal_digits);
    }

    if (defined($payload) && $payload =~ /\A(\d+)'o(.+)\z/i) {
        my $octal_digits = $class->_normalized_separated_digits($2, '[0-7]');
        return undef unless defined $octal_digits;
        return $class->_octal_literal_bits_and_width($1, $octal_digits);
    }

    if (defined($payload) && $payload =~ /\A(\d+)'so(.+)\z/i) {
        my $octal_digits = $class->_normalized_separated_digits($2, '[0-7]');
        return undef unless defined $octal_digits;
        return $class->_octal_literal_bits_and_width($1, $octal_digits);
    }

    if (defined($payload) && $payload =~ /\A(\d+)'h(.+)\z/i) {
        my $hex_digits = $class->_normalized_separated_digits($2, '[0-9A-Fa-f]');
        return undef unless defined $hex_digits;
        return $class->_hex_literal_bits_and_width($1, $hex_digits);
    }

    if (defined($payload) && $payload =~ /\A(\d+)'sh(.+)\z/i) {
        my $hex_digits = $class->_normalized_separated_digits($2, '[0-9A-Fa-f]');
        return undef unless defined $hex_digits;
        return $class->_hex_literal_bits_and_width($1, $hex_digits);
    }

    my $intent_parts = FSM::Package::IntegerLiteralSupport->literal_parts_from_scalar($payload);
    if ($intent_parts && defined($intent_parts->{width})) {
        my $binary_payload = FSM::Package::IntegerLiteralSupport->core_literal_payload_from_parts(
            %$intent_parts,
            radix => 'binary',
        );
        if (ref($binary_payload) eq 'HASH' && defined($binary_payload->{width}) && defined($binary_payload->{value})) {
            my $bits = $class->_pad_binary_bits_to_width($binary_payload->{value}, $binary_payload->{width});
            return ($bits, 0 + $binary_payload->{width});
        }
    }

    return;
}

sub is_target_width_bound_actual_kind ($class, $kind) {
    return 0 unless defined($kind) && !ref($kind);
    return (
        $kind eq 'actual_scalar_literal'
            || $kind eq 'actual_unsized_binary'
            || $kind eq 'actual_unsized_decimal'
            || $kind eq 'actual_unsized_signed_decimal'
            || $kind eq 'actual_unsized_signed_binary'
            || $kind eq 'actual_unsized_signed_octal'
            || $kind eq 'actual_unsized_signed_hex'
            || $kind eq 'actual_unsized_octal'
            || $kind eq 'actual_unsized_hex'
    ) ? 1 : 0;
}

sub actual_connection_expr_for_target ($class, $source, $target_width, $fsm_file = undef, $header = undef) {
    return _clone($source->{connection_expr})
        unless ref($source) eq 'HASH' && (($source->{kind} || '') =~ /^actual_/);

    return _clone($source->{connection_expr})
        unless $class->is_target_width_bound_actual_kind($source->{kind} || '');

    confess "Scalar actuals require a positive target width before binding.\n"
        unless defined($target_width) && $target_width =~ /\A\d+\z/ && $target_width > 0;

    if (($source->{kind} || '') eq 'actual_scalar_literal') {
        my $scalar_bit = $source->{scalar_bit} // '';
        confess "Scalar actuals must preserve one-bit payload metadata.\n"
            unless $scalar_bit =~ /\A[01]\z/;

        my $bits = '0' x $target_width;
        substr($bits, -1, 1, $scalar_bit) if $scalar_bit eq '1';
        return bit_vector_literal_expr($bits);
    }

    if (($source->{kind} || '') eq 'actual_unsized_binary') {
        my $binary_bits = $source->{binary_bits} // '';
        my ($bits, undef) = $class->_binary_literal_bits_and_width(
            $target_width,
            $binary_bits,
            on_overflow => sub {
                return
                    "Composition source '$header' in '$fsm_file' uses actual literal '".$source->{raw}."', ".
                    "but explicit actual binding is blocked because unsized binary actual value does not fit direct target width $target_width. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            },
        );
        return bit_vector_literal_expr($bits);
    }

    if (($source->{kind} || '') eq 'actual_unsized_decimal') {
        my $decimal_digits = $source->{decimal_digits} // '';
        my ($bits, undef) = $class->_decimal_literal_bits_and_width(
            $target_width,
            $decimal_digits,
            on_overflow => sub {
                return
                    "Composition source '$header' in '$fsm_file' uses actual literal '".$source->{raw}."', ".
                    "but explicit actual binding is blocked because unsized decimal actual value does not fit direct target width $target_width. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            },
        );
        return bit_vector_literal_expr($bits);
    }

    if (($source->{kind} || '') eq 'actual_unsized_signed_decimal') {
        my $decimal_digits = $source->{decimal_digits} // '';
        my ($bits, undef) = $class->_signed_decimal_literal_bits_and_width(
            $target_width,
            "-$decimal_digits",
            on_overflow => sub {
                return
                    "Composition source '$header' in '$fsm_file' uses actual literal '".$source->{raw}."', ".
                    "but explicit actual binding is blocked because unsized signed decimal actual value does not fit signed direct target width $target_width. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            },
        );
        return bit_vector_literal_expr($bits);
    }

    if (($source->{kind} || '') eq 'actual_unsized_signed_binary') {
        my $binary_bits = $source->{binary_bits} // '';
        my ($bits, undef) = $class->_signed_bits_literal_bits_and_width(
            $target_width,
            $binary_bits,
            on_overflow => sub {
                return
                    "Composition source '$header' in '$fsm_file' uses actual literal '".$source->{raw}."', ".
                    "but explicit actual binding is blocked because unsized signed binary actual value does not fit signed direct target width $target_width. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            },
        );
        return bit_vector_literal_expr($bits);
    }

    if (($source->{kind} || '') eq 'actual_unsized_octal') {
        my $octal_digits = $source->{octal_digits} // '';
        my ($bits, undef) = $class->_octal_literal_bits_and_width(
            $target_width,
            $octal_digits,
            on_overflow => sub {
                return
                    "Composition source '$header' in '$fsm_file' uses actual literal '".$source->{raw}."', ".
                    "but explicit actual binding is blocked because unsized octal actual value does not fit direct target width $target_width. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            },
        );
        return bit_vector_literal_expr($bits);
    }

    if (($source->{kind} || '') eq 'actual_unsized_signed_octal') {
        my $octal_digits = $source->{octal_digits} // '';
        my ($intrinsic_bits, undef) = $class->_octal_literal_bits_and_width(length($octal_digits) * 3, $octal_digits);
        confess "Signed octal actuals must preserve intrinsic payload bits before widening.\n"
            unless defined $intrinsic_bits;
        my ($bits, undef) = $class->_signed_bits_literal_bits_and_width(
            $target_width,
            $intrinsic_bits,
            on_overflow => sub {
                return
                    "Composition source '$header' in '$fsm_file' uses actual literal '".$source->{raw}."', ".
                    "but explicit actual binding is blocked because unsized signed octal actual value does not fit signed direct target width $target_width. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            },
        );
        return bit_vector_literal_expr($bits);
    }

    if (($source->{kind} || '') eq 'actual_unsized_hex') {
        my $hex_digits = $source->{hex_digits} // '';
        my ($bits, undef) = $class->_hex_literal_bits_and_width(
            $target_width,
            $hex_digits,
            on_overflow => sub {
                return
                    "Composition source '$header' in '$fsm_file' uses actual literal '".$source->{raw}."', ".
                    "but explicit actual binding is blocked because unsized hex actual value does not fit direct target width $target_width. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            },
        );
        return bit_vector_literal_expr($bits);
    }

    if (($source->{kind} || '') eq 'actual_unsized_signed_hex') {
        my $hex_digits = $source->{hex_digits} // '';
        my ($intrinsic_bits, undef) = $class->_hex_literal_bits_and_width(length($hex_digits) * 4, $hex_digits);
        confess "Signed hex actuals must preserve intrinsic payload bits before widening.\n"
            unless defined $intrinsic_bits;
        my ($bits, undef) = $class->_signed_bits_literal_bits_and_width(
            $target_width,
            $intrinsic_bits,
            on_overflow => sub {
                return
                    "Composition source '$header' in '$fsm_file' uses actual literal '".$source->{raw}."', ".
                    "but explicit actual binding is blocked because unsized signed hex actual value does not fit signed direct target width $target_width. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            },
        );
        return bit_vector_literal_expr($bits);
    }

    confess "Unsupported actual kind '".$source->{kind}."' reached actual_connection_expr_for_target.\n";
}

sub binding_connection_type_contract ($class, $source, $target_width = undef) {
    my $aggregate_type_spec = $source->{aggregate_type_spec};
    if (ref($aggregate_type_spec) eq 'HASH') {
        return {
            connection_type_name => undef,
            connection_type_spec => $class->_clone_structured_value($aggregate_type_spec),
        };
    }

    return {
        connection_type_name => undef,
        connection_type_spec => undef,
    } if (($source->{kind} || '') eq 'actual_open');

    my $effective_width = $class->is_target_width_bound_actual_kind($source->{kind} || '')
        ? $target_width
        : $class->_endpoint_width($source);

    return {
        connection_type_name => undef,
        connection_type_spec => FSM::Package::PayloadTypeSupport->scalar_type_spec_from_width($effective_width),
    };
}

sub _normalized_separated_digits ($class, $text, $digit_class) {
    return undef unless defined($text) && !ref($text);
    return undef unless defined($digit_class) && !ref($digit_class) && length($digit_class);

    my $pattern = qr/\A(?:$digit_class)(?:_?(?:$digit_class))*\z/;
    return undef unless $text =~ $pattern;

    (my $normalized = $text) =~ s/_//g;
    return $normalized;
}

sub _decimal_literal_bits_and_width ($class, $declared_width, $decimal_digits, %opts) {
    return unless defined($declared_width) && $declared_width =~ /\A\d+\z/ && $declared_width > 0;
    $decimal_digits = $class->_normalized_separated_digits($decimal_digits, '[0-9]');
    return unless defined $decimal_digits;

    my $value = Math::BigInt->new($decimal_digits);
    return unless defined $value;

    my $bits = $value->as_bin();
    $bits =~ s/\A0b//;
    $bits = '0' unless length $bits;

    if (length($bits) < $declared_width) {
        $bits = ('0' x ($declared_width - length($bits))) . $bits;
        return ($bits, 0 + $declared_width);
    }

    if (length($bits) > $declared_width) {
        confess $opts{on_overflow}->()
            if $opts{on_overflow};
        return;
    }

    return ($bits, 0 + $declared_width);
}

sub _confess_on_ambiguous_bare_actual_literal ($class, $payload, %opts) {
    return unless FSM::Package::IntegerLiteralSupport->obviously_binary_like_bare_value_literal($payload);

    my ($binary_example, $decimal_example, $exact_width_example) =
        FSM::Package::IntegerLiteralSupport->explicit_examples_for_obviously_binary_like_bare_value_literal($payload);
    $binary_example = '='.$binary_example;
    $decimal_example = '='.$decimal_example;
    $exact_width_example = '='.$exact_width_example;

    my $raw = $opts{raw} // "=$payload";
    my $fsm_file = $opts{fsm_file};
    my $header = $opts{header};
    my $lane = $opts{lane} // 'direct_actual';

    my $prefix = (defined($fsm_file) && defined($header))
        ? "Composition source '$header' in '$fsm_file' "
        : "Composition actual-literal parsing ";

    my $context = $lane eq 'concat_operand'
        ? "uses literal actual '$raw' inside a top expression"
        : "uses actual endpoint '$raw'";
    my $blocking_clause = $lane eq 'concat_operand'
        ? "but explicit link endpoint resolution is blocked because"
        : "but explicit actual binding is blocked because";

    confess
        $prefix.$context.", ".
        $blocking_clause." '$payload' is an ambiguous bare integer literal. ".
        "FSMGen does not guess obviously bitstring-like bare 0/1 tokens on composition actual lanes. ".
        "Use '$binary_example' for intrinsic-width binary, '$exact_width_example' for exact-width binary, or '$decimal_example' if decimal was intended. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
}

sub _intrinsic_decimal_literal_bits_and_width ($class, $decimal_digits) {
    $decimal_digits = $class->_normalized_separated_digits($decimal_digits, '[0-9]');
    return unless defined $decimal_digits;

    my $value = Math::BigInt->new($decimal_digits);
    return unless defined $value;

    my $bits = $value->as_bin();
    $bits =~ s/\A0b//;
    $bits = '0' unless length $bits;

    return ($bits, length($bits));
}

sub _intrinsic_signed_decimal_literal_bits_and_width ($class, $signed_decimal_text) {
    return unless defined($signed_decimal_text) && !ref($signed_decimal_text);

    my $negative = ($signed_decimal_text =~ s/\A-//) ? 1 : 0;
    my $decimal_digits = $class->_normalized_separated_digits($signed_decimal_text, '[0-9]');
    return unless defined $decimal_digits;

    my $value = Math::BigInt->new($decimal_digits);
    return unless defined $value;
    $value->bneg() if $negative;

    return $class->_intrinsic_signed_integer_bits_and_width($value);
}

sub _intrinsic_signed_integer_bits_and_width ($class, $value) {
    return unless defined($value) && ref($value) && $value->isa('Math::BigInt');

    my $width = 1;
    if (!$value->is_neg()) {
        my $bits = $value->copy()->as_bin();
        $bits =~ s/\A0b//;
        my $bit_length = ($bits eq '0') ? 0 : length($bits);
        $width = $bit_length + 1 if $bit_length >= 1;
    }
    else {
        my $magnitude_minus_one = $value->copy()->bneg();
        $magnitude_minus_one->bdec();
        my $bits = $magnitude_minus_one->as_bin();
        $bits =~ s/\A0b//;
        my $bit_length = ($bits eq '0') ? 0 : length($bits);
        $width = $bit_length + 1 if $bit_length >= 1;
    }

    return $class->_signed_integer_bits_and_width($width, $value);
}

sub _signed_decimal_literal_bits_and_width ($class, $declared_width, $signed_decimal_text, %opts) {
    return unless defined($declared_width) && $declared_width =~ /\A\d+\z/ && $declared_width > 0;
    return unless defined($signed_decimal_text) && !ref($signed_decimal_text);

    my $negative = ($signed_decimal_text =~ s/\A-//) ? 1 : 0;
    my $decimal_digits = $class->_normalized_separated_digits($signed_decimal_text, '[0-9]');
    return unless defined $decimal_digits;

    my $value = Math::BigInt->new($decimal_digits);
    return unless defined $value;
    $value->bneg() if $negative;

    return $class->_signed_integer_bits_and_width($declared_width, $value, %opts);
}

sub _signed_integer_bits_and_width ($class, $declared_width, $value, %opts) {
    return unless defined($declared_width) && $declared_width =~ /\A\d+\z/ && $declared_width > 0;
    return unless defined($value) && ref($value) && $value->isa('Math::BigInt');

    my $min_value = Math::BigInt->bone();
    $min_value->blsft($declared_width - 1);
    $min_value->bneg();

    my $max_value = Math::BigInt->bone();
    $max_value->blsft($declared_width - 1);
    $max_value->bdec();

    if ($value->copy()->bcmp($min_value) < 0 || $value->copy()->bcmp($max_value) > 0) {
        confess $opts{on_overflow}->()
            if $opts{on_overflow};
        return;
    }

    my $normalized_value = $value->copy();
    if ($normalized_value->is_neg()) {
        my $modulus = Math::BigInt->bone();
        $modulus->blsft($declared_width);
        $normalized_value->badd($modulus);
    }

    my $bits = $normalized_value->as_bin();
    $bits =~ s/\A0b//;
    $bits = '0' unless length $bits;

    if (length($bits) < $declared_width) {
        $bits = ('0' x ($declared_width - length($bits))) . $bits;
    }

    return ($bits, 0 + $declared_width);
}

sub _signed_bits_literal_bits_and_width ($class, $declared_width, $raw_bits, %opts) {
    return unless defined($declared_width) && $declared_width =~ /\A\d+\z/ && $declared_width > 0;
    $raw_bits = $class->_normalized_separated_digits($raw_bits, '[01]');
    return unless defined $raw_bits;

    my $intrinsic_width = length($raw_bits);
    return unless $intrinsic_width > 0;

    my $value = Math::BigInt->from_bin('0b'.$raw_bits);
    return unless defined $value;

    if (substr($raw_bits, 0, 1) eq '1') {
        my $modulus = Math::BigInt->bone();
        $modulus->blsft($intrinsic_width);
        $value->bsub($modulus);
    }

    return $class->_signed_integer_bits_and_width($declared_width, $value, %opts);
}

sub _binary_literal_bits_and_width ($class, $declared_width, $binary_bits, %opts) {
    return unless defined($declared_width) && $declared_width =~ /\A\d+\z/ && $declared_width > 0;
    $binary_bits = $class->_normalized_separated_digits($binary_bits, '[01]');
    return unless defined $binary_bits;

    my $bits = $binary_bits;
    if (length($bits) < $declared_width) {
        $bits = ('0' x ($declared_width - length($bits))) . $bits;
        return ($bits, 0 + $declared_width);
    }

    if (length($bits) > $declared_width) {
        my $overflow_bits = substr($bits, 0, length($bits) - $declared_width);
        if ($overflow_bits =~ /1/) {
            confess $opts{on_overflow}->()
                if $opts{on_overflow};
            return;
        }
        $bits = substr($bits, -$declared_width);
    }

    return ($bits, 0 + $declared_width);
}

sub _octal_literal_bits_and_width ($class, $declared_width, $octal_digits, %opts) {
    return unless defined($declared_width) && $declared_width =~ /\A\d+\z/ && $declared_width > 0;
    $octal_digits = $class->_normalized_separated_digits($octal_digits, '[0-7]');
    return unless defined $octal_digits;

    my %octal_bits = (
        0 => '000',
        1 => '001',
        2 => '010',
        3 => '011',
        4 => '100',
        5 => '101',
        6 => '110',
        7 => '111',
    );

    my $bits = join '', map { $octal_bits{$_} } split //, $octal_digits;
    if (length($bits) < $declared_width) {
        $bits = ('0' x ($declared_width - length($bits))) . $bits;
        return ($bits, 0 + $declared_width);
    }

    if (length($bits) > $declared_width) {
        my $overflow_bits = substr($bits, 0, length($bits) - $declared_width);
        if ($overflow_bits =~ /1/) {
            confess $opts{on_overflow}->()
                if $opts{on_overflow};
            return;
        }
        $bits = substr($bits, -$declared_width);
    }

    return ($bits, 0 + $declared_width);
}

sub _hex_literal_bits_and_width ($class, $declared_width, $hex_digits, %opts) {
    return unless defined($declared_width) && $declared_width =~ /\A\d+\z/ && $declared_width > 0;
    $hex_digits = $class->_normalized_separated_digits($hex_digits, '[0-9A-Fa-f]');
    return unless defined $hex_digits;

    my %hex_bits = (
        0 => '0000',
        1 => '0001',
        2 => '0010',
        3 => '0011',
        4 => '0100',
        5 => '0101',
        6 => '0110',
        7 => '0111',
        8 => '1000',
        9 => '1001',
        a => '1010',
        b => '1011',
        c => '1100',
        d => '1101',
        e => '1110',
        f => '1111',
    );

    my $bits = join '', map { $hex_bits{lc($_)} } split //, $hex_digits;
    if (length($bits) < $declared_width) {
        $bits = ('0' x ($declared_width - length($bits))) . $bits;
        return ($bits, 0 + $declared_width);
    }

    if (length($bits) > $declared_width) {
        my $overflow_bits = substr($bits, 0, length($bits) - $declared_width);
        if ($overflow_bits =~ /1/) {
            confess $opts{on_overflow}->()
                if $opts{on_overflow};
            return;
        }
        $bits = substr($bits, -$declared_width);
    }

    return ($bits, 0 + $declared_width);
}

sub _endpoint_width ($class, $endpoint) {
    return $endpoint->{expr_width}
        if ref($endpoint) eq 'HASH' && defined $endpoint->{expr_width};

    my $port = ref($endpoint) eq 'HASH' ? $endpoint->{port} : undef;
    return 0 unless $port;
    return $port->{width} if ref($port) eq 'HASH';
    return $port->width if ref($port) && $port->can('width');
    return 0;
}

sub _pad_binary_bits_to_width ($class, $bits, $width) {
    return $bits unless defined($bits) && defined($width) && $width =~ /\A\d+\z/ && $width > 0;
    return $bits if length($bits) >= $width;
    return ('0' x ($width - length($bits))).$bits;
}

sub _clone_structured_value ($class, $value) {
    return undef unless defined $value;

    if (ref($value) eq 'HASH') {
        return {
            map { $_ => $class->_clone_structured_value($value->{$_}) }
                keys %$value
        };
    }

    if (ref($value) eq 'ARRAY') {
        return [map { $class->_clone_structured_value($_) } @$value];
    }

    return $value;
}

sub _clone ($value) {
    return undef unless defined $value;

    if (ref($value) eq 'HASH') {
        return {
            map { $_ => _clone($value->{$_}) }
                keys %$value
        };
    }

    if (ref($value) eq 'ARRAY') {
        return [map { _clone($_) } @$value];
    }

    return $value;
}

1;

__END__

=head1 METHODS

=head2 resolve_actual_payload

Parses one actual payload into the normalized endpoint structure used by
composition planning.

=head2 literal_bits_and_width

Parses exact-width literal actuals and returns normalized bit text plus width.

=head2 expression_literal_bits_and_width

Parses concat-operand literal actuals using intrinsic-width rules for unsized
forms.

=head2 actual_connection_expr_for_target

Lowers one actual source into the structural connection expression appropriate
for the direct target width.

=head2 binding_connection_type_contract

Returns the structural binding type contract for one actual source.

=cut
