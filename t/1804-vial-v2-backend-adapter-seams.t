#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::VIALSemanticFamilyBackendAdapter qw(
    build_vial_semantic_family_backend_adapter_registry
    preflight_vial_semantic_family_backend_adapter
    vial_semantic_family_backend_adapter_registry_keys
);
use FSM::Support::VIALSemanticFamilyRegistry qw(
    build_vial_semantic_family_registry
);
use FSM::VIAL::Backend::OSVVM2026_05Materialization;
use FSM::VIAL::Backend::SVPortableVerilator;
use FSM::VIAL::Backend::SVUVMAccellera2020_3_1;
use FSM::VIAL::Backend::VHDLOSVVM2026_05;
use FSM::VIAL::Backend::VHDLPortableGHDL;
use FSM::VIAL::Parser;
use FSM::VIAL::PlanBuilder;

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $vial_name = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $hial_name = 'ppif/ahb_lite_subordinate.ppif';
my $artifact_root = '.artifacts/test/vial-v2-backend-adapter-seams';
my $json = JSON::PP->new->canonical->utf8;
my @profile_ids = qw(
    sv_portable_verilator
    sv_uvm_emit.accellera_2020_3_1
    vhdl_osvvm_qualified
    vhdl_portable_ghdl
);
my @requirements = qw(
    advanced_coverage advanced_data_structure advanced_randomization
    advanced_reporting advanced_scoreboard advanced_synchronization
    verification_component_adapter
);

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

