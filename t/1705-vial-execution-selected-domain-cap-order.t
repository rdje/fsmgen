#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleExecutionGraph;
use FSM::VIAL::ExecutionBuilder;

my $class = 'FSM::VIAL::ArchitectureScaleExecutionGraph';
my $hial_path = 'ppif/ahb_lite_subordinate.ppif';
my $vial_path = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $hial = slurp_raw(repo_path($hial_path));
my $vial = slurp_raw(repo_path($vial_path));

my $accepted_inputs = $class->_test_selected_domain_inputs(
    $hial, $hial_path, $vial, $vial_path,
);
my $accepted = FSM::VIAL::ArchitectureScaleExecutionGraph::_build_execution(
    $accepted_inputs,
);
ok($accepted->{ok}, 'the exact one-domain profile remains accepted');
diag(JSON::PP->new->canonical(1)->encode($accepted->{diagnostics}))
    unless $accepted->{ok};
is($accepted->{plan}{plan_id},
    'plan/e236297c8b434a9b374d1800112841e00327bdbd5d8d9130440bd20681fbed6e',
    'accepted profile retains its exact plan identity');

my $hostile_data = $accepted_inputs->{semantic_ir}->as_hashref;
my $dut = $hostile_data->{packages}[0]{fixtures}[0]{dut};
my $hostile_domain = JSON::PP->new->decode(
    JSON::PP->new->canonical(1)->encode($dut->{domains}[0]),
);
$hostile_domain->{name} = 'hostile';
$hostile_domain->{semantic_id} =~ s/::bus\z/::hostile/;
$hostile_domain->{semantic_path} = '/packages/0/fixtures/0/dut/domains/1';
$hostile_domain->{bridge_ref} = 'domain/missing';
push @{$dut->{domains}}, $hostile_domain;

# The public semantic layer already enforces its own one-domain profile. This
# exact-class object isolates the downstream execution admission boundary and
# proves that it remains defensive when handed internally constructed IR.
my $hostile_semantic_ir = bless({data => $hostile_data}, 'FSM::VIAL::SemanticIR');
my $hostile_inputs = {
    %{$accepted_inputs},
    semantic_ir => $hostile_semantic_ir,
    arguments => {
        %{$accepted_inputs->{arguments}},
        semantic_ir => $hostile_semantic_ir,
    },
};

my $source_map_entries = 0;
my $rejected;
{
    no warnings 'redefine';
    local *FSM::VIAL::ExecutionBuilder::_add_source_map = sub {
        ++$source_map_entries;
    };
    $rejected = FSM::VIAL::ArchitectureScaleExecutionGraph::_build_execution(
        $hostile_inputs,
    );
}

ok(!$rejected->{ok}, 'the two-domain execution profile is rejected');
is_deeply(
    $rejected->{diagnostics},
    [{
        schema_version => 1,
        severity => 'error',
        code => 'VIAL_EXECUTION_LIMIT_ERROR',
        phase => 'limit',
        message => 'the first execution profile requires exactly one selected domain',
        semantic_path => '/packages/0/fixtures/0/dut',
        source_location => {
            source_name => $vial_path,
            start_line => 33,
            start_column => 9,
            start_byte => 900,
            end_line => 42,
            end_column => 67,
            end_byte_exclusive => 1422,
        },
        bridge_fact_paths => [],
        related => [],
    }],
    'profile admission wins before the hostile second-domain reference',
);
is($source_map_entries, 0,
    'profile admission precedes every binding source-map record');
is($rejected->{execution_ir}, undef,
    'profile rejection returns no partial ExecutionIR');
is($rejected->{plan}, undef, 'profile rejection returns no partial plan');

my $hostile_bridge_data = $accepted_inputs->{bridge_manifest}->as_hashref;
my $hostile_unit = JSON::PP->new->decode(
    JSON::PP->new->canonical(1)->encode($hostile_bridge_data->{units}[0]),
);
$hostile_unit->{unit_id} = 'unit/hostile';
push @{$hostile_bridge_data->{units}}, $hostile_unit;
my $hostile_bridge = bless(
    {data => $hostile_bridge_data},
    'FSM::HIAL::VIALBridge::Manifest',
);
my $hostile_unit_inputs = {
    %{$accepted_inputs},
    bridge_manifest => $hostile_bridge,
    arguments => {
        %{$accepted_inputs->{arguments}},
        bridge_manifest => $hostile_bridge,
    },
};

my $bridge_index_entries = 0;
my $unit_rejected;
{
    no warnings 'redefine';
    local *FSM::VIAL::ExecutionBuilder::_index_bridge = sub {
        ++$bridge_index_entries;
    };
    $unit_rejected = FSM::VIAL::ArchitectureScaleExecutionGraph::_build_execution(
        $hostile_unit_inputs,
    );
}

ok(!$unit_rejected->{ok}, 'the two-unit execution profile is rejected');
is_deeply(
    $unit_rejected->{diagnostics},
    [{
        schema_version => 1,
        severity => 'error',
        code => 'VIAL_BIND_REFERENCE_ERROR',
        phase => 'bind',
        message => 'the first execution profile requires exactly one bridge unit',
        semantic_path => '/packages/0/fixtures/0/dut',
        source_location => {
            source_name => $vial_path,
            start_line => 33,
            start_column => 9,
            start_byte => 900,
            end_line => 42,
            end_column => 67,
            end_byte_exclusive => 1422,
        },
        bridge_fact_paths => ['/units'],
        related => [],
    }],
    'unit-profile admission retains its exact diagnostic',
);
is($bridge_index_entries, 0,
    'unit-profile admission precedes bridge index materialization');
is($unit_rejected->{execution_ir}, undef,
    'unit-profile rejection returns no partial ExecutionIR');
is($unit_rejected->{plan}, undef,
    'unit-profile rejection returns no partial plan');

done_testing();

sub repo_path {
    my ($relative) = @_;
    return File::Spec->catfile($FindBin::Bin, '..', split m{/}, $relative);
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "Cannot read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $text;
}

package FSM::VIAL::ArchitectureScaleExecutionGraph;

sub _test_selected_domain_inputs {
    my ($class, $hial, $hial_path, $vial, $vial_path) = @_;
    return _canonical_ahb_inputs(
        {},
        {content => $hial, relative_path => $hial_path},
        {content => $vial, relative_path => $vial_path},
    );
}
