package Admission;
use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use StageObserver;

my $base = 'docs/audits/native-group-witness-20260927';
my $audit = "$base/priority-observer";
my %targets = (qualification => "$audit/control.t", priority => 't/1974-isf-priority-contributor-union.t');
my %scenarios = map {$_ => 1} qw(healthy query_gap capture_gap retention_gap diagnostic_errno);

sub target { return $targets{$_[0]} }

sub paths {
    my ($mode) = @_;
    die "unknown fixed observation mode\n" unless exists $targets{$mode};
    my @paths = (
        "$audit/Admission.pm", "$audit/StageObserver.pm", "$audit/observe.t",
        "$base/manifest.json", "$base/failure-only/manifest.json",
        "$base/GroupWitness.pm", "$base/failure-only/FailureWitness.pm",
        't/lib/FSM/Test/VerilatorRuntime.pm', 't/lib/FSM/Test/ProcessSupervisor.pm',
        't/lib/FSM/Test/SourceQueryRunner.pm', 't/lib/FSM/Test/ProjectDataLocality.pm',
        'perl/FSM/Support/ProcessSupervisor.pm',
        $targets{$mode},
        $mode eq 'qualification' ? ("$audit/control_setup.pl") : (
            'perl/FSM/Scheduler/ISF/LoweringIR.pm', 'perl/FSM/Scheduler/ISF/Emitter/FSM.pm',
            'bin/fsmgen', 'bin/fsmgen-mcp'),
    );
    return sort @paths;
}

sub validate {
    my ($a, $capture) = @_;
    die "invalid closed admission object\n" unless ref($a) eq 'HASH'
        && join(',', sort keys %$a) eq 'capture,expected_stages,mode,scenario,schema,sha256,target';
    for my $key (qw(capture mode scenario schema target)) {
        die "invalid scalar admission field: $key\n" if !defined($a->{$key}) || ref($a->{$key});
    }
    die "wrong admission schema or capture\n" unless $a->{schema} eq 'fsmgen.fixed_priority_observer_admission.v1'
        && $a->{capture} eq $capture && $capture =~ /\A[a-z][a-z0-9_]{0,63}\z/;
    die "target outside fixed observation scope\n" unless exists($targets{$a->{mode}})
        && $a->{target} eq $targets{$a->{mode}};
    die "invalid fixed scenario\n" unless $a->{mode} eq 'qualification'
        ? $scenarios{$a->{scenario}} : $a->{scenario} eq 'none';
    my $counts = $a->{expected_stages};
    die "invalid stage coverage\n" unless ref($counts) eq 'HASH'
        && join(',', sort keys %$counts) eq 'compile,runtime'
        && !grep {!defined($_) || ref($_) || !/\A[1-9][0-9]*\z/ || $_ > 32} values %$counts;
    die "invalid fixed control coverage\n" if $a->{mode} eq 'qualification'
        && ($counts->{compile} != 1 || $counts->{runtime} != 2);
    my @paths = paths($a->{mode});
    die "incomplete or additional input identity\n" unless ref($a->{sha256}) eq 'HASH'
        && join('\n', sort keys %{$a->{sha256}}) eq join('\n', @paths);
    for my $path (@paths) {
        die "invalid input digest: $path\n" unless defined($a->{sha256}{$path})
            && !ref($a->{sha256}{$path}) && $a->{sha256}{$path} =~ /\A[0-9a-f]{64}\z/;
    }
    return 1;
}

sub check_inputs {
    my ($a) = @_;
    for my $path (paths($a->{mode})) {
        die "observation input changed: $path\n"
            unless sha256_hex(StageObserver::_read($path, 2_097_152)) eq $a->{sha256}{$path};
    }
}
1;
