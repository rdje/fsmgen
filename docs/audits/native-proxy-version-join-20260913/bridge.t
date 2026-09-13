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
use lib "$FindBin::Bin/../native-proxy-preparation-records-20260913";
use Fcntl qw(O_WRONLY O_CREAT O_EXCL);
use JSON::PP ();
use Test::More;
use PreparationRecord;

my $json = JSON::PP->new->canonical->ascii;
open my $input, '<:raw', "$FindBin::Bin/bridge-vectors.json" or die "vectors: $!";
my $vectors = $json->decode(do { local $/; <$input> });
close $input or die "close vectors: $!";
sysopen(my $output, "$FindBin::Bin/result/bridge.json", O_WRONLY | O_CREAT | O_EXCL, 0600)
    or die "reserve result: $!";
binmode($output);
my @rows;
for my $vector (@{$vectors->{vectors}}) {
    my $raw = $vector->{raw};
    utf8::downgrade($raw, 1) or die "record is not ASCII bytes\n";
    my ($record, $encoded);
    my $ok = eval {
        $record = NativeProxyPreparationRecord::decode_preparation_record($raw);
        $encoded = NativeProxyPreparationRecord::encode_preparation_record($record);
        1;
    };
    my $error = $@;
    push @rows, {name => $vector->{name}, accepted => $ok ? 1 : 0, encoded => $encoded, error => $error};
    if ($vector->{accept}) {
        ok($ok, "$vector->{name}: admitted") or diag $error;
        is($encoded, $raw, "$vector->{name}: canonical bytes unchanged");
    }
    else {
        ok(!$ok && length($error), "$vector->{name}: rejected");
    }
}
is($forbidden, 0, 'no fixture or process creation attempted');
# Presentation owns a different encoder; nested canonical byte strings remain exact.
my $presentation = JSON::PP->new->canonical->ascii->pretty;
print {$output} $presentation->encode({schema => 'fsmgen.inactive_version_bridge_result.v1',
    rows => \@rows, forbidden_process_attempts => $forbidden}) or die "write result: $!";
close $output or die "close result: $!";
done_testing;
