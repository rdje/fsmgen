use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use FSM::WidthExpressionSupport;
use FSM::Adapter::FSMGenFull::Parser;
use FSM::Adapter::FSMGenFull::SignalManager;
use FSM::Adapter::FSMGenFull::ExpressionBuilder;

my $json = JSON::PP->new->canonical;
my @lookups;
my %static = (W => {kind => 'scalar', payload => '4'},
    LEAF => {kind => 'scalar_expr', payload => 'W+2*3'},
    GROUP => {kind => 'list', items => []});
my %params = (W => {kind => 'scalar', payload => '16'});
my $kernel = FSM::WidthExpressionSupport->new(
    resolve_symbol_payload => sub {push @lookups, ['static', $_[0]]; return $static{$_[0]}},
    resolve_parameter_payload => sub {push @lookups, ['parameter', $_[0]]; return $params{$_[0]}},
);
my $manager = FSM::Adapter::FSMGenFull::SignalManager->new;
my $parser = FSM::Adapter::FSMGenFull::Parser->new(signal_manager => $manager,
    expression_builder => FSM::Adapter::FSMGenFull::ExpressionBuilder->new(signal_manager => $manager));

subtest 'shared arithmetic keeps canonical bounds and literal semantics' => sub {
    for my $case (
        ['0x10', 16], [['add', [3, 5]], 8],
        [['*', [3, ['+', [2, 4]]]], 18], [['/', [19, 4]], 4],
        [['mod', [19, 4]], 3], [['and', [7, 3]], 3],
        [['or', [8, 3]], 11], [['xor', [15, 3]], 12],
        [['-', [20, 3, 2]], 15],
    ) {
        my ($source, $expected) = @$case;
        my $before = $json->encode($source);
        is($kernel->resolve_positive_width_expression($source, 'shared width'), $expected, 'independent integer expectation');
        is($parser->resolve_positive_width_expression($source, 'direct width'), $expected, 'direct Parser interface conserves result');
        is($json->encode($source), $before, 'complete source token kinds remain unchanged');
    }
    is($kernel->evaluate_infix_constant_integer_expression('3+4*2|16', 'precedence')->bstr, 27, 'existing binding powers');
    is($kernel->evaluate_infix_constant_integer_expression('(3+4)*2', 'parentheses')->bstr, 14, 'explicit grouping');
};

subtest 'explicit callbacks select namespaces without borrowing equal names' => sub {
    my $before = $json->encode([\%static, \%params]);
    is($kernel->resolve_positive_width_expression('W', 'bare'), 4, 'bare symbol selects static callback');
    is($kernel->resolve_positive_width_expression(['param', ['W']], 'selected'), 16, 'selector selects actual declared parameter');
    is($kernel->resolve_positive_width_expression(['+', [['param', ['W']], 'LEAF']], 'mixed'), 26, 'nested static expression keeps its namespace');
    is_deeply(\@lookups, [['static', 'W'], ['parameter', 'W'], ['parameter', 'W'], ['static', 'LEAF'], ['static', 'W']], 'literal lookup identities and order');
    is($json->encode([\%static, \%params]), $before, 'resolver payloads remain unchanged');
    my $empty = FSM::WidthExpressionSupport->new;
    my $ok = eval {$empty->resolve_positive_width_expression(['param', ['W']], 'absent');1};
    ok(!$ok, 'missing parameter does not borrow another environment');
    like($@, qr/unknown declared parameter 'W'/, 'actual namespace refusal');
};

subtest 'same canonical refusal meanings through reusable and Parser entrypoints' => sub {
    for my $case (
        [0, qr/positive integer/], [['-', [2, 3]], qr/negative width-expression/],
        [['+', [1]], qr/at least two operands/], [['/', [4, 0]], qr/divides by zero/],
        [['%', [4, 0]], qr/modulo by zero/], [['<<', [1, 2]], qr/unsupported width expression operator/],
        [['param', ['W', 'EXTRA']], qr/exactly one declared parameter/],
        [['param', ['UNKNOWN']], qr/unknown declared parameter/],
        ['UNKNOWN', qr/unknown or non-scalar constant/],
    ) {
        for my $consumer ($kernel, $parser) {
            my $ok = eval {$consumer->resolve_positive_width_expression($case->[0], 'control');1};
            ok(!$ok, 'invalid width refuses');like($@, $case->[1], 'precise canonical failure');
        }
    }
    my $ok = eval {$kernel->resolve_positive_width_expression('GROUP', 'aggregate');1};
    ok(!$ok, 'aggregate does not become a width');like($@, qr/aggregate payload kind 'list'/, 'scalar-only refusal');
    $ok = eval {FSM::WidthExpressionSupport->new(resolve_symbol_payload => {});1};
    ok(!$ok, 'invalid resolver hook refuses at construction');
    like($@, qr/resolve_symbol_payload.*callback/, 'hook contract named');
};
done_testing();
