package NativeProxyReleaseOmissions;

use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use Fcntl qw(F_GETFD FD_CLOEXEC S_ISDIR S_ISREG);
use JSON::PP ();
use Scalar::Util qw(refaddr);
use CallFaultTrace;

my $JSON = JSON::PP->new->canonical->ascii;
sub _digest { return sha256_hex($JSON->encode($_[0])); }

sub _open_witness {
    my ($row) = @_;
    my $handle = $row->{handle}; my $descriptor = fileno($handle);
    die "omitted release descriptor no longer open\n" unless defined($descriptor) && $descriptor == $row->{descriptor};
    my (@native, $observer, $observer_closed, $cloexec);
    if ($row->{kind} eq 'directory') {
        open my $probe, '<&', $descriptor or die "release omission observer duplicate: $!\n";
        $observer = fileno($probe); @native = stat($probe);
        my $ok = CORE::close($probe); $observer_closed = !defined(fileno($probe)) ? 1 : 0;
        die "release omission observer duplicate did not close\n" unless $ok && $observer_closed;
        die "omitted release directory changed kind\n" unless @native && S_ISDIR($native[2]);
    } else {
        @native = stat($handle);
        die "omitted release file changed kind\n" unless @native && S_ISREG($native[2]);
        my $flags = CORE::fcntl($handle, F_GETFD, 0);
        die "omitted release file flags unavailable\n" unless defined($flags);
        $cloexec = ($flags & FD_CLOEXEC) ? 1 : 0;
    }
    die "omitted release native identity changed\n" unless $native[0] == $row->{device} && $native[1] == $row->{inode};
    return {label => $row->{label}, kind => $row->{kind}, path => $row->{path}, object_address => refaddr($handle),
        descriptor => $descriptor, native => \@native, device => $native[0], inode => $native[1],
        open_after_original_return => 1, cloexec => $cloexec,
        observer_descriptor => $observer, observer_closed => $observer_closed};
}

sub observe {
    die "expected release context, arguments, callers, flow and resolved omission\n" unless @_ == 6;
    my ($context, $arguments, $entries, $sealed, $flow, $resolved) = @_;
    die "only one release omission is admitted\n" unless ref($resolved) eq 'ARRAY' && @$resolved <= 1;
    my $selected = @$resolved ? $resolved->[0] : undef;
    my (@held, @hits, @witnesses, @recovery, @errors);
    my $actual_close = \&NativeProxyReleaseTrace::_close;
    no warnings 'redefine';
    local *NativeProxyReleaseTrace::_close = sub {
        my ($handle, $directory, $caller) = @_;
        my $row = $NativeProxyReleaseTrace::HANDLES{refaddr($handle)};
        die "release omission lost its owned handle\n" unless $row;
        return $actual_close->(@_) unless $selected && $row->{label} eq $selected->{label};
        die "resolved omission differs from actual custody\n"
            unless $row->{kind} eq $selected->{kind} && $row->{path} eq $selected->{path}
                && $caller eq $selected->{close_caller} && !!$directory == ($row->{kind} eq 'directory');
        die "selected release omission repeated\n" if @held || exists($row->{actual_close_ok});
        # This strong alias is the deliberate counterimplementation. Preserve
        # it beyond the original observer's dynamically localized handle list.
        push @held, $row; push @hits, $selected->{address};
        $row->{omitted_object_address} = refaddr($handle);
        push @{$NativeProxyReleaseTrace::ROW->{events}}, "close:$row->{label}:before";
        unless ($directory) {
            my $flags = CORE::fcntl($handle, F_GETFD, 0);
            $row->{cloexec_before_close} = defined($flags) && ($flags & FD_CLOEXEC) ? 1 : 0;
        }
        @$row{qw(actual_close_performed actual_close_ok actual_errno)} = (0, 0, 0);
        $row->{closed_after_call} = defined(fileno($handle)) ? 0 : 1;
        @$row{qw(close_caller reported_return reported_errno)} = ($caller, 1, 0);
        push @{$NativeProxyReleaseTrace::ROW->{events}}, "close:$row->{label}:after";
        $! = 0; return 1;
    };
    my $operation;
    my $observed = eval {
        $operation = NativeProxyReleaseCallFaultTrace::observe($context, $arguments, $entries, $sealed, $flow, undef);
        1;
    };
    push @errors, "release observer: $@" unless $observed;
    my $original_digest = defined($operation) ? _digest($operation) : undef;
    # Observe before recovery. Even a witness failure must not skip exact
    # cleanup; it remains a failed qualification with its original diagnostic.
    for my $row (@held) {
        my $ok = eval { push @witnesses, _open_witness($row); 1 };
        push @errors, "open witness: $@" unless $ok;
    }
    for my $row (@held) {
        my $handle = $row->{handle}; my $descriptor = fileno($handle);
        my $performed = defined($descriptor) ? 1 : 0;
        $! = 0;
        my $ok = $performed ? ($row->{kind} eq 'directory' ? CORE::closedir($handle) : CORE::close($handle)) : 0;
        my $error = 0 + $!;
        push @recovery, {label => $row->{label}, object_address => refaddr($handle), descriptor_before => $descriptor,
            primitive => $row->{kind} eq 'directory' ? 'CORE::closedir' : 'CORE::close',
            performed => $performed, actual_return => $ok ? 1 : 0, actual_errno => $error,
            closed_after => defined(fileno($handle)) ? 0 : 1};
    }
    my $after_digest = defined($operation) ? _digest($operation) : undef;
    return {operation => $operation, observation_returned => $observed ? 1 : 0,
        omission_hits => \@hits, open_witnesses => \@witnesses, observer_recovery => \@recovery, observer_errors => \@errors,
        original_sha256_before_recovery => $original_digest, original_sha256_after_recovery => $after_digest,
        recovery_complete => !@errors && !grep({ !$_->{performed} || !$_->{actual_return}
            || $_->{actual_errno} || !$_->{closed_after} } @recovery) ? 1 : 0};
}

1;
