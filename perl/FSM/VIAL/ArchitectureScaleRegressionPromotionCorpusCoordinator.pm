package FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusCoordinator;

use v5.20;
use strict;
use warnings;

use bytes ();
use Carp qw(confess);
use Cwd ();
use Errno qw(EAGAIN EINTR ENOENT EWOULDBLOCK);
use Fcntl qw(FD_CLOEXEC F_GETFD F_GETFL F_SETFD F_SETFL O_NONBLOCK);
use File::Spec;
use JSON::PP ();
use POSIX qw(WEXITSTATUS WIFEXITED WIFSIGNALED WNOHANG WTERMSIG _exit);
use Scalar::Util qw(blessed);
use Time::HiRes qw(sleep);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::VIAL::ArchitectureScaleRegressionPromotionCapturePlan;
use FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusStore;
use FSM::VIAL::ArchitectureScaleRegressionPromotionProfileCapture;
use FSM::VIAL::ArchitectureScaleRegressionPromotionProfileStore;

my $PLAN =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionCapturePlan';
my $CORPUS_STORE =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusStore';
my $PROFILE_CAPTURE =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionProfileCapture';
my $PROFILE_STORE =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionProfileStore';

my $SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_corpus_coordination.v2';
my $INVENTORY_SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_corpus_inventory.v1';
my $PROFILE_RESULT_SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_profile_capture.v1';
my $PROFILE_ARTIFACT_SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_profile_artifact.v1';
my $CORPUS_ARTIFACT_SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_corpus_artifact.v1';
my $PROFILE_WORKER_ERROR_SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_corpus_profile_worker_error.v1';

my $COORDINATION_REVISION =
    'regression_promotion_corpus_coordinator_v2';
my $PROFILE_COUNT = 11;
my $VALIDATION_RECORDS = 11;
my $RAW_MEASUREMENT_RECORDS = 33;
my $CONTROLLER_INVOCATIONS = 44;
my $SAMPLE_EXCLUSIONS = 0;

my $PROFILE_LIMITS = $PROFILE_CAPTURE->capture_limits;
my $MAX_PROFILE_IPC_BYTES = $PROFILE_LIMITS->{maximum_ipc_bytes};
my $MAX_ERROR_BYTES = $PROFILE_LIMITS->{maximum_error_bytes};

my @RESULT_KEYS = qw(
    schema schema_version operation plan_identity policy_identity
    capture_revision execution_revision common_identity summary profiles
    corpus_identity publication_identity corpus_artifact
);
my @SUMMARY_KEYS = qw(
    profile_count captured_profiles resumed_profiles validated_profiles
    validation_records raw_measurement_records controller_invocations
    sample_exclusions
);
my @PROFILE_OUTCOME_KEYS = qw(
    ordinal selection_key operation report_identity provider_status
    applicability_status artifact
);
my @INVENTORY_KEYS = qw(
    schema schema_version plan_identity policy_identity git_revision
    profile_count present_profiles missing_profiles profiles corpus
);
my @INVENTORY_PROFILE_KEYS = qw(
    ordinal selection_key status report_identity artifact
);
my @INVENTORY_CORPUS_KEYS = qw(
    status corpus_identity publication_identity artifact
);
my @COMMON_KEYS = qw(
    git_revision dirty_state host_profile tool_profile resource_guard
);
my @CORPUS_COMMON_KEYS = qw(
    git_revision dirty_state host_profile resource_guard
);
my @PROVIDER_KEYS = qw(
    kind external_verification_tool logical_name provider_identity
    tool_profile_identity
);
my @APPLICABILITY_KEYS = qw(
    required predicate controller_applicable measurement_applicable
    validation_records raw_measurement_records sample_exclusions outcome
);
my @PROFILE_WORKER_ERROR_KEYS = qw(schema schema_version error);
my $JSON = JSON::PP->new->canonical(1)->utf8(1);

sub result_keys($class) {
    _exact_invocant($class, 'result_keys');
    return [@RESULT_KEYS];
}

sub summary_keys($class) {
    _exact_invocant($class, 'summary_keys');
    return [@SUMMARY_KEYS];
}

sub profile_outcome_keys($class) {
    _exact_invocant($class, 'profile_outcome_keys');
    return [@PROFILE_OUTCOME_KEYS];
}

sub inventory_keys($class) {
    _exact_invocant($class, 'inventory_keys');
    return [@INVENTORY_KEYS];
}

sub inventory_profile_keys($class) {
    _exact_invocant($class, 'inventory_profile_keys');
    return [@INVENTORY_PROFILE_KEYS];
}

sub coordination_limits($class) {
    _exact_invocant($class, 'coordination_limits');
    return {
        coordination_revision => $COORDINATION_REVISION,
        maximum_profile_ipc_bytes => $MAX_PROFILE_IPC_BYTES,
        maximum_error_bytes => $MAX_ERROR_BYTES,
        profile_count => $PROFILE_COUNT,
        validation_records => $VALIDATION_RECORDS,
        raw_measurement_records => $RAW_MEASUREMENT_RECORDS,
        controller_invocations => $CONTROLLER_INVOCATIONS,
    };
}

sub inventory($class, @args) {
    _exact_invocant($class, 'inventory');
    my $request = _request('inventory', \@args, [qw(repository_root)]);
    _require_active_guard();
    my ($repo_root, $root_device) =
        _repository_root($request->{repository_root});
    my $git_revision = _require_clean_revision($repo_root);
    my $plan = $PLAN->derive({repository_root => $repo_root});
    my $inventory = _inventory(
        $repo_root, $root_device, $plan, $git_revision,
    );
    _require_unchanged_clean_revision($repo_root, $git_revision);
    _validate_inventory($inventory, $plan, $git_revision);
    return _clone($inventory);
}

