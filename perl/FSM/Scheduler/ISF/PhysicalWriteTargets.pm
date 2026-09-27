package FSM::Scheduler::ISF::PhysicalWriteTargets;

use strict;
use warnings;
use Carp qw(confess);
use FSM::Package::AggregatePathSupport;

# Private target algebra only. The caller supplies resolved declarations from
# an actual module; this module neither infers declarations nor admits writers.
sub resolve {
    my ($class, $module, $declarations, $target) = @_;
    confess "Physical write target requires a module identity and declaration map\n"
        unless _identifier($module) && ref($declarations) eq 'HASH';
    confess "Physical write target requires a scalar assignment target\n"
        unless defined($target) && !ref($target)
            && $target =~ /\A([A-Za-z_]\w*)(.*)\z/;
    my ($root, $path) = ($1, $2);
    my $declaration = $declarations->{$root};
    confess "Physical write target '$target' has no resolved declaration in '$module'\n"
        unless ref($declaration) eq 'HASH' && _width($declaration->{width});
    my $width = 0 + $declaration->{width};
    my $type = $declaration->{type_spec};
    confess "Physical write target '$target' has inconsistent resolved type width\n"
        if defined($type) && (ref($type) ne 'HASH' || !_width($type->{width})
            || $type->{width} != $width);
    my ($low, $high, $segments) = (0, $width - 1, []);
    if (length $path) {
        my $resolved = FSM::Package::AggregatePathSupport->resolve(
            root_type_spec => $type, path_text => $path);
        confess "Physical write target '$target' has unresolved aggregate path: $resolved->{code}\n"
            unless $resolved->{ok};
        my $range = FSM::Package::AggregatePathSupport->resolve_packed_range(
            root_type_spec => $type, path_segments => $resolved->{path_segments});
        confess "Physical write target '$target' has unresolved packed range: $range->{code}\n"
            unless $range->{ok};
        ($low, $high, $segments) = ($range->{low}, $range->{high}, $resolved->{path_segments});
        confess "Physical write target '$target' exceeds its resolved declaration\n"
            unless $low >= 0 && $high >= $low && $high < $width;
    }
    return {
        module => $module, root => $root, target => $target,
        root_width => $width, low => 0 + $low, high => 0 + $high,
        width => $high - $low + 1,
        path_segments => FSM::Package::AggregatePathSupport->clone_structured_value($segments),
    };
}

# Entire-root writes overlap regardless of the width inferred by the later
# public carrier parser. This contract proves no partial-range disjointness.
sub whole_root {
    my ($class, $module, $target) = @_;
    confess "Whole-root write target requires a module identity and bare signal target\n"
        unless _identifier($module) && _identifier($target);
    return {module => $module, root => $target, target => $target, coverage => 'whole_root'};
}

sub overlaps {
    my ($class, $left, $right) = @_;
    my @coverage = map {_checked_target($_)} ($left, $right);
    return 0 unless $left->{module} eq $right->{module} && $left->{root} eq $right->{root};
    return 1 if grep {$_ eq 'whole_root'} @coverage;
    confess "Physical write target overlap has inconsistent root widths\n"
        unless $left->{root_width} == $right->{root_width};
    return $left->{low} <= $right->{high} && $right->{low} <= $left->{high} ? 1 : 0;
}

sub _checked_target {
    my ($target) = @_;
    if (ref($target) eq 'HASH' && exists $target->{coverage}) {
        confess "Physical write target has a malformed whole-root contract\n"
            unless defined($target->{coverage}) && !ref($target->{coverage})
                && $target->{coverage} eq 'whole_root'
                && _identifier($target->{module}) && _identifier($target->{root})
                && _identifier($target->{target}) && $target->{target} eq $target->{root}
                && keys(%$target) == 4;
        return 'whole_root';
    }
    _checked_range($target);
    return 'packed_range';
}

sub _checked_range {
    my ($range) = @_;
    confess "Physical write target overlap requires a resolved packed range\n"
        unless ref($range) eq 'HASH' && _identifier($range->{module}) && _identifier($range->{root})
            && _width($range->{root_width}) && _width($range->{width})
            && _offset($range->{low}) && _offset($range->{high})
            && $range->{low} <= $range->{high} && $range->{high} < $range->{root_width}
            && $range->{width} == $range->{high} - $range->{low} + 1;
}
sub _identifier {defined($_[0]) && !ref($_[0]) && $_[0] =~ /\A[A-Za-z_]\w*\z/}
sub _width {defined($_[0]) && !ref($_[0]) && $_[0] =~ /\A[1-9][0-9]*\z/}
sub _offset {defined($_[0]) && !ref($_[0]) && $_[0] =~ /\A(?:0|[1-9][0-9]*)\z/}

1;
