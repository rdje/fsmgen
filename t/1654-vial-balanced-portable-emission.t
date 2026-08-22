#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleBalancedPortable;
use FSM::VIAL::ArchitectureScaleBalancedPortableEmission;
use FSM::VIAL::Backend::SVPortableVerilator;
use FSM::VIAL::PlanBuilder;

{
    package FSM::VIAL::ArchitectureScaleBalancedPortableEmission;

    sub test_emission_route {
        my ($construction) = @_;
        return FSM::VIAL::ArchitectureScaleBalancedPortable
            ->_build_emission_route({construction => $construction});
    }

    sub test_exact_emission {
        my ($route, $artifact_root, $backend_inputs) = @_;
        $backend_inputs //= $route->{backend_inputs};
        return FSM::VIAL::Backend::SVPortableVerilator
            ->emit_balanced_portable_qualification({
                execution_ir => $route->{execution_ir},
                bridge_manifest => $route->{bridge_manifest},
                backend_inputs => $backend_inputs,
                artifact_root => $artifact_root,
                backend_profile => 'sv_portable_verilator',
            });
    }
}

my $composer = 'FSM::VIAL::ArchitectureScaleBalancedPortable';
my $qualifier = 'FSM::VIAL::ArchitectureScaleBalancedPortableEmission';
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $json = JSON::PP->new->canonical(1)->utf8(1);
my @report_keys = qw(
    ok status schema schema_version report_identity rerun_identity
    composition_report_identity workload_identity stage_identities
    negotiation artifact_oracle oracle_applicability claims explicit_nonclaims
    diagnostics
);
my @artifact_relpaths = qw(
    backends/sv_portable_verilator/backend-manifest.json
    backends/sv_portable_verilator/backend-source-map.json
    backends/sv_portable_verilator/commands/compile-command.json
    backends/sv_portable_verilator/commands/run-command.json
    backends/sv_portable_verilator/evidence/tool-profile.json
    backends/sv_portable_verilator/src/balanced_gate_tb.sv
    backends/sv_portable_verilator/src/dut/vial-architecture-scale-balanced-portable.sv
    backends/sv_portable_verilator/src/fsmgen_vial_runtime_pkg.sv
);
my @nonclaims = qw(
    architecture_scale_capacity whole_product_big whole_product_really_big
    multi_unit multi_domain mixed_language native_uvm_runtime full_language
    synthesis general_cross_backend_parity
);

my $reference_hial = slurp_raw(repo_path(
    'ppif', 'ahb_lite_subordinate.ppif'));
my $reference_vial = slurp_raw(repo_path(
    'vial', 'ahb_subordinate_base_output_arbitration.vial'));
my $construction = $composer->construct({
    reference_hial_text => $reference_hial,
    reference_vial_text => $reference_vial,
});

my $report;