sub capture($class, @args) {
    _exact_invocant($class, 'capture');
    my $request = _request('capture', \@args, [qw(repository_root)]);
    return _clone(_coordinate('capture', $request->{repository_root}));
}

sub validate($class, @args) {
    _exact_invocant($class, 'validate');
    my $request = _request('validate', \@args, [qw(repository_root)]);
    return _clone(_coordinate('validate', $request->{repository_root}));
}

sub _coordinate($operation, $repository_root) {
    confess "corpus coordination operation is invalid\n"
        unless $operation =~ /\A(?:capture|validate)\z/;
    _require_active_guard();
    my ($repo_root, $root_device) = _repository_root($repository_root);
    my $execution_revision = _require_clean_revision($repo_root);
    my $plan = $PLAN->derive({repository_root => $repo_root});
    confess "corpus coordination plan cardinality changed\n"
        unless ref($plan->{entries}) eq 'ARRAY'
            && @{$plan->{entries}} == $PROFILE_COUNT;

    my ($capture_revision, $validation_authority) =
        ($execution_revision, undef);
    if ($operation eq 'validate') {
        my $state = _corpus_inventory(
            $repo_root, $root_device, $plan,
        );
        _require_unchanged_clean_revision(
            $repo_root, $execution_revision,
        );
        confess "corpus validation requires an existing complete publication\n"
            unless $state->{status} eq 'present';
        $validation_authority = $CORPUS_STORE->load({
            repository_root => $repo_root,
        });
        _require_unchanged_clean_revision(
            $repo_root, $execution_revision,
        );
        $capture_revision = _validation_capture_revision(
            $validation_authority,
        );
    }

    my (@profiles, @outcomes);
    my ($captured, $resumed) = (0, 0);
    my $corpus_common;
    for my $index (0 .. $PROFILE_COUNT - 1) {
        my $entry = $plan->{entries}[$index];
        confess "corpus coordination plan order changed\n"
            unless _json_integer_equals($entry->{ordinal}, $index + 1);
        my $state = _profile_inventory(
            $repo_root, $root_device, $entry,
        );
        if ($operation eq 'validate' && $state->{status} ne 'present') {
            confess "corpus validation profile $entry->{ordinal} is missing\n";
        }
        my $profile_operation = $operation eq 'validate'
            ? 'corpus_validate_resume'
            : $state->{status} eq 'present' ? 'resume' : 'capture';
        my $result = _run_profile_operation(
            $profile_operation, $repo_root, $entry->{ordinal},
            $capture_revision,
        );
        _require_unchanged_clean_revision($repo_root, $execution_revision);
        my $reported_profile_operation =
            $profile_operation eq 'corpus_validate_resume'
                ? 'resume' : $profile_operation;
        _validate_profile_result(
            $result, $reported_profile_operation, $plan, $entry,
            $capture_revision,
        );
        _require_loaded_profile_match($repo_root, $entry, $result);
        my $candidate = _corpus_common($result->{common_identity});
        if (defined $corpus_common) {
            confess "corpus coordination common identity changed\n"
                unless _canonical_json($candidate)
                    eq _canonical_json($corpus_common);
        }
        else {
            $corpus_common = $candidate;
        }
        push @profiles, _clone($result);
        push @outcomes, _profile_outcome(
            $reported_profile_operation, $result,
        );
        $reported_profile_operation eq 'capture'
            ? $captured++ : $resumed++;
    }
    confess "corpus coordination did not visit every profile exactly once\n"
        unless @profiles == $PROFILE_COUNT
            && $captured + $resumed == $PROFILE_COUNT;

    my ($published_artifact, $loaded);
    if ($operation eq 'capture') {
        $published_artifact = $CORPUS_STORE->publish({
            repository_root => $repo_root,
            profiles => \@profiles,
        });
        _require_unchanged_clean_revision($repo_root, $execution_revision);
        $loaded = $CORPUS_STORE->load({repository_root => $repo_root});
    }
    else {
        $loaded = $CORPUS_STORE->load({repository_root => $repo_root});
        $published_artifact = $loaded->{artifact};
    }
    _require_unchanged_clean_revision($repo_root, $execution_revision);
    confess "complete corpus changed during validation\n"
        if defined($validation_authority)
            && _canonical_json($loaded) ne
                _canonical_json($validation_authority);
    _require_corpus_profile_match($loaded, \@profiles, $plan);

    my $result = {
        schema => $SCHEMA,
        schema_version => 2,
        operation => $operation,
        plan_identity => $plan->{plan_identity},
        policy_identity => $plan->{policy_identity},
        capture_revision => $capture_revision,
        execution_revision => $execution_revision,
        common_identity => $corpus_common,
        summary => {
            profile_count => $PROFILE_COUNT,
            captured_profiles => $captured,
            resumed_profiles => $resumed,
            validated_profiles => $PROFILE_COUNT,
            validation_records => $VALIDATION_RECORDS,
            raw_measurement_records => $RAW_MEASUREMENT_RECORDS,
            controller_invocations => $CONTROLLER_INVOCATIONS,
            sample_exclusions => $SAMPLE_EXCLUSIONS,
        },
        profiles => \@outcomes,
        corpus_identity => $loaded->{report}{corpus_identity},
        publication_identity => $loaded->{manifest}{publication_identity},
        corpus_artifact => _clone($published_artifact),
    };
    _validate_result(
        $result, $plan, $operation,
        $capture_revision, $execution_revision,
    );
    return $result;
}

