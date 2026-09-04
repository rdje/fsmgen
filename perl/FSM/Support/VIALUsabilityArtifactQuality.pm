package FSM::Support::VIALUsabilityArtifactQuality;

use strict;
use warnings;

use bytes ();
use Digest::SHA qw(sha256_hex);
use Exporter 'import';
use JSON::PP ();
use Scalar::Util qw(blessed reftype);

our @EXPORT_OK = qw(
    build_vial_usability_artifact_quality_contract
    evaluate_vial_author_quality
    evaluate_vial_backend_artifact_quality
    vial_author_quality_report_keys
    vial_backend_artifact_quality_report_keys
    vial_usability_artifact_quality_contract_keys
);

my @CONTRACT_KEYS = qw(
    schema schema_version contract_id status author_surface_kinds
    semantic_document_kinds public_fixture_paths forbidden_vocabulary
    quality_dimensions profile_ids profiles explicit_nonclaims
);
my @RULE_KEYS = qw(rule_id expression witness);
my @PROFILE_KEYS = qw(
    profile_id source_languages required_artifact_roles required_source_roles
    conditional_artifact_roles max_total_artifacts max_source_artifacts max_source_bytes
    max_source_map_entries readability
);
my @CONDITIONAL_ROLE_KEYS = qw(feature role);
my @READABILITY_KEYS = qw(
    preferred_line_bytes minimum_preferred_line_numerator
    minimum_preferred_line_denominator max_line_bytes require_final_newline
    forbid_tab forbid_nul
);
my @AUTHOR_REPORT_KEYS = qw(
    schema schema_version contract_id accepted surface_count
    semantic_document_count checked_bytes dimensions issues
);
my @BACKEND_REPORT_KEYS = qw(
    schema schema_version contract_id profile_id accepted artifact_count
    source_artifact_count source_bytes source_map_entries total_lines
    preferred_lines max_line_bytes dimensions issues
);
my @ISSUE_KEYS = qw(dimension code path message);
my @BACKEND_DIMENSIONS = qw(
    deterministic readable minimal_shape source_mapped bounded_cost
    absence_driven_elision
);

sub vial_usability_artifact_quality_contract_keys {
    return [@CONTRACT_KEYS];
}

sub vial_author_quality_report_keys {
    return [@AUTHOR_REPORT_KEYS];
}

sub vial_backend_artifact_quality_report_keys {
    return [@BACKEND_REPORT_KEYS];
}

