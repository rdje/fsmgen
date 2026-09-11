package NativeProxyLowerReaderTrace;

use strict;
use warnings;
use Fcntl qw(F_GETFD FD_CLOEXEC);
use POSIX ();
use Scalar::Util qw(refaddr weaken isweak);
use Errno qw(EIO EBADF);

our ($ACTIVE, $ROW, $EXPECTED_PATH, $SELECTION);

# Install before RustProxyFixture compiles. Every unselected call retains its
# original argument aliases, arity and return value.
BEGIN {
    *CORE::GLOBAL::sysopen = sub (*$$;$) {
        my $selected = $ACTIVE && caller eq 'FSM::Test::RustProxyFixture';
        die "unexpected lower-reader source path\n" if $selected && $_[1] ne $EXPECTED_PATH;
        push @{$ROW->{events}}, 'sysopen:before' if $selected;
        my $ok = @_ == 3 ? CORE::sysopen($_[0], $_[1], $_[2]) : CORE::sysopen($_[0], $_[1], $_[2], $_[3]);
        my $error = 0 + $!;
        if ($selected) {
            die "duplicate observed lower-reader open\n" if exists $ROW->{opened};
            $ROW->{open_return} = $ok ? 1 : 0;
            $ROW->{open_errno} = $error;
            if ($ok) {
                my @native = stat($_[0]);
                my $flags = fcntl($_[0], F_GETFD, 0);
                die "cannot inspect opened lower-reader descriptor\n" unless @native && defined($flags);
                $ROW->{opened} = {descriptor => fileno($_[0]), metadata => \@native,
                    cloexec => ($flags & FD_CLOEXEC) ? 1 : 0};
                $ROW->{weak_alias} = $_[0];
                weaken($ROW->{weak_alias});
                $ROW->{alias_is_weak} = isweak($ROW->{weak_alias}) ? 1 : 0;
                $ROW->{strong_alias} = $_[0] if $SELECTION->{strong_alias};
            }
            push @{$ROW->{events}}, 'sysopen:after';
        }
        $! = $error;
        return $ok;
    };
    *CORE::GLOBAL::sysread = sub (*$$;$) {
        return @_ == 3 ? CORE::sysread($_[0], $_[1], $_[2]) : CORE::sysread($_[0], $_[1], $_[2], $_[3])
            unless $ACTIVE && caller eq 'FSM::Test::RustProxyFixture';
        die "read without the observed lower descriptor\n" unless exists($ROW->{opened})
            && fileno($_[0]) == $ROW->{opened}{descriptor};
        my $index = @{$ROW->{reads}};
        push @{$ROW->{events}}, "sysread:$index:before";
        my $injected = $SELECTION->{fail_read} && $index == 0;
        my $count;
        if ($injected) { $! = EIO; }
        else { $count = @_ == 3 ? CORE::sysread($_[0], $_[1], $_[2]) : CORE::sysread($_[0], $_[1], $_[2], $_[3]); }
        my $error = 0 + $!;
        push @{$ROW->{reads}}, {index => $index, requested => $_[2], returned => $count,
            errno => $error, injected => $injected ? 1 : 0,
            chunk_defined => defined($_[1]) ? 1 : 0, chunk_hex => defined($_[1]) ? unpack('H*', $_[1]) : undef};
        push @{$ROW->{events}}, "sysread:$index:after";
        $! = $error;
        return $count;
    };
    *CORE::GLOBAL::close = sub (*) {
        return CORE::close($_[0]) unless $ACTIVE && caller eq 'FSM::Test::RustProxyFixture';
        die "close without the observed lower descriptor\n" unless exists($ROW->{opened})
            && defined(fileno($_[0])) && fileno($_[0]) == $ROW->{opened}{descriptor};
        push @{$ROW->{events}}, 'reader_close:before';
        my $ok = CORE::close($_[0]); my $error = 0 + $!;
        push @{$ROW->{reader_closes}}, {returned => $ok ? 1 : 0, errno => $error,
            closed_after_call => defined(fileno($_[0])) ? 0 : 1};
        push @{$ROW->{events}}, 'reader_close:after';
        $! = $error;
        return $ok;
    };
}

