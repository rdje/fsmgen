package IndexObserver;
use strict;
use warnings;
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use Fcntl qw(O_WRONLY O_CREAT O_EXCL);
use JSON::PP ();
use FailureWitness;
use FSM::Test::TaskAcceptanceIndexRuntime ();

our $AUDIT = 'docs/audits/task-acceptance-index-observer-20261017';
our $WORK = '.artifacts/task-acceptance-index-observer-20261017';
my $NATIVE = 'docs/audits/native-group-witness-20260927';
my %targets = (
    index => 't/2068-task-acceptance-index-runtime.t',
    policy => 't/2070-audit-index-fixture-policy.t',
    scope => 't/2071-audit-source-acceptance.t',
);
my %counts = (index => [14, 57, 6], policy => [40, 342, 36], scope => [20, 199, 20]);
my %scenarios = map { $_ => 1 } qw(healthy query_gap write_gap retention_gap diagnostic_errno coverage_gap);

sub selection {
    my ($selector) = @_;
    for my $name (sort keys %targets) {
        return ($name, $targets{$name}, 'none', $counts{$name}) if $selector eq $targets{$name};
    }
    return ($selector, "$AUDIT/control.t", $1, [3, 21, 2])
        if $selector =~ /\Acontrol_([a-z_]+)\z/ && $scenarios{$1};
    die "target outside fixed index observation scope\n";
}

sub paths {
    return sort { $a cmp $b } (
        (map { "$AUDIT/$_" } qw(IndexObserver.pm Control.pm control.t observe.pl qualify.t run.py verify.py)),
        (values %targets),
        "$NATIVE/manifest.json", "$NATIVE/GroupWitness.pm", "$NATIVE/context.c",
        "$NATIVE/failure-only/manifest.json", "$NATIVE/failure-only/FailureWitness.pm",
        qw(t/lib/FSM/Test/TaskAcceptanceIndexRuntime.pm t/lib/FSM/Test/ProcessSupervisor.pm
           t/lib/FSM/Test/ProjectDataLocality.pm perl/FSM/Support/ProcessSupervisor.pm
           perl/FSM/ProjectDataLocality.pm scripts/check_task_acceptance.sh
           doctrine/task_acceptance/change_paths.tsv doctrine/task_acceptance/evidence_signatures.tsv
           docs/tasks/TASK-ACCEPTANCE-PORTABLE-DOCTRINE.md .proverc
           scripts/run_with_ram_guard.sh scripts/project_data_locality_env.sh),
    );
}

sub admission {
    my ($selector) = @_;
    my ($name, $target, $scenario, $expected) = selection($selector);
    return {schema => 'fsmgen.fixed_index_observer_admission.v1', selector => $selector,
        target => $target, scenario => $scenario, expected => $expected,
        sha256 => {map { $_ => sha256_hex(read_bytes($_, 2_097_152)) } paths()}};
}

sub validate {
    my ($admission, $selector) = @_;
    die "closed observer admission or source identity changed\n"
        unless encode($admission) eq encode(admission($selector));
    my %allowed = map {abs_path($_) => 1} paths();
    my $root = abs_path('.');
    for my $path (values %INC) {
        next unless defined($path) && -f $path;
        my $resolved = abs_path($path);
        die "unbound loaded project source: $path\n"
            if index($resolved, "$root/") == 0 && !$allowed{$resolved};
    }
    return 1;
}

sub read_bytes {
    my ($path, $limit) = @_;
    die "observer input exceeds envelope: $path\n" unless -f $path && !-l $path && -s $path <= $limit;
    open my $fh, '<:raw', $path or die "read observer input: $!";
    local $/;
    my $body = <$fh>;
    close $fh or die "close observer input: $!";
    return $body;
}

sub encode { return JSON::PP->new->canonical->utf8->encode($_[0]) }

sub save {
    my ($path, $body) = @_;
    sysopen my $fh, $path, O_WRONLY | O_CREAT | O_EXCL, 0600 or die "exclusive observer retention: $!";
    print {$fh} $body or die "write observer retention: $!";
    close $fh or die "close observer retention: $!";
}

# Normalize this checkout prefix only. Preserve field kinds and every result
# value; the complete environment is compared in memory, never exported.
sub normalize {
    my ($value) = @_;
    return {map { $_ => normalize($value->{$_}) } keys %$value} if ref($value) eq 'HASH';
    return [map { normalize($_) } @$value] if ref($value) eq 'ARRAY';
    return $value if !defined($value) || ref($value);
    my $text = $value;
    my $root = abs_path('.');
    return $value unless index($text, $root) >= 0;
    return '.' if $text eq $root;
    $text =~ s{\Q$root\E/}{}g;
    return $text;
}

sub new {
    my ($class, $sink, $directory) = @_;
    return bless {witness => FailureWitness->new($sink, 'outside_stage'), directory => $directory,
        receipts => [], errors => [], stages => 0, cases => 0, index_git => 0, index_checker => 0}, $class;
}

sub retain {
    my ($self, $label, $record, $limit) = @_;
    my $data = encode(normalize($record)) . "\n";
    die "observer retention envelope exceeded\n" if length($data) > $limit;
    save("$self->{directory}/$label.json", $data);
    push @{$self->{receipts}}, {label => $label, sha256 => sha256_hex($data)};
}

