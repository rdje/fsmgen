package RecordInputAdmission;
use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use StageObserver;

my $native = 'docs/audits/native-group-witness-20260927';
my $prior = "$native/priority-observer";
my $audit = 'docs/audits/record-input-observer-corrected-20261001';
my %target = (qualification => "$prior/control.t", record_input => 't/2024-isf-record-input-runtime.t');
my %scenario = map {$_ => 1} qw(healthy query_gap capture_gap retention_gap diagnostic_errno);
sub target { $target{$_[0]} }

sub paths {
    my ($mode) = @_;
    die "unknown fixed observation mode\n" unless exists $target{$mode};
    my @own = map {"$audit/$_"} qw(RecordInputAdmission.pm observe.t prepare.pl qualify.t seal.py verify.py);
    my @paths = (
        @own,
        "$native/manifest.json", "$native/failure-only/manifest.json",
        "$native/GroupWitness.pm", "$native/failure-only/FailureWitness.pm",
        "$prior/StageObserver.pm", "$prior/manifest.json",
        't/lib/FSM/Test/VerilatorRuntime.pm', 't/lib/FSM/Test/ProcessSupervisor.pm',
        't/lib/FSM/Test/SourceQueryRunner.pm', 't/lib/FSM/Test/ProjectDataLocality.pm',
        'perl/FSM/Support/ProcessSupervisor.pm', $target{$mode},
        $mode eq 'qualification' ? ("$prior/control_setup.pl") : (
            't/data/isf_record_input_runtime.isf', 't/data/isf_record_input_runtime_tb.sv',
            'bin/fsmgen', 'perl/FSM/Adapter/ISF/Parser.pm',
            'perl/FSM/Scheduler/ISF/LoweringIR.pm', 'perl/FSM/Scheduler/ISF/Emitter/FSM.pm',
            'perl/FSM/Scheduler/ISF/Emitter/JSON.pm',
            'perl/FSM/Support/ISFRecordPortContexts.pm', 'perl/FSM/Support/ISFRecordPortValues.pm',
            'perl/FSM/Support/ISFRecordPortScopes.pm', 'perl/FSM/Support/ISFInterfacePortMetadata.pm',
            'perl/FSM/Package/AggregatePathSupport.pm',
            'perl/FSM/Backend/VerilogFamily/TypeDeclarationSupport.pm',
            'perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm'),
    );
    return sort @paths;
}

sub validate {
    my ($input,$capture) = @_;
    die "invalid closed admission object\n" unless ref($input) eq 'HASH';
    # Perl's string/numeric inspection can alter scalar flags. Keep all
    # inspected values detached so validation preserves the caller's JSON kinds.
    my $a = {%$input};
    for my $key (qw(expected_stages sha256)) {
        $a->{$key} = {%{$a->{$key}}} if ref($a->{$key}) eq 'HASH';
    }
    die "invalid closed admission object\n" unless
        join(',',sort keys %$a) eq 'capture,expected_stages,mode,scenario,schema,sha256,target';
    for my $key (qw(capture mode scenario schema target)) {
        die "invalid scalar admission field: $key\n" if !defined($a->{$key}) || ref($a->{$key});
    }
    die "wrong admission schema or capture\n" unless $a->{schema} eq 'fsmgen.fixed_record_input_observer_admission.v1'
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
