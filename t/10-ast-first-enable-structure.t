#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

my $fsm_file = File::Spec->catfile($FindBin::Bin, '..', 'fsm', 'trial_1.fsm');
my $pipeline = FSM::Pipeline::HDLGenerator->new(
    debug_level => 0,
    target_language => 'systemverilog',
    quiet => 1,
);

{
    local $SIG{__WARN__} = sub { };
    $pipeline->generate_hdl_from_file($fsm_file);
}

my $hdl = $pipeline->{hdl_generator};
my $assignment_analysis = $hdl->{assignment_analysis} || {};

ok(
    scalar(keys %$assignment_analysis) > 0,
    'live generation builds assignment_analysis for AST-first enable synthesis',
);

my @rhs_groups;
for my $lhs (sort keys %$assignment_analysis) {
    my $rhs_groups = $assignment_analysis->{$lhs}{rhs_groups} || {};
    push @rhs_groups, map { $rhs_groups->{$_} } sort keys %$rhs_groups;
}

ok(
    scalar(@rhs_groups) > 0,
    'live generation populates RHS groups for enable synthesis',
);

my @groups_with_ast_dt_enables = grep {
    ref($_->{dt_specific_enables}) eq 'ARRAY'
        && scalar(@{$_->{dt_specific_enables}}) > 0
        && ref($_->{dt_specific_enables}[0]) eq 'HASH'
        && $_->{dt_specific_enables}[0]{enable_ast}
} @rhs_groups;
ok(
    scalar(@groups_with_ast_dt_enables) > 0,
    'DT-specific enables are stored as AST-backed metadata inside rhs_groups',
);

my @groups_with_ast_lhs_enables = grep {
    ref($_->{lhs_level_enable}) eq 'HASH'
        && $_->{lhs_level_enable}{ast}
} @rhs_groups;
ok(
    scalar(@groups_with_ast_lhs_enables) > 0,
    'LHS-level enables are stored as AST-backed metadata inside rhs_groups',
);

ok(
    !exists $hdl->{dt_specific_enables},
    'live generation leaves no legacy top-level dt_specific_enables state behind',
);

ok(
    !exists $hdl->{lhs_to_enable_value_pairs},
    'live generation leaves no legacy top-level lhs_to_enable_value_pairs state behind',
);

done_testing();
