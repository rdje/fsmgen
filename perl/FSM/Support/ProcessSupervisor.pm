package FSM::Support::ProcessSupervisor;

=head1 NAME

FSM::Support::ProcessSupervisor - Caller-sealed repository-local process supervision

=head1 DESCRIPTION

Provides one internal shell-free process engine for the sealed HDL-validation
and test-policy boundaries. It captures stdout and stderr separately under one
aggregate limit, owns a process group, and proves leader/group cleanup before
returning a structured first-attempt result. It is not a public command runner.

=cut

use strict;
use warnings;

use bytes ();
use Cwd qw(abs_path);
use Errno qw(EAGAIN ECHILD EINTR EPERM EWOULDBLOCK);
use Exporter qw(import);
use Fcntl qw(FD_CLOEXEC F_GETFD F_GETFL F_SETFD F_SETFL O_NONBLOCK);
use File::Basename qw(dirname);
use File::Spec;
use IO::Select;
use POSIX qw(WNOHANG _exit setpgid);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep);

use FSM::ProjectDataLocality ();

our @EXPORT_OK = qw(
    process_failure
    repository_contained_path
    repository_root
    supervise_process
    validate_argument_vector
);

my $READ_CHUNK_BYTES = 65_536;
my $CONTROL_LIMIT_BYTES = 2_048;
my $TERM_GRACE_SECONDS = 2;
my $KILL_GRACE_SECONDS = 2;
my %SUPERVISION_CALLER = map { $_ => 1 } qw(
    FSM::Support::HDLExternalValidation
    FSM::Test::ProcessSupervisor
);

my $REPO_ROOT = FSM::ProjectDataLocality::repository_root();
my @REPO_STAT = stat($REPO_ROOT);
die "cannot stat repository root for FSM::Support::ProcessSupervisor: $!"
    unless @REPO_STAT;
my $REPO_DEVICE = $REPO_STAT[0];

sub repository_root {
    return $REPO_ROOT;
}

sub validate_argument_vector {
    my ($argv) = @_;
    return 'command must be one non-empty scalar argument vector'
        unless ref($argv) eq 'ARRAY' && @$argv;
    return 'command arguments must be defined scalars without NUL bytes'
        if grep { !defined($_) || ref($_) || /\x00/ } @$argv;
    return undef;
}

sub repository_contained_path {
    my ($path, %args) = @_;
    my $must_exist = delete($args{must_exist}) // 0;
    die "unknown repository_contained_path argument: $_\n"
        for sort keys %args;
    die "repository_contained_path must_exist must be 0 or 1\n"
        unless $must_exist == 0 || $must_exist == 1;
    return (undef, 'path must be one non-empty scalar')
        unless defined($path) && !ref($path) && length($path)
            && index($path, "\0") < 0;
    my @component = File::Spec->splitdir($path);
    return (undef, 'parent traversal is forbidden')
        if grep { $_ eq '..' } @component;
    my $absolute = File::Spec->canonpath(
        File::Spec->rel2abs($path, $REPO_ROOT),
    );
    return (undef, 'path escapes the repository root')
        unless _is_below_repo($absolute);
    return (undef, 'path does not exist')
        if $must_exist && !-e $absolute && !-l $absolute;

    my $relative = File::Spec->abs2rel($absolute, $REPO_ROOT);
    my $cursor = $REPO_ROOT;
    for my $part (File::Spec->splitdir($relative)) {
        next if $part eq '' || $part eq '.';
        $cursor = File::Spec->catfile($cursor, $part);
        last unless -e $cursor || -l $cursor;
        return (undef, 'symlink ancestry is forbidden') if -l $cursor;
    }

    my $existing = $absolute;
    $existing = dirname($existing)
        while !-e $existing && !-l $existing && $existing ne $REPO_ROOT;
    my $resolved = abs_path($existing);
    return (undef, 'existing ancestry cannot be resolved')
        unless defined $resolved && _is_below_repo($resolved);
    my @existing_stat = stat($resolved);
    return (undef, 'existing ancestry cannot be inspected')
        unless @existing_stat;
    return (undef, 'path is not on the repository volume')
        unless $existing_stat[0] == $REPO_DEVICE;
    return ($absolute, undef);
}

