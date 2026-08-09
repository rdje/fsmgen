#!/usr/bin/env perl

use strict;
use warnings;

use bytes ();
use Digest::SHA qw(sha256_hex);
use File::Basename qw(basename);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::IAL2::PPIF;
use FSM::Adapter::ISF;
use FSM::HIAL::VIALBridge::Builder;
use FSM::HIAL::VIALBridge::Manifest;
use FSM::HIAL::VIALBridge::Report;
use FSM::Pipeline::HDLGenerator;
use FSM::Scheduler::ISF;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::HIALVIALBridgeContract qw(
    build_hial_vial_bridge_contract
    hial_vial_bridge_contract_keys
);
use FSM::Support::RegressionCorpus qw(regression_corpus_entries);
use FSM::VIAL::Parser;

my $json = JSON::PP->new->canonical;
my $ial0_path = repo_path('fsm/ahb_lite_subordinate.fsm');
my $ial1_path = repo_path('isf/verification_observation_metadata.isf');
my $ial2_path = repo_path('ppif/ahb_lite_subordinate.ppif');
my $vial_path = repo_path('vial/ahb_subordinate_base_output_arbitration.vial');

my $ial0_text = slurp_raw($ial0_path);
my $ial1_text = slurp_raw($ial1_path);
my $ial2_text = slurp_raw($ial2_path);
my $vial_text = slurp_raw($vial_path);

my $ial0_hdl = FSM::Pipeline::HDLGenerator->new(
    debug_level => 0,
    target_language => 'systemverilog',
    quiet => 1,
    strict_mode => 1,
)->generate_hdl_from_file($ial0_path);

my $isf_adapter = FSM::Adapter::ISF->new();
my $scheduler = FSM::Scheduler::ISF->new();
my $ial1_actor = $isf_adapter->parse_source($ial1_text, basename($ial1_path));
my $ial1_schedule = $json->decode($scheduler->report($ial1_actor));
my $ial1_lowered = $scheduler->lower($ial1_actor);
my $ial1_fsm_text = $ial1_lowered->{files}{'verification_observation_metadata.fsm'};

my $ial2_result = FSM::Adapter::IAL2::PPIF->new()->parse_source(
    $ial2_text,
    'ppif/ahb_lite_subordinate.ppif',
);
my $generated_ial1_text = $ial2_result->{generated_ial1}{text};
my $generated_ial1_actor = $isf_adapter->parse_source(
    $generated_ial1_text,
    $ial2_result->{generated_ial1}{name},
);
my $generated_ial0_text = $ial2_result->{generated_ial0}{files}{'ahb_lite_subordinate.fsm'};

my $ial0_route = {
    profile => 'core_single_unit_v1',
    authored_source => source_record($ial0_text, 'fsm/ahb_lite_subordinate.fsm'),
    hdl_result => $ial0_hdl,
    backend_names => backend_names(
        'ahb_lite_subordinate',
        [qw(clk rst_n HSEL HREADY HADDR HTRANS HWRITE HSIZE HWDATA wait_cycles HREADYOUT HRESP HRDATA)],
        [],
        [],
    ),
};

my $ial1_route = {
    profile => 'core_single_unit_v1',
    authored_source => source_record($ial1_text, 'isf/verification_observation_metadata.isf'),
    actor => $ial1_actor,
    schedule_report => $ial1_schedule,
    generated_ial0 => source_record($ial1_fsm_text, undef, 'verification_observation_metadata.fsm'),
    backend_names => backend_names(
        'verification_observation_metadata',
        [qw(clk rst_n valid data ready done)],
        [],
        [],
    ),
};

my $ial2_route = {
    profile => 'core_single_unit_v1',
    authored_source => source_record($ial2_text, 'ppif/ahb_lite_subordinate.ppif'),
    generated_ial1 => {
        source => source_record($generated_ial1_text, undef, 'ahb_lite_subordinate.isf'),
        actor => $generated_ial1_actor,
        schedule_report => $ial2_result->{generated_ial1_schedule_report},
    },
    generated_ial0 => source_record($generated_ial0_text, undef, 'ahb_lite_subordinate.fsm'),
    backend_names => backend_names(
        'ahb_lite_subordinate',
        [qw(clk rst_n HSEL HREADY HADDR HTRANS HWRITE HSIZE HWDATA wait_cycles HREADYOUT HRESP HRDATA)],
        [],
        ['reg_data_q'],
    ),
};

