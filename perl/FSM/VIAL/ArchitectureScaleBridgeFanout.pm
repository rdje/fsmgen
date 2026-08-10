package FSM::VIAL::ArchitectureScaleBridgeFanout;

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
use FSM::HIAL::VIALBridge::Manifest;
use FSM::Scheduler::ISF;
use FSM::VIAL::ArchitectureScaleWorkload;
use FSM::VIAL::Parser;

my $FAMILY = 'bridge_fanout_v1';
my $HIAL_SOURCE = 'generated/vial-scale/bridge_fanout/vial_architecture_scale.isf';
my $VIAL_SOURCE = 'generated/vial-scale/bridge_fanout/vial_architecture_scale.vial';
my $REFERENCE_HIAL_SOURCE = 'ppif/ahb_lite_subordinate.ppif';
my $REFERENCE_VIAL_SOURCE = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $REFERENCE_HIAL_BYTES = 1_326;
my $REFERENCE_HIAL_SHA256 =
    '9a1d7a591d3ec9a3419b07f05bc83aefa2b213b2cae45f5332f9349ffa27056c';
my $REFERENCE_VIAL_BYTES = 4_986;
my $REFERENCE_VIAL_SHA256 =
    '2205b3b4f073a61374b19cb72f06afe31d75fc4d88f903c414b9b28a744ca4cd';
my $EVALUATION_SCHEMA = 'fsmgen.vial_architecture_scale_bridge_evaluation.v1';
my @CONSTRUCT_KEYS = qw(
    level primary_axis reference_hial_text reference_vial_text
);
my @EVALUATE_KEYS = qw(construction);
my @EVALUATION_KEYS = qw(
    ok status schema schema_version workload_identity family level primary_axis
    requested_counts observed_outcome metrics manifest_sha256 report_sha256
    review_layers input_identities diagnostics contract_discrepancies
);
sub construct($class, @args) {
    _exact_invocant($class, 'construct');
    confess __PACKAGE__ . "->construct expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $raw = $args[0];
    _confess_exact_keys($raw, \@CONSTRUCT_KEYS, 'bridge construction');

    my ($axis, $level) = @{$raw}{qw(primary_axis level)};
    my $catalog = FSM::VIAL::ArchitectureScaleWorkload->catalog;
    my $axis_contract = defined($axis)
        ? $catalog->{families}{$FAMILY}{axes}{$axis}
        : undef;
    confess "unknown bridge-fanout primary axis\n" unless defined $axis_contract;
    confess "unknown bridge-fanout level\n"
        unless defined($level) && exists $axis_contract->{levels}{$level};

    my $inputs;
    if ($level eq 'reference_v1') {
        _validate_reference(
            $raw->{reference_hial_text}, $REFERENCE_HIAL_BYTES,
            $REFERENCE_HIAL_SHA256, 'HIAL',
        );
        _validate_reference(
            $raw->{reference_vial_text}, $REFERENCE_VIAL_BYTES,
            $REFERENCE_VIAL_SHA256, 'VIAL',
        );
        $inputs = [
            _input($REFERENCE_HIAL_SOURCE, 'hial_source', $raw->{reference_hial_text}),
            _input($REFERENCE_VIAL_SOURCE, 'vial_source', $raw->{reference_vial_text}),
        ];
    }
    else {
        confess "reference_hial_text is accepted only for reference_v1\n"
            if defined $raw->{reference_hial_text};
        confess "reference_vial_text is accepted only for reference_v1\n"
            if defined $raw->{reference_vial_text};
        my $requested = $axis_contract->{levels}{$level};
        $inputs = [
            _input($HIAL_SOURCE, 'hial_source', _render_hial($axis, $level, $requested)),
            _input($VIAL_SOURCE, 'vial_source', _render_vial()),
        ];
    }

    return FSM::VIAL::ArchitectureScaleWorkload->construct({
        family => $FAMILY,
        level => $level,
        primary_axis => $axis,
        backend_profile => undef,
        tool_profile => undef,
        inputs => $inputs,
    });
}

