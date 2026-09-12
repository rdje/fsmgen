package NativeProxyReleaseCloseReports;

use strict;
use warnings;
use Errno qw(EIO);
use Scalar::Util qw(refaddr);
use CallFaultTrace;

sub observe {
    die "expected release context, arguments, callers, flow and resolved reports\n"
        unless @_ == 6;
    my ($context, $arguments, $entries, $sealed, $flow, $resolved) = @_;
    die "only one release close report is admitted\n" unless ref($resolved) eq 'ARRAY' && @$resolved <= 1;
    my %selected = map { $_->{label} => $_ } @$resolved;
    my (@reports, @hits);
    my $actual_close = \&NativeProxyReleaseTrace::_close;
    no warnings 'redefine';
    local *NativeProxyReleaseTrace::_close = sub {
        my ($handle, $directory, $caller) = @_;
        my $observed = $NativeProxyReleaseTrace::HANDLES{refaddr($handle)};
        die "release close observer lost its owned handle\n" unless $observed;
        my $actual = $actual_close->(@_); my $actual_errno = 0 + $!;
        my $target = $selected{$observed->{label}};
        if ($target) {
            die "resolved close differs from actual custody\n"
                unless $target->{kind} eq $observed->{kind}
                    && $target->{path} eq $observed->{path}
                    && $target->{close_caller} eq $caller;
        }
        # Preserve an unexpected real failure. Reporting EIO is authorized only
        # after the real close succeeded and the exact observed handle closed.
        my $applied = $target && $actual && $observed->{closed_after_call};
        my $returned = $applied ? 0 : ($actual ? 1 : 0);
        my $error = $applied ? EIO : $actual_errno;
        if ($applied) {
            die "selected close report repeated\n" if @hits;
            push @hits, $target->{address};
            $observed->{modeled_close_errno} = EIO;
            ++$NativeProxyReleaseTrace::ROW->{modeled_close_hits};
        }
        @$observed{qw(reported_return reported_errno)} = ($returned, $error);
        push @reports, {label => $observed->{label}, kind => $observed->{kind}, path => $observed->{path},
            descriptor => $observed->{descriptor}, device => $observed->{device}, inode => $observed->{inode},
            actual_return => $actual ? 1 : 0, actual_errno => $actual_errno,
            closed_after_call => $observed->{closed_after_call}, report_applied => $applied ? 1 : 0,
            reported_return => $returned, reported_errno => $error,
            selected_address => $target ? $target->{address} : undef};
        $! = $error; return $returned;
    };
    my $operation = NativeProxyReleaseCallFaultTrace::observe($context, $arguments, $entries, $sealed, $flow, undef);
    $operation->{close_reports} = \@reports;
    $operation->{reported_error_hits} = \@hits;
    return $operation;
}

1;
