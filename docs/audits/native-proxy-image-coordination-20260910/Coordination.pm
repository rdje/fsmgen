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

# Inactive checked coordination. Public inspection and the fixed internal
# publication/reference operations share custody; no caller callback is accepted.
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

sub _open_existing_lock {
    my ($path, $purpose) = @_;
    sysopen(my $handle, $path, O_RDWR | O_NOFOLLOW | O_NONBLOCK)
        or die "cannot open existing $purpose lock: $!\n";
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
    return _transaction($_[0], 'inspect');
}

sub _transaction {
    my ($case, $operation, @payload) = @_;
    die "unknown inactive transaction\n" unless defined($operation) && !ref($operation)
        && (($operation eq 'inspect' && !@payload)
            || ($operation eq 'publish_image' && @payload == 2
                && defined(&NativeProxyImagePublication::_publish_locked))
            || (($operation eq 'inspect_runtime_references' || $operation eq 'inspect_references') && !@payload
                && defined(&NativeProxyReferenceCensus::_inspect_locked))
            || ($operation eq 'acquire_runtime_reference' && @payload == 3
                && defined(&NativeProxyReferenceAcquisition::_admit_locked)
                && defined(&NativeProxyReferenceCensus::_inspect_locked)
                && defined(&NativeProxyImagePublication::_publish_locked))
            || ($operation eq 'retire_runtime_reference' && @payload == 2
                && defined(&NativeProxyRuntimeRetirement::_admit_locked)
                && defined(&NativeProxyReferenceCensus::_inspect_locked))
            || ($operation eq 'remove_unreferenced_image' && @payload == 1
                && defined(&NativeProxyImageMaintenance::_admit_locked)
                && defined(&NativeProxyReferenceCensus::_inspect_locked))
            || ($operation eq 'acquire_observation_reference' && @payload == 1
                && defined(&NativeProxyObservationAcquisition::_admit_locked)
                && defined(&NativeProxyReferenceCensus::_inspect_locked))
            || ($operation eq 'reuse_observation_reference' && @payload == 2
                && defined(&NativeProxyObservationAcquisition::_admit_locked)
                && defined(&NativeProxyReferenceCensus::_inspect_locked)));
    NativeProxyImageCustody::image_key(@payload) if $operation eq 'publish_image';
    NativeProxyReferenceAcquisition::_request(@payload) if $operation eq 'acquire_runtime_reference';
    NativeProxyRuntimeRetirement::_request($case, @payload) if $operation eq 'retire_runtime_reference';
    NativeProxyImageMaintenance::_request(@payload) if $operation eq 'remove_unreferenced_image';
    NativeProxyObservationAcquisition::_request(@payload) if $operation eq 'acquire_observation_reference';
    if ($operation eq 'reuse_observation_reference') {
        my $request = NativeProxyObservationAcquisition::_request($payload[0]);
        NativeProxyObservationAcquisition::_previous($case, $request, $payload[1]);
    }
    NativeProxyImageCustody::_relative_path($case);
    die "only the inactive qualification namespace is admitted\n"
        unless $case =~ /\A\Q$CASE_PREFIX\Efsmgen-[A-Za-z0-9_]+\z/;
    my $base = File::Spec->catdir($ROOT, $case);
    my $root_before = NativeProxyImageCustody::_directory($base);
    my $path = "$base/coordination.lock";
    my $existing_only = $operation eq 'retire_runtime_reference' || $operation eq 'remove_unreferenced_image'
        || $operation eq 'acquire_observation_reference' || $operation eq 'reuse_observation_reference';
    my $purpose = $operation eq 'retire_runtime_reference' ? 'retirement'
        : $operation eq 'remove_unreferenced_image' ? 'maintenance' : 'observation';
    my $handle = $existing_only
        ? _open_existing_lock($path, $purpose)
        : _open_lock($path);
    my $result;
    my $ok = eval {
        my $before = _lock_identity($handle, $path);
        my $flags = fcntl($handle, F_GETFD, 0);
        die "cannot read permanent lock descriptor flags: $!\n" unless defined $flags;
        fcntl($handle, F_SETFD, $flags | FD_CLOEXEC)
            or die "cannot seal permanent lock descriptor inheritance: $!\n";
        _acquire($handle, $path, $before);
        die "retirement lock differs from acquired identity\n"
            if $operation eq 'retire_runtime_reference'
                && ($before->[0] != $payload[0]{lock}{device} || $before->[1] != $payload[0]{lock}{inode});
        die "observation lock differs from acquired identity\n"
            if $operation eq 'reuse_observation_reference'
                && ($before->[0] != $payload[1]{lock}{device} || $before->[1] != $payload[1]{lock}{inode});
        die "store root replaced during acquisition\n"
            unless NativeProxyImageCustody::_same_metadata(
                $root_before, NativeProxyImageCustody::_directory($base), 0,1,2,4);
        _structure($base, $existing_only ? 0 : 1);
        my @directories = map { NativeProxyImageCustody::_directory("$base/$_") } qw(images references);
        my $census = _census($base);
        my $publication = $operation eq 'publish_image'
            ? NativeProxyImagePublication::_publish_locked($case, $census, @payload) : undef;
        my $references = $operation eq 'inspect_runtime_references' || $operation eq 'inspect_references'
            ? NativeProxyReferenceCensus::_inspect_locked($case, $census,
                $operation eq 'inspect_runtime_references' ? 1 : 0) : undef;
        my $acquisition;
        if ($operation eq 'acquire_runtime_reference') {
            my $before = NativeProxyReferenceCensus::_inspect_locked($case, $census);
            my $plan = NativeProxyReferenceAcquisition::_admit_locked($case, $census, $payload[0]);
            my $published = NativeProxyImagePublication::_publish_locked($case, $census, @payload[1,2]);
            my $acquired = NativeProxyReferenceAcquisition::_acquire_locked($case, $plan, $published);
            my $after = NativeProxyReferenceCensus::_inspect_locked($case, _census($base));
            $acquisition = NativeProxyReferenceAcquisition::_finish_locked(
                $case, $plan, $published, $acquired, $before, $after);
        }
        my $retirement;
        if ($operation eq 'retire_runtime_reference') {
            my $before = NativeProxyReferenceCensus::_inspect_locked($case, $census);
            my $plan = NativeProxyRuntimeRetirement::_admit_locked($case, $before, $payload[0]);
            NativeProxyRuntimeRetirement::_retire_locked($plan);
            my $current = NativeProxyReferenceCensus::_inspect_locked($case, _census($base));
            NativeProxyRuntimeRetirement::_release_locked($plan, $current);
            my $final_census = _census($base);
            die "retirement changed image namespace membership\n"
                unless join(',', @{$census->{images}}) eq join(',', @{$final_census->{images}});
            my $after = NativeProxyReferenceCensus::_inspect_locked($case, $final_census);
            $retirement = NativeProxyRuntimeRetirement::_finish_locked($case, $plan, $after);
        }
        my $maintenance;
        if ($operation eq 'remove_unreferenced_image') {
            my $references = NativeProxyReferenceCensus::_inspect_locked($case, $census);
            my $plan = NativeProxyImageMaintenance::_admit_locked($case, $census, $references, $payload[0]);
            my $current = _census($base);
            my $current_references = NativeProxyReferenceCensus::_inspect_locked($case, $current);
            NativeProxyImageMaintenance::_closure_locked($case, $plan, $current, $current_references);
            NativeProxyImageMaintenance::_remove_locked($case, $plan);
            my $after = _census($base);
            my $after_references = NativeProxyReferenceCensus::_inspect_locked($case, $after);
            $maintenance = NativeProxyImageMaintenance::_finish_locked($case, $plan, $after, $after_references);
        }
        my $observation;
        if ($operation eq 'acquire_observation_reference' || $operation eq 'reuse_observation_reference') {
            my $before = NativeProxyReferenceCensus::_inspect_locked($case, $census);
            my $plan = NativeProxyObservationAcquisition::_admit_locked($case, $before, @payload);
            my $complete = eval {
                my $sealed = NativeProxyObservationAcquisition::_acquire_locked($plan);
                my $final_census = _census($base);
                die "observation acquisition changed image namespace membership\n"
                    unless join(',', @{$census->{images}}) eq join(',', @{$final_census->{images}});
                my $after = NativeProxyReferenceCensus::_inspect_locked($case, $final_census);
                $observation = NativeProxyObservationAcquisition::_finish_locked($case, $plan, $sealed, $before, $after);
                1;
            };
            my $error = $@;
            my $close_error = NativeProxyObservationAcquisition::_close_sources($plan->{sources});
            die $error unless $complete;
            die $close_error if length($close_error);
        }
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
        my $lock = {path => "$case/coordination.lock", device => $before->[0], inode => $before->[1]};
        $result = $operation eq 'publish_image'
            ? {schema => 'fsmgen.inactive_image_publication.v1', runtime_authorized => 0,
               executable => undef, lock => $lock, %$publication}
            : $operation eq 'inspect_runtime_references'
            ? {schema => 'fsmgen.inactive_runtime_reference_census.v1', runtime_authorized => 0,
               executable => undef, lock => $lock, %$references}
            : $operation eq 'inspect_references'
            ? {schema => 'fsmgen.inactive_image_reference_census.v1', runtime_authorized => 0,
               executable => undef, lock => $lock, %$references}
            : $operation eq 'acquire_runtime_reference'
            ? {schema => 'fsmgen.inactive_runtime_reference_acquisition.v1', runtime_authorized => 0,
               executable => undef, lock => $lock, %$acquisition}
            : $operation eq 'retire_runtime_reference'
            ? {schema => 'fsmgen.inactive_runtime_retirement.v1', runtime_authorized => 0,
               executable => undef, lock => $lock, %$retirement}
            : $operation eq 'remove_unreferenced_image'
            ? {schema => 'fsmgen.inactive_image_maintenance.v1', runtime_authorized => 0,
               executable => undef, lock => $lock, %$maintenance}
            : $operation eq 'acquire_observation_reference' || $operation eq 'reuse_observation_reference'
            ? {schema => 'fsmgen.inactive_observation_acquisition.v1', runtime_authorized => 0,
               executable => undef, lock => $lock, %$observation}
            : {schema => 'fsmgen.inactive_image_namespace.v1',
            completeness => 'structure_only; contents_and_reference_semantics_unqualified',
            lock => $lock,
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
