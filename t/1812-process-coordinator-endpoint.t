#!/usr/bin/env perl
use strict;
use warnings;
use Config;
use Cwd qw(getcwd);
use Digest::SHA qw(sha256_hex);
use Errno qw(EACCES);
use Fcntl qw(:mode FD_CLOEXEC F_GETFD F_GETFL O_NONBLOCK);
use File::Spec;
use IO::Select;
use POSIX qw(SIG_BLOCK SIG_SETMASK WNOHANG _exit);
use Socket qw(AF_UNIX SOCK_STREAM sockaddr_un);
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC sleep);
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../perl", "$FindBin::Bin/lib";
use FSM::Test::ProjectDataLocality;
use FSM::ProjectDataLocality qw(create_project_tempdir repository_root);
use FSM::Support::ProcessSupervisor::Wire ();
use FSM::Support::ProcessSupervisor::Endpoint ();

my $endpoint = 'FSM::Support::ProcessSupervisor::Endpoint';
my $repo = repository_root();
my $workspace = create_project_tempdir(purpose => 'coordinator-endpoint-tests');
my @runs;
END {
    local $?;
    $_->close for grep { !$_->{closed} && $_->{owner_pid} == $$ } @runs;
}

sub create_run {
    my $run = FSM::Support::ProcessSupervisor::Endpoint::create_run();
    push @runs, $run;
    return $run;
}

sub context_record {
    return FSM::Support::ProcessSupervisor::Wire::decode_context($_[0]->context);
}

sub path_of {
    return File::Spec->catdir($repo, split m{/}, context_record($_[0])->{directory});
}

sub error_from {
    my ($operation) = @_;
    local $@;
    eval { $operation->(); 1 };
    return $@;
}

sub environment_digest {
    return sha256_hex(join('', map {
        length($_) . ':' . $_ . length($ENV{$_}) . ':' . $ENV{$_}
    } sort keys %ENV));
}

sub signal_mask {
    my $current = POSIX::SigSet->new;
    POSIX::sigprocmask(SIG_BLOCK, POSIX::SigSet->new, $current)
        or die 'cannot observe signal mask';
    return join(',', map { $current->ismember($_) ? $_ : () }
        grep { $_ > 0 } split /\s+/, $Config{sig_num});
}

sub raw_accept {
    my ($listener) = @_;
    IO::Select->new($listener)->can_read(2) or die 'raw accept deadline';
    accept(my $peer, $listener) or die 'raw accept failed';
    return $peer;
}

sub raw_read {
    my ($handle) = @_;
    IO::Select->new($handle)->can_read(2) or die 'raw read deadline';
    my $n = sysread($handle, my $bytes, 64);
    die 'raw read failed' unless defined($n) && $n;
    return $bytes;
}

sub remove_fixture {
    my ($path, $identity) = @_;
    my @current = lstat($path);
    die 'fixture directory identity changed' unless @current
        && $current[0] == $identity->[0] && $current[1] == $identity->[1];
    # This helper handles only the exact socket/extra names deliberately made
    # by the test. rmdir refuses any unrecorded residue; no recursive deletion.
    unlink "$path/s" if -e "$path/s" || -l "$path/s";
    unlink "$path/extra" if -e "$path/extra";
    rmdir($path) or die 'cannot remove exact endpoint fixture';
}

