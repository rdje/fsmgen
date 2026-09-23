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
            'osvvm-ghdl-execution-plan/d80c4533fc3181d0027814a685da88a29d4d4277dfc9a85e1a3bfd9cb1d66515',
        settings =>
            'd48d2be3023e61e712eb167af93aa6e30116922e50cb4617c7e843c174872ede',
        source =>
            'source/7e21df531a86a5a023f811fc02acb53db5cbdc7c182aacc1b215474ec30b5b04',
    },
    gate_candidate_v1 => {
        plan =>
            'osvvm-ghdl-execution-plan/9c37ac1b03fb060f36f9c09f804be4df0ca70a571cfd4a7a002b5c7ba2ccb542',
        settings =>
            '9e139cd59927986bbf362c29b968300042cde234e7b447694d601ddfdd18a1c7',
        source =>
            'source/5c392b879cadec2da0c143e297469f154b5daa2610d29c1277c3f0db84c12f53',
    },
    qualification_candidate_v1 => {
        plan =>
            'osvvm-ghdl-execution-plan/56c2dabfe0a12dc7ed322dde18b1f4673cb7ac52e9b3d763da9a7327d367cbce',
        settings =>
            '545014fef057e0defa75c7307d8c0438c59836d0a5d6522895d1d517b7870190',
        source =>
            'source/f331a858130d76d445879b66cca38165138f748339e503bc0c7d8254d4fc5bef',
    },
);
my %report;
my $provider_root = File::Spec->catdir(
    $repo_root, '.artifacts', 'cache', 'providers', 'osvvm', '2026.05', 'source',
);
my $provider_present = -d $provider_root && !-l $provider_root
    && -e File::Spec->catfile($provider_root, '.git')
    && !-l File::Spec->catfile($provider_root, '.git');

subtest 'three materialized roles own one exact closed provider/tool plan' => sub {
    plan skip_all => 'exact OSVVM 2026.05 provider cache is absent on an ordinary checkout'
        unless $provider_present;
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
    plan skip_all => 'exact OSVVM 2026.05 provider cache is absent on an ordinary checkout'
        unless $provider_present;
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
    plan skip_all => 'exact OSVVM 2026.05 provider cache is absent on an ordinary checkout'
        unless $provider_present;
    my $oracle = $report{reference_v1}{qualifier_oracle};
    is($oracle->{status}, 'byte_exact_executable_oracle',
        'oracle status is explicit');
    is($oracle->{qualification_id},
        'qualification/fe49e8b23dfc671349cd407c0a17df1be6ba00262402de149daf9f60aee7b278',
        'checked qualification identity is exact');
    is($oracle->{bytes}, 74_976, 'checked report byte size is exact');
    is($oracle->{sha256},
        'd397bed3a9820fec473af8f070bb3f5b9a18e4b5ff925286c1458fab46f8b9ab',
        'checked report bytes are sealed');
    is($oracle->{generated_settings_sha256},
        '2f48ef01a4fedccb02ec990a7cc6d98e84d6a7cb180cae5ccb4a68061f54d0cc',
        'qualifier settings bytes come from the extracted authority');
    is($oracle->{command_projection_sha256},
        'a5de1a59a3d7f4612c46153475bb3dad614a0fb208a931144a72b963ef26bb48',
        'every checked qualifier command matches the extracted plan');
};

subtest 'caller substitution, mutation, preflight, and invocant bypass fail' => sub {
    plan skip_all => 'exact OSVVM 2026.05 provider cache is absent on an ordinary checkout'
        unless $provider_present;
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
