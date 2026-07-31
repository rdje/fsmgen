package FSM::VIAL::PlanBuilder;

use v5.20;
use strict;
use warnings;
use bytes ();
use Carp qw(confess);
use Digest::SHA qw(sha256_hex);
use File::Basename qw(basename);
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Adapter::IAL2::PPIF;
use FSM::Adapter::ISF;
use FSM::HIAL::VIALBridge::Builder;
use FSM::Pipeline::DirectGenerationOrchestrator;
use FSM::Pipeline::HDLGenerator;
use FSM::Pipeline::SourceFrontend;
use FSM::Scheduler::ISF;
use FSM::VIAL::ExecutionBuilder;
use FSM::VIAL::SemanticIR;

sub build($class, @args) {
    return _failure('VIAL_TOOL_INVOCATION_ERROR', 'build requires the exact PlanBuilder class invocant', '/')
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return _failure('VIAL_TOOL_INVOCATION_ERROR', 'build expects one closed argument hash', '/')
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);

    my $result = eval { _build($args[0]) };
    return $result if defined $result;
    return _failure(
        'VIAL_HOST_ERROR',
        _sanitize_exception($@),
        '/',
    );
}

sub _build($raw) {
    my @keys = qw(
        semantic_ir hial_source fixture_id scenario_ids execution_profile
        replay_manifest native_extension_catalog
    );
    _require_exact_keys($raw, \@keys, 'plan build');
    confess 'semantic_ir must be an exact FSM::VIAL::SemanticIR object'
        unless blessed($raw->{semantic_ir})
            && ref($raw->{semantic_ir}) eq 'FSM::VIAL::SemanticIR';
    confess 'hial_source must be an unblessed hash'
        unless ref($raw->{hial_source}) eq 'HASH' && !blessed($raw->{hial_source});
    confess 'scenario_ids must be an array'
        unless ref($raw->{scenario_ids}) eq 'ARRAY';
    confess 'native_extension_catalog must be an array'
        unless ref($raw->{native_extension_catalog}) eq 'ARRAY';

    my $route = eval { _build_hial_route($raw->{hial_source}) };
    return _failure(
        'VIAL_HIAL_SOURCE_ERROR',
        _sanitize_exception($@),
        '/hial_source',
    ) unless defined $route;
    my $bridge = $route->{bridge_result};
    return {
        ok => JSON::PP::false,
        bridge_manifest => undef,
        bridge_report => undef,
        plan => undef,
        review_artifacts => [],
        diagnostics => [_bridge_diagnostics($bridge->{diagnostics})],
    } unless $bridge->{ok};

    my $selection = eval { [
        _resolve_selection(
            $raw->{semantic_ir},
            $raw->{fixture_id},
            $raw->{scenario_ids},
        ),
    ] };
    return _failure(
        'VIAL_TOOL_INVOCATION_ERROR',
        _sanitize_exception($@),
        '/options',
    ) unless defined $selection;
    my ($fixture_id, $scenario_ids) = @$selection;
    my $execution = FSM::VIAL::ExecutionBuilder->build({
        semantic_ir => $raw->{semantic_ir},
        bridge_manifest => $bridge->{manifest},
        fixture_id => $fixture_id,
        scenario_ids => $scenario_ids,
        execution_profile => $raw->{execution_profile},
        replay_manifest => $raw->{replay_manifest},
        native_extension_catalog => $raw->{native_extension_catalog},
    });
    return {
        ok => JSON::PP::false,
        bridge_manifest => undef,
        bridge_report => undef,
        plan => undef,
        review_artifacts => [],
        diagnostics => [_execution_diagnostics($execution->{diagnostics})],
    } unless $execution->{ok};

    return {
        ok => JSON::PP::true,
        bridge_manifest => $bridge->{manifest},
        bridge_report => _clone($bridge->{report}),
        plan => _clone($execution->{plan}),
        review_artifacts => _clone($route->{review_artifacts}),
        diagnostics => [],
    };
}

