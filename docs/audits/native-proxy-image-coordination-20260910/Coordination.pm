package NativeProxyImageCoordination;

use strict;
use warnings;

use Errno qw(EAGAIN EEXIST EWOULDBLOCK);
use Fcntl qw(O_CREAT O_EXCL O_NOFOLLOW O_NONBLOCK O_RDWR
    F_GETFD F_SETFD FD_CLOEXEC LOCK_EX LOCK_NB S_ISREG);
use File::Spec;
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC sleep);
use FSM::Test::ProcessSupervisor qw(repository_root);
use ImageCustody;

# Inactive structure inspection only. No compiler, image publication, reference
# release, maintenance or process-capable callback is exposed by this module.
my $ROOT = repository_root();
my $DEVICE = (stat($ROOT))[0];
my $CASE_PREFIX = '.artifacts/tmp/native-proxy-image-custody/cases/';
my $WAIT_SECONDS = 2;
my $POLL_SECONDS = 0.005;
my $IMAGE_LIMIT = 32;
my $REFERENCE_LIMIT = 128;

sub _now { return clock_gettime(CLOCK_MONOTONIC); }
sub _pause { sleep($_[0]); }
sub _try_lock { return flock($_[0], LOCK_EX | LOCK_NB); }

sub _lock_identity {
    my ($handle, $path) = @_;
    my @descriptor = stat($handle);
    my @named = lstat($path);
    die "invalid permanent lock identity\n"
        unless @descriptor && S_ISREG($descriptor[2]) && $descriptor[0] == $DEVICE
            && ($descriptor[2] & 07777) == 0600 && $descriptor[3] == 1
            && $descriptor[4] == $< && $descriptor[7] == 0
            && NativeProxyImageCustody::_same_metadata(\@descriptor, \@named, 0,1,2,3,4,7);
    return \@descriptor;
}

sub _open_lock {
    my ($path) = @_;
    my $handle;
    if (!sysopen($handle, $path, O_RDWR | O_CREAT | O_EXCL | O_NOFOLLOW | O_NONBLOCK, 0600)) {
        die "cannot exclusively create permanent lock: $!\n" unless $! == EEXIST;
        # An expected existing-file race admits only this exact checked file.
        # Never truncate, chmod, replace or unlink another contender's lock.
        sysopen($handle, $path, O_RDWR | O_NOFOLLOW | O_NONBLOCK)
            or die "cannot open existing permanent lock: $!\n";
    }
    return $handle;
}

sub _acquire {
    my ($handle, $path, $before) = @_;
    my $deadline = _now() + $WAIT_SECONDS;
    while (1) {
        die "permanent lock admission deadline expired\n" if _now() >= $deadline;
        if (_try_lock($handle)) {
            die "permanent lock admission deadline expired\n" if _now() >= $deadline;
            die "permanent lock replaced during acquisition\n"
                unless NativeProxyImageCustody::_same_metadata(
                    $before, _lock_identity($handle, $path), 0,1,2,3,4,7);
            return;
        }
        my $error = 0 + $!;
        die "permanent lock acquisition failed: errno $error\n"
            unless $error == EAGAIN || $error == EWOULDBLOCK;
        my $remaining = $deadline - _now();
        die "permanent lock admission deadline expired\n" if $remaining <= 0;
        _pause($remaining < $POLL_SECONDS ? $remaining : $POLL_SECONDS);
    }
}

sub _names {
    my ($path, $limit) = @_;
    opendir(my $directory, $path) or die "cannot open bounded namespace: $!\n";
    my @names;
    while (defined(my $name = readdir($directory))) {
        next if $name eq '.' || $name eq '..';
        push @names, $name;
        die "namespace capacity exceeded\n" if @names > $limit;
    }
    closedir($directory) or die "cannot close bounded namespace: $!\n";
    return [sort @names];
}

