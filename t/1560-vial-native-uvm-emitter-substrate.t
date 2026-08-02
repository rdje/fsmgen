#!/usr/bin/env perl

use strict;
use warnings;

use bytes ();
use Digest::SHA qw(sha256_hex);
use File::Path qw(remove_tree);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArtifactTransaction;
use FSM::VIAL::Backend::SVUVMAccellera2020_3_1;
use FSM::VIAL::Backend::SVUVMStaticValidator;
use FSM::VIAL::Parser;
use FSM::VIAL::PlanBuilder;

my $json = JSON::PP->new->canonical(1);
my $vial_id = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $hial_id = 'ppif/ahb_lite_subordinate.ppif';
my $profile = 'sv_uvm_emit.accellera_2020_3_1';
my $artifact_root = '.artifacts/test/vial-native-uvm-emitter-substrate';
my $built = build_plan();

ok($built->{ok}, 'checked VIAL/HIAL fixture reaches native UVM backend inputs');
diag($json->encode($built->{diagnostics})) unless $built->{ok};

subtest 'native emitter produces a deterministic closed unqualified UVM graph' => sub {
    my $first = emit_backend();
    ok($first->{ok}, 'native UVM foundation emission succeeds');
    diag($json->encode($first->{diagnostics})) unless $first->{ok};
    is_deeply(
        [sort keys %$first],
        [sort @{FSM::VIAL::Backend::SVUVMAccellera2020_3_1->result_keys}],
        'backend result shell is closed',
    );
    is($first->{status}, 'emitted_unqualified', 'status does not imply compile or runtime qualification');
    is($first->{backend_profile}, $profile, 'backend profile is exact');
    like($first->{operation_id}, qr/\Aop-[0-9a-f]{64}\z/, 'operation identity is deterministic and safe');
    is(scalar(@{$first->{artifacts}}), 14, 'emission graph contains the exact fourteen artifacts');
    is_deeply(
        [map { $_->{relpath} } @{$first->{artifacts}}],
        [sort map { $_->{relpath} } @{$first->{artifacts}}],
        'artifact graph is sorted by repository-relative path',
    );
    is_deeply(
        [sort keys %{$first->{backend_manifest}}],
        [sort @{FSM::VIAL::Backend::SVUVMAccellera2020_3_1->manifest_keys}],
        'backend manifest is closed',
    );
    is_deeply(
        [sort keys %{$first->{source_map}}],
        [sort @{FSM::VIAL::Backend::SVUVMAccellera2020_3_1->source_map_keys}],
        'source map is closed',
    );
    for my $entry (@{$first->{source_map}{entries}}) {
        is_deeply(
            [sort keys %$entry],
            [sort @{FSM::VIAL::Backend::SVUVMAccellera2020_3_1->source_map_entry_keys}],
            "source-map entry '$entry->{generated_symbol}' is closed",
        );
        is($entry->{generated_start_column}, 1,
            "source-map entry '$entry->{generated_symbol}' starts at the exact full-line column");
        cmp_ok($entry->{generated_end_column}, '>', 1,
            "source-map entry '$entry->{generated_symbol}' ends at a measured source column");
    }
    my %mapped = map { $_->{generated_relpath} => 1 } @{$first->{source_map}{entries}};
    for my $artifact (grep { $_->{language} eq 'systemverilog' } @{$first->{artifacts}}) {
        ok($mapped{$artifact->{relpath}}, "source artifact '$artifact->{relpath}' has a source-map entry");
    }

    my $again = emit_backend();
    is_deeply($again, $first, 'identical inputs reproduce the byte-identical complete result');
    is(
        sha256_hex($json->encode($again)),
        sha256_hex($json->encode($first)),
        'canonical complete-result digest is deterministic',
    );
};

