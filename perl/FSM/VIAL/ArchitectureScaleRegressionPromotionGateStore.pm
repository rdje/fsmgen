package FSM::VIAL::ArchitectureScaleRegressionPromotionGateStore;

use v5.20;
use strict;
use warnings;

use bytes ();
use Carp qw(confess);
use Cwd ();
use Digest::SHA qw(sha256_hex);
use Errno qw(EINTR);
use Fcntl qw(O_CREAT O_EXCL O_NOFOLLOW O_RDONLY O_WRONLY);
use File::Basename qw(dirname);
use File::Spec;
use IO::Handle ();
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::VIAL::ArchitectureScaleRegressionPromotionGateContract;
use FSM::VIAL::ArchitectureScaleRegressionPromotionGateCoordinator;

my $CONTRACT =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionGateContract';
my $COORDINATOR =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionGateCoordinator';
my $RESULT_SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_gate_result.v1';
my $ARTIFACT_SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_gate_result_artifact.v1';
my $PUBLICATION_RELATIVE = join '/', qw(
    .artifacts qualification vial-scale v2 regression-promotion-gate-v1
    current regression-promotion-gate-result.json
);
my $QUALIFICATION_RELATIVE = join '/', qw(
    .artifacts qualification vial-scale v2
    regression-promotion-budget-qualification-v1 current
);
my $STAGING_RELATIVE = join '/', qw(
    .artifacts tmp vial-scale regression-promotion-gate-publication v1
);
my $PUBLICATION_REVISION = 'regression_promotion_gate_store_v1';
my $MAX_RESULT_BYTES = 1_048_576;
my $MAX_ERROR_BYTES = 4_096;

my @ARTIFACT_KEYS = qw(
    schema schema_version status publication_relative_path sha256 bytes
    same_volume atomic replaced_previous
);
my @LOAD_RESULT_KEYS = qw(result artifact);
my $JSON = JSON::PP->new->canonical(1)->utf8(1);

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
        publication_relative_path => $PUBLICATION_RELATIVE,
        staging_relative_path => $STAGING_RELATIVE,
        maximum_result_bytes => $MAX_RESULT_BYTES,
        maximum_error_bytes => $MAX_ERROR_BYTES,
        maximum_recovery_entries => 1,
    };
}

sub publish($class, @args) {
    _exact_invocant($class, 'publish');
    my $request = _request('publish', \@args, [qw(repository_root)]);
    _require_active_guard();
    my ($repository_root, $root_device) =
        _repository_root($request->{repository_root});
    my $execution_revision = _require_clean_revision($repository_root);
    my $contract = _derive_contract($repository_root);
    _require_unchanged_clean_revision(
        $repository_root, $execution_revision,
    );

    my @staging = _staging_candidates({
        repository_root => $repository_root,
        root_device => $root_device,
    });
    _reject_ambiguous_staging({
        repository_root => $repository_root,
        root_device => $root_device,
        candidates => \@staging,
    }) if @staging > 1;
    if (@staging) {
        my $artifact = _recover({
            repository_root => $repository_root,
            root_device => $root_device,
            contract => $contract,
            execution_revision => $execution_revision,
            stage_relative => $staging[0],
        });
        _require_unchanged_clean_revision(
            $repository_root, $execution_revision,
        );
        return _clone($artifact);
    }

    my $result = $COORDINATOR->run({
        repository_root => $repository_root,
    });
    _require_unchanged_clean_revision(
        $repository_root, $execution_revision,
    );
    my ($admitted, $encoded) = _admit_result({
        result => $result,
        contract => $contract,
        execution_revision => $execution_revision,
    });

    my ($target_relative, $target_absolute) = _target_path({
        repository_root => $repository_root,
        root_device => $root_device,
    });
    my ($previous_bytes, $previous_stat);
    if (-e $target_absolute || -l $target_absolute) {
        (undef, $previous_bytes, $previous_stat) = _read_result({
            repository_root => $repository_root,
            root_device => $root_device,
            contract => $contract,
        });
        if ($previous_bytes eq $encoded) {
            _require_no_staging({
                repository_root => $repository_root,
                root_device => $root_device,
            });
            _require_unchanged_clean_revision(
                $repository_root, $execution_revision,
            );
            return _clone(_artifact({
                status => 'unchanged',
                target_relative => $target_relative,
                encoded => $encoded,
                replaced_previous => JSON::PP::false,
            }));
        }
    }

    my $artifact = _publish_result({
        repository_root => $repository_root,
        root_device => $root_device,
        contract => $contract,
        execution_revision => $execution_revision,
        result => $admitted,
        encoded => $encoded,
        previous_stat => $previous_stat,
    });
    _require_unchanged_clean_revision(
        $repository_root, $execution_revision,
    );
    return _clone($artifact);
}

