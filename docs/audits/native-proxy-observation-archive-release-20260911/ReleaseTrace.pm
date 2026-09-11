package NativeProxyReleaseTrace;

use strict;
use warnings;
our ($ACTIVE, $ROW, $ROOT, $CASE, $EVIDENCE, $CONTROL);
our (%HANDLES, %COUNTERS, @HELD);

BEGIN {
    *CORE::GLOBAL::sysopen = sub (*$$;$) {
        my $ok = @_ == 4 ? CORE::sysopen($_[0], $_[1], $_[2], $_[3]) : CORE::sysopen($_[0], $_[1], $_[2]);
        my $error = 0 + $!;
        if ($ACTIVE && caller eq 'NativeProxyImageCoordination') {
            push @{$ROW->{lock_opens}}, {path => _relative($_[1]), flags => $_[2], returned => $ok ? 1 : 0, errno => $error};
            _handle($_[0], 'lock', $_[1]) if $ok;
        }
        $! = $error; return $ok;
    };
    *CORE::GLOBAL::opendir = sub (*$) {
        my $ok = CORE::opendir($_[0], $_[1]); my $error = 0 + $!;
        if ($ACTIVE && $ok && (caller eq 'NativeProxyImageCoordination' || caller eq 'NativeProxyImageCustody')) {
            _handle($_[0], 'directory', $_[1]);
        }
        $! = $error; return $ok;
    };
    *CORE::GLOBAL::closedir = sub (*) {
        return CORE::closedir($_[0]) unless $ACTIVE && ref($_[0]) && exists($HANDLES{Scalar::Util::refaddr($_[0])});
        return _close($_[0], 1, scalar(caller));
    };
    *CORE::GLOBAL::close = sub (*) {
        return CORE::close($_[0]) unless $ACTIVE && ref($_[0]) && exists($HANDLES{Scalar::Util::refaddr($_[0])});
        return _close($_[0], 0, scalar(caller));
    };
    *CORE::GLOBAL::unlink = sub (@) {
        return CORE::unlink(@_) unless $ACTIVE;
        my @paths = map { _relative($_) } @_;
        unless (caller eq 'NativeProxyObservationRelease' && @paths == 1 && $paths[0] eq $ROW->{expected_hold}) {
            $ROW->{forbidden_mutation_attempts}++;
            die "release attempted an unauthorized unlink\n";
        }
        my $ordinal = @{$ROW->{unlinks}};
        push @{$ROW->{events}}, "unlink:$ordinal:before";
        $! = 0; my $count = CORE::unlink(@_); my $error = 0 + $!;
        push @{$ROW->{unlinks}}, {paths => \@paths, actual_count => $count, actual_errno => $error};
        push @{$ROW->{events}}, "unlink:$ordinal:after";
        $! = $error; return $count;
    };
    *CORE::GLOBAL::mkdir = sub ($;$) {
        if ($ACTIVE) { $ROW->{forbidden_mutation_attempts}++; die "release attempted mkdir\n"; }
        return @_ == 1 ? CORE::mkdir($_[0]) : CORE::mkdir($_[0], $_[1]);
    };
    *CORE::GLOBAL::chmod = sub (@) { if ($ACTIVE) { $ROW->{forbidden_mutation_attempts}++; die "release attempted chmod\n"; } return CORE::chmod(@_); };
    *CORE::GLOBAL::rename = sub ($$) { if ($ACTIVE) { $ROW->{forbidden_mutation_attempts}++; die "release attempted rename\n"; } return CORE::rename($_[0], $_[1]); };
    *CORE::GLOBAL::rmdir = sub ($) { if ($ACTIVE) { $ROW->{forbidden_mutation_attempts}++; die "release attempted rmdir\n"; } return CORE::rmdir($_[0]); };
    *CORE::GLOBAL::syswrite = sub (*$$;$) {
        if ($ACTIVE) { $ROW->{forbidden_mutation_attempts}++; die "release attempted syswrite\n"; }
        return @_ == 4 ? CORE::syswrite($_[0], $_[1], $_[2], $_[3]) : CORE::syswrite($_[0], $_[1], $_[2]);
    };
}

