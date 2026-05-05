package FSM::Test::DefensiveCopyAudit;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(
    contains_sentinel
    mutate_structure
);

sub mutate_structure {
    my ($value, $sentinel) = @_;
    return unless ref($value);

    if (ref($value) eq 'ARRAY') {
        push @{$value}, $sentinel;
        mutate_structure($_, $sentinel) for @{$value};
        return;
    }

    if (ref($value) eq 'HASH') {
        $value->{$sentinel} = $sentinel;
        mutate_structure($_, $sentinel) for values %{$value};
        return;
    }

    return;
}

sub contains_sentinel {
    my ($value, $sentinel) = @_;
    return 1 if defined($value) && !ref($value) && $value eq $sentinel;
    return 0 unless ref($value);

    if (ref($value) eq 'ARRAY') {
        for my $entry (@{$value}) {
            return 1 if contains_sentinel($entry, $sentinel);
        }
        return 0;
    }

    if (ref($value) eq 'HASH') {
        return 1 if exists($value->{$sentinel});
        for my $entry (values %{$value}) {
            return 1 if contains_sentinel($entry, $sentinel);
        }
        return 0;
    }

    return 0;
}

1;