sub parse($class, @args) {
    _exact_invocant($class, 'parse');
    confess __PACKAGE__ . "->parse expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys($args[0], \@EVALUATE_KEYS, 'bridge parse');
    my $construction = _validated_construction($args[0]{construction});
    my $hial = _hial_input($construction);
    if ($construction->{specification}{level} eq 'reference_v1') {
        my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(
            $hial->{content}, $hial->{relative_path},
        );
        return FSM::Adapter::ISF->new()->parse_source(
            $result->{generated_ial1}{text}, $result->{generated_ial1}{name},
        );
    }
    return FSM::Adapter::ISF->new()->parse_source(
        $hial->{content}, basename($hial->{relative_path}),
    );
}

sub evaluate($class, @args) {
    _exact_invocant($class, 'evaluate');
    confess __PACKAGE__ . "->evaluate expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys($args[0], \@EVALUATE_KEYS, 'bridge evaluation');
    my $construction = _validated_construction($args[0]{construction});
    my $spec = $construction->{specification};
    my ($axis, $level) = @{$spec}{qw(primary_axis level)};

    my ($route, $vial_checked) = eval {
        my $built_route = _route($construction);
        my $checked = _check_vial($construction);
        ($built_route, $checked);
    };
    if ($@) {
        return _evaluation_failure(
            $construction, 'VIAL_SCALE_BRIDGE_ROUTE_ERROR',
            _sanitize_exception($@), '/',
        );
    }

    my $first = $route->{method}->($route->{class}, $route->{arguments});
    if (!$first->{ok}) {
        return _rejection_evaluation($construction, $first->{diagnostics});
    }

    my @oracle_errors;
    push @oracle_errors, _oracle_error(
        'VIAL_SCALE_BRIDGE_OUTCOME_ERROR',
        'over-limit workload was accepted instead of failing at an authoritative boundary',
        '/observed_outcome',
    ) if $level eq 'over_limit_v1';

    my $manifest = $first->{manifest}->as_hashref;
    my $canonical = JSON::PP->new->canonical(1)->utf8(1);
    push @oracle_errors, _oracle_error(
        'VIAL_SCALE_BRIDGE_REPORT_ERROR',
        'manifest and bridge report projections differ',
        '/report',
    ) unless $canonical->encode($manifest) eq $canonical->encode($first->{report});

    my $second = $route->{method}->($route->{class}, $route->{arguments});
    push @oracle_errors, _oracle_error(
        'VIAL_SCALE_BRIDGE_DETERMINISM_ERROR',
        'independent bridge construction did not reproduce byte-equal output',
        '/report',
    ) unless $second->{ok}
        && $canonical->encode($second->{report}) eq $canonical->encode($first->{report});

    my $metrics = _metrics($first->{report}, $canonical);
    my $observed = $axis eq 'serialized_manifest_bytes'
        ? $metrics->{serialized_manifest_bytes}
        : $metrics->{$axis};
    my $requested = _requested_count($spec->{requested_counts}, $axis);
    push @oracle_errors, _oracle_error(
        'VIAL_SCALE_BRIDGE_COUNT_ERROR',
        "observed $axis count $observed does not equal requested count $requested",
        "/metrics/$axis",
    ) if defined($requested) && (!defined($observed) || $observed != $requested);

    push @oracle_errors, @{_manifest_integrity_errors($first->{report})};
    push @oracle_errors, @{_vial_resolution_errors($vial_checked, $first->{report})};

    my $report_json = $canonical->encode($first->{report});
    my @layers = map { $_->{layer} } @{$first->{report}{review_route}{stages}};
    return _evaluation({
        ok => @oracle_errors ? JSON::PP::false : JSON::PP::true,
        status => @oracle_errors ? 'oracle_failure' : 'accepted',
        schema => $EVALUATION_SCHEMA,
        schema_version => 1,
        workload_identity => $construction->{workload_identity},
        family => $FAMILY,
        level => $level,
        primary_axis => $axis,
        requested_counts => _clone($spec->{requested_counts}),
        observed_outcome => 'accepted',
        metrics => $metrics,
        manifest_sha256 => sha256_hex($canonical->encode($manifest)),
        report_sha256 => sha256_hex($report_json),
        review_layers => \@layers,
        input_identities => _clone($construction->{input_identities}),
        diagnostics => \@oracle_errors,
        contract_discrepancies => [],
    });
}

sub evaluation_keys($class) {
    _exact_invocant($class, 'evaluation_keys');
    return [@EVALUATION_KEYS];
}

