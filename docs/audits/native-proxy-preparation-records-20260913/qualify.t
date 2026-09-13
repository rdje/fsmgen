#!/usr/bin/env perl
use strict;
use warnings;
our $forbidden = 0;
BEGIN {
    *CORE::GLOBAL::fork = sub { ++$forbidden; die "forbidden fork\n"; };
    *CORE::GLOBAL::system = sub { ++$forbidden; die "forbidden system\n"; };
    *CORE::GLOBAL::exec = sub { ++$forbidden; die "forbidden exec\n"; };
}
use FindBin;
use lib $FindBin::Bin;
use Fcntl qw(O_WRONLY O_CREAT O_EXCL);
use JSON::PP ();
use Test::More;
use PreparationRecord;

my $json = JSON::PP->new->canonical->ascii;
open my $input, '<:raw', "$FindBin::Bin/vectors.json" or die "vectors: $!";
my $vectors = $json->decode(do { local $/; <$input> });
close $input or die "close vectors: $!";
sysopen(my $output, "$FindBin::Bin/result/qualification.json", O_WRONLY | O_CREAT | O_EXCL, 0600)
    or die "reserve qualification: $!";
binmode($output);
my $encode = \&NativeProxyPreparationRecord::encode_preparation_record;
my $decode = \&NativeProxyPreparationRecord::decode_preparation_record;
my (@rows, @mutants);

sub clone { return $json->decode($json->encode($_[0])); }

for my $vector (@{$vectors->{vectors}}) {
    my ($record, $encoded);
    my $ok = eval {
        my $raw = $vector->{raw};
        # The vector file is JSON text. Turn its ASCII payload back into the
        # byte-string interface required by the codec, without changing bytes.
        utf8::downgrade($raw, 1) or die "vector payload is not bytes\n";
        $record = $decode->($raw);
        $encoded = $encode->($record);
        1;
    };
    my $error = $@;
    $error =~ s/\Q$FindBin::Bin\E/./g;
    if ($vector->{accept}) {
        ok($ok, "$vector->{name}: valid record") or diag $error;
        is($encoded, $vector->{raw}, "$vector->{name}: independent canonical bytes");
    }
    else {
        ok(!$ok && length($error), "$vector->{name}: rejected");
        like($error, qr/\Q$vector->{reason}\E/, "$vector->{name}: intended guard") if defined($vector->{reason});
    }
    push @rows, {name => $vector->{name}, accepted => $ok ? 1 : 0,
                 encoded => $encoded, diagnostic => $error};
}

my $base = $vectors->{base};
my $failed = clone($base);
@$failed{qw(ok status failure_stage diagnostic executable)} =
    (0, 'invocation_error', 'image_reference', 'controlled reference failure', undef);
{
    no warnings 'redefine';
    my $real = \&NativeProxyPreparationRecord::_validate;
    local *NativeProxyPreparationRecord::_validate = sub {
        my $copy = clone($_[0]);
        $copy->{executable} = undef unless $copy->{ok};
        return $real->($copy);
    };
    $failed->{executable} = $base->{executable};
    my $raw = $encode->($failed);
    ok(defined($json->decode($raw)->{executable}), 'sanitized-copy mutant emits a runnable failure');
    push @mutants, {name => 'validation_of_sanitized_copy', raw => $raw};
}
{
    no warnings 'redefine';
    local *NativeProxyPreparationRecord::_reference = sub { return; };
    my $record = clone($base);
    $record->{image_reference}{global}{sha256} = '0' x 64;
    my $raw = $encode->($record);
    is($json->decode($raw)->{image_reference}{global}{sha256}, '0' x 64,
       'omitted-reference mutant emits inconsistent byte identity');
    push @mutants, {name => 'omitted_reference_validation', raw => $raw};
}

my @interface;
my $legacy = clone($vectors->{original_v1});
my $legacy_ok = eval { $encode->($legacy); 1 };
ok(!$legacy_ok && length($@), 'legacy v1 remains outside the native v2 codec');
is($json->encode($legacy), $vectors->{original_v1_raw}, 'original v1 record remains byte-exact');
for my $case (
    ['extra encode argument', sub { $encode->($base, 'extra') }],
    ['missing decode argument', sub { $decode->() }],
    ['character input', sub { my $raw = $vectors->{vectors}[0]{raw}; utf8::upgrade($raw); $decode->($raw) }],
    ['reference input', sub { $decode->([]) }],
) {
    my $ok = eval { $case->[1]->(); 1 };
    ok(!$ok && length($@), $case->[0]);
    push @interface, {name => $case->[0], rejected => $ok ? 0 : 1};
}
is($forbidden, 0, 'no compiler, fixture or process launch attempts');
my $passing = Test::More->builder->is_passing ? JSON::PP::true : JSON::PP::false;
my $presentation = JSON::PP->new->canonical->ascii->pretty;
print {$output} $presentation->encode({schema => 'fsmgen.inactive_preparation_qualification.v1',
    success => $passing, rows => \@rows, mutants => \@mutants,
    original_v1_raw => $json->encode($legacy),
    interface_controls => \@interface, forbidden_process_attempts => $forbidden,
    fixture_allocations => 0}) or die "write qualification: $!";
close $output or die "close qualification: $!";
done_testing();
