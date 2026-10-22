package UnaryAdmission;
use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use StageObserver;
use JSON::PP ();

my $native = 'docs/audits/native-group-witness-20260927';
my $prior = "$native/priority-observer";
my $audit = 'docs/audits/unary-observer-20261022';
my %target = (qualification => "$prior/control.t", unary => 't/2090-isf-unary-reduction-runtime.t');
my %scenario = map {$_ => 1} qw(healthy query_gap capture_gap retention_gap diagnostic_errno);
sub target { $target{$_[0]} }

sub paths {
    my ($mode) = @_;
    die "unknown fixed observation mode\n" unless exists $target{$mode};
    my @own = map {"$audit/$_"} qw(UnaryAdmission.pm observe.t prepare.pl qualify.t seal.py verify.py);
    my $producers = JSON::PP->new->decode(StageObserver::_read("$audit/producer-paths.json", 131_072));
    die "invalid fixed producer membership\n" unless ref($producers) eq 'ARRAY'
        && @$producers && !grep {ref($_) || !m{\A(?:bin|perl)/[A-Za-z0-9_./-]+\z} || m{(?:\A|/)\.\.(?:/|\z)}} @$producers;
    my %seen;
    die "duplicate fixed producer path\n" if grep {$seen{$_}++} @$producers;
    my @paths = (
        @own, "$audit/producer-paths.json", @$producers,
        "$native/manifest.json", "$native/failure-only/manifest.json",
        "$native/GroupWitness.pm", "$native/failure-only/FailureWitness.pm",
        "$prior/StageObserver.pm", "$prior/manifest.json",
        't/lib/FSM/Test/VerilatorRuntime.pm', 't/lib/FSM/Test/ProcessSupervisor.pm',
        't/lib/FSM/Test/SourceQueryRunner.pm', 't/lib/FSM/Test/ProjectDataLocality.pm',
        $target{$mode},
        $mode eq 'qualification' ? ("$prior/control_setup.pl") : (
            't/data/unary_reduction_runtime.isf', 't/data/unary_reduction_runtime_tb.sv',
            't/data/unary_reduction_runtime_vectors.hex'),
    );
    %seen = ();
    return sort grep {!$seen{$_}++} @paths;
}

sub validate {
    my ($a,$capture) = @_;
    die "invalid closed admission object\n" unless ref($a) eq 'HASH'
        && join(',',sort keys %$a) eq 'capture,expected_stages,mode,scenario,schema,sha256,target';
    for my $key (qw(capture mode scenario schema target)) {
        die "invalid scalar admission field: $key\n" if !defined($a->{$key}) || ref($a->{$key});
    }
    die "wrong admission schema or capture\n" unless $a->{schema} eq 'fsmgen.fixed_unary_observer_admission.v1'
        && $a->{capture} eq $capture && $capture =~ /\A[a-z][a-z0-9_]{0,63}\z/;
    die "target outside fixed observation scope\n" unless exists($target{$a->{mode}})
        && $a->{target} eq $target{$a->{mode}};
    die "invalid fixed scenario\n" unless $a->{mode} eq 'qualification'
        ? $scenario{$a->{scenario}} : $a->{scenario} eq 'none';
    my $counts = $a->{expected_stages};
    die "invalid stage coverage\n" unless ref($counts) eq 'HASH'
        && join(',',sort keys %$counts) eq 'compile,runtime'
        && !grep {!defined($_) || ref($_) || !/\A[1-9][0-9]*\z/ || $_ > 32} values %$counts;
    my ($compile,$runtime) = $a->{mode} eq 'qualification' ? (1,2) : (3,3);
    die "invalid fixed control coverage\n" unless $counts->{compile} == $compile && $counts->{runtime} == $runtime;
    my @paths = paths($a->{mode});
    die "incomplete or additional input identity\n" unless ref($a->{sha256}) eq 'HASH'
        && join('\n',sort keys %{$a->{sha256}}) eq join('\n',@paths);
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
            unless sha256_hex(StageObserver::_read($path,2_097_152)) eq $a->{sha256}{$path};
    }
}
1;
