package FSM::HIAL::VIALBridge::Builder;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use Math::BigInt;
use Scalar::Util qw(blessed);
use bytes ();
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::HIAL::VIALBridge::Manifest;
use FSM::HIAL::VIALBridge::Report;
use FSM::Support::HIALVIALBridgeContract qw(build_hial_vial_bridge_contract);

my $SCHEMA = 'fsmgen.hial_vial_bridge_manifest.v1';
my $PROFILE = 'core_single_unit_v1';
my $ARCHITECTURE_SCALE_CAPABILITY =
    'hial_vial.bridge_qualification.architecture_scale_v1';

my %LIMIT = %{build_hial_vial_bridge_contract()->{limits}};

my @AHB_FACT_ORDER = qw(
    supported_transfer okay_response error_response error_completion
);
my %AHB_FACT_VALUE = (
    supported_transfer => "2'b10",
    okay_response => "1'b0",
    error_response => "1'b1",
    error_completion => 'two-cycle',
);
my @AHB_RESIDUE_ORDER = qw(
    ahb_subordinate_profile_alias_deferred
    ahb_interconnect_generation_deferred
    ahb_subordinate_optional_signal_residue
    ahb_burst_seq_support_deferred
    ahb_verification_output_deferred
);
my %AHB_RESIDUE = map {
    $_ => {
        detail => {
            ahb_subordinate_profile_alias_deferred => 'The bounded generic AHB subordinate profile-alias exposure remains separately tracked.',
            ahb_interconnect_generation_deferred => 'Broader AHB interconnect, decode, arbitration, and composition remain separately tracked.',
            ahb_subordinate_optional_signal_residue => 'Optional and property-gated AHB subordinate signals remain separately tracked.',
            ahb_burst_seq_support_deferred => 'Broader AHB burst and SEQ behavior remains separately tracked.',
            ahb_verification_output_deferred => 'Target verification output and backend runtime remain separately tracked.',
        }->{$_},
        owner => undef,
        required_capability => undef,
    }
} @AHB_RESIDUE_ORDER;

sub build_ial0($class, @args) {
    return _invoke($class, 'build_ial0', 'IAL0', @args);
}

sub build_ial1($class, @args) {
    return _invoke($class, 'build_ial1', 'IAL1', @args);
}

sub build_ial2_via_ial1($class, @args) {
    return _invoke($class, 'build_ial2_via_ial1', 'IAL2', @args);
}

sub _invoke($class, $method, $layer, @args) {
    return _failure_result(
        code => 'HIAL_VIAL_BRIDGE_INVOCATION_ERROR',
        category => 'invocation',
        message => "$method must be called with the FSM::HIAL::VIALBridge::Builder class invocant",
        path => '/',
    ) unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return _failure_result(
        code => 'HIAL_VIAL_BRIDGE_INVOCATION_ERROR',
        category => 'invocation',
        message => "$method expects exactly one validated route hash reference",
        path => '/',
    ) unless @args == 1 && ref($args[0]) eq 'HASH';

    my $result = eval { _build_route($layer, $args[0]) };
    return $result if $result;
    my $error = $@;
    if (blessed($error) && $error->isa('FSM::HIAL::VIALBridge::Builder::Failure')) {
        return _failure_result(%$error);
    }
    return _failure_result(
        code => 'HIAL_VIAL_BRIDGE_INTERNAL_ERROR',
        category => 'internal',
        message => 'internal bridge construction failure',
        path => '/',
    );
}

sub _build_route($layer, $raw) {
    for my $forbidden (qw(ppif_ast ppif_report)) {
        _throw(
            'HIAL_VIAL_BRIDGE_ROUTE_ERROR',
            'route',
            "$forbidden cannot bypass the generated and reparsed IAL1 review route",
            "/$forbidden",
        ) if exists $raw->{$forbidden};
    }
    my %allowed = map { $_ => 1 } qw(profile authored_source backend_names);
    $allowed{hdl_result} = 1 if $layer eq 'IAL0';
    if ($layer eq 'IAL1') {
        $allowed{actor} = 1;
        $allowed{schedule_report} = 1;
        $allowed{generated_ial0} = 1;
    }
    if ($layer eq 'IAL2') {
        $allowed{generated_ial1} = 1;
        $allowed{generated_ial0} = 1;
    }
    _reject_unknown_keys($raw, \%allowed, '/');
    _throw('HIAL_VIAL_BRIDGE_INVOCATION_ERROR', 'invocation', 'profile is required', '/profile')
        unless exists $raw->{profile};
    _throw('HIAL_VIAL_BRIDGE_CAPABILITY_ERROR', 'capability', "unsupported bridge profile '$raw->{profile}'", '/profile')
        unless defined($raw->{profile}) && !ref($raw->{profile}) && $raw->{profile} eq $PROFILE;

    my $authored = _source_input($raw->{authored_source}, '/authored_source', 1);
    my $backend_names = _backend_names_input($raw->{backend_names});

    my ($actor, $schedule_report, @source_specs);
    if ($layer eq 'IAL0') {
        _throw('HIAL_VIAL_BRIDGE_INVOCATION_ERROR', 'invocation', 'hdl_result is required for the IAL0 route', '/hdl_result')
            unless exists $raw->{hdl_result};
        $actor = _project_ial0_hdl_result($raw->{hdl_result});
        @source_specs = ({ layer => 'IAL0', role => 'authored', source_id => 'source/authored', input => $authored });
    } elsif ($layer eq 'IAL1') {
        _throw('HIAL_VIAL_BRIDGE_INVOCATION_ERROR', 'invocation', 'actor, schedule_report, and generated_ial0 are required for the IAL1 route', '/')
            unless exists($raw->{actor}) && exists($raw->{schedule_report}) && exists($raw->{generated_ial0});
        $actor = _clone_plain($raw->{actor}, '/actor');
        $schedule_report = _clone_plain($raw->{schedule_report}, '/schedule_report');
        my $ial0 = _source_input($raw->{generated_ial0}, '/generated_ial0', 0);
        @source_specs = (
            { layer => 'IAL1', role => 'authored', source_id => 'source/authored', input => $authored },
            { layer => 'IAL0', role => 'generated_review', source_id => 'source/generated_ial0', input => $ial0 },
        );
    } else {
        _throw('HIAL_VIAL_BRIDGE_INVOCATION_ERROR', 'invocation', 'generated_ial1 and generated_ial0 are required for the IAL2-via-IAL1 route', '/')
            unless exists($raw->{generated_ial1}) && exists($raw->{generated_ial0});
        my $ial1 = _generated_ial1_input($raw->{generated_ial1});
        my $ial0 = _source_input($raw->{generated_ial0}, '/generated_ial0', 0);
        $actor = $ial1->{actor};
        $schedule_report = $ial1->{schedule_report};
        @source_specs = (
            { layer => 'IAL2', role => 'authored', source_id => 'source/authored', input => $authored },
            { layer => 'IAL1', role => 'generated_review', source_id => 'source/generated_ial1', input => $ial1->{source} },
            { layer => 'IAL0', role => 'generated_review', source_id => 'source/generated_ial0', input => $ial0 },
        );
    }

    _validate_actor_and_report($actor, $schedule_report, $layer);
    my ($sources, $artifacts, $route) = _build_review_route($layer, \@source_specs);
    my $model = _build_semantic_model($actor, $layer, $backend_names, $sources, $artifacts);

    my $unit_id = $model->{units}[0]{unit_id};
    my $authored_identity = $authored->{repository_path};
    my $manifest_hash = sha256_hex(join("\0",
        $SCHEMA,
        $layer,
        $authored_identity,
        $authored->{content_sha256},
        $unit_id,
    ));

    my %manifest = (
        schema => $SCHEMA,
        schema_version => 1,
        profile => $PROFILE,
        manifest_id => "bridge/$manifest_hash",
        producer => {
            name => 'FSMGen',
            contract_source => 'FSM::HIAL::VIALBridge::Manifest',
            reference_implementation => 'perl',
        },
        entry_source_id => 'source/authored',
        sources => $sources,
        review_route => $route,
        review_artifacts => $artifacts,
        (map { $_ => $model->{$_} } qw(
            units configurations types endpoints domains transactions events
            protocols observations probes backend_bindings required_capabilities
            unsupported_residue
        )),
        source_map => [],
        diagnostics => [],
    );
    $manifest{source_map} = _build_source_map(\%manifest, $layer, $sources, $artifacts);
    _validate_limits(\%manifest);
    _validate_unique_semantic_ids(\%manifest);
    my $encoded = JSON::PP->new->canonical->encode(\%manifest);
    _throw('HIAL_VIAL_BRIDGE_LIMIT_ERROR', 'limit', 'serialized manifest exceeds 16777216 bytes', '/')
    if bytes::length($encoded) > $LIMIT{serialized_manifest_bytes};

    my $object = FSM::HIAL::VIALBridge::Manifest->_from_builder(\%manifest, __PACKAGE__);
    return {
        ok => JSON::PP::true,
        manifest => $object,
        report => FSM::HIAL::VIALBridge::Report->build($object),
        diagnostics => [],
    };
}