subtest 'methodology identity and capability states are exact and honest' => sub {
    my $emission = emit_backend();
    my $methodology_artifact = artifact_by_role($emission, 'selected_methodology_profile');
    my $methodology = JSON::PP->new->decode($methodology_artifact->{content});
    is($methodology->{methodology_standard}{designation}, 'IEEE 1800.2-2020', 'methodology standard is exact');
    is($methodology->{reference_implementation}{release}, '2020-3.1', 'Accellera release is exact');
    is($methodology->{reference_implementation}{git_tag}, '2020.3.1', 'Accellera tag is exact');
    is(
        $methodology->{reference_implementation}{git_commit},
        '78c06547a2a0a29b3dc9dcafae62b75b2ff61544',
        'Accellera source commit is exact',
    );
    ok(!$methodology->{library_materialization}{network_fetch_during_emission},
        'ordinary emission performs no network fetch');
    is($methodology->{library_materialization}{current_state}, 'not_requested_or_inspected',
        'emission neither requires nor pretends to inspect UVM library bytes');

    my $evidence = $emission->{backend_manifest}{capability_evidence};
    is($evidence->{emission}, 'passed', 'emission is the only product stage passed here');
    is($evidence->{static_validation}, 'passed_structural_only', 'static evidence is labelled structural only');
    is($evidence->{manual_review}, 'pending', 'director visual review remains pending');
    is($evidence->{preprocessing}, 'not_run', 'preprocessing is not run');
    is($evidence->{parse}, 'not_run', 'parse is not run');
    is($evidence->{library_compile}, 'not_run', 'UVM library compile is not run');
    is($evidence->{fixture_compile}, 'not_run', 'fixture compile is not run');
    is($evidence->{elaboration}, 'not_run', 'elaboration is not run');
    is($evidence->{runtime}, 'not_run', 'runtime is not run');
    is($evidence->{result}, 'not_produced', 'runtime result is not produced');
    is($evidence->{parity}, 'not_evaluated', 'parity is not evaluated');
    is($emission->{backend_manifest}{result}{status}, 'not_produced', 'manifest has no invented result');
};