sub supervise_process {
    my (%args) = @_;
    my $caller = caller;
    die "FSM::Support::ProcessSupervisor is caller-sealed; '$caller' cannot launch a process\n"
        unless defined($caller) && $SUPERVISION_CALLER{$caller};
    my %allowed = map { $_ => 1 } qw(
        argv bounds containment cwd schema stage
    );
    die "unknown supervise_process argument: $_\n"
        for sort grep { !$allowed{$_} } keys %args;
    _require_config_scalar(\%args, $_) for qw(schema stage containment cwd);
    die "supervise_process bounds must be one hash reference\n"
        unless ref($args{bounds}) eq 'HASH';
    my %bounds = %{$args{bounds}};
    die "unknown supervise_process bound: $_\n"
        for sort grep {
            $_ ne 'timeout_seconds' && $_ ne 'capture_limit_bytes'
        } keys %bounds;
    for my $field (qw(timeout_seconds capture_limit_bytes)) {
        die "supervise_process $field must be a positive integer\n"
            unless defined($bounds{$field}) && !ref($bounds{$field})
                && $bounds{$field} =~ /\A[1-9][0-9]*\z/;
        $bounds{$field} = 0 + $bounds{$field};
    }

    my $argument_error = validate_argument_vector($args{argv});
    return process_failure(
        schema => $args{schema}, stage => $args{stage}, bounds => \%bounds,
        containment => $args{containment}, status => 'invocation_error',
        diagnostic => $argument_error,
    ) if defined $argument_error;

    my ($cwd, $cwd_error) = repository_contained_path(
        $args{cwd}, must_exist => 1,
    );
    return process_failure(
        schema => $args{schema}, stage => $args{stage}, bounds => \%bounds,
        containment => $args{containment}, status => 'invocation_error',
        diagnostic => "supervised cwd is invalid: $cwd_error",
    ) if defined $cwd_error;
    return process_failure(
        schema => $args{schema}, stage => $args{stage}, bounds => \%bounds,
        containment => $args{containment}, status => 'invocation_error',
        diagnostic => 'supervised cwd must be a directory',
    ) unless -d $cwd;

    return _supervise({
        schema => $args{schema},
        stage => $args{stage},
        bounds => \%bounds,
        containment => $args{containment},
        cwd => $cwd,
        argv => [@{$args{argv}}],
    });
}

sub process_failure {
    my (%args) = @_;
    my %allowed = map { $_ => 1 } qw(
        bounds containment diagnostic schema stage started status
    );
    die "unknown process_failure argument: $_\n"
        for sort grep { !$allowed{$_} } keys %args;
    _require_config_scalar(\%args, $_)
        for qw(schema stage containment status diagnostic);
    die "process_failure bounds must be one hash reference\n"
        unless ref($args{bounds}) eq 'HASH';
    my $finished = defined($args{started})
        ? clock_gettime(CLOCK_MONOTONIC) : undef;
    return _finish_result({
        schema => $args{schema}, stage => $args{stage},
        bounds => {
            timeout_seconds => $args{bounds}{timeout_seconds},
            capture_limit_bytes => $args{bounds}{capture_limit_bytes},
        },
        containment => $args{containment}, status => $args{status},
        diagnostic => $args{diagnostic}, stdout => '', stderr => '',
        exec_error => undef, started => $args{started},
        exec_handoff => undef, first_output => undef, finished => $finished,
        leader_status => undef,
        cleanup => _new_cleanup(0, $args{containment}),
        timed_out => 0, output_limited => 0, exec_failed => 0,
    });
}

sub _require_config_scalar {
    my ($args, $field) = @_;
    die "supervisor $field must be one non-empty scalar without NUL bytes\n"
        unless defined($args->{$field}) && !ref($args->{$field})
            && length($args->{$field}) && index($args->{$field}, "\0") < 0;
}

