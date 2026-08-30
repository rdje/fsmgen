package FSM::VIAL::ArchitectureScaleCalibrationClosure;

use v5.20;
use strict;
use warnings;
use bytes ();
use Carp qw(confess);
use Cwd ();
use Digest::SHA qw(sha256_hex);
use File::Spec;
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::VIAL::ArchitectureScaleBackendEmissionMeasurement;
use FSM::VIAL::ArchitectureScaleBackendEmissionMeasurementMatrix;
use FSM::VIAL::ArchitectureScaleBalancedPortableMeasurement;
use FSM::VIAL::ArchitectureScaleBalancedPortableMeasurementMatrix;
use FSM::VIAL::ArchitectureScaleExecutionCheckingMeasurement;
use FSM::VIAL::ArchitectureScaleExecutionCheckingMeasurementMatrix;
use FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement;
use FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurementMatrix;
use FSM::VIAL::ArchitectureScalePortableRuntimeMeasurement;
use FSM::VIAL::ArchitectureScalePortableRuntimeMeasurementMatrix;
use FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMeasurement;
use FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMeasurementMatrix;
use FSM::VIAL::ArchitectureScaleSemanticBridgeMeasurement;
use FSM::VIAL::ArchitectureScaleSemanticBridgeMeasurementMatrix;

my $SCHEMA = 'fsmgen.vial_architecture_scale_calibration_closure.v1';
my $PUBLICATION_BASE = '.artifacts/qualification/vial-scale/v1';
my $MAX_ARTIFACT_BYTES = 67_108_864;
my $MILLISECOND_NS = 1_000_000;
my $TWO_SECONDS_NS = 2_000_000_000;
my $MIB_16 = 16_777_216;
my $MIB_256 = 268_435_456;

my @STAGES = qw(
    construct parse_validate bridge bind_plan emit compile_analyze elaborate
    run trace_validate result_produce publish cleanup
);
my %STAGE_INDEX = map { $STAGES[$_] => $_ } 0 .. $#STAGES;
my @COST_CLASSES = qw(fsmgen external_tool artifact);
my @REPORT_KEYS = qw(
    schema schema_version closure_identity authorities profiles summary
    candidate_formula outcome diagnostics explicit_nonclaims
);
my @COMMON_KEYS = qw(
    git_revision dirty_state host_profile tool_profile resource_guard
);
my @NONCLAIMS = qw(
    promoted_performance_budget public_performance_budget cap_implementation
    performance_regression_enforcement architecture_capacity
    reached_resource_boundary backend_support family_support
    whole_product_big whole_product_really_big multi_unit multi_domain
    mixed_language native_uvm_runtime full_language synthesis
    general_cross_backend_parity cross_host_performance_comparison
    cross_tool_performance_comparison public_api_change
);
my @AUTHORITIES = (
    {
        authority => 'semantic_bridge',
        matrix_class =>
            'FSM::VIAL::ArchitectureScaleSemanticBridgeMeasurementMatrix',
        adapter_class =>
            'FSM::VIAL::ArchitectureScaleSemanticBridgeMeasurement',
        complete_relative_path => join('/', $PUBLICATION_BASE,
            'semantic-bridge-complete-matrix-v1', 'complete-matrix.json'),
    },
    {
        authority => 'execution_checking',
        matrix_class =>
            'FSM::VIAL::ArchitectureScaleExecutionCheckingMeasurementMatrix',
        adapter_class =>
            'FSM::VIAL::ArchitectureScaleExecutionCheckingMeasurement',
        complete_relative_path => join('/', $PUBLICATION_BASE,
            'execution-checking-complete-matrix-v1', 'complete-matrix.json'),
    },
    {
        authority => 'backend_emission',
        matrix_class =>
            'FSM::VIAL::ArchitectureScaleBackendEmissionMeasurementMatrix',
        adapter_class =>
            'FSM::VIAL::ArchitectureScaleBackendEmissionMeasurement',
        complete_relative_path => join('/', $PUBLICATION_BASE,
            'backend-emission-complete-matrix-v2', 'complete-matrix.json'),
    },
    {
        authority => 'portable_runtime',
        matrix_class =>
            'FSM::VIAL::ArchitectureScalePortableRuntimeMeasurementMatrix',
        adapter_class =>
            'FSM::VIAL::ArchitectureScalePortableRuntimeMeasurement',
        complete_relative_path => join('/', $PUBLICATION_BASE,
            'portable-runtime-complete-matrix-v1', 'complete-matrix.json'),
    },
    {
        authority => 'portable_vhdl_runtime',
        matrix_class =>
            'FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMeasurementMatrix',
        adapter_class =>
            'FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMeasurement',
        complete_relative_path => join('/', $PUBLICATION_BASE,
            'portable-vhdl-runtime-complete-matrix-v1',
            'complete-matrix.json'),
    },
    {
        authority => 'osvvm_runtime',
        matrix_class =>
            'FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurementMatrix',
        adapter_class =>
            'FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement',
        complete_relative_path => join('/', $PUBLICATION_BASE,
            'osvvm-runtime-complete-matrix-v1', 'complete-matrix.json'),
    },
    {
        authority => 'balanced_portable',
        matrix_class =>
            'FSM::VIAL::ArchitectureScaleBalancedPortableMeasurementMatrix',
        adapter_class =>
            'FSM::VIAL::ArchitectureScaleBalancedPortableMeasurement',
        complete_relative_path => join('/', $PUBLICATION_BASE,
            'balanced-portable-complete-matrix-v1', 'complete-matrix.json'),
    },
);
my $CANDIDATE_FORMULA = {
    authority => 'decision-0056',
    status => 'candidate_only',
    wall_time_ns => {
        floor => $TWO_SECONDS_NS,
        multiplier_numerator => 3,
        multiplier_denominator => 2,
        rounding_quantum => $MILLISECOND_NS,
    },
    cpu_time_ns => {
        floor => $TWO_SECONDS_NS,
        multiplier_numerator => 3,
        multiplier_denominator => 2,
        rounding_quantum => $MILLISECOND_NS,
    },
    peak_tree_rss_bytes => {
        floor => $MIB_256,
        multiplier_numerator => 5,
        multiplier_denominator => 4,
        rounding_quantum => $MIB_16,
    },
};