sub load($class, @args) {
    _exact_invocant($class, 'load');
    my $request = _request('load', \@args, [qw(repository_root)]);
    _require_active_guard();
    my ($repository_root, $root_device) =
        _repository_root($request->{repository_root});
    _require_no_staging({
        repository_root => $repository_root,
        root_device => $root_device,
    });
    my $contract = _derive_contract($repository_root);
    my ($result, $encoded) = _read_result({
        repository_root => $repository_root,
        root_device => $root_device,
        contract => $contract,
    });
    _require_no_staging({
        repository_root => $repository_root,
        root_device => $root_device,
    });
    my ($target_relative) = _target_path({
        repository_root => $repository_root,
        root_device => $root_device,
    });
    return _clone({
        result => $result,
        artifact => _artifact({
            status => 'loaded',
            target_relative => $target_relative,
            encoded => $encoded,
            replaced_previous => JSON::PP::false,
        }),
    });
}

sub _derive_contract($repository_root) {
    my $contract = $CONTRACT->derive({
        repository_root => $repository_root,
    });
    _validate_contract_boundary($contract);
    return $contract;
}

sub _validate_contract_boundary($contract) {
    confess "regression gate result publication contract is malformed\n"
        unless ref($contract) eq 'HASH' && !blessed($contract)
            && ($contract->{contract_identity} // '') =~
                m{\Aregression-promotion-gate-contract/[0-9a-f]{64}\z}
            && ref($contract->{qualification_evidence}) eq 'HASH'
            && !blessed($contract->{qualification_evidence})
            && ref($contract->{result_contract}) eq 'HASH'
            && !blessed($contract->{result_contract});
    my $result_contract = $contract->{result_contract};
    _exact_keys(
        $result_contract, $CONTRACT->result_contract_keys,
        'regression gate result publication contract',
    );
    my $limits = $CONTRACT->contract_limits;
    confess "regression gate result publication contract changed\n"
        unless ($result_contract->{schema} // '') eq $RESULT_SCHEMA
            && ($result_contract->{identity_prefix} // '') eq
                'regression-promotion-gate-result/'
            && ($result_contract->{publication_relative_path} // '') eq
                $PUBLICATION_RELATIVE
            && ($result_contract->{staging_relative_path} // '') eq
                $STAGING_RELATIVE
            && ($result_contract->{publication_relative_path} // '') ne
                $QUALIFICATION_RELATIVE
            && ($result_contract->{publication_mode} // '') eq
                'atomic_replaceable_latest_observation'
            && _json_integer_equals(
                $result_contract->{maximum_result_bytes},
                $MAX_RESULT_BYTES,
            )
            && _json_integer_equals(
                $result_contract->{maximum_result_bytes},
                $limits->{maximum_result_bytes},
            )
            && _json_integer_equals(
                $result_contract->{maximum_error_bytes},
                $MAX_ERROR_BYTES,
            )
            && _json_integer_equals(
                $result_contract->{maximum_recovery_entries}, 1,
            )
            && _json_true($result_contract->{same_volume})
            && _json_true($result_contract->{atomic})
            && _json_true(
                $result_contract->{interrupted_run_preserves_previous_result},
            )
            && !_json_true(
                $result_contract->{result_is_qualification_evidence},
            )
            && !_json_true($result_contract->{qualification_overwrite})
            && ($result_contract->{cleanup} // '') eq
                'owned_staging_absent_after_result_reload';
    my $evidence = $contract->{qualification_evidence};
    confess "regression gate result qualification binding changed\n"
        unless ($evidence->{qualification_identity} // '') =~
                m{\Aregression-promotion-qualification/[0-9a-f]{64}\z}
            && ($evidence->{publication_identity} // '') =~
                m{\Aregression-promotion-budget-qualification-publication/[0-9a-f]{64}\z}
            && ($evidence->{qualification_file_set_sha256} // '') =~
                /\A[0-9a-f]{64}\z/;
    return 1;
}

sub _admit_result($raw) {
    _validate_contract_boundary($raw->{contract});
    confess "regression gate result execution revision is invalid\n"
        unless defined($raw->{execution_revision})
            && !ref($raw->{execution_revision})
            && $raw->{execution_revision} =~ /\A[0-9a-f]{40}\z/;
    confess "regression gate result value is malformed\n"
        unless ref($raw->{result}) eq 'HASH'
            && !blessed($raw->{result});
    my $result = $COORDINATOR->_admit_for_store({
        result => $raw->{result},
        contract => $raw->{contract},
        execution_revision => $raw->{execution_revision},
    });
    confess "regression gate result admission returned a malformed value\n"
        unless ref($result) eq 'HASH' && !blessed($result);
    my $evidence = $raw->{contract}{qualification_evidence};
    confess "regression gate result evidence binding changed\n"
        unless ($result->{schema} // '') eq $RESULT_SCHEMA
            && ($result->{contract_identity} // '') eq
                $raw->{contract}{contract_identity}
            && ($result->{qualification_identity} // '') eq
                $evidence->{qualification_identity}
            && ($result->{qualification_publication_identity} // '') eq
                $evidence->{publication_identity}
            && ($result->{qualification_file_set_sha256} // '') eq
                $evidence->{qualification_file_set_sha256}
            && ($result->{execution_revision} // '') eq
                $raw->{execution_revision};
    my $encoded = _canonical_json($result) . "\n";
    _require_bounded_bytes($encoded, $MAX_RESULT_BYTES);
    return (_clone($result), $encoded);
}

sub _publish_result($raw) {
    my ($target_relative, $target_absolute) = _target_path($raw);
    my $digest = sha256_hex($raw->{encoded});
    my ($stage_relative, $stage_absolute) =
        _stage_path($raw, $digest);
    my @created;
    my $stage_identity;
    my $published = eval {
        _ensure_directory_path(
            $raw->{repository_root}, $raw->{root_device},
            dirname($stage_absolute), dirname($stage_relative), \@created,
        );
        _sync_directory(dirname($stage_absolute), $raw->{root_device});
        _write_synced_file(
            $stage_absolute, $raw->{root_device}, $raw->{encoded},
        );
        _sync_directory(dirname($stage_absolute), $raw->{root_device});
        my @stage_stat = lstat($stage_absolute);
        $stage_identity = [@stage_stat];
        my ($staged, $staged_bytes, $validated_stage_stat) =
            _read_result_file({
                path => $stage_absolute,
                root_device => $raw->{root_device},
                contract => $raw->{contract},
                expected_revision => $raw->{execution_revision},
            });
        confess "regression gate staged result bytes changed\n"
            unless $staged_bytes eq $raw->{encoded}
                && _canonical_json($staged) eq
                    _canonical_json($raw->{result})
                && _same_identity(\@stage_stat, $validated_stage_stat);

        my @created_target;
        _ensure_directory_path(
            $raw->{repository_root}, $raw->{root_device},
            dirname($target_absolute), dirname($target_relative),
            \@created_target,
        );
        push @created, @created_target;
        _sync_directory(dirname($target_absolute), $raw->{root_device});
        _require_target_unchanged(
            $target_absolute, $raw->{previous_stat},
        );
        _require_file_identity(
            $stage_absolute, $raw->{root_device}, $validated_stage_stat,
            'staged result',
        );
        _atomic_replace($stage_absolute, $target_absolute);
        _sync_directory(dirname($target_absolute), $raw->{root_device});
        _sync_directory(dirname($stage_absolute), $raw->{root_device});
        1;
    };
    if (!$published) {
        my $error = $@;
        my $cleanup_error = _cleanup_stage_after_failure({
            path => $stage_absolute,
            root_device => $raw->{root_device},
            identity => $stage_identity,
        });
        _remove_empty_directories(\@created);
        die $error unless length($cleanup_error);
        die $error . "regression gate result cleanup residue: "
            . $cleanup_error;
    }
    _remove_empty_directories(\@created);
    my (undef, $reloaded) = _read_result({
        repository_root => $raw->{repository_root},
        root_device => $raw->{root_device},
        contract => $raw->{contract},
        expected_revision => $raw->{execution_revision},
    });
    confess "regression gate published result bytes changed\n"
        unless $reloaded eq $raw->{encoded};
    _require_no_staging($raw);
    return _artifact({
        status => $raw->{previous_stat} ? 'replaced' : 'published',
        target_relative => $target_relative,
        encoded => $raw->{encoded},
        replaced_previous => $raw->{previous_stat}
            ? JSON::PP::true : JSON::PP::false,
    });
}

sub _recover($raw) {
    my ($stage_relative, $stage_absolute) = _candidate_path(
        $raw, $raw->{stage_relative},
    );
    my $recovered = eval {
        my ($result, $encoded, $stage_stat) = _read_result_file({
            path => $stage_absolute,
            root_device => $raw->{root_device},
            contract => $raw->{contract},
            expected_revision => $raw->{execution_revision},
        });
        my $digest = sha256_hex($encoded);
        confess "regression gate result recovery identity changed\n"
            unless $stage_relative eq
                "$STAGING_RELATIVE/gate-result-$digest.json";

        my ($target_relative, $target_absolute) = _target_path($raw);
        my $previous_stat;
        if (-e $target_absolute || -l $target_absolute) {
            (undef, undef, $previous_stat) = _read_result({
                repository_root => $raw->{repository_root},
                root_device => $raw->{root_device},
                contract => $raw->{contract},
            });
        }
        my @created;
        _ensure_directory_path(
            $raw->{repository_root}, $raw->{root_device},
            dirname($target_absolute), dirname($target_relative), \@created,
        );
        _sync_directory(dirname($target_absolute), $raw->{root_device});
        _require_target_unchanged($target_absolute, $previous_stat);
        _sync_directory(dirname($stage_absolute), $raw->{root_device});
        _require_file_identity(
            $stage_absolute, $raw->{root_device}, $stage_stat,
            'recovery result',
        );
        _atomic_replace($stage_absolute, $target_absolute);
        _sync_directory(dirname($target_absolute), $raw->{root_device});
        _sync_directory(dirname($stage_absolute), $raw->{root_device});
        _remove_empty_directories(\@created);
        _prune_staging_parents(
            $raw->{repository_root}, dirname($stage_absolute),
        );
        my (undef, $reloaded) = _read_result({
            repository_root => $raw->{repository_root},
            root_device => $raw->{root_device},
            contract => $raw->{contract},
            expected_revision => $raw->{execution_revision},
        });
        confess "regression gate recovered result bytes changed\n"
            unless $reloaded eq $encoded;
        _require_no_staging($raw);
        return _artifact({
            status => 'recovered',
            target_relative => $target_relative,
            encoded => $encoded,
            replaced_previous => $previous_stat
                ? JSON::PP::true : JSON::PP::false,
        });
    };
    return $recovered if defined($recovered) && !$@;
    my $error = $@ || "regression gate result recovery failed\n";
    my $cleanup_error = _cleanup_stage_after_failure({
        path => $stage_absolute,
        root_device => $raw->{root_device},
    });
    _prune_staging_parents(
        $raw->{repository_root}, dirname($stage_absolute),
    );
    die $error unless length($cleanup_error);
    die $error . "regression gate result cleanup residue: "
        . $cleanup_error;
}

sub _read_result($raw) {
    my (undef, $target_absolute) = _target_path($raw);
    return _read_result_file({
        path => $target_absolute,
        root_device => $raw->{root_device},
        contract => $raw->{contract},
        (exists($raw->{expected_revision})
            ? (expected_revision => $raw->{expected_revision}) : ()),
    });
}

sub _read_result_file($raw) {
    my ($encoded, $stat) = _read_exact_file(
        $raw->{path}, $raw->{root_device}, $MAX_RESULT_BYTES,
    );
    my $result = _decode_canonical_json($encoded);
    my $revision = exists($raw->{expected_revision})
        ? $raw->{expected_revision} : $result->{execution_revision};
    my ($admitted, $canonical) = _admit_result({
        result => $result,
        contract => $raw->{contract},
        execution_revision => $revision,
    });
    confess "regression gate result bytes changed on admission\n"
        unless $canonical eq $encoded;
    return ($admitted, $encoded, $stat);
}

sub _decode_canonical_json($encoded) {
    confess "regression gate result is not newline-terminated\n"
        unless $encoded =~ /\n\z/;
    my $value = eval { JSON::PP->new->utf8(1)->decode($encoded) };
    confess "regression gate result JSON is invalid\n"
        if $@ || !defined($value);
    confess "regression gate result JSON is not canonical\n"
        unless _canonical_json($value) . "\n" eq $encoded;
    return $value;
}

sub _artifact($raw) {
    my $artifact = {
        schema => $ARTIFACT_SCHEMA,
        schema_version => 1,
        status => $raw->{status},
        publication_relative_path => $raw->{target_relative},
        sha256 => sha256_hex($raw->{encoded}),
        bytes => bytes::length($raw->{encoded}),
        same_volume => JSON::PP::true,
        atomic => JSON::PP::true,
        replaced_previous => $raw->{replaced_previous},
    };
    _exact_keys(
        $artifact, \@ARTIFACT_KEYS,
        'regression gate result artifact',
    );
    confess "regression gate result artifact is invalid\n"
        unless ($artifact->{status} // '') =~
                /\A(?:loaded|published|replaced|recovered|unchanged)\z/
            && ($artifact->{publication_relative_path} // '') eq
                $PUBLICATION_RELATIVE
            && ($artifact->{sha256} // '') =~ /\A[0-9a-f]{64}\z/
            && _json_integer_equals(
                $artifact->{bytes}, bytes::length($raw->{encoded}),
            )
            && _json_true($artifact->{same_volume})
            && _json_true($artifact->{atomic})
            && JSON::PP::is_bool($artifact->{replaced_previous});
    return $artifact;
}

sub _target_path($raw) {
    my $parent_relative = dirname($PUBLICATION_RELATIVE);
    my $parent_absolute = _safe_destination(
        $raw->{repository_root}, $raw->{root_device}, $parent_relative,
    );
    return (
        $PUBLICATION_RELATIVE,
        File::Spec->catfile(
            $parent_absolute, 'regression-promotion-gate-result.json',
        ),
    );
}

sub _stage_path($raw, $digest) {
    confess "regression gate result staging digest is invalid\n"
        unless defined($digest) && !ref($digest)
            && $digest =~ /\A[0-9a-f]{64}\z/;
    my $relative = "$STAGING_RELATIVE/gate-result-$digest.json";
    return _candidate_path($raw, $relative);
}

sub _candidate_path($raw, $relative) {
    confess "regression gate result staging coordinate is invalid\n"
        unless defined($relative) && !ref($relative)
            && $relative =~
                m{\A\Q$STAGING_RELATIVE\E/gate-result-[0-9a-f]{64}[.]json\z};
    my $parent_absolute = _safe_destination(
        $raw->{repository_root}, $raw->{root_device}, $STAGING_RELATIVE,
    );
    my ($filename) = $relative =~ m{/([^/]+)\z};
    return ($relative, File::Spec->catfile($parent_absolute, $filename));
}

sub _staging_candidates($raw) {
    my $base_absolute = _safe_destination(
        $raw->{repository_root}, $raw->{root_device}, $STAGING_RELATIVE,
    );
    return () unless -e $base_absolute || -l $base_absolute;
    my $base_stat = _require_directory(
        $base_absolute, $raw->{root_device}, 'staging base',
    );
    opendir my $dh, $base_absolute
        or confess "cannot inspect regression gate result staging\n";
    my @opened_stat = stat($dh);
    confess "regression gate result staging directory changed\n"
        unless @opened_stat && -d _
            && _same_identity($base_stat, \@opened_stat);
    my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    my @final_stat = stat($dh);
    closedir $dh
        or confess "cannot close regression gate result staging\n";
    confess "regression gate result staging directory changed\n"
        unless @final_stat && _same_identity(\@opened_stat, \@final_stat);
    if (grep { !/^gate-result-[0-9a-f]{64}[.]json\z/ } @entries) {
        my @cleanup_errors;
        for my $entry (@entries) {
            my $error = _cleanup_stage_after_failure({
                path => File::Spec->catfile($base_absolute, $entry),
                root_device => $raw->{root_device},
            });
            push @cleanup_errors, $error if length($error);
        }
        _prune_staging_parents(
            $raw->{repository_root}, $base_absolute,
        );
        confess "regression gate result staging entry is invalid\n"
            unless @cleanup_errors;
        confess "regression gate result staging entry is invalid; cleanup residue: "
            . join('', @cleanup_errors);
    }
    return map { "$STAGING_RELATIVE/$_" } @entries;
}

sub _require_no_staging($raw) {
    confess "regression gate result retained staging residue\n"
        if _staging_candidates($raw);
    return 1;
}

sub _reject_ambiguous_staging($raw) {
    my @cleanup_errors;
    for my $relative (@{$raw->{candidates}}) {
        my (undef, $absolute) = _candidate_path($raw, $relative);
        my $error = _cleanup_stage_after_failure({
            path => $absolute,
            root_device => $raw->{root_device},
        });
        push @cleanup_errors, $error if length($error);
    }
    my $base_absolute = _safe_destination(
        $raw->{repository_root}, $raw->{root_device}, $STAGING_RELATIVE,
    );
    _prune_staging_parents(
        $raw->{repository_root}, $base_absolute,
    );
    confess "regression gate result recovery state is ambiguous\n"
        unless @cleanup_errors;
    confess "regression gate result recovery state is ambiguous; cleanup residue: "
        . join('', @cleanup_errors);
}

sub _read_exact_file($path, $root_device, $maximum) {
    my @path_stat = lstat($path);
    confess "regression gate result artifact is invalid\n"
        unless @path_stat && !-l _ && -f _;
    confess "regression gate result artifact crossed repository volume\n"
        unless $path_stat[0] == $root_device;
    confess "regression gate result artifact owner changed\n"
        unless $path_stat[4] == $<;
    confess "regression gate result artifact is hard-linked\n"
        unless $path_stat[3] == 1;
    _require_bounded_size($path_stat[7], $maximum);
    sysopen(my $fh, $path, O_RDONLY | O_NOFOLLOW)
        or confess "cannot open regression gate result artifact\n";
    binmode($fh, ':raw')
        or confess "cannot set regression gate result byte mode\n";
    my @handle_stat = stat($fh);
    confess "regression gate result artifact changed\n"
        unless @handle_stat && -f _
            && _same_identity(\@path_stat, \@handle_stat)
            && $handle_stat[3] == 1;
    my $encoded = '';
    while (bytes::length($encoded) <= $maximum) {
        my $remaining = $maximum + 1 - bytes::length($encoded);
        last if $remaining <= 0;
        my $chunk = '';
        my $read = sysread($fh, $chunk, $remaining);
        if (!defined($read)) {
            next if $! == EINTR;
            confess "cannot read regression gate result artifact\n";
        }
        last if $read == 0;
        $encoded .= $chunk;
    }
    _require_bounded_bytes($encoded, $maximum);
    my @final_handle_stat = stat($fh);
    close $fh or confess "cannot close regression gate result artifact\n";
    my @final_path_stat = lstat($path);
    confess "regression gate result artifact changed while reading\n"
        unless bytes::length($encoded) == $path_stat[7]
            && @final_handle_stat && @final_path_stat
            && _same_identity(\@path_stat, \@final_handle_stat)
            && _same_identity(\@path_stat, \@final_path_stat);
    return ($encoded, \@path_stat);
}

sub _write_synced_file($path, $root_device, $encoded) {
    sysopen(my $fh, $path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0600)
        or confess "cannot create regression gate staged result\n";
    binmode($fh, ':raw')
        or confess "cannot set regression gate result byte mode\n";
    print {$fh} $encoded
        or confess "cannot write regression gate staged result\n";
    $fh->flush or confess "cannot flush regression gate staged result\n";
    $fh->sync or confess "cannot sync regression gate staged result\n";
    my @stat = stat($fh);
    confess "regression gate staged result is invalid\n"
        unless @stat && -f _ && $stat[0] == $root_device
            && $stat[3] == 1 && $stat[4] == $<;
    close $fh or confess "cannot close regression gate staged result\n";
    return 1;
}

sub _atomic_replace($source, $target) {
    rename($source, $target)
        or confess "cannot atomically replace regression gate result\n";
    return 1;
}

sub _require_target_unchanged($path, $expected) {
    my @actual = lstat($path);
    if ($expected) {
        confess "regression gate result target changed before replacement\n"
            unless @actual && !-l _ && -f _
                && _same_identity($expected, \@actual);
    }
    else {
        confess "regression gate result target appeared before replacement\n"
            if @actual || -l $path;
    }
    return 1;
}

sub _require_file_identity($path, $root_device, $expected, $label) {
    my @actual = lstat($path);
    confess "regression gate $label changed before replacement\n"
        unless @actual && !-l _ && -f _
            && $actual[0] == $root_device
            && $actual[3] == 1 && $actual[4] == $<
            && _same_identity($expected, \@actual);
    return 1;
}

sub _cleanup_stage_after_failure($raw) {
    return '' unless -e $raw->{path} || -l $raw->{path};
    my $cleaned = eval {
        my @stat = lstat($raw->{path});
        confess "unsafe regression gate result staging residue\n"
            unless @stat && $stat[4] == $<
                && (defined($raw->{root_device})
                    ? $stat[0] == $raw->{root_device} : 1)
                && (!defined($raw->{identity})
                    || _same_identity($raw->{identity}, \@stat));
        confess "unsafe regression gate result staging directory residue\n"
            if !-l _ && -d _;
        unlink($raw->{path})
            or confess "cannot remove regression gate result staging residue\n";
        confess "regression gate result staging residue remains\n"
            if -e $raw->{path} || -l $raw->{path};
        1;
    };
    return $cleaned ? '' : ($@ || "unknown staging cleanup failure\n");
}

sub _sync_directory($path, $root_device) {
    my $path_stat =
        _require_directory($path, $root_device, 'directory sync target');
    sysopen(my $fh, $path, O_RDONLY | O_NOFOLLOW)
        or confess "cannot open regression gate result directory for sync\n";
    my @stat = stat($fh);
    confess "regression gate result sync target is invalid\n"
        unless @stat && -d _ && $stat[0] == $root_device
            && _same_identity($path_stat, \@stat);
    $fh->sync
        or confess "cannot sync regression gate result directory\n";
    close $fh
        or confess "cannot close regression gate result directory\n";
    my @final_stat = lstat($path);
    confess "regression gate result sync target changed\n"
        unless @final_stat && !-l _ && -d _
            && _same_identity(\@stat, \@final_stat);
    return 1;
}

sub _ensure_directory_path(
    $repository_root, $root_device, $absolute, $relative, $created,
) {
    my $path = $repository_root;
    for my $part (split m{/}, _safe_relative_path($relative)) {
        $path = File::Spec->catdir($path, $part);
        if (-e $path || -l $path) {
            _require_directory($path, $root_device, 'publication parent');
        }
        else {
            mkdir($path, 0700)
                or confess "cannot create regression gate result publication parent\n";
            push @$created, $path;
            _require_directory($path, $root_device, 'publication parent');
        }
    }
    confess "regression gate result publication parent mismatch\n"
        unless $path eq $absolute;
    return 1;
}

sub _require_directory($path, $root_device, $label) {
    my @stat = lstat($path);
    confess "regression gate result $label is not a real directory\n"
        unless @stat && !-l _ && -d _;
    confess "regression gate result $label crossed repository volume\n"
        unless $stat[0] == $root_device;
    confess "regression gate result $label owner changed\n"
        unless $stat[4] == $<;
    return \@stat;
}

sub _safe_destination($repository_root, $root_device, $relative) {
    _safe_relative_path($relative);
    my $path = $repository_root;
    for my $part (split m{/}, $relative) {
        $path = File::Spec->catdir($path, $part);
        if (-e $path || -l $path) {
            _require_directory(
                $path, $root_device, 'destination component',
            );
        }
    }
    return $path;
}

sub _safe_relative_path($path) {
    confess "regression gate result path is unsafe\n"
        unless defined($path) && !ref($path) && length($path)
            && !File::Spec->file_name_is_absolute($path)
            && $path !~ m{(?:\A|/)[.][.](?:/|\z)}
            && $path !~ m{//}
            && $path !~ m{/\z};
    return $path;
}

sub _repository_root($value) {
    confess "regression gate result repository root is invalid\n"
        unless defined($value) && !ref($value) && length($value);
    my $root = Cwd::realpath($value);
    confess "regression gate result repository root is unavailable\n"
        unless defined($root) && -d $root && !-l $root;
    my $git = File::Spec->catfile($root, '.git');
    confess "regression gate result repository Git identity is invalid\n"
        unless (-d $git || -f $git) && !-l $git;
    my @stat = lstat($root);
    confess "regression gate result repository root cannot be inspected\n"
        unless @stat && !-l _ && -d _;
    confess "regression gate result repository root owner changed\n"
        unless $stat[4] == $<;
    return ($root, $stat[0]);
}

sub _require_active_guard() {
    confess "regression gate result publication requires the active repository RAM guard\n"
        unless ($ENV{FSMGEN_RAM_GUARD_ACTIVE} // '') eq '1'
            && ($ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT} // '') =~
                /\A[0-9]+\z/
            && ($ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB} // '') =~
                /\A[0-9]+\z/;
    return 1;
}

sub _require_clean_revision($repository_root) {
    my $revision = _capture_command(
        'git', '-C', $repository_root, 'rev-parse', '--verify', 'HEAD',
    );
    $revision =~ s/\s+\z//;
    confess "regression gate result publisher revision is invalid\n"
        unless $revision =~ /\A[0-9a-f]{40}\z/;
    my $status = _capture_command(
        'git', '-C', $repository_root, 'status', '--porcelain=v1',
        '--untracked-files=all',
    );
    confess "regression gate result publication requires a clean Git revision\n"
        if length($status);
    return $revision;
}

sub _require_unchanged_clean_revision($repository_root, $expected) {
    my $actual = _require_clean_revision($repository_root);
    confess "regression gate result publisher revision changed\n"
        unless $actual eq $expected;
    return 1;
}

sub _capture_command(@command) {
    open my $fh, '-|', @command
        or confess "cannot execute regression gate result Git probe\n";
    local $/;
    my $output = <$fh> // '';
    close $fh or confess "regression gate result Git probe failed\n";
    return $output;
}

sub _prune_staging_parents($repository_root, $path) {
    my $stop = File::Spec->catdir(
        $repository_root, split m{/}, '.artifacts/tmp',
    );
    while ($path ne $repository_root && index($path, "$stop/") == 0) {
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

sub _require_bounded_size($actual, $maximum) {
    confess "regression gate result exceeds its bounded ceiling "
        . "(actual=$actual bytes, maximum=$maximum bytes)\n"
        unless defined($actual) && $actual > 0 && $actual <= $maximum;
    return 1;
}

sub _require_bounded_bytes($encoded, $maximum) {
    _require_bounded_size(bytes::length($encoded), $maximum);
    return 1;
}

sub _request($method, $args, $keys) {
    confess __PACKAGE__ . "->$method expects one closed hash\n"
        unless @$args == 1 && ref($args->[0]) eq 'HASH'
            && !blessed($args->[0]);
    _exact_keys($args->[0], $keys, "regression gate result $method request");
    return $args->[0];
}

sub _exact_keys($value, $keys, $label) {
    confess "$label must be one unblessed hash\n"
        unless ref($value) eq 'HASH' && !blessed($value)
            && ref($keys) eq 'ARRAY';
    my %expected = map { $_ => 1 } @$keys;
    confess "$label contains unknown key '$_'\n"
        for grep { !$expected{$_} } keys %$value;
    confess "$label is missing '$_'\n"
        for grep { !exists($value->{$_}) } @$keys;
    return 1;
}

sub _exact_invocant($class, $method) {
    confess __PACKAGE__ . "->$method requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return 1;
}

sub _json_true($value) {
    return JSON::PP::is_bool($value) && $value ? 1 : 0;
}

sub _json_integer_equals($value, $expected) {
    return defined($value) && !ref($value)
        && "$value" =~ /\A(?:0|[1-9][0-9]*)\z/
        && 0 + $value == $expected;
}

sub _canonical_json($value) {
    return $JSON->encode($value);
}

sub _clone($value) {
    return $JSON->decode($JSON->encode($value));
}

1;
