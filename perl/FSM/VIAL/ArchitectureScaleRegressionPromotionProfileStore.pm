package FSM::VIAL::ArchitectureScaleRegressionPromotionProfileStore;

use v5.20;
use strict;
use warnings;
use bytes ();
use Carp qw(confess);
use Cwd ();
use Digest::SHA qw(sha256_hex);
use Fcntl qw(O_CREAT O_EXCL O_NOFOLLOW O_RDONLY O_WRONLY);
use File::Basename qw(dirname);
use File::Spec;
use IO::Handle ();
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::VIAL::ArchitectureScaleRegressionPromotionCapturePlan;

my $PLAN = 'FSM::VIAL::ArchitectureScaleRegressionPromotionCapturePlan';
my $SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_profile_publication.v1';
my $ARTIFACT_SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_profile_artifact.v1';
my $STAGING_BASE =
    '.artifacts/tmp/vial-scale/regression-promotion-profile-publication/v1';
my $REPORT_FILENAME = 'measurement-report.json';
my $PUBLICATION_REVISION = 'regression_promotion_profile_store_v1';

# This is a provisional storage/admission ceiling, not a performance, fit, or
# capacity claim. It matches the largest explicit bound among the five newer
# v1 publishers. The two older semantic/execution publishers are unbounded;
# v2 deliberately adds this fail-closed ceiling instead of inheriting that gap.
my $MAX_PUBLICATION_BYTES = 67_108_864;
my $MAX_IPC_BYTES = 65_536;
my $MAX_ERROR_BYTES = 4_096;

my @PUBLICATION_KEYS = qw(
    schema schema_version publication_identity plan_identity policy_identity
    publication_id publication_schema profile report
);
my @ARTIFACT_KEYS = qw(
    schema schema_version status ordinal selection_key
    artifact_relative_path artifact_sha256 artifact_bytes same_volume atomic
);
my @LOAD_RESULT_KEYS = qw(publication artifact);
my $JSON = JSON::PP->new->canonical(1)->utf8(1);

sub publication_keys($class) {
    _exact_invocant($class, 'publication_keys');
    return [@PUBLICATION_KEYS];
}

sub artifact_keys($class) {
    _exact_invocant($class, 'artifact_keys');
    return [@ARTIFACT_KEYS];
}

sub load_result_keys($class) {
    _exact_invocant($class, 'load_result_keys');
    return [@LOAD_RESULT_KEYS];
}

sub publication_limits($class) {
    _exact_invocant($class, 'publication_limits');
    return {
        publication_revision => $PUBLICATION_REVISION,
        report_filename => $REPORT_FILENAME,
        maximum_publication_bytes => $MAX_PUBLICATION_BYTES,
        maximum_ipc_bytes => $MAX_IPC_BYTES,
        maximum_error_bytes => $MAX_ERROR_BYTES,
        maximum_same_profile_recovery_entries => 1,
    };
}

sub publish($class, @args) {
    _exact_invocant($class, 'publish');
    my $request = _request(
        'publish', \@args, [qw(repository_root ordinal report)],
    );
    _validate_report_input($request->{report});
    my ($repo_root, $root_device) =
        _repository_root($request->{repository_root});
    my ($plan, $entry) = _current_entry($repo_root, $request->{ordinal});
    my $publication = _publication_value(
        $plan, $entry, $request->{report},
    );
    return _clone(_publish({
        repository_root => $repo_root,
        root_device => $root_device,
        plan => $plan,
        entry => $entry,
        publication => $publication,
    }));
}

sub load($class, @args) {
    _exact_invocant($class, 'load');
    my $request = _request(
        'load', \@args, [qw(repository_root ordinal)],
    );
    my ($repo_root, $root_device) =
        _repository_root($request->{repository_root});
    my ($plan, $entry) = _current_entry($repo_root, $request->{ordinal});
    my @staging = _same_profile_staging_candidates(
        {
            repository_root => $repo_root,
            root_device => $root_device,
            plan => $plan,
            entry => $entry,
        },
        _profile_token($entry),
    );
    confess "regression-promotion profile publication retained staging residue\n"
        if @staging;
    my ($publication, $artifact) = _read_publication({
        repository_root => $repo_root,
        root_device => $root_device,
        plan => $plan,
        entry => $entry,
    });
    return _clone({publication => $publication, artifact => $artifact});
}

