use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Scalar::Util qw(refaddr blessed reftype);
use Storable ();
require './docs/audits/record-value-copy-probes-20261004/candidate.pl';

my ($mode, $destination) = @ARGV;
my %allowed = map {$_ => 1} qw(ordinary storable alias split-sharing cycle-alias mutate-input numeric-result);
die 'mode and repository-relative destination required' unless defined $mode
    && $allowed{$mode} && defined $destination && $destination =~ m{\Adocs/audits/record-value-copy-probes-20261004/};
my $json = JSON::PP->new->canonical;
my $pure = \&source_value_copy;
my $assert_is = Test::More->can('is');
my (@cases, @assertions, @native);
my $active;

sub observed_graph {
    my ($value, $seen, $path) = @_;
    return $value unless ref($value);
    die 'unsupported observation reference' if blessed($value)
        || (ref($value) ne 'HASH' && ref($value) ne 'ARRAY');
    $seen ||= {}; $path //= '';
    my $address = refaddr($value);
    return ['reference', $seen->{$address}] if exists $seen->{$address};
    $seen->{$address} = $path;
    if (ref($value) eq 'HASH') {
        my %result;
        for my $key (sort keys %$value) {
            my $escaped = $key; $escaped =~ s/~/~0/g; $escaped =~ s{/}{~1}g;
            $result{$key} = observed_graph($value->{$key}, $seen, "$path/$escaped");
        }
        return ['hash', \%result];
    }
    return ['array', [map {observed_graph($value->[$_], $seen, "$path/$_")} 0..$#$value]];
}

sub specimen {
    my ($name) = @_;
    return undef if $name eq 'null';
    return 1 if $name eq 'number';
    return '1' if $name eq 'string';
    return [] if $name eq 'empty-array';
    if ($name eq 'tree') {
        my $number = 1;
        $number =~ /\A\d+\z/; # Actual numeric validation also supplies a string flag.
        return {number => $number, string => '1', children => [undef, {width => 7}]};
    }
    if ($name eq 'shared') {
        my $child = {number => 1, string => '1'};
        return {left => $child, right => $child};
    }
    if ($name eq 'hash-cycle') {
        my $root = {number => 1}; $root->{self} = $root; return $root;
    }
    if ($name eq 'array-cycle') {
        my $root = [1, '1']; push @$root, $root; return $root;
    }
    die 'unknown specimen';
}

{
    no warnings 'redefine';
    local *main::is = sub ($$;$) {
        my ($actual, $expected, $label) = @_;
        my $passed = $assert_is->(@_);
        push @assertions, {case => $active, label => $label,
            actual => $actual, expected => $expected, passed => $passed ? 1 : 0};
        return $passed;
    };
    local *main::source_value_copy = sub {
        my ($value, $memo) = @_;
        return $pure->(@_) if defined $memo;
        my $copy = $pure->(@_); # Bad providers execute the complete correct copy first.
        return Storable::dclone($value) if $mode eq 'storable' && $active eq 'tree';
        return $value if $mode eq 'alias' && $active eq 'shared';
        if ($mode eq 'split-sharing' && $active eq 'shared') {
            $copy->{right} = $pure->($value->{right});
        }
        if ($mode eq 'cycle-alias' && $active eq 'hash-cycle') {
            $copy->{self} = $value;
        }
        if ($mode eq 'mutate-input' && $active eq 'tree') {
            $value->{number} = '1';
        }
        if ($mode eq 'numeric-result' && $active eq 'tree') {
            $copy->{number} = '1';
        }
        return $copy;
    };
    for my $name (qw(null number string empty-array tree shared hash-cycle array-cycle)) {
        $active = $name;
        my $input = specimen($name);
        my $before = $json->decode($json->encode(observed_graph($input)));
        my $start = scalar @assertions;
        my $copy = source_copy($input, $name);
        push @cases, {name => $name, before => $before, after => observed_graph($input),
            result => observed_graph($copy), joint => observed_graph({input => $input, result => $copy}),
            assertion_start => $start, assertion_end => scalar @assertions};
    }
}

# Both copying and snapshots reject the old finite native exception in this
# stricter T1986 plain profile. Preserve actual class/shape/identity and errors.
for my $class (qw(CoverageCauseSentinel CopyProbeNativeSentinel)) {
    my $value = bless {}, $class;
    my $before = {class => ref($value), reftype => reftype($value),
        identity => refaddr($value), keys => [sort keys %$value]};
    for my $operation (qw(copy snapshot)) {
        my $ok = eval {
            $operation eq 'copy' ? $pure->($value) : input_snapshot($value);
            1;
        };
        my $error = $@;
        ok(!$ok, "$class $operation refuses unsupported native reference");
        push @native, {operation => $operation, before => $before,
            after => {class => ref($value), reftype => reftype($value),
                identity => refaddr($value), keys => [sort keys %$value]},
            accepted => $ok ? 1 : 0, error => $error};
    }
}
open my $out, '>:raw', $destination or die $!;
print {$out} $json->encode({mode => $mode, cases => \@cases,
    assertions => \@assertions, native => \@native, host => {perl => "$^V",
        json_pp => $JSON::PP::VERSION, storable => $Storable::VERSION}}), "\n" or die $!;
close $out or die $!;
done_testing;
