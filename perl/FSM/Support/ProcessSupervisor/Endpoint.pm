package FSM::Support::ProcessSupervisor::Endpoint;

use strict;
use warnings;

use Errno qw(EAGAIN EINPROGRESS EINTR EWOULDBLOCK);
use Fcntl qw(:mode FD_CLOEXEC F_GETFD F_GETFL F_SETFD F_SETFL
    O_DIRECTORY O_NOFOLLOW O_NONBLOCK O_RDONLY);
use File::Spec;
use POSIX qw(SIG_BLOCK SIG_SETMASK SIGCHLD SA_NOCLDWAIT);
use Socket qw(AF_UNIX SOCK_STREAM SOL_SOCKET SO_ERROR sockaddr_un);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime);
use FSM::Support::ProcessSupervisor ();
use FSM::Support::ProcessSupervisor::Wire ();

# Inactive private transport, not a command runner or an authentication service.
# Only its future coordinator may bind a decoded context to live job authority.
# These operations require a single-threaded Unix caller with no concurrent cwd
# mutation. No endpoint is opened merely by loading this module.
my $ROOT = FSM::Support::ProcessSupervisor::repository_root();
my $DEVICE = (stat $ROOT)[0];
my $DIRECTORY = '.artifacts/tmp/process-coordinator';
my $LIMIT = FSM::Support::ProcessSupervisor::Wire::limits();

sub _fail { die "private process endpoint: $_[0]\n" }

sub _seal_handle {
    my ($handle, $nonblocking) = @_;
    my $flags = fcntl($handle, F_GETFD, 0);
    _fail('cannot seal descriptor') unless defined($flags)
        && fcntl($handle, F_SETFD, $flags | FD_CLOEXEC);
    if ($nonblocking) {
        $flags = fcntl($handle, F_GETFL, 0);
        _fail('cannot make descriptor nonblocking') unless defined($flags)
            && fcntl($handle, F_SETFL, $flags | O_NONBLOCK);
    }
    return $handle;
}

sub _random_bytes {
    my ($count) = @_;
    # This character device is an explicit read-only OS dependency. Tokens
    # remain in memory and never appear in diagnostics, files or task evidence.
    sysopen(my $source, '/dev/urandom', O_RDONLY | O_NONBLOCK)
        or _fail('OS random source unavailable');
    _seal_handle($source, 0);
    my $bytes = '';
    my $deadline = clock_gettime(CLOCK_MONOTONIC) + $LIMIT->{handshake_seconds};
    for (1 .. 8) {
        last if length($bytes) == $count
            || clock_gettime(CLOCK_MONOTONIC) >= $deadline;
        my $read = sysread($source, my $part, $count - length($bytes));
        next if !defined($read) && $! == EINTR;
        last unless defined($read) && $read > 0;
        $bytes .= $part;
    }
    close $source or _fail('cannot close OS random source');
    _fail('OS random source returned incomplete authority') unless length($bytes) == $count;
    return $bytes;
}

sub new_job_token {
    _fail('unexpected token arguments') if @_;
    return _random_bytes(32);
}

sub _lstat { return lstat($_[0]) }

sub _identity {
    my ($path, $kind, $mode) = @_;
    my @stat = _lstat($path);
    _fail('endpoint identity is absent or inaccessible') unless @stat;
    _fail('endpoint has wrong file type')
        unless $kind eq 'directory' ? S_ISDIR($stat[2]) : S_ISSOCK($stat[2]);
    _fail('endpoint has foreign owner or device')
        unless $stat[0] == $DEVICE && $stat[4] == $>;
    _fail('endpoint permissions changed')
        if defined($mode) && ($stat[2] & 07777) != $mode;
    return [@stat[0, 1, 2, 4]];
}

sub _same_identity {
    my ($left, $right) = @_;
    return join(':', @$left) eq join(':', @$right);
}

sub _absolute_directory {
    my ($relative) = @_;
    my ($absolute, $error) = FSM::Support::ProcessSupervisor::repository_contained_path(
        $relative, must_exist => 1,
    );
    _fail('endpoint directory is outside the admitted repository ancestry') if defined $error;
    # Recheck every existing component for ownership/type/device, including
    # the fixed ancestry. Only the exclusively owned run has an exact mode.
    my $cursor = $ROOT;
    _identity($cursor, 'directory', undef);
    for my $part (split m{/}, $relative) {
        $cursor .= "/$part";
        _identity($cursor, 'directory', undef);
    }
    return $absolute;
}

