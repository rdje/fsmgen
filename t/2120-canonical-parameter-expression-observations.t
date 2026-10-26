use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::ParameterValueSupport;
use FSM::Package::Symbols;

my $json = JSON::PP->new->canonical;
my %capture;
sub copy {return $json->decode($json->encode($_[0]))}
sub literal {return {kind => 'literal', token => $_[0]}}
sub symbol {return {kind => 'symbol', token => $_[0]}}
sub operator {my ($canonical, $source, @operands) = @_;return {
    kind => 'operator', operator => $canonical, source_operator => $source, operands => \@operands}}
sub ast {
    my ($expression) = @_;
    my $text = "(?fsm:expression_source (+params (VALUE $expression)))";
    my $raw = Lispish::multi(\$text);
    return $raw->[0][1][0][1][0][1];
}
my $symbols = FSM::Package::Symbols->new(constants => {
    W => {kind => 'scalar', payload => '16'}, K => {kind => 'scalar', payload => '4'},
    LANES => {kind => 'list', items => [{kind => 'scalar', payload => "8'hA5"}, {kind => 'scalar', payload => "8'h3C"}]},
    FRAME => {kind => 'map', member_order => ['tag'], members => {tag => {kind => 'scalar', payload => "4'hA"}}},
});

subtest 'actual canonical branches preserve source structure without changing values or callbacks' => sub {
    for my $case (
        ['literal', '0x10', literal('0x10')],
        ['symbol', 'W', symbol('W')],
        ['alias operator', '(add W 2)', operator('+', 'add', symbol('W'), literal('2'))],
        ['nested operator', '(+ W (* K 2))', operator('+', '+', symbol('W'), operator('*', '*', symbol('K'), literal('2')))],
        ['list', "(8'hA5 8'h3C)", {kind => 'list', items => [literal("8'hA5"), literal("8'h3C")]}],
        ['map', "((tag 4'hA) (flag 1'b1))", {kind => 'map', member_order => [qw(tag flag)], members => {tag => literal("4'hA"), flag => literal("1'b1")}}],
        ['unary aggregate', '(not LANES)', operator('~', 'not', symbol('LANES'))],
        ['binary aggregate', '(xor LANES LANES)', operator('^', 'xor', symbol('LANES'), symbol('LANES'))],
        ['aggregate comparison', '(== LANES LANES)', operator('==', '==', symbol('LANES'), symbol('LANES'))],
        ['member path', 'FRAME.tag', symbol('FRAME.tag')],
        ['index path', 'LANES[1]', symbol('LANES[1]')],
    ) {
        my ($name, $source, $expected) = @$case;my $input = ast($source);my $before = $json->encode($input);
        my (%result, %calls);
        for my $mode (0, 1) {
            my $caller = copy($input);
            $result{$mode} = FSM::ParameterValueSupport->canonical_value(value_ast => $caller,
                capture_expression => $mode, resolve_symbol_payload => sub {
                    push @{$calls{$mode}}, $_[0];return $symbols->resolve_payload($_[0]);
                });
            is($json->encode($caller), $before, "$name preserves caller primitive kinds with capture $mode");
        }
        ok(!exists($result{0}{value_expression}), "$name ordinary result shape is unchanged");
        my $with = copy($result{1});delete $with->{value_expression};
        my $expression = $result{1}{value_expression};
        is($json->encode($with), $json->encode($result{0}), "$name complete canonical result stays exact");
        is($json->encode($expression), $json->encode($expected), "$name records actual source structure and token kinds");
        is_deeply($calls{1}, $calls{0}, "$name preserves actual resolver call order");
        $capture{cases}{$name} = {without => copy($result{0}), with => copy($result{1}), calls => copy($calls{1}), source => copy($input)};
        $input->[0] = 'WRONG';
        is($json->encode($expression), $json->encode($expected), "$name expression is detached from source mutation");
    }
};

subtest 'semantic payloads remain canonical payload nodes rather than invented source syntax' => sub {
    for my $input ({kind => 'scalar', payload => "8'hA5"}, {kind => 'scalar_expr', payload => '(8 + 1)'},
        {kind => 'list', items => [{kind => 'scalar', payload => "8'hA5"}, {kind => 'scalar', payload => "8'h3C"}]}) {
        my $before = $json->encode($input);
        my $result = FSM::ParameterValueSupport->canonical_value(value_ast => $input, capture_expression => 1);
        my $expression = $result->{value_expression};
        is($json->encode($expression), $json->encode({kind => 'payload', value => $input}), 'semantic payload has an explicit opaque canonical node');
        is($json->encode($input), $before, 'semantic payload caller is unchanged');
        if ($input->{kind} eq 'list') {$input->{items}[0]{payload} = 'WRONG'}
        else {$input->{payload} = 'WRONG'}
        is($json->encode($expression), '{"kind":"payload","value":'.$before.'}', 'payload source is detached');
        $capture{payloads}{$before} = copy($expression);
        SKIP: {
            skip 'required expression is absent above', 1 unless ref($expression) eq 'HASH';
            my $cache_before = $json->encode($result->{value_payload});
            if ($expression->{value}{kind} eq 'list') {$expression->{value}{items}[0]{payload} = 'WRONG'}
            else {$expression->{value}{payload} = 'WRONG'}
            is($json->encode($result->{value_payload}), $cache_before, 'metadata mutation cannot rewrite the canonical value cache');
        }
    }
};

subtest 'capture does not admit refused canonical expressions' => sub {
    for my $case (['unknown', 'UNKNOWN', qr/UNKNOWN/], ['arity', '(+ W)', qr/at least 2 operands/],
        ['mixed aggregate', "((tag 4'hA) 8'hA5)", qr/cannot mix/]) {
        my ($name, $source, $expected) = @$case;
        for my $mode (0, 1) {
            my $input = ast($source);
            my $ok = eval {FSM::ParameterValueSupport->canonical_value(value_ast => $input,
                capture_expression => $mode, resolve_symbol_payload => sub {$symbols->resolve_payload($_[0])});1};my $error = $@;
            ok(!$ok, "$name refuses with capture $mode");like($error, $expected, "$name keeps its canonical reason with capture $mode");
            $capture{refusals}{$name}{$mode} = {ok => $ok ? 1 : 0, error => $error};
        }
    }
};

if (my $path = $ENV{FSMGEN_PARAMETER_EXPRESSION_CAPTURE}) {
    open my $out, '>', $path or die $!;print {$out} $json->encode(\%capture), "\n" or die $!;close $out or die $!;
}
done_testing();
