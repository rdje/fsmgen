package NativeProxyArchiveReplacement;

use strict;
use warnings;
use Fcntl qw(F_GETFD FD_CLOEXEC);
use ArchiveTrace;
use ArchiveFixture;
use FSM::Test::ProcessSupervisor qw(repository_root);

my $ROOT = repository_root();

sub _witness {
    my @rows;
    # Borrow existing tracer aliases only inside this call. No extra owner
    # survives to turn lexical cleanup into an apparent implementation leak.
    for my $handle (sort { $a->{file_index} <=> $b->{file_index} }
            grep { $_->{kind} eq 'source' && defined(fileno($_->{handle})) }
            values %NativeProxyArchiveTrace::HANDLES) {
        my @descriptor = stat($handle->{handle});
        my @named = lstat("$ROOT/$handle->{path}");
        my $flags = fcntl($handle->{handle}, F_GETFD, 0);
        die "cannot witness admitted archive source\n" unless @descriptor && @named && defined($flags);
        push @rows, {label => $handle->{label}, path => $handle->{path},
            descriptor => fileno($handle->{handle}), metadata => \@descriptor, named => \@named,
            cloexec => ($flags & FD_CLOEXEC) ? 1 : 0};
    }
    return \@rows;
}

sub _replace {
    my ($context, $selection, $spec, $record) = @_;
    my $kind = $selection->{kind};
    my $path = $kind eq 'file' ? $spec->{files}[$selection->{index}]{path} : $spec->{archive_directory};
    my $retained = "$context->{evidence}{path}/displaced-".
        ($kind eq 'file' ? "source-$selection->{index}" : 'archive');
    die "replacement destination already exists\n" if -e "$ROOT/$retained" || -l "$ROOT/$retained";
    @$record{qw(path retained)} = ($path, $retained);
    rename("$ROOT/$path", "$ROOT/$retained") or die "retain original archive object: $!\n";
    $record->{original_retained} = 1;
    if ($kind eq 'directory') {
        mkdir("$ROOT/$path", 0700) or die "create replacement archive directory: $!\n";
        for my $file (@{$spec->{files}}) {
            die "replacement canonical file exists\n" if -e "$ROOT/$file->{path}" || -l "$ROOT/$file->{path}";
            NativeProxyArchiveFixture::write_bytes("$ROOT/$file->{path}", $file->{bytes}, 0400);
        }
    } else {
        die "replacement canonical file exists\n" if -e "$ROOT/$path" || -l "$ROOT/$path";
        NativeProxyArchiveFixture::write_bytes("$ROOT/$path", $spec->{files}[$selection->{index}]{bytes}, 0400);
    }
}

sub observe {
    die "expected inert context and replacement selection\n" unless @_ == 2;
    my ($context, $selection) = @_;
    my $spec = NativeProxyObservationArchiveRecord::archive_specification(
        $context->{store}{path}, $context->{request}, $context->{acquired});
    my $hits = 0;
    my $record;
    my $record_event = \&NativeProxyArchiveTrace::_event;
    no warnings 'redefine';
    local *NativeProxyArchiveTrace::_event = sub {
        $record_event->(@_);
        return unless defined($selection->{selector}) && $_[0] eq $selection->{selector};
        die "replacement selector repeated\n" if $hits++;
        $record = {selector => $_[0], kind => $selection->{kind}, complete => 0, original_retained => 0};
        $record->{before} = NativeProxyArchiveFixture::footprint($context);
        $record->{descriptors_before} = _witness();
        my $ok = eval {
            _replace($context, $selection, $spec, $record);
            $record->{after} = NativeProxyArchiveFixture::footprint($context);
            $record->{descriptors_after} = _witness();
            $record->{complete} = 1;
            1;
        };
        $record->{error} = $@;
        die $record->{error} unless $ok;
    };
    my $operation = NativeProxyArchiveTrace::observe_archive($context);
    $operation->{replacement_hits} = $hits;
    $operation->{replacement} = $record;
    return $operation;
}

1;
