package NativeProxyObservationArchive;

use strict;
use warnings;
use JSON::PP ();
use FSM::Test::ProcessSupervisor qw(repository_root);
use ArchiveRecord;
use ImageCustody;
use Publication;
use Coordination;
use ReferenceCensus;

my $ROOT = repository_root();
my $JSON = JSON::PP->new->canonical->ascii;
my $FILE_LIMIT = 64;
my $TOTAL_LIMIT = 4 * 1024 * 1024;

# Inactive filesystem archival only. The acquisition's original target paths
# are historical data. This module opens only its fixed evidence/archive paths.
# The returned receipt grants neither execution nor observation release.
sub _limits {
    my ($spec) = @_;
    my $total = 0;
    die "archive unique-file capacity exceeded\n" if @{$spec->{files}} > $FILE_LIMIT;
    for my $file (@{$spec->{files}}) {
        NativeProxyImageCustody::_bytes($file->{bytes}, 65_536);
        $total += length($file->{bytes});
        die "archive aggregate-byte capacity exceeded\n" if $total > $TOTAL_LIMIT;
    }
}

sub _directory_closure {
    my ($state) = @_;
    for my $directory (@{$state->{directories}}) {
        my $current = NativeProxyImageCustody::_directory("$ROOT/$directory->{path}");
        die "archive or evidence directory changed\n"
            unless NativeProxyImageCustody::_same_metadata($directory->{metadata}, $current, 0,1,2,4);
    }
}

sub _members {
    my ($state, $expected) = @_;
    my $names = NativeProxyImageCoordination::_names("$ROOT/$state->{spec}{archive_directory}", $FILE_LIMIT);
    die "archive has incomplete or unknown members\n"
        unless $JSON->encode($names) eq $JSON->encode([sort @$expected]);
}

sub _close_sources {
    my ($sources) = @_;
    my $error = '';
    for my $source (@$sources) {
        $error ||= "cannot close retained archive descriptor: $!\n" unless close($source->{handle});
    }
    return $error;
}

sub _source_closure {
    my ($state) = @_;
    for my $source (@{$state->{sources}}) {
        NativeProxyImageCustody::_recheck_source($source);
        my $fresh = NativeProxyImageCustody::_source($source->{path}, 0400, 65_536);
        my $ok = eval {
            die "archive reread bytes or native identity changed\n"
                unless $fresh->{bytes} eq $source->{bytes}
                    && NativeProxyImageCustody::_same_metadata(
                        $source->{metadata}, $fresh->{metadata}, 0,1,2,3,4,7,9,10);
            NativeProxyImageCustody::_recheck_source($fresh);
            1;
        };
        my $error = $@;
        my $closed = close($fresh->{handle});
        die $error unless $ok;
        die "cannot close archive reread descriptor: $!\n" unless $closed;
    }
    NativeProxyImageCustody::_recheck_source($_) for @{$state->{sources}};
}

sub _snapshot {
    my ($source) = @_;
    return NativeProxyReferenceCensus::_snapshot($source);
}

sub _receipt {
    my ($case, $request, $acquired, $state) = @_;
    my $archive = $state->{directories}[1];
    return NativeProxyObservationArchiveRecord::archive_receipt($case, $request, $acquired,
        {path => $archive->{path}, device => $archive->{metadata}[0], inode => $archive->{metadata}[1]},
        [map { _snapshot($_) } @{$state->{sources}}]);
}

sub archive_retained_sources {
    die "expected store, request and original retained acquisition\n" unless @_ == 3;
    my ($case, $request, $acquired) = @_;
    # Pure validation and full copies precede every filesystem lookup/write.
    my $spec = NativeProxyObservationArchiveRecord::archive_specification($case, $request, $acquired);
    _limits($spec);
    my $evidence = $spec->{evidence_directory_identity};
    my $prior = NativeProxyObservationAcquisition::_prior_directory($evidence, 'archive evidence');
    my $path = "$ROOT/$spec->{archive_directory}";
    my $exists = -e $path || -l $path;
    # Existing partial/unknown archives are never filled in or repaired. An
    # exclusive-creation race fails instead of changing routes mid-operation.
    unless ($exists) {
        NativeProxyObservationAcquisition::_prior_directory($evidence, 'archive evidence');
        mkdir($path, 0700) or die "cannot exclusively create archive directory: $!\n";
    }
    my $directory = NativeProxyImageCustody::_directory($path);
    my $state = {spec => $spec, sources => [], directories => [
        {path => $evidence->{path}, metadata => $prior},
        {path => $spec->{archive_directory}, metadata => $directory}]};
    my @names = map { "$_->{sha256}.source" } @{$spec->{files}};
    my @published;
    my $receipt;
    my $ok = eval {
        _directory_closure($state);
        _members($state, $exists ? \@names : []);
        for my $index (0..$#{$spec->{files}}) {
            my $file = $spec->{files}[$index];
            _directory_closure($state);
            my $written;
            unless ($exists) {
                _members($state, \@published);
                $written = NativeProxyImagePublication::_write_payload("$ROOT/$file->{path}", $file->{bytes}, 0400);
                push @published, $names[$index];
            }
            # Transfer ownership into the cleanup list immediately, before
            # any content/identity check that can throw.
            push @{$state->{sources}}, NativeProxyImageCustody::_source("$ROOT/$file->{path}", 0400, 65_536);
            my $source = $state->{sources}[-1];
            die "archive bytes differ from retained snapshot\n" unless $source->{bytes} eq $file->{bytes};
            die "new archive file differs from sealed writer\n" if $written
                && !NativeProxyImageCustody::_same_metadata($written, $source->{metadata}, 0,1,2,3,4,7);
            NativeProxyImageCustody::_recheck_source($source);
        }
        _members($state, \@names);
        _directory_closure($state);
        _source_closure($state);
        $receipt = _receipt($case, $request, $acquired, $state);
        _members($state, \@names);
        _directory_closure($state);
        NativeProxyImageCustody::_recheck_source($_) for @{$state->{sources}};
        1;
    };
    my $error = $@;
    my $close_error = _close_sources($state->{sources});
    die $error unless $ok;
    die $close_error if length($close_error);
    return $receipt;
}

1;
