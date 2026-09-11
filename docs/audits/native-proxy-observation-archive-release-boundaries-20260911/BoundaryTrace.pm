package NativeProxyReleaseBoundaryTrace;

use strict;
use warnings;
use Scalar::Util qw(refaddr);
use ReleaseTrace;

our ($ACTIVE, $CALLS, $STACK, $BASE_DEPTH);
our %ORDINALS;
my $ROOT = FSM::Test::ProcessSupervisor::repository_root();

# The original caller guards remain intact. These wrappers tail-call the exact
# helper; completion is observed at the caller's next selected continuation,
# after the helper frame has disappeared. No return wrapper impersonates a
# permitted caller. Ordinary unsealed calls retain their Perl return context.
my %SEALED = map { $_ => 1 } (
    'NativeProxyObservationRelease::_coordinator_request',
    'NativeProxyObservationRelease::_admit_locked',
    'NativeProxyObservationRelease::_release_locked',
    'NativeProxyObservationRelease::_finish_locked',
    'NativeProxyObservationRelease::_unlink_exact',
    'NativeProxyReferenceCensus::_inspect_locked');

sub _depth {
    my $depth = 0;
    ++$depth while defined(caller($depth));
    die "release trace stack exceeded its observation ceiling\n" if $depth > 128;
    return $depth;
}

sub _event { push @{$NativeProxyReleaseTrace::ROW->{events}}, $_[0]; }

sub _complete {
    my ($frame, $kind, $continuation, $error) = @_;
    die "release boundary completed twice\n" if exists($frame->{completion});
    $frame->{completion} = $kind;
    $frame->{continuation} = $continuation;
    my $recorded_error = $error;
    $recorded_error =~ s/\Q$ROOT\E/./g;
    $frame->{error} = $recorded_error;
    _event("call:$frame->{id}:".(length($error) ? 'error' : 'after'));
}

sub _flush {
    my ($depth, $continuation) = @_;
    while (@$STACK && $STACK->[-1]{tail} && $STACK->[-1]{depth} >= $depth) {
        my $frame = pop @$STACK;
        _complete($frame, 'caller_continuation', $continuation, '');
    }
}

sub _enter {
    my ($entry, $caller, $arguments) = @_;
    my ($saved_errno, $saved_eval, $saved_status) = (0 + $!, $@, $?);
    my $depth = _depth();
    _flush($depth, $entry->{name});
    $BASE_DEPTH = $depth unless defined($BASE_DEPTH);
    my $ordinal = $ORDINALS{$entry->{name}} // 0; $ORDINALS{$entry->{name}} = $ordinal + 1;
    my $frame = {id => scalar(@$CALLS), name => $entry->{name}, occurrence => $ordinal,
        category => $entry->{category}, caller => $caller, depth => $depth,
        relative_depth => $depth - $BASE_DEPTH, parent => @$STACK ? $STACK->[-1]{id} : undef,
        tail => $SEALED{$entry->{name}} ? 1 : 0};
    if ($entry->{name} eq 'NativeProxyImageCustody::_recheck_source') {
        my $source = $arguments->[0];
        my $handle = $NativeProxyReleaseTrace::HANDLES{refaddr($source->{handle})};
        die "recheck has no observed owning handle\n" unless $handle;
        $frame->{source_handle} = $handle->{label};
        $frame->{path} = $handle->{path};
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
    push @$CALLS, $frame; push @$STACK, $frame;
    _event("call:$frame->{id}:before");
    ($!, $@, $?) = ($saved_errno, $saved_eval, $saved_status);
    return $frame;
}

sub _leave {
    my ($frame, $error) = @_;
    my ($saved_errno, $saved_eval, $saved_status) = (0 + $!, $@, $?);
    my $depth = _depth();
    _flush($depth, 'return:'.$frame->{name});
    die "release boundary stack differs from caller\n" unless @$STACK && pop(@$STACK) == $frame;
    _complete($frame, 'direct_return', undef, $error);
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
        my $want = wantarray;
        my $frame = _enter($entry, scalar(caller), \@_);
        my (@values, $value);
        my $ok = eval {
            if (!defined($want)) { $original->(@_); }
            elsif ($want) { @values = $original->(@_); }
            else { $value = $original->(@_); }
            1;
        };
        my ($error, $saved_errno, $saved_status) = ($@, 0 + $!, $?);
        _leave($frame, $ok ? '' : $error);
        ($!, $?) = ($saved_errno, $saved_status);
        die $error unless $ok;
        return $want ? @values : $value;
    };
}

