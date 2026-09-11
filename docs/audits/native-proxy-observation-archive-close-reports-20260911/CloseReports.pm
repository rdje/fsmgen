package NativeProxyArchiveCloseReports;

use strict;
use warnings;
use Errno qw(EIO ENOSPC);
use Scalar::Util qw(refaddr);
use ArchiveTrace;


sub observe {
    die "expected inert context and close-report selection\n" unless @_ == 2;
    my ($context, $selection) = @_;
    my %errors = (EIO => EIO, ENOSPC => ENOSPC);
    my %selected;
    for my $report (@{$selection->{reports}}) {
        die "duplicate or unknown close report\n" if exists($selected{$report->{label}})
            || !exists($errors{$report->{errno}});
        $selected{$report->{label}} = $report->{errno};
    }
    my (@reports, @hits);
    my $primary_hits = 0;
    my $actual_close = \&NativeProxyArchiveTrace::_close;
    my $record_event = \&NativeProxyArchiveTrace::_event;
    no warnings 'redefine';
    local *NativeProxyArchiveTrace::_event = sub {
        $record_event->(@_);
        if (defined($selection->{primary}) && $_[0] eq $selection->{primary}) {
            ++$primary_hits;
            die "primary archive close-control: $selection->{name}\n";
        }
    };
    local *NativeProxyArchiveTrace::_close = sub {
        my ($handle, $directory) = @_;
        my $observed = $NativeProxyArchiveTrace::HANDLES{refaddr($handle)};
        die "close-report observer lost owned handle\n" unless $observed;
        my $actual = $actual_close->(@_);
        my $actual_errno = 0 + $!;
        my $name = $selected{$observed->{label}};
        # Preserve an unexpected real close failure instead of masking it with
        # the planned report. The qualification must then fail on actual truth.
        my $applied = defined($name) && $actual && $observed->{closed_after_call};
        my $returned = $applied ? 0 : ($actual ? 1 : 0);
        my $error = $applied ? $errors{$name} : $actual_errno;
        push @hits, $observed->{label} if $applied;
        push @reports, {label => $observed->{label}, kind => $observed->{kind}, path => $observed->{path},
            descriptor => $observed->{descriptor}, device => $observed->{device}, inode => $observed->{inode},
            actual_return => $actual ? 1 : 0, actual_errno => $actual_errno,
            closed_after_call => $observed->{closed_after_call}, report_applied => $applied ? 1 : 0,
            reported_return => $returned, reported_errno => $error, selected_errno => $name};
        $! = $error;
        return $returned;
    };
    my $operation = NativeProxyArchiveTrace::observe_archive($context);
    $operation->{close_reports} = \@reports;
    $operation->{reported_error_hits} = \@hits;
    $operation->{primary_hits} = $primary_hits;
    return $operation;
}

1;
