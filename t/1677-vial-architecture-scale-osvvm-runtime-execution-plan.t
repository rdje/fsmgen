#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleOSVVMRuntimeExecutionPlan;

my $class = 'FSM::VIAL::ArchitectureScaleOSVVMRuntimeExecutionPlan';
my $repo_root = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::Bin, '..'),
);
my $json = JSON::PP->new->canonical(1);
my @levels = qw(
    reference_v1 gate_candidate_v1 qualification_candidate_v1
);
my %expected = (
    reference_v1 => {
        plan =>
            'osvvm-ghdl-execution-plan/3639c39639ca5dbbdc5a715dd919617137beebdec13c37ee28011628c6981483',
        settings =>
            '232c837ee8080859ed006601c0f32bc066433e45974546d46cab53c584f567ad',
        source =>
            'source/d479aeca91f41ee74d2572d1324e771aa922911b37b0ae4389ed215eac57ec53',
    },
    gate_candidate_v1 => {
        plan =>
            'osvvm-ghdl-execution-plan/3adc10d1d81888b4d6c920413411f3e554bceaab2e6ce8cb0f10efbbed3f075e',
        settings =>
            'ad46bfc343691cc0cb8c975323105a040769d3f992a8ce2a7ff9fd3155ed81ea',
        source =>
            'source/5eba85abfc7ea62f3a959bef724f8b11dc5bb94b42845b8a9d4c3c633ee13463',
    },
    qualification_candidate_v1 => {
        plan =>
            'osvvm-ghdl-execution-plan/7e35cfc36d528327535648026d382455148cc55ca370d3e540f53b8a576f6307',
        settings =>
            '456532f388b3fa51f14c9a55ac16a777c8bd191065a7b81b6c771a6aa27e22be',
        source =>
            'source/d4450e0b195c095f1927891bf6ee8a0aebeffc3c102e0d0bb40850392a44aa69',
    },
);
my %report;

subtest 'three materialized roles own one exact closed provider/tool plan' => sub {
    is_deeply($class->owned_shapes, [map {{
        backend_profile => 'vhdl_osvvm_qualified', level => $_,
    }} @levels], 'plan authority owns only the three materialized roles');

    for my $level (@levels) {
        my $actual = $class->evaluate({
            repository_root => $repo_root, level => $level,
        });
        $report{$level} = $actual;
        is_deeply([sort keys %$actual], [sort @{$class->report_keys}],
            "$level report is closed");
        is($actual->{status}, 'closed_not_executed',
            "$level remains a structural plan");
        is($actual->{plan_identity}, $expected{$level}{plan},
            "$level plan identity is exact");
        is($actual->{generated_settings}{sha256},
            $expected{$level}{settings},
            "$level generated settings are content-addressed");
        is($actual->{source_authority}{source_identity},
            $expected{$level}{source},
            "$level generated/probe source authority is exact");
        is(scalar(@{$actual->{provider_authority}{provider_sources}}), 61,
            "$level seals every provider analysis input");
        is(scalar(@{$actual->{source_authority}{generated_sources}}), 7,
            "$level seals all emitted VHDL sources");
        is(scalar(@{$actual->{source_authority}{ordered_analysis_relpaths}}),
            8, "$level adds only the checked provider probe");
        is(scalar(@{$actual->{commands}{provider_analyze}}), 61,
            "$level closes every provider analysis command");
        is(scalar(@{$actual->{report_inventory}}), 4,
            "$level owns the complete supplementary report inventory");
        ok($actual->{claims}{provider_sources_sealed}
                && $actual->{claims}{generated_sources_sealed}
                && $actual->{claims}{tool_sealed}
                && $actual->{claims}{commands_sealed},
            "$level binds every authority leg");
        ok(!$actual->{claims}{external_tool_executed}
                && !$actual->{claims}{staging_created}
                && !$actual->{claims}{runtime_executed},
            "$level creates no stage and executes no tool");
        ok(!-e repo_path($actual->{storage_authority}{staging_identity}),
            "$level canonical stage identity remains unmaterialized");
    }

    isnt($report{reference_v1}{source_authority}{source_identity},
        $report{gate_candidate_v1}{source_authority}{source_identity},
        'gate source identity cannot alias reference');
    isnt($report{gate_candidate_v1}{source_authority}{source_identity},
        $report{qualification_candidate_v1}{source_authority}{source_identity},
        'qualification source identity cannot alias gate');
};

