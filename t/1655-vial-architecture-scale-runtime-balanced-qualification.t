#!/usr/bin/env perl

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleRuntimeBalancedQualification;

my $class = 'FSM::VIAL::ArchitectureScaleRuntimeBalancedQualification';
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $reference_hial = slurp_raw(repo_path(
    'ppif', 'ahb_lite_subordinate.ppif'));
my $reference_vial = slurp_raw(repo_path(
    'vial', 'ahb_subordinate_base_output_arbitration.vial'));
my @profiles = qw(
    sv_portable_verilator
    vhdl_portable_ghdl
    vhdl_osvvm_qualified
);
my @levels = qw(
    reference_v1 gate_candidate_v1 qualification_candidate_v1
    limit_v1 over_limit_v1
);
my @nonclaims = qw(
    architecture_scale_capacity whole_product_big whole_product_really_big
    multi_unit multi_domain mixed_language native_uvm_runtime full_language
    synthesis general_cross_backend_parity
);
my @report_keys = qw(
    ok status schema schema_version report_identity rerun_identity
    source_identity ownership members oracle_applicability claims
    explicit_nonclaims diagnostics
);
my @member_keys = qw(
    member_id family backend_profile level construction_identity
    construction_sha256 report_sha256 report_identity rerun_identity
    applicability_sha256 claims_sha256 nonclaims_sha256 report
);
my @stages = qw(
    construct semantic bridge plan backend_inputs emit compile runtime trace
    result failure
);
my $report;

subtest 'closed ownership contains fifteen runtime and one balanced member' => sub {
    my @expected = map {
        my $profile = $_;
        map {{
            family => 'runtime_stream_v1',
            backend_profile => $profile,
            level => $_,
        }} @levels
    } @profiles;
    push @expected, {
        family => 'balanced_portable_v1',
        backend_profile => 'sv_portable_verilator',
        level => 'gate_candidate_v1',
    };
    is_deeply($class->owned_shapes, \@expected,
        'the unified gate owns exactly the closed sixteen-member partition');
    my $defensive = $class->owned_shapes;
    $defensive->[0]{level} = 'forged';
    is($class->owned_shapes->[0]{level}, 'reference_v1',
        'ownership callers receive a defensive value');
};

