package ControlFixture;
use strict;
use warnings;
use Errno qw(EPERM EIO);
use Fcntl qw(O_WRONLY O_CREAT O_EXCL);
use JSON::PP;
use POSIX ();
use Storable qw(dclone);
our ($kind, $calls, $queries, $writes, $before, $reference, $arguments, $errno);
$kind = 'ordinary';
my $json = JSON::PP->new->canonical;
my $native = \&FSM::Support::ProcessSupervisor::setpgid;
my $query = \&FailureWitness::_query_context;
my $write = \&FailureWitness::_write;
my $save = \&StageObserver::_save;
no warnings 'redefine';
*FSM::Support::ProcessSupervisor::setpgid = sub {
    my @args = @_;
    # This exception belongs only to the deliberate session-leader control.
    # Normal parent race closure and every genuine priority stage are unchanged.
    return 0 if $kind eq 'session' && $args[0] != 0;
    ++$calls;
    if ($args[0] == 0) {
        die "control setsid failed\n" if $kind eq 'session' && POSIX::setsid() != $$;
        $! = EPERM if $kind eq 'stale';
    }
    return $native->(@args);
};
*FailureWitness::_query_context = sub {
    ++$queries;
    die "modeled query failure\n" if $main::observer_scenario eq 'query_gap';
    return $query->(@_);
};
*FailureWitness::_write = sub {
    ++$writes;
    if ($main::observer_scenario eq 'capture_gap') { $! = EIO; die "modeled capture failure\n" }
    $write->(@_);
    $! = EIO if $main::observer_scenario eq 'diagnostic_errno';
};
*StageObserver::_save = sub {
    $save->(@_);
    $! = EIO if $main::observer_scenario eq 'diagnostic_errno';
};
for my $method (qw(run_verilator_compile run_generated_binary)) {
    no strict 'refs';
    my $original = \&{"FSM::Test::VerilatorRuntime::$method"};
    *{"FSM::Test::VerilatorRuntime::$method"} = sub {
        $arguments = dclone(\@_);
        my $result = $original->(@_);
        $errno = 0 + $!;
        $reference = $result;
        $before = dclone($result);
        $! = $errno;
        return $result;
    };
}

sub after_install {
    my $observed = \&FSM::Support::ProcessSupervisor::setpgid;
    *FSM::Support::ProcessSupervisor::setpgid = sub {
        my @args = @_;
        my $result = $observed->(@args);
        my $error = 0 + $!;
        if ($args[0] == 0) {
            my $data = $json->encode({pid => $$, ppid => getppid(), kind => $kind,
                pgid => CORE::getpgrp(0), result => $result, errno => $error,
                calls => $calls, queries => $queries, writes => $writes}) . "\n";
            die "control relay envelope\n" if length($data) > 4096;
            sysopen my $fh, "$main::observer_work/$kind-child.json", O_WRONLY | O_CREAT | O_EXCL, 0600 or die $!;
            my $size = syswrite($fh, $data);
            die "control relay write\n" unless defined($size) && $size == length($data);
            close $fh or die $!;
        }
        $! = $error;
        return $result;
    };
}
1;