sub _render_hial($axis, $level, $requested) {
    return _render_two_unit_source() if $axis eq 'selected_units' && $level eq 'over_limit_v1';
    return _render_two_domain_source() if $axis eq 'selected_domains' && $level eq 'over_limit_v1';

    my %shape = (
        configurations => 0,
        type_count => 1,
        endpoints => 4,
        transactions => 1,
        events => 1,
        observations => 0,
        probes => 1,
        residues => 0,
        tuning_width => undef,
    );
    my $count = _requested_count($requested, $axis);
    if ($axis eq 'configurations') {
        $shape{configurations} = $count;
    }
    elsif ($axis eq 'types') {
        $shape{type_count} = $count;
        $shape{configurations} = $count - 1;
    }
    elsif ($axis eq 'endpoints') {
        $shape{endpoints} = $count;
    }
    elsif ($axis eq 'transactions') {
        $shape{transactions} = $count;
    }
    elsif ($axis eq 'events') {
        $shape{events} = $count;
    }
    elsif ($axis eq 'observations') {
        $shape{observations} = $count;
    }
    elsif ($axis eq 'probes') {
        $shape{probes} = $count;
    }
    elsif ($axis eq 'retained_residue_records') {
        $shape{residues} = $count;
    }
    elsif ($axis eq 'backend_bindings') {
        my $represented = $level eq 'over_limit_v1' ? $count + 1 : $count;
        my $semantic_records = int($represented / 2);
        $shape{endpoints} = $semantic_records <= 4_098 ? $semantic_records - 2 : 4_096;
        $shape{configurations} = $semantic_records
            - 1 - $shape{endpoints} - $shape{probes};
    }
    elsif ($axis eq 'source_map_records') {
        $shape{configurations} = _source_map_configuration_recipe($level);
        $shape{residues} = _source_map_residue_recipe($level);
    }
    elsif ($axis eq 'serialized_manifest_bytes') {
        $shape{configurations} = _manifest_byte_configuration_recipe($level);
        $shape{residues} = _manifest_byte_residue_recipe($level);
        $shape{observations} = _manifest_byte_observation_recipe($level);
        $shape{tuning_width} = _manifest_byte_width_recipe($level);
    }
    elsif ($axis ne 'selected_units' && $axis ne 'selected_domains') {
        confess "unsupported bridge-fanout axis '$axis'\n";
    }
    return _render_qualification_source(\%shape);
}

sub _render_qualification_source($shape) {
    my @params;
    for my $index (0 .. $shape->{configurations} - 1) {
        my $width = defined($shape->{tuning_width}) && $index == 0
            ? $shape->{tuning_width}
            : $shape->{type_count} > 1 ? $index + 2 : 1;
        push @params, sprintf('(configuration_%08d %d\'h0)', $index, $width);
    }
    my @extra_endpoints = map {
        sprintf('(input endpoint_%08d)', $_)
    } 0 .. $shape->{endpoints} - 5;
    my @storage = map {
        sprintf('(var probe_%08d (width 1))', $_)
    } 0 .. $shape->{probes} - 1;
    my @events = map {
        sprintf('(event bridge_event_%08d predicate sample scale_input)', $_)
    } 0 .. $shape->{events} - 1;
    my @probes = map {
        sprintf('(probe probe_%08d read_only)', $_)
    } 0 .. $shape->{probes} - 1;
    my @residues = map {
        sprintf('(residue retained_%08d)', $_)
    } 0 .. $shape->{residues} - 1;
    my @observations = map {
        sprintf('(observe observation_%08d (role passive_monitor) (signals scale_input))', $_)
    } 0 .. $shape->{observations} - 1;
    my @transactions = map {
        sprintf('(transaction transaction_%08d (on scale_input))', $_)
    } 0 .. $shape->{transactions} - 2;

    return join('',
        '(actor vial_architecture_scale',
        (@params ? ' (params ' . join(' ', @params) . ')' : ''),
        ' (clock clk)',
        ' (reset (rst_n async active_low))',
        ' (interface (input scale_input) ', join(' ', @extra_endpoints),
        ' (output scale_output))',
        ' (storage ', join(' ', @storage), ')',
        ' (verification-bridge',
        ' (domain scale)',
        ' (protocol architecture_scale_probe',
        ' (profile qualification_only)',
        ' (revision 1)',
        ' (role verification)',
        ' (facts (fact scale_evidence_only true)))',
        ' (transaction bridge_anchor',
        ' (fields (field anchor scale_input drive unspecified))',
        ' (events ', join(' ', @events), '))',
        ' ', join(' ', @probes),
        ' ', join(' ', @residues),
        ')',
        ' ', join(' ', @observations),
        ' ', join(' ', @transactions),
        ")\n",
    );
}