sub _inventory($repo_root, $root_device, $plan, $git_revision) {
    my @profiles;
    my ($present, $missing) = (0, 0);
    for my $entry (@{$plan->{entries}}) {
        my $profile = _profile_inventory(
            $repo_root, $root_device, $entry,
        );
        push @profiles, $profile;
        $profile->{status} eq 'present' ? $present++ : $missing++;
    }
    return {
        schema => $INVENTORY_SCHEMA,
        schema_version => 1,
        plan_identity => $plan->{plan_identity},
        policy_identity => $plan->{policy_identity},
        git_revision => $git_revision,
        profile_count => $PROFILE_COUNT,
        present_profiles => $present,
        missing_profiles => $missing,
        profiles => \@profiles,
        corpus => _corpus_inventory(
            $repo_root, $root_device, $plan,
        ),
    };
}

sub _profile_inventory($repo_root, $root_device, $entry) {
    my $state = _relative_file_state(
        $repo_root, $root_device, $entry->{publication_relative_path},
        "profile $entry->{ordinal} publication",
    );
    return {
        ordinal => 0 + $entry->{ordinal},
        selection_key => $entry->{selection_key},
        status => 'missing',
        report_identity => undef,
        artifact => undef,
    } if $state eq 'missing';
    my $loaded = $PROFILE_STORE->load({
        repository_root => $repo_root,
        ordinal => $entry->{ordinal},
    });
    return {
        ordinal => 0 + $entry->{ordinal},
        selection_key => $entry->{selection_key},
        status => 'present',
        report_identity => $loaded->{publication}{report}{report_identity},
        artifact => _clone($loaded->{artifact}),
    };
}

sub _corpus_inventory($repo_root, $root_device, $plan) {
    my $limits = $CORPUS_STORE->publication_limits;
    my $relative = join '/',
        $plan->{publication_base}, $plan->{publication_id}, 'complete',
        $limits->{report_filename};
    my $state = _relative_file_state(
        $repo_root, $root_device, $relative, 'complete corpus publication',
    );
    return {
        status => 'missing',
        corpus_identity => undef,
        publication_identity => undef,
        artifact => undef,
    } if $state eq 'missing';
    my $loaded = $CORPUS_STORE->load({repository_root => $repo_root});
    return {
        status => 'present',
        corpus_identity => $loaded->{report}{corpus_identity},
        publication_identity => $loaded->{manifest}{publication_identity},
        artifact => _clone($loaded->{artifact}),
    };
}

sub _relative_file_state(
    $repo_root, $root_device, $relative, $label,
) {
    _safe_relative_path($relative);
    my @parts = split m{/}, $relative;
    my $cursor = $repo_root;
    for my $index (0 .. $#parts) {
        $cursor = File::Spec->catfile($cursor, $parts[$index]);
        my @stat = lstat($cursor);
        if (!@stat) {
            return 'missing' if $! == ENOENT && $index < $#parts;
            confess "$label is incomplete\n" if $! == ENOENT;
            confess "cannot inspect $label\n";
        }
        confess "$label crosses a symbolic link\n" if -l _;
        confess "$label changed filesystem device\n"
            unless $stat[0] == $root_device;
        confess "$label owner changed\n" unless $stat[4] == $<;
        if ($index < $#parts) {
            confess "$label path component is not a directory\n"
                unless -d _;
        }
        else {
            confess "$label is not a regular file\n" unless -f _;
            confess "$label has multiple links\n" unless $stat[3] == 1;
        }
    }
    return 'present';
}

sub _run_profile_operation(
    $operation, $repo_root, $ordinal, $capture_revision,
) {
    confess "corpus profile operation is invalid\n"
        unless $operation =~ /\A(?:capture|resume|corpus_validate_resume)\z/;
    pipe(my $reader, my $writer)
        or confess "cannot create corpus profile worker pipe\n";
    my $descriptor_ok = eval {
        _set_profile_worker_close_on_exec($reader, 'reader');
        _set_profile_worker_close_on_exec($writer, 'writer');
        my $flags = fcntl($reader, F_GETFL, 0);
        confess "cannot inspect corpus profile worker reader flags\n"
            unless defined $flags;
        confess "cannot make corpus profile worker reader nonblocking\n"
            unless fcntl($reader, F_SETFL, $flags | O_NONBLOCK);
        1;
    };
    if (!$descriptor_ok) {
        my $error = $@;
        close $reader;
        close $writer;
        die $error;
    }

    my $pid = fork();
    if (!defined $pid) {
        close $reader;
        close $writer;
        confess "cannot fork corpus profile worker\n";
    }
    if ($pid == 0) {
        close $reader;
        my ($encoded, $worker_error);
        my $ok = eval {
            my $result = _run_profile_operation_in_child(
                $operation, $repo_root, $ordinal, $capture_revision,
            );
            $encoded = _canonical_json($result);
            confess "corpus profile worker metadata exceeded the bounded envelope\n"
                if bytes::length($encoded) > $MAX_PROFILE_IPC_BYTES;
            1;
        };
        $worker_error = $@ unless $ok;
        my $exit_code = 0;
        if (defined $worker_error) {
            $encoded = _canonical_json({
                schema => $PROFILE_WORKER_ERROR_SCHEMA,
                schema_version => 1,
                error => _bounded_profile_worker_error($worker_error),
            });
            $exit_code = 70;
        }
        my $written = _write_profile_worker_result($writer, $encoded);
        close $writer;
        _exit($written ? $exit_code : 74);
    }

    close $writer;
    my ($buffer, $read_error, $wait_status, $done) = ('', undef, undef, 0);
    while (!$done) {
        $read_error //= _drain_profile_worker_pipe($reader, \$buffer);
        if (defined $read_error) {
            kill 'TERM', $pid;
            my $waited = waitpid($pid, 0);
            $wait_status = $? if $waited == $pid;
            last;
        }
        my $waited = waitpid($pid, WNOHANG);
        if ($waited == $pid) {
            $wait_status = $?;
            $done = 1;
        }
        elsif ($waited == -1) {
            $read_error = 'cannot wait for corpus profile worker';
            $done = 1;
        }
        else {
            sleep(0.01);
        }
    }
    $read_error //= _drain_profile_worker_pipe($reader, \$buffer);
    close $reader
        or $read_error //= 'cannot close corpus profile worker reader';
    confess "$read_error\n" if defined $read_error;

    my $signal = defined($wait_status) && WIFSIGNALED($wait_status)
        ? WTERMSIG($wait_status) : 0;
    confess "corpus profile worker terminated by signal $signal\n"
        if $signal;
    my $exit_code = defined($wait_status) && WIFEXITED($wait_status)
        ? WEXITSTATUS($wait_status) : undef;
    if (defined($exit_code) && $exit_code == 0) {
        return _decode_profile_worker_result($buffer);
    }
    my ($failure, $decode_error) =
        _decode_profile_worker_failure($buffer);
    if (defined $decode_error) {
        my $status = defined($exit_code)
            ? " with exit status $exit_code" : '';
        confess "corpus profile worker $decode_error$status\n";
    }
    confess "corpus profile worker failed: $failure->{error}\n";
}

