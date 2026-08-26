package FSM::Test::VerilatorRuntime;

use strict;
use warnings;

use bytes ();
use Cwd qw(abs_path);
use Errno qw(EAGAIN ECHILD EINTR EPERM EWOULDBLOCK);
use Exporter qw(import);
use Fcntl qw(FD_CLOEXEC F_GETFD F_GETFL F_SETFD F_SETFL O_NONBLOCK);
use File::Basename qw(basename dirname);
use File::Spec;
use IO::Select;
use POSIX qw(WNOHANG _exit setpgid);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep);

our @EXPORT_OK = qw(
    darwin_verilator_runtime_qualified
    darwin_verilator_runtime_skip_reason
    run_verilator_version
    run_verilator_compile
    run_generated_binary
);

my $SCHEMA = 'fsmgen.test.verilator_runtime_result.v1';
my $DARWIN_GUARD = 'FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME';
my $READ_CHUNK_BYTES = 65_536;
my $CONTROL_LIMIT_BYTES = 2_048;
my $TERM_GRACE_SECONDS = 2;
my $KILL_GRACE_SECONDS = 2;
my %STAGE = (
    version => {timeout_seconds => 10, capture_limit_bytes => 65_536},
    compile => {timeout_seconds => 120, capture_limit_bytes => 8_388_608},
    runtime => {timeout_seconds => 30, capture_limit_bytes => 67_108_864},
);

my $MODULE_PATH = abs_path(__FILE__)
    or die "cannot resolve FSM::Test::VerilatorRuntime module path: $!";
my $REPO_ROOT = abs_path(File::Spec->catdir(
    dirname($MODULE_PATH), '..', '..', '..', '..',
)) or die "cannot derive repository root for FSM::Test::VerilatorRuntime: $!";
my @REPO_STAT = stat($REPO_ROOT);
die "cannot stat repository root for FSM::Test::VerilatorRuntime: $!"
    unless @REPO_STAT;
my $REPO_DEVICE = $REPO_STAT[0];

sub darwin_verilator_runtime_qualified {
    return 1 unless $^O eq 'darwin';
    return defined($ENV{$DARWIN_GUARD})
        && $ENV{$DARWIN_GUARD} eq '1';
}

sub darwin_verilator_runtime_skip_reason {
    return undef if darwin_verilator_runtime_qualified();
    return "set $DARWIN_GUARD=1 to qualify legacy Verilator test runtime on Darwin";
}

sub run_verilator_version {
    return _run_stage('version', ['verilator', '--version']);
}

sub run_verilator_compile {
    return _run_stage('compile', @_);
}

sub run_generated_binary {
    return _run_stage('runtime', @_);
}

sub _run_stage {
    my ($stage, @arguments) = @_;
    my $bounds = $STAGE{$stage};
    return _failure(
        $stage, $bounds, 'qualification_required',
        darwin_verilator_runtime_skip_reason(), undef,
    ) unless darwin_verilator_runtime_qualified();
    return _failure(
        $stage, $bounds, 'invocation_error',
        "$stage stage expects one argument-vector reference", undef,
    ) unless @arguments == 1 && ref($arguments[0]) eq 'ARRAY';
    my $argv = $arguments[0];
    my $argument_error = _validate_argument_vector($argv);
    return _failure(
        $stage, $bounds, 'invocation_error', $argument_error, undef,
    ) if defined $argument_error;
    my $stage_error = $stage eq 'version'
        ? _validate_version_command($argv)
        : $stage eq 'compile'
            ? _validate_compile_command($argv)
            : _validate_runtime_command($argv);
    return _failure(
        $stage, $bounds, 'invocation_error', $stage_error, undef,
    ) if defined $stage_error;
    return _supervise($stage, $bounds, $argv);
}

sub _validate_argument_vector {
    my ($argv) = @_;
    return 'command must be one non-empty scalar argument vector'
        unless @$argv;
    return 'command arguments must be defined scalars without NUL bytes'
        if grep { !defined($_) || ref($_) || /\x00/ } @$argv;
    return undef;
}

sub _validate_version_command {
    my ($argv) = @_;
    return 'version stage command is sealed'
        unless @$argv == 2
            && $argv->[0] eq 'verilator'
            && $argv->[1] eq '--version';
    return undef;
}