sub _is_below_repo {
    my ($path) = @_;
    return 1 if $path eq $REPO_ROOT;
    return index($path, $REPO_ROOT . File::Spec->catfile('', '')) == 0;
}

# Private state-machine entrypoints stay behind the existing caller-sealed
# facade. Advancing a job never sleeps or waits for I/O/termination; the driver
# alone owns waiting, so a later coordinator can service several owned jobs.
sub _supervise {
    my ($request) = @_;
    my $state = _start_supervision($request);
    while ($state->{phase} ne 'finished') {
        _advance_supervision($state);
        last if $state->{phase} eq 'finished';
        my $wait = _supervision_poll_delay($state);
        if ($state->{select} && $state->{select}->count) {
            $state->{select}->can_read($wait);
        }
        else {
            sleep($wait) if $wait > 0;
        }
    }
    return $state->{result};
}

sub _failed_supervision_start {
    return {phase => 'finished', result => _host_failure(@_)};
}

sub _supervision_poll_delay {
    my ($state) = @_;
    return 0 if $state->{phase} eq 'finished';
    my $terminating = $state->{phase} eq 'cleanup';
    my $deadline = $terminating
        ? $state->{termination}{deadline} : $state->{deadline};
    my $wait = $deadline - clock_gettime(CLOCK_MONOTONIC);
    return 0 if $wait <= 0;
    my $interval = $terminating ? 0.02 : 0.05;
    return $wait < $interval ? $wait : $interval;
}

sub _advance_supervision {
    my ($state) = @_;
    return if $state->{phase} eq 'finished';
    if ($state->{phase} eq 'cleanup') {
        _advance_owned_termination($state->{termination});
        _complete_supervision($state)
            if $state->{termination}{phase} eq 'finished';
        return;
    }
    _advance_supervision_capture($state);
}

