package FSM::Package::IntegerLiteralSupport;

use v5.20;
use strict;
use warnings;
use Math::BigInt;
use Scalar::Util qw(blessed);
use feature qw(signatures);
no warnings 'experimental::signatures';

sub integer_from_literal_like ($class, $literal_like) {
    return undef unless defined $literal_like;

    if (ref($literal_like) eq 'HASH') {
        return undef unless ($literal_like->{kind} || '') eq 'scalar';
        return $class->integer_from_literal_like($literal_like->{payload});
    }

    if (blessed($literal_like)
        && $literal_like->can('value')
        && $literal_like->can('radix')) {
        return $class->integer_from_parts(
            $literal_like->value,
            ($literal_like->radix // 'decimal'),
        );
    }

    return undef if ref($literal_like);
    return $class->integer_from_scalar($literal_like);
}

sub positive_integer_from_literal_like ($class, $literal_like) {
    my $value = $class->integer_from_literal_like($literal_like);
    return undef unless defined $value;
    return undef unless $value->bcmp(0) > 0;
    return 0 + $value->bstr;
}

sub integer_from_scalar ($class, $payload) {
    return undef unless defined($payload) && !ref($payload);

    my $text = $payload;
    $text =~ s/_//g;

    return $class->integer_from_parts($2, 'decimal', $1)
        if $text =~ /\A([+-]?)(\d+)\z/;

    return $class->integer_from_parts($1, 'decimal')
        if $text =~ /\A0d([+-]?\d+)\z/i;

    return $class->integer_from_parts($1, 'binary')
        if $text =~ /\A0b([01]+)\z/i;

    return $class->integer_from_parts($1, 'octal')
        if $text =~ /\A0o([0-7]+)\z/i;

    return $class->integer_from_parts($1, 'hex')
        if $text =~ /\A0x([0-9A-Fa-f]+)\z/i;

    if ($text =~ /\A(?:\d+)?'(s?)([bodh])([+-]?[0-9A-Fa-f]+)\z/i) {
        my ($radix, $digits) = (lc($2), $3);
        return $class->integer_from_parts($digits, $radix);
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

1;
