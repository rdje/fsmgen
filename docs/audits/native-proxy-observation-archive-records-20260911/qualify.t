#!/usr/bin/env perl
use strict;
use warnings;
our ($forbidden, $lookups) = (0, 0);
BEGIN {
    *CORE::GLOBAL::fork = sub { ++$forbidden; die 'forbidden fork'; };
    *CORE::GLOBAL::system = sub { ++$forbidden; die 'forbidden system'; };
}
use FindBin;
use lib "$FindBin::Bin/../../../perl", "$FindBin::Bin/../../../t/lib", $FindBin::Bin,
    map { "$FindBin::Bin/../$_" } qw(native-proxy-image-custody-20260910
        native-proxy-image-coordination-20260910 native-proxy-image-publication-20260910
        native-proxy-runtime-records-20260910 native-proxy-runtime-census-20260910
        native-proxy-observation-records-20260910 native-proxy-observation-acquisition-20260910);
use JSON::PP ();
use Test::More;
use FSM::ProjectDataLocality qw(ensure_project_artifact_dir);
use FSM::Test::RustProxyFixture ();
BEGIN { *CORE::GLOBAL::exec = sub { ++$forbidden; die 'forbidden exec'; }; }
use Coordination;
use ArchiveRecord;

my $JSON = JSON::PP->new->canonical->ascii;
open my $input, '<:raw', "$FindBin::Bin/plan.json" or die "plan: $!";
my $plan = $JSON->decode(do { local $/; <$input> });
close $input or die "plan close: $!";
my $log = ensure_project_artifact_dir(qw(logs native-proxy-observation-archive-records-20260911));
my $result = {schema => 'fsmgen.inactive_archive_record_qualification.v1',
    vectors => [], controls => [], mutants => []};

# Plan and output I/O are legitimate. Every current target/archive lookup and
# every process entry point used by these prototypes is forbidden thereafter.
no warnings 'redefine';
local *FSM::Test::RustProxyFixture::supervise_process = sub { ++$forbidden; die 'forbidden process'; };
local *FSM::Test::RustProxyFixture::_read_file = sub { ++$lookups; die 'forbidden file read'; };
local *NativeProxyImageCustody::_directory = sub { ++$lookups; die 'forbidden directory lookup'; };
local *NativeProxyImageCustody::_source = sub { ++$lookups; die 'forbidden source lookup'; };
local *NativeProxyImageCustody::read_entry = sub { ++$lookups; die 'forbidden image lookup'; };
local *NativeProxyImagePublication::_write_payload = sub { ++$lookups; die 'forbidden publication'; };
local *NativeProxyImageCoordination::_transaction = sub { ++$lookups; die 'forbidden coordination'; };
local *NativeProxyObservationAcquisition::_prior_directory = sub { ++$lookups; die 'forbidden prior directory'; };