sub _source_input($raw, $path, $authored) {
    _throw('HIAL_VIAL_BRIDGE_INVOCATION_ERROR', 'invocation', "$path must be a source hash reference", $path)
        unless ref($raw) eq 'HASH';
    my %allowed = map { $_ => 1 } qw(text repository_path artifact_name content_sha256 byte_length line_count);
    _reject_unknown_keys($raw, \%allowed, $path);
    for my $key (qw(text repository_path artifact_name content_sha256 byte_length line_count)) {
        _throw('HIAL_VIAL_BRIDGE_INVOCATION_ERROR', 'invocation', "$path is missing '$key'", "$path/$key")
            unless exists $raw->{$key};
    }
    _throw('HIAL_VIAL_BRIDGE_ROUTE_ERROR', 'route', "$path text must be a defined scalar", "$path/text")
        if !defined($raw->{text}) || ref($raw->{text});
    _throw('HIAL_VIAL_BRIDGE_ROUTE_ERROR', 'route', "$path artifact_name must be a basename", "$path/artifact_name")
        unless _is_basename($raw->{artifact_name});
    _validate_repository_path($raw->{repository_path}, "$path/repository_path", $authored);
    my $sha = sha256_hex($raw->{text});
    my $bytes = bytes::length($raw->{text});
    my $lines = _line_count($raw->{text});
    _throw('HIAL_VIAL_BRIDGE_ROUTE_ERROR', 'route', "$path content_sha256 does not match exact source bytes", "$path/content_sha256")
        unless defined($raw->{content_sha256}) && !ref($raw->{content_sha256}) && $raw->{content_sha256} eq $sha;
    _throw('HIAL_VIAL_BRIDGE_ROUTE_ERROR', 'route', "$path byte_length does not match exact source bytes", "$path/byte_length")
        unless defined($raw->{byte_length}) && !ref($raw->{byte_length}) && "$raw->{byte_length}" =~ /\A[0-9]+\z/
            && 0 + $raw->{byte_length} == $bytes;
    _throw('HIAL_VIAL_BRIDGE_ROUTE_ERROR', 'route', "$path line_count does not match exact source bytes", "$path/line_count")
        unless defined($raw->{line_count}) && !ref($raw->{line_count}) && "$raw->{line_count}" =~ /\A[0-9]+\z/
            && 0 + $raw->{line_count} == $lines;
    return {
        text => $raw->{text},
        repository_path => $raw->{repository_path},
        artifact_name => $raw->{artifact_name},
        content_sha256 => $sha,
        byte_length => $bytes,
        line_count => $lines,
    };
}

sub _generated_ial1_input($raw) {
    _throw('HIAL_VIAL_BRIDGE_INVOCATION_ERROR', 'invocation', 'generated_ial1 must be a hash reference', '/generated_ial1')
        unless ref($raw) eq 'HASH';
    my %allowed = map { $_ => 1 } qw(source actor schedule_report);
    _reject_unknown_keys($raw, \%allowed, '/generated_ial1');
    for my $key (qw(source actor schedule_report)) {
        _throw('HIAL_VIAL_BRIDGE_INVOCATION_ERROR', 'invocation', "generated_ial1 is missing '$key'", "/generated_ial1/$key")
            unless exists $raw->{$key};
    }
    return {
        source => _source_input($raw->{source}, '/generated_ial1/source', 0),
        actor => _clone_plain($raw->{actor}, '/generated_ial1/actor'),
        schedule_report => _clone_plain($raw->{schedule_report}, '/generated_ial1/schedule_report'),
    };
}

sub _backend_names_input($raw) {
    _throw('HIAL_VIAL_BRIDGE_INVOCATION_ERROR', 'invocation', 'backend_names is required and must be a hash reference', '/backend_names')
        unless ref($raw) eq 'HASH';
    my %allowed_languages = map { $_ => 1 } qw(systemverilog vhdl);
    _reject_unknown_keys($raw, \%allowed_languages, '/backend_names');
    my %out;
    for my $language (qw(systemverilog vhdl)) {
        my $entry = $raw->{$language};
        _throw('HIAL_VIAL_BRIDGE_INVOCATION_ERROR', 'invocation', "backend_names.$language is required", "/backend_names/$language")
            unless ref($entry) eq 'HASH';
        my %allowed = map { $_ => 1 } qw(unit endpoints configurations probes);
        _reject_unknown_keys($entry, \%allowed, "/backend_names/$language");
        for my $key (qw(unit endpoints configurations probes)) {
            _throw('HIAL_VIAL_BRIDGE_INVOCATION_ERROR', 'invocation', "backend_names.$language is missing '$key'", "/backend_names/$language/$key")
                unless exists $entry->{$key};
        }
        _throw('HIAL_VIAL_BRIDGE_ROUTE_ERROR', 'route', "backend_names.$language.unit must be an HDL identifier", "/backend_names/$language/unit")
            unless _is_identifier($entry->{unit});
        my %copy = (unit => $entry->{unit});
        for my $family (qw(endpoints configurations probes)) {
            _throw('HIAL_VIAL_BRIDGE_ROUTE_ERROR', 'route', "backend_names.$language.$family must be a hash reference", "/backend_names/$language/$family")
                unless ref($entry->{$family}) eq 'HASH';
            my %names;
            for my $semantic_name (sort keys %{$entry->{$family}}) {
                my $target = $entry->{$family}{$semantic_name};
                _throw('HIAL_VIAL_BRIDGE_ACCESS_ERROR', 'access', "backend_names.$language.$family target names must be scalar identifiers without hierarchy", "/backend_names/$language/$family/$semantic_name")
                    unless _is_identifier($semantic_name) && _is_identifier($target);
                $names{$semantic_name} = $target;
            }
            $copy{$family} = \%names;
        }
        $out{$language} = \%copy;
    }
    return \%out;
}

