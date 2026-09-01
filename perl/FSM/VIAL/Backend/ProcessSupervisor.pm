package FSM::VIAL::Backend::ProcessSupervisor;

use v5.20;
use strict;
use warnings;
use bytes ();
use Cwd qw(abs_path);
use Errno qw(EAGAIN EINTR EWOULDBLOCK);
use Fcntl qw(FD_CLOEXEC F_GETFD F_GETFL F_SETFD F_SETFL O_NONBLOCK);
use IO::Select;
use JSON::PP ();
use POSIX qw(WNOHANG _exit setpgid);
use Scalar::Util qw(blessed);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

my $POLICY_SCHEMA = 'fsmgen.vial_process_supervisor_policy.v1';
my $PROCESS_CENSUS_MAX_BYTES = 4_194_304;
my $PROCESS_CENSUS_MAX_ROWS = 65_536;
my $PROCESS_OBSERVATION_INTERVAL_SECONDS = 0.05;
my $HOST_OBSERVER_SETUP_TIMEOUT_SECONDS = 1;
my $HOST_OBSERVER_CLEANUP_TIMEOUT_SECONDS = 2;
my @POLICY_KEYS = qw(
    schema schema_version containment timeout_seconds capture_limit_bytes
);
my %CALLER = map { $_ => 1 } qw(
    FSM::VIAL::Backend::VerilatorLifecycle
    FSM::VIAL::Backend::GHDLLifecycle
    FSM::VIAL::Backend::VHDLPortableGHDLQualification
);

