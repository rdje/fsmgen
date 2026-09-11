package NativeProxyObservationRelease;

use strict;
use warnings;
use JSON::PP ();
use FSM::Test::ProcessSupervisor qw(repository_root);
use ArchiveRecord;
use ObservationArchive;
use ObservationAcquisition;
use WorkRecord;
use Coordination;
use ReferenceCensus;
use ImageCustody;
use PrivateWorkspace;

my $ROOT = repository_root();
my $JSON = JSON::PP->new->canonical->ascii;

# Inactive attempts only. Supplied selection/seal/cleanup records are not
# authenticated native ownership or an implementation of launch prevention.
sub _same { return $JSON->encode($_[0]) eq $JSON->encode($_[1]); }
sub _copy { return $JSON->decode($JSON->encode($_[0])); }

sub _close_owned {
    my ($sources) = @_;
    my $error = '';
    for my $source (@$sources) {
        $error ||= "cannot close retained release descriptor: $!\n" unless close($source->{handle});
    }
    return $error;
}

sub _archive_closure {
    my ($state) = @_;
    my $archive = $state->{archive_state};
    NativeProxyObservationArchive::_members($archive, $state->{archive_names});
    NativeProxyObservationArchive::_directory_closure($archive);
    NativeProxyObservationArchive::_source_closure($archive);
    my $current = NativeProxyObservationArchive::_receipt(
        $state->{case}, $state->{request}, $state->{acquired}, $archive);
    die "release archive differs from original complete custody\n"
        unless _same($current, $state->{archive_receipt});
    NativeProxyObservationArchive::_members($archive, $state->{archive_names});
    NativeProxyObservationArchive::_directory_closure($archive);
    NativeProxyImageCustody::_recheck_source($_) for @{$archive->{sources}};
}

sub _prepare {
    my ($state, $case, $request, $acquired, $archive_receipt, $selection, $settlement) = @_;
    $request = NativeProxyObservationAcquisition::_request($request);
    $acquired = NativeProxyObservationAcquisition::_previous($case, $request, $acquired);
    my $spec = NativeProxyObservationArchiveRecord::archive_specification($case, $request, $acquired);
    NativeProxyObservationArchiveRecord::validate_archive_receipt($case, $request, $acquired, $archive_receipt);
    NativeProxyObservationWorkRecord::validate_work_settlement($case, $request, $acquired, $selection, $settlement);
    NativeProxyObservationArchive::_limits($spec);
    @$state{qw(case request acquired archive_receipt selection settlement)} =
        ($case, $request, $acquired, _copy($archive_receipt), _copy($selection), _copy($settlement));
    my $evidence = $spec->{evidence_directory_identity};
    my $prior = NativeProxyObservationAcquisition::_prior_directory($evidence, 'release evidence');
    # There is deliberately no creation/publication route in release admission.
    my $directory = NativeProxyImageCustody::_directory("$ROOT/$spec->{archive_directory}");
    die "release archive directory differs from original custody\n"
        unless $directory->[0] == $archive_receipt->{archive_directory_identity}{device}
            && $directory->[1] == $archive_receipt->{archive_directory_identity}{inode};
    $state->{archive_state} = {spec => $spec, sources => [], directories => [
        {path => $evidence->{path}, metadata => $prior},
        {path => $spec->{archive_directory}, metadata => $directory}]};
    $state->{archive_names} = [map { "$_->{sha256}.source" } @{$spec->{files}}];
    NativeProxyObservationArchive::_members($state->{archive_state}, $state->{archive_names});
    for my $file (@{$spec->{files}}) {
        # Register actual ownership before any validation can throw.
        push @{$state->{owned}}, NativeProxyImageCustody::_source("$ROOT/$file->{path}", 0400, 65_536);
        my $source = $state->{owned}[-1];
        push @{$state->{archive_state}{sources}}, $source;
        die "release archive bytes differ from retained original\n" unless $source->{bytes} eq $file->{bytes};
        NativeProxyImageCustody::_recheck_source($source);
    }
    _archive_closure($state);
}

sub _coordinator_request {
    die "release admission requires the fixed coordinator\n" unless caller eq 'NativeProxyImageCoordination';
    my ($case, $state) = @_;
    die "release state differs from admitted store\n" unless $case eq $state->{case};
    # The coordinator admits this payload only from release_observation_reference.
    # It never accepts a caller-provided callback or raw synthetic source handle.
    NativeProxyObservationWorkRecord::validate_work_settlement($case, @$state{qw(request acquired selection settlement)});
}

sub _current_image {
    my ($state, $image) = @_;
    my $key = $state->{acquired}{observation_reference}{record}{image_key};
    die "release canonical image is absent or changed\n" unless defined($image) && $image->{key} eq $key
        && _same([@{$image->{snapshots}}[0,1]], [@{$state->{acquired}{target_sources}}[3,4]]);
}

