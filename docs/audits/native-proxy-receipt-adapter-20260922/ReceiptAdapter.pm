package NativeProxyReceiptAdapter;

use strict;
use warnings;
use Scalar::Util qw(refaddr);

my @ROLES = qw(compiler outer inner);

# Inactive review of owner-bound receipts. The caller supplies private
# supervisor states, not a cleanup array. A copied cleanup hash is not the
# state member and grants no authority. No process is launched or signalled.
sub receipts_bound {
    my ($states, $frontier) = @_;
    return 0 unless @_ == 2 && ref($states) eq 'ARRAY' && @$states >= 1
        && @$states <= @ROLES;
    return 0 unless _frontier($frontier) && $frontier->{closed};
    my %seen;
    for my $index (0 .. $#$states) {
        my $state = $states->[$index];
        return 0 unless ref($state) eq 'HASH';
        return 0 unless defined($state->{role}) && !ref($state->{role})
            && $state->{role} eq $ROLES[$index];
        return 0 unless _identity($state->{birth});
        return 0 unless _identity($state->{group});
        # The current supervisor calls setpgid(0, 0) and admits the child
        # only when getpgrp(0) equals its pid. Group absence is later
        # checked with kill(0, -$pid). A real finished stage therefore
        # carries one identity for both leader and group.
        return 0 unless _same_identity($state->{birth}, $state->{group});
        my $key = join ':', map { $state->{birth}{$_} } qw(pid start_sec start_usec);
        return 0 if $seen{$key}++;
        return 0 unless defined($state->{stage}) && !ref($state->{stage})
            && $state->{stage} =~ /\A[A-Za-z0-9_]{1,64}\z/;
        return 0 unless defined($state->{phase}) && !ref($state->{phase})
            && $state->{phase} eq 'finished';
        return 0 unless defined($state->{leader_reaped}) && $state->{leader_reaped} == 1;
        my $cleanup = $state->{cleanup};
        return 0 unless _cleanup($cleanup);
        # The public result copies cleanup. Only the private member counts.
        return 0 unless refaddr($cleanup) == ($state->{cleanup_identity} // -1);
        return 0 unless $cleanup->{leader_started} && $cleanup->{leader_reaped}
            && $cleanup->{group_gone};
        return 0 if exists $state->{cleanup_array};
    }
    return 1;
}

sub launch_allowed {
    my ($frontier) = @_;
    return 0 unless @_ == 1 && _frontier($frontier);
    return $frontier->{closed} ? 0 : 1;
}

sub _frontier {
    my ($frontier) = @_;
    return ref($frontier) eq 'HASH' && !ref($frontier->{closed})
        && defined($frontier->{closed}) && $frontier->{closed} =~ /\A[01]\z/;
}

sub _identity {
    my ($value) = @_;
    return 0 unless ref($value) eq 'HASH';
    for my $field (qw(pid start_sec start_usec)) {
        return 0 unless defined($value->{$field}) && !ref($value->{$field})
            && $value->{$field} =~ /\A[1-9][0-9]*\z/;
    }
    return 0 unless $value->{pid} <= 2147483647 && $value->{start_usec} < 1000000;
    return 1;
}

sub _same_identity {
    my ($left, $right) = @_;
    return $left->{pid} == $right->{pid}
        && $left->{start_sec} == $right->{start_sec}
        && $left->{start_usec} == $right->{start_usec};
}

sub _cleanup {
    my ($value) = @_;
    return 0 unless ref($value) eq 'HASH';
    for my $field (qw(leader_started leader_reaped group_gone)) {
        return 0 unless defined($value->{$field}) && !ref($value->{$field})
            && $value->{$field} =~ /\A[01]\z/;
    }
    return 1;
}

1;
