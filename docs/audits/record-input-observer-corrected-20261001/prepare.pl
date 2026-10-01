#!/usr/bin/env perl
use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use Fcntl qw(O_WRONLY O_CREAT O_EXCL);
use JSON::PP;
use lib 'perl', 't/lib', 'docs/audits/native-group-witness-20260927',
    'docs/audits/native-group-witness-20260927/failure-only',
    'docs/audits/native-group-witness-20260927/priority-observer',
    'docs/audits/record-input-observer-corrected-20261001';
use FSM::Test::ProjectDataLocality;
use RecordInputAdmission;

my ($name, $mode, $scenario, $compile, $runtime) = @ARGV;
die "usage: prepare.pl capture mode scenario compile-count runtime-count\n" unless @ARGV == 5;
my $admission = {schema => 'fsmgen.fixed_record_input_observer_admission.v1', capture => $name,
    mode => $mode, scenario => $scenario, target => RecordInputAdmission::target($mode),
    expected_stages => {compile => $compile, runtime => $runtime},
    sha256 => {map {$_ => sha256_hex(StageObserver::_read($_, 2_097_152))} RecordInputAdmission::paths($mode)}};
RecordInputAdmission::validate($admission, $name);
# This newly constructed CLI packet owns numeric coverage on disk. Validation
# itself remains observational for callers, including numeric-string callers.
$admission->{expected_stages} = {compile => 0 + $compile, runtime => 0 + $runtime};
sysopen my $fh, ".artifacts/record-input-native-observer-corrected/$name-admission.json",
    O_WRONLY | O_CREAT | O_EXCL, 0600 or die "exclusive admission: $!";
print {$fh} JSON::PP->new->canonical->encode($admission), "\n" or die $!;
close $fh or die $!;