sub build_vial_usability_artifact_quality_contract {
    my @forbidden = (
        {
            rule_id => 'backend_language_name',
            expression => '\\b(?:SystemVerilog|Verilator|UVM|VHDL|GHDL|OSVVM)\\b',
            witness => 'UVM',
        },
        {
            rule_id => 'systemverilog_process_syntax',
            expression => '\\b(?:always_ff|always_comb|virtual\\s+interface|std::randomize)\\b',
            witness => 'always_ff',
        },
        {
            rule_id => 'uvm_plumbing_identifier',
            expression => '\\buvm_[A-Za-z0-9_]+\\b',
            witness => 'uvm_config_db',
        },
        {
            rule_id => 'uvm_transport_identifier',
            expression => '\\b(?:analysis_port|seq_item_port|tlm_fifo)\\b',
            witness => 'analysis_port',
        },
        {
            rule_id => 'vhdl_type_or_edge_syntax',
            expression => '\\b(?:std_logic(?:_vector)?|rising_edge|falling_edge)\\b',
            witness => 'std_logic_vector',
        },
        {
            rule_id => 'osvvm_package_identifier',
            expression => '\\b(?:OsvvmContext|AlertLogPkg|CoveragePkg|RandomPkg|TbUtilPkg)\\b',
            witness => 'OsvvmContext',
        },
        {
            rule_id => 'backend_profile_identifier',
            expression => '\\b(?:sv_portable_verilator|sv_uvm_emit\\.accellera_2020_3_1|vhdl_portable_ghdl|vhdl_osvvm_qualified)\\b',
            witness => 'vhdl_portable_ghdl',
        },
        {
            rule_id => 'methodology_configuration_identifier',
            expression => '\\b(?:config_db|factory_override|type_override)\\b',
            witness => 'factory_override',
        },
        {
            rule_id => 'target_language_directive',
            expression => '(?:`timescale|library\\s+ieee|use\\s+ieee\\.)',
            witness => 'library ieee',
        },
    );
    my @profiles = (
        _profile(
            'sv_portable_verilator', ['systemverilog'],
            [qw(
                backend_manifest backend_source_map compile_command
                generated_hial_dut run_command selected_tool_profile
                vial_generated_fixture vial_runtime_support
            )], [], [qw(
                generated_hial_dut vial_generated_fixture vial_runtime_support
            )], 8, 3,
        ),
        _profile(
            'sv_uvm_emit.accellera_2020_3_1', ['systemverilog'],
            [qw(
                backend_manifest backend_source_map bound_sva_checker
                generated_hial_dut review_workflow selected_mapping_matrix
                selected_methodology_profile static_validation
                uvm_checking_results uvm_component_foundations
                uvm_fixture_interface uvm_fixture_package uvm_fixture_top
                uvm_notification_interception uvm_stimulus_services
                uvm_types_package
            )], [], [qw(
                bound_sva_checker generated_hial_dut uvm_checking_results
                uvm_component_foundations uvm_fixture_interface
                uvm_fixture_package uvm_fixture_top
                uvm_notification_interception uvm_stimulus_services
                uvm_types_package
            )], 16, 10,
        ),
        _profile(
            'vhdl_osvvm_qualified', ['vhdl'],
            [qw(
                advanced_mapping_matrix backend_manifest backend_source_map
                combined_qualification_reference portable_generated_hial_vhdl_dut
                portable_vhdl_fixture_metadata portable_vhdl_fixture_top
                portable_vhdl_runtime_package portable_vhdl_types_package
                provider_materialization semantic_preservation source_order
                static_validation tool_profile vhdl_osvvm_adapter_package
            )], [{feature => 'verification_probe',
                    role => 'portable_vhdl_probe_adapter'}], [qw(
                portable_generated_hial_vhdl_dut
                portable_vhdl_fixture_metadata portable_vhdl_fixture_top
                portable_vhdl_runtime_package portable_vhdl_types_package
                vhdl_osvvm_adapter_package
            )], 16, 7,
        ),
        _profile(
            'vhdl_portable_ghdl', ['vhdl'],
            [qw(
                analyze_command backend_manifest backend_source_map
                elaborate_command generated_hial_vhdl_dut migration_proof
                ordered_vhdl_sources review_workflow run_command
                selected_mapping_matrix selected_tool_profile
                vhdl_fixture_metadata vhdl_fixture_top vhdl_runtime_package
                vhdl_static_validation vhdl_types_package
            )], [{feature => 'verification_probe', role => 'vhdl_probe_adapter'}],
            [qw(
                generated_hial_vhdl_dut vhdl_fixture_metadata vhdl_fixture_top
                vhdl_runtime_package vhdl_types_package
            )], 17, 6,
        ),
    );
    my $contract = {
        schema => 'fsmgen.vial_usability_artifact_quality_contract.v1',
        schema_version => 1,
        contract_id => undef,
        status => 'executable_foundation_and_lifecycle_compiler_quality_gate',
        author_surface_kinds => [qw(
            public_example canonical_normal canonical_terse source_diagnostic
        )],
        semantic_document_kinds => [qw(
            semantic_ir semantic_family_carrier
        )],
        public_fixture_paths => [qw(
            vial/ahb_subordinate_base_output_arbitration.vial
            vial/ahb_subordinate_base_output_arbitration_v2.vial
            vial/ahb_subordinate_base_output_arbitration_lifecycle_v2.vial
            vial/qualification/sv_portable_verilator_runtime_gate.vial
            vial/qualification/sv_portable_verilator_runtime_qualification.vial
            vial/qualification/vhdl_portable_ghdl_runtime_gate.vial
            vial/qualification/vhdl_portable_ghdl_runtime_qualification.vial
        )],
        forbidden_vocabulary => \@forbidden,
        quality_dimensions => [qw(
            target_free_author_surface target_free_semantic_carrier
            deterministic readable minimal_shape source_mapped bounded_cost
            absence_driven_elision
        )],
        profile_ids => [map { $_->{profile_id} } @profiles],
        profiles => \@profiles,
        explicit_nonclaims => [qw(
            public_api support_promotion non_lifecycle_family_implementation
            backend_byte_change runtime_qualification subjective_style_proof
            arbitrary_generated_language_quality
        )],
    };
    my $identity = _clone($contract);
    $identity->{contract_id} = undef;
    $contract->{contract_id} = 'vial-quality/'
        . sha256_hex(_canonical_json($identity));
    return _validate_contract($contract);
}