sub clone { return $JSON->decode($JSON->encode($_[0])); }
sub materialize {
    my ($value) = @_;
    if (ref($value) eq 'ARRAY') { return [map { materialize($_) } @$value]; }
    if (ref($value) eq 'HASH') {
        my %out;
        for my $key (keys %$value) {
            if ($key eq 'bytes_hex') { $out{bytes} = pack('H*', $value->{$key}); }
            else { $out{$key} = materialize($value->{$key}); }
        }
        return \%out;
    }
    return $value;
}
sub export_bytes {
    my ($value) = @_;
    if (ref($value) eq 'ARRAY') { return [map { export_bytes($_) } @$value]; }
    if (ref($value) eq 'HASH') {
        my %out;
        for my $key (keys %$value) {
            if ($key eq 'bytes') {
                $out{bytes_hex} = unpack('H*', $value->{$key});
                $out{bytes_utf8} = utf8::is_utf8($value->{$key}) ? 1 : 0;
            } else { $out{$key} = export_bytes($value->{$key}); }
        }
        return \%out;
    }
    return $value;
}
sub signature { return $JSON->encode(export_bytes($_[0])); }
sub slot {
    my ($value, $path) = @_;
    for my $index (0..$#$path-1) {
        $value = ref($value) eq 'ARRAY' ? $value->[$path->[$index]] : $value->{$path->[$index]};
    }
    return ($value, $path->[-1]);
}
sub changed {
    my ($control) = @_;
    my $value = clone($plan->{vectors}[$control->{vector}]);
    for my $step (@{$control->{steps}}) {
        my ($parent, $key) = slot($value, $step->{path});
        my $target = ref($parent) eq 'ARRAY' ? \$parent->[$key] : \$parent->{$key};
        my $action = $step->{action};
        if ($action eq 'set') { $$target = clone($step->{value}); }
        elsif ($action eq 'delete') { die 'delete requires map' unless ref($parent) eq 'HASH'; delete $parent->{$key}; }
        elsif ($action eq 'pop') { pop @{$$target}; }
        elsif ($action eq 'reverse') { $$target = [reverse @{$$target}]; }
        elsif ($action eq 'duplicate') { push @{$$target}, clone($$target->[0]); }
        else { die 'unknown planned mutation'; }
    }
    $value = materialize($value);
    if ($control->{upgrade}) {
        my ($parent, $key) = slot($value, $control->{upgrade});
        utf8::upgrade($parent->{$key});
    }
    return $value;
}
sub invoke {
    my ($operation, $value, $argument_change) = @_;
    my @args = @$value{qw(case request acquired)};
    my %methods = (specification => \&NativeProxyObservationArchiveRecord::archive_specification,
        receipt => \&NativeProxyObservationArchiveRecord::archive_receipt,
        validate => \&NativeProxyObservationArchiveRecord::validate_archive_receipt,
        encode => \&NativeProxyObservationArchiveRecord::encode_archive_receipt,
        decode => \&NativeProxyObservationArchiveRecord::decode_archive_receipt);
    die 'unknown operation' unless exists $methods{$operation};
    push @args, @$value{qw(directory snapshots)} if $operation eq 'receipt';
    push @args, $value->{receipt} if $operation eq 'validate' || $operation eq 'encode';
    push @args, $value->{raw} if $operation eq 'decode';
    pop @args if ($argument_change // '') eq 'drop';
    push @args, 'extra' if ($argument_change // '') eq 'append';
    return $methods{$operation}->(@args);
}

for my $vector (@{$plan->{vectors}}) {
    my $value = materialize(clone($vector));
    my $before = signature($value);
    my $spec = invoke('specification', $value);
    my $receipt = invoke('receipt', $value);
    my $raw = NativeProxyObservationArchiveRecord::encode_archive_receipt(@$value{qw(case request acquired)}, $receipt);
    my $decoded = invoke('decode', $value);
    is(signature($spec), signature($value->{specification}), "$value->{name}: independent specification");
    is(signature($receipt), signature($value->{receipt}), "$value->{name}: independent receipt");
    is($raw, $value->{raw}, "$value->{name}: canonical bytes");
    is(signature($decoded), signature($receipt), "$value->{name}: decoded receipt");
    my $row = {name => $value->{name}, specification => export_bytes($spec), receipt => $receipt,
               raw => $raw, decoded => $decoded};
    # Mutate independent return copies after saving the observations. A caller
    # can change them without rewriting the original request/acquired octets.
    $row = clone($row);
    $spec->{sources}[0]{snapshot}{bytes} = 'changed';
    $spec->{sources}[0]{snapshot}{identity}{inode} = 7;
    $spec->{files}[0]{bytes} = 'changed';
    $receipt->{source_bindings}[0]{source}{inode} = 7;
    $receipt->{source_bindings}[0]{archive}{inode} = 7;
    $receipt->{evidence_directory_identity}{inode} = 7;
    $receipt->{archive_directory_identity}{inode} = 7;
    $decoded->{source_bindings}[0]{source}{inode} = 7;
    $row->{inputs_unchanged} = signature($value) eq $before ? 1 : 0;
    ok($row->{inputs_unchanged}, "$value->{name}: independent returned copies preserve input");
    push @{$result->{vectors}}, $row;
}
for my $control (@{$plan->{controls}}) {
    my $value = changed($control);
    my $before = signature($value);
    my $accepted = eval { invoke($control->{operation}, $value, $control->{argument_change}); 1 };
    my $error = $@;
    my $unchanged = signature($value) eq $before ? 1 : 0;
    ok(!$accepted && length($error) && $unchanged, $control->{name}) or diag($error || 'unexpected acceptance');
    push @{$result->{controls}}, {name => $control->{name}, rejected => $accepted ? 0 : 1,
        error => $error, inputs_unchanged => $unchanged};
}
for my $mutant (@{$plan->{mutants}}) {
    my ($control) = grep { $_->{name} eq $mutant->{control} } @{$plan->{controls}};
    die 'missing mutant control' unless $control;
    my $value = changed($control);
    my ($accepted, $output, $error);
    {
        no strict 'refs';
        local *{'NativeProxyObservationArchiveRecord::'.$mutant->{helper}} = sub { return 1 };
        $accepted = eval { $output = invoke($control->{operation}, $value); 1 };
        $error = $@;
    }
    ok($accepted, "$mutant->{name}: weakened helper accepts known invalid data") or diag($error);
    push @{$result->{mutants}}, {name => $mutant->{name}, accepted => $accepted ? 1 : 0,
        operation_result => $output, invalid_receipt => $control->{operation} eq 'receipt' ? $output : $value->{receipt},
        error => $error};
}
is($lookups, 0, 'no current target or archive lookup');
is($forbidden, 0, 'no process attempt');
$result->{success} = Test::More->builder->is_passing ? JSON::PP::true : JSON::PP::false;
$result->{filesystem_lookup_attempts} = $lookups;
$result->{forbidden_process_attempts} = $forbidden;
open my $output, '>:raw', "$log/qualification.json" or die "result: $!";
print {$output} JSON::PP->new->canonical->ascii->pretty->encode($result) or die "write result: $!";
close $output or die "result close: $!";
chmod(0600, "$log/qualification.json") == 1 or die "result mode: $!";
done_testing;