sub report_keys($class) {
    _exact_invocant($class, 'report_keys');
    return [@REPORT_KEYS];
}

sub explicit_nonclaims($class) {
    _exact_invocant($class, 'explicit_nonclaims');
    return [@NONCLAIMS];
}

sub derive($class, @args) {
    _exact_invocant($class, 'derive');
    my $raw = _request('derive', \@args, [qw(repository_root)]);
    _require_active_guard();
    my ($repo_root, $root_device) =
        _repository_root($raw->{repository_root});
    return _clone(_derive($repo_root, $root_device));
}

sub validate_report($class, @args) {
    _exact_invocant($class, 'validate_report');
    my $raw = _request(
        'validate_report', \@args, [qw(repository_root report)],
    );
    confess "calibration closure report must be one unblessed hash\n"
        unless ref($raw->{report}) eq 'HASH'
            && !blessed($raw->{report});
    _exact_keys($raw->{report}, \@REPORT_KEYS, 'calibration closure report');
    _require_active_guard();
    my ($repo_root, $root_device) =
        _repository_root($raw->{repository_root});
    my $expected = _derive($repo_root, $root_device);
    _require_unchanged_report($raw->{report}, $expected);
    return _clone($expected);
}

sub _derive($repo_root, $root_device) {
    my (@authorities, @profiles);
    my (%profile_ids, %measurement_ids);
    my ($raw_records, $excluded_records, $candidate_profiles) = (0, 0, 0);

    for my $authority (@AUTHORITIES) {
        my $matrix_class = $authority->{matrix_class};
        my $adapter_class = $authority->{adapter_class};
        my $validated = $matrix_class->validate_complete_publication({
            repository_root => $repo_root,
        });
        my $complete_artifact = _load_json_artifact({
            repository_root => $repo_root,
            root_device => $root_device,
            relative_path => $authority->{complete_relative_path},
        });
        confess "$authority->{authority} complete reload disagrees with its validator\n"
            unless _canonical_json($complete_artifact->{value})
                eq _canonical_json($validated);
        my $complete = $complete_artifact->{value};
        my @manifests = exists($complete->{family_manifests})
            ? @{$complete->{family_manifests}}
            : ($complete->{family_manifest});
        confess "$authority->{authority} has no family publication\n"
            unless @manifests && !grep { ref($_) ne 'HASH' } @manifests;

        my $inventory = $matrix_class->inventory;
        my $inventory_keys = $matrix_class->profile_keys;
        my @family_evidence;
        my $authority_profiles = 0;
        my $applicability_identity = 'calibration-applicability/'
            . sha256_hex(_canonical_json($complete->{common_identity}));
        _validate_common_identity(
            $complete->{common_identity}, "$authority->{authority} common identity",
        );

        for my $manifest (@manifests) {
            my $matrix_artifact = _load_json_artifact({
                repository_root => $repo_root,
                root_device => $root_device,
                relative_path => $manifest->{artifact_relative_path},
                expected_sha256 => $manifest->{artifact_sha256},
                expected_bytes => $manifest->{artifact_bytes},
            });
            my $matrix = $matrix_artifact->{value};
            confess "$authority->{authority} family matrix identity changed\n"
                unless ($matrix->{matrix_identity} // '')
                    eq ($manifest->{matrix_identity} // '');
            confess "$authority->{authority} family matrix name changed\n"
                unless ($matrix->{family} // '') eq ($manifest->{family} // '');
            confess "$authority->{authority} family matrix common identity changed\n"
                unless _canonical_json($matrix->{common_identity})
                    eq _canonical_json($complete->{common_identity});

            my @expected = grep {
                ($_->{family} // '') eq ($manifest->{family} // '')
            } @$inventory;
            confess "$authority->{authority} producer inventory count changed\n"
                unless @expected == @{$matrix->{profiles}}
                    && @expected == ($manifest->{profile_count} // -1);

            for my $index (0 .. $#expected) {
                my $entry = $matrix->{profiles}[$index];
                my %projection = map { $_ => $entry->{$_} } @$inventory_keys;
                confess "$authority->{authority} producer inventory order changed\n"
                    unless _canonical_json(\%projection)
                        eq _canonical_json($expected[$index]);
                my $qualified_id = join('/',
                    $authority->{authority}, $entry->{profile_id});
                confess "calibration closure contains duplicate profile '$qualified_id'\n"
                    if $profile_ids{$qualified_id}++;

                my $profile = _derive_profile({
                    repository_root => $repo_root,
                    root_device => $root_device,
                    authority => $authority,
                    inventory => $expected[$index],
                    matrix_entry => $entry,
                    common_identity => $complete->{common_identity},
                    applicability_identity => $applicability_identity,
                    adapter_class => $adapter_class,
                });
                for my $identity (@{$profile->{raw_measurement_identities}}) {
                    confess "calibration closure contains duplicate measurement '$identity'\n"
                        if $measurement_ids{$identity}++;
                }
                $raw_records += scalar(@{$profile->{raw_measurement_identities}});
                $excluded_records += scalar(@{$profile->{sample_exclusions}});
                $candidate_profiles++ if defined($profile->{candidate_budget});
                $profile->{ordinal} = scalar(@profiles) + 1;
                push @profiles, $profile;
                $authority_profiles++;
            }

            push @family_evidence, {
                family => $manifest->{family},
                matrix_identity => $manifest->{matrix_identity},
                profile_count => $manifest->{profile_count},
                artifact => $matrix_artifact->{evidence},
            };
        }

        confess "$authority->{authority} complete profile count changed\n"
            unless $authority_profiles == ($complete->{total_profile_count} // -1)
                && $authority_profiles == @$inventory;
        push @authorities, {
            authority => $authority->{authority},
            matrix_class => $matrix_class,
            adapter_class => $adapter_class,
            matrix_identity => $complete->{matrix_identity},
            profile_count => $authority_profiles,
            applicability_identity => $applicability_identity,
            common_identity => _clone($complete->{common_identity}),
            complete_artifact => $complete_artifact->{evidence},
            family_artifacts => \@family_evidence,
            dominance => _clone($complete->{dominance}),
            outcome => $complete->{outcome},
            diagnostics => _clone($complete->{diagnostics}),
            explicit_nonclaims => _clone($complete->{explicit_nonclaims}),
        };
    }

    my $summary = {
        authority_count => scalar(@authorities),
        family_count => _sum(map { scalar(@{$_->{family_artifacts}}) }
            @authorities),
        profile_count => scalar(@profiles),
        raw_measurement_records => $raw_records,
        excluded_measurement_records => $excluded_records,
        candidate_profiles => $candidate_profiles,
        noncandidate_profiles => scalar(@profiles) - $candidate_profiles,
    };
    my $report = {
        schema => $SCHEMA,
        schema_version => 1,
        closure_identity => undef,
        authorities => \@authorities,
        profiles => \@profiles,
        summary => $summary,
        candidate_formula => _clone($CANDIDATE_FORMULA),
        outcome => 'accepted',
        diagnostics => [],
        explicit_nonclaims => [@NONCLAIMS],
    };
    my %identity_input = %$report;
    delete $identity_input{closure_identity};
    $report->{closure_identity} = 'calibration-closure/'
        . sha256_hex(_canonical_json(\%identity_input));
    return $report;
}

sub _derive_profile($args) {
    my $entry = $args->{matrix_entry};
    my $artifact = _load_json_artifact({
        repository_root => $args->{repository_root},
        root_device => $args->{root_device},
        relative_path => $entry->{artifact_relative_path},
        expected_sha256 => $entry->{artifact_sha256},
        expected_bytes => $entry->{artifact_bytes},
    });
    my $document = $artifact->{value};
    my $report = exists($document->{report}) ? $document->{report} : $document;
    confess "$args->{authority}{authority} profile publication has no report\n"
        unless ref($report) eq 'HASH' && !blessed($report);
    # The exact matrix validator above has already validated this profile with
    # its exact adapter in an isolated process.  Reload the bytes independently
    # here, then enforce the cross-publication closure without repeating that
    # memory-bounded adapter work in the coordinator.
    confess "$args->{authority}{authority} profile report identity changed\n"
        unless ($report->{report_identity} // '')
            eq ($entry->{report_identity} // '');
    for my $key (qw(family level mode)) {
        confess "$args->{authority}{authority} profile $key changed\n"
            unless _canonical_json($report->{$key})
                eq _canonical_json($args->{inventory}{$key});
    }

    my $applicability = $report->{measurement_applicability};
    confess "$args->{authority}{authority} measurement applicability is not closed\n"
        unless ref($applicability) eq 'HASH'
            && !blessed($applicability)
            && exists($applicability->{applicable})
            && exists($applicability->{reason});
    my $applicable = $applicability->{applicable} ? 1 : 0;
    my $records = $report->{measurement_records};
    my $exclusions = $report->{sample_exclusions};
    confess "$args->{authority}{authority} profile record arrays changed\n"
        unless ref($records) eq 'ARRAY' && ref($exclusions) eq 'ARRAY';

    my $expected_records = $report->{mode} eq 'gate_measurement' ? 3
        : $report->{mode} eq 'qualification_measurement' ? 5 : 0;
    if ($applicable) {
        confess "$args->{authority}{authority} applicable profile has no validation\n"
            unless ref($report->{validation_record}) eq 'HASH';
        confess "$args->{authority}{authority} applicable profile repetition count changed\n"
            unless $expected_records && @$records == $expected_records;
    }
    else {
        confess "$args->{authority}{authority} inapplicable profile retained measurements\n"
            if @$records;
    }

    my @identity_records = grep { defined($_) }
        ($report->{validation_record}, @$records);
    for my $record (@identity_records) {
        _require_record_identity(
            $record, $args->{common_identity}, $args->{authority}{authority},
        );
    }

    my (@run_totals, @runs);
    for my $index (0 .. $#$records) {
        my $record = $records->[$index];
        confess "$args->{authority}{authority} measurement ordinal changed\n"
            unless ($record->{run_ordinal} // -1) == $index + 1;
        my $run = _derive_run($record);
        push @runs, $run;
        push @run_totals, {
            measurement_identity => $record->{measurement_identity},
            wall_time_ns => $run->{total}{wall_time_ns},
            cpu_time_ns => $run->{total}{cpu_time_ns},
            peak_tree_rss_bytes => $run->{total}{peak_tree_rss_bytes},
        };
    }

    my ($aggregate, $stages, $costs, $candidate);
    if ($applicable) {
        $aggregate = _aggregate_statistics(\@runs);
        $stages = _stage_statistics(\@runs);
        $costs = _cost_statistics(\@runs);
        $candidate = _candidate_budget($aggregate);
    }

    return {
        authority => $args->{authority}{authority},
        ordinal => undef,
        coordinates => _clone($args->{inventory}),
        matrix_profile => _clone($entry),
        raw_evidence => $artifact->{evidence},
        applicability_identity => $args->{applicability_identity},
        measurement_applicability => _clone($applicability),
        validation_identity => defined($report->{validation_record})
            ? $report->{validation_record}{measurement_identity} : undef,
        raw_measurement_identities => [map {
            $_->{measurement_identity}
        } @$records],
        sample_exclusions => _clone($exclusions),
        accepted_run_totals => \@run_totals,
        aggregate_statistics => $aggregate,
        stage_statistics => $stages,
        cost_statistics => $costs,
        candidate_budget => $candidate,
        dominance => {
            outcome => $report->{outcome},
            diagnostics => _clone($report->{diagnostics}),
            requested_counts => _clone($report->{requested_counts}),
            canonical_evaluation => _clone($report->{canonical_evaluation}),
            controller_applicability =>
                _clone($report->{controller_applicability}),
            profile_authority => _clone($report->{profile_authority}),
            provider_verification => _clone($report->{provider_verification}),
        },
        cleanup => _clone($report->{cleanup}),
        explicit_nonclaims => _clone($report->{explicit_nonclaims}),
    };
}

sub _derive_run($record) {
    my %cost = map { $_ => {
        wall_time_ns => 0,
        cpu_time_ns => 0,
        peak_tree_rss_bytes => undef,
        measured_stages => 0,
    } } @COST_CLASSES;
    my (%stages, $wall, $cpu, $rss) = ();
    $wall = 0;
    $cpu = 0;
    $rss = undef;

    for my $stage (@{$record->{stage_measurements}}) {
        next unless ($stage->{status} // '') =~ /\Ameasured/;
        my $name = $stage->{stage};
        confess "measurement contains an unknown stage '$name'\n"
            unless exists $STAGE_INDEX{$name};
        my $cost_class = $name =~ /\A(?:publish|cleanup)\z/
            ? 'artifact'
            : $stage->{classification} eq 'external_tool'
                ? 'external_tool' : 'fsmgen';
        my $stage_cpu = _stage_cpu($stage);
        my $stage_rss = $stage->{rss}{peak_process_tree_bytes};
        confess "measured stage '$name' has no process-tree RSS\n"
            if !defined($stage_rss)
                && !(($stage->{rss}{unsupported_reason} // '')
                    eq 'cleanup_is_controller_local');
        my $stage_wall = $stage->{wall_time_ns};
        $wall += $stage_wall;
        $cpu += $stage_cpu;
        $rss = $stage_rss
            if defined($stage_rss) && (!defined($rss) || $stage_rss > $rss);
        $cost{$cost_class}{wall_time_ns} += $stage_wall;
        $cost{$cost_class}{cpu_time_ns} += $stage_cpu;
        $cost{$cost_class}{peak_tree_rss_bytes} = $stage_rss
            if defined($stage_rss)
                && (!defined($cost{$cost_class}{peak_tree_rss_bytes})
                    || $stage_rss > $cost{$cost_class}{peak_tree_rss_bytes});
        $cost{$cost_class}{measured_stages}++;
        $stages{$name} = {
            classification => $stage->{classification},
            cost_class => $cost_class,
            wall_time_ns => $stage_wall,
            cpu_time_ns => $stage_cpu,
            peak_tree_rss_bytes => $stage_rss,
        };
    }
    confess "measurement record has no measured process-tree RSS\n"
        unless defined $rss;
    return {
        total => {
            wall_time_ns => $wall,
            cpu_time_ns => $cpu,
            peak_tree_rss_bytes => $rss,
        },
        stages => \%stages,
        costs => \%cost,
    };
}

sub _stage_cpu($stage) {
    my $total = 0;
    for my $kind (qw(controller_cpu descendant_cpu)) {
        my $counter = $stage->{$kind};
        for my $field (qw(user_ns system_ns)) {
            if (defined($counter->{$field})) {
                $total += $counter->{$field};
                next;
            }
            confess "measured stage '$stage->{stage}' has unsupported $kind $field\n"
                unless $kind eq 'descendant_cpu'
                    && $stage->{stage} eq 'cleanup'
                    && ($counter->{unsupported_reason} // '')
                        eq 'no_descendant_cleanup_process';
        }
    }
    return $total;
}

sub _aggregate_statistics($runs) {
    return {
        wall_time_ns => _statistics([map {
            $_->{total}{wall_time_ns}
        } @$runs]),
        cpu_time_ns => _statistics([map {
            $_->{total}{cpu_time_ns}
        } @$runs]),
        peak_tree_rss_bytes => _statistics([map {
            $_->{total}{peak_tree_rss_bytes}
        } @$runs]),
    };
}

sub _stage_statistics($runs) {
    my @result;
    for my $stage_name (@STAGES) {
        my @values = grep { exists($_->{stages}{$stage_name}) } @$runs;
        next unless @values;
        confess "measured stage '$stage_name' is missing from one repetition\n"
            unless @values == @$runs;
        my %classifications = map {
            $_->{stages}{$stage_name}{classification} => 1
        } @values;
        my %cost_classes = map {
            $_->{stages}{$stage_name}{cost_class} => 1
        } @values;
        confess "measured stage '$stage_name' classification changed\n"
            unless keys(%classifications) == 1 && keys(%cost_classes) == 1;
        push @result, {
            stage => $stage_name,
            classification => (keys %classifications)[0],
            cost_class => (keys %cost_classes)[0],
            wall_time_ns => _statistics([map {
                $_->{stages}{$stage_name}{wall_time_ns}
            } @values]),
            cpu_time_ns => _statistics([map {
                $_->{stages}{$stage_name}{cpu_time_ns}
            } @values]),
            peak_tree_rss_bytes => _nullable_statistics([map {
                $_->{stages}{$stage_name}{peak_tree_rss_bytes}
            } @values]),
        };
    }
    return \@result;
}

sub _cost_statistics($runs) {
    my %result;
    for my $class (@COST_CLASSES) {
        my @applicable = grep {
            $_->{costs}{$class}{measured_stages} > 0
        } @$runs;
        confess "$class cost applicability changed between repetitions\n"
            unless !@applicable || @applicable == @$runs;
        $result{$class} = !@applicable ? {
            applicable => JSON::PP::false,
            wall_time_ns => undef,
            cpu_time_ns => undef,
            peak_tree_rss_bytes => undef,
        } : {
            applicable => JSON::PP::true,
            wall_time_ns => _statistics([map {
                $_->{costs}{$class}{wall_time_ns}
            } @applicable]),
            cpu_time_ns => _statistics([map {
                $_->{costs}{$class}{cpu_time_ns}
            } @applicable]),
            peak_tree_rss_bytes => _nullable_statistics([map {
                $_->{costs}{$class}{peak_tree_rss_bytes}
            } @applicable]),
        };
    }
    return \%result;
}

sub _statistics($values) {
    confess "statistics require a nonempty integer vector\n"
        unless ref($values) eq 'ARRAY' && @$values
            && !grep { !defined($_) || ref($_) || $_ !~ /\A[0-9]+\z/ } @$values;
    my @sorted = sort { $a <=> $b } @$values;
    my $median = _median(\@sorted);
    my @deviations = sort { $a <=> $b } map {
        abs($_ - $median)
    } @sorted;
    return {
        sample_count => scalar(@sorted),
        minimum => $sorted[0],
        median => $median,
        maximum => $sorted[-1],
        median_absolute_deviation => _median(\@deviations),
    };
}

sub _nullable_statistics($values) {
    return undef if !grep { defined($_) } @$values;
    confess "nullable statistic is supported for only a complete vector\n"
        if grep { !defined($_) } @$values;
    return _statistics($values);
}

sub _median($sorted) {
    my $count = @$sorted;
    return $sorted->[int($count / 2)] if $count % 2;
    my $sum = $sorted->[$count / 2 - 1] + $sorted->[$count / 2];
    confess "statistics median is not an exact integer\n" if $sum % 2;
    return $sum / 2;
}

sub _candidate_budget($aggregate) {
    my $wall_max = $aggregate->{wall_time_ns}{maximum};
    my $cpu_max = $aggregate->{cpu_time_ns}{maximum};
    my $rss_max = $aggregate->{peak_tree_rss_bytes}{maximum};
    return {
        status => 'candidate_only',
        formula_authority => 'decision-0056',
        wall_time_ns => _rounded_candidate(
            $wall_max, 3, 2, $TWO_SECONDS_NS, $MILLISECOND_NS,
        ),
        cpu_time_ns => _rounded_candidate(
            $cpu_max, 3, 2, $TWO_SECONDS_NS, $MILLISECOND_NS,
        ),
        peak_tree_rss_bytes => _rounded_candidate(
            $rss_max, 5, 4, $MIB_256, $MIB_16,
        ),
    };
}

sub _rounded_candidate($maximum, $numerator, $denominator, $floor, $quantum) {
    my $scaled = int(
        ($maximum * $numerator + $denominator - 1) / $denominator,
    );
    $scaled = $floor if $scaled < $floor;
    return int(($scaled + $quantum - 1) / $quantum) * $quantum;
}

sub _require_record_identity($record, $common, $authority) {
    confess "$authority evidence record is not one hash\n"
        unless ref($record) eq 'HASH' && !blessed($record);
    my %actual = map { $_ => $record->{$_} } @COMMON_KEYS;
    confess "$authority evidence record has mixed revision/host/tool/guard identity\n"
        unless _canonical_json(\%actual) eq _canonical_json($common);
    confess "$authority evidence record is not accepted\n"
        unless ($record->{outcome} // '') eq 'accepted';
}

sub _validate_common_identity($identity, $label) {
    confess "$label must be one closed hash\n"
        unless ref($identity) eq 'HASH' && !blessed($identity);
    _exact_keys($identity, \@COMMON_KEYS, $label);
    confess "$label Git revision is invalid\n"
        unless ($identity->{git_revision} // '') =~ /\A[0-9a-f]{40}\z/;
    confess "$label is dirty\n" if $identity->{dirty_state};
}

sub _load_json_artifact($args) {
    my $relative = $args->{relative_path};
    _safe_relative_path($relative);
    my @components = split m{/}, $relative;
    my $path = File::Spec->catfile($args->{repository_root}, @components);
    my $cursor = $args->{repository_root};
    for my $index (0 .. $#components) {
        $cursor = File::Spec->catfile($cursor, $components[$index]);
        confess "calibration artifact path contains a symlink: $relative\n"
            if -l $cursor;
        confess "calibration artifact path is missing: $relative\n"
            unless $index == $#components ? -f $cursor : -d $cursor;
        my @stat = stat($cursor);
        confess "calibration artifact filesystem identity changed: $relative\n"
            unless @stat && $stat[0] == $args->{root_device};
    }
    my @stat = stat($path);
    confess "calibration artifact exceeds the read-only closure envelope: $relative\n"
        if $stat[7] > $MAX_ARTIFACT_BYTES;
    open my $fh, '<:raw', $path
        or confess "cannot open calibration artifact $relative: $!\n";
    local $/;
    my $bytes = <$fh>;
    close $fh or confess "cannot close calibration artifact $relative: $!\n";
    confess "calibration artifact changed while reading: $relative\n"
        unless defined($bytes) && bytes::length($bytes) == $stat[7];
    my $sha256 = sha256_hex($bytes);
    confess "calibration artifact byte count changed: $relative\n"
        if defined($args->{expected_bytes})
            && $stat[7] != $args->{expected_bytes};
    confess "calibration artifact digest changed: $relative\n"
        if defined($args->{expected_sha256})
            && $sha256 ne $args->{expected_sha256};
    my $value = eval { JSON::PP->new->utf8(1)->decode($bytes) };
    confess "calibration artifact is not valid JSON: $relative\n" if $@;
    confess "calibration artifact is not canonical JSON: $relative\n"
        unless $bytes eq _canonical_json($value) . "\n";
    return {
        value => $value,
        evidence => {
            relative_path => $relative,
            sha256 => $sha256,
            bytes => $stat[7],
        },
    };
}

sub _safe_relative_path($path) {
    confess "calibration artifact path must be repository-relative\n"
        unless defined($path) && !ref($path) && length($path)
            && !File::Spec->file_name_is_absolute($path)
            && $path !~ m{(?:\A|/)\.\.(?:/|\z)}
            && $path !~ m{(?:\A|/)\.(?:/|\z)}
            && $path !~ m{//}
            && $path !~ /\0/;
}

sub _repository_root($raw) {
    confess "repository_root must name one scalar directory path\n"
        unless defined($raw) && !ref($raw);
    my $repo_root = Cwd::abs_path($raw);
    confess "repository root is not a readable directory\n"
        unless defined($repo_root) && -d $repo_root;
    my $git = File::Spec->catfile($repo_root, '.git');
    confess "repository root has no regular Git identity\n"
        unless (-d $git || -f $git) && !-l $git;
    my @stat = stat($repo_root);
    confess "repository filesystem identity is unavailable\n" unless @stat;
    return ($repo_root, $stat[0]);
}

sub _require_active_guard() {
    confess "calibration closure requires the active repository RAM guard\n"
        unless ($ENV{FSMGEN_RAM_GUARD_ACTIVE} // '') eq '1';
    my $host = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    my $rss = $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    confess "calibration closure guard thresholds are invalid\n"
        unless defined($host) && $host =~ /\A[0-9]+(?:[.][0-9]+)?\z/
            && $host <= 88
            && defined($rss) && $rss =~ /\A[0-9]+(?:[.][0-9]+)?\z/
            && $rss <= 4096;
}

sub _request($operation, $args, $required) {
    confess "$operation expects exactly one hash reference\n"
        unless @$args == 1 && ref($args->[0]) eq 'HASH'
            && !blessed($args->[0]);
    my $raw = $args->[0];
    my %allowed = map { $_ => 1 } @$required;
    for my $key (keys %$raw) {
        confess "$operation received unknown key '$key'\n"
            unless $allowed{$key};
    }
    for my $key (@$required) {
        confess "$operation is missing '$key'\n" unless exists $raw->{$key};
    }
    return $raw;
}

sub _exact_invocant($class, $method) {
    confess "$method requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
}

sub _exact_keys($value, $keys, $label) {
    my @actual = sort keys %$value;
    my @expected = sort @$keys;
    confess "$label keys changed\n"
        unless _canonical_json(\@actual) eq _canonical_json(\@expected);
}

sub _require_unchanged_report($actual, $expected) {
    confess "calibration closure report must be one unblessed hash\n"
        unless ref($actual) eq 'HASH' && !blessed($actual);
    _exact_keys($actual, \@REPORT_KEYS, 'calibration closure report');
    confess "calibration closure changed from immutable derivation\n"
        unless _canonical_json($actual) eq _canonical_json($expected);
}

sub _sum(@values) {
    my $total = 0;
    $total += $_ for @values;
    return $total;
}

sub _canonical_json($value) {
    return JSON::PP->new->canonical(1)->utf8(1)->encode($value);
}

sub _clone($value) {
    return JSON::PP->new->utf8(1)->decode(_canonical_json($value));
}

1;
