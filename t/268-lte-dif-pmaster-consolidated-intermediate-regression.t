#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'lte_dif_pmaster consolidated intermediate block keeps referenced helpers declared and strips redundant truthiness leaves' => sub {
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
        qr/always_comb begin\s+next_state = current_state;\s+\/\/ Default value/s,
        'generated next_state mux keeps typed hold-state default instead of a 1-bit literal',
    );

    my ($block) = $hdl =~ /(^\s*\/\/ Consolidated intermediate signals .*?)(?=^\s*\/\/ Unified WEN\/EN Signal Generation)/ms;
    ok(defined $block && $block ne '', 'generated HDL includes a consolidated intermediate block');
    like(
        $block,
        qr/\bassign\s+s_rst_n_and_apb_rq\s*=\s*s_rst_n\s*&\s*apb_rq\s*;/,
        'consolidated block collapses apb_rq nonzero leaf helpers into direct signal use',
    );
    like(
        $block,
        qr/\bassign\s+s_rst_n_and_pready\s*=\s*s_rst_n\s*&\s*pready\s*;/,
        'consolidated block collapses pready nonzero leaf helpers into direct signal use',
    );
    like(
        $block,
        qr/\bassign\s+s_rst_n_and_not_pwrite\s*=\s*s_rst_n\s*&\s*!pwrite\s*;/,
        'consolidated block collapses pwrite equals-zero leaf helpers into direct negation',
    );
    like(
        $block,
        qr/\bassign\s+s_rst_n_and_pwrite\s*=\s*s_rst_n\s*&\s*pwrite\s*;/,
        'consolidated block collapses pwrite nonzero leaf helpers into direct signal use',
    );
    unlike(
        $block,
        qr/\b(apb_rq|pready|pwrite|s_rst_n)_(?:eq|ne)_const_[A-Za-z0-9]+\b/,
        'consolidated block no longer emits standalone truthiness leaf helpers for direct signal checks',
    );

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
    unlike(
        $block,
        qr/\bassign\s+\w+\s*=\s*[^;\n]*\s(?:==|!=)\s(?:0|1\'b[01])\b/,
        'consolidated helper assigns do not keep redundant truthiness comparisons against zero or one-bit literals',
    );
};

done_testing();