sub _make_ancestry {
    my $cursor = $ROOT;
    for my $part (split m{/}, $DIRECTORY) {
        $cursor .= "/$part";
        unless (-e $cursor || -l $cursor) {
            mkdir($cursor, 0700) or _fail('cannot create endpoint ancestry');
            # Do not mutate the caller's umask. chmod applies only to this
            # just-created directory, never an existing or foreign component.
            _identity($cursor, 'directory', undef);
            chmod(0700, $cursor) == 1 or _fail('cannot secure endpoint ancestry');
        }
        _identity($cursor, 'directory', undef);
    }
}

sub _open_run_directory {
    my ($relative) = @_;
    my $absolute = _absolute_directory($relative);
    my $identity = _identity($absolute, 'directory', 0700);
    sysopen(my $handle, $absolute, O_RDONLY | O_DIRECTORY | O_NOFOLLOW)
        or _fail('cannot open endpoint directory');
    _seal_handle($handle, 0);
    my @opened = stat($handle);
    _fail('endpoint directory changed while opening') unless @opened
        && _same_identity($identity, [@opened[0, 1, 2, 4]]);
    return ($handle, $identity);
}

sub _entries {
    opendir(my $directory, '.') or _fail('cannot inspect endpoint directory');
    my @entries;
    while (defined(my $entry = readdir $directory)) {
        next if $entry eq '.' || $entry eq '..';
        # No unbounded directory census or diagnostic of attacker-chosen names.
        _fail('unexpected endpoint directory entry') if $entry ne 's' || @entries;
        push @entries, $entry;
    }
    closedir($directory) or _fail('cannot close endpoint directory inspection');
    return scalar @entries;
}

sub _bind_socket { return bind($_[0], sockaddr_un('s')) }
sub _connect_socket { return connect($_[0], sockaddr_un('s')) }
sub _restore_cwd { return chdir($_[0]) }

sub _directory_operation {
    my ($state, $operation, $socket) = @_;
    _fail('unknown directory operation')
        unless $operation eq 'bind' || $operation eq 'connect' || $operation eq 'remove';
    sysopen(my $saved, '.', O_RDONLY | O_DIRECTORY)
        or _fail('cannot save caller directory');
    _seal_handle($saved, 0);
    my $all = POSIX::SigSet->new;
    $all->fillset;
    my $previous = POSIX::SigSet->new;
    defined(POSIX::sigprocmask(SIG_BLOCK, $all, $previous))
        or _fail('cannot mask directory transaction signals');

    my ($error, $connecting);
    {
        local $@;
        eval {
            my $absolute = _absolute_directory($state->{directory});
            _fail('endpoint directory identity changed') unless _same_identity(
                $state->{directory_identity}, _identity($absolute, 'directory', 0700));
            chdir($state->{directory_handle}) or _fail('cannot enter endpoint directory');
            _fail('endpoint directory handle identity changed') unless _same_identity(
                $state->{directory_identity}, _identity('.', 'directory', 0700));
            my $entries = _entries();
            if ($operation eq 'bind') {
                _fail('endpoint name already exists') if $entries;
                _bind_socket($socket) or _fail('cannot bind private socket');
                # Retain identity immediately, including before chmod/listen,
                # so partial startup owns exactly the filesystem name it made.
                $state->{socket_identity} = _identity('s', 'socket', undef);
                chmod(0600, 's') == 1 or _fail('cannot secure private socket');
                $state->{socket_identity} = _identity('s', 'socket', 0600);
                listen($socket, $LIMIT->{backlog}) or _fail('cannot listen on private socket');
            }
            elsif ($operation eq 'connect') {
                _fail('stale endpoint has no socket') unless $entries;
                my $before = _identity('s', 'socket', 0600);
                unless (_connect_socket($socket)) {
                    _fail('cannot connect private socket') unless $! == EINPROGRESS;
                    $connecting = 1;
                }
                _fail('socket identity changed during connection')
                    unless _same_identity($before, _identity('s', 'socket', 0600));
            }
            else {
                if ($state->{socket_identity}) {
                    _fail('owned socket identity changed') unless $entries
                        && _same_identity($state->{socket_identity},
                            _identity('s', 'socket', undef));
                    unlink('s') or _fail('cannot remove owned socket');
                    $state->{socket_removed} = 1;
                }
                else { _fail('unowned socket appeared during startup') if $entries; }
                # Recheck the named directory before removing it. Never walk
                # recursively, reclaim a previous run, or infer ownership from PID.
                _fail('endpoint directory identity changed before removal') unless _same_identity(
                    $state->{directory_identity}, _identity($absolute, 'directory', 0700));
                rmdir($absolute) or _fail('cannot remove empty owned endpoint directory');
                $state->{directory_removed} = 1;
            }
            if ($operation ne 'remove') {
                _absolute_directory($state->{directory});
                _fail('endpoint directory identity changed during socket operation')
                    unless _same_identity($state->{directory_identity},
                        _identity($absolute, 'directory', 0700));
                _entries();
            }
            1;
        } or $error = $@ || 'private process endpoint: directory transaction failed';
    }
    # Restoration is unconditional and handle-based, including a renamed
    # caller directory. No callback, fork or event-loop work runs in this scope.
    my $cwd_restored = eval { _restore_cwd($saved) };
    my $mask_restored = eval { defined POSIX::sigprocmask(SIG_SETMASK, $previous) };
    my $saved_closed = close $saved;
    _fail('fatal caller directory restoration failure') unless $cwd_restored;
    _fail('fatal caller signal-mask restoration failure') unless $mask_restored;
    _fail('cannot close saved caller directory') unless $saved_closed;
    die $error if defined $error;
    return $connecting ? 1 : 0;
}