my $ial0 = FSM::HIAL::VIALBridge::Builder->build_ial0($ial0_route);
my $ial1 = FSM::HIAL::VIALBridge::Builder->build_ial1($ial1_route);
my $ial2 = FSM::HIAL::VIALBridge::Builder->build_ial2_via_ial1($ial2_route);

subtest 'canonical HIAL review routes produce closed versioned manifests' => sub {
    ok($ial0->{ok}, 'direct IAL0 bridge construction succeeds');
    diag($json->encode($ial0->{diagnostics})) unless $ial0->{ok};
    ok($ial1->{ok}, 'direct IAL1 bridge construction succeeds');
    diag($json->encode($ial1->{diagnostics})) unless $ial1->{ok};
    ok($ial2->{ok}, 'IAL2 bridge construction succeeds only through generated and reparsed IAL1');
    diag($json->encode($ial2->{diagnostics})) unless $ial2->{ok};

    for my $case (
        ['IAL0', $ial0, [qw(IAL0)]],
        ['IAL1', $ial1, [qw(IAL1 IAL0)]],
        ['IAL2', $ial2, [qw(IAL2 IAL1 IAL0)]],
    ) {
        my ($label, $result, $layers) = @$case;
        isa_ok($result->{manifest}, 'FSM::HIAL::VIALBridge::Manifest', "$label manifest");
        is_deeply(
            [sort keys %{$result->{report}}],
            [sort @{FSM::HIAL::VIALBridge::Manifest->top_level_keys()}],
            "$label report has exactly the selected top-level keys",
        );
        is($result->{report}{schema}, 'fsmgen.hial_vial_bridge_manifest.v1', "$label schema is versioned");
        is($result->{report}{profile}, 'core_single_unit_v1', "$label profile is bounded");
        like($result->{report}{manifest_id}, qr{\Abridge/[0-9a-f]{64}\z}, "$label identity is stable-form SHA-256");
        is_deeply(
            [map { $_->{layer} } @{$result->{report}{review_route}{stages}}],
            $layers,
            "$label preserves its canonical review route",
        );
        ok(!$result->{report}{review_route}{direct_ial2_to_verification}, "$label forbids direct IAL2-to-verification bypass");
        is_deeply($result->{diagnostics}, [], "$label success has no diagnostics");
        ok(!contains_non_json_reference($result->{report}), "$label report is JSON-safe plain data");
        source_map_is_total($result->{report}, $label);
    }

    is(scalar(@{$ial0->{report}{units}}), 1, 'IAL0 projects one root unit');
    is(scalar(@{$ial0->{report}{endpoints}}), 13, 'IAL0 projects clock, reset, and all public ports');
    is(scalar(@{$ial0->{report}{domains}}), 1, 'IAL0 projects the explicit system domain');
    is_deeply($ial0->{report}{protocols}, [], 'IAL0 does not infer a protocol from signal spelling');
    is_deeply($ial0->{report}{observations}, [], 'IAL0 does not invent observations');
    is_deeply($ial0->{report}{probes}, [], 'IAL0 does not invent probes');

    is($ial1->{report}{transactions}[0]{transaction_id}, 'transaction/main', 'IAL1 projects its declared transaction');
    is_deeply(
        [map { $_->{event_id} } @{$ial1->{report}{events}}],
        [qw(event/main/complete event/main/on)],
        'IAL1 projects on and completion predicates as stable events',
    );
    is($ial1->{report}{observations}[0]{observation_id}, 'observation/link_rx', 'IAL1 projects passive observation intent');
    is_deeply(
        $ial1->{report}{observations}[0]{endpoint_ids},
        [qw(endpoint/valid endpoint/ready endpoint/data)],
        'IAL1 preserves authored observation endpoint order',
    );
    is_deeply($ial1->{report}{protocols}, [], 'plain IAL1 does not infer protocol metadata');

    record_keys_are($ial2->{report}{producer}, [qw(name contract_source reference_implementation)], 'producer');
    record_keys_are($ial2->{report}{sources}[0], [qw(source_id layer kind role repository_path artifact_name content_sha256 byte_length line_count)], 'source');
    record_keys_are($ial2->{report}{review_route}, [qw(authored_layer direct_ial2_to_verification stages)], 'review route');
    record_keys_are($ial2->{report}{review_route}{stages}[0], [qw(layer source_id review_artifact_ids)], 'review stage');
    record_keys_are($ial2->{report}{review_artifacts}[0], [qw(artifact_id layer format artifact_name repository_path source_id content_sha256 generated entry)], 'review artifact');
    record_keys_are($ial2->{report}{units}[0], [qw(unit_id name parent_unit_id instance_name source_layer configuration_ids endpoint_ids domain_ids transaction_ids protocol_ids observation_ids probe_ids backend_binding_ids)], 'unit');
    record_keys_are($ial2->{report}{types}[0], [qw(type_id name kind state_domain signed width enum_members fields element_type_id length)], 'type');
    record_keys_are($ial2->{report}{endpoints}[0], [qw(endpoint_id unit_id name direction type_id role access domain_id backend_binding_ids)], 'endpoint');
    record_keys_are($ial2->{report}{domains}[0], [qw(domain_id unit_id name clock_endpoint_id active_edge reset_endpoint_id reset_kind reset_polarity)], 'domain');
    record_keys_are($ial2->{report}{transactions}[0], [qw(transaction_id unit_id name type_id protocol_id ordering correlation fields event_ids)], 'transaction');
    record_keys_are($ial2->{report}{transactions}[0]{fields}[0], [qw(name type_id endpoint_id direction phase_role)], 'transaction field');
    record_keys_are($ial2->{report}{events}[0], [qw(event_id transaction_id name kind phase expression required_endpoint_ids required_probe_ids)], 'event');
    record_keys_are($ial2->{report}{protocols}[0], [qw(protocol_id unit_id name profile revision role transaction_ids facts)], 'protocol');
    record_keys_are($ial2->{report}{protocols}[0]{facts}[0], [qw(name value)], 'protocol fact');
    record_keys_are($ial1->{report}{observations}[0], [qw(observation_id unit_id name role domain_id endpoint_ids)], 'observation');
    record_keys_are($ial2->{report}{probes}[0], [qw(probe_id unit_id name type_id access domain_id adapter_requirement backend_binding_ids)], 'probe');
    record_keys_are($ial2->{report}{backend_bindings}[0], [qw(binding_id semantic_id target_language target_kind target_name status required_capabilities)], 'backend binding');
    record_keys_are($ial2->{report}{unsupported_residue}[0], [qw(residue_id source_id detail owner required_capability)], 'unsupported residue');
    record_keys_are($ial2->{report}{source_map}[0], [qw(fact_path semantic_id field_path provenance)], 'source-map record');
    record_keys_are($ial2->{report}{source_map}[0]{provenance}[0], [qw(source_id review_artifact_id precision semantic_path start_byte end_byte start_line start_column end_line end_column derivation)], 'source-map provenance');
};

