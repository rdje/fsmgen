package NativeProxyReferenceCensus;

use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use File::Spec;
use FSM::Test::ProcessSupervisor qw(repository_root);
use ImageCustody;
use RuntimeRecord;
use Coordination;

my $ROOT = repository_root();

# Inactive read-only reference semantics. Stale native IDs are preserved, never
# reinterpreted as current custody or used to release an owner's storage hold.
sub inspect_runtime_references {
    die "expected one inactive reference store\n" unless @_ == 1;
    return NativeProxyImageCoordination::_transaction($_[0], 'inspect_runtime_references');
}

sub _snapshot {
    my ($source) = @_;
    return {bytes => $source->{bytes}, identity => {
        path => File::Spec->abs2rel($source->{path}, $ROOT),
        device => $source->{metadata}[0], inode => $source->{metadata}[1],
        size_bytes => length($source->{bytes}), sha256 => sha256_hex($source->{bytes})}};
}

sub _image {
    my ($case, $key) = @_;
    my $entry = "$ROOT/$case/images/$key";
    my $directory = NativeProxyImageCustody::_directory($entry);
    my (@inputs, $snapshot);
    my $ok = eval {
        push @inputs, NativeProxyImageCustody::_source("$entry/rustup.c", 0400, 65_536);
        push @inputs, NativeProxyImageCustody::_source("$entry/rustup", 0500, 65_536);
        $snapshot = NativeProxyImageCustody::read_entry($case, $key, map { $_->{bytes} } @inputs);
        for my $index (0, 1) {
            NativeProxyImageCustody::_recheck_source($inputs[$index]);
            my $identity = $snapshot->{snapshots}[$index]{identity};
            die "image input identity changed\n" unless $identity->{device} == $inputs[$index]{metadata}[0]
                && $identity->{inode} == $inputs[$index]{metadata}[1];
        }
        die "referenced image directory changed\n" unless NativeProxyImageCustody::_same_metadata(
            $directory, NativeProxyImageCustody::_directory($entry), 0,1,2,4);
        1;
    };
    my $error = $@;
    my $close_error = '';
    for my $source (@inputs) {
        $close_error ||= "cannot close image input: $!\n" unless close($source->{handle});
    }
    die $error unless $ok;
    die $close_error if length($close_error);
    return {snapshot => $snapshot, directory => $directory};
}

sub _matches_image {
    my ($record, $image) = @_;
    for my $index (0, 1) {
        my $historical = $record->{selected_sources}[$index];
        my $current = $image->{snapshot}{snapshots}[$index]{identity};
        die "reference content differs from complete image\n"
            unless $historical->{size_bytes} == $current->{size_bytes}
                && $historical->{sha256} eq $current->{sha256};
    }
    # Device/inode differences are deliberately retained as historical IDs.
    # Acquiring or releasing a caller's reference needs separate fresh custody.
}

sub _filename_key {
    my ($name, $record) = @_;
    die "global reference filename differs from record key\n"
        unless $name eq "$record->{reference_key}.json";
}

sub _closure {
    my ($case, $names, $sources, $images) = @_;
    my $current = NativeProxyImageCoordination::_names("$ROOT/$case/references", 128);
    my %expected = map { $_ => 1 } @$names;
    die "reference membership changed\n" unless @$current == @$names
        && !grep { !$expected{$_} } @$current;
    for my $source (@$sources) {
        NativeProxyImageCustody::_recheck_source($source);
        my $fresh = NativeProxyImageCustody::_source($source->{path}, 0400, 4096);
        my $ok = eval {
            die "reference identity or bytes changed\n" unless $source->{bytes} eq $fresh->{bytes}
                && NativeProxyImageCustody::_same_metadata(
                    $source->{metadata}, $fresh->{metadata}, 0,1,2,3,4,7,9,10);
            NativeProxyImageCustody::_recheck_source($fresh);
            1;
        };
        my $error = $@;
        my $closed = close($fresh->{handle});
        die $error unless $ok;
        die "cannot close fresh reference: $!\n" unless $closed;
    }
    for my $key (sort keys %$images) {
        my $before = $images->{$key};
        my $after = _image($case, $key);
        die "referenced image directory replaced\n" unless NativeProxyImageCustody::_same_metadata(
            $before->{directory}, $after->{directory}, 0,1,2,4);
        for my $index (0, 1, 2) {
            my $a = $before->{snapshot}{snapshots}[$index];
            my $b = $after->{snapshot}{snapshots}[$index];
            die "referenced source replaced or changed\n" unless $a->{bytes} eq $b->{bytes}
                && $a->{identity}{device} == $b->{identity}{device}
                && $a->{identity}{inode} == $b->{identity}{inode};
        }
    }
}

sub _inspect_locked {
    die "reference inspection requires the sealed coordinator\n"
        unless caller eq 'NativeProxyImageCoordination';
    my ($case, $census) = @_;
    my (@sources, @references, %images);
    my %available = map { $_ => 1 } @{$census->{images}};
    my $ok = eval {
        for my $name (@{$census->{references}}) {
            my $source = NativeProxyImageCustody::_source("$ROOT/$case/references/$name", 0400, 4096);
            push @sources, $source;
            my $record = NativeProxyRuntimeRecord::decode_runtime_record($case, $source->{bytes});
            _filename_key($name, $record);
            my $key = $record->{image_key};
            die "reference names an absent image\n" unless $available{$key};
            $images{$key} //= _image($case, $key);
            _matches_image($record, $images{$key});
            NativeProxyImageCustody::_recheck_source($source);
            push @references, {record => $record, source => _snapshot($source)};
        }
        _closure($case, $census->{references}, \@sources, \%images);
        1;
    };
    my $error = $@;
    my $close_error = '';
    for my $source (@sources) {
        $close_error ||= "cannot close runtime reference: $!\n" unless close($source->{handle});
    }
    die $error unless $ok;
    die $close_error if length($close_error);
    return {references => \@references,
        images => [map { $images{$_}{snapshot} } sort keys %images],
        retention => 'all_valid_runtime_records_retained; stale_owners_not_released'};
}

1;