sub capture($class, @args) {
    _throw(
        'VIAL_PROCESS_INVOCATION_ERROR',
        'process supervision requires the exact class invocant', '/',
    ) unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    _throw(
        'VIAL_PROCESS_INVOCATION_ERROR',
        'process supervision is caller-sealed', '/',
    ) unless $CALLER{scalar caller};
    _throw(
        'VIAL_PROCESS_INVOCATION_ERROR',
        'process supervision expects one closed argument hash', '/',
    ) unless @args == 1 && ref($args[0]) eq 'HASH'
        && !blessed($args[0]);
    my $raw = $args[0];
    _closed($raw, [qw(working_directory argv policy)], 'process request');
    my $working_directory = abs_path($raw->{working_directory});
    _throw(
        'VIAL_PROCESS_PATH_ERROR',
        'process working directory is not one readable non-symlink directory',
        '/working_directory',
    ) unless defined($working_directory) && -d $working_directory
        && !-l $working_directory;
    my $argv = $raw->{argv};
    _throw(
        'VIAL_PROCESS_INVOCATION_ERROR',
        'selected tool command is not one non-empty scalar argument vector',
        '/argv',
    ) unless ref($argv) eq 'ARRAY' && @$argv
        && !grep { !defined($_) || ref($_) || /\x00/ } @$argv;
    my $policy = $raw->{policy};
    _closed($policy, \@POLICY_KEYS, 'process policy');
    _throw(
        'VIAL_PROCESS_POLICY_ERROR',
        'process policy schema is not exact', '/policy/schema',
    ) unless ($policy->{schema} // '') eq $POLICY_SCHEMA
        && ($policy->{schema_version} // 0) == 1;
    _throw(
        'VIAL_PROCESS_POLICY_ERROR',
        'process containment policy is not admitted', '/policy/containment',
    ) unless ($policy->{containment} // '') =~
        /\A(?:lifecycle_process_group|outer_worker_process_group)\z/;
    for my $field (qw(timeout_seconds capture_limit_bytes)) {
        _throw(
            'VIAL_PROCESS_POLICY_ERROR',
            "process $field is not one positive integer", "/policy/$field",
        ) unless defined($policy->{$field}) && !ref($policy->{$field})
            && $policy->{$field} =~ /\A[1-9][0-9]*\z/;
    }
    return _capture($working_directory, $argv, $policy);
}

sub policy($class, @args) {
    _throw(
        'VIAL_PROCESS_INVOCATION_ERROR',
        'process policy construction requires the exact class invocant', '/',
    ) unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    _throw(
        'VIAL_PROCESS_INVOCATION_ERROR',
        'process policy construction is caller-sealed', '/',
    ) unless $CALLER{scalar caller};
    _throw(
        'VIAL_PROCESS_INVOCATION_ERROR',
        'process policy construction expects containment, timeout, and limit',
        '/',
    ) unless @args == 3;
    my ($containment, $timeout, $limit) = @args;
    my $value = {
        schema => $POLICY_SCHEMA,
        schema_version => 1,
        containment => $containment,
        timeout_seconds => $timeout,
        capture_limit_bytes => $limit,
    };
    _closed($value, \@POLICY_KEYS, 'process policy');
    return $value;
}

sub _capture($working_directory, $argv, $policy) {
    my ($stdin_reader, $stdin_writer);
    my ($output_reader, $output_writer);
    my ($control_reader, $control_writer);
    my ($containment_reader, $containment_writer);
    pipe($stdin_reader, $stdin_writer)
        or _throw('VIAL_PROCESS_HOST_ERROR',
            'cannot create selected-tool stdin pipe', '/process');
    pipe($output_reader, $output_writer)
        or _throw('VIAL_PROCESS_HOST_ERROR',
            'cannot create selected-tool output pipe', '/process');
    pipe($control_reader, $control_writer)
        or _throw('VIAL_PROCESS_HOST_ERROR',
            'cannot create selected-tool exec-control pipe', '/process');
    pipe($containment_reader, $containment_writer)
        or _throw('VIAL_PROCESS_HOST_ERROR',
            'cannot create selected-tool containment pipe', '/process');
    my $containment_identity = eval {
        _containment_pipe_identity(
            $containment_writer,
            clock_gettime(CLOCK_MONOTONIC)
                + $HOST_OBSERVER_SETUP_TIMEOUT_SECONDS,
        );
    };
    if (!defined $containment_identity) {
        close $_ for (
            $stdin_reader, $stdin_writer,
            $output_reader, $output_writer,
            $control_reader, $control_writer,
            $containment_reader, $containment_writer,
        );
        _throw(
            'VIAL_PROCESS_HOST_ERROR',
            'cannot authenticate selected-tool containment pipe', '/process',
        );
    }
    my $control_flags = fcntl($control_writer, F_GETFD, 0);
    _throw('VIAL_PROCESS_HOST_ERROR',
        'cannot inspect selected-tool exec-control pipe', '/process')
        unless defined $control_flags;
    _throw('VIAL_PROCESS_HOST_ERROR',
        'cannot seal selected-tool exec-control pipe close-on-exec', '/process')
        unless fcntl($control_writer, F_SETFD, $control_flags | FD_CLOEXEC);

    my $started = clock_gettime(CLOCK_MONOTONIC);
    my $capture_deadline = $started + $policy->{timeout_seconds};
    my $pid = fork();
    _throw('VIAL_PROCESS_HOST_ERROR',
        'cannot fork the selected tool', '/process') unless defined $pid;
    if ($pid == 0) {
        close $stdin_writer;
        close $output_reader;
        close $control_reader;
        close $containment_reader;
        my $containment_flags = fcntl(
            $containment_writer, F_GETFD, 0,
        );
        if (!defined($containment_flags)
                || !fcntl(
                    $containment_writer, F_SETFD,
                    $containment_flags & ~FD_CLOEXEC,
                )) {
            _write_child_control(
                $control_writer,
                'containment handoff failed',
            );
            _exit(126);
        }
        if ($policy->{containment} eq 'lifecycle_process_group') {
            unless (eval { setpgid(0, 0); 1 }) {
                _write_child_control(
                    $control_writer, "process-group containment failed: $!",
                );
                _exit(126);
            }
        }
        unless (chdir($working_directory)) {
            _write_child_control(
                $control_writer,
                "repository working-directory handoff failed: $!",
            );
            _exit(126);
        }
        unless (open STDIN, '<&', $stdin_reader) {
            _write_child_control($control_writer, "stdin handoff failed: $!");
            _exit(126);
        }
        unless (open STDOUT, '>&', $output_writer) {
            _write_child_control($control_writer, "stdout handoff failed: $!");
            _exit(126);
        }
        unless (open STDERR, '>&', $output_writer) {
            _write_child_control($control_writer, "stderr handoff failed: $!");
            _exit(126);
        }
        close $stdin_reader;
        close $output_writer;
        {
            no warnings 'exec';
            exec {$argv->[0]} @$argv;
        }
        _write_child_control($control_writer, "exec failed: $!");
        _exit(127);
    }

    close $stdin_reader;
    close $output_writer;
    close $control_writer;
    close $containment_writer;
    close $stdin_writer;
    eval { setpgid($pid, $pid); 1 }
        if $policy->{containment} eq 'lifecycle_process_group';
    for my $fh ($output_reader, $control_reader, $containment_reader) {
        my $flags = fcntl($fh, F_GETFL, 0);
        fcntl($fh, F_SETFL, $flags | O_NONBLOCK) if defined $flags;
    }
    my $output_fileno = fileno($output_reader);
    my $control_fileno = fileno($control_reader);
    my $select = IO::Select->new($control_reader, $output_reader);
    my ($output, $exec_error) = ('', '');
    my ($timed_out, $limited) = (0, 0);
    my ($exec_handoff, $first_output);
    my (%observed_descendants, $observation_error);
    my $next_observation = $started;
    while ($select->count) {
        my $now = clock_gettime(CLOCK_MONOTONIC);
        if ($now > $capture_deadline) {
            $timed_out = 1;
            last;
        }
        if ($now >= $next_observation) {
            my $observed = eval {
                _observe_selected_tool_descendants(
                    $pid, \%observed_descendants, $capture_deadline,
                );
                1;
            };
            if (!$observed) {
                $observation_error = $@;
                last;
            }
            $next_observation += $PROCESS_OBSERVATION_INTERVAL_SECONDS
                while $next_observation <= $now;
        }
        my @ready = sort {
            (fileno($a) == $control_fileno ? 0 : 1)
                <=> (fileno($b) == $control_fileno ? 0 : 1)
        } $select->can_read(0.05);
        for my $fh (@ready) {
            my $chunk = '';
            my $read = sysread($fh, $chunk, 65_536);
            if (defined($read) && $read > 0) {
                if (fileno($fh) == $output_fileno) {
                    $first_output //= clock_gettime(CLOCK_MONOTONIC);
                    $output .= $chunk;
                    if (bytes::length($output)
                            > $policy->{capture_limit_bytes}) {
                        $limited = 1;
                        last;
                    }
                }
                else {
                    $exec_error .= $chunk;
                }
            }
            elsif (defined($read) && $read == 0) {
                $exec_handoff //= clock_gettime(CLOCK_MONOTONIC)
                    if fileno($fh) == $control_fileno
                        && !length($exec_error);
                $select->remove($fh);
                close $fh;
            }
        }
        last if $limited;
    }
    if (defined $observation_error) {
        $select->remove($_) for $select->handles;
        close $_ for grep { defined(fileno($_)) }
            ($output_reader, $control_reader);
        my $contained = eval {
            _terminate_supervised_domains(
                $pid,
                $policy->{containment} eq 'lifecycle_process_group',
                \%observed_descendants,
                $containment_reader, $containment_identity,
            );
            1;
        };
        _throw(
            'VIAL_PROCESS_RESIDUE_ERROR',
            'selected-tool process domains survived failed observation',
            '/process',
        ) unless $contained;
        _throw(
            'VIAL_PROCESS_HOST_ERROR',
            'selected-tool descendant observation failed', '/process',
        );
    }
    my $status;
    if ($timed_out || $limited) {
        $select->remove($_) for $select->handles;
        close $_ for grep { defined(fileno($_)) }
            ($output_reader, $control_reader);
        $status = _terminate_supervised_domains(
            $pid,
            $policy->{containment} eq 'lifecycle_process_group',
            \%observed_descendants,
            $containment_reader, $containment_identity,
        );
    }
    else {
        while (1) {
            my $now = clock_gettime(CLOCK_MONOTONIC);
            if ($now > $capture_deadline) {
                $timed_out = 1;
                $status = _terminate_supervised_domains(
                    $pid,
                    $policy->{containment} eq 'lifecycle_process_group',
                    \%observed_descendants,
                    $containment_reader, $containment_identity,
                );
                last;
            }
            if ($now >= $next_observation) {
                my $observed = eval {
                    _observe_selected_tool_descendants(
                        $pid, \%observed_descendants, $capture_deadline,
                    );
                    1;
                };
                if (!$observed) {
                    $observation_error = $@;
                    last;
                }
                $next_observation += $PROCESS_OBSERVATION_INTERVAL_SECONDS
                    while $next_observation <= $now;
            }
            my ($waited, $wait_status) = _poll_owned_child($pid);
            if (defined($waited)
                    && ($waited == $pid || $waited == -1)) {
                $status = $wait_status;
                last;
            }
            sleep(0.01);
        }
        if (defined $observation_error) {
            my $contained = eval {
                _terminate_supervised_domains(
                    $pid,
                    $policy->{containment} eq 'lifecycle_process_group',
                    \%observed_descendants,
                    $containment_reader, $containment_identity,
                );
                1;
            };
            _throw(
                'VIAL_PROCESS_RESIDUE_ERROR',
                'selected-tool process domains survived failed observation',
                '/process',
            ) unless $contained;
            _throw(
                'VIAL_PROCESS_HOST_ERROR',
                'selected-tool descendant observation failed', '/process',
            );
        }
        my ($observed_residue, $observed_failure) = (0, undef);
        my $observed = eval {
            $observed_residue = _terminate_observed_descendants(
                \%observed_descendants,
                _host_observer_cleanup_deadline(),
            );
            1;
        };
        $observed_failure = $@ unless $observed;
        my ($group_residue, $group_failure) = (0, undef);
        if ($policy->{containment} eq 'lifecycle_process_group') {
            $group_residue = kill(0, -$pid) ? 1 : 0;
            if ($group_residue) {
                my $contained = eval {
                    _terminate_residual_group($pid);
                    1;
                };
                $group_failure = $@ unless $contained;
            }
        }
        my ($pipe_residue, $pipe_failure) = (0, undef);
        my $pipe_contained = eval {
            $pipe_residue = _terminate_containment_pipe_holders(
                $containment_reader, $containment_identity,
                _host_observer_cleanup_deadline(),
            );
            1;
        };
        $pipe_failure = $@ unless $pipe_contained;
        _throw(
            'VIAL_PROCESS_RESIDUE_ERROR',
            'selected-tool residual process domains survived containment',
            '/process',
        ) if defined($observed_failure) || defined($group_failure)
            || defined($pipe_failure);
        if ($observed_residue || $group_residue || $pipe_residue) {
            _throw(
                'VIAL_PROCESS_RESIDUE_ERROR',
                'selected-tool process containment retained a descendant '
                    . 'after its leader exited',
                '/process',
            );
        }
    }
    close $containment_reader;
    my $finished = clock_gettime(CLOCK_MONOTONIC);
    $exec_handoff //= $finished unless length $exec_error;
    $exec_error =~ s/[\r\n\t]+/ /g;
    $exec_error =~ s/\s+/ /g;
    $exec_error = substr($exec_error, 0, 2_048)
        if length($exec_error) > 2_048;
    my $started_ns = int($started * 1_000_000_000);
    my $exec_handoff_ns = defined($exec_handoff)
        ? int($exec_handoff * 1_000_000_000) : undef;
    my $first_output_ns = defined($first_output)
        ? int($first_output * 1_000_000_000) : undef;
    my $finished_ns = int($finished * 1_000_000_000);
    return {
        ok => (!$timed_out && !$limited && !length($exec_error)
                && ($status & 127) == 0)
            ? JSON::PP::true : JSON::PP::false,
        exit_code => ($status & 127)
            ? 128 + ($status & 127) : ($status >> 8),
        signal => $status & 127,
        output => $output,
        timed_out => $timed_out ? JSON::PP::true : JSON::PP::false,
        output_limited => $limited ? JSON::PP::true : JSON::PP::false,
        exec_failed => length($exec_error)
            ? JSON::PP::true : JSON::PP::false,
        exec_error => length($exec_error) ? $exec_error : undef,
        started_monotonic_ns => $started_ns,
        exec_handoff_monotonic_ns => $exec_handoff_ns,
        first_output_monotonic_ns => $first_output_ns,
        finished_monotonic_ns => $finished_ns,
        spawn_to_exec_ns => defined($exec_handoff_ns)
            ? $exec_handoff_ns - $started_ns : undef,
        execution_ns => defined($exec_handoff_ns)
            ? $finished_ns - $exec_handoff_ns : undef,
        exec_to_first_output_ns =>
            defined($exec_handoff_ns) && defined($first_output_ns)
                ? $first_output_ns - $exec_handoff_ns : undef,
        first_output_to_exit_ns => defined($first_output_ns)
            ? $finished_ns - $first_output_ns : undef,
        containment => $policy->{containment},
        timeout_seconds => 0 + $policy->{timeout_seconds},
        capture_limit_bytes => 0 + $policy->{capture_limit_bytes},
        output_bytes => bytes::length($output),
    };
}

sub _write_child_control($fh, $message) {
    $message = substr($message, 0, 2_048);
    my $offset = 0;
    while ($offset < bytes::length($message)) {
        my $written = syswrite(
            $fh, $message, bytes::length($message) - $offset, $offset,
        );
        next if !defined($written) && $! == EINTR;
        last unless defined($written) && $written > 0;
        $offset += $written;
    }
    return;
}

sub _host_observer_cleanup_deadline() {
    return clock_gettime(CLOCK_MONOTONIC)
        + $HOST_OBSERVER_CLEANUP_TIMEOUT_SECONDS;
}

sub _poll_owned_child($pid) {
    my $waited = waitpid($pid, WNOHANG);
    return if $waited == -1 && $! == EINTR;
    return ($waited, $?);
}

sub _terminate_host_observer($pid) {
    kill 'TERM', $pid;
    my $term_deadline = clock_gettime(CLOCK_MONOTONIC) + 0.2;
    while (clock_gettime(CLOCK_MONOTONIC) < $term_deadline) {
        my ($waited) = _poll_owned_child($pid);
        return if defined($waited)
            && ($waited == $pid || $waited == -1);
        sleep(0.01);
    }
    kill 'KILL', $pid;
    my $kill_deadline = clock_gettime(CLOCK_MONOTONIC) + 1;
    while (clock_gettime(CLOCK_MONOTONIC) < $kill_deadline) {
        my ($waited) = _poll_owned_child($pid);
        return if defined($waited)
            && ($waited == $pid || $waited == -1);
        sleep(0.01);
    }
    die "selected-tool host observer could not be reaped\n";
}

sub _abort_host_observer($reader, $pid, $message) {
    my $contained = eval {
        _terminate_host_observer($pid);
        1;
    };
    close $reader;
    die "selected-tool host observer survived containment\n"
        unless $contained;
    die "$message\n";
}

sub _bounded_host_command($deadline, @command) {
    my ($reader, $writer);
    pipe($reader, $writer)
        or die "selected-tool host observation pipe is unavailable\n";
    my $pid = fork();
    if (!defined $pid) {
        close $reader;
        close $writer;
        die "selected-tool host observation command is unavailable\n";
    }
    if ($pid == 0) {
        close $reader;
        open STDIN, '<', '/dev/null' or _exit(126);
        open STDOUT, '>&', $writer or _exit(126);
        open STDERR, '>', '/dev/null' or _exit(126);
        close $writer;
        {
            no warnings 'exec';
            exec {$command[0]} @command;
        }
        _exit(127);
    }
    close $writer;
    my $flags = fcntl($reader, F_GETFL, 0);
    _abort_host_observer(
        $reader, $pid,
        'selected-tool host observation pipe cannot be inspected',
    ) unless defined $flags;
    _abort_host_observer(
        $reader, $pid,
        'selected-tool host observation pipe cannot be made nonblocking',
    ) unless fcntl($reader, F_SETFL, $flags | O_NONBLOCK);

    my $output = '';
    my ($eof, $status) = (0, undef);
    while (1) {
        while (!$eof) {
            my $chunk = '';
            my $read = sysread($reader, $chunk, 65_536);
            if (defined $read) {
                if ($read == 0) {
                    $eof = 1;
                    last;
                }
                $output .= $chunk;
                _abort_host_observer(
                    $reader, $pid,
                    'selected-tool host observation exceeds its bound',
                ) if bytes::length($output) > $PROCESS_CENSUS_MAX_BYTES;
                next;
            }
            next if $! == EINTR;
            last if $! == EAGAIN || $! == EWOULDBLOCK;
            _abort_host_observer(
                $reader, $pid,
                'selected-tool host observation could not be read',
            );
        }
        if (!defined $status) {
            my ($waited, $wait_status) = _poll_owned_child($pid);
            if (defined $waited) {
                $status = $wait_status if $waited == $pid;
                $status = 0 if $waited == -1;
            }
        }
        last if $eof && defined $status;
        _abort_host_observer(
            $reader, $pid,
            'selected-tool host observation exceeded its deadline',
        ) if clock_gettime(CLOCK_MONOTONIC) >= $deadline;
        sleep(0.01);
    }
    close $reader;
    die "selected-tool host observation did not complete\n"
        unless ($status & 127) == 0 && ($status >> 8) == 0;
    return $output;
}

sub _containment_pipe_identity($writer, $deadline) {
    die "selected-tool containment descriptor is not a pipe\n"
        unless -p $writer;
    if ($^O eq 'linux') {
        my @stat = stat($writer);
        die "selected-tool containment pipe identity is unavailable\n"
            unless @stat && $stat[1] =~ /\A[1-9][0-9]*\z/;
        return "linux-pipe-inode:$stat[1]";
    }
    if ($^O eq 'darwin') {
        my $fd = fileno($writer);
        die "selected-tool containment descriptor is unavailable\n"
            unless defined $fd;
        my $output = _bounded_host_command(
            $deadline,
            'lsof', '-nP', '-F', 'pfn', '-a', '-p', "$$", '-d', "$fd",
        );
        my @identities = $output =~ /^n(->0x[0-9a-f]+)$/gmi;
        die "selected-tool containment endpoint identity is ambiguous\n"
            unless @identities == 1;
        return "darwin-pipe-endpoint:$identities[0]";
    }
    die "selected-tool containment host is unsupported\n";
}

sub _containment_pipe_has_writer($reader) {
    my $drained = 0;
    while (1) {
        my $chunk = '';
        my $read = sysread($reader, $chunk, 65_536);
        if (defined $read) {
            return 0 if $read == 0;
            $drained += $read;
            return 1 if $drained > $PROCESS_CENSUS_MAX_BYTES;
            next;
        }
        next if $! == EINTR;
        return 1 if $! == EAGAIN || $! == EWOULDBLOCK;
        die "selected-tool containment pipe cannot be observed\n";
    }
}

sub _darwin_containment_pipe_holders($endpoint, $deadline) {
    my $user = getpwuid($<);
    die "selected-tool containment owner is unavailable\n"
        unless defined($user) && length($user);
    my $output = _bounded_host_command(
        $deadline,
        'lsof', '-nP', '-F', 'pn', '-u', $user,
    );
    my ($pid, %holders, $rows);
    for my $line (split /\n/, $output) {
        $rows++;
        die "selected-tool holder census exceeds its row bound\n"
            if $rows > $PROCESS_CENSUS_MAX_ROWS;
        if ($line =~ /\Ap([1-9][0-9]*)\z/) {
            $pid = 0 + $1;
            next;
        }
        if ($line eq "n$endpoint") {
            die "selected-tool holder census has no PID context\n"
                unless defined $pid;
            $holders{$pid} = 1 unless $pid == $$;
        }
    }
    return [sort { $a <=> $b } keys %holders];
}

sub _linux_containment_pipe_holders($inode) {
    opendir my $proc, '/proc'
        or die "selected-tool procfs census is unavailable\n";
    my (@pids, $rows);
    while (my $entry = readdir $proc) {
        next unless $entry =~ /\A[1-9][0-9]*\z/;
        my $pid = 0 + $entry;
        next if $pid == $$;
        my @stat = stat("/proc/$pid");
        next unless @stat && $stat[4] == $<;
        opendir my $fds, "/proc/$pid/fd" or next;
        my $holds = 0;
        while (my $fd = readdir $fds) {
            next unless $fd =~ /\A[0-9]+\z/;
            $rows++;
            if ($rows > $PROCESS_CENSUS_MAX_ROWS) {
                closedir $fds;
                closedir $proc;
                die "selected-tool procfs holder census exceeds its bound\n";
            }
            my $target = readlink "/proc/$pid/fd/$fd";
            if (defined($target) && $target eq "pipe:[$inode]") {
                $holds = 1;
                last;
            }
        }
        closedir $fds;
        push @pids, $pid if $holds;
    }
    closedir $proc;
    return [sort { $a <=> $b } @pids];
}

sub _containment_pipe_holders($identity, $deadline) {
    if ($identity =~ /\Adarwin-pipe-endpoint:(->0x[0-9a-f]+)\z/) {
        return _darwin_containment_pipe_holders($1, $deadline);
    }
    if ($identity =~ /\Alinux-pipe-inode:([1-9][0-9]*)\z/) {
        return _linux_containment_pipe_holders($1);
    }
    die "selected-tool containment identity is malformed\n";
}

sub _terminate_containment_pipe_holders($reader, $identity, $deadline) {
    return 0 unless _containment_pipe_has_writer($reader);
    my $holders = _containment_pipe_holders($identity, $deadline);
    die "selected-tool containment pipe has no attributable holder\n"
        unless @$holders;
    kill 'STOP', @$holders;
    kill 'KILL', @$holders;
    my $absence_deadline = clock_gettime(CLOCK_MONOTONIC) + 2;
    while (clock_gettime(CLOCK_MONOTONIC) < $absence_deadline) {
        return scalar(@$holders)
            unless _containment_pipe_has_writer($reader);
        sleep(0.02);
    }
    die "selected-tool containment pipe remained live after holder kill\n";
}

sub _selected_tool_process_snapshot($deadline) {
    my $output = _bounded_host_command(
        $deadline, 'ps', '-axo', 'pid=,ppid=,lstart=',
    );
    my (%rows, $bytes, $count);
    for my $line (split /(?<=\n)/, $output) {
        $bytes += bytes::length($line);
        $count++;
        if ($bytes > $PROCESS_CENSUS_MAX_BYTES
                || $count > $PROCESS_CENSUS_MAX_ROWS) {
            die "selected-tool process census exceeds its structural bound\n";
        }
        next if $line =~ /\A\s*\z/;
        my ($pid, $parent, $started) = $line
            =~ /\A\s*([1-9][0-9]*)\s+([0-9]+)\s+(.+?\S)\s*\z/
            or do {
                die "selected-tool process census is malformed\n";
            };
        die "selected-tool process census repeats a PID\n"
            if exists $rows{$pid};
        $rows{$pid} = {
            parent => 0 + $parent,
            started => $started,
        };
    }
    return \%rows;
}

sub _observe_selected_tool_descendants($root_pid, $observed, $deadline) {
    my $rows = _selected_tool_process_snapshot($deadline);
    my %children;
    for my $pid (keys %$rows) {
        push $children{$rows->{$pid}{parent}}->@*, 0 + $pid;
    }
    my (@pending, %seen);
    push @pending, $children{$root_pid}->@*
        if exists $children{$root_pid};
    while (@pending) {
        my $pid = shift @pending;
        next if $seen{$pid}++;
        $observed->{$pid} = $rows->{$pid}{started};
        push @pending, $children{$pid}->@*
            if exists $children{$pid};
    }
    return;
}

sub _terminate_observed_descendants($observed, $deadline) {
    my %targets;
    while (1) {
        my $rows = _selected_tool_process_snapshot($deadline);
        my %children;
        for my $pid (keys %$rows) {
            push $children{$rows->{$pid}{parent}}->@*, 0 + $pid;
        }
        my @pending = grep {
            exists($rows->{$_})
                && $rows->{$_}{started} eq $observed->{$_}
        } keys %$observed;
        my @new;
        while (@pending) {
            my $pid = shift @pending;
            next if exists $targets{$pid};
            $targets{$pid} = $rows->{$pid}{started};
            push @new, $pid;
            push @pending, $children{$pid}->@*
                if exists $children{$pid};
        }
        last unless @new;
        kill 'STOP', @new;
    }

    my $count = scalar keys %targets;
    return 0 unless $count;
    kill 'KILL', sort { $a <=> $b } keys %targets;
    my $absence_deadline = clock_gettime(CLOCK_MONOTONIC) + 2;
    while (clock_gettime(CLOCK_MONOTONIC) < $absence_deadline) {
        my $rows = _selected_tool_process_snapshot($deadline);
        my @alive = grep {
            exists($rows->{$_}) && $rows->{$_}{started} eq $targets{$_}
        } keys %targets;
        return $count unless @alive;
        sleep(0.02);
    }
    die "selected-tool detached descendants survived containment\n";
}

sub _terminate_supervised_domains(
    $pid, $process_group, $observed, $containment_reader,
    $containment_identity,
) {
    my ($status, $group_error, $observed_error, $pipe_error);
    my $group_contained = eval {
        $status = _terminate_process($pid, $process_group);
        1;
    };
    $group_error = $@ unless $group_contained;
    my $observed_contained = eval {
        _terminate_observed_descendants(
            $observed, _host_observer_cleanup_deadline(),
        );
        1;
    };
    $observed_error = $@ unless $observed_contained;
    my $pipe_contained = eval {
        _terminate_containment_pipe_holders(
            $containment_reader, $containment_identity,
            _host_observer_cleanup_deadline(),
        );
        1;
    };
    $pipe_error = $@ unless $pipe_contained;
    _throw(
        'VIAL_PROCESS_RESIDUE_ERROR',
        'selected-tool process domains survived containment', '/process',
    ) if defined($group_error) || defined($observed_error)
        || defined($pipe_error);
    return $status;
}

sub _terminate_process($pid, $process_group) {
    my $target = $process_group ? -$pid : $pid;
    kill 'TERM', $target;
    my $deadline = clock_gettime(CLOCK_MONOTONIC) + 2;
    my ($leader_reaped, $leader_status) = (0, undef);
    while (clock_gettime(CLOCK_MONOTONIC) < $deadline) {
        unless ($leader_reaped) {
            my ($waited, $wait_status) = _poll_owned_child($pid);
            if (defined($waited)
                    && ($waited == $pid || $waited == -1)) {
                $leader_reaped = 1;
                $leader_status = $wait_status;
            }
        }
        my $domain_alive = $process_group
            ? kill(0, -$pid)
            : (!$leader_reaped && kill(0, $pid));
        return defined($leader_status) ? $leader_status : 0
            if $leader_reaped && !$domain_alive;
        select undef, undef, undef, 0.02;
    }
    kill 'KILL', $target;
    unless ($leader_reaped) {
        my $reap_deadline = clock_gettime(CLOCK_MONOTONIC) + 2;
        while (clock_gettime(CLOCK_MONOTONIC) < $reap_deadline) {
            my ($waited, $wait_status) = _poll_owned_child($pid);
            if (defined($waited)
                    && ($waited == $pid || $waited == -1)) {
                $leader_reaped = 1;
                $leader_status = $wait_status;
                last;
            }
            sleep(0.02);
        }
    }
    my $leader_reap_failed = !$leader_reaped;
    if ($process_group) {
        my $kill_deadline = clock_gettime(CLOCK_MONOTONIC) + 2;
        while (kill(0, -$pid)
                && clock_gettime(CLOCK_MONOTONIC) < $kill_deadline) {
            select undef, undef, undef, 0.02;
        }
        _throw(
            'VIAL_PROCESS_RESIDUE_ERROR',
            'selected-tool process group survived TERM/KILL containment',
            '/process',
        ) if kill(0, -$pid);
    }
    _throw(
        'VIAL_PROCESS_RESIDUE_ERROR',
        'selected-tool leader survived bounded SIGKILL reap', '/process',
    ) if $leader_reap_failed;
    return defined($leader_status) ? $leader_status : 0;
}

sub _terminate_residual_group($pid) {
    kill 'TERM', -$pid;
    my $deadline = clock_gettime(CLOCK_MONOTONIC) + 2;
    while (kill(0, -$pid)
            && clock_gettime(CLOCK_MONOTONIC) < $deadline) {
        select undef, undef, undef, 0.02;
    }
    return unless kill(0, -$pid);
    kill 'KILL', -$pid;
    my $kill_deadline = clock_gettime(CLOCK_MONOTONIC) + 2;
    while (kill(0, -$pid)
            && clock_gettime(CLOCK_MONOTONIC) < $kill_deadline) {
        select undef, undef, undef, 0.02;
    }
    _throw(
        'VIAL_PROCESS_RESIDUE_ERROR',
        'selected-tool residual process group survived TERM/KILL containment',
        '/process',
    ) if kill(0, -$pid);
}

sub _closed($value, $keys, $label) {
    _throw('VIAL_PROCESS_INVOCATION_ERROR', "$label is not one hash", '/')
        unless ref($value) eq 'HASH' && !blessed($value);
    my %expected = map { $_ => 1 } @$keys;
    my @unknown = sort grep { !$expected{$_} } keys %$value;
    my @missing = grep { !exists($value->{$_}) } @$keys;
    _throw('VIAL_PROCESS_INVOCATION_ERROR',
        "$label has unknown key '$unknown[0]'", '/') if @unknown;
    _throw('VIAL_PROCESS_INVOCATION_ERROR',
        "$label is missing key '$missing[0]'", '/') if @missing;
}

sub _throw($code, $message, $path) {
    die bless {code => $code, message => $message, path => $path},
        'FSM::VIAL::Backend::ProcessSupervisor::Failure';
}

package FSM::VIAL::Backend::ProcessSupervisor::Failure;

use overload '""' => sub {
    $_[0]{message} // 'VIAL process supervision failure'
}, fallback => 1;

1;
