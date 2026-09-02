package FSM::VIAL::ArchitectureScaleRegressionPromotionProfileCapture;

use v5.20;
use strict;
use warnings;

use bytes ();
use Carp qw(confess);
use Cwd ();
use Digest::SHA qw(sha256_hex);
use Errno qw(EAGAIN EINTR EWOULDBLOCK);
use Fcntl qw(
    FD_CLOEXEC F_GETFD F_GETFL F_SETFD F_SETFL O_NONBLOCK
);
use File::Spec;
use JSON::PP ();
use POSIX qw(WEXITSTATUS WIFEXITED WIFSIGNALED WNOHANG WTERMSIG _exit);
use Scalar::Util qw(blessed);
use Time::HiRes qw(sleep);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::VIAL::ArchitectureScaleRegressionPromotionCapturePlan;
use FSM::VIAL::ArchitectureScaleRegressionPromotionProfileStore;
use FSM::VIAL::ArchitectureScaleMeasurement;

my $PLAN = 'FSM::VIAL::ArchitectureScaleRegressionPromotionCapturePlan';
my $STORE = 'FSM::VIAL::ArchitectureScaleRegressionPromotionProfileStore';
my $MEASUREMENT = 'FSM::VIAL::ArchitectureScaleMeasurement';
my $CORPUS_COORDINATOR =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusCoordinator';
my $SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_profile_capture.v1';
my $WORKER_SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_profile_worker.v1';
my $ARTIFACT_SCHEMA =
    'fsmgen.vial_architecture_scale_regression_promotion_profile_artifact.v1';

my @RESULT_KEYS = qw(
    schema schema_version plan_identity policy_identity ordinal selection_key
    report_identity common_identity provider_status applicability_status
    artifact
);
my @COMMON_KEYS = qw(
    git_revision dirty_state host_profile tool_profile resource_guard
);
my @PROVIDER_KEYS = qw(
    kind external_verification_tool logical_name provider_identity
    tool_profile_identity
);
my @APPLICABILITY_KEYS = qw(
    required predicate controller_applicable measurement_applicable
    validation_records raw_measurement_records sample_exclusions outcome
);
my @WORKER_ENVELOPE_KEYS = qw(schema schema_version ok payload error);
my $LIMITS = $STORE->publication_limits;
my $MAX_WORKER_BYTES = $LIMITS->{maximum_ipc_bytes};
my $MAX_WORKER_ERROR_BYTES = $LIMITS->{maximum_error_bytes};
my $JSON = JSON::PP->new->canonical(1)->utf8(1);

sub result_keys($class) {
    _exact_invocant($class, 'result_keys');
    return [@RESULT_KEYS];
}

sub capture_limits($class) {
    _exact_invocant($class, 'capture_limits');
    return {
        capture_revision => 'regression_promotion_profile_capture_v1',
        maximum_ipc_bytes => $MAX_WORKER_BYTES,
        maximum_error_bytes => $MAX_WORKER_ERROR_BYTES,
        validation_records => 1,
        raw_measurement_records => 3,
        controller_invocations => 4,
    };
}