sub _retain_live_sources {
    my ($state) = @_;
    my $hold = $state->{acquired}{observation_reference}{source};
    my $key = $state->{acquired}{observation_reference}{record}{image_key};
    my @specs = (
        ["$state->{case}/images/$key/rustup.c", 0400, 65_536, $state->{acquired}{target_sources}[3]],
        ["$state->{case}/images/$key/rustup", 0500, 65_536, $state->{acquired}{target_sources}[4]],
        [$hold->{identity}{path}, 0400, 4096, $hold]);
    for my $spec (@specs) {
        push @{$state->{owned}}, NativeProxyImageCustody::_source("$ROOT/$spec->[0]", $spec->[1], $spec->[2]);
        my $source = $state->{owned}[-1];
        die "release live source differs from original custody\n"
            unless _same(NativeProxyReferenceCensus::_snapshot($source), $spec->[3]);
        NativeProxyImageCustody::_recheck_source($source);
    }
}

sub _admit_locked {
    die "release ownership admission requires the fixed coordinator\n" unless caller eq 'NativeProxyImageCoordination';
    my ($case, $before, $state) = @_;
    my $original = $state->{acquired}{observation_reference};
    my ($hold) = grep { $_->{source}{identity}{path} eq $original->{source}{identity}{path} } @{$before->{references}};
    die "original observation hold is absent or changed\n" unless defined($hold) && _same($hold, $original);
    my ($image) = grep { $_->{key} eq $original->{record}{image_key} } @{$before->{images}};
    _current_image($state, $image);
    @$state{qw(before image)} = ($before, $image);
    _archive_closure($state);
    _retain_live_sources($state);
    return $state;
}

sub _unlink_exact {
    die "exact unlink requires the release owner\n" unless caller eq __PACKAGE__;
    my ($state) = @_;
    my $path = $state->{acquired}{observation_reference}{source}{identity}{path};
    $state->{effect}{unlink_attempted} = 1;
    unlink("$ROOT/$path") == 1 or die "cannot unlink exact observation hold: $!\n";
    # Record the actual successful syscall before a later helper can fail.
    $state->{effect}{unlink_completed} = 1;
}

sub _assert_absent {
    my ($state, $phase) = @_;
    my $path = $state->{acquired}{observation_reference}{source}{identity}{path};
    my $check = {phase => $phase, state => 'unknown'};
    $state->{effect}{last_reference_check} = $check;
    my $absent = NativeProxyPrivateWorkspace::_absent($path);
    $check->{state} = $absent ? 'absent' : 'present';
    die "released observation hold remains present\n" unless $absent;
    $state->{effect}{reference_absence_verified} = 1;
}

sub _release_locked {
    die "exact release requires the fixed coordinator\n" unless caller eq 'NativeProxyImageCoordination';
    my ($case, $state, $current) = @_;
    die "release changed another current reference or image\n" unless _same($state->{before}, $current);
    _archive_closure($state);
    my $image = NativeProxyReferenceCensus::_image($case, $state->{image}{key});
    die "release image changed before unlink\n" unless _same($image->{snapshot}, $state->{image});
    _retain_live_sources($state);
    NativeProxyImageCustody::_recheck_source($_) for @{$state->{owned}};
    _unlink_exact($state);
    _assert_absent($state, 'after_unlink');
}

sub _finish_locked {
    die "release closure requires the fixed coordinator\n" unless caller eq 'NativeProxyImageCoordination';
    my ($case, $state, $after) = @_;
    my $path = $state->{acquired}{observation_reference}{source}{identity}{path};
    my @references = grep { $_->{source}{identity}{path} ne $path } @{$state->{before}{references}};
    my %referenced = map { $_->{record}{image_key} => 1 } @references;
    my @images = grep { $referenced{$_->{key}} } @{$state->{before}{images}};
    die "release changed another owner or image\n" unless _same(
        {references => \@references, images => \@images, retention => $state->{before}{retention}}, $after);
    # A last observation release keeps even an unreferenced image intact.
    my $image = NativeProxyReferenceCensus::_image($case, $state->{image}{key});
    die "release changed the retained canonical image\n" unless _same($image->{snapshot}, $state->{image});
    _archive_closure($state);
    _assert_absent($state, 'finish');
    return {released_reference => $path, image => $image->{snapshot}, archive => $state->{archive_receipt},
            settlement => $state->{settlement}};
}

sub release_observation_reference {
    die "expected store, request, acquisition, archive, original selection and settlement\n" unless @_ == 6;
    my ($case, $request, $acquired, $archive, $selection, $settlement) = @_;
    my $state = {owned => [], effect => {unlink_attempted => 0, unlink_completed => 0,
        reference_absence_verified => 0, last_reference_check => undef}};
    my $receipt;
    my $ok = eval {
        _prepare($state, $case, $request, $acquired, $archive, $selection, $settlement);
        $receipt = NativeProxyImageCoordination::_transaction($case, 'release_observation_reference', $state);
        1;
    };
    my $error = $@;
    my $close_error = _close_owned($state->{owned});
    $error = $close_error if $ok && length($close_error);
    my $success = $ok && !length($close_error);
    return {schema => 'fsmgen.inactive_observation_release_attempt.v1', runtime_authorized => 0,
        executable => undef, success => $success ? 1 : 0, error => $success ? '' : $error,
        %{$state->{effect}}, release => $success ? $receipt : undef};
}

1;
