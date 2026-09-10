#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../../perl", "$FindBin::Bin/../../../t/lib",
    map { "$FindBin::Bin/../$_" } qw(native-proxy-image-custody-20260910
        native-proxy-image-coordination-20260910 native-proxy-image-publication-20260910
        native-proxy-runtime-records-20260910 native-proxy-runtime-census-20260910
        native-proxy-observation-records-20260910 native-proxy-observation-acquisition-20260910);
use JSON::PP ();
use Storable qw(dclone);
use Scalar::Util qw(dualvar);
use lib $FindBin::Bin;
use FixtureClone;
use Test::More;
use ObservationAcquisition;

my $JSON = JSON::PP->new->canonical->ascii;
# Replay only the retained failed receipt. Its directories are absent; no
# filesystem custody or process operation is needed to diagnose representation.
open my $fh, '<:raw', "$FindBin::Bin/../../../.artifacts/logs/native-proxy-observation-reuse-20260910/initial-byte-representation-failure/qualification.json" or die $!;
my $result = $JSON->decode(do { local $/; <$fh> }); close $fh or die $!;
my $context = $result->{cases}[0]{context};
my $previous = $context->{previous};
my $attempts = 0;
no warnings 'redefine';
local *NativeProxyImageCustody::_source = sub { ++$attempts; die 'forbidden source read'; };
local *NativeProxyImageCustody::_directory = sub { ++$attempts; die 'forbidden directory lookup'; };
sub snapshots { return ($_[0]{observation_reference}{source}, @{$_[0]{target_sources}}); }
my @flagged = map { utf8::is_utf8($_->{bytes}) ? 1 : 0 } snapshots($previous);
is_deeply(\@flagged, [0,0,0,0,1,1], 'retained JSON exposes character flags on the original binary C/image vectors');
utf8::downgrade($_->{bytes}, 1) or die 'retained value is not recoverable as original octets' for snapshots($previous);
my $json_copy = $JSON->decode($JSON->encode($previous));
my $ok = eval { NativeProxyObservationAcquisition::_previous($context->{store}{path}, $context->{request}, $json_copy); 1 };
ok(!$ok && $@ =~ /expected bounded bytes/, 'JSON cloning reproduces the failure before custody');
my $copy = NativeProxyObservationFixtureClone::clone($previous);
ok(!grep({ utf8::is_utf8($_->{bytes}) } snapshots($copy)), 'fixture cloning preserves octets');
is($JSON->encode($copy), $JSON->encode($previous), 'fixture clone preserves all closed data values and types');
my $validated = NativeProxyObservationAcquisition::_previous($context->{store}{path}, $context->{request}, $copy);
ok(!grep({ utf8::is_utf8($_->{bytes}) } snapshots($validated)), 'validated defensive clone also retains octets');
$validated->{target_sources}[0]{bytes} .= 'changed';
is($JSON->encode($copy), $JSON->encode($previous), 'validated receipt is a separate nested copy');
my $wide = NativeProxyObservationFixtureClone::clone($previous); $wide->{target_sources}[0]{bytes} = "\x{100}";
$ok = eval { NativeProxyObservationAcquisition::_previous($context->{store}{path}, $context->{request}, $wide); 1 };
ok(!$ok && $@ =~ /expected bounded bytes/, 'character input remains rejected; the native-byte contract is not relaxed');
is($attempts, 0, 'representation controls perform no filesystem custody operation');
my $dual = {number => dualvar(7, '7')};
is($JSON->encode($dual), '{"number":7}', 'native-style dual scalar has JSON integer meaning');
is($JSON->encode(dclone($dual)), '{"number":"7"}', 'Storable reproduces the native integer-to-string failure');
my $flagged_ascii = 'A'; utf8::upgrade($flagged_ascii);
my $flagged_latin = pack('C', 255); utf8::upgrade($flagged_latin);
my $vectors = {integer => 7, numeric_string => '7', boolean => JSON::PP::true,
    null => undef, dual => $dual, binary => pack('C*', 0, 255), wide => "\x{100}",
    flagged_ascii => $flagged_ascii, flagged_latin => $flagged_latin,
    nested => [{large => 9007199254740993, bytes => pack('C*', 255, 0)}]};
my $cloned = NativeProxyObservationFixtureClone::clone($vectors);
is($JSON->encode($cloned), $JSON->encode($vectors), 'fixture clone preserves the complete JSON type/value vector');
is_deeply([map { utf8::is_utf8($cloned->{$_}) ? 1 : 0 } qw(binary wide flagged_ascii flagged_latin)],
    [0,1,1,1], 'fixture clone preserves both octet and character flags, including ASCII characters');
$cloned->{nested}[0]{bytes} .= 'changed';
is($vectors->{nested}[0]{bytes}, pack('C*', 255, 0), 'fixture clone owns separate nested data');
my $native = NativeProxyObservationFixtureClone::clone($previous);
for my $source (snapshots($native)) {
    $source->{identity}{$_} = dualvar($source->{identity}{$_}, "$source->{identity}{$_}") for qw(device inode);
}
$native->{lock}{$_} = dualvar($native->{lock}{$_}, "$native->{lock}{$_}") for qw(device inode);
my $native_copy = NativeProxyObservationFixtureClone::clone($native);
$ok = eval { NativeProxyObservationAcquisition::_previous($context->{store}{path}, $context->{request}, $native_copy); 1 };
ok($ok, 'full prior receipt with native-style dual identities validates after fixture cloning') or diag($@);
is($attempts, 0, 'all representation controls remain independent of filesystem custody');
done_testing();
