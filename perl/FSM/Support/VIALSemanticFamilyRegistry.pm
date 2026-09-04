package FSM::Support::VIALSemanticFamilyRegistry;

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use Exporter 'import';
use JSON::PP ();
use Scalar::Util qw(blessed reftype);

use FSM::Support::VIALSemanticFamilyContract qw(
    build_vial_semantic_family_contract
);

our @EXPORT_OK = qw(
    build_vial_semantic_family_registry
    negotiate_vial_semantic_family_requirements
    vial_family_requirements_from_execution_ir
    vial_family_requirements_from_semantic_ir
    vial_profile_supported_capabilities
    vial_public_tool_capabilities
    vial_semantic_family_negotiation_message
    vial_semantic_family_registry_keys
);

my @REGISTRY_KEYS = qw(
    schema schema_version registry_id status contract_source family_keys
    profile_keys maturity_keys backend_mapping_keys bound_profile_keys
    requirement_keys negotiation_keys issue_keys maturity_levels limits
    bound_profiles families profiles public_tool_capabilities explicit_nonclaims
);
my @FAMILY_KEYS = qw(
    family_id revision capability_id dependencies effect_kinds bound_profile_id
    maturity backend_profiles task_owner
);
my @PROFILE_KEYS = qw(
    profile_id profile_kind stages accepted_language_versions
    accepted_execution_schemas accepted_execution_profiles
    supported_family_revisions supported_capabilities supported_effect_kinds
);
my @MATURITY_KEYS = qw(
    selection source semantic binding execution plan emission compile runtime
    result parity public
);
my @BACKEND_MATURITY_KEYS = qw(emission compile runtime result parity);
my @BACKEND_MAPPING_KEYS = qw(profile_id maturity);
my @BOUND_PROFILE_KEYS = qw(bound_profile_id limits);
my @REQUIREMENT_KEYS = qw(
    family_id revision required_capabilities effect_kinds
);
my @NEGOTIATION_KEYS = qw(
    schema schema_version registry_id stage profile_id accepted required
    satisfied unsupported issues
);
my @ISSUE_KEYS = qw(kind requirement message);
my %LIMIT = (
    families_per_registry => 256,
    families_per_negotiation => 256,
    dependencies_per_family => 256,
    effects_per_family => 256,
    capabilities_per_family => 256,
    profiles_per_registry => 64,
);
my @MATURITY_LEVELS = qw(unavailable selected implemented qualified);
my @PUBLIC_TOOL_CAPABILITIES = qw(
    vial.tooling.cli.v1
    vial.tooling.api.v1
    vial.source_projection.normal_v1
    vial.source_projection.terse_v1
    vial.semantic_projection.v1
    vial.artifact_layout.v1
    vial.tool_manifest.v1
    vial.verification_output_manifest.v2
    vial.backend.sv_portable_verilator.v1
    vial.backend.sv_portable_verilator.known_value_runtime_v1
    vial.backend.sv_portable_verilator.inactive_edge_scheduler_v1
    vial.backend.sv_portable_verilator.declared_probe_adapter_v1
    vial.backend.sv_portable_verilator.runtime_trace_v1
    vial.parity.ahb_base_output_arbitration.v1
    vial.parity_report.v1
    vial.result_manifest.v1
    vial.architecture_scale.regression_gate.v1
);
my @SV_PORTABLE_CAPABILITIES = qw(
    hial_vial.bridge_manifest.v1
    hial_vial.bridge_probe.equivalent_adapter_required
    hial_vial.bridge_profile.core_single_unit_v1
    hial_vial.bridge_protocol.ahb_subordinate_v1
    hial_vial.bridge_source.ial0_direct
    hial_vial.bridge_source.ial1_via_generated_ial0
    hial_vial.bridge_source.ial2_via_generated_ial1
    vial.binding.directional_representation.v1
    vial.execution_ir.v1
    vial.execution_profile.core_directed_single_clock_execution_v1
    vial.logical_time.drive_sample_react_check_v1
    vial.plan.v1
    vial.profile.core_directed_single_clock_v1
    vial.random.sha256_counter_rejection_v1
    vial.replay.v1
    vial.semantic_ir.v1
    vial.source.v1
);
my @BACKEND_PROFILE_IDS = qw(
    sv_portable_verilator
    sv_uvm_emit.accellera_2020_3_1
    vhdl_osvvm_qualified
    vhdl_portable_ghdl
);

