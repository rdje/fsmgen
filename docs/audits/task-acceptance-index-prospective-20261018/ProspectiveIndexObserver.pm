package ProspectiveIndexObserver;
use strict;
use warnings;
use IndexObserver;

our $AUDIT = 'docs/audits/task-acceptance-index-prospective-20261018';
$IndexObserver::WORK = '.artifacts/task-acceptance-index-prospective-20261018';
my $paths = \&IndexObserver::paths;
my $install = \&IndexObserver::install;

sub stop_harness {
    my ($observer) = @_;
    # TAP's standard bailout also stops prove before the next test program.
    Test::More::BAIL_OUT('prospective native failure retained; no further native execution')
        if $observer->{prospective_stop};
}

sub unexpected {
    my ($result, $intentional_session) = @_;
    return 1 unless ref($result->{cleanup}) eq 'HASH'
        && $result->{cleanup}{leader_reaped} && $result->{cleanup}{group_gone}
        && !$result->{cleanup}{surviving_descendants};
    return 1 if $result->{timed_out} || $result->{output_limited} || $result->{signal};
    return 0 if $intentional_session && ($result->{exec_error} // '')
        =~ /operation=setpgid result=undef errno=1 /;
    return 1 if defined($result->{exec_error}) && length($result->{exec_error});
    return 1 if $result->{stage} eq 'index_git' && !$result->{ok};
    if ($result->{stage} eq 'index_checker') {
        # Text inspection must not change the returned scalar's copy semantics.
        my $exit_code = $result->{exit_code};
        return 1 if !defined($exit_code) || $exit_code !~ /\A[01]\z/;
    }
    return 0;
}

{
    no warnings 'redefine';
    *IndexObserver::paths = sub {
        return sort { $a cmp $b } ($paths->(), "$IndexObserver::AUDIT/verify_failure.py", map { "$AUDIT/$_" }
            qw(ProspectiveIndexObserver.pm observe.pl run.py verify.py verify_failure.py preflight.t preflight.py contract.json));
    };
    *IndexObserver::install = sub {
        my ($self) = @_;
        $install->(@_);
        my $stage = \&FSM::Test::TaskAcceptanceIndexRuntime::supervise_process;
        my $run = \&FSM::Test::TaskAcceptanceIndexRuntime::run_index_case;
        *FSM::Test::TaskAcceptanceIndexRuntime::supervise_process = sub {
            die "prospective qualification refuses later native stage\n" if $self->{prospective_stop};
            my ($result, $error);
            eval { $result = $stage->(@_); 1 } or $error = $@;
            my $errno = 0 + $!;
            if (defined $error) {
                $self->{prospective_stop} = 'supervision exception';
                die $error;
            }
            my $intentional = exists($INC{'Control.pm'})
                && defined($Control::kind) && $Control::kind eq 'session';
            $self->{prospective_stop} = 'unexpected native stage ' . $self->{stages}
                if unexpected($result, $intentional);
            $! = $errno;
            return $result;
        };
        *FSM::Test::TaskAcceptanceIndexRuntime::run_index_case = sub {
            my $result = $run->(@_);
            my $errno = 0 + $!;
            # The original adapter has now settled/retired (or explicitly
            # retained) its workspace, and IndexObserver retained the result.
            # Abort the selected test here, before it can start another case.
            die "prospective qualification stopped after retained case result: $self->{prospective_stop}\n"
                if $self->{prospective_stop};
            $! = $errno;
            return $result;
        };
    };
}
1;
