package FSM::Composition::Plan;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

sub new ($class, %args) {
    return bless {
        lane => $args{lane},
        top_name => $args{top_name},
        ports => _clone($args{ports} || []),
        links => _clone($args{links} || []),
        resolved_links => _clone($args{resolved_links} || []),
        nets => _clone($args{nets} || []),
        instances => _clone($args{instances} || []),
        auxiliary_assignments => _clone($args{auxiliary_assignments} || []),
        shared_datapath_candidates => _clone($args{shared_datapath_candidates} || []),
        raw_spec => _clone($args{raw_spec}),
    }, $class;
}

sub lane ($self) { return $self->{lane} }
sub top_name ($self) { return $self->{top_name} }
sub ports ($self) { return _clone($self->{ports}) }
sub links ($self) { return _clone($self->{links}) }
sub resolved_links ($self) { return _clone($self->{resolved_links}) }
sub nets ($self) { return _clone($self->{nets}) }
sub instances ($self) { return _clone($self->{instances}) }
sub auxiliary_assignments ($self) { return _clone($self->{auxiliary_assignments}) }
sub shared_datapath_candidates ($self) { return _clone($self->{shared_datapath_candidates}) }
sub raw_spec ($self) { return _clone($self->{raw_spec}) }

sub _clone ($value) {
    return undef unless defined $value;

    if (ref($value) eq 'HASH') {
        return {
            map { $_ => _clone($value->{$_}) } sort keys %$value
        };
    }

    if (ref($value) eq 'ARRAY') {
        return [ map { _clone($_) } @$value ];
    }

    return $value;
}

1;
