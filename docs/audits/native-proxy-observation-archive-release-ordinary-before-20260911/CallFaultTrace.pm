package NativeProxyReleaseCallFaultTrace;

use strict;
use warnings;
use Scalar::Util qw(refaddr);
use File::Spec;
use JSON::PP ();
use ReleaseTrace;

our ($ACTIVE, $CALLS, $STACK, $FLOW, $SELECTED, $HITS);
our (%ORDINALS, %SEALED);
my $ROOT = FSM::Test::ProcessSupervisor::repository_root();
my $JSON = JSON::PP->new->canonical->ascii;

sub _depth {
    my $depth = 0;
    ++$depth while defined(caller($depth));
    die "call-fault observation stack exceeded its ceiling\n" if $depth > 128;
    return $depth;
}

sub _flush {
    my ($depth, $continuation) = @_;
    while (@$STACK && $STACK->[-1]{tail} && $STACK->[-1]{depth} >= $depth) {
        my $frame = pop @$STACK;
        $frame->{completion} = 'caller_continuation';
        $frame->{continuation} = $continuation;
        # This is the same physical continuation as the next before event.
        # It has no separate after event or independently injectable location.
    }
}

sub _boundary {
    my ($frame, $phase) = @_;
    my ($saved_errno, $saved_eval, $saved_status) = (0 + $!, $@, $?);
    push @{$NativeProxyReleaseTrace::ROW->{events}}, "call:$frame->{id}:$phase";
    if (defined($SELECTED) && $frame->{name} eq $SELECTED->{symbol}
            && $frame->{occurrence} == $SELECTED->{occurrence} && $phase eq $SELECTED->{phase}) {
        die "fault resolved to another current call\n" unless $frame->{id} == $SELECTED->{call_id};
        die "fault target repeated\n" if $HITS++;
        die "injected release call: $SELECTED->{address}\n";
    }
    ($!, $@, $?) = ($saved_errno, $saved_eval, $saved_status);
}

sub _enter {
    my ($entry, $caller, $arguments) = @_;
    my ($saved_errno, $saved_eval, $saved_status) = (0 + $!, $@, $?);
    my $depth = _depth(); _flush($depth, $entry->{name});
    my $ordinal = $ORDINALS{$entry->{name}} // 0; $ORDINALS{$entry->{name}} = $ordinal + 1;
    my $frame = {id => scalar(@$CALLS), name => $entry->{name}, occurrence => $ordinal,
        caller => $caller, parent => @$STACK ? $STACK->[-1]{id} : undef,
        depth => $depth, tail => $SEALED{$entry->{name}} ? 1 : 0};
    if ($entry->{name} eq 'NativeProxyImageCustody::_recheck_source') {
        my $source = $arguments->[0];
        my $handle = $NativeProxyReleaseTrace::HANDLES{refaddr($source->{handle})};
        die "fault recheck has no observed source\n" unless $handle;
        @$frame{qw(path source_handle)} = @$handle{qw(path label)};
    } elsif ($entry->{name} eq 'NativeProxyImageCustody::_source') {
        $frame->{path} = File::Spec->abs2rel($arguments->[0], $ROOT);
        @$frame{qw(mode limit)} = @$arguments[1,2];
    } elsif ($entry->{name} eq 'NativeProxyImageCustody::_directory'
             || $entry->{name} eq 'NativeProxyImageCustody::_members'
             || $entry->{name} eq 'NativeProxyImageCoordination::_names') {
        $frame->{path} = File::Spec->abs2rel($arguments->[0], $ROOT);
    } elsif ($entry->{name} eq 'NativeProxyReferenceCensus::_image') {
        $frame->{image_key} = $arguments->[1];
    } elsif ($entry->{name} eq 'NativeProxyReferenceCensus::_inspect_locked'
             && ref($arguments->[1]) eq 'HASH' && ref($arguments->[1]{references}) eq 'ARRAY') {
        $frame->{reference_names} = [@{$arguments->[1]{references}}];
    } elsif ($entry->{name} eq 'NativeProxyObservationRelease::_assert_absent') {
        $frame->{phase} = $arguments->[1];
    } elsif ($entry->{name} eq 'NativeProxyPrivateWorkspace::_absent') {
        $frame->{path} = $arguments->[0];
    }
    if (defined($FLOW)) {
        my $expected = $FLOW->[$frame->{id}];
        die "observed call exceeds prospective flow\n" unless $expected;
        my %required = %$expected; delete $required{opens};
        my %actual = map { $_ => $frame->{$_} } keys %required;
        die "observed call differs from prospective current-input flow\n"
            unless $JSON->encode(\%actual) eq $JSON->encode(\%required);
    }
    push @$CALLS, $frame; push @$STACK, $frame;
    _boundary($frame, 'before');
    ($!, $@, $?) = ($saved_errno, $saved_eval, $saved_status);
    return $frame;
}

