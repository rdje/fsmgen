#!/usr/bin/env perl
use strict;
use warnings;
use Config;
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use Fcntl qw(O_WRONLY O_CREAT O_EXCL O_APPEND);
use JSON::PP;
use lib 'perl', 't/lib', 'docs/audits/native-group-witness-20260927';
use FSM::Test::ProjectDataLocality;
use FSM::Test::VerilatorRuntime ();
use FSM::Test::SourceQueryRunner ();
use GroupWitness;

my $audit = 'docs/audits/native-group-witness-20260927';
my $work = '.artifacts/native-group-witness/original';
my $root = abs_path('.');
my $json = JSON::PP->new->canonical->utf8;

sub witness_read {
    open my $fh, '<:raw', $_[0] or die "read witness input: $!";
    local $/;
    my $data = <$fh>;
    close $fh or die "close witness input: $!";
    return $data;
}

my $admission = $json->decode(witness_read("$audit/original/admission.json"));
my $qualification = $json->decode(witness_read("$audit/manifest.json"));
die "unexpected Perl ABI\n" unless $Config{version} eq $qualification->{build}{perl_version};
die "runtime qualification not enabled\n"
    unless ($ENV{FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME} // '') eq '1';
die "unexpected injected Perl configuration\n" if $ENV{PERL5OPT};
for my $name (sort keys %{$qualification->{sha256}}) {
    die "witness qualification changed: $name\n"
        unless sha256_hex(witness_read("$audit/$name")) eq $qualification->{sha256}{$name};
}
my $helper = '.artifacts/native-group-witness/context.bundle';
die "qualified helper binary changed\n"
    unless sha256_hex(witness_read($helper)) eq $qualification->{build}{binary_sha256};
for my $path (sort keys %{$admission->{sha256}}) {
    die "original input changed: $path\n"
        unless sha256_hex(witness_read($path)) eq $admission->{sha256}{$path};
}

# The fixed destination is exclusive: this observer cannot silently rerun.
mkdir $work or die "original observation already exists or cannot be created: $!";
sysopen my $sink, "$work/events.jsonl", O_WRONLY | O_CREAT | O_EXCL | O_APPEND, 0600
    or die "exclusive original witness capture: $!";
GroupWitness->load_context(abs_path($helper));
GroupWitness->install($sink);
GroupWitness::record({event => 'begin', context => GroupWitness::context(0),
    admission_sha256 => sha256_hex(witness_read("$audit/original/admission.json")),
    qualification_sha256 => sha256_hex(witness_read("$audit/manifest.json"))});

my ($stage_sequence, @retention_errors);
$stage_sequence = 0;
for my $item ([run_verilator_compile => 'compile'], [run_generated_binary => 'runtime']) {
    my ($method, $stage) = @$item;
    no strict 'refs';
    no warnings 'redefine';
    my $original = \&{"FSM::Test::VerilatorRuntime::$method"};
    *{"FSM::Test::VerilatorRuntime::$method"} = sub {
        my @arguments = @_;
        my $label = sprintf('%02d_%s', ++$stage_sequence, $stage);
        local $GroupWitness::label = $label;
        GroupWitness::record({event => 'stage_begin', label => $label, stage => $stage});
        my $result = $original->(@arguments);
        my $saved_errno = 0 + $!;
        # Retain every result. Only the exact repository prefix is normalized;
        # the original result reference returned to T1972 is untouched.
        my $captured = FSM::Test::SourceQueryRunner::normalize_repository_paths(
            {arguments => \@arguments, result => $result}, $root);
        my $retained = eval {
            my $data = $json->encode($captured) . "\n";
            my $path = "$work/$label.json";
            sysopen my $fh, $path, O_WRONLY | O_CREAT | O_EXCL, 0600
                or die "exclusive original result: $!";
            print {$fh} $data or die "write original result: $!";
            close $fh or die "close original result: $!";
            GroupWitness::record({event => 'stage_result', label => $label,
                path => $path, sha256 => sha256_hex($data)});
            1;
        };
        push @retention_errors, $@ unless $retained;
        $! = $saved_errno;
        return $result;
    };
}

my $completed = do './t/1972-isf-constant-false-guards.t';
my $test_error = $@;
die "original test failed to load: $test_error $!\n" unless defined $completed;
for my $path (sort keys %{$admission->{sha256}}) {
    die "original input changed during observation: $path\n"
        unless sha256_hex(witness_read($path)) eq $admission->{sha256}{$path};
}
GroupWitness::record({event => 'end', stages => $stage_sequence,
    context => GroupWitness::context(0), capture_error => GroupWitness::capture_error(),
    retention_errors => \@retention_errors});
close $sink or die "close original witness: $!";
die "original witness retention failed\n" if @retention_errors || GroupWitness::capture_error();