sub _run_profile_operation_in_child(
    $operation, $repo_root, $ordinal, $capture_revision,
) {
    confess "corpus profile child operation is invalid\n"
        unless $operation =~ /\A(?:capture|resume|corpus_validate_resume)\z/;
    my $result = $operation eq 'corpus_validate_resume'
        ? $PROFILE_CAPTURE->_corpus_validate_resume({
            repository_root => $repo_root,
            ordinal => $ordinal,
            capture_revision => $capture_revision,
        })
        : $PROFILE_CAPTURE->$operation({
            repository_root => $repo_root,
            ordinal => $ordinal,
        });
    my $encoded = _canonical_json($result);
    confess "corpus profile worker metadata exceeded the bounded envelope\n"
        if bytes::length($encoded) > $MAX_PROFILE_IPC_BYTES;
    return $result;
}

sub _decode_profile_worker_result($buffer) {
    confess "corpus profile worker returned no result\n"
        unless length($buffer // '');
    confess "corpus profile worker result exceeded the bounded envelope\n"
        if bytes::length($buffer) > $MAX_PROFILE_IPC_BYTES;
    my $decoded = eval { JSON::PP->new->utf8(1)->decode($buffer) };
    confess "corpus profile worker result is not valid JSON\n"
        unless defined $decoded;
    confess "corpus profile worker result is not canonical JSON\n"
        unless _canonical_json($decoded) eq $buffer;
    confess "corpus profile worker result is invalid\n"
        unless ref($decoded) eq 'HASH' && !blessed($decoded);
    return _clone($decoded);
}

sub _decode_profile_worker_failure($buffer) {
    return (undef, 'returned no result') unless length($buffer // '');
    return (undef, 'result exceeded the bounded envelope')
        if bytes::length($buffer) > $MAX_PROFILE_IPC_BYTES;
    my $decoded = eval { JSON::PP->new->utf8(1)->decode($buffer) };
    return (undef, 'result is not valid JSON') unless defined $decoded;
    return (undef, 'result is not canonical JSON')
        unless _canonical_json($decoded) eq $buffer;
    my $valid = eval {
        _exact_keys(
            $decoded, \@PROFILE_WORKER_ERROR_KEYS,
            'corpus profile worker failure',
        );
        confess "corpus profile worker failure schema is invalid\n"
            unless ($decoded->{schema} // '') eq $PROFILE_WORKER_ERROR_SCHEMA
                && _json_integer_equals($decoded->{schema_version}, 1);
        confess "corpus profile worker failure error is invalid\n"
            unless defined($decoded->{error}) && !ref($decoded->{error})
                && length($decoded->{error})
                && bytes::length($decoded->{error}) <= $MAX_ERROR_BYTES;
        1;
    };
    return (undef, _bounded_profile_worker_error($@)) unless $valid;
    return ($decoded, undef);
}

sub _bounded_profile_worker_error($error) {
    $error = 'corpus profile worker failed without an exception'
        unless defined($error) && !ref($error) && length($error);
    $error =~ s/[^\x20-\x7e]+/ /g;
    $error =~ s/\s+/ /g;
    $error =~ s/\A\s+|\s+\z//g;
    $error = 'corpus profile worker failed without a usable exception'
        unless length($error);
    return substr($error, 0, $MAX_ERROR_BYTES);
}

sub _write_profile_worker_result($writer, $encoded) {
    my $offset = 0;
    while ($offset < bytes::length($encoded)) {
        my $written = syswrite(
            $writer, $encoded, bytes::length($encoded) - $offset, $offset,
        );
        if (!defined $written) {
            next if $! == EINTR;
            return 0;
        }
        return 0 unless $written > 0;
        $offset += $written;
    }
    return 1;
}

sub _drain_profile_worker_pipe($reader, $buffer_ref) {
    while (1) {
        my $chunk = '';
        my $read = sysread($reader, $chunk, 16_384);
        if (!defined $read) {
            next if $! == EINTR;
            return undef if $! == EAGAIN || $! == EWOULDBLOCK;
            return 'cannot read corpus profile worker result';
        }
        return undef if $read == 0;
        $$buffer_ref .= $chunk;
        return 'corpus profile worker result exceeded the bounded envelope'
            if bytes::length($$buffer_ref) > $MAX_PROFILE_IPC_BYTES;
    }
}

sub _set_profile_worker_close_on_exec($handle, $label) {
    my $flags = fcntl($handle, F_GETFD, 0);
    confess "cannot inspect corpus profile worker $label descriptor\n"
        unless defined $flags;
    confess "cannot protect corpus profile worker $label descriptor\n"
        unless fcntl($handle, F_SETFD, $flags | FD_CLOEXEC);
}

sub _validate_profile_result(
    $result, $operation, $plan, $entry, $capture_revision,
) {
    _exact_keys(
        $result, $PROFILE_CAPTURE->result_keys,
        'corpus coordination profile result',
    );
    confess "corpus coordination profile result schema is invalid\n"
        unless ($result->{schema} // '') eq $PROFILE_RESULT_SCHEMA
            && _json_integer_equals($result->{schema_version}, 1);
    confess "corpus coordination profile plan binding changed\n"
        unless ($result->{plan_identity} // '') eq $plan->{plan_identity}
            && ($result->{policy_identity} // '') eq $plan->{policy_identity};
    confess "corpus coordination profile order changed\n"
        unless _json_integer_equals($result->{ordinal}, $entry->{ordinal})
            && ($result->{selection_key} // '') eq $entry->{selection_key};
    confess "corpus coordination report identity is invalid\n"
        unless ($result->{report_identity} // '')
            =~ m{\A[A-Za-z0-9_.-]+/[0-9a-f]{64}\z};

    _exact_keys(
        $result->{common_identity}, \@COMMON_KEYS,
        'corpus coordination profile common identity',
    );
    confess "corpus coordination profile revision changed\n"
        unless ($result->{common_identity}{git_revision} // '')
                eq $capture_revision
            && !_json_boolean(
                $result->{common_identity}{dirty_state},
                'corpus coordination profile dirty state',
            );
    confess "corpus coordination profile environment is invalid\n"
        unless ref($result->{common_identity}{host_profile}) eq 'HASH'
            && !blessed($result->{common_identity}{host_profile})
            && ref($result->{common_identity}{tool_profile}) eq 'HASH'
            && !blessed($result->{common_identity}{tool_profile})
            && ref($result->{common_identity}{resource_guard}) eq 'HASH'
            && !blessed($result->{common_identity}{resource_guard})
            && _json_boolean(
                $result->{common_identity}{resource_guard}{active},
                'corpus coordination profile active guard',
            );

    _exact_keys(
        $result->{provider_status}, \@PROVIDER_KEYS,
        'corpus coordination profile provider status',
    );
    confess "corpus coordination profile provider changed\n"
        unless _canonical_json($result->{provider_status})
            eq _canonical_json($entry->{provider_requirement});
    _exact_keys(
        $result->{applicability_status}, \@APPLICABILITY_KEYS,
        'corpus coordination profile applicability',
    );
    my $applicability = $result->{applicability_status};
    confess "corpus coordination profile applicability changed\n"
        unless _json_boolean(
                $applicability->{required},
                'corpus coordination required applicability',
            )
            && _json_boolean(
                $applicability->{controller_applicable},
                'corpus coordination controller applicability',
            )
            && _json_boolean(
                $applicability->{measurement_applicable},
                'corpus coordination measurement applicability',
            )
            && _json_integer_equals($applicability->{validation_records}, 1)
            && _json_integer_equals(
                $applicability->{raw_measurement_records}, 3,
            )
            && _json_integer_equals($applicability->{sample_exclusions}, 0)
            && ($applicability->{predicate} // '') eq
                $entry->{applicability_requirement}{predicate}
            && ($applicability->{outcome} // '') eq 'accepted';

    my $artifact = $result->{artifact};
    _exact_keys(
        $artifact, $PROFILE_STORE->artifact_keys,
        'corpus coordination profile artifact',
    );
    confess "corpus coordination profile artifact schema is invalid\n"
        unless ($artifact->{schema} // '') eq $PROFILE_ARTIFACT_SCHEMA
            && _json_integer_equals($artifact->{schema_version}, 1);
    my $expected_status = $operation eq 'resume' ? 'loaded' : undef;
    confess "corpus coordination resume did not load the exact profile\n"
        if defined($expected_status)
            && ($artifact->{status} // '') ne $expected_status;
    confess "corpus coordination capture returned a resume artifact\n"
        if $operation eq 'capture'
            && ($artifact->{status} // '') eq 'loaded';
    confess "corpus coordination profile artifact status is invalid\n"
        unless ($artifact->{status} // '')
            =~ /\A(?:loaded|published|recovered|unchanged)\z/;
    confess "corpus coordination profile artifact coordinate changed\n"
        unless _json_integer_equals($artifact->{ordinal}, $entry->{ordinal})
            && ($artifact->{selection_key} // '') eq $entry->{selection_key}
            && ($artifact->{artifact_relative_path} // '') eq
                $entry->{publication_relative_path};
    confess "corpus coordination profile artifact identity is invalid\n"
        unless ($artifact->{artifact_sha256} // '') =~ /\A[0-9a-f]{64}\z/
            && _json_positive_integer($artifact->{artifact_bytes})
            && $artifact->{artifact_bytes} <=
                $PROFILE_STORE->publication_limits->{maximum_publication_bytes}
            && _json_boolean(
                $artifact->{same_volume},
                'corpus coordination profile same-volume status',
            )
            && _json_boolean(
                $artifact->{atomic},
                'corpus coordination profile atomic status',
            );
    return 1;
}

sub _require_loaded_profile_match($repo_root, $entry, $result) {
    my $loaded = $PROFILE_STORE->load({
        repository_root => $repo_root,
        ordinal => $entry->{ordinal},
    });
    confess "corpus coordination profile report changed after worker return\n"
        unless ($loaded->{publication}{report}{report_identity} // '') eq
            $result->{report_identity};
    for my $key (qw(
        ordinal selection_key artifact_relative_path artifact_sha256
        artifact_bytes same_volume atomic
    )) {
        confess "corpus coordination profile artifact changed after worker return\n"
            unless _canonical_json($loaded->{artifact}{$key})
                eq _canonical_json($result->{artifact}{$key});
    }
    return 1;
}

sub _validation_capture_revision($loaded) {
    _exact_keys(
        $loaded, $CORPUS_STORE->load_result_keys,
        'corpus validation authority',
    );
    my $report = $loaded->{report};
    confess "corpus validation report authority is invalid\n"
        unless ref($report) eq 'HASH' && !blessed($report);
    my $common = $report->{common_identity};
    _exact_keys(
        $common, \@CORPUS_COMMON_KEYS,
        'corpus validation common authority',
    );
    my $capture_revision = $common->{git_revision};
    confess "corpus validation capture revision is invalid\n"
        unless defined($capture_revision) && !ref($capture_revision)
            && $capture_revision =~ /\A[0-9a-f]{40}\z/
            && !_json_boolean(
                $common->{dirty_state},
                'corpus validation common dirty state',
            );
    confess "corpus validation profile authority is invalid\n"
        unless ref($report->{profiles}) eq 'ARRAY'
            && @{$report->{profiles}} == $PROFILE_COUNT;
    for my $profile (@{$report->{profiles}}) {
        my $profile_common = $profile->{common_identity};
        _exact_keys(
            $profile_common, \@COMMON_KEYS,
            'corpus validation profile common authority',
        );
        confess "corpus validation profile capture revision changed\n"
            unless ($profile_common->{git_revision} // '') eq
                    $capture_revision
                && !_json_boolean(
                    $profile_common->{dirty_state},
                    'corpus validation profile dirty state',
                );
    }
    return $capture_revision;
}

sub _corpus_common($common) {
    _exact_keys(
        $common, \@COMMON_KEYS,
        'corpus coordination common identity',
    );
    return {
        map { $_ => _clone($common->{$_}) } @CORPUS_COMMON_KEYS
    };
}

sub _profile_outcome($operation, $result) {
    return {
        ordinal => 0 + $result->{ordinal},
        selection_key => $result->{selection_key},
        operation => $operation,
        report_identity => $result->{report_identity},
        provider_status => _clone($result->{provider_status}),
        applicability_status => _clone($result->{applicability_status}),
        artifact => _clone($result->{artifact}),
    };
}

sub _require_corpus_profile_match($loaded, $results, $plan) {
    _exact_keys(
        $loaded, $CORPUS_STORE->load_result_keys,
        'corpus coordination loaded publication',
    );
    confess "corpus coordination loaded profile count changed\n"
        unless ref($loaded->{report}{profiles}) eq 'ARRAY'
            && @{$loaded->{report}{profiles}} == $PROFILE_COUNT
            && @$results == $PROFILE_COUNT;
    for my $index (0 .. $PROFILE_COUNT - 1) {
        my $expected = _corpus_profile_projection(
            $results->[$index], $plan->{entries}[$index],
        );
        confess "corpus coordination complete profile changed\n"
            unless _canonical_json($loaded->{report}{profiles}[$index])
                eq _canonical_json($expected);
    }
    return 1;
}

sub _corpus_profile_projection($result, $entry) {
    my $artifact = $result->{artifact};
    return {
        ordinal => 0 + $entry->{ordinal},
        selection_key => $entry->{selection_key},
        report_identity => $result->{report_identity},
        common_identity => _clone($result->{common_identity}),
        provider_status => _clone($result->{provider_status}),
        applicability_status => _clone($result->{applicability_status}),
        artifact => {
            ordinal => 0 + $entry->{ordinal},
            selection_key => $entry->{selection_key},
            relative_path => $artifact->{artifact_relative_path},
            sha256 => $artifact->{artifact_sha256},
            bytes => 0 + $artifact->{artifact_bytes},
            same_volume => JSON::PP::true,
            atomic => JSON::PP::true,
        },
    };
}

sub _validate_result(
    $result, $plan, $operation, $capture_revision, $execution_revision,
) {
    _exact_keys($result, \@RESULT_KEYS, 'corpus coordination result');
    confess "corpus coordination result schema is invalid\n"
        unless ($result->{schema} // '') eq $SCHEMA
            && _json_integer_equals($result->{schema_version}, 2);
    confess "corpus coordination result operation changed\n"
        unless ($result->{operation} // '') eq $operation;
    confess "corpus coordination result plan binding changed\n"
        unless ($result->{plan_identity} // '') eq $plan->{plan_identity}
            && ($result->{policy_identity} // '') eq $plan->{policy_identity}
            && ($result->{capture_revision} // '') eq $capture_revision
            && ($result->{execution_revision} // '') eq $execution_revision
            && $result->{capture_revision} =~ /\A[0-9a-f]{40}\z/
            && $result->{execution_revision} =~ /\A[0-9a-f]{40}\z/;
    confess "corpus capture used different evidence and execution revisions\n"
        if $operation eq 'capture'
            && $capture_revision ne $execution_revision;
    _exact_keys(
        $result->{common_identity}, \@CORPUS_COMMON_KEYS,
        'corpus coordination result common identity',
    );
    confess "corpus coordination result common revision changed\n"
        unless ($result->{common_identity}{git_revision} // '') eq
            $capture_revision;
    _exact_keys($result->{summary}, \@SUMMARY_KEYS,
        'corpus coordination result summary');
    my $summary = $result->{summary};
    for my $key (@SUMMARY_KEYS) {
        confess "corpus coordination result summary '$key' is invalid\n"
            unless _json_nonnegative_integer($summary->{$key});
    }
    confess "corpus coordination result census changed\n"
        unless _json_integer_equals($summary->{profile_count}, $PROFILE_COUNT)
            && _json_integer_equals(
                $summary->{captured_profiles} +
                    $summary->{resumed_profiles},
                $PROFILE_COUNT,
            )
            && _json_integer_equals(
                $summary->{validated_profiles}, $PROFILE_COUNT,
            )
            && _json_integer_equals(
                $summary->{validation_records}, $VALIDATION_RECORDS,
            )
            && _json_integer_equals(
                $summary->{raw_measurement_records},
                $RAW_MEASUREMENT_RECORDS,
            )
            && _json_integer_equals(
                $summary->{controller_invocations},
                $CONTROLLER_INVOCATIONS,
            )
            && _json_integer_equals(
                $summary->{sample_exclusions}, $SAMPLE_EXCLUSIONS,
            );
    confess "corpus validation unexpectedly captured a profile\n"
        if $operation eq 'validate'
            && !_json_integer_equals($summary->{captured_profiles}, 0);
    confess "corpus coordination result profiles are invalid\n"
        unless ref($result->{profiles}) eq 'ARRAY'
            && @{$result->{profiles}} == $PROFILE_COUNT;
    for my $index (0 .. $PROFILE_COUNT - 1) {
        my $profile = $result->{profiles}[$index];
        _exact_keys(
            $profile, \@PROFILE_OUTCOME_KEYS,
            "corpus coordination result profile $index",
        );
        confess "corpus coordination result profile order changed\n"
            unless _json_integer_equals($profile->{ordinal}, $index + 1)
                && ($profile->{selection_key} // '') eq
                    $plan->{entries}[$index]{selection_key}
                && ($profile->{operation} // '') =~ /\A(?:capture|resume)\z/;
    }
    confess "corpus coordination result identities are invalid\n"
        unless ($result->{corpus_identity} // '')
                =~ m{\Aregression-promotion-corpus/[0-9a-f]{64}\z}
            && ($result->{publication_identity} // '')
                =~ m{\Aregression-promotion-corpus-publication/[0-9a-f]{64}\z};
    _exact_keys(
        $result->{corpus_artifact}, $CORPUS_STORE->artifact_keys,
        'corpus coordination result artifact',
    );
    confess "corpus coordination result artifact is invalid\n"
        unless ($result->{corpus_artifact}{schema} // '') eq
                $CORPUS_ARTIFACT_SCHEMA
            && _json_integer_equals(
                $result->{corpus_artifact}{schema_version}, 1,
            )
            && ($result->{corpus_artifact}{status} // '')
                =~ /\A(?:loaded|published|recovered|unchanged)\z/
            && _json_boolean(
                $result->{corpus_artifact}{same_volume},
                'corpus coordination complete same-volume status',
            )
            && _json_boolean(
                $result->{corpus_artifact}{atomic},
                'corpus coordination complete atomic status',
            );
    return 1;
}

sub _validate_inventory($inventory, $plan, $git_revision) {
    _exact_keys($inventory, \@INVENTORY_KEYS, 'corpus inventory');
    confess "corpus inventory schema is invalid\n"
        unless ($inventory->{schema} // '') eq $INVENTORY_SCHEMA
            && _json_integer_equals($inventory->{schema_version}, 1);
    confess "corpus inventory plan binding changed\n"
        unless ($inventory->{plan_identity} // '') eq $plan->{plan_identity}
            && ($inventory->{policy_identity} // '') eq $plan->{policy_identity}
            && ($inventory->{git_revision} // '') eq $git_revision;
    confess "corpus inventory census changed\n"
        unless _json_nonnegative_integer($inventory->{present_profiles})
            && _json_nonnegative_integer($inventory->{missing_profiles})
            && _json_integer_equals($inventory->{profile_count}, $PROFILE_COUNT)
            && _json_integer_equals(
                $inventory->{present_profiles} +
                    $inventory->{missing_profiles},
                $PROFILE_COUNT,
            )
            && ref($inventory->{profiles}) eq 'ARRAY'
            && @{$inventory->{profiles}} == $PROFILE_COUNT;
    for my $index (0 .. $PROFILE_COUNT - 1) {
        my $profile = $inventory->{profiles}[$index];
        _exact_keys(
            $profile, \@INVENTORY_PROFILE_KEYS,
            "corpus inventory profile $index",
        );
        confess "corpus inventory profile order changed\n"
            unless _json_integer_equals($profile->{ordinal}, $index + 1)
                && ($profile->{selection_key} // '') eq
                    $plan->{entries}[$index]{selection_key}
                && ($profile->{status} // '') =~ /\A(?:missing|present)\z/;
        if ($profile->{status} eq 'missing') {
            confess "missing corpus inventory profile retained evidence\n"
                if defined($profile->{report_identity})
                    || defined($profile->{artifact});
        }
        else {
            confess "present corpus inventory profile identity is invalid\n"
                unless ($profile->{report_identity} // '')
                    =~ m{\A[A-Za-z0-9_.-]+/[0-9a-f]{64}\z};
            _exact_keys(
                $profile->{artifact}, $PROFILE_STORE->artifact_keys,
                "corpus inventory profile $index artifact",
            );
        }
    }
    _exact_keys(
        $inventory->{corpus}, \@INVENTORY_CORPUS_KEYS,
        'corpus inventory complete publication',
    );
    confess "corpus inventory complete status is invalid\n"
        unless ($inventory->{corpus}{status} // '')
            =~ /\A(?:missing|present)\z/;
    if ($inventory->{corpus}{status} eq 'missing') {
        confess "missing corpus inventory retained complete evidence\n"
            if defined($inventory->{corpus}{corpus_identity})
                || defined($inventory->{corpus}{publication_identity})
                || defined($inventory->{corpus}{artifact});
    }
    else {
        confess "present corpus inventory identities are invalid\n"
            unless ($inventory->{corpus}{corpus_identity} // '')
                    =~ m{\Aregression-promotion-corpus/[0-9a-f]{64}\z}
                && ($inventory->{corpus}{publication_identity} // '')
                    =~ m{\Aregression-promotion-corpus-publication/[0-9a-f]{64}\z};
        _exact_keys(
            $inventory->{corpus}{artifact}, $CORPUS_STORE->artifact_keys,
            'corpus inventory complete artifact',
        );
    }
    return 1;
}

sub _repository_root($value) {
    confess "corpus coordinator repository root is invalid\n"
        unless defined($value) && !ref($value) && length($value);
    my $root = Cwd::realpath($value);
    confess "corpus coordinator repository root is unavailable\n"
        unless defined($root) && -d $root && !-l $root;
    my $git = File::Spec->catfile($root, '.git');
    confess "corpus coordinator repository Git identity is invalid\n"
        unless (-d $git || -f $git) && !-l $git;
    my @stat = lstat($root);
    confess "corpus coordinator repository root cannot be inspected\n"
        unless @stat && !-l _ && -d _;
    confess "corpus coordinator repository root owner changed\n"
        unless $stat[4] == $<;
    return ($root, $stat[0]);
}

sub _require_clean_revision($repo_root) {
    my ($revision_ok, $revision) = _capture_command(
        'git', '-C', $repo_root, 'rev-parse', 'HEAD',
    );
    confess "cannot derive corpus coordinator Git revision\n"
        unless $revision_ok;
    $revision =~ s/\s+\z//;
    confess "corpus coordinator Git revision is invalid\n"
        unless $revision =~ /\A[0-9a-f]{40}\z/;
    my ($status_ok, $status) = _capture_command(
        'git', '-C', $repo_root, 'status', '--porcelain=v1',
        '--untracked-files=normal',
    );
    confess "cannot derive corpus coordinator Git state\n"
        unless $status_ok;
    confess "corpus coordinator requires a clean Git revision\n"
        if length($status);
    return $revision;
}

sub _require_unchanged_clean_revision($repo_root, $expected) {
    my $actual = _require_clean_revision($repo_root);
    confess "corpus coordinator Git revision changed during coordination\n"
        unless $actual eq $expected;
}

sub _capture_command(@command) {
    open my $fh, '-|', @command or return (0, '');
    local $/;
    my $output = <$fh> // '';
    my $ok = close $fh;
    return ($ok ? 1 : 0, $output);
}

sub _require_active_guard() {
    confess "corpus coordinator requires the active repository RAM guard\n"
        unless ($ENV{FSMGEN_RAM_GUARD_ACTIVE} // '') eq '1';
    my $host = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    my $rss = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    confess "corpus coordinator guard thresholds are invalid\n"
        unless defined($host) && $host =~ /\A[0-9]+(?:[.][0-9]+)?\z/
            && $host > 0 && $host <= 88
            && defined($rss) && $rss =~ /\A[0-9]+(?:[.][0-9]+)?\z/
            && $rss > 0 && $rss <= 4096;
}

sub _safe_relative_path($path) {
    confess "corpus coordinator path is invalid\n"
        unless defined($path) && !ref($path) && length($path)
            && $path !~ m{\A/}
            && $path !~ /\\/
            && $path !~ /(?:\A|\/)\.\.?\/?(?:\z|\/)/
            && $path !~ m{//};
}

sub _request($method, $args, $keys) {
    confess __PACKAGE__ . "->$method expects one closed hash\n"
        unless @{$args} == 1 && ref($args->[0]) eq 'HASH'
            && !blessed($args->[0]);
    _exact_keys($args->[0], $keys, "$method invocation");
    return $args->[0];
}

sub _exact_keys($value, $keys, $label) {
    confess "$label must be one unblessed hash\n"
        unless ref($value) eq 'HASH' && !blessed($value);
    my %expected = map { $_ => 1 } @$keys;
    for my $key (keys %$value) {
        confess "$label contains unknown key '$key'\n"
            unless $expected{$key};
    }
    for my $key (@$keys) {
        confess "$label is missing key '$key'\n"
            unless exists $value->{$key};
    }
}

sub _exact_invocant($class, $method) {
    confess __PACKAGE__ . "->$method requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
}

sub _json_boolean($value, $label) {
    confess "$label is not a JSON boolean\n"
        unless JSON::PP::is_bool($value);
    return $value ? 1 : 0;
}

sub _json_integer_equals($actual, $expected) {
    return defined($actual) && !ref($actual)
        && _canonical_json($actual) eq "$expected";
}

sub _json_positive_integer($actual) {
    return defined($actual) && !ref($actual)
        && _canonical_json($actual) =~ /\A[1-9][0-9]*\z/;
}

sub _json_nonnegative_integer($actual) {
    return defined($actual) && !ref($actual)
        && _canonical_json($actual) =~ /\A(?:0|[1-9][0-9]*)\z/;
}

sub _canonical_json($value) {
    return $JSON->encode($value);
}

sub _clone($value) {
    return $JSON->decode($JSON->encode($value));
}

1;
