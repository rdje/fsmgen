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
        native-proxy-observation-records-20260910 native-proxy-observation-acquisition-20260910
        native-proxy-observation-archive-records-20260911 native-proxy-cleanup-receipts-20260910);
use JSON::PP ();
use Digest::SHA qw(sha256_hex);
use Test::More;
use FSM::ProjectDataLocality qw(ensure_project_artifact_dir);
use FSM::Test::RustProxyFixture ();
BEGIN { *CORE::GLOBAL::exec = sub { ++$forbidden; die 'forbidden exec'; }; }
use Coordination;
use WorkRecord;

my $JSON = JSON::PP->new->canonical->ascii;
sub document {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "input: $!";
    my $raw = do { local $/; <$fh> };
    close $fh or die "input close: $!";
    return $JSON->decode($raw);
}
my $plan = document("$FindBin::Bin/plan.json");
my $pins = document("$FindBin::Bin/preflight-pins.json");
for my $pin (@$pins, @{$plan->{inputs}}) {
    open my $fh, '<:raw', "$FindBin::Bin/../../../$pin->{path}" or die "pinned input: $!";
    my $raw = do { local $/; <$fh> };
    close $fh or die "pinned close: $!";
    die "pinned input changed\n" unless length($raw) == $pin->{size_bytes} && sha256_hex($raw) eq $pin->{sha256};
}
my $log = ensure_project_artifact_dir(qw(logs native-proxy-observation-work-records-20260911));
my $result = {schema => 'fsmgen.inactive_observation_work_record_qualification.v1',
    vectors => [], cleanup_cases => [], controls => [], mutants => [], prospective_pins => $pins};