subtest 'kernel peers connect in a long repository path with exact caller context' => sub {
    my $environment = environment_digest();
    my $mask_before = signal_mask();
    my $mask = POSIX::SigSet->new(POSIX::SIGUSR1());
    my $old = POSIX::SigSet->new;
    POSIX::sigprocmask(SIG_BLOCK, $mask, $old) or die 'cannot set test mask';
    my $selected_mask = signal_mask();
    my $old_umask = umask(0077);
    my $cwd = getcwd();
    my $run = create_run();
    my $path = path_of($run);
    my @directory = lstat $path;
    my @socket = lstat "$path/s";
    ok(S_ISDIR($directory[2]) && ($directory[2] & 07777) == 0700,
        'kernel directory mode is private');
    ok(S_ISSOCK($socket[2]) && ($socket[2] & 07777) == 0600,
        'kernel socket mode and type are exact');
    is($directory[0], (stat $repo)[0], 'endpoint is on the repository volume');
    is($directory[4], $>, 'endpoint belongs to the caller');
    ok(length("$path/s") > 108, 'actual full socket pathname exceeds Unix address capacity');
    socket(my $bad, AF_UNIX, SOCK_STREAM, 0) or die 'raw socket failed';
    my ($absolute_ok, $absolute_error);
    {
        local $SIG{__WARN__} = sub { $absolute_error = 'address rejected' };
        $absolute_error = error_from(sub { $absolute_ok = connect($bad, sockaddr_un("$path/s")); });
    }
    ok(!$absolute_ok, 'independent absolute-address counterexample cannot connect');
    close $bad;

    # Independent peer builds no module context and uses no endpoint helper.
    # Its successful exchange proves the listener is in the actual long path.
    open(my $saved, '<', '.') or die 'raw save cwd failed';
    chdir $path or die 'raw enter long directory failed';
    socket(my $raw_client, AF_UNIX, SOCK_STREAM, 0) or die 'raw client failed';
    connect($raw_client, sockaddr_un('s')) or die 'raw local connect failed';
    chdir $saved or die 'raw restore cwd failed';
    close $saved;
    my $peer = raw_accept($run->listener);
    syswrite($raw_client, "raw\0\xff") == 5 or die 'raw write failed';
    is(raw_read($peer), "raw\0\xff", 'kernel peer reaches the expected listener with exact bytes');
    close $peer;
    close $raw_client;

    my $client = FSM::Support::ProcessSupervisor::Endpoint::connect_context($run->context);
    IO::Select->new($client->handle)->can_write(2) or die 'client connection deadline';
    ok($client->connection_ready, 'nonblocking connection actually completes');
    $peer = raw_accept($run->listener);
    syswrite($peer, "reply\xff") == 6 or die 'peer write failed';
    is(raw_read($client->handle), "reply\xff", 'module client interoperates with raw peer');
    for my $handle ($run->listener, $client->handle, $run->{directory_handle}) {
        ok(fcntl($handle, F_GETFD, 0) & FD_CLOEXEC, 'every retained endpoint descriptor is close-on-exec');
    }
    for my $handle ($run->listener, $client->handle) {
        ok(fcntl($handle, F_GETFL, 0) & O_NONBLOCK, 'socket I/O is nonblocking');
    }
    close $peer;
    ok($client->close->{ok}, 'client closes without deleting server files');
    ok(-S "$path/s", 'server socket survives client closure');
    my $stale = $run->context;
    my $closed = $run->close;
    ok($closed->{ok} && $closed->{socket_removed} && $closed->{directory_removed},
        'owned endpoint identities close completely');
    ok(!-e $path, 'independent filesystem census finds no owned endpoint residue');
    is_deeply($run->close, $closed, 'closure is terminal and idempotent');
    ok(length(error_from(sub { FSM::Support::ProcessSupervisor::Endpoint::connect_context($stale) })),
        'stale context cannot connect or recreate its endpoint');
    is(getcwd(), $cwd, 'caller cwd remains exact');
    is(signal_mask(), $selected_mask, 'selected signal mask remains exact');
    is(umask(), 0077, 'caller umask remains exact');
    is(environment_digest(), $environment, 'caller environment remains exact without logging its values');
    umask($old_umask);
    POSIX::sigprocmask(SIG_SETMASK, $old) or die 'cannot restore test mask';
    is(signal_mask(), $mask_before, 'test restores its own signal selection');
};

