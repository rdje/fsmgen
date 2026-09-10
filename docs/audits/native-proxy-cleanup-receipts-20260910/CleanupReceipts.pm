package NativeProxyCleanupReceipts;

use strict;
use warnings;

# Inactive, pure review of the existing T1669 cleanup fields. The caller must
# supply its compiler and outer receipts and every returned inner stage.
# Neither receipt authenticity nor completeness of the caller's transport is
# established here. A true result grants no filesystem or release authority.
sub cleanup_receipts_settled {
    return 0 unless @_ == 3;
    my ($compiler, $outer, $stages) = @_;
    return 0 unless ref($stages) eq 'ARRAY' && @$stages;
    for my $owner ($compiler, $outer, @$stages) {
        return 0 unless _settled_owner($owner);
    }
    return 1;
}

sub _settled_owner {
    my ($owner) = @_;
    return 0 unless ref($owner) eq 'HASH' && ref($owner->{cleanup}) eq 'HASH';
    my $cleanup = $owner->{cleanup};
    for my $field (qw(leader_started leader_reaped group_gone)) {
        return 0 unless defined($cleanup->{$field}) && !ref($cleanup->{$field})
            && $cleanup->{$field} =~ /\A[01]\z/;
    }
    # Match the existing scalar 0/1 contract, including string spellings.
    # Exit success is independent of cleanup: a failed process can be settled.
    return 0 unless $cleanup->{group_gone};
    return 0 if $cleanup->{leader_started} && !$cleanup->{leader_reaped};
    return 1;
}

1;
