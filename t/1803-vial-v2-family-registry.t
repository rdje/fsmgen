#!/usr/bin/env perl

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::VIALSemanticFamilyRegistry qw(
    build_vial_semantic_family_registry
    negotiate_vial_semantic_family_requirements
    vial_profile_supported_capabilities
    vial_public_tool_capabilities
    vial_semantic_family_negotiation_message
    vial_semantic_family_registry_keys
);
use FSM::Support::VIALToolingContract qw(build_vial_tooling_contract);
use FSM::VIAL::Backend::Runner;
use FSM::VIAL::Backend::SVPortableVerilator;
use FSM::VIAL::Parser;
use FSM::VIAL::PlanBuilder;

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $vial_name = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $hial_name = 'ppif/ahb_lite_subordinate.ppif';
my $v1_source = slurp_raw(repo_path($vial_name));
my $v2_source = to_v2($v1_source);
my $hial_source = slurp_raw(repo_path($hial_name));
my $json = JSON::PP->new->canonical->utf8;

sub repo_path {
    my ($relative) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relative);
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "Cannot read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $text;
}

sub to_v2 {
    my ($source) = @_;
    my $converted = $source;
    $converted =~ s/\(version 1\)/\(version 2\)/
        or die 'version selector was not found';
    $converted =~ s/\n    \(fixtures/\n    (intents)\n    (fixtures/
        or die 'fixture section was not found';
    return $converted;
}

sub with_intents {
    my ($source, $intents) = @_;
    my $changed = $source;
    $changed =~ s/\(intents\)/$intents/
        or die 'intents section was not found';
    return $changed;
}

sub plan_args {
    my ($semantic_ir, $hial_text) = @_;
    return {
        semantic_ir => $semantic_ir,
        hial_source => {
            source_id => $hial_name,
            format => 'ppif',
            text => defined($hial_text) ? $hial_text : $hial_source,
        },
        fixture_id => 'base_output_arbitration',
        scenario_ids => [],
        execution_profile => 'core_directed_single_clock_execution_v2',
        replay_manifest => undef,
        native_extension_catalog => [],
    };
}

subtest 'registry is closed, bounded, deterministic, and support-conservative' => sub {
    my $registry = build_vial_semantic_family_registry();
    is_deeply([sort keys %{$registry}],
        [sort @{vial_semantic_family_registry_keys()}],
        'registry has exactly its declared top-level keys');
    is($registry->{schema}, 'fsmgen.vial_semantic_family_registry.v1',
        'registry has an exact versioned schema');
    like($registry->{registry_id},
        qr{\Avial-family-registry/[0-9a-f]{64}\z},
        'registry identity is content-addressed');
    is($registry->{status}, 'selected_taxonomy_no_implemented_family',
        'selected identities do not claim family implementation');

    my @expected = qw(
        lifecycle_control notification_interception timed_interface
        stimulus_orchestration producer_observer implementation_selection
        scoped_configuration register_intent constrained_decision
        coverage_property bounded_fault result_introspection
    );
    is_deeply([map { $_->{family_id} } @{$registry->{families}}], \@expected,
        'registry owns the twelve roadmap-selected family identities');
    for my $index (0 .. $#{$registry->{families}}) {
        my $family = $registry->{families}[$index];
        is($family->{revision}, 1, "$family->{family_id} has one exact revision");
        is($family->{task_owner},
            'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.' . ($index + 2),
            "$family->{family_id} maps to its vertical activity");
        is($family->{maturity}{selection}, 'selected',
            "$family->{family_id} records selection maturity");
        is_deeply(
            [grep { $family->{maturity}{$_} ne 'unavailable' }
                grep { $_ ne 'selection' } @{$registry->{maturity_keys}}],
            [], "$family->{family_id} advertises no functional maturity");
        ok(@{$family->{effect_kinds}},
            "$family->{family_id} reserves a target-neutral effect vocabulary");
        is($family->{bound_profile_id}, 'vial_common_envelope_v2',
            "$family->{family_id} uses the common finite bound profile");
        is_deeply([map { $_->{profile_id} } @{$family->{backend_profiles}}],
            [qw(
                sv_portable_verilator
                sv_uvm_emit.accellera_2020_3_1
                vhdl_osvvm_qualified
                vhdl_portable_ghdl
            )], "$family->{family_id} maps every selected backend profile");
        for my $mapping (@{$family->{backend_profiles}}) {
            is_deeply($mapping->{maturity}, {
                emission => 'unavailable', compile => 'unavailable',
                runtime => 'unavailable', result => 'unavailable',
                parity => 'unavailable',
            }, "$family->{family_id}/$mapping->{profile_id} cannot borrow maturity");
        }
    }

    my $second = build_vial_semantic_family_registry();
    is($json->encode($second), $json->encode($registry),
        'registry bytes are deterministic');
    $registry->{families}[0]{maturity}{source} = 'qualified';
    is($second->{families}[0]{maturity}{source}, 'unavailable',
        'registry callers receive defensive data');
};

subtest 'public v1 capability bytes and portable support derive without drift' => sub {
    my $tooling = build_vial_tooling_contract();
    is(sha256_hex($json->encode($tooling)),
        '42db05da519dffd97c3e40ec254c82d09b5f20ef53a849e53025b976f5aded4e',
        'existing public VIAL tooling contract remains byte-exact');
    is_deeply($tooling->{capabilities}, vial_public_tool_capabilities(),
        'public capability projection is registry-derived');
    my %portable = map { $_ => 1 }
        @{vial_profile_supported_capabilities('sv_portable_verilator')};
    ok($portable{'vial.execution_ir.v1'}
        && !$portable{'vial.execution_ir.v2'}
        && !$portable{'vial.family.lifecycle_control.v1'},
        'portable backend support is exact and does not infer v2 family support');
};

subtest 'negotiation reports the complete unsupported set from one profile' => sub {
    my $empty = negotiate_vial_semantic_family_requirements({
        stage => 'planner',
        profile_id => 'core_directed_single_clock_execution_v2',
        source_language_version => 2,
        execution_schema => undef,
        execution_profile => 'core_directed_single_clock_execution_v2',
        requirements => [],
    });
    ok($empty->{accepted}, 'empty-family v2 base is accepted by its plan profile');
    is_deeply($empty->{unsupported}, [],
        'accepted base has no hidden unsupported requirement');

    my $rejected = negotiate_vial_semantic_family_requirements({
        stage => 'emitter',
        profile_id => 'sv_portable_verilator',
        source_language_version => undef,
        execution_schema => 'fsmgen.vial_execution_ir.v2',
        execution_profile => 'core_directed_single_clock_execution_v2',
        requirements => [{
            family_id => 'lifecycle_control',
            revision => 1,
            required_capabilities => [
                'vial.family.lifecycle_control.deadline.v1',
                'vial.family.lifecycle_control.v1',
            ],
            effect_kinds => [qw(deadline drain)],
        }, {
            family_id => 'unregistered_family',
            revision => 7,
            required_capabilities => ['vial.family.unregistered.v7'],
            effect_kinds => ['escape'],
        }],
    });
    ok(!$rejected->{accepted}, 'unsupported family set rejects atomically');
    my %unsupported = map { $_ => 1 } @{$rejected->{unsupported}};
    ok($unsupported{'execution_schema:fsmgen.vial_execution_ir.v2'}
        && $unsupported{'execution_profile:core_directed_single_clock_execution_v2'}
        && $unsupported{'family:lifecycle_control@1'}
        && $unsupported{'family:unregistered_family@7'}
        && $unsupported{'capability:vial.family.lifecycle_control.v1'}
        && $unsupported{'capability:vial.family.lifecycle_control.deadline.v1'}
        && $unsupported{'capability:vial.family.unregistered.v7'}
        && $unsupported{'effect:deadline'}
        && $unsupported{'effect:drain'}
        && $unsupported{'effect:escape'},
        'schema, profile, every family, every capability, and every effect are reported');
    like(vial_semantic_family_negotiation_message($rejected),
        qr/lifecycle_control.*unregistered_family/s,
        'stable rejection text retains the complete family set');
};

subtest 'parser and planner reject all unavailable families before allocation' => sub {
    my $source = with_intents($v2_source,
        '(intents (family lifecycle_control (revision 1)) '
        . '(family native_uvm (revision 1)))');
    my $checked = FSM::VIAL::Parser->check_source({
        text => $source,
        source_name => $vial_name,
    });
    ok(!$checked->{ok}, 'parser rejects selected-but-unimplemented and unknown families');
    is($checked->{diagnostics}[0]{code}, 'VIAL_FAMILY_UNSUPPORTED',
        'parser uses the stable family diagnostic');
    like($checked->{diagnostics}[0]{message}, qr/lifecycle_control.*native_uvm/s,
        'parser diagnostic reports the complete unsupported family set');
    is($checked->{semantic_report}, undef,
        'parser returns no partial SemanticIR report');

    my $wrong_revision = FSM::VIAL::Parser->check_source({
        text => with_intents($v2_source,
            '(intents (family lifecycle_control (revision 2)))'),
        source_name => $vial_name,
    });
    is($wrong_revision->{diagnostics}[0]{code},
        'VIAL_FAMILY_REVISION_MISMATCH',
        'known family with an unknown revision fails distinctly');
    like($wrong_revision->{diagnostics}[0]{message},
        qr/revision 2 is not registered; revision 1 is selected/,
        'revision failure names requested and selected revisions');

    my $semantic_ir = FSM::VIAL::Parser->parse_source({
        text => $v2_source,
        source_name => $vial_name,
    });
    $semantic_ir->{data}{packages}[0]{intent_families} = [{
        family_id => 'lifecycle_control', revision => 1, nodes => [],
    }];
    my $planned = FSM::VIAL::PlanBuilder->build(
        plan_args($semantic_ir, 'not valid HIAL'));
    ok(!$planned->{ok}, 'planner independently rejects a hostile family carrier');
    is($planned->{diagnostics}[0]{code}, 'VIAL_FAMILY_UNSUPPORTED',
        'planner rejects through registry negotiation');
    like($planned->{diagnostics}[0]{message}, qr/lifecycle_control/,
        'planner rejection names the unsupported family');
    is_deeply($planned->{review_artifacts}, [],
        'planner rejects before HIAL review or artifact allocation');

    my $wrong_profile_args = plan_args($semantic_ir, 'not valid HIAL');
    $wrong_profile_args->{execution_profile} = 'unregistered_execution_profile';
    my $wrong_profile = FSM::VIAL::PlanBuilder->build($wrong_profile_args);
    ok(!$wrong_profile->{ok}, 'planner rejects an unsupported profile');
    is($wrong_profile->{diagnostics}[0]{code}, 'VIAL_FAMILY_UNSUPPORTED',
        'profile rejection uses the common negotiation boundary');
    like($wrong_profile->{diagnostics}[0]{message},
        qr/does not accept execution profile 'unregistered_execution_profile'/,
        'profile rejection names the complete unsupported profile requirement');
    is_deeply($wrong_profile->{review_artifacts}, [],
        'profile negotiation rejects before invalid HIAL is inspected');
};

subtest 'emitter and runner reject v2 requirements before artifacts or processes' => sub {
    my $semantic_ir = FSM::VIAL::Parser->parse_source({
        text => $v2_source,
        source_name => $vial_name,
    });
    my $built = FSM::VIAL::PlanBuilder->build(plan_args($semantic_ir));
    ok($built->{ok}, 'empty-family v2 private plan builds');
    diag($json->encode($built->{diagnostics})) unless $built->{ok};

    $built->{execution_ir}{data}{semantic_families} = [{
        semantic => {
            family_id => 'lifecycle_control', revision => 1,
            effects => [{kind => 'drain'}],
        },
        required_capabilities => [qw(
            vial.family.lifecycle_control.deadline.v1
            vial.family.lifecycle_control.v1
        )],
    }];
    my $emission = FSM::VIAL::Backend::SVPortableVerilator->emit({
        execution_ir => $built->{execution_ir},
        bridge_manifest => $built->{bridge_manifest},
        backend_inputs => $built->{backend_inputs},
        artifact_root => '.artifacts/test/vial-v2-family-registry',
        backend_profile => 'sv_portable_verilator',
    });
    ok(!$emission->{ok}, 'emitter rejects the hostile v2 family carrier');
    is($emission->{diagnostics}[0]{code}, 'VIAL_BACKEND_UNSUPPORTED',
        'emitter rejection stays a backend capability failure');
    is_deeply($emission->{artifacts}, [],
        'emitter allocates no artifact on negotiation failure');
    ok(!-e repo_path('.artifacts/test/vial-v2-family-registry'),
        'emitter creates no artifact root on negotiation failure');
    my %emitter_unsupported = map { $_ => 1 }
        @{$emission->{negotiation}{unsatisfied}};
    ok($emitter_unsupported{'family:lifecycle_control@1'}
        && $emitter_unsupported{'capability:vial.family.lifecycle_control.v1'}
        && $emitter_unsupported{'capability:vial.family.lifecycle_control.deadline.v1'}
        && $emitter_unsupported{'effect:drain'},
        'emitter exposes the complete unsupported family requirement set');

    my $run = FSM::VIAL::Backend::Runner->run({
        repo_root => $repo_root,
        execution_ir => $built->{execution_ir},
        emission => {},
    });
    ok(!$run->{ok}, 'runner independently rejects the hostile v2 family carrier');
    is($run->{diagnostics}[0]{code}, 'VIAL_BACKEND_UNSUPPORTED',
        'runner uses the stable backend capability diagnostic');
    like($run->{diagnostics}[0]{message},
        qr/lifecycle_control.*deadline.*drain/s,
        'runner rejection carries family, capability, and effect failures');
    is_deeply($run->{artifacts}, [],
        'runner returns no artifact on negotiation failure');
    is_deeply($run->{cleanup}, {
        staging_identity => undef,
        removed => JSON::PP::false,
    }, 'runner rejects before a lifecycle workspace or process exists');
};

done_testing();
