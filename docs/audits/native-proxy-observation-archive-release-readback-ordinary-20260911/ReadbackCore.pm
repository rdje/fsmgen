package NativeProxyReleaseReadbackCore;

use strict;
use warnings;
use Errno qw(EIO EBADF);
use Fcntl qw(F_GETFD FD_CLOEXEC);
use POSIX ();
use Scalar::Util qw(refaddr weaken isweak);

our ($ACTIVE, $ROW, $SELECTION, $INITIAL_READ, $INSTALLED);

# Compile the original reader against a named sysread hook. ReleaseTrace installs
# sysopen before loading ImageCustody and thus RustProxyFixture. The later hooks
# below can then replace both names without rewriting the original reader.
BEGIN {
    die "readback hook loaded after the original reader\n" if $INC{'FSM/Test/RustProxyFixture.pm'};
    die "unexpected pre-existing read hook\n" if defined(&CORE::GLOBAL::sysread);
    *CORE::GLOBAL::sysread = sub (*$$;$) {
        return @_ == 3 ? CORE::sysread($_[0], $_[1], $_[2])
            : CORE::sysread($_[0], $_[1], $_[2], $_[3]);
    };
    $INITIAL_READ = \&CORE::GLOBAL::sysread;
}

# Same descriptor-probe mechanism as the qualified standalone lower-reader
# observer. Only observer-owned duplicates may be attached or closed here.
sub probe {
    my ($descriptor) = @_;
    die "invalid observed reader descriptor\n"
        unless defined($descriptor) && !ref($descriptor) && $descriptor =~ /\A(?:0|[1-9][0-9]*)\z/;
    $! = 0;
    my $duplicate = POSIX::dup($descriptor);
    my $error = 0 + $!;
    my $record = {descriptor => $descriptor, duplicate => defined($duplicate) ? 0 + $duplicate : undef,
        errno => $error, metadata => undef, duplicate_close => undef, duplicate_closed_probe => undef};
    return $record unless defined($duplicate);
    my $attached;
    my $ok = eval {
        CORE::open($attached, '<&=', $duplicate) or die "attach owned reader observer duplicate: $!\n";
        die "reader observer duplicate alias mismatch\n"
            unless fileno($attached) == $duplicate && $duplicate != $descriptor;
        my @native = stat($attached); die "stat reader observer duplicate: $!\n" unless @native;
        $record->{metadata} = \@native;
        1;
    };
    my $failure = $@;
    $! = 0;
    my $closed = defined($attached) && defined(fileno($attached))
        ? CORE::close($attached) : POSIX::close($duplicate);
    my $close_errno = 0 + $!;
    $record->{duplicate_close} = {returned => $closed ? 1 : 0, errno => $close_errno,
        attached_closed => defined($attached) && defined(fileno($attached)) ? 0 : 1};
    $! = 0;
    my $again = POSIX::dup($duplicate); my $again_errno = 0 + $!;
    $record->{duplicate_closed_probe} = {duplicate => defined($again) ? 0 + $again : undef, errno => $again_errno};
    if (defined($again)) {
        POSIX::close($again);
        POSIX::close($duplicate);
    }
    die $failure unless $ok;
    die "owned reader observer duplicate did not close\n"
        unless $closed && !defined($again) && $again_errno == EBADF;
    return $record;
}

sub _buffer {
    return {defined => defined($_[0]) ? 1 : 0,
        bytes_hex => defined($_[0]) ? unpack('H*', $_[0]) : undef,
        utf8 => defined($_[0]) && utf8::is_utf8($_[0]) ? 1 : 0};
}