# The setup above reads only declared inputs and establishes this new output.
# Subsequent prototype calls may not reach current target/archive/process helpers.
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
    return [map { materialize($_) } @$value] if ref($value) eq 'ARRAY';
    if (ref($value) eq 'HASH') {
        return {map { $_ eq 'bytes_hex' ? (bytes => pack('H*', $value->{$_})) : ($_ => materialize($value->{$_})) } keys %$value};
    }
    return $value;
}
sub fingerprint {
    my ($value) = @_;
    return [map { fingerprint($_) } @$value] if ref($value) eq 'ARRAY';
    return {map { $_ => fingerprint($value->{$_}) } keys %$value} if ref($value) eq 'HASH';
    return {json => JSON::PP->new->canonical->ascii->allow_nonref->encode($value),
            utf8 => !ref($value) && defined($value) && utf8::is_utf8($value) ? 1 : 0};
}
sub signature { return $JSON->encode(fingerprint($_[0])); }
sub vector_value {
    my ($index, $context) = @_;
    my $vector = clone($plan->{vectors}[$index]);
    $context = $vector->{context} unless defined($context);
    return {%{clone($plan->{contexts}[$context])}, %$vector};
}
sub changed {
    my ($control) = @_;
    my $value = vector_value($control->{vector}, $control->{context});
    for my $step (@{$control->{steps}}) {
        my @path = @{$step->{path}}; my $key = pop @path; my $parent = $value;
        for my $part (@path) { $parent = ref($parent) eq 'ARRAY' ? $parent->[$part] : $parent->{$part}; }
        my $slot = ref($parent) eq 'ARRAY' ? \$parent->[$key] : \$parent->{$key};
        my $action = $step->{action};
        if ($action eq 'set') { $$slot = clone($step->{value}); }
        elsif ($action eq 'delete') { die 'delete requires map' unless ref($parent) eq 'HASH'; delete $parent->{$key}; }
        elsif ($action eq 'pop') { pop @{$$slot}; }
        elsif ($action eq 'duplicate') { push @{$$slot}, clone($$slot->[0]); }
        elsif ($action eq 'reverse') { $$slot = [reverse @{$$slot}]; }
        else { die 'unknown planned mutation'; }
    }
    $value = materialize($value);
    utf8::upgrade($value->{$control->{upgrade}}) if $control->{upgrade};
    return $value;
}
sub invoke {
    my ($operation, $value, $change) = @_;
    my %methods = (selection => \&NativeProxyObservationWorkRecord::work_selection,
        encode_selection => \&NativeProxyObservationWorkRecord::encode_work_selection,
        decode_selection => \&NativeProxyObservationWorkRecord::decode_work_selection,
        settlement => \&NativeProxyObservationWorkRecord::work_settlement,
        validate => \&NativeProxyObservationWorkRecord::validate_work_settlement,
        encode_settlement => \&NativeProxyObservationWorkRecord::encode_work_settlement,
        decode_settlement => \&NativeProxyObservationWorkRecord::decode_work_settlement);
    my %fields = (selection => ['entries'], encode_selection => ['selection'], decode_selection => ['selection_raw'],
        settlement => [qw(selection receipts sealed)], validate => [qw(selection settlement)],
        encode_settlement => [qw(selection settlement)], decode_settlement => [qw(selection settlement_raw)]);
    die 'unknown operation' unless exists($methods{$operation});
    my @args = (@$value{qw(case request acquired)}, @$value{@{$fields{$operation}}});
    pop @args if ($change // '') eq 'drop';
    push @args, 'extra' if ($change // '') eq 'append';
    return $methods{$operation}->(@args);
}

for my $index (0..$#{$plan->{vectors}}) {
    my $value = materialize(vector_value($index)); my $before = signature($value);
    my $selection = invoke('selection', $value);
    my $selection_raw = invoke('encode_selection', $value);
    my $selection_decoded = invoke('decode_selection', $value);
    my $settlement = invoke('settlement', $value);
    my $settlement_raw = invoke('encode_settlement', $value);
    my $settlement_decoded = invoke('decode_settlement', $value);
    my $valid = invoke('validate', $value);
    is($JSON->encode($selection), $JSON->encode($value->{selection}), "$value->{name}: original selection");
    is($selection_raw, $value->{selection_raw}, "$value->{name}: canonical selection");
    is($JSON->encode($selection_decoded), $selection_raw, "$value->{name}: selection decode");
    is($JSON->encode($settlement), $JSON->encode($value->{settlement}), "$value->{name}: original settlement");
    is($settlement_raw, $value->{settlement_raw}, "$value->{name}: canonical settlement");
    is($JSON->encode($settlement_decoded), $settlement_raw, "$value->{name}: settlement decode");
    is($valid, 1, "$value->{name}: settlement validation");
    my $row = clone({name => $value->{name}, selection => $selection, selection_raw => $selection_raw,
        selection_decoded => $selection_decoded, settlement => $settlement, settlement_raw => $settlement_raw,
        settlement_decoded => $settlement_decoded});
    for my $returned ($selection, $selection_decoded, $settlement->{selection}, $settlement_decoded->{selection}) {
        $returned->{entries}[0]{work_id} = 'changed'; $returned->{evidence_directory_identity}{inode} = 7;
    }
    $_->{receipts}[0]{cleanup}{group_gone} = 0 for ($settlement, $settlement_decoded);
    $row->{inputs_unchanged} = signature($value) eq $before ? 1 : 0;
    ok($row->{inputs_unchanged}, "$value->{name}: returned copies preserve every input scalar and byte flag");
    push @{$result->{vectors}}, $row;
}
for my $case (@{$plan->{cleanup_cases}}) {
    my $value = materialize(vector_value(0));
    $value->{entries} = [$value->{entries}[0]];
    $value->{selection} = invoke('selection', $value);
    $value->{receipts} = [{%{$value->{entries}[0]}, outcome => $case->{outcome},
        cleanup => {map { (qw(leader_started leader_reaped group_gone))[$_] => $case->{flags}[$_] } 0..2}}];
    my $before = signature($value); my $output;
    my $accepted = eval { $output = invoke('settlement', $value); 1 }; my $error = $@;
    my $unchanged = signature($value) eq $before ? 1 : 0;
    ok(($accepted ? 1 : 0) == ($case->{accepted} ? 1 : 0) && $unchanged, $case->{name}) or diag($error);
    push @{$result->{cleanup_cases}}, {name => $case->{name}, accepted => $accepted ? 1 : 0,
        error => $error, output => $output, inputs_unchanged => $unchanged};
}
for my $control (@{$plan->{controls}}) {
    my $value = changed($control); my $before = signature($value);
    my $accepted = eval { invoke($control->{operation}, $value, $control->{argument_change}); 1 }; my $error = $@;
    my $unchanged = signature($value) eq $before ? 1 : 0;
    ok(!$accepted && length($error) && $unchanged, $control->{name}) or diag($error || 'unexpected acceptance');
    push @{$result->{controls}}, {name => $control->{name}, rejected => $accepted ? 0 : 1,
        error => $error, inputs_unchanged => $unchanged};
}
for my $mutant (@{$plan->{mutants}}) {
    my ($control) = grep { $_->{name} eq $mutant->{control} } @{$plan->{controls}}; die 'missing mutant witness' unless $control;
    my $value = changed($control); my ($output, $accepted, $error);
    {
        no strict 'refs';
        local *{'NativeProxyObservationWorkRecord::'.$mutant->{helper}} = sub { return 1 };
        $accepted = eval { $output = invoke($control->{operation}, $value); 1 }; $error = $@;
    }
    ok($accepted, "$mutant->{name}: weakened helper accepts invalid settlement") or diag($error);
    push @{$result->{mutants}}, {name => $mutant->{name}, accepted => $accepted ? 1 : 0, error => $error, output => $output};
}
is($lookups, 0, 'no current target or archive helper lookup');
is($forbidden, 0, 'no process attempt');
$result->{success} = Test::More->builder->is_passing ? JSON::PP::true : JSON::PP::false;
$result->{filesystem_lookup_attempts} = $lookups; $result->{forbidden_process_attempts} = $forbidden;
open my $output, '>:raw', "$log/qualification.json" or die "result: $!";
print {$output} JSON::PP->new->canonical->ascii->pretty->encode($result) or die "result write: $!";
close $output or die "result close: $!";
chmod(0600, "$log/qualification.json") == 1 or die "result mode: $!";
done_testing;