sub _validate_compile_command {
    my ($argv) = @_;
    return 'compile stage executable must be named verilator'
        unless basename($argv->[0]) eq 'verilator';
    my @binary = grep { $argv->[$_] eq '--binary' } 0 .. $#$argv;
    return 'compile stage requires exactly one --binary option'
        unless @binary == 1;
    my @mdir = grep { $argv->[$_] eq '--Mdir' } 0 .. $#$argv;
    return 'compile stage requires exactly one --Mdir path'
        unless @mdir == 1 && $mdir[0] < $#$argv;
    my ($absolute, $path_error) = _contained_path(
        $argv->[$mdir[0] + 1], 0,
    );
    return "compile object directory is invalid: $path_error"
        if defined $path_error;
    return undef;
}

sub _validate_runtime_command {
    my ($argv) = @_;
    my ($absolute, $path_error) = _contained_path($argv->[0], 1);
    return "runtime executable is invalid: $path_error"
        if defined $path_error;
    my @metadata = lstat($absolute);
    return 'runtime executable cannot be inspected' unless @metadata;
    return 'runtime executable must not be a symlink' if -l _;
    return 'runtime executable must be a regular executable file'
        unless -f _ && -x _;
    return undef;
}

sub _contained_path {
    my ($path, $must_exist) = @_;
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

sub _is_below_repo {
    my ($path) = @_;
    return 1 if $path eq $REPO_ROOT;
    return index($path, $REPO_ROOT . File::Spec->catfile('', '')) == 0;
}

sub _supervise {
    my ($stage, $bounds, $argv) = @_;
    my ($stdin_reader, $stdin_writer);
    my ($stdout_reader, $stdout_writer);
    my ($stderr_reader, $stderr_writer);
    my ($control_reader, $control_writer);
    return _failure($stage, $bounds, 'host_error',
        "cannot create stdin pipe: $!", undef)
        unless pipe($stdin_reader, $stdin_writer);
    unless (pipe($stdout_reader, $stdout_writer)) {
        _close_handles($stdin_reader, $stdin_writer);
        return _failure($stage, $bounds, 'host_error',
            "cannot create stdout pipe: $!", undef);
    }
    unless (pipe($stderr_reader, $stderr_writer)) {
        _close_handles(
            $stdin_reader, $stdin_writer, $stdout_reader, $stdout_writer,
        );
        return _failure($stage, $bounds, 'host_error',
            "cannot create stderr pipe: $!", undef);
    }
    unless (pipe($control_reader, $control_writer)) {
        _close_handles(
            $stdin_reader, $stdin_writer, $stdout_reader, $stdout_writer,
            $stderr_reader, $stderr_writer,
        );
        return _failure($stage, $bounds, 'host_error',
            "cannot create exec-control pipe: $!", undef);
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
        return _failure($stage, $bounds, 'host_error',
            "cannot seal exec-control pipe close-on-exec: $!", undef);
    }

    my $started = clock_gettime(CLOCK_MONOTONIC);
    my $pid = fork();
    unless (defined $pid) {
        _close_handles(
            $stdin_reader, $stdin_writer, $stdout_reader, $stdout_writer,
            $stderr_reader, $stderr_writer, $control_reader, $control_writer,
        );
        return _failure($stage, $bounds, 'host_error',
            "cannot fork supervised process: $!", $started);
    }
    if ($pid == 0) {
        close $stdin_writer;
        close $stdout_reader;
        close $stderr_reader;
        close $control_reader;
        unless (eval { setpgid(0, 0); 1 }) {
            _write_child_control(
                $control_writer, "process-group containment failed: $!",
            );
            _exit(126);
        }
        unless (chdir($REPO_ROOT)) {
            _write_child_control(
                $control_writer, "repository chdir failed: $!",
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
            exec {$argv->[0]} @$argv;
        }
        _write_child_control($control_writer, "exec failed: $!");
        _exit(127);
    }

    _close_handles(
        $stdin_reader, $stdout_writer, $stderr_writer, $control_writer,
        $stdin_writer,
    );
    eval { setpgid($pid, $pid); 1 };
    my $cleanup = _new_cleanup(1);
    for my $fh ($stdout_reader, $stderr_reader, $control_reader) {
        unless (_set_nonblocking($fh)) {
            my $message = "cannot make supervised pipe nonblocking: $!";
            _close_handles($stdout_reader, $stderr_reader, $control_reader);
            my ($leader_reaped, $leader_status) = (0, undef);
            _terminate_owned_process(
                $pid, \$leader_reaped, \$leader_status, $cleanup,
            );
            return _finish_result({
                stage => $stage, bounds => $bounds, status => 'host_error',
                diagnostic => $message, stdout => '', stderr => '',
                exec_error => undef, started => $started,
                exec_handoff => undef, first_output => undef,
                finished => clock_gettime(CLOCK_MONOTONIC),
                leader_status => $leader_status, cleanup => $cleanup,
                timed_out => 0, output_limited => 0, exec_failed => 0,
            });
        }
    }

    my %stream = (
        fileno($stdout_reader) => ['stdout', $stdout_reader],
        fileno($stderr_reader) => ['stderr', $stderr_reader],
        fileno($control_reader) => ['control', $control_reader],
    );
    my $control_fileno = fileno($control_reader);
    my $select = IO::Select->new(
        $control_reader, $stdout_reader, $stderr_reader,
    );
    my ($stdout, $stderr, $exec_error) = ('', '', '');
    my ($exec_handoff, $first_output);
    my ($leader_reaped, $leader_status) = (0, undef);
    my ($timed_out, $output_limited) = (0, 0);
    my ($host_error, $surviving_descendants);
    my $deadline = $started + $bounds->{timeout_seconds};

    while (1) {
        _poll_leader($pid, \$leader_reaped, \$leader_status, \$host_error);
        if ($leader_reaped && _group_alive($pid)) {
            $surviving_descendants = 1;
            $cleanup->{surviving_descendants} = 1;
            last;
        }
        last if $leader_reaped && !$select->count;
        my $now = clock_gettime(CLOCK_MONOTONIC);
        if ($now >= $deadline) {
            $timed_out = 1;
            last;
        }
        my $wait = $deadline - $now;
        $wait = 0.05 if $wait > 0.05;
        my @ready = $select->count ? $select->can_read($wait) : ();
        sleep($wait) unless @ready || $select->count;
        @ready = sort {
            (fileno($a) == $control_fileno ? 0 : 1)
                <=> (fileno($b) == $control_fileno ? 0 : 1)
        } @ready;
        for my $fh (@ready) {
            my $fileno = fileno($fh);
            next unless defined($fileno) && exists $stream{$fileno};
            my ($name) = @{$stream{$fileno}};
            my $chunk = '';
            my $read = sysread($fh, $chunk, $READ_CHUNK_BYTES);
            if (!defined $read) {
                next if $! == EINTR || $! == EAGAIN || $! == EWOULDBLOCK;
                $host_error = "$name pipe read failed: $!";
                last;
            }
            if ($read == 0) {
                $exec_handoff = clock_gettime(CLOCK_MONOTONIC)
                    if $name eq 'control' && !length($exec_error)
                        && !defined($exec_handoff);
                $select->remove($fh);
                close $fh;
                delete $stream{$fileno};
                next;
            }
            if ($name eq 'control') {
                my $remaining = $CONTROL_LIMIT_BYTES - bytes::length($exec_error);
                if ($remaining <= 0 || $read > $remaining) {
                    $host_error = 'exec-control message exceeded its fixed limit';
                    last;
                }
                $exec_error .= $chunk;
                next;
            }
            $first_output = clock_gettime(CLOCK_MONOTONIC)
                unless defined $first_output;
            my $captured = bytes::length($stdout) + bytes::length($stderr);
            my $remaining = $bounds->{capture_limit_bytes} - $captured;
            if ($remaining <= 0 || $read > $remaining) {
                if ($remaining > 0) {
                    if ($name eq 'stdout') {
                        $stdout .= substr($chunk, 0, $remaining);
                    }
                    else {
                        $stderr .= substr($chunk, 0, $remaining);
                    }
                }
                $output_limited = 1;
                last;
            }
            if ($name eq 'stdout') {
                $stdout .= $chunk;
            }
            else {
                $stderr .= $chunk;
            }
        }
        last if defined($host_error) || $output_limited;
    }

    _close_handles($stdout_reader, $stderr_reader, $control_reader);
    if ($timed_out || $output_limited || $surviving_descendants
            || defined($host_error)
            || length($exec_error)) {
        _terminate_owned_process(
            $pid, \$leader_reaped, \$leader_status, $cleanup,
        );
    }
    else {
        while (!$leader_reaped
                && clock_gettime(CLOCK_MONOTONIC) < $deadline) {
            _poll_leader(
                $pid, \$leader_reaped, \$leader_status, \$host_error,
            );
            sleep(0.01) unless $leader_reaped;
        }
        unless ($leader_reaped) {
            $timed_out = 1;
            _terminate_owned_process(
                $pid, \$leader_reaped, \$leader_status, $cleanup,
            );
        }
        if (_group_alive($pid)) {
            $surviving_descendants = 1;
            $cleanup->{surviving_descendants} = 1;
            _terminate_owned_process(
                $pid, \$leader_reaped, \$leader_status, $cleanup,
            );
        }
    }
    $cleanup->{leader_reaped} = $leader_reaped ? 1 : 0;
    $cleanup->{group_gone} = _group_alive($pid) ? 0 : 1;
    my $finished = clock_gettime(CLOCK_MONOTONIC);
    $exec_handoff = $finished
        if !defined($exec_handoff) && !length($exec_error);
    $exec_error = _sanitize_control($exec_error);

    my $status = defined($host_error) ? 'host_error'
        : $timed_out ? 'timed_out'
        : $output_limited ? 'output_limited'
        : length($exec_error) ? 'exec_error'
        : $surviving_descendants ? 'surviving_descendants'
        : !$cleanup->{leader_reaped} || !$cleanup->{group_gone}
            ? 'cleanup_failed'
        : !defined($leader_status) ? 'host_error'
        : ($leader_status & 127) ? 'signaled'
        : ($leader_status >> 8) != 0 ? 'nonzero_exit'
        : 'success';
    my $diagnostic = defined($host_error) ? $host_error
        : $status eq 'success' ? 'supervised process completed successfully'
        : $status eq 'timed_out' ? 'supervised process exceeded its fixed deadline'
        : $status eq 'output_limited' ? 'supervised process exceeded its aggregate capture limit'
        : $status eq 'exec_error' ? $exec_error
        : $status eq 'surviving_descendants' ? 'supervised process left descendants after leader exit'
        : $status eq 'cleanup_failed' ? 'supervised process cleanup could not prove leader and group disappearance'
        : $status eq 'signaled' ? 'supervised process exited after a signal'
        : $status eq 'nonzero_exit' ? 'supervised process exited nonzero'
        : 'supervised process status could not be determined';
    return _finish_result({
        stage => $stage, bounds => $bounds, status => $status,
        diagnostic => $diagnostic, stdout => $stdout, stderr => $stderr,
        exec_error => length($exec_error) ? $exec_error : undef,
        started => $started, exec_handoff => $exec_handoff,
        first_output => $first_output, finished => $finished,
        leader_status => $leader_status, cleanup => $cleanup,
        timed_out => $timed_out, output_limited => $output_limited,
        exec_failed => length($exec_error) ? 1 : 0,
    });
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
        schema => $SCHEMA,
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

sub _failure {
    my ($stage, $bounds, $status, $diagnostic, $started) = @_;
    my $finished = defined($started)
        ? clock_gettime(CLOCK_MONOTONIC) : undef;
    return _finish_result({
        stage => $stage,
        bounds => $bounds || {timeout_seconds => undef, capture_limit_bytes => undef},
        status => $status,
        diagnostic => $diagnostic,
        stdout => '',
        stderr => '',
        exec_error => undef,
        started => $started,
        exec_handoff => undef,
        first_output => undef,
        finished => $finished,
        leader_status => undef,
        cleanup => _new_cleanup(0),
        timed_out => 0,
        output_limited => 0,
        exec_failed => 0,
    });
}

sub _new_cleanup {
    my ($leader_started) = @_;
    return {
        containment => 'test_runtime_process_group',
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
    my ($pid, $reaped, $status, $cleanup) = @_;
    my $group_alive = _group_alive($pid);
    my $leader_alive = !$$reaped && kill(0, $pid);
    my $target = $group_alive ? -$pid : $pid;
    if ($group_alive || $leader_alive) {
        $cleanup->{term_sent} = kill('TERM', $target) ? 1 : 0;
    }
    my $deadline = clock_gettime(CLOCK_MONOTONIC) + $TERM_GRACE_SECONDS;
    while (clock_gettime(CLOCK_MONOTONIC) < $deadline) {
        my $ignored;
        _poll_leader($pid, $reaped, $status, \$ignored);
        last if $$reaped && !_group_alive($pid);
        sleep(0.02);
    }
    $group_alive = _group_alive($pid);
    $leader_alive = !$$reaped && kill(0, $pid);
    if ($group_alive || $leader_alive) {
        $target = $group_alive ? -$pid : $pid;
        $cleanup->{kill_sent} = kill('KILL', $target) ? 1 : 0;
    }
    unless ($$reaped) {
        while (1) {
            my $waited = waitpid($pid, 0);
            if ($waited == $pid) {
                $$reaped = 1;
                $$status = $?;
                last;
            }
            next if $waited == -1 && $! == EINTR;
            $$reaped = 1 if $waited == -1 && $! == ECHILD;
            last;
        }
    }
    my $kill_deadline =
        clock_gettime(CLOCK_MONOTONIC) + $KILL_GRACE_SECONDS;
    while (_group_alive($pid)
            && clock_gettime(CLOCK_MONOTONIC) < $kill_deadline) {
        sleep(0.02);
    }
    $cleanup->{leader_reaped} = $$reaped ? 1 : 0;
    $cleanup->{group_gone} = _group_alive($pid) ? 0 : 1;
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
