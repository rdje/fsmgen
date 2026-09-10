package NativeProxyImagePublication;

use strict;
use warnings;

use Fcntl qw(O_CREAT O_EXCL O_NOFOLLOW O_RDWR S_ISREG F_GETFD F_SETFD FD_CLOEXEC);
use File::Spec;
use FSM::Test::ProcessSupervisor qw(repository_root);
use ImageCustody;
use Coordination;

my $ROOT = repository_root();
my $IMAGE_LIMIT = 32;

# Inactive byte publication only. Inputs are inert qualification bytes, not
# compiler attestations. No runtime reference or executable authorization is
# created here. The fixed transaction always releases coordination before return.
sub publish_image {
    die "expected inactive root and bounded C/image bytes\n" unless @_ == 3;
    my ($case, $c, $image) = @_;
    return NativeProxyImageCoordination::_transaction($case, 'publish_image', $c, $image);
}

sub _write_payload {
    my ($path, $bytes, $mode) = @_;
    sysopen(my $writer, $path, O_RDWR | O_CREAT | O_EXCL | O_NOFOLLOW, 0400)
        or die "cannot exclusively create canonical payload: $!\n";
    my $source;
    my $sealed_identity;
    my $ok = eval {
        binmode($writer) or die "cannot select canonical byte mode: $!\n";
        my $flags = fcntl($writer, F_GETFD, 0);
        die "cannot read canonical writer flags: $!\n" unless defined $flags;
        fcntl($writer, F_SETFD, $flags | FD_CLOEXEC)
            or die "cannot seal canonical writer inheritance: $!\n";
        my $offset = 0;
        while ($offset < length($bytes)) {
            my $written = syswrite($writer, $bytes, length($bytes) - $offset, $offset);
            die "cannot write complete canonical bytes: $!\n" unless defined($written) && $written > 0;
            $offset += $written;
        }
        # Read through the already qualified bounded descriptor mechanism, then
        # bind that read back to the original writer before sealing its inode.
        $source = NativeProxyImageCustody::_source($path, 0400,
            $path =~ /\/image\.json\z/ ? 4096 : 65_536);
        my @written = stat($writer);
        die "canonical writer identity or bytes changed\n"
            unless $source->{bytes} eq $bytes
                && NativeProxyImageCustody::_same_metadata(
                    \@written, $source->{metadata}, 0,1,2,3,4,7);
        NativeProxyImageCustody::_recheck_source($source);
        _seal_payload($writer, $mode);
        my @sealed = stat($writer);
        my @named = lstat($path);
        die "canonical payload changed during sealing\n"
            unless NativeProxyImageCustody::_same_metadata(\@sealed, \@named, 0,1,2,3,4,7)
                && $sealed[0] == $written[0] && $sealed[1] == $written[1]
                && S_ISREG($sealed[2]) && ($sealed[2] & 07777) == $mode
                && $sealed[3] == 1 && $sealed[7] == length($bytes);
        $sealed_identity = \@sealed;
        1;
    };
    my $error = $@;
    my $close_error = '';
    if ($source && !close($source->{handle})) { $close_error = "cannot close canonical reader: $!\n"; }
    if (!close($writer)) { $close_error ||= "cannot close canonical writer: $!\n"; }
    die $error unless $ok;
    die $close_error if length($close_error);
    return $sealed_identity;
}

sub _seal_payload {
    my ($writer, $mode) = @_;
    chmod($mode, $writer) == 1 or die "cannot seal canonical payload: $!\n";
}

sub _publish_locked {
    die "canonical publication requires the sealed coordinator\n"
        unless caller eq 'NativeProxyImageCoordination';
    my ($case, $census, $c, $image) = @_;
    my $key = NativeProxyImageCustody::image_key($c, $image);
    my $entry = File::Spec->catdir($ROOT, $case, 'images', $key);
    if (-e $entry || -l $entry) {
        # A hash only routes lookup. Existing partial, corrupt or colliding
        # objects fail; nothing is overwritten or repaired on this path.
        my $snapshot = NativeProxyImageCustody::read_entry($case, $key, $c, $image);
        return {created => 0, image => $snapshot};
    }
    die "image publication capacity exceeded\n" if @{$census->{images}} >= $IMAGE_LIMIT;
    mkdir($entry, 0700) or die "cannot exclusively create canonical image directory: $!\n";
    my $directory_identity = NativeProxyImageCustody::_directory($entry);
    # The executable has its final name from creation. Its execute permission
    # appears only after source/manifest publication and checked complete bytes.
    my %published;
    $published{'rustup.c'} = _write_payload("$entry/rustup.c", $c, 0400);
    $published{'image.json'} = _write_payload("$entry/image.json", NativeProxyImageCustody::manifest_bytes($c, $image), 0400);
    $published{'rustup'} = _write_payload("$entry/rustup", $image, 0500);
    my $snapshot = NativeProxyImageCustody::read_entry($case, $key, $c, $image);
    die "canonical image directory replaced during publication\n"
        unless NativeProxyImageCustody::_same_metadata(
            $directory_identity, NativeProxyImageCustody::_directory($entry), 0,1,2,4);
    for my $source (@{$snapshot->{snapshots}}) {
        my ($name) = $source->{identity}{path} =~ m{/([^/]+)\z};
        my $sealed = $published{$name};
        die "sealed canonical source identity changed\n"
            unless $sealed && $source->{identity}{device} == $sealed->[0]
                && $source->{identity}{inode} == $sealed->[1]
                && $source->{identity}{size_bytes} == $sealed->[7];
    }
    return {created => 1, image => $snapshot};
}

1;
