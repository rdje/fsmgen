#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleBackendEmission;
use FSM::VIAL::Backend::OSVVM2026_05Materialization;
use FSM::VIAL::Backend::VHDLOSVVM2026_05;
use FSM::VIAL::Backend::VHDLPortableGHDL;

my $json = JSON::PP->new->canonical(1);
my $scale_class = 'FSM::VIAL::ArchitectureScaleBackendEmission';
my $backend_class = 'FSM::VIAL::Backend::VHDLOSVVM2026_05';
my $dependency_root = '.artifacts/cache/providers/osvvm/2026.05/source';
my @requirements = qw(
    advanced_coverage advanced_data_structure advanced_randomization
    advanced_reporting advanced_scoreboard advanced_synchronization
    verification_component_adapter
);
my $provider_manifest = $json->decode(slurp_raw(repo_path(
    'vial', 'review_gallery', 'vhdl_osvvm_qualified',
    'ahb_base_output_advanced_services', 'evidence',
    'provider-materialization.json',
)));
my $construction = $scale_class->construct({
    backend_profile => 'vhdl_osvvm_qualified',
    level => 'reference_v1',
    reference_hial_text => slurp_raw(repo_path(
        'ppif', 'ahb_lite_subordinate.ppif')),
    reference_vial_text => slurp_raw(repo_path(
        'vial', 'ahb_subordinate_base_output_arbitration.vial')),
});
ok($construction->{ok}, 'OSVVM reference construction succeeds');
my $route = $scale_class->build({construction => $construction});
ok($route->{ok}, 'OSVVM reference route builds');

my $original_portable_emit =
    'FSM::VIAL::Backend::VHDLPortableGHDL'->can('emit');
my $original_adapter = $backend_class->can('_render_adapter');

my @callback_order;
my ($callback_verify_calls, $callback_second) = (0, undef);
my $callback_accepted;
{
    no warnings 'redefine';
    local *FSM::VIAL::Backend::VHDLPortableGHDL::emit = sub {
        push @callback_order, 'portable';
        return $original_portable_emit->(@_);
    };
    local *FSM::VIAL::Backend::OSVVM2026_05Materialization::verify = sub {
        ++$callback_verify_calls;
        push @callback_order, 'provider';
        return provider_result();
    };
    $callback_accepted = $backend_class->with_provider_evaluation({
        dependency_root => $dependency_root,
        consumer => sub {
            my ($evaluation) = @_;
            my $first = $evaluation->emit(backend_args());
            $callback_second = $evaluation->emit(backend_args());
            return $first;
        },
    });
}
ok($callback_accepted->{ok}, 'callback-scoped accepted emission succeeds');
ok($callback_second->{ok}, 'callback-scoped accepted rerun succeeds');
is($callback_verify_calls, 1,
    'two accepted callback emissions reuse one provider verification');
is_deeply(\@callback_order, [qw(portable provider portable)],
    'portable foundation precedes lazy provider verification and reuse');
is($json->encode($callback_accepted), $json->encode($callback_second),
    'accepted callback emissions remain byte-identical');
is(scalar(@{$callback_accepted->{artifacts}}), 16,
    'accepted callback artifact inventory remains unchanged');
is(scalar(@{$callback_accepted->{source_map}{entries}}), 66,
    'accepted callback source-map inventory remains unchanged');

my @standalone_order;
my $standalone;
{
    no warnings 'redefine';
    local *FSM::VIAL::Backend::VHDLPortableGHDL::emit = sub {
        push @standalone_order, 'portable';
        return $original_portable_emit->(@_);
    };
    local *FSM::VIAL::Backend::OSVVM2026_05Materialization::verify = sub {
        push @standalone_order, 'provider';
        return provider_result();
    };
    $standalone = $backend_class->emit(backend_args());
}
ok($standalone->{ok}, 'standalone accepted emission succeeds');
is_deeply(\@standalone_order, [qw(portable provider)],
    'standalone portable foundation precedes provider verification');
is($json->encode($standalone), $json->encode($callback_accepted),
    'standalone and callback-scoped accepted graphs remain byte-identical');

my ($excess_verify_calls, $excess_second) = (0, undef);
my $callback_excess;
{
    no warnings 'redefine';
    local *FSM::VIAL::Backend::VHDLPortableGHDL::_render_fixture = sub {
        return 'x' x 16_777_217;
    };
    local *FSM::VIAL::Backend::OSVVM2026_05Materialization::verify = sub {
        ++$excess_verify_calls;
        return provider_result();
    };
    $callback_excess = $backend_class->with_provider_evaluation({
        dependency_root => $dependency_root,
        consumer => sub {
            my ($evaluation) = @_;
            my $first = $evaluation->emit(backend_args());
            $excess_second = $evaluation->emit(backend_args());
            return $first;
        },
    });
}
portable_excess($callback_excess,
    'callback-scoped known portable excess');
portable_excess($excess_second,
    'callback-scoped known portable excess rerun');
is($excess_verify_calls, 0,
    'known callback-scoped portable excess performs no provider verification');

