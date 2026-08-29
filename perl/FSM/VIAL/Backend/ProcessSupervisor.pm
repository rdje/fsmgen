package FSM::VIAL::Backend::ProcessSupervisor;

use v5.20;
use strict;
use warnings;
use bytes ();
use Cwd qw(abs_path);
use Errno qw(EINTR);
use Fcntl qw(FD_CLOEXEC F_GETFD F_GETFL F_SETFD F_SETFL O_NONBLOCK);
use IO::Select;
use JSON::PP ();
use POSIX qw(WNOHANG _exit setpgid);
use Scalar::Util qw(blessed);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime sleep time);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

my $POLICY_SCHEMA = 'fsmgen.vial_process_supervisor_policy.v1';
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
    pipe($stdin_reader, $stdin_writer)
        or _throw('VIAL_PROCESS_HOST_ERROR',
            'cannot create selected-tool stdin pipe', '/process');
    pipe($output_reader, $output_writer)
        or _throw('VIAL_PROCESS_HOST_ERROR',
            'cannot create selected-tool output pipe', '/process');
    pipe($control_reader, $control_writer)
        or _throw('VIAL_PROCESS_HOST_ERROR',
            'cannot create selected-tool exec-control pipe', '/process');
    my $control_flags = fcntl($control_writer, F_GETFD, 0);
    _throw('VIAL_PROCESS_HOST_ERROR',
        'cannot inspect selected-tool exec-control pipe', '/process')
        unless defined $control_flags;
    _throw('VIAL_PROCESS_HOST_ERROR',
        'cannot seal selected-tool exec-control pipe close-on-exec', '/process')
        unless fcntl($control_writer, F_SETFD, $control_flags | FD_CLOEXEC);

    my $started = clock_gettime(CLOCK_MONOTONIC);
    my $pid = fork();
    _throw('VIAL_PROCESS_HOST_ERROR',
        'cannot fork the selected tool', '/process') unless defined $pid;
    if ($pid == 0) {
        close $stdin_writer;
        close $output_reader;
        close $control_reader;
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
    close $stdin_writer;
    eval { setpgid($pid, $pid); 1 }
        if $policy->{containment} eq 'lifecycle_process_group';
    for my $fh ($output_reader, $control_reader) {
        my $flags = fcntl($fh, F_GETFL, 0);
        fcntl($fh, F_SETFL, $flags | O_NONBLOCK) if defined $flags;
    }
    my $output_fileno = fileno($output_reader);
    my $control_fileno = fileno($control_reader);
    my $select = IO::Select->new($control_reader, $output_reader);
    my ($output, $exec_error) = ('', '');
    my ($timed_out, $limited) = (0, 0);
    my ($exec_handoff, $first_output);
    while ($select->count) {
        my $now = clock_gettime(CLOCK_MONOTONIC);
        if ($now - $started > $policy->{timeout_seconds}) {
            $timed_out = 1;
            last;
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
    my $status;
    if ($timed_out || $limited) {
        $select->remove($_) for $select->handles;
        close $_ for grep { defined(fileno($_)) }
            ($output_reader, $control_reader);
        $status = _terminate_process(
            $pid, $policy->{containment} eq 'lifecycle_process_group',
        );
    }
    else {
        while (1) {
            my $waited = waitpid($pid, WNOHANG);
            if ($waited == $pid || $waited == -1) {
                $status = $?;
                last;
            }
            if (clock_gettime(CLOCK_MONOTONIC) - $started
                    > $policy->{timeout_seconds}) {
                $timed_out = 1;
                $status = _terminate_process(
                    $pid,
                    $policy->{containment} eq 'lifecycle_process_group',
                );
                last;
            }
            sleep(0.01);
        }
        if ($policy->{containment} eq 'lifecycle_process_group'
                && kill(0, -$pid)) {
            _terminate_residual_group($pid);
            _throw(
                'VIAL_PROCESS_RESIDUE_ERROR',
                'selected-tool process group retained a descendant after '
                    . 'its leader exited',
                '/process',
            );
        }
    }
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

sub _terminate_process($pid, $process_group) {
    my $target = $process_group ? -$pid : $pid;
    kill 'TERM', $target;
    my $deadline = time() + 2;
    my ($leader_reaped, $leader_status) = (0, undef);
    while (time() < $deadline) {
        unless ($leader_reaped) {
            my $waited = waitpid($pid, WNOHANG);
            if ($waited == $pid || $waited == -1) {
                $leader_reaped = 1;
                $leader_status = $?;
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
        waitpid($pid, 0);
        $leader_status = $?;
    }
    if ($process_group) {
        my $kill_deadline = time() + 2;
        while (kill(0, -$pid) && time() < $kill_deadline) {
            select undef, undef, undef, 0.02;
        }
        _throw(
            'VIAL_PROCESS_RESIDUE_ERROR',
            'selected-tool process group survived TERM/KILL containment',
            '/process',
        ) if kill(0, -$pid);
    }
    return defined($leader_status) ? $leader_status : 0;
}

sub _terminate_residual_group($pid) {
    kill 'TERM', -$pid;
    my $deadline = time() + 2;
    while (kill(0, -$pid) && time() < $deadline) {
        select undef, undef, undef, 0.02;
    }
    return unless kill(0, -$pid);
    kill 'KILL', -$pid;
    my $kill_deadline = time() + 2;
    while (kill(0, -$pid) && time() < $kill_deadline) {
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
