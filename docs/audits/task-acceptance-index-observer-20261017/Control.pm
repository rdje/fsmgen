package Control;
use strict;
use warnings;
use Errno qw(EPERM EIO);
use POSIX ();
use Storable qw(dclone);
use Scalar::Util qw(refaddr);
use JSON::PP ();
use IndexObserver;

our ($kind, $calls, $queries, $writes, @checks);
my %calls_by_pid;

sub before_install {
    my ($directory, $scenario) = @_;
    my $native = \&FSM::Support::ProcessSupervisor::setpgid;
    my $query = \&FailureWitness::_query_context;
    my $write = \&FailureWitness::_write;
    my $retain = \&IndexObserver::retain;
    no warnings 'redefine';
    *FSM::Support::ProcessSupervisor::setpgid = sub {
        my @args = @_;
        # Only this deliberate rejection control skips parent race closure.
        # The genuine selected tests never load this module.
        return 0 if $kind eq 'session' && $args[0] != 0;
        $calls = ++$calls_by_pid{$$};
        die "intentional control setsid failed\n" if $kind eq 'session'
            && $args[0] == 0 && POSIX::setsid() != $$;
        my $result = $native->(@args);
        $! = EPERM if $kind eq 'stale' && $args[0] == 0;
        return $result;
    };
    *FailureWitness::_query_context = sub {
        ++$queries;
        die "modeled query gap\n" if $scenario eq 'query_gap';
        return $query->(@_);
    };
    *FailureWitness::_write = sub {
        ++$writes;
        die "modeled write gap\n" if $scenario eq 'write_gap';
        $write->(@_);
        $! = EIO if $scenario eq 'diagnostic_errno';
    };
    *IndexObserver::retain = sub {
        $retain->(@_);
        $! = EIO if $scenario eq 'diagnostic_errno';
    };
    for my $method (qw(supervise_process run_index_case)) {
        no strict 'refs';
        my $original = \&{"FSM::Test::TaskAcceptanceIndexRuntime::$method"};
        *{"FSM::Test::TaskAcceptanceIndexRuntime::$method"} = sub {
            my $args = dclone(\@_);
            my $result = $original->(@_);
            my $errno = 0 + $!;
            push @checks, {method => $method, arguments => $args, result => $result,
                before => dclone($result), errno => $errno};
            $! = $errno;
            return $result;
        };
    }
    IndexObserver::save("$directory/stage_a.json", "intentional retention collision\n")
        if $scenario eq 'retention_gap';
}

sub after_install {
    my ($directory) = @_;
    my $observed = \&FSM::Support::ProcessSupervisor::setpgid;
    no warnings 'redefine';
    *FSM::Support::ProcessSupervisor::setpgid = sub {
        my @arguments = @_;
        my $result = $observed->(@arguments);
        my $errno = 0 + $!;
        if ($arguments[0] == 0) {
            IndexObserver::save("$directory/$kind-$$.json", IndexObserver::encode({pid => $$,
                result => $result, errno => $errno, calls => $calls, queries => $queries, writes => $writes}));
        }
        $! = $errno;
        return $result;
    };
    for my $method (qw(supervise_process run_index_case)) {
        no strict 'refs';
        my $observed_method = \&{"FSM::Test::TaskAcceptanceIndexRuntime::$method"};
        *{"FSM::Test::TaskAcceptanceIndexRuntime::$method"} = sub {
            my $args = dclone(\@_);
            my $result = $observed_method->(@_);
            my $errno = 0 + $!;
            my ($reference) = reverse grep {$_->{method} eq $method} @checks;
            die "observer changed original arguments\n" unless IndexObserver::encode($args)
                eq IndexObserver::encode($reference->{arguments});
            die "observer changed result identity\n" unless refaddr($result) == refaddr($reference->{result});
            die "observer changed result fields\n" unless IndexObserver::encode($result)
                eq IndexObserver::encode($reference->{before});
            die "observer changed original errno\n" unless $errno == $reference->{errno};
            $reference->{invariant} = 1;
            $! = $errno;
            return $result;
        };
    }
}
1;
