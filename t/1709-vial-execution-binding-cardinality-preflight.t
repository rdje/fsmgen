#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::VIALExecutionContract qw(build_vial_execution_contract);
use FSM::VIAL::ArchitectureScaleExecutionGraph;
use FSM::VIAL::ExecutionBuilder;

my $class = 'FSM::VIAL::ArchitectureScaleExecutionGraph';
my $json = JSON::PP->new->canonical(1);
my $hial_path = 'ppif/ahb_lite_subordinate.ppif';
my $vial_path = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $inputs = $class->_test_binding_cardinality_inputs(
    slurp_raw(repo_path($hial_path)), $hial_path,
    slurp_raw(repo_path($vial_path)), $vial_path,
);

my $accepted_preflight_count;
my $original_preflight =
    \&FSM::VIAL::ExecutionBuilder::_preflight_binding_cardinality;
my $accepted;
{
    no warnings 'redefine';
    local *FSM::VIAL::ExecutionBuilder::_preflight_binding_cardinality = sub {
        $accepted_preflight_count = $original_preflight->(@_);
        return $accepted_preflight_count;
    };
    $accepted = FSM::VIAL::ArchitectureScaleExecutionGraph::_build_execution(
        $inputs,
    );
}
ok($accepted->{ok}, 'the canonical accepted profile still builds');
diag($json->encode($accepted->{diagnostics})) unless $accepted->{ok};
is($accepted->{plan}{plan_id},
    'plan/e236297c8b434a9b374d1800112841e00327bdbd5d8d9130440bd20681fbed6e',
    'accepted profile retains its exact plan identity');

my $limit = build_vial_execution_contract()->{limits}{bindings};
my $semantic = $inputs->{semantic_ir}->as_hashref;
my $fields = $semantic->{packages}[0]{transactions}[0]{fields};
my $accepted_bindings = $accepted->{execution_ir}->as_hashref
    ->{resource_summary}{bindings};
is($accepted_preflight_count, $accepted_bindings,
    'compact preflight exactly matches the terminal accepted binding count');
$#$fields += $limit + 1 - $accepted_bindings;

my $bind_calls = 0;
my $original_bind = \&FSM::VIAL::ExecutionBuilder::_bind_fixture;
my $rejected;
{
    no warnings 'redefine';
    local *FSM::VIAL::ExecutionBuilder::_bind_fixture = sub {
        ++$bind_calls;
        return $original_bind->(@_);
    };
    $rejected = FSM::VIAL::ArchitectureScaleExecutionGraph::_build_execution(
        forged_inputs($inputs, $semantic),
    );
}

ok(!$rejected->{ok}, 'a compactly known one-over binding count is rejected');
is_deeply($rejected->{diagnostics}, [{
        schema_version => 1,
        severity => 'error',
        code => 'VIAL_EXECUTION_LIMIT_ERROR',
        phase => 'limit',
        message => "bindings exceeds the limit $limit",
        semantic_path => '/bindings',
        source_location => undef,
        bridge_fact_paths => [],
        related => [],
    }], 'known binding excess retains the exact execution diagnostic');
is($bind_calls, 0,
    'known binding excess rejects before binding-record construction');
is($rejected->{execution_ir}, undef,
    'known binding excess returns no partial ExecutionIR');
is($rejected->{plan}, undef,
    'known binding excess returns no partial plan');

done_testing();

sub forged_inputs {
    my ($base, $semantic_data) = @_;
    my $semantic_ir = bless({data => $semantic_data}, 'FSM::VIAL::SemanticIR');
    return {
        %{$base},
        semantic_ir => $semantic_ir,
        arguments => {
            %{$base->{arguments}},
            semantic_ir => $semantic_ir,
        },
    };
}

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

sub _test_binding_cardinality_inputs {
    my ($class, $hial, $hial_path, $vial, $vial_path) = @_;
    return _canonical_ahb_inputs(
        {},
        {content => $hial, relative_path => $hial_path},
        {content => $vial, relative_path => $vial_path},
    );
}