sub _probe {
    my ($descriptor) = @_;
    # dup never changes or closes the observed original descriptor.
    $! = 0;
    my $duplicate = POSIX::dup($descriptor);
    my $error = 0 + $!;
    my $row = {descriptor => $descriptor, duplicate => defined($duplicate) ? 0 + $duplicate : undef,
               errno => $error, metadata => undef, duplicate_close => undef, duplicate_closed_probe => undef};
    return $row unless defined($duplicate);
    my $attached;
    my $ok = eval {
        CORE::open($attached, '<&=', $duplicate) or die "attach owned observer duplicate: $!\n";
        die "observer duplicate alias mismatch\n" unless fileno($attached) == $duplicate && $duplicate != $descriptor;
        my @native = stat($attached); die "stat owned observer duplicate: $!\n" unless @native;
        $row->{metadata} = \@native;
        1;
    };
    my $failure = $@;
    $! = 0;
    my $closed = defined($attached) && defined(fileno($attached)) ? CORE::close($attached) : POSIX::close($duplicate);
    my $close_errno = 0 + $!;
    $row->{duplicate_close} = {returned => $closed ? 1 : 0, errno => $close_errno,
        attached_closed => defined($attached) && defined(fileno($attached)) ? 0 : 1};
    $! = 0;
    my $again = POSIX::dup($duplicate); my $again_errno = 0 + $!;
    $row->{duplicate_closed_probe} = {duplicate => defined($again) ? 0 + $again : undef, errno => $again_errno};
    # If a close unexpectedly failed, recover only the observer-owned objects,
    # keep the failed record and propagate failure instead of claiming closure.
    if (defined($again)) {
        POSIX::close($again);
        POSIX::close($duplicate);
    }
    die $failure unless $ok;
    die "owned observer duplicate did not close\n" unless $closed && !defined($again) && $again_errno == EBADF;
    return $row;
}

sub observe {
    die "expected absolute source path and closed selection\n" unless @_ == 2;
    my ($path, $selection) = @_;
    die "nested lower-reader observation\n" if $ACTIVE;
    local $ROW = {events => [], reads => [], reader_closes => [], cleanup => [],
                  reader_returned => 0, reader_error => '', observer_error => '', result => undef};
    local $EXPECTED_PATH = $path;
    local $SELECTION = $selection;
    my @result;
    {
        local $ACTIVE = 1;
        my $ok = eval { @result = FSM::Test::RustProxyFixture::_read_file($path, $selection->{keep_open}); 1 };
        $ROW->{reader_error} = $@;
        $ROW->{reader_returned} = $ok ? 1 : 0;
    }
    push @{$ROW->{events}}, 'reader:return';
    my $observation_ok = eval {
        die "lower reader did not supply an observed descriptor\n" unless exists($ROW->{opened});
        $ROW->{weak_alive_at_return} = defined($ROW->{weak_alias}) ? 1 : 0;
        $ROW->{weak_open_at_return} = defined($ROW->{weak_alias}) && defined(fileno($ROW->{weak_alias})) ? 1 : 0;
        $ROW->{cloexec_at_reader_return} = undef;
        if ($ROW->{weak_open_at_return}) {
            my $flags = fcntl($ROW->{weak_alias}, F_GETFD, 0);
            die "cannot inspect returned lower-reader flags\n" unless defined($flags);
            $ROW->{cloexec_at_reader_return} = ($flags & FD_CLOEXEC) ? 1 : 0;
        }
        $ROW->{at_reader_return} = _probe($ROW->{opened}{descriptor});
        if ($ROW->{reader_returned}) {
            $ROW->{result} = {bytes_hex => unpack('H*', $result[0]), metadata => $result[1],
                descriptor => defined($result[2]) ? fileno($result[2]) : undef};
        }
        1;
    };
    $ROW->{observer_error} = $@;
    # These are explicit caller/control cleanup operations, recorded after the
    # reader-return verdict. They never change the original liveness record.
    my @owned = ([returned => $result[2]], [strong_counterexample => $ROW->{strong_alias}]);
    my %seen;
    for my $entry (@owned) {
        my ($role, $handle) = @$entry;
        next unless defined($handle) && defined(fileno($handle));
        next if $seen{refaddr($handle)}++;
        my $descriptor = fileno($handle);
        $! = 0;
        my $ok = CORE::close($handle); my $error = 0 + $!;
        push @{$ROW->{cleanup}}, {role => $role, descriptor => $descriptor,
            returned => $ok ? 1 : 0, errno => $error, closed_after_call => defined(fileno($handle)) ? 0 : 1};
    }
    if (exists($ROW->{opened})) {
        my $ok = eval { $ROW->{after_cleanup} = _probe($ROW->{opened}{descriptor}); 1 };
        $ROW->{observer_error} ||= $@ unless $ok;
    }
    delete @$ROW{qw(weak_alias strong_alias)};
    $ROW->{observer_completed} = $observation_ok && !length($ROW->{observer_error}) ? 1 : 0;
    return $ROW;
}

1;
