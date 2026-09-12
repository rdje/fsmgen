package NativeProxyReleaseReadbackTrace;

use strict;
use warnings;
use Scalar::Util qw(refaddr);
use Fcntl qw(F_GETFD FD_CLOEXEC);
use ReadbackCore;
use CallFaultTrace;

my $ROOT = FSM::Test::ProcessSupervisor::repository_root();
our ($ACTIVE, $ROW, $SELECTION, $HITS);

sub _observe_reader {
    my ($original, $arguments) = @_;
    die "selected reader requires its fixed open-handle contract\n"
        unless @$arguments == 2 && $arguments->[1] == 1
            && $arguments->[0] eq "$ROOT/$SELECTION->{path}";
    die "selected source read repeated\n" if $HITS++;
    my $row = $ROW->{reader} = {events => [], reads => [], recovery => [],
        reader_returned => 0, reader_error => '', observation_error => '', result => undef};
    local $NativeProxyReleaseReadbackCore::ROW = $row;
    local $NativeProxyReleaseReadbackCore::SELECTION = {%$SELECTION, absolute_path => $arguments->[0]};
    my (@values, $reader_error, $reader_errno, $reader_status, $returned);
    {
        local $NativeProxyReleaseReadbackCore::ACTIVE = 1;
        $returned = eval { @values = $original->(@$arguments); 1 };
        ($reader_error, $reader_errno, $reader_status) = ($@, 0 + $!, $?);
    }
    $row->{reader_returned} = $returned ? 1 : 0;
    $row->{reader_error} = $reader_error;
    push @{$row->{events}}, 'reader:return';
    my $observed = eval {
        die "selected reader supplied no observable descriptor\n" unless exists($row->{opened});
        $row->{weak_alive_at_return} = defined($row->{weak_alias}) ? 1 : 0;
        $row->{weak_open_at_return} = defined($row->{weak_alias}) && defined(fileno($row->{weak_alias})) ? 1 : 0;
        $row->{cloexec_at_reader_return} = undef;
        if ($row->{weak_open_at_return}) {
            my $flags = fcntl($row->{weak_alias}, F_GETFD, 0);
            die "cannot inspect reader-return inheritance flags\n" unless defined($flags);
            $row->{cloexec_at_reader_return} = ($flags & FD_CLOEXEC) ? 1 : 0;
        }
        $row->{at_reader_return} = NativeProxyReleaseReadbackCore::probe($row->{opened}{descriptor});
        if ($returned) {
            die "selected reader changed return arity\n" unless @values == 3;
            $row->{result} = {bytes_hex => unpack('H*', $values[0]),
                bytes_utf8 => utf8::is_utf8($values[0]) ? 1 : 0,
                metadata => $values[1], descriptor => defined($values[2]) ? fileno($values[2]) : undef};
        }
        1;
    };
    my $observation_error = $@;
    $row->{observation_error} = $observation_error;
    $row->{observation_completed} = $observed ? 1 : 0;
    ($!, $?) = ($reader_errno, $reader_status);
    # Observation never replaces an already captured original reader failure.
    die $reader_error unless $returned;
    die $observation_error unless $observed;
    return @values;
}

sub observe {
    my ($context, $arguments, $entries, $sealed, $flow, $selected) = @_;
    die "readback hooks were not installed after module loading\n" unless $NativeProxyReleaseReadbackCore::INSTALLED;
    die "nested release readback observation\n" if $ACTIVE;
    local ($ROW, $SELECTION, $HITS, $ACTIVE) = ({reader => undef}, $selected, 0, 1);
    if (defined($selected)) {
        die "unknown selected readback control\n"
            unless $selected->{control} =~ /\A(?:first-eio|partial-eio|early-eof|body-xor|one-byte)\z/;
        die "strong readback alias is only a first-EIO calibration\n"
            if $selected->{strong_alias} && $selected->{control} ne 'first-eio';
    }
    my $reader = \&FSM::Test::RustProxyFixture::_read_file;
    no warnings 'redefine';
    local *FSM::Test::RustProxyFixture::_read_file = sub {
        my $frame = $NativeProxyReleaseCallFaultTrace::STACK->[-1];
        die "release reader has no current source frame\n" unless $frame
            && $frame->{name} eq 'NativeProxyImageCustody::_source';
        return $reader->(@_) unless defined($SELECTION) && $frame->{occurrence} == $SELECTION->{occurrence};
        die "readback selection differs from prospective current-input call\n"
            unless $frame->{id} == $SELECTION->{call_id} && $frame->{path} eq $SELECTION->{path};
        return _observe_reader($reader, \@_);
    };
    my $operation = NativeProxyReleaseCallFaultTrace::observe($context, $arguments, $entries, $sealed, $flow, undef);
    $operation->{readback_hits} = $HITS;
    my $row = $ROW->{reader};
    $operation->{readback} = $row;
    if (defined($row)) {
        my $error = '';
        my $ok = eval {
            die "selected reader has no recorded descriptor at release return\n" unless exists($row->{opened});
            $row->{weak_open_at_release_return} = defined($row->{weak_alias}) && defined(fileno($row->{weak_alias})) ? 1 : 0;
            $row->{at_release_return} = NativeProxyReleaseReadbackCore::probe($row->{opened}{descriptor});
            1;
        };
        $error = $@ unless $ok;
        if (defined($row->{strong_alias}) && defined(fileno($row->{strong_alias}))) {
            my $recovered = eval {
                my $handle = $row->{strong_alias};
                my @native = stat($handle);
                die "strong-alias recovery lost its owned handle\n" unless exists($row->{opened}) && @native
                    && refaddr($handle) == refaddr($row->{weak_alias})
                    && fileno($handle) == $row->{opened}{descriptor}
                    && $native[0] == $row->{opened}{metadata}[0] && $native[1] == $row->{opened}{metadata}[1];
                $! = 0; my $closed = CORE::close($handle); my $close_errno = 0 + $!;
                push @{$row->{recovery}}, {role => 'observer_strong_counterexample',
                    returned => $closed ? 1 : 0, errno => $close_errno,
                    closed_after_call => defined(fileno($handle)) ? 0 : 1};
                1;
            };
            $error ||= $@ unless $recovered;
        }
        $row->{after_recovery} = undef;
        if ($selected->{strong_alias} && exists($row->{opened})) {
            my $probed = eval { $row->{after_recovery} = NativeProxyReleaseReadbackCore::probe($row->{opened}{descriptor}); 1 };
            $error ||= $@ unless $probed;
        }
        $row->{post_observation_error} = $error;
        $row->{reader_error} =~ s/\Q$ROOT\E/./g;
        $row->{observation_error} =~ s/\Q$ROOT\E/./g;
        $row->{post_observation_error} =~ s/\Q$ROOT\E/./g;
        delete @$row{qw(weak_alias strong_alias)};
    }
    return $operation;
}

1;