subtest 'provider-free gate preserves every authoritative member report' => sub {
    $report = $class->evaluate({
        reference_hial_text => $reference_hial,
        reference_vial_text => $reference_vial,
    });
    ok($report->{ok}, 'unified provider-free qualification succeeds');
    diag($json->encode($report->{diagnostics})) unless $report->{ok};
    return unless $report->{ok};

    is($report->{status}, 'provider_free_construction_qualified',
        'status stops at the completed construction boundary');
    is($report->{schema},
        'fsmgen.vial_architecture_scale_runtime_balanced_qualification_report.v1',
        'the gate has one dedicated revision-1 report schema');
    is_deeply([sort keys %$report], [sort @report_keys],
        'the unified report schema is closed');
    is_deeply($class->report_keys, \@report_keys,
        'the public report-key authority is exact');
    like($report->{report_identity},
        qr{\Aruntime-balanced-qualification/[0-9a-f]{64}\z},
        'the complete report has one content address');
    like($report->{rerun_identity},
        qr{\Aruntime-balanced-reruns/[0-9a-f]{64}\z},
        'all member reruns have one aggregate identity');

    is_deeply($report->{source_identity}, {
        hial => {
            relative_path => 'ppif/ahb_lite_subordinate.ppif',
            bytes => 1_326,
            sha256 => sha256_hex($reference_hial),
        },
        vial => {
            relative_path =>
                'vial/ahb_subordinate_base_output_arbitration.vial',
            bytes => 4_986,
            sha256 => sha256_hex($reference_vial),
        },
    }, 'checked reference source bytes are bound explicitly');
    is_deeply($report->{ownership}, {
        schema => 'fsmgen.vial_architecture_scale_runtime_balanced_ownership.v1',
        schema_version => 1,
        runtime_family => 'runtime_stream_v1',
        runtime_profile_count => 3,
        runtime_level_count => 5,
        runtime_member_count => 15,
        balanced_family => 'balanced_portable_v1',
        balanced_member_count => 1,
        total_member_count => 16,
        ownership_identity => $report->{ownership}{ownership_identity},
    }, 'ownership counts and families remain explicit');
    like($report->{ownership}{ownership_identity},
        qr{\Aruntime-balanced-ownership/[0-9a-f]{64}\z},
        'the exact ownership partition is content-addressed');

    is(scalar(@{$report->{members}}), 16,
        'every owned member contributes evidence');
    is_deeply([map { $_->{member_id} } @{$report->{members}}], [
        (map {
            my $profile = $_;
            map { "runtime_stream_v1/$profile/$_" } @levels
        } @profiles),
        'balanced_portable_v1/sv_portable_verilator/gate_candidate_v1',
    ], 'member order is deterministic and ownership-exact');

    for my $index (0 .. $#{$report->{members}}) {
        my $member = $report->{members}[$index];
        is_deeply([sort keys %$member], [sort @member_keys],
            "member $index schema is closed");
        ok($member->{report}{ok}, "member $index report succeeded");
        like($member->{construction_sha256}, qr{\A[0-9a-f]{64}\z},
            "member $index construction has one SHA-256 identity");
        is($member->{report_sha256},
            sha256_hex($json->encode($member->{report})),
            "member $index retains its complete report bytes");
        is($member->{report_identity}, $member->{report}{report_identity},
            "member $index preserves child report authority");
        is($member->{rerun_identity}, $member->{report}{rerun_identity},
            "member $index preserves child rerun authority");
        is($member->{claims_sha256},
            sha256_hex($json->encode($member->{report}{claims})),
            "member $index binds the child claim set");
        is($member->{nonclaims_sha256},
            sha256_hex($json->encode($member->{report}{explicit_nonclaims})),
            "member $index binds the child nonclaims");
        is_deeply($member->{report}{explicit_nonclaims}, \@nonclaims,
            "member $index retains every explicit nonclaim");
    }
    is_deeply(
        [map { "$_->{stage}:$_->{status}:$_->{completed_members}/"
                . "$_->{applicable_members}" }
            @{$report->{oracle_applicability}}],
        [
            'construct:completed:16/16',
            'semantic:completed:16/16',
            'bridge:completed:16/16',
            'plan:completed:16/16',
            'backend_inputs:completed:16/16',
            'emit:family_partial:1/16',
            'compile:not_run:0/16',
            'runtime:not_run:0/16',
            'trace:not_materialized:0/16',
            'result:not_produced:0/16',
            'failure:specified_not_observed:0/15',
        ],
        'stage summary preserves family-specific applicability and limits',
    );
    is_deeply([map { $_->{stage} } @{$report->{oracle_applicability}}],
        \@stages, 'the complete normalized stage order is stable');
    ok(!scalar(grep {
            ($_->{authority} // '') ne 'embedded_member_reports'
        } @{$report->{oracle_applicability}}),
        'every summary row points back to full member authority');

    my $claims = $report->{claims};
    ok($claims->{qualification_only}
            && $claims->{ownership_partition_closed}
            && $claims->{all_members_constructed}
            && $claims->{all_member_reports_qualified}
            && $claims->{all_member_reruns_qualified}
            && $claims->{checked_reference_sources_bound}
            && $claims->{balanced_revision_2_structurally_emitted},
        'only completed provider-free qualifications are true');
    ok(!scalar(grep { $claims->{$_} } qw(
            provider_accessed external_tool_executed compile_executed
            runtime_executed trace_materialized result_produced
            support_claimed performance_claimed capacity_claimed
            structural_boundary_reached
        )), 'provider, runtime, product, and scale claims remain false');
    is_deeply($report->{explicit_nonclaims}, \@nonclaims,
        'the unified gate retains the complete nonclaim boundary');
    is_deeply($report->{diagnostics}, [],
        'qualified construction has no diagnostic');
};

subtest 'independent regeneration and hostile mutation fail closed' => sub {
    return unless $report && $report->{ok};
    my $validated = $class->validate_report({
        reference_hial_text => $reference_hial,
        reference_vial_text => $reference_vial,
        report => $report,
    });
    is($json->encode($validated), $json->encode($report),
        'independent full-gate regeneration is byte-identical');
    $validated->{members}[0]{report}{status} = 'mutated';
    isnt($validated->{members}[0]{report}{status},
        $report->{members}[0]{report}{status},
        'validated evidence is defensive');

    my $changed = clone($report);
    $changed->{claims}{runtime_executed} = JSON::PP::true;
    like(dies(sub {
        $class->validate_report({
            reference_hial_text => $reference_hial,
            reference_vial_text => $reference_vial,
            report => $changed,
        });
    }), qr/claim boundary changed/,
        'mutated runtime claim is rejected at the closed claim boundary');
    like(dies(sub {
        $class->evaluate({
            reference_hial_text => $reference_hial,
            reference_vial_text => $reference_vial,
            injected_report => {},
        });
    }), qr/unknown key 'injected_report'/,
        'callers cannot inject child evidence');
    like(dies(sub {
        $class->evaluate({
            reference_hial_text => "$reference_hial ",
            reference_vial_text => $reference_vial,
        });
    }), qr/checked-AHB HIAL byte length changed/,
        'changed source bytes are rejected before qualification');
    like(dies(sub {
        'Subclass'
            ->FSM::VIAL::ArchitectureScaleRuntimeBalancedQualification::owned_shapes;
    }), qr/exact class invocant/,
        'borrowed invocants cannot widen ownership');
};

subtest 'same-volume dual-family staging cleans success and failure' => sub {
    my @seen_roots;
    my $success = $class->with_staging({
        reference_hial_text => $reference_hial,
        reference_vial_text => $reference_vial,
        repository_root => $repo_root,
        consumer => sub {
            my ($context) = @_;
            @seen_roots = map { $context->{$_}{staging_root} }
                qw(runtime balanced);
            ok(!scalar(grep { !-d($_) || -l($_) } @seen_roots),
                'consumer sees two real repository-volume stages');
        },
    });
    ok($success->{ok} && $success->{same_volume} && $success->{removed},
        'dual-family success is on-volume and cleaned');
    ok(!scalar(grep { -e($_) || -l($_) } @seen_roots),
        'successful dual-family staging leaves no residue');

    @seen_roots = ();
    my $failed = $class->with_staging({
        reference_hial_text => $reference_hial,
        reference_vial_text => $reference_vial,
        repository_root => $repo_root,
        consumer => sub {
            my ($context) = @_;
            @seen_roots = map { $context->{$_}{staging_root} }
                qw(runtime balanced);
            die "intentional unified failure at $repo_root/private\n";
        },
    });
    ok(!$failed->{ok}, 'dual-family consumer failure remains visible');
    is($failed->{diagnostics}[0]{code},
        'VIAL_SCALE_UNIFIED_CONSUMER_ERROR',
        'failure uses one stable unified diagnostic');
    unlike($json->encode($failed), qr{\Q$repo_root\E},
        'failure diagnostics redact the machine-local repository path');
    ok(!scalar(grep { -e($_) || -l($_) } @seen_roots),
        'failed dual-family staging leaves no residue');
};

done_testing();

sub repo_path {
    return File::Spec->catfile($repo_root, @_);
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!";
    local $/;
    return <$fh>;
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
