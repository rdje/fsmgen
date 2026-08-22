#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleBalancedPortable;

my $class = 'FSM::VIAL::ArchitectureScaleBalancedPortable';
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $reference_hial = slurp_raw(repo_path(
    'ppif', 'ahb_lite_subordinate.ppif'));
my $reference_vial = slurp_raw(repo_path(
    'vial', 'ahb_subordinate_base_output_arbitration.vial'));
my @nonclaims = qw(
    architecture_scale_capacity whole_product_big whole_product_really_big
    multi_unit multi_domain mixed_language native_uvm_runtime full_language
    synthesis general_cross_backend_parity
);
my @gate_family = qw(
    semantic_catalog_v1 bridge_fanout_v1 execution_graph_v1
    checking_state_v1 backend_emission_v1 runtime_stream_v1
);
my @gate_axis = qw(
    record_fields endpoints bindings random_occurrences artifact_graph
    runtime_trace_records
);

sub construction {
    return $class->construct({
        reference_hial_text => $reference_hial,
        reference_vial_text => $reference_vial,
    });
}

my $construction;
my $report;

subtest 'canonical construction owns ordinary path-independent sources' => sub {
    my $first = construction();
    my $second = construction();
    ok($first->{ok}, 'balanced source construction succeeds');
    is($first->{status}, 'canonical_sources_constructed',
        'construction states only its completed source boundary');
    is($json->encode($second), $json->encode($first),
        'independent source constructions are byte-equal');
    is($first->{workload}{specification}{family}, 'balanced_portable_v1',
        'construction consumes the sole catalog-owned balanced family');
    is($first->{workload}{specification}{level}, 'gate_candidate_v1',
        'balanced shape remains an unqualified gate candidate');
    is($first->{workload}{specification}{primary_axis},
        'interaction_profile', 'construction consumes the catalog axis');
    is($first->{workload}{specification}{backend_profile},
        'sv_portable_verilator', 'portable SV is the sole eligible backend');
    is_deeply($first->{workload}{specification}{explicit_nonclaims},
        \@nonclaims, 'every architecture-scale nonclaim is retained');
    is_deeply(
        [map { $_->{relative_path} } @{$first->{workload}{inputs}}],
        [
            'generated/vial-scale/balanced-portable/'
                . 'vial_architecture_scale_balanced_portable.isf',
            'generated/vial-scale/balanced-portable/'
                . 'vial_architecture_scale_balanced_portable.vial',
        ],
        'workload contains only repository-relative ordinary HIAL/VIAL source',
    );
    my @declared_paths = (
        map({ $_->{relative_path} } @{$first->{reference_sources}}{qw(hial vial)}),
        map({ $_->{relative_path} } @{$first->{workload}{inputs}}),
        map({ $_->{relative_path} } @{$first->{workload}{input_identities}}),
        $first->{workload}{staging_identity},
    );
    ok(!scalar(grep { m{\A/|(?:\A|/)\.\.(?:/|\z)} } @declared_paths),
        'every construction path is repository-relative and non-traversing');
    like($first->{workload}{inputs}[0]{content},
        qr/\(profile balanced_portable\).*\(revision 2\)/,
        'ordinary HIAL source carries the selected revision-2 profile');
    like($first->{workload}{inputs}[1]{content},
        qr/\(fixture balanced_gate\b/,
        'ordinary VIAL source carries the canonical balanced fixture');
    $construction = $first;
};

subtest 'all six fresh gates precede the exact balanced interaction proof' => sub {
    $report = $class->evaluate({construction => $construction});
    ok($report->{ok}, 'complete canonical composition validates');
    diag($json->encode($report->{diagnostics})) unless $report->{ok};
    return unless $report->{ok};

    is($report->{status}, 'canonical_composition_validated',
        'report states only provider-free composition validation');
    like($report->{report_identity},
        qr{\Abalanced-composition/[0-9a-f]{64}\z},
        'complete report has one content address');
    like($report->{rerun_identity}, qr{\Arerun/[0-9a-f]{64}\z},
        'independent canonical rerun has one identity');
    like($report->{replay_identity}, qr{\Areplay/[0-9a-f]{64}\z},
        'balanced keyed replay has one identity');

    is_deeply([map { $_->{family} } @{$report->{gate_evidence}}],
        \@gate_family, 'fresh evidence covers exactly the six families');
    is_deeply([map { $_->{primary_axis} } @{$report->{gate_evidence}}],
        \@gate_axis, 'each family uses its closed representative gate');
    is_deeply([map { $_->{level} } @{$report->{gate_evidence}}],
        [('gate_candidate_v1') x 6],
        'every prerequisite is freshly evaluated at the gate level');
    ok(!scalar(grep { !$_->{substantive_oracle} }
            @{$report->{gate_evidence}}),
        'every fresh report passes a family-specific substantive oracle');
    ok(!scalar(grep { ($_->{report_sha256} // '')
            !~ /\A[0-9a-f]{64}\z/ } @{$report->{gate_evidence}}),
        'every consumed full gate report has a content digest');

    my $expected = {
        selected_units => 1,
        selected_domains => 1,
        endpoints => 128,
        transactions => 16,
        transaction_fields => 1_744,
        events => 128,
        probes => 32,
        scenarios => 32,
        operations_total => 1_024,
        fibers_total => 128,
        simultaneously_live_fibers => 32,
        bindings => 2_048,
        execution_types => 512,
        model_instances => 32,
        scalar_model_state_cells => 512,
        scoreboard_instances => 32,
        scoreboard_capacity => 4_096,
        coverpoints => 256,
        coverage_bins => 4_096,
        faults => 32,
        random_occurrences => 1_024,
    };
    is_deeply(
        {map { $_ => $report->{metrics}{$_} } sort keys %$expected},
        {map { $_ => $expected->{$_} } sort keys %$expected},
        'report proves the complete decision-0055 interaction vector',
    );
    is_deeply($report->{metrics}{fields_per_transaction}, [(109) x 16],
        'all 1,744 fields remain evenly and genuinely bound');
    is_deeply($report->{logical_time}{phase_order},
        [qw(drive sample react check)], 'logical phase order is exact');
    is_deeply($report->{logical_time}{tie_break_order}, [qw(
        domain_rank static_operation_rank local_emission_index semantic_id
    )], 'logical tie-break order is exact');
    ok($report->{logical_time}{exact}, 'all logical-time invariants pass');
    is_deeply($report->{fiber_semantics}{scenario_fiber_counts},
        [32, (4) x 3, (3) x 28],
        'fiber distribution derives 128 total and 32 live without padding');
    is_deeply($report->{fiber_semantics}{scenario_operation_counts},
        [60, (32) x 3, (31) x 28],
        'scenario operation distribution derives exactly 1,024 operations');
    ok($report->{fiber_semantics}{topology_exact},
        'fiber topology and joins are exact');

    ok($report->{checking_semantics}{models_have_sixteen_increment_rules},
        '32 models own 512 exercised scalar update rules');
    ok($report->{checking_semantics}
            {scoreboards_exercise_expect_start_check},
        '32 capacity-128 scoreboards exercise expect/start/check structure');
    ok($report->{checking_semantics}
            {coverpoints_have_sixteen_authored_bins},
        '256 coverpoints retain 4,096 authored bins');
    ok($report->{checking_semantics}{faults_have_one_cycle_activation},
        'all 32 faults retain bounded activation semantics');
    is($report->{random_semantics}{algorithm},
        'sha256_counter_rejection_v1', 'keyed random algorithm is exact');
    is($report->{random_semantics}{occurrence_count}, 1_024,
        'all keyed random occurrences are materialized');
    ok($report->{random_semantics}{occurrences_unique},
        'all random occurrence identities are unique');
    ok($report->{random_semantics}{normalized_plans_equal},
        'generated and replayed plans are normalized-equal');
    ok(!$report->{claims}{portable_emission_qualified}
            && !$report->{claims}{external_tool_executed}
            && !$report->{claims}{runtime_executed}
            && !$report->{claims}{support_claimed}
            && !$report->{claims}{performance_claimed}
            && !$report->{claims}{capacity_claimed},
        'emission, tool, runtime, support, performance, and capacity remain unclaimed');
};

subtest 'reports and private seams reject hostile mutation' => sub {
    my $validated = $class->validate_report({
        construction => $construction,
        report => $report,
    });
    is($json->encode($validated), $json->encode($report),
        'independent defensive regeneration accepts the canonical report');

    my $mutated_report = clone($report);
    $mutated_report->{metrics}{bindings}--;
    my $report_error = dies(sub {
        $class->validate_report({
            construction => $construction,
            report => $mutated_report,
        });
    });
    like($report_error, qr/identity does not cover its payload/,
        'report mutation fails at the content-address boundary');

    my $mutated_source = clone($construction);
    $mutated_source->{workload}{inputs}[1]{content} .= ' ';
    my $source_error = dies(sub {
        $class->evaluate({construction => $mutated_source});
    });
    like($source_error, qr/construction is not canonical/,
        'source mutation is rejected before any gate or canonical stage');

    my $injection_error = dies(sub {
        $class->construct({
            reference_hial_text => $reference_hial,
            reference_vial_text => $reference_vial,
            gate_reports => [],
        });
    });
    like($injection_error, qr/unknown key.*gate_reports/,
        'callers cannot inject gate reports');

    my $route_error = dies(sub {
        $class->_canonical_route($construction->{workload});
    });
    like($route_error,
        qr{private to FSM::VIAL::ArchitectureScaleBalancedPortable},
        'callers cannot bypass gate admission through the canonical route');
    my $bridge_error = dies(sub { $class->_call_bridge({}) });
    like($bridge_error, qr/requires the exact composer invocant/,
        'callers cannot borrow the composer bridge seal');
    my $execution_error = dies(sub { $class->_call_execution({}) });
    like($execution_error, qr/requires the exact composer invocant/,
        'callers cannot borrow the composer execution seal');
};

subtest 'same-volume staging cleans success and consumer failure exactly' => sub {
    my $stage_abs = File::Spec->catdir(
        $repo_root, split(m{/}, $construction->{workload}{staging_identity}),
    );
    ok(!-e $stage_abs && !-l $stage_abs,
        'deterministic repository-local staging root begins absent');
    my $seen = 0;
    my $success = $class->with_staging({
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
    is($seen, 2, 'consumer sees exactly the canonical HIAL/VIAL pair');
    ok(!-e $stage_abs && !-l $stage_abs,
        'successful consumer leaves no stage residue');

    my $failed = $class->with_staging({
        construction => $construction,
        repository_root => $repo_root,
        consumer => sub { die "consumer failure at $repo_root/sensitive\n" },
    });
    ok(!$failed->{ok}, 'consumer failure is reported');
    is($failed->{diagnostics}[0]{code}, 'VIAL_SCALE_CONSUMER_ERROR',
        'consumer failure retains the stable diagnostic family');
    unlike($json->encode($failed), qr{\Q$repo_root\E},
        'failure diagnostics redact the exact machine-local repository path');
    ok(!-e $stage_abs && !-l $stage_abs,
        'consumer failure leaves no stage residue');
};

done_testing();

sub dies {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? '' : "$@";
}

sub clone {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}

sub repo_path {
    return File::Spec->catfile($repo_root, @_);
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read '$path': $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "cannot close '$path': $!";
    return $text;
}