sub _render_two_domain_source() {
    return join('',
        '(actor vial_architecture_scale',
        ' (clock-domains',
        ' (domain scale (clock clk) (reset (rst_n async active_low)) :default)',
        ' (domain auxiliary (clock aux_clk) (reset (aux_rst_n sync active_high))))',
        ' (interface (input scale_input (domain scale))',
        ' (output scale_output (domain scale))))',
        "\n",
    );
}

sub _render_two_unit_source() {
    return join('',
        '(actor vial_architecture_scale',
        ' (clock clk)',
        ' (reset (rst_n async active_low))',
        ' (interface (input scale_input) (output scale_output))',
        ' (imports (library scale.child as scale_child))',
        ' (instance child of scale_child.worker))',
        ' (library scale.child',
        ' (exports (actor worker))',
        ' (actor worker',
        ' (clock clk)',
        ' (reset (rst_n async active_low))',
        ' (interface (input start) (output done))))',
        "\n",
    );
}

sub _render_vial() {
    return join('',
        '(vial (version 1) (package architecture_scale_bridge',
        ' (imports)',
        ' (types (type bit_t (logic 1)))',
        ' (transactions (transaction bridge_anchor',
        ' (fields (anchor (type bit_t)))',
        ' (events bridge_event_00000000)))',
        ' (models)',
        ' (scoreboards)',
        ' (fixtures (fixture qualification',
        ' (dut dut',
        ' (unit "unit/vial_architecture_scale")',
        ' (domains (domain scale "domain/scale"))',
        ' (endpoints',
        ' (endpoint anchor "endpoint/scale_input" (type bit_t) public_port)',
        ' (endpoint retained "probe/probe_00000000" (type bit_t) verification_probe))',
        ' (transactions (transaction bridge "transaction/bridge_anchor" bridge_anchor)))',
        ' (instances)',
        ' (coverage)',
        ' (faults)',
        ' (randomness (seed 1701))',
        ' (scenarios (scenario smoke',
        ' (timeout (cycles scale 16))',
        ' (steps (reset scale 1))))))))',
        "\n",
    );
}

# These recipes are calibrated against the version-1 manifest projection.
# Every increment is a real semantic record or referenced logical width; no
# comment, blank-data, or caller-supplied report padding participates.
sub _source_map_configuration_recipe($level) {
    return {
        gate_candidate_v1 => 2,
        qualification_candidate_v1 => 1_022,
        limit_v1 => 1_605,
        over_limit_v1 => 1_607,
    }->{$level};
}

sub _source_map_residue_recipe($level) {
    return {
        gate_candidate_v1 => 1_583,
        qualification_candidate_v1 => 4_063,
        limit_v1 => 4_075,
        over_limit_v1 => 4_064,
    }->{$level};
}

sub _manifest_byte_width_recipe($level) {
    return {
        gate_candidate_v1 => 4_609,
        qualification_candidate_v1 => 8_673,
        limit_v1 => 413_102,
        over_limit_v1 => 413_105,
    }->{$level};
}

sub _manifest_byte_configuration_recipe($level) {
    return $level eq 'limit_v1' || $level eq 'over_limit_v1' ? 500 : 1;
}

sub _manifest_byte_residue_recipe($level) {
    return {
        gate_candidate_v1 => 388,
        qualification_candidate_v1 => 1_700,
        limit_v1 => 4_000,
        over_limit_v1 => 4_000,
    }->{$level};
}

sub _manifest_byte_observation_recipe($level) {
    return $level eq 'limit_v1' || $level eq 'over_limit_v1' ? 2 : 0;
}

