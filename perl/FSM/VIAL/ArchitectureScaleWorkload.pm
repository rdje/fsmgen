package FSM::VIAL::ArchitectureScaleWorkload;

use v5.20;
use strict;
use warnings;
use bytes ();
use Carp qw(confess);
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use Fcntl qw(O_CREAT O_EXCL O_WRONLY);
use File::Path qw(remove_tree);
use File::Spec;
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::VIAL::ExecutionRandom;

my $SPEC_SCHEMA = 'fsmgen.vial_architecture_scale_workload.v1';
my $CONSTRUCTION_SCHEMA = 'fsmgen.vial_architecture_scale_construction.v1';
my $STAGING_SCHEMA = 'fsmgen.vial_architecture_scale_staging.v1';
my $GENERATOR_REVISION = 'fsmgen.vial_architecture_scale_generator.v1';
my $SEED = 1701;
my $STAGING_BASE = '.artifacts/tmp/vial-scale';
my $MAX_INPUT_BYTES = 17_825_792;
my $MAX_SINGLE_INPUT_BYTES = 1_114_112;
my @LEVELS = qw(
    reference_v1 gate_candidate_v1 qualification_candidate_v1 limit_v1
    over_limit_v1
);
my @SPEC_KEYS = qw(
    schema schema_version family level primary_axis requested_counts
    expected_stage expected_outcome generator_revision seed anchor_identity
    source_route backend_profile tool_profile applicable_oracles
    explicit_nonclaims
);
my @CONSTRUCT_KEYS = qw(
    family level primary_axis backend_profile tool_profile inputs
);
my @INPUT_KEYS = qw(relative_path role encoding content);
my @CONSTRUCTION_KEYS = qw(
    ok status schema schema_version workload_identity specification
    input_identities inputs staging_identity diagnostics
);
my @STAGING_KEYS = qw(
    ok status schema schema_version workload_identity staging_identity
    same_volume removed diagnostics
);
my @NONCLAIMS = qw(
    architecture_scale_capacity whole_product_big whole_product_really_big
    multi_unit multi_domain mixed_language native_uvm_runtime full_language
    synthesis general_cross_backend_parity
);

sub specification_keys($class) {
    _exact_invocant($class, 'specification_keys');
    return [@SPEC_KEYS];
}

sub construction_keys($class) {
    _exact_invocant($class, 'construction_keys');
    return [@CONSTRUCTION_KEYS];
}

sub staging_keys($class) {
    _exact_invocant($class, 'staging_keys');
    return [@STAGING_KEYS];
}

sub catalog($class) {
    _exact_invocant($class, 'catalog');
    return _clone(_catalog_data());
}

sub stable_name($class, @args) {
    _exact_invocant($class, 'stable_name');
    confess __PACKAGE__ . "->stable_name expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $raw = $args[0];
    _confess_exact_keys($raw, [qw(family primary_axis ordinal)], 'stable name');
    my ($family, $axis) = @{$raw}{qw(family primary_axis)};
    confess "stable name family is invalid\n" unless _safe_token($family);
    confess "stable name primary_axis is invalid\n" unless _safe_token($axis);
    confess "stable name ordinal must be an unsigned integer below 100000000\n"
        unless defined($raw->{ordinal}) && !ref($raw->{ordinal})
            && $raw->{ordinal} =~ /\A(?:0|[1-9][0-9]*)\z/
            && $raw->{ordinal} < 100_000_000;
    return join('__', 'vial_scale', $family, $axis, sprintf('%08d', $raw->{ordinal}));
}

sub payload_uint($class, @args) {
    _exact_invocant($class, 'payload_uint');
    confess __PACKAGE__ . "->payload_uint expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $raw = $args[0];
    _confess_exact_keys($raw, [qw(family primary_axis ordinal low high)], 'payload request');
    my $name = $class->stable_name({
        family => $raw->{family},
        primary_axis => $raw->{primary_axis},
        ordinal => $raw->{ordinal},
    });
    my $generated = FSM::VIAL::ExecutionRandom->generate({
        width => 64,
        seed => $SEED,
        occurrence_id => "$GENERATOR_REVISION/$name/payload",
        low => $raw->{low},
        high => $raw->{high},
    });
    confess "architecture-scale payload rejection bound was exhausted\n"
        unless defined $generated;
    return {
        algorithm => FSM::VIAL::ExecutionRandom->algorithm_id,
        seed => $SEED,
        occurrence_id => "$GENERATOR_REVISION/$name/payload",
        value => $generated->{value}->bstr,
        attempt => 0 + $generated->{attempt},
    };
}

sub construct($class, @args) {
    return _construction_failure(
        'VIAL_SCALE_INVOCATION_ERROR',
        'construct requires the exact ArchitectureScaleWorkload class invocant',
        '/',
    ) unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return _construction_failure(
        'VIAL_SCALE_INVOCATION_ERROR',
        'construct expects one closed argument hash',
        '/',
    ) unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);

    my $result = eval { _construct($args[0]) };
    return $result if defined $result;
    my $error = $@;
    return _construction_failure($error->{code}, $error->{message}, $error->{path})
        if blessed($error) && $error->isa(__PACKAGE__ . '::Failure');
    return _construction_failure(
        'VIAL_SCALE_HOST_ERROR', _sanitize_exception($error), '/',
    );
}

