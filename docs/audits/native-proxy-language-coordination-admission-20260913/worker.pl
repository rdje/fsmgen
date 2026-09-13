#!/usr/bin/env perl
use strict;
use warnings;

our $forbidden = 0;
BEGIN {
    *CORE::GLOBAL::fork = sub { ++$forbidden; die "unadmitted fork\n"; };
    *CORE::GLOBAL::system = sub { ++$forbidden; die "unadmitted system\n"; };
}
use FindBin;
use lib "$FindBin::Bin/../../../perl", "$FindBin::Bin/../../../t/lib",
    "$FindBin::Bin/../native-proxy-image-custody-20260910",
    "$FindBin::Bin/../native-proxy-image-coordination-20260910";
use Fcntl qw(F_GETFD F_SETFD FD_CLOEXEC);
use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use POSIX ();
use FSM::Test::RustProxyFixture ();
use Coordination;
BEGIN { *CORE::GLOBAL::exec = sub { ++$forbidden; die "unadmitted exec\n"; }; }

my $JSON = JSON::PP->new->canonical->ascii;
my $TRUE = JSON::PP::true;
my $FALSE = JSON::PP::false;

sub emit {
    my ($event, %fields) = @_;
    my $bytes = $JSON->encode({event => $event, pid => $$, %fields}) . "\n";
    die "worker event exceeds bound\n" if length($bytes) > 4096;
    my $offset = 0;
    while ($offset < length($bytes)) {
        my $written = syswrite(STDOUT, $bytes, length($bytes) - $offset, $offset);
        die "worker event write failed: $!\n" unless defined($written) && $written > 0;
        $offset += $written;
    }
}

sub command {
    my ($expected) = @_;
    my $bytes = '';
    while (length($bytes) < 32) {
        my $count = sysread(STDIN, my $byte, 1);
        die "controller command pipe failed: $!\n" unless defined($count) && $count == 1;
        $bytes .= $byte;
        next unless $byte eq "\n";
        die "unexpected controller command\n" unless $bytes eq "$expected\n";
        return;
    }
    die "controller command exceeds bound\n";
}

sub exec_probe {
    my ($handle, $identity, $sealed) = @_;
    my $flags = fcntl($handle, F_GETFD, 0);
    die "original close-on-exec seal missing\n" unless defined($flags) && ($flags & FD_CLOEXEC);
    if (!$sealed) {
        # Explicit omitted-guard countercontrol before acquiring the lock.
        fcntl($handle, F_SETFD, $flags & ~FD_CLOEXEC)
            or die "cannot select omitted-seal control: $!\n";
    }
    my $descriptor = fileno($handle);
    my $child = CORE::fork();
    die "cannot fork admitted descriptor probe: $!\n" unless defined($child);
    if ($child == 0) {
        no warnings 'exec';
        CORE::exec {$^X} $^X, "$FindBin::Bin/probe.pl", $descriptor, $identity->[0], $identity->[1];
        POSIX::_exit(126);
    }
    emit('probe_spawned', child_pid => $child, before_acquisition => $TRUE,
        sealed => $sealed ? $TRUE : $FALSE);
    my $waited = waitpid($child, 0);
    my $status = $?;
    die "wrong descriptor probe reaped\n" unless $waited == $child;
    my $code = ($status & 127) ? -($status & 127) : ($status >> 8);
    emit('probe_reaped', child_pid => $child, exit_code => $code);
    die "unexpected exec probe outcome\n" unless $code == ($sealed ? 0 : 23);
    fcntl($handle, F_SETFD, $flags) or die "cannot restore descriptor seal: $!\n";
}

