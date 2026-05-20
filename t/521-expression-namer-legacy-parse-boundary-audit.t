#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Scalar::Util qw(blessed);
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::ExpressionNamer;
use FSM::GlobalASTManager;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::OperandContractValidationSupport;
use FSM::Synthesis::EnableGraph::FactorizationPolicySupport;
use FSM::Synthesis::EnableGraph::FactorizationSupport;
use FSM::Synthesis::EnableGraph::IntermediateSignalSupport;
use FSM::Synthesis::EnableGraph::SignalSupport;

{
    package Local::IntermediateSignalSet;

    sub new {
        my ($class, @signal_names) = @_;
        return bless { map { $_ => 1 } @signal_names }, $class;
    }

    sub is_intermediate_signal {
        my ($self, $signal_name) = @_;
        return $self->{$signal_name} ? 1 : 0;
    }
}

{
    package Local::NoNativeIntermediateSupport;

    sub _get_native_intermediate_signal_ast {
        return undef;
    }
}

sub is_legacy_hash_ast {
    my ($ast, $label) = @_;
    ok(ref($ast) eq 'HASH' && !blessed($ast), "$label returns an unblessed legacy hash AST");
}

sub sorted_names {
    return [ sort @_ ];
}

subtest 'parse_expression returns private legacy hash AST shapes' => sub {
    my $namer = FSM::ExpressionNamer->new();

    my $empty = $namer->parse_expression('');
    is_legacy_hash_ast($empty, 'empty expression');
    is_deeply(
        $empty,
        {
            type => 'literal',
            format => 'decimal',
            value => 0,
            bit_value => 0,
            width => 1,
        },
        'empty expression maps to the documented zero literal fallback',
    );

    my $signal = $namer->parse_expression('ready');
    is_legacy_hash_ast($signal, 'simple signal');
    is_deeply(
        $signal,
        {
            type => 'signal',
            name => 'ready',
            slice_type => 'full',
            width => 1,
        },
        'simple signal uses the legacy signal hash form',
    );

    my $slice = $namer->parse_expression('payload[7:0]');
    is($slice->{type}, 'signal', 'range select remains a signal hash');
    is($slice->{slice_type}, 'range', 'range select records range slice type');
    is($slice->{width}, 8, 'range select width is inferred from endpoints');

    my $constant = $namer->parse_expression('const_8b10101010');
    is($constant->{type}, 'constant', 'encoded constant uses constant hash type');
    is($constant->{format}, 'binary', 'encoded constant records binary format');
    is($constant->{width}, 8, 'encoded constant preserves width');

    my $unary = $namer->parse_expression('!ready');
    is($unary->{type}, 'unary_op', 'unary expression uses unary_op hash type');
    is($unary->{operand}{name}, 'ready', 'unary operand is recursively parsed');

    my $binary = $namer->parse_expression('ready & valid');
    is($binary->{type}, 'binary_op', 'bitwise/logical expression uses binary_op hash type');
    is($binary->{left}{name}, 'ready', 'binary left operand is recursively parsed');
    is($binary->{right}{name}, 'valid', 'binary right operand is recursively parsed');

    my $comparison = $namer->parse_expression('ready == valid');
    is($comparison->{type}, 'comparison', 'comparison expression uses comparison hash type');
    is($comparison->{op}, '==', 'comparison records the operator');

    my $arithmetic = $namer->parse_expression('count + one');
    is($arithmetic->{type}, 'arithmetic', 'arithmetic expression uses arithmetic hash type');
    is($arithmetic->{op}, '+', 'arithmetic records the operator');
};

subtest 'parse_and_name_expression stores hash-backed private definitions' => sub {
    my $namer = FSM::ExpressionNamer->new();

    my $signal_name = $namer->parse_and_name_expression('payload[7:0]');
    my $definitions = $namer->get_signal_definitions;
    my $definition = $definitions->{$signal_name};

    ok($definition, 'parse_and_name_expression registers one signal definition');
    is($definition->{definition}, 'payload[7:0]', 'registered definition preserves rendered SystemVerilog');
    is($definition->{width}, 8, 'registered definition uses legacy hash width inference');
    is_legacy_hash_ast($definition->{ast}, 'registered definition AST');
    is($definition->{ast}{type}, 'signal', 'registered definition keeps the legacy signal hash');
};