sub with_staging($class, @args) {
    return _staging_failure(
        'VIAL_SCALE_INVOCATION_ERROR',
        'with_staging requires the exact ArchitectureScaleWorkload class invocant',
        '/',
    ) unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return _staging_failure(
        'VIAL_SCALE_INVOCATION_ERROR',
        'with_staging expects one closed argument hash',
        '/',
    ) unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);

    my $result = eval { _with_staging($args[0]) };
    return $result if defined $result;
    my $error = $@;
    return _staging_failure($error->{code}, $error->{message}, $error->{path})
        if blessed($error) && $error->isa(__PACKAGE__ . '::Failure');
    return _staging_failure(
        'VIAL_SCALE_HOST_ERROR', _sanitize_exception($error), '/',
    );
}

sub _construct($raw) {
    _require_exact_keys($raw, \@CONSTRUCT_KEYS, 'workload construction');
    my $specification = _selected_specification($raw);
    my ($inputs, $identities) = _validated_inputs($raw->{inputs});
    _validate_family_inputs($specification->{family}, $inputs);
    my $identity_projection = {
        specification => $specification,
        input_content_digests => $identities,
    };
    my $digest = sha256_hex(_canonical_json($identity_projection));
    my $workload_identity = "workload/$digest";
    return _construction_result({
        ok => JSON::PP::true,
        status => 'constructed_unmeasured',
        schema => $CONSTRUCTION_SCHEMA,
        schema_version => 1,
        workload_identity => $workload_identity,
        specification => $specification,
        input_identities => $identities,
        inputs => $inputs,
        staging_identity => "$STAGING_BASE/$digest",
        diagnostics => [],
    });
}

sub _selected_specification($raw) {
    my $catalog = _catalog_data();
    for my $key (qw(family level primary_axis)) {
        _throw('VIAL_SCALE_SPEC_ERROR', "$key must be a non-empty scalar", "/$key")
            unless defined($raw->{$key}) && !ref($raw->{$key}) && length($raw->{$key});
    }
    my $family = $raw->{family};
    my $family_contract = $family eq 'balanced_portable_v1'
        ? $catalog->{balanced_profile}
        : $catalog->{families}{$family};
    _throw('VIAL_SCALE_SPEC_ERROR', "unknown workload family '$family'", '/family')
        unless defined $family_contract;
    my $axis = $raw->{primary_axis};
    my $axis_contract = $family_contract->{axes}{$axis};
    _throw('VIAL_SCALE_SPEC_ERROR', "unknown primary axis '$axis' for '$family'", '/primary_axis')
        unless defined $axis_contract;
    my $level = $raw->{level};
    my $requested = $axis_contract->{levels}{$level};
    _throw('VIAL_SCALE_SPEC_ERROR', "level '$level' is not selected for '$family/$axis'", '/level')
        unless defined $requested;

    my ($backend_profile, $tool_profile) = _validated_profiles(
        $catalog, $family, $raw->{backend_profile}, $raw->{tool_profile},
    );
    my $counts = _clone($requested);
    if ($family eq 'backend_emission_v1') {
        $counts->{backend_authority} = _clone(
            $catalog->{backend_profiles}{$backend_profile}{structural_authority}
        );
    }
    if ($family eq 'runtime_stream_v1') {
        $counts->{backend_limits} = _clone(
            $catalog->{backend_profiles}{$backend_profile}{runtime_limits}
        );
    }

    return {
        schema => $SPEC_SCHEMA,
        schema_version => 1,
        family => $family,
        level => $level,
        primary_axis => $axis,
        requested_counts => $counts,
        expected_stage => $axis_contract->{expected_stage},
        expected_outcome => _expected_outcome($level),
        generator_revision => $GENERATOR_REVISION,
        seed => $SEED,
        anchor_identity => _clone($catalog->{anchor_identity}),
        source_route => $family_contract->{source_route},
        backend_profile => $backend_profile,
        tool_profile => $tool_profile,
        applicable_oracles => _clone($family_contract->{applicable_oracles}),
        explicit_nonclaims => [@NONCLAIMS],
    };
}

sub _validated_profiles($catalog, $family, $backend, $tool) {
    my $requires_backend = $family =~ /\A(?:backend_emission|runtime_stream)_v1\z/
        || $family eq 'balanced_portable_v1';
    if (!$requires_backend) {
        _throw('VIAL_SCALE_SPEC_ERROR', 'backend_profile must be null for this family', '/backend_profile')
            if defined $backend;
        _throw('VIAL_SCALE_SPEC_ERROR', 'tool_profile must be null for this family', '/tool_profile')
            if defined $tool;
        return (undef, undef);
    }
    _throw('VIAL_SCALE_SPEC_ERROR', 'backend_profile must name one selected profile', '/backend_profile')
        unless defined($backend) && !ref($backend)
            && exists $catalog->{backend_profiles}{$backend};
    if ($family eq 'balanced_portable_v1') {
        _throw('VIAL_SCALE_SPEC_ERROR', 'balanced_portable_v1 uses sv_portable_verilator', '/backend_profile')
            unless $backend eq 'sv_portable_verilator';
    }
    if ($family eq 'runtime_stream_v1') {
        my $profile = $catalog->{backend_profiles}{$backend};
        _throw('VIAL_SCALE_SPEC_ERROR', 'backend profile is not runtime-eligible', '/backend_profile')
            unless $profile->{runtime_eligible};
        _throw('VIAL_SCALE_SPEC_ERROR', 'tool_profile does not match the selected qualified backend', '/tool_profile')
            unless defined($tool) && !ref($tool) && $tool eq $profile->{tool_profile};
        return ($backend, $tool);
    }
    _throw('VIAL_SCALE_SPEC_ERROR', 'tool_profile must be null until runtime measurement', '/tool_profile')
        if defined $tool;
    return ($backend, undef);
}