sub run_case {
    my ($case, $role) = @_;
    my ($handle, $entered, $busy_count, $first_ns, $last_ns) = (undef, 0, 0, undef, undef);
    my $acquire = \&NativeProxyImageCoordination::_acquire;
    my $try_lock = \&NativeProxyImageCoordination::_try_lock;
    my $now = \&NativeProxyImageCoordination::_now;
    my $census = \&NativeProxyImageCoordination::_census;
    no warnings 'redefine';
    local *FSM::Test::RustProxyFixture::supervise_process = sub { ++$forbidden; die "unadmitted compiler\n"; };
    local *FSM::Test::ProcessSupervisor::supervise_process = sub { ++$forbidden; die "unadmitted supervisor\n"; };
    local *NativeProxyImageCoordination::_now = sub {
        my $value = $now->();
        $first_ns = int($value * 1_000_000_000) unless defined($first_ns);
        $last_ns = int($value * 1_000_000_000);
        return $value;
    };
    local *NativeProxyImageCoordination::_try_lock = sub {
        my $value = $try_lock->(@_);
        my $error = 0 + $!;
        if (!$value) {
            ++$busy_count;
            emit('busy', errno => $error) if $busy_count == 1;
        }
        $! = $error;
        return $value;
    };
    local *NativeProxyImageCoordination::_acquire = sub {
        my ($opened, $path, $identity) = @_;
        $handle = $opened;
        my $flags = fcntl($handle, F_GETFD, 0);
        die "cannot inspect descriptor seal: $!\n" unless defined($flags);
        emit('opened', descriptor => fileno($handle), device => $identity->[0], inode => $identity->[1],
            close_on_exec => ($flags & FD_CLOEXEC) ? $TRUE : $FALSE);
        command('lock');
        exec_probe($handle, $identity, $case->{sealed}) if $role eq 'inheritance';
        return $acquire->(@_);
    };
    local *NativeProxyImageCoordination::_census = sub {
        die "unexpected repeated worker census\n" if $entered;
        $entered = 1;
        emit('entered');
        if ($role eq 'holder') {
            emit('held');
            command('release');
        }
        return $census->(@_);
    };
    my $ok = eval { NativeProxyImageCoordination::inspect_store($case->{store}); 1 };
    my $error = $@;
    my $closed = defined($handle) && !defined(fileno($handle));
    emit('finished', success => $ok ? $TRUE : $FALSE, error => $ok ? undef : $error,
        entered => $entered ? $TRUE : $FALSE, busy_count => $busy_count,
        first_ns => $first_ns, last_ns => $last_ns,
        descriptor_closed => $closed ? $TRUE : $FALSE, close_error => undef,
        forbidden_process_attempts => $forbidden);
    return $closed && !$forbidden ? 0 : 24;
}

sub main {
    die "expected declared case and role\n" unless @ARGV == 2;
    my ($name, $role) = @ARGV;
    die "unknown role\n" unless $role eq 'holder' || $role eq 'waiter' || $role eq 'inheritance';
    my $read = sub {
        my ($path, $mode, $limit) = @_;
        my $source = NativeProxyImageCustody::_source($path, $mode, $limit);
        my $ok = eval { NativeProxyImageCustody::_recheck_source($source); 1 };
        my $error = $@;
        my $closed = close($source->{handle});
        die $error unless $ok;
        die "cannot close worker admission input: $!\n" unless $closed;
        return $source->{bytes};
    };
    my $raw = $read->("$FindBin::Bin/plan.json", 0644, 65536);
    my $plan = $JSON->decode($raw);
    my $permit = $JSON->decode($read->(
        FSM::Test::ProcessSupervisor::repository_root()
            . '/.artifacts/logs/native-proxy-language-coordination-20260913/execution-admission.json', 0600, 4096));
    die "worker lacks the current fixed execution permit\n"
        unless $permit->{schema} eq 'fsmgen.language_coordination_execution_admission.v1'
            && $permit->{execution_owner} eq $plan->{execution_owner}
            && $permit->{plan_sha256} eq sha256_hex($raw);
    my @selected = grep { $_->{name} eq $name } @{$plan->{cases}};
    die "case is not uniquely admitted\n" unless @selected == 1;
    my $case = $selected[0];
    if ($case->{kind} eq 'pair') {
        die "wrong declared Perl role\n" if $role eq 'inheritance' || $case->{$role} ne 'perl';
    } else {
        die "wrong inheritance role\n" unless $role eq 'inheritance' && $case->{language} eq 'perl';
    }
    die "worker lacks normal-user private process group\n" unless $< > 0 && $< == $> && getpgrp(0) == $$;
    alarm(20);
    emit('ready', case => $name, role => $role, language => 'perl', uid => 0 + $<, euid => 0 + $>,
        ppid => getppid(), pgid => getpgrp(0));
    command('admit');
    return run_case($case, $role);
}

exit main();
