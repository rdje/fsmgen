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

use FSM::Adapter::ISF;
use FSM::HIAL::VIALBridge::Builder;
use FSM::Scheduler::ISF;
use FSM::VIAL::ExecutionBuilder;
use FSM::VIAL::Parser;

my $json = JSON::PP->new->canonical(1)->utf8(1);
my $capability =
    'hial_vial.bridge_qualification.balanced_portable_v2';

my $hial_text = render_hial();
my $vial_text = render_vial();

subtest 'revision-2 bridge is direct, exact, and deterministic' => sub {
    my $first = build_route();
    ok($first->{bridge}{ok}, 'caller-sealed direct-IAL1 bridge succeeds');
    diag($json->encode($first->{bridge}{diagnostics}))
        unless $first->{bridge}{ok};
    return unless $first->{bridge}{ok};

    my $manifest = $first->{bridge}{manifest}->as_hashref;
    is_deeply(
        [map { $_->{layer} } @{$manifest->{review_route}{stages}}],
        [qw(IAL1 IAL0)],
        'balanced qualification retains the direct IAL1-to-IAL0 review route',
    );
    is_deeply(
        [map { scalar(@{$manifest->{$_}}) }
            qw(units domains endpoints transactions events probes)],
        [1, 1, 128, 16, 128, 32],
        'manifest carries the exact balanced structural shape',
    );
    is_deeply(
        [map { scalar(@{$_->{fields}}) } @{$manifest->{transactions}}],
        [(109) x 16],
        'every transaction alias carries exactly 109 endpoint-backed fields',
    );
    is_deeply(
        [map { $_->{correlation} } @{$manifest->{transactions}}],
        [('single_active') x 16],
        'all balanced aliases use the executable single-active correlation',
    );
    is_deeply($manifest->{unsupported_residue}, [],
        'balanced bridge retains no residue or padding record');
    ok(grep($_ eq $capability, @{$manifest->{required_capabilities}}),
        'manifest carries the dedicated revision-2 qualification capability');
    ok(!grep($_ eq 'hial_vial.bridge_qualification.architecture_scale_v1',
            @{$manifest->{required_capabilities}}),
        'manifest does not inherit private-nonportable revision-1 authority');
    ok(!grep($_ eq 'hial_vial.bridge_protocol.ahb_subordinate_v1',
            @{$manifest->{required_capabilities}}),
        'manifest does not masquerade as the public AHB bridge');
    my $identity_payload = clone($manifest);
    delete $identity_payload->{manifest_id};
    is($manifest->{manifest_id},
        'bridge/' . sha256_hex($json->encode($identity_payload)),
        'revision-2 identity covers the complete canonical manifest payload');

    my $second = build_route();
    ok($second->{bridge}{ok}, 'independent bridge construction succeeds');
    is($json->encode($second->{bridge}{report}),
        $json->encode($first->{bridge}{report}),
        'independent parsing, scheduling, lowering, and bridging are byte-equal');
};

