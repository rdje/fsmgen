package NativeProxyReceiptAdmission;

use strict;
use warnings;

# Inactive admission for one later compiler-only capture. This module
# launches nothing. One fresh permit names the sealed private supervisor
# return and can be consumed once. Compiler, probe and tool-resolution
# execution remain closed.
my @ROLES = (
    {role => 'compiler', stage => 'compile_proxy', containment => 'rust_proxy_compiler_group'},
    {role => 'outer', stage => 'probe', containment => 'rust_tool_resolution_probe_group'},
    {role => 'inner', stage => 'tool_resolution', containment => 'rust_tool_resolution_probe_group'},
);
my @PRIVATE = qw(pid start_sec start_usec group_pid group_start_sec group_start_usec cleanup_identity);
my $SEALED_RETURN = 'FSM::Test::ProcessSupervisor::sealed_supervise_process';
my $permit;

sub _closed_plan {
    my ($plan) = @_;
    return 0 unless @_ == 1 && ref($plan) eq 'HASH';
    return 0 unless defined($plan->{source_revision}) && !ref($plan->{source_revision})
        && $plan->{source_revision} =~ /\A[0-9a-f]{40}\z/;
    return 0 unless defined($plan->{execution}) && $plan->{execution} eq 'closed';
    return 0 unless ref($plan->{roles}) eq 'ARRAY' && @{$plan->{roles}} == @ROLES;
    return 0 unless ref($plan->{private_fields}) eq 'ARRAY'
        && join("\0", @{$plan->{private_fields}}) eq join("\0", @PRIVATE);
    for my $index (0 .. $#ROLES) {
        my $role = $plan->{roles}[$index];
        return 0 unless ref($role) eq 'HASH';
        for my $field (qw(role stage containment)) {
            return 0 unless defined($role->{$field}) && !ref($role->{$field})
                && $role->{$field} eq $ROLES[$index]{$field};
        }
    }
    return 0 if $plan->{replay_original} || $plan->{replay_proxy} || $plan->{live_collector};
    return 1;
}

sub admitted {
    my ($plan) = @_;
    return 0 unless _closed_plan($plan);
    return 0 unless defined($plan->{permit}) && $plan->{permit} eq 'unissued';
    return 1;
}

# One fresh permit names the sealed private return and the current source
# revision. It does not launch a process. A second issue is rejected, and
# the returned token is the only value a later consume accepts.
sub issue_permit {
    my ($plan) = @_;
    return undef unless @_ == 1 && _closed_plan($plan);
    return undef unless defined($plan->{permit}) && $plan->{permit} eq 'unissued';
    return undef unless defined($plan->{sealed_return}) && !ref($plan->{sealed_return})
        && $plan->{sealed_return} eq $SEALED_RETURN;
    return undef if defined $permit;
    $permit = {
        schema => 'fsmgen.native_proxy_receipt_permit.v1',
        source_revision => $plan->{source_revision},
        sealed_return => $SEALED_RETURN,
        uses_remaining => 1,
    };
    return { %$permit };
}

sub consume_permit {
    my ($plan, $token) = @_;
    return 0 unless @_ == 2 && _closed_plan($plan) && ref($token) eq 'HASH' && defined $permit;
    return 0 unless defined($plan->{permit}) && $plan->{permit} eq 'unissued';
    return 0 unless defined($plan->{sealed_return}) && !ref($plan->{sealed_return})
        && $plan->{sealed_return} eq $SEALED_RETURN;
    return 0 unless $plan->{source_revision} eq $permit->{source_revision};
    return 0 unless defined($token->{schema}) && $token->{schema} eq $permit->{schema};
    return 0 unless defined($token->{source_revision})
        && $token->{source_revision} eq $permit->{source_revision};
    return 0 unless defined($token->{sealed_return})
        && $token->{sealed_return} eq $permit->{sealed_return};
    return 0 unless ($token->{uses_remaining} // 0) == 1;
    return 0 unless $permit->{uses_remaining} == 1;
    $permit->{uses_remaining} = 0;
    return 1;
}

sub execution_allowed {
    my ($plan) = @_;
    return 0 unless @_ == 1 && admitted($plan);
    return 0;
}

sub required_roles { return [map { {%$_} } @ROLES]; }
sub required_private_fields { return [@PRIVATE]; }
sub sealed_return_name { return $SEALED_RETURN; }

1;