sub evaluate_vial_author_quality {
    my ($args) = @_;
    _plain_hash($args, 'author-quality evaluation');
    _exact_hash($args, [qw(surfaces semantic_documents)],
        'author-quality evaluation');
    _plain_array($args->{surfaces}, 'author-quality surfaces');
    _plain_array($args->{semantic_documents},
        'author-quality semantic_documents');

    my $contract = build_vial_usability_artifact_quality_contract();
    my %surface_kind = map { $_ => 1 } @{$contract->{author_surface_kinds}};
    my %public_fixture = map { $_ => 1 } @{$contract->{public_fixture_paths}};
    my %document_kind = map { $_ => 1 }
        @{$contract->{semantic_document_kinds}};
    my @issues;
    my %seen_surface_kind;
    my %seen_surface_id;
    my %seen_public_fixture;
    my %seen_document_kind;
    my $checked_bytes = 0;

    for my $index (0 .. $#{$args->{surfaces}}) {
        my $surface = $args->{surfaces}[$index];
        _plain_hash($surface, "author surface $index");
        _exact_hash($surface, [qw(surface_id kind text)],
            "author surface $index");
        _bounded_scalar($surface->{surface_id}, "author surface $index id", 512);
        _bounded_scalar($surface->{kind}, "author surface $index kind", 64);
        die "author surface $index has unknown kind '$surface->{kind}'\n"
            unless $surface_kind{$surface->{kind}};
        die "author surface $index text must be a scalar\n"
            if !defined($surface->{text}) || ref($surface->{text});
        _issue(\@issues, 'target_free_author_surface',
            'VIAL_AUTHOR_SURFACE_ID_DUPLICATED', "/surfaces/$index/surface_id",
            "author surface id '$surface->{surface_id}' is duplicated")
            if $seen_surface_id{$surface->{surface_id}}++;
        if ($surface->{kind} eq 'public_example') {
            _issue(\@issues, 'target_free_author_surface',
                'VIAL_AUTHOR_PUBLIC_FIXTURE_UNKNOWN',
                "/surfaces/$index/surface_id",
                "public example '$surface->{surface_id}' is not maintained")
                unless $public_fixture{$surface->{surface_id}};
            $seen_public_fixture{$surface->{surface_id}}++
                if $public_fixture{$surface->{surface_id}};
        }
        $seen_surface_kind{$surface->{kind}}++;
        $checked_bytes += bytes::length($surface->{text});
        _scan_text(
            text => $surface->{text},
            path => "/surfaces/$index/text",
            dimension => 'target_free_author_surface',
            code => 'VIAL_AUTHOR_TARGET_VOCABULARY',
            rules => $contract->{forbidden_vocabulary},
            issues => \@issues,
        );
    }

    for my $index (0 .. $#{$args->{semantic_documents}}) {
        my $document = $args->{semantic_documents}[$index];
        _plain_hash($document, "semantic document $index");
        _exact_hash($document, [qw(document_id kind value)],
            "semantic document $index");
        _bounded_scalar($document->{document_id},
            "semantic document $index id", 512);
        _bounded_scalar($document->{kind},
            "semantic document $index kind", 64);
        die "semantic document $index has unknown kind '$document->{kind}'\n"
            unless $document_kind{$document->{kind}};
        _assert_plain_json($document->{value},
            "/semantic_documents/$index/value");
        $seen_document_kind{$document->{kind}} = 1;
        _scan_value(
            value => $document->{value},
            path => "/semantic_documents/$index/value",
            rules => $contract->{forbidden_vocabulary},
            issues => \@issues,
        );
    }

    for my $kind (@{$contract->{author_surface_kinds}}) {
        _issue(\@issues, 'target_free_author_surface',
            'VIAL_AUTHOR_SURFACE_MISSING', '/surfaces',
            "required author surface kind '$kind' is absent")
            unless $seen_surface_kind{$kind};
    }
    for my $path (@{$contract->{public_fixture_paths}}) {
        _issue(\@issues, 'target_free_author_surface',
            'VIAL_AUTHOR_PUBLIC_FIXTURE_MISSING', '/surfaces',
            "maintained public example '$path' is absent")
            unless ($seen_public_fixture{$path} // 0) == 1;
    }
    for my $kind (@{$contract->{semantic_document_kinds}}) {
        _issue(\@issues, 'target_free_semantic_carrier',
            'VIAL_SEMANTIC_DOCUMENT_MISSING', '/semantic_documents',
            "required semantic document kind '$kind' is absent")
            unless $seen_document_kind{$kind};
    }

    my %failed = map { $_->{dimension} => 1 } @issues;
    my $report = {
        schema => 'fsmgen.vial_author_quality_report.v1',
        schema_version => 1,
        contract_id => $contract->{contract_id},
        accepted => _bool(!@issues),
        surface_count => scalar(@{$args->{surfaces}}),
        semantic_document_count => scalar(@{$args->{semantic_documents}}),
        checked_bytes => $checked_bytes,
        dimensions => {
            target_free_author_surface =>
                _bool(!$failed{target_free_author_surface}),
            target_free_semantic_carrier =>
                _bool(!$failed{target_free_semantic_carrier}),
        },
        issues => \@issues,
    };
    return _clone($report);
}

sub evaluate_vial_backend_artifact_quality {
    my ($args) = @_;
    _plain_hash($args, 'backend-artifact-quality evaluation');
    _exact_hash($args,
        [qw(profile_id emission repeat_emission feature_presence)],
        'backend-artifact-quality evaluation');
    _bounded_scalar($args->{profile_id}, 'backend profile_id', 128);
    _plain_hash($args->{emission}, 'backend emission');
    _plain_hash($args->{repeat_emission}, 'repeated backend emission');
    _plain_hash($args->{feature_presence}, 'backend feature_presence');
    _exact_hash($args->{feature_presence}, ['verification_probe'],
        'backend feature_presence');
    die "backend feature_presence verification_probe must be boolean-like\n"
        unless _boolean_like($args->{feature_presence}{verification_probe});

    my $contract = build_vial_usability_artifact_quality_contract();
    my ($profile) = grep { $_->{profile_id} eq $args->{profile_id} }
        @{$contract->{profiles}};
    die "backend-artifact-quality evaluation has unknown profile '$args->{profile_id}'\n"
        unless $profile;

    my @issues;
    _issue(\@issues, 'deterministic', 'VIAL_ARTIFACT_NONDETERMINISTIC',
        '/repeat_emission', 'repeated backend emission bytes changed')
        unless _canonical_json($args->{emission})
            eq _canonical_json($args->{repeat_emission});

    my $emission = $args->{emission};
    _issue(\@issues, 'minimal_shape', 'VIAL_ARTIFACT_PROFILE_MISMATCH',
        '/emission/backend_profile', 'emission backend profile changed')
        unless defined($emission->{backend_profile})
            && !ref($emission->{backend_profile})
            && $emission->{backend_profile} eq $profile->{profile_id};
    _issue(\@issues, 'minimal_shape', 'VIAL_ARTIFACT_EMISSION_FAILED',
        '/emission/ok', 'quality evaluation requires a successful emission')
        unless $emission->{ok};

    my $artifacts = $emission->{artifacts};
    if (ref($artifacts) ne 'ARRAY' || blessed($artifacts)) {
        _issue(\@issues, 'minimal_shape', 'VIAL_ARTIFACT_GRAPH_INVALID',
            '/emission/artifacts', 'artifact graph must be one plain array');
        $artifacts = [];
    }
    my %source_language = map { $_ => 1 } @{$profile->{source_languages}};
    my (@source, %artifact_by_path, %role_count, %source_role_count);
    my @paths;
    for my $index (0 .. $#$artifacts) {
        my $artifact = $artifacts->[$index];
        if (ref($artifact) ne 'HASH' || blessed($artifact)) {
            _issue(\@issues, 'minimal_shape', 'VIAL_ARTIFACT_RECORD_INVALID',
                "/emission/artifacts/$index",
                'artifact record must be one plain hash');
            next;
        }
        my $path = $artifact->{relpath};
        my $role = $artifact->{role};
        if (!_safe_relpath($path)) {
            _issue(\@issues, 'minimal_shape', 'VIAL_ARTIFACT_PATH_INVALID',
                "/emission/artifacts/$index/relpath",
                'artifact path must be safe and repository-relative');
            next;
        }
        if (!defined($role) || ref($role) || $role !~ /\A[a-z][a-z0-9_]*\z/) {
            _issue(\@issues, 'minimal_shape', 'VIAL_ARTIFACT_ROLE_INVALID',
                "/emission/artifacts/$index/role",
                'artifact role must be one lowercase identifier');
            next;
        }
        _issue(\@issues, 'minimal_shape', 'VIAL_ARTIFACT_PATH_DUPLICATED',
            "/emission/artifacts/$index/relpath",
            "artifact path '$path' is duplicated") if $artifact_by_path{$path};
        $artifact_by_path{$path} = $artifact;
        $role_count{$role}++;
        push @paths, $path;
        if (defined($artifact->{language}) && !ref($artifact->{language})
            && $source_language{$artifact->{language}}) {
            push @source, $artifact;
            $source_role_count{$role}++;
        }
    }
    _issue(\@issues, 'minimal_shape', 'VIAL_ARTIFACT_ORDER_CHANGED',
        '/emission/artifacts', 'artifact graph must be sorted by relative path')
        unless join("\0", @paths) eq join("\0", sort @paths);

    my @expected_roles = @{$profile->{required_artifact_roles}};
    for my $conditional (@{$profile->{conditional_artifact_roles}}) {
        push @expected_roles, $conditional->{role}
            if $args->{feature_presence}{$conditional->{feature}};
        if (!$args->{feature_presence}{$conditional->{feature}}
            && $role_count{$conditional->{role}}) {
            _issue(\@issues, 'absence_driven_elision',
                'VIAL_OPTIONAL_ARTIFACT_NOT_ELIDED', '/emission/artifacts',
                "role '$conditional->{role}' remains while feature '$conditional->{feature}' is absent");
        }
    }
    my %expected_role = map { $_ => 1 } @expected_roles;
    my @unexpected = sort grep { !$expected_role{$_} } keys %role_count;
    my @missing = sort grep { !$role_count{$_} } keys %expected_role;
    my @duplicated = sort grep { $role_count{$_} != 1 } keys %role_count;
    _issue(\@issues, 'minimal_shape', 'VIAL_ARTIFACT_ROLE_SET_CHANGED',
        '/emission/artifacts', 'artifact roles must equal the profile-specific minimal set')
        if @unexpected || @missing || @duplicated;

    my $source_bytes = 0;
    my $total_lines = 0;
    my $preferred_lines = 0;
    my $max_line_bytes = 0;
    my $readability = $profile->{readability};
    for my $artifact (@source) {
        my $content = $artifact->{content};
        my $path = $artifact->{relpath};
        if (!defined($content) || ref($content)) {
            _issue(\@issues, 'readable', 'VIAL_SOURCE_CONTENT_INVALID',
                "/emission/artifacts/$path/content",
                'generated source content must be a scalar');
            next;
        }
        my $bytes = bytes::length($content);
        $source_bytes += $bytes;
        _issue(\@issues, 'readable', 'VIAL_SOURCE_FINAL_NEWLINE_MISSING',
            "/emission/artifacts/$path/content",
            'generated source must end with one newline')
            if $readability->{require_final_newline} && $content !~ /\n\z/;
        _issue(\@issues, 'readable', 'VIAL_SOURCE_TAB_PRESENT',
            "/emission/artifacts/$path/content",
            'generated source contains a literal tab')
            if $readability->{forbid_tab} && index($content, "\t") >= 0;
        _issue(\@issues, 'readable', 'VIAL_SOURCE_NUL_PRESENT',
            "/emission/artifacts/$path/content",
            'generated source contains a NUL byte')
            if $readability->{forbid_nul} && index($content, "\0") >= 0;
        my @line = split /\n/, $content, -1;
        pop @line if @line && $line[-1] eq '';
        for my $line (@line) {
            my $line_bytes = bytes::length($line);
            $total_lines++;
            $preferred_lines++
                if $line_bytes <= $readability->{preferred_line_bytes};
            $max_line_bytes = $line_bytes if $line_bytes > $max_line_bytes;
        }
    }
    _issue(\@issues, 'readable', 'VIAL_SOURCE_EMPTY',
        '/emission/artifacts', 'generated source inventory has no source lines')
        unless $total_lines;
    _issue(\@issues, 'readable', 'VIAL_SOURCE_READABILITY_RATIO_LOW',
        '/emission/artifacts',
        'too few generated source lines meet the preferred readable width')
        if $total_lines
            && $preferred_lines
                * $readability->{minimum_preferred_line_denominator}
                < $total_lines
                    * $readability->{minimum_preferred_line_numerator};
    _issue(\@issues, 'readable', 'VIAL_SOURCE_LINE_LIMIT_EXCEEDED',
        '/emission/artifacts', 'generated source line exceeds the hard byte bound')
        if $max_line_bytes > $readability->{max_line_bytes};

    _issue(\@issues, 'bounded_cost', 'VIAL_ARTIFACT_COUNT_LIMIT_EXCEEDED',
        '/emission/artifacts', 'artifact count exceeds the profile bound')
        if @$artifacts > $profile->{max_total_artifacts};
    _issue(\@issues, 'bounded_cost', 'VIAL_SOURCE_COUNT_LIMIT_EXCEEDED',
        '/emission/artifacts', 'source artifact count exceeds the profile bound')
        if @source > $profile->{max_source_artifacts};
    my @expected_source_roles = @{$profile->{required_source_roles}};
    for my $conditional (@{$profile->{conditional_artifact_roles}}) {
        push @expected_source_roles, $conditional->{role}
            if $args->{feature_presence}{$conditional->{feature}};
    }
    my %expected_source_role = map { $_ => 1 } @expected_source_roles;
    my @unexpected_source = sort grep {
        !$expected_source_role{$_}
    } keys %source_role_count;
    my @missing_source = sort grep {
        !$source_role_count{$_}
    } keys %expected_source_role;
    my @duplicated_source = sort grep {
        $source_role_count{$_} != 1
    } keys %source_role_count;
    _issue(\@issues, 'minimal_shape', 'VIAL_SOURCE_ROLE_SET_CHANGED',
        '/emission/artifacts',
        'source artifact roles and languages must equal the feature-adjusted profile shape')
        if @unexpected_source || @missing_source || @duplicated_source;
    _issue(\@issues, 'bounded_cost', 'VIAL_SOURCE_BYTES_LIMIT_EXCEEDED',
        '/emission/artifacts', 'generated source bytes exceed the profile bound')
        if $source_bytes > $profile->{max_source_bytes};

    my $source_map = $emission->{source_map};
    my $source_map_entries = 0;
    if (ref($source_map) ne 'HASH' || blessed($source_map)
        || ref($source_map->{artifacts}) ne 'ARRAY'
        || ref($source_map->{entries}) ne 'ARRAY') {
        _issue(\@issues, 'source_mapped', 'VIAL_SOURCE_MAP_INVALID',
            '/emission/source_map',
            'source map must contain plain artifact and entry arrays');
    }
    else {
        $source_map_entries = scalar(@{$source_map->{entries}});
        _evaluate_source_map(\@issues, \@source, $source_map);
        _issue(\@issues, 'bounded_cost',
            'VIAL_SOURCE_MAP_ENTRY_LIMIT_EXCEEDED',
            '/emission/source_map/entries',
            'source-map entry count exceeds the profile bound')
            if $source_map_entries > $profile->{max_source_map_entries};
    }

    my %failed = map { $_->{dimension} => 1 } @issues;
    my %dimensions = map { $_ => _bool(!$failed{$_}) } @BACKEND_DIMENSIONS;
    my $report = {
        schema => 'fsmgen.vial_backend_artifact_quality_report.v1',
        schema_version => 1,
        contract_id => $contract->{contract_id},
        profile_id => $profile->{profile_id},
        accepted => _bool(!@issues),
        artifact_count => scalar(@$artifacts),
        source_artifact_count => scalar(@source),
        source_bytes => $source_bytes,
        source_map_entries => $source_map_entries,
        total_lines => $total_lines,
        preferred_lines => $preferred_lines,
        max_line_bytes => $max_line_bytes,
        dimensions => \%dimensions,
        issues => \@issues,
    };
    return _clone($report);
}

sub _profile {
    my ($profile_id, $languages, $required, $conditional, $source_roles,
        $total, $sources) = @_;
    return {
        profile_id => $profile_id,
        source_languages => $languages,
        required_artifact_roles => [sort @$required],
        required_source_roles => [sort @$source_roles],
        conditional_artifact_roles => $conditional,
        max_total_artifacts => $total,
        max_source_artifacts => $sources,
        max_source_bytes => 16_777_216,
        max_source_map_entries => 1_000_000,
        readability => {
            preferred_line_bytes => 160,
            minimum_preferred_line_numerator => 9,
            minimum_preferred_line_denominator => 10,
            max_line_bytes => 4_096,
            require_final_newline => JSON::PP::true,
            forbid_tab => JSON::PP::true,
            forbid_nul => JSON::PP::true,
        },
    };
}

sub _evaluate_source_map {
    my ($issues, $sources, $source_map) = @_;
    my %source = map { $_->{relpath} => $_ } @$sources;
    my %reference;
    for my $index (0 .. $#{$source_map->{artifacts}}) {
        my $reference = $source_map->{artifacts}[$index];
        if (ref($reference) ne 'HASH' || blessed($reference)
            || !_safe_relpath($reference->{relpath})) {
            _issue($issues, 'source_mapped', 'VIAL_SOURCE_MAP_REFERENCE_INVALID',
                "/emission/source_map/artifacts/$index",
                'source-map artifact reference is invalid');
            next;
        }
        my $path = $reference->{relpath};
        $reference{$path}++;
        my $artifact = $source{$path};
        if (!$artifact) {
            _issue($issues, 'source_mapped',
                'VIAL_SOURCE_MAP_REFERENCE_UNKNOWN',
                "/emission/source_map/artifacts/$index/relpath",
                "source-map reference '$path' names no source artifact");
            next;
        }
        my $content = $artifact->{content};
        next unless defined($content) && !ref($content);
        my $expected_sha = sha256_hex($content);
        my $expected_bytes = bytes::length($content);
        _issue($issues, 'source_mapped', 'VIAL_SOURCE_MAP_HASH_CHANGED',
            "/emission/source_map/artifacts/$index/sha256",
            "source-map hash for '$path' does not match source bytes")
            unless defined($reference->{sha256})
                && !ref($reference->{sha256})
                && $reference->{sha256} eq $expected_sha;
        my $reported_bytes = exists($reference->{bytes})
            ? $reference->{bytes} : $reference->{byte_length};
        _issue($issues, 'source_mapped', 'VIAL_SOURCE_MAP_BYTES_CHANGED',
            "/emission/source_map/artifacts/$index",
            "source-map byte count for '$path' does not match source bytes")
            unless defined($reported_bytes) && !ref($reported_bytes)
                && "$reported_bytes" =~ /\A[0-9]+\z/
                && $reported_bytes == $expected_bytes;
    }
    for my $path (sort keys %source) {
        _issue($issues, 'source_mapped', 'VIAL_SOURCE_MAP_ARTIFACT_MISSING',
            '/emission/source_map/artifacts',
            "source artifact '$path' lacks one exact map reference")
            unless ($reference{$path} // 0) == 1;
    }

    my (%entry_id, %covered);
    for my $index (0 .. $#{$source_map->{entries}}) {
        my $entry = $source_map->{entries}[$index];
        if (ref($entry) ne 'HASH' || blessed($entry)) {
            _issue($issues, 'source_mapped', 'VIAL_SOURCE_MAP_ENTRY_INVALID',
                "/emission/source_map/entries/$index",
                'source-map entry must be one plain hash');
            next;
        }
        my $path = $entry->{generated_relpath};
        my $id = $entry->{source_map_id};
        if (!_safe_relpath($path) || !$source{$path}) {
            _issue($issues, 'source_mapped', 'VIAL_SOURCE_MAP_ENTRY_PATH_INVALID',
                "/emission/source_map/entries/$index/generated_relpath",
                'source-map entry names no generated source artifact');
            next;
        }
        $covered{$path}++;
        _issue($issues, 'source_mapped', 'VIAL_SOURCE_MAP_ID_INVALID',
            "/emission/source_map/entries/$index/source_map_id",
            'source-map identity must be a unique nonempty scalar')
            if !defined($id) || ref($id) || $id eq '' || $entry_id{$id}++;
        my @lines = split /\n/, $source{$path}{content}, -1;
        pop @lines if @lines && $lines[-1] eq '';
        my ($start, $end) = @{$entry}{qw(
            generated_start_line generated_end_line
        )};
        _issue($issues, 'source_mapped', 'VIAL_SOURCE_MAP_SPAN_INVALID',
            "/emission/source_map/entries/$index",
            'source-map line span lies outside generated source')
            unless defined($start) && defined($end)
                && !ref($start) && !ref($end)
                && "$start" =~ /\A[0-9]+\z/ && "$end" =~ /\A[0-9]+\z/
                && $start >= 1 && $end >= $start && $end <= @lines;
        _issue($issues, 'source_mapped', 'VIAL_SOURCE_MAP_SYMBOL_MISSING',
            "/emission/source_map/entries/$index/generated_symbol",
            'source-map entry lacks a readable generated symbol')
            unless defined($entry->{generated_symbol})
                && !ref($entry->{generated_symbol})
                && $entry->{generated_symbol} ne '';
        _issue($issues, 'source_mapped', 'VIAL_SOURCE_MAP_ROLE_MISSING',
            "/emission/source_map/entries/$index/role",
            'source-map entry lacks a semantic role')
            unless defined($entry->{role}) && !ref($entry->{role})
                && $entry->{role} ne '';
    }
    for my $path (sort keys %source) {
        _issue($issues, 'source_mapped', 'VIAL_SOURCE_MAP_COVERAGE_MISSING',
            '/emission/source_map/entries',
            "source artifact '$path' has no source-map entry")
            unless $covered{$path};
    }
}

sub _scan_text {
    my (%args) = @_;
    for my $rule (@{$args{rules}}) {
        my $regex = qr/$rule->{expression}/i;
        next unless $args{text} =~ /$regex/;
        my $prefix = substr($args{text}, 0, $-[0]);
        my $line = 1 + ($prefix =~ tr/\n/\n/);
        _issue($args{issues}, $args{dimension}, $args{code},
            "$args{path}:$line",
            "forbidden target or methodology vocabulary '$rule->{rule_id}' is present");
    }
}

sub _scan_value {
    my (%args) = @_;
    my $value = $args{value};
    if (ref($value) eq 'HASH') {
        for my $key (sort keys %$value) {
            _scan_text(
                text => $key, path => "$args{path}/$key",
                dimension => 'target_free_semantic_carrier',
                code => 'VIAL_SEMANTIC_METHODOLOGY_LEAK',
                rules => $args{rules}, issues => $args{issues},
            );
            _scan_value(%args, value => $value->{$key},
                path => "$args{path}/$key");
        }
    }
    elsif (ref($value) eq 'ARRAY') {
        _scan_value(%args, value => $value->[$_],
            path => "$args{path}/$_") for 0 .. $#$value;
    }
    elsif (defined($value) && !ref($value)) {
        _scan_text(
            text => "$value", path => $args{path},
            dimension => 'target_free_semantic_carrier',
            code => 'VIAL_SEMANTIC_METHODOLOGY_LEAK',
            rules => $args{rules}, issues => $args{issues},
        );
    }
}

sub _validate_contract {
    my ($contract) = @_;
    _exact_hash($contract, \@CONTRACT_KEYS, 'quality contract');
    die "quality contract schema is invalid\n"
        unless $contract->{schema}
            eq 'fsmgen.vial_usability_artifact_quality_contract.v1'
            && $contract->{schema_version} == 1;
    my $identity = _clone($contract);
    $identity->{contract_id} = undef;
    die "quality contract identity is not content-derived\n"
        unless $contract->{contract_id} eq 'vial-quality/'
            . sha256_hex(_canonical_json($identity));
    my %rule;
    for my $entry (@{$contract->{forbidden_vocabulary}}) {
        _exact_hash($entry, \@RULE_KEYS, 'forbidden vocabulary rule');
        die "quality contract has duplicate forbidden rule '$entry->{rule_id}'\n"
            if $rule{$entry->{rule_id}}++;
        my $regex = qr/$entry->{expression}/i;
        die "quality contract forbidden-rule witness is invalid\n"
            unless $entry->{witness} =~ /$regex/;
    }
    my %profile;
    for my $entry (@{$contract->{profiles}}) {
        _exact_hash($entry, \@PROFILE_KEYS, 'quality profile');
        die "quality contract has duplicate profile '$entry->{profile_id}'\n"
            if $profile{$entry->{profile_id}}++;
        _exact_hash($entry->{readability}, \@READABILITY_KEYS,
            'profile readability');
        my %role;
        die "quality profile required artifact roles are not sorted\n"
            unless join("\0", @{$entry->{required_artifact_roles}})
                eq join("\0", sort @{$entry->{required_artifact_roles}});
        $role{$_}++ for @{$entry->{required_artifact_roles}};
        die "quality profile required source roles are not sorted\n"
            unless join("\0", @{$entry->{required_source_roles}})
                eq join("\0", sort @{$entry->{required_source_roles}});
        my %source_role;
        for my $source_role (@{$entry->{required_source_roles}}) {
            die "quality profile source role '$source_role' is not an artifact role\n"
                unless $role{$source_role};
            die "quality profile source role '$source_role' is duplicated\n"
                if $source_role{$source_role}++;
        }
        for my $conditional (@{$entry->{conditional_artifact_roles}}) {
            _exact_hash($conditional, \@CONDITIONAL_ROLE_KEYS,
                'conditional artifact role');
            die "quality profile role '$conditional->{role}' is duplicated\n"
                if $role{$conditional->{role}}++;
        }
        die "quality profile source artifact ceiling is inconsistent\n"
            unless $entry->{max_source_artifacts}
                == @{$entry->{required_source_roles}}
                    + @{$entry->{conditional_artifact_roles}};
    }
    die "quality contract profile index changed\n"
        unless join("\0", @{$contract->{profile_ids}})
            eq join("\0", map { $_->{profile_id} } @{$contract->{profiles}});
    return _clone($contract);
}

sub _issue {
    my ($issues, $dimension, $code, $path, $message) = @_;
    push @$issues, {
        dimension => $dimension,
        code => $code,
        path => $path,
        message => $message,
    };
}

sub _bool {
    return $_[0] ? JSON::PP::true : JSON::PP::false;
}

sub _boolean_like {
    my ($value) = @_;
    return 1 if blessed($value) && $value->isa('JSON::PP::Boolean');
    return defined($value) && !ref($value) && "$value" =~ /\A[01]\z/;
}

sub _bounded_scalar {
    my ($value, $label, $limit) = @_;
    die "$label must be a nonempty bounded scalar\n"
        unless defined($value) && !ref($value) && $value ne ''
            && bytes::length($value) <= $limit;
}

sub _safe_relpath {
    my ($value) = @_;
    return defined($value) && !ref($value) && $value ne ''
        && bytes::length($value) <= 4096
        && $value !~ m{\A/|(?:\A|/)\.\.(?:/|\z)|\\|\0};
}

sub _plain_hash {
    my ($value, $label) = @_;
    die "$label must be one plain hash\n"
        unless ref($value) eq 'HASH' && !blessed($value);
}

sub _plain_array {
    my ($value, $label) = @_;
    die "$label must be one plain array\n"
        unless ref($value) eq 'ARRAY' && !blessed($value);
}

sub _exact_hash {
    my ($value, $keys, $label) = @_;
    _plain_hash($value, $label);
    my @actual = sort keys %$value;
    my @expected = sort @$keys;
    die "$label key set is not closed\n"
        unless join("\0", @actual) eq join("\0", @expected);
}

sub _assert_plain_json {
    my ($value, $path) = @_;
    return unless ref($value);
    return if blessed($value) && $value->isa('JSON::PP::Boolean');
    die "semantic document contains blessed data at $path\n" if blessed($value);
    my $type = reftype($value) || '';
    if ($type eq 'HASH') {
        _assert_plain_json($value->{$_}, "$path/$_") for sort keys %$value;
        return;
    }
    if ($type eq 'ARRAY') {
        _assert_plain_json($value->[$_], "$path/$_") for 0 .. $#$value;
        return;
    }
    die "semantic document contains unsupported reference type '$type' at $path\n";
}

sub _canonical_json {
    return JSON::PP->new->canonical(1)->utf8(1)->encode($_[0]);
}

sub _clone {
    my ($value) = @_;
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    return {map { $_ => _clone($value->{$_}) } sort keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    die "quality contract cannot clone blessed data\n" if blessed($value);
    die "quality contract cannot clone reference type '" . ref($value) . "'\n"
        if ref($value);
    return $value;
}

1;
