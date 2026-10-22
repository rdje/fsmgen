#!/usr/bin/env perl
use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use Fcntl qw(O_WRONLY O_CREAT O_EXCL);
use JSON::PP;
use lib 'perl', 't/lib', 'docs/audits/native-group-witness-20260927',
    'docs/audits/native-group-witness-20260927/failure-only',
    'docs/audits/native-group-witness-20260927/priority-observer',
    'docs/audits/unary-observer-20261022';
use FSM::Test::ProjectDataLocality;
use UnaryAdmission;

my ($name, $mode, $scenario, $compile, $runtime) = @ARGV;
die "usage: prepare.pl capture mode scenario compile-count runtime-count\n" unless @ARGV == 5;
my $admission = {schema => 'fsmgen.fixed_unary_observer_admission.v1', capture => $name,
    mode => $mode, scenario => $scenario, target => UnaryAdmission::target($mode),
    expected_stages => {compile => $compile, runtime => $runtime},
    sha256 => {map {$_ => sha256_hex(StageObserver::_read($_, 2_097_152))} UnaryAdmission::paths($mode)}};
UnaryAdmission::validate($admission, $name);
sysopen my $fh, ".artifacts/unary-native-observer/$name-admission.json",
    O_WRONLY | O_CREAT | O_EXCL, 0600 or die "exclusive admission: $!";
print {$fh} JSON::PP->new->canonical->encode($admission), "\n" or die $!;
close $fh or die $!;
