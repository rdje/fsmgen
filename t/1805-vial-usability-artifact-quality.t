#!/usr/bin/env perl

use strict;
use warnings;

use bytes ();
use Digest::SHA qw(sha256_hex);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::VIALUsabilityArtifactQuality qw(
    build_vial_usability_artifact_quality_contract
    evaluate_vial_author_quality
    evaluate_vial_backend_artifact_quality
    vial_author_quality_report_keys
    vial_backend_artifact_quality_report_keys
    vial_usability_artifact_quality_contract_keys
);
use FSM::VIAL::Backend::OSVVM2026_05Materialization;
use FSM::VIAL::Backend::SVPortableVerilator;
use FSM::VIAL::Backend::SVUVMAccellera2020_3_1;
use FSM::VIAL::Backend::VHDLOSVVM2026_05;
use FSM::VIAL::Backend::VHDLPortableGHDL;
use FSM::VIAL::Parser;
use FSM::VIAL::PlanBuilder;
use FSM::VIAL::SourceProjection;

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $vial_name = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $hial_name = 'ppif/ahb_lite_subordinate.ppif';
my $artifact_root = '.artifacts/test/vial-usability-artifact-quality';
my $dependency_root = '.artifacts/cache/providers/osvvm/2026.05/source';
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $contract = build_vial_usability_artifact_quality_contract();

sub repo_path {
    my ($relative) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relative);
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!\n";
    local $/;
    my $text = <$fh> // '';
    close $fh or die "cannot close $path: $!\n";
    return $text;
}

sub clone {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}