sub _start_supervision {
    my ($request) = @_;
    my ($stdin_reader, $stdin_writer);
    my ($stdout_reader, $stdout_writer);
    my ($stderr_reader, $stderr_writer);
    my ($control_reader, $control_writer);
    return _failed_supervision_start($request, "cannot create stdin pipe: $!", undef)
        unless pipe($stdin_reader, $stdin_writer);
    unless (pipe($stdout_reader, $stdout_writer)) {
        _close_handles($stdin_reader, $stdin_writer);
        return _failed_supervision_start(
            $request, "cannot create stdout pipe: $!", undef,
        );
    }
    unless (pipe($stderr_reader, $stderr_writer)) {
        _close_handles(
            $stdin_reader, $stdin_writer, $stdout_reader, $stdout_writer,
        );
        return _failed_supervision_start(
            $request, "cannot create stderr pipe: $!", undef,
        );
    }
    unless (pipe($control_reader, $control_writer)) {
        _close_handles(
            $stdin_reader, $stdin_writer, $stdout_reader, $stdout_writer,
            $stderr_reader, $stderr_writer,
        );
        return _failed_supervision_start(
            $request, "cannot create exec-control pipe: $!", undef,
        );
    }
    my $control_flags = fcntl($control_writer, F_GETFD, 0);
    unless (defined($control_flags)
            && fcntl(
                $control_writer, F_SETFD, $control_flags | FD_CLOEXEC,
            )) {
        _close_handles(
            $stdin_reader, $stdin_writer, $stdout_reader, $stdout_writer,
            $stderr_reader, $stderr_writer, $control_reader, $control_writer,
        );
        return _failed_supervision_start(
            $request,
            "cannot seal exec-control pipe close-on-exec: $!",
            undef,
        );
    }

    my $started = clock_gettime(CLOCK_MONOTONIC);
    my $pid = fork();
    unless (defined $pid) {
        _close_handles(
            $stdin_reader, $stdin_writer, $stdout_reader, $stdout_writer,
            $stderr_reader, $stderr_writer, $control_reader, $control_writer,
        );
        return _failed_supervision_start(
            $request, "cannot fork supervised process: $!", $started,
        );
    }
    if ($pid == 0) {
        close $stdin_writer;
        close $stdout_reader;
        close $stderr_reader;
        close $control_reader;
        # POSIX failures normally return undef instead of throwing. The child
        # must verify containment itself before exec; the parent's matching
        # setpgid call is only a race-closing attempt, not admission evidence.
        unless (eval {
            my $group_result = setpgid(0, 0);
            defined($group_result) && $group_result == 0 && getpgrp(0) == $$;
        }) {
            _write_child_control(
                $control_writer, "process-group containment failed: $!",
            );
            _exit(126);
        }
        unless (chdir($request->{cwd})) {
            _write_child_control(
                $control_writer, "supervised cwd chdir failed: $!",
            );
            _exit(126);
        }
        unless (open STDIN, '<&', $stdin_reader) {
            _write_child_control($control_writer, "stdin handoff failed: $!");
            _exit(126);
        }
        unless (open STDOUT, '>&', $stdout_writer) {
            _write_child_control($control_writer, "stdout handoff failed: $!");
            _exit(126);
        }
        unless (open STDERR, '>&', $stderr_writer) {
            _write_child_control($control_writer, "stderr handoff failed: $!");
            _exit(126);
        }
        _close_handles(
            $stdin_reader, $stdout_writer, $stderr_writer,
        );
        {
            no warnings 'exec';
            exec {$request->{argv}[0]} @{$request->{argv}};
        }
        _write_child_control($control_writer, "exec failed: $!");
        _exit(127);
    }

    _close_handles(
        $stdin_reader, $stdout_writer, $stderr_writer, $control_writer,
        $stdin_writer,
    );
    eval { setpgid($pid, $pid); 1 };
    my $state = {
        %$request,
        phase => 'capture', pid => $pid, started => $started,
        stdout => '', stderr => '', exec_error => '',
        exec_handoff => undef, first_output => undef,
        leader_reaped => 0, leader_status => undef,
        timed_out => 0, output_limited => 0,
        cleanup => _new_cleanup(1, $request->{containment}),
        deadline => $started + $request->{bounds}{timeout_seconds},
        select => IO::Select->new(), streams => {},
    };
    for my $entry (
        ['stdout', $stdout_reader], ['stderr', $stderr_reader],
        ['control', $control_reader],
    ) {
        my ($name, $fh) = @$entry;
        $state->{streams}{fileno($fh)} = $entry;
        $state->{select}->add($fh);
    }
    $state->{control_fileno} = fileno($control_reader);
    for my $fh ($stdout_reader, $stderr_reader, $control_reader) {
        unless (_set_nonblocking($fh)) {
            $state->{host_error} = "cannot make supervised pipe nonblocking: $!";
            # This setup failure predates observable exec-handoff evidence.
            $state->{handoff_unknown} = 1;
            _end_supervision_capture($state);
            last;
        }
    }
    return $state;
}