my @FAMILY_SPEC = (
    [lifecycle_control => 2 => [qw(
        complete deadline drain failure finalize ready service_start service_stop
        shutdown stimulus_start
    )]],
    [notification_interception => 3 => [qw(
        cancel filter notify observe transform
    )]],
    [timed_interface => 4 => [qw(drive reset sample synchronize)]],
    [stimulus_orchestration => 5 => [qw(
        scenario_complete scenario_start transaction_accept transaction_complete
        transaction_start
    )]],
    [producer_observer => 6 => [qw(
        model_update observe publish scoreboard_compare
    )]],
    [implementation_selection => 7 => [qw(restore select substitute)]],
    [scoped_configuration => 8 => [qw(configure resolve)]],
    [register_intent => 9 => [qw(
        mirror predict register_read register_write
    )]],
    [constrained_decision => 10 => [qw(choose constrain replay solve)]],
    [coverage_property => 11 => [qw(assert assume cover sample)]],
    [bounded_fault => 12 => [qw(activate deactivate inject restore)]],
    [result_introspection => 13 => [qw(diagnose inspect report trace)]],
);

sub vial_semantic_family_registry_keys {
    return [@REGISTRY_KEYS];
}

sub build_vial_semantic_family_registry {
    my $common = build_vial_semantic_family_contract();
    my $unavailable = _unavailable_maturity();
    my @families = map {
        my ($family_id, $activity, $effects) = @{$_};
        {
            family_id => $family_id,
            revision => 1,
            capability_id => "vial.family.$family_id.v1",
            dependencies => [],
            effect_kinds => [sort @{$effects}],
            bound_profile_id => 'vial_common_envelope_v2',
            maturity => {
                %{$unavailable},
                selection => 'selected',
            },
            backend_profiles => [map { +{
                profile_id => $_,
                maturity => {
                    map { $_ => 'unavailable' } @BACKEND_MATURITY_KEYS
                },
            } } @BACKEND_PROFILE_IDS],
            task_owner =>
                "HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.$activity",
        }
    } @FAMILY_SPEC;
    my @profiles = (
        {
            profile_id => 'core_directed_single_clock_execution_v2',
            profile_kind => 'execution',
            stages => ['planner'],
            accepted_language_versions => [2],
            accepted_execution_schemas => [],
            accepted_execution_profiles => [
                'core_directed_single_clock_execution_v2',
            ],
            supported_family_revisions => [],
            supported_capabilities => [qw(
                vial.execution_ir.v2
                vial.execution_profile.core_directed_single_clock_execution_v2
                vial.plan.v2
                vial.profile.core_directed_single_clock_v2
                vial.semantic_family_envelope.v2
                vial.semantic_ir.v2
                vial.source.v2
            )],
            supported_effect_kinds => [],
        },
        {
            profile_id => 'sv_portable_verilator',
            profile_kind => 'backend',
            stages => [qw(emitter runner)],
            accepted_language_versions => [],
            accepted_execution_schemas => ['fsmgen.vial_execution_ir.v1'],
            accepted_execution_profiles => [
                'core_directed_single_clock_execution_v1',
            ],
            supported_family_revisions => [],
            supported_capabilities => [sort @SV_PORTABLE_CAPABILITIES],
            supported_effect_kinds => [],
        },
        {
            profile_id => 'sv_uvm_emit.accellera_2020_3_1',
            profile_kind => 'backend',
            stages => ['emitter'],
            accepted_language_versions => [],
            accepted_execution_schemas => ['fsmgen.vial_execution_ir.v1'],
            accepted_execution_profiles => [
                'core_directed_single_clock_execution_v1',
            ],
            supported_family_revisions => [],
            supported_capabilities => [sort @SV_PORTABLE_CAPABILITIES],
            supported_effect_kinds => [],
        },
        {
            profile_id => 'vhdl_osvvm_qualified',
            profile_kind => 'backend',
            stages => ['emitter'],
            accepted_language_versions => [],
            accepted_execution_schemas => ['fsmgen.vial_execution_ir.v1'],
            accepted_execution_profiles => [
                'core_directed_single_clock_execution_v1',
            ],
            supported_family_revisions => [],
            supported_capabilities => [sort @SV_PORTABLE_CAPABILITIES],
            supported_effect_kinds => [],
        },
        {
            profile_id => 'vhdl_portable_ghdl',
            profile_kind => 'backend',
            stages => ['emitter'],
            accepted_language_versions => [],
            accepted_execution_schemas => ['fsmgen.vial_execution_ir.v1'],
            accepted_execution_profiles => [
                'core_directed_single_clock_execution_v1',
            ],
            supported_family_revisions => [],
            supported_capabilities => [sort @SV_PORTABLE_CAPABILITIES],
            supported_effect_kinds => [],
        },
        {
            profile_id => 'vial_parser_v2',
            profile_kind => 'parser',
            stages => ['parser'],
            accepted_language_versions => [2],
            accepted_execution_schemas => [],
            accepted_execution_profiles => [],
            supported_family_revisions => [],
            supported_capabilities => [qw(
                vial.profile.core_directed_single_clock_v2
                vial.semantic_ir.v2
                vial.source.v2
            )],
            supported_effect_kinds => [],
        },
    );
    my $registry = {
        schema => 'fsmgen.vial_semantic_family_registry.v1',
        schema_version => 1,
        registry_id => undef,
        status => 'selected_taxonomy_no_implemented_family',
        contract_source => __PACKAGE__,
        family_keys => [@FAMILY_KEYS],
        profile_keys => [@PROFILE_KEYS],
        maturity_keys => [@MATURITY_KEYS],
        backend_mapping_keys => [@BACKEND_MAPPING_KEYS],
        bound_profile_keys => [@BOUND_PROFILE_KEYS],
        requirement_keys => [@REQUIREMENT_KEYS],
        negotiation_keys => [@NEGOTIATION_KEYS],
        issue_keys => [@ISSUE_KEYS],
        maturity_levels => [@MATURITY_LEVELS],
        limits => {%LIMIT},
        bound_profiles => [{
            bound_profile_id => 'vial_common_envelope_v2',
            limits => _clone($common->{limits}),
        }],
        families => \@families,
        profiles => \@profiles,
        public_tool_capabilities => [@PUBLIC_TOOL_CAPABILITIES],
        explicit_nonclaims => [qw(
            compatibility_adapter complete_result_manifest family_grammar
            family_implementation family_runtime mixed_language
            qualified_v2_backend reverse_migration support_promotion
        )],
    };
    my $identity = _clone($registry);
    $identity->{registry_id} = undef;
    $registry->{registry_id} = 'vial-family-registry/'
        . sha256_hex(_canonical_json($identity));
    return _validate_registry($registry);
}