sub v2_plan {
    my $source = slurp_raw(repo_path($vial_name));
    $source =~ s/\(version 1\)/\(version 2\)/
        or die 'version selector was not found';
    $source =~ s/\n    \(fixtures/\n    (intents)\n    (fixtures/
        or die 'fixture section was not found';
    my $semantic_ir = FSM::VIAL::Parser->parse_source({
        text => $source,
        source_name => $vial_name,
    });
    my $built = FSM::VIAL::PlanBuilder->build({
        semantic_ir => $semantic_ir,
        hial_source => {
            source_id => $hial_name,
            format => 'ppif',
            text => slurp_raw(repo_path($hial_name)),
        },
        fixture_id => 'base_output_arbitration',
        scenario_ids => [],
        execution_profile => 'core_directed_single_clock_execution_v2',
        replay_manifest => undef,
        native_extension_catalog => [],
    });
    die 'empty-family v2 plan did not build: '
        . $json->encode($built->{diagnostics}) unless $built->{ok};
    return $built;
}

sub hostile_family_carrier {
    my ($built) = @_;
    $built->{execution_ir}{data}{semantic_families} = [{
        semantic => {
            family_id => 'lifecycle_control', revision => 1,
            effects => [{kind => 'deadline'}, {kind => 'drain'}],
        },
        required_capabilities => [qw(
            vial.family.lifecycle_control.deadline.v1
            vial.family.lifecycle_control.v1
        )],
    }, {
        semantic => {
            family_id => 'unknown_escape', revision => 7,
            effects => [{kind => 'escape'}],
        },
        required_capabilities => ['vial.family.unknown_escape.v7'],
    }];
    return $built;
}

sub base_args {
    my ($built, $profile_id) = @_;
    return {
        execution_ir => $built->{execution_ir},
        bridge_manifest => $built->{bridge_manifest},
        backend_inputs => $built->{backend_inputs},
        artifact_root => $artifact_root,
        backend_profile => $profile_id,
    };
}

subtest 'adapter registry is closed, deterministic, and maturity-exact' => sub {
    my $registry = build_vial_semantic_family_backend_adapter_registry();
    is_deeply([sort keys %{$registry}],
        [sort @{vial_semantic_family_backend_adapter_registry_keys()}],
        'registry exposes exactly its declared keys');
    like($registry->{registry_id},
        qr{\Avial-backend-adapters/[0-9a-f]{64}\z},
        'registry identity is content-addressed');
    is_deeply([map { $_->{profile_id} } @{$registry->{adapters}}],
        \@profile_ids, 'registry owns exactly the four selected routes');

    my %adapter = map { $_->{profile_id} => $_ } @{$registry->{adapters}};
    is_deeply($adapter{sv_portable_verilator}{maturity}, {
        emission => 'qualified', compile => 'qualified',
        runtime => 'qualified', result => 'qualified',
        parity => 'qualified', public => 'qualified',
    }, 'portable SystemVerilog reports its exact public executable maturity');
    is_deeply($adapter{'sv_uvm_emit.accellera_2020_3_1'}{maturity}, {
        emission => 'implemented', compile => 'unavailable',
        runtime => 'unavailable', result => 'unavailable',
        parity => 'unavailable', public => 'unavailable',
    }, 'native UVM reports emission without borrowing executable maturity');
    for my $profile (qw(vhdl_osvvm_qualified vhdl_portable_ghdl)) {
        is_deeply($adapter{$profile}{maturity}, {
            emission => 'qualified', compile => 'qualified',
            runtime => 'qualified', result => 'qualified',
            parity => 'qualified', public => 'unavailable',
        }, "$profile reports qualified private maturity without public support");
    }
    isnt($adapter{vhdl_osvvm_qualified}{target_mechanism},
        $adapter{vhdl_portable_ghdl}{target_mechanism},
        'OSVVM and provider-free VHDL mechanisms remain isolated');
    my $execution_json = $json->encode(v2_plan()->{execution_ir}->as_hashref);
    for my $entry (@{$registry->{adapters}}) {
        unlike($execution_json, qr/\Q$entry->{target_mechanism}\E/,
            "$entry->{profile_id} mechanism does not enter ExecutionIR");
    }
    is($json->encode(build_vial_semantic_family_backend_adapter_registry()),
        $json->encode($registry), 'registry bytes are deterministic');
    $registry->{adapters}[0]{maturity}{public} = 'unavailable';
    is(build_vial_semantic_family_backend_adapter_registry()
            ->{adapters}[0]{maturity}{public},
        'qualified', 'callers receive defensive registry data');
};

subtest 'all family mappings remain unavailable on every adapter' => sub {
    my $registry = build_vial_semantic_family_registry();
    for my $family (@{$registry->{families}}) {
        is_deeply([map { $_->{profile_id} } @{$family->{backend_profiles}}],
            \@profile_ids, "$family->{family_id} maps every adapter");
        for my $mapping (@{$family->{backend_profiles}}) {
            is_deeply([grep {
                $mapping->{maturity}{$_} ne 'unavailable'
            } qw(emission compile runtime result parity)], [],
                "$family->{family_id}/$mapping->{profile_id} stays unavailable");
        }
    }
};

my $built = hostile_family_carrier(v2_plan());

subtest 'shared typed preflight reports every rejected semantic requirement' => sub {
    for my $profile (@profile_ids) {
        my $preflight = preflight_vial_semantic_family_backend_adapter({
            profile_id => $profile,
            execution_ir => $built->{execution_ir},
        });
        ok(!$preflight->{accepted}, "$profile rejects the hostile v2 carrier");
        is($preflight->{adapter}{profile_id}, $profile,
            "$profile receives only its own adapter record");
        my %unsupported = map { $_ => 1 } @{$preflight->{unsatisfied}};
        ok($unsupported{'execution_schema:fsmgen.vial_execution_ir.v2'}
            && $unsupported{'execution_profile:core_directed_single_clock_execution_v2'}
            && $unsupported{'family:lifecycle_control@1'}
            && $unsupported{'family:unknown_escape@7'}
            && $unsupported{'capability:vial.family.lifecycle_control.deadline.v1'}
            && $unsupported{'capability:vial.family.lifecycle_control.v1'}
            && $unsupported{'capability:vial.family.unknown_escape.v7'}
            && $unsupported{'effect:deadline'}
            && $unsupported{'effect:drain'}
            && $unsupported{'effect:escape'},
            "$profile reports schema, profile, family, capability, and effect rejection");
    }

    my $unknown = preflight_vial_semantic_family_backend_adapter({
        profile_id => 'unregistered_backend',
        execution_ir => $built->{execution_ir},
    });
    ok(!$unknown->{accepted} && !defined($unknown->{adapter}),
        'an unknown backend profile cannot acquire an adapter');
    ok(scalar(grep { $_->{kind} eq 'profile_unknown' }
            @{$unknown->{issues}}),
        'unknown profile rejection retains its exact cause');

    my $error = eval {
        preflight_vial_semantic_family_backend_adapter({
            profile_id => 'sv_portable_verilator',
            execution_ir => {},
        });
        '';
    };
    $error = $@ if $@;
    like($error, qr/exact FSM::VIAL::ExecutionIR object/,
        'untyped input cannot cross the shared adapter boundary');

    {
        local $built->{execution_ir}{data}{schema} =
            'fsmgen.vial_execution_ir.v1';
        my $inconsistent =
            preflight_vial_semantic_family_backend_adapter({
                profile_id => 'sv_portable_verilator',
                execution_ir => $built->{execution_ir},
            });
        ok(!$inconsistent->{accepted}
                && scalar(grep { $_ eq 'execution_ir:typed_versioned' }
                    @{$inconsistent->{unsatisfied}}),
            'internally inconsistent typed IR still fails closed');
    }
};

subtest 'all emitters reject before artifacts, provider access, or delegation' => sub {
    my @case = (
        [sv_portable_verilator => 'VIAL_BACKEND_UNSUPPORTED', sub {
            FSM::VIAL::Backend::SVPortableVerilator->emit($_[0]);
        }],
        ['sv_uvm_emit.accellera_2020_3_1' =>
            'VIAL_UVM_BACKEND_UNSUPPORTED', sub {
                FSM::VIAL::Backend::SVUVMAccellera2020_3_1->emit($_[0]);
            }],
        [vhdl_portable_ghdl => 'VIAL_VHDL_BACKEND_UNSUPPORTED', sub {
            FSM::VIAL::Backend::VHDLPortableGHDL->emit($_[0]);
        }],
    );
    for my $case (@case) {
        my ($profile, $code, $emit) = @{$case};
        my $result = $emit->(base_args($built, $profile));
        ok(!$result->{ok}, "$profile rejects before emission");
        is($result->{diagnostics}[0]{code}, $code,
            "$profile retains its backend diagnostic family");
        is_deeply($result->{artifacts}, [],
            "$profile publishes no partial artifact graph");
        ok(scalar(grep { $_ eq 'effect:escape' }
                @{$result->{negotiation}{unsatisfied}}),
            "$profile does not omit an unknown semantic effect");
    }

    my ($portable_calls, $provider_calls) = (0, 0);
    my $osvvm;
    {
        no warnings 'redefine';
        local *FSM::VIAL::Backend::VHDLPortableGHDL::emit = sub {
            ++$portable_calls;
            die 'portable delegation must not run';
        };
        local *FSM::VIAL::Backend::OSVVM2026_05Materialization::verify = sub {
            ++$provider_calls;
            die 'provider verification must not run';
        };
        my $args = base_args($built, 'vhdl_osvvm_qualified');
        $args->{dependency_root} =
            '.artifacts/cache/providers/osvvm/2026.05/source';
        $args->{advanced_requirements} = [@requirements];
        $osvvm = FSM::VIAL::Backend::VHDLOSVVM2026_05->emit($args);
    }
    ok(!$osvvm->{ok}, 'OSVVM rejects before its portable/provider layers');
    is($osvvm->{diagnostics}[0]{code}, 'VIAL_OSVVM_BACKEND_UNSUPPORTED',
        'OSVVM retains its backend diagnostic family');
    is_deeply([$portable_calls, $provider_calls], [0, 0],
        'OSVVM performs neither portable delegation nor provider verification');
    is_deeply($osvvm->{artifacts}, [],
        'OSVVM publishes no partial artifact graph');
    ok(scalar(grep { $_ eq 'effect:escape' }
            @{$osvvm->{negotiation}{unsatisfied}}),
        'OSVVM does not omit an unknown semantic effect');
    ok(!-e repo_path($artifact_root),
        'rejected adapters create no artifact root');
};

done_testing();