subtest 'source order, commands, limits, paths, and reports are exact' => sub {
    my $reference = $report{reference_v1};
    is($reference->{tool_authority}{archive}{bytes}, 37_155_806,
        'official archive byte identity is sealed');
    is($reference->{tool_authority}{archive}{sha256},
        'c21312d5a0cc5833e6d8690d8c4343e67f4fc32f070c07343816cd11a31c7769',
        'official archive digest is sealed');
    is($reference->{tool_authority}{binary}{sha256},
        '38a99c1cc18b04dfae128b118c7344910e08b8ba6eeb9c1e67f950a84bca3c3d',
        'materialized GHDL binary is sealed');
    is($reference->{provider_authority}{root_commit},
        '2f7c391051dfb11890fa4bdbda9918d1db492250',
        'OSVVM commit is sealed');
    is($reference->{provider_authority}{root_tree},
        'bd4fdc594f2c26d564cf8907ff599578b9a39e22',
        'OSVVM tree is sealed');

    my @command_names = qw(
        version provider_analyze analyze_generated elaborate_fixture
        run_fixture elaborate_provider_probe run_provider_probe
    );
    is_deeply([sort keys %{$reference->{commands}}],
        [sort @command_names], 'command family is closed');
    is($reference->{commands}{version}{timeout_seconds}, 10,
        'version deadline is exact');
    is($reference->{commands}{provider_analyze}[0]{timeout_seconds}, 120,
        'each provider analysis deadline is exact');
    is($reference->{commands}{run_fixture}{capture_limit_bytes}, 67_108_864,
        'fixture capture ceiling is exact');
    is($reference->{commands}{run_provider_probe}{capture_limit_bytes},
        8_388_608, 'probe capture ceiling is exact');
    is($reference->{commands}{elaborate_fixture}{argv}[-1],
        'base_output_arbitration_tb', 'fixture top is exact');
    is($reference->{commands}{elaborate_provider_probe}{argv}[-1],
        'fsmgen_vial_osvvm_runtime_probe', 'provider-probe top is exact');
    is_deeply([map { $_->{name} } @{$reference->{report_inventory}}], [qw(
        OsvvmRun.yml AlertLogTop_alerts.yml AlertLogTop_cov.yml
        AlertLogTop_sb_slv.yml
    )], 'supplementary report order is exact');

    for my $level (@levels) {
        my $actual = $report{$level};
        for my $path (
            $actual->{tool_authority}{root},
            $actual->{tool_authority}{archive}{relpath},
            $actual->{tool_authority}{binary}{relpath},
            $actual->{provider_authority}{dependency_root},
            $actual->{storage_authority}{staging_identity},
            $actual->{generated_settings}{relpath},
            map({ $_->{relpath} }
                @{$actual->{source_authority}{generated_sources}}),
            map({ $_->{relpath} } @{$actual->{report_inventory}}),
        ) {
            unlike($path, qr{(?:\A/|\A~|\A[A-Za-z]:|\\|(?:\A|/)\.\.(?:/|\z))},
                "$level retains only safe repository-relative paths");
        }
    }
};

subtest 'the checked qualifier remains the byte-exact executable oracle' => sub {
    my $oracle = $report{reference_v1}{qualifier_oracle};
    is($oracle->{status}, 'byte_exact_executable_oracle',
        'oracle status is explicit');
    is($oracle->{qualification_id},
        'qualification/67e01b077b3f74c358631262cbf7d76f95bdda83d0855b62dee2d90cd0d8e605',
        'checked qualification identity is unchanged');
    is($oracle->{bytes}, 74_976, 'checked report byte size is exact');
    is($oracle->{sha256},
        'e83c1a346c31cde5b516e1b6d19696f0c63e05902a31f945f011f23e2268f1fa',
        'checked report bytes are sealed');
    is($oracle->{generated_settings_sha256},
        'c48fa4057f500800de47540905b4dee315598c8c01b31ea5e249355c695b7b67',
        'qualifier settings bytes come from the extracted authority');
    is($oracle->{command_projection_sha256},
        '75b7724e0ed8bf2d47855459cd285fa6bd6bd8a821950e57a7ab4620c778a024',
        'every checked qualifier command matches the extracted plan');
};

subtest 'caller substitution, mutation, preflight, and invocant bypass fail' => sub {
    my $validated = $class->validate_report({
        repository_root => $repo_root,
        report => $report{reference_v1},
    });
    is($validated->{plan_identity}, $expected{reference_v1}{plan},
        'canonical report validates by independent reconstruction');

    my $mutated = clone($report{reference_v1});
    push @{$mutated->{commands}{run_fixture}{argv}}, '--foreign-option';
    my $accepted = eval {
        $class->validate_report({
            repository_root => $repo_root, report => $mutated,
        });
        1;
    };
    ok(!$accepted, 'caller-mutated command report rejects');
    like($@, qr/report is not canonical/,
        'mutation rejection names the canonical plan boundary');

    my $limit = eval {
        $class->evaluate({
            repository_root => $repo_root, level => 'limit_v1',
        });
        1;
    };
    ok(!$limit, 'preflight-dominated level cannot acquire a tool plan');
    like($@, qr/level is not selected/,
        'preflight rejection occurs before provider or tool access');

    my $unknown = eval {
        $class->evaluate({
            repository_root => $repo_root, level => 'reference_v1', extra => 1,
        });
        1;
    };
    ok(!$unknown, 'unknown caller input cannot substitute plan authority');
    like($@, qr/unknown key 'extra'/, 'closed invocation reports exact key');

    my $authority = eval { $class->_qualification_authority; 1 };
    ok(!$authority, 'qualification authority seam rejects a direct caller');
    like($@, qr/authority is caller-sealed/,
        'authority seam names its caller seal');
    my $plan = eval {
        $class->_qualification_plan({
            staging_identity =>
                '.artifacts/tmp/vial-osvvm-ghdl-qualification/' . ('0' x 64),
        });
        1;
    };
    ok(!$plan, 'qualification plan seam rejects a direct caller');
    like($@, qr/plan is caller-sealed/,
        'plan seam names its caller seal');

    {
        package Local::OSVVMExecutionPlanSubclass;
        our @ISA = ('FSM::VIAL::ArchitectureScaleOSVVMRuntimeExecutionPlan');
    }
    my $subclass = eval {
        Local::OSVVMExecutionPlanSubclass->evaluate({
            repository_root => $repo_root, level => 'reference_v1',
        });
        1;
    };
    ok(!$subclass, 'subclass invocant cannot widen the exact authority');
    like($@, qr/exact class invocant/,
        'subclass rejection names exact invocant boundary');
};

done_testing();

sub repo_path {
    return File::Spec->catfile($repo_root, split m{/}, $_[0]);
}

sub clone {
    return $json->decode($json->encode($_[0]));
}