sub _build_hial_route($source) {
    my $source_id = $source->{source_id};
    return _build_ial0_route($source) if $source_id =~ /\.fsm\z/i;
    return _build_ial1_route($source) if $source_id =~ /\.isf\z/i;
    return _build_ial2_route($source) if $source_id =~ /\.ppif\z/i;
    confess "HIAL source '$source_id' must end in .fsm, .isf, or .ppif";
}

sub _build_ial0_route($source) {
    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_source(
        source_text => $source->{text},
        source_label => $source->{source_id},
        debug_level => 0,
    );
    my $source_info = FSM::Pipeline::SourceFrontend->classify_source_ast($raw_ast);
    confess 'the direct IAL0 VIAL planning route accepts one direct .fsm root only'
        unless ($source_info->{kind} // '') eq 'fsm';
    confess 'the direct IAL0 VIAL planning route does not yet accept package imports'
        if @{$source_info->{package_import_names} || []};
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
        strict_mode => 1,
    );
    my $hdl_result = FSM::Pipeline::DirectGenerationOrchestrator->generate_from_source(
        pipeline => $pipeline,
        raw_ast => $raw_ast,
        source_info => $source_info,
        fsm_file => undef,
    );
    my $bridge = FSM::HIAL::VIALBridge::Builder->build_ial0({
        profile => 'core_single_unit_v1',
        authored_source => _source_record($source->{text}, $source->{source_id}),
        hdl_result => $hdl_result,
        backend_names => _backend_names_from_hdl_result($hdl_result),
    });
    return { bridge_result => $bridge, review_artifacts => [] };
}

sub _build_ial1_route($source) {
    my $adapter = FSM::Adapter::ISF->new();
    my $scheduler = FSM::Scheduler::ISF->new();
    my $actor = $adapter->parse_source($source->{text}, basename($source->{source_id}));
    my $schedule = JSON::PP->new->decode($scheduler->report($actor));
    my $lowered = $scheduler->lower($actor);
    my ($entry_name, $entry_text) = _generated_ial0_entry($actor, $lowered->{files});
    my $bridge = FSM::HIAL::VIALBridge::Builder->build_ial1({
        profile => 'core_single_unit_v1',
        authored_source => _source_record($source->{text}, $source->{source_id}),
        actor => $actor,
        schedule_report => $schedule,
        generated_ial0 => _source_record($entry_text, undef, $entry_name),
        backend_names => _backend_names_from_actor($actor),
    });
    return {
        bridge_result => $bridge,
        review_artifacts => _review_ial0_artifacts($lowered->{files}, $source->{source_id}),
    };
}

sub _build_ial2_route($source) {
    my $ial2 = FSM::Adapter::IAL2::PPIF->new()->parse_source(
        $source->{text},
        $source->{source_id},
    );
    my $generated_ial1 = $ial2->{generated_ial1};
    confess 'the first IAL2 VIAL planning route requires one generated IAL1 review source'
        unless ref($generated_ial1) eq 'HASH'
            && defined($generated_ial1->{text}) && !ref($generated_ial1->{text})
            && defined($generated_ial1->{name}) && !ref($generated_ial1->{name});
    my $adapter = FSM::Adapter::ISF->new();
    my $actor = $adapter->parse_source($generated_ial1->{text}, $generated_ial1->{name});
    my ($entry_name, $entry_text) = _generated_ial0_entry(
        $actor,
        $ial2->{generated_ial0}{files},
    );
    my $bridge = FSM::HIAL::VIALBridge::Builder->build_ial2_via_ial1({
        profile => 'core_single_unit_v1',
        authored_source => _source_record($source->{text}, $source->{source_id}),
        generated_ial1 => {
            source => _source_record($generated_ial1->{text}, undef, $generated_ial1->{name}),
            actor => $actor,
            schedule_report => $ial2->{generated_ial1_schedule_report},
        },
        generated_ial0 => _source_record($entry_text, undef, $entry_name),
        backend_names => _backend_names_from_actor($actor),
    });
    return {
        bridge_result => $bridge,
        review_artifacts => [
            {
                artifact_name => basename($generated_ial1->{name}),
                text => $generated_ial1->{text},
                layer => 'IAL1',
                source_id => $source->{source_id},
            },
            @{_review_ial0_artifacts($ial2->{generated_ial0}{files}, $source->{source_id})},
        ],
    };
}