sub _advance_supervision_capture {
    my ($state) = @_;
    _poll_leader(
        $state->{pid}, \$state->{leader_reaped},
        \$state->{leader_status}, \$state->{host_error},
    );
    if ($state->{leader_reaped} && _group_alive($state->{pid})) {
        $state->{surviving_descendants} = 1;
        $state->{cleanup}{surviving_descendants} = 1;
        _end_supervision_capture($state);
        return;
    }
    if ($state->{leader_reaped} && !$state->{select}->count) {
        _end_supervision_capture($state);
        return;
    }
    if (clock_gettime(CLOCK_MONOTONIC) >= $state->{deadline}) {
        $state->{timed_out} = 1;
        _end_supervision_capture($state);
        return;
    }

    my @ready = $state->{select}->can_read(0);
    @ready = sort {
        (fileno($a) == $state->{control_fileno} ? 0 : 1)
            <=> (fileno($b) == $state->{control_fileno} ? 0 : 1)
    } @ready;
    for my $fh (@ready) {
        my $fileno = fileno($fh);
        next unless defined($fileno) && exists $state->{streams}{$fileno};
        my ($name) = @{$state->{streams}{$fileno}};
        my $chunk = '';
        my $read = sysread($fh, $chunk, $READ_CHUNK_BYTES);
        if (!defined $read) {
            next if $! == EINTR || $! == EAGAIN || $! == EWOULDBLOCK;
            $state->{host_error} = "$name pipe read failed: $!";
            last;
        }
        if ($read == 0) {
            $state->{exec_handoff} = clock_gettime(CLOCK_MONOTONIC)
                if $name eq 'control' && !length($state->{exec_error})
                    && !defined($state->{exec_handoff});
            $state->{select}->remove($fh);
            close $fh;
            delete $state->{streams}{$fileno};
            next;
        }
        if ($name eq 'control') {
            my $remaining = $CONTROL_LIMIT_BYTES
                - bytes::length($state->{exec_error});
            if ($remaining <= 0 || $read > $remaining) {
                $state->{host_error} = 'exec-control message exceeded its fixed limit';
                last;
            }
            $state->{exec_error} .= $chunk;
            next;
        }
        $state->{first_output} = clock_gettime(CLOCK_MONOTONIC)
            unless defined $state->{first_output};
        my $captured = bytes::length($state->{stdout})
            + bytes::length($state->{stderr});
        my $remaining = $state->{bounds}{capture_limit_bytes} - $captured;
        if ($remaining <= 0 || $read > $remaining) {
            $state->{$name} .= substr($chunk, 0, $remaining)
                if $remaining > 0;
            $state->{output_limited} = 1;
            last;
        }
        $state->{$name} .= $chunk;
    }
    _end_supervision_capture($state)
        if defined($state->{host_error}) || $state->{output_limited};
}

sub _end_supervision_capture {
    my ($state) = @_;
    _close_handles(map { $_->[1] } values %{$state->{streams}});
    $state->{streams} = {};
    $state->{select} = IO::Select->new();
    if ($state->{timed_out} || $state->{output_limited}
            || $state->{surviving_descendants}
            || defined($state->{host_error}) || length($state->{exec_error})) {
        $state->{phase} = 'cleanup';
        $state->{termination} = _start_owned_termination(
            $state->{pid}, \$state->{leader_reaped},
            \$state->{leader_status}, $state->{cleanup},
        );
        return;
    }
    # Normal capture ends only once the direct child was harvested and all
    # streams closed. Preserve the final independent group check.
    if (_group_alive($state->{pid})) {
        $state->{surviving_descendants} = 1;
        $state->{cleanup}{surviving_descendants} = 1;
        $state->{phase} = 'cleanup';
        $state->{termination} = _start_owned_termination(
            $state->{pid}, \$state->{leader_reaped},
            \$state->{leader_status}, $state->{cleanup},
        );
        return;
    }
    _complete_supervision($state);
}

