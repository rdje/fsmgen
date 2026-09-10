package NativeProxyImageMaintenance;

use strict;
use warnings;
use Errno qw(ENOENT);
use JSON::PP ();
use FSM::Test::ProcessSupervisor qw(repository_root);
use ImageCustody;
use RuntimeRecord;
use ReferenceCensus;

my $ROOT = repository_root();
my $JSON = JSON::PP->new->canonical->ascii;

# Explicit inactive maintenance only: acquisition and runtime retirement never
# invoke this operation. Unknown reference variants and partial images reject.
sub remove_unreferenced_image {
    die "expected inactive store and one selected image key\n" unless @_ == 2;
    return NativeProxyImageCoordination::_transaction($_[0], 'remove_unreferenced_image', $_[1]);
}

sub _request { NativeProxyRuntimeRecord::_digest($_[0]); }

sub _all_images {
    my ($case, $names) = @_;
    return [map { NativeProxyReferenceCensus::_image($case, $_) } @$names];
}

sub _same_image {
    my ($before, $after) = @_;
    return NativeProxyImageCustody::_same_metadata($before->{directory}, $after->{directory}, 0,1,2,4)
        && $JSON->encode($before->{snapshot}) eq $JSON->encode($after->{snapshot});
}

sub _referenced {
    my ($references, $key) = @_;
    return scalar(grep { $_->{record}{image_key} eq $key } @{$references->{references}});
}

sub _admit_locked {
    die "image maintenance admission requires the sealed coordinator\n"
        unless caller eq 'NativeProxyImageCoordination';
    my ($case, $census, $references, $key) = @_;
    my $images = _all_images($case, $census->{images});
    my ($candidate) = grep { $_->{snapshot}{key} eq $key } @$images;
    die "selected maintenance image is absent\n" unless defined($candidate);
    die "selected image is retained by an unresolved reference\n"
        if _referenced($references, $key);
    return {key => $key, images => $images, candidate => $candidate,
            references => $references, names => [@{$census->{images}}]};
}

sub _closure_locked {
    die "image maintenance closure requires the sealed coordinator\n"
        unless caller eq 'NativeProxyImageCoordination';
    my ($case, $plan, $census, $references) = @_;
    die "image or reference membership changed before maintenance\n"
        unless $JSON->encode($plan->{names}) eq $JSON->encode($census->{images})
            && $JSON->encode($plan->{references}) eq $JSON->encode($references);
    my $images = _all_images($case, $census->{images});
    for my $index (0..$#$images) {
        die "image bytes or identity changed before maintenance\n"
            unless _same_image($plan->{images}[$index], $images->[$index]);
    }
}

sub _absent {
    my ($path) = @_;
    my @metadata = lstat("$ROOT/$path");
    return 0 if @metadata;
    die "cannot establish maintained path absence: $!\n" unless $! == ENOENT;
    return 1;
}

sub _directory {
    my ($case, $plan) = @_;
    my $path = "$ROOT/$case/images/$plan->{key}";
    die "maintenance candidate directory changed\n"
        unless NativeProxyImageCustody::_same_metadata(
            $plan->{candidate}{directory}, NativeProxyImageCustody::_directory($path), 0,1,2,4);
}

sub _source {
    my ($snapshot, $mode, $limit) = @_;
    my $source = NativeProxyImageCustody::_source("$ROOT/$snapshot->{identity}{path}", $mode, $limit);
    my $ok = eval {
        NativeProxyImageCustody::_recheck_source($source);
        die "maintenance candidate source changed\n"
            unless $JSON->encode(NativeProxyReferenceCensus::_snapshot($source)) eq $JSON->encode($snapshot);
        1;
    };
    my $error = $@;
    my $closed = close($source->{handle});
    die $error unless $ok;
    die "cannot close maintenance source: $!\n" unless $closed;
}

sub _unlink { unlink("$ROOT/$_[0]") == 1 or die "cannot unlink selected image source: $!\n"; }
sub _rmdir { rmdir("$ROOT/$_[0]") or die "cannot remove selected image directory: $!\n"; }

sub _remove_locked {
    die "image removal requires the sealed coordinator\n" unless caller eq 'NativeProxyImageCoordination';
    my ($case, $plan) = @_;
    my $snapshots = $plan->{candidate}{snapshot}{snapshots};
    # Leave any partial deletion visible and failed. Never repair, rename,
    # recreate, retry, or remove a reference to make this candidate eligible.
    for my $item ([$snapshots->[0], 0400, 65_536], [$snapshots->[2], 0400, 4096],
                  [$snapshots->[1], 0500, 65_536]) {
        _directory($case, $plan);
        _source(@$item);
        my $path = $item->[0]{identity}{path};
        _unlink($path);
        die "removed image source remains present\n" unless _absent($path);
    }
    _directory($case, $plan);
    my $directory = "$case/images/$plan->{key}";
    _rmdir($directory);
    die "removed image directory remains present\n" unless _absent($directory);
}

sub _finish_locked {
    die "maintenance result requires the sealed coordinator\n" unless caller eq 'NativeProxyImageCoordination';
    my ($case, $plan, $census, $references) = @_;
    my @remaining = grep { $_ ne $plan->{key} } @{$plan->{names}};
    die "maintenance changed other images or reference custody\n"
        unless $JSON->encode(\@remaining) eq $JSON->encode($census->{images})
            && $JSON->encode($references) eq $JSON->encode($plan->{references});
    my $images = _all_images($case, $census->{images});
    my @prior = grep { $_->{snapshot}{key} ne $plan->{key} } @{$plan->{images}};
    for my $index (0..$#$images) {
        die "maintenance changed a retained image\n" unless _same_image($prior[$index], $images->[$index]);
    }
    die "maintained image reappeared\n" unless _absent("$case/images/$plan->{key}");
    return {removed_image => $plan->{key}, removed_sources => $plan->{candidate}{snapshot}{snapshots}};
}

1;