sub v2_source {
    my ($source) = @_;
    my $converted = $source;
    $converted =~ s/\(version 1\)/\(version 2\)/
        or die "version selector not found\n";
    $converted =~ s/\n    \(fixtures/\n    (intents)\n    (fixtures/
        or die "fixture section not found\n";
    return $converted;
}

sub build_plan {
    my $source = slurp_raw(repo_path($vial_name));
    my $semantic_ir = FSM::VIAL::Parser->parse_source({
        text => $source,
        source_name => $vial_name,
        source_catalog => {},
    });
    return ($semantic_ir, FSM::VIAL::PlanBuilder->build({
        semantic_ir => $semantic_ir,
        hial_source => {
            source_id => $hial_name,
            text => slurp_raw(repo_path($hial_name)),
            format => 'ppif',
        },
        fixture_id => undef,
        scenario_ids => [],
        execution_profile => 'core_directed_single_clock_execution_v1',
        replay_manifest => undef,
        native_extension_catalog => [],
    }));
}

sub backend_args {
    my ($built, $profile) = @_;
    return {
        execution_ir => $built->{execution_ir},
        bridge_manifest => $built->{bridge_manifest},
        backend_inputs => $built->{backend_inputs},
        artifact_root => $artifact_root,
        backend_profile => $profile,
    };
}

sub refresh_source_map_reference {
    my ($emission, $path) = @_;
    my ($artifact) = grep { $_->{relpath} eq $path }
        @{$emission->{artifacts}};
    die "source artifact '$path' is not unique\n" unless $artifact;
    my ($reference) = grep { $_->{relpath} eq $path }
        @{$emission->{source_map}{artifacts}};
    die "source-map artifact '$path' is not unique\n" unless $reference;
    $reference->{sha256} = sha256_hex($artifact->{content});
    my $length_key = exists($reference->{bytes}) ? 'bytes' : 'byte_length';
    $reference->{$length_key} = bytes::length($artifact->{content});
}

sub elide_source_role {
    my ($emission, $role) = @_;
    my ($artifact) = grep { $_->{role} eq $role }
        @{$emission->{artifacts}};
    die "source role '$role' is not unique\n" unless $artifact;
    my $path = $artifact->{relpath};
    $emission->{artifacts} = [grep { $_->{relpath} ne $path }
        @{$emission->{artifacts}}];
    $emission->{source_map}{artifacts} = [grep { $_->{relpath} ne $path }
        @{$emission->{source_map}{artifacts}}];
    $emission->{source_map}{entries} = [grep {
        $_->{generated_relpath} ne $path
    } @{$emission->{source_map}{entries}}];
}

subtest 'quality contract is closed, deterministic, and defensive' => sub {
    is_deeply([sort keys %$contract],
        [sort @{vial_usability_artifact_quality_contract_keys()}],
        'contract exposes exactly its declared keys');
    like($contract->{contract_id}, qr{\Avial-quality/[0-9a-f]{64}\z},
        'contract identity is content-addressed');
    is_deeply($contract->{profile_ids}, [qw(
        sv_portable_verilator
        sv_uvm_emit.accellera_2020_3_1
        vhdl_osvvm_qualified
        vhdl_portable_ghdl
    )], 'contract owns exactly the four adapter profiles');
    is_deeply($contract->{author_surface_kinds}, [qw(
        public_example canonical_normal canonical_terse source_diagnostic
    )], 'all four target-free author surfaces are mandatory');
    is(scalar(@{$contract->{forbidden_vocabulary}}), 9,
        'finite target and methodology vocabulary has nine witnessed rules');
    for my $rule (@{$contract->{forbidden_vocabulary}}) {
        like($rule->{witness}, qr/$rule->{expression}/i,
            "$rule->{rule_id} retains a live RED witness");
    }
    is($json->encode(build_vial_usability_artifact_quality_contract()),
        $json->encode($contract), 'contract bytes are deterministic');
    $contract->{profiles}[0]{max_total_artifacts} = 1;
    is(build_vial_usability_artifact_quality_contract()
            ->{profiles}[0]{max_total_artifacts},
        8, 'callers receive defensive contract data');
    $contract = build_vial_usability_artifact_quality_contract();
};

my $v1_source = slurp_raw(repo_path($vial_name));
my $v2_source = v2_source($v1_source);
my $normal = FSM::VIAL::SourceProjection->format_source({
    text => $v2_source,
    source_name => $vial_name,
    output_style => 'normal',
})->{text};
my $terse = FSM::VIAL::SourceProjection->format_source({
    text => $v2_source,
    source_name => $vial_name,
    output_style => 'terse',
})->{text};
my $v1_ir = FSM::VIAL::Parser->parse_source({
    text => $v1_source, source_name => $vial_name, source_catalog => {},
});
my $v2_ir = FSM::VIAL::Parser->parse_source({
    text => $normal, source_name => $vial_name, source_catalog => {},
});
my $unknown_version = $normal;
$unknown_version =~ s/\(version 2\)/\(version 3\)/
    or die "normal version selector not found\n";
my $diagnostics = FSM::VIAL::Parser->check_source({
    text => $unknown_version,
    source_name => $vial_name,
    source_catalog => {},
})->{diagnostics};
my $author_args = {
    surfaces => [
        (map {{
            surface_id => $_,
            kind => 'public_example',
            text => slurp_raw(repo_path($_)),
        }} @{$contract->{public_fixture_paths}}),
        {surface_id => 'canonical/v2/normal', kind => 'canonical_normal',
            text => $normal},
        {surface_id => 'canonical/v2/terse', kind => 'canonical_terse',
            text => $terse},
        {surface_id => 'diagnostic/unknown-version', kind => 'source_diagnostic',
            text => $json->encode($diagnostics)},
    ],
    semantic_documents => [
        {document_id => 'semantic-ir/v1', kind => 'semantic_ir',
            value => $v1_ir->as_hashref},
        {document_id => 'semantic-ir/v2', kind => 'semantic_ir',
            value => $v2_ir->as_hashref},
        {document_id => 'semantic-families/v2',
            kind => 'semantic_family_carrier',
            value => $v2_ir->as_hashref->{packages}[0]{intent_families}},
    ],
};

subtest 'public examples, canonical forms, diagnostics, and semantics are target-free' => sub {
    my $report = evaluate_vial_author_quality($author_args);
    is_deeply([sort keys %$report],
        [sort @{vial_author_quality_report_keys()}],
        'author report is closed');
    ok($report->{accepted}, 'complete public author corpus passes');
    ok($report->{dimensions}{target_free_author_surface},
        'examples, normal/terse forms, and diagnostics are target-free');
    ok($report->{dimensions}{target_free_semantic_carrier},
        'v1/v2 SemanticIR and the family carrier contain no methodology plumbing');
    is($report->{surface_count},
        scalar(@{$contract->{public_fixture_paths}}) + 3,
        'every declared public fixture plus three derived surfaces was checked');
    is($report->{semantic_document_count}, 3,
        'both semantic versions and the family carrier were checked');
    ok($report->{checked_bytes} > 0,
        'author report accounts for all checked source bytes');
    is_deeply($report->{issues}, [], 'accepted author corpus has no issue');
    is(FSM::VIAL::SourceProjection->semantic_projection_sha256($v2_ir),
        FSM::VIAL::SourceProjection->semantic_projection_sha256(
            FSM::VIAL::Parser->parse_source({
                text => $terse, source_name => $vial_name,
                source_catalog => {},
            })),
        'target-free normal and terse forms retain one exact meaning');
};

subtest 'every forbidden target or methodology rule has author and semantic RED controls' => sub {
    for my $rule (@{$contract->{forbidden_vocabulary}}) {
        my $author_hostile = clone($author_args);
        $author_hostile->{surfaces}[0]{text} .= "\n$rule->{witness}\n";
        my $author_report = evaluate_vial_author_quality($author_hostile);
        ok(!$author_report->{accepted}
                && !$author_report->{dimensions}{target_free_author_surface},
            "$rule->{rule_id} fails the author surface");
        ok(scalar(grep {
            $_->{code} eq 'VIAL_AUTHOR_TARGET_VOCABULARY'
                && $_->{message} =~ /\Q$rule->{rule_id}\E/
        } @{$author_report->{issues}}),
            "$rule->{rule_id} reports its exact author cause");

        my $semantic_hostile = clone($author_args);
        $semantic_hostile->{semantic_documents}[2]{value} = [{
            hostile_methodology => $rule->{witness},
        }];
        my $semantic_report = evaluate_vial_author_quality($semantic_hostile);
        ok(!$semantic_report->{accepted}
                && !$semantic_report->{dimensions}{target_free_semantic_carrier},
            "$rule->{rule_id} fails the semantic carrier");
        ok(scalar(grep {
            $_->{code} eq 'VIAL_SEMANTIC_METHODOLOGY_LEAK'
                && $_->{message} =~ /\Q$rule->{rule_id}\E/
        } @{$semantic_report->{issues}}),
            "$rule->{rule_id} reports its exact semantic cause");
    }
};

subtest 'author gate requires every maintained public fixture' => sub {
    my $missing = clone($author_args);
    shift @{$missing->{surfaces}};
    my $report = evaluate_vial_author_quality($missing);
    ok(!$report->{accepted}
            && !$report->{dimensions}{target_free_author_surface},
        'removing one maintained public example fails author quality');
    ok(scalar(grep {
        $_->{code} eq 'VIAL_AUTHOR_PUBLIC_FIXTURE_MISSING'
    } @{$report->{issues}}),
        'missing public example reports the exact membership cause');
};

my ($semantic_ir, $built) = build_plan();
ok($built->{ok}, 'canonical VIAL/HIAL fixture reaches typed backend inputs');
diag($json->encode($built->{diagnostics})) unless $built->{ok};
my %pair;

subtest 'all four backend routes satisfy the same objective quality dimensions' => sub {
    my @case = (
        [sv_portable_verilator => 'FSM::VIAL::Backend::SVPortableVerilator'],
        ['sv_uvm_emit.accellera_2020_3_1' =>
            'FSM::VIAL::Backend::SVUVMAccellera2020_3_1'],
        [vhdl_portable_ghdl => 'FSM::VIAL::Backend::VHDLPortableGHDL'],
    );
    for my $case (@case) {
        my ($profile, $class) = @$case;
        my $args = backend_args($built, $profile);
        my $first = $class->emit($args);
        my $second = $class->emit($args);
        ok($first->{ok} && $second->{ok}, "$profile emits twice");
        $pair{$profile} = [$first, $second];
    }

    my $provider_manifest = $json->decode(slurp_raw(repo_path(
        'vial/review_gallery/vhdl_osvvm_qualified/'
        . 'ahb_base_output_advanced_services/evidence/'
        . 'provider-materialization.json'
    )));
    my ($osvvm_first, $osvvm_second);
    {
        no warnings 'redefine';
        local *FSM::VIAL::Backend::OSVVM2026_05Materialization::verify = sub {
            return {
                ok => JSON::PP::true,
                status => 'complete_recursive_verified',
                manifest => clone($provider_manifest),
                diagnostics => [],
            };
        };
        $osvvm_second = FSM::VIAL::Backend::VHDLOSVVM2026_05
            ->with_provider_evaluation({
                dependency_root => $dependency_root,
                consumer => sub {
                    my ($evaluation) = @_;
                    my $args = backend_args($built, 'vhdl_osvvm_qualified');
                    $args->{dependency_root} = $dependency_root;
                    $args->{advanced_requirements} = [qw(
                        advanced_coverage advanced_data_structure
                        advanced_randomization advanced_reporting
                        advanced_scoreboard advanced_synchronization
                        verification_component_adapter
                    )];
                    $osvvm_first = $evaluation->emit($args);
                    return $evaluation->emit($args);
                },
            });
    }
    ok($osvvm_first->{ok} && $osvvm_second->{ok},
        'OSVVM emits twice through one sealed provider evaluation');
    $pair{vhdl_osvvm_qualified} = [$osvvm_first, $osvvm_second];

    for my $profile (@{$contract->{profile_ids}}) {
        my $report = evaluate_vial_backend_artifact_quality({
            profile_id => $profile,
            emission => $pair{$profile}[0],
            repeat_emission => $pair{$profile}[1],
            feature_presence => {verification_probe => JSON::PP::true},
        });
        is_deeply([sort keys %$report],
            [sort @{vial_backend_artifact_quality_report_keys()}],
            "$profile report is closed");
        ok($report->{accepted}, "$profile passes the complete quality gate");
        is_deeply([grep { !$report->{dimensions}{$_} }
                qw(deterministic readable minimal_shape source_mapped
                    bounded_cost absence_driven_elision)],
            [], "$profile passes every independent dimension");
        ok($report->{source_artifact_count} > 0
                && $report->{source_map_entries} >= $report->{source_artifact_count},
            "$profile source inventory is completely mapped");
        ok($report->{preferred_lines} * 10 >= $report->{total_lines} * 9
                && $report->{max_line_bytes} <= 4_096,
            "$profile generated sources satisfy both readability bounds");
    }
};

subtest 'backend quality dimensions retain focused RED controls' => sub {
    my ($first, $second) = @{$pair{vhdl_portable_ghdl}};

    my $changed_repeat = clone($second);
    $changed_repeat->{status} = 'changed';
    my $nondeterministic = evaluate_vial_backend_artifact_quality({
        profile_id => 'vhdl_portable_ghdl',
        emission => $first,
        repeat_emission => $changed_repeat,
        feature_presence => {verification_probe => JSON::PP::true},
    });
    ok(!$nondeterministic->{dimensions}{deterministic},
        'byte-changing rerun fails determinism');

    my $tabbed = clone($first);
    my ($types) = grep { $_->{role} eq 'vhdl_types_package' }
        @{$tabbed->{artifacts}};
    $types->{content} =~ s/\n\z/\n\t-- hostile tab\n/
        or die "types source lacks final newline\n";
    refresh_source_map_reference($tabbed, $types->{relpath});
    my $unreadable = evaluate_vial_backend_artifact_quality({
        profile_id => 'vhdl_portable_ghdl',
        emission => $tabbed,
        repeat_emission => $tabbed,
        feature_presence => {verification_probe => JSON::PP::true},
    });
    ok(!$unreadable->{dimensions}{readable}
            && $unreadable->{dimensions}{source_mapped},
        'literal tab fails readability without falsifying source-map identity');

    my $missing_role = clone($first);
    $missing_role->{artifacts} = [grep { $_->{role} ne 'run_command' }
        @{$missing_role->{artifacts}}];
    my $shape = evaluate_vial_backend_artifact_quality({
        profile_id => 'vhdl_portable_ghdl',
        emission => $missing_role,
        repeat_emission => $missing_role,
        feature_presence => {verification_probe => JSON::PP::true},
    });
    ok(!$shape->{dimensions}{minimal_shape},
        'missing required role fails minimal shape');

    my $unmapped = clone($first);
    my $unmapped_path = $unmapped->{source_map}{artifacts}[0]{relpath};
    $unmapped->{source_map}{entries} = [grep {
        $_->{generated_relpath} ne $unmapped_path
    } @{$unmapped->{source_map}{entries}}];
    my $map = evaluate_vial_backend_artifact_quality({
        profile_id => 'vhdl_portable_ghdl',
        emission => $unmapped,
        repeat_emission => $unmapped,
        feature_presence => {verification_probe => JSON::PP::true},
    });
    ok(!$map->{dimensions}{source_mapped}
            && $map->{dimensions}{readable},
        'unmapped source fails map coverage without falsifying readability');

    my $relabeled = clone($first);
    my ($relabeled_source) = grep { $_->{role} eq 'vhdl_types_package' }
        @{$relabeled->{artifacts}};
    $relabeled_source->{language} = 'metadata';
    my $relabeled_path = $relabeled_source->{relpath};
    $relabeled->{source_map}{artifacts} = [grep {
        $_->{relpath} ne $relabeled_path
    } @{$relabeled->{source_map}{artifacts}}];
    $relabeled->{source_map}{entries} = [grep {
        $_->{generated_relpath} ne $relabeled_path
    } @{$relabeled->{source_map}{entries}}];
    my $source_shape = evaluate_vial_backend_artifact_quality({
        profile_id => 'vhdl_portable_ghdl',
        emission => $relabeled,
        repeat_emission => $relabeled,
        feature_presence => {verification_probe => JSON::PP::true},
    });
    ok(!$source_shape->{dimensions}{minimal_shape}
            && $source_shape->{dimensions}{source_mapped},
        'relabeled source fails exact source shape despite a consistent map');

    my $oversized = clone($first);
    my $extra = clone($oversized->{artifacts}[0]);
    $extra->{relpath} = 'backends/vhdl_portable_ghdl/evidence/extra.json';
    $extra->{role} = 'unexpected_extra_evidence';
    push @{$oversized->{artifacts}}, $extra;
    @{$oversized->{artifacts}} = sort {
        $a->{relpath} cmp $b->{relpath}
    } @{$oversized->{artifacts}};
    my $cost = evaluate_vial_backend_artifact_quality({
        profile_id => 'vhdl_portable_ghdl',
        emission => $oversized,
        repeat_emission => $oversized,
        feature_presence => {verification_probe => JSON::PP::true},
    });
    ok(!$cost->{dimensions}{bounded_cost}
            && $cost->{dimensions}{readable}
            && $cost->{dimensions}{source_mapped},
        'one excess artifact fails bounded cost without changing source quality');

    my $retained = evaluate_vial_backend_artifact_quality({
        profile_id => 'vhdl_portable_ghdl',
        emission => $first,
        repeat_emission => $second,
        feature_presence => {verification_probe => JSON::PP::false},
    });
    ok(!$retained->{dimensions}{absence_driven_elision},
        'retained probe adapter fails when its semantic feature is absent');

    my $elided_first = clone($first);
    my $elided_second = clone($second);
    elide_source_role($elided_first, 'vhdl_probe_adapter');
    elide_source_role($elided_second, 'vhdl_probe_adapter');
    my $elided = evaluate_vial_backend_artifact_quality({
        profile_id => 'vhdl_portable_ghdl',
        emission => $elided_first,
        repeat_emission => $elided_second,
        feature_presence => {verification_probe => JSON::PP::false},
    });
    ok($elided->{accepted}
            && $elided->{dimensions}{absence_driven_elision}
            && $elided->{source_artifact_count} == 5,
        'absent probe projects to an exact five-source graph and map');
};

done_testing();