sub install {
    die "readback hooks already installed\n" if $INSTALLED;
    die "release/readback load order differs\n" unless $INC{'ReleaseTrace.pm'}
        && $INC{'FSM/Test/RustProxyFixture.pm'} && defined(&CORE::GLOBAL::sysopen)
        && refaddr(\&CORE::GLOBAL::sysread) == refaddr($INITIAL_READ);
    my $open = \&CORE::GLOBAL::sysopen;
    my $read = \&CORE::GLOBAL::sysread;
    no warnings 'redefine';
    *CORE::GLOBAL::sysopen = sub (*$$;$) {
        goto &$open unless $ACTIVE && caller eq 'FSM::Test::RustProxyFixture';
        die "selected reader opened another path\n" unless $_[1] eq $SELECTION->{absolute_path};
        die "selected reader opened twice\n" if exists($ROW->{open});
        push @{$ROW->{events}}, 'open:before';
        $! = 0;
        my $ok = @_ == 3 ? CORE::sysopen($_[0], $_[1], $_[2]) : CORE::sysopen($_[0], $_[1], $_[2], $_[3]);
        my $error = 0 + $!;
        $ROW->{open} = {arity => scalar(@_), flags => 0 + $_[2], returned => $ok ? 1 : 0, errno => $error};
        if ($ok) {
            my @native = stat($_[0]); my $flags = fcntl($_[0], F_GETFD, 0);
            die "cannot inspect selected reader descriptor\n" unless @native && defined($flags);
            $ROW->{opened} = {descriptor => fileno($_[0]), metadata => \@native,
                cloexec => ($flags & FD_CLOEXEC) ? 1 : 0};
            $ROW->{weak_alias} = $_[0]; weaken($ROW->{weak_alias});
            $ROW->{alias_is_weak} = isweak($ROW->{weak_alias}) ? 1 : 0;
            $ROW->{strong_alias} = $_[0] if $SELECTION->{strong_alias};
        }
        push @{$ROW->{events}}, 'open:after';
        $! = $error;
        return $ok;
    };
    *CORE::GLOBAL::sysread = sub (*$$;$) {
        goto &$read unless $ACTIVE && caller eq 'FSM::Test::RustProxyFixture';
        die "selected read lost its exact handle\n" unless exists($ROW->{opened})
            && defined($ROW->{weak_alias}) && defined(fileno($_[0]))
            && fileno($_[0]) == $ROW->{opened}{descriptor}
            && refaddr($_[0]) == refaddr($ROW->{weak_alias});
        die "selected reader changed sysread arity\n" unless @_ == 3;
        my $index = @{$ROW->{reads}};
        my $mode = $SELECTION->{control};
        my $action = ($mode eq 'first-eio' && $index == 0) || ($mode eq 'partial-eio' && $index == 1)
            ? 'report-eio' : $mode eq 'early-eof' && $index == 0 ? 'report-eof'
            : ($mode eq 'partial-eio' || $mode eq 'one-byte') && $index == 0 ? 'delegate-one-byte'
            : $mode eq 'body-xor' && $index == 0 ? 'delegate-then-xor' : 'delegate';
        my $record = {index => $index, action => $action, requested => 0 + $_[2],
            delegated_requested => undef, actual => undef, reported => undef};
        push @{$ROW->{reads}}, $record;
        push @{$ROW->{events}}, "read:$index:before";
        my ($count, $error);
        if ($action eq 'report-eio') {
            $error = EIO;
        } elsif ($action eq 'report-eof') {
            ($count, $error, $_[1]) = (0, 0, '');
        } else {
            my $requested = $action eq 'delegate-one-byte' ? 1 : $_[2];
            $record->{delegated_requested} = 0 + $requested;
            $! = 0;
            $count = CORE::sysread($_[0], $_[1], $requested);
            $error = 0 + $!;
            $record->{actual} = {count => $count, errno => $error, buffer => _buffer($_[1])};
            if ($action eq 'delegate-then-xor') {
                die "body alteration requires a real nonempty read\n" unless defined($count) && $count > 0;
                substr($_[1], 0, 1, chr(ord(substr($_[1], 0, 1)) ^ 0x80));
            }
        }
        $record->{reported} = {count => $count, errno => $error, buffer => _buffer($_[1])};
        push @{$ROW->{events}}, "read:$index:after";
        $! = $error;
        return $count;
    };
    $INSTALLED = 1;
}

1;
