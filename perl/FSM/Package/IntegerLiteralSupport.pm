package FSM::Package::IntegerLiteralSupport;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Math::BigInt;
use Scalar::Util qw(blessed);
use feature qw(signatures);
no warnings 'experimental::signatures';

sub integer_from_literal_like ($class, $literal_like) {
    my $parts = $class->literal_parts_from_literal_like($literal_like);
    return undef unless $parts;
    return $parts->{value}->copy;
}

sub positive_integer_from_literal_like ($class, $literal_like) {
    my $value = $class->integer_from_literal_like($literal_like);
    return undef unless defined $value;
    return undef unless $value->bcmp(0) > 0;
    return 0 + $value->bstr;
}

sub integer_from_scalar ($class, $payload) {
    my $parts = $class->literal_parts_from_scalar($payload);
    return undef unless $parts;
    return $parts->{value}->copy;
}

sub literal_parts_from_literal_like ($class, $literal_like) {
    return undef unless defined $literal_like;

    if (ref($literal_like) eq 'HASH') {
        return undef unless ($literal_like->{kind} || '') eq 'scalar';
        return $class->literal_parts_from_literal_like($literal_like->{payload});
    }

    if (blessed($literal_like) && $literal_like->can('value')) {
        return $class->literal_parts_from_scalar($literal_like->value)
            unless $literal_like->can('radix');

        my $width = $literal_like->can('width') ? $literal_like->width : undef;
        my $radix = $class->_normalize_radix_name($literal_like->radix // 'decimal');
        my $value = $class->integer_from_parts($literal_like->value, $radix);

        return {
            value => $value,
            width => $width,
            radix => $radix,
            digits => $literal_like->value,
        } if defined $value;

        return $class->literal_parts_from_scalar($literal_like->value)
            unless defined $width;

        return undef;
    }

    return undef if ref($literal_like);
    return $class->literal_parts_from_scalar($literal_like);
}

sub systemverilog_literal_from_literal_like ($class, $literal_like) {
    my $parts = $class->literal_parts_from_literal_like($literal_like);
    return undef unless $parts;
    return $class->systemverilog_literal_from_parts(%$parts);
}

sub systemverilog_literal_from_parts ($class, %parts) {
    my $value = $parts{value};
    return undef unless defined $value && blessed($value) && $value->isa('Math::BigInt');

    my $width = $parts{width};
    my $radix = $class->_normalize_radix_name($parts{radix} // 'decimal');
    my $was_negative = $value->bcmp(0) < 0;

    if (!defined $width) {
        return $value->bstr if $was_negative || $radix eq 'decimal';

        my $digits = $parts{digits};
        $digits = $class->_digits_for_radix($value, $radix, undef, 0)
            unless defined($digits) && length($digits);
        $digits =~ s/\A[+-]//;
        return undef unless defined $digits && length $digits;

        my $prefix = $class->_systemverilog_radix_prefix($radix);
        return "'".$prefix.uc($digits) if $radix eq 'hex';
        return "'".$prefix.$digits;
    }

    return undef unless defined($width) && !ref($width) && $width =~ /\A\d+\z/ && $width > 0;

    my $encoded = $class->_encoded_value_for_width($value, $width);
    my $digits = $class->_digits_for_radix($encoded, $radix, $width, $was_negative);
    return undef unless defined $digits;

    my $prefix = $class->_systemverilog_radix_prefix($radix);
    return $width."'".$prefix.$digits;
}

sub core_literal_payload_from_parts ($class, %parts) {
    my $value = $parts{value};
    return undef unless defined $value && blessed($value) && $value->isa('Math::BigInt');

    my $width = $parts{width};
    my $radix = $class->_normalize_radix_name($parts{radix} // 'decimal');

    if (defined $width) {
        return undef unless defined($width) && !ref($width) && $width =~ /\A\d+\z/ && $width > 0;
        my $encoded = $class->_encoded_value_for_width($value, $width);
        return {
            value => $class->_digits_for_radix($encoded, $radix, $width, $value->bcmp(0) < 0),
            width => $width,
            radix => $radix,
        };
    }

    return {
        value => $value->bstr,
        radix => 'decimal',
    } if $value->bcmp(0) < 0 || $radix eq 'decimal';

    my $digits = $parts{digits};
    $digits =~ s/\A[+-]// if defined $digits;
    $digits = $class->_digits_for_radix($value, $radix, undef, 0)
        unless defined($digits) && length($digits);

    return {
        value => ($radix eq 'hex' ? uc($digits) : $digits),
        radix => $radix,
    };
}

sub literal_parts_from_scalar ($class, $payload) {
    return undef unless defined($payload) && !ref($payload);

    my $text = $payload;
    $text =~ s/_//g;

    if ($text =~ /\A([+-]?)(?:(\d+))?'(s?)([bodhx])([+-]?[0-9A-Fa-f]+)\z/i) {
        my ($outer_sign, $width, $radix, $digits) = ($1, $2, lc($4), $5);
        $radix = $class->_normalize_radix_name($radix);
        my $value = $class->integer_from_parts($digits, $radix, $outer_sign);
        return undef unless defined $value;
        return {
            value => $value,
            width => $width,
            radix => $radix,
            digits => $digits,
        };
    }

    if ($text =~ /\A(\d+)'([+-]?(?:0[dDbBoOxX][+-]?[0-9A-Fa-f]+|[0-9]+))\z/) {
        my ($width, $inner) = ($1, $2);
        my $value = $class->integer_from_scalar($inner);
        return undef unless defined $value;
        return {
            value => $value,
            width => $width,
            radix => $class->_radix_from_intent_token($inner),
        };
    }

    if ($text =~ /\A([+-]?)(\d+)\z/) {
        my $value = $class->integer_from_parts($2, 'decimal', $1);
        return undef unless defined $value;
        return { value => $value, radix => 'decimal' };
    }

    if ($text =~ /\A([+-]?)0d([+-]?\d+)\z/i) {
        my $value = $class->integer_from_parts($2, 'decimal', $1);
        return undef unless defined $value;
        return { value => $value, radix => 'decimal' };
    }

    if ($text =~ /\A([+-]?)0b([+-]?[01]+)\z/i) {
        my $value = $class->integer_from_parts($2, 'binary', $1);
        return undef unless defined $value;
        return { value => $value, radix => 'binary', digits => $2 };
    }

    if ($text =~ /\A([+-]?)0o([+-]?[0-7]+)\z/i) {
        my $value = $class->integer_from_parts($2, 'octal', $1);
        return undef unless defined $value;
        return { value => $value, radix => 'octal', digits => $2 };
    }

    if ($text =~ /\A([+-]?)0x([+-]?[0-9A-Fa-f]+)\z/i) {
        my $value = $class->integer_from_parts($2, 'hex', $1);
        return undef unless defined $value;
        return { value => $value, radix => 'hex', digits => $2 };
    }

    if ($text =~ /\A(?:\d+)?'(s?)([bodh])([+-]?[0-9A-Fa-f]+)\z/i) {
        my ($radix, $digits) = (lc($2), $3);
        my $value = $class->integer_from_parts($digits, $radix);
        return undef unless defined $value;
        return {
            value => $value,
            radix => $class->_normalize_radix_name($radix),
            digits => $digits,
        };
    }

    return undef;
}

sub integer_from_parts ($class, $digits, $radix, $sign = '') {
    return undef unless defined($digits) && defined($radix);
    return undef if ref($digits) || ref($radix);

    $digits =~ s/_//g;
    return undef unless length $digits;

    my $negative = 0;
    if ($digits =~ s/\A([+-])//) {
        $negative = $1 eq '-' ? 1 : 0;
    }
    $negative = 1 if defined($sign) && $sign eq '-';

    my %normalized = (
        b => 'binary',
        d => 'decimal',
        o => 'octal',
        h => 'hex',
    );
    $radix = $normalized{$radix} // $radix;

    my %base_for = (
        decimal => 10,
        binary => 2,
        octal => 8,
        hex => 16,
    );
    my $base = $base_for{$radix} or return undef;

    my %value_for = (
        0 => 0, 1 => 1, 2 => 2, 3 => 3, 4 => 4,
        5 => 5, 6 => 6, 7 => 7, 8 => 8, 9 => 9,
        a => 10, b => 11, c => 12, d => 13, e => 14, f => 15,
    );

    my $value = Math::BigInt->new(0);
    for my $char (split //, lc($digits)) {
        return undef unless exists $value_for{$char} && $value_for{$char} < $base;
        $value->bmul($base);
        $value->badd($value_for{$char});
    }

    $value->bneg if $negative;
    return $value;
}

sub _normalize_radix_name ($class, $radix) {
    my %normalized = (
        b => 'binary',
        binary => 'binary',
        d => 'decimal',
        decimal => 'decimal',
        o => 'octal',
        octal => 'octal',
        h => 'hex',
        x => 'hex',
        hex => 'hex',
    );
    return $normalized{lc($radix // 'decimal')} // 'decimal';
}

sub _radix_from_intent_token ($class, $token) {
    return 'decimal' unless defined $token;
    my $copy = $token;
    $copy =~ s/\A[+-]//;
    return 'binary' if $copy =~ /\A0b/i;
    return 'octal' if $copy =~ /\A0o/i;
    return 'hex' if $copy =~ /\A0x/i;
    return 'decimal';
}

sub _systemverilog_radix_prefix ($class, $radix) {
    $radix = $class->_normalize_radix_name($radix);
    return 'b' if $radix eq 'binary';
    return 'o' if $radix eq 'octal';
    return 'h' if $radix eq 'hex';
    return 'd';
}

sub _encoded_value_for_width ($class, $value, $width) {
    my $limit = Math::BigInt->new(2);
    $limit->bpow($width);

    if ($value->bcmp(0) >= 0) {
        confess "Integer literal value ".$value->bstr." does not fit in $width bit(s).\n"
            if $value->bcmp($limit) >= 0;
        return $value->copy;
    }

    my $min_signed = Math::BigInt->new(2);
    $min_signed->bpow($width - 1);
    $min_signed->bneg;
    confess "Integer literal value ".$value->bstr." does not fit in signed $width bit(s).\n"
        if $value->bcmp($min_signed) < 0;

    my $encoded = $limit->copy;
    $encoded->badd($value);
    return $encoded;
}

sub _digits_for_radix ($class, $value, $radix, $width = undef, $pad = 0) {
    $radix = $class->_normalize_radix_name($radix);

    return $value->bstr if $radix eq 'decimal';

    my $digits;
    if ($radix eq 'binary') {
        $digits = $value->as_bin;
        $digits =~ s/\A0b//;
        $digits = '0' unless length $digits;
        if ($pad && defined $width && length($digits) < $width) {
            $digits = ('0' x ($width - length($digits))).$digits;
        }
        return $digits;
    }

    if ($radix eq 'octal') {
        $digits = $value->as_oct;
        $digits =~ s/\A0//;
        $digits = '0' unless length $digits;
        if ($pad && defined $width) {
            my $min_digits = int(($width + 2) / 3);
            $digits = ('0' x ($min_digits - length($digits))).$digits
                if length($digits) < $min_digits;
        }
        return $digits;
    }

    if ($radix eq 'hex') {
        $digits = $value->as_hex;
        $digits =~ s/\A0x//;
        $digits = '0' unless length $digits;
        $digits = uc($digits);
        if ($pad && defined $width) {
            my $min_digits = int(($width + 3) / 4);
            $digits = ('0' x ($min_digits - length($digits))).$digits
                if length($digits) < $min_digits;
        }
        return $digits;
    }

    return undef;
}

1;