sub _structure {
    my ($base, $allow_creation) = @_;
    my $members = _names($base, 3);
    die "unknown store member\n" if grep { !/\A(?:coordination\.lock|images|references)\z/ } @$members;
    for my $name (qw(images references)) {
        my $path = "$base/$name";
        if ($allow_creation && !-e $path && !-l $path) {
            mkdir($path, 0700) or die "cannot exclusively create store directory: $!\n";
        }
        NativeProxyImageCustody::_directory($path);
    }
    die "incomplete store structure\n"
        unless join(',', @{_names($base, 3)}) eq 'coordination.lock,images,references';
}

sub _census {
    my ($base) = @_;
    my $images = _names("$base/images", $IMAGE_LIMIT);
    my $references = _names("$base/references", $REFERENCE_LIMIT);
    for my $name (@$images) {
        die "invalid image name\n" unless $name =~ /\A[0-9a-f]{64}\z/;
        NativeProxyImageCustody::_directory("$base/images/$name");
    }
    for my $name (@$references) {
        die "invalid reference name\n" unless $name =~ /\A[0-9a-f]{64}\.json\z/;
        my $source = NativeProxyImageCustody::_source("$base/references/$name", 0400, 4096);
        my $ok = eval { NativeProxyImageCustody::_recheck_source($source); 1 };
        my $error = $@;
        my $closed = close($source->{handle});
        die $error unless $ok;
        die "cannot close census reference: $!\n" unless $closed;
    }
    # Count incomplete image/record objects. This structure-only result cannot
    # establish complete image contents or reference schema/lifetime validity.
    return {images => $images, references => $references};
}

sub inspect_store {
    die "expected one inactive store root\n" unless @_ == 1;
    my ($case) = @_;
    NativeProxyImageCustody::_relative_path($case);
    die "only the inactive qualification namespace is admitted\n"
        unless $case =~ /\A\Q$CASE_PREFIX\Efsmgen-[A-Za-z0-9_]+\z/;
    my $base = File::Spec->catdir($ROOT, $case);
    my $root_before = NativeProxyImageCustody::_directory($base);
    my $path = "$base/coordination.lock";
    my $handle = _open_lock($path);
    my $result;
    my $ok = eval {
        my $before = _lock_identity($handle, $path);
        my $flags = fcntl($handle, F_GETFD, 0);
        die "cannot read permanent lock descriptor flags: $!\n" unless defined $flags;
        fcntl($handle, F_SETFD, $flags | FD_CLOEXEC)
            or die "cannot seal permanent lock descriptor inheritance: $!\n";
        _acquire($handle, $path, $before);
        die "store root replaced during acquisition\n"
            unless NativeProxyImageCustody::_same_metadata(
                $root_before, NativeProxyImageCustody::_directory($base), 0,1,2,4);
        _structure($base, 1);
        my @directories = map { NativeProxyImageCustody::_directory("$base/$_") } qw(images references);
        my $census = _census($base);
        _structure($base, 0);
        for my $i (0, 1) {
            my $name = $i ? 'references' : 'images';
            die "store namespace directory replaced\n"
                unless NativeProxyImageCustody::_same_metadata(
                    $directories[$i], NativeProxyImageCustody::_directory("$base/$name"), 0,1,2,4);
        }
        die "store root replaced during census\n"
            unless NativeProxyImageCustody::_same_metadata(
                $root_before, NativeProxyImageCustody::_directory($base), 0,1,2,4);
        die "permanent lock replaced during census\n"
            unless NativeProxyImageCustody::_same_metadata(
                $before, _lock_identity($handle, $path), 0,1,2,3,4,7);
        $result = {schema => 'fsmgen.inactive_image_namespace.v1',
            completeness => 'structure_only; contents_and_reference_semantics_unqualified',
            lock => {path => "$case/coordination.lock", device => $before->[0], inode => $before->[1]},
            %$census};
        1;
    };
    my $error = $@;
    # Closing the owning descriptor releases cooperation on every success and
    # failure path. The permanent named lock is intentionally left in place.
    my $closed = close($handle);
    die $error unless $ok;
    die "cannot close permanent lock: $!\n" unless $closed;
    return $result;
}

1;