sub vial_public_tool_capabilities {
    return _clone(build_vial_semantic_family_registry()
        ->{public_tool_capabilities});
}

sub vial_profile_supported_capabilities {
    my ($profile_id) = @_;
    _identifier($profile_id, 'profile_id');
    my $registry = build_vial_semantic_family_registry();
    my ($profile) = grep { $_->{profile_id} eq $profile_id }
        @{$registry->{profiles}};
    die "VIAL semantic-family profile '$profile_id' is not registered\n"
        unless $profile;
    return _clone($profile->{supported_capabilities});
}

sub vial_family_requirements_from_semantic_ir {
    my ($semantic) = @_;
    _plain_hash($semantic, 'SemanticIR projection');
    return [] if ($semantic->{schema_version} // 0) == 1;
    die "SemanticIR projection must have schema_version 1 or 2\n"
        unless ($semantic->{schema_version} // 0) == 2;
    my @families;
    for my $package (@{$semantic->{packages} || []}) {
        push @families, @{$package->{intent_families} || []};
    }
    return _requirements_from_family_records(\@families, 'semantic');
}

sub vial_family_requirements_from_execution_ir {
    my ($execution) = @_;
    _plain_hash($execution, 'ExecutionIR projection');
    return [] if ($execution->{schema_version} // 0) == 1;
    die "ExecutionIR projection must have schema_version 1 or 2\n"
        unless ($execution->{schema_version} // 0) == 2;
    return _requirements_from_family_records(
        $execution->{semantic_families} || [], 'execution',
    );
}

sub negotiate_vial_semantic_family_requirements {
    my ($args) = @_;
    _plain_hash($args, 'semantic-family negotiation');
    _exact_hash($args, [qw(
        stage profile_id source_language_version execution_schema
        execution_profile requirements
    )], 'semantic-family negotiation');
    my %known_stage = map { $_ => 1 } qw(parser planner emitter runner);
    die "semantic-family negotiation stage is invalid\n"
        unless defined($args->{stage}) && !ref($args->{stage})
            && $known_stage{$args->{stage}};
    _identifier($args->{profile_id}, 'profile_id');
    _optional_scalar($args->{source_language_version}, 'source_language_version');
    _optional_scalar($args->{execution_schema}, 'execution_schema');
    _optional_scalar($args->{execution_profile}, 'execution_profile');
    my $requirements = _validate_requirements($args->{requirements});

    my $registry = build_vial_semantic_family_registry();
    my ($profile) = grep { $_->{profile_id} eq $args->{profile_id} }
        @{$registry->{profiles}};
    my (@required, @satisfied, @issues);
    my $add_required = sub {
        my ($requirement) = @_;
        push @required, $requirement
            unless grep { $_ eq $requirement } @required;
    };
    my $add_satisfied = sub {
        my ($requirement) = @_;
        push @satisfied, $requirement
            unless grep { $_ eq $requirement } @satisfied;
    };
    my $add_issue = sub {
        my ($kind, $requirement, $message) = @_;
        push @issues, {
            kind => $kind,
            requirement => $requirement,
            message => $message,
        };
    };

    my $profile_requirement = "profile:$args->{profile_id}:$args->{stage}";
    $add_required->($profile_requirement);
    if (!$profile) {
        $add_issue->(
            'profile_unknown', $profile_requirement,
            "profile '$args->{profile_id}' is not registered",
        );
    }
    elsif (!grep { $_ eq $args->{stage} } @{$profile->{stages}}) {
        $add_issue->(
            'stage_unsupported', $profile_requirement,
            "profile '$args->{profile_id}' does not own stage '$args->{stage}'",
        );
    }
    else {
        $add_satisfied->($profile_requirement);
    }

    if (defined $args->{source_language_version}) {
        my $requirement = "source_language:$args->{source_language_version}";
        $add_required->($requirement);
        if ($profile && grep {
                "$_" eq "$args->{source_language_version}"
            } @{$profile->{accepted_language_versions}}) {
            $add_satisfied->($requirement);
        }
        else {
            $add_issue->(
                'language_version', $requirement,
                "profile '$args->{profile_id}' does not accept VIAL language version $args->{source_language_version}",
            );
        }
    }
    if (defined $args->{execution_schema}) {
        my $requirement = "execution_schema:$args->{execution_schema}";
        $add_required->($requirement);
        if ($profile && grep {
                $_ eq $args->{execution_schema}
            } @{$profile->{accepted_execution_schemas}}) {
            $add_satisfied->($requirement);
        }
        else {
            $add_issue->(
                'execution_schema', $requirement,
                "profile '$args->{profile_id}' does not accept execution schema '$args->{execution_schema}'",
            );
        }
    }
    if (defined $args->{execution_profile}) {
        my $requirement = "execution_profile:$args->{execution_profile}";
        $add_required->($requirement);
        if ($profile && grep {
                $_ eq $args->{execution_profile}
            } @{$profile->{accepted_execution_profiles}}) {
            $add_satisfied->($requirement);
        }
        else {
            $add_issue->(
                'execution_profile', $requirement,
                "profile '$args->{profile_id}' does not accept execution profile '$args->{execution_profile}'",
            );
        }
    }

    my %required_family = map {
        ("$_->{family_id}\0$_->{revision}" => 1)
    } @{$requirements};
    my %family = map { ($_->{family_id} => $_) } @{$registry->{families}};
    my %profile_family = $profile ? map { ($_ => 1) }
        @{$profile->{supported_family_revisions}} : ();
    my %profile_capability = $profile ? map { ($_ => 1) }
        @{$profile->{supported_capabilities}} : ();
    my %profile_effect = $profile ? map { ($_ => 1) }
        @{$profile->{supported_effect_kinds}} : ();
    my %stage_to_maturity = (
        parser => 'source', planner => 'plan',
        emitter => 'emission', runner => 'runtime',
    );
    for my $entry (@{$requirements}) {
        my $identity = "$entry->{family_id}\@$entry->{revision}";
        my $family_requirement = "family:$identity";
        $add_required->($family_requirement);
        my $registered = $family{$entry->{family_id}};
        if (!$registered) {
            $add_issue->(
                'family_unknown', $family_requirement,
                "intent family '$entry->{family_id}' has no registered semantic grammar",
            );
        }
        elsif ($registered->{revision} != $entry->{revision}) {
            $add_issue->(
                'family_revision', $family_requirement,
                "intent family '$entry->{family_id}' revision $entry->{revision} is not registered; revision $registered->{revision} is selected",
            );
        }
        else {
            my $maturity_key = $stage_to_maturity{$args->{stage}};
            if ($registered->{maturity}{$maturity_key} eq 'unavailable') {
                $add_issue->(
                    'family_maturity', $family_requirement,
                    "intent family '$identity' is selected but has no implemented $maturity_key stage",
                );
            }
            elsif (!$profile_family{$identity}) {
                $add_issue->(
                    'family_profile', $family_requirement,
                    "profile '$args->{profile_id}' does not support intent family '$identity'",
                );
            }
            else {
                $add_satisfied->($family_requirement);
            }
            for my $dependency (@{$registered->{dependencies}}) {
                my $dependency_identity =
                    "$dependency->{family_id}\0$dependency->{revision}";
                my $requirement = "dependency:$identity->"
                    . "$dependency->{family_id}\@$dependency->{revision}";
                $add_required->($requirement);
                if ($required_family{$dependency_identity}) {
                    $add_satisfied->($requirement);
                }
                else {
                    $add_issue->(
                        'dependency_missing', $requirement,
                        "intent family '$identity' requires '$dependency->{family_id}\@$dependency->{revision}'",
                    );
                }
            }
        }
        for my $capability (@{$entry->{required_capabilities}}) {
            my $requirement = "capability:$capability";
            $add_required->($requirement);
            if ($profile_capability{$capability}) {
                $add_satisfied->($requirement);
            }
            else {
                $add_issue->(
                    'capability_unsupported', $requirement,
                    "profile '$args->{profile_id}' does not support capability '$capability'",
                );
            }
        }
        for my $effect (@{$entry->{effect_kinds}}) {
            my $requirement = "effect:$effect";
            $add_required->($requirement);
            if ($profile_effect{$effect}) {
                $add_satisfied->($requirement);
            }
            else {
                $add_issue->(
                    'effect_unsupported', $requirement,
                    "profile '$args->{profile_id}' does not support effect '$effect'",
                );
            }
        }
    }
    my @unsupported;
    my %seen_unsupported;
    for my $issue (@issues) {
        push @unsupported, $issue->{requirement}
            unless $seen_unsupported{$issue->{requirement}}++;
    }
    my %unsupported = map { $_ => 1 } @unsupported;
    @satisfied = grep { !$unsupported{$_} } @satisfied;
    return _clone({
        schema => 'fsmgen.vial_semantic_family_negotiation.v1',
        schema_version => 1,
        registry_id => $registry->{registry_id},
        stage => $args->{stage},
        profile_id => $args->{profile_id},
        accepted => @issues ? JSON::PP::false : JSON::PP::true,
        required => \@required,
        satisfied => \@satisfied,
        unsupported => \@unsupported,
        issues => \@issues,
    });
}

sub vial_semantic_family_negotiation_message {
    my ($negotiation) = @_;
    _exact_hash($negotiation, \@NEGOTIATION_KEYS,
        'semantic-family negotiation result');
    return 'semantic-family negotiation accepted'
        if $negotiation->{accepted};
    return 'semantic-family negotiation rejected: '
        . join('; ', map { $_->{message} } @{$negotiation->{issues}});
}

sub _requirements_from_family_records {
    my ($records, $stage) = @_;
    die "$stage semantic-family carrier must be an unblessed array\n"
        unless ref($records) eq 'ARRAY' && !blessed($records);
    my @requirements;
    for my $record (@{$records}) {
        _plain_hash($record, "$stage semantic-family record");
        my $semantic = $stage eq 'execution' ? $record->{semantic} : undef;
        my $family_id = $stage eq 'execution'
            ? $semantic->{family_id} : $record->{family_id};
        my $revision = $stage eq 'execution'
            ? $semantic->{revision} : $record->{revision};
        my @capabilities = $stage eq 'execution'
            ? @{$record->{required_capabilities} || []} : ();
        my @nodes = $stage eq 'execution'
            ? ($semantic) : @{$record->{nodes} || []};
        my @effects;
        for my $node (@nodes) {
            push @effects, map { $_->{kind} }
                @{$node->{effects} || []};
        }
        my @capability_set = sort(_unique(@capabilities));
        my @effect_set = sort(_unique(@effects));
        push @requirements, {
            family_id => $family_id,
            revision => $revision,
            required_capabilities => \@capability_set,
            effect_kinds => \@effect_set,
        };
    }
    return _validate_requirements(\@requirements);
}

sub _validate_requirements {
    my ($requirements) = @_;
    die "semantic-family requirements must be an unblessed array\n"
        unless ref($requirements) eq 'ARRAY' && !blessed($requirements);
    die "semantic-family requirements exceed the $LIMIT{families_per_negotiation}-entry limit\n"
        if @{$requirements} > $LIMIT{families_per_negotiation};
    my @validated;
    for my $requirement (@{$requirements}) {
        _plain_hash($requirement, 'semantic-family requirement');
        _exact_hash($requirement, \@REQUIREMENT_KEYS,
            'semantic-family requirement');
        _identifier($requirement->{family_id}, 'family_id');
        die "semantic-family revision must be a positive bounded integer\n"
            unless defined($requirement->{revision})
                && !ref($requirement->{revision})
                && $requirement->{revision} =~ /\A[1-9][0-9]*\z/
                && $requirement->{revision} <= 2_147_483_647;
        my $capabilities = _sorted_identifiers(
            $requirement->{required_capabilities}, 'required_capabilities',
            $LIMIT{capabilities_per_family},
        );
        my $effects = _sorted_identifiers(
            $requirement->{effect_kinds}, 'effect_kinds',
            $LIMIT{effects_per_family},
        );
        push @validated, {
            family_id => $requirement->{family_id},
            revision => 0 + $requirement->{revision},
            required_capabilities => $capabilities,
            effect_kinds => $effects,
        };
    }
    return \@validated;
}

sub _validate_registry {
    my ($registry) = @_;
    _plain_hash($registry, 'semantic-family registry');
    _exact_hash($registry, \@REGISTRY_KEYS, 'semantic-family registry');
    die "semantic-family registry schema is invalid\n"
        unless $registry->{schema} eq 'fsmgen.vial_semantic_family_registry.v1'
            && $registry->{schema_version} == 1;
    die "semantic-family registry identity is invalid\n"
        unless $registry->{registry_id}
            =~ m{\Avial-family-registry/[0-9a-f]{64}\z};
    my $identity = _clone($registry);
    $identity->{registry_id} = undef;
    die "semantic-family registry identity is not content-derived\n"
        unless $registry->{registry_id} eq 'vial-family-registry/'
            . sha256_hex(_canonical_json($identity));
    die "semantic-family registry exceeds its family limit\n"
        if @{$registry->{families}} > $LIMIT{families_per_registry};
    die "semantic-family registry exceeds its profile limit\n"
        if @{$registry->{profiles}} > $LIMIT{profiles_per_registry};
    my (%family, %profile, %bound);
    for my $entry (@{$registry->{bound_profiles}}) {
        _exact_hash($entry, \@BOUND_PROFILE_KEYS, 'bound profile');
        _identifier($entry->{bound_profile_id}, 'bound_profile_id');
        die "bound profile identity is duplicated\n"
            if $bound{$entry->{bound_profile_id}}++;
        _plain_hash($entry->{limits}, 'bound profile limits');
    }
    for my $entry (@{$registry->{profiles}}) {
        _exact_hash($entry, \@PROFILE_KEYS, 'semantic-family profile');
        _identifier($entry->{profile_id}, 'profile_id');
        die "semantic-family profile identity is duplicated\n"
            if $profile{$entry->{profile_id}}++;
        die "semantic-family profile kind is invalid\n"
            unless $entry->{profile_kind} =~ /\A(?:parser|execution|backend)\z/;
        _sorted_identifiers($entry->{stages}, 'profile stages', 4);
        _sorted_scalars($entry->{accepted_language_versions},
            'accepted language versions', 8);
        _sorted_identifiers($entry->{accepted_execution_schemas},
            'accepted execution schemas', 8);
        _sorted_identifiers($entry->{accepted_execution_profiles},
            'accepted execution profiles', 8);
        _sorted_family_revisions($entry->{supported_family_revisions});
        _sorted_identifiers($entry->{supported_capabilities},
            'supported capabilities', 512);
        _sorted_identifiers($entry->{supported_effect_kinds},
            'supported effect kinds', 512);
    }
    for my $entry (@{$registry->{families}}) {
        _exact_hash($entry, \@FAMILY_KEYS, 'semantic-family entry');
        _identifier($entry->{family_id}, 'family_id');
        die "semantic-family identity is duplicated\n"
            if $family{$entry->{family_id}}++;
        die "semantic-family revision is invalid\n"
            unless $entry->{revision} == 1;
        _identifier($entry->{capability_id}, 'capability_id');
        die "semantic-family dependency collection is too large\n"
            if @{$entry->{dependencies}} > $LIMIT{dependencies_per_family};
        for my $dependency (@{$entry->{dependencies}}) {
            _exact_hash($dependency, [qw(family_id revision)],
                'semantic-family dependency');
            _identifier($dependency->{family_id}, 'dependency family_id');
            die "semantic-family dependency revision is invalid\n"
                unless $dependency->{revision} == 1;
        }
        _sorted_identifiers($entry->{effect_kinds}, 'family effect kinds',
            $LIMIT{effects_per_family});
        die "semantic-family bound profile is unavailable\n"
            unless $bound{$entry->{bound_profile_id}};
        _validate_maturity($entry->{maturity}, \@MATURITY_KEYS);
        my %backend_mapping;
        for my $mapping (@{$entry->{backend_profiles}}) {
            _exact_hash($mapping, \@BACKEND_MAPPING_KEYS,
                'semantic-family backend mapping');
            die "semantic-family backend mapping profile is unavailable\n"
                unless $profile{$mapping->{profile_id}};
            die "semantic-family backend mapping profile is duplicated\n"
                if $backend_mapping{$mapping->{profile_id}}++;
            _validate_maturity($mapping->{maturity}, \@BACKEND_MATURITY_KEYS);
        }
        die "semantic-family backend mapping set is incomplete\n"
            unless join("\0", sort keys %backend_mapping)
                eq join("\0", @BACKEND_PROFILE_IDS);
        die "semantic-family task owner is invalid\n"
            unless $entry->{task_owner}
                =~ /\AHIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE\.19\.[0-9]+\z/;
    }
    return _clone($registry);
}

sub _unavailable_maturity {
    return {map { $_ => 'unavailable' } @MATURITY_KEYS};
}

sub _validate_maturity {
    my ($value, $keys) = @_;
    _exact_hash($value, $keys, 'semantic-family maturity');
    my %level = map { $_ => 1 } @MATURITY_LEVELS;
    die "semantic-family maturity level is invalid\n"
        if grep { !$level{$value->{$_}} } @{$keys};
}

sub _sorted_family_revisions {
    my ($values) = @_;
    die "supported family revisions must be an unblessed array\n"
        unless ref($values) eq 'ARRAY' && !blessed($values);
    my @sorted = sort @{$values};
    die "supported family revisions must be sorted and unique\n"
        unless _canonical_json($values) eq _canonical_json(\@sorted)
            && @sorted == _unique(@sorted);
    for my $value (@sorted) {
        die "supported family revision identity is invalid\n"
            unless defined($value) && !ref($value)
                && $value =~ /\A[A-Za-z][A-Za-z0-9_]*\@[1-9][0-9]*\z/;
    }
    return [@sorted];
}

sub _sorted_identifiers {
    my ($values, $label, $limit) = @_;
    die "$label must be an unblessed array\n"
        unless ref($values) eq 'ARRAY' && !blessed($values);
    die "$label exceeds its $limit-entry limit\n" if @{$values} > $limit;
    my @copy = map {
        _identifier($_, $label);
        $_;
    } @{$values};
    my @sorted = sort @copy;
    die "$label must be sorted and unique\n"
        unless _canonical_json(\@copy) eq _canonical_json(\@sorted)
            && @sorted == _unique(@sorted);
    return \@sorted;
}

sub _sorted_scalars {
    my ($values, $label, $limit) = @_;
    die "$label must be an unblessed array\n"
        unless ref($values) eq 'ARRAY' && !blessed($values);
    die "$label exceeds its $limit-entry limit\n" if @{$values} > $limit;
    die "$label must contain scalar values\n"
        if grep { !defined($_) || ref($_) } @{$values};
    my @sorted = sort { "$a" cmp "$b" } @{$values};
    die "$label must be sorted and unique\n"
        unless _canonical_json($values) eq _canonical_json(\@sorted)
            && @sorted == _unique(map { "$_" } @sorted);
    return [@sorted];
}

sub _identifier {
    my ($value, $label) = @_;
    die "$label is invalid\n"
        unless defined($value) && !ref($value)
            && $value =~ /\A[A-Za-z][A-Za-z0-9_.-]*\z/
            && length($value) <= 192;
    return $value;
}

sub _optional_scalar {
    my ($value, $label) = @_;
    die "$label must be null or scalar\n"
        if defined($value) && ref($value);
}

sub _plain_hash {
    my ($value, $label) = @_;
    die "$label must be one unblessed hash\n"
        unless ref($value) eq 'HASH' && !blessed($value);
}

sub _exact_hash {
    my ($value, $keys, $label) = @_;
    _plain_hash($value, $label);
    my %expected = map { $_ => 1 } @{$keys};
    my @unknown = sort grep { !$expected{$_} } keys %{$value};
    my @missing = grep { !exists($value->{$_}) } @{$keys};
    die "$label has unknown key '$unknown[0]'\n" if @unknown;
    die "$label is missing key '$missing[0]'\n" if @missing;
}

sub _unique {
    my %seen;
    return grep { !$seen{$_}++ } @_;
}

sub _canonical_json {
    return JSON::PP->new->canonical->utf8->encode($_[0]);
}

sub _clone {
    my ($value) = @_;
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    my $type = ref($value) ? (reftype($value) || '') : '';
    return {map { $_ => _clone($value->{$_}) } sort keys %{$value}}
        if $type eq 'HASH';
    return [map { _clone($_) } @{$value}] if $type eq 'ARRAY';
    die "VIAL semantic-family registry contains unsupported reference type '$type'\n"
        if ref($value);
    return $value;
}

1;