sub create_run {
    _fail('unexpected create arguments') if @_;
    my $children = POSIX::SigAction->new;
    _fail('cannot inspect child-reaping disposition')
        unless defined POSIX::sigaction(SIGCHLD, undef, $children);
    _fail('default child-reaping disposition is required')
        unless defined($children->handler) && !ref($children->handler)
            && $children->handler eq 'DEFAULT'
            && !($children->flags & SA_NOCLDWAIT);
    my $run = _random_bytes(16);
    my $token = new_job_token();
    # Directory entropy is separate from the run/job authority: paths can be
    # inspected without publishing either protocol token.
    my $relative = "$DIRECTORY/run_" . unpack('H*', _random_bytes(32));
    _make_ancestry();
    my $absolute = File::Spec->catdir($ROOT, split m{/}, $relative);
    mkdir($absolute, 0700) or _fail('cannot exclusively create endpoint directory');
    my $state = bless {kind => 'run', owner_pid => $$, directory => $relative,
        run => $run, root_token => $token, socket_removed => 0, directory_removed => 0}, __PACKAGE__;
    my $ok = eval {
        my $initial = _identity($absolute, 'directory', undef);
        $state->{directory_identity} = $initial;
        chmod(0700, $absolute) == 1 or _fail('cannot secure endpoint directory');
        $state->{directory_identity} = _identity($absolute, 'directory', 0700);
        my ($handle, $identity) = _open_run_directory($relative);
        _fail('new endpoint directory was replaced')
            unless $initial->[0] == $identity->[0] && $initial->[1] == $identity->[1];
        @{$state}{qw(directory_handle directory_identity)} = ($handle, $identity);
        socket(my $socket, AF_UNIX, SOCK_STREAM, 0) or _fail('cannot create private socket');
        $state->{listener} = $socket;
        _seal_handle($socket, 1);
        _directory_operation($state, 'bind', $socket);
        1;
    };
    unless ($ok) {
        my $error = $@;
        my $cleanup = $state->close;
        die $error . ($cleanup->{ok} ? '' : "private process endpoint: startup cleanup incomplete\n");
    }
    return $state;
}

sub _require_owner {
    my ($self, $kind) = @_;
    _fail('invalid endpoint handle') unless ref($self) eq __PACKAGE__;
    _fail('inherited endpoint handle cannot be reused') unless $self->{owner_pid} == $$;
    _fail('endpoint handle is closed') if $self->{closed};
    _fail('endpoint handle has wrong role') if defined($kind) && $self->{kind} ne $kind;
}

sub context {
    my ($self) = @_;
    _fail('unexpected context arguments') unless @_ == 1;
    return $self->context_for(1, $self->{root_token});
}

