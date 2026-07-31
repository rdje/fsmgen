package FSM::VIAL::ExecutionRandom;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Digest::SHA qw(sha256);
use Math::BigInt;
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

my $PREFIX = "fsmgen.vial.random.sha256_counter_rejection.v1\0";
my $MAX_ATTEMPTS = 1_000_000;

sub algorithm_id($class) {
    confess "$class->algorithm_id requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return 'sha256_counter_rejection_v1';
}

sub generate($class, @args) {
    confess "$class->generate requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    confess "$class->generate expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH';
    my $raw = $args[0];
    my %allowed = map { $_ => 1 } qw(width seed occurrence_id low high accept max_attempts);
    my @unknown = sort grep { !$allowed{$_} } keys %$raw;
    confess 'ExecutionRandom unknown key(s): ' . join(', ', @unknown) . "\n" if @unknown;
    for my $required (qw(width seed occurrence_id low high)) {
        confess "ExecutionRandom missing '$required'\n" unless exists $raw->{$required};
    }
    my $width = $raw->{width};
    confess "ExecutionRandom width must be a positive integer\n"
        unless defined($width) && !ref($width) && $width =~ /\A[1-9][0-9]*\z/;
    my $seed = _big_uint($raw->{seed}, 'seed');
    confess "ExecutionRandom seed exceeds unsigned 64-bit range\n"
        if $seed->bcmp(Math::BigInt->new(2)->bpow(64)->bdec) > 0;
    confess "ExecutionRandom occurrence_id must be non-empty UTF-8 bytes\n"
        unless defined($raw->{occurrence_id}) && !ref($raw->{occurrence_id})
            && length($raw->{occurrence_id}) && utf8::valid($raw->{occurrence_id});
    my $low = _big_int($raw->{low}, 'low');
    my $high = _big_int($raw->{high}, 'high');
    confess "ExecutionRandom range is empty\n" if $low->bcmp($high) > 0;
    my $range = $high->copy->bsub($low)->binc;
    my $space = Math::BigInt->new(2)->bpow($width);
    confess "ExecutionRandom range exceeds width\n" if $range->bcmp($space) > 0;
    my $limit = $space->copy->bsub($space->copy->bmod($range));
    my $accept = $raw->{accept};
    confess "ExecutionRandom accept must be a code reference when supplied\n"
        if defined($accept) && ref($accept) ne 'CODE';
    my $max = exists($raw->{max_attempts}) ? $raw->{max_attempts} : $MAX_ATTEMPTS;
    confess "ExecutionRandom max_attempts is invalid\n"
        unless defined($max) && !ref($max) && $max =~ /\A[1-9][0-9]*\z/
            && $max <= $MAX_ATTEMPTS;

    for my $attempt (0 .. $max - 1) {
        my $candidate = _candidate($width, $seed, $raw->{occurrence_id}, $attempt);
        next if $candidate->bcmp($limit) >= 0;
        my $proposal = $low->copy->badd($candidate->copy->bmod($range));
        next if $accept && !$accept->($proposal->copy);
        return {value => $proposal, attempt => $attempt};
    }
    return undef;
}

sub normalized_scalar($class, @args) {
    confess "$class->normalized_scalar requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    confess "$class->normalized_scalar expects value, type_id, state_domain, signed, width\n"
        unless @args == 5;
    my ($value, $type_id, $state_domain, $signed, $width) = @args;
    my $big = _big_int($value, 'value');
    my $modulus = Math::BigInt->new(2)->bpow($width);
    $big->badd($modulus) if $big->is_neg;
    confess "normalized scalar is not representable\n"
        if $big->is_neg || $big->bcmp($modulus) >= 0;
    my $digits = int(($width + 3) / 4);
    my $hex = $big->as_hex;
    $hex =~ s/\A0x//;
    $hex = ('0' x ($digits - length($hex))) . lc($hex);
    my $known = ('f' x $digits);
    if ($width % 4) {
        substr($known, 0, 1, sprintf('%x', (1 << ($width % 4)) - 1));
    }
    return {
        kind => 'scalar',
        type_id => $type_id,
        state_domain => $state_domain,
        signed => $signed ? 1 : 0,
        width => 0 + $width,
        value_hex => $hex,
        known_hex => $known,
        z_hex => ('0' x $digits),
    };
}

sub _candidate($width, $seed, $occurrence, $attempt) {
    my $blocks = int(($width + 255) / 256);
    my $seed_bytes = pack('H*', _u64_hex($seed));
    my $length = length($occurrence);
    confess "ExecutionRandom occurrence_id is too long\n" if $length > 0xffff_ffff;
    my $attempt_big = Math::BigInt->new($attempt);
    my $hex = '';
    for my $block (0 .. $blocks - 1) {
        my $input = $PREFIX . $seed_bytes . pack('N', $length) . $occurrence
            . pack('H*', _u64_hex($attempt_big)) . pack('N', $block);
        $hex .= unpack('H*', sha256($input));
    }
    my $value = Math::BigInt->from_hex('0x' . $hex);
    my $extra = $blocks * 256 - $width;
    $value->brsft($extra) if $extra;
    return $value;
}

sub _u64_hex($value) {
    my $hex = $value->as_hex;
    $hex =~ s/\A0x//;
    return ('0' x (16 - length($hex))) . $hex;
}

sub _big_uint($value, $label) {
    my $big = _big_int($value, $label);
    confess "ExecutionRandom $label must be unsigned\n" if $big->is_neg;
    return $big;
}

sub _big_int($value, $label) {
    confess "ExecutionRandom $label must be an integer\n"
        if !defined($value) || ref($value) || $value !~ /\A-?[0-9]+\z/;
    return Math::BigInt->new("$value");
}

1;