sub _current_entry($repo_root, $ordinal) {
    confess "regression-promotion profile ordinal is invalid\n"
        unless _json_positive_integer($ordinal);
    my $plan = $PLAN->derive({repository_root => $repo_root});
    confess "regression-promotion profile ordinal is unknown\n"
        if $ordinal > @{$plan->{entries}};
    my $entry = $plan->{entries}[$ordinal - 1];
    confess "regression-promotion profile ordinal changed\n"
        unless $entry->{ordinal} == $ordinal;
    return ($plan, $entry);
}

sub _publication_value($plan, $entry, $report) {
    _validate_report_input($report);
    my $report_copy = eval { _clone($report) };
    confess "regression-promotion profile report is not canonical JSON data\n"
        if $@ || !defined($report_copy);
    my $publication = {
        schema => $SCHEMA,
        schema_version => 1,
        publication_identity => undef,
        plan_identity => $plan->{plan_identity},
        policy_identity => $plan->{policy_identity},
        publication_id => $plan->{publication_id},
        publication_schema => $plan->{publication_schema},
        profile => _clone($entry),
        report => $report_copy,
    };
    $publication->{publication_identity} =
        'regression-promotion-profile-publication/'
        . sha256_hex(_canonical_json($publication));
    _validate_publication($publication, $plan, $entry);
    return $publication;
}

sub _validate_report_input($report) {
    confess "regression-promotion profile report must be one JSON object\n"
        unless ref($report) eq 'HASH' && !blessed($report);
    return 1;
}