sub _complete_supervision {
    my ($state) = @_;
    my $cleanup = $state->{cleanup};
    $cleanup->{leader_reaped} = $state->{leader_reaped} ? 1 : 0;
    $cleanup->{group_gone} = _group_alive($state->{pid}) ? 0 : 1;
    $state->{finished} = clock_gettime(CLOCK_MONOTONIC);
    $state->{exec_handoff} = $state->{finished}
        if !$state->{handoff_unknown} && !defined($state->{exec_handoff})
            && !length($state->{exec_error});
    my $exec_error = _sanitize_control($state->{exec_error});
    my $leader_status = $state->{leader_status};
    my $status = defined($state->{host_error}) ? 'host_error'
        : $state->{timed_out} ? 'timed_out'
        : $state->{output_limited} ? 'output_limited'
        : length($exec_error) ? 'exec_error'
        : $state->{surviving_descendants} ? 'surviving_descendants'
        : !$cleanup->{leader_reaped} || !$cleanup->{group_gone}
            ? 'cleanup_failed'
        : !defined($leader_status) ? 'host_error'
        : ($leader_status & 127) ? 'signaled'
        : ($leader_status >> 8) != 0 ? 'nonzero_exit'
        : 'success';
    my $diagnostic = defined($state->{host_error}) ? $state->{host_error}
        : $status eq 'success' ? 'supervised process completed successfully'
        : $status eq 'timed_out' ? 'supervised process exceeded its fixed deadline'
        : $status eq 'output_limited' ? 'supervised process exceeded its aggregate capture limit'
        : $status eq 'exec_error' ? $exec_error
        : $status eq 'surviving_descendants' ? 'supervised process left descendants after leader exit'
        : $status eq 'cleanup_failed' ? 'supervised process cleanup could not prove leader and group disappearance'
        : $status eq 'signaled' ? 'supervised process exited after a signal'
        : $status eq 'nonzero_exit' ? 'supervised process exited nonzero'
        : 'supervised process status could not be determined';
    $state->{result} = _finish_result({
        %$state, status => $status, diagnostic => $diagnostic,
        exec_error => length($exec_error) ? $exec_error : undef,
        exec_failed => length($exec_error) ? 1 : 0,
    });
    $state->{phase} = 'finished';
}

sub _host_failure {
    my ($request, $diagnostic, $started) = @_;
    return process_failure(
        schema => $request->{schema}, stage => $request->{stage},
        bounds => $request->{bounds}, containment => $request->{containment},
        status => 'host_error', diagnostic => $diagnostic,
        started => $started,
    );
}

sub _finish_result {
    my ($state) = @_;
    my $started_ns = _to_ns($state->{started});
    my $exec_ns = _to_ns($state->{exec_handoff});
    my $first_ns = _to_ns($state->{first_output});
    my $finished_ns = _to_ns($state->{finished});
    my $raw = $state->{leader_status};
    my $signal = defined($raw) ? $raw & 127 : undef;
    my $exit_code = !defined($raw) || $signal ? undef : $raw >> 8;
    return {
        schema => $state->{schema},
        schema_version => 1,
        stage => $state->{stage},
        ok => $state->{status} eq 'success' ? 1 : 0,
        status => $state->{status},
        diagnostic => $state->{diagnostic},
        stdout => $state->{stdout},
        stderr => $state->{stderr},
        stdout_bytes => bytes::length($state->{stdout}),
        stderr_bytes => bytes::length($state->{stderr}),
        exit_code => $exit_code,
        signal => $signal,
        timed_out => $state->{timed_out} ? 1 : 0,
        output_limited => $state->{output_limited} ? 1 : 0,
        exec_failed => $state->{exec_failed} ? 1 : 0,
        exec_error => $state->{exec_error},
        timeout_seconds => $state->{bounds}{timeout_seconds},
        capture_limit_bytes => $state->{bounds}{capture_limit_bytes},
        started_monotonic_ns => $started_ns,
        exec_handoff_monotonic_ns => $exec_ns,
        first_output_monotonic_ns => $first_ns,
        finished_monotonic_ns => $finished_ns,
        spawn_to_exec_ns => defined($started_ns) && defined($exec_ns)
            ? $exec_ns - $started_ns : undef,
        execution_ns => defined($exec_ns) && defined($finished_ns)
            ? $finished_ns - $exec_ns : undef,
        exec_to_first_output_ns => defined($exec_ns) && defined($first_ns)
            ? $first_ns - $exec_ns : undef,
        first_output_to_exit_ns => defined($first_ns) && defined($finished_ns)
            ? $finished_ns - $first_ns : undef,
        cleanup => $state->{cleanup},
    };
}

sub _new_cleanup {
    my ($leader_started, $containment) = @_;
    return {
        containment => $containment,
        leader_started => $leader_started ? 1 : 0,
        term_sent => 0,
        kill_sent => 0,
        leader_reaped => 0,
        group_gone => 1,
        surviving_descendants => 0,
    };
}

