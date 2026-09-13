#!/usr/bin/env perl
use strict;
use warnings;
our ($forbidden, $lookups) = (0, 0);
BEGIN {
    *CORE::GLOBAL::fork = sub { ++$forbidden; die 'forbidden fork'; };
    *CORE::GLOBAL::system = sub { ++$forbidden; die 'forbidden system'; };
}
use FindBin;
use lib "$FindBin::Bin/../../../perl", "$FindBin::Bin/../../../t/lib",
    map { "$FindBin::Bin/../$_" } qw(native-proxy-image-custody-20260910
        native-proxy-image-coordination-20260910 native-proxy-image-publication-20260910
        native-proxy-runtime-records-20260910 native-proxy-runtime-census-20260910
        native-proxy-observation-records-20260910 native-proxy-observation-acquisition-20260910
        native-proxy-observation-archive-records-20260911 native-proxy-cleanup-receipts-20260910
        native-proxy-observation-work-records-20260911);
use JSON::PP ();
use Digest::SHA qw(sha256_hex);
use Test::More;
use FSM::Test::RustProxyFixture ();
BEGIN { *CORE::GLOBAL::exec = sub { ++$forbidden; die 'forbidden exec'; }; }
use Coordination;
use WorkRecord;

my $JSON = JSON::PP->new->canonical->ascii;
sub read_document {
    open my $fh, '<:raw', $_[0] or die "input: $!";
    my $raw = do { local $/; <$fh> };
    close $fh or die "input close: $!";
    return $JSON->decode($raw);
}
sub clone { return $JSON->decode($JSON->encode($_[0])); }
sub materialize {
    my ($value) = @_;
    return [map { materialize($_) } @$value] if ref($value) eq 'ARRAY';
    return {map { $_ eq 'bytes_hex' ? (bytes => pack('H*', $value->{$_})) : ($_ => materialize($value->{$_})) }
            keys %$value} if ref($value) eq 'HASH';
    return $value;
}
sub retain {
    my ($value) = @_;
    return [map { retain($_) } @$value] if ref($value) eq 'ARRAY';
    return {map { $_ eq 'bytes' ? (bytes_hex => unpack('H*', $value->{$_})) : ($_ => retain($value->{$_})) }
            keys %$value} if ref($value) eq 'HASH';
    return $value;
}
my $plan = read_document("$FindBin::Bin/plan.json");
my $pins = read_document("$FindBin::Bin/preflight-pins.json");
for my $pin (@{$plan->{inputs}}, @$pins) {
    open my $fh, '<:raw', "$FindBin::Bin/../../../$pin->{path}" or die "pin: $!";
    my $raw = do { local $/; <$fh> };
    close $fh or die "pin close: $!";
    die "pin changed: $pin->{path}\n" unless length($raw) == $pin->{size_bytes} && sha256_hex($raw) eq $pin->{sha256};
}
my $prepared = read_document("$FindBin::Bin/prepared.json");
my $signature = $JSON->encode($prepared);
my $result = {schema => 'fsmgen.inactive_lifetime_record_bridge.v1', seeds => {}, controls => []};
{
    no warnings 'redefine';
    local *FSM::Test::RustProxyFixture::supervise_process = sub { ++$forbidden; die 'forbidden process'; };
    local *FSM::Test::RustProxyFixture::_read_file = sub { ++$lookups; die 'forbidden file read'; };
    local *NativeProxyImageCustody::_directory = sub { ++$lookups; die 'forbidden directory'; };
    local *NativeProxyImageCustody::_source = sub { ++$lookups; die 'forbidden source'; };
    local *NativeProxyImageCustody::read_entry = sub { ++$lookups; die 'forbidden image'; };
    local *NativeProxyImagePublication::_write_payload = sub { ++$lookups; die 'forbidden publication'; };
    local *NativeProxyImageCoordination::_transaction = sub { ++$lookups; die 'forbidden coordinator'; };
    local *NativeProxyObservationAcquisition::_prior_directory = sub { ++$lookups; die 'forbidden prior directory'; };
    for my $profile (@{$plan->{profiles}}) {
        my $seed = materialize($prepared->{seeds}{$profile});
        my $case = $seed->{observers}{a}{case};
        my $row = {runtime_bytes => {}, observations => {}};
        for my $name (qw(target other)) {
            my $record = $seed->{runtimes}{$name}{record};
            my $bytes = NativeProxyRuntimeRecord::encode_runtime_record($case, $record);
            is_deeply(NativeProxyRuntimeRecord::decode_runtime_record($case, $bytes), $record, "$profile $name original runtime codec");
            $row->{runtime_bytes}{$name} = unpack('H*', $bytes);
        }
        for my $name (qw(a b)) {
            my $v = $seed->{observers}{$name};
            my @base = ($v->{case}, $v->{request}, $v->{acquired});
            my $previous = NativeProxyObservationAcquisition::_previous(@base);
            is_deeply($previous, $v->{acquired}, "$profile $name previous acquisition");
            my $spec = NativeProxyObservationArchiveRecord::archive_specification(@base);
            my $receipt = NativeProxyObservationArchiveRecord::archive_receipt(@base, $v->{directory}, $v->{snapshots});
            is_deeply($receipt, $v->{archive}, "$profile $name original archive receipt");
            my $selection = NativeProxyObservationWorkRecord::work_selection(@base, $v->{entries});
            is_deeply($selection, $v->{selection}, "$profile $name original work selection");
            ok(NativeProxyObservationWorkRecord::validate_work_settlement(@base, $v->{selection}, $v->{settlement}), "$profile $name completed/failed/cancelled all settled");
            $row->{observations}{$name} = retain({previous => $previous, specification => $spec, archive => $receipt,
                                                 selection => $selection, settlement => $v->{settlement}});
        }
        $result->{seeds}{$profile} = $row;
    }
    for my $item (@{$prepared->{controls}}) {
        my $control = $item->{control};
        next unless exists $control->{oracle};
        my $value = materialize($item->{seed}{observers}{a});
        my @base = ($value->{case}, $value->{request}, $value->{acquired});
        my $ok = eval {
            if ($control->{oracle} eq 'settlement') {
                NativeProxyObservationWorkRecord::validate_work_settlement(@base, $value->{selection}, $value->{settlement});
            } elsif ($control->{oracle} eq 'archive') {
                my $receipt = materialize($item->{state}{archives}{a});
                NativeProxyObservationArchiveRecord::validate_archive_receipt(@base, $receipt);
            } elsif ($control->{oracle} eq 'previous') {
                NativeProxyObservationAcquisition::_previous(@base);
            } elsif ($control->{oracle} eq 'cleanup') {
                die 'unsettled cleanup' unless NativeProxyCleanupReceipts::cleanup_receipts_settled(
                    @{$item->{seed}{runtimes}{target}{cleanup}});
            } else { die 'undeclared oracle'; }
            1;
        } ? 1 : 0;
        my $error = $@;
        is($ok, $control->{oracle_accept} ? 1 : 0, "$control->{name} unchanged pure oracle");
        push @{$result->{controls}}, {name => $control->{name}, accepted => $ok, error => $error};
    }
}
is($JSON->encode($prepared), $signature, 'loaded input values unchanged');
is($forbidden, 0, 'no process attempt');
is($lookups, 0, 'no fixture filesystem helper attempt');
$result->{process_attempts} = $forbidden;
$result->{fixture_lookup_attempts} = $lookups;
$result->{input_unchanged} = JSON::PP::true;
open my $out, '>:raw', \my $bytes or die 'memory output';
print {$out} JSON::PP->new->canonical->ascii->pretty->encode($result);
close $out or die 'memory output close';
use Fcntl qw(O_WRONLY O_CREAT O_EXCL);
sysopen my $file, "$FindBin::Bin/bridge.json", O_WRONLY | O_CREAT | O_EXCL, 0600 or die "exclusive output: $!";
print {$file} $bytes or die "output: $!";
close $file or die "output close: $!";
done_testing();