sub install {
    my ($self) = @_;
    die "observer already installed\n" if $self->{installed}++;
    no warnings 'redefine';
    *FSM::Support::ProcessSupervisor::setpgid =
        $self->{witness}->wrap(\&FSM::Support::ProcessSupervisor::setpgid);
    my $supervise = \&FSM::Test::TaskAcceptanceIndexRuntime::supervise_process;
    *FSM::Test::TaskAcceptanceIndexRuntime::supervise_process = sub {
        my @arguments = @_;
        my %args = @arguments;
        my $number = ++$self->{stages};
        my $label = 'stage_' . letters($number);
        local $self->{witness}{label} = $label;
        my $result = $supervise->(@arguments);
        my $errno = 0 + $!;
        eval {
            die "stage outside fixed population\n" unless $number <= 700
                && ($args{stage} eq 'index_git' || $args{stage} eq 'index_checker');
            ++$self->{$args{stage}};
            $self->retain($label, {kind => 'stage', arguments => {map {$_ => $args{$_}}
                qw(argv schema stage containment bounds cwd)}, result => $result},
                8 * $args{bounds}{capture_limit_bytes} + 65_536);
            1;
        } or push @{$self->{errors}}, {label => $label, error => "$@"};
        $! = $errno;
        return $result;
    };
    my $run = \&FSM::Test::TaskAcceptanceIndexRuntime::run_index_case;
    *FSM::Test::TaskAcceptanceIndexRuntime::run_index_case = sub {
        my @arguments = @_;
        my $number = ++$self->{cases};
        my $first_stage = $self->{stages} + 1;
        my $result = $run->(@arguments);
        my $errno = 0 + $!;
        eval {
            die "case population exceeds envelope\n" if $number > 80;
            $self->retain('case_' . letters($number), {kind => 'case', arguments => \@arguments,
                first_stage => $first_stage, last_stage => $self->{stages}, result => $result}, 67_108_864);
            1;
        } or push @{$self->{errors}}, {label => 'case_' . letters($number), error => "$@"};
        $! = $errno;
        return $result;
    };
}

sub capture_gaps {
    my ($self) = @_;
    my $bytes = read_bytes("$self->{directory}/events.jsonl", 1_048_576);
    die "partial native capture\n" if length($bytes) && $bytes !~ /\n\z/;
    my @events = map {JSON::PP->new->decode($_)} split /\n/, $bytes;
    my (%joined, @gaps);
    for my $receipt (@{$self->{receipts}}) {
        my $data = read_bytes("$self->{directory}/$receipt->{label}.json", 67_108_864);
        die "retained receipt changed\n" unless sha256_hex($data) eq $receipt->{sha256};
        my $row = JSON::PP->new->decode($data);
        next unless $row->{kind} eq 'stage'
            && ($row->{result}{exec_error} // '') =~ /pid=(\d+) operation=setpgid result=\S+ errno=(\d+)/;
        my ($pid, $errno) = ($1, $2);
        my @matches = grep {($_->{label} // '') eq $receipt->{label}
            && ($_->{pid} // 0) == $pid && ($_->{errno} // -1) == $errno} @events;
        if (@matches != 1) {
            push @gaps, {kind => 'missing_or_duplicate_native_event', label => $receipt->{label}, pid => 0 + $pid};
            next;
        }
        my $event = $matches[0];
        $joined{$event->{label} . ':' . $pid} = 1;
        die "invalid native rejection\n" unless ($event->{event} // '') eq 'child_setpgid_failure'
            && encode($event->{arguments}) eq '[0,0]' && !defined($event->{result});
        if (defined($event->{context_error})) {
            push @gaps, {kind => 'native_context_query', label => $event->{label}, error => $event->{context_error}};
            next;
        }
        for my $who (qw(caller target)) {
            my $context = $event->{context}{$who};
            die "incomplete native context\n" unless ref($context) eq 'HASH'
                && !grep {!exists $context->{$_}} qw(pid pgid sid pgid_errno sid_errno);
            for my $field (qw(pgid_errno sid_errno)) {
                push @gaps, {kind => 'native_context_query_result', label => $event->{label}, query => "$who.$field"}
                    if $context->{$field};
            }
        }
    }
    push @gaps, {kind => 'unjoined_native_event', label => $_->{label}, pid => $_->{pid}}
        for grep {!$joined{($_->{label} // '') . ':' . ($_->{pid} // '')}} @events;
    return \@gaps;
}

sub finish {
    my ($self, $admission, $input_error, $test_error) = @_;
    my $gaps = eval {$self->capture_gaps()};
    $gaps = [{kind => 'capture_validation', error => "$@"}] if $@;
    my $actual = [@{$self}{qw(cases index_git index_checker)}];
    my $summary = {schema => 'fsmgen.fixed_index_observation.v1', actual => $actual,
        coverage_error => encode($actual) ne encode($admission->{expected}) ? 'fixed population differs' : undef,
        receipt_coverage_error => @{$self->{receipts}} != $self->{cases} + $self->{stages}
            ? 'missing retained receipt' : undef,
        admission_sha256 => sha256_hex(encode($admission)), receipts => $self->{receipts},
        retention_errors => $self->{errors}, capture_gaps => $gaps,
        input_error => $input_error, test_error => $test_error};
    save("$self->{directory}/summary.json", encode($summary) . "\n");
    return $summary;
}

sub letters {
    my ($number) = @_;
    my $label = '';
    while ($number) {--$number; $label = chr(97 + $number % 26) . $label; $number = int($number / 26)}
    return $label;
}
1;
