package NativeProxyReleaseSyscallTrace;

use strict;
use warnings;
our ($ACTIVE, $SELECTED, $TRACE, $INSTALLED);

# This hook must exist before PrivateWorkspace compiles its lstat call.
# Inactive calls preserve the original caller and Perl's list/scalar context.
BEGIN {
    die "absence implementation already loaded\n" if $INC{'PrivateWorkspace.pm'};
    die "unexpected prior lstat hook\n" if defined &CORE::GLOBAL::lstat;
    *CORE::GLOBAL::lstat = sub (_) { goto &_lstat; };
}

use Errno qw(EACCES EIO ENOENT);
use File::Spec;

sub _native {
    my ($path) = @_;
    $! = 0;
    my @metadata = CORE::lstat($path);
    my $errno = 0 + $!;
    return {metadata => \@metadata, errno => $errno};
}

sub _lstat {
    return wantarray ? CORE::lstat($_[0]) : scalar CORE::lstat($_[0]) unless $ACTIVE
        && caller eq 'NativeProxyPrivateWorkspace';
    my $stack = $NativeProxyReleaseCallFaultTrace::STACK;
    return wantarray ? CORE::lstat($_[0]) : scalar CORE::lstat($_[0]) unless @$stack
        && $stack->[-1]{name} eq 'NativeProxyPrivateWorkspace::_absent';
    my $parent = $stack->[-2];
    die "unexpected absence syscall scope\n" unless @_ == 1 && wantarray && $parent
        && $parent->{name} eq 'NativeProxyObservationRelease::_assert_absent'
        && $_[0] eq "$NativeProxyReleaseTrace::ROOT/$NativeProxyReleaseTrace::ROW->{expected_hold}";
    my $actual = _native($_[0]);
    my $phase = $parent->{phase};
    my $modeled = defined($SELECTED) && defined($SELECTED->{phase}) && $SELECTED->{phase} eq $phase;
    my $reported = {metadata => [@{$actual->{metadata}}], errno => $actual->{errno}};
    if ($modeled) {
        die "selected report repeated\n" if $TRACE->{hits}++;
        if ($SELECTED->{control} eq 'absence-eio') {
            $reported = {metadata => [], errno => EIO};
        } elsif ($SELECTED->{control} eq 'absence-present') {
            # An explicit synthetic report of the original hold's metadata.
            # The actual lstat above remains independently retained as absent.
            $reported = {metadata => [@{$TRACE->{unlink}{before}{metadata}}], errno => 0};
            die "missing original hold metadata\n" unless @{$reported->{metadata}} == 13;
        } else { die "unknown absence report\n"; }
    }
    push @{$TRACE->{absence}}, {path => $NativeProxyReleaseTrace::ROW->{expected_hold},
        call_id => $stack->[-1]{id}, phase => $phase, modeled => $modeled ? 1 : 0,
        actual => $actual, reported => $reported};
    $! = $reported->{errno};
    return @{$reported->{metadata}};
}

sub install {
    die "syscall hooks already installed\n" if $INSTALLED;
    die "release observer not loaded\n" unless defined &CORE::GLOBAL::unlink;
    my $original = \&CORE::GLOBAL::unlink;
    no warnings 'redefine';
    *CORE::GLOBAL::unlink = sub (@) {
        goto &$original unless $ACTIVE;
        my $row = $NativeProxyReleaseTrace::ROW;
        my @paths = map { File::Spec->abs2rel($_, $NativeProxyReleaseTrace::ROOT) } @_;
        die "unexpected release unlink scope\n" unless caller eq 'NativeProxyObservationRelease'
            && @paths == 1 && $paths[0] eq $row->{expected_hold} && !defined($TRACE->{unlink});
        my $before = _native($_[0]);
        my $modeled = defined($SELECTED) && $SELECTED->{control} eq 'unlink-eacces';
        my ($actual, $reported);
        push @{$row->{events}}, 'unlink:0:before';
        if ($modeled) {
            die "selected report repeated\n" if $TRACE->{hits}++;
            $actual = {executed => 0, count => undef, errno => undef};
            $reported = {count => 0, errno => EACCES};
        } else {
            $! = 0;
            my $count = CORE::unlink(@_); my $errno = 0 + $!;
            $actual = {executed => 1, count => $count, errno => $errno};
            $reported = {count => $count, errno => $errno};
        }
        my $after = _native($_[0]);
        $TRACE->{unlink} = {path => $paths[0], before => $before, after => $after,
            modeled => $modeled ? 1 : 0, actual => $actual, reported => $reported};
        # Keep the original observer's event stream and real effect ledger.
        # A suppressed syscall has no entry in that real-call ledger. Its
        # attempt, null actual result and modeled return remain in TRACE.
        push @{$row->{unlinks}}, {paths => \@paths, actual_count => $actual->{count}, actual_errno => $actual->{errno}}
            if $actual->{executed};
        push @{$row->{events}}, 'unlink:0:after';
        $! = $reported->{errno};
        return $reported->{count};
    };
    $INSTALLED = 1;
}

sub observe {
    my ($context, $arguments, $entries, $sealed, $flow, $selected) = @_;
    die "nested or uninstalled syscall observation\n" if $ACTIVE || !$INSTALLED;
    local $SELECTED = $selected;
    local $TRACE = {hits => 0, unlink => undef, absence => []};
    local $ACTIVE = 1;
    my $operation = NativeProxyReleaseCallFaultTrace::observe($context, $arguments, $entries, $sealed, $flow, undef);
    $operation->{syscall_trace} = $TRACE;
    return $operation;
}

1;
