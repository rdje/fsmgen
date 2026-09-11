package NativeProxyArchiveWriteTrace;

use strict;
use warnings;
our ($ACTIVE, $SELECTION, $FILES, $CALLS, $HITS, $LIMIT);
our %ORDINALS;

# Install before ArchiveTrace loads the unchanged Publication implementation.
BEGIN {
    *CORE::GLOBAL::syswrite = sub (*$;$$) {
        if ($ACTIVE && $NativeProxyArchiveTrace::ACTIVE && caller eq 'NativeProxyImagePublication') {
            return _write(@_);
        }
        return @_ == 4 ? CORE::syswrite($_[0], $_[1], $_[2], $_[3])
            : @_ == 3 ? CORE::syswrite($_[0], $_[1], $_[2]) : CORE::syswrite($_[0], $_[1]);
    };
}

use Digest::SHA qw(sha256_hex);
use Errno qw(EIO);
use Fcntl qw(F_GETFD FD_CLOEXEC S_ISREG);
use Scalar::Util qw(refaddr);


sub _write {
    die "unexpected archive syswrite arity\n" unless @_ == 4;
    my ($writer, $bytes, $requested, $offset) = @_;
    die "archive write call capacity\n" unless @$CALLS < $LIMIT;
    my $handle = $NativeProxyArchiveTrace::HANDLES{refaddr($writer)};
    die "archive write has no observed writer\n" unless $handle && $handle->{kind} eq 'writer';
    my $index = $handle->{file_index};
    my $file = $FILES->[$index];
    my $expected = $file->{bytes};
    die "archive write buffer or range differs\n" unless $bytes eq $expected
        && !utf8::is_utf8($bytes) && $offset >= 0 && $offset < length($bytes)
        && $requested == length($bytes) - $offset;
    my @before = stat($writer);
    my $flags = CORE::fcntl($writer, F_GETFD, 0);
    die "archive write identity or offset differs\n" unless @before && S_ISREG($before[2])
        && $before[0] == $handle->{device} && $before[1] == $handle->{inode}
        && $before[7] == $offset && defined($flags) && ($flags & FD_CLOEXEC);
    my $selected = $index == $SELECTION->{file_index};
    my $fault_at;
    if ($selected && ($SELECTION->{mode} eq 'zero' || $SELECTION->{mode} eq 'error')) {
        my %offsets = (start => 0, one => 1, middle => int(length($bytes) / 2), last => length($bytes) - 1);
        die "unknown archive write offset\n" unless exists $offsets{$SELECTION->{offset}};
        $fault_at = $offsets{$SELECTION->{offset}};
        die "archive writer advanced beyond selected failure\n" if $offset > $fault_at || $HITS;
    }
    my $ordinal = $ORDINALS{$index} // 0;
    $ORDINALS{$index} = $ordinal + 1;
    my $row = {file_index => $index, call_index => $ordinal, path => $file->{path},
        descriptor => fileno($writer), device => $before[0], inode => $before[1],
        cloexec => 1, before_size => $before[7], buffer_bytes => length($bytes),
        buffer_sha256 => sha256_hex($bytes), requested => $requested, offset => $offset,
        syscall_performed => 0, actual_requested => 0, actual_return => undef, actual_errno => 0,
        accepted_hex => ''};
    my ($returned, $error);
    if (defined($fault_at) && $offset == $fault_at) {
        ++$HITS;
        $returned = $SELECTION->{mode} eq 'zero' ? 0 : undef;
        $error = EIO;
    } else {
        my $count = $requested;
        $count = $SELECTION->{chunk} if $selected && $count > $SELECTION->{chunk};
        $count = $fault_at - $offset if defined($fault_at) && $count > $fault_at - $offset;
        die "nonpositive actual archive write request\n" unless $count > 0;
        $! = 0;
        $returned = CORE::syswrite($writer, $bytes, $count, $offset);
        $error = 0 + $!;
        $row->{syscall_performed} = 1;
        $row->{actual_requested} = $count;
        $row->{actual_return} = $returned;
        $row->{actual_errno} = $error;
        $row->{accepted_hex} = unpack('H*', substr($bytes, $offset, $returned))
            if defined($returned) && $returned > 0;
    }
    my @after = stat($writer);
    die "archive writer lost after write\n" unless @after;
    @$row{qw(after_device after_inode after_size)} = @after[0, 1, 7];
    $row->{reported_return} = $returned; $row->{reported_errno} = $error;
    push @$CALLS, $row;
    $! = $error;
    return $returned;
}


sub observe {
    die "expected context, selection and call bound\n" unless @_ == 3;
    my ($context, $selection, $limit) = @_;
    die "nested archive write observation\n" if $ACTIVE;
    my $spec = NativeProxyObservationArchiveRecord::archive_specification(
        $context->{store}{path}, $context->{request}, $context->{acquired});
    local $FILES = $spec->{files}; local $SELECTION = $selection;
    local $LIMIT = $limit; local $CALLS = []; local $HITS = 0; local %ORDINALS;
    local $ACTIVE = 1;
    my $operation = NativeProxyArchiveTrace::observe_archive($context);
    $operation->{syswrites} = $CALLS;
    $operation->{write_fault_hits} = $HITS;
    return $operation;
}

1;