sub _leave {
    my ($frame) = @_;
    my ($saved_errno, $saved_eval, $saved_status) = (0 + $!, $@, $?);
    _flush(_depth(), 'return:'.$frame->{name});
    die "return differs from active observed call\n" unless @$STACK && pop(@$STACK) == $frame;
    $frame->{completion} = 'direct_return';
    _boundary($frame, 'after');
    ($!, $@, $?) = ($saved_errno, $saved_eval, $saved_status);
}

sub _wrapper {
    my ($entry, $original) = @_;
    if ($SEALED{$entry->{name}}) {
        return sub {
            goto &$original unless $ACTIVE;
            _enter($entry, scalar(caller), \@_);
            goto &$original;
        };
    }
    return sub {
        goto &$original unless $ACTIVE;
        my $want = wantarray; my $frame = _enter($entry, scalar(caller), \@_);
        my (@values, $value);
        # No observer eval catches and reclassifies the original exception.
        # A fault leaves its interrupted ancestor frames as prefix evidence;
        # only actual normal returns reach _leave.
        if (!defined($want)) { $original->(@_); }
        elsif ($want) { @values = $original->(@_); }
        else { $value = $original->(@_); }
        _leave($frame);
        return $want ? @values : $value;
    };
}

sub _installed {
    my ($entries, $index, $action) = @_;
    return $action->() if $index == @$entries;
    my $entry = $entries->[$index];
    no strict 'refs'; no warnings 'redefine';
    my $original = \&{$entry->{name}};
    local *{$entry->{name}} = _wrapper($entry, $original);
    return _installed($entries, $index + 1, $action);
}

sub observe {
    my ($context, $arguments, $entries, $sealed, $flow, $selected) = @_;
    die "nested release call-fault observation\n" if $ACTIVE;
    local ($CALLS, $STACK, $FLOW, $SELECTED, $HITS, %ORDINALS, %SEALED);
    ($CALLS, $STACK, $FLOW, $SELECTED, $HITS) = ([], [], $flow, $selected, 0);
    %SEALED = map { $_ => 1 } @$sealed;
    if (defined($selected)) {
        die "unsafe source or sealed return fault\n" if $selected->{phase} eq 'after'
            && ($SEALED{$selected->{symbol}} || $selected->{symbol} eq 'NativeProxyImageCustody::_source');
    }
    my $public = \&NativeProxyObservationRelease::release_observation_reference;
    no warnings 'redefine';
    local *NativeProxyObservationRelease::release_observation_reference = sub {
        my @arguments = @_;
        local $ACTIVE = 1;
        return _installed($entries, 0, sub { $public->(@arguments) });
    };
    my $operation = NativeProxyReleaseTrace::observe($context, $arguments, 'none');
    $operation->{boundary_calls} = $CALLS;
    $operation->{interrupted_boundary_ids} = [map { $_->{id} } @$STACK];
    $operation->{injected_hits} = $HITS;
    return $operation;
}

sub caller_controls {
    my ($entries, $sealed) = @_;
    my @results; local %SEALED = map { $_ => 1 } @$sealed;
    for my $entry (grep { $SEALED{$_->{name}} } @$entries) {
        no strict 'refs';
        my $original = \&{$entry->{name}};
        my $before = eval { $original->(); 1 }; my $before_error = $@;
        local ($CALLS, $STACK, $FLOW, $SELECTED, $HITS, %ORDINALS);
        ($CALLS, $STACK, $FLOW, $SELECTED, $HITS) = ([], [], undef, undef, 0);
        local $NativeProxyReleaseTrace::ROW = {events => []}; local $ACTIVE = 1;
        my $after = eval { _installed([$entry], 0, sub { &{$entry->{name}}(); }); 1 }; my $after_error = $@;
        push @results, {name => $entry->{name}, baseline_returned => $before ? 1 : 0, baseline_error => $before_error,
            instrumented_returned => $after ? 1 : 0, instrumented_error => $after_error, calls => $CALLS,
            events => $NativeProxyReleaseTrace::ROW->{events}, interrupted_boundary_ids => [map { $_->{id} } @$STACK]};
    }
    return \@results;
}

1;
