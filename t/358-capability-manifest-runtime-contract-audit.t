#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::BackendValidationContract qw(build_backend_validation_contract);
use FSM::Support::BackendValidationSection qw(build_manifest_systemverilog_external_surface);
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::CapabilityManifestContract qw(build_capability_manifest_contract);
use FSM::Support::CompositionReportContract qw(build_composition_report_contract);
use FSM::Support::DebugRuntimeContract qw(build_debug_runtime_contract);
use FSM::Support::DiagnosticCodeRegistryContract qw(build_diagnostic_code_registry_contract);
use FSM::Support::DiagnosticsContract qw(build_diagnostics_contract);
use FSM::Support::DiagnosticsSection qw(build_manifest_check_json_surface);
use FSM::Support::DocumentationContract qw(build_documentation_contract);
use FSM::Support::EmbeddingContract qw(build_embedding_contract);
use FSM::Support::ExtensionContract qw(build_extension_contract);
use FSM::Support::HDLGeneratorFacadeContract qw(build_hdl_generator_facade_contract);
use FSM::Support::HDLGeneratorResultContract qw(build_hdl_generator_result_contract);
use FSM::Support::LanguageSurfaceContract qw(build_language_surface_contract);
use FSM::Support::ProducerContract qw(build_producer_contract);
use FSM::Support::SemanticExportsContract qw(build_semantic_exports_contract);
use FSM::Support::SemanticExportsSection qw(build_manifest_normalized_semantic_json_surface);
use FSM::Support::SupportAccountingContract qw(build_support_accounting_contract);

my $in_process_manifest = build_capability_manifest();
my @manifest_views = (
    {
        label => 'in-process capability manifest',
        manifest => $in_process_manifest,
    },
    {
        label => 'CLI capability manifest',
        manifest => run_capability_manifest('--capability-manifest'),
    },
    {
        label => 'CLI alias capability manifest',
        manifest => run_capability_manifest('--emit-capability-manifest'),
    },
);

subtest 'CLI manifest surfaces stay identical to the in-process builder' => sub {
    is_deeply(
        $manifest_views[1]{manifest},
        $in_process_manifest,
        'primary CLI capability manifest matches the in-process builder exactly',
    );
    is_deeply(
        $manifest_views[2]{manifest},
        $in_process_manifest,
        'CLI alias capability manifest matches the in-process builder exactly',
    );
};

subtest 'embedded exact-builder contracts stay exact at runtime' => sub {
    for my $view (@manifest_views) {
        my $manifest = $view->{manifest};
        my $label = $view->{label};

        assert_exact_builder_copy(
            $manifest->{manifest_contract},
            scalar(build_capability_manifest_contract()),
            "$label keeps manifest_contract as an exact builder copy",
        );
        assert_exact_builder_copy(
            $manifest->{producer}{section_contract},
            scalar(build_producer_contract()),
            "$label keeps producer.section_contract as an exact builder copy",
        );
        assert_exact_builder_copy(
            $manifest->{support_accounting}{section_contract},
            scalar(build_support_accounting_contract()),
            "$label keeps support_accounting.section_contract as an exact builder copy",
        );
        assert_exact_builder_copy(
            $manifest->{diagnostics}{stable_code_registry},
            scalar(build_diagnostic_code_registry_contract()),
            "$label keeps diagnostics.stable_code_registry as an exact builder copy",
        );
        assert_exact_builder_copy(
            $manifest->{diagnostics}{section_contract},
            scalar(build_diagnostics_contract()),
            "$label keeps diagnostics.section_contract as an exact builder copy",
        );
        assert_exact_builder_copy(
            $manifest->{semantic_exports}{section_contract},
            scalar(build_semantic_exports_contract()),
            "$label keeps semantic_exports.section_contract as an exact builder copy",
        );
        assert_exact_builder_copy(
            $manifest->{backend_validation}{section_contract},
            scalar(build_backend_validation_contract()),
            "$label keeps backend_validation.section_contract as an exact builder copy",
        );
        assert_exact_builder_copy(
            $manifest->{embedding}{composition_report},
            scalar(build_composition_report_contract()),
            "$label keeps embedding.composition_report as an exact builder copy",
        );
        assert_exact_builder_copy(
            $manifest->{embedding}{hdl_generator_facade},
            scalar(build_hdl_generator_facade_contract()),
            "$label keeps embedding.hdl_generator_facade as an exact builder copy",
        );
        assert_exact_builder_copy(
            $manifest->{embedding}{hdl_generator_result},
            scalar(build_hdl_generator_result_contract()),
            "$label keeps embedding.hdl_generator_result as an exact builder copy",
        );
        assert_exact_builder_copy(
            $manifest->{embedding}{typed_extensions},
            scalar(build_extension_contract()),
            "$label keeps embedding.typed_extensions as an exact builder copy",
        );
        assert_exact_builder_copy(
            $manifest->{embedding}{debug_runtime},
            scalar(build_debug_runtime_contract()),
            "$label keeps embedding.debug_runtime as an exact builder copy",
        );
        assert_exact_builder_copy(
            $manifest->{embedding}{section_contract},
            scalar(build_embedding_contract()),
            "$label keeps embedding.section_contract as an exact builder copy",
        );
        assert_exact_builder_copy(
            $manifest->{language_surface}{surface_contract},
            scalar(build_language_surface_contract()),
            "$label keeps language_surface.surface_contract as an exact builder copy",
        );
        assert_exact_builder_copy(
            $manifest->{documentation}{section_contract},
            scalar(build_documentation_contract()),
            "$label keeps documentation.section_contract as an exact builder copy",
        );
    }
};

subtest 'manifest-context enrichments stay bounded and deliberate at runtime' => sub {
    my $expected_check_json = build_manifest_check_json_surface();
    my $expected_normalized_semantic_json = build_manifest_normalized_semantic_json_surface();
    my $expected_systemverilog_external = build_manifest_systemverilog_external_surface();

    for my $view (@manifest_views) {
        my $manifest = $view->{manifest};
        my $label = $view->{label};

        assert_exact_builder_copy(
            $manifest->{diagnostics}{check_json},
            $expected_check_json,
            "$label keeps diagnostics.check_json as builder-plus-bounded-manifest-context",
        );
        assert_exact_builder_copy(
            $manifest->{semantic_exports}{normalized_semantic_json},
            $expected_normalized_semantic_json,
            "$label keeps semantic_exports.normalized_semantic_json as builder-plus-bounded-manifest-context",
        );
        assert_exact_builder_copy(
            $manifest->{backend_validation}{systemverilog_external},
            $expected_systemverilog_external,
            "$label keeps backend_validation.systemverilog_external as builder-plus-bounded-manifest-context",
        );
    }
};

done_testing();

sub run_capability_manifest {
    my ($mode) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', $mode],
    );

    ok($success, "$mode succeeds");
    is(join('', @{$stderr_buf || []}), '', "$mode keeps stderr clean");

    return decode_json(join('', @{$stdout_buf || []}));
}

sub assert_exact_builder_copy {
    my ($got, $expected, $label) = @_;
    is_deeply($got, $expected, $label);
}