subtest 'AHB annotation is the sole protocol authority after IAL1 reparsing' => sub {
    like($generated_ial1_text, qr/\(verification-bridge\b/, 'generated IAL1 carries additive bridge metadata');
    is($ial2->{report}{units}[0]{unit_id}, 'unit/ahb_lite_subordinate', 'AHB unit ID is exact');
    is($ial2->{report}{domains}[0]{domain_id}, 'domain/ahb_bus', 'AHB domain ID is exact');
    is($ial2->{report}{transactions}[0]{transaction_id}, 'transaction/ahb_write', 'AHB transaction ID is exact');
    is($ial2->{report}{transactions}[0]{type_id}, undef, 'scalar-only profile keeps aggregate transaction type null');
    is_deeply(
        [map { $_->{name} } @{$ial2->{report}{transactions}[0]{fields}}],
        [qw(address transfer write size data wait_cycles)],
        'AHB transaction fields retain their selected semantic order',
    );
    is_deeply(
        [map { $_->{name} } @{$ial2->{report}{events}}],
        [sort qw(requested accepted captured held completed error)],
        'AHB publishes the exact six event family in deterministic ID order',
    );
    my ($accepted_event) = grep { $_->{name} eq 'accepted' } @{$ial2->{report}{events}};
    record_keys_are($accepted_event->{expression}, [qw(kind operator operands value reference_kind semantic_id)], 'canonical event expression');
    record_keys_are($accepted_event->{expression}{operands}[0], [qw(kind operator operands value reference_kind semantic_id)], 'canonical event expression operand');
    is($ial2->{report}{protocols}[0]{protocol_id}, 'protocol/ahb_lite_subordinate', 'AHB protocol ID is exact');
    is($ial2->{report}{probes}[0]{probe_id}, 'probe/reg_data_q', 'AHB verification probe ID is exact');
    is($ial2->{report}{probes}[0]{access}, 'verification_probe', 'probe is not projected as a public DUT endpoint');
    is($ial2->{report}{probes}[0]{adapter_requirement}, 'equivalent_adapter_required', 'probe requires a target adapter');
    is_deeply(
        [map { $_->{residue_id} } @{$ial2->{report}{unsupported_residue}}],
        [map { "residue/$_" } qw(
            ahb_subordinate_profile_alias_deferred
            ahb_interconnect_generation_deferred
            ahb_subordinate_optional_signal_residue
            ahb_burst_seq_support_deferred
            ahb_verification_output_deferred
        )],
        'all five unsupported residue IDs survive in source order',
    );
    is_deeply(
        $ial2->{report}{required_capabilities},
        [qw(
            hial_vial.bridge_manifest.v1
            hial_vial.bridge_probe.equivalent_adapter_required
            hial_vial.bridge_profile.core_single_unit_v1
            hial_vial.bridge_protocol.ahb_subordinate_v1
            hial_vial.bridge_source.ial2_via_generated_ial1
        )],
        'AHB manifest claims only exercised bridge capabilities',
    );

    my %source_layers = map { $_->{layer} => 1 } @{$ial2->{report}{sources}};
    ok($source_layers{IAL2} && $source_layers{IAL1} && $source_layers{IAL0}, 'AHB provenance carries all three review layers');
    my ($generated_fact_map) = grep { $_->{fact_path} eq '/protocols/0/facts/0/value' } @{$ial2->{report}{source_map}};
    is_deeply(
        [map { $_->{source_id} } @{$generated_fact_map->{provenance}}],
        [qw(source/authored source/generated_ial1)],
        'generated protocol fact retains authored IAL2 plus generated IAL1 provenance',
    );
};

subtest 'every checked VIAL bridge reference resolves by ID, access, and type' => sub {
    my $checked = FSM::VIAL::Parser->check_source({
        text => $vial_text,
        source_name => 'vial/ahb_subordinate_base_output_arbitration.vial',
        source_catalog => {},
    });
    ok($checked->{ok}, 'checked VIAL fixture remains semantically valid');
    my %record = (
        (map { $_->{unit_id} => $_ } @{$ial2->{report}{units}}),
        (map { $_->{domain_id} => $_ } @{$ial2->{report}{domains}}),
        (map { $_->{endpoint_id} => $_ } @{$ial2->{report}{endpoints}}),
        (map { $_->{probe_id} => $_ } @{$ial2->{report}{probes}}),
        (map { $_->{transaction_id} => $_ } @{$ial2->{report}{transactions}}),
    );
    my %type = map { $_->{type_id} => $_ } @{$ial2->{report}{types}};
    is(scalar(@{$checked->{semantic_report}{unresolved_bridge_refs}}), 7, 'VIAL fixture declares seven opaque bridge references');
    for my $ref (@{$checked->{semantic_report}{unresolved_bridge_refs}}) {
        my $resolved = $record{$ref->{bridge_ref}};
        ok($resolved, "$ref->{bridge_ref} resolves exactly");
        next unless $resolved;
        is($resolved->{access}, $ref->{access}, "$ref->{bridge_ref} access matches")
            if defined $ref->{access};
        if (ref($ref->{expected_type}) eq 'HASH') {
            my $actual = $type{$resolved->{type_id}};
            is($actual->{kind}, 'logic', "$ref->{bridge_ref} resolves to logic");
            is($actual->{width}, $ref->{expected_type}{width}, "$ref->{bridge_ref} width matches");
            is($actual->{signed} ? 1 : 0, $ref->{expected_type}{signed}, "$ref->{bridge_ref} signedness matches");
            is($actual->{state_domain}, 'four_state', "$ref->{bridge_ref} preserves four-state observability");
        }
    }
};

subtest 'generation remains deterministic, immutable, and behavior-preserving' => sub {
    my $second = FSM::HIAL::VIALBridge::Builder->build_ial2_via_ial1($ial2_route);
    is($json->encode($second->{report}), $json->encode($ial2->{report}), 'same route produces byte-identical canonical report JSON');

    my $copy = $ial2->{manifest}->as_hashref;
    $copy->{units}[0]{name} = 'mutated';
    is($ial2->{manifest}->get('units')->[0]{name}, 'ahb_lite_subordinate', 'manifest accessor is defensively copied');
    my $standalone_report = FSM::HIAL::VIALBridge::Report->build($ial2->{manifest});
    $standalone_report->{protocols}[0]{facts}[0]{value} = 'mutated';
    isnt(FSM::HIAL::VIALBridge::Report->build($ial2->{manifest})->{protocols}[0]{facts}[0]{value}, 'mutated', 'report does not share nested mutable storage');
    my $forged = eval {
        FSM::HIAL::VIALBridge::Manifest->_from_builder(
            $ial2->{report},
            'FSM::HIAL::VIALBridge::Builder',
        );
        1;
    };
    ok(!$forged, 'manifest construction remains Builder-owned despite a copied token string');

    is(bytes::length($generated_ial1_text), 4174, 'generated IAL1 additive annotation has the selected byte length');
    is(sha256_hex($generated_ial1_text), 'b0f3446874367787d0dd134701ff9e89a3b24af6ef9c03d6eb9dc484093f9e4c', 'generated IAL1 annotation is byte deterministic');
    is(bytes::length($generated_ial0_text), 5854, 'generated IAL0 byte length is unchanged');
    is(sha256_hex($generated_ial0_text), '3d8fa7ac7c3a7f2c9ca063aca2cf707106b511219243d8b277ac3e2e8cf47bcf', 'generated IAL0 bytes are unchanged by metadata');

    my $sv = $ial0_hdl->{hdl_code};
    $sv =~ s{^// Date: .*\n}{// Date: <normalized>\n}m;
    is(sha256_hex($sv), '95dbfc0fb7efecc5b1a04f98365cacad3dcb250d9c69523562368aebe8cfd28c', 'direct SystemVerilog HIAL output is semantically stable after date normalization');
    my $vhdl = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'vhdl',
        quiet => 1,
        strict_mode => 1,
    )->generate_hdl_from_file($ial0_path)->{hdl_code};
    is(sha256_hex($vhdl), 'ab668d3104b9f8f75f7cb7a92e819a3645a13d552d71995d53280317c0ca87aa', 'direct VHDL HIAL output is byte stable');
};

subtest 'malformed routes and annotations fail closed with sanitized diagnostics' => sub {
    bridge_failure(
        'direct PPIF AST bypass',
        'HIAL_VIAL_BRIDGE_ROUTE_ERROR',
        FSM::HIAL::VIALBridge::Builder->build_ial2_via_ial1({%$ial2_route, ppif_ast => {}}),
    );
    bridge_failure(
        'content identity mismatch',
        'HIAL_VIAL_BRIDGE_ROUTE_ERROR',
        FSM::HIAL::VIALBridge::Builder->build_ial2_via_ial1({
            %$ial2_route,
            authored_source => {%{$ial2_route->{authored_source}}, content_sha256 => ('0' x 64)},
        }),
    );
    bridge_failure(
        'unsafe authored path',
        'HIAL_VIAL_BRIDGE_ROUTE_ERROR',
        FSM::HIAL::VIALBridge::Builder->build_ial2_via_ial1({
            %$ial2_route,
            authored_source => {%{$ial2_route->{authored_source}}, repository_path => '/outside-repository/unsafe.ppif'},
        }),
    );
    bridge_failure(
        'raw target hierarchy',
        'HIAL_VIAL_BRIDGE_ACCESS_ERROR',
        FSM::HIAL::VIALBridge::Builder->build_ial2_via_ial1({
            %$ial2_route,
            backend_names => {
                %{$ial2_route->{backend_names}},
                systemverilog => {
                    %{$ial2_route->{backend_names}{systemverilog}},
                    probes => {reg_data_q => 'dut.reg_data_q'},
                },
            },
        }),
    );

    my $tampered_actor = clone_json($generated_ial1_actor);
    $tampered_actor->{verification_bridge}{protocol}{facts}[0]{value} = 'wrong';
    my $tampered_report = clone_json($ial2_result->{generated_ial1_schedule_report});
    $tampered_report->{verification_bridge} = clone_json($tampered_actor->{verification_bridge});
    bridge_failure(
        'unknown AHB fact value',
        'HIAL_VIAL_BRIDGE_ANNOTATION_ERROR',
        FSM::HIAL::VIALBridge::Builder->build_ial2_via_ial1({
            %$ial2_route,
            generated_ial1 => {
                %{$ial2_route->{generated_ial1}},
                actor => $tampered_actor,
                schedule_report => $tampered_report,
            },
        }),
    );

    my $missing_bridge_actor = clone_json($generated_ial1_actor);
    $missing_bridge_actor->{verification_bridge} = undef;
    my $missing_bridge_report = clone_json($ial2_result->{generated_ial1_schedule_report});
    $missing_bridge_report->{verification_bridge} = undef;
    bridge_failure(
        'missing reparsed IAL1 bridge annotation',
        'HIAL_VIAL_BRIDGE_ANNOTATION_ERROR',
        FSM::HIAL::VIALBridge::Builder->build_ial2_via_ial1({
            %$ial2_route,
            generated_ial1 => {
                %{$ial2_route->{generated_ial1}},
                actor => $missing_bridge_actor,
                schedule_report => $missing_bridge_report,
            },
        }),
    );

    my $wrong_width_actor = clone_json($generated_ial1_actor);
    (grep { $_->{name} eq 'HADDR' } @{$wrong_width_actor->{interface}{inputs}})[0]{width} = 31;
    bridge_failure(
        'wrong AHB endpoint width',
        'HIAL_VIAL_BRIDGE_ANNOTATION_ERROR',
        FSM::HIAL::VIALBridge::Builder->build_ial2_via_ial1({
            %$ial2_route,
            generated_ial1 => {
                %{$ial2_route->{generated_ial1}},
                actor => $wrong_width_actor,
            },
        }),
    );

    my $wrong_phase_actor = clone_json($generated_ial1_actor);
    $wrong_phase_actor->{verification_bridge}{transaction}{events}[1]{phase} = 'react';
    my $wrong_phase_report = clone_json($ial2_result->{generated_ial1_schedule_report});
    $wrong_phase_report->{verification_bridge} = clone_json($wrong_phase_actor->{verification_bridge});
    bridge_failure(
        'wrong AHB event phase',
        'HIAL_VIAL_BRIDGE_ANNOTATION_ERROR',
        FSM::HIAL::VIALBridge::Builder->build_ial2_via_ial1({
            %$ial2_route,
            generated_ial1 => {
                %{$ial2_route->{generated_ial1}},
                actor => $wrong_phase_actor,
                schedule_report => $wrong_phase_report,
            },
        }),
    );

    my $wrong_access_actor = clone_json($generated_ial1_actor);
    $wrong_access_actor->{verification_bridge}{probes}[0]{access} = 'write_only';
    my $wrong_access_report = clone_json($ial2_result->{generated_ial1_schedule_report});
    $wrong_access_report->{verification_bridge} = clone_json($wrong_access_actor->{verification_bridge});
    bridge_failure(
        'wrong AHB probe access',
        'HIAL_VIAL_BRIDGE_ACCESS_ERROR',
        FSM::HIAL::VIALBridge::Builder->build_ial2_via_ial1({
            %$ial2_route,
            generated_ial1 => {
                %{$ial2_route->{generated_ial1}},
                actor => $wrong_access_actor,
                schedule_report => $wrong_access_report,
            },
        }),
    );

    my $multi_domain_actor = clone_json($ial1_actor);
    $multi_domain_actor->{clock_domains} = {bus => {}};
    bridge_failure(
        'unsupported multi-domain actor',
        'HIAL_VIAL_BRIDGE_CAPABILITY_ERROR',
        FSM::HIAL::VIALBridge::Builder->build_ial1({%$ial1_route, actor => $multi_domain_actor}),
    );

    my $typed_actor = clone_json($ial1_actor);
    $typed_actor->{type_declarations} = [{name => 'aggregate_t', kind => 'record'}];
    bridge_failure(
        'unsupported authored aggregate type',
        'HIAL_VIAL_BRIDGE_CAPABILITY_ERROR',
        FSM::HIAL::VIALBridge::Builder->build_ial1({%$ial1_route, actor => $typed_actor}),
    );

    my $parse_ok = eval {
        my $bad = $generated_ial1_text;
        $bad =~ s{(\(residue ahb_verification_output_deferred\))}{$1\n  $1};
        $isf_adapter->parse_source($bad, 'duplicate-residue.isf');
        1;
    };
    ok(!$parse_ok, 'duplicate generated annotation residue is rejected during ordinary IAL1 parsing');
    like($@, qr/verification-bridge has duplicate residue/, 'duplicate residue diagnostic names the annotation defect');

    my $rising_ok = eval {
        my $bad = $generated_ial1_text;
        $bad =~ s/\(event captured rising sample ahb_phase_pending_q\)/(event captured rising sample reg_data_q)/;
        $isf_adapter->parse_source($bad, 'wide-rising-source.isf');
        1;
    };
    ok(!$rising_ok, 'rising annotation event rejects a wide signal reference');
    like($@, qr/rising event 'captured' requires one scalar one-bit signal reference/, 'rising-event diagnostic names the one-bit contract');

    my $operator_ok = eval {
        my $bad = $generated_ial1_text;
        $bad =~ s/\(event accepted predicate sample \(& /\(event accepted predicate sample \(unknown_op /;
        $isf_adapter->parse_source($bad, 'unknown-bridge-operator.isf');
        1;
    };
    ok(!$operator_ok, 'bridge predicate rejects an operator outside the closed IAL1 expression family');
    like($@, qr/expression uses unsupported operator 'unknown_op'/, 'unknown-operator diagnostic names the expression defect');

    my $predicate_width_ok = eval {
        my $bad = $generated_ial1_text;
        $bad =~ s/\(event completed predicate sample HREADYOUT\)/(event completed predicate sample HRDATA)/;
        $isf_adapter->parse_source($bad, 'wide-bridge-predicate.isf');
        1;
    };
    ok(!$predicate_width_ok, 'bridge predicate rejects a wide non-Boolean expression');
    like($@, qr/predicate event 'completed' requires a one-bit Boolean expression/, 'wide-predicate diagnostic names the Boolean contract');

    my $large_actor = clone_json($ial1_actor);
    $large_actor->{interface}{inputs} = [
        @{$large_actor->{interface}{inputs}},
        map { {name => sprintf('limit_input_%04d', $_), width => 1, signed => 0} } 0 .. 4096
    ];
    my @large_names = (qw(clk rst_n valid data ready done), map { sprintf('limit_input_%04d', $_) } 0 .. 4096);
    bridge_failure(
        'endpoint safety limit',
        'HIAL_VIAL_BRIDGE_LIMIT_ERROR',
        FSM::HIAL::VIALBridge::Builder->build_ial1({
            %$ial1_route,
            actor => $large_actor,
            backend_names => backend_names('verification_observation_metadata', \@large_names, [], []),
        }),
    );
};

subtest 'capability and support accounting expose only the private bridge seam' => sub {
    my $contract = build_hial_vial_bridge_contract();
    is_deeply([sort keys %$contract], [sort @{hial_vial_bridge_contract_keys()}], 'bridge capability contract is closed');
    is($contract->{status}, 'shipped_private_in_process', 'bridge is discoverable as private in-process support');
    is_deeply(
        $contract->{limits},
        {
            sources => 3,
            review_artifacts => 3,
            units => 1,
            domains => 1,
            configurations => 4096,
            types => 4096,
            endpoints => 4096,
            transactions => 256,
            events => 2048,
            protocols => 16,
            observations => 256,
            probes => 256,
            backend_bindings => 16384,
            unsupported_residue => 4096,
            source_map => 65536,
            serialized_manifest_bytes => 16_777_216,
        },
        'every selected private bridge safety limit is discoverable exactly',
    );
    ok(!$contract->{writes_files}, 'bridge contract claims no file output');
    ok(!$contract->{public_embedding_api}, 'bridge contract claims no supported embedding API');
    my $manifest = build_capability_manifest();
    is_deeply($manifest->{language_surface}{hial_vial_bridge}, $contract, 'language surface publishes the exact bridge capability contract');

    my ($entry) = grep { $_->{id} eq 'intent.ppif_ahb_lite_subordinate' } regression_corpus_entries();
    is_deeply($entry->{private_capabilities}, $ial2->{report}{required_capabilities}, 'AHB support entry matches the exercised bridge capability set');
    my ($published_entry) = grep { $_->{id} eq 'intent.ppif_ahb_lite_subordinate' } @{$manifest->{support_accounting}{catalog_entries}};
    is_deeply($published_entry->{private_capabilities}, $entry->{private_capabilities}, 'public support accounting preserves the sanitized private bridge capabilities');
    is_deeply($published_entry->{private_nonclaims}, $entry->{private_nonclaims}, 'public support accounting preserves the sanitized private bridge nonclaims');
    my %nonclaim = map { $_ => 1 } @{$entry->{private_nonclaims}};
    ok($nonclaim{vial_binding} && $nonclaim{execution_plan} && $nonclaim{uvm} && $nonclaim{vhdl_methodology}, 'support entry preserves the principal backend/runtime nonclaims');
};

done_testing();

sub repo_path {
    my ($relative) = @_;
    return File::Spec->catfile($FindBin::Bin, '..', split m{/}, $relative);
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "Cannot read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $text;
}

sub source_record {
    my ($text, $repository_path, $artifact_name) = @_;
    $artifact_name //= basename($repository_path);
    my $line_count = length($text) ? (() = $text =~ /\n/g) + ($text =~ /\n\z/ ? 0 : 1) : 0;
    return {
        text => $text,
        repository_path => $repository_path,
        artifact_name => $artifact_name,
        content_sha256 => sha256_hex($text),
        byte_length => bytes::length($text),
        line_count => $line_count,
    };
}

sub backend_names {
    my ($unit, $endpoints, $configurations, $probes) = @_;
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

sub clone_json {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}

sub contains_non_json_reference {
    my ($value) = @_;
    return 0 unless ref($value);
    return 0 if ref($value) eq 'JSON::PP::Boolean';
    if (ref($value) eq 'HASH') {
        return scalar grep { contains_non_json_reference($value->{$_}) } keys %$value;
    }
    if (ref($value) eq 'ARRAY') {
        return scalar grep { contains_non_json_reference($_) } @$value;
    }
    return 1;
}

sub record_keys_are {
    my ($record, $keys, $label) = @_;
    is_deeply([sort keys %$record], [sort @$keys], "$label record has exactly the selected keys");
}

sub source_map_is_total {
    my ($report, $label) = @_;
    my %mapped;
    $mapped{$_->{fact_path}}++ for @{$report->{source_map}};
    is_deeply(
        [sort grep { $mapped{$_} != 1 } keys %mapped],
        [],
        "$label source map has exactly one record per mapped fact path",
    );
    my @missing;
    for my $family (qw(units configurations types endpoints domains transactions events protocols observations probes backend_bindings unsupported_residue)) {
        for my $index (0 .. $#{$report->{$family}}) {
            collect_paths($report->{$family}[$index], "/$family/$index", \@missing, \%mapped);
        }
    }
    is_deeply(\@missing, [], "$label source map covers every semantic scalar and array field");
}

sub collect_paths {
    my ($value, $path, $missing, $mapped) = @_;
    if (ref($value) eq 'HASH') {
        collect_paths($value->{$_}, "$path/" . pointer_escape($_), $missing, $mapped) for sort keys %$value;
        return;
    }
    if (ref($value) eq 'ARRAY') {
        push @$missing, $path unless $mapped->{$path};
        collect_paths($value->[$_], "$path/$_", $missing, $mapped) for 0 .. $#$value;
        return;
    }
    push @$missing, $path unless $mapped->{$path};
}

sub pointer_escape {
    my ($value) = @_;
    $value =~ s/~/~0/g;
    $value =~ s{/}{~1}g;
    return $value;
}

sub bridge_failure {
    my ($label, $code, $result) = @_;
    ok(!$result->{ok}, "$label fails closed");
    is($result->{manifest}, undef, "$label returns no partial manifest");
    is($result->{report}, undef, "$label returns no partial report");
    is(scalar(@{$result->{diagnostics}}), 1, "$label returns one stable diagnostic");
    is($result->{diagnostics}[0]{code}, $code, "$label uses $code");
    is_deeply(
        [sort keys %{$result->{diagnostics}[0]}],
        [sort qw(code category message source path span related)],
        "$label diagnostic shape is closed",
    );
    unlike($result->{diagnostics}[0]{message}, qr{(?:/Volumes/|/private/| at \S+\.pm line |stack)}, "$label diagnostic contains no machine path or Perl stack");
}