sub _validated_inputs($raw) {
    _throw('VIAL_SCALE_INPUT_ERROR', 'inputs must be a non-empty array', '/inputs')
        unless ref($raw) eq 'ARRAY' && @$raw;
    my (@inputs, @identities, %exact, %folded, %directory);
    my $total_bytes = 0;
    for my $index (0 .. $#$raw) {
        my $input = $raw->[$index];
        _throw('VIAL_SCALE_INPUT_ERROR', "input $index must be one unblessed hash", "/inputs/$index")
            unless ref($input) eq 'HASH' && !blessed($input);
        _require_exact_keys($input, \@INPUT_KEYS, "input $index");
        my $relative = $input->{relative_path};
        _throw('VIAL_SCALE_INPUT_ERROR', "input $index relative_path is unsafe", "/inputs/$index/relative_path")
            unless _safe_relative_path($relative);
        _throw('VIAL_SCALE_INPUT_ERROR', "duplicate input path '$relative'", "/inputs/$index/relative_path")
            if $exact{$relative}++;
        my $folded = lc($relative);
        _throw('VIAL_SCALE_INPUT_ERROR', "case-fold input collision at '$relative'", "/inputs/$index/relative_path")
            if exists($folded{$folded}) && $folded{$folded} ne $relative;
        $folded{$folded} = $relative;
        my @parts = split m{/}, $relative;
        pop @parts;
        my $prefix = '';
        for my $part (@parts) {
            $prefix = length($prefix) ? "$prefix/$part" : $part;
            _throw('VIAL_SCALE_INPUT_ERROR', "input file/directory collision at '$prefix'", "/inputs/$index/relative_path")
                if $exact{$prefix};
            $directory{$prefix} = 1;
        }
        _throw('VIAL_SCALE_INPUT_ERROR', "input file/directory collision at '$relative'", "/inputs/$index/relative_path")
            if $directory{$relative};

        my $role = $input->{role};
        my %suffix = (
            vial_source => qr{\.vial\z}i,
            hial_source => qr{\.(?:fsm|isf|ppif)\z}i,
            replay_manifest => qr{\.json\z}i,
        );
        _throw('VIAL_SCALE_INPUT_ERROR', "input $index role is unsupported", "/inputs/$index/role")
            unless defined($role) && !ref($role) && exists $suffix{$role};
        _throw('VIAL_SCALE_INPUT_ERROR', "input $index path does not match role '$role'", "/inputs/$index/relative_path")
            unless $relative =~ $suffix{$role};
        _throw('VIAL_SCALE_INPUT_ERROR', "input $index encoding must be utf-8", "/inputs/$index/encoding")
            unless defined($input->{encoding}) && !ref($input->{encoding})
                && lc($input->{encoding}) eq 'utf-8';
        _throw('VIAL_SCALE_INPUT_ERROR', "input $index content must be a scalar without NUL bytes", "/inputs/$index/content")
            unless defined($input->{content}) && !ref($input->{content})
                && index($input->{content}, "\0") < 0;
        my $bytes = bytes::length($input->{content});
        _throw('VIAL_SCALE_INPUT_ERROR', "input $index exceeds the bounded construction envelope", "/inputs/$index/content")
            if $bytes > $MAX_SINGLE_INPUT_BYTES;
        $total_bytes += $bytes;
        _throw('VIAL_SCALE_INPUT_ERROR', 'combined inputs exceed the bounded construction envelope', '/inputs')
            if $total_bytes > $MAX_INPUT_BYTES;
        push @inputs, {
            relative_path => $relative,
            role => $role,
            encoding => 'utf-8',
            content => $input->{content},
        };
    }
    @inputs = sort { $a->{relative_path} cmp $b->{relative_path} } @inputs;
    for my $input (@inputs) {
        push @identities, {
            relative_path => $input->{relative_path},
            role => $input->{role},
            encoding => $input->{encoding},
            bytes => bytes::length($input->{content}),
            sha256 => sha256_hex($input->{content}),
        };
    }
    return (\@inputs, \@identities);
}