subtest 'hash-aware callers keep accepting legacy hash ASTs' => sub {
    my $namer = FSM::ExpressionNamer->new();
    my $ast = $namer->parse_expression('mid & src');

    my $factorization_support =
      FSM::Synthesis::EnableGraph::FactorizationSupport->new(flattened_dt => {});
    ok($factorization_support->ast_contains_signal($ast, 'mid'), 'FactorizationSupport finds signals in hash ASTs');
    ok(!$factorization_support->ast_contains_signal($ast, 'missing'), 'FactorizationSupport does not invent missing hash signals');

    my $operand_validator =
      FSM::HDL::FlattenedDT::Backend::SystemVerilog::OperandContractValidationSupport->new(flattened_dt => {});
    my @operand_names;
    $operand_validator->_collect_signal_operand_names($ast, \@operand_names, {}, {});
    is_deeply(sorted_names(@operand_names), [qw(mid src)], 'operand validator collects names from hash ASTs');

    my $signal_support =
      FSM::Synthesis::EnableGraph::SignalSupport->new(flattened_dt => {
          intermediate_signals => { mid => {} },
          global_expressions => {},
          ast_factorizer => {},
          referenced_intermediate_signals => {},
          enable_graph_intermediate_support => bless({}, 'Local::NoNativeIntermediateSupport'),
          fsm_module => undef,
      });
    is_deeply(
        [ $signal_support->extract_intermediate_signals_from_ast($ast) ],
        ['mid'],
        'SignalSupport extracts intermediate signal names from hash ASTs',
    );

    my $policy_support =
      FSM::Synthesis::EnableGraph::FactorizationPolicySupport->new(flattened_dt => {
          enable_graph_signal_support => Local::IntermediateSignalSet->new('mid'),
      });
    ok($policy_support->ast_contains_intermediate_signals($ast), 'FactorizationPolicySupport detects hash AST intermediate signals');
};

subtest 'blessed-only legacy hooks still ignore ExpressionNamer hash output' => sub {
    my $namer = FSM::ExpressionNamer->new();
    my $ast = $namer->parse_expression('mid & src');

    my $global_ast_manager = FSM::GlobalASTManager->new();
    $global_ast_manager->collect_ast($ast, 'legacy_hash');
    is(scalar(@{$global_ast_manager->{all_asts}}), 0, 'GlobalASTManager collect_ast ignores unblessed hash ASTs');
    is($global_ast_manager->{stats}{total_asts_collected}, 0, 'GlobalASTManager collection stats stay unchanged for hash ASTs');

    my $intermediate_support =
      FSM::Synthesis::EnableGraph::IntermediateSignalSupport->new(flattened_dt => {
          expr_namer => $namer,
      });
    is(
        $intermediate_support->_parse_intermediate_expression_to_ast('mid & src', 'mid_expr', 'unit_test'),
        undef,
        'IntermediateSignalSupport compatibility parser remains blessed-only for current hash output',
    );

    my $signal_support =
      FSM::Synthesis::EnableGraph::SignalSupport->new(flattened_dt => {
          expr_namer => $namer,
          global_expressions => { 'mid & src' => 'mid_and_src' },
          intermediate_signals => {},
          ast_factorizer => {},
          referenced_intermediate_signals => {},
          enable_graph_intermediate_support => bless({}, 'Local::NoNativeIntermediateSupport'),
          fsm_module => undef,
      });
    ok(
        !$signal_support->_signal_name_indicates_ast_operators('mid_and_src'),
        'SignalSupport AST-operator metadata hook remains blessed-only for current hash output',
    );
};

done_testing;