sub _project_ial0_hdl_result($result) {
    _throw('HIAL_VIAL_BRIDGE_INVOCATION_ERROR', 'invocation', 'hdl_result must be a validated HDLGenerator result hash reference', '/hdl_result')
        unless ref($result) eq 'HASH';
    my $module_info = $result->{module_info};
    _throw('HIAL_VIAL_BRIDGE_ROUTE_ERROR', 'route', 'hdl_result.module_info is missing', '/hdl_result/module_info')
        unless ref($module_info) eq 'HASH';
    my $name = $module_info->{module_name};
    _throw('HIAL_VIAL_BRIDGE_ROUTE_ERROR', 'route', 'hdl_result module name must be an HDL identifier', '/hdl_result/module_info/module_name')
        unless _is_identifier($name);
    _throw('HIAL_VIAL_BRIDGE_CAPABILITY_ERROR', 'capability', 'IAL0 bridge profile accepts a direct fsm root only', '/hdl_result/module_info/source_root_kind')
        unless ($module_info->{source_root_kind} // '') eq 'fsm';
    my $system = $module_info->{explicit_system_contract};
    _throw('HIAL_VIAL_BRIDGE_ROUTE_ERROR', 'route', 'IAL0 bridge profile requires an explicit clock/reset system contract', '/hdl_result/module_info/explicit_system_contract')
        unless ref($system) eq 'HASH' && _is_identifier($system->{clock}) && _is_identifier($system->{reset});
    _throw('HIAL_VIAL_BRIDGE_ROUTE_ERROR', 'route', 'IAL0 bridge reset kind must be async or sync', '/hdl_result/module_info/explicit_system_contract/reset_kind')
        unless ($system->{reset_kind} // '') =~ /\A(?:async|sync)\z/;
    _throw('HIAL_VIAL_BRIDGE_ROUTE_ERROR', 'route', 'IAL0 bridge reset active level must be zero or one', '/hdl_result/module_info/explicit_system_contract/reset_active_level')
        unless defined($system->{reset_active_level})
            && !ref($system->{reset_active_level})
            && "$system->{reset_active_level}" =~ /\A[01]\z/;
    my @inputs;
    my @outputs;
    my $signals = $module_info->{signals};
    _throw('HIAL_VIAL_BRIDGE_ROUTE_ERROR', 'route', 'hdl_result.module_info.signals must be a hash reference', '/hdl_result/module_info/signals')
        unless ref($signals) eq 'HASH';
    for my $signal_name (sort keys %$signals) {
        my $signal = $signals->{$signal_name};
        next unless blessed($signal)
            && $signal->can('get_attribute')
            && $signal->can('name')
            && $signal->can('signed')
            && $signal->can('width');
        my $role = $signal->get_attribute('signal_role') // '';
        next unless $role eq 'INPUT' || $role eq 'OUTPUT';
        my $entry = {
            name => $signal->name,
            width => 0 + $signal->width,
            signed => $signal->signed ? 1 : 0,
        };
        push @{$role eq 'INPUT' ? \@inputs : \@outputs}, $entry;
    }
    return {
        actor_name => $name,
        clock => $system->{clock},
        reset => {
            name => $system->{reset},
            kind => $system->{reset_kind},
            polarity => $system->{reset_active_level} == 0
                ? 'active_low' : 'active_high',
        },
        clock_domains => undef,
        interface => { inputs => \@inputs, outputs => \@outputs },
        params => [],
        storage => [],
        transactions => [],
        verification_observations => [],
        verification_bridge => undef,
    };
}

sub _validate_actor_and_report($actor, $report, $layer) {
    _throw('HIAL_VIAL_BRIDGE_ROUTE_ERROR', 'route', 'validated actor must be a hash reference', '/actor')
        unless ref($actor) eq 'HASH';
    _throw('HIAL_VIAL_BRIDGE_ROUTE_ERROR', 'route', 'validated actor requires scalar actor_name, clock, explicit reset, and interface', '/actor')
        unless _is_identifier($actor->{actor_name}) && _is_identifier($actor->{clock})
            && ref($actor->{reset}) eq 'HASH' && _is_identifier($actor->{reset}{name})
            && ref($actor->{interface}) eq 'HASH';
    _throw('HIAL_VIAL_BRIDGE_ROUTE_ERROR', 'route', 'validated actor reset kind and polarity must be explicit supported values', '/actor/reset')
        unless ($actor->{reset}{kind} // '') =~ /\A(?:async|sync)\z/
            && ($actor->{reset}{polarity} // '') =~ /\A(?:active_low|active_high)\z/;
    _throw('HIAL_VIAL_BRIDGE_CAPABILITY_ERROR', 'capability', 'core_single_unit_v1 rejects multi-domain actors', '/actor/clock_domains')
        if ref($actor->{clock_domains}) eq 'HASH';
    _throw('HIAL_VIAL_BRIDGE_CAPABILITY_ERROR', 'capability', 'core_single_unit_v1 rejects actor-network composition and native hierarchy', '/actor/actor_network')
        if ref($actor->{actor_network}) eq 'HASH';
    _throw('HIAL_VIAL_BRIDGE_CAPABILITY_ERROR', 'capability', 'core_single_unit_v1 rejects authored named, enum, record, and list type declarations', '/actor/type_declarations')
        if @{$actor->{type_declarations} || []} || @{$actor->{enum_declarations} || []};
    return 1 if $layer eq 'IAL0';
    _throw('HIAL_VIAL_BRIDGE_ROUTE_ERROR', 'route', 'schedule_report must be a decoded hash reference', '/schedule_report')
        unless ref($report) eq 'HASH';
    _throw('HIAL_VIAL_BRIDGE_ROUTE_ERROR', 'route', 'schedule_report source actor does not match validated actor', '/schedule_report/source')
        unless ($report->{source} // '') eq "$actor->{actor_name}.isf";
    my $actor_bridge = $actor->{verification_bridge};
    my $report_bridge = $report->{verification_bridge};
    my $json = JSON::PP->new->canonical;
    _throw('HIAL_VIAL_BRIDGE_ROUTE_ERROR', 'route', 'schedule_report verification_bridge projection does not match the reparsed actor', '/schedule_report/verification_bridge')
        unless $json->encode($actor_bridge) eq $json->encode($report_bridge);
    if ($layer eq 'IAL2') {
        _throw('HIAL_VIAL_BRIDGE_ANNOTATION_ERROR', 'annotation', 'IAL2 bridge route requires generated and reparsed IAL1 verification-bridge metadata', '/actor/verification_bridge')
            unless ref($actor_bridge) eq 'HASH';
        _throw('HIAL_VIAL_BRIDGE_ANNOTATION_ERROR', 'annotation', 'architecture-scale qualification is accepted only through the direct IAL1 route', '/actor/verification_bridge/protocol')
            if _is_architecture_scale_protocol($actor_bridge);
    }
}

sub _build_review_route($layer, $specs) {
    my (@sources, @artifacts, @stages);
    for my $index (0 .. $#$specs) {
        my $spec = $specs->[$index];
        my $input = $spec->{input};
        my $source = {
            source_id => $spec->{source_id},
            layer => $spec->{layer},
            kind => lc($spec->{layer}),
            role => $spec->{role},
            repository_path => $input->{repository_path},
            artifact_name => $input->{artifact_name},
            content_sha256 => $input->{content_sha256},
            byte_length => $input->{byte_length},
            line_count => $input->{line_count},
        };
        push @sources, $source;
        my $artifact_id = $index == 0 ? 'artifact/authored' : 'artifact/generated_' . lc($spec->{layer});
        push @artifacts, {
            artifact_id => $artifact_id,
            layer => $spec->{layer},
            format => lc($spec->{layer}) eq 'ial0' ? 'fsm' : lc($spec->{layer}) eq 'ial1' ? 'isf' : 'ppif',
            artifact_name => $input->{artifact_name},
            repository_path => $input->{repository_path},
            source_id => $spec->{source_id},
            content_sha256 => $input->{content_sha256},
            generated => $spec->{role} eq 'generated_review' ? JSON::PP::true : JSON::PP::false,
            entry => $spec->{layer} eq 'IAL0' ? JSON::PP::true : JSON::PP::false,
        };
        push @stages, {
            layer => $spec->{layer},
            source_id => $spec->{source_id},
            review_artifact_ids => [$artifact_id],
        };
    }
    return (
        \@sources,
        \@artifacts,
        {
            authored_layer => $layer,
            direct_ial2_to_verification => JSON::PP::false,
            stages => \@stages,
        },
    );
}

sub _build_semantic_model($actor, $layer, $backend_names, $sources, $artifacts) {
    my $unit_name = $actor->{actor_name};
    my $unit_id = "unit/$unit_name";
    my $bridge = ref($actor->{verification_bridge}) eq 'HASH' ? $actor->{verification_bridge} : undef;
    my $bridge_kind = $bridge && _is_architecture_scale_protocol($bridge)
        ? 'architecture_scale' : $bridge ? 'ahb' : 'plain';
    my $domain_name = $bridge ? $bridge->{domain} : 'default';
    my $domain_id = "domain/$domain_name";
    my (%types_by_key, @types, @endpoints);
    my $logic1 = _ensure_logic_type(\%types_by_key, \@types, 1, 0);

    my %protocol_role = $bridge_kind eq 'ahb' ? _ahb_endpoint_roles($bridge) : ();
    my @port_specs = (
        { name => $actor->{clock}, direction => 'input', width => 1, signed => 0, role => 'clock' },
        { name => $actor->{reset}{name}, direction => 'input', width => 1, signed => 0, role => 'reset' },
    );
    for my $direction (qw(inputs outputs)) {
        for my $port (@{($actor->{interface} || {})->{$direction} || []}) {
            _throw('HIAL_VIAL_BRIDGE_TYPE_ERROR', 'type', "interface endpoint '$port->{name}' requires a resolved positive scalar width", "/actor/interface/$direction")
                unless _is_identifier($port->{name}) && defined($port->{width}) && !ref($port->{width})
                    && "$port->{width}" =~ /\A[1-9][0-9]*\z/;
            push @port_specs, {
                name => $port->{name},
                direction => $direction eq 'inputs' ? 'input' : 'output',
                width => 0 + $port->{width},
                signed => $port->{signed} ? 1 : 0,
                role => $protocol_role{$port->{name}} // 'data',
            };
        }
    }
    my %seen_endpoint;
    for my $port (@port_specs) {
        _throw('HIAL_VIAL_BRIDGE_DUPLICATE_ID', 'identity', "duplicate endpoint name '$port->{name}'", "/endpoints")
            if $seen_endpoint{$port->{name}}++;
        my $type_id = $port->{width} == 1 && !$port->{signed}
            ? $logic1 : _ensure_logic_type(\%types_by_key, \@types, $port->{width}, $port->{signed});
        push @endpoints, {
            endpoint_id => "endpoint/$port->{name}",
            unit_id => $unit_id,
            name => $port->{name},
            direction => $port->{direction},
            type_id => $type_id,
            role => $port->{role},
            access => 'public_port',
            domain_id => $domain_id,
            backend_binding_ids => [],
        };
    }
    @endpoints = sort { $a->{endpoint_id} cmp $b->{endpoint_id} } @endpoints;
    my %endpoint_by_name = map { $_->{name} => $_ } @endpoints;

    my @configurations = _build_configurations(
        $actor, $unit_id, \%types_by_key, \@types, $bridge_kind,
    );
    my @observations = _build_observations($actor, $unit_id, $domain_id, \%endpoint_by_name);
    my (@transactions, @events, @protocols, @probes, @residue);
    if ($bridge) {
        if ($bridge_kind eq 'architecture_scale') {
            _validate_architecture_scale_bridge(
                $bridge, \%endpoint_by_name, $actor, $layer,
            );
        }
        else {
            _validate_ahb_bridge($bridge, \%endpoint_by_name, $actor);
        }
        my $semantics = _build_bridge_semantics(
            $bridge, $actor, $unit_id, $domain_id, \%endpoint_by_name,
            \%types_by_key, \@types, $layer, $bridge_kind,
        );
        @transactions = @{$semantics->{transactions}};
        @events = @{$semantics->{events}};
        @protocols = @{$semantics->{protocols}};
        @probes = @{$semantics->{probes}};
        @residue = @{$semantics->{unsupported_residue}};
        if ($bridge_kind eq 'architecture_scale') {
            my $plain = _build_plain_transactions(
                $actor, $unit_id, \%endpoint_by_name, \%types_by_key, \@types,
            );
            push @transactions, @{$plain->{transactions}};
            push @events, @{$plain->{events}};
        }
    } else {
        my $semantics = _build_plain_transactions(
            $actor, $unit_id, \%endpoint_by_name, \%types_by_key, \@types,
        );
        @transactions = @{$semantics->{transactions}};
        @events = @{$semantics->{events}};
    }

    my @bindings = _build_backend_bindings(
        $backend_names, $unit_id, $unit_name, \@endpoints,
        \@configurations, \@probes,
    );
    my %binding_by_semantic;
    push @{$binding_by_semantic{$_->{semantic_id}}}, $_->{binding_id} for @bindings;
    $_->{backend_binding_ids} = [sort @{$binding_by_semantic{$_->{endpoint_id}} || []}] for @endpoints;
    $_->{backend_binding_ids} = [sort @{$binding_by_semantic{$_->{configuration_id}} || []}] for @configurations;
    $_->{backend_binding_ids} = [sort @{$binding_by_semantic{$_->{probe_id}} || []}] for @probes;

    my @capabilities = (
        'hial_vial.bridge_manifest.v1',
        'hial_vial.bridge_profile.core_single_unit_v1',
        $layer eq 'IAL0' ? 'hial_vial.bridge_source.ial0'
            : $layer eq 'IAL1' ? 'hial_vial.bridge_source.ial1'
            : 'hial_vial.bridge_source.ial2_via_generated_ial1',
        (@observations ? 'hial_vial.bridge_observation.passive_monitor' : ()),
        (@protocols ? ($bridge_kind eq 'architecture_scale'
            ? $ARCHITECTURE_SCALE_CAPABILITY
            : 'hial_vial.bridge_protocol.ahb_subordinate_v1') : ()),
        (@probes ? 'hial_vial.bridge_probe.equivalent_adapter_required' : ()),
    );

    my @unit_binding_ids = sort @{$binding_by_semantic{$unit_id} || []};
    my $unit = {
        unit_id => $unit_id,
        name => $unit_name,
        parent_unit_id => undef,
        instance_name => undef,
        source_layer => $layer,
        configuration_ids => [sort map { $_->{configuration_id} } @configurations],
        endpoint_ids => [sort map { $_->{endpoint_id} } @endpoints],
        domain_ids => [$domain_id],
        transaction_ids => [sort map { $_->{transaction_id} } @transactions],
        protocol_ids => [sort map { $_->{protocol_id} } @protocols],
        observation_ids => [sort map { $_->{observation_id} } @observations],
        probe_ids => [sort map { $_->{probe_id} } @probes],
        backend_binding_ids => \@unit_binding_ids,
    };
    my $clock_endpoint = $endpoint_by_name{$actor->{clock}};
    my $reset_endpoint = $endpoint_by_name{$actor->{reset}{name}};
    my $domain = {
        domain_id => $domain_id,
        unit_id => $unit_id,
        name => $domain_name,
        clock_endpoint_id => $clock_endpoint->{endpoint_id},
        active_edge => 'rising',
        reset_endpoint_id => $reset_endpoint->{endpoint_id},
        reset_kind => $actor->{reset}{kind} // 'sync',
        reset_polarity => $actor->{reset}{polarity} // 'active_high',
    };

    return {
        units => [$unit],
        configurations => [sort { $a->{configuration_id} cmp $b->{configuration_id} } @configurations],
        types => [sort { $a->{type_id} cmp $b->{type_id} } @types],
        endpoints => \@endpoints,
        domains => [$domain],
        transactions => [sort { $a->{transaction_id} cmp $b->{transaction_id} } @transactions],
        events => [sort { $a->{event_id} cmp $b->{event_id} } @events],
        protocols => [sort { $a->{protocol_id} cmp $b->{protocol_id} } @protocols],
        observations => [sort { $a->{observation_id} cmp $b->{observation_id} } @observations],
        probes => [sort { $a->{probe_id} cmp $b->{probe_id} } @probes],
        backend_bindings => \@bindings,
        required_capabilities => [sort @capabilities],
        unsupported_residue => \@residue,
    };
}

sub _ensure_logic_type($by_key, $types, $width, $signed) {
    _throw('HIAL_VIAL_BRIDGE_TYPE_ERROR', 'type', 'logic width must be a positive integer', '/types')
        unless defined($width) && !ref($width) && "$width" =~ /\A[1-9][0-9]*\z/;
    my $key = ($signed ? 's' : 'u') . (0 + $width);
    return $by_key->{$key} if $by_key->{$key};
    my $name = 'logic_' . $key;
    my $id = "type/$name";
    push @$types, {
        type_id => $id,
        name => $name,
        kind => 'logic',
        state_domain => 'four_state',
        signed => $signed ? JSON::PP::true : JSON::PP::false,
        width => 0 + $width,
        enum_members => [],
        fields => [],
        element_type_id => undef,
        length => undef,
    };
    $by_key->{$key} = $id;
    return $id;
}

sub _build_configurations($actor, $unit_id, $types_by_key, $types, $bridge_kind = 'plain') {
    my @configurations;
    for my $param (@{$actor->{params} || []}) {
        my ($width, $signed) = ($param->{width}, $param->{signed} ? 1 : 0);
        if ($bridge_kind eq 'architecture_scale' && !defined $width) {
            ($width, $signed) = _architecture_scale_parameter_type($param);
        }
        _throw('HIAL_VIAL_BRIDGE_TYPE_ERROR', 'type', "configuration '$param->{name}' requires resolved scalar width and value", '/actor/params')
            unless _is_identifier($param->{name}) && defined($width) && !ref($width)
                && "$width" =~ /\A[1-9][0-9]*\z/ && defined($param->{value}) && !ref($param->{value});
        my $type_id = _ensure_logic_type($types_by_key, $types, $width, $signed);
        push @configurations, {
            configuration_id => "configuration/$param->{name}",
            unit_id => $unit_id,
            name => $param->{name},
            type_id => $type_id,
            value => _normalized_value($type_id, $width, $param->{value}),
            origin => 'parameter',
            backend_binding_ids => [],
        };
    }
    return @configurations;
}

sub _architecture_scale_parameter_type($param) {
    return unless ref($param) eq 'HASH'
        && ($param->{name} // '') =~ /\Aconfiguration_[0-9]{8}\z/;
    my $value = $param->{value};
    return unless defined($value) && !ref($value)
        && $value =~ /\A([1-9][0-9]*)'[hH][0-9a-fA-F_]+\z/;
    return (0 + $1, 0);
}

sub _normalized_value($type_id, $width, $raw) {
    my $value;
    if ($raw =~ /\A[0-9]+\z/) {
        $value = Math::BigInt->new($raw);
    } elsif ($raw =~ /\A([0-9]+)'[hH]([0-9a-fA-F_]+)\z/) {
        _throw('HIAL_VIAL_BRIDGE_TYPE_ERROR', 'type', 'configuration literal width does not match declared width', '/configurations/value')
            unless 0 + $1 == 0 + $width;
        (my $hex = $2) =~ s/_//g;
        $value = Math::BigInt->from_hex("0x$hex");
    } else {
        _throw('HIAL_VIAL_BRIDGE_TYPE_ERROR', 'type', "unsupported configuration scalar value '$raw'", '/configurations/value');
    }
    my $digits = int(($width + 3) / 4);
    my $limit = Math::BigInt->new(2)->bpow($width);
    _throw('HIAL_VIAL_BRIDGE_TYPE_ERROR', 'type', 'configuration value does not fit declared width', '/configurations/value')
        if $value->bcmp($limit) >= 0;
    my $value_hex = $value->as_hex();
    $value_hex =~ s/\A0x//;
    $value_hex = ('0' x ($digits - length($value_hex))) . lc($value_hex);
    return {
        type_id => $type_id,
        width => 0 + $width,
        value_hex => $value_hex,
        known_hex => _all_known_hex($width),
        z_hex => '0' x $digits,
    };
}

sub _all_known_hex($width) {
    my $digits = int(($width + 3) / 4);
    my $top_bits = $width % 4;
    return 'f' x $digits unless $top_bits;
    return sprintf('%x', (2 ** $top_bits) - 1) . ('f' x ($digits - 1));
}

sub _build_observations($actor, $unit_id, $domain_id, $endpoint_by_name) {
    my @out;
    for my $observation (@{$actor->{verification_observations} || []}) {
        _throw('HIAL_VIAL_BRIDGE_CAPABILITY_ERROR', 'capability', "unsupported observation role '$observation->{role}'", '/actor/verification_observations')
            unless ($observation->{role} // '') eq 'passive_monitor';
        my @endpoint_ids;
        for my $signal (@{$observation->{signals} || []}) {
            my $name = ref($signal) eq 'HASH' ? $signal->{name} : undef;
            _throw('HIAL_VIAL_BRIDGE_UNRESOLVED_REFERENCE', 'reference', "observation '$observation->{name}' references unknown endpoint", '/actor/verification_observations')
                unless $name && $endpoint_by_name->{$name};
            push @endpoint_ids, $endpoint_by_name->{$name}{endpoint_id};
        }
        push @out, {
            observation_id => "observation/$observation->{name}",
            unit_id => $unit_id,
            name => $observation->{name},
            role => $observation->{role},
            domain_id => $domain_id,
            endpoint_ids => \@endpoint_ids,
        };
    }
    return @out;
}

sub _build_plain_transactions($actor, $unit_id, $endpoint_by_name, $types_by_key, $types) {
    my (@transactions, @events);
    for my $transaction (@{$actor->{transactions} || []}) {
        my (@fields, @event_ids);
        for my $direction (qw(inputs outputs)) {
            for my $port (@{($transaction->{ports} || {})->{$direction} || []}) {
                my $endpoint = $endpoint_by_name->{$port->{name}};
                next unless $endpoint;
                push @fields, {
                    name => $port->{name},
                    type_id => $endpoint->{type_id},
                    endpoint_id => $endpoint->{endpoint_id},
                    direction => $direction eq 'inputs' ? 'drive' : 'sample',
                    phase_role => 'unspecified',
                };
            }
        }
        for my $clause (@{$transaction->{clauses} || []}) {
            next unless ref($clause) eq 'ARRAY' && @$clause >= 2;
            my $name = $clause->[0];
            next unless $name eq 'on' || $name eq 'complete';
            my $event_id = "event/$transaction->{name}/$name";
            my ($expression, $endpoint_ids, $probe_ids) = _canonical_expression(
                $clause->[1], $endpoint_by_name, {}, $actor,
            );
            push @events, {
                event_id => $event_id,
                transaction_id => "transaction/$transaction->{name}",
                name => $name,
                kind => 'predicate',
                phase => 'sample',
                expression => $expression,
                required_endpoint_ids => $endpoint_ids,
                required_probe_ids => $probe_ids,
            };
            push @event_ids, $event_id;
        }
        push @transactions, {
            transaction_id => "transaction/$transaction->{name}",
            unit_id => $unit_id,
            name => $transaction->{name},
            type_id => undef,
            protocol_id => undef,
            ordering => 'in_order',
            correlation => 'declaration_order',
            fields => \@fields,
            event_ids => \@event_ids,
        };
    }
    return {
        transactions => \@transactions,
        events => \@events,
    };
}

sub _is_architecture_scale_protocol($bridge) {
    return ref($bridge) eq 'HASH'
        && ref($bridge->{protocol}) eq 'HASH'
        && ($bridge->{protocol}{name} // '') eq 'architecture_scale_probe';
}

sub _validate_architecture_scale_bridge($bridge, $endpoint_by_name, $actor, $layer) {
    _throw('HIAL_VIAL_BRIDGE_ANNOTATION_ERROR', 'annotation', 'architecture-scale qualification is accepted only through the direct IAL1 route', '/actor/verification_bridge/protocol')
        unless $layer eq 'IAL1';

    my $protocol = $bridge->{protocol};
    my @facts = @{$protocol->{facts} || []};
    _throw('HIAL_VIAL_BRIDGE_ANNOTATION_ERROR', 'annotation', 'architecture-scale protocol metadata must match the closed qualification-only profile', '/actor/verification_bridge/protocol')
        unless ($protocol->{name} // '') eq 'architecture_scale_probe'
            && ($protocol->{profile} // '') eq 'qualification_only'
            && ($protocol->{revision} // '') eq '1'
            && ($protocol->{role} // '') eq 'verification'
            && @facts == 1
            && ($facts[0]{name} // '') eq 'scale_evidence_only'
            && ($facts[0]{value} // '') eq 'true'
            && ($bridge->{domain} // '') eq 'scale';

    my $transaction = $bridge->{transaction};
    my @fields = @{$transaction->{fields} || []};
    my @events = @{$transaction->{events} || []};
    my $anchor_endpoint = $endpoint_by_name->{scale_input};
    _throw('HIAL_VIAL_BRIDGE_ANNOTATION_ERROR', 'annotation', 'architecture-scale bridge anchor must be one resolved one-bit input field', '/actor/verification_bridge/transaction/fields')
        unless ref($transaction) eq 'HASH'
            && ($transaction->{name} // '') eq 'bridge_anchor'
            && @fields == 1
            && ($fields[0]{name} // '') eq 'anchor'
            && ($fields[0]{direction} // '') eq 'drive'
            && ($fields[0]{phase_role} // '') eq 'unspecified'
            && ref($fields[0]{source}) eq 'HASH'
            && ($fields[0]{source}{kind} // '') eq 'endpoint'
            && ($fields[0]{source}{name} // '') eq 'scale_input'
            && ($fields[0]{source}{direction} // '') eq 'input'
            && ($fields[0]{source}{width} // 0) == 1
            && !$fields[0]{source}{signed}
            && ref($anchor_endpoint) eq 'HASH'
            && ($anchor_endpoint->{direction} // '') eq 'input'
            && ($anchor_endpoint->{type_id} // '') eq _logic_type_id(1, 0);
    _throw('HIAL_VIAL_BRIDGE_ANNOTATION_ERROR', 'annotation', 'architecture-scale bridge requires at least one generated event', '/actor/verification_bridge/transaction/events')
        unless @events;
    for my $index (0 .. $#events) {
        my $event = $events[$index];
        my $expected = sprintf('bridge_event_%08d', $index);
        _throw('HIAL_VIAL_BRIDGE_ANNOTATION_ERROR', 'annotation', 'architecture-scale event family is not closed and ordinal', "/actor/verification_bridge/transaction/events/$index")
            unless ($event->{name} // '') eq $expected
                && ($event->{kind} // '') eq 'predicate'
                && ($event->{phase} // '') eq 'sample'
                && !ref($event->{expression})
                && ($event->{expression} // '') eq 'scale_input';
    }

    my @probes = @{$bridge->{probes} || []};
    _throw('HIAL_VIAL_BRIDGE_ACCESS_ERROR', 'access', 'architecture-scale bridge requires at least one storage-backed probe', '/actor/verification_bridge/probes')
        unless @probes;
    for my $index (0 .. $#probes) {
        my $probe = $probes[$index];
        my $expected = sprintf('probe_%08d', $index);
        my $storage = _actor_storage($actor, $expected);
        _throw('HIAL_VIAL_BRIDGE_ACCESS_ERROR', 'access', 'architecture-scale probe family is not closed, ordinal, read-only, and storage-backed', "/actor/verification_bridge/probes/$index")
            unless ($probe->{name} // '') eq $expected
                && ($probe->{access} // '') eq 'read_only'
                && ref($probe->{source}) eq 'HASH'
                && ($probe->{source}{kind} // '') eq 'storage'
                && ($probe->{source}{name} // '') eq $expected
                && ($probe->{source}{direction} // '') eq 'sample'
                && ($probe->{source}{width} // 0) == 1
                && !$probe->{source}{signed}
                && ref($storage) eq 'HASH'
                && ($storage->{width} // 0) == 1
                && !$storage->{signed};
    }

    for my $index (0 .. $#{$bridge->{residues} || []}) {
        my $expected = sprintf('retained_%08d', $index);
        _throw('HIAL_VIAL_BRIDGE_ANNOTATION_ERROR', 'annotation', 'architecture-scale residue family is not closed and ordinal', "/actor/verification_bridge/residues/$index")
            unless ($bridge->{residues}[$index] // '') eq $expected;
    }
    for my $index (0 .. $#{$actor->{params} || []}) {
        my $expected = sprintf('configuration_%08d', $index);
        my $param = $actor->{params}[$index];
        _throw('HIAL_VIAL_BRIDGE_ANNOTATION_ERROR', 'annotation', 'architecture-scale configuration family is not closed and ordinal', "/actor/params/$index")
            unless ($param->{name} // '') eq $expected
                && defined($param->{value}) && !ref($param->{value})
                && $param->{value} =~ /\A[1-9][0-9]*'[hH][0-9a-fA-F_]+\z/;
    }
    for my $index (0 .. $#{$actor->{transactions} || []}) {
        my $expected = sprintf('transaction_%08d', $index);
        my $transaction = $actor->{transactions}[$index];
        my @clauses = @{$transaction->{clauses} || []};
        _throw('HIAL_VIAL_BRIDGE_ANNOTATION_ERROR', 'annotation', 'architecture-scale ordinary transaction family is not closed and ordinal', "/actor/transactions/$index")
            unless ($transaction->{name} // '') eq $expected
                && @clauses == 1
                && ref($clauses[0]) eq 'ARRAY'
                && @{$clauses[0]} == 2
                && ($clauses[0][0] // '') eq 'on'
                && ($clauses[0][1] // '') eq 'scale_input';
    }
    for my $index (0 .. $#{$actor->{verification_observations} || []}) {
        my $expected = sprintf('observation_%08d', $index);
        my $observation = $actor->{verification_observations}[$index];
        my @signals = @{$observation->{signals} || []};
        _throw('HIAL_VIAL_BRIDGE_ANNOTATION_ERROR', 'annotation', 'architecture-scale observation family is not closed and ordinal', "/actor/verification_observations/$index")
            unless ($observation->{name} // '') eq $expected
                && ($observation->{role} // '') eq 'passive_monitor'
                && @signals == 1
                && ref($signals[0]) eq 'HASH'
                && ($signals[0]{name} // '') eq 'scale_input';
    }

    my @inputs = @{($actor->{interface} || {})->{inputs} || []};
    my @outputs = @{($actor->{interface} || {})->{outputs} || []};
    _throw('HIAL_VIAL_BRIDGE_ANNOTATION_ERROR', 'annotation', 'architecture-scale interface must retain the closed scale output', '/actor/interface/outputs')
        unless @outputs == 1
            && ($outputs[0]{name} // '') eq 'scale_output'
            && ($outputs[0]{width} // 0) == 1;
    for my $index (0 .. $#inputs) {
        my $expected = $index == 0
            ? 'scale_input' : sprintf('endpoint_%08d', $index - 1);
        _throw('HIAL_VIAL_BRIDGE_ANNOTATION_ERROR', 'annotation', 'architecture-scale input endpoint family is not closed and ordinal', "/actor/interface/inputs/$index")
            unless ($inputs[$index]{name} // '') eq $expected
                && ($inputs[$index]{width} // 0) == 1;
    }
}

sub _ahb_endpoint_roles($bridge) {
    my %field_role = (
        address => 'address', transfer => 'transfer', write => 'write',
        size => 'size', data => 'write_data', wait_cycles => 'verification_control',
    );
    my %role;
    for my $field (@{$bridge->{transaction}{fields} || []}) {
        next unless ref($field->{source}) eq 'HASH' && $field->{source}{kind} eq 'endpoint';
        $role{$field->{source}{name}} = $field_role{$field->{name}} // 'data';
    }
    $role{HSEL} = 'select' if exists $role{HADDR};
    $role{HREADY} = 'ready_in' if exists $role{HADDR};
    $role{HREADYOUT} = 'ready_out' if exists $role{HADDR};
    $role{HRESP} = 'response' if exists $role{HADDR};
    $role{HRDATA} = 'read_data' if exists $role{HADDR};
    return %role;
}

sub _validate_ahb_bridge($bridge, $endpoint_by_name, $actor) {
    my $protocol = $bridge->{protocol};
    _throw('HIAL_VIAL_BRIDGE_ANNOTATION_ERROR', 'annotation', 'verification-bridge protocol must select ahb_lite_subordinate/ahb/subordinate', '/actor/verification_bridge/protocol')
        unless ref($protocol) eq 'HASH' && ($protocol->{name} // '') eq 'ahb_lite_subordinate'
            && ($protocol->{profile} // '') eq 'ahb' && ($protocol->{role} // '') eq 'subordinate'
            && ($protocol->{revision} // '') eq 'ARM-AMBA-AHB-IHI0033-C-2021-09';
    my %facts = map { $_->{name} => $_->{value} } @{$protocol->{facts} || []};
    _throw('HIAL_VIAL_BRIDGE_ANNOTATION_ERROR', 'annotation', 'AHB verification-bridge facts must match the selected closed fact family', '/actor/verification_bridge/protocol/facts')
        unless keys(%facts) == @AHB_FACT_ORDER
            && !grep { !exists($facts{$_}) || $facts{$_} ne $AHB_FACT_VALUE{$_} } @AHB_FACT_ORDER;
    my $tx = $bridge->{transaction};
    my @expected_fields = qw(address transfer write size data wait_cycles);
    my @expected_events = qw(requested accepted captured held completed error);
    _throw('HIAL_VIAL_BRIDGE_ANNOTATION_ERROR', 'annotation', 'AHB verification-bridge transaction name or field/event family does not match the selected profile', '/actor/verification_bridge/transaction')
        unless ref($tx) eq 'HASH' && ($tx->{name} // '') eq 'ahb_write'
            && join(',', map { $_->{name} } @{$tx->{fields} || []}) eq join(',', @expected_fields)
            && join(',', map { $_->{name} } @{$tx->{events} || []}) eq join(',', @expected_events);
    my @expected_field_contract = (
        [address => 'HADDR',  'endpoint', drive => 'address_phase', 32],
        [transfer => 'HTRANS', 'endpoint', drive => 'address_phase', 2],
        [write => 'HWRITE', 'endpoint', drive => 'address_phase', 1],
        [size => 'HSIZE', 'endpoint', drive => 'address_phase', 3],
        [data => 'HWDATA', 'endpoint', drive => 'data_phase', 32],
        [wait_cycles => 'wait_cycles', 'endpoint', drive => 'configuration', 4],
    );
    for my $index (0 .. $#expected_field_contract) {
        my ($name, $source_name, $source_kind, $direction, $phase_role, $width) = @{$expected_field_contract[$index]};
        my $field = $tx->{fields}[$index];
        my $source = $field->{source};
        my $endpoint = $endpoint_by_name->{$source_name};
        _throw('HIAL_VIAL_BRIDGE_ANNOTATION_ERROR', 'annotation', "AHB verification-bridge field '$name' does not match the selected source/direction/phase/type contract", "/actor/verification_bridge/transaction/fields/$index")
            unless ref($source) eq 'HASH'
                && ref($endpoint) eq 'HASH'
                && ($field->{name} // '') eq $name
                && ($source->{name} // '') eq $source_name
                && ($source->{kind} // '') eq $source_kind
                && ($source->{direction} // '') eq 'input'
                && ($source->{width} // 0) == $width
                && !$source->{signed}
                && ($endpoint->{direction} // '') eq 'input'
                && (($endpoint->{type_id} // '') eq _logic_type_id($width, 0))
                && ($field->{direction} // '') eq $direction
                && ($field->{phase_role} // '') eq $phase_role;
    }
    my @expected_event_contract = (
        [requested => scenario_start => drive => undef],
        [accepted => predicate => sample => ['&', 'HSEL', 'HREADY', ['==', 'HTRANS', "2'b10"]]],
        [captured => rising => sample => 'ahb_phase_pending_q'],
        [held => predicate => sample => ['==', 'HREADYOUT', '0']],
        [completed => predicate => sample => 'HREADYOUT'],
        [error => predicate => sample => ['==', 'HRESP', "1'b1"]],
    );
    my $canonical_json = JSON::PP->new->canonical;
    for my $index (0 .. $#expected_event_contract) {
        my ($name, $kind, $phase, $expression) = @{$expected_event_contract[$index]};
        my $event = $tx->{events}[$index];
        _throw('HIAL_VIAL_BRIDGE_ANNOTATION_ERROR', 'annotation', "AHB verification-bridge event '$name' does not match the selected kind/phase/expression contract", "/actor/verification_bridge/transaction/events/$index")
            unless ($event->{name} // '') eq $name
                && ($event->{kind} // '') eq $kind
                && ($event->{phase} // '') eq $phase
                && $canonical_json->encode($event->{expression}) eq $canonical_json->encode($expression);
    }
    my @residues = @{$bridge->{residues} || []};
    _throw('HIAL_VIAL_BRIDGE_ANNOTATION_ERROR', 'annotation', 'AHB verification-bridge residue family does not match the selected profile', '/actor/verification_bridge/residues')
        unless join(',', @residues) eq join(',', @AHB_RESIDUE_ORDER);
    _throw('HIAL_VIAL_BRIDGE_ACCESS_ERROR', 'access', 'AHB verification-bridge requires exactly one read-only reg_data_q probe', '/actor/verification_bridge/probes')
        unless @{$bridge->{probes} || []} == 1
            && $bridge->{probes}[0]{name} eq 'reg_data_q'
            && $bridge->{probes}[0]{access} eq 'read_only'
            && ref($bridge->{probes}[0]{source}) eq 'HASH'
            && ($bridge->{probes}[0]{source}{kind} // '') eq 'storage'
            && ($bridge->{probes}[0]{source}{name} // '') eq 'reg_data_q'
            && ($bridge->{probes}[0]{source}{direction} // '') eq 'sample'
            && ($bridge->{probes}[0]{source}{width} // 0) == 32
            && !$bridge->{probes}[0]{source}{signed};
    my $probe_storage = _actor_storage($actor, 'reg_data_q');
    _throw('HIAL_VIAL_BRIDGE_ACCESS_ERROR', 'access', 'AHB reg_data_q probe storage must remain unsigned 32-bit actor storage', '/actor/storage/reg_data_q')
        unless ref($probe_storage) eq 'HASH'
            && ($probe_storage->{width} // 0) == 32
            && !$probe_storage->{signed};
    my $captured_storage = _actor_storage($actor, 'ahb_phase_pending_q');
    _throw('HIAL_VIAL_BRIDGE_TYPE_ERROR', 'type', 'AHB captured event source must remain one-bit actor storage', '/actor/storage/ahb_phase_pending_q')
        unless ref($captured_storage) eq 'HASH' && ($captured_storage->{width} // 0) == 1;
}

sub _logic_type_id($width, $signed) {
    return 'type/logic_' . ($signed ? 's' : 'u') . $width;
}

sub _build_bridge_semantics($bridge, $actor, $unit_id, $domain_id, $endpoint_by_name, $types_by_key, $types, $layer, $bridge_kind = 'ahb') {
    my $protocol_id = "protocol/$bridge->{protocol}{name}";
    my $transaction_id = "transaction/$bridge->{transaction}{name}";
    my (@fields, @events, @event_ids, @probes, @residue);
    my %probe_by_name;
    for my $probe (@{$bridge->{probes}}) {
        my $source = $probe->{source};
        my $type_id = _ensure_logic_type($types_by_key, $types, $source->{width}, $source->{signed});
        my $record = {
            probe_id => "probe/$probe->{name}",
            unit_id => $unit_id,
            name => $probe->{name},
            type_id => $type_id,
            access => 'verification_probe',
            domain_id => $domain_id,
            adapter_requirement => 'equivalent_adapter_required',
            backend_binding_ids => [],
        };
        push @probes, $record;
        $probe_by_name{$probe->{name}} = $record;
    }
    for my $field (@{$bridge->{transaction}{fields}}) {
        my $source = $field->{source};
        my $endpoint = $endpoint_by_name->{$source->{name}};
        _throw('HIAL_VIAL_BRIDGE_UNRESOLVED_REFERENCE', 'reference', "bridge field '$field->{name}' endpoint is unresolved", '/transactions/fields')
            unless $endpoint;
        push @fields, {
            name => $field->{name},
            type_id => $endpoint->{type_id},
            endpoint_id => $endpoint->{endpoint_id},
            direction => $field->{direction},
            phase_role => $field->{phase_role},
        };
    }
    for my $event (@{$bridge->{transaction}{events}}) {
        my $event_id = "event/$bridge->{transaction}{name}/$event->{name}";
        my ($expression, $endpoint_ids, $probe_ids) = defined($event->{expression})
            ? _canonical_expression($event->{expression}, $endpoint_by_name, \%probe_by_name, $actor)
            : (undef, [], []);
        push @events, {
            event_id => $event_id,
            transaction_id => $transaction_id,
            name => $event->{name},
            kind => $event->{kind},
            phase => $event->{phase},
            expression => $expression,
            required_endpoint_ids => $endpoint_ids,
            required_probe_ids => $probe_ids,
        };
        push @event_ids, $event_id;
    }
    my $transaction = {
        transaction_id => $transaction_id,
        unit_id => $unit_id,
        name => $bridge->{transaction}{name},
        type_id => undef,
        protocol_id => $protocol_id,
        ordering => 'in_order',
        correlation => 'single_active',
        fields => \@fields,
        event_ids => \@event_ids,
    };
    my @facts = sort { $a->{name} cmp $b->{name} }
        map { { name => $_->{name}, value => $_->{value} } } @{$bridge->{protocol}{facts}};
    my $protocol = {
        protocol_id => $protocol_id,
        unit_id => $unit_id,
        name => $bridge->{protocol}{name},
        profile => $bridge->{protocol}{profile},
        revision => $bridge->{protocol}{revision},
        role => $bridge->{protocol}{role},
        transaction_ids => [$transaction_id],
        facts => \@facts,
    };
    my $residue_source = $layer eq 'IAL2' ? 'source/generated_ial1' : 'source/authored';
    for my $id (@{$bridge->{residues}}) {
        my $definition = $bridge_kind eq 'architecture_scale'
            ? {
                detail => "Architecture-scale qualification retained record $id.",
                owner => undef,
                required_capability => $ARCHITECTURE_SCALE_CAPABILITY,
            }
            : $AHB_RESIDUE{$id};
        _throw('HIAL_VIAL_BRIDGE_ANNOTATION_ERROR', 'annotation', "unknown bridge residue '$id'", '/actor/verification_bridge/residues')
            unless $definition;
        push @residue, {
            residue_id => "residue/$id",
            source_id => $residue_source,
            detail => $definition->{detail},
            owner => $definition->{owner},
            required_capability => $definition->{required_capability},
        };
    }
    return {
        transactions => [$transaction],
        events => \@events,
        protocols => [$protocol],
        probes => \@probes,
        unsupported_residue => \@residue,
    };
}

sub _canonical_expression($raw, $endpoint_by_name, $probe_by_name, $actor) {
    my (%endpoint_ids, %probe_ids);
    my $build;
    $build = sub {
        my ($value) = @_;
        if (ref($value) eq 'ARRAY') {
            _throw('HIAL_VIAL_BRIDGE_TYPE_ERROR', 'type', 'bridge expression lists must be non-empty', '/events/expression')
                unless @$value && defined($value->[0]) && !ref($value->[0]);
            my @operands = $#$value >= 1
                ? map { $build->($_) } @{$value}[1 .. $#$value]
                : ();
            return {
                kind => 'call',
                operator => $value->[0],
                operands => \@operands,
                value => undef,
                reference_kind => undef,
                semantic_id => undef,
            };
        }
        _throw('HIAL_VIAL_BRIDGE_TYPE_ERROR', 'type', 'bridge expression leaves must be scalar', '/events/expression')
            if !defined($value) || ref($value);
        if ($value =~ /\A(?:true|false|[0-9]+|[0-9]+'[sS]?[bBoOdDhH][0-9a-fA-F_xXzZ?]+)\z/) {
            return {
                kind => 'literal', operator => undef, operands => [], value => "$value",
                reference_kind => undef, semantic_id => undef,
            };
        }
        my ($kind, $semantic_id);
        if (my $endpoint = $endpoint_by_name->{$value}) {
            $kind = 'endpoint';
            $semantic_id = $endpoint->{endpoint_id};
            $endpoint_ids{$semantic_id} = 1;
        } elsif (my $probe = $probe_by_name->{$value}) {
            $kind = 'probe';
            $semantic_id = $probe->{probe_id};
            $probe_ids{$semantic_id} = 1;
        } elsif (_actor_storage($actor, $value)) {
            $kind = 'storage';
            $semantic_id = undef;
        } else {
            _throw('HIAL_VIAL_BRIDGE_UNRESOLVED_REFERENCE', 'reference', "bridge expression reference '$value' is unresolved", '/events/expression');
        }
        return {
            kind => 'reference', operator => undef, operands => [], value => "$value",
            reference_kind => $kind, semantic_id => $semantic_id,
        };
    };
    my $expression = $build->($raw);
    return ($expression, [sort keys %endpoint_ids], [sort keys %probe_ids]);
}

sub _actor_storage($actor, $name) {
    for my $storage (@{$actor->{storage} || []}) {
        return $storage if ($storage->{name} // '') eq $name;
        for my $signal (@{$storage->{signals} || []}) {
            return $signal if ($signal->{name} // '') eq $name;
        }
    }
    return undef;
}

sub _build_backend_bindings($names, $unit_id, $unit_name, $endpoints, $configurations, $probes) {
    my @bindings;
    for my $language (qw(systemverilog vhdl)) {
        my $entry = $names->{$language};
        _throw('HIAL_VIAL_BRIDGE_ROUTE_ERROR', 'route', "backend unit mapping does not match HIAL unit '$unit_name'", "/backend_names/$language/unit")
            unless $entry->{unit} eq $unit_name;
        push @bindings, {
            binding_id => "binding/$language/$unit_id",
            semantic_id => $unit_id,
            target_language => $language,
            target_kind => $language eq 'systemverilog' ? 'module' : 'entity',
            target_name => $entry->{unit},
            status => 'declared',
            required_capabilities => [],
        };
        for my $endpoint (@$endpoints) {
            my $target = $entry->{endpoints}{$endpoint->{name}};
            _throw('HIAL_VIAL_BRIDGE_UNRESOLVED_REFERENCE', 'reference', "missing $language backend endpoint mapping for '$endpoint->{name}'", "/backend_names/$language/endpoints/$endpoint->{name}")
                unless defined $target;
            push @bindings, {
                binding_id => "binding/$language/$endpoint->{endpoint_id}",
                semantic_id => $endpoint->{endpoint_id},
                target_language => $language,
                target_kind => 'port',
                target_name => $target,
                status => 'declared',
                required_capabilities => [],
            };
        }
        for my $configuration (@$configurations) {
            my $target = $entry->{configurations}{$configuration->{name}};
            _throw('HIAL_VIAL_BRIDGE_UNRESOLVED_REFERENCE', 'reference', "missing $language backend configuration mapping for '$configuration->{name}'", "/backend_names/$language/configurations/$configuration->{name}")
                unless defined $target;
            push @bindings, {
                binding_id => "binding/$language/$configuration->{configuration_id}",
                semantic_id => $configuration->{configuration_id},
                target_language => $language,
                target_kind => 'generic',
                target_name => $target,
                status => 'declared',
                required_capabilities => [],
            };
        }
        for my $probe (@$probes) {
            my $target = $entry->{probes}{$probe->{name}};
            _throw('HIAL_VIAL_BRIDGE_UNRESOLVED_REFERENCE', 'reference', "missing $language probe-adapter mapping for '$probe->{name}'", "/backend_names/$language/probes/$probe->{name}")
                unless defined $target;
            push @bindings, {
                binding_id => "binding/$language/$probe->{probe_id}",
                semantic_id => $probe->{probe_id},
                target_language => $language,
                target_kind => 'probe_adapter',
                target_name => $target,
                status => 'adapter_required',
                required_capabilities => ['hial_vial.bridge_probe.equivalent_adapter_required'],
            };
        }
    }
    return sort { $a->{binding_id} cmp $b->{binding_id} } @bindings;
}

sub _build_source_map($manifest, $layer, $sources, $artifacts) {
    my @provenance_sources = $layer eq 'IAL2'
        ? (['source/authored', 'artifact/authored', 'authored'], ['source/generated_ial1', 'artifact/generated_ial1', 'generated_annotation'])
        : (['source/authored', 'artifact/authored', 'authored']);
    my @entries;
    my %id_key = (
        units => 'unit_id', configurations => 'configuration_id', types => 'type_id',
        endpoints => 'endpoint_id', domains => 'domain_id', transactions => 'transaction_id',
        events => 'event_id', protocols => 'protocol_id', observations => 'observation_id',
        probes => 'probe_id', backend_bindings => 'binding_id', unsupported_residue => 'residue_id',
    );
    for my $family (qw(units configurations types endpoints domains transactions events protocols observations probes backend_bindings unsupported_residue)) {
        for my $index (0 .. $#{$manifest->{$family}}) {
            my $record = $manifest->{$family}[$index];
            my $semantic_id = $record->{$id_key{$family}};
            _source_map_walk(
                \@entries, $record, "/$family/$index", '', $semantic_id,
                \@provenance_sources,
            );
        }
    }
    return [sort { $a->{fact_path} cmp $b->{fact_path} } @entries];
}

sub _source_map_walk($entries, $value, $fact_path, $field_path, $semantic_id, $sources) {
    if (ref($value) eq 'HASH') {
        for my $key (sort keys %$value) {
            my $escaped = _pointer_escape($key);
            _source_map_walk($entries, $value->{$key}, "$fact_path/$escaped", "$field_path/$escaped", $semantic_id, $sources);
        }
        return;
    }
    if (ref($value) eq 'ARRAY') {
        push @$entries, _source_map_entry($fact_path, $field_path, $semantic_id, $sources);
        for my $index (0 .. $#$value) {
            _source_map_walk($entries, $value->[$index], "$fact_path/$index", "$field_path/$index", $semantic_id, $sources);
        }
        return;
    }
    push @$entries, _source_map_entry($fact_path, $field_path, $semantic_id, $sources);
}

sub _source_map_entry($fact_path, $field_path, $semantic_id, $sources) {
    my $identity = $field_path =~ /(?:^|\/)(?:[a-z_]*_id|[a-z_]*_ids|name)\z/;
    my @provenance = map {
        {
            source_id => $_->[0],
            review_artifact_id => $_->[1],
            precision => $_->[2] eq 'generated_annotation' ? 'generated' : 'semantic_path',
            semantic_path => "bridge$fact_path",
            start_byte => undef,
            end_byte => undef,
            start_line => undef,
            start_column => undef,
            end_line => undef,
            end_column => undef,
            derivation => $identity ? 'derived_identity' : $_->[2],
        }
    } @$sources;
    return {
        fact_path => $fact_path,
        semantic_id => $semantic_id,
        field_path => length($field_path) ? $field_path : '/',
        provenance => \@provenance,
    };
}

sub _validate_limits($manifest) {
    for my $family (qw(sources review_artifacts units domains configurations types endpoints transactions events protocols observations probes backend_bindings unsupported_residue source_map)) {
        my $count = @{$manifest->{$family} || []};
        _throw('HIAL_VIAL_BRIDGE_LIMIT_ERROR', 'limit', "$family count $count exceeds limit $LIMIT{$family}", "/$family")
            if $count > $LIMIT{$family};
    }
}

sub _validate_unique_semantic_ids($manifest) {
    my %id_key = (
        units => 'unit_id', configurations => 'configuration_id', types => 'type_id',
        endpoints => 'endpoint_id', domains => 'domain_id', transactions => 'transaction_id',
        events => 'event_id', protocols => 'protocol_id', observations => 'observation_id',
        probes => 'probe_id', backend_bindings => 'binding_id', unsupported_residue => 'residue_id',
    );
    my %seen;
    for my $family (sort keys %id_key) {
        for my $record (@{$manifest->{$family} || []}) {
            my $id = $record->{$id_key{$family}};
            _throw('HIAL_VIAL_BRIDGE_DUPLICATE_ID', 'identity', "duplicate semantic id '$id'", "/$family")
                if $seen{$id}++;
        }
    }
}

sub _reject_unknown_keys($hash, $allowed, $path) {
    my @unknown = sort grep { !$allowed->{$_} } keys %$hash;
    _throw('HIAL_VIAL_BRIDGE_INVOCATION_ERROR', 'invocation', 'unknown route key(s): ' . join(', ', @unknown), $path)
        if @unknown;
}

sub _validate_repository_path($path, $field_path, $required) {
    if (!defined $path) {
        _throw('HIAL_VIAL_BRIDGE_ROUTE_ERROR', 'route', "$field_path is required for authored source identity", $field_path)
            if $required;
        return 1;
    }
    _throw('HIAL_VIAL_BRIDGE_ROUTE_ERROR', 'route', "$field_path must be a safe repository-relative POSIX path", $field_path)
        if ref($path) || $path eq '' || $path =~ m{\A/|//|/\z|\\|(?:\A|/)\.\.?/|/\.\.?\z|\A~|[\0\r\n\t]};
    return 1;
}

sub _is_basename($value) {
    return defined($value) && !ref($value) && length($value)
        && $value !~ m{[/\\\0]} && $value ne '.' && $value ne '..';
}

sub _is_identifier($value) {
    return defined($value) && !ref($value) && $value =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
}

sub _line_count($text) {
    return 0 unless length $text;
    my $count = () = $text =~ /\n/g;
    return $count + ($text =~ /\n\z/ ? 0 : 1);
}

sub _pointer_escape($value) {
    $value =~ s/~/~0/g;
    $value =~ s{/}{~1}g;
    return $value;
}

sub _clone_plain($value, $path) {
    return undef unless defined $value;
    if (blessed($value) && $value->isa('JSON::PP::Boolean')) {
        return $value ? JSON::PP::true : JSON::PP::false;
    }
    if (ref($value) eq 'HASH') {
        return { map { $_ => _clone_plain($value->{$_}, "$path/" . _pointer_escape($_)) } sort keys %$value };
    }
    if (ref($value) eq 'ARRAY') {
        return [map { _clone_plain($value->[$_], "$path/$_") } 0 .. $#$value];
    }
    _throw('HIAL_VIAL_BRIDGE_INVOCATION_ERROR', 'invocation', 'route contains a live object or unsupported reference', $path)
        if ref($value);
    return $value;
}

sub _throw($code, $category, $message, $path, $source = undef) {
    die bless {
        code => $code,
        category => $category,
        message => $message,
        source => $source,
        path => $path,
        span => undef,
        related => [],
    }, 'FSM::HIAL::VIALBridge::Builder::Failure';
}

sub _failure_result(%args) {
    my $diagnostic = {
        code => $args{code},
        category => $args{category},
        message => $args{message},
        source => $args{source},
        path => $args{path},
        span => $args{span},
        related => $args{related} || [],
    };
    return {
        ok => JSON::PP::false,
        manifest => undef,
        report => undef,
        diagnostics => [$diagnostic],
    };
}

package FSM::HIAL::VIALBridge::Builder::Failure;

use overload '""' => sub { $_[0]{message} // 'HIAL/VIAL bridge failure' }, fallback => 1;

1;