sub capture($class, @args) {
    _exact_invocant($class, 'capture');
    my $request = _request(
        'capture', \@args, [qw(repository_root ordinal)],
    );
    _require_active_guard();
    my $repo_root = _repository_root($request->{repository_root});
    my ($plan, $entry) = _current_entry($repo_root, $request->{ordinal});
    my $git_revision = _require_clean_revision($repo_root);
    my $result = _run_profile_worker({
        operation => 'capture',
        repository_root => $repo_root,
        plan => $plan,
        entry => $entry,
        git_revision => $git_revision,
        execution_revision => $git_revision,
    });
    _require_unchanged_clean_revision($repo_root, $git_revision);
    _validate_result($result, $plan, $entry, $git_revision);
    confess "profile capture worker returned a resume artifact\n"
        if ($result->{artifact}{status} // '') eq 'loaded';
    _revalidate_in_parent(
        'capture', $repo_root, $plan, $entry,
        $git_revision, $git_revision, $result,
    );
    return _clone($result);
}

sub resume($class, @args) {
    _exact_invocant($class, 'resume');
    my $request = _request(
        'resume', \@args, [qw(repository_root ordinal)],
    );
    _require_active_guard();
    my $repo_root = _repository_root($request->{repository_root});
    my ($plan, $entry) = _current_entry($repo_root, $request->{ordinal});
    my $git_revision = _require_clean_revision($repo_root);
    my $result = _run_profile_worker({
        operation => 'resume',
        repository_root => $repo_root,
        plan => $plan,
        entry => $entry,
        git_revision => $git_revision,
        execution_revision => $git_revision,
    });
    _require_unchanged_clean_revision($repo_root, $git_revision);
    _validate_result($result, $plan, $entry, $git_revision);
    confess "profile resume worker did not load an existing artifact\n"
        unless ($result->{artifact}{status} // '') eq 'loaded';
    _revalidate_in_parent(
        'resume', $repo_root, $plan, $entry,
        $git_revision, $git_revision, $result,
    );
    return _clone($result);
}

# A complete corpus has already authenticated one immutable capture revision.
# This exact-caller seam revalidates those sealed bytes with the current clean
# implementation without weakening public same-revision profile resume.
sub _corpus_validate_resume($class, @args) {
    _exact_invocant($class, '_corpus_validate_resume');
    my $caller = caller;
    confess "profile corpus-validation resume is private to the exact coordinator\n"
        unless defined($caller) && $caller eq $CORPUS_COORDINATOR;
    my $request = _request(
        '_corpus_validate_resume', \@args,
        [qw(repository_root ordinal capture_revision)],
    );
    my $capture_revision = $request->{capture_revision};
    confess "profile corpus-validation capture revision is invalid\n"
        unless defined($capture_revision) && !ref($capture_revision)
            && $capture_revision =~ /\A[0-9a-f]{40}\z/;
    _require_active_guard();
    my $repo_root = _repository_root($request->{repository_root});
    my ($plan, $entry) = _current_entry($repo_root, $request->{ordinal});
    my $execution_revision = _require_clean_revision($repo_root);
    my $result = _run_profile_worker({
        operation => 'resume',
        repository_root => $repo_root,
        plan => $plan,
        entry => $entry,
        git_revision => $capture_revision,
        execution_revision => $execution_revision,
    });
    _require_unchanged_clean_revision($repo_root, $execution_revision);
    _validate_result($result, $plan, $entry, $capture_revision);
    confess "profile corpus-validation worker did not load an existing artifact\n"
        unless ($result->{artifact}{status} // '') eq 'loaded';
    _revalidate_in_parent(
        'corpus-validation resume', $repo_root, $plan, $entry,
        $capture_revision, $execution_revision, $result,
    );
    return _clone($result);
}

sub _revalidate_in_parent(
    $operation, $repo_root, $plan, $entry,
    $capture_revision, $execution_revision, $result,
) {
    my $loaded = $STORE->load({
        repository_root => $repo_root,
        ordinal => $entry->{ordinal},
    });
    _require_loaded_artifact_match($result->{artifact}, $loaded->{artifact});
    my $report = $loaded->{publication}{report};
    my $adapter = $entry->{adapter_class};
    my $validated = $adapter->validate_report({
        repository_root => $repo_root,
        report => $report,
    });
    confess "profile $operation parent adapter changed the admitted report\n"
        unless _canonical_json($validated) eq _canonical_json($report);
    my ($common, $provider, $applicability) = _admit_report(
        $report, $entry, $capture_revision,
    );
    _require_current_resume_identity($repo_root, $entry, $common)
        unless $operation eq 'capture';
    my $expected = _result(
        $plan, $entry, $report, $common, $provider, $applicability,
        $result->{artifact},
    );
    confess "profile $operation worker metadata changed after publication\n"
        unless _canonical_json($result) eq _canonical_json($expected);
    _require_unchanged_clean_revision($repo_root, $execution_revision);
    return 1;
}

sub _capture_in_child($raw) {
    my ($repo_root, $plan, $entry, $git_revision, $execution_revision) =
        @{$raw}{qw(
            repository_root plan entry git_revision execution_revision
        )};
    _require_unchanged_clean_revision($repo_root, $execution_revision);
    my $adapter = $entry->{adapter_class};
    my $method = $entry->{adapter_method};
    confess "profile capture adapter method is unavailable\n"
        unless defined($adapter) && !ref($adapter)
            && defined($method) && !ref($method)
            && $adapter->can($method);
    confess "profile capture adapter validator is unavailable\n"
        unless $adapter->can('validate_report');
    my $arguments = _clone($entry->{adapter_arguments});
    confess "profile capture plan injected repository_root\n"
        if exists $arguments->{repository_root};
    $arguments->{repository_root} = $repo_root;
    my $report = $adapter->$method($arguments);
    my $validated = $adapter->validate_report({
        repository_root => $repo_root,
        report => $report,
    });
    confess "profile capture adapter changed its produced report\n"
        unless _canonical_json($validated) eq _canonical_json($report);
    my ($common, $provider, $applicability) = _admit_report(
        $report, $entry, $git_revision,
    );
    _require_unchanged_clean_revision($repo_root, $execution_revision);
    my $artifact = $STORE->publish({
        repository_root => $repo_root,
        ordinal => $entry->{ordinal},
        report => $report,
    });
    _require_unchanged_clean_revision($repo_root, $execution_revision);
    return _result(
        $plan, $entry, $report, $common, $provider, $applicability,
        $artifact,
    );
}

sub _resume_in_child($raw) {
    my ($repo_root, $plan, $entry, $git_revision, $execution_revision) =
        @{$raw}{qw(
            repository_root plan entry git_revision execution_revision
        )};
    _require_unchanged_clean_revision($repo_root, $execution_revision);
    my $loaded = $STORE->load({
        repository_root => $repo_root,
        ordinal => $entry->{ordinal},
    });
    confess "profile resume store did not load an existing artifact\n"
        unless ($loaded->{artifact}{status} // '') eq 'loaded';
    my $report = $loaded->{publication}{report};
    my $adapter = $entry->{adapter_class};
    confess "profile resume adapter validator is unavailable\n"
        unless defined($adapter) && !ref($adapter)
            && $adapter->can('validate_report');
    my $validated = $adapter->validate_report({
        repository_root => $repo_root,
        report => $report,
    });
    confess "profile resume adapter changed the stored report\n"
        unless _canonical_json($validated) eq _canonical_json($report);
    my ($common, $provider, $applicability) = _admit_report(
        $report, $entry, $git_revision,
    );
    _require_current_resume_identity($repo_root, $entry, $common);
    _require_unchanged_clean_revision($repo_root, $execution_revision);
    return _result(
        $plan, $entry, $report, $common, $provider, $applicability,
        $loaded->{artifact},
    );
}

sub _admit_report($report, $entry, $git_revision) {
    confess "profile capture report must be one unblessed hash\n"
        unless ref($report) eq 'HASH' && !blessed($report);
    for my $key (qw(family level primary_axis backend_profile)) {
        my $expected = $entry->{report_coordinate_authority}{$key};
        if (defined $expected) {
            confess "profile capture report coordinate '$key' changed\n"
                unless defined($report->{$key}) && !ref($report->{$key})
                    && $report->{$key} eq $expected;
        }
        elsif (exists($report->{$key}) && defined($report->{$key})) {
            confess "profile capture report coordinate '$key' appeared\n";
        }
    }
    confess "profile capture report mode changed\n"
        unless ($report->{mode} // '') eq 'gate_measurement';
    confess "profile capture report identity is invalid\n"
        unless ($report->{report_identity} // '')
            =~ m{\A[A-Za-z0-9_.-]+/[0-9a-f]{64}\z};
    confess "profile capture validation record is invalid\n"
        unless ref($report->{validation_record}) eq 'HASH'
            && !blessed($report->{validation_record});
    confess "profile capture measurement records are invalid\n"
        unless ref($report->{measurement_records}) eq 'ARRAY'
            && @{$report->{measurement_records}}
                == $entry->{raw_measurement_records};
    confess "profile capture sample exclusions are invalid\n"
        unless ref($report->{sample_exclusions}) eq 'ARRAY'
            && !@{$report->{sample_exclusions}};
    confess "profile capture diagnostics are invalid\n"
        unless ref($report->{diagnostics}) eq 'ARRAY'
            && !@{$report->{diagnostics}};
    confess "profile capture report outcome did not accept\n"
        unless ($report->{outcome} // '') eq 'accepted';

    my @records = (
        $report->{validation_record}, @{$report->{measurement_records}},
    );
    confess "profile capture controller invocation count changed\n"
        unless @records == $entry->{controller_invocations}
            && $entry->{validation_records} == 1;
    for my $index (0 .. $#records) {
        my $expected_class = $index ? 'gate_measurement' : 'validation';
        confess "profile capture record order changed\n"
            unless ($records[$index]{run_class} // '') eq $expected_class
                && _json_integer_equals(
                    $records[$index]{run_ordinal}, $index,
                );
        confess "profile capture record $index did not accept\n"
            unless ($records[$index]{outcome} // '') eq 'accepted';
    }

    my $measurement = $report->{measurement_applicability};
    confess "profile capture measurement applicability is invalid\n"
        unless ref($measurement) eq 'HASH' && !blessed($measurement)
            && _json_boolean(
                $measurement->{applicable},
                'profile capture measurement applicable',
            )
            && !defined($measurement->{reason});
    my $controller = $report->{controller_applicability};
    if (defined $controller) {
        confess "profile capture controller applicability is invalid\n"
            unless ref($controller) eq 'HASH' && !blessed($controller)
                && _json_boolean(
                    $controller->{applicable},
                    'profile capture controller applicable',
                )
                && !defined($controller->{reason});
    }
    confess "profile capture required applicability changed\n"
        unless _json_boolean(
                $entry->{applicability_requirement}{required},
                'profile capture required applicability',
            )
            && defined($entry->{applicability_requirement}{predicate})
            && !ref($entry->{applicability_requirement}{predicate})
            && length($entry->{applicability_requirement}{predicate});

    my $cleanup = $report->{cleanup};
    confess "profile capture cleanup is invalid\n"
        unless ref($cleanup) eq 'HASH' && !blessed($cleanup)
            && _canonical_json([sort keys %$cleanup]) eq
                _canonical_json([sort qw(
                    ephemeral_removed records_total residue
                )])
            && _json_integer_equals(
                $cleanup->{records_total}, scalar @records,
            )
            && _json_boolean(
                $cleanup->{ephemeral_removed},
                'profile capture cleanup removed',
            )
            && ref($cleanup->{residue}) eq 'ARRAY'
            && !@{$cleanup->{residue}};

    my $common = _record_common_identity($records[0]);
    for my $record (@records) {
        confess "profile capture mixed host/tool/guard/common identities\n"
            unless _canonical_json(_record_common_identity($record))
                eq _canonical_json($common);
    }
    confess "profile capture Git revision changed\n"
        unless ($common->{git_revision} // '') eq $git_revision;
    confess "profile capture report is dirty\n"
        if _json_boolean(
            $common->{dirty_state}, 'profile capture dirty state',
        );
    confess "profile capture host/tool/guard identity is invalid\n"
        unless ref($common->{host_profile}) eq 'HASH'
            && ref($common->{tool_profile}) eq 'HASH'
            && ref($common->{resource_guard}) eq 'HASH'
            && _json_boolean(
                $common->{resource_guard}{active},
                'profile capture resource guard active',
            );

    my $provider = _provider_status($report, $entry, $common);
    my $applicability = {
        required => JSON::PP::true,
        predicate => $entry->{applicability_requirement}{predicate},
        controller_applicable => JSON::PP::true,
        measurement_applicable => JSON::PP::true,
        validation_records => 1,
        raw_measurement_records => scalar @{$report->{measurement_records}},
        sample_exclusions => 0,
        outcome => $report->{outcome},
    };
    _exact_keys(
        $applicability, \@APPLICABILITY_KEYS,
        'profile capture applicability status',
    );
    return (_clone($common), $provider, $applicability);
}

sub _provider_status($report, $entry, $common) {
    my $required = $entry->{provider_requirement};
    _exact_keys(
        $required, \@PROVIDER_KEYS,
        'profile capture provider requirement',
    );
    my $kind = $required->{kind} // '';
    if ($kind eq 'exact_tool_profile') {
        my $tool = $report->{tool_profile};
        confess "profile capture exact provider tool profile is absent\n"
            unless ref($tool) eq 'HASH' && !blessed($tool);
        confess "profile capture exact provider identity changed\n"
            unless _json_boolean(
                    $tool->{external_verification_tool},
                    'profile capture external provider flag',
                )
                && ($tool->{logical_name} // '') eq
                    ($required->{logical_name} // '')
                && ($tool->{provider_identity} // '') eq
                    ($required->{provider_identity} // '')
                && 'tool-profile/' . sha256_hex(_canonical_json($tool)) eq
                    ($required->{tool_profile_identity} // '')
                && _canonical_json($tool) eq
                    _canonical_json($common->{tool_profile});
    }
    elsif ($kind eq 'repository_materialization') {
        my $authority = $report->{profile_authority};
        my $verification = $report->{provider_verification};
        confess "profile capture repository provider became external\n"
            if _json_boolean(
                    $required->{external_verification_tool},
                    'profile capture repository provider requirement flag',
                )
                || _json_boolean(
                    $common->{tool_profile}{external_verification_tool},
                    'profile capture repository common tool external flag',
                );
        confess "profile capture repository provider authority changed\n"
            unless ref($authority) eq 'HASH'
                && ref($authority->{structural_authority}) eq 'HASH'
                && ($authority->{structural_authority}
                    {provider_materialization} // '') eq
                    ($required->{provider_identity} // '');
        confess "profile capture repository provider status changed\n"
            unless ref($verification) eq 'HASH'
                && _json_boolean(
                    $verification->{applicable},
                    'profile capture repository provider applicable',
                )
                && _json_boolean(
                    $verification->{included_in_emit},
                    'profile capture repository provider inclusion',
                )
                && _json_boolean(
                    $verification->{read_only},
                    'profile capture repository provider read-only',
                )
                && !_json_boolean(
                    $verification->{external_verification_tool},
                    'profile capture repository provider external flag',
                )
                && ($verification->{classification} // '') eq
                    'sealed_osvvm_2026_05_provider_materialization';
    }
    elsif ($kind eq 'not_applicable') {
        confess "profile capture inapplicable provider became external\n"
            if _json_boolean(
                    $required->{external_verification_tool},
                    'profile capture provider requirement external flag',
                )
                || defined($required->{logical_name})
                || defined($required->{provider_identity})
                || defined($required->{tool_profile_identity})
                || _json_boolean(
                    $common->{tool_profile}{external_verification_tool},
                    'profile capture common tool external flag',
                );
        if (exists $report->{provider_verification}) {
            my $verification = $report->{provider_verification};
            confess "profile capture inapplicable provider status changed\n"
                unless ref($verification) eq 'HASH'
                    && !_json_boolean(
                        $verification->{applicable},
                        'profile capture inapplicable provider applicable',
                    )
                    && !_json_boolean(
                        $verification->{included_in_emit},
                        'profile capture inapplicable provider inclusion',
                    )
                    && !_json_boolean(
                        $verification->{read_only},
                        'profile capture inapplicable provider read-only',
                    )
                    && !_json_boolean(
                        $verification->{external_verification_tool},
                        'profile capture inapplicable provider external flag',
                    )
                    && ($verification->{classification} // '') eq
                        'not_applicable';
        }
    }
    else {
        confess "profile capture provider kind is invalid\n";
    }
    return _clone($required);
}

sub _require_current_resume_identity($repo_root, $entry, $common) {
    my $current = $MEASUREMENT->current_environment_identity({
        repository_root => $repo_root,
    });
    confess "profile resume host identity is stale\n"
        unless _canonical_json($common->{host_profile}) eq
            _canonical_json($current->{host_profile});
    confess "profile resume guard identity is stale\n"
        unless _canonical_json($common->{resource_guard}) eq
            _canonical_json($current->{resource_guard});
    if (($entry->{provider_requirement}{kind} // '') ne
            'exact_tool_profile') {
        confess "profile resume tool identity is stale\n"
            unless _canonical_json($common->{tool_profile}) eq
                _canonical_json($current->{tool_profile});
    }
    return 1;
}

sub _record_common_identity($record) {
    confess "profile capture record must be one unblessed hash\n"
        unless ref($record) eq 'HASH' && !blessed($record);
    my $common = {
        git_revision => $record->{git_revision},
        dirty_state => _clone($record->{dirty_state}),
        host_profile => _clone($record->{host_profile}),
        tool_profile => _clone($record->{tool_profile}),
        resource_guard => _clone($record->{resource_guard}),
    };
    _exact_keys($common, \@COMMON_KEYS, 'profile capture common identity');
    return $common;
}

sub _result(
    $plan, $entry, $report, $common, $provider, $applicability, $artifact,
) {
    my $result = {
        schema => $SCHEMA,
        schema_version => 1,
        plan_identity => $plan->{plan_identity},
        policy_identity => $plan->{policy_identity},
        ordinal => $entry->{ordinal},
        selection_key => $entry->{selection_key},
        report_identity => $report->{report_identity},
        common_identity => _clone($common),
        provider_status => _clone($provider),
        applicability_status => _clone($applicability),
        artifact => _clone($artifact),
    };
    _validate_result(
        $result, $plan, $entry, $common->{git_revision},
    );
    return $result;
}

sub _validate_result($result, $plan, $entry, $git_revision) {
    _exact_keys($result, \@RESULT_KEYS, 'profile capture result');
    confess "profile capture result schema is invalid\n"
        unless ($result->{schema} // '') eq $SCHEMA
            && _json_integer_equals($result->{schema_version}, 1);
    confess "profile capture result plan identity changed\n"
        unless ($result->{plan_identity} // '') eq $plan->{plan_identity}
            && ($result->{policy_identity} // '') eq $plan->{policy_identity};
    confess "profile capture result dispatch changed\n"
        unless _json_integer_equals($result->{ordinal}, $entry->{ordinal})
            && ($result->{selection_key} // '') eq $entry->{selection_key};
    confess "profile capture result report identity is invalid\n"
        unless ($result->{report_identity} // '')
            =~ m{\A[A-Za-z0-9_.-]+/[0-9a-f]{64}\z};
    _exact_keys(
        $result->{common_identity}, \@COMMON_KEYS,
        'profile capture result common identity',
    );
    confess "profile capture result Git revision changed\n"
        unless ($result->{common_identity}{git_revision} // '') eq
            $git_revision
            && !_json_boolean(
                $result->{common_identity}{dirty_state},
                'profile capture result dirty state',
            );
    _exact_keys(
        $result->{provider_status}, \@PROVIDER_KEYS,
        'profile capture result provider status',
    );
    confess "profile capture result provider status changed\n"
        unless _canonical_json($result->{provider_status}) eq
            _canonical_json($entry->{provider_requirement});
    _exact_keys(
        $result->{applicability_status}, \@APPLICABILITY_KEYS,
        'profile capture result applicability status',
    );
    confess "profile capture result applicability changed\n"
        unless _json_boolean(
                $result->{applicability_status}{required},
                'profile capture result required applicability',
            )
            && _json_boolean(
                $result->{applicability_status}{controller_applicable},
                'profile capture result controller applicability',
            )
            && _json_boolean(
                $result->{applicability_status}{measurement_applicable},
                'profile capture result measurement applicability',
            )
            && _json_integer_equals(
                $result->{applicability_status}{validation_records}, 1,
            )
            && _json_integer_equals(
                $result->{applicability_status}{raw_measurement_records}, 3,
            )
            && _json_integer_equals(
                $result->{applicability_status}{sample_exclusions}, 0,
            )
            && ($result->{applicability_status}{predicate} // '') eq
                $entry->{applicability_requirement}{predicate}
            && ($result->{applicability_status}{outcome} // '') eq 'accepted';
    _validate_artifact($result->{artifact}, $entry);
    return 1;
}

sub _validate_artifact($artifact, $entry) {
    _exact_keys(
        $artifact, $STORE->artifact_keys,
        'profile capture artifact metadata',
    );
    confess "profile capture artifact status is invalid\n"
        unless ($artifact->{schema} // '') eq $ARTIFACT_SCHEMA
            && _json_integer_equals($artifact->{schema_version}, 1)
            && ($artifact->{status} // '')
                =~ /\A(?:loaded|published|recovered|unchanged)\z/;
    confess "profile capture artifact dispatch changed\n"
        unless _json_integer_equals($artifact->{ordinal}, $entry->{ordinal})
            && ($artifact->{selection_key} // '') eq $entry->{selection_key}
            && ($artifact->{artifact_relative_path} // '') eq
                $entry->{publication_relative_path};
    confess "profile capture artifact identity is invalid\n"
        unless ($artifact->{artifact_sha256} // '') =~ /\A[0-9a-f]{64}\z/
            && _json_positive_integer($artifact->{artifact_bytes})
            && $artifact->{artifact_bytes} <=
                $LIMITS->{maximum_publication_bytes}
            && _json_boolean(
                $artifact->{same_volume},
                'profile capture artifact same-volume status',
            )
            && _json_boolean(
                $artifact->{atomic},
                'profile capture artifact atomic status',
            );
}

sub _require_loaded_artifact_match($worker, $loaded) {
    for my $key (qw(
        ordinal selection_key artifact_relative_path artifact_sha256
        artifact_bytes same_volume atomic
    )) {
        confess "profile capture loaded artifact metadata changed\n"
            unless _canonical_json($worker->{$key}) eq
                _canonical_json($loaded->{$key});
    }
}

sub _run_profile_worker($raw) {
    confess "profile worker operation is invalid\n"
        unless ($raw->{operation} // '') =~ /\A(?:capture|resume)\z/;
    pipe(my $reader, my $writer)
        or confess "cannot create profile capture worker pipe\n";
    my $descriptor_ok = eval {
        _set_close_on_exec($reader, 'reader');
        _set_close_on_exec($writer, 'writer');
        my $flags = fcntl($reader, F_GETFL, 0);
        confess "cannot inspect profile capture worker reader flags\n"
            unless defined $flags;
        confess "cannot make profile capture worker reader nonblocking\n"
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
        confess "cannot fork profile capture worker\n";
    }
    if ($pid == 0) {
        close $reader;
        my ($payload, $worker_error);
        my $ok = eval {
            $payload = $raw->{operation} eq 'capture'
                ? _capture_in_child($raw)
                : _resume_in_child($raw);
            1;
        };
        $worker_error = $@ unless $ok;
        my $envelope = defined($worker_error)
            ? _failure_envelope($worker_error)
            : {
                schema => $WORKER_SCHEMA,
                schema_version => 1,
                ok => JSON::PP::true,
                payload => $payload,
                error => undef,
            };
        my $encoded = eval { _canonical_json($envelope) };
        my $exit_code = defined($worker_error) ? 70 : 0;
        if (!defined($encoded)
                || bytes::length($encoded) > $MAX_WORKER_BYTES) {
            $envelope = _failure_envelope(
                'profile capture worker result exceeded the bounded envelope',
            );
            $encoded = _canonical_json($envelope);
            $exit_code = 75;
        }
        my $written = _write_worker_result($writer, $encoded);
        close $writer;
        _exit($written ? $exit_code : 74);
    }

    close $writer;
    my ($buffer, $read_error, $wait_status, $done) = ('', undef, undef, 0);
    while (!$done) {
        $read_error //= _drain_worker_pipe($reader, \$buffer);
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
            $read_error = 'cannot wait for profile capture worker';
            $done = 1;
        }
        else {
            sleep(0.01);
        }
    }
    $read_error //= _drain_worker_pipe($reader, \$buffer);
    close $reader
        or $read_error //= 'cannot close profile capture worker reader';
    confess "$read_error\n" if defined $read_error;

    my $signal = defined($wait_status) && WIFSIGNALED($wait_status)
        ? WTERMSIG($wait_status) : 0;
    confess "profile capture worker terminated by signal $signal\n"
        if $signal;
    my ($envelope, $decode_error) = _decode_worker_envelope($buffer);
    my $exit_code = defined($wait_status) && WIFEXITED($wait_status)
        ? WEXITSTATUS($wait_status) : undef;
    if (defined $decode_error) {
        my $status = defined($exit_code)
            ? " with exit status $exit_code" : '';
        confess "profile capture worker $decode_error$status\n";
    }
    confess "profile capture worker failed: $envelope->{error}\n"
        unless $envelope->{ok};
    confess "profile capture worker exited with status $exit_code\n"
        unless defined($exit_code) && $exit_code == 0;
    return _clone($envelope->{payload});
}

sub _failure_envelope($error) {
    return {
        schema => $WORKER_SCHEMA,
        schema_version => 1,
        ok => JSON::PP::false,
        payload => undef,
        error => _bounded_error($error),
    };
}

sub _bounded_error($error) {
    $error = 'profile capture worker failed without an exception'
        unless defined($error) && !ref($error) && length($error);
    $error =~ s/[^\x20-\x7e]+/ /g;
    $error =~ s/\s+/ /g;
    $error =~ s/\A\s+|\s+\z//g;
    return substr($error, 0, $MAX_WORKER_ERROR_BYTES);
}

sub _decode_worker_envelope($buffer) {
    return (undef, 'returned no result') unless length($buffer // '');
    return (undef, 'result exceeded the bounded envelope')
        if bytes::length($buffer) > $MAX_WORKER_BYTES;
    my $decoded = eval { JSON::PP->new->utf8(1)->decode($buffer) };
    return (undef, 'result is not valid JSON') unless defined $decoded;
    return (undef, 'result is not canonical JSON')
        unless _canonical_json($decoded) eq $buffer;
    my $valid = eval {
        _exact_keys(
            $decoded, \@WORKER_ENVELOPE_KEYS,
            'profile capture worker envelope',
        );
        confess "profile capture worker envelope schema is invalid\n"
            unless ($decoded->{schema} // '') eq $WORKER_SCHEMA
                && _json_integer_equals($decoded->{schema_version}, 1);
        _json_boolean($decoded->{ok}, 'profile capture worker envelope ok');
        if ($decoded->{ok}) {
            confess "successful profile capture worker retained an error\n"
                if defined $decoded->{error};
            confess "successful profile capture worker payload is invalid\n"
                unless ref($decoded->{payload}) eq 'HASH'
                    && !blessed($decoded->{payload});
        }
        else {
            confess "failed profile capture worker retained a payload\n"
                if defined $decoded->{payload};
            confess "failed profile capture worker error is invalid\n"
                unless defined($decoded->{error})
                    && !ref($decoded->{error})
                    && length($decoded->{error})
                    && bytes::length($decoded->{error})
                        <= $MAX_WORKER_ERROR_BYTES;
        }
        1;
    };
    return (undef, _bounded_error($@)) unless $valid;
    return ($decoded, undef);
}

sub _write_worker_result($writer, $encoded) {
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

sub _drain_worker_pipe($reader, $buffer_ref) {
    while (1) {
        my $chunk = '';
        my $read = sysread($reader, $chunk, 16_384);
        if (!defined $read) {
            next if $! == EINTR;
            return undef if $! == EAGAIN || $! == EWOULDBLOCK;
            return 'cannot read profile capture worker result';
        }
        return undef if $read == 0;
        $$buffer_ref .= $chunk;
        return 'profile capture worker result exceeded the bounded envelope'
            if bytes::length($$buffer_ref) > $MAX_WORKER_BYTES;
    }
}

sub _set_close_on_exec($handle, $label) {
    my $flags = fcntl($handle, F_GETFD, 0);
    confess "cannot inspect profile capture worker $label descriptor\n"
        unless defined $flags;
    confess "cannot protect profile capture worker $label descriptor\n"
        unless fcntl($handle, F_SETFD, $flags | FD_CLOEXEC);
}

sub _current_entry($repo_root, $ordinal) {
    confess "profile capture ordinal is invalid\n"
        unless _json_positive_integer($ordinal);
    my $plan = $PLAN->derive({repository_root => $repo_root});
    my @matches = grep {
        _json_integer_equals($_->{ordinal}, $ordinal)
    } @{$plan->{entries}};
    confess "profile capture ordinal is unknown\n" unless @matches == 1;
    return ($plan, _clone($matches[0]));
}

sub _repository_root($value) {
    confess "profile capture repository root is invalid\n"
        unless defined($value) && !ref($value) && length($value);
    my $root = Cwd::realpath($value);
    confess "profile capture repository root is unavailable\n"
        unless defined($root) && -d $root && !-l $root;
    my $git = File::Spec->catfile($root, '.git');
    confess "profile capture repository Git identity is invalid\n"
        unless (-d $git || -f $git) && !-l $git;
    return $root;
}

sub _require_clean_revision($repo_root) {
    my ($revision_ok, $revision) = _capture_command(
        'git', '-C', $repo_root, 'rev-parse', 'HEAD',
    );
    confess "cannot derive profile capture Git revision\n"
        unless $revision_ok;
    $revision =~ s/\s+\z//;
    confess "profile capture Git revision is invalid\n"
        unless $revision =~ /\A[0-9a-f]{40}\z/;
    my ($status_ok, $status) = _capture_command(
        'git', '-C', $repo_root, 'status', '--porcelain=v1',
        '--untracked-files=normal',
    );
    confess "cannot derive profile capture Git state\n" unless $status_ok;
    confess "profile capture requires a clean Git revision\n"
        if length($status);
    return $revision;
}

sub _require_unchanged_clean_revision($repo_root, $expected) {
    my $actual = _require_clean_revision($repo_root);
    confess "profile capture Git revision changed during capture\n"
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
    confess "profile capture requires the active repository RAM guard\n"
        unless ($ENV{FSMGEN_RAM_GUARD_ACTIVE} // '') eq '1';
    my $host = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    my $rss = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    confess "profile capture guard thresholds are invalid\n"
        unless defined($host) && $host =~ /\A[0-9]+(?:[.][0-9]+)?\z/
            && $host > 0 && $host <= 88
            && defined($rss) && $rss =~ /\A[0-9]+(?:[.][0-9]+)?\z/
            && $rss > 0 && $rss <= 4096;
}

sub _request($method, $args, $keys) {
    confess __PACKAGE__ . "->$method expects one closed hash\n"
        unless @{$args} == 1 && ref($args->[0]) eq 'HASH'
            && !blessed($args->[0]);
    _exact_keys($args->[0], $keys, "$method invocation");
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

sub _json_boolean($value, $label) {
    my $encoded = eval { _canonical_json($value) };
    confess "$label is not a JSON boolean\n"
        unless defined($encoded)
            && ($encoded eq 'true' || $encoded eq 'false');
    return $encoded eq 'true' ? 1 : 0;
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