sub _generated_ial0_entry($actor, $files) {
    confess 'HIAL lowering emitted no generated IAL0 file map'
        unless ref($files) eq 'HASH' && keys %$files;
    my @candidate = (
        "$actor->{actor_name}_top.fsm",
        "$actor->{actor_name}.fsm",
        sort grep { /\.fsm\z/i } keys %$files,
    );
    my %seen;
    for my $name (@candidate) {
        next if $seen{$name}++;
        return ($name, $files->{$name})
            if exists($files->{$name}) && defined($files->{$name}) && !ref($files->{$name});
    }
    confess 'HIAL lowering emitted no scalar generated IAL0 entry source';
}

sub _review_ial0_artifacts($files, $source_id) {
    confess 'generated IAL0 review files must be a hash'
        unless ref($files) eq 'HASH';
    return [map {
        confess "generated IAL0 review artifact '$_' must be a basename"
            unless basename($_) eq $_ && $_ =~ /\.fsm\z/i;
        confess "generated IAL0 review artifact '$_' must contain scalar text"
            unless defined($files->{$_}) && !ref($files->{$_});
        {
            artifact_name => $_,
            text => $files->{$_},
            layer => 'IAL0',
            source_id => $source_id,
        }
    } sort keys %$files];
}

sub _backend_names_from_actor($actor) {
    my @endpoints = ($actor->{clock}, $actor->{reset}{name});
    push @endpoints, map { $_->{name} }
        @{$actor->{interface}{inputs} || []}, @{$actor->{interface}{outputs} || []};
    my @configurations = map { $_->{name} } @{$actor->{params} || []};
    my @probes = map { $_->{name} }
        @{ref($actor->{verification_bridge}) eq 'HASH'
            ? ($actor->{verification_bridge}{probes} || []) : []};
    return _identity_backend_names(
        $actor->{actor_name}, \@endpoints, \@configurations, \@probes,
    );
}

sub _backend_names_from_hdl_result($result) {
    my $module_info = $result->{module_info};
    confess 'direct IAL0 generation did not produce module_info'
        unless ref($module_info) eq 'HASH';
    my (@endpoints, @configurations);
    my $system = $module_info->{explicit_system_contract};
    push @endpoints, $system->{clock}, $system->{reset}
        if ref($system) eq 'HASH';
    for my $name (sort keys %{$module_info->{signals} || {}}) {
        my $signal = $module_info->{signals}{$name};
        next unless blessed($signal) && $signal->can('get_attribute') && $signal->can('name');
        my $role = $signal->get_attribute('signal_role') // '';
        push @endpoints, $signal->name if $role eq 'INPUT' || $role eq 'OUTPUT';
    }
    my %seen;
    @endpoints = grep { defined($_) && !$seen{$_}++ } @endpoints;
    return _identity_backend_names(
        $module_info->{module_name}, \@endpoints, \@configurations, [],
    );
}

sub _identity_backend_names($unit, $endpoints, $configurations, $probes) {
    my %endpoint = map { $_ => $_ } @$endpoints;
    my %configuration = map { $_ => $_ } @$configurations;
    my %probe = map { $_ => $_ } @$probes;
    return {
        map {
            $_ => {
                unit => $unit,
                endpoints => {%endpoint},
                configurations => {%configuration},
                probes => {%probe},
            }
        } qw(systemverilog vhdl)
    };
}

sub _source_record($text, $repository_path, $artifact_name = undef) {
    $artifact_name //= basename($repository_path);
    my $line_count = length($text)
        ? (() = $text =~ /\n/g) + ($text =~ /\n\z/ ? 0 : 1)
        : 0;
    return {
        text => $text,
        repository_path => $repository_path,
        artifact_name => $artifact_name,
        content_sha256 => sha256_hex($text),
        byte_length => bytes::length($text),
        line_count => $line_count,
    };
}

