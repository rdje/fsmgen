package FSM::Support::ProcessSupervisor::ReservedReceipt;

use strict;
use warnings;
use Scalar::Util qw(refaddr);
use FSM::Support::ProcessSupervisor::ReservedJob ();

# Inactive, producer-free review of one retained creator-owned stage. Neither
# serialized addresses nor a public result can supply this ownership. A true
# result grants no launch, filesystem, complete-stage-set or delivery authority.
# Historical own-group receipt review and captured sources remain unchanged.
sub receipt_bound {
    my ($job, $receipt, $expected_role, $frontier) = @_;
    return 0 unless @_ == 4
        && ref($job) eq 'FSM::Support::ProcessSupervisor::ReservedJob'
        && ref($receipt) eq 'HASH' && ref($frontier) eq 'HASH'
        && defined($frontier->{closed}) && !ref($frontier->{closed})
        && $frontier->{closed} eq '1'
        && defined($expected_role) && !ref($expected_role);
    my $basis = eval { $job->receipt_basis };
    return 0 unless $basis && ref($basis->{receipt}) eq 'HASH'
        && refaddr($receipt) == refaddr($basis->{receipt});
    my $role = FSM::Support::ProcessSupervisor::_receipt_role($basis->{stage});
    return 0 unless defined($role) && $role eq $expected_role;
    for my $field ([schema => 'fsmgen.process_supervisor.receipt_observation.v1'],
        [role => $role], [stage => $basis->{stage}], [phase => 'finished']) {
        return 0 unless defined($receipt->{$field->[0]}) && !ref($receipt->{$field->[0]})
            && $receipt->{$field->[0]} eq $field->[1];
    }
    my ($c, $r, $closed) = @{$basis}{qw(command reservation closure)};
    return 0 unless _one($basis->{capture_closed}) && _one($c->{command_reaped})
        && _one($c->{retired}) && _zero($c->{command_authority})
        && _one($r->{reaped}) && _one($r->{retired})
        && ($r->{phase} // '') eq 'finished' && _one($r->{moved})
        && _one($r->{group_ready}) && ($closed->{phase} // '') eq 'finished'
        && _one($closed->{complete}) && _one($closed->{group_gone})
        && _one($closed->{leader_reaped}) && _one($closed->{reservation_reaped})
        && !defined($closed->{failure});
    # Reaping and successful exit are distinct. A nonzero or signaled command
    # or reservation can have completely settled resources.
    return 0 unless _wait_status($c->{command_status}) && _wait_status($r->{wait_status});
    return 0 unless _identity($receipt->{birth}, $c->{command_pid}, $c->{birth_sec}, $c->{birth_usec})
        && _identity($receipt->{group}, $r->{pid}, $r->{birth_sec}, $r->{birth_usec})
        && $c->{command_pid} != $r->{pid};
    my $cleanup = $receipt->{cleanup};
    return 0 unless ref($cleanup) eq 'HASH' && ref($basis->{cleanup}) eq 'HASH'
        && refaddr($cleanup) == refaddr($basis->{cleanup})
        && defined($receipt->{cleanup_identity}) && !ref($receipt->{cleanup_identity})
        && $receipt->{cleanup_identity} eq refaddr($cleanup)
        && _one($receipt->{leader_reaped}) && _one($cleanup->{leader_started})
        && _one($cleanup->{leader_reaped}) && _one($cleanup->{group_gone})
        && defined($cleanup->{containment}) && !ref($cleanup->{containment})
        && $cleanup->{containment} eq $basis->{containment};
    return 0 if exists $receipt->{cleanup_array};
    return 1;
}

sub _one { return defined($_[0]) && !ref($_[0]) && $_[0] eq '1' }
sub _zero { return defined($_[0]) && !ref($_[0]) && $_[0] eq '0' }
sub _wait_status {
    return defined($_[0]) && !ref($_[0]) && length($_[0]) <= 5
        && $_[0] =~ /\A(?:0|[1-9][0-9]*)\z/ && $_[0] <= 65535;
}
sub _identity {
    my ($identity, $pid, $sec, $usec) = @_;
    return 0 unless ref($identity) eq 'HASH' && keys(%$identity) == 3;
    for my $field ([pid => $pid], [start_sec => $sec], [start_usec => $usec]) {
        my ($key, $value) = @$field;
        return 0 unless defined($value) && !ref($value) && $value =~ /\A(?:0|[1-9][0-9]*)\z/
            && defined($identity->{$key}) && !ref($identity->{$key})
            && $identity->{$key} eq "$value";
    }
    return $pid > 0 && $pid <= 2147483647 && $sec > 0 && $usec < 1_000_000;
}

1;
