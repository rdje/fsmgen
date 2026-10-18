package BoundaryIndexObserver;
use strict;
use warnings;
use ProspectiveIndexObserver;

our $AUDIT = 'docs/audits/task-acceptance-committed-boundary-20261018';
our $TARGET = 't/2072-task-acceptance-box-boundaries.t';
$IndexObserver::WORK = '.artifacts/task-acceptance-committed-boundary-20261018';
my $paths = \&IndexObserver::paths;

# Only admission data and storage change. The qualified capture, result,
# cleanup and stop methods remain the exact loaded implementations.
{
    no warnings 'redefine';
    *IndexObserver::paths = sub {
        return sort { $a cmp $b } ($paths->(), $TARGET, map { "$AUDIT/$_" }
            qw(BoundaryIndexObserver.pm run.py verify.py preflight.t preflight.py contract.json));
    };
    *IndexObserver::selection = sub {
        die "outside committed boundary scope\n" unless @_ == 1 && defined($_[0]) && $_[0] eq $TARGET;
        return ('boundary', $TARGET, 'none', [9, 90, 9]);
    };
}
1;