sub _resolve_selection($semantic_ir, $requested_fixture, $requested_scenarios) {
    my $semantic = $semantic_ir->as_hashref;
    my @fixtures = map { @{$_->{fixtures} || []} } @{$semantic->{packages}};
    my @fixture_matches = defined($requested_fixture)
        ? grep {
            $_->{semantic_id} eq $requested_fixture || $_->{name} eq $requested_fixture
        } @fixtures
        : @fixtures;
    confess defined($requested_fixture)
        ? "fixture '$requested_fixture' does not resolve exactly once"
        : 'fixture_id is required when VIAL declares zero or multiple fixtures'
        unless @fixture_matches == 1;
    my $fixture = $fixture_matches[0];

    my @selected;
    if (@$requested_scenarios) {
        my %seen;
        for my $requested (@$requested_scenarios) {
            confess 'scenario selection names must be non-empty scalars'
                unless defined($requested) && !ref($requested) && length($requested);
            my @matches = grep {
                $_->{semantic_id} eq $requested || $_->{name} eq $requested
            } @{$fixture->{scenarios}};
            confess "scenario '$requested' does not resolve exactly once in fixture '$fixture->{name}'"
                unless @matches == 1;
            confess "scenario '$requested' is selected more than once"
                if $seen{$matches[0]{semantic_id}}++;
            push @selected, $matches[0]{semantic_id};
        }
    }
    else {
        @selected = map { $_->{semantic_id} } @{$fixture->{scenarios}};
    }
    confess "fixture '$fixture->{name}' selects no scenario" unless @selected;
    return ($fixture->{semantic_id}, \@selected);
}

sub _bridge_diagnostics($diagnostics) {
    return map {
        {
            code => $_->{code},
            severity => 'error',
            message => $_->{message},
            source_locations => [],
            semantic_path => $_->{path} // '/',
            related => _clone($_->{related} || []),
            notes => [],
            hints => [],
        }
    } @$diagnostics;
}

sub _execution_diagnostics($diagnostics) {
    return map {
        {
            code => $_->{code},
            severity => $_->{severity} // 'error',
            message => $_->{message},
            source_locations => defined($_->{source_location})
                ? [_clone($_->{source_location})] : [],
            semantic_path => $_->{semantic_path} // '/',
            related => _clone($_->{related} || []),
            notes => [map { "bridge fact: $_" } @{$_->{bridge_fact_paths} || []}],
            hints => [],
        }
    } @$diagnostics;
}

sub _failure($code, $message, $path) {
    return {
        ok => JSON::PP::false,
        bridge_manifest => undef,
        bridge_report => undef,
        plan => undef,
        review_artifacts => [],
        diagnostics => [{
            code => $code,
            severity => 'error',
            message => $message,
            source_locations => [],
            semantic_path => $path,
            related => [],
            notes => [],
            hints => [],
        }],
    };
}

sub _require_exact_keys($value, $keys, $label) {
    my %expected = map { $_ => 1 } @$keys;
    my @unknown = sort grep { !$expected{$_} } keys %$value;
    my @missing = grep { !exists($value->{$_}) } @$keys;
    confess "$label has unknown key '$unknown[0]'" if @unknown;
    confess "$label is missing key '$missing[0]'" if @missing;
}

sub _sanitize_exception($exception) {
    my $text = "$exception";
    $text =~ s/\s+at\s+\S+\s+line\s+\d+.*\z//s;
    $text =~ s/[\r\n]+/ /g;
    $text =~ s/^\s+|\s+$//g;
    return length($text) ? $text : 'invalid HIAL source';
}

sub _clone($value) {
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    return {map { $_ => _clone($value->{$_}) } sort keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    confess 'PlanBuilder output contains unsupported reference data' if ref($value);
    return $value;
}

1;