subtest 'first review sources contain typed, interface, component, fixture, and top foundations' => sub {
    my $emission = emit_backend();
    my $types = artifact_by_role($emission, 'uvm_types_package')->{content};
    like($types, qr/package fsmgen_vial_uvm_types_pkg;/, 'typed support package is emitted');
    like($types, qr/typedef enum int unsigned.*VIAL_DRIVE_PHASE/s, 'logical phase type is emitted');
    like($types, qr/class fsmgen_vial_execution_context extends uvm_object;/, 'typed execution context is emitted');

    my $components = artifact_by_role($emission, 'uvm_component_foundations')->{content};
    like($components, qr/class fsmgen_vial_component_base extends uvm_component;/, 'component base is emitted');
    like($components, qr/class fsmgen_vial_agent_base extends uvm_agent;/, 'agent base is emitted');
    like($components, qr/class fsmgen_vial_env_base extends fsmgen_vial_component_base;/, 'environment base is emitted');
    like($components, qr/class fsmgen_vial_test_base extends uvm_test;/, 'test base is emitted');

    my $interface = artifact_by_role($emission, 'uvm_fixture_interface')->{content};
    like($interface, qr/interface base_output_arbitration_if;/, 'typed fixture interface is emitted');
    like($interface, qr/clocking driver_cb \@\(negedge clk\);/, 'drive clocking block owns the inactive edge');
    like($interface, qr/clocking monitor_cb \@\(posedge clk\);/, 'sample clocking block owns the active edge');
    like($interface, qr/modport driver_mp/, 'driver modport is emitted');
    like($interface, qr/modport monitor_mp/, 'monitor modport is emitted');

    my $notifications = artifact_by_role($emission, 'uvm_notification_interception')->{content};
    like($notifications, qr/package base_output_arbitration_notifications_pkg;/,
        'typed notification package is emitted');
    like($notifications, qr/extends uvm_event_callback#\(base_output_arbitration_notification_payload\)/,
        'typed UVM callback foundation is emitted');

    my $services = artifact_by_role($emission, 'uvm_stimulus_services')->{content};
    like($services, qr/package base_output_arbitration_services_pkg;/,
        'typed stimulus/services package is emitted');
    like($services, qr/class base_output_arbitration_ahb_write_item extends uvm_sequence_item;/,
        'typed transaction item is emitted');
    like($services, qr/class base_output_arbitration_success_sequence extends uvm_sequence#/,
        'public scenario sequence structure is emitted');

    my $fixture = artifact_by_role($emission, 'uvm_fixture_package')->{content};
    like($fixture, qr/class base_output_arbitration_config extends uvm_object;/,
        'typed fixture configuration is emitted');
    like($fixture, qr/class base_output_arbitration_env extends fsmgen_vial_env_base;/,
        'fixture environment foundation is emitted');
    like($fixture, qr/class base_output_arbitration_test extends fsmgen_vial_test_base;/,
        'fixture test foundation is emitted');

    my $top = artifact_by_role($emission, 'uvm_fixture_top')->{content};
    like($top, qr/ahb_lite_subordinate dut \(/, 'generated HIAL DUT is bound in the top');
    like($top, qr/uvm_config_db#\(virtual base_output_arbitration_if\)::set/,
        'top publishes the exact virtual interface type');
    like($top, qr/run_test\("base_output_arbitration_test"\);/,
        'top selects the generated test foundation');
    unlike(join('', map { $_->{content} } @{$emission->{artifacts}}),
        qr/\b(?:xcelium|irun|vcs|questa|modelsim|verilator|iverilog|nexsim)\b/i,
        'canonical artifacts contain no simulator-provider source branch or name');
};

subtest 'checked review gallery is byte-identical to deterministic emitter output' => sub {
    my $emission = emit_backend();
    my $gallery = repo_path(qw(
        vial review_gallery sv_uvm_emit.accellera_2020_3_1
        ahb_base_output_foundation
    ));
    my %filename = (
        uvm_types_package => 'fsmgen_vial_uvm_types_pkg.sv',
        uvm_component_foundations => 'fsmgen_vial_uvm_components_pkg.sv',
        uvm_fixture_interface => 'base_output_arbitration_if.sv',
        uvm_notification_interception => 'base_output_arbitration_notifications_pkg.sv',
        uvm_stimulus_services => 'base_output_arbitration_services_pkg.sv',
        uvm_checking_results => 'base_output_arbitration_checking_pkg.sv',
        bound_sva_checker => 'base_output_arbitration_sva_checker.sv',
        uvm_fixture_package => 'base_output_arbitration_pkg.sv',
        uvm_fixture_top => 'base_output_arbitration_tb.sv',
    );
    for my $role (sort keys %filename) {
        my $expected = slurp_raw(File::Spec->catfile($gallery, $filename{$role}));
        is(artifact_by_role($emission, $role)->{content}, $expected,
            "gallery snapshot '$filename{$role}' matches exact emitted bytes");
    }
    my $readme = slurp_raw(File::Spec->catfile($gallery, 'README.md'));
    like($readme, qr/plan\/038c968edbd7782d36f49af5092dd4301ca95989914eeba73250f9b609525574/,
        'gallery records the exact deterministic plan identity');
    like($readme, qr/have\s+not been preprocessed, parsed, compiled, elaborated, or run/,
        'gallery preserves every syntax and runtime non-claim');
};

subtest 'static validator is closed, fail-closed, and never becomes a syntax claim' => sub {
    my $emission = emit_backend();
    my $static = $emission->{static_validation};
    is_deeply(
        [sort keys %$static],
        [sort @{FSM::VIAL::Backend::SVUVMStaticValidator->result_keys}],
        'static validator result is closed',
    );
    ok($static->{ok}, 'generated foundation passes all selected structural checks');
    is($static->{status}, 'passed', 'static status is exact');
    ok(!(grep { $_->{status} ne 'passed' } @{$static->{checks}}),
        'every selected structural check passes');

    my @source = map { clone($_) }
        grep { $_->{language} eq 'systemverilog' } @{$emission->{artifacts}};
    my @missing = grep { $_->{role} ne 'uvm_component_foundations' } @source;
    static_failure(\@missing, 'VIAL_UVM_STATIC_REQUIRED_ROLE_ERROR', 'missing required source role');

    my @provider = map { clone($_) } @source;
    artifact_in(\@provider, 'uvm_fixture_top')->{content} .= "// xcelium-only workaround\n";
    static_failure(\@provider, 'VIAL_UVM_STATIC_PROVIDER_LEAK', 'provider-specific source leakage');

    my @unbalanced = map { clone($_) } @source;
    artifact_in(\@unbalanced, 'uvm_fixture_top')->{content} =~ s/endmodule\n\z//;
    static_failure(\@unbalanced, 'VIAL_UVM_STATIC_BALANCE_ERROR', 'unbalanced generated source');

    my $bad_profile = FSM::VIAL::Backend::SVUVMStaticValidator->validate({
        backend_profile => 'sv_uvm_qualified',
        artifacts => \@source,
    });
    ok(!$bad_profile->{ok}, 'validator rejects a substituted profile');
    is($bad_profile->{diagnostics}[0]{code}, 'VIAL_UVM_STATIC_HOST_ERROR',
        'substituted profile is a closed invocation failure');
};

subtest 'backend rejects malformed or unsupported inputs atomically' => sub {
    backend_failure(
        FSM::VIAL::Backend::SVUVMAccellera2020_3_1->emit({}),
        'VIAL_UVM_BACKEND_INVOCATION_ERROR', 'missing closed invocation keys',
    );
    backend_failure(
        emit_backend(backend_profile => 'sv_uvm_qualified'),
        'VIAL_UVM_BACKEND_UNSUPPORTED', 'unselected qualified profile',
    );
    my $absolute_artifact_root = File::Spec->catdir(
        File::Spec->rootdir(), 'tmp', 'off-volume-vial-uvm',
    );
    backend_failure(
        emit_backend(artifact_root => $absolute_artifact_root),
        'VIAL_UVM_BACKEND_INVOCATION_ERROR', 'absolute artifact root',
    );
    my $bad_inputs = clone($built->{backend_inputs});
    $bad_inputs->{dut_systemverilog}[0]{text} .= "\n";
    backend_failure(
        emit_backend(backend_inputs => $bad_inputs),
        'VIAL_UVM_BACKEND_UNSUPPORTED', 'DUT content/digest mismatch',
    );
};

subtest 'artifact transaction publishes atomically, replays identically, and cleans exactly' => sub {
    my $repo_root = repo_path();
    my $target = repo_path(split m{/}, $artifact_root);
    remove_tree($target) if -e $target;
    ok(!-e $target, 'exact test artifact root is absent before publication');
    my $emission = emit_backend();
    my $published = FSM::VIAL::ArtifactTransaction->publish({
        repo_root => $repo_root,
        artifact_root => $artifact_root,
        operation_id => $emission->{operation_id},
        artifacts => $emission->{artifacts},
    });
    ok($published->{ok}, 'complete native UVM graph publishes atomically');
    is($published->{status}, 'planned', 'first atomic publication uses the established transaction status');
    ok(-f File::Spec->catfile($target, split m{/},
        'backends/sv_uvm_emit.accellera_2020_3_1/backend-manifest.json'),
        'published graph contains its backend manifest');
    my $unchanged = FSM::VIAL::ArtifactTransaction->publish({
        repo_root => $repo_root,
        artifact_root => $artifact_root,
        operation_id => $emission->{operation_id},
        artifacts => $emission->{artifacts},
    });
    ok($unchanged->{ok}, 'identical publication is accepted');
    is($unchanged->{status}, 'unchanged', 'identical publication does not rewrite files');

    my @mutated = map { clone($_) } @{$emission->{artifacts}};
    $mutated[0]{content} .= "\n";
    my $collision = FSM::VIAL::ArtifactTransaction->publish({
        repo_root => $repo_root,
        artifact_root => $artifact_root,
        operation_id => $emission->{operation_id},
        artifacts => \@mutated,
    });
    ok(!$collision->{ok}, 'non-identical existing graph is rejected');
    is($collision->{diagnostics}[0]{code}, 'VIAL_ARTIFACT_COLLISION', 'collision has exact diagnostic');

    remove_tree($target);
    ok(!-e $target, 'exact published test graph is removed');
    my $staging = repo_path('.artifacts', 'tmp', 'vial', $emission->{operation_id});
    ok(!-e $staging, 'operation-owned staging has no residue');
};

done_testing;

sub build_plan {
    my $semantic_ir = FSM::VIAL::Parser->parse_source({
        text => slurp_raw(repo_path(split m{/}, $vial_id)),
        source_name => $vial_id,
        source_catalog => {},
    });
    return FSM::VIAL::PlanBuilder->build({
        semantic_ir => $semantic_ir,
        hial_source => {
            source_id => $hial_id,
            text => slurp_raw(repo_path(split m{/}, $hial_id)),
            format => 'ppif',
        },
        fixture_id => undef,
        scenario_ids => [],
        execution_profile => 'core_directed_single_clock_execution_v1',
        replay_manifest => undef,
        native_extension_catalog => [],
    });
}

sub emit_backend {
    my (%override) = @_;
    return FSM::VIAL::Backend::SVUVMAccellera2020_3_1->emit({
        execution_ir => $built->{execution_ir},
        bridge_manifest => $built->{bridge_manifest},
        backend_inputs => $built->{backend_inputs},
        artifact_root => $artifact_root,
        backend_profile => $profile,
        %override,
    });
}

sub artifact_by_role {
    my ($emission, $role) = @_;
    my @artifact = grep { $_->{role} eq $role } @{$emission->{artifacts}};
    is(scalar(@artifact), 1, "artifact role '$role' occurs exactly once");
    return $artifact[0];
}

sub artifact_in {
    my ($artifacts, $role) = @_;
    my @artifact = grep { $_->{role} eq $role } @$artifacts;
    die "test fixture role '$role' is not unique\n" unless @artifact == 1;
    return $artifact[0];
}

sub static_failure {
    my ($artifacts, $code, $label) = @_;
    my $result = FSM::VIAL::Backend::SVUVMStaticValidator->validate({
        backend_profile => $profile,
        artifacts => $artifacts,
    });
    ok(!$result->{ok}, "$label fails closed");
    ok((grep { $_->{code} eq $code } @{$result->{diagnostics}}),
        "$label has exact diagnostic");
}

sub backend_failure {
    my ($result, $code, $label) = @_;
    ok(!$result->{ok}, "$label fails closed");
    is($result->{diagnostics}[0]{code}, $code, "$label has exact diagnostic");
    is_deeply($result->{artifacts}, [], "$label emits no partial artifact graph");
    is($result->{backend_manifest}, undef, "$label emits no backend manifest");
}

sub clone {
    my ($value) = @_;
    return undef unless defined $value;
    return {map { $_ => clone($value->{$_}) } keys %$value} if ref($value) eq 'HASH';
    return [map { clone($_) } @$value] if ref($value) eq 'ARRAY';
    return $value;
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!\n";
    local $/;
    my $text = <$fh>;
    close $fh or die "cannot close $path: $!\n";
    return $text;
}

sub repo_path {
    return File::Spec->catfile($FindBin::Bin, '..', @_);
}