subtest 'authority comes from distinct complete random reads without path disclosure' => sub {
    my $run = create_run();
    my $context = context_record($run);
    is(length($context->{run}), 16, 'run identity has the selected byte width');
    is(length($context->{token}), 32, 'root authority has the selected byte width');
    my $job = FSM::Support::ProcessSupervisor::Endpoint::new_job_token();
    ok(length($job) == 32 && $job ne $context->{token}, 'new job receives independent authority');
    ok(index($context->{directory}, unpack('H*', $context->{token})) < 0
        && index($context->{directory}, unpack('H*', $context->{run})) < 0,
        'filesystem name discloses neither protocol authority value');
    for my $bad (undef, '', '1:partial', '2:unknown') {
        ok(length(error_from(sub { FSM::Support::ProcessSupervisor::Endpoint::connect_context($bad) })),
            'invalid inherited context fails without outer-run fallback');
    }
    ok(length(error_from(sub { FSM::Support::ProcessSupervisor::Endpoint::create_run(root => $workspace) })),
        'caller cannot replace repository root');
    ok($run->close->{ok}, 'authority fixture closes');
};

subtest 'restrictive caller umask is preserved while owned modes remain exact' => sub {
    my $old = umask(0777);
    my $run;
    my $error = error_from(sub { $run = create_run(); });
    my $actual = umask();
    umask($old);
    die $error if length $error;
    is($actual, 0777, 'creation never replaces the caller umask');
    my $path = path_of($run);
    is((lstat $path)[2] & 07777, 0700, 'owned run still receives exact private mode');
    is((lstat "$path/s")[2] & 07777, 0600, 'owned socket still receives exact private mode');
    ok($run->close->{ok}, 'restrictive-umask fixture closes');
};

subtest 'foreign identity and symlink ancestry fail before connection' => sub {
    my $run = create_run();
    my $path = path_of($run);
    my $context = $run->context;
    for my $field (0, 4) {
        my $native = $endpoint->can('_lstat');
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::Endpoint::_lstat = sub {
            my @stat = $native->(@_);
            $stat[$field]++ if @stat && $_[0] eq $path;
            return @stat;
        };
        like(error_from(sub { FSM::Support::ProcessSupervisor::Endpoint::connect_context($context) }),
            qr/foreign owner or device/, 'model-only foreign identity is rejected without off-volume data or chown');
    }
    chmod(0750, $path) == 1 or die 'cannot set hostile directory mode';
    like(error_from(sub { FSM::Support::ProcessSupervisor::Endpoint::connect_context($context) }),
        qr/permissions/, 'real non-private directory is rejected');
    chmod(0700, $path) == 1 or die 'cannot restore directory mode';
    rename($path, "$path.saved") or die 'cannot move owned directory';
    symlink("$path.saved", $path) or die 'cannot plant directory symlink';
    ok(length(error_from(sub { FSM::Support::ProcessSupervisor::Endpoint::connect_context($context) })),
        'real symlink ancestry is rejected');
    unlink($path) or die 'cannot remove exact test symlink';
    rename("$path.saved", $path) or die 'cannot restore owned directory';
    ok($run->close->{ok}, 'restored exact identity closes');
};

subtest 'nondefault child reaping rejects a run before creating endpoint files' => sub {
    my @before = sort glob "$repo/.artifacts/tmp/process-coordinator/*";
    for my $handler ('IGNORE', sub {}) {
        local $SIG{CHLD} = $handler;
        like(error_from(sub { create_run() }), qr/default child-reaping disposition/,
            'ignored or competing handler cannot establish a run');
    }
    my $old = POSIX::SigAction->new;
    my $auto_reap = POSIX::SigAction->new('DEFAULT', POSIX::SigSet->new, POSIX::SA_NOCLDWAIT());
    POSIX::sigaction(POSIX::SIGCHLD(), $auto_reap, $old) or die 'cannot set auto-reap control';
    my $error = error_from(sub { create_run() });
    POSIX::sigaction(POSIX::SIGCHLD(), $old) or die 'cannot restore child signal action';
    like($error, qr/default child-reaping disposition/, 'native auto-reaping flag is rejected too');
    is_deeply([sort glob "$repo/.artifacts/tmp/process-coordinator/*"], \@before,
        'failed admission leaves no filesystem output');
};