sub context_for {
    my ($self, $parent, $token) = @_;
    _fail('unexpected authority arguments') unless @_ == 3;
    _require_owner($self, 'run');
    return FSM::Support::ProcessSupervisor::Wire::encode_context({
        directory => $self->{directory}, run => $self->{run}, parent => $parent, token => $token,
    });
}

sub listener {
    my ($self) = @_;
    _fail('unexpected listener arguments') unless @_ == 1;
    _require_owner($self, 'run');
    return $self->{listener};
}

sub connect_context {
    _fail('expected one inherited context') unless @_ == 1;
    my $context = FSM::Support::ProcessSupervisor::Wire::decode_context($_[0]);
    my ($directory, $identity) = _open_run_directory($context->{directory});
    my $state = bless {kind => 'client', owner_pid => $$, context => $context,
        directory => $context->{directory}, directory_handle => $directory,
        directory_identity => $identity}, __PACKAGE__;
    my $ok = eval {
        socket(my $socket, AF_UNIX, SOCK_STREAM, 0) or _fail('cannot create client socket');
        $state->{socket} = $socket;
        _seal_handle($socket, 1);
        $state->{connecting} = _directory_operation($state, 'connect', $socket);
        1;
    };
    my $error = $@;
    close(delete $state->{directory_handle}) or _fail('cannot close connected directory handle');
    unless ($ok) { $state->close; die $error; }
    return $state;
}

sub handle {
    my ($self) = @_;
    _fail('unexpected client handle arguments') unless @_ == 1;
    _require_owner($self, 'client');
    return $self->{socket};
}

sub connection_ready {
    my ($self) = @_;
    _fail('unexpected connection arguments') unless @_ == 1;
    _require_owner($self, 'client');
    return 1 unless $self->{connecting};
    # The connection driver calls this only after writable readiness and owns
    # the fixed connection deadline. EINPROGRESS is never a successful handoff.
    my $error = getsockopt($self->{socket}, SOL_SOCKET, SO_ERROR);
    _fail('cannot inspect connection completion') unless defined $error;
    _fail('private socket connection failed') if unpack('i', $error);
    return 0 unless defined getpeername($self->{socket});
    delete $self->{connecting};
    return 1;
}

sub discard_inherited {
    my ($self) = @_;
    _fail('expected an inherited endpoint handle') unless @_ == 1
        && ref($self) eq __PACKAGE__ && $self->{owner_pid} != $$;
    # The forked copy may close descriptors, never retire its creator's files.
    for my $key (qw(listener socket directory_handle)) {
        close(delete $self->{$key}) if $self->{$key};
    }
    $self->{closed} = 1;
    return;
}

sub close {
    my ($self) = @_;
    _fail('unexpected close arguments') unless @_ == 1;
    _fail('inherited endpoint handle cannot clean up its creator')
        unless ref($self) eq __PACKAGE__ && $self->{owner_pid} == $$;
    return {%{$self->{cleanup}}} if $self->{closed};
    my @error;
    for my $key (qw(listener socket)) {
        push @error, 'socket close failed' if $self->{$key} && !close(delete $self->{$key});
    }
    if ($self->{kind} eq 'run') {
        if ($self->{directory_handle}) {
            eval { _directory_operation($self, 'remove'); 1 } or push @error, $@;
        }
        else {
            # Failure before opening the run handle still owns the recorded
            # new directory. rmdir itself proves emptiness even if umask or
            # an open failure prevents entry; it cannot delete a nonempty tree.
            eval {
                my $absolute = _absolute_directory($self->{directory});
                _fail('startup directory identity unavailable or changed')
                    unless $self->{directory_identity} && _same_identity(
                        $self->{directory_identity}, _identity($absolute, 'directory', undef));
                rmdir($absolute) or _fail('cannot remove empty startup directory');
                $self->{directory_removed} = 1;
                1;
            } or push @error, $@;
        }
    }
    push @error, 'directory handle close failed'
        if $self->{directory_handle} && !close(delete $self->{directory_handle});
    $self->{closed} = 1;
    $self->{cleanup} = {ok => @error ? 0 : 1,
        socket_removed => $self->{socket_removed} ? 1 : 0,
        directory_removed => $self->{directory_removed} ? 1 : 0,
        diagnostic => @error ? join('; ', @error) : 'private endpoint closed'};
    return {%{$self->{cleanup}}};
}

1;
