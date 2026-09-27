package StageObserver;
use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use Fcntl qw(O_WRONLY O_CREAT O_EXCL);
use JSON::PP;
use FailureWitness;
use FSM::Test::SourceQueryRunner ();
use FSM::Test::VerilatorRuntime ();

sub new {
    my ($class, $sink, $work, $root) = @_;
    die "observer requires an existing private work directory\n" unless -d $work;
    return bless {witness => FailureWitness->new($sink, 'outside_stage'),
        work => $work, root => $root, sequence => 0, receipts => [], errors => []}, $class;
}

sub install {
    my ($self) = @_;
    die "observer already installed\n" if $self->{installed}++;
    no warnings 'redefine';
    my $native = \&FSM::Support::ProcessSupervisor::setpgid;
    *FSM::Support::ProcessSupervisor::setpgid = $self->{witness}->wrap($native);
    for my $item ([run_verilator_compile => 'compile'], [run_generated_binary => 'runtime']) {
        my ($method, $stage) = @$item;
        no strict 'refs';
        my $original = \&{"FSM::Test::VerilatorRuntime::$method"};
        *{"FSM::Test::VerilatorRuntime::$method"} = sub {
            my @arguments = @_;
            my $number = ++$self->{sequence};
            # The selected test is finite. Labels remain valid native-witness
            # labels without converting stages to context queries on success.
            my $label = $stage . '_' . _letters($number);
            local $self->{witness}{label} = $label;
            my $result = $original->(@arguments);
            my $native_errno = 0 + $!;
            my $saved = eval {
                my $copy = FSM::Test::SourceQueryRunner::normalize_repository_paths(
                    {arguments => \@arguments, result => $result}, $self->{root});
                my $data = JSON::PP->new->canonical->utf8->encode($copy) . "\n";
                # JSON escaping can expand bounded original output. This cap
                # belongs to diagnostic retention, not the supervised command.
                my $limit = ref($result) eq 'HASH' ? ($result->{capture_limit_bytes} // 0) : 0;
                die "invalid original capture bound\n" unless $limit =~ /\A[0-9]+\z/;
                die "observer result retention envelope exceeded\n"
                    if $number > 64 || length($data) > 8 * $limit + 65_536;
                $self->_save("$label.json", $data);
                push @{$self->{receipts}}, {label => $label, stage => $stage,
                    path => "$label.json", sha256 => sha256_hex($data)};
                1;
            };
            push @{$self->{errors}}, {label => $label, error => "$@"} unless $saved;
            $! = $native_errno;
            return $result;
        };
    }
}

sub _save {
    my ($self, $name, $data) = @_;
    sysopen my $fh, "$self->{work}/$name", O_WRONLY | O_CREAT | O_EXCL, 0600
        or die "exclusive observer result: $!";
    print {$fh} $data or die "write observer result: $!";
    close $fh or die "close observer result: $!";
}

sub finish {
    my ($self, $admission_sha256, $input_error, $test_error) = @_;
    my $gaps = eval {$self->_capture_gaps()};
    $gaps = [{kind => 'capture_validation', error => "$@"}] if $@;
    my $summary = {schema => 'fsmgen.priority_stage_observation.v1',
        admission_sha256 => $admission_sha256, stages => $self->{sequence},
        receipts => $self->{receipts}, retention_errors => $self->{errors},
        capture_gaps => $gaps,
        input_error => $input_error, test_error => $test_error};
    $self->_save('summary.json', JSON::PP->new->canonical->utf8->encode($summary) . "\n");
    return $summary;
}

sub _capture_gaps {
    my ($self) = @_;
    my $json = JSON::PP->new;
    my $bytes = _read("$self->{work}/events.jsonl", 1_048_576);
    die "partial native capture\n" if length($bytes) && $bytes !~ /\n\z/;
    my @events = map {$json->decode($_)} split /\n/, $bytes;
    for my $event (@events) {
        die "invalid native failure event\n" unless ref($event) eq 'HASH'
            && ($event->{event} // '') eq 'child_setpgid_failure'
            && ($event->{label} // '') =~ /\A[a-z_]{1,64}\z/
            && ($event->{pid} // '') =~ /\A[1-9][0-9]*\z/
            && ref($event->{arguments}) eq 'ARRAY' && @{$event->{arguments}} == 2
            && $event->{arguments}[0] == 0 && $event->{arguments}[1] == 0
            && !(defined($event->{result}) && $event->{result} == 0);
        die "missing native context without diagnostic\n"
            unless defined($event->{context_error}) || ref($event->{context}) eq 'HASH';
    }
    my (@gaps, %joined);
    for my $receipt (@{$self->{receipts}}) {
        my $data = _read("$self->{work}/$receipt->{path}", 536_936_448);
        die "retained result changed\n" unless sha256_hex($data) eq $receipt->{sha256};
        my $result = $json->decode($data)->{result};
        next unless ($result->{exec_error} // '') =~ /pid=(\d+) operation=setpgid result=\S+ errno=(\d+)/;
        my ($pid, $errno) = ($1, $2);
        my @matches = grep {$_->{label} eq $receipt->{label} && $_->{pid} == $pid && $_->{errno} == $errno} @events;
        if (@matches != 1) {
            push @gaps, {kind => 'missing_or_duplicate_native_event', label => $receipt->{label}, pid => 0 + $pid};
            next;
        }
        $joined{$receipt->{label} . ':' . $pid} = 1;
        push @gaps, {kind => 'native_context_query', label => $receipt->{label},
            pid => 0 + $pid, error => $matches[0]{context_error}}
            if defined $matches[0]{context_error};
        my $context = $matches[0]{context};
        if (ref($context) eq 'HASH') {
            for my $who (qw(caller target)) {
                die "incomplete native query context\n" unless ref($context->{$who}) eq 'HASH'
                    && !grep {!exists $context->{$who}{$_}} qw(pid pgid sid pgid_errno sid_errno);
                for my $field (qw(pgid_errno sid_errno)) {
                    push @gaps, {kind => 'native_context_query_result', label => $receipt->{label},
                        pid => 0 + $pid, query => "$who.$field", errno => $context->{$who}{$field}}
                        if $context->{$who}{$field};
                }
            }
        }
    }
    for my $event (@events) {
        push @gaps, {kind => 'unjoined_native_event', label => $event->{label}, pid => $event->{pid}}
            unless $joined{$event->{label} . ':' . $event->{pid}};
    }
    return \@gaps;
}

sub _read {
    my ($path, $limit) = @_;
    die "observer input exceeds envelope\n" unless -f $path && -s $path <= $limit;
    open my $fh, '<:raw', $path or die "read observer input: $!";
    local $/;
    my $data = <$fh>;
    close $fh or die "close observer input: $!";
    return $data;
}

sub _letters {
    my ($number) = @_;
    my $label = '';
    while ($number) {
        --$number;
        $label = chr(97 + $number % 26) . $label;
        $number = int($number / 26);
    }
    return $label;
}
1;