subtest 'cleanup preserves unexpected names and replacement identities' => sub {
    for my $fault (qw(extra socket directory)) {
        my $run = create_run();
        my $path = path_of($run);
        my @identity = lstat $path;
        if ($fault eq 'directory') {
            rename($path, "$path.saved") or die 'cannot move original directory';
            mkdir($path, 0700) or die 'cannot create replacement directory';
        }
        else {
            unlink "$path/s" or die 'cannot remove test socket name' if $fault eq 'socket';
            open(my $file, '>', "$path/" . ($fault eq 'extra' ? 'extra' : 's'))
                or die 'cannot create hostile entry';
            print {$file} 'test-owned replacement';
            close $file;
        }
        my $closed = $run->close;
        ok(!$closed->{ok}, 'changed endpoint cannot report successful cleanup');
        ok(-d $path, 'cleanup preserves unexpected directory state');
        if ($fault eq 'directory') {
            ok(-S "$path.saved/s", 'original moved socket is preserved too');
            rmdir($path) or die 'cannot remove empty test replacement';
            rename("$path.saved", $path) or die 'cannot restore original fixture';
        }
        else { ok(-e "$path/" . ($fault eq 'extra' ? 'extra' : 's'), 'unexpected entry survives'); }
        remove_fixture($path, \@identity);
        ok(!-e $path, 'exact test-owned residue is removed after inspection');
    }
};

subtest 'cwd restoration uses a handle even when the original path is renamed' => sub {
    my $caller = "$workspace/caller";
    mkdir($caller, 0700) or die 'cannot create caller fixture';
    chdir($caller) or die 'cannot enter caller fixture';
    my @before = stat '.';
    my $bind = $endpoint->can('_bind_socket');
    my $run;
    {
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::Endpoint::_bind_socket = sub {
            rename($caller, "$caller.moved") or die 'cannot rename caller fixture';
            return $bind->(@_);
        };
        $run = create_run();
    }
    my @after = stat '.';
    is_deeply([@after[0, 1]], [@before[0, 1]], 'kernel cwd identity survives original-path loss');
    is(getcwd(), "$caller.moved", 'restoration reaches the renamed caller directory');
    ok($run->close->{ok}, 'endpoint cleanup also preserves renamed cwd');
    chdir($repo) or die 'cannot leave caller fixture';
};

subtest 'bind and reported restoration failures preserve context and own partial cleanup' => sub {
    my $cwd = getcwd();
    my $mask = signal_mask();
    my $environment = environment_digest();
    my @before = sort glob "$repo/.artifacts/tmp/process-coordinator/*";
    {
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::Endpoint::_bind_socket = sub { $! = EACCES; return; };
        like(error_from(sub { create_run() }), qr/cannot bind/, 'bind failure is retained');
    }
    my $restore = $endpoint->can('_restore_cwd');
    {
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::Endpoint::_restore_cwd = sub {
            $restore->(@_) or die 'native restoration failed';
            return; # Reported failure control restores the test process first.
        };
        like(error_from(sub { create_run() }), qr/fatal caller directory restoration/,
            'a false restoration result cannot become success');
    }
    is_deeply([sort glob "$repo/.artifacts/tmp/process-coordinator/*"], \@before,
        'independent root census finds no partial-start endpoint residue');
    is(getcwd(), $cwd, 'cwd remains exact after rejected operations');
    is(signal_mask(), $mask, 'signal mask remains exact after rejected operations');
    is(environment_digest(), $environment, 'environment remains exact after rejected operations');
};

