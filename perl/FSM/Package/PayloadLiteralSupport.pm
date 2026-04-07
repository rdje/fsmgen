package FSM::Package::PayloadLiteralSupport;

use v5.20;
use strict;
use warnings;
use Math::BigInt;
use feature qw(signatures);
no warnings 'experimental::signatures';

sub payload_to_bits_and_width ($class, $payload) {
    return $class->_payload_to_bits_and_width($payload);
}

sub _payload_to_bits_and_width ($class, $payload) {
    return (undef, undef, 'missing_payload') unless defined $payload;

    if (!ref($payload)) {
        my ($bits, $width) = $class->_scalar_literal_bits_and_width($payload);
        return (defined($bits) ? ($bits, $width, undef) : (undef, undef, 'unsupported_scalar'));
    }

    return (undef, undef, 'malformed_payload') unless ref($payload) eq 'HASH';

    my $kind = $payload->{kind} || '';
    if ($kind eq 'scalar') {
        my ($bits, $width) = $class->_scalar_literal_bits_and_width($payload->{payload});
        return (defined($bits) ? ($bits, $width, undef) : (undef, undef, 'unsupported_scalar'));
    }

    if ($kind eq 'list') {
        my @item_bits;
        my $total_width = 0;

        for my $item (@{$payload->{items} || []}) {
            my ($bits, $width, $reason) = $class->_payload_to_bits_and_width($item);
            return (undef, undef, $reason) unless defined $bits;
            push @item_bits, $bits;
            $total_width += $width;
        }

        return (undef, undef, 'empty_list') unless @item_bits;
        return (join('', @item_bits), $total_width, undef);
    }

    if ($kind eq 'map') {
        return (undef, undef, 'hash_aggregate');
    }

    return (undef, undef, 'malformed_payload');
}

sub _scalar_literal_bits_and_width ($class, $payload_text) {
    return unless defined($payload_text) && !ref($payload_text);

    if ($payload_text =~ /\A(\d+)'b([01]+)\z/i) {
        return $class->_binary_literal_bits_and_width($1, $2);
    }

    if ($payload_text =~ /\A(\d+)'d([0-9]+)\z/i) {
        return $class->_decimal_literal_bits_and_width($1, $2);
    }

    if ($payload_text =~ /\A(\d+)'h([0-9A-Fa-f]+)\z/i) {
        return $class->_hex_literal_bits_and_width($1, $2);
    }

    if ($payload_text =~ /\A([0-9]+)\z/) {
        return $class->_intrinsic_decimal_literal_bits_and_width($1);
    }

    return;
}

sub _normalized_digits ($class, $text, $allowed_pattern) {
    return undef unless defined($text) && !ref($text);
    return undef unless defined($allowed_pattern) && length($allowed_pattern);

    my $digits = $text;
    $digits =~ s/_//g;
    return undef unless length($digits) && $digits =~ /\A(?:$allowed_pattern)+\z/;
    return $digits;
}

sub _binary_literal_bits_and_width ($class, $declared_width, $binary_bits) {
    return unless defined($declared_width) && $declared_width =~ /\A\d+\z/ && $declared_width > 0;
    $binary_bits = $class->_normalized_digits($binary_bits, '[01]');
    return unless defined $binary_bits;

    my $bits = $binary_bits;
    if (length($bits) < $declared_width) {
        $bits = ('0' x ($declared_width - length($bits))) . $bits;
        return ($bits, 0 + $declared_width);
    }

    if (length($bits) > $declared_width) {
        my $overflow_bits = substr($bits, 0, length($bits) - $declared_width);
        return unless $overflow_bits !~ /1/;
        $bits = substr($bits, -$declared_width);
    }

    return ($bits, 0 + $declared_width);
}

sub _decimal_literal_bits_and_width ($class, $declared_width, $decimal_digits) {
    return unless defined($declared_width) && $declared_width =~ /\A\d+\z/ && $declared_width > 0;
    $decimal_digits = $class->_normalized_digits($decimal_digits, '[0-9]');
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

    return unless length($bits) <= $declared_width;
    return ($bits, 0 + $declared_width);
}

sub _hex_literal_bits_and_width ($class, $declared_width, $hex_digits) {
    return unless defined($declared_width) && $declared_width =~ /\A\d+\z/ && $declared_width > 0;
    $hex_digits = $class->_normalized_digits($hex_digits, '[0-9A-Fa-f]');
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
        return unless $overflow_bits !~ /1/;
        $bits = substr($bits, -$declared_width);
    }

    return ($bits, 0 + $declared_width);
}

sub _intrinsic_decimal_literal_bits_and_width ($class, $decimal_digits) {
    $decimal_digits = $class->_normalized_digits($decimal_digits, '[0-9]');
    return unless defined $decimal_digits;

    my $value = Math::BigInt->new($decimal_digits);
    return unless defined $value;

    my $bits = $value->as_bin();
    $bits =~ s/\A0b//;
    $bits = '0' unless length $bits;

    return ($bits, length($bits));
}

1;