subtest 'exact revision-2 structural emission is fully qualified' => sub {
    $report = $qualifier->evaluate({construction => $construction});
    ok($report->{ok}, 'balanced portable-SystemVerilog qualification succeeds');
    diag($json->encode($report->{diagnostics})) unless $report->{ok};
    return unless $report->{ok};

    is($report->{status}, 'structural_emission_qualified',
        'report states only the structural emission boundary');
    is($report->{schema},
        'fsmgen.vial_architecture_scale_balanced_portable_emission_report.v1',
        'report uses the dedicated balanced-emission schema');
    is_deeply([sort keys %$report], [sort @report_keys],
        'report schema is closed');
    is_deeply($qualifier->report_keys, \@report_keys,
        'reported key authority matches the closed result');
    like($report->{report_identity},
        qr{\Abalanced-emission/[0-9a-f]{64}\z},
        'report has one content address');
    like($report->{rerun_identity}, qr{\Arerun/[0-9a-f]{64}\z},
        'independent route and emission rerun has one identity');
    like($report->{composition_report_identity},
        qr{\Abalanced-composition/[0-9a-f]{64}\z},
        'emission retains the fresh six-family composition identity');
    is($report->{workload_identity},
        $construction->{workload}{workload_identity},
        'emission remains attached to the canonical workload');
    ok(!scalar(grep { !defined($_) || $_ !~ /\A[0-9a-f]{64}\z/ }
            values %{$report->{stage_identities}}),
        'every canonical stage and artifact graph has one SHA-256 identity');

    my $negotiation = $report->{negotiation};
    is(scalar(@{$negotiation->{required}}), 15,
        'negotiation retains exactly fifteen closed capabilities');
    is_deeply($negotiation->{satisfied}, $negotiation->{required},
        'every exact revision-2 requirement is satisfied');
    is_deeply($negotiation->{unsatisfied}, [],
        'no requirement is admitted by approximation');
    is_deeply($negotiation->{native_only}, [],
        'balanced qualification contains no native-only capability');
    ok(scalar(grep {
            $_ eq 'hial_vial.bridge_qualification.balanced_portable_v2'
        } @{$negotiation->{satisfied}}),
        'the dedicated revision-2 capability is explicitly negotiated');

    my $oracle = $report->{artifact_oracle};
    is($oracle->{backend_profile}, 'sv_portable_verilator',
        'only the selected portable-SystemVerilog backend is qualified');
    is($oracle->{artifact_count}, 8,
        'the complete deterministic artifact graph is present');
    is($oracle->{source_artifact_count}, 3,
        'the graph contains exactly three SystemVerilog sources');
    is($oracle->{source_bytes}, 503_279,
        'the exact source byte total is frozen');
    is($oracle->{source_map_entries}, 3_605,
        'the exact backend source-map cardinality is frozen');
    is($oracle->{mapped_operation_count}, 1_024,
        'every expanded operation has source-map coverage');
    is($oracle->{mapped_binding_count}, 2_048,
        'every genuine ExecutionIR binding has source-map coverage');
    is_deeply($oracle->{artifact_relpaths}, \@artifact_relpaths,
        'artifact paths and order are exact');
    is(scalar(@{$oracle->{source_identities}}), 3,
        'each source has one byte/digest identity');
    ok(!scalar(grep {
            ($_->{sha256} // '') !~ /\A[0-9a-f]{64}\z/
                || ($_->{bytes} // 0) <= 0
        } @{$oracle->{source_identities}}),
        'all source identities carry positive bytes and SHA-256');
    cmp_ok($oracle->{maximum_generated_identifier_bytes}, '<=',
        $oracle->{generated_identifier_limit_bytes},
        'every generated identifier stays inside the frozen limit');
    ok($oracle->{byte_equal_rerun} && $oracle->{in_memory_only},
        'independent emission is byte-equal and remains in memory');
    ok($oracle->{public_bypass_rejected} && $oracle->{atomic_rejection},
        'the public emitter bypass rejects atomically');
    is_deeply($oracle->{diagnostics}, [],
        'qualified emission has no backend diagnostics');

    is_deeply(
        [map { "$_->{stage}:$_->{status}" }
            @{$report->{oracle_applicability}}],
        [
            qw(
                construct:completed semantic:completed bridge:completed
                plan:completed backend_inputs:completed emit:completed
                compile:not_run runtime:not_run trace:not_materialized
                result:not_produced
            )
        ],
        'oracle applicability ends exactly at structural emission',
    );
    ok($report->{claims}{qualification_only}
            && $report->{claims}{all_six_gate_reports_consumed}
            && $report->{claims}{canonical_sources_constructed}
            && $report->{claims}{canonical_execution_constructed}
            && $report->{claims}{canonical_backend_inputs_constructed}
            && $report->{claims}{exact_revision_2_negotiated}
            && $report->{claims}{structural_emission_qualified},
        'only completed structural qualification claims are true');
    ok(!scalar(grep { $report->{claims}{$_} } qw(
            external_tool_executed compile_executed runtime_executed
            trace_materialized result_produced support_claimed
            performance_claimed capacity_claimed
        )), 'external, runtime, support, performance, and capacity claims stay false');
    is_deeply($report->{explicit_nonclaims}, \@nonclaims,
        'every architecture-scale nonclaim remains explicit');
};

subtest 'exact admission rejects public, altered, and unsealed evidence' => sub {
    my $route =
        FSM::VIAL::ArchitectureScaleBalancedPortableEmission::test_emission_route(
            $construction,
        );
    ok($route->{ok}, 'test reconstructs one canonical sealed emission route');
    my $artifact_root =
        "$construction->{workload}{staging_identity}/backend-output";
    my $exact =
        FSM::VIAL::ArchitectureScaleBalancedPortableEmission::test_exact_emission(
            $route, $artifact_root,
        );
    ok($exact->{ok}, 'exact caller-sealed evidence emits');

    my $public = 'FSM::VIAL::Backend::SVPortableVerilator'->emit({
        execution_ir => $route->{execution_ir},
        bridge_manifest => $route->{bridge_manifest},
        backend_inputs => $route->{backend_inputs},
        artifact_root => $artifact_root,
        backend_profile => 'sv_portable_verilator',
    });
    is($public->{diagnostics}[0]{code}, 'VIAL_BACKEND_UNSUPPORTED',
        'the public emitter rejects revision 2');
    is_deeply($public->{artifacts}, [],
        'public rejection constructs no artifact');
    is_deeply(
        $public->{negotiation}{unsatisfied},
        [
            'hial_vial.bridge_qualification.balanced_portable_v2',
            'hial_vial.bridge_source.ial1',
        ],
        'public rejection names only the two intentionally private requirements',
    );

    my $direct_private =
        'FSM::VIAL::Backend::SVPortableVerilator'
            ->emit_balanced_portable_qualification({
                execution_ir => $route->{execution_ir},
                bridge_manifest => $route->{bridge_manifest},
                backend_inputs => $route->{backend_inputs},
                artifact_root => $artifact_root,
                backend_profile => 'sv_portable_verilator',
            });
    is($direct_private->{diagnostics}[0]{code},
        'VIAL_BACKEND_INVOCATION_ERROR',
        'unsealed direct qualification call is rejected');
    is_deeply($direct_private->{artifacts}, [],
        'unsealed rejection constructs no artifact');

    my $original_execution = \&FSM::VIAL::ExecutionIR::as_hashref;
    my $changed_execution;
    {
        no warnings 'redefine';
        local *FSM::VIAL::ExecutionIR::as_hashref = sub {
            my $value = $original_execution->(@_);
            $value->{resource_summary}{bindings} = 2_047;
            return $value;
        };
        $changed_execution =
            FSM::VIAL::ArchitectureScaleBalancedPortableEmission::test_exact_emission(
                $route, $artifact_root,
            );
    }
    atomic_shape_rejection(
        $changed_execution, 'balanced:resource-summary',
        'changed ExecutionIR resource evidence',
    );

    my $original_bridge = \&FSM::HIAL::VIALBridge::Manifest::as_hashref;
    my $changed_bridge;
    {
        no warnings 'redefine';
        local *FSM::HIAL::VIALBridge::Manifest::as_hashref = sub {
            my $value = $original_bridge->(@_);
            $value->{protocols}[0]{facts}[0]{value} = 'other_emitter';
            return $value;
        };
        $changed_bridge =
            FSM::VIAL::ArchitectureScaleBalancedPortableEmission::test_exact_emission(
                $route, $artifact_root,
            );
    }
    atomic_shape_rejection(
        $changed_bridge, 'balanced:protocol',
        'changed bridge protocol evidence',
    );

    my $changed_inputs = clone($route->{backend_inputs});
    $changed_inputs->{dut_systemverilog}[0]{text} .= "\n";
    my $changed_backend =
        FSM::VIAL::ArchitectureScaleBalancedPortableEmission::test_exact_emission(
            $route, $artifact_root, $changed_inputs,
        );
    atomic_shape_rejection(
        $changed_backend, 'balanced:backend-inputs',
        'changed backend-input evidence',
    );

    like(dies(sub {
        $composer->_build_emission_route({construction => $construction});
    }), qr/caller-sealed/,
        'composer emission route rejects an unsealed caller');
    like(dies(sub {
        'FSM::VIAL::PlanBuilder'->_build_balanced_portable_backend_inputs({});
    }), qr/caller-sealed/,
        'PlanBuilder backend-input route rejects an unsealed caller');
};

subtest 'report regeneration and closed inputs reject mutation' => sub {
    my $validated = $qualifier->validate_report({
        construction => $construction,
        report => $report,
    });
    is($json->encode($validated), $json->encode($report),
        'independent canonical regeneration is byte-equal');

    my $changed = clone($report);
    $changed->{status} = 'claimed_runtime';
    like(dies(sub {
        $qualifier->validate_report({
            construction => $construction,
            report => $changed,
        });
    }), qr/report identity is invalid/,
        'mutated report fails before canonical comparison');
    like(dies(sub {
        $qualifier->evaluate({construction => $construction, injected => {}});
    }), qr/unknown key 'injected'/,
        'evaluation rejects injected route evidence');
    like(dies(sub {
        'Subclass'->FSM::VIAL::ArchitectureScaleBalancedPortableEmission::report_keys;
    }), qr/exact class invocant/,
        'public methods reject a borrowed invocant');
};

subtest 'same-volume staging cleans success and consumer failure' => sub {
    my $stage_abs = File::Spec->catdir(
        $repo_root, split m{/}, $construction->{workload}{staging_identity},
    );
    my $seen = 0;
    my $success = $qualifier->with_staging({
        construction => $construction,
        repository_root => $repo_root,
        consumer => sub {
            my ($context) = @_;
            $seen = scalar(@{$context->{inputs}});
            ok(-d $context->{staging_root} && !-l $context->{staging_root},
                'consumer receives a real repository-volume directory');
        },
    });
    ok($success->{ok} && $success->{same_volume} && $success->{removed},
        'successful staging proves same-volume placement and removal');
    is($seen, 2, 'consumer sees only the canonical HIAL/VIAL pair');
    ok(!-e $stage_abs && !-l $stage_abs,
        'success leaves no staging residue');

    my $failed = $qualifier->with_staging({
        construction => $construction,
        repository_root => $repo_root,
        consumer => sub { die "consumer failure at $repo_root/sensitive\n" },
    });
    ok(!$failed->{ok}, 'consumer failure is reported');
    is($failed->{diagnostics}[0]{code}, 'VIAL_SCALE_CONSUMER_ERROR',
        'consumer failure retains the stable diagnostic family');
    unlike($json->encode($failed), qr{\Q$repo_root\E},
        'consumer diagnostic redacts the machine-local repository path');
    ok(!-e $stage_abs && !-l $stage_abs,
        'consumer failure leaves no staging residue');
};

done_testing();

sub repo_path {
    return File::Spec->catfile($repo_root, @_);
}

sub atomic_shape_rejection {
    my ($result, $reason, $label) = @_;
    is($result->{diagnostics}[0]{code}, 'VIAL_BACKEND_UNSUPPORTED',
        "$label rejects before artifact construction");
    is_deeply($result->{artifacts}, [], "$label leaves no partial artifact");
    ok(scalar(grep { $_ eq $reason }
            @{$result->{negotiation}{unsatisfied} || []}),
        "$label identifies the exact unsatisfied boundary");
}

sub dies {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? '' : "$@";
}

sub clone {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read '$path': $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "cannot close '$path': $!";
    return $text;
}
