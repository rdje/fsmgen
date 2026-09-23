package FSM::Support::ProcessSupervisor::Admission;

use strict;
use warnings;
use Math::BigInt;
use Scalar::Util qw(refaddr);
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime);
use FSM::Support::ProcessSupervisor::GatedPair ();
use FSM::Support::ProcessSupervisor::Wire ();

# Private accounting only: no native resources or execution snapshots live here.
# A single creator serializes mutations (including signal handlers). Native owners
# must retain actual effects before reducing these conservative reservations.
# Reported usage is trusted owner accounting, never proof of kernel closure.
my $LIMIT = FSM::Support::ProcessSupervisor::Wire::limits();
my $COST = FSM::Support::ProcessSupervisor::GatedPair::resource_cost();
my $U64 = '18446744073709551615';
sub _error { die "private process admission: $_[0]\n" }
sub _now_ns { return sprintf('%.0f', clock_gettime(CLOCK_MONOTONIC) * 1_000_000_000) }
sub _uint { return FSM::Support::ProcessSupervisor::Wire::_uint(@_) }
sub _owner {
    my ($self) = @_;
    _error('invalid or copied ledger') unless ref($self) eq __PACKAGE__
        && defined($self->{identity}) && $self->{identity} == refaddr($self);
    _error('inherited ledger cannot be reused') unless $self->{owner_pid} == $$;
}
sub _record {
    my ($self, $grant) = @_; _owner($self);
    _error('invalid job grant') unless ref($grant) eq __PACKAGE__ . '::JobGrant';
    for my $record (values %{$self->{jobs}}) {
        return $record if refaddr($record->{grant}) == refaddr($grant);
    }
    _error('foreign, copied or retired job grant');
}
sub _replace {
    my ($self, $record, %change) = @_;
    $self->{jobs}{$record->{id}} = {%$record, %change};
    return;
}
sub _live {
    my ($self, $record, $now) = @_;
    while ($record) {
        _error('job or ancestor admission revoked') unless $record->{accepting};
        _error('original invocation deadline expired')
            if Math::BigInt->new($record->{deadline_ns})->bcmp($now) <= 0;
        $record = $record->{parent} ? $self->{jobs}{$record->{parent}} : undef;
    }
}
sub _timing {
    my ($started, $timeout, $parent, $now) = @_;
    $started = _uint($started, $U64, 0);
    $timeout = _uint($timeout, '4294967295', 1);
    my $start = Math::BigInt->new($started);
    _error('invocation starts in the future') if $start->bcmp($now) > 0;
    _error('invocation precedes its parent')
        if $parent && $start->bcmp($parent->{started_ns}) < 0;
    my $deadline = $start->copy->badd(Math::BigInt->new($timeout)->bmul(1_000_000_000));
    $deadline = Math::BigInt->new($parent->{deadline_ns})
        if $parent && $deadline->bcmp($parent->{deadline_ns}) > 0;
    _error('deadline exceeds wire range') if $deadline->bcmp($U64) > 0;
    _error('original invocation deadline expired') if $deadline->bcmp($now) <= 0;
    return (started_ns => $started, timeout_seconds => $timeout, deadline_ns => $deadline->bstr);
}
sub _new_record {
    my ($id, $parent, @timing) = @_;
    return {id => $id, parent => $parent ? $parent->{id} : 0,
        depth => $parent ? $parent->{depth} + 1 : 1, @timing,
        grant => bless({}, __PACKAGE__ . '::JobGrant'), phase => 'reserved', accepting => 1,
        children => 0, descriptors => 0,
        reserved_children => $COST->{children}, reserved_descriptors => $COST->{descriptors}};
}