subtest 'revision-2 execution admission proves 2048 genuine bindings' => sub {
    my $route = build_route();
    ok($route->{bridge}{ok}, 'bridge prerequisite succeeds');
    return unless $route->{bridge}{ok};
    my $inputs = execution_inputs($route->{bridge}{manifest});
    my $built = FSM::VIAL::ArchitectureScaleBalancedPortable::_call_execution(
        $inputs->{arguments},
    );
    ok($built->{ok}, 'caller-sealed balanced execution admission succeeds');
    diag($json->encode($built->{diagnostics})) unless $built->{ok};
    return unless $built->{ok};

    my $ir = $built->{execution_ir}->as_hashref;
    is_deeply(
        [map { scalar(@{$ir->{bindings}{$_}}) }
            qw(domains endpoints probes transactions events)],
        [1, 126, 32, 16, 128],
        'execution binding families retain the exact selected cardinalities',
    );
    is_deeply(
        [map { scalar(@{$_->{fields}}) } @{$ir->{bindings}{transactions}}],
        [(109) x 16],
        'execution binds all 1,744 transaction fields without a shortcut',
    );
    is_deeply(
        [map { scalar(@{$_->{event_input_bindings}}) }
            @{$ir->{bindings}{transactions}}],
        [(0) x 16],
        'events add no hidden endpoint-input binding padding',
    );
    is_deeply(
        [map { scalar(@{$_->{adapter_state_binding_ids}}) }
            @{$ir->{bindings}{events}}],
        [(0) x 128],
        'events add no adapter-state binding padding',
    );
    is($ir->{resource_summary}{bindings}, 2_048,
        'resource summary derives exactly 2,048 genuine bindings');

    my ($qualification) = grep {
        ($_->{capability_id} // '') eq $capability
    } @{$ir->{capability_ledger}};
    ok($qualification, 'execution ledger retains revision-2 authority');
    is($qualification->{classification}, 'qualification_only',
        'revision-2 authority remains qualification-only');
    is($qualification->{portable_class},
        'portable_with_exact_emitter_qualification',
        'portability requires the separately qualified exact emitter');
    is_deeply($qualification->{origins}, ['bridge_manifest'],
        'revision-2 authority has only the validated bridge origin');
};

subtest 'public and near-miss routes fail closed' => sub {
    my $route = build_route();
    ok($route->{bridge}{ok}, 'canonical route is available for negative controls');
    return unless $route->{bridge}{ok};

    my $direct_bridge = FSM::HIAL::VIALBridge::Builder
        ->build_balanced_portable_qualification($route->{bridge_arguments});
    ok(!$direct_bridge->{ok}, 'direct callers cannot invoke revision-2 bridging');
    is($direct_bridge->{diagnostics}[0]{code},
        'HIAL_VIAL_BRIDGE_INVOCATION_ERROR',
        'direct bridge rejection uses the stable invocation family');
    like($direct_bridge->{diagnostics}[0]{message},
        qr/private to FSM::VIAL::ArchitectureScaleBalancedPortable/,
        'direct bridge rejection names the sole admitted composer');

    my $public_bridge = FSM::HIAL::VIALBridge::Builder
        ->build_ial1($route->{bridge_arguments});
    ok(!$public_bridge->{ok}, 'public IAL1 route rejects revision-2 metadata');
    is($public_bridge->{diagnostics}[0]{code},
        'HIAL_VIAL_BRIDGE_ANNOTATION_ERROR',
        'public bridge rejection uses the annotation family');

    my $inputs = execution_inputs($route->{bridge}{manifest});
    my $direct_execution = FSM::VIAL::ExecutionBuilder
        ->build_balanced_portable_qualification($inputs->{arguments});
    ok(!$direct_execution->{ok},
        'direct callers cannot invoke balanced execution admission');
    is($direct_execution->{diagnostics}[0]{code},
        'VIAL_EXECUTION_INVOCATION_ERROR',
        'direct execution rejection uses the stable invocation family');
    like($direct_execution->{diagnostics}[0]{message},
        qr/private to FSM::VIAL::ArchitectureScaleBalancedPortable/,
        'direct execution rejection names the sole admitted composer');

    my $public_execution = FSM::VIAL::ExecutionBuilder
        ->build($inputs->{arguments});
    ok(!$public_execution->{ok},
        'public execution binding rejects revision-2 capability authority');
    is($public_execution->{diagnostics}[0]{code}, 'VIAL_CAPABILITY_ERROR',
        'public execution rejection uses the capability family');
    like($public_execution->{diagnostics}[0]{message}, qr/\Q$capability\E/,
        'public execution rejection names the private qualification capability');

    my $profile_mutation = clone($route->{bridge_arguments});
    $profile_mutation->{actor}{verification_bridge}{protocol}{profile}
        = 'qualification_only';
    $profile_mutation->{schedule_report}{verification_bridge}{protocol}{profile}
        = 'qualification_only';
    my $bad_profile = FSM::VIAL::ArchitectureScaleBalancedPortable::_call_bridge(
        $profile_mutation,
    );
    ok(!$bad_profile->{ok}, 'revision-1 profile substitution fails closed');
    is($bad_profile->{diagnostics}[0]{code},
        'HIAL_VIAL_BRIDGE_ANNOTATION_ERROR',
        'profile substitution identifies the annotation boundary');

    my $missing_bridge = clone($route->{bridge_arguments});
    delete $missing_bridge->{actor}{verification_bridge};
    delete $missing_bridge->{schedule_report}{verification_bridge};
    my $bad_missing_bridge =
        FSM::VIAL::ArchitectureScaleBalancedPortable::_call_bridge(
            $missing_bridge,
        );
    ok(!$bad_missing_bridge->{ok},
        'the private route cannot qualify an unannotated IAL1 actor');
    is($bad_missing_bridge->{diagnostics}[0]{path},
        '/actor/verification_bridge',
        'missing revision-2 metadata names the exact bridge boundary');

    my $field_mutation = clone($route->{bridge_arguments});
    pop @{$field_mutation->{actor}{verification_bridge}{transaction}{fields}};
    pop @{$field_mutation->{schedule_report}{verification_bridge}{transaction}{fields}};
    my $bad_fields = FSM::VIAL::ArchitectureScaleBalancedPortable::_call_bridge(
        $field_mutation,
    );
    ok(!$bad_fields->{ok}, 'a 108-field alias fails closed');
    is($bad_fields->{diagnostics}[0]{path},
        '/actor/verification_bridge/transaction/fields',
        'field near miss names the exact sealed locus');

    my $manifest_data = $route->{bridge}{manifest}->as_hashref;
    $manifest_data->{protocols}[0]{facts}[0]{value} = 'altered';
    my $forged_manifest = bless {data => $manifest_data},
        'FSM::HIAL::VIALBridge::Manifest';
    my %forged_arguments = (
        %{$inputs->{arguments}},
        bridge_manifest => $forged_manifest,
    );
    my $bad_manifest =
        FSM::VIAL::ArchitectureScaleBalancedPortable::_call_execution(
            \%forged_arguments,
        );
    ok(!$bad_manifest->{ok}, 'post-bridge protocol mutation fails closed');
    is($bad_manifest->{diagnostics}[0]{semantic_path},
        '/bridge_manifest/protocols',
        'post-bridge mutation names the independently sealed protocol locus');

    my $identity_data = $route->{bridge}{manifest}->as_hashref;
    $identity_data->{manifest_id} = 'bridge/' . ('0' x 64);
    my $forged_identity = bless {data => $identity_data},
        'FSM::HIAL::VIALBridge::Manifest';
    my %identity_arguments = (
        %{$inputs->{arguments}},
        bridge_manifest => $forged_identity,
    );
    my $bad_identity =
        FSM::VIAL::ArchitectureScaleBalancedPortable::_call_execution(
            \%identity_arguments,
        );
    ok(!$bad_identity->{ok}, 'forged content identity fails closed');
    is($bad_identity->{diagnostics}[0]{semantic_path},
        '/bridge_manifest/manifest_id',
        'identity forgery names the exact sealed identity locus');
};

done_testing();

sub build_route {
    my $actor = FSM::Adapter::ISF->new()->parse_source(
        $hial_text,
        'vial_architecture_scale_balanced_portable.isf',
    );
    my $scheduler = FSM::Scheduler::ISF->new();
    my $schedule_report = $json->decode($scheduler->report($actor));
    my $lowered = $scheduler->lower($actor);
    my $artifact_name = $actor->{actor_name} . '.fsm';
    $artifact_name = $actor->{actor_name} . '_top.fsm'
        unless exists $lowered->{files}{$artifact_name};
    my $arguments = {
        profile => 'core_single_unit_v1',
        authored_source => source_record(
            $hial_text,
            'generated/vial-scale/balanced-portable/'
                . 'vial_architecture_scale_balanced_portable.isf',
        ),
        actor => $actor,
        schedule_report => $schedule_report,
        generated_ial0 => source_record(
            $lowered->{files}{$artifact_name}, undef, $artifact_name,
        ),
        backend_names => backend_names($actor),
    };
    return {
        bridge_arguments => $arguments,
        bridge => FSM::VIAL::ArchitectureScaleBalancedPortable::_call_bridge(
            $arguments,
        ),
    };
}

sub execution_inputs {
    my ($manifest) = @_;
    my $semantic_ir = FSM::VIAL::Parser->parse_source({
        text => $vial_text,
        source_name => 'generated/vial-scale/balanced-portable/'
            . 'vial_architecture_scale_balanced_portable.vial',
        source_catalog => {},
    });
    my $semantic = $semantic_ir->as_hashref;
    my $fixture = $semantic->{packages}[0]{fixtures}[0];
    return {
        semantic_ir => $semantic_ir,
        arguments => {
            semantic_ir => $semantic_ir,
            bridge_manifest => $manifest,
            fixture_id => $fixture->{semantic_id},
            scenario_ids => [map { $_->{semantic_id} }
                @{$fixture->{scenarios}}],
            execution_profile =>
                'core_directed_single_clock_execution_v1',
            replay_manifest => undef,
            native_extension_catalog => [],
        },
    };
}

sub render_hial {
    my @endpoints = map { sprintf('endpoint_%08d', $_) } 0 .. 125;
    my @field_endpoints = @endpoints[0 .. 108];
    my @interface = map { "(input $_)" } @endpoints;
    my @storage = map {
        sprintf('(var probe_%08d (width 1))', $_)
    } 0 .. 31;
    my @fields = map { "(field $_ $_ drive unspecified)" }
        @field_endpoints;
    my @bridge_events = map {
        sprintf('(event bridge_event_%08d predicate sample endpoint_00000000)',
            $_)
    } 0 .. 112;
    my @probes = map { sprintf('(probe probe_%08d read_only)', $_) }
        0 .. 31;
    my @ports = map { "(input $_)" } @field_endpoints;
    my @transactions = map {
        sprintf('(transaction transaction_%08d (ports %s) '
            . '(on endpoint_00000000))', $_, join(' ', @ports))
    } 1 .. 15;
    return join('',
        '(actor vial_architecture_scale_balanced_portable',
        ' (clock clk)',
        ' (reset (rst_n async active_low))',
        ' (interface ', join(' ', @interface), ')',
        ' (storage ', join(' ', @storage), ')',
        ' (verification-bridge',
        ' (domain balanced)',
        ' (protocol architecture_scale_probe',
        ' (profile balanced_portable)',
        ' (revision 2)',
        ' (role verification)',
        ' (facts (fact scale_evidence_only true)',
        ' (fact qualified_emitter sv_portable_verilator)))',
        ' (transaction transaction_00000000',
        ' (fields ', join(' ', @fields), ')',
        ' (events ', join(' ', @bridge_events), '))',
        ' ', join(' ', @probes), ')',
        ' ', join(' ', @transactions), ')',
        "\n",
    );
}

sub render_vial {
    my @endpoints = map { sprintf('endpoint_%08d', $_) } 0 .. 125;
    my @field_endpoints = @endpoints[0 .. 108];
    my @fields = map { "($_ (type bit_t))" } @field_endpoints;
    my @bridge_events = map { sprintf('bridge_event_%08d', $_) } 0 .. 112;
    my @transaction_types = (
        '(transaction transaction_00000000 (fields '
            . join(' ', @fields) . ') (events '
            . join(' ', @bridge_events) . '))',
        map {
            sprintf('(transaction transaction_%08d (fields %s) (events on))',
                $_, join(' ', @fields))
        } 1 .. 15,
    );
    my @endpoint_bindings = map {
        sprintf('(endpoint %s "endpoint/%s" (type bit_t) public_port)',
            $_, $_)
    } @endpoints;
    my @probe_bindings = map {
        sprintf('(endpoint probe_%08d "probe/probe_%08d" '
            . '(type bit_t) verification_probe)', $_, $_)
    } 0 .. 31;
    my @transaction_bindings = map {
        sprintf('(transaction alias_%08d "transaction/transaction_%08d" '
            . 'transaction_%08d)', $_, $_, $_)
    } 0 .. 15;
    return join('',
        '(vial (version 1) (package architecture_scale_balanced_portable',
        ' (imports)',
        ' (types (type bit_t (logic 1)))',
        ' (transactions ', join(' ', @transaction_types), ')',
        ' (models)',
        ' (scoreboards)',
        ' (fixtures (fixture balanced_gate',
        ' (dut dut',
        ' (unit "unit/vial_architecture_scale_balanced_portable")',
        ' (domains (domain balanced "domain/balanced"))',
        ' (endpoints ', join(' ', @endpoint_bindings), ' ',
            join(' ', @probe_bindings), ')',
        ' (transactions ', join(' ', @transaction_bindings), '))',
        ' (instances)',
        ' (coverage)',
        ' (faults)',
        ' (randomness (seed 1701))',
        ' (scenarios (scenario smoke',
        ' (timeout (cycles balanced 16))',
        ' (steps (reset balanced 1))))))))',
        "\n",
    );
}

sub backend_names {
    my ($actor) = @_;
    my @endpoints = ($actor->{clock}, $actor->{reset}{name});
    push @endpoints, map { $_->{name} }
        @{$actor->{interface}{inputs} || []};
    push @endpoints, map { $_->{name} }
        @{$actor->{interface}{outputs} || []};
    my @probes = map { $_->{name} }
        @{$actor->{verification_bridge}{probes} || []};
    my %endpoint = map { $_ => $_ } @endpoints;
    my %probe = map { $_ => $_ } @probes;
    return {
        map {
            $_ => {
                unit => $actor->{actor_name},
                endpoints => {%endpoint},
                configurations => {},
                probes => {%probe},
            }
        } qw(systemverilog vhdl)
    };
}

sub source_record {
    my ($text, $repository_path, $artifact_name) = @_;
    $artifact_name //= basename($repository_path || 'generated');
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

sub clone {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}

package FSM::VIAL::ArchitectureScaleBalancedPortable;

sub _call_bridge {
    my ($arguments) = @_;
    return FSM::HIAL::VIALBridge::Builder
        ->build_balanced_portable_qualification($arguments);
}

sub _call_execution {
    my ($arguments) = @_;
    return FSM::VIAL::ExecutionBuilder
        ->build_balanced_portable_qualification($arguments);
}