sub _validate_publication($publication, $plan, $entry) {
    _exact_keys(
        $publication, \@PUBLICATION_KEYS,
        'regression-promotion profile publication',
    );
    confess "regression-promotion profile publication schema is invalid\n"
        unless ($publication->{schema} // '') eq $SCHEMA
            && _json_integer_equals($publication->{schema_version}, 1);
    confess "regression-promotion profile plan binding changed\n"
        unless ($publication->{plan_identity} // '') eq
                $plan->{plan_identity}
            && ($publication->{policy_identity} // '') eq
                $plan->{policy_identity}
            && ($publication->{publication_id} // '') eq
                $plan->{publication_id}
            && ($publication->{publication_schema} // '') eq
                $plan->{publication_schema};
    confess "regression-promotion profile dispatch binding changed\n"
        unless _canonical_json($publication->{profile}) eq
            _canonical_json($entry);
    confess "regression-promotion profile report must be one JSON object\n"
        unless ref($publication->{report}) eq 'HASH'
            && !blessed($publication->{report});
    eval { _canonical_json($publication->{report}); 1 }
        or confess "regression-promotion profile report is not canonical JSON data\n";
    my $projection = _clone($publication);
    my $identity = $projection->{publication_identity};
    $projection->{publication_identity} = undef;
    confess "regression-promotion profile publication identity changed\n"
        unless defined($identity) && !ref($identity)
            && $identity eq 'regression-promotion-profile-publication/'
                . sha256_hex(_canonical_json($projection));
    return 1;
}

sub _publish($raw) {
    _validate_publication(
        $raw->{publication}, $raw->{plan}, $raw->{entry},
    );
    my $encoded = _canonical_json($raw->{publication}) . "\n";
    my $encoded_bytes = bytes::length($encoded);
    confess "regression-promotion profile publication exceeds its bounded ceiling "
        . "(actual=$encoded_bytes bytes, maximum=$MAX_PUBLICATION_BYTES bytes)\n"
        if $encoded_bytes > $MAX_PUBLICATION_BYTES;
    my $digest = sha256_hex($encoded);
    my ($target_rel, $target_abs) = _target_directory($raw);
    my ($stage_rel, $stage_abs, $profile_token) =
        _staging_directory($raw, $digest);
    my @candidates = _same_profile_staging_candidates(
        $raw, $profile_token,
    );
    confess "regression-promotion profile recovery state is ambiguous\n"
        if @candidates > 1
            || (@candidates == 1 && $candidates[0] ne $stage_rel);

    if (-e $target_abs || -l $target_abs) {
        confess "regression-promotion profile publication retained staging residue\n"
            if @candidates;
        my ($existing, $artifact, $existing_bytes) =
            _read_publication({%$raw});
        confess "regression-promotion profile publication collision\n"
            unless $existing_bytes eq $encoded;
        $artifact->{status} = 'unchanged';
        return $artifact;
    }

    if (@candidates) {
        _require_exact_stage(
            $stage_abs, $raw->{root_device}, $encoded,
        );
        my @created;
        _ensure_directory_path(
            $raw->{repository_root}, $raw->{root_device},
            dirname($target_abs), dirname($target_rel), \@created,
        );
        _sync_directory(dirname($target_abs), $raw->{root_device});
        unless (rename($stage_abs, $target_abs)) {
            _remove_empty_directories(\@created);
            confess "cannot recover regression-promotion profile publication\n";
        }
        _sync_directory(dirname($target_abs), $raw->{root_device});
        _prune_staging_parents($raw->{repository_root}, dirname($stage_abs));
        my (undef, $artifact, $reloaded) = _read_publication({%$raw});
        confess "regression-promotion profile recovery bytes changed\n"
            unless $reloaded eq $encoded;
        $artifact->{status} = 'recovered';
        return $artifact;
    }

    my ($created_stage, $created_target, $stage_identity) = ([], [], undef);
    my $published = eval {
        ($stage_abs, $created_stage, $stage_identity) =
            _create_stage(
                $raw->{repository_root}, $raw->{root_device}, $stage_rel,
            );
        my $artifact_abs = File::Spec->catfile(
            $stage_abs, $REPORT_FILENAME,
        );
        _write_synced_file(
            $artifact_abs, $raw->{root_device}, $encoded,
        );
        _require_exact_stage(
            $stage_abs, $raw->{root_device}, $encoded,
        );
        _sync_directory($stage_abs, $raw->{root_device});
        _ensure_directory_path(
            $raw->{repository_root}, $raw->{root_device},
            dirname($target_abs), dirname($target_rel), $created_target,
        );
        _sync_directory(dirname($target_abs), $raw->{root_device});
        confess "regression-promotion profile publication target appeared\n"
            if -e $target_abs || -l $target_abs;
        rename($stage_abs, $target_abs)
            or confess "cannot atomically publish regression-promotion profile\n";
        _sync_directory(dirname($target_abs), $raw->{root_device});
        1;
    };
    if (!$published) {
        my $error = $@;
        my $cleanup_error;
        if (defined($stage_identity)
                && (-e $stage_abs || -l $stage_abs)) {
            $cleanup_error = eval {
                _remove_owned_stage(
                    $stage_abs, $raw->{root_device}, $stage_identity,
                );
                undef;
            };
            $cleanup_error = $@ if $@;
        }
        _remove_empty_directories($created_stage);
        _remove_empty_directories($created_target);
        die $error unless defined($cleanup_error) && length($cleanup_error);
        die $error . "regression-promotion profile cleanup residue: "
            . $cleanup_error;
    }
    _remove_empty_directories($created_stage);
    my (undef, $artifact, $reloaded) = _read_publication({%$raw});
    confess "regression-promotion profile publication bytes changed\n"
        unless $reloaded eq $encoded;
    $artifact->{status} = 'published';
    return $artifact;
}

sub _read_publication($raw) {
    my ($target_rel, $target_abs) = _target_directory($raw);
    my ($encoded, $stat) = _read_exact_artifact_directory(
        $target_abs, $raw->{root_device}, $MAX_PUBLICATION_BYTES,
    );
    confess "regression-promotion profile publication is not newline-terminated\n"
        unless $encoded =~ /\n\z/;
    my $publication = eval {
        JSON::PP->new->utf8(1)->decode($encoded);
    };
    confess "regression-promotion profile publication JSON is invalid\n"
        if $@ || !defined($publication);
    confess "regression-promotion profile publication JSON is not canonical\n"
        unless _canonical_json($publication) . "\n" eq $encoded;
    _validate_publication(
        $publication, $raw->{plan}, $raw->{entry},
    );
    my $artifact = _artifact({
        status => 'loaded',
        entry => $raw->{entry},
        artifact_relative_path =>
            "$target_rel/$REPORT_FILENAME",
        artifact_sha256 => sha256_hex($encoded),
        artifact_bytes => $stat->[7],
    });
    return ($publication, $artifact, $encoded);
}

sub _target_directory($raw) {
    my $path = $raw->{entry}{publication_relative_path};
    confess "regression-promotion profile report coordinate is invalid\n"
        unless defined($path) && !ref($path)
            && $path =~ m{\A[.]artifacts/qualification/vial-scale/v2/
                regression-promotion-corpus-v1/profiles/
                [0-9]{2}-[0-9a-f]{64}/measurement-report[.]json\z}x
            && $path !~ m{(?:\A|/)[.][.](?:/|\z)}
            && $path !~ m{(?:\A|/)v1(?:/|\z)};
    my $target_rel = dirname($path);
    confess "regression-promotion profile report filename changed\n"
        unless $path eq "$target_rel/$REPORT_FILENAME";
    my $target_abs = _safe_destination(
        $raw->{repository_root}, $raw->{root_device}, $target_rel,
    );
    return ($target_rel, $target_abs);
}

sub _staging_directory($raw, $digest) {
    my $profile_token = _profile_token($raw->{entry});
    my $stage_rel = "$STAGING_BASE/$profile_token-$digest";
    my $stage_abs = _safe_destination(
        $raw->{repository_root}, $raw->{root_device}, $stage_rel,
    );
    return ($stage_rel, $stage_abs, $profile_token);
}

sub _profile_token($entry) {
    return sprintf(
        '%02d-%s', $entry->{ordinal},
        sha256_hex($entry->{selection_key}),
    );
}

sub _same_profile_staging_candidates($raw, $profile_token) {
    my $base_abs = _safe_destination(
        $raw->{repository_root}, $raw->{root_device}, $STAGING_BASE,
    );
    return () unless -e $base_abs || -l $base_abs;
    _require_directory($base_abs, $raw->{root_device}, 'staging base');
    opendir my $dh, $base_abs
        or confess "cannot inspect regression-promotion profile staging\n";
    my @entries = sort grep {
        $_ ne '.' && $_ ne '..'
            && /^\Q$profile_token\E/
    } readdir $dh;
    closedir $dh
        or confess "cannot close regression-promotion profile staging\n";
    return map { "$STAGING_BASE/$_" } @entries;
}

sub _artifact($raw) {
    my $artifact = {
        schema => $ARTIFACT_SCHEMA,
        schema_version => 1,
        status => $raw->{status},
        ordinal => $raw->{entry}{ordinal},
        selection_key => $raw->{entry}{selection_key},
        artifact_relative_path => $raw->{artifact_relative_path},
        artifact_sha256 => $raw->{artifact_sha256},
        artifact_bytes => $raw->{artifact_bytes},
        same_volume => JSON::PP::true,
        atomic => JSON::PP::true,
    };
    _exact_keys(
        $artifact, \@ARTIFACT_KEYS,
        'regression-promotion profile artifact',
    );
    confess "regression-promotion profile artifact status is invalid\n"
        unless $artifact->{status} =~ /\A(?:loaded|published|recovered|unchanged)\z/;
    confess "regression-promotion profile artifact identity is invalid\n"
        unless $artifact->{artifact_sha256} =~ /\A[0-9a-f]{64}\z/
            && _json_positive_integer($artifact->{artifact_bytes})
            && $artifact->{artifact_bytes} <= $MAX_PUBLICATION_BYTES;
    return $artifact;
}

sub _read_exact_artifact_directory($root, $root_device, $maximum) {
    my $root_stat =
        _require_directory($root, $root_device, 'publication root');
    opendir my $dh, $root
        or confess "cannot inspect regression-promotion profile publication\n";
    my @opened_stat = stat($dh);
    confess "regression-promotion profile publication directory changed\n"
        unless @opened_stat && -d _
            && _same_identity($root_stat, \@opened_stat);
    my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    confess "regression-promotion profile publication census changed\n"
        unless @entries == 1 && $entries[0] eq $REPORT_FILENAME;
    my @final_stat = stat($dh);
    closedir $dh
        or confess "cannot close regression-promotion profile publication\n";
    my @final_path_stat = lstat($root);
    confess "regression-promotion profile publication directory changed\n"
        unless @final_stat && @final_path_stat && !-l _ && -d _
            && _same_identity(\@opened_stat, \@final_stat)
            && _same_identity(\@opened_stat, \@final_path_stat);
    my $path = File::Spec->catfile($root, $REPORT_FILENAME);
    my @result = _read_exact_file($path, $root_device, $maximum);
    @final_path_stat = lstat($root);
    confess "regression-promotion profile publication directory changed\n"
        unless @final_path_stat && !-l _ && -d _
            && _same_identity(\@opened_stat, \@final_path_stat);
    return @result;
}

sub _read_exact_file($path, $root_device, $maximum) {
    my @path_stat = lstat($path);
    confess "regression-promotion profile publication artifact is invalid\n"
        unless @path_stat && !-l _ && -f _;
    confess "regression-promotion profile publication crossed repository volume\n"
        unless $path_stat[0] == $root_device;
    confess "regression-promotion profile publication artifact owner changed\n"
        unless $path_stat[4] == $<;
    confess "regression-promotion profile publication artifact is hard-linked\n"
        unless $path_stat[3] == 1;
    confess "regression-promotion profile publication exceeds its bounded ceiling "
        . "(actual=$path_stat[7] bytes, maximum=$maximum bytes)\n"
        unless $path_stat[7] > 0 && $path_stat[7] <= $maximum;
    sysopen(my $fh, $path, O_RDONLY | O_NOFOLLOW)
        or confess "cannot open regression-promotion profile publication artifact\n";
    binmode($fh, ':raw')
        or confess "cannot set regression-promotion publication byte mode\n";
    my @handle_stat = stat($fh);
    confess "regression-promotion profile publication artifact changed\n"
        unless @handle_stat && -f _
            && _same_identity(\@path_stat, \@handle_stat)
            && $handle_stat[3] == 1;
    local $/;
    my $encoded = <$fh>;
    my @final_handle_stat = stat($fh);
    close $fh
        or confess "cannot close regression-promotion profile publication artifact\n";
    my @final_path_stat = lstat($path);
    confess "regression-promotion profile publication artifact changed while reading\n"
        unless defined($encoded)
            && bytes::length($encoded) == $path_stat[7]
            && @final_handle_stat && @final_path_stat
            && _same_identity(\@path_stat, \@final_handle_stat)
            && _same_identity(\@path_stat, \@final_path_stat);
    return ($encoded, \@path_stat);
}

sub _require_exact_stage($root, $root_device, $expected) {
    my ($actual) = _read_exact_artifact_directory(
        $root, $root_device, $MAX_PUBLICATION_BYTES,
    );
    confess "regression-promotion profile staging is not recoverable\n"
        unless $actual eq $expected;
    return 1;
}

sub _create_stage($repo_root, $root_device, $relative) {
    my @created;
    my $path = $repo_root;
    my @parts = split m{/}, _safe_relative_path($relative);
    my $ok = eval {
        for my $index (0 .. $#parts) {
            $path = File::Spec->catdir($path, $parts[$index]);
            if (-e $path || -l $path) {
                _require_directory($path, $root_device, 'staging component');
                confess "regression-promotion profile staging root already exists\n"
                    if $index == $#parts;
            }
            else {
                mkdir($path, 0700)
                    or confess "cannot create regression-promotion profile staging directory\n";
                push @created, $path;
                _require_directory($path, $root_device, 'staging component');
            }
        }
        1;
    };
    if (!$ok) {
        my $error = $@;
        _remove_empty_directories(\@created);
        die $error;
    }
    my @stat = lstat($path);
    return ($path, \@created, [@stat[0, 1, 4]]);
}

sub _write_synced_file($path, $root_device, $encoded) {
    sysopen(my $fh, $path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0600)
        or confess "cannot create regression-promotion profile publication\n";
    binmode($fh, ':raw')
        or confess "cannot set regression-promotion publication byte mode\n";
    print {$fh} $encoded
        or confess "cannot write regression-promotion profile publication\n";
    $fh->flush
        or confess "cannot flush regression-promotion profile publication\n";
    $fh->sync
        or confess "cannot sync regression-promotion profile publication\n";
    my @stat = stat($fh);
    confess "regression-promotion profile publication crossed repository volume\n"
        unless @stat && -f _ && $stat[0] == $root_device
            && $stat[3] == 1 && $stat[4] == $<;
    close $fh
        or confess "cannot close regression-promotion profile publication\n";
    return 1;
}

sub _sync_directory($path, $root_device) {
    my $path_stat =
        _require_directory($path, $root_device, 'directory sync target');
    sysopen(my $fh, $path, O_RDONLY | O_NOFOLLOW)
        or confess "cannot open regression-promotion publication directory for sync\n";
    my @stat = stat($fh);
    confess "regression-promotion publication sync target is invalid\n"
        unless @stat && -d _ && $stat[0] == $root_device
            && _same_identity($path_stat, \@stat);
    $fh->sync
        or confess "cannot sync regression-promotion publication directory\n";
    close $fh
        or confess "cannot close regression-promotion publication directory\n";
    my @final_stat = lstat($path);
    confess "regression-promotion publication sync target changed\n"
        unless @final_stat && !-l _ && -d _
            && _same_identity(\@stat, \@final_stat);
    return 1;
}

sub _remove_owned_stage($path, $root_device, $identity) {
    my @root_stat = lstat($path);
    confess "regression-promotion profile staging cleanup identity changed\n"
        unless @root_stat && !-l _ && -d _
            && $root_stat[0] == $identity->[0]
            && $root_stat[1] == $identity->[1]
            && $root_stat[4] == $identity->[2]
            && $root_stat[0] == $root_device;
    opendir my $dh, $path
        or confess "cannot inspect regression-promotion profile cleanup\n";
    my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh
        or confess "cannot close regression-promotion profile cleanup\n";
    confess "regression-promotion profile cleanup census is unsafe\n"
        unless @entries <= 1
            && (!@entries || $entries[0] eq $REPORT_FILENAME);
    if (@entries) {
        my $artifact = File::Spec->catfile($path, $REPORT_FILENAME);
        my @stat = lstat($artifact);
        confess "regression-promotion profile cleanup artifact is unsafe\n"
            unless @stat && !-l _ && -f _ && $stat[0] == $root_device
                && $stat[3] == 1 && $stat[4] == $<;
        unlink($artifact)
            or confess "cannot remove regression-promotion profile cleanup artifact\n";
    }
    rmdir($path)
        or confess "cannot remove regression-promotion profile staging root\n";
    confess "regression-promotion profile staging remains after cleanup\n"
        if -e $path || -l $path;
    return 1;
}

sub _ensure_directory_path(
    $repo_root, $root_device, $absolute, $relative, $created,
) {
    my $path = $repo_root;
    for my $part (split m{/}, _safe_relative_path($relative)) {
        $path = File::Spec->catdir($path, $part);
        if (-e $path || -l $path) {
            _require_directory($path, $root_device, 'publication parent');
        }
        else {
            mkdir($path, 0700)
                or confess "cannot create regression-promotion publication parent\n";
            push @$created, $path;
            _require_directory($path, $root_device, 'publication parent');
        }
    }
    confess "regression-promotion publication parent mismatch\n"
        unless $path eq $absolute;
    return 1;
}

sub _require_directory($path, $root_device, $label) {
    my @stat = lstat($path);
    confess "regression-promotion profile $label is not a real directory\n"
        unless @stat && !-l _ && -d _;
    confess "regression-promotion profile $label crossed repository volume\n"
        unless $stat[0] == $root_device;
    confess "regression-promotion profile $label owner changed\n"
        unless $stat[4] == $<;
    return \@stat;
}

sub _safe_destination($repo_root, $root_device, $relative) {
    _safe_relative_path($relative);
    my $path = $repo_root;
    for my $part (split m{/}, $relative) {
        $path = File::Spec->catdir($path, $part);
        if (-e $path || -l $path) {
            _require_directory($path, $root_device, 'destination component');
        }
    }
    return $path;
}

sub _safe_relative_path($path) {
    confess "regression-promotion profile path is unsafe\n"
        unless defined($path) && !ref($path) && length($path)
            && !File::Spec->file_name_is_absolute($path)
            && $path !~ m{(?:\A|/)[.][.](?:/|\z)}
            && $path !~ m{//}
            && $path !~ m{/\z};
    return $path;
}

sub _repository_root($value) {
    confess "regression-promotion profile repository root is invalid\n"
        unless defined($value) && !ref($value) && length($value);
    my $root = Cwd::realpath($value);
    confess "regression-promotion profile repository root is unavailable\n"
        unless defined($root) && -d $root && !-l $root;
    my $git = File::Spec->catfile($root, '.git');
    confess "regression-promotion profile repository Git identity is invalid\n"
        unless (-d $git || -f $git) && !-l $git;
    my @stat = lstat($root);
    confess "regression-promotion profile repository root cannot be inspected\n"
        unless @stat && !-l _ && -d _;
    confess "regression-promotion profile repository root owner changed\n"
        unless $stat[4] == $<;
    return ($root, $stat[0]);
}

sub _prune_staging_parents($repo_root, $path) {
    my $stop = File::Spec->catdir(
        $repo_root, split m{/}, '.artifacts/tmp',
    );
    while ($path ne $repo_root && index($path, "$stop/") == 0) {
        last unless -d $path && !-l $path && rmdir($path);
        $path = dirname($path);
    }
}

sub _remove_empty_directories($paths) {
    for my $path (reverse @{$paths // []}) {
        next unless -d $path && !-l $path;
        rmdir($path);
    }
}

sub _same_identity($left, $right) {
    for my $index (0, 1, 2, 3, 4, 7, 9, 10) {
        return 0 unless $left->[$index] == $right->[$index];
    }
    return 1;
}

sub _request($method, $args, $keys) {
    confess __PACKAGE__ . "->$method expects one closed hash\n"
        unless @{$args} == 1 && ref($args->[0]) eq 'HASH'
            && !blessed($args->[0]);
    my %allowed = map { $_ => 1 } @{$keys};
    for my $key (keys %{$args->[0]}) {
        confess "$method received unknown key '$key'\n"
            unless $allowed{$key};
    }
    for my $key (@{$keys}) {
        confess "$method is missing '$key'\n"
            unless exists $args->[0]{$key};
    }
    return $args->[0];
}

sub _exact_keys($value, $keys, $label) {
    confess "$label must be a hash\n"
        unless ref($value) eq 'HASH' && !blessed($value);
    my %expected = map { $_ => 1 } @{$keys};
    for my $key (keys %{$value}) {
        confess "$label contains unknown key '$key'\n"
            unless $expected{$key};
    }
    for my $key (@{$keys}) {
        confess "$label is missing '$key'\n"
            unless exists $value->{$key};
    }
}

sub _exact_invocant($class, $method) {
    confess __PACKAGE__ . "->$method requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
}

sub _json_integer_equals($actual, $expected) {
    return defined($actual) && !ref($actual)
        && _canonical_json($actual) eq "$expected";
}

sub _json_positive_integer($actual) {
    return defined($actual) && !ref($actual)
        && _canonical_json($actual) =~ /\A[1-9][0-9]*\z/;
}

sub _canonical_json($value) {
    return $JSON->encode($value);
}

sub _clone($value) {
    return $JSON->decode($JSON->encode($value));
}

1;