sub _validate_family_inputs($family, $inputs) {
    my %role;
    $role{$_->{role}}++ for @$inputs;
    if ($family eq 'semantic_catalog_v1') {
        _throw('VIAL_SCALE_INPUT_ERROR', 'semantic workloads accept only VIAL source inputs', '/inputs')
            if ($role{hial_source} || $role{replay_manifest});
        return;
    }
    _throw('VIAL_SCALE_INPUT_ERROR', 'this workload family requires exactly one HIAL source input', '/inputs')
        unless ($role{hial_source} // 0) == 1;
    _throw('VIAL_SCALE_INPUT_ERROR', 'this workload family requires at least one VIAL source input', '/inputs')
        unless $role{vial_source};
    if ($family eq 'bridge_fanout_v1') {
        _throw('VIAL_SCALE_INPUT_ERROR', 'bridge construction does not accept a replay manifest', '/inputs')
            if $role{replay_manifest};
        return;
    }
    _throw('VIAL_SCALE_INPUT_ERROR', 'at most one replay manifest is accepted', '/inputs')
        if ($role{replay_manifest} // 0) > 1;
}

sub _with_staging($raw) {
    _require_exact_keys($raw, [qw(repository_root construction consumer)], 'staging invocation');
    _throw('VIAL_SCALE_INVOCATION_ERROR', 'consumer must be one code reference', '/consumer')
        unless ref($raw->{consumer}) eq 'CODE';
    my $construction = _validated_construction($raw->{construction});
    _throw('VIAL_SCALE_PATH_ERROR', 'repository_root must be a scalar directory path', '/repository_root')
        unless defined($raw->{repository_root}) && !ref($raw->{repository_root});
    my $repo_root = abs_path($raw->{repository_root});
    _throw('VIAL_SCALE_PATH_ERROR', 'repository root is not a readable directory', '/repository_root')
        unless defined($repo_root) && -d $repo_root;
    my $git_identity = File::Spec->catfile($repo_root, '.git');
    my @git_identity_stat = lstat($git_identity);
    _throw('VIAL_SCALE_PATH_ERROR', 'repository root does not contain a regular Git identity', '/repository_root')
        unless @git_identity_stat && !-l _ && (-f _ || -d _);
    my @root_stat = stat($repo_root);
    _throw('VIAL_SCALE_PATH_ERROR', 'repository filesystem identity is unavailable', '/repository_root')
        unless @root_stat;

    my @created_base;
    my $base_abs = _ensure_directory_chain(
        $repo_root, $STAGING_BASE, $root_stat[0], \@created_base,
    );
    my ($digest) = $construction->{workload_identity} =~ m{\Aworkload/([0-9a-f]{64})\z};
    _throw('VIAL_SCALE_SPEC_ERROR', 'construction workload identity is invalid', '/construction/workload_identity')
        unless defined $digest;
    my $stage_rel = "$STAGING_BASE/$digest";
    my $stage_abs = File::Spec->catdir($base_abs, $digest);
    _throw('VIAL_SCALE_COLLISION', "staging root '$stage_rel' already exists", '/staging_identity')
        if -e $stage_abs || -l $stage_abs;

    my $stage_created = 0;
    my $consumer_started = 0;
    my $workflow_ok = eval {
        mkdir($stage_abs)
            or _throw('VIAL_SCALE_HOST_ERROR', "cannot create staging root '$stage_rel'", '/staging_identity');
        $stage_created = 1;
        _assert_same_volume_directory($stage_abs, $stage_rel, $root_stat[0]);
        _materialize_inputs($stage_abs, $stage_rel, $construction->{inputs}, $root_stat[0]);
        my @context_inputs = map {
            {
                relative_path => $_->{relative_path},
                role => $_->{role},
                sha256 => sha256_hex($_->{content}),
                absolute_path => File::Spec->catfile(
                    $stage_abs, 'inputs', split(m{/}, $_->{relative_path}),
                ),
            }
        } @{$construction->{inputs}};
        $consumer_started = 1;
        $raw->{consumer}->({
            staging_identity => $stage_rel,
            staging_root => $stage_abs,
            inputs => \@context_inputs,
        });
        1;
    };
    my $workflow_error = $@;

    my $cleanup_error = _remove_owned_stage($stage_abs, $stage_rel, $stage_created);
    _remove_empty_created_directories(\@created_base);
    _throw('VIAL_SCALE_CLEANUP_ERROR', $cleanup_error, '/staging_identity')
        if defined $cleanup_error;
    if (!$workflow_ok) {
        die $workflow_error
            if blessed($workflow_error) && $workflow_error->isa(__PACKAGE__ . '::Failure');
        my $message = _sanitize_exception($workflow_error);
        $message =~ s{\Q$repo_root\E}{<repo>}g;
        _throw(
            $consumer_started ? 'VIAL_SCALE_CONSUMER_ERROR' : 'VIAL_SCALE_HOST_ERROR',
            $message,
            $consumer_started ? '/consumer' : '/staging_identity',
        );
    }

    return _staging_result({
        ok => JSON::PP::true,
        status => 'consumed_unmeasured',
        schema => $STAGING_SCHEMA,
        schema_version => 1,
        workload_identity => $construction->{workload_identity},
        staging_identity => $stage_rel,
        same_volume => JSON::PP::true,
        removed => JSON::PP::true,
        diagnostics => [],
    });
}

sub _validated_construction($raw) {
    _throw('VIAL_SCALE_INVOCATION_ERROR', 'construction must be one unblessed hash', '/construction')
        unless ref($raw) eq 'HASH' && !blessed($raw);
    _require_exact_keys($raw, \@CONSTRUCTION_KEYS, 'construction');
    _throw('VIAL_SCALE_SPEC_ERROR', 'construction must be successful', '/construction/ok')
        unless $raw->{ok};
    my $spec = $raw->{specification};
    _throw('VIAL_SCALE_SPEC_ERROR', 'construction specification must be one hash', '/construction/specification')
        unless ref($spec) eq 'HASH' && !blessed($spec);
    _require_exact_keys($spec, \@SPEC_KEYS, 'workload specification');
    my $rebuilt = _construct({
        family => $spec->{family},
        level => $spec->{level},
        primary_axis => $spec->{primary_axis},
        backend_profile => $spec->{backend_profile},
        tool_profile => $spec->{tool_profile},
        inputs => $raw->{inputs},
    });
    _throw('VIAL_SCALE_SPEC_ERROR', 'construction specification is not canonical', '/construction/specification')
        unless _canonical_json($rebuilt->{specification}) eq _canonical_json($spec);
    for my $key (qw(workload_identity staging_identity)) {
        _throw('VIAL_SCALE_SPEC_ERROR', "construction $key is not canonical", "/construction/$key")
            unless defined($raw->{$key}) && !ref($raw->{$key})
                && $raw->{$key} eq $rebuilt->{$key};
    }
    _throw('VIAL_SCALE_SPEC_ERROR', 'construction input identities are not canonical', '/construction/input_identities')
        unless _canonical_json($raw->{input_identities}) eq _canonical_json($rebuilt->{input_identities});
    return $rebuilt;
}

sub _materialize_inputs($stage_abs, $stage_rel, $inputs, $root_device) {
    my $input_root = File::Spec->catdir($stage_abs, 'inputs');
    mkdir($input_root)
        or _throw('VIAL_SCALE_HOST_ERROR', "cannot create '$stage_rel/inputs'", '/staging_identity');
    _assert_same_volume_directory($input_root, "$stage_rel/inputs", $root_device);
    for my $input (@$inputs) {
        my @parts = split m{/}, $input->{relative_path};
        my $file = pop @parts;
        my $parent = $input_root;
        my $parent_rel = "$stage_rel/inputs";
        for my $part (@parts) {
            $parent = File::Spec->catdir($parent, $part);
            $parent_rel .= "/$part";
            if (!-e $parent && !-l $parent) {
                mkdir($parent)
                    or _throw('VIAL_SCALE_HOST_ERROR', "cannot create '$parent_rel'", '/staging_identity');
            }
            _assert_same_volume_directory($parent, $parent_rel, $root_device);
        }
        my $path = File::Spec->catfile($parent, $file);
        sysopen(my $fh, $path, O_WRONLY | O_CREAT | O_EXCL)
            or _throw('VIAL_SCALE_HOST_ERROR', "cannot create staged input '$input->{relative_path}'", '/inputs');
        binmode($fh, ':raw');
        print {$fh} $input->{content}
            or _throw('VIAL_SCALE_HOST_ERROR', "cannot write staged input '$input->{relative_path}'", '/inputs');
        close($fh)
            or _throw('VIAL_SCALE_HOST_ERROR', "cannot close staged input '$input->{relative_path}'", '/inputs');
        my @file_stat = stat($path);
        _throw('VIAL_SCALE_PATH_ERROR', "staged input '$input->{relative_path}' left the repository volume", '/inputs')
            unless @file_stat && $file_stat[0] == $root_device && -f _ && !-l $path;
    }
}

sub _ensure_directory_chain($repo_root, $relative, $root_device, $created) {
    my $path = $repo_root;
    my $identity = '';
    for my $part (split m{/}, $relative) {
        $identity = length($identity) ? "$identity/$part" : $part;
        $path = File::Spec->catdir($path, $part);
        if (-e $path || -l $path) {
            _assert_same_volume_directory($path, $identity, $root_device);
            next;
        }
        mkdir($path)
            or _throw('VIAL_SCALE_HOST_ERROR', "cannot create directory '$identity'", '/staging_identity');
        _assert_same_volume_directory($path, $identity, $root_device);
        push @$created, $path;
    }
    return $path;
}

sub _assert_same_volume_directory($path, $identity, $root_device) {
    my @entry = lstat($path);
    _throw('VIAL_SCALE_PATH_ERROR', "path '$identity' is unreadable", '/staging_identity')
        unless @entry;
    _throw('VIAL_SCALE_PATH_ERROR', "path '$identity' must be a non-symlink directory", '/staging_identity')
        if -l _ || !-d _;
    my @resolved = stat($path);
    _throw('VIAL_SCALE_PATH_ERROR', "path '$identity' left the repository volume", '/staging_identity')
        unless @resolved && $resolved[0] == $root_device;
}

sub _remove_owned_stage($stage_abs, $stage_rel, $created) {
    return undef unless $created;
    return "owned staging root '$stage_rel' became a symlink"
        if -l $stage_abs;
    if (-d $stage_abs) {
        my $errors;
        remove_tree($stage_abs, {error => \$errors});
        return "cannot remove owned staging root '$stage_rel'"
            if defined($errors) && @$errors;
    }
    return "owned staging root '$stage_rel' remains after cleanup"
        if -e $stage_abs || -l $stage_abs;
    return undef;
}

sub _remove_empty_created_directories($created) {
    for my $path (reverse @$created) {
        next if -l $path || !-d $path;
        rmdir($path);
    }
}

sub _catalog_data() {
    my $anchor = {
        profile => 'checked_ahb_reference_v1',
        vial_source => 'vial/ahb_subordinate_base_output_arbitration.vial',
        vial_bytes => 4_986,
        vial_lines => 123,
        vial_sha256 => '2205b3b4f073a61374b19cb72f06afe31d75fc4d88f903c414b9b28a744ca4cd',
        fixture_count => 1,
        selected_units => 1,
        selected_domains => 1,
        scenarios => 2,
        operations_total => 21,
        fibers_total => 4,
        simultaneously_live_fibers => 3,
        bindings => 22,
        execution_types => 9,
        model_instances => 2,
        scoreboard_instances => 1,
        scoreboard_declared_capacity => 4,
        coverpoints => 1,
        coverage_bins => 2,
        faults => 1,
        random_occurrences => 1,
        plan_source_map_records => 39,
    };
    my $backend_profiles = {
        sv_portable_verilator => {
            tool_profile => 'verilator_5_046',
            runtime_eligible => JSON::PP::true,
            structural_authority => {
                backend_artifacts_base => 3,
                dut_artifacts_per_selected_unit => 1,
                generated_bytes => 16_777_216,
                source_map_entries => 1_000_000,
            },
            runtime_limits => {
                compile_transcript_bytes => 8_388_608,
                run_transcript_bytes => 67_108_864,
                runtime_trace_records => 8_000_002,
                runtime_trace_bytes => 67_108_864,
            },
        },
        vhdl_portable_ghdl => {
            tool_profile => 'ghdl_6_0_0_llvm_jit',
            runtime_eligible => JSON::PP::true,
            structural_authority => {
                generated_sources => 6,
                total_artifacts => 17,
                generated_bytes => 16_777_216,
                reference_source_map_entries => 59,
            },
            runtime_limits => {
                compile_transcript_bytes => 8_388_608,
                run_transcript_bytes => 67_108_864,
                runtime_trace_records => 8_000_002,
                runtime_trace_bytes => 67_108_864,
            },
        },
        vhdl_osvvm_qualified => {
            tool_profile => 'osvvm_2026_05_ghdl_6_0_0_llvm_jit',
            runtime_eligible => JSON::PP::true,
            structural_authority => {
                portable_generated_sources => 6,
                generated_provider_sources => 7,
                generated_bytes => 16_777_216,
                provider_materialization => 'external_exact_osvvm_2026_05',
            },
            runtime_limits => {
                compile_transcript_bytes => 8_388_608,
                run_transcript_bytes => 67_108_864,
                runtime_trace_records => 8_000_002,
                runtime_trace_bytes => 67_108_864,
            },
        },
        'sv_uvm_emit.accellera_2020_3_1' => {
            tool_profile => undef,
            runtime_eligible => JSON::PP::false,
            structural_authority => {
                generated_sources => 10,
                total_artifacts => 16,
                generated_bytes => 16_777_216,
                execution_status => 'emission_and_static_review_only',
            },
            runtime_limits => {},
        },
    };
    my $families = {
        semantic_catalog_v1 => _family(
            'semantic', 'vial_source_v1', [qw(construct semantic failure)], {
                imports => _numeric_axis('semantic', 'imports', 8, 32, 64, 65),
                declarations => _numeric_axis('semantic', 'declarations', 128, 1_024, 4_096, 4_097),
                fixtures => _numeric_axis('semantic', 'fixtures', 32, 256, 1_024, 1_025),
                actions => _numeric_axis('semantic', 'actions', 1_024, 16_384, 65_536, 65_537),
                parallel_depth => _numeric_axis('semantic', 'parallel_depth', 4, 12, 16, 17),
                fibers_per_parallel => _numeric_axis('semantic', 'fibers_per_parallel', 32, 128, 256, 257),
                scalar_or_list_length => _numeric_axis('semantic', 'scalar_or_list_length', 4_096, 32_768, 65_536, 65_537),
                record_fields => _numeric_axis('semantic', 'record_fields', 32, 128, 256, 257),
                aggregate_depth => _numeric_axis('semantic', 'aggregate_depth', 8, 24, 32, 33),
                scoreboard_capacity => _numeric_axis('semantic', 'scoreboard_capacity', 4_096, 262_144, 1_000_000, 1_000_001),
                coverage_bins => _numeric_axis('semantic', 'coverage_bins', 4_096, 262_144, 1_000_000, 1_000_001),
                literal_repeat_count => _numeric_axis('semantic', 'literal_repeat_count', 4_096, 262_144, 1_000_000, 1_000_001),
                source_bytes_per_source => _byte_axis('semantic', 'source_bytes_per_source', 1_048_576),
                source_bytes_combined => _byte_axis('semantic', 'source_bytes_combined', 16_777_216),
            },
        ),
        bridge_fanout_v1 => _family(
            'bridge', 'canonical_hial_bridge_v1', [qw(construct semantic bridge failure)], {
                selected_units => _numeric_axis('bridge', 'selected_units', 1, 1, 1, 2),
                selected_domains => _numeric_axis('bridge', 'selected_domains', 1, 1, 1, 2),
                configurations => _numeric_axis('bridge', 'configurations', 256, 2_048, 4_096, 4_097),
                types => _numeric_axis('bridge', 'types', 256, 2_048, 4_096, 4_097),
                endpoints => _numeric_axis('bridge', 'endpoints', 256, 2_048, 4_096, 4_097),
                transactions => _numeric_axis('bridge', 'transactions', 32, 192, 256, 257),
                events => _numeric_axis('bridge', 'events', 256, 1_536, 2_048, 2_049),
                observations => _numeric_axis('bridge', 'observations', 32, 192, 256, 257),
                probes => _numeric_axis('bridge', 'probes', 32, 192, 256, 257),
                backend_bindings => _numeric_axis('bridge', 'backend_bindings', 2_048, 12_288, 16_384, 16_385),
                retained_residue_records => _numeric_axis('bridge', 'retained_residue_records', 256, 2_048, 4_096, 4_097),
                source_map_records => _numeric_axis('bridge', 'source_map_records', 8_192, 49_152, 65_536, 65_537),
                serialized_manifest_bytes => _byte_axis('bridge', 'serialized_manifest_bytes', 16_777_216),
            },
        ),
        execution_graph_v1 => _family(
            'plan', 'generated_vial_hial_route_v1', [qw(construct semantic bridge plan failure)], {
                selected_fixtures => _numeric_axis('plan', 'selected_fixtures', 1, 1, 1, 2),
                selected_units => _numeric_axis('plan', 'selected_units', 1, 1, 1, 2),
                selected_domains => _numeric_axis('plan', 'selected_domains', 1, 1, 1, 2),
                scenarios => _numeric_axis('plan', 'scenarios', 32, 512, 4_096, 4_097),
                operations_per_scenario => _numeric_axis('plan', 'operations_per_scenario', 256, 8_192, 65_536, 65_537),
                operations_total => _numeric_axis('plan', 'operations_total', 1_024, 65_536, 1_000_000, 1_000_001),
                fibers_total => _numeric_axis('plan', 'fibers_total', 128, 8_192, 65_536, 65_537),
                simultaneously_live_fibers => _numeric_axis('plan', 'simultaneously_live_fibers', 32, 1_024, 16_384, 16_385),
                bindings => _numeric_axis('plan', 'bindings', 2_048, 32_768, 65_536, 65_537),
                execution_types => _numeric_axis('plan', 'execution_types', 512, 8_192, 65_536, 65_537),
                source_map_records => _numeric_axis('plan', 'source_map_records', 8_192, 262_144, 1_000_000, 1_000_001),
                random_attempts => _numeric_axis('plan', 'random_attempts', 8_192, 262_144, 1_000_000, 1_000_001),
                serialized_plan_bytes => _byte_axis('plan', 'serialized_plan_bytes', 16_777_216),
            },
        ),
        checking_state_v1 => _family(
            'plan', 'generated_vial_hial_route_v1', [qw(construct semantic bridge plan failure)], {
                model_instances => _numeric_axis('plan', 'model_instances', 32, 1_024, 4_096, 4_097),
                scalar_model_state_cells => _numeric_axis('plan', 'scalar_model_state_cells', 512, 32_768, 65_536, 65_537),
                scoreboard_instances => _numeric_axis('plan', 'scoreboard_instances', 32, 1_024, 4_096, 4_097),
                scoreboard_capacity => _numeric_axis('plan', 'scoreboard_capacity', 4_096, 262_144, 1_000_000, 1_000_001),
                coverpoints => _numeric_axis('plan', 'coverpoints', 256, 8_192, 65_536, 65_537),
                bins_and_cross_tuples => _numeric_axis('plan', 'bins_and_cross_tuples', 4_096, 262_144, 1_000_000, 1_000_001),
                faults => _numeric_axis('plan', 'faults', 32, 1_024, 4_096, 4_097),
                random_occurrences => _numeric_axis('plan', 'random_occurrences', 1_024, 32_768, 65_536, 65_537),
            },
        ),
        backend_emission_v1 => _family(
            'emit', 'proved_execution_ir_v1', [qw(construct semantic bridge plan emit failure)], {
                artifact_graph => _profile_axis('emit'),
            },
        ),
        runtime_stream_v1 => _family(
            'run', 'qualified_backend_v1', [qw(construct semantic bridge plan emit compile run failure)], {
                runtime_trace_records => {
                    expected_stage => 'run',
                    levels => {
                        reference_v1 => {anchor_profile => 'checked_ahb_reference_v1'},
                        gate_candidate_v1 => {semantic_trace_records => 10_000},
                        qualification_candidate_v1 => {semantic_trace_records => 100_000},
                        limit_v1 => {
                            structural_trace_records => 8_000_002,
                            structural_trace_bytes => 67_108_864,
                            earliest_cap_authoritative => JSON::PP::true,
                        },
                        over_limit_v1 => {
                            structural_trace_records => 8_000_003,
                            structural_trace_bytes => 67_108_865,
                            earliest_cap_authoritative => JSON::PP::true,
                        },
                    },
                },
            },
        ),
    };
    my $balanced = _family(
        'plan', 'generated_vial_hial_route_v1', [qw(construct semantic bridge plan emit failure)], {
            interaction_profile => {
                expected_stage => 'plan',
                levels => {
                    gate_candidate_v1 => {
                        selected_units => 1,
                        selected_domains => 1,
                        endpoints => 128,
                        transactions => 16,
                        events => 128,
                        probes => 32,
                        scenarios => 32,
                        operations_total => 1_024,
                        fibers_total => 128,
                        simultaneously_live_fibers => 32,
                        bindings => 2_048,
                        execution_types => 512,
                        model_instances => 32,
                        scalar_model_state_cells => 512,
                        scoreboard_instances => 32,
                        scoreboard_capacity => 4_096,
                        coverpoints => 256,
                        coverage_bins => 4_096,
                        faults => 32,
                        random_occurrences => 1_024,
                    },
                },
            },
        },
    );
    return {
        schema => 'fsmgen.vial_architecture_scale_catalog.v1',
        schema_version => 1,
        generator_revision => $GENERATOR_REVISION,
        seed => $SEED,
        random_algorithm => FSM::VIAL::ExecutionRandom->algorithm_id,
        stable_name_format => 'vial_scale__<family>__<axis>__<8-digit-ordinal>',
        staging_root => $STAGING_BASE,
        input_limits => {
            individual_bytes => $MAX_SINGLE_INPUT_BYTES,
            combined_bytes => $MAX_INPUT_BYTES,
        },
        levels => [@LEVELS],
        anchor_identity => $anchor,
        families => $families,
        balanced_profile => $balanced,
        backend_profiles => $backend_profiles,
        explicit_nonclaims => [@NONCLAIMS],
    };
}

sub _family($stage, $source_route, $oracles, $axes) {
    return {
        expected_stage => $stage,
        source_route => $source_route,
        applicable_oracles => $oracles,
        axes => $axes,
    };
}

sub _numeric_axis($stage, $axis, $gate, $qualification, $limit, $over) {
    return {
        expected_stage => $stage,
        levels => {
            reference_v1 => {anchor_profile => 'checked_ahb_reference_v1'},
            gate_candidate_v1 => {$axis => $gate},
            qualification_candidate_v1 => {$axis => $qualification},
            limit_v1 => {$axis => $limit},
            over_limit_v1 => {$axis => $over},
        },
    };
}

sub _byte_axis($stage, $axis, $limit) {
    my $gate = int($limit / 16);
    my $qualification = int($limit / 4);
    return {
        expected_stage => $stage,
        levels => {
            reference_v1 => {anchor_profile => 'checked_ahb_reference_v1'},
            gate_candidate_v1 => {
                $axis => $gate,
                derivation => 'floor_declared_cap_div_16',
            },
            qualification_candidate_v1 => {
                $axis => $qualification,
                derivation => 'floor_declared_cap_div_4',
            },
            limit_v1 => {
                $axis => $limit,
                construction_rule => 'exact_valid_referenced_source_bytes',
            },
            over_limit_v1 => {
                minimum_bytes => $limit + 1,
                declared_cap_bytes => $limit,
                construction_rule => 'first_complete_valid_record_over_boundary',
            },
        },
    };
}

sub _profile_axis($stage) {
    return {
        expected_stage => $stage,
        levels => {
            reference_v1 => {anchor_profile => 'checked_ahb_reference_v1'},
            gate_candidate_v1 => {upstream_workload_level => 'gate_candidate_v1'},
            qualification_candidate_v1 => {upstream_workload_level => 'qualification_candidate_v1'},
            limit_v1 => {structural_boundary => 'selected_backend_authority'},
            over_limit_v1 => {structural_boundary => 'first_representable_excess'},
        },
    };
}

sub _expected_outcome($level) {
    return 'accepted_reference' if $level eq 'reference_v1';
    return 'unqualified_candidate' if $level =~ /candidate_v1\z/;
    return 'limit_conformance_only' if $level eq 'limit_v1';
    return 'expected_earliest_authoritative_rejection';
}

sub _construction_result($value) {
    _assert_exact_result_keys($value, \@CONSTRUCTION_KEYS, 'construction result');
    return _clone($value);
}

sub _staging_result($value) {
    _assert_exact_result_keys($value, \@STAGING_KEYS, 'staging result');
    return _clone($value);
}

sub _construction_failure($code, $message, $path) {
    return _construction_result({
        ok => JSON::PP::false,
        status => 'error',
        schema => $CONSTRUCTION_SCHEMA,
        schema_version => 1,
        workload_identity => undef,
        specification => undef,
        input_identities => [],
        inputs => [],
        staging_identity => undef,
        diagnostics => [_diagnostic($code, $message, $path)],
    });
}

sub _staging_failure($code, $message, $path) {
    return _staging_result({
        ok => JSON::PP::false,
        status => 'error',
        schema => $STAGING_SCHEMA,
        schema_version => 1,
        workload_identity => undef,
        staging_identity => undef,
        same_volume => JSON::PP::false,
        removed => JSON::PP::false,
        diagnostics => [_diagnostic($code, $message, $path)],
    });
}

sub _diagnostic($code, $message, $path) {
    return {
        code => $code,
        severity => 'error',
        message => $message,
        path => $path,
    };
}

sub _assert_exact_result_keys($value, $keys, $label) {
    my %expected = map { $_ => 1 } @$keys;
    confess "$label has unknown key(s)\n" if grep { !$expected{$_} } keys %$value;
    confess "$label is missing key(s)\n" if grep { !exists($value->{$_}) } @$keys;
}

sub _require_exact_keys($value, $keys, $label) {
    my %expected = map { $_ => 1 } @$keys;
    my @unknown = sort grep { !$expected{$_} } keys %$value;
    my @missing = grep { !exists($value->{$_}) } @$keys;
    _throw('VIAL_SCALE_INVOCATION_ERROR', "$label has unknown key '$unknown[0]'", '/') if @unknown;
    _throw('VIAL_SCALE_INVOCATION_ERROR', "$label is missing key '$missing[0]'", '/') if @missing;
}

sub _confess_exact_keys($value, $keys, $label) {
    my %expected = map { $_ => 1 } @$keys;
    my @unknown = sort grep { !$expected{$_} } keys %$value;
    my @missing = grep { !exists($value->{$_}) } @$keys;
    confess "$label has unknown key '$unknown[0]'\n" if @unknown;
    confess "$label is missing key '$missing[0]'\n" if @missing;
}

sub _throw($code, $message, $path) {
    die bless {code => $code, message => $message, path => $path},
        __PACKAGE__ . '::Failure';
}

sub _exact_invocant($class, $method) {
    confess __PACKAGE__ . "->$method requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
}

sub _safe_token($value) {
    return defined($value) && !ref($value)
        && $value =~ /\A[a-z][a-z0-9_]*(?:\.[a-z0-9_]+)*\z/;
}

sub _safe_relative_path($value) {
    return 0 unless defined($value) && !ref($value) && length($value);
    return 0 if $value =~ m{(?:\A/|\A~|\A[A-Za-z]:|://|\\|\x00)};
    my @parts = split m{/}, $value, -1;
    return 0 if grep { $_ eq '' || $_ eq '.' || $_ eq '..' } @parts;
    return 1;
}

sub _canonical_json($value) {
    return JSON::PP->new->canonical(1)->allow_nonref(1)->encode($value);
}

sub _sanitize_exception($error) {
    my $message = defined($error) ? "$error" : 'unknown architecture-scale failure';
    $message =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*\z//s;
    $message =~ s{(?:[A-Za-z]:)?[/\\][^\s:]+[/\\][^\s:]+}{<host-path>}g;
    $message =~ s/[\r\n]+/ /g;
    $message =~ s/\s+/ /g;
    $message =~ s/\A\s+|\s+\z//g;
    return length($message) ? $message : 'unknown architecture-scale failure';
}

sub _clone($value) {
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    return {map { $_ => _clone($value->{$_}) } sort keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    confess 'architecture-scale projection contains an unsupported reference' if ref($value);
    return $value;
}

package FSM::VIAL::ArchitectureScaleWorkload::Failure;

use overload '""' => sub { $_[0]{message} // 'VIAL architecture-scale failure' }, fallback => 1;

1;
