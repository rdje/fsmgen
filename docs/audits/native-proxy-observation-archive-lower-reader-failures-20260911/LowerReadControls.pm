package NativeProxyLowerReadControls;

use strict;
use warnings;
use Errno qw(EIO);
use Digest::SHA qw(sha256_hex);
use LowerReaderTrace;

BEGIN {
    my $original_read = \&CORE::GLOBAL::sysread;
    no warnings 'redefine';
    *CORE::GLOBAL::sysread = sub (*$$;$) {
        goto &$original_read unless $NativeProxyLowerReaderTrace::ACTIVE
            && caller eq 'FSM::Test::RustProxyFixture';
        my $row = $NativeProxyLowerReaderTrace::ROW;
        my $selection = $NativeProxyLowerReaderTrace::SELECTION;
        my $index = @{$row->{reads}};
        my $control = $selection->{control};
        my $action = $control eq 'partial-eio' && $index == 0 ? 'one-byte-delegation'
            : $control eq 'partial-eio' && $index == 1 ? 'injected-eio'
            : $control eq 'early-eof' && $index == 0 ? 'injected-eof'
            : $control eq 'named-replacement' && $index == 1 ? 'replace-then-delegate'
            : 'delegate';
        my $record = {index => $index, caller_requested => 0 + $_[2],
            delegated_requested => $action eq 'one-byte-delegation' ? 1
                : $action =~ /\Ainjected-/ ? undef : 0 + $_[2], action => $action};
        push @{$row->{read_controls}}, $record;
        if ($action eq 'injected-eio' || $action eq 'injected-eof') {
            die "controlled read without its admitted source\n" unless defined(fileno($_[0]))
                && fileno($_[0]) == $row->{opened}{descriptor};
            push @{$row->{events}}, "sysread:$index:before";
            my ($count, $error);
            if ($action eq 'injected-eio') { $error = EIO; }
            else { $count = 0; $error = 0; $_[1] = ''; }
            push @{$row->{reads}}, {index => $index, requested => 0 + $_[2], returned => $count,
                errno => $error, injected => 1, chunk_defined => defined($_[1]) ? 1 : 0,
                chunk_hex => defined($_[1]) ? unpack('H*', $_[1]) : undef};
            push @{$row->{events}}, "sysread:$index:after";
            $! = $error;
            return $count;
        }
        _replace_named() if $action eq 'replace-then-delegate';
        # Replace only the request slot; retain the caller's buffer alias and
        # avoid assigning through a potentially read-only expression argument.
        splice @_, 2, 1, 1 if $action eq 'one-byte-delegation';
        # The qualified hook checks its immediate caller. A normal sub call
        # here would bypass that instrumentation; the tail call preserves it.
        goto &$original_read;
    };
}

sub _replace_named {
    my $row = $NativeProxyLowerReaderTrace::ROW;
    my $path = $NativeProxyLowerReaderTrace::EXPECTED_PATH;
    die "named replacement repeated or premature\n" if exists($row->{named_replacement}) || @{$row->{reads}} != 1;
    die "named replacement lost its admitted descriptor\n" unless defined($row->{weak_alias})
        && defined(fileno($row->{weak_alias})) && fileno($row->{weak_alias}) == $row->{opened}{descriptor};
    my @before = lstat($path); my @descriptor_before = stat($row->{weak_alias});
    die "named replacement cannot inspect original\n" unless @before && @descriptor_before;
    my $read = $row->{reads}[0];
    my $bytes = pack('H*', $read->{chunk_hex});
    die "named replacement requires the complete original read\n" unless defined($read->{returned})
        && $read->{returned} == length($bytes) && length($bytes) == $before[7] && !$read->{injected};
    my $retained = "$path.retained-original";
    die "named replacement retained destination exists\n" if -e $retained || -l $retained;
    my $record = $row->{named_replacement} = {complete => 0, source_before => \@before,
        descriptor_before => \@descriptor_before, bytes_sha256 => sha256_hex($bytes),
        retained_basename => 'source.data.retained-original'};
    rename($path, $retained) or die "retain original lower-reader source: $!\n";
    open my $writer, '>:raw', $path or die "write lower-reader replacement: $!\n";
    my $written = eval { print {$writer} $bytes or die "write replacement bytes: $!\n"; 1 };
    my $error = $@; my $closed = close($writer);
    die $error unless $written; die "close lower-reader replacement: $!\n" unless $closed;
    chmod(0400, $path) == 1 or die "seal lower-reader replacement: $!\n";
    my @named = lstat($path); my @saved = lstat($retained); my @descriptor = stat($row->{weak_alias});
    die "cannot inspect lower-reader replacement\n" unless @named && @saved && @descriptor;
    @$record{qw(named_after retained_after descriptor_after complete)} = (\@named, \@saved, \@descriptor, 1);
}

1;