sub _installed {
    my ($entries, $index, $action) = @_;
    return $action->() if $index == @$entries;
    my $entry = $entries->[$index];
    no strict 'refs';
    no warnings 'redefine';
    my $original = \&{$entry->{name}};
    local *{$entry->{name}} = _wrapper($entry, $original);
    return _installed($entries, $index + 1, $action);
}

sub entries {
    my ($plan) = @_;
    my @entries;
    for my $item (@{$plan->{source_boundaries}}) {
        next unless $item->{category} eq 'safe_before_after' || $item->{category} eq 'before_only_returned_handle';
        my $path = "$ROOT/$item->{path}";
        open my $fh, '<:raw', $path or die "cannot read pinned source declaration: $!\n";
        my $first = <$fh>; close $fh or die "cannot close source declaration: $!\n";
        my ($package) = $first =~ /\Apackage ([A-Za-z0-9_:]+);/;
        die "missing pinned package declaration\n" unless defined($package);
        push @entries, {name => "$package\::$item->{symbol}", category => $item->{category}};
    }
    return \@entries;
}

sub _reset {
    $CALLS = []; $STACK = []; $BASE_DEPTH = undef; %ORDINALS = ();
}

sub observe {
    my ($context, $arguments, $entries) = @_;
    die "nested boundary observation\n" if $ACTIVE;
    local ($CALLS, $STACK, $BASE_DEPTH, %ORDINALS);
    _reset();
    my $public = \&NativeProxyObservationRelease::release_observation_reference;
    no warnings 'redefine';
    local *NativeProxyObservationRelease::release_observation_reference = sub {
        my @arguments = @_;
        local $ACTIVE = 1;
        return _installed($entries, 0, sub { $public->(@arguments) });
    };
    my $operation = NativeProxyReleaseTrace::observe($context, $arguments, 'none');
    $operation->{boundary_calls} = $CALLS;
    $operation->{pending_boundary_ids} = [map { $_->{id} } @$STACK];
    $operation->{boundary_stack_complete} = @$STACK ? 0 : 1;
    return $operation;
}

sub caller_controls {
    my ($entries) = @_;
    my @results;
    for my $entry (grep { $SEALED{$_->{name}} } @$entries) {
        no strict 'refs';
        my $original = \&{$entry->{name}};
        my $before = eval { $original->(); 1 };
        my $before_error = $@;
        local ($CALLS, $STACK, $BASE_DEPTH, %ORDINALS); _reset();
        local $NativeProxyReleaseTrace::ROW = {events => []};
        local $ACTIVE = 1;
        my $after = eval { _installed([$entry], 0, sub { &{$entry->{name}}(); }); 1 };
        my $after_error = $@;
        # This is an explicit failed external call, outside release and before
        # fixtures. It is not a successful caller-continuation observation.
        for my $frame (reverse @$STACK) { _complete($frame, 'external_rejection', undef, $after_error); }
        @$STACK = ();
        push @results, {name => $entry->{name}, baseline_returned => $before ? 1 : 0,
            baseline_error => $before_error, instrumented_returned => $after ? 1 : 0,
            instrumented_error => $after_error, calls => $CALLS, events => $NativeProxyReleaseTrace::ROW->{events}};
    }
    return \@results;
}

1;
