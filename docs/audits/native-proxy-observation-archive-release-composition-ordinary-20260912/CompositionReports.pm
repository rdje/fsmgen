package NativeProxyReleaseCompositionReports;

use strict;
use warnings;
use Errno qw(EIO ENOSPC);
use Scalar::Util qw(refaddr);
use DirectoryRead;
use CallFaultTrace;

sub observe {
    die "expected context, release arguments, callers, flow and composition\n" unless @_ == 6;
    my ($context, $arguments, $entries, $sealed, $flow, $resolved) = @_;
    my %errors = (EIO => EIO, ENOSPC => ENOSPC);
    my (%selected, %hit);
    for my $report (@{$resolved->{resolved_reports}}) {
        die "duplicate or unknown composition report\n" if exists($selected{$report->{label}})
            || !exists($errors{$report->{errno}});
        $selected{$report->{label}} = $report;
    }
    my $primary = $resolved->{resolved_primary};
    my $call_primary;
    local ($NativeProxyReleaseDirectoryRead::SELECTION, $NativeProxyReleaseDirectoryRead::REPORTS,
           $NativeProxyReleaseDirectoryRead::HITS) = (undef, [], 0);
    if (defined($primary)) {
        if ($primary->{kind} eq 'directory-read') {
            $NativeProxyReleaseDirectoryRead::SELECTION = $primary;
        } elsif ($primary->{kind} eq 'call') {
            $call_primary = {map { $_ => $primary->{$_} } qw(address symbol occurrence phase call_id)};
        } else { die "unknown composition primary kind\n"; }
    }
    my (@reports, @hits);
    my $actual_close = \&NativeProxyReleaseTrace::_close;
    no warnings 'redefine';
    local *NativeProxyReleaseTrace::_close = sub {
        my ($handle, $directory, $caller) = @_;
        my $observed = $NativeProxyReleaseTrace::HANDLES{refaddr($handle)};
        die "composition observer lost owned handle\n" unless $observed;
        my $actual = $actual_close->(@_); my $actual_errno = 0 + $!;
        my $target = $selected{$observed->{label}};
        if ($target) {
            die "composition close differs from actual custody\n" unless $target->{kind} eq $observed->{kind}
                && $target->{path} eq $observed->{path} && $target->{close_caller} eq $caller;
        }
        my $applied = $target && $actual && $observed->{closed_after_call};
        my $returned = $applied ? 0 : ($actual ? 1 : 0);
        my $error = $applied ? $errors{$target->{errno}} : $actual_errno;
        if ($applied) {
            die "composition close report repeated\n" if $hit{$target->{address}}++;
            push @hits, $target->{address};
            $observed->{modeled_close_errno} = $error;
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
    my $operation = NativeProxyReleaseCallFaultTrace::observe($context, $arguments, $entries, $sealed, $flow, $call_primary);
    $operation->{close_reports} = \@reports;
    $operation->{reported_error_hits} = \@hits;
    $operation->{directory_read_reports} = $NativeProxyReleaseDirectoryRead::REPORTS;
    $operation->{directory_primary_hits} = $NativeProxyReleaseDirectoryRead::HITS;
    return $operation;
}

1;
