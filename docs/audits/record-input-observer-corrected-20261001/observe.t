#!/usr/bin/env perl
use strict;
use warnings;
use Config;
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use Fcntl qw(O_WRONLY O_CREAT O_EXCL O_APPEND);
use JSON::PP;
use lib 'perl', 't/lib', 'docs/audits/native-group-witness-20260927',
    'docs/audits/native-group-witness-20260927/failure-only',
    'docs/audits/native-group-witness-20260927/priority-observer',
    'docs/audits/record-input-observer-corrected-20261001';
use FSM::Test::ProjectDataLocality;
use GroupWitness;
use StageObserver;
use RecordInputAdmission;

my $base = 'docs/audits/native-group-witness-20260927';
my $audit = 'docs/audits/record-input-observer-corrected-20261001';
my $name = shift @ARGV;
die "one fixed admission name is required\n"
    unless defined($name) && $name =~ /\A[a-z][a-z0-9_]*\z/ && !@ARGV;
die "unexpected injected Perl configuration\n" if $ENV{PERL5OPT};
die "runtime qualification must be explicitly enabled\n"
    unless ($ENV{FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME} // '') eq '1';
my $json = JSON::PP->new;
my $admission_bytes = StageObserver::_read(".artifacts/record-input-native-observer-corrected/$name-admission.json", 65_536);
my $admission = $json->decode($admission_bytes);
RecordInputAdmission::validate($admission, $name);
my $qualification = $json->decode(StageObserver::_read("$base/manifest.json", 65_536));
die "native helper Perl ABI changed\n" unless $Config{version} eq $qualification->{build}{perl_version};
for my $name (sort keys %{$qualification->{sha256}}) {
    die "native qualification input changed: $name\n"
        unless sha256_hex(StageObserver::_read("$base/$name", 2_097_152)) eq $qualification->{sha256}{$name};
}
my $failure = $json->decode(StageObserver::_read("$base/failure-only/manifest.json", 65_536));
for my $name (sort keys %{$failure->{sha256}}) {
    die "failure-only qualification input changed: $name\n"
        unless sha256_hex(StageObserver::_read("$base/failure-only/$name", 2_097_152)) eq $failure->{sha256}{$name};
}
my $helper = '.artifacts/native-group-witness/context.bundle';
die "native helper binary changed\n"
    unless sha256_hex(StageObserver::_read($helper, 2_097_152)) eq $qualification->{build}{binary_sha256};
if ($admission->{mode} eq 'record_input') {
    die "record-input observer qualification required\n" unless -f "$audit/manifest.json";
    my $sealed = $json->decode(StageObserver::_read("$audit/manifest.json", 65_536));
    die "record-input observer qualification required\n"
        unless $sealed->{schema} eq 'fsmgen.fixed_record_input_observer_qualification.v1';
    for my $name (sort keys %{$sealed->{sha256}}) {
        die "qualified observer source changed: $name\n"
            unless sha256_hex(StageObserver::_read("$audit/$name", 2_097_152)) eq $sealed->{sha256}{$name};
    }
    $ENV{FSMGEN_RECORD_INPUT_RUNTIME} = 1;
}
RecordInputAdmission::check_inputs($admission);
our $observer_work = ".artifacts/record-input-native-observer-corrected/$name";
our $observer_scenario = $admission->{scenario};
mkdir $observer_work or die "exclusive observer work directory: $!";
sysopen my $sink, "$observer_work/events.jsonl", O_WRONLY | O_CREAT | O_EXCL | O_APPEND, 0600 or die $!;
GroupWitness->load_context(abs_path($helper));
if ($admission->{mode} eq 'qualification') {
    do "./$base/priority-observer/control_setup.pl" or die "control setup failed: $@ $!";
}
my $observer = StageObserver->new($sink, $observer_work, abs_path('.'));
$observer->install();
ControlFixture::after_install() if $admission->{mode} eq 'qualification';
my $completed = do "./$admission->{target}";
my $test_error = defined($completed) ? undef : ($@ || "test load failed: $!");
eval {RecordInputAdmission::check_inputs($admission); 1};
my $input_error = $@ || undef;
my $summary = $observer->finish(sha256_hex($admission_bytes), $input_error, $test_error);
close $sink or die "close native capture: $!";
my %actual = (compile => 0, runtime => 0);
++ $actual{$_->{stage}} for @{$summary->{receipts}};
die "original test failed: $test_error\n" if $test_error;
die "observed inputs changed: $input_error\n" if $input_error;
die "observer diagnostic gaps retained in summary.json\n"
    if @{$summary->{retention_errors}} || @{$summary->{capture_gaps}};
die "observed stage coverage differs from admission\n"
    if grep {$actual{$_} != $admission->{expected_stages}{$_}} keys %actual;