sub _validated_construction($raw) {
    confess "construction must be one unblessed hash\n"
        unless ref($raw) eq 'HASH' && !blessed($raw);
    my $spec = $raw->{specification};
    confess "construction must be successful and carry one specification hash\n"
        unless $raw->{ok} && ref($spec) eq 'HASH' && !blessed($spec);
    my $rebuilt = FSM::VIAL::ArchitectureScaleWorkload->construct({
        family => $spec->{family},
        level => $spec->{level},
        primary_axis => $spec->{primary_axis},
        backend_profile => $spec->{backend_profile},
        tool_profile => $spec->{tool_profile},
        inputs => $raw->{inputs},
    });
    my $canonical = JSON::PP->new->canonical(1)->allow_nonref(1);
    confess "construction is not canonical\n"
        unless $rebuilt->{ok}
            && $canonical->encode($rebuilt) eq $canonical->encode($raw);
    return $rebuilt;
}

sub _hial_input($construction) {
    return _role_input($construction, 'hial_source');
}

sub _vial_input($construction) {
    return _role_input($construction, 'vial_source');
}

sub _role_input($construction, $role) {
    my @matches = grep { ($_->{role} // '') eq $role } @{$construction->{inputs}};
    confess "construction must contain exactly one $role input\n" unless @matches == 1;
    return $matches[0];
}

sub _route($construction) {
    my $hial = _hial_input($construction);
    my $adapter = FSM::Adapter::ISF->new();
    if ($construction->{specification}{level} eq 'reference_v1') {
        my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_source(
            $hial->{content}, $hial->{relative_path},
        );
        my $ial1_text = $ppif->{generated_ial1}{text};
        my $actor = $adapter->parse_source(
            $ial1_text, $ppif->{generated_ial1}{name},
        );
        return {
            class => 'FSM::HIAL::VIALBridge::Builder',
            method => sub ($class, $arguments) {
                return $class->build_ial2_via_ial1($arguments);
            },
            arguments => {
                profile => 'core_single_unit_v1',
                authored_source => _source_record(
                    $hial->{content}, $hial->{relative_path},
                ),
                generated_ial1 => {
                    source => _source_record(
                        $ial1_text, undef, $ppif->{generated_ial1}{name},
                    ),
                    actor => $actor,
                    schedule_report => $ppif->{generated_ial1_schedule_report},
                },
                generated_ial0 => _source_record(
                    $ppif->{generated_ial0}{files}{'ahb_lite_subordinate.fsm'},
                    undef, 'ahb_lite_subordinate.fsm',
                ),
                backend_names => _backend_names($actor),
            },
        };
    }

    my $actor = $adapter->parse_source(
        $hial->{content}, basename($hial->{relative_path}),
    );
    my $scheduler = FSM::Scheduler::ISF->new();
    my $schedule_report = JSON::PP->new->decode($scheduler->report($actor));
    my $lowered = $scheduler->lower($actor);
    my $artifact_name = $actor->{actor_name} . '.fsm';
    $artifact_name = $actor->{actor_name} . '_top.fsm'
        unless exists $lowered->{files}{$artifact_name};
    my $ial0_text = $lowered->{files}{$artifact_name};
    confess "ordinary IAL1 lowering did not emit '$artifact_name'\n"
        unless defined $ial0_text;
    return {
        class => 'FSM::HIAL::VIALBridge::Builder',
        method => sub ($class, $arguments) {
            return $class->build_ial1($arguments);
        },
        arguments => {
            profile => 'core_single_unit_v1',
            authored_source => _source_record(
                $hial->{content}, $hial->{relative_path},
            ),
            actor => $actor,
            schedule_report => $schedule_report,
            generated_ial0 => _source_record($ial0_text, undef, $artifact_name),
            backend_names => _backend_names($actor),
        },
    };
}

sub _backend_names($actor) {
    my @clock_names = defined($actor->{clock}) ? ($actor->{clock}) : ();
    my @reset_names = ref($actor->{reset}) eq 'HASH'
        ? ($actor->{reset}{name}) : ();
    if (ref($actor->{clock_domains}) eq 'HASH') {
        my $domains = $actor->{clock_domains}{domains} // [];
        push @clock_names, map { $_->{clock} } @$domains;
        push @reset_names, map { $_->{reset}{name} } grep {
            ref($_->{reset}) eq 'HASH'
        } @$domains;
    }
    my @endpoints = (@clock_names, @reset_names);
    push @endpoints, map { $_->{name} } @{$actor->{interface}{inputs} // []};
    push @endpoints, map { $_->{name} } @{$actor->{interface}{outputs} // []};
    my @configurations = map { $_->{name} } @{$actor->{params} // []};
    my @probes = map { $_->{name} } @{$actor->{verification_bridge}{probes} // []};
    my %endpoint = map { $_ => $_ } @endpoints;
    my %configuration = map { $_ => $_ } @configurations;
    my %probe = map { $_ => $_ } @probes;
    return {
        map {
            $_ => {
                unit => $actor->{actor_name},
                endpoints => {%endpoint},
                configurations => {%configuration},
                probes => {%probe},
            }
        } qw(systemverilog vhdl)
    };
}

sub _source_record($text, $repository_path, $artifact_name = undef) {
    $artifact_name //= basename($repository_path // 'generated');
    my $lines = length($text)
        ? (() = $text =~ /\n/g) + ($text =~ /\n\z/ ? 0 : 1)
        : 0;
    return {
        text => $text,
        repository_path => $repository_path,
        artifact_name => $artifact_name,
        content_sha256 => sha256_hex($text),
        byte_length => bytes::length($text),
        line_count => $lines,
    };
}

sub _check_vial($construction) {
    my $vial = _vial_input($construction);
    my $checked = FSM::VIAL::Parser->check_source({
        text => $vial->{content},
        source_name => $vial->{relative_path},
        source_catalog => {},
    });
    confess "checked VIAL input is invalid\n" unless $checked->{ok};
    return $checked;
}

sub _requested_count($requested, $axis) {
    return $requested->{$axis} if exists $requested->{$axis};
    return $requested->{minimum_bytes}
        if $axis eq 'serialized_manifest_bytes' && exists $requested->{minimum_bytes};
    return undef;
}

sub _metrics($report, $canonical) {
    return {
        selected_units => scalar(@{$report->{units}}),
        selected_domains => scalar(@{$report->{domains}}),
        configurations => scalar(@{$report->{configurations}}),
        types => scalar(@{$report->{types}}),
        endpoints => scalar(@{$report->{endpoints}}),
        transactions => scalar(@{$report->{transactions}}),
        events => scalar(@{$report->{events}}),
        observations => scalar(@{$report->{observations}}),
        probes => scalar(@{$report->{probes}}),
        backend_bindings => scalar(@{$report->{backend_bindings}}),
        retained_residue_records => scalar(@{$report->{unsupported_residue}}),
        source_map_records => scalar(@{$report->{source_map}}),
        serialized_manifest_bytes => bytes::length($canonical->encode($report)),
    };
}

sub _manifest_integrity_errors($report) {
    my @errors;
    my @actual_keys = sort keys %$report;
    my @expected_keys = sort @{FSM::HIAL::VIALBridge::Manifest->top_level_keys};
    push @errors, _oracle_error(
        'VIAL_SCALE_BRIDGE_SHAPE_ERROR',
        'bridge report top-level key set differs from the manifest contract',
        '/',
    ) unless join("\0", @actual_keys) eq join("\0", @expected_keys);

    my %seen;
    for my $family_spec (
        [units => 'unit_id'], [configurations => 'configuration_id'],
        [types => 'type_id'], [endpoints => 'endpoint_id'],
        [domains => 'domain_id'], [transactions => 'transaction_id'],
        [events => 'event_id'], [protocols => 'protocol_id'],
        [observations => 'observation_id'], [probes => 'probe_id'],
        [backend_bindings => 'binding_id'],
        [unsupported_residue => 'residue_id'],
    ) {
        my ($family, $id_key) = @$family_spec;
        for my $record (@{$report->{$family} // []}) {
            my $id = $record->{$id_key};
            push @errors, _oracle_error(
                'VIAL_SCALE_BRIDGE_ID_ERROR',
                "missing or duplicate semantic identity in $family",
                "/$family",
            ) if !defined($id) || $seen{$id}++;
        }
    }

    my %mapped;
    $mapped{$_->{fact_path}}++ for @{$report->{source_map} // []};
    my @missing;
    for my $family (qw(
        units configurations types endpoints domains transactions events
        protocols observations probes backend_bindings unsupported_residue
    )) {
        for my $index (0 .. $#{$report->{$family} // []}) {
            _collect_unmapped(
                $report->{$family}[$index], "/$family/$index", \@missing, \%mapped,
            );
        }
    }
    push @errors, _oracle_error(
        'VIAL_SCALE_BRIDGE_SOURCE_MAP_ERROR',
        'bridge source map is not total and one-to-one',
        '/source_map',
    ) if @missing || grep { $_ != 1 } values %mapped;

    my %semantic = map { $_ => 1 } keys %seen;
    for my $index (0 .. $#{$report->{backend_bindings} // []}) {
        my $id = $report->{backend_bindings}[$index]{semantic_id};
        push @errors, _oracle_error(
            'VIAL_SCALE_BRIDGE_BINDING_ERROR',
            "backend binding $index names an unknown semantic identity",
            "/backend_bindings/$index/semantic_id",
        ) unless defined($id) && $semantic{$id};
    }
    return \@errors;
}

sub _collect_unmapped($value, $path, $missing, $mapped) {
    if (ref($value) eq 'HASH') {
        for my $key (sort keys %$value) {
            my $escaped = $key;
            $escaped =~ s/~/~0/g;
            $escaped =~ s{/}{~1}g;
            _collect_unmapped($value->{$key}, "$path/$escaped", $missing, $mapped);
        }
        return;
    }
    if (ref($value) eq 'ARRAY') {
        push @$missing, $path unless $mapped->{$path};
        _collect_unmapped($value->[$_], "$path/$_", $missing, $mapped)
            for 0 .. $#$value;
        return;
    }
    push @$missing, $path unless $mapped->{$path};
}

sub _vial_resolution_errors($checked, $report) {
    my @errors;
    my %record = (
        (map { $_->{unit_id} => $_ } @{$report->{units}}),
        (map { $_->{domain_id} => $_ } @{$report->{domains}}),
        (map { $_->{endpoint_id} => $_ } @{$report->{endpoints}}),
        (map { $_->{probe_id} => $_ } @{$report->{probes}}),
        (map { $_->{transaction_id} => $_ } @{$report->{transactions}}),
    );
    my %type = map { $_->{type_id} => $_ } @{$report->{types}};
    my $refs = $checked->{semantic_report}{unresolved_bridge_refs} // [];
    for my $index (0 .. $#$refs) {
        my $ref = $refs->[$index];
        my $actual = $record{$ref->{bridge_ref}};
        if (!$actual) {
            push @errors, _oracle_error(
                'VIAL_SCALE_BRIDGE_REFERENCE_ERROR',
                "VIAL bridge reference '$ref->{bridge_ref}' does not resolve",
                "/vial_bridge_refs/$index",
            );
            next;
        }
        push @errors, _oracle_error(
            'VIAL_SCALE_BRIDGE_REFERENCE_ERROR',
            "VIAL bridge reference '$ref->{bridge_ref}' has mismatched access",
            "/vial_bridge_refs/$index/access",
        ) if defined($ref->{access}) && ($actual->{access} // '') ne $ref->{access};
        if (ref($ref->{expected_type}) eq 'HASH') {
            my $actual_type = $type{$actual->{type_id}};
            my $expected = ref($ref->{expected_type}{resolved}) eq 'HASH'
                ? $ref->{expected_type}{resolved} : $ref->{expected_type};
            my $expected_four_state = exists($expected->{four_state})
                ? $expected->{four_state} : 1;
            push @errors, _oracle_error(
                'VIAL_SCALE_BRIDGE_REFERENCE_ERROR',
                "VIAL bridge reference '$ref->{bridge_ref}' has mismatched type",
                "/vial_bridge_refs/$index/expected_type",
            ) unless $actual_type
                && ($actual_type->{kind} // '') eq 'logic'
                && ($actual_type->{width} // -1) == $expected->{width}
                && ($actual_type->{signed} ? 1 : 0) == $expected->{signed}
                && (($actual_type->{state_domain} // '') eq 'four_state')
                    == ($expected_four_state ? 1 : 0);
        }
    }
    return \@errors;
}

sub _rejection_evaluation($construction, $diagnostics) {
    my $spec = $construction->{specification};
    my ($axis, $level) = @{$spec}{qw(primary_axis level)};
    my $first = $diagnostics->[0] // {};
    my $expected = (($level eq 'qualification_candidate_v1'
            || $level eq 'limit_v1' || $level eq 'over_limit_v1')
            && ($first->{code} // '') eq 'HIAL_VIAL_BRIDGE_LIMIT_ERROR')
        || ($level eq 'over_limit_v1'
            && ($axis eq 'selected_units' || $axis eq 'selected_domains')
            && ($first->{code} // '') eq 'HIAL_VIAL_BRIDGE_CAPABILITY_ERROR');
    my $oracle = $expected ? [] : [_oracle_error(
        'VIAL_SCALE_BRIDGE_OUTCOME_ERROR',
        'workload was rejected before its declared authoritative outcome',
        $first->{path} // '/',
    )];
    my $layers = $level eq 'reference_v1'
        ? [qw(IAL2 IAL1 IAL0)] : [qw(IAL1 IAL0)];
    return _evaluation({
        ok => $expected ? JSON::PP::true : JSON::PP::false,
        status => $expected ? 'expected_rejection' : 'oracle_failure',
        schema => $EVALUATION_SCHEMA,
        schema_version => 1,
        workload_identity => $construction->{workload_identity},
        family => $FAMILY,
        level => $level,
        primary_axis => $axis,
        requested_counts => _clone($spec->{requested_counts}),
        observed_outcome => 'rejected',
        metrics => {},
        manifest_sha256 => undef,
        report_sha256 => undef,
        review_layers => $layers,
        input_identities => _clone($construction->{input_identities}),
        diagnostics => [@{$diagnostics // []}, @$oracle],
        contract_discrepancies => $expected ? [{
            code => $first->{code},
            path => $first->{path},
            authority => 'earliest_declared_bridge_cap',
        }] : [],
    });
}

sub _evaluation_failure($construction, $code, $message, $path) {
    my $spec = $construction->{specification};
    return _evaluation({
        ok => JSON::PP::false,
        status => 'error',
        schema => $EVALUATION_SCHEMA,
        schema_version => 1,
        workload_identity => $construction->{workload_identity},
        family => $FAMILY,
        level => $spec->{level},
        primary_axis => $spec->{primary_axis},
        requested_counts => _clone($spec->{requested_counts}),
        observed_outcome => 'route_error',
        metrics => {},
        manifest_sha256 => undef,
        report_sha256 => undef,
        review_layers => [],
        input_identities => _clone($construction->{input_identities}),
        diagnostics => [_oracle_error($code, $message, $path)],
        contract_discrepancies => [],
    });
}

sub _oracle_error($code, $message, $path) {
    return {
        code => $code,
        severity => 'error',
        message => $message,
        path => $path,
    };
}

sub _input($relative_path, $role, $content) {
    return {
        relative_path => $relative_path,
        role => $role,
        encoding => 'utf-8',
        content => $content,
    };
}

sub _validate_reference($text, $bytes, $sha256, $label) {
    confess "$label reference text must be one scalar\n"
        unless defined($text) && !ref($text);
    confess "$label reference text does not match its checked anchor\n"
        unless bytes::length($text) == $bytes && sha256_hex($text) eq $sha256;
}

sub _evaluation($value) {
    my %expected = map { $_ => 1 } @EVALUATION_KEYS;
    confess "bridge evaluation has unknown key(s)\n"
        if grep { !$expected{$_} } keys %$value;
    confess "bridge evaluation is missing key(s)\n"
        if grep { !exists($value->{$_}) } @EVALUATION_KEYS;
    return _clone($value);
}

sub _confess_exact_keys($value, $keys, $label) {
    my %expected = map { $_ => 1 } @$keys;
    my @unknown = sort grep { !$expected{$_} } keys %$value;
    my @missing = grep { !exists($value->{$_}) } @$keys;
    confess "$label has unknown key '$unknown[0]'\n" if @unknown;
    confess "$label is missing key '$missing[0]'\n" if @missing;
}

sub _exact_invocant($class, $method) {
    confess __PACKAGE__ . "->$method requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
}

sub _sanitize_exception($error) {
    my $message = defined($error) ? "$error" : 'unknown bridge route failure';
    $message =~ s/\s+at\s+\S+\s+line\s+\d+\.?(?:.*)\z//s;
    $message =~ s{(?:[A-Za-z]:)?[/\\][^\s:]+[/\\][^\s:]+}{<host-path>}g;
    $message =~ s/[\r\n]+/ /g;
    $message =~ s/\s+/ /g;
    $message =~ s/\A\s+|\s+\z//g;
    return length($message) ? $message : 'unknown bridge route failure';
}

sub _clone($value) {
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    return {map { $_ => _clone($value->{$_}) } sort keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    confess 'bridge evaluation contains an unsupported reference' if ref($value);
    return $value;
}

1;
