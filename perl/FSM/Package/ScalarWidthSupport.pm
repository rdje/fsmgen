package FSM::Package::ScalarWidthSupport;

use v5.20;
use strict;
use warnings;
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

    return 0 + $payload
        if $payload =~ /\A[1-9]\d*\z/;

    if ($payload =~ /\A\d+'(s?)([bodh])([0-9A-Fa-f_+-]+)\z/i) {
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

    if ($radix eq 'decimal') {
        return undef unless $digits =~ /\A[1-9]\d*\z/;
        return 0 + $digits;
    }

    if ($radix eq 'binary') {
        return undef unless $digits =~ /\A[01]+\z/;
        my $value = oct("0b$digits");
        return ($value && $value > 0) ? $value : undef;
    }

    if ($radix eq 'octal' || $radix eq 'o') {
        return undef unless $digits =~ /\A[0-7]+\z/;
        my $value = oct("0$digits");
        return ($value && $value > 0) ? $value : undef;
    }

    if ($radix eq 'hex') {
        return undef unless $digits =~ /\A[0-9A-Fa-f]+\z/;
        my $value = hex($digits);
        return ($value && $value > 0) ? $value : undef;
    }

    if ($radix eq 'b' || $radix eq 'd' || $radix eq 'h') {
        my %normalized = (
            b => 'binary',
            d => 'decimal',
            h => 'hex',
        );
        return $class->_positive_integer_from_parts($digits, $normalized{$radix});
    }

    return undef;
}

1;
