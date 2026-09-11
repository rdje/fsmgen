package NativeProxyArchiveOmittedCloses;

use strict;
use warnings;
use Fcntl qw(F_GETFD FD_CLOEXEC S_ISDIR S_ISREG);
use Scalar::Util qw(refaddr);
use ArchiveTrace;

sub _open_witness {
    my ($row) = @_;
    my $handle = $row->{handle};
    my $descriptor = fileno($handle);
    die "omitted descriptor no longer open\n" unless defined($descriptor) && $descriptor == $row->{descriptor};
    my (@native, $observer, $observer_closed, $cloexec);
    if ($row->{kind} eq 'directory') {
        open my $probe, '<&', $descriptor or die "omission observer duplicate: $!\n";
        $observer = fileno($probe);
        @native = stat($probe);
        my $ok = CORE::close($probe);
        $observer_closed = !defined(fileno($probe)) ? 1 : 0;
        die "omission observer duplicate did not close\n" unless $ok && $observer_closed;
        die "omitted directory native type changed\n" unless @native && S_ISDIR($native[2]);
    } else {
        @native = stat($handle);
        die "omitted file native type changed\n" unless @native && S_ISREG($native[2]);
        my $flags = CORE::fcntl($handle, F_GETFD, 0);
        die "omitted file flags unavailable\n" unless defined($flags);
        $cloexec = ($flags & FD_CLOEXEC) ? 1 : 0;
    }
    die "omitted descriptor native identity changed\n" unless $native[0] == $row->{device} && $native[1] == $row->{inode};
    return {label => $row->{label}, kind => $row->{kind}, path => $row->{path},
        descriptor => $descriptor, device => $native[0], inode => $native[1], open_at_return => 1,
        cloexec => $cloexec, observer_descriptor => $observer, observer_closed => $observer_closed};
}

sub observe {
    die "expected inert context and omission selection\n" unless @_ == 2;
    my ($context, $selection) = @_;
    my %selected;
    die "duplicate omitted-close selector\n" if grep { $selected{$_}++ } @{$selection->{omissions}};
    my (@held, @hits, @witnesses, @recovery, @errors);
    my $primary_hits = 0;
    my $actual_close = \&NativeProxyArchiveTrace::_close;
    my $record_event = \&NativeProxyArchiveTrace::_event;
    no warnings 'redefine';
    local *NativeProxyArchiveTrace::_event = sub {
        $record_event->(@_);
        if (defined($selection->{primary}) && $_[0] eq $selection->{primary}) {
            ++$primary_hits;
            die "primary archive omission-control: $selection->{name}\n";
        }
    };
    local *NativeProxyArchiveTrace::_close = sub {
        my ($handle, $directory) = @_;
        my $row = $NativeProxyArchiveTrace::HANDLES{refaddr($handle)};
        die "omission observer lost owned handle\n" unless $row;
        return $actual_close->(@_) unless $selected{$row->{label}};
        die "selected omitted handle closed twice\n" if exists($row->{actual_close_ok});
        # Keep the actual alias alive beyond observe_archive's local @HELD.
        push @held, $row;
        push @hits, $row->{label};
        $record_event->("close:$row->{label}:before");
        my $flags = $directory ? undef : CORE::fcntl($handle, F_GETFD, 0);
        $row->{cloexec_before_close} = $directory ? undef : defined($flags) && ($flags & FD_CLOEXEC) ? 1 : 0;
        $row->{actual_close_performed} = 0;
        $row->{actual_close_ok} = 0;
        $row->{actual_errno} = 0;
        $row->{closed_after_call} = defined(fileno($handle)) ? 0 : 1;
        $row->{reported_return} = 1;
        $row->{reported_errno} = 0;
        $record_event->("close:$row->{label}:after");
        $! = 0;
        return 1;
    };
    my $operation;
    my $observed = eval { $operation = NativeProxyArchiveTrace::observe_archive($context); 1; };
    push @errors, "archive observer: $@" unless $observed;
    # Observe ALL still-held identities before recovering any of them. Errors
    # cannot skip the later recovery loop or rewrite the original verdict.
    for my $row (@held) {
        my $ok = eval { push @witnesses, _open_witness($row); 1; };
        push @errors, "open witness: $@" unless $ok;
    }
    for my $row (@held) {
        my $handle = $row->{handle};
        my $descriptor = fileno($handle);
        my $performed = defined($descriptor) ? 1 : 0;
        $! = 0;
        my $ok = $performed ? ($row->{kind} eq 'directory' ? CORE::closedir($handle) : CORE::close($handle)) : 0;
        my $error = 0 + $!;
        push @recovery, {label => $row->{label}, descriptor_before => $descriptor,
            performed => $performed, actual_return => $ok ? 1 : 0, actual_errno => $error,
            closed_after => defined(fileno($handle)) ? 0 : 1};
    }
    $operation //= {handles => [], events => [], reads => [], writes => [], directories => [],
        returned => 0, error => 'archive observer failed', all_observed_handles_closed => 0};
    $operation->{omission_hits} = \@hits;
    $operation->{primary_hits} = $primary_hits;
    $operation->{open_witnesses} = \@witnesses;
    $operation->{observer_recovery} = \@recovery;
    $operation->{observer_errors} = \@errors;
    $operation->{recovery_complete} = !@errors && !grep({ !$_->{performed} || !$_->{actual_return}
        || $_->{actual_errno} || !$_->{closed_after} } @recovery) ? 1 : 0;
    return $operation;
}

1;