use Digest::SHA qw(sha256_hex);
use Errno qw(EIO);
use Fcntl qw(S_ISDIR S_ISREG F_GETFD FD_CLOEXEC O_CREAT O_EXCL);
use File::Spec;
use Scalar::Util qw(refaddr);
use FSM::Test::ProcessSupervisor qw(repository_root);
use ObservationRelease;

$ROOT = repository_root();
sub _relative { return File::Spec->abs2rel($_[0], $ROOT); }
sub _ordinal { my ($kind) = @_; my $n = $COUNTERS{$kind} // 0; $COUNTERS{$kind} = $n + 1; return $n; }

sub _allowed_read {
    my ($path) = @_;
    my $relative = _relative($path);
    my $allowed =
        $relative =~ /\A\Q$CASE\E\/references\/[0-9a-f]{64}\.json\z/
        || $relative =~ /\A\Q$CASE\E\/images\/[0-9a-f]{64}\/(?:rustup\.c|rustup|image\.json)\z/
        || $relative =~ /\A\Q$EVIDENCE\E\/retained-sources\/[0-9a-f]{64}\.source\z/;
    unless ($allowed) { $ROW->{forbidden_source_attempts}++; die "release attempted a private or foreign source read\n"; }
    return $relative;
}

sub _handle {
    my ($handle, $kind, $path, $source) = @_;
    my $address = refaddr($handle); die 'duplicate observed ownership' if exists($HANDLES{$address});
    my $fd = fileno($handle); die 'missing observed descriptor' unless defined($fd) && $fd >= 0;
    my (@native, $observer, $observer_closed);
    if ($kind eq 'directory') {
        open my $probe, '<&', $fd or die "directory observer duplicate: $!\n";
        @native = stat($probe); $observer = fileno($probe);
        $observer_closed = CORE::close($probe) ? 1 : 0;
        die 'directory observer close failed' unless $observer_closed && !defined(fileno($probe));
        die 'expected observed directory' unless @native && S_ISDIR($native[2]);
    } else {
        @native = stat($handle); die 'expected observed file' unless @native && S_ISREG($native[2]);
    }
    my @named = lstat($path);
    die 'observed descriptor differs from current name' unless @named && $named[0] == $native[0] && $named[1] == $native[1];
    my $label = $kind.':'._ordinal($kind);
    my $row = {handle => $handle, label => $label, kind => $kind, path => _relative($path), descriptor => $fd,
        native_at_admission => \@native, device => $native[0], inode => $native[1]};
    @$row{qw(observer_descriptor observer_closed)} = ($observer, $observer_closed) if defined($observer);
    if ($source) {
        $row->{size_bytes} = length($source->{bytes}); $row->{sha256} = sha256_hex($source->{bytes});
        my $flags = CORE::fcntl($handle, F_GETFD, 0);
        $row->{cloexec_at_handoff} = defined($flags) && ($flags & FD_CLOEXEC) ? 1 : 0;
    }
    $HANDLES{$address} = $row; push @HELD, $row;
    push @{$ROW->{events}}, "opened:$label";
}

sub _close {
    my ($handle, $directory, $caller) = @_;
    my $row = $HANDLES{refaddr($handle)}; die 'duplicate observed close' if exists($row->{actual_close_ok});
    push @{$ROW->{events}}, "close:$row->{label}:before";
    if (!$directory) {
        my $flags = CORE::fcntl($handle, F_GETFD, 0);
        $row->{cloexec_before_close} = defined($flags) && ($flags & FD_CLOEXEC) ? 1 : 0;
    }
    $! = 0; my $ok = $directory ? CORE::closedir($handle) : CORE::close($handle); my $error = 0 + $!;
    $row->{actual_close_ok} = $ok ? 1 : 0; $row->{actual_errno} = $error;
    $row->{closed_after_call} = defined(fileno($handle)) ? 0 : 1;
    my $unlinked = grep { $_->{actual_count} == 1 } @{$ROW->{unlinks}};
    my $source_control = ($CONTROL eq 'source-close-after-unlink' || $CONTROL eq 'primary-and-source-close')
        && $caller eq 'NativeProxyObservationRelease' && $row->{kind} eq 'source';
    my $lock_control = $CONTROL eq 'lock-close-after-unlink' && $row->{kind} eq 'lock';
    my $modeled = $ok && $unlinked && !$ROW->{modeled_close_hits} && ($source_control || $lock_control);
    if ($modeled) { $ROW->{modeled_close_hits}++; $row->{modeled_close_errno} = EIO; }
    @$row{qw(close_caller reported_return reported_errno)} = ($caller, $modeled ? 0 : ($ok ? 1 : 0), $modeled ? EIO : $error);
    push @{$ROW->{events}}, "close:$row->{label}:after";
    $! = $modeled ? EIO : $error;
    return $modeled ? 0 : $ok;
}

sub observe {
    my ($context, $arguments, $control) = @_;
    die 'nested release observation' if $ACTIVE;
    local $CASE = $context->{store}{path}; local $EVIDENCE = $context->{evidence}{path}; local $CONTROL = $control;
    local (%HANDLES, %COUNTERS, @HELD);
    local $ROW = {events => [], reads => [], source_requests => [], lock_opens => [], unlinks => [],
        modeled_close_hits => 0, forbidden_mutation_attempts => 0, forbidden_source_attempts => 0,
        expected_hold => $context->{acquired}{observation_reference}{source}{identity}{path}};
    my $source = \&NativeProxyImageCustody::_source;
    my $reader = \&FSM::Test::RustProxyFixture::_read_file;
    my $finish = \&NativeProxyObservationRelease::_finish_locked;
    no warnings 'redefine';
    local *NativeProxyImageCustody::_source = sub {
        my $path = _allowed_read($_[0]);
        push @{$ROW->{events}}, 'source_request:'.scalar(@{$ROW->{source_requests}});
        push @{$ROW->{source_requests}}, {path => $path, mode => $_[1], limit => $_[2]};
        my $value = $source->(@_);
        _handle($value->{handle}, 'source', $value->{path}, $value);
        return $value;
    };
    local *FSM::Test::RustProxyFixture::_read_file = sub {
        push @{$ROW->{events}}, 'read:'.scalar(@{$ROW->{reads}});
        push @{$ROW->{reads}}, _allowed_read($_[0]);
        return $reader->(@_);
    };
    local *NativeProxyObservationRelease::_finish_locked = sub {
        die "controlled failure after exact unlink\n" if $CONTROL eq 'before-finish' || $CONTROL eq 'primary-and-source-close';
        goto &$finish;
    };
    local *NativeProxyImagePublication::_write_payload = sub { $ROW->{forbidden_mutation_attempts}++; die 'release attempted publication'; };
    {
        local $ACTIVE = 1;
        push @{$ROW->{events}}, 'operation:begin';
        my $ok = eval {
            if ($CONTROL eq 'direct-coordinator') {
                $ROW->{result} = NativeProxyImageCoordination::_transaction($CASE, 'release_observation_reference', {});
            } elsif ($CONTROL eq 'direct-unlink') {
                $ROW->{result} = NativeProxyObservationRelease::_unlink_exact({});
            } else {
                $ROW->{result} = NativeProxyObservationRelease::release_observation_reference(@$arguments);
            }
            push @{$ROW->{events}}, 'operation:end';
            1;
        };
        my $error = $@; $error =~ s/\Q$ROOT\E/./g;
        $ROW->{error} = $error; $ROW->{returned} = $ok ? 1 : 0;
        if ($ok && ref($ROW->{result}) eq 'HASH') { $ROW->{result}{error} =~ s/\Q$ROOT\E/./g; }
    }
    $ROW->{handles} = [map {
        my %copy = %$_; delete $copy{handle};
        $copy{closed_at_return} = defined(fileno($_->{handle})) ? 0 : 1;
        \%copy;
    } @HELD];
    $ROW->{all_observed_handles_closed} = (grep { !$_->{closed_at_return} } @{$ROW->{handles}}) ? 0 : 1;
    return $ROW;
}

1;