subtest 'directory replacement during bind cannot publish a valid endpoint' => sub {
    my ($path, @identity, $run);
    my $bind = $endpoint->can('_bind_socket');
    my $error;
    {
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::Endpoint::_bind_socket = sub {
            $path = getcwd();
            @identity = lstat $path;
            rename($path, "$path.saved") or die 'cannot move bind directory';
            mkdir($path, 0700) or die 'cannot create bind replacement';
            return $bind->(@_);
        };
        $error = error_from(sub { $run = create_run(); });
    }
    like($error, qr/directory identity changed/, 'replacement cannot publish the wrong context');
    ok(-d $path && -S "$path.saved/s", 'both replacement and original are preserved for inspection');
    rmdir($path) or die 'cannot remove empty bind replacement';
    rename("$path.saved", $path) or die 'cannot restore bind fixture';
    if ($run) { ok($run->close->{ok}, 'unfixed-control endpoint still closes after restoration'); }
    else { remove_fixture($path, \@identity); }
    ok(!-e $path, 'exact bind fixture residue is removed');
};

subtest 'connection replacement and an existing generated name cannot be adopted' => sub {
    my $run = create_run();
    my $path = path_of($run);
    my $context = $run->context;
    my $connect = $endpoint->can('_connect_socket');
    my $error;
    {
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::Endpoint::_connect_socket = sub {
            my $result = $connect->(@_);
            rename($path, "$path.saved") or die 'cannot move connect directory';
            mkdir($path, 0700) or die 'cannot create connect replacement';
            return $result;
        };
        $error = error_from(sub { FSM::Support::ProcessSupervisor::Endpoint::connect_context($context) });
    }
    like($error, qr/directory identity changed/, 'connection cannot publish a replaced directory');
    rmdir($path) or die 'cannot remove exact empty connect replacement';
    rename("$path.saved", $path) or die 'cannot restore connect fixture';
    my $random = $endpoint->can('_random_bytes');
    my $draws = 0;
    my ($directory_hex) = $path =~ /run_([0-9a-f]+)\z/;
    {
        no warnings 'redefine';
        local *FSM::Support::ProcessSupervisor::Endpoint::_random_bytes = sub {
            return pack('H*', $directory_hex) if ++$draws == 3;
            return $random->(@_);
        };
        like(error_from(sub { create_run() }), qr/exclusively create/,
            'a generated-name collision fails instead of reclaiming an existing run');
    }
    ok(-S "$path/s", 'existing socket remains intact');
    ok($run->close->{ok}, 'original run still owns final cleanup');
};

subtest 'actual forked copies close only inherited descriptors' => sub {
    my $run = create_run();
    my $path = path_of($run);
    pipe(my $reader, my $writer) or die 'cannot create test pipe';
    my $pid = fork();
    die 'cannot fork endpoint oracle' unless defined $pid;
    if (!$pid) {
        close $reader;
        my $refused = length(error_from(sub { $run->context }))
            && length(error_from(sub { $run->close }));
        my $listener = $run->{listener};
        $run->discard_inherited;
        my $closed = !defined fileno($listener);
        syswrite($writer, $refused && $closed ? 'ok' : 'bad');
        close $writer;
        _exit(0);
    }
    close $writer;
    is(raw_read($reader), 'ok', 'independent child rejects cached authority and discards its descriptors');
    close $reader;
    my $deadline = clock_gettime(CLOCK_MONOTONIC) + 2;
    my $waited;
    while (($waited = waitpid($pid, WNOHANG)) == 0 && clock_gettime(CLOCK_MONOTONIC) < $deadline) {
        sleep(0.01);
    }
    my $status = $?;
    is($waited, $pid, 'exact oracle child is reaped without an unbounded wait');
    is($status, 0, 'forked oracle preserves native success');
    ok(-S "$path/s", 'child did not remove creator endpoint');
    ok($run->close->{ok}, 'creator retains cleanup authority');
};

done_testing();
