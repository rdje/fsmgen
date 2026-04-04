#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'lte_dif_pmaster consolidated intermediate block keeps referenced leaf helpers declared and assigned' => sub {
    my $fsm_file = File::Spec->catfile($FindBin::Bin, '..', 'fsm', 'lte_dif_pmaster.fsm');
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $result;
    {
        local $SIG{__WARN__} = sub { };
        $result = $pipeline->generate_hdl_from_file($fsm_file);
    }

    my $hdl = $result->{hdl_code} || '';
    ok($hdl ne '', 'pipeline returns generated HDL for lte_dif_pmaster');

    like(
        $hdl,
        qr/\bassign\s+apb_rq_ne_const_0\s*=\s*apb_rq\s*!=\s*0\s*;/,
        'generated HDL now emits the missing apb_rq truthiness helper',
    );
    like(
        $hdl,
        qr/\bassign\s+pready_ne_const_0\s*=\s*pready\s*!=\s*0\s*;/,
        'generated HDL now emits the missing pready truthiness helper',
    );
    like(
        $hdl,
        qr/\bassign\s+pwrite_eq_const_0\s*=\s*pwrite\s*==\s*0\s*;/,
        'generated HDL now emits the missing pwrite equals-zero helper',
    );
    like(
        $hdl,
        qr/\bassign\s+pwrite_ne_const_0\s*=\s*pwrite\s*!=\s*0\s*;/,
        'generated HDL now emits the missing pwrite nonzero helper',
    );
    like(
        $hdl,
        qr/always_comb begin\s+next_state = current_state;\s+\/\/ Default value/s,
        'generated next_state mux keeps typed hold-state default instead of a 1-bit literal',
    );

    my ($block) = $hdl =~ /(^\s*\/\/ Consolidated intermediate signals .*?)(?=^\s*\/\/ Unified WEN\/EN Signal Generation)/ms;
    ok(defined $block && $block ne '', 'generated HDL includes a consolidated intermediate block');

    my %declared_helper_signals;
    while ($block =~ /^\s*wire(?:\s+\[[^\]]+\])?\s+([A-Za-z_]\w*)\s*;/mg) {
        $declared_helper_signals{$1} = 1;
    }

    my %assigned_helper_signals;
    my %referenced_helper_signals;
    while ($block =~ /^\s*assign\s+([A-Za-z_]\w*)\s*=\s*(.*?)\s*;\s*\/\/ Source:/mg) {
        my ($lhs_signal, $rhs_expression) = ($1, $2);
        $assigned_helper_signals{$lhs_signal} = 1;

        while ($rhs_expression =~ /\b([A-Za-z_]\w*(?:_eq_const_[A-Za-z0-9]+|_ne_const_[A-Za-z0-9]+|_and_[A-Za-z0-9_]+|_or_[A-Za-z0-9_]+))\b/g) {
            $referenced_helper_signals{$1} = 1;
        }
    }

    my @missing_declarations = sort grep { !$declared_helper_signals{$_} } keys %referenced_helper_signals;
    my @missing_assignments = sort grep { !$assigned_helper_signals{$_} } keys %referenced_helper_signals;

    is_deeply(
        \@missing_declarations,
        [],
        'every referenced consolidated intermediate helper is declared in the generated block',
    );
    is_deeply(
        \@missing_assignments,
        [],
        'every referenced consolidated intermediate helper has an assign statement in the generated block',
    );
    unlike(
        $block,
        qr/\bassign\s+\w+\s*=\s*[^;\n]*&&[^;\n]*; \/\//,
        'consolidated helper assigns do not keep logical AND when both operands are 1-bit helpers/enables',
    );
    unlike(
        $block,
        qr/\bassign\s+\w+\s*=\s*[^;\n]*\|\|[^;\n]*; \/\//,
        'consolidated helper assigns do not keep logical OR when both operands are 1-bit helpers/enables',
    );
};

done_testing();
