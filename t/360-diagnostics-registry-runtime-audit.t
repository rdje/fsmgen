#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::CheckDiagnosticsContract qw(build_check_diagnostics_contract);
use FSM::Support::DiagnosticCodes qw(diagnostic_code_registry);
use FSM::Support::DiagnosticCodeRegistryContract qw(build_diagnostic_code_registry_contract);
use FSM::Support::DiagnosticsContract qw(build_diagnostics_contract);

my $expected_section = build_expected_diagnostics_section();

subtest 'diagnostics manifest section stays an exact bounded diagnostic-registry projection in-process' => sub {
    my $manifest = build_capability_manifest();

    is_deeply(
        $manifest->{diagnostics},
        $expected_section,
        'in-process diagnostics section matches the exact bounded diagnostic-registry projection',
    );
};

subtest 'diagnostics manifest section stays an exact bounded diagnostic-registry projection through the public CLI' => sub {
    my $decoded = run_capability_manifest('--capability-manifest');

    is_deeply(
        $decoded->{diagnostics},
        $expected_section,
        'CLI diagnostics section matches the exact bounded diagnostic-registry projection',
    );
};

subtest 'diagnostics manifest alias keeps the same exact bounded diagnostic-registry projection' => sub {
    my $decoded = run_capability_manifest('--emit-capability-manifest');

    is_deeply(
        $decoded->{diagnostics},
        $expected_section,
        'CLI alias diagnostics section matches the exact bounded diagnostic-registry projection',
    );
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

sub build_expected_diagnostics_section {
    my $diagnostic_registry = diagnostic_code_registry();
    my $check_json = {
        %{build_check_diagnostics_contract()},
        supported_smoke_corpus_covered => JSON::PP::true,
        strict_supported_corpus_covered => JSON::PP::true,
        expected_failure_corpus_covered => JSON::PP::true,
        classifier_match_policy => 'most_specific_expected_error_pattern',
        success_match_policy => 'resolved_source_path_to_non_failure_corpus_entry',
    };

    return {
        registry_source => 'FSM::Support::DiagnosticCodes',
        stable_codes => [
            map {
                +{
                    code => $_,
                    %{$diagnostic_registry->{$_}},
                }
            } sort keys %{$diagnostic_registry || {}}
        ],
        stable_code_registry => build_diagnostic_code_registry_contract(),
        check_json => $check_json,
        section_contract => build_diagnostics_contract(),
    };
}