sub _set_nonblocking {
    my ($fh) = @_;
    my $flags = fcntl($fh, F_GETFL, 0);
    return 0 unless defined $flags;
    return fcntl($fh, F_SETFL, $flags | O_NONBLOCK) ? 1 : 0;
}

sub _poll_leader {
    my ($pid, $reaped, $status, $host_error) = @_;
    return if $$reaped;
    my $waited = waitpid($pid, WNOHANG);
    if ($waited == $pid) {
        $$reaped = 1;
        $$status = $?;
    }
    elsif ($waited == -1) {
        $$reaped = 1;
        $$host_error = "cannot reap supervised leader: $!"
            unless $! == ECHILD;
    }
}

sub _terminate_owned_process {
    my $state = _start_owned_termination(@_);
    while ($state->{phase} ne 'finished') {
        _advance_owned_termination($state);
        sleep(0.02) if $state->{phase} ne 'finished';
    }
}

sub _start_owned_termination {
    my ($pid, $reaped, $status, $cleanup) = @_;
    my $group_alive = _group_alive($pid);
    my $leader_alive = !$$reaped && kill(0, $pid);
    my $target = $group_alive ? -$pid : $pid;
    if ($group_alive || $leader_alive) {
        $cleanup->{term_sent} = kill('TERM', $target) ? 1 : 0;
    }
    return {
        pid => $pid, reaped => $reaped, status => $status, cleanup => $cleanup,
        phase => 'term',
        deadline => clock_gettime(CLOCK_MONOTONIC) + $TERM_GRACE_SECONDS,
    };
}

sub _advance_owned_termination {
    my ($state) = @_;
    return if $state->{phase} eq 'finished';
    my ($pid, $reaped, $status, $cleanup) = @{$state}{qw(pid reaped status cleanup)};
    my $ignored;
    _poll_leader($pid, $reaped, $status, \$ignored);
    my $group_alive = _group_alive($pid);
    if ($$reaped && !$group_alive) {
        _complete_owned_termination($state);
        return;
    }
    return if clock_gettime(CLOCK_MONOTONIC) < $state->{deadline};
    if ($state->{phase} eq 'term') {
        my $leader_alive = !$$reaped && kill(0, $pid);
        if ($group_alive || $leader_alive) {
            my $target = $group_alive ? -$pid : $pid;
            $cleanup->{kill_sent} = kill('KILL', $target) ? 1 : 0;
        }
        $state->{phase} = 'kill';
        $state->{deadline} = clock_gettime(CLOCK_MONOTONIC) + $KILL_GRACE_SECONDS;
        return;
    }
    _complete_owned_termination($state);
}

sub _complete_owned_termination {
    my ($state) = @_;
    $state->{cleanup}{leader_reaped} = ${$state->{reaped}} ? 1 : 0;
    $state->{cleanup}{group_gone} = _group_alive($state->{pid}) ? 0 : 1;
    $state->{phase} = 'finished';
}

sub _group_alive {
    my ($pid) = @_;
    local $!;
    return 1 if kill(0, -$pid);
    return $! == EPERM ? 1 : 0;
}

sub _write_child_control {
    my ($fh, $message) = @_;
    $message = substr($message, 0, $CONTROL_LIMIT_BYTES);
    my $offset = 0;
    while ($offset < bytes::length($message)) {
        my $written = syswrite(
            $fh, $message, bytes::length($message) - $offset, $offset,
        );
        next if !defined($written) && $! == EINTR;
        last unless defined($written) && $written > 0;
        $offset += $written;
    }
}

sub _sanitize_control {
    my ($message) = @_;
    $message =~ s/[\r\n\t]+/ /g;
    $message =~ s/\s+/ /g;
    $message =~ s/^\s+|\s+$//g;
    return substr($message, 0, $CONTROL_LIMIT_BYTES);
}

sub _close_handles {
    for my $fh (@_) {
        next unless defined($fh) && defined(fileno($fh));
        close $fh;
    }
}

sub _to_ns {
    my ($time) = @_;
    return undef unless defined $time;
    return int($time * 1_000_000_000);
}

1;