sub prepare {
    my %args = @_;
    FSM::Support::ProcessSupervisor::Wire::_keys(\%args, qw(started_ns timeout_seconds));
    my @timing = _timing(@args{qw(started_ns timeout_seconds)}, undef, _now_ns());
    my $self = bless {owner_pid => $$, next_id => 2,
        jobs => {1 => _new_record(1, undef, @timing)}, external => []}, __PACKAGE__;
    $self->{identity} = refaddr($self);
    return $self;
}
sub root {
    my ($self) = @_; _owner($self);
    _error('root is retired') unless $self->{jobs}{1};
    return $self->{jobs}{1}{grant};
}
sub grants {
    my ($self) = @_; _owner($self);
    return [map { $self->{jobs}{$_}{grant} } sort { $a <=> $b } keys %{$self->{jobs}}];
}
sub describe {
    my ($self, $grant) = @_;
    my %copy = %{$self->_record($grant)};
    delete $copy{grant};
    return \%copy;
}
sub usage {
    my ($self) = @_; _owner($self);
    my %usage = (jobs => scalar(keys %{$self->{jobs}}), children => 0, descriptors => 0,
        reserved_children => 0, reserved_descriptors => 0);
    for my $record (values %{$self->{jobs}}) {
        $usage{$_} += $record->{$_} for qw(children descriptors reserved_children reserved_descriptors);
    }
    $usage{$_->{reserved} ? 'reserved_descriptors' : 'descriptors'} += $_->{count}
        for @{$self->{external}};
    $usage{charged_children} = $usage{children} + $usage{reserved_children};
    $usage{charged_descriptors} = $usage{descriptors} + $usage{reserved_descriptors};
    return \%usage;
}
sub reserve_job {
    my ($self, %args) = @_;
    FSM::Support::ProcessSupervisor::Wire::_keys(\%args, qw(parent started_ns timeout_seconds));
    my $parent = $self->_record($args{parent});
    my $now = _now_ns(); $self->_live($parent, $now);
    _error('parent is not active') unless $parent->{phase} eq 'active';
    _error('logical depth exhausted') if $parent->{depth} >= $LIMIT->{depth};
    my @timing = _timing(@args{qw(started_ns timeout_seconds)}, $parent, $now);
    my $usage = $self->usage;
    _error('job capacity exhausted') if $usage->{jobs} >= $LIMIT->{jobs};
    _error('child capacity exhausted') if $usage->{charged_children} + $COST->{children} > $LIMIT->{children};
    _error('descriptor capacity exhausted') if $usage->{charged_descriptors} + $COST->{descriptors} > $LIMIT->{descriptors};
    _error('job identity exhausted') if $self->{next_id} > 4_294_967_295;
    # An interrupted publication may skip an identity; it must never reuse one.
    my $id = $self->{next_id}++;
    my $record = _new_record($id, $parent, @timing);
    $self->{jobs}{$id} = $record;
    return $record->{grant};
}
sub _transition {
    my ($self, $grant, $from, $to) = @_;
    my $record = $self->_record($grant);
    $self->_live($record, _now_ns());
    _error("expected $from job") unless $record->{phase} eq $from;
    $self->_replace($record, phase => $to);
    return;
}
sub begin_prepare { $_[0]->_transition($_[1], 'reserved', 'preparing') }
sub begin_start { $_[0]->_transition($_[1], 'prepared', 'starting') }
sub prepared {
    my ($self, $grant, $descriptors) = @_;
    my $record = $self->_record($grant);
    _error('expected preparing job') unless $record->{phase} eq 'preparing';
    $descriptors = _uint($descriptors, "$COST->{descriptors}", 0);
    # Recording effects remains possible after expiry; begin_start rechecks it.
    $self->_replace($record, phase => 'prepared', descriptors => 0 + $descriptors,
        reserved_descriptors => 0);
    return;
}
sub activate {
    my ($self, $grant, $descriptors) = @_;
    my $record = $self->_record($grant);
    _error('expected starting job') unless $record->{phase} eq 'starting';
    $descriptors = _uint($descriptors, "$record->{descriptors}", 0);
    $self->_live($record, _now_ns());
    $self->_replace($record, phase => 'active', descriptors => 0 + $descriptors,
        children => $COST->{children}, reserved_children => 0);
    return;
}
sub cancel {
    my ($self, $grant) = @_;
    my $record = $self->_record($grant);
    my %jobs = %{$self->{jobs}};
    my %affected;
    for my $id (sort { $a <=> $b } keys %jobs) {
        next unless $id == $record->{id} || $affected{$jobs{$id}{parent}};
        $affected{$id} = 1;
        my $old = $jobs{$id};
        $jobs{$id} = {%$old, accepting => 0,
            phase => $old->{phase} eq 'result_pending' ? 'result_pending' : 'closing'};
    }
    # Revoke the subtree together, before its native owner starts cleanup.
    $self->{jobs} = \%jobs;
    return;
}
sub release_resources {
    my ($self, $grant, %args) = @_;
    FSM::Support::ProcessSupervisor::Wire::_keys(\%args, qw(children descriptors));
    my $record = $self->_record($grant);
    _error('resources may shrink only after launch or cancellation')
        unless $record->{phase} eq 'active' || $record->{phase} eq 'closing';
    for my $kind (qw(children descriptors)) {
        my $held = $record->{$kind} + $record->{"reserved_$kind"};
        $args{$kind} = 0 + _uint($args{$kind}, "$held", 0);
    }
    $self->_replace($record, %args, reserved_children => 0, reserved_descriptors => 0);
    return;
}
sub finish {
    my ($self, $grant) = @_;
    my $record = $self->_record($grant);
    _error('expected closing job') unless $record->{phase} eq 'closing';
    _error('resources remain charged')
        if grep { $record->{$_} } qw(children descriptors reserved_children reserved_descriptors);
    _error('descendant outcome remains retained')
        if grep { $_->{parent} == $record->{id} } values %{$self->{jobs}};
    $self->_replace($record, phase => 'result_pending');
    return;
}
sub retire {
    my ($self, $grant) = @_;
    my $record = $self->_record($grant);
    _error('result is not settled') unless $record->{phase} eq 'result_pending';
    _error('run descriptor reservations remain') if $record->{id} == 1 && @{$self->{external}};
    delete $self->{jobs}{$record->{id}};
    return;
}
sub reserve_descriptors {
    my ($self, $count) = @_; _owner($self);
    _error('root is retired') unless $self->{jobs}{1};
    $count = _uint($count, "$LIMIT->{descriptors}", 1);
    _error('descriptor capacity exhausted')
        if $self->usage->{charged_descriptors} + $count > $LIMIT->{descriptors};
    # Also usable for bounded cleanup transactions after admission is revoked.
    my $grant = bless {}, __PACKAGE__ . '::DescriptorGrant';
    push @{$self->{external}}, {grant => $grant, count => 0 + $count, reserved => 1};
    return $grant;
}
sub descriptor_grants {
    my ($self) = @_; _owner($self);
    return [map { $_->{grant} } @{$self->{external}}];
}
sub descriptors_prepared {
    my ($self, $grant, $count) = @_;
    $self->_descriptors($grant, $count, 1);
    return;
}
sub release_descriptors {
    my ($self, $grant, $remaining) = @_; _owner($self);
    $self->_descriptors($grant, $remaining, 0);
    return;
}
sub _descriptors {
    my ($self, $grant, $remaining, $prepared) = @_; _owner($self);
    _error('invalid descriptor grant') unless ref($grant) eq __PACKAGE__ . '::DescriptorGrant';
    my $records = $self->{external};
    for my $index (0 .. $#$records) {
        next unless refaddr($records->[$index]{grant}) == refaddr($grant);
        _error('descriptor grant already prepared') if $prepared && !$records->[$index]{reserved};
        $remaining = _uint($remaining, "$records->[$index]{count}", 0);
        if ($remaining) { $records->[$index] = {grant => $grant, count => 0 + $remaining,
            reserved => $prepared ? 0 : $records->[$index]{reserved}}; }
        else { splice @$records, $index, 1; }
        return;
    }
    _error('foreign, copied or retired descriptor grant');
}

1;
