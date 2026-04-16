package FSM::Package::ScalarWidthSupport;

use v5.20;
use strict;
use warnings;
use Math::BigInt;
use Scalar::Util qw(blessed);
use feature qw(signatures);
no warnings 'experimental::signatures';

sub positive_integer_from_literal_like ($class, $literal_like) {
    return undef unless defined $literal_like;

    if (ref($literal_like) eq 'HASH') {
        return undef unless ($literal_like->{kind} || '') eq 'scalar';
        return $class->positive_integer_from_literal_like($literal_like->{payload});
    }

    if (blessed($literal_like)
        && $literal_like->can('value')
        && $literal_like->can('radix')) {
        return $class->_positive_integer_from_parts(
            $literal_like->value,
            ($literal_like->radix // 'decimal'),
        );
    }

    return undef if ref($literal_like);
    return $class->_positive_integer_from_scalar_payload($literal_like);
}

sub _positive_integer_from_scalar_payload ($class, $payload) {
    return undef unless defined($payload) && !ref($payload);

    my $text = $payload;
    $text =~ s/_//g;

    return $class->_positive_integer_from_parts($1, 'decimal')
        if $text =~ /\A([1-9]\d*)\z/;

    return $class->_positive_integer_from_parts($1, 'decimal')
        if $text =~ /\A0d([1-9]\d*)\z/i;

    return $class->_positive_integer_from_parts($1, 'binary')
        if $text =~ /\A0b([01]+)\z/i;

    return $class->_positive_integer_from_parts($1, 'octal')
        if $text =~ /\A0o([0-7]+)\z/i;

    return $class->_positive_integer_from_parts($1, 'hex')
        if $text =~ /\A0x([0-9A-Fa-f]+)\z/i;

    if ($text =~ /\A(?:\d+)?'(s?)([bodh])([0-9A-Fa-f+-]+)\z/i) {
        my ($is_signed, $radix, $digits) = ($1, lc($2), $3);
        return undef if $is_signed && $digits =~ /\A-/;
        return $class->_positive_integer_from_parts($digits, $radix);
    }

    return undef;
}

sub _positive_integer_from_parts ($class, $digits, $radix) {
    return undef unless defined($digits) && defined($radix);
    return undef if ref($digits) || ref($radix);

    $digits =~ s/_//g;
    return undef unless length $digits;

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

    return undef unless $value->bcmp(0) > 0;
    return 0 + $value->bstr;
}

1;
