package NativeProxyReceiptAdmission;

use strict;
use warnings;

# Inactive admission for one later compiler-only capture. This module
# launches nothing and issues no permit. Execution remains a separate leaf.
my @ROLES = (
    {role => 'compiler', stage => 'compile_proxy', containment => 'rust_proxy_compiler_group'},
    {role => 'outer', stage => 'probe', containment => 'rust_tool_resolution_probe_group'},
    {role => 'inner', stage => 'tool_resolution', containment => 'rust_tool_resolution_probe_group'},
);
my @PRIVATE = qw(pid start_sec start_usec group_pid group_start_sec group_start_usec cleanup_identity);

sub admitted {
    my ($plan) = @_;
    return 0 unless @_ == 1 && ref($plan) eq 'HASH';
    return 0 unless defined($plan->{source_revision}) && !ref($plan->{source_revision})
        && $plan->{source_revision} =~ /\A[0-9a-f]{40}\z/;
    return 0 unless defined($plan->{execution}) && $plan->{execution} eq 'closed';
    return 0 unless defined($plan->{permit}) && $plan->{permit} eq 'unissued';
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

sub execution_allowed {
    my ($plan) = @_;
    return 0 unless @_ == 1 && admitted($plan);
    return 0;
}

sub required_roles { return [map { {%$_} } @ROLES]; }
sub required_private_fields { return [@PRIVATE]; }

1;