my $standalone_excess_verify_calls = 0;
my $standalone_excess;
{
    no warnings 'redefine';
    local *FSM::VIAL::Backend::VHDLPortableGHDL::_render_fixture = sub {
        return 'x' x 16_777_217;
    };
    local *FSM::VIAL::Backend::OSVVM2026_05Materialization::verify = sub {
        ++$standalone_excess_verify_calls;
        return provider_result();
    };
    $standalone_excess = $backend_class->emit(backend_args());
}
portable_excess($standalone_excess, 'standalone known portable excess');
is($standalone_excess_verify_calls, 0,
    'known standalone portable excess performs no provider verification');

my $inventory_verify_calls = 0;
my $inventory_rejected;
{
    no warnings 'redefine';
    local *FSM::VIAL::Backend::VHDLPortableGHDL::emit = sub {
        my $result = clone($original_portable_emit->(@_));
        @{$result->{artifacts}} = grep {
            ($_->{role} // '') ne 'vhdl_types_package'
        } @{$result->{artifacts}};
        return $result;
    };
    local *FSM::VIAL::Backend::OSVVM2026_05Materialization::verify = sub {
        ++$inventory_verify_calls;
        return provider_result();
    };
    $inventory_rejected = $backend_class->emit(backend_args());
}
wrapper_inventory_failure($inventory_rejected,
    'known portable source-inventory contradiction');
is($inventory_verify_calls, 0,
    'portable source-inventory contradiction performs no provider verification');

my $translation_verify_calls = 0;
my $translation_rejected;
{
    no warnings 'redefine';
    local *FSM::VIAL::Backend::VHDLPortableGHDL::emit = sub {
        my $result = clone($original_portable_emit->(@_));
        $result->{source_map}{entries}[0]{source_map_id} .= '-drift';
        return $result;
    };
    local *FSM::VIAL::Backend::OSVVM2026_05Materialization::verify = sub {
        ++$translation_verify_calls;
        return provider_result();
    };
    $translation_rejected = $backend_class->emit(backend_args());
}
ok(!$translation_rejected->{ok},
    'known portable source-map contradiction is rejected');
is($translation_rejected->{diagnostics}[0]{code},
    'VIAL_OSVVM_SOURCE_MAP_TRANSLATION_ERROR',
    'portable source-map contradiction retains its diagnostic family');
is($translation_rejected->{diagnostics}[0]{path},
    '/portable_foundation/source_map',
    'portable source-map contradiction retains its exact path');
is($translation_verify_calls, 0,
    'portable source-map contradiction performs no provider verification');
is_deeply($translation_rejected->{artifacts}, [],
    'portable source-map contradiction publishes no wrapper artifact graph');

my $adapter_verify_calls = 0;
my $adapter_rejected;
{
    no warnings 'redefine';
    local *FSM::VIAL::Backend::VHDLOSVVM2026_05::_render_adapter = sub {
        return $original_adapter->(@_) . ' ';
    };
    local *FSM::VIAL::Backend::OSVVM2026_05Materialization::verify = sub {
        ++$adapter_verify_calls;
        return provider_result();
    };
    $adapter_rejected = $backend_class->emit(backend_args());
}
wrapper_inventory_failure($adapter_rejected,
    'known adapter-byte contradiction');
is($adapter_verify_calls, 0,
    'adapter-byte contradiction performs no provider verification');

done_testing();

sub backend_args {
    return {
        execution_ir => $route->{execution_ir},
        bridge_manifest => $route->{bridge_manifest},
        backend_inputs => $route->{backend_inputs},
        artifact_root => '.artifacts/tmp/vial/backend-cap-order',
        backend_profile => 'vhdl_osvvm_qualified',
        dependency_root => $dependency_root,
        advanced_requirements => [@requirements],
    };
}

sub provider_result {
    return {
        ok => JSON::PP::true,
        status => 'complete_recursive_verified',
        manifest => $json->decode($json->encode($provider_manifest)),
        diagnostics => [],
    };
}

sub portable_excess {
    my ($result, $label) = @_;
    ok(!$result->{ok}, "$label is rejected");
    is_deeply($result->{diagnostics}, [{
        code => 'VIAL_OSVVM_PORTABLE_FOUNDATION_ERROR',
        message => 'generated VHDL exceeds the 16 MiB backend cap',
        path => '/portable_foundation',
    }], "$label retains the exact diagnostic");
    is($result->{provider_materialization}, undef,
        "$label publishes no provider evidence");
    is_deeply($result->{artifacts}, [],
        "$label publishes no wrapper artifact graph");
}

sub wrapper_inventory_failure {
    my ($result, $label) = @_;
    ok(!$result->{ok}, "$label is rejected");
    is_deeply($result->{diagnostics}, [{
        code => 'VIAL_OSVVM_BACKEND_LIMIT_EXCEEDED',
        message =>
            'OSVVM wrapper emitted an unexpected source or artifact inventory',
        path => '/artifacts',
    }], "$label retains the exact diagnostic");
    is($result->{provider_materialization}, undef,
        "$label publishes no provider evidence");
    is_deeply($result->{artifacts}, [],
        "$label publishes no wrapper artifact graph");
}

sub clone {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}

sub repo_path {
    return File::Spec->catfile($FindBin::Bin, '..', @_);
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "Cannot read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $text;
}
